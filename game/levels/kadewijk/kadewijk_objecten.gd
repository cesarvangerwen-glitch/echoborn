extends Node2D
## De objecten van S6 en S7 uit de objectenatlas (Technical Artist, #226;
## Art Director `docs/art/slice-kadewijk.md` §11.2 en §11.4, manifest
## `objecten`). Alleen beeld: de spelregels blijven in `gemaal.gd` en
## `pomprad.gd` (GP); dit script leest hun stand en luistert naar `pumped`.
##
## Staat als node `Objecten` onder `Art` (positie 0, dus in wereldcoördinaten
## zoals de lagen). Bouwt pas na de `_ready` van de inhoud (dan heeft het
## gemaal zijn schoepen).
##
## S6 (`gemaal` ingevuld):
## - per schoep een `pompschoep` (32 × 48, op de hurtbox) en een `pompslag`
##   (48 × 48, op het midden van de schoep). Bij elke pompslag (`pumped`, ook
##   met 0 LP) speelt de schoep frame 1–4 en dan 0, en de slag frame 0–4 en dan
##   weg. **P1 en de echo krijgen precies hetzelfde** (CD, #227): `who` wordt
##   niet gelezen, geen andere dekking, maat of timing.
## - `gemaal_rad` (96 × 96, middelpunt op het gemaal): frame 0 tot de eerste
##   pompslag die water pompt (`fill > 0`; een slag zonder licht pompt niets),
##   daarna draait hij rond op `fps`, en op `fps_vol` (6) zodra het gemaal vol
##   is (`is_full()`, trap 1; ook na laden).
## - `sluisklep` (cel 64 × 16, de klep van 60 × 10 op 2 px van links): op de
##   sluis, frame 0 dicht, frame 1 open (`gemaal.sluice_open`, ook na laden).
## - de laag `gemaal_aan` van `Art` (trap 1): aan als het gemaal vol is en de
##   staat niet `kleur` is (`s < 2`).
## - De placeholders (`Beeld` van de schoepen en van de sluis) gaan uit.
##
## S7 (`sokkel` aan): de `sokkel` (32 × 32), onderkant op de bovenvloer op
## `Layout.SOKKEL`. Frame 1 (aan, warme gloed) zolang de Neerslag erop ligt;
## de pick-up (WS-08, de `Pickup` `Neerslag`) roept `set_sokkel_aan(false)` via `kadewijk.gd` (#83).

const Layout = preload("res://levels/kadewijk/kadewijk_layout.gd")
const KadewijkObject = preload("res://levels/kadewijk/kadewijk_object.gd")
const Gemaal = preload("res://scripts/light/gemaal.gd")

## Het gemaal van S6 (bv. `../../Gemaal`); leeg in andere kamers.
@export var gemaal: NodePath
## De sokkel van V-01 in S7.
@export var sokkel := false

## Klep van 60 × 10 in een cel van 64 × 16: 2 px marge links, 0 boven.
const SLUIS_MARGE := Vector2(2, 0)

var _gemaal: Gemaal
## Schoep (Node2D) → [pompschoep, pompslag].
var schoepen := {}
var rad: KadewijkObject
var sluisklep: KadewijkObject
var sokkel_beeld: KadewijkObject


func _ready() -> void:
	var inhoud := get_parent().get_parent() if get_parent() else null
	if inhoud != null and not inhoud.is_node_ready():
		inhoud.ready.connect(_bouw, CONNECT_ONE_SHOT)
	else:
		_bouw()


func _bouw() -> void:
	if sokkel:
		sokkel_beeld = _maak("sokkel", "Sokkel")
		sokkel_beeld.position = Layout.SOKKEL - Vector2(16, 32)
		sokkel_beeld.toon(1)
	if gemaal.is_empty():
		return
	_gemaal = get_node_or_null(gemaal) as Gemaal
	if _gemaal == null:
		push_error("KadewijkObjecten: geen gemaal op %s" % gemaal)
		return
	for vane: Node2D in _gemaal.vanes:
		var schoep := _maak("pompschoep", "Schoep_" + String(vane.name))
		schoep.global_position = vane.global_position - Vector2(16, 24)
		schoep.toon(0)
		var slag := _maak("pompslag", "Slag_" + String(vane.name))
		slag.global_position = vane.global_position - Vector2(24, 24)
		slag.toon(-1)
		schoepen[vane] = [schoep, slag]
		_verberg(vane.get_node_or_null(^"Beeld"))
	rad = _maak("gemaal_rad", "Rad")
	rad.global_position = _gemaal.global_position - Vector2(48, 48)
	rad.toon(0)
	if _gemaal.sluice != null:
		sluisklep = _maak("sluisklep", "Sluisklep")
		var vorm := _gemaal.sluice.get_node_or_null(^"Vorm") as CollisionShape2D
		var maat: Vector2 = (vorm.shape as RectangleShape2D).size if vorm else Vector2(60, 10)
		sluisklep.global_position = _gemaal.sluice.global_position - maat * 0.5 - SLUIS_MARGE
		sluisklep.toon(0)
		_verberg(_gemaal.sluice.get_node_or_null(^"Beeld"))
	_gemaal.pumped.connect(_on_pumped)
	_volg()


func _maak(p_soort: String, p_naam: String) -> KadewijkObject:
	var obj := KadewijkObject.new(p_soort)
	obj.name = p_naam
	var art := get_parent()
	if art != null and "staat" in art:
		obj.staat = art.staat
	add_child(obj)
	return obj


func _verberg(node: Node) -> void:
	if node is CanvasItem:
		(node as CanvasItem).visible = false


## Elke pompslag, van P1, de echo of P2: hetzelfde beeld (`who` niet gelezen).
func _on_pumped(_tick: int, _amount: int, _who: String) -> void:
	var paar: Array = schoepen.get(_gemaal.last_vane, [])
	if paar.is_empty():
		return
	(paar[0] as KadewijkObject).speel([1, 2, 3, 4], 0)
	(paar[1] as KadewijkObject).speel([0, 1, 2, 3, 4], -1)


## Wat uit de stand van het gemaal volgt (ook na laden, zonder signaal).
func _volg() -> void:
	if _gemaal == null:
		return
	rad.lus(_gemaal.fill > 0 or _gemaal.is_full())
	rad.set_vol(_gemaal.is_full())
	if sluisklep != null:
		sluisklep.toon(1 if _gemaal.sluice_open else 0)
	var art := get_parent()
	if art != null and art.has_method("set_extra"):
		art.set_extra("gemaal_aan", _gemaal.is_full() and art.staat != "kleur")


func _process(_delta: float) -> void:
	_volg()


## Voor de GP (pick-up van de Neerslag, WS-08): de sokkel aan of uit.
func set_sokkel_aan(aan: bool) -> void:
	if sokkel_beeld != null:
		sokkel_beeld.toon(1 if aan else 0)
