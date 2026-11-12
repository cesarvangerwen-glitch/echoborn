extends RefCounted
## Tests voor de boss-basis en de Gemaalmeester (T8b-bouw deel 2a, #190): B-5 (`Boss`, de C-14- en
## C-16-test van gdd §4.6 op de testboss en op de Gemaalmeester, arena, reset bij respawn), B-6
## (maat en aanvallen) en B-7 (fase 1: schot, kern, drempels, adds). Bron:
## `docs/design/combat/slice-vijanden-en-boss.md` v0.1.1 §3, §6, §7 en `gemaalmeester.md` v0.2.
##
## Gevallen "(alle D)" draaien op D = 60, 120 en 180, met 90 als regressie. Alle getallen komen uit
## `slice.csv` en `echo_v04.json`; de vaste verwachtingen zijn de waarden uit het ontwerp, zodat een
## typefout in data hier rood wordt. Fase 2 (het rad, B-8) en de scripted runs (B-9) volgen in deel
## 2b; tot dan is de Gemaalmeester alleen via het debugcommando `set_health` Wankel te krijgen.

const Fx = preload("res://tests/echo_fixture.gd")
const InputBits = preload("res://scripts/input/input_bits.gd")
const GameEvents = preload("res://scripts/events/game_events.gd")
const PlayerActor = preload("res://scripts/echo/player_actor.gd")
const TailEcho = preload("res://scripts/echo/tail_echo.gd")
const Combat = preload("res://scripts/combat/combat.gd")
const SliceEnemy = preload("res://scripts/combat/slice_enemy.gd")
const EnemyData = preload("res://scripts/combat/enemy_data.gd")
const Boss = preload("res://scripts/combat/boss.gd")
const Testboss = preload("res://scripts/combat/testboss.gd")
const Gemaalmeester = preload("res://scripts/combat/gemaalmeester.gd")
const LightMeter = preload("res://scripts/light/light_meter.gd")
const Respawn = preload("res://scripts/save/respawn.gd")
const Layers = preload("res://scripts/world/layers.gd")
const Tuning = preload("res://scripts/echo/tuning.gd")

const L := InputBits.LEFT
const R := InputBits.RIGHT
const J := InputBits.JUMP
const A := InputBits.ATTACK
const ALL_D := [60, 120, 180, 90]
## Arena: de boss-node op x = 0, op de bovenkant van de vloer; arena-x = wereld-x.
const ORIGIN := Vector2(0, Fx.FLOOR_TOP)
## Middelpunt van de testboss (hurtbox 32 breed: 129–161).
const TB_X := 145.0
## P1 links van de ketel (276–324), kijkt naar rechts: zijn aanvalsvlak 268–288 raakt hem.
const KETEL_P1_X := 260.0


## Inputbron: elke `period` ticks één tik AANVAL (vanaf `offset`), plus `hold` (bv. kijkrichting).
class Rhythm:
	extends RefCounted
	var period := 20
	var offset := 0
	var hold := 0
	var enabled := true

	func sample(tick: int) -> int:
		var bits := hold
		if enabled and tick >= offset and (tick - offset) % period == 0:
			bits |= InputBits.ATTACK
		return bits


# --- hulpmiddelen ----------------------------------------------------------

## Wereld met P1 (handmatige input) op `x`, en optioneel zijn staart-echo met D = `d`.
func _world(t, x: float, d := -1) -> Dictionary:
	var sim = Fx.world(t)
	var p1 := Fx.manual_player(sim, 1, Vector2(x, Fx.STAND_Y))
	var echo: TailEcho = null
	if d > 0:
		echo = Fx.tail_echo(sim, p1, d)
	else:
		sim.set_tail_ticks(int(Tuning.echo()["tail_ticks"]))
	return {"sim": sim, "p1": p1, "echo": echo}


## P1 (of P2) met een Rhythm-bron op `x`.
func _rhythm_player(sim: Node, index: int, x: float, offset: int, period := 20) -> PlayerActor:
	var source := Rhythm.new()
	source.offset = offset
	source.period = period
	var player := PlayerActor.new()
	player.setup(index, source, Color.WHITE)
	player.position = Vector2(x, Fx.STAND_Y)
	sim.add_player(player)
	return player


func _testboss(sim: Node) -> Testboss:
	var boss := Testboss.new()
	boss.setup_testboss(ORIGIN, TB_X)
	boss.attach(sim)
	return boss


func _gemaalmeester(sim: Node) -> Gemaalmeester:
	var boss := Gemaalmeester.new()
	boss.setup_gemaalmeester(ORIGIN)
	boss.attach(sim)
	return boss


## Houdt de signalen van een boss bij: {naam: [[tick, ...], ...]}.
func _watch(boss: Boss) -> Dictionary:
	var log := {"started": [], "defeated": [], "finisher": [], "strikes": [], "attacks": [], "ended": [],
		"damage": [], "phase": [], "reset": [], "arena": []}
	boss.boss_started.connect(func(tick: int) -> void: log["started"].append(tick))
	boss.boss_defeated.connect(func(tick: int) -> void: log["defeated"].append(tick))
	boss.finisher_started.connect(func(tick: int) -> void: log["finisher"].append(tick))
	boss.finisher_strike.connect(func(tick: int, who: String) -> void: log["strikes"].append([tick, who]))
	boss.attack_started.connect(func(tick: int, kind: String, side: int) -> void:
		log["attacks"].append([tick, kind, side]))
	boss.attack_ended.connect(func(tick: int, kind: String, side: int, hit: bool) -> void:
		log["ended"].append([tick, kind, side, hit]))
	boss.damaged.connect(func(tick: int, amount: int, source: String) -> void:
		log["damage"].append([tick, amount, source]))
	boss.phase_changed.connect(func(tick: int, phase: String) -> void: log["phase"].append([tick, phase]))
	boss.boss_reset.connect(func(tick: int) -> void: log["reset"].append(tick))
	boss.arena_changed.connect(func(tick: int, closed: bool) -> void: log["arena"].append([tick, closed]))
	return log


## AANVAL-events per lichaam, onafhankelijk van de boss gemeten: P1 en P2 uit hun events van de
## tick, de echo als hij op tick `t` Actief is en P1 op `t − D` een AANVAL had (E-02).
func _watch_attacks(sim: Node, p1: PlayerActor, p2: PlayerActor = null) -> Dictionary:
	var seen := {"p1": [], "p2": [], "echo_present": {}}
	# P2 kan verdwijnen (drop-out): een zwakke verwijzing, geen vangst van de node.
	var p2_ref: WeakRef = weakref(p2) if p2 != null else null
	sim.tick_finished.connect(func(tick: int) -> void:
		if p1.tick_events & GameEvents.ATTACK:
			seen["p1"].append(tick)
		var partner: PlayerActor = p2_ref.get_ref() if p2_ref != null else null
		if partner != null and not partner.dissolved and partner.tick_events & GameEvents.ATTACK:
			seen["p2"].append(tick)
		for echo in sim.echoes:
			if echo.is_present():
				seen["echo_present"][tick] = true)
	return seen


## C-14 c: de verwachte finisherslagen [tick, wie] voor `t_f`, vanaf BOSS_START `start`.
func _expected_strikes(seen: Dictionary, d: int, t_f: int, start: int) -> Array:
	var events: Array = []
	for at: int in seen["p1"]:
		events.append([at, "p1"])
		if seen["echo_present"].has(at + d):
			events.append([at + d, "echo"])
	for at: int in seen["p2"]:
		events.append([at, "p2"])
	var out: Array = []
	for e: Array in events:
		var at: int = e[0]
		if at >= t_f - 600 and at < t_f and at >= start:
			out.append([t_f + (at - (t_f - 600)) / 5, e[1]])
	out.sort_custom(func(a: Array, b: Array) -> bool:
		return a[0] < b[0] or (a[0] == b[0] and String(a[1]) < String(b[1])))
	return out


func _sorted(strikes: Array) -> Array:
	var out := strikes.duplicate()
	out.sort_custom(func(a: Array, b: Array) -> bool:
		return a[0] < b[0] or (a[0] == b[0] and String(a[1]) < String(b[1])))
	return out


## Speelt `n` ticks met inputbits `bits` voor `player`.
func _play(t, sim: Node, player: PlayerActor, bits: int, n := 1) -> void:
	player.input_source.bits = bits
	await t.run_ticks(sim, n)
	player.input_source.bits = 0


## Draait tot `sim.tick == tick` (de volgende tick die de Sim verwerkt).
func _run_to(t, sim: Node, tick: int) -> void:
	if tick > sim.tick:
		await t.run_ticks(sim, tick - sim.tick)


## Draait tot `done.call()` waar is, in stukken van `step`, hooguit `limit` ticks.
func _run_until(t, sim: Node, done: Callable, limit: int, step := 20) -> void:
	var until: int = sim.tick + limit
	while sim.tick < until and not done.call():
		await t.run_ticks(sim, mini(step, until - sim.tick))


# --- data -------------------------------------------------------------------

## B-5–B-7: de boss-waarden in `slice.csv` houden de regels van §3 (GMB-02, GMB-10, GMB-11, GMB-13,
## VJ-01) en de testboss die van gdd §4.6 C-14.
func test_b5_boss_data_consistent(t) -> void:
	var g := "gemaalmeester"
	t.check(EnemyData.missing_keys(EnemyData.groups()).is_empty(), "ontbreekt: %s" % EnemyData.missing_keys(EnemyData.groups()))
	var se := EnemyData.ticks(g, "se")
	var thresholds: Array = []
	for i in EnemyData.ticks(g, "openingen"):
		thresholds.append(EnemyData.ticks(g, "drempel_%d" % (i + 1)))
	t.check(se == 1500 and thresholds == [1350, 1200, 1050, 900], "SE %d, drempels %s" % [se, thresholds])
	# GMB-10: fase 1 tot 60 %, Wankel op 20 %.
	t.check(thresholds[-1] * 10 == se * 6 and EnemyData.ticks(g, "wankel_se") * 5 == se, "60 % / 20 % kloppen niet")
	# GMB-02: de merkplek is het middelpunt van het schot, op 24–48 px (GM-06).
	var cx := (EnemyData.value(g, "schot_x1") + EnemyData.value(g, "schot_x2")) * 0.5
	var cy := (EnemyData.value(g, "schot_y1") + EnemyData.value(g, "schot_y2")) * 0.5
	t.check(cx == EnemyData.value(g, "merkplek_x") and cy == EnemyData.value(g, "merkplek_y"),
		"merkplek (%s, %s) ≠ middelpunt van het schot (%s, %s)" % [EnemyData.value(g, "merkplek_x"),
			EnemyData.value(g, "merkplek_y"), cx, cy])
	t.check(cy >= 24.0 and cy <= 48.0, "merkplek op %s px (24–48)" % cy)
	# VJ-01: elke aanloop ≥ 30, elk actief vlak ≤ 8.
	for key: String in ["eerste_aanloop", "pomp1_aanloop", "pomp2_aanloop", "zwiep_aanloop"]:
		t.check(EnemyData.ticks(g, key) >= 30, "%s %d < 30" % [key, EnemyData.ticks(g, key)])
	for key: String in ["pomp1_actief", "pomp2_actief", "zwiep_actief"]:
		t.check(EnemyData.ticks(g, key) <= 8, "%s %d > 8" % [key, EnemyData.ticks(g, key)])
	# De aanval van een maat is klaar vóór de volgende maat.
	t.check(EnemyData.ticks(g, "eerste_aanloop") + EnemyData.ticks(g, "pomp1_actief")
		+ EnemyData.ticks(g, "pomp1_herstel") <= EnemyData.ticks(g, "maat_fase1"), "fase 1 past niet in de maat")
	for k: String in ["pomp2", "zwiep"]:
		t.check(EnemyData.ticks(g, k + "_aanloop") + EnemyData.ticks(g, k + "_actief")
			+ EnemyData.ticks(g, k + "_herstel") <= EnemyData.ticks(g, "maat_fase2"), "%s past niet in de maat" % k)
	t.check(EnemyData.ticks("testboss", "se") == 100 and EnemyData.ticks("testboss", "wankel_se") == 20,
		"testboss %d SE, drempel %d (100, 20)" % [EnemyData.ticks("testboss", "se"), EnemyData.ticks("testboss", "wankel_se")])
	t.check(EnemyData.ticks(g, "finisher_ticks") == 120 and EnemyData.ticks(g, "finisher_bron") == 600,
		"finisher 600 → 120 (C-14 c)")


# --- B-5: de C-14-test op de testboss ----------------------------------------

## B-5 / C-14 (alle D), solo: op 20 SE gezet (debug, zonder merk) is hij Wankel: geen aanval, een
## treffer doet 0 SE; P1 merkt hem op `x`, de echo knalt op `x + D + 3` = `t_f`: FINISHER_START;
## verslagen op `t_f + 120` (niet eerder). FINISHERSLAG = de AANVAL-events van P1 en de Actieve echo
## in `t_f − 600 … t_f − 1` vanaf BOSS_START, elk op `t_f + ⌊i / 5⌋`, elk +1 LP. Tijdens de finisher
## loopt en springt P1, ook door de plek van de gedeelde echo (geen botsing, C-01).
func test_c14_testboss_solo_finisher(t) -> void:
	for d: int in ALL_D:
		# P1 begint buiten de arena: zijn eerste AANVAL valt vóór BOSS_START.
		var w := _world(t, -10.0, d)
		var sim = w["sim"]
		var p1: PlayerActor = w["p1"]
		p1.health = 1000
		var boss := _testboss(sim)
		var log := _watch(boss)
		var seen := _watch_attacks(sim, p1)
		var meter := LightMeter.new(sim, p1)
		meter.watch_boss(boss)
		var lp := {"strike": 0}
		meter.filled.connect(func(_tick: int, _amount: int, added: int, source: String, _who: String) -> void:
			if source == "finisherslag":
				lp["strike"] += 1)
		await _play(t, sim, p1, A)
		await _play(t, sim, p1, R, 65)
		t.check(log["started"].size() == 1 and log["started"][0] > 0, "D = %d: BOSS_START %s" % [d, log["started"]])
		t.check(boss.arena_closed, "D = %d: arena niet dicht na BOSS_START" % d)
		await _run_to(t, sim, 80)
		await _play(t, sim, p1, A)
		await t.run_ticks(sim, 24)
		await _play(t, sim, p1, A)
		await t.run_ticks(sim, d + 60)
		t.check(sim.combat.mark_on(boss.core) == null, "D = %d: nog een merk op de boss" % d)
		t.check(not boss.is_wankel() and boss.se > 20, "D = %d: al Wankel vóór het debugcommando (%d SE)" % [d, boss.se])
		boss.set_health(sim.tick, 20)
		t.check(boss.is_wankel() and boss.se == 20, "D = %d: niet Wankel op 20 SE" % d)
		var attacks_before: int = log["attacks"].size()
		await t.run_ticks(sim, 200)
		t.check(log["attacks"].size() == attacks_before and not boss.is_telling() and not boss.is_attack_active(),
			"D = %d: Wankel en toch %d aanvallen" % [d, log["attacks"].size() - attacks_before])
		var damage_before: int = log["damage"].size()
		var x: int = sim.tick
		await _play(t, sim, p1, A)
		t.check(sim.combat.mark_on(boss.core) != null, "D = %d: de slag op de Wankele boss zette geen merk" % d)
		await t.run_ticks(sim, d + 10)
		var t_f := x + d + 3
		t.check(log["finisher"] == [t_f], "D = %d: FINISHER_START %s (%d = x + D + 3)" % [d, log["finisher"], t_f])
		t.check(log["damage"].size() == damage_before and boss.se == 20, "D = %d: Wankel kreeg SE: %s" % [d, log["damage"].slice(damage_before)])
		# De gedeelde echo: geen lichaam (C-01).
		var shared := boss.shared_echo
		t.check(shared != null and shared.collision_layer == 0 and shared.collision_mask == 0
			and shared.find_children("*", "CollisionShape2D").is_empty(), "D = %d: gedeelde echo %s" % [d, shared])
		# P1 loopt door de plek van de gedeelde echo en springt.
		var x0 := p1.position.x
		await _play(t, sim, p1, R, 30)
		t.check(p1.position.x > x0 + 50.0 and p1.position.x > shared.global_position.x + 16.0,
			"D = %d: P1 liep niet door (%.1f → %.1f, echo op %.1f)" % [d, x0, p1.position.x, shared.global_position.x])
		await _play(t, sim, p1, J, 1)
		await t.run_ticks(sim, 5)
		t.check(p1.position.y < Fx.STAND_Y - 10.0, "D = %d: P1 sprong niet tijdens de finisher" % d)
		await _run_to(t, sim, t_f + 120)
		t.check(not boss.is_defeated() and boss.is_finisher_running(), "D = %d: al verslagen op t_f + 119" % d)
		await t.run_ticks(sim, 1)
		t.check(boss.is_defeated(), "D = %d: niet verslagen op t_f + 120" % d)
		await t.run_ticks(sim, 2)
		t.check(log["defeated"] == [t_f + 120], "D = %d: BOSS_VERSLAGEN %s (t_f + 120 = %d)" % [d, log["defeated"], t_f + 120])
		t.check(not boss.arena_closed and boss.shared_echo == null, "D = %d: arena dicht of gedeelde echo na het einde" % d)
		var expected := _expected_strikes(seen, d, t_f, log["started"][0])
		t.check(expected.size() >= 3, "D = %d: te weinig events om te toetsen (%d)" % [d, expected.size()])
		t.check(_sorted(log["strikes"]) == expected, "D = %d: slagen %s, verwacht %s" % [d, _sorted(log["strikes"]), expected])
		t.check(lp["strike"] == expected.size() and boss.finisher_count == expected.size(),
			"D = %d: %d keer +1 LP voor %d slagen" % [d, lp["strike"], expected.size()])
		t.check(meter.value == LightMeter.MAX, "D = %d: meter %d na BOSS_VERSLAGEN (GM-10: 100)" % [d, meter.value])
		await t.cleanup()


## B-5 / C-14 (aparte run, alle D): Wankel; een merk op een vijand naast de boss knalt: 0 SE op de
## boss, en die ontploffing start de finisher. Tijdens de finisher: een treffer op een vijand zet geen
## merk, en een vijand vlak bij P1 valt niet aan. En: een ontploffing op een niet-Wankele boss doet
## gewone schade en start geen finisher.
func test_c14_testboss_blast_beside_and_not_wankel(t) -> void:
	for d: int in ALL_D:
		var w := _world(t, 92.0, d)
		var sim = w["sim"]
		var p1: PlayerActor = w["p1"]
		p1.health = 1000
		var boss := _testboss(sim)
		var log := _watch(boss)
		var enemy := SliceEnemy.new()
		enemy.setup_enemy(SliceEnemy.Type.KADELOPER, 118.0, Fx.FLOOR_TOP)
		sim.add_object(enemy)
		t.check(enemy.global_position.distance_to(boss.core.global_position)
			<= float(Tuning.combat()["explosion_radius_px"]), "D = %d: Kadeloper niet binnen E van de boss" % d)
		await t.run_ticks(sim, 2)
		boss.set_health(sim.tick, 20)
		var x: int = sim.tick
		await _play(t, sim, p1, A)
		t.check(sim.combat.mark_on(enemy) != null and sim.combat.mark_on(boss.core) == null,
			"D = %d: merk op de vijand en niet op de boss verwacht" % d)
		await t.run_ticks(sim, d + 6)
		t.check(log["finisher"] == [x + d + 3] and boss.se == 20 and log["damage"].is_empty(),
			"D = %d: finisher %s (verwacht %d), %d SE, schade %s" % [d, log["finisher"], x + d + 3, boss.se, log["damage"]])
		# Tijdens de finisher: een nieuwe Kadeloper vlak vóór P1; slaan zet geen merk, hij valt niet aan.
		var other := SliceEnemy.new()
		other.setup_enemy(SliceEnemy.Type.KADELOPER, p1.position.x + 18.0, Fx.FLOOR_TOP)
		sim.add_object(other)
		other.health = 1000
		var windups := []
		other.attack_started.connect(func(tick: int) -> void: windups.append(tick))
		var marks := []
		sim.combat.mark_set.connect(func(tick: int, _m: Combat.Mark) -> void: marks.append(tick))
		var hits := []
		sim.combat.hit.connect(func(tick: int, _a: String, target: Node2D, _dmg: int) -> void:
			if target == other:
				hits.append(tick))
		await _play(t, sim, p1, A)
		await t.run_ticks(sim, 80)
		t.check(boss.is_finisher_running(), "D = %d: finisher al voorbij" % d)
		t.check(not hits.is_empty() and marks.is_empty(), "D = %d: treffers %s, merken %s (geen merk)" % [d, hits, marks])
		t.check(windups.is_empty(), "D = %d: vijand viel aan tijdens de finisher: %s" % [d, windups])
		await t.run_ticks(sim, 50)
		t.check(boss.is_defeated(), "D = %d: niet verslagen" % d)
		await t.cleanup()
	# Niet Wankel: de knal doet 20 SE en start niets.
	var w2 := _world(t, 120.0, 60)
	var sim2 = w2["sim"]
	var boss2 := _testboss(sim2)
	var log2 := _watch(boss2)
	await t.run_ticks(sim2, 2)
	await _play(t, sim2, w2["p1"], A)
	await t.run_ticks(sim2, 70)
	t.check(log2["damage"].size() >= 2 and log2["damage"][1][1] == 20 and log2["damage"][1][2] == "ontploffing"
		and log2["finisher"].is_empty() and boss2.se == 70, "geen gewone schade bij een knal: %s, %d SE" % [log2["damage"], boss2.se])
	await t.cleanup()


## B-5 / C-14, co-op: zelfde met P1 en P2 (merk van P1, P2 knalt het); slagen van P2 tellen mee,
## ook van vóór een drop-out binnen de 600 ticks (daarna knalt de echo).
func test_c14_testboss_coop_and_drop_out(t) -> void:
	for drop_out: bool in [false, true]:
		var w := _world(t, 120.0)
		var sim = w["sim"]
		var p1: PlayerActor = w["p1"]
		p1.health = 1000
		var p2 := Fx.manual_player(sim, 2, Vector2(170, Fx.STAND_Y))
		var boss := _testboss(sim)
		var log := _watch(boss)
		var seen := _watch_attacks(sim, p1, p2)
		await _play(t, sim, p2, L)
		await _run_to(t, sim, 10)
		await _play(t, sim, p2, A)
		await _run_to(t, sim, 20)
		await _play(t, sim, p1, A)
		await _run_to(t, sim, 40)
		await _play(t, sim, p2, A)
		t.check(seen["p2"].size() == 2 and seen["p1"].size() == 1, "%s: events %s" % [drop_out, seen])
		await t.run_ticks(sim, 200)
		var echo: TailEcho = null
		if drop_out:
			echo = sim.drop_out()
			t.check(echo != null, "drop-out gaf geen echo")
			await t.run_ticks(sim, 70)
		boss.set_health(sim.tick, 20)
		var x: int = sim.tick
		await _play(t, sim, p1, A)
		var t_f := x + 60 + 3
		if not drop_out:
			await _run_to(t, sim, x + 30)
			await _play(t, sim, p2, A)
			t_f = x + 30
		await _run_to(t, sim, x + 70)
		t.check(log["finisher"] == [t_f], "%s: finisher %s (verwacht %d)" % [drop_out, log["finisher"], t_f])
		await _run_to(t, sim, t_f + 125)
		t.check(log["defeated"] == [t_f + 120], "%s: verslagen %s" % [drop_out, log["defeated"]])
		var expected := _expected_strikes(seen, 60, t_f, log["started"][0])
		var p2_strikes := expected.filter(func(s: Array) -> bool: return s[1] == "p2")
		t.check(p2_strikes.size() == 2, "%s: slagen van P2 %s (2)" % [drop_out, p2_strikes])
		t.check(_sorted(log["strikes"]) == expected, "%s: slagen %s, verwacht %s" % [drop_out, _sorted(log["strikes"]), expected])
		await t.cleanup()


## B-5 / C-14: na 0 slagen (alleen het merk) is de boss toch verslagen op `t_f + 120`. Het merk en
## de merksprong van de echo vallen hier vóór BOSS_START (de boss start met het debugcommando
## tussen de merksprong en de knal), dus telt geen enkel AANVAL-event.
func test_c14_testboss_zero_strikes(t) -> void:
	# De hurtbox op arena-x 2 (−14 … 18): P1 op −22 raakt hem van buiten de arena.
	var w := _world(t, -22.0, 60)
	var sim = w["sim"]
	var boss := Testboss.new()
	boss.setup_testboss(ORIGIN, 2.0)
	boss.attach(sim)
	var log := _watch(boss)
	await t.run_ticks(sim, 2)
	var x: int = sim.tick
	await _play(t, sim, w["p1"], A)
	t.check(sim.combat.mark_on(boss.core) != null and boss.state == Boss.State.IDLE and boss.se == 100,
		"merk vóór BOSS_START: %s, staat %d, %d SE" % [sim.combat.mark_on(boss.core), boss.state, boss.se])
	await _run_to(t, sim, x + 61)
	boss.start(sim.tick)
	boss.set_health(sim.tick, 20)
	t.check(boss.is_wankel() and log["started"] == [x + 61], "niet Wankel na de start")
	await _run_to(t, sim, x + 63 + 125)
	t.check(log["finisher"] == [x + 63] and log["defeated"] == [x + 63 + 120],
		"finisher %s, einde %s (x = %d)" % [log["finisher"], log["defeated"], x])
	t.check(log["strikes"].is_empty() and boss.finisher_count == 0, "slagen %s (0)" % [log["strikes"]])
	await t.cleanup()


# --- B-5: de C-16-test op de testboss ---------------------------------------

## B-5 / C-16 (1): solo met de echo uit is de testboss in 6000 ticks niet te verslaan (Wankel, geen
## finisher).
func test_c16_testboss_solo_echo_off(t) -> void:
	var sim = Fx.world(t)
	var p1 := _rhythm_player(sim, 1, 120.0, 2)
	p1.health = 1000
	var boss := _testboss(sim)
	var log := _watch(boss)
	await t.run_ticks(sim, 6000)
	t.check(boss.is_wankel() and log["finisher"].is_empty() and log["defeated"].is_empty(),
		"echo uit: Wankel %s, finisher %s, verslagen %s" % [boss.is_wankel(), log["finisher"], log["defeated"]])
	await t.cleanup()


## B-5 / C-16 (2): co-op waarin P2 nooit slaat: in 6000 ticks niet te verslaan.
func test_c16_testboss_coop_p2_never_hits(t) -> void:
	var sim = Fx.world(t)
	var p1 := _rhythm_player(sim, 1, 120.0, 2)
	p1.health = 1000
	Fx.manual_player(sim, 2, Vector2(170, Fx.STAND_Y))
	var boss := _testboss(sim)
	var log := _watch(boss)
	await t.run_ticks(sim, 6000)
	t.check(boss.is_wankel() and log["finisher"].is_empty() and log["defeated"].is_empty(),
		"P2 slaat nooit: Wankel %s, finisher %s" % [boss.is_wankel(), log["finisher"]])
	await t.cleanup()


## B-5 / C-16 (3): solo met de echo (D = 60, 120, 180, 90) en co-op met een P2 die slaat: verslagen.
func test_c16_testboss_with_echo_or_partner_wins(t) -> void:
	for run: Array in [["solo", 60], ["solo", 120], ["solo", 180], ["solo", 90], ["coop", 60]]:
		var sim = Fx.world(t)
		var p1 := _rhythm_player(sim, 1, 120.0, 2)
		p1.health = 1000
		if run[0] == "solo":
			Fx.tail_echo(sim, p1, run[1])
		else:
			var p2 := _rhythm_player(sim, 2, 168.0, 12)
			p2.motor.facing = -1
		var boss := _testboss(sim)
		await _run_until(t, sim, func() -> bool: return boss.is_defeated(), 6000, 50)
		t.check(boss.is_defeated(), "%s D = %d: niet verslagen in 6000 ticks (%d SE)" % [run[0], run[1], boss.se])
		await t.cleanup()


# --- B-5: de C-14-test op de Gemaalmeester, arena en respawn ---------------

## B-5 / C-14 (alle D) op de Gemaalmeester: op 300 SE gezet (debug) is hij Wankel: geen aanval; de
## merkplek op de ketel (300, 36) neemt een merk en 0 SE; de echo knalt op `x + D + 3` = `t_f`;
## verslagen op `t_f + 120`, de arena open en de meter op 100 LP (GM-10).
func test_c14_gemaalmeester_wankel_finisher(t) -> void:
	for d: int in ALL_D:
		var w := _world(t, KETEL_P1_X, d)
		var sim = w["sim"]
		var p1: PlayerActor = w["p1"]
		var boss := _gemaalmeester(sim)
		var log := _watch(boss)
		var seen := _watch_attacks(sim, p1)
		var meter := LightMeter.new(sim, p1)
		meter.watch_boss(boss)
		await t.run_ticks(sim, 3)
		boss.set_health(sim.tick, EnemyData.ticks("gemaalmeester", "wankel_se"))
		t.check(boss.is_wankel() and log["phase"].back()[1] == "wankel", "D = %d: niet Wankel: %s" % [d, log["phase"]])
		var attacks: int = log["attacks"].size()
		await t.run_ticks(sim, 200)
		t.check(log["attacks"].size() == attacks, "D = %d: aanvallen in Wankel" % d)
		var x: int = sim.tick
		await _play(t, sim, p1, A)
		var mark: Combat.Mark = sim.combat.mark_on(boss.ketel)
		t.check(mark != null and mark.center() == boss.arena_point(300, 36) and log["damage"].is_empty(),
			"D = %d: merkplek: merk %s, schade %s" % [d, mark.center() if mark else null, log["damage"]])
		await _play(t, sim, p1, L, 30)
		await _run_to(t, sim, x + d + 3 + 121)
		t.check(log["finisher"] == [x + d + 3] and log["defeated"] == [x + d + 3 + 120],
			"D = %d: finisher %s, verslagen %s (x = %d)" % [d, log["finisher"], log["defeated"], x])
		t.check(_sorted(log["strikes"]) == _expected_strikes(seen, d, x + d + 3, log["started"][0]),
			"D = %d: slagen %s" % [d, log["strikes"]])
		t.check(not boss.arena_closed and meter.value == LightMeter.MAX, "D = %d: arena %s, meter %d" % [d, boss.arena_closed, meter.value])
		await t.cleanup()


## B-5 / GM-01 en GM-11: BOSS_START als P1 de arena in komt, de deur dicht; bij 0 levenspunten
## respawnt P1 (buiten de arena) en begint de boss opnieuw: 1500 SE, fase 1, adds weg, arena open.
## Komt P1 weer binnen, dan opnieuw BOSS_START.
func test_b5_arena_and_reset_on_respawn(t) -> void:
	var w := _world(t, -40.0)
	var sim = w["sim"]
	var p1: PlayerActor = w["p1"]
	var boss := _gemaalmeester(sim)
	var log := _watch(boss)
	var door := Fx.block(t, "Deur", Rect2(-8, Fx.FLOOR_TOP - 60, 8, 60), Layers.WORLD)
	boss.add_door(door, Layers.WORLD)
	var respawn := Respawn.new(p1, func() -> Vector2: return Vector2(-40, Fx.STAND_Y))
	t.check(door.collision_layer == 0 and not boss.arena_closed, "deur dicht vóór BOSS_START")
	await t.run_ticks(sim, 10)
	t.check(log["started"].is_empty(), "BOSS_START met P1 buiten de arena")
	await _play(t, sim, p1, R, 60)
	t.check(log["started"].size() == 1 and door.collision_layer == Layers.WORLD and boss.arena_closed,
		"BOSS_START %s, deur %d" % [log["started"], door.collision_layer])
	var start: int = log["started"][0]
	# Een opening tot de drempel (debug), adds uit de spuigaten, en P1 op 1 levenspunt.
	boss.ketel.break_armor(sim.tick)
	boss.set_health(sim.tick, 1350)
	await t.run_ticks(sim, 35)
	t.check(boss.opening_index == 1 and boss.adds.size() == 2, "opening %d, adds %d" % [boss.opening_index, boss.adds.size()])
	var adds: Array = boss.adds.duplicate()
	p1.health = 1
	await _run_until(t, sim, func() -> bool: return not log["reset"].is_empty(), 400, 1)
	t.check(log["reset"].size() == 1 and p1.died, "geen reset op de respawntick: %s" % [log["reset"]])
	await t.run_ticks(sim, 2)
	t.check(boss.se == 1500 and boss.phase == Gemaalmeester.Phase.ONE and boss.opening_index == 0
		and boss.state == Boss.State.IDLE and not boss.arena_closed and door.collision_layer == 0,
		"na reset: %d SE, fase %d, opening %d, staat %d, deur %d" % [boss.se, boss.phase, boss.opening_index,
			boss.state, door.collision_layer])
	t.check(boss.adds.is_empty() and adds.all(func(a) -> bool: return not is_instance_valid(a) or not a.alive),
		"adds niet weg na de reset")
	t.check(boss.ketel.armor_intact and boss.ketel.is_markable(), "schot niet heel na de reset")
	await _play(t, sim, p1, R, 40)
	t.check(log["started"].size() == 2 and log["started"][1] > start and boss.arena_closed, "geen nieuwe BOSS_START: %s" % [log["started"]])
	t.check(respawn != null, "respawn")
	await t.cleanup()


# --- B-6: maat en aanvallen --------------------------------------------------

## B-6 / GM-04: fase 1 één pompslag per maat van 120 ticks (de eerste met 60 ticks aanloop, daarna
## 40), op de helft van P1; fasewissel 60 ticks zonder aanval; fase 2 om de 90 ticks om en om
## pompslag (aanloop 30) en schoepenzwiep (aanloop 30). Elke aanloop ≥ 30, actief 6 / 6 / 8.
func test_b6_measure_and_windups(t) -> void:
	var w := _world(t, 200.0)
	var sim = w["sim"]
	w["p1"].health = 1000
	var boss := _gemaalmeester(sim)
	var log := _watch(boss)
	# Per actief vlak: [eerste tick, lengte, soort].
	var actives: Array = []
	sim.tick_finished.connect(func(tick: int) -> void:
		if not boss.is_attack_active():
			return
		if actives.is_empty() or actives.back()[0] + actives.back()[1] != tick:
			actives.append([tick, 0, boss.attack_kind])
		actives.back()[1] += 1)
	await t.run_ticks(sim, 400)
	var starts: Array = log["attacks"].map(func(a: Array) -> int: return a[0])
	t.check(starts == [0, 120, 240, 360], "fase 1 aanvallen op %s (0, 120, 240, 360)" % [starts])
	t.check(log["attacks"].all(func(a: Array) -> bool: return a[1] == "pomp" and a[2] == -1),
		"fase 1: %s (pompslag links)" % [log["attacks"]])
	await _run_to(t, sim, 500)
	boss.set_health(sim.tick, 900)
	var switch_at: int = sim.tick
	t.check(boss.phase == Gemaalmeester.Phase.SWITCH, "geen fasewissel op 900 SE")
	var n_before: int = log["attacks"].size()
	await t.run_ticks(sim, 60 + 90 * 4 + 40)
	var phase2: Array = log["attacks"].slice(n_before)
	var p2_starts: Array = phase2.map(func(a: Array) -> int: return a[0] - switch_at)
	t.check(p2_starts == [60, 150, 240, 330, 420], "fase 2 aanvallen op wissel + %s" % [p2_starts])
	t.check(phase2.map(func(a: Array) -> String: return a[1]) == ["pomp", "zwiep", "pomp", "zwiep", "pomp"],
		"fase 2 niet om en om: %s" % [phase2])
	# Aanloop = eerste actieve tick − begin van de aanloop, voor elke aanval die niet afbrak.
	var windups: Array = []
	for a: Array in log["attacks"]:
		var first: Array = actives.filter(func(v: Array) -> bool: return v[0] > a[0])
		if not first.is_empty() and (first[0][0] - a[0]) <= 60:
			windups.append([a[1], first[0][0] - a[0], first[0][1]])
	t.check(windups.size() >= 8 and windups.all(func(r: Array) -> bool: return r[1] >= 30), "aanlopen %s" % [windups])
	t.check(windups.map(func(r: Array) -> int: return r[1]).slice(0, 4) == [60, 40, 40, 40], "fase 1 aanlopen %s" % [windups])
	t.check(windups.slice(4).all(func(r: Array) -> bool: return r[1] == 30), "fase 2 aanlopen %s" % [windups.slice(4)])
	t.check(windups.all(func(r: Array) -> bool: return r[2] == (8 if r[0] == "zwiep" else 6)), "actief %s (6 / 6 / 8)" % [windups])
	await t.cleanup()


## B-6 / §3.4, §3.5: de vlakken. Fase 1 links x 140–300 of rechts 300–460, 24 hoog; fase 2 de
## pompslag 160 breed gecentreerd op P1 (geklemd op 0–600), de zwiep 300 breed op y 36–60.
func test_b6_attack_boxes(t) -> void:
	for x: float in [200.0, 400.0, 30.0, 590.0]:
		var w := _world(t, x)
		var sim = w["sim"]
		w["p1"].health = 1000
		var boss := _gemaalmeester(sim)
		var log := _watch(boss)
		await t.run_ticks(sim, 1)
		# B-11: de tell (stofstrook) staat in beeld zolang de aanloop loopt, op het vlak.
		var tell := boss.get_node("Tell") as Polygon2D
		t.check(boss.is_telling() and tell.visible and tell.polygon[0] + boss.global_position == boss.attack_box.position,
			"x = %s: geen tell op het vlak" % x)
		var box := boss.attack_box
		var left := x < 300.0
		var want := boss.arena_rect(140.0, 300.0, 0.0, 24.0) if left else boss.arena_rect(300.0, 460.0, 0.0, 24.0)
		t.check(box == want and log["attacks"][0][2] == (-1 if left else 1), "x = %s: fase 1 vlak %s (%s)" % [x, box, want])
		boss.set_health(sim.tick, 900)
		await t.run_ticks(sim, 61)
		var x1 := clampf(x - 80.0, 0.0, 440.0)
		t.check(boss.attack_kind == "pomp" and boss.attack_box == boss.arena_rect(x1, x1 + 160.0, 0.0, 24.0),
			"x = %s: fase 2 pompslag %s" % [x, boss.attack_box])
		await t.run_ticks(sim, 90)
		var z := boss.arena_rect(0.0, 300.0, 36.0, 60.0) if left else boss.arena_rect(300.0, 600.0, 36.0, 60.0)
		t.check(boss.attack_kind == "zwiep" and boss.attack_box == z, "x = %s: zwiep %s (%s)" % [x, boss.attack_box, z])
		await t.cleanup()


## Hoogte van de onderkant van P1 boven de vloer.
func _feet(p1: PlayerActor) -> float:
	return Fx.FLOOR_TOP - (p1.position.y + Tuning.body_size().y * 0.5)


## Uitkomst van de aanval die als `nth` (0, 1, …) van soort `kind` eindigde: raakte hij P1?
func _hit_of(log: Dictionary, kind: String, nth := 0) -> Variant:
	var of_kind: Array = log["ended"].filter(func(e: Array) -> bool: return e[1] == kind)
	return of_kind[nth][3] if of_kind.size() > nth else null


## B-6: de pompslag raakt P1 op de vloer in het vlak (1 levenspunt), niet P1 in de lucht en niet op
## de plank van de echo (30 px; het vlak reikt tot 24).
func test_b6_pomp_hits_floor_not_air_or_plank(t) -> void:
	# Op de vloer.
	var w := _world(t, 200.0)
	var boss := _gemaalmeester(w["sim"])
	var log := _watch(boss)
	await t.run_ticks(w["sim"], 95)
	t.check(_hit_of(log, "pomp") == true and w["p1"].health == 4, "op de vloer niet geraakt (%d LP)" % w["p1"].health)
	await t.cleanup()
	# In de lucht: springen 10 ticks vóór het actieve vlak (aanloop 60).
	var w2 := _world(t, 200.0)
	var sim2 = w2["sim"]
	var boss2 := _gemaalmeester(sim2)
	var log2 := _watch(boss2)
	var feet := []
	sim2.tick_finished.connect(func(_tick: int) -> void:
		if boss2.is_attack_active():
			feet.append(_feet(w2["p1"])))
	await _run_to(t, sim2, 50)
	await _play(t, sim2, w2["p1"], J, 1)
	await t.run_ticks(sim2, 45)
	t.check(feet.size() == 6 and feet.all(func(f: float) -> bool: return f > 24.0), "voeten tijdens het vlak %s" % [feet])
	t.check(_hit_of(log2, "pomp") == false and w2["p1"].health == 5, "in de lucht geraakt")
	await t.cleanup()
	# Op de plank van de echo.
	var sim3 = Fx.world(t)
	var ghost := Fx.ghost(t)
	Fx.ghost_path(ghost, -1, 500, func(_k: int) -> Vector2: return Vector2(200, Fx.STAND_Y))
	Fx.tail_echo(sim3, ghost, 1)
	var p3 := Fx.manual_player(sim3, 1, Vector2(200, Fx.ON_ECHO_Y - 2))
	var boss3 := _gemaalmeester(sim3)
	var log3 := _watch(boss3)
	await t.run_ticks(sim3, 95)
	t.check(p3.motor.on_floor and absf(p3.position.y - Fx.ON_ECHO_Y) < 0.6, "P1 staat niet op de echo: %s" % p3.position)
	t.check(_hit_of(log3, "pomp") == false and p3.health == 5, "op de plank geraakt")
	await t.cleanup()


## B-6: de schoepenzwiep raakt P1 op de plank van de echo en op de top van een sprong, niet op de
## vloer en niet boven 60 px.
func test_b6_zwiep_hits_plank_and_jump_top_only(t) -> void:
	for case: String in ["vloer", "plank", "sprong", "hoog"]:
		var sim = Fx.world(t)
		var p1: PlayerActor
		if case == "plank":
			var ghost := Fx.ghost(t)
			Fx.ghost_path(ghost, -1, 590, func(_k: int) -> Vector2: return Vector2(100, Fx.STAND_Y))
			Fx.tail_echo(sim, ghost, 1)
			p1 = Fx.manual_player(sim, 1, Vector2(100, Fx.ON_ECHO_Y - 2))
		elif case == "hoog":
			Fx.block(t, "Hoog", Rect2(80, Fx.FLOOR_TOP - 70, 40, 6), Layers.WORLD)
			p1 = Fx.manual_player(sim, 1, Vector2(100, Fx.FLOOR_TOP - 70 - 16))
		else:
			p1 = Fx.manual_player(sim, 1, Vector2(100, Fx.STAND_Y))
		if case != "plank":
			sim.set_tail_ticks(60)
		p1.health = 1000
		var boss := _gemaalmeester(sim)
		var log := _watch(boss)
		var feet := []
		sim.tick_finished.connect(func(_tick: int) -> void:
			if boss.is_attack_active() and boss.attack_kind == "zwiep":
				feet.append(_feet(p1)))
		await t.run_ticks(sim, 2)
		boss.set_health(sim.tick, 900)
		var k: int = sim.tick
		# Zwiep: maat 2 van fase 2, aanloop vanaf k + 150, actief vanaf k + 180.
		if case == "sprong":
			await _run_to(t, sim, k + 160)
			await _play(t, sim, p1, J, 1)
		await _run_to(t, sim, k + 215)
		var hit: Variant = _hit_of(log, "zwiep")
		var want := case == "plank" or case == "sprong"
		t.check(hit == want, "%s: zwiep raakte %s (verwacht %s), voeten %s" % [case, hit, want, feet])
		match case:
			"vloer":
				t.check(feet.all(func(f: float) -> bool: return absf(f) < 0.6), "vloer: voeten %s" % [feet])
			"plank":
				t.check(feet.all(func(f: float) -> bool: return absf(f - 30.0) < 0.6), "plank: voeten %s" % [feet])
			"sprong":
				t.check(feet.size() == 8 and feet.all(func(f: float) -> bool: return f > 30.0 and f < 60.0),
					"sprong: voeten %s (tussen 30 en 60)" % [feet])
			"hoog":
				t.check(feet.all(func(f: float) -> bool: return f >= 60.0), "hoog: voeten %s" % [feet])
		await t.cleanup()


## B-6 / E-14h, C-02: de aanvallen raken de echo en P2 nooit, ook als ze midden in het vlak staan
## (fase 1: de pompslag op de helft van P1, die er zelf naast staat).
func test_b6_never_hits_echo_or_p2(t) -> void:
	for coop: bool in [false, true]:
		var sim = Fx.world(t)
		var p1 := Fx.manual_player(sim, 1, Vector2(560, Fx.STAND_Y))
		var other: Node2D
		if coop:
			other = Fx.manual_player(sim, 2, Vector2(400, Fx.STAND_Y))
		else:
			sim.set_tail_ticks(60)
			var ghost := Fx.ghost(t)
			Fx.ghost_path(ghost, -1, 590, func(_k: int) -> Vector2: return Vector2(400, Fx.STAND_Y))
			other = Fx.tail_echo(sim, ghost, 1)
		var boss := _gemaalmeester(sim)
		var log := _watch(boss)
		var hits := []
		boss.hit_player.connect(func(tick: int, who: Node2D) -> void: hits.append([tick, who]))
		var inside := {"n": 0}
		sim.tick_finished.connect(func(_tick: int) -> void:
			if boss.is_attack_active() and boss.attack_box.intersects(Rect2(other.global_position
					- Tuning.body_size() * 0.5, Tuning.body_size())):
				inside["n"] += 1)
		await t.run_ticks(sim, 250)
		t.check(inside["n"] >= 12, "coop %s: het tweede lichaam stond %d actieve ticks in een vlak" % [coop, inside["n"]])
		t.check(hits.is_empty() and p1.health == 5, "coop %s: treffers %s" % [coop, hits])
		if coop:
			t.check((other as PlayerActor).health == 5, "P2 verloor leven")
		t.check(log["attacks"].size() >= 3, "coop %s: %d aanvallen" % [coop, log["attacks"].size()])
		await t.cleanup()


# --- B-7: fase 1 ---------------------------------------------------------------

## B-7 (alle D): solo-script "sla het schot één keer en loop weg": de slag doet 0 SE en geeft een
## tink, zet een merk op (300, 36); de echo breekt het schot op `slag + D + 3`.
func test_b7_strike_once_and_walk_away(t) -> void:
	for d: int in ALL_D:
		var w := _world(t, KETEL_P1_X, d)
		var sim = w["sim"]
		var boss := _gemaalmeester(sim)
		var log := _watch(boss)
		var broke := []
		boss.shot_broken.connect(func(tick: int) -> void: broke.append(tick))
		var tinks := []
		boss.ketel.armor_tinked.connect(func(tick: int) -> void: tinks.append(tick))
		await t.run_ticks(sim, 5)
		var x: int = sim.tick
		await _play(t, sim, w["p1"], A)
		var mark: Combat.Mark = sim.combat.mark_on(boss.ketel)
		t.check(mark != null and mark.center() == Vector2(300, Fx.FLOOR_TOP - 36), "D = %d: merk %s" % [d, mark.center() if mark else null])
		t.check(tinks == [x] and boss.ketel.tink_tick == x, "D = %d: tink %s" % [d, tinks])
		await _play(t, sim, w["p1"], L, 40)
		await _run_to(t, sim, x + d + 10)
		t.check(broke == [x + d + 3], "D = %d: schot brak op %s (verwacht %d)" % [d, broke, x + d + 3])
		t.check(log["damage"].is_empty() and boss.se == 1500 and boss.core_open, "D = %d: schade %s" % [d, log["damage"]])
		t.check(boss.shake_at(x + d + 3) == 2.0 and boss.shake_at(x + d + 9) == 0.0, "D = %d: schermschok" % d)
		await t.cleanup()


## B-7: een gewone treffer op het intacte schot doet 0 (ook een tweede slag op je eigen merk), en
## zonder echo breekt het schot in 6000 ticks nooit (C-16 (1) op de Gemaalmeester).
func test_b7_echo_off_never_breaks(t) -> void:
	var sim = Fx.world(t)
	sim.set_tail_ticks(60)
	var p1 := _rhythm_player(sim, 1, KETEL_P1_X, 2)
	p1.health = 1000
	var boss := _gemaalmeester(sim)
	var log := _watch(boss)
	var broke := []
	boss.shot_broken.connect(func(tick: int) -> void: broke.append(tick))
	var tinks := []
	boss.ketel.armor_tinked.connect(func(tick: int) -> void: tinks.append(tick))
	await t.run_ticks(sim, 6000)
	t.check(broke.is_empty() and boss.se == 1500 and log["damage"].is_empty(), "echo uit: breuk %s, %d SE" % [broke, boss.se])
	t.check(tinks.size() >= 290, "%d tinks (elke slag)" % tinks.size())
	await t.cleanup()


## B-7 / C-16 (2) op de Gemaalmeester: co-op waarin P2 nooit slaat: het schot breekt nooit.
func test_b7_coop_p2_never_hits_never_breaks(t) -> void:
	var sim = Fx.world(t)
	var p1 := _rhythm_player(sim, 1, KETEL_P1_X, 2)
	p1.health = 1000
	Fx.manual_player(sim, 2, Vector2(340, Fx.STAND_Y))
	var boss := _gemaalmeester(sim)
	var broke := []
	boss.shot_broken.connect(func(tick: int) -> void: broke.append(tick))
	await t.run_ticks(sim, 6000)
	t.check(broke.is_empty() and boss.se == 1500, "P2 slaat nooit: breuk %s" % [broke])
	await t.cleanup()


## B-7 / C-12e: in co-op leeft een merk 150 ticks, los van D: P2 slaat het merk van P1 op `+140` en
## breekt het schot; op `+150` is het gedoofd en breekt een slag van P2 niets.
func test_b7_coop_mark_lives_150(t) -> void:
	for d: int in [60, 180]:
		for late: int in [140, 150]:
			var w := _world(t, KETEL_P1_X)
			var sim = w["sim"]
			sim.set_tail_ticks(d)
			var p2 := Fx.manual_player(sim, 2, Vector2(342, Fx.STAND_Y))
			var boss := _gemaalmeester(sim)
			var broke := []
			boss.shot_broken.connect(func(tick: int) -> void: broke.append(tick))
			await _play(t, sim, p2, L)
			await t.run_ticks(sim, 3)
			var x: int = sim.tick
			await _play(t, sim, w["p1"], A)
			var mark: Combat.Mark = sim.combat.mark_on(boss.ketel)
			t.check(mark != null and mark.expires - mark.born == 150, "D = %d: merk leeft %s" % [d, mark.expires - mark.born if mark else null])
			await _run_to(t, sim, x + late)
			await _play(t, sim, p2, A)
			var want := [x + late] if late < 150 else []
			t.check(broke == want, "D = %d, P2 op +%d: breuk %s (verwacht %s)" % [d, late, broke, want])
			await t.cleanup()


## B-7 / §3.4, GMB-11: de kern neemt 10 (P1), 5 (echo) en 20 (knal); de boss klemt op de drempel van
## de opening, en dan sluit het schot ("drempel").
func test_b7_core_damage_and_clamp(t) -> void:
	var w := _world(t, KETEL_P1_X, 60)
	var sim = w["sim"]
	var boss := _gemaalmeester(sim)
	var log := _watch(boss)
	var closed := []
	boss.core_closed.connect(func(tick: int, reason: String) -> void: closed.append([tick, reason]))
	await t.run_ticks(sim, 3)
	boss.ketel.break_armor(sim.tick)
	t.check(boss.core_open and not boss.ketel.armor_intact and boss.ketel.is_markable(), "kern niet open en `Merkbaar`")
	await _play(t, sim, w["p1"], A)
	await t.run_ticks(sim, 19)
	await _play(t, sim, w["p1"], A)
	await t.run_ticks(sim, 90)
	var got: Array = log["damage"].map(func(e: Array) -> Array: return [e[1], e[2]])
	t.check(got == [[10, "p1"], [10, "p1"], [20, "ontploffing"], [5, "echo"]], "kern-schade %s" % [got])
	t.check(boss.se == 1455 and closed.is_empty(), "%d SE, dicht %s" % [boss.se, closed])
	# Klem: op 1355 doet de slag van 10 er nog 5, dan sluit het schot op de drempel.
	boss.set_health(sim.tick, 1355)
	await _play(t, sim, w["p1"], A)
	t.check(boss.se == 1350 and boss.opening_index == 1, "%d SE, opening %d (klem op 1350)" % [boss.se, boss.opening_index])
	t.check(closed.size() == 1 and closed[0][1] == "drempel" and boss.ketel.armor_intact and not boss.core_open,
		"dicht %s" % [closed])
	t.check(log["damage"].slice(4).map(func(e: Array) -> int: return e[1]) == [5], "na de klem: %s" % [log["damage"].slice(4)])
	await t.cleanup()


## B-7 / GMB-11, §3.4: zonder schade sluit de kern na 300 ticks ("tijd"); dan gloeien de spuigaten
## 30 ticks en komt er uit elk één Kadeloper, die 30 ticks niets doet; nooit meer dan 2 tegelijk;
## vóór opening 1 geen adds.
func test_b7_core_timeout_and_adds(t) -> void:
	var w := _world(t, 30.0)
	var sim = w["sim"]
	var p1: PlayerActor = w["p1"]
	p1.health = 1000
	var boss := _gemaalmeester(sim)
	var closed := []
	boss.core_closed.connect(func(tick: int, reason: String) -> void: closed.append([tick, reason]))
	var spawned := []
	boss.add_spawned.connect(func(tick: int, add: Node2D) -> void: spawned.append([tick, add]))
	var glow := []
	sim.tick_finished.connect(func(tick: int) -> void:
		if boss.spout_glowing:
			glow.append(tick)
		if boss.get_node("Spuigat_links").visible != boss.spout_glowing:
			glow.append(-1))
	await t.run_ticks(sim, 200)
	t.check(spawned.is_empty(), "adds vóór opening 1")
	var b: int = sim.tick
	boss.ketel.break_armor(b)
	await _run_to(t, sim, b + 300)
	t.check(boss.core_open, "kern al dicht vóór 300 ticks")
	await t.run_ticks(sim, 1)
	t.check(closed == [[b + 300, "tijd"]] and boss.ketel.armor_intact, "dicht %s (verwacht %d, tijd)" % [closed, b + 300])
	var c := b + 300
	await _run_to(t, sim, c + 30)
	var want_glow: Array = range(c, c + 30)
	t.check(glow == want_glow, "gloeien %s … (%d ticks, verwacht %d–%d)" % [glow.slice(0, 3), glow.size(), c, c + 29])
	t.check(spawned.size() == 2, "adds %s" % [spawned])
	var a: SliceEnemy = spawned[0][1]
	var bb: SliceEnemy = spawned[1][1]
	t.check(a.position.x == 236.0 and bb.position.x == 364.0 and a.enemy_type == SliceEnemy.Type.KADELOPER
		and is_equal_approx(a.position.y, Fx.FLOOR_TOP - 12.0), "adds op %s en %s" % [a.position, bb.position])
	var at := [a.position, bb.position]
	var windups := []
	a.attack_started.connect(func(tick: int) -> void: windups.append(tick))
	await _run_to(t, sim, c + 60)
	t.check(a.position == at[0] and bb.position == at[1] and windups.is_empty(), "adds deden iets in hun eerste 30 ticks")
	await t.run_ticks(sim, 10)
	t.check(a.position.x < at[0].x and bb.position.x < at[1].x, "adds lopen niet na 30 ticks")
	# Max. 2: weer een opening die uitloopt, met 2 levende adds: geen nieuwe.
	boss.ketel.break_armor(sim.tick)
	await t.run_ticks(sim, 340)
	t.check(spawned.size() == 2 and boss.adds.size() == 2, "%d adds (max. 2)" % spawned.size())
	# Eén dood: bij de volgende sluiting komt er één bij (uit het linker spuigat).
	a.apply_damage(sim.tick, 1000, "p1")
	boss.ketel.break_armor(sim.tick)
	await t.run_ticks(sim, 340)
	t.check(spawned.size() == 3 and (spawned[2][1] as SliceEnemy).start_position.x == 236.0 and boss.adds.size() == 2,
		"na een dode add: %d adds" % spawned.size())
	t.check(not is_instance_valid(a) or not boss.adds.has(a), "dode add niet opgeruimd")
	await t.cleanup()


## B-7 / GMB-12: op de laatste drempel de fasewissel: 60 ticks geen aanval, merken op de boss doven,
## adds lossen op, het schot sluit voorgoed (niet raakbaar, niet `Merkbaar`), het rad gaat naar de
## kant waar P1 niet is.
func test_b7_phase_switch(t) -> void:
	for x: float in [200.0, 420.0]:
		var w := _world(t, x)
		var sim = w["sim"]
		w["p1"].health = 1000
		var boss := _gemaalmeester(sim)
		var log := _watch(boss)
		var faded := []
		sim.combat.mark_faded.connect(func(tick: int, mark: Combat.Mark) -> void:
			if mark.target == boss.ketel:
				faded.append(tick))
		await t.run_ticks(sim, 3)
		# Een merk op het schot (zonder echo knalt niemand het).
		var ketel_x := 300.0 - 28.0 if x < 300.0 else 300.0 + 28.0
		w["p1"].position.x = ketel_x
		if x > 300.0:
			await _play(t, sim, w["p1"], L)
		await _play(t, sim, w["p1"], A)
		t.check(sim.combat.mark_on(boss.ketel) != null, "x = %s: geen merk op het schot" % x)
		boss.ketel.break_armor(sim.tick)
		boss.set_health(sim.tick, 1350)
		await t.run_ticks(sim, 35)
		var adds: Array = boss.adds.duplicate()
		t.check(adds.size() == 2, "x = %s: %d adds" % [x, adds.size()])
		var s: int = sim.tick
		boss.set_health(s, 900)
		t.check(boss.phase == Gemaalmeester.Phase.SWITCH and faded == [s] and sim.combat.mark_on(boss.ketel) == null,
			"x = %s: fasewissel, gedoofd %s" % [x, faded])
		t.check(boss.rad_side == (1 if x < 300.0 else -1), "x = %s: rad naar %d" % [x, boss.rad_side])
		var n: int = log["attacks"].size()
		await t.run_ticks(sim, 2)
		t.check(adds.all(func(a) -> bool: return not is_instance_valid(a) or not a.alive), "x = %s: adds niet opgelost" % x)
		await _run_to(t, sim, s + 60)
		t.check(log["attacks"].size() == n, "x = %s: aanval in de fasewissel" % x)
		await t.run_ticks(sim, 1)
		t.check(boss.phase == Gemaalmeester.Phase.TWO and log["attacks"].size() == n + 1 and log["attacks"][n][0] == s + 60,
			"x = %s: fase 2 begint niet op s + 60" % x)
		# Fase 2: het schot is niet raakbaar en niet `Merkbaar`.
		var hits := []
		sim.combat.hit.connect(func(tick: int, _a: String, target: Node2D, _dmg: int) -> void:
			if target == boss.ketel:
				hits.append(tick))
		await _play(t, sim, w["p1"], A)
		t.check(hits.is_empty() and sim.combat.mark_on(boss.ketel) == null and not boss.ketel.is_markable(),
			"x = %s: schot in fase 2 geraakt %s" % [x, hits])
		await t.cleanup()


## B-7 / GMB-11 (D = 60 en 180): een run die elke opening tot de drempel slaat (P1 slaat om de 20
## ticks bij de kern, de echo herhaalt): precies 4 openingen, 3 keer "drempel", dan de fasewissel;
## de SE staat na elke opening precies op zijn drempel; adds pas na opening 1.
func test_b7_four_openings(t) -> void:
	for d: int in [60, 180]:
		var sim = Fx.world(t)
		var p1 := _rhythm_player(sim, 1, KETEL_P1_X, 2)
		p1.health = 1000
		Fx.tail_echo(sim, p1, d)
		var boss := _gemaalmeester(sim)
		var log := _watch(boss)
		var broke := []
		boss.shot_broken.connect(func(tick: int) -> void: broke.append(tick))
		var closed := []
		boss.core_closed.connect(func(tick: int, reason: String) -> void: closed.append([tick, reason, boss.se]))
		var spawned := []
		boss.add_spawned.connect(func(tick: int, _add: Node2D) -> void: spawned.append(tick))
		await _run_until(t, sim, func() -> bool: return boss.phase != Gemaalmeester.Phase.ONE, 3000, 50)
		t.check(boss.phase == Gemaalmeester.Phase.SWITCH or boss.phase == Gemaalmeester.Phase.TWO,
			"D = %d: geen fasewissel in 3000 ticks (%d SE, %d openingen)" % [d, boss.se, broke.size()])
		t.check(broke.size() == 4, "D = %d: %d openingen (4): %s" % [d, broke.size(), broke])
		t.check(closed.map(func(c: Array) -> Array: return [c[1], c[2]]) == [["drempel", 1350], ["drempel", 1200], ["drempel", 1050]],
			"D = %d: sluitingen %s" % [d, closed])
		t.check(boss.se == 900, "D = %d: %d SE bij de fasewissel (900)" % [d, boss.se])
		t.check(not spawned.is_empty() and spawned[0] > broke[0], "D = %d: adds %s vóór opening 1 (%s)" % [d, spawned, broke])
		t.note("D = %d: openingen op %s, fasewissel op %s" % [d, broke, log["phase"]])
		await t.cleanup()
