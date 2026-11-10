extends "res://scripts/objects/sim_object.gd"
## Checkpoint (E-04b, LM-08; T5b deel 3a, #82; ontwerp.md §7).
##
## Komt P1 in het vlak (zijn vorm overlapt het; de flank: niet al op de
## vorige tick), dan wordt dit de plek waar P1 na laden verschijnt en volgt er een
## autosave: `Progress.reach_checkpoint` meldt `checkpoint_reached`, en de
## autoload `SaveService` schrijft het slot (met `store_world` vlak ervoor).
##
## - Alleen P1 (laag 2, E-05): de echo en P2 zetten geen checkpoint (C-08:
##   in co-op respawnen beiden op het checkpoint van P1).
## - De plek is `global_position + spawn_offset`: zet het object op de vloer.
## - Een gemaal is een checkpoint (LM-08): zet er een `Checkpoint` naast.
##   Wie het pomprad raakt zonder in het vlak te komen, zet (nog) geen
##   checkpoint: open punt voor deel 3b (§12).
## - Geen blijvende stand: na laden begint het checkpoint los; een P1 die op
##   het checkpoint verschijnt, telt op die eerste tick als binnenkomen, maar
##   dat schrijft dezelfde plek nog een keer weg.
## - Mag in de gestreamde inhoud van een kamer staan (§3a).
##
## Werkt in stap (5) van E-07b, met een directe vormtest (A2).

## P1 kwam deze tick het vlak in.
signal reached(tick: int)

## Waar P1 verschijnt, ten opzichte van dit object.
@export var spawn_offset := Vector2.ZERO
## De autoload `Progress`; null = `/root/Progress`. Een test geeft een
## eigen node, zodat hij nooit een echte save raakt.
var progress: Node = null

var _inside := false


func _init() -> void:
	owner_layers = Layers.LIGHT


func spawn_point() -> Vector2:
	return global_position + spawn_offset


func sim_update(tick: int, bodies: Array[Node2D]) -> void:
	var now := false
	for body in bodies_inside(bodies):
		if (body as CollisionObject2D).collision_layer & Layers.LIGHT != 0:
			now = true
	if now and not _inside:
		reached.emit(tick)
		var target := progress if progress != null else get_node_or_null(^"/root/Progress")
		if target != null:
			target.reach_checkpoint(spawn_point())
	_inside = now
