"""Slice-art deel 4, de Kadewijk: S5 Sluiswachtershuis, S6 Gemaalplein en S7 Sluiskelder op eindkwaliteit,
plus de objecten (breekbaar luik V-01 voor S7 en S9, holle schaduwklep, pompschoep met pompslag, sluisklep,
sokkel, het rad van het gemaal). Art Director, #85, T8c.

Draait eerst deel 3 (dat deel 2 draait: S1–S4, manifest, eenrichtingsatlas met `trede_r`) en voegt toe:
  - S5, S6, S7 als kamerlagen (achter, midden, speelvlak, licht, voor) in grijs, half, kleur en index;
  - in S6 de extra laag `gemaal_aan` (trap 1: het gemaal is aan, de wijk nog grijs);
  - `kadewijk_objecten_*.png` (atlas met alle objecten, frames in het manifest);
  - renders, lichtovergang, geometriecontrole bij D = 60 en 120, metingen.

De geometrie komt uit `kadewijk_blokken.json` (Layout.blocks() van alle kamers, gedumpt met
`dump_blokken.gd` in Godot 4.6.3), dus de art leest dezelfde getallen als het spel.

Eigen werk (docs/licenties.md §2). Draaien vanaf de repo-root:
    python3 docs/art/slice/bron/genereer_slice_deel4.py
"""
import json
import os
import sys

import numpy as np
from scipy import ndimage

HIER = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HIER)
import genereer_slice_deel3 as D3  # noqa: E402

D2 = D3.D2
D1, R, SP = D2.D1, D2.R, D2.SP
T, MI, K = D2.T, D2.MI, D2.K
Kamer, STATEN = D2.Kamer, D2.STATEN
UIT_GAME, UIT_DOCS = D2.UIT_GAME, D2.UIT_DOCS
tegel, rng = D2.tegel, D2.rng
D = D2.D

with open(os.path.join(HIER, "kadewijk_blokken.json")) as f:
    BLOKKEN = json.load(f)

# Welke blokken een eenrichtingsstuk per D krijgen (S5: richels en treden van B2).
S5_STUKKEN = {"Richel1": "richel", "Richel2": "richel", "Richel3": "richel", "Zolder": "richel"}
for _v, _s in [("B2a", "trede_r"), ("B2b", "trede"), ("B2c", "trede_r"), ("B2d", "trede")]:
    for _h in (30, 60, 90):
        S5_STUKKEN[f"{_v}Trede{_h}"] = _s


def room(id_):
    x, y, w, h = BLOKKEN["60"][id_]["rect"]
    return int(x), int(y), int(w), int(h)


def blokken(id_, d=D):
    """[(naam, x, y, w, h, eenrichting)] lokaal (ten opzichte van linksboven van de kamer)."""
    rx, ry, _, _ = room(id_)
    return [(b[0], int(round(b[1] - rx)), int(round(b[2] - ry)), int(round(b[3])), int(round(b[4])), b[5])
            for b in BLOKKEN[str(d)][id_]["blocks"]]


def blok(id_, naam, d=D):
    return next(b for b in blokken(id_, d) if b[0] == naam)


def rect_of(k, b):
    _, x, y, w, h, _ = b
    return k.rect(x, y, x + w, y + h)


# ------------------------------------------------------------------ hulp: binnenmuren
def pleister(k, m, laag, mat, base, seed=0):
    """Gepleisterde binnenmuur: vlak met een zachte korrel en scheurtjes, onderaan een plint."""
    k.paint(m, laag, mat, base)
    r = rng(seed)
    korrel = (r.random((k.h, k.w)) < 0.05) & m
    k.add(korrel, laag, -1)
    k.add(m & (k.BAY < 0.08) & (((k.XX * 5 + k.YY * 3 + seed) % 13) == 0), laag, 1)


def lambrisering(k, x0, x1, y0, y1, laag, mat="hout"):
    m = k.rect(x0, y0, x1, y1)
    k.paint(m, laag, mat, 2)
    k.paint(m & ((k.XX - x0) % 24 == 0), laag, mat, 1)
    k.paint(m & ((k.XX - x0) % 24 == 1), laag, mat, 3)
    k.paint(k.rect(x0, y0, x1, y0 + 2), laag, mat, 3)   # donkere lijst: geen valse richel boven de lambrisering
    k.paint(k.rect(x0, y0, x1, y0 + 1), laag, mat, 1)


def raam_buiten(k, x, y, w, h, laag, seed, lit_k=True):
    """Een raam in de achterwand met de nacht erachter (lucht, een daklijn); kozijn en roeden."""
    k.paint(k.rect(x - 3, y - 3, x + w + 3, y + h + 4), laag, "hout", 3)
    k.paint(k.rect(x - 3, y - 3, x + w + 3, y - 2), laag, "hout", 5)
    k.paint(k.rect(x - 4, y + h + 2, x + w + 4, y + h + 4), laag, "steen", 5)
    glas = k.rect(x, y, x + w, y + h)
    v = np.clip(1 + (k.YY - y) / max(1, h) * 3 + k.BAY - 0.5, 0, 4).astype(int)
    k.paint(glas, laag, "lucht", 1)
    k.t[D2.LI[laag]][glas] = v[glas]
    r = rng(seed)
    top = y + h - 6 - (r.random(k.w) * 6).astype(int)
    dak = glas & (k.YY >= top[k.XX])
    k.paint(dak, laag, "ver", 1)
    for _ in range(3):                                   # verre ramen: alleen aan in kleur (emissief via ramen)
        wx, wy = x + int(r.integers(2, max(3, w - 3))), y + h - 4
        k.ramen.append(dict(x=wx, y=wy, w=1, h=2, laag=laag, jit=float(r.random()), kruis=False,
                            aan=dict(grijs=False, half=lit_k, kleur=lit_k)))
    k.paint(k.rect(x + w // 2, y, x + w // 2 + 1, y + h) | k.rect(x, y + h // 2, x + w, y + h // 2 + 1), laag, "hout", 4)


def plank_vloer(k, x0, x1, y, laag, dt=0):
    """Houten vloerdelen met een balk eronder (speelvlak-vloer van een verdieping, niet eenrichting)."""
    m = k.rect(x0, y, x1, y + 6)
    k.paint(m, laag, "hout", 4 + dt)
    k.paint(k.rect(x0, y, x1, y + 1), laag, "hout", 6 + dt)
    k.paint(m & ((k.XX - x0) % 20 == 19), laag, "hout", 2 + dt)
    k.paint(k.rect(x0, y + 5, x1, y + 6), laag, "hout", 2 + dt)


# ------------------------------------------------------------------ S5 Sluiswachtershuis
def bouw_s5():
    rx, ry, w, h = room("S5")
    k = Kamer("s5_sluiswachtershuis", rx, w, h, wy=ry)
    YY, XX = k.YY, k.XX
    vl = blok("S5", "Vloer")[2]                       # 460
    lv = [vl] + [blok("S5", n)[2] for n in ("Richel1", "Richel2", "Richel3", "Zolder")]   # 460, 370, 280, 190, 100
    wl = 80                                            # binnenkant linkerwand
    wr = blok("S5", "WandRechts")[1]                   # 560
    # --- achter: de lucht boven het dak en het dak (zolder), daarna de binnenmuur per verdieping
    k.paint(np.ones((h, w), bool), "lucht", "lucht", 0)
    k.t[D2.LI["lucht"]] = np.clip(1 + YY / 200 * 3 + k.BAY - 0.5, 0, 5).astype(np.int16)
    k.sterren = [(int(x), int(y), bool(i % 3)) for i, (x, y) in enumerate(rng(55).integers(0, [w, 90], (40, 2)))]
    # verdiepingen: elk een eigen muur, plint, raam en inrichting (variatie per verdieping, LGD-besluit #227)
    vloeren = [
        # (y_boven, y_onder, mat, base, naam)
        (lv[1] + 6, lv[0], "huis_wit", 2, "keuken"),
        (lv[2] + 6, lv[1], "huis_groen", 2, "wasruimte"),
        (lv[3] + 6, lv[2], "huis_oker", 2, "werkplaats"),
        (lv[4] + 6, lv[3], "huis_rood", 2, "kaartenkamer"),
    ]
    for i, (y0, y1, mat, base, _) in enumerate(vloeren):
        pleister(k, k.rect(wl, y0, wr, y1), "huizen", mat, base, seed=i + 1)
        lambrisering(k, wl, wr, y1 - 18, y1, "huizen")
        k.add(k.rect(wl, y0, wr, y0 + 10) & (k.BAY < (y0 + 10 - YY) / 10), "huizen", -1)   # schaduw onder de richel
    # zolder: schuin dak met sporen, een dakraam met sterren
    zold = k.rect(wl, 0, w, lv[4] + 6)
    k.paint(zold, "huizen", "hout", 2)
    for sx in range(wl - 40, w + 40, 34):                               # sporen
        spoor = (np.abs((XX - sx) - (lv[4] - YY) * 0.55) < 3) & zold
        k.paint(spoor, "huizen", "hout", 3)
        k.paint(spoor & (np.abs((XX - sx) - (lv[4] - YY) * 0.55) < 1), "huizen", "hout", 4)
    k.paint(zold & (YY % 12 == 0), "huizen", "hout", 1)                 # panlatten
    k.paint(k.rect(wl, 40, w, 46), "huizen", "hout", 4)                 # hanenbalk
    k.paint(k.rect(wl, 40, w, 41), "huizen", "hout", 5)
    dakraam = k.rect(300, 8, 340, 34)
    k.paint(dakraam, "huizen", "lucht", 2)
    k.paint(ndimage.binary_dilation(dakraam, iterations=2) & ~dakraam, "huizen", "hout", 3)
    for (sx, sy) in [(306, 14), (322, 20), (334, 12), (314, 27)]:
        k.ramen.append(dict(x=sx, y=sy, w=1, h=1, laag="huizen", jit=0.0, kruis=False, aan=dict(grijs=False, half=True, kleur=True)))
    # inrichting per verdieping
    # keuken (begane grond): tegeltableau, fornuis met warme gloed, tafel met het logboek
    tegels = k.rect(wl + 120, lv[0] - 60, wl + 240, lv[0] - 18)
    k.paint(tegels, "huizen", "huis_wit", 5)
    k.paint(tegels & (((XX - wl) % 8 == 0) | ((YY - lv[0]) % 8 == 0)), "huizen", "huis_wit", 3)
    k.paint(tegels & ((XX + YY) % 8 == 3) & ((XX // 8 + YY // 8) % 2 == 0), "huizen", "dak", 4)   # blauwe tegeltjes
    fornuis = k.rect(wl + 150, lv[0] - 40, wl + 200, lv[0])
    k.paint(fornuis, "midden", "ijzer", 2)
    k.paint(k.rect(wl + 150, lv[0] - 40, wl + 200, lv[0] - 38), "midden", "ijzer", 4)
    vuur = k.rect(wl + 162, lv[0] - 24, wl + 188, lv[0] - 10)
    k.paint(vuur, "midden", "gloed", 3, emis=True)
    k.paint(vuur & (k.BAY < 0.5), "midden", "gloed", 5, emis=True)
    k.paint(k.rect(wl + 170, 0, wl + 180, lv[0] - 40) & (YY > lv[1] + 6), "midden", "ijzer", 2)     # kachelpijp
    k.lampen.append(dict(x=wl + 175, y=lv[0] - 18, r=0.9, aan=dict(grijs=True, half=True, kleur=True), links_van=wl))
    tafel_x = 3700 - rx
    k.paint(k.rect(tafel_x - 26, lv[0] - 20, tafel_x + 26, lv[0] - 17), "midden", "hout", 4)
    k.paint(k.rect(tafel_x - 24, lv[0] - 17, tafel_x - 21, lv[0]) | k.rect(tafel_x + 21, lv[0] - 17, tafel_x + 24, lv[0]), "midden", "hout", 2)
    k.paint(k.rect(tafel_x - 8, lv[0] - 23, tafel_x + 6, lv[0] - 20), "midden", "roest", 4)   # het logboek
    k.paint(k.rect(tafel_x - 8, lv[0] - 23, tafel_x + 6, lv[0] - 22), "midden", "huis_wit", 6)
    raam_buiten(k, wl + 300, lv[0] - 70, 28, 36, "huizen", 1)
    # wasruimte: waslijn met lakens, een tobbe
    raam_buiten(k, wl + 60, lv[1] - 70, 22, 30, "huizen", 2)
    lijn = (np.abs(YY - (lv[1] - 64 + 0.0012 * (XX - wl - 300) ** 2 * 0)) < 0.6) & (XX > wl + 140) & (XX < wl + 460)
    k.paint(lijn, "midden", "hout", 4)
    for (lx, lw_, lh_, mat) in [(wl + 160, 24, 26, "huis_wit"), (wl + 200, 18, 20, "huis_oker"), (wl + 240, 30, 30, "huis_wit"), (wl + 300, 20, 22, "huis_groen")]:
        laken = k.rect(lx, lv[1] - 64, lx + lw_, lv[1] - 64 + lh_)
        k.paint(laken, "midden", mat, 5)
        k.paint(laken & (XX == lx + lw_ - 1), "midden", mat, 3)
        k.paint(laken & (YY == lv[1] - 64 + lh_ - 1) & (XX % 3 == 0), "midden", mat, 3)
    k.stamp(D2.ton(12), wl + 410, lv[1] - 16, "midden")
    # werkplaats: de peilschaal van de sluiswachter (grote meetlat met waterstanden), tandwielen op een plank
    peil = k.rect(wl + 210, lv[2] - 76, wl + 222, lv[2] - 20)
    k.paint(peil, "huizen", "huis_wit", 6)
    for i, py in enumerate(range(lv[2] - 74, lv[2] - 20, 4)):
        k.paint(k.rect(wl + 210, py, wl + 214 + (4 if i % 5 == 0 else 0), py + 1), "huizen", "raamdonker", 1)
    k.paint(k.rect(wl + 222, lv[2] - 50, wl + 230, lv[2] - 49), "huizen", "roest", 5)   # het peil: hoog water
    k.paint(k.rect(wl + 280, lv[2] - 52, wl + 400, lv[2] - 49), "huizen", "hout", 4)    # plank
    for gx in (wl + 296, wl + 330, wl + 372):
        dr = np.hypot(XX - gx, YY - (lv[2] - 60))
        ang = np.arctan2(YY - (lv[2] - 60), XX - gx)
        tw = ((dr < 7) | ((dr < 9) & (np.sin(ang * 8) > 0))) & (dr > 2)
        k.paint(tw, "huizen", "koper", 4)
    raam_buiten(k, wl + 440, lv[2] - 70, 22, 30, "huizen", 3)
    # kaartenkamer: kaart van de wijk in een lijst, een bed onder het schuine plafond
    kaart = k.rect(wl + 150, lv[3] - 74, wl + 250, lv[3] - 28)
    k.paint(kaart, "huizen", "huis_oker", 6)
    k.paint(ndimage.binary_dilation(kaart, iterations=2) & ~kaart, "huizen", "hout", 2)
    gracht = kaart & (np.abs(YY - (lv[3] - 50 + 8 * np.sin((XX - wl) / 14))) < 2)
    k.paint(gracht, "huizen", "water", 4)
    k.paint(kaart & ((XX - wl - 150) % 12 < 8) & ((YY - lv[3] + 74) % 10 < 6) & ~gracht, "huizen", "huis_oker", 4)
    k.paint(k.rect(wl + 222, lv[3] - 58, wl + 226, lv[3] - 54), "huizen", "roest", 5)   # het gemaal op de kaart
    k.paint(k.rect(wl + 300, lv[3] - 22, wl + 380, lv[3] - 10), "midden", "huis_rood", 3)  # bed
    k.paint(k.rect(wl + 300, lv[3] - 22, wl + 380, lv[3] - 20), "midden", "huis_wit", 5)
    k.paint(k.rect(wl + 296, lv[3] - 34, wl + 300, lv[3]), "midden", "hout", 3)
    raam_buiten(k, wl + 60, lv[3] - 70, 22, 30, "huizen", 4)
    # balken onder elke richel (midden): zichtbaar aan de open kant
    for y in lv[1:]:
        k.paint(k.rect(wl, y + 6, wr, y + 10), "midden", "hout", 2)
        k.paint(k.rect(wl, y + 6, wr, y + 7), "midden", "hout", 3)
    # lampen per verdieping (aan na het oppompen)
    wu, wa = D2.wandlamp()
    for i, (lx, y) in enumerate([(wl + 4, lv[1] - 46), (wr - 20, lv[2] - 46), (wl + 4, lv[3] - 46)]):
        k.wissel.append(("midden", lx, y, wu, wa, dict(grijs=False, half=True, kleur=True)))
        k.lampen.append(dict(x=lx + 8, y=y + 14, r=0.85, aan=dict(grijs=False, half=True, kleur=True),
                             links_van=wl if lx < 300 else None))
    # --- speelvlak: buitenmuren (doorsnede), vloer, de hoek met de trap van S9
    wL = rect_of(k, blok("S5", "WandLinks"))
    k.tegels(lambda i, j, x, y: "baksteen_speklaag" if j % 6 == 3 else ("baksteen_m1" if (i + j) % 2 else "baksteen_m2"),
             0, 0, wl, int(blok("S5", "WandLinks")[4]), "speelvlak")
    k.paint(wL & (XX >= wl - 2), "speelvlak", "steen", 4)
    k.paint(wL & (XX == wl - 1), "speelvlak", "steen", 2)
    onder_wl = int(blok("S5", "WandLinks")[4])
    # de doorgang uit S4 onder de linkerwand: een gang met een plavuizen vloer en een deurkozijn
    gang = k.rect(0, onder_wl, wl, vl)
    k.paint(gang, "huizen", "huis_wit", 1)
    k.add(gang & (k.BAY < 0.15), "huizen", 1)
    k.paint(k.rect(0, vl - 14, wl, vl), "huizen", "hout", 1)
    k.paint(k.rect(wl - 6, onder_wl, wl - 2, vl), "huizen", "hout", 3)
    k.paint(k.rect(wl - 6, onder_wl, wl - 5, vl), "huizen", "hout", 5)
    k.paint(k.rect(0, onder_wl - 6, wl, onder_wl), "speelvlak", "steen", 4)            # latei van de doorgang uit S4
    k.paint(k.rect(0, onder_wl - 1, wl, onder_wl), "speelvlak", "steen", 2)
    for b in ("WandRechts", "WandRechts2"):
        _, x, y, bw, bh, _ = blok("S5", b)
        k.tegels(lambda i, j, xx_, yy_: "baksteen_speklaag" if j % 6 == 3 else ("baksteen_m1" if (i + j) % 2 else "baksteen_m2"),
                 int(x), int(y), int(x + bw), int(y + bh), "speelvlak")
    k.paint(k.rect(wr, lv[4], w, lv[4] + 2), "speelvlak", "steen", 6)                    # drempel naar de loopbrug van S6
    k.paint(k.rect(wr, lv[4] + 2, w, lv[4] + 5), "speelvlak", "steen", 3)
    k.paint(k.rect(wr, lv[4], wr + 2, h), "speelvlak", "steen", 2)
    # vloer van het huis (planken) en de fundering
    _, x, y, bw, bh, _ = blok("S5", "Vloer")
    plank_vloer(k, int(x), int(x + bw), int(y), "speelvlak")
    k.tegels(lambda i, j, xx_, yy_: "kelderbodem_m1" if (i + j) % 2 else "kelderbodem_m2", int(x), int(y) + 6, int(x + bw), h, "speelvlak", dt=-1)
    # de trap van S9 in de hoek (x 580..640, onder de wand): donker trappenhuis, treden van hardsteen
    hoek = k.rect(580, int(blok("S5", "WandRechts2")[2] + blok("S5", "WandRechts2")[4]), w, h)
    k.tegels(lambda i, j, xx_, yy_: "baksteen_donker_m1" if (i + j) % 2 else "baksteen_donker_m2", 580, int(hoek.nonzero()[0].min()), w, h, "midden", dt=-1)
    for b in blokken("S5"):
        if b[0].startswith("Trap9"):
            st = D2.ninepatch(D2.trede_stuk(), 32)
            k.stamp(st, int(b[1]), int(b[2]), "speelvlak")
    return k


# ------------------------------------------------------------------ S6 Gemaalplein
def gemaal_gebouw(k, x0, x1, top, grond):
    """Het gemaal: een bakstenen hal met trapgevel, boograam, speklagen en het rad aan de gevel."""
    YY, XX = k.YY, k.XX
    hal = k.rect(x0, top + 60, x1, grond)
    cx = (x0 + x1) // 2
    for s_ in range(5):
        hal |= k.rect(x0 + 20 + 22 * s_, top + 60 - 12 * (s_ + 1), x1 - 20 - 22 * s_, top + 60)
    k.paint(hal, "midden", "baksteen", 3)
    row = (YY - top) // 4
    k.add(hal & (((YY - top) % 4 == 0) | (((XX + (row % 2) * 4) % 8) == 0)) & (k.BAY < 0.7), "midden", -1)
    rand_b = hal & ~np.vstack([np.zeros((1, k.w), bool), hal[:-1]])
    k.paint(ndimage.binary_dilation(rand_b, structure=np.ones((3, 1))) & hal, "midden", "steen", 4)
    k.paint(rand_b, "midden", "steen", 6)
    for yy0 in (top + 120, top + 200, grond - 60):
        k.paint(k.rect(x0, yy0, x1, yy0 + 5) & hal, "midden", "steen", 4)
        k.paint(k.rect(x0, yy0, x1, yy0 + 1) & hal, "midden", "steen", 6)
    k.paint(hal & (XX < x0 + 4), "midden", "baksteen", 1)
    k.paint(hal & (XX >= x1 - 3), "midden", "baksteen", 4)
    # schoorsteen
    sch = k.rect(x1 - 70, top - 40, x1 - 54, top + 60)
    k.paint(sch, "midden", "baksteen", 2)
    k.paint(k.rect(x1 - 72, top - 44, x1 - 52, top - 38), "midden", "steen", 4)
    # twee boogramen met de machine erachter (aan/uit), opschrift-steen met jaartal (geen tekst: een cartouche)
    for bx in (cx + 20, cx + 150):                      # rechts van het rad (dat hangt op S6/Gemaal, links op de gevel)
        bu, ba = D1.boograam(False), D1.boograam(True)
        k.wissel.append(("midden", bx, top + 130, bu, ba, dict(grijs=False, half=True, kleur=True)))
    k.paint((np.hypot((XX - cx) / 22, (YY - (top + 84)) / 10) < 1), "midden", "steen", 5)
    k.paint((np.hypot((XX - cx) / 18, (YY - (top + 84)) / 7) < 1), "midden", "steen", 3)
    # het rad aan de gevel (statisch frame 0; de animatie is het prop `gemaal_rad`)
    return hal


def gemaal_rad(f, n=8, d=96):
    """Het grote rad van het gemaal, d x d, frame f van n (8 schoepen; per frame een schoep/8 verder)."""
    t = T(d, d)
    yy, xx = np.mgrid[0:d, 0:d]
    c = (d - 1) / 2
    dr = np.hypot(xx - c, yy - c)
    a = np.arctan2(yy - c, xx - c)
    rot = f * (2 * np.pi / 8) / n
    R_ = d / 2 - 10
    t.fill((dr >= R_ - 3) & (dr < R_), "ijzer", 4)
    t.fill((dr >= R_ - 3) & (dr < R_ - 2), "ijzer", 6)
    t.fill((dr >= R_ - 1) & (dr < R_), "ijzer", 2)
    for kk in range(8):
        ak = rot + kk * np.pi / 4
        da = np.angle(np.exp(1j * (a - ak)))
        t.fill((np.abs(da * dr) < 1.4) & (dr < R_ - 3) & (dr > 7), "ijzer", 4 if np.cos(ak + 0.8) > 0 else 3)
        sch = (np.abs(da * dr) < 3.5) & (dr >= R_) & (dr < d / 2)
        t.fill(sch, "hout", 4 if np.sin(ak) < 0 else 3)
        t.fill(sch & (dr >= d / 2 - 1.5), "hout", 6)
        t.fill(sch & (np.abs(da * dr) >= 2.5), "hout", 2)
    t.fill(dr < 8, "ijzer", 3)
    t.fill(dr < 4, "koper", 5)
    return t


def bouw_s6():
    rx, ry, w, h = room("S6")
    k = Kamer("s6_gemaalplein", rx, w, h, wy=ry)
    YY, XX = k.YY, k.XX
    plein = int(blok("S6", "Plein")[2])                  # 460
    sl, sr = int(blok("S6", "Plein")[3]), int(blok("S6", "WandRechts")[1])   # 840, 900
    D2.lucht_en_ver(k, 606, belfort=(860, 60), top_range=(210, 270))
    huis = D2.huizenrij(k, 100, 300, plein, 61, 250, 300, lit_p=0.7)
    # de kerk en daklijn hoger achter het gemaal: de hoge lucht van S6 is niet leeg
    kerk = k.rect(560, 120, 760, plein) | k.rect(620, 60, 700, 120) | k.rect(652, 20, 668, 60)
    k.paint(kerk, "ver", "ver", 2)
    k.paint(kerk & (XX < 564), "ver", "ver", 1)
    for wx_ in range(574, 750, 30):
        k.ramen.append(dict(x=wx_, y=140, w=8, h=24, laag="ver", jit=0.5, kruis=True, aan=dict(grijs=False, half=True, kleur=True)))
    hal = gemaal_gebouw(k, 300, 820, 200, plein)
    gx, gy = 4600 - rx, 140 - ry                         # S6/Gemaal: het middelpunt van het rad aan de gevel
    k.stamp(gemaal_rad(0), gx - 48, gy - 48, "midden")
    k.paint(k.rect(gx - 4, gy + 40, gx + 4, plein - 24), "midden", "ijzer", 2)        # drijfstang naar de pompgang
    # de pompgang: een ijzeren as en een goot van het gemaal langs de vier schoepen (de schoepen zijn objecten)
    as_y = plein - 38
    k.paint(k.rect(300, as_y - 2, 820, as_y + 2), "midden", "ijzer", 3)
    k.paint(k.rect(300, as_y - 2, 820, as_y - 1), "midden", "ijzer", 5)
    for vx in (4480, 4560, 4640, 4720):
        lx = vx - rx
        k.paint(k.rect(lx - 6, as_y - 6, lx + 6, as_y + 6), "midden", "ijzer", 2)     # lager
        k.paint(k.rect(lx - 3, as_y + 6, lx + 3, plein), "midden", "ijzer", 2)        # bok
        k.paint(k.rect(lx - 8, plein - 4, lx + 8, plein), "midden", "steen", 4)
    goot = k.rect(300, plein - 12, 840, plein)
    k.paint(goot, "midden", "steen", 3)
    k.paint(k.rect(300, plein - 12, 840, plein - 11), "midden", "steen", 5)
    k.paint(goot & (YY >= plein - 9) & (YY < plein - 5), "midden", "water", 3)
    # het water van het gemaal in de goot glanst warm als het gemaal aan is: via de laag `gemaal_aan`
    # --- loopbrug van de zolder (speelvlak, vast, eenrichting) met leuning en de trap (treden als consoles)
    _, bx_, by_, bw_, _, _ = blok("S6", "Loopbrug")
    k.stamp(D2.ninepatch(D2.galerij_stuk(), int(bw_)), int(bx_), int(by_), "speelvlak")
    for px in range(int(bx_) + 6, int(bx_ + bw_), 14):
        k.paint(k.rect(px, by_ - 14, px + 2, by_), "midden", "ijzer", 3)
    k.paint(k.rect(bx_, by_ - 15, bx_ + bw_, by_ - 13), "midden", "ijzer", 4)
    # trap: een ijzeren steiger tegen de huizen, met hardstenen treden
    tx0 = int(blok("S6", "Trap1")[1])
    k.paint(k.rect(tx0 - 2, by_ + 6, tx0, plein) | k.rect(tx0 + 40, by_ + 6, tx0 + 42, plein), "midden", "ijzer", 2)
    for b in blokken("S6"):
        if b[0].startswith("Trap"):
            k.stamp(D2.ninepatch(D2.trede_stuk(), int(b[3])), int(b[1]), int(b[2]), "speelvlak")
            k.paint((np.abs((XX - tx0) - (YY - b[2] - 6)) < 0.7) & (YY > b[2] + 6) & (YY < b[2] + 40) & (XX >= tx0) & (XX < tx0 + 40), "midden", "ijzer", 2)
    # --- plein (speelvlak): kasseien op 460, met een rand van hardsteen bij de sluis
    kas = [D2.kasseien(s) for s in (7, 8, 9)]
    k.tegels(lambda i, j, x, y: kas[i % 3] if j == 0 else ("kade_wand_hoog_m1" if j < 3 else
             ("kelderbodem_m1" if (i + j) % 2 else "kelderbodem_m2")), 0, plein, sl, h, "speelvlak")
    k.paint(k.rect(sl - 3, plein, sl, h), "speelvlak", "steen", 3)
    k.paint(k.rect(sl - 1, plein + 4, sl, h), "speelvlak", "steen", 1)
    # --- de rechterwand (speelvlak): de sluistoren van het gemaal, hardsteen met een ijzeren peilschaal
    k.tegels(lambda i, j, x, y: "kade_wand_hoog_m1" if (i + j) % 2 else "kade_wand_hoog_m2", sr, 0, w, h, "speelvlak")
    tw = k.rect(sr, 0, w, h)
    k.paint(tw & (XX == sr), "speelvlak", "steen", 2)
    k.paint(tw & (XX == sr + 1), "speelvlak", "steen", 5)
    for py in range(120, plein, 8):
        k.paint(k.rect(sr + 10, py, sr + 14 + (4 if py % 40 == 0 else 0), py + 1), "speelvlak", "huis_wit", 6)
    k.paint(k.rect(sr + 8, 120, sr + 9, plein), "speelvlak", "ijzer", 4)
    # --- de schacht onder de sluis (midden): baksteen en het water van de kelderingang
    k.tegels(lambda i, j, x, y: "baksteen_donker_m1" if (i + j) % 2 else "baksteen_donker_m2", sl, plein, sr, h, "midden", dt=-1)
    k.paint(k.rect(sl, plein + 14, sr, h), "midden", "water", 2)
    k.paint(k.rect(sl, plein + 14, sr, plein + 15), "midden", "water", 5)
    # --- lampen: grijs geen; het gemaal gaat aan bij trap 1 (extra laag), kleur alles
    su, sa = D2.straatlamp()
    for lx in (160, 860 - 40):
        k.wissel.append(("midden", lx - 8, plein - 48, su, sa, dict(grijs=False, half=True, kleur=True)))
        k.lampen.append(dict(x=lx, y=plein - 40, r=1.0, aan=dict(grijs=False, half=True, kleur=True)))
    k.lampen.append(dict(x=gx, y=gy + 80, r=1.6, aan=dict(grijs=False, half=True, kleur=True), halo=False))
    k.paint(k.rect(0, plein - 2, 60, plein) & (k.BAY < 0.3), "huizen", "steen", 2)
    return k


def gemaal_aan_laag(k):
    """Trap 1 (s = 1): de wijk is nog grijs, maar het gemaal is aan. Een RGBA-laag boven `midden`
    met de boogramen warm, de poel rond het gemaal in kleur (licht = kleur) en het water in de goot."""
    lagen_g = k.render("grijs")
    # het gemaal aan in grijs: dezelfde render met alleen de gemaal-lampen en -ramen aan
    bewaar = [dict(l) for l in k.lampen]
    wis = list(k.wissel)
    try:
        for lp in k.lampen:
            if lp.get("halo") is False:
                lp["aan"] = dict(grijs=True, half=True, kleur=True)
        k.wissel = [(a, b, c, d_, e, (dict(grijs=True, half=True, kleur=True) if a == "midden" and d_.mat.shape == (48, 32) else f))
                    for (a, b, c, d_, e, f) in wis]
        lagen_a = k.render("grijs")
    finally:
        k.lampen = bewaar
        k.wissel = wis
    out = np.zeros((k.h, k.w, 4))
    for ln in ["ver", "huizen", "midden", "speelvlak"]:
        g, a = lagen_g[ln], lagen_a[ln]
        diff = (np.abs(g[..., :3] - a[..., :3]).sum(-1) > 1e-6) & (a[..., 3] > 0)
        out[diff] = a[diff]
    lucht_diff = np.abs(lagen_g["lucht"][..., :3] - lagen_a["lucht"][..., :3]).sum(-1) > 1e-6
    out[lucht_diff & (out[..., 3] == 0)] = lagen_a["lucht"][lucht_diff & (out[..., 3] == 0)]
    return out


# ------------------------------------------------------------------ S7 Sluiskelder
def bouw_s7():
    rx, ry, w, h = room("S7")
    k = Kamer("s7_sluiskelder", rx, w, h, wy=ry)
    YY, XX = k.YY, k.XX
    kwl, kwr = blok("S7", "KelderWandLinks"), blok("S7", "KelderWandRechts")
    bv, bv2 = blok("S7", "Bovenvloer"), blok("S7", "Bovenvloer2")
    vw, vo = blok("S7", "VloerWest"), blok("S7", "VloerOost")
    kb, kt = blok("S7", "KanaalBodem"), blok("S7", "KanaalTrede")
    wr = blok("S7", "WandRechts")
    low = int(vw[2])                                        # 260
    # --- achter: de gewelven van de kelder (geen lucht), baksteen, donker
    k.paint(np.ones((h, w), bool), "lucht", "baksteen", 1)
    k.tegels(lambda i, j, x, y: "baksteen_donker_m1" if (i + j) % 2 else "baksteen_donker_m2", 0, 0, w, h, "lucht", dt=-1)
    # tongewelven over de hal: bogen met pijlers (midden), het kanaal eronder
    for i, cx in enumerate(range(80, w, 160)):
        pijl = k.rect(cx - 10, 40, cx + 10, low)
        if not (int(kb[1]) - 10 < cx < int(kb[1] + kb[3]) + 10):
            k.paint(pijl, "huizen", "steen", 3)
            k.paint(pijl & (XX == cx - 10), "huizen", "steen", 1)
            k.paint(pijl & (XX == cx + 9), "huizen", "steen", 5)
            k.paint(k.rect(cx - 14, 40, cx + 14, 46), "huizen", "steen", 4)
        boog = (np.hypot((XX - (cx + 80)) / 72.0, (YY - 120) / 80.0) < 1.12) & (np.hypot((XX - (cx + 80)) / 72.0, (YY - 120) / 80.0) >= 1.0) & (YY < 120)
        k.paint(boog, "huizen", "steen", 2)
        k.paint(boog & (np.abs(np.sin(np.arctan2(YY - 120, XX - cx - 80) * 16)) < 0.15), "huizen", "steen", 0)
    # buizen langs de wand naar de machinehal (west)
    for py, mt in [(150, "koper"), (162, "ijzer")]:
        k.paint(k.rect(0, py, w, py + 6), "huizen", mt, 3)
        k.paint(k.rect(0, py, w, py + 1), "huizen", mt, 5)
        for fx in range(20, w, 90):
            k.paint(k.rect(fx, py - 1, fx + 4, py + 7), "huizen", mt, 2)
    # de deur naar de machinehal (links): een rondboog, donker, met een rode gloed? Nee: rood is van vijanden.
    deur = D2.R_arch(k, 4, 44, low - 70, low)
    k.paint(ndimage.binary_dilation(deur, iterations=3) & ~deur, "huizen", "steen", 4)
    k.paint(deur, "huizen", "raamdonker", 0)
    # --- de kelder (de zak): een lager gewelf, kisten, de schacht van de kelderingang
    zak = k.rect(int(kwl[1]) + 20, 0, int(kwr[1]), int(bv[2]))
    k.tegels(lambda i, j, x, y: "baksteen_m1" if (i + j) % 2 else "baksteen_m2", int(kwl[1]) + 20, 0, int(kwr[1]), int(bv[2]), "huizen", dt=-1)
    gw = zak & (np.hypot((XX - (kwl[1] + kwr[1] + 20) / 2) / 200.0, (YY - 60) / 70.0) >= 1.0) & (YY < 60)
    k.paint(gw, "huizen", "steen", 2)
    # schacht van de kelderingang (x 5000..5060 → 200..260): licht valt erin (koud in grijs)
    sx0, sx1 = 5000 - rx, 5060 - rx
    k.paint(k.rect(sx0, 0, sx1, 12), "huizen", "raamdonker", 1)
    k.paint(k.rect(sx0 - 2, 0, sx0, 14) | k.rect(sx1, 0, sx1 + 2, 14), "huizen", "steen", 4)
    bundel = k.rect(sx0 + 4, 12, sx1 - 4, int(bv[2])) & (k.BAY < 0.18 + 0.12 * (1 - YY / 80))
    k.paint(bundel, "midden", "steen", 5)
    for (cx_, cy_) in [(kwl[1] + 40, bv[2] - 14), (kwl[1] + 58, bv[2] - 10)]:
        k.paint(k.rect(cx_, cy_, cx_ + 16, bv[2]), "midden", "hout", 2)
        k.paint(k.rect(cx_, cy_, cx_ + 16, cy_ + 1), "midden", "hout", 4)
    # de sokkel (V-01) is een object; hier alleen zijn warme gloed in grijs (kleurscript S7)
    sok = (5150 - rx, 440 - ry)
    k.lampen.append(dict(x=sok[0], y=sok[1] - 14, r=0.8, aan=dict(grijs=True, half=True, kleur=True), halo=False,
                         links_van=int(kwl[1]) + 20, boven_y=None))
    # het metselwerk tussen de kelder en de hal (midden, niet bereikbaar)
    tussen = k.rect(int(kwl[1]), int(bv[2]) + 16, int(kwr[1]) + 20, int(bv[2]) + 40)
    k.tegels(lambda i, j, x, y: "baksteen_donker_m1" if (i + j) % 2 else "baksteen_donker_m2", int(kwl[1]), int(bv[2]) + 16, int(kwr[1]) + 20, int(bv[2]) + 40, "midden")
    k.add(tussen & (YY > bv[2] + 30), "midden", -1)
    # --- speelvlak: kelderwanden, bovenvloeren (het luik is een object: de opening blijft leeg)
    for b in (kwl, kwr):
        k.tegels(lambda i, j, x, y: "kade_wand_hoog_m1" if (i + j) % 2 else "kade_wand_hoog_m2", int(b[1]), int(b[2]), int(b[1] + b[3]), int(b[2] + b[4]), "speelvlak")
    for b in (bv, bv2):
        k.tegels(lambda i, j, x, y: ("kade_boven_m1" if i % 2 else "kade_boven_m2"), int(b[1]), int(b[2]), int(b[1] + b[3]), int(b[2] + b[4]), "speelvlak")
    k.paint(k.rect(bv[1] + bv[3] - 2, bv[2], bv[1] + bv[3], bv[2] + 16), "speelvlak", "steen", 2)   # sponning van het luik
    k.paint(k.rect(bv2[1], bv2[2], bv2[1] + 2, bv2[2] + 16), "speelvlak", "steen", 2)
    # benedenvloeren
    for b in (vw, vo):
        k.tegels(lambda i, j, x, y: ("kade_boven_m1" if i % 2 else "kade_boven_m2") if j == 0 else
                 ("kelderbodem_m1" if (i + j) % 2 else "kelderbodem_m2"), int(b[1]), int(b[2]), int(b[1] + b[3]), h, "speelvlak")
    k.tegels(lambda i, j, x, y: "kade_getij_m1" if i % 2 else "kade_getij_m2", 0, low + 30, int(vw[3]), low + 46, "speelvlak")
    k.tegels(lambda i, j, x, y: "kade_getij_m1" if i % 2 else "kade_getij_m2", int(vo[1]), low + 30, int(wr[1]), low + 46, "speelvlak")
    # kanaal: bodem en trede (speelvlak), water als beeld (midden), kademuren
    k.tegels(lambda i, j, x, y: "kelderbodem_m1" if (i + j) % 2 else "kelderbodem_m2", int(kb[1]), int(kb[2]), int(kb[1] + kb[3]), h, "speelvlak")
    k.paint(k.rect(kb[1], kb[2], kb[1] + kb[3], kb[2] + 1), "speelvlak", "steen", 5)
    k.tegels(lambda i, j, x, y: "trap_vul" if j else "kade_boven_m1", int(kt[1]), int(kt[2]), int(kt[1] + kt[3]), int(kt[2] + kt[4]), "speelvlak")
    kan = k.rect(kb[1], low, kb[1] + kb[3], kb[2])
    k.tegels(lambda i, j, x, y: "kade_wand_laag_m1" if (i + j) % 2 else "kade_wand_laag_m2", int(kb[1]), low, int(kb[1] + kb[3]), int(kb[2]), "midden", dt=-1)
    wat = kan & (YY >= kb[2] - 14)
    k.paint(wat, "midden", "water", 2)
    k.paint(wat & (YY == kb[2] - 14), "midden", "water", 5)
    k.paint(wat & (YY == kb[2] - 14) & ((XX // 4) % 3 == 0), "midden", "water", 7)
    # rechterwand
    k.tegels(lambda i, j, x, y: "kade_wand_hoog_m1" if (i + j) % 2 else "kade_wand_hoog_m2", int(wr[1]), 0, w, h, "speelvlak")
    k.paint(k.rect(wr[1], 0, wr[1] + 1, h), "speelvlak", "steen", 5)
    # lampen: alleen in kleur, aan de pijlers
    wu, wa = D2.wandlamp()
    for lx in (238, 558, 878):
        if lx < wr[1] - 20:
            k.wissel.append(("huizen", lx, 120, wu, wa, dict(grijs=False, half=True, kleur=True)))
            k.lampen.append(dict(x=lx + 8, y=134, r=1.0, aan=dict(grijs=False, half=True, kleur=True)))
    k.lucht_bundels = None
    return k


# ------------------------------------------------------------------ objecten
def luik(fase):
    """Het breekbare luik (V-01, L-03), 40 x 16: dicht met een scheur (0), breuk (1, 2), open (3)."""
    t = T(40, 16)
    yy, xx = np.mgrid[0:16, 0:40]
    if fase < 3:
        t.box(0, 0, 40, 16, "hout", 3)
        t.fill(xx % 8 == 7, "hout", 2)
        t.fill((yy == 4) & (xx % 8 == 3), "hout", 4)
        t.box(0, 0, 40, 1, "steen", 7)                  # sponning: het loopvlak leest
        t.box(0, 1, 40, 2, "hout", 6)
        t.box(0, 13, 40, 16, "ijzer", 3)
        t.box(0, 0, 2, 16, "ijzer", 4)
        t.box(38, 0, 40, 16, "ijzer", 4)
        t.fill((yy == 8) & ((xx == 1) | (xx == 38)), "ijzer", 6)
        zig = 19 + np.round(3 * np.sin(yy * 1.2)).astype(int)
        scheur = (np.abs(xx - zig) == 0) & (yy >= 1) & (yy <= 13)
        t.fill(scheur, "raamdonker", 0)
        t.fill((np.abs(xx - zig) == 1) & (yy >= 2) & (yy <= 12), "hout", 6)      # vers breukvlak (L-03)
        if fase >= 1:
            gat = (np.abs(xx - 19.5) < (5 if fase == 1 else 13) + np.round(1.5 * np.sin(yy * 2.1))) & (yy >= 1) & (yy <= 13)
            t.mat[gat] = -1
            rand = ndimage.binary_dilation(gat) & ~gat & (t.mat >= 0)
            t.fill(rand, "hout", 6)
            if fase == 2:                                # splinters vallen
                for (sx, sy) in [(12, 15), (27, 15), (20, 15)]:
                    t.box(sx, sy - 1, sx + 2, sy + 1, "hout", 5)
    else:
        t.box(0, 0, 4, 16, "hout", 3)                     # alleen de randen blijven, met splinters
        t.box(36, 0, 40, 16, "hout", 3)
        t.box(0, 0, 4, 1, "steen", 7)
        t.box(36, 0, 40, 1, "steen", 7)
        t.box(0, 13, 40, 16, "ijzer", 3)
        t.fill((xx >= 4) & (xx < 7) & (yy < 9) & (yy % 3 != 2), "hout", 6)
        t.fill((xx >= 33) & (xx < 36) & (yy < 7) & (yy % 3 != 1), "hout", 6)
        t.box(0, 0, 2, 16, "ijzer", 4)
        t.box(38, 0, 40, 16, "ijzer", 4)
    return t


def pompschoep(fase):
    """Een schoep van de pompgang (hurtbox 32 x 48): een houten blad aan een ijzeren arm.
    fase 0 = rust, 1–4 = slag (het blad zwaait door, en terug). P1 én de echo gebruiken dezelfde frames:
    de pompslag van de echo moet even zwaar ogen als die van P1 (CD, #227)."""
    t = T(32, 48)
    yy, xx = np.mgrid[0:48, 0:32]
    hoek = [0.0, 0.3, 0.5, 0.35, 0.12][fase]          # binnen de cel van 32 x 48
    cx, cy = 16, 40                                       # as onderaan, bij de goot
    dx, dy = np.sin(hoek), -np.cos(hoek)
    s_ = (xx - cx) * dx + (yy - cy) * dy                   # langs de arm
    n_ = (xx - cx) * -dy + (yy - cy) * dx                  # dwars
    arm = (s_ > 0) & (s_ < 38) & (np.abs(n_) < 1.5)
    blad = (s_ > 16) & (s_ < 38) & (np.abs(n_) < 7)
    t.fill(blad, "hout", 4)
    t.fill(blad & (np.abs(n_) > 5.5), "hout", 2)
    t.fill(blad & ((s_.astype(int) % 7) == 0), "hout", 3)
    t.fill(blad & (s_ > 36), "hout", 6)
    t.fill(arm, "ijzer", 4)
    t.fill(arm & (n_ < -0.5), "ijzer", 6)
    t.fill(np.hypot(xx - cx, yy - cy) < 4, "ijzer", 3)
    t.fill(np.hypot(xx - cx, yy - cy) < 2, "koper", 5)
    t.box(8, 44, 24, 48, "steen", 4)
    t.box(8, 44, 24, 45, "steen", 6)
    return t


def pompslag(fase):
    """Het effect van een pompslag, 48 x 48, 5 frames: een warme ring van licht dat in het gemaal stroomt.
    Voor P1 en de echo gelijk: zelfde frames, 100 % dekkend, geen nagalm-transparantie (CD, #227)."""
    t = T(48, 48)
    yy, xx = np.mgrid[0:48, 0:48]
    dr = np.hypot(xx - 23.5, yy - 23.5)
    ang = np.arctan2(yy - 23.5, xx - 23.5)
    r_ = [6, 11, 16, 20, 23][fase]
    dik = [4, 3, 3, 2, 1][fase]
    ring = (dr >= r_ - dik) & (dr < r_)
    t.fill(ring, "gloed", [7, 6, 5, 4, 3][fase])
    if fase < 4:
        t.fill(ring & (np.abs(np.sin(ang * 4)) < 0.25), "gloed", 7)
    if fase <= 1:
        t.fill(dr < [5, 3][fase], "gloed", 7)
    stralen = (np.abs(np.sin(ang * 4 + 0.4)) < 0.08) & (dr > r_) & (dr < r_ + [6, 8, 6, 3, 0][fase])
    t.fill(stralen, "gloed", 6)
    if fase >= 2:                                         # vonken die naar de as (onder) stromen
        for i in range(6):
            a = np.pi / 2 + (i - 2.5) * 0.35
            px, py = int(23.5 + np.cos(a) * (r_ + 2)), int(23.5 + np.sin(a) * (r_ + 2))
            if 0 <= px < 48 and 0 <= py < 48:
                t.box(px, py, px + 1, py + 2, "gloed", 6)
    return t


def sluisklep(open_):
    """De sluis boven de kelderingang (S6, 60 x 10, in een cel van 64 x 16): dicht of open (opgeklapt)."""
    t = T(64, 16)
    if not open_:
        t.box(2, 0, 62, 10, "hout", 3)
        t.fill(np.mgrid[0:16, 0:64][1] % 10 == 1, "hout", 2)
        t.box(2, 0, 62, 1, "steen", 7)
        t.box(2, 1, 62, 2, "hout", 5)
        t.box(2, 4, 62, 6, "roest", 3)
        t.box(2, 9, 62, 10, "ijzer", 2)
        t.box(2, 0, 4, 10, "ijzer", 4)
        t.box(60, 0, 62, 10, "ijzer", 4)
    else:
        t.box(2, 0, 6, 16, "hout", 3)                    # opgeklapt tegen de linkerkant
        t.box(2, 0, 3, 16, "hout", 5)
        t.box(6, 0, 8, 16, "roest", 3)
        t.box(58, 0, 62, 10, "ijzer", 2)
    return t


def sokkel(aan):
    """De sokkel van de neerslag (V-01), 32 x 32: hardsteen met een koperen schaal; aan = warme gloed."""
    t = T(32, 32)
    yy, xx = np.mgrid[0:32, 0:32]
    t.box(6, 18, 26, 32, "steen", 3)
    t.box(4, 28, 28, 32, "steen", 2)
    t.box(6, 18, 26, 19, "steen", 5)
    t.box(8, 14, 24, 18, "steen", 4)
    t.box(8, 14, 24, 15, "steen", 6)
    schaal = (np.hypot((xx - 15.5) / 9, (yy - 12) / 3.5) < 1) & (yy >= 10)
    t.fill(schaal, "koper", 4)
    t.fill(schaal & (yy == 10), "koper", 6)
    if aan:
        t.fill((np.hypot(xx - 15.5, yy - 8) < 4) & (yy < 11), "gloed", 6)
        t.fill((np.hypot(xx - 15.5, yy - 8) < 2), "gloed", 7)
    else:
        t.fill((np.hypot(xx - 15.5, yy - 9) < 3) & (yy < 11), "raamdonker", 2)
    return t


OBJ_RIJEN = [
    # (naam, frames, cel_w, cel_h)
    ("schaduwklep", [D3.schaduwklep(f) for f in range(3)], 40, 16),
    ("luik", [luik(f) for f in range(4)], 40, 16),
    ("pompschoep", [pompschoep(f) for f in range(5)], 32, 48),
    ("pompslag", [pompslag(f) for f in range(5)], 48, 48),
    ("sluisklep", [sluisklep(False), sluisklep(True)], 64, 16),
    ("sokkel", [sokkel(False), sokkel(True)], 32, 32),
    ("gemaal_rad", [gemaal_rad(f) for f in range(8)], 96, 96),
]


def objecten_export(manifest):
    W_ = max(len(fr) * cw for _, fr, cw, _ in OBJ_RIJEN)
    H_ = sum(ch for _, _, _, ch in OBJ_RIJEN)
    items, meta, y = [], {}, 0
    for naam, frames, cw, ch in OBJ_RIJEN:
        rects = []
        for i, fr in enumerate(frames):
            items.append((i * cw, y, fr))
            fh, fw = fr.mat.shape
            rects.append([i * cw, y, fw, fh])
        meta[naam] = rects
        y += ch
    for staat in STATEN:
        D2.save(D1.render_items(items, W_, H_, staat), os.path.join(UIT_GAME, f"kadewijk_objecten_{staat}.png"))
    D1.index_atlas(items, W_, H_).save(os.path.join(UIT_GAME, "kadewijk_objecten_index.png"))
    manifest["objecten"] = dict(
        atlas={s: f"kadewijk_objecten_{s}.png" for s in STATEN + ["index"]},
        schaduwklep=dict(frames=meta["schaduwklep"], fps=12, z_index=-9,
                         plaatsing="Sprite2D op de rechthoek van het luik (40 x 16), linksboven; frame 0 zolang de schaduwklep op laag 5 "
                                   "staat; bij `schaduwklep_weg` frame 1 en 2, dan weg. Hol (rand + arcering), zoals de echo"),
        luik=dict(frames=meta["luik"], fps=15, z_index=-9,
                  plaatsing="Luik (scripts/objects/luik.gd), 40 x 16, linksboven op de rechthoek: frame 0 dicht (met scheur, L-03), "
                            "bij `opened` frame 1–2, daarna frame 3 (open, ook na laden met `verslagen`). S7 en S9"),
        pompschoep=dict(frames=meta["pompschoep"], fps=20, z_index=-5,
                        plaatsing="Pomprad (scripts/light/pomprad.gd), hurtbox 32 x 48 gecentreerd: frame 0 rust, bij een treffer "
                                  "1–4 en terug naar 0. **P1 en de echo gebruiken dezelfde frames en dezelfde timing** (CD #227)"),
        pompslag=dict(frames=meta["pompslag"], fps=20, z_index=5,
                      plaatsing="Effect op het midden van de schoep bij elke pompslag, 100 % dekkend, ook voor de echo "
                                "(geen transparantie, geen kleinere versie): de echo is een tweede lichaam, geen nagalm"),
        sluisklep=dict(frames=meta["sluisklep"], z_index=-9, plaatsing="S6/Sluis (60 x 10), linksboven op (5000, 260) met 2 px marge in de cel: frame 0 dicht, 1 open (t_v)"),
        sokkel=dict(frames=meta["sokkel"], z_index=-15, plaatsing="De sokkel van V-01 in S7, onderkant op de bovenvloer bij x 5150: 0 uit, 1 aan (warme gloed)"),
        gemaal_rad=dict(frames=meta["gemaal_rad"], fps=10, z_index=-19,
                        plaatsing="S6, middelpunt op S6/Gemaal (4600, 140): staat stil (frame 0) tot de eerste pompslag, draait als het gemaal pompt"),
    )
    return items, W_, H_


# ------------------------------------------------------------------ figuren (renders)
def figuren(id_, staat):
    kleur, donker = staat == "kleur", staat != "kleur"
    rx, ry, _, _ = room(id_)

    def f(img):
        if id_ == "S5":
            return D2.plak_fig(img, [("echo", SP.P1_RUN[1], 3990 - rx, 170 - ry, False, kleur),
                                     ("p1", SP.P1_JUMP, 4030 - rx, 110 - ry, True, True)], 0)
        if id_ == "S6":
            img = D2.plak_fig(img, [("echo", SP.P1_RUN[2], 4520 - rx, 260 - ry, False, kleur),
                                    ("p1", SP.P1_RUN[0], 4600 - rx, 260 - ry, False, True)], 0)
            # de schoepen (objecten) in de render: de tweede wordt net door P1 geslagen, de eerste door de echo
            for i, vx in enumerate((4480, 4560, 4640, 4720)):
                fase = {0: 2, 1: 2}.get(i, 0)
                lay = pompschoep(fase).render("kleur" if kleur else "grijs")
                D1.stamp_rgba(img, lay, vx - rx - 16, 222 - ry - 24)
            for vx in (4480, 4560):                          # de pompslag: even zwaar voor de echo en P1
                D1.stamp_rgba(img, pompslag(1).render("kleur"), vx - rx - 24, 214 - ry - 24)
            return img
        if id_ == "S7":
            img = D2.plak_fig(img, [("echo", SP.P1_JUMP, 5282 - rx, 440 - ry, False, kleur),
                                    ("p1", SP.P1_JUMP, 5040 - rx, 560 - ry, True, True)], 0)
            D1.stamp_rgba(img, luik(3).render("kleur" if kleur else "grijs"), 5260 - rx, 440 - ry)
            D1.stamp_rgba(img, D3.schaduwklep(0).render("kleur" if kleur else "grijs"), 5260 - rx, 440 - ry)
            D1.stamp_rgba(img, sokkel(True).render("kleur"), 5150 - rx - 16, 440 - ry - 32)
            for wx in (5013, 5067):
                body, kern, ogen, extra = D1.dwaallicht("idle")
                lay = D1.vijand_render(body, kern, ogen, extra, staat="kleur", donker=donker)
                D1.stamp_rgba(img, lay, int(wx - rx - lay.shape[1] // 2), 620 - 40 - ry - lay.shape[0])
            return img
        return img
    return f


def met_stukken(k, id_, staat="grijs", golf=None, d=D):
    """Render met de eenrichtingsstukken per D (S5) zoals de TA ze plaatst."""
    L = D2.LI["speelvlak"]
    bm, bt = k.mat[L].copy(), k.t[L].copy()
    try:
        if id_ == "S5":
            for (naam, x, y, w, h, e) in blokken(id_, d):
                soort = S5_STUKKEN.get(naam)
                if soort:
                    k.stamp(D2.ninepatch(D2.EENRICHTING[soort], int(w)), int(x), int(y), "speelvlak")
        return k.render(staat, golf)
    finally:
        k.mat[L], k.t[L] = bm, bt


def controle_blokken(id_, d=D):
    return [(x, y, w, h, e) for (n, x, y, w, h, e) in blokken(id_, d) if y + h > 0]


def main():
    if "--snel" not in sys.argv:
        D3.main()
    with open(os.path.join(UIT_GAME, "kadewijk_kamers.json")) as f:
        manifest = json.load(f)
    print("Slice-art deel 4: S5, S6, S7 (D = 60), objecten")
    kamers = {"S5": bouw_s5(), "S6": bouw_s6(), "S7": bouw_s7()}
    for k in kamers.values():
        D2.export_kamer(k, manifest)
    # S6: de extra laag voor trap 1 (gemaal aan, wijk grijs)
    ga = gemaal_aan_laag(kamers["S6"])
    D2.save(ga, os.path.join(UIT_GAME, "s6_gemaalplein_gemaal_aan_grijs.png"))
    manifest["kamers"]["s6_gemaalplein"]["extra"] = dict(
        gemaal_aan=dict(bestand="s6_gemaalplein_gemaal_aan_grijs.png", z_index=-15,
                        wanneer="zichtbaar als het gemaal vol is (GEMAAL_VOL, trap 1) en s < 2; uit bij s = 2 (dan staat alles in `kleur`)"))
    manifest["eenrichting"]["blokken"].update({f"S5/{n}": s for n, s in S5_STUKKEN.items()})
    objecten_export(manifest)
    manifest["versie"] = "0.4"
    manifest["gemaal_werkaanname"] = list(D2.GEMAAL_WERELD)
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
            vlakken = [(x, y, w) for (x, y, w, h, e) in controle_blokken(id_) if y > 2 and w >= 8]
            metingen[(k.naam, staat)] = dict(chroma=D2.chroma(zonder), loopvlak=D2.loopvlak_contrast(zonder, vlakken))
        if id_ == "S6":                                    # trap 1: grijs met het gemaal aan
            g1 = figuren(id_, "grijs")(D2.over(r_["grijs"][0], ga))
            D2.save(g1, os.path.join(UIT_DOCS, f"{k.naam}_trap1_{k.w}x{k.h}.png"))
            metingen[(k.naam, "trap 1")] = dict(chroma=D2.chroma(D2.over(r_["grijs"][0], ga)), loopvlak=[])
            vb = np.concatenate([D2.label_bar(k.w, "GRIJS", "S = 0"), r_["grijs"][1],
                                 D2.label_bar(k.w, "TRAP 1", "GEMAAL AAN, WIJK NOG GRIJS"), g1,
                                 D2.label_bar(k.w, "KLEUR", "S = 2"), r_["kleur"][1]], 0)
        else:
            vb = np.concatenate([D2.label_bar(k.w, "GRIJS", "S = 0 / 1"), r_["grijs"][1],
                                 D2.label_bar(k.w, "KLEUR", "S = 2, NA TRAP 2"), r_["kleur"][1]], 0)
        D2.save(vb, os.path.join(UIT_DOCS, f"{k.naam}_vergelijking_x2.png"), 2)
        D2.save(D2.geometrie_controle(r_["grijs"][0], k, controle_blokken(id_)), os.path.join(UIT_DOCS, f"{k.naam}_geometrie_controle_x2.png"))
        if id_ == "S5":
            img = k.samengesteld(met_stukken(k, id_, "grijs", d=120))
            D2.save(D2.geometrie_controle(img, k, controle_blokken(id_, 120)), os.path.join(UIT_DOCS, f"{k.naam}_geometrie_controle_d120_x2.png"))
        # lichtovergang: de golf begint hier (S6) of vlak bij het gemaal
        v, lag = 300.0, 0.4
        gx, gy = D2.GEMAAL_WERELD[0] - k.wx, D2.GEMAAL_WERELD[1] - k.wy
        hoeken = [np.hypot(gx - cx, gy - cy) for cx in (0, k.w) for cy in (0, k.h)]
        t0 = max(0.0, (min(hoeken) if not (0 <= gx < k.w and 0 <= gy < k.h) else 0.0) / v - 0.1)
        t1 = max(hoeken) / v + lag + 0.15
        strip = []
        for tt in np.linspace(t0, t1, 5):
            img = k.samengesteld(met_stukken(k, id_, "grijs", golf=(v * tt, v * (tt - lag))))
            if k.w > 640:
                img = img[:, 160:800]
            strip += [D2.label_bar(img.shape[1], f"T = {tt:.1f} S NA GEMAAL_VOL", "HALF-VOORKANT %d PX" % int(v * tt)), img]
        D2.save(np.concatenate(strip, 0), os.path.join(UIT_DOCS, f"{k.naam}_lichtovergang_strip.png"))

    # objecten ×4 (grijs en kleur)
    items, W_, H_ = objecten_export(manifest)
    ov = []
    for staat in ["grijs", "kleur"]:
        a = D1.render_items(items, W_, H_, staat)
        bg = np.zeros((H_, W_, 3)) + D1.BG
        ov += [D2.label_bar(W_, f"OBJECTEN {staat.upper()}", "SCHADUWKLEP, LUIK, POMPSCHOEP, POMPSLAG, SLUISKLEP, SOKKEL, RAD"), D2.over(bg, a)]
    D2.save(np.concatenate(ov, 0), os.path.join(UIT_DOCS, "kadewijk_objecten_x3.png"), 3)

    print("  metingen deel 4 (chroma; ΔL* loopvlakken):")
    for (naam, staat), m in metingen.items():
        print(f"    {naam:22s} {staat:6s} chroma {m['chroma']:5.1f}   loopvlak ΔL* " + " ".join(f"{x:4.1f}" for x in m["loopvlak"]))


if __name__ == "__main__":
    main()
