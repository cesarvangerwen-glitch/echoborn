extends RefCounted
## De Kadewijk als lus (#83, kamerdoc `docs/design/kamers/kadewijk.md` §3f, §9):
## de laatste placeholders als echte objecten, en de hele route als bot-test.
## Bronnen: `docs/design/gdd.md` v0.8.4 (LM-03, LM-07, LM-08, LM-10, LM-12,
## §4.5 `SLICE_EIND`), `docs/design/wereld.md` (WS-03, WS-08, SL-02, L-12),
## `docs/design/gemaalmeester.md` v0.2.2 (GM-10).
##
## - **Gemaal met twee trappen** (LM-08, SL-02, WS-03): G_max = 200; in een
##   bosswijk tot `release_boss_cap()` niet verder dan 100; `trap_full` voor trap
##   1 en 2; `stand()` = `s`; uit een save met vulstand 200 staat trap 2 vol.
## - **Verzamelobjecten** (WS-08, LM-07, LM-12): het lampglas, logbladzijde 1–3 en
##   de Neerslag op de sokkel zijn `Pickup`s; P1 en P2 pakken op, de echo niet;
##   opgepakt is een vlag in de save; na laden zijn ze weg, het lampglas geeft
##   dan nog steeds 6 levenspunten, en de sokkel staat uit (#244).
## - **Boss verslagen in de save** (GM-10, LM-12): de vlag `S8/BossVerslagen`;
##   na laden geen boss, de deur naar S9 open en het gemaal zonder grens.
## - **`s = 2`** (LM-10): het `Hoogwater` van S9 gaat 180 ticks na trap 2 open,
##   en meteen uit een save met vulstand 200.
## - **De lus** S1 → S8 → de Gemaalmeester → S9 → de trap → trap 2 → S9 → S1
##   (`SLICE_EIND`), de gescripte geoefende run (`kadewijk_bot.gd` met `lus`, in
##   S8 `boss_bot.gd`), solo bij D = 60, 120 en 180.
##
## Elke test maakt een eigen `Progress`; de autoloads en `user://saves` blijven onaangeroerd.

const Scene := preload("res://levels/kadewijk/kadewijk.tscn")
const Bot = preload("res://levels/kadewijk/kadewijk_bot.gd")
const BossBot = preload("res://tests/boss_bot.gd")
const Layout = preload("res://levels/kadewijk/kadewijk_layout.gd")
const Kadewijk = preload("res://levels/kadewijk/kadewijk.gd")
const Progress = preload("res://scripts/save/progress.gd")
const GameState = preload("res://scripts/save/game_state.gd")
const AreaLoader = preload("res://scripts/world/area_loader.gd")
const FlowReport = preload("res://levels/flowkamer/flow_report.gd")
const Gemaal = preload("res://scripts/light/gemaal.gd")
const Pickup = preload("res://scripts/objects/pickup.gd")
const LightMeter = preload("res://scripts/light/light_meter.gd")
const Fx = preload("res://tests/echo_fixture.gd")
const PlayerActor = preload("res://scripts/echo/player_actor.gd")
const InputBits = preload("res://scripts/input/input_bits.gd")
const ScriptedInput = preload("res://scripts/input/scripted_input.gd")

## Ruim boven de langste lus (± 17 000 ticks bij D = 60).
const RUN_LIMIT := 30000
const MAX_FRAMES := {
	"test_lus_d60": 32000, "test_lus_d120": 32000, "test_lus_d180": 32000,
}


func _wijk(t, d: int, start: StringName, run_end: StringName, input: RefCounted, state: GameState = null) -> Array:
	var progress := Progress.new()
	progress.name = "TestProgress"
	t.tree.root.add_child(progress)
	if state != null:
		progress.adopt(state, -1)
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


func _ticks(t, n: int) -> void:
	for i in n:
		await t.tree.physics_frame


func _flag(room: StringName, path: NodePath) -> StringName:
	return AreaLoader.object_flag(room, path, Kadewijk.GEBIED)


func _block(wijk, room: StringName, block_name: String) -> StaticBody2D:
	var kamer = wijk.loader.kamers[room]
	if kamer.inhoud_node == null:
		return null
	return kamer.inhoud_node.get_node_or_null("Blokken/" + block_name) as StaticBody2D


func _closed(wijk, room: StringName, block_name: String) -> bool:
	var body := _block(wijk, room, block_name)
	return body != null and body.collision_layer != 0


func _count(rows: Array, event: String, value := "") -> int:
	var n := 0
	for row in rows:
		if row[2] == event and (value == "" or row[3] == value):
			n += 1
	return n


func _first(rows: Array, event: String, value := "") -> int:
	for row in rows:
		if row[2] == event and (value == "" or row[3] == value):
			return int(row[0])
	return -1


# --- Het gemaal met twee trappen (LM-08, SL-02) -----------------------------------------

class Meter:
	extends RefCounted
	var value := 0

	func take(amount: int) -> int:
		var taken := mini(amount, value)
		value -= taken
		return taken


## LM-03/LM-08/SL-02: met `boss_cap` blijft G op 100 (de slagen pompen 0), na
## `release_boss_cap` tot 200; `trap_full` op 100 (trap 1, samen met `full`) en
## op 200 (trap 2); `stand()` 0 → 1 → 2. Zonder grens gaat het in één keer door.
func test_gemaal_twee_trappen_en_boss_grens(t) -> void:
	for capped in [true, false]:
		var meter := Meter.new()
		meter.value = 1000
		var vane := Node2D.new()
		var gemaal := Gemaal.new()
		gemaal.trappen = 2
		gemaal.boss_cap = capped
		gemaal.setup_gemaal(meter, vane, null, Rect2(), 0.0, 0.0)
		var traps: Array = []
		var fulls: Array = []
		gemaal.trap_full.connect(func(tick: int, trap: int) -> void: traps.append([tick, trap]))
		gemaal.full.connect(func(tick: int) -> void: fulls.append(tick))
		var stands: Array = []
		for i in 10:
			gemaal._on_hit(i, "p1", vane, 1)
			stands.append(gemaal.stand())
		var label := "boss_cap %s" % capped
		if capped:
			t.check(gemaal.fill == 100 and gemaal.cap() == 100 and traps == [[6, 1]] and fulls == [6] and gemaal.trap_2_tick < 0,
				"%s: G %d, trappen %s, vol %s (SL-02: niet boven 100 vóór de boss)" % [label, gemaal.fill, traps, fulls])
			t.check(meter.value == 1000 - 100, "%s: %d LP gepompt (de slagen boven 100 pompen niets)" % [label, 1000 - meter.value])
			gemaal.release_boss_cap()
		for i in range(10, 20):
			gemaal._on_hit(i, "echo", vane, 1)
			stands.append(gemaal.stand())
		t.check(gemaal.fill == 200 and gemaal.g_max() == 200 and gemaal.stand() == 2,
			"%s: G %d, stand %d (verwacht 200, 2)" % [label, gemaal.fill, gemaal.stand()])
		var tv2 := 16 if capped else 13
		t.check(traps == [[6, 1], [tv2, 2]] and gemaal.trap_2_tick == tv2 and fulls.size() == 1,
			"%s: trap_full %s (verwacht trap 1 op 6, trap 2 op %d)" % [label, traps, tv2])
		t.check(stands[5] == 0 and stands[6] == 1 and stands[stands.size() - 1] == 2, "%s: standen %s" % [label, stands])
		gemaal.free()
		vane.free()
	# Laden (LM-12): 200 = trap 2 vol, stand 2; een gemaal met één trap klemt op 100.
	var g2 := Gemaal.new()
	g2.trappen = 2
	g2.restore_state(200, true)
	var g1 := Gemaal.new()
	g1.restore_state(150, true)
	t.check(g2.fill == 200 and g2.stand() == 2 and g2.trap_2_tick == 0 and g2.is_full(),
		"laden 200: G %d, stand %d, trap 2 op %d" % [g2.fill, g2.stand(), g2.trap_2_tick])
	t.check(g1.fill == 100 and g1.stand() == 1 and g1.trap_2_tick < 0, "laden 150 bij één trap: G %d, stand %d" % [g1.fill, g1.stand()])
	g2.free()
	g1.free()


## LM-12: een save met vulstand 200 is geldig (2 trappen), 201 niet; zie ook test_save.gd.
func test_save_vulstand_twee_trappen(t) -> void:
	var state := GameState.new()
	state.set_gemaal(&"kadewijk/S6/Gemaal", 200, true)
	var errors := PackedStringArray()
	var back = GameState.from_dict(state.to_dict(), errors)
	t.check(back != null and back.gemalen[&"kadewijk/S6/Gemaal"]["vulstand"] == 200, "vulstand 200 geweigerd: %s" % errors)
	var data := state.to_dict()
	data["gemalen"]["kadewijk/S6/Gemaal"]["vulstand"] = 201
	errors = PackedStringArray()
	t.check(GameState.from_dict(data, errors) == null and errors.size() == 1, "vulstand 201 niet geweigerd: %s" % errors)


# --- Verzamelobjecten en de sokkel (WS-08, L-12) -----------------------------------------

## De pick-ups staan op de plekken van de WLD (kamerdoc §3b, §3c, §3d, §3f), met
## hun soort, en kennen hun vlag (`AreaLoader.known_object_flags`). De kinderen
## van een kamerscène staan in wereldcoördinaten (`kadewijk_inhoud.gd`).
func test_pickups_in_de_kamers(t) -> void:
	var parts := _wijk(t, 60, &"S1", &"S4", ScriptedInput.new([]))
	var wijk = parts[0]
	var known: Dictionary = wijk.loader.known_object_flags()
	var expect := [
		[&"S5", ^"Lampglas", Pickup.Soort.LAMPGLAS, 0, Layout.LAMPGLAS],
		[&"S5", ^"Logbladzijde1", Pickup.Soort.LOGBLADZIJDE, 1, Layout.LOGBLAD_1],
		[&"S6", ^"Logbladzijde2", Pickup.Soort.LOGBLADZIJDE, 2, Layout.LOGBLAD_2],
		[&"S7", ^"Neerslag", Pickup.Soort.VAARDIGHEID, 0, Layout.SOKKEL - Vector2(0, Layout.HALF_H)],
		[&"S9", ^"Logbladzijde3", Pickup.Soort.LOGBLADZIJDE, 3, Layout.LOGBLAD_3],
	]
	for e: Array in expect:
		var kamer = wijk.loader.kamers[e[0]]
		var root: Node = kamer.inhoud.instantiate()
		var node := root.get_node_or_null(e[1]) as Pickup
		t.check(node != null and node.soort == e[2] and node.nummer == e[3] and node.position.is_equal_approx(e[4]),
			"%s/%s: soort %s, nummer %s, plek %s (verwacht %s)" % [e[0], e[1], node.soort if node else null, node.nummer if node else null,
			node.position if node else null, e[4]])
		t.check(known.has(_flag(e[0], e[1])), "%s/%s: vlag niet bekend bij de loader" % [e[0], e[1]])
		root.free()
	t.check(known.has(_flag(&"S8", ^"BossVerslagen")), "S8/BossVerslagen: vlag niet bekend bij de loader")
	var neerslag_root: Node = wijk.loader.kamers[&"S7"].inhoud.instantiate()
	t.check(neerslag_root.get_node(^"Neerslag").vaardigheid == &"V-01", "S7: de sokkel draagt niet V-01")
	neerslag_root.free()
	await _free(t, parts)


## Een `Pickup`: P1 en P2 pakken op binnen 12 px, de echo nooit; opgepakt is
## onzichtbaar en meldt maar één keer; de blijvende stand (R10).
func test_pickup_wie_en_wanneer(t) -> void:
	var sim = Fx.world(t)
	var pickup := Pickup.new()
	pickup.position = Vector2(300, Fx.STAND_Y)
	t.world_root().add_child(pickup)
	sim.add_object(pickup)
	var got: Array = []
	pickup.picked_up.connect(func(tick: int, who: String) -> void: got.append([tick, who]))
	var ghost := Fx.ghost(t)
	Fx.ghost_path(ghost, 0, 200, func(_k: int) -> Vector2: return Vector2(300, Fx.STAND_Y))
	var echo := Fx.tail_echo(sim, ghost, 1)
	await t.run_ticks(sim, 20)
	t.check(echo.is_present() and got.is_empty() and not pickup.opgepakt, "de echo pakte op (%s)" % [got])
	var p1 := Fx.p1(sim, [[200, InputBits.RIGHT]], Vector2(200, Fx.STAND_Y))
	await t.run_ticks(sim, 80)
	t.check(got.size() == 1 and got[0][1] == "p1" and not pickup.visible and pickup.get_persistent_state(),
		"P1: %s, zichtbaar %s" % [got, pickup.visible])
	t.check(absf(p1.position.x - 300.0) > 12.0 or got.size() == 1, "meer dan één melding")
	pickup.set_persistent_state(false)
	t.check(pickup.visible and not pickup.opgepakt, "set_persistent_state(false): nog opgepakt")
	await t.cleanup()
	# P2 pakt ook op (C-02).
	sim = Fx.world(t)
	var p2pick := Pickup.new()
	p2pick.position = Vector2(260, Fx.STAND_Y)
	t.world_root().add_child(p2pick)
	sim.add_object(p2pick)
	var who := []
	p2pick.picked_up.connect(func(_tick: int, w: String) -> void: who.append(w))
	var p1b := Fx.p1(sim, [[200, 0]], Vector2(100, Fx.STAND_Y))
	var p2 := PlayerActor.new()
	p2.setup(2, ScriptedInput.new([[200, InputBits.RIGHT]]), Color.WHITE)
	p2.position = Vector2(200, Fx.STAND_Y)
	sim.add_player(p2)
	await t.run_ticks(sim, 60)
	t.check(who == ["p2"], "P2 pakte niet op: %s (P1 op %s)" % [who, p1b.position])
	await t.cleanup()


## LM-12: een save waarin het lampglas, de logbladzijden en de Neerslag al
## opgepakt zijn en de boss verslagen is. Bij het laden: de objecten zijn weg,
## P1 heeft 6 levenspunten (WS-08 a), de sokkel staat uit (#244), in S8 staat
## geen boss en de deur naar S9 is open, en het gemaal pompt tot 200 (SL-02).
func test_save_opgepakt_en_boss_verslagen(t) -> void:
	var state := GameState.new()
	for spec: Array in [[&"S5", ^"Lampglas"], [&"S5", ^"Logbladzijde1"], [&"S6", ^"Logbladzijde2"],
			[&"S7", ^"Neerslag"], [&"S9", ^"Logbladzijde3"], [&"S8", ^"BossVerslagen"]]:
		state.set_flag(_flag(spec[0], spec[1]))
	state.set_gemaal(_flag(&"S6", ^"Gemaal"), 100, true)
	# P1 begint in S7: S6 en S8 laden mee.
	var parts := _wijk(t, 60, &"S7", &"S4", ScriptedInput.new([]), state)
	var wijk = parts[0]
	await _ticks(t, 2)
	t.check(wijk.start_errors.is_empty(), "start: %s" % [wijk.start_errors])
	t.check(wijk.p1.max_health == 6 and wijk.p1.health == 6, "lampglas uit de save: %d van %d levenspunten" % [wijk.p1.health, wijk.p1.max_health])
	var s7: Node = wijk.loader.kamers[&"S7"].inhoud_node
	var neerslag: Pickup = s7.get_node(^"Neerslag")
	var sokkel = s7.get_node(^"Art/Objecten").sokkel_beeld
	t.check(neerslag.opgepakt and not neerslag.visible and sokkel != null and sokkel.frame_nu == 0,
		"S7: Neerslag opgepakt %s, zichtbaar %s, sokkel frame %s (verwacht uit)" % [neerslag.opgepakt, neerslag.visible, sokkel.frame_nu if sokkel else null])
	var blad2: Pickup = wijk.loader.kamers[&"S6"].inhoud_node.get_node(^"Logbladzijde2")
	t.check(blad2.opgepakt and not blad2.visible, "S6: logbladzijde 2 nog zichtbaar")
	t.check(wijk.boss == null and wijk.boss_spawns == 0 and wijk.is_boss_defeated() and not _closed(wijk, &"S8", "DeurLinks"),
		"S8: boss %s, spawns %d, DeurLinks dicht %s" % [wijk.boss, wijk.boss_spawns, _closed(wijk, &"S8", "DeurLinks")])
	t.check(wijk.gemaal != null and wijk.gemaal.boss_cap_released and wijk.gemaal.cap() == 200,
		"S6: het gemaal heeft nog de grens van de boss (cap %d)" % (wijk.gemaal.cap() if wijk.gemaal else -1))
	await _free(t, parts)


## GM-10, LM-12: `BOSS_VERSLAGEN` zet de vlag `S8/BossVerslagen`; als S8 ontlaadt,
## staat hij in de save. Zonder vlag staat de boss er wel en is DeurLinks dicht.
func test_boss_verslagen_in_de_save(t) -> void:
	var parts := _wijk(t, 60, &"S8", &"S4", ScriptedInput.new([]))
	var wijk = parts[0]
	var progress = parts[1]
	await _ticks(t, 2)
	t.check(wijk.boss != null and not wijk.is_boss_defeated() and _closed(wijk, &"S8", "DeurLinks"),
		"zonder vlag: boss %s, DeurLinks dicht %s" % [wijk.boss, _closed(wijk, &"S8", "DeurLinks")])
	wijk._on_boss_defeated(wijk.sim.tick)
	t.check(not progress.state.has_flag(_flag(&"S8", ^"BossVerslagen")), "de vlag staat al vóór store_world in de save")
	progress.store_world()
	t.check(progress.state.has_flag(_flag(&"S8", ^"BossVerslagen")) and not _closed(wijk, &"S8", "DeurLinks"),
		"na BOSS_VERSLAGEN: vlag %s, DeurLinks dicht %s" % [progress.state.has_flag(_flag(&"S8", ^"BossVerslagen")), _closed(wijk, &"S8", "DeurLinks")])
	await _free(t, parts)


# --- De waterstand s = 2 (LM-10) ---------------------------------------------------------

## Trap 2 vol: 180 ticks later (het water zakt, LM-10) gaat het hoogwater open,
## niet eerder; uit een save met vulstand 200 staat het meteen open.
func test_hoogwater_op_stand_2(t) -> void:
	var parts := _wijk(t, 60, &"S9", &"S4", ScriptedInput.new([]))
	var wijk = parts[0]
	await _ticks(t, 2)
	t.check(_closed(wijk, &"S9", "Hoogwater") and not wijk.hoogwater_open, "S9: hoogwater open vóór trap 2")
	var t2: int = wijk.sim.tick
	wijk._on_trap_full(t2, 2)
	await _ticks(t, Gemaal.DRAIN_TICKS - 10)
	t.check(_closed(wijk, &"S9", "Hoogwater"), "hoogwater al open %d ticks na trap 2" % (Gemaal.DRAIN_TICKS - 10))
	await _ticks(t, 20)
	var opened := _first(wijk.meetlog.rows, "WATERSTAND", "2")
	t.check(not _closed(wijk, &"S9", "Hoogwater") and opened - t2 == Gemaal.DRAIN_TICKS,
		"hoogwater open %d ticks na trap 2 (verwacht %d, LM-10)" % [opened - t2, Gemaal.DRAIN_TICKS])
	t.check(_count(wijk.meetlog.rows, "TRAP_VOL", "2") == 1 and _count(wijk.meetlog.rows, "WATERSTAND", "2") == 1,
		"meetlog: TRAP_VOL %d, WATERSTAND %d" % [_count(wijk.meetlog.rows, "TRAP_VOL"), _count(wijk.meetlog.rows, "WATERSTAND")])
	await _free(t, parts)
	var state := GameState.new()
	state.set_gemaal(_flag(&"S6", ^"Gemaal"), 200, true)
	parts = _wijk(t, 60, &"S9", &"S4", ScriptedInput.new([]), state)
	wijk = parts[0]
	await _ticks(t, 1)
	t.check(not _closed(wijk, &"S9", "Hoogwater") and wijk.hoogwater_open, "uit de save (200): hoogwater dicht")
	await _free(t, parts)
	state = GameState.new()
	state.set_gemaal(_flag(&"S6", ^"Gemaal"), 100, true)
	parts = _wijk(t, 60, &"S9", &"S4", ScriptedInput.new([]), state)
	wijk = parts[0]
	await _ticks(t, 1)
	t.check(_closed(wijk, &"S9", "Hoogwater"), "uit de save (100, trap 1): hoogwater open")
	await _free(t, parts)


# --- De lus: S1 → S9 → S1 door de arena -------------------------------------------------

## De gescripte geoefende run door de hele slice (solo): `kadewijk_bot.gd` met
## `lus` tot de arena, in S8 `boss_bot.gd` (B-9: 2 slagen per bounce, met
## ontwijken), dan de deur links uit, de trap naar het plein, trap 2 (4 + 4
## slagen met de 100 LP van GM-10), de trap af, S9 en door het snelluik terug
## op de gang van S1 (`SLICE_EIND`).
func _lus(t, d: int) -> void:
	var name := "lus D = %d" % d
	var progress := Progress.new()
	progress.name = "TestProgress"
	t.tree.root.add_child(progress)
	var wijk = Scene.instantiate()
	wijk.tail = d
	wijk.echo_on = true
	wijk.show_hud = false
	wijk.progress = progress
	wijk.start_at = Layout.ROOM_START[&"S1"]
	wijk.run_end = Kadewijk.RUN_END_LUS
	var bot := Bot.new(wijk, d, &"S1")
	bot.lus = true
	var boss_bots: Array = []
	bot.boss_input = func(sim: Node, boss: Node) -> RefCounted:
		var b := BossBot.new(sim, boss)
		boss_bots.append(b)
		return b.p1_source
	wijk.input_override = bot
	t.tree.root.add_child(wijk)
	var breaks: Array = []
	wijk.echo.broke.connect(func(tick: int, at: Vector2) -> void: breaks.append([tick, wijk.room, at]))
	var hits: Array = []
	var last_health := {"v": wijk.p1.health}
	wijk.p1.health_changed.connect(func(tick: int, health: int) -> void:
		if health < int(last_health["v"]):
			hits.append([tick, health])
		last_health["v"] = health)
	await t.tree.physics_frame
	while not wijk.run_over and wijk.sim.tick < RUN_LIMIT:
		await t.tree.physics_frame
	await _ticks(t, 2)
	if not wijk.run_over:
		wijk.meetlog.finish()
	var rows: Array = wijk.meetlog.rows
	var rep = FlowReport.from_rows(rows, true)
	t.check(wijk.start_errors.is_empty(), "start: %s" % [wijk.start_errors])
	t.check(wijk.run_over and wijk.slice_end_tick > 0 and wijk.room == &"S1",
		"%s: SLICE_EIND niet gehaald (tick %d, stap %s, sub %s, kamer %s, P1 %s)" % [
		name, wijk.sim.tick, bot.leg_name(), bot.sub, wijk.room, wijk.p1.position])
	var at := {
		"S8": -1, "boss_start": _first(rows, "BOSS_START"), "verslagen": _first(rows, "BOSS_VERSLAGEN"),
		"trap2": _first(rows, "TRAP_VOL", "2"), "water": _first(rows, "WATERSTAND", "2"), "eind": _first(rows, "SLICE_EIND"),
		"plein": int(bot.leg_done.get("S9-trap", -1)), "af": int(bot.leg_done.get("S9-trap-af", -1)),
	}
	for row in rows:
		if row[2] == "KAMER" and row[4] == "S8" and at["S8"] < 0:
			at["S8"] = int(row[0])
	var start: int = int(rows[0][0]) if not rows.is_empty() else 0
	# Volgorde: de boss, dan trap 2 (SL-02), dan het water (LM-10), dan SLICE_EIND.
	t.check(at["verslagen"] > 0 and _count(rows, "BOSS_VERSLAGEN") == 1, "%s: de boss niet verslagen (%s)" % [name, at])
	t.check(at["trap2"] > at["verslagen"] and wijk.trap_2_tick == at["trap2"] and _count(rows, "TRAP_VOL", "2") == 1,
		"%s: trap 2 niet na de boss (%s)" % [name, at])
	t.check(at["water"] == at["trap2"] + Gemaal.DRAIN_TICKS and at["eind"] > at["water"],
		"%s: hoogwater open op %d (trap 2 %d + 180), SLICE_EIND %d" % [name, at["water"], at["trap2"], at["eind"]])
	t.check(_count(rows, "SLICE_EIND") == 1 and _count(rows, "GEMAAL_VOL") == 1, "%s: SLICE_EIND %d, GEMAAL_VOL %d" % [
		name, _count(rows, "SLICE_EIND"), _count(rows, "GEMAAL_VOL")])
	# De verzamelobjecten en de sokkel (WS-08, L-12, #244).
	var picked := {"lampglas": wijk.lampglas_tick, "neerslag": wijk.neerslag_tick, "blad": wijk.logblad_ticks}
	t.check(wijk.lampglas_tick > 0 and wijk.neerslag_tick > 0 and wijk.logblad_ticks.keys().size() == 3
		and _count(rows, "LAMPGLAS") == 1 and _count(rows, "VAARDIGHEID", "V-01") == 1 and _count(rows, "LOGBLAD") == 3,
		"%s: niet alles opgepakt: %s" % [name, picked])
	t.check(wijk.p1.max_health == 6, "%s: %d maximum levenspunten na het lampglas (WS-08 a: 6)" % [name, wijk.p1.max_health])
	# De save (LM-12): alles staat erin na `store_world`.
	progress.store_world()
	var state: GameState = progress.state
	var missing: Array = []
	for spec: Array in [[&"S5", ^"Lampglas"], [&"S5", ^"Logbladzijde1"], [&"S6", ^"Logbladzijde2"],
			[&"S7", ^"Neerslag"], [&"S9", ^"Logbladzijde3"], [&"S8", ^"BossVerslagen"]]:
		if not state.has_flag(_flag(spec[0], spec[1])):
			missing.append("%s/%s" % spec)
	var g: Dictionary = state.gemalen.get(_flag(&"S6", ^"Gemaal"), {})
	t.check(missing.is_empty() and int(g.get("vulstand", 0)) == 200 and bool(g.get("vol", false)),
		"%s: niet in de save: %s, gemaal %s" % [name, missing, g])
	# Normen die de boss-run en de kamers al hebben (gemaalmeester.md §7, MP-1, L-13 f).
	t.check(_count(rows, "RESPAWN") == 0, "%s: %d respawns" % [name, _count(rows, "RESPAWN")])
	t.check(rep.longest_still <= 300, "%s: MP-1 %d > 300" % [name, rep.longest_still])
	t.check(wijk.most_at_once <= 5, "%s: %d vijanden tegelijk (L-13 f)" % [name, wijk.most_at_once])
	t.check(boss_bots.size() == 1, "%s: %d keer een boss-bot (verwacht 1: één poging)" % [name, boss_bots.size()])
	t.check(hits.size() <= 4, "%s: %d treffers op P1 (≤ 4, zoals de boss-runs)" % [name, hits.size()])
	# De echo breekt nergens bij D = 60 (V-01d, #227). Bij 120 en 180 hooguit één keer,
	# en alleen in S6 na trap 2: op de trap terug naar S9 ontlaadt S6 terwijl de echo
	# er nog loopt (kamerdoc §9, TD/WLD). Een breuk elders maakt de test rood (Lead-review TD #252).
	if d == 60:
		t.check(breaks.is_empty(), "%s: de echo brak %d× (%s)" % [name, breaks.size(), breaks])
	else:
		var elsewhere := breaks.filter(func(b: Array) -> bool:
			return Layout.room_of(b[2]) != &"S6" or int(b[0]) <= int(at["trap2"]) or int(b[0]) >= int(at["af"]))
		t.check(breaks.size() <= 1 and elsewhere.is_empty(),
			"%s: de echo brak %d× (≤ 1, alleen in S6 op de trap terug, tussen trap 2 op %d en S9 op %d): %s" % [
			name, breaks.size(), at["trap2"], at["af"], breaks])
	var seg := func(a: int, b: int) -> String: return "%d" % (b - a) if a >= 0 and b >= 0 else "?"
	t.note(("%s: run %d ticks (%.1f s) · S1 → S8 %s · S8 → BOSS_START %s · boss %s · → plein %s · trap 2 %s · → S9 (trap af) %s · " +
		"S9 → SLICE_EIND %s · per kamer %s · MP-1 %d · MP-2 %.1f per min, langste gat %d · LP %d · treffers %d (%s) · echo-breuken %d %s · " +
		"opgepakt %s · lijnen %s") % [
		name, wijk.run_ticks(), wijk.run_ticks() / 60.0, seg.call(start, at["S8"]), seg.call(at["S8"], at["boss_start"]),
		seg.call(at["boss_start"], at["verslagen"]), seg.call(at["verslagen"], at["plein"]), seg.call(at["plein"], at["trap2"]),
		seg.call(at["trap2"], at["af"]), seg.call(at["af"], at["eind"]), rep.room_time, rep.longest_still, rep.actions_per_min,
		rep.longest_gap, rep.lp_total, hits.size(), hits, breaks.size(), breaks, picked, bot.lines])
	await _free(t, [wijk, progress])


func test_lus_d60(t) -> void:
	await _lus(t, 60)


func test_lus_d120(t) -> void:
	await _lus(t, 120)


func test_lus_d180(t) -> void:
	await _lus(t, 180)
