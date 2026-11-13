extends "res://levels/kadewijk/kadewijk_object.gd"
## Het beeld van de schaduwklep (V-01d) van een `Luik` (Technical Artist,
## #226; Art Director `docs/art/slice-kadewijk.md` §10.1, §10.4 en §11.2,
## manifest `objecten.schaduwklep`). Alleen beeld: de logica blijft in
## `scripts/objects/luik.gd` (GP); dit script luistert naar zijn signalen.
##
## Staat als zus van het luik in de kamerscène (`luik = ../Luik`), na
## `Luikbeeld`, niet als kind: het luik zet zichzelf onzichtbaar zodra het breekt.
## - `opened` met `luik.schaduwklep`: frame 0 (de hele afdruk, hol, nog niet
##   aan het oplossen), linksboven op de rechthoek van de klep (40 × 16).
## - `schaduwklep_weg`: frame 1 en 2 (oplossen, Bayer 50 % en 25 %) op
##   `fps` uit het manifest, daarna weg.
## - Breekt het luik zonder schaduwklep (co-op, echo uit, P2, de echo), of is
##   het bij het laden al open: nooit zichtbaar.

const Luik = preload("res://scripts/objects/luik.gd")

## Het luik waar deze schaduwklep bij hoort.
@export var luik: NodePath = ^"../Luik"

var _luik: Luik


func _init() -> void:
	soort = "schaduwklep"


func _ready() -> void:
	super._ready()
	_luik = get_node_or_null(luik) as Luik
	if _luik == null:
		push_error("Schaduwklep: geen luik op %s" % luik)
	else:
		_luik.opened.connect(_on_opened)
		_luik.schaduwklep_weg.connect(_on_weg)
	toon(0 if _luik != null and _luik.schaduwklep else -1)


func _on_opened(_tick: int, _by: String) -> void:
	if _luik.schaduwklep:
		toon(0)


func _on_weg(_tick: int, _by: String) -> void:
	speel([1, 2], -1)


func toon(n: int) -> void:
	super.toon(n)
	if n >= 0 and _luik != null:
		global_position = luik_hoek(_luik)
