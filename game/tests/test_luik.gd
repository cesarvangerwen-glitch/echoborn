extends RefCounted
## Tests voor het luik en de schaduwklep (gdd V-01d, aanvulling LGD in #227,
## voorstel A). Een losse wereld: een vloer op 400 met een gat van 40 px op
## x 180–220 waarin het luik ligt, en 200 px lager een benedenvloer. P1 staat
## op het luik (handmatige input), springt en doet een neerslag op de klep.
##
## - Solo met de echo Actief (alle D): de klep gaat op de breuk `b` van laag 1
##   naar laag 5 en P1 valt erdoor. De neerslag is een AANVAL in de lucht
##   (V-01a), dus P1 zette al vóór `b` af van de klep (op `s`). De echo staat
##   tot zijn sprong (`s + D`) op de schaduwklep en breekt niet; hij speelt de
##   neerslag af op `b + D` (de schaduwklep is dan weg, door de echo) en valt
##   achter P1 aan; de echo breekt nooit.
## - Echo uit: geen schaduwklep, het luik breekt in één keer.
## - Echo aan maar Leeg op de breuk (bij het begin, of na een respawn op het
##   luik): wel een schaduwklep (besluit LGD, #232); de echo staat erop, haalt
##   hem weg met zijn neerslag op `breuk + D` en breekt 0×.
## - De echo komt niet (Leeg na de breuk): de schaduwklep gaat weg op
##   `breuk + D + G`.
## - Co-op: geen schaduwklep (P2 botst met laag 5); P2 valt mee door het gat.
## - Alleen een neerslag opent het luik, ook niet een gewone AANVAL van boven.

const Fx = preload("res://tests/echo_fixture.gd")
const InputBits = preload("res://scripts/input/input_bits.gd")
const PlayerActor = preload("res://scripts/echo/player_actor.gd")
const TailEcho = preload("res://scripts/echo/tail_echo.gd")
const Layers = preload("res://scripts/world/layers.gd")
const SpikeWorld = preload("res://scripts/world/spike_world.gd")
const Luik = preload("res://scripts/objects/luik.gd")
const Tuning = preload("res://scripts/echo/tuning.gd")

const ALL_D := [60, 90, 120, 180]
const FLOOR := 400.0
const LOW := 600.0
const LUIK_X := 200.0
## Startplek van P1 met echo: links van het luik.
const START_X := 120.0
const MAX_FRAMES := {"test_schaduwklep_echo_valt_mee_alle_d": 2400, "test_luik_respawn_op_luik_echo_breekt_niet": 2400}


## Wereld met het gat en het luik; geeft [sim, luik].
func _world(t) -> Array:
	var sim = t.make_sim(false)
	var root: Node2D = t.world_root()
	SpikeWorld.add_block(root, "Links", Vector2(-410, FLOOR + 8), Vector2(1180, 16))
	SpikeWorld.add_block(root, "Rechts", Vector2(1110, FLOOR + 8), Vector2(1780, 16))
	SpikeWorld.add_block(root, "Laag", Vector2(1000, LOW + 20), Vector2(4000, 40))
	var luik := Luik.new()
	luik.name = "Luik"
	luik.position = Vector2(LUIK_X, FLOOR + 4.0)
	root.add_child(luik)
	sim.add_object(luik)
	return [sim, luik]


## P1 loopt van links op het luik, springt er meteen weer van af (hij stond
## er dus op, net als de echo straks) en doet een neerslag zolang zijn voeten
## nog ≤ 12 px boven de klep zijn. Geeft de tick van de neerslag, of -1. Zo is
## P1 door het luik vóór de echo er aankomt, en landt hij niet op de plank van
## zijn eigen echo.
func _jump_and_neerslag(t, sim, p1: PlayerActor, walk_to := LUIK_X - 6.0) -> int:
	var input: Fx.ManualInput = p1.input_source
	if p1.position.x < walk_to:
		input.bits = InputBits.RIGHT
		for i in 120:
			if p1.position.x >= walk_to:
				break
			await t.run_ticks(sim, 1)
	input.bits = InputBits.JUMP
	await t.run_ticks(sim, 1)
	for i in 90:
		var feet := p1.position.y + 15.0
		if not p1.motor.on_floor and FLOOR - feet <= 12.0:
			input.bits = InputBits.ATTACK | InputBits.DOWN
			var at: int = sim.tick
			await t.run_ticks(sim, 1)
			input.bits = 0
			return at
		await t.run_ticks(sim, 1)
	return -1


func _free(t) -> void:
	await t.cleanup()


func test_schaduwklep_echo_valt_mee_alle_d(t) -> void:
	var g := int(Tuning.echo()["break_tolerance_ticks"])
	for d: int in ALL_D:
		var w := _world(t)
		var sim = w[0]
		var luik: Luik = w[1]
		var p1 := Fx.manual_player(sim, 1, Vector2(START_X, FLOOR - 15.0))
		var echo := Fx.tail_echo(sim, p1, d)
		var breaks := {"n": 0}
		echo.broke.connect(func(_tick: int, _at: Vector2) -> void: breaks["n"] += 1)
		var weg := {"tick": -1, "by": ""}
		luik.schaduwklep_weg.connect(func(tick: int, by: String) -> void:
			weg["tick"] = tick
			weg["by"] = by)
		# Per tick (na stap 5): staat P1 op de vloer, en waar staat de echo?
		var p1_floor := {}
		var echo_at := {}
		sim.tick_finished.connect(func(tick: int) -> void:
			p1_floor[tick] = p1.motor.on_floor
			echo_at[tick] = echo.position if echo.is_present() else Vector2.INF)
		# Wachten tot de echo Actief is (D ticks), dan naar het luik.
		await t.run_ticks(sim, d + 20)
		t.check(echo.is_present() and not luik.is_open, "D=%d: echo niet Actief vóór de sprong (open %s)" % [d, luik.is_open])
		var hit := await _jump_and_neerslag(t, sim, p1)
		var label := "D=%d" % d
		t.check(hit > 0 and luik.is_open and luik.opened_by == "p1" and luik.opened_tick == hit,
			"%s: het luik ging niet open door de neerslag van P1 (tick %d, open %s door %s)" % [label, hit, luik.is_open, luik.opened_by])
		t.check(luik.schaduwklep and luik.klep().collision_layer == Layers.SHADOW_GEOMETRY,
			"%s: geen schaduwklep op laag 5 na de breuk (laag %d)" % [label, luik.klep().collision_layer])
		t.check(luik.schaduwklep_tot == hit + d + g, "%s: schaduwklep tot %d (breuk + D + G = %d)" % [label, luik.schaduwklep_tot, hit + d + g])
		# `s`: de afzet van P1 van de klep (de eerste tick in de lucht vóór de breuk).
		var s := -1
		for k in range(hit, hit - 30, -1):
			if p1_floor.get(k, true) and k < hit:
				s = k + 1
				break
		t.check(s > 0 and s <= hit, "%s: geen afzet van P1 vóór de breuk %d (s %d)" % [label, hit, s])
		# P1 ziet laag 5 niet: zijn neerslag raakt de schaduwklep niet, de echo wel.
		var box: Rect2 = sim.combat.neerslag_box(Vector2(LUIK_X, FLOOR - 25.0))
		t.check(not luik.is_hit_by(box, Layers.LIGHT) and luik.is_hit_by(box, Layers.SHADOW),
			"%s: de schaduwklep is raakbaar voor P1 of niet voor de echo" % label)
		# P1 valt erdoor naar de benedenvloer.
		await t.run_ticks(sim, 50)
		t.check(p1.position.y > FLOOR + 30.0, "%s: P1 viel niet door het luik (P1 %s)" % [label, p1.position])
		t.check(luik.schaduwklep, "%s: de schaduwklep ging te vroeg weg (tick %d, %s)" % [label, weg["tick"], weg["by"]])
		# De echo staat tot zijn sprong (s + D) op de klep, vanaf de breuk dus op
		# de schaduwklep, en zet op s + D af.
		await t.run_ticks(sim, s + d + 1 - sim.tick)
		var stand := FLOOR - 15.0
		var off := []
		for k in range(hit, s + d):
			var at: Vector2 = echo_at.get(k, Vector2.INF)
			if at == Vector2.INF or absf(at.y - stand) > 0.5:
				off.append([k, at])
		t.check(s + d - 1 >= hit and off.is_empty(), "%s: de echo stond niet op de schaduwklep van de breuk %d tot s + D − 1 = %d (%s)" % [label, hit, s + d - 1, off])
		var jump_at: Vector2 = echo_at.get(s + d, Vector2.INF)
		t.check(jump_at != Vector2.INF and jump_at.y < stand - 0.5, "%s: de echo zette niet af op s + D = %d (echo %s)" % [label, s + d, jump_at])
		# De echo speelt de neerslag af: de schaduwklep is weg op breuk + D, door de echo.
		await t.run_ticks(sim, hit + d + 1 - sim.tick)
		t.check(weg["tick"] == hit + d and weg["by"] == "echo" and not luik.schaduwklep and luik.klep().collision_layer == 0,
			"%s: schaduwklep weg op %d door %s (verwacht %d door de echo; laag %d)" % [label, weg["tick"], weg["by"], hit + d, luik.klep().collision_layer])
		# En de echo valt achter P1 aan, zonder te breken.
		await t.run_ticks(sim, 60)
		t.check(echo.is_present() and echo.position.y > FLOOR + 30.0, "%s: de echo viel niet door het luik (echo %s, Actief %s)" % [label, echo.position, echo.is_present()])
		t.check(breaks["n"] == 0, "%s: de echo brak %d× op het luik" % [label, breaks["n"]])
		await _free(t)


## Echo uit (geen staart-echo): geen schaduwklep, het luik breekt in één keer.
func test_luik_echo_uit_geen_schaduwklep(t) -> void:
	var w := _world(t)
	var sim = w[0]
	var luik: Luik = w[1]
	var p1 := Fx.manual_player(sim, 1, Vector2(LUIK_X, FLOOR - 15.0))
	await t.run_ticks(sim, 10)
	var hit := await _jump_and_neerslag(t, sim, p1)
	t.check(hit > 0 and luik.is_open and not luik.schaduwklep and luik.klep().collision_layer == 0,
		"echo uit: open %s, schaduwklep %s, laag %d (verwacht open, geen schaduwklep, laag 0)" % [luik.is_open, luik.schaduwklep, luik.klep().collision_layer])
	await _free(t)


## Volgt de breuk binnen D ticks op `valid_from` (de echo is Leeg op de
## breuktick), dan komt er toch een schaduwklep (besluit LGD, #232): de echo
## speelt daarna de frames van P1 op de klep af, staat op de schaduwklep en
## haalt hem weg met zijn neerslag op `breuk + D` (uiterlijk `breuk + D + G`).
## De echo breekt 0×.
func _lege_echo_breuk(t, sim, luik: Luik, p1: PlayerActor, echo: TailEcho, label: String) -> void:
	var d: int = echo.tail_ticks
	var g := int(Tuning.echo()["break_tolerance_ticks"])
	var breaks := {"n": 0}
	echo.broke.connect(func(_tick: int, _at: Vector2) -> void: breaks["n"] += 1)
	var weg := {"tick": -1, "by": ""}
	luik.schaduwklep_weg.connect(func(tick: int, by: String) -> void:
		weg["tick"] = tick
		weg["by"] = by)
	await t.run_ticks(sim, 10)
	var hit := await _jump_and_neerslag(t, sim, p1, -INF)
	t.check(not echo.is_present(), "%s: de echo was al Actief op de breuk" % label)
	t.check(hit > 0 and luik.schaduwklep and luik.klep().collision_layer == Layers.SHADOW_GEOMETRY and luik.schaduwklep_tot == hit + d + g,
		"%s: geen schaduwklep tot breuk + D + G na de breuk (tick %d, schaduwklep %s, laag %d, tot %d)" % [label, hit, luik.schaduwklep, luik.klep().collision_layer, luik.schaduwklep_tot])
	await t.run_ticks(sim, hit + d + g + 60 - sim.tick)
	t.check(weg["tick"] == hit + d and weg["by"] == "echo", "%s: schaduwklep weg op %d door %s (verwacht %d door de echo)" % [label, weg["tick"], weg["by"], hit + d])
	t.check(breaks["n"] == 0 and echo.is_present() and echo.position.y > FLOOR + 30.0,
		"%s: de echo brak %d× of viel niet door het luik (echo %s)" % [label, breaks["n"], echo.position])


## Lege echo: de echo begint op het luik (Leeg, D ticks) en P1 breekt het luik
## vóór de echo Actief is.
func test_luik_lege_echo_wel_schaduwklep(t) -> void:
	for d: int in [60, 180]:
		var w := _world(t)
		var p1 := Fx.manual_player(w[0], 1, Vector2(LUIK_X, FLOOR - 15.0))
		var echo := Fx.tail_echo(w[0], p1, d)
		await _lege_echo_breuk(t, w[0], w[1], p1, echo, "D=%d Lege echo" % d)
		await _free(t)


## Respawn op het luik (de echo is weer Leeg, E-04b), breuk binnen D ticks:
## de echo breekt niet.
func test_luik_respawn_op_luik_echo_breekt_niet(t) -> void:
	for d: int in [60, 180]:
		var w := _world(t)
		var sim = w[0]
		var p1 := Fx.manual_player(sim, 1, Vector2(START_X, FLOOR - 15.0))
		var echo := Fx.tail_echo(sim, p1, d)
		await t.run_ticks(sim, d + 20)
		t.check(echo.is_present(), "D=%d: echo niet Actief vóór de respawn" % d)
		p1.respawn_at(Vector2(LUIK_X, FLOOR - 15.0))
		await t.run_ticks(sim, 2)
		t.check(absf(p1.position.x - LUIK_X) < 0.5 and echo.valid_from >= sim.tick - 2, "D=%d: geen respawn op het luik (P1 %s)" % [d, p1.position])
		await _lege_echo_breuk(t, sim, w[1], p1, echo, "D=%d respawn op het luik" % d)
		await _free(t)


## De echo komt niet (Leeg gemaakt na de breuk): de schaduwklep gaat op
## `breuk + D + G` weg, in stap (5).
func test_schaduwklep_weg_na_d_plus_g(t) -> void:
	var d := 60
	var g := int(Tuning.echo()["break_tolerance_ticks"])
	var w := _world(t)
	var sim = w[0]
	var luik: Luik = w[1]
	var p1 := Fx.manual_player(sim, 1, Vector2(START_X, FLOOR - 15.0))
	var echo := Fx.tail_echo(sim, p1, d)
	var weg := {"tick": -1, "by": ""}
	luik.schaduwklep_weg.connect(func(tick: int, by: String) -> void:
		weg["tick"] = tick
		weg["by"] = by)
	await t.run_ticks(sim, d + 20)
	var hit := await _jump_and_neerslag(t, sim, p1)
	t.check(hit > 0 and luik.schaduwklep, "geen schaduwklep na de breuk (tick %d)" % hit)
	echo.reset(sim.tick)
	await t.run_ticks(sim, hit + d + g - 1 - sim.tick)
	t.check(luik.schaduwklep, "schaduwklep weg vóór breuk + D + G (tick %d)" % sim.tick)
	await t.run_ticks(sim, 2)
	t.check(weg["tick"] == hit + d + g and weg["by"] == "tijd" and luik.klep().collision_layer == 0,
		"schaduwklep weg op %d door %s (verwacht %d door de tijd)" % [weg["tick"], weg["by"], hit + d + g])
	await _free(t)


## Co-op: geen schaduwklep; P1 breekt het luik in één keer en P2, die naast
## hem op het luik staat, valt mee (P2 botst met laag 5, dus een schaduwklep
## zou hem dragen).
func test_luik_coop_geen_schaduwklep(t) -> void:
	var w := _world(t)
	var sim = w[0]
	var luik: Luik = w[1]
	var p1 := Fx.manual_player(sim, 1, Vector2(LUIK_X - 10.0, FLOOR - 15.0))
	var p2 := Fx.manual_player(sim, 2, Vector2(LUIK_X + 8.0, FLOOR - 15.0))
	await t.run_ticks(sim, 70)
	t.check(sim.is_coop() and sim.echoes.is_empty(), "geen co-op of toch een echo")
	var hit := await _jump_and_neerslag(t, sim, p1, -INF)
	t.check(hit > 0 and luik.is_open and not luik.schaduwklep and luik.klep().collision_layer == 0,
		"co-op: open %s, schaduwklep %s, laag %d (verwacht geen schaduwklep)" % [luik.is_open, luik.schaduwklep, luik.klep().collision_layer])
	await t.run_ticks(sim, 40)
	t.check(p2.position.y > FLOOR + 30.0 and not p2.dissolved, "co-op: P2 viel niet door het luik (P2 %s, opgelost %s, vloer %s, v %s)" % [p2.position, p2.dissolved, p2.motor.on_floor, p2.motor.velocity])
	await _free(t)


## Alleen een neerslag: een gewone AANVAL van P1 die op het luik staat of
## erboven springt, opent het niet.
func test_luik_alleen_neerslag(t) -> void:
	var w := _world(t)
	var sim = w[0]
	var luik: Luik = w[1]
	var p1 := Fx.manual_player(sim, 1, Vector2(LUIK_X, FLOOR - 15.0))
	var input: Fx.ManualInput = p1.input_source
	for i in 4:
		input.bits = InputBits.ATTACK
		await t.run_ticks(sim, 1)
		input.bits = 0
		await t.run_ticks(sim, 20)
	input.bits = InputBits.JUMP
	await t.run_ticks(sim, 4)
	input.bits = InputBits.ATTACK
	await t.run_ticks(sim, 1)
	input.bits = 0
	await t.run_ticks(sim, 60)
	t.check(not luik.is_open and absf(p1.position.y - (FLOOR - 15.0)) < 1.5,
		"het luik ging open zonder neerslag (open %s, P1 %s)" % [luik.is_open, p1.position])
	await _free(t)
