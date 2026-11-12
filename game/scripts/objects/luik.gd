extends "res://scripts/combat/combat_target.gd"
## `Luik`: een luik in een vloer (gdd V-01d, SL-04; `docs/design/wereld.md`
## §2.2 S7 en S9; kamerdoc `docs/design/kamers/kadewijk.md` §3b en §3e).
## Systeemobject van de Gameplay Programmer (was de placeholder
## `levels/kadewijk/kadewijk_luik.gd` van de World & Level Designer).
##
## Het luik is een stuk vloer (een `StaticBody2D` op laag 1, `Klep`) met een
## hurtbox van dezelfde breedte en 8 px hoog op de bovenkant. Alleen een
## neerslag raakt het: het aanvalsvlak van een slag staat 7–23 px boven de
## voeten, het neerslagvlak 0–20 px eronder (`Combat.neerslag_box`), dus wie
## op of boven het luik staat en gewoon slaat, raakt het niet. De eerste
## treffer (P1, P2 of de echo die een neerslag herhaalt, V-01d/e) opent het:
## de klep verdwijnt meteen van laag 1, ook uit de physics-ruimte, en wie erop
## stond valt. Een treffer van P1 of P2 geeft een stuit (V-01b), zoals op elk
## doel.
##
## **De schaduwklep** (V-01d, aanvulling LGD in #227, voorstel A). Breekt P1
## solo het luik met de echo aan (`Combat.echo_on`; ook als de echo op die
## tick Leeg is, besluit LGD in #232), dan gaat de klep van laag 1
## naar **laag 5** (schaduwgeometrie) in plaats van weg. P1 botst niet met
## laag 5 (E-05) en valt erdoor; de echo vindt hem met zijn steuncontrole
## (E-08b ziet laag 1 en 5) en blijft erop staan tot hij de neerslag van P1 op
## dit luik afspeelt. Die treffer (van de echo, laag 3) haalt de schaduwklep
## weg, op die tick in stap (4); de echo valt daarna achter P1 aan. Komt die
## treffer niet (de echo is Leeg, gebroken, doet een merksprong of slaat
## anders), dan gaat de schaduwklep in stap (5) van tick `breuk + D + G` weg
## (D = `Combat.tail_ticks`, G = `break_tolerance_ticks`, E-08). Elk frame van
## P1 op de klep ligt vóór de breuk en wordt uiterlijk op `breuk + D`
## afgespeeld, dus `D + G` dekt ook een Lege echo die na een respawn of reset
## frames van P1 op de klep gaat afspelen. E-08 zelf verandert niet. In co-op
## (`Combat.coop`) en met de echo uit is er geen schaduwklep: P2 botst met
## laag 5 en is geen afspeler; het luik breekt in één keer. Komt P2 erbij
## terwijl de schaduwklep er nog ligt, dan kan hij er hooguit `D + G` ticks
## op staan (TD, Lead-review #232; kamerdoc §9).
## De schaduwklep is onzichtbaar (beeld: Art Director); voor P1 is het luik
## open vanaf de breuk (`is_open`, `opened`).
##
## Niet `Merkbaar` (soort `DUMMY`), geeft geen licht. Open = `verslagen` in de
## save (LM-13 b), en het komt nooit terug (`terugkerend` NEE). Een bewaard
## open luik (laden, opnieuw laden van de kamer) heeft geen schaduwklep.

## Het luik is open voor P1 (de klep is van laag 1). `by` = "p1", "p2" of "echo".
signal opened(tick: int, by: String)
## De schaduwklep is weg: `by` = "echo" (de echo speelde de neerslag af) of
## "tijd" (`D + G` ticks na de breuk).
signal schaduwklep_weg(tick: int, by: String)

## Breedte en dikte van de klep (wereldpx). De node staat 4 px onder de
## bovenkant van de klep: daar ligt het middelpunt van de hurtbox (8 px hoog).
@export var size := Vector2(40, 16)

## Combat van de Sim (gezet door `Sim.add_object`): `coop`, `echo_on`
## en `tail_ticks`. Zonder Combat (een losse test) is er geen schaduwklep.
var combat: RefCounted = null

var is_open := false
var opened_tick := -1
var opened_by := ""
## Staat de schaduwklep er nu (laag 5)?
var schaduwklep := false
## Tick waarop de schaduwklep uiterlijk weggaat (`breuk + D + G`), of -1.
var schaduwklep_tot := -1
## Tick en oorzaak van het verdwijnen van de schaduwklep (voor tests).
var schaduwklep_weg_tick := -1
var schaduwklep_weg_by := ""
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
		_set_layer(0)


## De klep, voor tests (laag: `collision_layer`).
func klep() -> StaticBody2D:
	return _klep


## Dicht: elke neerslag raakt (E-06, gedeeld). Met de schaduwklep alleen een
## lichaam op laag 3 (de echo; in co-op is er geen schaduwklep, dus nooit P2).
func is_hit_by(box: Rect2, attacker_layer: int) -> bool:
	if schaduwklep:
		if attacker_layer & Layers.SHADOW == 0:
			return false
		var rect := RectangleShape2D.new()
		rect.size = box.size
		return shape.collide(global_transform, rect, Transform2D(0.0, box.get_center()))
	return super.is_hit_by(box, attacker_layer)


## Elke treffer opent het luik (alleen een neerslag kan het raken, zie boven).
## Een treffer van de echo op de schaduwklep haalt die weg.
func apply_damage(tick: int, _amount: int, source: String) -> int:
	if schaduwklep:
		if source == "echo":
			_end_schaduwklep(tick, "echo")
		return 0
	if is_open:
		return 0
	is_open = true
	opened_tick = tick
	opened_by = source
	alive = false
	if _wants_schaduwklep(source):
		schaduwklep = true
		schaduwklep_tot = tick + int(combat.tail_ticks) + int(Tuning.echo()["break_tolerance_ticks"])
		visible = false
		_set_layer(Layers.SHADOW_GEOMETRY)
	else:
		_set_open()
	opened.emit(tick, source)
	return 0


## V-01d (#227, #232): alleen P1, solo, met de echo aan (ook als hij Leeg is).
func _wants_schaduwklep(source: String) -> bool:
	return source == "p1" and combat != null and not combat.coop and combat.echo_on


func _end_schaduwklep(tick: int, by: String) -> void:
	schaduwklep = false
	schaduwklep_tot = -1
	schaduwklep_weg_tick = tick
	schaduwklep_weg_by = by
	_set_open()
	schaduwklep_weg.emit(tick, by)


func _set_open() -> void:
	alive = false
	visible = false
	_set_layer(0)


## Zet de laag van de klep, ook meteen in de physics-ruimte (de controles van
## de echo in stap (1) van de volgende tick zien hem dan al).
func _set_layer(layer: int) -> void:
	if _klep == null:
		return
	_klep.collision_layer = layer
	_klep.visible = layer == Layers.WORLD
	if _klep.is_inside_tree():
		PhysicsServer2D.body_set_collision_layer(_klep.get_rid(), layer)


func has_persistent_state() -> bool:
	return true


func get_persistent_state() -> bool:
	return is_open


## Open uit de save (of opnieuw geladen): weg, zonder schaduwklep.
func set_persistent_state(on: bool) -> void:
	if on:
		is_open = true
		schaduwklep = false
		schaduwklep_tot = -1
		_set_open()


func is_returning() -> bool:
	return false


func is_markable() -> bool:
	return false


## Het luik loopt niet, valt niet aan en staat niet stil.
func stun(_tick: int) -> void:
	pass


## Stap (5): de schaduwklep gaat uiterlijk op `breuk + D + G` weg.
func sim_update(tick: int, _bodies: Array[Node2D]) -> void:
	if schaduwklep and tick >= schaduwklep_tot:
		_end_schaduwklep(tick, "tijd")
