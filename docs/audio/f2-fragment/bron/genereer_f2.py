#!/usr/bin/env python3
"""F2-referentiefragment v2: merk-aftelling met het carillon (T2, #66).

Alles is synthese (numpy/scipy), zonder externe samples. Vaste seed: elke run
geeft bit voor bit dezelfde WAV-bestanden (de OGG en de PNG kunnen per
ffmpeg- of matplotlib-build verschillen).

Opnieuw maken, vanaf de repo-root:
    python3 docs/audio/f2-fragment/bron/genereer_f2.py

Schrijft naar docs/audio/f2-fragment/:
    f2_merk_aftelling_carillon_placeholder.wav   (48 kHz, 16 bit, stereo)
    f2_merk_aftelling_carillon_placeholder.ogg   (Vorbis q6, als ffmpeg er is)
    f2_spectrogram_placeholder.png               (als matplotlib er is)
    losse-sfx/*.wav                              (de bouwstenen, los)
en print de metingen uit docs/audio/bible.md §9 (ook ffmpeg ebur128, als
ffmpeg er is).

v2 tegenover v1 (bible §9.3, punten 2-6):
  2. water: bellenmodel (Minnaert-bellen met stijgende toon, van den Doel)
     op golfslagen, in plaats van gefilterde ruis; leeglopen = klokkende
     grote bellen; druppels = "plink" met stijgende bel.
  3. P1-slag: gelaagd (zwaai met stoffen flapper, transiënt, houtmodi met
     spreiding, koperen naklank, gruis), niet één modale tik.
  4. harmonium: twee rieten per toon (celeste, +-3 cent), riet-geruis
     synchroon met de periode, toetsklik, balgdruk die ook de klankkleur
     stuurt, stemmen die na elkaar inzetten.
  5. galm: vroege reflecties uit een spiegelbronmodel van de ruimte
     (belfort 7,5 x 7,5 x 19 m; verzonken gewelf 5 x 9 x 3,2 m) en een
     staart met een eigen nagalmtijd per band.
  6. grijs droger en kaler, opgepompt helderder; het gemaal zonder
     subsonisch laag (punt 7).
  En: de levensduur van een merk zonder echo als losse reeks (doven op
  D + 30, E-14b), met de timing op ticks gemeten.

Tijdlijn (60 Hz-ticks, staart D = 120 ticks = 2 s, merk leeft D + 30 ticks,
aftelling = laatste 60 ticks, één carillonslag per 15 ticks):
  A. grijze wijk (0-6,2 s): P1 slaat (0,60), sprong (1,20); aftelling 2,10 en
     2,35; de echo slaat op 2,60 (= slag 3) en laat het merk ontploffen;
     echo-sprong 3,20.
  B. oppompen bij het gemaal (6,2-8,6 s): water zakt, machine slaat aan,
     de terts komt terug.
  C. opgepompte wijk (8,6-15,5 s): twee slagen (9,00 en 9,30), twee merken;
     aftelling 10,50 en 10,75; echo op 11,00: ketting k = 1, 2; de tweede
     echo-slag (11,30) vindt geen merk meer (gewone echo-treffer).
"""
import json
import os
import re
import shutil
import subprocess
import sys
import tempfile

import numpy as np
from scipy import signal
from scipy.io import wavfile

SR = 48000
TICK = 1.0 / 60.0
D_TICKS = 120  # werkaanname 8A: staart +- 2 s (bereik 90-180)
LEVENSDUUR = D_TICKS + 30  # E-14b
AFTEL = 60  # E-14b: laatste 60 ticks
AFTEL_STAP = 15  # 4 slagen; de echo valt altijd op slag 3 (30 ticks voor het einde)
DUUR = 15.5
DOEL_LUFS = -18.0
DOEL_TP = -1.5  # ruimte voor Vorbis: na decoderen blijft de true peak onder -1 dBTP

HIER = os.path.dirname(os.path.abspath(__file__))
UIT = os.path.dirname(HIER)
LOS = os.path.join(UIT, "losse-sfx")

rng = np.random.default_rng(66)
DUK = {}  # gemeten duk van bed en muziek
LOG = []  # (spoor, naam, verwachte tijd in s) voor de timingcontrole


# ---------------------------------------------------------------- hulpmiddelen
def n(sec):
    return int(round(sec * SR))


def tijd(sec):
    return np.arange(n(sec)) / SR


def sos(kind, f, order=2):
    if isinstance(f, (list, tuple)):
        f = [min(x, SR / 2 * 0.98) for x in f]
    else:
        f = min(f, SR / 2 * 0.98)
    return signal.butter(order, f, btype=kind, fs=SR, output="sos")


def filt(x, kind, f, order=2):
    return signal.sosfilt(sos(kind, f, order), x, axis=0)


def ruis(sec):
    return rng.standard_normal(n(sec))


def roze(sec):
    w = np.fft.rfft(ruis(sec))
    fr = np.fft.rfftfreq(n(sec), 1 / SR)
    fr[0] = fr[1]
    return np.fft.irfft(w / np.sqrt(fr), n(sec))


def norm(x, peak=1.0):
    m = np.max(np.abs(x))
    return x * (peak / m) if m > 0 else x


def rmsnorm(x):
    return x / (np.sqrt(np.mean(x**2)) + 1e-12)


def env_ad(sec, a, tau):
    t = tijd(sec)
    e = np.exp(-t / tau)
    na = max(1, n(a))
    e[:na] *= np.linspace(0, 1, na) ** 2
    return e


def fade(x, fi=0.0, fo=0.0):
    x = x.copy()
    if fi > 0:
        k = min(n(fi), len(x))
        x[:k] *= np.sin(np.linspace(0, np.pi / 2, k)) ** 2
    if fo > 0:
        k = min(n(fo), len(x))
        x[-k:] *= np.cos(np.linspace(0, np.pi / 2, k)) ** 2
    return x


def pan(x, p):
    """p in -1..1, constante kracht."""
    a = (p + 1) * np.pi / 4
    return np.stack([x * np.cos(a), x * np.sin(a)], axis=1)


def leg(y, sig, t0, g=1.0):
    i = n(t0)
    j = min(len(y), i + len(sig))
    if j > i:
        y[i:j] += g * sig[: j - i]


def svf_bandpass(x, fc, q):
    """Tijdvariabele bandpass (Chamberlin). fc en q mogen arrays zijn."""
    fc = np.broadcast_to(fc, x.shape)
    q = np.broadcast_to(q, x.shape)
    f = 2 * np.sin(np.pi * np.clip(fc, 10, SR / 6) / SR)
    damp = 1.0 / q
    y = np.zeros_like(x)
    low = band = 0.0
    for i in range(len(x)):
        high = x[i] - low - damp[i] * band
        band += f[i] * high
        low += f[i] * band
        y[i] = band
    return y


class Spoor:
    """Een stereo-stem op de tijdlijn."""

    def __init__(self, sec=DUUR, naam=""):
        self.x = np.zeros((n(sec), 2))
        self.naam = naam

    def zet(self, sig, t0, gain_db=0.0, p=0.0, log=None, aanslag=0.0):
        """aanslag = tijd (s) binnen sig waarop het hoorbare moment valt."""
        if sig.ndim == 1:
            sig = pan(sig, p)
        g = 10 ** (gain_db / 20)
        i = n(t0)
        j = min(len(self.x), i + len(sig))
        if j > i:
            self.x[i:j] += sig[: j - i] * g
        if log:
            LOG.append((self.naam, log, round(t0 + aanslag, 4)))


# ---------------------------------------------------------------- galm (punt 5)
def galm_ir(sec, rt60, donker_hz, ruimte, band_rt, beta, breedte=1.0):
    """Impulsrespons: spiegelbronnen (vroege reflecties) + staart per band.

    ruimte = (Lx, Ly, Lz) in m; beta = reflectiefactor van de wanden;
    band_rt = vermenigvuldiger op rt60 voor laag (< 500 Hz), midden, hoog (> 3 kHz).
    """
    t = tijd(sec)
    L = np.array(ruimte, float)
    bron = L * np.array([0.30, 0.25, 0.55])
    c = 343.0
    ir = np.zeros((len(t), 2))
    d_direct = None
    for kanaal, dx in enumerate((-0.18, 0.18)):
        ontv = L * np.array([0.62, 0.70, 0.45]) + np.array([dx, 0, 0])
        if d_direct is None:
            d_direct = np.linalg.norm(bron - ontv)
        orde_sig = [np.zeros(len(t)) for _ in range(4)]
        for nx in range(-3, 4):
            for ny in range(-3, 4):
                for nz in range(-3, 4):
                    orde = abs(nx) + abs(ny) + abs(nz)
                    if orde == 0 or orde > 3:
                        continue
                    beeld = np.array([
                        (nx * L[0] + (bron[0] if nx % 2 == 0 else L[0] - bron[0])),
                        (ny * L[1] + (bron[1] if ny % 2 == 0 else L[1] - bron[1])),
                        (nz * L[2] + (bron[2] if nz % 2 == 0 else L[2] - bron[2])),
                    ])
                    d = np.linalg.norm(beeld - ontv)
                    k = n((d - d_direct) / c)
                    if 0 < k < len(t):
                        orde_sig[orde][k] += (beta**orde) * d_direct / d * rng.choice([-1, 1], p=[0.15, 0.85])
        vroeg = sum(filt(orde_sig[o], "lowpass", donker_hz * 1.6 * 0.72**o, 2) for o in range(1, 4))
        # staart: echodichtheid groeit tot de mengtijd, nagalm per band
        t_mix = 2e-3 * np.sqrt(np.prod(L))
        t1 = n(0.004)
        groei = np.clip((t - t1 / SR) / t_mix, 0, 1) ** 2
        staart = np.zeros(len(t))
        for (soort, f), m in zip((("lowpass", 500), ("bandpass", [500, 3000]), ("highpass", 3000)), band_rt):
            staart += filt(rng.standard_normal(len(t)), soort, f, 2) * np.exp(-6.9 * t / (rt60 * m))
        staart = filt(staart, "lowpass", donker_hz, 2) * groei
        # staart sluit op niveau aan bij de vroege reflecties rond de mengtijd
        w = slice(n(t_mix * 0.8), n(t_mix * 1.6))
        schaal = np.sqrt(np.mean(vroeg[w] ** 2) + 1e-12) / (np.sqrt(np.mean(staart[w] ** 2)) + 1e-12)
        ir[:, kanaal] = vroeg + 0.9 * schaal * staart
    m = 0.5 * (ir[:, 0] + ir[:, 1])
    ir[:, 0] = m + breedte * (ir[:, 0] - m)
    ir[:, 1] = m + breedte * (ir[:, 1] - m)
    return ir / np.sqrt(np.sum(ir**2) / 2)


def galm(x, ir, nat):
    """x stereo; geeft alleen het natte signaal terug (send/return)."""
    mono = x.mean(axis=1)
    y = np.stack([signal.fftconvolve(mono, ir[:, c])[: len(mono)] for c in range(2)], axis=1)
    return y * nat


# opgepompt: stenen belfort, warm en helder; hoog sterft sneller dan laag
IR_BELFORT = galm_ir(3.6, 2.9, 6000, (7.5, 7.5, 19.0), (1.15, 1.0, 0.62), 0.86, 1.0)
# grijs: laag, nat gewelf; korter, donker, hoog sterft snel
IR_VERZONKEN = galm_ir(2.4, 1.8, 1300, (5.0, 9.0, 3.2), (1.0, 0.65, 0.3), 0.62, 0.6)


# ---------------------------------------------------------------- klokken
# Partialen van een goed gestemde carillonklok (minor-terts-klok), t.o.v. de
# prime (= slagtoon): verhouding, amplitude, relatieve nagalm.
KLOK = [
    (0.500, 0.30, 1.00),  # hum
    (1.000, 0.55, 0.62),  # prime
    (1.200, 0.42, 0.50),  # (kleine) terts: het karakter van de klok
    (1.497, 0.18, 0.40),  # kwint
    (2.000, 0.80, 0.36),  # nominaal
    (2.510, 0.20, 0.24),  # deciem
    (2.667, 0.16, 0.22),  # undeciem
    (3.011, 0.20, 0.18),  # duodeciem
    (4.050, 0.10, 0.12),  # dubbel octaaf
    (5.340, 0.06, 0.08),
    (6.800, 0.035, 0.06),
]


def klok(f, sec=None, grootte=1.0, grijs=False, helder=1.0, slag=1.0):
    """Modale synthese van één klokslag. f = slagtoon (prime) in Hz.

    grijs=True: zonder terts, minder bovenpartialen, iets ontstemd en dof.
    """
    rt = 3.2 * grootte * (500.0 / f) ** 0.45
    if sec is None:
        sec = min(6.0, rt * 1.1 + 0.2)
    t = tijd(sec)
    y = np.zeros(len(t))
    for r, a, d in KLOK:
        if grijs:
            if abs(r - 1.2) < 0.01:
                continue  # de terts ontbreekt: hol, neutraal
            if r > 3.1:
                continue
            r = r * (1 + 0.004 * (r - 1))  # licht uitgerekt: valser
        fr = f * r
        if fr > 17000:
            continue
        hoog = 1.0 if r <= 2.0 else helder
        tau = max(0.04, rt * d / 6.9)
        # doublet: twee bijna gelijke modi geven het trage zweven van echt brons
        dw = rng.uniform(0.4, 1.6) * (1 if r > 1 else 0.4)
        for s in (-1, 1):
            ph = rng.uniform(0, 2 * np.pi)
            y += 0.5 * a * hoog * np.exp(-t / tau) * np.sin(2 * np.pi * (fr + s * dw / 2) * t + ph)
    # aanslag: klepel op brons, kort en metalig
    k = n(0.006)
    klepel = rng.standard_normal(k) * np.exp(-np.arange(k) / (k / 5))
    klepel = filt(klepel, "highpass", min(2 * f, 6000), 2)
    y[:k] += 0.35 * slag * klepel * (0.3 if grijs else 1.0)
    y[: n(0.0015)] *= np.linspace(0, 1, n(0.0015))
    if grijs:
        y = filt(y, "lowpass", 2600, 2)
    return fade(y, 0, 0.15)


# ---------------------------------------------------------------- water (punt 2)
def bel(f0, amp, stijg=0.08, maxsec=0.3):
    """Eén luchtbel in water (Minnaert-resonantie, van den Doel 2005).

    Demping d = 0,043 f + 0,0014 f^1,5 per seconde; de toon stijgt terwijl de
    bel naar het oppervlak gaat: f(t) = f0 (1 + stijg * d * t).
    """
    d = 0.043 * f0 + 0.0014 * f0**1.5
    sec = min(maxsec, 6.0 / d)
    t = tijd(sec)
    f = f0 * (1 + stijg * d * t)
    y = np.sin(2 * np.pi * np.cumsum(f) / SR) * np.exp(-d * t)
    k = max(2, n(0.0006))
    y[:k] *= np.linspace(0, 1, k)
    return amp * y


def golfslag(sec, kleur):
    """Water tegen een kademuur: golven met een zwiep en een wolk bellen."""
    y = np.zeros(n(sec))
    t = rng.uniform(0, 0.8)
    lo, hi = (380, 3600) if kleur else (220, 1100)
    while t < sec:
        sterk = rng.uniform(0.5, 1.0)
        # zwiep: water dat langs de steen omhoog loopt en terugvalt
        zl = rng.uniform(0.6, 1.1)
        zt = tijd(zl)
        zw = filt(roze(zl), "bandpass", [lo * 0.6, hi * 0.8], 2)
        zw = rmsnorm(zw) * np.interp(zt, [0, 0.22 * zl, zl], [0, 1, 0]) ** 1.5 * 0.10 * sterk
        leg(y, zw, t)
        # bellenwolk: dicht op de top van de golf, dan dunner
        for _ in range(int(rng.poisson(18 if kleur else 11) * sterk) + 2):
            t0 = t + 0.15 * zl + rng.exponential(0.18)
            f0 = np.exp(rng.uniform(np.log(lo), np.log(hi)))
            leg(y, bel(f0, rng.uniform(0.25, 1.0) * (f0 / 500) ** -0.35 * sterk), t0)
        t += rng.uniform(1.4, 3.1)
    # het zachte geruis van open water ertussen
    y += 0.02 * rmsnorm(filt(roze(sec), "lowpass", 500 if not kleur else 900, 2))
    return y


def druppel():
    """Druppel in een plas: een kleine bel die snel omhoog schiet + een tikje."""
    f0 = rng.uniform(1300, 2300)
    y = bel(f0, 1.0, stijg=0.55, maxsec=0.12)
    tik = filt(rng.standard_normal(n(0.002)), "highpass", 3000, 2) * 0.25
    y[: len(tik)] += tik
    return fade(y, 0, 0.02)


def leeglopen(sec):
    """Water zakt weg door de duiker: klokken van grote bellen, dalend."""
    y = np.zeros(n(sec))
    t = 0.15
    while t < sec - 0.2:
        rel = t / sec
        f_basis = 520 - 330 * rel  # de holte wordt groter: de klok zakt
        for i in range(rng.integers(3, 7)):
            leg(y, bel(f_basis * rng.uniform(0.85, 1.2), rng.uniform(0.5, 1.0), stijg=0.15), t + i * rng.uniform(0.004, 0.012))
        t += 1.0 / np.interp(rel, [0, 0.3, 1], [3.0, 6.5, 3.5]) * rng.uniform(0.7, 1.3)
    tt = tijd(sec)
    stroom = svf_bandpass(roze(sec) / 30, np.interp(tt, [0, sec], [900, 260]), 3.0)
    y += 0.25 * rmsnorm(stroom) * np.sqrt(np.mean(y**2))
    return y * np.interp(tt, [0, 0.4, sec * 0.7, sec], [0, 1, 0.7, 0])


def wind(sec):
    """Wind langs de kade: twee banden met vlagen (alleen grijs, zacht)."""
    t = tijd(sec)
    vlaag = 0.55 + 0.45 * filt(rng.standard_normal(len(t)), "lowpass", 0.4, 2) * 18
    vlaag = np.clip(vlaag, 0.15, 1.2)
    fc = 420 + 260 * vlaag
    nz = roze(sec)
    y = svf_bandpass(nz / np.std(nz), fc, 2.5) + 0.3 * filt(nz / np.std(nz), "lowpass", 250, 2)
    return y * vlaag


# ---------------------------------------------------------------- spelergeluid (punt 3)
P1_MODI = [(238, 0.75, 0.075), (431, 0.6, 0.06), (702, 0.42, 0.045), (1068, 0.33, 0.032),
           (1507, 0.22, 0.022), (2185, 0.13, 0.015), (3090, 0.07, 0.01)]
KOPER = [(2410, 0.10, 0.18), (3895, 0.06, 0.13), (5520, 0.035, 0.09)]


def p1_slag():
    """Levend: zwaai met stoffen flapper, een harde aanslag, hout met lijf en
    een korte koperen naklank (speler 1 = warm koper en hout, A5)."""
    r = np.random.default_rng(1066)
    sec = 0.5
    t = tijd(sec)
    i0 = n(0.06)  # treffer
    tt = t[: len(t) - i0]
    # zwaai: bandpass die omhoog veegt, met fladderend stof (± 38 Hz)
    nz = r.standard_normal(len(t))
    sweep = np.interp(t, [0, 0.03, 0.07, sec], [450, 1100, 3600, 2400])
    zwaai = svf_bandpass(nz, sweep, 1.8)
    zwaai *= np.interp(t, [0, 0.03, 0.058, 0.12, sec], [0, 0.55, 1.0, 0.1, 0])
    zwaai *= 1 + 0.35 * np.sin(2 * np.pi * 38 * t) * np.interp(t, [0, 0.06, 0.1], [1, 1, 0])
    # aanslag: 1,5 ms klik, breedband
    klik = np.zeros(len(t))
    k = n(0.0015)
    klik[i0 : i0 + k] = filt(r.standard_normal(k), "highpass", 1800, 2) * np.linspace(1, 0, k)
    # hout: modi met kleine spreiding
    hout = np.zeros(len(t))
    for fr, a, tau in P1_MODI:
        fr *= r.uniform(0.985, 1.015)
        hout[i0:] += a * np.exp(-tt / tau) * np.sin(2 * np.pi * fr * tt + r.uniform(0, 6.3))
    # koper: dunne, langere naklank boven het hout
    koper = np.zeros(len(t))
    for fr, a, tau in KOPER:
        koper[i0:] += a * np.exp(-tt / tau) * np.sin(2 * np.pi * fr * tt + r.uniform(0, 6.3))
    # lijf: korte lage plof met dalende toon
    lijf = np.zeros(len(t))
    f_lijf = 70 * np.exp(-tt / 0.05) + 72
    lijf[i0:] = np.sin(2 * np.pi * np.cumsum(f_lijf) / SR) * np.exp(-tt / 0.055)
    # gruis: een paar korte tikjes erna (splinters, druppels van de vijand)
    gruis = np.zeros(len(t))
    for _ in range(5):
        j = i0 + n(r.uniform(0.008, 0.06))
        g = n(0.0025)
        gruis[j : j + g] += filt(r.standard_normal(g), "bandpass", [2500, 7000], 2) * r.uniform(0.15, 0.4)
    y = 0.55 * zwaai + 0.9 * klik + 0.7 * hout + 0.5 * koper + 0.5 * lijf + 0.6 * gruis
    return fade(y, 0.002, 0.06)


def merk_zet(grijs=False):
    """Lichtvonk: een heel klein klokje (amber = warm, niet schril) + glinstering."""
    f = 1760.0
    y = klok(f, 0.9, grootte=0.35, grijs=grijs, helder=0.6, slag=0.6)
    t = tijd(0.9)
    glans = np.zeros(len(t))
    for fr in (3520 * 1.003, 4400, 5270):
        glans += np.sin(2 * np.pi * fr * t + rng.uniform(0, 6.3)) * np.exp(-t / 0.08)
    glans *= 1 + 0.5 * np.sin(2 * np.pi * 23 * t)  # trilling: vonk
    y = 0.8 * y + (0.06 if grijs else 0.14) * glans
    return fade(y, 0.001, 0.2)


def merk_zoem(sec, grijs=False):
    """Zacht zoemen zolang het merk leeft (aan het merk, zeer stil)."""
    t = tijd(sec)
    f = 880.0
    y = np.sin(2 * np.pi * f * t) + 0.3 * np.sin(2 * np.pi * 2 * f * 1.001 * t)
    y *= 0.5 + 0.5 * np.sin(2 * np.pi * 5.5 * t)
    if grijs:
        y = filt(y, "lowpass", 1400, 2)
    return fade(y, 0.08, 0.06)


AFTEL_TONEN = [880.00, 987.77, 1108.73, 1174.66]  # A5 B5 C#6 D6: stijgt naar de grondtoon


def aftel_slag(i, grijs=False):
    return klok(AFTEL_TONEN[i], 1.6, grootte=0.55, grijs=grijs, helder=0.75, slag=0.8)


def merksprong():
    """Echo schiet naar het merk: korte, holle zip omhoog (40 ms aanloop + staart)."""
    sec = 0.16
    t = tijd(sec)
    sweep = np.interp(t, [0, 0.04, sec], [700, 5200, 6000])
    y = svf_bandpass(ruis(sec), sweep, 6.0) * np.interp(t, [0, 0.02, 0.045, sec], [0, 1, 0.5, 0])
    return comb_hol(y)


def ontploffing(k=1, grijs=False):
    """Uitbarsting van licht en schaduw, geen vleeswond (pitch §6, PEGI 12).

    Schaduw: diepe plof + donkere ruisgolf. Licht: een grote klok op de
    grondtoon D5 met hum D4, plus lichtdeeltjes (kleine klokjes).
    k = schakel in de ketting (1..5): elke schakel klinkt groter en hoger.
    """
    sec = 3.4
    t = tijd(sec)
    y = np.zeros(len(t))
    f_plof = 60 * np.exp(-t / 0.08) + 48
    y += 0.5 * np.sin(2 * np.pi * np.cumsum(f_plof) / SR) * np.exp(-t / (0.16 + 0.02 * k))
    golf = filt(ruis(sec), "lowpass", 700 if grijs else 1100, 2) * env_ad(sec, 0.004, 0.16)
    y += 0.55 * golf
    licht = klok(587.33, sec, grootte=1.25, grijs=grijs, helder=0.9, slag=1.0)
    y += (0.8 if grijs else 0.85) * licht
    aantal = (5 if grijs else 9) + 3 * (k - 1)
    penta = [1174.66, 1318.51, 1479.98, 1760.0, 1975.53, 2349.32]
    for _ in range(aantal):
        t0 = rng.uniform(0.03, 0.9) ** 1.6
        f = rng.choice(penta) * (2 if rng.random() < 0.25 else 1)
        v = klok(f, 0.7, grootte=0.18, grijs=grijs, helder=0.5, slag=0.3)
        leg(y, v, t0, (0.05 if grijs else 0.085) * rng.uniform(0.5, 1.0))
    if grijs:
        y = filt(y, "lowpass", 4200, 2)
    y = filt(y, "highpass", 40, 2)
    return fade(y, 0, 0.4)


def ketting_klok(k, grijs=False):
    """Elke volgende schakel: een klok een stap hoger in de pentatoniek."""
    penta = [587.33, 739.99, 880.0, 987.77, 1174.66]
    return klok(penta[min(k, 5) - 1], 2.4, grootte=0.9, grijs=grijs, helder=0.8, slag=0.9)


def comb_hol(x, ms=4.6, g=0.62):
    """Holle buis: terugkoppelende kam (resonanties om de 1/ms)."""
    m = n(ms / 1000)
    a = np.zeros(m + 1)
    a[0] = 1
    a[-1] = -g
    return signal.lfilter([1 - g], a, x)


def echo_versie(x, verzwakking_db=-7.0):
    """Het geluid van de echo = het geluid van de eigenaar, maar hol.

    Zelfde ritme en toonhoogte (je herkent je eigen slag), zonder lijf
    (< 260 Hz weg), door een holle kam, met een omgekeerde aanloop
    (het geluid komt uit het verleden terug) en breder in stereo.
    """
    droog = filt(x, "highpass", 260, 4)
    hol = 0.55 * comb_hol(droog) + 0.45 * filt(droog, "bandpass", [700, 4200], 2)
    staart = signal.fftconvolve(droog, IR_VERZONKEN[:, 0])[: n(0.35)]
    voor = fade(staart[::-1], 0.12, 0.0) * 0.35
    y = np.concatenate([voor, hol])
    st = np.stack([y, np.concatenate([np.zeros(n(0.011)), y])[: len(y)]], axis=1)  # Haas 11 ms
    return st * 10 ** (verzwakking_db / 20), len(voor) / SR


def sprong():
    """Afzet: korte stoffen flap + voet op natte steen."""
    sec = 0.3
    t = tijd(sec)
    flap = filt(ruis(sec), "bandpass", [400, 2600], 2) * np.interp(t, [0, 0.01, 0.07, sec], [0, 1, 0.1, 0])
    voet = filt(ruis(sec), "lowpass", 900, 2) * env_ad(sec, 0.001, 0.025)
    plof = np.sin(2 * np.pi * 120 * t) * env_ad(sec, 0.001, 0.03)
    return 0.4 * flap + 0.7 * voet + 0.5 * plof


def landing():
    """Landing op natte steen: voet, plof, en een paar spatbelletjes."""
    sec = 0.35
    t = tijd(sec)
    voet = filt(ruis(sec), "lowpass", 1400, 2) * env_ad(sec, 0.001, 0.04)
    plof = np.sin(2 * np.pi * (90 * np.exp(-t / 0.05) + 60) * t) * env_ad(sec, 0.001, 0.05)
    plets = np.zeros(len(t))
    for _ in range(6):
        leg(plets, bel(rng.uniform(1500, 3800), rng.uniform(0.3, 0.8), 0.3, 0.08), rng.uniform(0.004, 0.05))
    return 0.7 * voet + 0.7 * plof + 0.22 * plets


def dooft(grijs=False):
    """Merk dooft zonder ontploffing: de leidtoon C#6, gedempt en dalend."""
    y = klok(1108.73, 1.0, grootte=0.4, grijs=True, helder=0.3, slag=0.4)
    t = tijd(1.0)
    y = filt(y, "lowpass", 1800, 2) * np.exp(-t / 0.18)
    zucht = filt(ruis(1.0), "bandpass", [600, 2400], 2) * np.interp(t, [0, 0.05, 0.4, 1.0], [0, 0.25, 0.05, 0])
    return fade(0.8 * y + 0.2 * zucht, 0, 0.2)


# ---------------------------------------------------------------- muziek (punt 4)
def harmonium(f, sec, helder=1.0, celeste_cent=3.0, inzet=0.09):
    """Rietorgel: per toon twee rieten (celeste), riet-geruis synchroon met de
    periode, een toetsklik, en balgdruk die volume én klankkleur stuurt."""
    t = tijd(sec)
    # balgdruk: traag ademen + het trappen van de balg (± 1,1 Hz) + onrust
    onrust = filt(rng.standard_normal(len(t)), "lowpass", 2.0, 2) * 9
    druk = 1 + 0.035 * np.sin(2 * np.pi * 0.31 * t + rng.uniform(0, 6)) \
        + 0.012 * np.sin(2 * np.pi * 1.1 * t + rng.uniform(0, 6)) + 0.01 * onrust
    druk *= np.clip(t / inzet, 0, 1) ** 1.5  # het riet spreekt aan
    y = np.zeros(len(t))
    for cent, niveau in ((-celeste_cent / 2, 1.15), (celeste_cent / 2, 0.85)):  # ongelijke rieten: zachter zweven
        fr = f * 2 ** (cent / 1200)
        # bij het aanspreken staat het riet heel even iets lager
        fr_t = fr * (1 - 0.004 * np.exp(-t / 0.04))
        fase = 2 * np.pi * np.cumsum(fr_t) / SR + rng.uniform(0, 6)
        for h in range(1, 16):
            if f * h > 9000:
                break
            a = (1.0 / h) * (0.6 if h % 2 == 0 else 1.0) * (helder ** (h / 4))
            y += 0.5 * niveau * a * np.sin(h * fase) * druk ** (1 + 0.12 * h)  # meer druk = helderder
    # riet-geruis: lucht die langs het riet blaast, één stoot per periode
    puls = (0.5 + 0.5 * np.cos(2 * np.pi * np.cumsum(np.full(len(t), f)) / SR)) ** 8
    adem = filt(rng.standard_normal(len(t)), "bandpass", [1200, 5000], 2) * puls * druk
    y += 0.018 * helder * rmsnorm(adem) * np.sqrt(np.mean(y**2) + 1e-12)
    # toetsklik: hout op hout, heel kort
    k = n(0.004)
    y[:k] += 0.04 * filt(rng.standard_normal(k), "bandpass", [800, 4000], 2) * np.linspace(1, 0, k)
    return y


def gemaal(sec, start_t=0.0):
    """Draaiend gemaal: pompslag, waterstoot uit het schoepenrad, 50 Hz-brom.

    Het gemaal versnelt vanaf start_t naar zijn vaste periode van 0,8 s.
    """
    y = np.zeros(n(sec))
    t = start_t + 0.0
    periode = 1.9
    slag = 0
    while t < sec - 0.1:
        k = n(0.9)
        tt = np.arange(k) / SR
        plof = np.sin(2 * np.pi * (52 * np.exp(-tt / 0.15) + 46) * tt) * np.exp(-tt / 0.2)
        stoot = filt(rng.standard_normal(k), "bandpass", [280, 1100], 2) * np.interp(
            tt, [0, 0.12, 0.25, 0.9], [0, 0.6, 0.35, 0]
        )
        # het schoepenrad gooit water: een handvol bellen in de stoot
        spat = np.zeros(k)
        for _ in range(8):
            leg(spat, bel(rng.uniform(350, 1400), rng.uniform(0.2, 0.6)), rng.uniform(0.08, 0.35))
        deel = 0.8 * plof + 0.5 * stoot + 0.35 * spat
        if slag % 2 == 1:
            for fr, a, tau in [(310, 0.25, 0.08), (742, 0.15, 0.05), (1214, 0.09, 0.03)]:
                deel += a * np.exp(-tt / tau) * np.sin(2 * np.pi * fr * tt)
        leg(y, deel, t, min(1.0, 0.35 + 0.2 * slag))
        t += periode
        periode = max(0.8, periode * 0.78)
        slag += 1
    tt = tijd(sec)
    brom = sum(np.sin(2 * np.pi * 50 * h * tt) / h for h in (1, 2, 3)) * 0.05
    brom *= np.clip((tt - start_t) / 1.5, 0, 1)
    return filt(y + brom, "highpass", 45, 2)  # punt 7: geen subsonisch laag


def machine_aan():
    """De poldermachine slaat aan: zware koppeling + metaal."""
    sec = 2.0
    t = tijd(sec)
    y = np.sin(2 * np.pi * (60 * np.exp(-t / 0.2) + 40) * t) * np.exp(-t / 0.5)
    for fr, a, tau in [(118, 0.5, 0.6), (287, 0.35, 0.4), (611, 0.22, 0.25), (1043, 0.12, 0.15), (1688, 0.06, 0.08)]:
        y += a * np.exp(-t / tau) * np.sin(2 * np.pi * fr * t + rng.uniform(0, 6))
    y += 0.4 * filt(ruis(sec), "lowpass", 500, 2) * env_ad(sec, 0.002, 0.06)
    return y


# ---------------------------------------------------------------- de mix
def bouw():
    st = {k: Spoor(naam=k) for k in ("bed", "muziek", "speler", "echo", "combat")}
    t_pomp = 6.2
    t_kleur = 7.4  # de kleurgolf (+- 2 s) begint hier
    sec = DUUR
    tt = tijd(sec)
    x_grijs = np.clip((t_kleur + 1.6 - tt) / 2.0, 0, 1)  # kruisfade over +- 2 s
    x_kleur = 1 - x_grijs
    # ---- bed. Grijs: dof, dichtbij, droog. Opgepompt: helder, verder weg.
    wg = np.stack([golfslag(sec, False), golfslag(sec, False)], axis=1)
    wg = filt(wg, "lowpass", 1100, 2)
    wk = np.stack([golfslag(sec, True), golfslag(sec, True)], axis=1)
    bed = rmsnorm(wg) * (0.030 * x_grijs)[:, None] + rmsnorm(wk) * (0.028 * x_kleur)[:, None]
    wi = wind(sec)
    bed += pan(rmsnorm(wi) * 0.010 * (0.35 + 0.65 * x_grijs), -0.3)
    for t0 in (0.35, 1.9, 3.7, 5.3):
        d = pan(druppel(), rng.uniform(-0.7, 0.7)) * 0.05
        bed[n(t0) : n(t0) + len(d)] += d
    for t0 in (9.6, 12.4, 13.9):  # opgepompt: druppels van het schoepenrad, verder weg
        d = pan(druppel(), rng.uniform(-0.6, 0.6)) * 0.035
        bed[n(t0) : n(t0) + len(d)] += d
    # verre, verzonken klok (alleen grijs)
    ver = filt(klok(196.0, 5.0, grootte=1.6, grijs=True), "lowpass", 600) * 0.12
    bed[n(1.0) : n(1.0) + len(ver)] += pan(ver, 0.45)
    gm = gemaal(sec, start_t=t_pomp + 0.9)
    bed += pan(filt(gm, "lowpass", 2200), 0.25) * 0.24
    st["bed"].x += bed
    st["bed"].zet(rmsnorm(leeglopen(2.6)) * 0.035, t_pomp + 0.1, 0, -0.15)
    st["combat"].zet(machine_aan() * 0.55, t_pomp, 0, 0.25, log="machine_aan")
    # ---- muziek: grijs = lege kwint (D2 + A2), dun; opgepompt = D-groot add9
    drone = (harmonium(73.42, sec, 0.3, inzet=0.6) + 0.8 * harmonium(110.0, sec, 0.3, inzet=0.6)) * 0.03
    drone = filt(drone, "lowpass", 750)
    akk = np.zeros(n(sec))
    t_akk = t_pomp + 1.0
    for i, (f, a) in enumerate(((146.83, 1.0), (220.0, 0.85), (185.0, 0.8), (329.63, 0.5), (659.26, 0.22))):
        stem = harmonium(f, sec - t_akk, 1.0)
        leg(akk, a * stem, t_akk + 0.14 * i)  # de stemmen zetten na elkaar in
    akk = filt(akk, "lowpass", 5000) * 0.020
    env_akk = (0.15 + 0.85 * np.clip((tt - t_akk) / 2.4, 0, 1) ** 1.5) * np.clip((DUUR - tt) / 1.5, 0, 1)
    env_drone = 0.55 + 0.45 * x_grijs
    m_l = drone * env_drone + akk * env_akk
    m_r = drone * env_drone + np.roll(akk, n(0.007)) * env_akk
    st["muziek"].x += np.stack([m_l, m_r], axis=1)
    st["combat"].zet(klok(293.66, 5.0, grootte=1.8, grijs=False, helder=0.8) * 0.20, t_pomp + 1.2, 0, 0.1,
                     log="bloei_D4")

    # ---- A: grijze wijk, één merk
    def slag_met_merk(t_hit, grijs, p, naam):
        st["speler"].zet(p1_slag(), t_hit - 0.06, -5, p, log=f"p1_slag_{naam}", aanslag=0.06)
        st["combat"].zet(merk_zet(grijs), t_hit, -9, p + 0.1, log=f"merk_zet_{naam}")

    def echo_slag(t_hit, p, naam):
        e, voor = echo_versie(p1_slag(), -7)
        st["echo"].zet(e, t_hit - 0.06 - voor, 0, p, log=f"echo_slag_{naam}", aanslag=0.06 + voor)

    def aftelling(t_hit, grijs, p, tot_slag, naam):
        t_af = t_hit + (LEVENSDUUR - AFTEL) * TICK
        for i in range(tot_slag):
            st["combat"].zet(aftel_slag(i, grijs), t_af + i * AFTEL_STAP * TICK, -6 + 1.5 * i, p,
                             log=f"aftelslag_{i + 1}_{naam}")
        z = merk_zoem((LEVENSDUUR - AFTEL + tot_slag * AFTEL_STAP) * TICK, grijs)
        st["combat"].zet(z * 0.03, t_hit + 0.05, 0, p)

    p_vijand = 0.25
    t1 = 0.60
    slag_met_merk(t1, True, p_vijand, "grijs")
    st["speler"].zet(sprong(), 1.20, -8, -0.1)
    st["speler"].zet(landing(), 1.78, -8, 0.05)
    aftelling(t1, True, p_vijand, 2, "grijs")
    t_echo = t1 + D_TICKS * TICK
    echo_slag(t_echo, p_vijand - 0.15, "grijs")
    st["echo"].zet(merksprong(), t_echo - 0.04, -12, p_vijand - 0.1)
    st["combat"].zet(ontploffing(1, grijs=True), t_echo, -3, p_vijand, log="ontploffing_grijs")
    e, voor = echo_versie(sprong(), -8)
    st["echo"].zet(e, 1.20 + D_TICKS * TICK - voor, 0, -0.25)
    e, voor = echo_versie(landing(), -8)
    st["echo"].zet(e, 1.78 + D_TICKS * TICK - voor, 0, -0.1)

    # ---- C: opgepompte wijk, twee merken, ketting
    ta, tb = 9.00, 9.30
    pa, pb = 0.15, 0.4
    slag_met_merk(ta, False, pa, "kleur_a")
    slag_met_merk(tb, False, pb, "kleur_b")
    aftelling(ta, False, pa, 2, "kleur")  # één aftelling tegelijk: merk A loopt eerst af
    z = merk_zoem((LEVENSDUUR - AFTEL) * TICK + 0.5, False)
    st["combat"].zet(z * 0.02, tb + 0.05, 0, pb)
    t_e = ta + D_TICKS * TICK
    echo_slag(t_e, pa - 0.15, "kleur_a")
    st["echo"].zet(merksprong(), t_e - 0.04, -12, pa - 0.1)
    st["combat"].zet(ontploffing(1, grijs=False), t_e, -3, pa, log="ontploffing_k1")
    st["combat"].zet(ketting_klok(2) * 0.6, t_e + 0.045, -2, pb, log="ketting_k2_rol")
    st["combat"].zet(ontploffing(2, grijs=False) * 0.6, t_e + TICK, -6, pb)
    echo_slag(tb + D_TICKS * TICK, pb - 0.15, "kleur_b")

    # ---- bed en muziek dukken onder het gevecht (§8: 3-6 dB), sidechain op Combat + Speler
    sc = (st["combat"].x + st["speler"].x).mean(axis=1)
    om = np.sqrt(np.convolve(sc**2, np.ones(n(0.01)) / n(0.01), mode="same"))
    rel = n(0.35)
    houd = signal.lfilter([1 / rel], [1, -(1 - 1 / rel)], om)  # trage release
    om = np.maximum(om, houd)
    drempel = 0.12 * np.max(om)  # volle duk vanaf -18 dB onder de luidste gevechtsklank
    duk_db = -5.0 * np.clip(om / drempel, 0, 1)
    duk = 10 ** (duk_db / 20)
    st["bed"].x *= duk[:, None]
    st["muziek"].x *= duk[:, None]
    DUK["max_db"] = round(float(np.min(duk_db)), 1)
    DUK["op_2.6s_db"] = round(float(duk_db[n(2.7)]), 1)
    DUK["op_4.5s_db"] = round(float(duk_db[n(4.5)]), 1)

    # ---- galm (send/return per toestand). Grijs droger (punt 6).
    droog = st["speler"].x + st["echo"].x + st["combat"].x + 0.6 * st["muziek"].x
    droog = filt(droog, "highpass", 180, 2)  # geen laag in de galm: houdt de mix helder
    nat_grijs = galm(droog * x_grijs[:, None], IR_VERZONKEN, 0.20)
    nat_kleur = galm(droog * x_kleur[:, None], IR_BELFORT, 0.36)
    st["galm"] = Spoor(naam="galm")
    st["galm"].x = nat_grijs + nat_kleur
    return st


def levensduur_reeks(grijs=True):
    """Een merk zonder echo, van zetten tot doven (E-14b): zet op tick 0,
    slagen op D-30, D-15, D (C#6, de echo komt niet), zachte slag 4 (C#6,
    -6 dB) op D+15, doven op D+30."""
    t0 = 0.1
    sec = t0 + LEVENSDUUR * TICK + 1.3
    y = np.zeros(n(sec))
    ticks = {}
    leg(y, merk_zet(grijs), t0, 10 ** (-9 / 20))
    ticks["merk_zet"] = 0
    for i, (tk, toon, g) in enumerate(((D_TICKS - 30, 0, -6), (D_TICKS - 15, 1, -4.5), (D_TICKS, 2, -3),
                                       (D_TICKS + 15, 2, -9))):
        leg(y, aftel_slag(toon, grijs), t0 + tk * TICK, 10 ** (g / 20))
        ticks[f"slag_{i + 1}"] = tk
    leg(y, dooft(), t0 + LEVENSDUUR * TICK, 10 ** (-6 / 20))
    ticks["merk_dooft"] = LEVENSDUUR
    z = merk_zoem(LEVENSDUUR * TICK, grijs) * 0.03
    leg(y, z, t0 + 0.05)
    return y, t0, ticks


# ---------------------------------------------------------------- meten
K_B1 = [1.53512485958697, -2.69169618940638, 1.19839281085285]
K_A1 = [1.0, -1.69065929318241, 0.73248077421585]
K_B2 = [1.0, -2.0, 1.0]
K_A2 = [1.0, -1.99004745483398, 0.99007225036621]


def k_weeg(x):
    y = signal.lfilter(K_B1, K_A1, x, axis=0)
    return signal.lfilter(K_B2, K_A2, y, axis=0)


def blok_ms(x, blok, stap):
    y = k_weeg(x)
    b, s = n(blok), n(stap)
    out = []
    for i in range(0, max(1, len(y) - b + 1), s):
        out.append(np.sum(np.mean(y[i : i + b] ** 2, axis=0)))
    return np.array(out)


def lufs_geintegreerd(x):
    z = blok_ms(x, 0.4, 0.1)
    l = -0.691 + 10 * np.log10(z + 1e-12)
    z1 = z[l > -70]
    if len(z1) == 0:
        return -np.inf
    rel = -0.691 + 10 * np.log10(np.mean(z1)) - 10
    z2 = z[(l > -70) & (l > rel)]
    return -0.691 + 10 * np.log10(np.mean(z2))


def lufs_max(x, venster):
    z = blok_ms(x, venster, 0.1)
    return float(np.max(-0.691 + 10 * np.log10(z + 1e-12)))


def true_peak_db(x):
    up = signal.resample_poly(x, 4, 1, axis=0)
    return 20 * np.log10(np.max(np.abs(up)) + 1e-12)


def banden(x, t0=None, t1=None):
    m = x.mean(axis=1) if x.ndim == 2 else x
    if t0 is not None:
        m = m[n(t0) : n(t1)]
    f, p = signal.welch(m, SR, nperseg=8192)
    tot = np.sum(p)
    grens = [(20, 60), (60, 250), (250, 2000), (2000, 8000), (8000, 20000)]
    aandeel = {f"{a}-{b} Hz": round(float(100 * np.sum(p[(f >= a) & (f < b)]) / tot), 1) for a, b in grens}
    centroid = float(np.sum(f * p) / tot)
    return aandeel, round(centroid)


def partialen(sig, f0, top=8):
    w = np.hanning(len(sig))
    spec = np.abs(np.fft.rfft(sig * w, 1 << 19))
    fr = np.fft.rfftfreq(1 << 19, 1 / SR)
    pk, _ = signal.find_peaks(spec, distance=int(30 / (fr[1])), height=spec.max() * 0.02)
    pk = pk[np.argsort(spec[pk])[::-1][:top]]
    return sorted(round(float(fr[i] / f0), 3) for i in pk)


def textuur(x):
    """Hoe 'korrelig' (gebeurtenissen) tegenover 'egaal' (ruis) een geluid is.

    kurtosis van de omhullende (5 ms): ruis ± 0-1, losse gebeurtenissen hoog;
    spectrale vlakheid (Wiener): 1 = witte ruis, 0 = zuivere tonen.
    """
    m = x.mean(axis=1) if x.ndim == 2 else x
    om = np.sqrt(np.convolve(m**2, np.ones(n(0.005)) / n(0.005), mode="valid"))[:: n(0.005)]
    om = om - om.mean()
    kurt = float(np.mean(om**4) / (np.mean(om**2) ** 2 + 1e-24) - 3)
    f, p = signal.welch(m, SR, nperseg=4096)
    p = p[(f > 100) & (f < 8000)]
    vlak = float(np.exp(np.mean(np.log(p + 1e-30))) / np.mean(p))
    return {"kurtosis_omhullende": round(kurt, 1), "spectrale_vlakheid": round(vlak, 3)}


def rt_per_band(ir):
    """T20 x 3 (Schroeder) per band, in s."""
    out = {}
    for naam, (soort, f) in (("<500 Hz", ("lowpass", 500)), ("0,5-3 kHz", ("bandpass", [500, 3000])),
                             ("> 3 kHz", ("highpass", 3000))):
        h = filt(ir[:, 0], soort, f, 4)
        e = np.cumsum((h**2)[::-1])[::-1]
        db = 10 * np.log10(e / e[0] + 1e-30)
        i5, i25 = np.argmax(db <= -5), np.argmax(db <= -25)
        out[naam] = round(3 * (i25 - i5) / SR, 2)
    return out


def vroege_reflecties(ir, ms=80):
    h = np.abs(ir[: n(ms / 1000), 0])
    pk, _ = signal.find_peaks(h, height=h.max() * 0.1, distance=n(0.0005))
    return int(len(pk))


def aanzet(x, t_verwacht):
    """Gemeten aanzet: eerste ms waarin de energie boven 1 kHz 6 dB boven de
    30 ms ervoor uitkomt (en boven 5 % van de piek in het venster)."""
    m = x.mean(axis=1) if x.ndim == 2 else x
    i0, i1 = n(max(0, t_verwacht - 0.04)), n(t_verwacht + 0.04)
    seg = filt(m, "highpass", 1000, 2)[i0:i1] ** 2  # de aanslag zit in het hoog
    e = np.convolve(seg, np.ones(n(0.001)) / n(0.001), mode="full")[: len(seg)]  # alleen verleden
    basis = np.mean(e[: n(0.03)])
    drempel = max(4 * basis, 0.05 * np.max(e[n(0.03):]))
    k = n(0.03) + int(np.argmax(e[n(0.03):] > drempel))
    return (i0 + k) / SR


def ebur128(pad):
    """Meting met ffmpeg ebur128 (onafhankelijk van de meting hierboven)."""
    if not shutil.which("ffmpeg"):
        return None
    r = subprocess.run(["ffmpeg", "-nostats", "-hide_banner", "-i", pad, "-af", "ebur128=peak=true+sample",
                        "-f", "null", "-"], capture_output=True, text=True)
    s = r.stderr[r.stderr.rfind("Summary:"):]
    get = lambda k: float(re.search(k + r":\s+(-?[\d.]+|-inf)", s).group(1))
    return {"I_LUFS": get("I"), "LRA_LU": get("LRA"), "true_peak_dBFS": get(r"True peak:\s+Peak"),
            "sample_peak_dBFS": get(r"Sample peak:\s+Peak")}


def meet(mix, st):
    m = {}
    m["duur_s"] = round(len(mix) / SR, 3)
    m["lufs_geintegreerd"] = round(lufs_geintegreerd(mix), 2)
    m["lufs_kort_max_3s"] = round(lufs_max(mix, 3.0), 2)
    m["lufs_momentaan_max_400ms"] = round(lufs_max(mix, 0.4), 2)
    m["sample_piek_dbfs"] = round(20 * np.log10(np.max(np.abs(mix))), 2)
    m["true_peak_dbtp"] = round(true_peak_db(mix), 2)
    m["clipping_samples"] = int(np.sum(np.abs(mix) >= 0.9999))
    m["dc_offset"] = float(np.round(np.mean(mix), 6))
    rms = np.sqrt(np.mean(mix**2))
    m["crest_factor_db"] = round(20 * np.log10(np.max(np.abs(mix)) / rms), 1)
    m["stereo_correlatie"] = round(float(np.corrcoef(mix[:, 0], mix[:, 1])[0, 1]), 2)
    m["grijs_0-6s"] = dict(zip(("banden_%", "centroid_hz"), banden(mix, 0.0, 6.0)))
    m["opgepompt_9-15s"] = dict(zip(("banden_%", "centroid_hz"), banden(mix, 9.0, 15.0)))
    bed = st["bed"].x + st["muziek"].x
    wereld = bed + st["galm"].x
    m["wereld_grijs_0-6s"] = dict(zip(("banden_%", "centroid_hz"), banden(wereld, 0.0, 6.0)))
    m["wereld_opgepompt_9-15s"] = dict(zip(("banden_%", "centroid_hz"), banden(wereld, 9.0, 15.0)))
    m["bed_lufs"] = round(lufs_geintegreerd(bed), 2)
    for naam, t0 in (("aftelslag_1_grijs", 2.10), ("aftelslag_1_kleur", 10.50), ("ontploffing_grijs", 2.60),
                     ("ontploffing_ketting", 11.00)):
        seg = st["combat"].x[n(t0) : n(t0 + 0.4)]
        bseg = bed[n(t0) : n(t0 + 0.4)]
        m[f"{naam}_boven_bed_LU"] = round(
            float(10 * np.log10(np.sum(blok_ms(seg, 0.4, 0.4)) / (np.sum(blok_ms(bseg, 0.4, 0.4)) + 1e-12))), 1
        )
    p1 = p1_slag()
    e, _ = echo_versie(p1, 0)
    bp, cp = banden(p1)
    be, ce = banden(e)
    m["p1_slag"] = {"banden_%": bp, "centroid_hz": cp, **textuur(p1)}
    m["echo_slag"] = {"banden_%": be, "centroid_hz": ce}
    m["water_grijs_bed_0-6s"] = textuur(st["bed"].x[n(0.0) : n(6.0)])
    m["klok_D5_kleur_partialen"] = partialen(klok(587.33, 2.0, grootte=1.25), 587.33)
    m["klok_D5_grijs_partialen"] = partialen(klok(587.33, 2.0, grootte=1.25, grijs=True), 587.33)
    m["galm_belfort"] = {"rt_s": rt_per_band(IR_BELFORT), "vroege_reflecties_80ms": vroege_reflecties(IR_BELFORT)}
    m["galm_verzonken"] = {"rt_s": rt_per_band(IR_VERZONKEN),
                           "vroege_reflecties_80ms": vroege_reflecties(IR_VERZONKEN)}
    m["aftelling_tick_s"] = {
        "slag_1": round((LEVENSDUUR - AFTEL) * TICK, 3),
        "echo_op_slag": 1 + (D_TICKS - (LEVENSDUUR - AFTEL)) // AFTEL_STAP,
    }
    # timing: gemeten aanzet per gebeurtenis tegenover de tick waarop hij hoort
    tim = {}
    for spoor, naam, t in LOG:
        gemeten = aanzet(st[spoor].x, t)
        tim[naam] = {"t_s": t, "tick": round(t / TICK, 2), "fout_ms": round(1000 * (gemeten - t), 1)}
    m["timing"] = tim
    m["timing_max_fout_ms"] = max(abs(v["fout_ms"]) for v in tim.values())
    return m


def schrijf_wav(pad, x):
    x16 = np.clip(np.round(x * 32767), -32768, 32767).astype(np.int16)
    wavfile.write(pad, SR, x16)


def master(x):
    """Gain naar het LUFS-doel, dan een zachte limiter op de true peak."""
    g = DOEL_LUFS - lufs_geintegreerd(x)
    x = x * 10 ** (g / 20)
    plafond = 10 ** ((DOEL_TP - 0.3) / 20)
    up = np.max(np.abs(signal.resample_poly(x, 4, 1, axis=0)), axis=1)
    om = up[: 4 * len(x)].reshape(-1, 4).max(axis=1)
    om = np.maximum(om, 1e-9)
    gain = np.minimum(1.0, plafond / om)
    w = n(0.004)
    gain = _minf(gain, w)
    kern = np.hanning(2 * w + 1)
    kern /= kern.sum()
    gain = np.convolve(gain, kern, mode="same")
    return x * gain[:, None], g


def _minf(g, w):
    from scipy.ndimage import minimum_filter1d

    return minimum_filter1d(g, size=2 * w + 1)


def main():
    os.makedirs(LOS, exist_ok=True)
    st = bouw()
    mix = sum(s.x for s in st.values())
    mix = filt(mix, "highpass", 28, 2)  # geen subsonisch gerommel
    mix = np.stack([fade(mix[:, 0], 0.4, 1.2), fade(mix[:, 1], 0.4, 1.2)], axis=1)
    mix, g = master(mix)
    for _ in range(2):  # limiter kost een fractie LU: één keer bijsturen
        corr = DOEL_LUFS - lufs_geintegreerd(mix)
        if abs(corr) < 0.1:
            break
        mix, _ = master(mix)
    pad = os.path.join(UIT, "f2_merk_aftelling_carillon_placeholder.wav")
    schrijf_wav(pad, mix)
    ogg = pad[:-4] + ".ogg"
    if shutil.which("ffmpeg"):
        subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-i", pad, "-c:a", "libvorbis", "-q:a", "6", ogg],
                       check=True)
    los = {
        "p1_slag": p1_slag(),
        "echo_slag": echo_versie(p1_slag(), 0)[0],
        "merk_zet_kleur": merk_zet(False),
        "merk_zet_grijs": merk_zet(True),
        "merksprong": merksprong(),
        "ontploffing_k1_kleur": ontploffing(1, False),
        "ontploffing_k1_grijs": ontploffing(1, True),
        "ontploffing_k3_kleur": ontploffing(3, False),
        "merk_dooft": dooft(),
    }
    for i in range(4):
        los[f"aftelling_{i + 1}_kleur"] = aftel_slag(i, False)
        los[f"aftelling_{i + 1}_grijs"] = aftel_slag(i, True)
    reeks, t0_reeks, ticks_reeks = levensduur_reeks(True)
    los["merk_levensduur_zonder_echo_grijs"] = reeks
    for naam, s in los.items():
        if s.ndim == 1:
            s = np.stack([s, s], axis=1)
        schrijf_wav(os.path.join(LOS, f"{naam}_placeholder.wav"), norm(s, 10 ** (-3 / 20)))
    m = meet(mix, st)
    m["master_gain_db"] = round(g, 2)
    m["duk_bed_muziek"] = DUK
    # de reeks zonder echo: gemeten aanzet per tick (E-14b: doven op D + 30)
    m["levensduur_zonder_echo"] = {
        k: {"tick": v, "fout_ms": round(1000 * (aanzet(reeks, t0_reeks + v * TICK) - (t0_reeks + v * TICK)), 1)}
        for k, v in ticks_reeks.items()
    }
    m["ebur128_wav"] = ebur128(pad)
    if os.path.exists(ogg):
        with tempfile.TemporaryDirectory() as tmp:
            dec = os.path.join(tmp, "dec.wav")
            subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-i", ogg, dec], check=True)
            m["ebur128_ogg_gedecodeerd"] = ebur128(dec)
    try:
        import matplotlib

        matplotlib.use("Agg")
        import matplotlib.pyplot as plt

        fig, ax = plt.subplots(2, 1, figsize=(12, 6), sharex=True, gridspec_kw={"height_ratios": [1, 3]})
        mono = mix.mean(axis=1)
        tt = np.arange(len(mono)) / SR
        ax[0].plot(tt[::40], mono[::40], lw=0.4, color="#444")
        ax[0].set_ylabel("golfvorm")
        for t0, lab in ((0.6, "slag"), (2.1, "1"), (2.35, "2"), (2.6, "echo+knal"), (6.2, "oppompen"),
                        (9.0, "slag"), (9.3, "slag"), (10.5, "1"), (10.75, "2"), (11.0, "echo+ketting")):
            ax[0].axvline(t0, color="#c80", lw=0.6)
            ax[0].text(t0, 0.9 * np.max(np.abs(mono)), lab, fontsize=7, color="#a60")
        ax[1].specgram(mono, NFFT=2048, Fs=SR, noverlap=1536, cmap="magma", vmin=-130)
        ax[1].set_yscale("symlog", linthresh=500)
        ax[1].set_ylim(30, 16000)
        ax[1].set_ylabel("Hz")
        ax[1].set_xlabel("s")
        fig.suptitle("F2-fragment v2: merk-aftelling met het carillon (grijs -> opgepompt) - placeholder")
        fig.tight_layout()
        fig.savefig(os.path.join(UIT, "f2_spectrogram_placeholder.png"), dpi=110)
    except ImportError:
        pass
    print(json.dumps(m, indent=1, ensure_ascii=False))


if __name__ == "__main__":
    sys.exit(main())
