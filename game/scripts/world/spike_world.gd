extends RefCounted
## Bouwt het testlevel van de spike: vloer, twee muren en een platform.

const Layers = preload("res://scripts/world/layers.gd")

const FLOOR_Y := 400.0
const PLAYER_SPAWN := Vector2(200, FLOOR_Y - 15.0)  ## lichaam 16 × 30 (gdd §2.5a)


static func build(parent: Node) -> void:
	add_block(parent, "Floor", Vector2(640, FLOOR_Y + 20), Vector2(1400, 40))
	add_block(parent, "WallLeft", Vector2(-40, 200), Vector2(40, 600))
	add_block(parent, "WallRight", Vector2(1320, 200), Vector2(40, 600))
	add_block(parent, "Platform", Vector2(700, FLOOR_Y - 90), Vector2(200, 20))


static func add_block(parent: Node, block_name: String, center: Vector2, size: Vector2,
		layer: int = Layers.WORLD, one_way: bool = false) -> StaticBody2D:
	var body := StaticBody2D.new()
	body.name = block_name
	body.position = center
	body.collision_layer = layer
	body.collision_mask = 0
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = size
	shape.shape = rect
	shape.one_way_collision = one_way
	body.add_child(shape)
	var visual := Polygon2D.new()
	var h := size * 0.5
	visual.polygon = PackedVector2Array([
		Vector2(-h.x, -h.y), Vector2(h.x, -h.y), Vector2(h.x, h.y), Vector2(-h.x, h.y)])
	visual.color = Color(0.35, 0.35, 0.4)
	body.add_child(visual)
	parent.add_child(body)
	return body
