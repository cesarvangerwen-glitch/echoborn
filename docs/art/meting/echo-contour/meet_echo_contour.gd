extends SceneTree
## Meting van de echo-contour in de engine (Technical Artist, #226, risico R2).
##
## Rendert de echte kamerscènes (node `Art` met de lagen, `set_staat`) in Godot
## 4.6 met de figuren uit `figuren/` (zie `exporteer_figuren.py`) op de slechtste
## plekken. De echo krijgt de contour uit `game/art/shaders/echo_contour.gdshader`
## (`EchoContour`), of geen (ter vergelijking). Daarna meet het per figuur:
##
## - **A (figuur)**: |p90 L\* van de figuur − mediaan L\* van de ring|, precies
##   zoals de AD (`genereer_slice_deel2.py`): figuur = de getekende pixels (bij
##   de echo: rand, arcering, ogen en contour), m = figuur + 1 px, ring = 3–6 px
##   van m (kruis, zoals `ndimage.binary_dilation`);
## - **B (contour)**: |p90 L\* van de contour − mediaan L\* van de ring|; de
##   contour = de pixels van de figuur met een buur (kruis) erbuiten;
## - **leesbaarheid** = max(A, B) (bible §6.4: "op de vulling of de contour").
## Norm: ≥ 40 overal; P1 ≥ 40 en P1 het hoogst.
##
## Draaien vanaf de repo-root (venster nodig, dus xvfb en opengl3):
##   xvfb-run -a godot --path game --rendering-driver opengl3 --audio-driver Dummy \
##     -s "$PWD/docs/art/meting/echo-contour/meet_echo_contour.gd"
## Schrijft `resultaten.json` en `uitsneden_x4.png` naast dit script.

const Layout = preload("res://levels/kadewijk/kadewijk_layout.gd")
const EchoContour = preload("res://art/shaders/echo_contour.gd")

const SCENES := {
	&"S3": "res://levels/kadewijk/s3_vismarkt.tscn",
	&"S8": "res://levels/kadewijk/s8_machinehal.tscn",
	&"S9": "res://levels/kadewijk/s9_lage_kade.tscn",
}
## Plekken en figuren zoals in de renders van de AD (wereldcoördinaten, voeten midden onder):
## [soort, pose, x, y, spiegel].
const GEVALLEN := [
	{"plek": "S3 voor het verlichte winkelraam", "kamer": &"S3",
		"figuren": [["echo", "run2", 1954, 260, false], ["p1", "run0", 2030, 260, false]]},
	{"plek": "S9 rustpunt bij de bootjes", "kamer": &"S9",
		"figuren": [["echo", "run2", 3460, 635, true], ["p1", "run0", 3380, 635, true]]},
	{"plek": "S8 bij de ketel naast P1 (concept-boss)", "kamer": &"S8", "boss": Vector2(4180, 680),
		"figuren": [["p1", "run0", 4416, 680, false], ["echo", "jump", 4448, 660, false]]},
]
const STATEN := ["grijs", "kleur"]
const MARGE := 12

var _dir := ""
var _posities: Dictionary = {}


func _init() -> void:
	_dir = (get_script() as Script).resource_path.get_base_dir()
	_posities = JSON.parse_string(FileAccess.get_file_as_string(_dir + "/posities.json"))
	_run.call_deferred()


func _tex(naam: String) -> Texture2D:
	return ImageTexture.create_from_image(Image.load_from_file(_dir + "/figuren/" + naam + ".png"))


func _run() -> void:
	var uit: Array = []
	var uitsneden: Array[Image] = []
	var fouten := 0
	for geval: Dictionary in GEVALLEN:
		for staat: String in STATEN:
			for contour: bool in [true, false]:
				_contour_staat = contour
				var r: Array = await _render(geval, staat, contour)
				var img: Image = r[0]
				var rects: Array = r[1]
				var regel := {"plek": geval["plek"], "staat": staat, "contour": contour, "figuren": []}
				var alle: Array[Rect2i] = []
				for fr: Array in rects:
					alle.append(fr[1])
				for i in rects.size():
					var m := _meet(img, rects, i)
					regel["figuren"].append(m)
				uit.append(regel)
				var crop := _unie(alle).grow(MARGE).intersection(Rect2i(Vector2i.ZERO, img.get_size()))
				var u := img.get_region(crop)
				u.resize(u.get_width() * 4, u.get_height() * 4, Image.INTERPOLATE_NEAREST)
				uitsneden.append(u)
				var tekst := PackedStringArray()
				for m: Dictionary in regel["figuren"]:
					tekst.append("%s A %.1f B %s lees %.1f" % [m["soort"], m["A"], "%.1f" % m["B"] if m["B"] >= 0.0 else "-", m["lees"]])
				print("%-42s %-5s contour %-5s | %s" % [geval["plek"], staat, contour, " | ".join(tekst)])
				if contour:
					var echo: Dictionary = regel["figuren"].filter(func(m: Dictionary) -> bool: return m["soort"] == "echo")[0]
					var p1: Dictionary = regel["figuren"].filter(func(m: Dictionary) -> bool: return m["soort"] == "p1")[0]
					regel["norm"] = echo["lees"] >= 40.0 and p1["lees"] >= 40.0 and p1["lees"] >= echo["lees"]
					if not regel["norm"]:
						fouten += 1
	var f := FileAccess.open(_dir + "/resultaten.json", FileAccess.WRITE)
	f.store_string(JSON.stringify(uit, " "))
	f.close()
	_plak(uitsneden).save_png(_dir + "/uitsneden_x4.png")
	print("klaar: %d gevallen met contour buiten de norm" % fouten)
	quit(1 if fouten > 0 else 0)


func _render(geval: Dictionary, staat: String, contour: bool) -> Array:
	var id: StringName = geval["kamer"]
	var room: Rect2 = Layout.ROOMS[id]
	var vp := SubViewport.new()
	vp.size = Vector2i(room.size)
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	vp.canvas_item_default_texture_filter = Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_NEAREST
	root.add_child(vp)
	var world := Node2D.new()
	world.position = -room.position
	vp.add_child(world)
	var houder := Node2D.new()
	houder.position = room.get_center()
	world.add_child(houder)
	var inhoud: Node = load(SCENES[id]).instantiate()
	houder.add_child(inhoud)
	await process_frame
	for child in inhoud.get_children():
		if child is CanvasItem and child.name != &"Art":
			(child as CanvasItem).visible = false
	inhoud.get_node(^"Art").set_staat(staat)
	var rects: Array = []
	if geval.has("boss"):
		var boss := Sprite2D.new()
		boss.texture = _tex("boss_fase1")
		boss.centered = false
		boss.position = Vector2(geval["boss"]) - Vector2(0, float(_posities["boss_av"]))
		world.add_child(boss)
	for fig: Array in geval["figuren"]:
		var soort: String = fig[0]
		var naam := "%s_%s" % [soort, fig[1]] + ("_" + staat if soort == "echo" else "")
		var maat: Array = _posities["maten"][naam]
		var s := Sprite2D.new()
		s.texture = _tex(naam)
		s.centered = false
		s.flip_h = fig[4]
		s.position = Vector2(int(fig[2]) - int(maat[0]) / 2 - 1, int(fig[3]) - int(maat[1]) - 1)
		world.add_child(s)
		if soort == "echo" and contour:
			s.material = EchoContour.materiaal()
		var tl := Vector2i(s.position - room.position)
		rects.append([soort, Rect2i(tl, Vector2i(s.texture.get_size())), s.texture.get_image(), s.flip_h])
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	var img := vp.get_texture().get_image()
	vp.queue_free()
	await process_frame
	return [img, rects]


## L* (CIELAB, D65) van een sRGB-kleur.
static func _l(c: Color) -> float:
	var lin := func(v: float) -> float: return v / 12.92 if v <= 0.04045 else pow((v + 0.055) / 1.055, 2.4)
	var y: float = 0.2126 * lin.call(c.r) + 0.7152 * lin.call(c.g) + 0.0722 * lin.call(c.b)
	var f := pow(y, 1.0 / 3.0) if y > 0.008856 else 7.787 * y + 16.0 / 116.0
	return 116.0 * f - 16.0


static func _p(waarden: Array, q: float) -> float:
	if waarden.is_empty():
		return -1.0
	var s := waarden.duplicate()
	s.sort()
	var pos := q * (s.size() - 1)
	var lo := int(floor(pos))
	var hi := mini(lo + 1, s.size() - 1)
	return lerpf(s[lo], s[hi], pos - lo)


## Pixels van een figuur in de render: [getekend, contour]. Getekend = in het silhouet
## alfa ≥ 2/255, plus de contour. Contour: bij de echo met shader de pixels net buiten het
## silhouet (kruis); bij P1 zijn eigen buitenste pixels (zijn contour zit in de sprite).
func _figuur_pixels(fr: Array, met_contour: bool) -> Array:
	var rect: Rect2i = fr[1]
	var tex: Image = fr[2]
	var getekend := {}
	var silhouet := {}
	for y in rect.size.y:
		for x in rect.size.x:
			var tx := rect.size.x - 1 - x if fr[3] else x
			var a := tex.get_pixel(tx, y).a
			if a > 0.0:
				silhouet[rect.position + Vector2i(x, y)] = true
				if a * 255.0 >= 1.5:
					getekend[rect.position + Vector2i(x, y)] = true
	var contour := {}
	for p: Vector2i in silhouet:
		for d: Vector2i in KRUIS:
			if not silhouet.has(p + d):
				if met_contour:
					contour[p + d] = true
				elif fr[0] == "p1":
					contour[p] = true
	getekend.merge(contour)
	return [getekend, contour]


const KRUIS := [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]


func _meet(img: Image, rects: Array, i: int) -> Dictionary:
	var fr: Array = rects[i]
	var soort: String = fr[0]
	var contour_aan := soort == "echo" and _contour_staat
	var fc := _figuur_pixels(fr, contour_aan)
	var fig: Dictionary = fc[0]
	var cont: Dictionary = fc[1]
	var anderen := {}
	for j in rects.size():
		if j != i:
			anderen.merge(_figuur_pixels(rects[j], rects[j][0] == "echo" and _contour_staat)[0])
	# afstand (kruis) tot m = figuur + 1 px
	var m := {}
	for p: Vector2i in fig:
		m[p] = true
		for d: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			m[p + d] = true
	var dist := {}
	var rand: Array = m.keys()
	for p: Vector2i in rand:
		dist[p] = 0
	var stap := 0
	while stap < 6:
		stap += 1
		var nieuw: Array = []
		for p: Vector2i in rand:
			for d: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				var q: Vector2i = p + d
				if not dist.has(q):
					dist[q] = stap
					nieuw.append(q)
		rand = nieuw
	var w := img.get_width()
	var h := img.get_height()
	var ring: Array = []
	for p: Vector2i in dist:
		if dist[p] > 2 and p.x >= 0 and p.y >= 0 and p.x < w and p.y < h and not anderen.has(p):
			ring.append(_l(img.get_pixelv(p)))
	var lf: Array = []
	var lc: Array = []
	for p: Vector2i in fig:
		if p.x < 0 or p.y < 0 or p.x >= w or p.y >= h:
			continue
		var l := _l(img.get_pixelv(p))
		lf.append(l)
		if cont.has(p):
			lc.append(l)
	var bg := _p(ring, 0.5)
	var a := absf(_p(lf, 0.9) - bg)
	var b := absf(_p(lc, 0.9) - bg) if not lc.is_empty() else -1.0
	return {"soort": soort, "A": snappedf(a, 0.1), "B": snappedf(b, 0.1), "lees": snappedf(maxf(a, b), 0.1),
		"ring_L": snappedf(bg, 0.1)}


var _contour_staat := false


func _unie(rs: Array[Rect2i]) -> Rect2i:
	var u := rs[0]
	for r in rs:
		u = u.merge(r)
	return u


func _plak(beelden: Array[Image]) -> Image:
	var kolommen := 4
	var bw := 0
	var bh := 0
	for b in beelden:
		bw = maxi(bw, b.get_width())
		bh = maxi(bh, b.get_height())
	var rijen := ceili(beelden.size() / float(kolommen))
	var out := Image.create(bw * kolommen, bh * rijen, false, Image.FORMAT_RGBA8)
	out.fill(Color(0.1, 0.1, 0.1))
	for i in beelden.size():
		var b := beelden[i]
		b.convert(Image.FORMAT_RGBA8)
		out.blit_rect(b, Rect2i(Vector2i.ZERO, b.get_size()), Vector2i((i % kolommen) * bw, (i / kolommen) * bh))
	return out
