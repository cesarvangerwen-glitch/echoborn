extends RefCounted
## Tests voor de respawn bij 0 levenspunten (T5b deel 3b, punt 1, #82;
## gdd E-04b, C-08, LM-05, LM-08, L-10; ontwerp.md §7).
##
## - Met een checkpoint in het gebied respawnt P1 daar, ook in een kamer die
##   niet geladen was (kamerwissel met reset, E-04a), met levenspunten vol,
##   `geldig_vanaf` op de respawntick, L gelijk, en een extra autosave op
##   dezelfde plek (binnenkomen in het vlak, §7).
## - Zonder checkpoint (nieuw spel, ander gebied, zonder Progress): het begin
##   van de kamer, zoals in de flow-kamer (LM-05).
## - Co-op: P2 verschijnt naast P1 op het checkpoint (C-08, C-03), ook als hij
##   opgelost was. Solo: de echo is D ticks Leeg (E-04b).
## - Een treffer die niet de laatste is en terugzetten zonder dood (L-10)
##   gaan nooit naar het checkpoint.
## - Meetlog (gdd §4.5): één `RESPAWN` per respawn, ook als `requested` twee
##   keer met dezelfde tick komt (nieuw checkpoint na de laatste treffer).
##
## Elke test maakt een eigen `Progress` (en zo nodig `SaveService`) met een
## eigen map; de echte autoloads en `user://saves` blijven onaangeroerd.

const Fx = preload("res://tests/echo_fixture.gd")
const GameState = preload("res://scripts/save/game_state.gd")
const SaveService = preload("res://scripts/save/save_service.gd")
const Progress = preload("res://scripts/save/progress.gd")
const Checkpoint = preload("res://scripts/save/checkpoint.gd")
const Respawn = preload("res://scripts/save/respawn.gd")
const Kamer = preload("res://scripts/world/kamer.gd")
const AreaLoader = preload("res://scripts/world/area_loader.gd")
const Layers = preload("res://scripts/world/layers.gd")
const LightMeter = preload("res://scripts/light/light_meter.gd")
const PlayerActor = preload("res://scripts/echo/player_actor.gd")
const Tuning = preload("res://scripts/echo/tuning.gd")
const Meetlog = preload("res://scripts/events/meetlog.gd")
const EnemyData = preload("res://scripts/combat/enemy_data.gd")

const DIR := "user://test_saves_t5b_respawn"
const TOP := -400.0
const HEIGHT := 1200.0
const GEBIED := &"testgebied"
## Kamers A – B – C; C is alleen buur van B. Met P1 in A is C niet geladen.
const IN_A := Vector2(200, Fx.STAND_Y)
const IN_B := Vector2(1000, Fx.STAND_Y)
const ROOM_C := Rect2(1640, TOP, 1360, HEIGHT)
## Het checkpoint in de inhoud van C (vlak 40 × 40 op de vloer).
const CHECKPOINT_AT := Vector2(2200, Fx.STAND_Y)
## VJ-02 (B-12): zo lang is P1 na een respawn onkwetsbaar (`slice.csv`).
var _respawn_safe := EnemyData.ticks("gedeeld", "onkwetsbaar_respawn")
## Begin van elke kamer (de terugval, LM-05).
const STARTS := {
	&"A": Vector2(100, Fx.STAND_Y),
	&"B": Vector2(700, Fx.STAND_Y),
	&"C": Vector2(1700, Fx.STAND_Y),
}


func _clear() -> void:
	var dir := DirAccess.open(DIR)
	if dir == null:
		return
	for file in dir.get_files():
		dir.remove(file)
	DirAccess.remove_absolute(DIR)


## De inhoud van kamer C: alleen een checkpoint.
func _checkpoint_scene() -> PackedScene:
	var root := Node2D.new()
	root.name = "Inhoud"
	var checkpoint := Checkpoint.new()
	checkpoint.name = "Checkpoint"
	checkpoint.setup(Layers.LIGHT, Vector2(40, 40))
	checkpoint.position = CHECKPOINT_AT - ROOM_C.get_center()
	root.add_child(checkpoint)
	checkpoint.owner = root
	var scene := PackedScene.new()
	scene.pack(root)
	root.free()
	return scene


## Een lege wereld (de Sim) met een eigen Progress (en een SaveService in
## DIR als `with_service`, slot 1).
func _progress(t, with_service: bool) -> Dictionary:
	var sim = Fx.world(t)
	var progress := Progress.new()
	progress.name = "TestProgress"
	t.world_root().add_child(progress)
	var service: SaveService = null
	var saves: Array = []
	if with_service:
		_clear()
		service = SaveService.new()
		service.name = "TestSaveService"
		service.dir = DIR
		service.use(progress)
		t.world_root().add_child(service)
		service.new_game(1)
		service.saved.connect(func(slot: int, reason: String, error: Error) -> void:
			saves.append([slot, reason, error]))
	else:
		progress.adopt(GameState.new(), -1)
	return {"sim": sim, "progress": progress, "service": service, "saves": saves}


## Bouwt in de wereld van `sim` een gebied met de kamers A – B – C, met P1 in
## A (en P2 als `coop`), een lichtmeter en een Respawn met `progress` (of
## zonder). Het checkpoint in C krijgt bij elk laden de eigen Progress, nooit
## de autoload.
func _world(t, sim: Node, progress: Progress, coop := false, gebied := GEBIED) -> Dictionary:
	var p1 := Fx.manual_player(sim, 1, IN_A)
	var p2: PlayerActor = Fx.manual_player(sim, 2, IN_A + Vector2(60, 0)) if coop else null
	var a: Kamer = Kamer.make(&"A", Rect2(-1000, TOP, 1640, HEIGHT), ["B"])
	var b: Kamer = Kamer.make(&"B", Rect2(640, TOP, 1000, HEIGHT), ["A", "C"])
	var c: Kamer = Kamer.make(&"C", ROOM_C, ["B"])
	c.inhoud = _checkpoint_scene()
	var loader := AreaLoader.new()
	loader.name = "AreaLoader"
	for room: Kamer in [a, b, c]:
		t.world_root().add_child(room)
		loader.add_kamer(room)
	t.world_root().add_child(loader)
	sim.set_area_loader(loader)
	loader.geladen_gewijzigd.connect(func(_tick: int, kamer: StringName, geladen: bool) -> void:
		if kamer == &"C" and geladen:
			(c.inhoud_node.get_node("Checkpoint") as Checkpoint).progress = progress)
	var meter := LightMeter.new(sim, p1)
	if progress != null:
		progress.bind_area_loader(loader, gebied)
		progress.bind_meter(meter)
	var errors := loader.start(sim.tick, p1.position)
	t.check(errors.is_empty(), "start: %s" % [errors])
	var respawn := Respawn.new(p1, func() -> Vector2: return STARTS[loader.huidige], progress)
	var requests: Array = []
	respawn.requested.connect(func(tick: int, at: Vector2, on_checkpoint: bool) -> void:
		requests.append([tick, at, on_checkpoint]))
	return {"sim": sim, "p1": p1, "p2": p2, "loader": loader, "meter": meter, "c": c,
		"respawn": respawn, "requests": requests}


## P1 loopt via B het vlak van het checkpoint in C in (autosave) en gaat
## daarna terug naar A: C is dan niet meer geladen.
## In co-op gaat P2 mee (60 px rechts van P1): anders staat hij na de sprong
## van P1 in een kamer die niet geladen is en lost hij op (C-06, `ontladen`).
func _reach_checkpoint_then_leave(w: Dictionary, t) -> void:
	var sim = w["sim"]
	var p1: PlayerActor = w["p1"]
	var p2: PlayerActor = w.get("p2")
	for at: Vector2 in [IN_B, CHECKPOINT_AT, IN_A]:
		p1.position = at
		if p2 != null:
			p2.position = at + Vector2(60, 0)
		await t.run_ticks(sim, 1)


## De laatste treffer: P1 op 1 levenspunt, één vijandelijke treffer. Geeft de
## tick waarop P1 respawnt (de volgende stap van P1).
func _kill(p1: PlayerActor, sim: Node) -> int:
	p1.health = 1
	p1.take_hit(sim.tick)
	return sim.tick


## Respawn op het checkpoint in een kamer die niet geladen is (E-04b, LM-08):
## P1 staat op de respawntick op het checkpoint, C is geladen en de kamer
## van P1, levenspunten vol, `geldig_vanaf` = respawntick, L gelijk, en het
## binnenkomen geeft één extra autosave op dezelfde plek (§7).
func test_respawn_on_checkpoint_in_unloaded_room(t) -> void:
	var p := _progress(t, true)
	var progress: Progress = p["progress"]
	var service: SaveService = p["service"]
	var saves: Array = p["saves"]
	var w := _world(t, p["sim"], progress)
	var sim = w["sim"]
	var p1: PlayerActor = w["p1"]
	var loader: AreaLoader = w["loader"]
	var meter: LightMeter = w["meter"]
	var c: Kamer = w["c"]
	var respawn: Respawn = w["respawn"]
	t.check(not respawn.has_checkpoint(), "nieuw spel heeft al een checkpoint")
	await _reach_checkpoint_then_leave(w, t)
	t.check(saves.size() == 1 and progress.state.checkpoint_kamer == &"C"
		and progress.state.checkpoint_positie == CHECKPOINT_AT and respawn.has_checkpoint(),
		"checkpoint niet gezet: %s, %s" % [saves, progress.state.to_dict()])
	t.check(loader.huidige == &"A" and c.inhoud_node == null, "C nog geladen met P1 in A")
	meter.value = 37
	var t0 := _kill(p1, sim)
	t.check(p1.health == 0 and p1.position.distance_to(IN_A) < 1.0,
		"vóór de respawntick: %d levenspunten, P1 op %s" % [p1.health, p1.position])
	t.check(w["requests"] == [[t0, CHECKPOINT_AT, true]], "verzoek: %s" % [w["requests"]])
	# Tot de respawntick kost een treffer niets meer.
	p1.take_hit(sim.tick)
	t.check(p1.health == 0 and w["requests"].size() == 1, "tweede treffer op 0 levenspunten telde")
	await t.run_ticks(sim, 1)
	t.check(p1.position.distance_to(CHECKPOINT_AT) < 1.0 and p1.died and p1.echo_valid_from == t0,
		"respawntick: P1 op %s, died %s, geldig_vanaf %d (t0 = %d)" % [p1.position, p1.died, p1.echo_valid_from, t0])
	t.check(p1.health == int(Tuning.combat()["p1_health"]), "levenspunten niet vol: %d" % p1.health)
	t.check(loader.huidige == &"C" and c.inhoud_node != null, "C niet geladen na de respawn (kamer %s)" % loader.huidige)
	t.check(meter.value == 37, "L veranderde bij de respawn: %d" % meter.value)
	var stored: GameState = SaveService.read(service.path_of(1))["state"]
	t.check(saves.size() == 2 and saves[1] == [1, "checkpoint", OK] and stored != null
		and stored.checkpoint_positie == CHECKPOINT_AT and stored.lichtmeter == 37,
		"extra autosave op de respawntick: %s %s" % [saves, stored.to_dict() if stored else null])
	# Dood in de kamer van het checkpoint zelf: weer daar, nog een autosave.
	p1.position = CHECKPOINT_AT + Vector2(300, 0)
	# VJ-02 (B-12): na de respawn is P1 eerst `onkwetsbaar_respawn` ticks onkwetsbaar.
	await t.run_ticks(sim, 2 + _respawn_safe)
	_kill(p1, sim)
	await t.run_ticks(sim, 1)
	t.check(p1.position.distance_to(CHECKPOINT_AT) < 1.0 and saves.size() == 3,
		"tweede dood: P1 op %s, %d saves" % [p1.position, saves.size()])
	await t.cleanup()
	_clear()


## Geen checkpoint: het begin van de kamer van P1 (LM-05), zonder save. Zo
## bij een nieuw spel, zonder Progress, en in een nieuw gebied vóór zijn
## eerste checkpoint (het checkpoint van het vorige gebied telt dan niet).
func test_respawn_without_checkpoint_room_start(t) -> void:
	# Nieuw spel.
	var p := _progress(t, false)
	var w := _world(t, p["sim"], p["progress"])
	var sim = w["sim"]
	var p1: PlayerActor = w["p1"]
	p1.position = IN_B
	await t.run_ticks(sim, 1)
	var t0 := _kill(p1, sim)
	await t.run_ticks(sim, 1)
	t.check(w["requests"] == [[t0, STARTS[&"B"], false]] and p1.position.distance_to(STARTS[&"B"]) < 1.0
		and p1.health == int(Tuning.combat()["p1_health"]) and p1.echo_valid_from == t0,
		"nieuw spel: %s, P1 op %s" % [w["requests"], p1.position])
	await t.cleanup()
	# Zonder Progress (de flow-kamer).
	w = _world(t, Fx.world(t), null)
	sim = w["sim"]
	p1 = w["p1"]
	_kill(p1, sim)
	await t.run_ticks(sim, 1)
	t.check(p1.position.distance_to(STARTS[&"A"]) < 1.0 and not w["respawn"].has_checkpoint(),
		"zonder Progress: P1 op %s" % p1.position)
	await t.cleanup()
	# Een checkpoint in een ander gebied.
	p = _progress(t, false)
	var progress: Progress = p["progress"]
	progress.state.gebied = &"vorig_gebied"
	progress.state.checkpoint_kamer = &"C"
	progress.state.checkpoint_positie = CHECKPOINT_AT
	w = _world(t, p["sim"], progress)
	sim = w["sim"]
	p1 = w["p1"]
	_kill(p1, sim)
	await t.run_ticks(sim, 1)
	t.check(p1.position.distance_to(STARTS[&"A"]) < 1.0 and w["requests"][0][2] == false,
		"checkpoint uit een ander gebied gebruikt: P1 op %s" % p1.position)
	await t.cleanup()
	# Een checkpoint dat in geen kamer van het gebied ligt (oude save).
	p = _progress(t, false)
	progress = p["progress"]
	progress.state.gebied = GEBIED
	progress.state.checkpoint_positie = Vector2(5000, Fx.STAND_Y)
	w = _world(t, p["sim"], progress)
	t.check(not w["respawn"].has_checkpoint() and w["respawn"].target() == STARTS[&"A"],
		"checkpoint buiten alle kamers gebruikt: %s" % w["respawn"].target())
	await t.cleanup()


## C-08: P1 sterft in co-op; beiden respawnen op het checkpoint, P2 naast P1
## volgens de plaatsingsregel (C-03, binnen 64 px), `geldig_vanaf = t0`. Ook
## een opgeloste P2 (C-06) komt mee. De plek van P2 vóór de respawn (in A,
## dat dan ontlaadt) telt niet als "P2 in een ontladen kamer" (§3a, keuze (c)).
func test_c08_coop_both_on_checkpoint(t) -> void:
	var p := _progress(t, true)
	var progress: Progress = p["progress"]
	var w := _world(t, p["sim"], progress, true)
	var sim = w["sim"]
	var p1: PlayerActor = w["p1"]
	var p2: PlayerActor = w["p2"]
	var back: Array = []
	sim.partner_returned.connect(func(tick: int, _at: Vector2) -> void: back.append(tick))
	await _reach_checkpoint_then_leave(w, t)
	p2.position = IN_A + Vector2(-80, 0)
	await t.run_ticks(sim, 5)
	t.check(not p2.dissolved, "P2 opgelost vóór de test (opzet)")
	var outside: Array = []
	w["loader"].partner_in_ontladen_kamer.connect(func(tick: int, _p2: PlayerActor, kamer: StringName) -> void:
		outside.append([tick, kamer]))
	var t0 := _kill(p1, sim)
	await t.run_ticks(sim, 1)
	t.check(p1.position.distance_to(CHECKPOINT_AT) < 1.0 and p1.echo_valid_from == t0,
		"P1 op %s, geldig_vanaf %d (t0 = %d)" % [p1.position, p1.echo_valid_from, t0])
	t.check(not p2.dissolved and p2.position.distance_to(p1.position) <= 64.0 and back == [t0],
		"P2 op %s (P1 %s), terug %s" % [p2.position, p1.position, back])
	t.check(w["loader"].room_at(p2.global_position) == &"C" and not w["loader"].is_partner_outside()
		and outside.is_empty(), "P2 niet in de geladen kamer van het checkpoint, of gemeld als buiten: %s" % [outside])
	# Een opgeloste P2 komt ook mee.
	p1.position = IN_A
	await t.run_ticks(sim, 1)
	sim.dissolve_partner("val")
	# VJ-02 (B-12): eerst voorbij de onkwetsbaarheid na de respawn (P2 komt pas na 120 ticks terug).
	await t.run_ticks(sim, 3 + _respawn_safe)
	t0 = _kill(p1, sim)
	await t.run_ticks(sim, 1)
	t.check(not p2.dissolved and p1.position.distance_to(CHECKPOINT_AT) < 1.0
		and p2.position.distance_to(p1.position) <= 64.0 and back.size() == 2 and back[1] == t0,
		"opgeloste P2: op %s, opgelost %s, terug %s" % [p2.position, p2.dissolved, back])
	await t.cleanup()
	_clear()


## Solo (E-04b, C-08): na de respawn op het checkpoint is de echo Leeg van
## de respawntick t0 tot t0 + D − 1 en speelt hij op t0 + D weer af, vanaf
## het checkpoint (niet vanaf de plek van de dood).
func test_solo_echo_empty_after_checkpoint_respawn(t) -> void:
	var p := _progress(t, false)
	var progress: Progress = p["progress"]
	var w := _world(t, p["sim"], progress)
	var sim = w["sim"]
	var p1: PlayerActor = w["p1"]
	var d := 120
	var echo := Fx.tail_echo(sim, p1, d)
	progress.state.gebied = GEBIED
	progress.state.checkpoint_kamer = &"C"
	progress.state.checkpoint_positie = CHECKPOINT_AT
	await t.run_ticks(sim, d + 20)
	t.check(echo.is_present(), "echo speelt niet af vóór de dood (opzet)")
	var t0 := _kill(p1, sim)
	var seen := {}
	sim.tick_finished.connect(func(tick: int) -> void: seen[tick] = [echo.is_present(), echo.position])
	await t.run_ticks(sim, d + 2)
	t.check(not seen[t0][0] and not seen[t0 + d - 1][0] and seen[t0 + d][0],
		"echo Leeg tot t0 + D: %s, %s, %s" % [seen[t0][0], seen[t0 + d - 1][0], seen[t0 + d][0]])
	t.check((seen[t0 + d][1] as Vector2).distance_to(CHECKPOINT_AT) < 1.0,
		"echo begint op %s, niet op het checkpoint" % seen[t0 + d][1])
	await t.cleanup()


## L-10, LM-05: een treffer die P1 niet op 0 brengt en terugzetten zonder
## dood (gemiste sprong, diep water) gaan nooit naar het checkpoint.
func test_no_checkpoint_respawn_without_death(t) -> void:
	var p := _progress(t, false)
	var progress: Progress = p["progress"]
	var w := _world(t, p["sim"], progress)
	var sim = w["sim"]
	var p1: PlayerActor = w["p1"]
	progress.state.gebied = GEBIED
	progress.state.checkpoint_positie = CHECKPOINT_AT
	p1.take_hit(sim.tick)
	await t.run_ticks(sim, 1)
	t.check(p1.health == int(Tuning.combat()["p1_health"]) - 1 and p1.position.distance_to(IN_A) < 3.0
		and w["requests"].is_empty(), "treffer: %d levenspunten, P1 op %s" % [p1.health, p1.position])
	var back_to := IN_A + Vector2(40, 0)
	p1.respawn_at(back_to)
	await t.run_ticks(sim, 1)
	t.check(p1.position.distance_to(back_to) < 1.0 and not p1.died and w["requests"].is_empty()
		and p1.health == int(Tuning.combat()["p1_health"]) - 1,
		"terugzetten: P1 op %s, died %s, %d levenspunten" % [p1.position, p1.died, p1.health])
	await t.cleanup()


## Randgeval (§7): P1 valt op 0 en bereikt daarna, nog vóór de respawntick,
## een nieuw checkpoint (stap 5 van `t0 − 1`, hier `reach_checkpoint` tussen
## de ticks). Dan respawnt P1 op het nieuwe checkpoint, dat ook in de save
## staat, en `requested` meldt de nieuwe plek. Hetzelfde checkpoint nog eens
## (dezelfde plek) meldt niets. Na de respawn verplaatst een nieuw checkpoint
## de respawn niet meer.
func test_checkpoint_after_last_hit_is_respawn_point(t) -> void:
	var p := _progress(t, false)
	var progress: Progress = p["progress"]
	var w := _world(t, p["sim"], progress)
	var sim = w["sim"]
	var p1: PlayerActor = w["p1"]
	await _reach_checkpoint_then_leave(w, t)
	t.check(progress.state.checkpoint_positie == CHECKPOINT_AT, "eerste checkpoint niet gezet")
	var t0 := _kill(p1, sim)
	progress.reach_checkpoint(CHECKPOINT_AT)
	t.check(w["requests"] == [[t0, CHECKPOINT_AT, true]], "zelfde plek meldde opnieuw: %s" % [w["requests"]])
	var nieuw := IN_A + Vector2(80, 0)
	progress.reach_checkpoint(nieuw)
	progress.reach_checkpoint(nieuw)
	t.check(w["requests"] == [[t0, CHECKPOINT_AT, true], [t0, nieuw, true]], "verzoeken: %s" % [w["requests"]])
	await t.run_ticks(sim, 1)
	t.check(p1.died and p1.position.distance_to(nieuw) < 1.0 and progress.state.checkpoint_positie == nieuw,
		"respawn op %s, save heeft %s (verwacht %s)" % [p1.position, progress.state.checkpoint_positie, nieuw])
	progress.reach_checkpoint(IN_A)
	await t.run_ticks(sim, 1)
	t.check(not p1.died and p1.position.distance_to(nieuw) < 3.0 and w["requests"].size() == 2,
		"checkpoint na de respawn verplaatste P1: %s, %s" % [p1.position, w["requests"]])
	await t.cleanup()


## gdd §4.5 (meetlog, randgeval van §7): P1 krijgt de laatste treffer en
## bereikt vóór de respawntick een nieuw checkpoint, dus `requested` komt twee
## keer met dezelfde tick. Het meetlog heeft precies één `RESPAWN`, op de
## respawntick, met x, y = de plek waar P1 werkelijk verschijnt (het nieuwe
## checkpoint), en telt één respawn. Het log leest `echo_reset` van P1 na de
## tick, niet `requested`: twee meldingen geven zo nooit twee regels.
## Twee `RESPAWN`-regels op één tick zijn volgens gdd §4.5 een fout in het
## log: een tweede regel laat deze test falen (`rows.size() == 1`).
func test_meetlog_one_respawn_row_when_requested_twice(t) -> void:
	var p := _progress(t, false)
	var progress: Progress = p["progress"]
	var w := _world(t, p["sim"], progress)
	var sim = w["sim"]
	var p1: PlayerActor = w["p1"]
	await _reach_checkpoint_then_leave(w, t)
	var log := Meetlog.new(sim, p1, null)
	await t.run_ticks(sim, 5)
	var t0 := _kill(p1, sim)
	var nieuw := IN_A + Vector2(80, 0)
	progress.reach_checkpoint(nieuw)
	t.check(w["requests"].size() == 2 and w["requests"][0][0] == t0 and w["requests"][1][0] == t0,
		"opzet: twee meldingen met dezelfde tick verwacht: %s" % [w["requests"]])
	await t.run_ticks(sim, 10)
	log.finish()
	var rows: Array = []
	for row in log.rows:
		if row[2] == "RESPAWN":
			rows.append(row)
	t.check(log.count("RESPAWN") == 1 and rows.size() == 1, "RESPAWN-regels: %s" % [rows])
	if rows.size() == 1:
		var at := Vector2(float(rows[0][5]), float(rows[0][6]))
		t.check(int(rows[0][0]) == t0, "RESPAWN op tick %s, respawntick %d" % [rows[0][0], t0])
		t.check(at.distance_to(nieuw) < 1.0 and at.distance_to(CHECKPOINT_AT) > 100.0,
			"RESPAWN op %s, P1 verschijnt op %s" % [at, nieuw])
	await t.cleanup()
