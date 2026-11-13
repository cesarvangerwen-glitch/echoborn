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
## - Deel 4 (§11.4): S5–S7 zitten in de collisiontest hierboven (met de richels
##   en treden van S5 als stukken). Het luikbeeld in S7 en S9 (dicht op de klep,
##   placeholders uit, breuk 1–2 en dan open; open uit de save meteen open). In
##   S6 de objecten op hun plek: schoep en slag per schoep, met **precies
##   hetzelfde beeld voor P1 en de echo**, het rad (stil tot de eerste slag, dan
##   rond), de sluisklep (dicht, open na `t_v`) en de laag `gemaal_aan` (aan bij
##   een vol gemaal zolang de staat niet `kleur` is). In S7 de sokkel.
## - Deel 5 (§12.4): S8 en S9 zitten in de collisiontest (de stukken van S9 per
##   D op hun blok). Blokken met een vast stuk (de deuren, het hoogwater, B3)
##   tekent hun stuk, niet `speelvlak`; een blok dat open begint
##   (`Layout.START_OPEN`) heeft dan geen collision en zijn stuk is weg. De
##   deuren van S8 en het hoogwater van S9 volgen `set_door`, het hoogwater ook
##   na laden (vulstand 200). Het rad draait op `fps_vol` als het gemaal vol is.
##
## Leest de PNG's voor de pixelcontrole met `Image.load_from_file` (de bron,
## niet de importcache); de sprites zelf laden via de import (CI: `--import`).

const Scene := preload("res://levels/kadewijk/kadewijk.tscn")
const Bot = preload("res://levels/kadewijk/kadewijk_bot.gd")
const Layout = preload("res://levels/kadewijk/kadewijk_layout.gd")
const Kadewijk = preload("res://levels/kadewijk/kadewijk.gd")
const Progress = preload("res://scripts/save/progress.gd")
const KadewijkArt = preload("res://levels/kadewijk/kadewijk_art.gd")

const DS := [60, 90, 120, 180]
const KAMERS := {&"S1": "s1_kade_ingang", &"S2": "s2_kadegang", &"S3": "s3_vismarkt", &"S4": "s4_brugkloof",
	&"S5": "s5_sluiswachtershuis", &"S6": "s6_gemaalplein", &"S7": "s7_sluiskelder",
	&"S8": "s8_machinehal", &"S9": "s9_lage_kade"}
const Schaduwklep = preload("res://levels/kadewijk/kadewijk_schaduwklep.gd")
const GameState = preload("res://scripts/save/game_state.gd")
const AreaLoader = preload("res://scripts/world/area_loader.gd")
const KadewijkObject = preload("res://levels/kadewijk/kadewijk_object.gd")
const Luikbeeld = preload("res://levels/kadewijk/kadewijk_luikbeeld.gd")
const LUIK_KAMERS := {&"S7": "res://levels/kadewijk/s7_sluiskelder.tscn", &"S9": "res://levels/kadewijk/s9_lage_kade.tscn"}


## Combat voor een los luik: P1 solo met de echo aan geeft een schaduwklep.
class NepCombat:
	extends RefCounted
	var coop := false
	var echo_on := true
	var tail_ticks := 60


## Invoer die niets doet: P1 staat stil (de objecttests sturen zelf).
class StilInput:
	extends RefCounted
	func sample(_tick: int) -> int:
		return 0


func _wijk(t, d: int, start: StringName, stil := false, state: GameState = null) -> Array:
	var progress := Progress.new()
	progress.name = "TestProgress"
	t.tree.root.add_child(progress)
	if state != null:
		progress.adopt(state, -1)
	# V-01 (besluit LGD #252): wie voorbij de sokkel (S7) begint, heeft de Neerslag al.
	if start == &"S8" or start == &"S9":
		Kadewijk.give_neerslag(progress.state)
	var wijk = Scene.instantiate()
	wijk.tail = d
	wijk.echo_on = false
	wijk.show_hud = false
	wijk.progress = progress
	wijk.start_at = Layout.ROOM_START[start]
	wijk.input_override = StilInput.new() if stil else Bot.new(wijk, d, start)
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
		elif KadewijkArt.manifest().get("vaste_stukken", {}).has("%s/%s" % [id, body.name]):
			pass  # getekend door zijn vaste stuk (2b), niet door `speelvlak` (deuren, hoogwater, B3)
		elif rect.end.y > room.position.y:
			vast.append(rect)
		for child in body.get_children():
			if child is Polygon2D:
				t.check(not (child as Polygon2D).visible, "%s: placeholder van %s staat nog aan" % [tag, body.name])
		# Een blok dat open begint (`Layout.START_OPEN`, de `DeurRechts` van S8) heeft bij de start geen collision.
		if Layout.START_OPEN.has(String(body.name)):
			t.check(body.collision_layer == 0, "%s: %s begint open, maar heeft collision" % [tag, body.name])
		else:
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
		t.check(sprite.visible == (body.collision_layer != 0), "%s %s: stuk zichtbaar %s, collision %d" % [tag, blok, sprite.visible, body.collision_layer])
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


## S1–S9 (start in die kamer) bij elke D: lagen geladen, op de collision.
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
			# Linksboven op de echte klep van het luik (body + vorm uit `luik.gd`), niet op `KLEP_BOVEN`.
			var klep_body: StaticBody2D = luik.klep()
			var klep_maat: Vector2 = (klep_body.get_child(0).shape as RectangleShape2D).size
			var hoek: Vector2 = klep_body.global_position - klep_maat * 0.5
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


## Het frame van `obj` als `Rect2` uit het manifest.
func _frame(soort: String, n: int) -> Rect2:
	var f: Array = KadewijkArt.manifest()["objecten"][soort]["frames"][n]
	return Rect2(f[0], f[1], f[2], f[3])


## Volgt de frames van `objs` tot ze niet meer veranderen (max. `n` frames); per object
## de reeks van verschillende `frame_nu`, met het eerste frame erbij.
func _volg_frames(t, objs: Array, n: int) -> Array:
	var gezien: Array = []
	for obj in objs:
		gezien.append([obj.frame_nu])
	for i in n:
		await t.tree.process_frame
		for k in objs.size():
			if objs[k].frame_nu != gezien[k][-1]:
				gezien[k].append(objs[k].frame_nu)
	return gezien


## Het luik in S7 en S9 (de kamerscène zelf, met een los luik): dicht, breuk, open.
func test_kadewijk_art_luikbeeld(t) -> void:
	var stap := int(round(60.0 / float(KadewijkArt.manifest()["objecten"]["luik"]["fps"])))
	for id: StringName in LUIK_KAMERS:
		for geval: String in ["solo", "co-op", "save"]:
			var houder := Node2D.new()
			houder.position = Layout.ROOMS[id].get_center()
			t.tree.root.add_child(houder)
			var inhoud: Node = load(LUIK_KAMERS[id]).instantiate()
			houder.add_child(inhoud)
			var luik = inhoud.get_node(^"Luik")
			var beeld := inhoud.get_node_or_null(^"Luikbeeld") as Sprite2D
			var tag := "%s %s" % [id, geval]
			t.check(beeld != null and beeld.get_script() == Luikbeeld, "%s: geen Luikbeeld naast het luik" % tag)
			if beeld == null:
				houder.queue_free()
				continue
			t.check(beeld.get_index() < inhoud.get_node(^"Schaduwklep").get_index(), "%s: Luikbeeld staat niet vóór de Schaduwklep" % tag)
			var klep_body: StaticBody2D = luik.klep()
			var maat: Vector2 = (klep_body.get_child(0).shape as RectangleShape2D).size
			var hoek: Vector2 = klep_body.global_position - maat * 0.5
			t.check(beeld.visible and beeld.frame_nu == 0 and beeld.region_rect == _frame("luik", 0) and beeld.global_position.is_equal_approx(hoek),
				"%s: dicht frame %d op %s, klep linksboven op %s" % [tag, beeld.frame_nu, beeld.global_position, hoek])
			t.check(_z(beeld) == int(KadewijkArt.manifest()["objecten"]["luik"]["z_index"]) and beeld.texture_filter == CanvasItem.TEXTURE_FILTER_NEAREST, "%s: z %d of filter" % [tag, _z(beeld)])
			var aan: Array = []
			for node in [luik.get_node_or_null(^"Beeld")] + klep_body.get_children():
				if (node is Polygon2D or node is Line2D) and (node as CanvasItem).visible:
					aan.append(node.name)
			t.check(aan.is_empty() and klep_body.collision_layer != 0, "%s: placeholders van het luik aan %s, of collision uit" % [tag, aan])
			if geval == "save":
				luik.set_persistent_state(true)
				await t.tree.process_frame
				await t.tree.process_frame
				t.check(beeld.visible and beeld.frame_nu == 3 and beeld.region_rect == _frame("luik", 3), "%s: open uit de save, frame %d" % [tag, beeld.frame_nu])
				houder.queue_free()
				await t.tree.process_frame
				continue
			var nep := NepCombat.new()
			nep.coop = geval == "co-op"
			luik.combat = nep
			luik.apply_damage(100, 1, "p1")
			var gezien: Array = await _volg_frames(t, [beeld], stap * 5)
			t.check(gezien[0] == [1, 2, 3] and beeld.visible and beeld.region_rect == _frame("luik", 3), "%s: frames na de breuk %s, verwacht [1, 2, 3]" % [tag, gezien[0]])
			t.check(beeld.global_position.is_equal_approx(hoek), "%s: open op %s, verwacht %s" % [tag, beeld.global_position, hoek])
			houder.queue_free()
			await t.tree.process_frame


## S6: schoep en slag per schoep (gelijk voor P1 en de echo), rad, sluisklep, `gemaal_aan`.
func test_kadewijk_art_s6_objecten(t) -> void:
	var parts := _wijk(t, 60, &"S6", true)
	await t.tree.physics_frame
	await t.tree.process_frame
	var wijk = parts[0]
	var inhoud: Node = wijk.loader.kamers[&"S6"].inhoud_node
	var art = inhoud.get_node(^"Art")
	var objecten := art.get_node_or_null(^"Objecten")
	var gemaal = inhoud.get_node(^"Gemaal")
	t.check(objecten != null and objecten.schoepen.size() == 4, "S6: Objecten met 4 schoepen, gevonden %s" % [objecten.schoepen.size() if objecten else -1])
	if objecten == null:
		await _free(t, parts)
		return
	for vane: Node2D in gemaal.vanes:
		var paar: Array = objecten.schoepen.get(vane, [])
		t.check(paar.size() == 2, "S6 %s: geen schoep en slag" % vane.name)
		if paar.size() != 2:
			continue
		var schoep: Sprite2D = paar[0]
		var slag: Sprite2D = paar[1]
		var hb: Vector2 = (vane.shape as RectangleShape2D).size
		t.check(schoep.global_position.is_equal_approx(vane.global_position - hb * 0.5) and schoep.region_rect == _frame("pompschoep", 0) and schoep.visible,
			"S6 %s: schoep op %s (frame %d), hurtbox linksboven op %s" % [vane.name, schoep.global_position, schoep.frame_nu, vane.global_position - hb * 0.5])
		t.check(slag.global_position.is_equal_approx(vane.global_position - Vector2(24, 24)) and not slag.visible, "S6 %s: slag op %s of zichtbaar in rust" % [vane.name, slag.global_position])
		t.check(_z(schoep) == -5 and _z(slag) == 5, "S6 %s: z schoep %d, slag %d" % [vane.name, _z(schoep), _z(slag)])
		var b := vane.get_node_or_null(^"Beeld") as CanvasItem
		t.check(b == null or not b.visible, "S6 %s: placeholder van de schoep staat aan" % vane.name)
	var rad: Sprite2D = objecten.rad
	t.check(rad.global_position.is_equal_approx(gemaal.global_position - Vector2(48, 48)) and rad.frame_nu == 0 and not rad.speelt(), "S6: rad op %s frame %d draait %s" % [rad.global_position, rad.frame_nu, rad.speelt()])
	var sluis: Sprite2D = objecten.sluisklep
	var sluis_rect := Rect2(gemaal.sluice.global_position - Vector2(30, 5), Vector2(60, 10))
	t.check(sluis.global_position.is_equal_approx(sluis_rect.position - Vector2(2, 0)) and sluis.frame_nu == 0 and sluis.region_rect == _frame("sluisklep", 0),
		"S6: sluisklep op %s frame %d, verwacht %s" % [sluis.global_position, sluis.frame_nu, sluis_rect.position - Vector2(2, 0)])
	var sl_beeld := gemaal.sluice.get_node_or_null(^"Beeld") as CanvasItem
	t.check(sl_beeld == null or not sl_beeld.visible, "S6: placeholder van de sluis staat aan")
	var extra := art.get_node_or_null(^"gemaal_aan") as Sprite2D
	t.check(extra != null and not extra.visible and extra.z_index == -15 and extra.global_position.is_equal_approx(Layout.ROOMS[&"S6"].position)
		and extra.texture != null and Vector2(extra.texture.get_size()) == Layout.ROOMS[&"S6"].size, "S6: laag gemaal_aan ontbreekt, staat aan of verkeerd")

	# Een pompslag van P1 en daarna een van de echo: precies hetzelfde beeld.
	var reeksen := {}
	var combat = wijk.sim.combat
	gemaal.meter.value = 100
	for i in 2:
		var who: String = ["p1", "echo"][i]
		var vane: Node2D = gemaal.vanes[i]
		var paar: Array = objecten.schoepen[vane]
		combat.hit.emit(10 + i, who, vane, 0)
		var eigen := [paar[0].modulate, paar[0].self_modulate, paar[0].scale, paar[1].modulate, paar[1].self_modulate, paar[1].scale, paar[1].region_rect, paar[1].z_index]
		var gezien: Array = await _volg_frames(t, paar, 40)
		reeksen[who] = [gezien, eigen]
		t.check(gezien[0] == [1, 2, 3, 4, 0] and gezien[1] == [0, 1, 2, 3, 4, -1], "S6 %s: schoep %s, slag %s" % [who, gezien[0], gezien[1]])
		t.check(eigen[3].a == 1.0 and eigen[4].a == 1.0 and eigen[5] == Vector2.ONE, "S6 %s: slag niet 100 %% dekkend of geschaald" % who)
	t.check(reeksen["p1"] == reeksen["echo"], "S6: pompslag van de echo wijkt af van P1: %s tegen %s" % [reeksen["echo"], reeksen["p1"]])
	t.check(gemaal.fill > 0 and gemaal.strokes.size() == 2, "S6: pompslagen niet geteld (fill %d)" % gemaal.fill)
	t.check(rad.speelt(), "S6: rad draait niet na de eerste pompslag")
	t.check(not rad.vol and is_equal_approx(rad.fps_nu(), float(KadewijkArt.manifest()["objecten"]["gemaal_rad"]["fps"])), "S6: rad vult op %s fps, verwacht fps" % rad.fps_nu())
	var rad_frames: Array = await _volg_frames(t, [rad], 60)
	t.check(rad_frames[0].size() >= 8, "S6: rad draait %s in 1 s, verwacht alle 8 frames" % [rad_frames[0]])

	# Vol gemaal (zoals na laden, zonder signaal): sluis open, `gemaal_aan` aan tot `kleur`.
	gemaal.restore_state(100, true)
	await t.tree.process_frame
	t.check(sluis.frame_nu == 1 and sluis.region_rect == _frame("sluisklep", 1), "S6: sluisklep na t_v frame %d" % sluis.frame_nu)
	var rad_m: Dictionary = KadewijkArt.manifest()["objecten"]["gemaal_rad"]
	t.check(rad.speelt() and rad.vol and is_equal_approx(rad.fps_nu(), float(rad_m["fps_vol"])), "S6: rad bij een vol gemaal op %s fps, verwacht fps_vol %s" % [rad.fps_nu(), rad_m["fps_vol"]])
	var vol_frames: Array = await _volg_frames(t, [rad], 60)
	var stappen: int = vol_frames[0].size() - 1
	t.check(stappen >= int(rad_m["fps_vol"]) - 1 and stappen <= int(rad_m["fps_vol"]), "S6: rad vol %d frames in 1 s, verwacht %s" % [stappen, rad_m["fps_vol"]])
	t.check(extra != null and extra.visible, "S6: gemaal_aan uit bij een vol gemaal in grijs")
	art.set_staat("half")
	await t.tree.process_frame
	t.check(extra != null and extra.visible, "S6: gemaal_aan uit in half (s < 2)")
	art.set_staat("kleur")
	await t.tree.process_frame
	t.check(extra != null and not extra.visible, "S6: gemaal_aan aan in kleur (s = 2)")
	var want := KadewijkArt.DIR + String(KadewijkArt.manifest()["objecten"]["atlas"]["kleur"])
	for obj in [rad, sluis, objecten.schoepen[gemaal.vanes[0]][0]]:
		t.check(obj.texture != null and obj.texture.resource_path == want, "S6 %s: niet in kleur" % obj.name)
	await _free(t, parts)


## S7: de sokkel van V-01 op de bovenvloer, aan; de placeholder is uit.
func test_kadewijk_art_sokkel(t) -> void:
	var parts := _wijk(t, 60, &"S7", true)
	await t.tree.physics_frame
	await t.tree.process_frame
	var inhoud: Node = parts[0].loader.kamers[&"S7"].inhoud_node
	var objecten = inhoud.get_node_or_null(^"Art/Objecten")
	var sokkel: Sprite2D = objecten.sokkel_beeld if objecten else null
	t.check(sokkel != null, "S7: geen sokkel")
	if sokkel != null:
		var maat := _frame("sokkel", 1).size
		t.check(sokkel.global_position.is_equal_approx(Layout.SOKKEL - Vector2(maat.x * 0.5, maat.y)) and sokkel.frame_nu == 1 and sokkel.region_rect == _frame("sokkel", 1),
			"S7: sokkel op %s frame %d, verwacht onderkant op %s, aan" % [sokkel.global_position, sokkel.frame_nu, Layout.SOKKEL])
		t.check(_z(sokkel) == int(KadewijkArt.manifest()["objecten"]["sokkel"]["z_index"]), "S7: sokkel z %d" % _z(sokkel))
		objecten.set_sokkel_aan(false)
		t.check(sokkel.frame_nu == 0 and sokkel.region_rect == _frame("sokkel", 0), "S7: sokkel uit, frame %d" % sokkel.frame_nu)
	t.check(not (inhoud.get_node(^"Sokkel") as CanvasItem).visible, "S7: placeholder Sokkel staat aan")
	await _free(t, parts)


## S8: de deuren als vaste stukken volgen `set_door` (DeurRechts begint open).
func test_kadewijk_art_deuren_s8(t) -> void:
	var parts := _wijk(t, 60, &"S8", true)
	await t.tree.physics_frame
	await t.tree.process_frame
	var wijk = parts[0]
	var map: Node = wijk.loader.kamers[&"S8"].inhoud_node.get_node_or_null(^"Art/VasteStukken")
	var links := map.get_node_or_null(^"DeurLinks") as Sprite2D if map else null
	var rechts := map.get_node_or_null(^"DeurRechts") as Sprite2D if map else null
	t.check(links != null and rechts != null, "S8: deuren ontbreken als vaste stukken")
	if links == null or rechts == null:
		await _free(t, parts)
		return
	t.check(links.visible and not rechts.visible, "S8 start: DeurLinks %s (dicht), DeurRechts %s (open)" % [links.visible, rechts.visible])
	t.check(wijk.set_door(&"S8", "DeurRechts", true), "S8: set_door DeurRechts")
	await t.tree.process_frame
	t.check(rechts.visible, "S8: DeurRechts dicht (BOSS_START), stuk niet zichtbaar")
	wijk.set_door(&"S8", "DeurLinks", false)
	await t.tree.process_frame
	t.check(not links.visible, "S8: DeurLinks open (BOSS_VERSLAGEN), stuk nog zichtbaar")
	await _free(t, parts)


## S9: het hoogwater is dicht tot `s = 2` (set_door), en uit een save met vulstand 200 meteen weg.
func test_kadewijk_art_hoogwater_s9(t) -> void:
	for geval: String in ["dicht", "s2", "save200", "save100"]:
		var state: GameState = null
		if geval.begins_with("save"):
			state = GameState.new()
			state.set_gemaal(AreaLoader.object_flag(&"S6", ^"Gemaal", Kadewijk.GEBIED), 200 if geval == "save200" else 100, true)
		var parts := _wijk(t, 60, &"S9", true, state)
		await t.tree.physics_frame
		await t.tree.process_frame
		var wijk = parts[0]
		var stuk := wijk.loader.kamers[&"S9"].inhoud_node.get_node_or_null(^"Art/VasteStukken/Hoogwater") as Sprite2D
		t.check(stuk != null, "S9 %s: geen vast stuk Hoogwater" % geval)
		if stuk != null:
			if geval == "s2":
				wijk.hoogwater_open_tick = wijk.sim.tick
				wijk._update_hoogwater(wijk.sim.tick)
				await t.tree.process_frame
			var open: bool = geval == "s2" or geval == "save200"
			t.check(stuk.visible == not open and wijk.hoogwater_open == open, "S9 %s: hoogwater-stuk zichtbaar %s, open %s" % [geval, stuk.visible, wijk.hoogwater_open])
		await _free(t, parts)
