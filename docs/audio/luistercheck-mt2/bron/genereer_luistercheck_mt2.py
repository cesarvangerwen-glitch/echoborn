#!/usr/bin/env python3
"""Luisterfragment voor de luistercheck F2 op de kaart van MT2 (V-10, bible §9.4).

Het fragment dat F2 claimt (v2, `docs/audio/f2-fragment/
f2_merk_aftelling_carillon_placeholder.wav`, 15,5 s) duurt kort voor drie
vragen. Dit script zet het in een luisterreeks van ± 1 min 10 s, zonder iets
nieuws te renderen: elke klank komt uit het v2-fragment zelf of uit zijn
eigen bouwstenen (`f2-fragment/losse-sfx/`).

Opbouw (de tijden schrijft het script naar meting_placeholder.json):
  A   0,0-15,5 s  het v2-fragment, ongewijzigd en op 0,0 s, zodat de tijden van
                 bible §9.4 en de kaart (2,1 / 2,35 / 2,6 / 0,6 / 9,0 / 10,5-11,1 s)
                 blijven kloppen. Sample voor sample gelijk (het script controleert dat).
  L1  carillon:   aftelling + klokslag grijs (1,9-3,3 s), dan opgepompt (10,3-11,9 s); 2x
  L2  jij, maar hol: in de mix P1-slag (0,35-1,35 s) tegenover de echo (2,15-3,15 s);
                 dan de twee bouwstenen los: p1_slag en echo_slag (-7 dB, bible §4); 2x
  L3  warmer:     grijs (3,9-6,2 s) tegenover opgepompt (12,0-14,3 s); 2x
  B   het v2-fragment nog een keer, heel.
Tussen de delen 2 s stilte; geen gesproken tekst of signaaltonen (een toon
zou je met een klok verwarren).

Niveau: de stukken uit het fragment blijven op hun eigen niveau (0 dB gain,
alleen 15 ms in- en uitfaden). De losse bouwstenen staan elk op -3 dBFS piek;
het script zet de P1-slag op het niveau van zijn moment in de mix en de echo
7 dB lager, zoals in bible §4, en daarna beide samen zo veel zachter dat hun
true peak onder die van v2 blijft (-1,8 dBTP).

Opnieuw maken, vanaf de repo-root:
    python3 docs/audio/luistercheck-mt2/bron/genereer_luistercheck_mt2.py [--wav]

Schrijft naar docs/audio/luistercheck-mt2/:
    luistercheck_mt2_placeholder.ogg   (Vorbis q6, 48 kHz, stereo; met ffmpeg + libvorbis)
    luistercheck_mt2_placeholder.wav   (alleen met --wav, of als ffmpeg ontbreekt)
    meting_placeholder.json            (tijden, loudness, true peak, controles)
Nodig: numpy, scipy; optioneel pyloudnorm (tweede loudnessmeting) en ffmpeg.
De WAV is bit voor bit opnieuw te maken; de OGG kan per ffmpeg-build verschillen.
"""
import hashlib
import json
import os
import re
import shutil
import subprocess
import sys

import numpy as np
from scipy import signal
from scipy.io import wavfile

HIER = os.path.dirname(os.path.abspath(__file__))
UIT = os.path.dirname(HIER)
F2 = os.path.join(os.path.dirname(UIT), "f2-fragment")
V2 = os.path.join(F2, "f2_merk_aftelling_carillon_placeholder.wav")
V2_SHA = "b09aa64310188f997e46dcddf7fea1c8af0e8ced74dccd34fc4606d0c9609057"  # bible §9
SR = 48000
FADE = 0.015
PAUZE_DEEL = 2.0
PAUZE_KORT = 0.7

K_B1 = [1.53512485958697, -2.69169618940638, 1.19839281085285]
K_A1 = [1.0, -1.69065929318241, 0.73248077421585]
K_B2 = [1.0, -2.0, 1.0]
K_A2 = [1.0, -1.99004745483398, 0.99007225036621]


def n(sec):
    return int(round(sec * SR))


def lees(pad):
    sr, x = wavfile.read(pad)
    assert sr == SR and x.dtype == np.int16, pad
    return x.astype(np.float64) / 32767


def blok_lufs(x, blok=0.4, stap=0.1):
    y = signal.lfilter(K_B2, K_A2, signal.lfilter(K_B1, K_A1, x, axis=0), axis=0)
    b, s = n(blok), n(stap)
    z = np.array([np.sum(np.mean(y[i: i + b] ** 2, axis=0)) for i in range(0, max(1, len(y) - b + 1), s)])
    return z


def lufs_geintegreerd(x):
    z = blok_lufs(x)
    l = -0.691 + 10 * np.log10(z + 1e-12)
    z1 = z[l > -70]
    rel = -0.691 + 10 * np.log10(np.mean(z1)) - 10
    return float(-0.691 + 10 * np.log10(np.mean(z[(l > -70) & (l > rel)])))


def momentaan_max(x):
    if len(x) < n(0.4):
        x = np.concatenate([x, np.zeros((n(0.4) - len(x), 2))])
    return float(np.max(-0.691 + 10 * np.log10(blok_lufs(x, 0.4, 0.01) + 1e-12)))


def true_peak_db(x):
    return float(20 * np.log10(np.max(np.abs(signal.resample_poly(x, 4, 1, axis=0))) + 1e-12))


def fade(x):
    x = x.copy()
    k = n(FADE)
    r = np.sin(np.linspace(0, np.pi / 2, k))[:, None] ** 2
    x[:k] *= r
    x[-k:] *= r[::-1]
    return x


def stilte(sec):
    return np.zeros((n(sec), 2))


def main():
    houd_wav = "--wav" in sys.argv
    sha = hashlib.sha256(open(V2, "rb").read()).hexdigest()
    if sha != V2_SHA:
        sys.exit(f"Het v2-fragment is niet de versie die F2 claimt (sha256 {sha}).")
    v2 = lees(V2)
    p1 = lees(os.path.join(F2, "losse-sfx", "p1_slag_placeholder.wav"))
    echo = lees(os.path.join(F2, "losse-sfx", "echo_slag_placeholder.wav"))

    uit = lambda a, b: fade(v2[n(a): n(b)])
    # P1-slag los op het niveau van de P1-slag in de mix (venster 0,55-0,95 s), echo 7 dB lager (bible §4)
    doel_p1 = momentaan_max(v2[n(0.55): n(0.95)])
    p1 = p1 * 10 ** ((doel_p1 - momentaan_max(p1)) / 20)
    echo = echo * 10 ** ((doel_p1 - 7.0 - momentaan_max(echo)) / 20)
    # true peak van het paar onder die van v2 (-1,8 dBTP): beide samen zachter, de -7 dB blijft
    tp_los = max(true_peak_db(p1), true_peak_db(echo))
    g_los = min(0.0, -1.8 - tp_los)
    p1, echo = p1 * 10 ** (g_los / 20), echo * 10 ** (g_los / 20)
    doel_p1 += g_los

    delen = []  # (label, signaal, beschrijving)

    def zet(label, x, wat):
        delen.append((label, x, wat))

    zet("A", v2.copy(), "v2-fragment heel (de tijden van bible §9.4 gelden hier)")
    zet("-", stilte(PAUZE_DEEL), "stilte")
    for i in (1, 2):
        zet(f"L1.{i}a", uit(1.9, 3.3), "carillon grijs: aftelslag 1 en 2 (2,1 / 2,35 s) en de klokslag met de echo (2,6 s)")
        zet("-", stilte(PAUZE_KORT), "stilte")
        zet(f"L1.{i}b", uit(10.3, 11.9), "carillon opgepompt: aftelling (10,5 / 10,75 s) en ketting (11,0 s)")
        zet("-", stilte(PAUZE_DEEL if i == 2 else PAUZE_KORT), "stilte")
    zet("L2.1a", uit(0.35, 1.35), "in de mix: slag van speler 1 (0,6 s)")
    zet("-", stilte(PAUZE_KORT), "stilte")
    zet("L2.1b", uit(2.15, 3.15), "in de mix: de echo op slag 3 (2,6 s)")
    zet("-", stilte(PAUZE_KORT), "stilte")
    for i in (2, 3):
        zet(f"L2.{i}a", fade(p1), "los: p1_slag (bouwsteen van v2)")
        zet("-", stilte(PAUZE_KORT), "stilte")
        zet(f"L2.{i}b", fade(echo), "los: echo_slag = echo_versie(p1_slag), 7 dB zachter")
        zet("-", stilte(PAUZE_DEEL if i == 3 else PAUZE_KORT), "stilte")
    for i in (1, 2):
        zet(f"L3.{i}a", uit(3.9, 6.2), "grijs: water, wind, bourdon, verre klok (wereld zonder spelers)")
        zet("-", stilte(PAUZE_KORT), "stilte")
        zet(f"L3.{i}b", uit(12.0, 14.3), "opgepompt: gemaal, harmonium D-groot add9, belfort-galm, helder water")
        zet("-", stilte(PAUZE_DEEL if i == 2 else PAUZE_KORT), "stilte")
    zet("B", v2.copy(), "v2-fragment nog een keer heel")

    reeks = np.concatenate([d[1] for d in delen])
    momenten, t = [], 0.0
    for label, x, wat in delen:
        if label != "-":
            momenten.append({"deel": label, "van_s": round(t, 2), "tot_s": round(t + len(x) / SR, 2), "wat": wat})
        t += len(x) / SR

    x16 = np.clip(np.round(reeks * 32767), -32768, 32767).astype(np.int16)
    _, bron16 = wavfile.read(V2)
    start_b = momenten[-1]["van_s"]
    controle = {
        "v2_sha256": sha,
        "deel_A_sample_gelijk_aan_v2": bool(np.array_equal(x16[: len(bron16)], bron16)),
        "deel_B_sample_gelijk_aan_v2": bool(np.array_equal(x16[n(start_b): n(start_b) + len(bron16)], bron16)),
        "clipping_samples": int(np.sum(np.abs(x16.astype(np.int32)) >= 32767)),
    }
    xm = x16.astype(np.float64) / 32767
    meting = {
        "duur_s": round(len(xm) / SR, 2),
        "lufs_geintegreerd_script": round(lufs_geintegreerd(xm), 1),
        "lufs_momentaan_max_script": round(momentaan_max(xm), 1),
        "true_peak_dbtp_script": round(true_peak_db(xm), 2),
        "niveau_los_p1_slag_lufs_momentaan": round(doel_p1, 1),
        "gain_los_paar_db_voor_true_peak": round(g_los, 2),
        "niveau_los_echo_slag_lufs_momentaan": round(doel_p1 - 7.0, 1),
    }
    try:
        import pyloudnorm as pyln

        meting["lufs_geintegreerd_pyloudnorm"] = round(float(pyln.Meter(SR).integrated_loudness(xm)), 1)
    except ImportError:
        pass

    wav = os.path.join(UIT, "luistercheck_mt2_placeholder.wav")
    ogg = wav[:-4] + ".ogg"
    wavfile.write(wav, SR, x16)
    meting["wav_sha256"] = hashlib.sha256(open(wav, "rb").read()).hexdigest()
    meting["wav_ebur128"] = ebur128(wav)
    if shutil.which("ffmpeg"):
        subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-i", wav, "-c:a", "libvorbis", "-q:a", "6",
                        "-map_metadata", "-1", "-fflags", "+bitexact", "-flags:a", "+bitexact", ogg], check=True)
        meting["ogg_na_decoderen_ebur128"] = ebur128(ogg)
        meting["ogg_na_decoderen_pyloudnorm"] = meet_ogg_pyln(ogg)
        meting["ogg_bytes"] = os.path.getsize(ogg)
        if not houd_wav:
            os.remove(wav)  # de WAV is bit voor bit opnieuw te maken; in de repo staat de OGG
    uitkomst = {"bestand": os.path.basename(ogg if shutil.which("ffmpeg") else wav), "controle": controle,
                "meting": meting, "momenten": momenten}
    with open(os.path.join(UIT, "meting_placeholder.json"), "w") as fh:
        json.dump(uitkomst, fh, indent=1, ensure_ascii=False)
    print(json.dumps(uitkomst, indent=1, ensure_ascii=False))
    if not (controle["deel_A_sample_gelijk_aan_v2"] and controle["deel_B_sample_gelijk_aan_v2"]):
        sys.exit("Deel A of B wijkt af van het v2-fragment.")


def ebur128(pad):
    if not shutil.which("ffmpeg"):
        return None
    r = subprocess.run(["ffmpeg", "-nostats", "-hide_banner", "-i", pad, "-af", "ebur128=peak=true",
                        "-f", "null", "-"], capture_output=True, text=True)
    s = r.stderr[r.stderr.rfind("Summary:"):]
    get = lambda k: float(re.search(k + r":\s+(-?[\d.]+|-inf)", s).group(1))
    return {"I_LUFS": get("I"), "LRA_LU": get("LRA"), "true_peak_dBTP": get(r"True peak:\s+Peak")}


def meet_ogg_pyln(ogg):
    try:
        import pyloudnorm as pyln
    except ImportError:
        return None
    r = subprocess.run(["ffmpeg", "-loglevel", "error", "-i", ogg, "-f", "f32le", "-ac", "2", "-ar", str(SR), "-"],
                       capture_output=True, check=True)
    x = np.frombuffer(r.stdout, dtype=np.float32).reshape(-1, 2).astype(np.float64)
    return {"I_LUFS": round(float(pyln.Meter(SR).integrated_loudness(x)), 1),
            "true_peak_dBTP_4x": round(true_peak_db(x), 2), "duur_s": round(len(x) / SR, 2)}


if __name__ == "__main__":
    main()
