"""R5-scene voor de art bible v0 (Art Director, #20).

Een plek in de gedroomde verzonken stad bij een gemaal, in twee toestanden:
  grijs  = het licht is nog niet teruggepompt (wereld en echo grijs, water hoog)
  kleur  = opgepompt (warme stad, water gezakt, gemaal aan, FelLicht-zone)
met speler 1 (machinist), speler 2 (sluiswachter, co-op) en de echo.

Alles is pixel art op 640x400 (Steam Deck); de pc-weergave 640x360 is de
middenuitsnede (rij 20-380). Elke kleur komt uit een vaste ramp van 8 tinten
(palet in de art bible). Licht werkt in banden: index = omgeving + vorm + lichtband.

Draaien vanaf de repo-root:  python3 docs/art/r5-scene/bron/genereer_r5.py
Het script print ook de metingen voor de art bible (dE, dL*).
"""
import os
import sys

import numpy as np
from PIL import Image, ImageDraw
from scipy import ndimage

HIER = os.path.dirname(os.path.abspath(__file__))
UIT = os.path.dirname(HIER)
sys.path.insert(0, HIER)
sys.path.insert(0, os.path.join(UIT, "..", "stijltests", "bron"))
import sprites as SP  # noqa: E402
from pixelfont import draw_text, text_width  # noqa: E402

W, H = 640, 400
PC = (20, 380)  # rijen van de 640x360-weergave
N = 8           # tinten per ramp


# ------------------------------------------------------------------ kleur
def hx(c):
    return np.array([int(c[i:i + 2], 16) for i in (1, 3, 5)], float) / 255.0


def srgb_to_lab(rgb):
    rgb = np.asarray(rgb, float)
    a = np.where(rgb <= 0.04045, rgb / 12.92, ((rgb + 0.055) / 1.055) ** 2.4)
    M = np.array([[0.4124, 0.3576, 0.1805], [0.2126, 0.7152, 0.0722], [0.0193, 0.1192, 0.9505]])
    xyz = a @ M.T / np.array([0.9505, 1.0, 1.089])
    f = np.where(xyz > 0.008856, np.cbrt(xyz), 7.787 * xyz + 16 / 116)
    return np.stack([116 * f[..., 1] - 16, 500 * (f[..., 0] - f[..., 1]), 200 * (f[..., 1] - f[..., 2])], -1)


def lab_to_srgb(lab):
    lab = np.asarray(lab, float)
    fy = (lab[..., 0] + 16) / 116
    fx = fy + lab[..., 1] / 500
    fz = fy - lab[..., 2] / 200
    f = np.stack([fx, fy, fz], -1)
    xyz = np.where(f > 0.206893, f ** 3, (f - 16 / 116) / 7.787) * np.array([0.9505, 1.0, 1.089])
    Mi = np.array([[3.2406, -1.5372, -0.4986], [-0.9689, 1.8758, 0.0415], [0.0557, -0.2040, 1.0570]])
    lin = np.clip(xyz @ Mi.T, 0, 1)
    return np.where(lin <= 0.0031308, lin * 12.92, 1.055 * lin ** (1 / 2.4) - 0.055)


def deuteranopia(rgb):
    rgb = np.asarray(rgb, float)
    lin = np.where(rgb <= 0.04045, rgb / 12.92, ((rgb + 0.055) / 1.055) ** 2.4)
    M = np.array([[0.367322, 0.860646, -0.227968], [0.280085, 0.672501, 0.047413], [-0.011820, 0.042940, 0.968881]])
    o = np.clip(lin @ M.T, 0, 1)
    return np.where(o <= 0.0031308, o * 12.92, 1.055 * o ** (1 / 2.4) - 0.055)


def grayscale(rgb):
    y = (rgb * np.array([0.2126, 0.7152, 0.0722])).sum(-1, keepdims=True)
    return np.repeat(y, 3, -1)


def ramp(keys):
    """8 tinten langs een pad in CIELAB door de sleutelkleuren (donker -> licht)."""
    labs = srgb_to_lab(np.array([hx(k) for k in keys]))
    t = np.linspace(0, 1, len(labs))
    out = []
    for s in np.linspace(0, 1, N):
        out.append([np.interp(s, t, labs[:, j]) for j in range(3)])
    return lab_to_srgb(np.array(out))


def desat(r, chroma, lmul=1.0, ladd=0.0, bshift=0.0):
    lab = srgb_to_lab(r)
    lab[:, 0] = lab[:, 0] * lmul + ladd
    lab[:, 1] *= chroma
    lab[:, 2] = lab[:, 2] * chroma + bshift
    return lab_to_srgb(lab)


# Materialen: sleutelkleuren donker -> licht, met hue-shift (schaduw koel, licht warm).
MAT_KEYS = {
    "lucht":    ["#06060f", "#0e1026", "#1c2044", "#2e3462", "#4a4c7c"],
    "ver":      ["#0a0a18", "#151832", "#252a4e", "#3a4070", "#5a6090"],
    "huis_rood": ["#120a14", "#3a1820", "#7a3428", "#b8603e", "#e89a64"],
    "huis_oker": ["#120c14", "#3a2618", "#82602e", "#c09448", "#f0cc7a"],
    "huis_wit": ["#0e0e1a", "#2e2c42", "#6e6a80", "#b2aaa4", "#ece2cc"],
    "huis_groen": ["#0a1014", "#1a2c2c", "#3a5a4e", "#6e927a", "#b2cca0"],
    "dak":      ["#0a0a16", "#181c32", "#2c3454", "#4a5a7c", "#7a8aa4"],
    "raam":     ["#2a1208", "#6a3010", "#c0701c", "#f0aa3a", "#fff0b8"],
    "raamdonker": ["#05050a", "#0c0c18", "#161828", "#22263a", "#30344c"],
    "steen":    ["#0a0a14", "#1e1e32", "#3c3e56", "#6a6878", "#a8a092", "#e0d0b0"],
    "baksteen": ["#0e0810", "#2e1418", "#622a24", "#9a4a34", "#d07e52", "#f4b884"],
    "ijzer":    ["#050508", "#121218", "#24222c", "#3e3a44", "#6a6268"],
    "koper":    ["#060c10", "#12262a", "#24504a", "#3e8470", "#7cc4a0", "#c8f0d0"],
    "hout":     ["#0c0808", "#24160e", "#4a3020", "#7a5236", "#b08050"],
    "water":    ["#03050c", "#081428", "#0e2a46", "#1a4c6a", "#3a7e96", "#8cc8d0"],
    "klimop":   ["#060c08", "#10200e", "#24401c", "#40682a", "#78a040"],
    "schaduwgeo": ["#0a0414", "#1c0c30", "#3a1a5c", "#623490", "#9a68d0"],
    "lichtgeo": ["#3a2c18", "#7a6644", "#c4b088", "#ece0c0", "#fffaf0"],
    "fellicht": ["#20303c", "#4a6a80", "#8ab8d0", "#c8ecfa", "#f4feff"],
    "gloed":    ["#4a2a0a", "#9a5414", "#e09028", "#ffc860", "#fff6d8"],
}
MATS = list(MAT_KEYS)
MI = {m: i for i, m in enumerate(MATS)}
RAMP_KLEUR = np.array([ramp(MAT_KEYS[m]) for m in MATS])
# grijs: kleur bijna weg, iets donkerder en koel (de wereld zonder licht)
RAMP_GRIJS = np.array([desat(r, 0.06, 0.86, 0.0, -2.5) for r in RAMP_KLEUR])
# half: in de lichtpoel van de lantaarn keert de kleur deels terug (licht = kleur)
RAMP_HALF = np.array([desat(r, 0.42, 0.95) for r in RAMP_KLEUR])
# materialen die in elke toestand hun kleur houden (lichtbronnen zelf)
for m in ["gloed"]:
    RAMP_GRIJS[MI[m]] = RAMP_KLEUR[MI[m]]
    RAMP_HALF[MI[m]] = RAMP_KLEUR[MI[m]]

# Figuren: vaste kleuren (onbelicht, altijd leesbaar)
FIG = {
    "p1_contour": hx("#140a12"), "p1_pet": hx("#3a2830"), "p1_pet_l": hx("#5e4448"),
    "p1_huid": hx("#f2d6b4"), "p1_oog": hx("#1a0e14"),
    "p1_jas": hx("#ece2c8"), "p1_jas_s": hx("#b4a48a"), "p1_riem": hx("#6a4a32"),
    "p1_laars": hx("#3a2830"), "p1_haar": hx("#5a3426"), "p1_naad": hx("#9c8a70"), "amber": hx("#f29a26"), "amber_s": hx("#b45c16"),
    "rim_licht": hx("#fff2c8"),
    "p2_lijf": hx("#08080e"), "p2_rand": hx("#3ee6f4"), "p2_oog": hx("#e8ffff"),
    "p2_sjaal": hx("#1fb4cc"), "p2_haak": hx("#1a1e26"),
    "p2_rand_g": hx("#a8c4c8"), "p2_sjaal_g": hx("#5a6a6e"),
    "echo_rand": hx("#f29a26"), "echo_bin": hx("#3a1e56"), "echo_oog": hx("#ffd27a"),
    "echo_rand_g": hx("#c8c4cc"), "echo_bin_g": hx("#3a3842"), "echo_oog_g": hx("#e8c888"),
}


# ------------------------------------------------------------------ hulp
def bayer(h, w):
    b = np.array([[0, 8, 2, 10], [12, 4, 14, 6], [3, 11, 1, 9], [15, 7, 13, 5]]) / 16.0
    return np.tile(b, (h // 4 + 1, w // 4 + 1))[:h, :w]


BAY = bayer(H, W)
YY, XX = np.mgrid[0:H, 0:W]


def poly(pts):
    im = Image.new("L", (W, H), 0)
    ImageDraw.Draw(im).polygon([tuple(p) for p in pts], fill=1)
    return np.array(im) > 0


def rect(x0, y0, x1, y1):
    m = np.zeros((H, W), bool)
    m[max(0, y0):min(H, y1), max(0, x0):min(W, x1)] = True
    return m


def ellipse(x0, y0, x1, y1):
    im = Image.new("L", (W, H), 0)
    ImageDraw.Draw(im).ellipse([x0, y0, x1, y1], fill=1)
    return np.array(im) > 0


def line_mask(pts, width=1):
    im = Image.new("L", (W, H), 0)
    ImageDraw.Draw(im).line([tuple(p) for p in pts], fill=1, width=width)
    return np.array(im) > 0


def arch(x0, x1, ytop, ybot):
    """Rondboog-opening: rechthoek met halve cirkel bovenop."""
    r = (x1 - x0) / 2
    m = rect(x0, int(ytop + r), x1, ybot)
    m |= ellipse(x0, ytop, x1 - 1, ytop + 2 * r)
    return m


def edge_of(m):
    return m & ~ndimage.binary_erosion(m)


def outer_of(m):
    return ndimage.binary_dilation(m) & ~m


# ------------------------------------------------------------------ wereld
class World:
    def __init__(self, state):
        self.state = state
        self.mat = np.full((H, W), MI["lucht"], np.int16)
        self.off = np.zeros((H, W), np.int16)
        self.layer = np.zeros((H, W), np.int8)   # 0 lucht, 1 ver, 2 huizen, 3 middengrond, 4 speelvlak
        self.emis = np.zeros((H, W), bool)        # eigen licht, niet belicht
        self.fixed = np.full((H, W), -1, np.int16)  # vaste index (ramen, gloed)
        self.solid = np.zeros((H, W), np.int16)   # occluder-component (0 = lucht)

    def paint(self, m, mat, off=0, layer=4, solid=None):
        self.mat[m] = MI[mat]
        self.off[m] = off
        self.layer[m] = layer
        self.emis[m] = False
        self.fixed[m] = -1
        if solid is not None:
            self.solid[m] = solid

    def glow(self, m, mat, idx):
        self.mat[m] = MI[mat]
        self.fixed[m] = idx
        self.emis[m] = True


def stone_blocks(m, w, h, off_rows=0, bw=24, bh=10, mortar=-2, top_hi=True, seed=0):
    """Blokverband: voegen donker, bovenkant van een blok een tint lichter."""
    rng = np.random.default_rng(seed)
    ys, xs = np.nonzero(m)
    y0 = ys.min()
    ry = (YY - y0 - off_rows) % bh
    row = (YY - y0 - off_rows) // bh
    rx = (XX + (row % 2) * (bw // 2)) % bw
    o = np.zeros((H, W), np.int16)
    o[(ry == 0) | (rx == 0)] = mortar
    if top_hi:
        o[(ry == 1) & (rx != 0)] = 1
    o[(ry == bh - 1) & (rx != 0)] = -1
    # verweerde blokken: hier en daar een blok een tint donkerder
    blk = (row * 131 + ((XX + (row % 2) * (bw // 2)) // bw) * 71 + seed) % 7
    o[(blk == 0) & (ry != 0) & (rx != 0)] -= 1
    w.off[m] += o[m]


def build(state):
    w = World(state)
    kleur = state == "kleur"
    rng = np.random.default_rng(7)
    wl = 368 if kleur else 324  # waterstand (rij); opgepompt = gezakt
    w.wl = wl

    # --- lucht: verloop in banden met ordered dithering
    g = np.clip((YY - 10) / 250.0, 0, 1) * 3.2
    w.off[:] = np.floor(g + BAY * 0.999).astype(np.int16)
    if kleur:
        # stadsgloed boven de daken
        sg = np.clip(1 - np.abs(YY - 236) / 70.0, 0, 1) * 1.2
        w.off += np.floor(sg + BAY * 0.999).astype(np.int16)
    w.off = np.clip(w.off, 0, 4)

    # --- verre laag: belfort en daklijn
    far = np.zeros((H, W), bool)
    # belfort
    far |= rect(234, 70, 272, 300)
    far |= rect(230, 112, 276, 118)
    far |= rect(238, 46, 268, 70)
    far |= poly([(238, 46), (253, 14), (268, 46)])
    far |= rect(252, 4, 254, 14)
    for cx in (230, 276):
        far |= rect(cx - 3, 60, cx + 3, 72)
        far |= poly([(cx - 3, 60), (cx, 52), (cx + 3, 60)])
    # daklijn: trapgevels en torens
    x = -6
    k = 0
    while x < W:
        bw = int(rng.integers(18, 34))
        top = int(rng.integers(196, 226))
        far |= rect(x, top, x + bw, 300)
        st = 4
        for s in range(3):
            far |= rect(x + st * (s + 1), top - 5 * (s + 1), x + bw - st * (s + 1), top)
        if k % 5 == 2:
            far |= rect(x + bw // 2 - 3, top - 40, x + bw // 2 + 3, top)
            far |= poly([(x + bw // 2 - 4, top - 40), (x + bw // 2, top - 54), (x + bw // 2 + 4, top - 40)])
        x += bw
        k += 1
    w.paint(far, "ver", 1, layer=1)
    w.off[far & (XX % 2 == 0) & ((YY + 1) % 9 == 0)] -= 0
    # belfort: galmgaten
    galm = np.zeros((H, W), bool)
    for gx in (241, 250, 259):
        galm |= arch(gx, gx + 6, 52, 66)
    galm |= arch(242, 250, 82, 104) | arch(256, 264, 82, 104)
    if kleur:
        w.glow(galm, "raam", 4)
        w.glow(galm & (YY > 60) & (YY < 64), "raam", 6)
    else:
        w.paint(galm, "raamdonker", 1, layer=1)
    # kleine ramen in de daklijn
    for i in range(60):
        rx_, ry_ = int(rng.integers(0, W)), int(rng.integers(214, 280))
        if far[ry_, rx_] and far[ry_ + 3, rx_ + 2]:
            m = rect(rx_, ry_, rx_ + 2, ry_ + 3)
            if kleur and rng.random() < 0.55:
                w.glow(m, "raam", 4)
            else:
                w.paint(m, "raamdonker", 1, layer=1)
    w.far = far

    # --- huizenrij (verzonken), middenlaag
    houses = np.zeros((H, W), bool)
    x = 26
    mats = ["huis_rood", "huis_oker", "huis_wit", "huis_groen", "huis_rood", "huis_wit", "huis_oker"]
    i = 0
    w.house_windows = []
    while x < 470:
        bw = [56, 48, 60, 44, 52, 58, 46][i % 7]
        top = [182, 200, 170, 206, 188, 176, 198][i % 7]
        m = rect(x, top, x + bw, H)
        st = 6
        for s in range(4):
            m |= rect(x + st * (s + 1) - 2, top - 7 * (s + 1), x + bw - st * (s + 1) + 2, top)
        houses |= m
        mt = mats[i % 7]
        w.paint(m, mt, 0, layer=2)
        # gevelrand en dakkant
        w.off[edge_of(m) & (XX > x) & (XX < x + bw - 1)] += 1
        w.off[m & (XX == x + bw - 1)] -= 1
        w.off[m & (XX == x + bw - 2)] -= 1
        # steenstructuur heel subtiel
        # metselwerk: alleen een voeg per 6 rijen, heel rustig
        w.off[m & ((YY - top) % 6 == 0) & ((XX + (YY // 6) * 5) % 9 < 6)] -= 1
        # ramen per verdieping
        for fy in range(top + 10, H - 20, 30):
            for fx in range(x + 8, x + bw - 12, 14):
                if fy > 296:
                    continue
                win = arch(fx, fx + 7, fy, fy + 12) if mt == "huis_rood" else rect(fx, fy, fx + 7, fy + 12)
                frame = rect(fx - 1, fy - 1, fx + 8, fy + 13) & ~win
                w.paint(frame, mt, 2, layer=2)
                lit = kleur and rng.random() < 0.5
                if lit:
                    w.glow(win, "raam", 4)
                    w.glow(win & (YY == fy + 6), "raam", 3)
                    w.glow(win & (XX == fx + 3), "raam", 3)
                    w.house_windows.append((fx, fy))
                else:
                    w.paint(win, "raamdonker", 2, layer=2)
                    w.paint(win & (YY == fy + 6), "raamdonker", 1, layer=2)
                # luiken bij groene en witte huizen
                if mt in ("huis_wit", "huis_oker"):
                    w.paint(rect(fx - 3, fy, fx - 1, fy + 12), "huis_groen", 2, layer=2)
        # deur met stoep (verdwijnt onder water in de grijze toestand)
        dx0 = x + bw // 2 - 6
        deurm = arch(dx0, dx0 + 12, 306, 330)
        w.paint(deurm, "hout", 1, layer=2)
        w.off[deurm & ((XX - dx0) % 4 == 0)] -= 1
        w.paint(rect(dx0 - 4, 330, dx0 + 16, 334), "steen", 2, layer=2)
        w.paint(rect(dx0 - 4, 330, dx0 + 16, 331), "steen", 3, layer=2)
        # klimop op sommige gevels
        if i % 3 == 1:
            iv = ellipse(x - 6, top + 30, x + 22, top + 120) & m
            iv &= (BAY + ((XX * 7 + YY * 3) % 5) / 10.0) > 0.55
            w.paint(iv, "klimop", 2, layer=2)
        x += bw - 2
        i += 1
    w.houses = houses

    # --- volumetrische bundels (handtekening): alleen in de achtergrond
    bg = w.layer <= 2
    if kleur:
        # warme bundels uit de galmgaten van het belfort naar de stad
        beams = [((242, 96), (250, 96), (170, 300), (90, 300)),
                 ((256, 96), (264, 96), (420, 300), (340, 300))]
        for p0, p1, p2, p3 in beams:
            b = poly([p0, p1, p2, p3]) & bg & (w.fixed < 0)
            # dichtheid loopt af naar beneden en naar de randen: zacht in de lucht
            t = np.clip((YY - p0[1]) / float(p2[1] - p0[1]), 0, 1)
            cx_ = p0[0] + (p2[0] + p3[0]) / 2.0 * t - p0[0] * t + (p1[0] - p0[0]) / 2.0 * (1 - t)
            half = ((p1[0] - p0[0]) * (1 - t) + (p2[0] - p3[0]) * t) / 2.0 + 1e-3
            rel = 1 - np.abs(XX - cx_) / half
            dens = np.clip(rel * 1.2, 0, 1) * (1 - 0.6 * t)
            w.beamd = np.maximum(getattr(w, "beamd", np.zeros((H, W))), np.where(b, dens, 0))
    else:
        # grijs: dunne, koude bundels door het wolkendek
        for pts in ([(96, 0), (124, 0), (210, 330), (150, 330)], [(330, 0), (350, 0), (400, 330), (356, 330)]):
            b = poly(pts) & bg & (w.fixed < 0)
            w.off[b & (BAY < 0.5)] += 1
            w.off[b & (BAY < 0.125)] += 1

    # --- middengrond: schoepenrad van het gemaal
    cx, cy, R = 404, 316, 54
    wheel = (np.hypot(XX - cx, YY - cy) <= R) & (np.hypot(XX - cx, YY - cy) >= R - 5)
    hub = np.hypot(XX - cx, YY - cy) <= 8
    spokes = np.zeros((H, W), bool)
    paddles = np.zeros((H, W), bool)
    rot = 0.18 if kleur else 0.0
    for a in np.linspace(0, 2 * np.pi, 12, endpoint=False) + rot:
        ex, ey = cx + np.cos(a) * (R - 3), cy + np.sin(a) * (R - 3)
        spokes |= line_mask([(cx, cy), (ex, ey)], 2)
        px, py = cx + np.cos(a) * (R + 6), cy + np.sin(a) * (R + 6)
        paddles |= line_mask([(ex, ey), (px, py)], 5)
    wheel_all = wheel | hub | spokes | paddles
    w.paint(paddles, "hout", 0, layer=3)
    w.paint(wheel | spokes, "koper" if kleur else "koper", 0, layer=3)
    w.paint(hub, "ijzer", 1, layer=3)
    w.off[edge_of(wheel_all) & (YY < cy)] += 1
    w.wheel = wheel_all

    # --- speelvlak
    # linker huis (muur met lantaarnarm)
    lw = rect(0, 0, 34, H)
    w.paint(lw, "baksteen", 0, solid=1)
    stone_blocks(lw, w, H, bw=12, bh=6, mortar=-1, seed=3)
    w.off[lw & (XX >= 31)] += 1
    w.paint(rect(30, 0, 34, H) & (YY % 6 == 0), "baksteen", -1, solid=1)
    # kade links
    kade = rect(0, 318, 262, H)
    w.paint(kade, "steen", 0, solid=2)
    stone_blocks(kade, w, H, bw=26, bh=11, seed=5)
    w.paint(rect(0, 318, 264, 322), "steen", 1, solid=2)  # dekrand
    w.paint(rect(0, 318, 264, 319), "steen", 2, solid=2)
    w.paint(rect(258, 322, 262, H), "steen", -1, solid=2)
    # meerpaal en mos op de kade
    paal = rect(244, 308, 252, 318) | rect(242, 306, 254, 309)
    w.paint(paal, "ijzer", 1)
    w.off[paal & (XX < 247)] += 1
    if kleur:
        mos = rect(0, 316, 262, 320) & ((BAY + ((XX * 13) % 7) / 7.0) > 1.15) & (XX > 34)
        w.paint(mos, "klimop", 2, solid=2)
    # zuil
    zuil = rect(201, 178, 221, 310) | rect(197, 166, 225, 178) | rect(195, 308, 227, 318)
    zuil |= rect(199, 162, 223, 166)
    w.paint(zuil, "steen", 0, solid=3)
    w.off[zuil & (XX < 205)] += 1
    w.off[zuil & (XX > 216)] -= 1
    w.off[zuil & (YY > 178) & (YY < 308) & ((XX - 201) % 5 == 0)] -= 1  # cannelures
    w.off[zuil & ((YY == 166) | (YY == 308))] += 1
    w.off[zuil & ((YY == 177) | (YY == 317))] -= 1
    # breuk bovenop de zuil
    w.paint(poly([(199, 162), (205, 156), (210, 160), (216, 154), (223, 162)]), "steen", 1, solid=3)

    # kanaal: achterwand + bodem
    achter = rect(262, 334, 440, H)
    w.paint(achter, "steen", -1, layer=3)
    stone_blocks(achter, w, H, bw=20, bh=8, mortar=-1, top_hi=False, seed=9)
    duiker = arch(292, 334, 334, 366)
    w.paint(duiker, "raamdonker", 0, layer=3)
    w.paint(outer_of(duiker) & achter, "steen", 1, layer=3)
    w.paint(outer_of(outer_of(duiker)) & achter & ~duiker, "steen", 0, layer=3)
    # loopbrug langs de achterwand (de nieuwe route als het water zakt)
    loop = rect(262, 362, 440, 366)
    w.paint(loop, "steen", 2, layer=4, solid=4)
    w.paint(rect(262, 366, 440, 368), "steen", -1, layer=4, solid=4)
    w.paint(rect(262, 362, 440, 363), "steen", 3, layer=4, solid=4)
    # getijdenrand: de oude waterstand
    if kleur:
        gr = rect(262, 322, 440, 332) & (BAY < 0.75 - (YY - 322) * 0.07) & (w.layer >= 2)
        w.paint(gr & ~duiker, "klimop", 1, layer=3)
        w.paint(rect(262, 322, 440, 323) & (w.layer >= 2), "klimop", 2, layer=3)
    bodem = rect(262, 384, 440, H)
    w.paint(bodem, "steen", -1, solid=5)

    # gemaal: vloer, gebouw, schoorsteen
    gv = rect(438, 300, W, H)
    w.paint(gv, "steen", 0, solid=6)
    stone_blocks(gv, w, H, bw=26, bh=11, seed=11)
    w.paint(rect(436, 300, W, 304), "steen", 1, solid=6)
    w.paint(rect(436, 300, W, 301), "steen", 2, solid=6)
    w.paint(rect(436, 304, 440, H), "steen", 1, solid=6)
    # leuning langs de gemaalkade en een perspijp op de kademuur
    leu = rect(438, 284, W, 286)
    for px in range(440, W, 18):
        leu |= rect(px, 284, px + 2, 300)
    w.paint(leu, "ijzer", 2)
    pijp = rect(438, 330, W, 338)
    w.paint(pijp, "koper", 1, solid=6)
    w.off[pijp & (YY == 331)] += 2
    w.off[pijp & (YY == 337)] -= 1
    for fx in range(452, W, 40):
        w.paint(rect(fx, 328, fx + 4, 340), "koper", 2, solid=6)
    geb = rect(470, 112, W, 300)
    for s in range(5):
        geb |= rect(470 + 12 * s, 112 - 9 * (s + 1), W - 12 * s + 40, 112 - 9 * s)
    schoor = rect(486, 26, 502, 112) | rect(484, 22, 504, 28)
    w.paint(schoor, "baksteen", 0, solid=0)
    w.off[schoor & (XX < 490)] += 1
    w.off[schoor & ((YY - 26) % 4 == 0)] -= 1
    w.paint(geb, "baksteen", 0, solid=0)
    stone_blocks(geb, w, H, bw=10, bh=5, mortar=-1, top_hi=False, seed=13)
    w.off[geb & (XX < 474)] += 1
    # dekstenen op de trapgevel
    for s in range(5):
        w.paint(rect(470 + 12 * s - 2, 112 - 9 * (s + 1) - 2, 470 + 12 * s + 10, 112 - 9 * (s + 1) + 1), "steen", 1, solid=0)
    # sierband en plint
    w.paint(rect(470, 140, W, 144), "steen", 1, solid=0)
    w.paint(rect(470, 286, W, 300), "steen", 0, solid=0)
    w.paint(rect(470, 286, W, 287), "steen", 1, solid=0)
    # groot boograam met machine-gloed
    raam = arch(520, 586, 156, 246)
    w.paint(outer_of(raam) | outer_of(outer_of(raam)), "steen", 1, solid=0)
    roeden = raam & ((XX - 520) % 11 == 0) | raam & ((YY - 156) % 14 == 0)
    if kleur:
        w.glow(raam, "raam", 4)
        w.glow(raam & (YY > 220), "raam", 5)
        # silhouet van de pompmachine binnen
        mach = (ellipse(532, 196, 574, 238) | rect(550, 170, 556, 246)) & raam
        w.glow(mach, "raam", 2)
        w.glow(roeden, "raam", 1)
    else:
        w.paint(raam, "raamdonker", 1, solid=0)
        w.paint(roeden, "ijzer", 1, solid=0)
    # deur
    deur = arch(604, 630, 246, 286)
    w.paint(deur, "hout", 1, solid=0)
    w.off[deur & ((XX - 604) % 6 == 0)] -= 1
    w.paint(outer_of(deur) & geb, "steen", 1, solid=0)
    # rond venster in de gevel
    rv = ellipse(546, 82, 562, 98)
    if kleur:
        w.glow(rv, "raam", 5)
    else:
        w.paint(rv, "raamdonker", 1, solid=0)
    w.paint(outer_of(rv), "steen", 1, solid=0)
    # lage aanbouw met straatlamp
    ab = rect(440, 236, 470, 300)
    w.paint(ab, "baksteen", 0, solid=8)
    stone_blocks(ab, w, H, bw=10, bh=5, mortar=-1, top_hi=False, seed=17)
    w.paint(rect(438, 232, 472, 236), "steen", 1, solid=8)

    # lampen (alleen het ijzerwerk; het licht volgt in light())
    # lantaarnarm (linker muur) en ketting
    arm = rect(34, 166, 128, 169) | line_mask([(34, 180), (60, 168)], 2)
    arm |= ellipse(40, 170, 52, 182) & ~ellipse(43, 173, 49, 179)
    w.paint(arm, "ijzer", 2)
    ket = rect(119, 169, 121, 190) & (YY % 3 != 0)
    w.paint(ket, "ijzer", 2)
    # lantaarn (verplaatsbaar): kap, glas met vlam, voet
    lan = rect(114, 194, 127, 212)
    w.paint(rect(113, 191, 128, 194) | poly([(113, 191), (120, 186), (127, 191)]), "ijzer", 2)
    w.paint(rect(113, 212, 128, 215), "ijzer", 2)
    w.paint(lan, "ijzer", 2)
    w.glow(rect(115, 195, 126, 212), "gloed", 5)
    w.glow(rect(117, 197, 124, 211), "gloed", 6)
    w.glow(poly([(119, 210), (118, 203), (120, 198), (122, 203), (122, 210)]), "gloed", 7)
    w.paint(rect(120, 194, 121, 212), "ijzer", 2)  # middenstijl
    w.lantern = (120, 204)

    # straatlamp met kap (gemaal)
    w.paint(rect(428, 208, 446, 210) | rect(444, 204, 446, 236) | line_mask([(436, 210), (444, 222)], 1), "ijzer", 2)
    kap = poly([(422, 214), (432, 208), (438, 212), (430, 220)])
    w.paint(kap, "ijzer", 2)
    lampglas = poly([(424, 216), (433, 211), (436, 214), (429, 220)])
    if kleur:
        w.glow(lampglas, "gloed", 7)
    else:
        w.paint(lampglas, "raamdonker", 2)
    w.streetlamp = (430, 219)

    # zoeklicht op het gemaal (FelLicht-bron)
    w.paint(rect(606, 116, 626, 126) | rect(612, 110, 620, 116), "ijzer", 2, solid=0)
    if kleur:
        w.glow(rect(608, 124, 624, 128), "fellicht", 7)
    w.searchlight = (616, 127)
    return w


# ------------------------------------------------------------------ licht
def occlusion(w, lx, ly, mask_targets):
    """1 = zichtbaar vanaf het licht, 0 = in de schaduw. Harde rand (geen halfschaduw)."""
    solid = w.solid
    vis = np.ones((H, W), bool)
    ys, xs = np.nonzero(mask_targets)
    if len(ys) == 0:
        return vis
    own = solid[ys, xs]
    K = 140
    t = np.linspace(0.0, 1.0, K)[1:-1]
    res = np.ones(len(ys), bool)
    CH = 20000
    for s in range(0, len(ys), CH):
        yy, xx, oo = ys[s:s + CH], xs[s:s + CH], own[s:s + CH]
        sx = (lx + (xx[:, None] - lx) * t[None, :]).round().astype(int).clip(0, W - 1)
        sy = (ly + (yy[:, None] - ly) * t[None, :]).round().astype(int).clip(0, H - 1)
        sc = solid[sy, sx]
        hit = (sc > 0) & (sc != oo[:, None])
        res[s:s + CH] = ~hit.any(1)
    vis[ys, xs] = res
    return vis


def lights_for(w):
    kleur = w.state == "kleur"
    L = []
    lx, ly = w.lantern
    L.append(dict(name="lantaarn", x=lx, y=ly, R=250 if kleur else 200, I=1.0, cone=None, fel=False, shadow=True))
    if kleur:
        sx, sy = w.streetlamp
        L.append(dict(name="straatlamp", x=sx, y=sy, R=180, I=0.95,
                      cone=((-60, 81), (26, 81)), fel=False, shadow=True))
        fx, fy = w.searchlight
        L.append(dict(name="fellicht", x=fx, y=fy, R=260, I=1.0,
                      cone=((-62, 173), (-14, 173)), fel=True, shadow=True))
    return L


def in_cone(x, y, cone):
    (ax, ay), (bx, by) = cone
    dx, dy = XX - x, YY - y
    c1 = ax * dy - ay * dx   # links van rand a?
    c2 = bx * dy - by * dx
    return (c1 <= 0) & (c2 >= 0) & (dy >= 0)


def light_fields(w):
    out = {}
    for L in lights_for(w):
        d = np.hypot(XX - L["x"], YY - L["y"])
        I = np.clip(1 - d / L["R"], 0, 1) ** 1.25 * L["I"]
        if L["cone"] is not None:
            I = I * in_cone(L["x"], L["y"], L["cone"])
        tgt = I > 0
        vis = occlusion(w, L["x"], L["y"], tgt)
        L["Iraw"] = I
        out[L["name"]] = (I * vis, vis, L)
    return out


# ------------------------------------------------------------------ figuren
def sprite_arrays(rows):
    h = len(rows)
    wd = max(len(r) for r in rows)
    grid = np.full((h, wd), ".", dtype="<U1")
    for y, r in enumerate(rows):
        for x, ch in enumerate(r):
            grid[y, x] = ch
    return grid


def place(grid, x, y, flip=False):
    """Zet een sprite met voeten (onderkant) op (x, y) gecentreerd; geeft (grid, x0, y0)."""
    g = grid[:, ::-1] if flip else grid
    h, wd = g.shape
    return g, x - wd // 2, y - h


def fig_layer(kind, rows, x, y, state, flip=False, lightpos=None):
    """Geeft (rgba H x W x 4, mask) voor een figuur.
    kind: 'p1', 'p2', 'echo' (hol, amber), 'echo_p2' (hol, cyaan, slechtste geval)."""
    grid = sprite_arrays(rows)
    g, x0, y0 = place(grid, x, y, flip)
    h, wd = g.shape
    body = np.zeros((H, W), bool)
    canvas = np.zeros((H, W, 4))
    sub = (g != ".")
    ys, xs = np.nonzero(sub)
    Y, X = ys + y0, xs + x0
    ok = (Y >= 0) & (Y < H) & (X >= 0) & (X < W)
    body[Y[ok], X[ok]] = True
    chars = np.full((H, W), ".", dtype="<U1")
    chars[Y[ok], X[ok]] = g[ys[ok], xs[ok]]
    grijs = state == "grijs"

    def put(m, col, a=1.0):
        canvas[m, :3] = col
        canvas[m, 3] = a

    if kind == "p1":
        cmap = {"h": "p1_pet", "H": "p1_pet_l", "f": "p1_huid", "e": "p1_oog", "s": "amber", "S": "amber_s",
                "c": "p1_jas", "C": "p1_jas_s", "g": "p1_riem", "b": "p1_laars", "r": "p1_haar", "d": "p1_naad"}
        for ch, k in cmap.items():
            put(chars == ch, FIG[k])
        cont = outer_of(body)
        put(cont, FIG["p1_contour"])
        if lightpos is not None:
            # randlicht aan de kant van de lantaarn (1 px, binnen het silhouet)
            lx, ly = lightpos
            e = edge_of(body)
            dx, dy = lx - XX, ly - YY
            sh_x = np.sign(dx).astype(int)
            sh_y = np.sign(dy).astype(int)
            nb = np.zeros_like(body)
            ys2, xs2 = np.nonzero(e)
            tx = (xs2 + sh_x[ys2, xs2]).clip(0, W - 1)
            ty = (ys2 + sh_y[ys2, xs2]).clip(0, H - 1)
            outside = ~body[ty, tx]
            nb[ys2[outside], xs2[outside]] = True
            cap = (chars == "h") | (chars == "H")
            put(nb & ~cap & (chars != "e") & (chars != "s") & (chars != "S") & (chars != "b"), FIG["rim_licht"])
            put(nb & cap, FIG["p1_pet_l"])
            put(nb & ((chars == "s") | (chars == "S")), hx("#ffd27a"))
        return canvas, body | cont
    if kind == "p2":
        put(body, FIG["p2_lijf"])
        put(chars == "e", FIG["p2_oog"])
        put(chars == "z", FIG["p2_sjaal_g"] if grijs else FIG["p2_sjaal"])
        put(chars == "p", FIG["p2_haak"])
        rim = edge_of(body) & (chars != "e")
        put(rim, FIG["p2_rand_g"] if grijs else FIG["p2_rand"])
        put(outer_of(body), hx("#05050a"))
        return canvas, body | outer_of(body)
    # echo's: hol (rand + diagonale arcering, verankerd aan de sprite)
    cyaan = kind == "echo_p2"
    rimc = (FIG["p2_rand_g"] if grijs else FIG["p2_rand"]) if cyaan else (FIG["echo_rand_g"] if grijs else FIG["echo_rand"])
    binc = FIG["echo_bin_g"] if grijs else (hx("#123a48") if cyaan else FIG["echo_bin"])
    oog = FIG["echo_oog_g"] if grijs else (FIG["p2_oog"] if cyaan else FIG["echo_oog"])
    rim = edge_of(body)
    lx_ = X - x0
    ly_ = Y - y0
    hatch = np.zeros((H, W), bool)
    hm = ((lx_ + ly_) % 3 == 0)
    hatch[Y[ok][hm[ok]], X[ok][hm[ok]]] = True
    put(hatch & body & ~rim, binc)
    put(outer_of(body), hx("#07050c"))
    put(rim, rimc)
    put((chars == "e") | (chars == "e"), oog)
    if not cyaan and not grijs:
        # levende echo: de sjaal krijgt zijn kleur terug
        put(((chars == "s") | (chars == "S")) & ~rim & hm.any() & body & ((XX + YY) % 2 == 0), FIG["amber_s"])
    return canvas, body | outer_of(body)


def trail_layer(rows, positions, state, kind="echo"):
    """Nabeelden van de echo: alleen de rand, gestippeld, oplopend in dichtheid."""
    canvas = np.zeros((H, W, 4))
    grijs = state == "grijs"
    col = (FIG["echo_rand_g"] if grijs else FIG["echo_rand"]) if kind == "echo" else (FIG["p2_rand_g"] if grijs else FIG["p2_rand"])
    dens = [0.22, 0.4]
    for (x, y), dsty in zip(positions, dens):
        grid = sprite_arrays(rows)
        g, x0, y0 = place(grid, x, y)
        body = np.zeros((H, W), bool)
        ys, xs = np.nonzero(g != ".")
        Y, X = ys + y0, xs + x0
        ok = (Y >= 0) & (Y < H) & (X >= 0) & (X < W)
        body[Y[ok], X[ok]] = True
        e = edge_of(body) & (BAY < dsty)
        canvas[e, :3] = col * (0.55 + 0.45 * dsty)
        canvas[e, 3] = 1
    return canvas


def over(img, layer):
    a = layer[..., 3:4]
    return img * (1 - a) + layer[..., :3] * a


# ------------------------------------------------------------------ render
FIGPOS = dict(p1=(168, 318), echo=(300, 278), p2=(346, 298))


def render(state, return_info=False, figures=True):
    w = build(state)
    kleur = state == "kleur"
    LF = light_fields(w)
    # lichtbanden (0..4) met ordered dithering op de verloopranden; schaduwrand blijft hard
    Iw = np.zeros((H, W))
    Iwarm = np.zeros((H, W))
    Ifel = np.zeros((H, W))
    dist0 = ndimage.distance_transform_edt(w.solid > 0)
    face = (w.solid > 0) & (dist0 > 4)   # voorkant van vaste blokken: geen slagschaduw van andere blokken
    for nm, (I, vis, L) in LF.items():
        I = np.where(face, L["Iraw"], I)
        if L["fel"]:
            Ifel = np.maximum(Ifel, I)
        else:
            Iwarm = np.maximum(Iwarm, I)
    recv = np.array([0.55, 0.35, 0.62, 0.9, 1.0])[w.layer]
    # diepte in vaste blokken: alleen de voorkant/bovenkant krijgt vol licht
    dist = ndimage.distance_transform_edt(w.solid > 0)
    depth = np.clip(1.15 - dist / 26.0, 0.45, 1.0)
    depth[w.solid == 0] = 1.0
    Ieff = np.maximum(Iwarm, Ifel) * recv * depth
    lb = np.floor(Ieff * 4.6 + (BAY - 0.5) * 0.6).clip(0, 4).astype(np.int16)
    lb[np.maximum(Iwarm, Ifel) <= 0] = 0
    amb = np.array([0, 1, 2, 2, 2] if kleur else [0, 1, 1, 1, 1])[w.layer]
    # speelvlak loopt naar onder toe donker weg (kader), gedithered
    fade = np.clip((YY - 336) / 44.0, 0, 1) * 1.6
    amb = amb - ((w.solid > 0) & (np.floor(fade + BAY * 0.999) >= 1)).astype(int) \
              - ((w.solid > 0) & (np.floor(fade + BAY * 0.999) >= 2)).astype(int)
    # geworpen schaduw: één tint onder de omgeving, zodat de laag ook op de achtergrond leest
    cast = np.zeros((H, W), bool)
    for nm, (I, vis, L) in LF.items():
        if L["cone"] is None:
            d_ = np.hypot(XX - L["x"], YY - L["y"])
            cast |= (~vis) & (d_ < L["R"] * 0.85) & (w.layer >= 2) & (w.fixed < 0) & ~face
    for nm, (I, vis, L) in LF.items():
        cast &= ~(I > 0)
    amb = amb - cast.astype(int)
    w.cast = cast
    idx = (amb + w.off + lb).clip(0, N - 1)
    idx = np.where(w.fixed >= 0, w.fixed, idx)

    # toestand per pixel: kleur / half / grijs
    if kleur:
        ramps = RAMP_KLEUR[w.mat, idx]
    else:
        rg = RAMP_GRIJS[w.mat, idx]
        rh = RAMP_HALF[w.mat, idx]
        rk = RAMP_KLEUR[w.mat, idx]
        lbw = np.floor(Iwarm * recv * 4.6 + (BAY - 0.5) * 0.9).clip(0, 4)
        ramps = np.where((lbw >= 3)[..., None], rk, np.where((lbw >= 2)[..., None], rh, rg))
        ramps = np.where(w.emis[..., None] & (w.mat == MI["gloed"])[..., None], rk, ramps)
    img = ramps.copy()
    # warme volumetrische bundels (alleen achtergrond): exacte paletkleuren, gedithered
    if kleur and hasattr(w, "beamd"):
        G0 = RAMP_KLEUR[MI["gloed"]]
        bd = w.beamd * (w.layer <= 1) * (w.fixed < 0)
        img[(BAY < bd * 0.42)] = G0[0]
        img[(BAY < bd * 0.12)] = G0[1]
        bh = w.beamd * (w.layer == 2) * (w.fixed < 0)
        sel = BAY < bh * 0.7
        img[sel] = RAMP_KLEUR[w.mat[sel], (idx[sel] + 1).clip(0, N - 1)]
        sel = BAY < bh * 0.2
        img[sel] = RAMP_KLEUR[w.mat[sel], (idx[sel] + 2).clip(0, N - 1)]

    # FelLicht: koud wit, harde rand, binnenin glinsteringen (anders dan warm licht)
    fel_air = (Ifel > 0.02) & (w.solid == 0) & (w.layer <= 3)
    if kleur:
        FL = RAMP_KLEUR[MI["fellicht"]]
        img[fel_air & (BAY < 0.5)] = FL[2]
        img[fel_air & (BAY < 0.125)] = FL[4]
        gevel = (Ifel > 0.02) & (w.solid == 0) & (w.layer == 4) & (w.fixed < 0)
        img[gevel & (BAY < 0.25)] = FL[3]
        img[gevel & (BAY >= 0.25) & (BAY < 0.5)] = FL[1]
        edgef = edge_of(Ifel > 0.02) & (w.solid == 0)
        img[edgef] = FL[5]
        # vloerpoel
        pool = (Ifel > 0.02) & (w.solid == 6) & (YY < 306)
        img[pool] = FL[np.clip(5 + w.off[pool], 3, 7)]
        rng = np.random.default_rng(3)
        ys, xs = np.nonzero(fel_air)
        sel = rng.random(len(ys)) < 0.012
        for yy, xx in zip(ys[sel], xs[sel]):
            img[yy, xx] = FL[7]
            if 0 < xx < W - 1 and 0 < yy < H - 1:
                img[yy - 1, xx] = FL[5]
                img[yy + 1, xx] = FL[5]

    # warm licht in de lucht: lichtval (stof) rond de lampen
    rng = np.random.default_rng(11)
    air = (w.solid == 0) & (w.layer <= 3) & (w.fixed < 0)
    lit_air = air & (Iwarm > 0.25)
    ys, xs = np.nonzero(lit_air)
    sel = rng.random(len(ys)) < (0.004 if kleur else 0.002)
    G = RAMP_KLEUR[MI["gloed"]]
    for yy, xx in zip(ys[sel], xs[sel]):
        img[yy, xx] = G[6] if kleur else (G[5] if Iwarm[yy, xx] > 0.5 else RAMP_HALF[MI["gloed"]][5])

    # halo en stralen van de lantaarn (herkenbare bron): banden + kruis
    lx, ly = w.lantern
    dl = np.hypot(XX - lx, (YY - ly) * 1.1)
    halo_m = air | (w.mat == MI["ijzer"])
    for r, k, dens in [(22, 3, 0.5), (16, 4, 0.75), (11, 5, 1.0)]:
        m = (dl < r) & halo_m & (w.fixed < 0) & (BAY < dens)
        img[m] = G[k]
    for dx, dy, ln in [(1, 0, 15), (-1, 0, 15), (0, 1, 13), (0, -1, 11)]:
        for s in range(9, ln):
            yy, xx = ly + dy * s, lx + dx * s
            if 0 <= yy < H and 0 <= xx < W and w.fixed[yy, xx] < 0:
                img[yy, xx] = G[6] if s < ln - 3 else G[4]
    for d in range(8, 12):
        for sx_, sy_ in [(1, 1), (-1, 1), (1, -1), (-1, -1)]:
            yy, xx = ly + sy_ * d, lx + sx_ * d
            if w.fixed[yy, xx] < 0 and d < 11:
                img[yy, xx] = G[4]
    # straatlamp-halo
    if kleur:
        sx, sy = w.streetlamp
        ds = np.hypot(XX - sx, YY - sy)
        for r, k, dens in [(14, 3, 0.5), (9, 5, 0.85)]:
            m = (ds < r) & (w.solid == 0) & (w.fixed < 0) & (BAY < dens) & (YY > sy - 4)
            img[m] = G[k]

    # laaggrens in de lucht: stippellijn waar de schaduw van de zuil begint (lantaarn)
    I_l, vis_l, _ = LF["lantaarn"]
    inr = np.hypot(XX - lx, YY - ly) < (250 if kleur else 200) - 4
    shadow_l = (~vis_l) & inr
    border = shadow_l & ndimage.binary_dilation(vis_l & inr) & air & (w.solid == 0)
    border &= ~ndimage.binary_dilation(w.solid > 0, iterations=3)
    border &= ((XX + YY) % 4 < 2)
    img[border] = (RAMP_KLEUR if kleur else RAMP_HALF)[MI["gloed"]][4]
    if kleur:
        # zelfde stippelrand langs de lichtkegel van de straatlamp (waar de brug oplost)
        I_s, vis_s, Ls = LF["straatlamp"]
        kegel = (I_s > 0)
        bs = edge_of(kegel) & ~edge_of(np.hypot(XX - Ls["x"], YY - Ls["y"]) < Ls["R"] - 2) & (w.solid == 0)
        bs &= (XX < Ls["x"] - 3) & (YY > Ls["y"] + 6) & ((XX + YY) % 4 < 2) & (w.layer <= 3)
        img[bs] = RAMP_KLEUR[MI["gloed"]][4]

    # schaduwgeometrie: brug bestaat alleen waar géén licht valt
    lit_any = np.zeros((H, W), bool)
    for nm, (I, vis, L) in LF.items():
        lit_any |= I > 0.0
    brug_vorm = rect(262, 298, 438, 305)
    ranken = np.zeros((H, W), bool)
    for rx_ in range(266, 438, 7):
        ln = 6 + (rx_ * 37) % 9
        ranken |= rect(rx_, 305, rx_ + 1, 305 + ln)
        ranken |= rect(rx_ + 1, 305 + ln - 2, rx_ + 2, 305 + ln)
    brug = brug_vorm & ~lit_any
    # alleen ranken onder het draagbare deel (geen kenmerken in het opgeloste deel)
    cols = brug.any(0)
    ranken &= cols[None, :]
    SG = (RAMP_KLEUR if kleur else RAMP_GRIJS)[MI["schaduwgeo"]]
    SGh = RAMP_KLEUR[MI["schaduwgeo"]] if kleur else desat(RAMP_KLEUR[MI["schaduwgeo"]], 0.5)
    bi = np.full((H, W), 3)
    bi[(XX + YY) % 4 == 0] = 2  # arcering
    bi[YY == 298] = 6
    bi[YY == 299] = 5
    bi[YY == 304] = 1
    img[brug] = SGh[bi[brug]]
    img[ranken & ~brug] = SGh[2]
    img[ranken & (YY % 3 == 0)] = SGh[3]
    # hard eindpunt: verticale eindrand + een paar losse schaduwdeeltjes erboven
    endx = np.nonzero(cols & (np.arange(W) > 262))[0]
    w.brug_end = endx.max() if len(endx) else None
    if kleur and w.brug_end is not None:
        ex = w.brug_end
        img[298:305, ex] = SGh[6]
        rng = np.random.default_rng(5)
        for k in range(10):
            px = ex + 2 + int(rng.integers(0, 12))
            py = 296 - int(rng.integers(0, 14))
            img[py, px] = SGh[5] if k % 2 else SGh[4]

    # lichtgeometrie: platform bestaat alleen in licht (onder de lantaarn)
    plat = rect(138, 262, 188, 268)
    platlit = plat & (Iwarm > 0)
    LG = RAMP_KLEUR[MI["lichtgeo"]] if kleur else RAMP_HALF[MI["lichtgeo"]]
    pi_ = np.full((H, W), 4)
    pi_[YY == 262] = 7
    pi_[YY == 263] = 6
    pi_[YY == 267] = 2
    pi_[(YY >= 264) & (YY <= 266) & ((XX - 138) % 8 == 0)] = 2   # gegraveerd maaswerk
    pi_[(YY == 265) & ((XX - 138) % 8 == 4)] = 6
    pi_[(XX == 138) | (XX == 187)] = 3
    img[platlit] = LG[pi_[platlit]]
    # glans eronder: 1 rij dunne lichtpixels
    under = rect(140, 269, 186, 270) & (BAY < 0.5)
    img[under] = LG[5]

    # water: kanaal en achtergrond; lager in de opgepompte toestand
    wl = w.wl
    WR = (RAMP_KLEUR if kleur else RAMP_GRIJS)[MI["water"]]
    watm = (YY >= wl) & ((w.layer <= 3) | (w.solid == 4) | (w.solid == 5)) & ~((w.solid > 0) & (w.solid != 4) & (w.solid != 5))
    watm &= (XX >= 262) & (XX < 438)
    # onder water: vormen blijven vaag zichtbaar
    under_l = (srgb_to_lab(img[watm])[:, 0] / 100.0)
    wi = (1 + np.floor(under_l * 4 + (BAY[watm] - 0.5) * 0.8)).clip(1, 4).astype(int)
    img[watm] = WR[wi]
    # reflecties: gespiegelde heldere pixels, onderbroken (elke 2e rij)
    src = img.copy()
    for d in range(1, 34):
        y = wl + d
        if y >= H:
            break
        ym = wl - d
        if ym < 0:
            break
        rowm = watm[y]
        bright = srgb_to_lab(src[ym])[:, 0] > (52 if kleur else 40)
        sh = int(np.sin(y * 0.9) * 2)
        bright = np.roll(bright, sh)
        m = rowm & bright & (((y + (XX[0] // 6)) % 2 == 0) if True else True) & (BAY[y] < (1 - d / 34.0))
        img[y, m] = WR[5] if kleur else WR[4]
    # wateroppervlak
    srf = (YY == wl) & ((XX >= 262) & (XX < 438))
    img[srf] = WR[5] if kleur else WR[4]
    img[(YY == wl) & srf & ((XX // 3) % 3 == 0)] = WR[7] if kleur else WR[6]
    img[(YY == wl + 1) & ((XX >= 262) & (XX < 438)) & ((XX // 5) % 4 == 1)] = WR[5]
    # golfjes tegen het rad
    img[(YY == wl - 1) & (np.abs(XX - 404) < 50) & ((XX // 2) % 5 == 0) & (XX > 262)] = WR[6]

    # figuren
    if not figures:
        return np.clip(img, 0, 1)
    lpos = w.lantern
    trail_pos = [(252, 300), (276, 286)]
    tr = trail_layer(SP.P1_JUMP, trail_pos, state)
    img = over(img, tr)
    e_c, e_m = fig_layer("echo", SP.P1_JUMP, *FIGPOS["echo"], state)
    img = over(img, e_c)
    p2_c, p2_m = fig_layer("p2", SP.P2_IDLE, *FIGPOS["p2"], state, flip=True)
    img = over(img, p2_c)
    p1_c, p1_m = fig_layer("p1", SP.P1_IDLE, *FIGPOS["p1"], state, lightpos=lpos)
    img = over(img, p1_c)
    # contactschaduw onder speler 1 en 2
    for (fx, fy), wd in [(FIGPOS["p1"], 14), (FIGPOS["p2"], 16)]:
        m = rect(fx - wd // 2, fy, fx + wd // 2, fy + 1) & ~(p1_m | p2_m)
        img[m] = RAMP_KLEUR[MI["steen"]][1] if kleur else RAMP_GRIJS[MI["steen"]][1]

    img = np.clip(img, 0, 1)
    if return_info:
        return img, dict(w=w, LF=LF, masks={"speler 1": p1_m, "speler 2": p2_m, "echo": e_m})
    return img


# ------------------------------------------------------------------ uitvoer
def to_pil(img, scale=1):
    im = Image.fromarray((np.clip(img, 0, 1) * 255 + 0.5).astype(np.uint8))
    if scale != 1:
        im = im.resize((im.width * scale, im.height * scale), Image.NEAREST)
    return im


def label_bar(width, text, sub=None, height=30, scale=2):
    bar = np.zeros((height, width, 3)) + np.array([0.06, 0.055, 0.09])
    draw_text(bar, text, 10, 8, np.array([0.95, 0.9, 0.8]), scale)
    if sub:
        draw_text(bar, sub, 20 + text_width(text, scale), 8, np.array([0.6, 0.6, 0.7]), scale)
    return bar


def edge_contrast(img, mask, ring_px):
    lab = srgb_to_lab(img)[..., 0]
    inner = ndimage.binary_erosion(mask, iterations=2)
    contour = mask & ~inner
    ring = ndimage.binary_dilation(mask, iterations=ring_px) & ~ndimage.binary_dilation(mask, iterations=1)
    bgL = np.median(lab[ring])
    return abs(np.median(lab[inner]) - bgL) if inner.any() else 0.0, abs(np.percentile(lab[contour], 90) - bgL)


def deck_true_size(img_x2):
    """Simuleert de Steam Deck (7 inch, 1280x800, ±216 ppi) op een monitor van ±96 ppi."""
    f = 96 / 216
    im = to_pil(img_x2)
    return im.resize((round(im.width * f), round(im.height * f)), Image.LANCZOS)


def motion_frames(state):
    """Speler 2 (vol) naast de echo (hol) in schaduw, in beweging. Voor de Deck-test."""
    frames = []
    base = render_bg_for_motion(state)
    for i in range(8):
        img = base.copy()
        x2 = 272 + i * 3
        xe = 306 + i * 3
        xw = 340 + i * 3
        f = i % 4
        tr = trail_layer(SP.P1_RUN[f], [(xe - 10, 298), (xe - 5, 298)], state)
        img = over(img, tr)
        c, _ = fig_layer("echo", SP.P1_RUN[f], xe, 298, state)
        img = over(img, c)
        tr2 = trail_layer(SP.P2_RUN[f], [(xw - 10, 298), (xw - 5, 298)], state, kind="p2")
        img = over(img, tr2)
        c, _ = fig_layer("echo_p2", SP.P2_RUN[f], xw, 298, state)
        img = over(img, c)
        c, _ = fig_layer("p2", SP.P2_RUN[f], x2, 298, state)
        img = over(img, c)
        frames.append(img[236:318, 240:384])
    return frames


_BG_CACHE = {}


def render_bg_for_motion(state):
    """Schaduwkant van de scène zonder figuren: achtergrond van de bewegingstest."""
    if state not in _BG_CACHE:
        _BG_CACHE[state] = render(state, figures=False)
    return _BG_CACHE[state]


def main():
    os.makedirs(UIT, exist_ok=True)
    res = {}
    for st in ("grijs", "kleur"):
        img, info = render(st, return_info=True)
        res[st] = (img, info)
        pc = img[PC[0]:PC[1]]
        to_pil(pc).save(os.path.join(UIT, f"r5_{st}_640x360.png"))
        to_pil(pc, 3).save(os.path.join(UIT, f"r5_{st}_x3.png"))
        to_pil(img, 2).save(os.path.join(UIT, f"r5_{st}_deck_1280x800.png"))
        print(f"{st}: schaduwbrug eindigt op x = {info['w'].brug_end}")

    # vergelijking: dezelfde plek grijs-donker en opgepompt-kleurrijk
    g, k = res["grijs"][0][PC[0]:PC[1]], res["kleur"][0][PC[0]:PC[1]]
    gx2 = np.kron(g, np.ones((2, 2, 1)))
    kx2 = np.kron(k, np.ones((2, 2, 1)))
    sheet = np.concatenate([label_bar(1280, "GRIJS-DONKER", "VOOR HET OPPOMPEN"), gx2,
                            label_bar(1280, "OPGEPOMPT-KLEURRIJK", "ZELFDE PLEK, WATER GEZAKT, GEMAAL AAN"), kx2], 0)
    to_pil(sheet).save(os.path.join(UIT, "r5_vergelijking_x2.png"))

    # grijswaarden en deuteranopie
    tiles = []
    for st in ("grijs", "kleur"):
        im = res[st][0][PC[0]:PC[1]]
        tiles.append(np.concatenate([label_bar(640, st.upper() + ": GRIJSWAARDEN", height=22, scale=1), grayscale(im)], 0))
        tiles.append(np.concatenate([label_bar(640, st.upper() + ": DEUTERANOPIE", height=22, scale=1), deuteranopia(im)], 0))
    row1 = np.concatenate(tiles[:2], 1)
    row2 = np.concatenate(tiles[2:], 1)
    to_pil(np.concatenate([row1, row2], 0), 1).save(os.path.join(UIT, "r5_leesbaarheid_grijs_deuteranopie.png"))

    # ware Deck-grootte: hele beeld + uitsnede rond de figuren, beide toestanden
    parts = []
    for st in ("grijs", "kleur"):
        im = res[st][0]
        full = deck_true_size(np.kron(im, np.ones((2, 2, 1))))
        parts.append(np.array(full).astype(float) / 255)
    ts = np.concatenate([np.concatenate([label_bar(parts[0].shape[1], "GRIJS", "WARE DECK-GROOTTE BIJ 96 PPI", 22, 1), parts[0]], 0),
                         np.concatenate([label_bar(parts[1].shape[1], "KLEUR", "WARE DECK-GROOTTE BIJ 96 PPI", 22, 1), parts[1]], 0)], 1)
    to_pil(ts).save(os.path.join(UIT, "r5_deck_ware_grootte.png"))

    # palet
    pal = np.zeros((len(MATS) * 14 + 24, 8 * 22 * 2 + 140, 3)) + 0.06
    draw_text(pal, "KLEUR", 140, 6, np.array([.9, .9, .8]), 1)
    draw_text(pal, "GRIJS", 140 + 8 * 22 + 6, 6, np.array([.9, .9, .8]), 1)
    for i, m in enumerate(MATS):
        y = 20 + i * 14
        draw_text(pal, m.upper(), 4, y + 3, np.array([.8, .8, .8]), 1)
        for j in range(8):
            pal[y:y + 12, 140 + j * 22:140 + j * 22 + 20] = RAMP_KLEUR[i, j]
            pal[y:y + 12, 146 + 8 * 22 + j * 22:146 + 8 * 22 + j * 22 + 20] = RAMP_GRIJS[i, j]
    to_pil(pal, 2).save(os.path.join(UIT, "palet.png"))

    # beweging: speler 2 naast de echo in schaduw (Deck-test)
    for st in ("grijs", "kleur"):
        fr = motion_frames(st)
        ims = [deck_true_size(np.kron(f, np.ones((2, 2, 1)))) for f in fr]
        big = [to_pil(f, 3) for f in fr]
        ims[0].save(os.path.join(UIT, f"r5_beweging_{st}_deck_ware_grootte_placeholder.gif"), save_all=True,
                    append_images=ims[1:], duration=110, loop=0)
        big[0].save(os.path.join(UIT, f"r5_beweging_{st}_x3_placeholder.gif"), save_all=True,
                    append_images=big[1:], duration=110, loop=0)
        strip = np.concatenate([np.array(i).astype(float) / 255 for i in ims[:8]], 1)
        res[st + "_strip"] = strip
    strip = np.concatenate([np.concatenate([label_bar(res["grijs_strip"].shape[1], "GRIJS: SPELER 2 VOL / ECHO HOL / ECHO CYAAN HOL", height=20, scale=1), res["grijs_strip"]], 0),
                            np.concatenate([label_bar(res["kleur_strip"].shape[1], "KLEUR: SPELER 2 VOL / ECHO HOL / ECHO CYAAN HOL", height=20, scale=1), res["kleur_strip"]], 0)], 0)
    to_pil(strip, 1).save(os.path.join(UIT, "r5_beweging_deck_ware_grootte_strip_placeholder.png"))

    # ---------------------------------------------------------- metingen
    print("\nLeesbaarheid (dL*, figuur tegen directe achtergrond, 640x400):")
    print("toestand | figuur    | vulling | contour")
    for st in ("grijs", "kleur"):
        img, info = res[st]
        for nm, m in info["masks"].items():
            a, b = edge_contrast(img, m, 6)
            print(f"{st:8s} | {nm:9s} | {a:7.1f} | {b:7.1f}")
    print("\nKleurverschil dE76 (normaal -> deuteranopie):")
    LG = RAMP_KLEUR[MI["lichtgeo"]]
    FL = RAMP_KLEUR[MI["fellicht"]]
    G = RAMP_KLEUR[MI["gloed"]]
    pairs = [
        ("amber sjaal / lichtgeometrie vlak (4)", FIG["amber"], LG[4]),
        ("amber sjaal / lichtgeometrie rand (7)", FIG["amber"], LG[7]),
        ("amber sjaal schaduw / lichtgeo vlak", FIG["amber_s"], LG[4]),
        ("amber / cyaan (speler 1 / speler 2)", FIG["amber"], FIG["p2_rand"]),
        ("warm licht (gloed 5) / FelLicht (5)", G[5], FL[5]),
        ("warm lichtval (gloed 4) / FelLicht (3)", G[4], FL[3]),
        ("cyaan / schaduwgeometrie (3)", FIG["p2_rand"], RAMP_KLEUR[MI["schaduwgeo"]][3]),
        ("echo-rand grijs / grijze muur (steen 2)", FIG["echo_rand_g"], RAMP_GRIJS[MI["steen"]][2]),
    ]
    for nm, a, b in pairs:
        la, lb_ = srgb_to_lab(np.array([a, b]))
        da, db = srgb_to_lab(deuteranopia(np.array([a, b])))
        print(f"  {nm:42s}: {np.linalg.norm(la - lb_):5.1f} -> {np.linalg.norm(da - db):5.1f}   (dL* {abs(la[0] - lb_[0]):4.1f})")

    # laaggrens: L* lichtkant vs schaduwkant op de achtergrondgevels vlak bij de grens
    for st in ("grijs", "kleur"):
        img, info = res[st]
        I, vis, _ = info["LF"]["lantaarn"]
        lab = srgb_to_lab(img)[..., 0]
        lw_ = info["w"]
        sel = (lw_.layer == 2) & (lw_.fixed < 0) & (lw_.mat != MI["raamdonker"])
        litm = rect(184, 200, 200, 300) & sel & vis
        shm = rect(223, 200, 239, 300) & sel & ~vis
        near = litm | shm
        vis = litm
        print(f"laaggrens naast de zuil (gevels, 16 px) {st}: L* licht {np.median(lab[near & vis]):.1f}, schaduw {np.median(lab[near & ~vis]):.1f}")

    # Deck: zichtbaarheid van de arcering in de echo op ware grootte (modulatie)
    for st in ("grijs", "kleur"):
        img, info = res[st]
        big = np.kron(img, np.ones((2, 2, 1)))
        ts_ = np.array(deck_true_size(big)).astype(float) / 255
        f = 96 / 216
        L = srgb_to_lab(ts_)[..., 0]
        for nm in ("echo", "speler 2"):
            m = info["masks"][nm]
            inner = ndimage.binary_erosion(m, iterations=3)
            mi = np.array(Image.fromarray(inner.astype(np.uint8) * 255).resize((ts_.shape[1], ts_.shape[0]), Image.BOX)) > 250
            print(f"Deck ware grootte {st} {nm}: binnenkant L* mediaan {np.median(L[mi]):.1f}, spreiding (p90-p10) {np.percentile(L[mi], 90) - np.percentile(L[mi], 10):.1f}")


if __name__ == "__main__":
    main()
