extends RefCounted
## Bouwt de vorm en het zichtbare blokje van een actor (spike-placeholder).

const SIZE := Vector2(24, 24)


static func add_box(body: CollisionObject2D, color: Color, size: Vector2 = SIZE) -> void:
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = size
	shape.shape = rect
	body.add_child(shape)
	var visual := Polygon2D.new()
	var h := size * 0.5
	visual.polygon = PackedVector2Array([
		Vector2(-h.x, -h.y), Vector2(h.x, -h.y), Vector2(h.x, h.y), Vector2(-h.x, h.y)])
	visual.color = color
	body.add_child(visual)
