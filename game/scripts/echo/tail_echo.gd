extends "res://scripts/echo/echo_body.gd"
## De echo van v0.4: loopt altijd D ticks achter P1 aan (gdd E-02, E-03).
##
## Speelt de opgenomen toestand af, wordt niet gesimuleerd. Draagt de
## schaduwplank (E-07, laag 6) en controleert elke tick of het oude pad nog
## klopt met de schaduwwereld (E-08); zo niet, dan breekt hij. Resets: breken,
## Loslaten, respawn en een wissel van D (E-04b–d). Kamerwissels (E-04a/e)
## en de merksprong (E-02m) volgen in een volgende stap van T16a.

## Breek-effect op `at` (E-08, E-09). De Art Director maakt het beeld.
signal broke(tick: int, at: Vector2)
## Leeg <-> Actief (E-03), voor HUD en meetlog (ECHO_LEEG_START, MP-4).
signal state_changed(tick: int, active: bool)

const PlayerActor = preload("res://scripts/echo/player_actor.gd")
const Motor = preload("res://scripts/echo/motor.gd")
const BodyBuilder = preload("res://scripts/echo/body_builder.gd")
const GameEvents = preload("res://scripts/events/game_events.gd")
const Layers = preload("res://scripts/world/layers.gd")
const Tuning = preload("res://scripts/echo/tuning.gd")
const Zone = preload("res://scripts/objects/zone.gd")

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

var _active := false
var _bad_run := 0
var _body_size := Vector2.ZERO


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
	reset(tick)


## Zet `geldig_vanaf = tick` (E-04): de echo is meteen Leeg en verschijnt
## D ticks later op de plek waar P1 op `tick` stond.
func reset(tick: int) -> void:
	valid_from = tick
	_bad_run = 0
	tick_events = 0
	_set_active(false, tick)


## Stap (1) van E-07b: frame `p = t − D` zetten en controleren (E-08).
func sim_step(tick: int, _delta: float) -> void:
	tick_events = 0
	if finished:
		return
	var p := tick - tail_ticks
	var index := source.recorder.index_of_tick(p) if p >= valid_from else -1
	if index < 0:
		_set_active(false, tick)
		return
	var rec := source.recorder
	position = rec.post_position(index)
	facing = rec.facing(index)
	support = rec.support(index)
	anim = rec.anim(index)
	_sync_plank()
	if _breaks(rec.post_on_floor(index)):
		_break(tick)
		return
	_set_active(true, tick)
	last_valid_position = position
	tick_events = rec.events(index) & REPLAYED_EVENTS


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
func _breaks(recorded_on_floor: bool) -> bool:
	var e: Dictionary = Tuning.echo()
	var space := get_world_2d().direct_space_state
	var free := not _overlaps(space, _inset_rect(float(e["overlap_tolerance_px"])),
		Vector2.ZERO, Layers.ECHO_CHECK_MASK, false)
	var supported := true
	# E-08b: stond P1 op een schaduwlichaam, dan geen steuncontrole (zweven).
	if recorded_on_floor and (support == Motor.Support.WORLD or support == Motor.Support.LIGHT):
		var probe := float(e["support_probe_px"])
		var rect := RectangleShape2D.new()
		rect.size = Vector2(_body_size.x - 0.02, probe)
		supported = _overlaps(space, rect, Vector2(0, (_body_size.y + probe) * 0.5),
			Layers.ECHO_CHECK_MASK, false)
	if free and supported:
		_bad_run = 0
	else:
		_bad_run += 1
		if _bad_run >= int(e["break_tolerance_ticks"]):
			return true
	# E-08c: middelpunt in fel licht; E-08d: vorm raakt een schaduwgevaar.
	if _zone_at_point(space, Zone.Kind.FEL_LICHT):
		return true
	var full := RectangleShape2D.new()
	full.size = _body_size
	return _zone_overlaps(space, full, Zone.Kind.GEVAAR)


func _break(tick: int) -> void:
	broke.emit(tick, last_valid_position if _active else position)
	reset(tick)


## Vorm van het lichaam, aan elke kant `inset` px kleiner (E-08a: tot 2 px
## overlap mag). 0,01 px extra zodat precies 2 px overlap nog vrij is.
func _inset_rect(inset: float) -> RectangleShape2D:
	var rect := RectangleShape2D.new()
	rect.size = _body_size - Vector2.ONE * (inset + 0.01) * 2.0
	return rect


func _query(shape: Shape2D, offset: Vector2, mask: int, areas: bool) -> PhysicsShapeQueryParameters2D:
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = shape
	query.transform = Transform2D(0.0, global_position + offset)
	query.collision_mask = mask
	query.collide_with_areas = areas
	query.collide_with_bodies = not areas
	return query


## Ruimte-query tegen statische geometrie (mag volgens standaarden §4.8).
func _overlaps(space: PhysicsDirectSpaceState2D, shape: Shape2D, offset: Vector2,
		mask: int, areas: bool) -> bool:
	return not space.intersect_shape(_query(shape, offset, mask, areas), 1).is_empty()


func _zone_overlaps(space: PhysicsDirectSpaceState2D, shape: Shape2D, kind: Zone.Kind) -> bool:
	for hit in space.intersect_shape(_query(shape, Vector2.ZERO, Layers.ZONES, true), 8):
		if _is_zone(hit["collider"], kind):
			return true
	return false


func _zone_at_point(space: PhysicsDirectSpaceState2D, kind: Zone.Kind) -> bool:
	var query := PhysicsPointQueryParameters2D.new()
	query.position = global_position
	query.collision_mask = Layers.ZONES
	query.collide_with_areas = true
	query.collide_with_bodies = false
	for hit in space.intersect_point(query, 8):
		if _is_zone(hit["collider"], kind):
			return true
	return false


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
