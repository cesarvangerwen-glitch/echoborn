"""Placeholder-mock-ups Polderlight, T10 (#87): Spelbestanden + bevestiging, Logboek, Credits,
herbinden met kolomkeuze, en het slot-kader in zijn staten. Antwoord op hud-menus.md par. 7 punt 16.

Eigen werk van de UI Artist, alleen uit bestaande onderdelen (genereer_ui.py, genereer_menu.py):
geen nieuwe assets in game/, geen nieuwe kleuren. Eind-art volgt later (stijlgids par. 10).
Draait vanaf de repo-root, na genereer_ui.py en genereer_menu.py:

    python3 docs/art/ui/bron/genereer_menu_placeholder.py

Schrijft alleen naar docs/art/ui/ (alle namen met _placeholder) en print de tekstmeting.
Indeling en maten: docs/ux/hud-menus.md par. 4.5, 4.7a, 4.8 en 4.9.
"""
import os
import sys

import numpy as np

HIER = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HIER)
import genereer_ui as U  # noqa: E402
import genereer_menu as M  # noqa: E402
import polderletter as PL  # noqa: E402
from genereer_ui import C, WIT, GLOED, LUCHT, over  # noqa: E402

K = C["K"]
FS = M.FS
GEMAAKT = U.GEMAAKT


# ------------------------------------------------------------------ hulp
def wrap(s, breedte, grootte="normaal"):
    """Woord voor woord afbreken op breedte (zoals autowrap in een Label)."""
    regels, r = [], ""
    for w in s.split(" "):
        t = (r + " " + w).strip()
        if PL.text_width(t, grootte) <= breedte:
            r = t
        else:
            regels.append(r)
            r = w
    regels.append(r)
    return regels


def kader(img, x, y, w, h):
    over(img, M.negen4(U.kader_9slice(), w, h, 2, 2, 2, 2), x, y)


def scherm(naam="r5_grijs_640x360.png"):
    img = U.laad(naam)
    M.dim(img)
    return img


def titel(img, s):
    M.label(img, s, 28, 8, WIT[7], schaal=2)


def stapel(*imgs):
    """Schermen onder elkaar, met een naad van 2 px bijna-zwart."""
    naad = np.zeros((2, imgs[0].shape[1], 3), np.uint8)
    naad[:] = K
    uit = [imgs[0]]
    for i in imgs[1:]:
        uit += [naad, i]
    return np.concatenate(uit, 0)


# ------------------------------------------------------------------ a. slot-kader (par. 4.7a)
SLOT = {"normaal": dict(w=400, h=36, pitch=44, r1=8, r2=20, grootte="normaal"),
        "groot": dict(w=584, h=50, pitch=58, r1=9, r2=27, grootte="groot")}


def slot_kader(img, x, y, n, regel2, staat="normaal", maat="normaal", kleur2=None, rechts=None):
    """Een plaats: kader_9slice (normaal) of keuzebalk + lamp (focus/hover/ingedrukt); 2 regels."""
    s = SLOT[maat]
    w, h, g = s["w"], s["h"], s["grootte"]
    kader(img, x, y, w, h)                                  # variant Uitleg, plaat 78 %
    if staat in ("focus", "hover", "ingedrukt"):
        if staat == "ingedrukt":
            over(img, M.negen4(M.keuzebalk("ingedrukt"), w, h, 3, 3, 3, 3), x, y)
        over(img, M.negen4(M.keuzebalk("focus"), w, h, 3, 3, 3, 3), x, y)
        over(img, M.lamp(), x + 3, y + (h - 9) // 2)
    c1 = WIT[7] if staat != "normaal" else WIT[5]
    if staat == "ingedrukt":
        c1 = GLOED[6]
    M.label(img, "Plaats %d" % n, x + 13, y + s["r1"], c1, g)
    if rechts:
        M.label(img, rechts, x + w - 8 - PL.text_width(rechts, g), y + s["r1"], WIT[5], g)
    M.label(img, regel2, x + 13, y + s["r2"], WIT[5] if kleur2 is None else kleur2, g)


PLAATSEN = [  # (regel 2, kleur, rechts op regel 1)
    ("Wijk 1.1 De Kadewijk · Licht 40 · 1 u 12 min", None, "Hersteld uit back-up"),
    ("Beschadigd: kan niet laden", GLOED[6], None),
    ("Leeg", WIT[3], None),
]


def spelbestanden_lijst(img, maat="normaal", focus=0, melding=True):
    s = SLOT[maat]
    titel(img, "Spelbestanden")
    for i, (r2, kl, re) in enumerate(PLAATSEN):
        slot_kader(img, 28, 40 + s["pitch"] * i, i + 1, r2, "focus" if i == focus else "normaal", maat, kl, re)
    if melding:   # MN-24, 5 s
        g = s["grootte"]
        my, mh = (176, 16) if maat == "normaal" else (216, 20)
        kader(img, 28, my, s["w"], mh)
        M.label(img, "Opslaan mislukt. Deze plaats is nu leeg.", 34, my + (1 if maat == "normaal" else 0), WIT[7], g)


def bevestiging(img, maat="normaal", apparaat="xbox"):
    """MN-23: paneel boven de lijst (lijst nog eens 50 % verduisterd); Terug staat standaard."""
    M.dim(img, 0.50)
    if maat == "normaal":
        px, py, pw, ph, g, tl, bw, by = 120, 116, 400, 128, "normaal", 10, 160, (80, 96)
        ty = 50
    else:
        px, py, pw, ph, g, tl, bw, by = 80, 96, 480, 168, "groot", 14, 200, (100, 120)
        ty = 56
    over(img, M.negen4(M.paneel(), pw, ph, 4, 4, 4, 4), px, py)
    M.label(img, "Plaats 1 overschrijven?", px + 16, py + 12, WIT[7], schaal=2)
    M.label(img, "Wijk 1.1 De Kadewijk · 1 u 12 min", px + 16, py + 38, WIT[5], g)
    body = "Dit spel wordt gewist. Dat kan niet terug." if maat == "normaal" else \
        "Het oude bestand blijft bewaard voor support, maar deze plaats begint opnieuw."
    regels = wrap(body, pw - 32, g)
    for i, r in enumerate(regels[:2]):
        M.label(img, r, px + 16, py + ty + i * tl, WIT[7], g)
    M.menuregel(img, "Terug", px + 16, py + by[0], bw, "focus", g)
    M.menuregel(img, "Overschrijven", px + 16, py + by[1], bw, "normaal", g)
    M.hints(img, [("a", "Kies"), ("b", "Terug")], apparaat, g)
    return regels


def mock_spelbestanden():
    a = scherm()
    spelbestanden_lijst(a, "normaal")
    M.hints(a, [("a", "Laden"), ("x", "Nieuw spel hier"), ("b", "Terug")], "xbox")
    b = scherm()
    spelbestanden_lijst(b, "normaal", melding=False)
    bevestiging(b, "normaal", "xbox")
    return stapel(a, b)


def mock_spelbestanden_groot():
    a = scherm()
    spelbestanden_lijst(a, "groot", focus=1)
    M.hints(a, [("x", "Nieuw spel hier"), ("b", "Terug")], "deck", "groot")   # KAPOT: geen A
    b = scherm()
    spelbestanden_lijst(b, "groot", focus=1, melding=False)
    bevestiging(b, "groot", "deck")
    return stapel(a, b)


def blad_slot_kader():
    """Het slot-kader in de staten normaal, focus, hover (= focus) en ingedrukt; normaal en groot."""
    W, H = 704, 4 * 54 + 4 * 66 + 16
    img = np.zeros((H, W, 3), np.uint8)
    img[:] = LUCHT[2]
    y = 8
    for maat in ("normaal", "groot"):
        s = SLOT[maat]
        for st in ("normaal", "focus", "hover", "ingedrukt"):
            slot_kader(img, 28, y, 1, "Wijk 1.1 De Kadewijk · Licht 40 · 12 min", st, maat)
            M.label(img, st, 28 + s["w"] + 6, y + s["r1"], GLOED[6] if st != "normaal" else WIT[6])
            y += s["h"] + 8 + (4 if maat == "groot" else 2)
        y += 8
    return img


# ------------------------------------------------------------------ b. logboek (par. 4.8)
BLADEN = [None, None, 3, 4, None, 6, None]   # 7 plekken, gevonden: 3, 4, 6 (lijstvolgorde = n)
TEKST4 = ("Logbladzijde 4", "De sluiswachter schreef het peil op de muur,", "elke avond een streep hoger.")


def logboek_kop(img, apparaat, g):
    titel(img, "Logboek")
    f = FS[g]
    groot = g == "groot"
    lb = M.glyph(apparaat, "lb" if apparaat == "xbox" else "l1", groot)
    rb = M.glyph(apparaat, "rb" if apparaat == "xbox" else "r1", groot)
    x, y = 22, 34
    over(img, lb, x, y + (f["rij"] - lb.shape[0]) // 2)
    x += lb.shape[1] + 4
    for i, s in enumerate(("Proloog", "De polderwijk")):
        w = 5 + PL.text_width(s, g) + 5
        if i == 1:
            over(img, M.negen4(M.tab_gekozen(), w, f["rij"], 3, 3, 3, 3), x, y)
        M.label(img, s, x + 5, y + 2, GLOED[6] if i == 1 else WIT[5], g)
        x += w + 4
    over(img, rb, x, y + (f["rij"] - rb.shape[0]) // 2)
    img[y + f["rij"], 16:624] = WIT[3]
    M.label(img, "3 van 7 gevonden", 28, 56, WIT[5], g)


def mock_logboek():
    uit = []
    for g, app in (("normaal", "xbox"), ("groot", "deck")):
        img = scherm("r5_kleur_640x360.png")
        logboek_kop(img, app, g)
        bw, pitch = (160, 16) if g == "normaal" else (200, 20)
        for i, n in enumerate(BLADEN):
            y = 74 + pitch * i
            if n is None:
                M.menuregel(img, "– – –", 28, y, bw, "uit", g)
            else:
                M.menuregel(img, "Logbladzijde %d" % n, 28, y, bw, "focus" if n == 4 else "normaal", g)
        if g == "normaal":       # logkader van de HUD rechts, 360 x 32
            x, y = 232, 74
            kader(img, x, y, 360, 32)
            U.tekst(img, TEKST4[0], x + 6, y + 3, GLOED[6])
            U.tekst(img, TEKST4[1], x + 6, y + 12, WIT[7])
            U.tekst(img, TEKST4[2], x + 6, y + 21, WIT[7])
        else:                    # groot logkader onder de lijst, 540 x 48 op (50, 222)
            x, y = 50, 222
            kader(img, x, y, 540, 48)
            U.tekst(img, TEKST4[0], x + 6, y + 4, GLOED[6], "groot")
            U.tekst(img, TEKST4[1], x + 6, y + 18, WIT[7], "groot")
            U.tekst(img, TEKST4[2], x + 6, y + 32, WIT[7], "groot")
        lb, rb = ("lb", "rb") if app == "xbox" else ("l1", "r1")
        M.hints(img, [(lb, "Gebied"), (rb, "Gebied"), ("b", "Terug")], app, g)
        uit.append(img)
    return stapel(*uit)


# ------------------------------------------------------------------ b. credits (par. 4.9)
MERKEN = ("Xbox is a trademark of the Microsoft group of companies. PlayStation is a registered trademark "
          "or trademark of Sony Interactive Entertainment Inc. Steam and Steam Deck are trademarks and/or "
          "registered trademarks of Valve Corporation. Polderlight is not affiliated with or endorsed by "
          "Microsoft, Sony Interactive Entertainment or Valve.")
CREDITS = [("Polderlight", ["Een spel van de studio"]),
           ("Rol", ["Naam", "Naam"]),
           ("Rol", ["Naam"]),
           ("Rol", ["Naam", "Naam", "Naam"]),
           ("Gemaakt met", ["Godot Engine"]),
           ("Merken", None),          # merkenregel, docs/business/knop-glyphs-check.md par. 3 punt 4
           ("Licenties", ["uit docs/licenties.md"])]


def mock_credits():
    uit = []
    for g, app, start in (("normaal", "xbox", 20), ("groot", "toetsenbord", -150)):
        img = scherm()
        regel, blok = (12, 14) if g == "normaal" else (16, 18)
        y = start
        for kop, namen in CREDITS:
            namen = wrap(MERKEN, 320, g) if namen is None else namen
            for i, s in enumerate([kop] + namen):
                tw = PL.text_width(s, g)
                if -16 < y < 360 - 30:      # ScrollContainer: alleen wat boven de knophints staat
                    M.label(img, s, (640 - tw) // 2, y, GLOED[6] if i == 0 else WIT[7], g)
                y += regel
            y += blok
        if app == "toetsenbord":
            M.hints(img, [(M.glyph("toetsenbord", "pijl_neer", True), "Sneller"), ("Esc", "Terug")], app, g)
        else:
            M.hints(img, [("dpad_verticaal", "Sneller"), ("b", "Terug")], app, g)
        uit.append(img)
    return stapel(*uit)


# ------------------------------------------------------------------ c. herbinden: kolom kiezen (par. 4.5)
# cellen: zie genereer_menu.HERBIND; "ook" = gedimde regel onder Links/Rechts (MN-43, geen cel)
HERBIND = [("Links", [("t", "A")], [("k", "pijl_links")], [("x", "dpad_links")]),
           ("Rechts", [("t", "D")], [("k", "pijl_rechts")], [("x", "dpad_rechts")]),
           "ook",
           ("Springen", [("t", "Spatie")], [("t", "Enter")], [("x", "a")]),
           ("Aanval", [("t", "E")], [("t", "R-Ctrl")], [("x", "x")]),
           ("Interactie (genezen)", [("t", "F")], [("t", "/")], [("x", "y")]),
           ("Echo (loslaten)", [("t", "Q")], [("t", ".")], [("x", "lb")]),
           ("Dash", [("t", "L-Shift")], [("t", "R-Shift")], [("x", "rb")]),
           ("Pauze", [("t", "Esc")], [("t", "Esc")], [("x", "menu")]),
           ("Meedoen (vrij apparaat)", "-", [("t", "Enter")], [("x", "menu")]),
           ("Stoppen (vasthouden)", "-", [("t", "Backspace")], [("x", "view")])]
KX = M.KOLOM_X
CEL_RECHTS = [KX[2] - 4, KX[3] - 4, 604]     # rechterrand van de cel per kolom


def mock_herbinden_kolom():
    """MN-40/41: de pad stuurt, dus de cursor start in Controller; cel_focus binnen de keuzebalk."""
    uit = []
    for focus_rij, kolom in ((3, 2), (4, 0)):
        img = scherm()
        y0 = M.opties_kop(img, 3, "xbox")
        for k, s in zip(KX, ("Actie", "Toetsenbord 1", "Toetsenbord 2", "Controller")):
            M.label(img, s, k + 13, y0, GLOED[6])
        y0 += 16
        for i, rij in enumerate(HERBIND):
            y = y0 + i * 18
            if rij == "ook":       # MENU_ALSO_STICK: geen cel, niet herbindbaar
                gi = M.glyph("xbox", "stick_l")
                cx = KX[3] + 13
                over(img, gi, cx, y + (15 - gi.shape[0]) // 2)
                M.label(img, "Ook: linker stick", cx + gi.shape[1] + 3, y, WIT[3])
                continue
            focus = i == focus_rij
            M.menuregel(img, rij[0], KX[0], y, 588, "focus" if focus else "normaal")
            for j, cel in enumerate(rij[1:]):
                cx = KX[j + 1] + 13
                if focus and j == kolom:
                    x0 = cx - 4
                    over(img, M.negen4(M.cel_focus(), CEL_RECHTS[j] - x0, 15, 2, 2, 2, 2), x0, y)
                if cel == "-":
                    PL.draw(img, "–", cx, y + 4, WIT[3])
                else:
                    M.cel_glyphs(img, cel, cx, y)
        yh = y0 + len(HERBIND) * 18 + 6
        M.menuregel(img, "Herstel alles", KX[0], yh, 588, "normaal")
        M.hints(img, [("dpad_horizontaal", "Kolom"), ("a", "Herbind"), ("x", "Standaard"), ("b", "Terug")], "xbox")
        uit.append(img)
    return stapel(*uit)


# ------------------------------------------------------------------ meting
def meting():
    print("Tekstmeting (Polderletter):")
    for g, vak in (("normaal", 379), ("groot", 563)):
        r2 = "Wijk 3.2 De Verzonken Gemaalpolder · Licht 100 · 12 u 59 min · Lampglas 4/4"
        print("  slot regel 2 %-7s %3d px van %d" % (g, PL.text_width(r2, g), vak))
    for g in ("normaal", "groot"):
        s = "Gemaakt met een nieuwere versie: kan niet laden"
        print("  slot NIEUWER  %-7s %3d px" % (g, PL.text_width(s, g)))
    for g, w in (("normaal", 368), ("groot", 448)):
        for s in ("Dit spel wordt gewist. Dat kan niet terug.",
                  "Het oude bestand blijft bewaard voor support, maar deze plaats begint opnieuw.",
                  "Alle kolommen krijgen weer de standaardknoppen."):
            print("  bevestiging %-7s %d regel(s) op %d px: %s" % (g, len(wrap(s, w, g)), w, s[:30]))
    for g in ("normaal", "groot"):
        print("  titel x2 'Plaats 3 overschrijven?' %d px (paneel binnen %d)"
              % (2 * PL.text_width("Plaats 3 overschrijven?"), 368 if g == "normaal" else 448))
    for s in TEKST4[1:] + ("Nog geen bladzijden in dit gebied.",):
        print("  logkader %3d px van 348 (groot %3d van 528): %s"
              % (PL.text_width(s), PL.text_width(s, "groot"), s))
    for g in ("normaal", "groot"):
        print("  credits merkenregel %-7s %d regels op 320 px" % (g, len(wrap(MERKEN, 320, g))))


def main():
    GEMAAKT.clear()
    U.preview(mock_spelbestanden(), "menu_spelbestanden_x2_placeholder.png", 2)
    U.preview(mock_spelbestanden_groot(), "menu_spelbestanden_groot_x2_placeholder.png", 2)
    U.preview(blad_slot_kader(), "menu_slot_kader_x2_placeholder.png", 2)
    U.preview(mock_logboek(), "menu_logboek_x2_placeholder.png", 2)
    U.preview(mock_credits(), "menu_credits_x2_placeholder.png", 2)
    U.preview(mock_herbinden_kolom(), "menu_herbinden_kolom_x2_placeholder.png", 2)
    print("Gemaakt (%d bestanden):" % len(GEMAAKT))
    for p, w, h in GEMAAKT:
        print("  ", p, "%dx%d" % (w, h))
    meting()


if __name__ == "__main__":
    main()
