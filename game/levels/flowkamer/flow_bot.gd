extends RefCounted
## De gescripte geoefende run door de flow-kamer (gdd §4.5, §4.6 L-02, FK-2).
##
## Een inputbron (`sample(tick) -> int`, zoals ScriptedInput) die per tick
## kijkt waar P1 en zijn echo staan en daarop de knoppen kiest. Hij gebruikt
## alleen wat een speler ziet (posities, de echo, de vijanden, de meter);
## dezelfde kamer en dezelfde D geven dus altijd dezelfde input en hetzelfde
## meetlog. `recorded` houdt de bits per tick bij: afgespeeld met een
## `ScriptedInput` geven ze precies dezelfde run (test_flowkamer).
##
## Werkaanname (WLD): de "scripted geoefende run" van §4.5 is deze bot, geen
## vaste lijst bits; een vaste lijst zou bij elke maatwijziging van de kamer
## opnieuw moeten. De bot neemt in elke bouwsteen de echolijn als de echo er
## is, anders de langzame lijn (met echo uit: altijd de langzame lijn, FK-2).
## In B4 is de echolijn de lancering (C-11, gdd §4.3, #125).

const InputBits = preload("res://scripts/input/input_bits.gd")
const Motor = preload("res://scripts/echo/motor.gd")
const Layout = preload("res://levels/flowkamer/flow_layout.gd")

const L := InputBits.LEFT
const R := InputBits.RIGHT
const J := InputBits.JUMP
const A := InputBits.ATTACK
const DASH := InputBits.DASH

## Afstand tot de echo waarop P1 bij keren afzet (gdd §4.3: ± 130 px).
const JUMP_ON_ECHO_PX := 130.0
## Bij hoeveel px achterstand op de echo P1 opgeeft en de langzame lijn neemt.
const GIVE_UP_PX := 260.0
## B4: hier staat P1 (en D ticks later zijn echo) aan de rand in houding
## (gdd §4.3: de drager ≤ 8 px van de rand).
const B4_STANCE_X := Layout.B4_NEAR_EDGE + 2.0
## B4: zo lang houdt P1 AANVAL vast (gdd §4.3: ≥ 30 ticks).
const B4_HOLD_TICKS := 32
## B4: P1 springt als zijn echo nog zo ver van hem is. De echo loopt 2 px/tick
## en staat dan 12 ticks later stil op `B4_STANCE_X`, in houding van 12 tot
## 32 ticks na zijn slag; de landing komt ± 33 ticks na de afzet, dus midden
## in dat venster (gdd §4.3: afzet op T + D − 21 … T + D − 3). Zo kijkt de bot
## naar de echo, niet naar de klok, en werkt het voor elke D.
const B4_JUMP_AT_ECHO_PX := 24.0
## B4: zo lang wacht P1 op de echo; daarna de langzame lijn.
const B4_GIVE_UP_TICKS := 300

## De bits per tick van deze run, vanaf de eerste `sample`.
var recorded := PackedInt32Array()
## Welke bouwstenen de echolijn haalden (naam -> true) of de langzame lijn (false).
var lines := {}
## Huidige stap, voor debug en tests.
var leg := 0
var sub := ""

var _room: Node
var _prev := 0
var _last_x := INF
var _stuck := 0
var _turn_x := 0.0
var _since := 0
var _last_attack := -1000
var _pump_strokes := 0
var _patrol_dir := 1
var _tick := 0
var _from_tread := false
var _needed := 0
var _echo_now_x := NAN
var _echo_last_x := NAN
var _echo_base := 0

## De route: [naam, soort, parameters]. "turn" = keren en op de echo bouncen
## (B1, B2): [niveau-y, richting heen, volgend niveau-y, richting langzame lijn].
var _legs := [
	["B4", "b4", []],
	["B3", "b3", []],
	["B1", "turn", [Layout.LEVEL_540, 1, Layout.LEVEL_450, 1]],
	["B2-0", "turn", [Layout.LEVEL_450, 1, Layout.LEDGES[0], -1]],
	["B2-1", "turn", [Layout.LEDGES[0], -1, Layout.LEDGES[1], 1]],
	["B2-2", "turn", [Layout.LEDGES[1], 1, Layout.LEDGES[2], -1]],
	["B2-3", "turn", [Layout.LEDGES[2], -1, Layout.LEDGES[3], 1]],
	["Bovenroute", "top", []],
	["K2", "arena", []],
	["K3", "gemaal", []],
]


func _init(room: Node) -> void:
	_room = room


func sample(tick: int) -> int:
	_tick = tick
	var bits := _decide()
	# Een knop die vorige tick al vast was, geeft geen nieuwe flank: laat hem
	# één tick los als de bot een nieuwe sprong, slag of dash wil.
	recorded.append(bits)
	_prev = bits
	return bits


# --- Hulpjes ---

func _p1() -> CharacterBody2D:
	return _room.p1


func _echo_ready() -> bool:
	var e = _room.echo
	return e != null and is_instance_valid(e) and e.is_present() and not e.in_merksprong


func _on_level(level_top: float) -> bool:
	var p := _p1()
	return p.motor.on_floor and p.motor.support != Motor.Support.SHADOW_BODY \
		and absf(p.position.y - (level_top - Layout.HALF_H)) < 1.5


## Loopt P1 op dit niveau tegen een wand (geen voortgang op x)? Tegen een
## wand is `on_floor` soms false, daarom alleen op de hoogte.
func _against_wall(level_top: float) -> bool:
	return _stuck >= 1 and absf(_p1().position.y - (level_top - Layout.HALF_H)) < 1.5


func _on_plank() -> bool:
	return _p1().motor.on_floor and _p1().motor.support == Motor.Support.SHADOW_BODY


## Een nieuwe flank van `bit` (los als hij vorige tick al vast was).
func _tap(bit: int) -> int:
	return 0 if _prev & bit else bit


func _walk(dir: int) -> int:
	return R if dir > 0 else L


## Telt ticks zonder voortgang op x (tegen een wand of trede).
func _update_stuck() -> void:
	var x := _p1().position.x
	if absf(x - _last_x) < 0.5:
		_stuck += 1
	else:
		_stuck = 0
	_last_x = x


func _next_leg(echo_line: bool) -> void:
	lines[_legs[leg][0]] = echo_line
	leg += 1
	sub = ""
	_since = 0
	_stuck = 0
	_last_x = INF


# --- Beslissing per tick ---

func _decide() -> int:
	_update_stuck()
	_since += 1
	var echo_x := _echo_now_x
	_echo_now_x = _room.echo.position.x if _echo_ready() else NAN
	_echo_last_x = echo_x if not is_nan(echo_x) else _echo_now_x
	if leg >= _legs.size():
		return 0
	var spec: Array = _legs[leg]
	match spec[1]:
		"b4":
			return _leg_b4()
		"b3":
			return _leg_b3()
		"turn":
			return _leg_turn(spec[2])
		"top":
			return _leg_top()
		"arena":
			return _leg_arena()
		"gemaal":
			return _leg_gemaal()
	return 0


## B4 lanceerkloof (gdd §4.3, C-11). Echolijn: naar de rand, slaan en
## AANVAL vasthouden met het gezicht naar de kloof; de echo loopt D ticks
## later onder je in en staat dan in houding. Spring als hij er bijna is: je
## landt op hem en vliegt over. Zonder echo, of als het mislukt: de langzame
## lijn (de kloof in, 160 px lopen, twee treden op).
func _leg_b4() -> int:
	var p := _p1()
	if p.position.x < Layout.B4_FAR_EDGE - 20.0 and _on_level(Layout.FLOOR):
		_next_leg(sub == "launched")
		return L
	match sub:
		"":
			if not _room.echo_on or _room.echo == null:
				sub = "slow"
				return L
			if p.position.x > B4_STANCE_X:
				return L
			sub = "stance"
			_since = 0
			return _tap(A)
		"stance":
			if _since < B4_HOLD_TICKS:
				return A
			sub = "wait"
			_since = 0
			return 0
		"wait":
			if _echo_ready():
				var dx: float = _room.echo.position.x - p.position.x
				if dx >= 0.0 and dx <= B4_JUMP_AT_ECHO_PX:
					sub = "air"
					_since = 0
					return _tap(J)
			if not _room.echo_on or _since > B4_GIVE_UP_TICKS:
				sub = "slow"
				return L
			return 0
		"air":
			if p.motor.launch_pending or p.motor.launch_left > 0:
				sub = "launched"
				return L
			if _since > 60 or (_since > 2 and _on_level(Layout.FLOOR)):
				sub = "slow"
				return L
			return 0
		"launched":
			# Na de lanceerstaat bepaalt LEFT weer v.x: blijf links houden.
			if _on_level(Layout.KLOOF_BOTTOM):
				sub = "slow"
			return L
	return _slow_b4()


## B4, langzame lijn: de kloof in, 160 px lopen, twee treden op.
func _slow_b4() -> int:
	var p := _p1()
	if _stuck >= 1:
		# Tegen de trede: één tick loslaten, anders is P1 niet `on_floor` en
		# springt hij niet (bevinding voor de Gameplay Programmer, zie kamerdoc).
		if p.motor.on_floor:
			return L | _tap(J)
		if absf(p.motor.velocity.y) < 0.3:
			return 0
	return L


## B3 lus: door de kom, op het blok, keren, terug op de echo en bouncen naar
## de galerij. Mis je de echo: langzame lijn via de trede van 35 px.
func _leg_b3() -> int:
	var p := _p1()
	if _on_level(Layout.LEVEL_540):
		_next_leg(sub == "bounce")
		return R
	match sub:
		"":
			if _on_level(Layout.FLOOR) and p.position.x <= 185.0:
				sub = "to_block"
				return L | _tap(J)
			return L
		"to_block":
			if _against_wall(Layout.FLOOR - 45.0):
				sub = "back"
				_since = 0
				return R
			if _on_level(Layout.FLOOR) and _stuck >= 2:
				sub = "slow"
			return L
		"back":
			# Op het blok terug naar de rand; daar afspringen zodra de echo
			# zo ver de kom in is dat je op hem landt (gdd §4.3: 29–49 ticks
			# na de rand, echo 99–146 px van de ingang).
			if _on_level(Layout.FLOOR - 45.0) and p.position.x >= Layout.B3_BLOCK_RIGHT - 10.0:
				var e = _room.echo
				if _echo_ready() and e.position.x <= Layout.B3_ENTRANCE + 60.0:
					sub = "off_block"
					return R | _tap(J)
				if _since > 400 or not _room.echo_on:
					sub = "off_block"
					return R | _tap(J)
				return 0
			return R
		"off_block":
			# Snel vallen op de echo is een vang (C-13): de zwiep gaat omhoog als een bounce.
			if p.move_events & Motor.EV_CATCH:
				sub = "bounce"
				_since = 0
				return R
			if _on_plank():
				sub = "bounce"
				_since = 0
				return R | _tap(J)
			if _on_level(Layout.FLOOR):
				sub = "slow"
				return 0
			# In de lucht naar de echo sturen.
			if _echo_ready() and p.motor.velocity.y > 0.0:
				var ex: float = _room.echo.position.x
				if ex > p.position.x + 2.0:
					return R
				if ex < p.position.x - 2.0:
					return L
				return 0
			return R
		"bounce":
			if _on_level(Layout.FLOOR):
				sub = "slow"
				return 0
			# Met de teruggekregen dash haal je de galerij altijd (gdd §4.3).
			if _since == 14 and p.position.x < Layout.B3_GALLERY_TIP - 4.0:
				return R | _tap(DASH)
			return R
		"slow":
			return _slow_b3()
	return 0


func _slow_b3() -> int:
	var p := _p1()
	var tread_top := Layout.FLOOR - 35.0
	if _on_level(tread_top):
		_from_tread = true
		return R | _tap(J)
	if _on_level(Layout.FLOOR):
		_from_tread = false
		var target := Layout.B3_GALLERY_TIP - 20.0
		if absf(p.position.x - target) <= 2.0:
			return _tap(J)
		return R if p.position.x < target else L
	return R if _from_tread else 0


## B1 en een verdieping van B2: heen naar de wand, keren, op de echo springen
## als hij ± 130 px vóór je is, bouncen naar het volgende niveau. Zonder echo
## (of gemist): de langzame lijn over de trede van 45 px tegen de wand.
func _leg_turn(args: Array) -> int:
	var level: float = args[0]
	var out_dir: int = args[1]
	var next_level: float = args[2]
	var slow_dir: int = args[3]
	var p := _p1()
	if _on_level(next_level):
		_next_leg(sub == "bounce")
		return 0
	match sub:
		"":
			if _against_wall(level):
				_turn_x = p.position.x
				sub = "back" if _room.echo_on else "slow"
				return _walk(-out_dir)
			return _walk(out_dir)
		"back":
			if not _on_level(level):
				return _walk(-out_dir)
			if absf(p.position.x - _turn_x) > GIVE_UP_PX:
				sub = "slow"
				return _walk(out_dir)
			if _echo_ready():
				var e: Node2D = _room.echo
				var ahead := (e.position.x - p.position.x) * -out_dir
				if absf(e.position.y - p.position.y) < 1.5 and ahead > 0.0 and ahead <= JUMP_ON_ECHO_PX:
					sub = "air"
					_since = 0
					return _walk(-out_dir) | _tap(J)
			return _walk(-out_dir)
		"air":
			if _on_plank():
				sub = "bounce"
				return _walk(-out_dir) | _tap(J)
			if _on_level(level):
				sub = "slow"
				return _walk(out_dir)
			return _steer_to_echo(-out_dir)
		"bounce":
			if _on_level(level):
				sub = "slow"
			return _walk(-out_dir)
		"slow":
			return _slow_turn(level, out_dir, slow_dir)
	return 0


## In de lucht naar de echo sturen: hij komt je tegemoet (2 px/tick), dus
## soms even niets of terug. Zonder echo: `fallback`.
func _steer_to_echo(fallback: int) -> int:
	if not _echo_ready():
		return _walk(fallback)
	var p := _p1()
	var e: Node2D = _room.echo
	# Waar staat de echo als P1 op zijn hoogte terug is? Zo ver vooruit kijken.
	var ticks_left := 33.0 - minf(_since, 33.0)
	var meet: float = e.position.x + (e.position.x - _echo_last_x) * ticks_left
	if meet > p.position.x + 2.0:
		return R
	if meet < p.position.x - 2.0:
		return L
	return 0


## Langzame lijn: onder de trede (40 px tegen de wand) recht omhoog springen,
## dan vanaf de trede naar het volgende niveau.
func _slow_turn(level: float, out_dir: int, slow_dir: int) -> int:
	var p := _p1()
	if _on_level(level - 45.0):
		_from_tread = true
		return _walk(slow_dir) | _tap(J)
	if _on_level(level):
		_from_tread = false
		if _turn_x == 0.0:
			return _walk(out_dir)
		var tread_x := _turn_x - out_dir * (Layout.TREAD_W * 0.5 - 8.0)
		if absf(p.position.x - tread_x) <= 2.0:
			return _tap(J)
		return _walk(1 if tread_x > p.position.x else -1)
	return _walk(slow_dir) if _from_tread else 0


## Bovenroute naar K2.
func _leg_top() -> int:
	if _room.room == "K2":
		_next_leg(false)
		return 0
	return R


## K2: elke vijand zonder merk één keer slaan (merk), doorlopen; de echo laat
## het merk D ticks later knallen (E-14, E-02m). Het pantserdoel ook: de
## eerste knal breekt het pantser, de tweede ronde maakt het af. Daarna door
## het gat naar K3.
func _leg_arena() -> int:
	var p := _p1()
	if _room.room == "K3":
		_next_leg(false)
		return L
	var target := _arena_target()
	if target == null and _arena_done():
		# Naar het gat rechts.
		return R
	if target == null:
		return _patrol()
	# Slaan als het doel 4–32 px vóór P1 staat (aanvalsvlak 8–28 px, doel
	# 16 px breed). Te dichtbij: eerst afstand nemen, dan teruglopen (zo kijkt
	# P1 altijd naar het doel als hij aankomt).
	var dx: float = target.position.x - p.position.x
	var rel: float = dx * p.motor.facing
	if rel >= 4.0 and rel <= 32.0 and absf(target.position.y - p.position.y) < 20.0:
		if _tick - _last_attack >= 21:
			_last_attack = _tick
			return _tap(A)
		return 0
	if absf(dx) <= 14.0:
		var away := -1 if dx > 0.0 else 1
		if p.position.x + away * 20.0 < Layout.K2_LEFT + 10.0 or p.position.x + away * 20.0 > Layout.K2_HOLE.position.x - 10.0:
			away = -away
		return _walk(away)
	return _walk(1 if dx > 0.0 else -1)


## Het dichtstbijzijnde levende doel zonder merk. Met echo uit: elke levende
## basisvijand (P1 slaat hem drie keer); een intact pantser breekt zonder
## echo niet (E-14g) en telt niet mee voor het einde van de golf.
func _arena_target() -> Node2D:
	var p := _p1()
	var best: Node2D = null
	var best_d := INF
	for e in _room.enemies:
		if not e.alive:
			continue
		if _room.echo_on:
			if _room.sim.combat.mark_on(e) != null:
				continue
		elif e.armor_intact:
			continue
		var d: float = absf(e.position.x - p.position.x)
		if d < best_d:
			best = e
			best_d = d
	return best


func _arena_done() -> bool:
	if _room.wave < 2:
		return false
	for e in _room.enemies:
		if e.alive and not (e.armor_intact and not _room.echo_on):
			return false
	return true


## Wachten op de echo zonder stil te staan: heen en weer, weg van vijanden.
func _patrol() -> int:
	var p := _p1()
	if p.position.x <= Layout.K2_LEFT + 40.0:
		_patrol_dir = 1
	elif p.position.x >= Layout.K2_HOLE.position.x - 40.0:
		_patrol_dir = -1
	return _walk(_patrol_dir)


## K3: naar het pomprad, pompen (de helft van de slagen; de echo herhaalt
## ze D ticks later), dan naar de sluis. Is het gemaal daarna niet vol, dan
## de trap op terug naar K2 voor meer licht (met echo uit: FK-2).
func _leg_gemaal() -> int:
	var p := _p1()
	var g = _room.gemaal
	if _room.run_over:
		return 0
	if _room.room == "K2":
		leg = _legs.size() - 2
		sub = ""
		return 0
	if g.full_tick >= 0 and sub != "pump":
		# Naar de sluis; wachten aan de waterkant zolang het water hoog staat.
		if p.motor.on_floor and g.in_deep_water(Vector2(p.position.x - 12.0, p.position.y), _tick):
			return 0
		return L
	match sub:
		"":
			if not _on_level(Layout.FLOOR):
				# Van de onderste trede aflopen en dan recht naar beneden vallen.
				return L if p.motor.on_floor else 0
			var dir := _pump_side()
			if dir == 0:
				return R if p.position.x < Layout.POMPRAD_AT.x else L
			sub = "pump"
			_pump_strokes = 0
			_needed = _strokes_needed()
			_echo_base = int(g.strokes.get("echo", 0))
			return 0
		"pump":
			if _pump_strokes < _needed:
				var side := _pump_side()
				if side == 0:
					return R if p.position.x < Layout.POMPRAD_AT.x else L
				if p.motor.facing != side:
					return _walk(side)
				if _tick - _last_attack >= 21:
					_last_attack = _tick
					_pump_strokes += 1
					return _tap(A)
				return 0
			sub = "wait" if _will_fill() else "climb"
			return L if sub == "wait" else R
		"wait":
			# Niet het water in zolang het gemaal niet vol is (Diepwater zet je terug).
			if p.motor.on_floor and g.in_deep_water(Vector2(p.position.x - 12.0, p.position.y), _tick):
				return 0
			return L
		"climb":
			return _climb()
	return 0


## Kant waarnaar P1 moet kijken om het pomprad te raken (0 = buiten bereik).
## Aanvalsvlak 8–28 px vóór het lichaam, pomprad 32 px breed.
func _pump_side() -> int:
	var dx := _p1().position.x - Layout.POMPRAD_AT.x
	if dx >= -6.0 and dx <= 42.0:
		return -1
	if dx >= -42.0 and dx < -6.0:
		return 1
	return 0


## Hoeveel slagen P1 zelf doet: met echo de helft van wat nodig is (de echo
## herhaalt elke slag), met echo uit alles.
func _strokes_needed() -> int:
	var g = _room.gemaal
	var useful := mini(100 - int(g.fill), int(_room.meter.value))
	var total := int(ceil(useful / 10.0))
	if _room.echo_on:
		return int(ceil(total / 2.0))
	return total


## Maakt de echo het gemaal vol met de slagen die hij nog herhaalt?
func _will_fill() -> bool:
	var g = _room.gemaal
	if g.full_tick >= 0:
		return true
	if not _room.echo_on:
		return false
	var pending := _pump_strokes - (int(g.strokes.get("echo", 0)) - _echo_base)
	return int(g.fill) + mini(pending * 10, int(_room.meter.value)) >= 100


## De trap op naar het gat in K2 (K3 → K2).
func _climb() -> int:
	var p := _p1()
	var stairs: Array = Layout.STAIRS
	# Op welke trede staat P1 (index), of -1 = vloer.
	var on := -1
	for i in stairs.size():
		if _on_level((stairs[i] as Rect2).position.y):
			on = i
	if on == -1 and _on_level(Layout.FLOOR):
		_from_tread = false
		var first: Rect2 = stairs[0]
		var x := first.get_center().x
		if absf(p.position.x - x) <= 2.0:
			return _tap(J)
		return R if p.position.x < x else L
	if on >= 0:
		# Eerst naar de linkerkant van de trede, dan springen (zo land je op de volgende).
		_from_tread = true
		var stair: Rect2 = stairs[on]
		if p.position.x > stair.position.x + 20.0:
			return L
		return L | _tap(J)
	# In de lucht: alleen naar links sturen na een sprong vanaf een trede.
	return L if _from_tread else 0
