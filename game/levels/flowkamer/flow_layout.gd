extends RefCounted
## Geometrie van de grijze flow-kamer (gdd §4.2–§4.4, T16b #77; na F0: gdd
## §4.7, T16d #176).
##
## Drie kamers in één scène, in een lus K1 → K2 → K3 → K1:
##
##   y=0   +-----------+-------------------------------+---------------+
##         | B2 zigzag |  bovenroute ---------------->  | K2 Merk-arena |
##         | (schacht) |                               |  (640 × 360)  |
##         | B1 keren  |  (massief)                    |          gat  |
##   y=360 | B3 lus    |                  B4 kloof     +---------------+-----+
##         | <-omkeer- |  <------------- startgang <---| K3 Gemaal (960 × 360) |
##   y=720 +-----------+-------------------------------+---------------------+
##
## De route: start rechtsonder in K1, naar links door B4 en de startgang (40 px
## lager dan B4, onder de kom van B3 door); links één opstap van 40 px die je
## omkeert (de enige keer zonder echo: K1 begint naar links en eindigt naar
## rechts, en de zes keerpunten met de echo, B3 + B1 + 4 × B2, keren je een
## even aantal keer). Dan B3 naar rechts, B1 naar links tegen de linkerwand,
## B2 in een schacht recht boven B1, de bovenroute naar K2, het gat rechts in
## K2 naar K3, de sluis in K3 terug naar K1. Alle maten zijn wereldpixels, y
## naar beneden; vloer = bovenkant van een blok. De maten van de bouwstenen
## komen uit gdd §4.3; waar de gdd een keuze laat, staat de keuze hier en in
## `docs/design/kamers/flowkamer.md`.
##
## **Keerzone** (gdd §4.3, W-1, W-2): bij elk keerpunt van B1 en B2 ligt
## binnen 120 px van de keerwand niets landbaars lager dan 120 px boven de
## vloer, behalve de treden van de langzame lijn (45 en 90 px tegen de wand).
## De weg omhoog begint op 120 px. Twee toevoegingen van de WLD (afwijking,
## gemeld in de review): een **overhang** (30 px breed, 85–129 px boven de
## vloer, 40–70 px van de wand) tussen de treden en de weg omhoog, zodat je van
## de treden alleen naar de richel op 135 px kunt (anders haal je met sprong +
## dash van de trede op 45 px de weg omhoog, even snel als keren), en een
## **dicht stuk** van 215 px aan de wandkant van elke richel van B2 (niet van
## onder door te springen), zodat je vanaf de richel op 135 px niet naar de
## richel twee hoger springt (anders sla je een verdieping over).
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
const TREAD_T := 4.0        ## dikte van de B3-trede en de opstap (je loopt eronder door)

## Vloeren (bovenkant).
const FLOOR := 610.0        ## B4 en vloer K3; ook de kom van B3 en de opstap
const STARTGANG := 650.0    ## startgang, 40 px lager: onder de kom van B3 door
const KLOOF_BOTTOM := 700.0 ## B4: 90 px lager dan de vloer
const LEVEL_540 := 540.0    ## B3-galerij (70) = gang van B1
const LEVEL_450 := 450.0    ## B1-galerij (90) = vloer van de schacht B2
const LEDGES := [360.0, 270.0, 180.0, 90.0]  ## B2: 90, 180, 270, 360 boven de schachtvloer
const TOP := 90.0           ## bovenroute = richel 4
const K2_FLOOR := 340.0
const K2_PLATFORM := 270.0  ## 70 px (gdd §4.2)

## B4 lanceerkloof: van rand tot rand 160 px; aan de overkant 40 px vloer op
## FLOOR, dan een stap van 40 px omlaag naar de startgang.
const B4_NEAR_EDGE := 1350.0
const B4_FAR_EDGE := 1190.0
const B4_SHELF_LEFT := 1150.0
## Opstap (omkeren): eenrichtingsrichel op FLOOR boven de startgang, van de
## linkerwand tot de ingang van B3. Je springt erop en loopt naar rechts.
const OPSTAP := Rect2(20, FLOOR, 280, TREAD_T)
## B3 lus: kom van 190 px; ingang links, blok rechts tegen de wand.
const B3_ENTRANCE := 300.0
const B3_BLOCK_LEFT := 490.0
const B3_GALLERY_TIP := 340.0
const B3_WALL_RIGHT := 640.0
## Kolom van B1 en B2: linkerwand (keerwand van B1) en rechterwand van de
## schacht (480 px).
const COLUMN_LEFT := 20.0
const COLUMN_RIGHT := 500.0
const SHAFT_LEFT := COLUMN_LEFT
const SHAFT_RIGHT := COLUMN_RIGHT
## Keerzone en langzame lijn (gdd §4.3, W-1, W-2); afstanden vanaf de keerwand.
const KEERZONE := 120.0
const TREAD_W := 40.0
const OVERHANG_FROM := 40.0
const OVERHANG_TO := 70.0
const OVERHANG_LOW := 85.0   ## onderkant boven de vloer (een sprong vanaf de vloer haalt met het lichaam 80)
const LEDGE135_LEN := 150.0
const LEDGE_LEN := 360.0
## Dicht stuk aan de wandkant van elke richel (zie boven).
const LEDGE_SOLID := 215.0
## Massief rechts van de schacht; plafond van de startgang.
const MASSIEF_RIGHT := 1150.0
const STARTGANG_CEILING := 550.0
## Galerij en treden van B1 liggen in de kolom; de onderkant van de schacht.
const SHAFT_BOTTOM := LEVEL_450 + ONE_WAY_T
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

## Vijanden in K2 (x op de vloer), na F0 in **paren** (gdd §4.2, §4.7.1 (c),
## W-3): twee basisvijanden 28 px uit elkaar (≤ 32: één merk raakt ze
## allebei; ≤ 48 = K: L-13 (d)), paren ≥ 160 px uit elkaar
## (gemeten tussen de naaste vijanden). Golf 1: drie paren over de arena;
## golf 2: drie paren vanaf de ingang (links), met het
## pantserdoel tussen de eerste twee. Bij een terugkeer komen de
## basisvijanden van golf 2 terug. Waarom 3 + 3 paren: met 2 + 2 haalt de
## gescripte run 97 LP na K1 + K2 (doel ≥ 100, gdd §4.2: eerst de aantallen
## bijstellen), met 3 + 2 duurt de run zonder echo bij D = 180 6895 ticks
## (twee terugkeren; de runner geeft een test 7200 frames), met 3 + 3 is één
## terugkeer genoeg (zie `docs/design/kamers/flowkamer.md` §4).
const PAIR_GAP := 28.0
const WAVE_1_PAIRS := [[1560.0, 1588.0], [1750.0, 1778.0], [1940.0, 1968.0]]
const WAVE_2_PAIRS := [[1470.0, 1498.0], [1660.0, 1688.0], [1850.0, 1878.0]]
const WAVE_1 := [1560.0, 1588.0, 1750.0, 1778.0, 1940.0, 1968.0]
const WAVE_2 := [1470.0, 1498.0, 1660.0, 1688.0, 1850.0, 1878.0]
const ARMORED_X := 1579.0


## Een keerpunt van B1 of B2: de keerwand (x van het wandvlak), de vloer (y),
## de kant van de wand (-1 = links, 1 = rechts) en het niveau van de weg omhoog.
## Volgorde: B1, B2-0 … B2-3 (de route).
static func turn_points() -> Array:
	var out: Array = []
	out.append({"name": "B1", "wall": COLUMN_LEFT, "floor": LEVEL_540, "side": -1, "up": LEVEL_450})
	var floors := [LEVEL_450, LEDGES[0], LEDGES[1], LEDGES[2]]
	for i in floors.size():
		var right := i % 2 == 0
		out.append({"name": "B2-%d" % i, "wall": COLUMN_RIGHT if right else COLUMN_LEFT,
			"floor": floors[i], "side": 1 if right else -1, "up": LEDGES[i]})
	return out


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
	# --- K1, beneden: startgang, B4 ---
	out.append(["Vloer", Rect2(20, STARTGANG, B4_SHELF_LEFT - 20, 720 - STARTGANG), false])
	out.append(["B4Overkant", Rect2(B4_SHELF_LEFT, FLOOR, B4_FAR_EDGE - B4_SHELF_LEFT, 720 - FLOOR), false])
	# B4: kloof van 160 px, 90 diep; twee treden van 45 tegen de overkant.
	out.append(["B4Bodem", Rect2(B4_FAR_EDGE, KLOOF_BOTTOM, B4_NEAR_EDGE - B4_FAR_EDGE, 720 - KLOOF_BOTTOM), false])
	out.append(["B4Trede", Rect2(B4_FAR_EDGE, KLOOF_BOTTOM - 45, TREAD_W, 45), false])
	out.append(["B4Aanloop", Rect2(B4_NEAR_EDGE, FLOOR, K1.end.x - B4_NEAR_EDGE, 720 - FLOOR), false])
	out.append(["StartgangPlafond", Rect2(B3_WALL_RIGHT, SHAFT_BOTTOM, MASSIEF_RIGHT - B3_WALL_RIGHT, STARTGANG_CEILING - SHAFT_BOTTOM), false])
	# --- K1, omkeren en B3 (kom op FLOOR, boven de startgang) ---
	out.append(["Opstap", OPSTAP, true])
	out.append(["B3Kom", Rect2(B3_ENTRANCE, FLOOR, B3_BLOCK_LEFT - B3_ENTRANCE, TREAD_T), false])
	out.append(["B3Blok", Rect2(B3_BLOCK_LEFT, FLOOR - 45, b, 45), false])
	out.append(["B3Wand", Rect2(B3_BLOCK_LEFT + b, SHAFT_BOTTOM, B3_WALL_RIGHT - B3_BLOCK_LEFT - b, FLOOR - SHAFT_BOTTOM), false])
	out.append(["B3Trede", Rect2(B3_GALLERY_TIP, FLOOR - 35, TREAD_W, TREAD_T), true])
	# --- K1, B1: gang op 540 (= B3-galerij) tot de linkerwand ---
	out.append(["Gang540", Rect2(COLUMN_LEFT, LEVEL_540, B3_GALLERY_TIP - COLUMN_LEFT, ONE_WAY_T), true])
	# --- K1, B2: schacht boven B1; de vloer is de galerij van B1 ---
	out.append(["B1Galerij", Rect2(COLUMN_LEFT + KEERZONE, LEVEL_450, COLUMN_RIGHT - COLUMN_LEFT - KEERZONE, ONE_WAY_T), true])
	for i in LEDGES.size():
		var y: float = LEDGES[i]
		var attached_left := i % 2 == 0
		if attached_left:
			out.append(["Richel%d_dicht" % (i + 1), Rect2(COLUMN_LEFT, y, LEDGE_SOLID, ONE_WAY_T), false])
			out.append(["Richel%d" % (i + 1), Rect2(COLUMN_LEFT + LEDGE_SOLID, y, LEDGE_LEN - LEDGE_SOLID, ONE_WAY_T), true])
		else:
			out.append(["Richel%d" % (i + 1), Rect2(COLUMN_RIGHT - LEDGE_LEN, y, LEDGE_LEN - LEDGE_SOLID, ONE_WAY_T), true])
			out.append(["Richel%d_dicht" % (i + 1), Rect2(COLUMN_RIGHT - LEDGE_SOLID, y, LEDGE_SOLID, ONE_WAY_T), false])
	# Langzame lijn bij elk keerpunt: treden op 45 en 90 tegen de keerwand,
	# de overhang, en de richel op 135 over de keerzone. De treden zijn
	# eenrichtingsrichels: je loopt eronder door tot de wand (het keerpunt).
	for tp: Dictionary in turn_points():
		var n: String = tp["name"].replace("-", "")
		var wall: float = tp["wall"]
		var y: float = tp["floor"]
		var away := -float(tp["side"])  # richting van de wand af
		out.append(["%sTrede45" % n, _strip(wall, away, 0.0, TREAD_W, y - 45.0, ONE_WAY_T), true])
		out.append(["%sTrede90" % n, _strip(wall, away, 0.0, TREAD_W, y - 90.0, ONE_WAY_T), true])
		out.append(["%sOverhang" % n, _strip(wall, away, OVERHANG_FROM, OVERHANG_TO, y - 135.0 + ONE_WAY_T,
			135.0 - ONE_WAY_T - OVERHANG_LOW), false])
		out.append(["%sRichel135" % n, _strip(wall, away, 0.0, LEDGE135_LEN, y - 135.0, ONE_WAY_T), true])
	# Rechterwand van de schacht, massief erachter, bovenroute (richel 4 loopt erin over).
	out.append(["Massief", Rect2(COLUMN_RIGHT, TOP, MASSIEF_RIGHT - COLUMN_RIGHT, SHAFT_BOTTOM - TOP), false])
	out.append(["Bovenroute", Rect2(MASSIEF_RIGHT, TOP, K1.end.x - MASSIEF_RIGHT, 10), false])
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


## Strook van `from` tot `to` px vanaf het wandvlak `wall`, in richting `away`.
static func _strip(wall: float, away: float, from: float, to: float, y: float, h: float) -> Rect2:
	var x0 := wall + away * from
	var x1 := wall + away * to
	return Rect2(minf(x0, x1), y, absf(x1 - x0), h)
