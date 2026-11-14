extends RefCounted
## Scripted boss-runs tegen de Gemaalmeester (T8b-bouw deel 2b, #190; B-9b, #218): B-9 (`boss_bot.gd`,
## solo en co-op per D, de C-16-runs, drop-out van P2) en B-10 (meetlog-events). Bron:
## `docs/design/combat/slice-vijanden-en-boss.md` v0.1.3 §3.5, §3.9, §6, §7; gdd v0.8.1 §4.5, §4.6 (C-16).
##
## B-9b: de bot ontwijkt in fase 2 (keren op de maat, sprong over de pompslag) en P1 speelt met
## `p1_health` = 5 LP, zonder genezing van buiten het spel. Elke run: verslagen zonder dood (geen
## RESPAWN, ≤ 4 treffers op P1 in de hele run; doel 0 in fase 2), MP-1 ≤ 300. Solo en co-op bij D = 60
## 95–150 s (v0.1.5, #247, LGD: doel ± 100 s), fase 1 ≥ 24 s en fase 2 ≤ 65 s, ook de realistische speler
## (duur); co-op bij D = 60 75–150 s (LGD, PR #253); MP-7 (co-op ÷ solo) 0,5 … 1,0 bij 60 / 90 / 120 (180 als note);
## `RAD_DRAAI` reden `tijd` hooguit 1 per solo-run bij D ≤ 120. Rapport: lopend wachten per keer-run en
## de beginner-run met 1 slag per bounce.
## Werkaanname (DoD #190): D = 60 (besluit CEO 2026-11-12, echo-staart 1 s) en Godot 4.6.3-stable
## (`.github/workflows/tests.yml`); de checks van B-14 (b) en (e) gelden bij D = 60.
##
## Elke run: arena van 600 px met twee muren, de Gemaalmeester op de linkermuur, P1 (en P2) met de
## bot als inputbron, meetlog met `watch_boss`. De run duurt van BOSS_START tot BOSS_VERSLAGEN; de
## duur per deel komt in de note (tabel voor de Combat Designer, §3.9). Een run duurt langer dan de
## standaardgrens van de runner (7200 frames): `MAX_FRAMES` zet per test een eigen grens.
##
## B-14 (G-2, v0.1.6.1 §3.10, §6; #190): in co-op heeft P2 in elke fase een taak (de wissel in fase 1,
## de rolwissel in fase 2, `boss_bot.gd`). (c) Solo geeft dezelfde ticks als v0.1.5 (D = 60: 5875);
## (e) `mp1_p2` ≤ 300 bij 60 / 90 / 120 (180 als note), met in de note de langste stilstand en het
## wachten (MP-7 (e)) van P1 en P2 per deel; (f) bij D = 60 zet P2 in fase 1 merken vanaf beide
## helften en springt hij er niet; (b) de note-run "P2 blijft als ontsteker op één plek"; (h) de
## C-16-run zonder schotbreuk; (i) MP-7 (a) en de co-op-duur blijven checks.

const Fx = preload("res://tests/echo_fixture.gd")
const BossBot = preload("res://tests/boss_bot.gd")
const PlayerActor = preload("res://scripts/echo/player_actor.gd")
const TailEcho = preload("res://scripts/echo/tail_echo.gd")
const Gemaalmeester = preload("res://scripts/combat/gemaalmeester.gd")
const EnemyData = preload("res://scripts/combat/enemy_data.gd")
const Meetlog = preload("res://scripts/events/meetlog.gd")
const FlowReport = preload("res://levels/flowkamer/flow_report.gd")
const LightMeter = preload("res://scripts/light/light_meter.gd")
const Layers = preload("res://scripts/world/layers.gd")
const Tuning = preload("res://scripts/echo/tuning.gd")
const InputBits = preload("res://scripts/input/input_bits.gd")

## Een run duurt bij D = 180 langer dan 2 minuten speltijd; de grens is ruim, de run zelf stopt bij
## BOSS_VERSLAGEN of op `RUN_LIMIT`.
const RUN_LIMIT := 20000
const MAX_FRAMES := {
	"test_b9_solo_d60": 22000, "test_b9_solo_d90": 22000, "test_b9_solo_d120": 22000,
	"test_b9_solo_d180": 22000, "test_b9_coop_d60": 22000, "test_b9_coop_d90": 22000,
	"test_b9_coop_d120": 22000, "test_b9_coop_d180": 22000, "test_b9_drop_out_phase1": 22000,
	"test_b9_drop_out_wankel": 22000, "test_b9_c16_solo_echo_off": 13000,
	"test_b9_c16_coop_p2_never_hits": 13000, "test_b9_one_strike_per_bounce": 22000,
	"test_b10_meetlog_events": 22000, "test_b9b_realistic_solo_d60": 22000,
	"test_b14_note_p2_one_place": 22000,
}
## B-14 (c): de solo-run bij D = 60 in ticks van v0.1.5 (de wissel geldt solo niet).
const SOLO_D60_TICKS := 5875
## B-14 (e): de verwachting van §3.10 voor de langste stilstand van P2 per deel (ticks).
## v0.1.7 (#302): fase 2 ± 150, bovengrens 180 (was ± 90).
const EXPECTED_P2 := {"fase 1": "± 90", "fasewissel": "≤ 60", "fase 2": "± 150, bovengrens 180", "wankel+finisher": "± 100"}
## B-14 (b): schotbreuken per maat van fase 1 in de gewone co-op-run bij D = 60 (note).
static var _coop_breaks_per_beat := -1.0
## B-14 (b2): de duur van fase 1 (ticks, BOSS_START tot de fasewissel) in de gewone co-op-run bij D = 60.
static var _coop_phase1_ticks := -1
## B-14 (b2, v0.1.7): fase 1 met P2 op één plek duurt ≥ 1,25 × zo lang als in de gewone co-op-run.
const P2_FIXED_PHASE1_MIN := 1.25
## B-14 (b): de run "P2 op één plek" duurt hooguit zoveel ticks vanaf BOSS_START.
const P2_FIXED_LIMIT := 6000
## B-9b: totale duur (ticks) van de solo-run per D, voor MP-7 in de co-op-run.
static var _solo_ticks := {}
## v0.1.5 (#247, LGD-besluit in #247): de normen van de solo-run bij D = 60, in seconden.
const TOTAL_MIN_S := 95.0
const TOTAL_MAX_S := 150.0
const PHASE1_MIN_S := 24.0
const PHASE2_MAX_S := 65.0
## Co-op bij D = 60 (besluit LGD in PR #253).
const COOP_MIN_S := 75.0


# --- arena en run -------------------------------------------------------------

## Arena (vloer, muren op x = 0 en 600), de Gemaalmeester, de bot, P1 (en P2), echo, meetlog.
func _arena(t, d: int, coop: bool, echo_on := true) -> Dictionary:
	var sim = Fx.world(t)
	Fx.block(t, "MuurLinks", Rect2(-40, Fx.FLOOR_TOP - 400, 40, 400), Layers.WORLD)
	Fx.block(t, "MuurRechts", Rect2(600, Fx.FLOOR_TOP - 400, 40, 400), Layers.WORLD)
	var boss := Gemaalmeester.new()
	boss.setup_gemaalmeester(Vector2(0, Fx.FLOOR_TOP))
	var bot := BossBot.new(sim, boss)
	var p1 := PlayerActor.new()
	p1.setup(1, bot.p1_source, Color.WHITE)
	p1.position = Vector2(200, Fx.STAND_Y)
	sim.add_player(p1)
	# B-9b: P1 speelt met zijn echte levenspunten (5), zonder genezing van buiten het spel.
	p1.health = int(Tuning.combat()["p1_health"])
	var p2: PlayerActor = null
	var echo: TailEcho = null
	if coop:
		p2 = PlayerActor.new()
		p2.setup(2, bot.p2_source, Color.GRAY)
		p2.position = Vector2(336, Fx.STAND_Y)
		sim.add_player(p2)
		sim.set_tail_ticks(d)
	elif echo_on:
		echo = Fx.tail_echo(sim, p1, d)
	else:
		sim.set_tail_ticks(d)
	boss.attach(sim)
	var log := Meetlog.new(sim, p1, echo)
	log.watch_boss(boss)
	var run := {"sim": sim, "boss": boss, "bot": bot, "p1": p1, "p2": p2, "echo": echo, "log": log,
		"hits": [], "breaks": 0, "d": d, "coop": coop}
	boss.hit_player.connect(func(tick: int, _who: Node2D) -> void: run["hits"].append(tick))
	# B-14 (f): merken van P2 in fase 1 per helft, en de JUMP-flanken van P2 in fase 1.
	run["p2_marks"] = {-1: 0, 1: 0}
	run["p2_jumps"] = 0
	run["beats1"] = 0
	sim.combat.mark_set.connect(func(_tick: int, mark) -> void:
		if mark.setter == "p2" and mark.target == boss.ketel and boss.phase == Gemaalmeester.Phase.ONE:
			run["p2_marks"][boss.half_of(mark.set_at)] += 1)
	boss.beat.connect(func(_tick: int, _n: int) -> void:
		if boss.phase == Gemaalmeester.Phase.ONE:
			run["beats1"] += 1)
	if p2 != null:
		var prev := {"j": false}
		sim.tick_finished.connect(func(_tick: int) -> void:
			var partner: PlayerActor = sim.get_player(2)
			var down := partner != null and partner.last_input & InputBits.JUMP != 0
			if down and not prev["j"] and boss.phase == Gemaalmeester.Phase.ONE and boss.state == boss.State.FIGHT:
				run["p2_jumps"] += 1
			prev["j"] = down)
	if echo != null:
		echo.broke.connect(func(_tick: int, _at: Vector2) -> void: run["breaks"] += 1)
	return run


## Draait tot `done` waar is, hooguit `limit` ticks.
func _run_until(t, sim: Node, done: Callable, limit: int, step := 30) -> void:
	var until: int = sim.tick + limit
	while sim.tick < until and not done.call():
		await t.run_ticks(sim, mini(step, until - sim.tick))


## De run tot BOSS_VERSLAGEN (of `RUN_LIMIT`); geeft de delen en de maten terug.
func _play_run(t, run: Dictionary) -> Dictionary:
	var sim = run["sim"]
	var boss: Gemaalmeester = run["boss"]
	await _run_until(t, sim, func() -> bool: return boss.is_defeated(), RUN_LIMIT)
	await t.run_ticks(sim, 2)
	run["log"].finish()
	return _measure(run)


## Duur per deel uit het meetlog (BOSS_START, BOSS_FASE, BOSS_VERSLAGEN), MP-1, treffers.
func _measure(run: Dictionary) -> Dictionary:
	var rows: Array = run["log"].rows
	var at := {}
	var rad := {}
	var turns := {"treffers": 0, "tijd": 0}
	var first_break := -1
	for row in rows:
		match row[2]:
			"BOSS_START":
				at["start"] = int(row[0])
			"BOSS_FASE":
				at[row[3]] = int(row[0])
			"BOSS_VERSLAGEN":
				at["verslagen"] = int(row[0])
			"SCHOT_BREUK":
				if first_break < 0:
					first_break = int(row[0])
			"RAD_TREFFER":
				var key := "%s/%s" % [row[4], row[3]]
				rad[key] = int(rad.get(key, 0)) + 1
			"RAD_DRAAI":
				turns[row[3]] = int(turns.get(row[3], 0)) + 1
	var rep = FlowReport.from_rows(rows, run["echo"] != null)
	var m := {"at": at, "rad": rad, "turns": turns, "first_break": first_break, "mp1": rep.longest_still,
		"mp1_p2": rep.longest_still_p2, "hits": run["hits"].size(), "breaks": run["breaks"],
		"defeated": run["boss"].is_defeated(), "health": run["p1"].health,
		"respawns": run["log"].count("RESPAWN"), "waits": run["bot"].waits, "jl": run["bot"].jl,
		"closed": run["bot"].closed, "rows": rows, "swaps": run["bot"].swaps.size(),
		"breaks_total": run["log"].count("SCHOT_BREUK")}
	if at.has("start") and at.has("verslagen"):
		m["total"] = int(at["verslagen"]) - int(at["start"])
	# Treffers op P1 per deel (de bot ontwijkt alleen de pompslag van fase 1).
	var per_part := {"fase 1": 0, "fase 2": 0, "anders": 0}
	for tick: int in run["hits"]:
		if tick < int(at.get("wissel", 1 << 40)):
			per_part["fase 1"] += 1
		elif tick >= int(at.get("2", 1 << 40)) and tick < int(at.get("wankel", 1 << 40)):
			per_part["fase 2"] += 1
		else:
			per_part["anders"] += 1
	m["hits_per_part"] = per_part
	return m


## Eén regel voor de tabel (§3.9): duur per deel in ticks en s.
func _table_row(name: String, m: Dictionary) -> String:
	var at: Dictionary = m["at"]
	var part := func(a: String, b: String) -> String:
		if not at.has(a) or not at.has(b):
			return "?"
		return "%d" % (int(at[b]) - int(at[a]))
	return ("%s: fase 1 %s · wissel %s · fase 2 %s · wankel+finisher %s · totaal %s ticks (%.1f s) · " +
		"MP-1 P1 %d (P2 %d) · treffers op P1 %s · LP over %d · rad %s · kanten %s · eerste SCHOT_BREUK na %d" +
		" · %s") % [name,
		part.call("start", "wissel"), part.call("wissel", "2"), part.call("2", "wankel"),
		part.call("wankel", "verslagen"), str(m.get("total", "?")), float(m.get("total", 0)) / 60.0,
		m["mp1"], m["mp1_p2"], "%d %s" % [m["hits"], m["hits_per_part"]], m["health"], m["rad"], m["turns"],
		int(m["first_break"]) - int(at.get("start", 0)), _waits_text(m)]


## B-9b, rapport: lopend wachten vóór het keervenster per keer-run (max en gemiddelde), en J en L na het
## keren (min–max).
func _waits_text(m: Dictionary) -> String:
	var waits: Array = m["waits"]
	if waits.is_empty():
		return "lopend wachten: geen keer-runs"
	var total := 0
	var most := 0
	for w: int in waits:
		total += w
		most = maxi(most, w)
	var text := "lopend wachten per keer-run: max %d, gem. %.0f ticks (%d keer-runs)" % [most, float(total) / waits.size(),
		waits.size()]
	var jl: Array = m["jl"]
	if not jl.is_empty():
		var j := jl.map(func(r: Array) -> int: return r[0])
		var l := jl.map(func(r: Array) -> int: return r[1])
		text += " · J − T %d–%d, L − T %d–%d" % [j.min(), j.max(), l.min(), l.max()]
	text += " · eerdere keertick gesloten door %s" % str(m["closed"])
	return text


# --- B-9: scripted runs per D ---------------------------------------------------

## B-9, B-9b en C-16 (3) op de Gemaalmeester, 2 slagen per bounce, met ontwijken, 5 LP: de run wint
## (BOSS_VERSLAGEN) zonder dood, MP-1 ≤ 300, de echo breekt nooit; bij D = 60 duurt de solo-run
## 90–150 s (§3.9); `RAD_DRAAI` reden `tijd` hooguit 1 bij D ≤ 120.
func _solo(t, d: int) -> void:
	var name := "solo D = %d (2 slagen per bounce, met ontwijken, 5 LP)" % d
	var run := _arena(t, d, false)
	var m := await _play_run(t, run)
	t.note(_table_row(name, m))
	_check_run(t, name, m)
	_solo_ticks[d] = int(m.get("total", 0))
	if d <= 120:
		t.check(int(m["turns"].get("tijd", 0)) <= 1, "%s: %d keer RAD_DRAAI reden tijd (≤ 1)" % [name, m["turns"].get("tijd", 0)])
	if d == 60:
		_check_duration(t, name, m)
		# B-14 (c): de wissel geldt solo niet, dus dezelfde ticks als v0.1.5.
		t.check(int(m.get("total", 0)) == SOLO_D60_TICKS, "%s: %s ticks (v0.1.5: %d; B-14 (c))" % [name,
			m.get("total", "?"), SOLO_D60_TICKS])
	await t.cleanup()


## v0.1.5 (#247, LGD): totaal 95–150 s, fase 1 ≥ 24 s, fase 2 ≤ 65 s (de solo-run bij D = 60).
func _check_duration(t, name: String, m: Dictionary) -> void:
	var s := float(m.get("total", 0)) / 60.0
	t.check(s >= TOTAL_MIN_S and s <= TOTAL_MAX_S, "%s: %.1f s (%.0f–%.0f, §3.9 v0.1.5)" % [name, s, TOTAL_MIN_S, TOTAL_MAX_S])
	var at: Dictionary = m["at"]
	var p1 := float(int(at.get("wissel", 0)) - int(at.get("start", 0))) / 60.0 if at.has("wissel") and at.has("start") else -1.0
	var p2 := float(int(at.get("wankel", 0)) - int(at.get("2", 0))) / 60.0 if at.has("wankel") and at.has("2") else INF
	t.check(p1 >= PHASE1_MIN_S, "%s: fase 1 %.1f s (≥ %.0f)" % [name, p1, PHASE1_MIN_S])
	t.check(p2 <= PHASE2_MAX_S, "%s: fase 2 %.1f s (≤ %.0f)" % [name, p2, PHASE2_MAX_S])


## B-9b: verslagen zonder dood (geen RESPAWN, P1 leeft, ≤ 4 treffers in de hele run); de treffers in
## fase 2 (doel 0) staan in de note.
func _check_run(t, name: String, m: Dictionary) -> void:
	t.check(m["defeated"], "%s: niet verslagen in %d ticks (%s)" % [name, RUN_LIMIT, m["at"]])
	t.check(m["respawns"] == 0 and m["health"] > 0 and m["hits"] <= 4,
		"%s: %d treffers op P1 %s (≤ 4), %d LP over, %d respawns (verslagen zonder dood)" % [name, m["hits"],
			m["hits_per_part"], m["health"], m["respawns"]])
	t.check(m["mp1"] <= 300, "%s: MP-1 %d > 300" % [name, m["mp1"]])
	t.check(m["breaks"] == 0, "%s: de echo brak %d keer" % [name, m["breaks"]])
	t.check(int(m["first_break"]) >= 0, "%s: geen SCHOT_BREUK" % name)


## B-9b: co-op met 5 LP; bij D = 60 75–150 s; MP-7 (co-op ÷ solo bij dezelfde D) ≥ 0,5 bij 60 / 90 / 120,
## bij 180 een note als het niet haalt. Co-op duurt niet langer dan solo (MP-7 ≤ 1,0; v0.1.3 §3.9
## besluit 1, na PR #219), ook bij 60 / 90 / 120; bij 180 een note.
func _coop(t, d: int) -> void:
	var name := "co-op D = %d (2 slagen per bounce, met ontwijken, 5 LP)" % d
	var run := _arena(t, d, true)
	var m := await _play_run(t, run)
	var solo: int = _solo_ticks.get(d, 0)
	var mp7 := float(m.get("total", 0)) / float(solo) if solo > 0 else -1.0
	t.note(_table_row(name, m) + " · MP-7 %.2f (solo %d ticks)" % [mp7, solo])
	_check_run(t, name, m)
	if d == 60:
		# v0.1.5 (besluit LGD in PR #253): co-op bij D = 60 duurt 75–150 s; de oude ondergrens van 90 s
		# vervalt (die paste niet met co-op ≤ solo bij D = 90 en fase 2 ≤ 65 s solo).
		var s := float(m.get("total", 0)) / 60.0
		t.check(s >= COOP_MIN_S and s <= TOTAL_MAX_S, "%s: %.1f s (%.0f–%.0f)" % [name, s, COOP_MIN_S, TOTAL_MAX_S])
	if d <= 120:
		t.check(mp7 >= 0.5 and mp7 <= 1.0, "%s: MP-7 %.2f (0,5 … 1,0; solo %d ticks)" % [name, mp7, solo])
	elif mp7 < 0.5 or mp7 > 1.0:
		t.note("%s: MP-7 %.2f buiten 0,5 … 1,0 (D = 180, regressie, geen eis)" % [name, mp7])
	# B-14 (e): MP-7 (b) voor P2 in de boss; de note per deel (stilstand en wachten, P1 en P2).
	t.note("%s: %s" % [name, _per_part_text(m)])
	if d <= 120:
		t.check(int(m["mp1_p2"]) <= 300, "%s: MP-7 (b) P2 %d > 300 (B-14 (e))" % [name, m["mp1_p2"]])
	elif int(m["mp1_p2"]) > 300:
		t.note("%s: MP-7 (b) P2 %d > 300 (D = 180, geen eis)" % [name, m["mp1_p2"]])
	if d == 60:
		# B-14 (f): P2 zet in fase 1 merken vanaf beide helften (≥ 2 per helft) en springt er niet.
		var marks: Dictionary = run["p2_marks"]
		t.check(int(marks[-1]) >= 2 and int(marks[1]) >= 2 and int(run["p2_jumps"]) == 0,
			"%s: fase 1 merken van P2 links %d / rechts %d (≥ 2), JUMP-flanken P2 %d (0)" % [name, marks[-1], marks[1],
				run["p2_jumps"]])
		_coop_breaks_per_beat = float(m["breaks_total"]) / maxf(float(run["beats1"]), 1.0)
		_coop_phase1_ticks = _phase1_ticks(m)
		t.note("%s: fase 1 %d schotbreuken in %d maten (%.2f per maat); merken van P2 links %d / rechts %d; rolwissels fase 2 %d" % [
			name, m["breaks_total"], run["beats1"], _coop_breaks_per_beat, marks[-1], marks[1], m["swaps"]])
	await t.cleanup()


## B-14 (e): de delen van de run (BOSS_FASE-ticks), als [naam, van, tot).
func _parts(m: Dictionary) -> Array:
	var at: Dictionary = m["at"]
	var end := int(at.get("verslagen", 1 << 40)) + 1
	return [["fase 1", int(at.get("start", 0)), int(at.get("wissel", end))],
		["fasewissel", int(at.get("wissel", end)), int(at.get("2", end))],
		["fase 2", int(at.get("2", end)), int(at.get("wankel", end))],
		["wankel+finisher", int(at.get("wankel", end)), end]]


## B-14 (e): per deel de langste stilstand (MP-1, `STIL_EIND` met bron p1/p2, geknipt op het deel) en
## het wachten (MP-7 (e), `WACHT_START`/`WACHT_EIND`: langste periode en aandeel van het deel; twee
## perioden die overlappen tellen als één), voor P1 en P2, naast de verwachting van §3.10 voor P2.
## Let op: deze arena heeft geen lichtmeter, dus geen `LP`-regels; slaan en ontsteken tellen hier niet
## als eigen actie (MP-7 (e)) en het wachten valt hoger uit dan in de Kadewijk-arena, waar de
## merk-combo's LP geven (`test_kadewijk_coop.gd`, S8 los: de boss).
func _per_part_text(m: Dictionary) -> String:
	var still := {"p1": [], "p2": []}
	var waits := {"p1": [], "p2": []}
	var wait_from := {}
	for row in m["rows"]:
		var tick := int(row[0])
		match row[2]:
			"STIL_EIND":
				if still.has(row[4]):
					still[row[4]].append([tick - int(row[3]), tick])
			"WACHT_START":
				wait_from[row[4]] = int(row[3])
			"WACHT_EIND":
				if wait_from.has(row[4]):
					waits[row[4]].append([int(wait_from[row[4]]), int(wait_from[row[4]]) + int(row[3])])
					wait_from.erase(row[4])
	var out := PackedStringArray()
	for part: Array in _parts(m):
		var a: int = part[1]
		var b: int = part[2]
		var cells := PackedStringArray()
		for who: String in ["p1", "p2"]:
			var longest_still := 0
			for w: Array in still[who]:
				longest_still = maxi(longest_still, mini(int(w[1]), b) - maxi(int(w[0]), a))
			var merged: Array = []
			for w: Array in waits[who]:
				if not merged.is_empty() and int(w[0]) <= int(merged[-1][1]):
					merged[-1][1] = maxi(int(merged[-1][1]), int(w[1]))
				else:
					merged.append([int(w[0]), int(w[1])])
			var longest_wait := 0
			var total := 0
			for w: Array in merged:
				var n := mini(int(w[1]), b) - maxi(int(w[0]), a)
				if n > 0:
					longest_wait = maxi(longest_wait, n)
					total += n
			cells.append("%s stil %d, wacht langste %d (%.1f %%)" % [who.to_upper(), longest_still, longest_wait,
				100.0 * total / maxf(float(b - a), 1.0)])
		out.append("%s (%d ticks): %s; verwacht P2 %s" % [part[0], b - a, " / ".join(cells), EXPECTED_P2[part[0]]])
	return "per deel (wachten zonder LP-regels, zie `_per_part_text`): " + " · ".join(out)


func test_b9_solo_d60(t) -> void:
	await _solo(t, 60)


func test_b9_solo_d90(t) -> void:
	await _solo(t, 90)


func test_b9_solo_d120(t) -> void:
	await _solo(t, 120)


func test_b9_solo_d180(t) -> void:
	await _solo(t, 180)


func test_b9_coop_d60(t) -> void:
	await _coop(t, 60)


func test_b9_coop_d90(t) -> void:
	await _coop(t, 90)


func test_b9_coop_d120(t) -> void:
	await _coop(t, 120)


func test_b9_coop_d180(t) -> void:
	await _coop(t, 180)


## B-9b, rapport: de beginner, dezelfde solo-run met 1 slag per bounce (met ontwijken, 5 LP). Hij wint
## zonder dood, MP-1 ≤ 300, de echo breekt niet; de duur en de kanten op treffers/tijd staan in de
## note (geen eis voor de duur).
func test_b9_one_strike_per_bounce(t) -> void:
	var run := _arena(t, 60, false)
	run["bot"].strikes_per_bounce = 1
	var m := await _play_run(t, run)
	t.note(_table_row("beginner: solo D = 60, 1 slag per bounce, met ontwijken, 5 LP", m))
	_check_run(t, "solo D = 60, 1 slag per bounce", m)
	await t.cleanup()


## B-9b: de realistische speler, solo D = 60 (2 slagen per bounce, geen dash in fase 2, 40 ticks
## aarzelen vóór elke oversteek, 5 LP): verslagen zonder dood, 95–150 s (v0.1.5), MP-1 ≤ 300.
func test_b9b_realistic_solo_d60(t) -> void:
	var name := "realistische speler: solo D = 60 (2 slagen per bounce, geen dash in fase 2, 40 ticks aarzelen, 5 LP)"
	var run := _arena(t, 60, false)
	run["bot"].realistic = true
	var m := await _play_run(t, run)
	t.note(_table_row(name, m))
	_check_run(t, name, m)
	var s := float(m.get("total", 0)) / 60.0
	t.check(s >= TOTAL_MIN_S and s <= TOTAL_MAX_S, "%s: %.1f s (%.0f–%.0f, §3.9 v0.1.5)" % [name, s, TOTAL_MIN_S, TOTAL_MAX_S])
	await t.cleanup()


# --- B-9: drop-out van P2 ----------------------------------------------------------

## Co-op-run waarin P2 uitvalt (C-05) op een moment (`moment`: "fase1" = de eerste schotbreuk,
## "wankel" = de tick waarop P1 de merkplek merkte, vóór P2 slaat); daarna speelt P1 solo met de
## echo die de drop-out maakt (C-12 b: merken van P2 knalt de echo). Geen moment vraagt twee
## spelers (C-16 e).
func _drop_out_run(t, moment: String) -> void:
	var name := "drop-out %s" % moment
	var run := _arena(t, 60, true)
	var sim = run["sim"]
	var boss: Gemaalmeester = run["boss"]
	var when := func() -> bool:
		if moment == "fase1":
			return boss.openings_count >= 1
		var mark = sim.combat.mark_on(boss.ketel)
		return boss.is_wankel() and mark != null and mark.setter == "p1"
	await _run_until(t, sim, when, RUN_LIMIT, 1)
	t.check(when.call(), "%s: het moment van de drop-out kwam niet" % name)
	var echo: TailEcho = sim.drop_out()
	t.check(echo != null and sim.get_player(2) == null, "%s: geen drop-out" % name)
	var at: int = sim.tick
	if echo != null:
		echo.broke.connect(func(_tick: int, _at: Vector2) -> void: run["breaks"] += 1)
	var m := await _play_run(t, run)
	t.note(_table_row("%s (op tick %d)" % [name, at - int(m["at"].get("start", 0))], m))
	_check_run(t, name, m)
	t.check(boss.finisher_count > 0, "%s: geen finisherslagen" % name)
	await t.cleanup()


## B-9: drop-out van P2 in fase 1, op de eerste schotbreuk.
func test_b9_drop_out_phase1(t) -> void:
	await _drop_out_run(t, "fase1")


## B-9: drop-out van P2 in Wankel, na het merk van P1 en vóór de slag van P2.
func test_b9_drop_out_wankel(t) -> void:
	await _drop_out_run(t, "wankel")


# --- B-9: C-16 op de Gemaalmeester -----------------------------------------------------

## C-16 (1) (gdd §4.6): solo met de echo uit haalt in 6000 ticks geen finisher (het schot breekt
## nooit, het rad is niet te raken).
func test_b9_c16_solo_echo_off(t) -> void:
	var run := _arena(t, 60, false, false)
	var sim = run["sim"]
	var boss: Gemaalmeester = run["boss"]
	await t.run_ticks(sim, 6000)
	run["log"].finish()
	t.check(run["log"].count("FINISHER_START") == 0 and not boss.is_defeated() and boss.se == EnemyData.ticks("gemaalmeester", "se"),
		"echo uit: finisher %d, %d SE" % [run["log"].count("FINISHER_START"), boss.se])
	t.check(run["log"].count("SCHOT_BREUK") == 0, "echo uit: het schot brak")
	await t.cleanup()


## C-16 (2): co-op waarin P2 nooit slaat haalt in 6000 ticks geen finisher.
func test_b9_c16_coop_p2_never_hits(t) -> void:
	var run := _arena(t, 60, true)
	run["bot"].p2_strikes = false
	var sim = run["sim"]
	var boss: Gemaalmeester = run["boss"]
	await t.run_ticks(sim, 6000)
	run["log"].finish()
	t.check(run["log"].count("FINISHER_START") == 0 and not boss.is_defeated() and boss.se == EnemyData.ticks("gemaalmeester", "se"),
		"P2 slaat nooit: finisher %d, %d SE" % [run["log"].count("FINISHER_START"), boss.se])
	# B-14 (h): ook geen schotbreuk (zonder P2 knalt niemand het merk van P1, C-16 b).
	t.check(run["log"].count("SCHOT_BREUK") == 0, "P2 slaat nooit: %d keer SCHOT_BREUK" % run["log"].count("SCHOT_BREUK"))
	await t.cleanup()


## B-14 (b), run "P2 blijft als ontsteker op één plek" (D = 60, v0.1.7, #302): de oude co-op-bot (P1
## links van de ketel, slaat om de 20 ticks; P2 rechts, zet geen merken en ontsteekt alleen van zijn
## plek). Twee checks. (b1) Elke merk-ontploffing op de ketel in fase 1 (elke `SCHOT_BREUK` en elke
## ontploffing van 20 SE op de kern) komt van een merk dat gezet werd terwijl de doelhelft op de andere
## helft stond dan P2: de doelhelft op de tick van het zetten, niet van de breuk (het merk leeft 150
## ticks, het venster is 120; Lead-review PR #303). (b2) Fase 1 duurt ≥ 1,25 × zo lang als in de
## gewone co-op-run. De schotbreuken per maat blijven een note (fase 1 heeft in beide runs 7 vaste
## openingen, dus ≤ ½ is niet te halen). Hooguit 6000 ticks vanaf BOSS_START; is fase 1 dan niet
## klaar, dan is (b2) rood. P1 heeft genoeg levens.
func test_b14_note_p2_one_place(t) -> void:
	if _coop_breaks_per_beat < 0.0 or _coop_phase1_ticks < 0:
		var normal := _arena(t, 60, true)
		var mn := await _play_run(t, normal)
		_coop_breaks_per_beat = float(mn["breaks_total"]) / maxf(float(normal["beats1"]), 1.0)
		_coop_phase1_ticks = _phase1_ticks(mn)
		await t.cleanup()
	var run := _arena(t, 60, true)
	run["bot"].p2_fixed = true
	run["p1"].health = 1000
	var sim = run["sim"]
	var boss: Gemaalmeester = run["boss"]
	var p2: PlayerActor = run["p2"]
	# Per merk: [zetter, doelhelft op de tick van het zetten, helft van P2 op die tick].
	var marks_half := {}
	sim.combat.mark_set.connect(func(tick: int, mark) -> void:
		marks_half[mark.id] = [mark.setter, boss.doelhelft(tick), boss.half_of(p2.global_position)])
	# Elke merk-ontploffing op de ketel in fase 1 (schotbreuk of 20 SE op de kern).
	var from := []
	sim.combat.mark_exploded.connect(func(_tick: int, mark, _link: int) -> void:
		if mark.target == boss.ketel and boss.phase == Gemaalmeester.Phase.ONE:
			from.append(marks_half.get(mark.id, [])))
	# De grens van 6000 ticks telt vanaf BOSS_START (de binnenkomst ervoor telt niet mee).
	await _run_until(t, sim, func() -> bool: return boss.start_tick >= 0, RUN_LIMIT, 1)
	t.check(boss.start_tick >= 0, "P2 op één plek: de boss startte niet")
	await _run_until(t, sim, func() -> bool: return boss.phase != Gemaalmeester.Phase.ONE,
		maxi(boss.start_tick + P2_FIXED_LIMIT - sim.tick, 0))
	run["log"].finish()
	var m := _measure(run)
	var breaks: int = run["log"].count("SCHOT_BREUK")
	var per_beat := float(breaks) / maxf(float(run["beats1"]), 1.0)
	var done := boss.phase != Gemaalmeester.Phase.ONE
	var p1_ticks := _phase1_ticks(m) if done else -1
	t.note("P2 als ontsteker op één plek (D = 60): %d schotbreuken in %d maten van fase 1 (%.2f per maat; gewone co-op-run %.2f), fase 1 %s" % [
		breaks, run["beats1"], per_beat, _coop_breaks_per_beat,
		"%d ticks" % p1_ticks if done else "niet klaar in %d ticks na BOSS_START" % P2_FIXED_LIMIT])
	# (b1)
	var good := func(f: Array) -> bool: return f.size() == 3 and f[0] == "p1" and f[1] != 0 and f[1] == -f[2]
	t.check(breaks > 0 and from.size() >= breaks and from.all(good),
		"P2 op één plek (b1): merk-ontploffingen op de ketel [zetter, doelhelft bij het zetten, helft P2] %s (verwacht elk [p1, d, −d])" % [from])
	# (b2)
	var ratio := float(p1_ticks) / float(_coop_phase1_ticks) if done and _coop_phase1_ticks > 0 else -1.0
	t.check(done and ratio >= P2_FIXED_PHASE1_MIN, "P2 op één plek (b2): fase 1 %d (−1 = niet klaar) tegen %d ticks in de gewone co-op-run (%.2f; ≥ %.2f)" % [
		p1_ticks, _coop_phase1_ticks, ratio, P2_FIXED_PHASE1_MIN])
	await t.cleanup()


## B-14 (b2): de duur van fase 1 in ticks (BOSS_START tot de fasewissel; −1 als die er niet is).
func _phase1_ticks(m: Dictionary) -> int:
	var at: Dictionary = m["at"]
	if not at.has("start") or not at.has("wissel"):
		return -1
	return int(at["wissel"]) - int(at["start"])


# --- B-10: meetlog ---------------------------------------------------------------------

## B-10: de events van de boss staan in het log van een run (solo, D = 60); GM-a (tijd tot de eerste
## SCHOT_BREUK) en GM-b (RAD_TREFFER per minuut per actie) zijn eruit te rekenen; elk event één keer
## per signaal.
func test_b10_meetlog_events(t) -> void:
	var run := _arena(t, 60, false)
	var log: Meetlog = run["log"]
	var boss: Gemaalmeester = run["boss"]
	var rad_hits := {"n": 0}
	boss.rad_hit.connect(func(_tick: int, _s: String, _a: String, _n: int) -> void: rad_hits["n"] += 1)
	var turns := {"n": 0}
	boss.rad_turning.connect(func(_tick: int, _r: String, _s: int) -> void: turns["n"] += 1)
	var m := await _play_run(t, run)
	t.check(m["defeated"], "run niet verslagen")
	for event: String in ["BOSS_START", "SCHOT_BREUK", "KERN_DICHT", "RAD_TREFFER", "RAD_DRAAI", "BOSS_AANVAL",
			"FINISHER_START", "FINISHERSLAG", "BOSS_VERSLAGEN"]:
		t.check(log.count(event) > 0, "geen %s in het log" % event)
	var phases: Array = log.rows.filter(func(r: PackedStringArray) -> bool: return r[2] == "BOSS_FASE") \
		.map(func(r: PackedStringArray) -> String: return r[3])
	t.check(phases == ["1", "wissel", "2", "wankel"], "BOSS_FASE %s" % [phases])
	t.check(log.count("RAD_TREFFER") == rad_hits["n"] and log.count("RAD_DRAAI") == turns["n"],
		"RAD_TREFFER %d (%d), RAD_DRAAI %d (%d)" % [log.count("RAD_TREFFER"), rad_hits["n"], log.count("RAD_DRAAI"), turns["n"]])
	# Elke opening sluit weer (drempel of tijd), behalve de laatste: die geeft de fasewissel.
	var closes: Array = log.rows.filter(func(r: PackedStringArray) -> bool: return r[2] == "KERN_DICHT") \
		.map(func(r: PackedStringArray) -> String: return r[3])
	# GMB-11: elke drempel behalve de laatste sluit één keer op "drempel" (v0.1.5: 7 openingen).
	var openings := EnemyData.ticks("gemaalmeester", "openingen")
	t.check(log.count("SCHOT_BREUK") >= openings and closes.size() == log.count("SCHOT_BREUK") - 1
		and closes.count("drempel") == openings - 1, "SCHOT_BREUK %d, KERN_DICHT %s" % [log.count("SCHOT_BREUK"), closes])
	t.note("SCHOT_BREUK %d, KERN_DICHT %s" % [log.count("SCHOT_BREUK"), closes])
	var verslagen: Array = log.rows.filter(func(r: PackedStringArray) -> bool: return r[2] == "BOSS_VERSLAGEN")
	t.check(int(verslagen[0][3]) == boss.finisher_count and log.count("FINISHERSLAG") == boss.finisher_count,
		"BOSS_VERSLAGEN %s, FINISHERSLAG %d (%d)" % [verslagen[0][3], log.count("FINISHERSLAG"), boss.finisher_count])
	for r: PackedStringArray in log.rows:
		if r[2] == "BOSS_AANVAL":
			t.check(r[4] == "raak" or r[4] == "mis", "BOSS_AANVAL bron %s" % r[4])
			break
	# GM-a en GM-b uit de regels.
	var start := -1
	var first_break := -1
	var phase2 := -1
	var wankel := -1
	var per_action := {}
	for r: PackedStringArray in log.rows:
		match r[2]:
			"BOSS_START":
				start = int(r[0])
			"SCHOT_BREUK":
				if first_break < 0:
					first_break = int(r[0])
			"BOSS_FASE":
				if r[3] == "2":
					phase2 = int(r[0])
				elif r[3] == "wankel":
					wankel = int(r[0])
			"RAD_TREFFER":
				per_action[r[3]] = int(per_action.get(r[3], 0)) + 1
	var minutes := float(wankel - phase2) / 3600.0
	var gm_b := {}
	for action: String in per_action:
		gm_b[action] = snappedf(per_action[action] / minutes, 0.1)
	t.check(first_break > start and start >= 0 and minutes > 0.0 and per_action.has("bounce"),
		"GM-a %d ticks, GM-b %s" % [first_break - start, gm_b])
	t.note("GM-a: eerste SCHOT_BREUK na %d ticks (%.1f s); GM-b: RAD_TREFFER per minuut fase 2 %s" % [
		first_break - start, (first_break - start) / 60.0, gm_b])
	await t.cleanup()
