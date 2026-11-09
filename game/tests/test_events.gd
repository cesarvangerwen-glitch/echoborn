extends RefCounted
## Tests voor het event-systeem (#68): events uit de input (E-10), opgenomen
## en door de echo afgespeeld tegen de huidige wereld (E-10, E-06), en welk
## object een INTERACTIE bedient (E-10b).

const InputBits = preload("res://scripts/input/input_bits.gd")
const ScriptedInput = preload("res://scripts/input/scripted_input.gd")
const PlayerActor = preload("res://scripts/echo/player_actor.gd")
const EchoActor = preload("res://scripts/echo/echo_actor.gd")
const EventDetector = preload("res://scripts/events/event_detector.gd")
const GameEvents = preload("res://scripts/events/game_events.gd")
const Lever = preload("res://scripts/objects/lever.gd")
const Layers = preload("res://scripts/world/layers.gd")
const SpikeWorld = preload("res://scripts/world/spike_world.gd")

const A := InputBits.ACTION
const I := InputBits.INTERACT


func _events_for(script: Array) -> PackedInt32Array:
	var detector := EventDetector.new()
	var source := ScriptedInput.new(script)
	var ticks := PackedInt32Array()
	for tick in source.length():
		var events := detector.detect(tick, source.sample(tick))
		if events:
			ticks.append(tick)
	return ticks


## E-10: een event op de flank 0 -> 1; AANVAL met herhaaltijd 20 ticks.
func test_events_on_rising_edge_with_attack_cooldown(t) -> void:
	var held := _events_for([[5, 0], [60, A], [5, 0]])
	t.check(held == PackedInt32Array([5]), "AANVAL 60 ticks vast: events op %s, verwacht [5]" % str(held))
	var ten := _events_for([[5, 0], [1, A], [9, 0], [1, A], [5, 0]])
	t.check(ten == PackedInt32Array([5]), "twee flanken 10 ticks na elkaar: %s, verwacht één" % str(ten))
	var twenty := _events_for([[5, 0], [1, A], [19, 0], [1, A], [5, 0]])
	t.check(twenty == PackedInt32Array([5, 25]), "twee flanken 20 ticks na elkaar: %s, verwacht twee" % str(twenty))
	var interact := _events_for([[2, 0], [1, I], [1, 0], [1, I], [3, 0]])
	t.check(interact == PackedInt32Array([2, 4]), "INTERACTIE heeft geen herhaaltijd: %s" % str(interact))


func _setup_world(t, script: Array) -> Array:
	var sim = t.make_sim()
	var p1 := PlayerActor.new()
	p1.setup(1, ScriptedInput.new(script), Color.WHITE)
	p1.position = SpikeWorld.PLAYER_SPAWN
	sim.add_player(p1)
	return [sim, p1]


func _add_lever(sim: Node, lever_name: String, owner: int, offset: Vector2,
		size := Vector2(40, 40)) -> Lever:
	var lever := Lever.new()
	lever.name = lever_name
	lever.setup(owner, size)
	lever.position = SpikeWorld.PLAYER_SPAWN + offset
	sim.add_object(lever)
	return lever


## E-10 + E-06: P1 drukt INTERACTIE bij een schaduwhendel op tick `x`: er
## gebeurt niets, maar het event wordt opgenomen. De echo zet de hendel om
## op `x + N` (N = de afstand tussen opname en afspelen, hier 600 ticks).
func test_echo_replays_interaction_against_current_world(t) -> void:
	var world := _setup_world(t, [[100, 0], [1, I], [499, 0]])
	var sim = world[0]
	var p1: PlayerActor = world[1]
	var lever := _add_lever(sim, "ShadowLever", Layers.SHADOW, Vector2.ZERO)
	var changes: Array[int] = []
	var on_change := func(tick: int, _on: bool, _by: Node2D) -> void:
		changes.append(tick)
	lever.changed.connect(on_change)
	var start: int = sim.tick
	await t.run_ticks(sim, 600)
	t.check(changes.is_empty(), "P1 zette een schaduwhendel om (E-06)")
	var clip = p1.recorder.snapshot()
	t.check(clip.events[100] == GameEvents.INTERACT, "INTERACTIE van P1 niet opgenomen op frame 100")
	var echo := EchoActor.new()
	echo.setup(Color.BLACK)
	sim.add_echo(echo)
	echo.start(clip, EchoActor.Mode.STATE)
	await t.run_ticks(sim, 600)
	var x := start + 100
	t.check(changes == [x + 600], "hendel ging om op %s, verwacht [%d]" % [str(changes), x + 600])
	t.check(lever.on, "schaduwhendel staat niet om na de echo")


## E-10b: twee hendels overlappen het lichaam bij een INTERACTIE: alleen de
## dichtstbijzijnde gaat om. Een lichthendel die dichterbij is, telt voor de
## echo niet mee (E-06).
func test_interaction_picks_nearest_accepted_object(t) -> void:
	var world := _setup_world(t, [[10, 0], [1, I], [9, 0]])
	var sim = world[0]
	var near := _add_lever(sim, "Near", Layers.LIGHT | Layers.SHADOW, Vector2(6, 0))
	var far := _add_lever(sim, "Far", Layers.LIGHT | Layers.SHADOW, Vector2(-14, 0))
	await t.run_ticks(sim, 20)
	t.check(near.on and not far.on, "P1: dichtstbijzijnde hendel moet om (near %s, far %s)" % [near.on, far.on])
	var clip = (world[1] as PlayerActor).recorder.snapshot()
	near.on = false
	var light := _add_lever(sim, "LightNearest", Layers.LIGHT, Vector2(1, 0))
	var echo := EchoActor.new()
	echo.setup(Color.BLACK)
	sim.add_echo(echo)
	echo.start(clip, EchoActor.Mode.STATE)
	await t.run_ticks(sim, 20)
	t.check(near.on and not far.on and not light.on,
		"echo: verwacht alleen Near om (near %s, far %s, licht %s)" % [near.on, far.on, light.on])
