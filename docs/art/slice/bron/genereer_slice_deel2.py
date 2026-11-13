"""Slice-art deel 2, de Kadewijk: eindkwaliteit voor de maatvaste kamers S1 en S3 (Art Director, #85, T8c).

Maakt de kamers S1 Kade-ingang en S3 Vismarkt op hun werkelijke geometrie
(`game/levels/kadewijk/kadewijk_layout.gd`, D = 60), in drie toestanden (grijs, half,
kleur) plus een index-laag voor de palet-LUT, als lagen per kamer:

  achter     lucht, verre daklijn, huizen (opaak, volle kamer)
  midden     decor achter de figuren (werf, kramen, vishal); geen collision
  speelvlak  alles waar je op staat of tegen loopt, precies op de blokken van de layout
  voor       voorgrond boven de figuren (alleen waar het spel niet leest)
  licht      halo's van de lampen (RGBA, boven speelvlak, onder de figuren)

Wat van D afhangt (de galerij en de treden van B1 in S1) zit níét in de lagen maar in
`kadewijk_eenrichting_*.png`: stukken voor een NinePatchRect die de TA op de rechthoeken
van `Layout.blocks()` zet. Zo blijft de art kloppen bij elke D.

Daarnaast renders voor de review in docs/art/slice/eindkwaliteit/ (met figuren ter
beoordeling; de figuren zitten niet in de assets).

Alles is eigen werk (docs/licenties.md §2): palet, tegels en figuren uit deel 1 en de
R5-scene, het eigen pixelfont. Geen externe assets.

Draaien vanaf de repo-root:  python3 docs/art/slice/bron/genereer_slice_deel2.py
"""
import json
import os
import sys

import numpy as np
from PIL import Image
from scipy import ndimage

HIER = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HIER)
import genereer_slice_deel1 as D1  # noqa: E402  (palet, tegels, props, vijanden; draait zelf niets)

R, SP = D1.R, D1.SP
MI, K, G, HALF, T = D1.MI, D1.K, D1.G, D1.HALF, D1.T
REPO = D1.REPO
UIT_GAME = os.path.join(REPO, "game", "art", "wereld", "kadewijk")
UIT_DOCS = os.path.join(REPO, "docs", "art", "slice", "eindkwaliteit")
os.makedirs(UIT_GAME, exist_ok=True)
os.makedirs(UIT_DOCS, exist_ok=True)
RAMPS = [G, HALF, K]                 # toestand 0 grijs, 1 half, 2 kleur
STATEN = ["grijs", "half", "kleur"]
hx = R.hx
tegel = D1.tegel

# ------------------------------------------------------------------ maten (kadewijk_layout.gd, D = 60)
D = 60
ONE_WAY_T = 6
ROOM_H = 360
S1 = dict(x=0, w=640)
S1_WALL, S1_FLOOR, S1_UP, S1_QUAY_LEFT = 20, 320, 230, 500
# Het snelluik (deel 3, PR #231): eenrichtingsluik in de gang, x 460..500 op 320; eronder de schacht naar S9.
SNELLUIK = (460, S1_FLOOR, 40)
S1_GANG_END = SNELLUIK[0]
S3 = dict(x=1600, w=960)
S3_ENTRY_RIGHT, S3_FLOOR, S2_TOP = 1680, 260, 70
S3_PLATFORMS = [(1820, 190, 120), (2180, 190, 120)]
TREAD_W = 40
# Werkaanname AD: het gemaal van S6 (nog niet gebouwd) staat rechts van S5, ± hier in
# wereldcoördinaten van de wijk. De TA leest de echte plek uit `wijk_gemaal` (kamerdoc §9).
GEMAAL_WERELD = (4960.0, 150.0)


def keerzone(d):
    return d + 30


def tread_90_width(d):
    return TREAD_W if d <= 60 else keerzone(d) - 14


def s1_eenrichting(d):
    """De D-afhankelijke eenrichtingsblokken van S1, zoals Layout.blocks(&"S1", d)."""
    z = keerzone(d)
    out = [("Galerij", "galerij", S1_WALL + z, S1_UP, S1_QUAY_LEFT - S1_WALL - z)]
    for h in (30, 60, 90):
        w = tread_90_width(d) if h == 90 else TREAD_W
        out.append((f"B1Trede{h}", "trede", S1_WALL, S1_FLOOR - h, w))
    out.append(("Snelluik", "snelluik", SNELLUIK[0], SNELLUIK[1], SNELLUIK[2]))   # vast, maar ook een stuk
    return out


# ------------------------------------------------------------------ kamer-canvas
LAGEN = ["lucht", "ver", "huizen", "midden", "speelvlak", "voor"]
LI = {n: i for i, n in enumerate(LAGEN)}
EXPORT = {"achter": ["lucht", "ver", "huizen"], "midden": ["midden"], "speelvlak": ["speelvlak"], "voor": ["voor"]}


class Kamer:
    """Een kamer als lagen van (materiaal, tint); mat -1 = leeg. Coördinaten lokaal (0,0 = linksboven)."""

    def __init__(self, naam, wx, w, h=ROOM_H):
        self.naam, self.wx, self.w, self.h = naam, wx, w, h
        self.mat = np.full((len(LAGEN), h, w), -1, np.int16)
        self.t = np.zeros((len(LAGEN), h, w), np.int16)
        self.emis = np.zeros((len(LAGEN), h, w), bool)   # eigen licht: houdt zijn kleur
        self.YY, self.XX = np.mgrid[0:h, 0:w]
        self.BAY = R.bayer(h, w)
        self.ramen = []      # dict(x, y, w, h, laag, aan={staat: bool}, kruis)
        self.lampen = []     # dict(x, y, r, aan={staat: bool}, sprite_uit, sprite_aan, sx, sy, laag)
        self.sterren = []
        self.wissel = []     # (laag, x, y, T_uit, T_aan, aan={staat: bool}): props met twee toestanden
        self.lucht_bundels = None
        self.warm_bundel = None

    # -- tekenen
    def rect(self, x0, y0, x1, y1):
        m = np.zeros((self.h, self.w), bool)
        m[max(0, int(y0)):min(self.h, int(y1)), max(0, int(x0)):min(self.w, int(x1))] = True
        return m

    def paint(self, m, laag, mat, t, emis=False):
        L = LI[laag]
        self.mat[L][m] = MI[mat]
        self.t[L][m] = t
        self.emis[L][m] = emis

    def add(self, m, laag, d):
        L = LI[laag]
        self.t[L][m & (self.mat[L] >= 0)] += d

    def stamp(self, tl, x, y, laag, dt=0, flip=False):
        L = LI[laag]
        mat, t = (tl.mat[:, ::-1], tl.t[:, ::-1]) if flip else (tl.mat, tl.t)
        hh, ww = mat.shape
        y0, x0 = max(0, y), max(0, x)
        y1, x1 = min(self.h, y + hh), min(self.w, x + ww)
        if y1 <= y0 or x1 <= x0:
            return
        sm = mat[y0 - y:y1 - y, x0 - x:x1 - x]
        st = t[y0 - y:y1 - y, x0 - x:x1 - x]
        ok = sm >= 0
        self.mat[L, y0:y1, x0:x1][ok] = sm[ok]
        self.t[L, y0:y1, x0:x1][ok] = st[ok] + dt
        self.emis[L, y0:y1, x0:x1][ok] = False

    def tegels(self, kies, x0, y0, x1, y1, laag, dt=0):
        """Vul de rechthoek met tegels; kies(i, j, x, y) -> tegelnaam (of T). Geknipt op de rechthoek."""
        L = LI[laag]
        for j, y in enumerate(range(y0, y1, 16)):
            for i, x in enumerate(range(x0, x1, 16)):
                nm = kies(i, j, x, y)
                if nm is None:
                    continue
                tl = tegel(nm) if isinstance(nm, str) else nm
                hh, ww = min(16, y1 - y), min(16, x1 - x)
                sm, st = tl.mat[:hh, :ww], tl.t[:hh, :ww]
                yy0, xx0 = max(0, y), max(0, x)
                sub_m = self.mat[L, yy0:y + hh, xx0:x + ww]
                ok = sm[:sub_m.shape[0], :sub_m.shape[1]] >= 0
                sub_m[ok] = sm[:sub_m.shape[0], :sub_m.shape[1]][ok]
                self.t[L, yy0:y + hh, xx0:x + ww][ok] = st[:sub_m.shape[0], :sub_m.shape[1]][ok] + dt
                self.emis[L, yy0:y + hh, xx0:x + ww][ok] = False

    # -- render
    def lichtband(self, staat_aan):
        band = np.zeros((self.h, self.w))
        for i, lp in enumerate(self.lampen):
            if not staat_aan(i, lp):
                continue
            r = lp["r"]
            d = np.hypot(self.XX - lp["x"], (self.YY - lp["y"]) * 1.15)
            grens = [14 * r, 30 * r, 52 * r, 80 * r]
            b = np.select([d < g for g in grens], [4, 3, 2, 1], 0).astype(float)
            nxt = np.select([d < g for g in grens], grens, grens[-1])
            frac = np.clip((nxt - d) / 6, 0, 1)
            b = np.where((frac < 1) & (self.BAY > frac) & (b > 0), b - 1, b)
            # wat achter een muur ligt, krijgt geen licht van de andere kant (eenvoudige occlusie per lamp)
            if lp.get("links_van") is not None:
                b[:, :lp["links_van"]] = 0
            if lp.get("boven_y") is not None:      # een luifel houdt het licht naar boven tegen
                b[:lp["boven_y"], :] = 0
            band = np.maximum(band, b)
        return band

    def toestand_kaart(self, staat=None, golf=None):
        """st per pixel: 0 grijs, 1 half, 2 kleur. golf = (r_half, r_vol) in px vanaf het gemaal."""
        if golf is None:
            return np.full((self.h, self.w), STATEN.index(staat), np.int8)
        gx, gy = GEMAAL_WERELD[0] - self.wx, GEMAAL_WERELD[1]
        d = np.hypot(self.XX - gx, self.YY - gy)
        edge = 10.0
        r_h, r_v = golf
        half = (d < r_h - edge) | ((d < r_h) & (self.BAY < (r_h - d) / edge))
        vol = (d < r_v - edge) | ((d < r_v) & (self.BAY < (r_v - d) / edge))
        st = np.zeros((self.h, self.w), np.int8)
        st[half] = 1
        st[vol] = 2
        return st

    def golf_aan(self, golf, x, y, jitter=0.0):
        if golf is None:
            return None
        gx, gy = GEMAAL_WERELD[0] - self.wx, GEMAAL_WERELD[1]
        return np.hypot(x - gx, y - gy) + jitter * 40 < golf[0]

    def render(self, staat="grijs", golf=None):
        """Geeft dict laag -> RGBA (h, w, 4), plus 'licht' (RGBA) en de toestandskaart."""
        st = self.toestand_kaart(staat, golf)
        sname = staat if golf is None else "golf"

        def is_aan(i, item):
            if golf is None:
                return item["aan"][staat]
            ga = self.golf_aan(golf, item["x"], item["y"], item.get("jit", 0))
            return bool(item["aan"]["grijs"] or ga)
        band = self.lichtband(is_aan)
        st = np.maximum(st, np.where(band >= 3, 2, np.where(band >= 2, 1, 0))).astype(np.int8)
        mat, t, emis = self.mat.copy(), self.t.copy(), self.emis.copy()
        # props met twee toestanden (lampen, boograam)
        for (laag, x, y, tu, ta, aan) in self.wissel:
            item = dict(x=x + ta.mat.shape[1] / 2, y=y + ta.mat.shape[0] / 2, aan=aan)
            tl = ta if is_aan(0, item) else tu
            L = LI[laag]
            hh, ww = tl.mat.shape
            ok = tl.mat >= 0
            mat[L, y:y + hh, x:x + ww][ok] = tl.mat[ok]
            t[L, y:y + hh, x:x + ww][ok] = tl.t[ok]
            gl = ok & (tl.mat == MI["gloed"])
            emis[L, y:y + hh, x:x + ww][gl] = True
        # ramen
        for rm in self.ramen:
            L = LI[rm["laag"]]
            x, y, w, h = rm["x"], rm["y"], rm["w"], rm["h"]
            if x < 0 or y < 0 or x + w > self.w or y + h > self.h:
                continue
            aan = is_aan(0, dict(x=x, y=y, aan=rm["aan"], jit=rm["jit"]))
            sub_m, sub_t, sub_e = mat[L, y:y + h, x:x + w], t[L, y:y + h, x:x + w], emis[L, y:y + h, x:x + w]
            yy, xx = np.mgrid[0:h, 0:w]
            if aan:
                sub_m[:] = MI["raam"]
                sub_t[:] = 5
                sub_t[yy >= h // 2] = 4
                sub_t[(yy == 0) | (xx == 0)] = 6
                sub_e[:] = True
                if rm.get("gordijn"):
                    g = (xx < 2) | (xx >= w - 2)
                    sub_t[g] = 3
            else:
                sub_m[:] = MI["raamdonker"]
                sub_t[:] = 2
                sub_t[yy >= h // 2] = 1
                sub_t[(yy == 1) & (xx == 1)] = 4
                sub_e[:] = False
            if rm.get("kruis", True):
                kr = (xx == w // 2) | (yy == h // 3)
                sub_m[kr] = MI["ijzer"] if aan else MI["raamdonker"]
                sub_t[kr] = 2 if aan else 0
                sub_e[kr] = False
        uit = {}
        omg_all = np.where(st == 0, -1, 0)
        for L, ln in enumerate(LAGEN):
            ok = mat[L] >= 0
            omg = omg_all if L >= LI["huizen"] else 0
            ti = np.clip(t[L] + omg + band.astype(int) * (L >= LI["huizen"]), 0, 7)
            img = np.zeros((self.h, self.w, 4))
            for s in range(3):
                m = ok & (st == s) & ~emis[L]
                img[m, :3] = RAMPS[s][mat[L][m], ti[m]]
            m = ok & emis[L]
            img[m, :3] = K[mat[L][m], np.clip(t[L][m], 0, 7)]
            img[ok, 3] = 1
            uit[ln] = img
        # lucht: sterren (kleur), bundels (koud in grijs, warm in kleur)
        lucht = uit["lucht"]
        vrij = (mat[LI["ver"]] < 0) & (mat[LI["huizen"]] < 0)
        if self.lucht_bundels is not None:
            kb = self.lucht_bundels & vrij & (st == 0)
            lucht[kb, :3] = G[MI["lucht"], 5]
        if self.warm_bundel is not None:
            wb = self.warm_bundel & vrij & (st == 2)
            lucht[wb, :3] = K[MI["gloed"], 1]
        for (x, y, k) in self.sterren:
            if st[y, x] == 2 and vrij[y, x]:
                lucht[y, x, :3] = K[MI["huis_wit"], 7] if k else K[MI["gloed"], 6]
        # licht-laag: halo's
        licht = np.zeros((self.h, self.w, 4))
        for i, lp in enumerate(self.lampen):
            if not is_aan(i, lp) or not lp.get("halo", True):
                continue
            hl = D1.halo().render("kleur")
            D1_stamp_rgba4(licht, hl, int(lp["x"]) - 16, int(lp["y"]) - 16)
        uit["licht"] = licht
        uit["_st"] = st
        uit["_naam"] = sname
        return uit

    def samengesteld(self, lagen, figuren=None):
        img = np.zeros((self.h, self.w, 3))
        for ln in ["lucht", "ver", "huizen", "midden", "speelvlak", "licht"]:
            img = over(img, lagen[ln])
        if figuren is not None:
            img = figuren(img)
        img = over(img, lagen["voor"])
        return img

    def index_laag(self, namen):
        """R = materiaal-id, G = tint x 32 + 16, B = 255 voor een raam (kan aan), A = 255; leeg = A 0."""
        out = np.zeros((self.h, self.w, 4), np.uint8)
        ramen = np.zeros((len(LAGEN), self.h, self.w), bool)
        for rm in self.ramen:
            ramen[LI[rm["laag"]], rm["y"]:rm["y"] + rm["h"], rm["x"]:rm["x"] + rm["w"]] = True
        for ln in namen:
            L = LI[ln]
            ok = self.mat[L] >= 0
            out[ok, 0] = self.mat[L][ok]
            out[ok, 1] = np.clip(self.t[L][ok], 0, 7) * 32 + 16
            out[ok, 2] = np.where(ramen[L][ok], 255, 0)
            out[ok, 3] = 255
        return out


def over(img, layer):
    a = layer[..., 3:4]
    return img * (1 - a) + layer[..., :3] * a


def D1_stamp_rgba4(dst, lay, x, y):
    """RGBA over RGBA (voor de licht-laag)."""
    h, w = lay.shape[:2]
    H_, W_ = dst.shape[:2]
    ys0, xs0, ys1, xs1 = max(0, y), max(0, x), min(H_, y + h), min(W_, x + w)
    if ys1 <= ys0 or xs1 <= xs0:
        return
    sub = lay[ys0 - y:ys1 - y, xs0 - x:xs1 - x]
    a = sub[..., 3:4]
    d = dst[ys0:ys1, xs0:xs1]
    d[..., :3] = d[..., :3] * (1 - a) + sub[..., :3] * a
    d[..., 3:4] = np.maximum(d[..., 3:4], a)


def rng(seed):
    return np.random.default_rng(seed)


# ------------------------------------------------------------------ nieuwe tegels en props (eindkwaliteit)
def galerij_stuk():
    """NinePatch 48x16 voor de galerij (eenrichting, 6 px dik): eiken dek op ijzeren consoles.
    Links 16 = kop, midden 16 = herhaalbaar, rechts 16 = kop. Loopvlak = rij 0."""
    t = T(48, 16)
    yy, xx = np.mgrid[0:16, 0:48]
    t.box(0, 0, 48, 6, "hout", 4)
    t.box(0, 0, 48, 1, "hout", 6)
    t.box(0, 1, 48, 2, "hout", 5)
    t.fill((yy >= 2) & (yy <= 4) & (xx % 12 == 11), "hout", 2)          # plankvoegen
    t.fill((yy == 3) & (xx % 7 == 3), "hout", 3)                       # nerf
    t.box(0, 5, 48, 6, "hout", 2)
    t.box(0, 6, 48, 7, "ijzer", 2)                                     # ijzeren ligger
    # console onder het midden van elk deel (ijzeren schoor met krul)
    for cx in (8, 24, 40):
        t.fill((xx >= cx - 1) & (xx <= cx) & (yy >= 7) & (yy <= 14), "ijzer", 4)
        t.fill((xx == cx - 1) & (yy >= 7) & (yy <= 14), "ijzer", 6)
        sch = (np.abs((xx - cx) - (yy - 7)) < 0.6) & (yy >= 7) & (yy <= 13) & (xx > cx)
        t.fill(sch, "ijzer", 3)
        t.fill((np.hypot(xx - (cx + 3.5), yy - 10.5) < 1.6) & (np.hypot(xx - (cx + 3.5), yy - 10.5) > 0.7), "ijzer", 5)
    # koppen: kopse kant van de planken
    t.box(0, 0, 2, 6, "hout", 3)
    t.box(0, 0, 1, 6, "hout", 2)
    t.box(46, 0, 48, 6, "hout", 3)
    t.box(47, 0, 48, 6, "hout", 2)
    t.fill((xx == 2) & (yy == 3), "ijzer", 6)
    t.fill((xx == 45) & (yy == 3), "ijzer", 6)
    return t


def trede_stuk():
    """NinePatch 48x16 voor een trede tegen de keerwand (eenrichting, 6 px): hardstenen console.
    Links 16 = in de muur, midden herhaalbaar, rechts 16 = afgeronde neus. Loopvlak = rij 0."""
    t = T(48, 16)
    yy, xx = np.mgrid[0:16, 0:48]
    t.box(0, 0, 48, 6, "steen", 4)
    t.box(0, 0, 48, 1, "steen", 6)
    t.box(0, 1, 48, 2, "steen", 5)
    t.box(0, 5, 48, 6, "steen", 2)
    t.fill((yy >= 2) & (yy <= 4) & (xx % 16 == 15) & (xx < 40), "steen", 2)
    r = rng(41)
    t.fill((r.random((16, 48)) < 0.06) & (yy >= 2) & (yy <= 4), "steen", 3)
    # neus
    t.fill((xx == 47) & (yy <= 5), "steen", -1 + 2)
    t.fill((xx == 47) & (yy == 0), "steen", 4)
    # onderkant: kraagsteen onder de muurkant (links), schaduw onder het midden
    kraag = (xx < 14) & (yy >= 6) & (yy < 6 + (14 - xx) * 0.7)
    t.fill(kraag, "steen", 3)
    t.fill(kraag & (yy == 6), "steen", 2)
    t.fill(kraag & (xx == 0), "steen", 2)
    t.fill((yy == 6) & (xx >= 14) & (xx < 46), "steen", 1)
    # ijzeren anker op de neus
    t.fill((xx >= 40) & (xx <= 41) & (yy >= 6) & (yy <= 8), "ijzer", 3)
    return t


def snelluik_stuk():
    """NinePatch 48x16 voor het snelluik (S1, x 460..500, eenrichting van onder): eiken luik in een
    ijzeren kader, met ringgreep. Links/rechts 16 = kader, midden herhaalbaar. Loopvlak = rij 0."""
    t = T(48, 16)
    yy, xx = np.mgrid[0:16, 0:48]
    t.box(0, 0, 48, 6, "hout", 4)
    t.fill((yy <= 5) & (xx % 6 == 5), "hout", 2)                       # planken
    t.fill((yy == 3) & (xx % 6 == 2), "hout", 4)
    t.box(0, 0, 48, 1, "steen", 7)                                      # hardstenen sponning (loopvlak, licht)
    t.box(0, 1, 48, 2, "hout", 6)
    t.box(0, 5, 48, 6, "ijzer", 2)
    t.box(0, 0, 3, 6, "ijzer", 4)
    t.box(45, 0, 48, 6, "ijzer", 4)
    t.fill((yy == 3) & ((xx == 1) | (xx == 46)), "ijzer", 6)            # klinknagels
    # scharnieren links, ringgreep rechts
    t.box(4, 2, 12, 4, "ijzer", 2)
    t.box(4, 2, 12, 3, "ijzer", 4)
    t.fill(np.abs(np.hypot(xx - 39.5, yy - 3.0) - 1.8) < 0.6, "ijzer", 5)
    # onderkant: de schacht in, met de balk die het luik draagt
    t.box(0, 6, 3, 10, "ijzer", 2)
    t.box(45, 6, 48, 10, "ijzer", 2)
    t.fill((yy >= 6) & (yy <= 7) & (xx >= 3) & (xx < 45), "raamdonker", 1)
    return t


def ninepatch(t_full, w):
    """Zet een NinePatch-stuk uit op breedte w (links 16, midden herhaald, rechts 16), als de engine doet."""
    assert w >= 32, "eenrichtingsblokken zijn minstens 40 px breed"
    out = T(w, 16)
    src = np.r_[np.arange(16), 16 + (np.arange(w - 32) % 16), np.arange(32, 48)]
    out.mat[:] = t_full.mat[:, src]
    out.t[:] = t_full.t[:, src]
    return out


EENRICHTING = {"galerij": galerij_stuk(), "trede": trede_stuk(), "snelluik": snelluik_stuk()}
EENR_VOLGORDE = ["galerij", "trede", "snelluik"]


def kasseien(seed):
    """Kinderkopjes (keien) als loopvlak van de markt; bovenrij licht, voegen donker."""
    t = T()
    yy, xx = np.mgrid[0:16, 0:16]
    t.fill(yy >= 0, "steen", 2)
    r = rng(seed)
    for row, (y0, hgt) in enumerate([(0, 5), (5, 5), (10, 6)]):
        off = (row * 3 + seed) % 6
        x = -off
        while x < 16:
            bw = int(r.integers(5, 8))
            m = (xx >= x + 1) & (xx < x + bw) & (yy >= y0 + (1 if row else 0)) & (yy < y0 + hgt)
            base = 4 if row == 0 else (3 if row == 1 else 2)
            base += int(r.integers(-1, 1))
            t.fill(m, "steen", base)
            top = m & (yy == y0 + (1 if row else 0))
            t.fill(top, "steen", base + 2)
            t.fill(m & (xx == x + 1), "steen", base + 1)
            x += bw
    t.box(0, 0, 16, 1, "steen", 6)
    return t


def kraam_luifel(w=120):
    """Luifel van een viskraam, w x 18: het loopvlak (6 px) is de houten lat met het zeil,
    eronder de geschulpte rand. Eenrichting op rij 0 (collision Kraam1/2)."""
    t = T(w, 18)
    yy, xx = np.mgrid[0:18, 0:w]
    streep = (xx // 10) % 2 == 0
    # zeil (strepen), 6 px: de bovenkant is het loopvlak
    t.fill((yy < 6) & streep, "huis_groen", 4)
    t.fill((yy < 6) & ~streep, "huis_wit", 5)
    # bovenkant = loopvlak: een lichte lat (huis_wit 7/6), zodat de rand in grijs en kleur leest
    t.fill((yy == 0), "huis_wit", 7)
    t.fill((yy == 1), "huis_wit", 6)
    t.fill((yy == 2) & streep, "huis_groen", 2)
    t.fill((yy == 2) & ~streep, "huis_wit", 3)
    t.fill((yy == 5), "hout", 3)
    # geschulpte rand
    sch = (yy >= 6) & (yy < 6 + 4 + np.round(2.5 * np.cos((xx % 10 - 4.5) / 4.5 * np.pi / 2)).astype(int))
    t.fill(sch & streep, "huis_groen", 3)
    t.fill(sch & ~streep, "huis_wit", 4)
    rand = sch & ~np.vstack([sch[1:], np.zeros((1, w), bool)])
    t.fill(rand & streep, "huis_groen", 2)
    t.fill(rand & ~streep, "huis_wit", 3)
    t.box(0, 0, 2, 7, "hout", 3)
    t.box(w - 2, 0, w, 7, "hout", 3)
    return t


def kraam_onder(w=120, seed=0, lamp=False):
    """Frame, toonbank en koopwaar van een kraam onder de luifel (decor, geen collision), w x 64."""
    t = T(w, 64)
    yy, xx = np.mgrid[0:64, 0:w]
    # palen
    for px in (3, w - 6):
        t.box(px, 0, px + 3, 64, "hout", 3)
        t.box(px, 0, px + 1, 64, "hout", 5)
        t.box(px + 2, 0, px + 3, 64, "hout", 2)
    # achterwand: zeil, half opgerold
    t.box(6, 2, w - 6, 8, "huis_wit", 3)
    t.fill((yy >= 2) & (yy < 8) & (xx % 10 < 5) & (xx >= 6) & (xx < w - 6), "huis_groen", 2)
    t.box(6, 8, w - 6, 9, "hout", 2)
    # toonbank: schuine plank met ijs en vis
    t.box(6, 36, w - 6, 44, "hout", 3)
    t.box(6, 36, w - 6, 37, "hout", 5)
    t.box(6, 43, w - 6, 44, "hout", 1)
    t.fill((yy >= 44) & (yy < 64) & (xx >= 10) & (xx < w - 10) & (xx % 18 < 2), "hout", 2)  # schragen
    t.box(8, 31, w - 8, 36, "steen", 5)         # ijs (steen, nooit de FelLicht-ramp: wit-blauw is gameplay)
    t.box(8, 31, w - 8, 32, "steen", 6)
    r = rng(seed)
    x = 10
    while x < w - 20:
        lw = int(r.integers(9, 13))
        vis = (np.hypot((xx - x - lw / 2) / (lw / 2), (yy - 31) / 2.2) < 1) & (yy < 33)
        staart = (np.abs(yy - 31) <= (xx - (x + lw)) * 0.8) & (xx >= x + lw) & (xx < x + lw + 3)
        t.fill(vis | staart, "steen", 6)
        t.fill(vis & (yy >= 31), "steen", 4)
        t.fill((xx == x + 2) & (yy == 30), "raamdonker", 0)
        x += lw + int(r.integers(2, 5))
    # manden en kisten onder de toonbank
    for kx in range(14, w - 24, 30):
        if r.random() < 0.5:
            t.box(kx, 50, kx + 18, 64, "hout", 3)
            t.box(kx, 50, kx + 18, 51, "hout", 5)
            t.fill((yy >= 50) & (xx >= kx) & (xx < kx + 18) & ((yy - 50) % 5 == 4), "hout", 2)
        else:
            mand = (np.hypot((xx - kx - 9) / 9, (yy - 64) / 12) < 1) & (yy < 64)
            t.fill(mand, "hout", 4)
            t.fill(mand & ((xx + yy) % 3 == 0), "hout", 2)
            t.fill(mand & (yy == 53), "hout", 5)
    # haken met hangende vis aan de voorlat
    for hx_ in range(16, w - 16, 22):
        t.box(hx_, 9, hx_ + 1, 14, "ijzer", 4)
        v = (np.abs(xx - hx_) <= 1 + (yy - 14) // 4) & (yy >= 14) & (yy < 22) & (np.abs(xx - hx_) <= 2)
        t.fill(v, "steen", 5)
        t.fill(v & (xx > hx_), "steen", 3)
    return t


def wandlamp():
    """Lantaarn aan een muurarm, 16x24 (bible §4.2: kern in een donker ijzeren frame). aan/uit."""
    def mk(aan):
        t = T(16, 24)
        yy, xx = np.mgrid[0:24, 0:16]
        t.box(0, 3, 9, 4, "ijzer", 3)                    # arm
        t.fill((np.abs((xx - 1) - (yy - 4) * 1.4) < 0.7) & (yy >= 4) & (yy <= 9), "ijzer", 3)
        t.box(0, 2, 2, 12, "ijzer", 2)                   # muurplaat
        t.box(8, 4, 9, 7, "ijzer", 4)                    # haak
        t.box(5, 7, 12, 8, "ijzer", 4)                   # kap
        t.box(6, 6, 11, 7, "ijzer", 3)
        t.box(5, 8, 12, 18, "ijzer", 2)                  # frame
        if aan:
            t.box(6, 9, 11, 17, "gloed", 5)
            t.box(7, 10, 10, 16, "gloed", 6)
            t.box(8, 11, 9, 15, "gloed", 7)
        else:
            t.box(6, 9, 11, 17, "raamdonker", 3)
            t.box(7, 10, 8, 12, "raamdonker", 5)
        t.fill((xx == 8) & (yy >= 8) & (yy < 18), "ijzer", 3)
        t.box(6, 18, 11, 19, "ijzer", 4)
        t.box(8, 19, 9, 21, "ijzer", 3)
        return t
    return mk(False), mk(True)


def kraamlamp():
    """Olielamp aan een ketting onder de luifel, 8x16."""
    def mk(aan):
        t = T(8, 16)
        t.box(3, 0, 5, 5, "ijzer", 3)
        t.fill(np.zeros((16, 8), bool), "ijzer", 0)
        t.box(1, 5, 7, 6, "ijzer", 4)
        t.box(1, 6, 7, 13, "ijzer", 2)
        if aan:
            t.box(2, 7, 6, 12, "gloed", 6)
            t.box(3, 8, 5, 11, "gloed", 7)
        else:
            t.box(2, 7, 6, 12, "raamdonker", 3)
        t.box(2, 13, 6, 14, "ijzer", 4)
        return t
    return mk(False), mk(True)


def straatlamp():
    return D1.lamp(False), D1.lamp(True)


def ton(seed):
    """Harington 14x16."""
    t = T(14, 16)
    yy, xx = np.mgrid[0:16, 0:14]
    m = np.abs(xx - 6.5) <= 6 - np.abs(yy - 7.5) * 0.18
    t.fill(m, "hout", 3)
    t.fill(m & (xx <= 2), "hout", 2)
    t.fill(m & (xx >= 9) & (xx <= 10), "hout", 4)
    t.fill(m & ((yy == 3) | (yy == 12)), "ijzer", 3)
    t.fill(m & (yy == 0), "hout", 5)
    return t


def rad_ver(aan):
    """Het rad van het gemaal in de verte, 58x58, in een ronde sleuf; aan = warm licht erachter."""
    t = T(58, 58)
    yy, xx = np.mgrid[0:58, 0:58]
    dr = np.hypot(xx - 28.5, yy - 28.5)
    ang = np.arctan2(yy - 28.5, xx - 28.5)
    if aan:
        t.fill(dr < 22, "gloed", 2)
        t.fill(dr < 15, "gloed", 3)
        t.fill(dr < 7, "gloed", 4)
    else:
        t.fill(dr < 22, "raamdonker", 0)
    spaak = (dr < 22) & (np.abs(np.sin(ang * 4)) * dr < 1.0)
    velg = np.abs(dr - 21) < 1.6
    schoep = (dr >= 22) & (dr < 28) & (np.abs(np.sin(ang * 4)) * dr < 2.2)
    t.fill(spaak | velg | (dr < 3), "ijzer", 1)
    t.fill(schoep, "hout", 1)
    return t


def bolder_klein():
    return D1.bolder()


# ------------------------------------------------------------------ bouwstenen van de achtergrond
def lucht_en_ver(k, seed, belfort=None, gemaal=None, top_range=(120, 160)):
    h, w = k.h, k.w
    YY, XX = k.YY, k.XX
    v = 1 + (YY / h * 4.6) + (k.BAY - 0.5)
    k.paint(np.ones((h, w), bool), "lucht", "lucht", 0)
    k.t[LI["lucht"]] = np.clip(v, 0, 5).astype(np.int16)
    r = rng(seed)
    # verre daklijn met torens en schoorstenen
    ver = np.zeros((h, w), bool)
    x = -int(r.integers(0, 20))
    while x < w:
        bw = int(r.integers(14, 34))
        top = int(r.integers(*top_range))
        ver[top:, max(0, x):x + bw] = True
        if r.random() < 0.35:
            # trapgevel in de verte
            for s in range(3):
                ver[top - 5 * (s + 1):top, max(0, x + 4 * (s + 1)):max(0, x + bw - 4 * (s + 1))] = True
        if r.random() < 0.25:
            cx = x + bw // 2
            ver[top - 18:top, max(0, cx - 1):cx + 2] = True
        x += bw
    k.paint(ver, "ver", "ver", 2)
    k.add(ver & (k.BAY < 0.25) & ((YY % 6) < 1), "ver", -1)
    if belfort is not None:
        bx, btop = belfort
        bel = k.rect(bx, btop + 60, bx + 26, h) | k.rect(bx + 4, btop + 26, bx + 22, btop + 60)
        bel |= k.rect(bx + 8, btop + 8, bx + 18, btop + 26) | k.rect(bx + 11, btop - 6, bx + 15, btop + 8)
        bel |= k.rect(bx + 12, btop - 14, bx + 14, btop - 6)
        k.paint(bel, "ver", "ver", 3)
        k.paint(bel & (XX < bx + 3), "ver", "ver", 2)
        galm = k.rect(bx + 7, btop + 34, bx + 10, btop + 48) | k.rect(bx + 16, btop + 34, bx + 19, btop + 48)
        k.paint(galm, "ver", "raamdonker", 2)
        wijzer = (np.hypot(XX - (bx + 13), YY - (btop + 72)) < 4.5)
        k.paint(wijzer, "ver", "ver", 4)
        k.paint(wijzer & (np.hypot(XX - (bx + 13), YY - (btop + 72)) < 3.2), "ver", "ver", 2)
        k.warm_bundel = (np.abs((XX - bx - 13) * 0.42 - (YY - btop - 40) * -0.95) < 22) & (YY < btop + 40) & (k.BAY < 0.32)
        k.ramen.append(dict(x=bx + 7, y=btop + 34, w=3, h=14, laag="ver", aan=dict(grijs=False, half=True, kleur=True), jit=0.2, kruis=False))
        k.ramen.append(dict(x=bx + 16, y=btop + 34, w=3, h=14, laag="ver", aan=dict(grijs=False, half=True, kleur=True), jit=0.3, kruis=False))
    if gemaal is not None:
        gx0, gx1, gtop = gemaal
        gm = k.rect(gx0, gtop + 24, gx1, h) | k.rect(gx0 + 10, gtop, gx1 - 10, gtop + 24)
        for s in range(4):
            gm |= k.rect(gx0 + 18 + 7 * s, gtop - 7 * (s + 1), gx1 - 18 - 7 * s, gtop)
        sch = k.rect(gx1 - 30, gtop - 50, gx1 - 22, gtop)
        gm |= sch
        k.paint(gm, "ver", "baksteen", 1)
        k.add(gm & ((YY % 4) == 0) & (k.BAY < 0.5), "ver", -1)
        k.paint(gm & (XX < gx0 + 3), "ver", "baksteen", 0)
        k.paint(sch & (YY < gtop - 46), "ver", "baksteen", 2)
        cx = (gx0 + gx1) // 2
        # boograam (uit = zwart, aan = warm met de machine erachter) en het rad als donkere cirkel
        bg_u, bg_a = D1.boograam(False), D1.boograam(True)
        k.wissel.append(("ver", cx - 40, gtop + 30, bg_u, bg_a, dict(grijs=False, half=True, kleur=True)))
        rx, ry = cx + 28, gtop + 84
        # het rad in een ronde sleuf: uit = de donkerste vorm in beeld (kleurscript S1),
        # aan = de spaken als silhouet tegen het warme licht van de machinekamer
        k.wissel.append(("ver", rx - 29, ry - 29, rad_ver(False), rad_ver(True), dict(grijs=False, half=True, kleur=True)))
        k.paint(k.rect(rx - 30, ry + 26, rx + 30, ry + 30), "ver", "steen", 2)
    # sterren (alleen zichtbaar in kleur) en koude bundels (grijs)
    for _ in range(int(w * 0.12)):
        k.sterren.append((int(r.integers(0, w)), int(r.integers(4, 140)), bool(r.random() < 0.7)))
    k.lucht_bundels = (((XX * 0.6 + YY) % 110) < 8) & (k.BAY < 0.28) & (YY < 210)


GEVEL_MATS = ["huis_rood", "huis_oker", "huis_wit", "huis_groen"]


def gevel(k, x0, bw, top, grond, mat, seed, laag="huizen", vorm="trap", lit_p=0.65, winkel=False,
          grijs_aan=()):
    """Een gevel met trap-, klok- of tuitgevel; ramen per verdieping (aan/uit per toestand)."""
    YY, XX = k.YY, k.XX
    r = rng(seed)
    m = k.rect(x0, top, x0 + bw, grond)
    kap = np.zeros_like(m)
    if vorm == "trap":
        n = 4
        sw = max(4, (bw // 2 - 6) // n)
        for s in range(n):
            kap |= k.rect(x0 + sw * (s + 1), top - 8 * (s + 1), x0 + bw - sw * (s + 1), top)
        kap |= k.rect(x0 + bw // 2 - 3, top - 8 * n - 6, x0 + bw // 2 + 3, top - 8 * n)
    elif vorm == "klok":
        hh = min(30, bw // 2)
        kap |= (np.hypot((XX - (x0 + bw / 2)) / (bw / 2 - 4), (YY - top) / hh) < 1) & (YY < top) & (XX > x0 + 3) & (XX < x0 + bw - 3)
        kap |= k.rect(x0 + bw // 2 - 5, top - hh - 4, x0 + bw // 2 + 5, top - hh + 4)
    else:  # tuit
        kap |= k.rect(x0 + 6, top - 10, x0 + bw - 6, top)
        kap |= k.rect(x0 + bw // 2 - 8, top - 30, x0 + bw // 2 + 8, top - 10)
        kap |= (np.abs(XX - (x0 + bw / 2)) < (top - YY - 26) * -0.9 + 8) & (YY >= top - 40) & (YY < top - 30)
    body = m | kap
    k.paint(body, laag, mat, 3)
    # textuur: baksteen (rood, oker) of pleister (wit, groen)
    if mat in ("huis_rood", "huis_oker"):
        row = (YY - top) // 3
        voeg = ((YY - top) % 3 == 0) | (((XX - x0) + (row % 2) * 4) % 8 == 0)
        k.add(body & voeg & (k.BAY < 0.6), laag, -1)
    else:
        k.add(body & (k.BAY < 0.12) & (((XX * 7 + YY * 3 + seed) % 11) == 0), laag, -1)
        k.add(body & ((YY - top) % 24 == 23), laag, -1)
    # randen: schaduwkant links, lichtkant rechts, afdekstenen op de treden
    e = body & ~ndimage.binary_erosion(body)
    k.add(e & (XX <= x0 + 1), laag, -2)
    rand_boven = body & ~np.vstack([np.zeros((1, k.w), bool), body[:-1]])
    k.paint(rand_boven, laag, "steen", 5)
    k.paint(ndimage.binary_dilation(rand_boven, structure=np.array([[0], [1], [1]])) & body & ~rand_boven, laag, "steen", 3)
    k.add(body & (XX >= x0 + bw - 2), laag, 1)
    # lijst boven de begane grond en speklagen
    lijst = k.rect(x0, grond - 40, x0 + bw, grond - 37)
    k.paint(lijst, laag, "steen", 4)
    k.paint(k.rect(x0, grond - 40, x0 + bw, grond - 39), laag, "steen", 6)
    if mat == "huis_rood" and r.random() < 0.6:
        for yy0 in range(top + 18, grond - 44, 26):
            k.paint(k.rect(x0, yy0, x0 + bw, yy0 + 2), laag, "steen", 4)
    # ramen per verdieping
    cols = max(1, (bw - 8) // 16)
    marge = (bw - cols * 16) // 2 + 4
    vy = list(range(top + 10, grond - 56, 26))
    for vi, wy in enumerate(vy):
        for c in range(cols):
            wx = x0 + marge + c * 16
            k.paint(k.rect(wx - 1, wy - 2, wx + 9, wy + 15), laag, "steen", 5)      # kozijn en latei
            k.paint(k.rect(wx - 1, wy - 2, wx + 9, wy - 1), laag, "steen", 6)
            k.paint(k.rect(wx - 2, wy + 14, wx + 10, wy + 16), laag, "steen", 4)    # dorpel
            if mat == "huis_groen" or (mat == "huis_wit" and seed % 2):
                k.paint(k.rect(wx - 4, wy, wx - 1, wy + 14), laag, "hout", 3)        # luiken
                k.paint(k.rect(wx + 9, wy, wx + 12, wy + 14), laag, "hout", 3)
                k.paint(k.rect(wx - 4, wy, wx - 3, wy + 14), laag, "hout", 2)
            aan_k = bool(r.random() < lit_p)
            k.ramen.append(dict(x=wx, y=wy, w=8, h=13, laag=laag, jit=float(r.random()), gordijn=bool(r.random() < 0.4),
                                aan=dict(grijs=(vi, c) in grijs_aan, half=aan_k, kleur=aan_k)))
    # in de trapgevel: een zolderluik of oculus
    if vorm == "trap":
        cy = top - 14
        k.paint(np.hypot(XX - (x0 + bw / 2 - 0.5), YY - cy) < 3.5, laag, "steen", 5)
        k.ramen.append(dict(x=x0 + bw // 2 - 2, y=cy - 2, w=4, h=4, laag=laag, jit=0.5, kruis=False,
                            aan=dict(grijs=False, half=False, kleur=bool(r.random() < 0.4))))
    # begane grond: deur, winkelraam
    dx = x0 + (bw - 12 if seed % 2 else 4)
    k.paint(k.rect(dx - 1, grond - 25, dx + 11, grond), laag, "steen", 5)
    k.paint(k.rect(dx, grond - 24, dx + 10, grond), laag, "hout", 2)
    k.paint(k.rect(dx + 1, grond - 23, dx + 9, grond - 13), laag, "hout", 3)
    k.paint(k.rect(dx + 7, grond - 12, dx + 8, grond - 11), laag, "ijzer", 6)
    k.paint(k.rect(dx, grond - 30, dx + 10, grond - 26), laag, "raamdonker", 2)       # bovenlicht
    if winkel or bw >= 56:
        sx = x0 + (8 if seed % 2 else bw - 30)
        k.paint(k.rect(sx - 1, grond - 30, sx + 23, grond - 6), laag, "hout", 3)
        k.ramen.append(dict(x=sx, y=grond - 28, w=22, h=18, laag=laag, jit=float(r.random()), kruis=True,
                            aan=dict(grijs=False, half=True, kleur=True)))
        k.paint(k.rect(sx - 2, grond - 6, sx + 24, grond - 4), laag, "steen", 4)
    # muurankers
    for ay in range(top + 22, grond - 44, 26):
        for ax in (x0 + 3, x0 + bw - 5):
            k.paint(k.rect(ax, ay, ax + 2, ay + 5), laag, "ijzer", 2)
            k.paint(k.rect(ax - 1, ay + 2, ax + 3, ay + 3), laag, "ijzer", 2)
    # schoorsteen
    if vorm != "trap" and r.random() < 0.7:
        sx = x0 + int(r.integers(4, max(5, bw - 10)))
        k.paint(k.rect(sx, top - 10, sx + 5, top + 1), laag, "baksteen", 2)
        k.paint(k.rect(sx - 1, top - 11, sx + 6, top - 9), laag, "steen", 4)
    # regenpijp
    pijp = x0 + bw - 1
    k.paint(k.rect(pijp, top, pijp + 1, grond), laag, "ijzer", 2)
    return body


def huizenrij(k, x0, x1, grond, seed, top_lo, top_hi, laag="huizen", grijs_aan=(), lit_p=0.65):
    r = rng(seed)
    x = x0
    i = 0
    alle = np.zeros((k.h, k.w), bool)
    while x < x1:
        bw = int(r.choice([44, 48, 52, 56, 60, 64]))
        bw = min(bw, x1 - x) if x1 - x > 36 else bw
        top = int(r.integers(top_lo, top_hi))
        mat = GEVEL_MATS[(i + seed) % 4] if r.random() < 0.8 else GEVEL_MATS[int(r.integers(0, 4))]
        vorm = ["trap", "klok", "trap", "tuit"][int(r.integers(0, 4))]
        ga = tuple(grijs_aan[i]) if i < len(grijs_aan) else ()
        alle |= gevel(k, x, bw, top, grond, mat, seed * 31 + i, laag=laag, vorm=vorm, lit_p=lit_p, grijs_aan=ga)
        x += bw + 1
        i += 1
    # luchtperspectief: de rij is een tint donkerder naar onder (bible §4.1.4)
    k.add(alle & (k.YY > grond - 20) & (k.BAY < (k.YY - (grond - 20)) / 20), laag, -1)
    return alle


# ------------------------------------------------------------------ S1 Kade-ingang
def bouw_s1():
    k = Kamer("s1_kade_ingang", S1["x"], S1["w"])
    YY, XX = k.YY, k.XX
    lucht_en_ver(k, 101, belfort=(232, 34), gemaal=(486, 616, 96), top_range=(128, 168))
    # huizen aan de straat (op 230), links van het verre gemaal; het gemaal blijft de donkerste vorm
    huizenrij(k, 24, 468, S1_UP, 7, 92, 128, grijs_aan=[(), (), (), ()], lit_p=0.7)
    # --- werf (midden): de wand onder de straat met werfkelders, 236 .. 320
    werf = k.rect(S1_WALL, S1_UP, S1_QUAY_LEFT, S1_FLOOR)
    k.tegels(lambda i, j, x, y: ("baksteen_donker_m1" if (i + j) % 2 else "baksteen_donker_m2"),
             S1_WALL, S1_UP, S1_QUAY_LEFT, S1_FLOOR, "midden")
    k.add(werf & (YY >= 304), "midden", -1)
    # hardstenen speklaag en plint
    k.tegels(lambda i, j, x, y: "kade_wand_laag_m1" if i % 2 else "kade_wand_laag_m2", S1_WALL, 304, S1_QUAY_LEFT, 320, "midden")
    k.paint(k.rect(S1_WALL, 262, S1_QUAY_LEFT, 266), "midden", "steen", 3)
    k.paint(k.rect(S1_WALL, 262, S1_QUAY_LEFT, 263), "midden", "steen", 5)
    # werfkelders: rondbogen met deuren, één open (donker), één met kisten
    for ci, cx in enumerate([150, 262, 374]):
        boog = R_arch(k, cx - 18, cx + 18, 270, 320)
        rand = ndimage.binary_dilation(boog, iterations=3) & ~boog & (YY < 320)
        k.paint(rand, "midden", "steen", 4)
        k.paint(rand & (YY < 286) & (((np.arctan2(YY - 288, XX - cx) * 5) % 1) < 0.18), "midden", "steen", 2)
        k.paint(ndimage.binary_dilation(boog) & ~boog & (YY < 320), "midden", "steen", 2)
        if ci == 1:
            k.paint(boog, "midden", "raamdonker", 1)
            k.paint(boog & (YY > 306), "midden", "raamdonker", 0)
            for (bx, bw_, bh_) in [(cx - 14, 14, 12), (cx + 1, 12, 9), (cx - 9, 10, 8)]:
                y1 = 320 if bx != cx - 9 else 308
                k.paint(k.rect(bx, y1 - bh_, bx + bw_, y1), "midden", "hout", 2)
                k.paint(k.rect(bx, y1 - bh_, bx + bw_, y1 - bh_ + 1), "midden", "hout", 3)
        else:
            k.paint(boog, "midden", "hout", 2)
            k.paint(boog & ((XX - cx) % 6 == 0), "midden", "hout", 1)
            k.paint(boog & ((YY == 290) | (YY == 308)), "midden", "roest", 2)
            k.paint(boog & (np.abs(XX - cx) < 1), "midden", "hout", 1)
            k.ramen.append(dict(x=cx - 5, y=280, w=10, h=6, laag="midden", jit=0.4, kruis=True,
                                aan=dict(grijs=False, half=True, kleur=ci == 0)))
    # proloogdeur (x 460..480, 280..320): smalle deur met ijzerbeslag, het begin van het spel
    k.paint(k.rect(457, 276, 483, 320), "midden", "steen", 4)
    k.paint(k.rect(457, 276, 483, 277), "midden", "steen", 6)
    k.paint(k.rect(460, 280, 480, 320), "midden", "hout", 3)
    k.paint(k.rect(460, 280, 480, 320) & ((XX - 460) % 5 == 4), "midden", "hout", 2)
    k.paint(k.rect(460, 288, 480, 290) | k.rect(460, 308, 480, 310), "midden", "roest", 3)
    k.paint(k.rect(476, 298, 478, 301), "midden", "ijzer", 6)
    # schaduw onder de straatrand / galerij
    k.add(werf & (YY < 246) & (k.BAY < (246 - YY) / 12), "midden", -1)
    # ijzeren consoles onder de straat (niet D-afhankelijk: ze hangen aan de werfwand)
    for cx in range(84, 500, 64):
        k.paint(k.rect(cx, 236, cx + 2, 252), "midden", "ijzer", 3)
        k.paint((np.abs((XX - cx) - (YY - 236)) < 0.8) & (YY >= 236) & (YY < 250) & (XX > cx), "midden", "ijzer", 2)
    # touwen en een meerpaal op de werf
    k.stamp(tegel("paal"), 520 - 30, 290, "midden")
    k.paint((np.abs(YY - (300 + 0.004 * (XX - 430) ** 2 - 6)) < 0.6) & (XX > 404) & (XX < 452), "midden", "hout", 4)
    # haringtonnen bij de deur
    k.stamp(ton(1), 426, 304, "midden")
    k.stamp(ton(2), 412, 306, "midden", dt=-1)
    # --- straatniveau boven de kademuur (midden): bolder en straatlamp; aan de rand van de werf een leuning
    k.stamp(bolder_klein(), 532, 214, "midden")
    su, sa = straatlamp()
    k.wissel.append(("midden", 612, 230 - 48, su, sa, dict(grijs=False, half=True, kleur=True)))
    k.lampen.append(dict(x=620, y=190, r=1.0, aan=dict(grijs=False, half=True, kleur=True)))
    # --- wandlantaarn boven het checkpoint: de lichtpoel in grijs (kleurscript S1)
    wu, wa = wandlamp()
    k.wissel.append(("midden", 384, 248, wu, wa, dict(grijs=True, half=True, kleur=True)))
    k.lampen.append(dict(x=392, y=262, r=1.05, aan=dict(grijs=True, half=True, kleur=True), links_van=S1_WALL))
    # een tweede lantaarn bij de keerwand: alleen aan na het oppompen (de werf leeft)
    k.wissel.append(("midden", 200, 248, wu, wa, dict(grijs=False, half=True, kleur=True)))
    k.lampen.append(dict(x=208, y=262, r=0.95, aan=dict(grijs=False, half=True, kleur=True), links_van=S1_WALL))
    # --- speelvlak: linkerwand (grachtmuur), gang (werfvloer), kademuur
    k.tegels(lambda i, j, x, y: ("kade_wand_hoog_m1" if (j % 2) else "kade_wand_hoog_m2"), 0, 0, S1_WALL, ROOM_H, "speelvlak")
    wand = k.rect(0, 0, S1_WALL, ROOM_H)
    k.add(wand & (XX >= S1_WALL - 2), "speelvlak", 1)
    k.paint(wand & (XX == S1_WALL - 1), "speelvlak", "steen", 5)
    k.add(wand & (YY > 300), "speelvlak", -1)
    for yy0 in range(40, 220, 36):                 # klimijzers in de grachtmuur
        k.paint(k.rect(S1_WALL - 6, yy0, S1_WALL - 1, yy0 + 2), "speelvlak", "ijzer", 4)
        k.paint(k.rect(S1_WALL - 6, yy0, S1_WALL - 5, yy0 + 4), "speelvlak", "ijzer", 3)
    k.paint(wand & (YY >= 336) & (k.BAY < 0.5), "speelvlak", "klimop", 1)
    k.tegels(lambda i, j, x, y: ("kade_boven_m1" if i % 2 else "kade_boven_m2") if j == 0 else
             ("kelderbodem_m1" if i % 2 else "kelderbodem_m2"), S1_WALL, S1_FLOOR, S1_GANG_END, ROOM_H, "speelvlak")
    k.tegels(lambda i, j, x, y: ("kade_boven_l" if i == 0 else ("kade_boven_m1" if i % 2 else "kade_boven_m2")) if j == 0 else
             ("kade_meerring" if (i, j) == (2, 3) else ("rooster" if (i, j) == (6, 5) else
              ("kade_wand_hoog_m1" if j < 4 else "kade_wand_laag_m2"))),
             S1_QUAY_LEFT, S1_UP, 640, ROOM_H, "speelvlak")
    k.tegels(lambda i, j, x, y: "baksteen_donker_m1" if (i + j) % 2 else "baksteen_donker_m2", S1_WALL, 344, S1_GANG_END, ROOM_H, "speelvlak")
    k.add(k.rect(S1_WALL, 344, S1_GANG_END, ROOM_H), "speelvlak", -1)
    # kopse kant van de gang aan de schacht (x 459): hardsteen, een tint lichter
    kop = k.rect(S1_GANG_END - 2, S1_FLOOR + 6, S1_GANG_END, ROOM_H)
    k.paint(kop, "speelvlak", "steen", 3)
    k.paint(kop & (XX == S1_GANG_END - 1), "speelvlak", "steen", 1)
    # de schacht onder het snelluik (midden: geen collision), naar S9
    schacht = k.rect(S1_GANG_END, S1_FLOOR, S1_QUAY_LEFT, ROOM_H)
    k.tegels(lambda i, j, x, y: "baksteen_donker_m1" if (i + j) % 2 else "baksteen_donker_m2",
             S1_GANG_END, S1_FLOOR, S1_QUAY_LEFT, ROOM_H, "midden", dt=-1)
    k.add(schacht & (YY > 334), "midden", -1)
    k.paint(schacht & (XX >= S1_QUAY_LEFT - 3), "midden", "raamdonker", 1)
    for ly in range(330, ROOM_H, 8):                # klimijzers in de schacht
        k.paint(k.rect(474, ly, 486, ly + 1), "midden", "ijzer", 3)
    k.paint(k.rect(473, 326, 474, ROOM_H) | k.rect(486, 326, 487, ROOM_H), "midden", "ijzer", 2)
    km = k.rect(S1_QUAY_LEFT, S1_UP, 640, ROOM_H)
    k.paint(km & (XX == S1_QUAY_LEFT), "speelvlak", "steen", 2)
    k.paint(km & (XX == S1_QUAY_LEFT + 1) & (YY > S1_UP + 6), "speelvlak", "steen", 4)
    # getijdenrand: de oude waterstand op de kademuur (bible §4.5), ook als er geen water is
    k.tegels(lambda i, j, x, y: "kade_getij_m1" if i % 2 else "kade_getij_m2", S1_QUAY_LEFT + 2, 302, 640, 318, "speelvlak")
    # --- voorgrond: niets boven het speelveld; alleen een donkere meerpaal-kop onderaan rechts
    paalkop = k.rect(600, 344, 610, 360) | (np.hypot(XX - 605, YY - 344) < 5.5)
    k.paint(paalkop, "voor", "hout", 1)
    k.paint(paalkop & (XX < 603), "voor", "hout", 0)
    return k


def R_arch(k, x0, x1, ytop, ybot):
    r = (x1 - x0) / 2
    m = k.rect(x0, ytop + r, x1, ybot)
    m |= (np.hypot(k.XX - (x0 + r - 0.5), k.YY - (ytop + r)) < r)
    return m


# ------------------------------------------------------------------ S3 Vismarkt
def bouw_s3():
    k = Kamer("s3_vismarkt", S3["x"], S3["w"])
    YY, XX = k.YY, k.XX
    ox = S3["x"]
    lucht_en_ver(k, 303, belfort=(612, 8), top_range=(104, 150))
    # kerk achter de markt (ver, groot): schip met steunberen, rechts van het belfort
    kerk = k.rect(660, 96, 900, 360) | k.rect(680, 70, 880, 96)
    k.paint(kerk, "ver", "ver", 2)
    for bx in range(668, 900, 40):
        boog = R_arch(k, bx + 8, bx + 22, 110, 150)
        k.paint(boog, "ver", "raamdonker", 2)
        k.ramen.append(dict(x=bx + 10, y=118, w=10, h=30, laag="ver", jit=0.6, kruis=True,
                            aan=dict(grijs=False, half=True, kleur=True)))
        k.paint(k.rect(bx, 96, bx + 4, 360), "ver", "ver", 3)
    # huizen rond de markt (grond 260)
    huizenrij(k, 80, 380, S3_FLOOR, 13, 96, 132, grijs_aan=[], lit_p=0.7)
    huizenrij(k, 560, 960, S3_FLOOR, 17, 90, 140, grijs_aan=[], lit_p=0.7)
    # --- vishal (midden): zuilengang met pannendak tussen de kramen, achter de arena
    hal = k.rect(380, 150, 560, 260)
    k.paint(k.rect(372, 140, 568, 152), "huizen", "dak", 3)
    k.paint(k.rect(372, 140, 568, 141), "huizen", "dak", 5)
    k.paint(k.rect(372, 140, 568, 152) & ((XX % 4) == 0), "huizen", "dak", 2)
    k.paint(k.rect(380, 152, 560, 260), "huizen", "raamdonker", 2)
    k.paint(k.rect(380, 152, 560, 160), "huizen", "raamdonker", 1)
    k.paint(k.rect(380, 152, 560, 156), "huizen", "steen", 3)
    for ci, cx in enumerate(range(388, 560, 34)):
        zuil = k.rect(cx, 156, cx + 8, 260)
        k.paint(zuil, "huizen", "steen", 4)
        k.paint(zuil & (XX == cx), "huizen", "steen", 2)
        k.paint(zuil & (XX == cx + 6), "huizen", "steen", 6)
        k.paint(k.rect(cx - 2, 156, cx + 10, 160), "huizen", "steen", 5)
        k.paint(k.rect(cx - 2, 252, cx + 10, 260), "huizen", "steen", 3)
        if cx + 34 < 560:
            boog = (np.hypot(XX - (cx + 21), YY - 172) < 13) & (YY < 172) & (XX > cx + 8) & (XX < cx + 34)
            k.paint(k.rect(cx + 8, 156, cx + 34, 172) & ~boog, "huizen", "steen", 3)
            # visbank: stenen tafel onder elke boog
            k.paint(k.rect(cx + 11, 236, cx + 31, 240), "huizen", "steen", 5)
            k.paint(k.rect(cx + 13, 240, cx + 15, 252), "huizen", "steen", 3)
            k.paint(k.rect(cx + 27, 240, cx + 29, 252), "huizen", "steen", 3)
            if ci % 2 == 0:
                k.stamp(ton(ci), cx + 14, 244, "huizen", dt=-1)
    # opschrift-bord boven de vishal (zonder tekst: een uithangbord met een vis)
    bord = k.rect(452, 122, 488, 138)
    k.paint(bord, "huizen", "hout", 3)
    k.paint(bord & ~ndimage.binary_erosion(bord), "huizen", "hout", 1)
    vis = (np.hypot((XX - 468) / 9, (YY - 130) / 3.2) < 1) | ((np.abs(YY - 130) <= (XX - 476) * 0.9) & (XX >= 476) & (XX < 482))
    k.paint(vis, "huizen", "koper", 4)
    k.paint(vis & (YY < 130), "huizen", "koper", 5)
    k.paint(k.rect(468, 114, 469, 122) | k.rect(470, 114, 471, 122), "huizen", "ijzer", 3)
    # --- bovenroute (speelvlak): de Waag, bakstenen toren x 0..80, vanaf 70
    tor = k.rect(0, S2_TOP, S3_ENTRY_RIGHT - ox, ROOM_H)
    k.tegels(lambda i, j, x, y: ("baksteen_dek" if j == 0 else ("baksteen_speklaag" if j in (5, 11) else
             ("baksteen_m1" if (i + j) % 2 else "baksteen_m2"))), 0, S2_TOP, 80, ROOM_H, "speelvlak")
    k.paint(k.rect(0, S2_TOP, 80, S2_TOP + 1), "speelvlak", "steen", 6)
    k.paint(tor & (XX >= 78), "speelvlak", "baksteen", 4)
    k.paint(tor & (XX == 79), "speelvlak", "steen", 5)
    k.add(tor & (YY > 230), "speelvlak", -1)
    for wy in (112, 176):                                          # vensters met luiken (dicht)
        k.paint(k.rect(40, wy - 2, 58, wy + 22), "speelvlak", "steen", 5)
        k.paint(k.rect(42, wy, 56, wy + 20), "speelvlak", "hout", 2)
        k.paint(k.rect(42, wy, 56, wy + 20) & ((XX - 42) % 7 == 6), "speelvlak", "hout", 1)
        k.paint(k.rect(42, wy + 9, 56, wy + 10), "speelvlak", "roest", 3)
    k.paint(k.rect(10, 100, 30, 101) | k.rect(19, 96, 21, 106), "speelvlak", "ijzer", 3)   # muuranker
    # hijsbalk boven de markt (decor, midden, steekt uit de toren)
    k.paint(k.rect(80, 82, 104, 86), "midden", "hout", 3)
    k.paint(k.rect(80, 82, 104, 83), "midden", "hout", 5)
    k.paint(k.rect(100, 86, 101, 120), "midden", "hout", 4)       # touw
    k.paint(k.rect(97, 120, 104, 126), "midden", "hout", 2)        # takelblok
    k.paint(k.rect(80, 86, 82, 98), "midden", "ijzer", 2)
    # klimop tegen de toren
    kl = (XX < 80) & (YY > 200) & (YY < 260) & (np.abs(XX - 60 - 6 * np.sin(YY / 9)) < 7 + (YY - 200) / 10) & (k.BAY < 0.55)
    k.paint(kl & tor, "speelvlak", "klimop", 2)
    k.paint(kl & tor & (k.BAY < 0.2), "speelvlak", "klimop", 4)
    # wandlamp aan de toren (aan in kleur)
    wu, wa = wandlamp()
    k.wissel.append(("midden", 80, 200, wu, wa, dict(grijs=False, half=True, kleur=True)))
    k.lampen.append(dict(x=88, y=214, r=0.9, aan=dict(grijs=False, half=True, kleur=True), links_van=80))
    # --- markt (speelvlak): kasseien op 260, daaronder hardsteen en de kelder van de markt
    kas = [kasseien(s) for s in (1, 2, 3)]
    k.tegels(lambda i, j, x, y: kas[i % 3] if j == 0 else ("kade_wand_hoog_m1" if j == 1 else
             ("kelderbodem_m1" if (i + j) % 2 else "kelderbodem_m2")), 80, S3_FLOOR, 960, ROOM_H, "speelvlak")
    k.tegels(lambda i, j, x, y: "baksteen_donker_m1" if (i + j) % 2 else "baksteen_donker_m2", 80, 292, 960, ROOM_H, "speelvlak")
    mk = k.rect(80, S3_FLOOR, 960, ROOM_H)
    k.add(mk & (YY >= 292), "speelvlak", -1)
    # twee duikers onder de markt: hier loopt het water onder de wijk door (beeld, geen speellaag)
    for dx in (330, 740):
        boog = R_arch(k, dx - 22, dx + 22, 306, ROOM_H)
        k.paint(ndimage.binary_dilation(boog, iterations=3) & ~boog & mk & (YY > 296), "speelvlak", "steen", 3)
        k.paint(ndimage.binary_dilation(boog) & ~boog & mk & (YY > 296), "speelvlak", "steen", 1)
        k.paint(boog, "speelvlak", "raamdonker", 0)
        water = boog & (YY >= 344)
        k.paint(water, "speelvlak", "water", 2)
        k.paint(water & (YY == 344), "speelvlak", "water", 4)
        k.paint(water & (YY == 344) & ((XX // 3) % 3 == 0), "speelvlak", "water", 6)
        k.paint(boog & (YY >= 336) & (YY < 344) & (XX < dx - 14), "speelvlak", "klimop", 1)
    k.paint(mk & (YY == 276), "speelvlak", "steen", 2)
    for gx in range(140, 960, 160):                                # roosters van de afwatering
        k.stamp(tegel("rooster"), gx, 276, "speelvlak", dt=-1)
    # --- kramen: luifel = eenrichting op 190 (vast in S3), frame eronder als decor
    for n, (wx, wy, ww) in enumerate(S3_PLATFORMS):
        lx = wx - ox
        k.stamp(kraam_onder(ww, seed=n + 4), lx, wy + 6, "midden")
        k.stamp(kraam_luifel(ww), lx, wy, "speelvlak")
    # één kraamlamp (de enige warme lamp in grijs, kleurscript S3)
    ku, ka = kraamlamp()
    k.wissel.append(("midden", 220 + 70, 200, ku, ka, dict(grijs=True, half=True, kleur=True)))
    k.paint(k.rect(293, 196, 295, 200), "midden", "ijzer", 3)
    k.lampen.append(dict(x=294, y=210, r=0.85, aan=dict(grijs=True, half=True, kleur=True), boven_y=197))
    # straatlampen op de markt (aan in kleur)
    su, sa = straatlamp()
    for lx in (470, 860):
        k.wissel.append(("midden", lx - 8, 260 - 48, su, sa, dict(grijs=False, half=True, kleur=True)))
        k.lampen.append(dict(x=lx, y=220, r=1.0, aan=dict(grijs=False, half=True, kleur=True)))
    # --- voorgrond: vlaggenlijn hoog over de markt (boven de bovenroute-hoogte, nooit in het speelveld)
    for (xa, xb, ya) in [(96, 400, 18), (560, 950, 12)]:
        n = (xb - xa) // 14
        for i in range(n + 1):
            x = xa + i * 14
            s = (x - xa) / (xb - xa)
            y = int(ya + 22 * 4 * s * (1 - s))
            if i < n:
                xm = x + 7
                sm = (xm - xa) / (xb - xa)
                ym = int(ya + 22 * 4 * sm * (1 - sm))
                k.paint((np.abs(YY - (y + (ym - y) * (XX - x) / 7)) < 0.6) & (XX >= x) & (XX < x + 14), "voor", "ijzer", 2)
                vl = (YY >= ym + 1) & (YY < ym + 8) & (np.abs(XX - xm) <= (ym + 8 - YY) * 0.5)
                mt = ["huis_oker", "huis_groen", "huis_wit", "huis_groen"][i % 4]
                k.paint(vl, "voor", mt, 4)
                k.paint(vl & (XX < xm), "voor", mt, 3)
    return k


# ------------------------------------------------------------------ figuren (alleen in de renders)
def figuren_s1(staat):
    echo_kleur = staat == "kleur"

    def f(img):
        # B1: P1 is net op de echo gebounced (boven de galerij), de echo loopt tegen de grachtwand
        return plak_fig(img, [("echo", SP.P1_RUN[1], 66, 320, True, echo_kleur),
                              ("p1", SP.P1_JUMP, 132, 214, False, True)], 0)
    return f


def figuren_s3(staat, ox=0):
    echo_kleur = staat == "kleur"
    donker = staat != "kleur"

    def f(img):
        img = plak_fig(img, [("echo", SP.P1_RUN[2], 1990 - 1600 - 36, 260, False, echo_kleur),
                             ("p1", SP.P1_RUN[0], 1990 - 1600 + 40, 260, False, True)], 0)
        for i, (wx, pose, flip) in enumerate([(2140, "aanloop", True), (2168, "idle", True), (2360, "idle", True)]):
            body, kern, ogen, extra = D1.kadeloper(pose)
            lay = D1.vijand_render(body, kern, ogen, extra, staat="kleur", donker=donker)
            if flip:
                lay = lay[:, ::-1]
            x = wx - 1600 - lay.shape[1] // 2
            y = 260 - lay.shape[0]
            if i == 1:
                D1.merk_rand(img, lay, x, y, "amber")
            D1.stamp_rgba(img, lay, x, y)
            if i == 1:
                D1.bereikcirkel(img, wx - 1600, 260 - 14, "amber")
        return img
    return f


def plak_fig(img, figs, ox):
    """Figuren uit de R5-code (640x400-canvas) op een kamer van willekeurige breedte zetten."""
    h, w = img.shape[:2]
    for kind, rows, x, y, flip, kleur in figs:
        vx = max(0, min(w - 640, x - 320))
        st = "kleur" if kleur else "grijs"
        lay, _ = R.fig_layer(kind, rows, x - vx, y, st, flip=flip)
        lay = lay[:h]
        sub = img[:, vx:vx + 640]
        img[:, vx:vx + 640] = over(sub, lay)
    return img


# ------------------------------------------------------------------ export en metingen
def save(img, path, scale=1):
    if img.shape[-1] == 4:
        arr = (np.clip(img, 0, 1) * 255 + 0.5).astype(np.uint8)
        im = Image.fromarray(arr, "RGBA")
    else:
        im = Image.fromarray((np.clip(img, 0, 1) * 255 + 0.5).astype(np.uint8), "RGB")
    if scale != 1:
        im = im.resize((im.width * scale, im.height * scale), Image.NEAREST)
    im.save(path, optimize=True)
    return im


def merge(lagen, namen):
    out = np.zeros_like(lagen[namen[0]])
    for n in namen:
        a = lagen[n][..., 3:4]
        out[..., :3] = out[..., :3] * (1 - a) + lagen[n][..., :3] * a
        out[..., 3:4] = np.maximum(out[..., 3:4], a)
    return out


def chroma(img):
    lab = R.srgb_to_lab(img)
    return float(np.mean(np.hypot(lab[..., 1], lab[..., 2])))


def loopvlak_contrast(img, rects):
    """ΔL* tussen de bovenste 2 px van een loopvlak en de 2..6 px erboven (mediaan)."""
    L = R.srgb_to_lab(img)[..., 0]
    out = []
    for (x0, y, w) in rects:
        x0, x1 = max(0, int(x0)), min(img.shape[1], int(x0 + w))
        top = L[y:y + 2, x0:x1]
        boven = L[max(0, y - 6):y - 2, x0:x1]
        out.append(abs(float(np.median(top)) - float(np.median(boven))))
    return out


def label_bar(w, tekst, sub=None, s=1):
    bar = np.zeros((14 if s == 1 else 26, w, 3)) + D1.BG
    D1.label(bar, tekst, 4, 4 if s == 1 else 7, s=s)
    if sub:
        D1.label(bar, sub, 8 + D1.text_width(tekst, s), 4 if s == 1 else 7, (0.6, 0.6, 0.7), s=s)
    return bar


def geometrie_controle(img, kamer, blokken):
    """Lijnen van de collision-rechthoeken (cyaan = vast, geel = eenrichting) over de art (x2)."""
    big = np.repeat(np.repeat(img.copy(), 2, 0), 2, 1)
    for (x, y, w, h, eenr) in blokken:
        col = np.array([1.0, 0.85, 0.2]) if eenr else np.array([0.2, 0.95, 1.0])
        x0, y0, x1, y1 = int(2 * x), int(2 * y), int(2 * (x + w)) - 1, int(2 * (y + h)) - 1
        x0c, x1c = max(0, x0), min(big.shape[1] - 1, x1)
        y0c, y1c = max(0, y0), min(big.shape[0] - 1, y1)
        if x1c < x0c or y1c < y0c:
            continue
        for yy in (y0, y1):
            if 0 <= yy < big.shape[0]:
                big[yy, x0c:x1c + 1][::2] = col
        for xx in (x0, x1):
            if 0 <= xx < big.shape[1]:
                big[y0c:y1c + 1, xx][::2] = col
    return big


def blokken_s1(d=D):
    z = keerzone(d)
    out = [(0, 0, S1_WALL, ROOM_H, False), (S1_WALL, S1_FLOOR, S1_GANG_END - S1_WALL, ROOM_H - S1_FLOOR, False),
           (S1_QUAY_LEFT, S1_UP, 640 - S1_QUAY_LEFT, ROOM_H - S1_UP, False)]
    for (_, _, x, y, w) in s1_eenrichting(d):
        out.append((x, y, w, ONE_WAY_T, True))
    return out


def blokken_s3():
    out = [(0, S2_TOP, 80, ROOM_H - S2_TOP, False), (80, S3_FLOOR, 880, ROOM_H - S3_FLOOR, False)]
    for (x, y, w) in S3_PLATFORMS:
        out.append((x - 1600, y, w, ONE_WAY_T, True))
    return out


def plaats_eenrichting(k, d):
    """De eenrichtingsstukken van S1 voor staart d, zoals de TA ze als NinePatch op Layout.blocks() zet."""
    lay_mat = np.full((k.h, k.w), -1, np.int16)
    lay_t = np.zeros((k.h, k.w), np.int16)
    for (_, soort, x, y, w) in s1_eenrichting(d):
        stuk = ninepatch(EENRICHTING[soort], int(w))
        hh, ww = stuk.mat.shape
        ok = stuk.mat >= 0
        lay_mat[y:y + hh, x:x + ww][ok] = stuk.mat[ok]
        lay_t[y:y + hh, x:x + ww][ok] = stuk.t[ok]
    return lay_mat, lay_t


def render_met_eenrichting(k, staat=None, golf=None, d=D):
    """Render met de eenrichtingsstukken in de speelvlak-laag (alleen voor de renders en de controle)."""
    m, t = plaats_eenrichting(k, d)
    L = LI["speelvlak"]
    bm, bt = k.mat[L].copy(), k.t[L].copy()
    ok = m >= 0
    k.mat[L][ok] = m[ok]
    k.t[L][ok] = t[ok]
    try:
        return k.render(staat or "grijs", golf)
    finally:
        k.mat[L], k.t[L] = bm, bt


def export_kamer(k, manifest, extra_lagen=None):
    files = {}
    for staat in STATEN:
        lagen = k.render(staat)
        for naam, delen in EXPORT.items():
            img = merge(lagen, delen)
            if naam == "voor" and img[..., 3].max() == 0:
                continue
            fn = f"{k.naam}_{naam}_{staat}.png"
            save(img, os.path.join(UIT_GAME, fn))
            files.setdefault(naam, {})[staat] = fn
        fn = f"{k.naam}_licht_{staat}.png"
        save(lagen["licht"], os.path.join(UIT_GAME, fn))
        files.setdefault("licht", {})[staat] = fn
    for naam, delen in EXPORT.items():
        if naam not in files:
            continue
        fn = f"{k.naam}_{naam}_index.png"
        Image.fromarray(k.index_laag(delen), "RGBA").save(os.path.join(UIT_GAME, fn), optimize=True)
        files[naam]["index"] = fn
    manifest["kamers"][k.naam] = dict(
        wereld_rect=[k.wx, 0, k.w, k.h],
        lagen=[dict(naam=n, z_index=z, bestanden=files[n]) for n, z in
               [("achter", -30), ("midden", -20), ("speelvlak", -10), ("licht", -5), ("voor", 20)] if n in files],
        lampen=[dict(x=lp["x"] + k.wx, y=lp["y"], straal_band1=int(80 * lp["r"]),
                     aan_in=[s for s in STATEN if lp["aan"][s]]) for lp in k.lampen],
        ramen=len(k.ramen),
    )


def eenrichting_export(manifest):
    w, h = 48, 16 * len(EENR_VOLGORDE)
    for staat in STATEN:
        img = np.zeros((h, w, 4))
        for i, soort in enumerate(EENR_VOLGORDE):
            img[i * 16:(i + 1) * 16] = EENRICHTING[soort].render(staat)
        save(img, os.path.join(UIT_GAME, f"kadewijk_eenrichting_{staat}.png"))
    items = [(0, 16 * i, EENRICHTING[s_]) for i, s_ in enumerate(EENR_VOLGORDE)]
    D1.index_atlas(items, w, h).save(os.path.join(UIT_GAME, "kadewijk_eenrichting_index.png"))
    manifest["eenrichting"] = dict(
        atlas={s: f"kadewijk_eenrichting_{s}.png" for s in STATEN + ["index"]},
        stukken={"galerij": dict(region=[0, 0, 48, 16], marge_links=16, marge_rechts=16, herhaal="tile"),
                 "trede": dict(region=[0, 16, 48, 16], marge_links=16, marge_rechts=16, herhaal="tile"),
                 "snelluik": dict(region=[0, 32, 48, 16], marge_links=16, marge_rechts=16, herhaal="tile")},
        blokken={"S1/Galerij": "galerij", "S1/B1Trede30": "trede", "S1/B1Trede60": "trede", "S1/B1Trede90": "trede",
                 "S1/Snelluik": "snelluik"},
        plaatsing="NinePatchRect op Rect2(blok.position, Vector2(blok.size.x, 16)); loopvlak = bovenrand van het blok",
    )


def main():
    print("Slice-art deel 2: eindkwaliteit S1 en S3 (D = 60)")
    manifest = dict(versie="0.2", eigenaar="Art Director", issue=85, d_render=D,
                    gemaal_werkaanname=list(GEMAAL_WERELD), kamers={})
    s1, s3 = bouw_s1(), bouw_s3()
    export_kamer(s1, manifest)
    export_kamer(s3, manifest)
    eenrichting_export(manifest)
    manifest["import"] = dict(
        map="res://art/wereld/kadewijk/",
        texture="Lossless, mipmaps uit, filter Nearest op het CanvasItem (texture_filter = NEAREST), repeat uit",
        positie="Sprite2D, centered = false, global_position = wereld_rect.position (linksboven van de kamer)",
        toestanden="grijs / half / kleur; index = R materiaal-id, G tint*32+16, B 255 = raam, A 255",
    )
    with open(os.path.join(UIT_GAME, "kadewijk_kamers.json"), "w") as f:
        json.dump(manifest, f, indent=1, ensure_ascii=False)

    metingen = {}
    renders = {}
    for k, figs, blok in [(s1, figuren_s1, blokken_s1()), (s3, figuren_s3, blokken_s3())]:
        for staat in ["grijs", "kleur"]:
            lagen = render_met_eenrichting(k, staat) if k is s1 else k.render(staat)
            zonder = k.samengesteld(lagen)
            met = k.samengesteld(lagen, figs(staat))
            renders[(k.naam, staat)] = (zonder, met)
            save(met, os.path.join(UIT_DOCS, f"{k.naam}_{staat}_{k.w}x{k.h}.png"))
            vlakken = [(x, y, w) for (x, y, w, h, e) in blok if y > 0]
            metingen[(k.naam, staat)] = dict(chroma=chroma(zonder), loopvlak=loopvlak_contrast(zonder, vlakken))
        g, kl = renders[(k.naam, "grijs")][1], renders[(k.naam, "kleur")][1]
        vb = np.concatenate([label_bar(k.w, "GRIJS", "S = 0, VOOR HET OPPOMPEN"), g,
                             label_bar(k.w, "KLEUR", "S = 2, NA TRAP 2 (ZELFDE PLEK)"), kl], 0)
        save(vb, os.path.join(UIT_DOCS, f"{k.naam}_vergelijking_x2.png"), 2)
        ctrl = geometrie_controle(renders[(k.naam, "grijs")][0], k, blok)
        save(ctrl, os.path.join(UIT_DOCS, f"{k.naam}_geometrie_controle_x2.png"))

    # S3 in camera-uitsnede (640 breed, zoals in het spel) en leesbaarheid
    for staat in ["grijs", "kleur"]:
        met = renders[("s3_vismarkt", staat)][1]
        save(met[:, 300:940], os.path.join(UIT_DOCS, f"s3_vismarkt_{staat}_camera_640x360.png"))
    met = renders[("s3_vismarkt", "grijs")][1][:, 300:940]
    lum = R.grayscale(met)
    deu = R.deuteranopia(met)
    save(np.concatenate([label_bar(640, "LUMINANTIE", "GRIJS"), lum, label_bar(640, "DEUTERANOPIE", "GRIJS"), deu], 0),
         os.path.join(UIT_DOCS, "s3_vismarkt_leesbaarheid_x2.png"), 2)

    # S1 met een andere D: de art volgt de layout (controle voor de TA)
    lagen = render_met_eenrichting(s1, "grijs", d=120)
    ctrl = geometrie_controle(s1.samengesteld(lagen), s1, blokken_s1(120))
    save(ctrl, os.path.join(UIT_DOCS, "s1_kade_ingang_geometrie_controle_d120_x2.png"))

    # lichtovergang: de kleurgolf vanaf het gemaal (werkaanname) door S1 en S3
    v, lag = 300.0, 0.4
    for k in (s1, s3):
        gx = GEMAAL_WERELD[0] - k.wx
        d_ver = float(np.hypot(gx, GEMAAL_WERELD[1]))           # verste hoek linksboven
        d_dicht = float(np.hypot(gx - k.w, 0))
        t0, t1 = d_dicht / v - 0.1, d_ver / v + lag + 0.15
        tijden = np.linspace(t0, t1, 5)
        strip = []
        frames = []
        for tt in np.arange(t0 - 0.3, t1 + 0.4, 0.1):
            golf = (v * tt, v * (tt - lag))
            lagen = render_met_eenrichting(k, golf=golf) if k is s1 else k.render("grijs", golf)
            img = k.samengesteld(lagen, (figuren_s1 if k is s1 else figuren_s3)("grijs"))
            frames.append(img)
        for tt in tijden:
            golf = (v * tt, v * (tt - lag))
            lagen = render_met_eenrichting(k, golf=golf) if k is s1 else k.render("grijs", golf)
            img = k.samengesteld(lagen)
            if k is s3:
                img = img[:, 160:800]
            strip.append(label_bar(img.shape[1], f"T = {tt - t0:.1f} S", "HALF-VOORKANT %d PX VAN HET GEMAAL" % int(v * tt)))
            strip.append(img)
        save(np.concatenate(strip, 0), os.path.join(UIT_DOCS, f"{k.naam}_lichtovergang_strip.png"))
        if k is s1:
            ims = [Image.fromarray((np.clip(f_, 0, 1) * 255 + 0.5).astype(np.uint8)) for f_ in frames]
            ims = [im.resize((im.width * 2, im.height * 2), Image.NEAREST) for im in ims]
            ims = [ims[0]] * 6 + ims + [ims[-1]] * 8
            ims[0].save(os.path.join(UIT_DOCS, f"{k.naam}_lichtovergang_x2.gif"), save_all=True, append_images=ims[1:],
                        duration=100, loop=0, optimize=True)

    # eenrichtingsstukken x4 (overzicht)
    ov = []
    for staat in STATEN:
        a = np.zeros((16 * len(EENR_VOLGORDE), 48, 3)) + D1.BG
        for i, soort in enumerate(EENR_VOLGORDE):
            r_ = EENRICHTING[soort].render(staat)
            a[i * 16:(i + 1) * 16] = over(a[i * 16:(i + 1) * 16], r_)
        ov.append(a)
        ov.append(np.zeros((16 * len(EENR_VOLGORDE), 4, 3)) + D1.BG)
    save(np.concatenate(ov, 1), os.path.join(UIT_DOCS, "kadewijk_eenrichting_x4.png"), 4)

    print("  metingen (gemiddelde chroma CIELAB, ΔL* loopvlak tegen de 2..6 px erboven):")
    for (naam, staat), m in metingen.items():
        print(f"    {naam:16s} {staat:6s} chroma {m['chroma']:5.1f}   loopvlak ΔL* " +
              " ".join(f"{v_:4.1f}" for v_ in m["loopvlak"]))
    # leesbaarheid figuren: P1 en echo tegen de achtergrond (ring 2..6 px), zoals deel 1
    for k, figs in [(s1, figuren_s1), (s3, figuren_s3)]:
        for staat in ["grijs", "kleur"]:
            zonder, met = renders[(k.naam, staat)]
            diff = np.abs(met - zonder).sum(-1) > 0.02
            lab, n = ndimage.label(ndimage.binary_dilation(diff, iterations=1))
            for i in range(1, n + 1):
                m_ = lab == i
                if m_.sum() < 60:
                    continue
                ys, xs = np.nonzero(m_)
                Lz = R.srgb_to_lab(met)[..., 0]
                ring = ndimage.binary_dilation(m_, iterations=6) & ~ndimage.binary_dilation(m_, iterations=2)
                inner = m_ & diff
                d_ = abs(float(np.percentile(Lz[inner], 90)) - float(np.median(Lz[ring])))
                print(f"    figuur {k.naam} {staat} x {xs.min()}-{xs.max()}: ΔL* contour(p90) {d_:4.1f}")
    bovenrand_meting(s3)
    return manifest, metingen


def bovenrand_meting(k):
    """Bible-regel uit deel 1 (§4.2): de bovenrand van een vijand leest met ΔL* ≥ 50 tegen de ring van 2..6 px."""
    for staat in ["grijs", "kleur"]:
        img = k.samengesteld(k.render(staat))
        L = R.srgb_to_lab(img)[..., 0]
        for wx, pose in [(2140, "aanloop"), (2168, "idle"), (2360, "idle")]:
            body, kern, ogen, extra = D1.kadeloper(pose)
            lay = D1.vijand_render(body, kern, ogen, extra, staat="kleur", donker=staat != "kleur")[:, ::-1]
            x, y = wx - k.wx - lay.shape[1] // 2, S3_FLOOR - lay.shape[0]
            comp = img.copy()
            D1.stamp_rgba(comp, lay, x, y)
            Lc = R.srgb_to_lab(comp)[..., 0]
            m = np.zeros(img.shape[:2], bool)
            m[y:y + lay.shape[0], x:x + lay.shape[1]] = lay[..., 3] > 0
            top = np.zeros_like(m)
            for c in range(m.shape[1]):
                ys = np.nonzero(m[:, c])[0]
                if len(ys):
                    top[ys[0]:ys[0] + 3, c] = True
            ring = ndimage.binary_dilation(m, iterations=6) & ~ndimage.binary_dilation(m, iterations=2) & (k.YY < S3_FLOOR)
            d_ = abs(float(np.percentile(Lc[top], 90)) - float(np.median(L[ring])))
            print(f"    Kadeloper S3 x {wx} {staat}: bovenrand ΔL* {d_:4.1f}")


if __name__ == "__main__":
    main()
