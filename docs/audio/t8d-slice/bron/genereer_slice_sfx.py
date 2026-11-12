#!/usr/bin/env python3
"""T8d deel 1 (#86): SFX-set van de slice, placeholder.

Alles is eigen synthese (numpy/scipy), zonder externe samples (bible §3,
`docs/licenties.md` §2). Bouwt verder op de bouwstenen van het F2-fragment
(`docs/audio/f2-fragment/bron/genereer_f2.py`: klok, bel, echo_versie,
ontploffing, ketting_klok, galm), zodat de slice uit dezelfde klokken en
hetzelfde water komt als het fragment dat de CEO "heel leuk" vond.

Alleen geluiden die NIET van de staart D afhangen (fasekader §2 T8d, §4 regel
2): tells, aanvallen, treffers, boss, finisher-bouwstenen en de twee
leesbaarheidssignalen. De merk-aftelling en alles wat op D vastzit, komt in
deel 2 (zie `docs/audio/slice-audio.md` §4).

Tijden in ticks (60 per s, `docs/tech/ontwerp.md` §2) uit
`docs/design/combat/slice-vijanden-en-boss.md` v0.1.1 (§2, §3, §9). Een
**aanloop**-bestand duurt precies zijn aanloop en eindigt op de tick waarop
het actieve vlak begint: start het op het begin van de aanloop, dan valt het
hoogtepunt vanzelf op de slag (framexact, bible §10).

Opnieuw maken, vanaf de repo-root:
    python3 docs/audio/t8d-slice/bron/genereer_slice_sfx.py

Schrijft naar docs/audio/t8d-slice/:
    sfx/<familie>/<naam>_placeholder.wav   (48 kHz, 16 bit, mono; finisher-slot stereo)
    luisterreeks_slice_sfx_placeholder.ogg (als ffmpeg er is; anders de .wav)
    luisterreeks_spectrogram_placeholder.png (als matplotlib er is)
    meting_placeholder.json                (duur, niveau, piek, aandeel > 250 Hz, ...)
Vaste seeds: de WAV-bestanden zijn bit voor bit opnieuw te maken.
"""
import importlib.util
import json
import os
import shutil
import subprocess
import sys

import numpy as np
from scipy import signal

HIER = os.path.dirname(os.path.abspath(__file__))
UIT = os.path.dirname(HIER)
SFX = os.path.join(UIT, "sfx")
F2_PAD = os.path.join(os.path.dirname(UIT), "f2-fragment", "bron", "genereer_f2.py")

sys.dont_write_bytecode = True  # geen __pycache__ naast het F2-script
_spec = importlib.util.spec_from_file_location("genereer_f2", F2_PAD)
f2 = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(f2)  # maakt alleen de galm-IR's; schrijft niets

SR, TICK = f2.SR, f2.TICK
n, tijd, filt, fade, norm, rmsnorm = f2.n, f2.tijd, f2.filt, f2.fade, f2.norm, f2.rmsnorm
klok, bel, svf_bandpass, comb_hol, env_ad = f2.klok, f2.bel, f2.svf_bandpass, f2.comb_hol, f2.env_ad

r = np.random.default_rng(86)


def tk(ticks):
    return ticks * TICK


def ruis(sec):
    return r.standard_normal(n(sec))


def roze(sec):
    w = np.fft.rfft(ruis(sec))
    fr = np.fft.rfftfreq(n(sec), 1 / SR)
    fr[0] = fr[1]
    return np.fft.irfft(w / np.sqrt(fr), n(sec))


def leg(y, sig, t0, g=1.0):
    i = n(t0)
    j = min(len(y), i + len(sig))
    if j > i:
        y[i:j] += g * sig[: j - i]


def modi(lijst, sec, t0=0.0, spreid=0.0):
    """Som van uitstervende sinussen: [(f, a, tau)], vanaf t0."""
    y = np.zeros(n(sec))
    i0 = n(t0)
    t = np.arange(len(y) - i0) / SR
    for f, a, tau in lijst:
        f *= 1 + r.uniform(-spreid, spreid)
        y[i0:] += a * np.exp(-t / tau) * np.sin(2 * np.pi * f * t + r.uniform(0, 6.3))
    return y


def klik(sec, t0, lo=1500, hi=9000, ms=1.5, g=1.0):
    y = np.zeros(n(sec))
    k = max(2, n(ms / 1000))
    leg(y, filt(r.standard_normal(k), "bandpass", [lo, hi], 2) * np.linspace(1, 0, k) * g, t0)
    return y


def lus(fn, sec, xf=0.25):
    """Naadloze lus: render sec + xf, vouw de staart over het begin."""
    y = fn(sec + xf)
    k = n(xf)
    a = np.sin(np.linspace(0, np.pi / 2, k)) ** 2
    y[:k] = y[:k] * a + y[n(sec) : n(sec) + k] * (1 - a)
    return y[: n(sec)]


def kap(y, sec):
    """Precies sec lang; de laatste 2 ms dicht (geen klik), het hoogtepunt blijft staan."""
    y = np.concatenate([y, np.zeros(max(0, n(sec) - len(y)))])[: n(sec)]
    k = n(0.002)
    y[-k:] *= np.linspace(1, 0, k)
    return y


# ============================================================ vijanden (§2, §9.1)
def kadeloper_aanloop():
    """Haak omhoog, ijzer schraapt over steen: stick-slip die versnelt en stijgt.
    30 ticks; eindigt op de eerste tick van het actieve vlak (haak op zijn top)."""
    sec = tk(30)
    t = tijd(sec)
    y = np.zeros(len(t))
    fase = 0.0
    tt = 0.0
    while tt < sec:
        rel = tt / sec
        rate = 22 + 60 * rel**1.4  # schokjes per s: versnelt
        g = n(0.004)
        korrel = r.standard_normal(g) * np.exp(-np.arange(g) / (g / 3))
        leg(y, korrel * (0.25 + 0.75 * rel**1.2) * r.uniform(0.6, 1.0), tt)
        tt += 1 / rate * r.uniform(0.75, 1.25)
    fc = np.interp(t, [0, sec], [700, 2000])
    y = svf_bandpass(y, fc, 3.5) + 0.08 * filt(y, "highpass", 3000, 2)
    # het ijzer zingt mee: een dunne toon die met de schraap omhoog gaat
    f = np.interp(t, [0, sec], [1180, 1650])
    zing = np.sin(2 * np.pi * np.cumsum(f) / SR) * np.interp(t, [0, 0.6 * sec, sec], [0, 0.10, 0.22])
    y = rmsnorm(y) * np.interp(t, [0, sec], [0.25, 1.0])
    y = np.tanh(1.2 * y) + zing  # de korrels zijn piekerig: zacht afronden, zodat de tell luid genoeg kan
    # haak op zijn top: één droge tik vlak voor het eind
    y += klik(sec, sec - 0.012, 2500, 9000, 2.0, 0.5)
    return kap(y, sec)


def kadeloper_haakslag():
    """Actief 6 ticks: de haak zwiept omlaag (dalende veeg) en het ijzer klinkt na."""
    sec = 0.4
    t = tijd(sec)
    sweep = np.interp(t, [0, tk(6), sec], [3400, 700, 500])
    veeg = svf_bandpass(ruis(sec), sweep, 2.2) * np.interp(t, [0, 0.01, tk(6), 0.16, sec], [0, 1, 0.8, 0.05, 0])
    ijzer = modi([(1130, 0.25, 0.09), (2870, 0.16, 0.06), (4410, 0.08, 0.04)], sec, tk(5), 0.01)
    return fade(0.9 * rmsnorm(veeg) * 0.3 + ijzer, 0.001, 0.05)


def schotdrager_aanloop():
    """Roestig sluisschot: piepend scharnier (toon met ruwheid) + rammelende plaat."""
    sec = tk(30)
    t = tijd(sec)
    f = np.interp(t, [0, sec], [330, 560]) * (1 + 0.012 * filt(r.standard_normal(len(t)), "lowpass", 30, 2) * 8)
    fase = 2 * np.pi * np.cumsum(f) / SR
    ruw = 1 + 0.6 * np.sign(np.sin(2 * np.pi * 47 * t))  # roest: het scharnier hapert
    piep = sum(np.sin(h * fase) / h**1.3 for h in range(1, 8)) * ruw
    piep = filt(piep, "highpass", 280, 2)
    rammel = np.zeros(len(t))
    tt = 0.02
    while tt < sec:
        leg(rammel, modi([(760, 0.5, 0.012), (1890, 0.35, 0.008), (3120, 0.2, 0.006)], 0.05), tt,
            r.uniform(0.6, 1.0) * (0.15 + 0.85 * (tt / sec) ** 2))
        tt += r.uniform(0.03, 0.07)
    y = 0.12 * piep * np.interp(t, [0, sec], [0.3, 1.0]) + 0.5 * rammel
    # het schot slaat in zijn stand: de piek valt in de laatste 3 ticks vóór de slag (Lead-review #193)
    # (eigen seed, zodat de rest van de set byte-gelijk blijft)
    tt = np.arange(n(tk(3))) / SR
    ph = np.random.default_rng(8653).uniform(0, 6.3, 3)
    stand = sum(a * np.exp(-tt / tau) * np.sin(2 * np.pi * f * tt + p)
                for (f, a, tau), p in zip([(760, 0.5, 0.02), (1890, 0.4, 0.015), (3120, 0.25, 0.01)], ph))
    leg(y, stand, sec - tk(2.5), 0.5)
    y += klik(sec, sec - tk(2.5), 1500, 7000, 2.5, 0.4)
    return kap(y, sec)


def schotdrager_schotstoot():
    """Actief 6 ticks: het schot wordt naar voren gestoten: plaat-dreun + luchtstoot."""
    sec = 0.5
    t = tijd(sec)
    plaat = modi([(182, 0.6, 0.09), (413, 0.45, 0.07), (694, 0.3, 0.05), (1180, 0.18, 0.035), (1960, 0.1, 0.02)],
                 sec, tk(4), 0.02)
    lucht = filt(ruis(sec), "bandpass", [500, 2500], 2) * np.interp(t, [0, tk(3), tk(6), 0.18, sec], [0, 0.5, 1, 0.1, 0])
    return fade(plaat + 0.25 * rmsnorm(lucht) * 0.4, 0.001, 0.06)


def pantser_tink():
    """0 SE (VJ-07): klein, droog, hoog, zonder lijf, en meteen gedempt.
    Zegt "dit is pantser": anders dan elke treffer met schade (die heeft hout,
    lijf en koper)."""
    sec = 0.28
    t = tijd(sec)
    y = modi([(2630, 0.5, 0.05), (4190, 0.35, 0.035), (6340, 0.2, 0.02), (8810, 0.08, 0.012)], sec, 0.0, 0.005)
    y *= np.interp(t, [0, 0.045, 0.06, sec], [1, 1, 0.25, 0.0])  # gedempt: geen naklank
    y += klik(sec, 0.0, 3000, 12000, 1.0, 1.2)
    return filt(fade(y, 0.0005, 0.03), "highpass", 1200, 2)


def schotdrager_pantser_breekt():
    """Schot breekt en valt (12 ticks): roest knispert, plaat scheurt, valt twee keer
    op de steen. Boven 1,2 kHz, zodat de ontploffing (D5) eronder hoorbaar blijft."""
    sec = 1.0
    t = tijd(sec)
    y = np.zeros(len(t))
    for _ in range(60):  # knisperen van roest
        t0 = r.uniform(0, tk(12)) ** 1.2 / tk(12) ** 0.2
        leg(y, klik(0.01, 0.0, 1800, 9000, r.uniform(0.3, 1.2), r.uniform(0.3, 1.0)), t0)
    scheur = filt(ruis(tk(12)), "bandpass", [1500, 6000], 2) * np.linspace(1, 0.2, n(tk(12))) * 0.35
    leg(y, scheur, 0.0)
    for t0, g in ((tk(12) + 0.08, 1.0), (tk(12) + 0.25, 0.45)):  # plaat op de steen
        leg(y, modi([(1240, 0.4, 0.05), (2050, 0.3, 0.04), (3310, 0.2, 0.03), (520, 0.3, 0.04)], 0.3), t0, g)
        leg(y, klik(0.01, 0.0, 800, 6000, 2.0, 1.5), t0, g)
    return fade(filt(y, "highpass", 400, 2), 0.0, 0.2)


def kadeloper_dood():
    """Lost op in donker water: een slok, dalende grote bellen, stilte."""
    sec = 0.9
    t = tijd(sec)
    y = np.zeros(len(t))
    for i in range(14):
        t0 = 0.02 + i * 0.035 * r.uniform(0.7, 1.3)
        f0 = np.interp(i, [0, 13], [900, 300]) * r.uniform(0.85, 1.15)
        leg(y, bel(f0, r.uniform(0.5, 1.0), stijg=-0.04, maxsec=0.25), t0)
    slok = np.sin(2 * np.pi * np.cumsum(np.interp(t, [0, 0.15], [420, 160])) / SR) * env_ad(sec, 0.004, 0.06)
    return fade(filt(0.7 * y + 0.5 * slok, "highpass", 120, 2), 0.002, 0.25)


def dwaallicht_zoem(sec):
    t = tijd(sec)
    # gehele aantallen trillingen per 2 s: naadloos te lussen
    vib = 0.006 * np.sin(2 * np.pi * 1.5 * t)
    fase = 2 * np.pi * np.cumsum(620 * (1 + vib)) / SR
    y = np.sin(fase) + 0.45 * np.sin(1.5 * fase + 0.3) + 0.2 * np.sin(3 * fase)
    y *= 0.75 + 0.25 * np.sin(2 * np.pi * 6.5 * t)
    lucht = filt(roze(sec), "bandpass", [1500, 5000], 2)
    return 0.5 * y + 0.06 * rmsnorm(lucht)


def dwaallicht_zweef():
    """Lus, 2 s: zacht zoemen zolang hij zweeft (aan de vijand, 2D)."""
    return lus(dwaallicht_zoem, 2.0)


def dwaallicht_aanloop():
    """Licht zwelt, toon stijgt een kwint (620 -> 930 Hz) en wordt helder; 30 ticks."""
    sec = tk(30)
    t = tijd(sec)
    f = np.interp(t, [0, sec], [620, 930]) ** 1.0
    fase = 2 * np.pi * np.cumsum(f * (1 + 0.012 * np.sin(2 * np.pi * np.interp(t, [0, sec], [6, 22]) * t))) / SR
    helder = np.interp(t, [0, sec], [0.2, 0.7])
    y = sum((helder ** (h - 1)) * np.sin(h * fase) / h for h in range(1, 7))
    y *= np.interp(t, [0, sec], [0.35, 1.0]) ** 1.5
    y += 0.08 * rmsnorm(filt(ruis(sec), "highpass", 4000, 2)) * np.interp(t, [0, sec], [0, 1])
    return kap(y, sec)


def dwaallicht_duik():
    """Duik 8 ticks: de toon valt een octaaf, met een luchtige veeg omlaag."""
    sec = 0.35
    t = tijd(sec)
    f = np.interp(t, [0, tk(8), sec], [930, 465, 440])
    y = np.sin(2 * np.pi * np.cumsum(f) / SR) * np.interp(t, [0, tk(8), sec], [1, 0.6, 0])
    veeg = svf_bandpass(ruis(sec), np.interp(t, [0, tk(8), sec], [5000, 1500, 1200]), 2.0)
    veeg *= np.interp(t, [0, tk(4), tk(8), 0.2, sec], [0.3, 1, 0.7, 0.05, 0])
    return fade(0.6 * y + 0.25 * rmsnorm(veeg) * 0.5, 0.001, 0.05)


def dwaallicht_dood():
    """Het licht dooft: glazen tikjes die opstijgen en verwaaien (geen knal)."""
    sec = 0.9
    y = np.zeros(n(sec))
    for i, f in enumerate((1760, 2217, 2637, 3520, 4435)):
        leg(y, klok(f, 0.5, grootte=0.12, grijs=True, helder=0.3, slag=0.2), 0.02 + 0.05 * i, 0.5 * 0.8**i)
    t = tijd(sec)
    sis = filt(ruis(sec), "bandpass", [3000, 7000], 2) * np.interp(t, [0, 0.05, 0.5, sec], [0, 0.03, 0.006, 0])
    return fade(filt(y, "lowpass", 6000, 2) + sis, 0.001, 0.2)


# ============================================================ Gemaalmeester (§3, §9.3)
D4, A3, D3 = 293.66, 220.0, 146.83


def gm_maat_tel(grijs=True):
    """Carillon-tel op het begin van elke maat (GM-04): de laagste klok van de wijk
    (D4) is zijn stem (bible §6.3). Kort gedempt, zodat 55 tellen niet zeuren."""
    sec = 1.4
    y = klok(D4, sec, grootte=1.1, grijs=grijs, helder=0.7, slag=1.0)
    t = tijd(sec)
    return fade(y * np.interp(t, [0, 0.5, sec], [1, 0.45, 0]), 0, 0.3)


def gm_pompslag_aanloop(ticks):
    """Sissende zuiger die stijgt (§3.4): stoom die opbouwt, de piepende as
    (GM-04) die omhoog trekt, en het hout van de drijfstang dat kraakt.
    Eén geluidsvorm voor 'laag, op de vloer: spring of stap opzij': een
    doorlopende stijging, anders dan de zwiep (versnellende pulsen)."""
    sec = tk(ticks)
    t = tijd(sec)
    rel = t / sec
    stoom = svf_bandpass(ruis(sec), np.interp(rel, [0, 1], [900, 3600]), 1.6)
    stoom = rmsnorm(stoom) * 0.45 * (0.15 + 0.85 * rel**1.6)
    f_as = np.interp(rel, [0, 1], [640, 1080]) * (1 + 0.01 * np.sin(2 * np.pi * 9 * t))
    fase = 2 * np.pi * np.cumsum(f_as) / SR
    as_ = (np.sin(fase) + 0.35 * np.sin(2 * fase) + 0.15 * np.sin(3 * fase)) * np.interp(rel, [0, 0.3, 1], [0, 0.2, 0.32])
    kraak = np.zeros(len(t))
    tt = 0.03
    while tt < sec - 0.02:
        leg(kraak, modi([(260, 0.6, 0.02), (590, 0.4, 0.015), (1170, 0.2, 0.01)], 0.06), tt, 0.25 + 0.5 * tt / sec)
        tt += r.uniform(0.07, 0.13)
    y = 0.7 * stoom + as_ + 0.6 * kraak
    y += klik(sec, sec - 0.01, 1200, 6000, 3.0, 0.4)  # de stang staat op zijn top
    return kap(filt(y, "highpass", 150, 2), sec)


def gm_pompslag_slag():
    """Op de slag (actief 6 ticks): de stang slaat op de vloer: dreun met een
    ijzeren klank erop (de klank houdt hem hoorbaar op Deck en tv, bible §8.2)."""
    sec = 1.0
    t = tijd(sec)
    dreun = np.sin(2 * np.pi * np.cumsum(58 * np.exp(-t / 0.12) + 50) / SR) * np.exp(-t / 0.22)
    ijzer = modi([(163, 0.5, 0.25), (392, 0.45, 0.18), (821, 0.3, 0.12), (1497, 0.18, 0.08), (2380, 0.1, 0.05)],
                 sec, 0.0, 0.01)
    stof = filt(ruis(sec), "bandpass", [600, 4000], 2) * np.interp(t, [0, 0.005, 0.08, 0.5, sec], [0, 1, 0.35, 0.05, 0])
    y = 0.55 * dreun + 1.1 * ijzer + 0.18 * rmsnorm(stof) * 0.5 + klik(sec, 0.0, 800, 8000, 3.0, 2.0)
    return fade(filt(y, "highpass", 40, 2), 0.0005, 0.3)


def gm_eerste_aarzeling():
    """De allereerste aanval heeft 60 ticks aanloop (hij aarzelt bij de sjaal):
    de zuiger zet aan, houdt in (een zucht van stoom), en stijgt dan alsnog."""
    sec = tk(60)
    y = np.zeros(n(sec))
    t = tijd(sec)
    zucht = filt(ruis(0.45), "bandpass", [700, 2400], 2) * np.interp(tijd(0.45), [0, 0.1, 0.45], [0, 0.35, 0])
    leg(y, zucht, 0.0)
    leg(y, gm_pompslag_aanloop(36), sec - tk(36))
    return kap(y, sec)


def gm_zwiep_aanloop():
    """Schoepen draaien op (30 ticks, §3.5): schoeppassages die versnellen
    (6 -> 18 per s) en water-gesuis dat aanzwelt. Versnellende pulsen = 'hoog,
    over de helft: blijf op de vloer'."""
    sec = tk(30)
    t = tijd(sec)
    y = np.zeros(len(t))
    tt = 0.0
    while tt < sec:
        rel = tt / sec
        k = 0.06
        kt = tijd(k)
        p = svf_bandpass(ruis(k), np.interp(kt, [0, k], [700, 1900]), 2.0) * np.sin(np.pi * kt / k) ** 2
        leg(y, p, tt, 0.3 + 0.7 * rel)
        tt += 1 / (6 + 12 * rel**1.2)
    gesuis = filt(roze(sec), "bandpass", [350, 1600], 2)
    gesuis = rmsnorm(gesuis) * np.interp(t, [0, sec], [0.05, 0.5]) ** 1.3
    for _ in range(25):
        t0 = r.uniform(0.1, sec - 0.02) ** 0.7 * sec ** 0.3
        leg(y, bel(r.uniform(450, 1500), r.uniform(0.1, 0.35)), t0)
    y = rmsnorm(y) * 0.6 + gesuis
    return kap(y, sec)


def gm_zwiep_veeg():
    """Veeg (actief 8 ticks): een vlakke, brede waterzwiep op dezelfde hoogte
    (geen dalende toon: horizontaal), met spatten."""
    sec = 0.7
    t = tijd(sec)
    zw = svf_bandpass(ruis(sec), np.interp(t, [0, tk(8), sec], [1300, 1700, 1100]), 1.2)
    zw *= np.interp(t, [0, tk(2), tk(8), 0.25, sec], [0, 1, 0.9, 0.12, 0])
    spat = np.zeros(len(t))
    for _ in range(30):
        leg(spat, bel(r.uniform(600, 3200), r.uniform(0.2, 0.7)), r.uniform(tk(4), 0.35))
    return fade(0.45 * rmsnorm(zw) * 0.6 + 0.35 * spat, 0.001, 0.15)


def gm_spuigat_borrel():
    """Spuigaten gloeien 30 ticks: borrelen dat dichter wordt, dan een stoot stoom."""
    sec = tk(30) + 0.35
    y = np.zeros(n(sec))
    tt = 0.0
    while tt < tk(30):
        rel = tt / tk(30)
        leg(y, bel(r.uniform(180, 520) * (1 + 0.5 * rel), r.uniform(0.4, 1.0), stijg=0.2), tt)
        tt += 1 / (8 + 30 * rel) * r.uniform(0.6, 1.4)
    t = tijd(0.35)
    stoot = filt(np.random.default_rng(8601).standard_normal(len(t)), "bandpass", [900, 6000], 2)
    leg(y, stoot * np.interp(t, [0, 0.02, 0.35], [0, 0.3, 0]), tk(30))
    return fade(filt(y, "highpass", 120, 2), 0.002, 0.1)


def gm_schot_tink():
    """0 SE op het intacte schot: dezelfde 'tink' als de Schotdrager, maar een
    grotere plaat (lager, iets langer), zodat je hem herkent als dezelfde les."""
    sec = 0.4
    t = tijd(sec)
    y = modi([(1720, 0.5, 0.07), (2790, 0.35, 0.05), (4240, 0.2, 0.03), (6150, 0.08, 0.02)], sec, 0.0, 0.005)
    y *= np.interp(t, [0, 0.07, 0.09, sec], [1, 1, 0.25, 0])
    y += klik(sec, 0.0, 2500, 11000, 1.2, 1.2)
    return filt(fade(y, 0.0005, 0.04), "highpass", 900, 2)


def gm_schot_breuk():
    """Het schot breekt (12 ticks): krak, scheur, stoom die vrijkomt; de kern licht op."""
    sec = 1.6
    t = tijd(sec)
    y = np.zeros(len(t))
    krak = modi([(612, 0.5, 0.06), (1415, 0.4, 0.05), (2380, 0.3, 0.035), (3770, 0.2, 0.02)], 0.3, 0, 0.02)
    leg(y, krak + klik(0.3, 0, 600, 9000, 4.0, 2.5), 0.0)
    for _ in range(40):
        leg(y, klik(0.01, 0, 1500, 9000, r.uniform(0.4, 1.5), r.uniform(0.2, 0.8)), r.uniform(0, tk(12)))
    stoom = filt(ruis(sec), "bandpass", [900, 7000], 2) * np.interp(t, [0, tk(6), 0.2, 1.2, sec], [0, 0.55, 0.4, 0.05, 0])
    gloed = filt(klok(D3 * 2, 1.4, grootte=0.8, grijs=False, helder=0.5, slag=0.3), "lowpass", 2500, 2)
    leg(y, gloed * 0.35, tk(10))
    return fade(y + 0.3 * rmsnorm(stoom) * 0.5, 0.0005, 0.3)


def gm_schot_dicht():
    """Schot schuift weer dicht (20 ticks): ijzer raspt, en sluit met een klap."""
    sec = tk(20) + 0.45
    t = tijd(sec)
    rasp = svf_bandpass(ruis(sec), np.interp(t, [0, tk(20), sec], [700, 1300, 1300]), 2.5)
    rasp *= np.interp(t, [0, 0.03, tk(20) - 0.02, tk(20), sec], [0, 0.6, 1, 0, 0])
    rasp *= 1 + 0.5 * np.sign(np.sin(2 * np.pi * 31 * t))
    klap = modi([(205, 0.6, 0.08), (488, 0.45, 0.06), (930, 0.3, 0.04), (1730, 0.2, 0.025)], sec, tk(20), 0.01)
    klap += klik(sec, tk(20), 800, 7000, 2.5, 1.6)
    return fade(0.25 * rmsnorm(rasp) * 0.5 + klap, 0.002, 0.15)


def gm_kern_puls():
    """Lus, 2 s: de kern ligt open: warm borrelen + een lage gloed (D3) die ademt."""
    def maak(sec):
        t = tijd(sec)
        gloed = np.sin(2 * np.pi * D3 * t) + 0.5 * np.sin(2 * np.pi * 2 * D3 * t) + 0.2 * np.sin(2 * np.pi * 3 * D3 * t)
        gloed *= 0.6 + 0.4 * np.sin(2 * np.pi * 1.0 * t) ** 2
        y = 0.25 * gloed
        tt = 0.0
        while tt < sec:
            leg(y, bel(r.uniform(160, 420), r.uniform(0.2, 0.6), stijg=0.15), tt)
            tt += r.uniform(0.04, 0.14)
        return y
    return lus(maak, 2.0)


def gm_kern_treffer():
    """Treffer op de kern: dof en warm (koperen ketel), geen metaalklank."""
    sec = 0.6
    t = tijd(sec)
    y = modi([(141, 0.7, 0.09), (332, 0.5, 0.07), (611, 0.35, 0.05), (1012, 0.15, 0.03)], sec, 0, 0.02)
    y += 0.4 * np.sin(2 * np.pi * np.cumsum(90 * np.exp(-t / 0.04) + 80) / SR) * np.exp(-t / 0.06)
    y += 0.3 * filt(ruis(sec), "bandpass", [400, 1800], 2) * env_ad(sec, 0.001, 0.03)
    y += modi([(611, 0.3, 0.06), (1012, 0.25, 0.04)], sec)  # het koper: hoorbaar op Deck en tv
    y = filt(y, "lowpass", 3200, 2)
    return fade(y, 0.0005, 0.15)


def gm_rad_treffer(i):
    """Treffer op het rad: ijzer dat zingt. De 2e treffer van een kant
    (kant_treffers = 2) klinkt een kwart hoger: 'deze kant is klaar'."""
    sec = 1.1
    s = 1.0 if i == 1 else 4 / 3
    y = modi([(523 * s, 0.5, 0.35), (1311 * s, 0.35, 0.25), (2243 * s, 0.25, 0.16), (3479 * s, 0.14, 0.1),
              (5112 * s, 0.06, 0.05)], sec, 0, 0.004)
    y += klik(sec, 0, 1500, 10000, 1.5, 1.8)
    t = tijd(sec)
    y += 0.3 * np.sin(2 * np.pi * np.cumsum(120 * np.exp(-t / 0.03) + 110) / SR) * np.exp(-t / 0.05)
    return fade(y, 0.0005, 0.3)


def gm_rad_ratel():
    """Rad trilt en ratelt 20 ticks vóór het draait (tell): pal-klikken die versnellen."""
    sec = tk(20)
    y = np.zeros(n(sec))
    tt = 0.0
    while tt < sec:
        rel = tt / sec
        leg(y, modi([(1850, 0.5, 0.008), (3020, 0.35, 0.006), (920, 0.3, 0.01)], 0.04) + klik(0.04, 0, 1500, 8000, 0.8),
            tt, 0.4 + 0.6 * rel)
        tt += 1 / (24 + 30 * rel)
    return kap(y, sec)


def gm_rad_draai():
    """Rad draait in 60 ticks naar de andere muur: zwaar malen, krakende as,
    en een klak als hij aankomt (op tick 60)."""
    sec = tk(60) + 0.5
    t = tijd(sec)
    rel = np.clip(t / tk(60), 0, 1)
    maal = filt(roze(sec), "bandpass", [120, 900], 2)
    maal = rmsnorm(maal) * np.sin(np.pi * rel) ** 0.7 * (t < tk(60))
    f = np.interp(rel, [0, 0.5, 1], [380, 470, 360])
    as_ = np.sin(2 * np.pi * np.cumsum(f) / SR) * 0.2 * np.sin(np.pi * rel) * (1 + 0.5 * np.sign(np.sin(2 * np.pi * 17 * t)))
    klak = modi([(310, 0.6, 0.07), (744, 0.45, 0.05), (1380, 0.3, 0.035)], sec, tk(60), 0.01)
    klak += klik(sec, tk(60), 800, 6000, 2.5, 1.3)
    return fade(0.35 * maal + filt(as_, "highpass", 250, 2) + klak, 0.01, 0.2)


def gm_fasewissel():
    """Fasewissel (60 ticks): alle stoom ontsnapt, kettingen hijsen het rad uit de
    ketel (klikken die stijgen), en het rad slaat vast."""
    sec = tk(60) + 0.8
    t = tijd(sec)
    stoom = filt(ruis(sec), "bandpass", [600, 6000], 2) * np.interp(t, [0, 0.05, 0.5, tk(60), sec], [0, 1, 0.5, 0.15, 0])
    y = 0.3 * rmsnorm(stoom) * 0.5
    for i in range(12):
        f = 700 * 2 ** (i / 12)
        leg(y, modi([(f, 0.4, 0.03), (f * 2.7, 0.2, 0.02)], 0.1) + klik(0.1, 0, 1500, 7000, 1.0, 0.8),
            0.15 + i * (tk(60) - 0.25) / 12, 0.5 + 0.04 * i)
    leg(y, gm_pompslag_slag() * 0.7, tk(60))
    return fade(y, 0.005, 0.3)


def gm_wankel_start():
    """Wankel: de klok wordt aangeslagen en meteen afgeklemd (het carillon valt stil),
    de machine zakt in toon weg."""
    sec = 2.0
    t = tijd(sec)
    bel_ = klok(D4, sec, grootte=1.1, grijs=True, helder=0.6) * np.interp(t, [0, 0.12, 0.18, sec], [1, 1, 0.04, 0])
    smoor = filt(ruis(sec), "bandpass", [300, 1500], 2) * np.interp(t, [0.1, 0.14, 0.3], [0, 0.5, 0])
    f = np.interp(t, [0, sec], [92, 38])
    zak = (np.sin(2 * np.pi * np.cumsum(f) / SR) + 0.4 * np.sin(2 * np.pi * np.cumsum(3.1 * f) / SR)) \
        * np.interp(t, [0, 0.1, sec], [0, 0.35, 0])
    return fade(bel_ + 0.3 * smoor + zak, 0.0, 0.3)


def gm_wankel_hapert():
    """Lus, 3 s: hij hapert: een zuiger die niet meer pakt, onregelmatig, en
    een as die kreunt. Geen ritme: de maat is weg."""
    def maak(sec):
        y = np.zeros(n(sec))
        tt = 0.1
        while tt < sec:
            k = n(0.5)
            kt = np.arange(k) / SR
            puf = np.sin(2 * np.pi * np.cumsum(70 * np.exp(-kt / 0.06) + 55) / SR) * np.exp(-kt / 0.12)
            puf += 0.9 * modi([(340, 0.5, 0.08), (870, 0.4, 0.05), (1530, 0.2, 0.03)], 0.5)
            leg(y, puf, tt, r.uniform(0.3, 0.8))
            tt += r.uniform(0.35, 0.95)
        t = tijd(sec)
        kreun = np.sin(2 * np.pi * np.cumsum(260 + 25 * np.sin(2 * np.pi * (1 / 3) * t)) / SR) * 0.08
        return filt(y + kreun * (1 + 0.5 * np.sign(np.sin(2 * np.pi * 11 * t))), "highpass", 45, 2)
    return lus(maak, 3.0, 0.4)


def gm_merkplek_open():
    """De merkplek op de ketel gaat open (20 ticks): een gloeiende peilmerk-vorm:
    licht dat aanzwelt en een klein klokje A5 (de familie van het merk)."""
    sec = tk(20) + 1.0
    t = tijd(sec)
    zwel = filt(ruis(sec), "bandpass", [2500, 7000], 2) * np.interp(t, [0, tk(20), tk(20) + 0.3, sec], [0, 0.3, 0.0, 0])
    y = 0.3 * rmsnorm(zwel) * 0.3
    leg(y, klok(880.0, 1.0, grootte=0.45, grijs=False, helder=0.6, slag=0.6), tk(20))
    return fade(y, 0.01, 0.2)


# ============================================================ finisher (§3.6, bible §6.4)
FIN_TONEN = [587.33, 659.26, 739.99, 880.0, 987.77, 1174.66, 1318.51, 1479.98]  # D-groot pentatoniek, D5 -> F#6


def fin_slag(i, wie):
    """Eén finisherslag: een carillonslag op toon i, in het materiaal van wie
    (p1 = warm koper en hout; p2 = ijzer en glas; echo = p1, maar hol)."""
    f = FIN_TONEN[i]
    sec = 1.1
    y = klok(f, sec, grootte=0.7, grijs=False, helder=0.8, slag=0.9)
    t = tijd(sec)
    if wie in ("p1", "echo"):
        hout = modi([(f * 0.5, 0.25, 0.03), (f * 1.27, 0.15, 0.02)], sec)
        y = y + hout
    if wie == "p2":
        glas = np.sin(2 * np.pi * f * 4.02 * t) * np.exp(-t / 0.25) * (1 + 0.3 * np.sin(2 * np.pi * 7 * t))
        ijzer = modi([(f * 2.76, 0.2, 0.08), (f * 5.4, 0.1, 0.05)], sec)
        y = filt(y, "highpass", f * 0.8, 2) + 0.12 * glas + ijzer
    if wie == "echo":
        # hol zoals bible §4, maar zonder omgekeerde aanloop: de finisher speelt
        # tot 5 slagen per s, een aanloop zou ze laten uitsmeren
        droog = filt(y, "highpass", 260, 4)
        y = (0.55 * comb_hol(droog) + 0.45 * filt(droog, "bandpass", [700, 4200], 2)) * 10 ** (-4 / 20)
    return fade(y, 0.0005, 0.25)


def finisher_start():
    """De gedeelde echo verschijnt: licht en schaduw zwellen samen aan (0,5 s)
    naar de eerste slag; omgekeerde klok, zoals de echo 'uit het verleden' komt."""
    sec = 0.5
    k = klok(587.33, 1.2, grootte=0.9, grijs=False, helder=0.7)[: n(sec)][::-1]
    t = tijd(sec)
    sis = filt(ruis(sec), "bandpass", [2000, 8000], 2) * (t / sec) ** 2
    return kap(k * (t / sec) ** 1.5 + 0.08 * rmsnorm(sis) * 0.4, sec)


def finisher_slot():
    """Slot in licht (tick 120 van de finisher): de volle klokkenrol, van D6
    omlaag naar de grote klok D4 met hum D3, in de galm van het belfort.
    Het enige moment met het hele carillon tegelijk (bible §6.4). Stereo."""
    sec = 5.0
    y = np.zeros(n(sec))
    rol = [1174.66, 987.77, 880.0, 739.99, 587.33, 493.88, 440.0, 369.99]
    for i, f in enumerate(rol):
        leg(y, klok(f, 3.0, grootte=0.8, grijs=False, helder=0.85), i * 0.045, 0.45)
    leg(y, klok(D4, 4.6, grootte=1.8, grijs=False, helder=0.85), 8 * 0.045 + 0.02, 0.9)
    t = tijd(sec)
    licht = filt(ruis(sec), "highpass", 6000, 2) * np.interp(t, [0, 0.4, 2.5, sec], [0, 0.04, 0.005, 0])
    y = y + licht
    st = np.stack([y, np.concatenate([np.zeros(n(0.004)), y])[: len(y)]], axis=1)
    nat = f2.galm(st, f2.IR_BELFORT, 0.55)
    return fade_st(st + nat, 0.0, 0.8)


def fade_st(x, fi, fo):
    return np.stack([fade(x[:, 0], fi, fo), fade(x[:, 1], fi, fo)], axis=1)


# ============================================================ merk en ketting (bible §6.2)
def ontploffing_schakel(k, grijs):
    """Ontploffing van schakel k (1..5): de ontploffing van het fragment, met de
    klok van schakel k een stap hoger (D5, F#5, A5, B5, D6). De rol van 45 ms
    tussen schakels doet de code (bible §6.2), niet het bestand."""
    y = f2.ontploffing(k, grijs)
    if k > 1:
        leg(y, f2.ketting_klok(k, grijs), 0.0, 0.8)
    return y


# ============================================================ leesbaarheidssignalen
def plank_signaal():
    """E-07d: één zachte, korte tik als de plank van de echo oplicht. Hout, hol
    (de familie van de echo), zonder lijf, 60 ms. Zacht gerenderd (zie meting)."""
    sec = 0.09
    t = tijd(sec)
    y = modi([(1560, 0.6, 0.012), (2410, 0.35, 0.008), (3720, 0.15, 0.005)], sec, 0, 0.0)
    y += klik(sec, 0, 1500, 6000, 0.8, 0.6)
    y = 0.6 * comb_hol(filt(y, "highpass", 600, 2), ms=0.64, g=0.4) + 0.4 * y
    return fade(y * np.interp(t, [0, 0.06, sec], [1, 0.3, 0]), 0.0005, 0.02)


def doelstreep_voorslag(grijs):
    """E-02t: carillon-voorslag, 30 ticks: een omgekeerd klokje dat aanzwelt en
    precies op de slag van de echo ophoudt (de knal neemt het over). Volgt
    doelstreep_strength (0 -> 1). Geen slag: het mag geen aftelslag lijken."""
    sec = tk(30)
    k = klok(1318.51, 1.0, grootte=0.35, grijs=grijs, helder=0.5, slag=0.2)[: n(sec)][::-1]
    t = tijd(sec)
    glans = np.sin(2 * np.pi * 2637.0 * t) * (1 + 0.4 * np.sin(2 * np.pi * 18 * t)) * 0.1
    y = (k + glans) * (t / sec) ** 2
    if grijs:
        y = filt(y, "lowpass", 3000, 2)
    return kap(filt(y, "highpass", 900, 2), sec)


# ============================================================ catalogus
# (familie, naam, functie, niveau-doel: max. momentane loudness (400 ms) in LUFS
#  binnen het bestand; zo staan alle bestanden op één schaal tegenover elkaar)
TELL, AANVAL, TINK, TREF, KNAL, LOOP, SIGNAAL = -15.0, -14.0, -17.0, -17.0, -13.0, -30.0, -29.0

CATALOGUS = [
    ("vijanden", "kadeloper_aanloop", kadeloper_aanloop, TELL),
    ("vijanden", "kadeloper_haakslag", kadeloper_haakslag, AANVAL),
    ("vijanden", "kadeloper_dood", kadeloper_dood, TREF),
    ("vijanden", "schotdrager_aanloop", schotdrager_aanloop, TELL),
    ("vijanden", "schotdrager_schotstoot", schotdrager_schotstoot, AANVAL),
    ("vijanden", "pantser_tink", pantser_tink, TINK),
    ("vijanden", "schotdrager_pantser_breekt", schotdrager_pantser_breekt, TREF),
    ("vijanden", "dwaallicht_zweef_lus", dwaallicht_zweef, LOOP),
    ("vijanden", "dwaallicht_aanloop", dwaallicht_aanloop, TELL),
    ("vijanden", "dwaallicht_duik", dwaallicht_duik, AANVAL),
    ("vijanden", "dwaallicht_dood", dwaallicht_dood, TREF),
    ("gemaalmeester", "gm_maat_tel_grijs", lambda: gm_maat_tel(True), TELL - 2),
    ("gemaalmeester", "gm_maat_tel_kleur", lambda: gm_maat_tel(False), TELL - 2),
    ("gemaalmeester", "gm_pompslag_aanloop_f1", lambda: gm_pompslag_aanloop(40), TELL),
    ("gemaalmeester", "gm_pompslag_aanloop_f2", lambda: gm_pompslag_aanloop(30), TELL),
    ("gemaalmeester", "gm_pompslag_aanloop_eerste", gm_eerste_aarzeling, TELL),
    ("gemaalmeester", "gm_pompslag_slag", gm_pompslag_slag, AANVAL + 1),
    ("gemaalmeester", "gm_zwiep_aanloop", gm_zwiep_aanloop, TELL),
    ("gemaalmeester", "gm_zwiep_veeg", gm_zwiep_veeg, AANVAL),
    ("gemaalmeester", "gm_spuigat_borrel", gm_spuigat_borrel, TELL - 3),
    ("gemaalmeester", "gm_schot_tink", gm_schot_tink, TINK),
    ("gemaalmeester", "gm_schot_breuk", gm_schot_breuk, KNAL),
    ("gemaalmeester", "gm_schot_dicht", gm_schot_dicht, TREF),
    ("gemaalmeester", "gm_kern_puls_lus", gm_kern_puls, LOOP),
    ("gemaalmeester", "gm_kern_treffer", gm_kern_treffer, TREF),
    ("gemaalmeester", "gm_rad_treffer_1", lambda: gm_rad_treffer(1), TREF),
    ("gemaalmeester", "gm_rad_treffer_2", lambda: gm_rad_treffer(2), TREF),
    ("gemaalmeester", "gm_rad_ratel", gm_rad_ratel, TELL),
    ("gemaalmeester", "gm_rad_draai", gm_rad_draai, TREF - 2),
    ("gemaalmeester", "gm_fasewissel", gm_fasewissel, KNAL),
    ("gemaalmeester", "gm_wankel_start", gm_wankel_start, TREF),
    ("gemaalmeester", "gm_wankel_hapert_lus", gm_wankel_hapert, LOOP + 4),
    ("gemaalmeester", "gm_merkplek_open", gm_merkplek_open, TREF - 2),
    ("finisher", "finisher_start", finisher_start, TREF),
]
for _w in ("p1", "p2", "echo"):
    for _i in range(len(FIN_TONEN)):
        CATALOGUS.append(("finisher", f"finisher_slag_{_w}_{_i + 1}", (lambda i=_i, w=_w: fin_slag(i, w)),
                          -19.0 if _w != "echo" else -23.0))
CATALOGUS.append(("finisher", "finisher_slot", finisher_slot, KNAL + 1))
for _k in range(1, 6):
    for _g in (True, False):
        CATALOGUS.append(("merk", f"ontploffing_k{_k}_{'grijs' if _g else 'kleur'}",
                          (lambda k=_k, g=_g: ontploffing_schakel(k, g)), KNAL))
CATALOGUS += [
    ("signalen", "plank_signaal", plank_signaal, SIGNAAL),
    ("signalen", "doelstreep_voorslag_grijs", lambda: doelstreep_voorslag(True), SIGNAAL + 2),
    ("signalen", "doelstreep_voorslag_kleur", lambda: doelstreep_voorslag(False), SIGNAAL + 2),
]


# ============================================================ meten en schrijven
def momentaan_max(x):
    st = x if x.ndim == 2 else np.stack([x, x], axis=1)
    if len(st) < n(0.4):
        st = np.concatenate([st, np.zeros((n(0.4) - len(st), 2))])
    return f2.lufs_max(st, 0.4)


def peil(x, doel):
    """Gain naar het niveau-doel, dan onder de true-peak-grens (−1,5 dBTP)."""
    x = x - np.mean(x, axis=0)
    g = doel - momentaan_max(x)
    x = x * 10 ** (g / 20)
    tp = f2.true_peak_db(x if x.ndim == 2 else x[:, None])
    if tp > -1.5:
        x = x * 10 ** ((-1.5 - tp) / 20)
    return x


def meet(x):
    m = x.mean(axis=1) if x.ndim == 2 else x
    f, p = signal.welch(m, SR, nperseg=min(4096, len(m)))
    tot = np.sum(p) + 1e-30
    om = np.abs(signal.hilbert(m))
    om = np.convolve(om, np.ones(n(0.005)) / n(0.005), mode="same")
    return {
        "duur_s": round(len(m) / SR, 3),
        "duur_ticks": round(len(m) / SR / TICK, 1),
        "lufs_momentaan_max": round(momentaan_max(x), 1),
        "true_peak_dbtp": round(f2.true_peak_db(x if x.ndim == 2 else x[:, None]), 1),
        "aandeel_boven_250hz_pct": round(float(100 * np.sum(p[f >= 250]) / tot), 1),
        "zwaartepunt_hz": int(np.sum(f * p) / tot),
        "piek_op_s": round(float(np.argmax(om)) / SR, 3),
        # tell-vorm: niveau van de laatste 100 ms tegenover de eerste 100 ms
        "stijging_db": round(float(20 * np.log10((np.sqrt(np.mean(m[-n(0.1):] ** 2)) + 1e-9)
                                                 / (np.sqrt(np.mean(m[: n(0.1)] ** 2)) + 1e-9))), 1),
    }


def main():
    uitkomst = {}
    klanken = {}
    for fam, naam, fn, doel in CATALOGUS:
        x = peil(fn(), doel)
        klanken[naam] = x
        d = os.path.join(SFX, fam)
        os.makedirs(d, exist_ok=True)
        f2.schrijf_wav(os.path.join(d, f"{naam}_placeholder.wav"), x)
        uitkomst[naam] = {"bestand": f"sfx/{fam}/{naam}_placeholder.wav", **meet(x)}
    reeks = luisterreeks(klanken)
    pad = os.path.join(UIT, "luisterreeks_slice_sfx_placeholder.wav")
    f2.schrijf_wav(pad, reeks)
    if shutil.which("ffmpeg"):
        subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-i", pad, "-c:a", "libvorbis", "-q:a", "6",
                        pad[:-4] + ".ogg"], check=True)
        os.remove(pad)  # de reeks gaat als OGG in de repo (10 MB minder); de WAV is opnieuw te maken
    spectrogram(reeks)
    uitkomst["_luisterreeks"] = {"duur_s": round(len(reeks) / SR, 2),
                                 "lufs_geintegreerd": round(f2.lufs_geintegreerd(reeks), 1),
                                 "true_peak_dbtp": round(f2.true_peak_db(reeks), 1),
                                 "momenten_s": REEKS_LOG}
    with open(os.path.join(UIT, "meting_placeholder.json"), "w") as fh:
        json.dump(uitkomst, fh, indent=1, ensure_ascii=False)
    print(json.dumps(uitkomst, indent=1, ensure_ascii=False))


REEKS_LOG = []
DELEN = [(0.5, "Kadeloper"), (4.7, "Schotdrager"), (9.5, "Dwaallicht"), (14.5, "ketting k1-k5"),
         (18.0, "GM fase 1"), (29.5, "fasewissel + fase 2"), (37.6, "Wankel"), (41.2, "finisher"),
         (48.3, "signalen")]


def spectrogram(reeks):
    try:
        import matplotlib

        matplotlib.use("Agg")
        import matplotlib.pyplot as plt
    except ImportError:
        return
    mono = reeks.mean(axis=1)
    fig, ax = plt.subplots(2, 1, figsize=(14, 6), sharex=True, gridspec_kw={"height_ratios": [1, 3]})
    tt = np.arange(len(mono)) / SR
    ax[0].plot(tt[::40], mono[::40], lw=0.4, color="#444")
    for t0, lab in DELEN:
        ax[0].axvline(t0, color="#c80", lw=0.6)
        ax[0].text(t0 + 0.1, 0.85 * np.max(np.abs(mono)), lab, fontsize=7, color="#a60")
    ax[1].specgram(mono + 1e-9, NFFT=2048, Fs=SR, noverlap=1536, cmap="magma", vmin=-130)
    ax[1].set_yscale("symlog", linthresh=500)
    ax[1].set_ylim(30, 16000)
    ax[1].set_ylabel("Hz")
    ax[1].set_xlabel("s")
    fig.suptitle("T8d deel 1: luisterreeks slice-SFX (placeholder)")
    fig.tight_layout()
    fig.savefig(os.path.join(UIT, "luisterreeks_spectrogram_placeholder.png"), dpi=100)


def luisterreeks(k):
    """Een reeks om te beluisteren, met de tells op hun echte ticks gezet (maten
    uit §3.4/§3.5); geen mix voor het spel (dat is de Audio Director)."""
    sec = 62.0
    y = np.zeros((n(sec), 2))

    def zet(naam, t0, db=0.0, p=0.0):
        x = k[naam]
        if x.ndim == 1:
            a = (p + 1) * np.pi / 4
            x = np.stack([x * np.cos(a), x * np.sin(a)], axis=1) * np.sqrt(2)
        i = n(t0)
        j = min(len(y), i + len(x))
        y[i:j] += x[: j - i] * 10 ** (db / 20)
        REEKS_LOG.append((round(t0, 3), naam))

    t = 0.5
    # 1. Kadeloper: aanloop (30) -> haakslag (6); P1 springt eroverheen
    for _ in range(2):
        zet("kadeloper_aanloop", t, 0, -0.3)
        zet("kadeloper_haakslag", t + tk(30), 0, -0.3)
        t += 1.4
    zet("kadeloper_dood", t, 0, -0.3)
    t += 1.4
    # 2. Schotdrager: aanloop + stoot; een slag op het pantser (tink); de ontploffing breekt het
    zet("schotdrager_aanloop", t, 0, 0.3)
    zet("schotdrager_schotstoot", t + tk(30), 0, 0.3)
    t += 1.3
    zet("pantser_tink", t, 0, 0.3)
    t += 0.9
    zet("ontploffing_k1_grijs", t, -3, 0.2)
    zet("schotdrager_pantser_breekt", t + tk(1), 0, 0.3)
    t += 2.6
    # 3. Dwaallicht: zweven, aanloop, duik, dood
    zet("dwaallicht_zweef_lus", t, 0, 0.0)
    zet("dwaallicht_zweef_lus", t + 2.0, 0, 0.0)
    zet("dwaallicht_aanloop", t + 2.2, 0, 0.0)
    zet("dwaallicht_duik", t + 2.2 + tk(30), 0, 0.0)
    zet("dwaallicht_dood", t + 3.6, 0, 0.0)
    t += 5.0
    # 4. Ketting k1..k5 (grijs), gerold op 45 ms zoals de code het zou doen
    for i in range(5):
        zet(f"ontploffing_k{i + 1}_grijs", t + 0.045 * i, -6 - i, -0.6 + 0.3 * i)
    t += 3.5
    # 5. Gemaalmeester fase 1: drie maten van 120 ticks; de eerste met de aarzeling (60)
    zet("gm_maat_tel_grijs", t)
    zet("gm_pompslag_aanloop_eerste", t, 0, -0.4)
    zet("gm_pompslag_slag", t + tk(60), 0, -0.4)
    t += tk(120)
    zet("gm_schot_tink", t - 0.6, 0, 0.0)
    for m in range(2):
        kant = 0.4 if m % 2 else -0.4
        zet("gm_maat_tel_grijs", t)
        zet("gm_pompslag_aanloop_f1", t, 0, kant)
        zet("gm_pompslag_slag", t + tk(40), 0, kant)
        t += tk(120)
    zet("gm_schot_breuk", t - 0.9, 0, 0.0)
    zet("gm_kern_puls_lus", t - 0.3, 0, 0.0)
    zet("gm_kern_treffer", t + 0.3, 0, 0.0)
    zet("gm_kern_treffer", t + 0.75, -2, 0.0)
    zet("gm_kern_puls_lus", t + 1.7, 0, 0.0)
    t += 2.0
    zet("gm_maat_tel_grijs", t)
    zet("gm_pompslag_aanloop_f1", t, 0, 0.4)
    zet("gm_pompslag_slag", t + tk(40), 0, 0.4)
    t += tk(120)
    zet("gm_schot_dicht", t - 0.6, 0, 0.0)
    zet("gm_spuigat_borrel", t, 0, -0.5)
    zet("gm_spuigat_borrel", t + 0.05, 0, 0.5)
    t += 1.5
    # 6. Fasewissel, fase 2: maten van 90 ticks, om en om pompslag (hoog-laag) en zwiep
    zet("gm_fasewissel", t)
    t += tk(60) + 0.6
    for m in range(4):
        zet("gm_maat_tel_grijs", t)
        if m % 2 == 0:
            zet("gm_pompslag_aanloop_f2", t, 0, 0.0)
            zet("gm_pompslag_slag", t + tk(30), 0, 0.0)
        else:
            zet("gm_zwiep_aanloop", t, 0, -0.5)
            zet("gm_zwiep_veeg", t + tk(30), 0, -0.5)
        if m == 1:
            zet("gm_rad_treffer_1", t + 0.9, 0, -0.6)
        if m == 2:
            zet("gm_rad_treffer_2", t + 0.5, 0, -0.6)
            zet("gm_rad_ratel", t + 0.9, 0, -0.6)
            zet("gm_rad_draai", t + 0.9 + tk(20), 0, -0.6)
        t += tk(90)
    t += 0.5
    # 7. Wankel, merkplek, finisher (120 ticks: 16 slagen om en om p1 / echo, oplopend), slot
    zet("gm_wankel_start", t)
    zet("gm_wankel_hapert_lus", t + 0.8)
    zet("gm_merkplek_open", t + 1.6)
    t += 3.6
    zet("finisher_start", t)
    t += 0.5
    for i in range(14):
        wie = "p1" if i % 2 == 0 else "echo"
        zet(f"finisher_slag_{wie}_{min(i // 2 + 1, 8)}", t + i * (tk(120) - 0.15) / 14, 0, -0.3 if wie == "p1" else 0.3)
    zet("finisher_slot", t + tk(120))
    t += tk(120) + 4.6
    # 8. Signalen: plank-signaal (2x) en de doelstreep-voorslag in aanloop naar een knal
    zet("plank_signaal", t)
    zet("plank_signaal", t + 0.8)
    zet("doelstreep_voorslag_grijs", t + 1.6)
    zet("ontploffing_k1_grijs", t + 1.6 + tk(30), -6)
    t += 4.5
    y = y[: n(min(sec, t))]
    g = 10 ** ((-18.0 - f2.lufs_geintegreerd(y)) / 20)
    y = y * g
    tp = f2.true_peak_db(y)
    if tp > -1.5:
        y *= 10 ** ((-1.5 - tp) / 20)
    return y


if __name__ == "__main__":
    sys.exit(main())
