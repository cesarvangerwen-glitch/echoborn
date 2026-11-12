extends "res://scripts/objects/sim_object.gd"
## Basis van elke boss (`Boss`, gdd C-14 a; T8b B-5): levens, Wankel, de finisher, de arena en de
## reset bij een respawn. De Gemaalmeester en de testboss van de C-14/C-16-test bouwen hierop.
##
## Coördinaten: de node staat op de linkermuur, op de bovenkant van de vloer; arena-x loopt naar
## rechts, arena-y omhoog (slice-vijanden-en-boss.md §3.2). Schade komt via zijn delen (`BossPart`)
## in stap (4) binnen (`receive`); aanvallen, maat en finisher lopen in stap (5) (`sim_update`).
##
## Wankel en finisher (C-14): op of onder `wankel_se` valt hij niet meer aan en doen treffers en
## ontploffingen 0 SE; de eerste merk-ontploffing die hem dan raakt, start de finisher op `t_f`.
## Die speelt de AANVAL-events van P1 en het tweede lichaam (solo de echo als hij Actief was, co-op
## P2) uit `t_f − 600 … t_f − 1`, vanaf `BOSS_START`, af als finisherslagen op `t_f + ⌊i / 5⌋`;
## op `t_f + 120` is hij verslagen. Het finisherlog luistert naar `Sim.attack_executed`.

## BOSS_START: P1 kwam de arena in; de arena sluit (GM-01, L-13 a).
signal boss_started(tick: int)
## BOSS_VERSLAGEN: op `t_f + 120`; de arena gaat open (C-14 d).
signal boss_defeated(tick: int)
## P1 respawnde (0 levenspunten): de boss begint opnieuw (GM-11).
signal boss_reset(tick: int)
## De arena gaat dicht (`closed`) of open (GM-01).
signal arena_changed(tick: int, closed: bool)
## Een nieuwe fase (meetlog BOSS_FASE, B-10): de boss zegt welke ("1", "wissel", "2", "wankel").
signal phase_changed(tick: int, phase: String)
## Schade aan de boss (na klemmen), met de bron uit `Combat` ("p1", "p2", "echo", "ontploffing").
signal damaged(tick: int, amount: int, source: String)
## FINISHER_START op `t_f` (C-14 b).
signal finisher_started(tick: int)
## FINISHERSLAG (C-14 c): `who` is "p1", "p2" of "echo"; +1 LP (`LightMeter.watch_boss`).
signal finisher_strike(tick: int, who: String)
## Een aanvalsvlak van de boss raakte P1 (1 levenspunt, VJ-02). De Sim verbindt dit (`add_object`).
signal hit_player(tick: int, player: Node2D)
## Een aanloop begint (tell in beeld en geluid, §9): soort, helft (−1 links, +1 rechts, 0 geen).
signal attack_started(tick: int, kind: String, side: int)
## Een aanval is voorbij of afgebroken (meetlog BOSS_AANVAL, B-10): raakte hij P1?
signal attack_ended(tick: int, kind: String, side: int, hit: bool)

const EnemyData = preload("res://scripts/combat/enemy_data.gd")
const BossPart = preload("res://scripts/combat/boss_part.gd")
const PlayerActor = preload("res://scripts/echo/player_actor.gd")
const Tuning = preload("res://scripts/echo/tuning.gd")
const BodyBuilder = preload("res://scripts/echo/body_builder.gd")

enum State { IDLE, FIGHT, WANKEL, FINISHER, DEFEATED }
## Fase van een aanval (VJ-01): aanloop met tell, actief vlak, herstel.
enum AttackPhase { IDLE, WINDUP, ACTIVE, RECOVER }

## Placeholder-kleuren van de gedeelde echo: half licht, half schaduw (C-14, pitch §5).
const SHARED_LIGHT := Color(1.0, 0.9, 0.6, 0.8)
const SHARED_SHADOW := Color(0.1, 0.1, 0.15, 0.8)

## Groep in `slice.csv` met de waarden van deze boss.
var data_group := ""
var state: State = State.IDLE
var se_max := 0
var se := 0
## C-14 a: de finisherdrempel (Wankel op of onder deze SE; de boss klemt erop).
var wankel_se := 0
## Breedte van de arena (px, vanaf de linkermuur): P1 hierbinnen = BOSS_START.
var arena_width := 600.0
## BOSS_START pas als het middelpunt van P1 zo ver binnen elke muur staat (px). 0 = op de muur (de
## arena van de tests); in een gebied staat P1 dan helemaal binnen als de deur dichtgaat (#83).
var start_inset := 0.0
## BOSS_START alleen als het middelpunt van P1 hooguit zo hoog boven de vloer staat (px). INF = elke
## hoogte; in een gebied ligt er een kamer boven de arena (Kadewijk: S6 boven S8, #83).
var arena_height := INF
## BOSS_START pas als elk lichaam (P1, P2, de echo die afspeelt; C-01) in de arena staat, en met een
## echo pas als P1 er al D ticks in staat (dan loopt ook de echo, die P1 D ticks later volgt, er
## helemaal in). In een gebied gaat bij BOSS_START een deur dicht, en een echo die daar nog loopt,
## breekt erop (E-08); zo komt P2 ook niet buiten te staan (werkaanname GP, #83). Uit = alleen P1,
## meteen (de arena van de tests).
var start_with_all_bodies := false
var arena_closed := false
var start_tick := -1
## `t_f` (C-14 b), of -1.
var finisher_tick := -1
var defeated_tick := -1
## Hoeveel finisherslagen de laatste finisher had (meetlog bij BOSS_VERSLAGEN, gdd §4.5).
var finisher_count := 0
## De hurtboxes (`BossPart`), in volgorde van toevoegen.
var parts: Array = []
## De gedeelde echo tijdens de finisher, anders null (C-01: geen lichaam, laag 0, masker 0).
var shared_echo: CharacterBody2D = null
## Gezet door `attach` en `Sim.add_object`.
var sim: Node = null
var combat: RefCounted = null

## De aanval van nu (B-6): vlaggen die tests, HUD en audio lezen.
var attack_kind := ""
var attack_side := 0
var attack_phase: AttackPhase = AttackPhase.IDLE
## Het vlak van de aanval van nu in wereldcoördinaten (bekend vanaf het begin van de aanloop).
var attack_box := Rect2()

var _finisher_ticks := 120
var _finisher_source := 600
## Finisherlog (C-04): [tick, wie] van elk uitgevoerd AANVAL-event sinds BOSS_START.
var _log: Array = []
## Finisherslagen die nog moeten komen: [tick, wie], oplopend.
var _strikes: Array = []
## Deuren van de arena: [lichaam, laag als hij dicht is].
var _doors: Array = []
## Sinds deze tick staat P1 (onafgebroken) in de arena, of -1 (`start_with_all_bodies`).
var _inside_since := -1
var _attack_hit := false
var _attack_start := 0
var _windup_end := 0
var _active_end := 0
var _recover_end := 0


## Leest de waarden uit `slice.csv` (groep `group`): `se`, `wankel_se`, `finisher_*`.
func setup_boss(group: String) -> void:
	data_group = group
	se_max = EnemyData.ticks(group, "se")
	se = se_max
	wankel_se = EnemyData.ticks(group, "wankel_se")
	arena_width = EnemyData.value(group, "arena_breedte")
	_finisher_ticks = EnemyData.ticks(group, "finisher_ticks")
	_finisher_source = EnemyData.ticks(group, "finisher_bron")


## Een hurtbox op arena-punt (`x`, `y`) met `size`.
func add_part(part_name: String, size: Vector2, at: Vector2) -> BossPart:
	var part := BossPart.new()
	part.setup_part(self, part_name, size, Vector2(at.x, -at.y))
	parts.append(part)
	add_child(part)
	return part


## Meldt de boss en zijn delen bij de Sim aan en luistert naar de AANVAL-events (C-04).
func attach(p_sim: Node) -> void:
	sim = p_sim
	sim.add_object(self)
	for part: BossPart in parts:
		sim.add_object(part)
	sim.attack_executed.connect(_on_attack_executed)
	sim.tick_finished.connect(after_tick)


## Meldt de boss, zijn delen en zijn signalen bij de Sim af: de kamer van de arena ontlaadt (R10,
## #83). Aanroepen tussen twee ticks of in `sim_track`, zoals `Sim.remove_object`. De node zelf
## ruimt de aanroeper op; daarna doet hij niets meer.
func detach() -> void:
	if sim == null:
		return
	abort_attack(sim.tick)
	_end_finisher()
	on_detach()
	for part: BossPart in parts:
		sim.remove_object(part)
	sim.remove_object(self)
	if sim.attack_executed.is_connected(_on_attack_executed):
		sim.attack_executed.disconnect(_on_attack_executed)
	if sim.tick_finished.is_connected(after_tick):
		sim.tick_finished.disconnect(after_tick)
	# `Sim.add_object` verbond `hit_player` met de Sim; alleen die verbinding gaat los.
	for c: Dictionary in hit_player.get_connections():
		if (c["callable"] as Callable).get_object() == sim:
			hit_player.disconnect(c["callable"])
	sim = null


## GM-01: een deur die dicht is (botsing op `closed_layer`) zolang de arena dicht is.
func add_door(door: CollisionObject2D, closed_layer: int) -> void:
	_doors.append([door, closed_layer])
	door.collision_layer = closed_layer if arena_closed else 0


func is_wankel() -> bool:
	return state == State.WANKEL


func is_finisher_running() -> bool:
	return state == State.FINISHER


func is_defeated() -> bool:
	return state == State.DEFEATED


func is_telling() -> bool:
	return attack_phase == AttackPhase.WINDUP


func is_attack_active() -> bool:
	return attack_phase == AttackPhase.ACTIVE


## Hoe ver de aanloop is (0 … 1), voor een tell die feller wordt (§3.4).
## Eerste actieve tick van de aanval van nu (einde van de aanloop), voor bots en tests.
func windup_end_tick() -> int:
	return _windup_end


## Eerste tick na het actieve vlak van de aanval van nu.
func active_end_tick() -> int:
	return _active_end


func windup_progress(tick: int) -> float:
	if attack_phase != AttackPhase.WINDUP:
		return 1.0
	var total := float(maxi(_windup_end - _attack_start, 1))
	return clampf(float(tick - _attack_start + 1) / total, 0.0, 1.0)


## Wereldpunt van arena-punt (`x`, `y`).
func arena_point(x: float, y: float) -> Vector2:
	return global_position + Vector2(x, -y)


## Wereldvlak van arena-x `x1 … x2` en hoogte `y1 … y2`.
func arena_rect(x1: float, x2: float, y1: float, y2: float) -> Rect2:
	return Rect2(global_position + Vector2(x1, -y2), Vector2(x2 - x1, y2 - y1))


## Arena-x van een wereldpunt.
func arena_x(at: Vector2) -> float:
	return at.x - global_position.x


## Staat het wereldpunt `at` (het middelpunt van P1) in de arena: BOSS_START (GM-01, L-13 a)?
func is_in_arena(at: Vector2) -> bool:
	var x := arena_x(at)
	var up := global_position.y - at.y
	return x >= start_inset and x <= arena_width - start_inset and up <= arena_height


## BOSS_START (normaal: P1 komt de arena in, `sim_update`).
func start(tick: int) -> void:
	if state != State.IDLE:
		return
	state = State.FIGHT
	start_tick = tick
	_log.clear()
	_set_arena(tick, true)
	boss_started.emit(tick)
	on_start(tick)


## Debugcommando (gdd §4.6 C-14): zet de SE, bv. op de drempel. Geen klem, geen merk.
func set_health(tick: int, value: int) -> void:
	se = clampi(value, 0, se_max)
	on_health_set(tick)
	if state == State.FIGHT and se <= wankel_se:
		_enter_wankel(tick)


## Stap (4): schade van `amount` SE op `part` van `source`. Geeft de toegepaste schade terug.
func receive(tick: int, amount: int, source: String, part: BossPart) -> int:
	amount = damage_for(part, amount, source)
	if state == State.WANKEL:
		# C-14 a/b: 0 SE; de eerste merk-ontploffing (elke schakel) start de finisher.
		if source == "ontploffing":
			_start_finisher(tick)
		return 0
	if state != State.FIGHT or amount <= 0:
		return 0
	var lowest := maxi(wankel_se, damage_floor(part))
	var done := clampi(amount, 0, maxi(se - lowest, 0))
	se -= done
	if done > 0:
		damaged.emit(tick, done, source)
	on_damage(tick, done, source, part)
	if state == State.FIGHT and se <= wankel_se:
		_enter_wankel(tick)
	return done


## Een pantser van een deel brak (E-14g); de Gemaalmeester opent dan de kern.
func on_armor_broken(_tick: int, _part: BossPart) -> void:
	pass


## Stap (5).
func sim_update(tick: int, bodies: Array[Node2D]) -> void:
	var p1 := _p1_of(bodies)
	var p1_actor: PlayerActor = sim.get_player(1) if sim != null else null
	# GM-11: P1 respawnde na 0 levenspunten: de boss begint opnieuw, buiten de arena.
	if p1_actor != null and p1_actor.died and (state == State.FIGHT or state == State.WANKEL):
		reset(tick)
	if state == State.IDLE and p1 != null:
		if not is_in_arena(p1.global_position):
			_inside_since = -1
		elif _inside_since < 0:
			_inside_since = tick
		if _inside_since >= 0 and (not start_with_all_bodies or _all_inside(tick, bodies)):
			start(tick)
	if state == State.FIGHT:
		_step_attack(tick, p1)
		fight_update(tick, p1)
	elif state == State.FINISHER:
		while not _strikes.is_empty() and int(_strikes[0][0]) <= tick:
			var strike: Array = _strikes.pop_front()
			finisher_count += 1
			finisher_strike.emit(tick, strike[1])
		if tick >= finisher_tick + _finisher_ticks:
			_defeat(tick)
	update_visual(tick)


## GM-11: terug naar het begin, de arena open; begint opnieuw als P1 de arena in komt.
func reset(tick: int) -> void:
	abort_attack(tick)
	state = State.IDLE
	se = se_max
	start_tick = -1
	_inside_since = -1
	finisher_tick = -1
	_log.clear()
	_strikes.clear()
	_end_finisher()
	_set_arena(tick, false)
	on_reset(tick)
	boss_reset.emit(tick)


# --- voor de soorten boss -------------------------------------------------------

## De schade die `part` van `source` krijgt; standaard die van `Combat` (het rad: 15 / 5, §3.5).
func damage_for(_part: BossPart, amount: int, _source: String) -> int:
	return amount


## Onder deze SE kan `part` nu niet komen (bv. de drempel van een opening, GMB-11).
func damage_floor(_part: BossPart) -> int:
	return 0


func on_start(_tick: int) -> void:
	pass


func on_damage(_tick: int, _done: int, _source: String, _part: BossPart) -> void:
	pass


func on_health_set(_tick: int) -> void:
	pass


func on_wankel(_tick: int) -> void:
	pass


func on_reset(_tick: int) -> void:
	pass


## `detach`: de soort ruimt zijn eigen objecten bij de Sim op (adds, extra signalen).
func on_detach() -> void:
	pass


## Stap (5) tijdens het gevecht, na de aanval van nu: maat, nieuwe aanvallen, fasen.
func fight_update(_tick: int, _p1: Node2D) -> void:
	pass


## Na stap (5) (`Sim.tick_finished`): objecten aan- of afmelden mag hier (adds).
func after_tick(_tick: int) -> void:
	pass


func update_visual(_tick: int) -> void:
	pass


## Begint een aanval op `tick`: `windup` ticks aanloop (tell), `active` ticks vlak `box`, `recover`.
func begin_attack(tick: int, kind: String, side: int, box: Rect2, windup: int, active: int,
		recover: int) -> void:
	abort_attack(tick)
	attack_kind = kind
	attack_side = side
	attack_box = box
	attack_phase = AttackPhase.WINDUP
	_attack_hit = false
	_attack_start = tick
	_windup_end = tick + windup
	_active_end = _windup_end + active
	_recover_end = _active_end + recover
	attack_started.emit(tick, kind, side)


## Een aanval die loopt, breekt af (fasewissel, Wankel, reset).
func abort_attack(tick: int) -> void:
	if attack_phase == AttackPhase.IDLE:
		return
	attack_phase = AttackPhase.IDLE
	attack_ended.emit(tick, attack_kind, attack_side, _attack_hit)


## Gaat de boss midden in een finisher uit de scène (arena verlaten, laden), dan blokkeert
## `Combat.finisher_running` de merken niet blijvend (SM-review PR #207).
func _exit_tree() -> void:
	if state == State.FINISHER and combat != null and "finisher_running" in combat:
		combat.finisher_running = false


# --- intern --------------------------------------------------------------------

func _step_attack(tick: int, p1: Node2D) -> void:
	if attack_phase == AttackPhase.IDLE:
		return
	if tick >= _recover_end:
		attack_phase = AttackPhase.IDLE
		attack_ended.emit(tick, attack_kind, attack_side, _attack_hit)
		return
	if tick >= _active_end:
		attack_phase = AttackPhase.RECOVER
		return
	if tick < _windup_end:
		return
	attack_phase = AttackPhase.ACTIVE
	# Alleen P1 (E-14h, C-02), één keer per aanval; geen contactschade (GM-02).
	if not _attack_hit and p1 != null and attack_box.intersects(_body_rect(p1)):
		_attack_hit = true
		hit_player.emit(tick, p1)


func _enter_wankel(tick: int) -> void:
	state = State.WANKEL
	abort_attack(tick)
	on_wankel(tick)
	phase_changed.emit(tick, "wankel")


func _start_finisher(tick: int) -> void:
	state = State.FINISHER
	finisher_tick = tick
	finisher_count = 0
	if combat != null and "finisher_running" in combat:
		combat.finisher_running = true
	# C-14 c: event op tick `t_f − 600 + i` (i = 0 … 599) → finishertick ⌊i / 5⌋.
	var from := tick - _finisher_source
	var speed := maxi(_finisher_source / maxi(_finisher_ticks, 1), 1)
	_strikes.clear()
	for entry: Array in _log:
		var at: int = entry[0]
		if at >= from and at < tick and at >= start_tick:
			_strikes.append([tick + (at - from) / speed, entry[1]])
	_strikes.sort_custom(func(a: Array, b: Array) -> bool: return int(a[0]) < int(b[0]))
	_spawn_shared_echo()
	finisher_started.emit(tick)


func _defeat(tick: int) -> void:
	state = State.DEFEATED
	defeated_tick = tick
	_end_finisher()
	_set_arena(tick, false)
	boss_defeated.emit(tick)


func _end_finisher() -> void:
	if combat != null and "finisher_running" in combat:
		combat.finisher_running = false
	if shared_echo != null:
		shared_echo.queue_free()
		shared_echo = null


## C-01: de gedeelde echo is geen lichaam: geen botsing, geen masker, geen plank.
func _spawn_shared_echo() -> void:
	var node := CharacterBody2D.new()
	node.name = "GedeeldeEcho"
	node.collision_layer = 0
	node.collision_mask = 0
	var size := Tuning.body_size()
	var light := Polygon2D.new()
	light.polygon = PackedVector2Array([Vector2(-size.x * 0.5, -size.y * 0.5), Vector2(0, -size.y * 0.5),
		Vector2(0, size.y * 0.5), Vector2(-size.x * 0.5, size.y * 0.5)])
	light.color = SHARED_LIGHT
	node.add_child(light)
	var shadow := Polygon2D.new()
	shadow.polygon = PackedVector2Array([Vector2(0, -size.y * 0.5), Vector2(size.x * 0.5, -size.y * 0.5),
		Vector2(size.x * 0.5, size.y * 0.5), Vector2(0, size.y * 0.5)])
	shadow.color = SHARED_SHADOW
	node.add_child(shadow)
	var at: Vector2 = parts[0].position if not parts.is_empty() else Vector2.ZERO
	node.position = Vector2(at.x, -size.y * 0.5)
	add_child(node)
	shared_echo = node


func _set_arena(tick: int, closed: bool) -> void:
	if arena_closed == closed:
		return
	arena_closed = closed
	for door: Array in _doors:
		(door[0] as CollisionObject2D).collision_layer = int(door[1]) if closed else 0
	arena_changed.emit(tick, closed)


## C-04: een AANVAL-event van P1, P2 of de Actieve echo (ook een merksprong), vanaf BOSS_START.
func _on_attack_executed(tick: int, actor: Node2D) -> void:
	if state != State.FIGHT and state != State.WANKEL:
		return
	var who := "echo"
	if actor is PlayerActor:
		who = "p%d" % (actor as PlayerActor).player_index
	_log.append([tick, who])
	while not _log.is_empty() and int(_log[0][0]) < tick - _finisher_source:
		_log.pop_front()


## `start_with_all_bodies`: elk lichaam in de arena, en met een echo P1 al D ticks.
func _all_inside(tick: int, bodies: Array[Node2D]) -> bool:
	for body in bodies:
		if not is_in_arena(body.global_position):
			return false
	if sim != null and not sim.echoes.is_empty() and combat != null and "tail_ticks" in combat:
		return tick - _inside_since >= int(combat.tail_ticks)
	return true


func _p1_of(bodies: Array[Node2D]) -> Node2D:
	for body in bodies:
		if (body as CollisionObject2D).collision_layer & Layers.LIGHT:
			return body
	return null


func _body_rect(body: Node2D) -> Rect2:
	var size := Tuning.body_size()
	return Rect2(body.global_position - size * 0.5, size)
