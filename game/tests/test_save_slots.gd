extends RefCounted
## Tests voor opslaan v1, deel 3a (T5b, #82; ontwerp.md §7 "Slots en
## autosave"): de autoloads `Progress` en `SaveService` met slots, de stand
## van een slot voor het menu (ook als save én back-up kapot zijn), het
## checkpoint met autosave (de objecten vlak vóór de save weggeschreven),
## autosave bij afsluiten, laden van lichtmeter en gemaal, en de controle en
## hernoeming van objectvlaggen.
##
## Elke test maakt een eigen `Progress` en `SaveService` met een eigen map;
## de echte autoloads en `user://saves` blijven onaangeroerd.

const Fx = preload("res://tests/echo_fixture.gd")
const GameState = preload("res://scripts/save/game_state.gd")
const SaveService = preload("res://scripts/save/save_service.gd")
const Progress = preload("res://scripts/save/progress.gd")
const Checkpoint = preload("res://scripts/save/checkpoint.gd")
const Kamer = preload("res://scripts/world/kamer.gd")
const AreaLoader = preload("res://scripts/world/area_loader.gd")
const Lever = preload("res://scripts/objects/lever.gd")
const Layers = preload("res://scripts/world/layers.gd")
const LightMeter = preload("res://scripts/light/light_meter.gd")
const Gemaal = preload("res://scripts/light/gemaal.gd")
const Pomprad = preload("res://scripts/light/pomprad.gd")

const DIR := "user://test_saves_t5b_3a"
const TOP := -400.0
const HEIGHT := 1200.0


func _clear() -> void:
	var dir := DirAccess.open(DIR)
	if dir == null:
		return
	for file in dir.get_files():
		dir.remove(file)
	DirAccess.remove_absolute(DIR)


## Een eigen Progress + SaveService in de boom (zodat `_ready` en signalen
## werken), met de testmap.
func _services(t) -> Array:
	var progress := Progress.new()
	progress.name = "TestProgress"
	var service := SaveService.new()
	service.name = "TestSaveService"
	service.dir = DIR
	service.use(progress)
	t.world_root().add_child(progress)
	t.world_root().add_child(service)
	return [progress, service]


func _write_text(path: String, text: String) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(text)
	file.close()


func _status(service: SaveService, slot: int) -> int:
	return service.slot_info(slot)["status"]


## De stand van een slot voor het menu, en wat er gebeurt als save én .bak
## kapot zijn (§12): het slot is KAPOT, laden verandert niets (geen half
## spel, geen crash), en "nieuw spel" zet beide bestanden opzij (`.kapot`,
## inhoud ongewijzigd) in plaats van ze te wissen. Ook: alleen de save kapot
## = HERSTELD (de back-up laadt), en een save van een nieuwere versie =
## NIEUWER, die ook opzij gaat en nooit overschreven wordt.
func test_slot_status_and_both_files_broken(t) -> void:
	_clear()
	t.make_sim(false)
	var s := _services(t)
	var progress: Progress = s[0]
	var service: SaveService = s[1]
	t.check(_status(service, 1) == SaveService.SlotStatus.LEEG, "leeg slot niet LEEG")
	var start := GameState.new()
	start.lichtmeter = 7
	t.check(service.new_game(1, start) == OK and progress.slot == 1, "nieuw spel in slot 1 mislukt")
	t.check(_status(service, 1) == SaveService.SlotStatus.OK, "slot na nieuw spel niet OK")
	progress.state.lichtmeter = 9
	service.save_now()
	var path := service.path_of(1)
	# Alleen de save kapot: de back-up (lichtmeter 7) laadt.
	_write_text(path, "{\"version\": 1, \"gebied\": ")
	progress.clear()
	var info := service.load_slot(1)
	t.check(info["status"] == SaveService.SlotStatus.HERSTELD and progress.slot == 1
		and progress.state.lichtmeter == 7 and not info["errors"].is_empty(),
		"kapotte save: niet HERSTELD uit de back-up (%s, %s)" % [info["status"], info["errors"]])
	# Save én back-up kapot.
	_write_text(path, "niet eens json")
	_write_text(path + ".bak", "{\"version\": 1}")
	progress.clear()
	info = service.load_slot(1)
	t.check(info["status"] == SaveService.SlotStatus.KAPOT and info["state"] == null,
		"save en back-up kapot: status %s" % info["status"])
	t.check(info["errors"].size() >= 1, "geen fout gemeld bij een kapot slot")
	t.check(progress.slot == -1 and progress.state.equals(GameState.new()),
		"een kapot slot veranderde het lopende spel")
	# Een autosave zonder lopend spel schrijft niets.
	t.check(service.save_now("checkpoint") == ERR_UNCONFIGURED and FileAccess.get_file_as_string(path) == "niet eens json",
		"save zonder slot schreef toch")
	# Nieuw spel in het kapotte slot: bestanden opzij, dan een goede save.
	t.check(service.new_game(1) == OK, "nieuw spel in een kapot slot mislukt")
	t.check(FileAccess.get_file_as_string(path + SaveService.SET_ASIDE) == "niet eens json"
		and FileAccess.get_file_as_string(path + ".bak" + SaveService.SET_ASIDE) == "{\"version\": 1}",
		"kapotte bestanden niet ongewijzigd opzijgezet")
	t.check(_status(service, 1) == SaveService.SlotStatus.OK and not FileAccess.file_exists(path + ".bak"),
		"slot na nieuw spel niet OK, of de kapotte back-up staat er nog")
	# Een save van een nieuwere versie: NIEUWER, niet geladen, nooit overschreven.
	var future := GameState.new().to_dict()
	future["version"] = SaveService.VERSION + 1
	_write_text(service.path_of(2), JSON.stringify(future))
	progress.clear()
	info = service.load_slot(2)
	t.check(info["status"] == SaveService.SlotStatus.NIEUWER and progress.slot == -1,
		"save van een nieuwere versie: status %s, slot %d" % [info["status"], progress.slot])
	service.new_game(2)
	t.check(FileAccess.file_exists(service.path_of(2) + SaveService.SET_ASIDE), "nieuwere save niet opzijgezet")
	# Slots zijn 1..SLOT_COUNT; daarbuiten geweigerd, zonder bestand of wijziging.
	progress.clear()
	for bad in [0, -1, SaveService.SLOT_COUNT + 1]:
		t.check(service.slot_info(bad)["status"] == SaveService.SlotStatus.ONGELDIG
			and service.load_slot(bad)["status"] == SaveService.SlotStatus.ONGELDIG
			and service.new_game(bad) == ERR_PARAMETER_RANGE_ERROR and progress.slot == -1
			and not FileAccess.file_exists(service.path_of(bad)),
			"slot %d buiten het bereik niet geweigerd" % bad)
	await t.cleanup()
	_clear()


## Kamer A met een Eenmalige hendel in zijn gestreamde inhoud en een
## checkpoint, in de wereld van `sim` (`Fx.world`). Geeft [sim, p1, loader,
## checkpoint].
func _world_with_checkpoint(t, sim: Node, progress: Progress) -> Array:
	var p1 := Fx.manual_player(sim, 1, Vector2(200, Fx.STAND_Y))
	var a: Kamer = Kamer.make(&"A", Rect2(-1000, TOP, 1640, HEIGHT), ["B"])
	var b: Kamer = Kamer.make(&"B", Rect2(640, TOP, 2000, HEIGHT), ["A"])
	var root := Node2D.new()
	root.name = "Inhoud"
	var lever := Lever.new()
	lever.name = "Hendel"
	lever.kind = Lever.Kind.EENMALIG
	lever.setup(Layers.LIGHT | Layers.SHADOW, Vector2(40, 40))
	lever.position = Vector2(-300, 0)
	root.add_child(lever)
	lever.owner = root
	var scene := PackedScene.new()
	scene.pack(root)
	root.free()
	a.inhoud = scene
	var loader := AreaLoader.new()
	loader.name = "AreaLoader"
	for room: Kamer in [a, b]:
		t.world_root().add_child(room)
		loader.add_kamer(room)
	t.world_root().add_child(loader)
	sim.set_area_loader(loader)
	var checkpoint := Checkpoint.new()
	checkpoint.name = "Checkpoint"
	checkpoint.setup(Layers.LIGHT, Vector2(40, 40))
	checkpoint.position = Vector2(1000, Fx.STAND_Y)
	checkpoint.progress = progress
	sim.add_object(checkpoint)
	progress.bind_area_loader(loader, &"testgebied")
	progress.bind_sim(sim)
	loader.start(sim.tick, p1.position)
	return [sim, p1, loader, checkpoint]


## Checkpoint en autosave (E-04b, LM-08, LM-12): P1 komt in het vlak → één
## save in zijn slot, met het checkpoint (kamer en positie) en de hendel die
## vlak vóór de save via `store_objects` werd weggeschreven (de kamer is
## nog geladen). Blijft P1 staan, dan geen tweede save (flank); weg en terug
## wel. Bij afsluiten volgt een autosave met de wereld van nu, maar het
## checkpoint blijft het laatste. Laden begint in de kamer van het
## checkpoint, met de hendel om.
func test_checkpoint_autosave_stores_objects_first(t) -> void:
	_clear()
	var sim = Fx.world(t)
	var s := _services(t)
	var progress: Progress = s[0]
	var service: SaveService = s[1]
	service.new_game(3)
	var saves: Array = []
	service.saved.connect(func(slot: int, reason: String, error: Error) -> void:
		saves.append([slot, reason, error]))
	var w := _world_with_checkpoint(t, sim, progress)
	var p1: Node2D = w[1]
	var loader: AreaLoader = w[2]
	var checkpoint: Checkpoint = w[3]
	var a: Kamer = loader.kamers[&"A"]
	var lever: Lever = a.inhoud_node.get_node("Hendel")
	lever.interact(p1, sim.tick)
	var flag := AreaLoader.object_flag(&"A", ^"Hendel", &"testgebied")
	t.check(not progress.state.has_flag(flag), "hendelvlag al vóór de save in de state")
	await t.run_ticks(sim, 1)
	t.check(saves.is_empty(), "save zonder checkpoint: %s" % [saves])
	p1.position = checkpoint.position
	await t.run_ticks(sim, 3)
	t.check(saves.size() == 1 and saves[0] == [3, "checkpoint", OK], "checkpoint gaf geen of meer dan één save: %s" % [saves])
	var on_disk := SaveService.read(service.path_of(3))
	var stored: GameState = on_disk["state"]
	t.check(stored != null and stored.checkpoint_kamer == &"B" and stored.checkpoint_positie == checkpoint.spawn_point(),
		"checkpoint niet in de save: %s" % [stored.to_dict() if stored else on_disk["errors"]])
	t.check(stored != null and stored.has_flag(flag) and stored.gebied == &"testgebied",
		"hendel niet vlak vóór de save weggeschreven: %s" % [stored.vlaggen if stored else null])
	t.check(stored != null and stored.speeltijd_ticks > 0, "speeltijd niet geteld")
	p1.position = Vector2(200, Fx.STAND_Y)
	await t.run_ticks(sim, 1)
	p1.position = checkpoint.position
	await t.run_ticks(sim, 1)
	t.check(saves.size() == 2, "weg en terug op het checkpoint: %d saves" % saves.size())
	# Afsluiten: autosave, het checkpoint blijft.
	p1.position = Vector2(200, Fx.STAND_Y)
	await t.run_ticks(sim, 1)
	service._notification(Node.NOTIFICATION_WM_CLOSE_REQUEST)
	stored = SaveService.read(service.path_of(3))["state"]
	t.check(saves.size() == 3 and saves[2][1] == "afsluiten", "geen autosave bij afsluiten: %s" % [saves])
	t.check(stored != null and stored.checkpoint_positie == checkpoint.spawn_point(),
		"afsluiten verplaatste het checkpoint")
	# Door een deur naar een tweede gebied, afsluiten vóór zijn eerste
	# checkpoint: de save houdt het oude gebied en checkpoint (EP-review #128).
	var other := AreaLoader.new()
	var c: Kamer = Kamer.make(&"Z", Rect2(5000, TOP, 1000, HEIGHT), [])
	t.world_root().add_child(c)
	other.add_kamer(c)
	t.world_root().add_child(other)
	progress.bind_area_loader(other, &"tweede_gebied")
	service._notification(Node.NOTIFICATION_WM_CLOSE_REQUEST)
	stored = SaveService.read(service.path_of(3))["state"]
	t.check(stored != null and stored.gebied == &"testgebied" and stored.checkpoint_kamer == &"B"
		and stored.checkpoint_positie == checkpoint.spawn_point(),
		"afsluiten in een nieuw gebied vóór zijn checkpoint: %s" % [stored.to_dict() if stored else null])
	progress.bind_area_loader(loader, &"testgebied")
	var inhoud: PackedScene = a.inhoud
	await t.cleanup()
	# Laden: een nieuwe wereld begint in de kamer van het checkpoint, de hendel om.
	var sim2 = Fx.world(t)
	s = _services(t)
	progress = s[0]
	service = s[1]
	var info := service.load_slot(3)
	t.check(info["status"] == SaveService.SlotStatus.OK and progress.slot == 3, "laden van slot 3: %s" % info["status"])
	var p1b := Fx.manual_player(sim2, 1, progress.state.checkpoint_positie)
	var loader2 := AreaLoader.new()
	var a2: Kamer = Kamer.make(&"A", Rect2(-1000, TOP, 1640, HEIGHT), ["B"])
	var b2: Kamer = Kamer.make(&"B", Rect2(640, TOP, 2000, HEIGHT), ["A"])
	a2.inhoud = inhoud
	for room: Kamer in [a2, b2]:
		t.world_root().add_child(room)
		loader2.add_kamer(room)
	t.world_root().add_child(loader2)
	sim2.set_area_loader(loader2)
	var unknown := progress.bind_area_loader(loader2, &"testgebied")
	var errors := loader2.start(sim2.tick, p1b.position, progress.state.checkpoint_kamer)
	t.check(unknown.is_empty() and errors.is_empty() and loader2.huidige == &"B", "laden: %s %s in %s" % [unknown, errors, loader2.huidige])
	t.check((a2.inhoud_node.get_node("Hendel") as Lever).on, "hendel na laden niet om")
	await t.cleanup()
	_clear()


## Alleen P1 zet een checkpoint (C-08): P2 op het vlak doet niets.
func test_checkpoint_only_p1(t) -> void:
	_clear()
	var sim = Fx.world(t)
	var s := _services(t)
	var progress: Progress = s[0]
	var service: SaveService = s[1]
	service.new_game(1)
	var w := _world_with_checkpoint(t, sim, progress)
	var checkpoint: Checkpoint = w[3]
	var reached: Array = []
	checkpoint.reached.connect(func(tick: int) -> void: reached.append(tick))
	var p2 := Fx.manual_player(sim, 2, checkpoint.position)
	await t.run_ticks(sim, 3)
	t.check(p2.collision_layer & Layers.LIGHT == 0, "P2 staat op laag 2 (testopzet)")
	t.check(reached.is_empty() and progress.state.checkpoint_positie == Vector2.ZERO,
		"P2 zette een checkpoint: %s" % [reached])
	await t.cleanup()
	_clear()


## Lichtmeter en gemaal (LM-03, LM-06, LM-12) via de autoload: `store_world`
## schrijft L en G weg; na laden krijgt een nieuw gemaal zijn stand terug.
## Een vol gemaal staat meteen in zijn eindstand (water laag, sluis open,
## `full_tick >= 0`) zonder `sluice_opened` of `full` opnieuw te melden.
func test_meter_and_gemaal_restore(t) -> void:
	var sim = Fx.world(t)
	var p1 := Fx.manual_player(sim, 1, Vector2(200, Fx.STAND_Y))
	var progress := Progress.new()
	t.world_root().add_child(progress)
	var build := func() -> Array:
		var meter := LightMeter.new(sim, p1)
		var pomprad := Pomprad.new()
		pomprad.setup_pomprad()
		sim.add_object(pomprad)
		var sluice: StaticBody2D = Fx.block(t, "Sluis", Rect2(900, 300, 20, 100), Layers.WORLD)
		var gemaal := Gemaal.new()
		gemaal.setup_gemaal(meter, pomprad, sluice, Rect2(600, 300, 400, 100), 320.0, 390.0)
		sim.add_object(gemaal)
		return [meter, gemaal, sluice]
	var first: Array = build.call()
	progress.bind_meter(first[0])
	progress.bind_gemaal(first[1], &"gemaal_k3")
	first[0].value = 55
	first[1].fill = 40
	progress.store_world()
	t.check(progress.state.lichtmeter == 55 and progress.state.gemalen[&"gemaal_k3"] == {"vulstand": 40, "vol": false},
		"store_world: %s" % [progress.state.to_dict()])
	progress.state.set_gemaal(&"gemaal_k3", 100, true)
	progress.state.lichtmeter = 12
	var second: Array = build.call()
	var signals: Array = []
	second[1].sluice_opened.connect(func(tick: int) -> void: signals.append(["sluis", tick]))
	second[1].full.connect(func(tick: int) -> void: signals.append(["vol", tick]))
	progress.bind_meter(second[0])
	progress.bind_gemaal(second[1], &"gemaal_k3")
	await t.run_ticks(sim, 2)
	var gemaal: Gemaal = second[1]
	var sluice: StaticBody2D = second[2]
	t.check(second[0].value == 12, "lichtmeter niet terug: %d" % second[0].value)
	t.check(gemaal.fill == 100 and gemaal.is_full() and gemaal.full_tick >= 0 and gemaal.sluice_open,
		"vol gemaal niet terug: G %d, t_v %d, sluis %s" % [gemaal.fill, gemaal.full_tick, gemaal.sluice_open])
	t.check(gemaal.waterline(sim.tick) == gemaal.y_low and sluice.collision_layer == 0,
		"water niet laag of sluis niet open na laden")
	t.check(signals.is_empty(), "laden meldde opnieuw: %s" % [signals])
	await t.cleanup()


## Vlag van een object (§12): `unknown_flags` vindt een vlag van dit gebied
## die bij geen object meer hoort (kamer of object hernoemd); vlaggen van
## een ander gebied of zonder kamer (een sluis) tellen niet. Met
## `flag_renames` houdt een bestaande save zijn stand.
func test_object_flags_check_and_renames(t) -> void:
	var sim = Fx.world(t)
	var progress := Progress.new()
	t.world_root().add_child(progress)
	var w := _world_with_checkpoint(t, sim, progress)
	var loader: AreaLoader = w[2]
	var known := AreaLoader.object_flag(&"A", ^"Hendel", &"testgebied")
	t.check(loader.known_object_flags() == {known: true}, "bekende vlaggen: %s" % [loader.known_object_flags()])
	var state := GameState.new()
	state.set_flag(known)
	state.set_flag(&"testgebied/A/OudeHendel")
	state.set_flag(&"testgebied/K9/Hendel")
	state.set_flag(&"anders/A/Hendel")
	state.set_flag(&"sluis_k3_open")
	t.check(loader.unknown_flags(state) == PackedStringArray(["testgebied/A/OudeHendel", "testgebied/K9/Hendel"]),
		"onbekende vlaggen: %s" % [loader.unknown_flags(state)])
	state.set_flag(known, false)
	loader.flag_renames = {"testgebied/A/OudeHendel": known}
	progress.adopt(state, -1)
	var unknown := progress.bind_area_loader(loader, &"testgebied")
	t.check(state.has_flag(known) and not state.has_flag(&"testgebied/A/OudeHendel"),
		"hernoeming niet toegepast: %s" % [state.vlaggen])
	t.check(unknown == PackedStringArray(["testgebied/K9/Hendel"]), "na hernoemen nog onbekend: %s" % [unknown])
	# Zonder gebied: een vlag hoort bij dit gebied als hij met een kamer-id begint.
	loader.gebied = &""
	var bare := GameState.new()
	bare.set_flag(&"A/Weg")
	bare.set_flag(&"sluis_k3_open")
	t.check(loader.unknown_flags(bare) == PackedStringArray(["A/Weg"]), "zonder gebied: %s" % [loader.unknown_flags(bare)])
	await t.cleanup()
