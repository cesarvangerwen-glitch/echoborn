extends RefCounted
## Tests voor de Kadewijk, deel 2: S5–S8 als grijze kamers (T8a, #83;
## `docs/design/wereld.md` §2.2–§2.6, gdd v0.8.2 §4.3, §4.5, §4.8.7, L-12,
## L-14; `docs/design/combat/slice-vijanden-en-boss.md` v0.1.3 §2.6, §3.2;
## `docs/design/gemaalmeester.md` GM-01; kamerdoc
## `docs/design/kamers/kadewijk.md` §3b–§3e, §6b). Deel 1: `test_kadewijk.gd`.
##
## - Indeling en maten per D: B2 in S5 (richels `450 − D`, gat Z, treden),
##   de pompgang van S6 (FK-5, L-14 b), het gemaal als `wijk_gemaal` van elke
##   kamer, het K-paar, het kanaal van S7 met twee Dwaallichten, het luik, de
##   arena van S8 (GM-01, GMB-01–06).
## - De gescripte geoefende run van S1 door het gemaal tot in S7 bij D = 60
##   (120 en 180 als regressie): elke echolijn, MP-1 en MP-2 per kamer,
##   **SL-01** (≥ 100 LP vóór de eerste pompslag), het gemaal vol op de eerste
##   doorgang, het lampglas; zonder echo hooguit 2× (C-15, FK-2, LM-09c), en
##   bij elke verdieping van B2 keren ≥ 30 ticks sneller dan de langzame lijn
##   zonder dash en ≥ 20 met dash, ≤ 2× (gdd §4.3, §4.8.7: bij elke D).
## - Per kamer los (D = 60): S5, S6 (met het licht van S1–S5, en zonder licht
##   via de trap), S7 (luik, stuitlijn, langzame lijn), S8 (keren in de lege
##   arena: de bounce haalt de plek van het rad, GM-07).
##
## Elke test maakt een eigen `Progress`; de autoloads en `user://saves` blijven
## onaangeroerd.

const Scene := preload("res://levels/kadewijk/kadewijk.tscn")
const Bot = preload("res://levels/kadewijk/kadewijk_bot.gd")
const Layout = preload("res://levels/kadewijk/kadewijk_layout.gd")
const Progress = preload("res://scripts/save/progress.gd")
const FlowReport = preload("res://levels/flowkamer/flow_report.gd")
const SliceEnemy = preload("res://scripts/combat/slice_enemy.gd")
const EnemyData = preload("res://scripts/combat/enemy_data.gd")
const Zone = preload("res://scripts/objects/zone.gd")
const Gemaal = preload("res://scripts/light/gemaal.gd")
const Luik = preload("res://levels/kadewijk/kadewijk_luik.gd")
const SlowDash = preload("res://tests/slow_dash_input.gd")
const InputBits = preload("res://scripts/input/input_bits.gd")
const Motor = preload("res://scripts/echo/motor.gd")

const TICK_CAP := 12000
const DASH_NS := [4, 8, 12, 16, 20, 24]
const B2_LEGS := ["S5-B2a", "S5-B2b", "S5-B2c", "S5-B2d"]
## LP waarmee P1 S6 binnenkomt in de run van S1 bij D = 60 (gemeten, kamerdoc §6b).
const LP_INTO_S6 := 88
const MAX_FRAMES := {
	"test_deel2_run_d60": 12000,
	"test_deel2_zonder_echo_d60": 14000,
	"test_deel2_run_d120": 12000,
	"test_deel2_zonder_echo_d120": 14000,
	"test_deel2_run_d180": 12000,
	"test_deel2_zonder_echo_d180": 14000,
	"test_deel2_b2_met_dash_d60": 36000,
	"test_deel2_b2_met_dash_d90": 36000,
	"test_deel2_b2_met_dash_d120": 36000,
	"test_deel2_b2_met_dash_d180": 36000,
	"test_deel2_s6_zonder_licht": 12000,
	"test_deel2_s6_los": 10000,
	"test_deel2_arena_bounce_haalt_rad": 6000,
}
static var _runs := {}


func _wijk(t, d: int, echo_on: bool, start: StringName = &"S1", run_end: StringName = &"S7", input: RefCounted = null) -> Array:
	var progress := Progress.new()
	progress.name = "TestProgress"
	t.tree.root.add_child(progress)
	var wijk = Scene.instantiate()
	wijk.tail = d
	wijk.echo_on = echo_on
	wijk.show_hud = false
	wijk.progress = progress
	wijk.start_at = Layout.ROOM_START[start]
	wijk.run_end = run_end
	var bot = null
	if input == null:
		bot = Bot.new(wijk, d, start)
		input = bot
	wijk.input_override = input
	t.tree.root.add_child(wijk)
	return [wijk, bot, progress]


func _free(t, parts: Array) -> void:
	parts[0].queue_free()
	parts[2].queue_free()
	await t.tree.process_frame


func _run(t, wijk, cap := TICK_CAP) -> void:
	# Als eerste test van de runner komt de scène pas na een frame in de boom.
	await t.tree.physics_frame
	while not wijk.run_over and wijk.sim.tick < cap:
		await t.tree.physics_frame


func _block(wijk, room: StringName, block_name: String) -> Rect2:
	var kamer = wijk.loader.kamers[room]
	if kamer.inhoud_node == null:
		return Rect2()
	var body: StaticBody2D = kamer.inhoud_node.get_node_or_null("Blokken/" + block_name)
	if body == null:
		return Rect2()
	var size: Vector2 = (body.get_child(0).shape as RectangleShape2D).size
	return Rect2(body.global_position - size * 0.5, size)


func _still_per_room(rows: Array) -> Dictionary:
	var out := {}
	for row in rows:
		if row[2] == "STIL_EIND" and row[4] == "p1":
			out[row[1]] = maxi(int(out.get(row[1], 0)), int(row[3]))
	return out


## SL-01: LP gevuld van RUN_START tot de eerste pompslag (P1 bij het gemaal).
func _lp_before_pump(rows: Array) -> int:
	var n := 0
	for row in rows:
		if row[2] == "POMP":
			return n
		if row[2] == "LP":
			n += int(str(row[3]).trim_prefix("+"))
	return n


func _count(rows: Array, event: String, source := "") -> int:
	var n := 0
	for row in rows:
		if row[2] == event and (source == "" or row[4] == source):
			n += 1
	return n


func _first(rows: Array, event: String) -> int:
	for row in rows:
		if row[2] == event:
			return int(row[0])
	return -1


# --- Indeling en maten ---------------------------------------------------------

## S5–S8 staan in de scène met de rechthoek en de buren van de layout; elke
## kamer heeft `wijk_gemaal` = het gemaal van S6 en `validate` geeft niets;
## geen zones (L-06); in S6 staan het gemaal (vier schoepen, sluis) en het
## checkpoint ervan, in S7 het luik.
func test_deel2_indeling(t) -> void:
	var parts := _wijk(t, 60, true, &"S6")
	var wijk = parts[0]
	await t.tree.physics_frame
	t.check(wijk.start_errors.is_empty() and wijk.loader.validate().is_empty(),
		"start %s, indeling %s" % [wijk.start_errors, wijk.loader.validate()])
	for id: StringName in Layout.ORDER:
		var kamer = wijk.loader.kamers.get(id)
		t.check(kamer != null and kamer.rect() == Layout.ROOMS[id], "%s: rechthoek %s (layout %s)" % [id, kamer.rect() if kamer else null, Layout.ROOMS[id]])
		if kamer:
			var want := PackedStringArray()
			for b: StringName in Layout.NEIGHBOURS[id]:
				want.append(String(b))
			t.check(kamer.buren == want, "%s: buren %s (layout %s)" % [id, kamer.buren, want])
			t.check(kamer.wijk_gemaal == &"S6/Gemaal", "%s: wijk_gemaal '%s' (L-14 a: het gemaal van S6)" % [id, kamer.wijk_gemaal])
		t.check(Layout.room_of(Layout.ROOM_START[id]) == id, "begin van %s ligt niet in %s" % [id, id])
	t.check(wijk.gemaal != null and wijk.gemaal.vanes.size() == 4 and wijk.gemaal.sluice != null,
		"S6: gemaal %s met %d schoepen" % [wijk.gemaal, wijk.gemaal.vanes.size() if wijk.gemaal else 0])
	var s6: Node = wijk.loader.kamers[&"S6"].inhoud_node
	t.check(s6.get_node("Checkpoint").get("_gemaal") == wijk.gemaal, "S6: het checkpoint hoort niet bij het gemaal (LM-08)")
	var zones: Array = wijk.find_children("*", "", true, false).filter(func(n: Node) -> bool: return n is Zone)
	t.check(zones.is_empty(), "zones in de Kadewijk (L-06): %s" % [zones])
	await _free(t, parts)
	var s7 := _wijk(t, 60, true, &"S7")
	await t.tree.physics_frame
	var luik = s7[0].loader.kamers[&"S7"].inhoud_node.get_node_or_null("Luik")
	t.check(luik is Luik and not luik.is_open, "S7: geen dicht luik (%s)" % luik)
	await _free(t, s7)


## B2 in S5 per D (gdd §4.3): schacht 480 px, richels `480 − Z` (= `450 − D`) om en om tegen
## de wanden op 90, 180, 270, 360 px boven de vloer, aan de open kant een gat
## van Z = D + 30 boven de keerwand; treden 30/60/90 tegen elke keerwand
## (de trede op 90 binnen Z); van de landing tot de volgende wand ≥ D + 24.
## Het lampglas ligt op de zolder, > 100 px boven richel 3 (L-12).
func test_deel2_b2_maten_per_d(t) -> void:
	for d in [60, 90, 120, 180]:
		var parts := _wijk(t, d, true, &"S5")
		var wijk = parts[0]
		await t.tree.physics_frame
		# Z = D + 30, en D + 40 als de loop over de richel korter is dan D (D > 130, kamerdoc §3b).
		var z := float(d + 30) if (480.0 - (d + 88.0)) * 0.5 >= d else float(d + 40)
		t.check(is_equal_approx(Layout.b2_keerzone(d), z), "D=%d B2: Z %.0f (verwacht %.0f)" % [d, Layout.b2_keerzone(d), z])
		t.check(is_equal_approx(Layout.B2_RIGHT - Layout.B2_LEFT, 480.0), "B2: schacht %.0f px" % (Layout.B2_RIGHT - Layout.B2_LEFT))
		for i in range(1, 5):
			var rect := _block(wijk, &"S5", "Richel%d" % i if i < 4 else "Zolder")
			var left_wall := i % 2 == 1
			var gap := (Layout.B2_RIGHT - rect.end.x) if left_wall else (rect.position.x - Layout.B2_LEFT)
			t.check(is_equal_approx(rect.size.x, 480.0 - z) and is_equal_approx(gap, z)
				and is_equal_approx(Layout.B2_LEVELS[0] - rect.position.y, 90.0 * i),
				"D=%d S5 richel %d: %s (breedte %.0f = 480 − Z, gat %.0f = Z, %d px hoog)" % [d, i, rect, 480.0 - z, gap, 90 * i])
		for tp: Dictionary in Layout.turn_points(d).slice(3, 7):
			var prefix := String(tp["name"]).trim_prefix("S5-")
			var t90 := _block(wijk, &"S5", "%sTrede90" % prefix)
			var dist := absf(t90.get_center().x - float(tp["wall"])) + t90.size.x * 0.5
			t.check(t90.size.x > 0.0 and dist < z and is_equal_approx(float(tp["floor"]) - t90.position.y, 90.0),
				"D=%d %s: trede op 90 %s binnen Z (%.0f < %.0f)" % [d, tp["name"], t90, dist, z])
			# Landing na keren zonder dash ± `D + 70` van de wand; tot de volgende wand ≥ D + 24.
			t.check(480.0 - (d + 88.0) >= d + 24.0, "D=%d B2: %.0f px tot de volgende wand (≥ D + 24)" % [d, 480.0 - (d + 88.0)])
		await _free(t, parts)
	# Het lampglas (9 px groot) hangt waar P1 op de zolder loopt; met een sprong
	# van richel 3 (± 50 px, het lichaam 30 erbij) kom je er niet bij.
	var jump_top: float = Layout.B2_LEVELS[3] - 50.0 - 30.0
	t.check(Layout.B2_LEVELS[3] - Layout.LAMPGLAS.y > 100.0 and Layout.LAMPGLAS.y + 9.0 < jump_top
		and is_equal_approx(Layout.LAMPGLAS.y + Layout.HALF_H, Layout.S5_ZOLDER),
		"lampglas %s: %.0f px boven richel 3 (L-12: > 100), onderkant %.0f boven het hoogste van een sprong (%.0f), op de zolder" % [
		Layout.LAMPGLAS, Layout.B2_LEVELS[3] - Layout.LAMPGLAS.y, jump_top - Layout.LAMPGLAS.y - 9.0, jump_top])


## S6 (FK-5, L-14 b, §2.6): vier schoepen op het plein, 80 px uit elkaar, het
## middelpunt 15–40 px boven de vloer; van de laatste schoep tot de sluis
## ≥ `2 × (D − 40)` voor elke D tot 180; het K-paar 40–44 px (`paar_k`) en
## ≥ 80 px van elke schoep; de trap terug met treden ≤ 45 px. S7: het kanaal
## 160 px breed en 90 diep met een trede ≤ 45, de Dwaallichten op 1/3 en 2/3
## met banen van 32 px, 40 px boven de vloer.
func test_deel2_s6_s7_maten(t) -> void:
	var parts := _wijk(t, 60, true, &"S6")
	var wijk = parts[0]
	await t.tree.physics_frame
	var g: Gemaal = wijk.gemaal
	for i in g.vanes.size():
		var v: Node2D = g.vanes[i]
		t.check(v.position == Layout.PUMP_VANES[i], "schoep %d op %s (layout %s)" % [i + 1, v.position, Layout.PUMP_VANES[i]])
		var up: float = Layout.S6_FLOOR - v.position.y
		t.check(up >= 15.0 and up <= 40.0, "schoep %d: %.0f px boven de vloer (FK-5: 15–40)" % [i + 1, up])
		if i > 0:
			t.check(is_equal_approx(v.position.x - g.vanes[i - 1].position.x, 80.0), "schoep %d: %.0f px van de vorige (80)" % [i + 1, v.position.x - g.vanes[i - 1].position.x])
	var last_x: float = g.vanes[g.vanes.size() - 1].position.x
	var sluice_x: float = g.sluice.global_position.x - 30.0
	t.check(sluice_x - last_x >= 2.0 * (180 - 40), "laatste schoep → sluis %.0f px (FK-5: ≥ 2 × (D − 40) tot D = 180)" % (sluice_x - last_x))
	var s6: Node = wijk.loader.kamers[&"S6"].inhoud_node
	var a: SliceEnemy = s6.get_node("Paar1A")
	var b: SliceEnemy = s6.get_node("Paar1B")
	var k := EnemyData.value("gedeeld", "paar_k")
	t.check(a.pair_partner == b and is_equal_approx(absf(a.position.x - b.position.x), k) and k >= 40.0 and k <= 44.0,
		"S6: K-paar op %.0f px (paar_k %.0f, 40–44)" % [absf(a.position.x - b.position.x), k])
	for e: SliceEnemy in [a, b]:
		for v: Node2D in g.vanes:
			t.check(absf(e.position.x - v.position.x) >= 80.0, "S6: %s %.0f px van een schoep (FK-5: ≥ 80)" % [e.name, absf(e.position.x - v.position.x)])
	var prev := Layout.S6_FLOOR
	for y: float in Layout.S6_STAIR + [Layout.S5_ZOLDER]:
		t.check(prev - y <= 45.0, "S6: trap %.0f → %.0f (FK-6: ≤ 45)" % [prev, y])
		prev = y
	await _free(t, parts)
	var s7 := _wijk(t, 60, true, &"S7")
	await t.tree.physics_frame
	var w7 = s7[0]
	t.check(is_equal_approx(Layout.KANAAL_RIGHT - Layout.KANAAL_LEFT, 160.0) and is_equal_approx(Layout.KANAAL_BOTTOM - Layout.S7_LOW, 90.0),
		"S7: kanaal %.0f × %.0f (160 × 90)" % [Layout.KANAAL_RIGHT - Layout.KANAAL_LEFT, Layout.KANAAL_BOTTOM - Layout.S7_LOW])
	var trede := _block(w7, &"S7", "KanaalTrede")
	t.check(trede.size.y <= 45.0 and Layout.KANAAL_BOTTOM - 45.0 - Layout.S7_LOW <= 45.0, "S7: trede %s (FK-6)" % trede)
	var wisps: Array = w7.loader.kamers[&"S7"].inhoud_node.find_children("Dwaallicht*", "", false, false)
	t.check(wisps.size() == 2, "S7: %d Dwaallichten (§2.6: 2)" % wisps.size())
	for i in wisps.size():
		var e: SliceEnemy = wisps[i]
		var third := Layout.KANAAL_LEFT + (Layout.KANAAL_RIGHT - Layout.KANAAL_LEFT) * (i + 1) / 3.0
		t.check(e.enemy_type == SliceEnemy.Type.DWAALLICHT and absf(e.start_position.x - third) <= 1.0
			and is_equal_approx(absf(e.lane_to - e.lane_from), 32.0)
			and is_equal_approx(Layout.S7_LOW - (e.position.y + 8.0), 40.0),
			"S7: %s op %.0f (1/3-plek %.0f), baan %.0f, onderkant %.0f px boven de vloer" % [e.name, e.start_position.x, third,
			absf(e.lane_to - e.lane_from), Layout.S7_LOW - (e.position.y + 8.0)])
	await _free(t, s7)


## De arena van de Gemaalmeester (GM-01, GMB-01–06): één scherm, een vlakke
## vloer van 600 px tussen twee muren, aan elke kant van het lichaam
## (x 252–348) ≥ D + 24 tot D = 180, het rad (y 100–140, x `D − 14 … D + 82`)
## past onder het plafond met ruimte voor de lancering (≥ 180 px vrij), geen
## eenrichtingsvloer, geen zones. De deur rechts staat open (van S7), links dicht;
## `set_door` sluit en opent ze (voor de GP).
func test_deel2_arena_maten(t) -> void:
	var parts := _wijk(t, 60, true, &"S8")
	var wijk = parts[0]
	await t.tree.physics_frame
	var floor_rect := _block(wijk, &"S8", "Vloer")
	t.check(is_equal_approx(floor_rect.size.x, Layout.ARENA_W) and is_equal_approx(floor_rect.position.x, Layout.ARENA_WALL_L)
		and is_equal_approx(floor_rect.position.y, Layout.ARENA_FLOOR), "S8: vloer %s (600 px vanaf de linkermuur)" % floor_rect)
	t.check(is_equal_approx(Layout.ARENA_W, 600.0) and 252.0 >= 180 + 24 and Layout.ARENA_W - 348.0 >= 180 + 24,
		"S8: vlak naast het lichaam %.0f / %.0f px (GM-01: ≥ D + 24 tot D = 180)" % [252.0, Layout.ARENA_W - 348.0])
	var r: Rect2 = Layout.ROOMS[&"S8"]
	t.check(is_equal_approx(r.size.x, 640.0) and is_equal_approx(r.size.y, 360.0), "S8: %s (één scherm)" % r)
	t.check(Layout.ARENA_FLOOR - r.position.y >= 180.0 and Layout.ARENA_FLOOR - r.position.y >= 140.0 + 30.0 + 30.0,
		"S8: %.0f px vrij boven de vloer (rad tot 140, lancering)" % (Layout.ARENA_FLOOR - r.position.y))
	var one_way := 0
	for spec: Array in Layout.blocks(&"S8", 60):
		if spec[2]:
			one_way += 1
	t.check(one_way == 0, "S8: %d eenrichtingsvloeren (GM-01: geen richels)" % one_way)
	var door_r := _block(wijk, &"S8", "DeurRechts")
	var body_r: StaticBody2D = wijk.loader.kamers[&"S8"].inhoud_node.get_node("Blokken/DeurRechts")
	var body_l: StaticBody2D = wijk.loader.kamers[&"S8"].inhoud_node.get_node("Blokken/DeurLinks")
	t.check(body_r.collision_layer == 0 and body_l.collision_layer != 0, "S8: deur rechts %d, links %d (verwacht open / dicht)" % [body_r.collision_layer, body_l.collision_layer])
	t.check(is_equal_approx(door_r.position.x, Layout.ARENA_WALL_R) and is_equal_approx(door_r.end.y, Layout.S7_LOW), "S8: deur rechts %s" % door_r)
	t.check(wijk.set_door(&"S8", "DeurRechts", true) and body_r.collision_layer == 1, "set_door sluit de deur niet")
	await _free(t, parts)


# --- Gescripte runs ------------------------------------------------------------

## Eén run van S1 door het gemaal tot in S7 (`run_end` S7). Bewaart de cijfers.
func _full_run(t, d: int, echo_on: bool) -> Array:
	var parts := _wijk(t, d, echo_on)
	var wijk = parts[0]
	var bot = parts[1]
	await _run(t, wijk)
	var rows: Array = wijk.meetlog.rows
	var rep = FlowReport.from_rows(rows, echo_on)
	var keer := {}
	for tp: Dictionary in Layout.turn_points(d):
		var n: String = tp["name"]
		if bot.turned.has(n) and bot.leg_done.has(n):
			keer[n] = int(bot.leg_done[n]) - int(bot.turned[n])
	var lp := _lp_before_pump(rows)
	_runs["%d_%s" % [d, "aan" if echo_on else "uit"]] = {"ticks": wijk.run_ticks(), "rooms": rep.room_time.duplicate(), "keer": keer,
		"returns": bot.s6_returns}
	var label := "D=%d echo %s" % [d, "aan" if echo_on else "uit"]
	t.check(wijk.run_over and wijk.room == &"S7", "%s: S7 niet gehaald (tick %d, stap %s, kamer %s, P1 %s, G %s, LP %d)" % [
		label, wijk.sim.tick, bot.leg_name(), wijk.room, wijk.p1.position, wijk.gemaal.fill if wijk.gemaal else -1, wijk.meter.value])
	t.check(wijk.start_errors.is_empty(), "start: %s" % [wijk.start_errors])
	t.check(_count(rows, "RESPAWN") == 0 and wijk.p1.health > 0, "%s: P1 stierf (%d respawns)" % [label, _count(rows, "RESPAWN")])
	t.check(wijk.most_at_once <= 5, "%s: %d vijanden tegelijk (L-13 f)" % [label, wijk.most_at_once])
	t.check(_first(rows, "GEMAAL_VOL") > 0, "%s: gemaal niet vol" % label)
	var still := _still_per_room(rows)
	for id: StringName in Layout.ORDER:
		t.check(int(still.get(String(id), 0)) <= 300, "%s %s: langste stilstand %d ticks (MP-1 ≤ 300)" % [label, id, still.get(String(id), 0)])
	t.check(wijk.lampglas_tick > 0, "%s: lampglas niet gehaald" % label)
	t.note("%s: S1 → S7 %d ticks (%s), MP-1 %s, LP totaal %d, LP vóór de eerste pompslag %d (SL-01), POMP p1/echo %d/%d, GEMAAL_VOL tick %d, terug naar S5 %d×, treffers P1 %d, keerpunten %s" % [
		label, wijk.run_ticks(), rep.room_time, still, rep.lp_total, lp, _count(rows, "POMP", "p1"), _count(rows, "POMP", "echo"),
		_first(rows, "GEMAAL_VOL"), bot.s6_returns, 5 - wijk.p1.health, keer])
	return [parts, rep, lp]


func _check_echo_run(t, d: int, out: Array) -> void:
	var parts: Array = out[0]
	var rep = out[1]
	var wijk = parts[0]
	var bot = parts[1]
	for n: String in B2_LEGS:
		t.check(bot.lines.get(n, false), "D=%d %s: niet via de echolijn (L-08)" % [d, n])
	for id: StringName in [&"S5", &"S6"]:
		var per: float = rep.actions_per_min_room.get(String(id), 0.0)
		t.check(per >= 3.0, "D=%d %s: %.2f echo-acties per minuut (MP-2 per kamer, L-11)" % [d, id, per])
	t.check(rep.longest_gap <= FlowReport.MP2_WINDOW, "D=%d: %d ticks zonder echo-actie (MP-2/L-11: ≤ 40 s)" % [d, rep.longest_gap])
	t.check(rep.echo_empty_share <= 0.4, "D=%d: echo %.0f %% Leeg (MP-4)" % [d, rep.echo_empty_share * 100.0])
	t.check(rep.lp_echo_share >= 0.4, "D=%d: %.0f %% LP met de echo (MP-6)" % [d, rep.lp_echo_share * 100.0])
	# SL-01 (L-14 c): de run van S1 tot het gemaal vult minstens één trap, en de
	# eerste doorgang van de pompgang maakt het gemaal vol (geen terugweg).
	t.check(int(out[2]) >= 100, "D=%d: %d LP vóór de eerste pompslag (SL-01: ≥ 100)" % [d, out[2]])
	t.check(bot.s6_returns == 0, "D=%d: %d× terug naar S5 voor licht (met echo: 0)" % [d, bot.s6_returns])
	if d == 60:
		t.check(rep.landings > 0 and rep.landings_without_still >= 0.75,
			"D=60: %.0f %% van %d landingen zonder stilstand (MP-3 ≥ 75 %%)" % [rep.landings_without_still * 100.0, rep.landings])
	t.note("D=%d: MP-2 %.1f/min %s, langste gat %d, MP-3 %.0f %% van %d, MP-4 %.0f %%, MP-6 %.0f %%, B2 bounce %s landing %s, stuits %d, lijnen %s" % [
		d, rep.actions_per_min, rep.actions_per_min_room, rep.longest_gap, rep.landings_without_still * 100.0, rep.landings,
		rep.echo_empty_share * 100.0, rep.lp_echo_share * 100.0, _pick(bot.bounce_from_wall, B2_LEGS), _pick(bot.landed_from_wall, B2_LEGS),
		bot.stuits, bot.lines])
	var _w = wijk


func _pick(dict: Dictionary, keys: Array) -> Dictionary:
	var out := {}
	for k in keys:
		if dict.has(k):
			out[k] = dict[k]
	return out


## C-15/FK-2/LM-09c en de eis bij keren zonder dash, per verdieping van B2.
## S6 per kamer: zonder echo komt P1 er met minder licht aan (48 tegen 88 LP
## bij D = 60) en moet hij terug voor licht; dat is FK-2/LM-09c (de run ≤ 2×,
## ≤ 4 keer terug), hier getoetst. Hetzelfde plein met hetzelfde licht bij
## binnenkomst (C-15 voor de route van S6): `test_deel2_s6_los`.
func _check_slow_lines(t, d: int) -> void:
	var on: Dictionary = _runs.get("%d_aan" % d, {})
	var off: Dictionary = _runs.get("%d_uit" % d, {})
	t.check(not on.is_empty() and not off.is_empty(), "D=%d: run met en zonder echo nodig" % d)
	if on.is_empty() or off.is_empty():
		return
	t.check(off["ticks"] <= 2 * on["ticks"], "D=%d: zonder echo %d ticks, met %d (C-15, LM-09c: ≤ 2×)" % [d, off["ticks"], on["ticks"]])
	t.check(int(off["returns"]) <= 4, "D=%d: zonder echo %d keer terug naar S5 voor licht (FK-2: ≤ 4)" % [d, off["returns"]])
	# SM-review #223: de run zonder echo zit op de grens (1,90× en 4 keer terug bij
	# D = 60); de marge per D staat in de melding, zodat een kleine wijziging opvalt.
	t.note("D=%d: marge zonder echo: %d ticks tot 2× (%.2f× van 2,00×), terugkeren %d van max. 4 (marge %d)" % [
		d, 2 * int(on["ticks"]) - int(off["ticks"]), float(off["ticks"]) / maxf(on["ticks"], 1), off["returns"], 4 - int(off["returns"])])
	var a5 := int(on["rooms"].get("S5", 0))
	var b5 := int(off["rooms"].get("S5", 0))
	t.check(a5 > 0 and b5 <= 2 * a5, "D=%d S5: zonder echo %d ticks, met %d (C-15: ≤ 2×)" % [d, b5, a5])
	t.note("D=%d: zonder echo %.2f× (run), S5 %.2f×, S6 %d tegen %d ticks (%d keer terug; met gelijk licht: test_deel2_s6_los)" % [
		d, float(off["ticks"]) / maxf(on["ticks"], 1), float(b5) / maxf(a5, 1), int(off["rooms"].get("S6", 0)),
		int(on["rooms"].get("S6", 0)), off["returns"]])
	for n: String in B2_LEGS:
		var keer := int(on["keer"].get(n, -1))
		var slow := int(off["keer"].get(n, -1))
		t.check(keer > 0 and slow - keer >= 30 and slow <= 2 * keer,
			"D=%d %s: keren %d, langzame lijn zonder dash %d ticks vanaf de wand (gdd §4.3: ≥ 30 sneller, ≤ 2×)" % [d, n, keer, slow])
		t.note("D=%d %s: keren %d, langzame lijn zonder dash %d (+%d, %.2f×)" % [d, n, keer, slow, slow - keer, float(slow) / maxf(keer, 1)])


func test_deel2_run_d60(t) -> void:
	var out := await _full_run(t, 60, true)
	_check_echo_run(t, 60, out)
	await _free(t, out[0])


func test_deel2_zonder_echo_d60(t) -> void:
	var out := await _full_run(t, 60, false)
	await _free(t, out[0])
	_check_slow_lines(t, 60)


func test_deel2_run_d120(t) -> void:
	var out := await _full_run(t, 120, true)
	_check_echo_run(t, 120, out)
	await _free(t, out[0])


func test_deel2_zonder_echo_d120(t) -> void:
	var out := await _full_run(t, 120, false)
	await _free(t, out[0])
	_check_slow_lines(t, 120)


func test_deel2_run_d180(t) -> void:
	var out := await _full_run(t, 180, true)
	_check_echo_run(t, 180, out)
	await _free(t, out[0])


func test_deel2_zonder_echo_d180(t) -> void:
	var out := await _full_run(t, 180, false)
	await _free(t, out[0])
	_check_slow_lines(t, 180)


# --- W-12 bij B2: de langzame lijn met dash (gdd v0.8.2 §4.8.7) ---------------

## Vanaf het begin van S5 tot de bot verdieping `leg` van B2 heeft afgerond.
func _keer_run(t, d: int, echo_on: bool, leg: String, dash_n: int) -> Array:
	var parts := _wijk(t, d, echo_on, &"S5", &"S6")
	var wijk = parts[0]
	var bot = parts[1]
	var source := SlowDash.new(bot, wijk, Layout.turn_points(d), dash_n)
	wijk.input_override = source
	wijk.p1.input_source = source
	while not bot.leg_done.has(leg) and wijk.sim.tick < 6000:
		await t.tree.physics_frame
	var ticks := -1
	if bot.leg_done.has(leg) and bot.turned.has(leg):
		ticks = int(bot.leg_done[leg]) - int(bot.turned[leg])
	var missed: bool = source.missed.get(leg, false)
	var line: bool = bot.lines.get(leg, false)
	await _free(t, parts)
	if echo_on and not line:
		return [-1, true]
	return [ticks, missed]


func _b2_with_dash(t, d: int) -> void:
	for leg: String in B2_LEGS:
		var keer: Array = await _keer_run(t, d, true, leg, -1)
		t.check(keer[0] > 0, "D=%d %s: keren niet gemeten" % [d, leg])
		var plain: Array = await _keer_run(t, d, false, leg, -1)
		t.check(plain[0] > 0 and plain[0] - keer[0] >= 30 and plain[0] <= 2 * keer[0],
			"D=%d %s: keren %d, langzame lijn zonder dash %d (≥ 30 trager, ≤ 2×)" % [d, leg, keer[0], plain[0]])
		var per := {}
		var fastest := -1
		for n: int in DASH_NS:
			var r: Array = await _keer_run(t, d, false, leg, n)
			per[n] = "mist" if r[1] or r[0] < 0 else r[0]
			if not r[1] and r[0] > 0 and (fastest < 0 or r[0] < fastest):
				fastest = r[0]
		t.check(fastest > 0, "D=%d %s: geen dash-variant haalt de volgende richel (%s)" % [d, leg, per])
		t.check(fastest - keer[0] >= 20 and fastest <= 2 * keer[0],
			"D=%d %s: keren %d, snelste langzame lijn met dash (n = 4 … 24) %d (gdd §4.8.7: ≥ 20 trager, ≤ 2×)" % [d, leg, keer[0], fastest])
		t.note("D=%d %s: keren %d, zonder dash %d, met dash na n ticks %s: snelste %d (+%d, %.2f×)" % [
			d, leg, keer[0], plain[0], per, fastest, fastest - keer[0], float(fastest) / maxf(keer[0], 1)])


func test_deel2_b2_met_dash_d60(t) -> void:
	await _b2_with_dash(t, 60)


func test_deel2_b2_met_dash_d90(t) -> void:
	await _b2_with_dash(t, 90)


func test_deel2_b2_met_dash_d120(t) -> void:
	await _b2_with_dash(t, 120)


func test_deel2_b2_met_dash_d180(t) -> void:
	await _b2_with_dash(t, 180)


# --- Per kamer los (D = 60) ------------------------------------------------------

## S5 vanaf zijn begin: vier keer keren via de echolijn naar de zolder, het
## lampglas, en S6 in; MP-1.
func test_deel2_s5_los(t) -> void:
	var parts := _wijk(t, 60, true, &"S5", &"S6")
	var wijk = parts[0]
	var bot = parts[1]
	await _run(t, wijk, 4000)
	t.check(wijk.run_over, "S5: S6 niet gehaald (stap %s, P1 %s)" % [bot.leg_name(), wijk.p1.position])
	for n: String in B2_LEGS:
		t.check(bot.lines.get(n, false), "S5: %s niet via de echolijn" % n)
	t.check(wijk.lampglas_tick > 0, "S5: lampglas niet gehaald")
	var still := _still_per_room(wijk.meetlog.rows)
	t.check(int(still.get("S5", 0)) <= 300, "S5: stilstand %d (MP-1)" % still.get("S5", 0))
	t.note("S5 los: %d ticks, lampglas tick %d, keren %s" % [wijk.run_ticks(), wijk.lampglas_tick, bot.turned])
	await _free(t, parts)


## S6 vanaf zijn begin, met het licht waarmee P1 er in de run aankomt
## (`LP_INTO_S6`): het paar, één doorgang door de pompgang, het gemaal vol,
## de sluis open op `t_v`, de kelder in (S7); MP-1. Het checkpoint is daarna
## het gemaal (SL-03).
func _s6_alone(t, echo_on: bool) -> Array:
	var parts := _wijk(t, 60, echo_on, &"S6", &"S7")
	var wijk = parts[0]
	await t.tree.physics_frame
	wijk.meter.add(wijk.sim.tick, LP_INTO_S6, "test", "p1")
	await _run(t, wijk, 4000)
	return parts


func test_deel2_s6_los(t) -> void:
	var off := await _s6_alone(t, false)
	var off_ticks: int = off[0].run_ticks() if off[0].run_over else -1
	var off_returns: int = off[1].s6_returns
	await _free(t, off)
	var parts := await _s6_alone(t, true)
	var wijk = parts[0]
	var bot = parts[1]
	var rows: Array = wijk.meetlog.rows
	t.check(wijk.run_over and wijk.room == &"S7", "S6: S7 niet gehaald (stap %s, P1 %s, G %d, LP %d)" % [
		bot.leg_name(), wijk.p1.position, wijk.gemaal.fill if wijk.gemaal else -1, wijk.meter.value])
	t.check(bot.s6_returns == 0, "S6: %d× terug voor licht" % bot.s6_returns)
	var still := _still_per_room(rows)
	t.check(int(still.get("S6", 0)) <= 300, "S6: stilstand %d (MP-1)" % still.get("S6", 0))
	var progress = parts[2]
	t.check(progress.state.checkpoint_kamer == &"S6", "S6: het gemaal is geen checkpoint geworden (LM-08; checkpoint in %s)" % progress.state.checkpoint_kamer)
	# C-15 voor de route van S6: zonder echo, met hetzelfde licht bij binnenkomst.
	# Bewust met gelijk licht (LGD-besluit bij afwijking 10, Lead-review #223): C-15
	# per kamer met gelijk licht; het tekort aan licht toetsen LM-09c en FK-2 op de run.
	t.check(off_ticks > 0 and off_ticks <= 2 * wijk.run_ticks(),
		"S6 met %d LP: zonder echo %d ticks, met %d (C-15: ≤ 2×, bewust met gelijk licht bij binnenkomst: LGD-besluit afwijking 10, #223)" % [
		LP_INTO_S6, off_ticks, wijk.run_ticks()])
	t.note("S6 los (LP %d bij binnenkomst, C-15 bewust met gelijk licht: LGD-besluit afwijking 10): %d ticks, POMP p1/echo %d/%d, GEMAAL_VOL tick %d, ontploffingen %d, checkpoint %s; zonder echo %d ticks (%.2f×, %d keer terug)" % [
		LP_INTO_S6, wijk.run_ticks(), _count(rows, "POMP", "p1"), _count(rows, "POMP", "echo"), _first(rows, "GEMAAL_VOL"),
		_count(rows, "ONTPLOFFING"), progress.state.checkpoint_positie, off_ticks, float(off_ticks) / maxf(wijk.run_ticks(), 1), off_returns])
	await _free(t, parts)


## S6 zonder licht in de meter en zonder echo (FK-2: nooit een slot): de bot
## pompt wat hij heeft, neemt de trap naar de loopbrug, gaat even S5 in en terug,
## het paar staat er weer (LM-13), en zo tot het gemaal vol is. Het slechtste
## geval (0 LP, 12 LP per keer): ≤ 9 keer terug; in de run zonder echo is het
## ≤ 4 (FK-2, `_check_slow_lines`).
func test_deel2_s6_zonder_licht(t) -> void:
	var parts := _wijk(t, 60, false, &"S6", &"S7")
	var wijk = parts[0]
	var bot = parts[1]
	await _run(t, wijk, 11000)
	t.check(wijk.run_over and wijk.room == &"S7", "S6 zonder licht: S7 niet gehaald (stap %s, sub %s, P1 %s, G %d, LP %d, terug %d)" % [
		bot.leg_name(), bot.sub, wijk.p1.position, wijk.gemaal.fill if wijk.gemaal else -1, wijk.meter.value, bot.s6_returns])
	t.check(bot.s6_returns <= 9, "S6 zonder licht: %d keer terug (≤ 9: 100 LP / 12 per keer)" % bot.s6_returns)
	t.note("S6 zonder licht en zonder echo: %d ticks, %d keer terug naar S5" % [wijk.run_ticks(), bot.s6_returns])
	await _free(t, parts)


## S7 vanaf zijn begin (onder de schacht): langs de sokkel naar het luik, een
## neerslag opent het (V-01, SL-04), de benedenvloer, de stuitlijn over de twee
## Dwaallichten (V-01b), de deur van de machinehal (S8). Met echo knalt de echo
## de merken van de neerslag (V-01e). Zonder echo ook (de stuit is van P1).
## En de langzame lijn: wie niet stuit, gaat door het kanaal (trede, kademuur).
## Van het checkpoint tot de arena-deur ≤ 10 s lopen (SL-03): gemeten in de run.
func test_deel2_s7_los(t) -> void:
	for echo_on in [true, false]:
		var parts := _wijk(t, 60, echo_on, &"S7", &"S8")
		var wijk = parts[0]
		var bot = parts[1]
		await _run(t, wijk, 3000)
		var rows: Array = wijk.meetlog.rows
		var label := "S7 echo %s" % ("aan" if echo_on else "uit")
		t.check(wijk.run_over and wijk.room == &"S8", "%s: S8 niet gehaald (stap %s, P1 %s)" % [label, bot.leg_name(), wijk.p1.position])
		t.check(_count(rows, "LUIK") == 1, "%s: luik niet open (%d)" % [label, _count(rows, "LUIK")])
		t.check(bot.lines.get("S7-kanaal", false) and _count(rows, "STUIT") >= 3, "%s: geen stuitlijn (luik + 2 Dwaallichten) (stuits %d, lijn %s)" % [label, _count(rows, "STUIT"), bot.lines.get("S7-kanaal")])
		t.check(_count(rows, "RESPAWN") == 0 and wijk.p1.health == 5, "%s: P1 geraakt of gestorven (leven %d)" % [label, wijk.p1.health])
		var still := _still_per_room(rows)
		t.check(int(still.get("S7", 0)) <= 300, "%s: stilstand %d (MP-1)" % [label, still.get("S7", 0)])
		if echo_on:
			t.check(_count(rows, "ONTPLOFFING") >= 1, "%s: de echo knalde geen merk van de neerslag (V-01e)" % label)
			var rep = FlowReport.from_rows(rows, true)
			var per: float = rep.actions_per_min_room.get("S7", 0.0)
			t.check(per >= 3.0, "%s: %.2f echo-acties per minuut (MP-2 per kamer)" % [label, per])
		t.note("%s: %d ticks, stuits %d, ontploffingen %d, luik door %s" % [label, wijk.run_ticks(), _count(rows, "STUIT"),
			_count(rows, "ONTPLOFFING"), wijk.loader.kamers[&"S7"].inhoud_node.get_node("Luik").opened_by])
		await _free(t, parts)


## SL-03 en GM-11: na het gemaal is het gemaal de respawnplek, en van daar tot
## de arena-deur is ≤ 10 s (600 ticks) lopen. Zoals bij een nieuwe poging: P1
## verschijnt op het checkpoint van S6, het gemaal is vol (de sluis open), het
## paar is verslagen (de wijk is vol: het komt niet terug, LM-13) en het luik is
## al open. Gemeten tot P1 de machinehal (S8) binnenkomt, met de stuitlijn.
func test_deel2_gemaal_tot_arena(t) -> void:
	for echo_on in [true, false]:
		var parts := _wijk(t, 60, echo_on, &"S6", &"S8")
		var wijk = parts[0]
		var bot = parts[1]
		await t.tree.physics_frame
		var s6: Node = wijk.loader.kamers[&"S6"].inhoud_node
		var checkpoint: Node2D = s6.get_node("Checkpoint")
		wijk.gemaal.restore_state(100, true)
		for n in ["Paar1A", "Paar1B"]:
			var e: SliceEnemy = s6.get_node(n)
			e.apply_damage(wijk.sim.tick, 1000, "test")
		var luik = wijk.loader.kamers[&"S7"].inhoud_node.get_node("Luik")
		luik.set_persistent_state(true)
		wijk.p1.respawn_at(checkpoint.spawn_point())
		await t.tree.physics_frame
		var t0: int = wijk.sim.tick
		await _run(t, wijk, t0 + 1200)
		var ticks: int = wijk.sim.tick - t0
		var label := "gemaal → arena-deur, echo %s" % ("aan" if echo_on else "uit")
		t.check(wijk.run_over and wijk.room == &"S8", "%s: S8 niet gehaald (stap %s, P1 %s)" % [label, bot.leg_name(), wijk.p1.position])
		t.check(ticks <= 600, "%s: %d ticks (SL-03, GM-11: ≤ 10 s)" % [label, ticks])
		t.note("%s: %d ticks (%.1f s), stuitlijn %s" % [label, ticks, ticks / 60.0, bot.lines.get("S7-kanaal")])
		await _free(t, parts)


## GM-07 in de lege arena (S8, per D): P1 loopt naar de linkermuur, keert en
## springt op zijn echo; de bounce brengt zijn aanvalsvlak (middelpunt ± 8 px)
## in de hurtbox van het rad (y 100–140 boven de vloer, x `D − 14 … D + 82`
## van de muur, GMB-04). Zo past de arena op de maten van de boss; de boss
## zelf koppelt de Gameplay Programmer. Bij D = 180 hangt het rad 214 px van de
## muur, dus ook dan haalt de bounce het.
func test_deel2_arena_bounce_haalt_rad(t) -> void:
	for d in [60, 90, 120, 180]:
		var parts := _wijk(t, d, true, &"S8", &"S1")
		var wijk = parts[0]
		var bot = parts[1]
		bot.leg = bot._legs.size() - 1
		await t.tree.physics_frame
		var hit := false
		var best_y := INF
		var rad_x0: float = Layout.ARENA_WALL_L + d - 14.0
		var rad_x1: float = Layout.ARENA_WALL_L + d + 82.0
		var rad_y0 := Layout.ARENA_FLOOR - 140.0
		var rad_y1 := Layout.ARENA_FLOOR - 100.0
		for i in 900:
			await t.tree.physics_frame
			if bot.sub != "bounce":
				if bot.sub == "slow" and bot.turned.has("S8-rad"):
					break
				continue
			var p = wijk.p1
			best_y = minf(best_y, p.position.y)
			# Het aanvalsvlak: 20 × 16 px vóór het lichaam, op zijn middelpunt (E-10a).
			var box := wijk.sim.combat.attack_box(p.position, p.motor.facing) as Rect2
			if box.intersects(Rect2(rad_x0, rad_y0, rad_x1 - rad_x0, rad_y1 - rad_y0)):
				hit = true
				break
		t.check(bot.turned.has("S8-rad") and hit, "D=%d S8: de bounce na het keren haalt het rad niet (sub %s, hoogste middelpunt %.0f px boven de vloer, bounce %.0f px van de muur)" % [
			d, bot.sub, Layout.ARENA_FLOOR - best_y, bot.bounce_from_wall.get("S8-rad", -1.0)])
		t.note("D=%d S8: bounce %.0f px van de muur, aanvalsvlak in het rad: %s" % [d, bot.bounce_from_wall.get("S8-rad", -1.0), hit])
		await _free(t, parts)


## S7, de langzame lijn (FK-2, L-10): wie niet stuit, springt het kanaal in en
## loopt over de bodem naar de trede en de kademuur; geen vastlopen, geen
## treffer van een Dwaallicht (het duikt tot 16 px boven de vloer, niet het
## kanaal in), en hooguit 2× de stuitlijn.
func test_deel2_s7_langzame_lijn(t) -> void:
	var fast := _wijk(t, 60, true, &"S7", &"S8")
	await _run(t, fast[0], 3000)
	var fast_ticks: int = fast[0].run_ticks()
	await _free(t, fast)
	var parts := _wijk(t, 60, true, &"S7", &"S8")
	var wijk = parts[0]
	var bot = parts[1]
	bot.kanaal_no_stuit = true
	await _run(t, wijk, 3000)
	t.check(wijk.run_over and not bot.lines.get("S7-kanaal", true), "S7 langzame lijn: S8 niet gehaald of toch gestuit (stap %s, P1 %s)" % [bot.leg_name(), wijk.p1.position])
	t.check(wijk.p1.health == 5, "S7 langzame lijn: P1 geraakt (leven %d)" % wijk.p1.health)
	t.check(wijk.run_ticks() <= 2 * fast_ticks, "S7: langzame lijn %d ticks, stuitlijn %d (FK-2: ≤ 2×)" % [wijk.run_ticks(), fast_ticks])
	var still := _still_per_room(wijk.meetlog.rows)
	t.check(int(still.get("S7", 0)) <= 300, "S7 langzame lijn: stilstand %d (MP-1)" % still.get("S7", 0))
	t.note("S7: stuitlijn %d ticks, langzame lijn (het kanaal door) %d ticks (%.2f×)" % [fast_ticks, wijk.run_ticks(), float(wijk.run_ticks()) / maxf(fast_ticks, 1)])
	await _free(t, parts)
