extends RefCounted
## Tests voor het beeld van de Gemaalmeester (Technical Artist, #265; overdracht
## `docs/art/animatie-timing.md` §1.6, manifest `gemaalmeester.json`).
##
## De sprite-frames volgen de toestand van de boss, tick voor tick:
## - de lagen staan op de offset en z-index uit het manifest, in grijs (s = 1);
## - de eerste aanloop (60): aarzeling (7 7 6), dan de pomp-aanloop met frame
##   0–3 op kwarten en frame 4 (de uithaal) precies op de laatste 3 ticks; het
##   actieve vlak = `pomp_slag`, herstel `pomp_ligt`, daarna `pomp_terug`, idle;
## - tell vroeg / laat / actief op `windup_progress` en `is_attack_active()`, op
##   `attack_box`; het effect pompslag ook;
## - ketel: schot, breuk → kern; fase 2 schot_dicht;
## - rad: fase 1 op de rug, fasewissel en draaien op `ticks_draaien` (3), hangen
##   op 8, trillen zonder placeholder-jitter;
## - oplossen op `boss_defeated`, daarna niets.

const Fx = preload("res://tests/echo_fixture.gd")
const Gemaalmeester = preload("res://scripts/combat/gemaalmeester.gd")
const Beeld = preload("res://art/animatie/gemaalmeester/gemaalmeester_beeld.gd")
const EnemyData = preload("res://scripts/combat/enemy_data.gd")

const ORIGIN := Vector2(0, Fx.FLOOR_TOP)


func _arena(t, x := 200.0) -> Dictionary:
	var sim = Fx.world(t)
	var p1 := Fx.manual_player(sim, 1, Vector2(x, Fx.STAND_Y))
	p1.health = 100000
	sim.set_tail_ticks(60)
	var boss := Gemaalmeester.new()
	boss.setup_gemaalmeester(ORIGIN)
	boss.attach(sim)
	return {"sim": sim, "boss": boss}


func _offset(blad: String) -> Vector2:
	var b: Dictionary = Beeld.lees_manifest()["bladen"][blad]
	return Vector2(b["offset"][0], b["offset"][1])


func _frame(blad: String, anim: String, n: int) -> Rect2:
	var f: Array = Beeld.lees_manifest()["bladen"][blad]["animaties"][anim]["frames"][n]
	return Rect2(f[0], f[1], f[2], f[3])


## Per tick (na stap 5) de stand van de lagen en de vlaggen.
func _volg(sim, boss) -> Array:
	var log: Array = []
	sim.tick_finished.connect(func(tick: int) -> void:
		var rij := {"tick": tick, "telling": boss.is_telling(), "actief": boss.is_attack_active(),
			"fase": boss.attack_phase, "p": boss.windup_progress(tick), "eind": boss.windup_end_tick()}
		for naam: String in ["LichaamBeeld", "KetelBeeld", "RadBeeld", "Tell", "Effect"]:
			var s = boss.get_node(naam)
			rij[naam] = [s.anim if s.visible else "", s.frame_nr if s.visible else -1]
		log.append(rij))
	return log


func test_lagen_op_manifest_in_grijs(t) -> void:
	var a := await _arena(t)
	var boss = a["boss"]
	await t.run_ticks(a["sim"], 2)
	var m := Beeld.lees_manifest()
	for paar: Array in [["LichaamBeeld", "lichaam"], ["KetelBeeld", "ketel"], ["RadBeeld", "rad"]]:
		var s: Sprite2D = boss.get_node(paar[0])
		var b: Dictionary = m["bladen"][paar[1]]
		t.check(s.visible and not s.centered and s.region_enabled and s.z_index == int(b["z_index"])
			and s.texture != null and s.texture.resource_path == Beeld.DIR + String(b["bestanden"]["grijs"])
			and s.texture_filter == CanvasItem.TEXTURE_FILTER_NEAREST,
			"%s: zichtbaar, z %d, texture %s" % [paar[0], s.z_index, s.texture.resource_path if s.texture else null])
		t.check(s.region_rect == _frame(paar[1], s.anim, s.frame_nr), "%s: region %s niet van %s/%d" % [paar[0], s.region_rect, s.anim, s.frame_nr])
	t.check(boss.get_node("LichaamBeeld").position == _offset("lichaam") and boss.get_node("KetelBeeld").position == _offset("ketel"),
		"lichaam of ketel niet op de offset")
	var rad = boss.get_node("RadBeeld")
	t.check(rad.anim == "draai_s0" and rad.frame_nr == 0 and rad.position == Vector2(boss.middle(), -120.0) + _offset("rad"),
		"rad in fase 1 niet op de rug: %s %d op %s" % [rad.anim, rad.frame_nr, rad.position])
	for naam: String in ["Lichaam", "Kern", "Schot", "Merkplek", "Tell"]:
		var n = boss.get_node_or_null(naam)
		t.check(n == null or not (n is Polygon2D), "placeholder %s staat er nog" % naam)
	await t.cleanup()


## De eerste aanloop (60) en de pompslag van fase 1: de frames volgen de vlaggen.
func test_pompslag_fase1_frames(t) -> void:
	var a := await _arena(t)
	var sim = a["sim"]
	var boss = a["boss"]
	var log := _volg(sim, boss)
	var aanvallen: Array = []
	boss.attack_started.connect(func(tick: int, kind: String, side: int) -> void: aanvallen.append([tick, kind, side]))
	await t.run_ticks(sim, 130)
	t.check(aanvallen.size() >= 1 and aanvallen[0][1] == "pomp" and aanvallen[0][2] == -1, "geen pompslag links: %s" % [aanvallen])
	if aanvallen.is_empty():
		await t.cleanup()
		return
	var a0: int = aanvallen[0][0]
	var eind := a0 + EnemyData.ticks("gemaalmeester", "eerste_aanloop")
	var aarzel: Array = []
	var aanloop: Array = []
	var fout: Array = []
	var gezien_slag := false
	var gezien_ligt := false
	var gezien_terug := false
	for rij: Dictionary in log:
		var tk: int = rij["tick"]
		var lb: Array = rij["LichaamBeeld"]
		if tk >= a0 + EnemyData.ticks("gemaalmeester", "maat_fase1"):
			break
		if tk < a0:
			if lb[0] != "idle":
				fout.append([tk, lb])
			continue
		if rij["telling"]:
			if tk < a0 + 20:
				aarzel.append(lb[1])
				if lb[0] != "aarzeling_links":
					fout.append([tk, lb])
			else:
				aanloop.append(lb[1])
				var uithaal: bool = eind - tk <= 3
				if lb[0] != "pomp_aanloop_links" or (lb[1] == 4) != uithaal:
					fout.append([tk, lb, "uithaal" if uithaal else ""])
			var tell: Array = rij["Tell"]
			if tell[0] != ("laat" if rij["p"] >= 0.5 else "vroeg") or rij["Effect"][0] != "aanloop" or rij["Effect"][1] != clampi(int(floor(rij["p"] * 4.0)), 0, 3):
				fout.append([tk, "tell/effect", tell, rij["Effect"]])
		elif rij["actief"]:
			gezien_slag = true
			if lb[0] != "pomp_slag_links" or rij["Tell"][0] != "actief" or rij["Effect"][0] != "actief":
				fout.append([tk, lb, rij["Tell"], rij["Effect"]])
		elif rij["fase"] == boss.AttackPhase.RECOVER:
			gezien_ligt = true
			if lb[0] != "pomp_ligt_links" or rij["Tell"][0] != "" or rij["Effect"][0] != "herstel":
				fout.append([tk, lb, rij["Effect"]])
		elif tk < a0 + 120:
			if lb[0] == "pomp_terug_links":
				gezien_terug = true
			elif lb[0] != "idle" or not gezien_ligt:
				fout.append([tk, lb])
	t.check(fout.is_empty(), "frames volgen de vlaggen niet: %s" % [fout.slice(0, 6)])
	t.check(aarzel == [0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 2, 2, 2, 2, 2, 2], "aarzeling %s, verwacht 7 7 6" % [aarzel])
	t.check(aanloop.size() == 40 and aanloop.slice(-3) == [4, 4, 4] and aanloop.slice(0, 37).max() == 3 and aanloop[0] == 0
		and _stijgend(aanloop), "pomp-aanloop %s" % [aanloop])
	t.check(gezien_slag and gezien_ligt and gezien_terug, "slag %s, ligt %s, terug %s" % [gezien_slag, gezien_ligt, gezien_terug])
	await t.cleanup()


func _stijgend(a: Array) -> bool:
	for i in range(1, a.size()):
		if a[i] < a[i - 1]:
			return false
	return true


## Ketel: schot, breuk (3 frames van 4) en dan de kern.
func test_ketel_breuk_en_kern(t) -> void:
	var a := await _arena(t)
	var sim = a["sim"]
	var boss = a["boss"]
	await t.run_ticks(sim, 5)
	var ketel = boss.get_node("KetelBeeld")
	t.check(ketel.anim == "schot", "ketel %s, verwacht schot" % ketel.anim)
	var log := _volg(sim, boss)
	boss.ketel.break_armor(sim.tick)
	await t.run_ticks(sim, 20)
	var anims: Array = log.map(func(r: Dictionary) -> String: return "%s%d" % r["KetelBeeld"])
	t.check(boss.core_open and anims.slice(0, 12) == ["breuk0", "breuk0", "breuk0", "breuk0", "breuk1", "breuk1", "breuk1", "breuk1", "breuk2", "breuk2", "breuk2", "breuk2"]
		and anims[12].begins_with("kern"), "ketel na de breuk %s" % [anims])
	await t.cleanup()


## Fase 2: fasewissel, schot dicht, het rad draait op `ticks_draaien`, hangt op 8 en trilt zonder jitter.
func test_fase2_rad(t) -> void:
	var a := await _arena(t)
	var sim = a["sim"]
	var boss = a["boss"]
	await t.run_ticks(sim, 2)
	var log := _volg(sim, boss)
	var g := "gemaalmeester"
	boss.set_health(sim.tick, EnemyData.ticks(g, "drempel_%d" % EnemyData.ticks(g, "openingen")))
	await t.run_ticks(sim, 30)
	var wissel: Array = log.filter(func(r: Dictionary) -> bool: return r["LichaamBeeld"][0] == "fasewissel")
	t.check(wissel.size() >= 29 and boss.get_node("KetelBeeld").anim == "schot_dicht", "fasewissel %d ticks, ketel %s" % [wissel.size(), boss.get_node("KetelBeeld").anim])
	var rad_frames: Array = log.map(func(r: Dictionary) -> int: return r["RadBeeld"][1])
	var wissels := 0
	for i in range(1, rad_frames.size()):
		if rad_frames[i] != rad_frames[i - 1]:
			wissels += 1
	t.check(wissels >= 9 and wissels <= 10, "rad draait %d frames in 30 ticks, verwacht ± 10 (3 ticks per frame)" % wissels)
	await t.run_ticks(sim, 40)
	var rad = boss.get_node("RadBeeld")
	t.check(boss.rad_state == Gemaalmeester.RadState.HANGING and rad.anim == "draai_s0", "rad hangt niet: %s" % rad.anim)
	log.clear()
	await t.run_ticks(sim, 32)
	rad_frames = log.map(func(r: Dictionary) -> int: return r["RadBeeld"][1])
	wissels = 0
	for i in range(1, rad_frames.size()):
		if rad_frames[i] != rad_frames[i - 1]:
			wissels += 1
	t.check(wissels >= 3 and wissels <= 4, "hangend rad %d frames in 32 ticks, verwacht 4 (8 ticks per frame)" % wissels)
	# Trillen: de frames schuiven zelf, de positie blijft (geen placeholder-jitter).
	boss.rad_side_hits = EnemyData.ticks(g, "kant_treffers")
	var posities := {}
	var trilt := 0
	for i in 12:
		await t.run_ticks(sim, 1)
		if boss.rad_state == Gemaalmeester.RadState.SHAKING:
			trilt += 1
			t.check(rad.anim == "trilt_s0", "rad trilt, beeld %s" % rad.anim)
			posities[rad.position] = true
	t.check(trilt >= 10 and posities.size() == 1 and posities.has(boss.rad.position + _offset("rad")), "trillen: %d ticks, posities %s" % [trilt, posities.keys()])
	await t.cleanup()


## GM-10: oplossen (10 frames van 6 ticks) en daarna niets.
func test_oplossen(t) -> void:
	var a := await _arena(t)
	var sim = a["sim"]
	var boss = a["boss"]
	await t.run_ticks(sim, 3)
	var log := _volg(sim, boss)
	boss._defeat(sim.tick)
	await t.run_ticks(sim, 70)
	var lijf: Array = log.map(func(r: Dictionary) -> int: return r["LichaamBeeld"][1])
	t.check(lijf.slice(0, 60) == range(60).map(func(i: int) -> int: return i / 6) and lijf.slice(60).all(func(v: int) -> bool: return v == -1),
		"lichaam oplossen %s" % [lijf])
	var nog: Array = []
	for naam: String in ["LichaamBeeld", "KetelBeeld", "RadBeeld", "Tell", "Effect", "Spuigat_links", "Spuigat_rechts"]:
		if boss.get_node(naam).visible:
			nog.append(naam)
	t.check(nog.is_empty(), "na het oplossen nog beeld: %s" % [nog])
	await t.cleanup()
