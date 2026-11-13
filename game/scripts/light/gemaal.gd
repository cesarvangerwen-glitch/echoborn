extends "res://scripts/objects/sim_object.gd"
## Eén gemaal met `n` pompschoepen, waterlijn, `Diepwater` en sluisdoorgang
## (gdd §2.12, LM-03, LM-04, LM-06; herzien na F0, §4.7), minimaal voor de
## flow-kamer.
##
## - LM-03: één `Gemaal`, één vulstand `G`, `n` pompschoepen (`vanes`; elk een
##   eigen hurtbox, `pomprad.gd`; `n = 1` is het pomprad van v0.6). Elke treffer
##   op een schoep (P1, de echo of P2) pompt `min(15, L, G_max − G)` LP van de
##   meter naar het gemaal; `G` daalt nooit. De 15 staat in
##   `data/echo_v04.json` (`light.pump_per_stroke`).
## - LM-04: een pompslag is een gewone aanval (herhaaltijd 20 ticks), geen
##   knop om vast te houden; elke schoep is lopend en springend te raken.
## - LM-06: op `t_v` (G = 100) verdwijnt de sluis (zelfde tick, na F0) en zakt
##   de waterlijn lineair in 180 ticks van `y_high` naar `y_low`. `Diepwater`
##   controleert alleen het middelpunt van P1: 30 ticks erin = terug op zijn
##   laatste vloerpositie buiten het water (telt als respawn, E-04b). De echo
##   en P2 negeren het water.
##
## Alles in de tick (stap 4 via `Combat.hit`, stap 5 via `sim_update`), zonder
## Area2D-signalen (ontwerp.md §4a).
##
## Twee manieren om het op te zetten (architectuur-aansluiting T5b deel 3b,
## #82; ontwerp.md §3a):
## - in code: `setup_gemaal(meter, pomprad, sluis, straat, y_hoog, y_laag)`,
##   dan `connect_combat` (zoals de flow-kamer); `pomprad` mag ook een lijst
##   schoepen zijn;
## - in een scène (ook in de gestreamde `inhoud` van een kamer): vul
##   `vane_paths` (of voor één schoep `pomprad_path`), `sluice_path`, `street`,
##   `y_high` en `y_low` in. De
##   AreaLoader geeft het gemaal bij het laden de lichtmeter (via `Progress`),
##   verbindt het met `Combat` en bindt zijn stand (`Progress.bind_gemaal`).
##
## **Trappen** (LM-08, LM-10, SL-02; #83): `trappen` = 1 of 2, elk 100 G, dus
## `G_max = 100 × trappen`. Trap *k* is vol zodra `G ≥ 100 × k` (`trap_full`).
## Wat hierboven "vol" heet (`is_full`, `full`, `t_v`, de sluis en het water
## van LM-06) is trap 1, zoals in de flow-kamer. `stand()` is de waterstand
## `s` van de wijk (het aantal volle trappen). **Bosswijk** (`boss_cap`,
## LM-03, WS-03): tot `release_boss_cap()` (bij `BOSS_VERSLAGEN`) pompt het
## gemaal niet verder dan G = 100, dus trap 2 kan pas na de boss.

signal pumped(tick: int, amount: int, who: String)
signal full(tick: int)
signal sluice_opened(tick: int)
## LM-08: trap `trap` (1 of 2) werd vol op `tick` (trap 1 op `t_v`, na `full`).
signal trap_full(tick: int, trap: int)

const Tuning = preload("res://scripts/echo/tuning.gd")

## LM-03: LP per pompslag (startwaarde 15, testbereik 10–25, gdd §2.9).
static func per_stroke() -> int:
	return int(Tuning.light()["pump_per_stroke"])
## G per trap (LM-08). Bij één trap is dit ook `G_max`.
const MAX := 100
## LM-08: hooguit zoveel trappen per gemaal.
const MAX_TRAPPEN := 2
const DRAIN_TICKS := 180
const DROWN_TICKS := 30

## LM-08: aantal trappen (1 of 2); `G_max = MAX × trappen`.
@export_range(1, 2) var trappen := 1
## LM-03, WS-03, SL-02: het gemaal van een bosswijk. Tot `release_boss_cap()`
## is de bovengrens G = 100 (trap 1), daarna `G_max`.
@export var boss_cap := false
## Vulstand G (0 … `G_max`).
var fill := 0
## `t_v`: tick waarop G = 100 werd (trap 1), of -1.
var full_tick := -1
## Tick waarop trap 2 vol werd (G = 200), of -1; 0 na laden uit een save.
var trap_2_tick := -1
## De boss van de wijk is verslagen: de grens van `boss_cap` geldt niet meer.
var boss_cap_released := false
var sluice_open := false
var meter: RefCounted
## De pompschoepen (LM-03), in de looprichting. `pomprad` is de eerste.
var vanes: Array[Node2D] = []
var pomprad: Node2D:
	get:
		return vanes[0] if not vanes.is_empty() else null
## De schoep van de laatste pompslag (meetlog POMP), of null.
var last_vane: Node2D = null
## De sluisdoorgang (wereldgeometrie, laag 1).
var sluice: StaticBody2D
## In een scène: de schoepen (nodes met `pomprad.gd`) en de sluis. Is
## `vane_paths` leeg, dan is `pomprad_path` de enige schoep.
@export var vane_paths: Array[NodePath] = []
@export var pomprad_path: NodePath
@export var sluice_path: NodePath
## Straat met water, in wereldcoördinaten: x-bereik en de vloer (`end.y`);
## de bovenkant is de waterlijn.
@export var street := Rect2()
@export var y_high := 0.0
@export var y_low := 0.0
## Aantal pompslagen per lichaam (MP-6).
var strokes := {}

var _water_visual: Polygon2D
var _wet_since := -1
var _last_dry := Vector2.ZERO
var _has_dry := false
## Vol geladen uit een save: het water staat al laag (`restore_state`).
var _drained := false


## `p_vanes`: één schoep (Node2D) of een lijst schoepen (LM-03).
func setup_gemaal(p_meter: RefCounted, p_vanes: Variant, p_sluice: StaticBody2D,
		p_street: Rect2, p_y_high: float, p_y_low: float) -> void:
	name = "Gemaal"
	meter = p_meter
	vanes.clear()
	if p_vanes is Array:
		for vane: Node2D in p_vanes:
			vanes.append(vane)
	elif p_vanes != null:
		vanes.append(p_vanes as Node2D)
	sluice = p_sluice
	street = p_street
	y_high = p_y_high
	y_low = p_y_low
	_setup_common()


## In een scène: de verwijzingen uit de geëxporteerde paden. Elke schoep
## krijgt hier zijn soort en hurtbox (`setup_pomprad`; die worden niet in de
## scène bewaard); de namen blijven staan (ze zitten in de id van het gemaal
## in de save, §3a).
func _ready() -> void:
	if not vanes.is_empty():
		return
	var paths: Array[NodePath] = vane_paths.duplicate()
	if paths.is_empty() and not pomprad_path.is_empty():
		paths.append(pomprad_path)
	if paths.is_empty():
		return
	sluice = get_node_or_null(sluice_path) as StaticBody2D
	for path in paths:
		var vane := get_node_or_null(path) as Node2D
		if vane == null:
			push_error("Gemaal '%s': schoep '%s' wijst nergens heen" % [name, path])
			continue
		if vane.has_method("setup_pomprad"):
			var own_name := vane.name
			vane.setup_pomprad()
			vane.name = own_name
		vanes.append(vane)
	_setup_common()


func _setup_common() -> void:
	setup(Layers.LIGHT | Layers.SHADOW, Vector2(1, 1))
	_water_visual = Polygon2D.new()
	_water_visual.color = Color(0.25, 0.35, 0.45, 0.7)
	add_child(_water_visual)
	_update_water_visual(y_high)


## Is G = 100 bereikt (LM-03, LM-06; trap 1)? Dat bewaart de save als `vol`.
func is_full() -> bool:
	return full_tick >= 0 or fill >= MAX


## LM-08: G_max = 100 × trappen.
func g_max() -> int:
	return MAX * clampi(trappen, 1, MAX_TRAPPEN)


## De bovengrens van nu: G = 100 in een bosswijk tot de boss verslagen is
## (LM-03, SL-02), anders `G_max`.
func cap() -> int:
	return MAX if boss_cap and not boss_cap_released else g_max()


## LM-10: de waterstand `s` van de wijk = het aantal volle trappen (0 … trappen).
func stand() -> int:
	return mini(fill / MAX, clampi(trappen, 1, MAX_TRAPPEN))


## `BOSS_VERSLAGEN` (SL-02): vanaf nu pompt het gemaal weer tot `G_max`.
func release_boss_cap() -> void:
	boss_cap_released = true


## Zet de bewaarde stand terug na laden (T5b deel 3a, ontwerp.md §7), zonder
## signalen. Een vol gemaal staat meteen in zijn eindstand: het water laag en
## de sluis open, ook als de save midden in het zakken (LM-06) gemaakt werd.
## `t_v` is na laden onbekend; `full_tick` wordt 0, zodat `full_tick >= 0`
## blijft betekenen dat het gemaal vol is.
func restore_state(vulstand: int, vol: bool) -> void:
	fill = clampi(vulstand, 0, g_max())
	trap_2_tick = 0 if trappen >= 2 and fill >= 2 * MAX else -1
	_drained = vol
	if not vol:
		full_tick = -1
		return
	full_tick = 0
	_set_sluice_open()
	_update_water_visual(y_low)


## Verbindt met `Combat.hit` van de Sim (stap 4).
func connect_combat(combat: RefCounted) -> void:
	if not combat.hit.is_connected(_on_hit):
		combat.hit.connect(_on_hit)


## Het omgekeerde, bij het ontladen van de kamer (AreaLoader).
func disconnect_combat(combat: RefCounted) -> void:
	if combat.hit.is_connected(_on_hit):
		combat.hit.disconnect(_on_hit)


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


## Een pompslag (stap 4): `min(15, L, G_max − G)` (LM-03). Slaan P1 en de
## echo op dezelfde tick, dan komt P1 eerst (volgorde van `Combat.hit`,
## E-07b). Wordt `G` hier 100, dan is dit `t_v`: de sluis gaat meteen open
## (LM-06, na F0), het water begint te zakken.
func _on_hit(tick: int, attacker: String, target: Node2D, _damage: int) -> void:
	if not vanes.has(target):
		return
	var amount := mini(per_stroke(), maxi(cap() - fill, 0))
	amount = meter.take(amount)
	fill += amount
	last_vane = target
	strokes[attacker] = int(strokes.get(attacker, 0)) + 1
	pumped.emit(tick, amount, attacker)
	if fill >= MAX and full_tick < 0:
		full_tick = tick
		full.emit(tick)
		_open_sluice(tick)
		trap_full.emit(tick, 1)
	if trappen >= 2 and fill >= 2 * MAX and trap_2_tick < 0:
		trap_2_tick = tick
		trap_full.emit(tick, 2)


## LM-06: de sluisdoorgang verdwijnt op `t_v`.
func _open_sluice(tick: int) -> void:
	if sluice_open:
		return
	_set_sluice_open()
	sluice_opened.emit(tick)


func _set_sluice_open() -> void:
	sluice_open = true
	if sluice:
		sluice.collision_layer = 0
		sluice.visible = false
		# Meteen in de physics-ruimte, niet pas na deze physics-stap.
		if sluice.is_inside_tree():
			PhysicsServer2D.body_set_collision_layer(sluice.get_rid(), 0)


## Stap (5): water en Diepwater voor P1 (de sluis gaat al open in `_on_hit`).
func sim_update(tick: int, bodies: Array[Node2D]) -> void:
	var line := waterline(tick)
	_update_water_visual(line)
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
