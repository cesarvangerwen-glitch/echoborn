extends RefCounted
## De gescripte geoefende boss-run tegen de Gemaalmeester (T8b B-9, B-9b; slice-vijanden-en-boss.md
## v0.1.3 §3, §6), naar het voorbeeld van `levels/flowkamer/flow_bot.gd`.
##
## Twee inputbronnen (`p1_source`, `p2_source`, elk met `sample(tick) -> int`) die per tick kijken
## waar P1, P2, de echo en de boss staan en daarop de knoppen kiezen. De bot leest alleen wat een
## speler ziet (posities, de tell en het vlak van de aanval, schot/kern, de kant en de stand van het
## rad); dezelfde D en dezelfde start geven dus dezelfde input. `recorded` houdt de bits per stoel bij.
##
## Werkaanname (Gameplay Programmer, kader §5): de "scripted geoefende run" is deze bot.
## - **Fase 1 solo** (§3.4): P1 staat links van de ketel (kijkt naar rechts) en slaat om de 20 ticks
##   (de AANVAL-cooldown); de echo knalt het merk. P1 springt over elke pompslag (afzet 16 ticks vóór
##   het actieve vlak) en slaat een add die vlak achter hem staat.
## - **Fase 1 co-op, de wissel** (GMB-14, B-14 (3); v0.1.6.1 §3.10): P2 loopt elke maat naar de
##   doelhelft (`Gemaalmeester.doelhelft`, `KETEL_OFFSET` px van het midden, kijkt naar de ketel) en
##   zet daar het merk (op schot of kern); P1 staat op de andere, veilige helft (waar de stang net
##   sloeg) en ontsteekt het merk, en op de open kern slaat hij gewoon (10 SE). Zo kruisen ze elkaar
##   elke maat door het lichaam. Staat P1 toch in een vlak, dan springt hij over de pompslag zoals
##   solo. Geen sprongen of stappen zonder taak. Met `p2_fixed` (note-run (b)) de oude co-op-bot: P1
##   links zoals solo, P2 rechts op één plek, die 10 ticks na P1 slaat.
## - **Fasewissel co-op**: P2 loopt al naar de kant van het rad (GMB-12: waar P1 niet is).
## - **Fase 2 solo** (§3.5): keren tegen de muur aan de kant van het rad en bouncen op de echo; bij
##   de bounce één slag als het aanvalsvlak boven 100 px is (`strikes_per_bounce`, §3.5: "1 treffer
##   per bounce"). Vóór elke keer een aanloop van `2D + 24` px naar de muur (D + 12 ticks), zodat
##   de echo achter P1 op de vloer loopt. Met `use_launch` de lancering met neerslag (B-8 (3)).
## - **Fase 2 co-op**: P2 gaat onder het midden van het rad staan; P1 springt op hem, bouncet, slaat,
##   valt terug en wordt gevangen (C-13), slaat weer.
## - **Wankel** (§3.6): één slag op de merkplek; solo knalt de echo, in co-op slaat P2; P1 blijft
##   lopen tot de boss verslagen is.
## - **Ontwijken in fase 2** (B-9b, §3.5 *Keren op de maat*): `_plan` kiest de vroegste keertick `T`
##   waarvan (a) beide slagen in een venster van het rad vallen, (b) geen actieve zwiep-tick in
##   `J + 1 … L + 6` of `L + 42 … L + 52` ligt (`J = T + max(0; (2D − 130)/4)`, `L = J + 33`; de bot
##   rekent de maat vooruit met `Gemaalmeester.phase2_beats`, die ligt vast) en (c) elke pompslag in
##   `T − 140 … L + 52` buiten `J + 6 … L + 43` te ontwijken is met een sprong `a − 16 … a + 24` die
##   `L − D − 10 … L − D + 5` en `J` niet raakt. Op de vloer springt hij over elke pompslag die hem
##   raakt (afzet `DODGE_LEAD` ticks vóór het actieve vlak, met de looprichting erbij); te vroeg = heen
##   en weer in de aanloopstrook (`hold`). In co-op springt P1 pas op P2 als (b) geldt voor zijn
##   opstap en val, en springt hij over de pompslag op de vloer; P2 blijft onder het rad.
## - **Rolwissel in fase 2 co-op** (GMB-15 (b), B-14 (4)): ligt de vroegste afzet van P1 op P2 bij
##   aankomst onder het rad meer dan `SWAP_WAIT` ticks verder, dan wisselen ze voor één bounce: P1
##   gaat onder het midden van het rad op de vloer staan (en springt over een pompslag die hem raakt),
##   P2 springt op hem, bouncet en slaat 2×; daarna weer de gewone rollen. Eén keer per kant.
## - **Realistische speler** (`realistic`): geen dash in fase 2 en `HESITATE` ticks aarzeling (stil)
##   vóór elke oversteek naar de andere muur.
## - **Meten** (B-9b, rapport): per keer-run het lopend wachten in `hold` (`waits`) en de afzet en de
##   landing op de echo ten opzichte van het keren (`jl`).

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
## Fase 1 co-op: een smaller venster, zodat de wissel ± 72 px door de machine is (± 36 px aan elke
## kant van het midden, GMB-14 d) en niet 60 px tot de binnenrand van `KETEL_WINDOW`.
const COOP_WINDOW := 2.0
## Pompslag fase 1 ontwijken: afzet zo veel ticks vóór het actieve vlak (voeten > 24 px op 6–34
## ticks na de afzet; §3.4: venster 24 ticks).
const DODGE_LEAD := 16
## Fase 1, solo (#247): een sprong over de pompslag landt zo veel ticks na de afzet (40, gdd §2.5a).
const JUMP_TICKS := 40
## Fase 1, solo (#247): P1 springt naar een plek zo ver naar de ketel toe als hij anders op zijn echo
## landt (de echo staat op de landingstick waar P1 D ticks eerder stond; een lichaam is 16 breed).
const DODGE_SHIFT := 20.0
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
## B-9b (§3.5): de landing op de echo (of P2) ligt zo veel ticks na de afzet `J`.
const LAND_AFTER_J := 33
## B-9b, co-op: de landing op P2 ligt zo veel ticks na de afzet (gemeten: 32).
const LAND_ON_P2 := 32
## GMB-15 (b): rolwissel als P1 bij aankomst langer dan zo veel ticks op zijn afzet moet wachten.
const SWAP_WAIT := 60
## GMB-15 (b): P2 staat voor zijn sprong op P1 zo ver van het midden van het rad, aan de muurkant.
const SWAP_P2_OFFSET := 36.0
## B-9b: veiligheidsmarge in ticks op de vensters van (b) en (c).
const PLAN_MARGIN := 2
## B-9b: zo ver vooruit zoekt `_plan` een keertick.
const PLAN_HORIZON := 900
## B-9b, realistische speler: zo lang aarzelt hij (stil) vóór elke oversteek.
const HESITATE := 40


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


## Elke keer een nieuwe `Seat` (zonder eigen toestand): de bot bewaart zijn stoelen niet. Anders
## houden bot en stoel elkaar vast (RefCounted-kring) en blijft `boss_bot.gd` na afloop in gebruik
## ("1 resources still in use at exit", #233).
var p1_source: Seat:
	get:
		return Seat.new(self, 1)
var p2_source: Seat:
	get:
		return Seat.new(self, 2)
## B-8 (2), late bot: zo veel ticks blijft P1 op de echo of P2 staan vóór de bounce.
var bounce_delay := 0
## Slagen per bounce. §3.5 rekent met 1; de geoefende run slaat er 2: de AANVAL-cooldown (20 ticks)
## past in het venster van 28 ticks boven 100 px (werkaanname Gameplay Programmer, zie de PR).
var strikes_per_bounce := 2
## Solo fase 2 met de lancering + neerslag in plaats van keren (B-8 (3)).
var use_launch := false
## C-16 (2): P2 slaat nooit.
var p2_strikes := true
## B-14 (b), note-run: P2 blijft als ontsteker op één plek (rechts van de ketel) en zet geen merken;
## P1 speelt fase 1 zoals de oude co-op-bot (links, slaan om de 20 ticks, springen).
var p2_fixed := false
## GMB-15 (b), rapport: de tick van elke rolwissel.
var swaps: Array[int] = []
## Fase 1 en 2: over de pompslag springen; fase 2 ook de keer-runs op de maat plannen (B-9b).
var dodge := true
## B-9b: realistische speler (geen dash in fase 2, `HESITATE` ticks aarzelen vóór elke oversteek).
var realistic := false
## B-9b, rapport: lopend wachten in `hold` per keer-run (ticks), en [J − T, L − T] per keer-run.
var waits: Array[int] = []
var jl: Array = []
## B-9b, rapport (v0.1.3 §3.9 besluit 2): per keer-run de regel die de vroegst haalbare keertick aan de
## gekozen kant sloot: "rad" (de slagen vallen niet in een venster), "zwiep", "pompslag", beide, of "geen".
var closed := {"rad": 0, "zwiep": 0, "pompslag": 0, "zwiep+pompslag": 0, "geen": 0}
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
## Fase 1 (#247): de x van P1 per tick (arena-x), om te weten waar de echo straks staat.
var _x_hist := {}
## Fase 1 (#247): verschuiving van de staplek (0 of DODGE_SHIFT).
var _stand_shift := 0.0
var _hold_ticks := 0
var _turn_tick := -1
var _jump_tick := -1
var _hesitate_left := -1
## GMB-15 (b): de rolwissel van nu ("" = geen; "go": P1 naar het midden, P2 opzij; "air", "bounce":
## P2 springt op P1 en slaat), en voor welke kant (`rad_since`) P1 al gekeken heeft.
var _swap := ""
var _swap_checked := -1


func _init(sim: Node, boss: Gemaalmeester) -> void:
	_sim = sim
	_boss = boss


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
	# Vóór BOSS_START naar het midden van de arena (in de Kadewijk komt P1 rechts binnen, #83).
	if _boss.state == _boss.State.IDLE:
		return _walk(1 if _ax(p) < _boss.middle() else -1)
	if _boss.is_wankel() or _boss.is_finisher_running():
		return _wankel_p1(p)
	if _boss.phase == Gemaalmeester.Phase.ONE:
		if _coop() and not p2_fixed:
			return _phase1_coop_p1(p)
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
	_x_hist[_tick] = x
	_x_hist.erase(_tick - 400)
	var stand := mid - KETEL_OFFSET + _stand_shift
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
		_choose_landing(x, mid)
	return bits


## Fase 1 co-op (GMB-14 d): P1 op de veilige helft (niet de doelhelft), kijkt naar de ketel en
## ontsteekt het merk van P2 (alleen van de andere helft dan waar het staat); op de open kern slaat
## hij ook zonder merk (10 SE, zet geen merk). Een add vlak achter hem: omdraaien en slaan.
func _phase1_coop_p1(p: CharacterBody2D) -> int:
	var x := _ax(p)
	var mid := _boss.middle()
	var here := -1 if x < mid else 1
	var target: int = _boss.doelhelft(_tick)
	var safe := -target if target != 0 else here
	# Ligt er een merk van P2, dan naar de helft waar hij het kan ontsteken (de andere dan waar het
	# gezet is); na de omslag van de doelhelft is dat de kant van de volgende slag (springen).
	var mark = _sim.combat.mark_on(_boss.ketel)
	if mark != null and mark.setter == "p2":
		safe = -_boss.half_of(mark.set_at)
	var face := -safe
	# Een add vlak achter hem slaat hij als er geen merk van P2 te ontsteken is, of als de add
	# aanloopt (een treffer zet hem stil, VJ-04).
	var to_detonate: bool = mark != null and mark.setter == "p2"
	for add in _boss.adds:
		if (not to_detonate or add.is_telling()) and add.alive and absf(_ax(add) - x) <= 34.0 and signf(_ax(add) - x) != float(face):
			face = -1 if _ax(add) < x else 1
	var bits := _approach(p, mid + safe * KETEL_OFFSET, face, COOP_WINDOW)
	if bits == 0 and _attack_ready(1) and _on_floor(p):
		if face != -safe:
			bits |= A
		elif mark != null and mark.setter == "p2" and _boss.half_of(mark.set_at) != here:
			bits |= A
		elif mark == null and _boss.core_open:
			bits |= A
	if dodge and _should_dodge(p):
		bits |= _tap(1, J)
	return bits


## #247, D = 90: sprong P1 op zijn plek, dan landde hij op zijn echo (die staat op de landingstick
## waar P1 D ticks eerder stond), en tilde de echo hem bij de volgende pompslag op en zakte hij er
## met hem in. Dan springt hij nu naar de andere staplek (20 px verder, naar de ketel; links komen
## de adds), en de keer erna weer terug als de echo daar staat.
func _choose_landing(x: float, mid: float) -> void:
	if _coop() or _echo() == null:
		return
	var back := _tick + JUMP_TICKS - _d()
	if back > _tick or not _x_hist.has(back):
		return
	var echo_x: float = _x_hist[back]
	var here := mid - KETEL_OFFSET + _stand_shift
	if absf(echo_x - here) < 17.0:
		_stand_shift = DODGE_SHIFT if _stand_shift == 0.0 else 0.0


## Naar `stand` ± KETEL_WINDOW met de kijkrichting `face`; 0 = staat goed. Een stap om te draaien
## blijft binnen het venster (anders eerst een stap terug), zodat het niet heen en weer gaat.
func _approach(p: CharacterBody2D, stand: float, face: int, window := KETEL_WINDOW) -> int:
	var x := _ax(p)
	if x < stand - window:
		return R
	if x > stand + window:
		return L
	if p.motor.facing == face:
		return 0
	var step := 2.0 * face
	if absf(x + step - stand) <= window:
		return _walk(face)
	return _walk(-face)


## Pompslag (B-6): afzetten `DODGE_LEAD` ticks vóór het actieve vlak, als het vlak P1 raakt. Ook
## vanaf de echo (een bounce, #247): bij D = 90 staat P1 in fase 1 om de maat op de echo die zijn
## vorige sprong naspeelt; bleef hij daar staan, dan zakte hij met de echo het vlak in (1 treffer per 2 maten).
func _should_dodge(p: CharacterBody2D) -> bool:
	if _boss.attack_kind != "pomp" or not _boss.is_telling() or not p.motor.on_floor:
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
## kant en het moment (`_plan`, B-9b): de eerste keer-run waarvan de slagen in een venster van het rad
## vallen en die de zwiep en de pompslag ontwijkt. Op de vloer springt hij over de pompslag.
func _phase2_turn(p: CharacterBody2D) -> int:
	var bits := _phase2_turn_move(p)
	if dodge and _should_dodge(p) and sub in ["", "out", "hold", "in", "back", "hesitate"]:
		bits |= _tap(1, J)
	return bits


func _phase2_turn_move(p: CharacterBody2D) -> int:
	var x := _ax(p)
	if sub == "" or sub == "hesitate":
		if not _on_floor(p):
			return _steer(p, _boss.rad_x(_side if _side != 0 else _target_side()))
		# Realistische speler: eerst aarzelen vóór een oversteek naar de andere muur.
		if realistic and sub == "" and _crossing_ahead(p):
			sub = "hesitate"
			_hesitate_left = HESITATE
		if sub == "hesitate":
			_hesitate_left -= 1
			if _hesitate_left > 0:
				return 0
		_plan(p)
		sub = "out"
		_hold_ticks = 0
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
			return _phase2_turn_move(p)
		"hold":
			# Wachten tot het geplande moment, in beweging tussen `need` en `need + 30` px.
			if _tick >= _turn_at - int((dist - 9.0) / 2.0):
				sub = "in"
				waits.append(_hold_ticks)
				return _walk(side)
			_hold_ticks += 1
			if dist >= need + 30.0:
				_wander = side
			elif dist <= need + 2.0:
				_wander = inward
			return _walk(_wander)
		"in":
			if dist <= Tuning.body_size().x * 0.5 + 1.0 and _stuck >= 1:
				sub = "back"
				_since = 0
				_turn_tick = _tick
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
				# De echo mag nog in de lucht zijn (hij speelt een ontwijksprong na); `_plan` zorgt dat
				# hij op de vloer loopt als P1 op hem landt (B-9b (c)).
				if _on_floor(p) and e.position.y <= p.position.y + 1.5 and ahead > 0.0 and ahead <= JUMP_ON_ECHO_PX:
					sub = "air"
					_since = 0
					_plank_ticks = 0
					_jump_tick = _tick
					return _walk(inward) | _tap(1, J)
			return _walk(inward)
		"air":
			if _on_plank(p):
				if _plank_ticks < bounce_delay:
					_plank_ticks += 1
					return 0
				if _plank_ticks == 0 and _turn_tick >= 0:
					jl.append([_jump_tick - _turn_tick, _tick - _turn_tick])
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


## Realistische speler: gaat de volgende keer-run naar de andere muur (een oversteek)?
func _crossing_ahead(p: CharacterBody2D) -> bool:
	var here := -1 if _ax(p) < _boss.middle() else 1
	return _target_side() != here


var _turn_at := 0
var _race := true


## Kiest de kant (`_side`) en de keertick (`_turn_at`) voor de volgende keer-run (B-9b): de vroegste
## keertick `T` per kant waarvan de slagen (`D/2 + 12` ticks na het keren, om de 20 ticks) in een venster
## van het rad vallen en die (b) en (c) van `_maat_ok` haalt; daarvan de vroegste slag.
func _plan(p: CharacterBody2D) -> void:
	var d := _d()
	var need := 2.0 * d + 24.0
	var speed := 2.0 if realistic else 3.0
	var beats: Array = _boss.phase2_beats(_tick + PLAN_HORIZON + 400) if dodge else []
	var best_side := _target_side()
	var best_strike := 1 << 40
	var best_turn := _tick
	var best_race := true
	var best_earliest := _tick
	for s: int in [_target_side(), -_target_side()]:
		var dist := absf(_ax(p) - _wall_x(s))
		var to_need := absf(need - dist) / speed
		var earliest_turn := _tick + int(to_need + (need - 9.0) / 2.0)
		var windows := _rad_windows(s)
		for turn in range(earliest_turn, earliest_turn + PLAN_HORIZON):
			var strike := turn + d / 2 + 12
			if strike >= best_strike:
				break
			var in_window := false
			for w: Vector2i in windows:
				if strike >= w.x + 2 and strike + (strikes_per_bounce - 1) * ATTACK_COOLDOWN <= w.y - 4:
					in_window = true
					break
			if not in_window or not _maat_ok(turn, beats, true):
				continue
			best_strike = strike
			best_side = s
			best_turn = turn
			best_earliest = earliest_turn
			best_race = best_turn <= earliest_turn + 4
			break
	_side = best_side
	_turn_at = best_turn
	_race = best_race
	closed[_closing_rule(best_earliest, best_turn, _rad_windows(best_side), beats)] += 1


## Welke regel sloot de vroegst haalbare keertick `earliest` (rapport)? "geen" als hij gekozen is.
func _closing_rule(earliest: int, chosen: int, windows: Array[Vector2i], beats: Array) -> String:
	if chosen <= earliest:
		return "geen"
	var strike := earliest + _d() / 2 + 12
	var in_window := false
	for w: Vector2i in windows:
		if strike >= w.x + 2 and strike + (strikes_per_bounce - 1) * ATTACK_COOLDOWN <= w.y - 4:
			in_window = true
	if not in_window:
		return "rad"
	# Beide regels apart, zodat een keertick die door allebei sneuvelt ook zo telt.
	var zwiep := _maat_reason(earliest, beats.filter(func(b: Array) -> bool: return b[1] == "zwiep"), true) != ""
	var pomp := _maat_reason(earliest, beats.filter(func(b: Array) -> bool: return b[1] == "pomp"), true) != ""
	if zwiep and pomp:
		return "zwiep+pompslag"
	if zwiep:
		return "zwiep"
	return "pompslag" if pomp else "geen"


## B-9b (§3.5 *Keren op de maat*): past een keer-run met keertick `turn` in de maat? Met
## `J = turn + max(0; (2D − 130)/4)` de afzet naar de echo (co-op: `turn` zelf, de afzet op P2) en
## `L = J + 33` de landing (co-op `J + 32` op P2): (b) geen actieve zwiep-tick in `J + 1 … L + 6` of `L + 42 … L + 52`; (c) elke
## pompslag in `turn − 140 … L + 52` ligt in `J + 6 … L + 43` (P1 is dan boven 24 px), of is te
## ontwijken met een sprong `a − 16 … a + 24` die `J` niet raakt en (solo) niet in `L − D − 10 …
## L − D + 5` valt (dan speelt de echo hem na als P1 op hem landt). Een pompslag die actief wordt in
## de val na de bounce (`L + 44 … L + 60`) is niet te ontwijken. Co-op toetst alleen (b), en geen
## afzet vlak vóór een actieve pompslag. Marge `PLAN_MARGIN` aan elke kant.
func _maat_ok(turn: int, beats: Array, solo: bool) -> bool:
	return _maat_reason(turn, beats, solo) == ""


## Zoals `_maat_ok`, maar met de regel die faalt: "" (past), "zwiep" of "pompslag".
func _maat_reason(turn: int, beats: Array, solo: bool) -> String:
	var d := _d()
	var m := PLAN_MARGIN
	var j := turn + (maxi(0, int(ceil((2.0 * d - 130.0) / 4.0))) if solo else 0)
	var l := j + (LAND_AFTER_J if solo else LAND_ON_P2)
	var g := _boss.data_group
	var zwiep_len := EnemyData.ticks(g, "zwiep_actief")
	var pomp_len := EnemyData.ticks(g, "pomp2_actief")
	var zwiep_lead := EnemyData.ticks(g, "zwiep_aanloop")
	var pomp_lead := EnemyData.ticks(g, "pomp2_aanloop")
	for beat: Array in beats:
		var start: int = beat[0]
		if beat[1] == "zwiep":
			var z0 := start + zwiep_lead
			var z1 := z0 + zwiep_len - 1
			if _overlap(z0, z1, j + 1 - m, l + 6 + m) or _overlap(z0, z1, l + 42 - m, l + 52 + m):
				return "zwiep"
			continue
		var a := start + pomp_lead
		var a1 := a + pomp_len - 1
		if not solo:
			# Co-op (B-9b (3)): alleen (b); over de pompslag springt P1 op de vloer. Wel niet afzetten
			# vlak vóór een actieve pompslag (P1 is pas na 6 ticks boven 24 px), en geen pompslag in
			# de val na de bounce (als de kant klaar is, loopt P2 weg en valt P1 tot de vloer).
			if _overlap(a, a1, j - m, j + 5 + m) or _overlap(a, a1, l + 44 - m, l + 60):
				return "pompslag"
			continue
		if a1 < turn - 140 or a > l + 60:
			continue
		if a >= j + 6 + m and a1 <= l + 43 - m:
			continue
		if _overlap(a, a1, l + 44 - m, l + 60):
			return "pompslag"
		var j0 := a - DODGE_LEAD
		var j1 := a + 24
		if j0 <= j + m and j1 >= j - m:
			return "pompslag"
		if solo and _overlap(j0, j1, l - d - 10 - m, l - d + 5 + m):
			return "pompslag"
	return ""


func _overlap(a0: int, a1: int, b0: int, b1: int) -> bool:
	return a0 <= b1 and b0 <= a1


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
	if realistic and _boss.phase == Gemaalmeester.Phase.TWO:
		return 0
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
			if _on_plank(p):
				# Op P2 (na een ontwijksprong of een kant die klaar is): bouncen als het rad hangt en de
				# maat het toelaat, anders van hem af stappen (op P2 staan is in de zwiep, §3.5).
				if _coop_bounce_ok():
					sub = "c_bounce"
					_strikes_air = 0
					return _tap(1, J)
				return _walk(_off_p2_dir(p2))
			if not _on_floor(p):
				# Draait het rad weg, dan niet op P2 landen (hij loopt naar de andere kant).
				return _steer(p, x2) if _boss.is_rad_hittable() else 0
			# B-9b: pas op P2 springen als de zwiep zijn opstap en val niet raakt en de pompslag te
			# ontwijken is (`_maat_ok` met J = nu); over de pompslag op de vloer springen.
			var jump_ok := not dodge or _maat_ok(_tick, _boss.phase2_beats(_tick + 200), false)
			# GMB-15 (b): bij aankomst (naast P2, die klaarstaat) één keer per kant kijken hoe lang P1
			# op zijn afzet moet wachten; langer dan `SWAP_WAIT` ticks: de rollen wisselen.
			var spot0 := rad_cx + 40.0 * (1.0 if rad_cx < _boss.middle() else -1.0)
			if ready and not p2_fixed and p2_strikes and _swap_checked != _boss.rad_since() \
					and absf(x - spot0) <= 30.0:
				_swap_checked = _boss.rad_since()
				if _earliest_coop_jump() - _tick > SWAP_WAIT:
					_swap = "go"
					swaps.append(_tick)
					sub = "c_swap"
					return _phase2_coop_p1(p)
			if ready and jump_ok and absf(x - x2) <= COOP_JUMP_PX and absf(x - x2) >= 2.0:
				sub = "c_air"
				_plank_ticks = 0
				return _tap(1, J) | _steer(p, x2)
			# Naast P2 gaan staan, aan de binnenkant (± 40 px), en daar heen en weer.
			var spot := rad_cx + 40.0 * (1.0 if rad_cx < _boss.middle() else -1.0)
			var walk := _wander_bits(p, spot) if absf(x - spot) <= 30.0 else _steer(p, spot) | _dash_if(p, absf(x - spot) > 60.0)
			if dodge and _should_dodge(p):
				walk |= _tap(1, J)
			return walk
		"c_swap":
			# GMB-15 (b): onder het midden van het rad op de vloer staan; P2 springt op hem. Over een
			# pompslag die hem raakt springt hij (C-10: P2 gaat mee).
			if _swap == "":
				sub = "c_go"
				return 0
			var bits := 0
			if not _on_floor(p) or absf(x - rad_cx) > 2.0:
				bits = _steer(p, rad_cx)
			if dodge and _should_dodge(p):
				bits |= _tap(1, J)
			return bits
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
				if not _coop_bounce_ok():
					sub = "c_go"
					return _walk(_off_p2_dir(p2))
				_strikes_air = 0
				return _tap(1, J)
			if _on_floor(p):
				sub = "c_go"
				return 0
			# Boven P2 blijven (voor de vang); kijkt P1 van het rad weg, dan één tick ernaartoe.
			# Is de kant klaar (het rad trilt of draait), dan naast P2 landen, niet op hem (B-9b).
			if not _boss.is_rad_hittable():
				return 0
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


## GMB-15 (b): de vroegste afzet van P1 op P2 vanaf nu die B-9b (3) toelaat (`_maat_ok`, co-op).
func _earliest_coop_jump() -> int:
	if not dodge:
		return _tick
	var beats := _boss.phase2_beats(_tick + PLAN_HORIZON + 200)
	for at in range(_tick, _tick + PLAN_HORIZON):
		if _maat_ok(at, beats, false):
			return at
	return _tick + PLAN_HORIZON


## Co-op: van P2 af stappen tegen zijn looprichting in (staat hij stil: naar het midden).
func _off_p2_dir(p2: CharacterBody2D) -> int:
	if absf(p2.motor.velocity.x) > 0.1:
		return -1 if p2.motor.velocity.x > 0.0 else 1
	return 1 if _ax(p2) < _boss.middle() else -1


## Co-op: nog een bounce op P2? Alleen als het rad hangt, de kant nog niet klaar is, en de maat de
## opstap en val toelaat (B-9b (b), `_maat_ok` met J = nu).
func _coop_bounce_ok() -> bool:
	if not _boss.is_rad_hittable():
		return false
	if _boss.rad_side_hits >= EnemyData.ticks(_boss.data_group, "kant_treffers"):
		return false
	return not dodge or _maat_ok(_tick, _boss.phase2_beats(_tick + 200), false)


# --- P2 --------------------------------------------------------------------------

func _decide_p2() -> int:
	var p2 := _p(2)
	if p2 == null or p2.dissolved or _boss.is_defeated():
		return 0
	var x := _ax(p2)
	if _boss.state == _boss.State.IDLE:
		return _walk(1)
	var p2_phase := _boss.phase != Gemaalmeester.Phase.ONE and not p2_fixed
	if (p2_phase or _boss.phase == Gemaalmeester.Phase.TWO) and not (_boss.is_wankel() or _boss.is_finisher_running()):
		if _swap != "":
			return _swap_p2(p2)
		# Onder het midden van het rad gaan staan (drager, §3.5); in de fasewissel al naar zijn kant.
		var target := _boss.rad_x(_target_side())
		if absf(target - x) <= 1.0:
			return 0
		return _walk(1 if target > x else -1)
	if _boss.phase == Gemaalmeester.Phase.ONE and not p2_fixed:
		return _phase1_coop_p2(p2)
	# Wankel (en de note-run `p2_fixed`): rechts van de ketel, kijkt naar links, slaat 10 ticks na P1.
	var stand := _boss.middle() + KETEL_OFFSET
	var move := _approach(p2, stand, -1)
	if move != 0:
		return move
	if not p2_strikes or not _attack_ready(2):
		return 0
	if _boss.is_wankel() or p2_fixed:
		return A if _ketel_mark_by("p1") else 0
	return A if _tick - int(_last_attack[1]) == ATTACK_COOLDOWN / 2 else 0


## Fase 1 co-op (GMB-14 d): naar de doelhelft, `KETEL_OFFSET` px van het midden, kijkt naar de
## ketel; daar het merk zetten (schot of kern), of een merk van P1 van de andere helft ontsteken.
func _phase1_coop_p2(p2: CharacterBody2D) -> int:
	var target: int = _boss.doelhelft(_tick)
	if target == 0:
		target = -1 if _ax(p2) < _boss.middle() else 1
	var move := _approach(p2, _boss.middle() + target * KETEL_OFFSET, -target, COOP_WINDOW)
	if move != 0:
		return move
	if not p2_strikes or not _attack_ready(2) or not _on_floor(p2):
		return 0
	var mark = _sim.combat.mark_on(_boss.ketel)
	if mark == null or (mark.setter == "p1" and _boss.half_of(mark.set_at) != target):
		return A
	return 0


## GMB-15 (b), P2 in de rolwissel: opzij aan de muurkant tot P1 onder het rad staat, dan op hem
## springen, bouncen en 2× slaan; terug op de vloer (of op P1) is de wissel voorbij.
func _swap_p2(p2: CharacterBody2D) -> int:
	var p1 := _p(1)
	var side := _target_side()
	var rad_cx := _boss.rad_x(side)
	var x := _ax(p2)
	var half := EnemyData.value(_boss.data_group, "rad_breedte") * 0.5
	if not _boss.is_rad_hittable() or _boss.rad_side_hits >= EnemyData.ticks(_boss.data_group, "kant_treffers"):
		_end_swap()
		return 0
	match _swap:
		"go":
			var spot := rad_cx + side * SWAP_P2_OFFSET
			if absf(x - spot) > 2.0 or not _on_floor(p2):
				return _steer(p2, spot)
			if _on_floor(p1) and absf(_ax(p1) - rad_cx) <= 2.0 and p1.motor.velocity.x == 0.0:
				_swap = "air"
				return _tap(2, J) | _steer(p2, _ax(p1))
			return 0
		"air":
			if _on_plank(p2):
				_swap = "bounce"
				_strikes_air = 0
				return _tap(2, J)
			if _on_floor(p2):
				_swap = "go"
				return 0
			return _steer(p2, _ax(p1))
		"bounce":
			if _on_floor(p2) or _on_plank(p2):
				_end_swap()
				return 0
			var face: int = p2.motor.facing
			var bits := _steer(p2, rad_cx)
			var box_x: float = x + face * 18.0
			if absf(box_x - rad_cx) > half + 2.0:
				face = 1 if rad_cx > x else -1
				bits = _walk(face)
				box_x = x + face * 18.0
			if _feet(p2) >= STRIKE_FEET and absf(box_x - rad_cx) <= half + 2.0 and _strikes_air < strikes_per_bounce \
					and _attack_ready(2):
				_strikes_air += 1
				bits |= A
			return bits
	return 0


func _end_swap() -> void:
	_swap = ""
	if sub == "c_swap":
		sub = "c_go"
