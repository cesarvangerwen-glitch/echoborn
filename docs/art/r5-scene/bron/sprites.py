"""Sprites voor de R5-scene (Art Director, #20). Zelf getekend, geen externe assets.

Elke sprite is een raster van letters. '.' = leeg. De buitencontour (1 px) wordt
automatisch toegevoegd door de render-code, dus die staat hier niet in.

Speler 1 (jonge machinist):  h/H pet, r haar, f gezicht/hand, e oog, s/S sjaal (amber), c/C/d jas, g riem, b laarzen
Speler 2 (sluiswachter):     k lijf (vol, bijna zwart), e oog, z sjaal (cyaan), p pikhaak
"""

P1_IDLE = [
    ".......hhhh.......",
    "......hHHHhh......",
    ".....hHHhhhhh.....",
    ".....hhhhhhhhh....",
    ".....hhhhhhhhhhhh.",
    ".....rrffffffff...",
    ".....rffffffeff...",
    ".....rffffffeff...",
    "......ffffffff....",
    ".......ffffff.....",
    "...SSssssssssss...",
    "..SsssssssssssS...",
    ".Ss..ccccccsSSS...",
    "Ss..cccccdccss....",
    "s...ccccccdcCCc...",
    "....cccccdccCCc...",
    "....ccccccdcCCc...",
    "....cgggggggggc...",
    "....cccccccdcCCc..",
    "....ccccccdccCff..",
    ".....cccccdcCCff..",
    ".....ccccccdCCc...",
    ".....cccc..cCC....",
    ".....cccc..cCC....",
    ".....cccC..ccC....",
    ".....CCCC..CCC....",
    ".....bbbb..bbb....",
    ".....bbbbb.bbbbb..",
]

P1_JUMP = [
    ".......hhhh.........",
    "......hHHHhh........",
    ".....hHHhhhhh.......",
    ".....hhhhhhhhh......",
    ".....hhhhhhhhhhhh...",
    ".....rrffffffff.....",
    ".....rffffffeff.....",
    ".....rffffffeff.....",
    "......ffffffff......",
    "SS.....ffffff.......",
    ".SSSSssssssssss.....",
    "...SsssssssssssS....",
    "......ccccccsSS..ff.",
    ".....cccccdccss.fff.",
    "....ccccccdcccCff...",
    "....cccccdccccCc....",
    "....cgggggggggCCc...",
    "....cccccdccccCCc...",
    "....ccccccdcccCCc...",
    "...cccccccdccccCc...",
    "..ccccc...cccccccC..",
    ".bbccc......ccCCCbb.",
    ".bbb.........bbbbb..",
]

# loopcyclus speler 1: bovenlijf + 4 beenstanden
_P1_TOP = P1_IDLE[:22]
_P1_LEGS = [
    [".....cccc..ccCC...", "....cccc....cCCc..", "...cccC.....cCCC..", "..CCCC.......CCC..", "..bbbb.......bbb..", ".bbbbb.......bbbb."],
    [".....ccccccCCC....", ".....ccccccCC.....", "......ccccCC......", "......cCCCC.......", "......bbbbb.......", "......bbbbbbb....."],
    [".....ccccc.cCC....", "......cccccCC.....", "......cCccCC......", "......CCC.CCC.....", "......bbb..bbb....", ".....bbbb..bbbb..."],
    [".....ccccccCCC....", ".....ccccccCC.....", "......ccccCC......", ".......CCCCc......", ".......bbbbb......", ".......bbbbbbb...."],
]
P1_RUN = [_P1_TOP + legs for legs in _P1_LEGS]

P2_IDLE = [
    "...................pp.",
    ".......kkkkk......p..p",
    "......kkkkkkk.....p...",
    "......kkkkkkk.....p...",
    "...kkkkkkkkkkkkk..p...",
    "....kkkkkkkkkkkk..p...",
    "......kkkkkkkk....p...",
    "......kkkkkekek...p...",
    "......kkkkkkkkk...p...",
    ".......kkkkkkk....p...",
    ".....zzzzzzzzzz...p...",
    "....zzzzzzzzzzzk..p...",
    "...zkkkkkkkkkkkkk.p...",
    "..zzkkkkkkkkkkkkkkp...",
    "..z.kkkkkkkkkkkkkkpk..",
    "....kkkkkkkkkkkkkkpk..",
    "...kkkkkkkkkkkkkk.pk..",
    "...kkkkkkkkkkkkkk.p...",
    "...kkkkkkkkkkkkkk.p...",
    "...kkkkkkkkkkkkkk.p...",
    "...kkkkkkkkkkkkkk.p...",
    "...kkkkkkkkkkkkkkkp...",
    "..kkkkkkkkkkkkkkkkp...",
    "..kkkkkkkkkkkkkkkkp...",
    "..kkkkkkkkkkkkkkkkp...",
    ".kkkkkkkkkkkkkkkkkp...",
    ".kkkkkkkkkkkkkkkkkp...",
    ".kkkkkkk..kkkkkkkkp...",
    "kkkkkkk....kkkkkkkp...",
    "....kkk.....kkk...p...",
    "....kkk.....kkk...p...",
    "...kkkk.....kkkk..p...",
    "...kkkkk....kkkkk.p...",
]

_P2_TOP = P2_IDLE[:27]
_P2_LEGS = [
    [".kkkkkkk..kkkkkkkkp...", "kkkkkk......kkkkkkp...", "..kkk........kkk..p...", ".kkk..........kkk.p...", "kkkk..........kkkkp...", "kkkkk..........kkkkk.."],
    [".kkkkkkkkkkkkkkkkkp...", "..kkkkkkkkkkkkkk..p...", ".....kkkkkkk......p...", "......kkkkk.......p...", "......kkkkk.......p...", "......kkkkkkk.....p..."],
    [".kkkkkkk..kkkkkkkkp...", "kkkkkkk....kkkkkkkp...", "...kkk......kkk...p...", "...kkk.......kkk..p...", "..kkkk.......kkkk.p...", "..kkkkk......kkkkkp..."],
    [".kkkkkkkkkkkkkkkkkp...", "..kkkkkkkkkkkkkk..p...", ".....kkkkkkk......p...", ".....kkkkkk.......p...", ".....kkkkkk.......p...", ".....kkkkkkkk.....p..."],
]
P2_RUN = [_P2_TOP + legs for legs in _P2_LEGS]
