extends RefCounted
## Tests voor de vijanden van de slice (T8b-bouw deel 1, #190): B-1 gedeelde regels, B-2
## Kadeloper, B-3 Schotdrager, B-4 Dwaallicht en B-11 (`slice.csv` en de vlaggen van het
## placeholder-beeld), en B-12 uit deel 2b (VJ-08 hoogtegrens van de aanloop, VJ-02 onkwetsbaar na een
## respawn). Bron: `docs/design/combat/slice-vijanden-en-boss.md` v0.1.2 §2, §6, §7.
##
## Gevallen "(alle D)" draaien op D = 60, 120 en 180, met 90 als regressie (zoals test_combat).
## Alle getallen komen uit `slice.csv` en `echo_v04.json`; de vaste verwachtingen hieronder zijn
## de waarden uit §7 van het ontwerp, zodat een typefout in data hier rood wordt.

const Fx = preload("res://tests/echo_fixture.gd")
const InputBits = preload("res://scripts/input/input_bits.gd")
const PlayerActor = preload("res://scripts/echo/player_actor.gd")
const TailEcho = preload("res://scripts/echo/tail_echo.gd")
const Combat = preload("res://scripts/combat/combat.gd")
const CombatTarget = preload("res://scripts/combat/combat_target.gd")
const SliceEnemy = preload("res://scripts/combat/slice_enemy.gd")
const EnemyData = preload("res://scripts/combat/enemy_data.gd")
const LightMeter = preload("res://scripts/light/light_meter.gd")
const Layers = preload("res://scripts/world/layers.gd")
const Tuning = preload("res://scripts/echo/tuning.gd")
const Respawn = preload("res://scripts/save/respawn.gd")

const L := InputBits.LEFT
const R := InputBits.RIGHT
const J := InputBits.JUMP
const A := InputBits.ATTACK
const DOWN := InputBits.DOWN
const ALL_D := [60, 120, 180, 90]
const KADELOPER := SliceEnemy.Type.KADELOPER
const SCHOTDRAGER := SliceEnemy.Type.SCHOTDRAGER
const DWAALLICHT := SliceEnemy.Type.DWAALLICHT
const EPS := 0.0001


# --- hulpmiddelen ----------------------------------------------------------

func _enemy(sim: Node, type: int, x: float) -> SliceEnemy:
	var enemy := SliceEnemy.new()
	enemy.setup_enemy(type, x, Fx.FLOOR_TOP)
	sim.add_object(enemy)
	return enemy


func _dwaallicht(sim: Node, from_x: float, to_x: float, floor_y := Fx.FLOOR_TOP) -> SliceEnemy:
	var enemy := SliceEnemy.new()
	enemy.setup_enemy(DWAALLICHT, from_x, floor_y, from_x, to_x)
	sim.add_object(enemy)
	return enemy


## Wereld met P1 (handmatige input) op `x`, en optioneel zijn staart-echo met D = `d`.
func _world(t, x: float, d := -1) -> Dictionary:
	var sim = Fx.world(t)
	var p1 := Fx.manual_player(sim, 1, Vector2(x, Fx.STAND_Y))
	var echo: TailEcho = null
	if d > 0:
		echo = Fx.tail_echo(sim, p1, d)
	else:
		sim.set_tail_ticks(int(Tuning.echo()["tail_ticks"]))
	var log := {"set": [], "exploded": [], "damage": [], "hits": []}
	sim.combat.mark_set.connect(func(tick: int, mark: Combat.Mark) -> void:
		log["set"].append([tick, mark.target, mark.setter]))
	sim.combat.mark_exploded.connect(func(tick: int, mark: Combat.Mark, link: int) -> void:
		log["exploded"].append([tick, mark.target, link, mark.center()]))
	sim.combat.hit.connect(func(tick: int, attacker: String, target: Node2D, damage: int) -> void:
		log["hits"].append([tick, attacker, target, damage]))
	return {"sim": sim, "p1": p1, "echo": echo, "log": log}


func _watch_damage(log: Dictionary, enemy: CombatTarget) -> void:
	enemy.damaged.connect(func(tick: int, amount: int, source: String) -> void:
		log["damage"].append([tick, enemy, amount, source]))


## Speelt `n` ticks met inputbits `bits` voor P1.
func _play(t, w: Dictionary, bits: int, n := 1) -> void:
	w["p1"].input_source.bits = bits
	await t.run_ticks(w["sim"], n)
	w["p1"].input_source.bits = 0


func _damage_of(log: Dictionary, enemy: CombatTarget) -> Array:
	var out: Array = []
	for entry: Array in log["damage"]:
		if entry[1] == enemy:
			out.append([entry[2], entry[3]])
	return out


# --- B-11: slice.csv ---------------------------------------------------------

## B-11: `slice.csv` leest in, heeft elke groep en sleutel die de code vraagt, en de waarden
## houden de regels van §2 (VJ-01, VJ-03, VJ-05) en de maten van echo_v04.json.
func test_b11_slice_csv_complete_and_consistent(t) -> void:
	var all := EnemyData.parse(EnemyData.PATH)
	for g: String in ["gedeeld", "kadeloper", "schotdrager", "dwaallicht", "gemaalmeester"]:
		t.check(all.has(g), "groep '%s' ontbreekt in slice.csv" % g)
	# Elke sleutel die de code leest (EnemyData.REQUIRED), ook een typefout in gedeeld.
	var missing := EnemyData.missing_keys(all)
	t.check(missing.is_empty(), "ontbreekt in slice.csv: %s" % ", ".join(missing))
	# Zelfcontrole: een CSV met een typefout wordt gevonden.
	var broken := all.duplicate(true)
	broken["gedeeld"].erase("v_grens")
	t.check(EnemyData.missing_keys(broken) == PackedStringArray(["gedeeld.v_grens"]),
		"missing_keys vindt een ontbrekende sleutel niet")
	var c: Dictionary = Tuning.combat()
	t.check(int(c["p1_hit_damage"]) == 1 and int(c["p1_invulnerable_ticks"]) == 45, "VJ-02 in echo_v04.json")
	for g: String in ["kadeloper", "schotdrager", "dwaallicht"]:
		# VJ-01: aanloop ≥ 30 ticks, actief vlak ≤ 8 ticks; VJ-03: v_max onder de grens.
		t.check(EnemyData.ticks(g, "aanloop") >= 30, "%s: aanloop %d < 30" % [g, EnemyData.ticks(g, "aanloop")])
		t.check(EnemyData.ticks(g, "actief") <= 8, "%s: actief %d > 8" % [g, EnemyData.ticks(g, "actief")])
		t.check(EnemyData.value(g, "v_max") <= EnemyData.value("gedeeld", "v_grens") + EPS, "%s: v_max boven 0,70" % g)
		t.check(EnemyData.ticks(g, "levens") == 30, "%s: %d SE (30)" % [g, EnemyData.ticks(g, "levens")])
	# VJ-03: 44 = R − 36 en 27 = 30 (stil) − 3 (knal op D + 3).
	t.check(is_equal_approx(EnemyData.value("gedeeld", "v_teller"), float(c["merksprong_radius_px"]) - 36.0),
		"v_teller ≠ R − 36")
	t.check(EnemyData.ticks("gedeeld", "v_aftrek") == EnemyData.ticks("gedeeld", "stil_na_treffer") - 3,
		"v_aftrek ≠ stil_na_treffer − 3")
	# VJ-05: E-paar binnen E (32), K-paar 40–44 px: buiten E, binnen K (48).
	var e_pair := EnemyData.value("gedeeld", "paar_e")
	var k_pair := EnemyData.value("gedeeld", "paar_k")
	t.check(e_pair <= float(c["explosion_radius_px"]), "E-paar %.0f px buiten E" % e_pair)
	t.check(k_pair >= 40.0 and k_pair <= 44.0 and k_pair > float(c["explosion_radius_px"])
		and k_pair <= float(c["chain_radius_px"]), "K-paar %.0f px niet in 40–44" % k_pair)
	# Gemaalmeester (voor B-5–B-10): dalende drempels, 150 SE per opening, Wankel op 300.
	var gm: Dictionary = all.get("gemaalmeester", {})
	var thresholds: Array = []
	for i in int(gm.get("openingen", 0)):
		thresholds.append(int(gm.get("drempel_%d" % (i + 1), -1)))
	t.check(thresholds == [1350, 1200, 1050, 900] and int(gm.get("se", 0)) == 1500
		and int(gm.get("wankel_se", 0)) == 300, "boss-drempels %s, SE %s" % [thresholds, gm.get("se")])


# --- B-1: gedeelde regels -------------------------------------------------------

## B-1 / VJ-03: v(D) = 0,5 / 0,5 / 0,473 / 0,287 bij D = 60 / 90 / 120 / 180 (Kadeloper en
## Schotdrager), 0,25 voor het Dwaallicht; v ≤ 0,70 bij elke D; en een Kadeloper in de Sim loopt
## echt zo snel.
func test_b1_speed_of_d(t) -> void:
	var expected := {60: 0.5, 90: 0.5, 120: 0.473, 180: 0.287}
	for d: int in expected:
		for g: String in ["kadeloper", "schotdrager"]:
			var v := EnemyData.speed(g, d)
			t.check(absf(v - expected[d]) < 0.0006, "%s D = %d: v = %.4f (%.3f)" % [g, d, v, expected[d]])
		t.check(is_equal_approx(EnemyData.speed("dwaallicht", d), 0.25),
			"Dwaallicht D = %d: v = %.4f" % [d, EnemyData.speed("dwaallicht", d)])
	var worst := 0.0
	for d in range(1, 601):
		for g: String in ["kadeloper", "schotdrager", "dwaallicht"]:
			worst = maxf(worst, EnemyData.speed(g, d))
	t.check(worst <= 0.70 + EPS, "v boven 0,70 px/tick: %.3f" % worst)
	for d: int in ALL_D:
		var w := _world(t, 1000.0)
		w["sim"].set_tail_ticks(d)
		var enemy := _enemy(w["sim"], KADELOPER, 300.0)
		await t.run_ticks(w["sim"], 100)
		var moved := enemy.position.x - 300.0
		t.check(absf(moved - 100.0 * EnemyData.speed("kadeloper", d)) < 0.01,
			"D = %d: Kadeloper liep %.2f px in 100 ticks" % [d, moved])
		await t.cleanup()


## B-1 / L-13 (c), (alle D): P1 slaat een Kadeloper op de verste slagafstand, springt erover en
## loopt weg; de Kadeloper volgt hem. De echo knalt het merk op slag + D + 3, en het merk ligt dan
## ≤ R = 80 px van de opgenomen positie (36 + v(D) × (D − 27)).
func test_b1_l13c_mark_within_r_for_every_d(t) -> void:
	var radius := float(Tuning.combat()["merksprong_radius_px"])
	for d: int in ALL_D:
		var w := _world(t, 100.0, d)
		var enemy := _enemy(w["sim"], KADELOPER, 134.0)
		_watch_damage(w["log"], enemy)
		await t.run_ticks(w["sim"], 2)
		var hit_tick: int = w["sim"].tick
		await _play(t, w, A)
		# Erover springen en in de lucht dashen, zodat P1 buiten zijn bereik is als hij weer loopt.
		await _play(t, w, R | J)
		await _play(t, w, R, 9)
		await _play(t, w, R | InputBits.DASH)
		await _play(t, w, R, d + 10)
		var exploded: Array = w["log"]["exploded"]
		t.check(exploded.size() == 1 and exploded[0][0] == hit_tick + d + 3,
			"D = %d: knal %s (verwacht op %d)" % [d, exploded, hit_tick + d + 3])
		if exploded.size() == 1:
			var distance: float = (exploded[0][3] as Vector2).distance_to(Vector2(100.0, Fx.STAND_Y))
			var bound := 36.0 + EnemyData.speed("kadeloper", d) * float(d - 27)
			t.check(distance <= radius and distance > bound - 4.0,
				"D = %d: merk %.1f px van de opgenomen positie (≤ %.0f, verwacht ± %.1f)" % [d, distance, radius, bound])
		t.check(not enemy.alive and _damage_of(w["log"], enemy) == [[10, "p1"], [20, "ontploffing"]],
			"D = %d: schade %s" % [d, _damage_of(w["log"], enemy)])
		await t.cleanup()


## B-1 / VJ-05: een E-paar (28 px) en een K-paar (42 px) komen nooit dichter dan hun `a`; een
## losse vijand en vijanden van verschillende paren nooit binnen 40 px. P1 loopt erdoorheen en
## heen en weer, zodat ze naar elkaar toe lopen. Bij D = 60 en 180.
func test_b1_vj05_pair_distance_rule(t) -> void:
	var e_pair := EnemyData.value("gedeeld", "paar_e")
	var k_pair := EnemyData.value("gedeeld", "paar_k")
	var loose := EnemyData.value("gedeeld", "afstand_los")
	for d: int in [60, 180]:
		var w := _world(t, 470.0)
		var sim = w["sim"]
		sim.set_tail_ticks(d)
		var e1 := _enemy(sim, KADELOPER, 380.0)
		var e2 := _enemy(sim, SCHOTDRAGER, 380.0 + e_pair)
		var k1 := _enemy(sim, KADELOPER, 520.0)
		var k2 := _enemy(sim, KADELOPER, 520.0 + k_pair)
		var lone := _enemy(sim, KADELOPER, 640.0)
		SliceEnemy.make_pair(e1, e2, e_pair)
		SliceEnemy.make_pair(k1, k2, k_pair)
		var all: Array[SliceEnemy] = [e1, e2, k1, k2, lone]
		var mins := {"e": INF, "k": INF, "other": INF}
		sim.tick_finished.connect(func(_tick: int) -> void:
			mins["e"] = minf(mins["e"], e1.position.distance_to(e2.position))
			mins["k"] = minf(mins["k"], k1.position.distance_to(k2.position))
			for i in all.size():
				for j in range(i + 1, all.size()):
					if all[i].pair_partner == all[j]:
						continue
					mins["other"] = minf(mins["other"], all[i].position.distance_to(all[j].position)))
		var p1: PlayerActor = w["p1"]
		# P1 staat tussen de paren, dan links van alles, dan midden in het K-paar.
		for step: Array in [[470.0, 500], [200.0, 900], [540.0, 500]]:
			p1.position = Vector2(step[0], Fx.STAND_Y)
			p1.health = 5
			await t.run_ticks(sim, step[1])
		t.check(mins["e"] >= e_pair - EPS and mins["e"] <= e_pair + 0.6,
			"D = %d: E-paar kwam op %.2f px (a = %.0f)" % [d, mins["e"], e_pair])
		t.check(mins["k"] >= k_pair - EPS and mins["k"] <= k_pair + 0.6,
			"D = %d: K-paar kwam op %.2f px (a = %.0f)" % [d, mins["k"], k_pair])
		t.check(mins["other"] >= loose - EPS and mins["other"] <= loose + 0.6,
			"D = %d: vijanden zonder paar kwamen op %.2f px (≥ %.0f)" % [d, mins["other"], loose])
		await t.cleanup()


## B-1 / VJ-04: na een treffer (merk) staat een Kadeloper 30 ticks stil en breekt zijn aanloop af;
## ook een ontploffing die hem niet doodt, maakt hem 30 ticks stil.
func test_b1_vj04_still_after_hit(t) -> void:
	var w := _world(t, 100.0)
	var sim = w["sim"]
	var enemy := _enemy(sim, KADELOPER, 128.0)
	enemy.health = 200
	await t.run_ticks(sim, 2)
	t.check(enemy.is_telling(), "geen aanloop met P1 binnen bereik")
	var hit_tick: int = sim.tick
	await _play(t, w, A)
	t.check(not enemy.is_telling() and enemy.phase == SliceEnemy.Phase.IDLE, "aanloop niet afgebroken")
	# P1 weg (buiten bereik), zodat hij na het stilstaan loopt.
	w["p1"].position = Vector2(400.0, Fx.STAND_Y)
	var xs: Dictionary = Fx.trace(sim, [enemy])[0]
	await t.run_ticks(sim, 40)
	var still := true
	for tick in range(hit_tick, hit_tick + 30):
		if xs.has(tick) and absf((xs[tick] as Vector2).x - 128.0) > EPS:
			still = false
	t.check(still, "Kadeloper liep binnen 30 ticks na de treffer")
	t.check(xs.has(hit_tick + 30) and (xs[hit_tick + 30] as Vector2).x > 128.0,
		"Kadeloper liep niet op treffer + 30: %s" % [xs.get(hit_tick + 30)])
	# Ontploffing (20 SE, overleeft): weer 30 stil.
	var mark: Combat.Mark = sim.combat.mark_on(enemy)
	t.check(mark != null, "geen merk na de treffer")
	if mark != null:
		var x0 := enemy.position.x
		var boom_tick: int = sim.tick
		sim.combat.detonate(boom_tick, mark)
		await t.run_ticks(sim, 29)
		t.check(enemy.alive and is_equal_approx(enemy.position.x, x0) and enemy.is_stunned(boom_tick + 29),
			"na de ontploffing niet 30 ticks stil (x %.2f → %.2f)" % [x0, enemy.position.x])
	await t.cleanup()


## B-1 / VJ-06 (S9): in een verlichte wijk loopt een Kadeloper 0,25 px/tick (v × 0,5) en is zijn
## aanloop 40 ticks (+10); in het donker 30. Het Dwaallicht keert verlicht niet terug.
func test_b1_vj06_lit_values(t) -> void:
	for lit: bool in [false, true]:
		var w := _world(t, 1000.0)
		var sim = w["sim"]
		var enemy := _enemy(sim, KADELOPER, 300.0)
		enemy.lit = lit
		await t.run_ticks(sim, 100)
		var expected := 0.5 * (0.5 if lit else 1.0)
		t.check(absf(enemy.position.x - 300.0 - 100.0 * expected) < 0.01,
			"verlicht %s: %.2f px in 100 ticks (v %.2f)" % [lit, enemy.position.x - 300.0, expected])
		# Aanloop: P1 binnen bereik, tel de ticks van de tell tot het actieve vlak.
		w["p1"].position = Vector2(enemy.position.x + 20.0, Fx.STAND_Y)
		var phases := {}
		sim.tick_finished.connect(func(tick: int) -> void:
			if enemy.is_telling() and not phases.has("tell"):
				phases["tell"] = tick
			if enemy.is_attack_active() and not phases.has("active"):
				phases["active"] = tick)
		await t.run_ticks(sim, 60)
		var windup: int = phases.get("active", -1000) - phases.get("tell", 0)
		t.check(windup == (40 if lit else 30), "verlicht %s: aanloop %d ticks" % [lit, windup])
		await t.cleanup()
	var w2 := _world(t, 1000.0)
	var dark := _dwaallicht(w2["sim"], 200.0, 232.0)
	var lit_one := _dwaallicht(w2["sim"], 400.0, 432.0)
	lit_one.lit = true
	t.check(dark.is_returning() and not lit_one.is_returning(), "Dwaallicht: terugkeer donker/verlicht fout")
	await t.cleanup()


## B-1 / VJ-02: een treffer kost P1 1 levenspunt; daarna 45 ticks onkwetsbaar.
func test_b1_vj02_p1_invulnerable_45_ticks(t) -> void:
	var w := _world(t, 100.0)
	var sim = w["sim"]
	var p1: PlayerActor = w["p1"]
	await t.run_ticks(sim, 2)
	var tick: int = sim.tick
	p1.take_hit(tick)
	t.check(p1.health == 4 and p1.invulnerable_until == tick + 45, "eerste treffer: %d LP, tot %d" % [p1.health, p1.invulnerable_until])
	p1.take_hit(tick + 44)
	t.check(p1.health == 4, "treffer op + 44 kostte een levenspunt")
	p1.take_hit(tick + 45)
	t.check(p1.health == 3, "treffer op + 45 kostte niets")
	await t.cleanup()


# --- B-2: Kadeloper -----------------------------------------------------------------

## B-2 / §2.2: hij valt alleen aan als P1 binnen 16 px is (randen; middelpunten ≤ 32 px): aanloop
## 30 met tell, dan 6 ticks het vlak (20 × 16 op 4–20 px boven de vloer) dat P1 op de vloer raakt;
## herstel 20. Geen contactschade: P1 die in hem staat terwijl hij stil is, verliest niets.
func test_b2_kadeloper_attacks_only_within_16(t) -> void:
	var w := _world(t, 100.0)
	var sim = w["sim"]
	var p1: PlayerActor = w["p1"]
	var enemy := _enemy(sim, KADELOPER, 200.0)
	var started := []
	enemy.attack_started.connect(func(tick: int) -> void:
		started.append([tick, absf(enemy.position.x - p1.position.x)]))
	var hits := []
	enemy.hit_player.connect(func(tick: int, _p: Node2D) -> void: hits.append(tick))
	var seen := {"runs": [], "run": 0, "box": Rect2(), "tell_visible": false}
	sim.tick_finished.connect(func(_tick: int) -> void:
		if enemy.is_attack_active():
			seen["run"] += 1
			seen["box"] = enemy.active_box
		elif seen["run"] > 0:
			seen["runs"].append(seen["run"])
			seen["run"] = 0
		if enemy.is_telling() and enemy.get_node("Tell").visible:
			seen["tell_visible"] = true)
	await t.run_ticks(sim, 260)
	t.check(not started.is_empty() and started[0][1] <= 32.0 + EPS and started[0][1] > 32.0 - 0.5 - EPS,
		"eerste aanloop op %s px (≤ 32, net binnen bereik)" % [started[0][1] if started else "-"])
	t.check(not hits.is_empty() and hits[0] - started[0][0] == 30, "treffer %s na aanloop %s" % [hits, started])
	t.check(started.size() >= 2 and started[1][0] - started[0][0] == 30 + 6 + 20,
		"volgende aanloop na %s ticks (30 + 6 + 20)" % [started[1][0] - started[0][0] if started.size() >= 2 else "-"])
	var box: Rect2 = seen["box"]
	t.check(box.size == Vector2(20, 16) and is_equal_approx(box.end.y, Fx.FLOOR_TOP - 4.0)
		and is_equal_approx(box.position.y, Fx.FLOOR_TOP - 20.0), "vlak %s (20 × 16 op 4–20 px)" % box)
	t.check(seen["runs"].size() >= 2 and seen["runs"].count(6) == seen["runs"].size(),
		"actieve ticks per aanval %s (6)" % [seen["runs"]])
	t.check(seen["tell_visible"], "geen tell in beeld tijdens de aanloop")
	t.check(p1.health < 5, "P1 op de vloer niet geraakt")
	await t.cleanup()
	# Geen contactschade: P1 midden in een verdoofde Kadeloper.
	var w2 := _world(t, 300.0)
	var still := _enemy(w2["sim"], KADELOPER, 300.0)
	still.stun(0)
	still.health = 1000
	for k in 10:
		still.stun(w2["sim"].tick)
		await t.run_ticks(w2["sim"], 3)
	t.check(w2["p1"].health == 5, "contactschade: P1 op %d LP" % w2["p1"].health)
	await t.cleanup()


## B-2 / §2.2, VJ-08: P1 op de plank van de echo (30 px) wordt niet geraakt; het vlak reikt tot 20 px,
## en sinds v0.1.2 (B-12) begint de Kadeloper daar ook geen aanloop.
func test_b2_kadeloper_misses_p1_on_echo_plank(t) -> void:
	var sim = Fx.world(t)
	var ghost := Fx.ghost(t)
	Fx.ghost_path(ghost, -1, 500, func(_k: int) -> Vector2: return Vector2(300, Fx.STAND_Y))
	var echo := Fx.tail_echo(sim, ghost, 1)
	t.check(echo != null, "geen echo")
	var p1 := Fx.manual_player(sim, 1, Vector2(300, Fx.ON_ECHO_Y - 2))
	var enemy := _enemy(sim, KADELOPER, 360.0)
	var hits := []
	enemy.hit_player.connect(func(tick: int, _p: Node2D) -> void: hits.append(tick))
	var active := {"n": 0}
	sim.tick_finished.connect(func(_tick: int) -> void:
		if enemy.is_attack_active():
			active["n"] += 1)
	await t.run_ticks(sim, 200)
	t.check(p1.motor.on_floor and absf(p1.position.y - Fx.ON_ECHO_Y) < 0.6,
		"P1 staat niet op de echo: %s" % p1.position)
	# VJ-08 (v0.1.2, B-12): op de plank (voeten 30 px boven zijn vloer) begint hij zelfs geen aanloop.
	t.check(active["n"] == 0 and not enemy.is_telling(), "Kadeloper liep aan op P1 op de plank (%d actieve ticks)" % active["n"])
	t.check(hits.is_empty() and p1.health == 5, "P1 op de plank geraakt: %s, %d LP" % [hits, p1.health])
	await t.cleanup()


## B-2 / VJ-05, (alle D): E-paar op 28 px. Eén slag van P1 merkt beide, één knal van de echo
## (merksprong) doodt beide: 10 + 20 SE elk, één ontploffing.
func test_b2_e_pair_one_strike_one_blast(t) -> void:
	var e_pair := EnemyData.value("gedeeld", "paar_e")
	for d: int in ALL_D:
		var w := _world(t, 100.0, d)
		var sim = w["sim"]
		var a := _enemy(sim, KADELOPER, 104.0)
		var b := _enemy(sim, KADELOPER, 104.0 + e_pair)
		SliceEnemy.make_pair(a, b, e_pair)
		_watch_damage(w["log"], a)
		_watch_damage(w["log"], b)
		await t.run_ticks(sim, 2)
		await _play(t, w, A)
		var marks: Array = w["log"]["set"]
		t.check(marks.size() == 2, "D = %d: één slag zette %d merken" % [d, marks.size()])
		await t.run_ticks(sim, d + 10)
		var exploded: Array = w["log"]["exploded"]
		t.check(exploded.size() == 1 and exploded[0][2] == 1, "D = %d: knallen %s (één)" % [d, exploded])
		t.check(not a.alive and not b.alive, "D = %d: paar niet dood (%d, %d SE)" % [d, a.health, b.health])
		t.check(_damage_of(w["log"], b) == [[10, "p1"], [20, "ontploffing"]], "D = %d: schade B %s" % [d, _damage_of(w["log"], b)])
		await t.cleanup()


## B-2 / VJ-05, (alle D): K-paar op 40 px. Twee merken en één knal: ketting 20 + 25, beide dood.
## De tweede Kadeloper heeft na zijn merk nog 20 SE, dus de schakel van 25 doet er 20; met
## `extra` SE erbij (alleen D = 60) is te zien dat de schakel echt 25 is.
func test_b2_k_pair_two_marks_chain(t) -> void:
	for run: Array in [[60, 0], [120, 0], [180, 0], [90, 0], [60, 30]]:
		var d: int = run[0]
		var extra: int = run[1]
		var w := _world(t, 100.0, d)
		var sim = w["sim"]
		var a := _enemy(sim, KADELOPER, 118.0)
		var b := _enemy(sim, KADELOPER, 158.0)
		SliceEnemy.make_pair(a, b, 40.0)
		_watch_damage(w["log"], a)
		_watch_damage(w["log"], b)
		await t.run_ticks(sim, 2)
		await _play(t, w, A)
		await _play(t, w, R, 20)
		await _play(t, w, A)
		b.health += extra
		t.check(w["log"]["set"].size() == 2, "D = %d: %d merken (2)" % [d, w["log"]["set"].size()])
		await t.run_ticks(sim, d + 10)
		var exploded: Array = w["log"]["exploded"]
		t.check(exploded.size() == 2 and exploded[0][2] == 1 and exploded[1][2] == 2
			and exploded[1][0] == exploded[0][0] + 1, "D = %d: ketting %s" % [d, exploded])
		var link2 := 20 if extra == 0 else 25
		t.check(_damage_of(w["log"], a) == [[10, "p1"], [20, "ontploffing"]]
			and _damage_of(w["log"], b).slice(0, 2) == [[10, "p1"], [link2, "ontploffing"]],
			"D = %d (+%d SE): schade %s / %s" % [d, extra, _damage_of(w["log"], a), _damage_of(w["log"], b)])
		t.check(not a.alive and b.alive == (extra > 0), "D = %d (+%d SE): A %s, B %s" % [d, extra, a.alive, b.alive])
		await t.cleanup()


# --- B-3: Schotdrager ------------------------------------------------------------------

## B-3 / §2.3, VJ-07: een treffer op het intacte pantser = 0 SE, 0 LP, wel een merk, en een
## tink-event (en vonk in beeld). Hij is `Kind.ENEMY` met pantser en loopt.
func test_b3_schotdrager_tink(t) -> void:
	var w := _world(t, 100.0)
	var sim = w["sim"]
	var meter := LightMeter.new(sim, w["p1"])
	var enemy := _enemy(sim, SCHOTDRAGER, 118.0)
	_watch_damage(w["log"], enemy)
	var tinks := []
	enemy.tinked.connect(func(tick: int) -> void: tinks.append(tick))
	t.check(enemy.kind == CombatTarget.Kind.ENEMY and enemy.armor_intact and enemy.walks
		and enemy.is_markable(), "Schotdrager is geen lopende Merkbare vijand met pantser")
	await t.run_ticks(sim, 2)
	var tick: int = sim.tick
	await _play(t, w, A)
	t.check(tinks == [tick], "tink %s (op %d)" % [tinks, tick])
	t.check(enemy.health == 30 and _damage_of(w["log"], enemy).is_empty() and w["log"]["hits"].size() == 1
		and w["log"]["hits"][0][3] == 0, "schade op het pantser: %s" % [w["log"]["hits"]])
	t.check(meter.value == 0, "LP na een tink: %d" % meter.value)
	t.check(w["log"]["set"].size() == 1 and enemy.armor_intact, "geen merk of pantser weg")
	t.check(enemy.get_node("Schot").visible and enemy.get_node("Schot").color == SliceEnemy.TINK_COLOR,
		"geen vonk op het schot")
	await t.cleanup()


## B-3 / §2.3, (alle D): in een E-paar (28 px) breekt de knal van het merk op de Kadeloper het
## pantser van de Schotdrager, zonder schade; daarna krijgt hij gewone schade (30 SE).
func test_b3_e_pair_blast_breaks_armor(t) -> void:
	var e_pair := EnemyData.value("gedeeld", "paar_e")
	for d: int in ALL_D:
		var w := _world(t, 100.0, d)
		var sim = w["sim"]
		var kade := _enemy(sim, KADELOPER, 118.0)
		var schot := _enemy(sim, SCHOTDRAGER, 118.0 + e_pair)
		SliceEnemy.make_pair(kade, schot, e_pair)
		_watch_damage(w["log"], schot)
		var broke := []
		schot.armor_broken.connect(func(tick: int) -> void: broke.append(tick))
		await t.run_ticks(sim, 2)
		var hit_tick: int = sim.tick
		await _play(t, w, A)
		t.check(w["log"]["set"].size() == 1, "D = %d: slag merkte ook de Schotdrager" % d)
		await t.run_ticks(sim, d + 6)
		t.check(not kade.alive and broke == [hit_tick + d + 3], "D = %d: pantser brak op %s (%d)" % [d, broke, hit_tick + d + 3])
		t.check(schot.alive and schot.health == 30 and _damage_of(w["log"], schot).is_empty()
			and not schot.armor_intact and not schot.get_node("Schot").visible,
			"D = %d: na de breuk %d SE, schade %s" % [d, schot.health, _damage_of(w["log"], schot)])
		# Daarna: gewone vijand, 30 SE. Een treffer doet 10.
		w["p1"].position = Vector2(schot.position.x - 18.0, Fx.STAND_Y)
		w["p1"].motor.facing = 1
		await t.run_ticks(sim, 25)
		await _play(t, w, A)
		t.check(_damage_of(w["log"], schot) == [[10, "p1"]], "D = %d: treffer na de breuk %s" % [d, _damage_of(w["log"], schot)])
		await t.cleanup()


## B-3 / LM-13a: de Schotdrager komt niet terug, de Kadeloper wel; `revive` geeft de Schotdrager
## zijn pantser terug (voor als een kamer hem toch terugzet).
func test_b3_schotdrager_does_not_return(t) -> void:
	var w := _world(t, 1000.0)
	var schot := _enemy(w["sim"], SCHOTDRAGER, 200.0)
	var kade := _enemy(w["sim"], KADELOPER, 300.0)
	t.check(not schot.is_returning() and kade.is_returning(), "terugkeer Schotdrager/Kadeloper fout")
	schot.break_armor(0)
	schot.apply_damage(0, 30, "p1")
	schot.revive()
	t.check(schot.alive and schot.armor_intact and schot.health == 30, "revive zonder pantser of leven")
	await t.cleanup()


# --- B-4: Dwaallicht ----------------------------------------------------------------------

## B-4 / §2.4: hij zweeft heen en weer op zijn baan (0,25 px/tick, onderkant 40 px); duikt als
## P1 er horizontaal binnen 24 px onder staat: aanloop 30, duik 8 ticks tot 16 px boven de vloer
## (raakt P1 op de vloer), dan 40 ticks terug zonder schade.
func test_b4_dwaallicht_lane_and_dive(t) -> void:
	var w := _world(t, 600.0)
	var sim = w["sim"]
	var p1: PlayerActor = w["p1"]
	var lane_y := Fx.FLOOR_TOP - 40.0 - 8.0
	var enemy := _dwaallicht(sim, 200.0, 232.0)
	t.check(is_equal_approx(enemy.position.y, lane_y), "baan op y %.1f (%.1f)" % [enemy.position.y, lane_y])
	var xs: Dictionary = Fx.trace(sim, [enemy])[0]
	await t.run_ticks(sim, 300)
	var lo := INF
	var hi := -INF
	for tick: int in xs:
		lo = minf(lo, (xs[tick] as Vector2).x)
		hi = maxf(hi, (xs[tick] as Vector2).x)
	t.check(is_equal_approx(lo, 200.0) and is_equal_approx(hi, 232.0), "baan %.2f–%.2f (200–232)" % [lo, hi])
	t.check(is_equal_approx(absf((xs[150] as Vector2).x - (xs[149] as Vector2).x), 0.25), "snelheid niet 0,25")
	# P1 eronder: aanloop, duik, terug.
	var started := []
	enemy.attack_started.connect(func(tick: int) -> void: started.append(tick))
	var hits := []
	enemy.hit_player.connect(func(tick: int, _p: Node2D) -> void: hits.append(tick))
	var ys := {}
	sim.tick_finished.connect(func(tick: int) -> void: ys[tick] = enemy.position.y)
	p1.position = Vector2(enemy.position.x + 10.0, Fx.STAND_Y)
	await t.run_ticks(sim, 1)
	var t0: int = started[0] if started else -1
	await t.run_ticks(sim, 90)
	t.check(t0 >= 0 and hits.size() == 1 and hits[0] >= t0 + 30 and hits[0] < t0 + 38,
		"duik raakte P1 op %s (aanloop vanaf %d)" % [hits, t0])
	var bottom_y := Fx.FLOOR_TOP - 16.0 - 8.0
	t.check(t0 >= 0 and is_equal_approx(ys.get(t0 + 29, 0.0), lane_y) and is_equal_approx(ys.get(t0 + 37, 0.0), bottom_y)
		and ys.get(t0 + 38, 0.0) < bottom_y and is_equal_approx(ys.get(t0 + 77, 0.0), lane_y),
		"duik: y %s / %s / %s (baan %.0f, bodem %.0f)" % [ys.get(t0 + 29), ys.get(t0 + 37), ys.get(t0 + 77), lane_y, bottom_y])
	t.check(p1.health == 4, "P1 op %d LP na één duik" % p1.health)
	await t.cleanup()


## B-4 / V-01b, V-01e, (alle D): een neerslag van P1 op een Dwaallicht op 40 px = stuit (v.y = −5,
## dash terug) + merk + 10 SE; de echo herhaalt de neerslag als merksprong en knalt: 30 SE samen.
func test_b4_neerslag_on_dwaallicht_stuit_mark_and_echo(t) -> void:
	for d: int in ALL_D:
		var w := _world(t, 216.0, d)
		var sim = w["sim"]
		var p1: PlayerActor = w["p1"]
		var enemy := _dwaallicht(sim, 210.0, 242.0)
		_watch_damage(w["log"], enemy)
		var stuits := []
		sim.stuit.connect(func(tick: int, body: Node2D) -> void: stuits.append([tick, body]))
		await t.run_ticks(sim, 2)
		await _play(t, w, J)
		await _play(t, w, DOWN, 12)
		var strike_tick: int = sim.tick
		await _play(t, w, DOWN | A)
		t.check(stuits.size() == 1 and stuits[0][0] == strike_tick and stuits[0][1] == p1,
			"D = %d: stuit %s (op %d)" % [d, stuits, strike_tick])
		t.check(is_equal_approx(p1.motor.velocity.y, -5.0) and p1.motor.dash_ready,
			"D = %d: na de stuit v.y %.2f, dash %s" % [d, p1.motor.velocity.y, p1.motor.dash_ready])
		t.check(w["log"]["set"].size() == 1 and w["log"]["set"][0][1] == enemy, "D = %d: geen merk" % d)
		await t.run_ticks(sim, d + 10)
		t.check(not enemy.alive and _damage_of(w["log"], enemy) == [[10, "p1"], [20, "ontploffing"]],
			"D = %d: schade %s" % [d, _damage_of(w["log"], enemy)])
		t.check(w["echo"].tick_events == 0 and stuits.size() == 1, "D = %d: de echo stuitte" % d)
		await t.cleanup()


## V-01: een neerslag zonder doel geeft geen stuit; een aanval op de grond met DOWN is een
## gewone aanval (vlak vóór P1).
func test_b4_neerslag_needs_target_and_air(t) -> void:
	var w := _world(t, 100.0)
	var sim = w["sim"]
	var stuits := []
	sim.stuit.connect(func(tick: int, _body: Node2D) -> void: stuits.append(tick))
	var enemy := _enemy(sim, KADELOPER, 118.0)
	enemy.health = 1000
	await t.run_ticks(sim, 2)
	await _play(t, w, DOWN | A)
	t.check(w["log"]["hits"].size() == 1 and stuits.is_empty(), "DOWN op de grond: %s, stuit %s" % [w["log"]["hits"], stuits])
	await _play(t, w, 0, 25)
	w["p1"].position = Vector2(600.0, Fx.STAND_Y)
	await t.run_ticks(sim, 2)
	await _play(t, w, J)
	await _play(t, w, DOWN, 10)
	await _play(t, w, DOWN | A)
	t.check(stuits.is_empty() and w["log"]["hits"].size() == 1, "neerslag zonder doel stuitte: %s" % [stuits])
	await t.cleanup()


## B-4 / §2.6 S7, (alle D): de scripted run haalt de overkant van een kanaal van 160 px via twee
## stuiten op de Dwaallichten (banen van 32 px rond 1/3 en 2/3, onderkant 40 px), zonder te landen
## tussen de oevers.
func test_b4_s7_crossing_with_two_stuits(t) -> void:
	for d: int in ALL_D:
		var sim = t.make_sim(false)
		# Oevers: links tot x = 0, rechts vanaf x = 160; het kanaal ertussen is diep.
		Fx.block(t, "OeverLinks", Rect2(-600, Fx.FLOOR_TOP, 600, 40), Layers.WORLD)
		Fx.block(t, "OeverRechts", Rect2(160, Fx.FLOOR_TOP, 600, 40), Layers.WORLD)
		Fx.block(t, "Bodem", Rect2(-600, Fx.FLOOR_TOP + 300, 1400, 40), Layers.WORLD)
		var p1 := Fx.manual_player(sim, 1, Vector2(-60, Fx.STAND_Y))
		var echo := Fx.tail_echo(sim, p1, d)
		var lights: Array[SliceEnemy] = [_dwaallicht(sim, 37.0, 69.0), _dwaallicht(sim, 91.0, 123.0)]
		var stuits := []
		sim.stuit.connect(func(tick: int, _body: Node2D) -> void: stuits.append(tick))
		var lowest := {"y": -INF}
		var landed_in_gap := {"n": 0}
		sim.tick_finished.connect(func(_tick: int) -> void:
			lowest["y"] = maxf(lowest["y"], p1.position.y)
			if p1.motor.on_floor and p1.position.x > 8.0 and p1.position.x < 152.0:
				landed_in_gap["n"] += 1)
		await t.run_ticks(sim, 2)
		var jumped := false
		for k in 260:
			var bits := 0
			var target: SliceEnemy = null
			for light in lights:
				if light.alive and not light.is_stunned(sim.tick) and light.position.x > p1.position.x - 16.0:
					target = light
					break
			if not jumped:
				bits = R
				if p1.position.x >= -6.0:
					bits |= J
					jumped = true
			elif p1.motor.on_floor:
				bits = 0
			elif target == null:
				bits = R | DOWN
			else:
				bits = DOWN
				if p1.position.x < target.position.x - 2.0:
					bits |= R
				# Zou het neerslagvlak na de volgende stap het Dwaallicht raken? Dan slaan.
				var v: Vector2 = p1.motor.velocity
				var next := p1.position + Vector2(2.0 if bits & R else 0.0, v.y + 0.125)
				var box: Rect2 = sim.combat.neerslag_box(next).grow(-2.0)
				var hurt := Rect2(target.position - Vector2(8, 8), Vector2(16, 16))
				if box.intersects(hurt) and p1.last_input & A == 0:
					bits |= A
			p1.input_source.bits = bits
			await t.run_ticks(sim, 1)
			if jumped and p1.motor.on_floor and p1.position.x > 160.0:
				break
		t.check(stuits.size() == 2, "D = %d: %d stuiten (2): %s" % [d, stuits.size(), stuits])
		t.check(p1.motor.on_floor and p1.position.x > 168.0 and absf(p1.position.y - Fx.STAND_Y) < 0.6,
			"D = %d: P1 niet aan de overkant: %s" % [d, p1.position])
		t.check(lowest["y"] <= Fx.STAND_Y + 0.6 and landed_in_gap["n"] == 0,
			"D = %d: P1 zakte in het kanaal (y %.1f)" % [d, lowest["y"]])
		t.check(echo != null, "D = %d: geen echo" % d)
		await t.cleanup()


# --- B-12: antwoorden #190 (VJ-08, VJ-02) ---------------------------------------------

## Een Kadeloper of Schotdrager op `x` en P1 met handmatige input op `p1_at`; telt aanlopen en treffers.
func _vj08_case(t, type: int, p1_at: Vector2, n: int, blocks: Array = [], enemy_floor := Fx.FLOOR_TOP,
		jump_at := -1) -> Dictionary:
	var sim = Fx.world(t)
	for r: Rect2 in blocks:
		Fx.block(t, "Blok%d" % blocks.find(r), r, Layers.WORLD)
	var p1 := Fx.manual_player(sim, 1, p1_at)
	sim.set_tail_ticks(60)
	var enemy := SliceEnemy.new()
	enemy.setup_enemy(type, 300.0, enemy_floor)
	sim.add_object(enemy)
	var seen := {"windups": [], "hits": [], "active": 0, "feet": []}
	enemy.attack_started.connect(func(tick: int) -> void:
		seen["windups"].append(tick)
		seen["feet"].append(snappedf(enemy_floor - (p1.position.y + 15.0), 0.01)))
	enemy.hit_player.connect(func(tick: int, _p: Node2D) -> void: seen["hits"].append(tick))
	sim.tick_finished.connect(func(tick: int) -> void:
		if enemy.is_attack_active():
			seen["active"] += 1
		if tick == jump_at:
			p1.input_source.bits = J
		elif tick == jump_at + 1:
			p1.input_source.bits = 0)
	await t.run_ticks(sim, n)
	await t.cleanup()
	return seen


## B-12 / VJ-08: een Kadeloper en een Schotdrager beginnen hun aanloop alleen als P1 binnen 32 px
## is (middelpunten) én de voeten van P1 tussen −20 en +20 px van hun vloer zijn
## (`aanloop_hoogte_min` / `_max` in slice.csv). P1 recht boven hem op 30 px (plank) of in de lucht:
## geen aanloop; P1 30 px lager, binnen 32 px: geen aanloop; P1 op de vloer binnen 32 px: aanloop;
## P1 op 20 px: aanloop, op 22 px: niet.
func test_b12_vj08_windup_only_in_height(t) -> void:
	for g: String in ["kadeloper", "schotdrager"]:
		t.check(EnemyData.value(g, "aanloop_hoogte_min") == -20.0 and EnemyData.value(g, "aanloop_hoogte_max") == 20.0,
			"%s: hoogtegrenzen %s … %s (−20 … 20)" % [g, EnemyData.value(g, "aanloop_hoogte_min"), EnemyData.value(g, "aanloop_hoogte_max")])
	for type: int in [KADELOPER, SCHOTDRAGER]:
		var name := "Kadeloper" if type == KADELOPER else "Schotdrager"
		# Op de vloer, 20 px ernaast: aanloop (controle).
		var floor_case := await _vj08_case(t, type, Vector2(320, Fx.STAND_Y), 40)
		t.check(not floor_case["windups"].is_empty(), "%s: geen aanloop op P1 op de vloer" % name)
		# Recht boven hem op een plank op 30 px (een blok, zoals de plank van de echo).
		var plank := await _vj08_case(t, type, Vector2(300, Fx.FLOOR_TOP - 30 - 15), 120,
			[Rect2(290, Fx.FLOOR_TOP - 30, 20, 4)])
		t.check(plank["windups"].is_empty(), "%s: aanloop op P1 recht boven hem op 30 px %s" % [name, plank["feet"]])
		# In de lucht recht boven hem: P1 valt van 60 px; na 15 ticks zijn zijn voeten nog op ± 32 px.
		var air := await _vj08_case(t, type, Vector2(300, Fx.STAND_Y - 60), 15)
		t.check(air["windups"].is_empty(), "%s: aanloop op P1 in de lucht %s" % [name, air["feet"]])
		# P1 30 px lager: de vijand op een verhoging (rand op 320), P1 ernaast op de vloer, 18 px verder.
		var low := await _vj08_case(t, type, Vector2(318, Fx.STAND_Y), 120,
			[Rect2(200, Fx.FLOOR_TOP - 30, 108, 30)], Fx.FLOOR_TOP - 30)
		t.check(low["windups"].is_empty(), "%s: aanloop op P1 30 px lager %s" % [name, low["feet"]])
		# Grens: voeten op 20 px (aanloop) en op 22 px (geen).
		var at20 := await _vj08_case(t, type, Vector2(322, Fx.FLOOR_TOP - 20 - 15), 40,
			[Rect2(312, Fx.FLOOR_TOP - 20, 30, 20)])
		var at22 := await _vj08_case(t, type, Vector2(322, Fx.FLOOR_TOP - 22 - 15), 40,
			[Rect2(312, Fx.FLOOR_TOP - 22, 30, 22)])
		t.check(not at20["windups"].is_empty() and at22["windups"].is_empty(),
			"%s: op 20 px %s, op 22 px %s" % [name, at20["feet"], at22["feet"]])


## B-12 / VJ-08: springt P1 tijdens de aanloop, dan loopt de aanloop door (het vlak komt; springen
## blijft een ontwijking: hij wordt niet geraakt).
func test_b12_vj08_windup_continues_when_p1_jumps(t) -> void:
	for type: int in [KADELOPER, SCHOTDRAGER]:
		# P1 20 px naast hem: aanloop op tick 0, P1 springt op 10 (voeten > 20 px op het vlak, 30–35).
		var seen := await _vj08_case(t, type, Vector2(320, Fx.STAND_Y), 50, [], Fx.FLOOR_TOP, 10)
		t.check(seen["windups"].size() == 1 and seen["windups"][0] <= 1 and seen["active"] == 6,
			"aanloop %s, actieve ticks %d (6)" % [seen["windups"], seen["active"]])
		t.check(seen["hits"].is_empty(), "P1 in de sprong geraakt: %s" % [seen["hits"]])


## B-12 / VJ-02, LM-05 (gdd v0.8.1): de dodelijke treffer geeft geen onkwetsbaarheid; na de respawn is
## P1 45 ticks onkwetsbaar (`combat.p1_respawn_invulnerable_ticks`, `r … r + 44`): een Kadeloper die op het respawnpunt
## al in zijn aanloop zat, raakt P1 niet; zijn volgende aanval (na r + 45) wel.
func test_b12_vj02_invulnerable_after_respawn(t) -> void:
	t.check(int(Tuning.combat()["p1_respawn_invulnerable_ticks"]) == 45, "p1_respawn_invulnerable_ticks %d (45)"
		% int(Tuning.combat()["p1_respawn_invulnerable_ticks"]))
	var w := _world(t, 400.0)
	var sim = w["sim"]
	var p1: PlayerActor = w["p1"]
	var respawn := Respawn.new(p1, func() -> Vector2: return Vector2(400, Fx.STAND_Y))
	var enemy := _enemy(sim, KADELOPER, 420.0)
	var windups := []
	enemy.attack_started.connect(func(tick: int) -> void: windups.append(tick))
	var attempts := []
	enemy.hit_player.connect(func(tick: int, _p: Node2D) -> void: attempts.append(tick))
	await _run_to(t, sim, 1)
	t.check(windups == [0], "aanloop %s (op 0)" % [windups])
	# Midden in de aanloop sterft P1 (laatste levenspunt, een andere bron): geen onkwetsbaarheid.
	await _run_to(t, sim, 10)
	p1.health = 1
	p1.take_hit(9)
	t.check(p1.health == 0 and p1.invulnerable_until < 10, "dodelijke treffer: %d LP, onkwetsbaar tot %d" % [p1.health, p1.invulnerable_until])
	await t.run_ticks(sim, 1)
	var r: int = sim.tick - 1
	t.check(p1.died and p1.health == 5 and p1.invulnerable_until == r + 45, "respawn op %d: died %s, %d LP, tot %d"
		% [r, p1.died, p1.health, p1.invulnerable_until])
	await _run_to(t, sim, 40)
	t.check(attempts.size() == 1 and attempts[0] >= r and attempts[0] < r + 45 and p1.health == 5,
		"de aanloop van vóór de respawn raakte op %s (respawn %d), %d LP" % [attempts, r, p1.health])
	await _run_to(t, sim, r + 100)
	t.check(attempts.size() == 2 and attempts[1] >= r + 45 and p1.health == 4,
		"volgende aanval op %s, %d LP (4)" % [attempts, p1.health])
	t.check(respawn != null, "respawn")
	await t.cleanup()


func _run_to(t, sim: Node, tick: int) -> void:
	if tick > sim.tick:
		await t.run_ticks(sim, tick - sim.tick)
