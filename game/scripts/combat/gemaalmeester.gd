extends "res://scripts/combat/boss.gd"
## De Gemaalmeester, de boss van de slice (T8b B-5–B-7; slice-vijanden-en-boss.md v0.1.1 §3,
## gemaalmeester.md v0.2). Alle waarden uit `slice.csv`, groep `gemaalmeester`.
##
## Fase 1, het schot (GMB-02, GMB-11, §3.4): de ketel is een `Pantserdoel` op de merkplek (300, 36);
## alleen een merk-ontploffing breekt het schot. Dan ligt de kern open tot de drempel van de opening
## (1350 / 1200 / 1050 / 900 SE, de boss klemt erop) of 300 ticks; daarna sluit het schot weer en
## komen er uit de spuigaten max. 2 Kadelopers (30 ticks gloeien, 30 ticks inactief). Na de laatste
## drempel de fasewissel (60 ticks, GMB-12), dan fase 2 (het rad volgt in B-8, deel 2b).
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
## Schermschok (B-11): `ticks` lang `px` (schotbreuk 6 / 2).
signal screen_shake(tick: int, ticks: int, px: float)

const SliceEnemy = preload("res://scripts/combat/slice_enemy.gd")

enum Phase { ONE, SWITCH, TWO }

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
var rad_side := 0
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
	_build_visual()
	on_reset(0)


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
	_set_ketel(true, true, true)
	if combat != null:
		combat.fade_marks_on(parts, tick)
	_dissolve_adds()


## GMB-11: in een opening klemt de boss op de drempel van die opening; dicht doet niets af.
func damage_floor(_part: BossPart) -> int:
	if phase == Phase.ONE and core_open and opening_index < thresholds.size():
		return thresholds[opening_index]
	return se


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


func on_damage(tick: int, _done: int, _source: String, _part: BossPart) -> void:
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
				phase_changed.emit(tick, "2")
				_beat(tick, p1)
		Phase.TWO:
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
	phase_changed.emit(tick, "wissel")


## §3.4: uit elk spuigat één Kadeloper, zolang er minder dan `adds_max` leven.
func _spawn_adds(tick: int) -> void:
	var g := data_group
	for key: String in ["spuigat_links", "spuigat_rechts"]:
		if _living_adds() >= EnemyData.ticks(g, "adds_max"):
			return
		var add := SliceEnemy.new()
		var at := arena_point(EnemyData.value(g, key), 0.0)
		add.setup_enemy(SliceEnemy.Type.KADELOPER, at.x, at.y)
		add.name = "Add%d" % tick
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
	var tell := get_node(^"Tell") as Polygon2D
	tell.visible = is_telling() or is_attack_active()
	if tell.visible:
		var r := Rect2(attack_box.position - global_position, attack_box.size)
		tell.polygon = PackedVector2Array([r.position, Vector2(r.end.x, r.position.y), r.end,
			Vector2(r.position.x, r.end.y)])
		var base := POMP_TELL if attack_kind == "pomp" else ZWIEP_TELL
		tell.color = Color(base, 0.15 + 0.45 * windup_progress(tick)) if is_telling() else ACTIVE_COLOR
