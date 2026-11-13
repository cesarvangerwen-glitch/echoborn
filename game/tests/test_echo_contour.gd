extends RefCounted
## Tests voor de donkere buitencontour van 1 px om de echo (Technical Artist,
## #226, risico R2; `art/shaders/echo_contour.gd` en `echo_contour.gdshader`).
##
## Headless rendert Godot niet; de meting in de engine (ΔL* op de slechtste
## plekken) staat in `docs/art/meting/echo-contour/` en draait met xvfb. Hier:
## - het placeholderblok krijgt een kader van precies 1 px rondom, in #07050c;
## - een sprite krijgt de shader, met die kleur en filter Nearest;
## - `op` is idempotent;
## - de staart-echo van de Kadewijk heeft de contour, in elke toestand van de
##   kamer-art (de contour hangt niet aan `set_staat`);
## - de shader rekent niet om (geen `source_color`) en kent de holle pixels (alfa 1/255).

const EchoContour = preload("res://art/shaders/echo_contour.gd")
const BodyBuilder = preload("res://scripts/echo/body_builder.gd")
const Scene := preload("res://levels/kadewijk/kadewijk.tscn")
const Layout = preload("res://levels/kadewijk/kadewijk_layout.gd")
const Progress = preload("res://scripts/save/progress.gd")


class StilInput:
	extends RefCounted
	func sample(_tick: int) -> int:
		return 0


func _rect(p: Polygon2D) -> Rect2:
	var r := Rect2(p.polygon[0], Vector2.ZERO)
	for q in p.polygon:
		r = r.expand(q)
	return Rect2(r.position + p.position, r.size)


func test_contour_om_blok(t) -> void:
	var echo := CharacterBody2D.new()
	BodyBuilder.add_box(echo, Color(0.42, 0.36, 0.7, 0.85))
	EchoContour.op(echo)
	EchoContour.op(echo)
	var kaders := echo.get_children().filter(func(c: Node) -> bool: return c.name == EchoContour.NAAM)
	t.check(kaders.size() == 1, "%d contouren na twee keer op, verwacht 1" % kaders.size())
	var kader: Node = kaders[0] if kaders.size() == 1 else null
	t.check(kader != null and kader.get_child_count() == 4, "contour heeft geen 4 strookjes")
	if kader == null:
		echo.free()
		return
	var blok := Rect2(-BodyBuilder.SIZE * 0.5, BodyBuilder.SIZE)
	var buiten := blok.grow(1.0)
	var pixels := {}
	for p: Polygon2D in kader.get_children():
		t.check(p.color == EchoContour.KLEUR and p.color == Color8(7, 5, 12), "strook in %s, verwacht #07050c" % p.color)
		var r := _rect(p)
		for y in range(int(r.position.y), int(r.end.y)):
			for x in range(int(r.position.x), int(r.end.x)):
				var k := Vector2i(x, y)
				t.check(not pixels.has(k), "pixel %s dubbel in de contour" % k)
				pixels[k] = true
	var fout := 0
	for y in range(int(buiten.position.y), int(buiten.end.y)):
		for x in range(int(buiten.position.x), int(buiten.end.x)):
			var in_blok := blok.has_point(Vector2(x, y) + Vector2(0.5, 0.5))
			if pixels.has(Vector2i(x, y)) == in_blok:
				fout += 1
	t.check(fout == 0 and pixels.size() == int(buiten.get_area() - blok.get_area()), "contour is geen ring van 1 px om het blok (%d fouten, %d pixels)" % [fout, pixels.size()])
	echo.free()


func test_contour_op_sprite(t) -> void:
	var echo := Node2D.new()
	var s := Sprite2D.new()
	echo.add_child(s)
	EchoContour.op(echo)
	var mat := s.material as ShaderMaterial
	t.check(mat != null and mat.shader == EchoContour.SHADER, "sprite zonder de contour-shader")
	if mat != null:
		var k: Vector4 = mat.get_shader_parameter(&"contour_kleur")
		t.check(k.is_equal_approx(Vector4(7.0 / 255.0, 5.0 / 255.0, 12.0 / 255.0, 1.0)), "contour_kleur %s" % k)
	t.check(s.texture_filter == CanvasItem.TEXTURE_FILTER_NEAREST, "filter niet Nearest")
	EchoContour.op(echo)
	t.check(s.material == mat, "tweede op vervangt het materiaal")
	t.check(echo.get_node_or_null(NodePath(String(EchoContour.NAAM))) == null, "sprite kreeg ook een blokkader")
	var code := FileAccess.get_file_as_string(EchoContour.SHADER.resource_path)
	t.check(not code.contains("source_color") and code.contains("contour_kleur") and code.contains("1.5"),
		"shader: geen sRGB-omzetting en drempel voor holle pixels (alfa 1/255)")
	echo.free()


func test_staart_echo_kadewijk_heeft_contour(t) -> void:
	var progress := Progress.new()
	progress.name = "TestProgress"
	t.tree.root.add_child(progress)
	var wijk = Scene.instantiate()
	wijk.tail = 60
	wijk.echo_on = true
	wijk.show_hud = false
	wijk.progress = progress
	wijk.start_at = Layout.ROOM_START[&"S3"]
	wijk.input_override = StilInput.new()
	t.tree.root.add_child(wijk)
	await t.tree.physics_frame
	var echo: Node = wijk.echo
	var kader := echo.get_node_or_null(NodePath(String(EchoContour.NAAM))) if echo else null
	t.check(kader != null and kader.get_child_count() == 4, "staart-echo zonder contour")
	var art = wijk.loader.kamers[&"S3"].inhoud_node.get_node(^"Art")
	for st: String in ["kleur", "half", "grijs"]:
		art.set_staat(st)
		await t.tree.process_frame
		var ok: bool = kader != null and kader.visible
		if kader != null:
			for p: Polygon2D in kader.get_children():
				ok = ok and p.visible and p.color == EchoContour.KLEUR
		t.check(ok, "contour weg of anders in staat %s" % st)
	wijk.queue_free()
	progress.queue_free()
	await t.tree.process_frame
