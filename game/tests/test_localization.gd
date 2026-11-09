extends RefCounted
## Tests voor de lokalisatie (T14, #74; `docs/tech/ontwerp.md` §8a): het CSV-bestand
## is geldig, elke sleutel uit code en scènes bestaat, er staat geen harde
## spelerstekst in code, en de taal wisselt.

const Localization = preload("res://scripts/locale/localization.gd")
const TextLint = preload("res://tests/text_lint.gd")


## Het CSV-bestand laadt zonder fouten, met een kolom per taal en Engels bij elke sleutel.
func test_csv_loads_with_english_for_every_key(t) -> void:
	var result := Localization.load_csv(Localization.CSV_PATH)
	t.check(result["errors"].is_empty(), "fouten in strings.csv: %s" % ", ".join(result["errors"]))
	t.check(result["keys"].has("GAME_TITLE"), "sleutel GAME_TITLE ontbreekt")
	var locales := PackedStringArray()
	for translation: Translation in result["translations"]:
		locales.append(translation.locale)
	for locale: String in Localization.LOCALES:
		t.check(locales.has(locale), "geen kolom voor taal %s" % locale)
	var missing_nl := PackedStringArray()
	for translation: Translation in result["translations"]:
		if translation.locale == "nl":
			for key: String in result["keys"]:
				if translation.get_message(key) == &"":
					missing_nl.append(key)
	if not missing_nl.is_empty():
		t.note("nog zonder NL (valt terug op EN, vertaling in fase 4): %s" % ", ".join(missing_nl))


## Elke sleutel die code of een scène gebruikt, staat in strings.csv.
func test_every_key_in_code_exists(t) -> void:
	var known: PackedStringArray = Localization.load_csv(Localization.CSV_PATH)["keys"]
	var used: Dictionary = TextLint.new().scan_project()["keys"]
	t.check(used.size() > 0, "geen enkele tr()-sleutel gevonden; scant de lint wel?")
	for key: String in used:
		t.check(known.has(key), "sleutel %s (in %s) ontbreekt in strings.csv" % [key, used[key]])
	var unused := PackedStringArray()
	for key in known:
		if not used.has(key):
			unused.append(key)
	if not unused.is_empty():
		t.note("niet gebruikt in code: %s" % ", ".join(unused))


## Geen harde spelerstekst in scripts/, scenes/ en levels/ (ontwerp.md §8a).
func test_no_hard_text_in_code(t) -> void:
	var violations: PackedStringArray = TextLint.new().scan_project()["violations"]
	t.check(violations.is_empty(), "harde tekst gevonden:\n       %s" % "\n       ".join(violations))


## De lint zelf: vangt harde tekst in een tekstveld, in een opgebouwde regel en in
## een scène, en laat sleutels, logregels, node-namen en ids met rust.
func test_lint_catches_hard_text(t) -> void:
	var lint := TextLint.new()
	var bad := lint.scan_source("\n".join([
		"\tlabel.text = \"Start\"",
		"\tlines.append(\"Druk op een knop %d\" % n)",
		"\ttr(\"Start het spel\")",
		"\tbutton.set_text('Doorgaan')",
	]))
	t.check(bad["violations"].size() == 4, "verwacht 4 overtredingen, kreeg %d: %s" % [
		bad["violations"].size(), ", ".join(bad["violations"])])
	var good := lint.scan_source("\n".join([
		"\tlabel.text = tr(\"MENU_START\")",
		"\tlines.append(tr(\"HUD_ROOM\") % [room, tail])  # \"Kamer en staart\"",
		"\tpush_error(\"Tuning: groep ontbreekt in %s\" % PATH)",
		"\terrors.append(\"veld '%s' ontbreekt\" % key)",
		"\tnode.name = \"Achtergrond\" + key",
		"\tvar id := &\"sluis k3\"",
		"\tlabel.text = \"\"",
	]))
	t.check(good["violations"].is_empty(), "onterecht gevonden: %s" % ", ".join(good["violations"]))
	t.check(good["keys"] == PackedStringArray(["MENU_START", "HUD_ROOM"]), "sleutels: %s" % good["keys"])
	var scene := lint.scan_scene("[node name=\"Knop\" type=\"Button\"]\ntext = \"Start\"\n" +
		"[node name=\"Titel\" type=\"Label\"]\ntext = \"GAME_TITLE\"\n")
	t.check(scene["violations"].size() == 1 and scene["keys"] == PackedStringArray(["GAME_TITLE"]),
		"scène: %s / %s" % [scene["violations"], scene["keys"]])


## Taalkeuze: `--lang=` gaat voor, dan de systeemtaal, anders Engels.
func test_pick_locale(t) -> void:
	t.check(Localization.pick_locale("nl_BE", PackedStringArray()) == "nl", "nl_BE geeft nl")
	t.check(Localization.pick_locale("nl-NL", PackedStringArray()) == "nl", "nl-NL geeft nl")
	t.check(Localization.pick_locale("fr_BE", PackedStringArray()) == "en", "fr_BE geeft en")
	t.check(Localization.pick_locale("nl_BE", PackedStringArray(["--lang=en"])) == "en", "--lang=en wint")
	t.check(Localization.pick_locale("en_US", PackedStringArray(["--lang=NL"])) == "nl", "--lang=NL geeft nl")
	t.check(Localization.pick_locale("en_US", PackedStringArray(["--lang=de"])) == "en", "onbekende taal")


## De autoload laadt de vertalingen; wisselen van taal wisselt de tekst, en een
## onbekende taal verandert niets.
func test_switching_language_changes_text(t) -> void:
	var loc: Node = t.tree.root.get_node_or_null("Localization")
	t.check(loc != null, "autoload Localization ontbreekt")
	if loc == null:
		return
	var before: String = loc.language()
	t.check(loc.set_language("nl"), "nl is een taal van het spel")
	t.check(TranslationServer.translate("HUD_ECHO_EMPTY") == "Leeg", "nl: HUD_ECHO_EMPTY = Leeg")
	t.check(loc.set_language("en"), "en is een taal van het spel")
	t.check(TranslationServer.translate("HUD_ECHO_EMPTY") == "Empty", "en: HUD_ECHO_EMPTY = Empty")
	t.check(TranslationServer.translate("GAME_TITLE") == "Polderlight", "titel is de werktitel")
	t.check(not loc.set_language("de"), "de is geen taal van het spel")
	t.check(loc.language() == "en", "onbekende taal laat de taal ongemoeid")
	loc.set_language(before)
