extends RefCounted
## Scripted boss-runs tegen de Gemaalmeester (T8b-bouw deel 2b, #190): B-9 (`boss_bot.gd`, solo en
## co-op per D, de C-16-runs, drop-out van P2) en B-10 (meetlog-events). Bron:
## `docs/design/combat/slice-vijanden-en-boss.md` v0.1.2 §3.9, §6, §7; gdd v0.8.1 §4.5, §4.6 (C-16).
##
## Elke run: arena van 600 px met twee muren, de Gemaalmeester op de linkermuur, P1 (en P2) met de
## bot als inputbron, meetlog met `watch_boss`. De run duurt van BOSS_START tot BOSS_VERSLAGEN; de
## duur per deel komt in de note (tabel voor de Combat Designer, §3.9). Een run duurt langer dan de
## standaardgrens van de runner (7200 frames): `MAX_FRAMES` zet per test een eigen grens.

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

## Een run duurt bij D = 180 langer dan 2 minuten speltijd; de grens is ruim, de run zelf stopt bij
## BOSS_VERSLAGEN of op `RUN_LIMIT`.
const RUN_LIMIT := 20000
const MAX_FRAMES := {
	"test_b9_solo_d60": 22000, "test_b9_solo_d90": 22000, "test_b9_solo_d120": 22000,
	"test_b9_solo_d180": 22000, "test_b9_coop_d60": 22000, "test_b9_coop_d90": 22000,
	"test_b9_coop_d120": 22000, "test_b9_coop_d180": 22000, "test_b9_drop_out_phase1": 22000,
	"test_b9_drop_out_wankel": 22000, "test_b9_c16_solo_echo_off": 13000,
	"test_b9_c16_coop_p2_never_hits": 13000, "test_b9_one_strike_per_bounce": 22000,
	"test_b10_meetlog_events": 22000,
}


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
	# Een geoefende run meet de duur; P1 mag er niet tussendoor aan doodgaan (de treffers tellen we).
	p1.health = 100000
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
		"defeated": run["boss"].is_defeated()}
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
		"MP-1 P1 %d (P2 %d) · treffers op P1 %s · rad %s · kanten %s · eerste SCHOT_BREUK na %d") % [name,
		part.call("start", "wissel"), part.call("wissel", "2"), part.call("2", "wankel"),
		part.call("wankel", "verslagen"), str(m.get("total", "?")), float(m.get("total", 0)) / 60.0,
		m["mp1"], m["mp1_p2"], "%d %s" % [m["hits"], m["hits_per_part"]], m["rad"], m["turns"],
		int(m["first_break"]) - int(at.get("start", 0))]


# --- B-9: scripted runs per D ---------------------------------------------------

## B-9 en C-16 (3) op de Gemaalmeester: de run wint (BOSS_VERSLAGEN), MP-1 ≤ 300, de echo breekt
## nooit; bij D = 60 duurt de solo-run 90–150 s (§3.9).
func _solo(t, d: int) -> void:
	var run := _arena(t, d, false)
	var m := await _play_run(t, run)
	t.note(_table_row("solo D = %d" % d, m))
	_check_run(t, "solo D = %d" % d, m)
	if d == 60:
		var s := float(m.get("total", 0)) / 60.0
		t.check(s >= 90.0 and s <= 150.0, "solo D = 60: %.1f s (90–150, §3.9)" % s)
	await t.cleanup()


func _check_run(t, name: String, m: Dictionary) -> void:
	t.check(m["defeated"], "%s: niet verslagen in %d ticks (%s)" % [name, RUN_LIMIT, m["at"]])
	t.check(m["mp1"] <= 300, "%s: MP-1 %d > 300" % [name, m["mp1"]])
	t.check(m["breaks"] == 0, "%s: de echo brak %d keer" % [name, m["breaks"]])
	t.check(int(m["first_break"]) >= 0, "%s: geen SCHOT_BREUK" % name)


func _coop(t, d: int) -> void:
	var run := _arena(t, d, true)
	var m := await _play_run(t, run)
	t.note(_table_row("co-op D = %d" % d, m))
	_check_run(t, "co-op D = %d" % d, m)
	await t.cleanup()


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


## B-9: §3.5 rekent met één slag per bounce; de geoefende run slaat er twee (cooldown 20 < venster
## 28). Hier dezelfde solo-run met één slag per bounce, voor de tabel van de Combat Designer: hij wint,
## MP-1 ≤ 300, de echo breekt niet; de duur staat in de note (geen eis).
func test_b9_one_strike_per_bounce(t) -> void:
	var run := _arena(t, 60, false)
	run["bot"].strikes_per_bounce = 1
	var m := await _play_run(t, run)
	t.note(_table_row("solo D = 60, 1 slag per bounce", m))
	_check_run(t, "solo D = 60, 1 slag per bounce", m)
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
	t.check(run["log"].count("FINISHER_START") == 0 and not boss.is_defeated() and boss.se == 1500,
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
	t.check(run["log"].count("FINISHER_START") == 0 and not boss.is_defeated() and boss.se == 1500,
		"P2 slaat nooit: finisher %d, %d SE" % [run["log"].count("FINISHER_START"), boss.se])
	await t.cleanup()


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
	t.check(log.count("SCHOT_BREUK") >= 4 and closes.size() == log.count("SCHOT_BREUK") - 1
		and closes.count("drempel") == 3, "SCHOT_BREUK %d, KERN_DICHT %s" % [log.count("SCHOT_BREUK"), closes])
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
