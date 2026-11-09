extends RefCounted
## De minimale lichtmeter (gdd §2.12, LM-01 en LM-02), voor de flow-kamer.
##
## Eén geheel getal `value` van 0 tot 100 LP. Lekt niet, verliest niets bij
## respawn, breken of Loslaten (LM-01). Luistert naar de Sim: treffers en
## ontploffingen uit `Combat`, springplank-landingen en bounces uit de
## bewegingsevents van P1 en in co-op ook van P2 (Motor.EV_*), ook lancering
## (+4) en vang (+3) uit co-op 7A (T16c, #78). `who` is dan de drager.
##
## Elk vullen geeft `filled`; het meetlog maakt er een LP-regel van (§4.5).

## `amount` is de waarde uit LM-02 (`+n`), `added` wat er na de grens van 100
## echt bij kwam. `source` is de bron uit LM-02, `who` wie hem mogelijk maakte:
## de aanvaller (treffer), de ontsteker (ontploffing) of de drager (springplank,
## bounce): `p1`, `p2` of `echo`.
signal filled(tick: int, amount: int, added: int, source: String, who: String)

const Motor = preload("res://scripts/echo/motor.gd")
const CombatTarget = preload("res://scripts/combat/combat_target.gd")

const MAX := 100
## LM-02.
const HIT := 2
const LINK := 6
const PLANK_BASE := 3
const PLANK_STEP := 2
const PLANK_MAX_N := 4
const BOUNCE := 2
const LAUNCH := 4
const CATCH := 3

var value := 0
## `n` van LM-02 voor P1: springplank-landingen sinds P1 voor het laatst
## wereld of licht-geometrie raakte.
var chain := 0
## `n` van LM-02 voor P2 (co-op: elk lichaam een eigen `n`).
var chain_p2 := 0
## Is het co-op? Bepaalt wie een ontploffing ontstak (C-12).
var coop := false
## Opgeteld per `who` (echt toegevoegd), voor MP-6.
var totals := {}

var _sim: Node
var _p1: Node


func _init(sim: Node, p1: Node) -> void:
	_sim = sim
	_p1 = p1
	sim.combat.hit.connect(_on_hit)
	sim.combat.mark_exploded.connect(_on_exploded)
	sim.tick_finished.connect(_on_tick)


## Licht toevoegen (LM-01: boven 100 gaat het teveel verloren).
func add(tick: int, amount: int, source: String, who: String) -> void:
	var added := clampi(amount, 0, MAX - value)
	value += added
	totals[who] = int(totals.get(who, 0)) + added
	filled.emit(tick, amount, added, source, who)


## Licht naar het gemaal (LM-03). Geeft terug wat er echt af ging.
func take(amount: int) -> int:
	var taken := clampi(amount, 0, value)
	value -= taken
	return taken


func _on_hit(tick: int, attacker: String, target: Node2D, damage: int) -> void:
	# LM-02: treffer op een vijand +2 (P1, P2, gewone echo-treffer); een intact
	# pantser geeft 0 (de schade is dan 0); trefpop en pomprad vullen niets.
	if target is CombatTarget and (target as CombatTarget).kind == CombatTarget.Kind.DUMMY:
		return
	if damage > 0:
		add(tick, HIT, "treffer", attacker)


func _on_exploded(tick: int, mark: RefCounted, _link: int) -> void:
	# Elke schakel +6. Solo ontsteekt alleen de echo; in co-op het andere
	# lichaam dan de zetter (C-12b).
	var who := "echo"
	if coop:
		who = "p2" if mark.setter == "p1" else "p1"
	add(tick, LINK, "ontploffing", who)


func _on_tick(tick: int) -> void:
	if _p1 == null or not is_instance_valid(_p1):
		return
	chain = _fill_from(tick, _p1, chain, "p2" if coop else "echo")
	# LM-02 co-op: springplank-landingen, bounces, lanceringen en vangen tellen
	# ook voor P2 als springer, met zijn eigen `n`; de drager is dan P1.
	var p2: Node = _sim.get_player(2) if _sim.has_method("get_player") else null
	if p2 != null and not p2.dissolved:
		chain_p2 = _fill_from(tick, p2, chain_p2, "p1")
	elif p2 == null:
		chain_p2 = 0


## LP voor één springer; `who` is de drager (bron in het meetlog, §4.5).
## Geeft de nieuwe `n` terug.
func _fill_from(tick: int, springer: Node, n: int, who: String) -> int:
	var motor = springer.motor
	if motor.on_floor and motor.support != Motor.Support.SHADOW_BODY:
		n = 0
	var ev: int = springer.move_events
	if ev & Motor.EV_SPRINGPLANK:
		n = mini(n + 1, PLANK_MAX_N)
		add(tick, PLANK_BASE + PLANK_STEP * (n - 1), "springplank", who)
	if ev & Motor.EV_BOUNCE:
		add(tick, BOUNCE, "bounce", who)
	# C-11, C-13: lancering +4, vang +3 (voor de springer). Een vang telt voor
	# `n` als springplank-landing (C-13).
	if ev & Motor.EV_CATCH:
		n = mini(n + 1, PLANK_MAX_N)
		add(tick, CATCH, "vang", who)
	if ev & Motor.EV_LAUNCH:
		add(tick, LAUNCH, "lancering", who)
	return n
