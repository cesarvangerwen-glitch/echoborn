#!/usr/bin/env python3
"""Pompslag op een schoep van het gemaal (#243, bible v0.5 §4.1), placeholder.

Eén bestand voor P1, P2 en de echo, zonder echo-variant (bible §4.1, §11).
De echo speelt hetzelfde bestand met `pitch_scale` 2^(-1/12); dat doet de
speler in Godot, niet dit script. Het script rendert die versie alleen als
controle (eis van de Audio Director in #243).

Klank (machinefamilie, bible §3 en de pompslag van `gemaal()` in het
F2-script): een zware houten schoep die op ijzer klapt, met een waterstoot
en spatbelletjes. Lijf onder 250 Hz, maar >= 35 % van de energie erboven,
zodat je hem ook op de Deck-luidsprekers hoort (bible §8.2).

Eisen (#243): max. momentane loudness -17 LUFS (400 ms), true peak
<= -1,5 dBTP, >= 35 % energie boven 250 Hz, duur <= 30 ticks (0,5 s).

Alles is eigen synthese (numpy/scipy), geen externe samples. Vaste seed:
de WAV-bestanden zijn bit voor bit opnieuw te maken.

Opnieuw maken, vanaf de repo-root:
    python3 audio-bron/sfx/omgeving/genereer_pompslag_schoep.py

Schrijft:
    game/audio/sfx/omgeving/pompslag_schoep_placeholder.wav      (48 kHz, 16 bit, mono)
    docs/audio/pompslag-schoep/pompslag_controle_zelfde_tick_placeholder.wav
        P1 (pitch 1,0) en de echo (pitch 2^(-1/12)) op dezelfde tick, mono
    docs/audio/pompslag-schoep/pompslag_controle_s6_reeks_placeholder.wav
        S6 bij D = 60: P1 slaat op tick 0, 20, 40, 60; de echo herhaalt op
        60, 80, 100, 120 (de slag op 60 valt samen), mono
    docs/audio/pompslag-schoep/meting_placeholder.json
Het .import-bestand maakt Godot (`godot --headless --path game --import`).
"""
import hashlib
import importlib.util
import json
import os
import re
import shutil
import subprocess
import sys

import numpy as np
from scipy import signal

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))))
F2_PAD = os.path.join(ROOT, "docs", "audio", "f2-fragment", "bron", "genereer_f2.py")
GAME_UIT = os.path.join(ROOT, "game", "audio", "sfx", "omgeving")
DOC_UIT = os.path.join(ROOT, "docs", "audio", "pompslag-schoep")

sys.dont_write_bytecode = True
_spec = importlib.util.spec_from_file_location("genereer_f2", F2_PAD)
f2 = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(f2)  # maakt alleen de galm-IR's; schrijft niets

SR, TICK = f2.SR, f2.TICK
n, tijd, filt, fade, bel, leg = f2.n, f2.tijd, f2.filt, f2.fade, f2.bel, f2.leg

DUUR_TICKS = 28  # eis #243: <= 30 ticks; 28, zodat ook de echo-versie (28 / 0,944 = 29,7) binnen 30 blijft
DOEL_MOMENTAAN = -17.0  # LUFS, niveau van treffers (slice-audio.md §1)
TP_GRENS = -1.5  # dBTP
ECHO_PITCH = 2 ** (-1 / 12)  # bible §4.1, ~0,944
D = 60  # werkaanname staart (bible, kop)

r = np.random.default_rng(243)


def modi(lijst, sec, spreid=0.0):
    """Som van uitstervende sinussen [(f, a, tau)]."""
    t = tijd(sec)
    y = np.zeros(len(t))
    for f, a, tau in lijst:
        f *= 1 + r.uniform(-spreid, spreid)
        y += a * np.exp(-t / tau) * np.sin(2 * np.pi * f * t + r.uniform(0, 6.3))
    return y


def pompslag():
    sec = DUUR_TICKS * TICK
    t = tijd(sec)
    # 1. klik van de aanslag (hout op ijzer), 2 ms
    k = n(0.002)
    klik = np.zeros(len(t))
    klik[:k] = filt(r.standard_normal(k), "bandpass", [900, 9000], 2) * np.linspace(1, 0, k)
    # 2. lijf: de plof van de schoep in het water, zakkend 98 -> 52 Hz (zoals gemaal(), korter)
    plof = np.sin(2 * np.pi * np.cumsum(46 * np.exp(-t / 0.05) + 52) / SR) * np.exp(-t / 0.11)
    plof[: n(0.003)] *= np.linspace(0, 1, n(0.003))
    # 3. hout: zware schoep, korte modi
    hout = modi([(176, 0.55, 0.06), (403, 0.5, 0.045), (688, 0.35, 0.035), (1105, 0.22, 0.025),
                 (1690, 0.12, 0.018)], sec, 0.01)
    # 4. ijzer: de as en het beslag, de modi van de pompslag in gemaal() (310, 742, 1214 Hz)
    ijzer = modi([(310, 0.32, 0.10), (742, 0.24, 0.08), (1214, 0.15, 0.06), (1987, 0.07, 0.04)], sec, 0.005)
    # 5. waterstoot: gefilterde ruis die na de klap aanzwelt en wegvalt
    stoot = filt(r.standard_normal(len(t)), "bandpass", [300, 2400], 2)
    stoot *= np.interp(t, [0, 0.015, 0.06, 0.2, sec], [0, 0.55, 0.4, 0.12, 0])
    # 6. spatbelletjes uit de schoep (Minnaert, zoals het schoepenrad in F2)
    spat = np.zeros(len(t))
    for _ in range(10):
        leg(spat, bel(r.uniform(420, 1900), r.uniform(0.15, 0.45), maxsec=0.2), r.uniform(0.03, 0.26))
    y = 0.35 * klik + 0.5 * plof + 1.1 * hout + 1.0 * ijzer + 0.6 * stoot + 0.45 * spat
    y = filt(y, "highpass", 45, 2)  # geen subsonisch laag (bible §9.3 punt 7)
    y = fade(y, 0.0, 0.12)
    y[-n(0.002):] = 0.0  # precies stil op tick 30
    return y


def momentaan_max(x):
    st = np.stack([x, x], axis=1) if x.ndim == 1 else x
    if len(st) < n(0.4):
        st = np.concatenate([st, np.zeros((n(0.4) - len(st), 2))])
    return f2.lufs_max(st, 0.4)


def begrens(x, plafond_db):
    """Zachte limiter op de true peak (4x overbemonsterd), zoals master() in F2:
    alleen de eerste milliseconden van de klap worden een fractie zachter."""
    plafond = 10 ** (plafond_db / 20)
    up = np.abs(signal.resample_poly(x, 4, 1))
    om = np.maximum(up[: 4 * len(x)].reshape(-1, 4).max(axis=1), 1e-9)
    g = np.minimum(1.0, plafond / om)
    w = n(0.002)
    g = f2._minf(g, w)
    kern = np.hanning(2 * w + 1)
    g = np.convolve(g, kern / kern.sum(), mode="same")
    return x * g


def peil(x):
    """Naar -17 LUFS momentaan max, met de true peak onder -1,5 dBTP."""
    x = x - np.mean(x)
    for _ in range(4):
        x = x * 10 ** ((DOEL_MOMENTAAN - momentaan_max(x)) / 20)
        x = begrens(x, TP_GRENS - 0.3)
    tp = f2.true_peak_db(x[:, None])
    if tp > TP_GRENS - 0.1:  # vangnet
        x = x * 10 ** ((TP_GRENS - 0.1 - tp) / 20)
    return x


def pitch(x, ps):
    """Zoals Godot `pitch_scale`: sneller/trager afspelen (toon en duur samen)."""
    m = int(round(len(x) / ps))
    pos = np.arange(m) * ps
    return np.interp(pos, np.arange(len(x)), x)


def pyln_momentaan_max(x):
    """Tweede meting: pyloudnorm (ITU-R BS.1770-4) op vensters van 400 ms, stap 10 ms."""
    try:
        import pyloudnorm as pyln
    except ImportError:
        return None
    m = pyln.Meter(SR, block_size=0.4)
    xx = np.concatenate([np.zeros(n(0.4)), x, np.zeros(n(0.4))])
    best = -np.inf
    for i in range(0, len(xx) - n(0.4), n(0.01)):
        w = xx[i: i + n(0.4)]
        if np.any(w):
            best = max(best, m.integrated_loudness(np.stack([w, w], axis=1)))
    return round(float(best), 1)


def ebur128(pad):
    if not shutil.which("ffmpeg"):
        return None
    # mono als dual mono meten, zoals de stereo-meting in het script (L = R)
    res = subprocess.run(["ffmpeg", "-nostats", "-hide_banner", "-i", pad, "-af",
                          "pan=stereo|c0=c0|c1=c0,apad=pad_dur=0.4,ebur128=peak=true", "-f", "null", "-"],
                         capture_output=True, text=True)
    s = res.stderr
    mom = [float(v) for v in re.findall(r"M:\s*(-?[\d.]+)", s)]
    tp = re.search(r"True peak:\s+Peak:\s+(-?[\d.]+|-inf)", s[s.rfind("Summary:"):])
    return {"M_max_LUFS": max(mom) if mom else None, "true_peak_dBTP": float(tp.group(1)) if tp else None}


def meet(x):
    f, p = signal.welch(x, SR, nperseg=min(4096, len(x)))
    tot = np.sum(p) + 1e-30
    om = np.abs(signal.hilbert(x))
    om = np.convolve(om, np.ones(n(0.005)) / n(0.005), mode="same")
    return {
        "duur_s": round(len(x) / SR, 4),
        "duur_ticks": round(len(x) / SR / TICK, 2),
        "lufs_momentaan_max": round(momentaan_max(x), 1),
        "lufs_momentaan_max_pyloudnorm": pyln_momentaan_max(x),
        "true_peak_dbtp": round(f2.true_peak_db(x[:, None]), 2),
        "aandeel_60_250hz_pct": round(float(100 * np.sum(p[(f >= 60) & (f < 250)]) / tot), 1),
        "aandeel_boven_250hz_pct": round(float(100 * np.sum(p[f >= 250]) / tot), 1),
        "zwaartepunt_hz": int(np.sum(f * p) / tot),
        "piek_op_ms": round(1000 * float(np.argmax(om)) / SR, 1),
        "clipping_samples": int(np.sum(np.abs(x) >= 32767 / 32768)),
    }


def piekfrequenties(x, lo=150, hi=2500, top=6):
    """Sterkste spectrale pieken (voor de controle: twee sets partialen?)."""
    X = np.abs(np.fft.rfft(x * np.hanning(len(x)), 8 * len(x)))
    fr = np.fft.rfftfreq(8 * len(x), 1 / SR)
    i, _ = signal.find_peaks(X, distance=int(8 * len(x) * 8 / SR))
    i = i[(fr[i] >= lo) & (fr[i] <= hi)]
    i = i[np.argsort(X[i])[::-1][:top]]
    return sorted(round(float(fr[k]), 1) for k in i)


def sha(pad):
    return hashlib.sha256(open(pad, "rb").read()).hexdigest()


def main():
    os.makedirs(GAME_UIT, exist_ok=True)
    os.makedirs(DOC_UIT, exist_ok=True)
    x = peil(pompslag())
    pad = os.path.join(GAME_UIT, "pompslag_schoep_placeholder.wav")
    f2.schrijf_wav(pad, x)
    x16 = np.round(x * 32767) / 32767  # meet wat er in het bestand staat
    uit = {"pompslag_schoep_placeholder.wav": {"pad": os.path.relpath(pad, ROOT), **meet(x16),
                                               "ffmpeg_ebur128": ebur128(pad), "sha256": sha(pad)}}

    # controle 1: P1 en de echo op dezelfde tick (Godot telt de twee spelers op)
    e = pitch(x16, ECHO_PITCH)
    zelfde = np.zeros(n(0.1) + len(e) + n(0.3))
    leg(zelfde, x16, 0.1)
    leg(zelfde, e, 0.1)
    tp1 = f2.true_peak_db(zelfde[:, None])
    g1 = min(0.0, TP_GRENS - tp1)  # alleen de controle: twee slagen tellen op tot ± +4 dB
    zelfde *= 10 ** (g1 / 20)
    p2 = os.path.join(DOC_UIT, "pompslag_controle_zelfde_tick_placeholder.wav")
    f2.schrijf_wav(p2, zelfde)
    uit["pompslag_controle_zelfde_tick_placeholder.wav"] = {
        "pad": os.path.relpath(p2, ROOT),
        "echo_pitch_scale": round(ECHO_PITCH, 4),
        "echo_duur_s": round(len(e) / SR, 4),
        "echo_duur_ticks": round(len(e) / SR / TICK, 2),
        "som_true_peak_voor_gain_dbtp": round(tp1, 2),
        "gain_db_tegen_clippen": round(g1, 2),
        "lufs_momentaan_max": round(momentaan_max(zelfde), 1),
        "true_peak_dbtp": round(f2.true_peak_db(zelfde[:, None]), 2),
        "piekfrequenties_p1_hz": piekfrequenties(x16),
        "piekfrequenties_echo_hz": piekfrequenties(e),
        "piekfrequenties_samen_hz": piekfrequenties(zelfde[n(0.1):], top=10),
        "sha256": sha(p2),
    }

    # controle 2: S6 bij D = 60, P1 om de 20 ticks (LM-04), de echo D ticks later
    reeks = np.zeros(n((120 + D + 30) * TICK + 0.6))
    momenten = []
    for tk in (0, 20, 40, 60):
        leg(reeks, x16, 0.2 + tk * TICK)
        momenten.append({"wie": "p1", "tick": tk, "s": round(0.2 + tk * TICK, 3)})
    for tk in (0, 20, 40, 60):
        leg(reeks, e, 0.2 + (tk + D) * TICK)
        momenten.append({"wie": "echo", "tick": tk + D, "s": round(0.2 + (tk + D) * TICK, 3)})
    tp = f2.true_peak_db(reeks[:, None])
    if tp > TP_GRENS:  # alleen de controle; het sample zelf blijft ongemoeid
        reeks *= 10 ** ((TP_GRENS - tp) / 20)
    p3 = os.path.join(DOC_UIT, "pompslag_controle_s6_reeks_placeholder.wav")
    f2.schrijf_wav(p3, reeks)
    uit["pompslag_controle_s6_reeks_placeholder.wav"] = {
        "pad": os.path.relpath(p3, ROOT), "momenten": momenten,
        "gain_db_tegen_clippen": round(min(0.0, TP_GRENS - tp), 2),
        "true_peak_dbtp": round(f2.true_peak_db(reeks[:, None]), 2), "sha256": sha(p3),
    }
    with open(os.path.join(DOC_UIT, "meting_placeholder.json"), "w") as fh:
        json.dump(uit, fh, indent=1, ensure_ascii=False)
    print(json.dumps(uit, indent=1, ensure_ascii=False))


if __name__ == "__main__":
    main()
