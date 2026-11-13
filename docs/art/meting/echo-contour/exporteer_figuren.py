"""Figuren voor de meting van de echo-contour (Technical Artist, #226, risico R2).

Zet de figuren van de R5-scène (`docs/art/r5-scene/bron/genereer_r5.py`, dezelfde als in
de renders van de Art Director) als losse PNG's in `figuren/`, met 1 px transparante rand
rondom (de shader `game/art/shaders/echo_contour.gdshader` tekent de contour in die rand):

- `p1_<pose>.png`: P1 zoals de AD hem tekent, met zijn eigen contour van 1 px (#140a12);
- `echo_<pose>_<staat>.png`: de holle echo **zonder** de buitencontour van 1 px. Die komt
  in de engine uit de shader, zodat de meting de echte weergave meet. De holle pixels binnen
  het silhouet hebben alfa 1/255 (conventie van de shader: alfa > 0 = silhouet);
- `boss_fase1.png`: de concept-boss uit deel 1 (alleen voor de meting in S8, zoals de AD).

`posities.json` geeft per figuur het ankerpunt (voeten, midden onder) zoals `place()` in
`genereer_r5.py`: linksboven van de PNG = (x - breedte // 2 - 1, y - hoogte - 1).

Draaien vanaf de repo-root:
    python3 docs/art/meting/echo-contour/exporteer_figuren.py
"""
import json
import os
import sys

import numpy as np
from PIL import Image

HIER = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.abspath(os.path.join(HIER, "..", "..", "..", ".."))
sys.path.insert(0, os.path.join(REPO, "docs", "art", "slice", "bron"))
import genereer_slice_deel1 as D1  # noqa: E402
import genereer_slice_deel5 as D5  # noqa: E402

R, SP = D1.R, D1.SP
UIT = os.path.join(HIER, "figuren")
POSES = {"run0": SP.P1_RUN[0], "run1": SP.P1_RUN[1], "run2": SP.P1_RUN[2], "jump": SP.P1_JUMP}


def save(rgba, naam):
    arr = (np.clip(rgba, 0, 1) * 255 + 0.5).astype(np.uint8)
    Image.fromarray(arr, "RGBA").save(os.path.join(UIT, naam), optimize=True)


def figuur(kind, rows, staat):
    """De figuur op het R5-canvas met de voeten op (320, 300); bijgesneden met 1 px rand."""
    grid = R.sprite_arrays(rows)
    h, wd = grid.shape
    canvas, _ = R.fig_layer(kind, rows, 320, 300, staat)
    x0, y0 = 320 - wd // 2, 300 - h
    body = np.zeros(canvas.shape[:2], bool)
    body[y0:y0 + h, x0:x0 + wd] = grid != "."
    if kind == "echo":
        canvas[~body] = 0.0                 # zonder de buitencontour: die maakt de shader
        # Hol: de pixels binnen het silhouet die niets tekenen krijgen alfa 1/255. Zo kent
        # de shader het silhouet (alfa > 0) en zet hij de contour er buiten, niet in het gat.
        gat = body & (canvas[..., 3] == 0)
        canvas[gat] = (0.0, 0.0, 0.0, 1.0 / 255.0)
    return canvas[y0 - 1:y0 + h + 1, x0 - 1:x0 + wd + 1], (wd, h)


def main():
    os.makedirs(UIT, exist_ok=True)
    maten = {}
    for pose, rows in POSES.items():
        img, maat = figuur("p1", rows, "kleur")
        save(img, f"p1_{pose}.png")
        maten[f"p1_{pose}"] = maat
        for staat in ("grijs", "kleur"):
            img, maat = figuur("echo", rows, staat)
            save(img, f"echo_{pose}_{staat}.png")
            maten[f"echo_{pose}_{staat}"] = maat
    boss = D5.boss_concept("fase1")
    save(boss, "boss_fase1.png")
    maten["boss_fase1"] = [int(boss.shape[1]), int(boss.shape[0])]
    with open(os.path.join(HIER, "posities.json"), "w") as f:
        json.dump({"maten": maten, "boss_av": D1.AV}, f, indent=1)
    print("ok", len(maten), "figuren in", UIT)


if __name__ == "__main__":
    main()
