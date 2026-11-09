extends Node2D
## De simulatieklok: één vaste tick per _physics_process (60 Hz).
##
## Volgorde per tick volgens E-07b (docs/design/gdd.md, ontwerp.md §2 en §4a):
##   (1) de schaduw: de echo zet zijn frame, óf P2 stapt (en wordt opgenomen)
##   (2) P1 stapt
##   (3) P1 wordt opgenomen; de echo verwerkt een reset van P1 (E-09, E-04b)
##   (4) events: eerst van P1, dan van de schaduw (E-10)
##   (5) objecten werken hun stand bij (drukplaten, hendels, later zones)
## Zo hangt het resultaat niet af van de volgorde van nodes in de boom.
##
## C-01 (max. twee lichamen) bewaakt de Sim zelf: er is hooguit één
## schaduwlichaam, de echo óf P2. Doet P2 mee, dan speelt er geen echo.

const PlayerActor = preload("res://scripts/echo/player_actor.gd")
const EchoBody = preload("res://scripts/echo/echo_body.gd")
const SimObject = preload("res://scripts/objects/sim_object.gd")
const GameEvents = preload("res://scripts/events/game_events.gd")
const Combat = preload("res://scripts/combat/combat.gd")
const CombatTarget = preload("res://scripts/combat/combat_target.gd")

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
var echoes: Array[EchoBody] = []
var objects: Array[SimObject] = []
## Aanval, schaduwmerk en kettingen (E-10a, E-14, E-02m, C-12).
var combat := Combat.new()


## Voegt een speler toe als C-01 dat toelaat: één P1 en hooguit één andere
## speler (P2). Een derde lichaam (een tweede P1, een tweede P2, of een
## index buiten 1–2 zoals P3) wordt geweigerd met `false`; de aanroeper ruimt de speler dan zelf op.
func add_player(player: PlayerActor) -> bool:
	if not can_add_player(player.player_index):
		return false
	players.append(player)
	players.sort_custom(func(a: PlayerActor, b: PlayerActor) -> bool:
		return a.player_index < b.player_index)
	add_child(player)
	# C-01: doet P2 mee, dan stopt het afspelen meteen. Waar P2 verschijnt
	# (C-03), regelt de drop-in (T16c), niet de Sim.
	if player.player_index != 1:
		for echo in echoes.duplicate():
			remove_echo(echo)
	return true


func can_add_player(player_index: int) -> bool:
	# Alleen P1 en P2 bestaan (C-01); een P3 of hoger komt er nooit bij.
	if player_index < 1 or player_index > 2:
		return false
	for other in players:
		if (other.player_index == 1) == (player_index == 1):
			return false
	return true


func remove_player(player: PlayerActor) -> void:
	players.erase(player)
	player.collision_layer = 0
	player.visible = false
	player.queue_free()


## Voegt een echo toe als C-01 dat toelaat: geen P2 in het spel en geen
## andere echo die nog speelt. Anders gebeurt er niets en is het antwoord
## `false`; de aanroeper ruimt de echo dan zelf op.
func add_echo(echo: EchoBody) -> bool:
	if not can_add_echo():
		return false
	echoes.append(echo)
	echo.combat = combat
	if "tail_ticks" in echo:
		combat.tail_ticks = echo.tail_ticks
	add_child(echo)
	return true


func can_add_echo() -> bool:
	if is_coop():
		return false
	for echo in echoes:
		if echo.is_active() or echo.is_present():
			return false
	return true


func remove_echo(echo: EchoBody) -> void:
	echoes.erase(echo)
	echo.stop()
	echo.queue_free()


func add_object(object: SimObject) -> void:
	objects.append(object)
	if object is CombatTarget:
		combat.add_target(object)
		object.hit_player.connect(_on_enemy_hit_player)
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
	# (0) merken die gedoofd zijn of op een dood doel zaten, gaan weg (E-14b).
	combat.begin_tick(tick)
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
	# Na (3): een echo reageert in dezelfde tick op Loslaten of respawn van
	# P1 (E-04b/c, E-09), zodat zijn events in (4) dan niet meer uitgaan.
	for echo in echoes:
		echo.sim_after_source(tick)
	# (4) events, eerst van P1, dan van de schaduw.
	for player in players:
		if player.player_index == 1:
			_run_events(player, player.tick_events)
	for echo in echoes:
		if echo.is_present():
			_run_events(echo, echo.tick_events)
			# E-02m: de echo laat op tick t + 3 zijn doelmerk ontploffen.
			if "detonate_mark" in echo and echo.detonate_mark != null:
				combat.detonate(tick, echo.detonate_mark)
	for player in players:
		if player.player_index != 1:
			_run_events(player, player.tick_events)
	# Kettingschakels van deze tick (E-14d), na alle events.
	combat.after_events(tick)
	# (5) objecten, in de volgorde van toevoegen, met de lichamen van deze tick.
	var present := bodies()
	for object in objects:
		actor_stepping.emit(tick, "5", object)
		object.sim_update(tick, present)
	tick_finished.emit(tick)
	# Een echo die deze tick zijn laatste frame speelde, verdwijnt nu pas en
	# gaat uit `echoes`. De node blijft bestaan tot zijn eigenaar hem opruimt
	# (`remove_echo` of `queue_free`), zodat die het resultaat nog kan lezen.
	for echo in echoes.duplicate():
		echo.sim_end_tick()
		if echo.finished and not echo.is_present():
			echoes.erase(echo)
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
	elif kind == GameEvents.ATTACK:
		# E-10a: aanvalsvlak in de (opgenomen) kijkrichting, 1 tick actief.
		var facing := 1
		var attacker := "echo"
		if actor is PlayerActor:
			facing = (actor as PlayerActor).motor.facing
			attacker = "p%d" % (actor as PlayerActor).player_index
		elif "facing" in actor:
			facing = actor.facing
		combat.attack(tick, attacker, (actor as CollisionObject2D).collision_layer,
			actor.global_position, facing)
	event_executed.emit(tick, kind, actor, target)


## Een aanvalsvlak van een vijand raakte P1 (§4.3, LM-05).
func _on_enemy_hit_player(hit_tick: int, player: Node2D) -> void:
	if player is PlayerActor:
		(player as PlayerActor).take_hit(hit_tick)


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
