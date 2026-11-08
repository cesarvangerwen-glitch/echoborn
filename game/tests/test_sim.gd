extends RefCounted
## Tests voor de simulatieklok: de volgorde per tick uit E-07b (issue #14).
##
## E-07b: schaduw (echo of P2) -> P1 stapt -> P1 opgenomen -> events P1 ->
## events schaduw -> objecten. Events en objecten bestaan nog niet in de
## spike; deze tests dekken stap 1 t/m 3.

const InputBits = preload("res://scripts/input/input_bits.gd")
const ScriptedInput = preload("res://scripts/input/scripted_input.gd")
const PlayerActor = preload("res://scripts/echo/player_actor.gd")
const EchoActor = preload("res://scripts/echo/echo_actor.gd")
const SpikeWorld = preload("res://scripts/world/spike_world.gd")

const R := InputBits.RIGHT
const J := InputBits.JUMP


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


## Logtest E-07b: elke tick eerst de schaduw (echo, daarna P2), dan P1. De
## volgorde van toevoegen (P1 eerst, echo als laatste) doet er niet toe.
func test_tick_order_shadow_before_p1(t) -> void:
	var sim = t.make_sim()
	var p1 := _spawn_player(sim, PlayerActor.new(), 1, [[60, R], [1, R | J], [59, R]])
	var p2 := _spawn_player(sim, PlayerActor.new(), 2, [[120, R]], Vector2(400, 0))
	await t.run_ticks(sim, 120)
	var echo := EchoActor.new()
	echo.setup(Color.BLACK)
	echo.name = "Echo1"
	sim.add_echo(echo)
	echo.start(p1.recorder.snapshot(), EchoActor.Mode.STATE)
	sim.log_steps = true
	var first: int = sim.tick
	await t.run_ticks(sim, 10)
	sim.log_steps = false
	var expected := PackedStringArray()
	for tick in range(first, first + 10):
		expected.append("%d:1:Echo1" % tick)
		expected.append("%d:1:%s" % [tick, p2.name])
		expected.append("%d:2+3:%s" % [tick, p1.name])
	t.check(sim.step_log == expected, "volgorde %s, verwacht %s" % [
		str(sim.step_log.slice(0, 3)), str(expected.slice(0, 3))])
	t.note("tick %d: %s" % [first, ", ".join(sim.step_log.slice(0, 3))])


## Gevolg van E-07b (nodig voor E-07a): als P1 op tick t stapt, staat de echo
## al op zijn frame van tick t, niet op dat van t - 1. En P1 wordt in
## dezelfde tick opgenomen, na zijn stap (E-01).
func test_p1_sees_shadow_of_same_tick_and_is_recorded_after_step(t) -> void:
	var sim = t.make_sim()
	var source := _spawn_player(sim, PlayerActor.new(), 2, [[60, R], [1, R | J], [59, R]])
	await t.run_ticks(sim, 120)
	var spy := SpyPlayer.new()
	_spawn_player(sim, spy, 1, [[120, R]], Vector2(-100, 0))
	var echo := EchoActor.new()
	echo.setup(Color.BLACK)
	sim.add_echo(echo)
	echo.start(source.recorder.snapshot(), EchoActor.Mode.STATE)
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
	var clip = spy.recorder.snapshot()
	t.check(clip.ticks[0] == first and clip.ticks[clip.size() - 1] == first + 99,
		"opname P1 loopt van tick %d tot %d" % [clip.ticks[0], clip.ticks[clip.size() - 1]])
	t.check(clip.end_position() == spy.position, "laatste opgenomen frame is niet de positie na de stap")
