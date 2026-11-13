extends SceneTree
## Controle van de Art Director (#85, deel 2 en 3): zet de kamerlagen van S1–S4 en de
## eenrichtingsstukken (en in S2 de vaste stukken per D) op de blokken van
## `Layout.blocks()` in Godot 4.6, tekent de
## collision-randen erover (cyaan = vast, geel = eenrichting) en bewaart een PNG.
## Geen spelcode: alleen een voorbeeld van de koppeling voor de Technical Artist
## (`docs/art/slice-kadewijk.md` §9.4). Laadt de PNG's met `Image.load_from_file`,
## dus zonder importcache.
##
## Draaien vanaf de repo-root (met xvfb voor een venster):
##   xvfb-run -a godot --path game --rendering-driver opengl3 --audio-driver Dummy \
##     -s "$PWD/docs/art/slice/bron/godot_controle.gd" -- S1 grijs 60 /tmp/s1_grijs.png
const Layout = preload("res://levels/kadewijk/kadewijk_layout.gd")
const DIR := "res://art/wereld/kadewijk/"


func tex(fn: String) -> Texture2D:
	var img := Image.load_from_file(ProjectSettings.globalize_path(DIR + fn))
	return ImageTexture.create_from_image(img)


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var room: StringName = StringName(args[0])
	var staat: String = args[1]
	var d := int(args[2])
	var out: String = args[3]
	var naam: String = {&"S1": "s1_kade_ingang", &"S2": "s2_kadegang", &"S3": "s3_vismarkt", &"S4": "s4_brugkloof"}[room]
	var r: Rect2 = Layout.ROOMS[room]
	var vp := SubViewport.new()
	vp.size = Vector2i(int(r.size.x), int(r.size.y))
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	vp.canvas_item_default_texture_filter = Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_NEAREST
	root.add_child(vp)
	var world := Node2D.new()
	world.position = -r.position
	vp.add_child(world)
	for laag in ["achter", "midden", "speelvlak", "licht", "voor"]:
		var fn: String = "%s_%s_%s.png" % [naam, laag, staat]
		if not FileAccess.file_exists(DIR + fn):
			continue
		var s := Sprite2D.new()
		s.texture = tex(fn)
		s.centered = false
		s.position = r.position
		world.add_child(s)
		if laag == "speelvlak":
			var m: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(DIR + "kadewijk_kamers.json"))
			# vaste stukken per D (S2: de rand van de B3-wand en het B3-blok; deel 3)
			var b3 := maxi(d - 60, 0)
			if room == &"S2":
				var wand := Sprite2D.new()
				wand.texture = tex(m["vaste_stukken"]["S2/B3Wand"]["bestanden"][staat])
				wand.centered = false
				wand.position = Vector2(1250 + b3, 76)
				world.add_child(wand)
				if b3 > 0:
					var blok := Sprite2D.new()
					blok.texture = tex(m["vaste_stukken"]["S2/B3Blok"]["bestanden"][staat])
					blok.centered = false
					blok.region_enabled = true
					blok.region_rect = Rect2(0, 0, b3, 45)
					blok.position = Vector2(1250, 185)
					world.add_child(blok)
			var atlas := tex("kadewijk_eenrichting_%s.png" % staat)
			for spec: Array in Layout.blocks(room, d):
				var soort: String = m["eenrichting"]["blokken"].get("%s/%s" % [room, spec[0]], "")
				if soort == "":
					continue
				var reg: Array = m["eenrichting"]["stukken"][soort]["region"]
				var rc: Rect2 = spec[1]
				var np := NinePatchRect.new()
				np.texture = atlas
				np.region_rect = Rect2(reg[0], reg[1], reg[2], reg[3])
				np.patch_margin_left = 16
				np.patch_margin_right = 16
				np.axis_stretch_horizontal = NinePatchRect.AXIS_STRETCH_MODE_TILE
				np.position = rc.position
				np.size = Vector2(rc.size.x, 16)
				world.add_child(np)
	for spec: Array in Layout.blocks(room, d):
		var rc: Rect2 = spec[1]
		if rc.position.y < 0:
			continue
		var l := Line2D.new()
		l.width = 1
		l.default_color = Color(1, 0.85, 0.2) if spec[2] else Color(0.2, 0.95, 1)
		l.points = PackedVector2Array([rc.position, Vector2(rc.end.x, rc.position.y), rc.end, Vector2(rc.position.x, rc.end.y), rc.position])
		world.add_child(l)
	for i in 4:
		await process_frame
	await RenderingServer.frame_post_draw
	vp.get_texture().get_image().save_png(out)
	print("ok ", out)
	quit(0)
