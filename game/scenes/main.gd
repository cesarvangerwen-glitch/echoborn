extends Node2D
## Speelbare spike: 2 lokale spelers, elk met een eigen echo.
##
## Beweeg met A/D + spatie (P1) of pijltjes + Enter (P2). Druk op de
## actieknop (P1: E, P2: rechter Ctrl) om je laatste 10 s als echo te
## laten afspelen. De echo staat op de schaduwlaag en botst niet met spelers.

const Sim = preload("res://scripts/sim.gd")
const PlayerActor = preload("res://scripts/echo/player_actor.gd")
const EchoActor = preload("res://scripts/echo/echo_actor.gd")
const DeviceInput = preload("res://scripts/input/device_input.gd")
const InputSetup = preload("res://scripts/input/input_setup.gd")
const SpikeWorld = preload("res://scripts/world/spike_world.gd")

const PLAYER_COLORS := [Color(1.0, 0.85, 0.4), Color(0.5, 0.85, 1.0)]
const ECHO_COLOR := Color(0.2, 0.15, 0.35, 0.8)

var _sim: Sim
var _echo_of: Dictionary = {}  # player_index -> EchoActor


func _ready() -> void:
	InputSetup.ensure_actions()
	SpikeWorld.build(self)
	_sim = Sim.new()
	_sim.name = "Sim"
	add_child(_sim)
	for i in 2:
		var player := PlayerActor.new()
		player.setup(i + 1, DeviceInput.new(i + 1), PLAYER_COLORS[i])
		player.position = SpikeWorld.PLAYER_SPAWN + Vector2(80 * i, 0)
		_sim.add_player(player)
	var camera := Camera2D.new()
	camera.position = Vector2(640, 260)
	add_child(camera)


# Spike-demo: de echo wordt hier buiten de tick opgeroepen. In productie
# loopt dit via het ACTION-bit binnen sim_step (standaarden.md §4).
func _unhandled_input(event: InputEvent) -> void:
	for player in _sim.players:
		if event.is_action_pressed("p%d_action" % player.player_index):
			_spawn_echo(player)


func _spawn_echo(player: PlayerActor) -> void:
	if _echo_of.has(player.player_index):
		_sim.remove_echo(_echo_of[player.player_index])
	var echo := EchoActor.new()
	echo.setup(ECHO_COLOR)
	echo.name = "Echo%d" % player.player_index
	_sim.add_echo(echo)
	echo.start(player.recorder.snapshot(), EchoActor.Mode.STATE)
	_echo_of[player.player_index] = echo
