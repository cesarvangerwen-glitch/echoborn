extends RefCounted
## Tests voor co-op 7A, deel 2 (T16c, #78) en E-07c (gdd v0.5, #81):
## C-02 (rest), C-06, C-07, C-08, C-09 (oplossen onder P1), C-12 (volledig),
## C-15, LP en meetlog-bron bij lancering en vang, en de koppeling van de
## flow-kamer aan drop-in/drop-out (InputRouter -> Sim).
##
## Lichamen zijn 16 × 30 px; op de vloer staat een middelpunt op y = 385.

const Fx = preload("res://tests/echo_fixture.gd")
const InputBits = preload("res://scripts/input/input_bits.gd")
const PlayerActor = preload("res://scripts/echo/player_actor.gd")
const TailEcho = preload("res://scripts/echo/tail_echo.gd")
const Motor = preload("res://scripts/echo/motor.gd")
const Layers = preload("res://scripts/world/layers.gd")
const Zone = preload("res://scripts/objects/zone.gd")
const GameEvents = preload("res://scripts/events/game_events.gd")
const ScriptedInput = preload("res://scripts/input/scripted_input.gd")
const CombatTarget = preload("res://scripts/combat/combat_target.gd")
const Combat = preload("res://scripts/combat/combat.gd")
const LightMeter = preload("res://scripts/light/light_meter.gd")
const Meetlog = preload("res://scripts/events/meetlog.gd")
const FlowRoom = preload("res://levels/flowkamer/flow_room.gd")
const FlowBot = preload("res://levels/flowkamer/flow_bot.gd")
const Layout = preload("res://levels/flowkamer/flow_layout.gd")
const SimScript = preload("res://scripts/sim.gd")

const L := InputBits.LEFT
const R := InputBits.RIGHT
const J := InputBits.JUMP
const A := InputBits.ATTACK
const E := InputBits.ECHO
const ALL_D := [90, 120, 180]
const ON_TOP := Fx.ON_ECHO_Y


func _pair(t, p1_at: Vector2, p2_at: Vector2) -> Dictionary:
	var sim = Fx.world(t)
	var p1 := Fx.manual_player(sim, 1, p1_at)
	var p2 := Fx.manual_player(sim, 2, p2_at)
	return {"sim": sim, "p1": p1, "p2": p2}


func _bits(p: PlayerActor, bits: int) -> void:
	(p.input_source as Fx.ManualInput).bits = bits


func _watch(sim: Node) -> Dictionary:
	var log := {"gone": [], "back": []}
	sim.partner_dissolved.connect(func(tick: int, at: Vector2, cause: String) -> void:
		log["gone"].append([tick, cause, at]))
	sim.partner_returned.connect(func(tick: int, at: Vector2) -> void:
		log["back"].append([tick, at]))
	return log


# --- E-07c: geen echo-toren -------------------------------------------------

## (3) Script "echo-toren": elke 20 ticks JUMP, D = 90, 2400 ticks. Vóór E-07c
## klom P1 zo ± 1100–1300 px (T16a); nu nooit hoger dan 100 px boven de vloer.
func test_e07c_no_echo_tower(t) -> void:
	var segments: Array = [[100, 0]]
	for i in 115:
		segments.append([1, J])
		segments.append([19, 0])
	var sim = Fx.world(t)
	var p1 := Fx.p1(sim, segments)
	var echo := Fx.tail_echo(sim, p1, 90)
	var best := {"h": 0.0, "plank": 0}
	sim.tick_finished.connect(func(_tick: int) -> void:
		best["h"] = maxf(best["h"], Fx.FLOOR_TOP - (p1.position.y + 15.0))
		if p1.motor.support == Motor.Support.SHADOW_BODY:
			best["plank"] += 1)
	await t.run_ticks(sim, 2400)
	# Eén bounce van een echo op de vloer haalt ± 100 px (gdd §4.3: 102 px met
	# deze waarden); een toren zou blijven stijgen.
	t.check(best["h"] <= 105.0, "P1 kwam %.1f px boven de vloer (± 100, geen toren)" % best["h"])
	t.check(echo.is_present() and echo.valid_from == 0, "echo niet Actief of gereset")
	t.note("echo-toren D=90: hoogste punt %.1f px, %d ticks op de echo" % [best["h"], best["plank"]])


## (5) Opgenomen frames: `plank_sinds_grond` is waar vanaf de landing op een
## plank tot de eerste tick op de vloer. (2) Zo'n frame draagt niet.
func test_e07c_recorded_flag(t) -> void:
	var sim = Fx.world(t)
	var ghost := Fx.ghost(t)
	Fx.ghost_path(ghost, 0, 300, func(_k: int) -> Vector2: return Vector2(300, Fx.STAND_Y))
	var carrier := Fx.tail_echo(sim, ghost, 1)
	var p1 := Fx.p1(sim, [[40, 0], [30, R], [100, 0]], Vector2(300, ON_TOP - 10.0))
	var flags := {}
	sim.tick_finished.connect(func(tick: int) -> void:
		var i := p1.recorder.index_of_tick(tick)
		flags[tick] = [p1.recorder.plank_since_ground(i), p1.motor.support, p1.motor.on_floor])
	await t.run_ticks(sim, 120)
	var first_plank := -1
	var first_floor := -1
	for tick in flags:
		if first_plank < 0 and flags[tick][1] == Motor.Support.SHADOW_BODY:
			first_plank = tick
		if first_plank >= 0 and first_floor < 0 and flags[tick][2] and flags[tick][1] == Motor.Support.WORLD:
			first_floor = tick
	var ok := first_plank >= 0 and first_floor > first_plank
	for tick in flags:
		var want: bool = first_plank >= 0 and tick >= first_plank and (first_floor < 0 or tick < first_floor)
		if flags[tick][0] != want:
			ok = false
	t.check(ok, "vlag niet waar van landing %d tot vloer %d" % [first_plank, first_floor])
	t.check(carrier.is_present(), "drager niet Actief")


## (1) P1 bouncet van zijn echo en valt D + 10 later op de echo die zijn
## eigen bounce-boog volgt: P1 valt erdoor. (4) Vanaf de grond gesprongen:
## de echo draagt wel (de gewone springplank-landing).
func test_e07c_echo_on_own_bounce_arc_does_not_carry_all_d(t) -> void:
	for d: int in ALL_D:
		var sim = Fx.world(t)
		# Op D + 10 op de stilstaande echo springen (landing + bounce), dan stil.
		var p1 := Fx.p1(sim, [[d + 10, 0], [1, J], [400, 0]])
		var echo := Fx.tail_echo(sim, p1, d)
		var landings := {"n": 0, "first": -1}
		sim.tick_finished.connect(func(tick: int) -> void:
			if p1.move_events & Motor.EV_SPRINGPLANK:
				landings["n"] += 1
				if landings["first"] < 0:
					landings["first"] = tick)
		await t.run_ticks(sim, 3 * d + 120)
		# (4) De eerste landing (de echo staat waar P1 vanaf de grond liep) mag;
		# daarna draagt de echo op zijn bounce-boog niet meer: geen tweede.
		t.check(landings["first"] >= 0 and landings["n"] == 1,
			"D=%d: %d springplank-landingen (1, eerste op %d)" % [d, landings["n"], landings["first"]])
		t.check(echo.is_present(), "D=%d: echo niet Actief" % d)
		await t.cleanup()


# --- C-02 (rest) -----------------------------------------------------------

func test_c02_p2_rules(t) -> void:
	var a := _pair(t, Vector2(100, Fx.STAND_Y), Vector2(300, Fx.STAND_Y))
	var sim: Node = a["sim"]
	var p2: PlayerActor = a["p2"]
	# Schaduwmuur op x = 340: P2 botst; lichtmuur op x = 200: P2 loopt erdoor.
	Fx.block(t, "ShadowWall", Rect2(340, 300, 20, 100), Layers.SHADOW_GEOMETRY)
	Fx.block(t, "LightWall", Rect2(220, 300, 20, 100), Layers.LIGHT_GEOMETRY)
	_bits(p2, R)
	await t.run_ticks(sim, 40)
	t.check(p2.position.x < 332.0 and not p2.dissolved, "P2 tegen schaduwmuur op x = %.1f, opgelost %s" % [p2.position.x, p2.dissolved])
	_bits(p2, L)
	await t.run_ticks(sim, 100)
	t.check(p2.position.x < 200.0, "P2 liep niet door de lichtmuur (x = %.1f)" % p2.position.x)
	# ECHO 60 ticks: niets (geen Loslaten, geen reset van P1).
	var before: int = a["p1"].echo_valid_from
	_bits(p2, E)
	await t.run_ticks(sim, 60)
	t.check(p2.echo_reset == PlayerActor.EchoReset.NONE and a["p1"].echo_valid_from == before,
		"ECHO van P2 deed iets")
	# Vijandelijke aanval: geen effect (P2 heeft geen levenspunten, E-14h).
	var health := p2.health
	p2.take_hit(sim.tick)
	t.check(p2.health == health, "vijandelijke treffer op P2 kostte iets")
	# P2-treffer: 10 SE, merk met zetter P2, +2 LP.
	_bits(p2, 0)
	var meter := LightMeter.new(sim, a["p1"])
	meter.coop = true
	var enemy := Fx.target(sim, CombatTarget.Kind.ENEMY, p2.position.x + 20.0)
	var setters: Array = []
	sim.combat.mark_set.connect(func(_tick: int, mark: Combat.Mark) -> void: setters.append(mark.setter))
	var damage: Array = []
	enemy.damaged.connect(func(_tick: int, amount: int, _s: String) -> void: damage.append(amount))
	p2.motor.facing = 1
	await t.run_ticks(sim, 1)
	_bits(p2, A)
	await t.run_ticks(sim, 1)
	_bits(p2, 0)
	await t.run_ticks(sim, 5)
	t.check(damage == [10] and setters == ["p2"] and meter.value == 2,
		"P2-treffer: schade %s, zetters %s, LP %d (10, p2, 2)" % [str(damage), str(setters), meter.value])


# --- C-06 en C-07 ------------------------------------------------------------

func test_c06_dissolve_and_return(t) -> void:
	for cause in ["fellicht", "gevaar", "val"]:
		var a := _pair(t, Vector2(100, Fx.STAND_Y), Vector2(300, Fx.STAND_Y))
		var sim: Node = a["sim"]
		var p1: PlayerActor = a["p1"]
		var p2: PlayerActor = a["p2"]
		var log := _watch(sim)
		if cause == "fellicht":
			Fx.zone(t, Zone.Kind.FEL_LICHT, Rect2(330, 300, 40, 100))
		elif cause == "gevaar":
			Fx.zone(t, Zone.Kind.GEVAAR, Rect2(330, 300, 40, 100))
		else:
			sim.room_bottom = 450.0
			p2.position = Vector2(300, 460)  # onder de vloer: valt uit de kamer
		await t.run_ticks(sim, 3)
		_bits(p2, R)
		await t.run_ticks(sim, 40)
		var gone: Array = log["gone"]
		t.check(gone.size() == 1 and gone[0][1] == cause and p2.dissolved and not p2.visible
			and p2.collision_layer == 0, "%s: opgelost %s" % [cause, str(gone)])
		t.check(p1.position == Vector2(100, Fx.STAND_Y), "%s: P1 verplaatst naar %s" % [cause, p1.position])
		t.check(sim.echoes.is_empty(), "%s: echo tijdens oplossen (C-01)" % cause)
		_bits(p2, 0)
		if not gone.is_empty():
			var t0: int = gone[0][0]
			while sim.tick <= t0 + 120:
				await t.run_ticks(sim, 1)
			var back: Array = log["back"]
			t.check(back.size() == 1 and back[0][0] == t0 + 120 and not p2.dissolved
				and p2.position.distance_to(p1.position) <= 64.0,
				"%s: terug %s (tick %d, naast P1)" % [cause, str(back), t0 + 120])
		await t.cleanup()


func test_c07_leash_59_and_60_ticks(t) -> void:
	for ticks_out in [59, 60]:
		# P2 staat 1000 px rechts (buiten 960 px beeld) en springt na de
		# gewenste ticks terug binnen beeld (teleport, alleen de leiband telt).
		var a := _pair(t, Vector2(100, Fx.STAND_Y), Vector2(200, Fx.STAND_Y))
		var sim: Node = a["sim"]
		var p1: PlayerActor = a["p1"]
		var p2: PlayerActor = a["p2"]
		var log := _watch(sim)
		await t.run_ticks(sim, 2)
		var start: int = sim.tick
		p2.position = Vector2(1100, Fx.STAND_Y)
		await t.run_ticks(sim, ticks_out)
		if not p2.dissolved:
			p2.position = Vector2(200, Fx.STAND_Y)
		await t.run_ticks(sim, 30)
		if ticks_out == 59:
			t.check(log["gone"].is_empty(), "59 ticks buiten beeld: toch opgelost %s" % str(log["gone"]))
		else:
			t.check(log["gone"].size() == 1 and log["gone"][0][0] == start + 59 and log["gone"][0][1] == "leiband",
				"60 ticks: opgelost %s (tick %d, leiband)" % [str(log["gone"]), start + 59])
		t.check(p1.position == Vector2(100, Fx.STAND_Y), "camera/leiband verplaatste P1 naar %s" % p1.position)
		await t.cleanup()


## C-07: camera en leiband sluiten aan. Voor afstanden rond de grens (op
## maximale zoom-uit) staat P2 in het camerabeeld precies als de leiband niet
## telt; P1 staat altijd minstens de marge binnen het beeld.
func test_c07_camera_matches_leash(t) -> void:
	var p1_at := Vector2(1000, 400)
	var bad: Array = []
	for dx in [0.0, 400.0, 900.0, 927.0, 928.0, 928.5, 929.0, 960.0, 1000.0]:
		for dy in [0.0, 300.0, 507.0, 508.0, 509.0, 540.0]:
			for sx in [-1.0, 1.0]:
				var p2_at := p1_at + Vector2(dx * sx, -dy)
				var rect := FlowRoom.camera_view(p1_at, p2_at)
				var shown := rect.grow(0.001).has_point(p2_at)
				var p1_inside := rect.grow(-31.999).has_point(p1_at)
				if shown != SimScript.partner_in_view(p1_at, p2_at) or not p1_inside:
					bad.append([dx * sx, dy, shown])
	t.check(bad.is_empty(), "beeld en leiband verschillen bij %s" % str(bad))


## C-09: P2 lost op terwijl P1 op hem staat: P1 valt op die tick.
func test_c09_p1_falls_when_p2_dissolves(t) -> void:
	var a := _pair(t, Vector2(300, ON_TOP), Vector2(300, Fx.STAND_Y))
	var sim: Node = a["sim"]
	var p1: PlayerActor = a["p1"]
	await t.run_ticks(sim, 5)
	t.check(p1.motor.support == Motor.Support.SHADOW_BODY, "P1 staat niet op P2")
	Fx.zone(t, Zone.Kind.FEL_LICHT, Rect2(290, 370, 20, 30))
	var log := _watch(sim)
	var support := {}
	sim.tick_finished.connect(func(tick: int) -> void: support[tick] = p1.motor.support)
	await t.run_ticks(sim, 10)
	t.check(log["gone"].size() == 1, "P2 loste niet op")
	if log["gone"].size() == 1:
		var t0: int = log["gone"][0][0]
		t.check(support.get(t0, -1) != Motor.Support.SHADOW_BODY and p1.position.y > ON_TOP,
			"P1 viel niet op tick %d (steun %s)" % [t0, str(support.get(t0, -1))])


# --- C-08 --------------------------------------------------------------------

func test_c08_p1_dies_in_coop(t) -> void:
	var a := _pair(t, Vector2(600, Fx.STAND_Y), Vector2(700, Fx.STAND_Y))
	var sim: Node = a["sim"]
	var p1: PlayerActor = a["p1"]
	var p2: PlayerActor = a["p2"]
	var log := _watch(sim)
	await t.run_ticks(sim, 10)
	p1.respawn_at(Vector2(200, Fx.STAND_Y), true)
	var t0: int = sim.tick
	await t.run_ticks(sim, 1)
	t.check(p1.position.distance_to(Vector2(200, Fx.STAND_Y)) < 1.0 and p1.echo_valid_from == t0,
		"P1 op %s, geldig_vanaf %d (t0 = %d)" % [p1.position, p1.echo_valid_from, t0])
	t.check(p2.position.distance_to(p1.position) <= 64.0 and log["back"].size() == 1 and log["back"][0][0] == t0,
		"P2 op %s, terug %s" % [p2.position, str(log["back"])])
	# Ook een opgeloste P2 komt meteen mee terug bij de dood van P1.
	sim.dissolve_partner("val")
	await t.run_ticks(sim, 5)
	p1.respawn_at(Vector2(400, Fx.STAND_Y), true)
	await t.run_ticks(sim, 1)
	t.check(not p2.dissolved and p2.position.distance_to(p1.position) <= 64.0, "opgeloste P2 kwam niet mee")
	# Een teleport zonder dood (respawn_at zonder `death`) verplaatst P2 niet.
	var p2_at := p2.position
	p1.respawn_at(Vector2(100, Fx.STAND_Y))
	await t.run_ticks(sim, 1)
	t.check(p2.position.distance_to(p2_at) < 3.0, "P2 verplaatst bij een respawn zonder dood")


## C-08 solo (alle D): P1 sterft op t0, echo Leeg tot t0 + D.
func test_c08_solo_echo_empty_until_t0_plus_d(t) -> void:
	for d: int in ALL_D:
		var sim = Fx.world(t)
		var p1 := Fx.manual_player(sim, 1, Vector2(200, Fx.STAND_Y))
		var echo := Fx.tail_echo(sim, p1, d)
		await t.run_ticks(sim, d + 20)
		p1.respawn_at(Vector2(300, Fx.STAND_Y), true)
		var t0: int = sim.tick
		var active := {}
		sim.tick_finished.connect(func(tick: int) -> void: active[tick] = echo.is_present())
		await t.run_ticks(sim, d + 2)
		t.check(not active[t0] and not active[t0 + d - 1] and active[t0 + d],
			"D=%d: echo Leeg tot t0 + D (%s, %s, %s)" % [d, active[t0], active[t0 + d - 1], active[t0 + d]])
		await t.cleanup()


# --- C-11 / C-10: lancering vóór bounce op dezelfde tick (SM-punt PR #113) -------

## P1 valt langzaam op P2 in houding met JUMP in de bouncebuffer: op de
## landingstick wordt het een lancering, geen bounce (C-11b).
func test_c11b_launch_beats_bounce_same_tick(t) -> void:
	var a := _pair(t, Vector2(500, Fx.STAND_Y), Vector2(300, Fx.STAND_Y))
	var sim: Node = a["sim"]
	var p1: PlayerActor = a["p1"]
	var p2: PlayerActor = a["p2"]
	_bits(p2, A)
	await t.run_ticks(sim, 20)
	p1.position = Vector2(300, ON_TOP - 10.0)
	p1.motor = Motor.State.new()  # geen coyote van de vloer op x = 500
	var rows: Array = []
	sim.tick_finished.connect(func(tick: int) -> void: rows.append([tick, p1.move_events]))
	await t.run_ticks(sim, 3)
	_bits(p1, J)  # JUMP in de lucht, ≤ 10 ticks vóór de landing (buffer)
	await t.run_ticks(sim, 1)
	_bits(p1, 0)
	await t.run_ticks(sim, 30)
	var launch := -1
	var bounce := -1
	for row: Array in rows:
		if launch < 0 and row[1] & Motor.EV_LAUNCH:
			launch = row[0]
		if bounce < 0 and row[1] & Motor.EV_BOUNCE:
			bounce = row[0]
	t.check(launch >= 0 and bounce < 0, "lancering op %d, bounce op %d (lancering, geen bounce)" % [launch, bounce])


# --- C-12 volledig -----------------------------------------------------------

func _hit(t, sim: Node, p: PlayerActor, target: CombatTarget) -> void:
	p.respawn_at(Vector2(target.position.x - 20.0, Fx.STAND_Y))
	await t.run_ticks(sim, 1)
	p.input_source.bits = A
	await t.run_ticks(sim, 1)
	p.input_source.bits = 0
	await t.run_ticks(sim, 20)


func test_c12_chain_armor_lp_and_fade(t) -> void:
	# Ketting: merk van P1 op V1 en van P2 op V2 (40 px); P2 laat V1 knallen.
	var a := _pair(t, Vector2(100, Fx.STAND_Y), Vector2(120, Fx.STAND_Y))
	var sim: Node = a["sim"]
	var meter := LightMeter.new(sim, a["p1"])
	meter.coop = true
	var v1 := Fx.target(sim, CombatTarget.Kind.ENEMY, 400.0)
	var v2 := Fx.target(sim, CombatTarget.Kind.ENEMY, 440.0)
	v1.health = 1000
	v2.health = 1000
	var exploded: Array = []
	sim.combat.mark_exploded.connect(func(tick: int, mark: Combat.Mark, link: int) -> void:
		exploded.append([tick, mark.target, link]))
	var v2_damage: Array = []
	v2.damaged.connect(func(_tick: int, amount: int, _s: String) -> void: v2_damage.append(amount))
	await _hit(t, sim, a["p1"], v1)
	await _hit(t, sim, a["p2"], v2)
	var lp_before := meter.value
	v2_damage.clear()
	await _hit(t, sim, a["p2"], v1)
	t.check(exploded.size() == 2 and exploded[0][1] == v1 and exploded[1][1] == v2
		and exploded[1][0] == exploded[0][0] + 1, "ketting %s (V1 op t_o, V2 op t_o + 1)" % str(exploded))
	t.check(v2_damage.has(25), "V2 kreeg %s (25 SE)" % str(v2_damage))
	t.check(meter.value - lp_before == 12, "LP %d (+6 per schakel = 12)" % (meter.value - lp_before))
	await t.cleanup()
	# Pantser: merk van P2 op het pantserdoel; P1 raakt het: pantser breekt.
	a = _pair(t, Vector2(100, Fx.STAND_Y), Vector2(120, Fx.STAND_Y))
	sim = a["sim"]
	var armored := Fx.target(sim, CombatTarget.Kind.ARMORED, 400.0)
	var body_damage: Array = []
	armored.damaged.connect(func(_tick: int, amount: int, _s: String) -> void: body_damage.append(amount))
	await _hit(t, sim, a["p2"], armored)
	await _hit(t, sim, a["p1"], armored)
	t.check(not armored.armor_intact and body_damage.all(func(x: int) -> bool: return x == 0),
		"pantser intact %s, schade %s (gebroken, 0)" % [armored.armor_intact, str(body_damage)])
	await t.cleanup()
	# Een merk dat niemand laat knallen, dooft op x + D + 30 (alle D).
	for d: int in ALL_D:
		a = _pair(t, Vector2(100, Fx.STAND_Y), Vector2(120, Fx.STAND_Y))
		sim = a["sim"]
		sim.combat.tail_ticks = d
		var v := Fx.target(sim, CombatTarget.Kind.ENEMY, 400.0)
		v.health = 1000
		var set_at := {"t": -1}
		var faded := {"t": -1}
		sim.combat.mark_set.connect(func(tick: int, _m: Combat.Mark) -> void: set_at["t"] = tick)
		sim.combat.mark_faded.connect(func(tick: int, _m: Combat.Mark) -> void: faded["t"] = tick)
		await _hit(t, sim, a["p2"], v)
		await t.run_ticks(sim, d + 40)
		t.check(set_at["t"] >= 0 and faded["t"] == set_at["t"] + d + 30,
			"D=%d: merk op %d doofde op %d (x + D + 30)" % [d, set_at["t"], faded["t"]])
		await t.cleanup()


# --- LP en meetlog-bron: de drager ---------------------------------------------

func test_lp_and_meetlog_source_is_carrier(t) -> void:
	# P1 valt snel op P2 (vang, bron p2); daarna P2 snel op P1 (vang, bron p1).
	var a := _pair(t, Vector2(300, Fx.STAND_Y - 90.0), Vector2(300, Fx.STAND_Y))
	var sim: Node = a["sim"]
	var p1: PlayerActor = a["p1"]
	var p2: PlayerActor = a["p2"]
	var meter := LightMeter.new(sim, p1)
	meter.coop = true
	var lp: Array = []
	meter.filled.connect(func(_tick: int, amount: int, _added: int, source: String, who: String) -> void:
		lp.append([source, who, amount]))
	var log := Meetlog.new(sim, p1, null)
	await t.run_ticks(sim, 60)
	p1.position = Vector2(500, Fx.STAND_Y)
	p2.position = Vector2(500, Fx.STAND_Y - 90.0)
	p2.motor = Motor.State.new()
	await t.run_ticks(sim, 60)
	var catches := lp.filter(func(r: Array) -> bool: return r[0] == "vang")
	t.check(catches.size() == 2 and catches[0][1] == "p2" and catches[1][1] == "p1" and catches[0][2] == 3,
		"vang-LP %s (p2 dan p1, +3)" % str(lp))
	var sources: Array = []
	for row in log.rows:
		if row[2] == "VANGEN":
			sources.append(row[4])
	t.check(sources == ["p2", "p1"], "meetlog VANGEN-bron %s (p2, p1)" % str(sources))


# --- Flow-kamer: InputRouter -> drop-in/drop-out, C-15 ------------------------

## P2 volgt P1 alleen: loopt naar een plek 40 px achter P1, springt nooit en
## slaat nooit (C-15 (2)). Blijft hij achter, dan lost hij op (leiband) en
## komt hij naast P1 terug (C-06).
class Follower:
	extends RefCounted
	var room: Node

	func _init(p_room: Node) -> void:
		room = p_room

	func sample(_tick: int) -> int:
		var p1: Node2D = room.p1
		var p2: Node2D = room.p2
		if p2 == null:
			return 0
		var goal: float = p1.position.x - 40.0 * float(p1.motor.facing)
		var dx := goal - p2.position.x
		if absf(dx) < 6.0:
			return 0
		return InputBits.RIGHT if dx > 0 else InputBits.LEFT


func _coop_room(t, d: int) -> Array:
	var room = FlowRoom.new()
	room.tail = d
	room.echo_on = false
	room.autosave = false
	room.show_hud = false
	var bot = FlowBot.new(room)
	room.input_override = bot
	t.tree.root.add_child(room)
	return [room, bot]


func _c15_coop(t, d: int) -> void:
	var pair := _coop_room(t, d)
	var room = pair[0]
	await t.tree.physics_frame
	t.check(room.join_partner(Follower.new(room)), "D=%d: drop-in mislukt" % d)
	while not room.run_over and room.sim.tick < 7000:
		await t.tree.physics_frame
	var coop_events := 0
	for ev in ["SPRINGPLANK", "BOUNCE", "LANCERING", "VANGEN", "ONTPLOFFING"]:
		coop_events += room.meetlog.count(ev)
	# Werkaanname: er is nog geen gescripte geoefende co-op-run; de maat is
	# 2× de FK-2-run zonder echo (± 6000 ticks), dus ≤ 12 000 ticks.
	t.check(room.run_over and room.run_ticks() <= 12000,
		"C-15 D=%d: co-op met meelopende P2 geen RUN_EIND binnen de maat (%d ticks)" % [d, room.run_ticks()])
	t.check(coop_events == 0, "C-15 D=%d: %d samenwerkings-events" % [d, coop_events])
	t.note("C-15 co-op meelopen, D=%d: %d ticks, P2 %d× opgelost (%s)" % [d, room.run_ticks(),
		room.meetlog.count("P2_OPGELOST"), _causes(room)])
	room.queue_free()
	await t.tree.process_frame


func _causes(room) -> String:
	var c := {}
	for row in room.meetlog.rows:
		if row[2] == "P2_OPGELOST":
			c[row[4]] = int(c.get(row[4], 0)) + 1
	return str(c)


func test_c15_coop_follow_only_d90(t) -> void:
	await _c15_coop(t, 90)


func test_c15_coop_follow_only_d180(t) -> void:
	await _c15_coop(t, 180)


## InputRouter-signalen gaan via `join_partner`/`leave_partner` naar
## `Sim.drop_in`/`drop_out`: P2 neemt de echo over, bij het verlaten neemt de
## echo het weer over; het meetlog krijgt DROP_IN en DROP_OUT (bron = oorzaak).
func test_flow_room_router_slots_drop_in_out(t) -> void:
	var room = FlowRoom.new()
	room.tail = 90
	room.autosave = false
	room.show_hud = false
	room.input_override = ScriptedInput.new([[200, InputBits.RIGHT], [400, 0]])
	t.tree.root.add_child(room)
	for i in 150:
		await t.tree.physics_frame
	var echo_at: Vector2 = room.echo.position
	room._on_slot_joined(2, "pad0")
	t.check(room.p2 != null and room.p2.position == echo_at and room.echo == null and room.sim.echoes.is_empty(),
		"drop-in nam de echo niet over (P2 %s, echo %s)" % [room.p2.position if room.p2 else null, echo_at])
	for i in 30:
		await t.tree.physics_frame
	room._on_slot_left(2, "apparaat weg")
	t.check(room.p2 == null and room.echo != null and room.sim.echoes.size() == 1, "drop-out gaf geen echo")
	t.check(room.meetlog.count("DROP_IN") == 1 and room.meetlog.count("DROP_OUT") == 1,
		"meetlog DROP_IN/DROP_OUT ontbreken")
	var reason := ""
	for row in room.meetlog.rows:
		if row[2] == "DROP_OUT":
			reason = row[4]
	t.check(reason == "apparaat", "DROP_OUT-bron %s (apparaat)" % reason)
	room.queue_free()
	await t.tree.process_frame
