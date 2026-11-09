extends Node2D
## Basis voor interactieve objecten (drukplaten, hendels, later zones en
## het schild): één eigenaarslaag (E-06) en één vlak.
##
## **Objectdetectie (A2, #68): een directe vormtest in de tick, zonder
## physics-ruimte.** Een object vergelijkt zijn vlak met de vorm van elk
## lichaam dat de Sim doorgeeft (`Shape2D.collide`, op de `global_transform`
## van de nodes). Dat zijn de posities van déze tick, dus geen vertraging.
##
## Waarom niet via de physics-ruimte: in Godot 4.6 krijgt een kinematisch
## lichaam (`CharacterBody2D`, `AnimatableBody2D`) zijn nieuwe positie pas in
## de physics-stap ná `_physics_process`. Een `intersect_shape`-query op de
## ruimte ziet de echo en P1 daardoor één tick te laat, en een `Area2D`
## (`body_entered`, `get_overlapping_bodies()`) twee ticks. Beide zijn
## vastgelegd in `test_objects.gd`. Objecten gebruiken die daarom niet voor
## gameplay. Zie `docs/tech/ontwerp.md` §4a.
##
## Geen eigen `_physics_process`: de Sim roept `interact` aan in stap (4) en
## `sim_update` in stap (5) van E-07b.

const Layers = preload("res://scripts/world/layers.gd")

## Wie het object mag voelen of bedienen (E-06): Layers.LIGHT, Layers.SHADOW
## of beide (gedeeld).
var owner_layers := Layers.LIGHT | Layers.SHADOW
## Het vlak: belasting voor een drukplaat, interactievlak voor een hendel.
var shape: Shape2D


func setup(p_owner_layers: int, size: Vector2) -> void:
	owner_layers = p_owner_layers
	var rect := RectangleShape2D.new()
	rect.size = size
	shape = rect


## Mag dit lichaam het object voelen of bedienen (E-06)? Een lichaam zonder
## laag (een echo die niet afspeelt) mag nooit.
func accepts(body: CollisionObject2D) -> bool:
	return body.collision_layer & owner_layers != 0


## Overlapt dit lichaam het vlak nu, en mag het het object voelen?
func overlaps(body: CollisionObject2D) -> bool:
	if not accepts(body):
		return false
	var own := global_transform
	for owner_id in body.get_shape_owners():
		if body.is_shape_owner_disabled(owner_id):
			continue
		var xform := body.global_transform * body.shape_owner_get_transform(owner_id)
		for i in body.shape_owner_get_shape_count(owner_id):
			if shape.collide(own, body.shape_owner_get_shape(owner_id, i), xform):
				return true
	return false


## De lichamen uit `bodies` die het vlak nu overlappen en die het mag voelen.
func bodies_inside(bodies: Array[Node2D]) -> Array[Node2D]:
	var found: Array[Node2D] = []
	for body in bodies:
		if overlaps(body as CollisionObject2D):
			found.append(body)
	return found


## Kan een INTERACTIE-event dit object bedienen? Standaard niet.
func is_interactable() -> bool:
	return false


## Stap (4): een INTERACTIE-event van `actor` bedient dit object (E-10b).
func interact(_actor: Node2D, _tick: int) -> void:
	pass


## Stap (5): het object werkt zijn stand bij. `bodies` zijn de lichamen van
## deze tick (`Sim.bodies()`, C-01: hooguit twee).
func sim_update(_tick: int, _bodies: Array[Node2D]) -> void:
	pass
