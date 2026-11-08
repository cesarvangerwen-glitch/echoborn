extends RefCounted
## Tests voor de echo-spike (issue #5).
##
## Kern: na 10 s (600 ticks) opnemen bereikt de echo exact dezelfde positie
## als het origineel. Daarnaast tests die de grenzen van input-opname
## vastleggen, zodat ze zichtbaar blijven als de engine of code verandert.

const InputBits = preload("res://scripts/input/input_bits.gd")
const ScriptedInput = preload("res://scripts/input/scripted_input.gd")
const PlayerActor = preload("res://scripts/echo/player_actor.gd")
const EchoActor = preload("res://scripts/echo/echo_actor.gd")
const EchoRecorder = preload("res://scripts/echo/echo_recorder.gd")
const SpikeWorld = preload("res://scripts/world/spike_world.gd")

const TEN_SECONDS := 600

const L := InputBits.LEFT
const R := InputBits.RIGHT
const J := InputBits.JUMP
const A := InputBits.ACTION

## 600 ticks lopen, springen, omkeren en stilstaan (P1).
const SCRIPT_P1 := [
	[20, 0], [60, R], [1, R | J], [50, R], [30, 0], [40, L], [1, J], [40, 0],
	[90, R], [1, R | J], [60, R], [40, L | A], [1, L | J], [80, L], [86, 0],
]
## 600 ticks met een ander patroon (P2), gelijktijdig met P1.
const SCRIPT_P2 := [
	[10, 0], [1, J], [45, 0], [120, R], [1, R | J], [30, R], [5, 0], [1, J],
	[60, L], [1, L | J], [100, L], [30, 0], [80, R], [1, J], [115, 0],
]
## Wat de spelers doen terwijl hun echo afspeelt.
const SCRIPT_LIVE := [[100, L], [1, J], [200, R], [1, R | J], [400, 0]]


func _spawn_player(sim: Node, index: int, segments: Array, offset := Vector2.ZERO) -> PlayerActor:
	var player := PlayerActor.new()
	player.setup(index, ScriptedInput.new(segments), Color.WHITE)
	player.position = SpikeWorld.PLAYER_SPAWN + offset
	sim.add_player(player)
	return player


func _spawn_echo(sim: Node, clip, mode: EchoActor.Mode) -> EchoActor:
	var echo := EchoActor.new()
	echo.setup(Color.BLACK)
	sim.add_echo(echo)
	echo.start(clip, mode)
	return echo


func _fmt(v: Vector2) -> String:
	return "(%.4f, %.4f)" % [v.x, v.y]


## Kern-DoD: toestand-opname -> echo eindigt exact op de positie van het origineel.
func test_state_echo_reaches_same_position(t) -> void:
	var sim = t.make_sim()
	var player := _spawn_player(sim, 1, SCRIPT_P1)
	await t.run_ticks(sim, TEN_SECONDS)
	var original_end := player.position
	var clip = player.recorder.snapshot()
	t.check(clip.size() == TEN_SECONDS, "clip heeft %d frames, verwacht %d" % [clip.size(), TEN_SECONDS])
	t.check(original_end.distance_to(clip.start_position()) > 100.0,
		"origineel moet echt bewogen hebben (afstand %.1f)" % original_end.distance_to(clip.start_position()))
	var echo := _spawn_echo(sim, clip, EchoActor.Mode.STATE)
	await t.run_ticks(sim, TEN_SECONDS)
	t.check(echo.finished, "echo is niet klaar met afspelen")
	t.check(echo.position == original_end,
		"eindpositie echo %s != origineel %s" % [_fmt(echo.position), _fmt(original_end)])
	t.check(echo.max_deviation() == 0.0, "max afwijking %f px, verwacht 0" % echo.max_deviation())
	t.note("origineel eind %s, echo eind %s, max afwijking %.6f px over %d ticks" % [
		_fmt(original_end), _fmt(echo.position), echo.max_deviation(), echo.trace.size()])


## Input-opname in een ongewijzigde wereld: dezelfde Motor, dezelfde input
## -> dezelfde positie (binnen deze build en machine bit-exact).
func test_input_echo_reaches_same_position(t) -> void:
	var sim = t.make_sim()
	var player := _spawn_player(sim, 1, SCRIPT_P1)
	await t.run_ticks(sim, TEN_SECONDS)
	var original_end := player.position
	var clip = player.recorder.snapshot()
	var echo := _spawn_echo(sim, clip, EchoActor.Mode.INPUT)
	await t.run_ticks(sim, TEN_SECONDS)
	t.check(echo.finished, "echo is niet klaar met afspelen")
	t.check(echo.position.distance_to(original_end) < 0.001,
		"eindpositie echo %s != origineel %s" % [_fmt(echo.position), _fmt(original_end)])
	t.note("input-replay: max afwijking %.6f px, eind %s vs %s" % [
		echo.max_deviation(), _fmt(echo.position), _fmt(original_end)])


## De ringbuffer houdt precies de laatste 10 s vast, aaneengesloten.
func test_ring_buffer_keeps_last_10_seconds(t) -> void:
	var sim = t.make_sim()
	var player := _spawn_player(sim, 1, SCRIPT_P1 + SCRIPT_LIVE)
	await t.run_ticks(sim, 900)
	var clip = player.recorder.snapshot()
	t.check(player.recorder.size() == TEN_SECONDS, "recorder bevat %d frames" % player.recorder.size())
	t.check(clip.ticks[0] == 300, "oudste tick %d, verwacht 300" % clip.ticks[0])
	t.check(clip.ticks[clip.size() - 1] == 899, "nieuwste tick %d, verwacht 899" % clip.ticks[clip.size() - 1])
	t.check(clip.end_position() == player.position, "laatste frame is niet de huidige positie")
	var gaps := 0
	for i in range(1, clip.size()):
		if clip.pre_pos[i] != clip.post_pos[i - 1] or clip.ticks[i] != clip.ticks[i - 1] + 1:
			gaps += 1
	t.check(gaps == 0, "%d gaten in de opname" % gaps)


## Co-op: twee spelers tegelijk, elk een eigen recorder en echo; de spelers
## blijven live bewegen terwijl hun echo's afspelen.
func test_two_players_each_get_exact_echo(t) -> void:
	var sim = t.make_sim()
	var p1 := _spawn_player(sim, 1, SCRIPT_P1 + SCRIPT_LIVE)
	var p2 := _spawn_player(sim, 2, SCRIPT_P2 + SCRIPT_LIVE, Vector2(400, 0))
	await t.run_ticks(sim, TEN_SECONDS)
	var end1 := p1.position
	var end2 := p2.position
	var echo1_state := _spawn_echo(sim, p1.recorder.snapshot(), EchoActor.Mode.STATE)
	var echo2_state := _spawn_echo(sim, p2.recorder.snapshot(), EchoActor.Mode.STATE)
	var echo1_input := _spawn_echo(sim, p1.recorder.snapshot(), EchoActor.Mode.INPUT)
	var echo2_input := _spawn_echo(sim, p2.recorder.snapshot(), EchoActor.Mode.INPUT)
	await t.run_ticks(sim, TEN_SECONDS)
	t.check(echo1_state.position == end1, "P1 state-echo %s != %s" % [_fmt(echo1_state.position), _fmt(end1)])
	t.check(echo2_state.position == end2, "P2 state-echo %s != %s" % [_fmt(echo2_state.position), _fmt(end2)])
	t.check(echo1_input.position.distance_to(end1) < 0.001, "P1 input-echo %s != %s" % [_fmt(echo1_input.position), _fmt(end1)])
	t.check(echo2_input.position.distance_to(end2) < 0.001, "P2 input-echo %s != %s" % [_fmt(echo2_input.position), _fmt(end2)])
	t.check(end1.distance_to(end2) > 1.0, "P1 en P2 eindigen op dezelfde plek; test zegt dan weinig")
	t.check(p1.position != end1 and p2.position != end2, "spelers bewogen niet live tijdens het afspelen")
	t.note("P1 eind %s, P2 eind %s; spelers live verder naar %s / %s" % [
		_fmt(end1), _fmt(end2), _fmt(p1.position), _fmt(p2.position)])


## Grens van input-opname: verandert de wereld, dan wijkt de input-echo af.
## De toestand-echo blijft exact. (Legt het risico vast; geen bug.)
func test_world_change_breaks_input_echo_not_state_echo(t) -> void:
	var sim = t.make_sim()
	var player := _spawn_player(sim, 1, SCRIPT_P1)
	await t.run_ticks(sim, TEN_SECONDS)
	var clip = player.recorder.snapshot()
	# Er verschijnt een blok op het pad (bv. een deur die dichtging).
	SpikeWorld.add_block(t.world_root(), "Obstacle", Vector2(330, SpikeWorld.FLOOR_Y - 20), Vector2(20, 40))
	await t.run_ticks(sim, 1)
	var state_echo := _spawn_echo(sim, clip, EchoActor.Mode.STATE)
	var input_echo := _spawn_echo(sim, clip, EchoActor.Mode.INPUT)
	await t.run_ticks(sim, TEN_SECONDS)
	t.check(state_echo.max_deviation() == 0.0, "state-echo week af: %f px" % state_echo.max_deviation())
	t.check(input_echo.max_deviation() > 10.0,
		"input-echo zou moeten afwijken door het obstakel, afwijking %f px" % input_echo.max_deviation())
	t.note("na wereldwijziging: state-echo %.3f px, input-echo %.1f px max afwijking" % [
		state_echo.max_deviation(), input_echo.max_deviation()])


## Grens van input-opname: verborgen toestand (is_on_floor) zit niet in
## positie+snelheid. Begint de clip met een sprong vanaf de vloer, dan
## springt een vers gespawnde input-echo niet.
func test_hidden_state_breaks_input_echo_at_clip_start(t) -> void:
	var sim = t.make_sim()
	var player := _spawn_player(sim, 1, [[30, 0], [1, J], [200, R], [369, 0]])
	await t.run_ticks(sim, 30)
	player.recorder.clear()
	await t.run_ticks(sim, TEN_SECONDS)
	var clip = player.recorder.snapshot()
	t.check(clip.pre_on_floor[0] == 1 and clip.inputs[0] & J, "clip moet beginnen met een sprong vanaf de vloer")
	var state_echo := _spawn_echo(sim, clip, EchoActor.Mode.STATE)
	var input_echo := _spawn_echo(sim, clip, EchoActor.Mode.INPUT)
	await t.run_ticks(sim, TEN_SECONDS)
	t.check(state_echo.max_deviation() == 0.0, "state-echo week af: %f px" % state_echo.max_deviation())
	t.check(input_echo.max_deviation() > 10.0,
		"input-echo zou de eerste sprong missen, afwijking %f px" % input_echo.max_deviation())
	t.note("verborgen vloer-toestand: state-echo %.3f px, input-echo %.1f px max afwijking" % [
		state_echo.max_deviation(), input_echo.max_deviation()])


## Geheugen/kosten: 10 s opnemen is goedkoop en alloceert niet per tick.
func test_recorder_snapshot_is_independent_copy(t) -> void:
	var recorder := EchoRecorder.new(4)
	for i in 6:
		recorder.push(i, i, Vector2(i, 0), Vector2.ZERO, false, Vector2(i + 1, 0), Vector2.ZERO)
	var clip = recorder.snapshot()
	t.check(clip.size() == 4, "clip-grootte %d" % clip.size())
	t.check(clip.ticks[0] == 2 and clip.ticks[3] == 5, "verkeerde volgorde: %s" % str(clip.ticks))
	recorder.push(6, 6, Vector2(6, 0), Vector2.ZERO, false, Vector2(7, 0), Vector2.ZERO)
	t.check(clip.ticks[0] == 2, "clip veranderde mee met de recorder")
	var last2 = recorder.snapshot(2)
	t.check(last2.size() == 2 and last2.ticks[0] == 5 and last2.ticks[1] == 6, "snapshot(2) = %s" % str(last2.ticks))
