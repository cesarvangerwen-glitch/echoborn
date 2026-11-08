extends Node2D
## De simulatieklok: één vaste tick per _physics_process (60 Hz).
##
## Alle gameplay-actors worden hier in een vaste volgorde gestapt:
## eerst spelers (op player_index), dan echo's (in spawnvolgorde).
## Zo hangt het resultaat niet af van de volgorde van nodes in de boom.

const PlayerActor = preload("res://scripts/echo/player_actor.gd")
const EchoActor = preload("res://scripts/echo/echo_actor.gd")

## Aantal verwerkte ticks sinds de start.
var tick := 0
var players: Array[PlayerActor] = []
var echoes: Array[EchoActor] = []


func add_player(player: PlayerActor) -> void:
	players.append(player)
	players.sort_custom(func(a: PlayerActor, b: PlayerActor) -> bool:
		return a.player_index < b.player_index)
	add_child(player)


func add_echo(echo: EchoActor) -> void:
	echoes.append(echo)
	add_child(echo)


func remove_echo(echo: EchoActor) -> void:
	echoes.erase(echo)
	echo.queue_free()


func _physics_process(delta: float) -> void:
	for player in players:
		player.sim_step(tick, delta)
	for echo in echoes:
		echo.sim_step(tick, delta)
	tick += 1
