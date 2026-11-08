extends CharacterBody2D
## Een speler: leest zijn inputbron, beweegt via Motor en neemt elke tick op.
##
## Heeft geen eigen _physics_process: de Sim roept `sim_step` aan, zodat de
## volgorde van alle actors per tick vastligt (E-07b: schaduw, dan P1).

const Motor = preload("res://scripts/echo/motor.gd")
const EchoRecorder = preload("res://scripts/echo/echo_recorder.gd")
const BodyBuilder = preload("res://scripts/echo/body_builder.gd")
const Layers = preload("res://scripts/world/layers.gd")

## Elke inputbron heeft `sample(tick: int) -> int` (DeviceInput, ScriptedInput).
var input_source: RefCounted
var recorder: EchoRecorder
var player_index: int
var last_input := 0


func setup(p_player_index: int, p_input_source: RefCounted, color: Color,
		capacity: int = EchoRecorder.DEFAULT_CAPACITY) -> void:
	player_index = p_player_index
	input_source = p_input_source
	recorder = EchoRecorder.new(capacity)
	name = "Player%d" % player_index
	collision_layer = Layers.LIGHT
	collision_mask = Layers.WORLD
	BodyBuilder.add_box(self, color)


func sim_step(tick: int, delta: float) -> void:
	var bits: int = input_source.sample(tick)
	last_input = bits
	var pre_position := position
	var pre_velocity := velocity
	var pre_floor := is_on_floor()
	Motor.step(self, bits, delta)
	recorder.push(tick, bits, pre_position, pre_velocity, pre_floor, position, velocity)
