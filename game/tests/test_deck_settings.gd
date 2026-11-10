extends RefCounted
## Tests voor de Deck-instellingen (T7, #79; `docs/tech/performance-flowkamer.md` §3):
## met de feature `deck` rendert de wereld op 640×400 in een venster van
## 1280×800. Zet iemand dit terug naar native 1280×800, dan geldt het
## lichtbudget van #21 niet meer en wordt deze test rood.

const PROJECT := "res://project.godot"

## Verwachte `.deck`-waarden in `[display]`.
const DECK := {
	"window/size/viewport_width.deck": 640,
	"window/size/viewport_height.deck": 400,
	"window/size/window_width_override.deck": 1280,
	"window/size/window_height_override.deck": 800,
	"window/stretch/mode.deck": "viewport",
	"window/size/mode.deck": 3,
	"window/vsync/vsync_mode.deck": 1,
}


## `project.godot` bevat de Deck-waarden voor 640×400, ×2 opgeschaald naar 1280×800.
func test_deck_renders_640x400_in_1280x800(t) -> void:
	var cfg := ConfigFile.new()
	var err := cfg.load(PROJECT)
	t.check(err == OK, "project.godot laadt niet (fout %d)" % err)
	for key: String in DECK:
		t.check(cfg.has_section_key("display", key), "[display] %s ontbreekt" % key)
		var got = cfg.get_value("display", key, null)
		t.check(got == DECK[key], "[display] %s = %s, verwacht %s" % [key, got, DECK[key]])


## Zonder feature `deck` (editor, pc, tests) blijft het 1280×720 zonder stretch.
func test_without_deck_feature_stays_1280x720(t) -> void:
	t.check(not OS.has_feature("deck"), "feature deck is actief in de tests")
	t.check(ProjectSettings.get_setting("display/window/size/viewport_width") == 1280, "viewport_width is niet 1280")
	t.check(ProjectSettings.get_setting("display/window/size/viewport_height") == 720, "viewport_height is niet 720")
	t.check(ProjectSettings.get_setting("display/window/stretch/mode") == "disabled", "stretch/mode is niet disabled")
