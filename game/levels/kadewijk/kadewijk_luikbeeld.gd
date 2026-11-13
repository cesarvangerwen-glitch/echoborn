extends "res://levels/kadewijk/kadewijk_object.gd"
## Het beeld van een breekbaar `Luik` (V-01, SL-04) in S7 en S9 (Technical
## Artist, #226; Art Director `docs/art/slice-kadewijk.md` §11.2, manifest
## `objecten.luik`). Alleen beeld: de logica blijft in
## `scripts/objects/luik.gd` (GP); dit script luistert naar `opened`.
##
## Staat als zus van het luik in de kamerscène (`luik = ../Luik`), vóór de
## `Schaduwklep` (die tekent erover), niet als kind: het luik zet zichzelf
## onzichtbaar zodra het breekt.
## - Dicht: frame 0 (met de scheur, L-03), linksboven op de klep (40 × 16).
##   De placeholders van het luik (`Beeld`, en de polygon en scheur van `Klep`)
##   gaan uit; de collision blijft.
## - `opened`: frame 1 en 2 (breuk) op `fps` uit het manifest, daarna frame 3
##   (open). Met en zonder schaduwklep gelijk: voor P1 is het luik open.
## - Open uit de save (`set_persistent_state`, zonder signaal): frame 3.

const Luik = preload("res://scripts/objects/luik.gd")

const DICHT := 0
const OPEN := 3

## Het luik waar dit beeld bij hoort.
@export var luik: NodePath = ^"../Luik"

var _luik: Luik


func _init() -> void:
	soort = "luik"


func _ready() -> void:
	super._ready()
	_luik = get_node_or_null(luik) as Luik
	if _luik == null:
		push_error("Luikbeeld: geen luik op %s" % luik)
		toon(-1)
		return
	_luik.opened.connect(_on_opened)
	for node: Node in [_luik.get_node_or_null(^"Beeld"), _luik.klep()]:
		if node == null:
			continue
		for child in [node] + node.get_children():
			if (child is Polygon2D or child is Line2D) and child != _luik.klep():
				(child as CanvasItem).visible = false
	toon(OPEN if _luik.is_open else DICHT)


func _on_opened(_tick: int, _by: String) -> void:
	speel([1, 2], OPEN)


## Open uit de save komt zonder signaal (AreaLoader, na `_ready`).
func _process(delta: float) -> void:
	if not speelt() and frame_nu == DICHT and _luik != null and _luik.is_open:
		toon(OPEN)
	super._process(delta)


func toon(n: int) -> void:
	super.toon(n)
	if n >= 0 and _luik != null:
		global_position = luik_hoek(_luik)
