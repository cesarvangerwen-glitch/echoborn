extends SceneTree
## Leesbaarheid van de slice-vijanden in de engine (Technical Artist, #272;
## `docs/art/animatie-timing.md` §2.4 en §2.6).
##
## Rendert de echte kamerscènes (node `Art`, `set_staat`) in Godot 4.6 met echte
## `SliceEnemy`-nodes en hun sprites (`VijandBeeld`) op de plekken uit combat
## §2.6 (dezelfde als `genereer_vijanden.py`, `PLEKKEN`), in grijs (`lit` uit) en
## kleur (`lit` aan, s = 2). De pose kiest de code zelf: `phase` en `_phase_end`
## gezet, dan `_update_visual(tick)`. Daarna meet het:
##
## - **bovenrand**: |p90 L\* van de bovenrand − mediaan L\* van de ring van 2–6 px
##   rond de figuur| (de ring in de render zonder vijand). De bovenrand = de
##   bovenste pixel van het silhouet in vijandkern 7 (index-atlas: R = 22,
##   G = 7 × 32 + 16; erboven niets of de contour, R = 21 en tint 0), zoals
##   `bovenrand_van(q, 1)` van de Animator; staan, frame 0.
## - **figuur**: hetzelfde met alle getekende pixels (p90).
## - **tells** (vroeg / laat / actief): de vijand in zijn aanloop- of actieve
##   frame, met en zonder `Tell`: ΔL\* gemiddeld over het vlak en de mediaan over
##   de gezette pixels van de tell die zichtbaar blijven (niet onder het lijf).
##   Anders dan de Animator (de tell los op de achtergrond) staat hier de vijand
##   erbij, in de pose van dat moment, zoals in het spel.
##
## Draaien vanaf de repo-root (venster nodig, dus xvfb en opengl3):
##   xvfb-run -a godot --path game --rendering-driver opengl3 --audio-driver Dummy \
##     -s "$PWD/docs/art/meting/vijanden/meet_vijanden.gd"
## Schrijft `resultaten.json` en `tells_kleur_x3.png` naast dit script.

const Layout = preload("res://levels/kadewijk/kadewijk_layout.gd")
const SliceEnemy = preload("res://scripts/combat/slice_enemy.gd")
const EnemyData = preload("res://scripts/combat/enemy_data.gd")
const Gemaalmeester = preload("res://scripts/combat/gemaalmeester.gd")

const SCENES := {
	&"S2": "res://levels/kadewijk/s2_kadegang.tscn",
	&"S3": "res://levels/kadewijk/s3_vismarkt.tscn",
	&"S4": "res://levels/kadewijk/s4_brugkloof.tscn",
	&"S6": "res://levels/kadewijk/s6_gemaalplein.tscn",
	&"S7": "res://levels/kadewijk/s7_sluiskelder.tscn",
	&"S8": "res://levels/kadewijk/s8_machinehal.tscn",
	&"S9": "res://levels/kadewijk/s9_lage_kade.tscn",
}
const TYPES := {"kadeloper": SliceEnemy.Type.KADELOPER, "schotdrager": SliceEnemy.Type.SCHOTDRAGER,
	"dwaallicht": SliceEnemy.Type.DWAALLICHT}
## [kamer, type, scène-x, vloer (wereld-y), kijkrichting, wat] (genereer_vijanden.py `PLEKKEN`;
## bij het Dwaallicht de vloer of het water onder zijn baan). S8: de spuigaten van de boss.
const PLEKKEN := [
	[&"S2", "kadeloper", 880, 230, 1, "E-paar links"], [&"S2", "kadeloper", 908, 230, -1, "E-paar rechts"],
	[&"S3", "kadeloper", 2140, 260, -1, "golf 1 E-paar"], [&"S3", "kadeloper", 2168, 260, -1, "golf 1 E-paar"],
	[&"S3", "kadeloper", 2360, 260, -1, "golf 1 los"],
	[&"S3", "schotdrager", 1770, 260, 1, "golf 2 E-paar"], [&"S3", "kadeloper", 1798, 260, 1, "golf 2 E-paar"],
	[&"S3", "kadeloper", 1990, 260, 1, "golf 2 los"],
	[&"S4", "kadeloper", 3260, 260, -1, "overkant"],
	[&"S6", "kadeloper", 4340, 260, -1, "K-paar"], [&"S6", "kadeloper", 4382, 260, -1, "K-paar"],
	[&"S7", "dwaallicht", 5013, 620, 1, "baan 1/3"], [&"S7", "dwaallicht", 5067, 620, 1, "baan 2/3"],
	[&"S8", "kadeloper", -1, 680, 1, "add spuigat links"], [&"S8", "kadeloper", -2, 680, -1, "add spuigat rechts"],
	[&"S9", "kadeloper", 1060, 635, -1, "E-paar (verlicht)"], [&"S9", "kadeloper", 1088, 635, -1, "E-paar (verlicht)"],
	[&"S9", "dwaallicht", 2310, 635, 1, "baan (verlicht)"],
]
## De tells van de Animator (tell_metingen): [kamer, type, x, vloer, kijkrichting].
const TELLS := [
	[&"S3", "kadeloper", 1798, 260, 1], [&"S3", "schotdrager", 1770, 260, 1],
	[&"S6", "kadeloper", 4340, 260, -1], [&"S9", "kadeloper", 1060, 635, -1],
	[&"S7", "dwaallicht", 5013, 620, 1], [&"S9", "dwaallicht", 2310, 635, 1],
]
const STATEN := ["grijs", "kleur"]
const KERN := 22
const LIJF := 21
const RAND_G := 7 * 32 + 16
const TICK := 1000

var _dir := ""
var _vp: SubViewport
var _world: Node2D
var _kamer: StringName = &""
var _staat := ""
var _index := {}


func _init() -> void:
	_dir = (get_script() as Script).resource_path.get_base_dir()
	_run.call_deferred()


func _run() -> void:
	var uit := {"plekken": [], "tells": []}
	var crops: Array[Image] = []
	for staat: String in STATEN:
		for p: Array in PLEKKEN:
			await _kamer_klaar(p[0], staat)
			var e := _vijand(p, staat)
			var zonder := await _shot([e], false)
			e.visible = true
			var met := await _shot([e], true)
			var r := _meet_figuur(e, zonder, met)
			r.merge({"kamer": String(p[0]), "type": p[1], "x": p[2], "wat": p[5], "staat": staat})
			uit["plekken"].append(r)
			print("%-3s %-11s %5d %-20s %-5s bovenrand %5.1f  figuur %5.1f" % [p[0], p[1], p[2], p[5], staat, r["bovenrand"], r["figuur"]])
			e.free()
		for p: Array in TELLS:
			await _kamer_klaar(p[0], staat)
			var fasen := ["vroeg", "laat"] if p[1] == "dwaallicht" else ["vroeg", "laat", "actief"]
			for fase: String in fasen:
				var e := _vijand(p, staat)
				_pose(e, fase)
				var tell := e.get_node("Tell") as Sprite2D
				tell.visible = false
				var zonder := await _shot([e], true)
				tell.visible = true
				var met := await _shot([e], true)
				var r := _meet_tell(e, zonder, met)
				r.merge({"kamer": String(p[0]), "type": p[1], "x": p[2], "staat": staat, "fase": fase,
					"lijf": "%s/%d" % [e.get_node("Lijf").anim, e.get_node("Lijf").frame_nr]})
				uit["tells"].append(r)
				print("tell %-3s %-11s %-5s %-6s gemiddeld %5.1f  gezet %5.1f  (zichtbaar %d px, lijf %s)" % [
					p[0], p[1], staat, fase, r["gem"], r["gezet"], r["n"], r["lijf"]])
				if staat == "kleur":
					crops.append(_crop(met, e))
				e.free()
	var f := FileAccess.open(_dir + "/resultaten.json", FileAccess.WRITE)
	f.store_string(JSON.stringify(uit, " "))
	f.close()
	_plak(crops).save_png(_dir + "/tells_kleur_x3.png")
	print("klaar")
	quit(0)


## Een kamer (en een staat) in de viewport; de inhoud van de scène behalve `Art` uit.
func _kamer_klaar(id: StringName, staat: String) -> void:
	if id == _kamer and staat == _staat:
		return
	if _vp != null:
		_vp.free()
		await process_frame
	_kamer = id
	_staat = staat
	var room: Rect2 = Layout.ROOMS[id]
	_vp = SubViewport.new()
	_vp.size = Vector2i(room.size)
	_vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	_vp.canvas_item_default_texture_filter = Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_NEAREST
	root.add_child(_vp)
	_world = Node2D.new()
	_world.position = -room.position
	_vp.add_child(_world)
	var houder := Node2D.new()
	houder.position = room.get_center()
	_world.add_child(houder)
	var inhoud: Node = load(SCENES[id]).instantiate()
	houder.add_child(inhoud)
	await process_frame
	for child in inhoud.get_children():
		if child is CanvasItem and child.name != &"Art":
			(child as CanvasItem).visible = false
	inhoud.get_node(^"Art").set_staat(staat)
	if id == &"S8":
		var boss := Gemaalmeester.new()
		boss.name = "Boss"
		_world.add_child(boss)
		boss.setup_gemaalmeester(Layout.ARENA_ORIGIN)
		boss.update_visual(TICK)


func _vijand(p: Array, staat: String) -> SliceEnemy:
	var e := SliceEnemy.new()
	e.lit = staat == "kleur"
	var x := float(p[2])
	if int(p[2]) < 0:
		var g := "gemaalmeester"
		x = Layout.ARENA_ORIGIN.x + EnemyData.value(g, "spuigat_links" if int(p[2]) == -1 else "spuigat_rechts")
	var vloer := float(p[3])
	if p[1] == "dwaallicht":
		e.setup_enemy(TYPES[p[1]], x, vloer, x, x)
	else:
		e.setup_enemy(TYPES[p[1]], x, vloer)
	e.facing = int(p[4])
	e._attack_facing = int(p[4])
	e.visible = false
	_world.add_child(e)
	e._update_visual(TICK)
	return e


## Aanloop vroeg (een kwart), laat (frame 3) of actief (het verste frame).
func _pose(e: SliceEnemy, fase: String) -> void:
	var totaal := EnemyData.windup(e._group(), e.lit)
	match fase:
		"vroeg":
			e.phase = SliceEnemy.Phase.WINDUP
			e._phase_end = TICK + totaal - int(totaal * 0.25)
		"laat":
			e.phase = SliceEnemy.Phase.WINDUP
			e._phase_end = TICK + 4
		"actief":
			e.phase = SliceEnemy.Phase.ACTIVE
			e._phase_end = TICK + EnemyData.ticks(e._group(), "actief")
			e.active_box = e._walker_box()
	e._update_visual(TICK)
	e.visible = true


func _shot(_e: Array, _met: bool) -> Image:
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	return _vp.get_texture().get_image()


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


func _index_img(e: SliceEnemy) -> Image:
	var naam: String = e._group()
	if not _index.has(naam):
		var pad := "res://art/animatie/%s/%s_index.png" % [naam, naam]
		_index[naam] = Image.load_from_file(ProjectSettings.globalize_path(pad))
	return _index[naam]


## Pixels van een sprite in de viewport (`global_position` = viewport-px: de wereld staat op −kamer): {Vector2i(viewport): Vector2i(atlas)}, met alfa > 0.
func _pixels(s: Sprite2D) -> Dictionary:
	var out := {}
	var img := s.texture.get_image()
	var r := Rect2i(s.region_rect)
	var tl := Vector2i(s.global_position.round())
	for y in r.size.y:
		for x in r.size.x:
			var ax := r.position.x + (r.size.x - 1 - x if s.flip_h else x)
			if img.get_pixel(ax, r.position.y + y).a > 0.0:
				out[tl + Vector2i(x, y)] = Vector2i(ax, r.position.y + y)
	return out


func _ring(m: Dictionary, w: int, h: int) -> Array[Vector2i]:
	var d2 := _grow(m, 2)
	var d6 := _grow(d2, 4)
	var ring: Array[Vector2i] = []
	for p: Vector2i in d6:
		if not d2.has(p) and p.x >= 0 and p.y >= 0 and p.x < w and p.y < h:
			ring.append(p)
	return ring


## Kruis-dilatie, `n` keer (zoals `ndimage.binary_dilation`).
func _grow(m: Dictionary, n: int) -> Dictionary:
	var cur := m.duplicate()
	for i in n:
		var nxt := cur.duplicate()
		for p: Vector2i in cur:
			for d: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				nxt[p + d] = true
		cur = nxt
	return cur


func _meet_figuur(e: SliceEnemy, zonder: Image, met: Image) -> Dictionary:
	var lijf := e.get_node("Lijf") as Sprite2D
	var px := _pixels(lijf)
	var index := _index_img(e)
	var kleur := lijf.texture.get_image()
	var ring := _ring(px, met.get_width(), met.get_height())
	var l_ring: Array = ring.map(func(p: Vector2i) -> float: return _l(zonder.get_pixelv(p)))
	var achter := _p(l_ring, 0.5)
	var fig: Array = []
	var rand: Array = []
	for p: Vector2i in px:
		if p.x < 0 or p.y < 0 or p.x >= met.get_width() or p.y >= met.get_height():
			continue
		var l := _l(met.get_pixelv(p))
		fig.append(l)
		var a: Vector2i = px[p]
		var c := index.get_pixelv(a)
		# Boven de rand ligt niets, of de contour van 1 px buiten het silhouet (vijandlijf, tint 0).
		var boven := index.get_pixel(a.x, a.y - 1) if a.y > 0 else Color(0, 0, 0, 0)
		var boven_leeg := a.y == 0 or kleur.get_pixel(a.x, a.y - 1).a == 0.0 \
			or (boven.r8 == LIJF and boven.g8 == 16)
		if c.r8 == KERN and c.g8 == RAND_G and boven_leeg:
			rand.append(l)
	return {"bovenrand": absf(_p(rand, 0.9) - achter) if not rand.is_empty() else -1.0,
		"figuur": absf(_p(fig, 0.9) - achter), "ring": achter, "rand_px": rand.size()}


func _meet_tell(e: SliceEnemy, zonder: Image, met: Image) -> Dictionary:
	var tell := e.get_node("Tell") as Sprite2D
	var px := _pixels(tell)
	var vlak := Rect2i(Vector2i(tell.global_position.round()) + Vector2i(1, 1),
		Vector2i(tell.region_rect.size) - Vector2i(2, 2))
	var som := 0.0
	var n := 0
	for y in range(vlak.position.y, vlak.end.y):
		for x in range(vlak.position.x, vlak.end.x):
			som += _l(met.get_pixel(x, y)) - _l(zonder.get_pixel(x, y))
			n += 1
	var gezet: Array = []
	for p: Vector2i in px:
		var a := met.get_pixelv(p)
		var b := zonder.get_pixelv(p)
		if not a.is_equal_approx(b):
			gezet.append(absf(_l(a) - _l(b)))
	return {"gem": absf(som / maxf(n, 1)), "gezet": _p(gezet, 0.5), "n": gezet.size(), "tell_px": px.size()}


func _crop(img: Image, e: SliceEnemy) -> Image:
	var c := Vector2i(e.global_position.round())
	var r := Rect2i(c - Vector2i(40, 36), Vector2i(80, 56)).intersection(Rect2i(Vector2i.ZERO, img.get_size()))
	var u := img.get_region(r)
	u.resize(u.get_width() * 3, u.get_height() * 3, Image.INTERPOLATE_NEAREST)
	return u


func _plak(beelden: Array[Image]) -> Image:
	var per_rij := 3
	var w := 240
	var h := 168
	var rijen := int(ceil(beelden.size() / float(per_rij)))
	var uit := Image.create(per_rij * (w + 4), rijen * (h + 4), false, Image.FORMAT_RGBA8)
	uit.fill(Color(0.1, 0.1, 0.1))
	for i in beelden.size():
		var b := beelden[i]
		uit.blit_rect(b, Rect2i(Vector2i.ZERO, b.get_size()), Vector2i((i % per_rij) * (w + 4), (i / per_rij) * (h + 4)))
	return uit
