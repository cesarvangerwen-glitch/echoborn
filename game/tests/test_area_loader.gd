extends RefCounted
## Tests voor de AreaLoader v1 en de echo door de deur (T5b, #82): E-04a
## (1)–(5) en E-04e uit gdd §4.6, plus het laden en ontladen van de inhoud
## van kamers en een rechte doorloop door drie kamers zonder reset (FK-3).
##
## "(alle D)" = voor D = 90, 120 en 180. Posities van de echo worden exact
## vergeleken (standaarden §6).

const Fx = preload("res://tests/echo_fixture.gd")
const InputBits = preload("res://scripts/input/input_bits.gd")
const PlayerActor = preload("res://scripts/echo/player_actor.gd")
const TailEcho = preload("res://scripts/echo/tail_echo.gd")
const GameEvents = preload("res://scripts/events/game_events.gd")
const Lever = preload("res://scripts/objects/lever.gd")
const Layers = preload("res://scripts/world/layers.gd")
const Kamer = preload("res://scripts/world/kamer.gd")
const Motor = preload("res://scripts/echo/motor.gd")
const AreaLoader = preload("res://scripts/world/area_loader.gd")

const R := InputBits.RIGHT
const L := InputBits.LEFT
const ALL_D := [90, 120, 180]
## Hoogte van alle testkamers: ruim boven en onder de vloer (y = 400).
const TOP := -400.0
const HEIGHT := 1200.0


func _room(id: String, x0: float, x1: float, buren: Array) -> Kamer:
	return Kamer.make(StringName(id), Rect2(x0, TOP, x1 - x0, HEIGHT), buren) as Kamer


## Zet de kamers in de wereld, maakt de loader en koppelt hem aan de Sim.
## `start` doet de test zelf, als P1 er staat.
func _loader(t, sim: Node, rooms: Array) -> AreaLoader:
	var loader := AreaLoader.new()
	loader.name = "AreaLoader"
	for room: Kamer in rooms:
		t.world_root().add_child(room)
		loader.add_kamer(room)
	t.world_root().add_child(loader)
	sim.set_area_loader(loader)
	return loader


## Per tick na stap (5): P1, de echo, Actief, Buiten en geldig_vanaf.
func _trace(sim: Node, p1: PlayerActor, echo: TailEcho) -> Dictionary:
	var log := {"p1": {}, "echo": {}, "present": {}, "outside": {}, "valid_from": {}}
	sim.tick_finished.connect(func(tick: int) -> void:
		log["p1"][tick] = p1.position
		log["echo"][tick] = echo.position
		log["present"][tick] = echo.is_present()
		log["outside"][tick] = echo.is_outside()
		log["valid_from"][tick] = echo.valid_from)
	return log


func _switches(loader: AreaLoader) -> Array:
	var switches: Array = []
	loader.kamer_gewisseld.connect(func(tick: int, van: StringName, naar: StringName, reset: bool) -> void:
		switches.append([tick, String(van), String(naar), reset]))
	return switches


## Eerste tick waarop P1 (na zijn stap) in [from, to) van x staat, vanaf `after`.
func _first_tick_in(log: Dictionary, from: float, to: float, after: int = 0) -> int:
	var ticks: Array = log["p1"].keys()
	ticks.sort()
	for tick: int in ticks:
		var x: float = log["p1"][tick].x
		if tick >= after and x >= from and x < to:
			return tick
	return -1


# --- E-04a (1), (2) en E-04e ------------------------------------------------

## (alle D) A en B zijn buren. P1 loopt van A naar B en terug. Elke wissel
## valt op de tick waarop het middelpunt van P1 de grens over gaat (E-04e) en
## is geen reset; de echo loopt D ticks later door dezelfde doorgang, 0 px van
## het opgenomen pad, en is na D geen enkele tick Leeg.
func test_e04a_neighbour_switch_no_reset_all_d(t) -> void:
	for d: int in ALL_D:
		var sim = Fx.world(t)
		var p1 := Fx.p1(sim, [[120, R], [120, L], [400, 0]], Vector2(500, Fx.STAND_Y))
		var echo := Fx.tail_echo(sim, p1, d)
		var loader := _loader(t, sim, [_room("A", -1000, 640, ["B"]), _room("B", 640, 1280, ["A"])])
		var errors := loader.start(sim.tick, p1.position)
		var switches := _switches(loader)
		var log := _trace(sim, p1, echo)
		var total := 240 + d + 20
		await t.run_ticks(sim, total)
		var t_in := _first_tick_in(log, 640, 1280)
		var t_back := _first_tick_in(log, -1000, 640, t_in)
		t.check(errors.is_empty(), "D=%d: indeling geeft fouten %s" % [d, errors])
		t.check(t_in > 0 and t_back > t_in, "D=%d: P1 ging niet heen en terug (%d, %d)" % [d, t_in, t_back])
		t.check(switches == [[t_in, "A", "B", false], [t_back, "B", "A", false]],
			"D=%d: wissels %s, verwacht A→B op %d en B→A op %d, zonder reset" % [d, switches, t_in, t_back])
		var off := 0
		var empty := 0
		for tick in range(d, total):
			if not log["present"][tick]:
				empty += 1
			elif log["echo"][tick] != log["p1"][tick - d]:
				off += 1
		t.check(empty == 0 and off == 0, "D=%d: na D %d ticks Leeg en %d ticks naast het pad" % [d, empty, off])
		t.check(log["echo"][t_in + d].x >= 640.0 and log["echo"][t_in + d - 1].x < 640.0,
			"D=%d: echo gaat niet op t0 + D door de doorgang" % d)
		t.check(log["valid_from"][total - 1] == 0, "D=%d: geldig_vanaf veranderde" % d)
		t.check(loader.loaded_ids() == [&"A", &"B"], "D=%d: geladen %s" % [d, loader.loaded_ids()])
		await t.cleanup()


# --- E-04a (3) --------------------------------------------------------------

## (alle D) P1 wordt van B naar C gezet (debug-teleport); C is geen buur van
## B: reset op die tick. De echo is Leeg op t0 + D − 1 en Actief op t0 + D, op
## de plek van P1 op t0.
func test_e04a_teleport_to_non_neighbour_resets_all_d(t) -> void:
	for d: int in ALL_D:
		var sim = Fx.world(t)
		var p1 := Fx.p1(sim, [], Vector2(700, Fx.STAND_Y))
		var echo := Fx.tail_echo(sim, p1, d)
		var loader := _loader(t, sim, [
			_room("A", -1000, 640, ["B"]), _room("B", 640, 1280, ["A"]), _room("C", 1280, 2280, [])])
		loader.start(sim.tick, p1.position)
		var switches := _switches(loader)
		var log := _trace(sim, p1, echo)
		await t.run_ticks(sim, 200)
		var t0: int = sim.tick
		p1.position = Vector2(1500, Fx.STAND_Y)
		await t.run_ticks(sim, d + 10)
		t.check(switches == [[t0, "B", "C", true]], "D=%d: wissels %s, verwacht B→C met reset op %d" % [d, switches, t0])
		t.check(log["valid_from"][t0] == t0 and log["present"][t0 - 1],
			"D=%d: geldig_vanaf %d op t0 = %d" % [d, log["valid_from"][t0], t0])
		var leeg_ok := true
		for tick in range(t0, t0 + d):
			if log["present"][tick] or log["outside"][tick]:
				leeg_ok = false
		t.check(leeg_ok, "D=%d: echo niet Leeg (zonder Buiten) op t0 … t0 + D − 1" % d)
		t.check(log["present"][t0 + d] and log["echo"][t0 + d] == log["p1"][t0],
			"D=%d: op t0 + D niet Actief op %s (staat op %s)" % [d, log["p1"][t0], log["echo"][t0 + d]])
		t.check(loader.loaded_ids() == [&"C"], "D=%d: geladen %s, verwacht alleen C" % [d, loader.loaded_ids()])
		await t.cleanup()


# --- E-04a (4) --------------------------------------------------------------

## A wordt op t1 als niet geladen gemarkeerd terwijl frame p in A ligt: de
## echo is Buiten (onzichtbaar, geen plank: P1 valt erdoor, een INTERACTIE in
## A wordt niet uitgevoerd), geldig_vanaf blijft gelijk; zodra frame p in B
## ligt, is hij weer Actief op zijn opname. Hoogtes van P1 met 0,1 px marge
## (de veilige marge van `move_and_slide`). Ter controle draait hetzelfde
## zonder ontladen: dan staat P1 op de plank en gaat de hendel om.
func test_e04a_outside_when_room_not_loaded(t) -> void:
	for unload: bool in [false, true]:
		var label := "ontladen" if unload else "controle"
		var sim = Fx.world(t)
		var ghost := Fx.ghost(t)
		for k in 400:
			var at := Vector2(600 if k < 200 else 700, Fx.STAND_Y)
			Fx.ghost_frame(ghost, k, at, true, Motor.Support.WORLD, GameEvents.INTERACT if k == 120 else 0)
		var echo := Fx.tail_echo(sim, ghost, 10)
		var p1 := Fx.manual_player(sim, 1, Vector2(600, Fx.ON_ECHO_Y - 40))
		var lever := Lever.new()
		lever.setup(Layers.SHADOW, Vector2(40, 40))
		lever.position = Vector2(600, Fx.STAND_Y)
		sim.add_object(lever)
		var loader := _loader(t, sim, [_room("A", -1000, 640, ["B"]), _room("B", 640, 1280, ["A"])])
		loader.start(sim.tick, p1.position)
		var log := _trace(sim, p1, echo)
		var echo_events: Array = []
		sim.event_executed.connect(func(tick: int, kind: int, actor: Node2D, _target: Node) -> void:
			if actor == echo:
				echo_events.append([tick, kind]))
		await t.run_ticks(sim, 100)
		if unload:
			loader.force_unloaded(&"A", true)
		await t.run_ticks(sim, 120)
		t.check(log["present"][99] and absf(log["p1"][99].y - Fx.ON_ECHO_Y) < 0.1,
			"%s: P1 staat op tick 99 niet op de plank (y %s)" % [label, log["p1"][99].y])
		if unload:
			var outside := true
			for tick in range(100, 210):
				if log["present"][tick] or not log["outside"][tick]:
					outside = false
			t.check(outside, "ontladen: echo niet Buiten op tick 100–209")
			t.check(absf(log["p1"][150].y - Fx.STAND_Y) < 0.1, "ontladen: P1 valt niet door de plank (y %s)" % log["p1"][150].y)
			t.check(not lever.on and echo_events.is_empty(),
				"ontladen: INTERACTIE in A uitgevoerd (%s)" % [echo_events])
			t.check(log["present"][210] and not log["outside"][210] and log["echo"][210] == Vector2(700, Fx.STAND_Y),
				"ontladen: op tick 210 niet Actief op (700, %s) maar %s" % [Fx.STAND_Y, log["echo"][210]])
		else:
			t.check(absf(log["p1"][150].y - Fx.ON_ECHO_Y) < 0.1 and lever.on and echo_events == [[130, GameEvents.INTERACT]],
				"controle: P1 y %s, hendel %s, events %s" % [log["p1"][150].y, lever.on, echo_events])
		var same := true
		for tick in range(0, 220):
			if log["valid_from"][tick] != 0:
				same = false
		t.check(same, "%s: geldig_vanaf veranderde" % label)
		await t.cleanup()


# --- E-04a (5) --------------------------------------------------------------

## Validatie bij het laden: buren die niet wederzijds zijn, onbekende buren,
## een kamer die zichzelf als buur heeft, overlappende en dubbele kamers.
func test_e04a_validation_errors(t) -> void:
	var good := AreaLoader.new()
	for room: Kamer in [_room("A", 0, 100, ["B"]), _room("B", 100, 200, ["A"])]:
		good.add_kamer(room)
	t.check(good.validate().is_empty(), "geldige indeling geeft fouten: %s" % good.validate())
	var one_way := AreaLoader.new()
	for room: Kamer in [_room("A", 0, 100, ["B"]), _room("B", 100, 200, [])]:
		one_way.add_kamer(room)
	var e1 := one_way.validate()
	t.check(e1.size() == 1 and e1[0].contains("niet andersom"), "eenrichtingsburen: %s" % e1)
	var bad := AreaLoader.new()
	var bad_rooms := [_room("A", 0, 100, ["Z", "A"]), _room("B", 50, 200, []), _room("B", 300, 400, [])]
	for room: Kamer in bad_rooms:
		bad.add_kamer(room)
	var e2 := " | ".join(bad.validate())
	for part: String in ["onbekende buur 'Z'", "zichzelf als buur", "overlappen", "twee keer"]:
		t.check(e2.contains(part), "fout '%s' ontbreekt in: %s" % [part, e2])
	for room: Kamer in bad_rooms:
		room.free()
	for loader: AreaLoader in [good, one_way]:
		for id in loader.kamers:
			loader.kamers[id].free()
	for loader: AreaLoader in [good, one_way, bad]:
		loader.free()


# --- E-04e ------------------------------------------------------------------

## P2 gaat in co-op naar kamer B terwijl P1 in A blijft: geen kamerwissel.
## Daarna zet een wissel van P1 naar een kamer die geen buur is, geldig_vanaf.
func test_e04e_p2_never_switches_room(t) -> void:
	var sim = Fx.world(t)
	var p1 := Fx.manual_player(sim, 1, Vector2(500, Fx.STAND_Y))
	var p2 := Fx.manual_player(sim, 2, Vector2(560, Fx.STAND_Y))
	p2.input_source.bits = R
	var loader := _loader(t, sim, [
		_room("A", -1000, 640, ["B"]), _room("B", 640, 1280, ["A"]), _room("C", 1280, 2280, [])])
	loader.start(sim.tick, p1.position)
	var switches := _switches(loader)
	await t.run_ticks(sim, 200)
	t.check(p2.position.x > 700.0, "P2 kwam niet in B (x %s)" % p2.position.x)
	t.check(switches.is_empty() and loader.huidige == &"A", "kamerwissel door P2: %s" % [switches])
	# C-04: een kamerwissel van P1 naar een kamer die geen buur is, zet ook
	# in co-op (zonder echo) geldig_vanaf bij P1.
	var t0: int = sim.tick
	p1.position = Vector2(1500, Fx.STAND_Y)
	await t.run_ticks(sim, 2)
	t.check(loader.huidige == &"C" and p1.echo_valid_from == t0,
		"co-op: teleport naar C zette geldig_vanaf %d (%d)" % [p1.echo_valid_from, t0])


# --- Streamen en FK-3 -------------------------------------------------------

## (alle D) Drie kamers in een rij, A–B en B–C buren, A en C niet; elke kamer
## heeft inhoud die meestreamt. P1 loopt rechtdoor van A naar C: geen reset
## (FK-3), geladen is steeds P1's kamer met zijn buren, en de inhoud van een
## ontladen kamer is weg. B is smal (200 px): zolang frame p nog in A ligt
## terwijl P1 al in C is, is de echo Buiten, daarna weer Actief op zijn pad.
func test_streaming_and_outside_in_a_row_all_d(t) -> void:
	for d: int in ALL_D:
		var sim = Fx.world(t)
		var p1 := Fx.p1(sim, [[400, R]], Vector2(500, Fx.STAND_Y))
		var echo := Fx.tail_echo(sim, p1, d)
		var rooms := [_room("A", -1000, 640, ["B"]), _room("B", 640, 840, ["A", "C"]), _room("C", 840, 2840, ["B"])]
		for room: Kamer in rooms:
			room.inhoud = _content_scene(room.id())
		var loader := _loader(t, sim, rooms)
		loader.start(sim.tick, p1.position)
		var loaded_at_start := loader.loaded_ids()
		var content_at_start: bool = rooms[0].inhoud_node != null and rooms[2].inhoud_node == null
		var log := _trace(sim, p1, echo)
		var loaded_log := {}
		sim.tick_finished.connect(func(tick: int) -> void: loaded_log[tick] = loader.loaded_ids())
		var total := 400
		await t.run_ticks(sim, total)
		var t_b := _first_tick_in(log, 640, 840)
		var t_c := _first_tick_in(log, 840, 2840)
		t.check(loaded_at_start == [&"A", &"B"] and content_at_start, "start: geladen %s" % [loaded_at_start])
		t.check(loaded_log[t_b - 1] == [&"A", &"B"] and loaded_log[t_b] == [&"A", &"B", &"C"]
			and loaded_log[t_c] == [&"B", &"C"], "D=%d: geladen rond de wissels klopt niet" % d)
		t.check(rooms[0].inhoud_node == null and rooms[0].get_child_count() == 1
			and rooms[2].inhoud_node != null and rooms[2].inhoud_node.get_parent() == rooms[2],
			"D=%d: inhoud van A niet weg of van C niet geladen" % d)
		# Buiten: van t_c (A ontladen) tot frame p in B ligt (t_b + D).
		var wrong := 0
		var outside_ticks := 0
		for tick in range(d, total):
			var expect_outside := tick >= t_c and tick < t_b + d
			if expect_outside:
				outside_ticks += 1
			if log["outside"][tick] != expect_outside or log["present"][tick] == expect_outside:
				wrong += 1
			elif not expect_outside and log["echo"][tick] != log["p1"][tick - d]:
				wrong += 1
		t.check(wrong == 0, "D=%d: %d ticks verkeerd (Buiten verwacht op %d–%d)" % [d, wrong, t_c, t_b + d - 1])
		t.check(log["valid_from"][total - 1] == 0, "D=%d: reset bij een doorloop door buren (FK-3)" % d)
		t.note("D=%d: P1 in B op %d, in C op %d; echo %d ticks Buiten" % [d, t_b, t_c, outside_ticks])
		await t.cleanup()


func _content_scene(id: StringName) -> PackedScene:
	var node := Node2D.new()
	node.name = "Inhoud_%s" % id
	var scene := PackedScene.new()
	scene.pack(node)
	node.free()
	return scene
