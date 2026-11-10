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


# --- T5b deel 2: objecten in gestreamde kamers (R10) ------------------------

const PressurePlate = preload("res://scripts/objects/pressure_plate.gd")
const GameState = preload("res://scripts/save/game_state.gd")
const CombatTarget = preload("res://scripts/combat/combat_target.gd")


## Inhoud voor kamer `room` met een Eenmalige hendel, een Wissel-hendel en
## een gedeelde drukplaat, alle met middelpunt op wereld-x `x` (op de vloer).
func _object_scene(room: Kamer, x: float) -> PackedScene:
	var root := Node2D.new()
	root.name = "Inhoud"
	var at := Vector2(x, Fx.STAND_Y) - room.position
	var lever := Lever.new()
	lever.name = "Hendel"
	lever.kind = Lever.Kind.EENMALIG
	lever.setup(Layers.LIGHT | Layers.SHADOW, Vector2(40, 40))
	lever.position = at
	var toggle := Lever.new()
	toggle.name = "Wissel"
	toggle.kind = Lever.Kind.WISSEL
	toggle.setup(Layers.LIGHT | Layers.SHADOW, Vector2(40, 40))
	toggle.position = at
	var plate := PressurePlate.new()
	plate.name = "Plaat"
	plate.setup(Layers.LIGHT | Layers.SHADOW, Vector2(40, 40))
	plate.position = at
	for node: Node2D in [lever, toggle, plate]:
		root.add_child(node)
		node.owner = root
	var scene := PackedScene.new()
	scene.pack(root)
	root.free()
	return scene


func _in_sim(sim: Node, room: Kamer) -> Array:
	var found: Array = []
	for object in sim.objects:
		if room.is_ancestor_of(object):
			found.append(String(object.name))
	return found


## R10: objecten in de inhoud van een kamer doen mee zolang de kamer geladen
## is, in de tick van het laden al (stap 5), en zijn weg uit de Sim als hij
## ontlaadt. De stand van een Eenmalige hendel komt via GameState terug in
## de nieuwe instantie, en `store_objects` schrijft de stand van een geladen
## kamer weg (vóór een save). Zonder GameState begint de hendel weer los.
func test_r10_objects_in_streamed_rooms(t) -> void:
	var sim = Fx.world(t)
	var p1 := Fx.manual_player(sim, 1, Vector2(500, Fx.STAND_Y))
	var rooms := [_room("A", -1000, 640, ["B"]), _room("B", 640, 840, ["A", "C"]), _room("C", 840, 2840, ["B"])]
	var c: Kamer = rooms[2]
	c.inhoud = _object_scene(c, 1000)
	var loader := _loader(t, sim, rooms)
	var state := GameState.new()
	loader.game_state = state
	loader.start(sim.tick, p1.position)
	t.check(_in_sim(sim, c).is_empty() and c.inhoud_node == null, "C niet geladen, toch objecten: %s" % [_in_sim(sim, c)])
	# P1 naar B: C laadt, beide objecten bij de Sim in boomvolgorde.
	p1.position = Vector2(700, Fx.STAND_Y)
	await t.run_ticks(sim, 1)
	t.check(_in_sim(sim, c) == ["Hendel", "Wissel", "Plaat"], "C geladen, objecten in de Sim: %s" % [_in_sim(sim, c)])
	# P1 op de plaat in C: de plaat volgt hem in dezelfde tick (stap 5).
	var plate_ticks: Array = []
	var plate: PressurePlate = c.inhoud_node.get_node("Plaat")
	plate.changed.connect(func(tick: int, on: bool) -> void: plate_ticks.append([tick, on]))
	var t_on: int = sim.tick
	p1.position = Vector2(1000, Fx.STAND_Y)
	await t.run_ticks(sim, 2)
	t.check(plate.active and plate_ticks.size() == 1 and plate_ticks[0][0] == t_on,
		"plaat in gestreamde inhoud volgt P1 niet in dezelfde tick: %s (tick %d)" % [plate_ticks, t_on])
	var lever: Lever = c.inhoud_node.get_node("Hendel")
	var toggle: Lever = c.inhoud_node.get_node("Wissel")
	lever.interact(p1, sim.tick)
	toggle.interact(p1, sim.tick)
	loader.store_objects()
	var flag := AreaLoader.object_flag(&"C", ^"Hendel")
	var toggle_flag := AreaLoader.object_flag(&"C", ^"Wissel")
	t.check(lever.on and toggle.on and state.has_flag(flag) and state.has_flag(toggle_flag),
		"store_objects schreef de vlaggen niet (%s)" % [state.vlaggen])
	# Wis de vlaggen: dan moet het ontladen ze zelf opnieuw schrijven.
	state.set_flag(flag, false)
	state.set_flag(toggle_flag, false)
	# P1 terug naar A: C ontlaadt; objecten uit de Sim, stand in GameState.
	p1.position = Vector2(500, Fx.STAND_Y)
	await t.run_ticks(sim, 1)
	t.check(c.inhoud_node == null and sim.objects.is_empty(), "C ontladen, nog %d objecten in de Sim" % sim.objects.size())
	t.check(state.has_flag(flag) and state.has_flag(toggle_flag),
		"stand van de hendels niet bewaard bij ontladen: %s" % [state.vlaggen])
	# Weer naar B: nieuwe instanties, met hun stand uit GameState vóór elke
	# bediening. De Eenmalige blijft daarna vast (E-13); de Wissel staat aan.
	p1.position = Vector2(700, Fx.STAND_Y)
	await t.run_ticks(sim, 1)
	var again: Lever = c.inhoud_node.get_node("Hendel")
	var toggle_again: Lever = c.inhoud_node.get_node("Wissel")
	t.check(not is_instance_valid(lever) and not is_instance_valid(toggle) and sim.objects.has(again),
		"na opnieuw laden geen nieuwe instanties in de Sim")
	t.check(again.on and toggle_again.on, "stand niet terug na opnieuw laden: Eenmalig %s, Wissel %s" % [again.on, toggle_again.on])
	again.interact(p1, sim.tick)
	t.check(again.on, "Eenmalige hendel ging na opnieuw laden weer om (niet vast)")
	# Zonder GameState: na opnieuw laden de standaardstand.
	loader.game_state = null
	p1.position = Vector2(500, Fx.STAND_Y)
	await t.run_ticks(sim, 1)
	p1.position = Vector2(700, Fx.STAND_Y)
	await t.run_ticks(sim, 1)
	t.check(not (c.inhoud_node.get_node("Hendel") as Lever).on and not (c.inhoud_node.get_node("Wissel") as Lever).on,
		"zonder GameState toch een stand bewaard")
	await t.cleanup()


## `Sim.remove_object` voor een vijand (gestreamde inhoud kan vijanden
## bevatten): weg uit de objecten en uit Combat, zijn merk dooft, en het
## signaal is los. De volgende tick loopt zonder fout door.
func test_r10_remove_combat_target(t) -> void:
	var sim = Fx.world(t)
	Fx.manual_player(sim, 1, Vector2(200, Fx.STAND_Y))
	var target := Fx.target(sim, CombatTarget.Kind.ENEMY, 400)
	sim.combat._set_mark(sim.tick, target, "P1")
	var mark = sim.combat.mark_on(target)
	sim.remove_object(target)
	t.check(not sim.objects.has(target) and not sim.combat.targets.has(target), "vijand nog aangemeld")
	t.check(mark != null and not mark.alive, "merk op een afgemelde vijand leeft nog")
	t.check(not target.hit_player.is_connected(sim._on_enemy_hit_player), "hit_player nog verbonden")
	target.queue_free()
	await t.run_ticks(sim, 2)
	await t.cleanup()


# --- T5b deel 2: P2 in een kamer die niet geladen is (keuze (c), §3a) -------

## Legt het oplossen (C-06) en het terugkomen van P2 vast: [tick, oorzaak, plek].
func _partner_log(sim: Node) -> Dictionary:
	var log := {"gone": [], "back": []}
	sim.partner_dissolved.connect(func(tick: int, at: Vector2, cause: String) -> void:
		log["gone"].append([tick, cause, at]))
	sim.partner_returned.connect(func(tick: int, at: Vector2) -> void:
		log["back"].append([tick, at]))
	return log


## C-06, keuze (c): P1 blijft in A (buur B, C geen buur van A). P2 loopt van A
## via B naar C: in B niets; op de tick waarop zijn middelpunt in C komt één
## melding, en P2 lost op díé tick op met de oorzaak `ontladen` (gdd §4.5),
## zonder kamerwissel. 120 ticks later staat hij naast P1 (C-03).
## Daarna: P1 in B (C geladen), P2 in C: niets. P1 terug naar A ontlaadt C:
## P2 lost op op de tick van de kamerwissel.
func test_c06_partner_in_unloaded_room(t) -> void:
	var sim = Fx.world(t)
	# P1 en P2 dicht bij elkaar, en P2 stopt net in C: zo grijpt de leiband
	# (C-07, 60 ticks buiten beeld) niet in.
	var p1 := Fx.manual_player(sim, 1, Vector2(600, Fx.STAND_Y))
	var p2 := Fx.manual_player(sim, 2, Vector2(620, Fx.STAND_Y))
	p2.input_source.bits = R
	var loader := _loader(t, sim, [
		_room("A", -1000, 640, ["B"]), _room("B", 640, 840, ["A", "C"]), _room("C", 840, 2840, ["B"])])
	loader.start(sim.tick, p1.position)
	var reports: Array = []
	loader.partner_in_ontladen_kamer.connect(func(tick: int, who: PlayerActor, kamer: StringName) -> void:
		reports.append([tick, who == p2, String(kamer)]))
	var log := _partner_log(sim)
	var switches := _switches(loader)
	var p2_x := {}
	sim.partner_dissolved.connect(func(_tick: int, _at: Vector2, _cause: String) -> void:
		p2.input_source.bits = 0)
	sim.tick_finished.connect(func(tick: int) -> void:
		if not p2.dissolved:
			p2_x[tick] = p2.position.x)
	# P2 komt rond tick 110 in C; 120 ticks later terug.
	await t.run_ticks(sim, 300)
	var gone: Array = log["gone"]
	var t_c: int = gone[0][0] if not gone.is_empty() else -1
	t.check(t_c > 0 and reports == [[t_c, true, "C"]],
		"melding P2 in ontladen C: %s (opgelost op tick %d)" % [reports, t_c])
	t.check(gone.size() == 1 and gone[0][1] == "ontladen" and loader.room_at(gone[0][2]) == &"C"
		and p2_x.get(t_c - 1, 9999.0) < 840.0, "oplossen: %s (P2 vóór t_c op x %s)" % [gone, p2_x.get(t_c - 1)])
	t.check(switches.is_empty() and loader.huidige == &"A" and not loader.is_partner_outside(),
		"P2 wisselde de kamer, of telt als opgelost nog als Buiten")
	var back: Array = log["back"]
	t.check(back.size() == 1 and back[0][0] == t_c + 120 and not p2.dissolved and p2.visible
		and p2.position.distance_to(p1.position) <= 64.0 and loader.room_at(p2.global_position) == &"A",
		"terug: %s (verwacht op tick %d, naast P1 op %s)" % [back, t_c + 120, p1.position])
	# P1 in B: C geladen; P2 in C telt dan niet.
	p1.position = Vector2(700, Fx.STAND_Y)
	await t.run_ticks(sim, 1)
	p2.position = Vector2(900, Fx.STAND_Y)
	await t.run_ticks(sim, 2)
	t.check(loader.is_loaded(&"C") and gone.size() == 1 and not p2.dissolved, "P2 in geladen C opgelost: %s" % [gone])
	# De kamerwissel van P1 terug naar A ontlaadt C: P2 lost op díé tick op.
	p1.position = Vector2(600, Fx.STAND_Y)
	var t_back: int = sim.tick
	await t.run_ticks(sim, 1)
	t.check(not loader.is_loaded(&"C") and reports.size() == 2 and reports[1] == [t_back, true, "C"]
		and gone.size() == 2 and gone[1][0] == t_back and gone[1][1] == "ontladen" and p2.dissolved,
		"kamerwissel ontlaadt C: meldingen %s, opgelost %s (tick %d)" % [reports, gone, t_back])
	await t.cleanup()


## C-06, keuze (c), met `force_unloaded` (debugmenu, gdd §4.6): P2 in B, B
## wordt uitgezet: op de volgende tick lost P2 op (`ontladen`). P2 in een gat
## tussen kamers (keuze (a)): geen oorzaak, ook niet als de kamer ernaast
## niet geladen is.
func test_c06_force_unloaded_and_gap(t) -> void:
	var sim = Fx.world(t)
	var p1 := Fx.manual_player(sim, 1, Vector2(600, Fx.STAND_Y))
	var p2 := Fx.manual_player(sim, 2, Vector2(700, Fx.STAND_Y))
	# A en B grenzen; tussen B en C ligt een gat [900, 960).
	var loader := _loader(t, sim, [
		_room("A", -1000, 640, ["B"]), _room("B", 640, 900, ["A", "C"]), _room("C", 960, 2000, ["B"])])
	loader.start(sim.tick, p1.position)
	var log := _partner_log(sim)
	await t.run_ticks(sim, 2)
	t.check(log["gone"].is_empty(), "P2 opgelost in geladen B: %s" % [log["gone"]])
	loader.force_unloaded(&"B", true)
	var t0: int = sim.tick
	await t.run_ticks(sim, 1)
	t.check(log["gone"].size() == 1 and log["gone"][0][0] == t0 and log["gone"][0][1] == "ontladen" and p2.dissolved,
		"force_unloaded(B): %s (verwacht op tick %d)" % [log["gone"], t0])
	await t.run_ticks(sim, 121)
	t.check(log["back"].size() == 1 and log["back"][0][0] == t0 + 120 and not p2.dissolved,
		"terug na force_unloaded: %s" % [log["back"]])
	# P2 in het gat: geen oorzaak (keuze (a)), ook met B en C uit.
	loader.force_unloaded(&"C", true)
	p2.position = Vector2(930, Fx.STAND_Y)
	await t.run_ticks(sim, 5)
	t.check(log["gone"].size() == 1 and not p2.dissolved and loader.room_at(p2.global_position) == &"",
		"P2 in een gat opgelost: %s" % [log["gone"]])
	await t.cleanup()


# --- SM-punt: AreaLoader.start controleert de startkamer --------------------

func test_start_checks_start_room(t) -> void:
	var loader := AreaLoader.new()
	for room: Kamer in [_room("A", 0, 100, ["B"]), _room("B", 100, 200, ["A"])]:
		loader.add_kamer(room)
	t.check(loader.start_errors(Vector2(150, 0), &"B").is_empty() and loader.start_room(Vector2(150, 0), &"B") == &"B",
		"geldige start geeft fouten: %s" % loader.start_errors(Vector2(150, 0), &"B"))
	var unknown := loader.start_errors(Vector2(50, 0), &"Z")
	t.check(unknown.size() == 1 and unknown[0].contains("'Z' bestaat niet") and loader.start_room(Vector2(50, 0), &"Z") == &"A",
		"onbekende startkamer: %s" % unknown)
	var elsewhere := loader.start_errors(Vector2(50, 0), &"B")
	t.check(elsewhere.size() == 1 and elsewhere[0].contains("niet in startkamer 'B'"), "positie buiten de kamer: %s" % elsewhere)
	var nowhere := loader.start_errors(Vector2(500, 0))
	t.check(nowhere.size() == 1 and nowhere[0].contains("geen enkele kamer"), "positie in geen kamer: %s" % nowhere)
	for id in loader.kamers:
		loader.kamers[id].free()
	loader.free()
