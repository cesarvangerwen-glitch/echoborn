extends "res://scripts/objects/sim_object.gd"
## Eén gemaal met pomprad, waterlijn, `Diepwater` en sluisdoorgang (gdd §2.12,
## LM-03, LM-04, LM-06), minimaal voor de flow-kamer.
##
## - LM-03: elke treffer op het pomprad (P1, de echo of P2) pompt
##   `min(10, L, 100 − G)` LP van de meter naar het gemaal; `G` daalt nooit.
## - LM-04: een pompslag is een gewone aanval (herhaaltijd 20 ticks), geen
##   knop om vast te houden.
## - LM-06: op `t_v` (G = 100) zakt de waterlijn lineair in 180 ticks van
##   `y_high` naar `y_low`; op `t_v + 180` verdwijnt de sluis. `Diepwater`
##   controleert alleen het middelpunt van P1: 30 ticks erin = terug op zijn
##   laatste vloerpositie buiten het water (telt als respawn, E-04b). De echo
##   en P2 negeren het water.
##
## Alles in de tick (stap 4 via `Combat.hit`, stap 5 via `sim_update`), zonder
## Area2D-signalen (ontwerp.md §4a).

signal pumped(tick: int, amount: int, who: String)
signal full(tick: int)
signal sluice_opened(tick: int)

const PER_STROKE := 10
const MAX := 100
const DRAIN_TICKS := 180
const DROWN_TICKS := 30

## Vulstand G (0–100).
var fill := 0
## `t_v`: tick waarop G = 100 werd, of -1.
var full_tick := -1
var sluice_open := false
var meter: RefCounted
var pomprad: Node2D
## De sluisdoorgang (wereldgeometrie, laag 1).
var sluice: StaticBody2D
## Straat met water: x-bereik en de vloer (`end.y`); de bovenkant is de waterlijn.
var street := Rect2()
var y_high := 0.0
var y_low := 0.0
## Aantal pompslagen per lichaam (MP-6).
var strokes := {}

var _water_visual: Polygon2D
var _wet_since := -1
var _last_dry := Vector2.ZERO
var _has_dry := false
## Vol geladen uit een save: het water staat al laag (`restore_state`).
var _drained := false


func setup_gemaal(p_meter: RefCounted, p_pomprad: Node2D, p_sluice: StaticBody2D,
		p_street: Rect2, p_y_high: float, p_y_low: float) -> void:
	setup(Layers.LIGHT | Layers.SHADOW, Vector2(1, 1))
	name = "Gemaal"
	meter = p_meter
	pomprad = p_pomprad
	sluice = p_sluice
	street = p_street
	y_high = p_y_high
	y_low = p_y_low
	_water_visual = Polygon2D.new()
	_water_visual.color = Color(0.25, 0.35, 0.45, 0.7)
	add_child(_water_visual)
	_update_water_visual(y_high)


## Is G = 100 bereikt (LM-03, LM-06)? Dat bewaart de save als `vol`.
func is_full() -> bool:
	return full_tick >= 0 or fill >= MAX


## Zet de bewaarde stand terug na laden (T5b deel 3a, ontwerp.md §7), zonder
## signalen. Een vol gemaal staat meteen in zijn eindstand: het water laag en
## de sluis open, ook als de save midden in het zakken (LM-06) gemaakt werd.
## `t_v` is na laden onbekend; `full_tick` wordt 0, zodat `full_tick >= 0`
## blijft betekenen dat het gemaal vol is.
func restore_state(vulstand: int, vol: bool) -> void:
	fill = clampi(vulstand, 0, MAX)
	_drained = vol
	if not vol:
		full_tick = -1
		return
	full_tick = 0
	sluice_open = true
	if sluice:
		sluice.collision_layer = 0
		sluice.visible = false
		if sluice.is_inside_tree():
			PhysicsServer2D.body_set_collision_layer(sluice.get_rid(), 0)
	_update_water_visual(y_low)


## Verbindt met `Combat.hit` van de Sim (stap 4).
func connect_combat(combat: RefCounted) -> void:
	combat.hit.connect(_on_hit)


## Waterlijn op `tick` (LM-06).
func waterline(tick: int) -> float:
	if _drained:
		return y_low
	if full_tick < 0:
		return y_high
	var f := clampf(float(tick - full_tick) / DRAIN_TICKS, 0.0, 1.0)
	return lerpf(y_high, y_low, f)


## Ligt `at` (het middelpunt van P1) nu in `Diepwater`?
func in_deep_water(at: Vector2, tick: int) -> bool:
	var top := waterline(tick)
	return at.x >= street.position.x and at.x <= street.end.x and at.y > top and at.y < street.end.y


func _on_hit(tick: int, attacker: String, target: Node2D, _damage: int) -> void:
	if target != pomprad:
		return
	var amount := mini(PER_STROKE, MAX - fill)
	amount = meter.take(amount)
	fill += amount
	strokes[attacker] = int(strokes.get(attacker, 0)) + 1
	pumped.emit(tick, amount, attacker)
	if fill >= MAX and full_tick < 0:
		full_tick = tick
		full.emit(tick)


## Stap (5): water, sluis en Diepwater voor P1.
func sim_update(tick: int, bodies: Array[Node2D]) -> void:
	var line := waterline(tick)
	_update_water_visual(line)
	if full_tick >= 0 and not sluice_open and tick >= full_tick + DRAIN_TICKS:
		sluice_open = true
		if sluice:
			sluice.collision_layer = 0
			sluice.visible = false
			# Meteen in de physics-ruimte, niet pas na deze physics-stap.
			PhysicsServer2D.body_set_collision_layer(sluice.get_rid(), 0)
		sluice_opened.emit(tick)
	for body in bodies:
		if not (body is CharacterBody2D) or (body as CollisionObject2D).collision_layer & Layers.LIGHT == 0:
			continue
		# Alleen P1 (laag 2); de echo en P2 negeren het water.
		var p1 := body as CharacterBody2D
		var wet := in_deep_water(p1.global_position, tick)
		if wet:
			if _wet_since < 0:
				_wet_since = tick
			# Teruggezet op de stap van tick t + 30 (respawn_at werkt de volgende tick).
			if tick - _wet_since == DROWN_TICKS - 1 and _has_dry and p1.has_method("respawn_at"):
				p1.respawn_at(_last_dry)
				_wet_since = -1
		else:
			_wet_since = -1
			if p1.get("motor") != null and p1.motor.on_floor:
				_last_dry = p1.global_position
				_has_dry = true


func _update_water_visual(line: float) -> void:
	if _water_visual == null:
		return
	var top := line - global_position.y
	var left := street.position.x - global_position.x
	var right := street.end.x - global_position.x
	var bottom := street.end.y - global_position.y
	if top >= bottom:
		_water_visual.visible = false
		return
	_water_visual.visible = true
	_water_visual.polygon = PackedVector2Array([
		Vector2(left, top), Vector2(right, top), Vector2(right, bottom), Vector2(left, bottom)])
