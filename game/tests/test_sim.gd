extends RefCounted
## Tests voor de simulatieklok: de volgorde per tick uit E-07b (#14, #68) en
## de grens van twee lichamen uit C-01 (#68).
##
## E-07b: schaduw (echo of P2) -> P1 stapt -> P1 opgenomen -> events P1 ->
## events schaduw -> objecten.

const InputBits = preload("res://scripts/input/input_bits.gd")
const ScriptedInput = preload("res://scripts/input/scripted_input.gd")
const PlayerActor = preload("res://scripts/echo/player_actor.gd")
const EchoActor = preload("res://scripts/echo/echo_actor.gd")
const PressurePlate = preload("res://scripts/objects/pressure_plate.gd")
const Lever = preload("res://scripts/objects/lever.gd")
const GameEvents = preload("res://scripts/events/game_events.gd")
const Layers = preload("res://scripts/world/layers.gd")
const SpikeWorld = preload("res://scripts/world/spike_world.gd")

const R := InputBits.RIGHT
const L := InputBits.LEFT
const J := InputBits.JUMP
const I := InputBits.INTERACT


## Speler die bij elke stap noteert waar een ander lichaam op dat moment is.
class SpyPlayer extends PlayerActor:
	var watched: Node2D
	var seen: PackedVector2Array = []

	func sim_step(tick: int, delta: float) -> void:
		seen.append(watched.position)
		super.sim_step(tick, delta)


func _spawn_player(sim: Node, player: PlayerActor, index: int, segments: Array,
		offset := Vector2.ZERO) -> PlayerActor:
	player.setup(index, ScriptedInput.new(segments), Color.WHITE)
	player.position = SpikeWorld.PLAYER_SPAWN + offset
	sim.add_player(player)
	return player


func _start_echo(sim: Node, clip, echo_name := "Echo1") -> EchoActor:
	var echo := EchoActor.new()
	echo.setup(Color.BLACK)
	echo.name = echo_name
	if not sim.add_echo(echo):
		echo.free()
		return null
	echo.start(clip, EchoActor.Mode.STATE)
	return echo


func _add_plate(sim: Node, plate_name: String, owner: int, x: float) -> PressurePlate:
	var plate := PressurePlate.new()
	plate.name = plate_name
	plate.setup(owner, Vector2(48, 8))
	plate.position = Vector2(x, SpikeWorld.FLOOR_Y - 2.0)
	sim.add_object(plate)
	return plate


func _add_lever(sim: Node, lever_name: String, owner: int, x: float) -> Lever:
	var lever := Lever.new()
	lever.name = lever_name
	lever.setup(owner, Vector2(40, 40))
	lever.position = Vector2(x, SpikeWorld.PLAYER_SPAWN.y)
	sim.add_object(lever)
	return lever


func _log_phases(sim: Node, from_tick: int, lines: Array[String]) -> Callable:
	var log_step := func(tick: int, phase: String, actor: Node) -> void:
		if tick >= from_tick:
			lines.append("%d:%s:%s" % [tick, phase, actor.name])
	sim.actor_stepping.connect(log_step)
	return log_step


## Logtest E-07b stap 1–5, solo: per tick echo -> P1 stapt -> P1 opgenomen ->
## events P1 -> events echo -> objecten (in volgorde van toevoegen). De
## volgorde van toevoegen (objecten eerst, P1, dan de echo) doet er niet toe.
func test_tick_order_solo_steps_1_to_5(t) -> void:
	var sim = t.make_sim()
	var plate := _add_plate(sim, "Plate", Layers.SHADOW, 900.0)
	var lever := _add_lever(sim, "Lever", Layers.LIGHT | Layers.SHADOW, 900.0)
	var p1 := _spawn_player(sim, PlayerActor.new(), 1, [[60, R], [1, R | J], [59, R]])
	await t.run_ticks(sim, 120)
	_start_echo(sim, p1.recorder.snapshot())
	# Array, geen PackedStringArray: een lambda vangt packed arrays als kopie.
	var log_lines: Array[String] = []
	var first: int = sim.tick
	var log_step := _log_phases(sim, first, log_lines)
	await t.run_ticks(sim, 10)
	sim.actor_stepping.disconnect(log_step)
	var expected: Array[String] = []
	for tick in range(first, first + 10):
		expected.append_array(["%d:1:Echo1" % tick, "%d:2:%s" % [tick, p1.name],
			"%d:3:%s" % [tick, p1.name], "%d:4:%s" % [tick, p1.name], "%d:4:Echo1" % tick,
			"%d:5:%s" % [tick, plate.name], "%d:5:%s" % [tick, lever.name]])
	t.check(log_lines == expected, "volgorde %s, verwacht %s" % [
		str(log_lines.slice(0, 7)), str(expected.slice(0, 7))])
	t.note("tick %d: %s" % [first, ", ".join(PackedStringArray(log_lines.slice(0, 7)))])


## Logtest E-07b stap 1–5, co-op: P2 stapt als schaduw vóór P1; de events van
## P2 komen na die van P1.
func test_tick_order_coop_steps_1_to_5(t) -> void:
	var sim = t.make_sim()
	var p1 := _spawn_player(sim, PlayerActor.new(), 1, [[120, R]])
	var p2 := _spawn_player(sim, PlayerActor.new(), 2, [[120, R]], Vector2(400, 0))
	var plate := _add_plate(sim, "Plate", Layers.SHADOW, 900.0)
	var log_lines: Array[String] = []
	var first: int = sim.tick
	var log_step := _log_phases(sim, first, log_lines)
	await t.run_ticks(sim, 5)
	sim.actor_stepping.disconnect(log_step)
	var expected: Array[String] = []
	for tick in range(first, first + 5):
		expected.append_array(["%d:1:%s" % [tick, p2.name], "%d:2:%s" % [tick, p1.name],
			"%d:3:%s" % [tick, p1.name], "%d:4:%s" % [tick, p1.name],
			"%d:4:%s" % [tick, p2.name], "%d:5:%s" % [tick, plate.name]])
	t.check(log_lines == expected, "volgorde %s, verwacht %s" % [
		str(log_lines.slice(0, 6)), str(expected.slice(0, 6))])


## E-07b stap 4 en 5 met inhoud: P1 en de echo bedienen op dezelfde tick
## dezelfde gedeelde Wissel-hendel. Eerst P1 (om), dan de echo (terug), in
## dezelfde tick. Een schaduwplaat onder de echo ziet in stap 5 de positie
## van stap 1 van déze tick.
func test_events_p1_before_shadow_then_objects_same_tick(t) -> void:
	var sim = t.make_sim()
	var lever := _add_lever(sim, "Lever", Layers.LIGHT | Layers.SHADOW, SpikeWorld.PLAYER_SPAWN.x)
	var plate := _add_plate(sim, "Plate", Layers.SHADOW, SpikeWorld.PLAYER_SPAWN.x)
	# P1 staat stil bij de hendel en drukt INTERACTIE op lokale tick 30 en 90.
	var p1 := _spawn_player(sim, PlayerActor.new(), 1, [[30, 0], [1, I], [59, 0], [1, I], [29, 0]])
	await t.run_ticks(sim, 120)
	t.check(lever.on == false, "na twee bedieningen door P1 hoort de hendel uit te staan")
	var clip = p1.recorder.snapshot()
	var echo := _start_echo(sim, clip)
	# Nieuw script voor P1: weer stil, INTERACTIE 30 ticks na de start van de
	# echo, dus op dezelfde tick als de echo zijn eerste INTERACTIE afspeelt.
	p1.input_source = ScriptedInput.new([[30, 0], [1, I], [200, 0]])
	var log_lines: Array[String] = []
	var log_event := func(tick: int, kind: int, actor: Node2D, target: Node) -> void:
		log_lines.append("%d:%s:%s:%s" % [tick, GameEvents.describe(kind), actor.name,
			target.name if target else "-"])
	sim.event_executed.connect(log_event)
	var states: Array[bool] = []
	var on_lever := func(tick: int, on: bool, _by: Node2D) -> void:
		states.append(on)
	lever.changed.connect(on_lever)
	var plate_ticks: Array[int] = []
	var on_plate := func(tick: int, active: bool) -> void:
		plate_ticks.append(tick if active else -tick)
	plate.changed.connect(on_plate)
	var start: int = sim.tick
	# 121 ticks: de 120 frames van de clip plus de tick waarop de plaat ziet
	# dat de echo weg is.
	await t.run_ticks(sim, 121)
	sim.event_executed.disconnect(log_event)
	var x := start + 30
	var expected: Array[String] = ["%d:interactie:%s:Lever" % [x, p1.name],
		"%d:interactie:Echo1:Lever" % x, "%d:interactie:Echo1:Lever" % (start + 90)]
	t.check(log_lines == expected, "events %s, verwacht %s" % [str(log_lines), str(expected)])
	t.check(states == [true, false, true], "standen hendel %s, verwacht om/terug/om" % str(states))
	t.check(plate_ticks.size() >= 1 and plate_ticks[0] == start,
		"schaduwplaat ging aan op %s, verwacht op de eerste echo-tick %d" % [str(plate_ticks), start])
	t.check(echo != null and plate_ticks.has(-(start + clip.size())),
		"schaduwplaat ging niet uit op de tick na het laatste echo-frame: %s" % str(plate_ticks))
	t.note("events: %s" % ", ".join(PackedStringArray(log_lines)))


## Gevolg van E-07b (nodig voor E-07a): als P1 op tick t stapt, staat de echo
## al op zijn frame van tick t, niet op dat van t - 1. En P1 wordt in
## dezelfde tick opgenomen, na zijn stap (E-01).
func test_p1_sees_shadow_of_same_tick_and_is_recorded_after_step(t) -> void:
	var sim = t.make_sim()
	var source := _spawn_player(sim, PlayerActor.new(), 1, [[60, R], [1, R | J], [59, R]])
	await t.run_ticks(sim, 120)
	var clip = source.recorder.snapshot()
	sim.remove_player(source)
	var spy := SpyPlayer.new()
	_spawn_player(sim, spy, 1, [[120, R]], Vector2(-100, 0))
	var echo := _start_echo(sim, clip)
	spy.watched = echo
	var first: int = sim.tick
	await t.run_ticks(sim, 100)
	t.check(spy.seen.size() == 100, "P1 stapte %d keer, verwacht 100" % spy.seen.size())
	var lagging := 0
	for i in spy.seen.size():
		if spy.seen[i] != echo.trace[i]:
			lagging += 1
	t.check(lagging == 0, "%d ticks zag P1 de echo van de vorige tick" % lagging)
	t.check(echo.trace[99] != echo.trace[0], "echo bewoog niet; test zegt dan weinig")
	var recorded = spy.recorder.snapshot()
	t.check(recorded.ticks[0] == first and recorded.ticks[recorded.size() - 1] == first + 99,
		"opname P1 loopt van tick %d tot %d" % [recorded.ticks[0], recorded.ticks[recorded.size() - 1]])
	t.check(recorded.end_position() == spy.position, "laatste opgenomen frame is niet de positie na de stap")


## C-01 (gdd §4.3): gescripte sessie van 3000 ticks met twee drop-ins en twee
## drop-outs van P2, en een echo in elke solo-periode. Op elke tick: hooguit
## één schaduwlichaam en hooguit twee lichamen. Tijdens co-op is er geen
## echo-actor zichtbaar of vindbaar voor objecten, en lukt een nieuwe echo
## niet. Drop-in en drop-out zelf (C-03, C-05) bouwt T16c; hier is meedoen
## kaal `add_player` en stoppen `remove_player`.
func test_c01_never_more_than_two_bodies(t) -> void:
	var sim = t.make_sim()
	var walk := []
	for i in 30:
		walk.append_array([[50, R], [50, L]])
	var p1 := _spawn_player(sim, PlayerActor.new(), 1, walk)
	var stats := {"ticks": 0, "worst_shadow": 0, "worst_total": 0, "echo_in_coop": 0,
		"solo_echo_ticks": 0, "coop_ticks": 0}
	var on_tick := func(_tick: int) -> void:
		var shadow: Array[Node2D] = sim.shadow_bodies()
		var total: int = sim.bodies().size()
		stats["ticks"] += 1
		stats["worst_shadow"] = maxi(stats["worst_shadow"], shadow.size())
		stats["worst_total"] = maxi(stats["worst_total"], total)
		if sim.is_coop():
			stats["coop_ticks"] += 1
			for echo in sim.echoes:
				if echo.visible or echo.collision_layer != 0:
					stats["echo_in_coop"] += 1
		elif not shadow.is_empty():
			stats["solo_echo_ticks"] += 1
	sim.tick_finished.connect(on_tick)
	var refused := 0
	var p2: PlayerActor = null
	# [ticks wachten, actie]: echo = echo starten, in = P2 meedoen, uit = P2 stopt.
	var plan := [[600, "echo"], [200, "in"], [300, "echo"], [300, "uit"], [100, "echo"],
		[200, "in"], [300, "echo"], [300, "uit"], [100, "echo"], [600, ""]]
	for step: Array in plan:
		await t.run_ticks(sim, step[0])
		match step[1]:
			"echo":
				if _start_echo(sim, p1.recorder.snapshot()) == null:
					refused += 1
			"in":
				p2 = _spawn_player(sim, PlayerActor.new(), 2, walk, Vector2(300, 0))
			"uit":
				sim.remove_player(p2)
	sim.tick_finished.disconnect(on_tick)
	t.check(stats["ticks"] == 3000, "sessie duurde %d ticks, verwacht 3000" % stats["ticks"])
	t.check(stats["worst_shadow"] <= 1, "%d schaduwlichamen op één tick" % stats["worst_shadow"])
	t.check(stats["worst_total"] <= 2, "%d lichamen op één tick" % stats["worst_total"])
	t.check(stats["echo_in_coop"] == 0, "%d keer een zichtbare of botsende echo in co-op" % stats["echo_in_coop"])
	t.check(refused == 2, "%d echo's geweigerd, verwacht 2 (de twee pogingen tijdens co-op)" % refused)
	t.check(stats["coop_ticks"] == 1200, "co-op duurde %d ticks, verwacht 1200" % stats["coop_ticks"])
	# Echo's spelen 600-799, 1500-1699 en 2400-2999 (afgebroken door P2 of aan het einde).
	t.check(stats["solo_echo_ticks"] == 1000, "echo speelde %d ticks solo, verwacht 1000" % stats["solo_echo_ticks"])
	t.note("3000 ticks: max %d schaduwlichaam, max %d lichamen, %d echo-ticks solo, %d co-op-ticks" % [
		stats["worst_shadow"], stats["worst_total"], stats["solo_echo_ticks"], stats["coop_ticks"]])
