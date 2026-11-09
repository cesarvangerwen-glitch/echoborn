extends Node
## Laadt de vertaalbestanden en kiest de taal (T14, #74). Autoload `Localization`.
##
## Alle spelerszichtbare tekst staat als sleutel in `res://locale/strings.csv`; code
## gebruikt `tr("SLEUTEL")`. Regels en werkaannames: `docs/tech/ontwerp.md` §8a.

## Brontaal: elke sleutel heeft een Engelse tekst; NL komt erbij (#51 deel 1: 5A).
const SOURCE_LOCALE := "en"
## Talen die het spel aanbiedt (NL in principe ja, #51: 5A).
const LOCALES := ["en", "nl"]
const CSV_PATH := "res://locale/strings.csv"
## Taal kiezen bij het starten, na `--`: `godot --path game -- --lang=nl`.
const LANG_ARG := "--lang="
## Een geldige sleutel: hoofdletters, cijfers en `_`, begint met een letter.
const KEY_PATTERN := "^[A-Z][A-Z0-9_]*$"

## Fouten bij het laden van het CSV-bestand; leeg = in orde.
var load_errors := PackedStringArray()
var _translations: Array[Translation] = []


func _ready() -> void:
	var result := load_csv(CSV_PATH)
	load_errors = result["errors"]
	for error in load_errors:
		push_error("Localization: %s" % error)
	for translation: Translation in result["translations"]:
		TranslationServer.add_translation(translation)
		_translations.append(translation)
	set_language(pick_locale(OS.get_locale(), OS.get_cmdline_user_args()))


func _exit_tree() -> void:
	for translation in _translations:
		TranslationServer.remove_translation(translation)
	_translations.clear()


## Zet de taal van het spel. Geeft false bij een taal die het spel niet kent.
## Bewaren van de keuze volgt met het optiemenu (`ontwerp.md` §8a, open punten).
func set_language(locale: String) -> bool:
	if not LOCALES.has(locale):
		return false
	TranslationServer.set_locale(locale)
	if is_inside_tree():
		get_window().title = tr("GAME_TITLE")
	return true


func language() -> String:
	return TranslationServer.get_locale().get_slice("_", 0)


## Kiest de taal: eerst `--lang=xx` na `--`, dan de taal van het systeem
## (`nl_BE` en `nl_NL` geven `nl`), anders de brontaal.
static func pick_locale(os_locale: String, user_args: PackedStringArray) -> String:
	for arg in user_args:
		if arg.begins_with(LANG_ARG):
			var wanted := arg.trim_prefix(LANG_ARG).to_lower()
			if LOCALES.has(wanted):
				return wanted
	var system := os_locale.get_slice("_", 0).get_slice("-", 0).to_lower()
	return system if LOCALES.has(system) else SOURCE_LOCALE


## Leest het CSV-bestand (`keys,en,nl,…`; kolommen die met `_` beginnen zijn
## notities) en geeft {translations, keys, errors}. Een lege cel krijgt geen
## vertaling, zodat de TranslationServer terugvalt op de brontaal.
static func load_csv(path: String) -> Dictionary:
	var errors := PackedStringArray()
	var keys := PackedStringArray()
	var by_locale: Dictionary = {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		errors.append("%s niet te openen (%s)" % [path, error_string(FileAccess.get_open_error())])
		return {"translations": [], "keys": keys, "errors": errors}
	var header := file.get_csv_line()
	var columns: Dictionary = {}
	for i in range(1, header.size()):
		var locale := header[i].strip_edges()
		if locale.begins_with("_") or locale.is_empty():
			continue
		if not LOCALES.has(locale):
			errors.append("kolom '%s' is geen taal uit LOCALES" % locale)
			continue
		columns[i] = locale
		var translation := Translation.new()
		translation.locale = locale
		by_locale[locale] = translation
	if header.is_empty() or header[0] != "keys" or not by_locale.has(SOURCE_LOCALE):
		errors.append("kop moet 'keys,%s,…' zijn" % SOURCE_LOCALE)
	var key_regex := RegEx.create_from_string(KEY_PATTERN)
	var line := 1
	while not file.eof_reached():
		var row := file.get_csv_line()
		line += 1
		if row.size() == 1 and row[0].strip_edges().is_empty():
			continue
		var key := row[0].strip_edges()
		if key_regex.search(key) == null:
			errors.append("regel %d: '%s' is geen geldige sleutel" % [line, key])
			continue
		if keys.has(key):
			errors.append("regel %d: sleutel %s staat er twee keer in" % [line, key])
			continue
		keys.append(key)
		for i: int in columns:
			var text := row[i] if i < row.size() else ""
			if text.is_empty():
				if columns[i] == SOURCE_LOCALE:
					errors.append("regel %d: %s heeft geen Engelse tekst" % [line, key])
				continue
			by_locale[columns[i]].add_message(key, text)
	var translations: Array[Translation] = []
	for locale: String in by_locale:
		translations.append(by_locale[locale])
	return {"translations": translations, "keys": keys, "errors": errors}
