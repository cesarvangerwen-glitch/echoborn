extends "res://scripts/echo/echo_body.gd"
## De echo van v0.4: loopt altijd D ticks achter P1 aan (gdd E-02, E-03).
##
## Speelt de opgenomen toestand af, wordt niet gesimuleerd. Draagt de
## schaduwplank (E-07, laag 6) en controleert elke tick of het oude pad nog
## klopt met de schaduwwereld (E-08); zo niet, dan breekt hij. Resets: breken,
## Loslaten, respawn en een wissel van D (E-04b–d). De enige afwijking van
## het opgenomen pad is de merksprong (E-02m). Kamerwissels (E-04a/e) volgen
## met de AreaLoader (T5b).

## Breek-effect op `at` (E-08, E-09). De Art Director maakt het beeld.
signal broke(tick: int, at: Vector2)
## Leeg <-> Actief (E-03), voor HUD en meetlog (ECHO_LEEG_START, MP-4).
signal state_changed(tick: int, active: bool)
## Een merksprong begint (E-02m, meetlog MERKSPRONG); `mark_id` is het doelmerk.
signal merksprong_started(tick: int, mark_id: int)

const PlayerActor = preload("res://scripts/echo/player_actor.gd")
const Motor = preload("res://scripts/echo/motor.gd")
const BodyBuilder = preload("res://scripts/echo/body_builder.gd")
const GameEvents = preload("res://scripts/events/game_events.gd")
const Layers = preload("res://scripts/world/layers.gd")
const Tuning = preload("res://scripts/echo/tuning.gd")
const Zone = preload("res://scripts/objects/zone.gd")
const Combat = preload("res://scripts/combat/combat.gd")

## Echo-events die de echo uitvoert (E-10); bewegingsevents nooit.
const REPLAYED_EVENTS := GameEvents.ATTACK | GameEvents.INTERACT

## De speler van wie dit de echo is (P1).
var source: PlayerActor
## D, de staartlengte in ticks (E-02). Wisselen via `set_tail_ticks`.
var tail_ticks := 120
## `geldig_vanaf` (E-03): frames van vóór deze tick worden nooit afgespeeld.
var valid_from := 0
## Opgenomen kijkrichting, steunsoort en animatie van het frame van nu.
var facing := 1
var support := 0
var anim := 0
# `tick_events` en `finished` komen uit echo_body.gd. Een staart-echo is
# nooit "klaar"; hij gaat alleen weg via `Sim.remove_echo` (bv. als P2 meedoet).
## De schaduwplank (E-07): een StaticBody2D op laag 6 met een eenrichtingsvorm.
var plank: StaticBody2D
## Laatste positie waarop alle controles van E-08 slaagden.
var last_valid_position := Vector2.ZERO
## Het merk dat de echo deze tick laat ontploffen (E-02m, tick t + 3); de
## Sim voert het uit in stap (4), na de events van P1.
var detonate_mark: Combat.Mark = null
## Loopt er een merksprong (E-02m)?
var in_merksprong := false
## De opgenomen positie van frame `p` (bij een merksprong wijkt `position` af).
var recorded_position := Vector2.ZERO

var _active := false
var _bad_run := 0
var _body_size := Vector2.ZERO
var _has_valid := false
var _tolerance_ticks := 3
var _support_offset := Vector2.ZERO
var _free_query: PhysicsShapeQueryParameters2D
var _support_query: PhysicsShapeQueryParameters2D
var _danger_query: PhysicsShapeQueryParameters2D
var _light_query: PhysicsPointQueryParameters2D
var _ms_mark: Combat.Mark = null
var _ms_start := 0
var _ms_back_start := -1     ## tick met j = 1 van *terug*; -1 = nog *heen*
var _ms_anchor := Vector2.ZERO
var _ms_out := 4
var _ms_back := 8


func setup(p_source: PlayerActor, color: Color, p_tail_ticks: int = -1, start_tick: int = 0) -> void:
	source = p_source
	tail_ticks = p_tail_ticks if p_tail_ticks > 0 else int(Tuning.echo()["tail_ticks"])
	valid_from = start_tick
	name = "Echo%d" % source.player_index
	collision_layer = 0
	collision_mask = 0
	_body_size = Tuning.body_size()
	BodyBuilder.add_box(self, color, _body_size)
	_build_plank()
	_build_checks()
	var c: Dictionary = Tuning.combat()
	_ms_out = int(c["merksprong_out_ticks"])
	_ms_back = int(c["merksprong_back_ticks"])
	_apply_presence(false)


## C-01: zolang deze echo bestaat, is de plaats voor een echo bezet.
func is_active() -> bool:
	return not finished


## Actief (E-03): zichtbaar, op laag 3, met plank en events.
func is_present() -> bool:
	return _active


func stop() -> void:
	finished = true
	tick_events = 0
	_apply_presence(false)


## Wissel van D (E-02, E-04c): telt als reset op `tick`.
func set_tail_ticks(p_tail_ticks: int, tick: int) -> void:
	tail_ticks = p_tail_ticks
	if combat:
		combat.tail_ticks = tail_ticks
	reset(tick)


## Zet `geldig_vanaf = tick` (E-04): de echo is meteen Leeg en verschijnt
## D ticks later op de plek waar P1 op `tick` stond.
func reset(tick: int) -> void:
	valid_from = tick
	_bad_run = 0
	_has_valid = false
	tick_events = 0
	detonate_mark = null
	_end_merksprong()
	_set_active(false, tick)


## Stap (1) van E-07b: frame `p = t − D` zetten en controleren (E-08).
func sim_step(tick: int, _delta: float) -> void:
	tick_events = 0
	detonate_mark = null
	if finished:
		return
	var p := tick - tail_ticks
	var index := source.recorder.index_of_tick(p) if p >= valid_from else -1
	if index < 0:
		_end_merksprong()
		_set_active(false, tick)
		return
	var rec := source.recorder
	recorded_position = rec.post_position(index)
	facing = rec.facing(index)
	support = rec.support(index)
	anim = rec.anim(index)
	var events := rec.events(index) & REPLAYED_EVENTS
	if not in_merksprong and events & GameEvents.ATTACK:
		_try_start_merksprong(tick)
	var detonate: Combat.Mark = null
	if in_merksprong:
		detonate = _merksprong_step(tick)
		# Het AANVAL-event is de merksprong, geen gewone treffer (E-02m).
		events &= ~GameEvents.ATTACK
	else:
		position = recorded_position
	_sync_plank()
	if _breaks(rec.post_on_floor(index), not in_merksprong):
		_break(tick)
		return
	_set_active(true, tick)
	# E-02m: tijdens de merksprong staat de plank uit.
	plank.collision_layer = 0 if in_merksprong else Layers.PLANK
	# Alleen een tick waarop (a) en (b) slaagden, is geldig: faalt er een
	# binnen de tolerantie G, dan komt het breek-effect op de tick ervoor.
	if _bad_run == 0:
		last_valid_position = position
		_has_valid = true
	detonate_mark = detonate
	tick_events = events
	if in_merksprong and _ms_back_start >= 0 and tick - _ms_back_start + 1 >= _ms_back:
		_end_merksprong()


## E-02m: zoekt het doelmerk bij een AANVAL-event van frame `p`. Staat P1 op
## de plank van de echo, dan een gewone treffer (C-11e).
func _try_start_merksprong(tick: int) -> void:
	if combat == null:
		return
	if source.motor.support == Motor.Support.SHADOW_BODY and source.motor.plank == plank:
		return
	var mark: Combat.Mark = combat.find_jump_target(recorded_position, get_world_2d().direct_space_state)
	if mark == null:
		return
	in_merksprong = true
	_ms_mark = mark
	_ms_start = tick
	_ms_back_start = -1
	merksprong_started.emit(tick, mark.id)


## Positie van de merksprong op `tick`; geeft het merk terug als het op deze
## tick ontploft (k = 3).
func _merksprong_step(tick: int) -> Combat.Mark:
	if _ms_back_start < 0:
		var k := tick - _ms_start
		if not _ms_mark.alive:
			# Doelmerk weg tijdens *heen*: meteen terug vanaf hier, zonder knal.
			_ms_anchor = position
			_ms_back_start = tick
		else:
			var to := _ms_mark.center()
			if k >= _ms_out - 1:
				position = to
				_ms_anchor = to
				_ms_back_start = tick + 1
				return _ms_mark
			position = recorded_position.lerp(to, float(k + 1) / _ms_out)
			return null
	var j := tick - _ms_back_start + 1
	if j >= _ms_back:
		position = recorded_position
	else:
		position = _ms_anchor.lerp(recorded_position, float(j) / _ms_back)
	return null


func _end_merksprong() -> void:
	in_merksprong = false
	_ms_mark = null
	_ms_back_start = -1


## Na stap (3): reageert op Loslaten en respawn van P1 in dezelfde tick,
## zodat de events van de echo in stap (4) niet meer uitgevoerd worden.
func sim_after_source(tick: int) -> void:
	match source.echo_reset:
		PlayerActor.EchoReset.RELEASE:
			# E-09: breekt met effect; een Lege echo zonder effect.
			if _active:
				broke.emit(tick, position)
			reset(tick)
		PlayerActor.EchoReset.RESPAWN:
			reset(tick)


func sim_end_tick() -> void:
	pass


## E-08 (a)–(d) op de opgenomen positie van nu. `true` = de echo breekt.
## De vormen en query-objecten staan klaar uit `_build_checks`; hier komt
## alleen de positie erin (geen allocaties per tick).
## Tijdens een merksprong (`path_checks` uit) gelden (a) en (b) niet: die gaan
## over het opgenomen pad (E-02m); (c) en (d) wel, op de echte positie.
func _breaks(recorded_on_floor: bool, path_checks: bool = true) -> bool:
	var space := get_world_2d().direct_space_state
	var at := global_position
	if not path_checks:
		_bad_run = 0
		return _in_zone(space, at)
	_free_query.transform = Transform2D(0.0, at)
	var free := _is_free(space)
	var supported := true
	# E-08b: stond P1 op een schaduwlichaam, dan geen steuncontrole (zweven).
	if recorded_on_floor and (support == Motor.Support.WORLD or support == Motor.Support.LIGHT):
		_support_query.transform = Transform2D(0.0, at + _support_offset)
		supported = not space.intersect_shape(_support_query, 1).is_empty()
	if free and supported:
		_bad_run = 0
	else:
		_bad_run += 1
		if _bad_run >= _tolerance_ticks:
			return true
	return _in_zone(space, at)


## E-08a (a): de vorm overlapt geen wereld- of schaduwgeometrie. Een
## eenrichtingsrichel (laag 1, `one_way_collision`, gdd §4.1) telt niet: P1
## springt er van onder doorheen, dus de echo ook (T16b, #77).
func _is_free(space: PhysicsDirectSpaceState2D) -> bool:
	for hit in space.intersect_shape(_free_query, 8):
		var body := hit["collider"] as CollisionObject2D
		if body == null:
			return false
		var owner_id := body.shape_find_owner(int(hit["shape"]))
		if not body.is_shape_owner_one_way_collision_enabled(owner_id):
			return false
	return true


## E-08c: middelpunt in fel licht; E-08d: vorm raakt een schaduwgevaar.
func _in_zone(space: PhysicsDirectSpaceState2D, at: Vector2) -> bool:
	_light_query.position = at
	for hit in space.intersect_point(_light_query, 8):
		if _is_zone(hit["collider"], Zone.Kind.FEL_LICHT):
			return true
	_danger_query.transform = Transform2D(0.0, at)
	for hit in space.intersect_shape(_danger_query, 8):
		if _is_zone(hit["collider"], Zone.Kind.GEVAAR):
			return true
	return false


func _break(tick: int) -> void:
	broke.emit(tick, last_valid_position if _has_valid else position)
	reset(tick)


## Vormen en queries voor E-08, één keer per echo. Ruimte-queries tegen
## statische geometrie en zones (mag volgens standaarden §4.8).
func _build_checks() -> void:
	var e: Dictionary = Tuning.echo()
	_tolerance_ticks = int(e["break_tolerance_ticks"])
	# (a) Vorm aan elke kant `overlap_tolerance_px` kleiner (tot 2 px overlap
	# mag), plus 0,01 px zodat precies 2 px overlap nog vrij is.
	var inset := float(e["overlap_tolerance_px"]) + 0.01
	var free_rect := RectangleShape2D.new()
	free_rect.size = _body_size - Vector2.ONE * inset * 2.0
	_free_query = _shape_query(free_rect, Layers.ECHO_CHECK_MASK, false)
	# (b) Strook van `support_probe_px` direct onder het lichaam.
	var probe := float(e["support_probe_px"])
	var support_rect := RectangleShape2D.new()
	support_rect.size = Vector2(_body_size.x - 0.02, probe)
	_support_offset = Vector2(0, (_body_size.y + probe) * 0.5)
	_support_query = _shape_query(support_rect, Layers.ECHO_CHECK_MASK, false)
	# (c) Middelpunt; (d) hele vorm, beide tegen zones op laag 7.
	_light_query = PhysicsPointQueryParameters2D.new()
	_light_query.collision_mask = Layers.ZONES
	_light_query.collide_with_areas = true
	_light_query.collide_with_bodies = false
	var full_rect := RectangleShape2D.new()
	full_rect.size = _body_size
	_danger_query = _shape_query(full_rect, Layers.ZONES, true)


func _shape_query(shape: Shape2D, mask: int, areas: bool) -> PhysicsShapeQueryParameters2D:
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = shape
	query.collision_mask = mask
	query.collide_with_areas = areas
	query.collide_with_bodies = not areas
	return query


func _is_zone(collider: Object, kind: Zone.Kind) -> bool:
	return collider is Zone and (collider as Zone).kind == kind and (collider as Zone).enabled


func _build_plank() -> void:
	var thickness := float(Tuning.echo()["plank_thickness_px"])
	plank = StaticBody2D.new()
	plank.name = "Plank"
	plank.collision_mask = 0
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(_body_size.x, thickness)
	shape.shape = rect
	shape.one_way_collision = true
	shape.position = Vector2(0, (thickness - _body_size.y) * 0.5)
	plank.add_child(shape)
	add_child(plank)


## De plank moet in déze tick op zijn nieuwe plek staan in de physics-ruimte,
## want P1 botst er in stap (2) mee via `move_and_slide`. Een node-transform
## bereikt de ruimte pas na `_physics_process` (ontwerp.md §4a, R8); daarom
## zetten we hem ook rechtstreeks in de PhysicsServer.
func _sync_plank() -> void:
	PhysicsServer2D.body_set_state(plank.get_rid(), PhysicsServer2D.BODY_STATE_TRANSFORM,
		plank.global_transform)


func _set_active(active: bool, tick: int) -> void:
	if active == _active:
		return
	_apply_presence(active)
	state_changed.emit(tick, active)


func _apply_presence(active: bool) -> void:
	_active = active
	visible = active
	collision_layer = Layers.SHADOW if active else 0
	if plank:
		plank.collision_layer = Layers.PLANK if active else 0
	if not active:
		tick_events = 0
