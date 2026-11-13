extends RefCounted
## De bussen van de game (audio bible §10), minimaal: `res://default_bus_layout.tres`.
##
## Master (HardLimiter, plafond −1 dB) met Muziek, Omgeving en SFX; onder SFX
## Speler, Echo, Combat en UI. Bus Echo staat op 0 dB: de −7/−8 dB van de echo
## zit al in de voorgerenderde varianten (`slice-audio.md` §7.2, Lead-review
## PR #274; bible §10 gaat naar v0.6). Nog niet hier (volgende koppeling):
## de sidechain-compressor op Muziek/Omgeving en de galmbussen.
##
## Godot laadt de layout zelf bij het opstarten (ook headless, met de
## Dummy-driver). `ensure()` laadt hem alsnog als de bus SFX ontbreekt, bv.
## als iets anders de layout verving; zonder bus valt een speler stil terug
## op Master, en dat mag een echo-actie met gewicht (bible §4.1) niet.

const LAYOUT := "res://default_bus_layout.tres"

const MASTER := &"Master"
const SFX := &"SFX"
const SPELER := &"Speler"
const ECHO := &"Echo"
const COMBAT := &"Combat"


## Zorgt dat de bussen van de layout er zijn. Raakt de Sim niet.
static func ensure() -> void:
	if AudioServer.get_bus_index(SFX) >= 0:
		return
	var layout := load(LAYOUT) as AudioBusLayout
	if layout == null:
		push_error("AudioBuses: %s ontbreekt" % LAYOUT)
		return
	AudioServer.set_bus_layout(layout)


## De send van `bus` (de bus waar hij in uitkomt), of "" zonder bus.
static func send_of(bus: StringName) -> StringName:
	var index := AudioServer.get_bus_index(bus)
	return AudioServer.get_bus_send(index) if index >= 0 else &""


## Aantal effecten op `bus` (−1 zonder bus).
static func effect_count(bus: StringName) -> int:
	var index := AudioServer.get_bus_index(bus)
	return AudioServer.get_bus_effect_count(index) if index >= 0 else -1
