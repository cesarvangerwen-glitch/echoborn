extends "res://scripts/audio/sim_sfx.gd"
## Het breekgeluid van een `Luik` (#243; audio bible v0.5 §4.1): een echo-actie
## met gewicht. Hangt onder het luik (`luik.gd` maakt hem aan).
##
## Breekt P1, P2 of de echo het luik (`opened`), of haalt de echo met zijn
## neerslag de schaduwklep weg (`schaduwklep_weg` met `by` = "echo", V-01d),
## dan klinkt **hetzelfde** breekgeluid: zelfde `stream`, `volume_db`, bus
## (`SFX`) en `pitch_scale` 1,0, voor iedereen. Gaat de schaduwklep vanzelf
## weg (`by` = "tijd"), dan klinkt er niets: niemand brak iets.
##
## Het geluid zelf bestaat nog niet (`data/audio.json`, groep `luik_breekt`,
## `stream` leeg): tot de Composer/Sound Designer het levert, is de koppeling
## stil. `sfx` kan in een test of scène ook direct gezet worden.

const BUS := &"SFX"

## Untyped: de signalen en velden staan in het script van het object.
var luik
## Het breekgeluid; standaard uit de data.
var sfx: AudioStream


func _init() -> void:
	name = "LuikAudio"
	var c := config("luik_breekt")
	max_voices = int(c.get("max_stemmen", 2))
	sfx = stream(String(c.get("stream", "")))


func bind(p_luik: Node2D) -> void:
	luik = p_luik
	if not luik.opened.is_connected(_on_opened):
		luik.opened.connect(_on_opened)
	if not luik.schaduwklep_weg.is_connected(_on_schaduwklep_weg):
		luik.schaduwklep_weg.connect(_on_schaduwklep_weg)


func _on_opened(tick: int, by: String) -> void:
	_break(tick, by)


func _on_schaduwklep_weg(tick: int, by: String) -> void:
	if by == "echo":
		_break(tick, by)


func _break(tick: int, by: String) -> void:
	play_on_tick(tick, sfx, place_of(luik), BUS,
		float(config("luik_breekt").get("volume_db", 0.0)), 1.0, by)
