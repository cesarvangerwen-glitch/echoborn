#!/usr/bin/env python3
"""F2-referentiefragment: merk-aftelling met het carillon (T2, #66).

Alles is synthese (numpy/scipy), zonder externe samples. Vaste seed: elke run
geeft bit voor bit hetzelfde resultaat.

Opnieuw maken, vanaf de repo-root:
    python3 docs/audio/f2-fragment/bron/genereer_f2.py

Schrijft naar docs/audio/f2-fragment/:
    f2_merk_aftelling_carillon_placeholder.wav   (48 kHz, 16 bit, stereo)
    f2_merk_aftelling_carillon_placeholder.ogg   (Vorbis q6, als ffmpeg er is)
    f2_spectrogram_placeholder.png               (als matplotlib er is)
    losse-sfx/*.wav                              (de bouwstenen, los)
en print de metingen uit docs/audio/bible.md §9.

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
import shutil
import subprocess
import sys

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

    def __init__(self, sec=DUUR):
        self.x = np.zeros((n(sec), 2))

    def zet(self, sig, t0, gain_db=0.0, p=0.0):
        if sig.ndim == 1:
            sig = pan(sig, p)
        g = 10 ** (gain_db / 20)
        i = n(t0)
        j = min(len(self.x), i + len(sig))
        if j > i:
            self.x[i:j] += sig[: j - i] * g


# ---------------------------------------------------------------- galm
def galm_ir(sec, rt60, donker_hz, vroeg_ms, breedte=1.0):
    """Synthetische impulsrespons: vroege reflecties + exponentiële staart."""
    t = tijd(sec)
    ir = np.zeros((len(t), 2))
    for c in range(2):
        staart = rng.standard_normal(len(t)) * np.exp(-6.9 * t / rt60)
        staart = filt(staart, "lowpass", donker_hz, 2)
        # hoge tonen sterven sneller: tweede, donkerdere laag erbij
        staart += 0.6 * filt(rng.standard_normal(len(t)), "lowpass", donker_hz * 0.35, 2) * np.exp(
            -6.9 * t / (rt60 * 1.25)
        )
        staart[: n(vroeg_ms / 1000)] = 0
        for _ in range(9):
            d = rng.uniform(vroeg_ms * 0.15, vroeg_ms) / 1000
            staart[n(d)] += rng.uniform(0.25, 0.6) * rng.choice([-1, 1])
        ir[:, c] = staart
    m = 0.5 * (ir[:, 0] + ir[:, 1])
    ir[:, 0] = m + breedte * (ir[:, 0] - m)
    ir[:, 1] = m + breedte * (ir[:, 1] - m)
    return ir / np.sqrt(np.sum(ir**2) / 2)


def galm(x, ir, nat):
    """x stereo; geeft alleen het natte signaal terug (send/return)."""
    mono = x.mean(axis=1)
    y = np.stack([signal.fftconvolve(mono, ir[:, c])[: len(mono)] for c in range(2)], axis=1)
    return y * nat


IR_BELFORT = galm_ir(3.6, 2.9, 5200, 38, 1.0)  # opgepompt: stenen belfort, warm
IR_VERZONKEN = galm_ir(2.6, 2.1, 1500, 22, 0.7)  # grijs: dof, alsof onder water


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


# ---------------------------------------------------------------- spelergeluid
def p1_slag():
    """Levend: lucht door een zwaai + een warme, houtig-koperen tik met lijf."""
    sec = 0.42
    t = tijd(sec)
    nz = ruis(sec)
    # zwaai: bandpass die snel omhoog veegt
    sweep = np.interp(t, [0, 0.03, 0.11, sec], [500, 900, 3400, 2500])
    zwaai = svf_bandpass(nz, sweep, 2.2) * np.interp(t, [0, 0.025, 0.09, 0.2, sec], [0, 0.6, 1.0, 0.15, 0])
    # treffer op 0,06 s: modaal, inharmonisch (koper op hout), korte decay
    tr = np.zeros(len(t))
    i0 = n(0.06)
    tt = t[: len(t) - i0]
    for fr, a, tau in [(210, 1.0, 0.09), (528, 0.55, 0.06), (1130, 0.35, 0.035), (1915, 0.2, 0.02), (3300, 0.1, 0.012)]:
        tr[i0:] += a * np.exp(-tt / tau) * np.sin(2 * np.pi * fr * tt)
    # lijf: korte lage plof
    lijf = np.zeros(len(t))
    f_lijf = 70 * np.exp(-tt / 0.06) + 75
    lijf[i0:] = np.sin(2 * np.pi * np.cumsum(f_lijf) / SR) * np.exp(-tt / 0.05)
    y = 0.6 * zwaai + 0.7 * tr + 0.45 * lijf
    return fade(y, 0.002, 0.05)


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
    # schaduw
    f_plof = 60 * np.exp(-t / 0.08) + 48
    y += 0.5 * np.sin(2 * np.pi * np.cumsum(f_plof) / SR) * np.exp(-t / (0.16 + 0.02 * k))
    golf = filt(ruis(sec), "lowpass", 700 if grijs else 1100, 2) * env_ad(sec, 0.004, 0.16)
    y += 0.55 * golf
    # licht: de grote klok (D5), bij grijs zonder terts
    licht = klok(587.33, sec, grootte=1.25, grijs=grijs, helder=0.9, slag=1.0)
    y += (0.8 if grijs else 0.85) * licht
    # lichtdeeltjes: kleine klokjes in de pentatoniek van D, verspreid
    if not grijs or k > 0:
        aantal = (5 if grijs else 9) + 3 * (k - 1)
        penta = [1174.66, 1318.51, 1479.98, 1760.0, 1975.53, 2349.32]
        for _ in range(aantal):
            t0 = rng.uniform(0.03, 0.9) ** 1.6
            f = rng.choice(penta) * (2 if rng.random() < 0.25 else 1)
            v = klok(f, 0.7, grootte=0.18, grijs=grijs, helder=0.5, slag=0.3)
            i0 = n(t0)
            j = min(len(y), i0 + len(v))
            y[i0:j] += (0.05 if grijs else 0.085) * v[: j - i0] * rng.uniform(0.5, 1.0)
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
    droog = filt(x, "highpass", 260, 2)
    hol = 0.55 * comb_hol(droog) + 0.45 * filt(droog, "bandpass", [700, 4200], 2)
    # omgekeerde aanloop: de galm van de slag, achterstevoren, eindigt op de slag
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
    sec = 0.35
    t = tijd(sec)
    voet = filt(ruis(sec), "lowpass", 1400, 2) * env_ad(sec, 0.001, 0.04)
    plets = filt(ruis(sec), "bandpass", [1800, 6000], 2) * env_ad(sec, 0.003, 0.05)  # natte steen
    plof = np.sin(2 * np.pi * (90 * np.exp(-t / 0.05) + 60) * t) * env_ad(sec, 0.001, 0.05)
    return 0.7 * voet + 0.25 * plets + 0.7 * plof


def dooft(grijs=False):
    """Merk dooft zonder ontploffing: de leidtoon C#6, gedempt en dalend."""
    y = klok(1108.73, 1.0, grootte=0.4, grijs=True, helder=0.3, slag=0.4)
    t = tijd(1.0)
    y = filt(y, "lowpass", 1800, 2) * np.exp(-t / 0.18)
    zucht = filt(ruis(1.0), "bandpass", [600, 2400], 2) * np.interp(t, [0, 0.05, 0.4, 1.0], [0, 0.25, 0.05, 0])
    return fade(0.8 * y + 0.2 * zucht, 0, 0.2)


# ---------------------------------------------------------------- omgeving en muziek
def water(sec, rustig=1.0):
    """Kabbelend water tegen kademuren: roze ruis met trage, golvende filters."""
    t = tijd(sec)
    lfo = 0.5 + 0.5 * np.sin(2 * np.pi * 0.23 * t + 1.0) * np.sin(2 * np.pi * 0.071 * t)
    fc = 300 + 500 * lfo
    nz = roze(sec)
    y = svf_bandpass(nz / np.std(nz), fc, 1.3) * (0.4 + 0.6 * lfo)
    # klotsen: korte resonante korrels
    for _ in range(int(sec * 2.2 * rustig)):
        t0 = rng.uniform(0, sec - 0.2)
        f = rng.uniform(240, 720)
        g = n(0.12)
        tt = np.arange(g) / SR
        korrel = np.sin(2 * np.pi * (f + 400 * tt) * tt) * np.exp(-tt / 0.03) * rng.uniform(0.2, 0.6)
        i = n(t0)
        y[i : i + g] += korrel
    return y


def wind(sec):
    t = tijd(sec)
    fc = 500 + 350 * np.sin(2 * np.pi * 0.05 * t) + 120 * np.sin(2 * np.pi * 0.17 * t + 2)
    nz = roze(sec)
    y = svf_bandpass(nz / np.std(nz), fc, 3.0)
    return y * (0.6 + 0.4 * np.sin(2 * np.pi * 0.09 * t) ** 2)


def druppel():
    sec = 0.25
    t = tijd(sec)
    f = 1400 + 1600 * (1 - np.exp(-t / 0.01))
    return np.sin(2 * np.pi * np.cumsum(f) / SR) * env_ad(sec, 0.0005, 0.02)


def harmonium(f, sec, helder=1.0):
    """Rietorgel: additieve riettoon met trage balgadem."""
    t = tijd(sec)
    y = np.zeros(len(t))
    vib = 1 + 0.0012 * np.sin(2 * np.pi * 4.6 * t + rng.uniform(0, 6))
    fase = 2 * np.pi * f * np.cumsum(vib) / SR
    for h in range(1, 14):
        if f * h > 9000:
            break
        a = (1.0 / h) * (0.6 if h % 2 == 0 else 1.0) * (helder ** (h / 4))
        y += a * np.sin(h * fase + rng.uniform(0, 6))
    adem = 0.85 + 0.15 * np.sin(2 * np.pi * 0.31 * t + rng.uniform(0, 6))
    return y * adem


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
        plof = np.sin(2 * np.pi * (52 * np.exp(-tt / 0.15) + 40) * tt) * np.exp(-tt / 0.22)
        stoot = filt(rng.standard_normal(k), "bandpass", [280, 1100], 2) * np.interp(
            tt, [0, 0.12, 0.25, 0.9], [0, 0.6, 0.35, 0]
        )
        deel = 0.9 * plof + 0.5 * stoot
        if slag % 2 == 1:
            for fr, a, tau in [(310, 0.25, 0.08), (742, 0.15, 0.05), (1214, 0.09, 0.03)]:
                deel += a * np.exp(-tt / tau) * np.sin(2 * np.pi * fr * tt)
        i = n(t)
        j = min(len(y), i + k)
        y[i:j] += deel[: j - i] * min(1.0, 0.35 + 0.2 * slag)
        t += periode
        periode = max(0.8, periode * 0.78)
        slag += 1
    tt = tijd(sec)
    brom = sum(np.sin(2 * np.pi * 50 * h * tt) / h for h in (1, 2, 3)) * 0.06
    brom *= np.clip((tt - start_t) / 1.5, 0, 1)
    return y + brom


def leeglopen(sec):
    """Water zakt: gorgelende ruis met een dalende resonantie en belletjes."""
    t = tijd(sec)
    fc = np.interp(t, [0, sec], [950, 230])
    y = svf_bandpass(roze(sec) / 30, fc, 4.0)
    y = y / (np.std(y) + 1e-9) * np.interp(t, [0, 0.4, sec * 0.7, sec], [0, 1, 0.7, 0])
    for _ in range(int(sec * 9)):
        t0 = rng.uniform(0.1, sec - 0.15)
        f = np.interp(t0, [0, sec], [900, 300]) * rng.uniform(0.8, 1.25)
        g = n(0.07)
        tt = np.arange(g) / SR
        y[n(t0) : n(t0) + g] += 0.5 * np.sin(2 * np.pi * (f + 2500 * tt) * tt) * np.exp(-tt / 0.018)
    return y


def machine_aan():
    """De poldermachine slaat aan: zware koppeling + metaal."""
    sec = 2.0
    t = tijd(sec)
    y = np.sin(2 * np.pi * (60 * np.exp(-t / 0.2) + 36) * t) * np.exp(-t / 0.5)
    for fr, a, tau in [(118, 0.5, 0.6), (287, 0.35, 0.4), (611, 0.22, 0.25), (1043, 0.12, 0.15), (1688, 0.06, 0.08)]:
        y += a * np.exp(-t / tau) * np.sin(2 * np.pi * fr * t + rng.uniform(0, 6))
    y += 0.4 * filt(ruis(sec), "lowpass", 500, 2) * env_ad(sec, 0.002, 0.06)
    return y


# ---------------------------------------------------------------- de mix
def bouw():
    st = {k: Spoor() for k in ("bed", "muziek", "speler", "echo", "combat")}
    t_pomp = 6.2
    t_kleur = 7.4  # de kleurgolf (+- 2 s) begint hier
    # ---- bed: grijs (verzonken) en opgepompt
    sec = DUUR
    tt = tijd(sec)
    x_grijs = np.clip((t_kleur + 1.6 - tt) / 2.0, 0, 1)  # kruisfade over +- 2 s
    x_kleur = 1 - x_grijs
    wl, wr = water(sec), water(sec)
    w = np.stack([filt(wl, "lowpass", 1400), filt(wr, "lowpass", 1400)], axis=1)
    w_kleur = np.stack([wl, wr], axis=1)
    bed = w * (0.10 * x_grijs)[:, None] + w_kleur * (0.075 * x_kleur)[:, None]
    wi = wind(sec)
    bed += pan(wi * 0.05 * (0.6 + 0.4 * x_grijs), -0.3)
    for t0 in (0.35, 1.9, 3.7, 5.3):
        d = pan(druppel(), rng.uniform(-0.7, 0.7)) * 0.05
        bed[n(t0) : n(t0) + len(d)] += d
    # verre, verzonken klok (alleen grijs)
    ver = filt(klok(196.0, 5.0, grootte=1.6, grijs=True), "lowpass", 600) * 0.12
    bed[n(1.0) : n(1.0) + len(ver)] += pan(ver, 0.45)
    # gemaal draait vanaf het oppompen
    gm = gemaal(sec, start_t=t_pomp + 0.9)
    bed += pan(filt(gm, "lowpass", 2200), 0.25) * 0.28
    st["bed"].x += bed
    # oppompen
    st["bed"].zet(leeglopen(2.6) * 0.16, t_pomp + 0.1, 0, -0.15)
    st["combat"].zet(machine_aan() * 0.55, t_pomp, 0, 0.25)
    # ---- muziek: grijs = lege kwint (D2 + A2), opgepompt = D-groot add9 (de terts komt terug)
    drone = (harmonium(73.42, sec, 0.35) + 0.8 * harmonium(110.0, sec, 0.35)) * 0.03
    drone = filt(drone, "lowpass", 900)
    akk = np.zeros(n(sec))
    for f, a in ((146.83, 1.0), (185.0, 0.8), (220.0, 0.85), (329.63, 0.5)):
        akk += a * harmonium(f, sec, 0.8)
    akk = filt(akk, "lowpass", 3200) * 0.020
    env_akk = np.clip((tt - (t_pomp + 1.0)) / 2.4, 0, 1) ** 1.5 * np.clip((DUUR - tt) / 1.5, 0, 1)
    env_drone = 0.6 + 0.4 * x_grijs
    m_l = drone * env_drone + akk * env_akk
    m_r = drone * env_drone + np.roll(akk, n(0.007)) * env_akk
    st["muziek"].x += np.stack([m_l, m_r], axis=1)
    # bloei bij het oppompen: grote klok op D4 met terts
    st["combat"].zet(klok(293.66, 5.0, grootte=1.8, grijs=False, helder=0.8) * 0.20, t_pomp + 1.2, 0, 0.1)

    # ---- A: grijze wijk, één merk
    def slag_met_merk(t_hit, grijs, p):
        st["speler"].zet(p1_slag(), t_hit - 0.06, -5, p)
        st["combat"].zet(merk_zet(grijs), t_hit, -9, p + 0.1)

    def echo_slag(t_hit, p):
        e, voor = echo_versie(p1_slag(), -7)
        st["echo"].zet(e, t_hit - 0.06 - voor, 0, p)

    def aftelling(t_hit, grijs, p, tot_slag):
        t_af = t_hit + (LEVENSDUUR - AFTEL) * TICK
        for i in range(tot_slag):
            st["combat"].zet(aftel_slag(i, grijs), t_af + i * AFTEL_STAP * TICK, -6 + 1.5 * i, p)
        # zoemen van het merk, van zetten tot ontploffen
        z = merk_zoem((LEVENSDUUR - AFTEL + tot_slag * AFTEL_STAP) * TICK, grijs)
        st["combat"].zet(z * 0.03, t_hit + 0.05, 0, p)

    p_vijand = 0.25
    t1 = 0.60
    slag_met_merk(t1, True, p_vijand)
    st["speler"].zet(sprong(), 1.20, -8, -0.1)
    st["speler"].zet(landing(), 1.78, -8, 0.05)
    aftelling(t1, True, p_vijand, 2)
    t_echo = t1 + D_TICKS * TICK
    echo_slag(t_echo, p_vijand - 0.15)
    st["echo"].zet(merksprong(), t_echo - 0.04, -12, p_vijand - 0.1)
    st["combat"].zet(ontploffing(1, grijs=True), t_echo, -3, p_vijand)
    e, voor = echo_versie(sprong(), -8)
    st["echo"].zet(e, 1.20 + D_TICKS * TICK - voor, 0, -0.25)
    e, voor = echo_versie(landing(), -8)
    st["echo"].zet(e, 1.78 + D_TICKS * TICK - voor, 0, -0.1)

    # ---- C: opgepompte wijk, twee merken, ketting
    ta, tb = 9.00, 9.30
    pa, pb = 0.15, 0.4
    slag_met_merk(ta, False, pa)
    slag_met_merk(tb, False, pb)
    # één aftelling tegelijk: het merk dat het eerst afloopt (A) telt hoorbaar af
    aftelling(ta, False, pa, 2)
    z = merk_zoem((LEVENSDUUR - AFTEL) * TICK + 0.5, False)
    st["combat"].zet(z * 0.02, tb + 0.05, 0, pb)
    t_e = ta + D_TICKS * TICK
    echo_slag(t_e, pa - 0.15)
    st["echo"].zet(merksprong(), t_e - 0.04, -12, pa - 0.1)
    st["combat"].zet(ontploffing(1, grijs=False), t_e, -3, pa)
    # schakel 2: in de sim 1 tick later; in het geluid gerold op 45 ms (een carillonrol)
    st["combat"].zet(ketting_klok(2) * 0.6, t_e + 0.045, -2, pb)
    st["combat"].zet(ontploffing(2, grijs=False) * 0.6, t_e + TICK, -6, pb)
    # de tweede echo-slag vindt geen merk meer: gewone echo-treffer
    echo_slag(tb + D_TICKS * TICK, pb - 0.15)

    # ---- galm (send/return per toestand)
    droog = st["speler"].x + st["echo"].x + st["combat"].x + 0.6 * st["muziek"].x
    droog = filt(droog, "highpass", 180, 2)  # geen laag in de galm: houdt de mix helder
    nat_grijs = galm(droog * x_grijs[:, None], IR_VERZONKEN, 0.30)
    nat_kleur = galm(droog * x_kleur[:, None], IR_BELFORT, 0.34)
    st["galm"] = Spoor()
    st["galm"].x = nat_grijs + nat_kleur
    return st


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
    # bed tegenover gebeurtenissen: hoorbaarheid van aftelling en ontploffing
    bed = st["bed"].x + st["muziek"].x
    # wereld zonder spelers (P1 blijft altijd "in kleur", art bible §5)
    wereld = bed + st["galm"].x
    m["wereld_grijs_0-6s"] = dict(zip(("banden_%", "centroid_hz"), banden(wereld, 0.0, 6.0)))
    m["wereld_opgepompt_9-15s"] = dict(zip(("banden_%", "centroid_hz"), banden(wereld, 9.0, 15.0)))
    m["bed_lufs"] = round(lufs_geintegreerd(bed), 2)
    for naam, t0 in (("aftelslag_1_grijs", 2.10), ("ontploffing_grijs", 2.60), ("ontploffing_ketting", 11.00)):
        seg = st["combat"].x[n(t0) : n(t0 + 0.4)]
        bseg = bed[n(t0) : n(t0 + 0.4)]
        m[f"{naam}_boven_bed_LU"] = round(
            float(10 * np.log10(np.sum(blok_ms(seg, 0.4, 0.4)) / (np.sum(blok_ms(bseg, 0.4, 0.4)) + 1e-12))), 1
        )
    # P1 tegenover echo: zelfde slag, ander lijf
    p1 = p1_slag()
    e, _ = echo_versie(p1, 0)
    bp, cp = banden(p1)
    be, ce = banden(e)
    m["p1_slag"] = {"banden_%": bp, "centroid_hz": cp}
    m["echo_slag"] = {"banden_%": be, "centroid_hz": ce}
    # klokspectrum: gemeten partialen t.o.v. de slagtoon
    m["klok_D5_kleur_partialen"] = partialen(klok(587.33, 2.0, grootte=1.25), 587.33)
    m["klok_D5_grijs_partialen"] = partialen(klok(587.33, 2.0, grootte=1.25, grijs=True), 587.33)
    m["aftelling_tick_s"] = {
        "slag_1": round((LEVENSDUUR - AFTEL) * TICK, 3),
        "echo_op_slag": 1 + (D_TICKS - (LEVENSDUUR - AFTEL)) // AFTEL_STAP,
    }
    return m


def schrijf_wav(pad, x):
    x16 = np.clip(np.round(x * 32767), -32768, 32767).astype(np.int16)
    wavfile.write(pad, SR, x16)


def master(x):
    """Gain naar het LUFS-doel, dan een zachte limiter op de true peak."""
    g = DOEL_LUFS - lufs_geintegreerd(x)
    x = x * 10 ** (g / 20)
    plafond = 10 ** ((DOEL_TP - 0.3) / 20)
    # look-ahead limiter: versterkingscurve uit de omhullende, gladgestreken
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
    if shutil.which("ffmpeg"):
        subprocess.run(
            ["ffmpeg", "-y", "-loglevel", "error", "-i", pad, "-c:a", "libvorbis", "-q:a", "6", pad[:-4] + ".ogg"],
            check=True,
        )
    # losse bouwstenen (piek -3 dBFS, zonder galm)
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
    for naam, s in los.items():
        if s.ndim == 1:
            s = np.stack([s, s], axis=1)
        schrijf_wav(os.path.join(LOS, f"{naam}_placeholder.wav"), norm(s, 10 ** (-3 / 20)))
    m = meet(mix, st)
    m["master_gain_db"] = round(g, 2)
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
        fig.suptitle("F2-fragment: merk-aftelling met het carillon (grijs -> opgepompt) - placeholder")
        fig.tight_layout()
        fig.savefig(os.path.join(UIT, "f2_spectrogram_placeholder.png"), dpi=110)
    except ImportError:
        pass
    print(json.dumps(m, indent=1, ensure_ascii=False))


if __name__ == "__main__":
    sys.exit(main())
