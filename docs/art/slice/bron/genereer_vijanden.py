"""De drie vijandtypes van de slice op eindkwaliteit: sprites en animaties (Animator, #272, assetlijst S-13).

Maakt in `game/art/animatie/<type>/`:
  - kadeloper    (cel 56 x 40): staan, lopen, haakslag (aanloop 4 stappen + uithaal, slag, herstel), stil na
                 een treffer, dood (lost op in donker water), uit de stoom stappen (adds van de Gemaalmeester);
  - schotdrager  (cel 56 x 40): idem met het roestschot en de schotstoot, tink, schot breekt en valt, het stuk op
                 de grond, en de gebroken Schotdrager (stoot met het stuk dat hij overhoudt);
  - dwaallicht   (cel 32 x 48): zweven, aanloop (de kern zwelt), duik, terug, stil (flakkert), dood;
  - tell-vlakken op het aanvalsvlak (haak 20 x 16, stoot 24 x 16, duik 16 x 16 op de landingsplek) en de
                 gestippelde duiklijn;
  elk in grijs, half en kleur, plus een index-atlas voor de palet-LUT, en per type een manifest `<type>.json`
  (frames, ticks per frame, plaatsing ten opzichte van de vijand-node).
En in `docs/art/slice/eindkwaliteit/`: overzichtsbladen, de vijanden op hun plek in de kamers (grijs en kleur),
leesbaarheid (luminantie, deuteranopie) en een GIF.

Maten uit de code en de data (gelezen, niet overgetikt): `game/data/vijanden/slice.csv` (hurtboxes, vlakken,
tijden) en `game/scripts/combat/slice_enemy.gd` (de node staat in het midden van de hurtbox; het vlak van een
loper ligt vóór hem, `vlak_onder` boven zijn vloer; het Dwaallicht duikt tot `duik_hoogte` boven de vloer).
Plekken in de kamers uit combat §2.6 (scène-x) en `kadewijk_blokken.json` (D = 60).

Eigen werk (docs/licenties.md §2): palet, helpers en kamers komen uit slice deel 1-5 en de Gemaalmeester.
Draaien vanaf de repo-root (deel 1-5 en de Gemaalmeester hoeven niet opnieuw):
    python3 docs/art/slice/bron/genereer_vijanden.py
Het script print de metingen voor docs/art/animatie-timing.md §2.
"""
import csv
import hashlib
import json
import math
import os
import sys

import numpy as np
from PIL import Image
from scipy import ndimage

HIER = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HIER)
import genereer_gemaalmeester as GMM  # noqa: E402  (Cel, tell, stoom, S8 en de boss; draait zelf niets)

D5, D2, D1, R, SP = GMM.D5, GMM.D2, GMM.D1, GMM.R, GMM.SP
import genereer_slice_deel3 as D3  # noqa: E402
import genereer_slice_deel4 as D4  # noqa: E402
MI, K = D1.MI, D1.K
Cel, stoom, tell, verdeel = GMM.Cel, GMM.stoom, GMM.tell, GMM.verdeel
REPO = D1.REPO
UIT_DOCS = os.path.join(REPO, "docs", "art", "slice", "eindkwaliteit")
STATEN = ["grijs", "half", "kleur"]
RAND = 1
TYPES = ("kadeloper", "schotdrager", "dwaallicht")


# ------------------------------------------------------------------ data uit het spel
def lees_data():
    d = {}
    with open(os.path.join(REPO, "game", "data", "vijanden", "slice.csv")) as f:
        for row in csv.reader(f):
            if len(row) >= 3 and row[0] in TYPES + ("gedeeld",):
                try:
                    d.setdefault(row[0], {})[row[1]] = float(row[2])
                except ValueError:
                    pass
    return d


V = lees_data()
KL, SD, DL, GD = V["kadeloper"], V["schotdrager"], V["dwaallicht"], V["gedeeld"]
HB_W, HB_H = KL["breedte"], KL["hoogte"]                       # 16 x 24, de node staat in het midden
assert (SD["breedte"], SD["hoogte"]) == (HB_W, HB_H)
HAAK = (HB_W / 2, KL["vlak_onder"], HB_W / 2 + KL["vlak_breedte"], KL["vlak_onder"] + KL["vlak_hoogte"])  # 8-28 x 4-20
STOOT = (HB_W / 2, SD["vlak_onder"], HB_W / 2 + SD["vlak_breedte"], SD["vlak_onder"] + SD["vlak_hoogte"])  # 8-32 x 4-20
SCHOT_W = SD["beeld_breedte"] - HB_W                            # 6: het schot steekt 6 px voor de hurtbox uit
SCHOT_H = SD["beeld_hoogte"]                                    # 26
DL_W, DL_H = DL["breedte"], DL["hoogte"]                        # 16 x 16
STIL = int(GD["stil_na_treffer"])
EXTRA_VERLICHT = int(GD["verlicht_aanloop_extra"])

# cellen: (breedte, hoogte, x van kolom 0, y van de bovenkant van rij 0); lopers: y = hoogte boven de vloer,
# x = 0 in het midden van de hurtbox, kijkrichting rechts. Dwaallicht: (0, 0) = midden van de hurtbox.
CEL_LOPER = (56, 40, -22, 38)
CEL_DWAAL = (32, 48, -16, 22)
NODE_Y_LOPER = HB_H / 2                                          # de node staat 12 px boven de vloer


def afwerk(c, dk, randdeel):
    """Zoals Cel.afwerken, maar de bovenrand van 2 px komt alleen op `randdeel` (rug, nek en kop; de kooi): niet op
    elke stekel, voet of rafel van de sluier, anders wordt het silhouet een rode spikkelvlek."""
    s = c.solid.copy()
    boven = np.vstack([np.zeros((1, c.w), bool), randdeel[:-1]])     # de rand volgt de rug, de stekels staan erop
    top = s & ~boven & randdeel & (c.mat == MI["vijandlijf"])
    onder = np.vstack([np.zeros((1, c.w), bool), top[:-1]]) & s & ~top & (c.mat == MI["vijandlijf"])
    c.put(onder, "vijandkern", 5 if dk else 4)
    c.put(top, "vijandkern", 7)
    cont = ndimage.binary_dilation(s) & ~s & (c.mat < 0)
    c.mat[cont] = MI["vijandlijf"]
    c.t[cont] = 0
    return c


def kopie(c):
    n = Cel((c.w, c.h, c.x0, c.ytop))
    n.mat, n.t, n.solid, n.lijf = c.mat.copy(), c.t.copy(), c.solid.copy(), c.lijf.copy()
    return n


# ------------------------------------------------------------------ de loper (Kadeloper en Schotdrager)
def lp(**kw):
    p = dict(dx=0, dy=0, lean=0, fb=0.0, ff=0.0, lb=0, lf=0, hand=(13, 9), tip=(23, 3), haak=True, ogen="open",
             kern=0, sway=0, smear=None, stof=None, schot=None, schot_x=HB_W / 2, schot_dy=0, stub=False, seed=0)
    p.update(kw)
    return p


def lijf_tinten(c, m, top_y):
    """Vol donker lijf (bible §6) met vorm in tinten: licht van boven, de buik donker, slib-spikkels."""
    t = np.full(c.mat.shape, 2, np.int16)
    t[c.Y < 6] = 1
    t[c.Y > top_y - 4] = 3
    t[(c.BAY < 0.07) & (c.Y > 5)] = 3
    t[(c.BAY > 0.95) & (c.Y > 3)] = 1
    c.put(m, "vijandlijf", t)


def haak_teken(c, hand, tip, dk):
    """Bootshaak: een houten steel door de hand, een ijzeren haak aan de punt die naar beneden/voren krult."""
    hx_, hy = hand
    tx, ty = tip
    L = max(math.hypot(tx - hx_, ty - hy), 1e-3)
    ux, uy = (tx - hx_) / L, (ty - hy) / L
    achter = (hx_ - ux * 5, hy - uy * 5)
    steel = c.seg(achter, tip, 1.4)
    c.put(steel, "hout", 4, lijf=False)
    c.put(steel & c.seg((achter[0], achter[1] + 0.5), (tx, ty + 0.5), 0.6), "hout", 6, lijf=False)
    # de haak: een prong haaks op de steel, naar de kant van de vloer, en een kleine weerhaak terug
    nx, ny = uy, -ux
    if ny > 0:
        nx, ny = -nx, -ny
    p1 = (tx + nx * 3.2 - ux * 0.5, ty + ny * 3.2 - uy * 0.5)
    prong = c.seg(tip, p1, 1.5) | c.seg(p1, (p1[0] - ux * 1.8, p1[1] - uy * 1.8), 1.3)
    kop = c.seg((tx - ux * 2, ty - uy * 2), (tx + ux * 1.5, ty + uy * 1.5), 1.8)
    c.put(prong | kop, "ijzer", 4, lijf=False)
    c.put((prong | kop) & ~ndimage.binary_erosion(prong | kop) & (c.Y > ty), "ijzer", 6, lijf=False)
    c.put(c.schijf(tx + ux * 1.5, ty + uy * 1.5, 0.8), "ijzer", 7, lijf=False)


def schot_teken(c, x0, dy, soort, dk, f=0):
    """Het roestschot (deel 1 §4.1): roest = pantser, 'hier moet een merk op'. Klinknagels, twee banden, de kant
    naar de vijand donker, de bovenkant licht. `soort`: heel, stuk (wat hij na de breuk overhoudt), tink, barst."""
    if soort == "stuk":
        m = c.rect(x0, 8 + dy, x0 + 5, 20 + dy)
        m &= ~((c.X - x0) + (c.Y - (8 + dy)) * 0.6 < 1.2)                   # gekartelde breukrand boven
        m &= ~(((c.Y - 8 - dy) < 3) & (((c.X - x0) // 1.5) % 2 == 0))
    else:
        m = c.rect(x0, dy, x0 + SCHOT_W, SCHOT_H + dy)
        m &= ~((c.X > x0 + SCHOT_W - 1) & ((c.Y < 2 + dy) | (c.Y > SCHOT_H - 2 + dy)))  # afgeronde hoeken
    t = np.full(c.mat.shape, 3, np.int16)
    t[(c.BAY < 0.18)] = 4
    t[(c.BAY > 0.85)] = 2
    band = (np.abs(c.Y - (7 + dy)) < 1) | (np.abs(c.Y - (18 + dy)) < 1)
    t[band] = 5
    t[c.X < x0 + 1] = 1
    c.put(m, "roest", t, lijf=False)
    top = m & ~np.vstack([np.zeros((1, c.w), bool), m[:-1]])
    c.put(top, "roest", 6, lijf=False)
    klink = m & band & (((c.X - x0) % 3) < 1) & (c.X > x0 + 1)
    c.put(klink, "ijzer", 6, lijf=False)
    if soort == "tink":                                                   # witte ster en bovenrand (VJ-07)
        cx, cy = x0 + SCHOT_W / 2, 14 + dy
        ster = (c.rect(cx - 4, cy - 0.5, cx + 4, cy + 0.5) | c.rect(cx - 0.5, cy - 4, cx + 0.5, cy + 4)
                | (c.schijf(cx, cy, 2.2) & (np.abs(np.abs(c.X - cx) - np.abs(c.Y - cy)) < 0.6)))
        c.put(ster, "ijzer", 7, solid=False, lijf=False)
        c.put(top | (m & (c.X > x0 + SCHOT_W - 1.5)), "ijzer", 7, lijf=False)
    if soort == "barst":                                                  # de breuk, frame 0: barsten met gloed
        zig = np.zeros_like(m)
        for (a, b) in [((x0, 22 + dy), (x0 + 3, 15 + dy)), ((x0 + 3, 15 + dy), (x0 + 1, 9 + dy)),
                       ((x0 + 3, 15 + dy), (x0 + 6, 12 + dy)), ((x0 + 1, 9 + dy), (x0 + 4, 3 + dy))]:
            zig |= c.seg(a, b, 0.9)
        c.put(zig & m, "roest", 0, lijf=False)
        c.put(ndimage.binary_dilation(zig) & m & ~zig & (c.BAY < 0.5), "vijandkern", 5 if dk else 4, lijf=False)
    return m


def stukken_teken(c, x0, f, dk):
    """Het schot valt in drie stukken (f 1: vallen, f 2: liggen) en blijft liggen (f 3: zonder de vijand)."""
    delen = [(0, 8, 0, 9), (0, 6, 9, 18), (0, 6, 18, 26)]                 # (x0, x1, y0, y1) in het schot
    val = {1: [(3, -6), (5, -3), (2, 4)], 2: [(4, -10), (9, -14), (14, -18)], 3: [(4, -10), (9, -14), (14, -18)]}[f]
    for i, ((a, b, y0, y1), (ox, oy)) in enumerate(zip(delen, val)):
        if f >= 2:                                                        # plat op de vloer: 2-3 px hoog
            w = (y1 - y0)
            xs = x0 + ox + i * 2
            m = c.rect(xs, 0, xs + w * 0.7, 2 + (i == 1))
            m &= ~((c.X > xs + w * 0.7 - 1) & (c.Y > 1))
        else:
            m = c.rect(x0 + a + ox, y0 + oy, x0 + min(b, SCHOT_W) + ox, y1 + oy) & (c.Y >= 0)
            m &= ~(((c.X - x0 - ox) + (c.Y - y0 - oy)) % 7 < 1)
        t = np.where(c.BAY < 0.3, 4, 3)
        c.put(m, "roest", t, lijf=False)
        top = m & ~np.vstack([np.zeros((1, c.w), bool), m[:-1]])
        c.put(top, "roest", 6, lijf=False)
    if f == 1:
        stoom(c, x0 + 3, 4, 4, 900 + f, dicht=0.4)


def loper(staat, p, schot=None):
    """Een loper (deel 1 §4.1): laag en breed, gebogen rug met stekels (slib en riet), kop vooruit, bootshaak of
    roestschot. Kijkrichting rechts, x = 0 in het midden van de hurtbox (16 x 24), y = 0 op de vloer."""
    dk = staat != "kleur"
    c = Cel(CEL_LOPER, dx=0)
    dx, dy, ln = p["dx"], p["dy"], p["lean"]
    # rug, kop, poten, arm
    rcx, rcy = -1 + dx + ln * 0.5, 12 + dy
    rug = c.ell(rcx, rcy, 12, 8.5) & (c.Y >= 4 + dy)
    kx, ky = 11 + dx + ln, 10 + dy - (1 if p["ogen"] == "streep" else 0)
    kop = c.ell(kx, ky, 5.5, 3.8) | c.rect(kx + 2, ky - 2.5, kx + 6.5, ky - 0.5)   # kop met een lage snuit
    nek = c.seg((rcx + 7, rcy + 1), (kx - 1, ky), 5)
    benen = np.zeros_like(c.solid)
    for hip, f, lift in ((-6, p["fb"], p["lb"]), (5, p["ff"], p["lf"])):
        hipp = (hip + dx + ln * 0.3, 7 + dy)
        foot = (hip + dx + f, 1.2 + lift)
        knie = ((hipp[0] + foot[0]) / 2 + 1.5, (hipp[1] + foot[1]) / 2 + 0.5)
        benen |= c.seg(hipp, knie, 3.2) | c.seg(knie, foot, 2.6)
        benen |= c.rect(foot[0] - 1, lift, foot[0] + 3, lift + 1.5)      # voet met klauw naar voren
    stekels = np.zeros_like(c.solid)
    for i, sx in enumerate(range(-11, 9, 3)):
        sxx = sx + dx + ln * 0.5
        u = np.clip((sxx - rcx) / 12, -0.99, 0.99)
        yt = rcy + 8.5 * math.sqrt(1 - u * u)
        hgt = 3 + (i % 2) * 2 + (1 if i in (2, 3) else 0)
        sw = p["sway"] * (1 if i % 2 else -1) * 0.5
        stekels |= c.seg((sxx, yt - 1.5), (sxx - 1.8 + sw, yt + hgt), 1.6)
    body = rug | kop | nek | benen | stekels
    top_y = rcy + 8.5
    lijf_tinten(c, body, top_y)
    c.put(stekels & ~rug & ~kop, "vijandlijf", np.where(c.BAY < 0.5, 3, 4))
    randdeel = rug | kop | nek
    # riet: twee lichte halmen tussen de stekels (slib en riet, deel 1 §4.1), hout als figuurmateriaal
    for sx, hgt in ((-6, 6), (2, 5)):
        sxx = sx + dx + ln * 0.5
        u = (sxx - rcx) / 12
        yt = rcy + 8.5 * math.sqrt(max(0, 1 - u * u))
        c.put(c.seg((sxx, yt), (sxx - 2.5 + p["sway"], yt + hgt), 0.9), "hout", 2, lijf=False)
    # kern (rode kern, deel 1 §4.2) met een gloed op het lijf
    kc = (rcx + 1, rcy - 0.5)
    rk = 2.6 + 0.4 * p["kern"]
    glow = c.schijf(*kc, rk + 2) & body & (c.BAY < 0.5)
    c.put(glow, "vijandkern", 1 if dk else 0)
    kern = c.schijf(*kc, rk)
    tk = (5 if dk else 4) + min(p["kern"], 0) + (1 if p["kern"] > 0 else 0)
    c.put(kern, "vijandkern", int(np.clip(tk, 1, 7)), lijf=False)
    c.put(c.schijf(*kc, max(rk - 1.3, 0.6)), "vijandkern", int(np.clip(tk + 2, 1, 7)), lijf=False)
    # arm en wapen
    schouder = (7 + dx + ln, 11 + dy)
    hand = (p["hand"][0] + dx, p["hand"][1] + dy * 0)
    if p["smear"] is not None:                                           # veeglijnen (ijzer, gedithered)
        sm = p["smear"](c)
        c.put(sm & (c.mat < 0) & (c.BAY < 0.55), "ijzer", 5, solid=False, lijf=False)
        c.put(sm & (c.mat < 0) & (c.BAY >= 0.55) & (c.BAY < 0.8), "ijzer", 3, solid=False, lijf=False)
    arm = c.seg(schouder, hand, 2.6)
    if schot is None and p["haak"]:
        haak_teken(c, hand, (p["tip"][0] + dx, p["tip"][1]), dk)
    c.put(arm, "vijandlijf", 3)
    c.put(c.schijf(hand[0], hand[1], 1.4), "vijandlijf", 4)
    if p["stub"]:                                                        # riem van het schot om de onderarm
        c.put(c.seg(schouder, hand, 2.6) & c.schijf(hand[0] - 1.5, hand[1], 1.6), "roest", 5, lijf=False)
    if schot is not None:
        schot_teken(c, p["schot_x"] + dx, p["schot_dy"], schot, dk)
    # ogen (na arm en wapen, zodat niets ze bedekt): wit (vijandkern 7), streep als hij stil staat
    for ox in (1.5, 3.8):
        ex, ey = kx + ox, ky + 0.5
        if p["ogen"] == "streep":
            c.put(c.rect(ex - 1, ey - 1, ex + 1, ey), "vijandkern", 3, lijf=False)
        elif p["ogen"] == "wijd":
            c.put(c.rect(ex - 0.5, ey - 1, ex + 0.5, ey + 1), "vijandkern", 7, lijf=False)
        else:
            c.put(c.rect(ex - 0.5, ey - 0.5, ex + 0.5, ey + 0.5), "vijandkern", 7, lijf=False)
    if p["stof"] is not None:                                            # stof waar de haak de vloer raakt
        sx, r = p["stof"]
        stoom(c, sx, 2, r, 300 + int(sx * 7) + p["seed"], dicht=0.5)
    return afwerk(c, dk, randdeel)


def smelt(c, k, staat, seed=0):
    """Dood (combat §9.1): hij lost op in donker water. Het lijf zakt in (k 0..1) en wordt water dat wegvloeit."""
    dk = staat != "kleur"
    n = Cel((c.w, c.h, c.x0, c.ytop))
    s = 1 - 0.9 * k
    rows = np.arange(c.h)
    Y = c.ytop - rows - 0.5
    src = np.clip(np.round(c.ytop - 0.5 - Y / s).astype(int), 0, c.h - 1)
    ok = (Y >= 0)
    m = np.where(ok[:, None], c.mat[src], -1)
    t = np.where(ok[:, None], c.t[src], 0)
    # het lijf verliest pixels van boven naar beneden (gedithered), wat over is wordt donker water
    hoog = n.Y > (1 - k) * 22
    vrij = (n.BAY < k * 1.2) | hoog
    m = np.where(vrij & (m >= 0) & (n.Y > 2), -1, m)
    n.mat[:], n.t[:] = m, t
    n.solid[:] = np.where(ok[:, None], c.solid[src], False) & (n.mat >= 0)
    n.lijf[:] = n.mat == MI["vijandlijf"]
    nat = (n.mat >= 0) & (n.BAY < 0.25 + k * 0.6) & (n.mat != MI["vijandkern"])
    n.put(nat, "water", np.where(n.Y < 3, 1, 2), solid=True, lijf=False)
    # de plas op de vloer
    br = 8 + 14 * k
    plas = (np.abs(n.X - 1) < br) & (n.Y >= 0) & (n.Y < 1 + (k > 0.3) + (np.abs(n.X - 1) < br * 0.5))
    n.put(plas & (n.mat < 0) | plas & (n.Y < 1), "water", np.where(n.BAY < 0.4, 2, 1), solid=False, lijf=False)
    n.put(plas & (n.Y >= 1) & (n.Y < 2) & ((n.X.astype(int) + seed) % 5 == 0), "water", 5, solid=False, lijf=False)
    # de kern zakt als laatste mee en dooft
    kt = int(round(6 - 5 * k)) if dk else int(round(5 - 4 * k))
    kc = (1, max(0.5, 11 * (1 - k)))
    c2 = n.schijf(*kc, 2.2 - 1.2 * k)
    n.put(c2, "vijandkern", max(kt, 1), solid=k < 0.7, lijf=False)
    return n


def plas_rest(staat, f):
    """Na het smelten: de plas trekt weg in de kieren (2 frames)."""
    c = Cel(CEL_LOPER)
    br = 20 - f * 7
    plas = (np.abs(c.X - 1) < br) & (c.Y >= 0) & (c.Y < 1) & (c.BAY < 0.75 - f * 0.3)
    c.put(plas, "water", np.where(c.BAY < 0.3, 2, 1), solid=False, lijf=False)
    if f == 0:
        c.put(c.schijf(1, 0.5, 0.7), "vijandkern", 2, solid=False, lijf=False)
    return c


def poses_loper(reik_x, schot):
    """Poses van de loper. `reik_x` = het verste punt van het vlak (28 haak, 32 stoot): het actieve frame reikt
    precies tot daar (combat §9: actief vlak = het verste frame). `schot`: None (haak), 'heel' of 'stuk'."""
    haak = schot is None
    x1v, y0v, y1v = HAAK[0], HAAK[1], HAAK[3]
    rust = dict(hand=(13, 9), tip=(23, 3)) if haak else dict(hand=(10, 11), schot_x=HB_W / 2)
    if schot == "stuk":
        rust = dict(hand=(11, 11), schot_x=10)

    loop = []
    for i in range(6):
        ph = i / 6 * 2 * math.pi
        fb, ff = 3.5 * math.sin(ph), 3.5 * math.sin(ph + math.pi)
        lb, lf = int(round(max(0, math.cos(ph)) * 2)), int(round(max(0, math.cos(ph + math.pi)) * 2))
        dy = 1 if abs(math.cos(ph)) > 0.7 else 0
        extra = dict(rust)
        if haak:
            extra.update(hand=(13, 9 + dy), tip=(23 + (i % 3 == 0), 3 + (dy and 1)))
        loop.append(lp(fb=fb, ff=ff, lb=lb, lf=lf, dy=dy, sway=[0, 1, 1, 0, -1, -1][i], seed=i, **extra))
    staan = [lp(dy=[0, 0, 1, 0][i], sway=[0, 1, 0, -1][i], ogen="streep" if i == 3 else "open", seed=10 + i, **rust)
             for i in range(4)]
    if haak:
        # aanloop: de haak gaat in 4 stappen omhoog en naar achteren boven de kop (deel 1 §4.3), het lijf leunt weg;
        # frame 4 = uithaal (de laatste 3 ticks): het lijf komt naar voren, veeglijnen achter de haak
        hoek = [40, 75, 105, 125]
        aan = []
        for i, a in enumerate(hoek):
            r_ = math.radians(a)
            hand = (8 - i * 0.8, 15 + i * 1.5)
            tip = (hand[0] + 14 * math.cos(r_), hand[1] + 14 * math.sin(r_))
            aan.append(lp(lean=-(i + 1) // 2, dy=i // 2, hand=hand, tip=tip, ogen="wijd" if i >= 2 else "open",
                          kern=1 if i >= 2 else 0, seed=20 + i))
        aan.append(lp(lean=1, dy=1, hand=(11, 17), tip=(23, 26), ogen="wijd", kern=1, seed=24,
                      smear=lambda c: (np.abs(np.hypot(c.X - 9, c.Y - 14) - 15) < 1.2) & (c.Y > 22) & (c.X > 0) & (c.X < 22)))
        # slag: het verste frame, de haak op de verste rand van het vlak, laag
        slag_tip = (reik_x - 1.5, y0v + 1.5)
        veeg = lambda c: (np.hypot(c.X - 9, c.Y - 9) < 19) & (np.hypot(c.X - 9, c.Y - 9) > 15.5) & (c.X > 12) & (c.Y > 3)
        slag = [lp(lean=3, dy=-1, hand=(17, 9), tip=slag_tip, ogen="wijd", kern=1, smear=veeg, seed=30),
                lp(lean=3, dy=-1, hand=(17, 9), tip=slag_tip, ogen="wijd", kern=1, stof=(slag_tip[0] - 1, 3), seed=31)]
        herstel = [lp(lean=2, dy=-1, hand=(16, 7), tip=(reik_x - 3, 1.5), seed=40),
                   lp(lean=1, dy=0, hand=(14, 8), tip=(25, 2.5), seed=41)]
    else:
        # schotstoot: het schot gaat in 4 stappen naar achteren (deel 1 §4.3), het lijf leunt weg en duikt in
        aan = [lp(lean=-(i + 1) // 2, dy=-(i // 2), hand=(8 - i, 11), schot_x=rust["schot_x"] - 1.3 * (i + 1),
                  ogen="wijd" if i >= 2 else "open", kern=1 if i >= 2 else 0, stub=schot == "stuk", seed=20 + i)
               for i in range(4)]
        aan.append(lp(lean=1, dy=-1, hand=(8, 11), schot_x=rust["schot_x"] - 2, ogen="wijd", kern=1, stub=schot == "stuk",
                      smear=lambda c: (c.rect(-12, 6, -4, 7) | c.rect(-14, 12, -5, 13) | c.rect(-12, 18, -4, 19)), seed=24))
        sw = SCHOT_W if schot == "heel" else 5
        sx = reik_x - sw                                                  # het schot tot de verste rand van het vlak
        veeg = lambda c: (c.rect(10, 6, sx, 7) | c.rect(8, 12, sx, 13) | c.rect(10, 18, sx, 19))
        slag = [lp(lean=4, dy=-1, hand=(sx - 1, 11), schot_x=sx, ogen="wijd", kern=1, smear=veeg, stub=schot == "stuk", seed=30),
                lp(lean=4, dy=-1, hand=(sx - 1, 11), schot_x=sx, ogen="wijd", kern=1, stof=(sx + 2, 3), stub=schot == "stuk",
                   seed=31)]
        herstel = [lp(lean=3, dy=0, hand=(sx - 4, 11), schot_x=sx - 4, stub=schot == "stuk", seed=40),
                   lp(lean=1, dy=0, hand=(rust["hand"][0] + 3, 11), schot_x=rust["schot_x"] + 3, stub=schot == "stuk", seed=41)]
        for q in loop + staan:
            q["stub"] = schot == "stuk"
    stil = [lp(dx=-1, dy=0, ogen="streep", kern=-1, seed=50, **rust),
            lp(dx=-1, dy=-1, ogen="streep", kern=-1, seed=51, **rust),
            lp(dx=0, dy=0, ogen="open", kern=0, seed=52, **rust)]
    if haak:
        stil[0].update(tip=(22, 1.5))
        stil[1].update(tip=(21, 1.5), hand=(12, 7))
    else:
        for q in stil:
            q["stub"] = schot == "stuk"
    return dict(loop=loop, staan=staan, aan=aan, slag=slag, herstel=herstel, stil=stil)


def uit_stoom(staat, i, schot):
    """Uit de stoom stappen (adds, combat §3.4 en §9.1): eerst alleen stoom, dan een donker silhouet, dan de ogen,
    dan de bovenrand en de kern; de stoom zakt weg."""
    dk = staat != "kleur"
    P = poses_loper(HAAK[2] if schot is None else STOOT[2], schot)
    basis = P["staan"][0] if i < 4 else P["loop"][1]
    c = loper(staat, basis, schot)
    if i <= 2:
        s = c.solid.copy()
        c.mat[s], c.t[s] = MI["vijandlijf"], 0 if i < 2 else 1
        c.lijf[:] = False
        if i == 0:
            c.wis(s)
        if i == 2:
            ogen = c.rect(13, 9, 16, 11) & (c.BAY < 0.5)
            c.put(ogen & s, "vijandkern", 6, lijf=False)
        c.solid[:] = c.mat >= 0
        c2 = Cel(CEL_LOPER)
        c2.mat, c2.t, c2.solid, c2.lijf = c.mat, c.t, c.solid, c.lijf
        c = c2
    dicht = [0.85, 0.75, 0.6, 0.4, 0.22][i]
    for j in range(3):
        stoom(c, (j - 1) * 7, 6 + j * 3 + i * 2, 9 - i, 700 + i * 5 + j, dicht=dicht)
    return c


# ------------------------------------------------------------------ het Dwaallicht
def dw(**kw):
    p = dict(dx=0, dy=0, kr=2.6, kt=0, spijl=5, sluier=0, sway=0, ogen="open", trail=0, oplos=0.0, uiteen=0, seed=0)
    p.update(kw)
    return p


def dwaallicht(staat, p):
    """Een gedoofde lantaarn op drift (deel 1 §4.1): ijzeren kooi om een rode kern, een rafelige sluier eronder.
    Het licht is rood, nooit warm. (0, 0) = midden van de hurtbox (16 x 16)."""
    dk = staat != "kleur"
    c = Cel(CEL_DWAAL)
    dx, dy = p["dx"], p["dy"]
    cx, cy = 0 + dx, 2.5 + dy
    kooi = c.schijf(cx, cy, 7.6)
    hengsel = (np.abs(np.hypot(c.X - cx, c.Y - (cy + 9.5)) - 2.2) < 0.8) & (c.Y > cy + 8.5)
    kap = c.rect(cx - 2, cy + 7, cx + 2, cy + 9)
    wd = 7.5 + p["sluier"]
    sl_top, sl_bot = cy - 1, cy - 13 + p["sluier"] * 0.5
    sluier = (c.Y < sl_top) & (c.Y >= sl_bot) & (np.abs(c.X - cx) < wd - (sl_top - c.Y) * (0.25 - p["sluier"] * 0.06))
    sluier &= ~(((c.X + c.Y + p["sway"]) % 4 < 1) & (c.Y < sl_top - 5))
    franje = np.zeros_like(kooi)
    for j, fx in enumerate(range(-6, 7, 3)):
        lengte = 3 + (j * 7 + p["seed"]) % 3
        fxx = cx + fx + p["sway"] * (0.5 if j % 2 else -0.5)
        franje |= c.seg((cx + fx, sl_bot + 1), (fxx, sl_bot - lengte), 1.1)
    trail = np.zeros_like(kooi)
    if p["trail"]:                                                       # de duik: de sluier sleept omhoog
        for j, fx in enumerate((-5, -2, 2, 5)):
            trail |= c.seg((cx + fx * 0.8, cy + 5), (cx + fx * 1.2, cy + 5 + p["trail"] - (j % 2) * 3), 1.2)
        sluier = sluier & (c.Y > cy - 8)
        franje[:] = False
    body = kooi | sluier | franje | kap | trail
    t = np.full(c.mat.shape, 2, np.int16)
    t[c.Y < cy - 5] = 1
    t[(c.BAY < 0.08)] = 3
    t[trail] = 1
    c.put(body, "vijandlijf", t)
    # de kern en zijn gloed binnen de kooi (vijandkern; in het donker feller, VJ-06)
    kr = p["kr"]
    kt0 = (5 if dk else 4) + p["kt"]
    glow = c.schijf(cx, cy, kr + 2.5) & kooi & (c.BAY < 0.45)
    c.put(glow, "vijandkern", int(np.clip(kt0 - 3, 0, 7)))
    c.put(c.schijf(cx, cy, kr), "vijandkern", int(np.clip(kt0, 0, 7)), lijf=False)
    c.put(c.schijf(cx, cy, max(kr - 1.4, 0.5)), "vijandkern", int(np.clip(kt0 + 2, 0, 7)), lijf=False)
    # spijlen van de kooi (ijzer; gloeien rood mee in de aanloop)
    r_ = np.hypot(c.X - cx, c.Y - cy)
    spijl = kooi & ((np.abs(c.X - cx - 3.5) < 0.5) | (np.abs(c.X - cx + 3.5) < 0.5) | (np.abs(r_ - 5.6) < 0.55)
                    | (np.abs(c.Y - cy) < 0.5)) & (r_ > kr + 0.3) & (r_ < 6.2)
    if p["spijl"] > 5:
        c.put(spijl, "vijandkern", min(p["spijl"] - 3, 7), lijf=False)
    else:
        c.put(spijl, "ijzer", p["spijl"], lijf=False)
    c.put(hengsel | kap, "ijzer", 3, lijf=False)
    c.put(kap & (c.Y > cy + 8), "ijzer", 5, lijf=False)
    # ogen onder de kooi, in de sluier
    for ox in (-2.5, 2.5):
        ex, ey = cx + ox, cy - 4.5
        if p["ogen"] == "streep":
            c.put(c.rect(ex - 1, ey - 0.5, ex + 1, ey + 0.5), "vijandkern", 3, lijf=False)
        elif p["ogen"] == "wijd":
            c.put(c.rect(ex - 0.5, ey - 1, ex + 0.5, ey + 1), "vijandkern", 7, lijf=False)
        elif p["ogen"] == "open":
            c.put(c.rect(ex - 0.5, ey - 0.5, ex + 0.5, ey + 0.5), "vijandkern", 7, lijf=False)
    if p["trail"]:                                                        # snelheidsstrepen boven hem
        for fx in (-6, 0, 6):
            ln = c.rect(cx + fx - 0.5, cy + 10, cx + fx + 0.5, cy + 10 + p["trail"]) & (c.BAY < 0.6) & (c.mat < 0)
            c.put(ln, "vijandkern", 3 if dk else 2, solid=False, lijf=False)
    afwerk(c, dk, kooi & ~kap)
    if p["uiteen"]:                                                       # dood: de kooi springt uiteen, valt
        k = p["uiteen"]
        n = Cel(CEL_DWAAL)
        rng = np.random.default_rng(55)
        # breek in brokken op een raster van 5 px
        blok = ((np.floor((c.X - cx + 20) / 5) * 13 + np.floor((c.Y - cy + 30) / 5)).astype(int))
        for b in np.unique(blok[c.mat >= 0]):
            m = (blok == b) & (c.mat >= 0)
            if m.sum() == 0:
                continue
            bx = float(np.mean(c.X[m])) - cx
            ox = int(round(bx * 0.35 * k + rng.uniform(-1, 1) * k))
            oy = int(round(-(k * k) * (3 + rng.uniform(0, 4)) + max(0, bx) * 0))
            keep = rng.uniform() > (k - 2.5) * 0.5
            if not keep:
                continue
            rr, cc = np.where(m)
            r2, c2 = rr - oy, cc + ox
            ok = (r2 >= 0) & (r2 < c.h) & (c2 >= 0) & (c2 < c.w)
            n.mat[r2[ok], c2[ok]] = c.mat[rr[ok], cc[ok]]
            n.t[r2[ok], c2[ok]] = c.t[rr[ok], cc[ok]]
        # alles dooft: de kern wordt donker, wat overblijft dithert weg
        kern = n.mat == MI["vijandkern"]
        n.t[kern] = np.clip(n.t[kern] - int(k * 1.5), 1, 7)
        weg = (n.BAY < (k - 1) * 0.3) & (n.mat >= 0)
        n.mat[weg] = -1
        n.solid[:] = n.mat >= 0
        return n
    return c


def poses_dwaal():
    zweef = [dw(dy=[0, 1, 1, 0, -1, -1][i], sway=[0, 1, 1, 0, -1, -1][i], kr=2.6 + 0.3 * (i in (1, 2)), seed=i)
             for i in range(6)]
    aan = [dw(kr=2.9 + 0.5 * i, kt=1 if i >= 2 else 0, spijl=4 + i * 1 + (i >= 2) * 2, sluier=i * 0.7,
              ogen="wijd" if i >= 1 else "open", seed=10 + i) for i in range(4)]
    aan.append(dw(dy=2, kr=4.6, kt=2, spijl=9, sluier=-1, ogen="wijd", seed=14))
    duik = [dw(kr=4.0, kt=2, spijl=8, trail=10, ogen="wijd", seed=20), dw(kr=3.6, kt=1, spijl=8, trail=13, ogen="wijd", seed=21)]
    terug = [dw(dy=[-1, 0, 1, 0][i], kr=2.0, kt=-2, spijl=3, sluier=-0.5, sway=[1, 0, -1, 0][i], ogen="open", seed=30 + i)
             for i in range(4)]
    stil = [dw(dx=[1, 0, -1, 0, 1, 0][i], kr=[1.6, 2.6, 1.4, 2.4, 1.8, 2.6][i], kt=[-3, 0, -4, -1, -3, 0][i], spijl=3,
               ogen="streep", seed=40 + i) for i in range(6)]
    dood = [dw(kr=5.2, kt=2, spijl=9, ogen="wijd", seed=50)] + \
           [dw(kr=3.0 - i * 0.3, kt=-i, spijl=4, ogen="streep", uiteen=0.6 + i * 0.55, seed=51 + i) for i in range(7)]
    return dict(zweef=zweef, aan=aan, duik=duik, terug=terug, stil=stil, dood=dood)


def duiklijn(staat, fase):
    """De aanloop wijst de landingsplek aan (deel 1 §4.3): een gestippelde lijn van zijn onderkant naar het vlak."""
    c = Cel((3, 40, -1.5, 40))
    lijn = (np.abs(c.X) < 0.6) & ((np.floor(c.Y) % 4) < 2)
    c.put(lijn, "vijandkern", 6 if fase == "laat" else 4, solid=False, lijf=False)
    if fase == "laat":
        c.put((np.abs(c.X) < 1.6) & ((np.floor(c.Y) % 4) == 0) & (c.BAY < 0.5), "vijandkern", 3, solid=False, lijf=False)
    return c


# ------------------------------------------------------------------ atlas, manifest en .import
class Blad(GMM.Blad):
    def __init__(self, typ, naam, cel):
        super().__init__(naam, cel)
        self.typ = typ

    def export(self, P=RAND):
        uit = os.path.join(REPO, "game", "art", "animatie", self.typ)
        os.makedirs(uit, exist_ok=True)
        kol = max(len(fr["grijs"]) for _, fr, _, _, _ in self.rijen)
        CW, CH = self.cw + 2 * P, self.ch + 2 * P
        W, H = kol * CW, len(self.rijen) * CH
        anims, rand_fout = {}, 0
        stem = f"{self.typ}_{self.naam}" if self.naam != self.typ else self.typ
        for s in STATEN:
            img = np.zeros((H, W, 4))
            for r, (naam, fr, _, _, _) in enumerate(self.rijen):
                for i, c in enumerate(fr[s]):
                    lay = c.render(s)
                    img[r * CH + P:r * CH + P + self.ch, i * CW + P:i * CW + P + self.cw] = lay
            D2.save(img, os.path.join(uit, f"{stem}_{s}.png"))
            # controle: geen pixel op de rand van een cel (eis #267)
            a = img[..., 3] > 0
            for r in range(len(self.rijen)):
                for i in range(kol):
                    cel = a[r * CH:(r + 1) * CH, i * CW:(i + 1) * CW]
                    if cel.size and (cel[0].any() or cel[-1].any() or cel[:, 0].any() or cel[:, -1].any()):
                        rand_fout += 1
        items = []
        for r, (naam, fr, ticks, lus, extra) in enumerate(self.rijen):
            for i, c in enumerate(fr["grijs"]):
                items.append((i * CW + P, r * CH + P, c))
            anims[naam] = dict(frames=[[i * CW, r * CH, CW, CH] for i in range(len(fr["grijs"]))],
                               ticks=list(ticks), lus=lus, **extra)
        D1.index_atlas(items, W, H).save(os.path.join(uit, f"{stem}_index.png"))
        self.rand_fout = rand_fout
        return dict(bestanden={s: f"{stem}_{s}.png" for s in STATEN + ["index"]},
                    cel=[CW, CH], rand_px=P, atlas=[W, H], animaties=anims)


def godot_uid(pad):
    """Een vaste uid per bestand (zoals Godot ze schrijft: base 36, a-z dan 0-9), zodat een nieuwe run niets
    verandert. Godot behoudt een uid die al in de .import staat."""
    n = int(hashlib.sha256(pad.encode()).hexdigest(), 16) & 0x7FFFFFFFFFFFFFFF
    s = ""
    while True:
        c = n % 36
        s = (chr(ord("a") + c) if c < 26 else chr(ord("0") + c - 26)) + s
        n //= 36
        if not n:
            break
    return "uid://" + s


IMPORT_SJABLOON = """[remap]

importer="texture"
type="CompressedTexture2D"
uid="{uid}"
path="res://.godot/imported/{naam}-{md5}.ctex"
metadata={{
"vram_texture": false
}}

[deps]

source_file="{res}"
dest_files=["res://.godot/imported/{naam}-{md5}.ctex"]

[params]

compress/mode=0
compress/high_quality=false
compress/lossy_quality=0.7
compress/uastc_level=0
compress/rdo_quality_loss=0.0
compress/hdr_compression=1
compress/normal_map=0
compress/channel_pack=0
mipmaps/generate=false
mipmaps/limit=-1
roughness/mode=0
roughness/src_normal=""
process/channel_remap/red=0
process/channel_remap/green=1
process/channel_remap/blue=2
process/channel_remap/alpha=3
process/fix_alpha_border=true
process/premult_alpha=false
process/normal_map_invert_y=false
process/hdr_as_srgb=false
process/hdr_clamp_exposure=false
process/size_limit=0
detect_3d/compress_to=1
"""


def schrijf_import(typ, naam):
    """Hetzelfde formaat als de .import van de Gemaalmeester (Lossless, mipmaps uit). Bestaat hij al, dan blijft hij."""
    pad = os.path.join(REPO, "game", "art", "animatie", typ, naam + ".import")
    if os.path.exists(pad):
        return
    res = f"res://art/animatie/{typ}/{naam}"
    md5 = hashlib.md5(res.encode()).hexdigest()
    with open(pad, "w") as f:
        f.write(IMPORT_SJABLOON.format(uid=godot_uid(res), naam=naam, md5=md5, res=res))


def plaatsing_loper(cel):
    w, h, x0, ytop = cel
    oy = int(-(ytop - NODE_Y_LOPER)) - RAND
    return dict(offset=[x0 - RAND, oy], offset_links=[-(x0 + w) - RAND, oy],
                ten_opzichte_van="vijand-node (midden van de hurtbox 16 x 24; de vloer ligt 12 px onder de node)",
                flip_h="kijkrichting links (`facing < 0`): flip_h = true en `offset_links`",
                noot=f"de hurtbox valt op kolom {int(-x0 - HB_W / 2) + RAND}-{int(-x0 + HB_W / 2) + RAND}, rij "
                     f"{int(ytop - HB_H) + RAND}-{int(ytop) + RAND} (met de rand); de vloer op rij {int(ytop) + RAND}",
                z_index=0)


def bouw_kadeloper():
    T = KL
    P = poses_loper(HAAK[2], None)
    b = Blad("kadeloper", "kadeloper", CEL_LOPER)
    b.anim("staan", lambda s, i: loper(s, P["staan"][i]), 4, [12] * 4, lus=True,
           noot="staat stil (geen pad, VJ-05 houdt hem tegen); ademt, de stekels wiegen")
    b.anim("lopen", lambda s, i: loper(s, P["loop"][i]), 6, [8] * 6, lus=True,
           noot="48 ticks per cyclus; bij 0,5 px/tick (D = 60) 24 px per cyclus, 12 px per stap. Verlicht (0,25): ticks x 2")
    aanloop = int(T["aanloop"])
    b.anim("haak_aanloop", lambda s, i: loper(s, P["aan"][i]), 5, verdeel(aanloop - 3, 4) + [3],
           stuurt="windup_progress: frame 0-3 op kwarten van (aanloop - 3); frame 4 (uithaal) de laatste 3 ticks",
           ticks_verlicht=verdeel(aanloop + EXTRA_VERLICHT - 3, 4) + [3])
    b.anim("haak_slag", lambda s, i: loper(s, P["slag"][i]), 2, verdeel(int(T["actief"]), 2),
           noot="het verste frame: de haak op de verste rand van het vlak (x 28), valt samen met de actieve ticks")
    b.anim("haak_herstel", lambda s, i: loper(s, P["herstel"][i]), 2, verdeel(int(T["herstel"]), 2), volgt="lopen")
    b.anim("stil", lambda s, i: loper(s, P["stil"][i]), 3, [4, STIL - 12, 8],
           noot="VJ-04: stil na een treffer (30): schok, knik (lijf 1 px lager, ogen een streep, kern dooft een tint), terug")
    b.anim("dood", lambda s, i: smelt(loper(s, P["stil"][1]), [0.0, 0.15, 0.3, 0.45, 0.6, 0.75][i], s, i) if i < 6
           else plas_rest(s, i - 6), 8, [6] * 8,
           noot="lost op in donker water (combat §9.1); voorstel 48 ticks, daarna niets meer tekenen")
    b.anim("uit_stoom", lambda s, i: uit_stoom(s, i, None), 5, verdeel(int(GMM.GM["add_inactief"]), 5),
           volgt="lopen", noot="adds uit de spuigaten van de Gemaalmeester (add_inactief 30): stoom, silhouet, ogen, rand")
    t = Blad("kadeloper", "tell_haak", (int(KL["vlak_breedte"]), int(KL["vlak_hoogte"])))
    for fase in ("vroeg", "laat", "actief"):
        t.anim(fase, lambda s, i, f=fase: tell(KL["vlak_breedte"], KL["vlak_hoogte"], f), 1, [1],
               stuurt={"vroeg": "windup_progress < 0,5", "laat": "windup_progress >= 0,5", "actief": "is_attack_active()"}[fase])
    return dict(kadeloper=b, tell_haak=t)


def bouw_schotdrager():
    T = SD
    P = poses_loper(STOOT[2], "heel")
    G = poses_loper(STOOT[2], "stuk")
    b = Blad("schotdrager", "schotdrager", CEL_LOPER)
    b.anim("staan", lambda s, i: loper(s, P["staan"][i], "heel"), 4, [12] * 4, lus=True)
    b.anim("lopen", lambda s, i: loper(s, P["loop"][i], "heel"), 6, [8] * 6, lus=True)
    aanloop = int(T["aanloop"])
    b.anim("stoot_aanloop", lambda s, i: loper(s, P["aan"][i], "heel"), 5, verdeel(aanloop - 3, 4) + [3],
           stuurt="windup_progress, zoals haak_aanloop", ticks_verlicht=verdeel(aanloop + EXTRA_VERLICHT - 3, 4) + [3])
    b.anim("stoot_actief", lambda s, i: loper(s, P["slag"][i], "heel"), 2, verdeel(int(T["actief"]), 2),
           noot="het verste frame: de voorkant van het schot op de verste rand van het vlak (x 32)")
    b.anim("stoot_herstel", lambda s, i: loper(s, P["herstel"][i], "heel"), 2, verdeel(int(T["herstel"]), 2), volgt="lopen")
    b.anim("stil", lambda s, i: loper(s, P["stil"][i], "heel"), 3, [4, STIL - 12, 8])
    b.anim("tink", lambda s, i: loper(s, P["staan"][0], "tink"), 1, [4],
           noot="VJ-07: een treffer op het intacte schot (TINK_TICKS 4): witte ster en bovenrand; daarna terug")
    b.anim("breuk", lambda s, i: breuk(s, i, G), 3, [4, 4, 4], volgt="gebroken_staan",
           noot="break_armor: het schot barst (gloed in de barsten), springt in drie stukken en valt (12)")
    b.anim("stuk", lambda s, i: stuk_los(s), 1, [1],
           noot="de stukken op de vloer, zonder de vijand: blijft liggen op de plek van de breuk (node-positie bij break_armor)")
    b.anim("uit_stoom", lambda s, i: uit_stoom(s, i, "heel"), 5, verdeel(30, 5), volgt="lopen",
           noot="de Schotdrager is geen add; voor de volledigheid (combat §9.1: als de Kadeloper)")
    b.anim("dood", lambda s, i: smelt(loper(s, G["stil"][1], "stuk"), [0.0, 0.15, 0.3, 0.45, 0.6, 0.75][i], s, i) if i < 6
           else plas_rest(s, i - 6), 8, [6] * 8, noot="kan alleen gebroken sterven (E-14g); als de Kadeloper")
    for naam, sleutel, n, ticks in (("gebroken_staan", "staan", 4, [12] * 4), ("gebroken_lopen", "loop", 6, [8] * 6),
                                    ("gebroken_aanloop", "aan", 5, verdeel(aanloop - 3, 4) + [3]),
                                    ("gebroken_actief", "slag", 2, verdeel(int(T["actief"]), 2)),
                                    ("gebroken_herstel", "herstel", 2, verdeel(int(T["herstel"]), 2)),
                                    ("gebroken_stil", "stil", 3, [4, STIL - 12, 8])):
        b.anim(naam, lambda s, i, k=sleutel: loper(s, G[k][i], "stuk"), n, ticks, lus=naam in ("gebroken_staan", "gebroken_lopen"),
               noot="na break_armor: hij stoot met het stuk schot dat hij overhoudt (zelfde vlak 24 x 16)")
    t = Blad("schotdrager", "tell_stoot", (int(SD["vlak_breedte"]), int(SD["vlak_hoogte"])))
    for fase in ("vroeg", "laat", "actief"):
        t.anim(fase, lambda s, i, f=fase: tell(SD["vlak_breedte"], SD["vlak_hoogte"], f), 1, [1],
               stuurt={"vroeg": "windup_progress < 0,5", "laat": "windup_progress >= 0,5", "actief": "is_attack_active()"}[fase])
    return dict(schotdrager=b, tell_stoot=t)


def breuk(staat, i, G):
    dk = staat != "kleur"
    P = poses_loper(STOOT[2], "heel")
    if i == 0:
        return loper(staat, dict(P["stil"][0]), "barst")
    c = loper(staat, dict(G["stil"][0] if i == 1 else G["staan"][0]), "stuk")
    stukken_teken(c, HB_W / 2, i, dk)
    return c


def stuk_los(staat):
    c = Cel(CEL_LOPER)
    stukken_teken(c, HB_W / 2, 3, staat != "kleur")
    return c.afwerken(dk=staat != "kleur", bovenrand=False)


def bouw_dwaallicht():
    T = DL
    P = poses_dwaal()
    b = Blad("dwaallicht", "dwaallicht", CEL_DWAAL)
    b.anim("zweven", lambda s, i: dwaallicht(s, P["zweef"][i]), 6, [8] * 6, lus=True,
           noot="heen en weer op zijn baan; dobbert 1 px, de sluier wiegt")
    aanloop = int(T["aanloop"])
    b.anim("aanloop", lambda s, i: dwaallicht(s, P["aan"][i]), 5, verdeel(aanloop - 3, 4) + [3],
           stuurt="windup_progress: de kern zwelt in 4 stappen, de spijlen gloeien mee; frame 4 (de laatste 3 ticks): hij trekt "
                  "zich 2 px op, de sluier strak", ticks_verlicht=verdeel(aanloop + EXTRA_VERLICHT - 3, 4) + [3])
    b.anim("duik", lambda s, i: dwaallicht(s, P["duik"][i]), 2, verdeel(int(T["actief"]), 2),
           noot="zijn lichaam is het vlak (16 x 16): de code verschuift de node; de sluier sleept omhoog")
    b.anim("terug", lambda s, i: dwaallicht(s, P["terug"][i]), 4, verdeel(int(T["herstel"]), 4), volgt="zweven",
           noot="terug naar zijn baan, zonder schade: de kern gedimd, de sluier slap")
    b.anim("stil", lambda s, i: dwaallicht(s, P["stil"][i]), 6, [5] * 6,
           noot="VJ-04 (30): hij flakkert, de kern gaat aan en uit, de kooi rammelt 1 px")
    b.anim("dood", lambda s, i: dwaallicht(s, P["dood"][i]), 8, [6] * 8,
           noot="de kern flitst, de kooi springt uiteen en valt, alles dooft; voorstel 48 ticks")
    t = Blad("dwaallicht", "tell_duik", (int(DL_W), int(DL_H)))
    for fase in ("vroeg", "laat"):
        t.anim(fase, lambda s, i, f=fase: tell(DL_W, DL_H, f), 1, [1],
               stuurt={"vroeg": "windup_progress < 0,5", "laat": "windup_progress >= 0,5"}[fase])
    lijn = Blad("dwaallicht", "duiklijn", (3, 40))
    for fase in ("vroeg", "laat"):
        lijn.anim(fase, lambda s, i, f=fase: duiklijn(s, f), 1, [1])
    return dict(dwaallicht=b, tell_duik=t, duiklijn=lijn)


PLAATSING = {
    "kadeloper": plaatsing_loper(CEL_LOPER),
    "schotdrager": plaatsing_loper(CEL_LOPER),
    "tell_haak": dict(offset=[-RAND, -RAND], ten_opzichte_van="_walker_box().position (linksboven): het vlak valt precies op de inhoud (de cel heeft 1 px rand)", z_index=1),
    "tell_stoot": dict(offset=[-RAND, -RAND], ten_opzichte_van="_walker_box().position: precies het vlak", z_index=1),
    "dwaallicht": dict(offset=[CEL_DWAAL[2] - RAND, -CEL_DWAAL[3] - RAND],
                       offset_links=[-(CEL_DWAAL[2] + CEL_DWAAL[0]) - RAND, -CEL_DWAAL[3] - RAND],
                       ten_opzichte_van="vijand-node (midden van de hurtbox 16 x 16)",
                       noot="de hurtbox valt op kolom 9-25, rij 15-31 (met de rand); symmetrisch, flip_h is niet nodig", z_index=0),
    "tell_duik": dict(offset=[-RAND, -RAND], ten_opzichte_van="de landingsplek: (node.x - 8, vloer - duik_hoogte - 16), linksboven",
                      noot="tijdens de aanloop is active_box leeg; de landingsplek is het vlak van de duik", z_index=1),
    "duiklijn": dict(offset=[-1 - RAND, -RAND], ten_opzichte_van="(node.x, node.y + 8): de onderkant van de hurtbox",
                     noot="region_rect: neem de bovenste (baan_hoogte - duik_hoogte - hoogte) px van de cel, de ruimte tussen hem en het vlak (in de slice 8; max. 24)",
                     z_index=1),
}


# ------------------------------------------------------------------ de kamers (combat §2.6)
def kamers():
    """De achtergronden (grijs en kleur) van de kamers waar ze staan, zoals deel 2-5 ze maken (D = 60)."""
    D5.maak_vaste_stukken()
    bouw = {"S2": D3.bouw_s2, "S3": D2.bouw_s3, "S4": D3.bouw_s4, "S6": D4.bouw_s6, "S7": D4.bouw_s7,
            "S8": D5.bouw_s8, "S9": D5.bouw_s9}
    uit = {}
    for id_, f in bouw.items():
        k = f()
        lagen = {}
        for s in ("grijs", "kleur"):
            if id_ in ("S6", "S7"):
                lagen[s] = D4.met_stukken(k, id_, s)
            elif id_ in ("S8", "S9"):
                lagen[s] = D5.met_stukken(k, id_, s)
            else:
                lagen[s] = k.render(s)
        uit[id_] = (k, lagen)
    return uit


# (kamer, type, scène-x, vloer of baan-midden (wereld-y), kijkrichting, naam). Uit combat §2.6 en de scènes.
B = json.load(open(os.path.join(HIER, "kadewijk_blokken.json")))["60"]
PLEKKEN = [
    ("S2", "kadeloper", 880, 230, 1, "E-paar links"), ("S2", "kadeloper", 908, 230, -1, "E-paar rechts"),
    ("S3", "kadeloper", 2140, 260, -1, "golf 1 E-paar"), ("S3", "kadeloper", 2168, 260, -1, "golf 1 E-paar"),
    ("S3", "kadeloper", 2360, 260, -1, "golf 1 los"),
    ("S3", "schotdrager", 1770, 260, 1, "golf 2 E-paar"), ("S3", "kadeloper", 1798, 260, 1, "golf 2 E-paar"),
    ("S3", "kadeloper", 1990, 260, 1, "golf 2 los"),
    ("S4", "kadeloper", 3260, 260, -1, "overkant"),
    ("S6", "kadeloper", 4340, 260, -1, "K-paar"), ("S6", "kadeloper", 4382, 260, -1, "K-paar"),
    ("S7", "dwaallicht", 5013, 620 - DL["baan_hoogte"] - DL_H / 2, 1, "baan 1/3"),
    ("S7", "dwaallicht", 5067, 620 - DL["baan_hoogte"] - DL_H / 2, 1, "baan 2/3"),
    ("S8", "kadeloper", 4180 + GMM.SPUI[0], 680, 1, "add spuigat links"),
    ("S8", "kadeloper", 4180 + GMM.SPUI[1], 680, -1, "add spuigat rechts"),
    ("S9", "kadeloper", 1060, 635, -1, "E-paar (verlicht)"), ("S9", "kadeloper", 1088, 635, -1, "E-paar (verlicht)"),
    ("S9", "dwaallicht", 2310, 635 - DL["baan_hoogte"] - DL_H / 2, 1, "baan (verlicht)"),
]


def plaats(typ, c, wx, wy, kant, id_):
    """Linksboven (kamer-px) van een cel voor een vijand op scène-x `wx` en vloer/midden `wy`."""
    rx, ry = int(B[id_]["rect"][0]), int(B[id_]["rect"][1])
    if typ == "dwaallicht":
        x = wx - rx + c.x0
        y = wy - ry - c.ytop
    else:
        x = wx - rx + (c.x0 if kant > 0 else -(c.x0 + c.w))
        y = wy - ry - c.ytop
    return int(round(x)), int(round(y))


def gespiegeld(c):
    n = kopie(c)
    n.mat, n.t, n.solid, n.lijf = c.mat[:, ::-1].copy(), c.t[:, ::-1].copy(), c.solid[:, ::-1].copy(), c.lijf[:, ::-1].copy()
    return n


def sprite_voor(typ, staat, soort="staan", i=0):
    if typ == "dwaallicht":
        P = poses_dwaal()
        return dwaallicht(staat, {"staan": P["zweef"][0], "aanloop": P["aan"][3], "stil": P["stil"][0]}[soort])
    schot = "heel" if typ == "schotdrager" else None
    P = poses_loper(STOOT[2] if schot else HAAK[2], schot)
    return loper(staat, {"staan": P["staan"][0], "aanloop": P["aan"][3], "slag": P["slag"][0]}[soort], schot)


def kamerbeeld(kamer, id_, staat, figs, s8_boss=True):
    """figs: [(cel, x, y)] in kamer-px; tussen 'licht' en 'voor' geplakt (zoals de figuren van deel 2-5)."""
    k, lagen = kamer

    def f(img):
        if id_ == "S8" and s8_boss:
            GMM.boss_beeld(img, staat, GMM.lichaam(GMM.IDLE[0], staat), GMM.ketel(staat, "schot", 0),
                           GMM.rad(staat, 0, 0), rad_achter=True)
        for (c, x, y) in figs:
            D1.stamp_rgba(img, c.render(staat), x, y)
        return img
    return k.samengesteld(lagen[staat], f)


def masker(c, x, y, h, w, alleen=None):
    m = np.zeros((h, w), bool)
    sub = (c.mat >= 0) if alleen is None else alleen(c)
    ys, xs = max(0, y), max(0, x)
    ye, xe = min(h, y + c.h), min(w, x + c.w)
    m[ys:ye, xs:xe] = sub[ys - y:ye - y, xs - x:xe - x]
    return m


def bovenrand_van(q, rijen):
    """De gloeiende bovenrand: de bovenste pixel van het silhouet in vijandkern 7 (rijen = 2: ook het rood eronder)."""
    s = q.solid
    top = s & ~np.vstack([np.zeros((1, q.w), bool), s[:-1]]) & (q.mat == MI["vijandkern"]) & (q.t == 7)
    if rijen == 2:
        top = top | (np.vstack([np.zeros((1, q.w), bool), top[:-1]]) & (q.mat == MI["vijandkern"]))
    return top


def ring_dl(L, L0, m, top, pct=90):
    ring = ndimage.binary_dilation(m, iterations=6) & ~ndimage.binary_dilation(m, iterations=2)
    return abs(float(np.percentile(L[top], pct)) - float(np.median(L0[ring])))


def metingen(KM):
    """ΔL* (bible §7.3, deel 1 §4.2) van de bovenrand (p90), de kern (p90) en het lijf (mediaan) tegen de ring van 2-6 px,
    voor elke vijand op zijn plek uit combat §2.6, in grijs en kleur."""
    rijen = []
    for (id_, typ, wx, wy, kant, wat) in PLEKKEN:
        for staat in ("grijs", "kleur"):
            c = sprite_voor(typ, staat)
            c = gespiegeld(c) if (kant < 0 and typ != "dwaallicht") else c
            x, y = plaats(typ, c, wx, wy, kant, id_)
            zonder = kamerbeeld(KM[id_], id_, staat, [])
            met = kamerbeeld(KM[id_], id_, staat, [(c, x, y)])
            h, w = zonder.shape[:2]
            L, L0 = R.srgb_to_lab(met)[..., 0], R.srgb_to_lab(zonder)[..., 0]
            m = masker(c, x, y, h, w)
            top = masker(c, x, y, h, w, lambda q: bovenrand_van(q, 1))
            kern = masker(c, x, y, h, w, lambda q: (q.mat == MI["vijandkern"]) & (q.t >= 4) & ~bovenrand_van(q, 2))
            lijf = masker(c, x, y, h, w, lambda q: q.mat == MI["vijandlijf"])
            rijen.append(dict(kamer=id_, type=typ, x=wx, wat=wat, staat=staat,
                              bovenrand=ring_dl(L, L0, m, top), kern=ring_dl(L, L0, m, kern),
                              lijf=ring_dl(L, L0, m, lijf, 50)))
    return rijen


def tell_metingen(KM):
    """De tells (deel 1 §4.3) op hun plek: ΔL* van het vlak met en zonder tell (gemiddeld) en van de gezette pixels."""
    uit = []
    gevallen = [("S3", "kadeloper", 1798, 260, 1, "tell_haak", HAAK), ("S3", "schotdrager", 1770, 260, 1, "tell_stoot", STOOT),
                ("S6", "kadeloper", 4340, 260, -1, "tell_haak", HAAK), ("S9", "kadeloper", 1060, 635, -1, "tell_haak", HAAK)]
    for (id_, typ, wx, wy, kant, naam, vl) in gevallen:
        rx, ry = int(B[id_]["rect"][0]), int(B[id_]["rect"][1])
        x0 = wx - rx + (vl[0] if kant > 0 else -vl[2])
        y0 = wy - ry - vl[3]
        for staat in ("grijs", "kleur"):
            z = kamerbeeld(KM[id_], id_, staat, [])
            L0 = R.srgb_to_lab(z)[..., 0]
            for fase in ("vroeg", "laat", "actief"):
                t = tell(vl[2] - vl[0], vl[3] - vl[1], fase)
                img = z.copy()
                D1.stamp_rgba(img, t.render(staat), int(x0), int(y0))
                L = R.srgb_to_lab(img)[..., 0]
                mt = np.zeros(L.shape, bool)
                mt[int(y0):int(y0) + t.h, int(x0):int(x0) + t.w] = True
                gz = masker(t, int(x0), int(y0), *L.shape)
                uit.append(dict(kamer=id_, tell=naam, staat=staat, fase=fase, gem=abs(float(L[mt].mean() - L0[mt].mean())),
                                gezet=abs(float(np.median(L[gz] - L0[gz])))))
    # de duik: het vlak op de landingsplek in S7 (boven het water) en de duiklijn
    for (id_, wx, vloer) in (("S7", 5013, 620), ("S9", 2310, 635)):
        rx, ry = int(B[id_]["rect"][0]), int(B[id_]["rect"][1])
        x0, y0 = wx - rx - DL_W / 2, vloer - ry - DL["duik_hoogte"] - DL_H
        for staat in ("grijs", "kleur"):
            z = kamerbeeld(KM[id_], id_, staat, [])
            L0 = R.srgb_to_lab(z)[..., 0]
            for fase in ("vroeg", "laat"):
                t = tell(DL_W, DL_H, fase)
                img = z.copy()
                D1.stamp_rgba(img, t.render(staat), int(x0), int(y0))
                L = R.srgb_to_lab(img)[..., 0]
                mt = np.zeros(L.shape, bool)
                mt[int(y0):int(y0) + t.h, int(x0):int(x0) + t.w] = True
                gz = masker(t, int(x0), int(y0), *L.shape)
                uit.append(dict(kamer=id_, tell="tell_duik", staat=staat, fase=fase, gem=abs(float(L[mt].mean() - L0[mt].mean())),
                                gezet=abs(float(np.median(L[gz] - L0[gz])))))
    return uit


# ------------------------------------------------------------------ renders
def scene(KM, id_, staat, items, cx, cy, w=200, h=88):
    """Een uitsnede van de kamer met vijanden: items = [(cel, x, y)]; (cx, cy) = midden in kamer-px."""
    img = kamerbeeld(KM[id_], id_, staat, items)
    H, W = img.shape[:2]
    x0 = int(np.clip(cx - w // 2, 0, W - w))
    y0 = int(np.clip(cy - h // 2, 0, H - h))
    return img[y0:y0 + h, x0:x0 + w]


def momenten(KM, staat):
    """Per type de tell-momenten op hun plek: vroeg, laat (pose + vlak), actief (verste frame) en stil."""
    rijen = []
    PK, PS, PD = poses_loper(HAAK[2], None), poses_loper(STOOT[2], "heel"), poses_dwaal()
    for (id_, typ, wx, wy, kant, vl, P, schot) in (("S3", "kadeloper", 1798, 260, 1, HAAK, PK, None),
                                                   ("S3", "schotdrager", 1770, 260, 1, STOOT, PS, "heel")):
        rx, ry = int(B[id_]["rect"][0]), int(B[id_]["rect"][1])
        beelden = []
        for (pose, fase) in ((P["staan"][0], None), (P["aan"][1], "vroeg"), (P["aan"][3], "laat"), (P["slag"][0], "actief"),
                             (P["stil"][1], None)):
            c = loper(staat, pose, schot)
            x, y = plaats(typ, c, wx, wy, kant, id_)
            items = []
            if fase:
                t = tell(vl[2] - vl[0], vl[3] - vl[1], fase)
                items.append((t, int(wx - rx + vl[0]), int(wy - ry - vl[3])))
            items.append((c, x, y))
            beelden.append(scene(KM, id_, staat, items, wx - rx + 10, wy - ry - 14, 96, 56))
        rijen.append((typ, beelden))
    # Dwaallicht in S7: zweven, aanloop vroeg/laat met vlak en lijn, duik (onderaan), stil
    id_, wx = "S7", 5013
    rx, ry = int(B[id_]["rect"][0]), int(B[id_]["rect"][1])
    midden = 620 - DL["baan_hoogte"] - DL_H / 2
    landing = 620 - DL["duik_hoogte"] - DL_H / 2
    beelden = []
    for (pose, fase, my) in ((PD["zweef"][0], None, midden), (PD["aan"][1], "vroeg", midden), (PD["aan"][3], "laat", midden),
                             (PD["duik"][0], "actief", landing), (PD["stil"][0], None, midden)):
        c = dwaallicht(staat, pose)
        x, y = plaats("dwaallicht", c, wx, my, 1, id_)
        items = []
        if fase in ("vroeg", "laat"):
            t = tell(DL_W, DL_H, fase)
            items.append((t, int(wx - rx - DL_W / 2), int(620 - ry - DL["duik_hoogte"] - DL_H)))
            ln = duiklijn(staat, fase)
            n = int(DL["baan_hoogte"] - DL["duik_hoogte"])
            ln2 = Cel((3, n, -1.5, n))
            ln2.mat, ln2.t = ln.mat[:n].copy(), ln.t[:n].copy()
            items.append((ln2, int(wx - rx - 1), int(midden - ry + DL_H / 2)))
        items.append((c, x, y))
        beelden.append(scene(KM, id_, staat, items, wx - rx, 620 - ry - 34, 96, 56))
    rijen.append(("dwaallicht", beelden))
    return rijen


def momenten_blad(KM):
    delen = []
    for staat in ("grijs", "kleur"):
        for typ, beelden in momenten(KM, staat):
            rij = np.concatenate([np.concatenate([b, np.zeros((b.shape[0], 2, 3)) + D1.BG], 1) for b in beelden], 1)
            delen += [D2.label_bar(rij.shape[1], f"{staat.upper()}  {typ.upper()}", "STAAN / AANLOOP VROEG / LAAT / ACTIEF / STIL"), rij]
    return np.concatenate(delen, 0)


def leesbaarheid(KM):
    """Luminantie en deuteranopie (deel 1 §4.2) van de tell-momenten in grijs, en deuteranopie in kleur."""
    delen = []
    g = momenten(KM, "grijs")
    k = momenten(KM, "kleur")
    for (typ, bg), (_, bk) in zip(g, k):
        rg = np.concatenate([np.concatenate([b, np.zeros((b.shape[0], 2, 3)) + D1.BG], 1) for b in bg], 1)
        rk = np.concatenate([np.concatenate([b, np.zeros((b.shape[0], 2, 3)) + D1.BG], 1) for b in bk], 1)
        delen += [D2.label_bar(rg.shape[1], f"LUMINANTIE {typ.upper()}", "GRIJS"), R.grayscale(rg),
                  D2.label_bar(rg.shape[1], f"DEUTERANOPIE {typ.upper()}", "GRIJS"), R.deuteranopia(rg),
                  D2.label_bar(rg.shape[1], f"DEUTERANOPIE {typ.upper()}", "KLEUR"), R.deuteranopia(rk)]
    return np.concatenate(delen, 0)


def kamers_blad(KM):
    """Alle plekken uit combat §2.6 in grijs en kleur, met de vijand op zijn plek (staan/zweven)."""
    per = {}
    for (id_, typ, wx, wy, kant, wat) in PLEKKEN:
        per.setdefault(id_, []).append((typ, wx, wy, kant))
    delen = []
    for id_, lst in per.items():
        rx, ry = int(B[id_]["rect"][0]), int(B[id_]["rect"][1])
        cx = int(np.mean([wx for _, wx, _, _ in lst])) - rx
        cy = int(np.mean([wy for _, _, wy, _ in lst])) - ry - 20
        w = max(160, int(max(wx for _, wx, _, _ in lst) - min(wx for _, wx, _, _ in lst)) + 96)
        w = min(w, 320)
        beelden = []
        for staat in ("grijs", "kleur"):
            items = []
            for (typ, wx, wy, kant) in lst:
                c = sprite_voor(typ, staat)
                c = gespiegeld(c) if (kant < 0 and typ != "dwaallicht") else c
                items.append((c, *plaats(typ, c, wx, wy, kant, id_)))
            beelden.append(scene(KM, id_, staat, items, cx, cy, w, 80))
        rij = np.concatenate([beelden[0], np.zeros((80, 4, 3)) + D1.BG, beelden[1]], 1)
        delen.append((id_, rij))
    W = max(r.shape[1] for _, r in delen)
    out = []
    for id_, r in delen:
        r = np.concatenate([r, np.zeros((r.shape[0], W - r.shape[1], 3)) + D1.BG], 1)
        out += [D2.label_bar(W, f"{id_}", "GRIJS  |  KLEUR"), r]
    return np.concatenate(out, 0)


def gif(KM, pad):
    """Drie panelen naast elkaar (grijs, de toestand van het gevecht): de Kadeloper en de Schotdrager in S3,
    het Dwaallicht in S7. Elk speelt zijn animaties op de tijden van het manifest; 20 beelden per seconde."""
    PK, PS, PG, PD = poses_loper(HAAK[2], None), poses_loper(STOOT[2], "heel"), poses_loper(STOOT[2], "stuk"), poses_dwaal()
    staat = "grijs"

    def seq_loper(P, schot, vl, extra=()):
        s = []
        A = int(KL["aanloop"])
        for t in range(96):
            s.append(("lopen", P["loop"][(t // 8) % 6], t * 0.5, None, schot))
        x = 48
        for t in range(24):
            s.append(("staan", P["staan"][(t // 12) % 4], x, None, schot))
        tk = verdeel(A - 3, 4) + [3]
        grenzen = np.cumsum(tk)
        for t in range(A):
            f = int(np.searchsorted(grenzen, t, side="right"))
            s.append(("aanloop", P["aan"][f], x, "vroeg" if t < A / 2 else "laat", schot))
        for t in range(6):
            s.append(("actief", P["slag"][t // 3], x, "actief", schot))
        for t in range(20):
            s.append(("herstel", P["herstel"][t // 10], x, None, schot))
        for t in range(30):
            s.append(("stil na treffer", P["stil"][0 if t < 4 else (1 if t < 22 else 2)], x, None, schot))
        s += list(extra)
        return s

    sd_extra = [("tink", PS["staan"][0], 48, None, "tink")] * 4 + [("breuk", ("breuk", t // 4), 48, None, None) for t in range(12)] + \
               [("gebroken", PG["staan"][(t // 12) % 4], 48, None, "stuk") for t in range(24)] + \
               [("dood", ("dood", t // 6), 48, None, "stuk") for t in range(48)]
    kl_extra = [("dood", ("dood", t // 6), 48, None, None) for t in range(48)] + \
               [("uit de stoom", ("stoom", t // 6), 48, None, None) for t in range(30)]
    seqs = [("KADELOPER", "S3", 1720, 260, HAAK, seq_loper(PK, None, HAAK, kl_extra)),
            ("SCHOTDRAGER", "S3", 1720, 260, STOOT, seq_loper(PS, "heel", STOOT, sd_extra))]
    # het Dwaallicht
    A = int(DL["aanloop"])
    midden = 620 - DL["baan_hoogte"] - DL_H / 2
    landing = 620 - DL["duik_hoogte"] - DL_H / 2
    ds = []
    for t in range(96):
        ds.append(("zweven", PD["zweef"][(t // 8) % 6], 5013 - 16, midden, None))
    tk = verdeel(A - 3, 4) + [3]
    grenzen = np.cumsum(tk)
    for t in range(A):
        f = int(np.searchsorted(grenzen, t, side="right"))
        ds.append(("aanloop", PD["aan"][f], 5013 - 16, midden, "vroeg" if t < A / 2 else "laat"))
    for t in range(8):
        ds.append(("duik", PD["duik"][t // 4], 5013 - 16, midden + (landing - midden) * (t + 1) / 8, "actief"))
    for t in range(40):
        ds.append(("terug", PD["terug"][t // 10], 5013 - 16, landing + (midden - landing) * (t + 1) / 40, None))
    for t in range(30):
        ds.append(("stil na treffer", PD["stil"][t // 5], 5013 - 16, midden, None))
    for t in range(48):
        ds.append(("dood", PD["dood"][t // 6], 5013 - 16, midden, None))
    n = max(len(seqs[0][5]), len(seqs[1][5]), len(ds))
    cache = {}

    def cel_loper(pose, schot):
        if isinstance(pose, tuple):
            soort, i = pose
            key = (soort, i, schot)
            if key not in cache:
                if soort == "breuk":
                    cache[key] = breuk(staat, i, PG)
                elif soort == "stoom":
                    cache[key] = uit_stoom(staat, i, None)
                else:
                    P = PG if schot == "stuk" else PK
                    cache[key] = smelt(loper(staat, P["stil"][1], schot), [0.0, 0.15, 0.3, 0.45, 0.6, 0.75][i], staat, i) \
                        if i < 6 else plas_rest(staat, i - 6)
            return cache[key]
        key = (id(pose), schot)
        if key not in cache:
            cache[key] = loper(staat, pose, schot)
        return cache[key]

    def cel_dwaal(pose):
        key = ("d", id(pose))
        if key not in cache:
            cache[key] = dwaallicht(staat, pose)
        return cache[key]

    kamer_cache = {}
    frames = []
    for t in range(0, n, 3):
        panelen = []
        for (naam, id_, x_start, vloer, vl, s) in seqs:
            rx, ry = int(B[id_]["rect"][0]), int(B[id_]["rect"][1])
            wat, pose, dx, fase, schot = s[min(t, len(s) - 1)]
            wx = x_start + dx
            c = cel_loper(pose, schot if schot != "tink" else "tink")
            x, y = plaats("kadeloper", c, wx, vloer, 1, id_)
            items = []
            if fase:
                tt = tell(vl[2] - vl[0], vl[3] - vl[1], fase)
                items.append((tt, int(wx - rx + vl[0]), int(vloer - ry - vl[3])))
            items.append((c, x, y))
            if id_ not in kamer_cache:
                kamer_cache[id_] = kamerbeeld(KM[id_], id_, staat, [])
            img = kamer_cache[id_].copy()
            for (q, qx, qy) in items:
                D1.stamp_rgba(img, q.render(staat), qx, qy)
            cx, cy = x_start + 48 - rx + 6, vloer - ry - 20
            sub = img[int(cy - 36):int(cy + 36), int(cx - 64):int(cx + 64)]
            panelen.append(np.concatenate([D2.label_bar(128, naam, wat.upper()), sub], 0))
        id_ = "S7"
        rx, ry = int(B[id_]["rect"][0]), int(B[id_]["rect"][1])
        wat, pose, wx, wy, fase = ds[min(t, len(ds) - 1)]
        c = cel_dwaal(pose)
        x, y = plaats("dwaallicht", c, wx, wy, 1, id_)
        if id_ not in kamer_cache:
            kamer_cache[id_] = kamerbeeld(KM[id_], id_, staat, [])
        img = kamer_cache[id_].copy()
        if fase in ("vroeg", "laat"):
            D1.stamp_rgba(img, tell(DL_W, DL_H, fase).render(staat), int(wx - rx - DL_W / 2), int(620 - ry - DL["duik_hoogte"] - DL_H))
            ln = duiklijn(staat, fase).render(staat)[:int(DL["baan_hoogte"] - DL["duik_hoogte"])]
            D1.stamp_rgba(img, ln, int(wx - rx - 1), int(midden - ry + DL_H / 2))
        D1.stamp_rgba(img, c.render(staat), x, y)
        cx, cy = wx - rx, 620 - ry - 34
        sub = img[int(cy - 36):int(cy + 36), int(cx - 64):int(cx + 64)]
        panelen.append(np.concatenate([D2.label_bar(128, "DWAALLICHT", wat.upper()), sub], 0))
        beeld = np.concatenate([np.concatenate([p, np.zeros((p.shape[0], 2, 3)) + D1.BG], 1) for p in panelen], 1)
        beeld = np.concatenate([D2.label_bar(beeld.shape[1], "S-13 GRIJS", f"TICK {t}"), beeld], 0)
        big = np.repeat(np.repeat(beeld, 2, 0), 2, 1)
        frames.append(Image.fromarray((np.clip(big, 0, 1) * 255 + 0.5).astype(np.uint8)))
    frames[0].save(pad, save_all=True, append_images=frames[1:], duration=50, loop=0, optimize=True)
    return len(frames), n


# ------------------------------------------------------------------ main
def main():
    print("Slice-vijanden: sprites en animaties (S-13)")
    alle = {"kadeloper": bouw_kadeloper(), "schotdrager": bouw_schotdrager(), "dwaallicht": bouw_dwaallicht()}
    koppeling = {
        "kadeloper": {
            "lopen / staan": "lopen als hij beweegt (v > 0), anders staan; kijkrichting = facing (flip_h en offset_links)",
            "_start_windup (Phase.WINDUP)": "haak_aanloop op windup_progress; tell_haak vroeg/laat op _walker_box() van dat moment",
            "Phase.ACTIVE": "haak_slag; tell_haak actief (onder de sprite: z 1 tegen 0 mag ook, het vlak blijft zichtbaar vóór hem)",
            "Phase.RECOVER": "haak_herstel, daarna lopen",
            "stun (VJ-04)": "stil (30 ticks), daarna lopen of staan",
            "dood (levens 0)": "dood (48 ticks), daarna niets meer tekenen",
            "add uit een spuigat": "uit_stoom (add_inactief 30) op de plek van het spuigat, daarna lopen",
            "verlicht (s = 2, VJ-06)": "de kleur-atlas (rand en kern een tint zachter); aanloop met ticks_verlicht (40), lopen trager in de tijd",
        },
        "schotdrager": {
            "armor_intact": "staan / lopen / stoot_aanloop / stoot_actief / stoot_herstel / stil; tell_stoot op _walker_box()",
            "tink(tick)": "tink (4 ticks), daarna terug naar wat hij deed",
            "break_armor(tick)": "breuk (12), daarna gebroken_*; zet `stuk` als losse Sprite2D op de node-positie van dat moment",
            "na de breuk": "gebroken_staan / gebroken_lopen / gebroken_aanloop / gebroken_actief / gebroken_herstel / gebroken_stil",
            "dood": "dood (48 ticks); hij kan alleen gebroken sterven",
        },
        "dwaallicht": {
            "zweven (op zijn baan)": "zweven",
            "Phase.WINDUP": "aanloop op windup_progress; tell_duik vroeg/laat op de landingsplek en de duiklijn tussen hem en het vlak",
            "Phase.ACTIVE (de duik, 8)": "duik; de code verschuift de node, de sprite volgt",
            "Phase.RECOVER (terug, 40)": "terug, daarna zweven",
            "stun (VJ-04)": "stil (30)",
            "dood": "dood (48 ticks)",
        },
    }
    rand_fout, nfr = 0, 0
    for typ, bladen in alle.items():
        manifest = dict(
            versie="0.1", eigenaar="Animator", issue=272,
            bron="docs/art/slice/bron/genereer_vijanden.py",
            maten="uit game/data/vijanden/slice.csv (groep " + typ + ") en game/scripts/combat/slice_enemy.gd",
            knoop="De vijand-node staat in het midden van de hurtbox (slice_enemy.gd: position = (x, vloer - hoogte/2)). "
                  "`offset` = linksboven van een cel in node-coördinaten (Sprite2D, centered = false), kijkrichting rechts.",
            ticks="per frame, in ticks van 60 per seconde (= frames bij 60 fps); `stuurt` zegt welke vlag het frame kiest, "
                  "als het niet op tijd loopt",
            bladen={},
        )
        for naam, b in bladen.items():
            e = b.export()
            e.update(PLAATSING[naam])
            manifest["bladen"][naam] = e
            rand_fout += b.rand_fout
            nfr += sum(len(a["frames"]) for a in e["animaties"].values())
            for s in STATEN + ["index"]:
                schrijf_import(typ, e["bestanden"][s])
        manifest["koppeling"] = koppeling[typ]
        manifest["import"] = dict(map=f"res://art/animatie/{typ}/",
                                  texture="Lossless, mipmaps uit, filter Nearest op het CanvasItem, repeat uit (zoals de Gemaalmeester)",
                                  toestanden="grijs en half = donkere wijk (s < 2: rand en kern feller, VJ-06) / kleur = verlicht; "
                                             "index = R materiaal-id, G tint*32+16, A 255")
        with open(os.path.join(REPO, "game", "art", "animatie", typ, f"{typ}.json"), "w") as f:
            json.dump(manifest, f, indent=1, ensure_ascii=False)
    print(f"  {nfr} frames per toestand; pixels op de rand van een cel: {rand_fout} (eis #267: 0)")

    # overzichtsbladen
    for staat in ("grijs", "kleur"):
        b = {f"{t}/{n}": bl for t, d in alle.items() for n, bl in d.items() if not n.startswith(("tell", "duik"))}
        D2.save(GMM.blad_overzicht(b, staat), os.path.join(UIT_DOCS, f"vijanden_bladen_{staat}_x2.png"), 2)
    KM = kamers()
    D2.save(momenten_blad(KM), os.path.join(UIT_DOCS, "vijanden_tells_x3.png"), 3)
    D2.save(leesbaarheid(KM), os.path.join(UIT_DOCS, "vijanden_leesbaarheid_x2.png"), 2)
    D2.save(kamers_blad(KM), os.path.join(UIT_DOCS, "vijanden_in_de_kamers_x2.png"), 2)

    met = metingen(KM)
    print("  ΔL* tegen de ring van 2-6 px (bible §6 regel 4, deel 1 §4.2): bovenrand p90 / kern p90 / lijf mediaan")
    for r in met:
        print(f"    {r['kamer']} {r['type']:11s} x {r['x']:5.0f} {r['wat']:20s} {r['staat']:6s} "
              f"{r['bovenrand']:5.1f} {r['kern']:5.1f} {r['lijf']:5.1f}")
    tm = tell_metingen(KM)
    print("  tells: ΔL* van het vlak met/zonder tell (gemiddeld) / van de gezette pixels (mediaan)")
    for r in tm:
        print(f"    {r['kamer']} {r['tell']:10s} {r['staat']:6s} {r['fase']:6s} {r['gem']:5.1f} {r['gezet']:5.1f}")
    nb, nt = gif(KM, os.path.join(UIT_DOCS, "vijanden_animaties.gif"))
    print(f"  GIF: {nb} beelden, {nt} ticks ({nt / 60:.1f} s)")
    return met, tm


if __name__ == "__main__":
    main()
