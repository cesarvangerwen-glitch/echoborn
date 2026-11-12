extends Node2D
## Speelbare demo van de echo v0.4: P1 met zijn staart-echo (E-02), en P2
## die mee kan doen (C-01).
##
## P1: A/D lopen, spatie springen, linker Shift dash, E aanval, Q 0,5 s
## vasthouden = Loslaten (E-09). Sla de rode vijand of het grijze pantserdoel:
## je zet een merk, en je echo laat het D ticks later knallen (E-14, E-02m). Spring op je echo: landen geeft je dash
## terug, springen vanaf de echo is een bounce (E-07a). Debug: F1/F2/F3/F7 zet
## D op 60/90/120/180 ticks (1/1,5/2/3 s, `echo.tail_options` in data; telt
## als reset). De demo start op D uit data (`echo.tail_ticks`, 60). Enter laat P2 meedoen,
## Backspace laat P2 stoppen (pijltjes + Enter + rechter Ctrl, `input.md`
## §2a); zolang P2 meedoet, is er geen echo
## (C-01). De echte drop-in en drop-out (C-03, C-05) komen in T16c; de
## flow-kamer in T16b. Vijanden van de slice (T8b, placeholder): een Kadeloper en een
## Schotdrager als E-paar en een Dwaallicht; Neerslag (V-01) = S + E in de lucht (P2: ↓).

const Sim = preload("res://scripts/sim.gd")
const PlayerActor = preload("res://scripts/echo/player_actor.gd")
const TailEcho = preload("res://scripts/echo/tail_echo.gd")
const DeviceInput = preload("res://scripts/input/device_input.gd")
const InputSetup = preload("res://scripts/input/input_setup.gd")
const SpikeWorld = preload("res://scripts/world/spike_world.gd")
const Tuning = preload("res://scripts/echo/tuning.gd")
const CombatTarget = preload("res://scripts/combat/combat_target.gd")
const SliceEnemy = preload("res://scripts/combat/slice_enemy.gd")
const EnemyData = preload("res://scripts/combat/enemy_data.gd")
## De toets-naar-plek-tabel van het debugmenu staat op één plek: in de flow-kamer (SM-punt PR #194).
const FlowRoom = preload("res://levels/flowkamer/flow_room.gd")

const PLAYER_COLORS := [Color(1.0, 0.85, 0.4), Color(0.5, 0.85, 1.0)]
const ECHO_COLOR := Color(0.2, 0.15, 0.35, 0.8)

var _sim: Sim
var _p1: PlayerActor
var _echo: TailEcho
var _p2: PlayerActor
var _tail := int(Tuning.echo()["tail_ticks"])


func _ready() -> void:
	InputSetup.ensure_actions()
	SpikeWorld.build(self)
	_sim = Sim.new()
	_sim.name = "Sim"
	add_child(_sim)
	_tail = int(Tuning.echo()["tail_ticks"])
	_p1 = PlayerActor.new()
	_p1.setup(1, DeviceInput.new(1), PLAYER_COLORS[0])
	_p1.position = SpikeWorld.PLAYER_SPAWN
	_sim.add_player(_p1)
	_add_echo()
	# Een basisvijand en een pantserdoel om het schaduwmerk te proberen (E-14).
	for spec: Array in [[CombatTarget.Kind.ENEMY, 520.0], [CombatTarget.Kind.ARMORED, 1000.0]]:
		var target := CombatTarget.new()
		target.setup_target(spec[0])
		target.position = Vector2(spec[1], SpikeWorld.FLOOR_Y - 12.0)
		_sim.add_object(target)
	# T8b (placeholder): een E-paar Kadeloper + Schotdrager en een Dwaallicht (slice.csv).
	var floor_y := SpikeWorld.FLOOR_Y
	var kadeloper := SliceEnemy.new()
	kadeloper.setup_enemy(SliceEnemy.Type.KADELOPER, 720.0, floor_y)
	var schotdrager := SliceEnemy.new()
	var e_pair := EnemyData.value("gedeeld", "paar_e")
	schotdrager.setup_enemy(SliceEnemy.Type.SCHOTDRAGER, 720.0 + e_pair, floor_y)
	SliceEnemy.make_pair(kadeloper, schotdrager, e_pair)
	var dwaallicht := SliceEnemy.new()
	dwaallicht.setup_enemy(SliceEnemy.Type.DWAALLICHT, 860.0, floor_y, 840.0, 900.0)
	for enemy: SliceEnemy in [kadeloper, schotdrager, dwaallicht]:
		_sim.add_object(enemy)
	var camera := Camera2D.new()
	camera.position = Vector2(640, 260)
	add_child(camera)


# Demo: D wisselen en meedoen gebeuren hier buiten de tick, op de volgende
# tick (`_sim.tick`). In productie loopt dit via het debugmenu (T16b) en de
# InputRouter (T16c deel 2).
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo \
			and FlowRoom.DEBUG_TAIL_KEYS.has(event.physical_keycode):
		_tail = FlowRoom.debug_tail(event.physical_keycode)
		_sim.set_tail_ticks(_tail)
	elif event.is_action_pressed("p2_join") and _p2 == null:
		_p2 = PlayerActor.new()
		_p2.setup(2, DeviceInput.new(2), PLAYER_COLORS[1])
		# C-03: P2 neemt de echo over, of verschijnt bij P1 (plaatsingsregel).
		if _sim.drop_in(_p2):
			_echo = null  # de Sim heeft hem weggehaald (C-01)
		else:
			_p2.free()
			_p2 = null
	elif event.is_action_pressed("p2_leave") and _p2 != null:
		# C-05: de echo neemt over met de `geldig_vanaf` van P1.
		_echo = _sim.drop_out(ECHO_COLOR)
		_p2 = null


func _add_echo() -> void:
	_echo = TailEcho.new()
	_echo.setup(_p1, ECHO_COLOR, _tail, _sim.tick)
	if not _sim.add_echo(_echo):
		_echo.free()
		_echo = null
