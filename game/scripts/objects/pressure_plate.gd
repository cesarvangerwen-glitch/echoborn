extends "res://scripts/objects/sim_object.gd"
## Drukplaat (E-13): actief zolang een lichaam op een eigenaarslaag erop
## staat (E-06). Kijkt elke tick in stap (5) met een directe vormtest, dus
## in dezelfde tick als de beweging (A2).

signal changed(tick: int, active: bool)

var active := false


func sim_update(tick: int, bodies: Array[Node2D]) -> void:
	var now := not bodies_inside(bodies).is_empty()
	if now != active:
		active = now
		changed.emit(tick, active)
