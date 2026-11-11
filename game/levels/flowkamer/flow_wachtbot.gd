extends RefCounted
## De wachtbot (gdd §4.6 L-08 (a), W-6; na F0): een inputbron die bij één
## keerpunt van B1 of B2 op één plek stilstaat tot zijn echo onder hem is, en
## dan op hem springt, bounct en op de top van de bounce van de wand af dasht.
## Hij meet het patroon van F0 ("wachten tot hij onder me is") en het restgat
## van de keerzone (gdd §4.3): haalt hij zo de weg omhoog, en na hoeveel
## stilstand? Hij rapporteert; hij beslist niets.
##
## Twee soorten plekken (`x` = afstand tot het wandvlak van de keerwand):
## - **"in"** (op weg naar binnen): P1 begint 20 px verder van de wand, loopt
##   naar de wand en stopt op `x` (ook onder de weg omhoog en op `x > D`);
## - **"uit"** (na het keren): P1 begint op `START_OUT` px van de wand, loopt
##   tot tegen de wand, keert en stopt op `x` (0 … D).
## Op `x` wacht hij tot de echo stilstaat onder hem (zelfde vloer, ≤ 4 px
## opzij): dat is de echo die op dezelfde plek stond als P1 D ticks eerder.
## Dan springt hij recht omhoog, landt op de echo, bounct meteen en dasht op
## de top van de wand af (de beste kans op de weg omhoog).
##
## Uitkomst (`result`): "omhoog" (geland op het niveau van de weg omhoog, buiten
## de keerzone), "trede" (op de treden of de richel op 135 van de langzame
## lijn), "vloer" (terug op de eigen vloer), "lager" (van het niveau af
## gevallen), "geen_echo" (de echo kwam niet
## onder hem binnen `GIVE_UP` ticks) of "anders". `waited` = ticks tussen
## stoppen en springen.

const InputBits = preload("res://scripts/input/input_bits.gd")
const Motor = preload("res://scripts/echo/motor.gd")
const Layout = preload("res://levels/flowkamer/flow_layout.gd")

const L := InputBits.LEFT
const R := InputBits.RIGHT
const J := InputBits.JUMP
const DASH := InputBits.DASH

## "uit": hier begint P1, voorbij de keerzone.
const START_OUT := 140.0
## Zo lang wacht hij hooguit op de echo.
const GIVE_UP := 400

var tp: Dictionary
var mode := "in"
var x := 0.0
var result := ""
## Ticks stilstand tussen stoppen en springen; -1 = niet gesprongen.
var waited := -1
## Afstand tot de wand waar hij landde (na de bounce), of NAN.
var landed_x := NAN
var done := false
## Dash op de top van de bounce (gdd L-08 (a): "met bounce en dash").
var use_dash := true

var _room: Node
var _phase := "walk"
var _turned := false
var _stopped_at := -1
var _bounced := false
var _dashed := false
var _prev := 0
var _tick := 0
var _last_x := INF
var _stuck := 0
var _echo_last_x := NAN


func _init(room: Node, p_tp: Dictionary, p_mode: String, p_x: float) -> void:
	_room = room
	tp = p_tp
	mode = p_mode
	x = p_x


## Startplek van P1 (zet de test vóór de eerste tick).
func start_position() -> Vector2:
	var from := x + 20.0 if mode == "in" else START_OUT
	return Vector2(_wall_x(from), float(tp["floor"]) - Layout.HALF_H)


func sample(tick: int) -> int:
	_tick = tick
	var bits := _decide()
	_prev = bits
	return bits


## x in de wereld op `dist` px van het wandvlak (van de wand af).
func _wall_x(dist: float) -> float:
	return float(tp["wall"]) - float(tp["side"]) * dist


func _dist() -> float:
	return absf(_room.p1.position.x - float(tp["wall"]))


func _away() -> int:
	return -int(tp["side"])


func _walk(dir: int) -> int:
	return R if dir > 0 else L


func _tap(bit: int) -> int:
	return 0 if _prev & bit else bit


func _on_level(level_top: float) -> bool:
	var p: CharacterBody2D = _room.p1
	return p.motor.on_floor and p.motor.support != Motor.Support.SHADOW_BODY \
		and absf(p.position.y - (level_top - Layout.HALF_H)) < 1.5


func _decide() -> int:
	if done:
		return 0
	var p: CharacterBody2D = _room.p1
	var floor_y := float(tp["floor"])
	var px := p.position.x
	_stuck = _stuck + 1 if absf(px - _last_x) < 0.5 else 0
	_last_x = px
	var e = _room.echo
	var echo_x: float = e.position.x if e != null and e.is_present() else NAN
	var echo_still := not is_nan(echo_x) and not is_nan(_echo_last_x) and absf(echo_x - _echo_last_x) < 0.5
	_echo_last_x = echo_x
	match _phase:
		"walk":
			var toward := int(tp["side"])
			if mode == "uit" and not _turned:
				if _stuck >= 1 and _on_level(floor_y) or _dist() < 8.5:
					_turned = true
				else:
					return _walk(toward)
			var target := _wall_x(maxf(x, 8.0))
			var dir := toward if mode == "in" else _away()
			if (target - px) * dir <= 1.0 or (x == 0.0 and _stuck >= 1):
				_phase = "wait"
				_stopped_at = _tick
				return 0
			return _walk(dir)
		"wait":
			if _tick - _stopped_at > GIVE_UP:
				result = "geen_echo"
				done = true
				return 0
			if echo_still and absf(echo_x - px) <= 4.0 and absf(e.position.y - p.position.y) < 1.5 \
					and not e.in_merksprong:
				waited = _tick - _stopped_at
				_phase = "air"
				return _tap(J)
			return 0
		"air":
			var on_world: bool = p.motor.on_floor and p.motor.support != Motor.Support.SHADOW_BODY
			if not _bounced:
				if p.motor.on_floor and p.motor.support == Motor.Support.SHADOW_BODY:
					_bounced = true
					return _tap(J)
				if on_world and _tick - _stopped_at > waited + 4:
					# Niet op de echo geland (bv. op een trede erboven).
					_finish(p)
				return 0
			if not _dashed and p.motor.velocity.y >= 0.0:
				_dashed = true
				return _walk(_away()) | (_tap(DASH) if use_dash else 0)
			if _dashed and on_world:
				_finish(p)
				return 0
			# Na de bounce van de wand af sturen.
			return _walk(_away())
	return 0


func _finish(p: CharacterBody2D) -> void:
	done = true
	landed_x = _dist()
	var floor_y := float(tp["floor"])
	var y := p.position.y + Layout.HALF_H
	if absf(y - float(tp["up"])) < 1.5 and landed_x >= Layout.KEERZONE:
		result = "omhoog"
	elif absf(y - floor_y) < 1.5:
		result = "vloer"
	elif y > floor_y + 1.5:
		result = "lager"
	elif landed_x < Layout.LEDGE135_LEN + 8.0 and (absf(y - (floor_y - 45.0)) < 1.5 \
			or absf(y - (floor_y - 90.0)) < 1.5 or absf(y - (floor_y - 135.0)) < 1.5):
		result = "trede"
	else:
		result = "anders"
