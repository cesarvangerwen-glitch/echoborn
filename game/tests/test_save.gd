extends RefCounted
## Tests voor opslaan en laden v1 (T5b, #82; ontwerp.md §7): rondreis exact,
## atomair schrijven met back-up, versies en migratie, en laden op een
## checkpoint in de goede kamer met een Lege echo.

const Fx = preload("res://tests/echo_fixture.gd")
const GameState = preload("res://scripts/save/game_state.gd")
const SaveService = preload("res://scripts/save/save_service.gd")
const Kamer = preload("res://scripts/world/kamer.gd")
const AreaLoader = preload("res://scripts/world/area_loader.gd")

## Eigen map, zodat een test nooit een echte save raakt.
const DIR := "user://test_saves_t5b"


func _state() -> GameState:
	var state := GameState.new()
	state.gebied = &"flow_kamer"
	state.checkpoint_kamer = &"K2"
	state.checkpoint_positie = Vector2(700.123456789012, 385.0000000001)
	state.lichtmeter = 64
	state.set_gemaal(&"gemaal_k3", 37, false)
	state.set_flag(&"sluis_k3_open")
	state.speeltijd_ticks = 123456
	return state


func _clear() -> void:
	var dir := DirAccess.open(DIR)
	if dir == null:
		return
	for file in dir.get_files():
		dir.remove(file)
	DirAccess.remove_absolute(DIR)


## Opslaan → laden geeft exact dezelfde inhoud (ook een float op volle
## precisie); twee keer dezelfde save geeft hetzelfde bestand; geen .tmp over.
func test_save_roundtrip_exact_and_deterministic(t) -> void:
	_clear()
	var path := SaveService.slot_path(1, DIR)
	var state := _state()
	t.check(SaveService.write(path, state) == OK, "schrijven mislukt")
	var first := FileAccess.get_file_as_string(path)
	var result := SaveService.read(path)
	var loaded: GameState = result["state"]
	t.check(loaded != null and result["errors"].is_empty(), "lezen mislukt: %s" % result["errors"])
	t.check(loaded != null and loaded.equals(state), "inhoud na laden anders")
	t.check(loaded != null and loaded.checkpoint_positie == state.checkpoint_positie,
		"positie niet exact: %s" % (loaded.checkpoint_positie if loaded else null))
	t.check(loaded != null and loaded.has_flag(&"sluis_k3_open") and loaded.gemalen[&"gemaal_k3"]["vulstand"] == 37,
		"vlag of gemaal niet terug")
	SaveService.write(path, state)
	t.check(FileAccess.get_file_as_string(path) == first, "tweede save van dezelfde inhoud geeft een ander bestand")
	t.check(not FileAccess.file_exists(path + ".tmp"), ".tmp blijft staan")
	t.check(first.contains("\"version\": 1"), "versie niet in het bestand")
	_clear()


## De vorige save wordt .bak; is de save kapot, dan laadt de back-up.
## Zonder save en zonder back-up: een fout, geen toestand.
func test_save_backup_when_file_is_broken(t) -> void:
	_clear()
	var path := SaveService.slot_path(2, DIR)
	var old := _state()
	var new := _state()
	new.lichtmeter = 100
	SaveService.write(path, old)
	SaveService.write(path, new)
	var normal := SaveService.read(path)
	t.check(normal["state"] != null and normal["state"].lichtmeter == 100 and not normal["from_backup"],
		"nieuwste save niet geladen")
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string("{\"version\": 1, \"gebied\": ")
	file.close()
	var result := SaveService.read(path)
	t.check(result["from_backup"] and result["state"] != null and result["state"].equals(old),
		"kapotte save: back-up niet geladen (%s)" % result["errors"])
	t.check(not result["errors"].is_empty(), "de fout van de kapotte save is niet gemeld")
	var none := SaveService.read(SaveService.slot_path(9, DIR))
	t.check(none["state"] == null and not none["errors"].is_empty(), "lege slot gaf een toestand")
	_clear()


## Een save van een nieuwere versie of zonder versie wordt geweigerd; een
## oudere gaat stap voor stap door de migraties (hier een testmigratie 1 → 2,
## want v1 is de eerste versie). Een ontbrekende migratie is een fout.
func test_save_versions_and_migration(t) -> void:
	var data := _state().to_dict()
	data["version"] = 1
	var errors := PackedStringArray()
	t.check(SaveService.migrate(data, errors) == data and errors.is_empty(), "v1 → v1 verandert iets: %s" % errors)
	var future := data.duplicate(true)
	future["version"] = 2
	errors = PackedStringArray()
	t.check(SaveService.migrate(future, errors).is_empty() and errors[0].contains("versie 2"),
		"nieuwere versie niet geweigerd: %s" % errors)
	var missing := data.duplicate(true)
	missing.erase("version")
	errors = PackedStringArray()
	t.check(SaveService.migrate(missing, errors).is_empty() and not errors.is_empty(), "save zonder versie geaccepteerd")
	var calls := [0]
	var double_light := func(d: Dictionary) -> Dictionary:
		calls[0] += 1
		d["lichtmeter"] = int(d["lichtmeter"]) * 2
		return d
	errors = PackedStringArray()
	var migrated := SaveService.migrate(data, errors, {1: double_light}, 2)
	t.check(errors.is_empty() and migrated["version"] == 2 and migrated["lichtmeter"] == 128 and calls[0] == 1,
		"migratie 1 → 2: %s, %s" % [migrated, errors])
	t.check(data["lichtmeter"] == 64, "migratie veranderde de invoer")
	errors = PackedStringArray()
	SaveService.migrate(data, errors, {1: double_light}, 3)
	t.check(errors.size() == 1 and errors[0].contains("2 naar 3"), "ontbrekende migratie niet gemeld: %s" % errors)
	var broken := data.duplicate(true)
	broken["checkpoint"].erase("x")
	errors = PackedStringArray()
	t.check(GameState.from_dict(broken, errors) == null and errors[0].contains("'x'"),
		"ontbrekend veld niet gemeld: %s" % errors)


## Laden op een checkpoint: de AreaLoader begint in de kamer uit de save met
## zijn buren geladen, zonder kamerwissel; de echo is D ticks Leeg en staat
## dan op het checkpoint (zoals na een respawn, E-04).
func test_save_load_starts_in_saved_room(t) -> void:
	_clear()
	var path := SaveService.slot_path(3, DIR)
	var saved := _state()
	saved.checkpoint_kamer = &"B"
	saved.checkpoint_positie = Vector2(700, Fx.STAND_Y)
	SaveService.write(path, saved)
	var state: GameState = SaveService.read(path)["state"]
	var sim = Fx.world(t)
	var p1 := Fx.p1(sim, [], state.checkpoint_positie)
	var echo := Fx.tail_echo(sim, p1, 120)
	var loader := AreaLoader.new()
	for room: Kamer in [
			Kamer.make(&"A", Rect2(-1000, -400, 1640, 1200), ["B"]) as Kamer,
			Kamer.make(&"B", Rect2(640, -400, 200, 1200), ["A", "C"]) as Kamer,
			Kamer.make(&"C", Rect2(840, -400, 2000, 1200), ["B"]) as Kamer]:
		t.world_root().add_child(room)
		loader.add_kamer(room)
	t.world_root().add_child(loader)
	sim.set_area_loader(loader)
	var switches: Array = []
	loader.kamer_gewisseld.connect(func(tick: int, _van: StringName, _naar: StringName, _reset: bool) -> void:
		switches.append(tick))
	var errors := loader.start(sim.tick, p1.position, state.checkpoint_kamer)
	t.check(errors.is_empty() and loader.huidige == &"B" and loader.loaded_ids() == [&"A", &"B", &"C"],
		"start: kamer %s, geladen %s, fouten %s" % [loader.huidige, loader.loaded_ids(), errors])
	await t.run_ticks(sim, 120)
	t.check(not echo.is_present(), "echo niet Leeg op tick 119")
	await t.run_ticks(sim, 1)
	t.check(echo.is_present() and echo.position == state.checkpoint_positie,
		"echo op tick 120 niet Actief op het checkpoint (%s)" % echo.position)
	t.check(switches.is_empty(), "kamerwissel bij laden: %s" % [switches])
	_clear()
