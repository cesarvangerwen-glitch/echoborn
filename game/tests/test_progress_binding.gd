extends RefCounted
## De binding van schema v2 via `Progress` (T8a, #83; ontwerp.md §12 punt 2 (a)
## en (b), acceptatiecriterium uit de SM-review van #281):
##
## - **Levenspunten** (LM-07): `Progress.bind_player` geeft P1 het maximum uit de
##   save (5 + lampglazen) en `levenspunten` (geklemd op 1 … max, 0 = vol);
##   `store_world` schrijft ze terug.
## - **Vaardigheden en verzamelobjecten** (V-01, WS-08): een `Pickup` schrijft
##   bij het oppakken zelf `set_vaardigheid` of `add_verzamelobject`; de
##   Kadewijk leest de Neerslag uit `vaardigheden` en het lampglas (via het
##   maximum) uit `verzamelobjecten`, niet meer uit de vlaggen.
## - **Regressie, terugval bij het laden**: een v1-save en een v2-save van vóór
##   de binding hebben alleen de vlag van de sokkel en die van het lampglas.
##   Na laden: V-01 en 6 levenspunten (anders een doodlopende kade, S8/S9).
##
## Elke test maakt een eigen `Progress` en een eigen map; de autoloads en
## `user://saves` blijven onaangeroerd.

const Scene := preload("res://levels/kadewijk/kadewijk.tscn")
const Kadewijk = preload("res://levels/kadewijk/kadewijk.gd")
const Layout = preload("res://levels/kadewijk/kadewijk_layout.gd")
const Progress = preload("res://scripts/save/progress.gd")
const GameState = preload("res://scripts/save/game_state.gd")
const SaveService = preload("res://scripts/save/save_service.gd")
const AreaLoader = preload("res://scripts/world/area_loader.gd")
const Pickup = preload("res://scripts/objects/pickup.gd")
const Fx = preload("res://tests/echo_fixture.gd")
const InputBits = preload("res://scripts/input/input_bits.gd")
const ScriptedInput = preload("res://scripts/input/scripted_input.gd")

const DIR := "user://test_saves_progress_binding"
const SOKKEL := &"kadewijk/S7/Neerslag"
const LAMPGLAS := &"kadewijk/S5/Lampglas"


func _clear() -> void:
	var dir := DirAccess.open(DIR)
	if dir == null:
		return
	for file in dir.get_files():
		dir.remove(file)
	DirAccess.remove_absolute(DIR)


func _write_text(path: String, text: String) -> void:
	DirAccess.make_dir_recursive_absolute(DIR)
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string(text)
	f.close()


## Een save in de Kadewijk zoals de code vóór de binding hem schreef: de vlag
## van de sokkel (S7) en van het lampglas (S5), het checkpoint in S1, en (in v2)
## `vaardigheden` en `verzamelobjecten` leeg en de levenspunten op de start.
func _old_state() -> GameState:
	var state := GameState.new()
	state.gebied = Kadewijk.GEBIED
	state.checkpoint_kamer = &"S1"
	state.checkpoint_positie = Layout.ROOM_START[&"S1"]
	state.set_flag(SOKKEL)
	state.set_flag(LAMPGLAS)
	return state


## Een v1-save (zonder de velden van v2), als tekst.
func _v1_text() -> String:
	var data := _old_state().to_dict()
	for key in ["levenspunten", "waterstanden", "vaardigheden", "verzamelobjecten"]:
		data.erase(key)
	data["version"] = 1
	return JSON.stringify(data, "\t", true, true)


## De Kadewijk met `state` in een eigen `Progress`, P1 in `start`.
func _wijk(t, state: GameState, start: StringName, input: RefCounted) -> Array:
	var progress := Progress.new()
	progress.name = "TestProgress"
	t.tree.root.add_child(progress)
	progress.adopt(state, -1)
	var wijk = Scene.instantiate()
	wijk.tail = 60
	wijk.echo_on = true
	wijk.show_hud = false
	wijk.progress = progress
	wijk.start_at = Layout.ROOM_START[start]
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


## Regressie (ontwerp.md §12 punt 2 (b)): een v1-save en een v2-save van vóór
## de binding, allebei met de vlag van de sokkel en die van het lampglas maar
## zonder vaardigheden en verzamelobjecten. Na laden heeft P1 de Neerslag (V-01)
## en 6 levenspunten (van 6), en staan V-01 en het lampglas in `state`. De
## volgende save is v2 met die velden; laden daarvan vult niets meer aan.
func test_regressie_oude_saves_geven_v01_en_6_levenspunten(t) -> void:
	_clear()
	var v1_path := DIR + "/slot_v1.json"
	var v2_path := DIR + "/slot_v2.json"
	_write_text(v1_path, _v1_text())
	t.check(SaveService.write(v2_path, _old_state()) == OK, "v2 van vóór de binding: schrijven mislukt")
	for path: String in [v1_path, v2_path]:
		var label := path.get_file()
		var result := SaveService.read(path)
		var state: GameState = result["state"]
		t.check(state != null and result["errors"].is_empty(), "%s laadt niet: %s" % [label, result["errors"]])
		if state == null:
			continue
		t.check(result["version"] == (1 if path == v1_path else 2), "%s: versie %d" % [label, result["version"]])
		t.check(state.has_flag(SOKKEL) and state.has_flag(LAMPGLAS) and state.vaardigheden.is_empty()
			and state.verzamelobjecten.is_empty() and state.levenspunten == 5,
			"%s is geen save van vóór de binding: %s" % [label, state.to_dict()])
		var parts := _wijk(t, state, &"S1", ScriptedInput.new([]))
		var wijk = parts[0]
		var progress = parts[1]
		await _ticks(t, 2)
		t.check(wijk.start_errors.is_empty(), "%s: start: %s" % [label, wijk.start_errors])
		t.check(wijk.sim.neerslag_unlocked and wijk.has_neerslag() and progress.state.has_vaardigheid(&"V-01"),
			"%s: de Neerslag weg na laden (vrij %s, vaardigheden %s)" % [label, wijk.sim.neerslag_unlocked, progress.state.vaardigheden])
		t.check(wijk.p1.max_health == 6 and wijk.p1.health == 6,
			"%s: %d van %d levenspunten (verwacht 6 van 6)" % [label, wijk.p1.health, wijk.p1.max_health])
		t.check(progress.state.verzamelobjecten == {LAMPGLAS: &"lampglas"} and progress.state.max_levenspunten() == 6,
			"%s: verzamelobjecten %s" % [label, progress.state.verzamelobjecten])
		# De volgende save is v2 met de velden; laden daarvan vult niets meer aan.
		progress.store_world()
		var again_path := path + ".na"
		t.check(SaveService.write(again_path, progress.state) == OK, "%s: opnieuw schrijven mislukt" % label)
		var again: GameState = SaveService.read(again_path)["state"]
		t.check(again != null and again.has_vaardigheid(&"V-01") and again.lampglazen() == 1 and again.levenspunten == 6,
			"%s: na opnieuw opslaan: %s" % [label, again.to_dict() if again else null])
		t.check(again != null and wijk.loader.apply_pickup_fallback(again) == 0, "%s: de terugval vult een nieuwe save nog aan" % label)
		await _free(t, parts)
	_clear()


## Zonder de vlag geen terugval: een nieuw spel heeft geen V-01 en 5 levenspunten.
## Een vlag van een logbladzijde wordt een `logbladzijde` (WS-08), en de
## levenspunten blijven dan 5 (van 5). Met de vlag van de sokkel maar zonder die
## van het lampglas: V-01, 5 van 5.
func test_terugval_alleen_bij_de_vlag(t) -> void:
	var fresh := GameState.new()
	var parts := _wijk(t, fresh, &"S1", ScriptedInput.new([]))
	await _ticks(t, 1)
	t.check(not parts[0].sim.neerslag_unlocked and parts[0].p1.max_health == 5 and parts[0].p1.health == 5
		and parts[1].state.vaardigheden.is_empty() and parts[1].state.verzamelobjecten.is_empty(),
		"nieuw spel: vrij %s, %d van %d" % [parts[0].sim.neerslag_unlocked, parts[0].p1.health, parts[0].p1.max_health])
	await _free(t, parts)
	var state := GameState.new()
	state.set_flag(SOKKEL)
	state.set_flag(&"kadewijk/S6/Logbladzijde2")
	parts = _wijk(t, state, &"S1", ScriptedInput.new([]))
	await _ticks(t, 1)
	t.check(parts[0].sim.neerslag_unlocked and parts[0].p1.max_health == 5 and parts[0].p1.health == 5,
		"alleen de sokkel: vrij %s, %d van %d" % [parts[0].sim.neerslag_unlocked, parts[0].p1.health, parts[0].p1.max_health])
	t.check(parts[1].state.verzamelobjecten == {&"kadewijk/S6/Logbladzijde2": &"logbladzijde"},
		"logbladzijde 2: %s" % [parts[1].state.verzamelobjecten])
	await _free(t, parts)


## LM-07 (ontwerp.md §12 punt 2 (a)): de levenspunten komen uit de save en gaan
## terug in `store_world`. Met een lampglas in `verzamelobjecten` is het
## maximum 6; 3 blijft 3; 0 laadt vol; meer dan het maximum wordt het maximum.
func test_levenspunten_uit_en_naar_de_save(t) -> void:
	for c: Array in [[3, true, 3, 6], [0, true, 6, 6], [8, false, 5, 5], [6, true, 6, 6]]:
		var state := GameState.new()
		state.levenspunten = c[0]
		if c[1]:
			state.add_verzamelobject(LAMPGLAS, &"lampglas")
			state.set_flag(LAMPGLAS)
		var parts := _wijk(t, state, &"S1", ScriptedInput.new([]))
		var wijk = parts[0]
		await _ticks(t, 1)
		t.check(wijk.p1.health == c[2] and wijk.p1.max_health == c[3],
			"save %d LP (lampglas %s): %d van %d (verwacht %d van %d)" % [c[0], c[1], wijk.p1.health, wijk.p1.max_health, c[2], c[3]])
		wijk.p1.health = 2
		parts[1].store_world()
		t.check(parts[1].state.levenspunten == 2, "store_world: %d levenspunten in de save (verwacht 2)" % parts[1].state.levenspunten)
		await _free(t, parts)


## Een `Pickup` schrijft bij het oppakken zelf in `game_state`, vóór
## `picked_up`: een vaardigheid in `vaardigheden`, een lampglas of
## logbladzijde in `verzamelobjecten` (met zijn vlag als id). Twee keer
## `record_in` verandert niets meer.
func test_pickup_schrijft_in_de_save(t) -> void:
	for c: Array in [[Pickup.Soort.VAARDIGHEID, &"V-01"], [Pickup.Soort.LAMPGLAS, &"lampglas"], [Pickup.Soort.LOGBLADZIJDE, &"logbladzijde"]]:
		var sim = Fx.world(t)
		var state := GameState.new()
		var pickup := Pickup.new()
		pickup.soort = c[0]
		pickup.vaardigheid = &"V-01" if c[0] == Pickup.Soort.VAARDIGHEID else &""
		pickup.game_state = state
		pickup.save_id = &"g/K1/Ding"
		pickup.position = Vector2(300, Fx.STAND_Y)
		t.world_root().add_child(pickup)
		sim.add_object(pickup)
		var seen: Array = []
		pickup.picked_up.connect(func(_tick: int, _who: String) -> void:
			seen.append(state.has_vaardigheid(&"V-01") or state.has_verzamelobject(&"g/K1/Ding")))
		Fx.p1(sim, [[200, InputBits.RIGHT]], Vector2(200, Fx.STAND_Y))
		await t.run_ticks(sim, 80)
		var ok: bool
		if c[0] == Pickup.Soort.VAARDIGHEID:
			ok = state.has_vaardigheid(&"V-01") and state.verzamelobjecten.is_empty()
		else:
			ok = state.verzamelobjecten == {&"g/K1/Ding": c[1]} and state.vaardigheden.is_empty()
		t.check(pickup.opgepakt and ok and seen == [true], "%s: vaardigheden %s, verzamelobjecten %s, bij picked_up al in state %s" % [
			c[1], state.vaardigheden, state.verzamelobjecten, seen])
		t.check(not pickup.record_in(state, &"g/K1/Ding"), "%s: record_in twee keer veranderde state" % c[1])
		await t.cleanup()


## In de Kadewijk: de sokkel van S7 schrijft V-01 meteen in `Progress.state`
## (de `AreaLoader` gaf de pick-up de save en zijn vlag), en het lampglas van
## S5 `kadewijk/S5/Lampglas` als `lampglas`.
func test_kadewijk_pickups_schrijven_in_progress(t) -> void:
	var parts := _wijk(t, GameState.new(), &"S7", ScriptedInput.new([[200, InputBits.RIGHT]]))
	var wijk = parts[0]
	await _ticks(t, 120)
	t.check(wijk.neerslag_tick > 0 and parts[1].state.has_vaardigheid(&"V-01") and wijk.has_neerslag(),
		"S7: opgepakt op %d, vaardigheden %s" % [wijk.neerslag_tick, parts[1].state.vaardigheden])
	await _free(t, parts)
	parts = _wijk(t, GameState.new(), &"S5", ScriptedInput.new([]))
	await _ticks(t, 1)
	var inhoud: Node = parts[0].loader.kamers[&"S5"].inhoud_node
	var lampglas := inhoud.get_node_or_null(^"Lampglas") as Pickup if inhoud != null else null
	t.check(lampglas != null and lampglas.save_id == LAMPGLAS and lampglas.game_state == parts[1].state,
		"S5: het lampglas kreeg %s en %s" % [lampglas.save_id if lampglas else null, lampglas.game_state if lampglas else null])
	await _free(t, parts)


## `flag_renames` zet ook de id van een verzamelobject om (de id is de vlag):
## anders vult de terugval het lampglas onder de nieuwe naam nog eens aan en
## telt het dubbel.
func test_flag_renames_verzamelobject(t) -> void:
	var loader := AreaLoader.new()
	loader.flag_renames = {&"g/K1/Oud": &"g/K1/Nieuw"}
	var state := GameState.new()
	state.set_flag(&"g/K1/Oud")
	state.add_verzamelobject(&"g/K1/Oud", &"lampglas")
	var moved := loader.apply_flag_renames(state)
	t.check(moved == 2 and state.has_flag(&"g/K1/Nieuw") and state.verzamelobjecten == {&"g/K1/Nieuw": &"lampglas"} and state.lampglazen() == 1,
		"hernoemd: %d, vlaggen %s, verzamelobjecten %s" % [moved, state.vlaggen, state.verzamelobjecten])
	loader.free()
