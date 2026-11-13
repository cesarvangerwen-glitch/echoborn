extends RefCounted
## Tests voor de art-koppeling van de Kadewijk (Technical Artist, #226;
## `docs/art/slice-kadewijk.md` §9.3–§9.4, manifest
## `res://art/wereld/kadewijk/kadewijk_kamers.json`, `kadewijk_art.gd`).
##
## Via de echte gebiedsscène en de AreaLoader, bij D = 60, 90, 120 en 180:
## - de lagen van S1, S2, S3 en S4 zijn geladen: per laag uit het manifest een
##   `Sprite2D` met texture, zo groot als de kamer, linksboven op de kamer, met
##   de z-index van het manifest en filter Nearest, en geen vlak dat de hele
##   kamer bedekt (de `Achtergrond` van de wijk) ligt erboven;
## - **de art valt op de collision**: per kolom van de kamer ligt de eerste
##   dekkende pixel van `speelvlak` (grijs, half en kleur) precies op de
##   bovenkant van het hoogste vaste blok in die kolom (de blokken zoals de
##   AreaLoader ze bouwde, niet de layout); de eenrichtingsstukken (galerij,
##   treden van B1) liggen met hun loopvlak (rij 0 van het stuk, dekkend) op
##   de bovenkant van hun blok en zijn even breed, dus ze schuiven mee met D;
## - de vaste stukken per D (S2: `B3Wand`, `B3Blok`; manifest `vaste_stukken`)
##   staan linksboven op hun blok, zo groot als het blok (begrensd tot de
##   texture), z −10 na `Speelvlak`, met een dekkende bovenrij en linkerkolom;
##   zonder blok (B3-blok bij D = 60) is er geen stuk;
## - de grijze placeholders zijn uit, de collision blijft aan;
## - `set_staat()` wisselt naar half en kleur en terug.
## - De schaduwklep (V-01d, deel 3 §10.4) naast het luik in S7 en S9: weg tot
##   het luik met schaduwklep breekt, dan frame 0 op de klep; bij
##   `schaduwklep_weg` frame 1 en 2 op 12 fps, dan weg; zonder schaduwklep nooit.
##
## Leest de PNG's voor de pixelcontrole met `Image.load_from_file` (de bron,
## niet de importcache); de sprites zelf laden via de import (CI: `--import`).

const Scene := preload("res://levels/kadewijk/kadewijk.tscn")
const Bot = preload("res://levels/kadewijk/kadewijk_bot.gd")
const Layout = preload("res://levels/kadewijk/kadewijk_layout.gd")
const Progress = preload("res://scripts/save/progress.gd")
const KadewijkArt = preload("res://levels/kadewijk/kadewijk_art.gd")

const DS := [60, 90, 120, 180]
const KAMERS := {&"S1": "s1_kade_ingang", &"S2": "s2_kadegang", &"S3": "s3_vismarkt", &"S4": "s4_brugkloof"}
const Schaduwklep = preload("res://levels/kadewijk/kadewijk_schaduwklep.gd")
const LUIK_KAMERS := {&"S7": "res://levels/kadewijk/s7_sluiskelder.tscn", &"S9": "res://levels/kadewijk/s9_lage_kade.tscn"}


## Combat voor een los luik: P1 solo met de echo aan geeft een schaduwklep.
class NepCombat:
	extends RefCounted
	var coop := false
	var echo_on := true
	var tail_ticks := 60


func _wijk(t, d: int, start: StringName) -> Array:
	var progress := Progress.new()
	progress.name = "TestProgress"
	t.tree.root.add_child(progress)
	var wijk = Scene.instantiate()
	wijk.tail = d
	wijk.echo_on = false
	wijk.show_hud = false
	wijk.progress = progress
	wijk.start_at = Layout.ROOM_START[start]
	wijk.input_override = Bot.new(wijk, d, start)
	t.tree.root.add_child(wijk)
	return [wijk, progress]


func _free(t, parts: Array) -> void:
	parts[0].queue_free()
	parts[1].queue_free()
	await t.tree.process_frame


func _image(bestand: String) -> Image:
	return Image.load_from_file(ProjectSettings.globalize_path(KadewijkArt.DIR + bestand))


## Z-index waarmee `item` getekend wordt (relatief opgeteld langs de ouders).
func _z(item: CanvasItem) -> int:
	var z := 0
	var node: Node = item
	while node is CanvasItem:
		z += (node as CanvasItem).z_index
		if not (node as CanvasItem).z_as_relative:
			break
		node = node.get_parent()
	return z


## Wereldrechthoek van een blok zoals het gebouwd is (vorm × plek van het lichaam).
func _body_rect(body: StaticBody2D) -> Rect2:
	var shape := body.get_child(0) as CollisionShape2D
	var size: Vector2 = (shape.shape as RectangleShape2D).size
	return Rect2(shape.global_position - size * 0.5, size)


func _check_kamer(t, wijk, id: StringName, d: int) -> void:
	var naam: String = KAMERS[id]
	var room: Rect2 = Layout.ROOMS[id]
	var kamer_m: Dictionary = KadewijkArt.manifest()["kamers"][naam]
	var eenrichting: Dictionary = KadewijkArt.manifest()["eenrichting"]
	var tag := "%s D=%d" % [id, d]
	var inhoud: Node = wijk.loader.kamers[id].inhoud_node
	t.check(inhoud != null, "%s: inhoud niet geladen" % tag)
	if inhoud == null:
		return
	var art := inhoud.get_node_or_null(^"Art") as Node2D
	t.check(art != null and art.get_script() == KadewijkArt, "%s: geen node Art met kadewijk_art.gd" % tag)
	if art == null:
		return
	t.check(art.texture_filter == CanvasItem.TEXTURE_FILTER_NEAREST, "%s: filter %d, verwacht Nearest" % [tag, art.texture_filter])
	t.check(Rect2(kamer_m["wereld_rect"][0], kamer_m["wereld_rect"][1], kamer_m["wereld_rect"][2], kamer_m["wereld_rect"][3]) == room,
		"%s: wereld_rect in het manifest %s wijkt af van de layout %s" % [tag, kamer_m["wereld_rect"], room])

	# 1. De lagen zijn geladen en staan op de kamer.
	for laag: Dictionary in kamer_m["lagen"]:
		var sprite := art.get_node_or_null(String(KadewijkArt.LAGEN[laag["naam"]])) as Sprite2D
		t.check(sprite != null, "%s: geen Sprite2D voor laag %s" % [tag, laag["naam"]])
		if sprite == null:
			continue
		var tex := sprite.texture
		t.check(tex != null and tex.resource_path == KadewijkArt.DIR + String(laag["bestanden"]["grijs"]),
			"%s %s: texture %s, verwacht %s" % [tag, laag["naam"], tex.resource_path if tex else null, laag["bestanden"]["grijs"]])
		t.check(tex != null and Vector2(tex.get_size()) == room.size, "%s %s: texture %s, kamer %s" % [tag, laag["naam"], tex.get_size() if tex else null, room.size])
		t.check(sprite.global_position.is_equal_approx(room.position) and not sprite.centered,
			"%s %s: linksboven op %s (centered %s), verwacht %s" % [tag, laag["naam"], sprite.global_position, sprite.centered, room.position])
		t.check(sprite.z_index == int(laag["z_index"]) and sprite.is_visible_in_tree(),
			"%s %s: z %d zichtbaar %s, manifest z %d" % [tag, laag["naam"], sprite.z_index, sprite.is_visible_in_tree(), int(laag["z_index"])])

	# 1b. Niets dat de hele kamer bedekt (een achtergrondvlak), ligt boven `achter`: anders zie
	# je alleen de lagen met een hogere z-index.
	var z_achter := _z(art.get_node(^"Achter"))
	for item in wijk.find_children("*", "Polygon2D", true, false):
		var poly := item as Polygon2D
		if art.is_ancestor_of(poly) or not poly.is_visible_in_tree() or poly.polygon.is_empty():
			continue
		var box := Rect2(poly.global_transform * poly.polygon[0], Vector2.ZERO)
		for pt in poly.polygon:
			box = box.expand(poly.global_transform * pt)
		if box.encloses(room):
			t.check(_z(poly) < z_achter, "%s: %s bedekt de kamer met z %d, boven achter (%d)" % [tag, poly.get_path(), _z(poly), z_achter])

	# 2. De blokken zoals ze gebouwd zijn: vast (in `speelvlak`) of een eenrichtingsstuk.
	var vast: Array[Rect2] = []
	var stukken := {}
	var n_bodies := 0
	for body in inhoud.get_node(^"Blokken").get_children():
		if not body is StaticBody2D:
			continue
		n_bodies += 1
		var rect := _body_rect(body)
		var soort: String = eenrichting["blokken"].get("%s/%s" % [id, body.name], "")
		if soort != "":
			stukken[String(body.name)] = [rect, soort, (body.get_child(0) as CollisionShape2D).one_way_collision]
		elif rect.end.y > room.position.y:
			vast.append(rect)
		for child in body.get_children():
			if child is Polygon2D:
				t.check(not (child as Polygon2D).visible, "%s: placeholder van %s staat nog aan" % [tag, body.name])
		t.check(body.collision_layer != 0, "%s: collision van %s is uit" % [tag, body.name])
	t.check(n_bodies == Layout.blocks(id, d).size(), "%s: %d blokken, layout %d" % [tag, n_bodies, Layout.blocks(id, d).size()])

	# 2b. Vaste stukken per D liggen op hun blok.
	var vaste_m: Dictionary = KadewijkArt.manifest().get("vaste_stukken", {})
	var vaste_map := art.get_node_or_null(^"VasteStukken")
	var n_vast := 0
	for key: String in vaste_m:
		if not key.begins_with(String(id) + "/"):
			continue
		var blok := key.get_slice("/", 1)
		var body := inhoud.get_node_or_null("Blokken/" + blok) as StaticBody2D
		var sprite := vaste_map.get_node_or_null(blok) as Sprite2D if vaste_map else null
		if body == null:
			t.check(sprite == null, "%s: stuk %s zonder blok" % [tag, blok])
			continue
		n_vast += 1
		var rect := _body_rect(body)
		t.check(sprite != null, "%s: geen vast stuk op %s" % [tag, blok])
		if sprite == null:
			continue
		var bestand: String = vaste_m[key]["bestanden"]["grijs"]
		var img := _image(bestand)
		var want := Rect2(Vector2.ZERO, rect.size.min(Vector2(img.get_size())))
		t.check(sprite.texture != null and sprite.texture.resource_path == KadewijkArt.DIR + bestand, "%s %s: texture %s" % [tag, blok, sprite.texture.resource_path if sprite.texture else null])
		t.check(sprite.global_position.is_equal_approx(rect.position) and not sprite.centered, "%s %s: stuk op %s, blok op %s" % [tag, blok, sprite.global_position, rect.position])
		t.check(sprite.region_enabled and sprite.region_rect == want, "%s %s: region %s, verwacht %s" % [tag, blok, sprite.region_rect, want])
		t.check(_z(sprite) == -10 and vaste_map.get_index() > art.get_node(^"Speelvlak").get_index(), "%s %s: z %d of niet na Speelvlak" % [tag, blok, _z(sprite)])
		var boven := 0
		for x in int(want.size.x):
			boven += 1 if img.get_pixel(x, 0).a > 0.0 else 0
		var links := 0
		for y in int(want.size.y):
			links += 1 if img.get_pixel(0, y).a > 0.0 else 0
		t.check(boven == int(want.size.x) and links == int(want.size.y), "%s %s: bovenrij %d/%d en linkerkolom %d/%d dekkend" % [tag, blok, boven, want.size.x, links, want.size.y])
	t.check((vaste_map.get_child_count() if vaste_map else 0) == n_vast, "%s: %d vaste stukken voor %d blokken" % [tag, vaste_map.get_child_count() if vaste_map else -1, n_vast])
	if id == &"S2":
		t.check(n_vast == (2 if Layout.b3_width(d) > 0.0 else 1), "%s: %d vaste stukken (B3Wand, en B3Blok bij D > 60)" % [tag, n_vast])

	# 3. `speelvlak` valt per kolom precies op de bovenkant van de vaste blokken.
	for st: String in KadewijkArt.STATEN:
		var speelvlak: Dictionary = (kamer_m["lagen"] as Array).filter(func(l: Dictionary) -> bool: return l["naam"] == "speelvlak")[0]
		var img := _image(speelvlak["bestanden"][st])
		t.check(img != null and Vector2(img.get_size()) == room.size, "%s: speelvlak_%s leest niet of heeft de verkeerde maat" % [tag, st])
		if img == null:
			continue
		var fout: Array = []
		for x in img.get_width():
			var wx := room.position.x + x + 0.5
			var verwacht := -1
			for r: Rect2 in vast:
				if wx >= r.position.x and wx < r.end.x:
					var top := maxi(int(round(r.position.y - room.position.y)), 0)
					verwacht = top if verwacht < 0 else mini(verwacht, top)
			var eerste := -1
			for y in img.get_height():
				if img.get_pixel(x, y).a > 0.0:
					eerste = y
					break
			if eerste != verwacht:
				fout.append([int(wx), eerste, verwacht])
		t.check(fout.is_empty(), "%s: speelvlak_%s valt in %d kolommen niet op de collision, bv. [x, eerste pixel, blok] %s" % [tag, st, fout.size(), fout.slice(0, 6)])

	# 4. De eenrichtingsstukken liggen op hun blok (schuiven mee met D).
	var map := art.get_node_or_null(^"Eenrichting")
	var verwacht_stukken := 0
	for key: String in eenrichting["blokken"]:
		if key.begins_with(String(id) + "/"):
			verwacht_stukken += 1
	t.check(stukken.size() == verwacht_stukken, "%s: %d blokken met een stuk, manifest %d" % [tag, stukken.size(), verwacht_stukken])
	t.check(map != null and map.get_child_count() == stukken.size(), "%s: %d stukken voor %d blokken" % [tag, map.get_child_count() if map else -1, stukken.size()])
	var atlas := _image(eenrichting["atlas"]["grijs"])
	for blok: String in stukken:
		var rect: Rect2 = stukken[blok][0]
		var stuk: Dictionary = eenrichting["stukken"][stukken[blok][1]]
		t.check(stukken[blok][2], "%s: %s heeft een stuk maar is geen eenrichting" % [tag, blok])
		var np := map.get_node_or_null(blok) as NinePatchRect if map else null
		t.check(np != null, "%s: geen stuk op %s" % [tag, blok])
		if np == null:
			continue
		var at: Vector2 = np.get_global_transform() * Vector2.ZERO
		t.check(at.is_equal_approx(rect.position), "%s %s: stuk op %s, blok op %s" % [tag, blok, at, rect.position])
		t.check(is_equal_approx(np.size.x, rect.size.x) and is_equal_approx(np.size.y, float(stuk["region"][3])),
			"%s %s: stuk %s, blok %s breed" % [tag, blok, np.size, rect.size.x])
		var region := Rect2(stuk["region"][0], stuk["region"][1], stuk["region"][2], stuk["region"][3])
		t.check(np.region_rect == region and np.texture != null and np.texture.resource_path == KadewijkArt.DIR + String(eenrichting["atlas"]["grijs"]),
			"%s %s: region %s texture %s" % [tag, blok, np.region_rect, np.texture.resource_path if np.texture else null])
		t.check(np.patch_margin_left == int(stuk["marge_links"]) and np.patch_margin_right == int(stuk["marge_rechts"])
			and np.axis_stretch_horizontal == NinePatchRect.AXIS_STRETCH_MODE_TILE, "%s %s: marges of herhaling" % [tag, blok])
		var dicht := true
		for x in int(region.size.x):
			dicht = dicht and atlas.get_pixel(int(region.position.x) + x, int(region.position.y)).a > 0.0
		t.check(dicht, "%s %s: loopvlak (rij 0 van het stuk) niet dekkend" % [tag, blok])
		var z: int = np.z_index + map.z_index
		t.check(z > -10 and z < -5, "%s %s: z %d, verwacht tussen speelvlak (−10) en licht (−5)" % [tag, blok, z])


## S1–S4 (start in die kamer) bij elke D: lagen geladen, op de collision.
func test_kadewijk_art_op_collision(t) -> void:
	for d: int in DS:
		for id: StringName in KAMERS:
			var parts := _wijk(t, d, id)
			await t.tree.physics_frame
			t.check(parts[0].start_errors.is_empty(), "%s D=%d start: %s" % [id, d, parts[0].start_errors])
			_check_kamer(t, parts[0], id, d)
			await _free(t, parts)


## De galerij van B1 begint op Z = D + 30 van de keerwand: het stuk schuift mee.
func test_kadewijk_art_galerij_schuift_mee(t) -> void:
	var xs := {}
	for d: int in [60, 120]:
		var parts := _wijk(t, d, &"S1")
		await t.tree.physics_frame
		var np := parts[0].loader.kamers[&"S1"].inhoud_node.get_node_or_null(^"Art/Eenrichting/Galerij") as NinePatchRect
		t.check(np != null, "D=%d: geen galerij-stuk" % d)
		if np:
			xs[d] = np.position.x
			t.check(is_equal_approx(np.position.x, Layout.S1_WALL + Layout.keerzone(d)), "D=%d: galerij op x %s, verwacht %s" % [d, np.position.x, Layout.S1_WALL + Layout.keerzone(d)])
		await _free(t, parts)
	t.check(xs.size() == 2 and is_equal_approx(xs[120] - xs[60], 60.0), "galerij schuift %s px bij D 60 → 120, verwacht 60" % [xs.get(120, 0.0) - xs.get(60, 0.0)])


## `set_staat()` wisselt alle lagen en stukken; de Proloogdeur (in `midden`) is uit.
func test_kadewijk_art_staten(t) -> void:
	var parts := _wijk(t, 60, &"S1")
	await t.tree.physics_frame
	var inhoud: Node = parts[0].loader.kamers[&"S1"].inhoud_node
	var art = inhoud.get_node(^"Art")
	var deur := inhoud.get_node_or_null(^"Proloogdeur") as CanvasItem
	t.check(deur != null and not deur.visible, "Proloogdeur-placeholder staat nog aan")
	t.check(inhoud.get_node_or_null(^"Checkpoint") != null and inhoud.get_node(^"BevrorenEchoBakker").visible, "checkpoint of bevroren echo weg")
	var kamer_m: Dictionary = KadewijkArt.manifest()["kamers"]["s1_kade_ingang"]
	for st: String in ["kleur", "half", "grijs"]:
		art.set_staat(st)
		t.check(art.staat == st, "staat %s, verwacht %s" % [art.staat, st])
		for laag: Dictionary in kamer_m["lagen"]:
			var sprite := art.get_node(String(KadewijkArt.LAGEN[laag["naam"]])) as Sprite2D
			var want := KadewijkArt.DIR + String(laag["bestanden"][st])
			t.check(sprite.texture != null and sprite.texture.resource_path == want, "%s %s: %s" % [st, laag["naam"], sprite.texture.resource_path if sprite.texture else null])
		for np in art.get_node(^"Eenrichting").get_children():
			var want_atlas := KadewijkArt.DIR + String(KadewijkArt.manifest()["eenrichting"]["atlas"][st])
			t.check(np.texture != null and np.texture.resource_path == want_atlas, "%s %s: atlas %s" % [st, np.name, np.texture.resource_path if np.texture else null])
	await _free(t, parts)


## In S2 schuiven de kopse kant van het pakhuis en het B3-blok mee met `b3_width(D)`.
func test_kadewijk_art_b3_schuift_mee(t) -> void:
	for d: int in [60, 120, 180]:
		var parts := _wijk(t, d, &"S2")
		await t.tree.physics_frame
		var art: Node = parts[0].loader.kamers[&"S2"].inhoud_node.get_node(^"Art")
		var b := Layout.b3_width(d)
		var wand := art.get_node_or_null(^"VasteStukken/B3Wand") as Sprite2D
		var blok := art.get_node_or_null(^"VasteStukken/B3Blok") as Sprite2D
		t.check(wand != null and is_equal_approx(wand.position.x, Layout.B3_BLOCK_LEFT + b), "D=%d: wand op %s, verwacht x %s" % [d, wand.position if wand else null, Layout.B3_BLOCK_LEFT + b])
		if b > 0.0:
			t.check(blok != null and is_equal_approx(blok.region_rect.size.x, b), "D=%d: blok %s breed, verwacht %s" % [d, blok.region_rect.size.x if blok else -1.0, b])
		else:
			t.check(blok == null, "D=%d: B3-blok-stuk zonder blok" % d)
		art.set_staat("kleur")
		t.check(wand != null and wand.texture.resource_path.ends_with("s2_kadegang_b3_wand_kleur.png"), "D=%d: wand niet in kleur" % d)
		await _free(t, parts)


## De schaduwklep naast het luik van S7 en S9 (de kamerscène zelf, met een los luik).
func test_kadewijk_art_schaduwklep(t) -> void:
	var objecten: Dictionary = KadewijkArt.manifest()["objecten"]
	var frames: Array = objecten["schaduwklep"]["frames"]
	var atlas := _image(objecten["atlas"]["grijs"])
	var dekking: Array[int] = []
	for f: Array in frames:
		var n := 0
		for x in int(f[2]):
			for y in int(f[3]):
				n += 1 if atlas.get_pixel(int(f[0]) + x, int(f[1]) + y).a > 0.0 else 0
		dekking.append(n)
	t.check(frames.size() == 3 and dekking[0] > dekking[1] and dekking[1] > dekking[2] and dekking[2] > 0, "frames vol → oplossen: dekking %s" % [dekking])
	# De lichte bovenrand (daar staat de echo): de eerste volle rij van frame 0. In de art van
	# deel 3 is dat rij 2 (rij 0 leeg, rij 1 met naden); open punt AD in de PR: 2 px onder de
	# bovenkant van de klep. Hier: hij ligt in de bovenste 3 rijen.
	var eerste_vol := -1
	for y in int(frames[0][3]):
		var n := 0
		for x in int(frames[0][2]):
			n += 1 if atlas.get_pixel(int(frames[0][0]) + x, int(frames[0][1]) + y).a > 0.0 else 0
		if n == int(frames[0][2]):
			eerste_vol = y
			break
	t.check(eerste_vol >= 0 and eerste_vol <= 2, "frame 0: eerste volle rij %d, verwacht ≤ 2 (bovenrand van de klep)" % eerste_vol)
	var stap := int(round(60.0 / float(objecten["schaduwklep"]["fps"])))
	for id: StringName in LUIK_KAMERS:
		for coop: bool in [false, true]:
			var houder := Node2D.new()
			houder.position = Layout.ROOMS[id].get_center()
			t.tree.root.add_child(houder)
			var inhoud: Node = load(LUIK_KAMERS[id]).instantiate()
			houder.add_child(inhoud)
			var luik = inhoud.get_node(^"Luik")
			var klep := inhoud.get_node_or_null(^"Schaduwklep") as Sprite2D
			t.check(klep != null and klep.get_script() == Schaduwklep, "%s: geen Schaduwklep naast het luik" % id)
			if klep == null:
				houder.queue_free()
				continue
			var tag := "%s %s" % [id, "co-op" if coop else "solo"]
			t.check(not klep.visible, "%s: schaduwklep zichtbaar vóór de breuk" % tag)
			var nep := NepCombat.new()
			nep.coop = coop
			luik.combat = nep
			luik.apply_damage(100, 1, "p1")
			t.check(luik.schaduwklep == not coop, "%s: luik.schaduwklep %s" % [tag, luik.schaduwklep])
			if coop:
				for i in stap * 3:
					await t.tree.process_frame
				t.check(not klep.visible, "%s: schaduwklep zichtbaar zonder schaduwklep" % tag)
				houder.queue_free()
				continue
			var hoek: Vector2 = luik.global_position + Vector2(-luik.size.x * 0.5, -4.0)
			t.check(klep.visible and klep.frame_nu == 0 and klep.region_rect == Rect2(frames[0][0], frames[0][1], frames[0][2], frames[0][3]),
				"%s: na de breuk frame %d zichtbaar %s" % [tag, klep.frame_nu, klep.visible])
			t.check(klep.global_position.is_equal_approx(hoek) and is_equal_approx(klep.region_rect.size.x, luik.size.x),
				"%s: schaduwklep op %s, klep linksboven op %s" % [tag, klep.global_position, hoek])
			t.check(_z(klep) == int(objecten["schaduwklep"]["z_index"]) and klep.texture_filter == CanvasItem.TEXTURE_FILTER_NEAREST, "%s: z %d of filter" % [tag, _z(klep)])
			for i in stap * 2:
				await t.tree.process_frame
			t.check(klep.visible and klep.frame_nu == 0, "%s: vol blijft staan tot schaduwklep_weg (frame %d)" % [tag, klep.frame_nu])
			luik.apply_damage(130, 1, "echo")
			t.check(not luik.schaduwklep and klep.visible and klep.frame_nu == 1, "%s: na schaduwklep_weg frame %d" % [tag, klep.frame_nu])
			var gezien: Array[int] = [klep.frame_nu]
			for i in stap * 3:
				await t.tree.process_frame
				if klep.frame_nu != gezien[-1]:
					gezien.append(klep.frame_nu)
			t.check(gezien == [1, 2, -1] and not klep.visible, "%s: frames na weg %s, verwacht [1, 2, -1] en weg" % [tag, gezien])
			klep.set_staat("kleur")
			t.check(klep.texture.resource_path == KadewijkArt.DIR + String(objecten["atlas"]["kleur"]), "%s: staat kleur" % tag)
			houder.queue_free()
			await t.tree.process_frame
