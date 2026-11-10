"""UI-art Polderlight, T10 deel 3 (#87): menu-art, knop-glyphs per apparaat, Godot Theme.

Eigen werk van de UI Artist. Geen externe assets, geen logo's of merkiconen van derden:
de glyphs zijn generieke vormen (schijf, pil, kruis, letters uit Polderletter of een eigen 3x5-letter).
Draait vanaf de repo-root, na genereer_ui.py (dat het lettertype en de HUD maakt):

    python3 docs/art/ui/bron/genereer_menu.py

Schrijft:
  game/art/ui/menu/      keuzebalk, tabs, schuif, keuzepijlen, herbind-cellen, scrollbalk, paneel, zijband
  game/art/ui/glyphs/    knop-glyphs per apparaat (toetsenbord, xbox, playstation, deck), normaal en groot
  game/art/ui/font/      polderletter_titel (x2) en polderletter_naam (x3), geschaald uit normaal
  game/art/ui/thema/     polderlight_menu.tres en polderlight_menu_groot.tres (Godot 4.6 Theme)
  docs/art/ui/           mock-ups per scherm (x2) en twee overzichtsbladen (x4)
en print de tekstmeting van de menu's (docs/art/ui-stijlgids.md par. 12.5).

Indeling en teksten volgen docs/ux/hud-menus.md par. 4 en de wireframes in docs/ux/wireframes/.
"""
import os
import re
import sys
import tempfile

import numpy as np
from PIL import Image

HIER = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HIER)
import genereer_ui as U  # noqa: E402
import polderletter as PL  # noqa: E402

from genereer_ui import C, WIT, LUCHT, GLOED, IJZER, doek, zet, vul, rechthoek, uit_raster, rand_van, over, tekst  # noqa: E402,E501

ROOT, GAME, DOCS = U.ROOT, U.GAME, U.DOCS
K = C["K"]
GEMAAKT = U.GEMAAKT
DIM_ALFA = 0.72            # verduistering van de wereld achter pauze en opties (ColorRect, lucht 0)


# ================================================================== hulp
def masker_rond(w, h, r):
    """Afgeronde rechthoek met pixelhoeken; r = straal (0-4)."""
    trap = {0: [], 1: [1], 2: [2, 1], 3: [3, 1, 1], 4: [4, 2, 1, 1]}[r]
    m = np.ones((h, w), bool)
    for i, n in enumerate(trap):
        m[i, :n] = m[i, w - n:] = False
        m[h - 1 - i, :n] = m[h - 1 - i, w - n:] = False
    return m


def schijf(S):
    yy, xx = np.mgrid[0:S, 0:S]
    c = (S - 1) / 2
    return np.hypot(xx - c, yy - c) <= S / 2 - 0.35


def negen4(a9, w, h, l, t, r, b):
    """9-slice uitrekken met vier marges (zoals StyleBoxTexture met stretch)."""
    H9, W9 = a9.shape[:2]
    cw, ch = W9 - l - r, H9 - t - b
    xs = list(range(l)) + [l + (i * cw) // max(1, w - l - r) for i in range(w - l - r)] + list(range(W9 - r, W9))
    ys = list(range(t)) + [t + (i * ch) // max(1, h - t - b) for i in range(h - t - b)] + list(range(H9 - b, H9))
    return a9[np.ix_(ys, xs)].copy()


def bewaar(a, *pad):
    return U.bewaar(a, *pad)


def preview(a, naam, schaal):
    U.preview(a, naam, schaal)


def masker_tekst(s, grootte="normaal"):
    w = max(1, PL.text_width(s, grootte))
    g = PL.GROOTTES[grootte]
    h = g["cap"] + g["desc"]
    img = np.zeros((h, w, 3), np.uint8)
    PL.draw(img, s, 0, 0, (255, 255, 255), grootte)
    m = img[..., 0] > 0
    # alleen de hoogte van de hoofdletter (knoplabels hebben geen onderstok)
    return m[:g["cap"]]


def plak(a, m, col, x=None, y=None):
    """Masker gecentreerd (of op x, y) in a."""
    H, W = a.shape[:2]
    h, w = m.shape
    x = (W - w) // 2 if x is None else x
    y = (H - h) // 2 if y is None else y
    vul(a, m, col, ox=x, oy=y)


def ras(rows):
    return np.array([[c == "#" for c in r] for r in rows], bool)


# ================================================================== 1. menu-onderdelen
GLOED_FILL_ALFA = 0.70     # warme vulling van de keuzebalk (doorschijnend, zoals plaat en kader)


def keuzebalk(staat="focus"):
    """Keuzebalk (focus) 9x9, marge 3. Licht aan op de gekozen regel: rand gloed, warme vulling."""
    a = doek(9, 9)
    m = masker_rond(9, 9, 1)
    vul(a, rand_van(m), K)
    binnen = np.zeros((9, 9), bool)
    binnen[1:8, 1:8] = True
    if staat == "focus":
        rand, boven, onder, vulc, alfa = GLOED[5], GLOED[6], GLOED[3], GLOED[0], GLOED_FILL_ALFA
    elif staat == "ingedrukt":     # ingezakt: bovenrand donker, vulling dichter
        rand, boven, onder, vulc, alfa = GLOED[4], GLOED[3], GLOED[5], GLOED[1], 0.92
    else:                          # hover met de muis zonder focus: zelfde vorm, rand gevel wit
        rand, boven, onder, vulc, alfa = WIT[4], WIT[5], WIT[3], LUCHT[1], 0.78
    vul(a, binnen, vulc, int(round(alfa * 255)))
    vul(a, rand_van(binnen), rand)
    rechthoek(a, 2, 1, 5, 1, boven)
    rechthoek(a, 2, 7, 5, 1, onder)
    return a


def lamp():
    """Aanwijzer: het lantaarntje van de HUD (7x9), licht alleen op de gekozen regel."""
    return U.lantaarn("vol")


def leeg_1x1():
    return doek(1, 1)


def tab_gekozen():
    """Gekozen tab, 9x9, marge 3: rand gevel wit 6 boven en opzij, onder open (staat op de tablijn)."""
    a = doek(9, 9)
    m = np.ones((9, 9), bool)
    m[0, 0] = m[0, 8] = False
    vul(a, m, LUCHT[1], int(round(U.KADER_ALFA * 255)))
    rechthoek(a, 1, 0, 7, 1, K)
    rechthoek(a, 0, 1, 1, 8, K)
    rechthoek(a, 8, 1, 1, 8, K)
    rechthoek(a, 1, 1, 7, 1, WIT[7])
    rechthoek(a, 1, 2, 1, 7, WIT[6])
    rechthoek(a, 7, 2, 1, 7, WIT[5])
    return a


def tab_paneel():
    """Paneel onder de tabs, 5x5 marge 2: alleen de tablijn (gevel wit 3) bovenaan."""
    a = doek(5, 5)
    rechthoek(a, 0, 0, 5, 1, WIT[3])
    return a


def schuif_baan():
    """Schuif (HSlider): leeg glas zoals de lichtmeter, 7x7, marge 3."""
    a = doek(7, 7)
    m = masker_rond(7, 7, 1)
    vul(a, m, LUCHT[3])
    vul(a, rand_van(m), K)
    rechthoek(a, 1, 1, 5, 1, LUCHT[4])
    return a


def schuif_vulling(gedimd=False):
    a = doek(7, 7)
    m = masker_rond(7, 7, 1)
    g = (GLOED[6], GLOED[5], GLOED[3]) if not gedimd else (WIT[6], WIT[5], WIT[4])
    vul(a, m, g[1])
    rechthoek(a, 1, 1, 5, 1, g[0])
    rechthoek(a, 1, 5, 5, 1, g[2])
    vul(a, rand_van(m), K)
    return a


def schuif_greep(staat="normaal"):
    """Greep 5x11: ijzeren klem (normaal), gloeiend bij focus/hover, gedoofd bij uit."""
    a = doek(5, 11)
    m = masker_rond(5, 11, 1)
    kl = {"normaal": (WIT[7], WIT[6], WIT[4]), "focus": (GLOED[7], GLOED[5], GLOED[3]),
          "uit": (WIT[4], WIT[3], WIT[2])}[staat]
    vul(a, m, kl[1])
    rechthoek(a, 1, 1, 3, 1, kl[0])
    rechthoek(a, 1, 1, 1, 8, kl[0])
    rechthoek(a, 1, 9, 3, 1, kl[2])
    rechthoek(a, 1, 5, 3, 1, kl[2])           # inkeping in het midden
    vul(a, rand_van(m), K)
    return a


PIJL = ["..#", ".##", "###", ".##", "..#"]


def keuzepijl(richting="links", focus=False):
    """< en > bij een keuzewaarde (bv. < Vasthouden >), 5x7 met contour."""
    m = ras(PIJL)
    if richting == "rechts":
        m = m[:, ::-1]
    a = doek(5, 7)
    mm = np.zeros((7, 5), bool)
    mm[1:6, 1:4] = m
    vul(a, U.ring_om(mm, diag=False), K)
    vul(a, mm, GLOED[6] if focus else WIT[5])
    return a


def herbind_wacht():
    """Cel die wacht op een nieuwe knop (MENU_PRESS_KEY): vol gloed, tekst bijna-zwart. 7x7, marge 2."""
    a = doek(7, 7)
    m = masker_rond(7, 7, 1)
    vul(a, m, GLOED[5])
    rechthoek(a, 1, 1, 5, 1, GLOED[6])
    rechthoek(a, 1, 5, 5, 1, GLOED[3])
    vul(a, rand_van(m), K)
    return a


def cel_focus():
    """Gekozen kolom binnen de gekozen herbind-regel: open rand gloed 6. 7x7, marge 2."""
    a = doek(7, 7)
    m = masker_rond(7, 7, 1)
    vul(a, rand_van(m), K)
    b = np.zeros((7, 7), bool)
    b[1:6, 1:6] = True
    vul(a, rand_van(b), GLOED[6])
    return a


def scroll_baan():
    a = doek(5, 7)
    m = masker_rond(5, 7, 1)
    vul(a, m, LUCHT[3])
    rechthoek(a, 1, 1, 1, 5, LUCHT[4])
    vul(a, rand_van(m), K)
    return a


def scroll_greep(staat="normaal"):
    a = doek(5, 7)
    m = masker_rond(5, 7, 1)
    kl = {"normaal": (WIT[6], WIT[5]), "hover": (WIT[7], WIT[6]), "vast": (GLOED[6], GLOED[5])}[staat]
    vul(a, m, kl[1])
    rechthoek(a, 1, 1, 1, 5, kl[0])
    vul(a, rand_van(m), K)
    return a


def paneel():
    """Dialoog (bevestigen, 'Bezet door ...'): ijzeren rand van 2 px met klinknagels, plaat 85 %. 11x11, marge 4."""
    a = doek(11, 11)
    rechthoek(a, 0, 0, 11, 11, LUCHT[1], int(round(0.85 * 255)))
    m = masker_rond(11, 11, 1)
    a[~m] = 0
    vul(a, rand_van(m), K)
    b1 = np.zeros((11, 11), bool)
    b1[1:10, 1:10] = True
    r1 = rand_van(b1)
    vul(a, r1, IJZER[6])
    b2 = np.zeros((11, 11), bool)
    b2[2:9, 2:9] = True
    r2 = rand_van(b2)
    vul(a, r2, IJZER[5])
    # licht van boven: bovenste en linker band lichter, onderste en rechter donkerder
    rechthoek(a, 1, 1, 9, 1, IJZER[7])
    rechthoek(a, 1, 9, 9, 1, IJZER[4])
    rechthoek(a, 9, 2, 1, 7, IJZER[4])
    b3 = np.zeros((11, 11), bool)
    b3[3:8, 3:8] = True
    vul(a, rand_van(b3), K, 160)
    for (x, y) in ((2, 2), (8, 2), (2, 8), (8, 8)):
        zet(a, y, x, WIT[5])                   # klinknagel
    return a


def zijband():
    """Band links achter hoofdmenu en pauze: plaat 78 % met een rand gevel wit 2 rechts. 5x5, marge 2."""
    a = doek(5, 5)
    rechthoek(a, 0, 0, 5, 5, LUCHT[1], int(round(U.KADER_ALFA * 255)))
    rechthoek(a, 4, 0, 1, 5, WIT[2])
    return a


# ================================================================== 2. knop-glyphs
# Formaat: normaal 11 px hoog (bij Polderletter normaal, regel 11), groot 15 px (bij groot, regel 16).
# Kleuren: lijf ijzer, symbool gevel wit 7, contour bijna-zwart. Geen merkkleuren: het apparaat
# herken je aan de vorm en de letter; de kleur blijft bij de HUD (gloed = licht, amber/cyaan = speler).
MICRO = {  # 3x5, voor labels op schouders, sticks en grepen (normaal)
    "L": ["#..", "#..", "#..", "#..", "###"], "R": ["##.", "#.#", "##.", "#.#", "#.#"],
    "B": ["##.", "#.#", "##.", "#.#", "##."], "T": ["###", ".#.", ".#.", ".#.", ".#."],
    "1": [".#.", "##.", ".#.", ".#.", "###"], "2": ["##.", "..#", ".#.", "#..", "###"],
    "3": ["##.", "..#", ".#.", "..#", "##."], "4": ["#.#", "#.#", "###", "..#", "..#"],
    "5": ["###", "#..", "##.", "..#", "##."],
}
LETTER5 = {
    "A": [".###.", "#...#", "#####", "#...#", "#...#"], "B": ["####.", "#...#", "####.", "#...#", "####."],
    "X": ["#...#", ".#.#.", "..#..", ".#.#.", "#...#"], "Y": ["#...#", ".#.#.", "..#..", "..#..", "..#.."],
}
PS5 = {
    "kruis": ["#...#", ".#.#.", "..#..", ".#.#.", "#...#"],
    "rondje": [".###.", "#...#", "#...#", "#...#", ".###."],
    "vierkant": ["#####", "#...#", "#...#", "#...#", "#####"],
    "driehoek": ["..#..", ".#.#.", ".#.#.", "#...#", "#####"],
}
PS7 = {
    "kruis": ["#.....#", ".#...#.", "..#.#..", "...#...", "..#.#..", ".#...#.", "#.....#"],
    "rondje": ["..###..", ".#...#.", "#.....#", "#.....#", "#.....#", ".#...#.", "..###.."],
    "vierkant": ["#######", "#.....#", "#.....#", "#.....#", "#.....#", "#.....#", "#######"],
    "driehoek": ["...#...", "..#.#..", "..#.#..", ".#...#.", ".#...#.", "#.....#", "#######"],
}
SYM = {
    ("menu", 5): ["#####", ".....", "#####", ".....", "#####"],
    ("menu", 7): ["#######", ".......", "#######", ".......", "#######"],
    ("create", 5): ["#.#.#", "#.#.#", "#.#.#", "#.#.#", "#.#.#"],
    ("create", 7): ["#..#..#", "#..#..#", "#..#..#", "#..#..#", "#..#..#"],
    ("view", 5): ["####..", "#..###", "#..#.#", "####.#", "..####"],
    ("view", 7): ["#####..", "#...###", "#...#.#", "#...#.#", "#####.#", ".#....#", ".######"],
    ("op", 5): ["..#..", ".###.", "#####", "..#..", "..#.."],
    ("op", 7): ["...#...", "..###..", ".#####.", "#######", "...#...", "...#...", "...#..."],
}
GLYPH_KLEUR = {
    "std": dict(lijf=IJZER[5], licht=IJZER[7], schaduw=IJZER[3], sym=WIT[7]),
    "deck": dict(lijf=IJZER[3], licht=IJZER[5], schaduw=IJZER[2], sym=WIT[7]),
}


def label_masker(s, groot):
    if not groot:
        ms = [ras(MICRO[c]) for c in s]
        w = sum(m.shape[1] for m in ms) + len(ms) - 1
        out = np.zeros((5, w), bool)
        x = 0
        for m in ms:
            out[:, x:x + m.shape[1]] = m
            x += m.shape[1] + 1
        return out
    return masker_tekst(s, "normaal")


def letter_masker(ch, groot):
    return masker_tekst(ch, "normaal") if groot else ras(LETTER5[ch])


def lijf(a, m, kl):
    vul(a, m, kl["lijf"])
    r = rand_van(m)
    vul(a, r, K)
    binnen = m & ~r
    rb = rand_van(binnen)
    ys, xs = np.nonzero(rb)
    h = a.shape[0]
    for y, x in zip(ys, xs):
        zet(a, y, x, kl["licht"] if y < h / 2 else kl["schaduw"])


def g_rond(sym_m, groot, kl):
    S = 15 if groot else 11
    a = doek(S, S)
    lijf(a, schijf(S), kl)
    plak(a, sym_m, kl["sym"])
    return a


def g_pil(s, groot, kl, vorm="schouder"):
    """Schouder (LB/L1), trekker (LT/L2) of greep (L4/L5): breedte volgt het label."""
    lm = label_masker(s, groot)
    h = 15 if groot else 11
    w = lm.shape[1] + (8 if groot else 6)
    a = doek(w, h)
    if vorm == "schouder":           # plat en breed: 2 px lager aan de bovenkant
        m = np.zeros((h, w), bool)
        top = 2
        m[top:, :] = masker_rond(w, h - top, 2 if groot else 1)
    elif vorm == "trekker":          # hoge, ronde bovenkant
        m = masker_rond(w, h, 4 if groot else 3)
        m[h - 2:, :] = masker_rond(w, h, 1)[h - 2:, :]
    else:                            # greep achterop (Deck L4/L5/R4/R5): rechthoek met schuine hoek
        m = masker_rond(w, h, 1)
        for i in range(3 if groot else 2):
            m[i, :(3 if groot else 2) - i] = False
    lijf(a, m, kl)
    ys, xs = np.nonzero(m)
    cy = (ys.min() + ys.max() + 1) // 2
    plak(a, lm, kl["sym"], y=cy - (lm.shape[0] + 1) // 2)
    return a


def g_klein(sym, groot, kl, breed=False):
    """Kleine pil voor Menu / View / Options / Create."""
    h = 15 if groot else 11
    w = (19 if groot else 13) if breed else h
    a = doek(w, h)
    m = masker_rond(w, h, 4 if groot else 3)
    lijf(a, m, kl)
    plak(a, ras(SYM[(sym, 7 if groot else 5)]), kl["sym"])
    return a


def g_touchpad(groot, kl):
    h = 15 if groot else 11
    w = 25 if groot else 19
    a = doek(w, h)
    m = masker_rond(w, h, 2)
    lijf(a, m, kl)
    d = 3
    plak(a, np.ones((d, d), bool) & ~np.array([[1, 0, 1], [0, 0, 0], [1, 0, 1]], bool), kl["sym"])
    return a


def g_dpad(richting, groot, kl):
    S = 15 if groot else 11
    arm = 7 if groot else 5
    a = doek(S, S)
    m = np.zeros((S, S), bool)
    o = (S - arm) // 2
    m[o:o + arm, :] = True
    m[:, o:o + arm] = True
    vul(a, m, kl["lijf"])
    vul(a, rand_van(m), K)
    binnen = m & ~rand_van(m)
    # gekozen richting licht op
    sel = np.zeros_like(m)
    c0, c1 = o + 1, o + arm - 1
    if richting in ("op", "alle"):
        sel[1:o + 1, c0:c1] = True
    if richting in ("neer", "alle"):
        sel[S - o - 1:S - 1, c0:c1] = True
    if richting in ("links", "alle"):
        sel[c0:c1, 1:o + 1] = True
    if richting in ("rechts", "alle"):
        sel[c0:c1, S - o - 1:S - 1] = True
    if richting in ("verticaal",):
        sel[1:o + 1, c0:c1] = True
        sel[S - o - 1:S - 1, c0:c1] = True
    if richting in ("horizontaal",):
        sel[c0:c1, 1:o + 1] = True
        sel[c0:c1, S - o - 1:S - 1] = True
    vul(a, sel & binnen, WIT[7] if richting != "alle" else kl["licht"])
    zet(a, S // 2, S // 2, kl["schaduw"])
    return a


def g_stick(zijde, groot, kl, klik=False):
    S = 15 if groot else 11
    a = doek(S, S)
    lijf(a, schijf(S), dict(kl, lijf=kl["schaduw"]))
    kap = np.zeros((S, S), bool)
    kap[2:S - 2, 2:S - 2] = schijf(S - 4)
    vul(a, kap, WIT[6] if klik else kl["licht"])
    if klik:
        vul(a, rand_van(kap), K)
    lm = label_masker(zijde, groot)
    plak(a, lm, K if klik else kl["sym"])
    return a


def g_trackpad(zijde, groot, kl):
    S = 15 if groot else 11
    a = doek(S, S)
    m = masker_rond(S, S, 2)
    lijf(a, m, kl)
    lm = label_masker(zijde, groot)
    plak(a, lm, kl["sym"])
    return a


# --- toetsenbord en muis
def toetskap(groot=False, ingedrukt=False):
    """Toetskap 9-slice. Normaal 7x11 (marges l3 t3 r3 b3), groot 9x16 (l4 t4 r4 b4)."""
    w, h = (9, 16) if groot else (7, 11)
    diep = 2 if groot else 1
    a = doek(w, h)
    m = masker_rond(w, h, 1)
    vul(a, m, IJZER[5] if not ingedrukt else IJZER[4])
    vul(a, rand_van(m), K)
    rechthoek(a, 1, 1, w - 2, 1, IJZER[7] if not ingedrukt else IJZER[5])
    rechthoek(a, 1, 2, 1, h - 3 - diep, IJZER[6] if not ingedrukt else IJZER[5])
    rechthoek(a, 1, h - 1 - diep, w - 2, diep, IJZER[3])
    return a


def toets_met(s_of_m, groot=False):
    """Toetskap met tekst (voor previews en vaste iconen); s_of_m = tekst of masker."""
    tk = toetskap(groot)
    g = "groot" if groot else "normaal"
    if isinstance(s_of_m, str):
        tw = PL.text_width(s_of_m, g)
    else:
        tw = s_of_m.shape[1]
    w = max(tk.shape[0], tw + (8 if groot else 6))
    a = negen4(tk, w, tk.shape[0], *((4, 4, 4, 4) if groot else (3, 3, 3, 3)))
    if isinstance(s_of_m, str):
        img = a[..., :3].copy()
        PL.draw(img, s_of_m, (w - tw) // 2, 2 if not groot else 3, WIT[7], g)
        diff = np.any(img != a[..., :3], -1)
        a[diff, :3] = img[diff]
    else:
        h = tk.shape[0] - (2 if groot else 1)
        plak(a, s_of_m, WIT[7], y=(h - s_of_m.shape[0]) // 2)
    return a


def g_pijltoets(richting, groot):
    m = ras(SYM[("op", 7 if groot else 5)])
    k = {"op": 0, "rechts": 3, "neer": 2, "links": 1}[richting]
    m = np.rot90(m, k)
    return toets_met(m, groot)


def g_muis(knop, groot):
    w, h = (11, 15) if groot else (9, 11)
    a = doek(w, h)
    m = masker_rond(w, h, 3 if groot else 2)
    vul(a, m, IJZER[5])
    vul(a, rand_van(m), K)
    split = 6 if groot else 4
    mid = w // 2
    rechthoek(a, mid, 1, 1, split, K)
    rechthoek(a, 1, split, w - 2, 1, K)
    if knop == "links":
        sel = np.zeros((h, w), bool)
        sel[1:split, 1:mid] = True
        vul(a, sel & m & ~rand_van(m), WIT[7])
    elif knop == "rechts":
        sel = np.zeros((h, w), bool)
        sel[1:split, mid + 1:w - 1] = True
        vul(a, sel & m & ~rand_van(m), WIT[7])
    else:  # wiel
        rechthoek(a, mid, 2, 1, split - 3, WIT[7])
    rechthoek(a, 2, split + 1, w - 4, 1, IJZER[7])
    return a


def glyphsets(groot):
    """Geeft {apparaat: [(naam, beeld), ...]}."""
    std, dk = GLYPH_KLEUR["std"], GLYPH_KLEUR["deck"]
    lm = lambda c: letter_masker(c, groot)  # noqa: E731
    ps = PS7 if groot else PS5
    dpads = [("dpad", "alle"), ("dpad_op", "op"), ("dpad_neer", "neer"), ("dpad_links", "links"),
             ("dpad_rechts", "rechts"), ("dpad_verticaal", "verticaal"), ("dpad_horizontaal", "horizontaal")]
    sets = {}
    sets["toetsenbord"] = [("pijl_%s" % r, g_pijltoets(r, groot)) for r in ("op", "neer", "links", "rechts")] + \
        [("muis_links", g_muis("links", groot)), ("muis_rechts", g_muis("rechts", groot)),
         ("muis_wiel", g_muis("wiel", groot))]
    x = [("a", g_rond(lm("A"), groot, std)), ("b", g_rond(lm("B"), groot, std)),
         ("x", g_rond(lm("X"), groot, std)), ("y", g_rond(lm("Y"), groot, std)),
         ("lb", g_pil("LB", groot, std)), ("rb", g_pil("RB", groot, std)),
         ("lt", g_pil("LT", groot, std, "trekker")), ("rt", g_pil("RT", groot, std, "trekker")),
         ("menu", g_klein("menu", groot, std)), ("view", g_klein("view", groot, std))]
    x += [(n, g_dpad(r, groot, std)) for n, r in dpads]
    x += [("stick_l", g_stick("L", groot, std)), ("stick_r", g_stick("R", groot, std)),
          ("stick_l_klik", g_stick("L", groot, std, True)), ("stick_r_klik", g_stick("R", groot, std, True))]
    sets["xbox"] = x
    p = [(n, g_rond(ras(ps[n]), groot, std)) for n in ("kruis", "rondje", "vierkant", "driehoek")]
    p += [("l1", g_pil("L1", groot, std)), ("r1", g_pil("R1", groot, std)),
          ("l2", g_pil("L2", groot, std, "trekker")), ("r2", g_pil("R2", groot, std, "trekker")),
          ("options", g_klein("menu", groot, std, breed=True)), ("create", g_klein("create", groot, std, breed=True)),
          ("touchpad", g_touchpad(groot, std))]
    p += [(n, g_dpad(r, groot, std)) for n, r in dpads]
    p += [("stick_l", g_stick("L", groot, std)), ("stick_r", g_stick("R", groot, std)),
          ("l3", g_stick("L", groot, std, True)), ("r3", g_stick("R", groot, std, True))]
    sets["playstation"] = p
    d = [("a", g_rond(lm("A"), groot, dk)), ("b", g_rond(lm("B"), groot, dk)),
         ("x", g_rond(lm("X"), groot, dk)), ("y", g_rond(lm("Y"), groot, dk)),
         ("l1", g_pil("L1", groot, dk)), ("r1", g_pil("R1", groot, dk)),
         ("l2", g_pil("L2", groot, dk, "trekker")), ("r2", g_pil("R2", groot, dk, "trekker")),
         ("l4", g_pil("L4", groot, dk, "greep")), ("l5", g_pil("L5", groot, dk, "greep")),
         ("r4", g_pil("R4", groot, dk, "greep")),
         ("r5", g_pil("R5", groot, dk, "greep")),
         ("menu", g_klein("menu", groot, dk)), ("view", g_klein("view", groot, dk))]
    d += [(n, g_dpad(r, groot, dk)) for n, r in dpads]
    d += [("stick_l", g_stick("L", groot, dk)), ("stick_r", g_stick("R", groot, dk)),
          ("l3", g_stick("L", groot, dk, True)), ("r3", g_stick("R", groot, dk, True)),
          ("trackpad_l", g_trackpad("L", groot, dk)), ("trackpad_r", g_trackpad("R", groot, dk))]
    sets["deck"] = d
    return sets


GLYPHS = {False: None, True: None}


def glyph(apparaat, naam, groot=False):
    if GLYPHS[groot] is None:
        GLYPHS[groot] = {k: dict(v) for k, v in glyphsets(groot).items()}
    return GLYPHS[groot][apparaat][naam]


# ================================================================== 3. lettertype x2 / x3 (titels)
def schaal_bmfont(n, naam, schaal):
    """Polderletter normaal, integer geschaald (nearest), als eigen BMFont: een BMFont schaalt in Godot niet."""
    fontdir = os.path.join(GAME, "font")
    with tempfile.TemporaryDirectory() as tmp:
        p_png, p_fnt = os.path.join(tmp, "n.png"), os.path.join(tmp, "n.fnt")
        PL.export_bmfont(p_png, p_fnt, "normaal")
        im = Image.open(p_png)
        txt = open(p_fnt, encoding="utf-8").read()
    im2 = im.resize((im.width * schaal, im.height * schaal), Image.NEAREST)
    out_png = os.path.join(fontdir, "polderletter_%s.png" % n)
    im2.save(out_png, optimize=True)

    def f(mo):
        return "%s=%d" % (mo.group(1), int(mo.group(2)) * schaal)
    regels = []
    for r in txt.splitlines():
        if r.startswith("info"):
            r = re.sub(r'face="[^"]*"', 'face="Polderletter %s"' % naam, r)
            r = re.sub(r"\b(size)=(\d+)", f, r)
        elif r.startswith("common"):
            r = re.sub(r"\b(lineHeight|base|scaleW|scaleH)=(\d+)", f, r)
        elif r.startswith("page"):
            r = 'page id=0 file="polderletter_%s.png"' % n
        elif r.startswith("char "):
            r = re.sub(r"\b(x|y|width|height|xoffset|yoffset|xadvance)=(-?\d+)", f, r)
        regels.append(r)
    out_fnt = os.path.join(fontdir, "polderletter_%s.fnt" % n)
    with open(out_fnt, "w", encoding="utf-8") as fh:
        fh.write("\n".join(regels) + "\n")
    for p in (out_png, out_fnt):
        GEMAAKT.append((os.path.relpath(p, ROOT), 0, 0))
    return 11 * schaal


# ================================================================== 4. Godot Theme (.tres)
def kleur(c, a=1.0):
    return "Color(%.4g, %.4g, %.4g, %.4g)" % (c[0] / 255, c[1] / 255, c[2] / 255, a)


class Thema:
    def __init__(self):
        self.ext, self.sub, self.props = [], [], []

    def tex(self, pad, typ="Texture2D"):
        for (t, p, i) in self.ext:
            if p == pad:
                return 'ExtResource("%s")' % i
        i = "%d_%s" % (len(self.ext) + 1, os.path.splitext(os.path.basename(pad))[0][:24])
        self.ext.append((typ, pad, i))
        return 'ExtResource("%s")' % i

    def stb(self, naam, pad, marge, inhoud, center=True):
        i = "StyleBoxTexture_%s" % naam
        r = ["texture = %s" % self.tex(pad)]
        for k, v in zip(("left", "top", "right", "bottom"), marge):
            r.append("texture_margin_%s = %.1f" % (k, v))
        for k, v in zip(("left", "top", "right", "bottom"), inhoud):
            r.append("content_margin_%s = %.1f" % (k, v))
        if not center:
            r.append("draw_center = false")
        self.sub.append(("StyleBoxTexture", i, r))
        return 'SubResource("%s")' % i

    def leeg(self, naam, inhoud):
        i = "StyleBoxEmpty_%s" % naam
        r = ["content_margin_%s = %.1f" % (k, v) for k, v in zip(("left", "top", "right", "bottom"), inhoud)]
        self.sub.append(("StyleBoxEmpty", i, r))
        return 'SubResource("%s")' % i

    def lijn(self, naam, col, dikte=1):
        i = "StyleBoxLine_%s" % naam
        self.sub.append(("StyleBoxLine", i, ["color = %s" % kleur(col), "thickness = %d" % dikte]))
        return 'SubResource("%s")' % i

    def zet(self, sleutel, waarde):
        self.props.append("%s = %s" % (sleutel, waarde))

    def schrijf(self, pad, kop):
        regels = ['[gd_resource type="Theme" load_steps=%d format=3]' % (len(self.ext) + len(self.sub) + 1), ""]
        for (t, p, i) in self.ext:
            regels.append('[ext_resource type="%s" path="%s" id="%s"]' % (t, p, i))
        regels.append("")
        for (t, i, r) in self.sub:
            regels.append('[sub_resource type="%s" id="%s"]' % (t, i))
            regels += r
            regels.append("")
        regels.append("[resource]")
        regels += self.props
        os.makedirs(os.path.dirname(pad), exist_ok=True)
        with open(pad, "w", encoding="utf-8") as fh:
            fh.write("\n".join(regels) + "\n")
        GEMAAKT.append((os.path.relpath(pad, ROOT), 0, 0))


RES = "res://art/ui/"
ONZICHTBAAR = (255, 255, 255)


def maak_thema(groot):
    t = Thema()
    font = t.tex(RES + "font/polderletter_%s.fnt" % ("groot" if groot else "normaal"), "FontFile")
    titel = t.tex(RES + "font/polderletter_titel.fnt", "FontFile")
    naam = t.tex(RES + "font/polderletter_naam.fnt", "FontFile")
    fs = 16 if groot else 11
    vt = 2                          # boven- en onderruimte in de keuzebalk (regel 11 + 4 = 15, groot 16 + 4 = 20)
    t.zet("default_font", font)
    t.zet("default_font_size", fs)

    # Label en varianten
    t.zet("Label/colors/font_color", kleur(WIT[7]))
    t.zet("Label/colors/font_shadow_color", kleur(K))
    t.zet("Label/constants/shadow_offset_x", 1)
    t.zet("Label/constants/shadow_offset_y", 1)
    t.zet("Label/constants/line_spacing", -2 if groot else -1)
    for var, col in (("Kop", GLOED[6]), ("Gedimd", WIT[5]), ("Uit", WIT[3]), ("P2", C["cyaan"])):
        t.zet("%s/base_type" % var, '&"Label"')
        t.zet("%s/colors/font_color" % var, kleur(col))
    t.zet('Titel/base_type', '&"Label"')
    t.zet("Titel/fonts/font", titel)
    t.zet("Titel/font_sizes/font_size", 22)
    t.zet("Titel/constants/shadow_offset_x", 2)
    t.zet("Titel/constants/shadow_offset_y", 2)
    t.zet('Spelnaam/base_type', '&"Label"')
    t.zet("Spelnaam/fonts/font", naam)
    t.zet("Spelnaam/font_sizes/font_size", 33)
    t.zet("Spelnaam/constants/shadow_offset_x", 3)
    t.zet("Spelnaam/constants/shadow_offset_y", 3)
    # Toetskap: Label met de toets als achtergrond (toetsenbord-glyph met de echte toetsnaam, ook AZERTY)
    tk = "toetskap_groot_9slice.png" if groot else "toetskap_9slice.png"
    m = 4 if groot else 3
    t.zet('Toetskap/base_type', '&"Label"')
    t.zet("Toetskap/styles/normal", t.stb("toetskap", RES + "glyphs/toetsenbord/" + tk, (m, m, m, m), (m, 0, m, 0)))
    t.zet("Toetskap/colors/font_shadow_color", kleur(K, 0))
    # HerbindWacht: Label tijdens MENU_PRESS_KEY
    t.zet('HerbindWacht/base_type', '&"Label"')
    t.zet("HerbindWacht/styles/normal", t.stb("herbind_wacht", RES + "menu/herbind_wacht_9slice.png",
                                              (2, 2, 2, 2), (4, 2, 4, 2)))
    t.zet("HerbindWacht/colors/font_color", kleur(K))
    t.zet("HerbindWacht/colors/font_shadow_color", kleur(K, 0))

    # Button = menuregel met lamp bij focus
    inh = (3, vt, 4, vt)
    t.zet("Button/styles/normal", t.leeg("knop_normaal", inh))
    t.zet("Button/styles/disabled", t.leeg("knop_uit", inh))
    t.zet("Button/styles/hover", t.stb("knop_hover", RES + "menu/keuzebalk_hover_9slice.png", (3, 3, 3, 3), inh))
    t.zet("Button/styles/pressed", t.stb("knop_ingedrukt", RES + "menu/keuzebalk_ingedrukt_9slice.png", (3, 3, 3, 3), inh))
    t.zet("Button/styles/hover_pressed", 'SubResource("StyleBoxTexture_knop_ingedrukt")')
    t.zet("Button/styles/focus", t.stb("knop_focus", RES + "menu/keuzebalk_9slice.png", (3, 3, 3, 3), inh))
    t.zet("Button/icons/icon", t.tex(RES + "menu/keuze_lamp.png"))
    t.zet("Button/constants/h_separation", 3)
    for k, col in (("font_color", WIT[5]), ("font_focus_color", WIT[7]), ("font_hover_color", WIT[7]),
                   ("font_pressed_color", GLOED[6]), ("font_hover_pressed_color", GLOED[6]),
                   ("font_disabled_color", WIT[3])):
        t.zet("Button/colors/%s" % k, kleur(col))
    t.zet("Button/colors/icon_normal_color", kleur(ONZICHTBAAR, 0))
    t.zet("Button/colors/icon_disabled_color", kleur(ONZICHTBAAR, 0))
    t.zet("Button/colors/icon_hover_color", kleur(ONZICHTBAAR, 0))
    for k in ("icon_focus_color", "icon_pressed_color", "icon_hover_pressed_color"):
        t.zet("Button/colors/%s" % k, kleur(ONZICHTBAAR, 1))
    # HerbindCel: knop in een kolom van Besturing, zonder lamp; gekozen kolom = open gloedrand
    t.zet('HerbindCel/base_type', '&"Button"')
    t.zet("HerbindCel/icons/icon", t.tex(RES + "menu/leeg_1x1.png"))
    t.zet("HerbindCel/constants/h_separation", 0)
    t.zet("HerbindCel/styles/focus", t.stb("cel_focus", RES + "menu/cel_focus_9slice.png", (2, 2, 2, 2), (4, vt, 4, vt)))
    t.zet("HerbindCel/styles/hover", 'SubResource("StyleBoxTexture_cel_focus")')
    t.zet("HerbindCel/styles/normal", t.leeg("cel_normaal", (4, vt, 4, vt)))
    t.zet("HerbindCel/styles/pressed", t.stb("cel_wacht", RES + "menu/herbind_wacht_9slice.png", (2, 2, 2, 2), (4, vt, 4, vt)))
    t.zet("HerbindCel/colors/font_color", kleur(WIT[6]))
    t.zet("HerbindCel/colors/font_pressed_color", kleur(K))

    # Panelen
    t.zet("PanelContainer/styles/panel", t.stb("paneel", RES + "menu/paneel_9slice.png", (4, 4, 4, 4), (8, 6, 8, 6)))
    t.zet("Panel/styles/panel", 'SubResource("StyleBoxTexture_paneel")')
    t.zet('Zijband/base_type', '&"PanelContainer"')
    t.zet("Zijband/styles/panel", t.stb("zijband", RES + "menu/zijband_9slice.png", (2, 2, 2, 2), (0, 0, 2, 0)))
    t.zet('Uitleg/base_type', '&"PanelContainer"')
    t.zet("Uitleg/styles/panel", t.stb("uitleg", RES + "hud/kader_9slice.png", (2, 2, 2, 2), (6, 3, 6, 3)))

    # Tabs (TabContainer en TabBar): LB/RB; de tabs zelf nemen geen focus
    tabinh = (5, vt, 5, vt)
    for typ in ("TabContainer", "TabBar"):
        t.zet("%s/styles/tab_selected" % typ, 'SubResource("StyleBoxTexture_tab_gekozen")' if typ == "TabBar"
              else t.stb("tab_gekozen", RES + "menu/tab_gekozen_9slice.png", (3, 3, 3, 3), tabinh))
        t.zet("%s/styles/tab_unselected" % typ, 'SubResource("StyleBoxEmpty_tab")' if typ == "TabBar"
              else t.leeg("tab", tabinh))
        t.zet("%s/styles/tab_hovered" % typ, 'SubResource("StyleBoxEmpty_tab")')
        t.zet("%s/styles/tab_disabled" % typ, 'SubResource("StyleBoxEmpty_tab")')
        t.zet("%s/styles/tab_focus" % typ, 'SubResource("StyleBoxEmpty_tab")')
        t.zet("%s/colors/font_selected_color" % typ, kleur(GLOED[6]))
        t.zet("%s/colors/font_unselected_color" % typ, kleur(WIT[5]))
        t.zet("%s/colors/font_hovered_color" % typ, kleur(WIT[7]))
        t.zet("%s/colors/font_disabled_color" % typ, kleur(WIT[3]))
        t.zet("%s/constants/h_separation" % typ, 4)
    t.zet("TabContainer/styles/panel", t.stb("tab_paneel", RES + "menu/tab_paneel_9slice.png", (2, 2, 2, 2), (0, 6, 0, 0)))
    t.zet("TabContainer/constants/side_margin", 0)

    # Schuif
    t.zet("HSlider/styles/slider", t.stb("schuif", RES + "menu/schuif_baan_9slice.png", (3, 3, 3, 3), (3, 3, 3, 4)))
    t.zet("HSlider/styles/grabber_area", t.stb("schuif_vulling", RES + "menu/schuif_vulling_9slice.png", (3, 3, 3, 3), (3, 3, 3, 4)))
    t.zet("HSlider/styles/grabber_area_highlight", 'SubResource("StyleBoxTexture_schuif_vulling")')
    t.zet("HSlider/styles/focus", t.leeg("schuif_focus", (0, 0, 0, 0)))
    t.zet("HSlider/icons/grabber", t.tex(RES + "menu/schuif_greep.png"))
    t.zet("HSlider/icons/grabber_highlight", t.tex(RES + "menu/schuif_greep_focus.png"))
    t.zet("HSlider/icons/grabber_disabled", t.tex(RES + "menu/schuif_greep_uit.png"))
    t.zet("HSlider/constants/center_grabber", 0)

    # Scrollbalk (credits, logboek, lange optielijst bij groot)
    t.zet("VScrollBar/styles/scroll", t.stb("scroll", RES + "menu/scroll_baan_9slice.png", (2, 2, 2, 2), (2, 2, 2, 2)))
    t.zet("VScrollBar/styles/scroll_focus", 'SubResource("StyleBoxTexture_scroll")')
    t.zet("VScrollBar/styles/grabber", t.stb("greep", RES + "menu/scroll_greep_9slice.png", (2, 2, 2, 2), (2, 2, 2, 2)))
    t.zet("VScrollBar/styles/grabber_highlight", t.stb("greep_hover", RES + "menu/scroll_greep_hover_9slice.png", (2, 2, 2, 2), (2, 2, 2, 2)))
    t.zet("VScrollBar/styles/grabber_pressed", t.stb("greep_vast", RES + "menu/scroll_greep_vast_9slice.png", (2, 2, 2, 2), (2, 2, 2, 2)))

    # Scheiding en lange tekst
    t.zet("HSeparator/styles/separator", t.lijn("scheiding", WIT[3]))
    t.zet("HSeparator/constants/separation", 1)
    t.zet("RichTextLabel/colors/default_color", kleur(WIT[7]))
    t.zet("RichTextLabel/colors/font_shadow_color", kleur(K))
    t.zet("RichTextLabel/constants/shadow_offset_x", 1)
    t.zet("RichTextLabel/constants/shadow_offset_y", 1)
    t.zet("RichTextLabel/constants/line_separation", -2 if groot else -1)

    naam_bestand = "polderlight_menu_groot.tres" if groot else "polderlight_menu.tres"
    t.schrijf(os.path.join(GAME, "thema", naam_bestand),
              "Godot 4.6 Theme, Polderlight menu's (%s). Gemaakt door docs/art/ui/bron/genereer_menu.py; "
              "niet met de hand wijzigen. Zie docs/art/ui-stijlgids.md par. 14." % ("groot, TG-10" if groot else "normaal"))


# ================================================================== 5. mock-ups (stellen de Theme na)
FS = {"normaal": dict(lijn=11, cap0=2, rij=15, pitch=16), "groot": dict(lijn=16, cap0=3, rij=20, pitch=22)}


def menuregel(img, s, x, y, w, staat="normaal", grootte="normaal"):
    """Button zoals het Theme hem tekent: y = bovenkant van de regel (hoogte 15 / groot 20)."""
    f = FS[grootte]
    h = f["rij"]
    if staat in ("focus", "ingedrukt", "hover"):
        if staat == "ingedrukt":
            over(img, negen4(keuzebalk("ingedrukt"), w, h, 3, 3, 3, 3), x, y)
        if staat == "hover":
            over(img, negen4(keuzebalk("hover"), w, h, 3, 3, 3, 3), x, y)
        if staat != "hover":
            over(img, negen4(keuzebalk("focus"), w, h, 3, 3, 3, 3), x, y)
    if staat in ("focus", "ingedrukt"):
        over(img, lamp(), x + 3, y + 2 + (f["lijn"] - 9) // 2)
    col = {"normaal": WIT[5], "focus": WIT[7], "hover": WIT[7], "ingedrukt": GLOED[6], "uit": WIT[3]}[staat]
    PL.draw(img, s, x + 3 + 7 + 3, y + 2 + f["cap0"], col, grootte)   # Button: geen schaduw (Godot)


def label(img, s, x, y, col=None, grootte="normaal", schaal=1):
    """Label: y = bovenkant van de regel."""
    f = FS[grootte]
    tekst(img, s, x, y + f["cap0"] * schaal, WIT[7] if col is None else col, grootte, schaal=schaal)


def hints(img, paren, apparaat, grootte="normaal", y=None, rechts=8):
    """Knophints rechtsonder: [(glyph, tekst)], rechts uitgelijnd."""
    H, W = img.shape[:2]
    groot = grootte == "groot"
    gh = 15 if groot else 11
    y = H - 8 - gh if y is None else y
    x = W - rechts
    for g, s in reversed(paren):
        tw = PL.text_width(s, grootte)
        x -= tw
        label(img, s, x, y + (gh - FS[grootte]["lijn"]) // 2 + (0 if groot else 0), WIT[6], grootte)
        if apparaat == "toetsenbord":
            gi = toets_met(g, groot) if isinstance(g, str) else g
        else:
            gi = glyph(apparaat, g, groot)
        x -= 3 + gi.shape[1]
        over(img, gi, x, y)
        x -= 10
    return x


def hint_links(img, g, s, apparaat, grootte="normaal", x=8, kleur=None):
    H = img.shape[0]
    groot = grootte == "groot"
    gh = 15 if groot else 11
    y = H - 8 - gh
    gi = toets_met(g, groot) if apparaat == "toetsenbord" else glyph(apparaat, g, groot)
    over(img, gi, x, y)
    label(img, s, x + gi.shape[1] + 3, y + (gh - FS[grootte]["lijn"]) // 2, WIT[6] if kleur is None else kleur, grootte)


def dim(img, alfa=DIM_ALFA):
    img[:] = (img.astype(float) * (1 - alfa) + np.array(LUCHT[0]) * alfa).round().astype(np.uint8)


def band(img, w):
    over(img, negen4(zijband(), w, img.shape[0], 2, 2, 2, 2), 0, 0)


def mock_hoofdmenu(apparaat="xbox"):
    img = U.laad("r5_grijs_640x360.png")
    band(img, 214)
    label(img, "Polderlight", 28, 44, WIT[7], schaal=3)
    label(img, "werktitel", 30, 80, WIT[5])
    regels = ["Doorgaan", "Nieuw spel", "Opties", "Credits", "Afsluiten"]
    for i, s in enumerate(regels):
        menuregel(img, s, 28, 108 + i * 16, 160, "focus" if i == 0 else "normaal")
    label(img, "Wijk 1.1 De Kadewijk · Licht 40 · 12 min", 41, 194, WIT[5])
    label(img, "2e speler: druk op Start", 640 - 8 - PL.text_width("2e speler: druk op Start"), 316, C["cyaan"])
    hint_links(img, "y", "Taal: Nederlands", apparaat)
    hints(img, [("a", "Kies"), ("b", "Terug")], apparaat)
    return img


def pauze_inhoud(img, apparaat, H=360):
    dim(img, 0.35)
    U.hud_coop(img, L=60, hp=4)
    band(img, 214)
    label(img, "Pauze", 28, 36, WIT[7], schaal=2)
    regels = ["Verder", "Logboek", "Opties", "Speler 2 stopt", "Naar hoofdmenu"]
    for i, s in enumerate(regels):
        menuregel(img, s, 28, 76 + i * 16, 160, "focus" if i == 0 else "normaal")
    info = [("Wijk 1.1 De Kadewijk", WIT[7]), ("Gemaal: trap 1 van 2", WIT[6]),
            ("Lampglas 0/1 · Logboek 3/7", WIT[6]), ("Opgeslagen bij het gemaal", WIT[5])]
    over(img, negen4(U.kader_9slice(), 152, 4 * 14 + 8, 2, 2, 2, 2), 226, 74)
    for i, (s, c) in enumerate(info):
        label(img, s, 232, 76 + i * 14, c)
    label(img, "Pauze van P1. P2 kan niet sturen.", 28, H - 40, WIT[5])
    hints(img, [("a" if apparaat != "playstation" else "kruis", "Kies"),
                ("b" if apparaat != "playstation" else "rondje", "Verder")], apparaat)


def mock_pauze(apparaat="playstation"):
    img = U.laad("r5_kleur_640x360.png")
    pauze_inhoud(img, apparaat)
    return img


def mock_pauze_deck():
    img = U.deck_achtergrond("r5_kleur_deck_1280x800.png")
    pauze_inhoud(img, "deck", H=400)
    return img


TABS_NL = ["Algemeen", "Beeld", "Geluid", "Besturing", "Toegankelijkheid"]
TABS_EN = ["General", "Display", "Audio", "Controls", "Accessibility"]


def opties_kop(img, gekozen, apparaat, grootte="normaal"):
    f = FS[grootte]
    groot = grootte == "groot"
    label(img, "Opties", 28, 8, WIT[7], schaal=2)
    y = 34
    x = 22
    lb = glyph(apparaat, "lb" if apparaat == "xbox" else "l1", groot) if apparaat != "toetsenbord" else toets_met("Q", groot)
    rb = glyph(apparaat, "rb" if apparaat == "xbox" else "r1", groot) if apparaat != "toetsenbord" else toets_met("E", groot)
    over(img, lb, x, y + (f["rij"] - lb.shape[0]) // 2)
    x += lb.shape[1] + 4
    for i, s in enumerate(TABS_NL):
        w = 5 + PL.text_width(s, grootte) + 5
        if i == gekozen:
            over(img, negen4(tab_gekozen(), w, f["rij"], 3, 3, 3, 3), x, y)
        label(img, s, x + 5, y + 2, GLOED[6] if i == gekozen else WIT[5], grootte)
        x += w + 4
    over(img, rb, x, y + (f["rij"] - rb.shape[0]) // 2)
    img[y + f["rij"], 16:624] = WIT[3]
    return y + f["rij"] + 7


def waarde(img, s, x, y, focus=False, grootte="normaal"):
    f = FS[grootte]
    if focus:
        over(img, keuzepijl("links", True), x, y + 2 + f["cap0"])
        label(img, s, x + 9, y + 2, WIT[7], grootte)
        over(img, keuzepijl("rechts", True), x + 9 + PL.text_width(s, grootte) + 4, y + 2 + f["cap0"])
    else:
        label(img, s, x + 9, y + 2, WIT[6], grootte)


def schuif(img, x, y, w, frac, focus=False):
    over(img, negen4(schuif_baan(), w, 7, 3, 3, 3, 3), x, y)
    fw = max(7, int(round(w * frac)))
    over(img, negen4(schuif_vulling(), fw, 7, 3, 3, 3, 3), x, y)
    g = schuif_greep("focus" if focus else "normaal")
    over(img, g, x + fw - 3, y - 2)


A11Y = [("Vasthouden of tikken", "Vasthouden"), ("Schermschok", None), ("Flitsen verminderen", "Uit"),
        ("Echo-rand dikker", "Uit"), ("Merk-ring groter", "Uit"), ("Aftelling ook trillen", "Aan"),
        ("Kleurprofiel spelers", "Amber / cyaan"), ("Ondertitels", "Aan"), ("Geluidsbijschriften", "Uit"),
        ("Tekstgrootte", "Groot"), ("HUD", "Altijd")]
UITLEG = ["Tikken: loslaten, genezen en stoppen met één druk. Nog een druk,",
          "sprong of treffer breekt af. Lanceerhouding: twee keer Aanval,",
          "snel na elkaar (ca. 0,3 s). Eén tik geeft nooit houding.",
          "Houding stopt bij Aanval, Dash, lancering of na 2 s."]


UITLEG_TG10 = ["Groot: menu's, logbladzijden en meldingen in een grotere letter,",
               "apart getekend (geen schaalfilter). De HUD blijft gelijk.", "", ""]


def mock_opties_a11y(apparaat="toetsenbord", grootte="normaal", focus=0):
    img = U.laad("r5_grijs_640x360.png")
    dim(img)
    f = FS[grootte]
    groot = grootte == "groot"
    y0 = opties_kop(img, 4, apparaat, grootte)
    uitleg_h = (4 * (14 if groot else 10)) + 8
    uitleg_y = 360 - 8 - (15 if groot else 11) - 8 - uitleg_h
    n_zicht = (uitleg_y - 6 - y0) // f["pitch"]
    start = max(0, focus - n_zicht + 2) if groot else 0
    vx = 400 if not groot else 392
    for j, (s, v) in enumerate(A11Y[start:start + n_zicht]):
        i = j + start
        y = y0 + j * f["pitch"]
        rw = 588 if not groot else 580
        menuregel(img, s, 20, y, rw, "focus" if i == focus else "normaal", grootte)
        if v is None:
            schuif(img, vx + 9, y + (f["rij"] - 7) // 2, 120, 1.0)
            label(img, "100%", vx + 9 + 128, y + 2, WIT[6], grootte)
        else:
            waarde(img, v, vx, y, i == focus, grootte)
    if groot:   # scrollbalk rechts naast de lijst
        sh = n_zicht * f["pitch"] - 4
        over(img, negen4(scroll_baan(), 5, sh, 2, 2, 2, 2), 612, y0)
        gh = int(sh * n_zicht / len(A11Y))
        over(img, negen4(scroll_greep(), 5, gh, 2, 2, 2, 2), 612, y0 + int((sh - gh) * start / max(1, len(A11Y) - n_zicht)))
    over(img, negen4(U.kader_9slice(), 588, uitleg_h, 2, 2, 2, 2), 20, uitleg_y)
    for i, r in enumerate(UITLEG if focus == 0 else UITLEG_TG10):
        label(img, r, 26, uitleg_y + 3 + i * (14 if groot else 10) - (1 if not groot else 1),
              WIT[7] if i < 3 else WIT[5], grootte)
    if apparaat == "toetsenbord":
        hints(img, [("Enter", "Wijzig"), ("Del", "Standaard"), ("Esc", "Terug")], apparaat, grootte)
    else:
        hints(img, [("a", "Wijzig"), ("x", "Standaard"), ("b", "Terug")], apparaat, grootte)
    return img


HERBIND = [("Links / rechts", "A / D", "Pijlen", "Stick, D-pad"), ("Springen", "Spatie", "Enter", "A"),
           ("Aanval", "E", "R-Ctrl", "X"), ("Interactie (genezen)", "F", "/", "Y"),
           ("Echo (loslaten)", "Q", ".", None), ("Dash", "L-Shift", "R-Shift", "RB"),
           ("Pauze", "Esc", "Esc", "Menu"), ("Meedoen (vrij apparaat)", "–", "Enter", "Menu"),
           ("Stoppen (vasthouden)", "–", "Backspace", "View")]
KOLOM_X = [20, 196, 326, 466]


def mock_besturing():
    img = U.laad("r5_grijs_640x360.png")
    dim(img)
    y0 = opties_kop(img, 3, "toetsenbord")
    for k, s in zip(KOLOM_X, ("Actie", "Toetsenbord 1", "Toetsenbord 2", "Controller")):
        label(img, s, k + 13, y0, GLOED[6])
    y0 += 16
    for i, rij in enumerate(HERBIND):
        y = y0 + i * 18
        focus = i == 4
        menuregel(img, rij[0], KOLOM_X[0], y, 588, "focus" if focus else "normaal")
        for j, cel in enumerate(rij[1:]):
            cx = KOLOM_X[j + 1]
            if cel is None:   # wacht op een nieuwe knop
                w = PL.text_width("Druk een knop…") + 8
                over(img, negen4(herbind_wacht(), w, 15, 2, 2, 2, 2), cx + 9, y)
                PL.draw(img, "Druk een knop…", cx + 13, y + 4, K)
            else:
                PL.draw(img, cel, cx + 13, y + 4, WIT[7] if focus else WIT[5])
    # dialoog "Bezet door Dash: wisselen?"
    s1, s2 = "Bezet door Dash: wisselen?", ""
    w = PL.text_width(s1) + 16
    px, py = (640 - w) // 2, 238
    over(img, negen4(paneel(), w, 40, 4, 4, 4, 4), px, py)
    label(img, s1, px + 8, py + 6, GLOED[6])
    xg = px + 8
    for g, s in (("Enter", "Wisselen"), ("Esc", "Annuleren")):
        gi = toets_met(g)
        over(img, gi, xg, py + 23)
        label(img, s, xg + gi.shape[1] + 3, py + 23, WIT[6])
        xg += gi.shape[1] + 3 + PL.text_width(s) + 12
    hints(img, [("Enter", "Herbind"), ("Del", "Standaard"), ("Esc", "Terug")], "toetsenbord")
    return img


# ================================================================== 6. overzichtsbladen
def elementenblad():
    W, H = 330, 236
    a = np.zeros((H, W, 3), np.uint8)
    a[:] = LUCHT[2]
    over(a, U.negen(U.plaat_9slice(), W, H), 0, 0)

    def kop(s, x, y):
        tekst(a, s, x, y, GLOED[6])

    def onder(s, x, y):
        tekst(a, s, x, y, WIT[5], schaduw=False)

    kop("Menuregel (Button) 15 hoog", 6, 4)
    for i, st in enumerate(("normaal", "focus", "ingedrukt", "hover", "uit")):
        menuregel(a, {"hover": "Opties (muis)", "uit": "Doorgaan"}.get(st, "Opties"), 6, 16 + i * 17, 110, st)
        onder(st, 122, 20 + i * 17)

    kop("Tabs", 180, 4)
    x = 180
    for i, s in enumerate(("Beeld", "Geluid")):
        w = 10 + PL.text_width(s)
        if i == 1:
            over(a, negen4(tab_gekozen(), w, 15, 3, 3, 3, 3), x, 16)
        tekst(a, s, x + 5, 20, GLOED[6] if i == 1 else WIT[5])
        x += w + 4
    a[31, 176:324] = WIT[3]
    onder("ongekozen / gekozen", 180, 36)

    kop("Schuif", 180, 52)
    schuif(a, 182, 66, 80, 0.6)
    schuif(a, 182, 82, 80, 0.3, focus=True)
    over(a, schuif_greep("uit"), 222, 51)
    onder("uit", 230, 53)
    onder("normaal", 268, 68)
    onder("focus", 268, 84)

    kop("Keuzewaarde", 180, 100)
    waarde(a, "Aan", 180, 110, True)
    waarde(a, "Uit", 250, 110, False)

    kop("Herbinden", 6, 104)
    over(a, negen4(cel_focus(), 40, 15, 2, 2, 2, 2), 6, 116)
    tekst(a, "Q", 12, 120, WIT[7], schaduw=False)
    w = PL.text_width("Druk een knop…") + 8
    over(a, negen4(herbind_wacht(), w, 15, 2, 2, 2, 2), 52, 116)
    PL.draw(a, "Druk een knop…", 56, 120, K)
    onder("kolom gekozen / wacht", 6, 134)

    kop("Paneel (dialoog)", 6, 150)
    over(a, negen4(paneel(), 120, 30, 4, 4, 4, 4), 6, 162)
    tekst(a, "Overschrijven?", 14, 168, GLOED[6])
    kop("Uitleg", 140, 150)
    over(a, negen4(U.kader_9slice(), 70, 30, 2, 2, 2, 2), 140, 162)
    tekst(a, "Regel 1", 146, 166, WIT[7])

    kop("Scroll", 220, 150)
    over(a, negen4(scroll_baan(), 5, 60, 2, 2, 2, 2), 222, 162)
    over(a, negen4(scroll_greep(), 5, 20, 2, 2, 2, 2), 222, 166)
    over(a, negen4(scroll_baan(), 5, 60, 2, 2, 2, 2), 232, 162)
    over(a, negen4(scroll_greep("hover"), 5, 20, 2, 2, 2, 2), 232, 180)
    over(a, negen4(scroll_baan(), 5, 60, 2, 2, 2, 2), 242, 162)
    over(a, negen4(scroll_greep("vast"), 5, 20, 2, 2, 2, 2), 242, 198)

    kop("Toetskap", 260, 150)
    over(a, toets_met("Esc"), 262, 164)
    over(a, toets_met("Enter"), 262, 180)
    over(a, toets_met("Esc", True), 290, 164)

    kop("Zijband", 6, 198)
    over(a, negen4(zijband(), 60, 24, 2, 2, 2, 2), 6, 210)
    return a


def glyphblad():
    titels = {"toetsenbord": "Toetsenbord en muis", "xbox": "Xbox-stijl", "playstation": "PlayStation-stijl",
              "deck": "Steam Deck"}
    W = 420
    a = np.zeros((1000, W, 3), np.uint8)
    a[:] = LUCHT[1]
    y = 4
    for app in ("toetsenbord", "xbox", "playstation", "deck"):
        for groot in (False, True):
            tekst(a, "%s · %s" % (titels[app], "groot 15" if groot else "normaal 11"), 6, y, GLOED[6])
            x, yy = 6, y + 12
            gh = 16 if groot else 11
            items = list(glyphsets(groot)[app])
            if app == "toetsenbord":
                items = [("", toets_met(t, groot)) for t in ("Esc", "Spatie", "Q")] + items
            for n, b in items:
                if x + b.shape[1] > W - 6:
                    x, yy = 6, yy + gh + 4
                over(a, b, x, yy)
                x += b.shape[1] + 3
            y = yy + gh + 6
    tekst(a, "Eigen tekeningen: generieke vormen, geen logo's of merkkleuren.", 6, y + 2, WIT[5])
    tekst(a, "Toets met tekst: variant Toetskap in het Theme (toont de echte toets, ook AZERTY).", 6, y + 13, WIT[5])
    return a[:y + 26]


# ================================================================== 7. tekstmeting (par. 13 stijlgids)
MEET = [
    # (vak, beschikbare breedte normaal, [(EN, NL)])
    ("Hoofdmenu/pauze-regel (Button 160, tekst max. 147)", 147, [
        ("Continue", "Doorgaan"), ("New game", "Nieuw spel"), ("Options", "Opties"), ("Quit", "Afsluiten"),
        ("Resume", "Verder"), ("Logbook", "Logboek"), ("Player 2 leaves", "Speler 2 stopt"),
        ("Back to main menu", "Naar hoofdmenu")]),
    ("Optieregel, label (tot de waardekolom, 360)", 360, [
        ("Hold or tap", "Vasthouden of tikken"), ("Reduce flashes", "Flitsen verminderen"),
        ("Countdown also vibrates", "Aftelling ook trillen"), ("Player colour profile", "Kleurprofiel spelers"),
        ("Sound captions", "Geluidsbijschriften")]),
    ("Herbinden, kolom Actie (163)", 163, [
        ("Interact (heal)", "Interactie (genezen)"), ("Join (free device)", "Meedoen (vrij apparaat)"),
        ("Leave (hold)", "Stoppen (vasthouden)")]),
    ("Herbinden, kolom toets (127)", 127, [("Keyboard 1", "Toetsenbord 1"), ("Press a key…", "Druk een knop…")]),
    ("Dialoog (max. 400)", 400, [("Taken by Dash: swap?", "Bezet door Dash: wisselen?"),
                                 ("Overwrite this save?", "Dit spelbestand overschrijven?")]),
]


def tabbalk_breedte(tabs, grootte):
    groot = grootte == "groot"
    glyph_w = glyph("xbox", "lb", groot).shape[1]
    return 2 * (glyph_w + 4) + sum(10 + PL.text_width(s, grootte) + 4 for s in tabs) - 4


def meting():
    print("\nTekstmeting menu's (px, Polderletter; groot: vak x1,5):")
    for vak, br, paren in MEET:
        for en, nl in paren:
            ew, nw, gw = PL.text_width(en), PL.text_width(nl), PL.text_width(nl, "groot")
            ok = "past" if nw <= br else "PAST NIET"
            okg = "past" if gw <= int(br * 1.5) else "PAST NIET"
            print("  %-50s %-26s EN %3d NL %3d vak %3d %-9s | groot NL %3d / %3d %s"
                  % (vak[:50], nl[:26], ew, nw, br, ok, gw, int(br * 1.5), okg))
    for g in ("normaal", "groot"):
        print("  Tabbalk %s: NL %d px, EN %d px (beschikbaar 608)" % (g, tabbalk_breedte(TABS_NL, g), tabbalk_breedte(TABS_EN, g)))
    # contrast van de knoptekst (zonder schaduw) op de keuzebalk boven de helderste achtergrond
    print("\nKnoptekst zonder schaduw (Godot Button): dL* tekst - ondergrond, op de lichtste plek van R5 kleur")
    bg = U.laad("r5_kleur_640x360.png").reshape(-1, 3)
    helderst = bg[np.argmax([U.lab(p)[0] for p in bg[::7]]) * 7]
    for naam, vulc, alfa, tc in (("focus: gloed 0 op 70 %", GLOED[0], GLOED_FILL_ALFA, WIT[7]),
                                 ("normaal: zijband 78 %", LUCHT[1], U.KADER_ALFA, WIT[5]),
                                 ("normaal: verduisterd 72 %", LUCHT[0], DIM_ALFA, WIT[5])):
        ond = np.array(helderst, float) * (1 - alfa) + np.array(vulc) * alfa
        print("  %-30s ondergrond L* %5.1f  tekst L* %5.1f  dL* %5.1f" % (naam, U.lab(ond)[0], U.lab(tc)[0], U.lab(tc)[0] - U.lab(ond)[0]))


# ================================================================== main
def main():
    GEMAAKT.clear()
    md = os.path.join(GAME, "menu")
    bewaar(keuzebalk("focus"), md, "keuzebalk_9slice.png")
    bewaar(keuzebalk("ingedrukt"), md, "keuzebalk_ingedrukt_9slice.png")
    bewaar(keuzebalk("hover"), md, "keuzebalk_hover_9slice.png")
    bewaar(lamp(), md, "keuze_lamp.png")
    bewaar(leeg_1x1(), md, "leeg_1x1.png")
    bewaar(tab_gekozen(), md, "tab_gekozen_9slice.png")
    bewaar(tab_paneel(), md, "tab_paneel_9slice.png")
    bewaar(schuif_baan(), md, "schuif_baan_9slice.png")
    bewaar(schuif_vulling(), md, "schuif_vulling_9slice.png")
    bewaar(schuif_greep("normaal"), md, "schuif_greep.png")
    bewaar(schuif_greep("focus"), md, "schuif_greep_focus.png")
    bewaar(schuif_greep("uit"), md, "schuif_greep_uit.png")
    for r in ("links", "rechts"):
        bewaar(keuzepijl(r), md, "keuzepijl_%s.png" % r)
        bewaar(keuzepijl(r, True), md, "keuzepijl_%s_focus.png" % r)
    bewaar(herbind_wacht(), md, "herbind_wacht_9slice.png")
    bewaar(cel_focus(), md, "cel_focus_9slice.png")
    bewaar(scroll_baan(), md, "scroll_baan_9slice.png")
    bewaar(scroll_greep(), md, "scroll_greep_9slice.png")
    bewaar(scroll_greep("hover"), md, "scroll_greep_hover_9slice.png")
    bewaar(scroll_greep("vast"), md, "scroll_greep_vast_9slice.png")
    bewaar(paneel(), md, "paneel_9slice.png")
    bewaar(zijband(), md, "zijband_9slice.png")

    gd = os.path.join(GAME, "glyphs")
    bewaar(toetskap(), gd, "toetsenbord", "toetskap_9slice.png")
    bewaar(toetskap(True), gd, "toetsenbord", "toetskap_groot_9slice.png")
    for groot in (False, True):
        for app, items in glyphsets(groot).items():
            for n, b in items:
                bewaar(b, gd, app, "%s%s.png" % (n, "_groot" if groot else ""))

    schaal_bmfont("titel", "Titel", 2)
    schaal_bmfont("naam", "Naam", 3)
    maak_thema(False)
    maak_thema(True)

    preview(mock_hoofdmenu("xbox"), "menu_hoofdmenu_x2.png", 2)
    preview(mock_pauze("playstation"), "menu_pauze_coop_x2.png", 2)
    preview(mock_pauze_deck(), "menu_pauze_deck_640x400_x2.png", 2)
    preview(mock_opties_a11y("toetsenbord"), "menu_opties_toegankelijkheid_x2.png", 2)
    preview(mock_besturing(), "menu_opties_besturing_herbinden_x2.png", 2)
    preview(mock_opties_a11y("xbox", "groot", focus=9), "menu_opties_groot_x2.png", 2)
    preview(elementenblad(), "menu_elementen_x4.png", 4)
    preview(glyphblad(), "knop_glyphs_x4.png", 4)

    print("Gemaakt (%d bestanden):" % len(GEMAAKT))
    for p, w, h in GEMAAKT:
        print("  ", p, ("%dx%d" % (w, h)) if w else "")
    meting()


if __name__ == "__main__":
    main()
