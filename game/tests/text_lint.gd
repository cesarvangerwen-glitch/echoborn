extends RefCounted
## Zoekt harde spelerstekst in code en scènes (T14, #74; `docs/tech/ontwerp.md` §8a).
##
## Hulp voor `test_localization.gd`: geeft overtredingen en de gebruikte sleutels terug.

const Localization = preload("res://scripts/locale/localization.gd")

## Mappen met code en scènes die de speler kan zien.
const SCAN_DIRS := ["res://scripts", "res://scenes", "res://levels"]
## Ontwikkelaarsschermen en meetscènes: geen speltekst, dus niet gecontroleerd.
const EXEMPT_DIRS := ["res://scenes/debug", "res://prototypes"]
## Bestanden met alleen ontwikkelaarstekst, elk met de reden.
const EXEMPT_FILES := {
	"res://levels/flowkamer/flow_report.gd": "meetrapport voor QA (T17), geen speltekst",
	"res://scripts/input/input_router.gd": "redenen bij slot_left, alleen in het debugscherm",
}
## Regels die ontwikkelaarstekst schrijven (log, fout, validatie): niet vertalen.
const DEV_CALLS := ["print(", "printerr(", "print_rich(", "print_debug(", "push_error(",
	"push_warning(", "assert(", "errors.append("]
## Tekst rechtstreeks in een tekstveld of venstertitel.
const UI_PATTERN := "(\\.(text|tooltip_text|placeholder_text|title)\\s*[+]?=\\s*|" + \
	"(set_text|append_text|add_text|set_tooltip_text|window_set_title)\\(\\s*)[\"']"
## Sleutel na tr(), tr_n() of TranslationServer.translate().
const KEY_CALL_PATTERN := "\\b(tr|tr_n|translate)\\(\\s*$"
## Tekstvelden in een .tscn: de waarde moet een sleutel zijn.
const TSCN_PATTERN := "^(text|tooltip_text|placeholder_text|title) = \"(.*)\"$"
## Een woord: alleen letters, eventueel met leestekens eromheen. Twee woorden met
## een spatie ertussen = natuurlijke taal; `tail_ticks` of een pad is dat niet.
const WORD_PATTERN := "^[(\"'«]*[A-Za-zÀ-ÿ][A-Za-zÀ-ÿ'’-]+[.,:;!?)»]*$"
const LETTER_PATTERN := "[A-Za-zÀ-ÿ]"

var _ui := RegEx.create_from_string(UI_PATTERN)
var _key_call := RegEx.create_from_string(KEY_CALL_PATTERN)
var _tscn := RegEx.create_from_string(TSCN_PATTERN)
var _key := RegEx.create_from_string(Localization.KEY_PATTERN)
var _word := RegEx.create_from_string(WORD_PATTERN)
var _letter := RegEx.create_from_string(LETTER_PATTERN)
var _format := RegEx.create_from_string("%[-+0-9.]*[a-zA-Z%]")


## Controleert alle bestanden onder SCAN_DIRS. Geeft {violations, keys}.
func scan_project() -> Dictionary:
	var violations := PackedStringArray()
	var keys: Dictionary = {}
	for dir: String in SCAN_DIRS:
		for path in _collect(dir):
			var source := FileAccess.get_file_as_string(path)
			var result := scan_scene(source) if path.ends_with(".tscn") else scan_source(source)
			for v: String in result["violations"]:
				violations.append("%s:%s" % [path, v])
			for key: String in result["keys"]:
				keys[key] = path
	return {"violations": violations, "keys": keys}


## Controleert één GDScript-bron. Geeft {violations: ["regel: uitleg"], keys}.
func scan_source(source: String) -> Dictionary:
	var violations := PackedStringArray()
	var keys := PackedStringArray()
	var lines := source.split("\n")
	for n in lines.size():
		var line := lines[n]
		var literals := _literals(line)
		if literals.is_empty():
			continue
		var code := line.substr(0, literals[-1]["end"])
		var dev := DEV_CALLS.any(func(c: String) -> bool: return code.contains(c))
		var first_ui := _ui.search(code)
		if first_ui != null:
			for lit: Dictionary in literals:
				var shown := String(lit["text"]).c_unescape()
				if lit["start"] == first_ui.get_end() - 1 and _letter.search(shown) != null:
					violations.append("%d: tekst rechtstreeks in een tekstveld: \"%s\"" % [n + 1, lit["text"]])
		for lit: Dictionary in literals:
			var text: String = lit["text"]
			if _key_call.search(line.substr(0, lit["start"])) != null:
				if _key.search(text) == null:
					violations.append("%d: tr() krijgt een sleutel, geen tekst: \"%s\"" % [n + 1, text])
				else:
					keys.append(text)
				continue
			if dev:
				continue
			if _word_count(text) >= 2:
				violations.append("%d: harde tekst, gebruik tr(\"SLEUTEL\"): \"%s\"" % [n + 1, text])
	return {"violations": violations, "keys": keys}


## Controleert één scène: tekstvelden bevatten alleen een sleutel (Godot vertaalt
## die zelf, auto_translate). Geeft {violations, keys}.
func scan_scene(source: String) -> Dictionary:
	var violations := PackedStringArray()
	var keys := PackedStringArray()
	var lines := source.split("\n")
	for n in lines.size():
		var m := _tscn.search(lines[n])
		if m == null or m.get_string(2).is_empty():
			continue
		if _key.search(m.get_string(2)) == null:
			violations.append("%d: %s is geen sleutel: \"%s\"" % [n + 1, m.get_string(1), m.get_string(2)])
		else:
			keys.append(m.get_string(2))
	return {"violations": violations, "keys": keys}


## Aantal woorden in een tekst, zonder opmaakcodes als `%d`.
func _word_count(text: String) -> int:
	var count := 0
	for token in _format.sub(text, " ", true).split(" ", false):
		if _word.search(token.strip_edges()) != null:
			count += 1
	return count


## Stringliteralen in één regel, zonder commentaar: [{text, start, end}].
## `&"naam"` (StringName) en `^"pad"` (NodePath) zijn geen tekst.
func _literals(line: String) -> Array:
	var out: Array = []
	var i := 0
	while i < line.length():
		var c := line[i]
		if c == "#":
			break
		if c == "\"" or c == "'":
			var start := i
			var j := i + 1
			while j < line.length() and line[j] != c:
				j += 2 if line[j] == "\\" else 1
			var prefix := line[start - 1] if start > 0 else ""
			if prefix != "&" and prefix != "^":
				out.append({"text": line.substr(start + 1, j - start - 1), "start": start, "end": j + 1})
			i = j + 1
			continue
		i += 1
	return out


func _collect(dir: String) -> PackedStringArray:
	var out := PackedStringArray()
	if EXEMPT_DIRS.has(dir):
		return out
	for sub in DirAccess.get_directories_at(dir):
		out.append_array(_collect(dir.path_join(sub)))
	for file in DirAccess.get_files_at(dir):
		var path := dir.path_join(file)
		if (file.ends_with(".gd") or file.ends_with(".tscn")) and not EXEMPT_FILES.has(path):
			out.append(path)
	out.sort()
	return out
