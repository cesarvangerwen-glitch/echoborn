#!/usr/bin/env python3
"""T8d deel 2 (#86): wat op de staart D = 60 vastzit, placeholder.

Bouwt op deel 1 (`genereer_slice_sfx.py`, zelfde map) en het F2-script
(`docs/audio/f2-fragment/bron/genereer_f2.py`): dezelfde klokken, hetzelfde
water, dezelfde echo-keten. Alles eigen synthese (numpy/scipy), geen samples.

Vier delen (`docs/audio/slice-audio.md` §5, §7):
  1. Merk-aftelling op D = 60 (bible §6.1, §10 `MerkAudio`; slice-audio §3.1):
     slagen op t 30/45/60/75, doven op t 90, knal op D + 3 = 63.
  2. Echo-varianten van de lichaamsgeluiden (bible §4, `echo_versie`) met een
     omgekeerde aanloop van 12 ticks (was 0,35 s = 21 ticks), afgestemd op D = 60.
  3. Boss-stems (slice-audio §4.4): fase 1 120 BPM 4/4, 16 maten = 32 s; fase 2
     120 BPM 3/4, 16 maten = 24 s; OGG met loop over het hele bestand.
  4. Speler geraakt (VJ-02, <= 45 ticks) en de slag van speler 2 (ijzer en glas, A5).

Opnieuw maken, vanaf de repo-root:
    python3 docs/audio/t8d-slice/bron/genereer_slice_deel2.py
Nodig: numpy, scipy, ffmpeg met libvorbis (OGG). Vaste seeds: de WAV-bestanden
zijn bit voor bit opnieuw te maken; de OGG-bestanden hangen van de ffmpeg-versie af.

Schrijft:
    game/audio/sfx/combat/*.wav          aftelling, merk_zet, merk_dooft, doelstreep-voorslag
    game/audio/sfx/speler/*.wav          p1_slag, p1_sprong, p1_landing, p2_slag, geraakt
    game/audio/sfx/echo/*.wav            echo-varianten
    game/audio/muziek/kadewijk/*.ogg     boss-stems
    (+ een .import per bestand, in het formaat van Godot 4.6; zie IMPORT_*)
    docs/audio/t8d-slice/deel2/aftelling_d60_controle_placeholder.wav (4 situaties uit §3.1)
    docs/audio/t8d-slice/deel2/boss_stems_samen_placeholder.ogg       (2 × 2 lussen achter elkaar)
    docs/audio/t8d-slice/deel2/meting_placeholder.json
"""
import hashlib
import importlib.util
import json
import os
import shutil
import subprocess
import sys

import numpy as np
from scipy import signal
from scipy.io import wavfile

sys.dont_write_bytecode = True
HIER = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HIER, "..", "..", "..", ".."))
GAME = os.path.join(ROOT, "game")
DOC = os.path.join(ROOT, "docs", "audio", "t8d-slice", "deel2")

_spec = importlib.util.spec_from_file_location("slice1", os.path.join(HIER, "genereer_slice_sfx.py"))
s1 = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(s1)  # laadt ook het F2-script; schrijft niets
f2 = s1.f2
f2.rng = np.random.default_rng(8602)  # klok(), landing() en ontploffing() lezen deze globale rng
r = np.random.default_rng(862)

SR, TICK = f2.SR, f2.TICK
n, tijd, filt, fade, leg, klok = f2.n, f2.tijd, f2.filt, f2.fade, f2.leg, f2.klok

D = 60                 # staart in ticks (besluit 2026-11-12)
L_SOLO = D + 30        # levensduur van een merk solo (E-14b, bible §6.1)
L_COOP = 150           # co-op (C-12e)
KNAL = D + 3           # E-02m
VOOR_TICKS = 12        # omgekeerde aanloop van de echo bij D = 60 (was 21 ticks)
TP_GRENS = -1.5


def tk(t):
    return t * TICK


# ============================================================ meten
def momentaan_max(x):
    return s1.momentaan_max(x)


def peil(x, doel):
    return s1.peil(x, doel)


def tp(x):
    return f2.true_peak_db(x if x.ndim == 2 else x[:, None])


def meet(x):
    m = s1.meet(x)
    m["clipping_samples"] = int(np.sum(np.abs(x) >= 32767 / 32768))
    return m


def aanzet_tick(x, drempel_db=-20.0):
    """Eerste sample waar de omhullende binnen 20 dB van de piek komt, in ticks."""
    m = x.mean(axis=1) if x.ndim == 2 else x
    om = np.abs(signal.hilbert(m))
    om = np.convolve(om, np.ones(n(0.002)) / n(0.002), mode="same")
    i = int(np.argmax(om >= om.max() * 10 ** (drempel_db / 20)))
    return round(i / SR / TICK, 2)


# ============================================================ schrijven + .import
def uid_voor(res_pad):
    """Vaste uid per pad (zelfde tekstvorm als ResourceUID::id_to_text, basis 36)."""
    v = int(hashlib.sha256(res_pad.encode()).hexdigest()[:16], 16) & ((1 << 63) - 1)
    tekens = ""
    while True:
        c = v % 36
        tekens = (chr(97 + c) if c < 26 else chr(48 + c - 26)) + tekens
        v //= 36
        if v == 0:
            break
    return "uid://" + tekens


IMPORT_WAV = """[remap]

importer="wav"
type="AudioStreamWAV"
uid="{uid}"
path="res://.godot/imported/{naam}-{md5}.sample"

[deps]

source_file="{res}"
dest_files=["res://.godot/imported/{naam}-{md5}.sample"]

[params]

force/8_bit=false
force/mono=false
force/max_rate=false
force/max_rate_hz=44100
edit/trim=false
edit/normalize=false
edit/loop_mode=0
edit/loop_begin=0
edit/loop_end=-1
compress/mode=2
"""

IMPORT_OGG = """[remap]

importer="oggvorbisstr"
type="AudioStreamOggVorbis"
uid="{uid}"
path="res://.godot/imported/{naam}-{md5}.oggvorbisstr"

[deps]

source_file="{res}"
dest_files=["res://.godot/imported/{naam}-{md5}.oggvorbisstr"]

[params]

loop=true
loop_offset=0
bpm={bpm}
beat_count={beats}
bar_beats={maat}
"""


def schrijf_import(pad, sjabloon, **extra):
    res = "res://" + os.path.relpath(pad, GAME).replace(os.sep, "/")
    naam = os.path.basename(pad)
    md5 = hashlib.md5(res.encode()).hexdigest()
    with open(pad + ".import", "w", newline="\n") as fh:
        fh.write(sjabloon.format(uid=uid_voor(res), naam=naam, md5=md5, res=res, **extra))


def schrijf_sfx(fam, naam, x):
    d = os.path.join(GAME, "audio", "sfx", fam)
    os.makedirs(d, exist_ok=True)
    pad = os.path.join(d, f"{naam}_placeholder.wav")
    f2.schrijf_wav(pad, x)
    schrijf_import(pad, IMPORT_WAV)
    return pad


def lees(pad):
    sr, x = wavfile.read(pad)
    assert sr == SR
    return x.astype(np.float64) / 32768.0


# ============================================================ 1. merk-aftelling op D = 60
AFTEL_SEC = 1.0  # was 1,6 s: bij D = 60 valt de knal 33 ticks na slag 1; korter = schonere knal


def aftel(i, grijs):
    y = klok(f2.AFTEL_TONEN[i], AFTEL_SEC, grootte=0.55, grijs=grijs, helder=0.75, slag=0.8)
    return fade(y, 0, 0.35)


# niveau (max. momentaan, LUFS): de verhoudingen van de F2-levensduurreeks
# (-6 / -4,5 / -3 / -9 dB, merk_zet -9, doven -6) rond slag 3 = -16 (onder TELL -15, onder KNAL -13)
AFTEL_NIVEAU = {"aftelling_1": -19.0, "aftelling_2": -17.5, "aftelling_3": -16.0, "aftelling_4_zacht": -22.0}


def maak_aftelling():
    uit, klank = {}, {}
    for kleur in ("grijs", "kleur"):
        g = kleur == "grijs"
        for i, naam in enumerate(("aftelling_1", "aftelling_2", "aftelling_3")):
            klank[f"{naam}_{kleur}"] = peil(aftel(i, g), AFTEL_NIVEAU[naam])
        # slag 4: de leidtoon C#6 nog eens, 6 dB zachter dan slag 3 (bible §6.1)
        klank[f"aftelling_4_zacht_{kleur}"] = peil(aftel(2, g), AFTEL_NIVEAU["aftelling_4_zacht"])
        klank[f"merk_zet_{kleur}"] = peil(f2.merk_zet(g), -22.0)
        # voorslag: dezelfde als deel 1 (byte-gelijk overgenomen), nu in game/
        klank[f"doelstreep_voorslag_{kleur}"] = lees(os.path.join(
            s1.SFX, "signalen", f"doelstreep_voorslag_{kleur}_placeholder.wav"))
    klank["merk_dooft"] = peil(f2.dooft(), -19.0)
    for naam, x in klank.items():
        schrijf_sfx("combat", naam, x)
        uit[naam] = {"bestand": f"game/audio/sfx/combat/{naam}_placeholder.wav", **meet(x),
                     "aanzet_ticks": aanzet_tick(x)}
    return uit, klank


def controle_aftelling(k):
    """De vier situaties van slice-audio §3.1 bij D = 60, achter elkaar (grijs).
    Elke situatie start op een hele tick; de momenten worden teruggemeten."""
    ontpl = lees(os.path.join(s1.SFX, "merk", "ontploffing_k1_grijs_placeholder.wav"))
    pauze = 1.4
    sit = [
        ("A geen doelstreep (echo Leeg)", L_SOLO,
         [("merk_zet_grijs", 0), ("aftelling_1_grijs", 30), ("aftelling_2_grijs", 45), ("aftelling_3_grijs", 60),
          ("aftelling_4_zacht_grijs", 75), ("merk_dooft", L_SOLO)], None, None),
        ("B doelstreep op dit merk", KNAL,
         [("merk_zet_grijs", 0), ("aftelling_1_grijs", 30), ("ontploffing_k1_grijs", KNAL)], 33, None),
        ("C streep weg op t 50", L_SOLO,
         [("merk_zet_grijs", 0), ("aftelling_1_grijs", 30), ("aftelling_3_grijs", 60),
          ("aftelling_4_zacht_grijs", 75), ("merk_dooft", L_SOLO)], 33, 50),
        ("D co-op (150 t, geen echo)", L_COOP,
         [("merk_zet_grijs", 0), ("aftelling_1_grijs", 90), ("aftelling_2_grijs", 105), ("aftelling_3_grijs", 120),
          ("aftelling_4_zacht_grijs", 135), ("merk_dooft", L_COOP)], None, None),
    ]
    klanken = dict(k)
    klanken["ontploffing_k1_grijs"] = ontpl
    delen, log = [], []
    t_abs = 0.0
    for titel, eind, events, voor_start, weg in sit:
        sec = tk(eind) + 1.6
        y = np.zeros(n(sec))
        gemeten = []
        for naam, tick in events:
            leg(y, klanken[naam], tk(tick))
            los = np.zeros(n(sec))
            leg(los, klanken[naam], tk(tick))
            gemeten.append({"event": naam, "tick": tick, "aanzet_gemeten_tick": aanzet_tick(los)})
        if voor_start is not None:
            v = klanken["doelstreep_voorslag_grijs"].copy()
            if weg is not None:  # 30 ms uitfaden op de tick waarop de streep verdwijnt
                j = n(tk(weg - voor_start))
                v[j:j + n(0.03)] *= np.linspace(1, 0, n(0.03))
                v[j + n(0.03):] = 0
            leg(y, v, tk(voor_start))
            nz = np.nonzero(np.abs(v) > 1e-4)[0]
            gemeten.append({"event": "doelstreep_voorslag_grijs", "tick": voor_start,
                            "einde_gemeten_tick": round((tk(voor_start) + (nz[-1] + 1) / SR) / TICK, 2)})
        log.append({"situatie": titel, "start_s": round(t_abs, 3), "events": gemeten})
        delen.append(y)
        delen.append(np.zeros(n(pauze)))
        t_abs += sec + pauze
    x = np.concatenate(delen)
    x = x * 10 ** ((TP_GRENS - 0.2 - tp(x)) / 20) if tp(x) > TP_GRENS else x
    os.makedirs(DOC, exist_ok=True)
    f2.schrijf_wav(os.path.join(DOC, "aftelling_d60_controle_placeholder.wav"), x)
    return {"bestand": "docs/audio/t8d-slice/deel2/aftelling_d60_controle_placeholder.wav",
            "duur_s": round(len(x) / SR, 2), "true_peak_dbtp": round(tp(x), 1), "situaties": log}


# ============================================================ 2. echo-varianten (bible §4)
def echo_versie_d60(x, verzwakking_db, voor_ticks=VOOR_TICKS, stereo=True):
    """f2.echo_versie met een omgekeerde aanloop van voor_ticks (exact) in plaats
    van 0,35 s. De rest van de keten is gelijk: hoogdoorlaat 260 Hz (4e orde),
    holle kam 4,6 ms + band 0,7-4,2 kHz, galm 'verzonken' achterstevoren, Haas 11 ms."""
    droog = filt(x, "highpass", 260, 4)
    hol = 0.55 * f2.comb_hol(droog) + 0.45 * filt(droog, "bandpass", [700, 4200], 2)
    k = int(round(voor_ticks * TICK * SR))
    staart = signal.fftconvolve(droog, f2.IR_VERZONKEN[:, 0])[:k]
    voor = fade(staart[::-1], tk(voor_ticks) * 0.35, 0.0) * 0.35
    y = np.concatenate([voor, hol]) * 10 ** (verzwakking_db / 20)
    if not stereo:
        return y
    return np.stack([y, np.concatenate([np.zeros(n(0.011)), y])[: len(y)]], axis=1)


def p2_slag():
    """Speler 2 (cyaan) = ijzer en glas (A5): zijn pikhaak. Zelfde opbouw als
    p1_slag (zwaai, klik, materiaal, lijf), maar een ijzeren staaf (inharmonische
    modi 1 : 2,76 : 5,40 : 8,93) en een glazen naklank in plaats van hout en koper."""
    sec = 0.5
    t = tijd(sec)
    i0 = n(0.06)
    tt = t[: len(t) - i0]
    nz = r.standard_normal(len(t))
    sweep = np.interp(t, [0, 0.03, 0.07, sec], [700, 1600, 4800, 3200])
    zwaai = f2.svf_bandpass(nz, sweep, 2.4) * np.interp(t, [0, 0.03, 0.058, 0.11, sec], [0, 0.5, 1.0, 0.08, 0])
    klik = np.zeros(len(t))
    kk = n(0.001)
    klik[i0:i0 + kk] = filt(r.standard_normal(kk), "highpass", 3000, 2) * np.linspace(1, 0, kk)
    ijzer = np.zeros(len(t))
    for verh, a, tau in ((1.0, 0.7, 0.09), (2.756, 0.5, 0.06), (5.404, 0.3, 0.04), (8.933, 0.16, 0.025)):
        ijzer[i0:] += a * np.exp(-tt / tau) * np.sin(2 * np.pi * 412 * verh * tt + r.uniform(0, 6.3))
    glas = np.zeros(len(t))
    for fr, a, tau in ((2963, 0.12, 0.22), (4471, 0.08, 0.17), (6702, 0.04, 0.11)):
        glas[i0:] += a * np.exp(-tt / tau) * np.sin(2 * np.pi * fr * tt + r.uniform(0, 6.3))
    lijf = np.zeros(len(t))
    lijf[i0:] = np.sin(2 * np.pi * np.cumsum(60 * np.exp(-tt / 0.04) + 88) / SR) * np.exp(-tt / 0.045)
    y = 0.5 * zwaai + 1.0 * klik + 0.75 * ijzer + 0.55 * glas + 0.45 * lijf
    return fade(y, 0.002, 0.06)


def geraakt(wie):
    """Speler geraakt (VJ-02): een doffe stoot in het lijf, het eigen materiaal
    dat even 'scheef' klinkt (een kleine secunde erbij) en de adem eruit. 40 ticks:
    korter dan de 45 ticks onkwetsbaarheid, dus nooit twee tegelijk."""
    sec = tk(40)
    t = tijd(sec)
    y = 0.5 * np.sin(2 * np.pi * np.cumsum(80 * np.exp(-t / 0.03) + 70) / SR) * np.exp(-t / 0.07)
    y += 0.5 * filt(r.standard_normal(len(t)), "lowpass", 900, 2) * f2.env_ad(sec, 0.001, 0.03)
    basis = 238 if wie == "p1" else 412
    for fr in (basis * 2, basis * 2 * 2 ** (1 / 12)):  # de kleine secunde: iets klopt niet
        y += 0.4 * np.exp(-t / 0.12) * np.sin(2 * np.pi * fr * t + r.uniform(0, 6.3))
    if wie == "p2":
        y += 0.1 * np.exp(-t / 0.1) * np.sin(2 * np.pi * 2963 * 1.02 * t)
    adem = filt(r.standard_normal(len(t)), "bandpass", [700, 2600], 2) * np.interp(t, [0, 0.03, 0.25, sec], [0, 0.22, 0.04, 0])
    return s1.kap(fade(y + adem, 0.0005, 0.15), sec)


LEVEND = {  # naam: (functie, niveau LUFS momentaan, echo-verzwakking dB of None)
    "p1_slag": (f2.p1_slag, -16.0, -7.0),
    "p1_sprong": (f2.sprong, -24.0, -8.0),
    "p1_landing": (f2.landing, -22.0, -8.0),
    "p2_slag": (p2_slag, -16.0, None),          # co-op: geen echo, dus geen echo-variant
    "p1_geraakt": (lambda: geraakt("p1"), -15.0, None),
    "p2_geraakt": (lambda: geraakt("p2"), -15.0, None),
}


def maak_speler_en_echo():
    uit = {}
    for naam, (fn, doel, echo_db) in LEVEND.items():
        x = peil(fn(), doel)
        schrijf_sfx("speler", naam, x)
        uit[naam] = {"bestand": f"game/audio/sfx/speler/{naam}_placeholder.wav", **meet(x)}
        if echo_db is None:
            continue
        e = echo_versie_d60(x, echo_db)  # zelfde gain als levend; dan de -7 / -8 dB van bible §4
        if tp(e) > TP_GRENS:
            e = e * 10 ** ((TP_GRENS - tp(e)) / 20)
        en = "echo_" + naam[3:]
        schrijf_sfx("echo", en, e)
        uit[en] = {"bestand": f"game/audio/sfx/echo/{en}_placeholder.wav", **meet(e),
                   "aanloop_ticks": VOOR_TICKS,
                   "verschil_met_levend_lu": round(momentaan_max(e) - momentaan_max(x), 1)}
    # rad-treffer van de echo (bible §4.1: via echo_versie, bus Echo; nooit _2). Mono: AudioStreamPlayer2D op het rad
    rad = lees(os.path.join(s1.SFX, "gemaalmeester", "gm_rad_treffer_1_placeholder.wav"))
    e = echo_versie_d60(rad, -7.0, stereo=False)
    schrijf_sfx("echo", "echo_gm_rad_treffer_1", e)
    uit["echo_gm_rad_treffer_1"] = {"bestand": "game/audio/sfx/echo/echo_gm_rad_treffer_1_placeholder.wav", **meet(e),
                                    "aanloop_ticks": VOOR_TICKS,
                                    "verschil_met_levend_lu": round(momentaan_max(e) - momentaan_max(rad), 1)}
    return uit


def controle_echo_reeks():
    """P1 slaat om de 20 ticks (LM-04, snelste ritme); de echo herhaalt D = 60 later.
    Telt hoe vaak de aanloop van echo-slag k vóór echo-slag k-1 begint (moet 0 zijn)."""
    res = {}
    for voor in (21, VOOR_TICKS):
        overlap = sum(1 for k in range(1, 4) if (60 + 20 * k - voor) < (60 + 20 * (k - 1)))
        res[f"aanloop_{voor}_ticks"] = {"aandeel_van_D_pct": round(100 * voor / D), "aanlopen_voor_vorige_slag": overlap}
    return res


# ============================================================ 3. boss-stems (slice-audio §4.4)
BPM = 120
TEL = 60 / BPM          # 0,5 s = 30 ticks
D2, A2, D3, A3 = 73.42, 110.0, 146.83, 220.0
M2 = [293.66, 277.18, 246.94, 220.0]  # D4 C#4 B3 A3: M1 omgekeerd en dalend


def vouw(y, sec):
    """Naadloze lus: alles na sec (galm, staarten) wordt over het begin gelegd."""
    k = n(sec)
    uit = y[:k].copy()
    rest = y[k:]
    while len(rest):
        m = min(k, len(rest))
        uit[:m] += rest[:m]
        rest = rest[m:]
    return uit


def stereo_galm(y, nat, breed_ms=6):
    st = np.stack([y, np.concatenate([np.zeros(n(breed_ms / 1000)), y])[: len(y)]], axis=1)
    return st + f2.galm(st, f2.IR_VERZONKEN, nat)


def stem_harmonium(maat_tellen, octaaf):
    """M2 in het laag van het harmonium, zonder terts (lege kwint D-A onder).
    16 maten: vier frasen van 4 maten, één noot van M2 per maat; frase 3 en 4
    met de noot op tel 1 en een herhaling op de laatste tel (meer drang)."""
    maat = maat_tellen * TEL
    sec = 16 * maat
    y = np.zeros(n(sec + 4))
    # bourdon: 1 s langer, met 1 s uitfaden; na het vouwen valt dat over de inzet van 1 s (geen stap)
    leg(y, fade(f2.harmonium(D2, sec + 1.0, helder=0.5, inzet=1.0), 0, 1.0) * 0.5, 0.0)
    leg(y, fade(f2.harmonium(A2, sec + 1.0, helder=0.5, inzet=1.0), 0, 1.0) * 0.35, 0.0)
    for m in range(16):
        f = M2[m % 4] * octaaf
        t0 = m * maat
        if m < 8:
            leg(y, fade(f2.harmonium(f, maat - 0.05, helder=0.7), 0.02, 0.12) * 0.55, t0)
        else:
            leg(y, fade(f2.harmonium(f, maat - TEL - 0.05, helder=0.8), 0.02, 0.08) * 0.6, t0)
            leg(y, fade(f2.harmonium(f, TEL - 0.06, helder=0.8), 0.01, 0.05) * 0.45, t0 + maat - TEL)
    # adem van de lus: een lange zwelling per frase van 4 maten
    t = tijd(len(y) / SR)
    y *= 0.85 + 0.15 * np.sin(2 * np.pi * t / (4 * maat) - np.pi / 2) ** 2
    return vouw(stereo_galm(filt(y, "highpass", 45, 2), 0.3), sec)


def plof(sec=0.6):
    t = tijd(sec)
    return np.sin(2 * np.pi * np.cumsum(50 * np.exp(-t / 0.12) + 46) / SR) * np.exp(-t / 0.16)


def ijzertik(sec=0.4):
    t = tijd(sec)
    y = sum(a * np.exp(-t / tau) * np.sin(2 * np.pi * fr * t + r.uniform(0, 6))
            for fr, a, tau in ((310, 0.25, 0.08), (742, 0.18, 0.05), (1214, 0.12, 0.03), (1987, 0.06, 0.02)))
    return fade(y, 0.0005, 0.05)


def houtklop(sec=0.15):
    return s1.modi([(612, 0.5, 0.025), (1340, 0.3, 0.015), (2210, 0.12, 0.01)], sec, 0, 0.01)


def schoepwater(sec=0.45):
    t = tijd(sec)
    st = filt(r.standard_normal(len(t)), "bandpass", [280, 1600], 2) * np.interp(t, [0, 0.05, 0.15, sec], [0, 0.6, 0.3, 0])
    spat = np.zeros(len(t))
    for _ in range(6):
        leg(spat, f2.bel(r.uniform(400, 1500), r.uniform(0.2, 0.5)), r.uniform(0.02, 0.2))
    return st + 0.3 * spat


def stem_ritme(maat_tellen):
    """Gemaalritme (bible §6.3). Tel 1 alleen een lage plof (de carillon-tel van
    het SFX, gm_maat_tel D4, blijft vrij: tells eerst, bible §8); 4/4: ijzertik op
    tel 2 en 4, houtklop op de achtsten; 3/4: water van de schoepen op tel 2 en 3."""
    maat = maat_tellen * TEL
    sec = 16 * maat
    y = np.zeros(n(sec + 4))
    for m in range(16):
        t0 = m * maat
        leg(y, plof(), t0, 0.35)
        leg(y, ijzertik(), t0, 0.3)  # de as tikt mee op tel 1: de plof alleen hoor je niet op de Deck
        for tel in range(1, maat_tellen):
            if maat_tellen == 4:
                leg(y, ijzertik() if tel % 2 else houtklop(), t0 + tel * TEL, 0.9 if tel % 2 else 0.6)
            else:
                leg(y, schoepwater(), t0 + tel * TEL, 1.0)
        for a in range(maat_tellen):  # zachte houtklop op de achtsten (de tweede helft van elke tel)
            leg(y, houtklop(), t0 + a * TEL + TEL / 2, 0.3 * r.uniform(0.8, 1.0))
    t = tijd(len(y) / SR)
    y += 0.015 * sum(np.sin(2 * np.pi * 50 * h * t) / h for h in (1, 2, 3))  # brom van het gemaal
    return vouw(stereo_galm(filt(y, "highpass", 45, 2), 0.25, 3), sec)


STEM_NIVEAU = -27.0  # geïntegreerd per stem; samen ± -24 LUFS (bed 5-6 LU onder -18, bible §8)


def ogg(pad_wav, pad_ogg):
    subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-i", pad_wav, "-c:a", "libvorbis", "-q:a", "5",
                    pad_ogg], check=True)


def decodeer(pad):
    p = subprocess.run(["ffmpeg", "-loglevel", "error", "-i", pad, "-f", "f32le", "-ac", "2", "-ar", str(SR), "-"],
                       check=True, capture_output=True)
    return np.frombuffer(p.stdout, dtype=np.float32).reshape(-1, 2).astype(np.float64)


def naad(x):
    """Lusnaad na decoderen. (1) De 250 ms rond de naad (eind + begin) tegenover de 250 ms
    rond de maatgrens halverwege (maat 8 -> 9): zelfde muzikale plek, dus ± 0 dB als de lus
    klopt. (2) De sprong tussen het laatste en het eerste sample tegenover de gewone sprong
    tussen twee samples (99e percentiel): kleiner = geen klik."""
    k = n(0.125)
    rond = np.concatenate([x[-k:], x[:k]])
    h = len(x) // 2
    midden = x[h - k:h + k]
    rms = lambda v: np.sqrt(np.mean(v ** 2)) + 1e-12
    sprong = np.max(np.abs(x[0] - x[-1]))
    gewoon = np.percentile(np.max(np.abs(np.diff(x, axis=0)), axis=1), 99)
    return {"naad_tegen_maatgrens_midden_db": round(float(20 * np.log10(rms(rond) / rms(midden))), 2),
            "sprong_over_naad": round(float(sprong), 5), "sprong_99e_pct_elders": round(float(gewoon), 5)}


def maak_stems():
    uit = {}
    d = os.path.join(GAME, "audio", "muziek", "kadewijk")
    os.makedirs(d, exist_ok=True)
    os.makedirs(DOC, exist_ok=True)
    stems = {
        "boss_fase1_harmonium": (lambda: stem_harmonium(4, 1.0 / 2), 4),   # laag: D3 C#3 B2 A2
        "boss_fase1_ritme": (lambda: stem_ritme(4), 4),
        "boss_fase2_harmonium": (lambda: stem_harmonium(3, 1.0), 3),       # een octaaf hoger
        "boss_fase2_ritme": (lambda: stem_ritme(3), 3),
    }
    gedecodeerd = {}
    for naam, (fn, tellen) in stems.items():
        x = fn()
        x = x * 10 ** ((STEM_NIVEAU - f2.lufs_geintegreerd(x)) / 20)
        if tp(x) > TP_GRENS - 0.5:
            x = x * 10 ** ((TP_GRENS - 0.5 - tp(x)) / 20)
        tmp = os.path.join(DOC, f"_{naam}.wav")
        f2.schrijf_wav(tmp, x)
        pad = os.path.join(d, f"{naam}_placeholder.ogg")
        ogg(tmp, pad)
        os.remove(tmp)
        schrijf_import(pad, IMPORT_OGG, bpm=BPM, beats=16 * tellen, maat=tellen)
        g = decodeer(pad)
        gedecodeerd[naam] = g
        uit[naam] = {"bestand": f"game/audio/muziek/kadewijk/{naam}_placeholder.ogg",
                     "maat": f"{tellen}/4", "maten": 16, "bpm": BPM,
                     "duur_s_bron": round(len(x) / SR, 4), "duur_ticks_bron": round(len(x) / SR / TICK, 1),
                     "samples_na_decoderen": len(g), "samples_verwacht": len(x),
                     "lufs_geintegreerd": round(f2.lufs_geintegreerd(g), 1), "true_peak_dbtp_na_decoderen": round(tp(g), 1),
                     "aandeel_boven_250hz_pct": s1.meet(g)["aandeel_boven_250hz_pct"],
                     "lusnaad": naad(g), "kb": round(os.path.getsize(pad) / 1024)}
    for fase in ("fase1", "fase2"):
        a, b = gedecodeerd[f"boss_{fase}_harmonium"], gedecodeerd[f"boss_{fase}_ritme"]
        m = min(len(a), len(b))
        som = a[:m] + b[:m]
        uit[f"_samen_{fase}"] = {"lufs_geintegreerd": round(f2.lufs_geintegreerd(som), 1),
                                 "true_peak_dbtp": round(tp(som), 1), "lusnaad": naad(som)}
    # luisterbestand: elke fase twee keer rond (de naad zit midden in elk deel), fase 1 -> fase 2
    delen = []
    for fase in ("fase1", "fase2"):
        a, b = gedecodeerd[f"boss_{fase}_harmonium"], gedecodeerd[f"boss_{fase}_ritme"]
        m = min(len(a), len(b))
        delen += [a[:m] + b[:m]] * 2
    luister = np.concatenate(delen)
    tmp = os.path.join(DOC, "_samen.wav")
    f2.schrijf_wav(tmp, luister)
    ogg(tmp, os.path.join(DOC, "boss_stems_samen_placeholder.ogg"))
    os.remove(tmp)
    uit["_luisterbestand"] = {"bestand": "docs/audio/t8d-slice/deel2/boss_stems_samen_placeholder.ogg",
                              "duur_s": round(len(luister) / SR, 1),
                              "naden_op_s": [32.0, 64.0, 88.0], "fase2_vanaf_s": 64.0}
    return uit


def main():
    if not shutil.which("ffmpeg"):
        sys.exit("ffmpeg met libvorbis is nodig voor de OGG-stems")
    uitkomst = {"_werkaanname": {"D_ticks": D, "merk_solo_ticks": L_SOLO, "merk_coop_ticks": L_COOP, "knal_tick": KNAL,
                                 "echo_aanloop_ticks": VOOR_TICKS, "bpm": BPM}}
    a, klank = maak_aftelling()
    uitkomst["aftelling"] = a
    uitkomst["aftelling_controle"] = controle_aftelling(klank)
    uitkomst["speler_en_echo"] = maak_speler_en_echo()
    uitkomst["echo_aanloop_bij_lm04"] = controle_echo_reeks()
    uitkomst["boss_stems"] = maak_stems()
    with open(os.path.join(DOC, "meting_placeholder.json"), "w") as fh:
        json.dump(uitkomst, fh, indent=1, ensure_ascii=False)
    print(json.dumps(uitkomst, indent=1, ensure_ascii=False))


if __name__ == "__main__":
    sys.exit(main())
