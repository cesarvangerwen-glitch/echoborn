extends "res://scripts/combat/combat_target.gd"
## Het pomprad van een gemaal (gdd LM-03): een gedeeld object met een hurtbox
## van 32 × 48 px, niet `Merkbaar`.
##
## Het is een doel voor `Combat`, zodat een treffer van P1, de echo (gewone
## echo-treffer, E-02m) of P2 vanzelf binnenkomt via `Combat.hit`. Het
## gemaal (`gemaal.gd`) maakt van die treffer een pompslag. Het rad loopt
## niet, valt niet aan en gaat nooit stuk.

const HURTBOX := Vector2(32, 48)


## Geen blijvende stand (LM-13 geldt niet): ook vóór `setup_pomprad`, als de
## soort nog op ENEMY staat (`AreaLoader.known_object_flags` maakt de inhoud
## buiten de boom aan).
func has_persistent_state() -> bool:
	return false


func setup_pomprad() -> void:
	setup_target(Kind.DUMMY)
	name = "Pomprad"
	(shape as RectangleShape2D).size = HURTBOX
	for child in get_children():
		if child is Polygon2D:
			var h := HURTBOX * 0.5
			(child as Polygon2D).polygon = PackedVector2Array([
				Vector2(-h.x, -h.y), Vector2(h.x, -h.y), Vector2(h.x, h.y), Vector2(-h.x, h.y)])
			(child as Polygon2D).color = Color(0.5, 0.5, 0.45)
