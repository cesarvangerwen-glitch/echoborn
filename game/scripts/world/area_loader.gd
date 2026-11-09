extends Node
## AreaLoader v1 (T5b, #82): weet in welke kamer P1 is, welke kamers geladen
## zijn, en meldt kamerwissels (gdd E-04, E-04a, E-04e; ontwerp.md §3a).
##
## Regels:
## - De kamer van P1 is de kamer waarvan de rechthoek het middelpunt van P1
##   bevat (E-04e). Ligt het middelpunt in geen enkele kamer (een gat in de
##   indeling), dan blijft de vorige kamer gelden: geen wissel.
## - Een kamerwissel naar een buur is geen reset; naar een kamer die geen buur
##   is wel (E-04a). Dan vraagt de loader bij P1 een reset van de echo aan
##   (`PlayerActor.EchoReset.ROOM`), die de echo in dezelfde tick verwerkt,
##   net als respawn en Loslaten.
## - Geladen zijn de kamer van P1 en al zijn buren (E-04a, minimum), behalve
##   kamers die een test of het debugmenu geforceerd uit zet.
## - P2 en de echo veroorzaken nooit een kamerwissel (E-04e).
##
## Geen eigen `_physics_process`: de Sim roept `sim_track` aan na stap (3)
## van E-07b, vóór de echo de resets van P1 verwerkt. Een wijziging in wat
## geladen is, geldt dus vanaf die plek in de tick; de echo kijkt er in stap
## (1) van de volgende tick weer naar, en ook meteen na de wijziging
## (`TailEcho.sim_after_source`).

const Kamer = preload("res://scripts/world/kamer.gd")
const PlayerActor = preload("res://scripts/echo/player_actor.gd")

## P1 ging van kamer `van` naar `naar`. `reset` = geen buur (E-04a).
signal kamer_gewisseld(tick: int, van: StringName, naar: StringName, reset: bool)
## Een kamer werd geladen of niet meer geladen.
signal geladen_gewijzigd(tick: int, kamer: StringName, geladen: bool)

## Alle kamers op id, in de volgorde van toevoegen.
var kamers: Dictionary = {}
## De kamer van P1 (E-04e), of &"" vóór `start`.
var huidige: StringName = &""

var _order: Array[StringName] = []
var _forced_unloaded: Dictionary = {}
var _last_tick := -1


## Zoekt alle `Kamer`-nodes onder `root` (in boomvolgorde) en voegt ze toe.
func collect(root: Node) -> void:
	for node in _walk(root):
		if node.get_script() == Kamer:
			add_kamer(node)


func add_kamer(kamer: Kamer) -> void:
	kamers[kamer.id()] = kamer
	_order.append(kamer.id())


## Fouten in de indeling, leeg = in orde (gdd §4.6, E-04a (5)). De loader
## geeft ze terug in plaats van ze te loggen, zodat tests ze kunnen lezen;
## `start` logt ze wel. Gecontroleerd: dubbele id's, kamers zonder
## rechthoek, overlappende kamers, onbekende buren, buren die niet
## wederzijds zijn, en een kamer die zichzelf als buur heeft.
func validate() -> PackedStringArray:
	var errors := PackedStringArray()
	var seen := {}
	for id in _order:
		if seen.has(id):
			errors.append("kamer '%s' staat er twee keer in" % id)
		seen[id] = true
	for i in _order.size():
		var a: Kamer = kamers[_order[i]]
		if not a.has_rect():
			errors.append("kamer '%s' heeft geen rechthoek (CollisionShape2D met RectangleShape2D)" % a.id())
			continue
		for j in range(i + 1, _order.size()):
			var b: Kamer = kamers[_order[j]]
			if b.has_rect() and a.rect().intersects(b.rect()):
				errors.append("kamers '%s' en '%s' overlappen (E-04e)" % [a.id(), b.id()])
	for id in _order:
		var kamer: Kamer = kamers[id]
		for buur_name in kamer.buren:
			var buur := StringName(buur_name)
			if buur == id:
				errors.append("kamer '%s' heeft zichzelf als buur" % id)
			elif not kamers.has(buur):
				errors.append("kamer '%s' heeft onbekende buur '%s'" % [id, buur])
			elif not (kamers[buur] as Kamer).buren.has(String(id)):
				errors.append("'%s' is buur van '%s', maar niet andersom (E-04a: altijd wederzijds)" % [buur, id])
	return errors


## Begint in de kamer van `position` (of in `kamer_id` als die gegeven is,
## bv. uit een save). Geen kamerwissel en geen reset: de echo begint toch
## Leeg. Geeft de fouten van `validate` terug en logt ze.
func start(tick: int, position: Vector2, kamer_id: StringName = &"") -> PackedStringArray:
	var errors := validate()
	for error in errors:
		push_error("AreaLoader: %s" % error)
	huidige = kamer_id if kamer_id != &"" and kamers.has(kamer_id) else room_at(position)
	_last_tick = tick
	_apply_loaded(tick)
	return errors


## Na stap (3): volgt P1 en wisselt zo nodig van kamer. Geeft `true` als er
## deze tick een kamerwissel was.
func sim_track(tick: int, p1: PlayerActor) -> bool:
	_last_tick = tick
	var naar := room_at(p1.global_position)
	if naar == &"" or naar == huidige:
		return false
	var van := huidige
	var reset := van == &"" or not is_neighbour(van, naar)
	huidige = naar
	if reset and p1.echo_reset == PlayerActor.EchoReset.NONE:
		p1.echo_reset = PlayerActor.EchoReset.ROOM
	kamer_gewisseld.emit(tick, van, naar, reset)
	_apply_loaded(tick)
	return true


func is_neighbour(a: StringName, b: StringName) -> bool:
	return kamers.has(a) and (kamers[a] as Kamer).buren.has(String(b))


## De kamer waarvan de rechthoek `point` bevat, of &"" als geen enkele.
## De huidige kamer eerst, daarna in de volgorde van toevoegen.
func room_at(point: Vector2) -> StringName:
	if huidige != &"" and (kamers[huidige] as Kamer).contains(point):
		return huidige
	for id in _order:
		if (kamers[id] as Kamer).contains(point):
			return id
	return &""


func is_loaded(id: StringName) -> bool:
	return kamers.has(id) and (kamers[id] as Kamer).geladen


## E-04a: ligt `point` in een kamer die niet geladen is, dan is de echo daar
## Buiten. Een punt buiten alle kamers telt als geladen (de regel gaat alleen
## over punten ín een kamer); de indeling hoort alle looppaden te dekken.
func is_loaded_at(point: Vector2) -> bool:
	var id := room_at(point)
	return id == &"" or is_loaded(id)


## Geladen kamers, in de volgorde van toevoegen.
func loaded_ids() -> Array[StringName]:
	var result: Array[StringName] = []
	for id in _order:
		if is_loaded(id):
			result.append(id)
	return result


## Test en debugmenu: zet een kamer geforceerd uit (of weer vrij). Geldt
## meteen, ook midden in een tick; de echo merkt het in stap (1).
func force_unloaded(id: StringName, unloaded: bool) -> void:
	if unloaded:
		_forced_unloaded[id] = true
	else:
		_forced_unloaded.erase(id)
	_apply_loaded(_last_tick)


func _should_load(id: StringName) -> bool:
	if _forced_unloaded.has(id) or huidige == &"":
		return false
	return id == huidige or is_neighbour(huidige, id)


## Laadt en ontlaadt volgens de regel, in de volgorde van toevoegen, zodat
## de signalen en de boom altijd in dezelfde volgorde veranderen.
func _apply_loaded(tick: int) -> void:
	for id in _order:
		var kamer: Kamer = kamers[id]
		var want := _should_load(id)
		if want == kamer.geladen:
			continue
		kamer.geladen = want
		if want and kamer.inhoud != null:
			kamer.inhoud_node = kamer.inhoud.instantiate()
			kamer.add_child(kamer.inhoud_node)
		elif not want and kamer.inhoud_node != null:
			kamer.remove_child(kamer.inhoud_node)
			kamer.inhoud_node.queue_free()
			kamer.inhoud_node = null
		geladen_gewijzigd.emit(tick, id, want)


func _walk(node: Node) -> Array[Node]:
	var result: Array[Node] = [node]
	for child in node.get_children():
		result.append_array(_walk(child))
	return result
