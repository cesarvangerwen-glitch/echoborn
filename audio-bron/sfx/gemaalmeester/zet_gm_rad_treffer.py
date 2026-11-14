#!/usr/bin/env python3
"""De levende rad-treffers van de Gemaalmeester naar `game/audio/` (#243).

`gm_rad_treffer_1` en `gm_rad_treffer_2` (slice-audio.md §2.2, B-10) zijn
gemaakt door `docs/audio/t8d-slice/bron/genereer_slice_sfx.py` (functie
`gm_rad_treffer`, vaste seed 86, byte-gelijk opnieuw te maken). Dit script
zet **precies die bestanden** in het spel, zonder ze opnieuw te renderen:
de holle `game/audio/sfx/echo/echo_gm_rad_treffer_1_placeholder.wav` is met
`echo_versie` uit déze `_1` afgeleid (slice-audio.md §7.2), dus zo blijft
"dat ben jij, maar hol" kloppen (bible §4).

- `_1`: ijzer dat zingt (C5, inharmonische boventonen); elke treffer van P1/P2
  die de kant nog niet vol maakt. Ook de bron van de holle echo-versie.
- `_2`: dezelfde klank een kwart hoger, "deze kant is klaar"; alleen op de
  treffer die `kant_treffers` haalt, nooit voor de echo (bible §4.1).

Opnieuw maken, vanaf de repo-root:
    python3 docs/audio/t8d-slice/bron/genereer_slice_sfx.py   # alleen als de bron wijzigt
    python3 audio-bron/sfx/gemaalmeester/zet_gm_rad_treffer.py

Schrijft:
    game/audio/sfx/gemaalmeester/gm_rad_treffer_{1,2}_placeholder.wav (48 kHz, 16 bit, mono)
    docs/audio/luik-rad/meting_placeholder.json (bijgewerkt)
Het .import-bestand maakt Godot 4.6.3 (`godot --headless --path game --import`).
"""
import importlib.util
import os
import shutil
import sys

import numpy as np
from scipy.io import wavfile

HIER = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(os.path.dirname(HIER)))
BRON = os.path.join(ROOT, "docs", "audio", "t8d-slice", "sfx", "gemaalmeester")
GAME_UIT = os.path.join(ROOT, "game", "audio", "sfx", "gemaalmeester")

sys.dont_write_bytecode = True
_spec = importlib.util.spec_from_file_location("luik", os.path.join(ROOT, "audio-bron", "sfx", "omgeving",
                                                                     "genereer_luik_breekt.py"))
luik = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(luik)  # alleen de meet-hulp; schrijft niets
ps = luik.ps


def main():
    os.makedirs(GAME_UIT, exist_ok=True)
    for i in (1, 2):
        naam = f"gm_rad_treffer_{i}_placeholder.wav"
        bron, doel = os.path.join(BRON, naam), os.path.join(GAME_UIT, naam)
        shutil.copyfile(bron, doel)
        assert luik.sha(bron) == luik.sha(doel)
        sr, x = wavfile.read(doel)
        assert sr == 48000 and x.dtype == np.int16 and x.ndim == 1, "verwacht 48 kHz, 16 bit, mono"
        x = x.astype(np.float64) / 32767
        data = {"pad": os.path.relpath(doel, ROOT), "bron": os.path.relpath(bron, ROOT), **ps.meet(x),
                "ffmpeg_ebur128": ps.ebur128(doel), "sha256": luik.sha(doel)}
        luik.bij_meting(naam, data)
        print(naam, data["duur_ticks"], "t", data["lufs_momentaan_max"], "LUFS", data["true_peak_dbtp"], "dBTP")


if __name__ == "__main__":
    main()
