extends RefCounted
## De gescripte geoefende co-op-run door de flow-kamer (gdd §4.5, §2.7; #125).
##
## Twee inputbronnen (`p1_input`, `p2_input`, elk met `sample(tick) -> int`,
## zoals ScriptedInput) voor een geoefend duo: P1 en P2 spelen samen de route,
## met de vier acties van §2.7 waar de kamer ze aanbiedt:
##
## - **B4 lancering** (C-11): P1 is de drager, staat aan de rand in houding;
##   P2 springt op hem en vliegt over. P1 neemt de langzame lijn.
## - **B3, B1, B2 bounce in beide richtingen** (C-09, C-10): op elk niveau
##   staat de een als drager onder het volgende niveau en bounct de ander op
##   hem omhoog; de drager neemt de langzame lijn (de trede) en is op het
##   volgende niveau de springer. Zo wisselen de rollen elk niveau: P1
##   springt in B3, B2-0 en B2-2, P2 in B4 (lancering), B1, B2-1 en B2-3.
## - **K2 merk-combo** (C-12): elk lichaam slaat eerst een vijand met een merk
##   van de ander (dat merk knalt), anders een vijand zonder merk (dat zet een
##   merk). De zetter laat zijn eigen merk staan.
## - **K3 pompen** (LM-03): P1 pompt rechts van het pomprad, P2 links.
##
## Net als `flow_bot.gd` gebruikt het duo alleen wat spelers zien (posities,
## houding, merken, de meter): dezelfde kamer en D geven dezelfde input en
## hetzelfde meetlog. `recorded` houdt per speler de bits bij. De bronnen
## verwijzen zwak naar het duo: wie ze gebruikt, houdt het duo zelf vast.
##
## Werkaanname (WLD, #125): de "scripted geoefende run" in co-op (gdd §4.5) is
## dit duo: twee spelers die de route kennen en op elkaar wachten waar dat
## moet. In co-op is er geen echo (C-01); de lus-timing van B3 en de
## keer-timing van B1/B2 (gdd §4.3) gelden dus niet: de drager gaat gewoon
## onder het volgende niveau staan. Wat de kamer daarvan meet, staat in
## `docs/design/kamers/flowkamer.md` §9.

const InputBits = preload("res://scripts/input/input_bits.gd")
const Motor = preload("res://scripts/echo/motor.gd")
const Layout = preload("res://levels/flowkamer/flow_layout.gd")

const L := InputBits.LEFT
const R := InputBits.RIGHT
const J := InputBits.JUMP
const A := InputBits.ATTACK

## B4: de drager staat hier aan de rand (gdd §4.3: ≤ 8 px van de rand).
const B4_STANCE_X := Layout.B4_NEAR_EDGE + 2.0
## B4: zo lang houdt de drager zijn houding vast als niemand op hem springt.
const B4_GIVE_UP_TICKS := 240
## Tussen twee slagen (aanval en pomp), zoals de solo-bot.
const ATTACK_EVERY := 21
## Zoveel px achter de ander loopt een speler als hij niets te doen heeft.
const FOLLOW_PX := 30.0
## De drager loopt heen en weer rond zijn plek tot de springer er is: zo staat
## hij niet stil (MP-1: binnen 24 px blijven is stil; ± 30 px is genoeg).
const PATROL_PX := 30.0
## Vanaf zo ver springt de springer al lopend op de drager (een sprong duurt
## ± 33 ticks tot plankhoogte, × 2 px/tick).
const RUNUP_PX := 66.0

## De route: [naam, soort, springer (1 of 2; 0 = geen), parameters].
## "lift" = de drager wacht rond `spot` op niveau `level` (± `PATROL_PX`, overal
## onder `next` en niet onder een trede); de springer bounct naar `next`; de
## drager neemt daarna de trede op `tread` (midden-x, bovenkant) en springt in
## richting `dir` naar `next`.
const STEPS := [
	["B4", "launch", 2, {}],
	["B3", "lift", 1, {"level": Layout.FLOOR, "next": Layout.LEVEL_540, "spot": 330.0,
		"tread": [Layout.B3_GALLERY_TIP - 20.0, Layout.FLOOR - 35.0], "dir": 1}],
	["B1", "lift", 2, {"level": Layout.LEVEL_540, "next": Layout.LEVEL_450, "spot": 565.0,
		"tread": [Layout.B1_WALL - 20.0, Layout.LEVEL_540 - 45.0], "dir": 1}],
	["B2-0", "lift", 1, {"level": Layout.LEVEL_450, "next": 360.0, "spot": 1030.0,
		"tread": [Layout.SHAFT_RIGHT - 20.0, Layout.LEVEL_450 - 45.0], "dir": -1}],
	["B2-1", "lift", 2, {"level": 360.0, "next": 270.0, "spot": 750.0,
		"tread": [Layout.SHAFT_LEFT + 20.0, 360.0 - 45.0], "dir": 1}],
	["B2-2", "lift", 1, {"level": 270.0, "next": 180.0, "spot": 1030.0,
		"tread": [Layout.SHAFT_RIGHT - 20.0, 270.0 - 45.0], "dir": -1}],
	["B2-3", "lift", 2, {"level": 180.0, "next": 90.0, "spot": 750.0,
		"tread": [Layout.SHAFT_LEFT + 20.0, 180.0 - 45.0], "dir": 1}],
	["Bovenroute", "top", 0, {}],
	["K2", "arena", 0, {}],
	["K3", "gemaal", 0, {}],
]

## Waar je pompt: links van het pomprad (gezicht rechts) of rechts (gezicht
## links). Aanvalsvlak 8–28 px vóór het lichaam, pomprad 32 px breed. Wie eerst
## beneden is, neemt links: de ander valt rechts van de trap naar beneden en
## landt dan niet op hem.
const PUMP_LEFT_X := Layout.POMPRAD_AT.x - 30.0
const PUMP_RIGHT_X := Layout.POMPRAD_AT.x + 30.0


## Eén speler: zijn bron, toestand en opgenomen bits.
class Seat:
	extends RefCounted
	## Zwakke verwijzing naar het duo (anders houden duo en stoel elkaar vast).
	var duo: WeakRef
	var index := 1
	var step := 0
	var sub := ""
	var since := 0
	var prev := 0
	var last_x := INF
	var stuck := 0
	var from_tread := false
	var last_attack := -1000
	var patrol_dir := 1
	var pump_x := NAN
	var recorded := PackedInt32Array()

	func sample(tick: int) -> int:
		var owner = duo.get_ref()
		var bits: int = owner._decide(self, tick) if owner != null else 0
		recorded.append(bits)
		prev = bits
		return bits


var p1_input: Seat
var p2_input: Seat
## Welke bouwstenen de samenwerkingsactie haalden (naam -> true), of de
## springer de langzame lijn moest nemen (false).
var lines := {}

var _room: Node
var _tick := 0


func _init(room: Node) -> void:
	_room = room
	p1_input = Seat.new()
	p1_input.duo = weakref(self)
	p1_input.index = 1
	p2_input = Seat.new()
	p2_input.duo = weakref(self)
	p2_input.index = 2


# --- Hulpjes ---

func _body(s: Seat) -> CharacterBody2D:
	return _room.p1 if s.index == 1 else _room.p2


func _other(s: Seat) -> Seat:
	return p2_input if s.index == 1 else p1_input


func _who(s: Seat) -> String:
	return "p%d" % s.index


func _on_level(s: Seat, level_top: float) -> bool:
	var b := _body(s)
	return b.motor.on_floor and b.motor.support != Motor.Support.SHADOW_BODY \
		and absf(b.position.y - (level_top - Layout.HALF_H)) < 1.5


## Staat `s` op de plank van de ander?
func _on_partner(s: Seat) -> bool:
	var b := _body(s)
	var o := _body(_other(s))
	return o != null and b.motor.on_floor and b.motor.support == Motor.Support.SHADOW_BODY \
		and b.motor.plank == o.plank


func _launched(b: CharacterBody2D) -> bool:
	return b.motor.launch_pending or b.motor.launch_left > 0


func _tap(s: Seat, bit: int) -> int:
	return 0 if s.prev & bit else bit


func _walk(dir: int) -> int:
	return R if dir > 0 else L


## Naar `x` lopen; 0 als je er (± 2 px) bent.
func _go_to(s: Seat, x: float) -> int:
	var dx := x - _body(s).position.x
	if absf(dx) <= 2.0:
		return 0
	return R if dx > 0.0 else L


func _update_stuck(s: Seat) -> void:
	var x := _body(s).position.x
	s.stuck = s.stuck + 1 if absf(x - s.last_x) < 0.5 else 0
	s.last_x = x


func _next_step(s: Seat) -> void:
	s.step += 1
	s.sub = ""
	s.since = 0
	s.stuck = 0
	s.last_x = INF
	s.from_tread = false


# --- Beslissing per tick ---

func _decide(s: Seat, tick: int) -> int:
	_tick = tick
	var b := _body(s)
	if b == null or _room.run_over or (s.index == 2 and b.dissolved):
		return 0
	_update_stuck(s)
	s.since += 1
	if s.step >= STEPS.size():
		return 0
	var spec: Array = STEPS[s.step]
	match spec[1]:
		"launch":
			return _launch(s, spec)
		"lift":
			return _lift(s, spec)
		"top":
			return _top(s)
		"arena":
			return _arena(s)
		"gemaal":
			return _gemaal(s)
	return 0


## B4 (C-11, gdd §4.3 co-op): de drager gaat aan de rand staan, slaat en houdt
## AANVAL vast met zijn gezicht naar de kloof; de springer springt op hem en
## vliegt over. De drager neemt daarna de langzame lijn.
func _launch(s: Seat, spec: Array) -> int:
	var b := _body(s)
	var springer: bool = s.index == spec[2]
	if b.position.x < Layout.B4_FAR_EDGE - 20.0 and _on_level(s, Layout.FLOOR):
		if springer:
			lines[spec[0]] = s.sub == "launched"
		_next_step(s)
		return L
	if not springer:
		match s.sub:
			"":
				if b.position.x > B4_STANCE_X:
					return L
				s.sub = "hold"
				s.since = 0
				return _tap(s, A)
			"hold":
				var o := _other(s)
				if (o.step == s.step and o.sub == "launched") or o.step > s.step or s.since > B4_GIVE_UP_TICKS:
					s.sub = "slow"
					return L
				return A
		return _slow_b4(s)
	var o := _other(s)
	var ob := _body(o)
	match s.sub:
		"":
			var go := _go_to(s, ob.position.x)
			if go != 0:
				return go
			# Springen zodra de drager in houding staat: de landing komt ± 33
			# ticks later, ruim na de 12 ticks van C-11a.
			if o.sub == "hold" and _on_level(o, Layout.FLOOR):
				s.sub = "air"
				s.since = 0
				return _tap(s, J)
			return 0
		"air":
			if _launched(b):
				s.sub = "launched"
				return L
			if s.since > 2 and _on_level(s, Layout.FLOOR):
				s.sub = ""  # gemist: opnieuw
				return 0
			return _go_to(s, ob.position.x)
		"launched":
			if _on_level(s, Layout.KLOOF_BOTTOM):
				s.sub = "slow"
			return L
	return _slow_b4(s)


## B4, langzame lijn: de kloof in, 160 px lopen, twee treden op.
func _slow_b4(s: Seat) -> int:
	var b := _body(s)
	if s.stuck >= 1:
		if b.motor.on_floor:
			return L | _tap(s, J)
		if absf(b.motor.velocity.y) < 0.3:
			return 0
	return L


## Eén niveau omhoog met de ander als plank (C-10). De drager loopt heen en
## weer rond `spot`; de springer loopt naar hem toe en springt al lopend op hem
## (aanloop); de drager blijft staan zodra de springer afzet. Zo staat niemand
## lang stil vóór de landing (MP-1, MP-3). Daarna bounct de springer naar `next`.
func _lift(s: Seat, spec: Array) -> int:
	var args: Dictionary = spec[3]
	var level: float = args["level"]
	var next: float = args["next"]
	var spot: float = args["spot"]
	var springer: bool = s.index == spec[2]
	var b := _body(s)
	if _on_level(s, next):
		if springer:
			lines[spec[0]] = s.sub == "bounce"
		_next_step(s)
		return 0
	var o := _other(s)
	var ob := _body(o)
	if not springer:
		match s.sub:
			"":
				if not _on_level(s, level):
					return 0
				var go := _go_to(s, spot)
				if go != 0:
					return go
				s.sub = "wait"
				s.patrol_dir = 1
				return 0
			"wait":
				# Heen en weer rond de plek; stoppen als de springer afzet.
				if o.step == s.step and o.sub == "air":
					s.sub = "hold"
					s.since = 0
					return 0
				if b.position.x >= spot + PATROL_PX:
					s.patrol_dir = -1
				elif b.position.x <= spot - PATROL_PX:
					s.patrol_dir = 1
				return _walk(s.patrol_dir)
			"hold":
				# Stil blijven staan tot de springer van de plank af is.
				if o.step > s.step or (o.step == s.step and o.sub == "bounce" and not _on_partner(o)):
					s.sub = "slow"
					return 0
				return 0
		return _slow_tread(s, level, args["tread"], args["dir"])
	# Springer.
	match s.sub:
		"":
			if not _on_level(s, level):
				return 0
			if o.step != s.step:
				# De drager is er nog niet: wachten naast de plek.
				var side := 1.0 if b.position.x > spot else -1.0
				return _go_to(s, spot + side * (PATROL_PX + 40.0))
			var dx: float = ob.position.x - b.position.x
			if not (o.sub in ["wait", "hold"]) or absf(dx) > RUNUP_PX:
				return _go_to(s, ob.position.x)
			# Al lopend op de drager springen (aanloop), of recht omhoog als je
			# al naast hem staat.
			s.sub = "air"
			s.since = 0
			return (_walk(1 if dx > 0.0 else -1) if absf(dx) > 2.0 else 0) | _tap(s, J)
		"air":
			if _on_partner(s):
				s.sub = "bounce"
				s.since = 0
				return _tap(s, J)
			if s.since > 2 and _on_level(s, level):
				s.sub = ""
				return 0
			return _go_to(s, ob.position.x)
		"bounce":
			if _on_level(s, level):
				s.sub = ""  # gemist: opnieuw
			return 0
	return 0


## Langzame lijn van de drager: naar de trede, erop springen, dan in richting
## `dir` naar het volgende niveau.
func _slow_tread(s: Seat, level: float, tread: Array, dir: int) -> int:
	var tx: float = tread[0]
	var top: float = tread[1]
	if _on_level(s, top):
		s.from_tread = true
		return _walk(dir) | _tap(s, J)
	if _on_level(s, level):
		s.from_tread = false
		var go := _go_to(s, tx)
		if go != 0:
			return go
		return _tap(s, J)
	return _walk(dir) if s.from_tread else 0


## Bovenroute naar K2. Wie eerst in K2 is, wacht daar (heen en weer).
func _top(s: Seat) -> int:
	var b := _body(s)
	if Layout.room_of(b.position) == "K2" and _on_level(s, Layout.K2_FLOOR):
		_next_step(s)
		return 0
	return R


## K2 (C-12): eerst een vijand met een merk van de ander slaan (hij knalt),
## anders een vijand zonder merk die de ander niet al aanpakt (merk zetten).
## Na golf 2 door het gat naar K3.
func _arena(s: Seat) -> int:
	var b := _body(s)
	if Layout.room_of(b.position) == "K3":
		_next_step(s)
		return L
	var target := _arena_target(s)
	if target == null and _arena_done():
		return R
	if target == null:
		return _wait_in_k2(s)
	var dx: float = target.position.x - b.position.x
	var rel: float = dx * b.motor.facing
	if rel >= 4.0 and rel <= 32.0 and absf(target.position.y - b.position.y) < 20.0:
		if _tick - s.last_attack >= ATTACK_EVERY:
			s.last_attack = _tick
			return _tap(s, A)
		return 0
	if absf(dx) <= 14.0:
		var away := -1 if dx > 0.0 else 1
		if b.position.x + away * 20.0 < Layout.K2_LEFT + 10.0 or b.position.x + away * 20.0 > Layout.K2_HOLE.position.x - 10.0:
			away = -away
		return _walk(away)
	return _walk(1 if dx > 0.0 else -1)


func _arena_target(s: Seat) -> Node2D:
	var b := _body(s)
	var me := _who(s)
	var combat = _room.sim.combat
	var best: Node2D = null
	var best_d := INF
	# (1) een merk van de ander: laten knallen.
	for e in _room.enemies:
		if not e.alive:
			continue
		var mark = combat.mark_on(e)
		if mark == null or mark.setter == me:
			continue
		var d: float = absf(e.position.x - b.position.x)
		if d < best_d:
			best = e
			best_d = d
	if best != null:
		return best
	# (2) geen merk: merk zetten, maar niet het doel waar de ander op afgaat.
	var taken: Node2D = null
	var o := _other(s)
	if _body(o) != null and o.step == s.step:
		taken = _unmarked_nearest(_body(o), null)
		if taken != null and absf(taken.position.x - _body(o).position.x) > absf(taken.position.x - b.position.x):
			taken = null  # ik ben dichterbij: dan is hij voor mij
	return _unmarked_nearest(b, taken)


func _unmarked_nearest(from: Node2D, skip: Node2D) -> Node2D:
	var best: Node2D = null
	var best_d := INF
	for e in _room.enemies:
		if not e.alive or e == skip or _room.sim.combat.mark_on(e) != null:
			continue
		var d: float = absf(e.position.x - from.position.x)
		if d < best_d:
			best = e
			best_d = d
	return best


func _arena_done() -> bool:
	if _room.wave < 2:
		return false
	for e in _room.enemies:
		if e.alive:
			return false
	return true


## Niets te slaan: meelopen met de ander, of (vóór de golf) heen en weer bij
## de ingang, zodat niemand stilstaat.
func _wait_in_k2(s: Seat) -> int:
	var b := _body(s)
	var o := _body(_other(s))
	if _room.wave == 0 or o == null or Layout.room_of(o.position) != "K2":
		if b.position.x <= Layout.K2_LEFT + 30.0:
			s.patrol_dir = 1
		elif b.position.x >= Layout.K2_LEFT + 110.0:
			s.patrol_dir = -1
		return _walk(s.patrol_dir)
	return _follow(s)


## `FOLLOW_PX` achter de ander; stil als je daar bent.
func _follow(s: Seat) -> int:
	var b := _body(s)
	var o := _body(_other(s))
	var goal: float = o.position.x - FOLLOW_PX * float(o.motor.facing)
	var dx := goal - b.position.x
	if absf(dx) < 6.0:
		return 0
	return R if dx > 0.0 else L


## K3 (LM-03): naar een kant van het pomprad, pompen tot het gemaal vol is of
## de meter leeg; dan naar de sluis (P2 loopt achter P1 aan). Is de meter leeg
## en het gemaal niet vol, dan de trap op naar K2 voor meer licht.
func _gemaal(s: Seat) -> int:
	var b := _body(s)
	var g = _room.gemaal
	if Layout.room_of(b.position) == "K2" and s.sub == "climb":
		s.step = STEPS.size() - 2
		s.sub = ""
		s.pump_x = NAN
		return 0
	if g.full_tick >= 0:
		if s.index == 2:
			return _follow(s)
		# Naar de sluis; wachten aan de waterkant zolang het water hoog staat.
		if b.motor.on_floor and g.in_deep_water(Vector2(b.position.x - 12.0, b.position.y), _tick):
			return 0
		return L
	match s.sub:
		"":
			if not _on_level(s, Layout.FLOOR):
				# Van de onderste trede aflopen en dan recht naar beneden vallen.
				return L if b.motor.on_floor else 0
			if is_nan(s.pump_x):
				var o := _other(s)
				var left_taken: bool = o.step == s.step and o.pump_x == PUMP_LEFT_X
				s.pump_x = PUMP_RIGHT_X if left_taken else PUMP_LEFT_X
			var go := _go_to(s, s.pump_x)
			if go != 0:
				return go
			s.sub = "pump"
			return 0
		"pump":
			if int(_room.meter.value) <= 0:
				s.sub = "climb"
				return R
			var face := 1 if s.pump_x < Layout.POMPRAD_AT.x else -1
			if b.motor.facing != face:
				return _walk(face)
			if _tick - s.last_attack >= ATTACK_EVERY:
				s.last_attack = _tick
				return _tap(s, A)
			return 0
		"climb":
			if s.index == 2:
				return _follow(s)
			return _climb(s)
	return 0


## De trap op naar het gat in K2 (K3 → K2), zoals de solo-bot.
func _climb(s: Seat) -> int:
	var b := _body(s)
	var stairs: Array = Layout.STAIRS
	var on := -1
	for i in stairs.size():
		if _on_level(s, (stairs[i] as Rect2).position.y):
			on = i
	if on == -1 and _on_level(s, Layout.FLOOR):
		s.from_tread = false
		var first: Rect2 = stairs[0]
		var go := _go_to(s, first.get_center().x)
		if go != 0:
			return go
		return _tap(s, J)
	if on >= 0:
		s.from_tread = true
		var stair: Rect2 = stairs[on]
		if b.position.x > stair.position.x + 20.0:
			return L
		return L | _tap(s, J)
	return L if s.from_tread else 0
