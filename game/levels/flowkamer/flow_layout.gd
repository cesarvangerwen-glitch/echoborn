extends RefCounted
## Geometrie van de grijze flow-kamer (gdd §4.2–§4.4, T16b #77).
##
## Drie kamers in één scène, in een lus K1 → K2 → K3 → K1:
##
##   y=0   +-------------------------------------------+---------------+
##         | K1 Sprongketen (1440 × 720)               | K2 Merk-arena |
##         |   B2 zigzag (schacht) ----> bovenroute -->|  (640 × 360)  |
##         |   B1 keren-opstap                         |          gat  |
##   y=360 |   B3 lus (links)          B4 lanceerkloof +---------------+-----+
##         |   <--- startgang <--------------------- <| K3 Gemaal (960 × 360) |
##   y=720 +-------------------------------------------+---------------------+
##
## De route: start rechtsonder in K1, naar links door B4 en de startgang,
## B3 keert je om, B1 en B2 brengen je 450 px omhoog, de bovenroute leidt
## naar K2, het gat rechts in K2 naar K3, de sluis in K3 terug naar K1.
## Alle maten zijn wereldpixels, y naar beneden; vloer = bovenkant van een
## blok. De maten van de bouwstenen komen uit gdd §4.3; waar de gdd een
## keuze laat, staat de keuze hier en in `docs/design/kamers/flowkamer.md`.
##
## Alle geometrie is laag 1 (wereld). Er is geen schaduwgeometrie, geen
## FelLicht en geen Schaduwgevaar (FK-4).

const K1 := Rect2(0, 0, 1440, 720)
const K2 := Rect2(1440, 0, 640, 360)
const K3 := Rect2(1440, 360, 960, 360)
const ROOMS := {"K1": K1, "K2": K2, "K3": K3}
## Buren (E-04a, FK-3): elke kamer is buur van de twee andere.
const NEIGHBOURS := {"K1": ["K2", "K3"], "K2": ["K1", "K3"], "K3": ["K1", "K2"]}

## Lichaam 16 × 30: het middelpunt staat 15 px boven de vloer.
const HALF_H := 15.0
const ONE_WAY_T := 6.0      ## dikte van een eenrichtingsrichel
const TREAD_T := 4.0        ## dikte van de B3-trede (P1 loopt eronder door)

## Vloeren (bovenkant).
const FLOOR := 610.0        ## benedenvloer K1 en vloer K3
const KLOOF_BOTTOM := 700.0 ## B4: 90 px lager
const LEVEL_540 := 540.0    ## B3-galerij (70) = gang van B1
const LEVEL_450 := 450.0    ## B1-galerij (90) = vloer van de schacht B2
const LEDGES := [360.0, 270.0, 180.0, 90.0]  ## B2: 90, 180, 270, 360 boven de schachtvloer
const TOP := 90.0           ## bovenroute = richel 4
const K2_FLOOR := 340.0
const K2_PLATFORM := 270.0  ## 70 px (gdd §4.2)

## B4 lanceerkloof: van rand tot rand 160 px.
const B4_NEAR_EDGE := 1350.0
const B4_FAR_EDGE := 1190.0
## B3 lus: kom van 190 px; het blok staat links tegen de wand.
const B3_BLOCK_RIGHT := 140.0
const B3_ENTRANCE := 330.0
const B3_GALLERY_TIP := 290.0
## B1: wand (met trede) rechts in de gang op 540.
const B1_WALL := 650.0
## B2: schacht van 480 px breed.
const SHAFT_LEFT := 650.0
const SHAFT_RIGHT := 1130.0
const SHAFT_GAP := 64.0
const TREAD_W := 40.0
## K2.
const K2_HOLE := Rect2(2000, 340, 60, 10)
const K2_LEFT := 1450.0
const K2_RIGHT := 2060.0
## K3: sluis links, straat met Diepwater, oever met pomprad rechts.
const SLUICE := Rect2(1440, 360, 20, 250)
const STREET := Rect2(1470, 570, 330, 40)   ## Diepwater bij hoog water: waterlijn 570
const WATER_HIGH := 570.0
const WATER_LOW := 610.0
const POMPRAD_AT := Vector2(1960, FLOOR - 30.0)  ## middelpunt 30 px boven de vloer (FK-5: 15–40)
## Trap terug naar K2 (K3 → K2 zonder sluis): vijf eenrichtingsrichels.
const STAIRS := [
	Rect2(2320, 565, 60, ONE_WAY_T),
	Rect2(2250, 520, 60, ONE_WAY_T),
	Rect2(2170, 475, 60, ONE_WAY_T),
	Rect2(2090, 430, 60, ONE_WAY_T),
	Rect2(2000, 385, 70, ONE_WAY_T),
]

## Start van de run en van elke kamer (respawn, LM-05).
const RUN_START := Vector2(1420, FLOOR - HALF_H)
const ROOM_START := {
	"K1": Vector2(1420, FLOOR - HALF_H),
	"K2": Vector2(1470, K2_FLOOR - HALF_H),
	"K3": Vector2(2030, FLOOR - HALF_H),
}

## Vijanden in K2 (x op de vloer). gdd §4.2 noemt 3 per golf; met 3 haalt de
## scripted run 92 LP na K1 + K2 (doel ≥ 100). Daarom 4 basisvijanden in
## golf 1 en 5 in golf 2 (gdd §4.2: eerst de aantallen bijstellen, niet de
## LP-waarden; de vijfde geeft marge sinds de vang in B3, Lead-review PR #112).
## Sinds golf 2 start zodra golf 1 gemerkt is (G-3, #177) knallen meer vijanden
## samen; een zesde in golf 2, bij de ingang, houdt D = 180 op ≥ 100 LP.
## Werkaanname tot de paren van W-3 (#176).
## Golf 2 heeft er ook het pantserdoel bij. Bij een terugkeer komen de
## basisvijanden van golf 2 terug.
const WAVE_1 := [1600.0, 1720.0, 1840.0, 1940.0]
const WAVE_2 := [1500.0, 1580.0, 1640.0, 1700.0, 1820.0, 1940.0]
const ARMORED_X := 1840.0


## Breedte van de bovenkant van het B3-blok bij staart D (gdd §4.3: B = D − 60).
static func b3_width(d: int) -> float:
	return float(d - 60)


## Kamer waarin `at` ligt (E-04e: het middelpunt telt).
static func room_of(at: Vector2) -> String:
	if at.x >= K2.position.x:
		return "K2" if at.y < K2.end.y else "K3"
	return "K1"


## Alle blokken als [naam, rect, eenrichting]. Het B3-blok en de wand erachter
## hangen af van D (`b3_width`); de rest is vast.
static func blocks(d: int) -> Array:
	var b := b3_width(d)
	var out: Array = []
	# Rand van de hele scène.
	out.append(["Plafond", Rect2(0, -20, 2400, 20), false])
	out.append(["WandLinks", Rect2(0, 0, 20, 720), false])
	out.append(["WandRechtsK3", Rect2(2380, 360, 20, 360), false])
	out.append(["Bodem", Rect2(0, 720, 2400, 20), false])
	# --- K1, benedenvloer ---
	if B3_BLOCK_RIGHT - b > 20.0:  # bij D = 180 staat het blok direct tegen de buitenwand
		out.append(["B3Wand", Rect2(20, 0, B3_BLOCK_RIGHT - b - 20, FLOOR), false])
	out.append(["B3Blok", Rect2(B3_BLOCK_RIGHT - b, FLOOR - 45, b, 45), false])
	out.append(["Vloer", Rect2(20, FLOOR, B4_FAR_EDGE - 20, 720 - FLOOR), false])
	out.append(["B3Trede", Rect2(B3_GALLERY_TIP - TREAD_W, FLOOR - 35, TREAD_W, TREAD_T), true])
	# B4: kloof van 160 px, 90 diep; twee treden van 45 tegen de overkant.
	out.append(["B4Bodem", Rect2(B4_FAR_EDGE, KLOOF_BOTTOM, B4_NEAR_EDGE - B4_FAR_EDGE, 720 - KLOOF_BOTTOM), false])
	out.append(["B4Trede", Rect2(B4_FAR_EDGE, KLOOF_BOTTOM - 45, TREAD_W, 45), false])
	out.append(["B4Aanloop", Rect2(B4_NEAR_EDGE, FLOOR, K1.end.x - B4_NEAR_EDGE, 720 - FLOOR), false])
	# --- K1, niveau 540: B3-galerij en gang van B1 ---
	out.append(["Gang540", Rect2(B3_GALLERY_TIP, LEVEL_540, B1_WALL - B3_GALLERY_TIP, ONE_WAY_T), true])
	# Treden van de langzame lijn (B1, B2) zijn eenrichtingsrichels op 45 px:
	# P1 loopt eronder door tot de wand, zodat het keerpunt van de echolijn de
	# wand blijft (de maten van gdd §4.3 rekenen vanaf de wand).
	out.append(["B1Trede", Rect2(B1_WALL - TREAD_W, LEVEL_540 - 45, TREAD_W, ONE_WAY_T), true])
	out.append(["B1Galerij", Rect2(B3_ENTRANCE, LEVEL_450, B1_WALL - B3_ENTRANCE, ONE_WAY_T), true])
	# B1-wand + schachtvloer: één massief blok; de onderkant is het plafond van de startgang.
	out.append(["SchachtVloer", Rect2(B1_WALL, LEVEL_450, SHAFT_RIGHT + 20 - B1_WALL, 100), false])
	# --- K1, schacht B2 ---
	out.append(["SchachtWandL", Rect2(SHAFT_LEFT - 20, 0, 20, LEDGES[0]), false])
	out.append(["SchachtWandR", Rect2(SHAFT_RIGHT, TOP + 10, 20, LEVEL_450 - TOP - 10), false])
	for i in LEDGES.size():
		var y: float = LEDGES[i]
		var attached_left := i % 2 == 0
		var x := SHAFT_LEFT if attached_left else SHAFT_LEFT + SHAFT_GAP
		out.append(["Richel%d" % (i + 1), Rect2(x, y, SHAFT_RIGHT - SHAFT_LEFT - SHAFT_GAP, ONE_WAY_T), true])
	# Treden van de langzame lijn: op elke verdieping tegen de keerwand.
	var floors := [LEVEL_450, LEDGES[0], LEDGES[1], LEDGES[2]]
	for i in floors.size():
		var at_right := i % 2 == 0
		var tx := SHAFT_RIGHT - TREAD_W if at_right else SHAFT_LEFT
		out.append(["SchachtTrede%d" % i, Rect2(tx, floors[i] - 45, TREAD_W, ONE_WAY_T), true])
	# Bovenroute (richel 4 loopt erin over).
	out.append(["Bovenroute", Rect2(SHAFT_RIGHT, TOP, K1.end.x - SHAFT_RIGHT, 10), false])
	# --- K2 ---
	out.append(["K2WandL", Rect2(K1.end.x, TOP + 10, 10, K2.end.y - TOP - 10), false])
	out.append(["K2Vloer", Rect2(K1.end.x, K2_FLOOR, K2_HOLE.position.x - K1.end.x, 10), false])
	out.append(["K2WandR", Rect2(K2_RIGHT, 0, 20, K2_FLOOR + 10), false])
	out.append(["K2Platform1", Rect2(1560, K2_PLATFORM, 120, ONE_WAY_T), true])
	out.append(["K2Platform2", Rect2(1820, K2_PLATFORM, 120, ONE_WAY_T), true])
	# Plafond van K3 rechts van K2.
	out.append(["K3Plafond", Rect2(K2.end.x, K2_FLOOR, K3.end.x - K2.end.x, 10), false])
	# --- K3 ---
	out.append(["K3Vloer", Rect2(K1.end.x, FLOOR, K3.end.x - K1.end.x, 720 - FLOOR), false])
	for i in STAIRS.size():
		out.append(["Trap%d" % (i + 1), STAIRS[i], true])
	return out
