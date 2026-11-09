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
const InputBits = preload("res://scripts/input/input_bits.gd")
const Layers = preload("res://scripts/world/layers.gd")
const Tuning = preload("res://scripts/echo/tuning.gd")

enum EchoReset { NONE, RELEASE, RESPAWN }

## Een vijandelijke treffer kostte een levenspunt (LM-05). Bij 0 volgt de
## respawn in de flow-kamer (T16b).
signal health_changed(tick: int, health: int)

## Elke inputbron heeft `sample(tick: int) -> int` (DeviceInput, ScriptedInput).
var input_source: RefCounted
var recorder: EchoRecorder
var player_index: int
var last_input := 0
## Events van de laatste stap (GameEvents-masker, E-10).
var tick_events := 0
## Bewegingsevents van de laatste stap (Motor.EV_*): sprong, bounce,
## springplank-landing, dash. Voor lichtmeter en meetlog, niet voor de echo.
var move_events := 0
## Verborgen bewegingstoestand (snelheid in px/tick, dash, buffers).
var motor := Motor.State.new()
## Vraagt deze tick een reset van de echo (E-04b respawn, E-04c Loslaten)?
## De echo leest dit na stap (3) van dezelfde tick (`sim_after_source`).
var echo_reset: EchoReset = EchoReset.NONE
## Levenspunten (LM-05: 5 in de flow-kamer). P2 heeft er geen (C-02).
var health := 5

var _detector := EventDetector.new()
var _pre_position := Vector2.ZERO
var _pre_velocity := Vector2.ZERO
var _pre_floor := false
var _echo_held := 0
var _respawn_requested := false
var _respawn_position := Vector2.ZERO


func setup(p_player_index: int, p_input_source: RefCounted, color: Color,
		capacity: int = -1) -> void:
	player_index = p_player_index
	input_source = p_input_source
	health = int(Tuning.combat()["p1_health"])
	# E-02: recorder-capaciteit uit de data, tenzij de aanroeper hem opgeeft.
	recorder = EchoRecorder.new(capacity if capacity > 0 else int(Tuning.echo()["recorder_capacity"]))
	name = "Player%d" % player_index
	# E-05: P1 op laag 2 met masker 1 + 4 + 6; P2 op laag 3 met masker 1 + 5.
	if player_index == 1:
		collision_layer = Layers.LIGHT
		collision_mask = Layers.P1_MASK
	else:
		collision_layer = Layers.SHADOW
		collision_mask = Layers.P2_MASK
	# E-07a (4): geen ingebouwde platformsnelheid; meebewegen doet de Motor.
	platform_on_leave = CharacterBody2D.PLATFORM_ON_LEAVE_DO_NOTHING
	platform_floor_layers = Layers.WORLD | Layers.LIGHT_GEOMETRY
	BodyBuilder.add_box(self, color, Tuning.body_size())


## Zet de speler op de volgende tick terug op `at` (respawn, E-04b). Dat
## telt als reset van de echo op die tick.
func respawn_at(at: Vector2) -> void:
	_respawn_requested = true
	_respawn_position = at


## Een vijandelijk aanvalsvlak raakt dit lichaam (alleen laag 2, E-14h).
func take_hit(tick: int) -> void:
	if player_index != 1 or health <= 0:
		return
	health -= 1
	health_changed.emit(tick, health)


## Stap (2) voor P1, (1) voor P2: input lezen, events bepalen, bewegen.
func sim_step(tick: int, _delta: float) -> void:
	echo_reset = EchoReset.NONE
	if _respawn_requested:
		_respawn_requested = false
		position = _respawn_position
		motor = Motor.State.new()
		velocity = Vector2.ZERO
		echo_reset = EchoReset.RESPAWN
	var bits: int = input_source.sample(tick)
	last_input = bits
	tick_events = _detector.detect(tick, bits)
	_pre_position = position
	_pre_velocity = motor.velocity
	_pre_floor = motor.on_floor
	move_events = Motor.step(self, motor, bits, tick)
	_update_release(bits)


## Stap (3): deze tick opnemen (E-01), na de stap.
func record(tick: int) -> void:
	recorder.push(tick, last_input, _pre_position, _pre_velocity, _pre_floor,
		position, motor.velocity, tick_events, motor.on_floor, motor.facing,
		motor.support, motor.anim, last_input & InputBits.ATTACK != 0)


## E-09: ECHO 30 ticks aaneengesloten vasthouden is Loslaten, één keer per druk.
func _update_release(bits: int) -> void:
	if bits & InputBits.ECHO:
		_echo_held += 1
		if _echo_held == int(Tuning.echo()["release_hold_ticks"]) and echo_reset == EchoReset.NONE:
			echo_reset = EchoReset.RELEASE
	else:
		_echo_held = 0
