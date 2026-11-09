extends Node2D
## De grijze flow-kamer (gdd §4, mijlpaal 1 F0; T16b #77).
##
## Drie kamers in één scène: K1 sprongketen, K2 merk-arena, K3 gemaal
## (`flow_layout.gd`). Een run begint bij de ingang van K1 (`RUN_START`) en
## eindigt als P1 na `GEMAAL_VOL` via de sluis K1 weer binnenkomt (`RUN_EIND`).
## Het meetlog (`flow_meetlog.gd`) schrijft dan de CSV voor de flownormen
## (§4.5); daarna vraagt de kamer per kamer de score voor norm (3).
##
## Besturing loopt via de InputRouter (T5a): de eerste knop neemt plaats 1;
## Enter/Start op een vrij apparaat laat P2 meedoen, Backspace/Select 1 s
## vasthouden laat P2 stoppen. Zolang P2 meedoet, is er geen echo (C-01). De
## echte drop-in/drop-out en de co-op-acties (C-03–C-13) komen in T16c (#78).
##
## Debugmenu (§4.1): F1/F2/F3 = D 90/120/180 (zet ook het B3-blok; start een
## nieuwe run), F4 = echo aan/uit (nieuwe run), F5 = meetlog aan/uit,
## F6 = herstart. Na de run: 1–5 = score per kamer.

signal run_finished(tick: int)

const Sim = preload("res://scripts/sim.gd")
const PlayerActor = preload("res://scripts/echo/player_actor.gd")
const TailEcho = preload("res://scripts/echo/tail_echo.gd")
const SpikeWorld = preload("res://scripts/world/spike_world.gd")
const Tuning = preload("res://scripts/echo/tuning.gd")
const CombatTarget = preload("res://scripts/combat/combat_target.gd")
const Layout = preload("res://levels/flowkamer/flow_layout.gd")
const FlowEnemy = preload("res://levels/flowkamer/flow_enemy.gd")
const FlowMeetlog = preload("res://levels/flowkamer/flow_meetlog.gd")
const LightMeter = preload("res://scripts/light/light_meter.gd")
const Gemaal = preload("res://scripts/light/gemaal.gd")
const Pomprad = preload("res://scripts/light/pomprad.gd")

const P1_COLOR := Color(1.0, 0.85, 0.4)
const P2_COLOR := Color(0.5, 0.85, 1.0)
const ECHO_COLOR := Color(0.42, 0.36, 0.7, 0.85)
const BLOCK_COLOR := Color(0.35, 0.35, 0.4)
const ONE_WAY_COLOR := Color(0.55, 0.55, 0.6)
const DEBUG_TAIL_KEYS := {KEY_F1: 90, KEY_F2: 120, KEY_F3: 180}
const SCORE_KEYS := {KEY_1: 1, KEY_2: 2, KEY_3: 3, KEY_4: 4, KEY_5: 5}

## Keuzes van het debugmenu; blijven staan bij een herstart van de scène.
static var chosen_tail := 120
static var chosen_echo_on := true
static var chosen_log_on := true

## --- Instellingen vóór `_ready` (tests, gescripte runs) ---
## Inputbron voor P1 (`sample(tick) -> int`); null = InputRouter plaats 1.
var input_override: RefCounted = null
## Staart D; -1 = de keuze van het debugmenu.
var tail := -1
var echo_on := true
## CSV opslaan bij RUN_EIND (in `user://`).
var autosave := true
## Map voor de CSV.
var log_dir := "user://"
var show_hud := true

## --- Toestand ---
var sim: Sim
var p1: PlayerActor
var p2: PlayerActor
var echo: TailEcho
var meter: LightMeter
var gemaal: Gemaal
var pomprad: Pomprad
var meetlog: FlowMeetlog
var room := "K1"
## Kamerwissels van P1 (E-04e), als [tick, van, naar].
var room_changes: Array = []
## Golf in K2: 0 = nog niet begonnen, 1, 2; daarna terugkeren.
var wave := 0
## Aantal keer dat P1 K2 binnenkwam ná golf 2 (FK-2: ≤ 4 zonder echo).
var k2_returns := 0
var enemies: Array[CombatTarget] = []
var armored: CombatTarget = null
var run_over := false
var end_tick := -1
var csv_path := ""
var coop_seen := false

var _level: Node2D
var _b3_nodes: Array[Node] = []
var _sluice: StaticBody2D
var _wave_basics: Array[CombatTarget] = []
var _hud: CanvasLayer
var _hud_label: Label
var _hud_bar: ColorRect
var _hud_fill: ColorRect
var _camera: Camera2D
var _scores: Array = []
var _k3_tint: Polygon2D
var _overlay: Node2D


func _ready() -> void:
	if tail < 0:
		tail = chosen_tail
		echo_on = chosen_echo_on
		autosave = autosave and chosen_log_on
	_level = Node2D.new()
	_level.name = "Level"
	add_child(_level)
	_build_backdrop()
	_build_level()
	sim = Sim.new()
	sim.name = "Sim"
	add_child(sim)
	sim.combat.tail_ticks = tail  # merk-levensduur D + 30, ook zonder echo (C-12e)
	p1 = PlayerActor.new()
	p1.setup(1, input_override if input_override else _router_source(1), P1_COLOR)
	p1.position = Layout.RUN_START
	sim.add_player(p1)
	p1.health_changed.connect(_on_health_changed)
	if echo_on:
		_add_echo()
	meter = LightMeter.new(sim, p1)
	_build_gemaal()
	meetlog = FlowMeetlog.new(sim, p1, echo, room)
	meter.filled.connect(func(t: int, amount: int, _added: int, source: String, who: String) -> void:
		meetlog.add_row(t, "LP", "+%d" % amount, "%s_%s" % [source, who], p1.position))
	gemaal.pumped.connect(func(t: int, amount: int, who: String) -> void:
		meetlog.add_row(t, "POMP", str(amount), who, pomprad.position))
	gemaal.full.connect(func(t: int) -> void:
		meetlog.add_row(t, "GEMAAL_VOL", "", "", pomprad.position)
		if _k3_tint:
			_k3_tint.color = Color(0.45, 0.35, 0.2, 0.35))
	sim.tick_finished.connect(_on_tick)
	# C-06: werkaanname T16c: de onderrand is die van het hele gebied (K2 gaat
	# open over in K3, dus een val van K2 naar K3 is geen val uit de kamer).
	sim.room_bottom = Layout.K1.end.y
	sim.partner_dissolved.connect(func(t: int, at: Vector2, cause: String) -> void:
		meetlog.add_row(t, "P2_OPGELOST", "", cause, at))
	sim.partner_returned.connect(func(t: int, at: Vector2) -> void:
		meetlog.add_row(t, "P2_TERUG", "", "", at))
	var router := _router()
	if router and input_override == null:
		router.slot_joined.connect(_on_slot_joined)
		router.slot_left.connect(_on_slot_left)
	_camera = Camera2D.new()
	_camera.zoom = Vector2(2, 2)  # 640 × 360 wereldpixels in het venster van 1280 × 720
	_camera.limit_left = 0
	_camera.limit_top = 0
	_camera.limit_right = int(Layout.K3.end.x)
	_camera.limit_bottom = 720
	_camera.position = p1.position
	add_child(_camera)
	if show_hud:
		_build_hud()
		# Merken en de vulstand van het gemaal in de wereld (placeholder, O-2).
		_overlay = Node2D.new()
		_overlay.name = "Overlay"
		_overlay.z_index = 10
		_overlay.draw.connect(_draw_overlay)
		add_child(_overlay)


func _process(_delta: float) -> void:
	if _camera and is_instance_valid(p1):
		var focus := p1.position
		var zoom := 2.0
		if p2 and is_instance_valid(p2) and not p2.dissolved:
			# C-07: beide in beeld tot de maximale zoom-uit (leash_view_px,
			# werkaanname); daarbuiten volgt de camera P1 en loopt de leiband.
			var view: Array = Tuning.coop()["leash_view_px"]
			var gap := (p2.position - p1.position).abs() + Vector2(64, 64)
			zoom = clampf(minf(1280.0 / gap.x, 720.0 / gap.y), 1280.0 / float(view[0]), 2.0)
			var half := Vector2(640, 360) / zoom
			focus = (p1.position + p2.position) * 0.5
			focus = focus.clamp(p1.position - half + Vector2(32, 32), p1.position + half - Vector2(32, 32))
		_camera.zoom = Vector2(zoom, zoom)
		_camera.position = focus
	if _hud_label:
		_update_hud()
	if _overlay:
		_overlay.queue_redraw()


## Duur van de run in ticks (tot nu, of tot RUN_EIND).
func run_ticks() -> int:
	var last := end_tick if end_tick >= 0 else sim.tick
	return last - meetlog._start_tick


# --- Opbouw ---

func _build_level() -> void:
	for spec: Array in Layout.blocks(tail):
		var body := SpikeWorld.add_block(_level, spec[0], (spec[1] as Rect2).get_center(),
			(spec[1] as Rect2).size, 1, spec[2])
		_tint(body, ONE_WAY_COLOR if spec[2] else BLOCK_COLOR)
		if str(spec[0]).begins_with("B3"):
			_b3_nodes.append(body)
	_sluice = SpikeWorld.add_block(_level, "Sluis", Layout.SLUICE.get_center(), Layout.SLUICE.size)
	_tint(_sluice, Color(0.3, 0.3, 0.32))


## Achtergrond per kamer (grijs; K3 wordt warm na het gemaal, LM-06).
func _build_backdrop() -> void:
	var shades := {"K1": Color(0.13, 0.13, 0.15), "K2": Color(0.15, 0.14, 0.15), "K3": Color(0.12, 0.13, 0.15)}
	for key: String in Layout.ROOMS:
		var r: Rect2 = Layout.ROOMS[key]
		var poly := Polygon2D.new()
		poly.name = "Achtergrond" + key
		poly.polygon = PackedVector2Array([r.position, Vector2(r.end.x, r.position.y), r.end,
			Vector2(r.position.x, r.end.y)])
		poly.color = shades[key]
		_level.add_child(poly)
		if key == "K3":
			_k3_tint = Polygon2D.new()
			_k3_tint.polygon = poly.polygon
			_k3_tint.color = Color(0, 0, 0, 0)
			_level.add_child(_k3_tint)


func _build_gemaal() -> void:
	pomprad = Pomprad.new()
	pomprad.setup_pomprad()
	pomprad.position = Layout.POMPRAD_AT
	sim.add_object(pomprad)
	gemaal = Gemaal.new()
	gemaal.setup_gemaal(meter, pomprad, _sluice, Layout.STREET, Layout.WATER_HIGH, Layout.WATER_LOW)
	gemaal.connect_combat(sim.combat)
	sim.add_object(gemaal)


func _tint(body: Node, color: Color) -> void:
	for child in body.get_children():
		if child is Polygon2D:
			(child as Polygon2D).color = color


func _add_echo() -> void:
	echo = TailEcho.new()
	echo.setup(p1, ECHO_COLOR, tail, sim.tick)
	if not sim.add_echo(echo):
		echo.free()
		echo = null


func _router() -> Node:
	return get_node_or_null("/root/InputRouter")


func _router_source(slot: int) -> RefCounted:
	var router := _router()
	if router:
		return router.source_for(slot)
	return preload("res://scripts/input/device_input.gd").new(slot)


# --- Per tick ---

func _on_tick(tick: int) -> void:
	var now := Layout.room_of(p1.position)
	if now != room:
		room_changes.append([tick, room, now])
		var came_from := room
		room = now
		meetlog.room = now
		meetlog.add_row(tick, "KAMER", "", now, p1.position)
		if now == "K2":
			_on_enter_k2()
		elif now == "K1" and came_from == "K3" and gemaal.full_tick >= 0 and not run_over:
			_finish_run(tick)
	if wave == 1 and _all_dead(_wave_basics):
		_spawn_wave_2()


func _on_enter_k2() -> void:
	if wave == 0:
		wave = 1
		_wave_basics = _spawn_basics(Layout.WAVE_1)
	elif wave == 2 and gemaal.full_tick < 0:
		k2_returns += 1
		# De basisvijanden van golf 2 komen terug (een levend exemplaar blijft staan).
		var xs: Array = []
		for i in Layout.WAVE_2.size():
			if i >= _wave_basics.size() or not _wave_basics[i].alive:
				xs.append(Layout.WAVE_2[i])
		var fresh := _spawn_basics(xs)
		var merged: Array[CombatTarget] = []
		for e in _wave_basics:
			if e.alive:
				merged.append(e)
		merged.append_array(fresh)
		_wave_basics = merged


func _spawn_wave_2() -> void:
	wave = 2
	_wave_basics = _spawn_basics(Layout.WAVE_2)
	armored = _spawn(CombatTarget.Kind.ARMORED, Layout.ARMORED_X)


func _spawn_basics(xs: Array) -> Array[CombatTarget]:
	var out: Array[CombatTarget] = []
	for x: float in xs:
		out.append(_spawn(CombatTarget.Kind.ENEMY, x))
	return out


func _spawn(kind: CombatTarget.Kind, x: float) -> CombatTarget:
	var enemy := FlowEnemy.new()
	enemy.setup_target(kind)
	enemy.position = Vector2(x, Layout.K2_FLOOR - 12.0)
	enemy.min_x = Layout.K2_LEFT + 8.0
	enemy.max_x = Layout.K2_HOLE.position.x - 8.0
	enemy.is_awake = func() -> bool: return room == "K2"
	enemy.name = "Vijand%d" % enemies.size()
	sim.add_object(enemy)
	enemies.append(enemy)
	return enemy


func _all_dead(list: Array[CombatTarget]) -> bool:
	for e in list:
		if e.alive:
			return false
	return not list.is_empty()


## LM-05: 0 levenspunten = respawn op het begin van de kamer, L en G gelijk.
func _on_health_changed(_tick: int, health: int) -> void:
	if health <= 0:
		p1.respawn_at(Layout.ROOM_START[room], true)  # C-08: P2 respawnt mee
		p1.health = int(Tuning.combat()["p1_health"])


func _finish_run(tick: int) -> void:
	run_over = true
	end_tick = tick
	meetlog.finish()
	if autosave:
		save_log()
	run_finished.emit(tick)


## Bestandsnaam volgens §4.5: `meetlog_<datum>_<solo|coop>_D<D>_<speler>.csv`.
func log_file_name() -> String:
	var stamp := Time.get_datetime_string_from_system(false, false).replace("-", "").replace(":", "").replace("T", "-")
	return "meetlog_%s_%s_D%d_p1.csv" % [stamp, "coop" if coop_seen else "solo", tail]


func save_log() -> Error:
	if csv_path.is_empty():
		csv_path = log_dir.path_join(log_file_name())
	var err := meetlog.save(csv_path)
	if err == OK:
		print("Meetlog opgeslagen: %s" % ProjectSettings.globalize_path(csv_path))
	return err


# --- Co-op: InputRouter -> drop-in en drop-out (C-03, C-05) ---

func _on_slot_joined(slot: int, _device: String) -> void:
	if slot != 2 or p2 != null:
		return
	join_partner(_router_source(2))


func _on_slot_left(slot: int, reason: String) -> void:
	if slot != 2 or p2 == null:
		return
	leave_partner("apparaat" if reason.begins_with("apparaat") else reason)


## C-03: P2 doet mee met deze inputbron (ook voor headless tests). Neemt de
## echo over als die afspeelt, anders de plaatsingsregel. Tussen twee ticks.
func join_partner(source: RefCounted) -> bool:
	if p2 != null:
		return false
	var partner := PlayerActor.new()
	partner.setup(2, source, P2_COLOR)
	if not sim.drop_in(partner):
		partner.free()
		return false
	p2 = partner
	echo = null  # de Sim heeft hem weggehaald (C-01)
	meter.coop = true
	coop_seen = true
	meetlog.add_row(sim.tick, "DROP_IN", "", "", p2.position)
	return true


## C-05: P2 lost op; de echo van P1 neemt over (als de echo aan staat).
func leave_partner(reason: String) -> void:
	if p2 == null:
		return
	meetlog.add_row(sim.tick, "DROP_OUT", "", reason, p2.position)
	var new_echo: TailEcho = sim.drop_out(ECHO_COLOR)
	p2 = null
	meter.coop = false
	if new_echo and not echo_on:
		sim.remove_echo(new_echo)
		new_echo = null
	echo = new_echo
	if echo:
		meetlog.watch_echo(echo)


# --- Debugmenu en score ---

func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey) or not event.pressed or event.echo:
		return
	var key: int = (event as InputEventKey).physical_keycode
	if DEBUG_TAIL_KEYS.has(key):
		chosen_tail = DEBUG_TAIL_KEYS[key]
		_restart()
	elif key == KEY_F4:
		chosen_echo_on = not chosen_echo_on
		_restart()
	elif key == KEY_F5:
		chosen_log_on = not chosen_log_on
		autosave = chosen_log_on
	elif key == KEY_F6:
		_restart()
	elif run_over and SCORE_KEYS.has(key) and _scores.size() < 3:
		var room_name: String = ["K1", "K2", "K3"][_scores.size()]
		_scores.append(SCORE_KEYS[key])
		meetlog.add_score(sim.tick, room_name, SCORE_KEYS[key])
		if _scores.size() == 3 and autosave:
			save_log()


func _restart() -> void:
	if meetlog and not meetlog.is_closed() and autosave:
		# Een afgebroken run wordt ook bewaard (zonder GEMAAL_VOL), als bewijs.
		meetlog.finish()
		csv_path = log_dir.path_join(log_file_name().replace(".csv", "_afgebroken.csv"))
		save_log()
	get_tree().reload_current_scene()


# --- Placeholder-HUD (§4.1; eindvorm T10) ---

## Merk = lichtvonk met een ring die de laatste 60 ticks krimpt (E-14b, i);
## naast het pomprad een balk met G.
func _draw_overlay() -> void:
	var countdown := int(Tuning.combat()["mark_countdown_ticks"])
	for mark in sim.combat.marks:
		if not mark.alive:
			continue
		var at: Vector2 = mark.center() + Vector2(0, -20)
		var left := mark.expires - sim.tick
		_overlay.draw_circle(at, 2.5, Color(1.0, 0.95, 0.7))
		var r := 7.0 if left > countdown else 7.0 * maxf(left, 0) / countdown
		_overlay.draw_arc(at, maxf(r, 1.0), 0.0, TAU, 20, Color(1.0, 0.9, 0.5), 1.0)
	var base := Layout.POMPRAD_AT + Vector2(22, 24)
	_overlay.draw_rect(Rect2(base + Vector2(0, -48), Vector2(4, 48)), Color(0.1, 0.1, 0.1))
	var h := 48.0 * gemaal.fill / 100.0
	_overlay.draw_rect(Rect2(base + Vector2(0, -h), Vector2(4, h)), Color(1.0, 0.85, 0.4))


func _build_hud() -> void:
	_hud = CanvasLayer.new()
	add_child(_hud)
	_hud_bar = ColorRect.new()
	_hud_bar.position = Vector2(16, 16)
	_hud_bar.size = Vector2(204, 16)
	_hud_bar.color = Color(0.1, 0.1, 0.1)
	_hud.add_child(_hud_bar)
	_hud_fill = ColorRect.new()
	_hud_fill.position = Vector2(18, 18)
	_hud_fill.size = Vector2(0, 12)
	_hud_fill.color = Color(1.0, 0.85, 0.4)
	_hud.add_child(_hud_fill)
	_hud_label = Label.new()
	_hud_label.position = Vector2(16, 36)
	_hud.add_child(_hud_label)


func _update_hud() -> void:
	_hud_fill.size.x = 2.0 * meter.value
	var echo_state := "uit"
	if p2:
		echo_state = "P2 doet mee"
	elif echo:
		echo_state = "Actief" if echo.is_present() else "Leeg"
	var lines := PackedStringArray([
		"Licht %d / 100   Gemaal G %d / 100   Leven %d" % [meter.value, gemaal.fill, p1.health],
		"Kamer %s   D = %d   echo %s   tijd %.1f s" % [room, tail, echo_state, run_ticks() / 60.0],
		"F1/F2/F3 D 90/120/180 · F4 echo aan/uit · F5 meetlog %s · F6 herstart" % ("aan" if autosave else "uit"),
	])
	if run_over:
		if _scores.size() < 3:
			lines.append("Run klaar in %.1f s. Voelde %s vloeiend/satisfying? Druk 1–5." % [
				run_ticks() / 60.0, ["K1", "K2", "K3"][_scores.size()]])
		else:
			lines.append("Bedankt. Meetlog: %s" % csv_path)
	_hud_label.text = "\n".join(lines)
