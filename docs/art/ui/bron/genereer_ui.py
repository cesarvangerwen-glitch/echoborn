"""UI-art Polderlight, T10 deel 2 (#87): HUD-assets, lettertype, previews en metingen.

Eigen werk van de UI Artist. Geen externe assets. Draait vanaf de repo-root:

    python3 docs/art/ui/bron/genereer_ui.py

Schrijft:
  game/assets/ui/font/   Polderletter normaal en groot (.fnt + .png, en .ttf)
  game/assets/ui/hud/    HUD-onderdelen op de interne resolutie (1 px = 1 px bij 640x360)
  game/assets/ui/wereld/ merk + klokring en peilbuis (staan in de wereld, niet in de HUD)
  docs/art/ui/           previews (x2, x3, x4) voor review
en print de metingen van docs/art/ui-stijlgids.md par. 6 en 7.

Maten en gedrag volgen docs/ux/hud-menus.md v0.1.2 en docs/ux/coop.md; kleuren de art bible par. 3 en 6.
"""
import math
import os
import sys

import numpy as np
from PIL import Image

HIER = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HIER)
import polderletter as PL  # noqa: E402

ROOT = os.path.abspath(os.path.join(HIER, "..", "..", "..", ".."))
R5 = os.path.join(ROOT, "docs", "art", "r5-scene")
GAME = os.path.join(ROOT, "game", "assets", "ui")
DOCS = os.path.join(ROOT, "docs", "art", "ui")


# ------------------------------------------------------------------ kleur
def hx(c):
    return np.array([int(c[i:i + 2], 16) for i in (1, 3, 5)], np.uint8)


def srgb_to_lab(rgb):
    rgb = np.asarray(rgb, float)
    a = np.where(rgb <= 0.04045, rgb / 12.92, ((rgb + 0.055) / 1.055) ** 2.4)
    M = np.array([[0.4124, 0.3576, 0.1805], [0.2126, 0.7152, 0.0722], [0.0193, 0.1192, 0.9505]])
    xyz = a @ M.T / np.array([0.9505, 1.0, 1.089])
    f = np.where(xyz > 0.008856, np.cbrt(xyz), 7.787 * xyz + 16 / 116)
    return np.stack([116 * f[..., 1] - 16, 500 * (f[..., 0] - f[..., 1]), 200 * (f[..., 1] - f[..., 2])], -1)


def deuteranopia(rgb):
    """Machado et al. 2009, volle sterkte (zelfde als genereer_r5.py en de wireframes)."""
    rgb = np.asarray(rgb, float)
    lin = np.where(rgb <= 0.04045, rgb / 12.92, ((rgb + 0.055) / 1.055) ** 2.4)
    M = np.array([[0.367322, 0.860646, -0.227968], [0.280085, 0.672501, 0.047413], [-0.011820, 0.042940, 0.968881]])
    o = np.clip(lin @ M.T, 0, 1)
    return np.where(o <= 0.0031308, o * 12.92, 1.055 * o ** (1 / 2.4) - 0.055)


def lab(c):
    return srgb_to_lab(np.asarray(c, float) / 255.0)


def lum(img):
    """Alleen luminantie (L* als grijs), om vorm en waarde te controleren."""
    L = srgb_to_lab(img[..., :3].astype(float) / 255)[..., 0]
    g = np.clip(L / 100 * 255, 0, 255).astype(np.uint8)
    out = img.copy()
    out[..., 0] = out[..., 1] = out[..., 2] = g
    return out


def deut(img):
    out = img.copy()
    out[..., :3] = (deuteranopia(img[..., :3].astype(float) / 255) * 255).round().astype(np.uint8)
    return out


# Palet: alles uit de art bible par. 3 (ramps) en par. 6 (figuurkleuren). Nieuw voor de UI
# (voorstel, review AD): "cyaan licht" #bff4fc, dezelfde kleur als de klokring in de wireframes.
WIT = [hx(c) for c in ("#0e0e1a", "#201f30", "#37344a", "#5b576e", "#817c8a", "#a8a19f", "#cbc2b5", "#ece2cc")]
LUCHT = [hx(c) for c in ("#06060f", "#0c0c1d", "#10132a", "#181c3b", "#21264c", "#2b315e", "#3a3e6d", "#4a4c7c")]
GLOED = [hx(c) for c in ("#4a2a0a", "#764110", "#a45c17", "#cc7e22", "#e9a039", "#fbc058", "#ffdb94", "#fff6d8")]
IJZER = [hx(c) for c in ("#050508", "#0d0d12", "#15151b", "#1f1d26", "#2b2933", "#3a3640", "#504b53", "#6a6268")]
C = {
    "K": hx("#06060f"),          # contour, bijna-zwart (lucht 0)
    "plaat": LUCHT[1],
    "amber_d": hx("#b45c16"), "amber": hx("#f29a26"), "amber_l": hx("#ffd27a"),
    "cyaan_d": hx("#1fb4cc"), "cyaan": hx("#3ee6f4"), "cyaan_l": hx("#e8ffff"), "cyaan_ring": hx("#bff4fc"),
    "p2_lijf": hx("#08080e"), "hatch": hx("#3a1e56"),
    "grijs_rand": hx("#a8c4c8"),
    "vijand": hx("#45091a"), "vijand_kern": hx("#ff475c"),
    "schaduw3": hx("#31164f"),
}
PLAAT_ALFA = 0.66        # hud-menus.md par. 2.3 zegt 62 %; 66 % haalt het meetpunt (stijlgids par. 6, open punt)
KADER_ALFA = 0.78        # logkader en meldingen (wireframes)


# ------------------------------------------------------------------ RGBA-hulp
def doek(w, h):
    return np.zeros((h, w, 4), np.uint8)


def zet(a, y, x, col, alfa=255):
    if 0 <= y < a.shape[0] and 0 <= x < a.shape[1]:
        a[y, x, :3] = col
        a[y, x, 3] = alfa


def vul(a, mask, col, alfa=255, ox=0, oy=0):
    ys, xs = np.nonzero(mask)
    ys, xs = ys + oy, xs + ox
    ok = (ys >= 0) & (ys < a.shape[0]) & (xs >= 0) & (xs < a.shape[1])
    a[ys[ok], xs[ok], :3] = col
    a[ys[ok], xs[ok], 3] = alfa


def rechthoek(a, x, y, w, h, col, alfa=255):
    m = np.zeros(a.shape[:2], bool)
    m[max(0, y):max(0, y + h), max(0, x):max(0, x + w)] = True
    vul(a, m, col, alfa)


def uit_raster(rows, kleuren):
    """Raster van letters -> RGBA; '.' = transparant."""
    h, w = len(rows), max(len(r) for r in rows)
    a = doek(w, h)
    for y, r in enumerate(rows):
        for x, ch in enumerate(r):
            if ch != ".":
                zet(a, y, x, kleuren[ch])
    return a


def rand_van(mask):
    """Buitenste laag van een masker (4-buren)."""
    p = np.pad(mask, 1)
    binnen = p[1:-1, 1:-1] & p[:-2, 1:-1] & p[2:, 1:-1] & p[1:-1, :-2] & p[1:-1, 2:]
    return mask & ~binnen


def ring_om(mask, diag=True):
    """Pixels net buiten een masker (contour van 1 px)."""
    p = np.pad(mask, 1)
    r = p[:-2, 1:-1] | p[2:, 1:-1] | p[1:-1, :-2] | p[1:-1, 2:]
    if diag:
        r |= p[:-2, :-2] | p[:-2, 2:] | p[2:, :-2] | p[2:, 2:]
    return r & ~mask


def schijf(size, r_in, r_out, cx=None, cy=None):
    c = (size - 1) / 2 if cx is None else cx
    cyy = (size - 1) / 2 if cy is None else cy
    yy, xx = np.mgrid[0:size, 0:size]
    d = np.hypot(xx - c, yy - cyy)
    hoek = (np.degrees(np.arctan2(xx - c, -(yy - cyy))) + 360) % 360  # 0 = boven, met de klok mee
    return (d >= r_in) & (d < r_out), hoek


def over(dst, src, x, y):
    """Alpha-composiet van RGBA src op RGB(A) dst, in place."""
    h, w = src.shape[:2]
    H, W = dst.shape[:2]
    x0, y0, x1, y1 = max(0, x), max(0, y), min(W, x + w), min(H, y + h)
    if x1 <= x0 or y1 <= y0:
        return
    s = src[y0 - y:y1 - y, x0 - x:x1 - x].astype(float)
    a = s[..., 3:4] / 255
    d = dst[y0:y1, x0:x1, :3].astype(float)
    dst[y0:y1, x0:x1, :3] = (d * (1 - a) + s[..., :3] * a).round().astype(np.uint8)
    if dst.shape[2] == 4:
        da = dst[y0:y1, x0:x1, 3:4].astype(float) / 255
        dst[y0:y1, x0:x1, 3:4] = ((a + da * (1 - a)) * 255).round().astype(np.uint8)


def strook(frames):
    """Frames naast elkaar (sprite-strook, zelfde maat per frame)."""
    return np.concatenate(frames, 1)


def bewaar(a, *pad):
    p = os.path.join(*pad)
    os.makedirs(os.path.dirname(p), exist_ok=True)
    Image.fromarray(a, "RGBA" if a.shape[2] == 4 else "RGB").save(p, optimize=True)
    GEMAAKT.append((os.path.relpath(p, ROOT), a.shape[1], a.shape[0]))
    return p


def preview(a, naam, schaal):
    im = Image.fromarray(a, "RGBA" if a.shape[2] == 4 else "RGB")
    im = im.resize((im.width * schaal, im.height * schaal), Image.NEAREST)
    p = os.path.join(DOCS, naam)
    os.makedirs(DOCS, exist_ok=True)
    im.save(p, optimize=True)
    GEMAAKT.append((os.path.relpath(p, ROOT), im.width, im.height))


GEMAAKT = []


def tekst(img, s, x, y, col, grootte="normaal", schaduw=True, schaal=1):
    return PL.draw(img, s, x, y, col, grootte, C["K"] if schaduw else None, schaal)


# ================================================================== HUD-onderdelen
# --- 1. Lantaarntje (HUD-01), 7x9
LANT = {
    "vol": ["..KwK..", ".KwWwK.", "KwwwwwK", "Kw565wK", "Kw676wK", "Kw676wK", "Kw454wK", "KwwwwwK", ".KKKKK."],
    "leeg": ["..KdK..", ".KdddK.", "KdddddK", "KdglldK", "KdllldK", "KdllldK", "KdllldK", "KdddddK", ".KKKKK."],
}


def lantaarn(staat="vol"):
    kl = {"K": C["K"], "w": WIT[6], "W": WIT[7], "d": WIT[4], "g": LUCHT[4], "l": LUCHT[3],
          "4": GLOED[4], "5": GLOED[5], "6": GLOED[6], "7": GLOED[7]}
    if staat == "flits":  # treffer: 6 ticks wit, daarna leeg
        kl.update({"w": WIT[7], "4": GLOED[7], "5": GLOED[7], "6": GLOED[7]})
        return uit_raster(LANT["vol"], kl)
    return uit_raster(LANT[staat], kl)


def glinster(frame):
    """Glinstering rond een nieuw lampje (lampglas, WS-08): 13x13, 3 frames, lampje in het midden."""
    a = doek(13, 13)
    pts = {0: [(6, 0), (0, 6), (12, 6)], 1: [(6, 0), (6, 1), (0, 6), (1, 6), (11, 6), (12, 6), (1, 1), (11, 1)],
           2: [(1, 1), (11, 1), (0, 9), (12, 9)]}[frame]
    for x, y in pts:
        zet(a, y, x, GLOED[7] if frame < 2 else GLOED[5])
    return a


# --- 2. Lichtmeter (HUD-02, HUD-03), 84x9 + genees-streep (3 px eronder)
MW, MH = 84, 9


def meter_segment_mask():
    m = np.zeros((MH, MW), bool)
    for i in range(10):
        m[2:7, 2 + i * 8:2 + i * 8 + 7] = True
    return m


def meter_onder():
    a = doek(MW, MH + 4)
    rechthoek(a, 0, 0, MW, MH, C["K"])
    rechthoek(a, 1, 1, MW - 2, 1, WIT[7])            # bovenrand: licht
    rechthoek(a, 1, MH - 2, MW - 2, 1, WIT[5])       # onderrand: schaduwkant
    rechthoek(a, 1, 1, 1, MH - 2, WIT[6])
    rechthoek(a, MW - 2, 1, 1, MH - 2, WIT[6])
    seg = meter_segment_mask()
    vul(a, seg, LUCHT[3])
    for i in range(10):
        rechthoek(a, 2 + i * 8, 2, 7, 1, LUCHT[4])   # glas: bovenste rij iets lichter
        if i < 9:
            rechthoek(a, 2 + i * 8 + 7, 2, 1, 5, C["K"])
    for (x, y) in ((0, 0), (MW - 1, 0), (0, MH - 1), (MW - 1, MH - 1)):
        a[y, x] = 0                                   # afgeronde buis
    # genees-streep bij 30 LP (HUD-03): 1x3 onder de grens, met contour
    gx = 2 + 3 * 8 - 1
    rechthoek(a, gx - 1, MH, 3, 4, C["K"])
    rechthoek(a, gx, MH, 1, 3, WIT[6])
    return a


def meter_vulling(kleur="gloed"):
    a = doek(MW, MH)
    for i in range(10):
        x = 2 + i * 8
        if kleur == "flits":
            rechthoek(a, x, 2, 7, 5, GLOED[7])
            continue
        rechthoek(a, x, 2, 7, 1, GLOED[6])
        rechthoek(a, x, 3, 7, 3, GLOED[5])
        rechthoek(a, x, 6, 7, 1, GLOED[3])
        zet(a, 3, x + 1, GLOED[7])                    # glans
    return a


def meter_kader(kleur):
    """Kader rond 3 segmenten (30 LP): genezen (gloed 7) of te weinig licht (gevel wit 3)."""
    a = doek(26, MH)
    rechthoek(a, 0, 0, 26, 1, kleur)
    rechthoek(a, 0, MH - 1, 26, 1, kleur)
    rechthoek(a, 0, 0, 1, MH, kleur)
    rechthoek(a, 25, 0, 1, MH, kleur)
    return a


def vonk(eigenaar, frame):
    """Vonk op de meter (LM-02) in de kleur van wie het licht verdiende: 7x7, 3 frames."""
    hoofd, licht = (C["amber"], C["amber_l"]) if eigenaar == "amber" else (C["cyaan"], C["cyaan_l"])
    a = doek(7, 7)
    if frame == 0:
        zet(a, 3, 3, licht)
        for d in ((0, 1), (0, -1), (1, 0), (-1, 0)):
            zet(a, 3 + d[0], 3 + d[1], hoofd)
    elif frame == 1:
        zet(a, 3, 3, GLOED[7] if eigenaar == "amber" else C["cyaan_l"])
        for k in (1, 2):
            for d in ((0, 1), (0, -1), (1, 0), (-1, 0)):
                zet(a, 3 + d[0] * k, 3 + d[1] * k, licht if k == 1 else hoofd)
    else:
        for (y, x) in ((0, 3), (6, 3), (3, 0), (3, 6), (1, 1), (5, 5)):
            zet(a, y, x, hoofd)
    return a


def meter_compleet(L, genezen=0.0, te_weinig=False, vonk_op=None, vol_flits=False):
    """Samengesteld beeld zoals de Gameplay Programmer het bouwt (alleen voor previews)."""
    a = meter_onder()
    v = meter_vulling("flits" if vol_flits else "gloed")
    px = 2 + int(round(L / 10.0 * 8))
    v[:, px:] = 0
    over(a, v, 0, 0)
    if genezen > 0 and L >= 30:
        top = px
        start = top - 24
        weg = int(24 * genezen)
        for x in range(start, top):
            if x >= top - weg:
                a[2:7, x, :3] = LUCHT[3]
            else:
                a[2, x, :3] = GLOED[7]
        over(a, meter_kader(GLOED[7]), start - 1, 0)
    if te_weinig:
        over(a, meter_kader(WIT[3]), 1, 0)
    if vonk_op is not None:
        lp, eig = vonk_op
        b = doek(MW + 6, MH + 8)
        over(b, a, 3, 4)
        over(b, vonk(eig, 1), 3 + 2 + int(lp / 10 * 8) - 3, 4 + 1)
        return b
    return a


# --- 3. Echo-icoon (HUD-04), 11x17: silhouet van speler 1 (pet met klep, sjaal, jas)
ECHO_SIL = [
    "...........",
    "....###....",
    "...######..",
    "...####....",
    "...####....",
    "....###....",
    ".######....",
    ".#.#####...",
    "...#####...",
    "...#####...",
    "...#####...",
    "...#####...",
    "...##.##...",
    "...##.##...",
    "...##.##...",
    "..###.###..",
    "...........",
]


def _echo_masks():
    m = np.array([[c == "#" for c in r] for r in ECHO_SIL])
    rand = rand_van(m)
    binnen = m & ~rand
    contour = ring_om(m, diag=False)
    return m, rand, binnen, contour


def echo_icoon(staat="actief", voortgang=1.0, frame=0):
    m, rand, binnen, contour = _echo_masks()
    H, W = m.shape
    a = doek(W, H)
    vul(a, contour, C["K"])
    yy, xx = np.mgrid[0:H, 0:W]
    arcering = binnen & ((yy + xx) % 3 == 0)          # hol: diagonaal om de 3 px (bible par. 6)
    if staat == "actief":
        vul(a, rand, C["amber"])
        vul(a, arcering, C["hatch"])
        zet(a, 3, 5, C["amber_l"])                    # oog
    elif staat in ("leeg", "buiten"):
        # gestippeld silhouet; vult van onder naar boven tot de echo terug is
        vul(a, rand & ((yy + xx) % 2 == 0), WIT[4])
        vul(a, rand & ((yy + xx) % 2 == 1), C["K"])
        rij = H - 1 - int(round((H - 2) * voortgang))
        vul(a, rand & (yy > rij), C["amber"])
        vul(a, arcering & (yy > rij), C["hatch"])
    elif staat == "breken":
        if frame == 0:
            vul(a, rand, GLOED[7])
            vul(a, arcering, C["amber"])
        else:
            # scherven: de rand valt in stukjes uiteen
            a[:] = 0
            stukjes = rand & (((yy * 3 + xx) % (3 + frame)) == 0)
            ys, xs = np.nonzero(stukjes)
            for y, x in zip(ys, xs):
                dx = int(np.sign(x - 5)) * frame
                dy = int(np.sign(y - 8)) * frame
                zet(a, y + dy, x + dx, C["amber"] if frame == 1 else C["amber_d"])
    elif staat == "uit":
        vul(a, rand, WIT[3])
    return a


def echo_pijl():
    """Pijltje naast het echo-icoon bij *Buiten* (E-04a): hij komt door de deur. 5x9."""
    rows = ["K....", "KaK..", "KaaK.", "KaaaK", "KaaaK", "KaaK.", "KaK..", "K....", "....."]
    return uit_raster(rows, {"K": C["K"], "a": C["amber"]})


# --- 4. P2-badge (co-op), 17x17
def badge_ring(kleur, deel=1.0, onder=None):
    a = doek(17, 17)
    ring, hoek = schijf(17, 5.6, 7.6)
    cont, _ = schijf(17, 7.6, 8.6)
    vul(a, cont, C["K"])
    if onder is not None:
        vul(a, ring, onder)
    vul(a, ring & (hoek < 360 * deel + 1e-6), kleur)
    return a


BADGE_KOP = [
    ".................",
    ".................",
    ".................",
    "......ccccc......",   # bol van de brede hoed (alleen de rand licht op)
    ".....cKKKKKc.....",
    ".....cKKKKKc.....",
    "...ccccccccccc...",   # brede rand
    "......KKKKK......",   # gezicht in de schaduw van de rand
    "......KEKEK......",   # ogen wit-cyaan
    "......dKKKd......",
    ".....dKKKKKzz....",   # kraag, sjaalpunt waait opzij
    "....cKKKKKKKc....",   # lange jas, brede schouders
    ".....cKKKKKc.....",
    "......KKKKK......",
    ".................",
    ".................",
    ".................",
]


def badge_kop(weg=False):
    a = doek(17, 17)
    binnen, _ = schijf(17, 0, 5.6)
    vul(a, binnen, C["K"])
    grijs = WIT[3]
    kl = {"c": grijs if weg else C["cyaan"], "d": grijs if weg else C["cyaan_d"],
          "b": grijs if weg else C["cyaan_d"], "z": grijs if weg else C["cyaan_d"],
          "E": WIT[2] if weg else C["cyaan_l"], "K": C["p2_lijf"]}
    over(a, uit_raster(BADGE_KOP, kl), 0, 0)
    return a


def badge(staat="speelt", deel=1.0):
    if staat == "speelt":
        r = badge_ring(C["cyaan"])
    elif staat == "opgelost":
        r = badge_ring(C["cyaan"], deel, onder=WIT[3])
    elif staat == "stoppen":
        r = badge_ring(WIT[7], deel, onder=C["cyaan"])
    elif staat == "weg":
        r = badge_ring(WIT[5], 1.0 - deel, onder=WIT[2])
    over(r, badge_kop(weg=(staat == "weg")), 0, 0)
    return r


def pad_weg():
    """Controller-icoon met '!' (Apparaat weg, CO-08). 15x9, generiek, geen merk."""
    rows = ["..KKKKKKKKKKK..",
            ".KwwwwwwwwwwwK.",
            "KwwKwwwwwwwKwwK",
            "KwKKKwwrwwKwKwK",
            "KwwKwwwrwwwKwwK",
            "KwwwwwwwwwwwwwK",
            "KwwwKKKrKKKwwwK",
            ".KwK.......KwK.",
            "..K.........K.."]
    return uit_raster(rows, {"K": C["K"], "w": WIT[6], "r": GLOED[6]})


def p2_pijl():
    """Cyaan pijl aan de schermrand als P2 buiten beeld is (C-07). 8x13, wijst naar rechts."""
    rows = []
    for i in range(13):
        d = 6 - abs(i - 6)
        rows.append(("K" + "c" * d + "K").ljust(8, "."))
    rows[0] = "K......."
    rows[12] = "K......."
    return uit_raster(rows, {"K": C["K"], "c": C["cyaan"]})


def ring_klein(kleur, deel=1.0, onder=None):
    """Leibandring naast de pijl (60 ticks), 15x15."""
    a = doek(15, 15)
    ring, hoek = schijf(15, 4.6, 6.6)
    cont, _ = schijf(15, 6.6, 7.6)
    cont_i, _ = schijf(15, 3.6, 4.6)
    vul(a, cont | cont_i, C["K"])
    if onder is not None:
        vul(a, ring, onder)
    vul(a, ring & (hoek < 360 * deel + 1e-6), kleur)
    return a


# --- 5. Merk (HUD-05, in de wereld): kern + klokring
def merk_kern(eigenaar, dooft=False):
    """Peilmerk (P1, amber, rond met waterlijn) of sluismerk (P2, cyaan, ruit met verticale streep). 9x9."""
    a = doek(9, 9)
    yy, xx = np.mgrid[0:9, 0:9]
    if eigenaar == "amber":
        d = np.hypot(xx - 4, yy - 4)
        kern, rand = d < 3.6, (d >= 3.6) & (d < 4.7)
        hoofd = C["amber_d"] if dooft else C["amber"]
        lijn = GLOED[4] if dooft else GLOED[7]
        vul(a, rand, C["K"])
        vul(a, kern, hoofd)
        if not dooft:
            vul(a, kern & (yy < 3), C["amber_l"])      # bovenkant vangt licht
        rechthoek(a, 1, 4, 7, 1, lijn)                # waterlijn (peil)
        zet(a, 4, 0, C["K"]); zet(a, 4, 8, C["K"])
    else:
        d = np.abs(xx - 4) + np.abs(yy - 4)
        kern, rand = d <= 3, d == 4
        hoofd = C["cyaan_d"] if dooft else C["cyaan"]
        lijn = C["grijs_rand"] if dooft else C["cyaan_l"]
        vul(a, rand, C["K"])
        vul(a, kern, hoofd)
        rechthoek(a, 4, 1, 1, 7, lijn)                # sluisstreep
    return a


def klokring(eigenaar, kwarten, groot=False):
    """Klokring van 2 px in 4 kwarten (doorsnede 17, groot 25) + contour. Elke carillonslag dooft
    een kwart, met de klok mee vanaf boven: kwart 0 (rechtsboven) dooft eerst."""
    S = 27 if groot else 19
    r_in, r_uit = (10.5, 12.5) if groot else (6.5, 8.5)
    a = doek(S, S)
    ring, hoek = schijf(S, r_in, r_uit)
    cont, _ = schijf(S, r_uit, r_uit + 1.0)
    cont_i, _ = schijf(S, r_in - 1.0, r_in)
    buiten_rij, _ = schijf(S, r_in + 1.0, r_uit)
    vul(a, cont | cont_i, C["K"])
    hoofd, licht = (C["amber"], GLOED[6]) if eigenaar == "amber" else (C["cyaan"], C["cyaan_ring"])
    spleet = 9 if not groot else 6
    for q in range(4):
        deel = ring & (hoek >= q * 90 + spleet) & (hoek < (q + 1) * 90 - spleet)
        brandt = q >= 4 - kwarten
        if brandt:
            vul(a, deel, licht)
            vul(a, deel & buiten_rij, hoofd)
        else:
            vul(a, deel, WIT[2])
        sp = ring & ~deel & (hoek >= q * 90 - spleet) & (hoek < q * 90 + spleet)
        vul(a, sp, C["K"])
    return a


def merk(eigenaar, kwarten, groot=False, dooft=False):
    r = klokring(eigenaar, kwarten, groot)
    S = r.shape[0]
    k = merk_kern(eigenaar, dooft)
    over(r, k, (S - 9) // 2, (S - 9) // 2)
    return r


def boem(eigenaar, frame, groot=False):
    """Ontploffing van het merk op slag 3 (de echo komt): 3 frames. 31x31 (groot 39x39)."""
    S = 39 if groot else 31
    a = doek(S, S)
    hoofd = C["amber"] if eigenaar == "amber" else C["cyaan"]
    licht = GLOED[7] if eigenaar == "amber" else C["cyaan_l"]
    yy, xx = np.mgrid[0:S, 0:S]
    c = (S - 1) / 2
    d = np.hypot(xx - c, yy - c)
    hoek = (np.degrees(np.arctan2(xx - c, -(yy - c))) + 360) % 360
    stralen = ((hoek % 45) < 7) | ((hoek % 45) > 38)
    sch = 1.3 if groot else 1.0
    if frame == 0:
        vul(a, d < 5 * sch, licht)
        vul(a, (d >= 5 * sch) & (d < 7 * sch), hoofd)
        vul(a, stralen & (d >= 7 * sch) & (d < 11 * sch), licht)
    elif frame == 1:
        vul(a, (d >= 7 * sch) & (d < 9 * sch), hoofd)
        vul(a, d < 3 * sch, licht)
        vul(a, stralen & (d >= 10 * sch) & (d < 14 * sch), hoofd)
    else:
        vul(a, stralen & (d >= 13 * sch) & (d < 15 * sch), hoofd)
        vul(a, ((hoek % 90) < 4) & (d >= 9 * sch) & (d < 10 * sch), licht)
    return a


# --- 6. Peilbuis (HUD-06, in de wereld), 9x42 met trapstrepen van 13 breed
PB_W, PB_H = 13, 42


def peilbuis_onder():
    a = doek(PB_W, PB_H)
    x0 = 2
    rechthoek(a, x0, 0, 9, PB_H, C["K"])
    rechthoek(a, x0 + 1, 1, 7, 2, IJZER[6])            # kap boven
    rechthoek(a, x0 + 1, 1, 7, 1, IJZER[7])
    rechthoek(a, x0 + 1, PB_H - 3, 7, 2, IJZER[5])     # voet
    rechthoek(a, x0 + 1, PB_H - 3, 7, 1, IJZER[7])
    rechthoek(a, x0 + 1, 3, 1, PB_H - 6, WIT[7])       # glas, kant naar het licht
    rechthoek(a, x0 + 7, 3, 1, PB_H - 6, WIT[5])
    rechthoek(a, x0 + 2, 3, 5, PB_H - 6, LUCHT[3])
    rechthoek(a, x0 + 2, 3, 1, PB_H - 6, LUCHT[4])
    return a


def peilbuis_vulling(flits=False):
    a = doek(PB_W, PB_H)
    x = 4
    if flits:
        rechthoek(a, x, 3, 5, PB_H - 6, GLOED[7])
        return a
    rechthoek(a, x, 3, 1, PB_H - 6, GLOED[6])
    rechthoek(a, x + 1, 3, 3, PB_H - 6, GLOED[5])
    rechthoek(a, x + 4, 3, 1, PB_H - 6, GLOED[3])
    return a


def peilbuis_streep():
    a = doek(PB_W, 3)
    rechthoek(a, 0, 0, PB_W, 3, C["K"])
    rechthoek(a, 1, 1, PB_W - 2, 1, WIT[6])
    return a


def peilbuis_klem():
    """IJzeren klem voor trap 2 van een bosswijk (LM-03): over de bovenste helft. 13x20."""
    a = doek(PB_W, 20)
    for y in (1, 9, 17):
        rechthoek(a, 0, y - 1, PB_W, 3, C["K"])
        rechthoek(a, 1, y, PB_W - 2, 1, IJZER[6])
        zet(a, y, 1, IJZER[7]); zet(a, y, PB_W - 2, IJZER[7])
    rechthoek(a, 5, 0, 3, 20, C["K"])
    rechthoek(a, 6, 1, 1, 18, IJZER[5])
    for y in (1, 9, 17):
        zet(a, y, 6, IJZER[7])                        # klinknagels
    return a


def peilbuis_compleet(G, trappen=2, klem=False, flits=False):
    a = peilbuis_onder()
    v = peilbuis_vulling(flits)
    binnen = PB_H - 6
    h = int(round(binnen * G / (100.0 * trappen)))
    v[:PB_H - 3 - h] = 0
    over(a, v, 0, 0)
    for k in range(1, trappen):
        y = PB_H - 3 - int(round(binnen * k / trappen))
        over(a, peilbuis_streep(), 0, y - 1)
    if klem:
        over(a, peilbuis_klem(), 0, 2)
    return a


# --- 7. Boss-balk (HUD-09), 240x4 binnen
BB_W = 240


def boss_onder():
    a = doek(BB_W + 2, 6)
    rechthoek(a, 0, 0, BB_W + 2, 6, C["K"])
    rechthoek(a, 1, 0, BB_W, 1, C["vijand_kern"])      # rode bovenrand: zoals elke vijand (bible par. 6)
    rechthoek(a, 1, 1, BB_W, 4, LUCHT[3])
    rechthoek(a, 1, 1, BB_W, 1, LUCHT[4])
    a[0, 0, 3] = a[0, -1, 3] = 0
    return a


def boss_vulling():
    a = doek(BB_W + 2, 6)
    rechthoek(a, 1, 1, BB_W, 1, WIT[7])
    rechthoek(a, 1, 2, BB_W, 2, WIT[6])
    rechthoek(a, 1, 4, BB_W, 1, WIT[4])
    return a


def boss_streep(wankel=False):
    a = doek(3, 10)
    rechthoek(a, 0, 0, 3, 10, C["K"])
    rechthoek(a, 1, 1, 1, 8, GLOED[6] if wankel else WIT[6])
    return a


def boss_compleet(frac, wankel=False):
    a = doek(BB_W + 4, 10)
    over(a, boss_onder(), 1, 2)
    v = boss_vulling()
    v[:, 1 + int(round(BB_W * frac)):] = 0
    over(a, v, 1, 2)
    for f in (0.6, 0.2):
        over(a, boss_streep(wankel and f == 0.2), 1 + 1 + int(BB_W * f) - 1, 0)
    return a


# --- 8. Plaat, logkader en melding (9-slice)
def plaat_9slice():
    a = doek(5, 5)
    rechthoek(a, 0, 0, 5, 5, C["plaat"], int(round(PLAAT_ALFA * 255)))
    for (x, y) in ((0, 0), (4, 0), (0, 4), (4, 4)):
        a[y, x] = 0
    return a


def kader_9slice(rand=None):
    """Logkader en melding: plaat 78 % met een rand van 1 px en klinknagels op de hoeken. 7x7, marge 2."""
    rand = WIT[3] if rand is None else rand
    a = doek(7, 7)
    rechthoek(a, 0, 0, 7, 7, C["plaat"], int(round(KADER_ALFA * 255)))
    rechthoek(a, 0, 0, 7, 1, rand)
    rechthoek(a, 0, 6, 7, 1, rand)
    rechthoek(a, 0, 0, 1, 7, rand)
    rechthoek(a, 6, 0, 1, 7, rand)
    for (x, y) in ((0, 0), (6, 0), (0, 6), (6, 6)):
        zet(a, y, x, WIT[5] if rand is WIT[3] else C["cyaan_l"])   # klinknagel
    rechthoek(a, 1, 1, 5, 1, C["K"], 140)            # binnen-schaduw onder de bovenrand
    return a


def negen(a9, w, h, m=2):
    """9-slice uitrekken (zoals Godot NinePatchRect), voor de previews."""
    H9, W9 = a9.shape[:2]
    out = doek(w, h)
    xs = list(range(m)) + [m] * (w - 2 * m) + list(range(W9 - m, W9))
    ys = list(range(m)) + [m] * (h - 2 * m) + list(range(H9 - m, H9))
    out[:] = a9[np.ix_(ys, xs)]
    return out


# --- 9. Opslaan: tandwiel van het gemaal (4.6), 13x13, 4 frames
def tandwiel(frame):
    S = 13
    a = doek(S, S)
    yy, xx = np.mgrid[0:S, 0:S]
    c = 6
    d = np.hypot(xx - c, yy - c)
    hoek = (np.degrees(np.arctan2(xx - c, -(yy - c))) + 360 + frame * 11.25) % 45
    tand = (hoek < 18) & (d < 6.4)
    lijf = d < 4.6
    gat = d < 1.6
    vorm = (lijf | tand) & ~gat
    vul(a, ring_om(vorm) & ~gat, C["K"])
    vul(a, vorm, WIT[6])
    vul(a, vorm & (yy < 5) & (xx < 7), WIT[7])
    vul(a, vorm & (d < 3.0) & ~gat, WIT[4])
    vul(a, gat, C["K"])
    return a


# ================================================================== HUD samenstellen (previews)
def hud_solo(img, L=50, hp=4, hpmax=5, echo="actief", echo_v=1.0, genezen=0.0, te_weinig=False,
             vonk_op=None, nieuw=False, y0=0):
    breedte = max(hpmax * 9 - 2, MW)
    pl = negen(plaat_9slice(), breedte + 8 + 4 + 11 + 4, 31)
    over(img, pl, 4, 4 + y0)
    for i in range(hpmax):
        over(img, lantaarn("vol" if i < hp else "leeg"), 8 + i * 9, 8 + y0)
    if nieuw:
        over(img, glinster(1), 8 + (hpmax - 1) * 9 - 3, 8 + y0 - 2)
    m = meter_compleet(L, genezen, te_weinig, vonk_op)
    if vonk_op is not None:
        over(img, m, 8 - 3, 20 + y0 - 4)
    else:
        over(img, m, 8, 20 + y0)
    if echo:
        ex = 8 + breedte + 4
        if echo == "actief":
            over(img, echo_icoon("actief"), ex, 8 + y0)
        else:
            over(img, echo_icoon(echo, echo_v), ex, 8 + y0)
            if echo == "buiten":
                over(img, echo_pijl(), ex + 11, 12 + y0)
    return 4 + breedte + 8 + 4 + 11 + 4


def hud_coop(img, L=60, hp=5, hpmax=5, p2="speelt", p2_v=1.0, y0=0):
    hud_solo(img, L=L, hp=hp, hpmax=hpmax, echo=None, y0=y0)
    W = img.shape[1]
    over(img, negen(plaat_9slice(), 25, 25), W - 8 - 17 - 4, 4 + y0)
    over(img, badge(p2, p2_v), W - 8 - 17, 8 + y0)
    if p2 == "weg":
        over(img, pad_weg(), W - 8 - 17 - 4 - 17, 12 + y0)


def logkader(img, kop, r1, r2, groot=False):
    H, W = img.shape[:2]
    w, h = (540, 48) if groot else (360, 32)
    x, y = (W - w) // 2, H - 8 - h
    over(img, negen(kader_9slice(), w, h), x, y)
    g = "groot" if groot else "normaal"
    if groot:
        tekst(img, kop, x + 6, y + 4, GLOED[6], g)
        tekst(img, r1, x + 6, y + 4 + 14, WIT[7], g)
        tekst(img, r2, x + 6, y + 4 + 28, WIT[7], g)
    else:
        tekst(img, kop, x + 6, y + 3, GLOED[6], g)
        tekst(img, r1, x + 6, y + 3 + 9, WIT[7], g)
        tekst(img, r2, x + 6, y + 3 + 18, WIT[7], g)
    return x, y, w, h


def melding(img, regels, rand=None, kleur=None, icoon=None, y_boven=0):
    H, W = img.shape[:2]
    tw = max(PL.text_width(r) for r in regels)
    iw = (icoon.shape[1] + 4) if icoon is not None else 0
    w, h = tw + iw + 12, 6 + 10 * len(regels) + 1
    x, y = W - 8 - w, H - 8 - h - y_boven
    over(img, negen(kader_9slice(rand), w, h), x, y)
    if icoon is not None:
        over(img, icoon, x + 6, y + (h - icoon.shape[0]) // 2)
    for i, r in enumerate(regels):
        tekst(img, r, x + 6 + iw, y + 4 + 10 * i, (kleur if i == 0 and kleur is not None else (WIT[7] if i == 0 else WIT[5])))
    return w, h


def bossbalk(img, naam, frac, wankel=False):
    H, W = img.shape[:2]
    b = boss_compleet(frac, wankel)
    x = (W - b.shape[1]) // 2
    y = H - 8 - b.shape[0]
    tekst(img, naam, x + 2, y - 9, WIT[7])
    over(img, b, x, y)


def laad(naam):
    return np.array(Image.open(os.path.join(R5, naam)).convert("RGB"))


def label(img, s, y=2, kleur=None):
    w = PL.text_width(s) + 8
    x = (img.shape[1] - w) // 2
    img[y:y + 12, x:x + w] = C["K"]
    tekst(img, s, x + 4, y + 2, WIT[7] if kleur is None else kleur, schaduw=False)


def deck_achtergrond(naam):
    """640x400 uit de Deck-render van de R5-scène (1280x800 = x2)."""
    im = Image.open(os.path.join(R5, naam)).convert("RGB")
    return np.array(im.resize((640, 400), Image.NEAREST))


# ================================================================== testteksten (par. 7 stijlgids)
# Testteksten EN/NL om vakken te meten. De echte teksten schrijven de Narrative Designer en de
# Gameplay Programmer (strings.csv). Sleutels uit hud-menus.md par. 6.
VAKKEN = [
    # (vak, breedte binnen in px normaal, [(sleutel, EN, NL), ...])
    ("Logkader, regel (360x32, binnen 348)", 348, [
        ("HUD_LOG_KOP", "Log page 3", "Logbladzijde 3"),
        ("log r1", "The water reached the second step.", "Het water stond tot de tweede trede van de kade."),
        ("log r2", "After that, nobody heard the bell again.", "Daarna hoorde niemand in de wijk de klok nog."),
        ("log r3 (lang, 58 tekens NL)", "The keeper locked the sluice and went home.",
         "De sluiswachter sloot de sluis en liep zonder lamp naar huis."),
    ]),
    ("Melding rechtsonder (voorstel max. 196, binnen 184)", 184, [
        ("HUD_LAMPGLAS", "Lamp glass: +1 life", "Lampglas: +1 leven"),
        ("HUD_P2_JOINED", "P2 joins in", "P2 doet mee"),
        ("HUD_P2_STOP_HOLD", "Hold View to stop", "Houd View vast om te stoppen"),
        ("HUD_P2_LEAVING", "P2 has stopped", "P2 is gestopt"),
        ("HUD_PAD_JOIN_HINT", "Controller 2: press Start to join", "Controller 2: druk op Start om mee te doen"),
        ("HUD_PAD_LOST", "Controller 2 lost", "Controller 2 kwijt"),
    ]),
    ("Boss-naam boven de balk (240)", 240, [
        ("HUD_BOSS_GEMAALMEESTER", "The Pump Master", "De Gemaalmeester"),
    ]),
    ("Menuregel (keuzevak 150, binnen 138)", 138, [
        ("MENU_CONTINUE", "Continue", "Doorgaan"), ("MENU_NEW_GAME", "New game", "Nieuw spel"),
        ("MENU_OPTIONS", "Options", "Opties"), ("MENU_CREDITS", "Credits", "Credits"),
        ("MENU_QUIT", "Quit", "Afsluiten"), ("MENU_RESUME", "Resume", "Verder"),
        ("MENU_LOGBOOK", "Logbook", "Logboek"), ("MENU_P2_LEAVE", "Player 2 leaves", "Speler 2 stopt"),
        ("MENU_TO_TITLE", "Main menu", "Naar hoofdmenu"),
    ]),
    ("Tabbalk opties (5 tabs + 4x16 tussenruimte, binnen 560)", 560, [
        ("tabs", "General  Display  Audio  Controls  Accessibility",
         "Algemeen  Beeld  Geluid  Besturing  Toegankelijkheid"),
    ]),
    ("Optienaam (kolom 44-392, 348)", 348, [
        ("OPT tikken", "Hold or tap", "Vasthouden of tikken"),
        ("OPT trillen", "Countdown also vibrates", "Aftelling ook trillen"),
        ("OPT bijschriften", "Sound captions", "Geluidsbijschriften"),
        ("OPT achtergrond", "Sound in the background", "Geluid op de achtergrond"),
        ("OPT aftelling", "Countdown and marks", "Aftelling en merken"),
        ("OPT kleur", "Player colour profile", "Kleurprofiel spelers"),
    ]),
    ("Optiewaarde met < > (kolom 388-600, binnen 188)", 188, [
        ("waarde venster", "< Full screen >", "< Volledig scherm >"),
        ("waarde kleur", "< Amber / cyan >", "< Amber / cyaan >"),
        ("waarde knoppen", "< Keyboard >", "< Toetsenbord >"),
    ]),
    ("Pauze, rechterkolom (250-632, 382)", 382, [
        ("pauze wijk", "Ward 1.1 The Quay Ward", "Wijk 1.1 De Kadewijk"),
        ("pauze gemaal", "Pumping station: stage 1 of 2", "Gemaal: trap 1 van 2"),
        ("pauze tellers", "Lamp glass 0/1   Log pages 3/7", "Lampglas 0/1   Logbladzijden 3/7"),
        ("MENU_SAVED_AT_PUMP", "Saved at the pumping station", "Opgeslagen bij het gemaal"),
    ]),
    ("Herbinden, kolom Actie (44-196, 152)", 152, [
        ("actie genezen", "Interact (heal)", "Interactie (genezen)"),
        ("actie meedoen", "Join (free device)", "Meedoen (vrij apparaat)"),
        ("actie stoppen", "Stop (hold)", "Stoppen (vasthouden)"),
    ]),
    ("Losse regels (titel, hoofdmenu, rebind)", 300, [
        ("MENU_PRESS_ANY", "Press any button", "Druk op een knop"),
        ("MENU_LANGUAGE_HINT", "Language: English", "Taal: Nederlands"),
        ("MENU_CONFIRM_OVERWRITE", "Overwrite this save?", "Dit spelbestand overschrijven?"),
        ("MENU_PRESS_KEY", "Press a key (Esc cancels)", "Druk op een toets (Esc annuleert)"),
        ("MENU_KEY_TAKEN", "Used by Dash: swap?", "Bezet door Dash: wisselen?"),
        ("MENU_PAUSED_BY", "Paused by P1", "Pauze van P1"),
        ("hoofdmenu 2e speler", "Player 2: press Start", "2e speler: druk op Start"),
    ]),
]


def meet_teksten():
    rijen = []
    for vak, breedte, items in VAKKEN:
        for sleutel, en, nl in items:
            if sleutel == "tabs":
                ew = sum(PL.text_width(t) for t in en.split("  ")) + 16 * 4
                nw = sum(PL.text_width(t) for t in nl.split("  ")) + 16 * 4
                ewg = sum(PL.text_width(t, "groot") for t in en.split("  ")) + 24 * 4
                nwg = sum(PL.text_width(t, "groot") for t in nl.split("  ")) + 24 * 4
            else:
                ew, nw = PL.text_width(en), PL.text_width(nl)
                ewg, nwg = PL.text_width(en, "groot"), PL.text_width(nl, "groot")
            rijen.append((vak, breedte, sleutel, en, nl, ew, nw, nwg))
    return rijen


def tekens_per_regel(breedte, grootte="normaal"):
    """Gemiddelde breedte per teken op lopende NL-tekst -> tekens per regel."""
    proef = ("Het water stond tot de tweede trede van de kade. Daarna hoorde niemand in de wijk "
             "de klok nog. De sluiswachter sloot de sluis en liep zonder lamp naar huis, langs het gemaal.")
    proef_en = ("The water reached the second step of the quay. After that nobody in the ward heard "
                "the bell again. The keeper locked the sluice and walked home without a lamp.")
    nl = PL.text_width(proef, grootte) / len(proef)
    en = PL.text_width(proef_en, grootte) / len(proef_en)
    return breedte / nl, breedte / en, nl, en


# ================================================================== metingen
def metingen(plaat_alfa):
    out = {}
    zones = []
    for naam in ("r5_grijs_640x360.png", "r5_kleur_640x360.png"):
        img = laad(naam)
        zones.append((naam, img, (4, 4, 4 + 111, 4 + 31)))
        zones.append((naam + " co-op", img, (640 - 29, 4, 640 - 4, 29)))
    for naam in ("r5_grijs_deck_1280x800.png", "r5_kleur_deck_1280x800.png"):
        img = deck_achtergrond(naam)
        zones.append((naam, img, (4, 4, 4 + 111, 4 + 31)))
    res = []
    for naam, img, (x0, y0, x1, y1) in zones:
        z = img[y0:y1, x0:x1].reshape(-1, 3).astype(float)
        L = lab(z)[:, 0]
        p = z * (1 - plaat_alfa) + C["plaat"].astype(float) * plaat_alfa
        Lp = lab(p)[:, 0]
        res.append((naam, np.median(L), np.percentile(L, 95), L.max(), np.percentile(Lp, 95), Lp.max()))
    out["zones"] = res
    return out


def contrast_paren():
    paren = [
        ("Meterrand (gevel wit 6) / contour", WIT[6], C["K"]),
        ("Meter: vulling (gloed 5) / leeg segment (lucht 3)", GLOED[5], LUCHT[3]),
        ("Lantaarn vol: rand (wit 6) / plaat", WIT[6], C["plaat"]),
        ("Lantaarn leeg: rand (wit 4) / plaat", WIT[4], C["plaat"]),
        ("Lantaarn: glas vol (gloed 6) / glas leeg (lucht 3)", GLOED[6], LUCHT[3]),
        ("Echo-icoon amber / plaat", C["amber"], C["plaat"]),
        ("Echo leeg: stippel (wit 4) / plaat", WIT[4], C["plaat"]),
        ("P2-badge cyaan / plaat", C["cyaan"], C["plaat"]),
        ("Merk amber (P1) / merk cyaan (P2)", C["amber"], C["cyaan"]),
        ("Klokring amber (gloed 6) / rode vijandkern", GLOED[6], C["vijand_kern"]),
        ("Klokring cyaan licht / cyaan kern", C["cyaan_ring"], C["cyaan"]),
        ("Klokring brandend (gloed 6) / gedoofd (wit 2)", GLOED[6], WIT[2]),
        ("Klokring cyaan brandend / gedoofd (wit 2)", C["cyaan_ring"], WIT[2]),
        ("Merkkern amber / rode vijandkern", C["amber"], C["vijand_kern"]),
        ("Merkkern cyaan / schaduwgeometrie 3", C["cyaan"], C["schaduw3"]),
        ("Boss-vulling (wit 6) / leeg (lucht 3)", WIT[6], LUCHT[3]),
        ("Fasestreep wankel (gloed 6) / normaal (wit 6)", GLOED[6], WIT[6]),
        ("Tekst (wit 7) / kader (plaat 78 %, zwartste)", WIT[7], C["plaat"]),
        ("Kop logkader (gloed 6) / plaat", GLOED[6], C["plaat"]),
    ]
    res = []
    for t, a, b in paren:
        la, lb = lab(a), lab(b)
        da = srgb_to_lab(deuteranopia(np.asarray(a, float) / 255))
        db = srgb_to_lab(deuteranopia(np.asarray(b, float) / 255))
        res.append((t, float(np.linalg.norm(la - lb)), float(np.linalg.norm(da - db)), float(abs(la[0] - lb[0]))))
    return res


# ================================================================== main
def main():
    os.makedirs(GAME, exist_ok=True)
    # ---- lettertype
    fontdir = os.path.join(GAME, "font")
    os.makedirs(fontdir, exist_ok=True)
    finfo = {}
    for g in ("normaal", "groot"):
        n, atlas, lijn, base = PL.export_bmfont(os.path.join(fontdir, "polderletter_%s.png" % g),
                                                os.path.join(fontdir, "polderletter_%s.fnt" % g), g)
        PL.export_ttf(os.path.join(fontdir, "polderletter_%s.ttf" % g), g)
        finfo[g] = (n, atlas, lijn, base)
        for ext in ("png", "fnt", "ttf"):
            p = os.path.join(fontdir, "polderletter_%s.%s" % (g, ext))
            GEMAAKT.append((os.path.relpath(p, ROOT), 0, 0))

    # ---- HUD
    hud = os.path.join(GAME, "hud")
    bewaar(strook([lantaarn("vol"), lantaarn("leeg"), lantaarn("flits")]), hud, "lantaarn_7x9_vol_leeg_flits.png")
    bewaar(lantaarn("vol"), hud, "lantaarn_vol.png")
    bewaar(lantaarn("leeg"), hud, "lantaarn_leeg.png")
    bewaar(strook([glinster(i) for i in range(3)]), hud, "lantaarn_glinster_13x13_3f.png")
    bewaar(meter_onder(), hud, "meter_onder.png")
    bewaar(meter_vulling(), hud, "meter_vulling.png")
    bewaar(meter_vulling("flits"), hud, "meter_vol_flits.png")
    bewaar(meter_kader(GLOED[7]), hud, "meter_genees_kader.png")
    bewaar(meter_kader(WIT[3]), hud, "meter_te_weinig_kader.png")
    bewaar(strook([vonk("amber", i) for i in range(3)]), hud, "vonk_amber_7x7_3f.png")
    bewaar(strook([vonk("cyaan", i) for i in range(3)]), hud, "vonk_cyaan_7x7_3f.png")
    bewaar(echo_icoon("actief"), hud, "echo_actief.png")
    bewaar(echo_icoon("uit"), hud, "echo_uit.png")
    bewaar(strook([echo_icoon("leeg", i / 15) for i in range(16)]), hud, "echo_leeg_vullen_11x17_16f.png")
    bewaar(strook([echo_icoon("breken", frame=i) for i in range(3)]), hud, "echo_breken_11x17_3f.png")
    bewaar(echo_pijl(), hud, "echo_pijl_buiten.png")
    bewaar(badge_kop(), hud, "p2_badge_kop.png")
    bewaar(badge_kop(weg=True), hud, "p2_badge_kop_weg.png")
    bewaar(badge_ring(C["cyaan"]), hud, "p2_badge_ring_cyaan.png")
    bewaar(badge_ring(WIT[3]), hud, "p2_badge_ring_grijs.png")
    bewaar(badge_ring(WIT[7]), hud, "p2_badge_ring_wit.png")
    bewaar(badge_ring(WIT[5]), hud, "p2_badge_ring_weg.png")
    for st in ("opgelost", "stoppen", "weg"):
        bewaar(strook([badge(st, i / 15) for i in range(16)]), hud, "p2_badge_%s_17x17_16f.png" % st)
    bewaar(badge("speelt"), hud, "p2_badge_speelt.png")
    bewaar(pad_weg(), hud, "pad_weg.png")
    bewaar(p2_pijl(), hud, "p2_pijl_rand.png")
    bewaar(ring_klein(C["cyaan"]), hud, "p2_leiband_ring_cyaan.png")
    bewaar(ring_klein(WIT[3]), hud, "p2_leiband_ring_onder.png")
    bewaar(strook([ring_klein(C["cyaan"], 1 - i / 15, WIT[3]) for i in range(16)]), hud, "p2_leiband_15x15_16f.png")
    bewaar(boss_onder(), hud, "boss_balk_onder.png")
    bewaar(boss_vulling(), hud, "boss_balk_vulling.png")
    bewaar(boss_streep(), hud, "boss_fasestreep.png")
    bewaar(boss_streep(True), hud, "boss_fasestreep_wankel.png")
    bewaar(plaat_9slice(), hud, "plaat_9slice.png")
    bewaar(kader_9slice(), hud, "kader_9slice.png")
    bewaar(kader_9slice(C["cyaan_d"]), hud, "kader_9slice_cyaan.png")
    bewaar(strook([tandwiel(i) for i in range(4)]), hud, "opslaan_tandwiel_13x13_4f.png")

    # ---- wereld (staat aan het object, niet in de HUD)
    wd = os.path.join(GAME, "wereld")
    bewaar(merk_kern("amber"), wd, "merk_kern_peil_amber.png")
    bewaar(merk_kern("amber", True), wd, "merk_kern_peil_amber_dooft.png")
    bewaar(merk_kern("cyaan"), wd, "merk_kern_sluis_cyaan.png")
    bewaar(merk_kern("cyaan", True), wd, "merk_kern_sluis_cyaan_dooft.png")
    for e in ("amber", "cyaan"):
        bewaar(strook([klokring(e, k) for k in (4, 3, 2, 1, 0)]), wd, "klokring_%s_19x19_5f.png" % e)
        bewaar(strook([klokring(e, k, True) for k in (4, 3, 2, 1, 0)]), wd, "klokring_%s_groot_27x27_5f.png" % e)
        bewaar(strook([boem(e, i) for i in range(3)]), wd, "merk_boem_%s_31x31_3f.png" % e)
        bewaar(strook([boem(e, i, True) for i in range(3)]), wd, "merk_boem_%s_groot_39x39_3f.png" % e)
    bewaar(peilbuis_onder(), wd, "peilbuis_onder.png")
    bewaar(peilbuis_vulling(), wd, "peilbuis_vulling.png")
    bewaar(peilbuis_vulling(True), wd, "peilbuis_flits.png")
    bewaar(peilbuis_streep(), wd, "peilbuis_trapstreep.png")
    bewaar(peilbuis_klem(), wd, "peilbuis_klem.png")

    previews()
    rapport(finfo)


# ================================================================== previews
def previews():
    # A. HUD solo, grijs en kleur, op ware grootte en x2
    g, k = laad("r5_grijs_640x360.png"), laad("r5_kleur_640x360.png")
    for img in (g, k):
        hud_solo(img, L=50, hp=4, hpmax=5, echo="actief")
        logkader(img, "Logbladzijde 3", "Het water stond tot de tweede trede van de kade.",
                 "Daarna hoorde niemand in de wijk de klok nog.")
    preview(np.concatenate([g, k], 0), "hud_solo_grijs_kleur_x2.png", 2)
    k3 = laad("r5_kleur_640x360.png")
    hud_solo(k3, L=70, hp=5, hpmax=6, echo="actief")
    preview(k3, "hud_solo_kleur_1920x1080_x3.png", 3)

    # B. Co-op: P2-badge, merken in de wereld, melding
    c = laad("r5_kleur_640x360.png")
    hud_coop(c, L=60, hp=4)
    over(c, merk("amber", 3), 300 - 9, 250 - 9)
    over(c, merk("cyaan", 2), 360 - 9, 236 - 9)
    melding(c, ["P2 doet mee", "Houd View vast om te stoppen"], rand=C["cyaan_d"], kleur=C["cyaan"])
    c2 = laad("r5_grijs_640x360.png")
    hud_coop(c2, L=20, hp=2, p2="opgelost", p2_v=0.5)
    over(c2, p2_pijl(), 640 - 8 - 8, 200)
    over(c2, ring_klein(C["cyaan"], 0.4, WIT[3]), 640 - 8 - 8 - 18, 199)
    melding(c2, ["Controller 2 kwijt"], icoon=pad_weg())
    preview(np.concatenate([c, c2], 0), "hud_coop_kleur_grijs_x2.png", 2)

    # C. Steam Deck 640x400: HUD aan de schermrand, in de 16:10-band (HUD-M1)
    d = deck_achtergrond("r5_kleur_deck_1280x800.png")
    hud_solo(d, L=50, hp=4, hpmax=5, echo="leeg", echo_v=0.6)
    melding(d, ["Lampglas: +1 leven"])
    preview(d, "hud_deck_640x400_x2.png", 2)

    # D. Boss-balk en logkader groot
    b = laad("r5_kleur_640x360.png")
    hud_solo(b, L=30, hp=3, hpmax=5, echo="actief")
    bossbalk(b, "De Gemaalmeester", 0.19, wankel=True)
    lg = laad("r5_grijs_640x360.png")
    hud_solo(lg, L=40, hp=5, hpmax=5)
    logkader(lg, "Logbladzijde 3", "Het water stond tot de tweede trede van de kade.",
             "Daarna hoorde niemand in de wijk de klok nog.", groot=True)
    preview(np.concatenate([b, lg], 0), "hud_boss_en_logkader_groot_x2.png", 2)

    # E. Elementenblad x4
    preview(elementenblad(), "hud_elementen_x4.png", 4)
    # F. Merk en klokring: normaal, alleen luminantie, deuteranopie
    m = merkblad()
    preview(np.concatenate([m, lum(m), deut(m)], 0), "merk_klokring_x4.png", 4)
    # G. Lettertype
    preview(fontblad(), "polderletter_specimen_x3.png", 3)


def elementenblad():
    W, H = 330, 250
    a = np.zeros((H, W, 3), np.uint8)
    a[:] = LUCHT[2]
    over(a, negen(plaat_9slice(), W, H), 0, 0)

    def kop(s, x, y):
        tekst(a, s, x, y, GLOED[6])

    def onder(s, x, y):
        tekst(a, s, x, y, WIT[5], schaduw=False)

    kop("Lantaarntje 7x9", 6, 4)
    for i, st in enumerate(("vol", "leeg", "flits")):
        over(a, lantaarn(st), 8 + i * 22, 16)
        onder(st, 6 + i * 22, 28)
    over(a, glinster(1), 70, 14)
    over(a, lantaarn("vol"), 73, 16)
    onder("nieuw", 70, 28)

    kop("Lichtmeter 84x9 + genees-streep", 100, 4)
    for i, (L, opt, t) in enumerate(((100, {}, "vol"), (50, {}, "50"), (50, {"genezen": 0.5}, "genezen"),
                                     (20, {"te_weinig": True}, "te weinig"))):
        over(a, meter_compleet(L, **opt), 100, 16 + i * 16)
        onder(t, 190, 18 + i * 16)
    over(a, meter_compleet(70, vonk_op=(70, "cyaan")), 97, 78)
    onder("vonk P2", 190, 84)
    for i in range(3):
        over(a, vonk("amber", i), 240 + i * 10, 18)
        over(a, vonk("cyaan", i), 240 + i * 10, 28)

    kop("Echo-icoon 11x17", 6, 104)
    st = [("actief", 1), ("leeg", 0.0), ("leeg", 0.5), ("buiten", 0.7), ("breken", 0), ("uit", 1)]
    for i, (s, v) in enumerate(st):
        x = 8 + i * 18
        if s == "breken":
            over(a, echo_icoon("breken", frame=1), x, 116)
        else:
            over(a, echo_icoon(s, v), x, 116)
        if s == "buiten":
            over(a, echo_pijl(), x + 11, 120)
    onder("act. leeg 50% buit. brk uit", 6, 136)

    kop("P2-badge 17x17", 130, 104)
    for i, (s, v) in enumerate((("speelt", 1), ("opgelost", 0.5), ("stoppen", 0.6), ("weg", 0.3))):
        over(a, badge(s, v), 132 + i * 22, 116)
    over(a, pad_weg(), 222, 120)
    onder("speelt  opgel.  stop  weg", 130, 136)
    over(a, p2_pijl(), 300, 112)
    over(a, ring_klein(C["cyaan"], 0.4, WIT[3]), 282, 111)

    kop("Peilbuis 9x42", 6, 150)
    for i, (G, kl, fl) in enumerate(((30, False, False), (100, False, False), (100, True, False), (100, False, True))):
        over(a, peilbuis_compleet(G, 2, kl, fl), 8 + i * 18, 162)
    kop("Boss-balk 240x4", 84, 150)
    over(a, boss_compleet(0.75), 84, 164)
    over(a, boss_compleet(0.19, True), 84, 180)
    onder("normaal / Wankel (streep 20 % gloed 6)", 84, 192)
    kop("Opslaan", 84, 208)
    for i in range(4):
        over(a, tandwiel(i), 84 + i * 16, 220)
    kop("Kader", 160, 208)
    over(a, negen(kader_9slice(), 60, 20), 160, 220)
    over(a, negen(kader_9slice(C["cyaan_d"]), 70, 20), 226, 220)
    tekst(a, "Lampglas", 166, 226, WIT[7])
    tekst(a, "P2 doet mee", 232, 226, C["cyaan"])
    return a


def merkblad():
    W, H = 330, 96
    a = np.zeros((H, W, 3), np.uint8)
    a[:] = LUCHT[2]
    # schaduwgeometrie als ondergrond voor de helft (merken staan vaak op schaduw)
    a[:, W // 2:] = C["schaduw3"]
    momenten = [("gezet", 4, False), ("slag 1", 3, False), ("slag 2", 2, False), ("slag 3", None, False),
                ("geen echo", 1, False), ("slag 4", 0, False), ("dooft", 0, True)]
    for r, e in enumerate(("amber", "cyaan")):
        for i, (t, kw, df) in enumerate(momenten):
            x, y = 6 + i * 23, 6 + r * 44
            if kw is None:
                over(a, boem(e, 0), x - 6, y - 6)
            else:
                over(a, merk(e, kw, dooft=df), x, y)
        over(a, merk(e, 2, groot=True), 172, 2 + r * 44)
        over(a, boem(e, 1), 200, r * 44 - 4)
        over(a, boem(e, 2), 232, r * 44 - 4)
    for i, t in enumerate(("gezet", "s1", "s2", "s3", "s3*", "s4", "uit")):
        tekst(a, t, 6 + i * 23 + (19 - PL.text_width(t)) // 2, 86, WIT[5], schaduw=False)
    tekst(a, "groot 25", 270, 12, WIT[6])
    tekst(a, "boem 2-3", 270, 24, WIT[6])
    return a


def fontblad():
    W, H = 420, 118
    a = np.zeros((H, W, 3), np.uint8)
    a[:] = LUCHT[1]
    y = 4
    tekst(a, "Polderletter normaal (hoofdletter 7 px) en groot (10 px). Eigen werk.", 4, y, GLOED[6]); y += 14
    for s in ("ABCDEFGHIJKLMNOPQRSTUVWXYZ abcdefghijklmnopqrstuvwxyz 0123456789",
              "ÀÁÂÄÅ àáâäå ÈÉÊË èéêë ÏÎ ïî ÖÓÔ öóô ÜÚÛ üúû Çç Ññ ß Æ æ Ø ø",
              ".,:;!?¡¿ -–— ‘’ “” «» () [] / + = % & € © ° · × …",
              "Toegankelijkheid · Accessibility · Logbladzijde 3 · Speler 2 stopt"):
        tekst(a, s, 4, y, WIT[7]); y += 11
    y += 4
    for s in ("Het water stond tot de tweede trede van de kade.",
              "Tekstgrootte: groot · Geluidsbijschriften · België, café, ruïne"):
        tekst(a, s, 4, y, WIT[7], "groot"); y += 15
    y += 2
    tekst(a, "Titel x2", 4, y, WIT[7], schaal=2)
    tekst(a, "Pauze", 110, y, GLOED[6], schaal=2)
    return a


# ================================================================== rapport
def rapport(finfo):
    print("Gemaakt:")
    for p, w, h in GEMAAKT:
        print("  ", p, ("%dx%d" % (w, h)) if w else "")
    for g, (n, atlas, lijn, base) in finfo.items():
        print("Polderletter %s: %d tekens, atlas %dx%d, regelhoogte %d, basislijn %d" % (g, n, atlas[0], atlas[1], lijn, base))

    print("\nMeetpunt: achtergrond in de HUD-zone (L*), mediaan / p95 / max; met plaat p95 / max")
    Lrand = lab(WIT[6])[0]
    for alfa in (PLAAT_ALFA,):
        m = metingen(alfa)
        for naam, med, p95, mx, pp95, pmx in m["zones"]:
            print("  %-36s %5.1f %5.1f %5.1f | %5.1f %5.1f  -> dL* meterrand %5.1f" % (naam, med, p95, mx, pp95, pmx, Lrand - pmx))
    print("  L* meterrand (wit 6) %.1f, bovenrand (wit 7) %.1f, contour %.1f" % (Lrand, lab(WIT[7])[0], lab(C["K"])[0]))
    for alfa in (0.62, 0.64, 0.66, 0.70):
        mx = max(z[5] for z in metingen(alfa)["zones"])
        print("  plaat %.2f: helderste pixel %.1f, dL* meterrand %.1f" % (alfa, mx, Lrand - mx))

    print("\nContrastparen (dE76 normaal / deuteranopie / dL*):")
    for t, a, b, l in contrast_paren():
        print("  %-52s %6.1f %6.1f %6.1f" % (t, a, b, l))

    print("\nTekstmeting (px, Polderletter normaal; groot = 1,5x-vak):")
    for vak, br, sl, en, nl, ew, nw, nwg in meet_teksten():
        ok = "past" if nw <= br else "PAST NIET"
        okg = "past" if nwg <= int(br * 1.5) else "PAST NIET"
        print("  %-48s %-26s EN %3d  NL %3d (%+4.0f%%)  vak %3d  %-9s | groot NL %3d / %3d %s"
              % (vak[:48], sl[:26], ew, nw, (nw / ew - 1) * 100 if ew else 0, br, ok, nwg, int(br * 1.5), okg))
    for br, g in ((348, "normaal"), (528, "groot")):
        tn, te, pn, pe = tekens_per_regel(br, g)
        print("  logregel %d px (%s): %.0f tekens NL (%.2f px/teken), %.0f tekens EN (%.2f px/teken)" % (br, g, tn, pn, te, pe))
    tn, te, pn, pe = tekens_per_regel(258)
    print("  EN-regel 258 px (348/1,35): %.0f tekens EN" % te)


if __name__ == "__main__":
    main()
