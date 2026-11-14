extends RefCounted
## De Kadewijk in co-op (T11 G-1, #88; testplan `docs/qa/testplan-t11-slice.md` §4 en §6):
## de gescripte geoefende co-op-run (`kadewijk_duo.gd`, P1 en P2 live, P2 in de rol
## van de schaduw, besluit #51 7A) per kamer S1–S9 en als lus S1 → S8 → de
## Gemaalmeester → S9 → trap 2 → S9 → S1 (`SLICE_EIND`), bij D = 60 en als regressie
## bij 90, 120 en 180.
##
## Wat een check is (gdd §4.5: de co-op-run bewijst dat de kamer de normen kán halen;
## testplan T11 §4, voorwaarde MT3): MP-1 van P1 én P2 ≤ 300, MP-2 ≥ 3,0 per minuut
## met een gat ≤ 2400 ticks, MP-4 ≤ 40 %, MP-6 ≥ 40 % met ≥ 1 pompslag van P2, en
## MP-7 (b)–(d), over de lus en per kamer (W38: per kamer = `KAMER` tot `KAMER`; de
## boss = `BOSS_START` … `BOSS_VERSLAGEN`, apart van de route van S8). MP-3 en MP-7 (a)
## (een mediaan over mensen) staan alleen in de uitvoer; MP-7 (a) tegen de solo-lus van
## dezelfde D uit dit script.
##
## Geen check (wel gemeten, in de uitvoer): MP-7 (b) van P2 in de boss (`BOSS_START` …
## `BOSS_VERSLAGEN`, in de lus en in S8 los). De boss-bot (`tests/boss_bot.gd`) laat P2
## aan de ketel en onder het rad ± 925 ticks stilstaan; wachten met wiebelen telt als
## wachten (gdd MP-1/MP-3), dus de waarde is niet gehaald → G-2 (Combat Designer). Een
## check die nu rood is, zegt niets over deze PR; de lus checkt MP-7 (b) van P2 daarom
## buiten de boss. De voorwaarde voor MT3 ("MP-7 in de boss") is dus nog niet gehaald.
## Ook in de uitvoer: de ticks waarin elke speler op de ander wacht (`wait_ticks`, ± 18 px,
## net buiten de 24 px van MP-1), per kamer, zodat "niemand wacht" (MP-7) niet alleen op
## MP-1 leunt. Verder: de lus is rond, de boss verslagen (één poging),
## trap 2 en het water, alles opgepakt, geen respawn, en de run is deterministisch.
##
## De meetlogs (zelfde formaat als de solo-meetlog: `tick, kamer, event, waarde, bron,
## x, y`; P2 met bron `p2`, de samenwerkingsacties met bron = de drager) schrijft dit
## script naar de map in de omgevingsvariabele `POLDERLIGHT_BOTLOGS` als die gezet is
## (`bot_lus_coop_D<D>.csv`, `bot_kamer_coop_<kamer>_D60.csv`, en de solo-referentie
## `bot_lus_solo_D60.csv`), voor `rekenen.gd` (Q-3).
##
## Werkaanname (kader §5): D = 60 is een CEO-besluit als werkaanname (2026-11-12, nog niet
## gespeeld); de geoefende co-op-run is het duo van `kadewijk_duo.gd` (werkaanname
## Gameplay Programmer, zie daar); per kamer telt de kamer van P1 (de kolom `kamer`).
## De run per kamer begint in S6 met 0 LP (zoals elke run vanaf het begin van een kamer):
## daar haalt het duo licht in S5 (LM-13), dus die tijd zegt niets over de lus.
##
## Elke test maakt een eigen `Progress`; de autoloads en `user://saves` blijven onaangeroerd.

const Scene := preload("res://levels/kadewijk/kadewijk.tscn")
const Duo = preload("res://levels/kadewijk/kadewijk_duo.gd")
const Bot = preload("res://levels/kadewijk/kadewijk_bot.gd")
const BossBot = preload("res://tests/boss_bot.gd")
const Layout = preload("res://levels/kadewijk/kadewijk_layout.gd")
const Kadewijk = preload("res://levels/kadewijk/kadewijk.gd")
const Progress = preload("res://scripts/save/progress.gd")
const GameState = preload("res://scripts/save/game_state.gd")
const AreaLoader = preload("res://scripts/world/area_loader.gd")
const FlowReport = preload("res://levels/flowkamer/flow_report.gd")
const Gemaal = preload("res://scripts/light/gemaal.gd")

const RUN_LIMIT := 34000
const MINUTE := 3600.0
## Bronnen van LP met een samenwerkingsactie (MP-6 co-op), zoals `test_flowtest_t17.gd`.
const COOP_LP := ["springplank", "bounce", "lancering", "vangen", "ontploffing"]
const MAX_FRAMES := {
	"test_solo_lus_referentie_d60": 20000,
	"test_coop_lus_d60": 36000, "test_coop_lus_d60_deterministisch": 36000,
	"test_coop_lus_d90": 36000, "test_coop_lus_d120": 36000, "test_coop_lus_d180": 36000,
	"test_coop_per_kamer_s1_s4_d60": 12000, "test_coop_per_kamer_s5_s7_d60": 12000,
	"test_coop_per_kamer_s8_d60": 16000, "test_coop_per_kamer_s9_d60": 12000,
}

## De solo-lus bij D = 60: tijd per kamer en totaal (MP-7 (a)).
static var _solo := {}
static var _lus60_csv := ""


# --- Opzet ------------------------------------------------------------------------

func _wijk(t, d: int, start: StringName, run_end: StringName, lus: bool) -> Array:
	var progress := Progress.new()
	progress.name = "TestProgress"
	t.tree.root.add_child(progress)
	# V-01 (besluit LGD #252): wie voorbij de sokkel (S7) begint, heeft de Neerslag al.
	if start == &"S8" or start == &"S9":
		Kadewijk.give_neerslag(progress.state)
	var wijk = Scene.instantiate()
	wijk.tail = d
	wijk.echo_on = true
	wijk.show_hud = false
	wijk.progress = progress
	wijk.start_at = Layout.ROOM_START[start]
	wijk.run_end = run_end
	var duo := Duo.new(wijk, d, start, lus)
	duo.boss_input = func(sim: Node, boss: Node) -> RefCounted: return BossBot.new(sim, boss)
	wijk.input_override = duo.p1_input
	t.tree.root.add_child(wijk)
	return [wijk, progress, duo]


func _free(t, parts: Array) -> void:
	parts[0].queue_free()
	parts[1].queue_free()
	await t.tree.process_frame
	await t.tree.physics_frame


## Eén co-op-run: P2 doet mee vóór de eerste tick (drop-in, de echo nog Leeg: P2
## verschijnt bij P1, C-03), zoals `test_flowtest_duo.gd`. Geeft de onderdelen terug.
func _coop(t, d: int, start: StringName, run_end: StringName, lus: bool, setup := Callable()) -> Dictionary:
	var parts := _wijk(t, d, start, run_end, lus)
	var wijk = parts[0]
	var duo = parts[2]
	await t.tree.physics_frame
	t.check(wijk.join_partner(duo.p2_input), "co-op %s D=%d: drop-in mislukt" % [start, d])
	if setup.is_valid():
		setup.call(wijk)
	var hits: Array = []
	var last_health := {"v": wijk.p1.health}
	wijk.p1.health_changed.connect(func(tick: int, health: int) -> void:
		if health < int(last_health["v"]):
			hits.append([tick, health])
		last_health["v"] = health)
	while not wijk.run_over and wijk.sim.tick < RUN_LIMIT:
		await t.tree.physics_frame
	await t.tree.physics_frame
	if not wijk.meetlog.is_closed():
		wijk.meetlog.finish()
	return {"wijk": wijk, "progress": parts[1], "duo": duo, "rows": wijk.meetlog.rows, "hits": hits, "parts": parts}


func _save_csv(wijk, file: String) -> void:
	var dir := OS.get_environment("POLDERLIGHT_BOTLOGS")
	if dir == "":
		return
	DirAccess.make_dir_recursive_absolute(dir)
	wijk.meetlog.save(dir.path_join(file))


func _count(rows: Array, event: String, value := "", source := "") -> int:
	var n := 0
	for row in rows:
		if row[2] == event and (value == "" or row[3] == value) and (source == "" or row[4] == source):
			n += 1
	return n


func _first(rows: Array, event: String, value := "") -> int:
	for row in rows:
		if row[2] == event and (value == "" or row[3] == value):
			return int(row[0])
	return -1


# --- Maten per stuk van de run (W38) --------------------------------------------

## Maten over de ticks van `segments` (lijst van [van, tot), halfopen) en de rijen
## waarvan de kamer in `rooms` ligt (leeg = alle); MP-1 = de langste stilstand die in
## het stuk eindigt (zoals `_still_per_room` van de solo-tests).
func _measure(rows: Array, segments: Array) -> Dictionary:
	var ticks := 0
	for seg: Array in segments:
		ticks += maxi(int(seg[1]) - int(seg[0]), 0)
	var inside := func(tick: int) -> bool:
		for seg: Array in segments:
			if tick >= int(seg[0]) and tick < int(seg[1]):
				return true
		return false
	var m := {"ticks": ticks, "mp1_p1": 0, "mp1_p2": 0, "actions": 0, "coop": 0, "combos": 0,
		"bounce": 0, "lancering": 0, "vangen": 0, "springplank": 0, "lp": 0, "lp_coop": 0,
		"pomp_p1": 0, "pomp_p2": 0, "dissolved": 0, "gap": 0, "stuit_p2": 0}
	var contacts := {}
	var action_ticks: Array = []
	var gone_since := -1
	for row in rows:
		var tick := int(row[0])
		var event: String = row[2]
		if event == "P2_OPGELOST":
			gone_since = tick
		elif event == "P2_TERUG" or event == "DROP_OUT":
			if gone_since >= 0:
				for k in range(gone_since, tick):
					if inside.call(k):
						m["dissolved"] += 1
			gone_since = -1
		if not inside.call(tick):
			continue
		match event:
			"STIL_EIND":
				var key := "mp1_p2" if row[4] == "p2" else "mp1_p1"
				m[key] = maxi(int(m[key]), int(row[3]))
			"SPRINGPLANK", "LANCERING", "VANGEN", "BOUNCE":
				m[event.to_lower()] += 1
				if event != "BOUNCE":
					var contact := "%d|%s" % [tick, row[4]]
					if not contacts.has(contact):
						contacts[contact] = true
						m["actions"] += 1
						m["coop"] += 1
						action_ticks.append(tick)
			"ONTPLOFFING":
				# In co-op knalt een merk alleen door het andere lichaam (C-12b); een ketting telt als één.
				if row[3] == "1":
					m["actions"] += 1
					m["coop"] += 1
					m["combos"] += 1
					action_ticks.append(tick)
			"LP":
				var n := int(str(row[3]).trim_prefix("+"))
				m["lp"] += n
				var src: PackedStringArray = str(row[4]).rsplit("_", true, 1)
				if src[src.size() - 1] == "p2" or src[0] in COOP_LP:
					m["lp_coop"] += n
			"POMP":
				if row[4] == "p1":
					m["pomp_p1"] += 1
				elif row[4] == "p2":
					m["pomp_p2"] += 1
			"STUIT":
				if row[4] == "p2":
					m["stuit_p2"] += 1
	if gone_since >= 0:
		for seg: Array in segments:
			for k in range(maxi(gone_since, int(seg[0])), int(seg[1])):
				m["dissolved"] += 1
	# MP-2: het langste gat zonder actie binnen de stukken.
	action_ticks.sort()
	for seg: Array in segments:
		var last := int(seg[0])
		for a: int in action_ticks:
			if a >= int(seg[0]) and a < int(seg[1]):
				m["gap"] = maxi(int(m["gap"]), a - last)
				last = a
		m["gap"] = maxi(int(m["gap"]), int(seg[1]) - last)
	var minutes := maxf(float(ticks), 1.0) / MINUTE
	m["mp2"] = float(m["actions"]) / minutes
	m["mp7c"] = float(m["coop"]) / minutes
	m["mp7d"] = float(m["dissolved"]) / maxf(float(ticks), 1.0)
	m["mp6"] = float(m["lp_coop"]) / maxf(float(m["lp"]), 1.0)
	return m


## De stukken per kamer (W38): `KAMER` tot `KAMER` (de kamer van P1), en S8 zonder
## `BOSS_START` … `BOSS_VERSLAGEN`, dat als "Boss" apart staat.
func _segments(rows: Array) -> Dictionary:
	var out := {}
	var room := ""
	var since := 0
	var end := int(rows[rows.size() - 1][0]) if not rows.is_empty() else 0
	var boss := [_first(rows, "BOSS_START"), _first(rows, "BOSS_VERSLAGEN")]
	for row in rows:
		if row[2] == "RUN_START":
			room = row[1]
			since = int(row[0])
		elif row[2] == "KAMER":
			_add_segment(out, room, since, int(row[0]), boss)
			room = row[4]
			since = int(row[0])
		elif row[2] == "RUN_EIND":
			end = int(row[0])
	_add_segment(out, room, since, end, boss)
	return out


func _add_segment(out: Dictionary, room: String, from: int, to: int, boss: Array) -> void:
	if room == "" or to <= from:
		return
	var parts: Array = [[from, to]]
	if room == "S8" and boss[0] >= 0:
		var b1: int = boss[1] if boss[1] >= 0 else to
		parts = [[from, mini(boss[0], to)], [maxi(b1, from), to]]
		if not out.has("Boss"):
			out["Boss"] = []
		out["Boss"].append([maxi(boss[0], from), mini(b1, to)])
	if not out.has(room):
		out[room] = []
	out[room].append_array(parts)


func _fmt(m: Dictionary) -> String:
	return ("%d ticks (%.1f s) · MP-1 P1 %d / P2 %d · MP-2 %.1f/min, gat %d · samen %d (bounce %d, lancering %d, vang %d, combo %d) " +
		"→ MP-7c %.2f/min per speler · MP-7d %.1f %% · MP-6 %.0f %% van %d LP · pomp P1 %d / P2 %d") % [
		m["ticks"], m["ticks"] / 60.0, m["mp1_p1"], m["mp1_p2"], m["mp2"], m["gap"], m["coop"], m["bounce"], m["lancering"],
		m["vangen"], m["combos"], m["mp7c"], m["mp7d"] * 100.0, m["mp6"] * 100.0, m["lp"], m["pomp_p1"], m["pomp_p2"]]


## Normen van de co-op-run (gdd §4.5, testplan T11 §2.1, §4): leeg = gehaald. `per_room`:
## dan geen MP-6 (een kamer zonder LP-bron is geen fout) en geen pompslag. `rates` = false:
## zonder MP-2 en MP-7 (c) (de route van S8, zie `_lus`). `p2_still` = false: zonder
## MP-7 (b) van P2 (de boss, zie de kop van dit script).
func _norms(m: Dictionary, per_room: bool, rates := true, p2_still := true) -> PackedStringArray:
	var out := PackedStringArray()
	if int(m["mp1_p1"]) > 300: out.append("MP-1 P1 %d" % m["mp1_p1"])
	if p2_still and int(m["mp1_p2"]) > 300: out.append("MP-7b P2 %d" % m["mp1_p2"])
	if rates and float(m["mp2"]) < 3.0: out.append("MP-2 %.2f/min" % m["mp2"])
	if int(m["gap"]) > 2400: out.append("MP-2 gat %d" % m["gap"])
	if rates and float(m["mp7c"]) < 1.0: out.append("MP-7c %.2f/min" % m["mp7c"])
	if float(m["mp7d"]) > 0.10: out.append("MP-7d %.0f %%" % (float(m["mp7d"]) * 100.0))
	if not per_room:
		if float(m["mp6"]) < 0.40: out.append("MP-6 %.0f %%" % (float(m["mp6"]) * 100.0))
		if int(m["pomp_p2"]) < 1: out.append("MP-6 geen pompslag van P2")
	return out


## MP-7 (b) van P2 in de boss, als echte waarde (geen check, zie de kop van dit script).
func _boss_p2(m: Dictionary) -> String:
	var v := int(m["mp1_p2"])
	return "MP-7b P2 in de boss %d%s" % [v, " (niet gehaald → G-2, Combat Designer; geen check)" if v > 300 else " (≤ 300)"]


## Wachten op de ander (`Seat.wait_ticks`, ± 18 px): per kamer van die speler, en totaal.
func _waits(duo, room := "") -> String:
	var out := PackedStringArray()
	for s in [duo.p1_input, duo.p2_input]:
		var per: Dictionary = s.wait_ticks
		if room != "":
			out.append("P%d %d" % [s.index, int(per.get(StringName(room), 0))])
			continue
		var total := 0
		var parts := PackedStringArray()
		for k in ["S1", "S2", "S3", "S4", "S5", "S6", "S7", "S8", "S9"]:
			var n := int(per.get(StringName(k), 0))
			total += n
			if n > 0:
				parts.append("%s %d" % [k, n])
		out.append("P%d %d (%s)" % [s.index, total, ", ".join(parts) if not parts.is_empty() else "—"])
	return "wachten op de ander %s ticks" % " / ".join(out)


# --- De solo-referentie (MP-7 (a)) ------------------------------------------------

## De solo-lus van `test_kadewijk_lus.gd` bij D = 60 (dezelfde bot), alleen om de
## co-op-tijden mee te vergelijken (MP-7 (a), per kamer en over de lus).
func test_solo_lus_referentie_d60(t) -> void:
	var progress := Progress.new()
	progress.name = "TestProgress"
	t.tree.root.add_child(progress)
	var wijk = Scene.instantiate()
	wijk.tail = 60
	wijk.echo_on = true
	wijk.show_hud = false
	wijk.progress = progress
	wijk.start_at = Layout.ROOM_START[&"S1"]
	wijk.run_end = Kadewijk.RUN_END_LUS
	var bot := Bot.new(wijk, 60, &"S1")
	bot.lus = true
	bot.boss_input = func(sim: Node, boss: Node) -> RefCounted: return BossBot.new(sim, boss).p1_source
	wijk.input_override = bot
	t.tree.root.add_child(wijk)
	await t.tree.physics_frame
	while not wijk.run_over and wijk.sim.tick < RUN_LIMIT:
		await t.tree.physics_frame
	var rows: Array = wijk.meetlog.rows
	t.check(wijk.run_over and wijk.slice_end_tick > 0, "solo-lus D=60: SLICE_EIND niet gehaald")
	var per := {}
	var segs := _segments(rows)
	for k: String in segs:
		per[k] = int(_measure(rows, segs[k])["ticks"])
	_solo = {"run": wijk.run_ticks(), "per": per}
	_save_csv(wijk, "bot_lus_solo_D60.csv")
	t.note("solo-lus D=60 (referentie MP-7a): run %d ticks · per stuk %s" % [wijk.run_ticks(), per])
	await _free(t, [wijk, progress])


# --- De lus in co-op -----------------------------------------------------------------

func _lus(t, d: int) -> String:
	var name := "co-op lus D=%d" % d
	var out: Dictionary = await _coop(t, d, &"S1", Kadewijk.RUN_END_LUS, true)
	var wijk = out["wijk"]
	var duo = out["duo"]
	var rows: Array = out["rows"]
	t.check(wijk.start_errors.is_empty(), "start: %s" % [wijk.start_errors])
	t.check(wijk.run_over and wijk.slice_end_tick > 0 and wijk.room == &"S1",
		"%s: SLICE_EIND niet gehaald (tick %d, P1 %s/%s op %s, P2 %s/%s op %s, kamer %s)" % [
		name, wijk.sim.tick, duo.leg_name(1), duo.p1_input.sub, wijk.p1.position, duo.leg_name(2), duo.p2_input.sub,
		wijk.p2.position if wijk.p2 else Vector2.ZERO, wijk.room])
	t.check(wijk.p2 != null and _count(rows, "DROP_IN") == 1 and _count(rows, "DROP_OUT") == 0, "%s: P2 niet de hele run in het spel" % name)
	var at := {"boss_start": _first(rows, "BOSS_START"), "verslagen": _first(rows, "BOSS_VERSLAGEN"),
		"trap2": _first(rows, "TRAP_VOL", "2"), "water": _first(rows, "WATERSTAND", "2"), "eind": _first(rows, "SLICE_EIND")}
	t.check(at["verslagen"] > 0 and _count(rows, "BOSS_VERSLAGEN") == 1 and wijk.boss_spawns == 1,
		"%s: de boss niet in één poging verslagen (%s, %d keer neergezet)" % [name, at, wijk.boss_spawns])
	t.check(at["trap2"] > at["verslagen"] and at["water"] == at["trap2"] + Gemaal.DRAIN_TICKS and at["eind"] > at["water"],
		"%s: trap 2 / het water / SLICE_EIND niet in volgorde (%s)" % [name, at])
	var picked := {"lampglas": wijk.lampglas_tick, "neerslag": wijk.neerslag_tick, "blad": wijk.logblad_ticks}
	t.check(wijk.lampglas_tick > 0 and wijk.neerslag_tick > 0 and wijk.logblad_ticks.keys().size() == 3,
		"%s: niet alles opgepakt: %s" % [name, picked])
	t.check(_count(rows, "RESPAWN") == 0, "%s: %d respawns" % [name, _count(rows, "RESPAWN")])
	t.check(out["hits"].size() <= 4, "%s: %d treffers op P1 (≤ 4, zoals de solo-lus)" % [name, out["hits"].size()])
	t.check(wijk.most_at_once <= 5, "%s: %d vijanden tegelijk (L-13 f)" % [name, wijk.most_at_once])
	# Wat het duo moet doen: elk keerpunt en B4 met de ander (de samenwerkingsactie).
	var missed: Array = []
	for leg: String in Duo.SPRINGER:
		if not duo.lines.get(leg, false):
			missed.append(leg)
	t.check(missed.is_empty(), "%s: zonder de ander (langzame lijn of niet gedaan): %s" % [name, missed])
	t.check(_count(rows, "LANCERING", "", "p1") >= 1, "%s: geen lancering van P2 over P1 (B4)" % name)
	t.check(_count(rows, "POMP", "", "p2") >= 1, "%s: geen pompslag van P2" % name)
	# Normen over de lus en per kamer.
	var first_tick := int(rows[0][0])
	var last_tick := int(rows[rows.size() - 1][0]) + 1
	var all := _measure(rows, [[first_tick, last_tick]])
	var mp4 := float(all["dissolved"]) / maxf(float(all["ticks"]), 1.0)
	# MP-7 (b) van P2 over de lus zonder de boss (de boss: geen check, zie de kop).
	var fails := _norms(all, false, true, false)
	if at["boss_start"] >= 0 and at["verslagen"] >= 0:
		var buiten := _measure(rows, [[first_tick, at["boss_start"]], [at["verslagen"], last_tick]])
		if int(buiten["mp1_p2"]) > 300:
			fails.append("MP-7b P2 buiten de boss %d" % buiten["mp1_p2"])
	if mp4 > 0.40:
		fails.append("MP-4 %.0f %%" % (mp4 * 100.0))
	t.check(fails.is_empty(), "%s: de lus haalt niet: %s" % [name, "; ".join(fails)])
	var segs := _segments(rows)
	var per_room := PackedStringArray()
	for k in ["S1", "S2", "S3", "S4", "S5", "S6", "S7", "S8", "Boss", "S9"]:
		if not segs.has(k):
			t.check(false, "%s: geen stuk %s in het meetlog" % [name, k])
			continue
		var m := _measure(rows, segs[k])
		# De route van S8 (W38: vóór `BOSS_START` en na `BOSS_VERSLAGEN`) is de arena in en de
		# deur links uit, ± 3 s zonder bouwsteen: daar geen MP-2 en MP-7 (c) per minuut (ook solo
		# heeft S8 daar geen MP-2, testplan T11 §3; SL-03 meet die tijd). Wel MP-1, MP-7 (b) en (d).
		var f := _norms(m, true, k != "S8", k != "Boss")
		t.check(f.is_empty(), "%s: %s haalt niet: %s" % [name, k, "; ".join(f)])
		var solo_t: int = int(_solo.get("per", {}).get(k, 0)) if d == 60 else 0
		var extra := (" · " + _boss_p2(m)) if k == "Boss" else (" · " + _waits(duo, k))
		per_room.append("%s: %s%s%s" % [k, _fmt(m), (" · MP-7a %.2f× solo" % (float(m["ticks"]) / solo_t)) if solo_t > 0 else "", extra])
	var solo_run: int = int(_solo.get("run", 0)) if d == 60 else 0
	var rep = FlowReport.from_rows(rows, false)
	t.note("%s: run %d ticks (%.1f s) · %s · MP-3 %.0f %% van %d landingen zonder wachten · MP-4 %.1f %% · MP-7a %s · treffers P1 %d · stuits P2 %d (combo %d) · %s · %s · lijnen %s" % [
		name, wijk.run_ticks(), wijk.run_ticks() / 60.0, _fmt(all), rep.landings_without_still * 100.0, rep.landings, mp4 * 100.0,
		("%.2f× solo (%d/%d)" % [float(wijk.run_ticks()) / solo_run, wijk.run_ticks(), solo_run]) if solo_run > 0 else "— (solo-referentie alleen bij D = 60)",
		out["hits"].size(), all["stuit_p2"], duo.p2_stuit_combos, _boss_p2(_measure(rows, segs.get("Boss", [[0, 0]]))),
		_waits(duo), duo.lines])
	t.note("%s per kamer (W38) · %s" % [name, " | ".join(per_room)])
	_save_csv(wijk, "bot_lus_coop_D%d.csv" % d)
	var csv: String = wijk.meetlog.to_csv()
	await _free(t, out["parts"])
	return csv


func test_coop_lus_d60(t) -> void:
	_lus60_csv = await _lus(t, 60)


## Dezelfde run nog eens: hetzelfde meetlog (gdd §4.5: het log is deterministisch).
func test_coop_lus_d60_deterministisch(t) -> void:
	t.check(_lus60_csv != "", "geen eerste co-op-lus D=60")
	var again: String = await _lus(t, 60)
	t.check(again == _lus60_csv, "co-op-lus D=60 gaf de tweede keer een ander meetlog")


func test_coop_lus_d90(t) -> void:
	await _lus(t, 90)


func test_coop_lus_d120(t) -> void:
	await _lus(t, 120)


func test_coop_lus_d180(t) -> void:
	await _lus(t, 180)


# --- Per kamer, vanaf het begin van de kamer (LM-08) ----------------------------------

## Waar de run per kamer eindigt: de volgende kamer, in S8 `BOSS_VERSLAGEN`, in S9 `SLICE_EIND`.
const NEXT := {&"S1": &"S2", &"S2": &"S3", &"S3": &"S4", &"S4": &"S5", &"S5": &"S6",
	&"S6": &"S7", &"S7": &"S8", &"S8": Kadewijk.RUN_END_BOSS, &"S9": Kadewijk.RUN_END_LUS}


func _kamer(t, id: StringName) -> void:
	var name := "co-op %s los D=60" % id
	var setup := Callable()
	if id == &"S9":
		# `s = 2`: trap 2 is vol, de lage kade is vrij (zoals `test_kadewijk_s9.gd`).
		setup = func(wijk) -> void: wijk.set_door(&"S9", "Hoogwater", false)
	var out: Dictionary = await _coop(t, 60, id, NEXT[id], false, setup)
	var wijk = out["wijk"]
	var duo = out["duo"]
	var rows: Array = out["rows"]
	t.check(wijk.run_over, "%s: niet uit de kamer (tick %d, P1 %s/%s op %s, P2 %s/%s op %s)" % [
		name, wijk.sim.tick, duo.leg_name(1), duo.p1_input.sub, wijk.p1.position, duo.leg_name(2), duo.p2_input.sub,
		wijk.p2.position if wijk.p2 else Vector2.ZERO])
	t.check(_count(rows, "RESPAWN") == 0, "%s: P1 stierf" % name)
	var legs: Array = []
	for leg: String in Duo.SPRINGER:
		if leg.begins_with(String(id)):
			legs.append(leg)
			t.check(duo.lines.get(leg, false), "%s: %s niet met de ander" % [name, leg])
	var segs := _segments(rows)
	var keys: Array = ["Boss"] if id == &"S8" else [String(id)]
	for k: String in keys:
		var m := _measure(rows, segs.get(k, [[0, 0]]))
		var f := _norms(m, true, true, k != "Boss")
		t.check(f.is_empty(), "%s: %s haalt niet: %s" % [name, k, "; ".join(f)])
		var extra := _boss_p2(m) if k == "Boss" else _waits(duo, k)
		t.note("%s: %s · %s · %s · keerpunten %s" % [name, k, _fmt(m), extra, legs])
	_save_csv(wijk, "bot_kamer_coop_%s_D60.csv" % id)
	await _free(t, out["parts"])


func test_coop_per_kamer_s1_s4_d60(t) -> void:
	for id: StringName in [&"S1", &"S2", &"S3", &"S4"]:
		await _kamer(t, id)


func test_coop_per_kamer_s5_s7_d60(t) -> void:
	for id: StringName in [&"S5", &"S6", &"S7"]:
		await _kamer(t, id)


func test_coop_per_kamer_s8_d60(t) -> void:
	await _kamer(t, &"S8")


func test_coop_per_kamer_s9_d60(t) -> void:
	await _kamer(t, &"S9")
