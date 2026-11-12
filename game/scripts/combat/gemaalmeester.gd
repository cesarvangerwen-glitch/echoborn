extends "res://scripts/combat/boss.gd"
## De Gemaalmeester, de boss van de slice (T8b B-5–B-8, B-13; slice-vijanden-en-boss.md v0.1.3 §3,
## gemaalmeester.md v0.2.1). Alle waarden uit `slice.csv`, groep `gemaalmeester`.
##
## Fase 1, het schot (GMB-02, GMB-11, §3.4): de ketel is een `Pantserdoel` op de merkplek (300, 36);
## alleen een merk-ontploffing breekt het schot. Dan ligt de kern open tot de drempel van de opening
## (1350 / 1200 / 1050 / 900 SE, de boss klemt erop) of 300 ticks; daarna sluit het schot weer en
## komen er uit de spuigaten max. 2 Kadelopers (30 ticks gloeien, 30 ticks inactief). Na de laatste
## drempel de fasewissel (60 ticks, GMB-12), dan fase 2.
## Fase 2, het grote rad (GMB-04, §3.5, B-8): een tweede deel (96 × 40 op y 100–140, middelpunt
## `x_rad = D + rad_offset` van de muur aan zijn kant; volgt D, ook bij een wissel van D in het
## debugmenu, SL-05; in co-op vast op `rad_coop_muur` (94 px), los van D, B-13). Niet `Merkbaar`;
## P1/P2 doen `rad_treffer` (18) SE, in co-op gedeeld door `coop_schaal` (1,0: ook 18), de echo 5. Na
## `kant_treffers` treffers van P1 en P2 samen (de echo telt niet) of `kant_ticks` (480) ticks trilt
## het `rad_tril` ticks en draait het in `rad_draai` ticks naar de andere muur; dan niet raakbaar.
## Wisselt de modus in fase 2 (drop-in/out) en verandert daardoor de plek, dan trilt en draait het
## meteen (RAD_DRAAI reden "modus", §3.5).
## Maat en aanvallen (B-6, GM-04): fase 1 elke 120 ticks een pompslag op de helft van P1 (eerste
## aanloop 60), fase 2 elke 90 ticks om en om een pompslag op de x van P1 en een schoepenzwiep.
## Wankel op 300 SE (GMB-13): de merkplek op de ketel; de finisher regelt `Boss`.

## Begin van een maat (carillon-tel, §9.3): `beat` telt vanaf BOSS_START.
signal beat(tick: int, number: int)
## SCHOT_BREUK (B-10): een merk-ontploffing brak het schot; de kern ligt open.
signal shot_broken(tick: int)
## KERN_DICHT (B-10): het schot schuift weer voor de kern; `reason` is "drempel" of "tijd".
signal core_closed(tick: int, reason: String)
## Een add stapt uit een spuigat (§3.4).
signal add_spawned(tick: int, add: Node2D)
## Schermschok (B-11): `ticks` lang `px` (schotbreuk 6 / 2, radtreffer 3 / 1).
signal screen_shake(tick: int, ticks: int, px: float)
## RAD_TREFFER (B-10): `source` "p1", "p2" of "echo"; `action` hoe de aanvaller daar kwam:
## "bounce", "lancering", "vang", "stuit" (na een neerslag-stuit), "sprong", of "echo".
signal rad_hit(tick: int, source: String, action: String, amount: int)
## RAD_DRAAI (B-10): de kant is klaar (`reason` "treffers", "tijd" of "modus": een drop-in/out
## verplaatste de plek, B-13); het rad trilt en draait daarna naar `to_side` (−1 links, +1 rechts).
signal rad_turning(tick: int, reason: String, to_side: int)

const SliceEnemy = preload("res://scripts/combat/slice_enemy.gd")
const Motor = preload("res://scripts/echo/motor.gd")

enum Phase { ONE, SWITCH, TWO }
## Het rad (§3.5): weg (fase 1), hangt (raakbaar), trilt, draait naar de andere muur.
enum RadState { HIDDEN, HANGING, SHAKING, TURNING }

## Placeholder-kleuren (§9: leesbaar in silhouet; Animator en Art vervangen ze).
const BODY_COLOR := Color(0.32, 0.33, 0.36)
const SHOT_COLOR := Color(0.6, 0.6, 0.66)
const CORE_COLOR := Color(1.0, 0.55, 0.2)
const MARK_SPOT_COLOR := Color(1.0, 0.85, 0.4)
const POMP_TELL := Color(0.85, 0.75, 0.55)
const ZWIEP_TELL := Color(0.7, 0.9, 1.0)
const SPOUT_COLOR := Color(1.0, 0.6, 0.3)
const ACTIVE_COLOR := Color(1.0, 0.4, 0.3, 0.8)
const TINK_COLOR := Color(1.0, 1.0, 0.9)
const TINK_TICKS := 4
const RAD_COLOR := Color(0.45, 0.5, 0.58)
const RAD_SHAKE_COLOR := Color(0.75, 0.7, 0.6)
const FLOOR_MARK_COLOR := Color(1.0, 0.85, 0.45, 0.35)

var phase: Phase = Phase.ONE
## De ketel: schot (intact pantser), kern (gebroken) en bij Wankel de merkplek (GMB-02, GMB-05).
var ketel: BossPart
## Drempels van fase 1 (GMB-11), uit data; `opening_index` = hoeveel er gehaald zijn.
var thresholds: Array[int] = []
var opening_index := 0
## Hoe vaak het schot brak (één opening per breuk).
var openings_count := 0
var core_open := false
## Gloeien de spuigaten nu (§3.4, B-11)?
var spout_glowing := false
## De levende en inactieve adds (Kadelopers uit de spuigaten).
var adds: Array = []
## GMB-12: de kant waar het rad heen draait bij de fasewissel (−1 links, +1 rechts): waar P1 niet is.
## In fase 2 de kant waar het rad nu hangt (tijdens het draaien al de nieuwe kant).
var rad_side := 0
## Het grote rad (GMB-04), een `BossPart`; raakbaar alleen als het hangt.
var rad: BossPart
var rad_state: RadState = RadState.HIDDEN
## Treffers van P1 en P2 samen op deze kant (`kant_treffers`, de echo telt niet).
var rad_side_hits := 0
## Hoe vaak het rad wegdraaide (aantal kanten dat klaar is).
var rad_turns := 0
## B-11: schermschok tot deze tick, met `shake_px`.
var shake_until := -1
var shake_px := 0.0

var _open_until := -1
var _switch_end := -1
var _next_beat := 0
var _beat_number := 0
var _phase2_beats := 0
var _glow_from := -1
var _glow_until := -1
var _rad_since := -1
var _rad_until := -1
var _rad_from_x := 0.0
## Hoe kwam P1/P2 in de lucht (RAD_TREFFER, B-10): {"p1": actie, "p2": actie}.
var _air_action := {}
var _noted_tick := -1
## B-13: de modus (co-op of niet) waarin het rad nu hangt.
var _rad_coop := false


## De boss op `origin`: de linkermuur van de arena, op de bovenkant van de vloer.
func setup_gemaalmeester(origin: Vector2) -> void:
	setup_boss("gemaalmeester")
	position = origin
	var g := data_group
	thresholds.clear()
	for i in EnemyData.ticks(g, "openingen"):
		thresholds.append(EnemyData.ticks(g, "drempel_%d" % (i + 1)))
	var size := Vector2(EnemyData.value(g, "schot_x2") - EnemyData.value(g, "schot_x1"),
		EnemyData.value(g, "schot_y2") - EnemyData.value(g, "schot_y1"))
	ketel = add_part("Ketel", size, Vector2(EnemyData.value(g, "merkplek_x"), EnemyData.value(g, "merkplek_y")))
	var y1 := EnemyData.value(g, "rad_y1")
	var y2 := EnemyData.value(g, "rad_y2")
	rad = add_part("Rad", Vector2(EnemyData.value(g, "rad_breedte"), y2 - y1), Vector2(rad_x(-1), (y1 + y2) * 0.5))
	_build_visual()
	on_reset(0)


## Luistert ook naar de stuit (V-01b) voor RAD_TREFFER.
func attach(p_sim: Node) -> void:
	super.attach(p_sim)
	if sim.has_signal(&"stuit"):
		sim.stuit.connect(_on_stuit)


## D van de sessie (`Combat.tail_ticks`; zonder Sim de standaard uit `echo_v04.json`).
func tail_ticks() -> int:
	if combat != null and "tail_ticks" in combat:
		return int(combat.tail_ticks)
	return EnemyData.default_tail()


## Co-op (twee spelers, `Combat.coop`)?
func is_coop() -> bool:
	return combat != null and "coop" in combat and combat.coop


## GMB-04: arena-x van het middelpunt van het rad aan kant `side`: solo `D + rad_offset` van die
## muur, in co-op `rad_coop_muur` (94 px, los van D; v0.1.3, B-13).
func rad_x(side: int) -> float:
	var from_wall := _rad_from_wall()
	return from_wall if side < 0 else arena_width - from_wall


func _rad_from_wall() -> float:
	if is_coop():
		return EnemyData.value(data_group, "rad_coop_muur")
	return float(tail_ticks()) + EnemyData.value(data_group, "rad_offset")


## GMB-04: het vloerteken onder het rad aan kant `side`, van `D` tot `D + 68` px van de muur
## (arena-x, van – tot). Alleen beeld. In co-op (geen echo) onder de vaste plek van het rad: van
## `rad_coop_muur − rad_offset` tot `+ 68` (60–128, de plek van D = 60; werkaanname GP).
func floor_mark(side: int) -> Vector2:
	var d := _rad_from_wall() - EnemyData.value(data_group, "rad_offset")
	var w := EnemyData.value(data_group, "vloerteken_breedte")
	return Vector2(d, d + w) if side < 0 else Vector2(arena_width - d - w, arena_width - d)


## Sinds wanneer het rad in zijn stand van nu is, en tot wanneer (trillen en draaien; -1 als het
## hangt). Voor bots, HUD en tests: wat een speler aan de tell ziet.
func rad_since() -> int:
	return _rad_since


func rad_until() -> int:
	return _rad_until


## De maat van fase 2 vooruit (§3.5, B-9b: "de maat ligt vast"): de aanvallen die nog actief kunnen
## worden, als [begin van de aanloop, soort] ("pomp" of "zwiep"), tot en met `until`. Tijdens de
## fasewissel vanaf de eerste maat van fase 2; in fase 1 en bij Wankel leeg. Voor bots en tests.
func phase2_beats(until: int) -> Array:
	var out: Array = []
	var maat := EnemyData.ticks(data_group, "maat_fase2")
	var start := 0
	var count := 0
	if phase == Phase.SWITCH:
		start = _switch_end
	elif phase == Phase.TWO and state == State.FIGHT:
		# De maat van nu telt mee: zijn actieve vlak kan nog komen.
		start = _next_beat - maat
		count = _phase2_beats - 1
		if count < 0:
			start = _next_beat
			count = 0
	else:
		return out
	var t := start
	while t <= until:
		out.append([t, "pomp" if count % 2 == 0 else "zwiep"])
		t += maat
		count += 1
	return out


func is_rad_hittable() -> bool:
	return rad != null and rad.hittable


func middle() -> float:
	return (EnemyData.value(data_group, "lichaam_x1") + EnemyData.value(data_group, "lichaam_x2")) * 0.5


## B-11: de schermschok van nu in px (0 = geen).
func shake_at(tick: int) -> float:
	return shake_px if tick < shake_until else 0.0


func on_start(tick: int) -> void:
	phase = Phase.ONE
	_next_beat = tick
	_beat_number = 0
	phase_changed.emit(tick, "1")


func on_reset(tick: int) -> void:
	phase = Phase.ONE
	opening_index = 0
	openings_count = 0
	core_open = false
	_open_until = -1
	_switch_end = -1
	_next_beat = 0
	_beat_number = 0
	_phase2_beats = 0
	_glow_from = -1
	_glow_until = -1
	spout_glowing = false
	rad_side = 0
	shake_until = -1
	rad_state = RadState.HIDDEN
	rad_side_hits = 0
	rad_turns = 0
	_rad_since = -1
	_rad_until = -1
	_air_action.clear()
	if rad != null:
		rad.hittable = false
		rad.markable = false
		rad.position.x = rad_x(-1)
	_set_ketel(true, true, true)
	if combat != null:
		combat.fade_marks_on(parts, tick)
	_dissolve_adds()


## GMB-11: in een opening klemt de boss op de drempel van die opening; dicht doet niets af.
## Fase 2: het rad neemt schade tot Wankel (GMB-13; `Boss` klemt op `wankel_se`).
func damage_floor(part: BossPart) -> int:
	if phase == Phase.ONE and core_open and opening_index < thresholds.size():
		return thresholds[opening_index]
	if phase == Phase.TWO and part == rad and rad.hittable:
		return 0
	return se


## §3.5: op het rad doen P1 en P2 `rad_treffer` (18), de echo `rad_echo` (5). In co-op deelt
## `coop_schaal` de schade (v0.1.3 na PR #219: 1,0, dus ook 18 SE; §3.8).
func damage_for(part: BossPart, amount: int, source: String) -> int:
	if part != rad:
		return amount
	var g := data_group
	var key := "rad_echo" if source == "echo" else "rad_treffer"
	var base := EnemyData.ticks(g, key)
	if is_coop():
		var scale := EnemyData.value(g, "coop_schaal")
		if scale > 0.0:
			base = int(round(float(base) / scale))
	return base


func on_armor_broken(tick: int, part: BossPart) -> void:
	if part != ketel or phase != Phase.ONE or state != State.FIGHT:
		return
	core_open = true
	openings_count += 1
	_open_until = tick + EnemyData.ticks(data_group, "opening_ticks")
	shake_until = tick + EnemyData.ticks(data_group, "schok_breuk_ticks")
	shake_px = EnemyData.value(data_group, "schok_breuk_px")
	shot_broken.emit(tick)
	screen_shake.emit(tick, EnemyData.ticks(data_group, "schok_breuk_ticks"), shake_px)


func on_damage(tick: int, done: int, source: String, part: BossPart) -> void:
	if part == rad and done > 0:
		_note_actions(tick)
		if source == "p1" or source == "p2":
			rad_side_hits += 1
		var g := data_group
		shake_until = tick + EnemyData.ticks(g, "schok_rad_ticks")
		shake_px = EnemyData.value(g, "schok_rad_px")
		screen_shake.emit(tick, EnemyData.ticks(g, "schok_rad_ticks"), shake_px)
		var action := "echo" if source == "echo" else String(_air_action.get(source, "sprong"))
		rad_hit.emit(tick, source, action, done)
		return
	if phase == Phase.ONE and core_open and opening_index < thresholds.size() \
			and se <= thresholds[opening_index]:
		_reach_threshold(tick)


## Debug (C-14): zet de SE. In fase 1 tellen de drempels die daarmee gehaald zijn.
func on_health_set(tick: int) -> void:
	if state != State.FIGHT or phase != Phase.ONE:
		return
	var reached := 0
	for threshold in thresholds:
		if se <= threshold:
			reached += 1
	if reached <= opening_index:
		return
	opening_index = reached
	if opening_index >= thresholds.size():
		_begin_switch(tick)
	elif core_open:
		_close_core(tick, "drempel")


## GMB-13 en GMB-05: geen aanvallen; de merkplek op de ketel gaat open (raakbaar, `Merkbaar`, 0 SE).
func on_wankel(_tick: int) -> void:
	if rad != null:
		rad.hittable = false
	core_open = false
	_glow_until = -1
	spout_glowing = false
	_set_ketel(false, true, true)


func fight_update(tick: int, p1: Node2D) -> void:
	match phase:
		Phase.ONE:
			if core_open and tick >= _open_until:
				_close_core(tick, "tijd")
			spout_glowing = tick >= _glow_from and tick < _glow_until
			if tick >= _next_beat:
				_beat(tick, p1)
		Phase.SWITCH:
			if tick >= _switch_end:
				phase = Phase.TWO
				_next_beat = tick
				_rad_hang(tick)
				phase_changed.emit(tick, "2")
				_beat(tick, p1)
			else:
				_update_rad(tick)
		Phase.TWO:
			_note_actions(tick)
			_update_rad(tick)
			if tick >= _next_beat:
				_beat(tick, p1)


## Na stap (5): adds uit de spuigaten op het eind van het gloeien; opgeloste en dode adds weg.
func after_tick(tick: int) -> void:
	if _glow_until > 0 and tick == _glow_until - 1 and state == State.FIGHT and phase == Phase.ONE:
		_spawn_adds(tick)
	for add: SliceEnemy in adds.duplicate():
		if not add.alive:
			adds.erase(add)
			if sim != null:
				sim.remove_object(add)
			add.queue_free()


# --- maat en aanvallen (B-6) ----------------------------------------------------

func _beat(tick: int, p1: Node2D) -> void:
	var g := data_group
	var px := arena_x(p1.global_position) if p1 != null else arena_width
	var side := -1 if px < middle() else 1
	if phase == Phase.ONE:
		var windup := EnemyData.ticks(g, "eerste_aanloop") if _beat_number == 0 \
			else EnemyData.ticks(g, "pomp1_aanloop")
		var width := EnemyData.value(g, "pomp_breedte")
		var x1 := middle() - width if side < 0 else middle()
		begin_attack(tick, "pomp", side, arena_rect(x1, x1 + width, 0.0, EnemyData.value(g, "pomp_hoogte")),
			windup, EnemyData.ticks(g, "pomp1_actief"), EnemyData.ticks(g, "pomp1_herstel"))
		_next_beat = tick + EnemyData.ticks(g, "maat_fase1")
	else:
		# §3.5: om en om, eerst de pompslag (hoog – laag).
		if _phase2_beats % 2 == 0:
			var width := EnemyData.value(g, "pomp_breedte")
			var x1 := clampf(px - width * 0.5, 0.0, arena_width - width)
			begin_attack(tick, "pomp", side, arena_rect(x1, x1 + width, 0.0, EnemyData.value(g, "pomp_hoogte")),
				EnemyData.ticks(g, "pomp2_aanloop"), EnemyData.ticks(g, "pomp2_actief"),
				EnemyData.ticks(g, "pomp2_herstel"))
		else:
			var width := EnemyData.value(g, "zwiep_breedte")
			var x1 := 0.0 if side < 0 else arena_width - width
			begin_attack(tick, "zwiep", side, arena_rect(x1, x1 + width, EnemyData.value(g, "zwiep_y1"),
				EnemyData.value(g, "zwiep_y2")), EnemyData.ticks(g, "zwiep_aanloop"),
				EnemyData.ticks(g, "zwiep_actief"), EnemyData.ticks(g, "zwiep_herstel"))
		_next_beat = tick + EnemyData.ticks(g, "maat_fase2")
		_phase2_beats += 1
	beat.emit(tick, _beat_number)
	_beat_number += 1


# --- fase 1 (B-7) ---------------------------------------------------------------

func _reach_threshold(tick: int) -> void:
	opening_index += 1
	if opening_index >= thresholds.size():
		_begin_switch(tick)
	else:
		_close_core(tick, "drempel")


## Het schot schuift weer voor de kern; de spuigaten gloeien (§3.4: na elke opening).
func _close_core(tick: int, reason: String) -> void:
	core_open = false
	_set_ketel(true, true, true)
	_glow_from = tick
	_glow_until = tick + EnemyData.ticks(data_group, "spuigat_gloei")
	spout_glowing = true
	core_closed.emit(tick, reason)


## GMB-12: 60 ticks geen aanval; merken op de boss doven, adds lossen op, het schot sluit voorgoed.
func _begin_switch(tick: int) -> void:
	phase = Phase.SWITCH
	core_open = false
	_switch_end = tick + EnemyData.ticks(data_group, "fasewissel_ticks")
	_glow_until = -1
	spout_glowing = false
	abort_attack(tick)
	_set_ketel(true, false, false)
	if combat != null:
		combat.fade_marks_on(parts, tick)
	_dissolve_adds()
	var p1: Node2D = sim.get_player(1) if sim != null else null
	var px := arena_x(p1.global_position) if p1 != null else 0.0
	rad_side = 1 if px < middle() else -1
	# Het rad hijst zich uit de ketel en draait naar zijn kant; raakbaar pas in fase 2.
	rad_state = RadState.TURNING
	_rad_from_x = middle()
	_rad_since = tick
	_rad_until = _switch_end
	phase_changed.emit(tick, "wissel")


# --- fase 2: het rad (B-8) ---------------------------------------------------------

## Het rad hangt aan kant `rad_side`: raakbaar, de kant begint (`kant_ticks`, `kant_treffers`).
func _rad_hang(tick: int) -> void:
	rad_state = RadState.HANGING
	rad.position.x = rad_x(rad_side)
	rad.hittable = true
	rad.markable = false
	rad_side_hits = 0
	_rad_since = tick
	_rad_until = -1
	_rad_coop = is_coop()


## §3.5: na `kant_treffers` of `kant_ticks` trilt het rad `rad_tril` ticks en draait het in
## `rad_draai` ticks naar de andere muur. Tijdens trillen en draaien is het niet raakbaar.
func _update_rad(tick: int) -> void:
	var g := data_group
	match rad_state:
		RadState.HANGING:
			var reason := ""
			# B-13 (§3.5): een drop-in/out verandert de plek van het rad: meteen trillen en draaien,
			# naar de plek van de nieuwe modus aan de andere muur. Zelfde plek (D = 60): niets.
			if is_coop() != _rad_coop:
				if absf(rad_x(rad_side) - rad.position.x) > 0.01:
					reason = "modus"
				_rad_coop = is_coop()
			if reason == "":
				rad.position.x = rad_x(rad_side)  # volgt D (SL-05)
				if rad_side_hits >= EnemyData.ticks(g, "kant_treffers"):
					reason = "treffers"
				elif tick - _rad_since >= EnemyData.ticks(g, "kant_ticks"):
					reason = "tijd"
			if reason != "":
				rad_state = RadState.SHAKING
				rad.hittable = false
				_rad_since = tick
				_rad_until = tick + EnemyData.ticks(g, "rad_tril")
				rad_turns += 1
				rad_turning.emit(tick, reason, -rad_side)
		RadState.SHAKING:
			if tick >= _rad_until:
				rad_state = RadState.TURNING
				_rad_from_x = rad.position.x
				rad_side = -rad_side
				_rad_since = tick
				_rad_until = tick + EnemyData.ticks(g, "rad_draai")
		RadState.TURNING:
			if tick >= _rad_until:
				if phase == Phase.TWO:
					_rad_hang(tick)
			else:
				var k := float(tick - _rad_since) / float(maxi(_rad_until - _rad_since, 1))
				rad.position.x = lerpf(_rad_from_x, rad_x(rad_side), k)


## RAD_TREFFER: hoe kwam P1/P2 in de lucht? Uit de bewegingsevents van deze tick (stap 1/2 is
## al geweest), één keer per tick; op de vloer begint het opnieuw.
func _note_actions(tick: int) -> void:
	if tick == _noted_tick or sim == null:
		return
	_noted_tick = tick
	for index: int in [1, 2]:
		var player: PlayerActor = sim.get_player(index)
		if player == null:
			continue
		var key := "p%d" % index
		var ev := player.move_events
		if ev & Motor.EV_LAUNCH:
			_air_action[key] = "lancering"
		elif ev & Motor.EV_CATCH:
			_air_action[key] = "vang"
		elif ev & Motor.EV_BOUNCE:
			_air_action[key] = "bounce"
		elif ev & Motor.EV_JUMP:
			_air_action[key] = "sprong"
		elif player.motor.on_floor and player.motor.support != Motor.Support.SHADOW_BODY:
			_air_action[key] = "sprong"


## V-01b: na een neerslag-stuit is de volgende treffer een "stuit".
func _on_stuit(tick: int, player: Node2D) -> void:
	_note_actions(tick)
	if player is PlayerActor:
		_air_action["p%d" % (player as PlayerActor).player_index] = "stuit"


## §3.4: uit elk spuigat één Kadeloper, zolang er minder dan `adds_max` leven.
func _spawn_adds(tick: int) -> void:
	var g := data_group
	for key: String in ["spuigat_links", "spuigat_rechts"]:
		if _living_adds() >= EnemyData.ticks(g, "adds_max"):
			return
		var add := SliceEnemy.new()
		var at := arena_point(EnemyData.value(g, key), 0.0)
		add.setup_enemy(SliceEnemy.Type.KADELOPER, at.x, at.y)
		# Vaste, unieke naam: tick en spuigat (twee adds op dezelfde tick, TD-review PR #207).
		add.name = "Add%d_%s" % [tick, key.get_slice("_", 1)]
		# Ze doen de eerste `add_inactief` ticks niets (uit de stoom stappen); eerste tick: tick + 1.
		add.hold_until(tick + 1 + EnemyData.ticks(g, "add_inactief"))
		adds.append(add)
		sim.add_object(add)
		add_spawned.emit(tick, add)


func _living_adds() -> int:
	var n := 0
	for add: SliceEnemy in adds:
		if add.alive:
			n += 1
	return n


## GMB-12, GM-11: levende adds lossen op in stoom (geen LP).
func _dissolve_adds() -> void:
	for add: SliceEnemy in adds:
		if add.alive:
			add.alive = false
			add.health = 0
			add.visible = false


func _set_ketel(armor: bool, hittable: bool, markable: bool) -> void:
	ketel.armor_intact = armor
	ketel.hittable = hittable
	ketel.markable = markable


# --- placeholder-beeld (B-11) ---------------------------------------------------

func _build_visual() -> void:
	var g := data_group
	var x1 := EnemyData.value(g, "lichaam_x1")
	var x2 := EnemyData.value(g, "lichaam_x2")
	_add_rect("Lichaam", Rect2(x1, -160.0, x2 - x1, 160.0), BODY_COLOR)
	var shot := Rect2(EnemyData.value(g, "schot_x1"), -EnemyData.value(g, "schot_y2"),
		EnemyData.value(g, "schot_x2") - EnemyData.value(g, "schot_x1"),
		EnemyData.value(g, "schot_y2") - EnemyData.value(g, "schot_y1"))
	_add_rect("Kern", shot, CORE_COLOR)
	_add_rect("Schot", shot, SHOT_COLOR)
	_add_rect("Merkplek", shot.grow(-14.0), MARK_SPOT_COLOR)
	for key: String in ["spuigat_links", "spuigat_rechts"]:
		var x := EnemyData.value(g, key)
		_add_rect("Spuigat_" + key.get_slice("_", 1), Rect2(x - 8.0, -6.0, 16.0, 6.0), SPOUT_COLOR)
	var rad_w := EnemyData.value(g, "rad_breedte")
	var rad_h := EnemyData.value(g, "rad_y2") - EnemyData.value(g, "rad_y1")
	_add_rect("RadBeeld", Rect2(-rad_w * 0.5, -rad_h * 0.5, rad_w, rad_h), RAD_COLOR)
	_add_rect("Vloerteken", Rect2(0.0, -3.0, 1.0, 3.0), FLOOR_MARK_COLOR)
	var tell := Polygon2D.new()
	tell.name = "Tell"
	tell.visible = false
	add_child(tell)


func _add_rect(node_name: String, r: Rect2, color: Color) -> void:
	var poly := Polygon2D.new()
	poly.name = node_name
	poly.polygon = PackedVector2Array([r.position, Vector2(r.end.x, r.position.y), r.end,
		Vector2(r.position.x, r.end.y)])
	poly.color = color
	add_child(poly)


## Tells (stofstrook van de pompslag, lichtstreep van de zwiep, gloeiende spuigaten), schot/kern,
## merkplek bij Wankel, tink-vonk. Alleen beeld: tests lezen de vlaggen (`is_telling`,
## `is_attack_active`, `attack_box`, `spout_glowing`, `shake_at`, `ketel.tink_tick`).
func update_visual(tick: int) -> void:
	var shown := not is_defeated()
	(get_node(^"Lichaam") as CanvasItem).visible = shown
	var shot := get_node(^"Schot") as Polygon2D
	shot.visible = shown and ketel.armor_intact and ketel.hittable and state != State.WANKEL
	shot.color = TINK_COLOR if tick - ketel.tink_tick < TINK_TICKS else SHOT_COLOR
	(get_node(^"Kern") as CanvasItem).visible = shown and core_open
	(get_node(^"Merkplek") as CanvasItem).visible = state == State.WANKEL
	(get_node(^"Spuigat_links") as CanvasItem).visible = spout_glowing
	(get_node(^"Spuigat_rechts") as CanvasItem).visible = spout_glowing
	# Het rad (GMB-04): hangt, trilt (flikkert) of draait; het vloerteken onder de hangende kant.
	var rad_visual := get_node(^"RadBeeld") as Polygon2D
	rad_visual.visible = shown and rad_state != RadState.HIDDEN
	var jitter := 1.0 if rad_state == RadState.SHAKING and tick % 4 < 2 else 0.0
	rad_visual.position = rad.position + Vector2(jitter, 0.0)
	rad_visual.color = RAD_SHAKE_COLOR if rad_state == RadState.SHAKING else RAD_COLOR
	var mark := get_node(^"Vloerteken") as Polygon2D
	mark.visible = shown and phase == Phase.TWO and rad_state == RadState.HANGING \
		and state == State.FIGHT
	if mark.visible:
		var span := floor_mark(rad_side)
		mark.polygon = PackedVector2Array([Vector2(span.x, -3.0), Vector2(span.y, -3.0), Vector2(span.y, 0.0),
			Vector2(span.x, 0.0)])
	var tell := get_node(^"Tell") as Polygon2D
	tell.visible = is_telling() or is_attack_active()
	if tell.visible:
		var r := Rect2(attack_box.position - global_position, attack_box.size)
		tell.polygon = PackedVector2Array([r.position, Vector2(r.end.x, r.position.y), r.end,
			Vector2(r.position.x, r.end.y)])
		var base := POMP_TELL if attack_kind == "pomp" else ZWIEP_TELL
		tell.color = Color(base, 0.15 + 0.45 * windup_progress(tick)) if is_telling() else ACTIVE_COLOR
