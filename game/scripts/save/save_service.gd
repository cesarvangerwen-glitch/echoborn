extends RefCounted
## Opslaan en laden (T5b, #82; ontwerp.md §7). Statisch, zonder toestand:
## de autoload `SaveService` uit de doelstructuur (§3) wordt een dunne laag
## hierover zodra het spel menu's en slots heeft.
##
## - Eén JSON-bestand per slot: `user://saves/slot_<n>.json`, met `version`.
##   `user://` is de map die Steam Cloud synchroniseert.
## - Schrijven is atomair: eerst `<pad>.tmp`, dan wordt de vorige save
##   `<pad>.bak`, dan wordt `.tmp` de save. Een crash halverwege laat altijd
##   een leesbare save of back-up achter; `read` valt terug op `.bak`.
## - Oudere versies gaan stap voor stap door `migrate` (versie n → n + 1).
##   Een save van een nieuwere versie wordt geweigerd, nooit half gelezen.
## - Deterministisch: gesorteerde sleutels, getallen op volle precisie, geen
##   klokuren in de inhoud.

const GameState = preload("res://scripts/save/game_state.gd")

## Huidige versie van het schema.
const VERSION := 1
const DEFAULT_DIR := "user://saves"


## Migraties: {van_versie: Callable(data: Dictionary) -> Dictionary}, die
## versie n naar n + 1 brengen. Nog leeg: v1 is de eerste versie. Een nieuwe
## versie voegt hier een regel toe en verhoogt VERSION. `read` en `migrate`
## nemen ook een eigen tabel aan (tests); leeg = deze.
static func builtin_migrations() -> Dictionary:
	return {}


static func slot_path(slot: int, dir: String = DEFAULT_DIR) -> String:
	return "%s/slot_%d.json" % [dir, slot]


## Schrijft `state` naar `path`. Geeft OK of de fout van de eerste stap die
## mislukte; bij een fout blijft de vorige save staan.
static func write(path: String, state: GameState) -> Error:
	var dir_path := path.get_base_dir()
	var made := DirAccess.make_dir_recursive_absolute(dir_path)
	if made != OK:
		return made
	var data := state.to_dict()
	data["version"] = VERSION
	var text := JSON.stringify(data, "\t", true, true)
	var tmp := path + ".tmp"
	var file := FileAccess.open(tmp, FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	file.store_string(text)
	file.flush()
	var write_error := file.get_error()
	file.close()
	if write_error != OK:
		return write_error
	var dir := DirAccess.open(dir_path)
	if dir == null:
		return DirAccess.get_open_error()
	var bak := path + ".bak"
	if FileAccess.file_exists(path):
		if FileAccess.file_exists(bak):
			var removed := dir.remove(bak)
			if removed != OK:
				return removed
		var kept := dir.rename(path, bak)
		if kept != OK:
			return kept
	return dir.rename(tmp, path)


## Leest een save. Resultaat: {"state": GameState of null, "errors":
## PackedStringArray, "from_backup": bool, "version": int (gelezen versie)}.
## Mislukt de save zelf, dan probeert hij `<pad>.bak`.
static func read(path: String, migrations: Dictionary = {}, target: int = VERSION) -> Dictionary:
	var result := _read_one(path, migrations, target)
	if result["state"] == null and FileAccess.file_exists(path + ".bak"):
		var backup := _read_one(path + ".bak", migrations, target)
		if backup["state"] != null:
			backup["from_backup"] = true
			backup["errors"] = result["errors"]
			return backup
	return result


## Brengt `data` van zijn versie naar `target`. Fouten komen in `errors`;
## het antwoord is dan een lege Dictionary.
static func migrate(data: Dictionary, errors: PackedStringArray,
		migrations: Dictionary = {}, target: int = VERSION) -> Dictionary:
	var version_value: Variant = data.get("version")
	if typeof(version_value) != TYPE_INT and typeof(version_value) != TYPE_FLOAT:
		errors.append("geen versie in de save")
		return {}
	var version := int(version_value)
	if version > target:
		errors.append("save is van versie %d, dit spel kent tot %d" % [version, target])
		return {}
	if version < 1:
		errors.append("onbekende versie %d" % version)
		return {}
	var table := migrations if not migrations.is_empty() else builtin_migrations()
	var current := data.duplicate(true)
	while version < target:
		if not table.has(version):
			errors.append("geen migratie van versie %d naar %d" % [version, version + 1])
			return {}
		current = (table[version] as Callable).call(current)
		version += 1
		current["version"] = version
	return current


static func _read_one(path: String, migrations: Dictionary, target: int) -> Dictionary:
	var result := {"state": null, "errors": PackedStringArray(), "from_backup": false, "version": 0}
	var errors: PackedStringArray = result["errors"]
	if not FileAccess.file_exists(path):
		errors.append("geen save op %s" % path)
		return result
	var text := FileAccess.get_file_as_string(path)
	var json := JSON.new()
	if json.parse(text) != OK or typeof(json.data) != TYPE_DICTIONARY:
		errors.append("%s is geen geldige JSON (regel %d: %s)" % [
			path, json.get_error_line(), json.get_error_message()])
		return result
	var data: Dictionary = json.data
	result["version"] = int(data.get("version", 0))
	var current := migrate(data, errors, migrations, target)
	if not errors.is_empty():
		return result
	result["state"] = GameState.from_dict(current, errors)
	return result
