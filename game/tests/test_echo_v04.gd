extends RefCounted
## Tests voor de staart-echo van v0.4 (gdd §2.2–2.6, §4.6): opname (E-01),
## korte staart D (E-02, alle D), Leeg/Actief (E-03), resets (E-04b–d),
## breken (E-08a–d, met E-08b: zweven op een schaduwlichaam) en Loslaten
## (E-09). T16a, #76.
##
## "(alle D)" = de test draait voor D = 60, 120 en 180, en 90 als regressie
## (gdd v0.8 §4.6). Posities van de echo worden exact vergeleken
## (standaarden §6): hij speelt de opgenomen toestand af.

const Fx = preload("res://tests/echo_fixture.gd")
const InputBits = preload("res://scripts/input/input_bits.gd")
const PlayerActor = preload("res://scripts/echo/player_actor.gd")
const TailEcho = preload("res://scripts/echo/tail_echo.gd")
const Motor = preload("res://scripts/echo/motor.gd")
const Lever = preload("res://scripts/objects/lever.gd")
const GameEvents = preload("res://scripts/events/game_events.gd")
const Layers = preload("res://scripts/world/layers.gd")
const SpikeWorld = preload("res://scripts/world/spike_world.gd")
const Zone = preload("res://scripts/objects/zone.gd")

const L := InputBits.LEFT
const R := InputBits.RIGHT
const J := InputBits.JUMP
const I := InputBits.INTERACT
const E := InputBits.ECHO
## "(alle D)" (gdd v0.8 §4.6, G-8): D = 60, 120 en 180; D = 90 draait mee als
## regressie (tot v0.8 was "(alle D)" 90 / 120 / 180).
const ALL_D := [60, 120, 180, 90]

## 400 ticks lopen, springen, keren en stilstaan.
const WALK := [
	[20, 0], [60, R], [1, R | J], [50, R], [30, 0], [40, L], [1, J], [40, 0],
	[60, R], [1, R | J], [40, L], [57, 0],
]


## Per tick na stap (5): positie en kijkrichting van P1 en de echo, en of de
## echo Actief is.
func _trace(sim: Node, p1: PlayerActor, echo: TailEcho) -> Dictionary:
	var log := {"p1": {}, "p1_facing": {}, "echo": {}, "facing": {}, "present": {}}
	sim.tick_finished.connect(func(tick: int) -> void:
		log["p1"][tick] = p1.position
		log["p1_facing"][tick] = p1.motor.facing
		log["echo"][tick] = echo.position
		log["facing"][tick] = echo.facing
		log["present"][tick] = echo.is_present())
	return log


func _breaks(echo: TailEcho) -> Array:
	var ticks: Array = []
	echo.broke.connect(func(tick: int, _at: Vector2) -> void: ticks.append(tick))
	return ticks


# --- E-01 ----------------------------------------------------------------

## Het opgenomen frame heeft steunsoort wereld, licht en schaduwlichaam op de
## juiste ticks, plus de andere velden; na 900 ticks 600 aaneengesloten frames.
func test_e01_frame_fields_and_support_kinds(t) -> void:
	var sim = Fx.world(t)
	Fx.block(t, "LightBlock", Rect2(380, 340, 60, 60), Layers.LIGHT_GEOMETRY)
	var ghost := Fx.ghost(t)
	Fx.ghost_path(ghost, 0, 600, func(_k: int) -> Vector2: return Vector2(700, Fx.STAND_Y))
	Fx.tail_echo(sim, ghost, 1)
	var p1 := Fx.p1(sim, [[30, 0], [1, I], [9, 0], [20, L], [840, 0]])
	await t.run_ticks(sim, 60)
	p1.respawn_at(Vector2(410, 340 - 15 - 2))
	await t.run_ticks(sim, 30)
	p1.respawn_at(Vector2(700, Fx.ON_ECHO_Y - 2))
	await t.run_ticks(sim, 810)
	var rec := p1.recorder
	t.check(rec.size() == 600, "recorder heeft %d frames (600)" % rec.size())
	var gaps := 0
	for back in 600:
		if rec.index_of_tick(899 - back) < 0:
			gaps += 1
	t.check(gaps == 0 and rec.index_of_tick(299) == -1, "%d gaten in tick 300–899" % gaps)
	await t.cleanup()
	# Zelfde run, maar de velden lezen voordat ze uit de buffer vallen.
	sim = Fx.world(t)
	Fx.block(t, "LightBlock", Rect2(380, 340, 60, 60), Layers.LIGHT_GEOMETRY)
	ghost = Fx.ghost(t)
	Fx.ghost_path(ghost, 0, 600, func(_k: int) -> Vector2: return Vector2(700, Fx.STAND_Y))
	Fx.tail_echo(sim, ghost, 1)
	p1 = Fx.p1(sim, [[30, 0], [1, I], [9, 0], [20, L], [840, 0]])
	await t.run_ticks(sim, 60)
	p1.respawn_at(Vector2(410, 340 - 15 - 2))
	await t.run_ticks(sim, 30)
	p1.respawn_at(Vector2(700, Fx.ON_ECHO_Y - 2))
	await t.run_ticks(sim, 30)
	rec = p1.recorder
	var at := func(tick: int) -> int: return rec.index_of_tick(tick)
	t.check(rec.support(at.call(20)) == Motor.Support.WORLD, "tick 20: steun %d (wereld)" % rec.support(at.call(20)))
	t.check(rec.support(at.call(80)) == Motor.Support.LIGHT, "tick 80: steun %d (licht)" % rec.support(at.call(80)))
	t.check(rec.support(at.call(110)) == Motor.Support.SHADOW_BODY,
		"tick 110: steun %d (schaduwlichaam)" % rec.support(at.call(110)))
	t.check(rec.events(at.call(30)) & GameEvents.INTERACT != 0 and rec.events(at.call(31)) == 0,
		"INTERACTIE-event niet op tick 30 opgenomen")
	t.check(rec.facing(at.call(45)) == -1 and rec.facing(at.call(20)) == 1, "kijkrichting niet opgenomen")
	t.check(rec.post_velocity(at.call(45)) == Vector2(-2.0, 0.0) and rec.anim(at.call(45)) == Motor.Anim.RUN,
		"snelheid %s / animatie %d op tick 45" % [rec.post_velocity(at.call(45)), rec.anim(at.call(45))])
	t.check(rec.post_on_floor(at.call(20)) and rec.post_position(at.call(110)).x == 700.0,
		"op_vloer of positie niet opgenomen")


# --- E-02, E-03 ------------------------------------------------------------

## (alle D) Op elke tick t ≥ D staat de echo op de positie van P1 op t − D
## (0 px), met dezelfde kijkrichting; vóór D is hij Leeg.
func test_e02_tail_follows_exactly_all_d(t) -> void:
	for d: int in ALL_D:
		var sim = Fx.world(t)
		var p1 := Fx.p1(sim, WALK)
		var echo := Fx.tail_echo(sim, p1, d)
		var log := _trace(sim, p1, echo)
		await t.run_ticks(sim, 400)
		var wrong := 0
		var early := 0
		for tick in 400:
			if tick < d:
				early += 1 if log["present"][tick] else 0
			elif not log["present"][tick] or log["echo"][tick] != log["p1"][tick - d] \
					or log["facing"][tick] != log["p1_facing"][tick - d]:
				wrong += 1
		t.check(early == 0, "D = %d: echo %d ticks zichtbaar vóór tick D" % [d, early])
		t.check(wrong == 0, "D = %d: %d ticks niet exact op P1 van D ticks geleden" % [d, wrong])
		await t.cleanup()


## E-02 (gdd v0.8 §4.6, G-6): wissel van D op t0 van 60 naar 120: Leeg tot
## t0 + 120, dan op de positie van P1 op t0. Bij D = 60 houdt de recorder
## 600 frames. De wissel 120 -> 180 (tot v0.8) draait mee als regressie.
func test_e02_switching_d_is_a_reset(t) -> void:
	for pair: Array in [[60, 120], [120, 180]]:
		var from: int = pair[0]
		var to: int = pair[1]
		var sim = Fx.world(t)
		var p1 := Fx.p1(sim, WALK + WALK + WALK)
		var echo := Fx.tail_echo(sim, p1, from)
		var log := _trace(sim, p1, echo)
		await t.run_ticks(sim, 300)
		var t0: int = sim.tick
		t.check(log["present"][t0 - 1] and log["echo"][t0 - 1] == log["p1"][t0 - 1 - from],
			"%d -> %d: vóór de wissel niet op P1 van D = %d ticks geleden" % [from, to, from])
		echo.set_tail_ticks(to, t0)
		await t.run_ticks(sim, to + 20)
		var leeg := true
		for tick in range(t0, t0 + to):
			leeg = leeg and not log["present"][tick]
		t.check(leeg, "%d -> %d: echo niet Leeg tussen t0 en t0 + %d" % [from, to, to])
		t.check(log["present"][t0 + to] and log["echo"][t0 + to] == log["p1"][t0],
			"%d -> %d: op t0 + %d niet op de positie van P1 op t0" % [from, to, to])
		t.check(echo.tail_ticks == to and sim.combat.tail_ticks == to,
			"%d -> %d: D van echo %d, van Combat %d" % [from, to, echo.tail_ticks, sim.combat.tail_ticks])
		await t.run_ticks(sim, 600)
		t.check(p1.recorder.size() == 600, "%d -> %d: recorder %d frames (600)" % [from, to, p1.recorder.size()])
		await t.cleanup()


## (alle D) Reset op t0; P1 deed op t0 − 5 INTERACTIE bij een schaduwhendel.
## Frames van vóór t0 worden nooit afgespeeld: de hendel blijft in zijn
## beginstand, de echo is Leeg tot t0 + D.
func test_e03_frames_before_reset_never_play(t) -> void:
	for d: int in ALL_D:
		var sim = Fx.world(t)
		var lever := Lever.new()
		lever.setup(Layers.SHADOW, Vector2(40, 40))
		lever.position = Vector2(200, Fx.STAND_Y)
		sim.add_object(lever)
		var p1 := Fx.p1(sim, [[45, 0], [1, I], [20, R], [400, 0]])
		var echo := Fx.tail_echo(sim, p1, d)
		var log := _trace(sim, p1, echo)
		await t.run_ticks(sim, 50)
		var t0: int = sim.tick
		echo.reset(t0)
		await t.run_ticks(sim, d + 20)
		var leeg := true
		for tick in range(t0, t0 + d):
			leeg = leeg and not log["present"][tick]
		t.check(leeg and log["present"][t0 + d], "D = %d: Leeg/Actief rond t0 + D klopt niet" % d)
		t.check(not lever.on, "D = %d: de hendel ging om door een frame van vóór de reset" % d)
		await t.cleanup()


# --- E-04 ----------------------------------------------------------------

## (alle D) Respawn, Loslaten, wissel van D en breken op t0: echo Leeg op
## t0 + D − 1, Actief op t0 + D, op de positie van P1 op t0.
func test_e04_every_reset_cause_all_d(t) -> void:
	for d: int in ALL_D:
		for cause in ["respawn", "loslaten", "wissel", "breken"]:
			var sim = Fx.world(t)
			var segments := [[400, R]]
			if cause == "loslaten":
				segments = [[220, R], [30, R | E], [200, R]]
			if cause == "breken":
				# P1 loopt door een schaduwmuur (laag 5); de echo breekt er.
				Fx.block(t, "ShadowWall", Rect2(500, 300, 20, 100), Layers.SHADOW_GEOMETRY)
			var p1 := Fx.p1(sim, segments)
			var echo := Fx.tail_echo(sim, p1, d)
			var log := _trace(sim, p1, echo)
			var broke := _breaks(echo)
			await t.run_ticks(sim, 250)
			if cause == "respawn":
				p1.respawn_at(Vector2(300, Fx.STAND_Y))
			elif cause == "wissel":
				echo.set_tail_ticks(d, sim.tick)
			await t.run_ticks(sim, 1)
			if cause == "breken":
				await t.run_ticks(sim, 250 + d)
			var t0 := echo.valid_from
			await t.run_ticks(sim, maxi(0, t0 + d + 1 - sim.tick))
			var expected_t0 := {"respawn": 250, "loslaten": 249, "wissel": 250}
			if cause in expected_t0:
				t.check(t0 == expected_t0[cause], "D = %d, %s: reset op %d (verwacht %d)" % [
					d, cause, t0, expected_t0[cause]])
			else:
				t.check(broke.size() >= 1 and broke[0] == t0, "D = %d, breken: geen breuk (%s)" % [d, str(broke)])
			t.check(not log["present"][t0 + d - 1] and log["present"][t0 + d]
				and log["echo"][t0 + d] == log["p1"][t0],
				"D = %d, %s: niet Leeg op t0 + D − 1 en Actief op t0 + D op P1 van t0" % [d, cause])
			await t.cleanup()


# --- E-08 ----------------------------------------------------------------

## E-08a: 2 px overlap met een schaduwmuur breekt niet; 3 px breekt op de 3e
## tick; 2 ticks overlap (daarna vrij) breekt niet.
func test_e08a_free_with_tolerance(t) -> void:
	for overlap in [2, 3]:
		var sim = Fx.world(t)
		Fx.block(t, "ShadowWall", Rect2(308 - overlap, 300, 30, 100), Layers.SHADOW_GEOMETRY)
		var ghost := Fx.ghost(t)
		Fx.ghost_path(ghost, 0, 100, func(_k: int) -> Vector2: return Vector2(300, Fx.STAND_Y))
		var echo := Fx.tail_echo(sim, ghost, 1)
		var broke := _breaks(echo)
		await t.run_ticks(sim, 30)
		if overlap == 2:
			t.check(broke.is_empty(), "2 px overlap brak de echo op tick %s" % str(broke))
		else:
			t.check(not broke.is_empty() and broke[0] == 3 and echo.valid_from >= 3,
				"3 px overlap: eerste breuk op %s (tick 3, de 3e tick van overlap)" % str(broke))
		await t.cleanup()
	var sim = Fx.world(t)
	Fx.block(t, "ShadowWall", Rect2(305, 300, 30, 100), Layers.SHADOW_GEOMETRY)
	var ghost := Fx.ghost(t)
	Fx.ghost_path(ghost, 0, 100, func(k: int) -> Vector2: return Vector2(300 if k < 2 else 250, Fx.STAND_Y))
	var echo := Fx.tail_echo(sim, ghost, 1)
	var broke := _breaks(echo)
	await t.run_ticks(sim, 30)
	t.check(broke.is_empty() and echo.is_present(), "2 ticks overlap brak de echo")


## E-08b: over een lichtbrug zonder schaduwbrug breekt de echo aan de rand;
## met een schaduwbrug loopt hij door.
func test_e08b_light_bridge_needs_shadow_support(t) -> void:
	for shadow_bridge in [false, true]:
		var sim = t.make_sim(false)
		Fx.block(t, "FloorLeft", Rect2(-200, 400, 500, 40), Layers.WORLD)
		Fx.block(t, "FloorRight", Rect2(400, 400, 600, 40), Layers.WORLD)
		Fx.block(t, "LightBridge", Rect2(300, 400, 100, 10), Layers.LIGHT_GEOMETRY)
		if shadow_bridge:
			Fx.block(t, "ShadowBridge", Rect2(300, 400, 100, 10), Layers.SHADOW_GEOMETRY)
		var p1 := Fx.p1(sim, [[300, R]])
		var echo := Fx.tail_echo(sim, p1, 90)
		var log := _trace(sim, p1, echo)
		var at: Array = []
		var when: Array = []
		echo.broke.connect(func(tick: int, where: Vector2) -> void:
			when.append(tick)
			at.append(where))
		await t.run_ticks(sim, 300)
		if shadow_bridge:
			t.check(at.is_empty() and echo.position.x > 400.0, "echo brak op de schaduwbrug: %s" % str(at))
		else:
			# De steun faalt zodra de proef (x ± 7,99) de linkervloer (tot 300)
			# niet meer raakt. Breuk op de 3e slechte tick (G = 3); het effect
			# staat op de laatste geldige positie: 3 ticks vóór de breuk.
			t.check(when.size() >= 1 and at[0] == log["echo"][when[0] - 3],
				"breek-effect niet op de laatste geldige positie: %s op tick %s" % [str(at), str(when)])
			t.check(not at.is_empty() and at[0].x <= 307.99 and at[0].x > 305.0,
				"laatste geldige positie %s (x in 305–307,99)" % str(at))
		await t.cleanup()


## (alle D) P1 springt op zijn echo, staat erop en loopt eraf. D ticks later
## zweeft de echo op de opgenomen posities, breekt niet en `geldig_vanaf`
## blijft gelijk.
func test_e08b_echo_floats_where_p1_stood_on_it_all_d(t) -> void:
	for d: int in ALL_D:
		var sim = Fx.world(t)
		# Springen op tick D + 10: dan staat de echo (Actief vanaf D) onder P1.
		var p1 := Fx.p1(sim, [[d + 10, 0], [1, J], [59, 0], [40, R], [400, 0]])
		var echo := Fx.tail_echo(sim, p1, d)
		var broke := _breaks(echo)
		var floating := {"ticks": 0}
		sim.tick_finished.connect(func(_tick: int) -> void:
			if echo.is_present() and echo.support == Motor.Support.SHADOW_BODY \
					and absf(echo.position.y - Fx.ON_ECHO_Y) < 0.1:
				floating["ticks"] += 1)
		await t.run_ticks(sim, 2 * d + 170)
		t.check(floating["ticks"] >= 20, "D = %d: echo zweefde maar %d ticks" % [d, floating["ticks"]])
		t.check(broke.is_empty() and echo.valid_from == 0, "D = %d: echo brak (%s)" % [d, str(broke)])
		await t.cleanup()


## E-08b met een spookbron: een zwevende echo (steun schaduwlichaam) breekt
## niet; staat er een schaduwmuur, dan breekt hij wel (E-08a). Sinds E-07c
## (gdd v0.5) draagt een zwevende echo niet meer: stond P1 in het frame op een
## plank (`plank_sinds_grond`), dan valt een P1 erdoor; zonder die vlag landt hij.
func test_e08b_floating_echo_carries_only_from_ground_and_walls_break(t) -> void:
	for variant in ["muur", "zweeft", "vanaf_grond"]:
		var sim = Fx.world(t)
		if variant == "muur":
			Fx.block(t, "ShadowWall", Rect2(290, 280, 30, 40), Layers.SHADOW_GEOMETRY)
		var ghost := Fx.ghost(t)
		Fx.ghost_path(ghost, 0, 100, func(_k: int) -> Vector2: return Vector2(300, 300),
			true, Motor.Support.SHADOW_BODY, variant != "vanaf_grond")
		var echo := Fx.tail_echo(sim, ghost, 1)
		var broke := _breaks(echo)
		var p1 := Fx.p1(sim, [], Vector2(300, 250))
		await t.run_ticks(sim, 40)
		if variant == "muur":
			t.check(not broke.is_empty() and broke[0] == 3, "schaduwmuur: breuk op %s (tick 3)" % str(broke))
		elif variant == "zweeft":
			t.check(broke.is_empty() and echo.is_present(), "zwevende echo brak: %s" % str(broke))
			t.check(p1.motor.support != Motor.Support.SHADOW_BODY and p1.position.y > 300.0,
				"E-07c: P1 viel niet door de zwevende echo: %s" % p1.position)
		else:
			t.check(broke.is_empty() and echo.is_present(), "echo brak: %s" % str(broke))
			t.check(p1.motor.support == Motor.Support.SHADOW_BODY and absf(p1.position.y - 270.0) < 0.1,
				"P1 landde niet op de dragende echo: %s" % p1.position)
		await t.cleanup()


## E-08c: de echo breekt op de tick waarop zijn middelpunt fel licht in komt.
## E-08d: hij breekt op de eerste tick van overlap met een schaduwgevaar; P1
## in dezelfde zone merkt niets.
func test_e08c_d_fel_licht_and_gevaar(t) -> void:
	for kind in [Zone.Kind.FEL_LICHT, Zone.Kind.GEVAAR]:
		var sim = Fx.world(t)
		var rect := Rect2(400, 300, 100, 100) if kind == Zone.Kind.FEL_LICHT else Rect2(400, 300, 20, 100)
		Fx.zone(t, kind, rect)
		var ghost := Fx.ghost(t)
		Fx.ghost_path(ghost, 0, 200, func(k: int) -> Vector2: return Vector2(301 + 2.0 * k, Fx.STAND_Y))
		var echo := Fx.tail_echo(sim, ghost, 1)
		var broke := _breaks(echo)
		var p1 := Fx.p1(sim, [[150, R]], Vector2(380, Fx.STAND_Y))
		await t.run_ticks(sim, 60)
		# Fel licht: middelpunt 401 op frame 50 (tick 51). Gevaar: rand 393 + 8 > 400 op frame 46 (tick 47).
		var expected := 51 if kind == Zone.Kind.FEL_LICHT else 47
		t.check(not broke.is_empty() and broke[0] == expected,
			"zone %d: breuk op %s (verwacht tick %d)" % [kind, str(broke), expected])
		t.check(p1.position.x > 490.0, "P1 werd door de zone gehinderd: %s" % p1.position)
		await t.cleanup()


## E-08 (events): bevat het frame van de breektick een INTERACTIE bij een
## schaduwhendel, dan gaat de hendel niet om. Zonder muur wel.
func test_e08_no_events_on_break_tick(t) -> void:
	for wall in [true, false]:
		var sim = Fx.world(t)
		if wall:
			Fx.block(t, "ShadowWall", Rect2(305, 300, 30, 100), Layers.SHADOW_GEOMETRY)
		var lever := Lever.new()
		lever.setup(Layers.SHADOW, Vector2(40, 40))
		lever.position = Vector2(300, Fx.STAND_Y)
		sim.add_object(lever)
		var ghost := Fx.ghost(t)
		for k in 100:
			Fx.ghost_frame(ghost, k, Vector2(300, Fx.STAND_Y), true, Motor.Support.WORLD,
				GameEvents.INTERACT if k == 2 else 0)
		var echo := Fx.tail_echo(sim, ghost, 1)
		var broke := _breaks(echo)
		await t.run_ticks(sim, 10)
		if wall:
			t.check(broke.size() >= 1 and broke[0] == 3 and not lever.on,
				"breuk op %s, hendel %s (breuk op 3, hendel uit)" % [str(broke), lever.on])
		else:
			t.check(broke.is_empty() and lever.on, "zonder muur ging de hendel niet om")
		await t.cleanup()


# --- E-09 ----------------------------------------------------------------

## 30 ticks ECHO: breekt op de 30e tick; 29: niet; 90 vasthouden: één keer.
## Bij een Lege echo wordt `geldig_vanaf` toch gezet, zonder breek-effect.
func test_e09_release(t) -> void:
	for hold in [29, 30, 90]:
		var sim = Fx.world(t)
		var p1 := Fx.p1(sim, [[100, 0], [hold, E], [100, 0]])
		var echo := Fx.tail_echo(sim, p1, 90)
		var broke := _breaks(echo)
		await t.run_ticks(sim, 250)
		if hold == 29:
			t.check(broke.is_empty() and echo.valid_from == 0, "29 ticks ECHO liet de echo los")
		else:
			t.check(broke == [129] and echo.valid_from == 129,
				"%d ticks ECHO: breuk %s, geldig_vanaf %d (één keer, tick 129)" % [hold, str(broke), echo.valid_from])
		await t.cleanup()
	var sim = Fx.world(t)
	var p1 := Fx.p1(sim, [[10, 0], [30, E], [100, 0]])
	var echo := Fx.tail_echo(sim, p1, 90)
	var broke := _breaks(echo)
	await t.run_ticks(sim, 60)
	t.check(broke.is_empty() and echo.valid_from == 39,
		"Lege echo: breuk %s, geldig_vanaf %d (geen effect, 39)" % [str(broke), echo.valid_from])
