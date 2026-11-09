extends RefCounted
## Ringbuffer met de laatste N physics-ticks van één speler.
##
## Standaard 600 ticks = 10 s bij 60 Hz. Schrijven is O(1) en alloceert
## niets per tick (vooraf gealloceerde packed arrays). `snapshot()` maakt
## een chronologische kopie (EchoClip) voor het afspelen.

const EchoClip = preload("res://scripts/echo/echo_clip.gd")

const DEFAULT_CAPACITY := 600

var capacity: int

var _ticks := PackedInt32Array()
var _inputs := PackedInt32Array()
var _events := PackedInt32Array()
var _pre_pos := PackedVector2Array()
var _pre_vel := PackedVector2Array()
var _pre_on_floor := PackedByteArray()
var _post_pos := PackedVector2Array()
var _post_vel := PackedVector2Array()
var _head := 0
var _count := 0


func _init(p_capacity: int = DEFAULT_CAPACITY) -> void:
	capacity = p_capacity
	_ticks.resize(capacity)
	_inputs.resize(capacity)
	_events.resize(capacity)
	_pre_pos.resize(capacity)
	_pre_vel.resize(capacity)
	_pre_on_floor.resize(capacity)
	_post_pos.resize(capacity)
	_post_vel.resize(capacity)


## `events` is het eventmasker van die tick (GameEvents, E-10). Events worden
## opgenomen ongeacht of ze bij de speler iets raakten.
func push(tick: int, bits: int, pre_position: Vector2, pre_velocity: Vector2,
		pre_floor: bool, post_position: Vector2, post_velocity: Vector2,
		events: int = 0) -> void:
	_ticks[_head] = tick
	_inputs[_head] = bits
	_events[_head] = events
	_pre_pos[_head] = pre_position
	_pre_vel[_head] = pre_velocity
	_pre_on_floor[_head] = 1 if pre_floor else 0
	_post_pos[_head] = post_position
	_post_vel[_head] = post_velocity
	_head = (_head + 1) % capacity
	_count = mini(_count + 1, capacity)


func size() -> int:
	return _count


func clear() -> void:
	_head = 0
	_count = 0


## Chronologische kopie van (maximaal) de laatste `max_frames` frames.
func snapshot(max_frames: int = -1) -> EchoClip:
	var n := _count if max_frames < 0 else mini(max_frames, _count)
	var clip := EchoClip.new()
	clip.ticks.resize(n)
	clip.inputs.resize(n)
	clip.events.resize(n)
	clip.pre_pos.resize(n)
	clip.pre_vel.resize(n)
	clip.pre_on_floor.resize(n)
	clip.post_pos.resize(n)
	clip.post_vel.resize(n)
	var first := (_head - n + capacity) % capacity
	for i in n:
		var src := (first + i) % capacity
		clip.ticks[i] = _ticks[src]
		clip.inputs[i] = _inputs[src]
		clip.events[i] = _events[src]
		clip.pre_pos[i] = _pre_pos[src]
		clip.pre_vel[i] = _pre_vel[src]
		clip.pre_on_floor[i] = _pre_on_floor[src]
		clip.post_pos[i] = _post_pos[src]
		clip.post_vel[i] = _post_vel[src]
	return clip
