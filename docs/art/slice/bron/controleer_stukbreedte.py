"""Controle van de Art Director (#85): steekt er ergens een loopvlak in `speelvlak` buiten zijn blok?

Kijkt per kamer (D = 60) op de bovenste rij van elk blok zonder eigen stuk, 1 en 2 px links en rechts
van het blok: is daar een dekkende pixel die in geen enkel blok ligt, en is de pixel erboven leeg, dan
steekt het loopvlak uit (zoals de treden van 32 op blokken van 30, 962105a). Stukken per D en vaste
stukken worden door hun eigen test gedekt (`test_kadewijk_art.gd`).

Draaien vanaf de repo-root:  python3 docs/art/slice/bron/controleer_stukbreedte.py .
"""
import json, sys, numpy as np
from PIL import Image
repo = sys.argv[1]
b = json.load(open(f"{repo}/docs/art/slice/bron/kadewijk_blokken.json"))
m = json.load(open(f"{repo}/game/art/wereld/kadewijk/kadewijk_kamers.json"))
namen = {"S1":"s1_kade_ingang","S2":"s2_kadegang","S3":"s3_vismarkt","S4":"s4_brugkloof","S5":"s5_sluiswachtershuis",
         "S6":"s6_gemaalplein","S7":"s7_sluiskelder","S8":"s8_machinehal","S9":"s9_lage_kade"}
stuk = set(m["eenrichting"]["blokken"]) | set(m.get("vaste_stukken", {}))
tot = 0
for id_, nm in namen.items():
    rx, ry, w, h = b["60"][id_]["rect"]
    a = np.asarray(Image.open(f"{repo}/game/art/wereld/kadewijk/{nm}_speelvlak_grijs.png"))[..., 3] > 0
    blocks = [(n, x - rx, y - ry, bw, bh, e) for n, x, y, bw, bh, e in b["60"][id_]["blocks"]]
    def in_blok(x, y):
        return any(bx <= x < bx + bw and by <= y < by + bh for _, bx, by, bw, bh, _ in blocks)
    for n, x, y, bw, bh, e in blocks:
        if f"{id_}/{n}" in stuk or y < 0 or y >= h:
            continue
        y0 = int(round(y))
        for xx in (int(round(x)) - 1, int(round(x)) - 2, int(round(x + bw)), int(round(x + bw)) + 1):
            if 0 <= xx < w and a[y0, xx] and not in_blok(xx + 0.5, y0 + 0.5):
                # de rij erboven ook dekkend? dan is het een wand of decor, geen uitstekend loopvlak
                if y0 == 0 or not a[y0 - 1, xx]:
                    print(f"{id_} {n}: dekkende pixel op x {xx + rx:.0f}, y {y0 + ry:.0f} buiten elk blok"); tot += 1
print("gevonden:", tot)
