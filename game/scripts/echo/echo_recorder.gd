extends RefCounted
## Ringbuffer met de laatste N physics-ticks van één speler (E-01, E-02).
##
## Standaard 600 ticks = 10 s bij 60 Hz: de staart gebruikt er D (± 2 s), de
## co-op-finisher later alle 600 (8A). Schrijven is O(1) en alloceert niets
## per tick. `snapshot()` maakt een chronologische kopie (EchoClip); de
## staart-echo leest een frame direct op zijn tick (`index_of_tick`).

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
var _post_on_floor := PackedByteArray()
var _facing := PackedByteArray()      ## 0 = links (-1), 1 = rechts (+1)
var _support := PackedByteArray()     ## Motor.Support
var _anim := PackedByteArray()        ## Motor.Anim
var _attack_held := PackedByteArray() ## `aanval_vast` (E-01, voor C-11)
var _head := 0
var _count := 0


func _init(p_capacity: int = DEFAULT_CAPACITY) -> void:
	capacity = p_capacity
	# Packed arrays zijn waardetypes: elk apart vergroten, niet via een lus.
	_ticks.resize(capacity)
	_inputs.resize(capacity)
	_events.resize(capacity)
	_pre_pos.resize(capacity)
	_pre_vel.resize(capacity)
	_pre_on_floor.resize(capacity)
	_post_pos.resize(capacity)
	_post_vel.resize(capacity)
	_post_on_floor.resize(capacity)
	_facing.resize(capacity)
	_support.resize(capacity)
	_anim.resize(capacity)
	_attack_held.resize(capacity)


## `events` is het eventmasker van die tick (GameEvents, E-10). Events worden
## opgenomen ongeacht of ze bij de speler iets raakten. De velden na `events`
## zijn de toestand ná de stap (E-01): op de vloer, kijkrichting, steunsoort
## animatietoestand en of AANVAL ingedrukt is (`aanval_vast`).
func push(tick: int, bits: int, pre_position: Vector2, pre_velocity: Vector2,
		pre_floor: bool, post_position: Vector2, post_velocity: Vector2,
		events: int = 0, post_floor: bool = false, facing: int = 1,
		support: int = 0, anim: int = 0, attack_held: bool = false) -> void:
	_ticks[_head] = tick
	_inputs[_head] = bits
	_events[_head] = events
	_pre_pos[_head] = pre_position
	_pre_vel[_head] = pre_velocity
	_pre_on_floor[_head] = 1 if pre_floor else 0
	_post_pos[_head] = post_position
	_post_vel[_head] = post_velocity
	_post_on_floor[_head] = 1 if post_floor else 0
	_facing[_head] = 1 if facing > 0 else 0
	_support[_head] = support
	_anim[_head] = anim
	_attack_held[_head] = 1 if attack_held else 0
	_head = (_head + 1) % capacity
	_count = mini(_count + 1, capacity)


func size() -> int:
	return _count


func clear() -> void:
	_head = 0
	_count = 0


## Index in de buffer van het frame van `tick`, of -1 als dat frame er niet
## (meer) is. Ticks zijn aaneengesloten zolang de speler elke tick opneemt.
func index_of_tick(tick: int) -> int:
	if _count == 0:
		return -1
	var last := (_head - 1 + capacity) % capacity
	var back := _ticks[last] - tick
	if back < 0 or back >= _count:
		return -1
	var index := (last - back + capacity) % capacity
	return index if _ticks[index] == tick else -1


func post_position(index: int) -> Vector2:
	return _post_pos[index]


func post_velocity(index: int) -> Vector2:
	return _post_vel[index]


func post_on_floor(index: int) -> bool:
	return _post_on_floor[index] == 1


func facing(index: int) -> int:
	return 1 if _facing[index] == 1 else -1


func support(index: int) -> int:
	return _support[index]


func anim(index: int) -> int:
	return _anim[index]


func attack_held(index: int) -> bool:
	return _attack_held[index] == 1


func events(index: int) -> int:
	return _events[index]


func tick_at(index: int) -> int:
	return _ticks[index]


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
