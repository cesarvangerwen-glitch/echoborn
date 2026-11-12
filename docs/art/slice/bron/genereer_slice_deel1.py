"""Slice-art deel 1, de Kadewijk (Art Director, #85, T8c).

Maakt het werk dat niet van de kamermaten afhangt:
  1. palet van de Kadewijk (ramps kleur / half / grijs, plus 3 nieuwe ramps)
  2. tileset 16x16 en props (kleur, half, grijs en een index-atlas voor de palet-LUT)
  3. lichtovergang grijs -> kleur (studie, geen kamer) als GIF en strip
  4. kleurscript van de slice (S1-S9 en de terugweg), met de gemeten chroma per beat
  5. concept-sheets van de drie vijandtypes en de Gemaalmeester (stijlregels)

Alles is eigen werk: ramps, figuren en helpers komen uit de R5-scene
(docs/art/r5-scene/bron), het font uit docs/art/stijltests/bron, en de merk-sprites
van de UI Artist uit game/art/ui/wereld. Geen externe assets.

Draaien vanaf de repo-root:  python3 docs/art/slice/bron/genereer_slice_deel1.py
Het script print de metingen voor docs/art/slice-kadewijk.md (dE76, dL*).
"""
import csv
import os
import sys

import numpy as np
from PIL import Image
from scipy import ndimage

HIER = os.path.dirname(os.path.abspath(__file__))
UIT = os.path.dirname(HIER)
REPO = os.path.abspath(os.path.join(UIT, "..", "..", ".."))
sys.path.insert(0, os.path.join(REPO, "docs", "art", "r5-scene", "bron"))
sys.path.insert(0, os.path.join(REPO, "docs", "art", "stijltests", "bron"))
import genereer_r5 as R  # noqa: E402  (palet, ramps, figuren; draait zelf niets)
import sprites as SP  # noqa: E402
from pixelfont import draw_text, text_width  # noqa: E402

TILES = os.path.join(UIT, "tiles")
os.makedirs(TILES, exist_ok=True)
hx = R.hx

# ------------------------------------------------------------------ palet
# Nieuwe ramps voor de Kadewijk (bible §3: 8 tinten met hue-shift).
NIEUW = {
    # roest: sluisschotten, banden van de sluisdeur, het schot van de Schotdrager.
    # Bewust bruinrood en weinig verzadigd: nooit in de buurt van amber (bible §6 regel 3).
    "roest": ["#0e080e", "#24141c", "#3e2024", "#5a2e2c", "#744238", "#8c5a4c", "#a47668", "#bc9688"],
    # vijand lijf: bijna zwart, koel paars (vol = levend, maar donker; bible §6)
    "vijandlijf": ["#05040a", "#0c0912", "#140f1c", "#1d1626", "#271e30", "#33283c", "#40334a", "#4e3f58"],
    # vijand kern en bovenrand: tint 5 = #ff475c (UI-stijlgids §3, open punt 4)
    "vijandkern": ["#2a0610", "#4e0c1a", "#7a1424", "#a81e30", "#d42e42", "#ff475c", "#ff8a90", "#ffd4d0"],
}
MATS = list(R.MATS) + list(NIEUW)
MI = {m: i for i, m in enumerate(MATS)}
K = np.concatenate([R.RAMP_KLEUR, np.array([R.ramp(v) for v in NIEUW.values()])])
G = np.concatenate([R.RAMP_GRIJS, np.array([R.desat(r, 0.06, 0.86, 0.0, -2.5) for r in K[len(R.MATS):]])])
HALF = np.concatenate([R.RAMP_HALF, np.array([R.desat(r, 0.42, 0.95) for r in K[len(R.MATS):]])])
# Wat in elke toestand zijn kleur houdt: lichtbronnen (gloed) en vijanden (figuren, bible §4.1.5)
for m in ["gloed", "vijandlijf", "vijandkern"]:
    G[MI[m]] = K[MI[m]]
    HALF[MI[m]] = K[MI[m]]
STAAT = {"grijs": G, "half": HALF, "kleur": K}
# Kadewijk gebruikt deze materialen (palet van de wijk)
KADE_MATS = ["lucht", "ver", "huis_rood", "huis_oker", "huis_wit", "huis_groen", "dak", "raam", "raamdonker",
             "steen", "baksteen", "ijzer", "koper", "hout", "water", "klimop", "roest", "gloed",
             "schaduwgeo", "lichtgeo", "vijandlijf", "vijandkern"]

LAB = R.srgb_to_lab


def dE(a, b, deut=False):
    a, b = np.asarray(a, float), np.asarray(b, float)
    if deut:
        a, b = R.deuteranopia(a), R.deuteranopia(b)
    return float(np.linalg.norm(LAB(a) - LAB(b)))


def dL(a, b):
    return float(abs(LAB(np.asarray(a, float))[0] - LAB(np.asarray(b, float))[0]))


def to_pil(img, scale=1):
    return R.to_pil(img, scale)


def label(img, text, x, y, col=(0.95, 0.9, 0.8), s=2):
    draw_text(img, text, x, y, np.array(col), s)


BG = np.array([0.06, 0.055, 0.09])


# ------------------------------------------------------------------ tiles
class T:
    """Een tegel of prop als (materiaal, tint); mat -1 = leeg."""

    def __init__(self, w=16, h=16):
        self.mat = np.full((h, w), -1, np.int16)
        self.t = np.zeros((h, w), np.int16)

    def fill(self, m, mat, t):
        self.mat[m] = MI[mat]
        self.t[m] = t

    def box(self, x0, y0, x1, y1, mat, t):
        self.mat[y0:y1, x0:x1] = MI[mat]
        self.t[y0:y1, x0:x1] = t

    def add(self, m, d):
        self.t[m] += d

    def render(self, staat, dt=0):
        ramp = STAAT[staat]
        h, w = self.mat.shape
        out = np.zeros((h, w, 4))
        ok = self.mat >= 0
        ti = np.clip(self.t + dt, 0, 7)
        out[ok, :3] = ramp[self.mat[ok], ti[ok]]
        out[ok, 3] = 1
        return out


def hrng(seed):
    return np.random.default_rng(seed)


def blokken(t, y0, y1, bw, bh, mat, base, seed=0, off=0, verweer=7):
    """Blokverband in een tegel; tegelbaar als 16 % bw == 0 en (y1 - y0) % bh == 0."""
    h, w = t.mat.shape
    yy, xx = np.mgrid[0:h, 0:w]
    m = (yy >= y0) & (yy < y1)
    ry = (yy - y0) % bh
    row = (yy - y0) // bh
    rx = (xx + ((row + off) % 2) * (bw // 2)) % bw
    t.fill(m, mat, base)
    t.add(m & ((ry == 0) | (rx == 0)), -2)
    t.add(m & (ry == 1) & (rx != 0), 1)
    t.add(m & (ry == bh - 1) & (rx != 0), -1)
    bid = (row * 131 + ((xx + ((row + off) % 2) * (bw // 2)) // bw) * 71 + seed) % verweer
    t.add(m & (bid == 0) & (ry != 0) & (rx != 0), -1)
    # een paar losse putjes (alleen in de vlakken, nooit op de bovenkant)
    r = hrng(seed)
    pit = (r.random((h, w)) < 0.025) & m & (ry > 1) & (rx > 0)
    t.add(pit, -1)


def kade_wand(seed, base=3):
    t = T()
    blokken(t, 0, 16, 16, 8, "steen", base, seed)
    return t


def kade_boven(seed, kop=None):
    t = T()
    blokken(t, 6, 16, 16, 8, "steen", 3, seed, off=1)
    t.box(0, 0, 16, 6, "steen", 4)      # dekplaat (blauwe hardsteen)
    t.box(0, 0, 16, 1, "steen", 6)      # bovenrand warm (licht)
    t.box(0, 1, 16, 2, "steen", 5)
    t.box(0, 5, 16, 6, "steen", 2)      # schaduwlijn onder de dekplaat
    if kop == "l":
        t.box(0, 0, 1, 16, "steen", 1)
        t.box(1, 0, 2, 6, "steen", 5)
    if kop == "r":
        t.box(15, 0, 16, 16, "steen", 1)
    r = hrng(seed + 9)
    yy = np.mgrid[0:16, 0:16][0]
    t.add((r.random((16, 16)) < 0.05) & (yy >= 2) & (yy <= 4), -1)   # slijtplekjes in de dekplaat
    return t


def kade_meerring():
    t = kade_wand(5)
    yy, xx = np.mgrid[0:16, 0:16]
    ring = (np.abs(np.hypot(xx - 7.5, yy - 9.5) - 3.6) < 0.8)
    t.fill(ring, "ijzer", 5)
    t.fill(ring & (yy < 9), "ijzer", 6)
    t.box(6, 4, 10, 7, "ijzer", 3)      # oog in de steen
    t.box(7, 4, 9, 5, "ijzer", 6)
    t.fill((yy == 14) & (xx >= 5) & (xx <= 10), "roest", 3)  # roestspoor
    return t


def kade_getij(seed):
    """Wand met getijdenrand: klimop op de oude waterstand (bible §4.5)."""
    t = kade_wand(seed)
    yy, xx = np.mgrid[0:16, 0:16]
    r = hrng(seed + 3)
    rand = 6 + (r.random(16) * 3).astype(int)
    band = (yy >= rand[xx]) & (yy <= rand[xx] + 4)
    t.fill(band, "klimop", 1)
    t.fill(band & (yy == rand[xx]), "klimop", 2)
    drip = (r.random(16) < 0.35)[xx] & (yy > rand[xx] + 4) & (yy < rand[xx] + 8)
    t.fill(drip, "klimop", 1)
    return t


def kade_voet(seed):
    """Onderkant van de wand bij het water: nat, donkerder, groen aangeslagen."""
    t = kade_wand(seed, base=2)
    yy, xx = np.mgrid[0:16, 0:16]
    t.add(yy >= 10, -1)
    r = hrng(seed)
    t.fill((yy >= 12) & (r.random((16, 16)) < 0.4), "klimop", 1)
    return t


def baksteen(seed, base=3):
    t = T()
    blokken(t, 0, 16, 8, 4, "baksteen", base, seed, verweer=5)
    return t


def baksteen_speklaag(seed):
    """Vlaamse speklaag: een band blauwe hardsteen in het metselwerk."""
    t = baksteen(seed)
    t.box(0, 6, 16, 11, "steen", 4)
    t.box(0, 6, 16, 7, "steen", 6)
    t.box(0, 10, 16, 11, "steen", 2)
    return t


def baksteen_dek(seed):
    t = baksteen(seed)
    t.box(0, 0, 16, 5, "steen", 4)
    t.box(0, 0, 16, 1, "steen", 6)
    t.box(0, 4, 16, 5, "steen", 2)
    return t


def boog(kant):
    """Rondboog van een duiker (2 tegels breed, straal 14), opening donker."""
    t = baksteen(11)
    yy, xx = np.mgrid[0:16, 0:16]
    cx = 16 if kant == "l" else -0.0
    d = np.hypot(xx + 0.5 - cx, yy + 0.5 - 18)
    t.fill(d < 14, "raamdonker", 1)
    t.fill((d >= 14) & (d < 17), "steen", 4)          # boogstenen in hardsteen
    t.fill((d >= 14) & (d < 15), "steen", 2)
    ang = np.arctan2(yy + 0.5 - 18, xx + 0.5 - cx)
    t.fill((d >= 14) & (d < 17) & (np.abs(np.sin(ang * 6)) < 0.18), "steen", 2)
    return t


def water_opp(f):
    """Wateroppervlak: lijn in tint 5-7 met onderbrekingen die per frame opschuiven."""
    t = T()
    yy, xx = np.mgrid[0:16, 0:16]
    t.fill(yy >= 0, "water", 1)
    t.fill(yy <= 3, "water", 2)
    bay = R.bayer(16, 16)
    t.fill((yy >= 1) & (yy <= 4) & (bay < 0.5 - yy * 0.1), "water", 3)
    lijn = ((xx + f * 2) % 16 < 11) & (yy == 0)
    t.fill(yy == 0, "water", 4)
    t.fill(lijn, "water", 6)
    t.fill(lijn & ((xx + f * 2) % 16 < 3), "water", 7)
    glans = (yy == 2) & ((xx + 16 - f * 2) % 16 >= 4) & ((xx + 16 - f * 2) % 16 < 7)
    t.fill(glans, "water", 5)
    return t


def water_vol(seed):
    t = T()
    t.fill(np.ones((16, 16), bool), "water", 1)
    r = hrng(seed)
    t.fill(r.random((16, 16)) < 0.012, "water", 2)
    return t


def onderwater_loopbrug():
    """Loopbrug onder hoog water (grijs): lijf tint 2, contour tint 3 (bible §4.5, §7.5)."""
    t = water_vol(4)
    t.box(0, 5, 16, 10, "water", 2)
    t.box(0, 5, 16, 6, "water", 3)
    yy, xx = np.mgrid[0:16, 0:16]
    t.fill((yy == 9) & (xx % 4 != 3), "water", 3)
    t.box(3, 10, 5, 16, "water", 2)
    t.box(11, 10, 13, 16, "water", 2)
    return t


def loopbrug(kant):
    t = T()
    yy, xx = np.mgrid[0:16, 0:16]
    t.box(0, 0, 16, 4, "hout", 4)
    t.box(0, 0, 16, 1, "hout", 6)
    t.fill((yy >= 1) & (yy <= 3) & (xx % 8 == 7), "hout", 2)  # plankvoegen
    t.fill((yy == 2) & (xx % 5 == 1), "hout", 5)
    t.box(0, 4, 16, 6, "hout", 2)
    # ijzeren beugel onder elke tegel
    t.fill((xx >= 6) & (xx <= 7) & (yy >= 6) & (yy <= 12), "ijzer", 4)
    t.fill(((xx - 6) == (yy - 6)) & (yy >= 6) & (yy <= 12) & (xx <= 12), "ijzer", 3)
    t.fill((xx == 6) & (yy >= 6), "ijzer", 6)
    if kant == "l":
        t.box(0, 0, 1, 6, "hout", 2)
    if kant == "r":
        t.box(15, 0, 16, 6, "hout", 2)
    return t


def paal():
    t = T()
    yy, xx = np.mgrid[0:16, 0:16]
    t.box(5, 0, 11, 16, "hout", 3)
    t.box(5, 0, 6, 16, "hout", 1)
    t.box(9, 0, 10, 16, "hout", 5)
    t.fill((yy % 7 == 3) & (xx >= 6) & (xx <= 9), "hout", 2)
    return t


def sluisdeur(deel):
    t = T()
    yy, xx = np.mgrid[0:16, 0:16]
    t.fill(yy >= 0, "hout", 3)
    t.fill(xx % 4 == 0, "hout", 2)                 # verticale planken
    t.fill((xx % 4 == 2) & (yy % 5 == 1), "hout", 4)
    t.box(0, 6, 16, 9, "roest", 3)                 # ijzeren band (geroest)
    t.box(0, 6, 16, 7, "roest", 5)
    t.fill((yy == 7) & (xx % 6 == 2), "ijzer", 6)  # klinknagels
    if deel == "boven":
        t.box(0, 0, 16, 3, "hout", 5)
        t.box(0, 0, 16, 1, "hout", 6)
    if deel == "onder":
        t.add(yy >= 10, -1)
        t.fill((yy >= 12) & ((xx * 7 + yy * 3) % 5 == 0), "klimop", 1)
    return t


def trap(kant):
    """Stenen trap 45 graden: treden van 4x4 px."""
    t = T()
    yy, xx = np.mgrid[0:16, 0:16]
    xs = xx if kant == "op" else 15 - xx
    vol = yy >= 15 - (xs // 4) * 4 - 3
    t.fill(vol, "steen", 3)
    neus = vol & ((yy == 15 - (xs // 4) * 4 - 3))
    t.fill(neus, "steen", 6)
    t.fill(vol & ((yy == 15 - (xs // 4) * 4 - 2)), "steen", 5)
    t.fill(vol & (xs % 4 == (0 if kant == "op" else 3)) & ~neus, "steen", 2)
    return t


def luik(kant, gebroken=False):
    """Luik in de kade (poort van de lus, V-01): 32x16, met zichtbare scheur (L-03)."""
    t = T()
    yy, xx = np.mgrid[0:16, 0:16]
    gx = xx + (0 if kant == "l" else 16)
    t.box(0, 0, 16, 16, "hout", 3)
    t.fill((gx % 6 == 0), "hout", 2)
    t.box(0, 0, 16, 2, "ijzer", 4)          # ijzeren rand
    t.box(0, 0, 16, 1, "ijzer", 6)
    t.box(0, 13, 16, 16, "ijzer", 3)
    if kant == "l":
        t.box(0, 0, 2, 16, "ijzer", 4)
    else:
        t.box(14, 0, 16, 16, "ijzer", 4)
    t.fill((yy == 7) & (gx % 8 == 4), "ijzer", 6)
    # de scheur: zigzag over het midden, lichter hout (vers breukvlak) met een donkere spleet
    zig = 14 + np.round(2.5 * np.sin(yy * 1.3)).astype(int)
    scheur = (np.abs(gx - zig) <= 0) & (yy >= 2) & (yy <= 12)
    t.fill(scheur, "raamdonker", 0)
    t.fill((np.abs(gx - zig) == 1) & (yy >= 2) & (yy <= 12), "hout", 6)
    t.fill((np.abs(gx - zig - 2) == 0) & (yy >= 4) & (yy <= 9), "hout", 5)
    if gebroken:
        gat = (np.abs(gx - 16) < 11 + np.round(1.5 * np.sin(yy * 2.1))) & (yy >= 2) & (yy <= 13)
        t.fill(gat, "raamdonker", 0)
        t.fill(ndimage.binary_dilation(gat) & ~gat, "hout", 6)
    return t


def kelderbodem(seed):
    t = T()
    blokken(t, 0, 16, 16, 8, "steen", 2, seed)
    t.box(0, 0, 16, 1, "steen", 4)
    return t


def rooster():
    t = T()
    yy, xx = np.mgrid[0:16, 0:16]
    t.fill(yy >= 0, "raamdonker", 0)
    t.fill((xx % 4 == 1), "ijzer", 4)
    t.fill((xx % 4 == 1) & (yy < 2), "ijzer", 6)
    t.box(0, 0, 16, 2, "ijzer", 3)
    t.box(0, 14, 16, 16, "ijzer", 3)
    return t


TILE_LIJST = [
    # rij 0: kade (blauwe hardsteen)
    ("kade_boven_l", kade_boven(1, "l")), ("kade_boven_m1", kade_boven(2)), ("kade_boven_m2", kade_boven(3)),
    ("kade_boven_r", kade_boven(4, "r")), ("kade_wand_hoog_m1", kade_wand(6, 3)), ("kade_wand_hoog_m2", kade_wand(7, 3)),
    ("kade_wand_laag_m1", kade_wand(8, 2)), ("kade_wand_laag_m2", kade_wand(9, 2)), ("kade_meerring", kade_meerring()),
    ("kade_getij_m1", kade_getij(10)), ("kade_getij_m2", kade_getij(11)), ("kade_voet_m1", kade_voet(12)),
    ("kade_voet_m2", kade_voet(13)), ("kelderbodem_m1", kelderbodem(14)), ("kelderbodem_m2", kelderbodem(15)),
    ("rooster", rooster()),
    # rij 1: baksteen (gemaal, huizen), duiker
    ("baksteen_m1", baksteen(20)), ("baksteen_m2", baksteen(21)), ("baksteen_donker_m1", baksteen(22, 2)),
    ("baksteen_donker_m2", baksteen(23, 2)), ("baksteen_dek", baksteen_dek(24)), ("baksteen_speklaag", baksteen_speklaag(25)),
    ("duikerboog_l", boog("l")), ("duikerboog_r", boog("r")), ("duiker_binnen", None),
    ("trap_op", trap("op")), ("trap_neer", trap("neer")), ("trap_vul", None),
    ("luik_l", luik("l")), ("luik_r", luik("r")), ("luik_gebroken_l", luik("l", True)), ("luik_gebroken_r", luik("r", True)),
    # rij 2: water, hout
    ("water_opp_f0", water_opp(0)), ("water_opp_f1", water_opp(1)), ("water_opp_f2", water_opp(2)),
    ("water_opp_f3", water_opp(3)), ("water_vol_m1", water_vol(1)), ("water_vol_m2", water_vol(2)),
    ("onderwater_loopbrug", onderwater_loopbrug()), ("loopbrug_l", loopbrug("l")), ("loopbrug_m", loopbrug("m")),
    ("loopbrug_r", loopbrug("r")), ("paal", paal()), ("sluisdeur_boven", sluisdeur("boven")),
    ("sluisdeur_mid", sluisdeur("mid")), ("sluisdeur_onder", sluisdeur("onder")), ("leeg_1", None), ("leeg_2", None),
]


def _vul(name):
    t = T()
    if name == "duiker_binnen":
        t.fill(np.ones((16, 16), bool), "raamdonker", 1)
        yy, xx = np.mgrid[0:16, 0:16]
        t.fill((yy % 8 == 0), "raamdonker", 0)
    elif name == "trap_vul":
        blokken(t, 0, 16, 16, 8, "steen", 2, 30)
    return t


TILES_FIN = [(n, (t if t is not None else _vul(n))) for n, t in TILE_LIJST]
KOLOM = 16


def atlas(staat):
    rows = (len(TILES_FIN) + KOLOM - 1) // KOLOM
    img = np.zeros((rows * 16, KOLOM * 16, 4))
    for i, (n, t) in enumerate(TILES_FIN):
        if n.startswith("leeg"):
            continue
        y, x = divmod(i, KOLOM)
        img[y * 16:(y + 1) * 16, x * 16:(x + 1) * 16] = t.render(staat)
    return img


def index_atlas(items, w, h):
    """R = materiaal-id, G = tint x 32 (+16), A = 255; leeg = A 0. Bron voor de palet-LUT (TA)."""
    img = np.zeros((h, w, 4), np.uint8)
    for (x, y, t) in items:
        hh, ww = t.mat.shape
        ok = t.mat >= 0
        sub = img[y:y + hh, x:x + ww]
        sub[ok, 0] = t.mat[ok]
        sub[ok, 1] = np.clip(t.t[ok], 0, 7) * 32 + 16
        sub[ok, 3] = 255
    return Image.fromarray(img, "RGBA")


def save_rgba(img, path, scale=1):
    im = Image.fromarray((np.clip(img, 0, 1) * 255 + 0.5).astype(np.uint8), "RGBA")
    if scale != 1:
        im = im.resize((im.width * scale, im.height * scale), Image.NEAREST)
    im.save(path)
    return im


# ------------------------------------------------------------------ props
def pomprad_frame(f, n=8):
    """Pomprad 64x64 (schoepenrad aan de gevel), frame f van n; elk frame getekend, niet gedraaid."""
    t = T(64, 64)
    yy, xx = np.mgrid[0:64, 0:64]
    cx, cy = 31.5, 31.5
    d = np.hypot(xx - cx, yy - cy)
    a = np.arctan2(yy - cy, xx - cx)
    rot = f * (2 * np.pi / 8) / n  # 8 schoepen: na n frames een schoep verder
    t.fill((d >= 22) & (d < 25), "ijzer", 4)          # velg
    t.fill((d >= 22) & (d < 23), "ijzer", 6)
    t.fill((d >= 24) & (d < 25), "ijzer", 2)
    for k in range(8):
        ak = rot + k * np.pi / 4
        # spaak
        da = np.angle(np.exp(1j * (a - ak)))
        sp = (np.abs(da * d) < 1.2) & (d < 22) & (d > 5)
        t.fill(sp, "ijzer", 4 if np.cos(ak + 0.8) > 0 else 3)
        # schoep: plank buiten de velg
        sch = (np.abs(da * d) < 2.6) & (d >= 25) & (d < 32)
        t.fill(sch, "hout", 4 if np.sin(ak) < 0 else 3)
        t.fill(sch & (np.abs(da * d) >= 1.8), "hout", 2)
        t.fill(sch & (d >= 31), "hout", 5)
    t.fill(d < 6, "ijzer", 3)                            # naaf
    t.fill(d < 3, "koper", 5)
    t.fill((d < 6) & (yy < cy - 2), "ijzer", 5)
    return t


def lamp(aan):
    """Straatlamp met kap, 16x48: kern in een donker frame van ijzer (bible §4.2)."""
    t = T(16, 48)
    t.box(7, 12, 9, 48, "ijzer", 3)
    t.box(7, 12, 8, 48, "ijzer", 5)
    t.box(5, 44, 11, 48, "ijzer", 2)
    t.box(4, 2, 12, 4, "ijzer", 4)       # kap
    t.box(3, 4, 13, 5, "ijzer", 3)
    t.box(5, 5, 11, 11, "ijzer", 2)      # frame
    if aan:
        t.box(6, 6, 10, 10, "gloed", 6)
        t.box(7, 7, 9, 9, "gloed", 7)
    else:
        t.box(6, 6, 10, 10, "raamdonker", 3)
        t.box(7, 7, 8, 8, "raamdonker", 5)
    t.box(6, 11, 10, 12, "ijzer", 4)
    return t


def halo():
    """Halo van een lamp in 3 ringen, 32x32 (tint 3/4/5, gedithered 50/75/100 %)."""
    t = T(32, 32)
    yy, xx = np.mgrid[0:32, 0:32]
    d = np.hypot(xx - 15.5, yy - 15.5)
    bay = R.bayer(32, 32)
    t.fill((d < 15) & (bay < 0.5), "gloed", 3)
    t.fill((d < 10) & (bay < 0.75), "gloed", 4)
    t.fill(d < 6, "gloed", 5)
    # kruisstralen (h 6 px, omlaag 4, omhoog 2) en 4 diagonale stippen
    t.fill((yy == 15) & (np.abs(xx - 15.5) < 15.5) & (np.abs(xx - 15.5) > 9), "gloed", 5)
    t.fill((xx == 15) & (yy > 21) & (yy < 26), "gloed", 5)
    t.fill((xx == 15) & (yy < 9) & (yy > 6), "gloed", 5)
    for sx, sy in [(-1, -1), (1, -1), (-1, 1), (1, 1)]:
        t.fill((xx == int(15.5 + sx * 8)) & (yy == int(15.5 + sy * 8)), "gloed", 6)
    return t


def boograam(aan):
    """Boograam van het gemaal, 32x48; aan = warm verlicht met de koperen machine erachter."""
    t = T(32, 48)
    yy, xx = np.mgrid[0:48, 0:32]
    d = np.hypot(xx - 15.5, yy - 15.5)
    vorm = ((d < 14) & (yy < 16)) | ((xx >= 2) & (xx < 30) & (yy >= 15) & (yy < 44))
    rand = ndimage.binary_dilation(vorm, iterations=2) & ~vorm
    t.fill(rand, "steen", 4)
    t.fill(rand & (yy < 14), "steen", 5)
    t.fill(ndimage.binary_dilation(vorm) & ~vorm, "steen", 2)
    if aan:
        t.fill(vorm, "raam", 5)
        t.fill(vorm & (yy > 30), "raam", 4)
        mach = vorm & (((np.hypot(xx - 12, yy - 30) < 7) & (np.hypot(xx - 12, yy - 30) > 4)) |
                       ((xx >= 18) & (xx <= 20) & (yy >= 14)) | ((yy >= 38) & (yy <= 40)))
        t.fill(mach, "koper", 2)
    else:
        t.fill(vorm, "raamdonker", 2)
        t.fill(vorm & (yy > 30), "raamdonker", 1)
    roe = vorm & ((xx == 15) | (xx == 16) | (yy == 28))
    t.fill(roe, "ijzer", 2)
    t.box(0, 44, 32, 48, "steen", 4)     # dorpel
    t.box(0, 44, 32, 45, "steen", 6)
    return t


def bolder():
    t = T(16, 16)
    yy, xx = np.mgrid[0:16, 0:16]
    body = ((xx >= 4) & (xx <= 11) & (yy >= 6)) | ((np.hypot(xx - 7.5, yy - 6) < 5.2) & (yy < 7))
    t.fill(body, "ijzer", 3)
    t.fill(body & (xx <= 5), "ijzer", 2)
    t.fill(body & (xx >= 9) & (xx <= 10), "ijzer", 5)
    t.fill((yy == 2) & (xx >= 5) & (xx <= 9), "ijzer", 6)
    t.box(3, 14, 13, 16, "ijzer", 2)
    return t


def sluisbalk():
    """Balans van een puntdeur (de lange balk boven de sluis), 64x16."""
    t = T(64, 16)
    yy, xx = np.mgrid[0:16, 0:64]
    taper = 5 - (xx / 64 * 2).astype(int)
    m = (yy >= 8 - taper) & (yy <= 8 + taper // 2 + 1)
    t.fill(m, "hout", 3)
    t.fill(m & (yy == 8 - taper), "hout", 5)
    t.fill(m & (yy == 8 + taper // 2 + 1), "hout", 1)
    t.box(56, 4, 60, 14, "roest", 3)
    t.fill((xx % 16 == 6) & m, "roest", 4)
    return t


PROPS = [("pomprad_64x64_8f", [pomprad_frame(f) for f in range(8)]),
         ("straatlamp_uit", [lamp(False)]), ("straatlamp_aan", [lamp(True)]), ("halo_lamp_32x32", [halo()]),
         ("boograam_uit", [boograam(False)]), ("boograam_aan", [boograam(True)]), ("bolder", [bolder()]),
         ("sluisbalk_64x16", [sluisbalk()])]


def props_atlas():
    """Props op een atlas van 512 breed, per rij geplaatst; geeft (items, w, h, manifest)."""
    x, y, rowh, W_ = 0, 0, 0, 512
    items, man = [], []
    for name, frames in PROPS:
        h, w = frames[0].mat.shape
        tot = w * len(frames)
        if x + tot > W_:
            x, y, rowh = 0, y + rowh, 0
        for i, fr in enumerate(frames):
            items.append((x + i * w, y, fr))
        man.append((name, x, y, w, h, len(frames)))
        x += tot
        rowh = max(rowh, h)
    return items, W_, y + rowh, man


def render_items(items, w, h, staat):
    img = np.zeros((h, w, 4))
    for (x, y, t) in items:
        hh, ww = t.mat.shape
        r = t.render(staat)
        a = r[..., 3:4]
        img[y:y + hh, x:x + ww] = img[y:y + hh, x:x + ww] * (1 - a) + r * a
    return img


# ------------------------------------------------------------------ studie lichtovergang
W, H = 640, 400
YY, XX = np.mgrid[0:H, 0:W]
KADE_Y = 300          # loopvlak
GRACHT = (208, 384)   # gracht tussen twee kades (x)
WATER = {1: 330, 2: 364}  # wateroppervlak bij stand 1 en 2 (studie, geen kamermaat)
GEMAAL = (436, 600)
BRON = (500, 236)     # middelpunt van het pomprad: hier begint de kleurgolf


def stamp(w_mat, w_t, t, x, y):
    hh, ww = t.mat.shape
    ys, xs = slice(max(0, y), min(H, y + hh)), slice(max(0, x), min(W, x + ww))
    sub = t.mat[ys.start - y:ys.stop - y, xs.start - x:xs.stop - x]
    ok = sub >= 0
    w_mat[ys, xs][ok] = sub[ok]
    w_t[ys, xs][ok] = t.t[ys.start - y:ys.stop - y, xs.start - x:xs.stop - x][ok]


def tegel(naam):
    return dict(TILES_FIN)[naam]


def studie_wereld(water_y, ramen_aan, lampen_aan, rad_f=0):
    mat = np.full((H, W), MI["lucht"], np.int16)
    t = np.zeros((H, W), np.int16)
    laag = np.zeros((H, W), np.int8)  # 0 lucht, 1 ver, 2 huizen, 4 speelvlak
    # lucht: verloop met dithering
    v = 1 + (YY / H * 4.5) + (R.BAY[:H, :W] - 0.5)
    t[:] = np.clip(v, 0, 5).astype(int)
    # verre daklijn met belfort
    rng = hrng(77)
    ver = np.zeros((H, W), bool)
    x = 0
    while x < W:
        bw = int(rng.integers(18, 40))
        top = int(rng.integers(150, 185))
        ver[top:, x:x + bw] = True
        x += bw
    ver[70:, 112:136] = True
    ver[52:70, 118:130] = True
    ver[40:52, 122:126] = True
    gal = (YY >= 84) & (YY < 96) & (((XX - 115) % 6) < 3) & (XX >= 115) & (XX < 133)
    mat[ver] = MI["ver"]
    t[ver] = 2
    laag[ver] = 1
    belfort_gat = gal
    # huizenrij met trapgevels (links van het gemaal)
    kleuren = ["huis_rood", "huis_oker", "huis_wit", "huis_groen", "huis_rood", "huis_wit", "huis_oker"]
    x = 0
    ramen = np.zeros((H, W), bool)
    i = 0
    while x < GEMAAL[0] - 8:
        bw = [56, 48, 64, 52, 60, 48, 56][i % 7]
        top = [176, 160, 186, 168, 158, 182, 170][i % 7]
        m = (XX >= x) & (XX < x + bw) & (YY >= top) & (YY < KADE_Y)
        # trapgevel: treden van 6 px
        for s in range(4):
            m |= (XX >= x + 6 * (s + 1)) & (XX < x + bw - 6 * (s + 1)) & (YY >= top - 8 * (s + 1)) & (YY < top)
        mat[m] = MI[kleuren[i % 7]]
        t[m] = 3
        e = m & ~ndimage.binary_erosion(m)
        t[e & (XX < x + 2)] = 1
        t[e & (YY < top) & ~(XX < x + 2)] = 4
        laag[m] = 2
        for wx in range(x + 8, x + bw - 10, 16):
            for wy in range(top + 10, KADE_Y - 30, 26):
                ramen[wy:wy + 12, wx:wx + 7] = True
        x += bw + 2
        i += 1
    # gemaal: baksteen met speklaag en boograam
    gm = (XX >= GEMAAL[0]) & (XX < GEMAAL[1]) & (YY >= 150) & (YY < KADE_Y)
    gm |= (XX >= GEMAAL[0] + 20) & (XX < GEMAAL[1] - 20) & (YY >= 130) & (YY < 150)
    for yy0 in range(128, KADE_Y, 16):
        for xx0 in range(GEMAAL[0], GEMAAL[1], 16):
            nm = "baksteen_speklaag" if yy0 == 192 else ("baksteen_m1" if (xx0 // 16 + yy0 // 16) % 2 else "baksteen_m2")
            tl = tegel(nm)
            sub = gm[yy0:yy0 + 16, xx0:xx0 + 16]
            mm, tt = mat[yy0:yy0 + 16, xx0:xx0 + 16], t[yy0:yy0 + 16, xx0:xx0 + 16]
            mm[sub] = tl.mat[:sub.shape[0], :sub.shape[1]][sub]
            tt[sub] = tl.t[:sub.shape[0], :sub.shape[1]][sub]
    laag[gm] = 2
    bg = boograam(True)  # trap 1 is vol: het gemaal is al aan (s = 1)
    stamp(mat, t, bg, 532, 210)
    stamp(mat, t, pomprad_frame(rad_f), BRON[0] - 32, BRON[1] - 32)
    # kades (tegels), gracht met water
    for xx0 in range(0, W, 16):
        if GRACHT[0] <= xx0 < GRACHT[1]:
            continue
        kop = "l" if xx0 == GRACHT[1] else ("r" if xx0 == GRACHT[0] - 16 else None)
        top = {"l": "kade_boven_l", "r": "kade_boven_r"}.get(kop, "kade_boven_m1" if xx0 % 32 else "kade_boven_m2")
        stamp(mat, t, tegel(top), xx0, KADE_Y)
        for yy0 in range(KADE_Y + 16, H, 16):
            nm = "kade_wand_hoog_m1" if yy0 < 340 else "kade_wand_laag_m2"
            if xx0 == 96 and yy0 == 332:
                nm = "kade_meerring"
            stamp(mat, t, tegel(nm), xx0, yy0)
        laag[KADE_Y:, xx0:xx0 + 16] = 4
    # grachtwanden en loopbrug
    for yy0 in range(KADE_Y, H, 16):
        for xx0 in (GRACHT[0], GRACHT[1] - 16):
            nm = "kade_getij_m1" if (water_y > WATER[1] and yy0 == 320) else ("kade_voet_m1" if yy0 >= 352 else "kade_wand_laag_m1")
            stamp(mat, t, tegel(nm), xx0, yy0)
        stamp(mat, t, tegel("duiker_binnen"), GRACHT[0] + 16, yy0)
    for xx0 in range(GRACHT[0] + 16, GRACHT[1] - 16, 16):
        for yy0 in range(KADE_Y, H, 16):
            stamp(mat, t, tegel("baksteen_donker_m1" if (xx0 // 16) % 2 else "baksteen_donker_m2"), xx0, yy0)
    lb_y = 352
    for k, xx0 in enumerate(range(GRACHT[0] + 16, GRACHT[0] + 96, 16)):
        nm = "loopbrug_l" if k == 0 else ("loopbrug_r" if k == 4 else "loopbrug_m")
        stamp(mat, t, tegel(nm), xx0, lb_y)
    laag[KADE_Y:, GRACHT[0]:GRACHT[1]] = 4
    # water in de gracht
    wm = (XX >= GRACHT[0] + 16) & (XX < GRACHT[1] - 16) & (YY >= water_y)
    onder = wm & (mat != MI["water"])
    vorm_onder = onder & ((mat == MI["hout"]) | (mat == MI["ijzer"]))
    mat[wm] = MI["water"]
    t[wm] = 1
    t[vorm_onder & ~ndimage.binary_erosion(vorm_onder)] = 3   # contour onder water (bible §4.5)
    t[vorm_onder & ndimage.binary_erosion(vorm_onder)] = 2
    surf = (YY == water_y) & (XX >= GRACHT[0] + 16) & (XX < GRACHT[1] - 16)
    t[surf] = np.where(((XX[surf] // 5) % 4) != 0, 6, 4)
    # ramen
    mat[ramen] = MI["raam"] if ramen_aan is True else MI["raamdonker"]
    t[ramen] = 5 if ramen_aan is True else 2
    if isinstance(ramen_aan, np.ndarray):
        lit = ramen & ramen_aan
        mat[ramen] = MI["raamdonker"]
        t[ramen] = 2
        mat[lit] = MI["raam"]
        t[lit] = 5
    # straatlampen
    lamp_pos = [(132, KADE_Y - 48), (404, KADE_Y - 48)]
    for k, (lx, ly) in enumerate(lamp_pos):
        stamp(mat, t, lamp(lampen_aan[k]), lx, ly)
    return mat, t, laag, ramen, belfort_gat, lamp_pos


def lichtband(lamp_pos, lampen_aan):
    band = np.zeros((H, W))
    for k, (lx, ly) in enumerate(lamp_pos):
        if not lampen_aan[k]:
            continue
        d = np.hypot(XX - (lx + 8), (YY - (ly + 8)) * 1.15)
        b = np.select([d < 14, d < 30, d < 52, d < 80], [4, 3, 2, 1], 0).astype(float)
        # gedithered verloop tussen banden (bible §4.1)
        frac = np.clip((np.select([d < 14, d < 30, d < 52, d < 80], [14, 30, 52, 80], 80) - d) / 6, 0, 1)
        b = np.where((frac < 1) & (R.BAY[:H, :W] > frac) & (b > 0), b - 1, b)
        band = np.maximum(band, b)
    return band


def render_studie(water_y, ramen_aan, lampen_aan, golf_r=None, vol_r=None, rad_f=0, figs=None, echo_kleur=False):
    mat, t, laag, ramen, gat, lamp_pos = studie_wereld(water_y, ramen_aan, lampen_aan, rad_f)
    band = lichtband(lamp_pos, lampen_aan)
    # toestand per pixel: 0 grijs, 1 half, 2 kleur
    st = np.zeros((H, W), np.int8)
    if golf_r is not None:
        d = np.hypot(XX - BRON[0], YY - BRON[1])
        edge = 10.0
        half = (d < golf_r - edge) | ((d < golf_r) & (R.BAY[:H, :W] < (golf_r - d) / edge))
        vol = (d < vol_r - edge) | ((d < vol_r) & (R.BAY[:H, :W] < (vol_r - d) / edge))
        st[half] = 1
        st[vol] = 2
    # licht = kleur: band 2 -> half, >= 3 -> vol
    st = np.maximum(st, np.where(band >= 3, 2, np.where(band >= 2, 1, 0))).astype(np.int8)
    # omgeving: grijs 1, half/kleur 2 (lucht 0 en ver 1 blijven)
    omg = np.where(laag >= 2, np.where(st == 0, -1, 0), 0)
    ti = np.clip(t + omg + band.astype(int), 0, 7)
    img = np.zeros((H, W, 3))
    for s, ramp in enumerate([G, HALF, K]):
        m = st == s
        img[m] = ramp[mat[m], ti[m]]
    # een verlicht raam is een lichtbron (emissief): het houdt in elke toestand zijn kleur
    em = mat == MI["raam"]
    img[em] = K[mat[em], np.clip(t[em], 0, 7)]
    # volumetrische bundels in de lucht: koud (grijs) of warm (kleur, uit het belfort)
    lucht = laag == 0
    koud = lucht & (((XX * 0.6 + YY) % 90) < 7) & (R.BAY[:H, :W] < 0.3) & (YY < 200)
    warm = lucht & (np.abs((XX - 124) * 0.35 - (YY - 90) * -0.9) < 26) & (YY < 120) & (R.BAY[:H, :W] < 0.35)
    img[koud & (st == 0)] = G[MI["lucht"], 5]
    img[warm & (st == 2)] = K[MI["gloed"], 1]
    img[gat & (st == 2)] = K[MI["gloed"], 4]
    # halo's van de lampen (sprite, emissief)
    for k, (lx, ly) in enumerate(lamp_pos):
        if lampen_aan[k]:
            hl = halo().render("kleur")
            y0, x0 = ly + 8 - 16, lx + 8 - 16
            sub = img[y0:y0 + 32, x0:x0 + 32]
            a = hl[..., 3:4]
            sub[:] = sub * (1 - a) + hl[..., :3] * a
    if figs:
        for kind, rows, x, y, flip in figs:
            state = "kleur" if (kind == "p1" or echo_kleur) else "grijs"
            lay, _ = R.fig_layer(kind, rows, x, y, state, flip=flip)
            img = R.over(img, lay)
    return img, st


def studie():
    """Lichtovergang trap 2 -> wijk verlicht (s = 1 -> 2). Studie op 640x400, geen kamer."""
    fps = 10
    v = 300.0          # px/s, voorkant 'half'
    lag = 0.4          # s, voorkant 'vol' komt later
    echo_lag = 0.5     # s, de echo kleurt mee na de vol-golf (bible §5)
    t_water = 3.0      # s, water zakt (180 ticks, gdd LM-06/K3)
    figs_x = dict(p1=(420, KADE_Y), echo=(170, KADE_Y))
    frames, stills = [], []
    rmax = float(np.hypot(BRON[0], BRON[1] + 20))
    T_end = (rmax / v) + lag + echo_lag + 0.6
    n_hold = 8
    # elk raam krijgt één vertraging (niet per pixel), zodat ramen één voor één aangaan
    _, _, _, ramen0, _, _ = studie_wereld(WATER[1], False, [False, False])
    lab_r, n_r = ndimage.label(ramen0)
    ramen_rng = np.concatenate([[0], hrng(5).random(n_r)])[lab_r]
    tijden = [-0.8] * n_hold + list(np.arange(0, T_end, 1 / fps)) + [T_end] * n_hold
    for k, tt in enumerate(tijden):
        ts = max(tt, 0)
        golf = v * ts if tt >= 0 else -1
        vol = v * (ts - lag) if tt >= 0 else -1
        wy = int(round(WATER[1] + (WATER[2] - WATER[1]) * min(ts / t_water, 1))) if tt >= 0 else WATER[1]
        # ramen gaan aan zodra de half-golf ze bereikt, licht verspreid (niet allemaal tegelijk)
        d = np.hypot(XX - BRON[0], YY - BRON[1])
        ramen_aan = (d + ramen_rng * 40) < golf
        d_l = [np.hypot(132 + 8 - BRON[0], KADE_Y - 40 - BRON[1]), np.hypot(404 + 8 - BRON[0], KADE_Y - 40 - BRON[1])]
        lampen = [golf > dl for dl in d_l]
        d_echo = np.hypot(figs_x["echo"][0] - BRON[0], figs_x["echo"][1] - 15 - BRON[1])
        echo_k = tt >= 0 and (vol - echo_lag * v) > d_echo
        fr = (k // 2) % 4
        figs = [("echo", SP.P1_RUN[fr % len(SP.P1_RUN)], figs_x["echo"][0], figs_x["echo"][1], False),
                ("p1", SP.P1_IDLE, figs_x["p1"][0], figs_x["p1"][1], True)]
        img, st = render_studie(wy, ramen_aan, lampen, golf, vol, rad_f=k % 8, figs=figs, echo_kleur=echo_k)
        pc = img[R.PC[0]:R.PC[1]]
        frames.append(pc)
        stills.append((tt, pc, st[R.PC[0]:R.PC[1]]))
    return frames, stills, dict(v=v, lag=lag, echo_lag=echo_lag, t_water=t_water, T_end=T_end, fps=fps)


# ------------------------------------------------------------------ kleurscript
TW, TH = 160, 90
TY, TX = np.mgrid[0:TH, 0:TW]
TB = R.bayer(TH, TW)


def chroma_van(img):
    lab = LAB(img)
    return float(np.mean(np.hypot(lab[..., 1], lab[..., 2])))


def thumb(beat):
    """Een beat van het kleurscript: waarden en kleur, geen detail en geen kamermaten."""
    kind, s, poel, key = beat["kind"], beat["s"], beat.get("poel", []), beat["key"]
    mat = np.full((TH, TW), MI["lucht"], np.int16)
    t = np.clip((1 + TY / TH * 4 + TB - 0.5), 0, 5).astype(np.int16)
    laag = np.zeros((TH, TW), np.int8)
    floor = 66
    if kind in ("kade", "plein", "brug"):
        rng = hrng(beat["seed"])
        x = 0
        while x < TW:
            bw = int(rng.integers(10, 20))
            top = int(rng.integers(26, 42))
            col = ["huis_rood", "huis_oker", "huis_wit", "huis_groen"][int(rng.integers(0, 4))]
            m = (TX >= x) & (TX < x + bw) & (TY >= top) & (TY < floor)
            m |= (TX >= x + 3) & (TX < x + bw - 3) & (TY >= top - 4) & (TY < top)
            mat[m], t[m], laag[m] = MI[col], 3, 2
            win = m & ((TX - x) % 5 == 2) & ((TY - top) % 8 == 3)
            mat[win], t[win] = (MI["raam"], 5) if beat.get("ramen") else (MI["raamdonker"], 2)
            x += bw + 1
        if beat.get("gemaal"):
            gx = beat["gemaal"]
            m = (TX >= gx) & (TX < gx + 34) & (TY >= 22) & (TY < floor)
            mat[m], t[m], laag[m] = MI["baksteen"], 3, 2
            wv = (np.hypot(TX - (gx + 17), TY - 40) < 7)
            mat[wv & m], t[wv & m] = (MI["raam"], 5) if beat.get("gemaal_aan") else (MI["raamdonker"], 2)
        if kind == "brug":
            m = (TX >= 64) & (TX < 70) & (TY >= 18) & (TY < floor)
            m |= (TX >= 66) & (TX < 100) & (np.abs(TY - (18 + (TX - 66) * 0.2)) < 2)
            mat[m], t[m], laag[m] = MI["hout"], 2, 4
        m = (TY >= floor) & (TY < floor + 6)
        if kind == "brug":
            m &= (TX < 64) | (TX > 104)
        mat[m], t[m], laag[m] = MI["steen"], 4, 4
        t[(TY == floor) & m] = 6
        m = (TY >= floor + 6)
        mat[m], t[m], laag[m] = MI["steen"], 2, 4
        wy = {0: 72, 1: 78, 2: 84}[s]
        m = (TY >= wy) & (((TX > 40) & (TX < 120)) if kind != "plein" else (TX > 100))
        if kind == "brug":
            m = (TY >= wy) & (TX >= 64) & (TX <= 104)
        mat[m], t[m] = MI["water"], 1
        t[(TY == wy) & m] = 5
        if s == 2:
            g = (TY >= 72) & (TY < 75) & ~m & (TY > floor + 5)
            mat[g], t[g] = MI["klimop"], 2
    else:  # interieur
        wand = {"huis": "huis_wit", "kelder": "steen", "hal": "baksteen"}[kind]
        mat[:], t[:], laag[:] = MI[wand], 2, 2
        blk = ((TY % 6 == 0) | ((TX + (TY // 6) % 2 * 6) % 12 == 0))
        t[blk] = 1
        m = TY >= floor + 4
        mat[m], t[m], laag[m] = MI["steen"], 3, 4
        t[(TY == floor + 4)] = 5
        if kind == "huis":
            w_ = (TX >= 100) & (TX < 118) & (TY >= 20) & (TY < 46)
            mat[w_], t[w_] = MI["lucht"], 3
            mat[(TX == 109) & w_], t[(TX == 109) & w_] = MI["hout"], 1
            m = (TX >= 30) & (TX < 70) & (TY >= 40) & (TY < 44)
            mat[m], t[m] = MI["hout"], 3
        if kind == "kelder":
            m = (TY >= 74) & (TX > 50) & (TX < 120)
            mat[m], t[m] = MI["water"], 1
            t[(TY == 74) & m] = 4
            m = (TX >= 20) & (TX < 32) & (TY >= 58) & (TY < floor + 4)
            mat[m], t[m] = MI["steen"], 4
        if kind == "hal":
            body = ((np.hypot(TX - 80, TY - 56) < 16) | ((np.abs(TX - 80) < 10) & (TY > 24) & (TY < 56)))
            mat[body], t[body], laag[body] = MI["vijandlijf"], 2, 3
            rad = np.abs(np.hypot((TX - 36) * 0.5, TY - 30) - 8) < 1.5
            mat[rad], t[rad], laag[rad] = MI["ijzer"], 4, 3
            beam = (np.abs(TY - 26) < 1) & (TX > 36) & (TX < 76)
            mat[beam], t[beam], laag[beam] = MI["ijzer"], 3, 3
            core = np.hypot(TX - 80, TY - 56) < 5
            mat[core], t[core] = MI["vijandkern"], 5
            top = body & ~np.roll(body, 1, 0)
            mat[top], t[top] = MI["vijandkern"], 4
    st = np.full((TH, TW), {"grijs": 0, "half": 1, "kleur": 2}[beat["staat"]], np.int8)
    band = np.zeros((TH, TW))
    for (px, py, r, matk) in poel:
        d = np.hypot(TX - px, (TY - py) * 1.2)
        b = np.select([d < r * 0.3, d < r * 0.6, d < r], [4, 3, 2], 0)
        band = np.maximum(band, b)
        k = d < 2.5
        mat[k], t[k] = MI[matk], 7
    st = np.maximum(st, np.where(band >= 3, 2, np.where(band >= 2, 1, 0))).astype(np.int8)
    omg = np.where(laag >= 2, np.where(st == 0, -1, 0), 0)
    ti = np.clip(t + omg + band.astype(int), 0, 7)
    img = np.zeros((TH, TW, 3))
    for s_, ramp in enumerate([G, HALF, K]):
        m = st == s_
        img[m] = ramp[mat[m], ti[m]]
    if beat["staat"] == "grijs" and kind not in ("huis", "kelder", "hal"):
        koud = (laag == 0) & (((TX * 0.6 + TY) % 40) < 3) & (TB < 0.3)
        img[koud] = G[MI["lucht"], 5]
    # halo van elke lichtbron (bible §4.2): warme ringen, gedithered, over alles behalve vloer en water
    for (px, py, r, matk) in poel:
        d = np.hypot(TX - px, (TY - py) * 1.2)
        for rr, dens, tk in [(r * 0.6, 0.25, 3), (r * 0.4, 0.5, 4), (r * 0.2, 1.0, 5)]:
            m = (d < rr) & (TB < dens) & (laag < 4)
            img[m] = K[MI["gloed"], tk]
    for (fx, fy, col) in beat.get("stippen", []):
        img[fy - 2:fy + 1, fx - 1:fx + 2] = hx(col)
    return img


BEATS = [
    dict(id="S1", naam="KADE-INGANG", kind="kade", s=0, staat="grijs", seed=1, gemaal=124, key="lantaarn",
         poel=[(40, 50, 26, "gloed")], stippen=[(48, 66, "#f29a26")]),
    dict(id="S2", naam="KADEGANG", kind="kade", s=0, staat="grijs", seed=2, key="geen (koud)",
         stippen=[(90, 66, "#ff475c"), (98, 66, "#ff475c")]),
    dict(id="S3", naam="VISMARKT", kind="plein", s=0, staat="grijs", seed=3, key="kraamlamp",
         poel=[(60, 50, 30, "gloed")], stippen=[(40, 66, "#ff475c"), (48, 66, "#ff475c"), (100, 66, "#ff475c")]),
    dict(id="S4", naam="BRUGKLOOF", kind="brug", s=0, staat="grijs", seed=4, key="koude bundel",
         stippen=[(130, 66, "#ff475c")]),
    dict(id="S5", naam="SLUISWACHTERSHUIS", kind="huis", s=0, staat="grijs", key="olielamp, 2 koppen",
         poel=[(50, 38, 30, "gloed")]),
    dict(id="S6", naam="GEMAALPLEIN TRAP 1", kind="plein", s=1, staat="grijs", seed=6, gemaal=110, gemaal_aan=True,
         key="gemaal gaat aan", poel=[(127, 40, 48, "raam"), (80, 50, 26, "gloed")]),
    dict(id="S7", naam="SLUISKELDER", kind="kelder", s=1, staat="grijs", key="sokkel neerslag",
         poel=[(26, 52, 22, "gloed")], stippen=[(76, 50, "#ff475c"), (100, 50, "#ff475c")]),
    dict(id="S8", naam="MACHINEHAL BOSS", kind="hal", s=1, staat="grijs", key="rode kern",
         poel=[]),
    dict(id="S9", naam="LAGE KADE TRAP 2", kind="kade", s=2, staat="kleur", seed=9, gemaal=124, gemaal_aan=True,
         ramen=True, key="warm, hele wijk", poel=[(141, 40, 50, "raam")]),
    dict(id="S1'", naam="TERUG NAAR S1", kind="kade", s=2, staat="kleur", seed=1, gemaal=124, gemaal_aan=True,
         ramen=True, key="stadsgloed", poel=[(40, 50, 26, "gloed")], stippen=[(48, 66, "#f29a26")]),
]


def kleurscript():
    cols, rows = 5, 2
    sc = 2
    pad = 12
    cell_w, cell_h = TW * sc, TH * sc + 44
    Wc = cols * cell_w + (cols + 1) * pad
    graf_h = 150
    Hc = 46 + rows * (cell_h + pad) + graf_h + 30
    img = np.zeros((Hc, Wc, 3)) + BG
    label(img, "KLEURSCRIPT KADEWIJK  S1-S9 EN TERUG   (PLACEHOLDER, GEEN KAMERMATEN)", pad, 14, s=2)
    chrom = []
    for i, b in enumerate(BEATS):
        th = thumb(b)
        c = chroma_van(th)
        chrom.append(c)
        r, cidx = divmod(i, cols)
        x0 = pad + cidx * (cell_w + pad)
        y0 = 46 + r * (cell_h + pad)
        big = np.repeat(np.repeat(th, sc, 0), sc, 1)
        img[y0:y0 + TH * sc, x0:x0 + TW * sc] = big
        label(img, f"{b['id']} {b['naam']}", x0, y0 + TH * sc + 6, s=1)
        label(img, f"WATER S={b['s']}  {b['staat'].upper()}  C={c:.0f}", x0, y0 + TH * sc + 18, (0.6, 0.6, 0.7), s=1)
        label(img, f"LICHT: {b['key'].upper()}", x0, y0 + TH * sc + 30, (0.6, 0.6, 0.7), s=1)
    # grafiek: gemeten gemiddelde chroma per beat
    gy0 = 46 + rows * (cell_h + pad) + 10
    label(img, "GEMIDDELDE CHROMA (CIELAB) PER BEAT, GEMETEN OP DE BEELDEN HIERBOVEN", pad, gy0, s=1)
    gx0, gx1, gh = pad + 20, Wc - pad - 20, graf_h - 40
    base = gy0 + 20 + gh
    img[base, gx0:gx1] = 0.4
    cmax = max(chrom) * 1.1
    pts = []
    for i, c in enumerate(chrom):
        x = int(gx0 + (gx1 - gx0) * (i + 0.5) / len(chrom))
        y = int(base - gh * c / cmax)
        pts.append((x, y))
        img[y - 3:y + 4, x - 3:x + 4] = hx("#fbc058") if BEATS[i]["staat"] == "kleur" else hx("#a8a19f")
        label(img, BEATS[i]["id"], x - 6, base + 6, (0.7, 0.7, 0.8), s=1)
    for (xa, ya), (xb, yb) in zip(pts, pts[1:]):
        n = max(abs(xb - xa), 1)
        for k in range(n):
            x = xa + k
            y = int(ya + (yb - ya) * k / n)
            img[y, x] = 0.7
    return img, chrom


# ------------------------------------------------------------------ figuren (concept)
def masker(w, h, f):
    yy, xx = np.mgrid[0:h, 0:w]
    return f(xx, yy)


def vijand_render(body, kern, ogen, extra=None, staat="kleur", donker=True):
    """Vijandregels: vol donker lijf, rode bovenrand, rode kern, witte ogen, contour 1 px.
    In het donker (wijk niet opgepompt) gloeien bovenrand en kern een tint feller (VJ-06)."""
    h, w = body.shape
    out = np.zeros((h, w, 4))
    lijf = K[MI["vijandlijf"]]
    kc = K[MI["vijandkern"]]

    def put(m, c):
        out[m, :3] = c
        out[m, 3] = 1
    put(body, lijf[2])
    # vorm in tinten: onderkant donkerder, binnenrand iets lichter
    yy, xx = np.mgrid[0:h, 0:w]
    rows = np.where(body.any(1))[0]
    if len(rows):
        put(body & (yy > rows.min() + (rows.max() - rows.min()) * 0.65), lijf[1])
    inner = body & ~ndimage.binary_erosion(body)
    put(inner, lijf[4])
    top = body & ~np.vstack([np.zeros((1, w), bool), body[:-1]])
    # bovenrand van 2 px: een gloeiende lijn (tint 7) met rood eronder; in het donker is het rood feller
    onder = body & ~top & np.vstack([np.zeros((1, w), bool), top[:-1]])
    put(onder, kc[5 if donker else 4])
    put(top, kc[7])
    if extra is not None:
        for m, c in extra:
            put(m, c)
    put(kern, kc[5 if donker else 4])
    put(kern & ndimage.binary_erosion(kern), kc[7 if donker else 6])
    put(ogen, hx("#f4f0ff"))
    cont = ndimage.binary_dilation(out[..., 3] > 0) & ~(out[..., 3] > 0)
    out[cont, :3] = hx("#05040a")
    out[cont, 3] = 1
    return out


def kadeloper(pose):
    """Kadeloper: laag, breed, gebogen rug met stekels (slib en riet), een bootshaak. 30x26 beeld,
    hurtbox 16x24 (combat §2.2). pose: idle, aanloop, actief, stil."""
    w, h = 34, 28
    yy, xx = np.mgrid[0:h, 0:w]
    cx = 14
    rug = ((xx - cx) / 11.0) ** 2 + ((yy - 17) / 8.5) ** 2 < 1
    rug &= yy < 24
    poten = ((np.abs(xx - (cx - 6)) < 2) | (np.abs(xx - (cx + 5)) < 2)) & (yy >= 22) & (yy < 28)
    kop = (((xx - (cx + 9)) / 4.5) ** 2 + ((yy - 18) / 3.8) ** 2) < 1
    body = rug | poten | kop
    # stekels op de rug
    for sx in range(cx - 9, cx + 8, 3):
        hgt = 3 + (sx % 2)
        st = (yy >= 9 - hgt + abs(sx - cx) // 3) & (yy < 11 + abs(sx - cx) // 3) & (np.abs(xx - sx) <= (yy - (9 - hgt + abs(sx - cx) // 3)) // 2)
        body |= st
    kern = (np.hypot(xx - (cx + 1), yy - 17) < 2.6)
    ogen = ((xx == cx + 10) | (xx == cx + 12)) & (yy == 17)
    # haak (ijzer): idle laag vooruit, aanloop omhoog boven de kop, actief neergeslagen
    haak = np.zeros((h, w), bool)
    if pose in ("idle", "stil"):
        haak |= (np.abs(yy - (20 + (xx - (cx + 11)) * 0.15)) < 0.7) & (xx > cx + 11) & (xx < cx + 20)
        haak |= (xx == cx + 20) & (yy >= 19) & (yy <= 23)
    elif pose == "aanloop":
        haak |= (np.abs(xx - (cx + 6 + (16 - yy) * 0.35)) < 0.7) & (yy >= 2) & (yy < 16)
        haak |= (yy == 2) & (xx >= cx + 11) & (xx <= cx + 14)
        haak |= (xx == cx + 14) & (yy >= 2) & (yy <= 5)
    elif pose == "actief":
        haak |= (np.abs(yy - (17 + (xx - (cx + 11)) * 0.55)) < 0.8) & (xx > cx + 11) & (xx < cx + 22)
        haak |= (yy == 23) & (xx >= cx + 19) & (xx <= cx + 22)
    if pose == "stil":
        body = np.roll(body, 1, 0)
        kern = np.roll(kern, 1, 0)
        ogen = np.zeros_like(ogen)
        ogen[18, cx + 10:cx + 13] = True
    extra = [(haak, K[MI["ijzer"], 6]), (ndimage.binary_dilation(haak) & ~haak & ~body, K[MI["ijzer"], 2])]
    return body, kern, ogen, extra


def schotdrager(pose, gebroken=False):
    body, kern, ogen, extra = kadeloper("idle" if pose in ("idle", "stil") else pose)
    h, w = body.shape
    yy, xx = np.mgrid[0:h, 0:w]
    if not gebroken:
        dx = {"idle": 0, "aanloop": -2, "actief": 4, "stil": 0}[pose]
        schot = (xx >= 24 + dx) & (xx < 30 + dx) & (yy >= 4) & (yy < 27)
        schot &= ~((xx == 29 + dx) & ((yy < 6) | (yy > 25)))
        klink = schot & ((yy - 4) % 6 == 2) & ((xx - dx) % 3 == 0)
        band = schot & ((yy == 10) | (yy == 20))
        rand = schot & (xx == 24 + dx)
        extra = extra[:0] + [(schot, K[MI["roest"], 3]), (band, K[MI["roest"], 5]), (rand, K[MI["roest"], 1]),
                             (klink, K[MI["ijzer"], 6]), (schot & (yy == 4), K[MI["roest"], 6])]
    else:
        stuk = ((xx >= 25) & (xx < 31) & (yy >= 22) & (yy < 27) & (xx + yy < 53))
        extra = extra + [(stuk, K[MI["roest"], 3])]
    return body, kern, ogen, extra


def dwaallicht(pose):
    """Dwaallicht: een gedoofde lantaarn die op drift is: ijzeren kooi om een rode kern, een
    rafelige sluier van stekels eronder. 20x24 beeld, hurtbox 16x16. Licht is hier rood, nooit warm."""
    w, h = 22, 26
    yy, xx = np.mgrid[0:h, 0:w]
    cx, cy = 10.5, 9.5
    kooi = (np.hypot(xx - cx, yy - cy) < 7.5)
    sluier = (yy >= cy) & (yy < 22) & (np.abs(xx - cx) < 7.5 - (yy - cy) * 0.25) & (((xx + yy) % 4 != 0) | (yy < 15))
    franje = (yy >= 18) & (yy < 24) & ((xx % 3) == 1) & (np.abs(xx - cx) < 6) & (yy < 24 - (xx % 2) * 2)
    body = kooi | sluier | franje
    body |= (xx >= 9) & (xx <= 12) & (yy >= 0) & (yy < 3)  # hengsel (lantaarn, maar zonder warm licht)
    rk = {"idle": 2.6, "aanloop": 4.2, "actief": 3.2, "stil": 1.8}[pose]
    kern = np.hypot(xx - cx, yy - cy) < rk
    spijl = kooi & ((np.abs(xx - cx) < 0.6) | (np.abs(yy - cy) < 0.6) | (np.abs(np.hypot(xx - cx, yy - cy) - 7) < 0.6)) & ~kern
    ogen = ((xx == 8) | (xx == 13)) & (yy == 14)
    extra = [(spijl, K[MI["ijzer"], 5])]
    if pose == "actief":
        body = np.roll(body, 1, 0)
    return body, kern, ogen, extra


def stamp_rgba(img, lay, x, y):
    h, w = lay.shape[:2]
    H_, W_ = img.shape[:2]
    ys0, xs0 = max(0, y), max(0, x)
    ys1, xs1 = min(H_, y + h), min(W_, x + w)
    if ys1 <= ys0 or xs1 <= xs0:
        return
    sub = lay[ys0 - y:ys1 - y, xs0 - x:xs1 - x]
    a = sub[..., 3:4]
    img[ys0:ys1, xs0:xs1] = img[ys0:ys1, xs0:xs1] * (1 - a) + sub[..., :3] * a


def tell_vlak(img, x0, y0, x1, y1, fase, bay=None):
    """Tell-taal (alle vijanden en de boss): het vlak waar de aanval komt, in vijandrood,
    gedithered van 25 % (begin aanloop) naar 75 % (eind), actief = vol met een lichte rand."""
    h, w = img.shape[:2]
    x0, x1, y0, y1 = max(0, x0), min(w, x1), max(0, y0), min(h, y1)
    b = R.bayer(y1 - y0, x1 - x0)
    sub = img[y0:y1, x0:x1]
    kc = K[MI["vijandkern"]]
    if fase == "actief":
        sub[:] = kc[4]
        sub[0, :] = kc[7]
        sub[-1, :] = kc[7]
        sub[:, 0] = kc[7]
        sub[:, -1] = kc[7]
    else:
        dens = {"vroeg": 0.25, "laat": 0.75}[fase]
        m = b < dens
        sub[m] = kc[3] if fase == "vroeg" else kc[4]
        sub[0, :] = np.where(np.arange(x1 - x0) % 4 < 2, 1, 0)[:, None] * kc[6] + (1 - np.where(np.arange(x1 - x0) % 4 < 2, 1, 0)[:, None]) * sub[0, :]


def bereikcirkel(img, cx, cy, eigenaar="amber", r=32):
    """E-14j: bereikcirkel met straal E (32 px), gestippeld in de eigenaarskleur, plus merkkern."""
    col = hx("#f29a26") if eigenaar == "amber" else hx("#3ee6f4")
    h, w = img.shape[:2]
    n = int(2 * np.pi * r)
    for k in range(n):
        if k % 4 < 2:
            a = k / r
            x, y = int(round(cx + r * np.cos(a))), int(round(cy + r * np.sin(a)))
            if 0 <= x < w and 0 <= y < h:
                img[y, x] = col
    f = "merk_kern_peil_amber.png" if eigenaar == "amber" else "merk_kern_sluis_cyaan.png"
    mk = np.asarray(Image.open(os.path.join(REPO, "game", "art", "ui", "wereld", f)).convert("RGBA"), float) / 255
    stamp_rgba(img, mk, cx - 4, cy - 4)


def merk_rand(img, lay, x, y, eigenaar="amber"):
    """Een vijand binnen E krijgt een rand in de eigenaarskleur (E-14j): alleen als overlay."""
    col = hx("#f29a26") if eigenaar == "amber" else hx("#3ee6f4")
    a = lay[..., 3] > 0
    ring = ndimage.binary_dilation(a) & ~a
    ys, xs = np.nonzero(ring)
    for yy_, xx_ in zip(ys + y, xs + x):
        if 0 <= yy_ < img.shape[0] and 0 <= xx_ < img.shape[1] and (xx_ + yy_) % 2 == 0:
            img[yy_, xx_] = col


def achtergrond(w, h, staat, vloer_y):
    """Kadegrond om de figuren op te beoordelen: lucht, gevels, kade (tegels), in grijs of kleur."""
    img = np.zeros((h, w, 3))
    ramp = STAAT[staat]
    dt = -1 if staat == "grijs" else 0
    yy, xx = np.mgrid[0:h, 0:w]
    b = R.bayer(h, w)
    img[:] = ramp[MI["lucht"], np.clip((1 + yy / h * 4 + b - 0.5), 0, 5).astype(int)]
    gev = (yy > vloer_y - 60) & (yy < vloer_y)
    kl = ["huis_wit", "huis_rood", "huis_oker", "huis_groen"]
    for i in range(0, w, 40):
        m = gev & (xx >= i) & (xx < i + 38) & (yy > vloer_y - 60 + (i // 40 % 3) * 8)
        img[m] = ramp[MI[kl[(i // 40) % 4]], 3 + dt]
    for x0 in range(0, w, 16):
        for y0, nm in [(vloer_y, "kade_boven_m1"), (vloer_y + 16, "kade_wand_hoog_m1"), (vloer_y + 32, "kade_wand_laag_m1")]:
            if y0 >= h:
                continue
            r = tegel(nm).render(staat, dt)[: h - y0, : min(16, w - x0)]
            img[y0:y0 + r.shape[0], x0:x0 + r.shape[1]] = r[..., :3]
    return img


def concept_vijanden():
    """Sheet per type: silhouet, idle, aanloop (tell), actief, stil na treffer, merk P1, merk P2;
    rij grijs (donker, s < 2) en rij kleur (verlicht). Native, daarna x4."""
    cw, ch = 96, 92
    vloer = 72
    typen = [("KADELOPER", kadeloper), ("SCHOTDRAGER", schotdrager), ("DWAALLICHT", dwaallicht)]
    kolommen = ["SILHOUET", "IDLE", "AANLOOP 0-15", "AANLOOP 15-30", "ACTIEF 6", "STIL 30", "MERK P1", "MERK P2"]
    lab_h = 14
    Wn = len(kolommen) * cw
    Hn = len(typen) * (2 * ch + lab_h) + lab_h
    img = np.zeros((Hn, Wn, 3)) + BG
    metingen = {}
    for ti, (naam, fn) in enumerate(typen):
        y_base = lab_h + ti * (2 * ch + lab_h)
        for ri, staat in enumerate(["grijs", "kleur"]):
            donker = staat == "grijs"
            for ci, kol in enumerate(kolommen):
                x0, y0 = ci * cw, y_base + lab_h + ri * ch
                cel = achtergrond(cw, ch, staat, vloer)
                pose = {"SILHOUET": "idle", "IDLE": "idle", "AANLOOP 0-15": "aanloop", "AANLOOP 15-30": "aanloop",
                        "ACTIEF 6": "actief", "STIL 30": "stil", "MERK P1": "idle", "MERK P2": "idle"}[kol]
                body, kern, ogen, extra = fn(pose)
                lay = vijand_render(body, kern, ogen, extra, staat, donker)
                h, w = lay.shape[:2]
                if naam == "DWAALLICHT":
                    fx, fy = 36, vloer - 40 - h + (8 if kol == "ACTIEF 6" else 0)
                else:
                    fx, fy = 30, vloer - h + 2
                if kol == "SILHOUET":
                    cel[:] = hx("#ece2cc")
                    sil = lay.copy()
                    sil[..., :3] = hx("#08080e")
                    lay = sil
                # tells
                if naam != "DWAALLICHT":
                    vx0, vx1 = fx + 22, fx + 22 + (24 if naam == "SCHOTDRAGER" else 20)
                    vy0, vy1 = vloer - 20, vloer - 4
                    if kol == "AANLOOP 0-15":
                        tell_vlak(cel, vx0, vy0, vx1, vy1, "vroeg")
                    if kol == "AANLOOP 15-30":
                        tell_vlak(cel, vx0, vy0, vx1, vy1, "laat")
                    if kol == "ACTIEF 6":
                        tell_vlak(cel, vx0, vy0, vx1, vy1, "actief")
                else:
                    kx = fx + 10
                    if kol in ("AANLOOP 0-15", "AANLOOP 15-30"):
                        dens = 0.25 if kol == "AANLOOP 0-15" else 0.75
                        col = K[MI["vijandkern"], 3 if dens < 0.5 else 5]
                        for yy_ in range(fy + h, vloer - 16):
                            if (yy_ // 2) % 2 == 0 and R.bayer(1, 1)[0, 0] < dens + 0.5:
                                cel[yy_, kx:kx + 2] = col
                        tell_vlak(cel, kx - 7, vloer - 18, kx + 9, vloer - 14, "vroeg" if dens < 0.5 else "laat")
                    if kol == "ACTIEF 6":
                        tell_vlak(cel, kx - 7, fy + 4, kx + 9, fy + 20, "actief")
                stamp_rgba(cel, lay, fx, fy)
                if kol in ("MERK P1", "MERK P2"):
                    eig = "amber" if kol == "MERK P1" else "cyaan"
                    merk_rand(cel, lay, fx, fy, eig)
                    bereikcirkel(cel, fx + w // 2 - 2, fy + h // 2, eig)
                if naam == "SCHOTDRAGER" and kol == "STIL 30":
                    body2, kern2, ogen2, extra2 = schotdrager("idle", gebroken=True)
                    cel2 = achtergrond(cw, ch, staat, vloer)
                    stamp_rgba(cel2, vijand_render(body2, kern2, ogen2, extra2, staat, donker), fx, fy)
                    cel = cel2
                img[y0:y0 + ch, x0:x0 + cw] = cel
                if ri == 0 and ti == 0:
                    label(img, kol, x0 + 2, 3, (0.8, 0.8, 0.85), s=1)
                if kol == "IDLE":
                    # meet: lijf, contour en bovenrand tegen de directe achtergrond (ring 2-6 px, bible §7.3)
                    a = np.zeros(cel.shape[:2], bool)
                    a[fy:fy + h, fx:fx + w] = lay[..., 3] > 0
                    ring = ndimage.binary_dilation(a, iterations=6) & ~ndimage.binary_dilation(a, iterations=2)
                    Lc = LAB(cel)[..., 0]
                    Lbg = float(np.median(Lc[ring]))
                    lijf = np.zeros_like(a)
                    lijf[fy:fy + h, fx:fx + w] = body
                    rand = np.zeros_like(a)
                    rand[fy:fy + h, fx:fx + w] = body & ~np.vstack([np.zeros((1, w), bool), body[:-1]])
                    cont = a & ~lijf
                    metingen[f"ring_{naam}_{staat}"] = (abs(float(np.median(Lc[lijf])) - Lbg),
                                                        abs(float(np.median(Lc[cont])) - Lbg),
                                                        abs(float(np.median(Lc[rand])) - Lbg))
            label(img, staat.upper() + (" (DONKER, S<2)" if donker else " (VERLICHT, S=2)"), 2, y_base + lab_h + ri * ch + 2, (0.1, 0.08, 0.12), s=1)
        label(img, naam if naam != "SCHOTDRAGER" else "SCHOTDRAGER  (STIL 30 = SCHOT GEBROKEN)", 2, y_base + 3, (1, 0.86, 0.58), s=1)
    # metingen op het palet
    kc = K[MI["vijandkern"]]
    metingen["vijandkern5_amber"] = (dE(kc[5], hx("#f29a26")), dE(kc[5], hx("#f29a26"), True), dL(kc[5], hx("#f29a26")))
    metingen["vijandkern6_amber"] = (dE(kc[6], hx("#f29a26")), dE(kc[6], hx("#f29a26"), True), dL(kc[6], hx("#f29a26")))
    metingen["tell4_gloed4"] = (dE(kc[4], K[MI["gloed"], 4]), dE(kc[4], K[MI["gloed"], 4], True), dL(kc[4], K[MI["gloed"], 4]))
    metingen["tell4_amber"] = (dE(kc[4], hx("#f29a26")), dE(kc[4], hx("#f29a26"), True), dL(kc[4], hx("#f29a26")))
    metingen["roest3_amber"] = (dE(K[MI["roest"], 3], hx("#f29a26")), dE(K[MI["roest"], 3], hx("#f29a26"), True), dL(K[MI["roest"], 3], hx("#f29a26")))
    metingen["roest5_amberS"] = (dE(K[MI["roest"], 5], hx("#b45c16")), dE(K[MI["roest"], 5], hx("#b45c16"), True), dL(K[MI["roest"], 5], hx("#b45c16")))
    metingen["merkamber_roest3"] = (dE(hx("#f29a26"), K[MI["roest"], 3]), dE(hx("#f29a26"), K[MI["roest"], 3], True), dL(hx("#f29a26"), K[MI["roest"], 3]))
    metingen["merkcyaan_vijandlijf2"] = (dE(hx("#3ee6f4"), K[MI["vijandlijf"], 2]), dE(hx("#3ee6f4"), K[MI["vijandlijf"], 2], True), dL(hx("#3ee6f4"), K[MI["vijandlijf"], 2]))
    metingen["vijandkern5_fellicht5"] = (dE(kc[5], K[MI["fellicht"], 5]), dE(kc[5], K[MI["fellicht"], 5], True), dL(kc[5], K[MI["fellicht"], 5]))
    # dL* bovenrand en lijf tegen grijze kade en tegen verlichte kade
    for staat, dt in [("grijs", -1), ("kleur", 0)]:
        kade = STAAT[staat][MI["steen"], 3 + dt]
        gevel = STAAT[staat][MI["huis_wit"], 3 + dt]
        metingen[f"lijf_vs_gevel_{staat}"] = dL(K[MI["vijandlijf"], 2], gevel)
        metingen[f"contour_lijf_vs_lichte_kade_{staat}"] = dL(K[MI["vijandlijf"], 2], STAAT[staat][MI["steen"], 6 + dt])
        metingen[f"kern_vs_kade_{staat}"] = dL(kc[7 if staat == "grijs" else 6], kade)
    return img, metingen


# ------------------------------------------------------------------ Gemaalmeester (concept)
AW, AH = 600, 200   # arena 600 px breed (combat §3.2); 200 px hoog in het sheet
AV = 180            # vloer op y = 180 (arena-y 0)


def ay(y):
    return AV - y


def gm_lichaam(fase):
    """Lichaam x 252-348 (96 px). Een gebogen werkman van machine: ketel als romp, stoomkap als kop,
    drijfstang als arm. Geen gezicht met tanden (toon verhaal §6)."""
    m = np.zeros((AH, AW), bool)
    yy, xx = np.mgrid[0:AH, 0:AW]
    ketel = (((xx - 300) / 46.0) ** 2 + ((yy - ay(40)) / 42.0) ** 2 < 1) & (yy <= AV)
    sokkel = (xx >= 254) & (xx < 346) & (yy > ay(10)) & (yy <= AV)
    rug = (((xx - 292) / 34.0) ** 2 + ((yy - ay(96)) / 30.0) ** 2 < 1)
    kap = (((xx - 322) / 14.0) ** 2 + ((yy - ay(118)) / 11.0) ** 2 < 1)
    pijp = (xx >= 274) & (xx < 284) & (yy > ay(150)) & (yy < ay(110))
    m = ketel | sokkel | rug | kap | pijp
    return m


def gm_render(fase, tell=None):
    img = np.zeros((AH, AW, 3))
    yy, xx = np.mgrid[0:AH, 0:AW]
    staat = "grijs"
    ramp = STAAT[staat]
    b = R.bayer(AH, AW)
    # machinehal: baksteen achterwand, donker, vloer hardsteen
    img[:] = ramp[MI["baksteen"], np.clip(1 + ((yy % 8 == 0) | (((xx + (yy // 8) % 2 * 8) % 16) == 0)) * -1, 0, 7)]
    img[(yy < 40)] = ramp[MI["baksteen"], 0]
    # tegenlicht achter de boss (koud licht door het boograam van de hal): de wand achter zijn
    # silhouet is 2 tinten lichter, zodat het donkere lijf erop leest (bible §6 regel 4)
    gl = np.hypot((xx - 300) / 1.3, yy - ay(70))
    for r_, dtt, dens in [(150, 1, 0.5), (115, 2, 0.75), (85, 2, 1.0)]:
        m = (gl < r_) & (b < dens) & (yy < AV)
        img[m] = ramp[MI["baksteen"], np.clip(1 + dtt - ((yy % 8 == 0) | (((xx + (yy // 8) % 2 * 8) % 16) == 0)) * 1, 0, 7)][m]
    for x0 in range(0, AW, 16):
        r = tegel("kelderbodem_m1" if (x0 // 16) % 2 else "kelderbodem_m2").render(staat)
        img[AV:AV + 16, x0:x0 + 16] = r[: AH - AV, : min(16, AW - x0), :3]
    # spuigaten (GMB-03)
    for sx in (236, 364):
        r = tegel("rooster").render(staat)
        img[AV - 12:AV, sx - 8:sx + 8] = r[4:16, :, :3]
    body = gm_lichaam(fase)
    lijf = K[MI["vijandlijf"]]
    kc = K[MI["vijandkern"]]
    img[body] = lijf[2]
    img[body & (yy > ay(30))] = lijf[1]
    inner = body & ~ndimage.binary_erosion(body)
    img[inner] = lijf[4]
    top = body & ~np.vstack([np.zeros((1, AW), bool), body[:-1]])
    img[top] = kc[6]
    img[ndimage.binary_dilation(top, iterations=1) & body & ~top] = kc[3]
    # klinknagelnaden op de ketel
    naad = body & (np.abs(np.hypot((xx - 300) / 46.0, (yy - ay(40)) / 42.0) - 0.75) < 0.012)
    img[naad] = lijf[5]
    # kop: twee doffe ogen in de stoomkap (wit, klein)
    img[ay(119):ay(117), 326:328] = hx("#f4f0ff")
    img[ay(119):ay(117), 331:333] = hx("#f4f0ff")
    # drijfstang (arm), positie per tell
    stang_x = {"links": 200, "rechts": 400}.get(tell, 360)
    stang_y = 20 if tell in ("links", "rechts") else 60
    pts = np.linspace(0, 1, 120)
    for p in pts:
        x = int(300 + (stang_x - 300) * p)
        y = int(ay(100) + (ay(stang_y + 40) - ay(100)) * p)
        img[y - 2:y + 2, x - 1:x + 2] = K[MI["ijzer"], 4]
        img[y - 2, x - 1:x + 2] = K[MI["ijzer"], 6]
    # schot (fase 1) of kern (open) op x 276-324, y 12-60 (GMB-02)
    sx0, sx1, sy0, sy1 = 276, 324, ay(60), ay(12)
    if fase in ("fase1", "wankel"):
        img[sy0:sy1, sx0:sx1] = K[MI["roest"], 3]
        img[sy0:sy1:8, sx0:sx1] = K[MI["roest"], 5]
        img[sy0:sy1, sx0:sx0 + 1] = K[MI["roest"], 1]
        img[sy0:sy0 + 1, sx0:sx1] = K[MI["roest"], 6]
        for ky in range(sy0 + 4, sy1, 8):
            for kx in range(sx0 + 4, sx1, 8):
                img[ky, kx] = K[MI["ijzer"], 6]
    if fase == "open":
        d = np.hypot(xx - 300, yy - ay(36))
        img[(d < 24)] = kc[4]
        img[(d < 16)] = kc[6]
        img[(d < 8)] = kc[7]
        # scheur en stoom
        img[(d >= 24) & (d < 26) & (b < 0.5)] = kc[2]
        st = (yy < ay(60)) & (yy > ay(90)) & (np.abs(xx - 300 - np.sin(yy * 0.3) * 6) < 8) & (b < 0.3)
        img[st] = G[MI["huis_wit"], 4]  # stoom: grijs wit, nooit FelLicht (GMB-06)
    if fase == "wankel":
        # merkplek op de ketel (GMB-05): gloeiende peilmerk-vorm, rood (van de boss), tot er een merk op staat
        d = np.hypot(xx - 300, yy - ay(36))
        img[(np.abs(d - 7) < 1)] = kc[5]
        img[(np.abs(yy - ay(36)) < 1) & (d < 6)] = kc[6]
    # rad (fase 2): hurtbox 96x40, y 100-140, midden x = D + 34 = 94 (GMB-04)
    if fase in ("fase2",):
        rx, ry = 94, ay(120)
        e = np.hypot((xx - rx) / 48.0, (yy - ry) / 20.0)
        img[(np.abs(e - 0.92) < 0.08)] = K[MI["ijzer"], 4]
        img[(np.abs(e - 0.92) < 0.03) & (yy < ry)] = K[MI["ijzer"], 6]
        a = np.arctan2((yy - ry) / 20.0, (xx - rx) / 48.0)
        img[(e < 0.86) & (np.abs(np.sin(a * 4)) < 0.12)] = K[MI["ijzer"], 3]
        img[(e > 0.98) & (e < 1.18) & (np.abs(np.sin(a * 4)) < 0.3)] = K[MI["hout"], 3]
        img[(np.hypot(xx - rx, yy - ry) < 4)] = kc[5]
        # balk van het rad naar het lichaam
        for p in pts:
            x = int(rx + (276 - rx) * p)
            y = int(ry + (ay(110) - ry) * p)
            img[y - 1:y + 2, x] = K[MI["ijzer"], 3]
            img[y - 1, x] = kc[5] if p < 0.98 else img[y - 1, x]
        # vloerteken onder het rad: olievlek met licht, van D tot D + 68 px van de muur (GMB-04)
        D = 60
        olie = (xx >= D) & (xx < D + 68) & (yy >= AV - 2) & (yy < AV + 2)
        img[olie & (b < 0.6)] = K[MI["koper"], 4]
        img[olie & (yy == AV - 2) & ((xx % 4) < 2)] = K[MI["koper"], 6]
    # tells
    if tell in ("links", "rechts"):
        x0, x1 = (140, 300) if tell == "links" else (300, 460)
        tell_vlak(img, x0, ay(24), x1, ay(0), "laat")
    if tell == "zwiep":
        tell_vlak(img, 0, ay(60), 300, ay(36), "laat")
    # contour
    cont = ndimage.binary_dilation(body) & ~body
    img[cont] = hx("#05040a")
    return img


def concept_gemaalmeester():
    panelen = [("FASE 1: HET SCHOT  (POMPSLAG LINKS, AANLOOP 40)", "fase1", "links", None),
               ("OPENING: KERN OPEN  (MERK P1 OP HET SCHOT GEKNALD)", "open", None, None),
               ("FASE 2: HET GROTE RAD  (SCHOEPENZWIEP, AANLOOP 30; VLOERTEKEN)", "fase2", "zwiep", None),
               ("WANKEL: MERKPLEK OP DE KETEL  (MERK P1 + BEREIKCIRKEL)", "wankel", None, "amber")]
    pad = 10
    lab_h = 16
    Wn = 2 * AW + 3 * pad
    Hn = 2 * (AH + 16 + lab_h) + 3 * pad + 20
    img = np.zeros((Hn, Wn, 3)) + BG
    for i, (titel, fase, tell, merk) in enumerate(panelen):
        r, c = divmod(i, 2)
        x0 = pad + c * (AW + pad)
        y0 = pad + r * (AH + 16 + lab_h + pad)
        p = np.zeros((AH + 16, AW, 3))
        p[:AH] = gm_render(fase, tell)
        p[AH:] = BG
        if merk:
            bereikcirkel(p, 300, ay(36), merk)
        if fase == "open":
            bereikcirkel(p, 300, ay(36), "amber")
        # maatlat: x 0-600 in stappen van 100
        for xm in range(0, AW + 1, 100):
            xm_ = min(xm, AW - 1)
            p[AH:AH + 4, xm_] = 0.7
            label(p, str(xm), max(0, xm_ - 6), AH + 6, (0.6, 0.6, 0.7), s=1)
        img[y0 + lab_h:y0 + lab_h + AH + 16, x0:x0 + AW] = p
        label(img, titel, x0, y0 + 3, (1, 0.86, 0.58), s=1)
    label(img, "GEMAALMEESTER CONCEPT (PLACEHOLDER)  ARENA 600 PX, LICHAAM X 252-348, SCHOT Y 12-60, RAD Y 100-140 BIJ D=60  (COMBAT 3.2)",
          pad, Hn - 16, (0.8, 0.8, 0.85), s=1)
    return img


# ------------------------------------------------------------------ hoofdprogramma
def main():
    print("Slice-art deel 1: Kadewijk")
    # 1. palet
    rows = len(KADE_MATS)
    sw = 14
    pal = np.zeros((rows * (sw + 2) + 24, 3 * (8 * sw + 10) + 150, 3)) + BG
    for ci, s in enumerate(["grijs", "half", "kleur"]):
        label(pal, s.upper(), 150 + ci * (8 * sw + 10), 6, s=1)
    for ri, m in enumerate(KADE_MATS):
        y = 20 + ri * (sw + 2)
        label(pal, m.upper() + (" *" if m in NIEUW else ""), 4, y + 4, (0.9, 0.85, 0.75) if m not in NIEUW else (1, 0.7, 0.7), s=1)
        for ci, s in enumerate(["grijs", "half", "kleur"]):
            for k in range(8):
                x = 150 + ci * (8 * sw + 10) + k * sw
                pal[y:y + sw, x:x + sw] = STAAT[s][MI[m], k]
    to_pil(pal, 2).save(os.path.join(UIT, "palet_kadewijk.png"))
    for m in NIEUW:
        print(f"  ramp {m}: " + " ".join("#%02x%02x%02x" % tuple(int(round(c * 255)) for c in K[MI[m], k]) for k in range(8)))

    # 2. tiles en props
    for s in ["kleur", "half", "grijs"]:
        save_rgba(atlas(s), os.path.join(TILES, f"tiles_kadewijk_16_{s}_placeholder.png"))
    items_t = [((i % KOLOM) * 16, (i // KOLOM) * 16, t) for i, (n, t) in enumerate(TILES_FIN) if not n.startswith("leeg")]
    rows_t = (len(TILES_FIN) + KOLOM - 1) // KOLOM
    index_atlas(items_t, KOLOM * 16, rows_t * 16).save(os.path.join(TILES, "tiles_kadewijk_16_index_placeholder.png"))
    items_p, pw, ph, man = props_atlas()
    for s in ["kleur", "half", "grijs"]:
        save_rgba(render_items(items_p, pw, ph, s), os.path.join(TILES, f"props_kadewijk_{s}_placeholder.png"))
    index_atlas(items_p, pw, ph).save(os.path.join(TILES, "props_kadewijk_index_placeholder.png"))
    with open(os.path.join(TILES, "tiles_kadewijk.csv"), "w", newline="") as f:
        wr = csv.writer(f)
        wr.writerow(["naam", "atlas", "x", "y", "w", "h", "frames"])
        for i, (n, t) in enumerate(TILES_FIN):
            if n.startswith("leeg"):
                continue
            wr.writerow([n, "tiles", (i % KOLOM) * 16, (i // KOLOM) * 16, 16, 16, 1])
        for (n, x, y, w, h, fr) in man:
            wr.writerow([n, "props", x, y, w, h, fr])
    with open(os.path.join(TILES, "materialen.csv"), "w", newline="") as f:
        wr = csv.writer(f)
        wr.writerow(["id", "materiaal", "staat"] + [f"t{k}" for k in range(8)])
        for m in MATS:
            for s in ["grijs", "half", "kleur"]:
                wr.writerow([MI[m], m, s] + ["#%02x%02x%02x" % tuple(int(round(c * 255)) for c in STAAT[s][MI[m], k]) for k in range(8)])
    # overzicht x3 met nummers
    ov_parts = []
    for s in ["kleur", "half", "grijs"]:
        a = atlas(s)
        base = np.zeros(a.shape[:2] + (3,)) + BG
        aa = a[..., 3:4]
        rgb = base * (1 - aa) + a[..., :3] * aa
        big = np.repeat(np.repeat(rgb, 3, 0), 3, 1)
        for i, (n, t) in enumerate(TILES_FIN):
            if n.startswith("leeg"):
                continue
            y, x = divmod(i, KOLOM)
            label(big, str(i), x * 48 + 1, y * 48 + 1, (1, 1, 1), s=1)
        bar = np.zeros((18, big.shape[1], 3)) + BG
        label(bar, f"TILES 16X16  {s.upper()}  (NUMMER = INDEX IN TILES_KADEWIJK.CSV)", 4, 5, s=1)
        ov_parts += [bar, big]
        p = render_items(items_p, pw, ph, s)
        pb = np.zeros((ph, pw, 3)) + BG
        pa = p[..., 3:4]
        prgb = pb * (1 - pa) + p[..., :3] * pa
        pbig = np.repeat(np.repeat(prgb, 2, 0), 2, 1)
        pbig = np.repeat(np.repeat(prgb, 3, 0), 3, 1)[:, :big.shape[1] * 2]
        pbig = pbig[::2, ::2] if pbig.shape[1] > big.shape[1] else pbig
        canvas = np.zeros((pbig.shape[0], big.shape[1], 3)) + BG
        canvas[:, :min(pbig.shape[1], big.shape[1])] = pbig[:, :big.shape[1]]
        bar2 = np.zeros((18, big.shape[1], 3)) + BG
        label(bar2, f"PROPS {s.upper()} (X1,5): POMPRAD 8F, STRAATLAMP UIT/AAN, HALO, BOOGRAAM UIT/AAN, BOLDER, SLUISBALK", 4, 5, s=1)
        ov_parts += [bar2, canvas]
    to_pil(np.concatenate(ov_parts, 0)).save(os.path.join(UIT, "tileset_kadewijk_overzicht_placeholder.png"))
    # pomprad als losse animatie (x3)
    rad = [to_pil(np.dstack([pomprad_frame(f).render("kleur")[..., :3] * pomprad_frame(f).render("kleur")[..., 3:4]
                             + BG * (1 - pomprad_frame(f).render("kleur")[..., 3:4])]), 3) for f in range(8)]
    rad[0].save(os.path.join(UIT, "pomprad_8f_x3_placeholder.gif"), save_all=True, append_images=rad[1:], duration=100, loop=0)

    # 3. lichtovergang
    frames, stills, par = studie()
    gif = [to_pil(f, 2) for f in frames]
    gif[0].save(os.path.join(UIT, "lichtovergang_kadewijk_x2_placeholder.gif"), save_all=True, append_images=gif[1:],
                duration=int(1000 / par["fps"]), loop=0)
    keuze = [-0.8, 0.5, 1.0, 1.5, 2.2, par["T_end"]]
    strip = []
    for tk in keuze:
        tt, pc, st = min(stills, key=lambda s: abs(s[0] - tk))
        bar = np.zeros((16, W, 3)) + BG
        aandeel = [float(np.mean(st == k)) * 100 for k in range(3)]
        label(bar, f"T = {max(tt, 0):.1f} S" if tt >= 0 else "VOOR TRAP 2 (S=1, GEMAAL AAN)", 4, 4, s=1)
        label(bar, f"GRIJS {aandeel[0]:.0f}%  HALF {aandeel[1]:.0f}%  KLEUR {aandeel[2]:.0f}%", 330, 4, (0.6, 0.6, 0.7), s=1)
        strip += [bar, pc]
    to_pil(np.concatenate(strip, 0)).save(os.path.join(UIT, "lichtovergang_kadewijk_strip_placeholder.png"))
    # voor/na native 640x360 (beoordelen op ware maat)
    to_pil(stills[0][1]).save(os.path.join(UIT, "lichtovergang_voor_640x360_placeholder.png"))
    to_pil(stills[-1][1]).save(os.path.join(UIT, "lichtovergang_na_640x360_placeholder.png"))
    print(f"  lichtovergang: v = {par['v']:.0f} px/s, vol {par['lag']} s later, echo +{par['echo_lag']} s, water {par['t_water']} s, totaal {par['T_end']:.1f} s")

    # 4. kleurscript
    ks, chrom = kleurscript()
    to_pil(ks).save(os.path.join(UIT, "kleurscript_kadewijk_placeholder.png"))
    print("  chroma per beat: " + ", ".join(f"{b['id']} {c:.1f}" for b, c in zip(BEATS, chrom)))

    # 5. concept-sheets
    cv, met = concept_vijanden()
    to_pil(cv, 4).save(os.path.join(UIT, "concept_vijanden_x4_placeholder.png"))
    lum = np.repeat(LAB(cv)[..., :1] / 100, 3, -1)
    deu = R.deuteranopia(cv)
    to_pil(np.concatenate([lum, np.zeros((6, cv.shape[1], 3)), deu], 0), 2).save(
        os.path.join(UIT, "concept_vijanden_luminantie_deuteranopie_x2_placeholder.png"))
    gm = concept_gemaalmeester()
    to_pil(gm, 2).save(os.path.join(UIT, "concept_gemaalmeester_x2_placeholder.png"))
    gl = np.repeat(LAB(gm)[..., :1] / 100, 3, -1)
    to_pil(np.concatenate([gl, R.deuteranopia(gm)], 0)).save(
        os.path.join(UIT, "concept_gemaalmeester_luminantie_deuteranopie_placeholder.png"))
    print("  metingen (dE76 normaal / deuteranopie / dL*):")
    for k, v in met.items():
        if k.startswith("ring_"):
            print(f"    {k}: dL* lijf {v[0]:.1f} / contour {v[1]:.1f} / bovenrand {v[2]:.1f}")
        elif isinstance(v, tuple):
            print(f"    {k}: {v[0]:.1f} / {v[1]:.1f} / {v[2]:.1f}")
        else:
            print(f"    {k}: dL* {v:.1f}")
    print("Klaar.")


if __name__ == "__main__":
    main()
