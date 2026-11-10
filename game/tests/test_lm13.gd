extends RefCounted
## Tests voor LM-13 (vijanden bij laden en binnenkomen) en de respawn die
## daarbij hoort (T5b, #82; gdd §2.12 en §4.6; ontwerp.md §3a en §7).
##
## Kamers A – B – C – D op een rij; elk alleen buur van de volgende. De
## vijanden staan in de inhoud van B. P1 in A of C: B geladen. P1 in D: B
## ontladen. Het gemaal van de wijk is `C/Gemaal`; zijn stand staat alleen in
## `state.gemalen` (een gemaal dat niet geladen is), dus `Progress` leest hem
## daar (`is_gemaal_full`).
##
## De Kadeloper is een basisvijand (terugkerend), de Schotdrager een
## pantserdoel (niet terugkerend, LM-13a). Het Dwaallicht bestaat nog niet
## als soort; `Terugkeer.JA` op een stilstaand doel staat ervoor.
##
## Elke test maakt een eigen `Progress`; de echte autoloads en `user://saves`
## blijven onaangeroerd.

const Fx = preload("res://tests/echo_fixture.gd")
const GameState = preload("res://scripts/save/game_state.gd")
const Progress = preload("res://scripts/save/progress.gd")
const Respawn = preload("res://scripts/save/respawn.gd")
const Kamer = preload("res://scripts/world/kamer.gd")
const AreaLoader = preload("res://scripts/world/area_loader.gd")
const CombatTarget = preload("res://scripts/combat/combat_target.gd")
const PlayerActor = preload("res://scripts/echo/player_actor.gd")
const Layers = preload("res://scripts/world/layers.gd")

const TOP := -400.0
const HEIGHT := 1200.0
const GEBIED := &"testgebied"
const IN_A := Vector2(200, Fx.STAND_Y)
const IN_B := Vector2(1000, Fx.STAND_Y)
const IN_C := Vector2(2000, Fx.STAND_Y)
const IN_D := Vector2(3500, Fx.STAND_Y)
const ROOM_B := Rect2(640, TOP, 1000, HEIGHT)
const KADELOPER_X := 1200.0
const SCHOTDRAGER_X := 1300.0
const DWAALLICHT_X := 1400.0
const WIJK := &"C/Gemaal"


## De inhoud van B: Kadeloper, Schotdrager en Dwaallicht (stil, terugkerend).
func _enemy_scene() -> PackedScene:
	var origin := ROOM_B.get_center()
	var root := Node2D.new()
	root.name = "Inhoud"
	var specs := [
		["Kadeloper", CombatTarget.Kind.ENEMY, KADELOPER_X, CombatTarget.Terugkeer.STANDAARD],
		["Schotdrager", CombatTarget.Kind.ARMORED, SCHOTDRAGER_X, CombatTarget.Terugkeer.STANDAARD],
		["Dwaallicht", CombatTarget.Kind.ARMORED, DWAALLICHT_X, CombatTarget.Terugkeer.JA],
	]
	for spec: Array in specs:
		var target := CombatTarget.new()
		target.setup_target(spec[1])
		target.name = spec[0]
		target.walks = false
		target.terugkerend = spec[3]
		target.position = Vector2(spec[2], Fx.TARGET_Y) - origin
		root.add_child(target)
		target.owner = root
	var scene := PackedScene.new()
	scene.pack(root)
	root.free()
	return scene


## Geeft {sim, p1, loader, progress, b, respawn}. `inhoud` = de inhoud van B
## (standaard `_enemy_scene`). `wijk` = false: B hoort bij
## geen wijk. `gemaal` = [vulstand, vol] van het gemaal van de wijk, gezet ná
## `bind_area_loader` (er staat geen echt gemaal in C; vóór het binden zou
## `unknown_flags` het melden).
func _world(t, state: GameState, wijk := true, gemaal: Array = [], inhoud: PackedScene = null) -> Dictionary:
	var sim = Fx.world(t)
	var p1 := Fx.manual_player(sim, 1, IN_A)
	var progress := Progress.new()
	progress.name = "TestProgress"
	t.world_root().add_child(progress)
	progress.adopt(state, -1)
	var a: Kamer = Kamer.make(&"A", Rect2(-1000, TOP, 1640, HEIGHT), ["B"])
	var b: Kamer = Kamer.make(&"B", ROOM_B, ["A", "C"])
	var c: Kamer = Kamer.make(&"C", Rect2(1640, TOP, 1360, HEIGHT), ["B", "D"])
	var d: Kamer = Kamer.make(&"D", Rect2(3000, TOP, 1000, HEIGHT), ["C"])
	b.inhoud = inhoud if inhoud != null else _enemy_scene()
	if wijk:
		for room: Kamer in [a, b, c, d]:
			room.wijk_gemaal = WIJK
	var loader := AreaLoader.new()
	loader.name = "AreaLoader"
	for room: Kamer in [a, b, c, d]:
		t.world_root().add_child(room)
		loader.add_kamer(room)
	t.world_root().add_child(loader)
	sim.set_area_loader(loader)
	progress.bind_area_loader(loader, GEBIED)
	if not gemaal.is_empty():
		state.set_gemaal(_gemaal_id(), gemaal[0], gemaal[1])
	var errors := loader.start(sim.tick, p1.position)
	t.check(errors.is_empty(), "start: %s" % [errors])
	var respawn := Respawn.new(p1, func() -> Vector2: return IN_A, progress)
	return {"sim": sim, "p1": p1, "loader": loader, "progress": progress, "b": b, "respawn": respawn}


func _enemy(b: Kamer, enemy_name: String) -> CombatTarget:
	return b.inhoud_node.get_node(enemy_name) if b.inhoud_node != null else null


## Doodt een vijand van B via de schade (zoals Combat); pantser telt niet.
func _defeat(sim: Node, b: Kamer, enemy_name: String) -> void:
	_enemy(b, enemy_name).apply_damage(sim.tick, 1000, "p1")


## Staat de vijand er: aangemeld, zichtbaar, op zijn startplek, vol leven?
func _is_back(sim: Node, target: CombatTarget, x: float) -> bool:
	return target != null and target.alive and target.visible and sim.objects.has(target) \
		and sim.combat.targets.has(target) and target.health == target.health_full() \
		and target.global_position == Vector2(x, Fx.TARGET_Y)


## Is de vijand weg: niet aangemeld, niet zichtbaar?
func _is_away(sim: Node, target: CombatTarget) -> bool:
	return target != null and not target.alive and not target.visible \
		and not sim.objects.has(target) and not sim.combat.targets.has(target)


func _goto(sim: Node, p1: PlayerActor, t, at: Vector2) -> void:
	p1.position = at
	await t.run_ticks(sim, 1)


func _gemaal_id() -> StringName:
	return StringName("%s/%s" % [GEBIED, WIJK])


func _flag(enemy_name: String) -> StringName:
	return AreaLoader.object_flag(&"B", NodePath(enemy_name), GEBIED)


## LM-13 (gdd §4.6, test 1): wijk met gemaal niet vol. Na ontladen en laden
## staan de Kadeloper en het Dwaallicht weer op hun startplek met vol leven,
## de Schotdrager is weg. Zonder ontladen (P1 naar een buur en terug): idem.
## Een Kadeloper met de helft van zijn leven, B ontlaadt en laadt: vol leven.
func test_lm13_returning_enemies_wijk_not_full(t) -> void:
	var state := GameState.new()
	var w := _world(t, state, true, [40, false])
	var sim = w["sim"]
	var p1: PlayerActor = w["p1"]
	var b: Kamer = w["b"]
	t.check(b.inhoud_node != null, "B niet geladen met P1 in A")
	await _goto(sim, p1, t, IN_B)
	_enemy(b, "Kadeloper").position.x += 50.0
	_enemy(b, "Dwaallicht").position.x -= 30.0
	for enemy_name in ["Kadeloper", "Schotdrager", "Dwaallicht"]:
		_defeat(sim, b, enemy_name)
	(w["loader"] as AreaLoader).store_objects()
	t.check(state.has_flag(_flag("Kadeloper")) and state.has_flag(_flag("Schotdrager")),
		"verslagen niet bewaard: %s" % [state.vlaggen])
	# Ontladen (P1 naar D) en weer laden (P1 naar C).
	await _goto(sim, p1, t, IN_C)
	await _goto(sim, p1, t, IN_D)
	t.check(b.inhoud_node == null, "B nog geladen met P1 in D")
	t.check(state.has_flag(_flag("Schotdrager")), "Schotdrager-vlag weg bij ontladen")
	await _goto(sim, p1, t, IN_C)
	t.check(_is_back(sim, _enemy(b, "Kadeloper"), KADELOPER_X), "Kadeloper niet terug na laden")
	t.check(_is_back(sim, _enemy(b, "Dwaallicht"), DWAALLICHT_X), "Dwaallicht niet terug na laden")
	t.check(_is_away(sim, _enemy(b, "Schotdrager")), "Schotdrager terug na laden")
	t.check(not state.has_flag(_flag("Kadeloper")) and state.has_flag(_flag("Schotdrager")),
		"vlaggen na laden: %s" % [state.vlaggen])
	# Zonder ontladen: verslaan in B, naar C (B blijft geladen) en terug.
	await _goto(sim, p1, t, IN_B)
	var kadeloper := _enemy(b, "Kadeloper")
	kadeloper.position.x += 40.0
	_defeat(sim, b, "Kadeloper")
	_defeat(sim, b, "Dwaallicht")
	await _goto(sim, p1, t, IN_C)
	t.check(not kadeloper.alive, "Kadeloper terug zonder binnenkomen")
	await _goto(sim, p1, t, IN_B)
	t.check(_is_back(sim, kadeloper, KADELOPER_X) and _is_back(sim, _enemy(b, "Dwaallicht"), DWAALLICHT_X),
		"niet terug na binnenkomen: Kadeloper op %s, leven %d" % [kadeloper.global_position, kadeloper.health])
	t.check(_is_away(sim, _enemy(b, "Schotdrager")), "Schotdrager terug na binnenkomen")
	# Halve Kadeloper: binnenkomen verandert hem niet, ontladen en laden wel.
	kadeloper.apply_damage(sim.tick, 15, "p1")
	await _goto(sim, p1, t, IN_C)
	await _goto(sim, p1, t, IN_B)
	t.check(kadeloper.alive and kadeloper.health == kadeloper.health_full() - 15,
		"binnenkomen veranderde een levende vijand: leven %d" % kadeloper.health)
	await _goto(sim, p1, t, IN_C)
	await _goto(sim, p1, t, IN_D)
	await _goto(sim, p1, t, IN_C)
	t.check(_is_back(sim, _enemy(b, "Kadeloper"), KADELOPER_X), "halve Kadeloper niet vol na laden")
	await t.cleanup()


## LM-13 (test 1, slot; test Dwaallicht, slot) en LM-09(a): gemaal vol. Een
## verslagen Kadeloper (ook als hij vóór het vullen viel) en een verslagen
## Dwaallicht komen niet terug: niet bij binnenkomen, niet na laden, niet na
## opslaan en laden, niet na sterven.
func test_lm13_wijk_full_nothing_returns(t) -> void:
	var state := GameState.new()
	var gemaal_id := _gemaal_id()
	var w := _world(t, state, true, [60, false])
	var sim = w["sim"]
	var p1: PlayerActor = w["p1"]
	var b: Kamer = w["b"]
	var loader: AreaLoader = w["loader"]
	var progress: Progress = w["progress"]
	await _goto(sim, p1, t, IN_B)
	_defeat(sim, b, "Kadeloper")
	_defeat(sim, b, "Dwaallicht")
	# Het gemaal wordt pas daarna vol.
	state.set_gemaal(gemaal_id, 100, true)
	t.check(loader.is_wijk_full(b), "wijk niet vol")
	await _goto(sim, p1, t, IN_C)
	await _goto(sim, p1, t, IN_B)
	t.check(not _enemy(b, "Kadeloper").alive and not _enemy(b, "Dwaallicht").alive,
		"Kadeloper of Dwaallicht terug na binnenkomen in een volle wijk")
	await _goto(sim, p1, t, IN_C)
	await _goto(sim, p1, t, IN_D)
	await _goto(sim, p1, t, IN_C)
	t.check(_is_away(sim, _enemy(b, "Kadeloper")) and _is_away(sim, _enemy(b, "Dwaallicht")),
		"Kadeloper of Dwaallicht terug na laden in een volle wijk")
	# Opslaan en laden: de vlag gaat mee door de save (to_dict/from_dict).
	progress.store_world()
	var errors := PackedStringArray()
	var loaded: GameState = GameState.from_dict(state.to_dict(), errors)
	t.check(errors.is_empty() and loaded.has_flag(_flag("Kadeloper")) and loaded.has_flag(_flag("Dwaallicht")),
		"vlag niet in de save: %s" % [errors])
	await _goto(sim, p1, t, IN_D)
	progress.adopt(loaded, -1)
	# Verwacht: één waarschuwing van `unknown_flags` (geen echt gemaal in C).
	progress.bind_area_loader(loader, GEBIED)
	await _goto(sim, p1, t, IN_C)
	t.check(_is_away(sim, _enemy(b, "Kadeloper")) and _is_away(sim, _enemy(b, "Dwaallicht")),
		"Kadeloper of Dwaallicht terug na opslaan en laden")
	# Sterven en respawnen in B (het checkpoint): hij blijft weg (LM-13e).
	await _goto(sim, p1, t, IN_B)
	progress.reach_checkpoint(IN_B)
	p1.health = 1
	p1.take_hit(sim.tick)
	await t.run_ticks(sim, 1)
	t.check(p1.died and _is_away(sim, _enemy(b, "Kadeloper")), "Kadeloper terug na sterven in een volle wijk")
	await t.cleanup()


## LM-13 (test 2): respawn telt als binnenkomen van de kamer van het
## checkpoint. Wijk niet vol: P1 verslaat de Kadeloper in B en sterft daar;
## op de respawntick staat de Kadeloper op zijn startplek met vol leven. De
## Schotdrager blijft weg.
func test_lm13_respawn_counts_as_entering(t) -> void:
	var w := _world(t, GameState.new())
	var sim = w["sim"]
	var p1: PlayerActor = w["p1"]
	var b: Kamer = w["b"]
	var progress: Progress = w["progress"]
	await _goto(sim, p1, t, IN_B)
	progress.reach_checkpoint(IN_B)
	var kadeloper := _enemy(b, "Kadeloper")
	kadeloper.position.x += 60.0
	_defeat(sim, b, "Kadeloper")
	_defeat(sim, b, "Schotdrager")
	await t.run_ticks(sim, 3)
	t.check(not kadeloper.alive, "Kadeloper terug zonder binnenkomen")
	p1.health = 1
	p1.take_hit(sim.tick)
	await t.run_ticks(sim, 1)
	t.check(p1.died and p1.position.distance_to(IN_B) < 1.0, "geen respawn op het checkpoint: %s" % p1.position)
	t.check(_is_back(sim, kadeloper, KADELOPER_X), "Kadeloper niet terug na de respawn")
	t.check(not _enemy(b, "Schotdrager").alive, "Schotdrager terug na de respawn")
	await t.cleanup()


## LM-13 (test 3): een kamer zonder wijk telt als niet vol.
func test_lm13_room_without_wijk(t) -> void:
	var state := GameState.new()
	# Een vol gemaal elders verandert niets: B hoort bij geen wijk.
	var w := _world(t, state, false, [100, true])
	var sim = w["sim"]
	var p1: PlayerActor = w["p1"]
	var b: Kamer = w["b"]
	t.check(not (w["loader"] as AreaLoader).is_wijk_full(b), "kamer zonder wijk telt als vol")
	await _goto(sim, p1, t, IN_B)
	_defeat(sim, b, "Kadeloper")
	await _goto(sim, p1, t, IN_C)
	await _goto(sim, p1, t, IN_B)
	t.check(_is_back(sim, _enemy(b, "Kadeloper"), KADELOPER_X), "Kadeloper niet terug in een kamer zonder wijk")
	await t.cleanup()


## LM-13(a) en de indeling: de soort bepaalt de standaard, `terugkerend`
## overschrijft; het pomprad heeft geen stand; `validate` meldt een
## `wijk_gemaal` die niet met een kamer van het gebied begint.
func test_lm13_returning_kinds_and_validation(t) -> void:
	var cases := [
		[CombatTarget.Kind.ENEMY, CombatTarget.Terugkeer.STANDAARD, true],
		[CombatTarget.Kind.ARMORED, CombatTarget.Terugkeer.STANDAARD, false],
		[CombatTarget.Kind.ENEMY, CombatTarget.Terugkeer.NEE, false],
		[CombatTarget.Kind.ARMORED, CombatTarget.Terugkeer.JA, true],
	]
	for case: Array in cases:
		var target := CombatTarget.new()
		target.kind = case[0]
		target.terugkerend = case[1]
		t.check(target.is_returning() == case[2], "soort %d, terugkerend %d: %s" % [case[0], case[1], target.is_returning()])
		t.check(target.has_persistent_state(), "vijand zonder blijvende stand")
		target.free()
	var dummy := CombatTarget.new()
	dummy.setup_target(CombatTarget.Kind.DUMMY)
	var pomprad: CombatTarget = load("res://scripts/light/pomprad.gd").new()
	t.check(not dummy.has_persistent_state() and not pomprad.has_persistent_state(), "trefpop of pomprad met stand")
	dummy.free()
	pomprad.free()
	var loader := AreaLoader.new()
	var a: Kamer = Kamer.make(&"A", Rect2(0, 0, 100, 100), [])
	a.wijk_gemaal = &"X/Gemaal"
	loader.add_kamer(a)
	var errors := loader.validate()
	t.check(errors.size() == 1 and errors[0].contains("wijk_gemaal"), "validate: %s" % [errors])
	a.wijk_gemaal = &"A/Gemaal"
	t.check(loader.validate().is_empty(), "validate met een goede wijk: %s" % [loader.validate()])
	a.free()
	loader.free()
	await t.cleanup()


## Zoals een vijand die de World & Level Designer in de editor in de inhoud
## zet: alleen geëxporteerde waarden, géén `setup_target`. De Kadeloper heeft
## geen vlak (dan het standaardvlak), de Schotdrager een eigen vlak van
## 20 × 30 en `walks` aan (de standaard in de inspector).
func _editor_scene() -> PackedScene:
	var origin := ROOM_B.get_center()
	var root := Node2D.new()
	root.name = "Inhoud"
	var kadeloper := CombatTarget.new()
	kadeloper.name = "Kadeloper"
	kadeloper.kind = CombatTarget.Kind.ENEMY
	kadeloper.walks = false
	kadeloper.position = Vector2(KADELOPER_X, Fx.TARGET_Y) - origin
	var schotdrager := CombatTarget.new()
	schotdrager.name = "Schotdrager"
	schotdrager.kind = CombatTarget.Kind.ARMORED
	var rect := RectangleShape2D.new()
	rect.size = Vector2(20, 30)
	schotdrager.shape = rect
	schotdrager.position = Vector2(SCHOTDRAGER_X, Fx.TARGET_Y) - origin
	for target: CombatTarget in [kadeloper, schotdrager]:
		root.add_child(target)
		target.owner = root
	var scene := PackedScene.new()
	scene.pack(root)
	root.free()
	return scene


func _visuals(target: CombatTarget) -> Array[Polygon2D]:
	var found: Array[Polygon2D] = []
	for child in target.get_children():
		if child is Polygon2D:
			found.append(child)
	return found


## LM-13, §12 punt (2), deel 1: een vijand die verslagen wordt in een kamer
## die geladen blijft, verdwijnt op die tick (niet zichtbaar, niet meer te
## raken). Hij blijft bij de Sim aangemeld (*keuze TD*, ontwerp.md §3a) en
## komt bij binnenkomen terug op zijn startplek, weer zichtbaar; de
## Schotdrager blijft weg en onzichtbaar.
func test_lm13_defeated_enemy_disappears_in_loaded_room(t) -> void:
	var state := GameState.new()
	var w := _world(t, state, true, [40, false])
	var sim = w["sim"]
	var p1: PlayerActor = w["p1"]
	var b: Kamer = w["b"]
	await _goto(sim, p1, t, IN_B)
	var kadeloper := _enemy(b, "Kadeloper")
	var schotdrager := _enemy(b, "Schotdrager")
	var died: Array = []
	kadeloper.died.connect(func(tick: int) -> void: died.append([tick, kadeloper.visible]))
	t.check(kadeloper.visible and schotdrager.visible, "vijanden niet zichtbaar vóór het gevecht")
	_defeat(sim, b, "Kadeloper")
	_defeat(sim, b, "Schotdrager")
	t.check(died.size() == 1 and died[0][1] == false, "Kadeloper zichtbaar bij `died`: %s" % [died])
	t.check(not kadeloper.visible and not schotdrager.visible, "verslagen vijand nog zichtbaar")
	var box := Rect2(kadeloper.global_position - Vector2(20, 20), Vector2(40, 40))
	t.check(not kadeloper.is_hit_by(box, Layers.LIGHT), "verslagen vijand nog te raken")
	await t.run_ticks(sim, 5)
	t.check(not kadeloper.visible and not schotdrager.visible and sim.objects.has(kadeloper),
		"na 5 ticks: zichtbaar %s / %s, aangemeld %s" % [kadeloper.visible, schotdrager.visible, sim.objects.has(kadeloper)])
	await _goto(sim, p1, t, IN_C)
	await _goto(sim, p1, t, IN_B)
	t.check(_is_back(sim, kadeloper, KADELOPER_X), "Kadeloper niet zichtbaar terug na binnenkomen")
	t.check(not schotdrager.alive and not schotdrager.visible, "Schotdrager terug of zichtbaar na binnenkomen")
	await t.cleanup()


## LM-13, §12 punt (2), deel 2: een vijand uit de editor (geen
## `setup_target`) krijgt bij het laden zijn beeld (één `Polygon2D`, zo groot
## als zijn vlak, in de kleur van zijn soort), het standaardvlak als hij er
## geen had, vol leven en het pantser van zijn soort; een pantserdoel loopt
## niet. Hij doet mee zoals een vijand uit code (aangemeld, te raken) en
## volgt LM-13 (weg na ontladen en laden). Een vijand uit code heeft ook na
## inpakken en laden precies één beeld.
func test_lm13_enemy_placed_in_editor(t) -> void:
	var state := GameState.new()
	var w := _world(t, state, true, [40, false], _editor_scene())
	var sim = w["sim"]
	var p1: PlayerActor = w["p1"]
	var b: Kamer = w["b"]
	var kadeloper := _enemy(b, "Kadeloper")
	var schotdrager := _enemy(b, "Schotdrager")
	var size: Array = load("res://scripts/echo/tuning.gd").combat()["enemy_size"]
	var cases := [[kadeloper, Vector2(float(size[0]), float(size[1]))], [schotdrager, Vector2(20, 30)]]
	for case: Array in cases:
		var target: CombatTarget = case[0]
		var visuals := _visuals(target)
		var want: Vector2 = case[1]
		t.check(target.shape is RectangleShape2D and (target.shape as RectangleShape2D).size == want,
			"%s: vlak %s (verwacht %s)" % [target.name, target.shape, want])
		t.check(visuals.size() == 1 and visuals[0].color == CombatTarget.COLORS[target.kind]
			and visuals[0].polygon[2] == want * 0.5, "%s: beeld %s" % [target.name, visuals.map(func(v): return v.polygon)])
		t.check(target.alive and target.visible and target.health == target.health_full()
			and sim.objects.has(target) and sim.combat.targets.has(target),
			"%s: leven %d, aangemeld %s" % [target.name, target.health, sim.objects.has(target)])
	t.check(schotdrager.armor_intact and not schotdrager.walks, "Schotdrager: pantser %s, loopt %s"
		% [schotdrager.armor_intact, schotdrager.walks])
	var box := Rect2(kadeloper.global_position - Vector2(20, 20), Vector2(40, 40))
	t.check(kadeloper.is_hit_by(box, Layers.LIGHT), "Kadeloper uit de editor niet te raken")
	await _goto(sim, p1, t, IN_B)
	_defeat(sim, b, "Schotdrager")
	await _goto(sim, p1, t, IN_C)
	await _goto(sim, p1, t, IN_D)
	await _goto(sim, p1, t, IN_C)
	t.check(_is_away(sim, _enemy(b, "Schotdrager")), "Schotdrager uit de editor terug na laden")
	t.check(_visuals(_enemy(b, "Kadeloper")).size() == 1, "Kadeloper na opnieuw laden: %d beelden"
		% _visuals(_enemy(b, "Kadeloper")).size())
	await t.cleanup()


## Een vijand uit code (`setup_target`, zoals in de flow-kamer en in
## `_enemy_scene`): één beeld, ook na inpakken en laden in een kamer.
func test_lm13_code_built_enemy_one_visual(t) -> void:
	var w2 := _world(t, GameState.new(), true, [40, false])
	var code_built := _enemy(w2["b"], "Kadeloper")
	t.check(_visuals(code_built).size() == 1 and code_built.get_node_or_null(^"Beeld") != null,
		"vijand uit code: %d beelden" % _visuals(code_built).size())
	var direct: CombatTarget = Fx.target(w2["sim"], CombatTarget.Kind.ARMORED, 400)
	t.check(_visuals(direct).size() == 1, "doel uit code direct in de Sim: %d beelden" % _visuals(direct).size())
	await t.cleanup()
