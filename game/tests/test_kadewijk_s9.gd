extends RefCounted
## Tests voor de Kadewijk, deel 3: S9 de lage kade, de lus terug naar S1
## (T8a, #83; `docs/design/wereld.md` §2.2 S9, SL-02, SL-04, L-14 d–f;
## gdd v0.8.2 §4.3 B1, §4.5, L-12, FK-6, C-15; kamerdoc
## `docs/design/kamers/kadewijk.md` §3f, §6c). Deel 1: `test_kadewijk.gd`,
## deel 2: `test_kadewijk_deel2.gd`.
##
## - Indeling en maten: S9 onder S1–S5 met de buren S8 (de deur van de arena),
##   S5 (de trap naar het plein door de hoek van S5) en S1 (het snelluik); het
##   hoogwater (placeholder voor `s = 2`) dicht bij het laden, het luik dicht,
##   het E-paar verlicht (VJ-06) op 28 px, treden ≤ 45 (FK-6), B1 per D,
##   logbladzijde 3 op een echolijn (L-12: > 100 px boven het looppad).
## - De gescripte geoefende run door S9 (van de deur van de arena tot de gang
##   van S1, `SLICE_EIND`) bij D = 60, 120 en 180, met en zonder echo: het luik
##   (alleen met een neerslag), B1 via de echolijn, logbladzijde 3, MP-1 en
##   MP-2 per kamer, zonder echo hooguit 2× (C-15, FK-2), en keren bij B1
##   ≥ 30 ticks sneller dan de langzame lijn zonder dash en ≤ 2× (gdd §4.3).
## - De gaten zonder echo-actie (visie-review CD, #227, voorstel A): het rustpunt
##   na de boss ≤ ± 12 s, daarna geen gat > ± 10 s; getoetst bij D = 60, bij de
##   andere D gerapporteerd (Lead-review #239).
## - Het hoogwater houdt de lage kade dicht tot `s = 2`; een gewone slag opent
##   het luik niet (SL-04, L-03); de trap naar het plein werkt omhoog en omlaag;
##   het snelluik in S1 is eenrichting (van boven sta je erop).
##
## Elke test maakt een eigen `Progress`; de autoloads en `user://saves` blijven
## onaangeroerd.

const Scene := preload("res://levels/kadewijk/kadewijk.tscn")
const Bot = preload("res://levels/kadewijk/kadewijk_bot.gd")
const Layout = preload("res://levels/kadewijk/kadewijk_layout.gd")
const Kadewijk = preload("res://levels/kadewijk/kadewijk.gd")
const Progress = preload("res://scripts/save/progress.gd")
const FlowReport = preload("res://levels/flowkamer/flow_report.gd")
const SliceEnemy = preload("res://scripts/combat/slice_enemy.gd")
const EnemyData = preload("res://scripts/combat/enemy_data.gd")
const Luik = preload("res://scripts/objects/luik.gd")
const ScriptedInput = preload("res://scripts/input/scripted_input.gd")
const SlowDash = preload("res://tests/slow_dash_input.gd")
const InputBits = preload("res://scripts/input/input_bits.gd")

const TICK_CAP := 8000
## De keerpunten van S9: B2 over de brugpijler en B1 tegen de grachtwand.
const S9_TURNS := ["S9-B2a", "S9-B2b", "S9-B1"]
const MAX_FRAMES := {
	"test_s9_run_d60": 9000,
	"test_s9_zonder_echo_d60": 9000,
	"test_s9_run_d120": 9000,
	"test_s9_zonder_echo_d120": 9000,
	"test_s9_run_d180": 9000,
	"test_s9_run_d90": 9000,
	"test_s9_zonder_echo_d180": 9000,
	"test_s9_met_dash_d60": 20000,
}
## W-12: dash `n` ticks na de afzet van de sprong naar de weg omhoog (gdd §4.6).
const DASH_NS := [4, 8, 12, 16, 20, 24]
## Per D (echo aan / uit): duur van de run en per kamer, voor C-15.
static var _runs := {}


func _wijk(t, d: int, echo_on: bool, start: StringName = &"S9", run_end: StringName = &"SLICE_EIND", input: RefCounted = null, at := Vector2.INF) -> Array:
	var progress := Progress.new()
	progress.name = "TestProgress"
	t.tree.root.add_child(progress)
	# V-01 (besluit LGD #252): wie voorbij de sokkel (S7) begint, heeft de Neerslag al.
	if start == &"S8" or start == &"S9":
		Kadewijk.give_neerslag(progress.state)
	var wijk = Scene.instantiate()
	wijk.tail = d
	wijk.echo_on = echo_on
	wijk.show_hud = false
	wijk.progress = progress
	wijk.start_at = Layout.ROOM_START[start] if at == Vector2.INF else at
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
	await t.tree.physics_frame
	while not wijk.run_over and wijk.sim.tick < cap:
		await t.tree.physics_frame


func _block(wijk, room: StringName, block_name: String) -> StaticBody2D:
	var kamer = wijk.loader.kamers[room]
	if kamer.inhoud_node == null:
		return null
	return kamer.inhoud_node.get_node_or_null("Blokken/" + block_name) as StaticBody2D


func _rect(body: StaticBody2D) -> Rect2:
	if body == null:
		return Rect2()
	var size: Vector2 = (body.get_child(0).shape as RectangleShape2D).size
	return Rect2(body.global_position - size * 0.5, size)


func _count(rows: Array, event: String) -> int:
	var n := 0
	for row in rows:
		if row[2] == event:
			n += 1
	return n


func _still_per_room(rows: Array) -> Dictionary:
	var out := {}
	for row in rows:
		if row[2] == "STIL_EIND" and row[4] == "p1":
			out[row[1]] = maxi(int(out.get(row[1], 0)), int(row[3]))
	return out


## `s = 2` (placeholder): trap 2 is vol, het water zakt, de lage kade komt vrij.
## Zo opent de Gameplay Programmer hem straks bij trap 2 (SL-02, LM-10).
func _open_hoogwater(wijk) -> bool:
	return wijk.set_door(&"S9", "Hoogwater", false)


# --- Indeling en maten ---------------------------------------------------------

## S9 ligt onder S1–S5 (y 360–720), heeft de buren van de layout en
## `wijk_gemaal` = het gemaal van S6; de kamers overlappen niet. Bij het laden:
## het hoogwater dicht, het luik dicht, het E-paar verlicht en op 28 px
## (`paar_e`), logbladzijde 3 op de galerij van B1.
func test_s9_indeling(t) -> void:
	var parts := _wijk(t, 60, true)
	var wijk = parts[0]
	await t.tree.physics_frame
	t.check(wijk.start_errors.is_empty() and wijk.loader.validate().is_empty(),
		"start %s, indeling %s" % [wijk.start_errors, wijk.loader.validate()])
	var r: Rect2 = Layout.ROOMS[&"S9"]
	t.check(r.position.y == 360.0 and r.end.y == Layout.AREA_BOTTOM and r.position.x == 0.0 and r.end.x == Layout.ROOMS[&"S8"].position.x,
		"S9: %s (onder S1–S5, tot de arena)" % r)
	for id: StringName in Layout.ORDER:
		if id != &"S9":
			t.check(not r.intersects(Layout.ROOMS[id]), "S9 overlapt %s" % id)
	var kamer = wijk.loader.kamers[&"S9"]
	t.check(kamer.rect() == r and kamer.wijk_gemaal == &"S6/Gemaal", "S9: kamer %s, wijk_gemaal '%s'" % [kamer.rect(), kamer.wijk_gemaal])
	for pair: Array in [[&"S1", &"S9"], [&"S5", &"S9"], [&"S8", &"S9"]]:
		t.check(Layout.NEIGHBOURS[pair[0]].has(pair[1]) and Layout.NEIGHBOURS[pair[1]].has(pair[0]), "%s–%s geen buren (wederzijds)" % pair)
	var water := _block(wijk, &"S9", "Hoogwater")
	t.check(water != null and water.collision_layer != 0 and _rect(water).end.y == Layout.S9_KADE,
		"S9: hoogwater %s laag %d (dicht tot s = 2, op de lage kade)" % [_rect(water), water.collision_layer if water else -1])
	var inhoud: Node = kamer.inhoud_node
	var luik = inhoud.get_node_or_null("Luik")
	t.check(luik is Luik and not luik.is_open and is_equal_approx(luik.global_position.x, Layout.S9_LUIK.get_center().x),
		"S9: geen dicht luik op x %.0f (%s)" % [Layout.S9_LUIK.get_center().x, luik])
	var a: SliceEnemy = inhoud.get_node("Paar1A")
	var b: SliceEnemy = inhoud.get_node("Paar1B")
	var e := EnemyData.value("gedeeld", "paar_e")
	t.check(a.lit and b.lit and a.enemy_type == SliceEnemy.Type.KADELOPER and b.enemy_type == SliceEnemy.Type.KADELOPER,
		"S9: het E-paar is niet twee verlichte Kadelopers (VJ-06, §2.6)")
	t.check(a.pair_partner == b and is_equal_approx(absf(a.position.x - b.position.x), e)
		and is_equal_approx(a.position.y + a.body_size().y * 0.5, Layout.S9_KADE),
		"S9: E-paar op %.0f px (paar_e %.0f), voeten op %.0f (kade %.0f)" % [absf(a.position.x - b.position.x), e,
		a.position.y + a.body_size().y * 0.5, Layout.S9_KADE])
	var slow: float = a.speed()
	var dark := EnemyData.speed("kadeloper", 60, false)
	t.check(is_equal_approx(slow, dark * 0.5), "S9: verlicht v %.3f (donker %.3f; VJ-06: × 0,5)" % [slow, dark])
	var blad := inhoud.get_node_or_null("Logbladzijde3") as Node2D
	t.check(blad != null and blad.global_position.distance_to(Layout.LOGBLAD_3 + Vector2(0, Layout.HALF_H - 5.0)) < 20.0,
		"S9: logbladzijde 3 niet bij %s (%s)" % [Layout.LOGBLAD_3, blad.global_position if blad else null])
	# Het snelluik in S1: een eenrichtingsvloer achter het begin, buiten de aanloop van B1.
	var luik_s1 := _block(wijk, &"S1", "Snelluik")
	t.check(luik_s1 != null and _rect(luik_s1) == Layout.SNELLUIK and luik_s1.get_child(0).one_way_collision,
		"S1: snelluik %s (eenrichting op de gang)" % _rect(luik_s1))
	t.check(Layout.SNELLUIK.position.x >= Layout.RUN_START.x + Layout.HALF_W and Layout.SNELLUIK.end.x <= Layout.S1_QUAY_LEFT,
		"S1: snelluik %s ligt niet achter het begin (%s)" % [Layout.SNELLUIK, Layout.RUN_START])
	await _free(t, parts)


## De maten van S9 per D (FK-6, gdd §4.3, L-12): de kademuur van 45, het luik in
## een plaat van 16 boven de benedenkade, B1 tegen de grachtwand (aanloop van de
## landing onder het luik tot de wand ≥ D + 24, galerij op 90 vanaf Z, treden
## 30/60/90), de schacht van de galerij tot het snelluik en de trap van de deur
## tot het plein met treden ≤ 45, en logbladzijde 3 > 100 px boven de benedenkade.
func test_s9_maten_per_d(t) -> void:
	t.check(Layout.S9_DOOR_FLOOR == Layout.ARENA_FLOOR, "S9: vloer bij de deur %.0f, arena %.0f" % [Layout.S9_DOOR_FLOOR, Layout.ARENA_FLOOR])
	t.check(Layout.S9_DOOR_FLOOR - Layout.S9_KADE <= 45.0, "S9: kademuur %.0f hoog (FK-6: ≤ 45)" % (Layout.S9_DOOR_FLOOR - Layout.S9_KADE))
	t.check(Layout.S9_LAAG - (Layout.S9_KADE + 16.0) >= 2.0 * Layout.HALF_H,
		"S9: onder de plaat %.0f px vrij (lichaam 30)" % (Layout.S9_LAAG - Layout.S9_KADE - 16.0))
	for d in [60, 90, 120, 180]:
		var parts := _wijk(t, d, true)
		var wijk = parts[0]
		await t.tree.physics_frame
		var z := Layout.keerzone(d)
		var gal := _rect(_block(wijk, &"S9", "Galerij"))
		t.check(is_equal_approx(gal.position.x - Layout.S9_WALL, z) and is_equal_approx(Layout.S9_LAAG - gal.position.y, 90.0)
			and is_equal_approx(gal.end.x, Layout.S9_SHAFT_LEFT),
			"D=%d S9: galerij %s (vanaf Z = %.0f, 90 boven de benedenkade, tot de schacht)" % [d, gal, z])
		var aanloop: float = Layout.S9_LUIK.get_center().x - Layout.S9_WALL
		t.check(aanloop >= Layout.aanloop(d), "D=%d S9: van het luik tot de grachtwand %.0f px (≥ D + 24)" % [d, aanloop])
		for h in [30, 60, 90]:
			var tr := _rect(_block(wijk, &"S9", "B1Trede%d" % h))
			t.check(is_equal_approx(Layout.S9_LAAG - tr.position.y, h) and is_equal_approx(tr.position.x, Layout.S9_WALL)
				and tr.end.x - Layout.S9_WALL < z, "D=%d S9: B1-trede op %d %s (binnen Z)" % [d, h, tr])
		# De brugpijler (B2, twee verdiepingen, zoals S5; Lead-review #231): schacht
		# 480, richels `480 − Z` met een gat van Z (`b2_keerzone`) om en om tegen de
		# wanden, 90 en 180 boven de kade, treden 30/60/90 tegen elke keerwand.
		var zb := Layout.b2_keerzone(d)
		t.check(is_equal_approx(Layout.S9_B2_RIGHT - Layout.S9_B2_LEFT, 480.0), "S9: pijlerschacht %.0f px (480)" % (Layout.S9_B2_RIGHT - Layout.S9_B2_LEFT))
		var r1 := _rect(_block(wijk, &"S9", "PijlerRichel1"))
		var r2 := _rect(_block(wijk, &"S9", "PijlerRichel2"))
		t.check(is_equal_approx(r1.size.x, 480.0 - zb) and is_equal_approx(r1.end.x, Layout.S9_B2_RIGHT)
			and is_equal_approx(r1.position.x - Layout.S9_B2_LEFT, zb) and is_equal_approx(Layout.S9_KADE - r1.position.y, 90.0),
			"D=%d S9 pijler richel 1 %s (breedte 480 − Z = %.0f, gat Z = %.0f bij de pijler, 90 boven de kade)" % [d, r1, 480.0 - zb, zb])
		t.check(is_equal_approx(r2.size.x, 480.0 - zb) and is_equal_approx(r2.position.x, Layout.S9_B2_LEFT)
			and is_equal_approx(Layout.S9_B2_RIGHT - r2.end.x, zb) and is_equal_approx(Layout.S9_KADE - r2.position.y, 180.0)
			and is_equal_approx(r2.position.y, Layout.S9_PIJLER.position.y),
			"D=%d S9 pijler richel 2 %s (breedte 480 − Z, gat Z bij de wand, 180 boven de kade, op de pijler)" % [d, r2])
		for tp: Dictionary in Layout.turn_points(d).slice(9, 11):
			var prefix := String(tp["name"]).trim_prefix("S9-")
			for h in [30, 60, 90]:
				var tb := _rect(_block(wijk, &"S9", "%sTrede%d" % [prefix, h]))
				var wall: float = tp["wall"]
				var at_wall := is_equal_approx(tb.position.x, wall) if int(tp["side"]) < 0 else is_equal_approx(tb.end.x, wall)
				var reach := maxf(absf(tb.position.x - wall), absf(tb.end.x - wall))
				t.check(tb.size.x > 0.0 and at_wall and is_equal_approx(float(tp["floor"]) - tb.position.y, h) and reach < float(tp["z"]),
					"D=%d %s: trede op %d %s (tegen de wand, binnen Z = %.0f)" % [d, tp["name"], h, tb, tp["z"]])
		await _free(t, parts)
	var prev := Layout.S9_UP
	for y: float in Layout.S9_SHAFT + [Layout.S1_FLOOR]:
		t.check(prev - y > 0.0 and prev - y <= 45.0, "S9: schacht %.0f → %.0f (FK-6: ≤ 45)" % [prev, y])
		prev = y
	prev = Layout.S9_DOOR_FLOOR
	for y: float in Layout.S9_TRAP + [Layout.S6_FLOOR]:
		t.check(prev - y > 0.0 and prev - y <= 45.0, "S9: trap naar het plein %.0f → %.0f (FK-6: ≤ 45)" % [prev, y])
		prev = y
	# L-12: zoals het lampglas, 105 px boven het looppad (de benedenkade).
	t.check(Layout.S9_LAAG - Layout.LOGBLAD_3.y > 100.0 and is_equal_approx(Layout.LOGBLAD_3.y + Layout.HALF_H, Layout.S9_UP),
		"logbladzijde 3 %s: %.0f px boven de benedenkade (L-12: > 100), op de galerij" % [Layout.LOGBLAD_3, Layout.S9_LAAG - Layout.LOGBLAD_3.y])


# --- Gescripte runs ------------------------------------------------------------

## Eén run door S9: van het begin (bij de deur van de arena; de boss is van de
## GP) met het hoogwater open, tot P1 door het snelluik in de gang van S1 staat.
func _s9_run(t, d: int, echo_on: bool) -> Array:
	var parts := _wijk(t, d, echo_on)
	var wijk = parts[0]
	var bot = parts[1]
	var breaks: Array = []
	if wijk.echo != null:
		wijk.echo.broke.connect(func(tick: int, at: Vector2) -> void: breaks.append([tick, at]))
	await t.tree.physics_frame
	var opened := _open_hoogwater(wijk)
	await _run(t, wijk)
	var luik = wijk.loader.kamers[&"S9"].inhoud_node.get_node("Luik")
	var rows: Array = wijk.meetlog.rows
	var rep = FlowReport.from_rows(rows, echo_on)
	var label := "D=%d echo %s" % [d, "aan" if echo_on else "uit"]
	var keer := {}
	for n: String in S9_TURNS:
		if bot.turned.has(n) and bot.leg_done.has(n):
			keer[n] = int(bot.leg_done[n]) - int(bot.turned[n])
	_runs["%d_%s" % [d, "aan" if echo_on else "uit"]] = {"ticks": wijk.run_ticks(), "rooms": rep.room_time.duplicate(), "keer": keer}
	t.check(opened, "%s: hoogwater niet te openen (set_door)" % label)
	t.check(wijk.run_over and wijk.room == &"S1" and wijk.slice_end_tick > 0,
		"%s: S1 niet gehaald door het snelluik (tick %d, stap %s, sub %s, kamer %s, P1 %s)" % [
		label, wijk.sim.tick, bot.leg_name(), bot.sub, wijk.room, wijk.p1.position])
	t.check(wijk.start_errors.is_empty(), "start: %s" % [wijk.start_errors])
	t.check(_count(rows, "SLICE_EIND") == 1, "%s: %d keer SLICE_EIND" % [label, _count(rows, "SLICE_EIND")])
	t.check(_count(rows, "LUIK") == 1 and bot.lines.get("S9-luik", false), "%s: luik niet open met een neerslag (%d)" % [label, _count(rows, "LUIK")])
	# V-01d (#227): met echo breekt de echo nergens in S9, ook niet op het luik;
	# hij speelt de neerslag af op de schaduwklep. Zonder echo geen schaduwklep.
	t.check(breaks.is_empty(), "%s: de echo brak %d× (%s)" % [label, breaks.size(), breaks])
	if echo_on:
		t.check(luik.schaduwklep_weg_by == "echo" and luik.schaduwklep_weg_tick == luik.opened_tick + d,
			"%s: schaduwklep weg op %d door %s (verwacht breuk %d + D door de echo)" % [label, luik.schaduwklep_weg_tick, luik.schaduwklep_weg_by, luik.opened_tick])
	else:
		t.check(luik.schaduwklep_weg_tick < 0, "%s: schaduwklep zonder echo (weg op %d)" % [label, luik.schaduwklep_weg_tick])
	t.check(wijk.logblad_3_tick > 0, "%s: logbladzijde 3 niet gehaald" % label)
	t.check(_count(rows, "RESPAWN") == 0 and wijk.p1.health > 0, "%s: P1 stierf (%d respawns)" % [label, _count(rows, "RESPAWN")])
	t.check(wijk.most_at_once <= 5, "%s: %d vijanden tegelijk (L-13 f)" % [label, wijk.most_at_once])
	# Het E-paar is verslagen; het Dwaallicht (#227) gaat alleen met de echo dood
	# (de merksprong), zonder echo blijft het gestund achter.
	var walkers: Array = wijk.enemies_in(&"S9").filter(func(e: Node) -> bool: return e.enemy_type == SliceEnemy.Type.KADELOPER)
	t.check(walkers.is_empty(), "%s: %d Kadelopers over in S9" % [label, walkers.size()])
	var still := _still_per_room(rows)
	for id: StringName in [&"S9", &"S1"]:
		t.check(int(still.get(String(id), 0)) <= 300, "%s %s: langste stilstand %d ticks (MP-1 ≤ 300)" % [label, id, still.get(String(id), 0)])
	t.note("%s: S9 → gang S1 %d ticks (%.1f s; %s), MP-1 %s, LP %d, logbladzijde 3 tick %d, keerpunten %s, treffers P1 %d, lijnen %s" % [
		label, wijk.run_ticks(), wijk.run_ticks() / 60.0, rep.room_time, still, rep.lp_total, wijk.logblad_3_tick, keer,
		5 - wijk.p1.health, bot.lines])
	t.note("%s: luik open op %d, schaduwklep weg op %d (%s), echo-breuken %d" % [label, luik.opened_tick, luik.schaduwklep_weg_tick,
		luik.schaduwklep_weg_by if luik.schaduwklep_weg_by != "" else "geen", breaks.size()])
	return [parts, rep]


## De gaten zonder echo-actie in S9 (visie-review CD, #227, voorstel A): het
## eerste stuk (van de deur tot de eerste echo-actie) is het rustpunt na de boss,
## ≤ `RUST_MAX`; daarna geen gat > `GAT_MAX` (ook niet van de laatste actie tot
## `SLICE_EIND`). Een actie zoals MP-2 (`FlowReport.actions`).
const RUST_MAX := 720   ## ± 12 s
const GAT_MAX := 600    ## ± 10 s


func _gaps(rep) -> Array:
	var out: Array = []
	var prev: int = rep.start
	for a: Array in rep.actions:
		out.append(int(a[0]) - prev)
		prev = int(a[0])
	out.append(rep.end - prev)
	return out


func _check_echo_run(t, d: int, out: Array) -> void:
	var bot = out[0][1]
	var rep = out[1]
	var gaps := _gaps(rep)
	var rest := gaps.slice(1)
	# Hard bij D = 60 (de gekozen D); bij de andere D rapport (Lead-review #239).
	if d == 60:
		t.check(gaps.size() >= 2 and gaps[0] <= RUST_MAX, "D=%d S9: rustpunt (deur → eerste echo-actie) %d ticks (≤ %d, ± 12 s; CD #227)" % [d, gaps[0] if gaps.size() else -1, RUST_MAX])
		t.check(not rest.is_empty() and rest.max() <= GAT_MAX, "D=%d S9: langste gat buiten het rustpunt %d ticks (≤ %d, ± 10 s; CD #227), gaten %s" % [d, rest.max() if rest.size() else -1, GAT_MAX, gaps])
	else:
		t.note("D=%d S9: rustpunt %d (norm bij D = 60: ≤ %d), langste gat daarna %d (≤ %d) (rapport)" % [d, gaps[0] if gaps.size() else -1, RUST_MAX, rest.max() if rest.size() else -1, GAT_MAX])
	t.note("D=%d S9: gaten zonder echo-actie %s ticks (rustpunt %.1f s, daarna langste %.1f s)" % [d, gaps, gaps[0] / 60.0, rest.max() / 60.0 if rest.size() else 0.0])
	for n: String in S9_TURNS:
		t.check(bot.lines.get(n, false), "D=%d %s: niet via de echolijn (L-08)" % [d, n])
	var per: float = rep.actions_per_min_room.get("S9", 0.0)
	t.check(per >= 3.0, "D=%d S9: %.2f echo-acties per minuut (MP-2 per kamer, L-11)" % [d, per])
	t.check(rep.longest_gap <= FlowReport.MP2_WINDOW, "D=%d S9: %d ticks zonder echo-actie (MP-2/L-11: ≤ 40 s)" % [d, rep.longest_gap])
	t.note("D=%d S9: MP-2 %.1f/min %s, langste gat %d (%.1f s), MP-3 %.0f %% van %d, MP-4 %.0f %%, MP-6 %.0f %% van %d LP, bounce %s landing %s (van de wand)" % [
		d, rep.actions_per_min, rep.actions_per_min_room, rep.longest_gap, rep.longest_gap / 60.0, rep.landings_without_still * 100.0,
		rep.landings, rep.echo_empty_share * 100.0, rep.lp_echo_share * 100.0, rep.lp_total,
		_pick(bot.bounce_from_wall, S9_TURNS), _pick(bot.landed_from_wall, S9_TURNS)])


func _pick(dict: Dictionary, keys: Array) -> Dictionary:
	var out := {}
	for k in keys:
		if dict.has(k):
			out[k] = dict[k]
	return out


## C-15/FK-2 voor S9 en de eis bij keren bij elk keerpunt (gdd §4.3: ≥ 30
## sneller, ≤ 2×; B1 en B2 zoals in S1 en S5, hier opnieuw gemeten).
func _check_slow_lines(t, d: int) -> void:
	var on: Dictionary = _runs.get("%d_aan" % d, {})
	var off: Dictionary = _runs.get("%d_uit" % d, {})
	t.check(not on.is_empty() and not off.is_empty(), "D=%d: run met en zonder echo nodig" % d)
	if on.is_empty() or off.is_empty():
		return
	t.check(off["ticks"] <= 2 * on["ticks"], "D=%d S9: zonder echo %d ticks, met %d (C-15: ≤ 2×)" % [d, off["ticks"], on["ticks"]])
	t.note("D=%d S9: zonder echo %d tegen %d ticks (%.2f×, marge %d ticks tot 2×)" % [
		d, off["ticks"], on["ticks"], float(off["ticks"]) / maxf(on["ticks"], 1), 2 * int(on["ticks"]) - int(off["ticks"])])
	for n: String in S9_TURNS:
		var keer := int(on["keer"].get(n, -1))
		var slow := int(off["keer"].get(n, -1))
		t.check(keer > 0 and slow - keer >= 30 and slow <= 2 * keer,
			"D=%d %s: keren %d, langzame lijn zonder dash %d ticks vanaf de wand (gdd §4.3: ≥ 30 sneller, ≤ 2×)" % [d, n, keer, slow])
		t.note("D=%d %s: keren %d, langzame lijn zonder dash %d (+%d, %.2f×)" % [d, n, keer, slow, slow - keer, float(slow) / maxf(keer, 1)])


func test_s9_run_d60(t) -> void:
	var out := await _s9_run(t, 60, true)
	_check_echo_run(t, 60, out)
	await _free(t, out[0])


func test_s9_zonder_echo_d60(t) -> void:
	var out := await _s9_run(t, 60, false)
	await _free(t, out[0])
	_check_slow_lines(t, 60)


func test_s9_run_d120(t) -> void:
	var out := await _s9_run(t, 120, true)
	_check_echo_run(t, 120, out)
	await _free(t, out[0])


## D = 90 (met echo): de echo breekt 0× in S9 (V-01d, #227).
func test_s9_run_d90(t) -> void:
	var out := await _s9_run(t, 90, true)
	_check_echo_run(t, 90, out)
	await _free(t, out[0])


func test_s9_zonder_echo_d120(t) -> void:
	var out := await _s9_run(t, 120, false)
	await _free(t, out[0])
	_check_slow_lines(t, 120)


func test_s9_run_d180(t) -> void:
	var out := await _s9_run(t, 180, true)
	_check_echo_run(t, 180, out)
	await _free(t, out[0])


func test_s9_zonder_echo_d180(t) -> void:
	var out := await _s9_run(t, 180, false)
	await _free(t, out[0])
	_check_slow_lines(t, 180)


# --- W-12: de langzame lijn met dash (gdd v0.8.2 §4.8.7; Lead-review #231) ----

## Waar een meting van een keerpunt begint: B2 van de pijler op de kade rechts
## van de pijlerwand (aanloop 620 px), B1 op de benedenkade onder het luik.
const KEER_START := {
	"S9-B2a": Vector2(3440, Layout.S9_KADE - Layout.HALF_H),
	"S9-B1": Vector2(580, Layout.S9_LAAG - Layout.HALF_H),
}


## Vanaf `KEER_START[from_leg]` tot de bot `legs` heeft afgerond. Geeft per stap
## [ticks van keren tot klaar, mist] (-1 als de echolijn gevraagd was maar niet lukte).
func _keer_run(t, echo_on: bool, from_leg: String, legs: Array, dash_n: int) -> Dictionary:
	var parts := _wijk(t, 60, echo_on, &"S9", &"SLICE_EIND", null, KEER_START[from_leg])
	var wijk = parts[0]
	var bot = parts[1]
	bot.leg = bot._legs.find(bot._legs.filter(func(l: Array) -> bool: return l[0] == from_leg)[0])
	var source := SlowDash.new(bot, wijk, Layout.turn_points(60), dash_n)
	wijk.input_override = source
	wijk.p1.input_source = source
	while not bot.leg_done.has(legs[-1]) and wijk.sim.tick < 4000:
		await t.tree.physics_frame
	var out := {}
	for leg: String in legs:
		var ticks := -1
		if bot.leg_done.has(leg) and bot.turned.has(leg):
			ticks = int(bot.leg_done[leg]) - int(bot.turned[leg])
		if echo_on and not bot.lines.get(leg, false):
			ticks = -1
		out[leg] = [ticks, source.missed.get(leg, false)]
	await _free(t, parts)
	return out


## Bij D = 60 voor de drie keerpunten van S9: keren, de langzame lijn zonder dash
## (≥ 30 trager, ≤ 2×) en de snelste langzame lijn met een dash n = 4 … 24 ticks
## na de afzet (≥ 20 trager, ≤ 2×). Bij de andere D dekken de maatcheck en de
## tests van S5 (B2) en S1 (B1) het, want de maten zijn gelijk.
func test_s9_met_dash_d60(t) -> void:
	for group: Array in [["S9-B2a", ["S9-B2a", "S9-B2b"]], ["S9-B1", ["S9-B1"]]]:
		var keer: Dictionary = await _keer_run(t, true, group[0], group[1], -1)
		var plain: Dictionary = await _keer_run(t, false, group[0], group[1], -1)
		var per := {}
		var fastest := {}
		for n: int in DASH_NS:
			var r: Dictionary = await _keer_run(t, false, group[0], group[1], n)
			for leg: String in group[1]:
				var v: Array = r[leg]
				if not per.has(leg):
					per[leg] = {}
				per[leg][n] = "mist" if v[1] or v[0] < 0 else v[0]
				if not v[1] and v[0] > 0 and (not fastest.has(leg) or v[0] < fastest[leg]):
					fastest[leg] = v[0]
		for leg: String in group[1]:
			var k: int = keer[leg][0]
			var p: int = plain[leg][0]
			var f: int = fastest.get(leg, -1)
			t.check(k > 0, "D=60 %s: keren niet gemeten (echolijn)" % leg)
			t.check(p > 0 and p - k >= 30 and p <= 2 * k, "D=60 %s: keren %d, langzame lijn zonder dash %d (≥ 30 trager, ≤ 2×)" % [leg, k, p])
			t.check(f > 0, "D=60 %s: geen dash-variant haalt de weg omhoog (%s)" % [leg, per.get(leg)])
			t.check(f - k >= 20 and f <= 2 * k,
				"D=60 %s: keren %d, snelste langzame lijn met dash (n = 4 … 24) %d (gdd §4.8.7: ≥ 20 trager, ≤ 2×)" % [leg, k, f])
			t.note("D=60 %s: keren %d, zonder dash %d, met dash na n ticks %s: snelste %d (+%d, %.2f×)" % [
				leg, k, p, per.get(leg), f, f - k, float(f) / maxf(k, 1)])


# --- Poorten en de trap ----------------------------------------------------------

## Zolang het hoogwater er staat (`s < 2`), komt P1 niet op de lage kade: de bot
## loopt ertegen en blijft bij de deur (L-14 d: de stand opent de route).
func test_s9_hoogwater_dicht(t) -> void:
	var parts := _wijk(t, 60, true)
	var wijk = parts[0]
	var bot = parts[1]
	await _run(t, wijk, 600)
	t.check(not wijk.run_over and wijk.p1.position.x > Layout.S9_STEP_X and bot.leg_name() == "S9-kade",
		"S9 met hoogwater: P1 op %s, stap %s (verwacht bij de deur)" % [wijk.p1.position, bot.leg_name()])
	await _free(t, parts)


## Het luik (SL-04, L-03): op het luik staan, springen en gewoon slaan opent het
## niet; alleen een neerslag. P1 begint op de lage kade vlak bij het luik.
func test_s9_luik_alleen_neerslag(t) -> void:
	var a := InputBits.ATTACK
	var j := InputBits.JUMP
	var segments: Array = [[40, 0]]
	for k in 6:
		segments.append_array([[1, a], [21, 0]])
	segments.append_array([[3, j], [3, 0], [1, a], [40, 0]])
	var input := ScriptedInput.new(segments)
	var parts := _wijk(t, 60, false, &"S9", &"SLICE_EIND", input)
	var wijk = parts[0]
	await t.tree.physics_frame
	wijk.p1.respawn_at(Vector2(Layout.S9_LUIK.get_center().x, Layout.S9_KADE - Layout.HALF_H))
	for i in input.length() + 20:
		await t.tree.physics_frame
	var luik = wijk.loader.kamers[&"S9"].inhoud_node.get_node("Luik")
	t.check(not luik.is_open and absf(wijk.p1.position.y - (Layout.S9_KADE - Layout.HALF_H)) < 1.5,
		"S9: het luik ging open zonder neerslag (open %s, P1 %s)" % [luik.is_open, wijk.p1.position])
	await _free(t, parts)


## De trap terug naar het plein (voor trap 2, SL-02): van de vloer bij de deur
## om en om de treden op, door de hoek van S5 het plein op (S6), en terug naar
## beneden. Geen vastlopen, geen stilstand > 300.
func test_s9_trap_naar_plein(t) -> void:
	var parts := _wijk(t, 60, true)
	var wijk = parts[0]
	var bot = parts[1]
	bot.leg = bot._legs.find(bot._legs.filter(func(l: Array) -> bool: return l[0] == "S9-trap")[0])
	await t.tree.physics_frame
	var t0: int = wijk.sim.tick
	while not bot.leg_done.has("S9-trap-af") and wijk.sim.tick < t0 + 2400:
		await t.tree.physics_frame
	var up := int(bot.leg_done.get("S9-trap", -1)) - t0
	var down := int(bot.leg_done.get("S9-trap-af", -1)) - int(bot.leg_done.get("S9-trap", 0))
	var seen := []
	for change: Array in wijk.room_changes:
		seen.append(change[2])
	t.check(bot.leg_done.has("S9-trap") and seen.has(&"S6"), "S9: het plein niet gehaald over de trap (stap %s, P1 %s, kamers %s)" % [bot.leg_name(), wijk.p1.position, seen])
	t.check(bot.leg_done.has("S9-trap-af") and wijk.room == &"S9", "S9: niet terug van het plein naar de deur (stap %s, P1 %s)" % [bot.leg_name(), wijk.p1.position])
	var still := _still_per_room(wijk.meetlog.rows)
	for id in still:
		t.check(int(still[id]) <= 300, "S9 trap: stilstand %d in %s (MP-1)" % [still[id], id])
	t.note("S9 trap naar het plein: omhoog %d ticks (%.1f s), omlaag %d ticks, kamers %s" % [up, up / 60.0, down, seen])
	await _free(t, parts)


## Het snelluik in S1 is eenrichting: wie erop staat (van boven), valt er niet
## door; van onder kom je erdoor (de run).
func test_s9_snelluik_eenrichting(t) -> void:
	var input := ScriptedInput.new([[90, 0]])
	var parts := _wijk(t, 60, true, &"S1", &"S4", input)
	var wijk = parts[0]
	await t.tree.physics_frame
	wijk.p1.respawn_at(Vector2(Layout.SNELLUIK.get_center().x, Layout.S1_FLOOR - Layout.HALF_H))
	for i in 90:
		await t.tree.physics_frame
	t.check(wijk.room == &"S1" and wijk.p1.motor.on_floor and absf(wijk.p1.position.y - (Layout.S1_FLOOR - Layout.HALF_H)) < 1.5,
		"S1: P1 op het snelluik zakte erdoor (P1 %s, kamer %s)" % [wijk.p1.position, wijk.room])
	await _free(t, parts)
