"""Slice-art deel 5, de Kadewijk: S8 Machinehal en S9 Lage kade op eindkwaliteit (Art Director, #85, T8c).

Draait eerst deel 4 (dat deel 2 en 3 draait) en voegt toe:
  - S8 Machinehal (de arena van de Gemaalmeester, één scherm, vaste camera): de hal met tegenlicht achter
    de ketel (deel 1 §4.4), de balk waaraan het rad hangt, machines, spuigaten; de deuren als vaste stukken;
  - S9 Lage kade (4160 px): de verlichte wijk boven je, de oude kademuur met de getijdenrand en het
    gezakte water ervoor, de kelder onder S1 met de schacht, de brugpijler, het hoogwater als vast stuk;
  - de eenrichtingsstukken van S9 per D in het manifest; `fps_vol` voor het rad (deel 4, besluit AD #244);
  - renders, camera-uitsneden (rustpunt, tussen Dwaallicht en E-paar), leesbaarheid van de echo bij de ketel.

Eigen werk (docs/licenties.md §2). Draaien vanaf de repo-root:
    python3 docs/art/slice/bron/genereer_slice_deel5.py          (alles)
    python3 docs/art/slice/bron/genereer_slice_deel5.py --snel   (alleen S8 en S9; deel 1–4 staan er al)
"""
import json
import os
import sys

import numpy as np
from scipy import ndimage

HIER = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HIER)
import genereer_slice_deel4 as D4  # noqa: E402

D3, D2 = D4.D3, D4.D2
D1, R, SP = D2.D1, D2.R, D2.SP
T, MI, K, G = D2.T, D2.MI, D2.K, D2.G
Kamer, STATEN = D2.Kamer, D2.STATEN
UIT_GAME, UIT_DOCS = D2.UIT_GAME, D2.UIT_DOCS
tegel, rng = D2.tegel, D2.rng
room, blokken, blok = D4.room, D4.blokken, D4.blok
D = D2.D

S9_STUKKEN = {"Galerij": "galerij", "B1Trede30": "trede", "B1Trede60": "trede", "B1Trede90": "trede",
              "PijlerRichel1": "galerij", "PijlerRichel2": "galerij",
              "B2aTrede30": "trede", "B2aTrede60": "trede", "B2aTrede90": "trede",
              "B2bTrede30": "trede_r", "B2bTrede60": "trede_r", "B2bTrede90": "trede_r"}
VAST = {"S8": ["DeurLinks", "DeurRechts"], "S9": ["Hoogwater"]}


# ------------------------------------------------------------------ vaste stukken (deuren, hoogwater)
def sluisdeur_stuk(w, h, seed, ijzer=False):
    """Een deur of sluisdeur van w x h: planken met geroeste banden en klinknagels (deel 1, `sluisdeur`)."""
    t = T(w, h)
    yy, xx = np.mgrid[0:h, 0:w]
    if ijzer:                                            # de stalen schuifdeuren van de machinehal
        t.fill(yy >= 0, "ijzer", 3)
        t.fill((yy % 24) == 0, "ijzer", 5)
        t.fill((yy % 24) == 23, "ijzer", 1)
        t.fill(((yy % 24) == 4) & (xx % 6 == 3), "ijzer", 6)
        t.fill(xx == 0, "ijzer", 2)
        t.fill(xx == w - 1, "ijzer", 4)
        t.fill((yy % 48 > 40) & (xx > 2) & (xx < w - 2), "roest", 3)
    else:
        t.fill(yy >= 0, "hout", 3)
        t.fill(xx % 6 == 0, "hout", 2)
        t.fill((xx % 6 == 3) & ((yy + seed) % 9 == 1), "hout", 4)
        for by in range(10, h, 40):
            t.fill((yy >= by) & (yy < by + 4), "roest", 3)
            t.fill(yy == by, "roest", 5)
            t.fill((yy == by + 2) & (xx % 8 == 4), "ijzer", 6)
        t.fill(yy < 3, "hout", 5)
        t.fill(yy > h - 30, "klimop", 1)                 # nat en groen onderaan
        t.fill((yy > h - 30) & ((xx * 7 + yy) % 5 == 0), "klimop", 3)
    return t


def hoogwater_stuk():
    """Het hoogwater van S9 (blok `Hoogwater`, 60 x 275): een dichte sluisdeur met water dat eroverheen
    sijpelt. Weg bij s = 2 (`set_door(&"S9", "Hoogwater", false)`)."""
    _, x, y, w, h, _ = blok("S9", "Hoogwater")
    t = sluisdeur_stuk(w, h, 3)
    yy, xx = np.mgrid[0:h, 0:w]
    t.fill((xx % 13 == 5) & (yy < h - 30) & ((yy // 3 + xx) % 4 != 0), "water", 4)   # sijpelend water
    t.fill((yy < 6), "water", 5)
    t.fill(yy == 0, "water", 7)
    return t


# ------------------------------------------------------------------ S8 Machinehal
def bouw_s8():
    rx, ry, w, h = room("S8")
    k = Kamer("s8_machinehal", rx, w, h, wy=ry)
    YY, XX = k.YY, k.XX
    vloer = blok("S8", "Vloer")[2]                       # 320
    wl, wr = 20, 620
    # --- achter: de achterwand van de hal (baksteen, donker, koud), met het grote boograam achter de
    #     boss: tegenlicht, 2 tinten lichter rond het silhouet (deel 1 §4.4)
    k.paint(np.ones((h, w), bool), "lucht", "baksteen", 1)
    k.tegels(lambda i, j, x, y: "baksteen_donker_m1" if (i + j) % 2 else "baksteen_donker_m2", 0, 0, w, h, "lucht")
    cx = wl + 300                                        # het midden van de boss (arena-x 300)
    raam = D2.R_arch(k, cx - 110, cx + 110, 40, vloer - 20)
    k.paint(raam, "lucht", "lucht", 3)
    v = np.clip(6 - (YY - 40) / (vloer - 60) * 3 + k.BAY - 0.5, 0, 7).astype(int)   # koud licht, boven het helderst
    k.t[D2.LI["lucht"]][raam] = v[raam]
    k.paint(raam & ((np.abs(XX - cx) % 36 == 0) | ((YY - 40) % 44 == 0)), "lucht", "ijzer", 2)      # roeden
    k.paint(ndimage.binary_dilation(raam, iterations=4) & ~raam, "lucht", "steen", 3)
    k.paint(ndimage.binary_dilation(raam, iterations=1) & ~raam, "lucht", "steen", 5)
    # tegenlicht op de wand rond het raam (gedithered, 2 tinten): ook in grijs, het is koud licht
    gl = np.hypot((XX - cx) / 1.3, YY - (vloer - 70))
    for r_, dtt, dens in [(190, 1, 0.5), (150, 1, 0.75), (120, 2, 1.0)]:
        m = (gl < r_) & (k.BAY < dens) & ~raam
        k.add(m, "lucht", dtt)
    # plint van de achterwand: donker, zodat de rand van de vloer leest
    k.paint(k.rect(0, vloer - 12, w, vloer), "lucht", "baksteen", 0)
    k.paint(k.rect(0, vloer - 12, w, vloer - 11), "lucht", "steen", 2)
    # buiten het raam: de daklijn van de wijk, donker
    dak = raam & (YY > vloer - 90 + 10 * np.sin(XX / 17.0).astype(int))
    k.paint(dak, "lucht", "ver", 1)
    # --- huizen-laag: de machinerie langs de wanden (beeld): buizen, manometers, een vliegwiel-stomp
    for (px, mt) in [(wl + 40, "koper"), (wl + 52, "ijzer"), (wr - 60, "koper")]:
        k.paint(k.rect(px, 0, px + 6, vloer), "huizen", mt, 3)
        k.paint(k.rect(px, 0, px + 1, vloer), "huizen", mt, 5)
        for fy in range(30, vloer, 70):
            k.paint(k.rect(px - 1, fy, px + 7, fy + 3), "huizen", mt, 2)
    for (mx, my) in [(wl + 70, 200), (wr - 80, 160)]:
        d_ = np.hypot(XX - mx, YY - my)
        k.paint(d_ < 9, "huizen", "koper", 3)
        k.paint(d_ < 7, "huizen", "huis_wit", 4)
        k.paint((d_ < 6) & (np.abs((XX - mx) - (YY - my) * -0.6) < 0.7) & (YY < my), "huizen", "raamdonker", 0)
    vw = np.hypot(XX - (wl + 20), YY - (vloer - 60))
    k.paint((vw < 54) & (vw > 46), "huizen", "ijzer", 2)
    k.paint((vw < 46) & (np.abs(np.sin(np.arctan2(YY - vloer + 60, XX - wl - 20) * 3)) < 0.1), "huizen", "ijzer", 2)
    k.paint(vw < 8, "huizen", "ijzer", 3)
    # de balk van het rad (fase 2: het rad hangt op 100–140 boven de vloer) en een loopkat
    by = vloer - 168
    k.paint(k.rect(wl, by, wr, by + 10), "midden", "ijzer", 3)
    k.paint(k.rect(wl, by, wr, by + 1), "midden", "ijzer", 5)
    k.paint(k.rect(wl, by + 9, wr, by + 10), "midden", "ijzer", 1)
    k.paint(k.rect(wl, by + 3, wr, by + 4) & (XX % 12 == 0), "midden", "ijzer", 6)   # klinknagels
    for kx in (wl + 4, wr - 14):
        k.paint(k.rect(kx, by - 30, kx + 10, by + 10) & ((np.abs((XX - kx) - (YY - by + 30) * 0.25) < 2) | (YY > by)), "midden", "ijzer", 2)
    k.paint(k.rect(cx - 10, by + 10, cx + 10, by + 16), "midden", "ijzer", 4)        # loopkat
    k.paint(k.rect(cx - 1, by + 16, cx + 1, by + 26), "midden", "ijzer", 3)          # ketting (het rad is van de boss)
    # --- speelvlak: de vloer (gietijzeren platen op hardsteen), de spuigaten, muren en drempel
    _, x, y, bw, bh, _ = blok("S8", "Vloer")
    k.tegels(lambda i, j, xx_, yy_: ("kade_boven_m1" if i % 2 else "kade_boven_m2") if j == 0 else
             ("kelderbodem_m1" if (i + j) % 2 else "kelderbodem_m2"), x, y, x + bw, h, "speelvlak")
    platen = k.rect(x, y + 2, x + bw, y + 5)
    k.paint(platen & ((XX - x) % 40 < 38), "speelvlak", "ijzer", 3)
    k.paint(platen & ((XX - x) % 40 == 20), "speelvlak", "ijzer", 6)
    for sx in (4416 - rx, 4544 - rx):                    # spuigaten (GMB-03): roosters in de vloer
        k.stamp(tegel("rooster"), sx - 8, vloer, "speelvlak")
    for naam in ("MuurRechts", "Drempel"):
        _, x, y, bw, bh, _ = blok("S8", naam)
        k.tegels(lambda i, j, xx_, yy_: "kade_wand_hoog_m1" if (i + j) % 2 else "kade_wand_hoog_m2", x, y, x + bw, y + bh, "speelvlak")
        k.paint(k.rect(x, y, x + bw, y + 1), "speelvlak", "steen", 6)
    # de deuropeningen (midden): donker, met een boog; de deuren zelf zijn vaste stukken
    for (dx0, dx1, dy0) in [(0, wl, 0), (wr, w, 0)]:
        k.paint(k.rect(dx0, dy0, dx1, vloer), "midden", "raamdonker", 0)
        k.paint(k.rect(dx0, dy0, dx1, dy0 + 8), "midden", "steen", 3)
    # --- lampen: in grijs (s < 2) geen warm licht in de arena (kleurscript S8); in kleur hangen er lampen
    wu, wa = D2.wandlamp()
    for lx in (wl + 100, wr - 116):
        k.wissel.append(("huizen", lx, 120, wu, wa, dict(grijs=False, half=True, kleur=True)))
        k.lampen.append(dict(x=lx + 8, y=134, r=1.1, aan=dict(grijs=False, half=True, kleur=True)))
    return k


def boss_concept(fase="fase1"):
    """De Gemaalmeester uit de concept-sheet van deel 1, als RGBA op de arena (alleen voor de renders)."""
    img = D1.gm_render(fase)
    body = D1.gm_lichaam(fase)
    m = ndimage.binary_dilation(body, iterations=1)
    m[D1.ay(60):D1.ay(12), 276:324] = True
    out = np.zeros(img.shape[:2] + (4,))
    out[m, :3] = img[m]
    out[m, 3] = 1
    return out


# ------------------------------------------------------------------ S9 Lage kade
def bouw_s9():
    rx, ry, w, h = room("S9")
    k = Kamer("s9_lage_kade", rx, w, h, wy=ry)
    YY, XX = k.YY, k.XX
    kade_y = blok("S9", "Kade")[2]                       # 275
    beneden = blok("S9", "Benedenkade")[2]               # 340
    kw = blok("S9", "Kadewand")                          # x 520..540, tot 291
    grond = 118                                          # de hoge kade (de wijk) boven je
    water_y = kade_y - 14                                # gezakt water (s = 2), vóór de oude kademuur
    oud_water = grond + 34                               # de oude waterstand: de getijdenrand
    # --- achter: de lucht en de verlichte wijk op de hoge kade (pillar 2: het beeld is de beloning)
    D2.lucht_en_ver(k, 909, belfort=(1720, -10), top_range=(30, 70))
    D2.huizenrij(k, 560, w, grond, 91, 0, 40, lit_p=0.85)
    # --- de oude kademuur (huizen-laag) van x 540 tot het eind, met de getijdenrand en het gezakte water
    k.tegels(lambda i, j, x, y: ("kade_boven_m1" if i % 2 else "kade_boven_m2") if j == 0 else
             ("kade_wand_hoog_m1" if (i + j) % 2 else "kade_wand_hoog_m2"), 540, grond, w, water_y + 4, "huizen")
    muur = k.rect(540, grond, w, water_y + 4)
    k.add(muur & (YY > oud_water + 10), "huizen", -1)                 # nat onder de oude waterstand
    k.tegels(lambda i, j, x, y: "kade_getij_m1" if i % 2 else "kade_getij_m2", 540, oud_water, w, oud_water + 16, "huizen")
    k.paint(muur & (YY >= oud_water + 16) & (k.BAY < 0.18) & (((XX * 3) % 7) == 0), "huizen", "klimop", 2)
    for mx in range(700, w, 380):                                     # meerringen en een trapje in de muur
        k.stamp(tegel("kade_meerring"), mx, oud_water + 24, "huizen")
    for (dx, dw) in [(1180, 44), (2560, 44), (3600, 44)]:            # duikers aan de voet
        boog = D2.R_arch(k, dx, dx + dw, water_y - 46, water_y + 4)
        k.paint(ndimage.binary_dilation(boog, iterations=2) & ~boog & muur, "huizen", "steen", 4)
        k.paint(boog, "huizen", "raamdonker", 0)
    # een stenen brug over de gracht tussen het Dwaallicht en het E-paar (x 1480–1940): zijaanzicht, de boog
    # staat in het water vóór de oude kademuur, het dek op de hoogte van de wijk, met lantaarns
    bx0, bx1 = 1480, 1940
    bcx = (bx0 + bx1) / 2
    e = ((XX - bcx) / ((bx1 - bx0) / 2 - 20)) ** 2 + ((YY - water_y) / 110.0) ** 2
    lijf = k.rect(bx0, grond - 14, bx1, water_y + 4)
    k.paint(lijf & (e >= 1.14), "huizen", "baksteen", 3)
    k.add(lijf & (e >= 1.14) & ((YY % 4) == 0), "huizen", -1)
    k.paint(lijf & (e >= 1.0) & (e < 1.14), "huizen", "steen", 4)
    k.paint(lijf & (e >= 1.0) & (e < 1.14) & (np.abs(np.sin(np.arctan2(YY - water_y, XX - bcx) * 22)) < 0.15), "huizen", "steen", 2)
    k.paint(lijf & (e < 1.0), "huizen", "raamdonker", 1)             # onder de boog: de gracht erachter, donker
    k.paint(k.rect(bx0 - 6, grond - 18, bx1 + 6, grond - 10), "huizen", "steen", 5)
    k.paint(k.rect(bx0 - 6, grond - 18, bx1 + 6, grond - 17), "huizen", "steen", 6)
    for px in range(bx0, bx1, 10):
        k.paint(k.rect(px, grond - 30, px + 2, grond - 18), "huizen", "ijzer", 2)
    k.paint(k.rect(bx0, grond - 31, bx1, grond - 29), "huizen", "ijzer", 3)
    for lx in (bx0 + 30, int(bcx), bx1 - 30):
        k.paint(k.rect(lx - 1, grond - 52, lx + 1, grond - 30), "huizen", "ijzer", 2)
        k.paint(k.rect(lx - 3, grond - 58, lx + 3, grond - 52), "huizen", "ijzer", 4)
        k.lampen.append(dict(x=lx, y=grond - 55, r=0.7, aan=dict(grijs=False, half=True, kleur=True)))
    # het water (gezakt), met weerspiegelde lichten in kleur
    wat = k.rect(540, water_y, w, kade_y)
    k.paint(wat, "midden", "water", 2)
    k.paint(k.rect(540, water_y, w, water_y + 1), "midden", "water", 5)
    k.paint(k.rect(540, water_y, w, water_y + 1) & ((XX // 5) % 4 == 0), "midden", "water", 7)
    r_ = rng(9)
    for _ in range(140):
        wx = int(r_.integers(560, w - 4))
        k.ramen.append(dict(x=wx, y=int(water_y + 3 + r_.integers(0, 8)), w=int(r_.integers(2, 5)), h=1, laag="midden",
                            jit=float(r_.random()), kruis=False, aan=dict(grijs=False, half=bool(r_.random() < 0.5), kleur=True)))
    # bootjes aan de kade bij het rustpunt (beeld, in het water vóór de muur)
    for (bx, bl) in [(3420, 70), (3560, 54)]:
        romp = (k.rect(bx, water_y - 6, bx + bl, water_y + 4)) & (np.abs(XX - (bx + bl / 2)) < bl / 2 - (YY - water_y + 6) * 0.8)
        k.paint(romp, "midden", "hout", 3)
        k.paint(romp & (YY == water_y - 6), "midden", "hout", 5)
        k.paint(romp & (YY > water_y), "midden", "hout", 2)
        k.paint(k.rect(bx + bl // 2, water_y - 26, bx + bl // 2 + 1, water_y - 6), "midden", "hout", 3)
        k.lampen.append(dict(x=bx + bl // 2 + 4, y=water_y - 24, r=0.6, aan=dict(grijs=False, half=True, kleur=True)))
        k.paint(k.rect(bx + bl // 2 + 2, water_y - 27, bx + bl // 2 + 6, water_y - 22), "midden", "ijzer", 4)
    # --- de kelder onder S1 (x 0..520): een tongewelf van baksteen, de schacht naar het snelluik
    kel = k.rect(0, 0, int(kw[1]), h)
    k.tegels(lambda i, j, x, y: "baksteen_donker_m1" if (i + j) % 2 else "baksteen_donker_m2", 0, 0, int(kw[1]), h, "huizen", dt=-1)
    for vx in range(40, int(kw[1]), 120):
        gw = (np.hypot((XX - vx - 60) / 64.0, (YY - 120) / 100.0) >= 1.0) & (np.hypot((XX - vx - 60) / 64.0, (YY - 120) / 100.0) < 1.1) & (YY < 120) & kel
        k.paint(gw, "huizen", "steen", 2)
    sx0, sx1 = 460, 500                                  # schacht
    k.paint(k.rect(sx0, 0, sx1, 250), "midden", "baksteen", 1)
    k.paint(k.rect(sx0 + 12, 0, sx0 + 28, 250) & (k.BAY < 0.15 + 0.2 * (1 - YY / 250)), "midden", "steen", 5)  # licht uit S1
    for b in blokken("S9"):
        if b[0].startswith("Schacht"):
            k.stamp(D2.ninepatch(D2.trede_stuk(), b[3]), b[1], b[2], "speelvlak")
    wu, wa = D2.wandlamp()
    k.wissel.append(("midden", 280, 196, wu, wa, dict(grijs=False, half=True, kleur=True)))
    k.lampen.append(dict(x=288, y=210, r=0.9, aan=dict(grijs=False, half=True, kleur=True), links_van=20))
    # logbladzijde 3 op de galerij: een lessenaar met een boek (beeld, het object is van de GP)
    # --- speelvlak: de wanden, de lage kade, de benedenkade, de platen naast het luik
    for naam in ("WandLinks", "Kadewand", "PijlerWand", "TrapWandLinks", "TrapWandRechts"):
        _, x, y, bw, bh, _ = blok("S9", naam)
        k.tegels(lambda i, j, xx_, yy_: "baksteen_m1" if (i + j) % 2 else "baksteen_m2", x, y, x + bw, y + bh, "speelvlak")
        k.paint(k.rect(x, y, x + 1, y + bh), "speelvlak", "steen", 2)
        k.paint(k.rect(x + bw - 1, y, x + bw, y + bh), "speelvlak", "steen", 5)
    _, x, y, bw, bh, _ = blok("S9", "Kade")
    k.tegels(lambda i, j, xx_, yy_: ("kade_boven_l" if i == 0 else ("kade_boven_m1" if i % 2 else "kade_boven_m2")) if j == 0 else
             ("kade_wand_hoog_m1" if j < 3 else ("kelderbodem_m1" if (i + j) % 2 else "kelderbodem_m2")), x, y, x + bw, h, "speelvlak")
    k.tegels(lambda i, j, xx_, yy_: "kade_getij_m1" if i % 2 else "kade_getij_m2", x, y + 30, x + bw, y + 46, "speelvlak")
    for naam in ("Plaat", "Plaat2"):
        _, x, y, bw, bh, _ = blok("S9", naam)
        k.tegels(lambda i, j, xx_, yy_: "kade_boven_m1" if i % 2 else "kade_boven_m2", x, y, x + bw, y + bh, "speelvlak")
    _, x, y, bw, bh, _ = blok("S9", "Benedenkade")
    k.tegels(lambda i, j, xx_, yy_: "kade_boven_m1" if i % 2 else "kade_boven_m2", x, y, x + bw, h, "speelvlak")
    _, x, y, bw, bh, _ = blok("S9", "Deurvloer")
    k.tegels(lambda i, j, xx_, yy_: ("kade_boven_m1" if i % 2 else "kade_boven_m2") if j == 0 else "kelderbodem_m1", x, y, x + bw, h, "speelvlak")
    # onder de platen (open: daar val je naar de benedenkade) en tussen de kade en de benedenkade
    k.tegels(lambda i, j, x_, y_: "baksteen_donker_m1" if (i + j) % 2 else "baksteen_donker_m2", 540, kade_y, 700, beneden, "huizen", dt=-1)
    # de brugpijler (speelvlak) en zijn brug erboven (midden): de pijler draagt een boog naar links en rechts
    _, x, y, bw, bh, _ = blok("S9", "Pijler")
    k.tegels(lambda i, j, xx_, yy_: "kade_wand_hoog_m1" if (i + j) % 2 else "kade_wand_hoog_m2", x, y, x + bw, y + bh, "speelvlak")
    k.paint(k.rect(x, y, x + bw, y + 2), "speelvlak", "steen", 6)
    for (c, kant) in [(x - 140, -1), (x + bw + 260, 1)]:
        e = ((XX - c) / (150 if kant < 0 else 270)) ** 2 + ((YY - (y + 30)) / 120.0) ** 2
        boog = (e >= 1) & (e < 1.15) & (YY < y + 30) & (YY > 0)
        zwik = (e >= 1.15) & (YY < y + 30) & (np.abs(XX - c) < (150 if kant < 0 else 270) + 30)
        k.paint(zwik, "midden", "baksteen", 1)       # het lijf van de brug: een donkere achtergrond voor de richels
        k.add(zwik & ((YY % 4) == 0), "midden", -1)
        k.paint(boog, "midden", "steen", 2)
        k.paint(boog & (e < 1.03), "midden", "steen", 4)
        onder = (e < 1) & (YY < y + 30)                  # slagschaduw onder de brug: de wijk erachter donkerder
        k.add(onder, "huizen", -2)
        k.add(onder & (k.BAY < 0.5), "ver", -1)
        for rm in k.ramen:                               # ramen onder de brug blijven donker (de brug ligt ervoor)
            if rm["laag"] == "huizen" and onder[min(k.h - 1, rm["y"]), min(k.w - 1, rm["x"])]:
                rm["aan"] = dict(grijs=False, half=False, kleur=False)
    # trap naar het plein (treden van de trap van S9) tussen de trapwanden
    for b in blokken("S9"):
        if b[0].startswith("Trap9"):
            k.stamp(D2.ninepatch(D2.trede_stuk(), 32), b[1], b[2], "speelvlak")
    k.tegels(lambda i, j, x_, y_: "baksteen_donker_m1" if (i + j) % 2 else "baksteen_donker_m2", 4100, 0, 4150, 320, "midden", dt=-1)
    # lampen op de lage kade (aan na trap 2), één per ± 500 px
    su, sa = D2.straatlamp()
    for lx in range(900, 3900, 520):
        k.wissel.append(("midden", lx - 8, kade_y - 48, su, sa, dict(grijs=False, half=True, kleur=True)))
        k.lampen.append(dict(x=lx, y=kade_y - 40, r=0.8, aan=dict(grijs=False, half=True, kleur=True)))
    return k


# ------------------------------------------------------------------ figuren (renders)
def figuren(id_, staat):
    kleur, donker = staat == "kleur", staat != "kleur"
    rx, ry, _, _ = room(id_)

    def f(img):
        if id_ == "S8":
            boss = boss_concept("fase1")                 # concept uit deel 1: alleen ter beoordeling
            D1.stamp_rgba(img, boss, 20, 320 - D1.AV)
            # punt van de CD: P1 en de echo bij de ketel in fase 1, de echo moet hol leesbaar zijn
            return D2.plak_fig(img, [("p1", SP.P1_RUN[0], 20 + 236, 320, False, True),
                                     ("echo", SP.P1_JUMP, 20 + 268, 300, False, kleur)], 0)
        if id_ == "S9":
            img = D2.plak_fig(img, [("echo", SP.P1_RUN[2], 3460, 275, True, kleur),
                                    ("p1", SP.P1_RUN[0], 3380, 275, True, True),
                                    ("echo", SP.P1_RUN[1], 1840, 275, True, kleur),
                                    ("p1", SP.P1_JUMP, 1760, 250, True, True)], 0)
            for wx in (1060, 1088):
                body, kern, ogen, extra = D1.kadeloper("idle")
                lay = D1.vijand_render(body, kern, ogen, extra, staat="kleur", donker=donker)
                D1.stamp_rgba(img, lay, wx - lay.shape[1] // 2, 275 - lay.shape[0])
            body, kern, ogen, extra = D1.dwaallicht("idle")
            lay = D1.vijand_render(body, kern, ogen, extra, staat="kleur", donker=donker)
            D1.stamp_rgba(img, lay, 2310 - lay.shape[1] // 2, 587 - 360 - lay.shape[0] // 2)
            D1.stamp_rgba(img, D4.luik(0).render("kleur" if kleur else "grijs"), 560, 275)
            return img
        return img
    return f


def met_stukken(k, id_, staat="grijs", golf=None, d=D):
    L = D2.LI["speelvlak"]
    bm, bt = k.mat[L].copy(), k.t[L].copy()
    try:
        for (naam, x, y, w, h, e) in blokken(id_, d):
            if id_ == "S9" and naam in S9_STUKKEN:
                k.stamp(D2.ninepatch(D2.EENRICHTING[S9_STUKKEN[naam]], int(w)), x, y, "speelvlak")
            if naam in VAST.get(id_, []) and not (id_ == "S8" and naam == "DeurRechts"):
                k.stamp(VASTE_STUKKEN[f"{id_}/{naam}"], x, y, "speelvlak")
        return k.render(staat, golf)
    finally:
        k.mat[L], k.t[L] = bm, bt


VASTE_STUKKEN = {}


def maak_vaste_stukken():
    for id_, namen in VAST.items():
        for naam in namen:
            _, x, y, w, h, _ = blok(id_, naam)
            if id_ == "S9":
                VASTE_STUKKEN[f"{id_}/{naam}"] = hoogwater_stuk()
            else:
                VASTE_STUKKEN[f"{id_}/{naam}"] = sluisdeur_stuk(w, h, len(naam), ijzer=True)


def echo_leesbaarheid(img_met, img_zonder):
    """ΔL* van de holle echo (contour, p90) tegen de ring van 2..6 px, en idem voor P1."""
    diff = np.abs(img_met - img_zonder).sum(-1) > 0.02
    lab, n = ndimage.label(ndimage.binary_dilation(diff, iterations=1))
    L = R.srgb_to_lab(img_met)[..., 0]
    out = []
    for i in range(1, n + 1):
        m = lab == i
        if m.sum() < 60:
            continue
        ring = ndimage.binary_dilation(m, iterations=6) & ~ndimage.binary_dilation(m, iterations=2)
        xs = np.nonzero(m)[1]
        out.append((int(xs.min()), int(xs.max()), abs(float(np.percentile(L[m & diff], 90)) - float(np.median(L[ring])))))
    return out


def main():
    if "--snel" not in sys.argv:
        D4.main()
    with open(os.path.join(UIT_GAME, "kadewijk_kamers.json")) as f:
        manifest = json.load(f)
    print("Slice-art deel 5: S8 en S9 (D = 60)")
    maak_vaste_stukken()
    kamers = {"S8": bouw_s8(), "S9": bouw_s9()}
    for k in kamers.values():
        D2.export_kamer(k, manifest)
    manifest["eenrichting"]["blokken"].update({f"S9/{n}": s for n, s in S9_STUKKEN.items()})
    plaats = {"S8/DeurLinks": "dicht tot BOSS_VERSLAGEN: zichtbaar zolang het blok collision heeft (`Kadewijk.set_door`)",
              "S8/DeurRechts": "open tot BOSS_START (START_OPEN): zichtbaar zolang het blok collision heeft",
              "S9/Hoogwater": "tot s = 2: zichtbaar zolang het blok collision heeft (`set_door(&\"S9\", \"Hoogwater\", false)`)"}
    for key, t in VASTE_STUKKEN.items():
        naam = key.replace("/", "_").lower()
        manifest["vaste_stukken"][key] = D3.stuk_export(f"kadewijk_{naam}", t, dict(
            plaatsing="Sprite2D linksboven op het blok met dezelfde naam, z -10; " + plaats[key]))
    manifest["objecten"]["gemaal_rad"]["fps_vol"] = 6
    manifest["versie"] = "0.5"
    with open(os.path.join(UIT_GAME, "kadewijk_kamers.json"), "w") as f:
        json.dump(manifest, f, indent=1, ensure_ascii=False)

    metingen = {}
    for id_, k in kamers.items():
        r_ = {}
        for staat in ["grijs", "kleur"]:
            lagen = met_stukken(k, id_, staat)
            zonder = k.samengesteld(lagen)
            met = k.samengesteld(lagen, figuren(id_, staat))
            r_[staat] = (zonder, met)
            D2.save(met, os.path.join(UIT_DOCS, f"{k.naam}_{staat}_{k.w}x{k.h}.png"))
            vlakken = [(x, y, w) for (n, x, y, w, h, e) in blokken(id_) if 2 < y < k.h and w >= 8 and n not in VAST.get(id_, [])]
            metingen[(k.naam, staat)] = dict(chroma=D2.chroma(zonder), loopvlak=D2.loopvlak_contrast(zonder, vlakken))
            if id_ == "S8":
                zb = zonder.copy()
                D1.stamp_rgba(zb, boss_concept("fase1"), 20, 320 - D1.AV)
                metingen[(k.naam, staat)]["figuren"] = echo_leesbaarheid(met, zb)
        if id_ == "S8":
            vb = np.concatenate([D2.label_bar(k.w, "GRIJS", "S = 1, HET GEVECHT (BOSS: CONCEPT DEEL 1)"), r_["grijs"][1],
                                 D2.label_bar(k.w, "KLEUR", "S = 2, NA DE BOSS EN TRAP 2"), r_["kleur"][1]], 0)
            D2.save(vb, os.path.join(UIT_DOCS, f"{k.naam}_vergelijking_x2.png"), 2)
            # de ketel ×4: de holle echo naast P1 vóór het donkere lijf en het tegenlicht
            crop = [r_[s][1][320 - 150:320 + 8, 20 + 180:20 + 420] for s in ("grijs", "kleur")]
            D2.save(np.concatenate([D2.label_bar(240, "KETEL GRIJS"), crop[0], D2.label_bar(240, "KETEL KLEUR"), crop[1]], 0),
                    os.path.join(UIT_DOCS, "s8_machinehal_ketel_echo_x4.png"), 4)
            lum = R.grayscale(r_["grijs"][1])
            D2.save(np.concatenate([D2.label_bar(640, "LUMINANTIE", "GRIJS"), lum, D2.label_bar(640, "DEUTERANOPIE", "GRIJS"),
                                    R.deuteranopia(r_["grijs"][1])], 0), os.path.join(UIT_DOCS, "s8_machinehal_leesbaarheid_x2.png"), 2)
        else:
            # S9: twee camera-uitsneden waar de CD het beeld de beloning wil (rustpunt, tussenstuk)
            for (nm, x0) in [("rustpunt", 3060), ("tussenstuk", 1440)]:
                vb = np.concatenate([D2.label_bar(640, "GRIJS", f"{nm.upper()}, X {x0}-{x0 + 640}"), r_["grijs"][1][:, x0:x0 + 640],
                                     D2.label_bar(640, "KLEUR", "NA TRAP 2: VERLICHTE WIJK, GEZAKT WATER"), r_["kleur"][1][:, x0:x0 + 640]], 0)
                D2.save(vb, os.path.join(UIT_DOCS, f"s9_lage_kade_{nm}_x2.png"), 2)
            D2.save(r_["kleur"][1][:, 0:1100], os.path.join(UIT_DOCS, "s9_lage_kade_kelder_kleur_1100x360.png"))
        D2.save(D2.geometrie_controle(r_["grijs"][0], k, [(x, y, w, h, e) for (n, x, y, w, h, e) in blokken(id_) if y + h > 0]),
                os.path.join(UIT_DOCS, f"{k.naam}_geometrie_controle_x2.png"))
        if id_ == "S9":
            img = k.samengesteld(met_stukken(k, id_, "grijs", d=120))[:, 2700:3400]
            bl = [(x - 2700, y, w, h, e) for (n, x, y, w, h, e) in blokken(id_, 120) if y + h > 0 and x + w > 2700 and x < 3400]
            D2.save(D2.geometrie_controle(img, k, bl), os.path.join(UIT_DOCS, "s9_lage_kade_pijler_d120_x2.png"))
        # lichtovergang
        v, lag = 300.0, 0.4
        gx, gy = D2.GEMAAL_WERELD[0] - k.wx, D2.GEMAAL_WERELD[1] - k.wy
        hoeken = [np.hypot(gx - cx, gy - cy) for cx in (0, k.w) for cy in (0, k.h)]
        t0 = max(0.0, min(hoeken) / v - 0.1)
        t1 = max(hoeken) / v + lag + 0.15
        strip = []
        for tt in np.linspace(t0, t1, 5):
            img = k.samengesteld(met_stukken(k, id_, "grijs", golf=(v * tt, v * (tt - lag))))
            if k.w > 640:
                img = img[:, 3060:3700]
            strip += [D2.label_bar(640, f"T = {tt:.1f} S NA GEMAAL_VOL", "HALF-VOORKANT %d PX" % int(v * tt)), img]
        D2.save(np.concatenate(strip, 0), os.path.join(UIT_DOCS, f"{k.naam}_lichtovergang_strip.png"))

    print("  metingen deel 5 (chroma; ΔL* loopvlakken; figuren):")
    for (naam, staat), m in metingen.items():
        print(f"    {naam:16s} {staat:6s} chroma {m['chroma']:5.1f}   loopvlak ΔL* " + " ".join(f"{x:4.1f}" for x in m["loopvlak"]))
        for (x0, x1, dl) in m.get("figuren", []):
            print(f"      figuur x {x0}-{x1}: ΔL* contour {dl:4.1f}")


if __name__ == "__main__":
    main()
