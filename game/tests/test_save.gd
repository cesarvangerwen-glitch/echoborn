extends RefCounted
## Tests voor opslaan en laden (T5b, #82; ontwerp.md §7): rondreis exact,
## atomair schrijven met back-up, versies en migratie (ook de echte 1 → 2),
## de controles van schema v2, en laden op een checkpoint in de goede kamer
## met een Lege echo.

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
	state.levenspunten = 4
	state.set_waterstand(&"gemaal_k3", 0)
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
	t.check(first.contains("\"version\": %d" % SaveService.VERSION), "versie niet in het bestand")
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
## oudere gaat stap voor stap door de migraties (hier een eigen testtabel
## 1 → 2 → 3, los van de echte). Een ontbrekende migratie is een fout.
func test_save_versions_and_migration(t) -> void:
	var data := _state().to_dict()
	data["version"] = SaveService.VERSION
	var errors := PackedStringArray()
	t.check(SaveService.migrate(data, errors) == data and errors.is_empty(), "huidige versie → zelfde verandert iets: %s" % errors)
	var future := data.duplicate(true)
	future["version"] = SaveService.VERSION + 1
	errors = PackedStringArray()
	t.check(SaveService.migrate(future, errors).is_empty() and errors[0].contains("versie %d" % (SaveService.VERSION + 1)),
		"nieuwere versie niet geweigerd: %s" % errors)
	data["version"] = 1
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
	data["version"] = SaveService.VERSION
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


func _write_text(path: String, text: String) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(text)
	file.close()


## SM-punt (#82): is de save kapot terwijl er een goede back-up is, dan
## vervangt de volgende save die back-up níét door het kapotte bestand. Is
## de vorige save goed, dan wordt die zoals altijd de back-up.
func test_save_broken_save_keeps_good_backup(t) -> void:
	_clear()
	var path := SaveService.slot_path(4, DIR)
	var a := _state()
	var b := _state()
	b.lichtmeter = 10
	var c := _state()
	c.lichtmeter = 20
	SaveService.write(path, a)
	SaveService.write(path, b)
	_write_text(path, "{\"version\": 1, \"gebied\": ")
	t.check(SaveService.write(path, c) == OK, "schrijven na een kapotte save mislukt")
	var now := SaveService.read(path)
	t.check(now["state"] != null and now["state"].equals(c) and not now["from_backup"], "nieuwe save niet geladen")
	var bak := SaveService.read(path + ".bak")
	t.check(bak["state"] != null and bak["state"].equals(a), "goede back-up vervangen: %s" % bak["errors"])
	SaveService.write(path, a)
	var rotated := SaveService.read(path + ".bak")
	t.check(rotated["state"] != null and rotated["state"].equals(c), "goede vorige save werd geen back-up")
	_clear()


## Crashpad: een crash laat een `.tmp` achter. (1) Na het schrijven van .tmp
## (half of heel): `read` negeert hem en geeft de save; de volgende save
## overschrijft hem en laat hem niet staan. (2) Na "save → .bak", vóór
## ".tmp → save": `read` geeft de back-up; de volgende save herstelt alles.
func test_save_crash_leaves_tmp(t) -> void:
	_clear()
	var path := SaveService.slot_path(5, DIR)
	var a := _state()
	var b := _state()
	b.lichtmeter = 10
	SaveService.write(path, a)
	_write_text(path + ".tmp", "{\"version\": 1, \"gebi")
	var one := SaveService.read(path)
	t.check(one["state"] != null and one["state"].equals(a) and not one["from_backup"], "(1) half .tmp stoorde het lezen")
	t.check(SaveService.write(path, b) == OK and not FileAccess.file_exists(path + ".tmp"), "(1) .tmp bleef staan")
	t.check(SaveService.read(path)["state"].equals(b), "(1) nieuwe save niet geladen na een oude .tmp")
	# (2) toestand na een crash tussen de twee hernoemingen.
	var dir := DirAccess.open(DIR)
	dir.remove(path + ".bak")
	dir.rename(path, path + ".bak")
	_write_text(path + ".tmp", "{\"version\": 1}")
	var two := SaveService.read(path)
	t.check(two["state"] != null and two["state"].equals(b) and two["from_backup"], "(2) back-up niet geladen")
	t.check(SaveService.write(path, a) == OK and not FileAccess.file_exists(path + ".tmp"), "(2) schrijven mislukt")
	t.check(SaveService.read(path)["state"].equals(a) and SaveService.read(path + ".bak")["state"].equals(b),
		"(2) na herstel klopt save of back-up niet")
	_clear()


## SM-punt (#82): `from_dict` controleert ook het bereik. Grenzen (0, 200:
## twee trappen, LM-08, #83) zijn goed; daarbuiten, of een breuk, of een vlag die geen bool is: null.
func test_save_from_dict_checks_range(t) -> void:
	var edge := _state().to_dict()
	edge["lichtmeter"] = 0
	edge["speeltijd_ticks"] = 0
	edge["gemalen"]["gemaal_k3"]["vulstand"] = 200
	var errors := PackedStringArray()
	t.check(GameState.from_dict(edge, errors) != null and errors.is_empty(), "grenswaarden geweigerd: %s" % errors)
	var cases := {
		"lichtmeter": func(d: Dictionary) -> void: d["lichtmeter"] = -1,
		"lichtmeter ": func(d: Dictionary) -> void: d["lichtmeter"] = 1.5,
		"speeltijd_ticks": func(d: Dictionary) -> void: d["speeltijd_ticks"] = -60,
		"vulstand": func(d: Dictionary) -> void: d["gemalen"]["gemaal_k3"]["vulstand"] = 201,
		"vulstand ": func(d: Dictionary) -> void: d["gemalen"]["gemaal_k3"]["vulstand"] = 37.5,
		"vlag": func(d: Dictionary) -> void: d["vlaggen"]["sluis_k3_open"] = "ja",
		"lichtmeter  ": func(d: Dictionary) -> void: d["lichtmeter"] = INF,
		"speeltijd_ticks ": func(d: Dictionary) -> void: d["speeltijd_ticks"] = 1e19,
	}
	# Zoals JSON het leest: "1e999" wordt INF (Godot meldt dan de
	# verwachte waarschuwing "Exponent too high"; een waarschuwing is geen FAIL).
	var json := JSON.new()
	json.parse(JSON.stringify(_state().to_dict()).replace("\"lichtmeter\":64", "\"lichtmeter\":1e999"))
	errors = PackedStringArray()
	t.check(typeof(json.data) == TYPE_DICTIONARY and GameState.from_dict(json.data, errors) == null
		and errors.size() == 1 and errors[0].contains("lichtmeter"), "lichtmeter 1e999 uit JSON niet geweigerd: %s" % errors)
	for name: String in cases:
		var data := _state().to_dict()
		(cases[name] as Callable).call(data)
		errors = PackedStringArray()
		t.check(GameState.from_dict(data, errors) == null and errors.size() == 1 and errors[0].contains(name.strip_edges()),
			"%s buiten bereik niet geweigerd: %s" % [name, errors])


## Een save van v1 zoals v1 hem schreef (zonder de velden van v2).
func _v1_text(gemalen: Dictionary) -> String:
	var data := _state().to_dict()
	for key in ["levenspunten", "waterstanden", "vaardigheden", "verzamelobjecten"]:
		data.erase(key)
	data["gemalen"] = gemalen
	data["vlaggen"]["kadewijk/S7/Neerslag"] = true
	data["version"] = 1
	return JSON.stringify(data, "\t", true, true)


## Schema v2 (LM-12): levenspunten, waterstand per wijk, vaardigheden en
## verzamelobjecten gaan exact heen en terug; de vaardigheden staan
## gesorteerd in het bestand; het maximum aan levenspunten volgt uit de
## lampglazen (LM-07, WS-08 a).
func test_save_v2_roundtrip(t) -> void:
	_clear()
	var path := SaveService.slot_path(6, DIR)
	var state := _state()
	state.levenspunten = 6
	state.set_gemaal(&"kadewijk/S6/Gemaal", 200, true)
	state.set_waterstand(&"kadewijk/S6/Gemaal", 2)
	state.set_vaardigheid(&"V-02")
	state.set_vaardigheid(&"V-01")
	state.add_verzamelobject(&"kadewijk/S5/Lampglas", &"lampglas")
	state.add_verzamelobject(&"kadewijk/S9/Logblad3", &"logbladzijde")
	t.check(state.max_levenspunten() == 6 and state.lampglazen() == 1, "max levenspunten: %d" % state.max_levenspunten())
	t.check(SaveService.write(path, state) == OK, "schrijven mislukt")
	var text := FileAccess.get_file_as_string(path)
	t.check(text.contains("\"version\": 2"), "geen versie 2 in het bestand")
	t.check(text.find("\"V-01\"") >= 0 and text.find("\"V-01\"") < text.find("\"V-02\""), "vaardigheden niet gesorteerd")
	var result := SaveService.read(path)
	var loaded: GameState = result["state"]
	t.check(loaded != null and loaded.equals(state), "v2 niet gelijk na laden: %s" % [result["errors"]])
	t.check(loaded != null and loaded.levenspunten == 6 and loaded.waterstand(&"kadewijk/S6/Gemaal") == 2
		and loaded.has_vaardigheid(&"V-01") and loaded.has_vaardigheid(&"V-02") and not loaded.has_vaardigheid(&"V-03")
		and loaded.has_verzamelobject(&"kadewijk/S5/Lampglas") and loaded.max_levenspunten() == 6,
		"velden van v2 niet terug")
	var fresh := GameState.new()
	t.check(fresh.levenspunten == GameState.start_levenspunten() and fresh.levenspunten == 5
		and fresh.max_levenspunten() == 5 and fresh.waterstand(&"x") == 0, "nieuw spel: %s" % [fresh.to_dict()])
	_clear()


## Migratie 1 → 2 (`builtin_migrations`): volle levenspunten, per gemaal `s`
## = het aantal volle trappen (LM-10, één gemaal per wijk), geen vaardigheden
## en geen verzamelobjecten; de rest (ook de vlag van een opgepakt object)
## blijft. De volgende save is v2 en laadt gelijk.
func test_save_migration_1_to_2(t) -> void:
	_clear()
	var path := SaveService.slot_path(7, DIR)
	DirAccess.make_dir_recursive_absolute(DIR)
	_write_text(path, _v1_text({
		"gemaal_k3": {"vulstand": 37, "vol": false},
		"wijk_b": {"vulstand": 100, "vol": true},
		"wijk_c": {"vulstand": 199, "vol": true},
		"kadewijk/S6/Gemaal": {"vulstand": 200, "vol": true},
	}))
	var result := SaveService.read(path)
	var loaded: GameState = result["state"]
	t.check(loaded != null and result["errors"].is_empty() and result["version"] == 1 and not result["from_backup"],
		"v1 laadt niet: %s" % [result["errors"]])
	if loaded == null:
		_clear()
		return
	t.check(loaded.levenspunten == 5, "levenspunten na migratie: %d" % loaded.levenspunten)
	t.check(loaded.waterstanden == {&"gemaal_k3": 0, &"wijk_b": 1, &"wijk_c": 1, &"kadewijk/S6/Gemaal": 2},
		"waterstanden na migratie: %s" % [loaded.waterstanden])
	t.check(loaded.vaardigheden.is_empty() and loaded.verzamelobjecten.is_empty(), "vaardigheden of verzamelobjecten na migratie")
	t.check(loaded.lichtmeter == 64 and loaded.checkpoint_kamer == &"K2" and loaded.has_flag(&"sluis_k3_open")
		and loaded.has_flag(&"kadewijk/S7/Neerslag") and loaded.gemalen[&"wijk_c"]["vulstand"] == 199,
		"v1-velden veranderd door de migratie")
	t.check(SaveService.write(path, loaded) == OK, "schrijven na migratie mislukt")
	t.check(FileAccess.get_file_as_string(path).contains("\"version\": 2"), "volgende save is geen v2")
	var again: GameState = SaveService.read(path)["state"]
	t.check(again != null and again.equals(loaded), "v2 na migratie niet gelijk")
	# Ook via een kapotte save: de back-up van v1 migreert.
	_write_text(path, "{\"version\": 2, \"gebi")
	_write_text(path + ".bak", _v1_text({"gemaal_k3": {"vulstand": 100, "vol": true}}))
	var backup := SaveService.read(path)
	t.check(backup["from_backup"] and backup["state"] != null and backup["state"].waterstand(&"gemaal_k3") == 1,
		"back-up van v1 niet gemigreerd: %s" % [backup["errors"]])
	# Een kapotte v1 blijft kapot: de migratie raadt niets.
	var bad: Dictionary = JSON.parse_string(_v1_text({"gemaal_k3": {"vulstand": -5, "vol": false}}))
	var errors := PackedStringArray()
	var migrated := SaveService.migrate(bad, errors)
	t.check(errors.is_empty() and not migrated["waterstanden"].has("gemaal_k3")
		and GameState.from_dict(migrated, errors) == null and errors.size() == 1 and errors[0].contains("vulstand"),
		"kapotte v1 na migratie: %s" % errors)
	_clear()


## De controles van v2 in `from_dict`: grenzen zijn goed; daarbuiten precies
## één fout met de naam van het veld, en geen toestand.
func test_save_v2_from_dict_checks(t) -> void:
	var base := _state()
	base.set_gemaal(&"kadewijk/S6/Gemaal", 150, true)
	base.set_waterstand(&"kadewijk/S6/Gemaal", 1)
	base.set_vaardigheid(&"V-01")
	base.add_verzamelobject(&"a/S1/Lampglas", &"lampglas")
	var edge := base.to_dict()
	edge["levenspunten"] = 9
	edge["waterstanden"]["wijk_zonder_gemaal"] = 2
	for i in 3:
		edge["verzamelobjecten"]["g%d/Lampglas" % i] = "lampglas"
	var errors := PackedStringArray()
	t.check(GameState.from_dict(edge, errors) != null and errors.is_empty(), "grenzen v2 geweigerd: %s" % errors)
	edge["levenspunten"] = 0
	errors = PackedStringArray()
	t.check(GameState.from_dict(edge, errors) != null, "levenspunten 0 geweigerd: %s" % errors)
	var cases := {
		"levenspunten": func(d: Dictionary) -> void: d["levenspunten"] = 10,
		"levenspunten ": func(d: Dictionary) -> void: d["levenspunten"] = -1,
		"levenspunten  ": func(d: Dictionary) -> void: d["levenspunten"] = 2.5,
		"waterstanden.wijk_x": func(d: Dictionary) -> void: d["waterstanden"]["wijk_x"] = 3,
		"waterstand 'wijk_y'": func(d: Dictionary) -> void: d["waterstanden"]["wijk_y"] = "1",
		"trap": func(d: Dictionary) -> void: d["waterstanden"]["kadewijk/S6/Gemaal"] = 2,
		"vaardigheid 'Neerslag'": func(d: Dictionary) -> void: d["vaardigheden"] = ["Neerslag"],
		"vaardigheid 'V--1'": func(d: Dictionary) -> void: d["vaardigheden"] = ["V--1"],
		"twee keer": func(d: Dictionary) -> void: d["vaardigheden"] = ["V-01", "V-01"],
		"vaardigheid '1'": func(d: Dictionary) -> void: d["vaardigheden"] = [1],
		"verzamelobject 'x'": func(d: Dictionary) -> void: d["verzamelobjecten"]["x"] = "munt",
		"lampglazen": func(d: Dictionary) -> void: d["verzamelobjecten"].merge(
			{"g0/L": "lampglas", "g1/L": "lampglas", "g2/L": "lampglas", "g3/L": "lampglas"}),
		"'vaardigheden'": func(d: Dictionary) -> void: d["vaardigheden"] = {"V-01": true},
		"'verzamelobjecten' ontbreekt": func(d: Dictionary) -> void: d.erase("verzamelobjecten"),
	}
	for name: String in cases:
		var data := base.to_dict()
		(cases[name] as Callable).call(data)
		errors = PackedStringArray()
		t.check(GameState.from_dict(data, errors) == null and errors.size() == 1 and errors[0].contains(name.strip_edges()),
			"%s niet geweigerd: %s" % [name, errors])
