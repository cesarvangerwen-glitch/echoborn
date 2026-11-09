extends "res://scripts/combat/combat_target.gd"
## Basisvijand of pantserdoel van de merk-arena K2 (gdd §4.2, §4.3).
##
## Gedrag uit `combat_target.gd`; deze kamerversie voegt twee regels toe:
## de vijand **verlaat K2 niet** (blijft tussen `min_x` en `max_x`) en doet
## alleen iets zolang P1 in K2 is (`is_awake`).

## Geeft `true` als P1 in K2 is. Gezet door de flow-kamer.
var is_awake: Callable
var min_x := -INF
var max_x := INF


func sim_update(tick: int, bodies: Array[Node2D]) -> void:
	if is_awake.is_valid() and not is_awake.call():
		return
	super.sim_update(tick, bodies)
	position.x = clampf(position.x, min_x, max_x)
