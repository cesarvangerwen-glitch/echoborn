extends Node2D
## De simulatieklok: één vaste tick per _physics_process (60 Hz).
##
## Volgorde per tick volgens E-07b (docs/design/gdd.md): eerst de schaduw
## (echo's in spawnvolgorde, daarna P2 en hoger), dan P1 (stap + opname).
## Zo hangt het resultaat niet af van de volgorde van nodes in de boom.

const PlayerActor = preload("res://scripts/echo/player_actor.gd")
const EchoActor = preload("res://scripts/echo/echo_actor.gd")

## Vlak vóór elke stap van een actor. `phase` volgt E-07b: "1" = schaduw,
## "2+3" = P1 stapt en wordt opgenomen. Bedoeld voor tests en debug-overlays;
## zonder verbinding kost het uitzenden vrijwel niets.
signal actor_stepping(tick: int, phase: String, actor: Node)

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
	# E-07b (1): de schaduw. Echo's zetten hun frame; P2 stapt. In de spike
	# kunnen echo en P2 nog naast elkaar bestaan (C-01 is nog niet gebouwd).
	for echo in echoes:
		actor_stepping.emit(tick, "1", echo)
		echo.sim_step(tick, delta)
	for player in players:
		if player.player_index != 1:
			actor_stepping.emit(tick, "1", player)
			player.sim_step(tick, delta)
	# E-07b (2) + (3): P1 stapt en wordt opgenomen (PlayerActor.sim_step).
	for player in players:
		if player.player_index == 1:
			actor_stepping.emit(tick, "2+3", player)
			player.sim_step(tick, delta)
	# E-07b (4) events en (5) objecten bestaan nog niet in de spike (R5).
	tick += 1
