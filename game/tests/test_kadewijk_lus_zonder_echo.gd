extends RefCounted
## G-3 (#291, testplan T11 §6): de Kadewijk-lus **zonder echo**, C-15 en FK-2 over de hele
## slice. Kamerdoc `docs/design/kamers/kadewijk.md` §6c, §6d, §9; gdd C-15, C-16, FK-2.
##
## Dezelfde gescripte geoefende run als `test_kadewijk_lus.gd` (`kadewijk_bot.gd` met `lus`,
## in S8 `boss_bot.gd`), maar solo met `echo_on = false`: de bot neemt dan overal de langzame
## lijn (FK-2) en haalt in S6 licht in S5 als de meter niet genoeg heeft (LM-13, zoals deel 2).
##
## **Testuitzondering voor S8 (C-16).** Solo met de echo uit is de Gemaalmeester niet te
## verslaan (C-16 (a); `test_boss.gd` B-5/B-7: het schot breekt zonder echo nooit). De lus zonder
## echo gaat daarom wél de arena in en vecht `C16_WINDOW` ticks met de boss-bot, en toetst in dat
## venster C-16 op de echte arena (alleen negatief bewijs; het bewijs voor C-16 (a) blijft B-5/B-7 in
## `test_boss.gd`): het schot breekt niet, de boss verliest geen SE en is niet
## verslagen. Daarna verslaat de test de boss (`Boss._defeat`, dezelfde weg als de finisher:
## `BOSS_VERSLAGEN`, de deuren open, 100 LP, de vlag). Zo blijft de rest van de lus (trap 2, het
## hoogwater, S9, het snelluik) te toetsen. De boss telt in geen enkele verhouding mee: de
## vergelijking met de lus mét echo is de **route** (alles behalve `BOSS_START` … `BOSS_VERSLAGEN`).
##
## Per kamer: de tijd (alle bezoeken samen, FlowReport `room_time`; S8 zonder de boss) zonder en
## mét echo, en de verhouding. Normen: de route ≤ 2× (C-15 a, FK-2), elke plek bereikbaar (alle
## kamers, de 5 verzamelobjecten, het gemaal vol, trap 2, het hoogwater, beide luiken,
## `SLICE_EIND`), geen enkele echolijn genomen (13 bouwstenen met een echolijn), geen respawn. Per kamer ≤ 2×, behalve S6:
## daar loopt de bot zonder echo terug voor licht (afwijking 10, LGD-besluit: C-15 in S6 met gelijk
## licht, `test_kadewijk_deel2.gd`); die twee zijn een rapportwaarde.

const Scene := preload("res://levels/kadewijk/kadewijk.tscn")
const Bot = preload("res://levels/kadewijk/kadewijk_bot.gd")
const BossBot = preload("res://tests/boss_bot.gd")
const Layout = preload("res://levels/kadewijk/kadewijk_layout.gd")
const Kadewijk = preload("res://levels/kadewijk/kadewijk.gd")
const Progress = preload("res://scripts/save/progress.gd")
const AreaLoader = preload("res://scripts/world/area_loader.gd")
const FlowReport = preload("res://levels/flowkamer/flow_report.gd")
const Gemaal = preload("res://scripts/light/gemaal.gd")
const Boss = preload("res://scripts/combat/boss.gd")

const RUN_LIMIT := 34000
## C-16-venster in de arena zonder echo: 1800 ticks (30 s), langer dan fase 1 mét echo bij
## D = 60 (1680 ticks, §6b): met de echo is het schot dan al gebroken.
const C16_WINDOW := 1800
const ROOMS := [&"S1", &"S2", &"S3", &"S4", &"S5", &"S6", &"S7", &"S8", &"S9"]
## De kamer waar de bot zonder echo 4× terug moet voor licht (afwijking 10): de verhouding is daar
## een rapport. S5 (licht halen) houdt wel ≤ 2× (TD-review #296).
const LIGHT_ROOMS := [&"S6"]
## Soorten stappen van `kadewijk_bot.gd` met een echolijn (bouwstenen B1–B4, het gemaal en trap 2:
## de echo pompt mee). Het luik, het kanaal, het Dwaallicht en de schacht zijn de Neerslag van P1
## zelf (V-01), geen samenwerkingsactie: daar is `lines` true als P1 stuit, met of zonder echo.
const ECHO_KINDS := ["turn", "b3", "b4", "gemaal", "trap2"]
const MAX_FRAMES := {
	"test_met_echo_d60": 20000, "test_zonder_echo_d60": 34000,
	"test_met_echo_d120": 20000, "test_zonder_echo_d120": 34000,
	"test_met_echo_d180": 20000, "test_zonder_echo_d180": 34000,
}

## De lus mét echo per D (de referentie), gevuld door `test_met_echo_d*`.
static var _ref := {}


func _flag(room: StringName, path: NodePath) -> StringName:
	return AreaLoader.object_flag(room, path, Kadewijk.GEBIED)


func _first(rows: Array, event: String, value := "") -> int:
	for row in rows:
		if row[2] == event and (value == "" or row[3] == value):
			return int(row[0])
	return -1


func _count(rows: Array, event: String, value := "") -> int:
	var n := 0
	for row in rows:
		if row[2] == event and (value == "" or row[3] == value):
			n += 1
	return n


func _kinds(bot) -> Dictionary:
	var out := {}
	for spec: Array in bot._legs:
		out[String(spec[0])] = String(spec[1])
	return out


## Eén lus van S1 tot `SLICE_EIND`. Geeft de meetwaarden terug.
func _lus(t, d: int, echo_on: bool) -> Dictionary:
	var progress := Progress.new()
	progress.name = "TestProgress"
	t.tree.root.add_child(progress)
	var wijk = Scene.instantiate()
	wijk.tail = d
	wijk.echo_on = echo_on
	wijk.show_hud = false
	wijk.progress = progress
	wijk.start_at = Layout.ROOM_START[&"S1"]
	wijk.run_end = Kadewijk.RUN_END_LUS
	var bot := Bot.new(wijk, d, &"S1")
	bot.lus = true
	bot.boss_input = func(sim: Node, boss: Node) -> RefCounted:
		return BossBot.new(sim, boss).p1_source
	wijk.input_override = bot
	t.tree.root.add_child(wijk)
	var c16 := {"window": false, "shot": [], "se_before": -1, "se_after": -1, "defeated_by_bot": false, "exception_tick": -1}
	var watched: Node = null
	await t.tree.physics_frame
	while not wijk.run_over and wijk.sim.tick < RUN_LIMIT:
		await t.tree.physics_frame
		var boss = wijk.boss
		if echo_on or boss == null or not is_instance_valid(boss):
			continue
		if watched != boss:
			watched = boss
			boss.shot_broken.connect(func(tick: int) -> void: c16["shot"].append(tick))
		# Testuitzondering S8 (C-16): na het venster verslaat de test de boss.
		if boss.start_tick >= 0 and c16["exception_tick"] < 0:
			if c16["se_before"] < 0:
				c16["se_before"] = boss.se_max
			if boss.state == Boss.State.DEFEATED:
				c16["defeated_by_bot"] = true
				c16["exception_tick"] = wijk.sim.tick
			elif wijk.sim.tick - boss.start_tick >= C16_WINDOW:
				c16["window"] = true
				c16["se_after"] = boss.se
				c16["exception_tick"] = wijk.sim.tick
				# Vanuit FIGHT kan een aanval lopen: eerst afbreken (attack_ended), dan verslaan
				# (TD-review #296). `_defeat` is privé; komt er een derde test die hem aanroept,
				# dan een publieke testingang op `Boss` (kamerdoc §9).
				boss.abort_attack(wijk.sim.tick)
				boss._defeat(wijk.sim.tick)
	await t.tree.physics_frame
	await t.tree.physics_frame
	if not wijk.run_over:
		wijk.meetlog.finish()
	var rows: Array = wijk.meetlog.rows
	var rep = FlowReport.from_rows(rows, echo_on)
	progress.store_world()
	var missing: Array = []
	for spec: Array in [[&"S5", ^"Lampglas"], [&"S5", ^"Logbladzijde1"], [&"S6", ^"Logbladzijde2"],
			[&"S7", ^"Neerslag"], [&"S9", ^"Logbladzijde3"], [&"S8", ^"BossVerslagen"]]:
		if not progress.state.has_flag(_flag(spec[0], spec[1])):
			missing.append("%s/%s" % spec)
	var g: Dictionary = progress.state.gemalen.get(_flag(&"S6", ^"Gemaal"), {})
	var luiken := {}
	for row in rows:
		if row[2] == "LUIK":
			luiken[row[1]] = true
	var rooms := {}
	for row in rows:
		if row[2] == "KAMER":
			rooms[StringName(row[4])] = true
	var boss_start := _first(rows, "BOSS_START")
	var verslagen := _first(rows, "BOSS_VERSLAGEN")
	var room_time: Dictionary = rep.room_time.duplicate()
	var boss_ticks := verslagen - boss_start if boss_start >= 0 and verslagen >= 0 else 0
	# S8 zonder de boss: de route (arena in en uit).
	room_time[&"S8"] = int(room_time.get("S8", 0)) - boss_ticks
	var out := {
		"d": d, "echo": echo_on, "ticks": wijk.run_ticks(), "slice_end": wijk.slice_end_tick, "run_over": wijk.run_over,
		"room": wijk.room, "leg": bot.leg_name(), "sub": bot.sub, "p1": wijk.p1.position,
		"boss_ticks": boss_ticks, "route": wijk.run_ticks() - boss_ticks, "room_time": room_time,
		"rooms": rooms, "missing": missing, "gemaal": g, "luiken": luiken,
		"trap2": _first(rows, "TRAP_VOL", "2"), "water": _first(rows, "WATERSTAND", "2"),
		"gemaal_vol": _count(rows, "GEMAAL_VOL"), "eind": _count(rows, "SLICE_EIND"),
		"respawns": _count(rows, "RESPAWN"), "verslagen": _count(rows, "BOSS_VERSLAGEN"),
		"picked": {"lampglas": wijk.lampglas_tick, "neerslag": wijk.neerslag_tick, "blad": wijk.logblad_ticks.keys().size()},
		"lines": bot.lines.duplicate(), "kinds": _kinds(bot), "returns": bot.s6_returns, "still": rep.longest_still,
		"most": wijk.most_at_once, "boss_spawns": wijk.boss_spawns, "c16": c16, "errors": wijk.start_errors,
	}
	wijk.queue_free()
	progress.queue_free()
	await t.tree.process_frame
	return out


## De gedeelde checks: de lus is rond en elke plek is gehaald (C-15 a).
func _check_rond(t, r: Dictionary, name: String) -> void:
	t.check(r["errors"].is_empty(), "%s: start %s" % [name, r["errors"]])
	t.check(r["run_over"] and r["slice_end"] > 0 and r["room"] == &"S1" and r["eind"] == 1,
		"%s: SLICE_EIND niet gehaald (tick %d, stap %s, sub %s, kamer %s, P1 %s)" % [
		name, r["ticks"], r["leg"], r["sub"], r["room"], r["p1"]])
	var not_seen: Array = ROOMS.filter(func(k: StringName) -> bool: return not r["rooms"].has(k))
	t.check(not_seen.is_empty(), "%s: kamers niet bezocht: %s" % [name, not_seen])
	t.check(r["missing"].is_empty() and int(r["gemaal"].get("vulstand", 0)) == 200 and bool(r["gemaal"].get("vol", false)),
		"%s: niet in de save: %s, gemaal %s" % [name, r["missing"], r["gemaal"]])
	t.check(r["picked"]["lampglas"] > 0 and r["picked"]["neerslag"] > 0 and r["picked"]["blad"] == 3,
		"%s: niet alles opgepakt: %s" % [name, r["picked"]])
	t.check(r["gemaal_vol"] == 1 and r["trap2"] > 0 and r["water"] == r["trap2"] + Gemaal.DRAIN_TICKS,
		"%s: GEMAAL_VOL %d, trap 2 %d, hoogwater %d" % [name, r["gemaal_vol"], r["trap2"], r["water"]])
	t.check(r["luiken"].has("S7") and r["luiken"].has("S9"), "%s: luiken open %s (S7 en S9)" % [name, r["luiken"].keys()])
	t.check(r["verslagen"] == 1 and r["boss_spawns"] == 1, "%s: BOSS_VERSLAGEN %d, boss %d× gespawnd" % [name, r["verslagen"], r["boss_spawns"]])
	t.check(r["respawns"] == 0, "%s: %d respawns" % [name, r["respawns"]])
	t.check(r["still"] <= 300, "%s: MP-1 %d > 300" % [name, r["still"]])
	t.check(r["most"] <= 5, "%s: %d vijanden tegelijk (L-13 f)" % [name, r["most"]])


func _met_echo(t, d: int) -> void:
	var r := await _lus(t, d, true)
	_check_rond(t, r, "met echo D = %d" % d)
	_ref[d] = r
	t.note("met echo D = %d: run %d, boss %d, route %d ticks; per kamer %s" % [d, r["ticks"], r["boss_ticks"], r["route"], r["room_time"]])


func _zonder_echo(t, d: int) -> void:
	var name := "zonder echo D = %d" % d
	var r := await _lus(t, d, false)
	_check_rond(t, r, name)
	# Geen enkele echolijn (FK-2): elke bouwsteen langs de langzame lijn.
	var echo_legs: Array = r["lines"].keys().filter(func(k: String) -> bool: return ECHO_KINDS.has(r["kinds"].get(k, "")))
	var echo_lines: Array = echo_legs.filter(func(k: String) -> bool: return r["lines"][k])
	t.check(echo_lines.is_empty() and echo_legs.size() >= 13, "%s: echolijn genomen zonder echo: %s (van %d bouwstenen)" % [name, echo_lines, echo_legs.size()])
	# S8, testuitzondering (C-16): het venster gehaald, het schot heel, geen SE eraf, niet door de bot verslagen.
	var c: Dictionary = r["c16"]
	t.check(c["window"] and not c["defeated_by_bot"] and c["shot"].is_empty() and c["se_after"] == c["se_before"] and c["se_before"] > 0,
		"%s: C-16 in de arena: venster %s, verslagen door de bot %s, schot gebroken %s, SE %d van %d" % [
		name, c["window"], c["defeated_by_bot"], c["shot"], c["se_after"], c["se_before"]])
	t.check(r["boss_ticks"] == C16_WINDOW, "%s: de boss %d ticks (verwacht het venster, %d)" % [name, r["boss_ticks"], C16_WINDOW])
	if not _ref.has(d):
		t.check(false, "%s: geen referentie mét echo (test_met_echo_d%d draait eerst)" % [name, d])
		return
	var ref: Dictionary = _ref[d]
	# C-15 a / FK-2: de route zonder echo ≤ 2× die mét echo (de boss telt niet).
	var ratio := float(r["route"]) / float(ref["route"])
	t.check(r["route"] <= 2 * ref["route"], "%s: route %d ticks, met echo %d (%.2f×; C-15, FK-2: ≤ 2×)" % [name, r["route"], ref["route"], ratio])
	t.check(r["returns"] <= 4, "%s: %d× terug naar S5 voor licht (FK-2: ≤ 4)" % [name, r["returns"]])
	var per_room: Array = []
	for k: StringName in ROOMS:
		var off := int(r["room_time"].get(String(k), r["room_time"].get(k, 0)))
		var on := int(ref["room_time"].get(String(k), ref["room_time"].get(k, 0)))
		var q := float(off) / float(on) if on > 0 else INF
		per_room.append("%s %d / %d (%.2f×)" % [k, off, on, q])
		if not LIGHT_ROOMS.has(k):
			t.check(on > 0 and off <= 2 * on, "%s: %s zonder echo %d ticks, met %d (%.2f×; C-15: ≤ 2×)" % [name, k, off, on, q])
	t.note("%s: route %d tegen %d ticks (%.2f×, marge %d tot 2×) · run %d (boss = C-16-venster %d) · %d× terug voor licht · per kamer zonder / met echo (S8 zonder de boss; S6 rapport, afwijking 10): %s" % [
		name, r["route"], ref["route"], ratio, 2 * ref["route"] - r["route"], r["ticks"], r["boss_ticks"], r["returns"], ", ".join(per_room)])


func test_met_echo_d60(t) -> void:
	await _met_echo(t, 60)


func test_zonder_echo_d60(t) -> void:
	await _zonder_echo(t, 60)


func test_met_echo_d120(t) -> void:
	await _met_echo(t, 120)


func test_zonder_echo_d120(t) -> void:
	await _zonder_echo(t, 120)


func test_met_echo_d180(t) -> void:
	await _met_echo(t, 180)


func test_zonder_echo_d180(t) -> void:
	await _zonder_echo(t, 180)
