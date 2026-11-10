extends Area2D
## Een kamer (gdd E-04e): een rechthoek in de gebiedsscène die tegelijk de
## camerazone en de streameenheid van de AreaLoader is (ontwerp.md §3a).
##
## De rechthoek komt uit de eerste `CollisionShape2D`-kind met een
## `RectangleShape2D` (zo tekent de level designer hem in de editor), of uit
## `make()` in code. Gameplay gebruikt die rechthoek alleen met een eigen
## puntcontrole (`contains`), nooit via de physics-ruimte: de Area2D zelf
## staat op geen enkele laag en monitort niets (A2, standaarden §4.8).
##
## Inhoud die meestreamt (geometrie, decor) staat in `inhoud`: de AreaLoader
## zet die scène als kind onder de kamer als hij geladen wordt en haalt hem
## weg als hij niet meer geladen is. Zonder `inhoud` staat alles al in de
## gebiedsscène (zoals de flow-kamer) en wisselt alleen `geladen`.

## Unieke naam binnen het gebied; ook de sleutel in een save (checkpoint).
## Leeg = de naam van de node.
@export var kamer_id: StringName = &""
## De kamers waarmee deze kamer een doorgang deelt (E-04a), op `kamer_id`.
## Altijd wederzijds; de AreaLoader controleert dat bij het laden.
@export var buren: PackedStringArray = PackedStringArray()
## Scène die meestreamt met de kamer (optioneel).
@export var inhoud: PackedScene
## Het gemaal van de wijk van deze kamer (L-14, LM-13; ontwerp.md §3a): de
## id in `GameState.gemalen` zonder gebied, dus `<kamer_id>/<pad in de
## inhoud>` (zoals `AreaLoader.gemaal_id`), bv. `K3/Gemaal`. Leeg = geen
## wijk: telt als niet vol (terugkerende vijanden komen altijd terug).
@export var wijk_gemaal: StringName = &""

## Is de kamer nu geladen? Gezet door de AreaLoader.
var geladen := false
## De ingeladen `inhoud`, of null.
var inhoud_node: Node = null

var _rect := Rect2()
var _has_rect := false


## Kamer in code (tests, gegenereerde gebieden). `rect` in wereldcoördinaten.
static func make(id: StringName, rect: Rect2, p_buren: Array = []) -> Area2D:
	var kamer: Area2D = load("res://scripts/world/kamer.gd").new()
	kamer.kamer_id = id
	kamer.name = String(id)
	kamer.buren = PackedStringArray(p_buren)
	kamer.position = rect.get_center()
	var shape := CollisionShape2D.new()
	var box := RectangleShape2D.new()
	box.size = rect.size
	shape.shape = box
	kamer.add_child(shape)
	return kamer


func _init() -> void:
	collision_layer = 0
	collision_mask = 0
	monitoring = false
	monitorable = false


func id() -> StringName:
	return kamer_id if kamer_id != &"" else StringName(name)


## De rechthoek in wereldcoördinaten. Wordt één keer bepaald (kamers bewegen
## niet); `refresh_rect()` na een verplaatsing in de editor of een test.
func rect() -> Rect2:
	if not _has_rect:
		refresh_rect()
	return _rect


func refresh_rect() -> void:
	_has_rect = true
	_rect = Rect2()
	for child in get_children():
		if child is CollisionShape2D and (child as CollisionShape2D).shape is RectangleShape2D:
			var shape := child as CollisionShape2D
			var size := (shape.shape as RectangleShape2D).size
			var center := global_position + shape.position
			_rect = Rect2(center - size * 0.5, size)
			return
	_has_rect = false


## Heeft de kamer een rechthoek met oppervlakte?
func has_rect() -> bool:
	return rect().has_area()


## Ligt `point` in de kamer? Halfopen: de linker- en bovenrand horen erbij,
## de rechter- en onderrand bij de volgende kamer. Zo hoort elk punt op een
## grens bij precies één kamer (E-04e: kamers overlappen niet).
func contains(point: Vector2) -> bool:
	return rect().has_point(point)
