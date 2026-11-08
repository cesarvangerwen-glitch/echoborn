extends RefCounted
## Een bevroren, chronologische opname (oudste frame eerst).
##
## Frame k bevat: de tick, de input die in die tick is toegepast, de
## toestand vóór de tick (pre_*) en de toestand ná de tick (post_*).
## Een clip verandert niet meer; de recorder kan intussen doorschrijven.

var ticks := PackedInt32Array()
var inputs := PackedInt32Array()
var pre_pos := PackedVector2Array()
var pre_vel := PackedVector2Array()
var pre_on_floor := PackedByteArray()
var post_pos := PackedVector2Array()
var post_vel := PackedVector2Array()


func size() -> int:
	return inputs.size()


func is_empty() -> bool:
	return inputs.is_empty()


func start_position() -> Vector2:
	return pre_pos[0]


func start_velocity() -> Vector2:
	return pre_vel[0]


func end_position() -> Vector2:
	return post_pos[post_pos.size() - 1]
