extends RefCounted
## Tests voor de flow-kamer na F0 (T16d, #176; gdd §4.7.4 W-1–W-4) en op
## D = 60 (T16f, #189; gdd v0.8 §4.8.4 W-8).
##
## - **Geometrie** (W-1, W-2, W-8; gdd §4.3 *Keerzone*, FK-6, L-08 voor zover
##   de geometrie): bij elk keerpunt van B1 en B2 de keerwand, D + 24 px vlakke
##   vloer, niets landbaars binnen Z = D + 30 = 90 px van de wand lager dan
##   120 px boven de vloer behalve de treden (30, 60, 90), geen overhang, de
##   weg omhoog van 90 tot ≥ 240 px op 70–100 px, de richel op 135, en de
##   landing na de bounce per D.
## - **K2 in paren** (W-3, L-13 (d)): per golf paren die ≤ 32 px uit elkaar
##   beginnen, paren ≥ 160 px uit elkaar, golf 2 aan de kant van de ingang,
##   het pantserdoel in golf 2.
## - **Keren** (L-08 (c), headless per D): de gescripte geoefende run haalt bij
##   elk keerpunt de weg omhoog via de echo, zonder stilstand van 20 ticks of
##   langer vóór de landing (MP-3 per keerpunt). Bij D = 60 (W-8): de landing
##   ≥ 9 px voorbij de rand, en de snelste langzame lijn zonder dash van
##   dezelfde bot met echo uit is ≥ 30 ticks trager dan keren en ≤ 2× (FK-2);
##   met een dash op 4 … 24 ticks na de afzet ≥ 20 ticks trager en ≤ 2× (W-12,
##   gdd v0.8.2 §4.8.7; bij 90, 120 en 180 rapporteren). Bij 90 en 120
##   (regressie) is keren sneller en de langzame lijn ≤ 2×; bij 180 ≤ 2× en
##   een ondergrens: de langzame lijn hooguit 32 ticks sneller dan keren en
##   ≥ 100 ticks (de kamer is op D = 60 gebouwd: `flowkamer.md` §12).
##
## - **K3 pompgang** (W-4; gdd §4.2, FK-5): vier schoepen, 80 px, 15–40 px
##   boven de vloer, ≥ 280 px droge vloer naar de sluis, de trap terug naar K2.
##
## FK-2 met echo uit (≤ 4 terugkeren, ≤ 2× de run) en de LM-04-run door K3
## staan in `test_flowkamer.gd`; de wachtbot, de late bot en het afzetvenster
## in `test_wachtbot.gd`.

const FlowRoom = preload("res://levels/flowkamer/flow_room.gd")
const FlowBot = preload("res://levels/flowkamer/flow_bot.gd")
const FlowReport = preload("res://levels/flowkamer/flow_report.gd")
const Layout = preload("res://levels/flowkamer/flow_layout.gd")
const SlowDash = preload("res://tests/slow_dash_input.gd")

const TICK_CAP := 7000
const DS := [60, 90, 120, 180]
## De D waarop de kamer gebouwd is (CEO-besluit 2026-11-12; gdd v0.8 §4.8.4):
## daar gelden de eisen van W-8; 90, 120 en 180 draaien als regressie.
const BUILT_D := 60
## Tijd van keren tot het volgende niveau per keerpunt, met echo, per D.
static var _turn_ticks := {}
## W-12: dash `n` ticks na de afzet van de sprong naar de weg omhoog (gdd §4.6).
const DASH_NS := [4, 8, 12, 16, 20, 24]
## W-12: zeven runs (zonder dash en zes dash-momenten) tot na B2-3, echo uit.
const MAX_FRAMES := {
	"test_turns_slow_line_with_dash_d60": 30000,
	"test_turns_slow_line_with_dash_d90": 30000,
	"test_turns_slow_line_with_dash_d120": 30000,
	"test_turns_slow_line_with_dash_d180": 30000,
}


# --- Geometrie --------------------------------------------------------------

## Een blok met een bovenvlak waarop P1 kan landen in x-bereik [x0, x1] en
## hoogte strikt tussen `y_hi` en `y_lo` (y naar beneden). Wanden en
## eenrichtingsrichels tellen allebei: van boven land je op allebei.
func _landable(blocks: Array, x0: float, x1: float, y_hi: float, y_lo: float) -> Array:
	var out: Array = []
	for spec: Array in blocks:
		var r: Rect2 = spec[1]
		var top := r.position.y
		if top > y_hi and top < y_lo and r.position.x < x1 and r.end.x > x0:
			out.append(spec[0])
	return out


## Lengte die de bovenvlakken op hoogte `y` afdekken in [x0, x1].
func _covered(blocks: Array, y: float, x0: float, x1: float) -> float:
	var spans: Array = []
	for spec: Array in blocks:
		var r: Rect2 = spec[1]
		if is_equal_approx(r.position.y, y) and r.position.x < x1 and r.end.x > x0:
			spans.append([maxf(r.position.x, x0), minf(r.end.x, x1)])
	spans.sort_custom(func(a: Array, b: Array) -> bool: return a[0] < b[0])
	var total := 0.0
	var reach := x0
	for s: Array in spans:
		if s[1] > reach:
			total += s[1] - maxf(s[0], reach)
			reach = s[1]
	return total


func _block(blocks: Array, block_name: String) -> Array:
	for spec: Array in blocks:
		if spec[0] == block_name:
			return spec
	return []


## Is er een dichte wand met het vlak op x = `wall` naast hoogte [y0, y1]?
func _wall_at(blocks: Array, wall: float, side: int, y0: float, y1: float) -> bool:
	for spec: Array in blocks:
		var r: Rect2 = spec[1]
		if spec[2]:
			continue
		var face := r.position.x if side > 0 else r.end.x
		if is_equal_approx(face, wall) and r.position.y <= y0 and r.end.y >= y1:
			return true
	return false


## W-1, W-2, W-8: keerzone, weg omhoog, langzame lijn en maten bij elk
## keerpunt. De kamer is op D = 60 gebouwd: Z = D + 30 = 90 px (gdd v0.8
## §4.3, §4.8.4 W-8), geen overhang; bij 90, 120 en 180 dezelfde geometrie
## (alleen het B3-blok volgt D), als regressie.
func test_keerzone_geometry(t) -> void:
	t.check(is_equal_approx(Layout.KEERZONE, 60.0 + 30.0), "Z = %.0f px (W-8: D + 30 = 90 bij D = 60)" % Layout.KEERZONE)
	var z := Layout.KEERZONE
	for d: int in DS:
		var blocks: Array = Layout.blocks(d)
		for tp: Dictionary in Layout.turn_points():
			var n: String = tp["name"]
			var wall: float = tp["wall"]
			var y: float = tp["floor"]
			var side: int = tp["side"]
			var up: float = tp["up"]
			var away := -side
			var tag := "D=%d %s" % [d, n]
			# De keerwand (dicht, minstens een lichaam hoog boven de vloer).
			t.check(_wall_at(blocks, wall, side, y - 30.0, y), "%s: geen keerwand op x = %.0f" % [tag, wall])
			# D + 24 px vlakke vloer vóór de wand (gdd §4.3, Keren).
			var x0 := minf(wall, wall + away * (d + 24.0))
			var x1 := maxf(wall, wall + away * (d + 24.0))
			t.check(_covered(blocks, y, x0, x1) >= d + 24.0 - 0.5, "%s: minder dan D + 24 px vloer vóór de wand" % tag)
			# Keerzone: binnen Z px van de wand (beide kanten) niets landbaars
			# lager dan 120 px boven de vloer, behalve de treden op 30, 60 en 90.
			var hits := _landable(blocks, wall - z, wall + z, y - 120.0, y)
			var short := n.replace("-", "")
			var allowed: Array = []
			for h: float in Layout.TREADS:
				allowed.append("%sTrede%d" % [short, int(h)])
			for h: String in hits:
				t.check(h in allowed, "%s: %s is landbaar in de keerzone" % [tag, h])
			t.check(hits.size() == allowed.size(), "%s: treden van de langzame lijn ontbreken (%s)" % [tag, hits])
			# Weg omhoog: op 70–100 px (FK-6), van Z tot ≥ Z + 150 (en ≥ D + 90) px van de wand.
			t.check(y - up >= 70.0 and y - up <= 100.0, "%s: weg omhoog op %.0f px (FK-6: 70–100)" % [tag, y - up])
			var reach := maxf(z + 150.0, 60.0 + 90.0)
			var w0 := minf(wall + away * z, wall + away * reach)
			var w1 := maxf(wall + away * z, wall + away * reach)
			t.check(_covered(blocks, up, w0, w1) >= reach - z - 0.5, "%s: weg omhoog dekt %.0f–%.0f px niet" % [tag, z, reach])
			var start := minf(wall + away * (z - 1.0), wall + away * (z + 1.0))
			t.check(_covered(blocks, up, start, start + 2.0) < 1.5, "%s: weg omhoog begint niet op %.0f px" % [tag, z])
			# Langzame lijn: treden op 30, 60 en 90 tegen de wand (≤ 45 px per
			# stap, FK-6), richel op 135 over de keerzone.
			var prev := 0.0
			for step: float in Layout.TREADS:
				var tread := _block(blocks, "%sTrede%d" % [short, int(step)])
				t.check(not tread.is_empty() and tread[2] and is_equal_approx((tread[1] as Rect2).position.y, y - step),
					"%s: eenrichtingstrede op %.0f ontbreekt" % [tag, step])
				t.check(step - prev <= 45.0, "%s: trede op %.0f is %.0f px hoger dan de vorige (FK-6: ≤ 45)" % [tag, step, step - prev])
				prev = step
			var ledge := _block(blocks, "%sRichel135" % short)
			t.check(not ledge.is_empty() and is_equal_approx((ledge[1] as Rect2).position.y, y - 135.0)
				and (ledge[1] as Rect2).size.x > z + 16.0, "%s: richel op 135 ontbreekt of is te kort" % tag)
			# Geen overhang (gdd v0.8 §4.8.3 punt 1): tussen de wand en Z is
			# niets dicht van de vloer tot 135 px erboven (daar bounct de echolijn
			# op 40–62 px van de wand).
			var space := Rect2(minf(wall, wall + away * z) + 0.5, y - 135.0 + 0.5, z - 1.0, 135.0 - 1.0)
			for spec: Array in blocks:
				if not spec[2]:
					t.check(not (spec[1] as Rect2).intersects(space), "%s: %s is dicht in de keerzone (overhang)" % [tag, spec[0]])
			# Landing na keren zonder dash (gdd §4.3): bij D = 60 bounce op
			# 40–62 px, landing op ± x_b + 68 = 108–130, voorbij de rand op Z + 8
			# met ≥ 9 px marge; bij D ≥ 90 op D + 68, ≥ 30 px marge.
			if d < 65:
				t.check(40.0 + 68.0 >= z + 8.0 + 9.0 - 0.5, "%s: landing 108 px, rand + marge %.0f" % [tag, z + 17.0])
			else:
				t.check(d + 68.0 >= z + 8.0 + 30.0 - 0.5, "%s: landing %.0f px, rand + marge %.0f" % [tag, d + 68.0, z + 38.0])
		# B2: de landing (≤ D + 88 px van de wand) ligt ≥ D + 24 px van de
		# volgende keerwand (W-2, gdd §4.3 nagerekend per D).
		var shaft := Layout.COLUMN_RIGHT - Layout.COLUMN_LEFT
		t.check(shaft - (d + 88.0) >= d + 24.0, "D=%d: B2 landing %.0f px van de volgende wand (≥ %d)" % [d, shaft - d - 88.0, d + 24])
	# B1 (W-1): gang van 320 px; B2 (W-2, W-8): schacht 480, richels 480 − Z = 390, gat Z.
	var blocks: Array = Layout.blocks(60)
	t.check(is_equal_approx(_covered(blocks, Layout.LEVEL_540, Layout.COLUMN_LEFT, Layout.COLUMN_LEFT + 400.0), 320.0),
		"B1: gang is geen 320 px")
	t.check(is_equal_approx(Layout.COLUMN_RIGHT - Layout.COLUMN_LEFT, 480.0), "B2: schacht is geen 480 px")
	for i in Layout.LEDGES.size():
		var ledge_blocks := blocks.filter(func(spec: Array) -> bool: return str(spec[0]).begins_with("Richel%d" % (i + 1)))
		var len := _covered(ledge_blocks, Layout.LEDGES[i], Layout.COLUMN_LEFT, Layout.COLUMN_RIGHT)
		t.check(is_equal_approx(len, 480.0 - z), "B2: richel %d is %.0f px (480 − Z = %.0f)" % [i + 1, len, 480.0 - z])


## Vanaf de richel op 135 kun je niet naar de richel twee hoger springen: het
## stuk erboven is dicht (geen eenrichting). Anders sla je een verdieping over.
func test_ledge_above_ledge135_is_solid(t) -> void:
	var blocks: Array = Layout.blocks(120)
	for tp: Dictionary in Layout.turn_points():
		var short: String = tp["name"].replace("-", "")
		var ledge: Rect2 = _block(blocks, "%sRichel135" % short)[1]
		var above_y: float = ledge.position.y - 45.0
		for spec: Array in blocks:
			var r: Rect2 = spec[1]
			if is_equal_approx(r.position.y, above_y) and r.position.x < ledge.end.x and r.end.x > ledge.position.x:
				t.check(not spec[2], "%s: %s boven de richel op 135 is eenrichting" % [tp["name"], spec[0]])


# --- K3 pompgang (W-4) -------------------------------------------------------

## W-4 (gdd §4.2, FK-5, LM-04): vier schoepen van 32 × 48 op een vlak stuk
## vloer, 80 px uit elkaar in de looprichting naar de sluis (naar links), het
## middelpunt 15–40 px boven de vloer; van de laatste schoep naar de sluis
## ≥ 280 px droge vloer (de kade boven de straat, niet door `Diepwater`); geen
## vijand binnen 80 px; de trap terug naar K2 blijft; wie door het gat valt,
## landt rechts van de eerste schoep.
func test_k3_pompgang_geometry(t) -> void:
	var blocks: Array = Layout.blocks(120)
	var vanes: Array = Layout.PUMP_VANES
	t.check(vanes.size() == 4, "K3: %d schoepen (4)" % vanes.size())
	for i in vanes.size():
		var v: Vector2 = vanes[i]
		var up := Layout.FLOOR - v.y
		t.check(up >= 15.0 and up <= 40.0, "schoep %d: %.0f px boven de vloer (FK-5: 15–40)" % [i + 1, up])
		t.check(Layout.room_of(v) == "K3", "schoep %d niet in K3" % (i + 1))
		if i > 0:
			var prev: Vector2 = vanes[i - 1]
			t.check(is_equal_approx(prev.x - v.x, 80.0) and is_equal_approx(prev.y, v.y),
				"schoep %d: %.0f px na schoep %d (80, naar de sluis)" % [i + 1, prev.x - v.x, i])
		# Geen vijand binnen 80 px (de vijanden blijven in K2, op de vloer van K2).
		for x: float in Layout.WAVE_1 + Layout.WAVE_2 + [Layout.ARMORED_X]:
			t.check(Vector2(x, Layout.K2_FLOOR - 12.0).distance_to(v) > 80.0, "vijand op %.0f binnen 80 px van schoep %d" % [x, i + 1])
	var first: Vector2 = vanes[0]
	var last: Vector2 = vanes[vanes.size() - 1]
	var sluice_x := Layout.SLUICE.end.x
	# Vlak stuk vloer onder de schoepen en ervoor (aanloop vanaf het gat).
	var gang0 := last.x - 16.0
	var gang1 := Layout.K2_HOLE.end.x
	t.check(is_equal_approx(_covered(blocks, Layout.FLOOR, gang0, gang1), gang1 - gang0), "pompgang: geen vlakke vloer van %.0f tot %.0f" % [gang0, gang1])
	# Niets dichts in de pompgang tussen vloer en schoeptop (lopen en springen).
	for spec: Array in blocks:
		var r: Rect2 = spec[1]
		if spec[2]:
			continue
		var overlap := r.intersects(Rect2(gang0, Layout.FLOOR - 80.0, first.x + 16.0 - gang0, 80.0 - 0.5))
		t.check(not overlap, "pompgang: %s hangt in de gang" % spec[0])
	# ≥ 280 px van de laatste schoep tot de sluis, droog: vloer op FLOOR over de
	# hele weg, en de straat met Diepwater ligt lager (onder de kade).
	t.check(last.x - sluice_x >= 280.0, "laatste schoep %.0f px van de sluis (≥ 280)" % (last.x - sluice_x))
	t.check(is_equal_approx(_covered(blocks, Layout.FLOOR, sluice_x, last.x), last.x - sluice_x), "geen droge vloer van de sluis tot de laatste schoep")
	t.check(Layout.WATER_HIGH > Layout.FLOOR + Layout.HALF_H and Layout.STREET.position.y > Layout.FLOOR,
		"Diepwater op de route: waterlijn %.0f, vloer %.0f" % [Layout.WATER_HIGH, Layout.FLOOR])
	var quay := _block(blocks, "Kade")
	t.check(not quay.is_empty() and not quay[2] and (quay[1] as Rect2).position.x <= Layout.STREET.position.x
		and (quay[1] as Rect2).end.x >= Layout.STREET.end.x, "kade dekt de straat niet")
	# De trap terug naar K2: de bovenste trede onder het gat, rechts van de
	# wand van het gemaalhuis; van trede naar trede ≤ 45 px hoger (FK-6).
	var top: Rect2 = Layout.STAIRS[Layout.STAIRS.size() - 1]
	t.check(top.position.x >= Layout.K2_HOLE.position.x and top.end.x <= Layout.K2_HOLE.end.x,
		"bovenste trede ligt niet onder het gat")
	t.check(is_equal_approx(Layout.GEMAALHUIS_WALL.end.x, top.position.x), "wand van het gemaalhuis sluit niet aan op de bovenste trede")
	for i in range(1, Layout.STAIRS.size()):
		var a: Rect2 = Layout.STAIRS[i - 1]
		var b: Rect2 = Layout.STAIRS[i]
		t.check(a.position.y - b.position.y <= 45.0 and a.position.x - b.end.x <= 64.0, "trap: trede %d → %d te hoog of te ver" % [i, i + 1])
	t.check(Layout.FLOOR - (Layout.STAIRS[0] as Rect2).position.y <= 45.0, "trap: eerste trede te hoog")
	# Landing na het gat ligt rechts van de eerste schoep (zie de run in
	# test_flowkamer.gd): de wand van het gemaalhuis hangt tot ≤ 110 px boven de vloer.
	t.check(Layout.GEMAALHUIS_WALL.end.y >= Layout.FLOOR - 110.0 and Layout.GEMAALHUIS_WALL.end.y <= Layout.FLOOR - 31.0,
		"wand van het gemaalhuis: onderkant %.0f" % Layout.GEMAALHUIS_WALL.end.y)


# --- K2 in paren -------------------------------------------------------------

func _check_pairs(t, pairs: Array, label: String) -> void:
	for p: Array in pairs:
		t.check(p.size() == 2 and absf(p[1] - p[0]) <= 32.0, "%s: paar %s niet ≤ 32 px" % [label, p])
		t.check(absf(p[1] - p[0]) <= 48.0, "%s: paar %s niet binnen K = 48 (L-13 (d))" % [label, p])
	for i in pairs.size():
		for j in range(i + 1, pairs.size()):
			var gap := INF
			for a: float in pairs[i]:
				for b: float in pairs[j]:
					gap = minf(gap, absf(a - b))
			t.check(gap >= 160.0, "%s: paren %s en %s %.0f px uit elkaar (≥ 160)" % [label, pairs[i], pairs[j], gap])


## W-3: elke golf uit paren; golf 2 aan de kant van de ingang; het
## pantserdoel blijft. Daarna in de kamer: zo staan ze er ook bij het begin
## van elke golf.
func test_k2_waves_in_pairs(t) -> void:
	_check_pairs(t, Layout.WAVE_1_PAIRS, "golf 1")
	_check_pairs(t, Layout.WAVE_2_PAIRS, "golf 2")
	var flat1: Array = []
	for p: Array in Layout.WAVE_1_PAIRS:
		flat1.append_array(p)
	var flat2: Array = []
	for p: Array in Layout.WAVE_2_PAIRS:
		flat2.append_array(p)
	t.check(flat1 == Layout.WAVE_1 and flat2 == Layout.WAVE_2, "WAVE_1/WAVE_2 wijken af van de paren")
	var mean := func(xs: Array) -> float:
		var s := 0.0
		for x: float in xs:
			s += x
		return s / xs.size()
	t.check(mean.call(flat2) < mean.call(flat1), "golf 2 staat niet aan de kant van de ingang (links)")
	t.check(Layout.WAVE_2_PAIRS[0][0] < Layout.ARMORED_X and Layout.ARMORED_X < Layout.WAVE_2_PAIRS[-1][0],
		"pantserdoel niet tussen de paren van golf 2")
	for x: float in flat1 + flat2 + [Layout.ARMORED_X]:
		t.check(x >= Layout.K2_LEFT + 8.0 and x <= Layout.K2_HOLE.position.x - 8.0, "vijand op x = %.0f buiten K2" % x)
	# In de kamer: P1 komt K2 binnen (golf 1), golf 1 valt (golf 2).
	var room = FlowRoom.new()
	room.tail = 120
	room.autosave = false
	room.show_hud = false
	room.input_override = preload("res://scripts/input/scripted_input.gd").new([[600, 0]])
	t.tree.root.add_child(room)
	await t.tree.physics_frame
	room.p1.position = Layout.ROOM_START["K2"]
	await t.tree.physics_frame
	await t.tree.physics_frame
	t.check(room.wave == 1, "golf 1 start niet bij binnenkomst in K2")
	var xs: Array = []
	for e in room.enemies:
		xs.append(e.position.x)
	t.check(_near(xs, Layout.WAVE_1), "golf 1 staat op %s (verwacht %s)" % [xs, Layout.WAVE_1])
	for e in room.enemies:
		e.alive = false
	await t.tree.physics_frame
	await t.tree.physics_frame
	t.check(room.wave == 2 and room.armored != null and room.armored.alive, "golf 2 (met pantserdoel) start niet")
	var xs2: Array = []
	for e in room.enemies:
		if e.alive and e != room.armored:
			xs2.append(e.position.x)
	t.check(_near(xs2, Layout.WAVE_2), "golf 2 staat op %s (verwacht %s)" % [xs2, Layout.WAVE_2])
	room.queue_free()
	await t.tree.process_frame


## Zelfde posities op ± 1 px (de vijanden lopen 0,25 px/tick naar P1).
func _near(xs: Array, want: Array) -> bool:
	if xs.size() != want.size():
		return false
	for i in xs.size():
		if absf(float(xs[i]) - float(want[i])) > 1.0:
			return false
	return true


# --- Keren: de gescripte run per D (L-08 (c), MP-3 per keerpunt) -------------

const TURNS := ["B1", "B2-0", "B2-1", "B2-2", "B2-3"]


func _bot_run(t, d: int, echo_on: bool) -> Array:
	var room = FlowRoom.new()
	room.tail = d
	room.echo_on = echo_on
	room.autosave = false
	room.show_hud = false
	var bot = FlowBot.new(room)
	room.input_override = bot
	t.tree.root.add_child(room)
	while not room.run_over and room.sim.tick < TICK_CAP:
		await t.tree.physics_frame
	return [room, bot]


func _turns_with_echo(t, d: int) -> void:
	var pair := await _bot_run(t, d, true)
	var room = pair[0]
	var bot = pair[1]
	t.check(room.run_over, "D=%d: geen RUN_EIND" % d)
	var times := {}
	# Stilstanden van P1 (STIL_EIND op tick e met lengte n: stil van e − n tot e).
	var stills: Array = []
	for row: Array in room.meetlog.rows:
		if row[2] == "STIL_EIND" and str(row[4]) == "p1":
			stills.append([int(row[0]) - int(row[3]), int(row[0])])
	for leg_name: String in TURNS:
		t.check(bot.lines.get(leg_name, false), "D=%d: %s niet via de echolijn (L-08 (c))" % [d, leg_name])
		var turn: int = bot.turned.get(leg_name, -1)
		var done: int = bot.leg_done.get(leg_name, -1)
		t.check(turn >= 0 and done > turn, "D=%d: %s zonder keertick" % [d, leg_name])
		times[leg_name] = done - turn
		if d == BUILT_D:
			# Rapport F0-2 §8.3 punt 3, gdd §4.3: zonder dash ≥ 9 px voorbij de
			# rand van de weg omhoog (Z + 8).
			var landed: float = bot.landed_from_wall.get(leg_name, -1.0)
			t.check(landed >= Layout.KEERZONE + 8.0 + 9.0, "D=%d: %s landing %.0f px van de wand, rand %.0f + 9 marge" % [
				d, leg_name, landed, Layout.KEERZONE + 8.0])
		# MP-3 per keerpunt: de landing na het keren zonder stilstand ≥ 20 ticks
		# in de 120 ticks ervoor.
		var landing := -1
		for row: Array in room.meetlog.rows:
			if row[2] == "SPRINGPLANK" and int(row[0]) > turn and int(row[0]) <= done:
				landing = int(row[0])
				break
		t.check(landing > 0, "D=%d: %s geen springplank-landing na het keren" % [d, leg_name])
		for s: Array in stills:
			var overlap := mini(s[1], landing) - maxi(s[0], landing - 120)
			t.check(not (s[1] - s[0] >= 20 and overlap > 0), "D=%d: %s stilstand %s vóór de landing (MP-3)" % [d, leg_name, s])
	_turn_ticks[d] = times
	t.note("D=%d keren tot het volgende niveau (ticks): %s" % [d, times])
	room.queue_free()
	await t.tree.process_frame


func _turns_without_echo(t, d: int) -> void:
	var with_echo: Dictionary = _turn_ticks.get(d, {})
	t.check(not with_echo.is_empty(), "D=%d: geen run met echo om mee te vergelijken" % d)
	var pair := await _bot_run(t, d, false)
	var room = pair[0]
	var bot = pair[1]
	t.check(room.run_over, "D=%d: met echo uit geen RUN_EIND" % d)
	var times := {}
	var slower_at_180: Array = []
	for leg_name: String in TURNS:
		var turn: int = bot.turned.get(leg_name, -1)
		var done: int = bot.leg_done.get(leg_name, -1)
		times[leg_name] = done - turn
		var echo_t: int = with_echo.get(leg_name, 0)
		t.check(echo_t > 0, "D=%d: %s zonder keertijd met echo" % [d, leg_name])
		if d == BUILT_D:
			# W-8 (gdd v0.8 §4.3, §4.8.4): keren ≥ 30 ticks sneller dan de
			# snelste langzame lijn zonder dash, vanaf de wand (v0.8.2; met dash:
			# `_slow_line_with_dash`, W-12).
			t.check(times[leg_name] - echo_t >= 30, "D=%d: %s langzame lijn zonder dash %d ticks, keren %d: verschil %d (W-8: ≥ 30)" % [
				d, leg_name, times[leg_name], echo_t, times[leg_name] - echo_t])
		elif d <= 120:
			# Regressie: bij 90 en 120 blijft keren sneller.
			t.check(times[leg_name] > echo_t, "D=%d: %s langzame lijn %d ticks, keren %d (keren moet sneller)" % [
				d, leg_name, times[leg_name], echo_t])
		else:
			# D = 180: keren duurt D/2 + 34 ≈ 124 ticks, en de langzame lijn van
			# de kamer op D = 60 hooguit 2 × 68 = 136 (W-8). Beide eisen samen
			# kunnen bij 180 niet; dat staat als bevinding in flowkamer.md §12.
			# Gemeten (T16f): langzame lijn 104–105, keren 125–133, dus de
			# langzame lijn is 20–29 ticks sneller. Ondergrens: hooguit 32 ticks
			# sneller, en de langzame lijn zelf ≥ 100 ticks; een verslechtering
			# (sneller treden of trager keren) faalt dan.
			t.check(echo_t - times[leg_name] <= 32, "D=%d: %s langzame lijn %d ticks, keren %d: langzame lijn %d ticks sneller (grens 32, gemeten 20–29)" % [
				d, leg_name, times[leg_name], echo_t, echo_t - times[leg_name]])
			t.check(times[leg_name] >= 100, "D=%d: %s langzame lijn %d ticks (≥ 100; gemeten 104–105)" % [d, leg_name, times[leg_name]])
			if times[leg_name] <= echo_t:
				slower_at_180.append("%s %d ≤ %d" % [leg_name, times[leg_name], echo_t])
		t.check(times[leg_name] <= 2 * maxi(echo_t, 1), "D=%d: %s langzame lijn %d ticks > 2× keren %d (FK-2)" % [
			d, leg_name, times[leg_name], echo_t])
	t.note("D=%d langzame lijn zonder dash vanaf de keerwand (ticks): %s" % [d, times])
	if not slower_at_180.is_empty():
		t.note("D=%d: langzame lijn niet trager dan keren (kamer op D = 60; ondergrens: hooguit 32 ticks sneller): %s" % [d, ", ".join(slower_at_180)])
	room.queue_free()
	await t.tree.process_frame


func test_turns_with_echo_d60(t) -> void:
	await _turns_with_echo(t, 60)


func test_turns_without_echo_d60(t) -> void:
	await _turns_without_echo(t, 60)


func test_turns_with_echo_d90(t) -> void:
	await _turns_with_echo(t, 90)


func test_turns_with_echo_d120(t) -> void:
	await _turns_with_echo(t, 120)


func test_turns_with_echo_d180(t) -> void:
	await _turns_with_echo(t, 180)


func test_turns_without_echo_d90(t) -> void:
	await _turns_without_echo(t, 90)


func test_turns_without_echo_d120(t) -> void:
	await _turns_without_echo(t, 120)


func test_turns_without_echo_d180(t) -> void:
	await _turns_without_echo(t, 180)


# --- W-12: de langzame lijn met dash (gdd v0.8.2 §4.8.7, §4.6) -----------------

## Echo uit, tot de bot B2-3 heeft afgerond: per keerpunt de tijd van de
## keerwand tot het volgende niveau en of de dash-sprong miste.
func _dash_run(t, d: int, dash_n: int) -> Dictionary:
	var room = FlowRoom.new()
	room.tail = d
	room.echo_on = false
	room.autosave = false
	room.show_hud = false
	var bot = FlowBot.new(room)
	var source := SlowDash.new(bot, room, Layout.turn_points(), dash_n)
	room.input_override = source
	t.tree.root.add_child(room)
	while not bot.leg_done.has(TURNS[-1]) and room.sim.tick < TICK_CAP:
		await t.tree.physics_frame
	var out := {}
	for leg_name: String in TURNS:
		var turn: int = bot.turned.get(leg_name, -1)
		var done: int = bot.leg_done.get(leg_name, -1)
		out[leg_name] = "mist" if source.missed.get(leg_name, false) or turn < 0 or done < 0 else done - turn
	room.queue_free()
	await t.tree.process_frame
	return out


## Per keerpunt zonder echo de langzame lijn met een dash op `n` = 4 … 24 ticks
## na de afzet van de trede op 60 (dezelfde bot). Bij D = 60 (de kamer is op
## D = 60 gebouwd) is de snelste die de weg omhoog haalt ≥ 20 ticks trager dan
## keren en ≤ 2× keren (gdd v0.8.2 §4.3, §4.8.7); bij 90, 120 en 180
## rapporteren (regressie, zoals de eis zonder dash).
func _slow_line_with_dash(t, d: int) -> void:
	var with_echo: Dictionary = _turn_ticks.get(d, {})
	t.check(not with_echo.is_empty(), "D=%d: geen run met echo om mee te vergelijken" % d)
	var plain := await _dash_run(t, d, -1)
	var per_n := {}
	for n: int in DASH_NS:
		per_n[n] = await _dash_run(t, d, n)
	var rows := PackedStringArray()
	for leg_name: String in TURNS:
		var keer: int = with_echo.get(leg_name, 0)
		var fastest := -1
		var line := {}
		for n: int in DASH_NS:
			var v = per_n[n][leg_name]
			line[n] = v
			if typeof(v) == TYPE_INT and (fastest < 0 or v < fastest):
				fastest = v
		if d == BUILT_D:
			t.check(fastest > 0, "D=%d: %s geen dash-variant haalt de weg omhoog (%s)" % [d, leg_name, line])
			t.check(fastest - keer >= 20 and fastest <= 2 * maxi(keer, 1),
				"D=%d: %s keren %d, snelste langzame lijn met dash %d ticks (gdd §4.8.7: ≥ 20 trager, ≤ 2×)" % [d, leg_name, keer, fastest])
		rows.append("%s keren %d, zonder dash %s, met dash %s, snelste %d (%+d)" % [leg_name, keer, plain[leg_name], line, fastest, fastest - keer])
	t.note("D=%d langzame lijn met dash (ticks vanaf de keerwand): %s" % [d, "; ".join(rows)])


func test_turns_slow_line_with_dash_d60(t) -> void:
	await _slow_line_with_dash(t, 60)


func test_turns_slow_line_with_dash_d90(t) -> void:
	await _slow_line_with_dash(t, 90)


func test_turns_slow_line_with_dash_d120(t) -> void:
	await _slow_line_with_dash(t, 120)


func test_turns_slow_line_with_dash_d180(t) -> void:
	await _slow_line_with_dash(t, 180)
