extends Node2D
## De simulatieklok: één vaste tick per _physics_process (60 Hz).
##
## Volgorde per tick volgens E-07b (docs/design/gdd.md, ontwerp.md §2 en §4a):
##   (1) de schaduw: de echo zet zijn frame, óf P2 stapt (en wordt opgenomen)
##   (2) P1 stapt
##   (3) P1 wordt opgenomen; de AreaLoader volgt P1 (E-04e); de echo verwerkt
##       een reset van P1 (E-04a kamerwissel, E-04b respawn, E-09 Loslaten)
##   (4) events: eerst van P1, dan van de schaduw (E-10)
##   (5) objecten werken hun stand bij (drukplaten, hendels, later zones)
## Zo hangt het resultaat niet af van de volgorde van nodes in de boom.
##
## C-01 (max. twee lichamen) bewaakt de Sim zelf: er is hooguit één
## schaduwlichaam, de echo óf P2. Doet P2 mee, dan speelt er geen echo.

const PlayerActor = preload("res://scripts/echo/player_actor.gd")
const EchoBody = preload("res://scripts/echo/echo_body.gd")
const SimObject = preload("res://scripts/objects/sim_object.gd")
const GameEvents = preload("res://scripts/events/game_events.gd")
const Combat = preload("res://scripts/combat/combat.gd")
const CombatTarget = preload("res://scripts/combat/combat_target.gd")
const Carry = preload("res://scripts/coop/carry.gd")
const TailEcho = preload("res://scripts/echo/tail_echo.gd")
const Motor = preload("res://scripts/echo/motor.gd")
const Layers = preload("res://scripts/world/layers.gd")
const Tuning = preload("res://scripts/echo/tuning.gd")
const Zone = preload("res://scripts/objects/zone.gd")
const InputBits = preload("res://scripts/input/input_bits.gd")

## Vlak vóór elke stap van een actor of object. `phase` is de stap uit E-07b:
## "1", "2", "3", "4" of "5". Bedoeld voor tests en debug-overlays; zonder
## verbinding kost het uitzenden vrijwel niets.
signal actor_stepping(tick: int, phase: String, actor: Node)
## Een event is uitgevoerd in stap (4). `target` is het bediende object, of
## null als het event niets raakte (het event bestaat dan toch, E-10).
## Systemen die nog komen (aanval E-10a, merk E-14) haken hier of in
## `_execute` in.
signal event_executed(tick: int, kind: int, actor: Node2D, target: Node)
## Na stap (5), vóór `tick` ophoogt. Alle standen van deze tick zijn dan af;
## een echo die deze tick zijn laatste frame speelde, staat er nog.
signal tick_finished(tick: int)

## V-01b: een neerslag van P1 of P2 raakte iets; het lichaam stuit (`v.y = −5`, dash terug).
signal stuit(tick: int, player: Node2D)

## P2 is opgelost bij een drop-out (breek-effect op `at`, C-05).
signal partner_left(tick: int, at: Vector2)
## P2 doet mee (C-03), op positie `at`.
signal partner_joined(tick: int, at: Vector2)
## P2 lost op (C-06) op `at`; `cause` is `fellicht`, `gevaar`, `val`,
## `leiband` (C-07) of `ontladen` (een kamer die niet geladen is, keuze (c)
## in ontwerp.md §3a), zoals de bron van `P2_OPGELOST` in het meetlog (§4.5).
signal partner_dissolved(tick: int, at: Vector2, cause: String)
## P2 is terug naast P1 (C-06 na 120 ticks, of C-08 bij een respawn van P1).
signal partner_returned(tick: int, at: Vector2)

## Aantal verwerkte ticks sinds de start.
var tick := 0
var players: Array[PlayerActor] = []
var echoes: Array[EchoBody] = []
var objects: Array[SimObject] = []
## Aanval, schaduwmerk en kettingen (E-10a, E-14, E-02m, C-12).
var combat := Combat.new()
## Optioneel: de AreaLoader van het gebied (E-04a, E-04e; ontwerp.md §3a).
## Zonder loader is alles één geladen kamer (zoals vóór T5b).
var area_loader: Node = null
## C-06: de onderrand van de kamer van P1 (wereld-y). P2 lost op als zijn
## middelpunt eronder komt. INF = geen rand (tests zonder kamer).
var room_bottom := INF

## C-06/C-07: tick waarop een opgeloste P2 terugkomt, en hoeveel ticks het
## middelpunt van P2 aaneengesloten buiten het beeld van de camera stond.
var _p2_return_tick := -1
var _p2_offscreen := 0
var _light_query: PhysicsPointQueryParameters2D
var _danger_query: PhysicsShapeQueryParameters2D


## Voegt een speler toe als C-01 dat toelaat: één P1 en hooguit één andere
## speler (P2). Een derde lichaam (een tweede P1, een tweede P2, of een
## index buiten 1–2 zoals P3) wordt geweigerd met `false`; de aanroeper ruimt de speler dan zelf op.
func add_player(player: PlayerActor) -> bool:
	if not can_add_player(player.player_index):
		return false
	players.append(player)
	players.sort_custom(func(a: PlayerActor, b: PlayerActor) -> bool:
		return a.player_index < b.player_index)
	add_child(player)
	combat.coop = is_coop()
	# C-01: doet P2 mee, dan stopt het afspelen meteen. Waar P2 verschijnt
	# (C-03), regelt de drop-in (T16c), niet de Sim.
	if player.player_index != 1:
		for echo in echoes.duplicate():
			remove_echo(echo)
	return true


func can_add_player(player_index: int) -> bool:
	# Alleen P1 en P2 bestaan (C-01); een P3 of hoger komt er nooit bij.
	if player_index < 1 or player_index > 2:
		return false
	for other in players:
		if (other.player_index == 1) == (player_index == 1):
			return false
	return true


func remove_player(player: PlayerActor) -> void:
	players.erase(player)
	combat.coop = is_coop()
	player.collision_layer = 0
	player.visible = false
	player.queue_free()


## Voegt een echo toe als C-01 dat toelaat: geen P2 in het spel en geen
## andere echo die nog speelt. Anders gebeurt er niets en is het antwoord
## `false`; de aanroeper ruimt de echo dan zelf op.
func add_echo(echo: EchoBody) -> bool:
	if not can_add_echo():
		return false
	echoes.append(echo)
	echo.combat = combat
	if "area_loader" in echo:
		echo.area_loader = area_loader
	if "tail_ticks" in echo:
		combat.tail_ticks = echo.tail_ticks
	add_child(echo)
	return true


func can_add_echo() -> bool:
	if is_coop():
		return false
	for echo in echoes:
		if echo.is_active() or echo.is_present():
			return false
	return true


## Koppelt de AreaLoader aan de Sim en aan de echo's die er al zijn. De
## loader krijgt de Sim terug, om objecten in gestreamde inhoud aan en af te
## melden (R10) en P2 te volgen (ontwerp.md §3a).
func set_area_loader(loader: Node) -> void:
	if area_loader != null and area_loader.has_signal(&"partner_in_ontladen_kamer") \
			and area_loader.partner_in_ontladen_kamer.is_connected(_on_partner_in_ontladen_kamer):
		area_loader.partner_in_ontladen_kamer.disconnect(_on_partner_in_ontladen_kamer)
	area_loader = loader
	if loader != null and "sim" in loader:
		loader.sim = self
	# C-06, keuze (c): P2 in een kamer die niet geladen is, lost op. De loader
	# meldt het in `sim_track` (na stap 3), niet op de respawntick van C-08.
	if loader != null and loader.has_signal(&"partner_in_ontladen_kamer"):
		loader.partner_in_ontladen_kamer.connect(_on_partner_in_ontladen_kamer)
	for echo in echoes:
		if "area_loader" in echo:
			echo.area_loader = loader


func remove_echo(echo: EchoBody) -> void:
	echoes.erase(echo)
	echo.stop()
	echo.queue_free()


## Meldt een object aan. Zonder ouder wordt het een kind van de Sim; een
## object dat al in de boom staat (gestreamde inhoud van een kamer, §3a)
## blijft waar het is.
func add_object(object: SimObject) -> void:
	objects.append(object)
	if object is CombatTarget:
		combat.add_target(object)
		object.hit_player.connect(_on_enemy_hit_player)
		# Vijanden van de slice lezen D en hun buren uit Combat (VJ-03, VJ-05).
		if "combat" in object:
			object.combat = combat
	if object.get_parent() == null:
		add_child(object)


## Meldt een object af (de AreaLoader bij het ontladen van een kamer, R10).
## Aanroepen tussen twee ticks of in `sim_track`, niet in stap (4) of (5).
## Een merk op een vijand die weggaat, dooft (E-14b); de node zelf ruimt de
## aanroeper op.
func remove_object(object: SimObject) -> void:
	objects.erase(object)
	if object is CombatTarget:
		combat.targets.erase(object)
		for mark in combat.marks:
			if mark.target == object:
				mark.alive = false
		if object.hit_player.is_connected(_on_enemy_hit_player):
			object.hit_player.disconnect(_on_enemy_hit_player)


func is_coop() -> bool:
	for player in players:
		if player.player_index != 1:
			return true
	return false


## Lichamen die nu in de wereld staan (C-01): P1, P2 en een echo die afspeelt.
func bodies() -> Array[Node2D]:
	var result: Array[Node2D] = []
	for player in players:
		if not player.dissolved:
			result.append(player)
	for echo in echoes:
		if echo.is_present():
			result.append(echo)
	return result


## Schaduwlichamen van nu: P2 of de echo die afspeelt (C-01: hooguit één).
func shadow_bodies() -> Array[Node2D]:
	var result: Array[Node2D] = []
	for body in bodies():
		if not (body is PlayerActor and body.player_index == 1):
			result.append(body)
	return result


func _physics_process(delta: float) -> void:
	# (0) merken die gedoofd zijn of op een dood doel zaten, gaan weg (E-14b).
	combat.begin_tick(tick)
	# (1) de schaduw. Echo's zetten hun frame; P2 stapt en wordt opgenomen.
	for echo in echoes:
		actor_stepping.emit(tick, "1", echo)
		echo.sim_step(tick, delta)
	var p1 := get_player(1)
	var p2 := get_player(2)
	# C-06: een opgeloste P2 komt 120 ticks later terug naast P1, vóór stap 1.
	if p2 and p2.dissolved and tick >= _p2_return_tick:
		_return_partner(p2, p1)
	# C-09 / E-07b: stond P2 aan het eind van t − 1 op de lichtplank van P1,
	# dan stapt P1 eerst en daarna P2; anders eerst P2.
	var p1_first := p1 != null and p2 != null and p2.motor.support == Motor.Support.SHADOW_BODY \
		and p2.motor.plank == p1.plank
	var p2_steps := p2 != null and not p2.dissolved
	if p2_steps and not p1_first:
		_step_player(p2, p1, "1", delta)
	# (2) P1 stapt, (3) P1 wordt opgenomen.
	if p1:
		_step_player(p1, p2 if p2 else _carrier_echo(), "2", delta)
	if p2_steps and p1_first:
		_step_player(p2, p1, "1", delta)
	# Na (3): de AreaLoader volgt P1 (E-04e); een kamerwissel naar een kamer
	# die geen buur is, vraagt een reset aan (E-04a). P2 wisselt nooit, maar
	# de loader meldt het als P2 in een kamer staat die niet geladen is (§3a).
	if area_loader and p1:
		area_loader.sim_track(tick, p1)
	# C-08: stierf P1 in co-op, dan respawnt P2 mee, naast P1. Anders: lost P2
	# deze tick op (C-06, C-07)? Dan voert hij in (4) geen events meer uit.
	# Een ontladen kamer (C-06, keuze (c)) gaf de loader hierboven al door
	# (`_on_partner_in_ontladen_kamer`).
	if p1 and p2:
		if p1.died:
			_return_partner(p2, p1)
		elif not p2.dissolved:
			_check_partner(p2, p1)
	# Een echo reageert in dezelfde tick op Loslaten, respawn of kamerwissel
	# van P1 (E-04a–c, E-09), zodat zijn events in (4) dan niet meer uitgaan.
	for echo in echoes:
		echo.sim_after_source(tick)
	# (4) events, eerst van P1, dan van de schaduw.
	for player in players:
		if player.player_index == 1:
			_run_events(player, player.tick_events)
	for echo in echoes:
		if echo.is_present():
			_run_events(echo, echo.tick_events)
			# E-02m: de echo laat op tick t + 3 zijn doelmerk ontploffen.
			if "detonate_mark" in echo and echo.detonate_mark != null:
				combat.detonate(tick, echo.detonate_mark)
	for player in players:
		if player.player_index != 1 and not player.dissolved:
			_run_events(player, player.tick_events)
	# Kettingschakels van deze tick (E-14d), na alle events.
	combat.after_events(tick)
	# (5) objecten, in de volgorde van toevoegen, met de lichamen van deze tick.
	var present := bodies()
	for object in objects:
		actor_stepping.emit(tick, "5", object)
		object.sim_update(tick, present)
	tick_finished.emit(tick)
	# Een echo die deze tick zijn laatste frame speelde, verdwijnt nu pas en
	# gaat uit `echoes`. De node blijft bestaan tot zijn eigenaar hem opruimt
	# (`remove_echo` of `queue_free`), zodat die het resultaat nog kan lezen.
	for echo in echoes.duplicate():
		echo.sim_end_tick()
		if echo.finished and not echo.is_present():
			echoes.erase(echo)
	tick += 1


## De speler met deze index, of null.
func get_player(index: int) -> PlayerActor:
	for p in players:
		if p.player_index == index:
			return p
	return null


## De solo-echo als drager (C-09): de staart-echo die nu afspeelt, of null.
func _carrier_echo() -> Node2D:
	for echo in echoes:
		if echo.has_method("carrier_valid") and echo.is_present():
			return echo
	return null


## Eén speler: de plank van de drager klaarzetten, stappen, vang en lancering
## (C-11, C-13), opnemen en de eigen plank op zijn nieuwe plek.
func _step_player(p: PlayerActor, carrier: Node2D, phase: String, delta: float) -> void:
	if carrier is PlayerActor:
		(carrier as PlayerActor).refresh_plank(true)
	actor_stepping.emit(tick, phase, p)
	p.sim_step(tick, delta)
	Carry.after_step(tick, p, carrier, p.pre_position(), p.pre_velocity())
	if p.player_index == 1:
		actor_stepping.emit(tick, "3", p)
	p.record(tick)
	p.refresh_plank(is_coop())


# --- drop-in en drop-out (C-03, C-05) ---------------------------------------

## C-03: P2 doet mee op deze tick (aanroepen tussen twee ticks, vóór stap 1).
## Speelde de echo af, dan neemt P2 zijn positie, snelheid en kijkrichting
## over; anders verschijnt P2 bij P1 volgens de plaatsingsregel. Geeft
## `false` als C-01 het niet toelaat (de aanroeper ruimt P2 dan op).
func drop_in(p2: PlayerActor) -> bool:
	var p1 := get_player(1)
	if p2.player_index != 2 or not can_add_player(2):
		return false
	var echo: TailEcho = null
	for e in echoes:
		if e is TailEcho and e.is_present():
			echo = e
	var p1_on_echo := false
	if echo != null:
		# In een merksprong: de huidige positie, en de merksprong stopt zonder
		# ontploffing (de echo verdwijnt vóór stap 4).
		p2.position = echo.position
		var index := echo.source.recorder.index_of_tick(tick - 1 - echo.tail_ticks)
		var v := Vector2.ZERO if echo.in_merksprong or index < 0 \
			else echo.source.recorder.post_velocity(index)
		p2.motor.velocity = v
		p2.motor.facing = echo.facing
		p1_on_echo = p1 != null and p1.motor.support == Motor.Support.SHADOW_BODY \
			and p1.motor.plank == echo.plank
	elif p1 != null:
		p2.position = placement(p1)
	if not add_player(p2):
		return false
	if p1 != null:
		p1.refresh_plank(true)
	p2.refresh_plank(true)
	if p1_on_echo:
		# Stond P1 op de echo, dan staat hij nu op P2 en valt hij niet.
		p1.motor.plank = p2.plank
		p1.motor.plank_position = p2.plank.global_position
	partner_joined.emit(tick, p2.position)
	return true


## C-05: P2 lost op (aanroepen tussen twee ticks, vóór stap 1). De lichtplank
## van P1 gaat uit en de echo van P1 neemt op deze tick over volgens E-02/E-03,
## met de `geldig_vanaf` van P1 (TD-noot PR #100): niets wordt gesimuleerd of
## verzonnen. Merken van P2 blijven staan.
func drop_out(echo_color: Color = Color(0.1, 0.1, 0.1)) -> TailEcho:
	var p2 := get_player(2)
	if p2 == null:
		return null
	var at := p2.position
	p2.plank.collision_layer = 0
	remove_player(p2)
	# C-06/C-07: geen oud oplossen of leibandteller voor een volgende P2.
	_p2_return_tick = -1
	_p2_offscreen = 0
	partner_left.emit(tick, at)
	var p1 := get_player(1)
	if p1 == null:
		return null
	p1.refresh_plank(false)
	var echo := TailEcho.new()
	echo.setup(p1, echo_color, combat.tail_ticks, -1)
	if not add_echo(echo):
		echo.free()
		return null
	return echo


## Wissel van D (E-02, E-04c) tussen twee ticks: telt als reset op deze
## tick. `geldig_vanaf` staat op P1, dus ook in co-op, zonder echo (C-04);
## een echo die afspeelt, wisselt mee.
func set_tail_ticks(p_tail_ticks: int) -> void:
	combat.tail_ticks = p_tail_ticks
	var p1 := get_player(1)
	if p1:
		p1.echo_valid_from = tick
	for echo in echoes:
		if echo is TailEcho:
			echo.set_tail_ticks(p_tail_ticks, tick)


# --- P2 lost op en komt terug (C-06, C-07, C-08) ------------------------------

## C-06 en C-07, na de stappen van P1 en P2: fel licht (middelpunt), een
## schaduwgevaar (vorm), onder de kamerrand (middelpunt) of 60 ticks
## aaneengesloten buiten het camerabeeld (leiband).
func _check_partner(p2: PlayerActor, p1: PlayerActor) -> void:
	var c: Dictionary = Tuning.coop()
	if not partner_in_view(p1.global_position, p2.global_position):
		_p2_offscreen += 1
	else:
		_p2_offscreen = 0
	var cause := ""
	var space := get_world_2d().direct_space_state
	if _light_query == null:
		_build_partner_queries()
	_light_query.position = p2.global_position
	_danger_query.transform = Transform2D(0.0, p2.global_position)
	if _zone_hit(space.intersect_point(_light_query, 8), Zone.Kind.FEL_LICHT):
		cause = "fellicht"
	elif _zone_hit(space.intersect_shape(_danger_query, 8), Zone.Kind.GEVAAR):
		cause = "gevaar"
	elif p2.global_position.y > room_bottom:
		cause = "val"
	elif _p2_offscreen >= int(c["leash_offscreen_ticks"]):
		cause = "leiband"
	if cause != "":
		dissolve_partner(cause)


## C-07: staat P2 in het camerabeeld op maximale zoom-uit? De camera houdt P1
## `leash_margin_px` van de rand, dus P2 mag hooguit `leash_view_px − marge`
## van P1 af staan (zelfde maten als `FlowRoom.camera_view`).
static func partner_in_view(p1_at: Vector2, p2_at: Vector2) -> bool:
	var c: Dictionary = Tuning.coop()
	var view: Array = c["leash_view_px"]
	var margin := float(c["leash_margin_px"])
	var delta := (p2_at - p1_at).abs()
	return delta.x <= float(view[0]) - margin and delta.y <= float(view[1]) - margin


## C-06, keuze (c) (ontwerp.md §3a): het middelpunt van P2 kwam na stap (3)
## in een kamer die niet geladen is. P2 lost op deze tick op, met de oorzaak
## `ontladen`; vóór de controles van `_check_partner`, die een opgeloste P2
## overslaat.
func _on_partner_in_ontladen_kamer(_tick: int, p2: PlayerActor, _kamer: StringName) -> void:
	if p2 == get_player(2):
		dissolve_partner("ontladen")


## C-06: P2 lost op deze tick op (breek-effect op zijn plek). Geen
## checkpoint-reset; stond P1 op P2, dan valt hij vanaf deze tick (C-09).
func dissolve_partner(cause: String) -> void:
	var p2 := get_player(2)
	if p2 == null or p2.dissolved:
		return
	var at := p2.position
	p2.dissolved = true
	p2.collision_layer = 0
	p2.plank.collision_layer = 0
	p2.visible = false
	p2.tick_events = 0
	p2.move_events = 0
	p2.motor = Motor.State.new()
	p2.velocity = Vector2.ZERO
	_p2_return_tick = tick + int(Tuning.coop()["dissolve_return_ticks"])
	_p2_offscreen = 0
	var p1 := get_player(1)
	if p1 and p1.motor.support == Motor.Support.SHADOW_BODY and p1.motor.plank == p2.plank:
		p1.motor.on_floor = false
		p1.motor.support = Motor.Support.NONE
		p1.motor.plank = null
	partner_dissolved.emit(tick, at, cause)


## C-06 en C-08: P2 staat weer naast P1 volgens de plaatsingsregel (C-03).
## Kost tot ± 800 shape-queries in het slechtste geval (geen vrije plek
## binnen 64 px); `Sim.placement` meten op de Steam Deck (#79).
func _return_partner(p2: PlayerActor, p1: PlayerActor) -> void:
	var was_dissolved := p2.dissolved
	p2.dissolved = false
	p2.collision_layer = Layers.SHADOW
	p2.visible = true
	p2.motor = Motor.State.new()
	p2.velocity = Vector2.ZERO
	p2.plank_since_ground = false
	p2.caught_this_airphase = false
	_p2_return_tick = -1
	_p2_offscreen = 0
	if p1:
		p2.position = placement(p1)
	p2.refresh_plank(true)
	if was_dissolved or (p1 and p1.died):
		partner_returned.emit(tick, p2.position)


func _build_partner_queries() -> void:
	_light_query = PhysicsPointQueryParameters2D.new()
	_light_query.collision_mask = Layers.ZONES
	_light_query.collide_with_areas = true
	_light_query.collide_with_bodies = false
	var rect := RectangleShape2D.new()
	rect.size = Tuning.body_size()
	_danger_query = PhysicsShapeQueryParameters2D.new()
	_danger_query.shape = rect
	_danger_query.collision_mask = Layers.ZONES
	_danger_query.collide_with_areas = true
	_danger_query.collide_with_bodies = false


func _zone_hit(hits: Array, kind: Zone.Kind) -> bool:
	for hit in hits:
		var z = hit["collider"]
		if z is Zone and (z as Zone).kind == kind and (z as Zone).enabled:
			return true
	return false


## Plaatsingsregel (C-03): de positie van P1, tenzij die in laag 1 of 5
## bezet is; dan de dichtstbijzijnde vrije plek binnen 64 px (stappen van
## 4 px), anders de laatste vloerpositie van P1.
func placement(p1: PlayerActor) -> Vector2:
	var c: Dictionary = Tuning.coop()
	var space := get_world_2d().direct_space_state
	var query := PhysicsShapeQueryParameters2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Tuning.body_size() - Vector2(0.02, 0.02)
	query.shape = rect
	query.collision_mask = Layers.WORLD | Layers.SHADOW_GEOMETRY
	var origin := p1.global_position
	var radius := float(c["dropin_radius_px"])
	var step := float(c["dropin_step_px"])
	var n := int(radius / step)
	var candidates: Array[Vector2] = []
	for iy in range(-n, n + 1):
		for ix in range(-n, n + 1):
			var offset := Vector2(ix * step, iy * step)
			if offset.length() <= radius + 0.001:
				candidates.append(offset)
	# Dichtstbijzijnde eerst; bij gelijke afstand vaste volgorde (boven, dan links).
	candidates.sort_custom(func(a: Vector2, b: Vector2) -> bool:
		var la := a.length_squared()
		var lb := b.length_squared()
		if la != lb:
			return la < lb
		if a.y != b.y:
			return a.y < b.y
		return a.x < b.x)
	for offset in candidates:
		query.transform = Transform2D(0.0, origin + offset)
		if space.intersect_shape(query, 1).is_empty():
			return origin + offset
	return p1.last_floor_position


func _run_events(actor: Node2D, events: int) -> void:
	actor_stepping.emit(tick, "4", actor)
	if events == 0:
		return
	for kind in GameEvents.KINDS:
		if events & kind:
			_execute(kind, actor)


func _execute(kind: int, actor: Node2D) -> void:
	var target: SimObject = null
	if kind == GameEvents.INTERACT:
		target = _interaction_target(actor)
		if target:
			target.interact(actor, tick)
	elif kind == GameEvents.ATTACK:
		# E-10a: aanvalsvlak in de (opgenomen) kijkrichting, 1 tick actief.
		# V-01a: in de lucht met DOWN is het een neerslag, met het vlak onder het lichaam.
		var facing := 1
		var attacker := "echo"
		var down := false
		if actor is PlayerActor:
			var player := actor as PlayerActor
			facing = player.motor.facing
			attacker = "p%d" % player.player_index
			down = not player.motor.on_floor and player.last_input & InputBits.DOWN != 0
		else:
			if "facing" in actor:
				facing = actor.facing
			if "neerslag" in actor:
				down = actor.neerslag
		var struck := combat.attack(tick, attacker, (actor as CollisionObject2D).collision_layer,
			actor.global_position, facing, down)
		# V-01b: één stuit per neerslag; de echo stuit niet (V-01e).
		if down and struck > 0 and actor is PlayerActor:
			(actor as PlayerActor).bounce_off(tick)
			stuit.emit(tick, actor)
	event_executed.emit(tick, kind, actor, target)


## Een aanvalsvlak van een vijand raakte P1 (§4.3, LM-05).
func _on_enemy_hit_player(hit_tick: int, player: Node2D) -> void:
	if player is PlayerActor:
		(player as PlayerActor).take_hit(hit_tick)


## E-10b: het object waarvan het interactievlak het lichaam nu overlapt en dat
## dit lichaam mag bedienen (E-06); bij meerdere het dichtstbijzijnde
## middelpunt, bij gelijke afstand het eerst toegevoegde.
## Een echo in een merksprong bedient objecten op zijn *opgenomen* positie
## (E-02m: INTERACTIE werkt op de opgenomen positie, E-10b).
func _interaction_target(actor: Node2D) -> SimObject:
	var at := actor.global_position
	if "in_merksprong" in actor and actor.in_merksprong:
		at = actor.recorded_position
	var offset := at - actor.global_position
	var best: SimObject = null
	var best_distance := INF
	for object in objects:
		if not object.is_interactable() or not object.overlaps(actor, offset):
			continue
		var distance := object.global_position.distance_squared_to(at)
		if distance < best_distance:
			best = object
			best_distance = distance
	return best
