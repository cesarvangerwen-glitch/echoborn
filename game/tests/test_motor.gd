extends RefCounted
## Tests voor de beweging van v0.4 (gdd §2.5a), de lagen (E-05) en de
## schaduw als platform met springplank (E-07, E-07a). T16a, #76.
##
## Echo-paden die P1 niet zelf kan lopen (bv. 3 px/tick) komen uit een
## spookbron (EchoFixture.ghost) met D = 1: de echo staat op tick t op het
## frame van tick t − 1. Posities zijn float32; waar een tolerantie staat,
## is die 0,01 px (afronding van 2 px/tick × 60 × 1/60), of 0,1 px voor
## een lichaam op de vloer (de veiligheidsmarge van `move_and_slide`).

const Fx = preload("res://tests/echo_fixture.gd")
const InputBits = preload("res://scripts/input/input_bits.gd")
const PlayerActor = preload("res://scripts/echo/player_actor.gd")
const TailEcho = preload("res://scripts/echo/tail_echo.gd")
const Motor = preload("res://scripts/echo/motor.gd")
const Layers = preload("res://scripts/world/layers.gd")
const ScriptedInput = preload("res://scripts/input/scripted_input.gd")

const L := InputBits.LEFT
const R := InputBits.RIGHT
const J := InputBits.JUMP
const D := InputBits.DASH
const EPS := 0.01


## Per tick na stap (5): positie, snelheid (px/tick), steun en events van P1.
func _log(sim: Node, p1: PlayerActor) -> Array:
	var rows: Array = []
	sim.tick_finished.connect(func(tick: int) -> void:
		rows.append({"tick": tick, "pos": p1.position, "vel": p1.motor.velocity,
			"floor": p1.motor.on_floor, "support": p1.motor.support,
			"ev": p1.move_events, "dash_ready": p1.motor.dash_ready}))
	return rows


## Index in `rows` van de eerste tick met `event`, of -1.
func _first(rows: Array, event: int) -> int:
	for i in rows.size():
		if rows[i]["ev"] & event:
			return i
	return -1


func _count(rows: Array, event: int) -> int:
	var n := 0
	for row: Dictionary in rows:
		if row["ev"] & event:
			n += 1
	return n


## Stilstaande echo op de vloer bij x (spookbron, D = 1, `ticks` frames).
func _still_echo(t, sim: Node, x: float, ticks := 600) -> TailEcho:
	var ghost := Fx.ghost(t)
	Fx.ghost_path(ghost, 0, ticks, func(_k: int) -> Vector2: return Vector2(x, Fx.STAND_Y))
	return Fx.tail_echo(sim, ghost, 1)


# --- §2.5a ---------------------------------------------------------------

## Sprong vanaf de vloer: top 49–51 px, 40 ± 1 ticks in de lucht. Lopen 2 px/tick.
func test_jump_height_airtime_and_walk_speed(t) -> void:
	var sim = Fx.world(t)
	var p1 := Fx.p1(sim, [[10, 0], [1, J], [60, 0], [50, R]])
	var rows := _log(sim, p1)
	await t.run_ticks(sim, 121)
	var top := 0.0
	var air := 0
	for row: Dictionary in rows:
		top = maxf(top, Fx.STAND_Y - (row["pos"] as Vector2).y)
		if row["tick"] >= 10 and row["tick"] < 70 and not row["floor"]:
			air += 1
	t.check(top >= 49.0 and top <= 51.0, "top van de sprong %.3f px (49–51)" % top)
	t.check(air >= 39 and air <= 41, "%d ticks in de lucht (40 ± 1)" % air)
	var walked: float = (rows[120]["pos"] as Vector2).x - (rows[70]["pos"] as Vector2).x
	t.check(absf(walked - 100.0) < EPS, "50 ticks lopen = %.4f px (100)" % walked)
	t.note("sprong: top %.2f px, %d ticks in de lucht" % [top, air])


## Dash: 40 px in 10 ticks met v.y = 0; geen tweede dash in de lucht zonder
## plank; op de grond 20 ticks herhaaltijd.
func test_dash_distance_air_limit_and_ground_cooldown(t) -> void:
	var sim = Fx.world(t)
	# Grond: dash op 5, flank op 20 (15 later: nee), flank op 25 (20 na 5: ja).
	var p1 := Fx.p1(sim, [[5, 0], [1, D], [14, 0], [1, D], [4, 0], [1, D], [30, 0]])
	var rows := _log(sim, p1)
	await t.run_ticks(sim, 60)
	var dx: float = (rows[14]["pos"] as Vector2).x - (rows[4]["pos"] as Vector2).x
	t.check(absf(dx - 40.0) < EPS, "dash = %.4f px in 10 ticks (40)" % dx)
	var flat := true
	for k in range(5, 15):
		flat = flat and rows[k]["vel"].y == 0.0
	t.check(flat, "v.y is niet 0 tijdens de dash")
	t.check(rows[20]["ev"] & Motor.EV_DASH == 0, "dash 15 ticks na de vorige op de grond")
	t.check(rows[25]["ev"] & Motor.EV_DASH != 0, "geen dash 20 ticks na de vorige op de grond")
	await t.cleanup()
	# Lucht: sprong, dash, nog een dash-flank in dezelfde luchtfase: niets.
	sim = Fx.world(t)
	p1 = Fx.p1(sim, [[5, 0], [1, J], [10, 0], [1, D], [15, 0], [1, D], [30, 0]])
	rows = _log(sim, p1)
	await t.run_ticks(sim, 60)
	t.check(rows[16]["ev"] & Motor.EV_DASH != 0, "eerste dash in de lucht ging niet")
	t.check(not rows[32]["floor"] and rows[32]["ev"] & Motor.EV_DASH == 0,
		"tweede dash in dezelfde luchtfase zonder plank")


## Sprongbuffer 6 ticks bij landen op de vloer; 7 ticks is te vroeg.
func test_jump_buffer_on_world_floor(t) -> void:
	var landing := await _landing_tick(t, Vector2(200, 300), [])
	for early in [6, 7]:
		var sim = Fx.world(t)
		var p1 := Fx.p1(sim, [[landing - early, 0], [1, J], [80, 0]], Vector2(200, 300))
		var rows := _log(sim, p1)
		await t.run_ticks(sim, landing + 40)
		var jumped: bool = rows[landing]["ev"] & Motor.EV_JUMP != 0
		t.check(jumped == (early == 6), "JUMP %d ticks vóór het landen: sprong = %s" % [early, jumped])
		await t.cleanup()


## Tick waarop P1 vanaf `at` op iets landt (zonder input of met `segments`).
func _landing_tick(t, at: Vector2, segments: Array, echo_x := -1.0) -> int:
	var sim = Fx.world(t)
	if echo_x >= 0.0:
		_still_echo(t, sim, echo_x)
	var p1 := Fx.p1(sim, segments, at)
	var rows := _log(sim, p1)
	await t.run_ticks(sim, 120)
	var tick := _first(rows, Motor.EV_LAND | Motor.EV_SPRINGPLANK)
	await t.cleanup()
	return tick


# --- E-05 ----------------------------------------------------------------

## Lagen en maskers volgens de tabel; P1 tegen licht-, door schaduwmuur; P2 omgekeerd.
func test_e05_layers_and_walls(t) -> void:
	var sim = Fx.world(t)
	var p1 := Fx.p1(sim, [[200, R]])
	var echo := _still_echo(t, sim, 900.0)
	await t.run_ticks(sim, 2)
	t.check(p1.collision_layer == Layers.LIGHT and p1.collision_mask == Layers.WORLD | Layers.LIGHT_GEOMETRY | Layers.PLANK,
		"P1: laag %d, masker %d" % [p1.collision_layer, p1.collision_mask])
	t.check(echo.collision_layer == Layers.SHADOW and echo.collision_mask == 0,
		"echo: laag %d, masker %d" % [echo.collision_layer, echo.collision_mask])
	t.check(echo.plank.collision_layer == Layers.PLANK and echo.plank.collision_mask == 0,
		"plank: laag %d, masker %d" % [echo.plank.collision_layer, echo.plank.collision_mask])
	await t.cleanup()
	for index in [1, 2]:
		sim = Fx.world(t)
		Fx.block(t, "ShadowWall", Rect2(260, 300, 10, 100), Layers.SHADOW_GEOMETRY)
		Fx.block(t, "LightWall", Rect2(360, 300, 10, 100), Layers.LIGHT_GEOMETRY)
		var player := PlayerActor.new()
		player.setup(index, ScriptedInput.new([[150, R]]), Color.WHITE)
		player.position = Vector2(200, Fx.STAND_Y)
		sim.add_player(player)
		await t.run_ticks(sim, 150)
		if index == 1:
			t.check(player.position.x > 270.0 and player.position.x <= 352.01,
				"P1 hoort door de schaduwmuur en tegen de lichtmuur: x = %.2f" % player.position.x)
		else:
			t.check(player.collision_layer == Layers.SHADOW and player.collision_mask == Layers.WORLD | Layers.SHADOW_GEOMETRY,
				"P2: laag %d, masker %d" % [player.collision_layer, player.collision_mask])
			t.check(player.position.x <= 252.01, "P2 hoort tegen de schaduwmuur: x = %.2f" % player.position.x)
		await t.cleanup()


# --- E-07 ----------------------------------------------------------------

## Van opzij en van onder gaat P1 door de schaduw; een echo die omhoog door
## P1 beweegt, duwt P1 niet; is de echo Leeg, dan valt P1 in dezelfde tick.
func test_e07_one_way_plank(t) -> void:
	# Van opzij: P1 loopt door een echo op de vloer.
	var sim = Fx.world(t)
	_still_echo(t, sim, 260.0)
	var p1 := Fx.p1(sim, [[60, R]])
	await t.run_ticks(sim, 60)
	t.check(p1.position.x > 300.0 and absf(p1.position.y - Fx.STAND_Y) < 0.1,
		"P1 liep niet door de echo heen: %s" % p1.position)
	await t.cleanup()
	# Van onder: sprong door een zwevende echo (plank 325–329) en terug op de vloer.
	sim = Fx.world(t)
	var ghost := Fx.ghost(t)
	Fx.ghost_path(ghost, 0, 600, func(_k: int) -> Vector2: return Vector2(200, 340), false, Motor.Support.NONE)
	Fx.tail_echo(sim, ghost, 1)
	p1 = Fx.p1(sim, [[5, 0], [1, J], [100, 0]])
	var rows := _log(sim, p1)
	await t.run_ticks(sim, 100)
	var on_plank := 0
	var top := 0.0
	for row: Dictionary in rows:
		on_plank += 1 if row["support"] == Motor.Support.SHADOW_BODY else 0
		top = maxf(top, Fx.STAND_Y - (row["pos"] as Vector2).y)
	t.check(top > 45.0 and on_plank == 0, "van onder: top %.1f px, %d ticks op de plank" % [top, on_plank])
	t.check(p1.motor.on_floor and absf(p1.position.y - Fx.STAND_Y) < 0.1,
		"P1 kwam niet terug op de vloer: %s" % p1.position)
	await t.cleanup()
	# Omhoog door P1: de echo stijgt 2 px/tick vanaf de vloer door P1 heen.
	sim = Fx.world(t)
	ghost = Fx.ghost(t)
	Fx.ghost_path(ghost, 0, 600, func(k: int) -> Vector2: return Vector2(200, Fx.STAND_Y - 2.0 * k),
		false, Motor.Support.NONE)
	Fx.tail_echo(sim, ghost, 1)
	p1 = Fx.p1(sim, [])
	rows = _log(sim, p1)
	await t.run_ticks(sim, 40)
	var moved := 0
	for row: Dictionary in rows:
		if row["tick"] > 0 and ((row["pos"] as Vector2).y != rows[0]["pos"].y or row["support"] != Motor.Support.WORLD):
			moved += 1
	t.check(moved == 0, "een stijgende echo verplaatste P1 of droeg hem op %d ticks" % moved)
	await t.cleanup()
	# Leeg onder P1: de opname stopt na tick 49, de echo is Leeg vanaf tick 51.
	sim = Fx.world(t)
	var echo := _still_echo(t, sim, 200.0, 50)
	p1 = Fx.p1(sim, [], Vector2(200, Fx.ON_ECHO_Y - 10.0))
	rows = _log(sim, p1)
	await t.run_ticks(sim, 60)
	t.check(rows[50]["support"] == Motor.Support.SHADOW_BODY, "P1 stond op tick 50 niet op de echo")
	t.check(not echo.is_present() and not rows[51]["floor"] and rows[51]["pos"].y > rows[50]["pos"].y,
		"P1 viel niet in de tick waarop de echo Leeg werd: %s -> %s" % [rows[50]["pos"], rows[51]["pos"]])


# --- E-07a ---------------------------------------------------------------

## (1) Meebewegen: de echo gaat 3 px/tick naar rechts, P1 staat erop zonder
## input en schuift in dezelfde tick mee. Met een muur stopt P1, de plank
## gaat door en P1 valt als de plank onder hem weg is.
func test_e07a_1_carried_by_plank_same_tick(t) -> void:
	for with_wall in [false, true]:
		var sim = Fx.world(t)
		var ghost := Fx.ghost(t)
		Fx.ghost_path(ghost, 0, 600, func(k: int) -> Vector2: return Vector2(300 + 3.0 * k, Fx.STAND_Y))
		var echo := Fx.tail_echo(sim, ghost, 1)
		if with_wall:
			# Muur op laag 1 boven de echo (onderkant 365 < bovenkant echo 370).
			Fx.block(t, "Wall", Rect2(400, 280, 20, 85), Layers.WORLD)
		await t.run_ticks(sim, 1)
		var p1 := Fx.p1(sim, [], Vector2(300, Fx.ON_ECHO_Y))
		var rows := _log(sim, p1)
		var echo_x := Fx.trace(sim, [echo])
		await t.run_ticks(sim, 40)
		if not with_wall:
			var off := 0
			for row: Dictionary in rows:
				var tick: int = row["tick"]
				if tick >= 2 and absf(row["pos"].x - (echo_x[0][tick] as Vector2).x) > EPS:
					off += 1
			t.check(off == 0, "%d ticks liep P1 niet gelijk met de plank (zelfde tick)" % off)
			t.check(absf(rows[30]["pos"].x - rows[29]["pos"].x - 3.0) < EPS,
				"P1 schoof %.3f px in één tick (3)" % (rows[30]["pos"].x - rows[29]["pos"].x))
		else:
			var stopped: float = rows[39]["pos"].x
			t.check(stopped <= 392.01 and stopped >= 391.0, "P1 hoort tegen de muur te stoppen: x = %.2f" % stopped)
			t.check(not rows[39]["floor"] and rows[39]["pos"].y > Fx.ON_ECHO_Y,
				"P1 viel niet toen de plank onder hem weg was: %s" % rows[39]["pos"])
			t.check(echo.is_present(), "de echo brak door de muur boven hem")
		await t.cleanup()


## (2) Landen: vaart blijft, v.y = 0, één SPRINGPLANK-event in 60 ticks, de
## dash komt terug en werkt na het verlaten van de plank opnieuw in de lucht.
func test_e07a_2_landing_keeps_speed_and_returns_dash(t) -> void:
	var sim = Fx.world(t)
	_still_echo(t, sim, 300.0)
	var p1 := Fx.p1(sim, [[200, R]], Vector2(260, 300))
	var rows := _log(sim, p1)
	await t.run_ticks(sim, 60)
	var land := _first(rows, Motor.EV_SPRINGPLANK)
	t.check(land > 0, "geen springplank-landing")
	if land > 0:
		t.check(rows[land]["vel"] == Vector2(2.0, 0.0), "snelheid op de landingstick %s (2, 0)" % rows[land]["vel"])
	await t.cleanup()
	# 60 ticks op de echo staan: één event.
	sim = Fx.world(t)
	_still_echo(t, sim, 300.0)
	p1 = Fx.p1(sim, [], Vector2(300, 320))
	rows = _log(sim, p1)
	await t.run_ticks(sim, 90)
	t.check(_count(rows, Motor.EV_SPRINGPLANK) == 1, "%d SPRINGPLANK-events (1)" % _count(rows, Motor.EV_SPRINGPLANK))
	await t.cleanup()
	# Dash in de lucht, landen op de echo, eraf lopen, opnieuw dashen in de lucht.
	sim = Fx.world(t)
	_still_echo(t, sim, 300.0)
	p1 = Fx.p1(sim, [[1, D], [44, 0], [12, R], [1, R | D], [20, 0]], Vector2(260, 250))
	rows = _log(sim, p1)
	await t.run_ticks(sim, 78)
	land = _first(rows, Motor.EV_SPRINGPLANK)
	t.check(land > 10 and rows[land]["dash_ready"], "geen dash terug bij de landing op de echo (tick %d)" % land)
	t.check(not rows[57]["floor"] and rows[57]["ev"] & Motor.EV_DASH != 0,
		"geen tweede dash in de lucht na de plank")
	t.check(_count(rows, Motor.EV_DASH) == 2, "%d dashes (2)" % _count(rows, Motor.EV_DASH))


## (2) Landen tijdens een dash: P1 dasht van een richel op plankhoogte de
## echo op en landt in tick 4 van de dash. De dash loopt door tot tick 10
## (4 px/tick), de dash is pas daarna terug, en er is één SPRINGPLANK-event.
func test_e07a_2_landing_during_dash_from_ledge(t) -> void:
	var sim = Fx.world(t)
	# Plank 290–306 op y 370; richel (laag 1) tot x = 274 met dezelfde bovenkant.
	_still_echo(t, sim, 298.0)
	Fx.block(t, "Ledge", Rect2(150, 370, 124, 30), Layers.WORLD)
	var p1 := Fx.p1(sim, [[10, 0], [1, D], [30, 0]], Vector2(268, Fx.ON_ECHO_Y))
	var rows := _log(sim, p1)
	await t.run_ticks(sim, 30)
	t.check(rows[10]["ev"] & Motor.EV_DASH != 0, "geen dash op tick 10")
	var land := _first(rows, Motor.EV_SPRINGPLANK)
	t.check(land == 13, "landing op de plank op tick %d (13 = dash-tick 4)" % land)
	t.check(_count(rows, Motor.EV_SPRINGPLANK) == 1, "%d SPRINGPLANK-events (1)" % _count(rows, Motor.EV_SPRINGPLANK))
	var steps_ok := true
	for k in range(10, 20):
		steps_ok = steps_ok and absf(rows[k]["pos"].x - rows[k - 1]["pos"].x - 4.0) < EPS
	t.check(steps_ok and absf(rows[20]["pos"].x - rows[19]["pos"].x) < EPS,
		"de dash liep niet precies 10 ticks door na de landing")
	var waiting := true
	for k in range(13, 19):
		waiting = waiting and not rows[k]["dash_ready"]
	t.check(waiting and rows[19]["dash_ready"], "dash niet pas na de dash terug (tick 19)")


## (3) Bounce: v.y = −6, top 70–74 px boven de plank, v.x blijft, BOUNCE-
## event; ≥ 98 px boven de vloer; buffer 10 (11 te vroeg), coyote 6 (7 te laat).
func test_e07a_3_bounce_buffer_and_coyote(t) -> void:
	var sim = Fx.world(t)
	_still_echo(t, sim, 300.0)
	var p1 := Fx.p1(sim, [[30, 0], [1, J], [80, 0]], Vector2(300, Fx.ON_ECHO_Y))
	var rows := _log(sim, p1)
	await t.run_ticks(sim, 100)
	t.check(rows[30]["ev"] & Motor.EV_BOUNCE != 0 and rows[30]["vel"].y < -5.5,
		"geen bounce op tick 30: ev %d, v %s" % [rows[30]["ev"], rows[30]["vel"]])
	var top := 0.0
	for row: Dictionary in rows:
		top = maxf(top, Fx.ON_ECHO_Y - (row["pos"] as Vector2).y)
	t.check(top >= 70.0 and top <= 74.0, "top %.2f px boven de plank (70–74)" % top)
	var above_floor := Fx.FLOOR_TOP - (Fx.ON_ECHO_Y + 15.0 - top)
	t.check(above_floor >= 98.0, "onderkant %.1f px boven de vloer (≥ 98)" % above_floor)
	t.check(rows[30]["vel"].x == 0.0, "v.x veranderde door de bounce")
	await t.cleanup()
	# Buffer: landingstick bepalen, dan JUMP 10 en 11 ticks ervoor.
	var landing := await _landing_tick(t, Vector2(300, 280), [], 300.0)
	for early in [10, 11]:
		sim = Fx.world(t)
		_still_echo(t, sim, 300.0)
		p1 = Fx.p1(sim, [[landing - early, 0], [1, J], [80, 0]], Vector2(300, 280))
		rows = _log(sim, p1)
		await t.run_ticks(sim, landing + 20)
		var bounced: bool = rows[landing]["ev"] & Motor.EV_BOUNCE != 0
		t.check(bounced == (early == 10), "JUMP %d ticks vóór de landing: bounce = %s" % [early, bounced])
		if early == 11:
			t.check(_count(rows, Motor.EV_JUMP) == 0, "JUMP 11 ticks vóór de landing gaf toch een sprong")
		await t.cleanup()
	# Coyote: van de plank aflopen; eerste tick zonder steun bepalen.
	sim = Fx.world(t)
	_still_echo(t, sim, 300.0)
	p1 = Fx.p1(sim, [[5, 0], [60, R]], Vector2(300, Fx.ON_ECHO_Y))
	rows = _log(sim, p1)
	await t.run_ticks(sim, 40)
	var leave := -1
	for row: Dictionary in rows:
		if row["tick"] > 5 and not row["floor"]:
			leave = row["tick"]
			break
	await t.cleanup()
	for late in [6, 7]:
		sim = Fx.world(t)
		_still_echo(t, sim, 300.0)
		p1 = Fx.p1(sim, [[5, 0], [leave + late - 5, R], [1, R | J], [30, R]], Vector2(300, Fx.ON_ECHO_Y))
		rows = _log(sim, p1)
		await t.run_ticks(sim, leave + late + 5)
		var ev: int = rows[leave + late]["ev"]
		t.check((ev & Motor.EV_BOUNCE != 0) == (late == 6) and (ev & Motor.EV_JUMP != 0) == (late == 6),
			"JUMP %d ticks na het verlaten van de plank: events %d" % [late, ev])
		await t.cleanup()
	t.note("landing op tick %d, plank verlaten op tick %d" % [landing, leave])


## (4) Geen plank-snelheid: P1 springt zonder input van een echo die 3 px/tick
## naar rechts gaat; daarna v.x = 0 en x blijft gelijk.
func test_e07a_4_no_plank_velocity_after_jump(t) -> void:
	var sim = Fx.world(t)
	var ghost := Fx.ghost(t)
	Fx.ghost_path(ghost, 0, 600, func(k: int) -> Vector2: return Vector2(300 + 3.0 * k, Fx.STAND_Y))
	Fx.tail_echo(sim, ghost, 1)
	await t.run_ticks(sim, 1)
	var p1 := Fx.p1(sim, [[20, 0], [1, J], [40, 0]], Vector2(300, Fx.ON_ECHO_Y))
	var rows := _log(sim, p1)
	await t.run_ticks(sim, 45)
	var jump := _first(rows, Motor.EV_JUMP)
	t.check(jump > 0 and rows[jump]["ev"] & Motor.EV_BOUNCE != 0, "geen bounce van de bewegende echo")
	var drift: float = rows[jump + 20]["pos"].x - rows[jump]["pos"].x
	t.check(rows[jump + 1]["vel"].x == 0.0 and absf(drift) < EPS,
		"P1 nam snelheid van de plank mee: v.x %.2f, %.2f px in 20 ticks" % [rows[jump + 1]["vel"].x, drift])
