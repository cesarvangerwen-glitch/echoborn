extends RefCounted
## Tests voor het beeld van de slice-vijanden (Technical Artist, #272; overdracht
## `docs/art/animatie-timing.md` §2.5, manifests `kadeloper.json`,
## `schotdrager.json`, `dwaallicht.json`).
##
## De sprite-frames volgen de toestand van de vijand, tick voor tick; de Sim
## verandert niet (`test_vijanden.gd` houdt de ticks):
## - de lagen staan op de offset en z-index uit het manifest; links = `flip_h`
##   met `offset_links`; grijs bij `lit = false`, kleur bij `lit = true`;
## - lopen terwijl hij schuift, staan als hij stilstaat;
## - de aanloop (30, verlicht 40): frame 0–3 op kwarten van (aanloop − 3), frame
##   4 (de uithaal) precies de laatste 3 ticks; het actieve vlak = het verste
##   frame (6 ticks); herstel 20; tell vroeg / laat / actief precies op het vlak;
## - Schotdrager: tink 4, breuk 12, dan `gebroken_*`, en `stuk` op de vloer;
## - stil na een treffer (30); uit de stoom (30) bij een add; dood (48) als los
##   effect naast de vijand, daarna weg;
## - Dwaallicht: aanloop met tell en duiklijn op de landingsplek, duik 8, terug 40.

const Fx = preload("res://tests/echo_fixture.gd")
const SliceEnemy = preload("res://scripts/combat/slice_enemy.gd")
const EnemyData = preload("res://scripts/combat/enemy_data.gd")
const Beeld = preload("res://art/animatie/vijanden/vijand_beeld.gd")

const KADELOPER := SliceEnemy.Type.KADELOPER
const SCHOTDRAGER := SliceEnemy.Type.SCHOTDRAGER
const DWAALLICHT := SliceEnemy.Type.DWAALLICHT


func _world(t, x: float) -> Dictionary:
	var sim = Fx.world(t)
	var p1 := Fx.manual_player(sim, 1, Vector2(x, Fx.STAND_Y))
	p1.health = 100000
	sim.set_tail_ticks(60)
	return {"sim": sim, "p1": p1}


func _enemy(sim: Node, type: int, x: float, lit := false) -> SliceEnemy:
	var enemy := SliceEnemy.new()
	enemy.lit = lit
	enemy.setup_enemy(type, x, Fx.FLOOR_TOP)
	sim.add_object(enemy)
	return enemy


func _blad(naam: String, blad: String) -> Dictionary:
	return Beeld.lees_manifest(naam)["bladen"][blad]


func _v(a: Array) -> Vector2:
	return Vector2(a[0], a[1])


## Per tick: [anim, frame] van het lijf, de tell (of ""), en de plek van de tell.
func _trace(sim: Node, enemy: SliceEnemy) -> Dictionary:
	var rows := {}
	sim.tick_finished.connect(func(tick: int) -> void:
		var lijf = enemy.get_node("Lijf")
		var tell = enemy.get_node("Tell")
		rows[tick] = {"lijf": "%s/%d" % [lijf.anim, lijf.frame_nr], "flip": lijf.flip_h, "pos": lijf.position,
			"tell": tell.anim if tell.visible else "", "tell_pos": tell.global_position, "tell_rect": tell.region_rect,
			"phase": enemy.phase, "box": enemy.active_box, "wbox": enemy._walker_box() if enemy.enemy_type != DWAALLICHT else Rect2(), "x": enemy.position.x, "texture": lijf.texture.resource_path,
			"lijn": enemy.get_node("Duiklijn").region_rect.size.y if enemy.has_node("Duiklijn") and enemy.get_node("Duiklijn").visible else -1.0,
			"lijn_pos": enemy.get_node("Duiklijn").global_position if enemy.has_node("Duiklijn") else Vector2.ZERO})
	return rows


## Hoe vaak elk frame van `anim` achter elkaar staat, vanaf `from`.
func _runs(rows: Dictionary, from: int, anim: String) -> Array:
	var out: Array = []
	var tick := from
	while rows.has(tick) and String(rows[tick]["lijf"]).begins_with(anim + "/"):
		var f: String = rows[tick]["lijf"]
		var n := 0
		while rows.has(tick) and rows[tick]["lijf"] == f:
			n += 1
			tick += 1
		out.append(n)
	return out


func _first(rows: Dictionary, key: String, value) -> int:
	var ticks := rows.keys()
	ticks.sort()
	for tick: int in ticks:
		if rows[tick][key] == value or (value is String and String(rows[tick][key]).begins_with(value)):
			return tick
	return -1


## Het beeld leest `Phase.RECOVER` als getal (geen preload-kring met `slice_enemy.gd`).
func test_beeld_constanten(t) -> void:
	t.check(Beeld.RECOVER == SliceEnemy.Phase.RECOVER and SliceEnemy.TINK_TICKS == 4,
		"RECOVER %d / %d, TINK_TICKS %d" % [Beeld.RECOVER, SliceEnemy.Phase.RECOVER, SliceEnemy.TINK_TICKS])
	for naam: String in ["kadeloper", "schotdrager", "dwaallicht"]:
		var m := Beeld.lees_manifest(naam)
		var anims: Dictionary = m["bladen"][naam]["animaties"]
		for rol: String in Beeld.ANIMS[naam]:
			t.check(anims.has(Beeld.ANIMS[naam][rol]), "%s: animatie %s ontbreekt" % [naam, Beeld.ANIMS[naam][rol]])
		t.check(anims.has("dood") and m["bladen"].has(Beeld.TELLS[naam]), "%s: dood of tell ontbreekt" % naam)
	for rol: String in Beeld.ANIMS["schotdrager_gebroken"]:
		t.check(_blad("schotdrager", "schotdrager")["animaties"].has(Beeld.ANIMS["schotdrager_gebroken"][rol]),
			"schotdrager: %s ontbreekt" % rol)
	await t.cleanup()


## Kadeloper: lopen naar P1, de haakslag (aanloop 7 7 7 6 3, slag 3 3, herstel 10 10) met de tell
## precies op het vlak, links gespiegeld met `offset_links`; grijs (donkere wijk).
func test_kadeloper_haakslag(t) -> void:
	var w := _world(t, 100.0)
	var sim = w["sim"]
	var enemy := _enemy(sim, KADELOPER, 200.0)
	var blad := _blad("kadeloper", "kadeloper")
	var tell_blad := _blad("kadeloper", "tell_haak")
	t.check(enemy.get_node("Lijf") is Sprite2D and not (enemy.get_node("Beeld") as CanvasItem).visible,
		"geen sprite, of het placeholderbeeld staat nog aan")
	var rows := _trace(sim, enemy)
	var started := []
	enemy.attack_started.connect(func(tick: int) -> void: started.append(tick))
	await t.run_ticks(sim, 300)
	t.check(not started.is_empty(), "geen aanloop")
	if started.is_empty():
		await t.cleanup()
		return
	var t0: int = started[0]
	var r0: Dictionary = rows[t0 - 1]
	t.check(String(r0["lijf"]).begins_with("lopen/") and r0["flip"] and r0["pos"] == _v(blad["offset_links"]),
		"vóór de aanloop: %s, flip %s, offset %s" % [r0["lijf"], r0["flip"], r0["pos"]])
	t.check(String(r0["texture"]).ends_with("kadeloper_grijs.png"), "texture %s" % r0["texture"])
	t.check(_runs(rows, t0, "haak_aanloop") == [7, 7, 7, 6, 3], "aanloop %s" % [_runs(rows, t0, "haak_aanloop")])
	t.check(_runs(rows, t0 + 30, "haak_slag") == [3, 3] and rows[t0 + 30]["phase"] == SliceEnemy.Phase.ACTIVE,
		"slag %s" % [_runs(rows, t0 + 30, "haak_slag")])
	t.check(_runs(rows, t0 + 36, "haak_herstel") == [10, 10], "herstel %s" % [_runs(rows, t0 + 36, "haak_herstel")])
	var tells: Array = []
	var off := _v(tell_blad["offset"])
	var on_box := true
	for tick in range(t0, t0 + 36):
		tells.append(rows[tick]["tell"])
		var box: Rect2 = rows[tick]["wbox"] if tick < t0 + 30 else rows[tick]["box"]
		on_box = on_box and rows[tick]["tell_pos"] - off == box.position and rows[tick]["tell_rect"].size == box.size + Vector2(2, 2)
	t.check(tells.count("vroeg") == 15 and tells.count("laat") == 15 and tells.count("actief") == 6
		and tells.slice(0, 15).count("vroeg") == 15, "tell %s" % [tells])
	t.check(on_box, "de tell ligt niet op het vlak")
	t.check(rows[t0 + 36]["tell"] == "" and rows[t0 + 56]["lijf"] != rows[t0 + 55]["lijf"],
		"na het herstel: tell %s, lijf %s" % [rows[t0 + 36]["tell"], rows[t0 + 56]["lijf"]])
	await t.cleanup()


## Verlicht (VJ-06, s = 2): de kleur-atlas en de aanloop van 40 (10 9 9 9 3); rechts zonder flip.
func test_kadeloper_verlicht(t) -> void:
	var w := _world(t, 300.0)
	var sim = w["sim"]
	var enemy := _enemy(sim, KADELOPER, 200.0, true)
	var rows := _trace(sim, enemy)
	var started := []
	enemy.attack_started.connect(func(tick: int) -> void: started.append(tick))
	await t.run_ticks(sim, 500)
	t.check(not started.is_empty(), "geen aanloop")
	if started.is_empty():
		await t.cleanup()
		return
	var t0: int = started[0]
	t.check(_runs(rows, t0, "haak_aanloop") == [10, 9, 9, 9, 3], "aanloop %s" % [_runs(rows, t0, "haak_aanloop")])
	t.check(String(rows[t0]["texture"]).ends_with("kadeloper_kleur.png") and not rows[t0]["flip"]
		and rows[t0]["pos"] == _v(_blad("kadeloper", "kadeloper")["offset"]), "verlicht: %s" % [rows[t0]])
	# Lopen verlicht: ticks × 2 (16 per frame).
	var walk := _first(rows, "lijf", "lopen/")
	t.check(walk >= 0 and _runs(rows, walk, "lopen").slice(1, 3) == [16, 16], "lopen verlicht %s" % [_runs(rows, walk, "lopen")])
	enemy._beeld.set_staat("half")
	await t.run_ticks(sim, 1)
	t.check(String(enemy.get_node("Lijf").texture.resource_path).ends_with("kadeloper_half.png")
		and String(enemy.get_node("Tell").texture.resource_path).ends_with("tell_haak_half.png"),
		"set_staat(half): %s" % enemy.get_node("Lijf").texture.resource_path)
	await t.cleanup()


## Stil na een treffer (VJ-04): stil 4 18 8; staan zolang hij vastgehouden wordt (het wekken).
func test_stil_na_treffer(t) -> void:
	var w := _world(t, 600.0)
	var sim = w["sim"]
	var enemy := _enemy(sim, KADELOPER, 200.0)
	var rows := _trace(sim, enemy)
	await t.run_ticks(sim, 5)
	# Het wekken van de Kadewijk: 2 ticks vasthouden, elke tick opnieuw = staan, niet stil.
	for i in 10:
		enemy.hold_until(sim.tick + 2)
		await t.run_ticks(sim, 1)
	t.check(String(rows[sim.tick - 1]["lijf"]).begins_with("staan/"), "vastgehouden: %s" % rows[sim.tick - 1]["lijf"])
	# `run_ticks` komt terug vóór de Sim stapt: `sim.tick` is de tick die nu komt (zoals stap 4).
	var hit: int = sim.tick
	enemy.apply_damage(hit, 10, "p1")
	enemy.stun(hit)
	await t.run_ticks(sim, 40)
	var from := _first(rows, "lijf", "stil/")
	t.check(from == hit and _runs(rows, from, "stil") == [4, 18, 8],
		"stil vanaf %d (%d): %s" % [from, hit, _runs(rows, from, "stil")])
	await t.cleanup()


## Schotdrager: tink 4 (het schot heel), breuk 4 4 4, dan `gebroken_*`; de stukken blijven
## liggen op de plek van de breuk.
func test_schotdrager_tink_en_breuk(t) -> void:
	var w := _world(t, 600.0)
	var sim = w["sim"]
	var enemy := _enemy(sim, SCHOTDRAGER, 200.0)
	var rows := _trace(sim, enemy)
	await t.run_ticks(sim, 3)
	var tick: int = sim.tick
	enemy.tink(tick)
	await t.run_ticks(sim, 8)
	t.check(_runs(rows, tick, "tink") == [4] and not String(rows[tick + 4]["lijf"]).begins_with("tink"),
		"tink %s" % [_runs(rows, tick, "tink")])
	var at: Vector2 = enemy.position
	var kant := "offset_links" if enemy.facing < 0 else "offset"
	tick = sim.tick
	enemy.break_armor(tick)
	await t.run_ticks(sim, 40)
	t.check(_runs(rows, tick, "breuk") == [4, 4, 4], "breuk %s" % [_runs(rows, tick, "breuk")])
	t.check(String(rows[tick + 12]["lijf"]).begins_with("gebroken_stil/") and String(rows[sim.tick - 1]["lijf"]).begins_with("gebroken_"),
		"na de breuk: %s, %s" % [rows[tick + 12]["lijf"], rows[sim.tick - 1]["lijf"]])
	var stuk: Sprite2D = enemy._beeld.stuk
	t.check(stuk != null and stuk.get_parent() == enemy.get_parent() and stuk.anim == "stuk"
		and stuk.position == at + _v(_blad("schotdrager", "schotdrager")[kant]) and stuk.flip_h == (enemy.facing < 0),
		"stuk %s" % [stuk.position if stuk != null else null])
	await t.cleanup()


## Dood (voorstel 48 ticks): los effect op zijn plek, de vijand zelf is meteen weg (LM-13).
func test_dood_als_effect(t) -> void:
	var w := _world(t, 600.0)
	var sim = w["sim"]
	var enemy := _enemy(sim, KADELOPER, 200.0)
	await t.run_ticks(sim, 3)
	var at: Vector2 = enemy.position
	var links := enemy.facing < 0
	enemy.apply_damage(sim.tick, 30, "p1")
	t.check(not enemy.alive and not enemy.visible, "de vijand is niet weg")
	var dood: Sprite2D = null
	for child in sim.get_children():
		if child.get_script() == Beeld.Dood:
			dood = child
	t.check(dood != null and dood.anim == "dood" and dood.frame_nr == 0
		and dood.position == at + _v(_blad("kadeloper", "kadeloper")["offset_links" if links else "offset"]) and dood.flip_h == links,
		"geen dood-effect op de plek: %s" % [dood.position if dood != null else null])
	# Eén frame per physics-tick (± 1 tick tegen de Sim, alleen beeld): 8 frames van 6, op volgorde.
	var frames := []
	for i in 50:
		await t.tree.physics_frame
		if is_instance_valid(dood) and not dood.is_queued_for_deletion():
			frames.append(dood.frame_nr)
	var midden_ok := true
	for f in range(1, 7):
		midden_ok = midden_ok and frames.count(f) == 6
	var sorted := frames.duplicate()
	sorted.sort()
	t.check(frames == sorted and frames.size() >= 46 and frames.size() <= 48 and midden_ok and frames.has(0) and frames.has(7),
		"frames %s" % [frames])
	t.check(not is_instance_valid(dood), "het dood-effect blijft na 48 ticks")
	await t.cleanup()


## Een add uit een spuigat (`hold_until`, add_inactief 30): uit_stoom 6 × 5, dan lopen.
func test_uit_stoom(t) -> void:
	var w := _world(t, 100.0)
	var sim = w["sim"]
	var enemy := SliceEnemy.new()
	enemy.setup_enemy(KADELOPER, 200.0, Fx.FLOOR_TOP)
	var held := EnemyData.ticks("gemaalmeester", "add_inactief")
	# Zoals `_spawn_adds`: zijn eerste tick is de volgende, en tot dan + add_inactief doet hij niets.
	enemy.hold_until(sim.tick + held)
	sim.add_object(enemy)
	var from: int = sim.tick
	var rows := _trace(sim, enemy)
	await t.run_ticks(sim, held + 10)
	t.check(_runs(rows, from, "uit_stoom") == [6, 6, 6, 6, 6] and String(rows[from + held]["lijf"]).begins_with("lopen/"),
		"uit de stoom: %s, daarna %s" % [_runs(rows, from, "uit_stoom"), rows[from + held]["lijf"]])
	await t.cleanup()


## Dwaallicht: zweven, aanloop met tell en duiklijn op de landingsplek, duik 4 4, terug 10 × 4.
func test_dwaallicht_duik(t) -> void:
	var w := _world(t, 600.0)
	var sim = w["sim"]
	var enemy := SliceEnemy.new()
	enemy.setup_enemy(DWAALLICHT, 200.0, Fx.FLOOR_TOP, 200.0, 232.0)
	sim.add_object(enemy)
	var rows := _trace(sim, enemy)
	var started := []
	enemy.attack_started.connect(func(tick: int) -> void: started.append(tick))
	await t.run_ticks(sim, 20)
	t.check(String(rows[sim.tick - 1]["lijf"]).begins_with("zweven/") and not rows[sim.tick - 1]["flip"],
		"op de baan: %s" % rows[sim.tick - 1]["lijf"])
	w["p1"].position = Vector2(enemy.position.x + 10.0, Fx.STAND_Y)
	await t.run_ticks(sim, 100)
	t.check(not started.is_empty(), "geen duik")
	if started.is_empty():
		await t.cleanup()
		return
	var t0: int = started[0]
	t.check(_runs(rows, t0, "aanloop") == [7, 7, 7, 6, 3], "aanloop %s" % [_runs(rows, t0, "aanloop")])
	t.check(_runs(rows, t0 + 30, "duik") == [4, 4], "duik %s" % [_runs(rows, t0 + 30, "duik")])
	t.check(_runs(rows, t0 + 38, "terug") == [10, 10, 10, 10], "terug %s" % [_runs(rows, t0 + 38, "terug")])
	var size := enemy.body_size()
	var gap := EnemyData.value("dwaallicht", "baan_hoogte") - EnemyData.value("dwaallicht", "duik_hoogte") - size.y
	var tells := []
	var ok := true
	for tick in range(t0, t0 + 30):
		tells.append(rows[tick]["tell"])
		var landing := Vector2(rows[tick]["x"] - size.x * 0.5,
			Fx.FLOOR_TOP - EnemyData.value("dwaallicht", "duik_hoogte") - size.y)
		ok = ok and rows[tick]["tell_pos"] - _v(_blad("dwaallicht", "tell_duik")["offset"]) == landing \
			and is_equal_approx(rows[tick]["lijn"], gap) \
			and rows[tick]["lijn_pos"] - _v(_blad("dwaallicht", "duiklijn")["offset"]) == Vector2(rows[tick]["x"], landing.y - gap)
	t.check(tells.count("vroeg") == 15 and tells.count("laat") == 15 and ok, "tell %s, op de landingsplek %s" % [tells, ok])
	# In de duik is zijn lichaam het vlak: geen tell, geen lijn.
	t.check(rows[t0 + 30]["tell"] == "" and rows[t0 + 30]["lijn"] < 0.0, "tell in de duik: %s" % rows[t0 + 30]["tell"])
	await t.cleanup()
