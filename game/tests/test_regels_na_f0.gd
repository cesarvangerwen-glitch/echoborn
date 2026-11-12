extends RefCounted
## Tests voor de regels en het placeholder-beeld na F0 (T16e, #177; gdd v0.7.3
## §4.7.4 G-1–G-5, §4.6): LM-03, LM-04, LM-06 (pompgang en sluis), L-13
## (start van golf 2 in K2), E-07d (plank-signaal), E-02t (doelstreep), E-14j
## (bereikcirkel en kettinglijn) en de D op het scorescherm (G-5). Sinds T16g
## (#188, gdd v0.8 §4.8.4 G-6) ook: de standaard-D 60 uit data, het debugmenu
## 60 / 90 / 120 / 180 en het B3-blok `max(D − 60, 0)`.
##
## De pompgang staat hier in een eigen testwereld (vier schoepen, 80 px uit
## elkaar, sluis 280 px verder): de geometrie van K3 is van de World & Level
## Designer (W-4), en de LM-04-test met de gescripte run door K3 hoort bij
## W-4/W-5. Gevallen met "(alle D)" gebruiken de echte echo van P1 voor
## D = 60, 120 en 180 (en 90 als regressie).

const Fx = preload("res://tests/echo_fixture.gd")
const InputBits = preload("res://scripts/input/input_bits.gd")
const PlayerActor = preload("res://scripts/echo/player_actor.gd")
const TailEcho = preload("res://scripts/echo/tail_echo.gd")
const Motor = preload("res://scripts/echo/motor.gd")
const CombatTarget = preload("res://scripts/combat/combat_target.gd")
const GameEvents = preload("res://scripts/events/game_events.gd")
const Layers = preload("res://scripts/world/layers.gd")
const LightMeter = preload("res://scripts/light/light_meter.gd")
const Gemaal = preload("res://scripts/light/gemaal.gd")
const Pomprad = preload("res://scripts/light/pomprad.gd")
const EchoHints = preload("res://scripts/echo/echo_hints.gd")
const FlowRoom = preload("res://levels/flowkamer/flow_room.gd")
const Layout = preload("res://levels/flowkamer/flow_layout.gd")
const Tuning = preload("res://scripts/echo/tuning.gd")
const Combat = preload("res://scripts/combat/combat.gd")

const L := InputBits.LEFT
const R := InputBits.RIGHT
const J := InputBits.JUMP
const A := InputBits.ATTACK
## "(alle D)" (gdd v0.8 §4.6, G-8): D = 60, 120 en 180; D = 90 draait mee als
## regressie (tot v0.8 was "(alle D)" 90 / 120 / 180).
const ALL_D := [60, 120, 180, 90]
const ENEMY := CombatTarget.Kind.ENEMY

## Pompgang (FK-5): vier schoepen, 80 px uit elkaar; de sluis 280 px na de
## laatste. Middelpunt `VANE_UP` boven de vloer (15–40 px).
const VANE_FIRST_X := 400.0
const VANE_STEP := 80.0
const VANE_UP := 30.0
const SLUICE_GAP := 280.0
## Straat met `Diepwater` (LM-06), ná de sluis: x 1500–1800, waterlijn hoog
## 370 (P1 staat met zijn middelpunt op 385: nat), laag 395 (droog).
const STREET := Rect2(1500, 360, 300, 40)
const WATER_HIGH := 370.0
const WATER_LOW := 395.0


# --- hulpmiddelen ----------------------------------------------------------

## Wereld met P1 (handmatige input), een meter met `light` LP, een gemaal met
## `n` schoepen op een rij, een sluis en een straat met water.
func _pompgang(t, light: int, d: int = 0, n: int = 4, up: float = VANE_UP) -> Dictionary:
	var sim = Fx.world(t)
	var p1 := Fx.manual_player(sim, 1, Vector2(200, Fx.STAND_Y))
	var echo: TailEcho = Fx.tail_echo(sim, p1, d) if d > 0 else null
	var meter := LightMeter.new(sim, p1)
	meter.value = light
	var vanes: Array = []
	for i in n:
		var vane := Pomprad.new()
		vane.setup_pomprad()
		vane.name = "Pompschoep%d" % (i + 1)
		vane.position = Vector2(VANE_FIRST_X + i * VANE_STEP, Fx.FLOOR_TOP - up)
		sim.add_object(vane)
		vanes.append(vane)
	var sluice_x: float = VANE_FIRST_X + (n - 1) * VANE_STEP + SLUICE_GAP
	var sluice: StaticBody2D = Fx.block(t, "Sluis", Rect2(sluice_x, 200, 20, 200), Layers.WORLD)
	var gemaal := Gemaal.new()
	gemaal.setup_gemaal(meter, vanes, sluice, STREET, WATER_HIGH, WATER_LOW)
	gemaal.connect_combat(sim.combat)
	sim.add_object(gemaal)
	var pumps: Array = []
	gemaal.pumped.connect(func(tick: int, amount: int, who: String) -> void:
		pumps.append([tick, who, amount, vanes.find(gemaal.last_vane)]))
	var opened: Array = []
	gemaal.sluice_opened.connect(func(tick: int) -> void: opened.append(tick))
	return {"sim": sim, "p1": p1, "echo": echo, "meter": meter, "gemaal": gemaal, "vanes": vanes,
		"pumps": pumps, "opened": opened, "sluice": sluice, "sluice_x": sluice_x}


## Eén tick met deze knoppen voor P1.
func _step(t, sim, p1: PlayerActor, bits: int) -> void:
	p1.input_source.bits = bits
	await t.run_ticks(sim, 1)


## P1 loopt naar rechts door de pompgang en slaat elke schoep één keer, op
## 30 px ervoor (aanvalsvlak 8–28 px vóór het lichaam). Geeft de ticks van de
## slagen. Daarna loopt P1 door tot `until_x` (of `extra` ticks).
func _walk_and_pump(t, w: Dictionary, until_x: float, extra := 0) -> Array:
	var sim = w["sim"]
	var p1: PlayerActor = w["p1"]
	var hits: Array = []
	var next := 0
	var guard := 0
	while (p1.position.x < until_x or extra > 0) and guard < 2000:
		guard += 1
		if p1.position.x >= until_x:
			extra -= 1
		var bits := R
		if next < w["vanes"].size() and p1.position.x >= (w["vanes"][next] as Node2D).position.x - 32.0:
			bits |= A
			hits.append(sim.tick)
			next += 1
		await _step(t, sim, p1, bits)
	return hits


func _pumps_of(w: Dictionary, who: String) -> Array:
	return w["pumps"].filter(func(row: Array) -> bool: return row[1] == who)


# --- G-1: LM-03 en LM-04 ---------------------------------------------------

## LM-03 (alle D): `L = 100`, `G = 0`: P1 slaat de vier schoepen op `x`,
## `x + 40`, `x + 80`, `x + 120` → G = 60, L = 40; de echo slaat ze D ticks
## later: 15, 15, 10 → G = 100 op `x + 80 + D`, L = 0; zijn vierde slag
## pompt 0. Een schoep is niet `Merkbaar` en heeft een hurtbox van 32 × 48.
func test_lm03_pompgang_all_d(t) -> void:
	for d: int in ALL_D:
		var w := _pompgang(t, 100, d)
		var g: Gemaal = w["gemaal"]
		var hits := await _walk_and_pump(t, w, VANE_FIRST_X + 3 * VANE_STEP + 40.0)
		var x: int = hits[0] if hits.size() > 0 else -1
		t.check(hits == [x, x + 40, x + 80, x + 120], "D = %d: slagen van P1 op %s (verwacht x, x + 40, x + 80, x + 120)" % [d, hits])
		await _step(t, w["sim"], w["p1"], 0)
		await t.run_ticks(w["sim"], d + 140)
		var p1_rows := _pumps_of(w, "p1")
		var echo_rows := _pumps_of(w, "echo")
		t.check(p1_rows.map(func(r: Array) -> int: return r[2]) == [15, 15, 15, 15]
			and p1_rows.map(func(r: Array) -> int: return r[3]) == [0, 1, 2, 3],
			"D = %d: pompslagen P1 %s" % [d, p1_rows])
		t.check(echo_rows.map(func(r: Array) -> int: return r[2]) == [15, 15, 10, 0]
			and echo_rows.map(func(r: Array) -> int: return r[0]) == [x + d, x + 40 + d, x + 80 + d, x + 120 + d],
			"D = %d: pompslagen echo %s (verwacht 15, 15, 10, 0 op x + D …)" % [d, echo_rows])
		t.check(g.fill == 100 and w["meter"].value == 0 and g.full_tick == x + 80 + d,
			"D = %d: G = %d, L = %d, t_v = %d (verwacht 100, 0, %d)" % [d, g.fill, w["meter"].value, g.full_tick, x + 80 + d])
		var vane: CombatTarget = w["vanes"][0]
		t.check(not vane.is_markable() and w["sim"].combat.mark_on(vane) == null
			and (vane.shape as RectangleShape2D).size == Vector2(32, 48),
			"D = %d: schoep merkbaar of hurtbox %s" % [d, (vane.shape as RectangleShape2D).size])
		await t.cleanup()


## LM-03: `L = 30`: P1 pompt 15, 15, 0, 0 → G = 30; de echo pompt 0. `G = 95`,
## `L = 50`: een slag pompt 5. Een slag van P1 en van de echo op dezelfde
## schoep op dezelfde tick: allebei volgens de formule, eerst P1 (E-07b).
## Respawn: G gelijk.
func test_lm03_formula_and_order(t) -> void:
	var w := _pompgang(t, 30, 90)
	await _walk_and_pump(t, w, VANE_FIRST_X + 3 * VANE_STEP + 40.0)
	await t.run_ticks(w["sim"], 90 + 140)
	t.check(_pumps_of(w, "p1").map(func(r: Array) -> int: return r[2]) == [15, 15, 0, 0],
		"L = 30: P1 pompt %s (verwacht 15, 15, 0, 0)" % [_pumps_of(w, "p1")])
	t.check(_pumps_of(w, "echo").map(func(r: Array) -> int: return r[2]) == [0, 0, 0, 0] and w["gemaal"].fill == 30,
		"L = 30: echo pompt %s, G = %d (verwacht 0 en 30)" % [_pumps_of(w, "echo"), w["gemaal"].fill])
	await t.cleanup()
	# G = 95, L = 50: één slag pompt 5.
	w = _pompgang(t, 50, 0, 1)
	w["gemaal"].fill = 95
	await _walk_and_pump(t, w, VANE_FIRST_X)
	t.check(w["pumps"].size() == 1 and w["pumps"][0][2] == 5 and w["gemaal"].fill == 100 and w["meter"].value == 45,
		"G = 95, L = 50: %s, G = %d, L = %d" % [w["pumps"], w["gemaal"].fill, w["meter"].value])
	await t.cleanup()
	# Zelfde tick, zelfde schoep: P1 slaat op x en op x + D; de echo herhaalt x
	# op x + D. G = 80, L = 100: op x pompt P1 15 (G 95); op x + D P1 5, de echo 0.
	var d := 90
	w = _pompgang(t, 100, d, 1)
	var sim = w["sim"]
	var p1: PlayerActor = w["p1"]
	w["gemaal"].fill = 80
	p1.respawn_at(Vector2(VANE_FIRST_X - 30.0, Fx.STAND_Y))
	await t.run_ticks(sim, 1)
	w["echo"].reset(sim.tick)
	await t.run_ticks(sim, d + 5)
	var x: int = sim.tick
	await _step(t, sim, p1, A)
	await _step(t, sim, p1, 0)
	await t.run_ticks(sim, d - 2)
	await _step(t, sim, p1, A)
	await t.run_ticks(sim, 2)
	var rows: Array = w["pumps"].map(func(r: Array) -> Array: return [r[0], r[1], r[2]])
	t.check(rows == [[x, "p1", 15], [x + d, "p1", 5], [x + d, "echo", 0]],
		"zelfde tick: %s (verwacht P1 15 op x, dan op x + D eerst P1 5 en de echo 0)" % [rows])
	# Respawn: G blijft.
	p1.respawn_at(Vector2(200, Fx.STAND_Y))
	await t.run_ticks(sim, 2)
	t.check(w["gemaal"].fill == 100, "respawn veranderde G: %d" % w["gemaal"].fill)
	await t.cleanup()


## LM-04: AANVAL 60 ticks vasthouden bij een schoep: één slag. P1 slaat een
## schoep vanuit een sprong (op de top): de slag pompt (schoep 40 px boven de
## vloer, de bovengrens van FK-5).
func test_lm04_no_hold_and_jump_stroke(t) -> void:
	var w := _pompgang(t, 100, 0, 1)
	var sim = w["sim"]
	var p1: PlayerActor = w["p1"]
	p1.respawn_at(Vector2(VANE_FIRST_X - 30.0, Fx.STAND_Y))
	await t.run_ticks(sim, 2)
	for i in 60:
		await _step(t, sim, p1, A)
	await _step(t, sim, p1, 0)
	t.check(w["pumps"].size() == 1 and w["gemaal"].fill == 15, "60 ticks AANVAL vast: %d slagen (verwacht 1)" % w["pumps"].size())
	await t.cleanup()
	w = _pompgang(t, 100, 0, 1, 40.0)
	sim = w["sim"]
	p1 = w["p1"]
	p1.respawn_at(Vector2(VANE_FIRST_X - 30.0, Fx.STAND_Y))
	await t.run_ticks(sim, 2)
	await _step(t, sim, p1, J)
	var apex := false
	var guard := 0
	while not apex and guard < 60:
		guard += 1
		var vy: float = p1.motor.velocity.y
		await _step(t, sim, p1, J)
		apex = vy < 0.0 and p1.motor.velocity.y >= 0.0
	await _step(t, sim, p1, A)
	await t.run_ticks(sim, 40)
	t.check(apex and w["pumps"].size() == 1 and w["pumps"][0][2] == 15,
		"slag op de top van een sprong pompt niet: %s (top %s, P1 op %.0f)" % [w["pumps"], apex, p1.position.y])
	await t.cleanup()


## LM-04 (alle D), in een pompgang zoals FK-5: met een volle meter slaat P1
## elke schoep één keer in het voorbijlopen en loopt zonder stilstand door;
## `GEMAAL_VOL` valt vóór P1 de sluis (280 px na de laatste schoep) bereikt,
## en de sluis is dan al weg (LM-06). De run door K3 zelf toetst W-4/W-5.
func test_lm04_pompgang_full_before_sluice_all_d(t) -> void:
	for d: int in ALL_D:
		var w := _pompgang(t, 100, d)
		var sim = w["sim"]
		var p1: PlayerActor = w["p1"]
		var g: Gemaal = w["gemaal"]
		var sluice_x: float = w["sluice_x"]
		var hits := await _walk_and_pump(t, w, sluice_x - 12.0)
		var arrival: int = sim.tick - 1
		var t4: int = hits[3] if hits.size() == 4 else -1
		t.check(g.full_tick >= 0 and g.full_tick < arrival, "D = %d: GEMAAL_VOL op %d, P1 bij de sluis op %d" % [d, g.full_tick, arrival])
		t.check(g.full_tick == t4 - 40 + d, "D = %d: t_v = %d (verwacht t_4 − 40 + D = %d)" % [d, g.full_tick, t4 - 40 + d])
		t.check(w["opened"] == [g.full_tick] and (w["sluice"] as StaticBody2D).collision_layer == 0,
			"D = %d: sluis open op %s (t_v %d)" % [d, w["opened"], g.full_tick])
		# Geen stilstand: P1 liep elke tick (MP-1, LM-04).
		t.check(p1.motor.velocity.x > 0.0 and arrival - hits[0] <= int((sluice_x - VANE_FIRST_X) / 2.0) + 18,
			"D = %d: P1 stond stil in de pompgang (%d ticks)" % [d, arrival - hits[0]])
		# P1 loopt door de sluisdoorgang.
		await _walk_and_pump(t, w, sluice_x + 60.0)
		t.check(p1.position.x >= sluice_x + 60.0, "D = %d: P1 niet door de sluis (x %.0f)" % [d, p1.position.x])
		await t.cleanup()


# --- G-2: LM-06 --------------------------------------------------------------

## LM-06: `G = 100` op `t_v`: waterlijn op `t_v + 90` halverwege (± 1 px), op
## `t_v + 180` op `y_laag`; de sluis is er nog op `t_v − 1` en weg op `t_v`.
## P1 in `Diepwater` op `t`: op `t + 30` op zijn laatste vloerpositie,
## levenspunten gelijk. De echo loopt door `Diepwater` zonder te breken.
## Respawn na `t_v`: water blijft laag.
func test_lm06_sluice_and_water(t) -> void:
	var w := _pompgang(t, 100, 0, 1)
	var sim = w["sim"]
	var p1: PlayerActor = w["p1"]
	var g: Gemaal = w["gemaal"]
	var sluice: StaticBody2D = w["sluice"]
	# Een echo (spookbron, D = 1) loopt door de hele straat met water.
	var ghost := Fx.ghost(t)
	Fx.ghost_path(ghost, sim.tick, 200, func(k: int) -> Vector2: return Vector2(STREET.position.x - 20.0 + 2.0 * k, Fx.STAND_Y))
	var echo := Fx.tail_echo(sim, ghost, 1)
	var broke: Array = []
	echo.broke.connect(func(tick: int, _at: Vector2) -> void: broke.append(tick))
	var echo_wet := [0]
	sim.tick_finished.connect(func(tick: int) -> void:
		if echo.is_present() and g.in_deep_water(echo.position, tick):
			echo_wet[0] += 1)
	# Diepwater: P1 loopt de straat in (voorbij de sluis).
	p1.respawn_at(Vector2(STREET.position.x - 40.0, Fx.STAND_Y))
	await t.run_ticks(sim, 2)
	var health: int = p1.health
	var wet_at := -1
	var last_dry := Vector2.ZERO
	var back_at := -1
	for i in 120:
		var before: Vector2 = p1.position
		await _step(t, sim, p1, R if wet_at < 0 else 0)
		var tick: int = sim.tick - 1
		if wet_at < 0 and g.in_deep_water(p1.position, tick):
			wet_at = tick
			last_dry = before
		elif wet_at >= 0 and not g.in_deep_water(p1.position, tick):
			back_at = tick
			break
	t.check(wet_at >= 0 and back_at == wet_at + 30, "Diepwater: nat op %d, terug op %d (verwacht t + 30)" % [wet_at, back_at])
	t.check(p1.position.distance_to(last_dry) <= 2.0 and p1.health == health,
		"Diepwater: P1 op %s (laatste vloer %s), leven %d → %d" % [p1.position, last_dry, health, p1.health])
	# De echo loopt door het water: breekt niet (`Diepwater` geldt alleen voor P1).
	await t.run_ticks(sim, 100)
	t.check(broke.is_empty() and echo_wet[0] >= 100 and echo.is_present(),
		"echo in Diepwater: breuken %s, %d ticks in het water" % [broke, echo_wet[0]])
	# G = 100 op t_v (één slag van P1 bij G = 85).
	g.fill = 85
	p1.respawn_at(Vector2(VANE_FIRST_X - 30.0, Fx.STAND_Y))
	await t.run_ticks(sim, 2)
	var layer_before: int = sluice.collision_layer
	await _step(t, sim, p1, A)
	var tv: int = g.full_tick
	t.check(tv == sim.tick - 1 and layer_before != 0 and sluice.collision_layer == 0 and not sluice.visible and w["opened"] == [tv],
		"sluis: t_v %d, laag vóór %d, na %d, geopend op %s" % [tv, layer_before, sluice.collision_layer, w["opened"]])
	t.check(absf(g.waterline(tv + 90) - lerpf(WATER_HIGH, WATER_LOW, 0.5)) <= 1.0, "waterlijn niet halverwege op t_v + 90")
	t.check(is_equal_approx(g.waterline(tv + 180), WATER_LOW) and is_equal_approx(g.waterline(tv), WATER_HIGH),
		"waterlijn niet op y_laag op t_v + 180")
	# In de physics-ruimte is de sluis weg: P1 loopt erdoor.
	p1.respawn_at(Vector2(w["sluice_x"] - 20.0, Fx.STAND_Y))
	await t.run_ticks(sim, 2)
	for i in 30:
		await _step(t, sim, p1, R)
	t.check(p1.position.x > w["sluice_x"] + 20.0, "P1 kan niet door de geopende sluis (x %.0f)" % p1.position.x)
	# Respawn na t_v: het water blijft laag (LM-06).
	await _step(t, sim, p1, 0)
	await t.run_ticks(sim, 180)
	p1.respawn_at(Vector2(STREET.get_center().x, Fx.STAND_Y))
	await t.run_ticks(sim, 40)
	t.check(not g.in_deep_water(p1.position, sim.tick) and g.waterline(sim.tick) == WATER_LOW
		and p1.position.distance_to(Vector2(STREET.get_center().x, Fx.STAND_Y)) < 2.0,
		"na t_v: water %.0f, P1 op %s" % [g.waterline(sim.tick), p1.position])
	await t.cleanup()


## LM-06 in de flow-kamer: na `t_v` is er in K3 geen `FelLicht`-zone (er
## zijn in de flow-kamer helemaal geen zones, FK-4) en de sluis is op `t_v`
## weg. De kamer bouwt het gemaal met de schoepen uit `flow_layout.gd`.
func test_lm06_flowkamer_sluice_on_tv(t) -> void:
	var room = FlowRoom.new()
	room.tail = 120
	room.autosave = false
	room.show_hud = false
	room.input_override = Fx.ManualInput.new()
	t.tree.root.add_child(room)
	await t.tree.physics_frame
	var g: Gemaal = room.gemaal
	t.check(g.vanes.size() == FlowRoom.vane_positions().size() and g.pomprad == room.vanes[0],
		"schoepen: %d in het gemaal, %d in de layout" % [g.vanes.size(), FlowRoom.vane_positions().size()])
	room.meter.add(room.sim.tick, 100, "test", "p1")
	var tick: int = room.sim.tick
	for i in 7:
		room.sim.combat.hit.emit(tick + i, "p1", room.vanes[i % room.vanes.size()], 10)
	t.check(g.full_tick == tick + 6 and g.sluice_open and room.get_node("Level/Sluis").collision_layer == 0,
		"flow-kamer: t_v %d (verwacht %d), sluis open %s" % [g.full_tick, tick + 6, g.sluice_open])
	var zones: Array = room.find_children("*", "Area2D", true, false)
	t.check(zones.is_empty(), "zones in de flow-kamer na t_v: %s" % [zones])
	room.queue_free()
	await t.tree.process_frame


# --- G-3: L-13 ---------------------------------------------------------------

## L-13 (K2, G-3): golf 2 start op de eerste tick waarop elke basisvijand van
## golf 1 een merk heeft of op is, niet eerder; het pantserdoel telt niet mee.
## De golf is op zonder pantserdoelen.
func test_l13_wave_2_on_marked_or_dead(t) -> void:
	var room = FlowRoom.new()
	room.tail = 120
	room.echo_on = false
	room.autosave = false
	room.show_hud = false
	room.input_override = Fx.ManualInput.new()
	t.tree.root.add_child(room)
	await t.tree.physics_frame
	var sim = room.sim
	var p1: PlayerActor = room.p1
	p1.respawn_at(Layout.ROOM_START["K2"])
	await t.run_ticks(sim, 2)
	t.check(room.wave == 1 and room._wave_basics.size() == Layout.WAVE_1.size(), "golf 1 niet gestart in K2")
	var basics: Array = room._wave_basics.duplicate()
	# De eerste is op (verslagen), de rest krijgt een merk van P1.
	(basics[0] as CombatTarget).apply_damage(sim.tick, 100, "test")
	await t.run_ticks(sim, 1)
	t.check(room.wave == 1, "golf 2 al na één verslagen vijand")
	var marked_at := -1
	for i in range(1, basics.size()):
		var e: CombatTarget = basics[i]
		t.check(room.wave == 1, "golf 2 vóór vijand %d een merk had" % i)
		p1.respawn_at(Vector2(e.position.x - 20.0, Layout.K2_FLOOR - Layout.HALF_H))
		p1.motor.facing = 1
		await t.run_ticks(sim, 1)
		await _step(t, sim, p1, A)
		if sim.combat.mark_on(e) == null and e.alive:
			t.check(false, "P1 zette geen merk op vijand %d" % i)
		marked_at = sim.tick - 1
		await _step(t, sim, p1, 0)
		if i < basics.size() - 1:
			await t.run_ticks(sim, 20)  # herhaaltijd AANVAL (E-10)
	t.check(room.wave == 2 and room.wave_2_tick == marked_at,
		"golf 2 op %d (verwacht de tick van het laatste merk, %d)" % [room.wave_2_tick, marked_at])
	t.check(room.armored != null and room._wave_basics.size() == Layout.WAVE_2.size(), "golf 2 zonder pantserdoel of basisvijanden")
	# Een golf is op als zijn basisvijanden op zijn; het pantserdoel blijft staan.
	for e: CombatTarget in room._wave_basics:
		e.apply_damage(sim.tick, 100, "test")
	await t.run_ticks(sim, 1)
	t.check(room.wave_done() and room.armored.alive, "golf 2 niet op zonder het pantserdoel")
	room.queue_free()
	await t.tree.process_frame


# --- G-4: E-07d --------------------------------------------------------------

## E-07d (alle D): P1 loopt een gang door, keert en loopt terug: het
## plank-signaal gaat aan op de eerste tick waarop de echo nadert en ≤ 130 px
## van P1 is, en uit op de tick van de landing. Keert P1 vóór de landing weer
## om (de afstand groeit niet meer af): uit op die tick. Leeg: uit.
## Bij D = 60 is de echo bij het keren al 120 px van P1 (gdd §4.8.2): wie dan
## meteen tegemoet springt, is al voorbij de echo vóór hij landt. Daarom bij
## D < 90 "stop en spring" (§4.8.2): P1 blijft staan en springt recht omhoog
## zodra de echo ≤ 66 px nadert, en landt op de naderende echo.
func test_e07d_plank_signal_all_d(t) -> void:
	for d: int in ALL_D:
		for again in [false, true]:
			var sim = Fx.world(t)
			var p1 := Fx.manual_player(sim, 1, Vector2(100, Fx.STAND_Y))
			var echo := Fx.tail_echo(sim, p1, d)
			var hints := EchoHints.new(sim, p1, func() -> Node2D: return echo)
			var early_on := false
			for i in d + 60:
				await _step(t, sim, p1, R)
				early_on = early_on or hints.plank_signaal
			var on_at := -1
			var off_at := -1
			var landed_at := -1
			var dx_prev := INF
			var dx_on := -1.0
			var dx_before_on := -1.0
			var gap := false
			var jumped := false
			for i in 120:
				var bits := L
				var gap_now := absf(echo.position.x - p1.position.x)
				if on_at >= 0 and again and sim.tick >= on_at + 3:
					bits = R
				elif on_at >= 0 and not again and not jumped and d < 90:
					bits = 0
					if gap_now <= 66.0:
						bits = J
						jumped = true
				elif on_at >= 0 and not again and not jumped:
					bits = L | J
					jumped = true
				elif jumped and d < 90:
					bits = 0
				await _step(t, sim, p1, bits)
				var tick: int = sim.tick - 1
				var dx := absf(echo.position.x - p1.position.x)
				if p1.move_events & Motor.EV_SPRINGPLANK and landed_at < 0:
					landed_at = tick
				if hints.plank_signaal and on_at < 0:
					on_at = tick
					dx_on = dx
					dx_before_on = dx_prev
				elif on_at >= 0 and off_at < 0 and not hints.plank_signaal:
					off_at = tick
				elif off_at >= 0 and hints.plank_signaal and landed_at < 0:
					gap = true
				dx_prev = dx
				if off_at >= 0:
					break
			t.check(not early_on, "D = %d: signaal aan zonder naderen" % d)
			t.check(on_at >= 0 and dx_on <= 130.0 and dx_before_on > 130.0,
				"D = %d: aan op %d bij %.0f px (tick ervoor %.0f px)" % [d, on_at, dx_on, dx_before_on])
			if again:
				t.check(off_at == on_at + 3 and landed_at < 0, "D = %d, weer omgekeerd: uit op %d (verwacht %d)" % [d, off_at, on_at + 3])
			else:
				t.check(landed_at >= 0 and off_at == landed_at and not gap,
					"D = %d: landing op %d, uit op %d" % [d, landed_at, off_at])
			await t.cleanup()


## E-07d: een zwevende echo (E-07c (2): P1 stond sinds zijn grondcontact op
## een plank) krijgt nooit een signaal, ook als hij nadert; dezelfde echo die
## draagt wel. Draagt hij na het zweven weer (nieuw grondcontact) terwijl P1
## binnen 130 px van hem af loopt: geen signaal, ook niet op de eerste
## dragende tick. In een merksprong (E-02m) staat het signaal uit.
func test_e07d_floating_and_merksprong(t) -> void:
	for floating in [true, false]:
		var sim = Fx.world(t)
		var p1 := Fx.manual_player(sim, 1, Vector2(100, Fx.STAND_Y))
		await t.run_ticks(sim, 2)
		var ghost := Fx.ghost(t)
		var start: int = sim.tick
		Fx.ghost_path(ghost, start, 200, func(k: int) -> Vector2: return Vector2(maxf(300.0 - 2.0 * k, 160.0), Fx.STAND_Y),
			true, Motor.Support.WORLD, floating)
		var echo := Fx.tail_echo(sim, ghost, 1)
		var hints := EchoHints.new(sim, p1, func() -> Node2D: return echo)
		var seen := false
		for i in 120:
			await t.run_ticks(sim, 1)
			seen = seen or hints.plank_signaal
		t.check(seen != floating, "zwevend = %s: signaal gezien = %s" % [floating, seen])
		await t.cleanup()
	# Nieuw grondcontact na zweven: de echo zweeft 30 frames (E-07c (2)) en
	# draagt daarna, 70 px van P1, die dan van hem af loopt. Op de eerste
	# dragende tick is er geen afstand op `t − 1`: geen signaal en geen tik.
	var sim3 = Fx.world(t)
	var p1c := Fx.manual_player(sim3, 1, Vector2(150, Fx.STAND_Y))
	await t.run_ticks(sim3, 2)
	var ghost3 := Fx.ghost(t)
	var s3: int = sim3.tick
	Fx.ghost_path(ghost3, s3, 30, func(_k: int) -> Vector2: return Vector2(220, Fx.STAND_Y),
		true, Motor.Support.WORLD, true)
	Fx.ghost_path(ghost3, s3 + 30, 60, func(_k: int) -> Vector2: return Vector2(220, Fx.STAND_Y))
	var echo3 := Fx.tail_echo(sim3, ghost3, 1)
	var hints3 := EchoHints.new(sim3, p1c, func() -> Node2D: return echo3)
	var taps: Array = []
	hints3.plank_signal_on.connect(func(tick: int) -> void: taps.append(tick))
	var floated := false
	var dx_first := -1.0
	var seen3 := false
	for i in 70:
		var carrying: bool = echo3.carrier_valid()
		floated = floated or (echo3.is_present() and not carrying)
		await _step(t, sim3, p1c, L if carrying else 0)
		if echo3.carrier_valid() and dx_first < 0.0:
			dx_first = absf(echo3.position.x - p1c.position.x)
		seen3 = seen3 or hints3.plank_signaal
	t.check(floated and dx_first >= 0.0 and dx_first <= 130.0,
		"opzet nieuw grondcontact: zweefde %s, afstand bij dragen %.0f px" % [floated, dx_first])
	t.check(not seen3 and taps.is_empty(), "nieuw grondcontact: signaal %s, tik op %s" % [seen3, taps])
	await t.cleanup()
	# Merksprong: P1 merkt een vijand; de echo nadert en springt naar het merk.
	var sim2 = Fx.world(t)
	var p1b := Fx.manual_player(sim2, 1, Vector2(100, Fx.STAND_Y))
	Fx.target(sim2, ENEMY, 120.0)
	await t.run_ticks(sim2, 2)
	await _step(t, sim2, p1b, A)
	await _step(t, sim2, p1b, 0)
	var ghost2 := Fx.ghost(t)
	var s2: int = sim2.tick
	for k in 120:
		Fx.ghost_frame(ghost2, s2 + k, Vector2(230.0 - 2.0 * minf(k, 50), Fx.STAND_Y), true, Motor.Support.WORLD,
			GameEvents.ATTACK if k == 20 else 0)
	var echo2 := Fx.tail_echo(sim2, ghost2, 1)
	var hints2 := EchoHints.new(sim2, p1b, func() -> Node2D: return echo2)
	var on_before := false
	var on_during := false
	var jumped := false
	for i in 60:
		await t.run_ticks(sim2, 1)
		if echo2.in_merksprong:
			jumped = true
			on_during = on_during or hints2.plank_signaal
		elif not jumped:
			on_before = on_before or hints2.plank_signaal
	t.check(jumped and on_before and not on_during,
		"merksprong: sprong %s, aan vóór %s, aan tijdens %s" % [jumped, on_before, on_during])
	await t.cleanup()


# --- G-4: E-02t --------------------------------------------------------------

## Wereld met P1 (handmatig) en zijn echo, P1 eerst D + 10 ticks stil, zodat
## de echo Actief is.
func _echo_world(t, d: int, p1_x: float) -> Dictionary:
	var sim = Fx.world(t)
	var p1 := Fx.manual_player(sim, 1, Vector2(p1_x, Fx.STAND_Y))
	var echo := Fx.tail_echo(sim, p1, d)
	var hints := EchoHints.new(sim, p1, func() -> Node2D: return echo)
	var jumps: Array = []
	echo.merksprong_started.connect(func(tick: int, _id: int) -> void: jumps.append(tick))
	var flags := {}
	sim.tick_finished.connect(func(tick: int) -> void:
		flags[tick] = hints.doelstreep_mark if hints.doelstreep else null)
	await t.run_ticks(sim, d + 10)
	return {"sim": sim, "p1": p1, "echo": echo, "hints": hints, "jumps": jumps, "flags": flags}


func _on_ticks(flags: Dictionary) -> Array:
	var out: Array = []
	for tick: int in flags:
		if flags[tick] != null:
			out.append(tick)
	out.sort()
	return out


## E-02t (alle D): (1) P1 zet een merk op een stilstaande vijand op `x`: de
## vlag `doelstreep` staat aan van `x + D − 30` tot de merksprong op `x + D`,
## met dat merk als doel. (2) Als (1), maar P1 maakt de vijand af op
## `x + D − 10`: de vlag gaat uit op die tick, er is geen merksprong.
func test_e02t_doelstreep_mark_all_d(t) -> void:
	for d: int in ALL_D:
		for kill in [false, true]:
			var w := await _echo_world(t, d, 200.0)
			var sim = w["sim"]
			var p1: PlayerActor = w["p1"]
			var enemy := Fx.target(sim, ENEMY, 220.0)
			enemy.health = 20
			await t.run_ticks(sim, 1)
			var x: int = sim.tick
			await _step(t, sim, p1, A)
			var mark = sim.combat.mark_on(enemy)
			await _step(t, sim, p1, 0)
			if kill:
				await t.run_ticks(sim, d - 12)
				await _step(t, sim, p1, A)
				await _step(t, sim, p1, 0)
			await t.run_ticks(sim, d + 20 - (sim.tick - x))
			var on := _on_ticks(w["flags"])
			if kill:
				var expected := range(x + d - 30, x + d - 10)
				t.check(not enemy.alive and on == expected and not w["jumps"].has(x + d),
					"D = %d, afgemaakt: aan op %s (verwacht %d … %d), sprongen %s" % [d, _span(on), x + d - 30, x + d - 11, w["jumps"]])
			else:
				var expected := range(x + d - 30, x + d)
				var target_ok := true
				for tick: int in on:
					target_ok = target_ok and w["flags"][tick] == mark
				t.check(mark != null and on == expected and target_ok and w["jumps"] == [x + d],
					"D = %d: aan op %s (verwacht %d … %d), merksprong op %s (verwacht %d)" % [d, _span(on), x + d - 30, x + d - 1, w["jumps"], x + d])
			await t.cleanup()


## E-02t (alle D): (3) P1 slaat op `x` in de lucht, zonder merk binnen R van
## die positie op `x + D − 30`: geen vlag. (4) Als (3), maar P1 zet op
## `x + D − 20` een merk binnen R van de positie van `x`: de vlag gaat aan
## op `x + D − 20`.
func test_e02t_doelstreep_air_all_d(t) -> void:
	for d: int in ALL_D:
		for late_mark in [false, true]:
			var w := await _echo_world(t, d, 200.0)
			var sim = w["sim"]
			var p1: PlayerActor = w["p1"]
			# Een sprong naar rechts (niet op de eigen echo, die op 200 staat), de
			# slag op de top rond x = 240; daarna land P1 op ± 280.
			var enemy: CombatTarget = Fx.target(sim, ENEMY, 230.0) if late_mark else null
			for i in 19:
				await _step(t, sim, p1, J | R)
			var x: int = sim.tick
			var air_at: Vector2 = p1.position
			await _step(t, sim, p1, A | R)
			var guard := 0
			while not p1.motor.on_floor and guard < 60:
				guard += 1
				await _step(t, sim, p1, R)
			await _step(t, sim, p1, 0)
			await t.run_ticks(sim, x + d - 36 - sim.tick)
			# 15 ticks naar links: P1 staat op 250 met zijn gezicht naar de vijand.
			for i in 15:
				await _step(t, sim, p1, L)
			await _step(t, sim, p1, 0)
			var mark_tick: int = sim.tick
			if late_mark:
				await _step(t, sim, p1, A)
				t.check(sim.combat.mark_on(enemy) != null, "D = %d: geen merk gezet (P1 op %s)" % [d, p1.position])
			await _step(t, sim, p1, 0)
			await t.run_ticks(sim, 40)
			var on := _on_ticks(w["flags"])
			if late_mark:
				var near: bool = air_at.distance_to(enemy.global_position) <= 80.0
				t.check(near and mark_tick == x + d - 20 and on.size() > 0 and on[0] == x + d - 20,
					"D = %d, laat merk op %d: aan vanaf %s (verwacht %d; afstand %.0f)" % [d, mark_tick, _span(on), x + d - 20, air_at.distance_to(enemy.global_position)])
			else:
				t.check(on.is_empty() and air_at.y < Fx.STAND_Y - 30.0,
					"D = %d, slag in de lucht zonder merk: aan op %s (P1 op %s)" % [d, _span(on), air_at])
			await t.cleanup()


func _span(ticks: Array) -> String:
	if ticks.is_empty():
		return "[]"
	return "%d … %d (%d ticks)" % [ticks[0], ticks[ticks.size() - 1], ticks.size()]


# --- G-4: E-14j --------------------------------------------------------------

## E-14j: merk op `x`: een vijand met zijn middelpunt op 32 px heeft de vlag
## `in_bereik`, op 33 px niet; hij beweegt binnen: de vlag gaat aan op die
## tick. Twee merken op 48 px: een kettinglijn; op 49 px niet. Na de
## ontploffing: geen cirkel, geen lijn.
func test_e14j_reach_and_chain(t) -> void:
	var sim = Fx.world(t)
	var p1 := Fx.manual_player(sim, 1, Vector2(100, Fx.STAND_Y))
	var hints := EchoHints.new(sim, p1, func() -> Node2D: return null)
	var center := Fx.target(sim, ENEMY, 300.0)
	var at_32 := Fx.target(sim, ENEMY, 332.0)
	var at_33 := Fx.target(sim, ENEMY, 267.0)
	var a := Fx.target(sim, ENEMY, 600.0)
	var b := Fx.target(sim, ENEMY, 648.0)
	var c := Fx.target(sim, ENEMY, 900.0)
	var e := Fx.target(sim, ENEMY, 949.0)
	# D vast op 120 (merk leeft 150 ticks): P1 zet vijf merken na elkaar
	# (± 23 ticks per merk) en ze moeten er alle vijf nog zijn. Bij de
	# standaard-D 60 (90 ticks) zou het eerste al gedoofd zijn; de levensduur
	# zelf testen E-14b (alle D) en C-12e.
	sim.combat.tail_ticks = 120
	for target: CombatTarget in [center, a, b, c, e]:
		p1.respawn_at(Vector2(target.position.x - 20.0, Fx.STAND_Y))
		await t.run_ticks(sim, 1)
		await _step(t, sim, p1, A)
		await _step(t, sim, p1, 0)
		await t.run_ticks(sim, 20)  # herhaaltijd AANVAL (E-10)
	t.check(sim.combat.marks.size() == 5, "niet vijf merken: %d" % sim.combat.marks.size())
	t.check(hints.is_in_bereik(center) and hints.is_in_bereik(at_32) and not hints.is_in_bereik(at_33),
		"in_bereik: midden %s, 32 px %s, 33 px %s" % [hints.is_in_bereik(center), hints.is_in_bereik(at_32), hints.is_in_bereik(at_33)])
	at_33.position.x = 268.0
	await t.run_ticks(sim, 1)
	t.check(hints.is_in_bereik(at_33), "vijand op 32 px na bewegen: geen in_bereik op die tick")
	var pairs: Array = hints.chain_links.map(func(link: Array) -> Array: return [link[0].target, link[1].target])
	t.check(pairs.size() == 1 and (pairs[0] == [a, b] or pairs[0] == [b, a]),
		"kettinglijnen: %d (verwacht één, tussen de merken op 48 px)" % pairs.size())
	# Ontploffing: het merk weg, de ketting knalt de tick erna; dan niets meer.
	sim.combat.detonate(sim.tick, sim.combat.mark_on(a))
	await t.run_ticks(sim, 3)
	var gone := sim.combat.mark_on(a) == null and sim.combat.mark_on(b) == null
	var still := hints.chain_links.filter(func(link: Array) -> bool: return link[0].target in [a, b] or link[1].target in [a, b])
	t.check(gone and still.is_empty() and not hints.is_in_bereik(a) and not hints.is_in_bereik(b),
		"na de ontploffing: merken weg %s, lijnen %d, bereik %s/%s" % [gone, still.size(), hints.is_in_bereik(a), hints.is_in_bereik(b)])
	await t.cleanup()


# --- G-5: D op het scorescherm -----------------------------------------------

## G-5 (rapport F0 §8 punt 8): na `RUN_EIND` staat het scorescherm meteen in
## beeld, met de D van de run; een nieuwe run (F1–F4, F6) kan pas na de drie
## scores.
func test_g5_score_screen_shows_d(t) -> void:
	for d: int in ALL_D:
		var room = FlowRoom.new()
		room.tail = d
		room.autosave = false
		room.show_hud = true
		room.input_override = Fx.ManualInput.new()
		t.tree.root.add_child(room)
		await t.tree.physics_frame
		t.check(room.score_text().is_empty() and not room._score_panel.visible, "D = %d: scorescherm tijdens de run" % d)
		room._finish_run(room.sim.tick)
		room._update_hud()
		var text: String = room.score_text()
		t.check(room._score_panel.visible and room._score_label.text == text and text.contains("D = %d" % d)
			and text.contains("%.1f" % (d / 60.0)) and text.contains("K1"),
			"D = %d: scorescherm '%s'" % [d, text])
		t.check(room.scores_pending(), "D = %d: wacht niet op scores" % d)
		var f6 := InputEventKey.new()
		f6.physical_keycode = KEY_F6
		f6.pressed = true
		room._unhandled_input(f6)
		t.check(room.is_inside_tree() and room.run_over, "D = %d: F6 herstartte vóór de scores" % d)
		for key in [KEY_3, KEY_4, KEY_5]:
			var ev := InputEventKey.new()
			ev.physical_keycode = key
			ev.pressed = true
			room._unhandled_input(ev)
		room._update_hud()
		t.check(not room.scores_pending() and room.meetlog.count("SCORE") == 3,
			"D = %d: scores niet gelogd (%d)" % [d, room.meetlog.count("SCORE")])
		room.queue_free()
		await t.tree.process_frame


# --- G-6: D = 60 standaard, op één plek in data --------------------------------

## G-6 (gdd v0.8 §4.8.4): D staat op één plek in data (`echo.tail_ticks` = 60)
## en de build start daarop: een kamer zonder eigen D, de echo, Combat en een
## nieuwe TailEcho volgen die waarde; de merken leven solo D + 30 = 90.
func test_g6_build_starts_on_d60_from_data(t) -> void:
	var d: int = int(Tuning.echo()["tail_ticks"])
	t.check(d == 60, "standaard-D in data %d (60)" % d)
	t.check(FlowRoom.chosen_tail == d, "debugmenu start op D = %d (data %d)" % [FlowRoom.chosen_tail, d])
	var bare_echo := TailEcho.new()
	t.check(Combat.new().tail_ticks == d and bare_echo.tail_ticks == d,
		"Combat of TailEcho start niet op D uit data")
	bare_echo.free()
	var room = FlowRoom.new()
	room.autosave = false
	room.show_hud = true
	room.input_override = Fx.ManualInput.new()
	t.tree.root.add_child(room)
	await t.tree.physics_frame
	t.check(room.tail == 60 and room.echo != null and room.echo.tail_ticks == 60 and room.sim.combat.tail_ticks == 60,
		"kamer zonder eigen D: tail %d, echo %d, combat %d (60)" % [room.tail,
		room.echo.tail_ticks if room.echo else -1, room.sim.combat.tail_ticks])
	t.check(room.get_node_or_null("Level/B3Blok") == null, "D = 60: er staat een B3-blok")
	t.check(room.sim.combat.life_ticks() == 90, "solo-merk leeft %d ticks (D + 30 = 90)" % room.sim.combat.life_ticks())
	room._update_hud()
	t.check(room._hud_label.text.contains("D = 60") and room._hud_label.text.contains("F1/F2/F3/F7 D 60/90/120/180"),
		"HUD '%s'" % room._hud_label.text)
	room.queue_free()
	await t.tree.process_frame


## G-6: het debugmenu kent 60 / 90 / 120 / 180 op F1 / F2 / F3 / F7 (waarden
## uit `echo.tail_options`), en het B3-blok volgt `max(D − 60, 0)`.
func test_g6_debug_menu_and_b3_block(t) -> void:
	var options: Array = Array(Tuning.echo()["tail_options"]).map(func(v: Variant) -> int: return int(v))
	t.check(options == [60, 90, 120, 180], "tail_options %s (60, 90, 120, 180)" % str(options))
	var got := []
	for key: int in [KEY_F1, KEY_F2, KEY_F3, KEY_F7]:
		got.append(FlowRoom.debug_tail(key))
	t.check(got == [60, 90, 120, 180], "F1/F2/F3/F7 geven D %s (60/90/120/180)" % str(got))
	t.check(FlowRoom.debug_tail_label() == "F1/F2/F3/F7 D 60/90/120/180", "label '%s'" % FlowRoom.debug_tail_label())
	for pair: Array in [[60, 0.0], [90, 30.0], [120, 60.0], [180, 120.0]]:
		var d: int = pair[0]
		var names := Layout.blocks(d).map(func(spec: Array) -> String: return str(spec[0]))
		t.check(is_equal_approx(Layout.b3_width(d), pair[1]) and (names.has("B3Blok") == (d > 60)),
			"D = %d: B3-blok %.0f px, in de layout %s (verwacht %.0f)" % [d, Layout.b3_width(d), names.has("B3Blok"), pair[1]])
