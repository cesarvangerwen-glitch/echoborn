extends RefCounted
## De gescripte geoefende run door de Kadewijk, deel 1 (S1–S4; gdd §4.5,
## L-08, FK-2, C-15; T8a #83).
##
## Een inputbron (`sample(tick) -> int`) die per tick kijkt waar P1, zijn echo
## en de vijanden staan en daarop de knoppen kiest, zoals `flow_bot.gd` van de
## flow-kamer (daar komen de bouwstenen B1, B3 en B4 vandaan, gespiegeld waar
## nodig). Hij neemt de echolijn als de echo er is, anders de langzame lijn;
## met echo uit altijd de langzame lijn (FK-2, C-15). Deterministisch: dezelfde
## kamers en dezelfde D geven dezelfde input (`recorded`).
##
## Werkaanname (WLD): de "scripted geoefende run" van §4.5 is deze bot. Per
## kamer begint hij bij de eerste stap van die kamer (`start_room`), zodat
## de tests elke kamer los kunnen doorlopen.

const InputBits = preload("res://scripts/input/input_bits.gd")
const Motor = preload("res://scripts/echo/motor.gd")
const Layout = preload("res://levels/kadewijk/kadewijk_layout.gd")
const SliceEnemy = preload("res://scripts/combat/slice_enemy.gd")

const L := InputBits.LEFT
const R := InputBits.RIGHT
const J := InputBits.JUMP
const A := InputBits.ATTACK
const DASH := InputBits.DASH

const JUMP_ON_ECHO_PX := 130.0
const GIVE_UP_PX := 260.0
## B4 achter een keerpunt (#217): bij een lange staart springt de bot op de echo
## als die zo ver vóór hem is (hij landt erop vóór de houding begint).
const B4_RIDE_JUMP_PX := 70.0
const B4_GIVE_UP_TICKS := 300
## B4, late bot (#217): zo veel ticks later op de echo springen, en zo veel
## ticks na de top van de lancering dashen (0 = op de top, zoals de run).
var b4_jump_delay := 0
var b4_dash_delay := 0
## Gevecht: herhaaltijd van de slag (zoals K2).
const ATTACK_EVERY := 21

## De bits per tick van deze run.
var recorded := PackedInt32Array()
## Per bouwsteen: echolijn (true) of langzame lijn (false).
var lines := {}
## Per stap: de tick waarop hij klaar was.
var leg_done := {}
## Per keerpunt: de tick waarop P1 tegen de keerwand keerde.
var turned := {}
## Per keerpunt: afstand tot de keerwand bij de bounce en bij de landing (px).
var bounce_from_wall := {}
var landed_from_wall := {}
var leg := 0
var sub := ""

var _room: Node
var _d := 60
var _prev := 0
var _last_x := INF
var _stuck := 0
var _turn_x := 0.0
var _since := 0
var _last_attack := -1000
var _plank_ticks := 0
var _apex_tick := -1
var _patrol_dir := -1
var _tick := 0
var _from_tread := false
var _off_ledge := false
var _echo_now_x := NAN
var _echo_last_x := NAN
var _b4_waited := 0

## De route: [naam, soort, parameter].
var _legs := [
	["S1-B1", "turn", 0],
	["S1-kade", "walk", &"S2"],
	["S2-B3", "b3", null],
	["S2-paar", "fight", null],
	["S2-B1", "turn", 2],
	["S2-boven", "walk", &"S3"],
	["S3-markt", "arena", null],
	["S4-B4", "b4", null],
	["S4-overkant", "fight", null],
	["S4-eind", "end", null],
]


func _init(room: Node, d: int, start_room: StringName = &"S1") -> void:
	_room = room
	_d = d
	for i in _legs.size():
		if String(_legs[i][0]).begins_with(String(start_room)):
			leg = i
			break


func sample(tick: int) -> int:
	_tick = tick
	var bits := _decide()
	recorded.append(bits)
	_prev = bits
	return bits


## Naam van de stap van nu (of "" als de run klaar is).
func leg_name() -> String:
	return _legs[leg][0] if leg < _legs.size() else ""


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


func _against_wall(level_top: float) -> bool:
	return _stuck >= 1 and absf(_p1().position.y - (level_top - Layout.HALF_H)) < 1.5


func _on_plank() -> bool:
	return _p1().motor.on_floor and _p1().motor.support == Motor.Support.SHADOW_BODY


func _tap(bit: int) -> int:
	return 0 if _prev & bit else bit


func _walk(dir: int) -> int:
	return R if dir > 0 else L


func _update_stuck() -> void:
	var x := _p1().position.x
	if absf(x - _last_x) < 0.5:
		_stuck += 1
	else:
		_stuck = 0
	_last_x = x


func _next_leg(echo_line: bool) -> void:
	lines[_legs[leg][0]] = echo_line
	leg_done[_legs[leg][0]] = _tick
	leg += 1
	sub = ""
	_off_ledge = false
	_from_tread = false
	_since = 0
	_stuck = 0
	_last_x = INF


func _tp(i: int) -> Dictionary:
	return Layout.turn_points(_d)[i]


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
		"turn":
			return _leg_turn(_tp(spec[2]))
		"walk":
			if _room.room == spec[2]:
				_next_leg(false)
				return R
			return R
		"b3":
			return _leg_b3()
		"fight":
			return _leg_fight(false)
		"arena":
			return _leg_fight(true)
		"b4":
			return _leg_b4()
		"end":
			if _room.run_over:
				_next_leg(false)
				return 0
			return R
	return 0


## B1 (gdd §4.3): heen naar de wand, keren, op de echo springen als hij
## ± 130 px vóór je is (bij D = 60 op het keren), bouncen naar het volgende
## niveau. Zonder echo (of gemist): de langzame lijn over de treden.
func _leg_turn(tp: Dictionary) -> int:
	var level: float = tp["floor"]
	var out_dir: int = tp["side"]
	var next_level: float = tp["up"]
	var slow_dir: int = -out_dir
	var wall: float = tp["wall"]
	var name: String = tp["name"]
	var p := _p1()
	if _on_level(next_level) and absf(p.position.x - wall) > Layout.keerzone(_d):
		if sub == "bounce":
			landed_from_wall[name] = absf(p.position.x - wall)
		_next_leg(sub == "bounce")
		return 0
	match sub:
		"":
			if _against_wall(level):
				_turn_x = p.position.x
				turned[name] = _tick
				sub = "back" if _room.echo_on and _room.echo != null else "slow"
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
				_apex_tick = -1
				sub = "bounce"
				bounce_from_wall[name] = absf(p.position.x - wall)
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
			return _slow_turn(level, out_dir, slow_dir, wall)
	return 0


func _steer_to_echo(fallback: int) -> int:
	if not _echo_ready():
		return _walk(fallback)
	var p := _p1()
	var e: Node2D = _room.echo
	var ticks_left := 33.0 - minf(_since, 33.0)
	var meet: float = e.position.x + (e.position.x - _echo_last_x) * ticks_left
	if meet > p.position.x + 2.0:
		return R
	if meet < p.position.x - 2.0:
		return L
	return 0


## Langzame lijn (gdd §4.3, W-8; zoals de flow-kamer): onder de treden recht
## omhoog op 30, op 60, en van 60 schuin van de wand af naar de weg omhoog (of,
## bij een langere D, de trede op 90 af tot de galerij).
func _slow_turn(level: float, out_dir: int, slow_dir: int, wall: float) -> int:
	var p := _p1()
	var dist := absf(p.position.x - wall)
	if _on_level(level - 30.0):
		_from_tread = true
		_off_ledge = false
		return _tap(J)
	if _on_level(level - 60.0) or _on_level(level - 90.0):
		_from_tread = true
		_off_ledge = true
		return _walk(slow_dir) | _tap(J)
	if _on_level(level):
		_from_tread = false
		_off_ledge = false
		if _turn_x == 0.0:
			return _walk(out_dir)
		var tread_x := _turn_x - out_dir * (Layout.TREAD_W * 0.5 - 8.0)
		if absf(p.position.x - tread_x) <= 2.0:
			return _tap(J)
		return _walk(1 if tread_x > p.position.x else -1)
	if _off_ledge:
		return _walk(slow_dir)
	if _from_tread:
		return _walk(slow_dir) if dist < Layout.TREAD_W - 2.0 else 0
	return 0


## B3 (gdd §4.3): bij D = 60 een keerpunt (rechterwand), daarboven de galerij
## op 70 naar links; bij een langere D het blok van `max(D − 60, 0)`. Mis je de
## echo: de trede van 35 px bij de ingang.
func _leg_b3() -> int:
	var p := _p1()
	var wall := Layout.B3_BLOCK_LEFT
	var b := Layout.b3_width(_d)
	if _on_level(Layout.S2_MID):
		if sub == "bounce":
			landed_from_wall["S2-B3"] = Layout.B3_GALLERY_TIP - p.position.x
		_next_leg(sub == "bounce")
		return L
	if not _room.echo_on or _room.echo == null:
		if sub == "":
			if _against_wall(Layout.S2_FLOOR) or (_on_level(Layout.S2_FLOOR) and p.position.x >= wall - 8.5):
				turned["S2-B3"] = _tick
				sub = "slow"
				return L
			if b > 0.0 and _on_level(Layout.S2_FLOOR - 45.0):
				turned["S2-B3"] = _tick
				sub = "slow"
				return L
			return R
		return _slow_b3()
	if b <= 0.0:
		return _leg_b3_turn(wall)
	match sub:
		"":
			if _on_level(Layout.S2_FLOOR) and p.position.x >= wall - 45.0:
				sub = "to_block"
				return R | _tap(J)
			return R
		"to_block":
			if _against_wall(Layout.S2_FLOOR - 45.0):
				turned["S2-B3"] = _tick
				sub = "back"
				_since = 0
				return L
			if _on_level(Layout.S2_FLOOR) and _stuck >= 2:
				sub = "slow"
			return R
		"back":
			if _on_level(Layout.S2_FLOOR - 45.0) and p.position.x <= wall + 10.0:
				var e = _room.echo
				if _echo_ready() and absf(e.position.y - (Layout.S2_FLOOR - Layout.HALF_H)) < 1.5 \
						and e.position.x >= Layout.B3_ENTRANCE - 60.0 and e.position.x < wall:
					sub = "off_block"
					return L | _tap(J)
				if _since > 400:
					sub = "off_block"
					return L | _tap(J)
				return 0
			return L
		"off_block":
			if p.move_events & Motor.EV_CATCH:
				sub = "bounce"
				_since = 0
				_apex_tick = -1
				return L
			if _on_plank():
				sub = "bounce"
				_since = 0
				_apex_tick = -1
				return L | _tap(J)
			if _on_level(Layout.S2_FLOOR):
				sub = "slow"
				return 0
			if _echo_ready() and p.motor.velocity.y > 0.0:
				var ex: float = _room.echo.position.x
				if ex > p.position.x + 2.0:
					return R
				if ex < p.position.x - 2.0:
					return L
				return 0
			return L
		"bounce":
			if _on_level(Layout.S2_FLOOR):
				sub = "slow"
				return 0
			# Dash op de top, zoals bij D = 60 (#217, besluit B3-galerij: het
			# venster loopt van 14 tot ± 38 ticks na de bounce; op 14 bleef 2 px).
			if p.motor.velocity.y >= 0.0 and _apex_tick < 0:
				_apex_tick = _tick
				if p.position.x > Layout.B3_GALLERY_TIP + 4.0:
					return L | _tap(DASH)
			return L
		"slow":
			return _slow_b3()
	return 0


## B3 bij D = 60 (W-9 van de flow-kamer): naar de wand, keren en meteen
## springen, op de echo landen, bouncen en op de top dashen naar de galerij.
func _leg_b3_turn(wall: float) -> int:
	var p := _p1()
	match sub:
		"":
			if _against_wall(Layout.S2_FLOOR) or (_on_level(Layout.S2_FLOOR) and p.position.x >= wall - 8.5):
				turned["S2-B3"] = _tick
				_turn_x = p.position.x
				sub = "back"
				return L
			return R
		"back":
			if not _on_level(Layout.S2_FLOOR):
				return L
			if absf(p.position.x - _turn_x) > GIVE_UP_PX * 0.5:
				sub = "slow"
				return 0
			if _echo_ready():
				var e: Node2D = _room.echo
				var ahead: float = p.position.x - e.position.x
				if absf(e.position.y - p.position.y) < 1.5 and ahead > 0.0 and ahead <= JUMP_ON_ECHO_PX:
					sub = "air"
					_since = 0
					return L | _tap(J)
			return L
		"air":
			if _on_plank():
				_apex_tick = -1
				bounce_from_wall["S2-B3"] = absf(p.position.x - wall)
				sub = "bounce"
				_since = 0
				return L | _tap(J)
			if _since > 2 and _on_level(Layout.S2_FLOOR):
				sub = "slow"
				return 0
			return _steer_to_echo(-1)
		"bounce":
			if _on_level(Layout.S2_FLOOR):
				landed_from_wall["S2-B3"] = Layout.B3_GALLERY_TIP - p.position.x
				sub = "slow"
				return 0
			if p.motor.velocity.y >= 0.0 and _apex_tick < 0:
				_apex_tick = _tick
			if _apex_tick >= 0 and _tick == _apex_tick:
				return L | _tap(DASH)
			return L
		"slow":
			return _slow_b3()
	return 0


func _slow_b3() -> int:
	var p := _p1()
	var tread_top := Layout.S2_FLOOR - 35.0
	if _on_level(tread_top):
		_from_tread = true
		return L | _tap(J)
	if _on_level(Layout.S2_FLOOR - 45.0):
		# Op het blok (D ≥ 90, echo uit): eraf de kom in.
		return L
	if _on_level(Layout.S2_FLOOR):
		_from_tread = false
		var target := Layout.B3_GALLERY_TIP + 20.0
		if absf(p.position.x - target) <= 2.0:
			return _tap(J)
		return R if p.position.x < target else L
	return L if _from_tread else 0


## Gevecht (L-13; zoals K2): elke vijand zonder merk één keer slaan en
## doorlopen; de echo laat het merk D + 3 ticks later knallen. Zonder echo:
## slaan tot hij op is; een heel pantser breekt zonder echo niet (E-14g) en
## blokkeert de route niet (L-13 e). `arena` (S3): klaar als golf 2 meedeed
## en er niemand meer over is; anders klaar als er in de kamer niemand meer is.
func _leg_fight(arena: bool) -> int:
	var p := _p1()
	var here: StringName = _room.room
	var next_room: StringName = &"S4" if arena else &""
	if arena and here == next_room:
		_next_leg(false)
		return R
	if not p.motor.on_floor:
		return _walk(_patrol_dir) if sub == "patrol" else (L if here == &"S2" else R)
	var target := _target(here)
	# Op de route (niet de arena) loopt P1 door zodra elke vijand een merk heeft
	# of op is: de echo laat de merken achter hem knallen (E-02m).
	if not arena and target == null and _room.echo_on and _room.echo != null:
		_next_leg(false)
		return 0
	var done: bool = target == null and _no_enemies_left(here) and (not arena or _room.wave >= 2)
	if done:
		if not arena:
			_next_leg(false)
			return 0
		return R
	if target == null:
		sub = "patrol"
		return _patrol(here)
	sub = "hit"
	var dx: float = target.position.x - p.position.x
	var rel: float = dx * p.motor.facing
	if rel >= 4.0 and rel <= 32.0 and absf(target.position.y - p.position.y) < 20.0:
		if _tick - _last_attack >= ATTACK_EVERY:
			_last_attack = _tick
			return _tap(A)
		return 0
	if absf(dx) <= 14.0:
		var away := -1 if dx > 0.0 else 1
		var bounds := _bounds(here)
		if p.position.x + away * 20.0 < bounds.x or p.position.x + away * 20.0 > bounds.y:
			away = -away
		return _walk(away)
	return _walk(1 if dx > 0.0 else -1)


func _target(here: StringName) -> Node2D:
	var p := _p1()
	var best: Node2D = null
	var best_d := INF
	for e in _room.enemies_in(here):
		if absf(e.position.y - p.position.y) > 40.0:
			continue
		if _room.echo_on and _room.echo != null:
			if _room.sim.combat.mark_on(e) != null:
				continue
		elif e.armor_intact:
			continue
		var d: float = absf(e.position.x - p.position.x)
		if d < best_d:
			best = e
			best_d = d
	return best


## Niemand meer om te verslaan (een heel pantser zonder echo telt niet, L-13 e).
func _no_enemies_left(here: StringName) -> bool:
	for e in _room.enemies_in(here):
		if not (e.armor_intact and (not _room.echo_on or _room.echo == null)):
			return false
	return true


## Loopbereik per kamer (x van/tot) op de vloer van het gevecht.
func _bounds(here: StringName) -> Vector2:
	match here:
		&"S2":
			return Vector2(Layout.S2_PIJLER + 10.0, Layout.B3_GALLERY_TIP - 10.0)
		&"S3":
			return Vector2(Layout.S3_LEFT + 10.0, Layout.ROOMS[&"S3"].end.x - 10.0)
		&"S4":
			return Vector2(Layout.B4_FAR_EDGE + 10.0, Layout.S4_END_WALL - 10.0)
	return Vector2(-INF, INF)


## Wachten op de echo zonder stil te staan: heen en weer.
func _patrol(here: StringName) -> int:
	var p := _p1()
	var bounds := _bounds(here)
	if p.position.x <= bounds.x + 30.0:
		_patrol_dir = 1
	elif p.position.x >= bounds.y - 30.0:
		_patrol_dir = -1
	return _walk(_patrol_dir)


## B4 naar rechts achter een keerpunt (#217; gdd §4.3, C-11): AANVAL slaan en
## vasthouden terwijl je naar de bolder op de rand loopt, keren tegen de bolder,
## en de echo komt je tegemoet in houding. Bij een korte staart (`hop`) spring
## je meteen op de echo, word je gelanceerd en dash je na de top over de kloof;
## bij een lange staart (`ride`) spring je op de echo vóór zijn houding begint
## en draagt hij je naar de bolder, waar de lancering ingaat. Zonder echo, of
## gemist: de langzame lijn (over de bolder de kloof in, twee treden op).
func _leg_b4() -> int:
	var p := _p1()
	var flying := sub == "launched" or sub == "dashed"
	if flying and _on_level(Layout.S4_FLOOR) and p.position.x > Layout.B4_FAR_EDGE - Layout.HALF_W \
			and not landed_from_wall.has("S4-B4"):
		landed_from_wall["S4-B4"] = p.position.x - Layout.B4_FAR_EDGE
	if p.position.x > Layout.B4_FAR_EDGE + 20.0 and _on_level(Layout.S4_FLOOR):
		_next_leg(flying)
		return R
	# Mis (te kort): in de kloof, dan de langzame lijn.
	if flying and p.motor.on_floor and p.motor.support != Motor.Support.SHADOW_BODY \
			and p.position.y > Layout.S4_FLOOR - Layout.HALF_H + 1.5:
		sub = "slow"
		return R
	var hop := Layout.b4_hop(_d)
	match sub:
		"":
			if not _room.echo_on or _room.echo == null:
				sub = "slow"
				return R
			if p.position.x >= Layout.b4_strike_x(_d):
				sub = "hold"
				return R | _tap(A)
			return R
		"hold":
			if _against_wall(Layout.S4_FLOOR):
				turned["S4-B4"] = _tick
				_turn_x = p.position.x
				sub = "back"
				_since = 0
				return L
			return R | A
		"back":
			if not _on_level(Layout.S4_FLOOR) or _since > B4_GIVE_UP_TICKS:
				sub = "slow"
				return R
			if _echo_ready():
				var e: Node2D = _room.echo
				var ahead: float = p.position.x - e.position.x
				var reach := JUMP_ON_ECHO_PX if hop else B4_RIDE_JUMP_PX
				if absf(e.position.y - p.position.y) < 1.5 and ahead > 0.0 and ahead <= reach:
					if _b4_waited < b4_jump_delay:
						_b4_waited += 1
						return L
					sub = "air"
					_since = 0
					return L | _tap(J)
			return L
		"air":
			if p.motor.launch_pending or p.motor.launch_left > 0:
				bounce_from_wall["S4-B4"] = absf(Layout.B4_NEAR_EDGE - p.position.x)
				sub = "launched"
				_since = 0
				return R
			if _on_plank():
				sub = "ride"
				return 0
			if _since > 2 and _on_level(Layout.S4_FLOOR):
				sub = "slow"
				return R
			return _steer_to_echo(-1)
		"ride":
			if p.motor.launch_pending or p.motor.launch_left > 0:
				bounce_from_wall["S4-B4"] = absf(Layout.B4_NEAR_EDGE - p.position.x)
				sub = "launched"
				_since = 0
				return R
			if not _on_plank():
				sub = "slow"
				return R
			return 0
		"launched":
			if hop and p.motor.launch_left == 0 and p.motor.velocity.y >= 0.0 and p.motor.dash_ready:
				if _b4_waited < b4_jump_delay + b4_dash_delay:
					_b4_waited += 1
					return R
				sub = "dashed"
				return R | _tap(DASH)
			return R
		"dashed":
			return R
	return _slow_b4()


func _slow_b4() -> int:
	var p := _p1()
	if _stuck >= 1:
		if p.motor.on_floor:
			return R | _tap(J)
		if absf(p.motor.velocity.y) < 0.3:
			return 0
	return R
