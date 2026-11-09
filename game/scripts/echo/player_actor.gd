extends CharacterBody2D
## Een speler: leest zijn inputbron, beweegt via Motor en neemt elke tick op.
##
## Heeft geen eigen _physics_process: de Sim roept `sim_step` en `record`
## aan, zodat de volgorde van alle actors per tick vastligt (E-07b: schaduw,
## dan P1 stapt, dan P1 wordt opgenomen). Een speler voert zijn events niet
## zelf uit; de Sim doet dat in stap (4).

const Motor = preload("res://scripts/echo/motor.gd")
const EchoRecorder = preload("res://scripts/echo/echo_recorder.gd")
const BodyBuilder = preload("res://scripts/echo/body_builder.gd")
const EventDetector = preload("res://scripts/events/event_detector.gd")
const Layers = preload("res://scripts/world/layers.gd")

## Elke inputbron heeft `sample(tick: int) -> int` (DeviceInput, ScriptedInput).
var input_source: RefCounted
var recorder: EchoRecorder
var player_index: int
var last_input := 0
## Events van de laatste stap (GameEvents-masker, E-10).
var tick_events := 0

var _detector := EventDetector.new()
var _pre_position := Vector2.ZERO
var _pre_velocity := Vector2.ZERO
var _pre_floor := false


func setup(p_player_index: int, p_input_source: RefCounted, color: Color,
		capacity: int = EchoRecorder.DEFAULT_CAPACITY) -> void:
	player_index = p_player_index
	input_source = p_input_source
	recorder = EchoRecorder.new(capacity)
	name = "Player%d" % player_index
	collision_layer = Layers.LIGHT if player_index == 1 else Layers.SHADOW
	collision_mask = Layers.WORLD
	BodyBuilder.add_box(self, color)


## Stap (2) voor P1, (1) voor P2: input lezen, events bepalen, bewegen.
func sim_step(tick: int, delta: float) -> void:
	var bits: int = input_source.sample(tick)
	last_input = bits
	tick_events = _detector.detect(tick, bits)
	_pre_position = position
	_pre_velocity = velocity
	_pre_floor = is_on_floor()
	Motor.step(self, bits, delta)


## Stap (3): deze tick opnemen (E-01), na de stap.
func record(tick: int) -> void:
	recorder.push(tick, last_input, _pre_position, _pre_velocity, _pre_floor,
		position, velocity, tick_events)
