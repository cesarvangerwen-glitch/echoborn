#!/usr/bin/env python3
"""Het luik breekt (#243, bible v0.5 §4.1, gdd V-01d/e), placeholder.

Eén bestand voor P1, P2 en de echo, zonder echo-variant en zonder
toonverschil (bible §4.1, §11; `luik_audio.gd` speelt het met `pitch_scale`
1,0 op bus SFX). Het klinkt ook zo als de echo met zijn neerslag de
**schaduwklep** wegslaat (V-01d): dat is breken, dus hetzelfde geluid. Gaat
de schaduwklep vanzelf weg ("tijd"), dan speelt de code niets.

Klank: een eiken luik met een scheur (L-03, art `slice-kadewijk.md` §10/§11)
dat onder een neerslag doorbreekt, droog (geen water: dat is de pompslag).
De aanslag valt op sample 0, de tick van `opened` / `schaduwklep_weg`
(framexact, bible §10, geen aanloop):
  1. de klap van de neerslag op het hout (plof 120 -> 60 Hz, het lijf);
  2. de scheur die openbarst: een korte reeks krakende breuken (0-90 ms),
     elke breuk een klik met houtmodi die per plank anders liggen;
  3. splinters tot ± 11 kHz (1,2 % boven 8 kHz); een objectgeluid, geen lichaam;
  4. het ijzeren beslag dat losschiet: één ring/scharnier-tik (A5-familie
     vermeden; inharmonisch, geen klok, bible §8.5);
  5. planken die beneden neerkomen: twee doffe houtklopjes op 260 en 330 ms
     (P1 valt erdoor, de stukken ook), en wat gruis.
Lijf onder 250 Hz, maar >= 35 % van de energie erboven (Deck, bible §8.2).

Eisen (eigen, naar slice-audio.md §1): max. momentane loudness -15 LUFS
(400 ms; tussen treffers -17 en knallen -13: een poort die opengaat), true
peak <= -1,5 dBTP, >= 35 % boven 250 Hz, duur 42 ticks (0,7 s).

Alles is eigen synthese (numpy/scipy), geen externe samples. Vaste seed:
het WAV-bestand is bit voor bit opnieuw te maken.

Opnieuw maken, vanaf de repo-root:
    python3 audio-bron/sfx/omgeving/genereer_luik_breekt.py

Schrijft:
    game/audio/sfx/omgeving/luik_breekt_placeholder.wav   (48 kHz, 16 bit, mono)
    docs/audio/luik-rad/meting_placeholder.json           (samen met zet_gm_rad_treffer.py)
Het .import-bestand maakt Godot 4.6.3 (`godot --headless --path game --import`).
"""
import hashlib
import importlib.util
import json
import os
import sys

import numpy as np

HIER = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(os.path.dirname(HIER)))
GAME_UIT = os.path.join(ROOT, "game", "audio", "sfx", "omgeving")
DOC_UIT = os.path.join(ROOT, "docs", "audio", "luik-rad")

sys.dont_write_bytecode = True
_spec = importlib.util.spec_from_file_location("pompslag", os.path.join(HIER, "genereer_pompslag_schoep.py"))
ps = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(ps)  # laadt ook het F2-script; schrijft niets
f2 = ps.f2

SR, TICK = f2.SR, f2.TICK
n, tijd, filt, fade, leg = f2.n, f2.tijd, f2.filt, f2.fade, f2.leg

DUUR_TICKS = 42
DOEL_MOMENTAAN = -15.0  # LUFS
TP_GRENS = -1.5  # dBTP

r = np.random.default_rng(2431)


def modi(lijst, sec, spreid=0.0):
    t = tijd(sec)
    y = np.zeros(len(t))
    for f, a, tau in lijst:
        f *= 1 + r.uniform(-spreid, spreid)
        y += a * np.exp(-t / tau) * np.sin(2 * np.pi * f * t + r.uniform(0, 6.3))
    return y


def klik(sec, lo, hi, ms):
    k = max(2, n(ms / 1000))
    y = np.zeros(n(sec))
    y[:k] = filt(r.standard_normal(k), "bandpass", [lo, hi], 2) * np.linspace(1, 0, k) ** 1.5
    return y


def breuk(sec, g):
    """Eén krakende breuk in een plank: klik + korte houtmodi (eik, droog)."""
    s = r.uniform(0.85, 1.2)
    y = 0.9 * klik(sec, 1200, 11000, r.uniform(0.8, 2.0))
    y += modi([(230 * s, 0.35, 0.018), (560 * s, 0.4, 0.014), (980 * s, 0.32, 0.011),
               (1570 * s, 0.22, 0.008), (2380 * s, 0.14, 0.006)], sec, 0.03)
    return g * y


def luik_breekt():
    sec = DUUR_TICKS * TICK
    t = tijd(sec)
    y = np.zeros(len(t))
    # 1. klap van de neerslag op het hout: het lijf
    plof = np.sin(2 * np.pi * np.cumsum(60 * np.exp(-t / 0.035) + 60) / SR) * np.exp(-t / 0.07)
    plof[: n(0.002)] *= np.linspace(0, 1, n(0.002))
    y += 0.75 * plof
    y += 0.8 * klik(sec, 600, 7000, 3.0)
    y += modi([(148, 0.5, 0.05), (331, 0.45, 0.035), (612, 0.3, 0.025)], sec, 0.01)  # het hele luik
    # 2. de scheur barst open: 9 breuken in 90 ms, de eerste het hardst
    tt = np.sort(np.concatenate([[0.0015], r.uniform(0.004, 0.09, 8)]))
    for i, t0 in enumerate(tt):
        leg(y, breuk(0.12, 1.0 * 0.8 ** i + 0.15), t0)
    # krakend geruis onder de breuken (vezels die scheuren)
    vezel = filt(r.standard_normal(len(t)), "bandpass", [700, 5000], 2)
    vezel *= np.interp(t, [0, 0.004, 0.05, 0.11, 0.16, sec], [0, 0.5, 0.35, 0.12, 0, 0])
    vezel *= 1 + 0.9 * np.sign(np.sin(2 * np.pi * 70 * t + 3 * np.sin(2 * np.pi * 23 * t)))  # rasp
    y += 0.35 * vezel
    # 3. splinters: heldere tikjes
    for _ in range(16):
        leg(y, 0.35 * r.uniform(0.3, 1.0) * klik(0.01, 3500, 11500, r.uniform(0.3, 0.8)), r.uniform(0.01, 0.22))
    # 4. het beslag schiet los: één inharmonische ijzertik
    ijzer = modi([(1873, 0.25, 0.09), (2911, 0.18, 0.07), (4430, 0.1, 0.04), (987, 0.12, 0.06)], 0.4, 0.004)
    ijzer += 0.4 * klik(0.4, 2000, 9000, 0.6)
    leg(y, 0.45 * ijzer, 0.035)
    # 5. de stukken komen beneden neer: twee doffe klopjes + gruis
    for t0, g in ((0.26, 0.42), (0.33, 0.28)):
        k = modi([(190, 0.6, 0.03), (420, 0.45, 0.022), (760, 0.25, 0.016)], 0.15, 0.06)
        k += 0.5 * klik(0.15, 400, 4000, 1.5)
        leg(y, g * k, t0)
    gruis = filt(r.standard_normal(len(t)), "bandpass", [1500, 8000], 2)
    gruis *= np.interp(t, [0, 0.05, 0.12, 0.35, 0.5, sec], [0, 0.0, 0.08, 0.05, 0.0, 0.0])
    y += gruis
    y = filt(y, "highpass", 45, 2)
    y = fade(y, 0.0, 0.15)
    y[-n(0.002):] = 0.0
    return y


def peil(x):
    x = x - np.mean(x)
    for _ in range(4):
        x = x * 10 ** ((DOEL_MOMENTAAN - ps.momentaan_max(x)) / 20)
        x = ps.begrens(x, TP_GRENS - 0.3)
    tp = f2.true_peak_db(x[:, None])
    if tp > TP_GRENS - 0.1:
        x = x * 10 ** ((TP_GRENS - 0.1 - tp) / 20)
    return x


def sha(pad):
    return hashlib.sha256(open(pad, "rb").read()).hexdigest()


def bij_meting(naam, data):
    os.makedirs(DOC_UIT, exist_ok=True)
    pad = os.path.join(DOC_UIT, "meting_placeholder.json")
    uit = {}
    if os.path.exists(pad):
        with open(pad) as fh:
            uit = json.load(fh)
    uit[naam] = data
    with open(pad, "w") as fh:
        json.dump(dict(sorted(uit.items())), fh, indent=1, ensure_ascii=False)
        fh.write("\n")


def main():
    os.makedirs(GAME_UIT, exist_ok=True)
    x = peil(luik_breekt())
    pad = os.path.join(GAME_UIT, "luik_breekt_placeholder.wav")
    f2.schrijf_wav(pad, x)
    x16 = np.round(x * 32767) / 32767
    data = {"pad": os.path.relpath(pad, ROOT), **ps.meet(x16), "ffmpeg_ebur128": ps.ebur128(pad),
            "aandeel_boven_8khz_pct": None, "sha256": sha(pad)}
    from scipy import signal
    f, p = signal.welch(x16, SR, nperseg=4096)
    data["aandeel_boven_8khz_pct"] = round(float(100 * np.sum(p[f >= 8000]) / np.sum(p)), 1)
    bij_meting("luik_breekt_placeholder.wav", data)
    print(json.dumps(data, indent=1, ensure_ascii=False))


if __name__ == "__main__":
    main()
