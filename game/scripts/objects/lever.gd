extends "res://scripts/objects/sim_object.gd"
## Hendel (E-13): **Wissel** keert bij elke bediening om, **Eenmalig** gaat
## bij de eerste bediening om en blijft dan vast. Bediend door een
## INTERACTIE-event van een lichaam op een eigenaarslaag (E-06, E-10b).

signal changed(tick: int, on: bool, by: Node2D)

enum Kind { WISSEL, EENMALIG }

var kind: Kind = Kind.WISSEL
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
