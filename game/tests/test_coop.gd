extends RefCounted
## Tests voor co-op 7A, deel 1 (T16c, #78): gdd §2.7 en §4.6, regels C-01,
## C-03, C-04, C-05, C-09, C-10, C-11 en C-13.
##
## Lichamen zijn 16 × 30 px. Op de vloer staat een middelpunt op y = 385
## (bovenkant 370); een lichaam dat op een ander staat, op y = 355.
## Solo-gevallen gebruiken een spookbron met D = 1 (EchoFixture.ghost).

const Fx = preload("res://tests/echo_fixture.gd")
const InputBits = preload("res://scripts/input/input_bits.gd")
const PlayerActor = preload("res://scripts/echo/player_actor.gd")
const TailEcho = preload("res://scripts/echo/tail_echo.gd")
const Motor = preload("res://scripts/echo/motor.gd")
const Layers = preload("res://scripts/world/layers.gd")
const GameEvents = preload("res://scripts/events/game_events.gd")

const L := InputBits.LEFT
const R := InputBits.RIGHT
const J := InputBits.JUMP
const A := InputBits.ATTACK
const D := InputBits.DASH
const E := InputBits.ECHO
const ALL_D := [90, 120, 180]
const TOP := Fx.STAND_Y - 15.0      ## bovenkant van een lichaam op de vloer (370)
const ON_TOP := Fx.ON_ECHO_Y        ## middelpunt van een lichaam erop (355)
const EPS := 0.01


# --- hulpmiddelen ----------------------------------------------------------

## Wereld met P1 en P2 (handmatige input) op `p1_at` en `p2_at`.
func _pair(t, p1_at: Vector2, p2_at: Vector2) -> Dictionary:
	var sim = Fx.world(t)
	var p1 := Fx.manual_player(sim, 1, p1_at)
	var p2 := Fx.manual_player(sim, 2, p2_at)
	return {"sim": sim, "p1": p1, "p2": p2}


## Per tick (na stap 5): positie, snelheid, steun en bewegingsevents.
func _log(sim: Node, p: PlayerActor) -> Array:
	var rows: Array = []
	sim.tick_finished.connect(func(tick: int) -> void:
		rows.append({"tick": tick, "pos": p.position, "vel": p.motor.velocity,
			"floor": p.motor.on_floor, "support": p.motor.support,
			"ev": p.move_events, "dash_ready": p.motor.dash_ready,
			"launch": p.motor.launch_left}))
	return rows


func _first(rows: Array, event: int, from := 0) -> int:
	for i in range(from, rows.size()):
		if rows[i]["ev"] & event:
			return i
	return -1


func _count(rows: Array, event: int) -> int:
	var n := 0
	for row: Dictionary in rows:
		if row["ev"] & event:
			n += 1
	return n


func _bits(p: PlayerActor, bits: int) -> void:
	(p.input_source as Fx.ManualInput).bits = bits


## Stilstaande solo-echo (spookbron, D = 1) op (x, vloer). `held_from` ≥ 0:
## AANVAL-event op frame 0 en AANVAL ingedrukt op alle frames (houding vanaf
## frame 12); -1: geen AANVAL.
func _still_echo(t, sim: Node, x: float, held: bool) -> TailEcho:
	var ghost := Fx.ghost(t)
	var at := Vector2(x, Fx.STAND_Y)
	for k in 600:
		var events := GameEvents.ATTACK if held and k == 0 else 0
		ghost.recorder.push(k, 0, at, Vector2.ZERO, true, at, Vector2.ZERO, events,
			true, 1, Motor.Support.WORLD, 0, held)
	return Fx.tail_echo(sim, ghost, 1)


# --- C-10 bounce in beide richtingen ---------------------------------------

func test_c10_bounce_p1_on_p2_and_p2_on_p1(t) -> void:
	for springer_index in [1, 2]:
		var carrier_at := Vector2(300, Fx.STAND_Y)
		var springer_at := Vector2(300, ON_TOP - 15.0)   # 15 px boven: geen vang
		var a := _pair(t, springer_at if springer_index == 1 else carrier_at,
			carrier_at if springer_index == 1 else springer_at)
		var springer: PlayerActor = a["p%d" % springer_index]
		var rows := _log(a["sim"], springer)
		await t.run_ticks(a["sim"], 20)
		var land := _first(rows, Motor.EV_SPRINGPLANK)
		t.check(land > 0 and rows[land]["vel"].y == 0.0 and rows[land]["dash_ready"],
			"P%d: springplank-landing op de ander (tick %d)" % [springer_index, land])
		t.check(_count(rows, Motor.EV_CATCH) == 0, "P%d: vang bij een lage val" % springer_index)
		t.check(absf(springer.position.y - ON_TOP) < EPS and springer.motor.support == Motor.Support.SHADOW_BODY,
			"P%d staat niet op de ander: y = %.2f" % [springer_index, springer.position.y])
		_bits(springer, J)
		await t.run_ticks(a["sim"], 1)
		_bits(springer, 0)
		var jump := rows.size() - 1
		await t.run_ticks(a["sim"], 50)
		t.check(rows[jump]["ev"] & Motor.EV_BOUNCE != 0, "P%d: geen BOUNCE vanaf de ander" % springer_index)
		var top := INF
		for i in range(jump, rows.size()):
			top = minf(top, rows[i]["pos"].y)
		var height := ON_TOP - top
		t.check(height >= 70.0 and height <= 74.0, "P%d: bounce %.2f px hoog (70–74)" % [springer_index, height])
		await t.cleanup()


# --- C-09 drager, plank en volgorde ----------------------------------------

func test_c09_order_p2_carried_by_p1_same_tick(t) -> void:
	var a := _pair(t, Vector2(300, Fx.STAND_Y), Vector2(300, ON_TOP))
	var p1: PlayerActor = a["p1"]
	var p2: PlayerActor = a["p2"]
	var order: Array = []
	a["sim"].actor_stepping.connect(func(tick: int, phase: String, actor: Node) -> void:
		if tick == 20 and (phase == "1" or phase == "2"):
			order.append(str(actor.name)))
	await t.run_ticks(a["sim"], 5)
	var rows1 := _log(a["sim"], p1)
	var rows2 := _log(a["sim"], p2)
	_bits(p1, R)
	await t.run_ticks(a["sim"], 30)
	var off := 0
	for i in range(1, rows1.size()):
		var dx1: float = rows1[i]["pos"].x - rows1[i - 1]["pos"].x
		var dx2: float = rows2[i]["pos"].x - rows2[i - 1]["pos"].x
		if absf(dx1 - 2.0) > EPS or absf(dx2 - 2.0) > EPS:
			off += 1
	t.check(off == 0, "%d ticks liep P2 niet 2,0 px mee in dezelfde tick als P1" % off)
	t.check(order == ["Player1", "Player2"], "volgording op P1: %s (P1, dan P2)" % str(order))
	await t.cleanup()
	# Zonder dat P2 op P1 staat: eerst P2.
	a = _pair(t, Vector2(200, Fx.STAND_Y), Vector2(400, Fx.STAND_Y))
	order = []
	a["sim"].actor_stepping.connect(func(tick: int, phase: String, actor: Node) -> void:
		if tick == 3 and (phase == "1" or phase == "2"):
			order.append(str(actor.name)))
	await t.run_ticks(a["sim"], 5)
	t.check(order == ["Player2", "Player1"], "volgorde los: %s (P2, dan P1)" % str(order))
	await t.cleanup()


func test_c09_light_plank_only_in_coop_and_one_way(t) -> void:
	# Solo: P1 heeft geen lichtplank aan.
	var sim = Fx.world(t)
	var p1 := Fx.manual_player(sim, 1, Vector2(300, Fx.STAND_Y))
	await t.run_ticks(sim, 3)
	t.check(p1.plank.collision_layer == 0, "solo: lichtplank aan (laag %d)" % p1.plank.collision_layer)
	await t.cleanup()
	# Co-op: aan op laag 8; P2 van opzij loopt erdoor.
	var a := _pair(t, Vector2(300, Fx.STAND_Y), Vector2(260, Fx.STAND_Y))
	await t.run_ticks(a["sim"], 2)
	t.check(a["p1"].plank.collision_layer == Layers.LIGHT_PLANK, "co-op: lichtplank laag %d (8)" % a["p1"].plank.collision_layer)
	t.check(a["p2"].plank.collision_layer == Layers.PLANK, "co-op: schaduwplank P2 laag %d (6)" % a["p2"].plank.collision_layer)
	_bits(a["p2"], R)
	await t.run_ticks(a["sim"], 50)
	t.check(a["p2"].position.x > 340.0 and absf(a["p2"].position.y - Fx.STAND_Y) < 0.1,
		"P2 liep niet door P1 heen: %s" % a["p2"].position)
	await t.cleanup()


func test_c09_ladder_rule(t) -> void:
	# P1 staat op P2: P1 stond op een plank, dus zijn lichtplank draagt niet.
	var a := _pair(t, Vector2(300, ON_TOP), Vector2(300, Fx.STAND_Y))
	await t.run_ticks(a["sim"], 5)
	var p1: PlayerActor = a["p1"]
	t.check(p1.motor.support == Motor.Support.SHADOW_BODY and not p1.carrier_valid()
		and p1.plank.collision_layer == 0, "P1 op P2 draagt nog (ladder)")
	# P1 stapt eraf op de vloer: draagt weer.
	_bits(p1, R)
	await t.run_ticks(a["sim"], 30)
	_bits(p1, 0)
	await t.run_ticks(a["sim"], 2)
	t.check(p1.motor.support == Motor.Support.WORLD and p1.carrier_valid()
		and p1.plank.collision_layer == Layers.LIGHT_PLANK, "P1 draagt niet na grondcontact")
	await t.cleanup()
	# P1 bouncet van P2; P2 valt daarna op P1 terwijl P1 in de lucht is: erdoor.
	a = _pair(t, Vector2(300, ON_TOP - 10.0), Vector2(300, Fx.STAND_Y))
	p1 = a["p1"]
	var p2: PlayerActor = a["p2"]
	await t.run_ticks(a["sim"], 10)
	_bits(p1, J)
	await t.run_ticks(a["sim"], 1)
	_bits(p1, 0)
	await t.run_ticks(a["sim"], 6)
	# P2 springt nu: P1 is nog in de lucht boven hem (stond op een plank).
	_bits(p2, J)
	await t.run_ticks(a["sim"], 1)
	_bits(p2, 0)
	var rows2 := _log(a["sim"], p2)
	await t.run_ticks(a["sim"], 60)
	t.check(_count(rows2, Motor.EV_SPRINGPLANK) == 0 and _count(rows2, Motor.EV_CATCH) == 0,
		"P2 landde op P1 die sinds zijn grondcontact op een plank stond")
	await t.cleanup()


# --- C-11 lancering ----------------------------------------------------------

## P1 staat op P2; P2 slaat op x en houdt `hold` ticks AANVAL vast.
func _stance_setup(t, hold: int, wall := false) -> Dictionary:
	var a := _pair(t, Vector2(300, ON_TOP), Vector2(300, Fx.STAND_Y))
	if wall:
		# Muur 40 px rechts van P1 (rechterkant 308), boven de bovenkant van P2.
		Fx.block(t, "Wall", Rect2(348, 200, 20, 160), Layers.WORLD)
	await t.run_ticks(a["sim"], 5)
	a["rows"] = _log(a["sim"], a["p1"])
	a["x"] = a["sim"].tick
	_bits(a["p2"], A)
	await t.run_ticks(a["sim"], hold)
	_bits(a["p2"], 0)
	return a


func test_c11a_stance_after_12_ticks(t) -> void:
	var a := await _stance_setup(t, 20)
	var rows: Array = a["rows"]
	var launch := _first(rows, Motor.EV_LAUNCH)
	t.check(launch == 12, "lancering op x + %d (12)" % launch)
	t.check(_count(rows, Motor.EV_LAUNCH) == 1, "%d lanceringen (1)" % _count(rows, Motor.EV_LAUNCH))
	await t.cleanup()
	a = await _stance_setup(t, 11)
	await t.run_ticks(a["sim"], 20)
	t.check(_count(a["rows"], Motor.EV_LAUNCH) == 0, "lancering na 11 ticks vasthouden")
	await t.cleanup()


func test_c11a_launch_on_landing_tick(t) -> void:
	# P2 houdt 200 ticks vast; P1 landt (laag, geen vang) op x + 150. P1 wacht
	# opzij op de vloer, binnen het camerabeeld (anders lost P2 op, C-07).
	var a := _pair(t, Vector2(500, Fx.STAND_Y), Vector2(300, Fx.STAND_Y))
	var p1: PlayerActor = a["p1"]
	var rows := _log(a["sim"], p1)
	_bits(a["p2"], A)
	await t.run_ticks(a["sim"], 140)
	p1.position = Vector2(300, ON_TOP - 15.0)
	p1.motor.velocity = Vector2.ZERO
	await t.run_ticks(a["sim"], 30)
	var land := _first(rows, Motor.EV_LAUNCH)
	t.check(land > 140 and rows[land]["floor"] and rows[land]["support"] == Motor.Support.SHADOW_BODY,
		"geen lancering op de landingstick (tick %d)" % land)
	t.check(_count(rows, Motor.EV_SPRINGPLANK) == 0 or _first(rows, Motor.EV_SPRINGPLANK) >= land,
		"springplank-landing zonder lancering")
	await t.cleanup()


func test_c11b_launch_motion(t) -> void:
	# LEFT op t + 5 verandert v.x niet; op t + 31 gewone beweging.
	var a := await _stance_setup(t, 13)
	var rows: Array = a["rows"]
	var p1: PlayerActor = a["p1"]
	var launch := _first(rows, Motor.EV_LAUNCH)
	await t.run_ticks(a["sim"], 4 - (rows.size() - 1 - launch))
	_bits(p1, L)
	await t.run_ticks(a["sim"], 40)
	var bad := 0
	for k in range(1, 31):
		if rows[launch + k]["vel"].x != 4.0:
			bad += 1
	t.check(bad == 0, "%d ticks in lanceerstaat zonder v.x = 4,0" % bad)
	t.check(rows[launch + 1]["dash_ready"], "geen dash terug op t + 1")
	t.check(rows[launch + 31]["vel"].x == -2.0 and rows[launch + 31]["launch"] == 0,
		"t + 31: v.x %.2f (−2,0, gewone beweging)" % rows[launch + 31]["vel"].x)
	await t.cleanup()
	# Top en afstand met RIGHT, zonder dash.
	a = await _stance_setup(t, 13)
	rows = a["rows"]
	p1 = a["p1"]
	_bits(p1, R)
	await t.run_ticks(a["sim"], 80)
	launch = _first(rows, Motor.EV_LAUNCH)
	var x0: float = rows[launch]["pos"].x
	var top := INF
	var cross := -1.0
	for i in range(launch + 1, rows.size()):
		var y: float = rows[i]["pos"].y
		top = minf(top, y)
		if cross < 0.0 and i > launch + 5 and y >= ON_TOP:
			var prev: Dictionary = rows[i - 1]
			var f: float = (ON_TOP - prev["pos"].y) / (y - prev["pos"].y)
			cross = lerpf(prev["pos"].x, rows[i]["pos"].x, f) - x0
	var height := ON_TOP - top
	t.check(height >= 112.0 and height <= 117.0, "top %.2f px boven de plank (112–117)" % height)
	t.check(cross >= 176.0 and cross <= 188.0, "op plankhoogte %.2f px verder (176–188)" % cross)
	t.note("lancering: top %.2f px, %.2f px op plankhoogte" % [height, cross])
	await t.cleanup()


func test_c11b_jump_on_launch_tick_is_launch(t) -> void:
	var a := _pair(t, Vector2(300, ON_TOP), Vector2(300, Fx.STAND_Y))
	await t.run_ticks(a["sim"], 5)
	var rows := _log(a["sim"], a["p1"])
	_bits(a["p2"], A)
	await t.run_ticks(a["sim"], 12)
	_bits(a["p1"], J)
	await t.run_ticks(a["sim"], 1)
	_bits(a["p1"], 0)
	await t.run_ticks(a["sim"], 3)
	var launch := _first(rows, Motor.EV_LAUNCH)
	t.check(launch == 12 and _count(rows, Motor.EV_BOUNCE) == 0,
		"JUMP op t: lancering %d, %d bounces (lancering, geen bounce)" % [launch, _count(rows, Motor.EV_BOUNCE)])
	t.check(rows[launch + 1]["vel"].x == 4.0, "na JUMP + lancering v.x %.2f (4,0)" % rows[launch + 1]["vel"].x)
	await t.cleanup()


func test_c11b_p2_launched_by_p1(t) -> void:
	var a := _pair(t, Vector2(300, Fx.STAND_Y), Vector2(300, ON_TOP))
	await t.run_ticks(a["sim"], 5)
	var rows := _log(a["sim"], a["p2"])
	_bits(a["p1"], A)
	await t.run_ticks(a["sim"], 15)
	_bits(a["p1"], 0)
	await t.run_ticks(a["sim"], 5)
	var launch := _first(rows, Motor.EV_LAUNCH)
	t.check(launch == 12 and rows[launch + 1]["vel"].x == 4.0, "P2 op P1: lancering op %d (12)" % launch)
	await t.cleanup()


func test_c11c_wall_and_dash_end_launch(t) -> void:
	var a := await _stance_setup(t, 13, true)
	await t.run_ticks(a["sim"], 30)
	var rows: Array = a["rows"]
	var launch := _first(rows, Motor.EV_LAUNCH)
	var hit := -1
	for i in range(launch + 1, rows.size()):
		if rows[i]["vel"].x == 0.0:
			hit = i
			break
	t.check(launch >= 0 and hit > launch and rows[hit]["launch"] == 0,
		"muur: lanceerstaat niet uit bij de botsing (tick %d)" % hit)
	await t.cleanup()
	a = await _stance_setup(t, 13)
	rows = a["rows"]
	launch = _first(rows, Motor.EV_LAUNCH)
	await t.run_ticks(a["sim"], 9 - (rows.size() - 1 - launch))
	_bits(a["p1"], D)
	await t.run_ticks(a["sim"], 1)
	_bits(a["p1"], 0)
	await t.run_ticks(a["sim"], 15)
	t.check(rows[launch + 10]["ev"] & Motor.EV_DASH != 0 and rows[launch + 10]["launch"] == 0,
		"DASH op t + 10 nam de lancering niet over")
	t.check(rows[launch + 21]["vel"].x == 0.0, "na de dash nog lanceerstaat: v.x %.2f" % rows[launch + 21]["vel"].x)
	await t.cleanup()


func test_c11d_no_second_launch_without_new_hit(t) -> void:
	# P2 blijft vasthouden; P1 landt na de lancering opnieuw op P2.
	var a := _pair(t, Vector2(300, ON_TOP), Vector2(300, Fx.STAND_Y))
	await t.run_ticks(a["sim"], 5)
	var rows := _log(a["sim"], a["p1"])
	_bits(a["p2"], A)
	await t.run_ticks(a["sim"], 14)
	# Terugzetten op P2 (laag, geen vang) terwijl P2 nog vasthoudt.
	a["p1"].position = Vector2(300, ON_TOP - 10.0)
	a["p1"].motor = Motor.State.new()
	await t.run_ticks(a["sim"], 40)
	t.check(_count(rows, Motor.EV_LAUNCH) == 1, "%d lanceringen zonder nieuwe slag (1)" % _count(rows, Motor.EV_LAUNCH))
	# Opnieuw slaan en 12 ticks vasthouden: wel. (Herhaaltijd AANVAL 20 ticks.)
	_bits(a["p2"], 0)
	await t.run_ticks(a["sim"], 1)
	_bits(a["p2"], A)
	await t.run_ticks(a["sim"], 14)
	t.check(_count(rows, Motor.EV_LAUNCH) == 2, "%d lanceringen na een nieuwe slag (2)" % _count(rows, Motor.EV_LAUNCH))
	await t.cleanup()


func test_c11e_solo_echo_stance(t) -> void:
	for held in [true, false]:
		var sim = Fx.world(t)
		_still_echo(t, sim, 300.0, held)
		var p1 := Fx.manual_player(sim, 1, Vector2(300, ON_TOP - 10.0))
		var rows := _log(sim, p1)
		await t.run_ticks(sim, 30)
		var launch := _first(rows, Motor.EV_LAUNCH)
		if held:
			# Echo op frame p = t − 1; houding vanaf frame 12, dus vanaf tick 13.
			t.check(launch == 13 and rows[launch + 1]["vel"].x == 4.0,
				"solo: lancering van de echo op tick %d (13)" % launch)
		else:
			t.check(launch == -1, "solo: lancering zonder vasthouden (tick %d)" % launch)
		await t.cleanup()


# --- C-13 vangen -------------------------------------------------------------

func test_c13_catch_coop_both_directions(t) -> void:
	for springer_index in [1, 2]:
		for case in [["recht", 0.0, 64.0, true], ["20 px opzij", 20.0, 64.0, true],
				["25 px opzij", 25.0, 64.0, false], ["20 px hoog", 0.0, 20.0, false]]:
			var carrier_at := Vector2(300, Fx.STAND_Y)
			var springer_at := Vector2(300.0 + case[1], TOP - case[2] - 15.0)
			var a := _pair(t, springer_at if springer_index == 1 else carrier_at,
				carrier_at if springer_index == 1 else springer_at)
			var springer: PlayerActor = a["p%d" % springer_index]
			var rows := _log(a["sim"], springer)
			await t.run_ticks(a["sim"], 40)
			var c := _first(rows, Motor.EV_CATCH)
			var label := "P%d %s" % [springer_index, case[0]]
			if case[3]:
				t.check(c >= 0 and rows[c]["vel"].y == -6.0 and rows[c]["dash_ready"]
					and absf(rows[c]["pos"].y - ON_TOP) < 0.1,
					"%s: vang %d, %s" % [label, c, str(rows[c] if c >= 0 else {})])
				t.check(c >= 0 and springer.invulnerable_until == rows[c]["tick"] + 12,
					"%s: 12 ticks onkwetsbaar" % label)
			else:
				t.check(c == -1, "%s: onterechte vang op %d" % [label, c])
			await t.cleanup()


func test_c13_one_catch_per_airphase_and_invulnerability(t) -> void:
	var a := _pair(t, Vector2(300, TOP - 64.0 - 15.0), Vector2(300, Fx.STAND_Y))
	var p1: PlayerActor = a["p1"]
	var rows := _log(a["sim"], p1)
	await t.run_ticks(a["sim"], 100)
	t.check(_count(rows, Motor.EV_CATCH) == 1, "%d vangsten zonder grond (1)" % _count(rows, Motor.EV_CATCH))
	var c := _first(rows, Motor.EV_CATCH)
	t.check(_first(rows, Motor.EV_SPRINGPLANK, c + 1) > c, "na de vang geen gewone landing op P2")
	var catch_tick: int = rows[c]["tick"]
	var h := p1.health
	p1.take_hit(catch_tick + 11)
	t.check(p1.health == h, "treffer op vangtick + 11 kostte een levenspunt")
	p1.take_hit(catch_tick + 12)
	t.check(p1.health == h - 1, "treffer op vangtick + 12 kostte niets")
	await t.cleanup()


func test_c13_catch_beats_stance(t) -> void:
	var a := _pair(t, Vector2(300, -3000), Vector2(300, Fx.STAND_Y))
	var rows := _log(a["sim"], a["p1"])
	_bits(a["p2"], A)
	await t.run_ticks(a["sim"], 20)
	a["p1"].position = Vector2(300, TOP - 64.0 - 15.0)
	a["p1"].motor = Motor.State.new()
	await t.run_ticks(a["sim"], 25)
	var c := _first(rows, Motor.EV_CATCH)
	t.check(c >= 0 and _first(rows, Motor.EV_LAUNCH) != c, "snel vallen op P2 in houding: geen vang (of lancering ervoor)")
	await t.cleanup()


func test_c13_solo_echo_catches(t) -> void:
	var sim = Fx.world(t)
	_still_echo(t, sim, 300.0, false)
	var p1 := Fx.manual_player(sim, 1, Vector2(300, TOP - 64.0 - 15.0))
	var rows := _log(sim, p1)
	await t.run_ticks(sim, 40)
	t.check(_first(rows, Motor.EV_CATCH) >= 0, "solo: de echo ving P1 niet")
	await t.cleanup()


# --- C-03 drop-in ------------------------------------------------------------

func _new_p2(at := Vector2.ZERO) -> PlayerActor:
	var p2 := PlayerActor.new()
	p2.setup(2, Fx.ManualInput.new(), Color.DIM_GRAY)
	p2.position = at
	return p2


func test_c03_drop_in_takes_over_active_echo(t) -> void:
	var sim = Fx.world(t)
	var ghost := Fx.ghost(t)
	Fx.ghost_path(ghost, 0, 600, func(k: int) -> Vector2: return Vector2(300 + k, Fx.STAND_Y))
	var echo := Fx.tail_echo(sim, ghost, 1)
	var p1 := Fx.manual_player(sim, 1, Vector2(100, Fx.STAND_Y))
	await t.run_ticks(sim, 20)
	var at: Vector2 = echo.position
	var p2 := _new_p2()
	t.check(sim.drop_in(p2), "drop-in geweigerd")
	t.check(p2.position == at and p2.motor.facing == echo.facing, "P2 op %s, echo stond op %s" % [p2.position, at])
	t.check(sim.echoes.is_empty() and sim.bodies().size() == 2, "na drop-in nog een echo (C-01)")
	await t.run_ticks(sim, 1)
	t.check(p1.plank.collision_layer == Layers.LIGHT_PLANK, "lichtplank van P1 niet aan na drop-in")
	await t.cleanup()


func test_c03_p1_on_echo_stays_on_p2(t) -> void:
	var sim = Fx.world(t)
	_still_echo(t, sim, 300.0, false)
	var p1 := Fx.manual_player(sim, 1, Vector2(300, ON_TOP - 5.0))
	await t.run_ticks(sim, 20)
	t.check(p1.motor.support == Motor.Support.SHADOW_BODY, "P1 staat niet op de echo")
	var p2 := _new_p2()
	sim.drop_in(p2)
	var rows := _log(sim, p1)
	await t.run_ticks(sim, 3)
	t.check(rows[0]["floor"] and rows[0]["support"] == Motor.Support.SHADOW_BODY and p1.motor.plank == p2.plank
		and absf(rows[0]["pos"].y - ON_TOP) < EPS, "P1 viel bij de drop-in: %s" % str(rows[0]))
	await t.cleanup()


func test_c03_placement_rule(t) -> void:
	# Lege echo (geen echo): P2 op de positie van P1.
	var sim = Fx.world(t)
	var p1 := Fx.manual_player(sim, 1, Vector2(300, Fx.STAND_Y))
	await t.run_ticks(sim, 3)
	var p2 := _new_p2()
	sim.drop_in(p2)
	t.check(p2.position == p1.position, "Lege echo: P2 op %s, P1 op %s" % [p2.position, p1.position])
	await t.cleanup()
	# Schaduwgeometrie op de plek van P1 (bovenkant van P1 erin).
	sim = Fx.world(t)
	p1 = Fx.manual_player(sim, 1, Vector2(300, Fx.STAND_Y))
	Fx.block(t, "ShadowCeiling", Rect2(250, 300, 100, 80), Layers.SHADOW_GEOMETRY)
	await t.run_ticks(sim, 3)
	p2 = _new_p2()
	sim.drop_in(p2)
	var d := p2.position.distance_to(p1.position)
	t.check(d > 0.0 and d <= 64.0 and fmod(absf(p2.position.y - p1.position.y), 4.0) < EPS,
		"vrije plek: P2 op %s (%.1f px van P1, ≤ 64, stappen van 4)" % [p2.position, d])
	await t.run_ticks(sim, 1)
	t.check(p2.position.y <= Fx.STAND_Y + EPS, "P2 zit vast of valt door de vloer: %s" % p2.position)
	await t.cleanup()
	# Geen vrije plek binnen 64 px: laatste vloerpositie van P1.
	sim = Fx.world(t)
	p1 = Fx.manual_player(sim, 1, Vector2(300, Fx.STAND_Y))
	await t.run_ticks(sim, 3)
	var floor_at := p1.last_floor_position
	Fx.block(t, "ShadowMass", Rect2(150, 200, 300, 199), Layers.SHADOW_GEOMETRY)
	await t.run_ticks(sim, 1)
	p2 = _new_p2()
	sim.drop_in(p2)
	t.check(p2.position == p1.last_floor_position and floor_at == p1.last_floor_position,
		"geen vrije plek: P2 op %s, laatste vloer %s" % [p2.position, p1.last_floor_position])
	await t.cleanup()


# --- C-04 / C-05 drop-out met geldig_vanaf van P1 ----------------------------

func test_c05_drop_out_after_release_all_d(t) -> void:
	for d in ALL_D:
		var sim = Fx.world(t)
		var p1 := Fx.manual_player(sim, 1, Vector2(200, Fx.STAND_Y))
		var echo := Fx.tail_echo(sim, p1, d)
		await t.run_ticks(sim, 10)
		sim.drop_in(_new_p2())
		t.check(not is_instance_valid(echo) or echo.is_queued_for_deletion(), "D = %d: echo bleef na drop-in" % d)
		await t.run_ticks(sim, d + 50)
		# Loslaten in co-op: 30 ticks ECHO, t0 = de 30e tick.
		_bits(p1, E)
		await t.run_ticks(sim, 30)
		_bits(p1, 0)
		var t0: int = sim.tick - 1
		t.check(p1.echo_valid_from == t0, "D = %d: Loslaten in co-op zette geldig_vanaf %d (%d)" % [d, p1.echo_valid_from, t0])
		await t.run_ticks(sim, 20 - (sim.tick - t0))
		var new_echo: TailEcho = sim.drop_out()
		var present := {}
		sim.tick_finished.connect(func(tick: int) -> void: present[tick] = new_echo.is_present())
		await t.run_ticks(sim, d + 5)
		t.check(new_echo != null and new_echo.valid_from == t0, "D = %d: echo na drop-out met geldig_vanaf van P1" % d)
		t.check(not present[t0 + d - 1] and present[t0 + d], "D = %d: echo niet Leeg tot t0 + D, Actief op t0 + D" % d)
		await t.cleanup()


func test_c04_d_switch_in_coop_then_drop_out(t) -> void:
	# C-04: een wissel van D in co-op zet geldig_vanaf op P1 (er is geen echo);
	# een drop-out 20 ticks later geeft een echo die Leeg is tot t1 + D.
	for d in ALL_D:
		var sim = Fx.world(t)
		var p1 := Fx.manual_player(sim, 1, Vector2(200, Fx.STAND_Y))
		Fx.tail_echo(sim, p1, 120)
		await t.run_ticks(sim, 5)
		sim.drop_in(_new_p2())
		_bits(p1, R)
		await t.run_ticks(sim, 300)
		var t1: int = sim.tick
		sim.set_tail_ticks(d)
		t.check(p1.echo_valid_from == t1 and sim.echoes.is_empty(),
			"D = %d: wissel in co-op zette geldig_vanaf %d (%d)" % [d, p1.echo_valid_from, t1])
		await t.run_ticks(sim, 20)
		var echo: TailEcho = sim.drop_out()
		var present := {}
		sim.tick_finished.connect(func(tick: int) -> void: present[tick] = echo.is_present())
		await t.run_ticks(sim, d)
		t.check(echo != null and echo.tail_ticks == d, "D = %d: echo na drop-out met D %d" % [d, echo.tail_ticks if echo else -1])
		t.check(not present[t1 + 20] and not present[t1 + d - 1] and present[t1 + d],
			"D = %d: echo niet Leeg tot t1 + D, Actief op t1 + D" % d)
		await t.cleanup()


func test_c05_drop_out_long_after_reset_is_active_at_once(t) -> void:
	var sim = Fx.world(t)
	var p1 := Fx.manual_player(sim, 1, Vector2(200, Fx.STAND_Y))
	sim.drop_in(_new_p2())
	_bits(p1, R)
	await t.run_ticks(sim, 120 + 300)
	var echo: TailEcho = sim.drop_out()
	var at_drop: int = sim.tick
	var expected := p1.recorder.post_position(p1.recorder.index_of_tick(at_drop - 120))
	await t.run_ticks(sim, 1)
	t.check(echo.is_present() and echo.position == expected,
		"echo op de drop-out-tick op %s (Actief, %s)" % [echo.position, expected])
	await t.cleanup()


func test_c05_p1_on_p2_falls_at_drop_out(t) -> void:
	var a := _pair(t, Vector2(300, ON_TOP), Vector2(300, Fx.STAND_Y))
	await t.run_ticks(a["sim"], 10)
	var p1: PlayerActor = a["p1"]
	a["sim"].drop_out()
	var rows := _log(a["sim"], p1)
	await t.run_ticks(a["sim"], 2)
	t.check(not rows[0]["floor"] and rows[0]["pos"].y > ON_TOP, "P1 viel niet op de drop-out-tick: %s" % str(rows[0]))
	t.check(p1.plank.collision_layer == 0, "lichtplank aan na drop-out")
	await t.cleanup()


func test_c04_recorder_continues_in_coop_and_c01_session(t) -> void:
	var sim = Fx.world(t)
	var p1 := Fx.manual_player(sim, 1, Vector2(200, Fx.STAND_Y))
	Fx.tail_echo(sim, p1, 120)
	var worst := {"bodies": 0, "shadow": 0, "echo_in_coop": 0}
	sim.tick_finished.connect(func(_tick: int) -> void:
		worst["bodies"] = maxi(worst["bodies"], sim.bodies().size())
		worst["shadow"] = maxi(worst["shadow"], sim.shadow_bodies().size())
		if sim.is_coop():
			for e in sim.echoes:
				if e.is_present() or e.visible:
					worst["echo_in_coop"] += 1)
	_bits(p1, R)
	for cycle in 2:
		await t.run_ticks(sim, 300)
		sim.drop_in(_new_p2())
		await t.run_ticks(sim, 700)
		var last: int = sim.tick - 1
		var gaps := 0
		for k in 600:
			if p1.recorder.index_of_tick(last - k) < 0:
				gaps += 1
		t.check(gaps == 0, "cyclus %d: %d gaten in de laatste 600 frames van P1 in co-op" % [cycle, gaps])
		_bits(p1, L if cycle == 0 else R)
		sim.drop_out()
	await t.run_ticks(sim, 300)
	t.check(worst["bodies"] <= 2 and worst["shadow"] <= 1 and worst["echo_in_coop"] == 0,
		"C-01: max %d lichamen, %d schaduwlichamen, %d echo-ticks in co-op" % [worst["bodies"], worst["shadow"], worst["echo_in_coop"]])
	await t.cleanup()
