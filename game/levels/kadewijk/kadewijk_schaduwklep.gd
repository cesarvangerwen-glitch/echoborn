extends Sprite2D
## Het beeld van de schaduwklep (V-01d) van een `Luik` (Technical Artist,
## #226; Art Director `docs/art/slice-kadewijk.md` §10.1 en §10.4, manifest
## `objecten.schaduwklep`). Alleen beeld: de logica blijft in
## `scripts/objects/luik.gd` (GP); dit script luistert naar zijn signalen.
##
## Staat als zus van het luik in de kamerscène (`luik = ../Luik`), niet als
## kind: het luik zet zichzelf onzichtbaar zodra het breekt.
## - `opened` met `luik.schaduwklep`: frame 0 (de hele afdruk, nog niet aan het
##   oplossen), linksboven op de
##   rechthoek van de klep (40 × 16).
## - `schaduwklep_weg`: frame 1 en 2 (oplossen, Bayer 50 % en 25 %) op
##   `fps` uit het manifest, daarna weg.
## - Breekt het luik zonder schaduwklep (co-op, echo uit, P2, de echo), of is
##   het bij het laden al open: nooit zichtbaar.

const KadewijkArt = preload("res://levels/kadewijk/kadewijk_art.gd")
const Luik = preload("res://scripts/objects/luik.gd")

## Het luik waar deze schaduwklep bij hoort.
@export var luik: NodePath = ^"../Luik"

## De node van het luik staat zoveel px onder de bovenkant van de klep
## (`luik.gd`: het middelpunt van de hurtbox van 8 px hoog; `_klep.position.y
## = size.y * 0.5 - 4`). Verandert dat in `luik.gd`, dan hier ook;
## `test_kadewijk_art.gd` meet tegen de echte `Klep` van het luik en wordt dan rood.
const KLEP_BOVEN := 4.0

var staat := "grijs"
## Frame dat nu getoond wordt (0 hele afdruk, 1–2 oplossen), of -1 als hij weg is.
var frame_nu := -1
var _frames: Array = []
var _frametijd := 1.0 / 12.0
var _klok := 0.0
var _luik: Luik


func _ready() -> void:
	var m: Dictionary = KadewijkArt.manifest().get("objecten", {})
	var klep: Dictionary = m.get("schaduwklep", {})
	_frames = klep.get("frames", [])
	_frametijd = 1.0 / float(klep.get("fps", 12))
	z_index = int(klep.get("z_index", -9))
	centered = false
	region_enabled = true
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	set_staat(staat)
	_luik = get_node_or_null(luik) as Luik
	if _luik == null:
		push_error("Schaduwklep: geen luik op %s" % luik)
	else:
		_luik.opened.connect(_on_opened)
		_luik.schaduwklep_weg.connect(_on_weg)
	_toon(0 if _luik != null and _luik.schaduwklep else -1)


## Wisselt de texture (`grijs`, `half` of `kleur`), zoals `KadewijkArt.set_staat`.
func set_staat(nieuw: String) -> void:
	var bestand: String = KadewijkArt.manifest().get("objecten", {}).get("atlas", {}).get(nieuw, "")
	if bestand == "":
		push_error("Schaduwklep: onbekende staat %s" % nieuw)
		return
	staat = nieuw
	texture = load(KadewijkArt.DIR + bestand)


func _on_opened(_tick: int, _by: String) -> void:
	if _luik.schaduwklep:
		_toon(0)


func _on_weg(_tick: int, _by: String) -> void:
	_klok = 0.0
	_toon(1)


func _process(delta: float) -> void:
	if frame_nu < 1:
		return
	_klok += delta
	while frame_nu >= 1 and _klok >= _frametijd:
		_klok -= _frametijd
		_toon(frame_nu + 1 if frame_nu + 1 < _frames.size() else -1)


func _toon(n: int) -> void:
	frame_nu = n
	visible = n >= 0
	if n < 0 or n >= _frames.size():
		return
	var f: Array = _frames[n]
	region_rect = Rect2(f[0], f[1], f[2], f[3])
	# Linksboven op de rechthoek van de klep (het luik staat `KLEP_BOVEN` onder de bovenkant).
	if _luik != null:
		var size: Vector2 = _luik.size
		global_position = _luik.global_position + Vector2(-size.x * 0.5, -KLEP_BOVEN)
