"""Wireframes voor T10 (UX Designer, #87): HUD, merk-aftelling, menu's, co-op.

Alles is placeholder (`_placeholder` in de naam): de vormen, maten en plekken
zijn de spec; de eind-art maakt de UI Artist. Getekend op de interne resolutie
(640x360 pc, 640x400 Steam Deck) en daarna alleen met nearest neighbour
vergroot (x2 = 1280x720/800, x4 voor detailbladen).

Achtergronden: de R5-scene van de Art Director (docs/art/r5-scene), zodat de
HUD getoetst wordt op het echte palet, in grijs en in kleur.
Tekst: het eigen 5x7-pixelfont van de Art Director (alleen hoofdletters);
het echte lettertype kiest de UI Artist (met licentie in docs/licenties.md).

Draaien vanaf de repo-root:  python3 docs/ux/wireframes/bron/genereer_wireframes.py
Het script print ook de metingen (dL*, dE76, deuteranopie) voor
docs/ux/hud-menus.md par. 2.3.
"""
import math
import os
import sys

import numpy as np
from PIL import Image

HIER = os.path.dirname(os.path.abspath(__file__))
UIT = os.path.dirname(HIER)
ROOT = os.path.abspath(os.path.join(HIER, "..", "..", "..", ".."))
sys.path.insert(0, os.path.join(ROOT, "docs", "art", "stijltests", "bron"))
from pixelfont import draw_text, text_width  # noqa: E402

R5 = os.path.join(ROOT, "docs", "art", "r5-scene")


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
    """Machado et al. 2009, volle sterkte (zelfde als genereer_r5.py)."""
    rgb = np.asarray(rgb, float)
    lin = np.where(rgb <= 0.04045, rgb / 12.92, ((rgb + 0.055) / 1.055) ** 2.4)
    M = np.array([[0.367322, 0.860646, -0.227968], [0.280085, 0.672501, 0.047413], [-0.011820, 0.042940, 0.968881]])
    o = np.clip(lin @ M.T, 0, 1)
    return np.where(o <= 0.0031308, o * 12.92, 1.055 * o ** (1 / 2.4) - 0.055)


def grijs(img):
    """Grijze toestand van de bible (chroma 6 %, L x 0,86) benaderd: luminantie x 0,86."""
    f = img.astype(float) / 255
    y = (f * np.array([0.2126, 0.7152, 0.0722])).sum(-1, keepdims=True) * 0.86
    return (np.repeat(y, 3, -1) * 255).astype(np.uint8)


def lab(c):
    return srgb_to_lab(np.asarray(c, float) / 255.0)


# Palet: uit de art bible par. 3 en 6 (figuren), plus twee wireframe-kleuren.
C = {
    "zwart": hx("#06060f"),       # buitencontour (bijna-zwart)
    "plaat": hx("#0c0c1d"),       # HUD-plaat (lucht tint 1), half doorzichtig
    "kader": hx("#cbc2b5"),       # gevel wit tint 6: rand van meter en lampjes
    "kader_d": hx("#5b576e"),     # gevel wit tint 3
    "leeg": hx("#181c3b"),        # lucht tint 3: leeg segment
    "gloed": [hx(c) for c in ("#4a2a0a", "#764110", "#a45c17", "#cc7e22", "#e9a039", "#fbc058", "#ffdb94", "#fff6d8")],
    "amber": hx("#f29a26"), "amber_d": hx("#b45c16"), "amber_l": hx("#ffd27a"),
    "cyaan": hx("#3ee6f4"), "cyaan_d": hx("#1fb4cc"), "cyaan_l": hx("#e8ffff"),
    "p2_lijf": hx("#08080e"),
    "hatch": hx("#3a1e56"),
    "vijand": hx("#45091a"), "vijand_d": hx("#210509"), "vijand_kern": hx("#ff475c"),
    "schaduw": hx("#31164f"),
    "tekst": hx("#ece2cc"),       # gevel wit tint 7
    "tekst_d": hx("#817c8a"),
    # alleen voor wireframes, niet in de game:
    "wf": hx("#8d8787"), "wf_d": hx("#37344a"), "wf_bg": hx("#10132a"),
    "noot": hx("#ff4fd8"),
}


# ------------------------------------------------------------------ tekenen
def rect(img, x, y, w, h, col, alpha=1.0):
    h0, w0 = img.shape[:2]
    x1, y1 = max(0, x), max(0, y)
    x2, y2 = min(w0, x + w), min(h0, y + h)
    if x2 <= x1 or y2 <= y1:
        return
    if alpha >= 1.0:
        img[y1:y2, x1:x2] = col
    else:
        img[y1:y2, x1:x2] = (img[y1:y2, x1:x2] * (1 - alpha) + np.asarray(col) * alpha).astype(np.uint8)


def frame(img, x, y, w, h, col, t=1):
    rect(img, x, y, w, t, col)
    rect(img, x, y + h - t, w, t, col)
    rect(img, x, y, t, h, col)
    rect(img, x + w - t, y, t, h, col)


def dashed(img, x, y, w, h, col, step=4):
    for i in range(x, x + w, step):
        rect(img, i, y, 2, 1, col)
        rect(img, i, y + h - 1, 2, 1, col)
    for j in range(y, y + h, step):
        rect(img, x, j, 1, 2, col)
        rect(img, x + w - 1, j, 1, 2, col)


def txt(img, s, x, y, col, scale=1, schaduw=True):
    if schaduw:
        draw_text(img, s, x + scale, y + scale, C["zwart"], scale)
    draw_text(img, s, x, y, col, scale)
    return text_width(s, scale)


def noot(img, n, x, y):
    """Genummerde notitie (magenta), verwijst naar de tabellen in hud-menus.md."""
    s = str(n)
    w = text_width(s, 1) + 4
    rect(img, x, y, w, 11, C["zwart"])
    rect(img, x + 1, y + 1, w - 2, 9, C["noot"])
    draw_text(img, s, x + 2, y + 2, C["zwart"], 1)


def disc_mask(r_in, r_out, size):
    c = (size - 1) / 2
    yy, xx = np.mgrid[0:size, 0:size]
    d = np.hypot(xx - c, yy - c)
    return (d >= r_in) & (d < r_out), xx - c, yy - c


def paint(img, mask, x, y, col):
    h, w = mask.shape
    ys, xs = np.nonzero(mask)
    ys, xs = ys + y, xs + x
    ok = (ys >= 0) & (ys < img.shape[0]) & (xs >= 0) & (xs < img.shape[1])
    img[ys[ok], xs[ok]] = col


# ------------------------------------------------------------------ HUD-onderdelen
def lampje(img, x, y, vol, nieuw=False):
    """Levenspunt (7x9): een klein lantaarntje. Vol = gloed, leeg = alleen rand."""
    vorm = ["0111110",
            "1000001",
            "1022201",
            "1023201",
            "1023201",
            "1022201",
            "1000001",
            "0111110",
            "0011100"]
    for r, row in enumerate(vorm):
        for c, v in enumerate(row):
            if v == "1":
                img[y + r, x + c] = C["kader"] if vol or nieuw else C["kader_d"]
            elif v == "0" and (r in (0, 7, 8)):
                continue
            elif v == "2":
                img[y + r, x + c] = C["gloed"][5] if vol else C["leeg"]
            elif v == "3":
                img[y + r, x + c] = C["gloed"][7] if vol else C["leeg"]
            elif v == "0":
                img[y + r, x + c] = C["zwart"]
    if nieuw:
        for dx, dy in ((-2, 3), (8, 3), (3, -2)):
            rect(img, x + dx, y + dy, 1, 1, C["gloed"][7])


METER_X, METER_Y = 8, 21


def lichtmeter(img, x, y, L, genezen=0.0, toevoeging=None, trillen=False):
    """Lichtmeter 84x9: 10 segmenten van 10 LP (= 1 pompslag, LM-03).

    genezen: 0..1, voortgang van 45 ticks INTERACTIE vasthouden (LM-07): de
    bovenste 3 gevulde segmenten (30 LP) lopen leeg van rechts naar links.
    toevoeging: (van_LP, kleur) toont een vonk op het segment dat net vol liep.
    """
    rect(img, x, y, 84, 9, C["zwart"])
    frame(img, x + 1, y + 1, 82, 7, C["kader"])
    vol_seg = L / 10.0
    for i in range(10):
        sx = x + 2 + i * 8
        rect(img, sx, y + 2, 7, 5, C["leeg"])
        f = min(1.0, max(0.0, vol_seg - i))
        if f > 0:
            pw = max(1, int(round(7 * f)))
            rect(img, sx, y + 2, pw, 1, C["gloed"][6])
            rect(img, sx, y + 3, pw, 3, C["gloed"][5])
            rect(img, sx, y + 6, pw, 1, C["gloed"][3])
        if i < 9:
            rect(img, sx + 7, y + 2, 1, 5, C["zwart"])
    if genezen > 0 and L >= 30:
        # het deel dat het genezen kost: 30 LP vanaf de top, knippert licht op en loopt leeg
        top = x + 2 + int(L / 10.0 * 8)
        start = top - 24
        weg = int(24 * genezen)
        for px in range(start, top):
            if px >= top - weg:
                rect(img, px, y + 2, 1, 5, C["leeg"])
            else:
                rect(img, px, y + 2, 1, 1, C["gloed"][7])
        frame(img, start - 1, y, top - start + 2, 9, C["gloed"][7])
    if trillen:
        # te weinig licht om te genezen: de drie segmenten vanaf de 30-streep flitsen donker
        frame(img, x + 2, y + 1, 24, 7, C["kader_d"])
    # streep bij 30 LP: genoeg om te genezen (LM-07)
    rect(img, x + 2 + 3 * 8 - 1, y + 9, 1, 3, C["kader"])
    rect(img, x + 2 + 3 * 8 - 1, y + 12, 1, 1, C["zwart"])
    if toevoeging is not None:
        lp, kleur = toevoeging
        sx = x + 2 + int(lp / 10.0 * 8)
        for dx, dy in ((0, -3), (0, 11), (-3, 4), (3, 4)):
            rect(img, sx + dx, y + dy, 1, 2 if dy in (-3, 11) else 1, kleur)


def echo_icoon(img, x, y, staat, voortgang=1.0):
    """Echo-indicator (11x17), solo. staat: actief, leeg, breken, buiten, uit."""
    sil = ["00011100000",
           "00111110000",
           "00111110000",
           "00011100000",
           "00111111000",
           "01111111100",
           "01111111110",
           "01111111000",
           "01111111000",
           "00111111000",
           "00111111000",
           "00111111000",
           "00110011000",
           "00110011000",
           "00110011000",
           "01110011100",
           "00000000000"]
    m = np.array([[c == "1" for c in r] for r in sil])
    rand = np.zeros_like(m)
    for dy, dx in ((0, 1), (0, -1), (1, 0), (-1, 0)):
        rand |= np.roll(np.roll(m, dy, 0), dx, 1) & ~m
    binnen = m & ~(np.roll(m, 1, 0) & np.roll(m, -1, 0) & np.roll(m, 1, 1) & np.roll(m, -1, 1))
    kern = m & ~binnen
    H = m.shape[0]
    for r in range(H):
        for c in range(m.shape[1]):
            px, py = x + c, y + r
            if rand[r, c]:
                img[py, px] = C["zwart"]
            elif binnen[r, c]:
                if staat == "actief":
                    img[py, px] = C["amber"]
                elif staat in ("leeg", "buiten"):
                    # gestippelde rand; vult van onder op naarmate de echo terugkomt
                    gevuld = (H - r) / H <= voortgang
                    img[py, px] = C["amber"] if gevuld else (C["kader_d"] if (r + c) % 2 else C["zwart"])
                elif staat == "breken":
                    img[py, px] = C["gloed"][7] if (r * 3 + c) % 4 == 0 else C["zwart"]
                elif staat == "uit":
                    img[py, px] = C["kader_d"]
            elif kern[r, c]:
                if staat == "actief" and (r + c) % 3 == 0:
                    img[py, px] = C["hatch"]
    if staat == "actief":
        img[y + 2, x + 5] = C["amber_l"]
    if staat == "buiten":
        # pijltje: de echo komt door de deur
        for i in range(3):
            rect(img, x + 12 + i, y + 6 + i, 1, 5 - 2 * i, C["amber"])


def p2_badge(img, x, y, staat, voortgang=1.0, label=True):
    """P2-badge (17x17) rechtsboven in co-op: ring in eigenaarskleur."""
    ring, dx, dy = disc_mask(6.0, 8.5, 17)
    rand_buiten, _, _ = disc_mask(8.5, 9.5, 17)
    hoek = (np.degrees(np.arctan2(dx, -dy)) + 360) % 360  # 0 = boven, met de klok mee
    paint(img, rand_buiten, x, y, C["zwart"])
    if staat == "speelt":
        paint(img, ring, x, y, C["cyaan"])
    elif staat in ("opgelost", "weg"):
        paint(img, ring, x, y, C["kader_d"])
        paint(img, ring & (hoek < 360 * voortgang), x, y, C["cyaan_d"] if staat == "opgelost" else C["kader"])
    elif staat == "stoppen":
        paint(img, ring, x, y, C["cyaan"])
        paint(img, ring & (hoek < 360 * voortgang), x, y, C["tekst"])
    binnen, _, _ = disc_mask(0, 6.0, 17)
    paint(img, binnen, x, y, C["zwart"])
    # hoofd van de sluiswachter: brede hoed, vol zwart lijf, cyaan rand, witte ogen
    rect(img, x + 3, y + 6, 11, 1, C["cyaan"] if staat != "weg" else C["kader_d"])
    rect(img, x + 5, y + 3, 7, 3, C["cyaan"] if staat != "weg" else C["kader_d"])
    rect(img, x + 6, y + 4, 5, 2, C["p2_lijf"])
    rect(img, x + 6, y + 7, 5, 6, C["p2_lijf"])
    frame(img, x + 5, y + 7, 7, 7, C["cyaan_d"] if staat != "weg" else C["kader_d"])
    rect(img, x + 7, y + 9, 1, 1, C["cyaan_l"])
    rect(img, x + 9, y + 9, 1, 1, C["cyaan_l"])
    if staat == "weg":
        # controller-glyph met uitroepteken
        rect(img, x - 14, y + 5, 11, 7, C["kader"])
        rect(img, x - 13, y + 6, 9, 5, C["zwart"])
        rect(img, x - 9, y + 6, 1, 3, C["tekst"])
        rect(img, x - 9, y + 10, 1, 1, C["tekst"])
    if label and staat != "weg":
        txt(img, "P2", x - 14, y + 5, C["cyaan"])


def merk(img, cx, cy, kleur, kwarten, staat="aftellen", groot=False):
    """Schaduwmerk (E-14i): peilmerk-vonk met een klokring van 4 kwarten.

    Elke carillonslag (audio bible 6.1) dooft een kwart, met de klok mee vanaf
    boven. kwarten = aantal dat nog brandt (4..0).
    """
    s = 25 if groot else 19
    r1, r2 = (8.0, 11.0) if groot else (6.0, 8.0)
    o = s // 2
    x, y = cx - o, cy - o
    ring, dx, dy = disc_mask(r1, r2, s)
    rb, _, _ = disc_mask(r2, r2 + 1.0, s)
    ri, _, _ = disc_mask(r1 - 1.0, r1, s)
    hoek = (np.degrees(np.arctan2(dx, -dy)) + 360) % 360
    licht = {"amber": C["gloed"][6], "cyaan": hx("#bff4fc")}[kleur]
    hoofd = C[kleur]
    if staat == "boem":
        burst, bx, by = disc_mask(0, r2 + 4, s + 8)
        ang = (np.degrees(np.arctan2(bx, -by)) + 360) % 360
        stralen = burst & ((ang % 45) < 12)
        paint(img, stralen, x - 4, y - 4, C["gloed"][7])
        kern, _, _ = disc_mask(0, r1, s)
        paint(img, kern, x, y, C["gloed"][7])
        paint(img, ring, x, y, hoofd)
        return
    paint(img, rb, x, y, C["zwart"])
    paint(img, ri, x, y, C["zwart"])
    for q in range(4):
        deel = ring & (hoek >= q * 90 + 6) & (hoek < (q + 1) * 90 - 6)
        # kwart q (0 = rechtsboven) dooft eerst: de ring loopt met de klok mee leeg
        brandt = q >= 4 - kwarten
        paint(img, deel, x, y, licht if brandt else C["wf_d"])
    # kern: peilmerk (schijfje met waterlijn)
    kr = 3.6 if not groot else 4.6
    kern, _, _ = disc_mask(0, kr, s)
    kernrand, _, _ = disc_mask(kr, kr + 1.0, s)
    dim = staat == "dooft"
    if kleur == "cyaan":
        # P2: sluismerk, een ruit met een verticale streep (vorm verschilt, niet alleen kleur)
        yy, xx = np.mgrid[0:s, 0:s]
        d1 = np.abs(xx - o) + np.abs(yy - o)
        kern, kernrand = d1 <= kr + 0.6, (d1 > kr + 0.6) & (d1 <= kr + 1.6)
    paint(img, kernrand, x, y, C["zwart"])
    paint(img, kern, x, y, (hoofd // 2) if dim else hoofd)
    if kleur == "cyaan":
        rect(img, cx, cy - int(kr) + 1, 1, 2 * int(kr) - 1, C["tekst_d"] if dim else C["cyaan_l"])
    else:
        rect(img, cx - int(kr) + 1, cy, 2 * int(kr) - 1, 1, C["tekst_d"] if dim else C["gloed"][7])


def vijand(img, cx, cy):
    """Basisvijand als placeholder (laag, breed, stekels, rode bovenrand, kern)."""
    rect(img, cx - 15, cy - 6, 30, 13, C["zwart"])
    rect(img, cx - 14, cy - 5, 28, 11, C["vijand"])
    rect(img, cx - 14, cy - 5, 28, 1, C["vijand_kern"])
    for i in range(-12, 13, 6):
        rect(img, cx + i, cy - 9, 2, 4, C["vijand_d"])
        rect(img, cx + i, cy - 9, 2, 1, C["vijand_kern"])
    rect(img, cx - 2, cy - 1, 4, 3, C["vijand_kern"])
    rect(img, cx - 9, cy - 2, 2, 2, hx("#ffeaf0"))
    rect(img, cx + 7, cy - 2, 2, 2, hx("#ffeaf0"))


# Plaat achter de HUD: 66 % (hud-menus.md 0.2, par. 2.3; was 62 %, ui-stijlgids par. 6).
PLAAT_ALPHA = 0.66
# Melding (HUD-08): max. 196 px breed; staat het logkader er, dan 36 px hoger (par. 3.7).
MELDING_MAX_B = 196
LOG_H = 32


def plaat(img, x, y, w, h, alpha=PLAAT_ALPHA):
    rect(img, x + 1, y, w - 2, h, C["plaat"], alpha)
    rect(img, x, y + 1, 1, h - 2, C["plaat"], alpha)
    rect(img, x + w - 1, y + 1, 1, h - 2, C["plaat"], alpha)


def hud_solo(img, L=50, hp=4, hpmax=5, echo="actief", echo_v=1.0, genezen=0.0, nieuw_lamp=False,
             toevoeging=None, trillen=False):
    breedte = max(hpmax * 9 + 4, 92)
    plaat(img, 4, 4, breedte + 22, 30)
    for i in range(hpmax):
        lampje(img, 8 + i * 9, 8, i < hp, nieuw=(nieuw_lamp and i == hpmax - 1))
    lichtmeter(img, METER_X, METER_Y, L, genezen=genezen, toevoeging=toevoeging, trillen=trillen)
    if echo:
        echo_icoon(img, breedte + 8, 10, echo, echo_v)


def hud_coop(img, L=60, hp=5, hpmax=5, p2="speelt", p2_v=1.0):
    hud_solo(img, L=L, hp=hp, hpmax=hpmax, echo=None)
    W = img.shape[1]
    plaat(img, W - 40, 4, 36, 25)
    p2_badge(img, W - 25, 8, p2, p2_v)


def logkader(img, regel1, regel2, kop="LOGBLADZIJDE 3"):
    H, W = img.shape[:2]
    w, h = 360, 32
    x, y = (W - w) // 2, H - 8 - h
    plaat(img, x, y, w, h, 0.78)
    frame(img, x, y, w, h, C["kader_d"])
    txt(img, kop, x + 6, y + 4, C["gloed"][6])
    txt(img, regel1, x + 6, y + 13, C["tekst"])
    txt(img, regel2, x + 6, y + 22, C["tekst"])


def melding(img, tekst, sub=None, kleur=None, boven_log=False):
    """Melding rechtsonder (lampglas, controller, opslaan): max. 3 s, geen pauze.

    Max. MELDING_MAX_B px breed (HUD-M5). Met boven_log=True staat het logkader
    er en schuift de melding LOG_H + 4 = 36 px omhoog (HUD-M6).
    """
    H, W = img.shape[:2]
    w = max(text_width(tekst, 1), text_width(sub or "", 1)) + 12
    assert w <= MELDING_MAX_B, "melding te breed (%d px): %s" % (w, tekst)
    h = 22 if sub else 13
    x, y = W - 8 - w, H - 8 - h
    if boven_log:
        y -= LOG_H + 4
    plaat(img, x, y, w, h, 0.78)
    frame(img, x, y, w, h, kleur if kleur is not None else C["kader_d"])
    txt(img, tekst, x + 6, y + 3, kleur if kleur is not None else C["tekst"])
    if sub:
        txt(img, sub, x + 6, y + 12, C["tekst_d"])


def gemaalmeter(img, x, y, G, trappen=2):
    """Stand van het gemaal in de wereld (LM-08): verschijnt binnen 96 px van het gemaal."""
    h = 42
    rect(img, x, y, 9, h, C["zwart"])
    frame(img, x + 1, y + 1, 7, h - 2, C["kader"])
    rect(img, x + 2, y + 2, 5, h - 4, C["leeg"])
    vul = int((h - 4) * G / (100 * trappen))
    rect(img, x + 2, y + h - 2 - vul, 5, vul, C["gloed"][5])
    for k in range(1, trappen):
        yy = y + h - 2 - int((h - 4) * k / trappen)
        rect(img, x - 2, yy, 13, 1, C["kader"])


def bossbalk(img, naam, frac):
    H, W = img.shape[:2]
    w = 240
    x, y = (W - w) // 2, H - 14
    txt(img, naam, x, y - 10, C["tekst"])
    rect(img, x - 1, y - 1, w + 2, 6, C["zwart"])
    rect(img, x, y, w, 4, C["wf_d"])
    rect(img, x, y, int(w * frac), 4, C["tekst"])
    for f in (0.6, 0.2):
        rect(img, x + int(w * f), y - 2, 1, 8, C["gloed"][6])


def pijl_rand(img, x, y, voortgang):
    """P2 buiten beeld (C-07): cyaan pijl aan de rand met een leibandring."""
    for i in range(6):
        rect(img, x - i, y - i, 1, 2 * i + 1, C["cyaan"])
    rect(img, x - 6, y - 6, 1, 13, C["zwart"])
    ring, dx, dy = disc_mask(5.0, 7.0, 15)
    hoek = (np.degrees(np.arctan2(dx, -dy)) + 360) % 360
    paint(img, ring, x - 24, y - 7, C["wf_d"])
    paint(img, ring & (hoek < 360 * (1 - voortgang)), x - 24, y - 7, C["cyaan"])


def knop(img, x, y, letter, kleur=None):
    """Knopglyph (9x9 rondje met letter). De echte glyphs per apparaat: UI Artist."""
    d, _, _ = disc_mask(0, 4.6, 9)
    paint(img, d, x, y, kleur if kleur is not None else C["kader"])
    draw_text(img, letter, x + 2, y + 1, C["zwart"], 1)
    return 11


# ------------------------------------------------------------------ scènes
def laad(naam):
    return np.array(Image.open(os.path.join(R5, naam)).convert("RGB"))


def opslaan(img, naam, schaal=1):
    im = Image.fromarray(img)
    if schaal != 1:
        im = im.resize((im.width * schaal, im.height * schaal), Image.NEAREST)
    pad = os.path.join(UIT, naam)
    im.save(pad, optimize=True)
    print("  ", os.path.relpath(pad, ROOT), im.size)


def label(img, tekst, kleur=None):
    """Bijschrift bovenaan in het midden (daar staat geen HUD)."""
    w = text_width(tekst, 1) + 8
    x = (img.shape[1] - w) // 2
    rect(img, x, 0, w, 11, C["zwart"])
    draw_text(img, tekst, x + 4, 2, kleur if kleur is not None else C["noot"], 1)


def blad_hud_grijs_kleur():
    """1. HUD solo op de R5-scène in grijs en in kleur, op ware interne grootte."""
    g = laad("r5_grijs_640x360.png")
    k = laad("r5_kleur_640x360.png")
    for img, staat in ((g, "GRIJS"), (k, "KLEUR")):
        hud_solo(img, L=50, hp=4, hpmax=5, echo="actief")
        logkader(img, "HET WATER STOND TOT DE TWEEDE TREDE.", "DAARNA HOORDE NIEMAND DE KLOK NOG.")
        label(img, "HUD SOLO, " + staat + " (640X360, X1)")
    opslaan(np.concatenate([g, k], 0), "hud_solo_grijs_kleur_640x360_placeholder.png")


def blad_hud_annotaties():
    """2. HUD solo met notities (x2), kleur, met merk, gemaalstand en boss-balk-variant."""
    img = laad("r5_kleur_640x360.png")
    hud_solo(img, L=70, hp=5, hpmax=6, echo="actief")
    noot(img, 1, 70, 6)
    noot(img, 2, 94, 21)
    noot(img, 3, 22, 33)
    noot(img, 4, 120, 10)
    vijand(img, 470, 268)
    merk(img, 470, 266, "amber", 2)
    noot(img, 5, 484, 246)
    gemaalmeter(img, 560, 196, 130)
    noot(img, 6, 572, 190)
    logkader(img, "HET WATER STOND TOT DE TWEEDE TREDE.", "DAARNA HOORDE NIEMAND DE KLOK NOG.")
    noot(img, 7, 126, 320)
    melding(img, "LAMPGLAS: +1 LEVEN", boven_log=True)
    noot(img, 8, 540, 288)
    label(img, "HUD SOLO MET NOTITIES (NRS = HUD-TABEL)")
    opslaan(img, "hud_solo_annotaties_x2_placeholder.png", 2)


def blad_hud_deck():
    """3. Steam Deck 640x400: HUD aan de schermrand, dus in de 16:10-band."""
    big = laad("r5_grijs_deck_1280x800.png")
    img = big[::2, ::2].copy()
    hud_solo(img, L=30, hp=3, hpmax=5, echo="leeg", echo_v=0.4)
    logkader(img, "DE SLUISWACHTER TELDE DE SLAGEN.", "EEN, TWEE, EN DAN HET WATER.")
    for yy in (20, 379):
        for xx in range(0, 640, 6):
            rect(img, xx, yy, 3, 1, C["noot"])
    txt(img, "16:10-BAND, 20 PX (NIET GEDIMD)", 450, 24, C["noot"])
    txt(img, "16:10-BAND, 20 PX", 520, 386, C["noot"])
    label(img, "STEAM DECK 640X400: HUD OP 8 PX VAN DE SCHERMRAND")
    opslaan(img, "hud_deck_640x400_placeholder.png")
    opslaan(img, "hud_deck_x2_1280x800_placeholder.png", 2)


def blad_hud_coop():
    """4. HUD co-op op ware interne grootte: gedeelde meter + P2-badge."""
    img = laad("r5_kleur_640x360.png")
    hud_coop(img, L=60, hp=5)
    lichtmeter(img, METER_X, METER_Y, 60, toevoeging=(60, C["cyaan"]))
    label(img, "HUD CO-OP: GEDEELDE METER LINKS, P2 RECHTS (640X360, X1)")
    opslaan(img, "hud_coop_640x360_placeholder.png")


def blad_elementen():
    """5. Alle HUD-onderdelen en hun toestanden (x4)."""
    W, H = 320, 258
    img = np.zeros((H, W, 3), np.uint8)
    img[:] = C["wf_bg"]
    y = 6
    txt(img, "LICHTMETER (10 SEGMENTEN = 10 POMPSLAGEN)", 6, y, C["noot"])
    y += 12
    for i, (L, opt, tekst) in enumerate([
            (0, {}, "0 LP"), (20, {"trillen": True}, "20: TE WEINIG"),
            (50, {"toevoeging": (50, C["amber"])}, "50 +LP"), (70, {"genezen": 0.5}, "GENEZEN 50%"),
            (100, {}, "100 VOL")]):
        xx = 6 + (i % 3) * 104
        yy = y + (i // 3) * 26
        lichtmeter(img, xx, yy, L, **opt)
        txt(img, tekst, xx, yy + 14, C["tekst_d"])
    y += 56
    txt(img, "LEVENSPUNTEN 5 TOT 9 (LAMPGLAS +1)", 6, y, C["noot"])
    y += 11
    for i in range(9):
        lampje(img, 6 + i * 9, y, i < 6, nieuw=(i == 8))
    txt(img, "6/9, NIEUW LAMPJE", 92, y + 1, C["tekst_d"])
    y += 18
    txt(img, "ECHO (SOLO)", 6, y, C["noot"])
    y += 11
    for i, (st, v, t) in enumerate([("actief", 1, "ACTIEF"), ("leeg", 0.3, "LEEG 30%"), ("leeg", 0.8, "LEEG 80%"),
                                     ("breken", 1, "BREEKT"), ("buiten", 0.6, "BUITEN"), ("uit", 1, "UIT (F4)")]):
        echo_icoon(img, 8 + i * 52, y, st, v)
        txt(img, t, 8 + i * 52 - 2, y + 20, C["tekst_d"])
    y += 34
    txt(img, "P2-BADGE (CO-OP)", 6, y, C["noot"])
    y += 11
    for i, (st, v, t) in enumerate([("speelt", 1, "SPEELT"), ("opgelost", 0.4, "TERUG 40%"),
                                     ("stoppen", 0.6, "STOPPEN 60%"), ("weg", 0.5, "PAD WEG")]):
        p2_badge(img, 22 + i * 78, y, st, v)
        txt(img, t, 8 + i * 78, y + 20, C["tekst_d"])
    y += 34
    txt(img, "GEMAAL (WERELD)  BOSS-BALK (60% EN 20%)", 6, y, C["noot"])
    gemaalmeter(img, 10, y + 10, 130)
    sub = img[y + 10:y + 40, 40:316]
    tmp = np.zeros((40, 276, 3), np.uint8)
    tmp[:] = C["wf_bg"]
    bossbalk(tmp, "DE GEMAALMEESTER", 0.45)
    img[y + 10:y + 50, 40:316] = tmp
    del sub
    opslaan(img, "hud_elementen_x4_placeholder.png", 4)


def blad_merk():
    """6. Merk-aftelling in de wereld (x4): solo amber, co-op cyaan; normaal, grijs, deuteranopie."""
    tw, th = 44, 40
    kolommen = [("GEZET|", 4, "aftellen"), ("D-30|SLAG 1", 3, "aftellen"), ("D-15|SLAG 2", 2, "aftellen"),
                ("D|BOEM", 0, "boem"), ("D|SLAG 3", 1, "aftellen"), ("D+15|SLAG 4", 0, "aftellen"),
                ("D+30|DOOFT", 0, "dooft")]
    rijen = [("AMBER (P1)", "amber"), ("CYAAN (P2)", "cyaan")]
    kop = 21
    lw = 76
    W = lw + tw * len(kolommen)
    blok = kop + th * len(rijen)
    img = np.zeros((blok * 3 + 6, W, 3), np.uint8)
    img[:] = C["wf_bg"]

    def teken(base_y):
        for c, (t, _, _) in enumerate(kolommen):
            r1, r2 = t.split("|")
            draw_text(img, r1, lw + c * tw + 2, base_y + 2, C["tekst"], 1)
            draw_text(img, r2, lw + c * tw + 2, base_y + 11, C["tekst_d"], 1)
        for r, (rt, kl) in enumerate(rijen):
            y0 = base_y + kop + r * th
            draw_text(img, rt.split(" ")[0], 2, y0 + 14, C["tekst"], 1)
            draw_text(img, rt.split(" ")[1], 2, y0 + 23, C["tekst_d"], 1)
            for c, (_, kw, st) in enumerate(kolommen):
                cx = lw + c * tw + tw // 2
                rect(img, lw + c * tw, y0, tw, th, C["schaduw"] if (c + r) % 2 else hx("#200e36"))
                vijand(img, cx, y0 + 26)
                merk(img, cx, y0 + 22, kl, kw, st)

    teken(0)
    normaal = img[:blok].copy()
    img[blok + 3:2 * blok + 3] = grijs(normaal)
    img[2 * blok + 6:3 * blok + 6] = (deuteranopia(normaal / 255.0) * 255).astype(np.uint8)
    for i, t in enumerate(["NORMAAL", "GRIJS (LUMINANTIE)", "DEUTERANOPIE"]):
        yy = i * (blok + 3) + 2
        draw_text(img, t.split(" ")[0], 2, yy, C["noot"], 1)
    opslaan(img, "merk_aftelling_x4_placeholder.png", 4)


def menu_basis(achtergrond="grijs", dim=0.55):
    img = laad("r5_grijs_640x360.png" if achtergrond == "grijs" else "r5_kleur_640x360.png")
    img = (img * (1 - dim) + C["plaat"] * dim).astype(np.uint8)
    return img


def menulijst(img, x, y, items, gekozen, stap=16, breedte=150):
    for i, it in enumerate(items):
        yy = y + i * stap
        dim = it.startswith("~")
        t = it.lstrip("~")
        if i == gekozen:
            rect(img, x - 6, yy - 4, breedte, 15, C["plaat"], 0.9)
            frame(img, x - 6, yy - 4, breedte, 15, C["amber"])
            for k in range(4):
                rect(img, x - 14 + k, yy - 1 + k, 1, 7 - 2 * k, C["amber"])
        txt(img, t, x, yy, C["kader_d"] if dim else (C["tekst"] if i == gekozen else C["tekst_d"]))


def hintbalk(img, hints):
    H, W = img.shape[:2]
    x = W - 8
    for letter, t in reversed(hints):
        w = text_width(t, 1)
        x -= w
        txt(img, t, x, H - 16, C["tekst_d"])
        x -= 13
        knop(img, x, H - 17, letter)
        x -= 10


# Onderdelen uit ui-stijlgids par. 12.2-12.3, als placeholder (v0.3). Maten in interne pixels.
def zijband(img, w=214):
    """Zijband links (hoofdmenu, pauze): plaat 78 %, rand rechts gevel wit 2."""
    rect(img, 0, 0, w, img.shape[0], C["plaat"], 0.78)
    rect(img, w - 1, 0, 1, img.shape[0], C["wf_d"])


def verduister(img, alpha=0.72):
    """Verduistering in lucht 0 (`ColorRect`), zoals achter Opties."""
    return (img * (1 - alpha) + np.asarray(C["zwart"]) * alpha).astype(np.uint8)


def lamp(img, x, y):
    """Het lantaarntje (7x9) van de keuzebalk: placeholder als driehoek."""
    for k in range(4):
        rect(img, x + k, y + 1 + k, 1, 7 - 2 * k, C["amber"])


def regel(img, x, y, tekst, gekozen=False, breedte=160, uit=False, h=15):
    """Menuregel (Button): keuzebalk + lamp bij focus; tekst op x + 13 (par. 12.3)."""
    if gekozen:
        rect(img, x, y, breedte, h, C["gloed"][0], 0.7)
        frame(img, x, y, breedte, h, C["gloed"][5])
        lamp(img, x + 3, y + (h - 9) // 2)
    kl = C["kader_d"] if uit else (C["tekst"] if gekozen else C["tekst_d"])
    txt(img, tekst, x + 13, y + (h - 7) // 2, kl)


def paneel(img, x, y, w, h):
    """Dialoog: ijzeren plaat met klinknagels (paneel_9slice), plaat 85 %."""
    plaat(img, x, y, w, h, 0.85)
    frame(img, x, y, w, h, C["wf"], 2)
    for px, py in ((x + 3, y + 3), (x + w - 5, y + 3), (x + 3, y + h - 5), (x + w - 5, y + h - 5)):
        rect(img, px, py, 2, 2, C["kader"])


def kader(img, x, y, w, h, alpha=0.78):
    """Kader (`Uitleg`, kader_9slice van de HUD)."""
    plaat(img, x, y, w, h, alpha)
    frame(img, x, y, w, h, C["kader_d"])


def maat(img, x, y, tekst):
    """Maatnotitie in magenta (geen tekst van het scherm)."""
    txt(img, tekst, x, y, C["noot"])


def blad_hoofdmenu():
    """Hoofdmenu op de plaatsing van ui-stijlgids par. 12.4 (zijband 214 px).

    v0.3: de regel onder DOORGAAN staat op twee regels (wijk / licht - speeltijd), par. 4.2 nr. 2.
    """
    img = menu_basis("grijs", 0.35)
    zijband(img)
    txt(img, "POLDERLIGHT", 28, 44, C["tekst"], scale=3)
    txt(img, "WERKTITEL", 30, 80, C["tekst_d"])
    regel(img, 28, 108, "DOORGAAN", True)
    txt(img, "WIJK 1.1 DE KADEWIJK", 41, 124, C["tekst_d"])
    txt(img, "LICHT 40   12 MIN", 41, 134, C["tekst_d"])
    dashed(img, 40, 122, 167, 21, C["noot"])
    for i, t in enumerate(["SPELBESTANDEN", "OPTIES", "CREDITS", "AFSLUITEN"]):
        regel(img, 28, 148 + 16 * i, t)
    noot(img, 1, 190, 104)
    noot(img, 2, 216, 126)
    txt(img, "MAX. 165 PX", 232, 128, C["noot"])
    knop(img, 8, 343, "Y")
    txt(img, "TAAL: NEDERLANDS", 21, 345, C["tekst_d"])
    noot(img, 3, 124, 342)
    txt(img, "2E SPELER: DRUK OP START", 420, 316, C["cyaan"])
    noot(img, 4, 570, 314)
    hintbalk(img, [("A", "KIES"), ("B", "TERUG")])
    label(img, "HOOFDMENU")
    opslaan(img, "menu_hoofdmenu_x2_placeholder.png", 2)


def blad_spelbestanden():
    """Slot-menu (hud-menus.md par. 4.7 en 4.7a): indeling in interne pixels.

    Paneel 1: lijst normaal (plaats 1 HERSTELD en gekozen, 2 beschadigd, 3 leeg).
    Paneel 2: de dwingende bevestiging (MN-23), cursor op TERUG.
    Paneel 3: lijst bij Tekstgrootte groot (kader 584 x 50).
    Geen vraagteken in het wireframe-font; de echte tekst staat in strings.csv.
    """
    RIJEN = [
        ("PLAATS 1", "WIJK 1.1 DE KADEWIJK   LICHT 40   1 U 12 MIN", C["tekst_d"]),
        ("PLAATS 2", "BESCHADIGD: KAN NIET LADEN", C["gloed"][6]),
        ("PLAATS 3", "LEEG", C["kader_d"]),
    ]

    def lijst(img, gekozen, groot=False):
        w, h, stap = (584, 50, 58) if groot else (400, 36, 44)
        r1, r2 = (9, 27) if groot else (8, 20)
        txt(img, "SPELBESTANDEN", 28, 8, C["tekst"], scale=2)
        for i, (kop, sub, kl) in enumerate(RIJEN):
            y = 40 + i * stap
            if i == gekozen:
                rect(img, 28, y, w, h, C["gloed"][0], 0.7)
                frame(img, 28, y, w, h, C["gloed"][5])
                lamp(img, 31, y + (h - 9) // 2)
            else:
                kader(img, 28, y, w, h)
            txt(img, kop, 41, y + r1, C["tekst"] if i == gekozen else C["tekst_d"])
            txt(img, sub, 41, y + r2, kl)
            if i == 0:
                # Stand HERSTELD: rechts op regel 1, naast PLAATS n (MN-22).
                t = "HERSTELD UIT BACK-UP"
                txt(img, t, 28 + w - 8 - text_width(t, 1), y + r1, C["tekst_d"])
                # Na schema v2: lampglas achteraan regel 2 (par. 7 punt 13).
                lx = 41 + text_width(sub, 1) + 18
                dashed(img, lx - 3, y + r2 - 3, text_width("LAMPGLAS 1/4", 1) + 6, 13, C["noot"])
                txt(img, "LAMPGLAS 1/4", lx, y + r2, C["kader_d"])
        return img

    basis = verduister(laad("r5_grijs_640x360.png"))

    a = lijst(basis.copy(), 0)
    noot(a, 1, 432, 40)
    noot(a, 2, 432, 84)
    noot(a, 3, 432, 128)
    noot(a, 4, 432, 66)
    maat(a, 448, 68, "LAMPGLAS: NA SCHEMA V2")
    maat(a, 28, 30, "X 28")
    maat(a, 432, 54, "400 X 36")
    maat(a, 432, 98, "8 PX ERTUSSEN")
    kader(a, 28, 176, 400, 16)
    txt(a, "(MN-24, 5 S) OPSLAAN MISLUKT. DEZE PLAATS IS NU LEEG.", 41, 180, C["tekst"])
    noot(a, 5, 432, 178)
    hintbalk(a, [("A", "LADEN"), ("X", "NIEUW SPEL HIER"), ("B", "TERUG")])
    noot(a, 6, 380, 328)
    label(a, "SPELBESTANDEN: INDELING NORMAAL (MN-21, MN-22, 4.7A)")

    b = lijst(basis.copy(), 0)
    b = verduister(b, 0.5)
    x, y, w, h = 120, 116, 400, 128
    paneel(b, x, y, w, h)
    txt(b, "PLAATS 1 OVERSCHRIJVEN", x + 16, y + 12, C["tekst"], scale=2)
    txt(b, "WIJK 1.1 DE KADEWIJK   1 U 12 MIN", x + 16, y + 38, C["tekst_d"])
    txt(b, "DIT SPEL WORDT GEWIST. DAT KAN NIET TERUG.", x + 16, y + 50, C["tekst"])
    dashed(b, x + 16, y + 48, 368, 21, C["noot"])
    regel(b, x + 16, y + 80, "TERUG", True)
    regel(b, x + 16, y + 96, "OVERSCHRIJVEN")
    noot(b, 1, x + 180, y + 80)
    noot(b, 2, x + 180, y + 96)
    maat(b, x + 200, y + 82, "A EN B = TERUG")
    maat(b, x + 200, y + 98, "ALLEEN OMLAAG + A")
    maat(b, x + 14, y + h + 22, "PANEEL 400 X 128 OP (120, 116); LIJST EXTRA 50 % VERDUISTERD")
    maat(b, x + 252, y + 72, "TEKST 2 REGELS")
    noot(b, 3, x, y + h + 8)
    maat(b, x + 14, y + h + 10, "NOTITIE: EERST LOSLATEN, 0,25 S. GEEN WRAP. CURSOR ALTIJD OP TERUG.")
    hintbalk(b, [("A", "KIES"), ("B", "TERUG")])
    label(b, "BEVESTIGING OVERSCHRIJVEN: DWINGEND, B = STANDAARD (MN-23)")

    c = lijst(basis.copy(), 0, groot=True)
    maat(c, 28, 220, "TEKSTGROOTTE GROOT: KADER 584 X 50, OM DE 58 PX; REGEL 2 OP Y + 27")
    maat(c, 28, 232, "PANEEL GROOT 480 X 168 OP (80, 96); KNOPPEN 200 X 20")
    hintbalk(c, [("A", "LADEN"), ("X", "NIEUW SPEL HIER"), ("B", "TERUG")])
    label(c, "SPELBESTANDEN: TEKSTGROOTTE GROOT")
    opslaan(np.concatenate([a, b, c], 0), "menu_spelbestanden_x2_placeholder.png", 2)


def blad_logboek():
    """Logboek (MN-15, MN-30-MN-34): tabs per gebied, lijst links, bladzijde rechts.

    Paneel 1: normaal. Paneel 2: Tekstgrootte groot (bladzijde onder de lijst, 540 x 48).
    """
    def basis(groot=False):
        img = laad("r5_kleur_640x360.png")
        img = verduister(img)
        txt(img, "LOGBOEK", 28, 8, C["tekst"], scale=2)
        tabbalk(img, ["PROLOOG", "WIJK 1.1 DE KADEWIJK"], 1, y=38)
        txt(img, "3 VAN 7 GEVONDEN", 28, 58, C["tekst_d"])
        return img

    rijen = [("LOGBLADZIJDE 3", True), ("LOGBLADZIJDE 4", True), ("-  -  -", False),
             ("LOGBLADZIJDE 6", True), ("-  -  -", False), ("-  -  -", False), ("-  -  -", False)]

    a = basis()
    for i, (t, gevonden) in enumerate(rijen):
        regel(a, 28, 74 + 16 * i, t, gekozen=(i == 1), uit=not gevonden)
    kader(a, 232, 74, 360, 32)
    txt(a, "LOGBLADZIJDE 4", 238, 78, C["gloed"][6])
    txt(a, "DE SLUISWACHTER SCHREEF HET PEIL OP DE MUUR,", 238, 88, C["tekst"])
    txt(a, "ELKE AVOND EEN STREEP HOGER.", 238, 97, C["tekst"])
    noot(a, 1, 250, 36)
    noot(a, 2, 132, 56)
    noot(a, 3, 190, 92)
    noot(a, 4, 190, 108)
    noot(a, 5, 596, 74)
    maat(a, 232, 112, "ZELFDE KADER ALS HUD-07: 360 X 32, BINNEN 348")
    maat(a, 232, 124, "VOLGT DE CURSOR METEEN; GEEN A NODIG")
    maat(a, 28, 190, "LEGE PLEK = UIT (GEVEL WIT 3), CURSOR SLAAT HEM OVER")
    hintbalk(a, [("L", "GEBIED"), ("R", "GEBIED"), ("B", "TERUG")])
    label(a, "LOGBOEK (PAUZE): NORMAAL")

    b = basis(groot=True)
    for i, (t, gevonden) in enumerate(rijen):
        regel(b, 28, 74 + 20 * i, t, gekozen=(i == 1), uit=not gevonden, breedte=200, h=20)
    kader(b, 50, 222, 540, 48)
    txt(b, "LOGBLADZIJDE 4", 58, 228, C["gloed"][6])
    txt(b, "DE SLUISWACHTER SCHREEF HET PEIL OP DE MUUR,", 58, 242, C["tekst"])
    txt(b, "ELKE AVOND EEN STREEP HOGER.", 58, 256, C["tekst"])
    maat(b, 260, 120, "GROOT: REGELS 200 X 20; BLADZIJDE ONDER DE LIJST")
    maat(b, 260, 132, "KADER 540 X 48 OP (50, 222), ZOALS HET GROTE LOGKADER")
    hintbalk(b, [("L", "GEBIED"), ("R", "GEBIED"), ("B", "TERUG")])
    label(b, "LOGBOEK: TEKSTGROOTTE GROOT")
    opslaan(np.concatenate([a, b], 0), "menu_logboek_x2_placeholder.png", 2)


def blad_credits():
    """Credits (MN-35-MN-37): een kolom in het midden die vanzelf omhoog schuift."""
    def kolom(img, y0):
        y = y0
        blokken = [("POLDERLIGHT", ["EEN SPEL VAN DE STUDIO"]),
                   ("ROL", ["NAAM", "NAAM"]),
                   ("ROL", ["NAAM"]),
                   ("ROL", ["NAAM", "NAAM", "NAAM"]),
                   ("GEMAAKT MET", ["GODOT ENGINE"]),
                   ("LICENTIES", ["UIT DOCS/LICENTIES.MD"])]
        for kop, namen in blokken:
            if 16 < y < 330:
                txt(img, kop, 320 - text_width(kop, 1) // 2, y, C["gloed"][6])
            y += 12
            for n in namen:
                if 16 < y < 330:
                    txt(img, n, 320 - text_width(n, 1) // 2, y, C["tekst"])
                y += 12
            y += 14
        return y

    a = verduister(laad("r5_grijs_640x360.png"))
    dashed(a, 160, 16, 320, 314, C["noot"])
    kolom(a, 40)
    noot(a, 1, 484, 16)
    maat(a, 484, 30, "KOLOM 320 BREED")
    maat(a, 484, 42, "GECENTREERD")
    noot(a, 2, 484, 60)
    maat(a, 484, 74, "ROL: GLOED 6")
    maat(a, 484, 86, "NAAM: GEVEL WIT 7")
    maat(a, 484, 98, "12 PX PER REGEL")
    maat(a, 484, 110, "14 PX TUSSEN BLOKKEN")
    noot(a, 3, 484, 130)
    maat(a, 484, 144, "SCHUIFT 20 PX/S OMHOOG")
    maat(a, 484, 156, "OMLAAG VAST = X4")
    maat(a, 484, 168, "OMHOOG VAST = TERUG")
    hintbalk(a, [("+", "SNELLER"), ("B", "TERUG")])
    label(a, "CREDITS (HOOFDMENU)")
    opslaan(a, "menu_credits_x2_placeholder.png", 2)


def blad_herbinden_kolom():
    """Herbinden: de kolom kiezen (MN-40-MN-44). Paneel 1: cel gekozen. Paneel 2: wachten op een knop."""
    kol = [20, 196, 326, 466]
    rijen = [("LINKS / RECHTS", "A / D", "PIJLEN", "STICK, D-PAD"),
             ("SPRINGEN", "SPATIE", "ENTER", "A"),
             ("AANVAL", "E", "R-CTRL", "X"),
             ("INTERACTIE (GENEZEN)", "F", "/", "Y"),
             ("ECHO (LOSLATEN)", "Q", ".", "LB"),
             ("DASH", "L-SHIFT", "R-SHIFT", "RB")]

    def tabel(img, rij, cel, wacht=False):
        txt(img, "OPTIES", 28, 8, C["tekst"], scale=2)
        tabbalk(img, TABS, 3)
        for x, t in zip(kol, ["ACTIE", "TOETSENBORD 1", "TOETSENBORD 2", "CONTROLLER"]):
            txt(img, t, x + 13, 58, C["gloed"][6])
        for i, r in enumerate(rijen):
            y = 74 + i * 18
            if i == rij:
                rect(img, 20, y, 588, 15, C["gloed"][0], 0.7)
                frame(img, 20, y, 588, 15, C["gloed"][5])
                lamp(img, 23, y + 3)
            for j, (x, t) in enumerate(zip(kol, r)):
                if i == rij and j == cel:
                    rechts = (kol[j + 1] - 7) if j + 1 < len(kol) else 604
                    if wacht:
                        rect(img, x + 10, y + 2, rechts - x - 10, 11, C["gloed"][5])
                        txt(img, "DRUK EEN KNOP...", x + 13, y + 4, C["zwart"], schaduw=False)
                        continue
                    frame(img, x + 10, y + 2, rechts - x - 10, 11, C["gloed"][6])
                txt(img, t, x + 13, y + 4, C["tekst"] if i == rij else C["tekst_d"])
        return img

    basis = verduister(laad("r5_grijs_640x360.png"))
    a = tabel(basis.copy(), 1, 3)
    noot(a, 1, 610, 74)
    maat(a, 300, 196, "LINKS / RECHTS: VAN KOLOM WISSELEN (GEEN WRAP)")
    maat(a, 300, 208, "OMHOOG / OMLAAG: ANDERE REGEL, ZELFDE KOLOM")
    maat(a, 300, 220, "START IN DE KOLOM VAN HET APPARAAT DAT STUURT")
    maat(a, 300, 232, "ACTIE IS GEEN CEL: LINKS STOPT BIJ TOETSENBORD 1")
    noot(a, 2, 280, 196)
    hintbalk(a, [("+", "KOLOM"), ("A", "HERBIND"), ("X", "STANDAARD"), ("B", "TERUG")])
    label(a, "HERBINDEN: KOLOM GEKOZEN MET CEL_FOCUS (MN-40, MN-41)")

    b = tabel(basis.copy(), 1, 3, wacht=True)
    noot(b, 1, 610, 74)
    maat(b, 300, 196, "ALLEEN EEN KNOP VAN DIT SOORT APPARAAT TELT:")
    maat(b, 300, 208, "CONTROLLER = ELKE PAD; TOETSENBORD = TOETSEN")
    maat(b, 300, 220, "ESC OF B ANNULEERT, VAN ELK APPARAAT; 5 S")
    noot(b, 2, 280, 196)
    hintbalk(b, [("B", "ANNULEREN")])
    label(b, "HERBINDEN: WACHTEN OP EEN KNOP (MN-42)")
    opslaan(np.concatenate([a, b], 0), "menu_herbinden_kolom_x2_placeholder.png", 2)


def blad_pauze():
    img = laad("r5_kleur_640x360.png")
    hud_coop(img, L=60, hp=4)
    img = (img * 0.45 + C["plaat"] * 0.55).astype(np.uint8)
    rect(img, 0, 0, 220, 360, C["plaat"], 0.85)
    txt(img, "PAUZE", 40, 40, C["tekst"], scale=2)
    menulijst(img, 48, 84, ["VERDER", "LOGBOEK", "OPTIES", "SPELER 2 STOPT", "NAAR HOOFDMENU"], 0)
    noot(img, 1, 26, 80)
    noot(img, 2, 156, 128)
    txt(img, "WIJK 1.1 DE KADEWIJK", 250, 84, C["tekst"])
    txt(img, "GEMAAL: TRAP 1 VAN 2", 250, 98, C["tekst_d"])
    txt(img, "LAMPGLAS 0/1   LOGBOEK 3/7", 250, 112, C["tekst_d"])
    txt(img, "OPGESLAGEN BIJ HET GEMAAL", 250, 126, C["tekst_d"])
    noot(img, 3, 420, 82)
    txt(img, "PAUZE VAN P1. P2 KAN NIET STUREN.", 48, 300, C["tekst_d"])
    noot(img, 4, 252, 298)
    hintbalk(img, [("A", "KIES"), ("B", "VERDER")])
    label(img, "PAUZE (CO-OP)")
    opslaan(img, "menu_pauze_x2_placeholder.png", 2)


def tabbalk(img, tabs, gekozen, y=36):
    x = 40
    for i, t in enumerate(tabs):
        w = text_width(t, 1)
        if i == gekozen:
            rect(img, x - 4, y - 4, w + 8, 15, C["plaat"], 0.95)
            frame(img, x - 4, y - 4, w + 8, 15, C["amber"])
        txt(img, t, x, y, C["tekst"] if i == gekozen else C["tekst_d"])
        x += w + 16
    knop(img, 22, y - 1, "L")
    knop(img, x, y - 1, "R")
    rect(img, 30, y + 14, 580, 1, C["kader_d"])


def optierij(img, y, naam, waarde, gekozen=False, schuif=None):
    if gekozen:
        rect(img, 36, y - 4, 568, 15, C["plaat"], 0.95)
        frame(img, 36, y - 4, 568, 15, C["amber"])
    txt(img, naam, 44, y, C["tekst"] if gekozen else C["tekst_d"])
    if schuif is not None:
        rect(img, 400, y + 1, 120, 5, C["wf_d"])
        rect(img, 400, y + 1, int(120 * schuif), 5, C["tekst"] if gekozen else C["tekst_d"])
        txt(img, "%d%%" % int(schuif * 100), 530, y, C["tekst_d"])
    else:
        t = "< " + waarde + " >" if gekozen else waarde
        txt(img, t, 400 - (12 if gekozen else 0), y, C["tekst"] if gekozen else C["tekst_d"])


TABS = ["ALGEMEEN", "BEELD", "GELUID", "BESTURING", "TOEGANKELIJKHEID"]


def blad_opties_toegankelijkheid():
    img = menu_basis("grijs", 0.8)
    txt(img, "OPTIES", 40, 12, C["tekst"], scale=2)
    tabbalk(img, TABS, 4)
    rijen = [
        ("VASTHOUDEN OF TIKKEN", "VASTHOUDEN", None),
        ("SCHERMSCHOK", "", 1.0),
        ("FLITSEN VERMINDEREN", "UIT", None),
        ("ECHO-RAND DIKKER", "UIT", None),
        ("MERK-RING GROTER", "UIT", None),
        ("AFTELLING OOK TRILLEN", "AAN", None),
        ("KLEURPROFIEL SPELERS", "AMBER / CYAAN", None),
        ("ONDERTITELS", "AAN", None),
        ("GELUIDSBIJSCHRIFTEN", "UIT", None),
        ("TEKSTGROOTTE", "NORMAAL", None),
        ("HUD", "ALTIJD", None),
    ]
    for i, (n, w, s) in enumerate(rijen):
        optierij(img, 64 + i * 18, n, w, gekozen=(i == 0), schuif=s)
    rect(img, 36, 268, 568, 52, C["plaat"], 0.95)
    frame(img, 36, 268, 568, 52, C["kader_d"])
    txt(img, "TIKKEN: LOSLATEN, GENEZEN EN STOPPEN MET EEN DRUK. NOG EEN DRUK,", 44, 274, C["tekst"])
    txt(img, "SPRONG OF TREFFER BREEKT AF. LANCEERHOUDING: TWEE KEER AANVAL,", 44, 286, C["tekst"])
    txt(img, "SNEL NA ELKAAR (CA. 0,3 S). EEN TIK GEEFT NOOIT HOUDING.", 44, 298, C["tekst"])
    txt(img, "HOUDING STOPT BIJ AANVAL, DASH, LANCERING OF NA 2 S.", 44, 310, C["tekst_d"])
    noot(img, 1, 610, 62)
    noot(img, 2, 610, 268)
    hintbalk(img, [("A", "WIJZIG"), ("X", "STANDAARD"), ("B", "TERUG")])
    label(img, "OPTIES: TOEGANKELIJKHEID")
    opslaan(img, "menu_opties_toegankelijkheid_x2_placeholder.png", 2)


def blad_opties_besturing():
    img = menu_basis("grijs", 0.8)
    txt(img, "OPTIES", 40, 12, C["tekst"], scale=2)
    tabbalk(img, TABS, 3)
    kol = [44, 200, 330, 470]
    for x, t in zip(kol, ["ACTIE", "TOETSENBORD 1", "TOETSENBORD 2", "CONTROLLER"]):
        txt(img, t, x, 62, C["noot"])
    rijen = [("LINKS / RECHTS", "A / D", "PIJLEN", "STICK, D-PAD"),
             ("SPRINGEN", "SPATIE", "ENTER", "A"),
             ("AANVAL", "E", "R-CTRL", "X"),
             ("INTERACTIE (GENEZEN)", "F", "/", "Y"),
             ("ECHO (LOSLATEN)", "Q", ".", "LB"),
             ("DASH", "L-SHIFT", "R-SHIFT", "RB"),
             ("PAUZE", "ESC", "ESC", "MENU"),
             ("MEEDOEN (VRIJ APPARAAT)", "-", "ENTER", "MENU"),
             ("STOPPEN (VASTHOUDEN)", "-", "BACKSPACE", "VIEW")]
    for i, r in enumerate(rijen):
        y = 80 + i * 18
        if i == 4:
            rect(img, 36, y - 4, 568, 15, C["plaat"], 0.95)
            frame(img, 36, y - 4, 568, 15, C["amber"])
        for j, (x, t) in enumerate(zip(kol, r)):
            if i == 4 and j == 3:
                rect(img, x - 3, y - 3, 60, 13, C["amber"])
                txt(img, "DRUK...", x, y, C["zwart"], schaduw=False)
            else:
                txt(img, t, x, y, C["tekst"] if i == 4 else C["tekst_d"])
    txt(img, "BEZET DOOR DASH: WISSELEN?", 300, 252, C["gloed"][6])
    noot(img, 1, 610, 150)
    noot(img, 2, 460, 250)
    hintbalk(img, [("A", "HERBIND"), ("X", "STANDAARD"), ("B", "TERUG")])
    label(img, "OPTIES: BESTURING (HERBINDEN PER APPARAAT)")
    opslaan(img, "menu_opties_besturing_x2_placeholder.png", 2)


def blad_coop_storyboard():
    """Vier momenten van drop-in/drop-out op de R5-scène (elk 640x360, x1)."""
    panelen = []
    # 1. solo, tweede controller aangesloten
    a = laad("r5_kleur_640x360.png")
    hud_solo(a, L=40, hp=5, echo="actief")
    melding(a, "CONTROLLER 2", "DRUK OP START OM MEE TE DOEN", C["cyaan"])
    label(a, "1. TWEEDE PAD AANGESLOTEN (MELDING 5 S)")
    panelen.append(a)
    # 2. drop-in op de plek van de echo
    b = laad("r5_kleur_640x360.png")
    hud_coop(b, L=40, hp=5)
    ring, _, _ = disc_mask(14, 16, 40)
    paint(b, ring, 345 - 20, 262 - 20, C["cyaan"])
    ring2, _, _ = disc_mask(20, 21, 52)
    paint(b, ring2, 345 - 26, 262 - 26, C["cyaan_d"])
    melding(b, "P2 DOET MEE", "HOUD VIEW VAST OM TE STOPPEN", C["cyaan"])
    label(b, "2. DROP-IN: DE SLUISWACHTER WORDT WAKKER")
    panelen.append(b)
    # 3. leiband: P2 buiten beeld
    c = laad("r5_kleur_640x360.png")
    hud_coop(c, L=40, hp=5, p2="speelt")
    pijl_rand(c, 632, 230, 0.35)
    label(c, "3. P2 BUITEN BEELD: PIJL + RING (60 TICKS)")
    panelen.append(c)
    # 4. drop-out: stoppen vasthouden
    d = laad("r5_kleur_640x360.png")
    hud_coop(d, L=40, hp=5, p2="stoppen", p2_v=0.6)
    ring, dx, dy = disc_mask(14, 16, 40)
    hoek = (np.degrees(np.arctan2(dx, -dy)) + 360) % 360
    paint(d, ring, 345 - 20, 262 - 20, C["wf_d"])
    paint(d, ring & (hoek < 216), 345 - 20, 262 - 20, C["tekst"])
    melding(d, "P2 STOPT...", "LOSLATEN = BLIJVEN", C["cyaan"])
    label(d, "4. DROP-OUT: VIEW 60 TICKS, DAN NEEMT DE ECHO OVER")
    panelen.append(d)
    top = np.concatenate(panelen[:2], 1)
    bot = np.concatenate(panelen[2:], 1)
    opslaan(np.concatenate([top, bot], 0), "coop_dropin_dropout_storyboard_placeholder.png")


# ------------------------------------------------------------------ metingen
def metingen():
    print("\nMetingen (zie hud-menus.md par. 2.3):")
    g = laad("r5_grijs_640x360.png")
    k = laad("r5_kleur_640x360.png")
    for naam, img in (("grijs", g), ("kleur", k)):
        zone = img[4:34, 4:126].reshape(-1, 3)
        Ls = lab(zone)[:, 0]
        plaatje = (zone * (1 - PLAAT_ALPHA) + C["plaat"] * PLAAT_ALPHA)
        Lp = lab(plaatje)[:, 0]
        print("  achtergrond HUD-zone %s: L* mediaan %.1f, p95 %.1f, max %.1f; met plaat: p95 %.1f, max %.1f"
              % (naam, np.median(Ls), np.percentile(Ls, 95), Ls.max(), np.percentile(Lp, 95), Lp.max()))
    Lk = lab(C["kader"])[0]
    Lg = lab(C["gloed"][5])[0]
    Ll = lab(C["leeg"])[0]
    Lz = lab(C["zwart"])[0]
    print("  L*: kader %.1f, vulling (gloed 5) %.1f, leeg segment %.1f, contour %.1f" % (Lk, Lg, Ll, Lz))
    print("  dL* vulling - leeg segment: %.1f" % (Lg - Ll))
    print("  dL* kader - contour: %.1f" % (Lk - Lz))
    paren = [("merk amber / merk cyaan", C["amber"], C["cyaan"]),
             ("merkring amber (gloed 6) / vijandkern", C["gloed"][6], C["vijand_kern"]),
             ("merkkern amber / vijandkern", C["amber"], C["vijand_kern"]),
             ("merkkern cyaan / schaduwgeometrie 3", C["cyaan"], C["schaduw"]),
             ("meter-vulling / leeg segment", C["gloed"][5], C["leeg"]),
             ("P2-badge cyaan / plaat", C["cyaan"], C["plaat"]),
             ("echo-icoon amber / plaat", C["amber"], C["plaat"])]
    print("  dE76 normaal / deuteranopie / dL*:")
    for t, a, b in paren:
        la, lb = lab(a), lab(b)
        da = srgb_to_lab(deuteranopia(np.asarray(a, float) / 255))
        db = srgb_to_lab(deuteranopia(np.asarray(b, float) / 255))
        print("   %-42s %5.1f  %5.1f  %5.1f" % (t, np.linalg.norm(la - lb), np.linalg.norm(da - db), abs(la[0] - lb[0])))
    # bedekking van de speelruimte
    print("  bedekking HUD solo (plaat 118x30 + niets anders vast): %.1f %% van 640x360" % (118 * 30 / (640 * 360) * 100))
    print("  bedekking HUD co-op (+ P2-plaat 36x25): %.1f %%" % ((118 * 30 + 36 * 25) / (640 * 360) * 100))


def svg_schermflow():
    """Schermflow als SVG (tekst blijft scherp en bewerkbaar)."""
    knopen = {
        "start": (40, 40, "Opstart", "taal = Steam/systeem (T14)"),
        "titel": (40, 130, "Titelscherm", "“druk op een knop” = P1 (W3)"),
        "hoofd": (40, 220, "Hoofdmenu", "Doorgaan · Spelbestanden · Opties · Credits · Afsluiten"),
        "slots": (340, 220, "Spelbestanden (§4.7)", "3 plaatsen; overschrijven dwingend bevestigen"),
        "opties": (340, 340, "Opties", "Algemeen · Beeld · Geluid · Besturing · Toegankelijkheid"),
        "spel": (40, 340, "Spel (HUD)", "solo of co-op; drop-in/out zonder menu"),
        "pauze": (40, 460, "Pauze", "Verder · Logboek · Opties · Speler 2 stopt · Hoofdmenu"),
        "log": (340, 460, "Logboek (§4.8)", "tabs per gebied; lege plekken; B = pauze"),
        "pad": (340, 580, "Controller kwijt (P1)", "spel pauzeert; wacht op een knop"),
        "credits": (640, 220, "Credits (§4.9)", "schuift vanzelf; B = terug"),
    }
    pijlen = [("start", "titel", ""), ("titel", "hoofd", "knop"), ("hoofd", "slots", "Spelbestanden"),
              ("hoofd", "spel", "Doorgaan"), ("slots", "spel", ""), ("hoofd", "opties", "Opties"),
              ("hoofd", "credits", ""), ("spel", "pauze", "Menu/Esc"), ("pauze", "spel", "Verder"),
              ("pauze", "log", ""), ("pauze", "opties", ""), ("pauze", "hoofd", "Hoofdmenu (opslaan)"),
              ("spel", "pad", "pad P1 weg")]
    bw, bh = 250, 64
    out = ['<svg xmlns="http://www.w3.org/2000/svg" width="920" height="680" viewBox="0 0 920 680" '
           'font-family="sans-serif">',
           '<rect width="920" height="680" fill="#10132a"/>',
           '<defs><marker id="p" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="7" markerHeight="7" '
           'orient="auto"><path d="M0,0 L10,5 L0,10 z" fill="#cbc2b5"/></marker></defs>',
           '<text x="20" y="22" fill="#ff4fd8" font-size="13">Schermflow T10 (placeholder) · '
           'hud-menus.md §4.1</text>']

    def mid(n):
        x, y, _, _ = knopen[n]
        return x + bw / 2, y + bh / 2

    for a, b, t in pijlen:
        (x1, y1), (x2, y2) = mid(a), mid(b)
        dx, dy = x2 - x1, y2 - y1
        if abs(dx) > abs(dy):
            sx = x1 + math.copysign(bw / 2, dx)
            ex = x2 - math.copysign(bw / 2, dx)
            sy, ey = y1, y2
        else:
            sy = y1 + math.copysign(bh / 2, dy)
            ey = y2 - math.copysign(bh / 2, dy)
            sx, ex = x1, x2
        off = 8 if (b, a) in [(p[0], p[1]) for p in pijlen] else 0
        out.append('<line x1="%.0f" y1="%.0f" x2="%.0f" y2="%.0f" stroke="#cbc2b5" stroke-width="1.5" '
                   'marker-end="url(#p)"/>' % (sx + off, sy + off, ex + off, ey + off))
        if t:
            out.append('<text x="%.0f" y="%.0f" fill="#ffdb94" font-size="11">%s</text>'
                       % ((sx + ex) / 2 + 6 + off, (sy + ey) / 2 - 4 + off, t))
    for n, (x, y, t, s) in knopen.items():
        kleur = "#f29a26" if n in ("spel",) else "#5b576e"
        out.append('<rect x="%d" y="%d" width="%d" height="%d" rx="4" fill="#0c0c1d" stroke="%s" '
                   'stroke-width="2"/>' % (x, y, bw, bh, kleur))
        out.append('<text x="%d" y="%d" fill="#ece2cc" font-size="14" font-weight="bold">%s</text>'
                   % (x + 10, y + 24, t))
        out.append('<text x="%d" y="%d" fill="#a8a19f" font-size="10.5">%s</text>' % (x + 10, y + 44, s))
    out.append('<text x="640" y="380" fill="#3ee6f4" font-size="11">Overal: een vrije controller + Start</text>')
    out.append('<text x="640" y="396" fill="#3ee6f4" font-size="11">= P2 doet mee (ook in menu’s en pauze).</text>')
    out.append('</svg>')
    pad = os.path.join(UIT, "schermflow_placeholder.svg")
    with open(pad, "w", encoding="utf-8") as f:
        f.write("\n".join(out) + "\n")
    print("  ", os.path.relpath(pad, ROOT))


if __name__ == "__main__":
    print("Wireframes naar", os.path.relpath(UIT, ROOT))
    blad_hud_grijs_kleur()
    blad_hud_annotaties()
    blad_hud_deck()
    blad_hud_coop()
    blad_elementen()
    blad_merk()
    blad_hoofdmenu()
    blad_spelbestanden()
    blad_pauze()
    blad_opties_toegankelijkheid()
    blad_opties_besturing()
    blad_herbinden_kolom()
    blad_logboek()
    blad_credits()
    blad_coop_storyboard()
    svg_schermflow()
    metingen()
