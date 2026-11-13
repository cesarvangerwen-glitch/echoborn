extends "res://scripts/objects/sim_object.gd"
## Een verzamelobject of vaardigheid om op te pakken (WS-08, LM-11, LM-12;
## T8a #83). Soorten:
## - `LAMPGLAS`: +1 maximum levenspunt en de levenspunten vol (LM-07, WS-08 a);
## - `LOGBLADZIJDE`: lore (`nummer`; het kader van de UX volgt in T10);
## - `VAARDIGHEID`: de vaardigheid op een sokkel (`vaardigheid`, bv. `V-01`).
##
## Wie: P1 en P2 (C-02: P2 is een volwaardige partner); de echo nooit (hij
## herhaalt alleen). Opgepakt als het middelpunt van het lichaam binnen
## `radius` px van het object is (de plek van P1 als hij erbij staat), in stap
## (5) van de tick. Werkaanname (GP): 12 px, de regel van de placeholders van
## de WLD (kamerdoc §3b, §3f), zodat de runs dezelfde ticks houden.
##
## Blijvende stand (R10, LM-12): `opgepakt`, als vlag in de save
## (`<gebied>/<kamer>/<pad>`). Na laden is een opgepakt object weg (niet
## zichtbaar, meldt niets meer). Het effect zelf (levenspunten, de sokkel)
## past de gebiedsscène toe op `picked_up`, en na laden op de vlag.

const PlayerActor = preload("res://scripts/echo/player_actor.gd")

enum Soort { LAMPGLAS, LOGBLADZIJDE, VAARDIGHEID }

## Opgepakt op `tick` door `who` (`p1` of `p2`).
signal picked_up(tick: int, who: String)

@export var soort: Soort = Soort.LOGBLADZIJDE
## Logbladzijde: het nummer in het gebied (1, 2, 3 …).
@export var nummer := 0
## Vaardigheid: de id uit de gdd (bv. `V-01`, de Neerslag).
@export var vaardigheid: StringName = &""
## Afstand (px) tussen het middelpunt van het lichaam en het object.
@export var radius := 12.0

var opgepakt := false
## Tick van het oppakken in deze scène, of -1 (ook -1 als het uit de save al weg was).
var picked_tick := -1


func _ready() -> void:
	_update_visual()


func has_persistent_state() -> bool:
	return true


func get_persistent_state() -> bool:
	return opgepakt


func set_persistent_state(on: bool) -> void:
	opgepakt = on
	_update_visual()


## De naam in het meetlog en de waarde (`LAMPGLAS`, `LOGBLAD` + nummer, `VAARDIGHEID` + id).
func event_name() -> String:
	match soort:
		Soort.LAMPGLAS:
			return "LAMPGLAS"
		Soort.VAARDIGHEID:
			return "VAARDIGHEID"
	return "LOGBLAD"


func event_value() -> String:
	match soort:
		Soort.LOGBLADZIJDE:
			return str(nummer)
		Soort.VAARDIGHEID:
			return String(vaardigheid)
	return ""


## Stap (5): P1 of P2 binnen `radius` pakt het op (P1 eerst, volgorde van `Sim.bodies`).
func sim_update(tick: int, bodies: Array[Node2D]) -> void:
	if opgepakt:
		return
	for body in bodies:
		if not (body is PlayerActor):
			continue
		if body.global_position.distance_to(global_position) <= radius:
			opgepakt = true
			picked_tick = tick
			_update_visual()
			picked_up.emit(tick, "p%d" % body.player_index)
			return


func _update_visual() -> void:
	visible = not opgepakt
