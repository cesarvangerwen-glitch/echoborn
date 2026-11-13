extends Node2D
## De art van één kamer van de Kadewijk (Technical Artist, #226; overdracht
## van de Art Director in `docs/art/slice-kadewijk.md` §9.4, manifest
## `res://art/wereld/kadewijk/kadewijk_kamers.json`).
##
## Staat als node `Art` in de kamerscène (S1–S7: `s1_kade_ingang.tscn` …
## `s7_sluiskelder.tscn`), onder de wortel van de inhoud. Die wortel staat op
## `-midden van de kamer`, dus alles hieronder staat in wereldcoördinaten
## (zoals `kadewijk_inhoud.gd`).
##
## - De lagen staan als `Sprite2D` in de scène (`Achter`, `Midden`,
##   `Speelvlak`, `Licht`, `Voor`; z-index en bestanden uit het manifest,
##   linksboven op `Layout.ROOMS[id].position`). `speelvlak` valt per kolom
##   precies op de bovenkant van de vaste blokken (`test_kadewijk_art.gd`).
## - Wat van D afhangt (in S1 de galerij en de treden van B1), is geen deel van
##   de laag: hier komt per blok uit `Layout.blocks(kamer_id, D)` een
##   `NinePatchRect` uit de eenrichtingsatlas, met het loopvlak (rij 0) op de
##   bovenkant van het blok. Zo schuiven de stukken mee met D.
## - Vaste stukken per D (manifest `vaste_stukken`, deel 3 §10.2: in S2 de
##   kopse kant van het pakhuis `B3Wand` en het `B3Blok`): een `Sprite2D`
##   linksboven op het blok met dezelfde naam uit `Layout.blocks(kamer_id, D)`,
##   met `region` = de maat van het blok, begrensd tot de texture. Geen blok bij
##   deze D (het B3-blok bij D ≤ 60): geen stuk. Na `Speelvlak` in de boom, z −10.
## - Extra lagen (manifest `kamers.<naam>.extra`, deel 4 §11.3: in S6
##   `gemaal_aan` voor trap 1): een `Sprite2D` met die naam, linksboven op de
##   kamer, z uit het manifest, standaard uit. `set_extra(naam, aan)` zet hem;
##   in S6 doet `Objecten` (`kadewijk_objecten.gd`) dat uit de stand van het gemaal.
## - Objecten uit de objectenatlas (`kadewijk_object.gd` en de scripts daarop)
##   in deze kamer volgen `set_staat()` mee (groep `kadewijk_object`).
## - Toestand `grijs` / `half` / `kleur`: zolang de LUT-shader er niet is,
##   wisselt `set_staat()` de textures. De waterstand (`s`) bestaat nog niet;
##   de GP roept dit later aan (`grijs` bij `s < 2`, `kleur` bij `s = 2`).
## - De grijze placeholder-polygons van de blokken en de nodes in `verberg`
##   (de `Proloogdeur`, die in `midden` zit) gaan uit. Collision blijft.

const Layout = preload("res://levels/kadewijk/kadewijk_layout.gd")
const Inhoud = preload("res://levels/kadewijk/kadewijk_inhoud.gd")

const DIR := "res://art/wereld/kadewijk/"
const MANIFEST := DIR + "kadewijk_kamers.json"
const STATEN := ["grijs", "half", "kleur"]
## Laagnaam in het manifest → node in de scène.
const LAGEN := {"achter": "Achter", "midden": "Midden", "speelvlak": "Speelvlak", "licht": "Licht", "voor": "Voor"}
## Net boven `speelvlak` (−10), onder `licht` (−5).
const EENRICHTING_Z := -9
## Zelfde z als `speelvlak` (manifest `vaste_stukken`).
const VAST_Z := -10

## Kamer in `Layout` (bv. `&"S1"`).
@export var kamer_id: StringName = &""
## Sleutel van de kamer in het manifest (bv. `s1_kade_ingang`).
@export var naam: String = ""
## Placeholders die in de art zitten en uit moeten (bv. `../Proloogdeur`).
@export var verberg: Array[NodePath] = []

var staat := "grijs"

static var _manifest: Dictionary = {}


static func manifest() -> Dictionary:
	if _manifest.is_empty():
		var tekst := FileAccess.get_file_as_string(MANIFEST)
		var data = JSON.parse_string(tekst)
		if data is Dictionary:
			_manifest = data
		else:
			push_error("KadewijkArt: manifest %s leest niet" % MANIFEST)
	return _manifest


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_bouw_vaste_stukken(Inhoud.tail)
	_bouw_extra()
	_bouw_eenrichting(Inhoud.tail)
	var ouder := get_parent()
	if ouder != null and not ouder.is_node_ready():
		ouder.ready.connect(_verberg_placeholders, CONNECT_ONE_SHOT)
	else:
		_verberg_placeholders()


## Wisselt alle lagen en stukken naar `nieuw` (`grijs`, `half` of `kleur`).
func set_staat(nieuw: String) -> void:
	if not STATEN.has(nieuw):
		push_error("KadewijkArt: onbekende staat %s" % nieuw)
		return
	staat = nieuw
	var kamer: Dictionary = manifest().get("kamers", {}).get(naam, {})
	for laag: Dictionary in kamer.get("lagen", []):
		var sprite := get_node_or_null(String(LAGEN.get(laag["naam"], ""))) as Sprite2D
		var bestand: String = laag["bestanden"].get(nieuw, "")
		if sprite != null and bestand != "":
			sprite.texture = load(DIR + bestand)
	var vast: Dictionary = manifest().get("vaste_stukken", {})
	for sprite in _vaste_stukken():
		var bestand: String = vast.get("%s/%s" % [kamer_id, sprite.name], {}).get("bestanden", {}).get(nieuw, "")
		if bestand != "":
			sprite.texture = load(DIR + bestand)
	var atlas := _atlas(nieuw)
	for np in _stukken():
		np.texture = atlas
	var ouder := get_parent()
	if ouder != null and is_inside_tree():
		for obj in get_tree().get_nodes_in_group(&"kadewijk_object"):
			if ouder.is_ancestor_of(obj):
				obj.set_staat(nieuw)


## Zet een extra laag (bv. `gemaal_aan`) aan of uit.
func set_extra(laag: String, aan: bool) -> void:
	var sprite := get_node_or_null(NodePath(laag)) as Sprite2D
	if sprite != null:
		sprite.visible = aan


func _bouw_extra() -> void:
	var extra: Dictionary = manifest().get("kamers", {}).get(naam, {}).get("extra", {})
	for laag: String in extra:
		var sprite := Sprite2D.new()
		sprite.name = laag
		sprite.texture = load(DIR + String(extra[laag]["bestand"]))
		sprite.centered = false
		sprite.z_index = int(extra[laag].get("z_index", 0))
		sprite.position = Layout.ROOMS[kamer_id].position
		sprite.visible = false
		var speelvlak := get_node_or_null(^"Speelvlak")
		if speelvlak != null:
			speelvlak.add_sibling(sprite)
		else:
			add_child(sprite)


## De eenrichtingsstukken van deze kamer (leeg als de kamer er geen heeft).
func _stukken() -> Array[NinePatchRect]:
	var out: Array[NinePatchRect] = []
	var map := get_node_or_null(^"Eenrichting")
	if map != null:
		for child in map.get_children():
			if child is NinePatchRect:
				out.append(child)
	return out


## De vaste stukken van deze kamer (leeg als de kamer er geen heeft).
func _vaste_stukken() -> Array[Sprite2D]:
	var out: Array[Sprite2D] = []
	var map := get_node_or_null(^"VasteStukken")
	if map != null:
		for child in map.get_children():
			if child is Sprite2D:
				out.append(child)
	return out


func _bouw_vaste_stukken(d: int) -> void:
	var vast: Dictionary = manifest().get("vaste_stukken", {})
	var map := Node2D.new()
	map.name = "VasteStukken"
	map.z_index = VAST_Z
	var speelvlak := get_node_or_null(^"Speelvlak")
	if speelvlak != null:
		speelvlak.add_sibling(map)
	else:
		add_child(map)
	for spec: Array in Layout.blocks(kamer_id, d):
		var stuk: Dictionary = vast.get("%s/%s" % [kamer_id, spec[0]], {})
		var bestand: String = stuk.get("bestanden", {}).get(staat, "")
		if bestand == "":
			continue
		var rect: Rect2 = spec[1]
		var tex: Texture2D = load(DIR + bestand)
		var sprite := Sprite2D.new()
		sprite.name = String(spec[0])
		sprite.texture = tex
		sprite.centered = false
		sprite.region_enabled = true
		sprite.region_rect = Rect2(Vector2.ZERO, rect.size.min(Vector2(tex.get_size())))
		sprite.position = rect.position
		map.add_child(sprite)


func _atlas(st: String) -> Texture2D:
	var bestand: String = manifest().get("eenrichting", {}).get("atlas", {}).get(st, "")
	return load(DIR + bestand) if bestand != "" else null


func _bouw_eenrichting(d: int) -> void:
	var eenrichting: Dictionary = manifest().get("eenrichting", {})
	var blokken: Dictionary = eenrichting.get("blokken", {})
	var stukken: Dictionary = eenrichting.get("stukken", {})
	var map := Node2D.new()
	map.name = "Eenrichting"
	map.z_index = EENRICHTING_Z
	add_child(map)
	var atlas := _atlas(staat)
	for spec: Array in Layout.blocks(kamer_id, d):
		var soort: String = blokken.get("%s/%s" % [kamer_id, spec[0]], "")
		if soort == "":
			continue
		var stuk: Dictionary = stukken[soort]
		var rect: Rect2 = spec[1]
		var region: Array = stuk["region"]
		var np := NinePatchRect.new()
		np.name = String(spec[0])
		np.mouse_filter = Control.MOUSE_FILTER_IGNORE
		np.texture = atlas
		np.region_rect = Rect2(region[0], region[1], region[2], region[3])
		np.patch_margin_left = int(stuk["marge_links"])
		np.patch_margin_right = int(stuk["marge_rechts"])
		if stuk.get("herhaal", "") == "tile":
			np.axis_stretch_horizontal = NinePatchRect.AXIS_STRETCH_MODE_TILE
		np.position = rect.position
		np.size = Vector2(rect.size.x, region[3])
		map.add_child(np)


## Na de `_ready` van de inhoud (die bouwt de blokken pas dan).
func _verberg_placeholders() -> void:
	var blokken := get_parent().get_node_or_null(^"Blokken") if get_parent() else null
	if blokken != null:
		for body in blokken.get_children():
			for child in body.get_children():
				if child is Polygon2D:
					(child as Polygon2D).visible = false
	for pad in verberg:
		var node := get_node_or_null(pad) as CanvasItem
		if node != null:
			node.visible = false
