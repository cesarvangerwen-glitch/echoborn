extends RefCounted
## De gescripte geoefende co-op-run door de Kadewijk (S1–S9 en de lus; T11 G-1, #88;
## gdd §2.7, §4.5; kamerdoc `docs/design/kamers/kadewijk.md` §9 T8a), naar het
## voorbeeld van `levels/flowkamer/flow_duo.gd`.
##
## Twee inputbronnen (`p1_input`, `p2_input`, elk met `sample(tick) -> int`) voor
## een geoefend duo: P1 en P2 live, P2 in de rol van de schaduw (besluit #51, 7A;
## C-01: in co-op geen echo). Elke stoel heeft een eigen solo-bot (`kadewijk_bot.gd`)
## die door een `View` naar de wijk kijkt: `p1` is daar het lichaam van die stoel,
## `echo` is leeg. Zo nemen beide spelers de route en de langzame lijnen van de
## solo-bot (lopen, de pompgang, het luik, het kanaal, de trap, de schacht), en
## neemt het duo het over waar de kamer een samenwerkingsactie aanbiedt:
##
## - **Bounce bij elk keerpunt** (C-09, C-10; B1 in S1, S2 en S9, B3 in S2, de vier
##   verdiepingen van B2 in S5 en de twee van de brugpijler in S9): de drager gaat
##   op het niveau onder het open stuk van de weg omhoog staan (`spot`, buiten de
##   treden) en loopt daar heen en weer (MP-1); de springer springt al lopend op
##   hem en bounct naar het volgende niveau; de drager neemt daarna de langzame
##   lijn van de solo-bot (de treden). De rollen wisselen per keerpunt
##   (`SPRINGER`): wie net sprong, is vooraan en draagt de volgende keer.
## - **B4 lancering** (C-11; kamerdoc §9: "de drager staat dan tegen de bolder,
##   16 px van de rand"): P1 slaat AANVAL en houdt hem vast tegen de bolder, P2
##   springt op hem en vliegt over de kloof; P1 neemt de langzame lijn.
## - **Merk-combo's** (C-12) in elk gevecht (S2, S3, S4, S6, S9): eerst een vijand
##   met een merk van de ander slaan (hij knalt), anders een vijand zonder merk
##   die de ander niet al aanpakt. Een eigen merk laat je staan zolang de ander in
##   de kamer is.
## - **Stuiten met de ander** (V-01b, V-01e): in het kanaal van S7 en boven de kade
##   van S9 stuit P1 op de Dwaallichten; P2 volgt en stuit op hetzelfde Dwaallicht,
##   en zijn neerslag laat het merk van P1 knallen (wat solo de echo doet).
## - **Pompen samen** (LM-03, LM-04): in S6 (trap 1) slaan beide spelers elke schoep
##   in het voorbijlopen. **Trap 2** (na de boss, SL-02; gdd v0.8.6 §2.7 "wat de echo
##   doet, kan P2 ook", #292): P2 gaat met P1 de trap naar het plein op, twee treden
##   (`TRAP_GAP`) achter hem, en pompt trap 2 in het voorbijgaan mee zoals de echo solo
##   (LM-03, C-02): P1 slaat de vier schoepen en gaat terug naar de trap zodra de slagen
##   die P2 nog voor zich heeft trap 2 vol maken (zoals `_will_fill_trap_2` met de echo),
##   P2 slaat de rest. Dan samen de trap af naar S9: wie het verst van de trap is, gaat
##   als tweede, twee treden achter de ander. Op de trap staat dus nooit iemand op de
##   ander, en niemand wacht onderaan.
## - **De Gemaalmeester** (S8): `boss_input` maakt de boss-bot (`tests/boss_bot.gd`,
##   co-op, B-14: in fase 1 de wissel van GMB-14, P2 zet het merk op de doelhelft en P1
##   ontsteekt vanaf de andere helft; in fase 2 drager en springer, GMB-15; Wankel GMB-16);
##   tot `BOSS_START` lopen beide spelers zelf de arena in (de boss start pas als beide
##   lichamen 24 px binnen de muren staan, #229, GM-01). Na `BOSS_VERSLAGEN` (deur links
##   open) nemen beide stoelen weer de route, door naar S9. MP-7 (b) van P2 in de boss:
##   `tests/test_kadewijk_coop.gd` (B-14 (g)).
##
## Samen blijven: wie voor is en meer dan 400 × 300 px van de ander, wacht heen en
## weer (± 18 px; net buiten de 24 px van MP-1, daarom telt elke stoel die ticks per
## kamer in `wait_ticks`) tot de ander bij is (de leiband van
## C-07 en de geladen kamers van C-06). Op de smalle plekken (de luiken van S7 en S9, de
## schacht van S9) gaan ze achter elkaar door zonder op elkaar te wachten (#298: de regel
## "P2 laat P1 eerst gaan" gaf P2 tot 367 ticks MP-7 (e)-wachten; de luiken en de schacht
## laten twee lichamen kort na elkaar toe). Bij de Dwaallichten (`TOGETHER`) wacht
## P1 tot P2 vlak achter hem is. Wie op de ander staat buiten een samenwerkingsactie,
## stapt eraf. Lost P2 op (C-06), dan pakt hij bij terugkomst de stap van P1 op.
##
## Net als de solo-bot leest het duo alleen wat spelers zien (posities, houding,
## merken, de meter): dezelfde start en D geven dezelfde input en hetzelfde meetlog.
##
## Werkaanname (Gameplay Programmer, kader §5): de "scripted geoefende run" in
## co-op (gdd §4.5) in de Kadewijk is dit duo, met de rolverdeling van `SPRINGER`
## en de plek van de drager `spot` (buiten de treden, ± 70 px van de keerwand,
## of `Z − 40` bij een lange staart). In co-op gelden de lus-timing van B3 en de
## keer-timing van B1/B2 niet (gdd §4.3, zoals `flow_duo.gd`).

const Bot = preload("res://levels/kadewijk/kadewijk_bot.gd")
const InputBits = preload("res://scripts/input/input_bits.gd")
const Motor = preload("res://scripts/echo/motor.gd")
const Layout = preload("res://levels/kadewijk/kadewijk_layout.gd")
const SliceEnemy = preload("res://scripts/combat/slice_enemy.gd")
const Gemaal = preload("res://scripts/light/gemaal.gd")

const L := InputBits.LEFT
const R := InputBits.RIGHT
const J := InputBits.JUMP
const A := InputBits.ATTACK
const DOWN := InputBits.DOWN
const DASH := InputBits.DASH

## Wie springt bij welk keerpunt (de ander draagt). Om en om: wie net sprong, is
## vooraan en draagt de volgende keer. B4: P2 vliegt, P1 draagt.
const SPRINGER := {
	"S1-B1": 1, "S2-B3": 2, "S2-B1": 1, "S4-B4": 2,
	"S5-B2a": 1, "S5-B2b": 2, "S5-B2c": 1, "S5-B2d": 2,
	"S9-B2a": 1, "S9-B2b": 2, "S9-B1": 1,
}
## De trap naar het plein, trap 2 en terug: samen, de tweede `TRAP_GAP` achter de eerste
## (`_trap_hold`); daar wacht niemand op de ander (de afstand blijft binnen de leiband).
const TRAP_LEGS := ["S9-trap", "S6-trap2", "S9-trap-af"]
## Op de trap (treden om en om, 42 px boven elkaar, kamerdoc §3f): de tweede begint pas als de
## eerste twee treden verder is, zodat hij niet op hem springt of valt.
const TRAP_GAP := 84.0
## Omlaag wacht de tweede pas zo dicht bij de rand van het plein (de schacht van de trap).
const TRAP_HOLD_DX := 40.0
## Stuiten op de Dwaallichten (S7, S9): P1 wacht tot P2 binnen `TOGETHER_PX` achter hem is.
const TOGETHER := ["S7-kanaal", "S9-dwaallicht"]
const TOGETHER_PX := 90.0
## Wie voor is en zo ver van de ander, wacht (de leiband van C-07 is 928 × 508 px).
const FAR_X := 400.0
const FAR_Y := 300.0
## De drager loopt zo ver heen en weer rond zijn plek (MP-1: binnen 24 px is stil).
const PATROL_PX := 20.0
## Wachten op de ander: heen en weer rond de plek waar je stond.
const WAIT_PX := 18.0
## Vanaf zo ver springt de springer al lopend op de drager (een sprong duurt
## ± 33 ticks tot plankhoogte, × 2 px/tick).
const RUNUP_PX := 66.0
## De drager wacht hooguit zo lang op de springer, dan de langzame lijn (allebei).
const LIFT_GIVE_UP := 1200
## B3: de drager staat rechts van de trede van 35 (x 1100–1140), anders landt de springer erop.
const B3_SPOT := 1185.0
## B4: de drager wacht hier (heen en weer) tot de springer op de aanloop is, en
## loopt dan naar de bolder (`Layout.B4_TURN_X`), slaat en houdt AANVAL vast.
const B4_WAIT_X := 2830.0
const B4_CALL_X := 2700.0
const B4_SPRINGER_WAIT_X := 2770.0
const B4_HOLD_GIVE_UP := 400
## Gevecht: tussen twee slagen (zoals de solo-bot).
const ATTACK_EVERY := 21


## Wat de solo-bot van één stoel ziet: de wijk, met het lichaam van die stoel als `p1`
## en zonder echo (C-01).
class View:
	extends RefCounted
	var w: Node
	var index := 1
	var p1: CharacterBody2D:
		get:
			return w.p1 if index == 1 else w.p2
	var echo: Node2D:
		get:
			return null
	var echo_on: bool:
		get:
			return w.echo_on
	var room: StringName:
		get:
			if index == 1:
				return w.room
			var b: CharacterBody2D = w.p2
			if b == null or b.dissolved:
				return w.room
			var id := Layout.room_of(b.position)
			return id if id != &"" else w.room
	var sim: Node:
		get:
			return w.sim
	var gemaal: Node:
		get:
			return w.gemaal
	var meter: RefCounted:
		get:
			return w.meter
	var wave: int:
		get:
			return w.wave
	var run_over: bool:
		get:
			return w.run_over
	var slice_end_tick: int:
		get:
			return w.slice_end_tick
	var boss: Node:
		get:
			return w.boss

	func enemies_in(id: StringName) -> Array:
		return w.enemies_in(id)

	func is_boss_defeated() -> bool:
		return w.is_boss_defeated()


## Eén speler: zijn solo-bot, de toestand van het duo en de opgenomen bits.
class Seat:
	extends RefCounted
	## Zwakke verwijzing naar het duo (anders houden duo en stoel elkaar vast, #233).
	var duo: WeakRef
	var index := 1
	var bot: RefCounted
	var sub := ""
	var since := 0
	var prev := 0
	var last_attack := -1000
	var patrol_dir := 1
	var anchor := NAN
	## Afgeronde stappen, en de stap (index in de solo-bot) die het duo laatst zag.
	var done := 0
	var leg_seen := -1
	var started := 0
	var was_dissolved := false
	## Wacht deze stoel deze tick op de ander (dan wacht de ander niet op hem)?
	var waiting := false
	## Ticks waarin deze stoel op de ander wachtte (`waiting`), per kamer van dit lichaam
	## (MP-7 "niemand wacht": het wachten ± 18 px valt buiten MP-1).
	var wait_ticks := {}
	var last_x := INF
	var stuck := 0
	var recorded := PackedInt32Array()

	func sample(tick: int) -> int:
		var owner: RefCounted = duo.get_ref()
		var bits: int = owner._decide(self, tick) if owner != null else 0
		recorded.append(bits)
		prev = bits
		return bits


var p1_input: Seat
var p2_input: Seat
## Maakt de boss-bot: `func(sim, boss) -> RefCounted` met `sample_for(index, tick)`
## (de test geeft `boss_bot.gd`); leeg = de stap in S8 is lopen.
var boss_input: Callable
## Per keerpunt: haalde de springer de samenwerkingsactie (true) of nam hij de langzame lijn.
var lines := {}
## Per keerpunt: de springer (index) en de tick van de bounce of lancering.
var actions := {}
## Ticks waarop de boss-bot het overnam en waarop de boss verslagen was.
var boss_from := -1
var boss_until := -1
## Stuits van P2 op een Dwaallicht met een merk van P1 (V-01e in co-op).
var p2_stuit_combos := 0

var _w: Node
var _d := 60
var _tick := 0
var _boss_bot: RefCounted = null


func _init(wijk: Node, d: int, start_room: StringName = &"S1", lus := false) -> void:
	_w = wijk
	_d = d
	p1_input = _seat(1, start_room, lus)
	p2_input = _seat(2, start_room, lus)


func _seat(index: int, start_room: StringName, lus: bool) -> Seat:
	var s := Seat.new()
	s.duo = weakref(self)
	s.index = index
	var view := View.new()
	view.w = _w
	view.index = index
	s.bot = Bot.new(view, _d, start_room)
	s.bot.lus = lus
	return s


## Naam van de stap van een stoel (debug, tests).
func leg_name(index: int) -> String:
	return (p1_input if index == 1 else p2_input).bot.leg_name()


# --- Hulpjes ---

func _body(s: Seat) -> CharacterBody2D:
	return _w.p1 if s.index == 1 else _w.p2


func _other(s: Seat) -> Seat:
	return p2_input if s.index == 1 else p1_input


func _room_of(s: Seat) -> StringName:
	return s.bot._room.room


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


## Heen en weer tussen `center − half` en `center + half` (MP-1: niet stil).
func _patrol(s: Seat, center: float, half: float) -> int:
	var x := _body(s).position.x
	if x >= center + half:
		s.patrol_dir = -1
	elif x <= center - half:
		s.patrol_dir = 1
	return _walk(s.patrol_dir)


## Wachten waar je bent: heen en weer rond de plek waar het wachten begon.
func _wait_here(s: Seat) -> int:
	var b := _body(s)
	if not b.motor.on_floor:
		return 0
	if is_nan(s.anchor):
		s.anchor = b.position.x
	return _patrol(s, s.anchor, WAIT_PX)


## Wachten op de ander (`_wait_here`), en dat laten zien.
func _wait(s: Seat) -> int:
	s.waiting = true
	return _wait_here(s)


## Geef de stap terug aan de solo-bot (de langzame lijn of de rest van de stap).
func _hand_over(s: Seat, bot_sub: String) -> void:
	s.sub = "solo"
	s.bot.sub = bot_sub
	s.bot._stuck = 0
	s.bot._last_x = INF
	s.bot._since = 0


func _solo(s: Seat, tick: int) -> int:
	return s.bot.sample(tick)


## Bits die het duo zelf koos: ook in het spoor van de solo-bot (zijn `_tap`).
func _own(s: Seat, bits: int) -> int:
	s.bot.recorded.append(bits)
	s.bot._prev = bits
	return bits


# --- Beslissing per tick ---

func _decide(s: Seat, tick: int) -> int:
	_tick = tick
	var b := _body(s)
	if b == null or _w.run_over:
		return 0
	if s.index == 2:
		if b.dissolved:
			s.was_dissolved = true
			return 0
		if s.was_dissolved:
			# C-08: P2 staat weer naast P1; hij pakt de stap van P1 op.
			s.was_dissolved = false
			s.bot.leg = p1_input.bot.leg
			s.bot.sub = ""
			s.leg_seen = s.bot.leg
			s.done = p1_input.done
			s.sub = ""
			s.anchor = NAN
	s.waiting = false
	var x := b.position.x
	s.stuck = s.stuck + 1 if absf(x - s.last_x) < 0.5 else 0
	s.last_x = x
	_note_leg(s, tick)
	s.since += 1
	var bits := _decide_leg(s, tick, b)
	if s.waiting:
		var here := _room_of(s)
		s.wait_ticks[here] = int(s.wait_ticks.get(here, 0)) + 1
	# De stap kan in deze tick afgerond zijn: de ander ziet dan meteen de nieuwe stap.
	_note_leg(s, tick)
	return bits


func _note_leg(s: Seat, tick: int) -> void:
	if s.bot.leg == s.leg_seen:
		return
	if s.leg_seen >= 0:
		s.done += 1
	s.leg_seen = s.bot.leg
	s.sub = ""
	s.since = 0
	s.started = tick
	s.anchor = NAN


func _decide_leg(s: Seat, tick: int, b: CharacterBody2D) -> int:
	var name: String = s.bot.leg_name()
	if name == "":
		return _own(s, 0)
	var spec: Array = s.bot._legs[s.bot.leg]
	var kind: String = spec[1]
	var o := _other(s)
	var coop_leg := SPRINGER.has(name)
	var fresh: bool = s.sub == "" and s.bot.sub == ""
	# Op de ander blijven staan buiten een samenwerkingsactie: eraf stappen.
	if _on_partner(s) and (not coop_leg or s.sub == "solo") and kind != "end":
		return _own(s, _walk(1 if b.position.x >= _body(o).position.x else -1))
	# De trap naar het plein en terug (v0.8.6, #292): de tweede houdt twee treden afstand.
	if (name == "S9-trap" or name == "S9-trap-af") and _trap_hold(s, name):
		return _own(s, _wait(s))
	# Trap 2: P1 gaat terug naar de trap als P2 hem met zijn slagen vol maakt (P2 als de echo).
	if s.index == 1 and name == "S6-trap2" and s.bot.sub == "gang" and s.bot._past_gang() and _p2_fills_trap_2():
		s.bot._next_leg(true)
		return _own(s, L)
	# Samen stuiten: P1 wacht tot P2 vlak achter hem is, P2 begint als P1 springt.
	# (Beide lopen daar naar links.)
	if name in TOGETHER and fresh and not _other_gone(o):
		var behind: float = _body(p2_input).position.x - _body(p1_input).position.x
		if s.index == 1 and not o.bot.leg_done.has(name) and not (o.bot.leg == s.bot.leg and behind <= TOGETHER_PX) and not o.waiting:
			return _own(s, _wait(s))
		if s.index == 2 and p1_input.bot.leg == s.bot.leg and behind < 30.0:
			return _own(s, _wait(s))
	# Samen blijven: wie voor is en ver weg, wacht waar hij staat (leiband C-07, ontladen C-06).
	if fresh and s.done > o.done and not _other_gone(o) and not o.waiting and b.motor.on_floor and _far(b, _body(o)) \
			and not name in TRAP_LEGS:
		return _own(s, _wait(s))
	if fresh and s.sub == "" and not is_nan(s.anchor) and not _far(b, _body(o)):
		s.anchor = NAN
	if coop_leg and s.sub != "solo":
		if kind == "b4":
			return _own_or_solo(s, _launch(s, name, tick), tick)
		return _own_or_solo(s, _lift(s, spec, name, tick), tick)
	match kind:
		"fight":
			return _own(s, _fight(s, false))
		"arena":
			return _own(s, _fight(s, true))
		"kanaal":
			if s.index == 2:
				return _own_or_solo(s, _follow_stuit(s, &"S7", Layout.S7_LOW, tick), tick)
		"stuit9":
			if s.index == 2:
				return _own_or_solo(s, _follow_stuit(s, &"S9", Layout.S9_KADE, tick), tick)
		"end":
			if boss_input.is_valid() and _room_of(s) == &"S8":
				return _own(s, _boss(s, tick))
	return _solo(s, tick)


## De trap naar het plein (`S9-trap`) en terug (`S9-trap-af`): moet `s` nog wachten tot de
## ander twee treden verder is? Omhoog gaat P1 eerst (P2 wacht op de vloer van S9); omlaag
## gaat wie het dichtst bij de trap is eerst (de ander loopt door en wacht pas aan de rand).
func _trap_hold(s: Seat, name: String) -> bool:
	var o := _other(s)
	if _other_gone(o) or o.bot.leg_done.has(name):
		return false
	var b := _body(s)
	var ob := _body(o)
	if name == "S9-trap":
		if s.index != 2 or not _on_level(s, Layout.S9_DOOR_FLOOR):
			return false
		return ob.position.y > Layout.S9_DOOR_FLOOR - Layout.HALF_H - TRAP_GAP
	# Omlaag: pas wachten vlak voor de trap (de schacht links van het plein), niet waar je staat.
	if not _on_level(s, Layout.S6_FLOOR) or o.bot.leg_name() != name \
			or b.position.x > Layout.ROOMS[&"S6"].position.x + TRAP_HOLD_DX:
		return false
	var plaza := Layout.S6_FLOOR - Layout.HALF_H
	var ahead: bool = ob.position.y > plaza + 1.0 or ob.position.x < b.position.x \
		or (ob.position.x == b.position.x and s.index == 2)
	return ahead and ob.position.y < plaza + TRAP_GAP


## Trap 2: maken de schoepen die P2 in deze doorgang nog voor zich heeft hem vol (LM-03; zoals
## `_will_fill_trap_2` van de solo-bot met de echo)?
func _p2_fills_trap_2() -> bool:
	var g: Node = _w.gemaal
	var o := p2_input
	if g == null or _other_gone(o) or o.bot.leg_name() != "S6-trap2" or o.bot.sub != "gang" or o.bot._pass_dir != 1:
		return false
	var x := _body(o).position.x
	var pending := 0
	for i in Layout.PUMP_VANES.size():
		if not o.bot._struck.has(i) and (Layout.PUMP_VANES[i] as Vector2).x - x >= -6.0:
			pending += 1
	return int(g.fill) + mini(pending * Gemaal.per_stroke(), int(_w.meter.value)) >= 2 * Gemaal.MAX


## Zo ver uit elkaar dat de voorste wacht.
func _far(a: Node2D, b: Node2D) -> bool:
	if b == null:
		return false
	return absf(a.position.x - b.position.x) > FAR_X or absf(a.position.y - b.position.y) > FAR_Y


## -1 = de solo-bot neemt deze tick.
func _own_or_solo(s: Seat, bits: int, tick: int) -> int:
	if bits < 0:
		return _solo(s, tick)
	return _own(s, bits)


## De ander is niet meer te verwachten (opgelost, of de run is klaar).
func _other_gone(o: Seat) -> bool:
	var b := _body(o)
	return b == null or (o.index == 2 and b.dissolved)


# --- Keerpunten: bounce op de ander (C-09, C-10) ---

## [wall, floor, up, away, z, spot, b3]
func _lift_params(spec: Array) -> Dictionary:
	if spec[1] == "b3":
		return {"wall": Layout.B3_BLOCK_LEFT + Layout.b3_width(_d), "floor": Layout.S2_FLOOR, "up": Layout.S2_MID,
			"away": -1, "z": 0.0, "spot": B3_SPOT, "wait": B3_SPOT - PATROL_PX - 50.0, "b3": true}
	var tp: Dictionary = Layout.turn_points(_d)[spec[2]]
	var z: float = tp.get("z", Layout.keerzone(_d))
	var away: int = -int(tp["side"])
	var spot_d := maxf(70.0, z - 40.0)
	# Waar de springer wacht tot de drager er is: verder van de wand, maar op een richel van B2
	# (`480 − Z` breed) niet over de rand.
	var wait_d := spot_d + PATROL_PX + 50.0
	if tp.has("z"):
		wait_d = minf(wait_d, Layout.b2_ledge(_d) - 30.0)
	return {"wall": tp["wall"], "floor": tp["floor"], "up": tp["up"], "away": away, "z": z,
		"spot": float(tp["wall"]) + away * spot_d, "wait": float(tp["wall"]) + away * wait_d, "b3": false}


## Staat de springer op het volgende niveau, voorbij de keerzone (B1, B2) of op de galerij (B3)?
func _lift_landed(s: Seat, p: Dictionary) -> bool:
	if not _on_level(s, p["up"]):
		return false
	var x := _body(s).position.x
	if p["b3"]:
		return x < Layout.B3_GALLERY_TIP + Layout.HALF_W
	return absf(x - float(p["wall"])) > float(p["z"])


func _lift(s: Seat, spec: Array, name: String, tick: int) -> int:
	var p := _lift_params(spec)
	if SPRINGER[name] == s.index:
		return _lift_springer(s, p, name, tick)
	return _lift_drager(s, p, name)


func _lift_drager(s: Seat, p: Dictionary, name: String) -> int:
	var o := _other(s)
	var same: bool = o.bot.leg == s.bot.leg
	match s.sub:
		"":
			if not _on_level(s, p["floor"]):
				return -1
			var go := _go_to(s, p["spot"])
			if go != 0:
				return go
			s.sub = "wait"
			s.since = 0
			return 0
		"wait":
			if same and o.sub == "air":
				s.sub = "hold"
				return 0
			# De springer is er al voorbij, of komt niet: de langzame lijn.
			if (not same and o.done > s.done) or (same and o.sub == "solo") or s.since > LIFT_GIVE_UP or _other_gone(o):
				_hand_over(s, "")
				return -1
			return _patrol(s, p["spot"], PATROL_PX)
		"hold":
			# Stil tot de springer van de plank af is; dan weer heen en weer tot hij boven is (mist
			# hij, dan springt hij opnieuw op de drager).
			if not same or o.sub == "solo":
				_hand_over(s, "")
				return -1
			if (o.sub == "bounce" and not _on_partner(o)) or o.sub == "":
				s.sub = "wait"
				return _patrol(s, p["spot"], PATROL_PX)
			return 0
	return -1


func _lift_springer(s: Seat, p: Dictionary, name: String, tick: int) -> int:
	var b := _body(s)
	var o := _other(s)
	var ob := _body(o)
	var away: int = p["away"]
	if s.sub != "" and _lift_landed(s, p):
		lines[name] = true
		s.bot._next_leg(true)
		return 0
	match s.sub:
		"":
			if not _on_level(s, p["floor"]):
				return -1
			var ready: bool = ob != null and o.bot.leg == s.bot.leg and o.sub in ["wait", "hold"]
			if _other_gone(o) or (o.bot.leg == s.bot.leg and o.sub == "solo") or (o.bot.leg != s.bot.leg and o.done > s.done):
				# Geen drager (meer): de langzame lijn (C-15).
				lines[name] = false
				_hand_over(s, "")
				return -1
			if not ready:
				return _patrol(s, p["wait"], WAIT_PX)
			var dx: float = ob.position.x - b.position.x
			if absf(dx) > RUNUP_PX:
				return _go_to(s, ob.position.x)
			s.sub = "air"
			s.since = 0
			return (_walk(1 if dx > 0.0 else -1) if absf(dx) > 2.0 else 0) | _tap(s, J)
		"air":
			if _on_partner(s):
				s.sub = "bounce"
				s.since = 0
				actions[name] = [s.index, tick]
				return _walk(away) | _tap(s, J)
			if s.since > 2 and b.motor.on_floor and not _on_partner(s):
				# Gemist (de vloer, of een trede): opnieuw.
				s.sub = ""
				return 0
			return _go_to(s, ob.position.x)
		"bounce":
			if _on_level(s, p["up"]):
				# Op de trede van 90 binnen de keerzone (lange staart): de rest is de langzame lijn.
				lines[name] = true
				_hand_over(s, "slow")
				return -1
			if _on_level(s, p["floor"]):
				s.sub = ""
				return 0
			if p["b3"] and b.motor.velocity.y >= 0.0 and b.position.x > Layout.B3_GALLERY_TIP + 4.0 and b.motor.dash_ready:
				return L | _tap(s, DASH)
			return _walk(away)
	return -1


# --- B4: lancering over de kloof (C-11) ---

func _launch(s: Seat, name: String, tick: int) -> int:
	var b := _body(s)
	var o := _other(s)
	var ob := _body(o)
	var same: bool = o.bot.leg == s.bot.leg
	if SPRINGER[name] != s.index:
		# Drager.
		match s.sub:
			"":
				if not _on_level(s, Layout.S4_FLOOR):
					return R
				var springer_near: bool = same and _on_level(o, Layout.S4_FLOOR) and ob.position.x > B4_CALL_X
				if springer_near:
					s.sub = "to_bolder"
					return R
				if (not same and o.done > s.done) or _other_gone(o):
					_hand_over(s, "slow")
					return -1
				if b.position.x < B4_WAIT_X - PATROL_PX:
					return R
				return _patrol(s, B4_WAIT_X, PATROL_PX)
			"to_bolder":
				# AANVAL slaan en vasthouden, met het gezicht naar de kloof, tegen de bolder.
				if b.position.x >= Layout.B4_TURN_X - 0.5 or s.stuck >= 1:
					s.sub = "hold"
					s.since = 0
				return R | A
			"hold":
				if not same or o.sub == "launched" or o.sub == "solo" or s.since > B4_HOLD_GIVE_UP:
					_hand_over(s, "slow")
					return -1
				return R | A
		return -1
	# Springer.
	if (s.sub == "launched" or s.sub == "air") and b.position.x > Layout.B4_FAR_EDGE + 20.0 and _on_level(s, Layout.S4_FLOOR):
		lines[name] = s.sub == "launched"
		s.bot._next_leg(s.sub == "launched")
		return R
	match s.sub:
		"":
			if _other_gone(o) or (same and o.sub == "solo") or (not same and o.done > s.done):
				lines[name] = false
				_hand_over(s, "slow")
				return -1
			if not _on_level(s, Layout.S4_FLOOR):
				return R
			var ready: bool = same and o.sub == "hold" and ob.carrier_in_stance(tick)
			if not ready:
				if b.position.x < B4_SPRINGER_WAIT_X - WAIT_PX:
					return R
				return _patrol(s, B4_SPRINGER_WAIT_X, WAIT_PX)
			var dx: float = ob.position.x - b.position.x
			if dx > RUNUP_PX:
				return R
			s.sub = "air"
			s.since = 0
			return (R if dx > 2.0 else 0) | _tap(s, J)
		"air":
			if _launched(b):
				s.sub = "launched"
				actions[name] = [s.index, tick]
				return R
			if s.since > 2 and _on_level(s, Layout.S4_FLOOR):
				s.sub = ""
				return 0
			return _go_to(s, ob.position.x)
		"launched":
			# Te kort (in de kloof): de langzame lijn.
			if b.motor.on_floor and b.motor.support != Motor.Support.SHADOW_BODY \
					and b.position.y > Layout.S4_FLOOR - Layout.HALF_H + 1.5:
				lines[name] = false
				_hand_over(s, "slow")
				return -1
			return R
	return -1


# --- Gevechten: merk-combo's (C-12) ---

## Zoals `_leg_fight` van de solo-bot, met de doelkeuze van `flow_duo.gd`.
func _fight(s: Seat, arena: bool) -> int:
	var b := _body(s)
	var here := _room_of(s)
	if arena and here == &"S4":
		s.bot._next_leg(false)
		return R
	if not b.motor.on_floor:
		return _walk(s.patrol_dir) if s.sub == "patrol" else (L if here == &"S2" or here == &"S9" else R)
	var target := _fight_target(s, here)
	if target == null:
		if _no_enemies(here) and (not arena or _w.wave >= 2):
			if arena:
				return R
			s.bot._next_leg(false)
			return 0
		s.sub = "patrol"
		return s.bot._patrol(here)
	s.sub = "hit"
	var dx: float = target.position.x - b.position.x
	var rel: float = dx * b.motor.facing
	if rel >= 4.0 and rel <= 32.0 and absf(target.position.y - b.position.y) < 20.0:
		if _tick - s.last_attack >= ATTACK_EVERY:
			s.last_attack = _tick
			return _tap(s, A)
		return 0
	if absf(dx) <= 14.0:
		var away := -1 if dx > 0.0 else 1
		var bounds: Vector2 = s.bot._bounds(here)
		if b.position.x + away * 20.0 < bounds.x or b.position.x + away * 20.0 > bounds.y:
			away = -away
		return _walk(away)
	return _walk(1 if dx > 0.0 else -1)


func _foes(s: Seat, here: StringName) -> Array:
	var b := _body(s)
	var out: Array = []
	for e in _w.enemies_in(here):
		if e.enemy_type == SliceEnemy.Type.DWAALLICHT or absf(e.position.y - b.position.y) > 40.0:
			continue
		out.append(e)
	return out


func _no_enemies(here: StringName) -> bool:
	for e in _w.enemies_in(here):
		if e.enemy_type != SliceEnemy.Type.DWAALLICHT:
			return false
	return true


func _fight_target(s: Seat, here: StringName) -> Node2D:
	var b := _body(s)
	var me := "p%d" % s.index
	var combat = _w.sim.combat
	var foes := _foes(s, here)
	var o := _other(s)
	var ob := _body(o)
	var partner_here: bool = not _other_gone(o) and _room_of(o) == here and absf(ob.position.y - b.position.y) <= 40.0
	var best: Node2D = null
	var best_d := INF
	# (1) een merk van de ander: laten knallen.
	for e in foes:
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
	if partner_here:
		taken = _unmarked_nearest(foes, ob.position.x, null)
		if taken != null and absf(taken.position.x - ob.position.x) > absf(taken.position.x - b.position.x):
			taken = null
	best = _unmarked_nearest(foes, b.position.x, taken)
	if best != null:
		return best
	# (3) alleen nog eigen merken en de ander is er niet: zelf afmaken (zonder pantser).
	if not partner_here:
		for e in foes:
			if e.armor_intact:
				continue
			var d: float = absf(e.position.x - b.position.x)
			if d < best_d:
				best = e
				best_d = d
	return best


func _unmarked_nearest(foes: Array, from_x: float, skip: Node2D) -> Node2D:
	var best: Node2D = null
	var best_d := INF
	for e in foes:
		if e == skip or _w.sim.combat.mark_on(e) != null:
			continue
		var d: float = absf(e.position.x - from_x)
		if d < best_d:
			best = e
			best_d = d
	return best


# --- Stuiten met de ander (V-01b, V-01e) ---

## P2 in het kanaal (S7) of boven de kade (S9): achter P1 aan; in de lucht een
## neerslag op het Dwaallicht met een merk van P1 (het knalt), anders op het
## eerstvolgende. -1 = de solo-bot (nog niet in de lucht, of geland).
func _follow_stuit(s: Seat, here: StringName, floor_top: float, tick: int) -> int:
	var b := _body(s)
	if b.motor.on_floor or s.bot.sub != "air":
		return -1
	var target := _wisp_for_p2(here)
	if target == null:
		return -1
	var dx: float = target.position.x - b.position.x
	var feet := b.position.y + Layout.HALF_H
	var top: float = target.position.y - 8.0
	if absf(dx) <= 10.0 and feet > top - 20.0 and feet < top + 14.0 and tick - s.bot._last_attack >= 4:
		s.bot._last_attack = tick
		s.bot.stuits += 1
		var mark = _w.sim.combat.mark_on(target)
		if mark != null and mark.setter == "p1":
			p2_stuit_combos += 1
		return DOWN | _tap(s, A)
	if dx < -2.0:
		return L
	if dx > 2.0:
		return R
	return 0


## Het eerstvolgende Dwaallicht naar links: met een merk van P1 eerst.
func _wisp_for_p2(here: StringName) -> Node2D:
	var b := _body(p2_input)
	var best: Node2D = null
	for e in _w.enemies_in(here):
		if e.enemy_type != SliceEnemy.Type.DWAALLICHT or e.position.x > b.position.x + 12.0:
			continue
		var mark = _w.sim.combat.mark_on(e)
		if mark != null and mark.setter == "p2":
			continue
		if mark == null and e.is_stunned(_tick):
			continue
		if best == null or e.position.x > best.position.x:
			best = e
	return best


# --- S8: de Gemaalmeester ---

func _boss(s: Seat, tick: int) -> int:
	if _w.is_boss_defeated():
		if boss_until < 0:
			boss_until = tick
		s.bot._next_leg(false)
		return L
	if _w.boss == null:
		return L
	if _boss_bot == null:
		_boss_bot = boss_input.call(_w.sim, _w.boss)
		boss_from = tick
	if s.index == 2 and _w.boss.state == _w.boss.State.IDLE:
		# Vóór BOSS_START: de arena in, rechts van het midden (de boss-bot laat P2 dan naar rechts lopen).
		return _go_to(s, Layout.ARENA_WALL_L + _w.boss.middle() + 40.0)
	return _boss_bot.sample_for(s.index, tick)
