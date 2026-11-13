extends RefCounted
## Tests voor fase 2 van de Gemaalmeester, het grote rad (T8b-bouw deel 2b, #190): B-8 uit
## `docs/design/combat/slice-vijanden-en-boss.md` v0.1.2 §3.2 (GMB-04), §3.5, §3.8, §6 en §7, en
## B-13 uit v0.1.3 (#218), bijgesteld in v0.1.5 (#247): radtreffer 33 (in co-op 25, `coop_schaal` 1,32), `kant_ticks` 480, het rad in co-op vast op
## 94 px van de muur (`rad_coop_muur`), en trillen en draaien bij een wissel van modus in fase 2.
##
## Gevallen "(alle D)" draaien op D = 60, 120 en 180, met 90 als regressie. De arena en de bot komen
## uit `test_boss_runs.gd` en `boss_bot.gd`; alle waarden uit `slice.csv`.

const Fx = preload("res://tests/echo_fixture.gd")
const Runs = preload("res://tests/test_boss_runs.gd")
const BossBot = preload("res://tests/boss_bot.gd")
const PlayerActor = preload("res://scripts/echo/player_actor.gd")
const Gemaalmeester = preload("res://scripts/combat/gemaalmeester.gd")
const EnemyData = preload("res://scripts/combat/enemy_data.gd")
const InputBits = preload("res://scripts/input/input_bits.gd")
const Motor = preload("res://scripts/echo/motor.gd")
const Layers = preload("res://scripts/world/layers.gd")

const ALL_D := [60, 120, 180, 90]
const MAX_FRAMES := {
	"test_b8_jump_never_hits_rad": 30000, "test_b8_turn_bounce_hits_rad": 22000,
	"test_b8_launch_neerslag_two_hits": 16000, "test_b8_coop_bounce_on_p2_every_x": 30000,
}

var _runs := Runs.new()


## De SE van de fasewissel: de laatste drempel van fase 1 (GMB-11, `slice.csv`; v0.1.5: 1050).
static func _switch_se() -> int:
	var g := "gemaalmeester"
	return EnemyData.ticks(g, "drempel_%d" % EnemyData.ticks(g, "openingen"))


## Arena met de Gemaalmeester en P1 met handmatige input, zonder echo (D = `d`); de boss in fase 2
## (debug op de laatste drempel van fase 1, `_switch_se()`; na de fasewissel van 60 ticks hangt het rad). Met `coop` staat P2 (handmatig)
## er al vóór de fasewissel, op x = 340.
func _phase2_manual(t, d: int, x := 200.0, coop := false) -> Dictionary:
	var sim = Fx.world(t)
	Fx.block(t, "MuurLinks", Rect2(-40, Fx.FLOOR_TOP - 400, 40, 400), Layers.WORLD)
	Fx.block(t, "MuurRechts", Rect2(600, Fx.FLOOR_TOP - 400, 40, 400), Layers.WORLD)
	var p1 := Fx.manual_player(sim, 1, Vector2(x, Fx.STAND_Y))
	p1.health = 100000
	var p2: PlayerActor = Fx.manual_player(sim, 2, Vector2(340, Fx.STAND_Y)) if coop else null
	sim.set_tail_ticks(d)
	var boss := Gemaalmeester.new()
	boss.setup_gemaalmeester(Vector2(0, Fx.FLOOR_TOP))
	boss.attach(sim)
	await t.run_ticks(sim, 2)
	boss.set_health(sim.tick, _switch_se())
	await t.run_ticks(sim, 61)
	return {"sim": sim, "p1": p1, "p2": p2, "boss": boss}


## Een run van de bot vanaf fase 2 (debug op `_switch_se()`), met de radtreffers in `rad`.
func _phase2_bot(t, d: int, coop: bool) -> Dictionary:
	var run: Dictionary = _runs._arena(t, d, coop)
	run["rad"] = []
	run["boss"].rad_hit.connect(func(tick: int, source: String, action: String, amount: int) -> void:
		run["rad"].append([tick, source, action, amount]))
	await t.run_ticks(run["sim"], 2)
	run["boss"].set_health(run["sim"].tick, _switch_se())
	return run


# --- plaats, schade, kanten ----------------------------------------------------------

## GMB-04, §7 (alle D): het rad is 96 × 40 op y 100–140, middelpunt `D + 34` van de muur aan zijn
## kant (60: 94 / 506; 120: 154 / 446; 180: 214 / 386); vloerteken van D tot D + 68; niet `Merkbaar`;
## in fase 1 niet raakbaar. Een wissel van D (debugmenu, SL-05) verplaatst het hangende rad mee.
## B-13 en v0.1.5 (#247, LGD): de waarden in slice.csv (33, 480, 1,32, 94; `kant_treffers` blijft 2).
func test_b8_rad_place_per_d(t) -> void:
	var g := "gemaalmeester"
	t.check(EnemyData.ticks(g, "rad_treffer") == 33 and EnemyData.ticks(g, "rad_echo") == 5
		and EnemyData.ticks(g, "kant_treffers") == 2 and EnemyData.ticks(g, "kant_ticks") == 480
		and EnemyData.ticks(g, "rad_tril") == 20 and EnemyData.ticks(g, "rad_draai") == 60
		and EnemyData.value(g, "rad_offset") == 34.0 and is_equal_approx(EnemyData.value(g, "coop_schaal"), 1.32)
		and EnemyData.value(g, "rad_coop_muur") == 94.0,
		"rad-waarden in slice.csv (§3.5, v0.1.5: 33, 2, 480, 20, 60, 34, 1,32, 94)")
	for d: int in ALL_D:
		var w := await _phase2_manual(t, d)
		var boss: Gemaalmeester = w["boss"]
		var side := boss.rad_side
		var want := float(d + 34) if side < 0 else 600.0 - (d + 34)
		var size: Vector2 = boss.rad.shape.get_rect().size
		var rect := Rect2(boss.rad.global_position - size * 0.5, size)
		t.check(boss.rad_state == Gemaalmeester.RadState.HANGING and boss.is_rad_hittable() and not boss.rad.is_markable(),
			"D = %d: rad hangt niet raakbaar, of is Merkbaar" % d)
		t.check(is_equal_approx(boss.rad.position.x, want) and size == Vector2(96, 40)
			and is_equal_approx(Fx.FLOOR_TOP - rect.end.y, 100.0) and is_equal_approx(Fx.FLOOR_TOP - rect.position.y, 140.0),
			"D = %d: rad op %s, vlak %s (middelpunt %s)" % [d, boss.rad.position, rect, want])
		t.check(boss.floor_mark(-1) == Vector2(d, d + 68) and boss.floor_mark(1) == Vector2(600 - d - 68, 600 - d),
			"D = %d: vloerteken %s / %s" % [d, boss.floor_mark(-1), boss.floor_mark(1)])
		var visual := boss.get_node("Vloerteken") as Polygon2D
		var span := boss.floor_mark(side)
		t.check(visual.visible and visual.polygon[0].x == span.x and visual.polygon[1].x == span.y,
			"D = %d: vloerteken niet in beeld" % d)
		# SL-05: D wisselt terwijl het rad hangt.
		var other := 120 if d != 120 else 60
		w["sim"].set_tail_ticks(other)
		await t.run_ticks(w["sim"], 1)
		var want2 := float(other + 34) if side < 0 else 600.0 - (other + 34)
		t.check(is_equal_approx(boss.rad.position.x, want2), "D %d → %d: rad op %s (%s)" % [d, other, boss.rad.position.x, want2])
		await t.cleanup()
	# Fase 1: het rad is er niet (niet raakbaar, niet in beeld).
	var sim = Fx.world(t)
	Fx.manual_player(sim, 1, Vector2(200, Fx.STAND_Y))
	sim.set_tail_ticks(60)
	var b1 := Gemaalmeester.new()
	b1.setup_gemaalmeester(Vector2(0, Fx.FLOOR_TOP))
	b1.attach(sim)
	await t.run_ticks(sim, 3)
	t.check(not b1.is_rad_hittable() and not (b1.get_node("RadBeeld") as CanvasItem).visible, "rad in fase 1")
	await t.cleanup()


## §3.5: een treffer van P1 op het rad doet `rad_treffer` SE (v0.1.5: 33), van de echo 5, geen merk; na 2
## treffers van P1 (de echo telt niet) trilt het 20 ticks en draait het in 60 ticks naar de andere muur
## (RAD_DRAAI "treffers"); trillen en draaien zijn niet raakbaar; na 480 ticks zonder 2 treffers draait
## het ook ("tijd"). Schermschok 3 ticks / 1 px per treffer (B-11).
func test_b8_damage_and_turning(t) -> void:
	var w := await _phase2_manual(t, 60)
	var sim = w["sim"]
	var boss: Gemaalmeester = w["boss"]
	var turns := []
	boss.rad_turning.connect(func(tick: int, reason: String, to_side: int) -> void: turns.append([tick, reason, to_side]))
	var hits := []
	boss.rad_hit.connect(func(tick: int, source: String, action: String, amount: int) -> void:
		hits.append([tick, source, action, amount]))
	var side := boss.rad_side
	var at := boss.rad.global_position - Vector2(18, 0)
	var tick: int = sim.tick
	var f := _switch_se()
	var r := EnemyData.ticks("gemaalmeester", "rad_treffer")
	var e := EnemyData.ticks("gemaalmeester", "rad_echo")
	# Rechtstreeks via Combat tussen twee ticks: de echo, dan P1 twee keer.
	sim.combat.attack(tick, "echo", Layers.SHADOW, at, 1)
	t.check(boss.se == f - e and boss.rad_side_hits == 0, "echo: %d SE, kant %d (%d, 0)" % [boss.se, boss.rad_side_hits, f - e])
	sim.combat.attack(tick, "p1", Layers.LIGHT, at, 1)
	t.check(boss.se == f - e - r and boss.rad_side_hits == 1 and boss.shake_at(tick) == 1.0 and boss.shake_at(tick + 3) == 0.0,
		"P1: %d SE, kant %d, schok %s" % [boss.se, boss.rad_side_hits, boss.shake_at(tick)])
	t.check(sim.combat.mark_on(boss.rad) == null, "merk op het rad")
	sim.combat.attack(tick, "p1", Layers.LIGHT, at, 1)
	await t.run_ticks(sim, 1)
	t.check(boss.se == f - e - 2 * r and hits.map(func(h: Array) -> int: return h[3]) == [e, r, r]
		and hits.map(func(h: Array) -> String: return h[1]) == ["echo", "p1", "p1"], "treffers %s" % [hits])
	t.check(turns.size() == 1 and turns[0][1] == "treffers" and turns[0][2] == -side and not boss.is_rad_hittable(),
		"na 2 treffers: %s" % [turns])
	var s0: int = turns[0][0]
	await t.run_ticks(sim, 15)
	sim.combat.attack(sim.tick, "p1", Layers.LIGHT, at, 1)
	t.check(boss.se == f - e - 2 * r and boss.rad_state == Gemaalmeester.RadState.SHAKING, "raakbaar tijdens trillen")
	await t.run_ticks(sim, 30)
	t.check(boss.rad_state == Gemaalmeester.RadState.TURNING and not boss.is_rad_hittable(), "draait niet of is raakbaar")
	await _runs._run_until(t, sim, func() -> bool: return boss.is_rad_hittable(), 200, 1)
	t.check(boss.rad_side == -side and boss.rad_since() == s0 + 80 and is_equal_approx(boss.rad.position.x, boss.rad_x(-side)),
		"hangt sinds %d (verwacht %d) aan kant %d" % [boss.rad_since(), s0 + 80, boss.rad_side])
	# Tijd: 480 ticks zonder treffers (v0.1.3).
	var hang2: int = boss.rad_since()
	await _runs._run_until(t, sim, func() -> bool: return turns.size() == 2, 600, 1)
	t.check(turns.size() == 2 and turns[1][1] == "tijd" and turns[1][0] == hang2 + 480, "tijd: %s (hangt sinds %d)" % [turns, hang2])
	await t.cleanup()


## §3.8 (v0.1.5, #247): in co-op deelt `coop_schaal` = 1,32 de radschade (33 → 25 SE, P1 en P2);
## Wankel op `wankel_se` (GMB-13, v0.1.5: 350) klemt de laatste radtreffer en maakt het rad niet raakbaar. P2 komt
## erbij in fase 2 bij D = 60: de co-op-plek (94) is de solo-plek, dus het rad blijft hangen.
func test_b8_coop_scale_and_wankel(t) -> void:
	var w := await _phase2_manual(t, 60)
	var sim = w["sim"]
	var boss: Gemaalmeester = w["boss"]
	var turns := []
	boss.rad_turning.connect(func(tick: int, reason: String, _s: int) -> void: turns.append([tick, reason]))
	var before: float = boss.rad.position.x
	Fx.manual_player(sim, 2, Vector2(300, Fx.STAND_Y))
	await t.run_ticks(sim, 2)
	t.check(sim.combat.coop, "geen co-op")
	t.check(turns.is_empty() and boss.is_rad_hittable() and boss.rad.position.x == before,
		"drop-in bij D = 60: rad %s → %s, draaien %s (blijft hangen)" % [before, boss.rad.position.x, turns])
	var at := boss.rad.global_position - Vector2(18, 0)
	var f := _switch_se()
	sim.combat.attack(sim.tick, "p2", Layers.SHADOW, at, 1)
	t.check(boss.se == f - 25, "P2 in co-op: %d SE (%d: 25)" % [boss.se, f - 25])
	sim.combat.attack(sim.tick, "p1", Layers.LIGHT, at, 1)
	t.check(boss.se == f - 50, "P1 in co-op: %d SE (%d: 25)" % [boss.se, f - 50])
	# Twee treffers: het rad draait weg; wachten tot het aan de andere kant hangt.
	await t.run_ticks(sim, 1)
	await _runs._run_until(t, sim, func() -> bool: return boss.is_rad_hittable(), 200, 1)
	at = boss.rad.global_position - Vector2(18, 0)
	var wankel := EnemyData.ticks("gemaalmeester", "wankel_se")
	boss.set_health(sim.tick, wankel + 10)
	sim.combat.attack(sim.tick, "p1", Layers.LIGHT, at, 1)
	t.check(boss.se == wankel and boss.is_wankel() and not boss.is_rad_hittable(), "Wankel: %d SE, raakbaar %s" % [boss.se, boss.is_rad_hittable()])
	await t.cleanup()


# --- B-8 (1)–(4) ---------------------------------------------------------------------

## B-8 (1) (alle D): sprong + aanval (op de top, voeten op 50 px) op elke x van de vloer (stap 4 px,
## gemeten van de muur aan de kant van het rad) raakt het rad nooit, terwijl het raakbaar hangt; het
## aanvalsvlak reikt tot 73 px.
func test_b8_jump_never_hits_rad(t) -> void:
	for d: int in ALL_D:
		var w := await _phase2_manual(t, d)
		var sim = w["sim"]
		var p1: PlayerActor = w["p1"]
		var boss: Gemaalmeester = w["boss"]
		var hits := []
		boss.rad_hit.connect(func(tick: int, _s: String, _a: String, _n: int) -> void: hits.append(tick))
		var tested := 0
		var top := 0.0
		var from_wall := 8.0
		while from_wall <= 592.0:
			# Afstand tot de muur aan de kant van het rad (de arena is symmetrisch): zo telt elke x
			# van de vloer, met het rad raakbaar, zonder op een bepaalde kant te wachten.
			# Een sprong duurt 22 ticks: niet meer beginnen vlak voor `kant_ticks` (het rad draait dan weg).
			if not boss.is_rad_hittable() or sim.tick - boss.rad_since() > EnemyData.ticks("gemaalmeester", "kant_ticks") - 25:
				await t.run_ticks(sim, 1)
				continue
			var x := from_wall if boss.rad_side < 0 else 600.0 - from_wall
			p1.position = Vector2(x, Fx.STAND_Y)
			p1.velocity = Vector2.ZERO
			p1.motor = Motor.State.new()
			p1.motor.facing = 1 if x < boss.rad.position.x else -1
			await t.run_ticks(sim, 2)
			p1.input_source.bits = InputBits.JUMP
			await t.run_ticks(sim, 1)
			p1.input_source.bits = 0
			await t.run_ticks(sim, 18)
			p1.input_source.bits = InputBits.ATTACK
			await t.run_ticks(sim, 1)
			p1.input_source.bits = 0
			top = maxf(top, Fx.FLOOR_TOP - p1.position.y + 8.0)
			t.check(boss.is_rad_hittable(), "D = %d, %s px van de muur: rad niet raakbaar bij de slag" % [d, from_wall])
			tested += 1
			from_wall += 4.0
		t.check(hits.is_empty() and tested == 147, "D = %d: %d sprongen, rad geraakt op %s" % [d, tested, hits])
		t.check(top > 70.0 and top <= 73.5, "D = %d: aanvalsvlak tot %.1f px (73)" % [d, top])
		await t.cleanup()


## B-8 (2) (alle D): keren tegen de muur en bouncen op de echo raakt het rad (RAD_TREFFER p1/bounce),
## ook met de late bot (bounce 4 en 8 ticks te laat).
func test_b8_turn_bounce_hits_rad(t) -> void:
	for d: int in ALL_D:
		for late: int in [0, 4, 8]:
			var run := await _phase2_bot(t, d, false)
			run["bot"].bounce_delay = late
			var rad: Array = run["rad"]
			await _runs._run_until(t, run["sim"], func() -> bool: return not rad.is_empty(), 1500, 5)
			var first: Array = rad[0] if not rad.is_empty() else []
			t.check(not first.is_empty() and first[1] == "p1" and first[2] == "bounce" and first[3] == EnemyData.ticks("gemaalmeester", "rad_treffer"),
				"D = %d, %d te laat: eerste radtreffer %s" % [d, late, first])
			await t.cleanup()


## B-8 (3) (alle D): de lancering (C-11, solo op de echo in houding) en de neerslag (V-01) geven 2
## treffers op het rad zonder te landen (RAD_TREFFER lancering, dan stuit; STUIT in het meetlog).
func test_b8_launch_neerslag_two_hits(t) -> void:
	for d: int in ALL_D:
		var run := await _phase2_bot(t, d, false)
		run["bot"].use_launch = true
		var p1: PlayerActor = run["p1"]
		var rad: Array = run["rad"]
		var landed := []
		run["sim"].tick_finished.connect(func(tick: int) -> void:
			if rad.size() == 1 and p1.motor.on_floor:
				landed.append(tick))
		await _runs._run_until(t, run["sim"], func() -> bool: return rad.size() >= 2, 1800, 5)
		var actions: Array = rad.map(func(h: Array) -> String: return "%s/%s" % [h[1], h[2]])
		t.check(actions.slice(0, 2) == ["p1/lancering", "p1/stuit"] and landed.is_empty(),
			"D = %d: treffers %s, geland tussendoor op %s" % [d, actions, landed])
		# B-10: de stuit en de radtreffers staan in het meetlog.
		var log = run["log"]
		t.check(log.count("STUIT") >= 1 and log.count("RAD_TREFFER") == rad.size() and log.count("LANCERING") >= 1,
			"D = %d: STUIT %d, RAD_TREFFER %d, LANCERING %d" % [d, log.count("STUIT"), log.count("RAD_TREFFER"), log.count("LANCERING")])
		await t.cleanup()


## B-8 (4) en B-13: co-op, het rad hangt bij D = 60 / 120 / 180 op 94 px van de muur
## (`rad_coop_muur`); P2 staat op elke x onder het rad (stap 8 px, het midden ± 48): P1 springt op
## hem, bouncet en raakt het rad.
func test_b8_coop_bounce_on_p2_every_x(t) -> void:
	for d: int in [60, 120, 180]:
		for k in range(13):
			var w := await _phase2_manual(t, d, 200.0, true)
			var sim = w["sim"]
			var boss: Gemaalmeester = w["boss"]
			var cx := boss.rad_x(boss.rad_side)
			t.check(is_equal_approx(cx, 94.0 if boss.rad_side < 0 else 506.0) and is_equal_approx(boss.rad.position.x, cx),
				"D = %d co-op: rad op %s (94 px van de muur)" % [d, boss.rad.position.x])
			var x2 := cx - 48.0 + 8.0 * k
			var p2: PlayerActor = w["p2"]
			p2.position = Vector2(x2, Fx.STAND_Y)
			p2.velocity = Vector2.ZERO
			var bot := BossBot.new(sim, boss)
			var p1: PlayerActor = w["p1"]
			p1.input_source = bot.p1_source
			p1.position = Vector2(cx + (60.0 if cx < 300.0 else -60.0), Fx.STAND_Y)
			var rad := []
			boss.rad_hit.connect(func(tick: int, source: String, action: String, _n: int) -> void:
				rad.append([tick, source, action]))
			await _runs._run_until(t, sim, func() -> bool: return not rad.is_empty(), 170, 1)
			t.check(not rad.is_empty() and rad[0][1] == "p1" and rad[0][2] == "bounce" and absf(p2.position.x - x2) < 0.01,
				"D = %d, P2 op %s (midden %s): %s" % [d, x2, cx, rad])
			await t.cleanup()


# --- B-13: de plek van het rad in co-op en een wissel van modus in fase 2 --------------------

## B-13 (GMB-04, §3.5): in co-op hangt het rad bij elke D op 94 px van de muur (bij de fasewissel en
## na elke kant). Solo bij D = 120 hangt het op 154. Een drop-out in fase 2 bij D = 120 (co-op → solo)
## laat het rad meteen trillen (RAD_DRAAI "modus", 20 ticks) en in 60 ticks naar `D + 34` aan de andere
## muur draaien; een drop-in bij D = 120 (solo → co-op) naar 94 aan de andere muur.
func test_b13_rad_coop_place_and_mode_switch(t) -> void:
	for d: int in [60, 120, 180]:
		var w := await _phase2_manual(t, d, 200.0, true)
		var boss: Gemaalmeester = w["boss"]
		var want := 94.0 if boss.rad_side < 0 else 506.0
		t.check(boss.rad_state == Gemaalmeester.RadState.HANGING and is_equal_approx(boss.rad.position.x, want),
			"co-op D = %d: rad op %s (%s)" % [d, boss.rad.position.x, want])
		t.check(boss.floor_mark(-1) == Vector2(60, 128), "co-op D = %d: vloerteken %s (60–128)" % [d, boss.floor_mark(-1)])
		await t.cleanup()
	for case: String in ["drop-out", "drop-in"]:
		var coop := case == "drop-out"
		var w := await _phase2_manual(t, 120, 200.0, coop)
		var sim = w["sim"]
		var boss: Gemaalmeester = w["boss"]
		var side := boss.rad_side
		var turns := []
		boss.rad_turning.connect(func(tick: int, reason: String, to_side: int) -> void: turns.append([tick, reason, to_side]))
		var at_hang: float = boss.rad.position.x
		var t0: int = sim.tick
		if coop:
			sim.drop_out()
		else:
			Fx.manual_player(sim, 2, Vector2(340, Fx.STAND_Y))
		await t.run_ticks(sim, 1)
		t.check(turns.size() == 1 and turns[0][1] == "modus" and turns[0][2] == -side and turns[0][0] <= t0 + 1
			and boss.rad_state == Gemaalmeester.RadState.SHAKING and not boss.is_rad_hittable(),
			"%s bij D = 120: draaien %s, stand %d (meteen trillen, reden modus)" % [case, turns, boss.rad_state])
		t.check(is_equal_approx(boss.rad.position.x, at_hang), "%s: rad sprong tijdens het trillen naar %s" % [case, boss.rad.position.x])
		var from_wall := 154.0 if coop else 94.0
		var want := from_wall if -side < 0 else 600.0 - from_wall
		await _runs._run_until(t, sim, func() -> bool: return boss.is_rad_hittable(), 200, 1)
		t.check(boss.rad_side == -side and is_equal_approx(boss.rad.position.x, want) and boss.rad_since() == turns[0][0] + 80,
			"%s: hangt op %s aan kant %d sinds %d (verwacht %s, kant %d, %d)" % [case, boss.rad.position.x, boss.rad_side,
				boss.rad_since(), want, -side, turns[0][0] + 80])
		await t.cleanup()
