extends Area2D
## Een gameplay-zone op laag 7 (gdd E-05): `FelLicht` (E-08c, E-11) of
## `Schaduwgevaar` (E-08d).
##
## Een zone is statisch. De echo vindt hem met een ruimte-query (standaarden
## §4.8: mag tegen statische geometrie); er wordt geen `Area2D`-signaal of
## `get_overlapping_bodies()` gebruikt. Alleen de zone telt, niet het beeld (E-11).

const Layers = preload("res://scripts/world/layers.gd")

enum Kind { FEL_LICHT, GEVAAR }

var kind: Kind = Kind.FEL_LICHT
## E-11: een lamp die uit is, heeft geen fel licht. Uit = de zone telt niet.
var enabled := true


func setup(p_kind: Kind, size: Vector2) -> void:
	kind = p_kind
	collision_layer = Layers.ZONES
	collision_mask = 0
	monitoring = false
	monitorable = true
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = size
	shape.shape = rect
	add_child(shape)
