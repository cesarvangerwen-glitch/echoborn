extends RefCounted
## Tests voor aanval (E-10, E-10a), schaduwmerk (E-14), merksprong (E-02m)
## en de merk-combo in co-op (C-12). T16a deel 2, #76.
##
## Geometrische gevallen van de merksprong gebruiken een spookbron met D = 1
## (EchoFixture.ghost): de echo staat op tick t op het frame van t − 1, met
## een AANVAL-event op een gekozen plek. Gevallen met "(alle D)" gebruiken de
## echte echo van P1 voor D = 90, 120 en 180. Merken zet P1 zelf, met een
## treffer (E-14a); hij wordt daarvoor naast het doel gezet (respawn).

const Fx = preload("res://tests/echo_fixture.gd")
const InputBits = preload("res://scripts/input/input_bits.gd")
const PlayerActor = preload("res://scripts/echo/player_actor.gd")
const TailEcho = preload("res://scripts/echo/tail_echo.gd")
const Motor = preload("res://scripts/echo/motor.gd")
const CombatTarget = preload("res://scripts/combat/combat_target.gd")
const Combat = preload("res://scripts/combat/combat.gd")
const GameEvents = preload("res://scripts/events/game_events.gd")
const Layers = preload("res://scripts/world/layers.gd")
const Lever = preload("res://scripts/objects/lever.gd")
const Zone = preload("res://scripts/objects/zone.gd")

const L := InputBits.LEFT
const R := InputBits.RIGHT
const J := InputBits.JUMP
const A := InputBits.ATTACK
const I := InputBits.INTERACT
const E := InputBits.ECHO
const ALL_D := [90, 120, 180]
const ENEMY := CombatTarget.Kind.ENEMY
const ARMORED := CombatTarget.Kind.ARMORED
const DUMMY := CombatTarget.Kind.DUMMY


# --- hulpmiddelen ----------------------------------------------------------

## Wereld met P1 (handmatige input) en stilstaande doelen op de vloer.
func _arena(t, xs: Array, kind: int = ENEMY, health := 30) -> Dictionary:
	var sim = Fx.world(t)
	var p1 := Fx.manual_player(sim, 1, Vector2(100, Fx.STAND_Y))
	var targets: Array = []
	for x: float in xs:
		var target := Fx.target(sim, kind, x)
		target.health = health
		targets.append(target)
	var log := {"damage": [], "exploded": [], "set": [], "hits": []}
	for target: CombatTarget in targets:
		target.damaged.connect(func(tick: int, amount: int, source: String) -> void:
			log["damage"].append([tick, targets.find(target), amount, source]))
	sim.combat.mark_exploded.connect(func(tick: int, mark: Combat.Mark, link: int) -> void:
		log["exploded"].append([tick, targets.find(mark.target), link]))
	sim.combat.mark_set.connect(func(tick: int, mark: Combat.Mark) -> void:
		log["set"].append([tick, targets.find(mark.target), mark.setter]))
	sim.combat.hit.connect(func(tick: int, attacker: String, target: Node2D, damage: int) -> void:
		log["hits"].append([tick, attacker, targets.find(target), damage]))
	await t.run_ticks(sim, 2)
	return {"sim": sim, "p1": p1, "targets": targets, "log": log}


## P1 springt naast `target`, slaat één keer en wacht de herhaaltijd af.
func _mark(t, a: Dictionary, target: CombatTarget, player: PlayerActor = null) -> void:
	var p: PlayerActor = player if player else a["p1"]
	p.respawn_at(Vector2(target.position.x - 20.0, Fx.STAND_Y))
	await t.run_ticks(a["sim"], 1)
	p.input_source.bits = A
	await t.run_ticks(a["sim"], 1)
	p.input_source.bits = 0
	await t.run_ticks(a["sim"], 20)


## Spookecho (D = 1) op `q` (zwevend, op vloerhoogte), met een AANVAL op frame start + 4: de echo
## verwerkt dat event op tick `t` = start + 5. `at(k)` geeft een ander pad.
func _ghost_attack(t, a: Dictionary, q: Vector2, at := Callable()) -> Dictionary:
	var sim: Node = a["sim"]
	var ghost := Fx.ghost(t)
	var start: int = sim.tick
	for k in 200:
		var where: Vector2 = at.call(k) if at.is_valid() else q
		Fx.ghost_frame(ghost, start + k, where, false, Motor.Support.NONE,
			GameEvents.ATTACK if k == 4 else 0)
	var echo := Fx.tail_echo(sim, ghost, 1)
	var trace := Fx.trace(sim, [echo])
	var broke: Array = []
	echo.broke.connect(func(tick: int, _at: Vector2) -> void: broke.append(tick))
	var jumps: Array = []
	echo.merksprong_started.connect(func(tick: int, _id: int) -> void: jumps.append(tick))
	return {"echo": echo, "t": start + 5, "pos": trace[0], "broke": broke, "jumps": jumps}


func _damage_of(log: Dictionary, index: int) -> Array:
	return log["damage"].filter(func(row: Array) -> bool: return row[1] == index)


func _center(target: CombatTarget) -> Vector2:
	return target.global_position


# --- E-10, E-10a ---------------------------------------------------------

## (alle D) INTERACTIE bij een schaduwhendel op x: hendel om op x + D. AANVAL
## 60 ticks vast: één event; twee flanken 10 ticks na elkaar: één; 20: twee.
## De echo herhaalt precies dezelfde treffers D ticks later (5 SE).
func test_e10_events_replayed_by_tail_all_d(t) -> void:
	for d: int in ALL_D:
		for pattern in ["vast", "10", "20"]:
			var sim = Fx.world(t)
			var dummy := Fx.target(sim, DUMMY, 220.0)
			var lever := Lever.new()
			lever.setup(Layers.SHADOW, Vector2(40, 40))
			lever.position = Vector2(200, Fx.STAND_Y)
			sim.add_object(lever)
			var segments := [[10, 0], [1, I], [9, 0]]
			match pattern:
				"vast":
					segments += [[60, A]]
				"10":
					segments += [[1, A], [9, 0], [1, A]]
				"20":
					segments += [[1, A], [19, 0], [1, A]]
			segments += [[400, 0]]
			var p1 := Fx.p1(sim, segments)
			Fx.tail_echo(sim, p1, d)
			var hits: Array = []
			sim.combat.hit.connect(func(tick: int, attacker: String, _target: Node2D, damage: int) -> void:
				hits.append([tick, attacker, damage]))
			var flips: Array = []
			lever.changed.connect(func(tick: int, _on: bool, _by: Node2D) -> void: flips.append(tick))
			await t.run_ticks(sim, d + 100)
			var p1_hits := hits.filter(func(h: Array) -> bool: return h[1] == "p1")
			var echo_hits := hits.filter(func(h: Array) -> bool: return h[1] == "echo")
			var expected := 2 if pattern == "20" else 1
			t.check(p1_hits.size() == expected and echo_hits.size() == expected,
				"D = %d, %s: P1 %d treffers, echo %d (verwacht %d)" % [d, pattern, p1_hits.size(), echo_hits.size(), expected])
			var shifted := true
			for i in mini(p1_hits.size(), echo_hits.size()):
				shifted = shifted and echo_hits[i][0] == p1_hits[i][0] + d and echo_hits[i][2] == 5
			t.check(shifted, "D = %d, %s: echo-treffers niet D ticks later met 5 SE: %s" % [d, pattern, str(hits)])
			t.check(flips == [10 + d], "D = %d: hendel om op %s (verwacht %d)" % [d, str(flips), 10 + d])
			await t.cleanup()


## E-10a: P1 kijkt links en slaat; met een trefpop links en rechts raakt de
## echo D ticks later alleen de linker, en het vlak is maar 1 tick actief.
func test_e10a_attack_box_uses_recorded_facing(t) -> void:
	var sim = Fx.world(t)
	var left := Fx.target(sim, DUMMY, 178.0)
	var right := Fx.target(sim, DUMMY, 218.0)
	var p1 := Fx.p1(sim, [[10, 0], [1, L], [1, A], [300, 0]])
	Fx.tail_echo(sim, p1, 120)
	var hits: Array = []
	sim.combat.hit.connect(func(tick: int, attacker: String, target: Node2D, _damage: int) -> void:
		hits.append([tick, attacker, "links" if target == left else "rechts"]))
	await t.run_ticks(sim, 150)
	t.check(hits == [[11, "p1", "links"], [131, "echo", "links"]],
		"treffers %s (alleen links, op 11 en 131)" % str(hits))
	t.check(right.damage_taken == 0 and left.damage_taken == 15, "schade links %d, rechts %d" % [
		left.damage_taken, right.damage_taken])


# --- E-14 ----------------------------------------------------------------

## (a, c, e) Eén merk per doel, 10 SE per P1-treffer, geen ontploffing door
## P1 of door losse knoppen, met echo uit dooft het op x + D + 30; een
## gewone echo-treffer zet geen merk en doet 5 SE.
func test_e14_a_c_e_marks_and_plain_hits(t) -> void:
	var a := await _arena(t, [220.0], ENEMY, 1000)
	var log: Dictionary = a["log"]
	var p1: PlayerActor = a["p1"]
	var faded := {"tick": -1}
	a["sim"].combat.mark_faded.connect(func(tick: int, _m: Combat.Mark) -> void: faded["tick"] = tick)
	await _mark(t, a, a["targets"][0])
	var x: int = log["set"][0][0]
	p1.input_source.bits = A
	await t.run_ticks(a["sim"], 1)
	p1.input_source.bits = 0
	for bit in [L, R, J, I, E, InputBits.DASH]:
		p1.input_source.bits = bit
		await t.run_ticks(a["sim"], 60)
		p1.input_source.bits = 0
		await t.run_ticks(a["sim"], 1)
	await t.run_ticks(a["sim"], 5)
	t.check(log["set"].size() == 1, "%d merken gezet (1)" % log["set"].size())
	t.check(_damage_of(log, 0).map(func(r: Array) -> int: return r[2]) == [10, 10],
		"schade %s (10, 10)" % str(_damage_of(log, 0)))
	t.check(log["exploded"].is_empty(), "ontploffing zonder ontsteker: %s" % str(log["exploded"]))
	t.check(faded["tick"] == x + 150, "merk doofde op %d (x + D + 30 = %d)" % [faded["tick"], x + 150])
	await t.cleanup()
	# (e) gewone echo-treffer op een doel zonder merk.
	a = await _arena(t, [360.0])
	var g := _ghost_attack(t, a, Vector2(340, Fx.STAND_Y))
	await t.run_ticks(a["sim"], 10)
	log = a["log"]
	t.check(log["set"].is_empty() and _damage_of(log, 0).map(func(r: Array) -> int: return r[2]) == [5],
		"echo-treffer: merken %s, schade %s (geen merk, 5 SE)" % [str(log["set"]), str(log["damage"])])
	t.check(g["jumps"].is_empty(), "merksprong zonder merk")


## (b) (alle D) Loslaten op x + 1, zodat de echo de treffer niet herhaalt:
## het merk dooft op x + D + 30 zonder schade; de aftelling start op x + D − 30.
func test_e14_b_lifetime_all_d(t) -> void:
	for d: int in ALL_D:
		var sim = Fx.world(t)
		var enemy := Fx.target(sim, ENEMY, 220.0)
		# ECHO op 13 … 42 (30 ticks: Loslaten op 42), AANVAL op x = 41.
		var p1 := Fx.p1(sim, [[13, 0], [28, E], [1, E | A], [1, E], [400, 0]])
		Fx.tail_echo(sim, p1, d)
		var marks: Array = []
		sim.combat.mark_set.connect(func(_tick: int, m: Combat.Mark) -> void: marks.append(m))
		var faded := {"tick": -1}
		sim.combat.mark_faded.connect(func(tick: int, _m: Combat.Mark) -> void: faded["tick"] = tick)
		await t.run_ticks(sim, 41 + d + 35)
		var x := 41
		t.check(marks.size() == 1 and marks[0].born == x, "D = %d: merk niet op tick 41 gezet" % d)
		if marks.size() == 1:
			var m: Combat.Mark = marks[0]
			t.check(not m.counting_down(x + d - 31, 60) or m.expires != x + d + 30,
				"D = %d: aftelling te vroeg" % d)
			t.check(m.expires == x + d + 30 and m.expires - 60 == x + d - 30, "D = %d: levensduur %d" % [d, m.expires - x])
		t.check(faded["tick"] == x + d + 30 and enemy.damage_taken == 10,
			"D = %d: gedoofd op %d (verwacht %d), schade %d (10)" % [d, faded["tick"], x + d + 30, enemy.damage_taken])
		await t.cleanup()


## (d) Ontploffing en ketting: straal 32, ketting 48, schakels 20/25/30 … 40.
func test_e14_d_explosion_and_chain(t) -> void:
	# Merk op V1, V2 op 30 px zonder merk: beide 20 SE.
	var a := await _arena(t, [400.0, 430.0], ENEMY, 1000)
	await _mark(t, a, a["targets"][0])
	var g := _ghost_attack(t, a, Vector2(340, Fx.STAND_Y))
	await t.run_ticks(a["sim"], 12)
	var tick0: int = g["t"] + 3
	t.check(_damage_of(a["log"], 1) == [[tick0, 1, 20, "ontploffing"]]
		and _damage_of(a["log"], 0).back() == [tick0, 0, 20, "ontploffing"],
		"V1/V2 op 30 px: %s" % str(a["log"]["damage"]))
	await t.cleanup()
	# Ketting V1 – V2 – V3 op 40 px; V3 op 80 px van V1. Merk op 49 px: geen ketting.
	a = await _arena(t, [400.0, 440.0, 480.0, 529.0], ENEMY, 1000)
	for i in 4:
		await _mark(t, a, a["targets"][i])
	g = _ghost_attack(t, a, Vector2(340, Fx.STAND_Y))
	await t.run_ticks(a["sim"], 14)
	tick0 = g["t"] + 3
	t.check(a["log"]["exploded"] == [[tick0, 0, 1], [tick0 + 1, 1, 2], [tick0 + 2, 2, 3]],
		"ketting %s" % str(a["log"]["exploded"]))
	var blast := func(i: int) -> Array:
		return _damage_of(a["log"], i).filter(func(r: Array) -> bool: return r[3] == "ontploffing")
	t.check(blast.call(0).map(func(r: Array) -> int: return r[2]) == [20]
		and blast.call(1).map(func(r: Array) -> int: return r[2]) == [25]
		and blast.call(2).map(func(r: Array) -> int: return r[2]) == [30],
		"schakelschade %s" % str(a["log"]["damage"]))
	t.check(blast.call(3).is_empty() and a["sim"].combat.mark_on(a["targets"][3]) != null,
		"merk op 49 px ontplofte mee")
	t.check(a["p1"].health == 5, "ontploffing deed P1 schade")
	await t.cleanup()
	# Ketting van 6: de 6e schakel doet 40 SE.
	var xs: Array = []
	for i in 6:
		xs.append(400.0 + 40.0 * i)
	a = await _arena(t, xs, ENEMY, 1000)
	for i in 6:
		await _mark(t, a, a["targets"][i])
	g = _ghost_attack(t, a, Vector2(340, Fx.STAND_Y))
	await t.run_ticks(a["sim"], 16)
	var sixth: Array = _damage_of(a["log"], 5).filter(func(r: Array) -> bool: return r[3] == "ontploffing")
	t.check(sixth.size() == 1 and sixth[0][2] == 40 and sixth[0][0] == g["t"] + 8,
		"6e schakel: %s (40 SE op t + 8)" % str(sixth))


## (g) Pantser: met echo uit 0 SE en één merk; met echo breekt de ontploffing
## het pantser zonder schade, daarna gewone treffers. Ketting: het pantser
## breekt op t_o, zijn eigen merk doet op t_o + 1 25 SE op het lichaam.
func test_e14_g_armor(t) -> void:
	var script := [[10, 0], [1, A], [19, 0], [1, A], [19, 0], [1, A], [149, 0], [1, A], [100, 0]]
	for with_echo in [false, true]:
		var sim = Fx.world(t)
		var armor := Fx.target(sim, ARMORED, 220.0)
		var p1 := Fx.p1(sim, script)
		var marks: Array = []
		sim.combat.mark_set.connect(func(tick: int, _m: Combat.Mark) -> void: marks.append(tick))
		var broke_at := {"tick": -1}
		armor.armor_broken.connect(func(tick: int) -> void: broke_at["tick"] = tick)
		if with_echo:
			Fx.tail_echo(sim, p1, 120)
		await t.run_ticks(sim, 60)
		t.check(armor.health == 30 and armor.armor_intact and marks == [10],
			"echo %s: na 3 treffers %d SE, merken %s (30, één merk)" % [with_echo, armor.health, str(marks)])
		if with_echo:
			await t.run_ticks(sim, 74)
			t.check(broke_at["tick"] == 133 and armor.health == 30, "pantser brak op %d, %d SE (133, 30)" % [
				broke_at["tick"], armor.health])
			await t.run_ticks(sim, 40)
			t.check(armor.health == 20, "na twee echo-treffers %d SE (20)" % armor.health)
			await t.run_ticks(sim, 30)
			t.check(armor.health == 10, "P1-treffer na het pantser: %d SE (10)" % armor.health)
		await t.cleanup()
	# Ketting: merk op het pantser (400) en op V2 (430); de echo laat V2 knallen.
	var a := await _arena(t, [400.0, 430.0], ENEMY, 1000)
	a["targets"][0].kind = ARMORED
	a["targets"][0].armor_intact = true
	a["targets"][0].health = 30
	await _mark(t, a, a["targets"][0])
	await _mark(t, a, a["targets"][1])
	var g := _ghost_attack(t, a, Vector2(490, Fx.STAND_Y))
	await t.run_ticks(a["sim"], 12)
	var to: int = g["t"] + 3
	t.check(a["log"]["exploded"] == [[to, 1, 1], [to + 1, 0, 2]], "ketting %s" % str(a["log"]["exploded"]))
	t.check(_damage_of(a["log"], 0) == [[to + 1, 0, 25, "ontploffing"]] and not a["targets"][0].armor_intact,
		"pantserdoel: %s (alleen 25 SE op t_o + 1)" % str(_damage_of(a["log"], 0)))


## (h) Een vijandelijke aanval raakt de plek van de echo: de echo gaat door
## en breekt niet; P1 verliest levenspunten.
func test_e14_h_echo_is_invulnerable(t) -> void:
	var sim = Fx.world(t)
	Fx.target(sim, ENEMY, 236.0, true)
	var p1 := Fx.p1(sim, [[400, 0]])
	var echo := Fx.tail_echo(sim, p1, 90)
	var broke: Array = []
	echo.broke.connect(func(tick: int, _at: Vector2) -> void: broke.append(tick))
	await t.run_ticks(sim, 260)
	t.check(p1.health <= 3, "de vijand raakte P1 niet vaak genoeg: %d levenspunten" % p1.health)
	t.check(broke.is_empty() and echo.is_present(), "de echo brak door een vijandelijke aanval")


# --- E-02m ---------------------------------------------------------------

## (1) (alle D) P1 slaat een stilstaande vijand op x: op x + D + 3 staat de
## echo op het merk, de vijand krijgt dan 20 SE en niet eerder; op x + D + 11
## staat de echo weer op zijn opname.
func test_e02m_1_jump_and_return_all_d(t) -> void:
	for d: int in ALL_D:
		var sim = Fx.world(t)
		var enemy := Fx.target(sim, ENEMY, 220.0)
		var p1 := Fx.p1(sim, [[10, 0], [1, A], [400, 0]])
		var echo := Fx.tail_echo(sim, p1, d)
		var trace := Fx.trace(sim, [echo, p1])
		var damage: Array = []
		enemy.damaged.connect(func(tick: int, amount: int, _s: String) -> void: damage.append([tick, amount]))
		await t.run_ticks(sim, d + 30)
		var x := 10
		t.check(trace[0][x + d + 3] == enemy.global_position, "D = %d: echo op x + D + 3 op %s, merk %s" % [
			d, trace[0][x + d + 3], enemy.global_position])
		t.check(damage == [[x, 10], [x + d + 3, 20]], "D = %d: schade %s" % [d, str(damage)])
		t.check(trace[0][x + d + 11] == trace[1][x + 11] and trace[0][x + d + 10] != trace[1][x + 10],
			"D = %d: niet precies op x + D + 11 terug op de opname" % d)
		await t.cleanup()


## (2) Merk op 79 px: merksprong; op 81 px: geen.
func test_e02m_2_radius(t) -> void:
	for distance in [79.0, 81.0]:
		var a := await _arena(t, [400.0])
		await _mark(t, a, a["targets"][0])
		# Echo op vloerhoogte (y 385), doel op 388: horizontaal zo dat de afstand klopt.
		var dy := Fx.TARGET_Y - Fx.STAND_Y
		var q := _center(a["targets"][0]) - Vector2(sqrt(distance * distance - dy * dy), dy)
		var g := _ghost_attack(t, a, q)
		await t.run_ticks(a["sim"], 10)
		var jumped: bool = g["pos"][g["t"] + 3] == _center(a["targets"][0])
		t.check(jumped == (distance < 80.0) and (g["jumps"].size() == 1) == jumped,
			"%.0f px: merksprong = %s" % [distance, jumped])
		await t.cleanup()


## (3) Het dichtstbijzijnde merk wint; bij gelijke afstand het oudste.
func test_e02m_3_nearest_then_oldest(t) -> void:
	for q_x in [440.0, 452.0]:
		var a := await _arena(t, [400.0, 480.0])
		await _mark(t, a, a["targets"][0])
		await _mark(t, a, a["targets"][1])
		var g := _ghost_attack(t, a, Vector2(q_x, Fx.STAND_Y))
		await t.run_ticks(a["sim"], 10)
		var expected: CombatTarget = a["targets"][0] if q_x == 440.0 else a["targets"][1]
		t.check(g["pos"][g["t"] + 3] == _center(expected),
			"echo op %.0f: doel %s, verwacht %s" % [q_x, g["pos"][g["t"] + 3], _center(expected)])
		await t.cleanup()


## (4) Zichtlijn: een muur op laag 1 of 5 houdt de merksprong tegen, licht-
## geometrie (laag 4) niet.
func test_e02m_4_line_of_sight(t) -> void:
	for layer in [Layers.WORLD, Layers.SHADOW_GEOMETRY, Layers.LIGHT_GEOMETRY]:
		var a := await _arena(t, [400.0])
		await _mark(t, a, a["targets"][0])
		Fx.block(t, "Wall", Rect2(360, 300, 4, 100), layer)
		var g := _ghost_attack(t, a, Vector2(340, Fx.STAND_Y))
		await t.run_ticks(a["sim"], 10)
		var expected: bool = layer == Layers.LIGHT_GEOMETRY
		t.check((g["jumps"].size() == 1) == expected, "muur op laag %d: merksprong %s" % [layer, str(g["jumps"])])
		await t.cleanup()


## (5) Tijdens de merksprong is de plank uit: P1 valt door de echo.
func test_e02m_5_plank_off_during_jump(t) -> void:
	for with_mark in [true, false]:
		var a := await _arena(t, [400.0])
		if with_mark:
			await _mark(t, a, a["targets"][0])
		var q := Vector2(340, Fx.STAND_Y)
		var g := _ghost_attack(t, a, q)
		await t.run_ticks(a["sim"], 4)
		var p1: PlayerActor = a["p1"]
		# P1 net boven de plank (bovenkant echo = q.y − 15), valt vanaf tick t.
		p1.respawn_at(Vector2(q.x, q.y - 15.0 - 15.0 - 1.0))
		var on_plank := {"ticks": 0}
		a["sim"].tick_finished.connect(func(_tick: int) -> void:
			if p1.motor.support == Motor.Support.SHADOW_BODY:
				on_plank["ticks"] += 1)
		await t.run_ticks(a["sim"], 12)
		if with_mark:
			t.check(on_plank["ticks"] == 0 and p1.position.y > q.y - 25.0,
				"P1 landde tijdens de merksprong op de echo: %s" % p1.position)
		else:
			t.check(on_plank["ticks"] > 5, "zonder merksprong landde P1 niet op de echo")
		await t.cleanup()


## (6) Het merk ligt in fel licht: de echo breekt op de tick waarop zijn
## middelpunt erin komt (t + 2), geen ontploffing.
func test_e02m_6_fel_licht_breaks_during_jump(t) -> void:
	var a := await _arena(t, [400.0])
	await _mark(t, a, a["targets"][0])
	Fx.zone(t, Zone.Kind.FEL_LICHT, Rect2(380, 360, 40, 40))
	var g := _ghost_attack(t, a, Vector2(340, Fx.STAND_Y))
	await t.run_ticks(a["sim"], 12)
	t.check(g["broke"].size() >= 1 and g["broke"][0] == g["t"] + 2 and g["echo"].valid_from >= g["t"] + 2,
		"breuk %s (verwacht t + 2 = %d)" % [str(g["broke"]), g["t"] + 2])
	t.check(a["log"]["exploded"].is_empty(), "toch een ontploffing")


## (7) De doelvijand sterft op t + 1: geen ontploffing, de echo staat op
## t + 9 weer op zijn opname.
func test_e02m_7_target_dies_during_jump(t) -> void:
	var a := await _arena(t, [400.0])
	await _mark(t, a, a["targets"][0])
	var q := Vector2(340, Fx.STAND_Y)
	var g := _ghost_attack(t, a, q)
	await t.run_ticks(a["sim"], 7)
	a["targets"][0].apply_damage(g["t"] + 1, 1000, "test")
	await t.run_ticks(a["sim"], 10)
	t.check(a["log"]["exploded"].is_empty(), "ontploffing op een dode vijand")
	t.check(g["pos"][g["t"] + 9] == q and g["pos"][g["t"] + 8] != q,
		"echo op t + 8 %s, t + 9 %s (pas op t + 9 terug op %s)" % [g["pos"][g["t"] + 8], g["pos"][g["t"] + 9], q])


## (8) AANVAL zonder merk binnen R, trefpop in het vlak: gewone echo-treffer,
## de echo verlaat zijn opname niet.
func test_e02m_8_plain_hit_without_mark(t) -> void:
	var a := await _arena(t, [360.0], DUMMY)
	var q := Vector2(340, Fx.STAND_Y)
	var g := _ghost_attack(t, a, q)
	await t.run_ticks(a["sim"], 20)
	var off := 0
	for tick in range(g["t"], g["t"] + 13):
		off += 0 if g["pos"][tick] == q else 1
	t.check(off == 0 and a["targets"][0].damage_taken == 5, "%d ticks van de opname, trefpop %d SE (0, 5)" % [
		off, a["targets"][0].damage_taken])


## (9) Het pad loopt tijdens de merksprong 3 ticks door een schaduwmuur: geen
## breuk; daarna nog 3 ticks: breuk op de 3e.
func test_e02m_9_path_checks_paused_during_jump(t) -> void:
	var a := await _arena(t, [370.0])
	await _mark(t, a, a["targets"][0])
	Fx.block(t, "ShadowWall", Rect2(290, 300, 20, 100), Layers.SHADOW_GEOMETRY)
	var q := Vector2(340, Fx.STAND_Y)
	var wall := Vector2(300, Fx.STAND_Y)
	var g := _ghost_attack(t, a, q, func(k: int) -> Vector2:
		return wall if k in [4, 5, 6, 16, 17, 18] else q)
	await t.run_ticks(a["sim"], 25)
	t.check(g["jumps"] == [g["t"]], "geen merksprong: %s" % str(g["jumps"]))
	t.check(g["broke"].size() >= 1 and g["broke"][0] == g["t"] + 14,
		"breuk %s (alleen na de merksprong, op t + 14 = %d)" % [str(g["broke"]), g["t"] + 14])


## (10) (alle D) Lopende basisvijand: P1 slaat met het verste deel van zijn
## vlak, springt over hem heen en loopt weg; de vijand loopt na 30 ticks mee.
## Op x + D ligt het merk binnen 36 + 0,25 × (D − 30) px: merksprong, en op
## x + D + 3 krijgt de vijand 20 SE.
func test_e02m_10_walking_enemy_all_d(t) -> void:
	for d: int in ALL_D:
		var sim = Fx.world(t)
		var enemy := Fx.target(sim, ENEMY, 235.0, true)
		var p1 := Fx.p1(sim, [[10, 0], [1, A], [5, 0], [1, R | J], [400, R]])
		var echo := Fx.tail_echo(sim, p1, d)
		var gap := {"at": -1.0}
		var jumps: Array = []
		echo.merksprong_started.connect(func(tick: int, _id: int) -> void:
			jumps.append(tick)
			gap["at"] = echo.recorded_position.distance_to(enemy.global_position))
		var damage: Array = []
		enemy.damaged.connect(func(tick: int, amount: int, _s: String) -> void: damage.append([tick, amount]))
		await t.run_ticks(sim, d + 20)
		var limit := 36.0 + 0.25 * (d - 30) + 3.0
		t.check(jumps == [10 + d] and gap["at"] <= limit and gap["at"] > 36.0,
			"D = %d: merksprong %s op %.1f px (≤ %.1f)" % [d, str(jumps), gap["at"], limit])
		t.check(damage.size() == 2 and damage[1] == [10 + d + 3, 20], "D = %d: schade %s" % [d, str(damage)])
		await t.cleanup()


# --- C-12 (alleen waar het het merk raakt) --------------------------------

## Co-op: het andere lichaam laat het merk knallen in plaats van 10 SE; de
## zetter op zijn eigen merk doet 10 SE.
func test_c12_other_body_detonates(t) -> void:
	var a := await _arena(t, [400.0, 500.0, 600.0], ENEMY, 1000)
	var p2 := Fx.manual_player(a["sim"], 2, Vector2(100, Fx.STAND_Y))
	await t.run_ticks(a["sim"], 2)
	await _mark(t, a, a["targets"][0])              # P1 merkt V1
	await _mark(t, a, a["targets"][0])              # P1 opnieuw: 10 SE, merk blijft
	await _mark(t, a, a["targets"][0], p2)          # P2 laat V1 knallen
	await _mark(t, a, a["targets"][1], p2)          # P2 merkt V2
	await _mark(t, a, a["targets"][1])              # P1 laat V2 knallen
	await _mark(t, a, a["targets"][2], p2)          # P2 merkt V3
	await _mark(t, a, a["targets"][2], p2)          # P2 opnieuw: 10 SE
	var log: Dictionary = a["log"]
	var amounts := func(i: int) -> Array: return _damage_of(log, i).map(func(r: Array) -> int: return r[2])
	t.check(amounts.call(0) == [10, 10, 20], "V1: %s (10, 10, 20)" % str(amounts.call(0)))
	t.check(amounts.call(1) == [10, 20], "V2: %s (10, 20)" % str(amounts.call(1)))
	t.check(amounts.call(2) == [10, 10] and log["exploded"].size() == 2,
		"V3: %s, ontploffingen %d (10, 10; 2)" % [str(amounts.call(2)), log["exploded"].size()])
	t.check(log["set"].map(func(r: Array) -> String: return r[2]) == ["p1", "p2", "p2"],
		"zetters %s" % str(log["set"]))


## C-11e (raakt de merksprong): staat P1 op de plank van zijn echo op de
## tick van een AANVAL van de echo, dan een gewone echo-treffer (5 SE) en
## geen merksprong. P1 slaat op 10, springt op 90 op zijn echo (D = 120).
func test_c11e_no_merksprong_with_p1_on_plank(t) -> void:
	var sim = Fx.world(t)
	var enemy := Fx.target(sim, ENEMY, 220.0)
	var p1 := Fx.p1(sim, [[10, 0], [1, A], [79, 0], [1, J], [200, 0]])
	var echo := Fx.tail_echo(sim, p1, 120)
	var jumps: Array = []
	echo.merksprong_started.connect(func(tick: int, _id: int) -> void: jumps.append(tick))
	var on_plank := {"at_130": false}
	sim.tick_finished.connect(func(tick: int) -> void:
		if tick == 129:
			on_plank["at_130"] = p1.motor.support == Motor.Support.SHADOW_BODY)
	var damage: Array = []
	enemy.damaged.connect(func(tick: int, amount: int, _s: String) -> void: damage.append([tick, amount]))
	await t.run_ticks(sim, 140)
	t.check(on_plank["at_130"], "P1 stond aan het eind van tick 129 niet op de echo")
	t.check(jumps.is_empty() and damage == [[10, 10], [130, 5]],
		"merksprong %s, schade %s (gewone echo-treffer op 130)" % [str(jumps), str(damage)])


## E-02m: een INTERACTIE in een frame tijdens de merksprong werkt op de
## opgenomen positie. Op t + 2 staat de echo uitgerekt op x = 385, zijn
## opname op 340: de hendel op de opname gaat om, die op de echte plek niet.
func test_e02m_interaction_on_recorded_position(t) -> void:
	var a := await _arena(t, [400.0])
	await _mark(t, a, a["targets"][0])
	var sim: Node = a["sim"]
	var levers: Array = []
	for x in [340.0, 385.0]:
		var lever := Lever.new()
		lever.setup(Layers.SHADOW, Vector2(40, 40))
		lever.position = Vector2(x, Fx.STAND_Y)
		sim.add_object(lever)
		levers.append(lever)
	var ghost := Fx.ghost(t)
	var start: int = sim.tick
	var q := Vector2(340, Fx.STAND_Y)
	for k in 100:
		var events := GameEvents.ATTACK if k == 4 else (GameEvents.INTERACT if k == 6 else 0)
		Fx.ghost_frame(ghost, start + k, q, false, Motor.Support.NONE, events)
	var echo := Fx.tail_echo(sim, ghost, 1)
	var trace := Fx.trace(sim, [echo])
	await t.run_ticks(sim, 12)
	var t0 := start + 5
	t.check(trace[0][t0 + 2].x == 385.0, "echo op t + 2 op %s (x = 385)" % trace[0][t0 + 2])
	t.check(levers[0].on and not levers[1].on,
		"hendel op de opname %s, op de echte plek %s (aan, uit)" % [levers[0].on, levers[1].on])
