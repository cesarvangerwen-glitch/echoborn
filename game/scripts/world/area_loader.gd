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
## - P2 en de echo veroorzaken nooit een kamerwissel (E-04e). Staat het
##   middelpunt van P2 in een kamer die niet geladen is, dan meldt de loader
##   dat één keer (`partner_in_ontladen_kamer`); keuze (c) in ontwerp.md §3a:
##   de Sim laat P2 dan oplossen met de oorzaak `ontladen` (C-06).
## - Objecten (`SimObject`) in de `inhoud` van een kamer worden bij het laden
##   bij de Sim aangemeld en bij het ontladen afgemeld (R10). Een object met
##   een blijvende stand (een hendel) bewaart die als vlag in `game_state`
##   (`<gebied>/<kamer_id>/<pad in de inhoud>`), zodat hij na opnieuw laden
##   terugkomt. Hernoem je een kamer of object, zet dan de oude vlag in
##   `flag_renames`; `unknown_flags` vindt vlaggen die nergens meer bij horen.
## - Een `Gemaal` in de inhoud (deel 3b) krijgt bij het laden de lichtmeter en
##   zijn stand via `progress` (`Progress.bind_gemaal`, id `gemaal_id`) en
##   wordt verbonden met `Combat`; bij het ontladen gaat zijn stand naar
##   `game_state` (`Progress.unbind_gemaal`) en wordt het losgemaakt.
## - Vijanden in de inhoud (LM-13): `verslagen` is een blijvende stand. Bij
##   het laden van de inhoud, bij een kamerwissel van P1 en bij een respawn
##   van P1 (de kamer van P1) blijft een verslagen vijand weg, behalve een
##   terugkerende vijand (`CombatTarget.is_returning`) in een wijk waarvan het
##   gemaal (`Kamer.wijk_gemaal`) niet vol is: die staat weer op zijn
##   startplek met vol leven. Een weggebleven vijand is niet bij de Sim
##   aangemeld en niet zichtbaar. Een vijand die verslagen wordt terwijl zijn
##   kamer geladen is, verdwijnt meteen (`CombatTarget.apply_damage`).
##
## Geen eigen `_physics_process`: de Sim roept `sim_track` aan na stap (3)
## van E-07b, vóór de echo de resets van P1 verwerkt. Een wijziging in wat
## geladen is, geldt dus vanaf die plek in de tick; de echo kijkt er in stap
## (1) van de volgende tick weer naar, en ook meteen na de wijziging
## (`TailEcho.sim_after_source`).

const Kamer = preload("res://scripts/world/kamer.gd")
const PlayerActor = preload("res://scripts/echo/player_actor.gd")
const SimObject = preload("res://scripts/objects/sim_object.gd")
const Gemaal = preload("res://scripts/light/gemaal.gd")
const CombatTarget = preload("res://scripts/combat/combat_target.gd")

## P1 ging van kamer `van` naar `naar`. `reset` = geen buur (E-04a).
signal kamer_gewisseld(tick: int, van: StringName, naar: StringName, reset: bool)
## Een kamer werd geladen of niet meer geladen.
signal geladen_gewijzigd(tick: int, kamer: StringName, geladen: bool)
## Het middelpunt van P2 kwam deze tick in een kamer die niet geladen is
## (keuze (c), §3a). Eén keer per keer; weer in een geladen kamer of weg uit
## het spel = opnieuw gewapend. Niet op de respawntick van C-08. De Sim
## (`set_area_loader`) laat P2 hierop oplossen: `dissolve_partner("ontladen")`.
signal partner_in_ontladen_kamer(tick: int, p2: PlayerActor, kamer: StringName)

## Alle kamers op id, in de volgorde van toevoegen.
var kamers: Dictionary = {}
## De kamer van P1 (E-04e), of &"" vóór `start`.
var huidige: StringName = &""

## De Sim (gezet door `Sim.set_area_loader`). Zonder Sim worden objecten in
## gestreamde inhoud niet aangemeld en wordt P2 niet gevolgd.
var sim: Node = null
## Waar blijvende standen van objecten in gestreamde inhoud heen gaan
## (`GameState`, R10). Null = niet bewaren: na opnieuw laden begint een
## object dan in zijn standaardstand.
var game_state: RefCounted = null
## De autoload `Progress` (of een eigen node in een test), gezet door
## `Progress.bind_area_loader`. Nodig voor een gemaal in gestreamde inhoud
## (deel 3b): zonder `progress` krijgt dat geen lichtmeter en geen stand.
var progress: Node = null
## Het gebied (de gebiedsscène) van deze kamers; het eerste deel van de vlag
## van een object (`object_flag`). Kamer-id's zijn alleen binnen een gebied
## uniek. Gezet door `Progress.bind_area_loader`; leeg = geen voorvoegsel
## (tests zonder gebied).
var gebied: StringName = &""
## Hernoemde vlaggen van dit gebied, {oude vlag: nieuwe vlag}: na het
## hernoemen van een kamer of een object in de inhoud zet de World & Level
## Designer hier de oude naam, zodat een bestaande save zijn stand houdt
## (`apply_flag_renames`). Regels blijven staan zolang oude saves kunnen
## bestaan.
var flag_renames: Dictionary = {}

var _order: Array[StringName] = []
## Per kamer de aangemelde objecten uit zijn inhoud, in boomvolgorde.
var _objects: Dictionary = {}
## Verslagen vijanden die niet bij de Sim zijn aangemeld (LM-13), {node: true}.
var _away: Dictionary = {}
var _partner_outside := false
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
		var wijk := String(kamer.wijk_gemaal)
		if wijk != "" and not kamers.has(StringName(wijk.get_slice("/", 0))):
			errors.append("kamer '%s': wijk_gemaal '%s' begint niet met een kamer van dit gebied (<kamer_id>/<pad>)" % [id, wijk])
	return errors


## Begint in `start_room(position, kamer_id)`: de kamer uit de save, of de
## kamer van `position`. Geen kamerwissel en geen reset: de echo begint toch
## Leeg. Geeft de fouten van `start_errors` terug en logt ze.
func start(tick: int, position: Vector2, kamer_id: StringName = &"") -> PackedStringArray:
	var errors := start_errors(position, kamer_id)
	for error in errors:
		push_error("AreaLoader: %s" % error)
	huidige = start_room(position, kamer_id)
	_partner_outside = false
	_last_tick = tick
	_apply_loaded(tick)
	return errors


## De startkamer: `kamer_id` als die bestaat, anders de kamer van
## `position` (&"" als die in geen enkele kamer ligt).
func start_room(position: Vector2, kamer_id: StringName = &"") -> StringName:
	if kamer_id != &"" and kamers.has(kamer_id):
		return kamer_id
	for id in _order:
		if (kamers[id] as Kamer).contains(position):
			return id
	return &""


## Fouten bij het starten, zonder iets te veranderen: die van `validate`,
## plus een onbekende `kamer_id` (dan geldt de kamer van de positie), een
## `position` die niet in `kamer_id` ligt, en geen startkamer (dan is niets
## geladen). Leeg = in orde.
func start_errors(position: Vector2, kamer_id: StringName = &"") -> PackedStringArray:
	var errors := validate()
	if kamer_id != &"" and not kamers.has(kamer_id):
		errors.append("startkamer '%s' bestaat niet; de kamer van de positie geldt" % kamer_id)
	elif kamer_id != &"" and not (kamers[kamer_id] as Kamer).contains(position):
		errors.append("startpositie %s ligt niet in startkamer '%s'" % [position, kamer_id])
	if start_room(position, kamer_id) == &"":
		errors.append("startpositie %s ligt in geen enkele kamer: niets geladen" % [position])
	return errors


## Na stap (3): volgt P1 en wisselt zo nodig van kamer. Geeft `true` als er
## deze tick een kamerwissel was.
func sim_track(tick: int, p1: PlayerActor) -> bool:
	_last_tick = tick
	var switched := _track_p1(tick, p1)
	# LM-13(c), (5): binnenkomen of respawnen in de kamer van P1.
	if switched or p1.died:
		enter_room(huidige)
	# C-08: stierf P1, dan zet de Sim P2 na deze stap naast hem (ook in een
	# kamer die nu pas laadt). De plek van P2 van vóór de respawn telt dan
	# niet als "in een ontladen kamer" (keuze (c), §3a).
	if p1.died:
		_partner_outside = false
	else:
		_track_partner(tick)
	return switched


func _track_p1(tick: int, p1: PlayerActor) -> bool:
	var naar := room_at(p1.global_position)
	if naar == &"" or naar == huidige:
		return false
	var van := huidige
	var reset := van == &"" or not is_neighbour(van, naar)
	huidige = naar
	if reset:
		# C-04: ook in co-op (zonder echo) zet de wissel geldig_vanaf bij P1.
		p1.echo_valid_from = tick
		if p1.echo_reset == PlayerActor.EchoReset.NONE:
			p1.echo_reset = PlayerActor.EchoReset.ROOM
	kamer_gewisseld.emit(tick, van, naar, reset)
	_apply_loaded(tick)
	return true


## Keuze (c), §3a: P2 in een kamer die niet geladen is. Een P2 in geen enkele
## kamer (een gat, keuze (a)) of een opgeloste P2 telt niet.
func _track_partner(tick: int) -> void:
	var p2: PlayerActor = sim.get_player(2) if sim != null else null
	var kamer := &""
	if p2 != null and not p2.dissolved:
		kamer = room_at(p2.global_position)
	var outside := kamer != &"" and not is_loaded(kamer)
	if outside and not _partner_outside:
		partner_in_ontladen_kamer.emit(tick, p2, kamer)
	_partner_outside = outside


## LM-13(c): P1 komt kamer `id` binnen (kamerwissel of respawn). Elke
## verslagen vijand die terugkomt, staat weer op zijn startplek met vol
## leven; een weggebleven vijand wordt weer aangemeld, in boomvolgorde.
## Levende vijanden blijven zoals ze zijn (LM-13d). Een kamer die net laadde,
## heeft dit al bij het laden gehad; dan doet het niets meer.
func enter_room(id: StringName) -> void:
	if not _objects.has(id):
		return
	var kamer: Kamer = kamers[id]
	for object: SimObject in _objects[id]:
		if object is CombatTarget and not object.alive and _comes_back(kamer, object):
			_revive(kamer, object)


## LM-13(c): komt verslagen vijand `target` in `kamer` terug?
func _comes_back(kamer: Kamer, target: CombatTarget) -> bool:
	return target.has_persistent_state() and target.is_returning() and not is_wijk_full(kamer)


## Is het gemaal van de wijk van `kamer` vol (LM-04)? Zonder wijk: nee. De
## stand komt via `progress` (gebonden gemaal of `state`), anders uit
## `game_state`.
func is_wijk_full(kamer: Kamer) -> bool:
	if kamer.wijk_gemaal == &"":
		return false
	var id := wijk_gemaal_id(kamer)
	if progress != null:
		return progress.is_gemaal_full(id)
	if game_state != null:
		return bool(game_state.gemalen.get(id, {}).get("vol", false))
	return false


## De id in `GameState.gemalen` van het gemaal van de wijk van `kamer`:
## `<gebied>/<wijk_gemaal>`, of `wijk_gemaal` zonder gebied.
func wijk_gemaal_id(kamer: Kamer) -> StringName:
	if gebied == &"":
		return kamer.wijk_gemaal
	return StringName("%s/%s" % [gebied, kamer.wijk_gemaal])


func _revive(kamer: Kamer, target: CombatTarget) -> void:
	target.revive()
	if game_state != null:
		game_state.set_flag(_flag_of(kamer, target), false)
	if _away.has(target):
		_away.erase(target)
		if sim != null:
			sim.add_object(target)


## Staat P2 nu in een kamer die niet geladen is (stand van de laatste tick)?
func is_partner_outside() -> bool:
	return _partner_outside


## Schrijft de blijvende standen van de objecten in alle geladen kamers naar
## `game_state` (R10). Aanroepen vlak vóór een save; bij het ontladen van
## een kamer gebeurt het vanzelf.
func store_objects() -> void:
	for id in _order:
		if _objects.has(id):
			_store(id)


## De vlag in `GameState` voor een object in de inhoud van kamer `id`:
## `<gebied>/<kamer_id>/<pad>`, of `<kamer_id>/<pad>` zonder gebied.
static func object_flag(id: StringName, path_in_inhoud: NodePath, p_gebied: StringName = &"") -> StringName:
	if p_gebied == &"":
		return StringName("%s/%s" % [id, path_in_inhoud])
	return StringName("%s/%s/%s" % [p_gebied, id, path_in_inhoud])


## Alle vlaggen die objecten met een blijvende stand in de inhoud van de
## kamers kunnen zetten, {vlag: true}. Maakt elke inhoud tijdelijk aan (niet
## in de boom, geen Sim); bedoeld voor het laden van een save en voor tests,
## niet per tick.
func known_object_flags() -> Dictionary:
	var known := {}
	for id in _order:
		var kamer: Kamer = kamers[id]
		if kamer.inhoud == null:
			continue
		var root := kamer.inhoud.instantiate()
		for node in _walk(root):
			if node is Gemaal or (node is SimObject and node.has_persistent_state()):
				known[object_flag(id, root.get_path_to(node), gebied)] = true
		root.free()
	return known


## De vlaggen en gemaal-id's (`state.gemalen`, deel 3b) in `state` die bij
## dit gebied horen maar bij geen object in de inhoud (gesorteerd): hernoemd
## of verwijderd zonder `flag_renames`. Een
## vlag hoort bij dit gebied als hij begint met `<gebied>/`, of (zonder
## gebied) met `<kamer_id>/` van een kamer hier. Andere vlaggen (een sluis,
## een ander gebied) tellen niet.
func unknown_flags(state: RefCounted) -> PackedStringArray:
	var known := known_object_flags()
	var unknown := PackedStringArray()
	for flag in state.vlaggen.keys() + state.gemalen.keys():
		var text := String(flag)
		if _is_own_flag(text) and not known.has(StringName(text)):
			unknown.append(text)
	unknown.sort()
	return unknown


## Zet elke oude vlag uit `flag_renames` die in `state` staat om naar zijn
## nieuwe naam; ook de id van een gemaal in `state.gemalen` (deel 3b). Geeft
## het aantal omgezette vlaggen en id's.
func apply_flag_renames(state: RefCounted) -> int:
	var moved := 0
	for old in flag_renames:
		var new := StringName(flag_renames[old])
		if state.has_flag(StringName(old)):
			state.set_flag(StringName(old), false)
			state.set_flag(new)
			moved += 1
		if state.gemalen.has(StringName(old)):
			state.gemalen[new] = state.gemalen[StringName(old)]
			state.gemalen.erase(StringName(old))
			moved += 1
	return moved


func _is_own_flag(text: String) -> bool:
	if gebied != &"":
		return text.begins_with(String(gebied) + "/")
	var slash := text.find("/")
	return slash > 0 and kamers.has(StringName(text.substr(0, slash)))


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
			_attach_objects(kamer)
		elif not want and kamer.inhoud_node != null:
			_detach_objects(kamer)
			kamer.remove_child(kamer.inhoud_node)
			kamer.inhoud_node.queue_free()
			kamer.inhoud_node = null
		geladen_gewijzigd.emit(tick, id, want)


## R10: de objecten in de inhoud krijgen hun bewaarde stand terug en gaan
## daarna, in boomvolgorde, bij de Sim. Ze doen dus in dezelfde tick al mee
## in stap (4) en (5).
func _attach_objects(kamer: Kamer) -> void:
	var found: Array[SimObject] = []
	for node in _walk(kamer.inhoud_node):
		if node is SimObject:
			found.append(node)
	_objects[kamer.id()] = found
	if sim == null and not found.is_empty():
		push_error("AreaLoader: kamer '%s' heeft %d objecten in zijn inhoud, maar er is geen Sim (eerst Sim.set_area_loader)" % [kamer.id(), found.size()])
	for object in found:
		if object is CombatTarget:
			object.remember_start()
		if game_state != null and object.has_persistent_state():
			object.set_persistent_state(game_state.has_flag(_flag_of(kamer, object)))
		if object is Gemaal:
			_bind_gemaal(kamer, object)
		# LM-13(c): een verslagen vijand blijft weg, of komt terug.
		if object is CombatTarget and not object.alive:
			if _comes_back(kamer, object):
				_revive(kamer, object)
			else:
				_away[object] = true
				continue
		if sim != null:
			sim.add_object(object)


func _detach_objects(kamer: Kamer) -> void:
	if not _objects.has(kamer.id()):
		return
	_store(kamer.id())
	for object: SimObject in _objects[kamer.id()]:
		if object is Gemaal:
			_unbind_gemaal(kamer, object)
		if _away.has(object):
			_away.erase(object)
		elif sim != null:
			sim.remove_object(object)
	_objects.erase(kamer.id())


func _store(id: StringName) -> void:
	if game_state == null:
		return
	var kamer: Kamer = kamers[id]
	for object: SimObject in _objects[id]:
		if object.has_persistent_state():
			game_state.set_flag(_flag_of(kamer, object), object.get_persistent_state())


## De id van een gemaal in de inhoud van `kamer` in `GameState.gemalen`:
## dezelfde vorm als een vlag (`object_flag`), dus ook met `flag_renames`.
func gemaal_id(kamer: Kamer, gemaal: Node) -> StringName:
	return _flag_of(kamer, gemaal)


## Deel 3b: stand en lichtmeter via `progress`, vóór het aanmelden bij de
## Sim (zoals de stand van een hendel), dan `Combat`.
func _bind_gemaal(kamer: Kamer, gemaal: Gemaal) -> void:
	if progress != null:
		progress.bind_gemaal(gemaal, gemaal_id(kamer, gemaal))
	else:
		push_error("AreaLoader: gemaal '%s' in kamer '%s', maar geen Progress (eerst Progress.bind_area_loader)" % [kamer.inhoud_node.get_path_to(gemaal), kamer.id()])
	if sim != null:
		gemaal.connect_combat(sim.combat)


func _unbind_gemaal(kamer: Kamer, gemaal: Gemaal) -> void:
	if progress != null:
		progress.unbind_gemaal(gemaal, gemaal_id(kamer, gemaal))
	if sim != null:
		gemaal.disconnect_combat(sim.combat)


func _flag_of(kamer: Kamer, object: Node) -> StringName:
	return object_flag(kamer.id(), kamer.inhoud_node.get_path_to(object), gebied)


func _walk(node: Node) -> Array[Node]:
	var result: Array[Node] = [node]
	for child in node.get_children():
		result.append_array(_walk(child))
	return result
