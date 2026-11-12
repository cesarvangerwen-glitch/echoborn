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
## - **K3 pompen** (LM-03, LM-04): P1 en P2 lopen door de pompgang en slaan
##   elk elke schoep één keer in het voorbijlopen.
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
## "lift" = de drager wacht rond `spot` op niveau `level` (± `PATROL_PX`, onder
## het open (eenrichtings) deel van `next` en niet onder een trede); de
## springer bounct naar `next`; de drager neemt daarna de langzame lijn vanaf
## de trede op `tread` (x, bovenkant): `steps` treden van `rise` px op
## (B3: 1 trede van 35; B1 en B2: 2, de treden op 30 en 60, gdd §4.3 v0.8,
## W-8), van de bovenste schuin in richting `dir` naar `next`.
## "omkeer" = de opstap aan het eind van de startgang (geen bouwsteen).
const STEPS := [
	["B4", "launch", 2, {}],
	["Omkeer", "omkeer", 0, {}],
	["B3", "lift", 1, {"level": Layout.FLOOR, "next": Layout.LEVEL_540, "spot": 260.0,
		"tread": [Layout.B3_GALLERY_TIP + 20.0, Layout.FLOOR - 35.0], "steps": 1, "rise": 35.0, "dir": -1}],
	["B1", "lift", 2, {"level": Layout.LEVEL_540, "next": Layout.LEVEL_450, "spot": 240.0,
		"tread": [Layout.COLUMN_LEFT + 16.0, Layout.LEVEL_540 - 30.0], "steps": 2, "rise": 30.0, "dir": 1}],
	["B2-0", "lift", 1, {"level": Layout.LEVEL_450, "next": 360.0, "spot": 310.0,
		"tread": [Layout.COLUMN_RIGHT - 16.0, Layout.LEVEL_450 - 30.0], "steps": 2, "rise": 30.0, "dir": -1}],
	["B2-1", "lift", 2, {"level": 360.0, "next": 270.0, "spot": 210.0,
		"tread": [Layout.COLUMN_LEFT + 16.0, 360.0 - 30.0], "steps": 2, "rise": 30.0, "dir": 1}],
	["B2-2", "lift", 1, {"level": 270.0, "next": 180.0, "spot": 310.0,
		"tread": [Layout.COLUMN_RIGHT - 16.0, 270.0 - 30.0], "steps": 2, "rise": 30.0, "dir": -1}],
	["B2-3", "lift", 2, {"level": 180.0, "next": 90.0, "spot": 210.0,
		"tread": [Layout.COLUMN_LEFT + 16.0, 180.0 - 30.0], "steps": 2, "rise": 30.0, "dir": 1}],
	["Bovenroute", "top", 0, {}],
	["K2", "arena", 0, {}],
	["K3", "gemaal", 0, {}],
]

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
	var off_ledge := false
	var last_attack := -1000
	var patrol_dir := 1
	## K3: looprichting in de pompgang en de geslagen schoepen van deze doorgang.
	var pass_dir := -1
	var struck := {}
	var climb_up := false
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
	s.off_ledge = false


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
		"omkeer":
			return _omkeer(s)
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
	if b.position.x < Layout.B4_FAR_EDGE - 20.0 and (_on_level(s, Layout.FLOOR) or _on_level(s, Layout.STARTGANG)):
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


## Omkeren: de startgang naar links tot onder de opstap, er recht op springen.
func _omkeer(s: Seat) -> int:
	var b := _body(s)
	if _on_level(s, Layout.FLOOR) and b.position.x < Layout.B3_ENTRANCE:
		_next_step(s)
		return R
	if _on_level(s, Layout.STARTGANG):
		if b.position.x > Layout.B3_ENTRANCE - 10.0:
			return L
		return _tap(s, J)
	return L if b.motor.on_floor or (b.motor.velocity.y >= 0.0 and b.position.x > Layout.B3_ENTRANCE - 10.0) else 0


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
	# Op het volgende niveau, niet op een trede die even hoog ligt (B1, B2).
	var tread: Array = args["tread"]
	if _on_level(s, next) and (int(args["steps"]) == 1 or absf(b.position.x - float(tread[0])) > Layout.KEERZONE):
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
		return _slow_tread(s, level, tread, int(args["steps"]), args["dir"], float(args["rise"]))
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


## Langzame lijn van de drager: naar de trede, `steps` keer recht omhoog
## springen (trede op trede, `rise` px per trede), en van de bovenste schuin in
## richting `dir` naar het volgende niveau (B3: van de trede af springen; B1,
## B2: van de trede op 60 naar de weg omhoog, vanaf de buitenrand van de trede).
func _slow_tread(s: Seat, level: float, tread: Array, steps: int, dir: int, rise: float) -> int:
	var tx: float = tread[0]
	var top: float = tread[1]
	var b := _body(s)
	for i in steps:
		if _on_level(s, top - rise * i):
			s.from_tread = true
			if i < steps - 1:
				return _tap(s, J)
			if steps > 1:
				# Eerst naar de buitenrand van de trede (B1, B2), dan schuin omhoog.
				var edge := tx + dir * 20.0
				if (edge - b.position.x) * dir > 2.0:
					return _walk(dir)
			s.off_ledge = true
			return _walk(dir) | _tap(s, J)
	if _on_level(s, level):
		s.from_tread = false
		s.off_ledge = false
		var go := _go_to(s, tx)
		if go != 0:
			return go
		return _tap(s, J)
	if s.off_ledge or (steps == 1 and s.from_tread):
		return _walk(dir)
	return 0


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


## K3 pompgang (LM-03, LM-04, FK-5, W-4): op de vloer naar links door de
## pompgang; elk lichaam slaat elke schoep één keer in het voorbijlopen. Is
## het gemaal vol, dan naar de sluis (P2 loopt achter P1 aan). Niet vol en nog
## licht in de meter: keren en de schoepen op de terugweg nog eens slaan; de
## meter leeg: de trap op naar K2 voor meer licht.
func _gemaal(s: Seat) -> int:
	var b := _body(s)
	var g = _room.gemaal
	if Layout.room_of(b.position) == "K2" and s.sub == "climb":
		s.step = STEPS.size() - 2
		s.sub = ""
		return 0
	if g.full_tick >= 0 and s.sub != "climb":
		if s.index == 2:
			return _follow(s)
		return L
	match s.sub:
		"":
			if not b.motor.on_floor:
				# Door het gat: recht naar beneden vallen.
				return 0
			if not _on_level(s, Layout.FLOOR):
				# Op een trede beland: naar rechts eraf (links hangt de wand van het gemaalhuis).
				return R
			s.sub = "gang"
			s.pass_dir = -1
			s.struck = {}
			return L
		"gang":
			var bits := _walk(s.pass_dir) | _pump_bits(s)
			if _past_gang(s):
				if int(_room.meter.value) <= 0:
					s.sub = "climb"
					return R
				s.pass_dir = -s.pass_dir
				s.struck = {}
			return bits
		"climb":
			if s.index == 2:
				return _follow(s)
			return _climb(s)
	return 0


## Een slag als een schoep in de looprichting binnen bereik ligt en dit lichaam
## hem in deze doorgang nog niet sloeg (zoals `flow_bot.gd`).
func _pump_bits(s: Seat) -> int:
	var b := _body(s)
	if _tick - s.last_attack < ATTACK_EVERY:
		return 0
	var vanes: Array = Layout.PUMP_VANES
	for i in vanes.size():
		if s.struck.has(i):
			continue
		var ahead: float = ((vanes[i] as Vector2).x - b.position.x) * float(b.motor.facing)
		if ahead >= -6.0 and ahead <= 36.0 and b.motor.facing == s.pass_dir:
			s.struck[i] = true
			s.last_attack = _tick
			return _tap(s, A)
	return 0


func _past_gang(s: Seat) -> bool:
	var x := _body(s).position.x
	var vanes: Array = Layout.PUMP_VANES
	if s.pass_dir < 0:
		return x < (vanes[vanes.size() - 1] as Vector2).x - 10.0
	return x > (vanes[0] as Vector2).x + 10.0


## De trap op naar het gat in K2 (K3 → K2), zoals de solo-bot.
func _climb(s: Seat) -> int:
	var b := _body(s)
	var stairs: Array = Layout.STAIRS
	var top: Rect2 = stairs[stairs.size() - 1]
	var on := -1
	for i in stairs.size():
		var st: Rect2 = stairs[i]
		if _on_level(s, st.position.y) and b.position.x > st.position.x - 8.0 and b.position.x < st.end.x + 8.0:
			on = i
	if on == -1 and _on_level(s, Layout.FLOOR):
		s.from_tread = false
		s.climb_up = false
		var go := _go_to(s, (stairs[0] as Rect2).get_center().x)
		if go != 0:
			return go
		return _tap(s, J)
	if on == stairs.size() - 1:
		s.climb_up = true
		var go := _go_to(s, top.position.x + 12.0)
		if go != 0:
			return go
		return _tap(s, J)
	if on >= 0:
		s.from_tread = true
		var stair: Rect2 = stairs[on]
		if b.position.x > stair.position.x + 4.0:
			return L
		return L | _tap(s, J)
	if s.climb_up:
		return L if b.position.y + Layout.HALF_H < Layout.K2_FLOOR - 1.0 else 0
	return L if s.from_tread else 0
