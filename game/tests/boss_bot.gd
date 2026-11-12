extends RefCounted
## De gescripte geoefende boss-run tegen de Gemaalmeester (T8b B-9; slice-vijanden-en-boss.md v0.1.2
## §3, §6), naar het voorbeeld van `levels/flowkamer/flow_bot.gd`.
##
## Twee inputbronnen (`p1_source`, `p2_source`, elk met `sample(tick) -> int`) die per tick kijken
## waar P1, P2, de echo en de boss staan en daarop de knoppen kiezen. De bot leest alleen wat een
## speler ziet (posities, de tell en het vlak van de aanval, schot/kern, de kant en de stand van het
## rad); dezelfde D en dezelfde start geven dus dezelfde input. `recorded` houdt de bits per stoel bij.
##
## Werkaanname (Gameplay Programmer, kader §5): de "scripted geoefende run" is deze bot.
## - **Fase 1** (§3.4): P1 staat links van de ketel (kijkt naar rechts) en slaat om de 20 ticks (de
##   AANVAL-cooldown); solo knalt de echo het merk, in co-op slaat P2 rechts van de ketel 10 ticks
##   later (merk-combo). P1 springt over elke pompslag (afzet 16 ticks vóór het actieve vlak) en slaat
##   een add die vlak achter hem staat.
## - **Fase 2 solo** (§3.5): keren tegen de muur aan de kant van het rad en bouncen op de echo; bij
##   de bounce één slag als het aanvalsvlak boven 100 px is (`strikes_per_bounce`, §3.5: "1 treffer
##   per bounce"). Vóór elke keer een aanloop van `2D + 24` px naar de muur (D + 12 ticks), zodat
##   de echo achter P1 op de vloer loopt. Met `use_launch` de lancering met neerslag (B-8 (3)).
## - **Fase 2 co-op**: P2 gaat onder het midden van het rad staan; P1 springt op hem, bouncet, slaat,
##   valt terug en wordt gevangen (C-13), slaat weer.
## - **Wankel** (§3.6): één slag op de merkplek; solo knalt de echo, in co-op slaat P2; P1 blijft
##   lopen tot de boss verslagen is.
## Geen ontwijken in fase 2: een sprong onderweg verstoort de aanloop van de keer-run (de echo speelt
## hem na) en de sprong op P2. De pompslag en de zwiep raken P1 dan soms; de run telt de treffers per
## deel (bekende beperking, zie de PR).

const InputBits = preload("res://scripts/input/input_bits.gd")
const Motor = preload("res://scripts/echo/motor.gd")
const Tuning = preload("res://scripts/echo/tuning.gd")
const EnemyData = preload("res://scripts/combat/enemy_data.gd")
const TailEcho = preload("res://scripts/echo/tail_echo.gd")
const Gemaalmeester = preload("res://scripts/combat/gemaalmeester.gd")

const L := InputBits.LEFT
const R := InputBits.RIGHT
const J := InputBits.JUMP
const A := InputBits.ATTACK
const DOWN := InputBits.DOWN
const DASH := InputBits.DASH

## E-10: tussen twee AANVAL-events minstens zo veel ticks (`game_events.gd`).
const ATTACK_COOLDOWN := 20
## Fase 1: P1 en P2 staan zo ver van het midden van de ketel (aanvalsvlak 8–28 px vóór het lichaam).
const KETEL_OFFSET := 36.0
const KETEL_WINDOW := 6.0
## Pompslag fase 1 ontwijken: afzet zo veel ticks vóór het actieve vlak (voeten > 24 px op 6–34
## ticks na de afzet; §3.4: venster 24 ticks).
const DODGE_LEAD := 16
## Afstand tot de echo waarop P1 na het keren afzet (gdd §4.3: ± 130 px).
const JUMP_ON_ECHO_PX := 130.0
## Slaan op het rad vanaf deze hoogte van de voeten (vlak boven 100 px vanaf 77, §3.5).
const STRIKE_FEET := 78.0
## Neerslag op het rad: voeten tussen deze hoogtes (vlak 20 px onder de voeten, rad op 100–140).
const NEERSLAG_LOW := 102.0
const NEERSLAG_HIGH := 158.0
## Lancering: zo ver van het midden van het rad staat de houding (de lancering vliegt 4 px/tick).
const LAUNCH_BEFORE_RAD := 70.0
const LAUNCH_HOLD := 32
## Co-op: P1 springt op P2 vanaf hooguit zo ver (een sprong haalt ± 66 px tot op 30 px hoogte).
const COOP_JUMP_PX := 56.0


## Eén stoel: geeft de bits van speler `index`.
class Seat:
	extends RefCounted
	var bot: RefCounted
	var index := 1

	func _init(p_bot: RefCounted, p_index: int) -> void:
		bot = p_bot
		index = p_index

	func sample(tick: int) -> int:
		return bot.sample_for(index, tick)


var p1_source: Seat
var p2_source: Seat
## B-8 (2), late bot: zo veel ticks blijft P1 op de echo of P2 staan vóór de bounce.
var bounce_delay := 0
## Slagen per bounce. §3.5 rekent met 1; de geoefende run slaat er 2: de AANVAL-cooldown (20 ticks)
## past in het venster van 28 ticks boven 100 px (werkaanname Gameplay Programmer, zie de PR).
var strikes_per_bounce := 2
## Solo fase 2 met de lancering + neerslag in plaats van keren (B-8 (3)).
var use_launch := false
## C-16 (2): P2 slaat nooit.
var p2_strikes := true
## Fase 1: over de pompslag springen.
var dodge := true
## De bits per stoel, vanaf de eerste `sample`.
var recorded := {1: PackedInt32Array(), 2: PackedInt32Array()}
## Huidige stap van P1 (debug, tests).
var sub := ""

var _sim: Node
var _boss: Gemaalmeester
var _prev := {1: 0, 2: 0}
var _last_attack := {1: -1000, 2: -1000}
var _tick := 0
var _last_x := INF
var _stuck := 0
var _side := 0
var _plank_ticks := 0
var _strikes_air := 0
var _stance_tick := -1
var _stance_x := 0.0
var _wander := 1
var _echo_last_x := NAN
var _since := 0


func _init(sim: Node, boss: Gemaalmeester) -> void:
	_sim = sim
	_boss = boss
	p1_source = Seat.new(self, 1)
	p2_source = Seat.new(self, 2)


func sample_for(index: int, tick: int) -> int:
	_tick = tick
	var bits := _decide_p1() if index == 1 else _decide_p2()
	recorded[index].append(bits)
	if bits & A and not (_prev[index] & A):
		_last_attack[index] = tick
	_prev[index] = bits
	return bits


# --- waarnemen ------------------------------------------------------------------

func _p(index: int) -> CharacterBody2D:
	return _sim.get_player(index)


func _coop() -> bool:
	var p2 = _p(2)
	return p2 != null and not p2.dissolved


func _echo() -> Node2D:
	for e in _sim.echoes:
		if e is TailEcho and e.is_present():
			return e
	return null


func _echo_ready() -> bool:
	var e := _echo()
	return e != null and not e.in_merksprong


## Arena-x (vanaf de linkermuur) en hoogte van de voeten boven de vloer.
func _ax(node: Node2D) -> float:
	return node.global_position.x - _boss.global_position.x


func _feet(node: Node2D) -> float:
	return _boss.global_position.y - (node.global_position.y + Tuning.body_size().y * 0.5)


func _d() -> int:
	return _boss.tail_ticks()


func _on_floor(p: CharacterBody2D) -> bool:
	return p.motor.on_floor and p.motor.support != Motor.Support.SHADOW_BODY


func _on_plank(p: CharacterBody2D) -> bool:
	return p.motor.on_floor and p.motor.support == Motor.Support.SHADOW_BODY


func _tap(index: int, bit: int) -> int:
	return 0 if _prev[index] & bit else bit


func _walk(dir: int) -> int:
	return R if dir > 0 else (L if dir < 0 else 0)


func _attack_ready(index: int) -> bool:
	return _tick - int(_last_attack[index]) >= ATTACK_COOLDOWN and not (_prev[index] & A)


## Ligt er een merk van P1 op de ketel (Wankel, merk-combo)?
func _ketel_mark_by(setter: String) -> bool:
	var mark = _sim.combat.mark_on(_boss.ketel)
	return mark != null and mark.setter == setter


# --- P1 --------------------------------------------------------------------------

func _decide_p1() -> int:
	var p := _p(1)
	if p == null or _boss.is_defeated():
		return 0
	_update_stuck(p)
	if _boss.state == _boss.State.IDLE:
		return _walk(1)
	if _boss.is_wankel() or _boss.is_finisher_running():
		return _wankel_p1(p)
	if _boss.phase == Gemaalmeester.Phase.ONE:
		return _phase1_p1(p)
	if _coop():
		return _phase2_coop_p1(p)
	if use_launch:
		return _phase2_launch(p)
	return _phase2_turn(p)


func _update_stuck(p: CharacterBody2D) -> void:
	var x := p.position.x
	_stuck = _stuck + 1 if absf(x - _last_x) < 0.5 else 0
	_last_x = x
	_since += 1


## Fase 1: links van de ketel, slaan om de 20 ticks, over de pompslag springen, adds achter je slaan.
func _phase1_p1(p: CharacterBody2D) -> int:
	var x := _ax(p)
	var bits := 0
	var mid := _boss.middle()
	var stand := mid - KETEL_OFFSET
	var face := 1
	# Een add vlak achter P1 (die de ketel niet raakt): omdraaien en slaan.
	for add in _boss.adds:
		if add.alive and absf(_ax(add) - x) <= 34.0 and signf(_ax(add) - x) != float(face):
			face = -1 if _ax(add) < x else 1
	var move := _approach(p, stand, face)
	if move != 0:
		bits |= move
	elif _attack_ready(1):
		bits |= A
	if dodge and _should_dodge(p):
		bits |= _tap(1, J)
	return bits


## Naar `stand` ± KETEL_WINDOW met de kijkrichting `face`; 0 = staat goed. Een stap om te draaien
## blijft binnen het venster (anders eerst een stap terug), zodat het niet heen en weer gaat.
func _approach(p: CharacterBody2D, stand: float, face: int) -> int:
	var x := _ax(p)
	if x < stand - KETEL_WINDOW:
		return R
	if x > stand + KETEL_WINDOW:
		return L
	if p.motor.facing == face:
		return 0
	var step := 2.0 * face
	if absf(x + step - stand) <= KETEL_WINDOW:
		return _walk(face)
	return _walk(-face)


## Pompslag (B-6): afzetten `DODGE_LEAD` ticks vóór het actieve vlak, als het vlak P1 raakt.
func _should_dodge(p: CharacterBody2D) -> bool:
	if _boss.attack_kind != "pomp" or not _boss.is_telling() or not _on_floor(p):
		return false
	if _boss.windup_end_tick() - _tick != DODGE_LEAD:
		return false
	var box: Rect2 = _boss.attack_box
	return p.global_position.x + 8.0 > box.position.x and p.global_position.x - 8.0 < box.end.x


## Wankel en finisher: een slag op de merkplek als er geen merk op ligt (in co-op pas als P2
## klaarstaat), daarna blijven lopen.
func _wankel_p1(p: CharacterBody2D) -> int:
	var x := _ax(p)
	var stand := _boss.middle() - KETEL_OFFSET
	if _boss.is_wankel() and _sim.combat.mark_on(_boss.ketel) == null:
		var move := _approach(p, stand, 1)
		if move != 0:
			return move
		if not _on_floor(p):
			return 0
		if _coop() and absf(_ax(_p(2)) - (_boss.middle() + KETEL_OFFSET)) > KETEL_WINDOW:
			return 0
		if _attack_ready(1):
			return A
		return 0
	return _wander_bits(p, stand)


## Heen en weer lopen rond `around` (± 30 px): geen stilstand (MP-1).
func _wander_bits(p: CharacterBody2D, around: float) -> int:
	var x := _ax(p)
	if x > around + 30.0 or x > _boss.arena_width - 20.0:
		_wander = -1
	elif x < around - 30.0 or x < 20.0:
		_wander = 1
	return _walk(_wander)


## De kant waar P1 heen moet: tijdens het trillen al de andere.
func _target_side() -> int:
	if _boss.rad_state == Gemaalmeester.RadState.SHAKING:
		return -_boss.rad_side
	return _boss.rad_side


func _wall_x(side: int) -> float:
	return 0.0 if side < 0 else _boss.arena_width


## Fase 2 solo: keren tegen de muur, op de echo bouncen, slaan boven 100 px. Per keer plant P1 de
## kant en het moment (`_plan`): de eerste keer-run waarvan de slag nog in een venster van het rad
## valt (180 ticks per kant, ervan uitgaand dat het niet eerder wegdraait). Haalt hij de kant waar
## het rad nu heen gaat niet meer, dan wacht hij aan de kant waar hij is tot het terugkomt.
func _phase2_turn(p: CharacterBody2D) -> int:
	var x := _ax(p)
	if sub == "":
		if not _on_floor(p):
			return _steer(p, _boss.rad_x(_side if _side != 0 else _target_side()))
		_plan(p)
		sub = "out"
	var side := _side
	var wall := _wall_x(side)
	var inward := -side
	var dist := absf(x - wall)
	var need := 2.0 * _d() + 24.0
	var rad_cx := _boss.rad_x(side)
	match sub:
		"out":
			if dist >= need:
				sub = "hold"
			else:
				return _walk(inward) | _dash_if(p, need - dist > 60.0)
			return _phase2_turn(p)
		"hold":
			# Wachten tot het geplande moment, in beweging tussen `need` en `need + 30` px.
			if _tick >= _turn_at - int((dist - 9.0) / 2.0):
				sub = "in"
				return _walk(side)
			if dist >= need + 30.0:
				_wander = side
			elif dist <= need + 2.0:
				_wander = inward
			return _walk(_wander)
		"in":
			if dist <= Tuning.body_size().x * 0.5 + 1.0 and _stuck >= 1:
				sub = "back"
				_since = 0
				return _walk(inward)
			# Dashen mag alleen als er niet gewacht wordt, en tot de aanloop van `need` px begint.
			return _walk(side) | _dash_if(p, _race and dist > need)
		"back":
			if dist > need + 40.0:
				# De echo kwam niet: opnieuw plannen.
				sub = ""
				return 0
			if _echo_ready():
				var e := _echo()
				var ahead := (e.position.x - p.position.x) * inward
				if absf(e.position.y - p.position.y) < 1.5 and ahead > 0.0 and ahead <= JUMP_ON_ECHO_PX:
					sub = "air"
					_since = 0
					_plank_ticks = 0
					return _walk(inward) | _tap(1, J)
			return _walk(inward)
		"air":
			if _on_plank(p):
				if _plank_ticks < bounce_delay:
					_plank_ticks += 1
					return 0
				_plank_ticks = 0
				sub = "bounce"
				_strikes_air = 0
				return _tap(1, J)
			if _on_floor(p):
				sub = ""
				return 0
			return _steer_to_echo(p, inward)
		"bounce":
			if p.move_events & Motor.EV_CATCH:
				_strikes_air = 0
			if _on_plank(p):
				_strikes_air = 0
				return _tap(1, J)
			if _on_floor(p):
				sub = ""
				return 0
			var bits := _steer(p, rad_cx)
			if _boss.is_rad_hittable() and _feet(p) >= STRIKE_FEET and absf(x - rad_cx) <= 30.0 \
					and _strikes_air < strikes_per_bounce and _attack_ready(1):
				_strikes_air += 1
				bits |= A
			return bits
	return 0


var _turn_at := 0
var _race := true


## Kiest de kant (`_side`) en de keertick (`_turn_at`) voor de volgende keer-run: de vroegste slag
## (`D/2 + 12` ticks na het keren) die in een venster van het rad valt.
func _plan(p: CharacterBody2D) -> void:
	var d := _d()
	var need := 2.0 * d + 24.0
	var best_side := _target_side()
	var best_strike := 1 << 40
	var best_turn := _tick
	var best_race := true
	for s: int in [_target_side(), -_target_side()]:
		var dist := absf(_ax(p) - _wall_x(s))
		var to_need := absf(need - dist) / 3.0
		var earliest_turn := _tick + int(to_need + (need - 9.0) / 2.0)
		var earliest_strike := earliest_turn + d / 2 + 12
		for w: Vector2i in _rad_windows(s):
			var strike := maxi(earliest_strike, w.x + 2)
			# Alle slagen van de bounce (om de 20 ticks) moeten in het venster vallen.
			if strike + (strikes_per_bounce - 1) * ATTACK_COOLDOWN <= w.y - 4:
				if strike < best_strike:
					best_strike = strike
					best_side = s
					best_turn = strike - d / 2 - 12
					best_race = best_turn <= earliest_turn + 4
				break
	_side = best_side
	_turn_at = best_turn
	_race = best_race


## De volgende twee vensters [open, dicht) van het rad aan kant `side`, als het nergens eerder
## wegdraait (kant_ticks, rad_tril, rad_draai uit data).
func _rad_windows(side: int) -> Array[Vector2i]:
	var g := _boss.data_group
	var kt := EnemyData.ticks(g, "kant_ticks")
	var shake := EnemyData.ticks(g, "rad_tril")
	var turn := EnemyData.ticks(g, "rad_draai")
	var period := 2 * (kt + shake + turn)
	var open := 0
	var since := _boss.rad_since()
	var until := _boss.rad_until()
	match _boss.rad_state:
		Gemaalmeester.RadState.HANGING:
			open = since if _boss.rad_side == side else since + kt + shake + turn
		Gemaalmeester.RadState.SHAKING:
			open = until + turn if side == -_boss.rad_side else until + turn + kt + shake + turn
		_:
			open = until if side == _boss.rad_side else until + kt + shake + turn
	return [Vector2i(open, open + kt), Vector2i(open + period, open + period + kt)]


## Een dash (4 px/tick, 10 ticks) als `wanted` en hij kan: op de vloer, 20 ticks na de vorige.
func _dash_if(p: CharacterBody2D, wanted: bool) -> int:
	if not wanted or not _on_floor(p) or p.motor.dash_left > 0 or not p.motor.dash_ready:
		return 0
	if _tick - p.motor.last_dash_tick < int(Tuning.movement()["dash_ground_cooldown_ticks"]):
		return 0
	return _tap(1, DASH) if p == _p(1) else _tap(2, DASH)


## In de lucht naar de echo sturen (hij komt je tegemoet): waar staat hij als P1 op zijn hoogte is?
func _steer_to_echo(p: CharacterBody2D, fallback: int) -> int:
	if not _echo_ready():
		return _walk(fallback)
	var e := _echo()
	var ex := e.position.x
	var dx := 0.0 if is_nan(_echo_last_x) else ex - _echo_last_x
	_echo_last_x = ex
	var ticks_left := 33.0 - minf(_since, 33.0)
	var meet := ex + dx * ticks_left
	if meet > p.position.x + 2.0:
		return R
	if meet < p.position.x - 2.0:
		return L
	return 0


## Naar arena-x `target` sturen (dode zone 2 px).
func _steer(p: CharacterBody2D, target: float) -> int:
	var x := _ax(p)
	if target > x + 2.0:
		return R
	if target < x - 2.0:
		return L
	return 0


## Fase 2 solo met de lancering (C-11, V-01): houding op `rad_x − 70` naar binnen, de echo staat
## D ticks later in houding; P1 springt op `T + D − 12` op hem, vliegt over het rad en slaat met
## de neerslag (stuit) twee keer zonder te landen.
func _phase2_launch(p: CharacterBody2D) -> int:
	if sub == "":
		if not _on_floor(p):
			return _steer(p, _boss.rad_x(_side if _side != 0 else _target_side()))
		_plan_launch(p)
		sub = "l_wall"
	var side := _side
	var wall := _wall_x(side)
	var inward := -side
	var x := _ax(p)
	var rad_cx := _boss.rad_x(side)
	var stance := rad_cx - inward * LAUNCH_BEFORE_RAD
	if absf(stance - wall) < 9.0:
		stance = wall + inward * 9.0
	var d := _d()
	match sub:
		"l_wall":
			# Eerst langs de muurkant, zodat P1 naar binnen kijkend op de houdingsplek komt.
			if (x - stance) * inward <= -16.0 or (absf(x - wall) <= 9.0 and _stuck >= 1):
				sub = "l_go"
				return _walk(inward)
			return _walk(side)
		"l_go":
			if (x - stance) * inward >= 0.0:
				if _tick < _turn_at:
					# Te vroeg voor het venster: een stukje naar de muur en terug, in beweging.
					sub = "l_wall"
					return _walk(side)
				if not _attack_ready(1):
					return 0
				sub = "l_hold"
				_stance_tick = _tick
				_stance_x = x
				return A
			return _walk(inward)
		"l_hold":
			if _tick - _stance_tick < LAUNCH_HOLD:
				return A
			sub = "l_wait"
			_wander = inward
			return 0
		"l_wait":
			var jump_at := _stance_tick + d - 12
			if _tick >= jump_at:
				sub = "l_air"
				return _tap(1, J) | _steer(p, _stance_x)
			# Rond de houdingsplek blijven bewegen, binnen een sprong ervan.
			if (x - _stance_x) * inward >= 36.0:
				_wander = -inward
			elif (x - _stance_x) * inward <= 6.0:
				_wander = inward
			return _walk(_wander)
		"l_air":
			if p.motor.launch_left > 0 or p.motor.launch_pending:
				sub = "l_fly"
				_strikes_air = 0
				return 0
			if _on_floor(p):
				sub = ""
				return 0
			return _steer(p, _stance_x)
		"l_fly":
			if _on_floor(p) or _on_plank(p):
				sub = ""
				return 0
			var bits := 0 if p.motor.launch_left > 0 else _steer(p, rad_cx)
			var feet := _feet(p)
			if _boss.is_rad_hittable() and feet >= NEERSLAG_LOW and feet <= NEERSLAG_HIGH \
					and absf(x - rad_cx) <= 52.0 and _strikes_air < 2 and _attack_ready(1):
				_strikes_air += 1
				bits |= A | DOWN
			return bits
	return 0


## De lancering: kant en slagtick (`_turn_at`) zo dat de neerslagen (± D + 35 en D + 75 ticks na de
## slag in houding) in een venster van het rad vallen.
func _plan_launch(p: CharacterBody2D) -> void:
	var d := _d()
	var best_t := 1 << 40
	var best_side := _target_side()
	for s: int in [_target_side(), -_target_side()]:
		var arrive := _tick + int(absf(_ax(p) - _wall_x(s)) / 2.0) + 20
		for w: Vector2i in _rad_windows(s):
			var t := maxi(arrive, w.x - d - 30)
			if t + d + 95 <= w.y and t < best_t:
				best_t = t
				best_side = s
				break
	_side = best_side
	_turn_at = best_t


## Fase 2 co-op, P1: naar P2 (die onder het rad staat), op hem springen, bouncen en slaan; de vang
## (C-13) brengt hem terug omhoog voor de tweede slag.
func _phase2_coop_p1(p: CharacterBody2D) -> int:
	var p2 := _p(2)
	var side := _target_side()
	var rad_cx := _boss.rad_x(side)
	var x := _ax(p)
	var x2 := _ax(p2)
	var half := EnemyData.value(_boss.data_group, "rad_breedte") * 0.5
	var ready: bool = absf(x2 - rad_cx) <= half and _on_floor(p2) and _boss.is_rad_hittable() \
		and (p2.motor.velocity.x == 0.0)
	match sub:
		"", "c_go":
			sub = "c_go"
			if not _on_floor(p):
				return _steer(p, x2)
			if ready and absf(x - x2) <= COOP_JUMP_PX and absf(x - x2) >= 2.0:
				sub = "c_air"
				_plank_ticks = 0
				return _tap(1, J) | _steer(p, x2)
			# Naast P2 gaan staan, aan de binnenkant (± 40 px), en daar heen en weer.
			var spot := rad_cx + 40.0 * (1.0 if rad_cx < _boss.middle() else -1.0)
			return _wander_bits(p, spot) if absf(x - spot) <= 30.0 else _steer(p, spot)
		"c_air":
			if _on_plank(p):
				if _plank_ticks < bounce_delay:
					_plank_ticks += 1
					return 0
				_plank_ticks = 0
				sub = "c_bounce"
				_strikes_air = 0
				return _tap(1, J)
			if _on_floor(p):
				sub = "c_go"
				return 0
			return _steer(p, x2)
		"c_bounce":
			if p.move_events & Motor.EV_CATCH:
				_strikes_air = 0
			if _on_plank(p):
				_strikes_air = 0
				return _tap(1, J)
			if _on_floor(p):
				sub = "c_go"
				return 0
			# Boven P2 blijven (voor de vang); kijkt P1 van het rad weg, dan één tick ernaartoe.
			var face: int = p.motor.facing
			var box_x: float = x + face * 18.0
			var bits := _steer(p, x2)
			if absf(box_x - rad_cx) > half + 2.0:
				bits = _walk(1 if rad_cx > x else -1)
				face = 1 if rad_cx > x else -1
				box_x = x + face * 18.0
			if _boss.is_rad_hittable() and _feet(p) >= STRIKE_FEET and absf(box_x - rad_cx) <= half + 2.0 \
					and _strikes_air < strikes_per_bounce and _attack_ready(1):
				_strikes_air += 1
				bits |= A
			return bits
	return 0


# --- P2 --------------------------------------------------------------------------

func _decide_p2() -> int:
	var p2 := _p(2)
	if p2 == null or p2.dissolved or _boss.is_defeated():
		return 0
	var x := _ax(p2)
	if _boss.state == _boss.State.IDLE:
		return _walk(1)
	if _boss.phase == Gemaalmeester.Phase.TWO and not (_boss.is_wankel() or _boss.is_finisher_running()):
		# Onder het midden van het rad gaan staan (drager, §3.5).
		var target := _boss.rad_x(_target_side())
		if absf(target - x) <= 1.0:
			return 0
		return _walk(1 if target > x else -1)
	# Fase 1 en Wankel: rechts van de ketel, kijkt naar links, slaat 10 ticks na P1.
	var stand := _boss.middle() + KETEL_OFFSET
	var move := _approach(p2, stand, -1)
	if move != 0:
		return move
	if not p2_strikes or not _attack_ready(2):
		return 0
	if _boss.is_wankel():
		return A if _ketel_mark_by("p1") else 0
	return A if _tick - int(_last_attack[1]) == ATTACK_COOLDOWN / 2 else 0
