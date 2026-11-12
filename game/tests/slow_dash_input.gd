extends RefCounted
## W-12 (gdd v0.8.2 §4.8.7, §4.6 *B1, B2: langzame lijn met dash*): een
## inputbron rond een gescripte bot (`flow_bot.gd`, `kadewijk_bot.gd`) die de
## langzame lijn neemt (echo uit), met een dash `n` ticks na de afzet van de
## sprong naar de weg omhoog. Die sprong is de sprong van de trede op 60: bij
## D = 60 schuin naar de weg omhoog, bij een langere D (Kadewijk: trede op 90
## tot `Z − 14`) naar de trede op 90 of de weg omhoog. De bot zelf verandert
## niet: deze bron geeft zijn knoppen door en zet er één DASH-flank bij.
##
## Per keerpunt (de eerste afzet van de trede op 60 na het keren) houdt hij bij
## of de sprong mist: P1 landt na de afzet lager dan de weg omhoog voordat de
## bot de stap afrondt (de bot klimt dan opnieuw; die tijd telt niet).

const Motor = preload("res://scripts/echo/motor.gd")
const InputBits = preload("res://scripts/input/input_bits.gd")

const HALF_H := 15.0

## De bot en de kamer of het gebied (met `p1`).
var bot: RefCounted
var room: Node
## Ticks na de afzet; -1 = geen dash (de lijn van de bot).
var dash_n := -1
## Keerpunten als in `Layout.turn_points()`: naam, vloer (`floor`), weg omhoog (`up`).
var turn_points: Array = []
## Per keerpunt: de tick van de afzet van de trede op 60, en of de sprong miste.
var afzet := {}
var missed := {}

var _dash_at := -1
var _prev_bot := 0
var _airborne_after := ""


func _init(p_bot: RefCounted, p_room: Node, p_turn_points: Array, p_dash_n: int = -1) -> void:
	bot = p_bot
	room = p_room
	turn_points = p_turn_points
	dash_n = p_dash_n


func _tp(leg_name: String) -> Dictionary:
	for tp: Dictionary in turn_points:
		if tp["name"] == leg_name:
			return tp
	return {}


func _on_level(level_top: float) -> bool:
	var p = room.p1
	return p.motor.on_floor and p.motor.support != Motor.Support.SHADOW_BODY \
		and absf(p.position.y - (level_top - HALF_H)) < 1.5


## Naam van de stap van de bot nu (`kadewijk_bot.gd` heeft `leg_name()`,
## `flow_bot.gd` alleen `leg` en de lijst van stappen).
func _leg_name() -> String:
	if bot.has_method("leg_name"):
		return bot.leg_name()
	var legs: Array = bot.get("_legs")
	return String(legs[bot.leg][0]) if bot.leg < legs.size() else ""


func sample(tick: int) -> int:
	var leg_name := _leg_name()
	var tp := _tp(leg_name)
	var on_60 := not tp.is_empty() and _on_level(float(tp["floor"]) - 60.0)
	var p = room.p1
	# Mist: na de afzet landt P1 lager dan de weg omhoog (vóór het einde van de stap).
	if _airborne_after != "" and _airborne_after == leg_name and p.motor.on_floor \
			and p.position.y > float(tp["up"]) - HALF_H + 1.5:
		missed[leg_name] = true
		_airborne_after = ""
	var bits: int = bot.sample(tick)
	var jump_flank := bits & InputBits.JUMP != 0 and _prev_bot & InputBits.JUMP == 0
	_prev_bot = bits
	if on_60 and jump_flank and not afzet.has(leg_name):
		afzet[leg_name] = tick
		_airborne_after = leg_name
		if dash_n >= 0:
			_dash_at = tick + dash_n
	if _leg_name() != leg_name:
		_airborne_after = ""
	if tick == _dash_at:
		bits |= InputBits.DASH
		_dash_at = -1
	return bits
