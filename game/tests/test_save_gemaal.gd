extends RefCounted
## Tests voor T5b deel 3b (#82; ontwerp.md §3a en §7): een gemaal in de
## gestreamde inhoud van een kamer, en een pompslag als checkpoint (LM-08).
##
## - Bij het laden van de kamer krijgt het gemaal uit de scène zijn pomprad
##   en sluis (geëxporteerde paden), de lichtmeter en zijn stand (via
##   `Progress.bind_gemaal`) en een verbinding met `Combat`; bij ontladen gaat
##   zijn stand naar `state` en wordt het losgemaakt.
## - Een pompslag van P1 of P2 zet het checkpoint naast het gemaal, ook
##   zonder in het vlak te komen; de echo niet (LM-08).
##
## Elke test maakt een eigen `Progress` (en zo nodig `SaveService`) met een
## eigen map; de echte autoloads en `user://saves` blijven onaangeroerd.

const Fx = preload("res://tests/echo_fixture.gd")
const GameState = preload("res://scripts/save/game_state.gd")
const SaveService = preload("res://scripts/save/save_service.gd")
const Progress = preload("res://scripts/save/progress.gd")
const Checkpoint = preload("res://scripts/save/checkpoint.gd")
const Kamer = preload("res://scripts/world/kamer.gd")
const AreaLoader = preload("res://scripts/world/area_loader.gd")
const Layers = preload("res://scripts/world/layers.gd")
const LightMeter = preload("res://scripts/light/light_meter.gd")
const Gemaal = preload("res://scripts/light/gemaal.gd")
const Pomprad = preload("res://scripts/light/pomprad.gd")
const CombatTarget = preload("res://scripts/combat/combat_target.gd")
const Respawn = preload("res://scripts/save/respawn.gd")
const PlayerActor = preload("res://scripts/echo/player_actor.gd")

const DIR := "user://test_saves_t5b_3b"
const TOP := -400.0
const HEIGHT := 1200.0
const GEBIED := &"testgebied"
## P1 in kamer A: C is niet geladen. P1 in B: C is geladen.
const IN_A := Vector2(200, Fx.STAND_Y)
const IN_B := Vector2(1000, Fx.STAND_Y)
const ROOM_C := Rect2(1640, TOP, 1360, HEIGHT)
const POMPRAD_AT := Vector2(2500, Fx.STAND_Y)
const CHECKPOINT_AT := Vector2(2200, Fx.STAND_Y)
const STREET := Rect2(2600, 300, 300, 100)


func _clear() -> void:
	var dir := DirAccess.open(DIR)
	if dir == null:
		return
	for file in dir.get_files():
		dir.remove(file)
	DirAccess.remove_absolute(DIR)


## De inhoud van kamer C, zoals de World & Level Designer hem in de editor
## zou bouwen: pomprad, sluis, gemaal (met paden) en een checkpoint dat naar
## het gemaal wijst. Posities ten opzichte van de kamer.
func _gemaal_scene() -> PackedScene:
	var origin := ROOM_C.get_center()
	var root := Node2D.new()
	root.name = "Inhoud"
	var pomprad := Pomprad.new()
	pomprad.name = "Pomprad"
	pomprad.position = POMPRAD_AT - origin
	var sluice := StaticBody2D.new()
	sluice.name = "Sluis"
	sluice.collision_layer = Layers.WORLD
	sluice.position = Vector2(2950, 350) - origin
	var shape := CollisionShape2D.new()
	shape.name = "Vorm"
	var box := RectangleShape2D.new()
	box.size = Vector2(20, 100)
	shape.shape = box
	sluice.add_child(shape)
	var gemaal := Gemaal.new()
	gemaal.name = "Gemaal"
	gemaal.position = Vector2(2700, Fx.STAND_Y) - origin
	gemaal.pomprad_path = ^"../Pomprad"
	gemaal.sluice_path = ^"../Sluis"
	gemaal.street = STREET
	gemaal.y_high = 320.0
	gemaal.y_low = 390.0
	var checkpoint := Checkpoint.new()
	checkpoint.name = "Checkpoint"
	checkpoint.setup(Layers.LIGHT, Vector2(40, 40))
	checkpoint.position = CHECKPOINT_AT - origin
	checkpoint.gemaal_path = ^"../Gemaal"
	for node: Node in [pomprad, sluice, gemaal, checkpoint]:
		root.add_child(node)
		node.owner = root
	shape.owner = root
	var scene := PackedScene.new()
	scene.pack(root)
	root.free()
	return scene


## Kamers A – B – C (C alleen buur van B), het gemaal in de inhoud van C, een
## eigen Progress met lichtmeter. `state` wordt vóór het binden overgenomen.
## Geeft {sim, p1, loader, progress, meter, c, id}.
func _world(t, state: GameState, progress: Progress = null, sim: Node = null) -> Dictionary:
	if sim == null:
		sim = Fx.world(t)
	var p1 := Fx.manual_player(sim, 1, IN_A)
	if progress == null:
		progress = Progress.new()
		progress.name = "TestProgress"
		t.world_root().add_child(progress)
		progress.adopt(state, -1)
	var a: Kamer = Kamer.make(&"A", Rect2(-1000, TOP, 1640, HEIGHT), ["B"])
	var b: Kamer = Kamer.make(&"B", Rect2(640, TOP, 1000, HEIGHT), ["A", "C"])
	var c: Kamer = Kamer.make(&"C", ROOM_C, ["B"])
	c.inhoud = _gemaal_scene()
	var loader := AreaLoader.new()
	loader.name = "AreaLoader"
	for room: Kamer in [a, b, c]:
		t.world_root().add_child(room)
		loader.add_kamer(room)
	t.world_root().add_child(loader)
	sim.set_area_loader(loader)
	var meter := LightMeter.new(sim, p1)
	progress.bind_area_loader(loader, GEBIED)
	progress.bind_meter(meter)
	var errors := loader.start(sim.tick, p1.position)
	t.check(errors.is_empty(), "start: %s" % [errors])
	return {"sim": sim, "p1": p1, "loader": loader, "progress": progress, "meter": meter, "c": c,
		"id": AreaLoader.object_flag(&"C", ^"Gemaal", GEBIED)}


## Een treffer van `attacker` op het pomprad, via de echte weg van stap (4)
## (`Combat.attack`): alleen een geladen, aangemeld pomprad wordt geraakt.
func _strike(sim: Node, attacker: String, layer: int) -> void:
	sim.combat.attack(sim.tick, attacker, layer, POMPRAD_AT - Vector2(16, 0), 1)


## Gemaal in gestreamde inhoud (deel 3b, punt 1): niet geladen = niet
## gebonden; laden = pomprad en sluis uit de paden, meter en stand via
## Progress, aangemeld bij Combat (een treffer pompt); ontladen = stand naar
## `state`, los van Combat, `store_world` slaat het over; opnieuw laden = de
## stand terug. Een vol gemaal laadt in zijn eindstand (sluis open).
func test_gemaal_in_streamed_room(t) -> void:
	var state := GameState.new()
	state.lichtmeter = 50
	var w := _world(t, state)
	var sim = w["sim"]
	var p1: Node2D = w["p1"]
	var progress: Progress = w["progress"]
	var meter: LightMeter = w["meter"]
	var c: Kamer = w["c"]
	var id: StringName = w["id"]
	state.set_gemaal(id, 30, false)
	var hits_before: int = sim.combat.hit.get_connections().size()
	t.check(c.inhoud_node == null and not progress.has_gemaal(id), "C geladen of gemaal gebonden vóór P1 in B")
	p1.position = IN_B
	await t.run_ticks(sim, 1)
	t.check(c.inhoud_node != null, "C niet geladen met P1 in B")
	if c.inhoud_node == null:
		await t.cleanup()
		return
	var gemaal: Gemaal = c.inhoud_node.get_node("Gemaal")
	var pomprad: CombatTarget = c.inhoud_node.get_node("Pomprad")
	t.check(progress.has_gemaal(id) and gemaal.meter == meter, "gemaal niet gebonden of zonder meter")
	t.check(gemaal.pomprad == pomprad and gemaal.sluice == c.inhoud_node.get_node("Sluis"),
		"paden niet opgelost: %s %s" % [gemaal.pomprad, gemaal.sluice])
	t.check(pomprad.name == &"Pomprad" and pomprad.kind == CombatTarget.Kind.DUMMY
		and (pomprad.shape as RectangleShape2D).size == Pomprad.HURTBOX,
		"pomprad niet opgezet: %s, soort %d" % [pomprad.name, pomprad.kind])
	t.check(gemaal.fill == 30 and sim.objects.has(gemaal) and sim.combat.targets.has(pomprad),
		"stand of aanmelding: G %d" % gemaal.fill)
	t.check(sim.combat.hit.get_connections().size() == hits_before + 1, "gemaal niet met Combat verbonden")
	_strike(sim, "p2", Layers.SHADOW)
	t.check(gemaal.fill == 40 and meter.value == 40, "pompslag: G %d, L %d" % [gemaal.fill, meter.value])
	# Ontladen: P1 terug in A, C is geen buur van A.
	p1.position = IN_A
	await t.run_ticks(sim, 1)
	t.check(c.inhoud_node == null and not progress.has_gemaal(id), "C nog geladen of gemaal nog gebonden")
	t.check(state.gemalen.get(id) == {"vulstand": 40, "vol": false}, "stand niet naar state: %s" % [state.gemalen])
	t.check(sim.combat.hit.get_connections().size() == hits_before, "gemaal niet los van Combat")
	state.set_gemaal(id, 70, false)
	progress.store_world()
	t.check(int(state.gemalen[id]["vulstand"]) == 70, "store_world schreef een ontladen gemaal terug")
	# Opnieuw laden: de stand komt terug.
	p1.position = IN_B
	await t.run_ticks(sim, 1)
	var again: Gemaal = c.inhoud_node.get_node("Gemaal")
	t.check(again != gemaal and again.fill == 70 and again.meter == meter and progress.has_gemaal(id),
		"opnieuw laden: G %d" % again.fill)
	# Vol uit de save: eindstand meteen, zonder signalen.
	p1.position = IN_A
	await t.run_ticks(sim, 1)
	state.set_gemaal(id, 100, true)
	p1.position = IN_B
	await t.run_ticks(sim, 1)
	var full: Gemaal = c.inhoud_node.get_node("Gemaal")
	var sluice: StaticBody2D = c.inhoud_node.get_node("Sluis")
	t.check(full.is_full() and full.sluice_open and sluice.collision_layer == 0 and full.waterline(sim.tick) == full.y_low,
		"vol gemaal laadt niet in zijn eindstand")
	await t.cleanup()


## Pompen zet een checkpoint (deel 3b, punt 2; LM-08 "aanraakte of dat P1
## of P2 pompte"): P1 komt niet in het vlak. Een treffer van de echo zet
## niets; de eerste pompslag van P2 wel (met autosave, G al bijgewerkt);
## volgende slagen (ook van P1) niet opnieuw; vol worden geeft nog één save.
## Na een ander checkpoint zet een slag van P1 het gemaal weer, een slag van
## de echo niet (gdd §4.6, LM-08: het checkpoint blijft het andere).
func test_pump_sets_checkpoint(t) -> void:
	_clear()
	var sim_first = Fx.world(t)
	var progress := Progress.new()
	progress.name = "TestProgress"
	var service := SaveService.new()
	service.name = "TestSaveService"
	service.dir = DIR
	service.use(progress)
	t.world_root().add_child(progress)
	t.world_root().add_child(service)
	service.new_game(2)
	progress.state.lichtmeter = 100
	var w := _world(t, progress.state, progress, sim_first)
	var sim = w["sim"]
	var p1: Node2D = w["p1"]
	var c: Kamer = w["c"]
	var id: StringName = w["id"]
	var reached: Array = []
	progress.checkpoint_reached.connect(func(kamer: StringName, positie: Vector2) -> void:
		reached.append([kamer, positie]))
	var saves: Array = []
	service.saved.connect(func(slot: int, reason: String, error: Error) -> void:
		saves.append([slot, reason, error]))
	p1.position = IN_B
	await t.run_ticks(sim, 1)
	var gemaal: Gemaal = c.inhoud_node.get_node("Gemaal")
	var checkpoint: Checkpoint = c.inhoud_node.get_node("Checkpoint")
	# Eigen Progress, niet de autoload.
	checkpoint.progress = progress
	var cp_ticks: Array = []
	checkpoint.reached.connect(func(tick: int) -> void: cp_ticks.append(tick))
	_strike(sim, "echo", Layers.SHADOW)
	t.check(gemaal.fill == 10 and reached.is_empty(), "echo zette een checkpoint: %s (G %d)" % [reached, gemaal.fill])
	await t.run_ticks(sim, 1)
	await t.run_ticks(sim, 1)
	_strike(sim, "p2", Layers.SHADOW)
	t.check(not checkpoint.overlaps(p1), "P1 staat in het vlak (testopzet)")
	t.check(reached == [[&"C", checkpoint.spawn_point()]] and cp_ticks == [sim.tick],
		"pompslag van P2 zette geen checkpoint: %s" % [reached])
	var stored: GameState = SaveService.read(service.path_of(2))["state"]
	t.check(saves.size() == 1 and saves[0] == [2, "checkpoint", OK] and stored != null
		and stored.checkpoint_kamer == &"C" and stored.gebied == GEBIED
		and stored.gemalen.get(id) == {"vulstand": 20, "vol": false},
		"autosave na de pompslag: %s %s" % [saves, stored.to_dict() if stored else null])
	await t.run_ticks(sim, 1)
	_strike(sim, "p1", Layers.LIGHT)
	t.check(reached.size() == 1 and saves.size() == 1 and gemaal.fill == 30,
		"tweede pompslag schreef opnieuw: %d saves" % saves.size())
	await t.run_ticks(sim, 1)
	_strike(sim, "p1", Layers.LIGHT)
	t.check(reached.size() == 1 and saves.size() == 1 and gemaal.fill == 40,
		"derde pompslag schreef opnieuw: %d saves" % saves.size())
	# Vol: nog één save, met het volle gemaal.
	gemaal.fill = 90
	await t.run_ticks(sim, 1)
	_strike(sim, "p2", Layers.SHADOW)
	stored = SaveService.read(service.path_of(2))["state"]
	t.check(gemaal.is_full() and saves.size() == 2 and stored != null and stored.gemalen.get(id) == {"vulstand": 100, "vol": true},
		"vol worden gaf geen save: %d saves, %s" % [saves.size(), stored.gemalen if stored else null])
	# Een checkpoint elders, dan weer pompen: weer het gemaal (LM-08: het laatste).
	progress.reach_checkpoint(IN_B)
	var before := saves.size()
	await t.run_ticks(sim, 1)
	gemaal.fill = 50
	gemaal.full_tick = -1
	_strike(sim, "echo", Layers.SHADOW)
	t.check(saves.size() == before and progress.state.checkpoint_positie == IN_B,
		"echo zette het gemaal terug als checkpoint: %s" % [progress.state.checkpoint_positie])
	await t.run_ticks(sim, 1)
	_strike(sim, "p1", Layers.LIGHT)
	t.check(saves.size() == before + 1 and progress.state.checkpoint_positie == checkpoint.spawn_point(),
		"pompen na een ander checkpoint: %s" % [progress.state.checkpoint_positie])
	await t.cleanup()
	_clear()


## Hernoemen (§3a): `flag_renames` zet ook de id van een gemaal om, en
## `unknown_flags` vindt een gemaal-id van dit gebied dat bij geen gemaal
## meer hoort.
func test_gemaal_id_renames_and_unknown(t) -> void:
	var state := GameState.new()
	var old := StringName("%s/C/OudGemaal" % GEBIED)
	var stale := StringName("%s/C/Weg" % GEBIED)
	state.set_gemaal(old, 60, false)
	state.set_gemaal(stale, 10, false)
	state.set_gemaal(&"gemaal_k3", 20, false)
	Fx.world(t)
	var progress := Progress.new()
	t.world_root().add_child(progress)
	progress.adopt(state, -1)
	var loader := AreaLoader.new()
	var c: Kamer = Kamer.make(&"C", ROOM_C, [])
	c.inhoud = _gemaal_scene()
	t.world_root().add_child(c)
	loader.add_kamer(c)
	t.world_root().add_child(loader)
	var id := AreaLoader.object_flag(&"C", ^"Gemaal", GEBIED)
	loader.flag_renames = {old: id}
	var unknown := progress.bind_area_loader(loader, GEBIED)
	t.check(state.gemalen.get(id) == {"vulstand": 60, "vol": false} and not state.gemalen.has(old),
		"gemaal-id niet hernoemd: %s" % [state.gemalen])
	t.check(unknown == PackedStringArray([String(stale)]), "onbekende id's: %s" % [unknown])
	await t.cleanup()


## LM-08 en C-08 (gdd §4.6, test LM-08): de respawnplek na pompen.
## Co-op: alleen P2 pompt het gemaal (P1 raakt het vlak niet), P1 sterft
## later in een andere kamer: beiden respawnen bij het gemaal, P2 naast P1.
## Solo: P1 pompt, sterft in een andere kamer (C ontladen): respawn bij het
## gemaal, met C weer geladen.
func test_lm08_respawn_at_pumped_gemaal(t) -> void:
	for coop in [true, false]:
		var state := GameState.new()
		state.lichtmeter = 100
		var w := _world(t, state)
		var sim = w["sim"]
		var p1: PlayerActor = w["p1"]
		var progress: Progress = w["progress"]
		var loader: AreaLoader = w["loader"]
		var c: Kamer = w["c"]
		var p2: PlayerActor = Fx.manual_player(sim, 2, IN_B + Vector2(60, 0)) if coop else null
		var respawn := Respawn.new(p1, func() -> Vector2: return IN_A, progress)
		p1.position = IN_B
		await t.run_ticks(sim, 1)
		var checkpoint: Checkpoint = c.inhoud_node.get_node("Checkpoint")
		checkpoint.progress = progress
		_strike(sim, "p2" if coop else "p1", Layers.SHADOW if coop else Layers.LIGHT)
		t.check(not checkpoint.overlaps(p1) and progress.state.checkpoint_positie == checkpoint.spawn_point()
			and respawn.has_checkpoint(), "co-op %s: pompslag zette geen checkpoint" % coop)
		# Naar A: C ontlaadt.
		p1.position = IN_A
		if coop:
			p2.position = IN_A + Vector2(60, 0)
		await t.run_ticks(sim, 2)
		t.check(c.inhoud_node == null, "co-op %s: C nog geladen" % coop)
		p1.health = 1
		p1.take_hit(sim.tick)
		await t.run_ticks(sim, 1)
		t.check(p1.died and p1.position.distance_to(CHECKPOINT_AT) < 1.0 and loader.huidige == &"C"
			and c.inhoud_node != null, "co-op %s: P1 respawnt op %s (kamer %s)" % [coop, p1.position, loader.huidige])
		if coop:
			t.check(not p2.dissolved and p2.position.distance_to(p1.position) <= 64.0,
				"P2 niet naast P1 bij het gemaal: %s" % p2.position)
		await t.cleanup()
