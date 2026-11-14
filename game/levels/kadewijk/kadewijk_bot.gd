extends RefCounted
## De gescripte geoefende run door de Kadewijk (S1–S9; gdd §4.5, L-08,
## FK-2, C-15; T8a #83; deel 2: S5 B2, S6 pompgang, S7 luik en kanaal;
## deel 3: S9 de lage kade, het luik, B1 met logbladzijde 3, de schacht naar S1;
## de lus (#83): met `lus` en een `boss_input` de hele route S1 → S8 → de boss →
## S9 → de trap naar het plein → trap 2 → terug → S9 → S1).
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
const Gemaal = preload("res://scripts/light/gemaal.gd")
const DOWN := InputBits.DOWN

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
## B3 bij D ≥ 90, late bot (SM-review #220): dash zo veel ticks na de bounce;
## -1 = op de top (de run). Het venster loopt van 14 tot ± 38.
var b3_dash_after := -1
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

## De wijk (`kadewijk.gd`), of een blik erop die voor één speler hetzelfde laat zien
## (`kadewijk_duo.gd`, co-op: `p1` is dan het lichaam van die speler, zonder echo).
var _room: Object
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
## S6 pompgang (zoals `flow_bot.gd`): looprichting, geslagen schoepen in deze
## doorgang, slagen van P1 sinds het begin, en de echo-slagen op dat moment.
var _pass_dir := 1
var _struck := {}
var _visit_strokes := -1
var _echo_base := 0
## S6 zonder genoeg licht: zo vaak terug naar S5 voor de Kadelopers (LM-13).
var s6_returns := 0
## S7: stuit-treffers op de Dwaallichten (V-01b), in volgorde.
var stuits := 0
## S7, test van de langzame lijn: geen neerslag boven het kanaal (het kanaal in).
var kanaal_no_stuit := false
## S9, de trap naar het plein: de x waar de bot heen stuurt in de lucht.
var _trap_x := NAN
## De lus (#83): na `S7-deur` speelt `boss_input` de boss in S8; na
## `BOSS_VERSLAGEN` de deur links uit, de trap op, trap 2 pompen, de trap af en
## S9 tot `SLICE_EIND` (`LUS_NEXT`). Zonder `lus` blijft alles zoals de runs van
## deel 1–3 (S8-eind wacht op het einde).
var lus := false
## Maakt de inputbron voor de boss: `func(sim, boss) -> RefCounted` met
## `sample(tick)` (de test geeft `boss_bot.gd`); leeg = niet gebruikt.
var boss_input: Callable
var _boss_source: RefCounted = null
## Ticks waarop de boss-bron het overnam en waarop de boss verslagen was (lus).
var boss_from := -1
var boss_until := -1
## De lus: na deze stap komt die stap (in plaats van de volgende in `_legs`).
const LUS_NEXT := {"S8-eind": "S9-deur", "S9-deur": "S9-trap", "S9-trap": "S6-trap2",
	"S6-trap2": "S9-trap-af", "S9-trap-af": "S9-kade"}

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
	["S4-eind", "walk", &"S5"],
	["S5-B2a", "turn", 3],
	["S5-B2b", "turn", 4],
	["S5-B2c", "turn", 5],
	["S5-B2d", "turn", 6],
	["S5-zolder", "walk", &"S6"],
	["S6-brug", "land", null],
	["S6-paar", "fight", null],
	["S6-gemaal", "gemaal", null],
	["S7-luik", "luik", 0],
	["S7-kanaal", "kanaal", null],
	["S7-deur", "west", &"S8"],
	["S8-eind", "end", null],
	# Deel 3: S9 vanaf zijn begin (bij de deur van de arena; de boss en de deur
	# zijn van de GP), met het hoogwater open (`s = 2`, placeholder).
	["S9-kade", "kade9", null],
	["S9-B2a", "turn", 9],
	["S9-B2b", "turn", 10],
	["S9-pijler", "pijler9", null],
	["S9-dwaallicht", "stuit9", null],
	["S9-paar", "fight", null],
	["S9-luik", "luik", 1],
	["S9-B1", "turn", 8],
	["S9-schacht", "schacht", null],
	["S9-eind", "end", null],
	# Niet in de run: de trap naar het plein en terug (de test zet `leg` hierop).
	["S9-trap", "trap9", null],
	["S9-trap-af", "trap9_af", null],
	# Alleen in de lus (`LUS_NEXT`): na de boss de deur links uit, en op het plein trap 2.
	["S9-deur", "west", &"S9"],
	["S6-trap2", "trap2", null],
	# Niet in de run (S8-eind wacht op het einde): de arena-test zet `leg` hierop.
	# Blijft de laatste stap.
	["S8-rad", "turn", 7],
]


func _init(room: Object, d: int, start_room: StringName = &"S1") -> void:
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
	var done_name: String = _legs[leg][0]
	lines[done_name] = echo_line
	leg_done[done_name] = _tick
	leg += 1
	if lus and LUS_NEXT.has(done_name):
		leg = _leg_index(LUS_NEXT[done_name])
	sub = ""
	_off_ledge = false
	_from_tread = false
	_since = 0
	_stuck = 0
	_last_x = INF


func _leg_index(leg_name_: String) -> int:
	for i in _legs.size():
		if _legs[i][0] == leg_name_:
			return i
	return _legs.size()


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
		"west":
			if _room.room == spec[2]:
				_next_leg(false)
				return L
			return L
		"land":
			# Van de loopbrug het plein op (S6).
			if _room.room == &"S6" and _on_level(Layout.S6_FLOOR):
				_next_leg(false)
				return R
			return R
		"gemaal":
			return _leg_gemaal()
		"luik":
			if spec[2] == 1:
				return _leg_luik(Layout.S9_LUIK, Layout.S9_KADE, Layout.S9_LAAG)
			return _leg_luik(Layout.LUIK, Layout.S7_UP, Layout.S7_LOW)
		"kade9":
			return _leg_kade9()
		"stuit9":
			return _leg_stuit9()
		"pijler9":
			# Van richel 2 over de pijler naar links, de kade weer op.
			if _on_level(Layout.S9_KADE) and _p1().position.x < Layout.S9_PIJLER.position.x:
				_next_leg(false)
			return L
		"schacht":
			return _leg_schacht()
		"trap9":
			return _leg_trap9()
		"trap9_af":
			return _leg_trap9_af()
		"kanaal":
			return _leg_kanaal()
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
			if lus and _room.room == &"S8":
				return _leg_boss()
			return R
		"trap2":
			return _leg_trap2()
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
	var z: float = tp.get("z", Layout.keerzone(_d))
	if _on_level(next_level) and absf(p.position.x - wall) > z:
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
			if b3_dash_after >= 0:
				if _since == b3_dash_after and p.position.x > Layout.B3_GALLERY_TIP + 4.0:
					return L | _tap(DASH)
				return L
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
		return _walk(_patrol_dir) if sub == "patrol" else (L if here == &"S2" or here == &"S9" else R)
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
		if absf(e.position.y - p.position.y) > 40.0 or e.enemy_type == SliceEnemy.Type.DWAALLICHT:
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


## Niemand meer om te verslaan (een heel pantser zonder echo telt niet, L-13 e;
## een Dwaallicht is geen tegenstander op de vloer, S9).
func _no_enemies_left(here: StringName) -> bool:
	for e in _room.enemies_in(here):
		if e.enemy_type == SliceEnemy.Type.DWAALLICHT:
			continue
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
		&"S6":
			return Vector2(Layout.ROOMS[&"S6"].position.x + 10.0, (Layout.PUMP_VANES[0] as Vector2).x - 20.0)
		&"S9":
			return Vector2(Layout.S9_PLAAT_END + 10.0, Layout.S9_PIJLER.position.x - 10.0)
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


# --- Deel 2 (#83) ---------------------------------------------------------------

## S6 pompgang (gdd LM-04, FK-5; zoals K3 van de flow-kamer): naar rechts door
## de vier schoepen, elke schoep één keer slaan in het voorbijlopen, en door
## naar de sluis; de echo slaat dezelfde schoepen D ticks later. Gaat de sluis
## niet open met wat de echo nog slaat (echo uit, of te weinig licht), dan
## keert P1 en slaat hij ze op de terugweg nog eens, zolang er licht in de meter
## is; is de meter leeg, dan de trap op naar de loopbrug, even S5 in en terug
## (de Kadelopers staan er dan weer, LM-13) voor meer licht. Klaar in S7.
func _leg_gemaal() -> int:
	var p := _p1()
	var g: Gemaal = _room.gemaal
	if _room.room == &"S7":
		_next_leg(g != null and int(g.strokes.get("echo", 0)) > 0)
		return 0
	if g == null:
		return R
	match sub:
		"":
			if not _on_level(Layout.S6_FLOOR):
				return R
			sub = "gang"
			_pass_dir = 1
			_struck = {}
			if _visit_strokes < 0:
				_visit_strokes = 0
				_echo_base = int(g.strokes.get("echo", 0))
			return R
		"gang":
			var bits := _walk(_pass_dir) | _pump_bits()
			if g.full_tick >= 0 or _will_fill():
				sub = "sluice"
				return bits
			if _past_gang():
				if int(_room.meter.value) <= 0:
					sub = "climb"
					return L
				_pass_dir = -_pass_dir
				_struck = {}
			return bits
		"sluice":
			if g.full_tick >= 0:
				return R
			# De echo slaat nog: heen en weer vóór de sluis, niet stilstaan (MP-1).
			if p.position.x >= Layout.S6_SHAFT_LEFT - 12.0:
				_patrol_dir = -1
			elif p.position.x <= Layout.S6_SHAFT_LEFT - 72.0:
				_patrol_dir = 1
			return _walk(_patrol_dir)
		"climb":
			return _climb_s6()
		"back":
			# Even in S5 geweest: terug naar het plein, dan het paar en de pompgang.
			if _room.room == &"S6" and _on_level(Layout.S6_FLOOR):
				s6_returns += 1
				leg = _legs.find(_legs.filter(func(l: Array) -> bool: return l[0] == "S6-paar")[0])
				sub = ""
				_visit_strokes = -1
				return R
			return R
	return 0


func _pump_bits() -> int:
	var p := _p1()
	if _tick - _last_attack < ATTACK_EVERY:
		return 0
	var vanes: Array = Layout.PUMP_VANES
	for i in vanes.size():
		if _struck.has(i):
			continue
		var ahead: float = ((vanes[i] as Vector2).x - p.position.x) * float(p.motor.facing)
		if ahead >= -6.0 and ahead <= 36.0 and p.motor.facing == _pass_dir:
			_struck[i] = true
			_last_attack = _tick
			_visit_strokes += 1
			return _tap(A)
	return 0


func _past_gang() -> bool:
	var x := _p1().position.x
	if _pass_dir > 0:
		return x > (Layout.PUMP_VANES[Layout.PUMP_VANES.size() - 1] as Vector2).x + 10.0
	return x < (Layout.PUMP_VANES[0] as Vector2).x - 10.0


## Maakt de echo het gemaal vol met de slagen die hij nog herhaalt (LM-03)?
func _will_fill() -> bool:
	var g: Gemaal = _room.gemaal
	if g.full_tick >= 0:
		return true
	if not _room.echo_on or _room.echo == null:
		return false
	var pending := _visit_strokes - (int(g.strokes.get("echo", 0)) - _echo_base)
	return int(g.fill) + mini(pending * Gemaal.per_stroke(), int(_room.meter.value)) >= Gemaal.MAX


## De trap naar de loopbrug: recht omhoog over de treden, dan de brug af naar
## links tot in S5 (de kamer verlaten, LM-13), en terug.
func _climb_s6() -> int:
	var p := _p1()
	if _room.room == &"S5":
		sub = "back"
		return R
	if _on_level(Layout.S5_ZOLDER):
		return L
	if not p.motor.on_floor:
		return 0
	if _on_level(Layout.S6_FLOOR):
		if absf(p.position.x - Layout.S6_STAIR_X) <= 2.0:
			return _tap(J)
		return _walk(1 if Layout.S6_STAIR_X > p.position.x else -1)
	return _tap(J)


## S7 en S9, het luik (V-01, SL-04): naar het luik (in S7 langs de sokkel, in
## S9 over de lage kade tot de kadewand), springen en meteen een neerslag (in
## de lucht AANVAL met omlaag): het luik gaat open, P1 stuit en valt erdoor
## naar de vloer eronder (`low`).
func _leg_luik(luik: Rect2, up: float, low: float) -> int:
	var p := _p1()
	if _on_level(low):
		_next_leg(true)
		return L
	var cx := luik.get_center().x
	if p.motor.on_floor and _on_level(up):
		if absf(p.position.x - cx) <= 3.0:
			sub = "jump"
			return _tap(J)
		return _walk(1 if cx > p.position.x else -1)
	if sub == "jump" and not p.motor.on_floor:
		sub = "slam"
		return DOWN | A
	return 0


## S7, het kanaal (V-01b, `slice-vijanden-en-boss.md` §2.6): naar links tot de
## rand (met coyote), springen, boven het eerste Dwaallicht een neerslag,
## stuiten, boven het tweede weer, en de overkant op. Gemist: het kanaal in en
## de langzame lijn (de trede en de kademuur).
func _leg_kanaal() -> int:
	var p := _p1()
	if _on_level(Layout.S7_LOW) and p.position.x < Layout.KANAAL_LEFT - 4.0:
		_next_leg(sub != "slow")
		return L
	if p.motor.on_floor and p.position.y > Layout.S7_LOW - Layout.HALF_H + 1.5:
		sub = "slow"
	match sub:
		"":
			if _on_level(Layout.S7_LOW) and p.position.x <= Layout.KANAAL_RIGHT + 6.0:
				sub = "air"
				_since = 0
				return L | _tap(J)
			if not p.motor.on_floor and p.position.x < Layout.KANAAL_RIGHT:
				# Over de rand gelopen: coyote-sprong.
				sub = "air"
				_since = 0
				return L | _tap(J)
			return L
		"air":
			var target := _next_wisp()
			if target == null or kanaal_no_stuit:
				return L
			var dx: float = target.position.x - p.position.x
			var feet := p.position.y + Layout.HALF_H
			var top: float = target.position.y - 8.0
			if absf(dx) <= 10.0 and feet > top - 20.0 and feet < top + 14.0 and _tick - _last_attack >= 4:
				_last_attack = _tick
				stuits += 1
				return DOWN | _tap(A)
			if dx < -2.0:
				return L
			if dx > 2.0:
				return R
			return 0
		"slow":
			return _slow_kanaal()
	return L


## Het volgende Dwaallicht in de looprichting (naar links) dat nog leeft en
## dat P1 nog niet raakte met een neerslag (gestund = net geraakt).
func _next_wisp(here: StringName = &"S7") -> Node2D:
	var p := _p1()
	var best: Node2D = null
	for e in _room.enemies_in(here):
		if e.enemy_type != SliceEnemy.Type.DWAALLICHT:
			continue
		if e.is_stunned(_tick) or (_room.sim.combat.mark_on(e) != null):
			continue
		if e.position.x > p.position.x + 12.0:
			continue
		if best == null or e.position.x > best.position.x:
			best = e
	return best


func _slow_kanaal() -> int:
	var p := _p1()
	if _on_level(Layout.KANAAL_BOTTOM - 45.0):
		return L | _tap(J)
	if _on_level(Layout.KANAAL_BOTTOM):
		if p.position.x <= Layout.KANAAL_LEFT + Layout.TREAD_W + 8.0 + 2.0:
			return L | _tap(J)
		return L
	return L


# --- Deel 3 (#83): S9 de lage kade ----------------------------------------------

## Van de deur van de arena naar links, de kademuur van 45 op (springen 16 px
## ervoor, zoals een speler: wie tegen een muur aan loopt, verliest de vloer en
## springt pas weer na loslaten, kamerdoc §9) en de lage kade op. Het hoogwater
## moet open zijn (`s = 2`).
func _leg_kade9() -> int:
	var p := _p1()
	if _on_level(Layout.S9_KADE):
		_next_leg(false)
		return L
	if _on_level(Layout.S9_DOOR_FLOOR) and p.position.x - Layout.S9_STEP_X <= Layout.HALF_W + 16.0:
		return L | _tap(J)
	return L


## Van de galerij van B1 naar de schacht (x 460–500) en de treden recht omhoog
## door het snelluik de gang van S1 in (`SLICE_EIND`).
func _leg_schacht() -> int:
	var p := _p1()
	if _room.slice_end_tick >= 0:
		_next_leg(true)
		return 0
	var cx := (Layout.S9_SHAFT_LEFT + Layout.S9_SHAFT_RIGHT) * 0.5
	if not p.motor.on_floor:
		if p.position.x < cx - 2.0:
			return R
		if p.position.x > cx + 2.0:
			return L
		return 0
	if _on_level(Layout.S9_UP):
		if p.position.x >= Layout.S9_SHAFT_LEFT - 14.0:
			return R | _tap(J)
		return R
	if absf(p.position.x - cx) > 2.0:
		return _walk(1 if cx > p.position.x else -1)
	return _tap(J)


## De trap van S9 naar het plein (voor trap 2, SL-02): van de vloer bij de deur
## onder de eerste trede, dan schuin omhoog naar de volgende (om en om links en
## rechts) en van de bovenste naar rechts het plein op. Klaar op het plein.
func _leg_trap9() -> int:
	var p := _p1()
	if _room.room == &"S6" and _on_level(Layout.S6_FLOOR):
		_next_leg(false)
		return 0
	var treads := Layout.s9_trap_treads()
	if not p.motor.on_floor:
		if is_nan(_trap_x):
			return 0
		if p.position.x < _trap_x - 2.0:
			return R
		if p.position.x > _trap_x + 2.0:
			return L
		return 0
	if _on_level(Layout.S9_DOOR_FLOOR):
		_trap_x = float(treads[0][1]) + Layout.S9_TRAP_W * 0.5
		if absf(p.position.x - _trap_x) <= 2.0:
			return _tap(J)
		return _walk(1 if _trap_x > p.position.x else -1)
	for i in treads.size():
		if _on_level(float(treads[i][0])):
			if i + 1 < treads.size():
				_trap_x = float(treads[i + 1][1]) + Layout.S9_TRAP_W * 0.5
			else:
				_trap_x = Layout.ROOMS[&"S6"].position.x + 16.0
			return _tap(J)
	return 0


## En terug: van het plein naar links de schacht in, en van elke trede aan de
## open kant eraf, tot de vloer bij de deur (S9).
func _leg_trap9_af() -> int:
	var p := _p1()
	if _room.room == &"S9" and _on_level(Layout.S9_DOOR_FLOOR):
		_next_leg(false)
		return 0
	if not p.motor.on_floor:
		return 0
	for tr: Array in Layout.s9_trap_treads():
		if _on_level(float(tr[0])):
			return R if float(tr[1]) <= Layout.S9_TRAP_LEFT else L
	return L


## S9, het Dwaallicht boven de kade (V-01b, #227): springen als het ± 44 px vóór
## je hangt (vóór het duikt), boven het Dwaallicht een neerslag, stuiten, en
## naar links de kade weer op. De echo laat het merk achter je knallen.
func _leg_stuit9() -> int:
	var p := _p1()
	if sub == "air" and _since > 2 and _on_level(Layout.S9_KADE):
		_next_leg(stuits > 0)
		return L
	match sub:
		"":
			if _on_level(Layout.S9_KADE) and p.position.x - Layout.S9_DWAALLICHT_X <= 44.0:
				sub = "air"
				_since = 0
				return L | _tap(J)
			return L
		"air":
			var target := _next_wisp(&"S9")
			if target == null:
				return L
			var dx: float = target.position.x - p.position.x
			var feet := p.position.y + Layout.HALF_H
			var top: float = target.position.y - 8.0
			if absf(dx) <= 10.0 and feet > top - 20.0 and feet < top + 14.0 and _tick - _last_attack >= 4:
				_last_attack = _tick
				stuits += 1
				return DOWN | _tap(A)
			if dx < -2.0:
				return L
			if dx > 2.0:
				return R
			return 0
	return L


# --- De lus (#83): de boss, trap 2 en terug -----------------------------------------

## S8 in de lus: `boss_input` speelt de Gemaalmeester (de bot van de boss-runs,
## B-9) tot `BOSS_VERSLAGEN`; daarna is S8-eind klaar (verder met `S9-deur`).
func _leg_boss() -> int:
	if _room.is_boss_defeated():
		if boss_until < 0:
			boss_until = _tick
		_next_leg(false)
		return L
	if _boss_source == null:
		if _room.boss == null or not boss_input.is_valid():
			return L
		_boss_source = boss_input.call(_room.sim, _room.boss)
		boss_from = _tick
	return _boss_source.sample(_tick)


## Trap 2 (SL-02, LM-08): van de trap het plein op naar rechts door de pompgang,
## elke schoep één keer slaan (de echo slaat ze D ticks later nog eens); is trap
## 2 vol, of maakt de echo hem vol, dan terug naar links naar de trap. Anders
## keert P1 na de laatste schoep en slaat hij ze op de terugweg nog eens,
## zolang er licht is (GM-10: na de boss 100 LP, 4 + 4 slagen = 100 G).
func _leg_trap2() -> int:
	var g: Gemaal = _room.gemaal
	if g == null:
		return R
	if sub != "" and (g.trap_2_tick >= 0 or _will_fill_trap_2()):
		_next_leg(int(g.strokes.get("echo", 0)) > _echo_base)
		return L
	match sub:
		"":
			sub = "gang"
			_pass_dir = 1
			_struck = {}
			_visit_strokes = 0
			_echo_base = int(g.strokes.get("echo", 0))
			return R
		"gang":
			var bits := _walk(_pass_dir) | _pump_bits()
			if _past_gang() and int(_room.meter.value) > 0:
				_pass_dir = -_pass_dir
				_struck = {}
			return bits
	return 0


## Maakt de echo trap 2 vol met de slagen die hij nog herhaalt?
func _will_fill_trap_2() -> bool:
	var g: Gemaal = _room.gemaal
	if not _room.echo_on or _room.echo == null:
		return false
	var pending := _visit_strokes - (int(g.strokes.get("echo", 0)) - _echo_base)
	return int(g.fill) + mini(pending * Gemaal.per_stroke(), int(_room.meter.value)) >= 2 * Gemaal.MAX
