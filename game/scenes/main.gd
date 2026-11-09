extends Node2D
## Speelbare spike: P1 met zijn echo, en P2 die mee kan doen (C-01).
##
## Beweeg met A/D + spatie (P1). Druk op E om je laatste 10 s als echo te
## laten afspelen. Rechter Ctrl laat P2 meedoen of stoppen (pijltjes + Enter
## om te bewegen); zolang P2 meedoet, speelt er geen echo (C-01). De echte
## drop-in en drop-out (C-03, C-05, InputRouter) komen in T16c.

const Sim = preload("res://scripts/sim.gd")
const PlayerActor = preload("res://scripts/echo/player_actor.gd")
const EchoActor = preload("res://scripts/echo/echo_actor.gd")
const DeviceInput = preload("res://scripts/input/device_input.gd")
const InputSetup = preload("res://scripts/input/input_setup.gd")
const SpikeWorld = preload("res://scripts/world/spike_world.gd")

const PLAYER_COLORS := [Color(1.0, 0.85, 0.4), Color(0.5, 0.85, 1.0)]
const ECHO_COLOR := Color(0.2, 0.15, 0.35, 0.8)

var _sim: Sim
var _echo: EchoActor
var _p2: PlayerActor


func _ready() -> void:
	InputSetup.ensure_actions()
	SpikeWorld.build(self)
	_sim = Sim.new()
	_sim.name = "Sim"
	add_child(_sim)
	var p1 := PlayerActor.new()
	p1.setup(1, DeviceInput.new(1), PLAYER_COLORS[0])
	p1.position = SpikeWorld.PLAYER_SPAWN
	_sim.add_player(p1)
	var camera := Camera2D.new()
	camera.position = Vector2(640, 260)
	add_child(camera)


# Spike-demo: echo en meedoen worden hier buiten de tick opgeroepen. In
# productie loopt dit via de InputRouter en events in de tick (standaarden §4).
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("p1_action"):
		_spawn_echo(_sim.players[0])
	elif event.is_action_pressed("p2_action") and _p2 == null:
		_p2 = PlayerActor.new()
		_p2.setup(2, DeviceInput.new(2), PLAYER_COLORS[1])
		_p2.position = _sim.players[0].position
		_sim.add_player(_p2)
		_echo = null  # de Sim heeft hem weggehaald (C-01)
	elif event.is_action_pressed("p2_action") and _p2 != null:
		_sim.remove_player(_p2)
		_p2 = null


func _spawn_echo(player: PlayerActor) -> void:
	if _echo != null:
		_sim.remove_echo(_echo)
		_echo = null
	var echo := EchoActor.new()
	echo.setup(ECHO_COLOR)
	echo.name = "Echo1"
	if not _sim.add_echo(echo):
		echo.free()
		return
	echo.start(player.recorder.snapshot(), EchoActor.Mode.STATE)
	_echo = echo
