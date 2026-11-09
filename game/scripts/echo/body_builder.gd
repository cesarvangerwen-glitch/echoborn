extends RefCounted
## Bouwt de vorm en het zichtbare blokje van een actor (placeholder-art).
##
## Lichaam van P1, P2 en de echo: 16 × 30 px (gdd §2.5a).

const SIZE := Vector2(16, 30)


static func add_box(body: CollisionObject2D, color: Color, size: Vector2 = SIZE) -> void:
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = size
	shape.shape = rect
	body.add_child(shape)
	body.add_child(make_visual(size, color))


static func make_visual(size: Vector2, color: Color) -> Polygon2D:
	var visual := Polygon2D.new()
	var h := size * 0.5
	visual.polygon = PackedVector2Array([
		Vector2(-h.x, -h.y), Vector2(h.x, -h.y), Vector2(h.x, h.y), Vector2(-h.x, h.y)])
	visual.color = color
	return visual


## Een plank (E-07, C-09): een StaticBody2D met een eenrichtingsvorm zo breed
## als het lichaam, op de bovenkant ervan. Begint uit (laag 0); de eigenaar
## zet de laag (6 schaduwplank, 8 lichtplank) en synchroniseert de transform.
static func add_plank(body: Node2D, body_size: Vector2, thickness: float) -> StaticBody2D:
	var plank := StaticBody2D.new()
	plank.name = "Plank"
	plank.collision_layer = 0
	plank.collision_mask = 0
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(body_size.x, thickness)
	shape.shape = rect
	shape.one_way_collision = true
	shape.position = Vector2(0, (thickness - body_size.y) * 0.5)
	plank.add_child(shape)
	body.add_child(plank)
	return plank


## Zet de plank in déze tick op zijn plek in de physics-ruimte (ontwerp.md
## §4a, R8): een node-transform bereikt de ruimte pas na `_physics_process`.
static func sync_plank(plank: StaticBody2D) -> void:
	PhysicsServer2D.body_set_state(plank.get_rid(), PhysicsServer2D.BODY_STATE_TRANSFORM,
		plank.global_transform)
