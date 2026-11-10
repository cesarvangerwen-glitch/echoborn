extends Node
## Autoload `Progress` (ontwerp.md §3 en §7, T5b deel 3a, #82): de
## voortgang van het spel dat nu loopt. Enige bron voor een save.
##
## Twee lagen:
## - `scripts/save/game_state.gd` (`GameState`) is het schema (v1): de inhoud
##   van één save, een `RefCounted` die je maakt, vergelijkt en wegschrijft.
## - Deze node (autoload `Progress`) houdt de huidige inhoud vast in `state`,
##   weet in welk slot het spel loopt, en kent de delen van de wereld die hun
##   stand pas vlak vóór een save wegschrijven (`store_world`).
##
## Werkt alleen in de tick of tussen twee ticks; schrijft zelf geen bestanden
## (dat doet de autoload `SaveService`, die naar `checkpoint_reached` luistert).
##
## Gebruik in een gebiedsscène, ná `loader.collect` en vóór `loader.start`:
##   Progress.bind_area_loader(loader, &"polderwijk")
##   Progress.bind_meter(meter)
##   Progress.bind_gemaal(gemaal, &"gemaal_k3")
##   Progress.bind_sim(sim)
## De autoload heet níét `GameState`: een autoload gaat in GDScript als
## typenaam vóór een lokale `const GameState = preload(...)`, en dat breekt
## elk script dat het schema zo gebruikt.
## `bind_area_loader` begint een nieuw gebied: de vorige bindingen vervallen.

const GameState = preload("res://scripts/save/game_state.gd")

## P1 bereikte een checkpoint en `state` is bijgewerkt (E-04b, LM-08). De
## autoload `SaveService` maakt hierop een autosave.
signal checkpoint_reached(kamer: StringName, positie: Vector2)
## `state` werd vervangen (nieuw spel of geladen save).
signal state_replaced(slot: int)

## De inhoud van het spel dat nu loopt. Nooit null.
var state: GameState = GameState.new()
## Het slot van het spel dat nu loopt; -1 = geen spel (titelscherm, tests).
## Zonder slot schrijft `SaveService` niets.
var slot := -1

var _loader: Node = null
var _meter: RefCounted = null
## {gemaal_id: Gemaal-node}, in de volgorde van binden.
var _gemalen: Dictionary = {}


## Begint een spel in `slot` met een lege inhoud (of `p_state`).
func adopt(p_state: GameState, p_slot: int) -> void:
	state = p_state if p_state != null else GameState.new()
	slot = p_slot
	_loader = null
	_meter = null
	_gemalen.clear()
	state_replaced.emit(slot)


## Geen spel meer (terug naar het titelscherm): niets wordt nog bewaard.
func clear() -> void:
	adopt(GameState.new(), -1)


## Koppelt de AreaLoader van een gebied aan `state` en begint een nieuw
## gebied: oude bindingen vervallen. Past eerst de hernoemingen van de
## loader toe (`flag_renames`) en geeft dan de vlaggen van dit gebied die
## bij geen object in de inhoud horen (`AreaLoader.unknown_flags`); die
## worden ook als waarschuwing gelogd. Leeg = in orde.
func bind_area_loader(loader: Node, gebied: StringName) -> PackedStringArray:
	_loader = loader
	_meter = null
	_gemalen.clear()
	state.gebied = gebied
	loader.gebied = gebied
	loader.game_state = state
	loader.apply_flag_renames(state)
	var unknown: PackedStringArray = loader.unknown_flags(state)
	for flag in unknown:
		push_warning("Progress: vlag '%s' hoort bij geen object in gebied '%s' (hernoemd zonder flag_renames?)" % [flag, gebied])
	return unknown


## De lichtmeter (LM-01): krijgt meteen `state.lichtmeter` en schrijft zijn
## waarde terug in `store_world`.
func bind_meter(meter: RefCounted) -> void:
	_meter = meter
	meter.value = state.lichtmeter


## Een gemaal in de gebiedsscène (LM-03, LM-06): krijgt meteen zijn stand
## uit `state.gemalen[id]` (zonder signalen) en schrijft hem terug in
## `store_world`. Een gemaal in gestreamde inhoud kan nog niet (deel 3b).
func bind_gemaal(gemaal: Node, id: StringName) -> void:
	_gemalen[id] = gemaal
	if state.gemalen.has(id):
		var entry: Dictionary = state.gemalen[id]
		gemaal.restore_state(int(entry["vulstand"]), bool(entry["vol"]))


## Schrijft de stand van de wereld naar `state`: de objecten in de geladen
## kamers (`AreaLoader.store_objects`), de lichtmeter en de gemalen.
## `SaveService` roept dit vlak vóór elke save aan.
func store_world() -> void:
	if is_instance_valid(_loader):
		_loader.store_objects()
	if _meter != null:
		state.lichtmeter = int(_meter.value)
	for id in _gemalen:
		var gemaal: Node = _gemalen[id]
		if is_instance_valid(gemaal):
			state.set_gemaal(id, gemaal.fill, gemaal.is_full())


## Een checkpoint (E-04b, LM-08): P1 verschijnt na laden op `positie`, in de
## kamer die de gekoppelde AreaLoader daar vindt (anders &"": dan geldt bij
## laden de kamer van de positie). Meldt `checkpoint_reached`.
func reach_checkpoint(positie: Vector2) -> void:
	var kamer := &""
	if is_instance_valid(_loader):
		kamer = _loader.room_at(positie)
	state.checkpoint_kamer = kamer
	state.checkpoint_positie = positie
	checkpoint_reached.emit(kamer, positie)


## Telt gespeelde ticks (ontwerp.md §2, regel 5: geen klokuren).
func add_play_ticks(ticks: int) -> void:
	state.speeltijd_ticks += ticks


## Telt elke tick van `sim` als speeltijd (`Sim.tick_finished`).
func bind_sim(sim: Node) -> void:
	if not sim.tick_finished.is_connected(_on_tick_finished):
		sim.tick_finished.connect(_on_tick_finished)


func _on_tick_finished(_tick: int) -> void:
	add_play_ticks(1)
