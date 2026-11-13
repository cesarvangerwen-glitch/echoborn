"""De Gemaalmeester op eindkwaliteit: sprites en animaties (Animator, #265, assetlijst S-14).

Maakt in `game/art/animatie/gemaalmeester/`:
  - lichaam   (cel 128 x 176): idle, aarzeling bij de sjaal, pompslag en schoepenzwiep per kant
                (aanloop, uithaal, actief, herstel), fasewissel, Wankel, geraakt, oplossen in licht;
  - ketel     (cel 64 x 64): het schot (fase 1), tink, breuk, kern open (puls), kern geraakt, schot
                sluit, schot voorgoed dicht (fase 2), merkplek van Wankel, oplossen;
  - rad       (cel 112 x 72): draaien in 8 frames, in 4 stadia van scheuren (één per ± 3 kanten),
                treffer, trillen, oplossen; met de loopkat aan de balk van S8;
  - effecten  pompslag (de vloer barst open op het vlak), schoepenzwiep (links en rechts), tell-vlakken
                (25 % / 75 % / actief) en de spuigaten;
  elk in grijs, half en kleur, plus een index-atlas voor de palet-LUT, en het manifest
  `gemaalmeester.json` (frames, ticks per frame, plaatsing ten opzichte van de boss-node).
En in `docs/art/slice/eindkwaliteit/`: overzichtsbladen, de boss in S8 (grijs en kleur), de ketel met
P1 en de holle echo (punt van de CD in #247), luminantie en deuteranopie, en een GIF van het gevecht.

Maten uit de code en de data (niet overgetikt, maar gelezen): `game/data/vijanden/slice.csv`, groep
`gemaalmeester` (lichaam 252-348, schot 276-324 x 12-60, merkplek (300, 36), rad 96 x 40 op y 100-140,
spuigaten 236 en 364, pompslag 160 x 24, zwiep 300 x 24 op y 36-60, alle tijden in ticks).

Eigen werk (docs/licenties.md §2): palet, figuren en helpers komen uit de R5-scène en slice deel 1-5.
Draaien vanaf de repo-root (deel 1-5 hoeven niet opnieuw):
    python3 docs/art/slice/bron/genereer_gemaalmeester.py
Het script print de metingen voor docs/art/animatie-timing.md.
"""
import csv
import json
import math
import os
import sys

import numpy as np
from PIL import Image
from scipy import ndimage

HIER = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HIER)
import genereer_slice_deel5 as D5  # noqa: E402  (S8, palet, figuren; draait zelf niets)

D2, D1, R, SP = D5.D2, D5.D1, D5.R, D5.SP
MI, K, STAAT = D1.MI, D1.K, D1.STAAT
REPO = D1.REPO
UIT_GAME = os.path.join(REPO, "game", "art", "animatie", "gemaalmeester")
UIT_DOCS = os.path.join(REPO, "docs", "art", "slice", "eindkwaliteit")
os.makedirs(UIT_GAME, exist_ok=True)
STATEN = ["grijs", "half", "kleur"]


# ------------------------------------------------------------------ data uit het spel
def lees_data():
    d = {}
    with open(os.path.join(REPO, "game", "data", "vijanden", "slice.csv")) as f:
        for row in csv.reader(f):
            if len(row) >= 3 and row[0] == "gemaalmeester":
                d[row[1]] = float(row[2])
    return d


GM = lees_data()
LX1, LX2 = GM["lichaam_x1"], GM["lichaam_x2"]                  # 252, 348
MX = (LX1 + LX2) / 2                                             # 300: het midden (middle())
SX1, SX2, SY1, SY2 = GM["schot_x1"], GM["schot_x2"], GM["schot_y1"], GM["schot_y2"]
MPX, MPY = GM["merkplek_x"], GM["merkplek_y"]
RAD_W, RAD_Y1, RAD_Y2 = GM["rad_breedte"], GM["rad_y1"], GM["rad_y2"]
RAD_YC = (RAD_Y1 + RAD_Y2) / 2                                    # 120
SPUI = (GM["spuigat_links"], GM["spuigat_rechts"])
POMP_W, POMP_H = GM["pomp_breedte"], GM["pomp_hoogte"]
ZW_W, ZW_Y1, ZW_Y2 = GM["zwiep_breedte"], GM["zwiep_y1"], GM["zwiep_y2"]
ARENA_W = GM["arena_breedte"]
D = 60
LICHAAM_H = 160                                                   # GM-02 en `_build_visual` (Rect2(x1, -160, ...))
BALK_ONDER = 158                                                  # S8: de balk ligt op 158-168 boven de vloer (deel 5)
TICKS = {k: int(v) for k, v in GM.items() if k.endswith(("aanloop", "actief", "herstel", "_ticks", "gloei",
                                                         "inactief", "tril", "draai"))}

# cellen: (breedte, hoogte, arena-x van kolom 0, arena-y van de bovenkant van rij 0)
CEL_LICHAAM = (128, 176, MX - 64, 176)                            # x 236-364, y 0-176
CEL_KETEL = (64, 64, MX - 32, 68)                                 # x 268-332, y 4-68
CEL_RAD = (112, 72, -56, RAD_YC + 44)                             # rond het middelpunt: y 92-164
CEL_POMP = (176, 40, -8, 36)                                      # rond het vlak (x1 - 8 ... x1 + 168), y -4..36
CEL_ZWIEP = (int(ZW_W), 40, 0, 70)                                # x 0-300 (links), y 30-70
CEL_SPUI = (24, 32, -12, 20)                                      # rond het spuigat, y -12..20


# ------------------------------------------------------------------ een cel als (materiaal, tint)
class Cel:
    """Een frame als (materiaal, tint) in arena-coördinaten (x naar rechts, y omhoog vanaf de vloer).
    `solid` = deel van het silhouet (krijgt contour en bovenrand); stoom, water en licht niet."""

    def __init__(self, cel, dx=0.0):
        self.w, self.h, self.x0, self.ytop = cel
        self.x0 += dx
        self.mat = np.full((self.h, self.w), -1, np.int16)
        self.t = np.zeros((self.h, self.w), np.int16)
        self.solid = np.zeros((self.h, self.w), bool)
        self.lijf = np.zeros((self.h, self.w), bool)          # vijandlijf: daar komt de bovenrand op
        rr, cc = np.mgrid[0:self.h, 0:self.w]
        self.X = self.x0 + cc + 0.5
        self.Y = self.ytop - rr - 0.5
        self.BAY = R.bayer(self.h, self.w)

    def put(self, m, mat, t, solid=True, lijf=None):
        self.mat[m] = MI[mat]
        self.t[m] = np.clip(t, 0, 7) if np.ndim(t) == 0 else np.clip(t[m], 0, 7)
        self.solid[m] = solid
        self.lijf[m] = (mat == "vijandlijf") if lijf is None else lijf

    def wis(self, m):
        self.mat[m] = -1
        self.solid[m] = False
        self.lijf[m] = False

    def ell(self, cx, cy, rx, ry):
        return ((self.X - cx) / rx) ** 2 + ((self.Y - cy) / ry) ** 2 < 1

    def rect(self, x0, y0, x1, y1):
        return (self.X >= x0) & (self.X < x1) & (self.Y >= y0) & (self.Y < y1)

    def seg(self, p, q, w):
        px, py = p
        qx, qy = q
        vx, vy = qx - px, qy - py
        L2 = max(vx * vx + vy * vy, 1e-6)
        u = np.clip(((self.X - px) * vx + (self.Y - py) * vy) / L2, 0, 1)
        return np.hypot(self.X - (px + u * vx), self.Y - (py + u * vy)) <= w / 2

    def schijf(self, cx, cy, r):
        return np.hypot(self.X - cx, self.Y - cy) <= r

    def afwerken(self, dk=True, bovenrand=True):
        """Bible §6 en deel 1 §4.2: contour 1 px bijna-zwart rond het silhouet; bovenrand van 2 px op het
        lijf (gloeiende lijn in vijandkern 7, rood eronder: 5 in het donker, 4 verlicht)."""
        s = self.solid.copy()
        if bovenrand:
            boven = np.vstack([np.zeros((1, self.w), bool), s[:-1]])
            top = s & ~boven & self.lijf
            onder = np.vstack([np.zeros((1, self.w), bool), top[:-1]]) & s & ~top & (self.mat == MI["vijandlijf"])
            self.put(onder, "vijandkern", 5 if dk else 4)
            self.put(top, "vijandkern", 7)
        cont = ndimage.binary_dilation(s) & ~s & (self.mat < 0)
        self.mat[cont] = MI["vijandlijf"]
        self.t[cont] = 0
        return self

    def render(self, staat):
        """Het lichaam, het schot, het rad en de stangen zijn een figuur: ze houden hun kleur in elke toestand
        (bible §4.1.5, deel 1 §4.2 regel 2). Water en stoom volgen de toestand van de wijk; de kern en de
        bovenrand gloeien in het donker een tint feller (VJ-06, al in de tinten)."""
        ramp = STAAT[staat]
        out = np.zeros((self.h, self.w, 4))
        ok = self.mat >= 0
        ti = np.clip(self.t, 0, 7)
        fig = ok & np.isin(self.mat, FIGUUR)
        rest = ok & ~fig
        out[fig, :3] = K[self.mat[fig], ti[fig]]
        out[rest, :3] = ramp[self.mat[rest], ti[rest]]
        out[ok, 3] = 1
        return out


FIGUUR = [MI[m] for m in ("vijandlijf", "vijandkern", "roest", "ijzer", "hout", "gloed")]


def stoom(c, cx, cy, r, seed, dicht=0.55):
    """Grijze stoom (nooit FelLicht, GMB-06): een gedithered wolkje in `huis_wit` (deel 1 §4.4)."""
    rg = np.random.default_rng(int(seed))
    m = np.zeros_like(c.solid)
    for _ in range(4):
        ox, oy = rg.uniform(-r * 0.6, r * 0.6), rg.uniform(-r * 0.3, r * 0.5)
        rr = r * rg.uniform(0.45, 0.8)
        m |= np.hypot(c.X - cx - ox, (c.Y - cy - oy) * 1.2) < rr
    kern = m & (c.BAY < dicht)
    rand = ndimage.binary_dilation(m, iterations=1) & ~m & (c.BAY < dicht * 0.45)
    vrij = c.mat < 0
    c.put(kern & vrij, "huis_wit", 4, solid=False)
    c.put(rand & vrij, "huis_wit", 3, solid=False)
    c.put(kern & vrij & (c.BAY < dicht * 0.3) & (c.Y > cy), "huis_wit", 6, solid=False)


# ------------------------------------------------------------------ het lichaam
RUST_L, RUST_R = (246.0, 30.0), (354.0, 30.0)                       # handen in rust (de stangen hangen)


def pose(**kw):
    p = dict(dx=0, dy=0, hl=RUST_L, hr=RUST_R, wl=(0, 0), wr=(0, 0), ogen="open", rook=0, seed=0,
             stof=None, smear=None, scheef=0, scheur=0, oplos=0.0, klap=None)
    p.update(kw)
    return p


def schoepenwiel(c, cx, cy, fase, snel, dk):
    """Het schoepenwiel aan de zijkant van de ketel (de schoepen van GM-02): ijzeren velg, houten schoepen.
    `snel` > 0: opgedraaid (de schoepen als vegen, geen transparantie)."""
    r = 13
    d = np.hypot(c.X - cx, c.Y - cy)
    a = np.arctan2(c.Y - cy, c.X - cx)
    n = 6 if snel == 0 else 12
    hoek = (a - fase) % (2 * np.pi / n)
    schoep = (d < r + 3) & (d > 4) & ((hoek < 0.22) if snel < 2 else (hoek < 0.45))
    c.put(schoep, "hout", 3 if snel < 2 else 4)
    c.put(schoep & (d > r), "hout", 5)
    c.put((np.abs(d - r + 2) < 1.3), "ijzer", 3)
    c.put(d < 4, "ijzer", 4)
    c.put(d < 1.6, "vijandkern", 5 if dk else 4)


def stang(c, schouder, hand, dk, smear=None):
    """De drijfstang (GM-02): een ijzeren stang met een oog bij de schouder en een kruiskop als hand."""
    if smear is not None:                                            # veeglijnen van de uithaal (geen transparantie)
        for i, (sx, sy) in enumerate(smear):
            m = c.seg(schouder, (sx, sy), 1.0) & (c.mat < 0) & ((c.BAY > 0.5) if i % 2 else (c.BAY <= 0.5))
            c.put(m, "huis_wit", 3, solid=False)
    c.put(c.seg(schouder, hand, 5), "ijzer", 2)
    c.put(c.seg((schouder[0], schouder[1] + 1), (hand[0], hand[1] + 1), 2), "ijzer", 4)
    c.put(c.schijf(*schouder, 4.5), "ijzer", 3)
    c.put(c.schijf(*schouder, 1.6), "ijzer", 6)
    hx, hy = hand
    kop = c.rect(hx - 6, hy - 5, hx + 6, hy + 5)
    c.put(kop, "ijzer", 3)
    c.put(kop & (c.Y >= hy + 3), "ijzer", 5)
    c.put(kop & (c.Y < hy - 3), "ijzer", 1)
    c.put(c.rect(hx - 1, hy - 1, hx + 1, hy + 1), "vijandkern", 5 if dk else 4)


def lijf_vorm(c, m, cx, cy, rx, ry, basis=2):
    """Vorm in tinten op een rond lijfdeel: onder donker, boven een tint lichter, binnenrand licht."""
    v = (c.Y - cy) / ry
    u = (c.X - cx) / rx
    t = np.full(c.mat.shape, basis)
    t = np.where(v < -0.45, basis - 1, t)
    t = np.where((v > 0.35) & (np.abs(u) < 0.7), basis + 1, t)
    c.put(m, "vijandlijf", t)
    rand = m & ~ndimage.binary_erosion(m) & (v > -0.6)
    c.put(rand, "vijandlijf", basis + 2)


def lichaam(p, staat):
    dk = staat != "kleur"
    c = Cel(CEL_LICHAAM)
    dx, dy = p["dx"], p["dy"]
    sk = p["scheef"]                                                  # Wankel: één schouder zakt
    # --- 1. schoorsteen (achter de linkerschouder), met stoom erboven
    sx = 270 + dx
    c.put(c.rect(sx - 5, 112 + dy, sx + 5, 150 + dy - max(0, sk)), "vijandlijf", 2)
    c.put(c.rect(sx - 5, 112 + dy, sx - 3, 150 + dy - max(0, sk)), "vijandlijf", 4)
    c.put(c.rect(sx - 7, 148 + dy - max(0, sk), sx + 7, 154 + dy - max(0, sk)), "vijandlijf", 3)
    for by in (122, 136):
        c.put(c.rect(sx - 5, by + dy, sx + 5, by + 2 + dy), "ijzer", 3)
    if p["rook"]:
        n = p["rook"]
        for i in range(n):
            stoom(c, sx + (i % 2) * 3 - 1, 160 + dy + i * 6, 4 + i * 1.5, p["seed"] * 7 + i, dicht=0.6 - 0.12 * i)
    # --- 2. de schoepenwielen achter de ketel
    for kant, (fase, snel) in ((-1, p["wl"]), (1, p["wr"])):
        uit = 6 if snel >= 1 else 0
        schoepenwiel(c, MX + kant * (44 + uit), 48, fase, snel, dk)
    # --- 3. sokkel (fundament): ijzer met bouten
    sok = c.rect(LX1 + 2, 0, LX2 - 2, 9)
    c.put(sok, "ijzer", 2)
    c.put(sok & (c.Y >= 7), "ijzer", 4)
    c.put(sok & (c.Y < 2), "ijzer", 1)
    c.put(sok & (np.abs(c.Y - 4.5) < 1) & (((c.X - LX1) % 12) < 2), "ijzer", 6)
    # --- 4. de ketel (romp): rond, met klinknagelbanden, en de nis van het schot
    ket = c.ell(MX, 46, 44, 40) & (c.Y >= 8)
    lijf_vorm(c, ket, MX, 46, 44, 40)
    for by in (24, 70):
        band = ket & (np.abs(c.Y - by) < 1.5)
        c.put(band, "vijandlijf", 4)
        c.put(band & (((c.X - MX) % 7) < 1.2) & (np.abs(c.Y - by) < 0.8), "vijandlijf", 6)
    nis = c.rect(SX1 - 3, SY1 - 3, SX2 + 3, SY2 + 3)
    c.put(nis, "ijzer", 1)
    c.put(c.rect(SX1 - 3, SY2 + 1, SX2 + 3, SY2 + 3), "ijzer", 3)
    c.put(c.rect(SX1, SY1, SX2, SY2), "vijandlijf", 0)                 # het gat: schot of kern komt erop (ketel)
    # drukleidingen langs de ketel en een manometer op de borst (Lage Landen: een gemaal, geen robot)
    for kant in (-1, 1):
        px = MX + kant * 33
        c.put(ket & (np.abs(c.X - px) < 2) & (c.Y > 14) & (c.Y < 66), "ijzer", 2)
        c.put(ket & (np.abs(c.X - px - kant) < 0.6) & (c.Y > 14) & (c.Y < 66), "ijzer", 4)
        for fy in (20, 44):
            c.put(ket & (np.abs(c.X - px) < 3) & (np.abs(c.Y - fy) < 1), "ijzer", 5)
    gx, gy = MX + 20, 72
    g = np.hypot(c.X - gx, c.Y - gy)
    c.put(g < 5, "ijzer", 4)
    c.put(g < 3.8, "vijandlijf", 6)
    naald = c.seg((gx, gy), (gx - 2 + p["dy"], gy + 3), 1.0) & (g < 3.8)
    c.put(naald, "vijandkern", 5 if dk else 4)
    for (mx, my) in ((MX - 32, 30), (MX + 32, 30), (MX - 34, 56), (MX + 34, 56)):
        c.put(c.schijf(mx, my, 1.2), "vijandlijf", 6)
    # --- 5. schouders en nek (gebogen: de kop hangt lager dan de schouders)
    sch = (c.ell(MX + dx - 22, 98 + dy - sk, 20, 18) | c.ell(MX + dx + 22, 98 + dy + sk, 20, 18)
           | c.ell(MX + dx, 92 + dy, 34, 12))
    lijf_vorm(c, sch & ~ket | (sch & (c.Y > 80)), MX + dx, 98 + dy, 42, 20)
    c.put(sch & (np.abs(c.Y - (88 + dy)) < 1) & (np.abs(c.X - MX - dx) < 26), "vijandlijf", 4)
    # klinknagels op de schouderplaten
    for kx in (-30, -20, 20, 30):
        c.put(c.schijf(MX + dx + kx, 104 + dy + (-sk if kx < 0 else sk), 1.1), "vijandlijf", 6)
    # --- 6. de kop: een stoomkap met een vizier en twee doffe ogen (geen tanden, verhaal §6)
    kx, ky = MX + dx + (sk * 0.5), 117 + dy - 2 * abs(sk)
    nek = c.rect(kx - 7, ky - 12, kx + 7, ky)
    c.put(nek, "ijzer", 2)
    c.put(nek & (((c.Y - ky) % 3) < 1), "ijzer", 4)
    kop = c.ell(kx, ky, 13, 11)
    lijf_vorm(c, kop, kx, ky, 15, 11, basis=3)
    c.put(c.rect(kx - 1.5, ky + 10, kx + 1.5, ky + 14), "ijzer", 4)    # ventiel
    c.put(c.rect(kx - 3, ky + 13, kx + 3, ky + 15), "ijzer", 5)
    viz = c.rect(kx - 11, ky - 3, kx + 11, ky + 2)
    c.put(viz, "vijandlijf", 1)
    ogen = p["ogen"]
    for ox in (-6, 6):
        if ogen in ("open", "wijd"):
            h = 3 if ogen == "wijd" else 2
            c.put(c.rect(kx + ox - 1, ky - 1, kx + ox + 1, ky - 1 + h), "vijandkern", 7, lijf=False)
            # doffe ogen: een ooglid erover (de bovenste rij van het oog dicht)
            if ogen == "open":
                c.put(c.rect(kx + ox - 2, ky, kx + ox + 2, ky + 1), "vijandlijf", 4)
        elif ogen == "half":
            c.put(c.rect(kx + ox - 1, ky - 1, kx + ox + 1, ky), "vijandkern", 7, lijf=False)
        else:                                                           # dicht: een streep
            c.put(c.rect(kx + ox - 2, ky - 1, kx + ox + 2, ky), "vijandlijf", 5)
    # --- 7. de drijfstangen (armen)
    stang(c, (MX + dx - 36, 98 + dy - sk), p["hl"], dk, p["smear"] if p["klap"] == "l" else None)
    stang(c, (MX + dx + 36, 98 + dy + sk), p["hr"], dk, p["smear"] if p["klap"] == "r" else None)
    # --- 8. stof en stoom van een inslag (geen silhouet)
    if p["stof"] is not None:
        x, n = p["stof"]
        for i in range(n):
            stoom(c, x + (i - n / 2) * 6, 4 + (i % 2) * 3, 4 + (i % 3), p["seed"] * 13 + i, dicht=0.5)
    c.afwerken(dk)
    # --- 9. oplossen in licht (GM-10): warme scheuren, dan stijgt het lijf weg als lichtdeeltjes
    if p["oplos"] > 0:
        oplossen(c, p["oplos"], p["seed"])
    return c


def oplossen(c, k, seed):
    """GM-10: hij lost op in licht (de ramp `gloed`: het licht dat hij vasthield). k = 0..1."""
    ok = c.mat >= 0
    rg = np.random.default_rng(seed)

    def rang(a):
        r = np.empty(a.size)
        r[np.argsort(a, axis=None)] = np.linspace(0, 1, a.size)
        return r.reshape(a.shape)
    ruis = rang(ndimage.uniform_filter(rg.random(c.mat.shape), 3))
    aders = rang(ndimage.uniform_filter(rg.random(c.mat.shape), 7))
    naad = ok & (np.abs(aders - 0.5) < 0.015 + 0.07 * k)          # warme aders: iso-lijnen van ruis, organisch
    c.put(naad, "gloed", 5 + int(k > 0.3) + int(k > 0.6), solid=False)
    weg = ok & (ruis * 0.8 + (c.Y - c.Y.min()) / max(1.0, float(np.ptp(c.Y))) * 0.2 < (k - 0.3) * 1.45)
    stip = weg & (rg.random(c.mat.shape) < 0.03 + 0.09 * (1 - k))
    c.wis(weg)
    # de deeltjes stijgen: een stip boven elke weggevallen kolom
    sh = int(4 + 12 * k)
    lift = np.vstack([stip[sh:], np.zeros((sh, c.w), bool)])
    c.put(lift & (c.mat < 0), "gloed", 7 if k < 0.8 else 6, solid=False)
    c.put(ok & ~weg & (c.mat >= 0) & (c.mat != MI["gloed"]) & (k > 0.55) & (c.BAY < (k - 0.55) * 1.5), "gloed", 4,
          solid=False)


# ------------------------------------------------------------------ de poses (per animatie)
def boog(a, b, k):
    return (a[0] + (b[0] - a[0]) * k, a[1] + (b[1] - a[1]) * k)


def spiegel_hand(h):
    return (2 * MX - h[0], h[1])


def pomp_poses(kant):
    """Pompslag (GM-05a) naar `kant` (-1 links, +1 rechts): de stang heft zich naar die helft (aanloop in 4
    stappen, het lijf leunt weg: anticipation), een uithaal (de laatste 3 ticks), dan de slag op de vloer:
    het verste frame valt op het actieve vlak (combat §9)."""
    def hand(h):
        return h if kant < 0 else spiegel_hand(h)

    def p(**kw):
        kw2 = dict(kw)
        if "h" in kw2:
            h = hand(kw2.pop("h"))
            if kant < 0:
                kw2["hl"] = h
            else:
                kw2["hr"] = h
            kw2["klap"] = "l" if kant < 0 else "r"
        return pose(**kw2)
    heft = [(244, 58), (242, 92), (246, 124), (252, 146)]
    aanloop = [p(h=h, dx=-kant * (i + 1) // 2, dy=i // 2, rook=1 + i // 2, seed=i, ogen="open") for i, h in enumerate(heft)]
    uithaal = p(h=(240, 52), dx=kant * 1, dy=0, rook=2, seed=5, smear=[hand((250, 140)), hand((244, 110)), hand((240, 80))])
    slag = [p(h=(239, 5), dx=kant * 2, dy=-2, stof=(hand((240, 0))[0], 4), seed=6 + i, rook=1) for i in range(2)]
    ligt = [p(h=(239, 5), dx=kant * 2, dy=-2, stof=(hand((240, 0))[0], 2), seed=8, rook=1)]
    terug = [p(h=(242, 18), dx=kant, dy=-1, seed=9), p(h=(245, 26), seed=10)]
    return aanloop + [uithaal], slag, ligt, terug


def zwiep_poses(kant):
    """Schoepenzwiep (GM-05b) naar `kant`: het schoepenwiel aan die kant draait op en schuift uit, de stang
    gaat naar achteren; de veeg (het verste frame) valt op de 8 actieve ticks."""
    def hand(h):
        return h if kant < 0 else spiegel_hand(h)

    def p(wiel, h, **kw):
        kw = dict(kw)
        if kant < 0:
            kw["wl"], kw["hl"] = wiel, hand(h)
        else:
            kw["wr"], kw["hr"] = wiel, hand(h)
        return pose(**kw)
    aanloop = [p((0.3 * i, 0 if i < 2 else 1), (248 + i * 2, 36 + i * 9), dx=kant * (i + 1) // 2, rook=i // 2, seed=20 + i)
               for i in range(4)]
    uithaal = p((1.1, 2), (254, 70), dx=kant * 2, dy=1, rook=2, seed=25)
    veeg = [p((0.2 * i, 2), (238, 48), dx=-kant * 2, dy=-1, rook=1, seed=26 + i) for i in range(2)]
    uit = [p((0.5, 1), (242, 40), dx=-kant, seed=28), p((0.9, 0), (245, 32), seed=29)]
    return aanloop + [uithaal], veeg, uit


def aarzel_poses(kant):
    """De allereerste aanloop (60 ticks, GM-04): hij aarzelt als hij de sjaal van de machinist ziet. De kop
    zakt naar de kant van P1, de ogen gaan open (wijd), de stang aan die kant reikt half (geen slag)."""
    def hand(h):
        return h if kant < 0 else spiegel_hand(h)
    hs = [(246, 34), (240, 50), (238, 56)]
    out = []
    for i, h in enumerate(hs):
        kw = dict(dx=kant * (1 + i), dy=-i, ogen="wijd" if i else "open", seed=40 + i)
        if kant < 0:
            kw["hl"] = hand(h)
        else:
            kw["hr"] = hand(h)
        out.append(pose(**kw))
    return out


IDLE = [pose(dy=[0, 0, 1, 1, 1, 0][i], rook=1 + (i % 3 == 0), seed=60 + i, ogen="dicht" if i == 4 else "open",
             wl=(0.1 * i, 0), wr=(-0.1 * i, 0)) for i in range(6)]
FASEWISSEL = [pose(dy=[0, 2, 3, 1][i], rook=3, seed=70 + i, ogen="wijd", hl=(244, 40 + i * 6), hr=(356, 40 + i * 6),
                   wl=(0.5 * i, 1), wr=(-0.5 * i, 1)) for i in range(4)]
WANKEL_IN = [pose(dy=-2, scheef=1, ogen="half", hl=(244, 14), hr=(356, 18), seed=80),
             pose(dy=-4, scheef=2, ogen="half", hl=(243, 6), hr=(357, 9), seed=81)]
WANKEL = [pose(dy=-4 + [0, 1, 0, -1][i], scheef=2 + [0, 0, 1, 0][i], ogen=["half", "half", "dicht", "half"][i],
               hl=(243, 6), hr=(357, 8 + [0, 2, 0, 1][i]), rook=[0, 1, 0, 0][i], seed=90 + i) for i in range(4)]
GERAAKT = [pose(dy=-3, dx=1, scheef=2, ogen="dicht", hl=(243, 8), hr=(357, 10), seed=95),
           pose(dy=-5, dx=-1, scheef=3, ogen="half", hl=(243, 6), hr=(357, 8), seed=96)]
OPLOSSEN = [pose(dy=-4, scheef=2, ogen="dicht" if i < 3 else "half", hl=(243, 6), hr=(357, 8), oplos=0.08 + i * 0.1,
                 seed=100) for i in range(10)]


# ------------------------------------------------------------------ de ketel: schot, kern, merkplek
def ketel(staat, soort, f=0, n=1):
    dk = staat != "kleur"
    c = Cel(CEL_KETEL)
    plaat = c.rect(SX1, SY1, SX2, SY2)
    kc5 = 5 if dk else 4

    def schot(m=plaat, glow=1, gelast=False, dy=0):
        mm = m & c.rect(SX1, SY1 + dy, SX2, SY2 + dy) if dy else m
        c.put(mm, "roest", 3)
        for by in (SY1 + 10, SY1 + 24, SY1 + 38):                       # banden met klinknagels
            band = mm & (np.abs(c.Y - by - dy) < 1.5)
            c.put(band, "roest", 5)
            c.put(band & (((c.X - SX1 - 4) % 8) < 1.3) & (np.abs(c.Y - by - dy) < 0.8), "ijzer", 6)
        c.put(mm & (c.Y >= SY2 + dy - 1), "roest", 6)                    # bovenkant licht
        c.put(mm & (c.X < SX1 + 1), "roest", 1)
        c.put(mm & (c.X >= SX2 - 1), "roest", 2)
        c.put(mm & (c.Y < SY1 + dy + 1), "roest", 1)
        roestvlek = mm & (np.sin(c.X * 0.9) * np.cos(c.Y * 0.7) > 0.82)
        c.put(roestvlek, "roest", 4)
        if gelast:                                                     # fase 2: dicht voor altijd, niet Merkbaar
            c.put(mm, "ijzer", 2)
            c.put(mm & (np.abs(c.Y - MPY) < 3), "ijzer", 4)
            for kx in (SX1 + 6, SX2 - 6):
                c.put(mm & (np.abs(c.X - kx) < 2.5), "ijzer", 4)
                c.put(mm & (np.abs(c.X - kx) < 0.8), "ijzer", 6)
            c.put(mm & (c.Y >= SY2 - 1), "ijzer", 5)
            c.put(mm & (np.abs(c.Y - MPY) < 0.8) & ((c.X % 4) < 2), "ijzer", 6)
        elif glow:                                                     # de naad gloeit: er zit iets achter
            naad = ndimage.binary_dilation(mm, iterations=1) & ~mm & c.rect(SX1 - 1, SY1 - 1, SX2 + 1, SY2 + 1)
            c.put(naad, "vijandkern", 2 + glow, solid=False)

    if soort == "schot":
        schot(glow=1 + (f % 2))
    elif soort == "tink":
        schot(glow=2)
        d = np.hypot(c.X - MX, c.Y - MPY)
        ster = ((np.abs(c.X - MX) < 0.8) & (np.abs(c.Y - MPY) < 7)) | ((np.abs(c.Y - MPY) < 0.8) & (np.abs(c.X - MX) < 9))
        c.put(ster, "huis_wit", 7, solid=False)
        c.put(d < 2, "huis_wit", 7, solid=False)
        c.put(plaat & (c.Y >= SY2 - 1), "huis_wit", 7, solid=False)
    elif soort in ("breuk", "kern", "kern_geraakt", "sluit"):
        # de kern: een gloeiend hart in de ketel (vijandkern, nooit FelLicht; GMB-06)
        d = np.hypot(c.X - MX, (c.Y - MPY) * 1.05)
        puls = {"kern": [0, 1, 2, 1][f % 4], "kern_geraakt": 3, "breuk": f, "sluit": 1}[soort]
        c.put(plaat, "vijandkern", 1, solid=False)
        c.put(plaat & (np.abs(np.sin((c.X - MX) * 0.5)) < 0.35) & (c.Y < MPY - 8), "ijzer", 1, solid=False)   # rooster
        c.put(d < 17 + puls, "vijandkern", kc5 - 1)
        c.put(d < 12 + puls, "vijandkern", kc5 + 1)
        c.put(d < 6 + puls * 0.7, "vijandkern", 7)
        # gescheurde randen van het oude schot rond de opening
        rand = plaat & ~c.rect(SX1 + 3, SY1 + 3, SX2 - 3, SY2 - 3) & (np.sin(c.X * 1.7 + c.Y * 2.3) > -0.2)
        c.put(rand, "roest", 2)
        c.put(rand & (np.sin(c.X * 1.7 + c.Y * 2.3) > 0.6), "roest", 4)
        if soort == "kern_geraakt":
            c.put(d < 22, "vijandkern", 6)
            c.put(d < 14, "vijandkern", 7)
            c.put(np.abs(d - 24) < 1, "huis_wit", 7, solid=False)
        if soort == "kern":
            stoom(c, MX + [-8, -4, 4, 8][f % 4], SY2 + 4 + (f % 2) * 2, 5, 300 + f, dicht=0.45)
        if soort == "breuk":
            # 0: barsten met gloed, 1: het schot springt in stukken, 2: de stukken vallen, stoom
            if f == 0:
                c.wis(plaat)
                schot(glow=3)
                bars = plaat & ((np.abs((c.X - MX) * 0.8 - (c.Y - MPY)) < 0.9) | (np.abs((c.X - MX) * -1.3 - (c.Y - MPY) + 4) < 0.9)
                                | (np.abs(c.Y - MPY - 2 + (c.X - MX) * 0.1) < 0.7) & (np.abs(c.X - MX) < 14))
                c.put(bars, "vijandkern", 7)
                c.put(ndimage.binary_dilation(bars) & ~bars & plaat, "vijandkern", 5)
            else:
                for i, (qx, qy) in enumerate([(-1, 1), (1, 1), (-1, -1), (1, -1)]):
                    off = 6 * f
                    st = c.rect(MX + (min(qx, 0)) * 24 + qx * off, MPY + min(qy, 0) * 24 + qy * off * 0.6 - (f - 1) * 8,
                                MX + (max(qx, 0)) * 24 + qx * off, MPY + max(qy, 0) * 24 + qy * off * 0.6 - (f - 1) * 8)
                    st &= (np.sin(c.X * 0.8 + i) + np.cos(c.Y * 0.9) > -1.2)
                    c.put(st, "roest", 3)
                    c.put(st & ~ndimage.binary_erosion(st), "roest", 5)
                stoom(c, MX - 10, MPY + 18, 7, 400 + f, dicht=0.6)
                stoom(c, MX + 12, MPY + 22, 6, 410 + f, dicht=0.5)
        if soort == "sluit":
            # een nieuw schot schuift van boven voor de kern (3 frames; f = 0..2)
            dy = int((2 - f) * 16)
            m = c.rect(SX1, SY1 + dy, SX2, SY2 + dy) & plaat
            c.wis(m)
            schot(m=m, glow=0, dy=dy)
            if f < 2:
                c.put(c.rect(SX1 - 2, SY1 + dy - 1, SX2 + 2, SY1 + dy) & plaat, "roest", 1)
    elif soort == "dicht":
        schot(gelast=True)
    elif soort in ("merkplek_open", "merkplek"):
        schot(gelast=True)
        # de merkplek van Wankel (GMB-05): een rode peilmerk-ring met een streep, tot het merk erop staat
        d = np.hypot(c.X - MPX, c.Y - MPY)
        r = {0: 3, 1: 5, 2: 7}.get(f, 7) if soort == "merkplek_open" else 7
        c.put(d < r + 2, "vijandlijf", 0)
        c.put(np.abs(d - r) < 1.0, "vijandkern", 7 if (soort == "merkplek" and f == 1) else 6)
        c.put((np.abs(c.Y - MPY) < 0.7) & (d < r + 3), "vijandkern", kc5 + 1)
        c.put((np.abs(d - r - 1.6) < 0.6) & (c.BAY < 0.5), "vijandkern", kc5, solid=False)
        if soort == "merkplek_open" and f == 0:
            for kx in (SX1 + 6, SX2 - 6):                              # de klemmen vallen weg
                c.wis(plaat & (np.abs(c.X - kx) < 2.5) & (c.Y > SY1 + 20))
    c.afwerken(dk, bovenrand=False)
    return c


# ------------------------------------------------------------------ het grote rad
def rad(staat, f=0, scheur=0, soort="draai", oplos=0.0):
    """Het grote rad (GMB-04): een liggend kaapstanderrad (het pomprad van Ward en de leerling), van onder
    gezien: velg, zes spaken (hout), naaf met de rode as, aan een ketting naar de loopkat op de balk.
    Hurtbox 96 x 40 op y 100-140: de velg vult hem. Draait in zijn vlak: 8 frames van 7,5 graden."""
    dk = staat != "kleur"
    jit = (1 if f % 2 else -1) if soort == "trilt" else 0
    c = Cel(CEL_RAD, dx=-jit)
    cx, cy = 0.0, RAD_YC + 2
    rx, ry = RAD_W / 2, 18.0
    th0 = math.radians(7.5 * (f % 8)) if soort == "draai" else math.radians(7.5 * 3)
    # loopkat en ketting (ze schuiven mee over de balk)
    lk = c.rect(-10, BALK_ONDER - 7, 10, BALK_ONDER)
    c.put(lk, "ijzer", 3)
    c.put(lk & (c.Y >= BALK_ONDER - 2), "ijzer", 5)
    for wx in (-7, 7):
        c.put(c.schijf(wx, BALK_ONDER + 0.5, 2.6), "ijzer", 4)
        c.put(c.schijf(wx, BALK_ONDER + 0.5, 0.9), "ijzer", 6)
    for i, yy in enumerate(range(int(cy + 8), int(BALK_ONDER - 7), 3)):
        ring = c.rect(-1.5 + (i % 2) * 0.5, yy, 1.5 - (i % 2) * 0.5, yy + 3) & ~c.rect(-0.5, yy + 1, 0.5, yy + 2)
        c.put(ring, "ijzer", 4 if i % 2 else 3)
    # de as steekt boven de naad uit (rood: hier zit het; deel 1 §4.4)
    c.put(c.rect(-2, cy, 2, cy + 9), "vijandkern", 4 if not dk else 5)
    c.put(c.rect(-2, cy + 7, 2, cy + 9), "ijzer", 4)
    # velg: buitenste ellips, met de dikte van de rand naar onder (je kijkt er van onder tegen)
    e = np.hypot((c.X - cx) / rx, (c.Y - cy) / ry)
    e_onder = np.hypot((c.X - cx) / rx, (c.Y - cy + 4) / ry)
    dikte = (e_onder < 1) & (e >= 0.82) & (c.Y < cy)
    c.put(dikte, "hout", 2)
    c.put(dikte & (np.abs(e_onder - 0.97) < 0.03), "hout", 1)
    velg = (e < 1) & (e >= 0.8)
    c.put(velg, "hout", 4)
    c.put(velg & (e > 0.93), "hout", 3)
    c.put(velg & (np.abs(e - 0.86) < 0.025), "hout", 5)
    a = np.arctan2((c.Y - cy) / ry, (c.X - cx) / rx)
    # ijzeren beslag op de velg (bouten om de 30 graden: periode past in 8 frames)
    beslag = velg & (np.abs(((a - th0 + np.pi / 12) % (np.pi / 6)) - np.pi / 12) < 0.06)
    c.put(beslag, "ijzer", 4)
    c.put(beslag & (np.abs(e - 0.9) < 0.03), "ijzer", 6)
    # spaken
    for k in range(6):
        ang = th0 + k * math.pi / 3
        p = (cx + 0.82 * rx * math.cos(ang), cy + 0.82 * ry * math.sin(ang))
        sp = c.seg((cx, cy), p, 3.2) & (e < 0.84)
        c.put(sp, "hout", 3 if math.sin(ang) < 0 else 5)
        c.put(c.seg((cx, cy), p, 1.2) & (e < 0.84), "hout", 4 if math.sin(ang) < 0 else 6)
    # naaf
    c.put(np.hypot((c.X - cx) / 9, (c.Y - cy) / 5) < 1, "ijzer", 3)
    c.put(np.hypot((c.X - cx) / 9, (c.Y - cy) / 5) < 0.6, "ijzer", 5)
    c.put(np.hypot((c.X - cx) / 3, (c.Y - cy) / 2) < 1, "vijandkern", 6 if not dk else 7)
    # scheuren (UX §9.2: het rad scheurt per kant): 6-voudig, zodat ze meedraaien zonder te verspringen
    if scheur:
        for k in range(6):
            ang = th0 + k * math.pi / 3 + math.pi / 6
            lengte = [0, 0.06, 0.12, 0.2][scheur]
            m = (np.abs(((a - ang + np.pi) % (2 * np.pi)) - np.pi) < 0.035) & (e > 0.8) & (e < 0.8 + lengte * 1.4)
            c.put(m, "vijandlijf", 1)
            if scheur >= 2:
                c.put(m & (e < 0.86), "vijandkern", 5 if dk else 4)
            if scheur == 3 and k % 2 == 0:
                hap = (np.abs(((a - ang + np.pi) % (2 * np.pi)) - np.pi) < 0.12) & (e > 0.95) & (e < 1.0)
                c.wis(hap)
    c.lijf[:] = c.mat >= 0
    c.lijf &= c.rect(-RAD_W, cy - 2, RAD_W, cy + 30)                    # bovenrand alleen op de velg, niet op de ketting
    c.lijf &= ~c.rect(-12, cy + 6, 12, BALK_ONDER + 4)
    c.afwerken(dk)
    if soort == "treffer":
        rand = (np.abs(e - 1.0) < 0.06) & (c.Y > cy - 4)
        c.put(rand, "huis_wit", 7)
        vonk = ((np.abs(c.X - 18 * (1 if f else -1)) < 0.7) & (np.abs(c.Y - cy - 16) < 6)) | \
               ((np.abs(c.Y - cy - 16) < 0.7) & (np.abs(c.X - 18 * (1 if f else -1)) < 6))
        c.put(vonk & (c.mat < 0), "huis_wit", 7, solid=False)
        c.put(velg & (c.BAY < 0.25 + 0.25 * (1 - f)), "vijandkern", 7)
    if soort == "trilt":
        # de tell van het wegdraaien: het rad ratelt (veeglijnen aan de zijkant), de as gloeit fel
        for s in (-1, 1):
            m = (np.abs(c.X - s * (rx + 3)) < 0.6) & (np.abs(c.Y - cy - (f * 2 - 1) * 3) < 5)
            c.put(m & (c.mat < 0), "huis_wit", 5, solid=False)
            m2 = (np.abs(c.X - s * (rx + 6)) < 0.6) & (np.abs(c.Y - cy + (f * 2 - 1) * 2) < 3)
            c.put(m2 & (c.mat < 0), "huis_wit", 4, solid=False)
        c.put(np.hypot((c.X - cx) / 4, (c.Y - cy) / 3) < 1, "vijandkern", 7)
    if oplos > 0:
        oplossen(c, oplos, 77)
    return c


# ------------------------------------------------------------------ effecten
def pomp_effect(staat, soort, f):
    """De pompslag (GM-05a): de drijfstang perst water door de leidingen onder de vloer, en de vloerplaten
    op het vlak (160 x 24) barsten open. Aanloop: de platen ratelen en er sijpelt stoom uit de voegen
    (de stofstrook van combat §3.4, die feller wordt); actief: platen omhoog en een waterwand van 24 px."""
    c = Cel(CEL_POMP)
    W = POMP_W
    in_vlak = (c.X >= 0) & (c.X < W)
    plaat_x = (c.X % 40)
    if soort == "aanloop":
        rammel = in_vlak & (c.Y >= 0) & (c.Y < 1 + (f >= 2)) & ((plaat_x < 38) & (((c.X // 40) + f) % 2 == 0))
        c.put(rammel, "ijzer", 4, solid=False)
        c.put(rammel & (plaat_x < 2), "ijzer", 6, solid=False)
        for i in range(1 + f):
            x = 20 + 40 * (i % 4) + (i // 4) * 10
            stoom(c, x, 2 + f * 1.5, 3 + f, 500 + f * 10 + i, dicht=0.35 + 0.08 * f)
    elif soort == "actief":
        rg = np.random.default_rng(600 + f)
        kolom = in_vlak & (c.Y >= 0) & (c.Y < POMP_H)
        golf = POMP_H - 3 + 3 * np.sin(c.X * 0.35 + f * 2.1)
        wand = kolom & (c.Y < golf)
        c.put(wand & (c.BAY < 0.5), "water", 4, solid=False)
        c.put(wand & (c.BAY >= 0.5), "water", 3, solid=False)
        c.put(kolom & (np.abs(c.Y - golf) < 1.0), "water", 7, solid=False)
        c.put(wand & (np.abs(np.sin(c.X * 0.9 + c.Y * 0.2 + f)) < 0.08), "water", 6, solid=False)
        for i in range(4):                                               # de platen, omhoog geslagen
            px = 4 + i * 40 + rg.integers(0, 6)
            py = 10 + rg.integers(0, 10)
            sl = (c.X >= px) & (c.X < px + 30) & (np.abs(c.Y - py - (c.X - px) * (0.15 if i % 2 else -0.15)) < 1.6)
            c.put(sl, "ijzer", 3)
            c.put(sl & (c.Y > py), "ijzer", 5)
        for x in (0, W):
            stoom(c, x + (-4 if x == 0 else 4), 10, 6, 620 + f + x, dicht=0.5)
        c.afwerken(staat != "kleur", bovenrand=False)
    else:                                                                # herstel: het water valt terug
        h = [14, 7, 3][f]
        val = in_vlak & (c.Y >= 0) & (c.Y < h) & (c.BAY < 0.5 - 0.12 * f)
        c.put(val, "water", 4 - f // 2, solid=False)
        c.put(in_vlak & (np.abs(c.Y - h) < 0.8) & ((c.X // 3) % 2 == 0), "water", 6, solid=False)
        for i in range(3 - f):
            stoom(c, 30 + i * 50, 6 + f * 3, 5, 640 + f * 5 + i, dicht=0.45 - 0.1 * f)
    return c


def zwiep_effect(staat, soort, f):
    """De schoepenzwiep (GM-05b), naar links (rechts = gespiegeld): de schoepen slingeren een waterwaaier over
    de helft, op 36-60 px. De wand vult het vlak al op het eerste actieve frame (het verste frame)."""
    c = Cel(CEL_ZWIEP)
    W = ZW_W
    band = (c.Y >= ZW_Y1) & (c.Y < ZW_Y2) & (c.X >= 0) & (c.X < W)
    if soort == "aanloop":
        # de waaier begint bij het lichaam (x 250-300): druppels (alleen het late deel van de aanloop)
        rg = np.random.default_rng(700 + f)
        for _ in range(10 + 8 * f):
            x, y = W - rg.uniform(0, 40 + 30 * f), rg.uniform(ZW_Y1 + 2, ZW_Y2 - 2)
            c.put(c.rect(x, y, x + 2 + f, y + 1), "water", 5 + (rg.random() < 0.3), solid=False)
    elif soort == "actief":
        # strepen die naar de muur toe dunner worden; een spat tegen de muur (x 0)
        rg = np.random.default_rng(720 + f)
        dicht = 0.55 + 0.35 * (c.X / W)
        rij = ((c.Y - ZW_Y1 + f) % 4 < 2)
        streep = band & rij & (c.BAY < dicht)
        c.put(streep, "water", 4, solid=False)
        c.put(band & ~rij & (c.BAY < dicht * 0.5), "water", 3, solid=False)
        for _ in range(40):
            x = rg.uniform(0, W - 20)
            y = rg.integers(int(ZW_Y1) + 1, int(ZW_Y2) - 1)
            c.put(c.rect(x, y, x + rg.uniform(8, 26), y + 1), "water", 6 + (rg.random() < 0.3), solid=False)
        # boven- en onderkant van de waaier: harde lijn, zodat de hoogte leest (36 en 60)
        c.put((np.abs(c.Y - ZW_Y2 + 0.5) < 0.6) & (c.X < W) & ((c.X + f * 2) % 6 < 4), "water", 7, solid=False)
        c.put((np.abs(c.Y - ZW_Y1 - 0.5) < 0.6) & (c.X < W) & ((c.X + f * 2) % 6 < 3), "water", 5, solid=False)
        spat = (c.X < 6) & (c.Y > ZW_Y1 - 4) & (c.Y < ZW_Y2 + 6) & (c.BAY < 0.5)
        c.put(spat, "water", 6, solid=False)
    else:                                                                # uit: druppels vallen
        rg = np.random.default_rng(740 + f)
        for _ in range(40 - 15 * f):
            x = rg.uniform(0, W)
            y = rg.uniform(ZW_Y1 - 6 - 4 * f, ZW_Y2 - 10 - 6 * f)
            c.put(c.rect(x, y, x + 1, y + 2), "water", 5, solid=False)
    return c


def tell(w, h, fase):
    """Tell-taal (deel 1 §4.3): het vlak waar de aanval komt, in vijandrood. Vroeg 25 %, laat 75 %, beide in
    vijandkern 4 (ook zonder kleur leesbaar; Lead-review AD op PR #266), met een gestippelde bovenlijn; actief vol (kern 4) met een rand in kern 7."""
    c = Cel((int(w), int(h), 0, h))
    alles = np.ones_like(c.solid)
    if fase == "actief":
        c.put(alles, "vijandkern", 4, solid=False)
        rand = ~ndimage.binary_erosion(alles, border_value=0)
        c.put(rand, "vijandkern", 7, solid=False)
    else:
        dens = {"vroeg": 0.25, "laat": 0.75}[fase]
        c.put(alles & (c.BAY < dens), "vijandkern", 4, solid=False)        # vroeg/laat verschillen in dichtheid (AD, PR #266)
        lijn = np.zeros_like(alles)
        lijn[0, :] = (np.arange(c.w) % 4) < 2
        c.put(lijn, "vijandkern", 6, solid=False)
    return c


def spuigat(staat, f):
    """De spuigaten (GMB-03): 30 ticks gloeien (3 frames), daarna stoom waar de Kadeloper uitstapt."""
    dk = staat != "kleur"
    c = Cel(CEL_SPUI)
    rooster = c.rect(-7, -10, 7, -1) & (((c.X + 8) % 4) < 2)
    if f < 3:
        c.put(rooster, "vijandkern", [3, 4, 6][f] if dk else [2, 3, 5][f], solid=False)
        c.put(c.rect(-7, -1, 7, 0) & ((c.X % 2) < 1), "vijandkern", [4, 5, 7][f], solid=False)
        for i in range(f + 1):
            stoom(c, (i - f / 2) * 4, 3 + i * 4, 3 + i, 800 + f * 3 + i, dicht=0.45)
    else:
        for i in range(3):
            stoom(c, (i - 1) * 5, 4 + i * 4 + (f - 3) * 3, 4 + i, 820 + f * 3 + i, dicht=0.5 - 0.15 * (f - 3))
    return c


# ------------------------------------------------------------------ atlas en manifest
RAND = 1                                                          # px transparante rand rond elk frame


class Blad:
    """Een atlas: per animatie een rij frames van één celgrootte."""

    def __init__(self, naam, cel):
        self.naam, self.cw, self.ch = naam, cel[0], cel[1]
        self.rijen = []                 # (animatie, [frames per staat], ticks, lus, extra)

    def anim(self, naam, maak, n, ticks, lus=False, **extra):
        frames = {s: [maak(s, i) for i in range(n)] for s in STATEN}
        self.rijen.append((naam, frames, ticks, lus, extra))

    def export(self, P=RAND):
        """Elk frame krijgt rondom P px transparante rand (eis van de echo-contour van de TA, #267): de cel in
        de atlas is cw + 2P bij ch + 2P; de offset in het manifest schuift (-P, -P)."""
        kol = max(len(fr["grijs"]) for _, fr, _, _, _ in self.rijen)
        CW, CH = self.cw + 2 * P, self.ch + 2 * P
        W, H = kol * CW, len(self.rijen) * CH
        anims = {}
        for s in STATEN:
            img = np.zeros((H, W, 4))
            for r, (naam, fr, _, _, _) in enumerate(self.rijen):
                for i, c in enumerate(fr[s]):
                    img[r * CH + P:r * CH + P + self.ch, i * CW + P:i * CW + P + self.cw] = c.render(s)
            D2.save(img, os.path.join(UIT_GAME, f"gemaalmeester_{self.naam}_{s}.png"))
        items = []
        for r, (naam, fr, ticks, lus, extra) in enumerate(self.rijen):
            for i, c in enumerate(fr["grijs"]):
                items.append((i * CW + P, r * CH + P, c))
            anims[naam] = dict(frames=[[i * CW, r * CH, CW, CH] for i in range(len(fr["grijs"]))],
                               ticks=list(ticks), lus=lus, **extra)
        D1.index_atlas(items, W, H).save(os.path.join(UIT_GAME, f"gemaalmeester_{self.naam}_index.png"))
        return dict(bestanden={s: f"gemaalmeester_{self.naam}_{s}.png" for s in STATEN + ["index"]},
                    cel=[CW, CH], rand_px=P, atlas=[W, H], animaties=anims)


def verdeel(totaal, n):
    """`totaal` ticks over `n` frames, zo gelijk mogelijk (de eerste frames iets langer)."""
    b, r = divmod(totaal, n)
    return [b + (1 if i < r else 0) for i in range(n)]


def bouw_bladen():
    T = TICKS
    lich = Blad("lichaam", CEL_LICHAAM)
    lich.anim("idle", lambda s, i: lichaam(IDLE[i], s), 6, [10] * 6, lus=True)
    for kn, kant in (("links", -1), ("rechts", 1)):
        aan, slag, ligt, terug = pomp_poses(kant)
        lich.anim(f"aarzeling_{kn}", lambda s, i, k=kant: lichaam(aarzel_poses(k)[i], s), 3,
                  verdeel(T["eerste_aanloop"] - T["pomp1_aanloop"], 3), kant=kant,
                  volgt="pomp_aanloop_" + kn,
                  noot="de eerste aanloop (eerste_aanloop = 60): eerst deze 3 frames (20 ticks), dan pomp_aanloop over de resterende 40")
        lich.anim(f"pomp_aanloop_{kn}", lambda s, i, a=aan: lichaam(a[i], s), 5,
                  verdeel(T["pomp1_aanloop"] - 3, 4) + [3], kant=kant,
                  stuurt="windup_progress: frame 0-3 op kwarten van (aanloop - 3); frame 4 (uithaal) de laatste 3 ticks",
                  ticks_fase2=verdeel(T["pomp2_aanloop"] - 3, 4) + [3])
        lich.anim(f"pomp_slag_{kn}", lambda s, i, a=slag: lichaam(a[i], s), 2, verdeel(T["pomp1_actief"], 2), kant=kant,
                  noot="het verste frame: valt samen met de actieve ticks")
        lich.anim(f"pomp_ligt_{kn}", lambda s, i, a=ligt: lichaam(a[i], s), 1, [T["pomp1_herstel"]], kant=kant)
        lich.anim(f"pomp_terug_{kn}", lambda s, i, a=terug: lichaam(a[i], s), 2, [6, 6], kant=kant,
                  noot="na het herstel, in de rust van de maat; daarna idle")
    for kn, kant in (("links", -1), ("rechts", 1)):
        aan, veeg, uit = zwiep_poses(kant)
        lich.anim(f"zwiep_aanloop_{kn}", lambda s, i, a=aan: lichaam(a[i], s), 5, verdeel(T["zwiep_aanloop"] - 3, 4) + [3],
                  kant=kant, stuurt="windup_progress, zoals pomp_aanloop")
        lich.anim(f"zwiep_veeg_{kn}", lambda s, i, a=veeg: lichaam(a[i], s), 2, verdeel(T["zwiep_actief"], 2), kant=kant)
        lich.anim(f"zwiep_uit_{kn}", lambda s, i, a=uit: lichaam(a[i], s), 2, verdeel(T["zwiep_herstel"], 2), kant=kant)
    lich.anim("fasewissel", lambda s, i: lichaam(FASEWISSEL[i], s), 4, verdeel(T["fasewissel_ticks"], 4))
    lich.anim("wankel_in", lambda s, i: lichaam(WANKEL_IN[i], s), 2, [8, 8], volgt="wankel")
    lich.anim("wankel", lambda s, i: lichaam(WANKEL[i], s), 4, [12, 4, 16, 6], lus=True,
              noot="hapert: onregelmatige tijden; geen aanvallen, geen tijdslimiet (GM-08)")
    lich.anim("geraakt", lambda s, i: lichaam(GERAAKT[i], s), 2, [4, 4],
              noot="bij een treffer op de kern (fase 1) en bij elke finisherslag (Wankel/finisher); daarna terug")
    lich.anim("oplossen", lambda s, i: lichaam(OPLOSSEN[i], s), 10, [6] * 10,
              noot="GM-10: op BOSS_VERSLAGEN; laatste frame = bijna leeg, daarna niets tekenen")

    ket = Blad("ketel", CEL_KETEL)
    ket.anim("schot", lambda s, i: ketel(s, "schot", i), 2, [30, 30], lus=True, noot="fase 1, intact (Merkbaar): de naad gloeit")
    ket.anim("tink", lambda s, i: ketel(s, "tink"), 1, [4], noot="een gewone treffer op het intacte schot (`ketel.tink_tick`)")
    ket.anim("breuk", lambda s, i: ketel(s, "breuk", i), 3, [4, 4, 4], volgt="kern", noot="SCHOT_BREUK (shot_broken)")
    ket.anim("kern", lambda s, i: ketel(s, "kern", i), 4, [8] * 4, lus=True, noot="core_open")
    ket.anim("kern_geraakt", lambda s, i: ketel(s, "kern_geraakt", i), 2, [3, 3], volgt="kern")
    ket.anim("schot_sluit", lambda s, i: ketel(s, "sluit", i), 3, [7, 7, 6], volgt="schot", noot="KERN_DICHT (core_closed)")
    ket.anim("schot_dicht", lambda s, i: ketel(s, "dicht"), 1, [1],
             noot="fasewissel en fase 2: voorgoed dicht, gelast, niet Merkbaar (GM-07)")
    ket.anim("merkplek_open", lambda s, i: ketel(s, "merkplek_open", i), 3, [7, 7, 6], volgt="merkplek",
             noot="op Wankel (GMB-05)")
    ket.anim("merkplek", lambda s, i: ketel(s, "merkplek", i), 2, [20, 20], lus=True)
    ket.anim("oplossen", lambda s, i: _ket_oplos(s, 0.08 + i * 0.1), 10, [6] * 10, noot="gelijk met lichaam/oplossen")

    rd = Blad("rad", CEL_RAD)
    for sc in range(4):
        rd.anim(f"draai_s{sc}", lambda s, i, sc=sc: rad(s, i, sc, "draai"), 8, [8] * 8, lus=True, scheur=sc,
                ticks_draaien=[3] * 8,
                noot="hangt: 8 ticks per frame; tijdens fasewissel en draaien (RadState.TURNING): 3 ticks per frame")
        rd.anim(f"treffer_s{sc}", lambda s, i, sc=sc: rad(s, i, sc, "treffer"), 2, [int(GM["schok_rad_ticks"]), 3],
                scheur=sc, noot="RAD_TREFFER (rad_hit); daarna draai")
        rd.anim(f"trilt_s{sc}", lambda s, i, sc=sc: rad(s, i, sc, "trilt"), 2, [2, 2], lus=True, scheur=sc,
                noot="RadState.SHAKING (rad_tril = 20 ticks); het frame verschuift zelf 1 px heen en weer")
    rd.anim("oplossen", lambda s, i: rad(s, 3, 3, "draai", oplos=0.1 + i * 0.12), 8, [7] * 8)

    pomp = Blad("pompslag", CEL_POMP)
    pomp.anim("aanloop", lambda s, i: pomp_effect(s, "aanloop", i), 4, verdeel(T["pomp1_aanloop"], 4),
              stuurt="windup_progress in kwarten")
    pomp.anim("actief", lambda s, i: pomp_effect(s, "actief", i), 2, verdeel(T["pomp1_actief"], 2))
    pomp.anim("herstel", lambda s, i: pomp_effect(s, "herstel", i), 3, verdeel(T["pomp1_herstel"], 3))

    zw = {}
    for kn in ("links", "rechts"):
        b = Blad(f"zwiep_{kn}", CEL_ZWIEP)
        flip = kn == "rechts"

        def mk(soort, s, i, flip=flip):
            c = zwiep_effect(s, soort, i)
            if flip:
                c.mat, c.t = c.mat[:, ::-1].copy(), c.t[:, ::-1].copy()
            return c
        b.anim("aanloop", lambda s, i, mk=mk: mk("aanloop", s, i), 2, verdeel(T["zwiep_aanloop"] // 2, 2),
               stuurt="windup_progress >= 0,5 (de tweede helft van de aanloop)")
        b.anim("actief", lambda s, i, mk=mk: mk("actief", s, i), 2, verdeel(T["zwiep_actief"], 2))
        b.anim("herstel", lambda s, i, mk=mk: mk("herstel", s, i), 2, verdeel(T["zwiep_herstel"], 2))
        zw[kn] = b

    tp = Blad("tell_pomp", (int(POMP_W), int(POMP_H)))
    tz = Blad("tell_zwiep", (int(ZW_W), int(ZW_Y2 - ZW_Y1)))
    for b, w, h in ((tp, POMP_W, POMP_H), (tz, ZW_W, ZW_Y2 - ZW_Y1)):
        for fase in ("vroeg", "laat", "actief"):
            b.anim(fase, lambda s, i, w=w, h=h, fase=fase: tell(w, h, fase), 1, [1],
                   stuurt={"vroeg": "windup_progress < 0,5", "laat": "windup_progress >= 0,5",
                           "actief": "is_attack_active()"}[fase])
    sp = Blad("spuigat", CEL_SPUI)
    sp.anim("gloei", lambda s, i: spuigat(s, i), 3, verdeel(T["spuigat_gloei"], 3), volgt="stoom",
            noot="spout_glowing (30 ticks)")
    sp.anim("stoom", lambda s, i: spuigat(s, 3 + i), 2, verdeel(T["add_inactief"], 2),
            noot="de add stapt uit de stoom (add_inactief)")
    return dict(lichaam=lich, ketel=ket, rad=rd, pompslag=pomp, zwiep_links=zw["links"], zwiep_rechts=zw["rechts"],
                tell_pomp=tp, tell_zwiep=tz, spuigat=sp)


PLAATSING = {
    "lichaam": dict(offset=[CEL_LICHAAM[2], -CEL_LICHAAM[3]], ten_opzichte_van="boss-node (linkermuur, bovenkant vloer)",
                    z_index=-2, noot="lichaam_x1/x2 = 252-348 en 160 hoog vallen op kolom 16-112, rij 16-176"),
    "ketel": dict(offset=[CEL_KETEL[2], -CEL_KETEL[3]], ten_opzichte_van="boss-node", z_index=-1,
                  noot="het schot/de kern (276-324 x 12-60) valt op kolom 8-56, rij 8-56; boven het lichaam"),
    "rad": dict(offset=[CEL_RAD[2], -CEL_RAD[3] + RAD_YC], ten_opzichte_van="rad.position (middelpunt van de hurtbox)",
                z_index=-3, noot="de hurtbox (96 x 40) valt op kolom 8-104, rij 24-64. In fase 1 (RadState.HIDDEN) "
                                 "hangt het rad achter de rug van het lichaam op (300, 120): draai_s0 frame 0, stil"),
    "pompslag": dict(offset=[CEL_POMP[2], -CEL_POMP[3] + POMP_H], ten_opzichte_van="attack_box.position (linksboven)",
                     z_index=1, noot="het vlak (160 x 24) valt op kolom 8-168, rij 12-36"),
    "zwiep_links": dict(offset=[0, -CEL_ZWIEP[3] + ZW_Y2], ten_opzichte_van="attack_box.position", z_index=1,
                        noot="het vlak (300 x 24) valt op rij 10-34; rechts: zwiep_rechts op dezelfde plek"),
    "zwiep_rechts": dict(offset=[0, -CEL_ZWIEP[3] + ZW_Y2], ten_opzichte_van="attack_box.position", z_index=1),
    "tell_pomp": dict(offset=[0, 0], ten_opzichte_van="attack_box.position", z_index=0,
                      noot="precies het vlak; onder het effect"),
    "tell_zwiep": dict(offset=[0, 0], ten_opzichte_van="attack_box.position", z_index=0),
    "spuigat": dict(offset=[CEL_SPUI[2], -CEL_SPUI[3]], ten_opzichte_van="(spuigat_links|spuigat_rechts, 0) in de boss-node",
                    z_index=-1),
}


# ------------------------------------------------------------------ renders in S8
VLOER = 320
WL = 20


def arena_room(x, y):
    return int(WL + x), int(VLOER - y)


def plak(img, c, staat, ax, ay_top):
    """Een cel op de kamer: (ax, ay_top) = arena-x van kolom 0 en arena-y van de bovenkant."""
    x, y = arena_room(ax, ay_top)
    D1.stamp_rgba(img, c.render(staat), x, y)


def boss_beeld(img, staat, lich, ket=None, rd=None, rad_x=MX, rad_achter=False, effecten=()):
    if rd is not None and rad_achter:
        plak(img, rd, staat, rad_x + CEL_RAD[2], CEL_RAD[3])
    plak(img, lich, staat, CEL_LICHAAM[2], CEL_LICHAAM[3])
    if ket is not None:
        plak(img, ket, staat, CEL_KETEL[2], CEL_KETEL[3])
    if rd is not None and not rad_achter:
        plak(img, rd, staat, rad_x + CEL_RAD[2], CEL_RAD[3])
    for (c, ax, ay_top) in effecten:
        plak(img, c, staat, ax, ay_top)
    return img


def s8_achtergrond():
    k = D5.bouw_s8()
    D5.maak_vaste_stukken()
    return {s: k.samengesteld(D5.met_stukken(k, "S8", s)) for s in ("grijs", "kleur")}


def ring_dl(img_met, img_zonder, masker, top=None, pct=90):
    """ΔL* (p90 van `top` of het masker) tegen de mediaan van de ring van 2..6 px rond het masker."""
    L = R.srgb_to_lab(img_met)[..., 0]
    L0 = R.srgb_to_lab(img_zonder)[..., 0]
    ring = ndimage.binary_dilation(masker, iterations=6) & ~ndimage.binary_dilation(masker, iterations=2)
    m = masker if top is None else top
    return abs(float(np.percentile(L[m], pct)) - float(np.median(L0[ring])))


def masker_van(c, ax, ay_top, h=360, w=640, alleen=None):
    m = np.zeros((h, w), bool)
    x, y = arena_room(ax, ay_top)
    sub = c.mat >= 0 if alleen is None else alleen(c)
    hh, ww = sub.shape
    m[y:y + hh, x:x + ww] = sub
    return m


def metingen(bg):
    out = {}
    for staat in ("grijs", "kleur"):
        z = bg[staat]
        lich = lichaam(IDLE[0], staat)
        ket = ketel(staat, "schot", 0)
        rd0 = rad(staat, 0, 0)
        met = boss_beeld(z.copy(), staat, lich, ket, rd0, rad_achter=True)
        m = masker_van(lich, CEL_LICHAAM[2], CEL_LICHAAM[3])
        top = masker_van(lich, CEL_LICHAAM[2], CEL_LICHAAM[3],
                         alleen=lambda c: (c.mat == MI["vijandkern"]) & (c.t == 7) & c.solid & (c.Y > 60))
        lijf = masker_van(lich, CEL_LICHAAM[2], CEL_LICHAAM[3], alleen=lambda c: c.mat == MI["vijandlijf"])
        out[(staat, "bovenrand lichaam")] = ring_dl(met, z, m, top)
        out[(staat, "lijf lichaam (mediaan)")] = ring_dl(met, z, m, lijf, pct=50)
        # het rad in fase 2, op zijn plek bij D = 60 (x 94 en 506) vóór de wand en de balk
        for xr in (D + GM["rad_offset"], ARENA_W - D - GM["rad_offset"]):
            img = z.copy()
            r_ = rad(staat, 2, 0)
            plak(img, r_, staat, xr + CEL_RAD[2], CEL_RAD[3])
            mr = masker_van(r_, xr + CEL_RAD[2], CEL_RAD[3])
            tr = masker_van(r_, xr + CEL_RAD[2], CEL_RAD[3], alleen=lambda c: (c.mat == MI["vijandkern"]) & (c.t == 7)
                            & (c.Y > RAD_YC))
            vl = masker_van(r_, xr + CEL_RAD[2], CEL_RAD[3], alleen=lambda c: (c.mat == MI["hout"]))
            out[(staat, f"bovenrand rad x {int(xr)}")] = ring_dl(img, z, mr, tr)
            out[(staat, f"velg rad x {int(xr)} (mediaan)")] = ring_dl(img, z, mr, vl, pct=50)
        # tells: ΔL* van het vlak met en zonder tell (gemiddeld), pompslag links (fase 1) en zwiep links
        for naam, (w, h, ax, ay0) in {"pomp": (POMP_W, POMP_H, MX - POMP_W, POMP_H),
                                      "zwiep": (ZW_W, ZW_Y2 - ZW_Y1, 0, ZW_Y2)}.items():
            for fase in ("vroeg", "laat", "actief"):
                img = z.copy()
                t = tell(w, h, fase)
                plak(img, t, staat, ax, ay0)
                mt = masker_van(t, ax, ay0, alleen=lambda c: np.ones_like(c.solid))
                L = R.srgb_to_lab(img)[..., 0]
                L0 = R.srgb_to_lab(z)[..., 0]
                out[(staat, f"tell {naam} {fase} (ΔL* gemiddeld)")] = abs(float(L[mt].mean() - L0[mt].mean()))
                gezet = masker_van(t, ax, ay0)
                out[(staat, f"tell {naam} {fase} (ΔL* gezette pixels, mediaan)")] = abs(float(np.median(L[gezet] - L0[gezet])))
        # de kern open tegen het schot (zelfde plek): leest de opening zonder kleur?
        a = boss_beeld(z.copy(), staat, lich, ketel(staat, "kern", 0))
        b = boss_beeld(z.copy(), staat, lich, ketel(staat, "schot", 0))
        mk = np.zeros((360, 640), bool)
        x0, y0 = arena_room(SX1, SY2)
        mk[y0:y0 + int(SY2 - SY1), x0:x0 + int(SX2 - SX1)] = True
        La, Lb = R.srgb_to_lab(a)[..., 0], R.srgb_to_lab(b)[..., 0]
        out[(staat, "kern open tegen schot (ΔL* gemiddeld)")] = abs(float(La[mk].mean() - Lb[mk].mean()))
        out[(staat, "kern open tegen schot (ΔL* p90)")] = abs(float(np.percentile(La[mk], 90) - np.percentile(Lb[mk], 90)))
    return out


def echo_bij_ketel(bg):
    """Punt van de CD (#247): P1 vlak bij de ketel, de echo speelt bijna dezelfde plek af. Drie gevallen:
    naast elkaar (12 px), half over elkaar (6 px) en bijna gelijk (3 px), vóór het schot en vóór de kern."""
    out, beelden = {}, []
    for staat in ("grijs", "kleur"):
        for kern in (False, True):
            for d in (12, 6, 3):
                z = boss_beeld(bg[staat].copy(), staat, lichaam(IDLE[0], staat), ketel(staat, "kern" if kern else "schot", 0),
                               rad(staat, 0, 0), rad_achter=True)
                p1x = WL + 286
                alleen_p1 = D2.plak_fig(z.copy(), [("p1", SP.P1_RUN[0], p1x, VLOER, True, True)], 0)
                beide = D2.plak_fig(alleen_p1.copy(), [("echo", SP.P1_RUN[1], p1x + d, VLOER, True, staat == "kleur")], 0)
                # het masker van de echo: wat de echo verandert tegenover alleen P1
                diff = np.abs(beide - alleen_p1).sum(-1) > 0.02
                L = R.srgb_to_lab(beide)[..., 0]
                Lp = R.srgb_to_lab(alleen_p1)[..., 0]
                # de rand van de echo: de lichtste pixels die hij zet (p90) tegen wat er zonder hem stond (mediaan)
                p1m = np.abs(alleen_p1 - z).sum(-1) > 0.02
                # zijn lichte rand waar hij niet over P1 valt, tegen de ring van 2..6 px (zoals deel 5)
                los = diff & ~p1m
                ring = ndimage.binary_dilation(diff, iterations=6) & ~ndimage.binary_dilation(diff | p1m, iterations=2)
                dl_rand = abs(float(np.percentile(L[los], 90)) - float(np.median(L[ring])))
                # zijn bijna-zwarte buitencontour waar hij over P1 valt (het deel dat hem van P1 scheidt)
                over = diff & p1m & (L < 20)
                dl_over = abs(float(np.median(L[over])) - float(np.median(Lp[over]))) if over.sum() > 3 else float("nan")
                out[(staat, "kern" if kern else "schot", d)] = (dl_rand, dl_over, int(over.sum()))
                if d in (6, 3):
                    beelden.append((staat, kern, d, beide[VLOER - 44:VLOER + 4, WL + 262:WL + 326]))
    return out, beelden


def blad_overzicht(bladen, staat, schaal=2):
    """Elk blad op een donkere achtergrond, met de animatienamen."""
    delen = []
    for naam, b in bladen.items():
        for anim, fr, ticks, lus, extra in b.rijen:
            frames = fr[staat]
            cw, ch = b.cw, b.ch
            rij = np.zeros((ch + 12, max(len(frames) * (cw + 4), 440), 3)) + D1.BG
            for i, c in enumerate(frames):
                lay = c.render(staat)
                sub = rij[12:12 + ch, i * (cw + 4):i * (cw + 4) + cw]
                rij[12:12 + ch, i * (cw + 4):i * (cw + 4) + cw] = sub * (1 - lay[..., 3:4]) + lay[..., :3] * lay[..., 3:4]
            D1.label(rij, f"{naam.upper()} / {anim.upper()}  TICKS {' '.join(map(str, ticks))}{'  (LUS)' if lus else ''}",
                     2, 3, (1, 0.86, 0.58), s=1)
            delen.append(rij)
    W = max(d.shape[1] for d in delen)
    delen = [np.concatenate([d, np.zeros((d.shape[0], W - d.shape[1], 3)) + D1.BG], 1) for d in delen]
    return np.concatenate(delen, 0)


# ------------------------------------------------------------------ het gevecht als tijdlijn (GIF)
def tijdlijn():
    """Een korte doorloop van het gevecht (solo, D = 60), in ticks: lijst van (duur, beschrijving, functie(t))."""
    T = TICKS
    seq = []

    def stap(n, wat, f):
        seq.append((n, wat, f))
    rust = lambda t: dict(lich=IDLE[(t // 10) % 6], ket=("schot", (t // 30) % 2), rad=("draai", 0, 0), rad_x=MX, achter=True)

    stap(40, "IDLE (FASE 1)", rust)

    def aanval(soort, kant, aanloop, actief, herstel, fase, x1=None, eerste=False):
        if soort == "pomp":
            aan, slag, ligt, terug = pomp_poses(kant)
        else:
            aan, slag, terug = zwiep_poses(kant)
            ligt = []
        kn = "links" if kant < 0 else "rechts"
        if x1 is None:
            x1 = MX - POMP_W if kant < 0 else MX
        w = POMP_W if soort == "pomp" else ZW_W
        tx = x1 if soort == "pomp" else (0 if kant < 0 else ARENA_W - ZW_W)
        ty = POMP_H if soort == "pomp" else ZW_Y2
        aarzel = T["eerste_aanloop"] - T["pomp1_aanloop"] if eerste else 0
        tot = aarzel + aanloop

        def f(t):
            base = dict(ket=("schot", 0) if fase == 1 else ("dicht", 0), rad=("draai", (t // 8) % 8, 1) if fase == 2 else ("draai", 0, 0),
                        rad_x=GM_RAD_X_LINKS if fase == 2 else MX, achter=fase == 1)
            eff = []
            if t < tot:
                prog = t / tot
                if t < aarzel:
                    base["lich"] = aarzel_poses(kant)[min(2, t * 3 // aarzel)]
                else:
                    ta = t - aarzel
                    base["lich"] = aan[4] if aanloop - ta <= 3 else aan[min(3, ta * 4 // (aanloop - 3))]
                eff.append(("tell_" + soort, "vroeg" if prog < 0.5 else "laat", tx, ty))
                if soort == "pomp":
                    eff.append(("pomp", ("aanloop", min(3, int(prog * 4))), x1 - 8, 36))
                elif prog >= 0.5:
                    eff.append(("zwiep", ("aanloop", min(1, int((prog - 0.5) * 4)), kn), 0, 70))
            elif t < tot + actief:
                i = (t - tot) * 2 // actief
                base["lich"] = slag[i]
                eff.append(("tell_" + soort, "actief", tx, ty))
                eff.append(("pomp", ("actief", i), x1 - 8, 36) if soort == "pomp" else ("zwiep", ("actief", i, kn), 0, 70))
            elif t < tot + actief + herstel:
                th = t - tot - actief
                if soort == "pomp":
                    base["lich"] = ligt[0]
                    eff.append(("pomp", ("herstel", min(2, th * 3 // herstel)), x1 - 8, 36))
                else:
                    base["lich"] = terug[min(1, th * 2 // herstel)]
                    eff.append(("zwiep", ("herstel", min(1, th * 2 // herstel), kn), 0, 70))
            else:
                base["lich"] = terug[min(1, (t - tot - actief - herstel) // 6)] if soort == "pomp" else IDLE[0]
            base["eff"] = eff
            return base
        return tot + actief + herstel + (12 if soort == "pomp" else 0), f

    n, f = aanval("pomp", 1, T["pomp1_aanloop"], T["pomp1_actief"], T["pomp1_herstel"], 1, eerste=True)
    stap(n, "EERSTE AANLOOP: AARZELING BIJ DE SJAAL, POMPSLAG RECHTS", f)
    stap(20, "SCHOT: TINK (GEWONE TREFFER)", lambda t: dict(rust(t), ket=("tink", 0) if t < 4 else ("schot", 0)))
    stap(12, "SCHOT_BREUK (MERK-ONTPLOFFING)", lambda t: dict(rust(t), ket=("breuk", t // 4)))
    stap(70, "KERN OPEN, TREFFERS", lambda t: dict(rust(t), ket=("kern_geraakt", t % 6 // 3) if (t % 24) < 6 else ("kern", (t // 8) % 4),
                                                    lich=GERAAKT[(t % 24) // 4] if (t % 24) < 8 and t > 20 else IDLE[(t // 10) % 6]))
    stap(20, "KERN_DICHT: SCHOT SCHUIFT VOOR", lambda t: dict(rust(t), ket=("sluit", min(2, t * 3 // 20))))
    stap(50, "SPUIGATEN GLOEIEN, ADDS STAPPEN UIT DE STOOM",
         lambda t: dict(rust(t), eff=[("spui", min(4, t // 10) if t < 30 else 3 + min(1, (t - 30) // 10), s, 20) for s in SPUI]))
    n, f = aanval("pomp", -1, T["pomp1_aanloop"], T["pomp1_actief"], T["pomp1_herstel"], 1)
    stap(n, "POMPSLAG LINKS (FASE 1, AANLOOP 40)", f)

    def wissel(t):
        k = t / T["fasewissel_ticks"]
        return dict(lich=FASEWISSEL[min(3, t // 15)], ket=("dicht", 0), rad=("draai", (t // 3) % 8, 0),
                    rad_x=MX + (GM_RAD_X_RECHTS - MX) * k, achter=t < 10)
    stap(T["fasewissel_ticks"], "FASEWISSEL: HET RAD HIJST ZICH UIT DE RUG", wissel)
    fase2 = lambda t, sc=0, x=GM_RAD_X_RECHTS: dict(lich=IDLE[(t // 10) % 6], ket=("dicht", 0), rad=("draai", (t // 8) % 8, sc), rad_x=x,
                                                   achter=False)
    stap(30, "FASE 2: HET RAD HANGT (X = D + 34)", fase2)
    stap(24, "RAD_TREFFER x2 (BOUNCE)", lambda t: dict(fase2(t, 1), rad=("treffer", (t % 12) // 3 % 2, 1) if (t % 12) < 6 else ("draai", 0, 1)))
    stap(T["rad_tril"], "HET RAD TRILT (TELL VAN HET WEGDRAAIEN)", lambda t: dict(fase2(t, 1), rad=("trilt", (t // 2) % 2, 1)))
    stap(T["rad_draai"], "HET RAD DRAAIT NAAR DE ANDERE MUUR",
         lambda t: dict(fase2(t, 1), rad=("draai", (t // 3) % 8, 1),
                        rad_x=GM_RAD_X_RECHTS + (GM_RAD_X_LINKS - GM_RAD_X_RECHTS) * t / T["rad_draai"]))
    n, f = aanval("zwiep", -1, T["zwiep_aanloop"], T["zwiep_actief"], T["zwiep_herstel"], 2)
    stap(n + 10, "SCHOEPENZWIEP LINKS (Y 36-60)", lambda t, f=f, n=n: f(t) if t < n else fase2(t, 1, GM_RAD_X_LINKS))
    n, f = aanval("pomp", -1, T["pomp2_aanloop"], T["pomp2_actief"], T["pomp2_herstel"], 2, x1=60)
    stap(n, "POMPSLAG FASE 2 OP DE X VAN P1 (AANLOOP 30)", lambda t, f=f: dict(f(t), rad=("draai", (t // 8) % 8, 2)))
    wank = lambda t: dict(lich=WANKEL[([0] * 12 + [1] * 4 + [2] * 16 + [3] * 6)[t % 38]], ket=("dicht", 0), rad=("draai", 3, 3),
                          rad_x=GM_RAD_X_LINKS, achter=False)
    stap(16, "WANKEL", lambda t: dict(wank(t), lich=WANKEL_IN[min(1, t // 8)]))
    stap(20, "MERKPLEK GAAT OPEN", lambda t: dict(wank(t), ket=("merkplek_open", min(2, t // 7))))
    stap(60, "WANKEL: HIJ HAPERT, GEEN AANVALLEN", lambda t: dict(wank(t), ket=("merkplek", (t // 20) % 2)))
    stap(T["finisher_ticks"], "FINISHER: DE GEDEELDE ECHO SLAAT (120 TICKS)",
         lambda t: dict(wank(t), ket=("merkplek", 1), lich=GERAAKT[(t % 10) // 4] if (t % 10) < 8 else WANKEL[0]))
    stap(60, "BOSS_VERSLAGEN: HIJ LOST OP IN LICHT",
         lambda t: dict(lich=OPLOSSEN[min(9, t // 6)], ket=None, rad=("oplossen", min(7, t // 7), 3), rad_x=GM_RAD_X_LINKS, achter=False,
                        oplos=min(9, t // 6)))
    stap(20, "", lambda t: dict(lich=None, ket=None, rad=None))
    return seq


GM_RAD_X_LINKS = D + GM["rad_offset"]
GM_RAD_X_RECHTS = ARENA_W - D - GM["rad_offset"]


class Cache:
    def __init__(self):
        self.d = {}

    def get(self, key, maak):
        if key not in self.d:
            self.d[key] = maak()
        return self.d[key]


def beeld_tick(bg, staat, st, cache):
    img = bg.copy()
    L = None
    if st.get("lich") is not None:
        L = cache.get(("lich", id(st["lich"]), staat), lambda: lichaam(st["lich"], staat))
    ket = None
    if st.get("ket"):
        soort, f = st["ket"]
        if "oplos" in st:
            pass
        ket = cache.get(("ket", soort, f, staat), lambda: ketel(staat, soort, f))
    if st.get("oplos") is not None:
        k = 0.08 + st["oplos"] * 0.1
        ket = cache.get(("ketop", st["oplos"], staat), lambda: _ket_oplos(staat, k))
    rd = None
    if st.get("rad"):
        soort, f, sc = st["rad"]
        if soort == "oplossen":
            rd = cache.get(("radop", f, staat), lambda: rad(staat, 3, 3, "draai", oplos=0.1 + f * 0.12))
        else:
            rd = cache.get(("rad", soort, f, sc, staat), lambda: rad(staat, f, sc, soort))
    eff = []
    for e in st.get("eff", []):
        kind = e[0]
        if kind.startswith("tell_"):
            w, h = (POMP_W, POMP_H) if kind == "tell_pomp" else (ZW_W, ZW_Y2 - ZW_Y1)
            eff.insert(0, (cache.get(("tell", kind, e[1], staat), lambda: tell(w, h, e[1])), e[2], e[3]))
        elif kind == "pomp":
            eff.append((cache.get(("pomp", e[1], staat), lambda: pomp_effect(staat, *e[1])), e[2], e[3]))
        elif kind == "zwiep":
            soort, i, kn = e[1]

            def mk():
                c = zwiep_effect(staat, soort, i)
                if kn == "rechts":
                    c.mat, c.t = c.mat[:, ::-1].copy(), c.t[:, ::-1].copy()
                return c
            eff.append((cache.get(("zwiep", soort, i, kn, staat), mk), e[2] if kn == "links" else ARENA_W - ZW_W, e[3]))
        elif kind == "spui":
            eff.append((cache.get(("spui", e[1], staat), lambda: spuigat(staat, e[1])), e[2] + CEL_SPUI[2], CEL_SPUI[3]))
    if L is not None:
        boss_beeld(img, staat, L, ket, rd, rad_x=st.get("rad_x", MX), rad_achter=st.get("achter", False), effecten=eff)
    elif rd is not None:
        plak(img, rd, staat, st.get("rad_x", MX) + CEL_RAD[2], CEL_RAD[3])
    return img


def _ket_oplos(staat, k):
    c = ketel(staat, "dicht")
    oplossen(c, k, 5)
    return c


# ------------------------------------------------------------------ hoofdprogramma
def main():
    print("Gemaalmeester: sprites en animaties (S-14)")
    bladen = bouw_bladen()
    manifest = dict(
        versie="0.1", eigenaar="Animator", issue=265,
        bron="docs/art/slice/bron/genereer_gemaalmeester.py",
        maten="uit game/data/vijanden/slice.csv (groep gemaalmeester) en game/scripts/combat/gemaalmeester.gd",
        knoop="De boss-node staat op de linkermuur van de arena, op de bovenkant van de vloer; arena-x naar rechts, "
              "node-y = -arena-y. `offset` = linksboven van een cel in node-coördinaten (Sprite2D, centered = false).",
        ticks="per frame, in ticks van 60 per seconde (= frames bij 60 fps); `stuurt` zegt welke vlag uit boss.gd/"
              "gemaalmeester.gd het frame kiest, als het niet op tijd loopt",
        import_=dict(map="res://art/animatie/gemaalmeester/",
                     texture="Lossless, mipmaps uit, filter Nearest op het CanvasItem, repeat uit (zoals kadewijk_kamers.json)",
                     toestanden="grijs (het gevecht, s = 1) / half / kleur; index = R materiaal-id, G tint*32+16, A 255 "
                                "(de vijandkleuren zijn in elke toestand gelijk; de index is die van grijs)"),
        bladen={},
    )
    for naam, b in bladen.items():
        e = b.export()
        e.update(PLAATSING[naam])
        e["offset"] = [e["offset"][0] - RAND, e["offset"][1] - RAND]       # de rand van 1 px
        manifest["bladen"][naam] = e
    manifest["koppeling"] = {
        "state == FIGHT, fase 1": "lichaam idle; ketel schot (core_open: kern); rad draai_s0 frame 0 op (300, 120), achter het lichaam",
        "attack_started(kind, side)": "lichaam pomp_aanloop_<kant> of zwiep_aanloop_<kant> (de allereerste: aarzeling_<kant>, dan "
                                      "pomp_aanloop); tell_<kind> en het effect op attack_box",
        "attack_phase ACTIVE / RECOVER": "<kind>_slag/_veeg en daarna _ligt/_uit; tell actief; effect actief/herstel",
        "ketel.tink_tick": "ketel tink (4 ticks)",
        "shot_broken / core_closed": "ketel breuk -> kern / schot_sluit -> schot",
        "damaged (kern of finisherslag)": "ketel kern_geraakt en lichaam geraakt",
        "spout_glowing": "spuigat gloei op beide spuigaten, dan stoom",
        "phase_changed('wissel')": "lichaam fasewissel; ketel schot_dicht; rad draai met ticks_draaien vanaf (300, 120)",
        "rad_state HANGING / SHAKING / TURNING": "rad draai_s<n> / trilt_s<n> / draai_s<n> met ticks_draaien; rad_hit: treffer_s<n>",
        "scheur": "s<n> = min(3, rad_turns // 3): het rad scheurt per ± 3 kanten (voorstel UX §9.2, de UX Designer beslist)",
        "state == WANKEL / FINISHER": "lichaam wankel_in -> wankel (finisher_strike: geraakt); ketel merkplek_open -> merkplek",
        "boss_defeated": "lichaam oplossen, ketel oplossen en rad oplossen tegelijk; daarna niets meer tekenen (GM-10)",
    }
    pad = os.path.join(UIT_GAME, "gemaalmeester.json")
    m2 = dict(manifest)
    m2["import"] = m2.pop("import_")
    with open(pad, "w") as f:
        json.dump(m2, f, indent=1, ensure_ascii=False)
    nfr = sum(len(a["frames"]) for b in manifest["bladen"].values() for a in b["animaties"].values())
    print(f"  {len(bladen)} bladen, {nfr} frames per toestand -> {os.path.relpath(UIT_GAME, REPO)}")

    # --- renders
    for staat in ("grijs", "kleur"):
        D2.save(blad_overzicht(bladen, staat), os.path.join(UIT_DOCS, f"gemaalmeester_bladen_{staat}_x2.png"), 2)
    bg = s8_achtergrond()
    sc = {}
    for staat in ("grijs", "kleur"):
        sc[staat] = {
            "fase1": boss_beeld(bg[staat].copy(), staat, lichaam(pomp_poses(-1)[0][3], staat), ketel(staat, "schot", 0),
                                rad(staat, 0, 0), rad_achter=True,
                                effecten=[(tell(POMP_W, POMP_H, "laat"), MX - POMP_W, POMP_H),
                                          (pomp_effect(staat, "aanloop", 3), MX - POMP_W - 8, 36)]),
            "kern": boss_beeld(bg[staat].copy(), staat, lichaam(GERAAKT[0] if False else IDLE[1], staat), ketel(staat, "kern", 1),
                               rad(staat, 0, 0), rad_achter=True,
                               effecten=[(spuigat(staat, 2), s + CEL_SPUI[2], CEL_SPUI[3]) for s in SPUI]),
            "fase2": boss_beeld(bg[staat].copy(), staat, lichaam(zwiep_poses(1)[1][0], staat), ketel(staat, "dicht"),
                                rad(staat, 2, 1), rad_x=GM_RAD_X_LINKS,
                                effecten=[(tell(ZW_W, ZW_Y2 - ZW_Y1, "actief"), ARENA_W - ZW_W, ZW_Y2)]),
            "wankel": boss_beeld(bg[staat].copy(), staat, lichaam(WANKEL[0], staat), ketel(staat, "merkplek", 1),
                                 rad(staat, 3, 3), rad_x=GM_RAD_X_RECHTS),
        }
        # de zwiep-veeg over de tell heen
        zv = zwiep_effect(staat, "actief", 0)
        zv.mat, zv.t = zv.mat[:, ::-1].copy(), zv.t[:, ::-1].copy()
        plak(sc[staat]["fase2"], zv, staat, ARENA_W - ZW_W, 70)
        # P1 en de echo in de beelden (schaal)
        sc[staat]["fase1"] = D2.plak_fig(sc[staat]["fase1"], [("p1", SP.P1_RUN[0], WL + 200, VLOER, False, True),
                                                               ("echo", SP.P1_RUN[2], WL + 420, VLOER, True, staat == "kleur")], 0)
        sc[staat]["fase2"] = D2.plak_fig(sc[staat]["fase2"], [("p1", SP.P1_JUMP, WL + 98, VLOER - 112, False, True),
                                                               ("echo", SP.P1_RUN[1], WL + 78, VLOER, False, staat == "kleur")], 0)
        D2.save(sc[staat]["fase1"], os.path.join(UIT_DOCS, f"s8_gemaalmeester_fase1_{staat}_640x360.png"))
        D2.save(sc[staat]["fase2"], os.path.join(UIT_DOCS, f"s8_gemaalmeester_fase2_{staat}_640x360.png"))
    rij = []
    for staat in ("grijs", "kleur"):
        for nm, sub in (("FASE 1: POMPSLAG LINKS, AANLOOP (TELL 75 %)", "fase1"), ("OPENING: KERN OPEN, SPUIGATEN GLOEIEN", "kern"),
                        ("FASE 2: RAD LINKS (X 94), ZWIEP RECHTS ACTIEF", "fase2"), ("WANKEL: MERKPLEK, RAD GESCHEURD", "wankel")):
            rij += [D2.label_bar(640, f"{staat.upper()}  {nm}"), sc[staat][sub]]
    D2.save(np.concatenate(rij, 0), os.path.join(UIT_DOCS, "s8_gemaalmeester_momenten_x2.png"), 2)
    lum = np.concatenate([D2.label_bar(640, "LUMINANTIE", "GRIJS, FASE 1"), R.grayscale(sc["grijs"]["fase1"]),
                          D2.label_bar(640, "LUMINANTIE", "GRIJS, FASE 2"), R.grayscale(sc["grijs"]["fase2"]),
                          D2.label_bar(640, "DEUTERANOPIE", "GRIJS, FASE 1"), R.deuteranopia(sc["grijs"]["fase1"]),
                          D2.label_bar(640, "DEUTERANOPIE", "KLEUR, FASE 2"), R.deuteranopia(sc["kleur"]["fase2"])], 0)
    D2.save(lum, os.path.join(UIT_DOCS, "s8_gemaalmeester_leesbaarheid_x2.png"), 2)

    # --- metingen
    met = metingen(bg)
    print("  metingen (ΔL*; bible §6 regel 4, deel 1 §4.2):")
    for (staat, wat), v in met.items():
        print(f"    {staat:6s} {wat:42s} {v:5.1f}")
    eb, beelden = echo_bij_ketel(bg)
    print("  echo bij de ketel (CD #247): ΔL* rand echo / ΔL* bijna-zwarte contour over P1 (pixels)")
    for (staat, achter, d), (a, b, n) in eb.items():
        print(f"    {staat:6s} voor {achter:5s} afstand {d:2d} px: rand {a:5.1f}  contour over P1 {b:5.1f} ({n})")
    tegels = []
    for staat in ("grijs", "kleur"):
        r_ = [b for (s, k, d, b) in beelden if s == staat]
        tegels.append(np.concatenate([np.concatenate([x, np.zeros((x.shape[0], 2, 3)) + D1.BG], 1) for x in r_], 1))
    ke = np.concatenate([D2.label_bar(tegels[0].shape[1], "GRIJS", "SCHOT 6 / 3 PX, KERN 6 / 3 PX"), tegels[0],
                         D2.label_bar(tegels[0].shape[1], "KLEUR"), tegels[1]], 0)
    D2.save(ke, os.path.join(UIT_DOCS, "s8_gemaalmeester_ketel_echo_x4.png"), 4)

    # --- GIF van het gevecht (grijs, de toestand van het gevecht), 20 beelden per seconde
    seq = tijdlijn()
    cache = Cache()
    frames, tick = [], 0
    p1 = None
    for (n, wat, f) in seq:
        for t in range(0, n, 3):
            img = beeld_tick(bg["grijs"], "grijs", f(t), cache)
            img = np.concatenate([D2.label_bar(640, wat or " ", f"TICK {tick + t}"), img], 0)
            frames.append(Image.fromarray((np.clip(img, 0, 1) * 255 + 0.5).astype(np.uint8)))
        tick += n
    frames[0].save(os.path.join(UIT_DOCS, "s8_gemaalmeester_gevecht.gif"), save_all=True, append_images=frames[1:],
                   duration=50, loop=0, optimize=True)
    print(f"  GIF: {len(frames)} beelden, {tick} ticks ({tick / 60:.1f} s)")
    return met, eb


if __name__ == "__main__":
    main()
