extends RefCounted
## Leesbaarheid na F0 (gdd §4.7 (a) en (c)): plank-signaal (E-07d), doelstreep
## (E-02t), bereikcirkel en kettinglijn (E-14j). **Alleen beeld en geluid**:
## niets hiervan verandert een spelregel. Elke tick (na stap 5, op
## `Sim.tick_finished`) zet dit object vlaggen die het beeld (placeholder in
## `flow_room.gd`, eindvorm T10) en de tests lezen.
##
## - `plank_signaal` (E-07d): de echo is Actief, draagt zijn plank (E-07c),
##   is niet in een merksprong, en de horizontale afstand tussen zijn
##   middelpunt en dat van P1 is kleiner dan op `t − 1` en ≤ 130 px. Uit bij
##   een landing op de plank of zodra de afstand niet meer kleiner wordt.
## - `doelstreep` (E-02t): in een van de frames `p + 1 … p + 30` (al
##   opgenomen, want D ≥ 90) staat een AANVAL-event, en op tick `t` ligt een
##   merk binnen R van de positie van dat frame met vrije zichtlijn (dezelfde
##   zoekregel als E-02m, `Combat.find_jump_target`). `doelstreep_mark` is dat
##   merk; `doelstreep_strength` loopt van 0 (30 ticks vooraf) naar 1 (de slag).
##   Welk merk echt ontploft, beslist E-02m op het moment zelf.
## - `in_bereik` (E-14j): elk doel met zijn middelpunt binnen E van een levend
##   merk (inclusief de grens); `chain_links`: paren merken binnen K.
##
## Geluid (tik bij het plank-signaal, carillon-voorslag bij de doelstreep)
## komt van de Audio Director (T10); de signalen hieronder zijn het haakje.

signal plank_signal_on(tick: int)
signal doelstreep_on(tick: int, mark_id: int)

const Tuning = preload("res://scripts/echo/tuning.gd")
const GameEvents = preload("res://scripts/events/game_events.gd")
const Motor = preload("res://scripts/echo/motor.gd")
const CombatTarget = preload("res://scripts/combat/combat_target.gd")

## E-07d: de plank van de echo licht op.
var plank_signaal := false
## E-02t: de doelstreep staat aan, naar `doelstreep_mark`.
var doelstreep := false
var doelstreep_mark: RefCounted = null
## 0 … 1: hoe dicht de slag is (feller naarmate de slag nadert).
var doelstreep_strength := 0.0
## E-14j: doelen binnen E van een merk (doel -> true).
var in_bereik := {}
## E-14j: kettinglijnen, als [merk, merk] met de middelpunten binnen K.
var chain_links: Array = []

var _sim: Node
var _p1: Node2D
## Geeft de staart-echo van nu (of null): die wisselt bij drop-in/drop-out.
var _echo_of: Callable
var _prev_dx := INF
var _lead_ticks := 30
var _signal_px := 130.0


func _init(sim: Node, p1: Node2D, echo_of: Callable) -> void:
	_sim = sim
	_p1 = p1
	_echo_of = echo_of
	_lead_ticks = int(Tuning.combat()["doelstreep_ticks"])
	_signal_px = float(Tuning.echo()["plank_signal_px"])
	sim.tick_finished.connect(update)


## Is `target` binnen E van een merk (E-14j)?
func is_in_bereik(target: Node) -> bool:
	return in_bereik.has(target)


func update(tick: int) -> void:
	var echo: Node2D = _echo_of.call() if _echo_of.is_valid() else null
	if echo != null and not is_instance_valid(echo):
		echo = null
	_update_plank_signal(tick, echo)
	_update_doelstreep(tick, echo)
	_update_reach()


# --- E-07d -------------------------------------------------------------------

func _update_plank_signal(tick: int, echo: Node2D) -> void:
	var was := plank_signaal
	var carrying: bool = echo != null and echo.is_present() and not echo.in_merksprong \
		and echo.has_method("carrier_valid") and echo.carrier_valid()
	if not carrying or _p1 == null:
		plank_signaal = false
		_prev_dx = INF
		return
	var dx: float = absf(echo.global_position.x - _p1.global_position.x)
	var on_plank: bool = _p1.motor.support == Motor.Support.SHADOW_BODY and _p1.motor.plank == echo.plank \
		or _p1.move_events & Motor.EV_SPRINGPLANK != 0
	plank_signaal = dx < _prev_dx and dx <= _signal_px and not on_plank
	_prev_dx = dx
	if plank_signaal and not was:
		plank_signal_on.emit(tick)


# --- E-02t -------------------------------------------------------------------

func _update_doelstreep(tick: int, echo: Node2D) -> void:
	var was_mark: RefCounted = doelstreep_mark if doelstreep else null
	doelstreep = false
	doelstreep_mark = null
	doelstreep_strength = 0.0
	if echo == null or echo.get("source") == null or echo.finished:
		return
	var rec = echo.source.recorder
	var p: int = tick - int(echo.tail_ticks)
	var space: PhysicsDirectSpaceState2D = echo.get_world_2d().direct_space_state
	# Het eerstvolgende AANVAL-event in p + 1 … p + 30 dat een doelmerk heeft.
	for ahead in range(1, _lead_ticks + 1):
		var q := p + ahead
		if q < int(echo.valid_from) or q > tick:
			continue
		var index: int = rec.index_of_tick(q)
		if index < 0 or rec.events(index) & GameEvents.ATTACK == 0:
			continue
		var mark: RefCounted = _sim.combat.find_jump_target(rec.post_position(index), space)
		if mark == null or not mark.target.alive:
			continue
		doelstreep = true
		doelstreep_mark = mark
		doelstreep_strength = 1.0 - float(ahead - 1) / float(_lead_ticks)
		break
	if doelstreep and doelstreep_mark != was_mark:
		doelstreep_on.emit(tick, doelstreep_mark.id)


# --- E-14j -------------------------------------------------------------------

func _update_reach() -> void:
	in_bereik.clear()
	chain_links.clear()
	var c: Dictionary = Tuning.combat()
	var reach := float(c["explosion_radius_px"])
	var chain := float(c["chain_radius_px"])
	var marks: Array = _sim.combat.marks.filter(func(m: RefCounted) -> bool: return m.alive and m.target.alive)
	for mark in marks:
		var at: Vector2 = mark.center()
		for target: CombatTarget in _sim.combat.targets:
			if target.alive and target.is_markable() and target.global_position.distance_to(at) <= reach:
				in_bereik[target] = true
	for i in marks.size():
		for j in range(i + 1, marks.size()):
			if marks[i].center().distance_to(marks[j].center()) <= chain:
				chain_links.append([marks[i], marks[j]])
