extends "res://scripts/objects/sim_object.gd"
## Checkpoint (E-04b, LM-08; T5b deel 3a, #82; ontwerp.md §7).
##
## Komt P1 in het vlak (zijn vorm overlapt het; de flank: niet al op de
## vorige tick), dan wordt dit de plek waar P1 na laden verschijnt en volgt er een
## autosave: `Progress.reach_checkpoint` meldt `checkpoint_reached`, en de
## autoload `SaveService` schrijft het slot (met `store_world` vlak ervoor).
##
## - Alleen P1 (laag 2, E-05): de echo en P2 zetten geen checkpoint (C-08:
##   in co-op respawnen beiden op het checkpoint van P1).
## - De plek is `global_position + spawn_offset`: zet het object op de vloer.
## - Een gemaal is een checkpoint (LM-08: "het laatste gemaal dat P1
##   aanraakte of pompte"): zet er een `Checkpoint` naast en wijs met
##   `gemaal_path` (of `watch_gemaal`) naar het gemaal (deel 3b). Dan zet ook
##   een pompslag van P1 dit checkpoint, zonder dat P1 in het vlak komt;
##   alleen als het nog niet het checkpoint van nu is (`Progress.
##   is_current_checkpoint`), zodat pompen niet elke slag een save schrijft.
##   Wordt het gemaal vol terwijl dit het checkpoint van nu is, dan volgt nog
##   één autosave (de volle stand bewaard). Werkaanname: een pompslag van de
##   echo of van P2 zet geen checkpoint (LM-08 noemt P1; C-08).
## - Geen blijvende stand: na laden begint het checkpoint los; een P1 die op
##   het checkpoint verschijnt, telt op die eerste tick als binnenkomen, maar
##   dat schrijft dezelfde plek nog een keer weg.
## - Mag in de gestreamde inhoud van een kamer staan (§3a).
##
## Werkt in stap (5) van E-07b, met een directe vormtest (A2).

## P1 bereikte het checkpoint deze tick: in het vlak gekomen of gepompt.
## Hooguit één keer per tick.
signal reached(tick: int)

## Waar P1 verschijnt, ten opzichte van dit object.
@export var spawn_offset := Vector2.ZERO
## De autoload `Progress`; null = `/root/Progress`. Een test geeft een
## eigen node, zodat hij nooit een echte save raakt.
var progress: Node = null
## Het gemaal waar dit checkpoint bij hoort (LM-08), in een scène; leeg = geen.
@export var gemaal_path: NodePath

var _inside := false
var _last_reached := -1
var _gemaal: Node = null


func _init() -> void:
	owner_layers = Layers.LIGHT


func _ready() -> void:
	if not gemaal_path.is_empty():
		var gemaal := get_node_or_null(gemaal_path)
		if gemaal == null:
			push_error("Checkpoint '%s': gemaal_path '%s' wijst nergens heen" % [name, gemaal_path])
		else:
			watch_gemaal(gemaal)


func spawn_point() -> Vector2:
	return global_position + spawn_offset


## Een pompslag van P1 op dit gemaal zet dit checkpoint (LM-08, deel 3b).
func watch_gemaal(gemaal: Node) -> void:
	_gemaal = gemaal
	if not gemaal.pumped.is_connected(_on_pumped):
		gemaal.pumped.connect(_on_pumped)
	if not gemaal.full.is_connected(_on_full):
		gemaal.full.connect(_on_full)


func sim_update(tick: int, bodies: Array[Node2D]) -> void:
	var now := false
	for body in bodies_inside(bodies):
		if (body as CollisionObject2D).collision_layer & Layers.LIGHT != 0:
			now = true
	if now and not _inside:
		_reach(tick)
	_inside = now


## Stap (4), via `Gemaal.pumped` uit `Combat.hit`.
func _on_pumped(tick: int, _amount: int, who: String) -> void:
	if who != "p1":
		return
	var target := _progress()
	if target != null and target.is_current_checkpoint(spawn_point()):
		return
	_reach(tick)


func _on_full(tick: int) -> void:
	var target := _progress()
	if target != null and target.is_current_checkpoint(spawn_point()):
		_reach(tick)


func _reach(tick: int) -> void:
	if tick == _last_reached:
		return
	_last_reached = tick
	reached.emit(tick)
	var target := _progress()
	if target != null:
		target.reach_checkpoint(spawn_point())


func _progress() -> Node:
	return progress if progress != null else get_node_or_null(^"/root/Progress")
