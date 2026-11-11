extends RefCounted
## Tests voor de flow-kamer na F0, deel 1 (T16d, #176; gdd §4.7.4 W-1–W-3).
##
## - **Geometrie** (W-1, W-2; gdd §4.3 *Keerzone*, FK-6, L-08 voor zover de
##   geometrie): bij elk keerpunt van B1 en B2 de keerwand, D + 24 px vlakke
##   vloer, niets landbaars binnen 120 px van de wand lager dan 120 px boven de
##   vloer behalve de treden, de weg omhoog van 120 tot ≥ 270 px op 70–100 px,
##   de langzame lijn (45, 90, 135) en de landing na de bounce per D.
## - **K2 in paren** (W-3, L-13 (d)): per golf paren die ≤ 32 px uit elkaar
##   beginnen, paren ≥ 160 px uit elkaar, golf 2 aan de kant van de ingang,
##   het pantserdoel in golf 2.
## - **Keren** (L-08 (c), headless per D): de gescripte geoefende run haalt bij
##   elk keerpunt de weg omhoog via de echo, zonder stilstand van 20 ticks of
##   langer vóór de landing (MP-3 per keerpunt), en keren is sneller dan de
##   langzame lijn van dezelfde bot met echo uit (gdd §4.3), hooguit 2× (FK-2).
##
## FK-2 met echo uit (≤ 4 terugkeren, ≤ 2× de run) staat in `test_flowkamer.gd`.

const FlowRoom = preload("res://levels/flowkamer/flow_room.gd")
const FlowBot = preload("res://levels/flowkamer/flow_bot.gd")
const FlowReport = preload("res://levels/flowkamer/flow_report.gd")
const Layout = preload("res://levels/flowkamer/flow_layout.gd")

const TICK_CAP := 7000
const DS := [90, 120, 180]
## Tijd van keren tot het volgende niveau per keerpunt, met echo, per D.
static var _turn_ticks := {}


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


## W-1, W-2: keerzone, weg omhoog, langzame lijn en maten bij elk keerpunt.
func test_keerzone_geometry(t) -> void:
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
			# Keerzone: binnen 120 px van de wand (beide kanten) niets landbaars
			# lager dan 120 px boven de vloer, behalve de treden op 45 en 90.
			var hits := _landable(blocks, wall - Layout.KEERZONE, wall + Layout.KEERZONE, y - 120.0, y)
			var short := n.replace("-", "")
			var allowed := ["%sTrede45" % short, "%sTrede90" % short]
			for h: String in hits:
				t.check(h in allowed, "%s: %s is landbaar in de keerzone" % [tag, h])
			t.check(hits.size() == 2, "%s: treden van de langzame lijn ontbreken (%s)" % [tag, hits])
			# Weg omhoog: op 70–100 px (FK-6), van 120 tot ≥ 270 px van de wand.
			t.check(y - up >= 70.0 and y - up <= 100.0, "%s: weg omhoog op %.0f px (FK-6: 70–100)" % [tag, y - up])
			var w0 := minf(wall + away * 120.0, wall + away * 270.0)
			var w1 := maxf(wall + away * 120.0, wall + away * 270.0)
			t.check(_covered(blocks, up, w0, w1) >= 149.5, "%s: weg omhoog dekt 120–270 px niet" % tag)
			var start := minf(wall + away * 119.0, wall + away * 121.0)
			t.check(_covered(blocks, up, start, start + 2.0) < 1.5, "%s: weg omhoog begint niet op 120 px" % tag)
			# Langzame lijn: treden op 45 en 90 (≤ 45 px per stap, FK-6), richel op
			# 135 over de keerzone tot voorbij 120 px.
			for step in [45.0, 90.0]:
				var tread := _block(blocks, "%sTrede%d" % [short, int(step)])
				t.check(not tread.is_empty() and is_equal_approx((tread[1] as Rect2).position.y, y - step),
					"%s: trede op %.0f ontbreekt" % [tag, step])
			var ledge := _block(blocks, "%sRichel135" % short)
			t.check(not ledge.is_empty() and is_equal_approx((ledge[1] as Rect2).position.y, y - 135.0)
				and (ledge[1] as Rect2).size.x > Layout.KEERZONE + 16.0, "%s: richel op 135 ontbreekt of is te kort" % tag)
			# Overhang (WLD): dicht van 85 tot 129 px boven de vloer, 40–70 px van de wand.
			var over := _block(blocks, "%sOverhang" % short)
			t.check(not over.is_empty() and not over[2] and is_equal_approx((over[1] as Rect2).end.y, y - Layout.OVERHANG_LOW),
				"%s: overhang ontbreekt" % tag)
			# Landing na keren zonder dash: D + 68 px van de wand, ≥ 30 px voorbij
			# de rand van de weg omhoog op 120 + 8 (gdd §4.3).
			t.check(d + 68.0 >= Layout.KEERZONE + 8.0 + 30.0 - 0.5, "%s: landing %.0f px, rand + marge %.0f" % [tag, d + 68.0, Layout.KEERZONE + 38.0])
		# B2: de landing (≤ D + 88 px van de wand) ligt ≥ D + 24 px van de
		# volgende keerwand (W-2, gdd §4.3 nagerekend per D).
		var shaft := Layout.COLUMN_RIGHT - Layout.COLUMN_LEFT
		t.check(shaft - (d + 88.0) >= d + 24.0, "D=%d: B2 landing %.0f px van de volgende wand (≥ %d)" % [d, shaft - d - 88.0, d + 24])
	# B1 (W-1): gang van 320 px; B2 (W-2): schacht 480, richels 360, gat 120.
	var blocks: Array = Layout.blocks(120)
	t.check(is_equal_approx(_covered(blocks, Layout.LEVEL_540, Layout.COLUMN_LEFT, Layout.COLUMN_LEFT + 400.0), 320.0),
		"B1: gang is geen 320 px")
	t.check(is_equal_approx(Layout.COLUMN_RIGHT - Layout.COLUMN_LEFT, 480.0), "B2: schacht is geen 480 px")
	for i in Layout.LEDGES.size():
		var ledge_blocks := blocks.filter(func(spec: Array) -> bool: return str(spec[0]).begins_with("Richel%d" % (i + 1)))
		var len := _covered(ledge_blocks, Layout.LEDGES[i], Layout.COLUMN_LEFT, Layout.COLUMN_RIGHT)
		t.check(is_equal_approx(len, 360.0), "B2: richel %d is %.0f px (360)" % [i + 1, len])


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
	for leg_name: String in TURNS:
		var turn: int = bot.turned.get(leg_name, -1)
		var done: int = bot.leg_done.get(leg_name, -1)
		times[leg_name] = done - turn
		var echo_t: int = with_echo.get(leg_name, 0)
		t.check(echo_t > 0 and times[leg_name] > echo_t, "D=%d: %s langzame lijn %d ticks, keren %d (keren moet sneller)" % [
			d, leg_name, times[leg_name], echo_t])
		t.check(times[leg_name] <= 2 * maxi(echo_t, 1), "D=%d: %s langzame lijn %d ticks > 2× keren %d (FK-2)" % [
			d, leg_name, times[leg_name], echo_t])
	t.note("D=%d langzame lijn vanaf de keerwand (ticks): %s" % [d, times])
	room.queue_free()
	await t.tree.process_frame


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
