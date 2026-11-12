extends "res://scripts/combat/combat_target.gd"
## Een luik in een vloer (V-01, SL-04; `docs/design/wereld.md` §2.2 S7 en S9;
## kamerdoc `docs/design/kamers/kadewijk.md` §3b). Placeholder van de World &
## Level Designer voor de grijze kamers; het eindobject (beeld, geluid, de
## scheur in de klep, L-03) is van de Gameplay Programmer en de art.
##
## Het luik is een stuk vloer (een `StaticBody2D` op laag 1, `Klep`) met een
## hurtbox van dezelfde breedte en 8 px hoog op de bovenkant. Alleen een
## neerslag raakt het: het aanvalsvlak van een slag staat 7–23 px boven de
## voeten, het neerslagvlak 0–20 px eronder (`Combat.neerslag_box`), dus wie
## op of boven het luik staat en gewoon slaat, raakt het niet. De eerste
## treffer (P1, P2 of de echo die een neerslag herhaalt, V-01d) opent het: de
## klep verdwijnt meteen, ook uit de physics-ruimte, en wie erop stond valt.
## Een treffer van P1 of P2 geeft een stuit (V-01b), zoals op elk doel.
##
## Niet `Merkbaar` (soort `DUMMY`), geeft geen licht. Open = `verslagen` in de
## save (LM-13 b), en het komt nooit terug (`terugkerend` NEE).

signal opened(tick: int, by: String)

## Breedte en dikte van de klep (wereldpx). De node staat 4 px onder de
## bovenkant van de klep: daar ligt het middelpunt van de hurtbox (8 px hoog).
@export var size := Vector2(40, 16)

var is_open := false
var opened_tick := -1
var opened_by := ""
var _klep: StaticBody2D


func _init() -> void:
	kind = Kind.DUMMY
	terugkerend = Terugkeer.NEE
	walks = false


func _ready() -> void:
	setup(Layers.LIGHT | Layers.SHADOW, Vector2(size.x, 8.0))
	super._ready()
	_klep = StaticBody2D.new()
	_klep.name = "Klep"
	_klep.collision_layer = Layers.WORLD
	_klep.collision_mask = 0
	var body_shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = size
	body_shape.shape = rect
	_klep.add_child(body_shape)
	var visual := Polygon2D.new()
	var h := size * 0.5
	visual.polygon = PackedVector2Array([Vector2(-h.x, -h.y), Vector2(h.x, -h.y), Vector2(h.x, h.y), Vector2(-h.x, h.y)])
	visual.color = Color(0.48, 0.4, 0.3)
	_klep.add_child(visual)
	# De scheur in de klep (L-03: je ziet vooraf dat hij breekt).
	var crack := Line2D.new()
	crack.points = PackedVector2Array([Vector2(-h.x + 6, -h.y + 2), Vector2(-2, 1), Vector2(4, -3), Vector2(h.x - 5, h.y - 3)])
	crack.width = 1.0
	crack.default_color = Color(0.15, 0.12, 0.1)
	_klep.add_child(crack)
	_klep.position.y = size.y * 0.5 - 4.0
	add_child(_klep)
	if is_open:
		_set_open()


## Elke treffer opent het luik (alleen een neerslag kan het raken, zie boven).
func apply_damage(tick: int, _amount: int, source: String) -> int:
	if is_open:
		return 0
	is_open = true
	opened_tick = tick
	opened_by = source
	alive = false
	_set_open()
	opened.emit(tick, source)
	return 0


func _set_open() -> void:
	alive = false
	visible = false
	if _klep == null:
		return
	_klep.collision_layer = 0
	_klep.visible = false
	if _klep.is_inside_tree():
		PhysicsServer2D.body_set_collision_layer(_klep.get_rid(), 0)


func has_persistent_state() -> bool:
	return true


func get_persistent_state() -> bool:
	return is_open


func set_persistent_state(on: bool) -> void:
	if on:
		is_open = true
		_set_open()


func is_returning() -> bool:
	return false


func is_markable() -> bool:
	return false


## Het luik loopt niet, valt niet aan en staat niet stil.
func stun(_tick: int) -> void:
	pass


func sim_update(_tick: int, _bodies: Array[Node2D]) -> void:
	pass
