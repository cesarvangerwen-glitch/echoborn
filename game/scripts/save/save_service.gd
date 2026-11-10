extends Node
## Opslaan en laden (T5b, #82; ontwerp.md §7), in twee lagen:
##
## - **Statisch** (`write`, `read`, `migrate`): bestanden, versies en
##   migratie, zonder toestand. Tests en tools gebruiken die via `preload`.
## - **Autoload `SaveService`** (deel 3a): slots, de stand van een slot voor
##   het menu (`slot_info`), laden en nieuw spel, en de autosave bij een
##   checkpoint (`Progress.checkpoint_reached`) en bij afsluiten. Vlak vóór
##   elke save schrijft `Progress.store_world()` de stand van de wereld weg
##   (`AreaLoader.store_objects`, lichtmeter, gemalen).
##
## - Eén JSON-bestand per slot: `user://saves/slot_<n>.json`, met `version`.
##   `user://` is de map die Steam Cloud synchroniseert.
## - Schrijven is atomair: eerst `<pad>.tmp`, dan wordt de vorige save
##   `<pad>.bak`, dan wordt `.tmp` de save. Een crash halverwege laat altijd
##   een leesbare save of back-up achter; `read` valt terug op `.bak`. Is de
##   vorige save zelf kapot, dan blijft de bestaande `.bak` staan (een
##   kapotte save vervangt nooit een goede back-up).
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
	if FileAccess.file_exists(path) and FileAccess.file_exists(bak) and not _is_good(path):
		# De vorige save is kapot: weg ermee, de goede back-up blijft.
		var dropped := dir.remove(path)
		if dropped != OK:
			return dropped
	elif FileAccess.file_exists(path):
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


## Is de save op `path` leesbaar tot een GameState (met de vaste migraties)?
## Een save van een nieuwere versie telt als goed: die gooien we niet weg.
static func _is_good(path: String) -> bool:
	var result := _read_one(path, {}, VERSION)
	return result["state"] != null or int(result["version"]) > VERSION


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


# --- Autoload: slots en autosave (T5b deel 3a) ---

## Wat een slot is, voor het menu (ontwerp.md §7, "Slots en autosave"):
## - LEEG: geen save en geen back-up. Menu: "nieuw spel".
## - OK: de save laadt.
## - HERSTELD: de save is kapot, de back-up laadt. Menu: gewoon laden; het
##   spel meldt één keer dat de laatste voortgang (sinds het vorige
##   checkpoint) verloren is. De volgende save herstelt het slot.
## - KAPOT: save én back-up kapot (of alleen een kapotte save). Menu: het
##   slot is "beschadigd" en laadt niet; alleen "nieuw spel in dit slot",
##   en dan worden de bestanden opzijgezet (`.kapot`), niet gewist.
## - NIEUWER: een save van een nieuwere versie van het spel. Menu: "kan niet
##   laden: nieuwere versie"; nieuw spel zet de bestanden ook opzij.
## De teksten zelf zijn voor de UX Designer en UI (T10), via Localization.
enum SlotStatus { LEEG, OK, HERSTELD, KAPOT, NIEUWER }

## Aantal slots in het menu (werkaanname, UX Designer T10 kan het wijzigen).
const SLOT_COUNT := 3
## Achtervoegsel voor opzijgezette bestanden van een kapot slot.
const SET_ASIDE := ".kapot"

## Na elke poging tot opslaan: `reason` is "checkpoint", "afsluiten", "nieuw_spel" of
## "handmatig"; `error` OK of de fout (de vorige save blijft dan staan).
signal saved(slot: int, reason: String, error: Error)

## De map met de slots. Een test zet een eigen map.
var dir := DEFAULT_DIR
## De autoload `Progress`; gezet in `_ready` of met `use`.
var progress: Node = null


func _ready() -> void:
	if progress == null:
		var node := get_node_or_null(^"/root/Progress")
		if node != null:
			use(node)


## Koppelt aan een `Progress`-node (de autoload, of een eigen in een test).
func use(p_progress: Node) -> void:
	if progress != null and progress.checkpoint_reached.is_connected(_on_checkpoint_reached):
		progress.checkpoint_reached.disconnect(_on_checkpoint_reached)
	progress = p_progress
	progress.checkpoint_reached.connect(_on_checkpoint_reached)


func path_of(slot: int) -> String:
	return slot_path(slot, dir)


## De stand van een slot voor het menu, zonder iets te veranderen:
## {"status": SlotStatus, "state": GameState of null, "errors":
## PackedStringArray}. Bij HERSTELD staan de fouten van de save zelf in
## `errors`.
func slot_info(slot: int) -> Dictionary:
	var path := path_of(slot)
	var result := read(path)
	var info := {"status": SlotStatus.OK, "state": result["state"], "errors": result["errors"]}
	if result["state"] != null:
		info["status"] = SlotStatus.HERSTELD if result["from_backup"] else SlotStatus.OK
	elif not FileAccess.file_exists(path) and not FileAccess.file_exists(path + ".bak"):
		info["status"] = SlotStatus.LEEG
	elif int(result["version"]) > VERSION:
		info["status"] = SlotStatus.NIEUWER
	else:
		info["status"] = SlotStatus.KAPOT
	return info


## Laadt een slot in `progress` als het OK of HERSTELD is; geeft
## `slot_info`. Bij LEEG, KAPOT of NIEUWER verandert er niets.
func load_slot(slot: int) -> Dictionary:
	var info := slot_info(slot)
	if info["status"] == SlotStatus.OK or info["status"] == SlotStatus.HERSTELD:
		progress.adopt(info["state"], slot)
	return info


## Begint een nieuw spel in `slot` en schrijft het meteen weg. Een kapot
## slot of een save van een nieuwere versie wordt eerst opzijgezet
## (`<pad>.kapot`, `<pad>.bak.kapot`; een vorige `.kapot` gaat weg). Een
## goede save in het slot wordt gewist: het menu vraagt dat eerst.
func new_game(slot: int, p_state: GameState = null) -> Error:
	var status: int = slot_info(slot)["status"]
	var path := path_of(slot)
	for file in [path, path + ".bak", path + ".tmp"]:
		if not FileAccess.file_exists(file):
			continue
		var err: Error
		if (status == SlotStatus.KAPOT or status == SlotStatus.NIEUWER) and not file.ends_with(".tmp"):
			if FileAccess.file_exists(file + SET_ASIDE):
				DirAccess.remove_absolute(file + SET_ASIDE)
			err = DirAccess.rename_absolute(file, file + SET_ASIDE)
		else:
			err = DirAccess.remove_absolute(file)
		if err != OK:
			return err
	progress.adopt(p_state, slot)
	return save_now("nieuw_spel")


## Slaat het lopende spel op in zijn slot, met `store_world` vlak ervoor.
## Zonder lopend spel (slot -1): ERR_UNCONFIGURED, en er wordt niets
## geschreven.
func save_now(reason: String = "handmatig") -> Error:
	if progress == null or progress.slot < 0:
		return ERR_UNCONFIGURED
	progress.store_world()
	var err := write(path_of(progress.slot), progress.state)
	if err != OK:
		push_error("SaveService: opslaan in slot %d mislukt (%s): %s" % [progress.slot, reason, error_string(err)])
	saved.emit(progress.slot, reason, err)
	return err


func _on_checkpoint_reached(_kamer: StringName, _positie: Vector2) -> void:
	save_now("checkpoint")


## Autosave bij afsluiten (LM-12). Het checkpoint blijft het laatste
## checkpoint: na laden sta je daar, met de stand van de wereld van nu.
func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		save_now("afsluiten")
