extends RefCounted
## Geometrie van de Kadewijk, deel 1: S1–S4 als grijze blokken (T8a, #83;
## `docs/design/wereld.md` §2.2, gdd v0.8.1 §4.3 en §4.8.5;
## `docs/design/kamers/kadewijk.md`).
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
## alle vier op `s = 0`; de waterstand bestaat nog niet (GP, zie kamerdoc).

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
}
## Buren (E-04a): op een rij. S4–S5 en S9–S1 (de lus, L-14f) komen met deel 2.
const NEIGHBOURS := {
	&"S1": [&"S2"],
	&"S2": [&"S1", &"S3"],
	&"S3": [&"S2", &"S4"],
	&"S4": [&"S3"],
}
const ORDER := [&"S1", &"S2", &"S3", &"S4"]
const AREA_RIGHT := 3520.0

## --- S1 Kade-ingang: B1 tegen de linkerwand (gracht) ---
const S1_WALL := 20.0
const S1_FLOOR := 320.0
const S1_UP := 230.0             ## galerij op 90 = de kade naar S2
const S1_QUAY_LEFT := 500.0      ## 480 px van de wand: einde van de galerij, begin van de kademuur

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
const S4_END_WALL := 3500.0
## Einde van deel 1: wie hier is, haalde S1–S4 (RUN_EIND in het meetlog).
const END_X := 3440.0

## Begin van elke kamer (LM-05, LM-08: vaste, veilige plek; ook het debugmenu).
const ROOM_START := {
	&"S1": Vector2(440, S1_FLOOR - HALF_H),
	&"S2": Vector2(660, S2_FLOOR - HALF_H),
	&"S3": Vector2(1620, S2_TOP - HALF_H),
	&"S4": Vector2(2580, S4_FLOOR - HALF_H),
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


## De keerpunten van deel 1 (B1 en B3), voor de bot en de tests.
## `wall` = x van het keervlak, `side` = kant van de wand (-1 = links van P1).
static func turn_points(d: int) -> Array:
	return [
		{"name": "S1-B1", "wall": S1_WALL, "floor": S1_FLOOR, "side": -1, "up": S1_UP},
		{"name": "S2-B3", "wall": B3_BLOCK_LEFT + b3_width(d), "floor": S2_FLOOR, "side": 1, "up": S2_MID},
		{"name": "S2-B1", "wall": S2_PIJLER, "floor": S2_MID, "side": -1, "up": S2_TOP},
	]


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
	out.append(["Plafond", Rect2(r.position.x, -20, r.size.x, 20), false])
	match id:
		&"S1":
			var z := keerzone(d)
			out.append(["WandLinks", Rect2(0, 0, S1_WALL, ROOM_H), false])
			out.append(["Gang", Rect2(S1_WALL, S1_FLOOR, S1_QUAY_LEFT - S1_WALL, ROOM_H - S1_FLOOR), false])
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
			out.append(["Overkant", Rect2(B4_FAR_EDGE, S4_FLOOR, S4_END_WALL - B4_FAR_EDGE, ROOM_H - S4_FLOOR), false])
			# Einde van deel 1: dicht tot S5 er is (deel 2).
			out.append(["EindWand", Rect2(S4_END_WALL, 0, r.end.x - S4_END_WALL, ROOM_H), false])
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
