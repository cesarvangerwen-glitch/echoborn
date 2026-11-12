extends RefCounted
## Geometrie van de Kadewijk: S1–S9 als grijze blokken (T8a, #83; deel 1
## S1–S4 hieronder getekend, deel 2 S5–S8 vanaf "S5 Sluiswachtershuis",
## deel 3 S9 (de lage kade, de lus terug naar S1) vanaf "S9 Lage kade";
## `docs/design/wereld.md` §2.2, gdd v0.8.2 §4.3 en §4.8.5;
## `docs/design/kamers/kadewijk.md`, §2 en §3b–§3e).
##
##   y=0    +----------+-------------------------+------------------+------------------+
##          | S1       | S2 Kadegang             | S3 Vismarkt      | S4 Brugkloof     |
##   y=70   |          | ===galerij B1==>------------>+            |                  |
##   y=160  |          | <==B3-galerij== gang B1  |    |            |                  |
##   y=230  | =galerij=>  ---> kom B3 | wand      |    v arena      |  aanloop  kloof  overkant
##   y=260  |          |                          |  ============== =====b     ====== ====
##   y=320  | <-- gang B1 (start)                 |                  |      bodem       |
##   y=360  +----------+-------------------------+------------------+------------------+
##
## Route (kritiek pad, links naar rechts): S1 B1 keren tegen de linkerwand en
## naar de galerij op 230; S2 over de kade naar de kom van B3 (bij D = 60 een
## keerpunt), bouncen naar de galerij op 160 (terug naar links), daar het
## E-paar, B1 tegen de brugpijler (x 700) en naar de bovenroute op 70; S3 de
## merk-arena op 260 (twee golven, sluit niet af); S4 de lanceerkloof (B4)
## achter een keerpunt (`b`, de bolder op de rand; #217) en de Kadeloper aan de
## overkant. Alles wereldpixels, y naar beneden; een vloer
## is de bovenkant van een blok. De maten komen uit gdd §4.3; wat van D
## afhangt (keerzone Z, de trede op 90, het B3-blok) is een formule hieronder
## (fasekader v0.4 §4, regel 2), en de kamerscènes bouwen hun blokken hieruit
## (`kadewijk_inhoud.gd`). Zo lezen de scènes, de bot en de tests dezelfde
## getallen.
##
## Geen schaduwgeometrie, geen FelLicht, geen Schaduwgevaar (L-06). Water:
## S1–S6 op `s = 0`, het water van de kelderingang (S6) zakt met het gemaal
## (LM-06); de waterstand per wijk (`s` 0/1/2) bestaat nog niet (GP, kamerdoc).

## Lichaam 16 × 30: het middelpunt staat 15 px boven de vloer.
const HALF_H := 15.0
const HALF_W := 8.0
const ONE_WAY_T := 6.0
const TREAD_T := 4.0
const TREAD_W := 40.0
const ROOM_H := 360.0

const ROOMS := {
	&"S1": Rect2(0, 0, 640, 360),
	&"S2": Rect2(640, 0, 960, 360),
	&"S3": Rect2(1600, 0, 960, 360),
	&"S4": Rect2(2560, 0, 960, 360),
	# Deel 2 (#83): het sluiswachtershuis en het gemaalplein liggen hoger
	# (trappenhuis omhoog, loopbrug naar het plein), de kelder en de
	# machinehal eronder.
	&"S5": Rect2(3520, -200, 640, 560),
	&"S6": Rect2(4160, -200, 960, 560),
	&"S7": Rect2(4800, 360, 960, 360),
	&"S8": Rect2(4160, 360, 640, 360),
	# Deel 3 (#83): de lage kade onder S1–S5, van de arena terug naar S1.
	&"S9": Rect2(0, 360, 4160, 360),
}
## Buren (E-04a): de doorgangen. S4–S5 op de kade, S5–S6 over de zolder en de
## loopbrug, S6–S7 door de kelderingang (de sluis), S7–S8 de deur van de
## machinehal. Deel 3: S8–S9 de deur links van de arena, S5–S9 de trap terug
## naar het plein (die door de hoek van S5 loopt), S9–S1 de snelkoppeling (het
## snelluik in de gang van S1; de lus, L-14 f).
const NEIGHBOURS := {
	&"S1": [&"S2", &"S9"],
	&"S2": [&"S1", &"S3"],
	&"S3": [&"S2", &"S4"],
	&"S4": [&"S3", &"S5"],
	&"S5": [&"S4", &"S6", &"S9"],
	&"S6": [&"S5", &"S7"],
	&"S7": [&"S6", &"S8"],
	&"S8": [&"S7", &"S9"],
	&"S9": [&"S8", &"S5", &"S1"],
}
const ORDER := [&"S1", &"S2", &"S3", &"S4", &"S5", &"S6", &"S7", &"S8", &"S9"]
## Deel 1 (S1–S4, PR #208/#220): de runs tot `END_X` en hun normen per kamer.
const DEEL_1 := [&"S1", &"S2", &"S3", &"S4"]
const AREA_RIGHT := 5760.0
const AREA_TOP := -200.0
const AREA_BOTTOM := 720.0

## --- S1 Kade-ingang: B1 tegen de linkerwand (gracht) ---
const S1_WALL := 20.0
const S1_FLOOR := 320.0
const S1_UP := 230.0             ## galerij op 90 = de kade naar S2
const S1_QUAY_LEFT := 500.0      ## 480 px van de wand: einde van de galerij, begin van de kademuur
## Het snelluik (deel 3): een eenrichtingsluik in de gang, achter het begin en
## buiten de aanloop van B1; de schacht van S9 komt hier uit (de lus, L-14 f).
## Van boven loop je eroverheen, van onder spring je erdoor.
const SNELLUIK := Rect2(460, S1_FLOOR, 40, ONE_WAY_T)

## --- S2 Kadegang: kade op 230, B3 (lus/keerpunt), gang op 160, B1, bovenroute op 70 ---
const S2_FLOOR := 230.0
const S2_MID := 160.0            ## galerij van B3 (70 boven de kom) = gang van B1
const S2_TOP := 70.0             ## galerij van B1 (90 boven de gang) = bovenroute naar S3
const S2_PIJLER := 700.0         ## keerwand van B1 (brugpijler), hangt van 76 tot 166
const B3_ENTRANCE := 1060.0      ## ingang van de kom
const B3_GALLERY_TIP := 1100.0   ## de galerij steekt 40 px de kom in
const B3_BLOCK_LEFT := 1250.0    ## kom van 190 px; blok (per D) of keerwand
const S2_TOP_SOLID := 1180.0     ## galerij B1 tot 480 px van de pijler, daarna dicht

## --- S3 Vismarkt: merk-arena op 260 ---
const S3_ENTRY_RIGHT := 1680.0   ## einde van de bovenroute; je valt de markt op
const S3_FLOOR := 260.0
const S3_LEFT := 1680.0
const S3_PLATFORMS := [Rect2(1820, 190, 120, ONE_WAY_T), Rect2(2180, 190, 120, ONE_WAY_T)]

## --- S4 Brugkloof: B4 naar rechts ---
const S4_FLOOR := 260.0
const B4_NEAR_EDGE := 2900.0
const B4_FAR_EDGE := 3060.0
const KLOOF_BOTTOM := 350.0      ## 90 px lager
## Keerpunt vóór B4 (#217, kamerdoc §3a): een bolder op de rand, de keerwand
## van de lancering. ≤ 12 hoog: dan haalt een sprong + dash van de bolder de
## overkant niet (gemeten: 8 → 3046, 16 → 3050, 20 → over; overkant vanaf 3052).
const B4_BOLDER_W := 8.0
const B4_BOLDER_H := 8.0
## Einde van de overkant: de kade loopt door naar S5 (deel 2).
const S4_END_WALL := 3520.0
## Einde van deel 1: wie hier is, haalde S1–S4 (RUN_EIND bij `run_end` = S4).
const END_X := 3440.0

## --- S5 Sluiswachtershuis: B2 zigzag omhoog naar de zolder (gdd §4.3, L-09) ---
## Een schacht van 480 px met vier eenrichtingsrichels van `450 − D` px op
## 90, 180, 270 en 360 px boven de vloer, om en om tegen de linker- en de
## rechterwand; aan de open kant een gat van Z px boven de keerwand eronder.
## De bovenste richel is de zolder en loopt door de rechterwand naar S6.
const S5_FLOOR := 260.0
const B2_LEFT := 3600.0
const B2_RIGHT := 4080.0
## Vloeren van onder naar boven: de kade, richel 1–3, de zolder.
const B2_LEVELS := [260.0, 170.0, 80.0, -10.0, -100.0]
const S5_ZOLDER := -100.0
## Het lampglas (L-12, WS-08; placeholder, de GP maakt het object) op de
## zolder, 105 px boven richel 3: alleen met de bounce in één beweging te
## halen, of via de treden (langzame lijn).
const LAMPGLAS := Vector2(3900, S5_ZOLDER - HALF_H)
## Logbladzijde 1 (het logboek op de tafel in het huis, placeholder).
const LOGBLAD_1 := Vector2(3700, S5_FLOOR - 12.0)

## --- S6 Gemaalplein: loopbrug, plein, pompgang (FK-5, L-14 b), sluis ---
const S6_FLOOR := 260.0
const S6_BRUG_END := 4260.0
## Pompschoepen: 80 px uit elkaar in de looprichting, middelpunt 38 px boven
## de vloer (FK-5: 15–40), zoals de flow-kamer.
const VANE_UP := 38.0
const PUMP_VANES := [
	Vector2(4480, S6_FLOOR - VANE_UP),
	Vector2(4560, S6_FLOOR - VANE_UP),
	Vector2(4640, S6_FLOOR - VANE_UP),
	Vector2(4720, S6_FLOOR - VANE_UP),
]
## De kelderingang: de sluis is een klep over de schacht naar S7, die opengaat
## op `t_v` (LM-06). 280 px na de laatste schoep (FK-5: ≥ `2 × (D − 40)`,
## dus voor elke D tot 180).
const SLUICE := Rect2(5000, 260, 60, 10)
const S6_SHAFT_LEFT := 5000.0
const S6_SHAFT_RIGHT := 5060.0
## Water in de kelderingang (`Diepwater` van het gemaal): de schacht onder de
## sluis, tot 40 px boven de bovenvloer van S7 (wie er doorheen valt, is er
## korter dan 30 ticks in).
const S6_STREET := Rect2(5000, 270, 60, 130)
const S6_WATER_HIGH := 272.0
const S6_WATER_LOW := 400.0
## Trap terug naar de loopbrug (L-10, en de langzame lijn voor licht zonder
## echo): eenrichtingstreden van 45 px (FK-6) recht boven elkaar.
const S6_STAIR_X := 4200.0
const S6_STAIR := [215.0, 170.0, 125.0, 80.0, 35.0, -10.0, -55.0]
## Logbladzijde 2 en de bevroren echo's (placeholders).
const LOGBLAD_2 := Vector2(4920, S6_FLOOR - 12.0)

## --- S7 Sluiskelder: de sokkel, het luik, het kanaal met twee Dwaallichten ---
const S7_UP := 440.0              ## bovenvloer (de schacht komt hier uit)
const S7_LOW := 620.0             ## benedenvloer
const S7_POCKET_LEFT := 4960.0
const S7_POCKET_RIGHT := 5340.0
## Het luik (V-01, SL-04: P1 breekt het met een neerslag), in de bovenvloer.
const LUIK := Rect2(5260, 440, 40, 16)
const SOKKEL := Vector2(5150, S7_UP)
## Kanaal van 160 px (V-01b: stuiten op de Dwaallichten in plaats van
## overspringen; langzame lijn: de kademuur en een trede).
const KANAAL_LEFT := 4960.0
const KANAAL_RIGHT := 5120.0
const KANAAL_BOTTOM := 710.0
## Dwaallichten op 1/3 en 2/3 van het kanaal, banen van 32 px
## (`slice-vijanden-en-boss.md` §2.6).
const DWAALLICHT_X := [5013.0, 5067.0]
const DWAALLICHT_LANE := 16.0
const S7_RIGHT_WALL := 5740.0

## --- S8 Machinehal: de arena van de Gemaalmeester (GM-01, GMB-01–06) ---
## Een scherm met een vlakke vloer van 600 px tussen twee muren; geen richels.
## `ARENA_ORIGIN` = de linkermuur op de bovenkant van de vloer (de `origin`
## van `gemaalmeester.gd`). De deur rechts (van S7) staat open tot
## `BOSS_START`, de deur links (naar S9) is dicht tot `BOSS_VERSLAGEN`: dat
## koppelt de Gameplay Programmer.
const ARENA_WALL_L := 4180.0
const ARENA_WALL_R := 4780.0
const ARENA_FLOOR := 680.0
const ARENA_W := 600.0
const ARENA_ORIGIN := Vector2(ARENA_WALL_L, ARENA_FLOOR)
const ARENA_DOOR_R := Rect2(4780, 360, 20, 260)
const ARENA_DOOR_L := Rect2(4160, 360, 20, 360)
## Blokken die bij het laden open staan (geen collision, niet in beeld); de
## Gameplay Programmer sluit ze bij `BOSS_START` (`Kadewijk.set_door`).
const START_OPEN := ["DeurRechts"]

## --- S9 Lage kade: de lus terug naar S1 (deel 3; wereld.md §2.2, L-14 d–f) ---
## Van de deur links van de arena (vloer 680) naar links: de trap terug naar
## het plein (voor trap 2, SL-02), het hoogwater (tot `s = 2` dicht), de lage
## kade op 635 met het E-paar (verlicht, VJ-06), het luik in de kade (SL-04:
## de enige vaardigheidspoort van de slice; zonder V-01 een doodlopende kade),
## de benedenkade op 700, **B1** tegen de grachtwand onder S1 met
## logbladzijde 3 op de galerij (L-12), en de schacht naar het snelluik in de
## gang van S1 (`SLICE_EIND`). Onderweg de brugpijler (B2, twee verdiepingen).
const S9_DOOR_FLOOR := 680.0       ## = `ARENA_FLOOR`: je loopt de arena uit
const S9_KADE := 635.0             ## de lage kade: 45 boven de vloer bij de deur (FK-6)
const S9_LAAG := 700.0             ## de benedenkade, onder het luik
const S9_STEP_X := 3980.0          ## de kademuur van de lage kade (45 hoog)
## Placeholder voor de waterstand (LM-10, SL-02): tot `s = 2` staat de lage
## kade onder water. Een blok dat de Gameplay Programmer opent met
## `Kadewijk.set_door(&"S9", "Hoogwater", false)` als trap 2 vol is.
const S9_HOOGWATER := Rect2(3920, 360, 60, S9_KADE - 360.0)
## De brugpijler onder S4 (B2 met twee verdiepingen, zoals S5): de lage kade
## loopt tegen de pijler; keren en bouncen naar richel 1 (tegen de pijlerwand
## rechts), daar keren en bouncen naar richel 2, die over de pijler gaat; dan
## naar links eraf, terug op de kade. Een schacht van 480 px, dus de maten van
## B2 (`b2_keerzone`, `b2_ledge`). Langzame lijn: de treden 30/60/90.
const S9_PIJLER := Rect2(2520, 455, 60, S9_KADE - 455.0)
const S9_B2_LEFT := 2580.0
const S9_B2_RIGHT := 3060.0
const S9_B2_LEVELS := [S9_KADE, S9_KADE - 90.0, S9_KADE - 180.0]
## Het luik in de kade (V-01, SL-04; `kadewijk_luik.gd`, zoals in S7), vlak
## vóór de kadewand: de lage kade loopt dood.
const S9_LUIK := Rect2(560, S9_KADE, 40, 16)
const S9_KADEWAND := Rect2(520, 360, 20, S9_KADE + 16.0 - 360.0)
## Rechts van het luik ligt de kadevloer als plaat (16 dik) tot hier; daaronder
## loopt de benedenkade naar links, de B1-hal in.
const S9_PLAAT_END := 700.0
## B1 tegen de grachtwand: dezelfde maten als in S1, één verdieping lager.
const S9_WALL := 20.0
const S9_UP := S9_LAAG - 90.0      ## galerij op 90 (610)
const S9_SHAFT_LEFT := 460.0       ## einde van de galerij = de schacht (onder het snelluik)
const S9_SHAFT_RIGHT := 500.0
## De schacht: eenrichtingstreden recht boven elkaar, ≤ 45 px (FK-6), van de
## galerij (610) tot het snelluik (320).
const S9_SHAFT := [569.0, 528.0, 486.0, 445.0, 403.0, 362.0]
## Logbladzijde 3 (WS-08, placeholder) op de galerij: 105 px boven de
## benedenkade, dus in één beweging alleen met de bounce (L-12; zoals het
## lampglas). Langzame lijn: de treden van B1.
const LOGBLAD_3 := Vector2(300, S9_UP - HALF_H)
## De trap terug naar het plein (voor trap 2; SL-02, GM-10): een schacht van
## 50 px (x 4100–4150) in de hoek bij de deur, door de hoek van S5 omhoog naar
## de linkerrand van het plein (260). Treden van 30 px om en om tegen de linker-
## en de rechterwand, 42 px boven elkaar: omhoog spring je schuin naar de
## volgende, omlaag stap je eraf en vang je de volgende. Het plein is zo ook de
## weg terug naar de lage kade. De bovenste twee liggen in S5.
const S9_TRAP_LEFT := 4100.0
const S9_TRAP_RIGHT := 4150.0
const S9_TRAP_W := 30.0
const S9_TRAP := [638.0, 596.0, 554.0, 512.0, 470.0, 428.0, 386.0, 344.0, 302.0]
## Onderkant van de trapwanden: de doorgang van de deur (680) blijft vrij.
const S9_TRAP_WALL_BOTTOM := 640.0
## Waar de echolijn van S9 begint en eindigt (de tests).
const S9_END := Vector2(480, S1_FLOOR - HALF_H)


## Treden van de trap terug naar het plein: [y, x0], om en om links en rechts.
static func s9_trap_treads() -> Array:
	var out: Array = []
	for i in S9_TRAP.size():
		var x0 := S9_TRAP_LEFT if i % 2 == 0 else S9_TRAP_RIGHT - S9_TRAP_W
		out.append([S9_TRAP[i], x0])
	return out


## Begin van elke kamer (LM-05, LM-08: vaste, veilige plek; ook het debugmenu).
const ROOM_START := {
	&"S1": Vector2(440, S1_FLOOR - HALF_H),
	&"S2": Vector2(660, S2_FLOOR - HALF_H),
	&"S3": Vector2(1620, S2_TOP - HALF_H),
	&"S4": Vector2(2580, S4_FLOOR - HALF_H),
	&"S5": Vector2(3540, S5_FLOOR - HALF_H),
	&"S6": Vector2(4180, S5_ZOLDER - HALF_H),
	&"S7": Vector2(5030, S7_UP - HALF_H),
	&"S8": Vector2(4790, S7_LOW - HALF_H),
	&"S9": Vector2(4060, S9_DOOR_FLOOR - HALF_H),
}
const RUN_START := Vector2(440, S1_FLOOR - HALF_H)


## --- Formules in D (gdd §4.3, §4.8.5) ---

## Keerzone: de weg omhoog begint op `Z = D + 30` px van de keerwand.
static func keerzone(d: int) -> float:
	return float(d + 30)


## Vlakke aanloop vóór een keerpunt: `D + 24`.
static func aanloop(d: int) -> float:
	return float(d + 24)


## Bovenkant van het B3-blok: `max(D − 60, 0)`; bij D = 60 geen blok (keerpunt).
static func b3_width(d: int) -> float:
	return float(maxi(d - 60, 0))


## Breedte van de trede op 90 van de langzame lijn (gdd §4.3: Z en de treden
## per D in data). Bij D = 60 40 px, zoals de flow-kamer (W-8): van de trede op
## 60 spring je schuin naar de galerij. Bij een langere D groeit de keerzone,
## en daarmee keren (`D/2 + 34`); de trede op 90 loopt dan door tot 14 px vóór
## Z, zodat de langzame lijn meegroeit (drie sprongen en het stuk lopen tot Z).
## Werkaanname WLD, gemeten in `test_kadewijk.gd` (kamerdoc §3).
static func tread_90_width(d: int) -> float:
	return TREAD_W if d <= 60 else keerzone(d) - 14.0


## B4 achter een keerpunt (#217): P1 keert tegen de bolder met zijn middelpunt
## hier; de echo komt hem tegemoet en ontmoet hem ± `D − 6` px ervoor (zoals bij
## B1 gemeten).
const B4_TURN_X := B4_NEAR_EDGE - B4_BOLDER_W - HALF_W
## Tot zo ver van de rand haalt een lancering met een dash na de top de overkant.
const B4_HOP_MAX := 80.0


static func b4_meet(d: int) -> float:
	return float(d) - 6.0


## Korte staart: op de echo springen waar hij je tegemoetkomt (lancering + dash).
static func b4_hop(d: int) -> bool:
	return b4_meet(d) + (B4_NEAR_EDGE - B4_TURN_X) <= B4_HOP_MAX


## Waar je AANVAL slaat (en vasthoudt tot de bolder): bij `hop` ruim vóór de
## ontmoeting, anders 14 ticks vóór de bolder, zodat de houding pas aan de
## bolder begint en de echo je erheen draagt.
static func b4_strike_x(d: int) -> float:
	if b4_hop(d):
		return B4_TURN_X - b4_meet(d) - 40.0
	return B4_TURN_X - 28.0


## De keerpunten (B1, B3 en de verdiepingen van B2 in S5), voor de bot en de
## tests. `wall` = x van het keervlak, `side` = kant van de wand (-1 = links
## van P1). Index 0–2: deel 1; 3–6: S5 (B2, van onder naar boven).
static func turn_points(d: int) -> Array:
	return [
		{"name": "S1-B1", "wall": S1_WALL, "floor": S1_FLOOR, "side": -1, "up": S1_UP},
		{"name": "S2-B3", "wall": B3_BLOCK_LEFT + b3_width(d), "floor": S2_FLOOR, "side": 1, "up": S2_MID},
		{"name": "S2-B1", "wall": S2_PIJLER, "floor": S2_MID, "side": -1, "up": S2_TOP},
		{"name": "S5-B2a", "wall": B2_RIGHT, "floor": B2_LEVELS[0], "side": 1, "up": B2_LEVELS[1], "z": b2_keerzone(d)},
		{"name": "S5-B2b", "wall": B2_LEFT, "floor": B2_LEVELS[1], "side": -1, "up": B2_LEVELS[2], "z": b2_keerzone(d)},
		{"name": "S5-B2c", "wall": B2_RIGHT, "floor": B2_LEVELS[2], "side": 1, "up": B2_LEVELS[3], "z": b2_keerzone(d)},
		{"name": "S5-B2d", "wall": B2_LEFT, "floor": B2_LEVELS[3], "side": -1, "up": B2_LEVELS[4], "z": b2_keerzone(d)},
		# Index 7: keren tegen de linkermuur van de arena (GM-07: de bounce naar
		# het rad). Geen weg omhoog (GM-01: geen richels), dus de stap rondt nooit
		# af; alleen voor de arena-test.
		{"name": "S8-rad", "wall": ARENA_WALL_L, "floor": ARENA_FLOOR, "side": -1, "up": ARENA_FLOOR - 400.0},
		# Index 8: S9, B1 tegen de grachtwand naar de galerij met logbladzijde 3.
		{"name": "S9-B1", "wall": S9_WALL, "floor": S9_LAAG, "side": -1, "up": S9_UP},
		# Index 9–10: S9, B2 over de brugpijler (van onder naar boven).
		{"name": "S9-B2a", "wall": S9_B2_LEFT, "floor": S9_B2_LEVELS[0], "side": -1, "up": S9_B2_LEVELS[1], "z": b2_keerzone(d)},
		{"name": "S9-B2b", "wall": S9_B2_RIGHT, "floor": S9_B2_LEVELS[1], "side": 1, "up": S9_B2_LEVELS[2], "z": b2_keerzone(d)},
	]


## B2: de keerzone. `Z = D + 30` (gdd §4.3), behalve als de loop over de
## richel (van de landing, ± `D + 70` van de vorige wand, tot de volgende
## wand: `(480 − (D + 88)) / 2` ticks) korter is dan D: dan hangt je echo bij
## het keren nog in zijn bounce, en keren duurt ± 8 ticks langer (gemeten bij
## D = 180: 133 tegen 125). Dan `Z = D + 40`, de grens van gdd §4.3 ("Z mag
## tot D + 40"), zodat ook de langzame lijn met dash ≥ 20 ticks trager blijft
## (gdd §4.8.7). Werkaanname WLD (kamerdoc §3b): alleen bij D > 130.
static func b2_keerzone(d: int) -> float:
	if (480.0 - (d + 88.0)) * 0.5 < float(d):
		return float(d + 40)
	return keerzone(d)


## B2: breedte van een richel, `480 − Z` (gdd §4.3: `450 − D`, 390 bij D = 60).
static func b2_ledge(d: int) -> float:
	return 480.0 - b2_keerzone(d)


## Vlak waarin de camera mag kijken (de rechthoek om alle kamers).
static func area_rect() -> Rect2:
	var out: Rect2 = ROOMS[ORDER[0]]
	for id: StringName in ORDER:
		out = out.merge(ROOMS[id])
	return out


## Kamer waarin `at` ligt (zelfde regel als `Kamer.contains`: halfopen).
static func room_of(at: Vector2) -> StringName:
	for id: StringName in ORDER:
		if (ROOMS[id] as Rect2).has_point(at):
			return id
	return &""


## Alle blokken van kamer `id` bij staart `d`, als [naam, rect, eenrichting].
static func blocks(id: StringName, d: int) -> Array:
	var out: Array = []
	var r: Rect2 = ROOMS[id]
	if id != &"S7" and id != &"S9":
		out.append(["Plafond", Rect2(r.position.x, r.position.y - 20, r.size.x, 20), false])
	match id:
		&"S1":
			var z := keerzone(d)
			out.append(["WandLinks", Rect2(0, 0, S1_WALL, ROOM_H), false])
			# De gang tot het snelluik (deel 3); het luik is een eenrichtingsvloer.
			out.append(["Gang", Rect2(S1_WALL, S1_FLOOR, SNELLUIK.position.x - S1_WALL, ROOM_H - S1_FLOOR), false])
			out.append(["Snelluik", SNELLUIK, true])
			out.append(["Kademuur", Rect2(S1_QUAY_LEFT, S1_UP, r.end.x - S1_QUAY_LEFT, ROOM_H - S1_UP), false])
			out.append(["Galerij", Rect2(S1_WALL + z, S1_UP, S1_QUAY_LEFT - S1_WALL - z, ONE_WAY_T), true])
			out.append_array(_treads("B1", S1_WALL, 1.0, S1_FLOOR, d))
		&"S2":
			var z := keerzone(d)
			var b := b3_width(d)
			out.append(["Kade", Rect2(r.position.x, S2_FLOOR, B3_BLOCK_LEFT + b - r.position.x, ROOM_H - S2_FLOOR), false])
			# Brugpijler: keerwand van B1, hangt boven de kade (je loopt er op 230 onderdoor).
			out.append(["Pijler", Rect2(S2_PIJLER - 20, S2_TOP + ONE_WAY_T, 20, S2_MID + ONE_WAY_T - S2_TOP - ONE_WAY_T), false])
			out.append(["Gang160", Rect2(S2_PIJLER, S2_MID, B3_GALLERY_TIP - S2_PIJLER, ONE_WAY_T), true])
			out.append(["B3Trede", Rect2(B3_GALLERY_TIP, S2_FLOOR - 35, TREAD_W, TREAD_T), true])
			if b > 0.0:
				out.append(["B3Blok", Rect2(B3_BLOCK_LEFT, S2_FLOOR - 45, b, 45), false])
			out.append(["B3Wand", Rect2(B3_BLOCK_LEFT + b, S2_TOP + ONE_WAY_T, r.end.x - B3_BLOCK_LEFT - b, ROOM_H - S2_TOP - ONE_WAY_T), false])
			out.append(["Galerij70", Rect2(S2_PIJLER + z, S2_TOP, S2_TOP_SOLID - S2_PIJLER - z, ONE_WAY_T), true])
			out.append(["Bovenroute", Rect2(S2_TOP_SOLID, S2_TOP, r.end.x - S2_TOP_SOLID, ONE_WAY_T), false])
			out.append_array(_treads("B1", S2_PIJLER, 1.0, S2_MID, d))
		&"S3":
			out.append(["Bovenroute", Rect2(r.position.x, S2_TOP, S3_ENTRY_RIGHT - r.position.x, ROOM_H - S2_TOP), false])
			out.append(["Markt", Rect2(S3_LEFT, S3_FLOOR, r.end.x - S3_LEFT, ROOM_H - S3_FLOOR), false])
			for i in S3_PLATFORMS.size():
				out.append(["Kraam%d" % (i + 1), S3_PLATFORMS[i], true])
		&"S4":
			out.append(["Aanloop", Rect2(r.position.x, S4_FLOOR, B4_NEAR_EDGE - r.position.x, ROOM_H - S4_FLOOR), false])
			out.append(["Bolder", Rect2(B4_NEAR_EDGE - B4_BOLDER_W, S4_FLOOR - B4_BOLDER_H, B4_BOLDER_W, B4_BOLDER_H), false])
			out.append(["KloofBodem", Rect2(B4_NEAR_EDGE, KLOOF_BOTTOM, B4_FAR_EDGE - B4_NEAR_EDGE, ROOM_H - KLOOF_BOTTOM + 20), false])
			# Langzame lijn: twee treden van 45 tegen de overkant (gdd §4.3 B4; "via de kademuur").
			out.append(["KloofTrede", Rect2(B4_FAR_EDGE - TREAD_W, KLOOF_BOTTOM - 45, TREAD_W, 45), false])
			# De overkant loopt door naar S5 (deel 2; tot #83 deel 2 hier de `EindWand`).
			out.append(["Overkant", Rect2(B4_FAR_EDGE, S4_FLOOR, S4_END_WALL - B4_FAR_EDGE, ROOM_H - S4_FLOOR), false])
		&"S5":
			var w := b2_ledge(d)
			out.append(["Vloer", Rect2(r.position.x, S5_FLOOR, B2_RIGHT - r.position.x, ROOM_H - S5_FLOOR), false])
			# Linkerwand van de schacht; de gang van S4 loopt eronder door (84 px hoog).
			out.append(["WandLinks", Rect2(r.position.x, r.position.y, B2_LEFT - r.position.x, B2_LEVELS[1] + ONE_WAY_T - r.position.y), false])
			# Rechterwand; zijn bovenkant is de zolder, die doorloopt naar S6.
			# Deel 3: onderin de hoek loopt de trap van S9 naar het plein, achter
			# een wand van 20 px (geen weg van het huis naar het plein).
			out.append(["WandRechts", Rect2(B2_RIGHT, S5_ZOLDER, S9_TRAP_LEFT - B2_RIGHT, ROOM_H - S5_ZOLDER), false])
			out.append(["WandRechts2", Rect2(S9_TRAP_LEFT, S5_ZOLDER, r.end.x - S9_TRAP_LEFT, S6_FLOOR - 60.0 - S5_ZOLDER), false])
			for tr: Array in s9_trap_treads():
				if tr[0] < r.end.y:
					out.append(["Trap9_%d" % int(tr[0]), Rect2(tr[1], tr[0], S9_TRAP_W, ONE_WAY_T), true])
			for i in range(1, B2_LEVELS.size()):
				var y: float = B2_LEVELS[i]
				var x0 := B2_LEFT if i % 2 == 1 else B2_RIGHT - w
				out.append(["Richel%d" % i if i < 4 else "Zolder", Rect2(x0, y, w, ONE_WAY_T), true])
			for tp: Dictionary in turn_points(d).slice(3, 7):
				var prefix: String = String(tp["name"]).trim_prefix("S5-")
				out.append_array(_treads(prefix, tp["wall"], -float(tp["side"]), tp["floor"], d))
		&"S6":
			out.append(["Loopbrug", Rect2(r.position.x, S5_ZOLDER, S6_BRUG_END - r.position.x, ONE_WAY_T), true])
			out.append(["Plein", Rect2(r.position.x, S6_FLOOR, S6_SHAFT_LEFT - r.position.x, ROOM_H - S6_FLOOR), false])
			out.append(["WandRechts", Rect2(S6_SHAFT_RIGHT, r.position.y, r.end.x - S6_SHAFT_RIGHT, ROOM_H - r.position.y), false])
			for i in S6_STAIR.size():
				out.append(["Trap%d" % (i + 1), Rect2(S6_STAIR_X - TREAD_W * 0.5, S6_STAIR[i], TREAD_W, ONE_WAY_T), true])
		&"S7":
			# Plafond met het gat van de schacht (de kelderingang van S6).
			out.append(["Plafond", Rect2(r.position.x, r.position.y - 20, S6_SHAFT_LEFT - r.position.x, 20), false])
			out.append(["Plafond2", Rect2(S6_SHAFT_RIGHT, r.position.y - 20, r.end.x - S6_SHAFT_RIGHT, 20), false])
			# De bovenvloer (de kelder) met het luik; dicht aan beide kanten.
			out.append(["KelderWandLinks", Rect2(S7_POCKET_LEFT - 20, r.position.y, 20, S7_UP + 16 - r.position.y), false])
			out.append(["Bovenvloer", Rect2(S7_POCKET_LEFT, S7_UP, LUIK.position.x - S7_POCKET_LEFT, 16), false])
			out.append(["Bovenvloer2", Rect2(LUIK.end.x, S7_UP, S7_POCKET_RIGHT - LUIK.end.x, 16), false])
			out.append(["KelderWandRechts", Rect2(S7_POCKET_RIGHT, r.position.y, 20, S7_UP + 16 - r.position.y), false])
			# Benedenvloer: west van het kanaal (naar de machinehal), het kanaal, oost.
			out.append(["VloerWest", Rect2(r.position.x, S7_LOW, KANAAL_LEFT - r.position.x, r.end.y - S7_LOW), false])
			out.append(["KanaalBodem", Rect2(KANAAL_LEFT, KANAAL_BOTTOM, KANAAL_RIGHT - KANAAL_LEFT, r.end.y - KANAAL_BOTTOM + 20), false])
			# Langzame lijn: een trede van 45 tegen de westkant (de kademuur, FK-6).
			out.append(["KanaalTrede", Rect2(KANAAL_LEFT, KANAAL_BOTTOM - 45, TREAD_W, 45), false])
			out.append(["VloerOost", Rect2(KANAAL_RIGHT, S7_LOW, S7_RIGHT_WALL - KANAAL_RIGHT, r.end.y - S7_LOW), false])
			out.append(["WandRechts", Rect2(S7_RIGHT_WALL, r.position.y, r.end.x - S7_RIGHT_WALL, ROOM_H), false])
		&"S8":
			out.append(["Vloer", Rect2(ARENA_WALL_L, ARENA_FLOOR, ARENA_W, r.end.y - ARENA_FLOOR), false])
			out.append(["MuurRechts", Rect2(ARENA_WALL_R, S7_LOW, r.end.x - ARENA_WALL_R, r.end.y - S7_LOW), false])
			out.append(["DeurLinks", ARENA_DOOR_L, false])
			out.append(["DeurRechts", ARENA_DOOR_R, false])
		&"S9":
			var z := keerzone(d)
			# Plafond met twee gaten: de schacht naar het snelluik en de trap.
			out.append(["Plafond", Rect2(0, r.position.y - 20, S9_SHAFT_LEFT, 20), false])
			out.append(["Plafond2", Rect2(S9_SHAFT_RIGHT, r.position.y - 20, S9_TRAP_LEFT - S9_SHAFT_RIGHT, 20), false])
			out.append(["WandLinks", Rect2(0, r.position.y, S9_WALL, ROOM_H), false])
			# De deur: de vloer van de arena loopt door tot onder de kademuur
			# (40 px eronder, zodat de hoek geen naad heeft).
			out.append(["Deurvloer", Rect2(S9_STEP_X - 40.0, S9_DOOR_FLOOR, r.end.x - S9_STEP_X + 40.0, r.end.y - S9_DOOR_FLOOR), false])
			out.append(["TrapWandLinks", Rect2(S9_TRAP_LEFT - 10.0, r.position.y, 10, S9_TRAP_WALL_BOTTOM - r.position.y), false])
			out.append(["TrapWandRechts", Rect2(S9_TRAP_RIGHT, r.position.y, r.end.x - S9_TRAP_RIGHT, S9_TRAP_WALL_BOTTOM - r.position.y), false])
			for tr: Array in s9_trap_treads():
				if tr[0] >= r.position.y:
					out.append(["Trap9_%d" % int(tr[0]), Rect2(tr[1], tr[0], S9_TRAP_W, ONE_WAY_T), true])
			out.append(["Hoogwater", S9_HOOGWATER, false])
			# De lage kade (635) van de kademuur tot de plaat, de plaat met het
			# luik tot de kadewand, en daaronder de benedenkade (700).
			out.append(["Kade", Rect2(S9_PLAAT_END, S9_KADE, S9_STEP_X - S9_PLAAT_END, r.end.y - S9_KADE), false])
			out.append(["Plaat", Rect2(S9_LUIK.end.x, S9_KADE, S9_PLAAT_END - S9_LUIK.end.x, 16), false])
			out.append(["Plaat2", Rect2(S9_KADEWAND.end.x, S9_KADE, S9_LUIK.position.x - S9_KADEWAND.end.x, 16), false])
			out.append(["Kadewand", S9_KADEWAND, false])
			# De brugpijler (B2): de pijler, de wand rechts (je loopt eronder door
			# de schacht in), richel 1 tegen de wand, richel 2 tegen de pijler.
			var w := b2_ledge(d)
			out.append(["Pijler", S9_PIJLER, false])
			out.append(["PijlerWand", Rect2(S9_B2_RIGHT, r.position.y, 20, S9_B2_LEVELS[1] + ONE_WAY_T - r.position.y), false])
			out.append(["PijlerRichel1", Rect2(S9_B2_RIGHT - w, S9_B2_LEVELS[1], w, ONE_WAY_T), true])
			out.append(["PijlerRichel2", Rect2(S9_B2_LEFT, S9_B2_LEVELS[2], w, ONE_WAY_T), true])
			for tp: Dictionary in turn_points(d).slice(9, 11):
				var prefix: String = String(tp["name"]).trim_prefix("S9-")
				out.append_array(_treads(prefix, tp["wall"], -float(tp["side"]), tp["floor"], d))
			out.append(["Benedenkade", Rect2(S9_WALL, S9_LAAG, S9_PLAAT_END - S9_WALL, r.end.y - S9_LAAG), false])
			# B1 tegen de grachtwand en de galerij tot de schacht.
			out.append(["Galerij", Rect2(S9_WALL + z, S9_UP, S9_SHAFT_LEFT - S9_WALL - z, ONE_WAY_T), true])
			out.append_array(_treads("B1", S9_WALL, 1.0, S9_LAAG, d))
			for y: float in S9_SHAFT:
				out.append(["Schacht%d" % int(y), Rect2(S9_SHAFT_LEFT, y, S9_SHAFT_RIGHT - S9_SHAFT_LEFT, ONE_WAY_T), true])
	return out


## Langzame lijn bij een keerpunt (gdd §4.3, W-8): eenrichtingstreden op 30,
## 60 en 90 px boven `floor` tegen de keerwand `wall`, in richting `away`
## (+1 = naar rechts). De trede op 90 hangt van D af (`tread_90_width`).
static func _treads(prefix: String, wall: float, away: float, floor_y: float, d: int) -> Array:
	var out: Array = []
	for h: float in [30.0, 60.0, 90.0]:
		var w := tread_90_width(d) if h == 90.0 else TREAD_W
		var x0 := wall if away > 0.0 else wall - w
		out.append(["%sTrede%d" % [prefix, int(h)], Rect2(x0, floor_y - h, w, ONE_WAY_T), true])
	return out
