extends "res://scripts/combat/combat_target.gd"
## De drie vijandtypes van de slice (T8b, B-1–B-4): Kadeloper, Schotdrager en Dwaallicht.
##
## Eén soort met een type (slice-vijanden-en-boss.md §2): alle drie `Merkbaar` (`Kind.ENEMY`);
## de Schotdrager is een Kadeloper met een pantser (E-14g), het Dwaallicht zweeft op een baan.
## Alle waarden komen uit `slice.csv` (EnemyData); de snelheid hangt van D af (VJ-03). Placeholder-
## beeld met tells en vlaggen die tests lezen (B-11): `is_telling`, `is_attack_active`, `tink_tick`.

const EnemyData = preload("res://scripts/combat/enemy_data.gd")

enum Type { KADELOPER, SCHOTDRAGER, DWAALLICHT }
## Fase van een aanval (VJ-01): aanloop met tell, actief vlak, herstel. Het Dwaallicht keert in
## `RECOVER` terug naar zijn baan (40 ticks, zonder schade).
enum Phase { IDLE, WINDUP, ACTIVE, RECOVER }

const GROUPS := {Type.KADELOPER: "kadeloper", Type.SCHOTDRAGER: "schotdrager",
	Type.DWAALLICHT: "dwaallicht"}
## Placeholder-kleuren (§9: leesbaar in silhouet; de Animator vervangt ze).
const TYPE_COLORS := {Type.KADELOPER: Color(0.72, 0.32, 0.3), Type.SCHOTDRAGER: Color(0.5, 0.42, 0.38),
	Type.DWAALLICHT: Color(0.55, 0.75, 0.95)}
const SHIELD_COLOR := Color(0.62, 0.62, 0.68)
const TELL_COLOR := Color(1.0, 0.85, 0.55)
const TINK_COLOR := Color(1.0, 1.0, 0.9)
const TINK_TICKS := 4

## Een aanloop begon (tell in beeld en geluid, §9): voor Audio, HUD en tests.
signal attack_started(tick: int)
## Een treffer op het intacte pantser: 0 SE, wel een merk, eigen geluid en vonk (VJ-07).
signal tinked(tick: int)

@export var enemy_type: Type = Type.KADELOPER
## VJ-06: verlichte wijk (waterstand s = 2): trager, langere aanloop, het Dwaallicht keert niet terug.
@export var lit := false
## VJ-05: de paargenoot en de afstand waaronder de twee niet komen (`slice.csv`: 28 of 40–44 px).
var pair_partner: Node2D = null
var pair_distance := 0.0
## Combat van de Sim (gezet door `Sim.add_object`): D en de andere vijanden.
var combat: RefCounted = null
## Dwaallicht: y van vloer of water onder de baan, en de baan (x van het middelpunt), in de
## coördinaten van de ouder (zoals `position`). In een scène via de inspector (#83); in code via
## `setup_enemy`. Een Dwaallicht zonder baan (`lane_from` = `lane_to` = 0) zweeft op zijn plek.
@export var floor_top := 0.0
@export var lane_from := 0.0
@export var lane_to := 0.0
var phase: Phase = Phase.IDLE
## Laatste tick van een tink (VJ-07), voor beeld en tests.
var tink_tick := -1_000_000
## Het aanvalsvlak van deze tick als het actief is, anders een leeg vlak (tests en beeld).
var active_box := Rect2()

var _phase_end := 0
var _lane_dir := 1
var _lane_y := 0.0
var _dive_from := Vector2.ZERO
var _attack_facing := 1


## In code (tests, demo, kamers): type en plek. Een loper staat met zijn onderkant op `floor_y`;
## het Dwaallicht zweeft op `baan_hoogte` boven `floor_y`, op een baan van `from_x` tot `to_x`.
func setup_enemy(p_type: Type, x: float, floor_y: float, from_x := NAN, to_x := NAN) -> void:
	enemy_type = p_type
	setup_target(Kind.ENEMY)
	var size := body_size()
	setup(Layers.LIGHT | Layers.SHADOW, size)
	floor_top = floor_y
	if enemy_type == Type.DWAALLICHT:
		lane_from = x if is_nan(from_x) else from_x
		lane_to = x if is_nan(to_x) else to_x
		position = Vector2(x, floor_y - EnemyData.value(_group(), "baan_hoogte") - size.y * 0.5)
	else:
		position = Vector2(x, floor_y - size.y * 0.5)
	start_position = position
	_reset_fight()
	_ensure_visual()


## Een vijand in een scène (LM-13): het vlak uit data als `shape` leeg is.
func _ready() -> void:
	if not _set_up and shape == null:
		setup(owner_layers, body_size())
	if enemy_type == Type.DWAALLICHT and lane_from == 0.0 and lane_to == 0.0:
		lane_from = position.x
		lane_to = position.x
	super._ready()


## Hurtbox uit data (§2.2–§2.4).
func body_size() -> Vector2:
	return Vector2(EnemyData.value(_group(), "breedte"), EnemyData.value(_group(), "hoogte"))


## VJ-05: twee vijanden als paar, met de afstand `a` waaronder ze niet komen.
static func make_pair(a: Node2D, b: Node2D, distance: float) -> void:
	a.pair_partner = b
	b.pair_partner = a
	a.pair_distance = distance
	b.pair_distance = distance


func health_full() -> int:
	return EnemyData.ticks(_group(), "levens")


## LM-13(a): Kadeloper ja, Schotdrager nee, Dwaallicht alleen in het donker (§2.4).
func is_returning() -> bool:
	match terugkerend:
		Terugkeer.JA:
			return true
		Terugkeer.NEE:
			return false
	if enemy_type == Type.DWAALLICHT and lit:
		return EnemyData.value(_group(), "terugkeer_verlicht") > 0.0
	return EnemyData.value(_group(), "terugkeer") > 0.0


func _reset_fight() -> void:
	super._reset_fight()
	armor_intact = enemy_type == Type.SCHOTDRAGER and EnemyData.value(_group(), "pantser") > 0.0
	phase = Phase.IDLE
	active_box = Rect2()
	tink_tick = -1_000_000
	_lane_dir = 1
	if enemy_type == Type.DWAALLICHT:
		_lane_y = start_position.y if start_position != Vector2.ZERO else position.y


## D van de sessie (VJ-03).
func tail_ticks() -> int:
	if combat != null and "tail_ticks" in combat:
		return int(combat.tail_ticks)
	return EnemyData.default_tail()


## VJ-03 en VJ-06: de snelheid van nu.
func speed() -> float:
	return EnemyData.speed(_group(), tail_ticks(), lit)


func is_telling() -> bool:
	return alive and phase == Phase.WINDUP


func is_attack_active() -> bool:
	return alive and phase == Phase.ACTIVE


func is_stunned(tick: int) -> bool:
	return tick < _stunned_until


## Doet niets tot `until` (bv. een add die uit de stoom stapt, §3.4): niet lopen, niet aanvallen.
## Raakbaar blijft hij wel.
func hold_until(until: int) -> void:
	_stunned_until = maxi(_stunned_until, until)
	phase = Phase.IDLE
	active_box = Rect2()


## VJ-04: na elke treffer 30 ticks stil; de aanloop breekt af. Een Dwaallicht dat duikt, keert
## meteen terug naar zijn baan (zonder schade).
func stun(tick: int) -> void:
	if not alive:
		return
	_stunned_until = tick + EnemyData.ticks("gedeeld", "stil_na_treffer")
	active_box = Rect2()
	if enemy_type == Type.DWAALLICHT and (phase == Phase.ACTIVE or phase == Phase.RECOVER):
		_enter(Phase.RECOVER, tick)
	else:
		phase = Phase.IDLE


## VJ-04: ook een ontploffing die hem niet doodt, maakt hem stil.
func apply_damage(tick: int, amount: int, source: String) -> int:
	var done := super.apply_damage(tick, amount, source)
	if done > 0 and alive and source == "ontploffing":
		stun(tick)
	return done


func break_armor(tick: int) -> void:
	super.break_armor(tick)
	stun(tick)


## VJ-07: treffer op het intacte pantser (Combat, E-14g).
func tink(tick: int) -> void:
	super.tink(tick)
	tink_tick = tick
	tinked.emit(tick)


## Stap (5): bewegen en aanvallen (§2.2–§2.4). Alleen P1 wordt aangevallen (E-14h, C-02).
func sim_update(tick: int, bodies: Array[Node2D]) -> void:
	if not alive:
		return
	# C-14e: tijdens een finisher vallen vijanden niet aan; een aanval die liep, breekt af.
	if combat != null and "finisher_running" in combat and combat.finisher_running:
		phase = Phase.IDLE
		active_box = Rect2()
		_update_visual(tick)
		return
	var p1: Node2D = null
	for body in bodies:
		if (body as CollisionObject2D).collision_layer & Layers.LIGHT:
			p1 = body
	if enemy_type == Type.DWAALLICHT:
		_update_dwaallicht(tick, p1)
	else:
		_update_walker(tick, p1)
	_update_visual(tick)


# --- Kadeloper en Schotdrager ------------------------------------------------

func _update_walker(tick: int, p1: Node2D) -> void:
	if tick < _stunned_until:
		return
	_advance_phase(tick)
	if phase == Phase.ACTIVE:
		active_box = _walker_box()
		if not _attack_hit and p1 != null and active_box.intersects(_body_rect(p1)):
			_attack_hit = true
			hit_player.emit(tick, p1)
		return
	active_box = Rect2()
	if phase != Phase.IDLE or p1 == null:
		return
	var dx := p1.global_position.x - global_position.x
	var reach := EnemyData.value(_group(), "bereik") + (body_size().x + Tuning.body_size().x) * 0.5
	if absf(dx) <= reach and _p1_in_height(p1):
		_attack_facing = 1 if dx >= 0.0 else -1
		facing = _attack_facing
		_start_windup(tick)
		return
	facing = 1 if dx > 0.0 else -1
	var step := speed() * facing
	var next := global_position + Vector2(step, 0.0)
	if _may_move_to(next) and _floor_ahead(next):
		position.x += step


## VJ-08: de voeten van P1 tussen `aanloop_hoogte_min` en `aanloop_hoogte_max` px boven zijn vloer
## (−20 … +20): alleen dan kan het vlak hem raken. Een aanloop die loopt, loopt door.
func _p1_in_height(p1: Node2D) -> bool:
	var own_floor := global_position.y + body_size().y * 0.5
	var feet := p1.global_position.y + Tuning.body_size().y * 0.5
	var height := own_floor - feet
	return height >= EnemyData.value(_group(), "aanloop_hoogte_min") - 0.0001 \
		and height <= EnemyData.value(_group(), "aanloop_hoogte_max") + 0.0001


## Het vlak vóór hem, `vlak_onder` tot `vlak_onder + vlak_hoogte` boven de vloer (§2.2, §2.3).
func _walker_box() -> Rect2:
	var g := _group()
	var size := Vector2(EnemyData.value(g, "vlak_breedte"), EnemyData.value(g, "vlak_hoogte"))
	var half := body_size()
	var bottom := global_position.y + half.y * 0.5 - EnemyData.value(g, "vlak_onder")
	var left := global_position.x + half.x * 0.5 if _attack_facing > 0 \
		else global_position.x - half.x * 0.5 - size.x
	return Rect2(Vector2(left, bottom - size.y), size)


## VJ-05: niet dichter bij de paargenoot dan `a`, niet binnen `afstand_los` van een ander. Weglopen
## mag altijd.
func _may_move_to(next: Vector2) -> bool:
	if combat == null:
		return true
	var loose := EnemyData.value("gedeeld", "afstand_los")
	for other in combat.targets:
		if other == self or not other.alive or not ("enemy_type" in other):
			continue
		if other.enemy_type == Type.DWAALLICHT:
			continue
		var limit: float = pair_distance if other == pair_partner else loose
		var now := global_position.distance_to(other.global_position)
		var then := next.distance_to(other.global_position)
		if then < limit - 0.0001 and then < now:
			return false
	return true


## §2.2: hij valt niet van een rand en loopt niet in een muur (query op statische geometrie).
func _floor_ahead(next: Vector2) -> bool:
	if not is_inside_tree():
		return true
	var space := get_world_2d().direct_space_state
	var half := body_size() * 0.5
	var query := PhysicsPointQueryParameters2D.new()
	query.collision_mask = Layers.WORLD
	query.position = Vector2(next.x + facing * half.x, next.y + half.y + 2.0)
	if space.intersect_point(query, 1).is_empty():
		return false
	query.position = Vector2(next.x + facing * half.x, next.y)
	return space.intersect_point(query, 1).is_empty()


# --- Dwaallicht ----------------------------------------------------------------

func _update_dwaallicht(tick: int, p1: Node2D) -> void:
	_advance_phase(tick)
	var size := body_size()
	var dive_y := floor_top - EnemyData.value(_group(), "duik_hoogte") - size.y * 0.5
	match phase:
		Phase.ACTIVE:
			var k := float(tick - (_phase_end - _phase_length(Phase.ACTIVE)) + 1)
			position = _dive_from.lerp(Vector2(_dive_from.x, dive_y), k / _phase_length(Phase.ACTIVE))
			active_box = Rect2(global_position - size * 0.5, size)
			if not _attack_hit and p1 != null and active_box.intersects(_body_rect(p1)):
				_attack_hit = true
				hit_player.emit(tick, p1)
			return
		Phase.RECOVER:
			active_box = Rect2()
			# Lineair terug: elke tick een gelijk deel van wat nog over is.
			var left := _phase_end - tick
			position.y = lerpf(position.y, _lane_y, 1.0 / float(maxi(left, 1)))
			return
	active_box = Rect2()
	if tick < _stunned_until or phase == Phase.WINDUP:
		return
	if p1 != null and absf(p1.global_position.x - global_position.x) <= EnemyData.value(_group(), "bereik") \
			and p1.global_position.y > global_position.y:
		_start_windup(tick)
		return
	# Heen en weer op de baan.
	var step := speed() * _lane_dir
	var lo := minf(lane_from, lane_to)
	var hi := maxf(lane_from, lane_to)
	position.x += step
	if position.x >= hi:
		position.x = hi
		_lane_dir = -1
	elif position.x <= lo:
		position.x = lo
		_lane_dir = 1
	facing = _lane_dir


# --- fasen ---------------------------------------------------------------------

func _start_windup(tick: int) -> void:
	_attack_hit = false
	phase = Phase.WINDUP
	_phase_end = tick + EnemyData.windup(_group(), lit)
	attack_started.emit(tick)


## De fase van deze tick: aanloop → actief → herstel → rust, op de grenzen van `_phase_end`.
func _advance_phase(tick: int) -> void:
	if phase == Phase.WINDUP and tick >= _phase_end:
		_dive_from = position
		_enter(Phase.ACTIVE, tick)
	if phase == Phase.ACTIVE and tick >= _phase_end:
		_enter(Phase.RECOVER, tick)
	if phase == Phase.RECOVER and tick >= _phase_end:
		phase = Phase.IDLE
		if enemy_type == Type.DWAALLICHT:
			position.y = _lane_y


func _enter(p_phase: Phase, tick: int) -> void:
	phase = p_phase
	_phase_end = tick + _phase_length(p_phase)


func _phase_length(p_phase: Phase) -> int:
	match p_phase:
		Phase.ACTIVE:
			return EnemyData.ticks(_group(), "actief")
		Phase.RECOVER:
			return EnemyData.ticks(_group(), "herstel")
	return 0


func _group() -> String:
	return GROUPS[enemy_type]


# --- placeholder-beeld (B-11) --------------------------------------------------

func _ensure_visual() -> void:
	super._ensure_visual()
	var body := get_node_or_null(^"Beeld") as Polygon2D
	if body != null:
		body.color = TYPE_COLORS[enemy_type]
	if enemy_type == Type.SCHOTDRAGER and get_node_or_null(^"Schot") == null:
		var shield := BodyBuilder.make_visual(Vector2(EnemyData.value(_group(), "beeld_breedte") - body_size().x,
			EnemyData.value(_group(), "beeld_hoogte")), SHIELD_COLOR)
		shield.name = "Schot"
		add_child(shield)
	if get_node_or_null(^"Ogen") == null:
		var eyes := BodyBuilder.make_visual(Vector2(6, 2), Color.WHITE)
		eyes.name = "Ogen"
		eyes.position = Vector2(0, -body_size().y * 0.25)
		add_child(eyes)
	if get_node_or_null(^"Tell") == null:
		var tell := Polygon2D.new()
		tell.name = "Tell"
		tell.color = TELL_COLOR
		tell.visible = false
		add_child(tell)


## Tell (aanloop: vlak licht op, feller naar het einde), actief vlak, tink-vonk, ogen in het donker
## feller (VJ-06). Alleen beeld; de vlaggen hierboven zijn wat tests lezen.
func _update_visual(tick: int) -> void:
	var tell := get_node_or_null(^"Tell") as Polygon2D
	var eyes := get_node_or_null(^"Ogen") as Polygon2D
	var shield := get_node_or_null(^"Schot") as Polygon2D
	if eyes != null:
		eyes.color = Color(1.0, 0.95, 0.6) if not lit else Color(0.6, 0.55, 0.45)
	if shield != null:
		shield.visible = armor_intact
		shield.position = Vector2(facing * (body_size().x * 0.5 + shield.polygon[2].x), 0.0)
		shield.color = TINK_COLOR if tick - tink_tick < TINK_TICKS else SHIELD_COLOR
	if tell == null:
		return
	var box := Rect2()
	if phase == Phase.WINDUP or phase == Phase.ACTIVE:
		box = _walker_box() if enemy_type != Type.DWAALLICHT else Rect2(global_position - body_size() * 0.5, body_size())
	tell.visible = box.has_area()
	if tell.visible:
		var local := box.position - global_position
		tell.polygon = PackedVector2Array([local, local + Vector2(box.size.x, 0), local + box.size,
			local + Vector2(0, box.size.y)])
		var progress := 1.0
		if phase == Phase.WINDUP:
			var total := float(EnemyData.windup(_group(), lit))
			progress = clampf(1.0 - float(_phase_end - tick) / total, 0.0, 1.0)
		tell.color = Color(TELL_COLOR, 0.15 + 0.45 * progress) if phase == Phase.WINDUP else Color(1, 0.4, 0.3, 0.8)
