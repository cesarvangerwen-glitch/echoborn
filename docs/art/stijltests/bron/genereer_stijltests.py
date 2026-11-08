"""Stijltests Echoborn (#7): dezelfde scène in 2D en in 2.5D.

Eigenaar: Art Director. Alles is procedureel getekend met numpy, scipy en Pillow;
er worden geen externe assets of fonts gebruikt (labels: eigen pixelfont).

Draaien (vanaf de repo-root):
    python3 docs/art/stijltests/bron/genereer_stijltests.py
Schrijft alle PNG's naar docs/art/stijltests/ en print de leesbaarheidsmetingen.

De scène (wereldeenheden 1280x720, 1 eenheid = 1 schermpixel op 720p):
- links een hangende lantaarn (lichtlaag), midden een zuil die een schaduw werpt;
- in die schaduw ligt een schaduwbrug over een kloof (alleen in de schaduwlaag);
- rechts valt een lichtschacht uit het plafond; waar die de brug raakt, lost de brug op;
- speler 1 (licht, amber), de echo van speler 1 (schaduw, amber omlijnd),
  speler 2 (live schaduw in co-op, cyaan), en een vijand (rood, laag en stekelig).
"""
import os
import sys

import numpy as np
from PIL import Image, ImageDraw
from scipy import ndimage

HIER = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HIER)
from pixelfont import draw_text, text_width  # noqa: E402

UIT = os.path.normpath(os.path.join(HIER, ".."))

# ---------------------------------------------------------------- palet
C = {
    "void": np.array([0.045, 0.040, 0.075]),
    "far": np.array([0.090, 0.085, 0.130]),
    "stone": np.array([0.40, 0.36, 0.34]),
    "ceiling": np.array([0.24, 0.22, 0.22]),
    "floor_top": np.array([0.56, 0.50, 0.44]),
    "floor_face": np.array([0.31, 0.28, 0.27]),
    "pillar": np.array([0.47, 0.42, 0.39]),
    "metal": np.array([0.13, 0.11, 0.10]),
    "lamp": np.array([1.00, 0.86, 0.56]),
    "sky": np.array([0.62, 0.62, 0.56]),
    "amb": np.array([0.17, 0.16, 0.32]),       # ambient in de schaduwlaag (koel)
    "lc1": np.array([1.00, 0.76, 0.44]),       # lantaarn (amber)
    "lc2": np.array([0.95, 0.93, 0.82]),       # lichtschacht (bleek)
    "ink": np.array([0.50, 0.36, 1.00]),       # schaduwgeometrie, rand
    "ink_fill": np.array([0.14, 0.09, 0.28]),  # schaduwgeometrie, vulling
    "glass": np.array([1.00, 0.84, 0.52]),     # lichtgeometrie
    # speler 1: licht, amber
    "p1_body": np.array([0.94, 0.89, 0.77]),
    "p1_shade": np.array([0.66, 0.58, 0.52]),
    "p1_acc": np.array([1.00, 0.62, 0.10]),
    "p1_eye": np.array([0.10, 0.06, 0.05]),
    # speler 2: live schaduw, cyaan
    "p2_body": np.array([0.045, 0.045, 0.09]),
    "p2_acc": np.array([0.22, 0.86, 1.00]),
    "p2_eye": np.array([0.80, 1.00, 1.00]),
    # echo: donker, half doorzichtig, rand in de kleur van de eigenaar
    "echo_body": np.array([0.11, 0.07, 0.21]),
    "echo_dith": np.array([0.24, 0.17, 0.40]),
    # vijand
    "en_body": np.array([0.27, 0.05, 0.09]),
    "en_dark": np.array([0.13, 0.025, 0.05]),
    "en_core": np.array([1.00, 0.28, 0.36]),
    "en_eye": np.array([1.00, 0.92, 0.94]),
    "outline": np.array([0.06, 0.04, 0.05]),
}

BAYER4 = np.array([[0, 8, 2, 10], [12, 4, 14, 6], [3, 11, 1, 9], [15, 7, 13, 5]]) / 16.0 + 1 / 32

LANTERN = (250.0, 250.0)
LANTERN_R = 2200.0
FLOOR_Y = 600.0
PIT = (700.0, 960.0)


def bayer(h, w):
    return np.tile(BAYER4, (h // 4 + 1, w // 4 + 1))[:h, :w]


def shaft_edges(y):
    """Linker- en rechterrand van de lichtschacht op hoogte y (wereld)."""
    t = (y - 60.0) / 540.0
    return 1000.0 - 80.0 * t, 1120.0 - 60.0 * t


# ---------------------------------------------------------------- canvas
class Canvas:
    def __init__(self, view, s, ss):
        self.vx0, self.vy0, self.VW, self.VH = view
        self.s, self.ss = s, ss
        self.w, self.h = int(round(self.VW * s)), int(round(self.VH * s))
        ys, xs = np.mgrid[0:self.h, 0:self.w]
        self.X = self.vx0 + (xs + 0.5) / s   # wereldcoördinaten per pixel
        self.Y = self.vy0 + (ys + 0.5) / s

    def P(self, x, y, k):
        return ((x - self.vx0) * k, (y - self.vy0) * k)

    def mask(self, shapes, hard=None):
        ss = self.ss
        k = self.s * ss
        big = Image.new("L", (self.w * ss, self.h * ss), 0)
        d = ImageDraw.Draw(big)
        for sh in shapes:
            kind = sh[0]
            if kind == "poly":
                d.polygon([self.P(x, y, k) for x, y in sh[1]], fill=255)
            elif kind == "rect":
                x0, y0, x1, y1 = sh[1:5]
                d.rectangle([self.P(x0, y0, k), self.P(x1, y1, k)], fill=255)
            elif kind == "ell":
                x0, y0, x1, y1 = sh[1:5]
                d.ellipse([self.P(x0, y0, k), self.P(x1, y1, k)], fill=255)
            elif kind == "line":
                d.line([self.P(x, y, k) for x, y in sh[1]], fill=255, width=max(1, int(round(sh[2] * k))))
            elif kind == "arc":
                x0, y0, x1, y1, a0, a1, wd = sh[1:8]
                d.arc([self.P(x0, y0, k), self.P(x1, y1, k)], a0, a1, fill=255, width=max(1, int(round(wd * k))))
        if ss > 1:
            big = big.resize((self.w, self.h), Image.BOX)
        m = np.asarray(big, dtype=float) / 255.0
        if hard or (hard is None and ss == 1):
            m = (m > 0.5).astype(float)
        return m


def blend(img, mask, color, alpha=1.0):
    a = (mask * alpha)[..., None]
    img[:] = img * (1 - a) + np.asarray(color) * a


def blur(a, sigma):
    if a.ndim == 3:
        return np.stack([ndimage.gaussian_filter(a[..., i], sigma) for i in range(a.shape[2])], -1)
    return ndimage.gaussian_filter(a, sigma)


# ---------------------------------------------------------------- licht
def light_fields(c, soft):
    """Lantaarn (met schaduw van de zuil) en lichtschacht. Geeft I1, I2 en de laagkaart."""
    # voor 2.5D rekenen we op halve resolutie en schalen we op (het licht is toch zacht)
    lc = Canvas((c.vx0, c.vy0, c.VW, c.VH), c.s * (0.5 if soft else 1.0), 1)
    occ = lc.mask(pillar_shapes(), hard=True)
    h, w = occ.shape
    py, px = np.mgrid[0:h, 0:w].astype(float)
    offsets = [(0, 0)] if not soft else [(0, 0), (-14, -8), (14, 8), (-10, 12), (10, -12)]
    vis_sum = np.zeros((h, w))
    for ox, oy in offsets:
        lx = (LANTERN[0] + ox - lc.vx0) * lc.s
        ly = (LANTERN[1] + oy - lc.vy0) * lc.s
        vis = np.ones((h, w))
        exited = occ < 0.5
        for t in np.linspace(0.01, 0.99, 56):
            qx = np.clip((px + (lx - px) * t).astype(int), 0, w - 1)
            qy = np.clip((py + (ly - py) * t).astype(int), 0, h - 1)
            o = occ[qy, qx]
            vis *= 1 - o * exited
            exited |= o < 0.5
        vis_sum += vis
    vis = vis_sum / len(offsets)
    d = np.hypot(lc.X - LANTERN[0], lc.Y - LANTERN[1])
    I1 = vis * np.clip(1 - d / LANTERN_R, 0, 1) ** 2.0
    xl, xr = shaft_edges(lc.Y)
    edge = 16.0 if soft else 0.01
    inside = np.clip((lc.X - xl) / edge + 0.5, 0, 1) * np.clip((xr - lc.X) / edge + 0.5, 0, 1)
    inside *= (lc.Y > 60) & (lc.Y < FLOOR_Y + 8)
    I2 = inside * (0.62 + 0.30 * np.clip((lc.Y - 60) / 540, 0, 1))
    if soft:
        def up(a):
            return np.asarray(Image.fromarray(a.astype(np.float32)).resize((c.w, c.h), Image.BILINEAR), dtype=float)
        I1, I2 = up(I1), up(I2)
    lit = ((I1 > 0.16) | (I2 > 0.30)).astype(float)
    return I1, I2, lit


# ---------------------------------------------------------------- geometrie
def pillar_shapes():
    return [("rect", 555, 290, 615, 600), ("rect", 540, 266, 630, 292), ("rect", 545, 584, 625, 600)]


ARCHES = [140, 420, 820, 1120]


def arch_shapes(cx, grow=0):
    return [("rect", cx - 70 - grow, 262, cx + 70 + grow, 600), ("ell", cx - 70 - grow, 192 - grow, cx + 70 + grow, 332 + grow)]


def humanoid(c, x, y, f, pose):
    """Silhouet van een speler of echo. Voeten op (x, y), f = +1 kijkt rechts."""
    body = [("ell", x - 9, y - 60, x + 9, y - 41)]
    body.append(("poly", [(x + 7 * f, y - 45), (x + 12 * f, y - 13), (x - 15 * f, y - 10), (x - 9 * f, y - 45)]))
    body.append(("poly", [(x - 6 * f, y - 58), (x - 13 * f, y - 64), (x - 8 * f, y - 50)]))  # punt van de kap
    if pose == "walk":
        legs = [[(x + 3 * f, y - 13), (x + 9 * f, y - 1)], [(x - 4 * f, y - 13), (x - 9 * f, y - 1)]]
    elif pose == "jump":
        legs = [[(x + 3 * f, y - 14), (x + 8 * f, y - 7)], [(x - 4 * f, y - 14), (x - 3 * f, y - 4)]]
    else:
        legs = [[(x + 3 * f, y - 13), (x + 3 * f, y - 1)], [(x - 4 * f, y - 13), (x - 4 * f, y - 1)]]
    for lg in legs:
        body.append(("line", lg, 5))
    scarf = [("poly", [(x - 9, y - 45), (x + 8, y - 45), (x + 8, y - 39), (x - 9, y - 39)]),
             ("poly", [(x - 7 * f, y - 44), (x - 25 * f, y - 37), (x - 23 * f, y - 31), (x - 7 * f, y - 39)])]
    eyes = [("rect", x + 1 * f - 1.5, y - 54, x + 1 * f + 1.5, y - 49), ("rect", x + 6 * f - 1.5, y - 54, x + 6 * f + 1.5, y - 49)]
    return {"body": c.mask(body), "scarf": c.mask(scarf), "eyes": c.mask(eyes), "cx": x, "cy": y - 32}


def enemy(c, x, y, f):
    body = [("ell", x - 38, y - 40, x + 34, y - 6), ("ell", x + 14 * f - 14, y - 40, x + 14 * f + 18, y - 14)]
    spines = []
    for i, sx in enumerate([-26, -14, -2, 10]):
        bx = x - sx * f
        spines.append(("poly", [(bx - 7, y - 32), (bx + 7, y - 32), (bx + 10 * f * -1 + (4 if i % 2 else 0), y - 58 + 3 * (i % 2))]))
    for lx in [-26, -10, 8, 22]:
        body.append(("line", [(x + lx, y - 14), (x + lx - 6 * f, y - 1)], 4))
    core = [("ell", x - 4 * f - 7, y - 30, x - 4 * f + 7, y - 16)]
    eyes = [("ell", x + 24 * f - 3, y - 33, x + 24 * f + 3, y - 27), ("ell", x + 15 * f - 2.5, y - 34, x + 15 * f + 2.5, y - 29)]
    return {"body": np.clip(c.mask(body) + c.mask(spines), 0, 1), "core": c.mask(core), "eyes": c.mask(eyes), "cx": x, "cy": y - 24}


# Posities in de scène
P1_POS = (440, 600, +1, "walk")
ECHO_POS = (812, 566, +1, "jump")
ECHO_TRAIL = [(706, 596, "walk"), (742, 580, "jump"), (777, 569, "jump")]
P2_POS = (858, 430, -1, "stand")
EN_POS = (1012, 600, -1)


# ---------------------------------------------------------------- achtergrond
def build_world(c, style):
    """Albedo, emissie, belichtbaarheid en hulpmaskers van de omgeving."""
    soft = style == "25d"
    h, w = c.h, c.w
    A = np.zeros((h, w, 3)) + C["void"]
    E = np.zeros((h, w, 3))
    Lf = np.zeros((h, w))
    X, Y = c.X, c.Y
    # verre achtergrond: torens in de leegte
    grad = np.clip((Y - 0) / 720, 0, 1)[..., None]
    A[:] = C["void"] * (1.15 - 0.45 * grad)
    towers = []
    rng = np.random.default_rng(7)
    for i in range(26):
        tx = i * 52 + rng.integers(-14, 14)
        th = rng.integers(120, 300)
        towers.append(("rect", tx, 600 - th, tx + rng.integers(18, 40), 600))
        towers.append(("poly", [(tx - 4, 600 - th), (tx + 15, 600 - th - rng.integers(20, 60)), (tx + 34, 600 - th)]))
    far = c.mask(towers)
    if soft:
        far = blur(far, 2.2 * c.s)
    blend(A, far, C["far"] * (1.0 + 0.3 * (1 - grad)))
    Lf += far * 0.12
    # muur met bogen
    wall = c.mask([("rect", 0, 70, 1280, 600)])
    openings = np.zeros((h, w))
    for cx in ARCHES:
        openings = np.maximum(openings, c.mask(arch_shapes(cx)))
    wall_m = wall * (1 - openings)
    stone = C["stone"] * np.ones((h, w, 3))
    # baksteen: voegen elke 24 eenheden, stootvoegen verspringend
    row = np.floor(Y / 24.0)
    mortar_h = (np.mod(Y, 24.0) < (2.0 if not soft else 1.6))
    mortar_v = (np.mod(X + (row % 2) * 24.0, 48.0) < (2.0 if not soft else 1.6))
    mort = (mortar_h | mortar_v).astype(float)
    if soft:
        mort = blur(mort, 0.6 * c.s)
        noise = blur(np.random.default_rng(3).normal(0, 1, (h, w)), 2.0 * c.s)
        stone = stone * (1 + 0.10 * noise[..., None])
    else:
        # pixel-art variatie: twee tinten per steen
        sid = (np.floor((X + (row % 2) * 24.0) / 48.0) * 31 + row * 17) % 5
        stone = stone * (1 + 0.05 * (sid[..., None] - 2) / 2)
    stone = stone * (1 - 0.35 * mort[..., None])
    A = A * (1 - wall_m[..., None]) + stone * wall_m[..., None]
    Lf = Lf * (1 - wall_m) + wall_m * (0.85 if soft else 1.0)
    # rand (dagkant) van de bogen: in 2.5D een diepe binnenkant, in 2D een lijn
    for cx in ARCHES:
        outer = c.mask(arch_shapes(cx, grow=0))
        inner = c.mask([("rect", cx - 60, 268, cx + 60, 600), ("ell", cx - 60, 202, cx + 60, 322)])
        if soft:
            reveal = np.clip(outer - inner, 0, 1)
            blend(A, reveal, C["stone"] * 0.55)
            Lf = np.maximum(Lf, reveal * 0.6)
        else:
            rim = np.clip(c.mask(arch_shapes(cx, grow=6)) - outer, 0, 1)
            blend(A, rim, C["stone"] * 1.22)
    # plafond met opening voor de lichtschacht
    ceil = c.mask([("rect", 0, -200, 1280, 72)])
    hole = c.mask([("poly", [(990, 20), (1130, 20), (1120, 72), (1000, 72)])])
    ceil_m = ceil * (1 - hole)
    blend(A, ceil_m, C["ceiling"])
    Lf = Lf * (1 - ceil_m) + ceil_m * 0.6
    blend(A, hole, C["sky"])
    E += hole[..., None] * C["sky"] * 0.55
    # vloer (links en rechts van de kloof)
    top = c.mask([("rect", 0, 600, PIT[0], 614), ("rect", PIT[1], 600, 1280, 614)])
    face = c.mask([("rect", 0, 614, PIT[0], 900), ("rect", PIT[1], 614, 1280, 900)])
    ff = C["floor_face"] * np.ones((h, w, 3)) * (1 - 0.3 * mort[..., None])
    if soft:
        # 2.5D: bovenvlak in perspectief, lichter naar achter, en een donkerder voorkant
        depth = np.clip((Y - 600) / 14, 0, 1)[..., None]
        blend(A, top, C["floor_top"] * (1.08 - 0.25 * depth))
        A = A * (1 - face[..., None]) + (ff * (1 - 0.35 * np.clip((Y - 614) / 120, 0, 1))[..., None]) * face[..., None]
    else:
        blend(A, top, C["floor_top"])
        A = A * (1 - face[..., None]) + ff * face[..., None]
        edge = c.mask([("rect", 0, 600, PIT[0], 601), ("rect", PIT[1], 600, 1280, 601)])
        blend(A, edge, C["floor_top"] * 1.2)
    Lf = np.maximum(Lf * (1 - top - face), top * 1.0 + face * 0.55)
    # kloof
    pit = c.mask([("rect", PIT[0], 600, PIT[1], 900)])
    pitg = np.clip((Y - 600) / 120, 0, 1)[..., None]
    A = A * (1 - pit[..., None]) + (C["void"] * (0.9 - 0.6 * pitg)) * pit[..., None]
    Lf *= 1 - pit
    # zuil
    pil = c.mask(pillar_shapes())
    pc = C["pillar"] * np.ones((h, w, 3))
    if soft:
        u = np.clip((X - 555) / 60, 0, 1)
        cyl = 0.55 + 0.6 * np.sin(np.pi * np.clip(u * 0.85, 0, 1))  # licht van links
        flute = 1 - 0.12 * (np.cos((X - 555) / 60 * np.pi * 6) > 0.6)
        pc = pc * (cyl * flute)[..., None]
    else:
        fl = ((np.mod(X - 555, 15) < 2) & (Y > 292) & (Y < 584)).astype(float)
        dark_side = (X > 597).astype(float)
        pc = pc * (1 - 0.25 * fl - 0.22 * dark_side)[..., None]
    A = A * (1 - pil[..., None]) + pc * pil[..., None]
    Lf = np.maximum(Lf * (1 - pil), pil)
    # lantaarn
    chain = c.mask([("line", [(250, 72), (250, 234)], 2)])
    blend(A, chain, C["metal"])
    lampb = c.mask([("poly", [(236, 234), (264, 234), (260, 266), (240, 266)]), ("rect", 233, 230, 267, 236)])
    blend(A, lampb, C["metal"])
    core = c.mask([("ell", 241, 241, 259, 261)])
    blend(A, core, C["lamp"])
    E += core[..., None] * C["lamp"] * (1.4 if soft else 0.5)
    Lf *= 1 - np.clip(chain + lampb + core, 0, 1)
    return A, E, Lf


def shadow_geometry(c):
    bridge = c.mask([("rect", PIT[0] - 6, 596, PIT[1] + 4, 609)])
    ledge = c.mask([("rect", 800, 430, 920, 442)])
    tendr = []
    for i, tx in enumerate(range(712, 960, 22)):
        ln = 18 + (i * 7) % 20
        tendr.append(("line", [(tx, 609), (tx + 4, 609 + ln * 0.5), (tx - 2, 609 + ln)], 2))
    for tx in range(808, 920, 26):
        tendr.append(("line", [(tx, 442), (tx + 3, 452), (tx - 1, 462)], 2))
    return bridge, ledge, c.mask(tendr)


def light_geometry(c):
    return c.mask([("rect", 660, 236, 800, 247)])


# ---------------------------------------------------------------- personages
def comp_humanoid_2d(img, c, parts, kind, light_xy, alpha=1.0, ghost=False):
    body, scarf, eyes = parts["body"] > 0.5, parts["scarf"] > 0.5, parts["eyes"] > 0.5
    union = body | scarf
    outline = ndimage.binary_dilation(union) & ~union
    owner = "p1" if kind in ("p1", "echo1") else "p2"
    acc = C[owner + "_acc"]
    dith = bayer(c.h, c.w)
    if ghost:
        sel = outline & (dith < alpha)
        img[sel] = acc
        return
    if kind == "p1":
        lx, ly = light_xy
        dx, dy = lx - parts["cx"], ly - parts["cy"]
        n = np.hypot(dx, dy) + 1e-6
        away = ((c.X - parts["cx"]) * dx / n + (c.Y - parts["cy"]) * dy / n) < -3
        img[body] = C["p1_body"]
        img[body & away] = C["p1_shade"]
        img[scarf] = acc
        img[eyes] = C["p1_eye"]
        img[outline] = C["outline"]
    elif kind == "p2":
        img[body] = C["p2_body"]
        img[scarf] = acc
        img[eyes] = C["p2_eye"]
        img[outline] = acc * 0.85
    else:  # echo
        checker = ((np.indices((c.h, c.w)).sum(0)) % 2 == 0)
        img[body] = C["echo_body"]
        img[body & checker] = C["echo_dith"]
        img[scarf & ~ndimage.binary_erosion(scarf)] = acc
        img[scarf & ndimage.binary_erosion(scarf)] = C["echo_dith"]
        img[eyes] = acc
        img[outline] = acc


def comp_enemy_2d(img, c, parts):
    body, core, eyes = parts["body"] > 0.5, parts["core"] > 0.5, parts["eyes"] > 0.5
    outline = ndimage.binary_dilation(body) & ~body
    lower = body & (c.Y > parts["cy"] + 6)
    img[body] = C["en_body"]
    img[lower] = C["en_dark"]
    top_rim = body & ~ndimage.binary_erosion(body) & (c.Y < parts["cy"])
    img[top_rim] = C["en_core"] * 0.75
    img[core] = C["en_core"]
    cc = ndimage.binary_erosion(core, iterations=2)
    img[cc] = np.array([1.0, 0.85, 0.85])
    img[eyes] = C["en_eye"]
    img[outline] = C["outline"]


def normals_from_mask(m, sigma):
    hgt = ndimage.gaussian_filter(m, sigma)
    gy, gx = np.gradient(hgt)
    k = 3.0 * sigma
    n = np.stack([-gx * k, -gy * k, np.ones_like(m)], -1)
    return n / np.linalg.norm(n, axis=-1, keepdims=True)


def comp_humanoid_25d(img, E, c, parts, kind, light_xy, I_here, alpha=1.0, ghost=False):
    body, scarf, eyes = parts["body"], parts["scarf"], parts["eyes"]
    union = np.clip(body + scarf, 0, 1)
    n = normals_from_mask(union, 2.6 * c.s)
    lx, ly = light_xy
    L = np.stack([lx - c.X, ly - c.Y, np.full_like(c.X, 90.0)], -1)
    L /= np.linalg.norm(L, axis=-1, keepdims=True)
    lam = np.clip((n * L).sum(-1), 0, 1)[..., None]
    fres = ((1 - n[..., 2]) ** 1.6)[..., None]
    owner = "p1" if kind in ("p1", "echo1") else "p2"
    acc = C[owner + "_acc"]
    if ghost:
        edge = np.clip(union - ndimage.grey_erosion(union, size=3), 0, 1)
        blend(img, edge, acc, alpha * 0.8)
        E += edge[..., None] * acc * alpha * 0.4
        return
    if kind == "p1":
        alb = C["p1_body"] * body[..., None] * (1 - scarf[..., None]) + C["p1_acc"] * scarf[..., None]
        col = alb * (0.42 + 1.05 * I_here * C["lc1"] * lam + 0.15) + fres * C["lc1"] * 0.25
        col = col * (1 - eyes[..., None]) + C["p1_eye"] * eyes[..., None]
        blend(img, union, np.clip(col, 0, 1.2))
        E += scarf[..., None] * C["p1_acc"] * 0.10
    elif kind == "p2":
        col = C["p2_body"] * (0.6 + 0.6 * lam) + fres * acc * 1.25
        col = col * (1 - scarf[..., None]) + (acc * (0.55 + 0.45 * lam)) * scarf[..., None]
        col = col * (1 - eyes[..., None]) + C["p2_eye"] * eyes[..., None]
        blend(img, union, np.clip(col, 0, 1.2))
        edge = np.clip(union - ndimage.grey_erosion(union, size=3), 0, 1)
        blend(img, edge, acc, 0.7)
        E += (edge[..., None] * 0.4 + fres * union[..., None] * 0.6 + eyes[..., None] * 1.2 + scarf[..., None] * 0.25) * acc
    else:  # echo: doorschijnend, rand in eigenaarskleur
        col = C["echo_body"] * (0.8 + 0.5 * lam) + fres * acc * 1.1
        col = col * (1 - eyes[..., None]) + acc * eyes[..., None]
        blend(img, union, np.clip(col, 0, 1.2), 0.78 * alpha)
        edge = np.clip(union - ndimage.grey_erosion(union, size=3), 0, 1)
        blend(img, edge, acc, 0.85 * alpha)
        E += (fres * union[..., None] * 0.55 + edge[..., None] * 0.5 + eyes[..., None] * 1.0) * acc * alpha


def comp_enemy_25d(img, E, c, parts, light_xy, I_here):
    body, core, eyes = parts["body"], parts["core"], parts["eyes"]
    n = normals_from_mask(body, 3.2 * c.s)
    lx, ly = light_xy
    L = np.stack([lx - c.X, ly - c.Y, np.full_like(c.X, 90.0)], -1)
    L /= np.linalg.norm(L, axis=-1, keepdims=True)
    lam = np.clip((n * L).sum(-1), 0, 1)[..., None]
    fres = ((1 - n[..., 2]) ** 1.5)[..., None]
    col = C["en_body"] * (0.45 + 1.1 * I_here * lam) + fres * C["en_core"] * 0.55
    col = col * (1 - core[..., None]) + C["en_core"] * 1.1 * core[..., None]
    col = col * (1 - eyes[..., None]) + C["en_eye"] * eyes[..., None]
    blend(img, body, np.clip(col, 0, 1.2))
    E += (core[..., None] * 1.4 + eyes[..., None] * 0.8 + fres * body[..., None] * 0.25) * C["en_core"]


def contact_shadow(img, c, x, y, wdt, soft, strength=0.55):
    if soft:
        m = c.mask([("ell", x - wdt, y - 4, x + wdt, y + 5)])
        m = blur(m, 3 * c.s)
    else:
        m = c.mask([("rect", x - wdt * 0.8, y, x + wdt * 0.8, y + 2)])
    img *= (1 - strength * m)[..., None]


def echo_timer(c, x, y, frac):
    ring = c.mask([("arc", x - 12, y - 12, x + 12, y + 12, -90, -90 + 360 * frac, 3.5)])
    back = c.mask([("arc", x - 12, y - 12, x + 12, y + 12, 0, 360, 3.5)])
    return ring, back


# ---------------------------------------------------------------- scène
def render_scene(style, view=(0, 0, 1280, 720)):
    soft = style == "25d"
    c = Canvas(view, 1.0 if soft else 0.5, 3 if soft else 1)
    I1, I2, lit = light_fields(c, soft)
    A, E, Lf = build_world(c, style)
    h, w = c.h, c.w
    dith = bayer(h, w)
    if soft:
        Ia, Ib = I1, I2
    else:
        # pixel-art belichting: drie banden plus ordered dithering op de overgang
        def bands(I):
            v = I + (dith - 0.5) * 0.10
            return np.select([v < 0.16, v < 0.40, v < 0.68], [0.0, 0.42, 0.72], 1.0)
        Ia, Ib = bands(I1), bands(I2) * 0.9
    light = C["amb"] + (1.6 if soft else 1.25) * Lf[..., None] * (C["lc1"] * Ia[..., None] + C["lc2"] * Ib[..., None])
    light = C["amb"] * (1 - Lf[..., None]) + light * Lf[..., None] + (1 - Lf[..., None]) * 0.0
    img = A * np.maximum(light, C["amb"][None, None] * 0.9)
    # volumetrisch licht (2.5D) / lichtbanden in de lucht (2D)
    air = 1 - np.clip(Lf, 0, 1) * 0.6
    if soft:
        img += air[..., None] * (I1[..., None] * C["lc1"] * 0.10 + I2[..., None] * C["lc2"] * 0.17)
    else:
        img += air[..., None] * (Ia[..., None] * C["lc1"] * 0.05 + Ib[..., None] * C["lc2"] * 0.10)
    img += E * (0.7 if soft else 1.0)

    # grens tussen licht- en schaduwlaag
    edge = (lit - ndimage.binary_erosion(lit > 0.5, iterations=1, border_value=1).astype(float)) * (c.Y < 598)
    if soft:
        g = blur(lit, 2.0)
        gm = np.hypot(*np.gradient(g)) * 6 * (c.Y < 598)
        img += np.clip(gm, 0, 1)[..., None] * C["lc1"] * 0.18
    else:
        dotted = edge * ((np.indices((h, w)).sum(0) % 2) == 0)  # alleen in de lucht/op de muur
        blend(img, dotted, C["lc1"] * 0.9, 0.55)

    # lichtgeometrie: alleen vast in het licht
    lg = light_geometry(c)
    vis_l = lit if not soft else np.clip(blur(lit, 1.5), 0, 1)
    if soft:
        blend(img, lg * vis_l, C["glass"] * 0.85, 0.75)
        lg_edge = np.clip(lg - ndimage.grey_erosion(lg, size=3), 0, 1)
        E_lg = lg_edge * vis_l
        img += E_lg[..., None] * C["glass"] * 0.6
        lg_glow = E_lg
    else:
        blend(img, lg * vis_l, C["glass"] * 0.8)
        top = lg * (1 - np.roll(lg, 1, axis=0))
        blend(img, top * vis_l, np.array([1, 1, 0.92]))
        bot = lg * (1 - np.roll(lg, -1, axis=0))
        blend(img, bot * vis_l, C["glass"] * 0.55)
        lg_glow = np.zeros((h, w))

    # schaduwgeometrie: alleen vast in de schaduw; lost op in licht
    bridge, ledge, tendr = shadow_geometry(c)
    sg = np.clip(bridge + ledge, 0, 1)
    if soft:
        unlit = np.clip(1 - blur(lit, 3.0) * 1.15, 0, 1)
        smoke = blur(np.random.default_rng(11).random((h, w)), 1.5)
        dissolve = np.clip((unlit - 0.25 + (smoke - 0.5) * 0.6) * 2.2, 0, 1)
        blend(img, sg * dissolve, C["ink_fill"], 0.92)
        sg_edge = np.clip(sg - ndimage.grey_erosion(sg, size=3), 0, 1)
        img += (sg_edge * dissolve)[..., None] * C["ink"] * 0.55
        blend(img, blur(tendr, 0.8) * dissolve, C["ink"] * 0.55, 0.7)
        sg_glow = (sg_edge * dissolve + sg * dissolve * 0.25)
    else:
        unlit = 1 - lit
        dissolve = ((unlit > 0.5) | (dith < 0.0)).astype(float)
        # in het licht: alleen nog verspreide stippen (oplossen)
        near = ndimage.binary_dilation(unlit > 0.5, iterations=6) & ~(unlit > 0.5)
        dissolve = np.maximum(dissolve, (near & (dith < 0.25)).astype(float))
        sgb = (sg > 0.5)
        hatch = (np.mod(np.indices((h, w))[1] + np.indices((h, w))[0], 4) == 0)
        img[sgb & (dissolve > 0)] = C["ink_fill"]
        img[sgb & (dissolve > 0) & hatch] = C["ink"] * 0.6
        rim = sgb & ~ndimage.binary_erosion(sgb)
        img[rim & (dissolve > 0)] = C["ink"]
        img[(tendr > 0.5) & (dissolve > 0)] = C["ink"] * 0.7
        sg_glow = np.zeros((h, w))

    # personages
    masks = {}
    Eglow = np.zeros((h, w, 3))
    lightxy = LANTERN
    x, y, f, pose = P1_POS
    contact_shadow(img, c, x, y, 16, soft)
    p1 = humanoid(c, x, y, f, pose)
    ex, ey, ef, epose = ECHO_POS
    trail = [humanoid(c, tx, ty, ef, tp) for tx, ty, tp in ECHO_TRAIL]
    for i, tp in enumerate(trail):
        a = [0.20, 0.35, 0.55][i]
        if soft:
            comp_humanoid_25d(img, Eglow, c, tp, "echo1", lightxy, 0, alpha=a, ghost=True)
        else:
            comp_humanoid_2d(img, c, tp, "echo1", lightxy, alpha=a, ghost=True)
    echo = humanoid(c, ex, ey, ef, epose)
    x2, y2, f2, pose2 = P2_POS
    p2 = humanoid(c, x2, y2, f2, pose2)
    enx, eny, enf = EN_POS
    contact_shadow(img, c, enx, eny, 36, soft)
    en = enemy(c, enx, eny, enf)

    def I_at(px, py):
        j = int(np.clip((px - c.vx0) * c.s, 0, w - 1))
        i = int(np.clip((py - c.vy0) * c.s, 0, h - 1))
        return float(I1[i, j]), float(I2[i, j])

    if soft:
        a1, _ = I_at(p1["cx"], p1["cy"])
        comp_humanoid_25d(img, Eglow, c, p1, "p1", lightxy, max(a1, 0.35))
        comp_humanoid_25d(img, Eglow, c, echo, "echo1", lightxy, 0.0)
        comp_humanoid_25d(img, Eglow, c, p2, "p2", lightxy, 0.0)
        _, b2 = I_at(en["cx"], en["cy"])
        comp_enemy_25d(img, Eglow, c, en, (1060, 60), max(b2, 0.3))
    else:
        comp_humanoid_2d(img, c, p1, "p1", lightxy)
        comp_humanoid_2d(img, c, echo, "echo1", lightxy)
        comp_humanoid_2d(img, c, p2, "p2", lightxy)
        comp_enemy_2d(img, c, en)

    # echo-timer (hoeveel van de 10 s nog over is), in de kleur van de eigenaar
    ring, back = echo_timer(c, ex + 26, ey - 74, 0.62)
    if soft:
        blend(img, back, C["echo_body"], 0.6)
        blend(img, ring, C["p1_acc"])
        Eglow += ring[..., None] * C["p1_acc"] * 0.4
    else:
        img[back > 0.5] = C["echo_body"]
        img[ring > 0.5] = C["p1_acc"]

    for name, parts, kind in [("speler 1", p1, "h"), ("echo", echo, "h"), ("speler 2", p2, "h"), ("vijand", en, "e")]:
        m = parts["body"] if kind == "e" else np.clip(parts["body"] + parts["scarf"], 0, 1)
        masks[name] = m > 0.5

    # stofdeeltjes in het licht
    rng = np.random.default_rng(5)
    motes = []
    for _ in range(46):
        mx, my = rng.uniform(80, 1240), rng.uniform(90, 590)
        motes.append((mx, my, rng.uniform(1.0, 2.6)))
    mote_m = c.mask([("ell", mx - r, my - r, mx + r, my + r) for mx, my, r in motes])
    lit_amt = np.clip(I1 + I2, 0, 1)
    if soft:
        img += (blur(mote_m, 0.8) * lit_amt)[..., None] * C["lc1"] * 0.7
    else:
        sel = (mote_m > 0.5) & (lit_amt > 0.3) & ~np.any(np.stack(list(masks.values())), 0)
        img[sel] = np.clip(img[sel] + C["lc1"] * 0.35, 0, 1)

    if soft:
        # bloom op emissie en heldere delen, diepte-onscherpe voorgrond, vignet
        bright = np.clip(img - 0.85, 0, None)
        glow_src = Eglow + E * 0.5 + bright + lg_glow[..., None] * C["glass"] * 0.5 + sg_glow[..., None] * C["ink"] * 0.35
        img += blur(glow_src, 4 * c.s) * 0.55 + blur(glow_src, 18 * c.s) * 0.45
        fg = c.mask([("poly", [(-20, 720), (-20, 250), (40, 236), (70, 720)]),
                     ("line", [(1250, -10), (1228, 140), (1240, 260)], 10)])
        fg = blur(fg, 6 * c.s)
        img = img * (1 - 0.92 * fg[..., None]) + 0.92 * fg[..., None] * np.array([0.02, 0.018, 0.03])
        vy, vx = (c.Y - 360) / 520, (c.X - 640) / 900
        vig = np.clip(1 - 0.55 * (vx ** 2 + vy ** 2), 0, 1)
        img *= vig[..., None]
        # licht filmisch afvlakken
        img = img / (1 + 0.18 * img)
        img = np.clip(img * 1.12, 0, 1)
    else:
        img = np.clip(img, 0, 1)
        # 2D: palet licht vastzetten (kwantiseren) voor een consistente pixel-look
        img = np.round(img * 31) / 31

    return {"img": img, "lit": lit, "I1": I1, "I2": I2, "masks": masks, "canvas": c,
            "sg": sg, "lg": lg}


def to_pil(img, scale=1):
    im = Image.fromarray((np.clip(img, 0, 1) * 255 + 0.5).astype(np.uint8))
    if scale != 1:
        im = im.resize((im.width * scale, im.height * scale), Image.NEAREST)
    return im


# ---------------------------------------------------------------- analyse
def srgb_to_lab(rgb):
    a = np.where(rgb <= 0.04045, rgb / 12.92, ((rgb + 0.055) / 1.055) ** 2.4)
    M = np.array([[0.4124, 0.3576, 0.1805], [0.2126, 0.7152, 0.0722], [0.0193, 0.1192, 0.9505]])
    xyz = a @ M.T / np.array([0.9505, 1.0, 1.089])
    f = np.where(xyz > 0.008856, np.cbrt(xyz), 7.787 * xyz + 16 / 116)
    L = 116 * f[..., 1] - 16
    A = 500 * (f[..., 0] - f[..., 1])
    B = 200 * (f[..., 1] - f[..., 2])
    return np.stack([L, A, B], -1)


def deuteranopia(rgb):
    lin = np.where(rgb <= 0.04045, rgb / 12.92, ((rgb + 0.055) / 1.055) ** 2.4)
    M = np.array([[0.367322, 0.860646, -0.227968], [0.280085, 0.672501, 0.047413], [-0.011820, 0.042940, 0.968881]])
    o = np.clip(lin @ M.T, 0, 1)
    return np.where(o <= 0.0031308, o * 12.92, 1.055 * o ** (1 / 2.4) - 0.055)


def grayscale(rgb):
    y = (rgb * np.array([0.2126, 0.7152, 0.0722])).sum(-1, keepdims=True)
    return np.repeat(y, 3, -1)


def edge_contrast(img, mask, ring_px):
    """Silhouetcontrast tegen de directe achtergrond, in CIELAB L* (lichtheid).

    fig     = silhouet + 2 px, zodat contour (2D) en rim (2.5D) meetellen
    vulling = binnenkant van het silhouet (zonder de buitenste 2 px)
    contour = buitenste 3 px van fig
    ring    = 3..ring_px px buiten fig
    Geeft (dL vulling, dL contour); een figuur leest als minstens één van beide groot is.
    """
    lab = srgb_to_lab(img)[..., 0]
    fig = ndimage.binary_dilation(mask, iterations=2)
    fill = ndimage.binary_erosion(mask, iterations=2)
    contour = fig & ~ndimage.binary_erosion(fig, iterations=3)
    ring = ndimage.binary_dilation(fig, iterations=ring_px) & ~ndimage.binary_dilation(fig, iterations=3)
    bg = np.median(lab[ring])
    return abs(np.median(lab[fill]) - bg), abs(np.percentile(lab[contour], 90) - bg) if np.median(lab[contour]) >= bg else abs(np.percentile(lab[contour], 10) - bg)


def label_bar(width, text, sub=None, height=44, bg=(0.07, 0.06, 0.10)):
    bar = np.zeros((height, width, 3)) + np.array(bg)
    draw_text(bar, text, 14, 10, np.array([0.95, 0.92, 0.85]), scale=3)
    if sub:
        draw_text(bar, sub, 14 + text_width(text, 3) + 24, 18, np.array([0.62, 0.60, 0.70]), scale=2)
    return bar


def label_on(img, text, x=10, y=10, scale=2):
    tw = text_width(text, scale)
    img[y - 4:y + 7 * scale + 4, x - 6:x + tw + 6] = img[y - 4:y + 7 * scale + 4, x - 6:x + tw + 6] * 0.25
    draw_text(img, text, x, y, np.array([0.96, 0.93, 0.86]), scale=scale)
    return img


def np_img(pil):
    return np.asarray(pil, dtype=float) / 255.0


# ---------------------------------------------------------------- lagenoverzicht
def layer_panels(res, style):
    """Vier panelen: laagkaart, alleen lichtlaag, alleen schaduwlaag, samengesteld."""
    img = res["img"]
    lit = res["lit"]
    c = res["canvas"]
    s = 2 if style == "2d" else 1
    full = img
    if s == 2:
        full = np_img(to_pil(img, 2))
        lit = np.kron(lit, np.ones((2, 2)))
        masks = {k: np.kron(v, np.ones((2, 2))) > 0.5 for k, v in res["masks"].items()}
        sg = np.kron(res["sg"], np.ones((2, 2))); lg = np.kron(res["lg"], np.ones((2, 2)))
    else:
        masks = res["masks"]; sg = res["sg"]; lg = res["lg"]
    gray = grayscale(full) * 0.35
    l3 = lit[..., None]
    # laagkaart
    kaart = np.zeros_like(full)
    kaart[:] = np.array([0.20, 0.15, 0.36]) * (1 - l3) + np.array([0.86, 0.70, 0.42]) * l3
    kaart = kaart * (0.55 + 0.45 * grayscale(full))
    for k, col in [("speler 1", C["p1_acc"]), ("vijand", C["en_core"])]:
        kaart[masks[k]] = col
    for k, col in [("echo", np.array([0.75, 0.55, 1.0])), ("speler 2", C["p2_acc"])]:
        kaart[masks[k]] = col
    kaart[sg > 0.5] = kaart[sg > 0.5] * 0.4 + C["ink"] * 0.6
    kaart[lg > 0.5] = np.array([1.0, 0.95, 0.75])
    licht = full * l3 + gray * (1 - l3)
    schaduw = full * (1 - l3) + gray * l3
    # personages tonen we in hun eigen laag, ook als ze over de grens staan
    for k in ["speler 1", "vijand"]:
        licht[masks[k]] = full[masks[k]]
        schaduw[masks[k]] = gray[masks[k]]
    for k in ["echo", "speler 2"]:
        schaduw[masks[k]] = full[masks[k]]
        licht[masks[k]] = gray[masks[k]]
    return kaart, licht, schaduw, full


def grid(panels, labels, cols, scale_to=(640, 360)):
    tiles = []
    for p, lab in zip(panels, labels):
        t = np_img(to_pil(p).resize(scale_to, Image.LANCZOS))
        tiles.append(label_on(t, lab))
    rows = [np.concatenate(tiles[i:i + cols], 1) for i in range(0, len(tiles), cols)]
    return np.concatenate(rows, 0)


# ---------------------------------------------------------------- personagekaart
def lineup(style):
    """Alle figuren naast elkaar op drie achtergronden: licht, grens, schaduw."""
    soft = style == "25d"
    out_rows = []
    figs = [("speler 1", "p1", +1), ("echo s1", "echo1", +1), ("speler 2", "p2", +1), ("echo s2", "echo2", +1), ("vijand", "en", -1)]
    for bgname in ["licht", "grens", "schaduw"]:
        view = (0, 0, 960, 140)
        c = Canvas(view, 1.5 if soft else 0.5, 3 if soft else 1)
        h, w = c.h, c.w
        A = C["stone"] * np.ones((h, w, 3))
        row = np.floor(c.Y / 24.0)
        mort = ((np.mod(c.Y, 24.0) < 2) | (np.mod(c.X + (row % 2) * 24.0, 48.0) < 2)).astype(float)
        A = A * (1 - 0.35 * mort[..., None])
        floor = c.Y > 118
        A[floor] = C["floor_top"]
        if bgname == "licht":
            I = np.full((h, w), 0.85)
        elif bgname == "schaduw":
            I = np.zeros((h, w))
        else:
            I = np.clip(1.0 - (c.X % 192) / 192 * 1.6, 0, 1)  # per figuur loopt licht over in schaduw
        if not soft:
            v = I + (bayer(h, w) - 0.5) * 0.10
            I = np.select([v < 0.16, v < 0.40, v < 0.68], [0.0, 0.42, 0.72], 1.0)
        img = A * (C["amb"] + 1.25 * C["lc1"] * I[..., None])
        E = np.zeros((h, w, 3))
        lightxy = (-200, -300)
        for i, (nm, kind, f) in enumerate(figs):
            fx = 96 + i * 192
            if kind == "en":
                parts = enemy(c, fx, 118, f)
                if soft:
                    comp_enemy_25d(img, E, c, parts, lightxy, float(I[int(h * 0.6), int((fx - 30) * c.s)]))
                else:
                    comp_enemy_2d(img, c, parts)
            else:
                parts = humanoid(c, fx + 6, 118, f, "stand")
                kk = {"p1": "p1", "p2": "p2", "echo1": "echo1", "echo2": "echo2"}[kind]
                if soft:
                    comp_humanoid_25d(img, E, c, parts, kk if kk != "echo2" else "echo2", lightxy,
                                      float(I[int(h * 0.5), int((fx + 6) * c.s)]))
                else:
                    comp_humanoid_2d(img, c, parts, kk, lightxy)
        if soft:
            img += blur(E, 3 * c.s) * 0.5 + blur(E, 10 * c.s) * 0.3
            img = img / (1 + 0.18 * img)
            img = np.clip(img * 1.12, 0, 1)
            pil = to_pil(img)
        else:
            pil = to_pil(np.round(np.clip(img, 0, 1) * 31) / 31, 3)
        t = np_img(pil)
        out_rows.append(label_on(t, bgname, x=8, y=8))
    return np.concatenate(out_rows, 0), [f[0] for f in figs]


# ---------------------------------------------------------------- main
def main():
    os.makedirs(UIT, exist_ok=True)
    print("render 2D ...")
    r2 = render_scene("2d")
    print("render 2.5D ...")
    r25 = render_scene("25d")
    img2 = np_img(to_pil(r2["img"], 2))
    img25 = r25["img"]
    to_pil(img2).save(os.path.join(UIT, "stijltest_2d_placeholder.png"))
    to_pil(img25).save(os.path.join(UIT, "stijltest_25d_placeholder.png"))

    # naast elkaar (onder elkaar, volle resolutie)
    cmp_ = np.concatenate([label_bar(1280, "A. 2D", "PIXEL ART 640X360, X2 GESCHAALD"), img2,
                           label_bar(1280, "B. 2.5D", "3D-LOOK: NORMALEN, ZACHT LICHT, MIST, BLOOM"), img25], 0)
    to_pil(cmp_).save(os.path.join(UIT, "vergelijking_2d_25d_placeholder.png"))

    # lagen
    for r, st, nm in [(r2, "2d", "2D"), (r25, "25d", "2.5D")]:
        k, l, s_, f = layer_panels(r, st)
        g = grid([k, l, s_, f], ["1. LAAGKAART (AMBER = LICHT, PAARS = SCHADUW)", "2. ALLEEN LICHTLAAG",
                                 "3. ALLEEN SCHADUWLAAG", "4. SAMENGESTELD"], 2)
        g = np.concatenate([label_bar(g.shape[1], "LAGEN " + nm), g], 0)
        to_pil(g).save(os.path.join(UIT, f"lagen_{st}_placeholder.png"))

    # leesbaarheid: grijswaarden en deuteranopie
    g = grid([grayscale(img2), grayscale(img25), deuteranopia(img2), deuteranopia(img25)],
             ["2D GRIJSWAARDEN", "2.5D GRIJSWAARDEN", "2D DEUTERANOPIE", "2.5D DEUTERANOPIE"], 2)
    g = np.concatenate([label_bar(g.shape[1], "LEESBAARHEID", "WAARDE EN KLEURENBLINDHEID"), g], 0)
    to_pil(g).save(os.path.join(UIT, "leesbaarheid_grijs_kleurenblind_placeholder.png"))

    # Steam Deck: native 1280x800 (16:10) render
    print("render Steam Deck 16:10 ...")
    d2 = render_scene("2d", view=(0, -40, 1280, 800))
    d25 = render_scene("25d", view=(0, -40, 1280, 800))
    dimg2 = np_img(to_pil(d2["img"], 2))
    dimg25 = d25["img"]
    to_pil(dimg2).save(os.path.join(UIT, "steamdeck_2d_1280x800_placeholder.png"))
    to_pil(dimg25).save(os.path.join(UIT, "steamdeck_25d_1280x800_placeholder.png"))
    # ware grootte: Deck-scherm ±216 ppi, gewone monitor ±96 ppi -> factor 0,444
    fw, fh = 569, 356
    sheet = np.zeros((44 + 40 + fh + 80 + 330, 2 * (fw + 140) + 60, 3)) + np.array([0.11, 0.11, 0.13])
    sheet[:44] = label_bar(sheet.shape[1], "STEAM DECK, WARE GROOTTE", "OP EEN MONITOR VAN ONGEVEER 96 PPI")[:44]
    for i, (im, nm) in enumerate([(dimg2, "A. 2D"), (dimg25, "B. 2.5D")]):
        x0 = 80 + i * (fw + 140)
        y0 = 44 + 40
        # behuizing (eenvoudig)
        sheet[y0 - 22:y0 + fh + 22, x0 - 60:x0 + fw + 60] = np.array([0.20, 0.20, 0.22])
        sheet[y0 - 4:y0 + fh + 4, x0 - 4:x0 + fw + 4] = np.array([0.03, 0.03, 0.03])
        small = np_img(to_pil(im).resize((fw, fh), Image.LANCZOS))
        sheet[y0:y0 + fh, x0:x0 + fw] = small
        draw_text(sheet, nm, x0, y0 + fh + 34, np.array([0.95, 0.92, 0.85]), scale=3)
        # uitsnede 1:1 van het midden (wat het oog ziet als je dichtbij kijkt)
        crop = im[400:700, 380:1000]
        cw = 620
        crop_small = np_img(to_pil(crop).resize((int(cw * 0.444 * 1.6), int(300 * 0.444 * 1.6)), Image.LANCZOS))
        cy = y0 + fh + 70
        hh, ww = crop_small.shape[:2]
        sheet[cy:cy + hh, x0:x0 + ww] = crop_small
        draw_text(sheet, "UITSNEDE, 1.6X WARE GROOTTE", x0, cy + hh + 8, np.array([0.62, 0.60, 0.70]), scale=2)
    to_pil(sheet[: 44 + 40 + fh + 80 + 270]).save(os.path.join(UIT, "steamdeck_ware_grootte_placeholder.png"))

    # personagekaart
    print("render personagekaart ...")
    l2, names = lineup("2d")
    l25, _ = lineup("25d")
    hdr = np.zeros((40, l2.shape[1], 3)) + np.array([0.07, 0.06, 0.10])
    for i, nm in enumerate(names):
        draw_text(hdr, nm, int((96 + i * 192) * 1.5) - text_width(nm, 2) // 2, 14, np.array([0.95, 0.92, 0.85]), 2)
    sheet = np.concatenate([label_bar(l2.shape[1], "PERSONAGEKAART", "BOVEN 2D, ONDER 2.5D, 1.5X"), hdr, l2,
                            label_bar(l2.shape[1], "2.5D"), l25], 0)
    to_pil(sheet).save(os.path.join(UIT, "personagekaart_placeholder.png"))

    # metingen
    print("\nLeesbaarheid: lichtheidscontrast silhouet tegen directe achtergrond (dL*, op 1280x720)")
    print("figuur      | 2D vulling  2D contour | 2.5D vulling  2.5D contour")
    up = lambda m: np.kron(m, np.ones((2, 2))) > 0.5  # noqa: E731
    rows = []
    for nm in ["speler 1", "echo", "speler 2", "vijand"]:
        a = edge_contrast(img2, up(r2["masks"][nm]), 12)
        b = edge_contrast(img25, r25["masks"][nm], 12)
        rows.append((nm, a, b))
        print(f"{nm:11s} | {a[0]:10.1f} {a[1]:11.1f} | {b[0]:12.1f} {b[1]:13.1f}")
    print("\nKleurverschil (dE76) van sleutelkleuren, normaal en bij deuteranopie:")
    for x, y in [("p1_acc", "p2_acc"), ("p1_acc", "en_core"), ("p2_acc", "ink"), ("p1_acc", "lc1")]:
        lab = srgb_to_lab(np.array([C[x], C[y]]))
        labd = srgb_to_lab(deuteranopia(np.array([C[x], C[y]])))
        print(f"  {x} vs {y}: {np.linalg.norm(lab[0]-lab[1]):.0f} -> {np.linalg.norm(labd[0]-labd[1]):.0f}")
    # licht/schaduw: lichtheidsverschil tussen muur in licht en muur in schaduw vlak bij de grens
    for r, im, nm, k in [(r2, img2, "2D", 2), (r25, img25, "2.5D", 1)]:
        lit = (r["lit"] if k == 1 else np.kron(r["lit"], np.ones((2, 2)))) > 0.5
        lab = srgb_to_lab(im)
        band = np.zeros_like(lit)
        band[280:590, 620:900] = True
        figs = np.zeros_like(lit)
        for m in r["masks"].values():
            figs |= ndimage.binary_dilation(m if k == 1 else up(m), iterations=6)
        a_ = lit & ndimage.binary_dilation(~lit, iterations=16) & band & ~figs
        b_ = ~lit & ndimage.binary_dilation(lit, iterations=16) & band & ~figs
        dl = np.median(lab[a_][:, 0]) - np.median(lab[b_][:, 0])
        print(f"laaggrens {nm}: mediaan L* licht {np.median(lab[a_][:, 0]):.1f}, schaduw {np.median(lab[b_][:, 0]):.1f}, dL* {dl:.1f}")
    return rows


if __name__ == "__main__":
    main()
