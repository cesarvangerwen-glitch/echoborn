extends RefCounted
## De donkere buitencontour van 1 px om de echo (Technical Artist, #226, risico
## R2; bible §1 "lijnwerk", de meting in `docs/art/meting/echo-contour/`).
##
## `EchoContour.op(echo)` zet hem op elk beeld van een echo:
## - een `Sprite2D` of `AnimatedSprite2D` krijgt `echo_contour.gdshader` (de
##   echte art van de echo: 1 px transparante rand per frame, holle pixels alfa
##   1/255, filter Nearest);
## - het placeholderblok (`Polygon2D` van `BodyBuilder`) krijgt een kader van
##   1 px in dezelfde kleur, net buiten het blok (`Contour`, vier strookjes).
## De contour hangt niet af van de toestand (grijs, half, kleur) en blijft dus
## altijd staan. Idempotent: twee keer `op` geeft één contour.

const SHADER := preload("res://art/shaders/echo_contour.gdshader")
## Bijna-zwart van de echo (R5 `outer_of`, #07050c).
const KLEUR := Color8(7, 5, 12)
const NAAM := &"Contour"


static func op(echo: Node) -> void:
	for child in echo.get_children():
		if child is Sprite2D or child is AnimatedSprite2D:
			_op_sprite(child as CanvasItem)
		elif child is Polygon2D and child.name != NAAM:
			_op_blok(child as Polygon2D)


static func materiaal() -> ShaderMaterial:
	var mat := ShaderMaterial.new()
	mat.shader = SHADER
	mat.set_shader_parameter(&"contour_kleur", Vector4(KLEUR.r, KLEUR.g, KLEUR.b, 1.0))
	return mat


static func _op_sprite(sprite: CanvasItem) -> void:
	if sprite.material is ShaderMaterial and (sprite.material as ShaderMaterial).shader == SHADER:
		return
	sprite.material = materiaal()
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST


## Een kader van 1 px om de rechthoek van `blok` (de placeholder is een
## rechthoek; de echte art krijgt de shader).
static func _op_blok(blok: Polygon2D) -> void:
	if blok.get_parent().has_node(NodePath(String(NAAM))):
		return
	var r := Rect2(blok.polygon[0], Vector2.ZERO)
	for p in blok.polygon:
		r = r.expand(p)
	r.position += blok.position
	var kader := Node2D.new()
	kader.name = NAAM
	for strook: Rect2 in [
			Rect2(r.position.x - 1, r.position.y - 1, r.size.x + 2, 1),
			Rect2(r.position.x - 1, r.end.y, r.size.x + 2, 1),
			Rect2(r.position.x - 1, r.position.y, 1, r.size.y),
			Rect2(r.end.x, r.position.y, 1, r.size.y)]:
		var p := Polygon2D.new()
		p.color = KLEUR
		p.polygon = PackedVector2Array([strook.position, Vector2(strook.end.x, strook.position.y), strook.end, Vector2(strook.position.x, strook.end.y)])
		kader.add_child(p)
	blok.add_sibling(kader)
