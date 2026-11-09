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
