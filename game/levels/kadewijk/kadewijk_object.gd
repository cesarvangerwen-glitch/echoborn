extends Sprite2D
## Eén object uit de objectenatlas van de Kadewijk (Technical Artist, #226;
## Art Director `docs/art/slice-kadewijk.md` §10.2 en §11.2, manifest
## `objecten`). Alleen beeld: een `Sprite2D` met `region` op een frame van
## `objecten.<soort>.frames`, z-index uit het manifest, filter Nearest,
## linksboven geplaatst (`centered = false`).
##
## - `toon(n)`: frame `n`, of weg bij `n < 0`.
## - `speel(reeks, na)`: de frames van `reeks` op `fps` uit het manifest, daarna
##   frame `na` (of weg bij `na < 0`).
## - `lus(aan)`: alle frames rond, op `fps` (het rad).
## - `set_staat()`: `grijs` / `half` / `kleur`, zoals `KadewijkArt.set_staat`
##   (die roept dit aan voor alle objecten in de groep `GROEP` onder zijn kamer).
##
## De beeldscripts bij de objecten van de GP (`kadewijk_luikbeeld.gd`,
## `kadewijk_schaduwklep.gd`, `kadewijk_objecten.gd`) bouwen hierop.

const KadewijkArt = preload("res://levels/kadewijk/kadewijk_art.gd")

const GROEP := &"kadewijk_object"
## De node van een `Luik` staat zoveel px onder de bovenkant van de klep
## (`luik.gd`: het middelpunt van de hurtbox van 8 px hoog; `_klep.position.y
## = size.y * 0.5 - 4`). Verandert dat in `luik.gd`, dan hier ook;
## `test_kadewijk_art.gd` meet tegen de echte `Klep` van het luik en wordt dan rood.
const KLEP_BOVEN := 4.0

## Sleutel in `objecten` van het manifest (bv. `luik`, `pompschoep`).
@export var soort := ""

var staat := "grijs"
## Frame dat nu getoond wordt, of -1 als het object weg is.
var frame_nu := -1
var _frames: Array = []
var _frametijd := 1.0 / 12.0
var _klok := 0.0
var _reeks: Array = []
var _na := -1
var _bezig := false
var _lus := false


func _init(p_soort: String = "") -> void:
	if p_soort != "":
		soort = p_soort


func _ready() -> void:
	add_to_group(GROEP)
	var obj: Dictionary = KadewijkArt.manifest().get("objecten", {}).get(soort, {})
	if obj.is_empty():
		push_error("KadewijkObject: onbekende soort '%s'" % soort)
	_frames = obj.get("frames", [])
	_frametijd = 1.0 / float(obj.get("fps", 12))
	z_index = int(obj.get("z_index", 0))
	centered = false
	region_enabled = true
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	set_staat(staat)


## Linksboven op de rechthoek van de klep van `luik` (40 × 16).
static func luik_hoek(luik) -> Vector2:
	return luik.global_position + Vector2(-luik.size.x * 0.5, -KLEP_BOVEN)


## Wisselt de texture (`grijs`, `half` of `kleur`).
func set_staat(nieuw: String) -> void:
	var bestand: String = KadewijkArt.manifest().get("objecten", {}).get("atlas", {}).get(nieuw, "")
	if bestand == "":
		push_error("KadewijkObject: onbekende staat %s" % nieuw)
		return
	staat = nieuw
	texture = load(KadewijkArt.DIR + bestand)


func aantal_frames() -> int:
	return _frames.size()


## Speelt er nu een reeks of de lus?
func speelt() -> bool:
	return _bezig or _lus


func toon(n: int) -> void:
	frame_nu = n
	visible = n >= 0
	if n < 0 or n >= _frames.size():
		return
	var f: Array = _frames[n]
	region_rect = Rect2(f[0], f[1], f[2], f[3])


func speel(reeks: Array, na: int) -> void:
	_lus = false
	_klok = 0.0
	_reeks = reeks.duplicate()
	_na = na
	_bezig = true
	toon(int(_reeks.pop_front()))


func lus(aan: bool) -> void:
	if aan == _lus:
		return
	_lus = aan
	_bezig = false
	_reeks.clear()
	_klok = 0.0
	if aan and frame_nu < 0:
		toon(0)


func _process(delta: float) -> void:
	if not speelt():
		return
	_klok += delta
	while speelt() and _klok >= _frametijd:
		_klok -= _frametijd
		if _lus:
			toon((frame_nu + 1) % maxi(_frames.size(), 1))
		elif _reeks.is_empty():
			_bezig = false
			toon(_na)
		else:
			toon(int(_reeks.pop_front()))
