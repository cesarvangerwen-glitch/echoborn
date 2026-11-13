extends CharacterBody2D
## Een speler: leest zijn inputbron, beweegt via Motor en neemt elke tick op.
##
## Heeft geen eigen _physics_process: de Sim roept `sim_step` en `record`
## aan, zodat de volgorde van alle actors per tick vastligt (E-07b: schaduw,
## dan P1 stapt, dan P1 wordt opgenomen). Een speler voert zijn events niet
## zelf uit; de Sim doet dat in stap (4).

const Motor = preload("res://scripts/echo/motor.gd")
const EchoRecorder = preload("res://scripts/echo/echo_recorder.gd")
const BodyBuilder = preload("res://scripts/echo/body_builder.gd")
const EventDetector = preload("res://scripts/events/event_detector.gd")
const InputBits = preload("res://scripts/input/input_bits.gd")
const Layers = preload("res://scripts/world/layers.gd")
const Tuning = preload("res://scripts/echo/tuning.gd")
const GameEvents = preload("res://scripts/events/game_events.gd")

## ROOM: kamerwissel naar een kamer die geen buur is (E-04a), gezet door de
## AreaLoader na stap (3).
enum EchoReset { NONE, RELEASE, RESPAWN, ROOM }

## De levenspunten van P1 veranderden: een vijandelijke treffer kostte er één
## (LM-05), of ze zijn weer vol op de respawntick na een dood. Bij 0 zet
## `scripts/save/respawn.gd` P1 terug (checkpoint of begin van de kamer).
## Tot die respawntick blijft P1 op 0 en kost een treffer niets meer.
signal health_changed(tick: int, health: int)

## Elke inputbron heeft `sample(tick: int) -> int` (DeviceInput, ScriptedInput).
var input_source: RefCounted
var recorder: EchoRecorder
var player_index: int
var last_input := 0
## Events van de laatste stap (GameEvents-masker, E-10).
var tick_events := 0
## Bewegingsevents van de laatste stap (Motor.EV_*): sprong, bounce,
## springplank-landing, dash. Voor lichtmeter en meetlog, niet voor de echo.
var move_events := 0
## Verborgen bewegingstoestand (snelheid in px/tick, dash, buffers).
var motor := Motor.State.new()
## Vraagt deze tick een reset van de echo (E-04a kamerwissel, E-04b respawn,
## E-04c Loslaten)?
## De echo leest dit na stap (3) van dezelfde tick (`sim_after_source`).
var echo_reset: EchoReset = EchoReset.NONE
## Levenspunten (LM-05: 5 in de flow-kamer). P2 heeft er geen (C-02).
var health := 5
## LM-07, WS-08 a: het maximum, 5 plus 1 per gevonden lampglas (tot `HEALTH_CAP`).
## Een respawn na een dood vult tot hier.
var max_health := 5
## LM-07: hooguit 9 levenspunten.
const HEALTH_CAP := 9
## `geldig_vanaf` van de echo van deze speler (E-03). Hoort bij P1, niet bij
## de echo-node: Loslaten en respawn zetten hem ook in co-op (E-09, C-04),
## en de echo van een drop-out neemt hem over (C-05).
var echo_valid_from := 0
## De plank van dit lichaam (C-09): P1 de lichtplank (laag 8, alleen in
## co-op), P2 de schaduwplank (laag 6). De Sim zet de laag per tick.
var plank: StaticBody2D
## Stond dit lichaam sinds zijn laatste grondcontact op een plank of werd het
## gevangen? Dan draagt zijn plank niet (C-09, ladderregel).
var plank_since_ground := false
## Werd dit lichaam in deze luchtfase al gevangen (C-13 (4))?
var caught_this_airphase := false
## Tot (niet t/m) deze tick onkwetsbaar voor vijandelijke aanvallen (C-13).
var invulnerable_until := -1
## Laatste positie op eigen vloer (laag 1, 4 of 5), voor de plaatsingsregel (C-03).
var last_floor_position := Vector2.ZERO
## Opgelost (C-06): het lichaam staat niet in de wereld (geen laag, geen
## plank, onzichtbaar, stapt niet). Alleen P2; de Sim zet en wist het.
var dissolved := false
## Stierf P1 bij de laatste respawn (C-08)? Dan zet de Sim P2 naast hem.
var died := false

## De plank waarop dit lichaam aan het begin van deze tick stond (of null).
var started_on_plank: CollisionObject2D = null

var _detector := EventDetector.new()
var _pre_position := Vector2.ZERO
var _pre_velocity := Vector2.ZERO
var _pre_floor := false
var _echo_held := 0
var _respawn_requested := false
var _respawn_position := Vector2.ZERO
var _respawn_death := false
var _stance_event := -1000000   ## tick van het laatste AANVAL-event (C-11a)
var _stance_held := false        ## AANVAL sindsdien aaneengesloten ingedrukt
## VJ-02 (LM-05): schade per vijandelijke treffer en ticks onkwetsbaar daarna (uit data, in `setup`).
var _hit_damage := 1
var _invulnerable_ticks := 45
## VJ-02 (B-12): ticks onkwetsbaar na een respawn (`combat.p1_respawn_invulnerable_ticks`).
var _respawn_invulnerable_ticks := 45


func setup(p_player_index: int, p_input_source: RefCounted, color: Color,
		capacity: int = -1) -> void:
	player_index = p_player_index
	input_source = p_input_source
	health = int(Tuning.combat()["p1_health"])
	max_health = health
	_hit_damage = int(Tuning.combat()["p1_hit_damage"])
	_invulnerable_ticks = int(Tuning.combat()["p1_invulnerable_ticks"])
	_respawn_invulnerable_ticks = int(Tuning.combat()["p1_respawn_invulnerable_ticks"])
	# E-02: recorder-capaciteit uit de data, tenzij de aanroeper hem opgeeft.
	recorder = EchoRecorder.new(capacity if capacity > 0 else int(Tuning.echo()["recorder_capacity"]))
	name = "Player%d" % player_index
	# E-05: P1 op laag 2 met masker 1 + 4 + 6; P2 op laag 3 met masker 1 + 5.
	if player_index == 1:
		collision_layer = Layers.LIGHT
		collision_mask = Layers.P1_MASK
	else:
		collision_layer = Layers.SHADOW
		collision_mask = Layers.P2_MASK
	# E-07a (4): geen ingebouwde platformsnelheid; meebewegen doet de Motor.
	platform_on_leave = CharacterBody2D.PLATFORM_ON_LEAVE_DO_NOTHING
	platform_floor_layers = Layers.WORLD | Layers.LIGHT_GEOMETRY
	BodyBuilder.add_box(self, color, Tuning.body_size())
	plank = BodyBuilder.add_plank(self, Tuning.body_size(), float(Tuning.echo()["plank_thickness_px"]))
	last_floor_position = position


## De laag van de plank als hij aan staat: P1 lichtplank, P2 schaduwplank.
func plank_layer() -> int:
	return Layers.LIGHT_PLANK if player_index == 1 else Layers.PLANK


## Zet de plank aan of uit en op zijn plek in de physics-ruimte, voor de stap
## van de springer in dezelfde tick (C-09). `coop`: doet P2 mee?
func refresh_plank(coop: bool) -> void:
	plank.collision_layer = plank_layer() if coop and carrier_valid() else 0
	BodyBuilder.sync_plank(plank)


# --- drager (C-09, C-11, C-13) ----------------------------------------------

## Draagt de plank (C-09)? Niet opgelost en sinds het laatste grondcontact
## niet op een plank gestaan of gevangen (ladderregel).
func carrier_valid() -> bool:
	return not dissolved and not plank_since_ground


## C-11a: AANVAL sinds het laatste AANVAL-event aaneengesloten ingedrukt, en
## dat event is ≥ 12 ticks geleden.
func carrier_in_stance(tick: int) -> bool:
	return _stance_held and tick - _stance_event >= int(Tuning.coop()["stance_hold_ticks"])


## C-11d: de houding eindigt op de lanceertick.
func consume_stance(_tick: int) -> void:
	_stance_held = false


func carrier_facing() -> int:
	return motor.facing


## Zet de speler op de volgende tick terug op `at` (respawn, E-04b). Dat
## telt als reset van de echo op die tick. `death`: P1 stierf (LM-05); in
## co-op respawnt P2 dan mee naast P1 (C-08).
func respawn_at(at: Vector2, death := false) -> void:
	_respawn_requested = true
	_respawn_position = at
	_respawn_death = death


## Een vijandelijk aanvalsvlak raakt dit lichaam (alleen laag 2, E-14h). Daarna is P1
## 45 ticks onkwetsbaar (VJ-02, LM-05; `combat.p1_invulnerable_ticks`, gelezen in `setup`).
func take_hit(tick: int) -> void:
	if player_index != 1 or health <= 0 or tick < invulnerable_until:
		return
	health = maxi(health - _hit_damage, 0)
	# Een treffer die P1 doodt, geeft geen onkwetsbaarheid: de respawn begint een nieuw leven.
	if health > 0:
		invulnerable_until = maxi(invulnerable_until, tick + _invulnerable_ticks)
	health_changed.emit(tick, health)


## V-01b: een neerslag raakte iets. `v.y = −5,0` (zoals een sprong), `v.x` blijft, dash terug;
## geen sprong in de coyote-tijd erna. Werkt vanaf de volgende stap (de Sim roept dit in stap 4).
func bounce_off(_tick: int) -> void:
	motor.velocity.y = float(Tuning.combat()["neerslag_bounce_velocity"])
	motor.dash_ready = true
	motor.dash_ready_after_dash = false
	motor.jumped_since_support = true


## Stap (2) voor P1, (1) voor P2: input lezen, events bepalen, bewegen.
func sim_step(tick: int, _delta: float) -> void:
	echo_reset = EchoReset.NONE
	died = false
	if _respawn_requested:
		_respawn_requested = false
		died = _respawn_death
		_respawn_death = false
		position = _respawn_position
		motor = Motor.State.new()
		velocity = Vector2.ZERO
		echo_reset = EchoReset.RESPAWN
		# Na een dood (C-08, LM-05) zijn de levenspunten weer vol, en is P1 45 ticks onkwetsbaar
		# vanaf de respawntick (`r … r + 44`; VJ-02, gdd v0.8.1), zodat een aanloop die bij het
		# respawnpunt al liep hem niet raakt. De dodelijke treffer zelf gaf geen onkwetsbaarheid.
		if died and player_index == 1:
			health = max_health
			invulnerable_until = tick + _respawn_invulnerable_ticks
			health_changed.emit(tick, health)
	var bits: int = input_source.sample(tick)
	last_input = bits
	tick_events = _detector.detect(tick, bits)
	_pre_position = position
	_pre_velocity = motor.velocity
	started_on_plank = motor.plank if motor.support == Motor.Support.SHADOW_BODY else null
	_pre_floor = motor.on_floor
	move_events = Motor.step(self, motor, bits, tick)
	_update_stance(tick, bits)
	_update_ground()
	if player_index == 1:
		_update_release(bits)
	if echo_reset != EchoReset.NONE:
		echo_valid_from = tick


func pre_position() -> Vector2:
	return _pre_position


func pre_velocity() -> Vector2:
	return _pre_velocity


## Stap (3): deze tick opnemen (E-01), na de stap.
func record(tick: int) -> void:
	recorder.push(tick, last_input, _pre_position, _pre_velocity, _pre_floor,
		position, motor.velocity, tick_events, motor.on_floor, motor.facing,
		motor.support, motor.anim, last_input & InputBits.ATTACK != 0, plank_since_ground)


func _update_stance(tick: int, bits: int) -> void:
	if tick_events & GameEvents.ATTACK:
		_stance_event = tick
		_stance_held = true
	elif bits & InputBits.ATTACK == 0:
		_stance_held = false


## Grondcontact (C-09, C-13 (4)): staan op laag 1, 4 of 5, niet op een plank.
func _update_ground() -> void:
	if not motor.on_floor:
		return
	if motor.support == Motor.Support.SHADOW_BODY:
		plank_since_ground = true
	else:
		plank_since_ground = false
		caught_this_airphase = false
		last_floor_position = position


## E-09: ECHO 30 ticks aaneengesloten vasthouden is Loslaten, één keer per druk.
func _update_release(bits: int) -> void:
	if bits & InputBits.ECHO:
		_echo_held += 1
		if _echo_held == int(Tuning.echo()["release_hold_ticks"]) and echo_reset == EchoReset.NONE:
			echo_reset = EchoReset.RELEASE
	else:
		_echo_held = 0


## WS-08 a, LM-07: een lampglas geeft +1 maximum levenspunt (tot 9) en vult de
## levenspunten aan. Alleen P1 heeft levenspunten (C-02).
func add_lampglas(tick: int) -> void:
	if player_index != 1:
		return
	max_health = mini(max_health + 1, HEALTH_CAP)
	health = max_health
	health_changed.emit(tick, health)
