extends "res://scripts/audio/sim_sfx.gd"
## De pompslag van een gemaal (#243; audio bible v0.5 §4.1, §10): een echo-actie
## met gewicht. Hangt onder het `Gemaal` (`gemaal.gd` maakt hem aan) en start
## op `pumped(tick, amount, who)` de pompslag als `AudioStreamPlayer2D` op de
## geraakte schoep (`gemaal.last_vane`), max. 3 tegelijk.
##
## Voor P1, P2 en de echo **hetzelfde** `stream`-object, dezelfde `volume_db`,
## dezelfde bus (`SFX`, niet `Echo`) en dus dezelfde send. Het enige verschil:
## de echo klinkt een halve toon lager (`pitch_scale` 2^(−1/12) ≈ 0,944), zodat
## twee slagen vlak na elkaar niet als één klinken. Geen echo-variant, geen
## effect op de bus, geen holle laag erbovenop. Ook een slag die 0 LP pompt
## (meter leeg, gemaal vol) klinkt: de schoep is geraakt, voor iedereen gelijk.
##
## Waarden in `data/audio.json`, groep `pompslag`.

const BUS := &"SFX"

## Untyped: de signalen en velden staan in het script van het object.
var gemaal
## De pompslag: één object voor P1, P2 en de echo; standaard uit de data.
var sfx: AudioStream


func _init() -> void:
	name = "PompslagAudio"
	var c := config("pompslag")
	max_voices = int(c.get("max_stemmen", 3))
	sfx = stream(String(c.get("stream", "")))


## Luistert naar `pumped` van `p_gemaal`.
func bind(p_gemaal: Node2D) -> void:
	gemaal = p_gemaal
	if not gemaal.pumped.is_connected(_on_pumped):
		gemaal.pumped.connect(_on_pumped)


## `pitch_scale` voor `who`: 1,0 voor P1 en P2, een vaste stap lager voor de echo.
static func pitch_of(who: String) -> float:
	if who == "echo":
		return pitch_for(float(config("pompslag").get("echo_halftonen", -1.0)))
	return 1.0


func _on_pumped(tick: int, _amount: int, who: String) -> void:
	var vane: Node2D = gemaal.last_vane if gemaal.last_vane != null else gemaal
	play_on_tick(tick, sfx, place_of(vane), BUS,
		float(config("pompslag").get("volume_db", 0.0)), pitch_of(who), who)
