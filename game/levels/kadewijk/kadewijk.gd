extends Node2D
## De Kadewijk (wijk 1.3): S1–S8 als grijze, speelbare kamers op placeholder
## (T8a, #83; deel 1 S1–S4, deel 2 S5–S8; `docs/design/wereld.md` §2.2,
## kamerdoc `docs/design/kamers/kadewijk.md`). S8 is de arena van de
## Gemaalmeester (`gemaalmeester.gd` op `Layout.ARENA_ORIGIN`).
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
## - **Meetlog** (gdd §4.5): `RUN_START` in S1, `KAMER`, `LP`, `P2_*`, `POMP`
##   en `GEMAAL_VOL` (S6), `LUIK` (S7, S9), de verzamelobjecten (`LAMPGLAS`,
##   `LOGBLAD` n, `VAARDIGHEID` V-01), `TRAP_VOL` 2 en `WATERSTAND` 2,
##   `SLICE_EIND`, en `RUN_EIND`: bij `run_end` = S4 als P1 het einde van
##   deel 1 haalt (`Layout.END_X`), bij `RUN_END_BOSS` op `BOSS_VERSLAGEN`,
##   bij `RUN_END_LUS` op `SLICE_EIND`, anders als P1 kamer `run_end` binnenkomt.
## - **Verzamelobjecten en de sokkel** (WS-08, L-12, #83): `Pickup`s in de
##   inhoud (`scripts/objects/pickup.gd`): het lampglas (S5, +1 maximum
##   levenspunt, LM-07), logbladzijde 1–3 (S5, S6, S9) en de Neerslag op de
##   sokkel (S7; daarna `Art/Objecten.set_sokkel_aan(false)`, #244). Opgepakt
##   blijft opgepakt (een vlag in de save).
## - **Trap 2 en `s = 2`** (SL-02, LM-08, LM-10, WS-03): het gemaal van S6 heeft
##   twee trappen en pompt tot `BOSS_VERSLAGEN` niet verder dan G = 100
##   (`boss_cap`). Is trap 2 vol, dan zakt het water van de wijk in 180 ticks
##   naar `s = 2` en daarna gaat het `Hoogwater` van S9 open
##   (`set_door(&"S9", "Hoogwater", false)`; LM-10: een doorgang opent op het
##   eind van het zakken). Ook na laden uit een save (vulstand 200).
## - **`SLICE_EIND`** (gdd §4.5): het object `S1/SliceEind` meldt het als P1 van
##   S9 door het snelluik op de gang van S1 staat.
## - **S6**: het gemaal (`S6/Gemaal`, de `wijk_gemaal` van elke kamer), de
##   pompgang en het K-paar; **S7**: het luik (de banen van de Dwaallichten
##   staan in de scène).
## - **S8, de Gemaalmeester** (#83, gemaalmeester.md GM-01, GM-10, GM-11): als
##   S8 laadt, staat de boss op `Layout.ARENA_ORIGIN` (breedte `ARENA_W`); als
##   S8 ontlaadt, gaat hij weg (`Boss.detach`). `BOSS_START` (P1 en de echo of
##   P2 helemaal in de arena, anders breekt de echo op de deur) sluit
##   `DeurRechts`, `BOSS_VERSLAGEN` opent `DeurLinks` (naar S9), beide met
##   `set_door`; een reset (P1 respawnt in een buurkamer) opent
##   `DeurRechts` weer. Bij 0 levenspunten respawnt P1 op het checkpoint (na de
##   eerste pompslag dat van het gemaal, S6); S8 ontlaadt dan en de boss begint
##   opnieuw als P1 terugkomt. Verslagen blijft verslagen: `boss_defeated_tick`
##   in de scène en de vlag `S8/BossVerslagen` in de save (`staat_vlag.gd`). Meetlog: de events van de
##   boss (`watch_boss`); de lichtmeter gaat bij `BOSS_VERSLAGEN` naar 100 LP.
##
## Debugmenu (SL-05, placeholder): F1/F2/F3/F7 = D 60/90/120/180 (uit
## `echo.tail_options`; de kamers worden opnieuw gebouwd), F4 = echo aan/uit,
## F6 = opnieuw, F8 = naar het begin van de volgende kamer. F8, F4 en de
## D-toetsen zetten een regel `DEBUG` in het meetlog (V-7, #250).
##
## Meetlog naar schijf (V-6, #250): als deze scène de hoofdscène van de run is
## (de start voor de CEO, `docs/tools/kadewijk-meetlog.md`), schrijft
## `kadewijk_meetlog_csv.gd` de CSV bij `RUN_EIND` en bij afbreken.

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
const Gemaal = preload("res://scripts/light/gemaal.gd")
const Luik = preload("res://scripts/objects/luik.gd")
const Gemaalmeester = preload("res://scripts/combat/gemaalmeester.gd")
const Pickup = preload("res://scripts/objects/pickup.gd")
const StaatVlag = preload("res://scripts/objects/staat_vlag.gd")
const SliceEind = preload("res://levels/kadewijk/kadewijk_slice_eind.gd")
const MeetlogCsv = preload("res://levels/kadewijk/kadewijk_meetlog_csv.gd")
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
## `run_end` voor een run tot en met de boss: `RUN_EIND` op `BOSS_VERSLAGEN`.
const RUN_END_BOSS := &"Gemaalmeester"
## BOSS_START als het middelpunt van P1 zo ver binnen de muren staat: het
## lichaam (16 px) is dan helemaal binnen als `DeurRechts` dichtgaat.
const BOSS_START_INSET := 24.0
## Objecten met een blijvende stand die deze scène ook leest als hun kamer niet
## geladen is (in de save: `<gebied>/<kamer>/<pad>`, `AreaLoader.object_flag`).
const BOSS_FLAG := [&"S8", ^"BossVerslagen"]
const LAMPGLAS_FLAG := [&"S5", ^"Lampglas"]
## De Neerslag op de sokkel (S7): de vlag is de vaardigheid V-01 (besluit LGD in #252).
const NEERSLAG_FLAG := [&"S7", ^"Neerslag"]
## Het gemaal van de wijk (S6), zoals in `state.gemalen`.
const GEMAAL_PATH := [&"S6", ^"Gemaal"]

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
## Waar de run eindigt (`RUN_EIND`): &"S4" = het einde van deel 1 (`END_X`),
## anders de kamer waar P1 binnenkomt (bv. &"S7": door de kelderingang, dus
## na het gemaal; &"S8": de arena).
var run_end: StringName = &"S4"
## `run_end` voor de lus (deel 3): `RUN_EIND` op `SLICE_EIND` (door S9 terug in S1).
const RUN_END_LUS := &"SLICE_EIND"

## Meetlog als CSV naar schijf (V-6): -1 = alleen als deze scène de
## `current_scene` is (F6 in de editor, de commandline), 0 = uit, 1 = aan.
var save_csv := -1
## Map voor de CSV.
var log_dir := "user://"

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
## S9 (deel 3): tick waarop P1 logbladzijde 3 haalde, of -1 (WS-08).
var logblad_3_tick := -1
## Per logbladzijde (nummer): de tick van oppakken in deze scène.
var logblad_ticks := {}
## S7: tick waarop de Neerslag (V-01) van de sokkel werd opgepakt, of -1.
var neerslag_tick := -1
## Tick van `SLICE_EIND`: P1 kwam door het snelluik van S9 en staat in de gang
## van S1 (de lus is rond, L-14 f), of -1.
var slice_end_tick := -1
## SL-02, LM-08: tick waarop trap 2 vol werd, of -1.
var trap_2_tick := -1
## LM-10: vanaf deze tick is de wijk op `s = 2` en is het `Hoogwater` van S9
## open (trap 2 + 180 ticks; 0 na laden uit een save), of -1.
var hoogwater_open_tick := -1
## Staat het `Hoogwater` nu open in de geladen S9?
var hoogwater_open := false
## S3: 0 = nog niet begonnen, 1, 2.
var wave := 0
var wave_2_tick := -1
## Grootste aantal levende, meedoende vijanden tegelijk in de kamer van P1 (L-13 f).
var most_at_once := 0
## Kamerwissels van P1 als [tick, van, naar].
var room_changes: Array = []
## Het gemaal van S6 als zijn kamer geladen is, anders null.
var gemaal: Gemaal = null
## Tick waarop P1 het lampglas (S5) haalde, of -1 (placeholder, WS-08).
var lampglas_tick := -1
## De Gemaalmeester als S8 geladen is en hij nog niet verslagen is, anders null.
var boss: Gemaalmeester = null
## Tick van `BOSS_VERSLAGEN`, of -1. Daarna komt de boss niet meer terug.
var boss_defeated_tick := -1
## Hoe vaak de boss in S8 werd neergezet (elke keer dat S8 laadt, tot hij verslagen is).
var boss_spawns := 0

var _awake: Dictionary = {}
## Meetlogrijen uit stap (5) (objecten), geschreven in `_on_tick` (zoals de
## placeholders van de WLD), als [tick, event, waarde, bron].
var _pending_rows: Array = []
var _slice_end_pending := -1
var _stand_2_logged := false
var _wave_1: Array = []
var _wave_2: Array = []
var _camera: Camera2D
var _hud_label: Label
## De CSV-schrijver (V-6), of null als de CSV uit staat.
var meetlog_csv: MeetlogCsv = null


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
	sim.room_bottom = Layout.AREA_BOTTOM + 40.0
	start_errors.append_array(loader.start(sim.tick, p1.position))
	room = loader.huidige
	respawn = Respawn.new(p1, func() -> Vector2: return Layout.ROOM_START.get(loader.huidige, Layout.RUN_START), progress)
	# Uit de save (LM-12): de Neerslag (V-01; zonder is AANVAL + DOWN een gewone aanval), het lampglas
	# (WS-08 a) en de waterstand (LM-10).
	sim.neerslag_unlocked = _saved_flag(NEERSLAG_FLAG)
	if _saved_flag(LAMPGLAS_FLAG):
		p1.max_health = mini(p1.max_health + 1, PlayerActor.HEALTH_CAP)
		p1.health = p1.max_health
	if _saved_vulstand() >= 2 * Gemaal.MAX:
		hoogwater_open_tick = 0
		_update_hoogwater(sim.tick)
	meetlog = FlowMeetlog.new(sim, p1, echo, String(room))
	if boss != null:
		meetlog.watch_boss(boss)
	meter.filled.connect(func(t: int, amount: int, _added: int, source: String, who: String) -> void:
		meetlog.add_row(t, "LP", "+%d" % amount, "%s_%s" % [source, who], p1.position))
	sim.partner_dissolved.connect(func(t: int, at: Vector2, cause: String) -> void:
		meetlog.add_row(t, "P2_OPGELOST", "", cause, at))
	sim.partner_returned.connect(func(t: int, at: Vector2) -> void:
		meetlog.add_row(t, "P2_TERUG", "", "", at))
	sim.tick_finished.connect(_on_tick)
	if save_csv == 1 or (save_csv < 0 and get_tree().current_scene == self):
		meetlog_csv = MeetlogCsv.new(self, log_dir)
		add_child(meetlog_csv)
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
	var area := Layout.area_rect()
	_camera.limit_left = int(area.position.x)
	_camera.limit_top = int(area.position.y) - 20
	_camera.limit_right = int(area.end.x)
	_camera.limit_bottom = int(area.end.y)
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
		var view := camera_view()
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
		_hud_label.text = "\n".join(PackedStringArray([tr("HUD_STATUS") % [meter.value, gemaal.fill if gemaal else 0, p1.health],
			tr("HUD_ROOM") % [room, tail, echo_state, run_ticks() / 60.0]]))


## Wat de camera laat zien (wereldpixels). Van `BOSS_START` tot `BOSS_VERSLAGEN` staat hij vast op
## de arena (GM-01, besluit LGD in #247): één scherm, beide muren, het rad en de echo altijd in
## beeld, solo en co-op; na een respawn en een nieuwe `BOSS_START` weer. Anders de camera van de
## flow-kamer (P1, in co-op P1 en P2).
func camera_view() -> Rect2:
	if is_arena_camera():
		return arena_view()
	var with_p2 := p2 != null and is_instance_valid(p2) and not p2.dissolved
	return FlowRoom.camera_view(p1.position, p2.position if with_p2 else p1.position)


## Staat de camera vast op de arena: de boss vecht (na `BOSS_START`, nog niet verslagen)?
func is_arena_camera() -> bool:
	return boss != null and is_instance_valid(boss) and boss.state != Gemaalmeester.State.IDLE and not boss.is_defeated()


## De arena als beeld: de rechthoek van S8 uit de layout (de arena met zijn muren, 640 × 360, precies
## één scherm, GM-01).
static func arena_view() -> Rect2:
	return Layout.ROOMS[&"S8"]


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
		elif id == &"S6":
			gemaal = null
		elif id == &"S8":
			_remove_boss()
		elif id == &"S9":
			hoogwater_open = false
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
		if node is Pickup:
			var pickup: Pickup = node
			pickup.picked_up.connect(func(t: int, who: String) -> void: _on_picked_up(pickup, t, who))
		elif node is SliceEind:
			(node as SliceEind).reached.connect(func(t: int, _at: Vector2) -> void: _slice_end_pending = t)
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
		&"S6":
			# K-paar (VJ-05: 42 px, de ketting), ≥ 80 px van elke schoep (FK-5).
			_pair(inhoud, ^"Paar1A", ^"Paar1B", "paar_k")
			gemaal = inhoud.get_node(^"Gemaal")
			gemaal.pumped.connect(func(t: int, amount: int, who: String) -> void:
				meetlog.add_row(t, "POMP", str(amount), who, gemaal.last_vane.position))
			gemaal.full.connect(func(t: int) -> void:
				meetlog.add_row(t, "GEMAAL_VOL", "", "", gemaal.last_vane.position))
			gemaal.trap_full.connect(_on_trap_full)
			# SL-02: na de boss pompt het gemaal weer tot G_max (ook na laden).
			if is_boss_defeated():
				gemaal.release_boss_cap()
		&"S9":
			# De lage kade (deel 3): het E-paar (verlicht, VJ-06: `lit` in de
			# scène tot de waterstand het zet, GP) en het luik (SL-04).
			_pair(inhoud, ^"Paar1A", ^"Paar1B", "paar_e")
			var luik_9: Luik = inhoud.get_node(^"Luik")
			luik_9.opened.connect(func(t: int, by: String) -> void:
				meetlog.add_row(t, "LUIK", "", by, luik_9.global_position))
			_update_hoogwater(sim.tick)
		&"S7":
			# Dwaallichten: banen van 32 px op 1/3 en 2/3 van het kanaal, 40 px
			# boven de vloer (§2.6), in de scène (`lane_from`, `lane_to`,
			# `floor_top` van `SliceEnemy`, #83).
			var luik: Luik = inhoud.get_node(^"Luik")
			luik.opened.connect(func(t: int, by: String) -> void:
				meetlog.add_row(t, "LUIK", "", by, luik.global_position))
			# #244: de sokkel gaat uit als de Neerslag weg is (ook na laden).
			var neerslag := inhoud.get_node_or_null(^"Neerslag") as Pickup
			if neerslag != null and neerslag.opgepakt:
				_sokkel_uit(inhoud)
		&"S8":
			if is_boss_defeated():
				# GM-10: het gemaal staat er stil, de deur naar S9 is open.
				set_door(&"S8", "DeurLinks", false)
			else:
				_spawn_boss(inhoud)


## S8: de Gemaalmeester op `Layout.ARENA_ORIGIN`, met de deuren via `set_door`.
func _spawn_boss(inhoud: Node) -> void:
	boss = Gemaalmeester.new()
	boss.name = "Gemaalmeester"
	boss.setup_gemaalmeester(Layout.ARENA_ORIGIN)
	inhoud.add_child(boss)
	boss.global_position = Layout.ARENA_ORIGIN
	boss.arena_width = Layout.ARENA_W
	boss.start_inset = BOSS_START_INSET
	boss.start_with_all_bodies = true
	boss.arena_height = Layout.ARENA_FLOOR - Layout.ROOMS[&"S8"].position.y
	boss.attach(sim)
	boss_spawns += 1
	boss.arena_changed.connect(func(_t: int, closed: bool) -> void:
		set_door(&"S8", "DeurRechts", closed))
	boss.boss_defeated.connect(_on_boss_defeated)
	# In `_ready` laadt S8 vóór het meetlog er is; dan volgt het meetlog hem daar.
	if meetlog != null:
		meetlog.watch_boss(boss)
	meter.watch_boss(boss)


func _on_boss_defeated(tick: int) -> void:
	boss_defeated_tick = tick
	set_door(&"S8", "DeurLinks", false)
	# De vlag in de save (LM-12), en trap 2 is te pompen (SL-02).
	var vlag := _loaded_node(BOSS_FLAG) as StaatVlag
	if vlag != null:
		vlag.aan = true
	if gemaal != null:
		gemaal.release_boss_cap()


## Is de Gemaalmeester verslagen: in deze scène, of in de save (de vlag
## `S8/BossVerslagen`, ook als S8 niet geladen is)?
func is_boss_defeated() -> bool:
	if boss_defeated_tick >= 0:
		return true
	var vlag := _loaded_node(BOSS_FLAG) as StaatVlag
	if vlag != null:
		return vlag.aan
	return _saved_flag(BOSS_FLAG)


## De vlag van de Neerslag in de save (V-01): wie in S8 of S9 begint (tests, het debugmenu), zet
## hem in zijn opzet, want de sokkel staat in S7 (besluit LGD in #252).
static func neerslag_flag() -> StringName:
	return AreaLoader.object_flag(NEERSLAG_FLAG[0], NEERSLAG_FLAG[1], GEBIED)


## Zet de Neerslag in `state` (een `GameState`), zoals na de pick-up.
static func give_neerslag(state: RefCounted) -> void:
	state.set_flag(neerslag_flag())


## Een node in de inhoud van een geladen kamer (`[kamer, pad]`), of null.
func _loaded_node(spec: Array) -> Node:
	var kamer = loader.kamers.get(spec[0]) if loader != null else null
	if kamer == null or kamer.inhoud_node == null:
		return null
	return kamer.inhoud_node.get_node_or_null(spec[1])


## Staat de vlag van `[kamer, pad]` aan in de save (`Progress.state`)?
func _saved_flag(spec: Array) -> bool:
	if progress == null:
		return false
	return progress.state.has_flag(AreaLoader.object_flag(spec[0], spec[1], GEBIED))


## De vulstand van het gemaal van S6: van het gemaal als S6 geladen is, anders uit de save.
func _saved_vulstand() -> int:
	if gemaal != null:
		return gemaal.fill
	if progress == null:
		return 0
	var id := AreaLoader.object_flag(GEMAAL_PATH[0], GEMAAL_PATH[1], GEBIED)
	return int(progress.state.gemalen.get(id, {}).get("vulstand", 0))


## LM-08, LM-10: trap 1 is het water van de kelderingang (LM-06, in het gemaal);
## trap 2 laat de wijk naar `s = 2` zakken: na 180 ticks gaat het hoogwater open.
func _on_trap_full(tick: int, trap: int) -> void:
	if trap != 2:
		return
	trap_2_tick = tick
	hoogwater_open_tick = tick + Gemaal.DRAIN_TICKS
	meetlog.add_row(tick, "TRAP_VOL", "2", "", gemaal.last_vane.position if gemaal and gemaal.last_vane else p1.position)


## LM-10: op `hoogwater_open_tick` is de wijk op `s = 2` (meetlog `WATERSTAND`,
## ook als S9 dan niet geladen is); het `Hoogwater` van S9 gaat open zodra S9
## geladen is.
func _update_hoogwater(tick: int) -> void:
	if hoogwater_open_tick < 0 or tick < hoogwater_open_tick:
		return
	if not _stand_2_logged and meetlog != null and hoogwater_open_tick > 0:
		_stand_2_logged = true
		meetlog.add_row(tick, "WATERSTAND", "2", "", Layout.S9_HOOGWATER.get_center())
	if not hoogwater_open and set_door(&"S9", "Hoogwater", false):
		hoogwater_open = true


## Een verzamelobject of de Neerslag werd opgepakt (stap 5): het effect nu, de
## rij in het meetlog in `_on_tick`.
func _on_picked_up(pickup: Pickup, tick: int, who: String) -> void:
	_pending_rows.append([tick, pickup.event_name(), pickup.event_value(), who])
	match pickup.soort:
		Pickup.Soort.LAMPGLAS:
			lampglas_tick = tick
			p1.add_lampglas(tick)
		Pickup.Soort.LOGBLADZIJDE:
			logblad_ticks[pickup.nummer] = tick
			if pickup.nummer == 3:
				logblad_3_tick = tick
		Pickup.Soort.VAARDIGHEID:
			neerslag_tick = tick
			sim.neerslag_unlocked = true
			var kamer = loader.kamers.get(&"S7")
			if kamer != null and kamer.inhoud_node != null:
				_sokkel_uit(kamer.inhoud_node)


## #244 (TA): de sokkel van V-01 zonder de Neerslag.
func _sokkel_uit(inhoud: Node) -> void:
	var objecten := inhoud.get_node_or_null(^"Art/Objecten")
	if objecten != null and objecten.has_method("set_sokkel_aan"):
		objecten.set_sokkel_aan(false)


## S8 ontlaadt (P1 respawnt buiten de buurkamers, F8): de boss weg bij de Sim.
func _remove_boss() -> void:
	if boss == null:
		return
	boss.detach()
	boss = null


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


## Een blok van een kamer (`Layout.blocks`), bv. de deuren van de arena:
## `set_door(&"S8", "DeurRechts", true)` sluit hem (bij `BOSS_START`, GP).
## Geeft false als de kamer niet geladen is of het blok niet bestaat.
func set_door(id: StringName, block_name: String, closed: bool) -> bool:
	var kamer = loader.kamers.get(id)
	if kamer == null or kamer.inhoud_node == null:
		return false
	var body := kamer.inhoud_node.get_node_or_null("Blokken/" + block_name) as StaticBody2D
	if body == null:
		return false
	body.collision_layer = 1 if closed else 0
	body.visible = closed
	PhysicsServer2D.body_set_collision_layer(body.get_rid(), body.collision_layer)
	return true


# --- Per tick ---

func _on_tick(tick: int) -> void:
	_wake(tick)
	_pick_up(tick)
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
	_update_hoogwater(tick)
	if run_over:
		return
	var done := room == run_end
	if run_end == &"S4":
		done = room == &"S4" and p1.position.x >= Layout.END_X
	elif run_end == RUN_END_BOSS:
		done = boss_defeated_tick >= 0
	if done:
		_end_run(tick)


func _end_run(tick: int) -> void:
	run_over = true
	end_tick = tick
	# `finish()` schrijft de enige `RUN_EIND` (zoals in de flow-kamer, #250).
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


## De rijen van de objecten van deze tick (opgepakt, `SLICE_EIND`), na de
## stap van de objecten. Met `run_end` = `RUN_END_LUS` eindigt de run op
## `SLICE_EIND` (het object `S1/SliceEind`, `kadewijk_slice_eind.gd`).
func _pick_up(tick: int) -> void:
	for row: Array in _pending_rows:
		meetlog.add_row(row[0], row[1], row[2], row[3], p1.position)
	_pending_rows.clear()
	if _slice_end_pending < 0 or slice_end_tick >= 0:
		return
	slice_end_tick = _slice_end_pending
	_slice_end_pending = -1
	meetlog.add_row(slice_end_tick, "SLICE_EIND", "", "", p1.position)
	if run_end == RUN_END_LUS and not run_over:
		_end_run(tick)


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
	debug_key(key)
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
		# Voorbij de sokkel (S8, S9): de Neerslag erbij, zoals in de opzet van de runs (V-01).
		if next == &"S8" or next == &"S9":
			sim.neerslag_unlocked = true
			if progress != null:
				give_neerslag(progress.state)
		p1.respawn_at(Layout.ROOM_START[next])


## V-7 (#250): een regel `DEBUG` (waarde = de toets, bron = de nieuwe kamer of
## D, of `echo_aan`/`echo_uit`) voor F8, de D-toetsen en F4. Herlaadt de toets
## de scène (alles behalve F8), dan schrijft de CSV-schrijver het log nu als
## `_afgebroken` (V-6). In een gesloten log (na `RUN_EIND`) komt er niets meer bij.
func debug_key(key: int) -> void:
	var source := ""
	if key == KEY_F8:
		source = String(Layout.ORDER[(Layout.ORDER.find(room) + 1) % Layout.ORDER.size()])
	elif DEBUG_TAIL_KEYS.has(key):
		source = "D%d" % int(Tuning.echo()["tail_options"][DEBUG_TAIL_KEYS[key]])
	elif key == KEY_F4:
		source = "echo_uit" if chosen_echo_on else "echo_aan"
	elif key != KEY_F6:
		return
	if key != KEY_F6 and not meetlog.is_closed():
		meetlog.add_row(sim.tick, "DEBUG", OS.get_keycode_string(key), source, p1.position)
	if key != KEY_F8 and meetlog_csv != null:
		meetlog_csv.abort()
