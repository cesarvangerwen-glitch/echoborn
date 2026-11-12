extends RefCounted
## Tests voor de Kadewijk, deel 1: S1–S4 als grijze kamers (T8a, #83;
## `docs/design/wereld.md` §2.2–§2.6, gdd v0.8.1 §4.3, §4.5, §4.8.5;
## `docs/design/kamers/kadewijk.md`).
##
## - De gebiedsscène laadt met de AreaLoader (kamers, buren, inhoud), de maten
##   die van D afhangen volgen de formules (keerzone, trede op 90, B3-blok), en
##   de vijanden staan zoals `slice-vijanden-en-boss.md` §2.6 (paren, afstanden).
## - De gescripte geoefende run (`kadewijk_bot.gd`) haalt bij D = 60 het einde
##   van S4, neemt elke echolijn en haalt per kamer MP-1 en de normen MP-2,
##   MP-4 en MP-6 (gdd §4.5); met echo uit haalt hij het ook, hooguit 2× zo lang
##   (C-15, FK-2), en bij elk keerpunt is keren ≥ 30 ticks sneller dan de
##   langzame lijn en die ≤ 2× keren (gdd §4.3: in de slice bij elke D).
## - 120 en 180 draaien als regressie (de eis bij keren ook), elk als eigen test
##   (een run duurt ± 3000–3900 ticks; de runner geeft een test 7200 frames).
## - S3: golf 2 pas na golf 1 (merk of op) en nooit meer dan 5 vijanden (L-13).
## - SL-03: vóór het gemaal respawnt P1 op S1.
##
## Elke test maakt een eigen `Progress`; de autoloads en `user://saves` blijven
## onaangeroerd.

const Scene := preload("res://levels/kadewijk/kadewijk.tscn")
const Bot = preload("res://levels/kadewijk/kadewijk_bot.gd")
const Layout = preload("res://levels/kadewijk/kadewijk_layout.gd")
const Progress = preload("res://scripts/save/progress.gd")
const FlowReport = preload("res://levels/flowkamer/flow_report.gd")
const ScriptedInput = preload("res://scripts/input/scripted_input.gd")
const SliceEnemy = preload("res://scripts/combat/slice_enemy.gd")
const EnemyData = preload("res://scripts/combat/enemy_data.gd")
const Zone = preload("res://scripts/objects/zone.gd")

const TICK_CAP := 7000
## Per D (echo aan / uit): duur van de run, per kamer, en per keerpunt
## (keren of langzame lijn, vanaf de wand), voor C-15 en de eis bij keren.
static var _runs := {}


## Bouwt de wijk; `input` = null geeft de bot. Geeft [wijk, bot, progress].
func _wijk(t, d: int, echo_on: bool, start: StringName = &"S1", input: RefCounted = null) -> Array:
	var progress := Progress.new()
	progress.name = "TestProgress"
	t.tree.root.add_child(progress)
	var wijk = Scene.instantiate()
	wijk.tail = d
	wijk.echo_on = echo_on
	wijk.show_hud = false
	wijk.progress = progress
	wijk.start_at = Layout.ROOM_START[start]
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


## Speelt tot RUN_EIND, of tot P1 kamer `until` binnenkomt. Telt de kamerwissels.
func _run(t, wijk, until: StringName = &"") -> void:
	while not wijk.run_over and wijk.sim.tick < TICK_CAP:
		await t.tree.physics_frame
		if until != &"" and wijk.room == until:
			return


## Langste stilstand van P1 per kamer (MP-1), uit de `STIL_EIND`-regels.
func _still_per_room(rows: Array) -> Dictionary:
	var out := {}
	for row in rows:
		if row[2] == "STIL_EIND" and row[4] == "p1":
			out[row[1]] = maxi(int(out.get(row[1], 0)), int(row[3]))
	return out


func _respawns(rows: Array) -> int:
	var n := 0
	for row in rows:
		if row[2] == "RESPAWN":
			n += 1
	return n


func _block(wijk, room: StringName, block_name: String) -> Rect2:
	var kamer = wijk.loader.kamers[room]
	if kamer.inhoud_node == null:
		return Rect2()
	var body: StaticBody2D = kamer.inhoud_node.get_node_or_null("Blokken/" + block_name)
	if body == null:
		return Rect2()
	var size: Vector2 = (body.get_child(0).shape as RectangleShape2D).size
	return Rect2(body.global_position - size * 0.5, size)


# --- Indeling en maten ---------------------------------------------------------

## De scène laadt zonder fouten; de kamers zijn die van de layout, buren
## wederzijds; P1 begint in S1 met S1 en S2 geladen; geen zones (L-06).
func test_kadewijk_loads(t) -> void:
	var parts := _wijk(t, 60, true)
	var wijk = parts[0]
	await t.tree.physics_frame
	t.check(wijk.start_errors.is_empty(), "start: %s" % [wijk.start_errors])
	t.check(wijk.loader.validate().is_empty(), "indeling: %s" % [wijk.loader.validate()])
	t.check(wijk.loader.kamers.size() == Layout.ORDER.size(), "%d kamers (verwacht %d)" % [wijk.loader.kamers.size(), Layout.ORDER.size()])
	for id: StringName in Layout.ORDER:
		var kamer = wijk.loader.kamers.get(id)
		t.check(kamer != null and kamer.rect() == Layout.ROOMS[id], "%s: rechthoek %s (layout %s)" % [id, kamer.rect() if kamer else null, Layout.ROOMS[id]])
		if kamer:
			var want := PackedStringArray()
			for b: StringName in Layout.NEIGHBOURS[id]:
				want.append(String(b))
			t.check(kamer.buren == want, "%s: buren %s (layout %s)" % [id, kamer.buren, want])
			t.check(kamer.inhoud != null, "%s: geen inhoud" % id)
		t.check(Layout.room_of(Layout.ROOM_START[id]) == id, "begin van %s ligt niet in %s" % [id, id])
	t.check(wijk.room == &"S1" and wijk.loader.is_loaded(&"S1") and wijk.loader.is_loaded(&"S2") \
		and not wijk.loader.is_loaded(&"S3"), "start: kamer %s, geladen %s" % [wijk.room, wijk.loader.loaded_ids()])
	var zones: Array = wijk.find_children("*", "", true, false).filter(func(n: Node) -> bool: return n is Zone)
	t.check(zones.is_empty(), "zones in de Kadewijk (L-06: geen FelLicht, geen Schaduwgevaar): %s" % [zones])
	await _free(t, parts)


## Wat van D afhangt, volgt de formule (gdd §4.3, §4.8.5): de galerij van B1
## begint op Z = D + 30 van de keerwand en reikt tot 480; de trede op 90; het
## B3-blok `max(D − 60, 0)`. En de vaste maten: B1-aanloop ≥ D + 24 (gang van
## ≥ 320), B3-gat ≥ 150, B4 160 breed en 90 diep, ≥ 40 px vlak vóór de rand,
## ≥ 180 px vrij erboven, de vlakke markt ≥ D + 24 (L-13 b).
func test_kadewijk_maten_per_d(t) -> void:
	for d in [60, 90, 120, 180]:
		var parts := _wijk(t, d, true, &"S2")
		var wijk = parts[0]
		await t.tree.physics_frame
		var z := float(d + 30)
		var s1 := _block(wijk, &"S1", "Galerij")
		t.check(is_equal_approx(s1.position.x - Layout.S1_WALL, z) and is_equal_approx(s1.end.x - Layout.S1_WALL, 480.0)
			and is_equal_approx(Layout.S1_FLOOR - s1.position.y, 90.0),
			"D=%d S1: galerij %s (Z = %.0f tot 480, 90 hoog)" % [d, s1, z])
		var s2 := _block(wijk, &"S2", "Galerij70")
		t.check(is_equal_approx(s2.position.x - Layout.S2_PIJLER, z) and is_equal_approx(s2.end.x - Layout.S2_PIJLER, 480.0),
			"D=%d S2: galerij van B1 %s (Z = %.0f tot 480)" % [d, s2, z])
		var t90 := _block(wijk, &"S1", "B1Trede90")
		var want90 := 40.0 if d <= 60 else z - 14.0
		t.check(is_equal_approx(t90.size.x, want90) and t90.end.x < Layout.S1_WALL + z,
			"D=%d S1: trede op 90 %s (breedte %.0f, binnen de keerzone)" % [d, t90, want90])
		var block := _block(wijk, &"S2", "B3Blok")
		var wall := _block(wijk, &"S2", "B3Wand")
		if d == 60:
			t.check(block == Rect2() and is_equal_approx(wall.position.x, Layout.B3_BLOCK_LEFT),
				"D=60 S2: B3-blok %s, wand op %.0f (verwacht geen blok, wand op %.0f)" % [block, wall.position.x, Layout.B3_BLOCK_LEFT])
		else:
			t.check(is_equal_approx(block.size.x, d - 60.0) and is_equal_approx(block.size.y, 45.0)
				and is_equal_approx(wall.position.x, Layout.B3_BLOCK_LEFT + d - 60.0),
				"D=%d S2: B3-blok %s (verwacht %d × 45), wand op %.0f" % [d, block, d - 60, wall.position.x])
		var gap := Layout.B3_BLOCK_LEFT - Layout.B3_GALLERY_TIP
		t.check(gap >= 150.0 and is_equal_approx(Layout.B3_BLOCK_LEFT - Layout.B3_ENTRANCE, 190.0),
			"B3: kom %.0f px, gat %.0f px (190, ≥ 150)" % [Layout.B3_BLOCK_LEFT - Layout.B3_ENTRANCE, gap])
		await _free(t, parts)
	var aanloop_s1 := Layout.S1_QUAY_LEFT - Layout.S1_WALL
	var aanloop_s2 := Layout.B3_GALLERY_TIP - Layout.S2_PIJLER
	t.check(aanloop_s1 >= 320.0 and aanloop_s2 >= 320.0 and aanloop_s2 >= Layout.aanloop(180),
		"B1-gang S1 %.0f, S2 %.0f px (≥ 320 en ≥ D + 24 voor D tot 180)" % [aanloop_s1, aanloop_s2])
	t.check(is_equal_approx(Layout.B4_FAR_EDGE - Layout.B4_NEAR_EDGE, 160.0) and is_equal_approx(Layout.KLOOF_BOTTOM - Layout.S4_FLOOR, 90.0)
		and Layout.B4_NEAR_EDGE - Layout.ROOMS[&"S4"].position.x >= 40.0 and Layout.S4_FLOOR >= 180.0,
		"B4: kloof %.0f × %.0f, aanloop %.0f, vrij %.0f" % [Layout.B4_FAR_EDGE - Layout.B4_NEAR_EDGE,
		Layout.KLOOF_BOTTOM - Layout.S4_FLOOR, Layout.B4_NEAR_EDGE - Layout.ROOMS[&"S4"].position.x, Layout.S4_FLOOR])
	var markt := Layout.ROOMS[&"S3"].end.x - Layout.S3_LEFT
	t.check(markt >= Layout.aanloop(180), "S3: vlakke markt %.0f px (L-13 b: ≥ D + 24)" % markt)


## De vijanden van `slice-vijanden-en-boss.md` §2.6: S2 een E-paar van
## Kadelopers; S3 golf 1 een E-paar + een losse ≥ 160 px van het paar, golf 2
## de Schotdrager in een E-paar met een Kadeloper + een losse; S4 één Kadeloper
## aan de overkant. Paren op `paar_e` (28 px, ≤ E = 32) met hun paargenoot.
func test_kadewijk_vijanden_volgens_2_6(t) -> void:
	var parts := _wijk(t, 60, true, &"S3")
	var wijk = parts[0]
	await t.tree.physics_frame
	var e := EnemyData.value("gedeeld", "paar_e")
	var s2: Node = wijk.loader.kamers[&"S2"].inhoud_node
	var s3: Node = wijk.loader.kamers[&"S3"].inhoud_node
	var s4: Node = wijk.loader.kamers[&"S4"].inhoud_node
	var pairs := [[s2, "Paar1A", "Paar1B"], [s3, "Golf1/Paar1A", "Golf1/Paar1B"], [s3, "Golf2/Paar1A", "Golf2/Paar1B"]]
	for p: Array in pairs:
		var a: SliceEnemy = p[0].get_node(p[1])
		var b: SliceEnemy = p[0].get_node(p[2])
		var gap := absf(a.position.x - b.position.x)
		t.check(a.pair_partner == b and b.pair_partner == a and is_equal_approx(a.pair_distance, e)
			and is_equal_approx(gap, e) and gap <= 32.0, "%s: paar %s/%s op %.0f px (paar_e %.0f, ≤ 32)" % [p[0].name, p[1], p[2], gap, e])
	for node: SliceEnemy in [s2.get_node("Paar1A"), s2.get_node("Paar1B"), s4.get_node("Overkant")]:
		t.check(node.enemy_type == SliceEnemy.Type.KADELOPER, "%s is geen Kadeloper" % node.name)
	t.check(s3.get_node("Golf2/Paar1A").enemy_type == SliceEnemy.Type.SCHOTDRAGER, "golf 2: geen Schotdrager in het paar")
	var types := 0
	for g in ["Golf1", "Golf2"]:
		var group: Node = s3.get_node(g)
		t.check(group.get_child_count() == 3, "%s: %d vijanden (§2.6: 3)" % [g, group.get_child_count()])
		var pair_end := maxf(group.get_node("Paar1A").position.x, group.get_node("Paar1B").position.x)
		var pair_start := minf(group.get_node("Paar1A").position.x, group.get_node("Paar1B").position.x)
		var loose: float = group.get_node("Los").position.x
		var apart := minf(absf(loose - pair_end), absf(loose - pair_start))
		t.check(apart >= 160.0, "%s: losse %.0f px van het paar (L-13 d: ≥ 160)" % [g, apart])
		for child in group.get_children():
			if child.enemy_type != SliceEnemy.Type.KADELOPER:
				types += 1
	t.check(types == 1, "S3: %d vijanden die geen Kadeloper zijn (verwacht 1 Schotdrager)" % types)
	var golf_1_left := INF
	for child in s3.get_node("Golf1").get_children():
		golf_1_left = minf(golf_1_left, child.position.x)
	for child in s3.get_node("Golf2").get_children():
		t.check(child.position.x < golf_1_left, "golf 2 (%s op %.0f) niet aan de kant van de ingang" % [child.name, child.position.x])
	t.check(s4.get_node("Overkant").position.x - Layout.B4_FAR_EDGE >= 80.0 + 30.0,
		"S4: Kadeloper %.0f px voorbij de rand" % (s4.get_node("Overkant").position.x - Layout.B4_FAR_EDGE))
	await _free(t, parts)


# --- Gescripte runs ------------------------------------------------------------

## Eén volledige run S1 → einde S4; bewaart de cijfers in `_runs` en geeft het rapport.
func _full_run(t, d: int, echo_on: bool) -> Array:
	var parts := _wijk(t, d, echo_on)
	var wijk = parts[0]
	var bot = parts[1]
	await _run(t, wijk)
	var rep = FlowReport.from_rows(wijk.meetlog.rows, echo_on)
	var keer := {}
	for tp: Dictionary in Layout.turn_points(d):
		var n: String = tp["name"]
		if bot.turned.has(n) and bot.leg_done.has(n):
			keer[n] = int(bot.leg_done[n]) - int(bot.turned[n])
	_runs["%d_%s" % [d, "aan" if echo_on else "uit"]] = {"ticks": wijk.run_ticks(), "rooms": rep.room_time.duplicate(), "keer": keer}
	t.check(wijk.run_over, "D=%d echo %s: einde van S4 niet gehaald (tick %d, stap %s, kamer %s, P1 %s)" % [
		d, "aan" if echo_on else "uit", wijk.sim.tick, bot.leg_name(), wijk.room, wijk.p1.position])
	t.check(wijk.start_errors.is_empty(), "start: %s" % [wijk.start_errors])
	var rooms_seen := []
	for change: Array in wijk.room_changes:
		rooms_seen.append(change[2])
	t.check(rooms_seen == [&"S2", &"S3", &"S4"], "kamerwissels %s (verwacht S2, S3, S4)" % [rooms_seen])
	t.check(_respawns(wijk.meetlog.rows) == 0 and wijk.p1.health > 0, "D=%d: P1 stierf (%d respawns)" % [d, _respawns(wijk.meetlog.rows)])
	t.check(wijk.most_at_once <= 5, "D=%d: %d vijanden tegelijk (L-13 f: ≤ 5)" % [d, wijk.most_at_once])
	t.check(wijk.wave == 2 and wijk.wave_2_tick > 0, "D=%d: golf 2 kwam niet (wave %d)" % [d, wijk.wave])
	var still := _still_per_room(wijk.meetlog.rows)
	for id: StringName in Layout.ORDER:
		t.check(int(still.get(String(id), 0)) <= 300, "D=%d %s: langste stilstand %d ticks (MP-1 ≤ 300)" % [d, id, still.get(String(id), 0)])
	t.note("D=%d echo %s: %d ticks (%s), MP-1 %s, LP %d, hits P1 %d, keerpunten %s" % [d, "aan" if echo_on else "uit",
		wijk.run_ticks(), rep.room_time, still, rep.lp_total, 5 - wijk.p1.health, keer])
	return [parts, rep]


func _check_echo_run(t, d: int, parts: Array, rep) -> void:
	var bot = parts[1]
	for n: String in ["S1-B1", "S2-B3", "S2-B1", "S4-B4"]:
		t.check(bot.lines.get(n, false), "D=%d %s: niet via de echolijn (L-08, gescripte geoefende run)" % [d, n])
	t.check(rep.actions_per_min >= 3.0, "D=%d: %.2f echo-acties per minuut (MP-2 ≥ 3,0)" % [d, rep.actions_per_min])
	for id: StringName in Layout.ORDER:
		var per: float = rep.actions_per_min_room.get(String(id), 0.0)
		t.check(per >= 3.0, "D=%d %s: %.2f echo-acties per minuut (MP-2 per kamer, L-11)" % [d, id, per])
	t.check(rep.longest_gap <= FlowReport.MP2_WINDOW, "D=%d: %d ticks zonder echo-actie (MP-2/L-11: ≤ 40 s)" % [d, rep.longest_gap])
	if d == 60:
		t.check(rep.landings > 0 and rep.landings_without_still >= 0.75,
			"D=60: %.0f %% van %d landingen zonder stilstand (MP-3 ≥ 75 %%)" % [rep.landings_without_still * 100.0, rep.landings])
	t.check(rep.echo_empty_share <= 0.4, "D=%d: echo %.0f %% Leeg (MP-4 ≤ 40 %%)" % [d, rep.echo_empty_share * 100.0])
	t.check(rep.lp_echo_share >= 0.4, "D=%d: %.0f %% LP met de echo (MP-6 ≥ 40 %%)" % [d, rep.lp_echo_share * 100.0])
	t.note("D=%d: MP-2 %.1f/min %s, langste gat %d, MP-3 %.0f %% van %d landingen, MP-4 %.0f %%, MP-6 %.0f %%, LP S1–S4 %d, B-marges bounce %s landing %s" % [
		d, rep.actions_per_min, rep.actions_per_min_room, rep.longest_gap, rep.landings_without_still * 100.0, rep.landings,
		rep.echo_empty_share * 100.0, rep.lp_echo_share * 100.0, rep.lp_total, bot.bounce_from_wall, bot.landed_from_wall])


## C-15, FK-2 en de eis bij keren (gdd §4.3: in de slice bij elke D): als
## beide runs van deze D er zijn.
func _check_slow_lines(t, d: int) -> void:
	var on: Dictionary = _runs.get("%d_aan" % d, {})
	var off: Dictionary = _runs.get("%d_uit" % d, {})
	t.check(not on.is_empty() and not off.is_empty(), "D=%d: run met en zonder echo nodig" % d)
	if on.is_empty() or off.is_empty():
		return
	t.check(off["ticks"] <= 2 * on["ticks"], "D=%d: zonder echo %d ticks, met %d (C-15: ≤ 2×)" % [d, off["ticks"], on["ticks"]])
	for id: StringName in Layout.ORDER:
		var a := int(on["rooms"].get(String(id), 0))
		var b := int(off["rooms"].get(String(id), 0))
		t.check(a > 0 and b <= 2 * a, "D=%d %s: zonder echo %d ticks, met %d (C-15: ≤ 2×)" % [d, id, b, a])
	for n: String in ["S1-B1", "S2-B1"]:
		var keer := int(on["keer"].get(n, -1))
		var slow := int(off["keer"].get(n, -1))
		t.check(keer > 0 and slow - keer >= 30 and slow <= 2 * keer,
			"D=%d %s: keren %d, langzame lijn %d ticks vanaf de wand (gdd §4.3: ≥ 30 sneller, ≤ 2×)" % [d, n, keer, slow])
		t.note("D=%d %s: keren %d, langzame lijn %d (+%d, %.2f×)" % [d, n, keer, slow, slow - keer, float(slow) / maxf(keer, 1)])


func test_kadewijk_run_d60(t) -> void:
	var out := await _full_run(t, 60, true)
	_check_echo_run(t, 60, out[0], out[1])
	await _free(t, out[0])


func test_kadewijk_zonder_echo_d60(t) -> void:
	var out := await _full_run(t, 60, false)
	await _free(t, out[0])
	_check_slow_lines(t, 60)


## De run van D = 60 met dezelfde bits als `ScriptedInput` geeft hetzelfde meetlog (gdd §4.5).
func test_kadewijk_replay_d60(t) -> void:
	var parts := _wijk(t, 60, true)
	await _run(t, parts[0])
	var bits: PackedInt32Array = parts[1].recorded
	var csv: String = parts[0].meetlog.to_csv()
	await _free(t, parts)
	var segments: Array = []
	for b in bits:
		segments.append([1, b])
	var again := _wijk(t, 60, true, &"S1", ScriptedInput.new(segments))
	await _run(t, again[0])
	t.check(again[0].run_over and again[0].meetlog.to_csv() == csv, "replay D=60 geeft een ander meetlog (deterministisch, gdd §4.5)")
	await _free(t, again)


## Per kamer los, vanaf het begin van de kamer (LM-08), bij D = 60 met echo:
## de bot haalt de volgende kamer (S4: het einde), via de echolijn, met MP-1.
func test_kadewijk_per_kamer_d60(t) -> void:
	var next := {&"S1": &"S2", &"S2": &"S3", &"S3": &"S4", &"S4": &""}
	var lines := {&"S1": ["S1-B1"], &"S2": ["S2-B3", "S2-B1"], &"S3": [], &"S4": ["S4-B4"]}
	for id: StringName in Layout.ORDER:
		var parts := _wijk(t, 60, true, id)
		var wijk = parts[0]
		await _run(t, wijk, next[id])
		var done: bool = wijk.run_over if next[id] == &"" else wijk.room == next[id]
		t.check(done, "%s: niet uit de kamer (tick %d, stap %s, P1 %s)" % [id, wijk.sim.tick, parts[1].leg_name(), wijk.p1.position])
		for n: String in lines[id]:
			t.check(parts[1].lines.get(n, false), "%s: %s niet via de echolijn" % [id, n])
		var still := _still_per_room(wijk.meetlog.rows)
		t.check(int(still.get(String(id), 0)) <= 300, "%s: langste stilstand %d (MP-1)" % [id, still.get(String(id), 0)])
		t.check(_respawns(wijk.meetlog.rows) == 0, "%s: P1 stierf" % id)
		t.note("%s los: %d ticks, hits P1 %d" % [id, wijk.run_ticks(), 5 - wijk.p1.health])
		await _free(t, parts)


func test_kadewijk_run_d120(t) -> void:
	var out := await _full_run(t, 120, true)
	_check_echo_run(t, 120, out[0], out[1])
	await _free(t, out[0])


func test_kadewijk_zonder_echo_d120(t) -> void:
	var out := await _full_run(t, 120, false)
	await _free(t, out[0])
	_check_slow_lines(t, 120)


func test_kadewijk_run_d180(t) -> void:
	var out := await _full_run(t, 180, true)
	_check_echo_run(t, 180, out[0], out[1])
	await _free(t, out[0])


func test_kadewijk_zonder_echo_d180(t) -> void:
	var out := await _full_run(t, 180, false)
	await _free(t, out[0])
	_check_slow_lines(t, 180)


# --- Golven, wekken en respawn -------------------------------------------------

## S3 (L-13): golf 2 doet niet mee vóór golf 1 gemerkt of op is (niet bij de
## Sim, niet in beeld); daarna wel, en nooit meer dan 5 tegelijk. De Schotdrager
## blokkeert niet: de bot is klaar als de Kadelopers op zijn (L-13 e).
func test_kadewijk_golven_s3(t) -> void:
	var parts := _wijk(t, 60, true, &"S3")
	var wijk = parts[0]
	await t.tree.physics_frame
	var golf_2: Array = wijk.loader.kamers[&"S3"].inhoud_node.get_node("Golf2").get_children()
	var early_ok := true
	while wijk.wave_2_tick < 0 and wijk.sim.tick < 2000:
		for e in golf_2:
			if wijk.sim.objects.has(e) or e.visible:
				early_ok = false
		await t.tree.physics_frame
	t.check(early_ok, "golf 2 deed mee vóór golf 1 gemerkt of op was")
	t.check(wijk.wave_2_tick > 0, "golf 2 kwam niet")
	for e in wijk._wave_1:
		t.check(not e.alive or wijk.sim.combat.mark_on(e) != null or wijk.wave_2_tick < 0,
			"golf 2 begon terwijl %s nog geen merk had" % e.name)
	await t.tree.physics_frame
	for e in golf_2:
		t.check(wijk.sim.objects.has(e) and e.visible, "golf 2: %s doet niet mee na de start" % e.name)
	await _run(t, wijk, &"S4")
	t.check(wijk.room == &"S4" and wijk.most_at_once <= 5, "S3: kamer %s, %d tegelijk (≤ 5)" % [wijk.room, wijk.most_at_once])
	await _free(t, parts)


## Wekken (kamerdoc §4): een vijand in een andere kamer of op een andere
## vloer doet niets; op zijn vloer binnen een half scherm wordt hij wakker.
func test_kadewijk_wekken(t) -> void:
	var parts := _wijk(t, 60, true, &"S2", ScriptedInput.new([[60, 0]]))
	var wijk = parts[0]
	await t.tree.physics_frame
	var a: SliceEnemy = wijk.loader.kamers[&"S2"].inhoud_node.get_node("Paar1A")
	var x0 := a.position.x
	await t.run_ticks(wijk.sim, 30)
	t.check(not wijk.is_awake(a) and is_equal_approx(a.position.x, x0), "S2: Paar1A wakker of bewoog terwijl P1 op de kade eronder stond (%.1f → %.1f)" % [x0, a.position.x])
	wijk.p1.respawn_at(Vector2(1060, Layout.S2_MID - Layout.HALF_H))
	await t.run_ticks(wijk.sim, 30)
	t.check(wijk.is_awake(a) and a.position.x > x0, "S2: Paar1A niet wakker met P1 op zijn gang (%.1f → %.1f)" % [x0, a.position.x])
	await _free(t, parts)


## SL-03: vóór het gemaal is S1 de respawnplek (het checkpoint bij de
## proloogdeur). P1 valt in S3 op 0 levenspunten en verschijnt op S1; één
## `RESPAWN` in het meetlog.
func test_kadewijk_respawn_s1(t) -> void:
	var parts := _wijk(t, 60, true, &"S1", ScriptedInput.new([[400, 0]]))
	var wijk = parts[0]
	var progress = parts[2]
	await t.run_ticks(wijk.sim, 2)
	t.check(progress.has_checkpoint_in_area() and progress.state.checkpoint_positie == Layout.RUN_START,
		"geen checkpoint op S1 (%s)" % progress.state.checkpoint_positie)
	wijk.p1.respawn_at(Layout.ROOM_START[&"S2"])
	await t.run_ticks(wijk.sim, 2)
	wijk.p1.respawn_at(Layout.ROOM_START[&"S3"])
	await t.run_ticks(wijk.sim, 2)
	t.check(wijk.room == &"S3", "niet in S3 (%s)" % wijk.room)
	var before := _respawns(wijk.meetlog.rows)
	for i in 5:
		wijk.p1.take_hit(wijk.sim.tick + 100 * i)
	await t.run_ticks(wijk.sim, 3)
	t.check(wijk.room == &"S1" and wijk.p1.position.distance_to(Layout.RUN_START) < 2.0 and wijk.p1.health == 5,
		"na 0 levenspunten: kamer %s, P1 %s, leven %d (SL-03: S1)" % [wijk.room, wijk.p1.position, wijk.p1.health])
	# De twee sprongen hierboven (`respawn_at` zonder dood) tellen ook als RESPAWN (E-04b).
	var after := _respawns(wijk.meetlog.rows) - before
	t.check(after == 1, "%d RESPAWN-regels na de dood (verwacht 1)" % after)
	await _free(t, parts)
