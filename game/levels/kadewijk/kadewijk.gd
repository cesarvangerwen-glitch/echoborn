extends Node2D
## De Kadewijk (wijk 1.3), deel 1: S1–S4 als grijze, speelbare kamers op
## placeholder (T8a, #83; `docs/design/wereld.md` §2.2, kamerdoc
## `docs/design/kamers/kadewijk.md`).
##
## Een gebiedsscène met de systemen van T5b (ontwerp.md §3a, §7): elke kamer
## is een `Kamer` met meestreamende inhoud (`s*_*.tscn`), de `AreaLoader`
## laadt de kamer van P1 en zijn buren, `Progress` bewaart het checkpoint
## (S1, SL-03: vóór het gemaal is S1 de respawnplek) en `Respawn` zet P1 bij 0
## levenspunten terug. De vijanden zijn `SliceEnemy`s in de inhoud, geplaatst
## volgens `slice-vijanden-en-boss.md` §2.6; hun paren (VJ-05) zet dit script
## bij het laden (`make_pair`; een `@export` voor de paargenoot volgt van de
## Gameplay Programmer, ontwerp.md §12).
##
## Wat dit script als level-script doet (de regels staan in het kamerdoc §4):
## - **Wekken**: een vijand doet pas mee als P1 in zijn kamer op zijn vloer
##   staat, binnen een half scherm (`WAKE_DX`); daarna tot P1 de kamer verlaat.
##   Zo loopt hij niet door een andere kamer of over een andere verdieping mee.
## - **Golven in S3** (L-13): golf 2 doet pas mee als elke Kadeloper van golf 1
##   een merk heeft of op is, en er dan hooguit 5 vijanden tegelijk zijn (L-13 f).
## - **Meetlog** (gdd §4.5): `RUN_START` in S1, `KAMER`, `LP`, `P2_*`,
##   `RUN_EIND` als P1 het einde van deel 1 haalt (S4, `Layout.END_X`).
##
## Debugmenu (SL-05, placeholder): F1/F2/F3/F7 = D 60/90/120/180 (uit
## `echo.tail_options`; de kamers worden opnieuw gebouwd), F4 = echo aan/uit,
## F6 = opnieuw, F8 = naar het begin van de volgende kamer.

signal run_finished(tick: int)

const Sim = preload("res://scripts/sim.gd")
const PlayerActor = preload("res://scripts/echo/player_actor.gd")
const TailEcho = preload("res://scripts/echo/tail_echo.gd")
const Tuning = preload("res://scripts/echo/tuning.gd")
const AreaLoader = preload("res://scripts/world/area_loader.gd")
const Respawn = preload("res://scripts/save/respawn.gd")
const LightMeter = preload("res://scripts/light/light_meter.gd")
const SliceEnemy = preload("res://scripts/combat/slice_enemy.gd")
const EnemyData = preload("res://scripts/combat/enemy_data.gd")
const Checkpoint = preload("res://scripts/save/checkpoint.gd")
const EchoHints = preload("res://scripts/echo/echo_hints.gd")
const Layout = preload("res://levels/kadewijk/kadewijk_layout.gd")
const Inhoud = preload("res://levels/kadewijk/kadewijk_inhoud.gd")
## Meetlog en camera van de flow-kamer, ongewijzigd hergebruikt (alleen gelezen).
const FlowMeetlog = preload("res://levels/flowkamer/flow_meetlog.gd")
const FlowRoom = preload("res://levels/flowkamer/flow_room.gd")

const GEBIED := &"kadewijk"
const P1_COLOR := Color(1.0, 0.85, 0.4)
const P2_COLOR := Color(0.5, 0.85, 1.0)
const ECHO_COLOR := Color(0.42, 0.36, 0.7, 0.85)
const DEBUG_TAIL_KEYS := {KEY_F1: 0, KEY_F2: 1, KEY_F3: 2, KEY_F7: 3}
## Wekken: P1 op de vloer van de vijand (voeten ± 40 px) en binnen een half scherm.
const WAKE_DY := 40.0
const WAKE_DX := 320.0
## L-13 (f): hooguit zoveel vijanden tegelijk in beeld.
const MAX_AT_ONCE := 5

static var chosen_tail := int(Tuning.echo()["tail_ticks"])
static var chosen_echo_on := true

## --- Instellingen vóór `_ready` (tests, gescripte runs) ---
var input_override: RefCounted = null
var tail := -1
var echo_on := true
var show_hud := true
## Waar P1 begint (standaard S1; tests per kamer: `Layout.ROOM_START`).
var start_at := Layout.RUN_START
## `Progress` voor deze scène; null = de autoload. Een test geeft een eigen node.
var progress: Node = null

## --- Toestand ---
var sim: Sim
var p1: PlayerActor
var p2: PlayerActor
var echo: TailEcho
var meter: LightMeter
var loader: AreaLoader
var respawn: Respawn
var meetlog: FlowMeetlog
var hints: EchoHints
var room: StringName = &""
var run_over := false
var end_tick := -1
## Fouten van `AreaLoader.start` en `Progress.bind_area_loader` (leeg = goed).
var start_errors := PackedStringArray()
## S3: 0 = nog niet begonnen, 1, 2.
var wave := 0
var wave_2_tick := -1
## Grootste aantal levende, meedoende vijanden tegelijk in de kamer van P1 (L-13 f).
var most_at_once := 0
## Kamerwissels van P1 als [tick, van, naar].
var room_changes: Array = []

var _awake: Dictionary = {}
var _wave_1: Array = []
var _wave_2: Array = []
var _camera: Camera2D
var _hud_label: Label


func _ready() -> void:
	if tail < 0:
		tail = chosen_tail
		echo_on = chosen_echo_on
	if progress == null:
		progress = get_node_or_null(^"/root/Progress")
	Inhoud.tail = tail
	sim = Sim.new()
	sim.name = "Sim"
	add_child(sim)
	sim.combat.tail_ticks = tail
	p1 = PlayerActor.new()
	p1.setup(1, input_override if input_override else _router_source(1), P1_COLOR)
	p1.position = start_at
	sim.add_player(p1)
	if echo_on:
		echo = TailEcho.new()
		echo.setup(p1, ECHO_COLOR, tail, sim.tick)
		if not sim.add_echo(echo):
			echo.free()
			echo = null
	meter = LightMeter.new(sim, p1)
	loader = AreaLoader.new()
	loader.name = "AreaLoader"
	add_child(loader)
	loader.collect(self)
	sim.set_area_loader(loader)
	loader.geladen_gewijzigd.connect(_on_loaded_changed)
	loader.kamer_gewisseld.connect(_on_room_changed)
	if progress != null:
		start_errors.append_array(progress.bind_area_loader(loader, GEBIED))
		progress.bind_meter(meter)
	sim.room_bottom = Layout.ROOM_H + 40.0
	start_errors.append_array(loader.start(sim.tick, p1.position))
	room = loader.huidige
	respawn = Respawn.new(p1, func() -> Vector2: return Layout.ROOM_START.get(loader.huidige, Layout.RUN_START), progress)
	meetlog = FlowMeetlog.new(sim, p1, echo, String(room))
	meter.filled.connect(func(t: int, amount: int, _added: int, source: String, who: String) -> void:
		meetlog.add_row(t, "LP", "+%d" % amount, "%s_%s" % [source, who], p1.position))
	sim.partner_dissolved.connect(func(t: int, at: Vector2, cause: String) -> void:
		meetlog.add_row(t, "P2_OPGELOST", "", cause, at))
	sim.partner_returned.connect(func(t: int, at: Vector2) -> void:
		meetlog.add_row(t, "P2_TERUG", "", "", at))
	sim.tick_finished.connect(_on_tick)
	hints = EchoHints.new(sim, p1, func() -> Node2D: return echo)
	var router := get_node_or_null(^"/root/InputRouter")
	if router and input_override == null:
		router.slot_joined.connect(func(slot: int, _device: String) -> void:
			if slot == 2 and p2 == null:
				join_partner(_router_source(2)))
		router.slot_left.connect(func(slot: int, reason: String) -> void:
			if slot == 2 and p2 != null:
				leave_partner("apparaat" if reason.begins_with("apparaat") else reason))
	_camera = Camera2D.new()
	_camera.limit_left = 0
	_camera.limit_top = -20
	_camera.limit_right = int(Layout.AREA_RIGHT)
	_camera.limit_bottom = int(Layout.ROOM_H)
	_camera.position = p1.position
	add_child(_camera)
	if show_hud:
		var hud := CanvasLayer.new()
		add_child(hud)
		_hud_label = Label.new()
		_hud_label.position = Vector2(16, 16)
		hud.add_child(_hud_label)
	for e in start_errors:
		push_error("Kadewijk: %s" % e)


func _process(delta: float) -> void:
	if _camera and is_instance_valid(p1):
		var with_p2 := p2 != null and is_instance_valid(p2) and not p2.dissolved
		var view := FlowRoom.camera_view(p1.position, p2.position if with_p2 else p1.position)
		var size := get_viewport().get_visible_rect().size
		var zoom := FlowRoom.camera_zoom(view, size if size.x > 0.0 else FlowRoom.BASE_VIEW_PX)
		_camera.zoom = Vector2(zoom, zoom)
		_camera.position = _camera.position.lerp(view.get_center(), 1.0 - exp(-8.0 * delta))
	if _hud_label:
		# Placeholder (T10 maakt de eindvorm); sleutels van de flow-kamer, `strings.csv`.
		# Nog geen gemaal in deel 1: G = 0. Debugtoetsen: zie de kop van dit script.
		var echo_state := tr("HUD_ECHO_OFF")
		if p2:
			echo_state = tr("HUD_ECHO_P2")
		elif echo:
			echo_state = tr("HUD_ECHO_ACTIVE") if echo.is_present() else tr("HUD_ECHO_EMPTY")
		_hud_label.text = "\n".join(PackedStringArray([tr("HUD_STATUS") % [meter.value, 0, p1.health],
			tr("HUD_ROOM") % [room, tail, echo_state, run_ticks() / 60.0]]))


func run_ticks() -> int:
	return (end_tick if end_tick >= 0 else sim.tick) - meetlog._start_tick


# --- Laden en kamers ---

## Een kamer laadt of ontlaadt (in `sim_track` of `start`, nooit in stap 4/5).
func _on_loaded_changed(_tick: int, id: StringName, geladen: bool) -> void:
	var kamer = loader.kamers[id]
	if not geladen:
		if id == &"S3":
			_wave_1 = []
			_wave_2 = []
			wave = 0
		return
	var inhoud: Node = kamer.inhoud_node
	if inhoud == null:
		return
	for node in inhoud.find_children("*", "", true, false):
		if node is Checkpoint:
			node.progress = progress
		# Wekken: een vijand die net laadt, slaapt tot `_wake` hem ziet (ook in stap 5 van deze tick).
		if node is SliceEnemy and not _awake.has(node):
			node.hold_until(sim.tick + 2)
	match id:
		&"S2":
			_pair(inhoud, ^"Paar1A", ^"Paar1B", "paar_e")
		&"S3":
			_pair(inhoud, ^"Golf1/Paar1A", ^"Golf1/Paar1B", "paar_e")
			_pair(inhoud, ^"Golf2/Paar1A", ^"Golf2/Paar1B", "paar_e")
			_wave_1 = inhoud.get_node(^"Golf1").get_children()
			_wave_2 = inhoud.get_node(^"Golf2").get_children()
			wave = 0
			# Golf 2 doet nog niet mee: niet bij de Sim en niet in beeld.
			for e in _wave_2:
				sim.remove_object(e)
				e.visible = false


## VJ-05: een paar met de startafstand uit `slice.csv` (`paar_e` = 28, `paar_k` = 42).
func _pair(inhoud: Node, a: NodePath, b: NodePath, key: String) -> void:
	SliceEnemy.make_pair(inhoud.get_node(a), inhoud.get_node(b), EnemyData.value("gedeeld", key))


func _on_room_changed(tick: int, van: StringName, naar: StringName, _reset: bool) -> void:
	room_changes.append([tick, van, naar])
	room = naar
	meetlog.room = String(naar)
	meetlog.add_row(tick, "KAMER", "", String(naar), p1.position)


## Vijanden die nu meedoen (bij de Sim, levend), in de kamer `id`.
func enemies_in(id: StringName) -> Array:
	var out: Array = []
	for object in sim.objects:
		if object is SliceEnemy and object.alive and Layout.room_of(object.start_position) == id:
			out.append(object)
	return out


func is_awake(enemy: Node2D) -> bool:
	return _awake.has(enemy)


# --- Per tick ---

func _on_tick(tick: int) -> void:
	_wake(tick)
	if room == &"S3":
		if wave == 0:
			wave = 1
		elif wave == 1 and _wave_1_marked_or_dead() and _alive_count(&"S3") + _alive(_wave_2).size() <= MAX_AT_ONCE:
			wave = 2
			wave_2_tick = tick
			for e in _alive(_wave_2):
				e.visible = true
				sim.add_object(e)
	most_at_once = maxi(most_at_once, _alive_count(room))
	if not run_over and room == &"S4" and p1.position.x >= Layout.END_X:
		run_over = true
		end_tick = tick
		meetlog.add_row(tick, "RUN_EIND", "", "", p1.position)
		meetlog.finish()
		run_finished.emit(tick)


## Wekken (kamerdoc §4): wakker als P1 in de kamer op de vloer van de vijand
## staat en binnen `WAKE_DX`; slapen als P1 de kamer verlaat. Een slapende
## vijand doet niets (`hold_until`), raakbaar blijft hij.
func _wake(tick: int) -> void:
	var feet := p1.position.y + Layout.HALF_H
	for object in sim.objects:
		if not (object is SliceEnemy) or not object.alive:
			continue
		var enemy: Node2D = object
		var own := Layout.room_of(enemy.start_position)
		if own != room:
			_awake.erase(enemy)
		elif not _awake.has(enemy):
			var enemy_feet: float = enemy.position.y + enemy.body_size().y * 0.5
			if absf(feet - enemy_feet) <= WAKE_DY and absf(p1.position.x - enemy.position.x) <= WAKE_DX:
				_awake[enemy] = tick
		if not _awake.has(enemy):
			enemy.hold_until(tick + 2)


func _wave_1_marked_or_dead() -> bool:
	if _wave_1.is_empty():
		return false
	for e in _wave_1:
		if is_instance_valid(e) and e.alive and sim.objects.has(e) and sim.combat.mark_on(e) == null:
			return false
	return true


func _alive(list: Array) -> Array:
	var out: Array = []
	for e in list:
		if is_instance_valid(e) and e.alive:
			out.append(e)
	return out


func _alive_count(id: StringName) -> int:
	return enemies_in(id).size()


# --- Co-op (C-03, C-05), zoals de flow-kamer ---

func join_partner(source: RefCounted) -> bool:
	if p2 != null:
		return false
	var partner := PlayerActor.new()
	partner.setup(2, source, P2_COLOR)
	if not sim.drop_in(partner):
		partner.free()
		return false
	p2 = partner
	echo = null
	meter.coop = true
	meetlog.add_row(sim.tick, "DROP_IN", "", "", p2.position)
	return true


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


func _router_source(slot: int) -> RefCounted:
	var router := get_node_or_null(^"/root/InputRouter")
	if router:
		return router.source_for(slot)
	return preload("res://scripts/input/device_input.gd").new(slot)


# --- Debugmenu (SL-05, placeholder) ---

func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey) or not event.pressed or event.echo:
		return
	var key: int = (event as InputEventKey).physical_keycode
	if DEBUG_TAIL_KEYS.has(key):
		chosen_tail = int(Tuning.echo()["tail_options"][DEBUG_TAIL_KEYS[key]])
		get_tree().reload_current_scene()
	elif key == KEY_F4:
		chosen_echo_on = not chosen_echo_on
		get_tree().reload_current_scene()
	elif key == KEY_F6:
		get_tree().reload_current_scene()
	elif key == KEY_F8:
		var i := Layout.ORDER.find(room)
		var next: StringName = Layout.ORDER[(i + 1) % Layout.ORDER.size()]
		p1.respawn_at(Layout.ROOM_START[next])
