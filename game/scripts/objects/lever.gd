extends "res://scripts/objects/sim_object.gd"
## Hendel (E-13): **Wissel** keert bij elke bediening om, **Eenmalig** gaat
## bij de eerste bediening om en blijft dan vast. Bediend door een
## INTERACTIE-event van een lichaam op een eigenaarslaag (E-06, E-10b).

signal changed(tick: int, on: bool, by: Node2D)

enum Kind { WISSEL, EENMALIG }

@export var kind: Kind = Kind.WISSEL
var on := false
var _used := false


func is_interactable() -> bool:
	return true


func interact(actor: Node2D, tick: int) -> void:
	match kind:
		Kind.WISSEL:
			on = not on
		Kind.EENMALIG:
			if _used:
				return
			on = true
			_used = true
	changed.emit(tick, on, actor)


## R10: de stand van een hendel blijft bewaard als zijn kamer ontlaadt; een
## Eenmalige hendel die om is, blijft vast.
func has_persistent_state() -> bool:
	return true


func get_persistent_state() -> bool:
	return on


func set_persistent_state(p_on: bool) -> void:
	on = p_on
	_used = p_on and kind == Kind.EENMALIG
