extends Node2D
## De simulatieklok: één vaste tick per _physics_process (60 Hz).
##
## Volgorde per tick volgens E-07b (docs/design/gdd.md, ontwerp.md §2 en §4a):
##   (1) de schaduw: de echo zet zijn frame, óf P2 stapt (en wordt opgenomen)
##   (2) P1 stapt
##   (3) P1 wordt opgenomen
##   (4) events: eerst van P1, dan van de schaduw (E-10)
##   (5) objecten werken hun stand bij (drukplaten, hendels, later zones)
## Zo hangt het resultaat niet af van de volgorde van nodes in de boom.
##
## C-01 (max. twee lichamen) bewaakt de Sim zelf: er is hooguit één
## schaduwlichaam, de echo óf P2. Doet P2 mee, dan speelt er geen echo.

const PlayerActor = preload("res://scripts/echo/player_actor.gd")
const EchoActor = preload("res://scripts/echo/echo_actor.gd")
const SimObject = preload("res://scripts/objects/sim_object.gd")
const GameEvents = preload("res://scripts/events/game_events.gd")

## Vlak vóór elke stap van een actor of object. `phase` is de stap uit E-07b:
## "1", "2", "3", "4" of "5". Bedoeld voor tests en debug-overlays; zonder
## verbinding kost het uitzenden vrijwel niets.
signal actor_stepping(tick: int, phase: String, actor: Node)
## Een event is uitgevoerd in stap (4). `target` is het bediende object, of
## null als het event niets raakte (het event bestaat dan toch, E-10).
## Systemen die nog komen (aanval E-10a, merk E-14) haken hier of in
## `_execute` in.
signal event_executed(tick: int, kind: int, actor: Node2D, target: Node)
## Na stap (5), vóór `tick` ophoogt. Alle standen van deze tick zijn dan af;
## een echo die deze tick zijn laatste frame speelde, staat er nog.
signal tick_finished(tick: int)

## Aantal verwerkte ticks sinds de start.
var tick := 0
var players: Array[PlayerActor] = []
var echoes: Array[EchoActor] = []
var objects: Array[SimObject] = []


func add_player(player: PlayerActor) -> void:
	players.append(player)
	players.sort_custom(func(a: PlayerActor, b: PlayerActor) -> bool:
		return a.player_index < b.player_index)
	add_child(player)
	# C-01: doet P2 mee, dan stopt het afspelen meteen. Waar P2 verschijnt
	# (C-03), regelt de drop-in (T16c), niet de Sim.
	if player.player_index != 1:
		for echo in echoes.duplicate():
			remove_echo(echo)


func remove_player(player: PlayerActor) -> void:
	players.erase(player)
	player.collision_layer = 0
	player.visible = false
	player.queue_free()


## Voegt een echo toe als C-01 dat toelaat: geen P2 in het spel en geen
## andere echo die nog speelt. Anders gebeurt er niets en is het antwoord
## `false`; de aanroeper ruimt de echo dan zelf op.
func add_echo(echo: EchoActor) -> bool:
	if not can_add_echo():
		return false
	echoes.append(echo)
	add_child(echo)
	return true


func can_add_echo() -> bool:
	if is_coop():
		return false
	for echo in echoes:
		if echo.is_active() or echo.is_present():
			return false
	return true


func remove_echo(echo: EchoActor) -> void:
	echoes.erase(echo)
	echo.stop()
	echo.queue_free()


func add_object(object: SimObject) -> void:
	objects.append(object)
	add_child(object)


func is_coop() -> bool:
	for player in players:
		if player.player_index != 1:
			return true
	return false


## Lichamen die nu in de wereld staan (C-01): P1, P2 en een echo die afspeelt.
func bodies() -> Array[Node2D]:
	var result: Array[Node2D] = []
	for player in players:
		result.append(player)
	for echo in echoes:
		if echo.is_present():
			result.append(echo)
	return result


## Schaduwlichamen van nu: P2 of de echo die afspeelt (C-01: hooguit één).
func shadow_bodies() -> Array[Node2D]:
	var result: Array[Node2D] = []
	for body in bodies():
		if not (body is PlayerActor and body.player_index == 1):
			result.append(body)
	return result


func _physics_process(delta: float) -> void:
	# (1) de schaduw. Echo's zetten hun frame; P2 stapt en wordt opgenomen.
	for echo in echoes:
		actor_stepping.emit(tick, "1", echo)
		echo.sim_step(tick, delta)
	for player in players:
		if player.player_index != 1:
			actor_stepping.emit(tick, "1", player)
			player.sim_step(tick, delta)
			player.record(tick)
	# (2) P1 stapt, (3) P1 wordt opgenomen.
	for player in players:
		if player.player_index == 1:
			actor_stepping.emit(tick, "2", player)
			player.sim_step(tick, delta)
			actor_stepping.emit(tick, "3", player)
			player.record(tick)
	# (4) events, eerst van P1, dan van de schaduw.
	for player in players:
		if player.player_index == 1:
			_run_events(player, player.tick_events)
	for echo in echoes:
		if echo.is_present():
			_run_events(echo, echo.tick_events)
	for player in players:
		if player.player_index != 1:
			_run_events(player, player.tick_events)
	# (5) objecten, in de volgorde van toevoegen, met de lichamen van deze tick.
	var present := bodies()
	for object in objects:
		actor_stepping.emit(tick, "5", object)
		object.sim_update(tick, present)
	tick_finished.emit(tick)
	# Een echo die deze tick zijn laatste frame speelde, verdwijnt nu pas.
	for echo in echoes:
		echo.sim_end_tick()
	tick += 1


func _run_events(actor: Node2D, events: int) -> void:
	actor_stepping.emit(tick, "4", actor)
	if events == 0:
		return
	for kind in GameEvents.KINDS:
		if events & kind:
			_execute(kind, actor)


func _execute(kind: int, actor: Node2D) -> void:
	var target: SimObject = null
	if kind == GameEvents.INTERACT:
		target = _interaction_target(actor)
		if target:
			target.interact(actor, tick)
	event_executed.emit(tick, kind, actor, target)


## E-10b: het object waarvan het interactievlak het lichaam nu overlapt en dat
## dit lichaam mag bedienen (E-06); bij meerdere het dichtstbijzijnde
## middelpunt, bij gelijke afstand het eerst toegevoegde.
func _interaction_target(actor: Node2D) -> SimObject:
	var best: SimObject = null
	var best_distance := INF
	for object in objects:
		if not object.is_interactable() or not object.overlaps(actor):
			continue
		var distance := object.global_position.distance_squared_to(actor.global_position)
		if distance < best_distance:
			best = object
			best_distance = distance
	return best
