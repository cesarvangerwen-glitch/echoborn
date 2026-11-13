extends RefCounted
## De Gemaalmeester in de Kadewijk-arena (S8 Machinehal; #83 open punten van de WLD na PR #223).
## Bron: `docs/design/gemaalmeester.md` v0.2.1 (GM-01, GM-07, GM-09, GM-10, GM-11, §7 acceptatie),
## `docs/design/combat/slice-vijanden-en-boss.md` v0.1.3 §3.9, kamerdoc
## `docs/design/kamers/kadewijk.md` §3e, §5, §9.
##
## - Plaatsing: de boss staat op `Layout.ARENA_ORIGIN` (4180, 680) met `ARENA_W` = 600 als S8 geladen
##   is (P1 in S7 of S8), en is er niet als S8 ontladen is. P1 in S6 (boven de arena, dezelfde x)
##   start hem niet.
## - Deuren: `BOSS_START` sluit `DeurRechts` (P1 staat dan helemaal binnen), `BOSS_VERSLAGEN` opent
##   `DeurLinks` (`Kadewijk.set_door`).
## - GM-11 / SL-03: P1 valt in S8 op 0 levenspunten en respawnt op het checkpoint van het gemaal (S6);
##   S8 ontlaadt en de boss gaat weg bij de Sim; terug in S8 staat er een nieuwe boss op 100 %.
## - B-9 in de Kadewijk: dezelfde gescripte geoefende run als `test_boss_runs.gd` (`boss_bot.gd`, 2
##   slagen per bounce, met ontwijken, 5 LP), solo bij D = 60, 90, 120 en 180, in de echte arena: P1
##   komt door de deur rechts binnen. Normen: verslagen zonder dood (≤ 4 treffers, geen RESPAWN),
##   MP-1 ≤ 300 (GM-09), de echo breekt niet, het schot breekt (GM-06), het rad wordt met een bounce
##   geraakt (GM-07), `RAD_DRAAI` reden `tijd` ≤ 1 bij D ≤ 120, bij D = 60 95–150 s met fase 1 ≥ 24 s en
##   fase 2 ≤ 65 s (§7, §3.9 v0.1.5, #247); na
##   `BOSS_VERSLAGEN` 100 LP (GM-10) en de deur links open; P1 blijft het hele gevecht in de arena.
## - De baan van het Dwaallicht (S7) staat als `@export` in de scène (`lane_from`, `lane_to`, `floor_top`).
##
## Elke test maakt een eigen `Progress`; de autoloads en `user://saves` blijven onaangeroerd.

const Scene := preload("res://levels/kadewijk/kadewijk.tscn")
const KadeBot = preload("res://levels/kadewijk/kadewijk_bot.gd")
const BossBot = preload("res://tests/boss_bot.gd")
const Layout = preload("res://levels/kadewijk/kadewijk_layout.gd")
const Kadewijk = preload("res://levels/kadewijk/kadewijk.gd")
const Progress = preload("res://scripts/save/progress.gd")
const FlowReport = preload("res://levels/flowkamer/flow_report.gd")
const Gemaalmeester = preload("res://scripts/combat/gemaalmeester.gd")
const InputBits = preload("res://scripts/input/input_bits.gd")
const LightMeter = preload("res://scripts/light/light_meter.gd")
const BossPart = preload("res://scripts/combat/boss_part.gd")
const SliceEnemy = preload("res://scripts/combat/slice_enemy.gd")
const EnemyData = preload("res://scripts/combat/enemy_data.gd")

## Zoals `test_boss_runs.gd`: de run stopt bij BOSS_VERSLAGEN of op `RUN_LIMIT` ticks na de start.
const RUN_LIMIT := 20000
const MAX_FRAMES := {
	"test_kadewijk_boss_solo_d60": 22000, "test_kadewijk_boss_solo_d90": 22000,
	"test_kadewijk_boss_solo_d120": 22000, "test_kadewijk_boss_solo_d180": 22000,
	"test_kadewijk_boss_respawn_op_gemaal": 4000,
}


## De inputbron van P1 vóór de boss bestaat: de bot komt pas als S8 geladen is (in `_ready`).
class LateSource:
	extends RefCounted
	var bot: RefCounted = null

	func sample(tick: int) -> int:
		return bot.p1_source.sample(tick) if bot != null else 0


## Loopt naar links tot `stop_x` en staat dan stil (de respawntest).
class WalkLeft:
	extends RefCounted
	var p1: Node2D = null
	var stop_x := 0.0

	func sample(_tick: int) -> int:
		return InputBits.LEFT if p1 != null and p1.position.x > stop_x else 0


func _wijk(t, d: int, start: StringName, run_end: StringName, input: RefCounted) -> Array:
	var progress := Progress.new()
	progress.name = "TestProgress"
	t.tree.root.add_child(progress)
	# V-01 (besluit LGD #252): wie voorbij de sokkel (S7) begint, heeft de Neerslag al.
	if start == &"S8" or start == &"S9":
		Kadewijk.give_neerslag(progress.state)
	var wijk = Scene.instantiate()
	wijk.tail = d
	wijk.echo_on = true
	wijk.show_hud = false
	wijk.progress = progress
	wijk.start_at = Layout.ROOM_START[start]
	wijk.run_end = run_end
	wijk.input_override = input
	t.tree.root.add_child(wijk)
	return [wijk, progress]


func _free(t, parts: Array) -> void:
	parts[0].queue_free()
	parts[1].queue_free()
	await t.tree.process_frame


func _door(wijk, block_name: String) -> StaticBody2D:
	var kamer = wijk.loader.kamers[&"S8"]
	if kamer.inhoud_node == null:
		return null
	return kamer.inhoud_node.get_node_or_null("Blokken/" + block_name)


func _door_closed(wijk, block_name: String) -> bool:
	var body := _door(wijk, block_name)
	return body != null and body.collision_layer != 0


func _ticks(t, wijk, n: int) -> void:
	for i in n:
		await t.tree.physics_frame


# --- Plaatsing en deuren ------------------------------------------------------------

## De boss op `ARENA_ORIGIN` als S8 geladen is; P1 in S7 start hem niet; in S6 is S8 niet geladen,
## en een punt in S6 boven de arena ligt niet in de arena (`arena_height`).
func test_kadewijk_boss_plaatsing(t) -> void:
	var parts := _wijk(t, 60, &"S8", &"S9", WalkLeft.new())
	var wijk = parts[0]
	await _ticks(t, wijk, 2)
	var boss: Gemaalmeester = wijk.boss
	t.check(boss != null and boss.is_inside_tree(), "S8 geladen: geen Gemaalmeester")
	if boss == null:
		await _free(t, parts)
		return
	t.check(boss.global_position == Layout.ARENA_ORIGIN, "boss op %s (ARENA_ORIGIN %s)" % [boss.global_position, Layout.ARENA_ORIGIN])
	t.check(is_equal_approx(boss.arena_width, Layout.ARENA_W), "arena_width %.0f (ARENA_W %.0f)" % [boss.arena_width, Layout.ARENA_W])
	t.check(wijk.sim.objects.has(boss) and wijk.sim.objects.has(boss.ketel) and wijk.sim.objects.has(boss.rad),
		"boss of zijn delen niet bij de Sim")
	# GM-07: het rad op D + 34 px van de linkermuur, het lichaam in het midden (252–348).
	t.check(is_equal_approx(boss.arena_point(boss.rad_x(-1), 0).x, Layout.ARENA_WALL_L + 94.0)
		and is_equal_approx(boss.arena_point(boss.rad_x(1), 0).x, Layout.ARENA_WALL_R - 94.0),
		"rad op %.0f / %.0f (verwacht 4274 / 4686)" % [boss.arena_point(boss.rad_x(-1), 0).x, boss.arena_point(boss.rad_x(1), 0).x])
	t.check(is_equal_approx(boss.arena_point(boss.middle(), 0).x, 4480.0), "midden van het lichaam op x %.0f (4480)" % boss.arena_point(boss.middle(), 0).x)
	t.check(boss.state == boss.State.IDLE, "P1 op het begin van S8 (x %.0f, op de drempel) startte de boss al" % wijk.p1.position.x)
	t.check(not _door_closed(wijk, "DeurRechts") and _door_closed(wijk, "DeurLinks"), "bij het laden: deur rechts open, links dicht")
	# P1 in S6, recht boven de arena (x 4400, y 245): niet in de arena.
	t.check(not boss.is_in_arena(Vector2(4400, Layout.S6_FLOOR - Layout.HALF_H)) and boss.is_in_arena(Vector2(4400, Layout.ARENA_FLOOR - Layout.HALF_H)),
		"is_in_arena: een punt in S6 boven de arena telt mee, of de vloer van de arena niet")
	await _free(t, parts)
	# Vanuit S7 (buur): de boss is er, IDLE; vanuit S6 is S8 niet geladen.
	parts = _wijk(t, 60, &"S7", &"S9", WalkLeft.new())
	wijk = parts[0]
	await _ticks(t, wijk, 30)
	t.check(wijk.boss != null and wijk.boss.state == Gemaalmeester.State.IDLE, "P1 in S7: boss %s" % [wijk.boss])
	await _free(t, parts)
	parts = _wijk(t, 60, &"S6", &"S9", WalkLeft.new())
	wijk = parts[0]
	await _ticks(t, wijk, 30)
	t.check(wijk.boss == null and not wijk.loader.is_loaded(&"S8"), "P1 in S6: S8 geladen of een boss")
	await _free(t, parts)


## GM-01 (L-13 a): P1 loopt de arena in → BOSS_START sluit `DeurRechts`, met P1 helemaal binnen.
func test_kadewijk_boss_start_sluit_deur(t) -> void:
	var input := WalkLeft.new()
	input.stop_x = 4600.0
	var parts := _wijk(t, 60, &"S8", &"S9", input)
	var wijk = parts[0]
	input.p1 = wijk.p1
	var start := {"tick": -1, "x": 0.0, "closed_at_start": false}
	wijk.boss.boss_started.connect(func(tick: int) -> void:
		start["tick"] = tick
		start["x"] = wijk.p1.position.x)
	wijk.boss.arena_changed.connect(func(_tick: int, closed: bool) -> void:
		if closed:
			start["closed_at_start"] = _door_closed(wijk, "DeurRechts"))
	await _ticks(t, wijk, 120)
	t.check(int(start["tick"]) >= 0, "geen BOSS_START (P1 %s)" % wijk.p1.position)
	t.check(start["closed_at_start"] and _door_closed(wijk, "DeurRechts") and _door(wijk, "DeurRechts").visible,
		"BOSS_START: DeurRechts niet dicht")
	t.check(_door_closed(wijk, "DeurLinks"), "BOSS_START: DeurLinks open")
	var right_edge: float = float(start["x"]) + Layout.HALF_W
	t.check(right_edge <= Layout.ARENA_WALL_R, "bij BOSS_START steekt P1 in de deur (rechterkant %.0f > %.0f)" % [right_edge, Layout.ARENA_WALL_R])
	t.check(wijk.meetlog.count("BOSS_START") == 1, "BOSS_START %d keer in het meetlog" % wijk.meetlog.count("BOSS_START"))
	# De deur houdt P1 binnen: naar rechts lopen komt niet voorbij de muur.
	wijk.p1.input_source = _Fixed.new(InputBits.RIGHT)
	await _ticks(t, wijk, 150)
	t.check(wijk.p1.position.x + Layout.HALF_W <= Layout.ARENA_WALL_R + 0.5 and wijk.room == &"S8",
		"P1 liep door de dichte deur (x %.1f, kamer %s)" % [wijk.p1.position.x, wijk.room])
	await _free(t, parts)


class _Fixed:
	extends RefCounted
	var bits := 0

	func _init(p_bits: int) -> void:
		bits = p_bits

	func sample(_tick: int) -> int:
		return bits


## GM-11, SL-03 (kamerdoc §5): na de eerste pompslag is het gemaal het checkpoint. P1 valt in S8 op
## 0 levenspunten (1 LP over, de eerste pompslag raakt), respawnt op het checkpoint van S6 (één
## RESPAWN); S8 ontlaadt, de boss en zijn adds zijn weg bij de Sim. Terug in S8 (de kadewijk-bot van
## het gemaal naar de arena) staat er een nieuwe boss op 100 % in fase 1, met de deur rechts open.
func test_kadewijk_boss_respawn_op_gemaal(t) -> void:
	var input := WalkLeft.new()
	input.stop_x = 4560.0
	var parts := _wijk(t, 60, &"S6", &"S9", input)
	var wijk = parts[0]
	var progress = parts[1]
	input.p1 = wijk.p1
	await _ticks(t, wijk, 2)
	var s6: Node = wijk.loader.kamers[&"S6"].inhoud_node
	# S6 ontlaadt als P1 in S8 is: de plek van het checkpoint vooraf.
	var spawn: Vector2 = s6.get_node("Checkpoint").spawn_point()
	# Zoals na de eerste pompslag van P1 (`Checkpoint._on_pumped`): het gemaal is het checkpoint.
	progress.reach_checkpoint(spawn)
	t.check(progress.state.checkpoint_kamer == &"S6", "checkpoint in %s (verwacht S6)" % progress.state.checkpoint_kamer)
	wijk.p1.respawn_at(Layout.ROOM_START[&"S8"])
	await _ticks(t, wijk, 120)
	var old: Gemaalmeester = wijk.boss
	t.check(old != null and old.state == Gemaalmeester.State.FIGHT and _door_closed(wijk, "DeurRechts"),
		"geen gevecht in S8 (boss %s, P1 %s)" % [old, wijk.p1.position])
	t.check(wijk.is_arena_camera() and wijk.camera_view() == Kadewijk.arena_view(), "geen vaste arena-camera in het gevecht")
	if old == null:
		await _free(t, parts)
		return
	wijk.p1.health = 1
	var respawns_before: int = wijk.meetlog.count("RESPAWN")
	var died := {"tick": -1}
	wijk.p1.health_changed.connect(func(tick: int, h: int) -> void:
		if h == 0 and int(died["tick"]) < 0:
			died["tick"] = tick
			# Na de respawn blijft P1 staan, zodat hij op het checkpoint te zien is.
			input.stop_x = INF)
	var waited := 0
	while int(died["tick"]) < 0 and waited < 600:
		await t.tree.physics_frame
		waited += 1
	await _ticks(t, wijk, 3)
	t.check(int(died["tick"]) >= 0, "de pompslag raakte P1 niet in 600 ticks")
	t.check(wijk.room == &"S6" and wijk.p1.position.distance_to(spawn) <= 1.0,
		"respawn in %s op %s (verwacht het checkpoint van het gemaal %s)" % [wijk.room, wijk.p1.position, spawn])
	t.check(wijk.meetlog.count("RESPAWN") - respawns_before == 1, "%d keer RESPAWN (verwacht 1)" % (wijk.meetlog.count("RESPAWN") - respawns_before))
	t.check(not wijk.loader.is_loaded(&"S8") and wijk.boss == null, "S8 nog geladen of de boss nog gezet")
	t.check(not wijk.is_arena_camera() and wijk.camera_view() != Kadewijk.arena_view(), "na de respawn staat de camera nog op de arena")
	# De oude boss is vrijgegeven met de inhoud van S8; bij de Sim staat niets meer van hem.
	var left := 0
	for object in wijk.sim.objects:
		if not is_instance_valid(object) or object is Gemaalmeester or object is BossPart \
				or (object is SliceEnemy and Layout.room_of(object.start_position) == &"S8"):
			left += 1
	t.check(left == 0, "%d objecten van de oude boss (boss, delen, adds) nog bij de Sim" % left)
	var listeners := 0
	for sig: Signal in [wijk.sim.tick_finished, wijk.sim.attack_executed, wijk.sim.stuit]:
		for c: Dictionary in sig.get_connections():
			var target: Object = (c["callable"] as Callable).get_object()
			if target == null or not is_instance_valid(target) or target is Gemaalmeester:
				listeners += 1
	t.check(listeners == 0, "%d verbindingen van de Sim naar de oude boss" % listeners)
	# Een nieuwe poging (besluit LGD #247): bij de nieuwe BOSS_START staat de camera weer vast op de arena.
	input.stop_x = 4560.0
	wijk.p1.respawn_at(Layout.ROOM_START[&"S8"])
	await _ticks(t, wijk, 120)
	t.check(wijk.boss != null and wijk.boss != old and wijk.boss.state == Gemaalmeester.State.FIGHT
		and wijk.is_arena_camera() and wijk.camera_view() == Kadewijk.arena_view(),
		"na de respawn en een nieuwe BOSS_START: boss %s, arena-camera %s" % [wijk.boss, wijk.is_arena_camera()])
	await _free(t, parts)
	# Terug naar de arena, zoals een nieuwe poging (`test_kadewijk_deel2.gd`, gemaal → arena-deur).
	var progress2 := Progress.new()
	progress2.name = "TestProgress"
	t.tree.root.add_child(progress2)
	var wijk2 = Scene.instantiate()
	wijk2.tail = 60
	wijk2.show_hud = false
	wijk2.progress = progress2
	wijk2.start_at = Layout.ROOM_START[&"S6"]
	wijk2.run_end = &"S8"
	var bot = KadeBot.new(wijk2, 60, &"S6")
	wijk2.input_override = bot
	t.tree.root.add_child(wijk2)
	await t.tree.physics_frame
	var s6b: Node = wijk2.loader.kamers[&"S6"].inhoud_node
	wijk2.gemaal.restore_state(100, true)
	for n in ["Paar1A", "Paar1B"]:
		s6b.get_node(n).apply_damage(wijk2.sim.tick, 1000, "test")
	wijk2.loader.kamers[&"S7"].inhoud_node.get_node("Luik").set_persistent_state(true)
	wijk2.p1.respawn_at(s6b.get_node("Checkpoint").spawn_point())
	await t.tree.physics_frame
	var t0: int = wijk2.sim.tick
	while not wijk2.run_over and wijk2.sim.tick < t0 + 1200:
		await t.tree.physics_frame
	var ticks: int = wijk2.sim.tick - t0
	var fresh: Gemaalmeester = wijk2.boss
	t.check(wijk2.run_over and fresh != null and fresh.se == fresh.se_max and fresh.phase == Gemaalmeester.Phase.ONE
		and fresh.state == Gemaalmeester.State.IDLE and not _door_closed(wijk2, "DeurRechts"),
		"terug in S8: boss %s (SE %s, fase %s), deur rechts %s" % [fresh, fresh.se if fresh else -1, fresh.phase if fresh else -1,
			"dicht" if _door_closed(wijk2, "DeurRechts") else "open"])
	t.check(ticks <= 600, "checkpoint van het gemaal → arena-deur %d ticks (GM-11, SL-03: ≤ 10 s)" % ticks)
	t.note("GM-11: respawn op het gemaal (S6), terug bij de arena-deur na %d ticks (%.1f s)" % [ticks, ticks / 60.0])
	await _free(t, [wijk2, progress2])


# --- B-9 in de Kadewijk -------------------------------------------------------------

## De gescripte geoefende boss-run in de echte arena: P1 begint op het begin van S8 (de drempel bij
## de deur rechts), de bot loopt de arena in en speelt de Gemaalmeester tot BOSS_VERSLAGEN.
func _solo(t, d: int) -> void:
	var name := "Kadewijk solo D = %d (2 slagen per bounce, met ontwijken, 5 LP)" % d
	var input := LateSource.new()
	var parts := _wijk(t, d, &"S8", Kadewijk.RUN_END_BOSS, input)
	var wijk = parts[0]
	var boss: Gemaalmeester = wijk.boss
	t.check(boss != null, "%s: geen boss in S8" % name)
	if boss == null:
		await _free(t, parts)
		return
	var bot := BossBot.new(wijk.sim, boss)
	input.bot = bot
	var hits: Array = []
	var breaks := {"n": 0}
	var outside := {"n": 0}
	var door := {"start_closed": false, "left_open_at_defeat": false}
	boss.hit_player.connect(func(tick: int, _p: Node2D) -> void: hits.append(tick))
	wijk.echo.broke.connect(func(_tick: int, _at: Vector2) -> void: breaks["n"] += 1)
	boss.arena_changed.connect(func(_tick: int, closed: bool) -> void:
		if closed:
			door["start_closed"] = _door_closed(wijk, "DeurRechts"))
	# GM-01 (besluit LGD #247): de camera vast op de arena van BOSS_START tot BOSS_VERSLAGEN, anders niet.
	var cam := {"vast": 0, "fout": 0, "voor": 0}
	wijk.sim.tick_finished.connect(func(_tick: int) -> void:
		var fighting: bool = boss.state != Gemaalmeester.State.IDLE and not boss.is_defeated()
		if fighting and wijk.camera_view() == Kadewijk.arena_view():
			cam["vast"] += 1
		elif fighting or wijk.is_arena_camera():
			cam["fout"] += 1)
	wijk.sim.tick_finished.connect(func(_tick: int) -> void:
		if boss.state != Gemaalmeester.State.IDLE and not boss.is_defeated():
			var x: float = wijk.p1.position.x
			if x - Layout.HALF_W < Layout.ARENA_WALL_L - 0.5 or x + Layout.HALF_W > Layout.ARENA_WALL_R + 0.5:
				outside["n"] += 1)
	await t.tree.physics_frame
	var until: int = wijk.sim.tick + RUN_LIMIT + 600
	while not wijk.run_over and wijk.sim.tick < until:
		await t.tree.physics_frame
	await _ticks(t, wijk, 2)
	if not wijk.run_over:
		wijk.meetlog.finish()
	var rows: Array = wijk.meetlog.rows
	var at := {}
	var turns := {"treffers": 0, "tijd": 0}
	var rad := {}
	var first_break := -1
	for row in rows:
		match row[2]:
			"BOSS_START":
				at["start"] = int(row[0])
			"BOSS_FASE":
				at[row[3]] = int(row[0])
			"BOSS_VERSLAGEN":
				at["verslagen"] = int(row[0])
			"SCHOT_BREUK":
				if first_break < 0:
					first_break = int(row[0])
			"RAD_TREFFER":
				var key := "%s/%s" % [row[4], row[3]]
				rad[key] = int(rad.get(key, 0)) + 1
			"RAD_DRAAI":
				turns[row[3]] = int(turns.get(row[3], 0)) + 1
	var rep = FlowReport.from_rows(rows, true)
	var total := int(at.get("verslagen", -1)) - int(at.get("start", 0)) if at.has("verslagen") else -1
	var part := func(a: String, b: String) -> String:
		return "%d" % (int(at[b]) - int(at[a])) if at.has(a) and at.has(b) else "?"
	t.note(("%s: van het begin van S8 tot BOSS_START %s · fase 1 %s · wissel %s · fase 2 %s · wankel+finisher %s · " +
		"totaal %d ticks (%.1f s) · MP-1 %d · treffers op P1 %d · LP na afloop %d · rad %s · kanten %s · eerste SCHOT_BREUK na %d") % [
		name, str(at.get("start", "?")), part.call("start", "wissel"), part.call("wissel", "2"), part.call("2", "wankel"),
		part.call("wankel", "verslagen"), total, total / 60.0, rep.longest_still, hits.size(), wijk.meter.value, rad, turns,
		first_break - int(at.get("start", 0))])
	# Normen (gemaalmeester.md §7, GM-09, GM-10; slice-vijanden-en-boss.md §3.9; zoals test_boss_runs.gd).
	t.check(boss.is_defeated() and wijk.run_over, "%s: niet verslagen in %d ticks (%s)" % [name, RUN_LIMIT, at])
	t.check(wijk.meetlog.count("RESPAWN") == 0 and wijk.p1.health > 0 and hits.size() <= 4,
		"%s: %d treffers op P1 (≤ 4), %d LP over, %d respawns (verslagen zonder dood)" % [name, hits.size(), wijk.p1.health, wijk.meetlog.count("RESPAWN")])
	t.check(rep.longest_still <= 300, "%s: MP-1 %d > 300" % [name, rep.longest_still])
	t.check(breaks["n"] == 0, "%s: de echo brak %d keer" % [name, breaks["n"]])
	t.check(first_break >= 0, "%s: geen SCHOT_BREUK (GM-06)" % name)
	t.check(int(rad.get("p1/bounce", 0)) > 0, "%s: geen RAD_TREFFER van P1 na een bounce (GM-07; %s)" % [name, rad])
	if d <= 120:
		t.check(int(turns.get("tijd", 0)) <= 1, "%s: %d keer RAD_DRAAI reden tijd (≤ 1)" % [name, turns.get("tijd", 0)])
	if d == 60:
		# v0.1.5 (#247, LGD): 95–150 s, fase 1 ≥ 24 s, fase 2 ≤ 65 s.
		var s := total / 60.0
		t.check(s >= 95.0 and s <= 150.0, "%s: %.1f s (95–150, §3.9 v0.1.5)" % [name, s])
		var f1 := float(int(at.get("wissel", -1)) - int(at.get("start", 0))) / 60.0 if at.has("wissel") else -1.0
		var f2 := float(int(at.get("wankel", -1)) - int(at.get("2", 0))) / 60.0 if at.has("wankel") and at.has("2") else INF
		t.check(f1 >= 24.0 and f2 <= 65.0, "%s: fase 1 %.1f s (≥ 24), fase 2 %.1f s (≤ 65)" % [name, f1, f2])
	# Kadewijk: deuren, licht, binnen de arena.
	t.check(door["start_closed"], "%s: DeurRechts ging niet dicht bij BOSS_START" % name)
	t.check(not _door_closed(wijk, "DeurLinks") and wijk.boss_defeated_tick >= 0, "%s: DeurLinks niet open na BOSS_VERSLAGEN" % name)
	t.check(wijk.meter.value == LightMeter.MAX, "%s: %d LP na BOSS_VERSLAGEN (GM-10: %d)" % [name, wijk.meter.value, LightMeter.MAX])
	t.check(outside["n"] == 0, "%s: P1 %d ticks buiten de arena tijdens het gevecht" % [name, outside["n"]])
	t.check(int(cam["vast"]) > 0 and int(cam["fout"]) == 0 and not wijk.is_arena_camera(),
		"%s: camera %d ticks vast op de arena, %d ticks fout, na BOSS_VERSLAGEN vast %s" % [name, cam["vast"], cam["fout"], wijk.is_arena_camera()])
	t.check(Kadewijk.arena_view() == Layout.ROOMS[&"S8"] and Kadewijk.arena_view().size == Vector2(640, 360),
		"arena-camera %s (verwacht S8, 640 × 360)" % Kadewijk.arena_view())
	await _free(t, parts)


func test_kadewijk_boss_solo_d60(t) -> void:
	await _solo(t, 60)


func test_kadewijk_boss_solo_d90(t) -> void:
	await _solo(t, 90)


func test_kadewijk_boss_solo_d120(t) -> void:
	await _solo(t, 120)


func test_kadewijk_boss_solo_d180(t) -> void:
	await _solo(t, 180)


# --- De baan van het Dwaallicht in de scène (S7, #83) -----------------------------------

## De banen van de twee Dwaallichten staan als `@export` in `s7_sluiskelder.tscn` (niet meer in
## `kadewijk.gd`): op 1/3 en 2/3 van het kanaal (`Layout.DWAALLICHT_X`), 32 px breed, boven de
## benedenvloer (`floor_top` = `S7_LOW`). Geladen in de Kadewijk blijven ze zo.
func test_kadewijk_dwaallicht_baan_in_scene(t) -> void:
	var scene: PackedScene = load("res://levels/kadewijk/s7_sluiskelder.tscn")
	var inhoud: Node = scene.instantiate()
	for i in Layout.DWAALLICHT_X.size():
		var e: SliceEnemy = inhoud.get_node("Dwaallicht%d" % (i + 1))
		var x: float = Layout.DWAALLICHT_X[i]
		t.check(e.enemy_type == SliceEnemy.Type.DWAALLICHT and is_equal_approx(e.lane_from, x - Layout.DWAALLICHT_LANE)
			and is_equal_approx(e.lane_to, x + Layout.DWAALLICHT_LANE) and is_equal_approx(e.floor_top, Layout.S7_LOW),
			"Dwaallicht%d in de scène: baan %.0f–%.0f, vloer %.0f (verwacht %.0f–%.0f, %.0f)" % [i + 1, e.lane_from, e.lane_to,
				e.floor_top, x - Layout.DWAALLICHT_LANE, x + Layout.DWAALLICHT_LANE, Layout.S7_LOW])
	inhoud.free()
	var parts := _wijk(t, 60, &"S7", &"S9", WalkLeft.new())
	var wijk = parts[0]
	await _ticks(t, wijk, 2)
	var s7: Node = wijk.loader.kamers[&"S7"].inhoud_node
	for i in Layout.DWAALLICHT_X.size():
		var e: SliceEnemy = s7.get_node("Dwaallicht%d" % (i + 1))
		var x: float = Layout.DWAALLICHT_X[i]
		t.check(wijk.sim.objects.has(e) and is_equal_approx(e.start_position.x, x)
			and is_equal_approx(e.position.y + e.body_size().y * 0.5, Layout.S7_LOW - EnemyData.value("dwaallicht", "baan_hoogte")),
			"Dwaallicht%d geladen: start %s (x %.0f, 40 px boven de vloer)" % [i + 1, e.start_position, x])
	await _free(t, parts)
