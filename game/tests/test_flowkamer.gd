extends RefCounted
## Tests voor de grijze flow-kamer (T16b, #77; gdd §4.2–§4.6).
##
## De kamer laadt, de gescripte geoefende run haalt per D het einde
## (`RUN_EIND`) en de normen MP-1, MP-2, MP-4 en MP-6, het meetlog schrijft de
## CSV en is deterministisch, en met echo uit is het gemaal vol te krijgen
## (FK-2). Elke run duurt ± 3800–6900 ticks; de runner geeft een test 7200
## frames, daarom is elke run een eigen test (ook FK-2 per D). De run van D = 90 wordt in een
## volgende test afgespeeld met een ScriptedInput (zelfde bits, zelfde log).

const FlowRoom = preload("res://levels/flowkamer/flow_room.gd")
const FlowBot = preload("res://levels/flowkamer/flow_bot.gd")
const FlowReport = preload("res://levels/flowkamer/flow_report.gd")
const Layout = preload("res://levels/flowkamer/flow_layout.gd")
const ScriptedInput = preload("res://scripts/input/scripted_input.gd")
const Zone = preload("res://scripts/objects/zone.gd")
const LightMeter = preload("res://scripts/light/light_meter.gd")
const Gemaal = preload("res://scripts/light/gemaal.gd")
const Meetlog = preload("res://scripts/events/meetlog.gd")

## Run van test_scripted_run_d90, voor de replay-test.
static var _d90_bits := PackedInt32Array()
static var _d90_csv := ""
## Duur van de run met echo per D, voor FK-2.
static var _echo_ticks := {}

const TICK_CAP := 7000


## Bouwt de kamer met een inputbron; `bot = true` geeft de gescripte run.
func _room(t, d: int, echo_on: bool, input: RefCounted = null) -> Array:
	var room = FlowRoom.new()
	room.tail = d
	room.echo_on = echo_on
	room.autosave = false
	room.show_hud = false
	var bot = null
	if input == null:
		bot = FlowBot.new(room)
		input = bot
	room.input_override = input
	t.tree.root.add_child(room)
	return [room, bot]


func _run(t, room) -> void:
	while not room.run_over and room.sim.tick < TICK_CAP:
		await t.tree.physics_frame


func _free(t, room) -> void:
	room.queue_free()
	await t.tree.process_frame


## De kamer laadt: drie kamers als buren, geen zones (FK-4), het B3-blok per D
## (gdd §4.3: B = D − 60), het pomprad 15–40 px boven de vloer (FK-5).
func test_room_loads(t) -> void:
	for d in [90, 120, 180]:
		var pair := _room(t, d, true)
		var room = pair[0]
		await t.tree.physics_frame
		t.check(room.sim != null and room.p1 != null and room.echo != null, "D=%d: Sim, P1 of echo ontbreekt" % d)
		var block: StaticBody2D = room.get_node("Level/B3Blok")
		var size: Vector2 = (block.get_child(0).shape as RectangleShape2D).size
		t.check(is_equal_approx(size.x, d - 60.0), "D=%d: B3-blok %.0f px (verwacht %d)" % [d, size.x, d - 60])
		var zones: Array = room.find_children("*", "Area2D", true, false)
		t.check(zones.is_empty(), "D=%d: zones in de flow-kamer (FK-4): %s" % [d, zones])
		var above: float = Layout.FLOOR - room.pomprad.position.y
		t.check(above >= 15.0 and above <= 40.0, "pomprad %.0f px boven de vloer (FK-5: 15–40)" % above)
		t.check(Layout.room_of(Layout.RUN_START) == "K1" and room.room == "K1", "run begint niet in K1")
		await _free(t, room)
	for key: String in Layout.NEIGHBOURS:
		for other: String in Layout.NEIGHBOURS[key]:
			t.check(key in Layout.NEIGHBOURS[other], "buren niet symmetrisch: %s/%s (E-04a)" % [key, other])


## Gemaal en lichtmeter (LM-01, LM-03, LM-06) zonder physics. De regels per
## schoep en per D staan in `test_regels_na_f0.gd`.
func test_gemaal_and_meter(t) -> void:
	var pair := _room(t, 120, true)
	var room = pair[0]
	await t.tree.physics_frame
	var meter: LightMeter = room.meter
	var g: Gemaal = room.gemaal
	meter.add(0, 110, "test", "p1")
	t.check(meter.value == 100, "LM-01: 110 LP opgeteld geeft %d (verwacht 100)" % meter.value)
	# LM-03: 4 slagen P1 (15 per slag), dan 3 van de echo: 15, 15, 10.
	for i in 4:
		room.sim.combat.hit.emit(i * 20, "p1", room.pomprad, 10)
	t.check(g.fill == 60 and meter.value == 40, "LM-03: na 4 slagen G=%d L=%d (60/40)" % [g.fill, meter.value])
	for i in 2:
		room.sim.combat.hit.emit(200 + i * 20, "echo", room.pomprad, 5)
	t.check(not g.sluice_open, "LM-06: sluis open vóór t_v")
	room.sim.combat.hit.emit(240, "echo", room.pomprad, 5)
	t.check(g.fill == 100 and meter.value == 0 and g.full_tick == 240, "LM-03: G=%d L=%d t_v=%d" % [g.fill, meter.value, g.full_tick])
	var tv: int = g.full_tick
	t.check(g.sluice_open and g.sluice.collision_layer == 0, "LM-06: sluis niet weg op t_v")
	t.check(absf(g.waterline(tv + 90) - lerpf(Layout.WATER_HIGH, Layout.WATER_LOW, 0.5)) <= 1.0, "LM-06: waterlijn halverwege op t_v + 90")
	t.check(is_equal_approx(g.waterline(tv + 180), Layout.WATER_LOW), "LM-06: waterlijn op y_laag op t_v + 180")
	await _free(t, room)


func _check_run(t, room, bot, d: int) -> FlowReport:
	var rep: FlowReport = FlowReport.from_rows(room.meetlog.rows)
	t.check(room.run_over, "D=%d: geen RUN_EIND binnen %d ticks (bot op %s/%s, kamer %s)" % [d, TICK_CAP, bot.leg, bot.sub, room.room])
	t.check(room.meetlog.count("RUN_EIND") == 1 and room.meetlog.count("GEMAAL_VOL") == 1, "D=%d: RUN_EIND/GEMAAL_VOL ontbreekt" % d)
	t.check(room.run_ticks() <= 7200, "D=%d: run %d ticks (doel ≤ 120 s)" % [d, room.run_ticks()])
	t.check(rep.lp_before_k3 >= 100, "D=%d: %d LP na K1 + K2 (gdd §4.2: ≥ 100)" % [d, rep.lp_before_k3])
	var fails := rep.failures()
	t.check(fails.is_empty(), "D=%d: normen niet gehaald: %s" % [d, ", ".join(fails)])
	# FK-3, FK-4: geen breuk en geen reset door een kamerwissel.
	t.check(room.meetlog.count("BREEK") == 0, "D=%d: echo brak %d keer (FK-4)" % [d, room.meetlog.count("BREEK")])
	t.check(room.meetlog.count("ECHO_LEEG_START") == 0, "D=%d: echo werd Leeg (FK-3)" % d)
	t.check(room.room_changes.size() >= 3, "D=%d: kamerwissels %s" % [d, room.room_changes])
	for leg_name in ["B4", "B3", "B1", "B2-0", "B2-1", "B2-2", "B2-3"]:
		t.check(bot.lines.get(leg_name, false), "D=%d: %s niet via de echolijn" % [d, leg_name])
	# Elk event van de kamer staat erin (gdd §4.6, meetlog).
	for event in ["RUN_START", "RUN_EIND", "KAMER", "STIL_START", "STIL_EIND", "ECHO_LEEG_EIND",
			"SPRINGPLANK", "BOUNCE", "LANCERING", "MERK_GEZET", "MERKSPRONG", "ONTPLOFFING", "LP", "POMP", "GEMAAL_VOL"]:
		t.check(room.meetlog.count(event) >= 1, "D=%d: event %s ontbreekt in het meetlog" % [d, event])
	t.note("D=%d: %s" % [d, rep.summary()])
	return rep


func test_scripted_run_d90(t) -> void:
	var pair := _room(t, 90, true)
	var room = pair[0]
	var bot = pair[1]
	await _run(t, room)
	_check_run(t, room, bot, 90)
	# Het meetlog schrijft de CSV (gdd §4.5).
	var path := "user://meetlog_test_solo_D90_p1.csv"
	t.check(room.meetlog.save(path) == OK, "CSV niet opgeslagen")
	var text := FileAccess.get_file_as_string(path)
	t.check(text.begins_with(Meetlog.HEADER) and text.count("\n") == room.meetlog.rows.size() + 1,
		"CSV klopt niet met het log")
	t.check(room.log_file_name().begins_with("meetlog_") and room.log_file_name().ends_with("_solo_D90_p1.csv"),
		"bestandsnaam %s" % room.log_file_name())
	_echo_ticks[90] = room.run_ticks()
	_d90_bits = bot.recorded
	_d90_csv = room.meetlog.to_csv()
	await _free(t, room)


## Dezelfde bits als ScriptedInput: hetzelfde log (gdd §4.5, determinisme).
func test_replay_d90_gives_same_log(t) -> void:
	t.check(not _d90_bits.is_empty(), "geen run van D = 90 om af te spelen")
	var segments: Array = []
	for bits in _d90_bits:
		if not segments.is_empty() and segments[-1][1] == bits:
			segments[-1][0] += 1
		else:
			segments.append([1, bits])
	var pair := _room(t, 90, true, ScriptedInput.new(segments))
	var room = pair[0]
	await _run(t, room)
	t.check(room.run_over, "replay haalt RUN_EIND niet")
	t.check(room.meetlog.to_csv() == _d90_csv, "replay gaf een ander meetlog")
	await _free(t, room)


func test_scripted_run_d120(t) -> void:
	var pair := _room(t, 120, true)
	var room = pair[0]
	await _run(t, room)
	_check_run(t, room, pair[1], 120)
	_echo_ticks[120] = room.run_ticks()
	await _free(t, room)


func test_scripted_run_d180(t) -> void:
	var pair := _room(t, 180, true)
	var room = pair[0]
	await _run(t, room)
	_check_run(t, room, pair[1], 180)
	_echo_ticks[180] = room.run_ticks()
	await _free(t, room)


## FK-2 (en C-15 (1)), per D (gdd §4.4): met echo uit is het gemaal vol na
## ≤ 4 terugkeren in K2 en duurt de run ≤ 2× de run met echo bij dezelfde D.
func _fk2_echo_off(t, d: int) -> void:
	var pair := _room(t, d, false)
	var room = pair[0]
	await _run(t, room)
	var with_echo: int = _echo_ticks.get(d, 0)
	t.check(room.run_over, "D=%d: met echo uit geen RUN_EIND (bot op %s/%s, G=%d)" % [d, pair[1].leg, pair[1].sub, room.gemaal.fill])
	t.check(room.gemaal.full_tick >= 0 and room.k2_returns <= 4, "FK-2 D=%d: %d terugkeren in K2 (≤ 4)" % [d, room.k2_returns])
	t.check(with_echo > 0 and room.run_ticks() <= 2 * with_echo,
		"FK-2 D=%d: run zonder echo %d ticks, met echo %d (≤ 2×)" % [d, room.run_ticks(), with_echo])
	t.check(room.meetlog.count("SPRINGPLANK") == 0 and room.meetlog.count("ONTPLOFFING") == 0,
		"D=%d: echo uit maar toch echo-acties" % d)
	t.note("echo uit, D=%d: %d ticks (%.2f× de run met echo), %d terugkeren in K2" % [
		d, room.run_ticks(), float(room.run_ticks()) / maxi(with_echo, 1), room.k2_returns])
	await _free(t, room)


func test_fk2_echo_off_d90(t) -> void:
	await _fk2_echo_off(t, 90)


func test_fk2_echo_off_d120(t) -> void:
	await _fk2_echo_off(t, 120)


func test_fk2_echo_off_d180(t) -> void:
	await _fk2_echo_off(t, 180)


## E-08a met een eenrichtingsrichel (laag 1, gdd §4.1): P1 springt er van
## onder doorheen en landt erop; de echo herhaalt dat en breekt niet. (Vóór
## T16b brak de echo op de 3e tick van overlap met de richel.)
func test_echo_passes_one_way_ledge(t) -> void:
	const Fx = preload("res://tests/echo_fixture.gd")
	const InputBits = preload("res://scripts/input/input_bits.gd")
	var sim = Fx.world(t)
	Fx.block(t, "Richel", Rect2(150, Fx.FLOOR_TOP - 45.0, 120, 6), 1, true)
	var p1 := Fx.p1(sim, [[20, 0], [1, InputBits.JUMP], [200, 0]])
	var echo := Fx.tail_echo(sim, p1, 90)
	var breaks := [0]
	echo.broke.connect(func(_tick: int, _at: Vector2) -> void: breaks[0] += 1)
	await t.run_ticks(sim, 200)
	t.check(absf(p1.position.y - (Fx.FLOOR_TOP - 45.0 - 15.0)) < 1.0, "P1 staat niet op de richel (y = %.1f)" % p1.position.y)
	t.check(breaks[0] == 0, "echo brak %d keer bij de eenrichtingsrichel" % breaks[0])
	t.check(echo.is_present() and absf(echo.position.y - p1.position.y) < 1.0, "echo staat niet op de richel")
	await t.cleanup()
