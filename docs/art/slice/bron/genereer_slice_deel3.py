"""Slice-art deel 3, de Kadewijk: S2 Kadegang en S4 Brugkloof op eindkwaliteit, het snelluik in S1
en de schaduwklep (Art Director, #85, T8c).

Draait eerst deel 2 (S1 met het snelluik uit PR #231, S3, de eenrichtingsatlas met het snelluik en het
manifest), en voegt dan toe:
  - S2 Kadegang en S4 Brugkloof als kamerlagen (achter, midden, speelvlak, licht, voor) in grijs, half,
    kleur en index, op de geometrie van `kadewijk_layout.gd` bij D = 60;
  - in S2 de eenrichtingsstukken per D (Galerij70, B1-treden tegen de pijler) via de bestaande atlas,
    en de **vaste stukken per D**: de rand van de B3-wand (schuift mee met `b3_width(D)`) en het B3-blok;
  - `kadewijk_objecten_*.png`: de **schaduwklep** (V-01d, PR #232) in 3 frames (vol, oplossen 1, 2);
  - renders, lichtovergang, geometriecontrole en metingen in docs/art/slice/eindkwaliteit/.

Eigen werk (docs/licenties.md §2). Draaien vanaf de repo-root:
    python3 docs/art/slice/bron/genereer_slice_deel3.py
"""
import json
import os
import sys

import numpy as np
from PIL import Image

HIER = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HIER)
import genereer_slice_deel2 as D2  # noqa: E402

D1, R, SP = D2.D1, D2.R, D2.SP
T, MI, K = D2.T, D2.MI, D2.K
Kamer, ROOM_H, STATEN = D2.Kamer, D2.ROOM_H, D2.STATEN
UIT_GAME, UIT_DOCS = D2.UIT_GAME, D2.UIT_DOCS
tegel, rng = D2.tegel, D2.rng
D = D2.D

# ------------------------------------------------------------------ maten (kadewijk_layout.gd)
S2_X = 640
S2_FLOOR, S2_MID, S2_TOP = 230, 160, 70
S2_PIJLER = 700
B3_GALLERY_TIP, B3_BLOCK_LEFT, S2_TOP_SOLID = 1100, 1250, 1180
ONE_WAY_T, TREAD_T, TREAD_W = 6, 4, 40
B3_MAX = 120                       # b3_width(180): verder schuift de wand in de regressie niet
WAND_STUK_W = B3_MAX + 16          # breedte van het wand-stuk (de rand + één tegel muur)

S4_X = 2560
S4_FLOOR, B4_NEAR, B4_FAR, KLOOF_BOTTOM = 260, 2900, 3060, 350
BOLDER = (2892, 252, 8, 8)


def b3_width(d):
    return max(d - 60, 0)


def s2_eenrichting(d):
    z = D2.keerzone(d)
    out = [("Galerij70", "galerij", S2_PIJLER + z, S2_TOP, S2_TOP_SOLID - S2_PIJLER - z)]
    for h in (30, 60, 90):
        w = D2.tread_90_width(d) if h == 90 else TREAD_W
        out.append((f"B1Trede{h}", "trede", S2_PIJLER, S2_MID - h, w))
    return out


def blokken_s2(d=D):
    """Lokaal (x - 640), zoals Layout.blocks(&"S2", d), voor de controles."""
    b = b3_width(d)
    o = S2_X
    out = [(0, S2_FLOOR, B3_BLOCK_LEFT + b - o, ROOM_H - S2_FLOOR, False),
           (S2_PIJLER - 20 - o, S2_TOP + ONE_WAY_T, 20, S2_MID - S2_TOP, False),
           (S2_PIJLER - o, S2_MID, B3_GALLERY_TIP - S2_PIJLER, ONE_WAY_T, True),
           (B3_GALLERY_TIP - o, S2_FLOOR - 35, TREAD_W, TREAD_T, True),
           (B3_BLOCK_LEFT + b - o, S2_TOP + ONE_WAY_T, 1600 - B3_BLOCK_LEFT - b, ROOM_H - S2_TOP - ONE_WAY_T, False),
           (S2_TOP_SOLID - o, S2_TOP, 1600 - S2_TOP_SOLID, ONE_WAY_T, False)]
    if b > 0:
        out.append((B3_BLOCK_LEFT - o, S2_FLOOR - 45, b, 45, False))
    for (_, _, x, y, w) in s2_eenrichting(d):
        out.append((x - o, y, w, ONE_WAY_T, True))
    return out


def blokken_s4():
    o = S4_X
    return [(0, S4_FLOOR, B4_NEAR - o, ROOM_H - S4_FLOOR, False),
            (BOLDER[0] - o, BOLDER[1], BOLDER[2], BOLDER[3], False),
            (B4_NEAR - o, KLOOF_BOTTOM, B4_FAR - B4_NEAR, ROOM_H - KLOOF_BOTTOM, False),
            (B4_FAR - TREAD_W - o, KLOOF_BOTTOM - 45, TREAD_W, 45, False),
            (B4_FAR - o, S4_FLOOR, 3520 - B4_FAR, ROOM_H - S4_FLOOR, False)]


# ------------------------------------------------------------------ stukken
def b3_wand_stuk():
    """De linkerrand van de pakhuismuur in S2 (B3-keerwand), WAND_STUK_W x 284 (y 76..360).
    Schuift mee met D: x = 1250 + b3_width(D). Rij 0 = de onderkant van de bovenroute (76)."""
    w, h = WAND_STUK_W, ROOM_H - (S2_TOP + ONE_WAY_T)
    t = T(w, h)
    yy, xx = np.mgrid[0:h, 0:w]
    # dezelfde tegels en speklagen als de muur in `speelvlak` (rij 3, 9, 15 vanaf 76), zodat de naad wegvalt
    for j in range(0, (h + 15) // 16):
        for i in range(0, (w + 15) // 16):
            nm = "baksteen_speklaag" if j in (3, 9, 15) else ("baksteen_m1" if (i + j) % 2 else "baksteen_m2")
            tl = tegel(nm)
            hh, ww = min(16, h - j * 16), min(16, w - i * 16)
            t.mat[j * 16:j * 16 + hh, i * 16:i * 16 + ww] = tl.mat[:hh, :ww]
            t.t[j * 16:j * 16 + hh, i * 16:i * 16 + ww] = tl.t[:hh, :ww]
    # hardstenen hoekblokken (afwisselend lang en kort) op de rand
    for k_, y0 in enumerate(range(0, h, 20)):
        bw = 14 if k_ % 2 == 0 else 9
        t.box(0, y0, bw, min(h, y0 + 10), "steen", 4)
        t.box(0, y0, bw, y0 + 1, "steen", 6)
        t.box(0, y0 + 9, bw, min(h, y0 + 10), "steen", 2)
    t.box(0, 0, 1, h, "steen", 2)                       # schaduwlijn op de kopse kant
    t.box(1, 0, 2, h, "steen", 5)
    t.add((yy > 154), -1)                               # onder de kade (230) donkerder, zoals de muur
    return t


def b3_blok_stuk():
    """Het B3-blok (D > 60), 120 x 45: een hardstenen aanlegblok; de TA knipt het op b3_width(D)."""
    t = T(B3_MAX, 45)
    D1.blokken(t, 0, 45 - 45 % 8, 16, 8, "steen", 3, 62)
    t.fill(np.mgrid[0:45, 0:B3_MAX][0] >= 40, "steen", 2)
    t.box(0, 0, B3_MAX, 5, "steen", 4)
    t.box(0, 0, B3_MAX, 1, "steen", 6)
    t.box(0, 4, B3_MAX, 5, "steen", 2)
    return t


def bolder8():
    """De bolder van B4: precies 8 x 8 (collision), gietijzer met een kraag, licht op de kop."""
    t = T(8, 8)
    t.box(1, 2, 7, 8, "ijzer", 3)
    t.box(0, 6, 8, 8, "ijzer", 2)
    t.box(0, 0, 8, 3, "ijzer", 4)
    t.box(0, 0, 8, 1, "steen", 6)              # versleten kop: licht, zodat de keerwand leest
    t.box(1, 1, 7, 2, "ijzer", 6)
    t.box(1, 2, 2, 8, "ijzer", 2)
    t.box(5, 3, 6, 6, "ijzer", 5)
    return t


def schaduwklep(fase):
    """De schaduwklep (V-01d): de schaduw van het luik waarop de echo blijft staan, 40 x 16.
    Schaduwgeometrie (bible §4.4): een holle afdruk van de klep (rand + arcering), paars, in grijs grijs.
    fase 0 = vol, 1 en 2 = oplossen (Bayer 50 % en 25 %)."""
    t = T(40, 16)
    yy, xx = np.mgrid[0:16, 0:40]
    r = rng(232)
    rand_b = 1 + (r.random(40) < 0.3).astype(int)
    lijf = (yy >= rand_b[xx]) & (yy < 12 + (r.random(40) < 0.4).astype(int)[xx])
    # deel 4, punt van de CD (#227): **hol**, zoals de echo (vol = levend, hol = echo): alleen een rand
    # en een diagonale arcering om de 3 px, geen vulling; de naden van de planken als onderbroken lijnen.
    rand = lijf & ~D2.ndimage.binary_erosion(lijf)
    t.fill(lijf & ((xx + yy) % 3 == 0), "schaduwgeo", 4)                 # arcering, aan het stuk verankerd
    t.fill(lijf & (xx % 8 == 7) & (yy > 2) & (yy % 2 == 0), "schaduwgeo", 3)   # naden van de planken
    t.fill(rand, "schaduwgeo", 5)
    t.fill(lijf & (yy == rand_b[xx]), "schaduwgeo", 7)                    # bovenrand: hier staat de echo
    rank = (yy >= 11) & (yy < 16) & (np.abs(xx - (6 + 9 * ((xx // 9)))) < 1) & ((yy - 11) < 2 + (xx % 3))
    t.fill(rank, "schaduwgeo", 4)                                         # ranken eronder
    if fase:
        bay = R.bayer(16, 40)
        weg = bay >= (0.5 if fase == 1 else 0.25)
        t.mat[weg & ~(yy == rand_b[xx])] = -1
        if fase == 2:
            t.mat[(yy == rand_b[xx]) & (xx % 2 == 1)] = -1
    return t


# ------------------------------------------------------------------ S2 Kadegang
def bouw_s2():
    k = Kamer("s2_kadegang", S2_X, 960)
    YY, XX = k.YY, k.XX
    o = S2_X
    pij = S2_PIJLER - o            # 60
    tip = B3_GALLERY_TIP - o       # 460
    b3 = B3_BLOCK_LEFT - o         # 610
    bov = S2_TOP_SOLID - o         # 540
    D2.lucht_en_ver(k, 202, belfort=(300, 20), top_range=(112, 150))
    # overkant van de gracht: een gevelrij op 230, half achter de pakhuismuur
    huis = D2.huizenrij(k, 120, 620, S2_FLOOR, 23, 96, 130, lit_p=0.7)
    k.add(huis, "huizen", -1)          # aan de overkant van de gracht: verder weg, een tint donkerder
    # --- de brug: een stenen boog die uit de linkerkant komt en op de pijler (40..60) rust
    boog_o = np.hypot((XX - (-60)) / 120.0, (YY - 82) / 82.0)
    boog = (boog_o >= 1.0) & (boog_o < 1.22) & (YY < 82) & (XX < pij)
    k.paint(boog, "midden", "steen", 3)
    k.paint(boog & (np.abs(np.sin(np.arctan2(YY - 82, XX + 60) * 14)) < 0.16), "midden", "steen", 1)
    k.paint(boog & (boog_o < 1.03), "midden", "steen", 5)
    dek = k.rect(0, 0, pij, 20) & ~boog & (boog_o >= 1.0)
    k.paint(dek, "midden", "baksteen", 2)
    k.paint(k.rect(0, 0, pij, 6), "midden", "steen", 4)
    # --- de pijler (speelvlak, 40..60, 76..166): hardstenen kop met ijzeren banden
    pm = k.rect(pij - 20, S2_TOP + ONE_WAY_T, pij, S2_MID + ONE_WAY_T)
    k.tegels(lambda i, j, x, y: "kade_wand_hoog_m1" if j % 2 else "kade_wand_hoog_m2", pij - 20, 76, pij, 172, "speelvlak")
    k.paint(pm & ~k.rect(0, 0, pij, S2_MID + ONE_WAY_T), "speelvlak", "steen", 3)
    k.paint(pm & (XX == pij - 1), "speelvlak", "steen", 5)
    k.paint(pm & (XX == pij - 20), "speelvlak", "steen", 1)
    k.paint(k.rect(pij - 20, 76, pij, 78), "speelvlak", "steen", 6)          # dekplaat van de pijlerkop
    k.paint(pm & ((YY == 100) | (YY == 140)), "speelvlak", "roest", 3)
    k.paint(pm & (YY >= S2_MID + 2), "speelvlak", "steen", 2)
    k.paint(pm & (YY == S2_MID + ONE_WAY_T - 1), "speelvlak", "steen", 1)
    # --- Gang160 (eenrichting, vast): een houten gang op consoles langs de pijler naar de kom
    gang = D2.ninepatch(D2.galerij_stuk(), tip - pij)
    k.stamp(gang, pij, S2_MID, "speelvlak", dt=1)
    k.paint(k.rect(pij, S2_MID, tip, S2_MID + 1), "speelvlak", "steen", 7)     # versleten kant van de gang: licht
    k.add(k.rect(pij, S2_MID - 8, tip, S2_MID) & (k.BAY < (YY - (S2_MID - 8)) / 8), "huizen", -1)   # slagschaduw van de leuning
    # touwleuning boven de gang (midden), hangt aan palen die achter staan
    for px in range(pij + 40, tip, 80):
        k.paint(k.rect(px, S2_MID - 22, px + 2, S2_MID), "midden", "hout", 3)
    k.paint((np.abs(YY - (S2_MID - 18 + 3 * np.sin((XX - pij - 40) / 80 * np.pi) ** 2)) < 0.6) & (XX > pij + 40) & (XX < tip - 40), "midden", "hout", 4)
    # --- B3-trede (eenrichting, vast, 4 dik): een stenen console aan de pakhuiskant van de kom
    k.stamp(D2.ninepatch(D2.trede_stuk(), TREAD_W), tip, S2_FLOOR - 35, "speelvlak")
    # --- kade op 230 (speelvlak): 0 .. b3 + B3_MAX (onder 230 is het altijd vast)
    k.tegels(lambda i, j, x, y: ("kade_boven_m1" if i % 2 else "kade_boven_m2") if j == 0 else
             ("kade_meerring" if (i, j) == (9, 3) else ("rooster" if (i, j) in ((4, 5), (21, 5)) else
              ("kade_wand_hoog_m1" if j < 4 else "kade_wand_laag_m2"))), 0, S2_FLOOR, b3 + B3_MAX, ROOM_H, "speelvlak")
    k.tegels(lambda i, j, x, y: "kade_getij_m1" if i % 2 else "kade_getij_m2", 0, 300, b3 + B3_MAX, 316, "speelvlak")
    kade = k.rect(0, S2_FLOOR, b3 + B3_MAX, ROOM_H)
    for dx in (150, 420):              # duikers onder de kade, met het water van de gracht (beeld)
        bg_ = D2.R_arch(k, dx - 24, dx + 24, 296, ROOM_H)
        k.paint(np.logical_and(D2.ndimage.binary_dilation(bg_, iterations=3) & ~bg_, kade & (YY > 290)), "speelvlak", "steen", 4)
        k.paint(D2.ndimage.binary_dilation(bg_) & ~bg_ & kade & (YY > 290), "speelvlak", "steen", 1)
        k.paint(bg_, "speelvlak", "raamdonker", 0)
        w_ = bg_ & (YY >= 340)
        k.paint(w_, "speelvlak", "water", 2)
        k.paint(w_ & (YY == 340), "speelvlak", "water", 4)
        k.paint(w_ & (YY == 340) & ((XX // 3) % 3 == 0), "speelvlak", "water", 6)
    # --- bovenroute op 70 (speelvlak, 540..960): hardstenen lijst op kraagstenen
    k.tegels(lambda i, j, x, y: "kade_boven_m1" if i % 2 else "kade_boven_m2", bov, S2_TOP, 960, S2_TOP + 6, "speelvlak")
    for cx in range(bov + 8, b3, 24):                 # kraagstenen onder de lijst, boven de kom (midden)
        cs = k.rect(cx, 76, cx + 8, 82) | k.rect(cx + 2, 82, cx + 6, 86)
        k.paint(cs, "midden", "steen", 3)
        k.paint(cs & (YY == 76), "midden", "steen", 1)
    # --- pakhuismuur (speelvlak) vanaf b3 + WAND_STUK_W; de rand zelf is het stuk `b3_wand` (per D)
    wx0 = b3 + WAND_STUK_W
    k.tegels(lambda i, j, x, y: "baksteen_speklaag" if (y - 76) % 96 == 48 else ("baksteen_m1" if (i + j) % 2 else "baksteen_m2"),
             wx0, 76, 960, ROOM_H, "speelvlak")
    pm = k.rect(wx0, 76, 960, ROOM_H)
    k.add(pm & (YY > 230), "speelvlak", -1)
    # hijsdeuren en ramen in het pakhuis (speelvlak-muur: alleen beeld, de muur is vast)
    for (dx, dy) in [(890, 96), (890, 152)]:   # rechts van 866: bij elke D vrij van het wand-stuk
        k.paint(k.rect(dx - 2, dy - 2, dx + 22, dy + 32), "speelvlak", "steen", 5)
        k.paint(k.rect(dx, dy, dx + 20, dy + 30), "speelvlak", "hout", 2)
        k.paint(k.rect(dx, dy, dx + 20, dy + 30) & ((XX - dx) % 5 == 4), "speelvlak", "hout", 1)
        k.paint(k.rect(dx, dy + 6, dx + 20, dy + 8) | k.rect(dx, dy + 22, dx + 20, dy + 24), "speelvlak", "roest", 3)
        k.paint(k.rect(dx + 9, dy, dx + 11, dy + 30), "speelvlak", "hout", 1)
    k.ramen.append(dict(x=936, y=110, w=10, h=14, laag="speelvlak", jit=0.3, kruis=True, aan=dict(grijs=False, half=True, kleur=True)))
    k.ramen.append(dict(x=936, y=180, w=10, h=14, laag="speelvlak", jit=0.6, kruis=True, aan=dict(grijs=False, half=False, kleur=True)))
    k.paint(k.rect(898, 78, 902, 92) | k.rect(888, 80, 922, 84), "speelvlak", "hout", 3)       # hijsbalk
    # --- decor op de kade (midden): manden bij de kom, een bolder, lampen
    k.stamp(D2.ton(5), 520, S2_FLOOR - 16, "midden")
    k.stamp(D2.ton(6), 506, S2_FLOOR - 14, "midden", dt=-1)
    k.stamp(D2.bolder_klein(), 300, S2_FLOOR - 16, "midden")
    wu, wa = D2.wandlamp()
    k.wissel.append(("speelvlak", 870, 150, wu, wa, dict(grijs=False, half=True, kleur=True)))
    k.lampen.append(dict(x=878, y=164, r=1.0, aan=dict(grijs=False, half=True, kleur=True)))
    su, sa = D2.straatlamp()
    k.wissel.append(("midden", 200, S2_FLOOR - 48, su, sa, dict(grijs=False, half=True, kleur=True)))
    k.lampen.append(dict(x=208, y=190, r=1.0, aan=dict(grijs=False, half=True, kleur=True)))
    # schaduw onder de gang op 160 en onder de brug
    k.add(k.rect(pij, S2_MID + 6, tip, S2_MID + 30) & (k.BAY < (S2_MID + 30 - YY) / 24), "huizen", -1)
    return k


# ------------------------------------------------------------------ S4 Brugkloof
def bouw_s4():
    k = Kamer("s4_brugkloof", S4_X, 960)
    YY, XX = k.YY, k.XX
    o = S4_X
    nr, fr = B4_NEAR - o, B4_FAR - o          # 340, 500
    D2.lucht_en_ver(k, 404, belfort=(700, 30), top_range=(118, 160))
    D2.huizenrij(k, 0, 300, S4_FLOOR, 41, 100, 140, lit_p=0.65)
    D2.huizenrij(k, 560, 960, S4_FLOOR, 43, 96, 136, lit_p=0.65)
    # --- de gebroken brug (midden): een boog over de kloof, het midden is ingestort
    cx_, dek_y = (nr + fr) / 2, 96
    e_in = ((XX - cx_) / 80.0) ** 2 + ((YY - S4_FLOOR) / 128.0) ** 2
    e_uit = ((XX - cx_) / 96.0) ** 2 + ((YY - S4_FLOOR) / 144.0) ** 2
    breuk = np.abs(XX - cx_) < 26 + 7 * np.sin(YY / 4.3) + (YY - dek_y) * 0.08
    ring = (e_in >= 1) & (e_uit < 1) & (YY < S4_FLOOR) & ~breuk
    zwik = (e_uit >= 1) & (YY >= dek_y + 12) & (YY < S4_FLOOR) & (np.abs(XX - cx_) < 112) & ~breuk
    dek = (YY >= dek_y) & (YY < dek_y + 12) & (np.abs(XX - cx_) < 118) & ~breuk
    k.paint(zwik, "midden", "baksteen", 1)
    k.add(zwik & ((YY % 4) == 0), "midden", -1)
    k.paint(ring, "midden", "steen", 2)
    k.paint(ring & (np.abs(np.sin(np.arctan2(YY - S4_FLOOR, XX - cx_) * 18)) < 0.16), "midden", "steen", 0)
    k.paint(ring & (e_in < 1.04), "midden", "steen", 4)
    k.paint(dek, "midden", "steen", 2)
    k.paint(dek & (YY == dek_y), "midden", "steen", 4)
    for px in range(int(cx_ - 116), int(cx_ + 118), 10):      # leuning op het dek, gebroken bij het gat
        k.paint(k.rect(px, dek_y - 10, px + 2, dek_y) & ~breuk, "midden", "ijzer", 2)
    k.paint(k.rect(cx_ - 118, dek_y - 11, cx_ + 118, dek_y - 9) & ~breuk, "midden", "ijzer", 3)
    # ketting en een losse balk aan de breukranden
    for kant in (-1, 1):
        hx_ = int(cx_ + kant * 30)
        k.paint(k.rect(hx_, dek_y + 12, hx_ + 1, dek_y + 56) & ((YY % 3) != 0), "midden", "ijzer", 3)
    k.paint((np.abs(YY - (dek_y + 14 + 0.9 * (XX - cx_ - 26))) < 1.0) & (XX > cx_ + 26) & (XX < cx_ + 50), "midden", "hout", 2)
    # --- aanloop en overkant op 260 (speelvlak)
    kas = [D2.kasseien(s) for s in (4, 5, 6)]
    for (x0, x1) in [(0, nr), (fr, 960)]:
        k.tegels(lambda i, j, x, y: kas[i % 3] if j == 0 else ("kade_wand_hoog_m1" if j < 3 else
                 ("kelderbodem_m1" if (i + j) % 2 else "kelderbodem_m2")), x0, S4_FLOOR, x1, ROOM_H, "speelvlak")
    k.add(k.rect(0, 292, 960, ROOM_H), "speelvlak", -1)
    # kloofwanden: de oude kademuur, afgebroken (kopse kanten op 340 en 500)
    for (x0, x1, kant) in [(nr - 3, nr, -1), (fr, fr + 3, 1)]:
        m = k.rect(x0, S4_FLOOR, x1, ROOM_H)
        k.paint(m, "speelvlak", "steen", 2)
        k.paint(m & (XX == (nr - 1 if kant < 0 else fr)), "speelvlak", "steen", 4)
    k.tegels(lambda i, j, x, y: "kade_getij_m1" if i % 2 else "kade_getij_m2", 0, 296, nr - 3, 312, "speelvlak")
    k.tegels(lambda i, j, x, y: "kade_getij_m1" if i % 2 else "kade_getij_m2", fr + 3, 296, 960, 312, "speelvlak")
    # --- de bolder: precies op de rand (8 x 8)
    k.stamp(bolder8(), BOLDER[0] - o, BOLDER[1], "speelvlak")
    # --- kloofbodem (350) en de trede van 45 tegen de overkant (speelvlak)
    k.tegels(lambda i, j, x, y: "kelderbodem_m1" if (i + j) % 2 else "kelderbodem_m2", nr, KLOOF_BOTTOM, fr, ROOM_H, "speelvlak")
    k.paint(k.rect(nr, KLOOF_BOTTOM, fr, KLOOF_BOTTOM + 3), "speelvlak", "klimop", 2)        # slik op de bodem
    k.paint(k.rect(nr, KLOOF_BOTTOM, fr, KLOOF_BOTTOM + 2), "speelvlak", "steen", 5)
    k.paint(k.rect(nr, KLOOF_BOTTOM, fr, KLOOF_BOTTOM + 1), "speelvlak", "steen", 6)
    tr = k.rect(fr - TREAD_W, KLOOF_BOTTOM - 45, fr, KLOOF_BOTTOM)
    k.tegels(lambda i, j, x, y: "trap_vul" if j else "kade_boven_m1", fr - TREAD_W, KLOOF_BOTTOM - 45, fr, KLOOF_BOTTOM, "speelvlak")
    k.paint(tr & (XX == fr - TREAD_W), "speelvlak", "steen", 2)
    # --- in de kloof (midden): de achterwand van de oude sluis, puin en een plas (beeld)
    kl = k.rect(nr, S4_FLOOR, fr, KLOOF_BOTTOM)
    k.tegels(lambda i, j, x, y: "kade_wand_laag_m1" if (i + j) % 2 else "kade_wand_laag_m2", nr, S4_FLOOR, fr, KLOOF_BOTTOM, "midden", dt=-1)
    k.add(kl & (YY > 320), "midden", -1)
    k.paint(kl & (YY >= 336) & (np.abs(XX - 400) < 34) & (YY >= 344), "midden", "water", 2)
    k.paint(kl & (YY == 344) & (np.abs(XX - 400) < 34), "midden", "water", 5)
    for (px, ph) in [(366, 10), (378, 6), (440, 8)]:
        k.paint(k.rect(px, KLOOF_BOTTOM - ph, px + 9, KLOOF_BOTTOM), "midden", "steen", 3)
        k.paint(k.rect(px, KLOOF_BOTTOM - ph, px + 9, KLOOF_BOTTOM - ph + 1), "midden", "steen", 5)
    for sx in (nr + 18, fr - TREAD_W - 30):                # resten van de sluisdeur
        k.tegels(lambda i, j, x, y: ["sluisdeur_boven", "sluisdeur_mid", "sluisdeur_onder"][min(j, 2)], sx, 300, sx + 16, KLOOF_BOTTOM, "midden", dt=-1)
    # --- lampen en decor op de kades (midden)
    su, sa = D2.straatlamp()
    for lx in (180, 760):
        k.wissel.append(("midden", lx - 8, S4_FLOOR - 48, su, sa, dict(grijs=False, half=True, kleur=True)))
        k.lampen.append(dict(x=lx, y=220, r=1.0, aan=dict(grijs=False, half=True, kleur=True)))
    k.stamp(D2.ton(9), 250, S4_FLOOR - 16, "midden")
    k.stamp(tegel("paal"), fr + 30, S4_FLOOR - 16, "midden")
    k.stamp(tegel("paal"), fr + 30, S4_FLOOR - 32, "midden")
    # koude bundels door de kloof (kleurscript S4): breder en lager dan in de andere kamers
    k.lucht_bundels = (((XX * 0.45 + YY) % 70) < 9) & (k.BAY < 0.32) & (YY < 240)
    return k


# ------------------------------------------------------------------ figuren (alleen renders)
def figuren_s2(staat):
    kleur = staat == "kleur"

    def f(img):
        # B3: P1 bounct op de echo in de kom en dasht naar de gang op 160
        return D2.plak_fig(img, [("echo", SP.P1_RUN[1], 560, 230, True, kleur),
                                 ("p1", SP.P1_JUMP, 520, 176, True, True)], 0)
    return f


def figuren_s4(staat):
    kleur, donker = staat == "kleur", staat != "kleur"

    def f(img):
        img = D2.plak_fig(img, [("echo", SP.P1_RUN[3], 2846 - S4_X, 260, True, kleur),
                                ("p1", SP.P1_JUMP, 2992 - S4_X, 120, False, True)], 0)
        body, kern, ogen, extra = D1.kadeloper("idle")
        lay = D1.vijand_render(body, kern, ogen, extra, staat="kleur", donker=donker)[:, ::-1]
        D1.stamp_rgba(img, lay, 3260 - S4_X - lay.shape[1] // 2, 260 - lay.shape[0])
        return img
    return f


# ------------------------------------------------------------------ export
def stuk_export(naam, t, manifest_entry):
    for staat in STATEN:
        D2.save(t.render(staat), os.path.join(UIT_GAME, f"{naam}_{staat}.png"))
    h, w = t.mat.shape
    D1.index_atlas([(0, 0, t)], w, h).save(os.path.join(UIT_GAME, f"{naam}_index.png"))
    manifest_entry["bestanden"] = {s: f"{naam}_{s}.png" for s in STATEN + ["index"]}
    return manifest_entry


def objecten_export(manifest):
    frames = [schaduwklep(f) for f in range(3)]
    for staat in STATEN:
        img = np.zeros((16, 120, 4))
        for i, fr in enumerate(frames):
            img[:, i * 40:(i + 1) * 40] = fr.render(staat)
        D2.save(img, os.path.join(UIT_GAME, f"kadewijk_objecten_{staat}.png"))
    D1.index_atlas([(i * 40, 0, fr) for i, fr in enumerate(frames)], 120, 16).save(
        os.path.join(UIT_GAME, "kadewijk_objecten_index.png"))
    manifest["objecten"] = dict(
        atlas={s: f"kadewijk_objecten_{s}.png" for s in STATEN + ["index"]},
        schaduwklep=dict(frames=[[i * 40, 0, 40, 16] for i in range(3)], fps=12,
                         plaatsing="Sprite2D op de rechthoek van het luik (Luik, 40 x 16), linksboven; zichtbaar zolang de "
                                   "schaduwklep bestaat (laag 5); bij `schaduwklep_weg` de frames 1 en 2 afspelen, dan weg",
                         z_index=-9),
    )


def main():
    manifest, _ = D2.main()
    print("Slice-art deel 3: S2 en S4 (D = 60), vaste stukken per D, schaduwklep")
    s2, s4 = bouw_s2(), bouw_s4()
    D2.export_kamer(s2, manifest)
    D2.export_kamer(s4, manifest)
    ee = manifest["eenrichting"]["blokken"]
    ee.update({"S2/Galerij70": "galerij", "S2/B1Trede30": "trede", "S2/B1Trede60": "trede", "S2/B1Trede90": "trede"})
    manifest["vaste_stukken"] = {
        "S2/B3Wand": stuk_export("s2_kadegang_b3_wand", b3_wand_stuk(), dict(
            plaatsing="Sprite2D, linksboven op (B3_BLOCK_LEFT + b3_width(D), S2_TOP + ONE_WAY_T) = (1250 + b, 76); z -10",
            reden="de kopse kant van de pakhuismuur is de B3-keerwand en schuift mee met D")),
        "S2/B3Blok": stuk_export("s2_kadegang_b3_blok", b3_blok_stuk(), dict(
            plaatsing="Sprite2D met region_enabled, region = (0, 0, b3_width(D), 45), linksboven op (1250, 185); alleen bij D > 60; z -10",
            reden="het B3-blok bestaat pas bij D > 60")),
    }
    objecten_export(manifest)
    manifest["versie"] = "0.3"
    with open(os.path.join(UIT_GAME, "kadewijk_kamers.json"), "w") as f:
        json.dump(manifest, f, indent=1, ensure_ascii=False)

    wand, blok = b3_wand_stuk(), b3_blok_stuk()

    def met_stukken(k, staat=None, golf=None, d=D):
        """Render met de eenrichtingsstukken en (S2) de vaste stukken per D, zoals de TA ze plaatst."""
        L = D2.LI["speelvlak"]
        bm, bt = k.mat[L].copy(), k.t[L].copy()
        try:
            if k.naam == "s2_kadegang":
                b = b3_width(d)
                k.stamp(wand, B3_BLOCK_LEFT + b - S2_X, S2_TOP + ONE_WAY_T, "speelvlak")
                if b > 0:
                    sub = T(b, 45)
                    sub.mat[:], sub.t[:] = blok.mat[:, :b], blok.t[:, :b]
                    k.stamp(sub, B3_BLOCK_LEFT - S2_X, S2_FLOOR - 45, "speelvlak")
                for (_, soort, x, y, w) in s2_eenrichting(d):
                    k.stamp(D2.ninepatch(D2.EENRICHTING[soort], int(w)), x - S2_X, y, "speelvlak")
            return k.render(staat or "grijs", golf)
        finally:
            k.mat[L], k.t[L] = bm, bt

    metingen = {}
    for k, figs, blokfn in [(s2, figuren_s2, blokken_s2), (s4, figuren_s4, lambda d=D: blokken_s4())]:
        r_ = {}
        for staat in ["grijs", "kleur"]:
            lagen = met_stukken(k, staat)
            zonder = k.samengesteld(lagen)
            met = k.samengesteld(lagen, figs(staat))
            r_[staat] = (zonder, met)
            D2.save(met, os.path.join(UIT_DOCS, f"{k.naam}_{staat}_{k.w}x{k.h}.png"))
            vlakken = [(x, y, w) for (x, y, w, h, e) in blokfn() if y > 0 and w >= 8]
            metingen[(k.naam, staat)] = dict(chroma=D2.chroma(zonder), loopvlak=D2.loopvlak_contrast(zonder, vlakken))
        vb = np.concatenate([D2.label_bar(k.w, "GRIJS", "S = 0, VOOR HET OPPOMPEN"), r_["grijs"][1],
                             D2.label_bar(k.w, "KLEUR", "S = 2, NA TRAP 2 (ZELFDE PLEK)"), r_["kleur"][1]], 0)
        D2.save(vb, os.path.join(UIT_DOCS, f"{k.naam}_vergelijking_x2.png"), 2)
        D2.save(D2.geometrie_controle(r_["grijs"][0], k, blokfn()), os.path.join(UIT_DOCS, f"{k.naam}_geometrie_controle_x2.png"))
        if k is s2:
            for d in (120, 180):
                img = s2.samengesteld(met_stukken(s2, "grijs", d=d))
                D2.save(D2.geometrie_controle(img, s2, blokken_s2(d)), os.path.join(UIT_DOCS, f"s2_kadegang_geometrie_controle_d{d}_x2.png"))
        # lichtovergang
        v, lag = 300.0, 0.4
        gx = D2.GEMAAL_WERELD[0] - k.wx
        t0 = float(np.hypot(gx - k.w, 0)) / v - 0.1
        t1 = float(np.hypot(gx, D2.GEMAAL_WERELD[1])) / v + lag + 0.15
        strip = []
        for tt in np.linspace(t0, t1, 5):
            img = k.samengesteld(met_stukken(k, golf=(v * tt, v * (tt - lag))))[:, 160:800]
            strip += [D2.label_bar(640, f"T = {tt - t0:.1f} S", "HALF-VOORKANT %d PX VAN HET GEMAAL" % int(v * tt)), img]
        D2.save(np.concatenate(strip, 0), os.path.join(UIT_DOCS, f"{k.naam}_lichtovergang_strip.png"))

    # S1: het snelluik in beeld (×4 uitsnede) en de schaduwklep op een luik (×4)
    s1 = D2.bouw_s1()
    stukken = []
    for staat in ["grijs", "kleur"]:
        img = s1.samengesteld(D2.render_met_eenrichting(s1, staat))[250:360, 380:560]
        stukken += [D2.label_bar(180, f"SNELLUIK {staat.upper()}"), img]
    D2.save(np.concatenate(stukken, 0), os.path.join(UIT_DOCS, "s1_kade_ingang_snelluik_x4.png"), 4)
    kl = []
    for staat in STATEN:
        a = np.zeros((40, 3 * 48, 3)) + D1.BG
        for i in range(3):
            fr = schaduwklep(i).render(staat)
            sub = a[12:28, i * 48 + 4:i * 48 + 44]
            a[12:28, i * 48 + 4:i * 48 + 44] = D2.over(sub, fr)
        kl += [D2.label_bar(144, f"SCHADUWKLEP {staat.upper()}", "VOL, OPLOSSEN 1, 2"), a]
    D2.save(np.concatenate(kl, 0), os.path.join(UIT_DOCS, "kadewijk_schaduwklep_x4.png"), 4)

    print("  metingen deel 3 (chroma; ΔL* loopvlakken):")
    for (naam, staat), m in metingen.items():
        print(f"    {naam:14s} {staat:6s} chroma {m['chroma']:5.1f}   loopvlak ΔL* " + " ".join(f"{x:4.1f}" for x in m["loopvlak"]))


if __name__ == "__main__":
    main()
