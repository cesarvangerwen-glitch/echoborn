extends RefCounted
## De Kadewijk in co-op (T11 G-1, #88; testplan `docs/qa/testplan-t11-slice.md` §4 en §6):
## de gescripte geoefende co-op-run (`kadewijk_duo.gd`, P1 en P2 live, P2 in de rol
## van de schaduw, besluit #51 7A) per kamer S1–S9 en als lus S1 → S8 → de
## Gemaalmeester → S9 → trap 2 → S9 → S1 (`SLICE_EIND`), bij D = 60 en als regressie
## bij 90, 120 en 180.
##
## Wat een check is (gdd §4.5: de co-op-run bewijst dat de kamer de normen kán halen;
## testplan T11 §4, voorwaarde MT3): MP-1 van P1 én P2 ≤ 300, MP-2 ≥ 3,0 per minuut
## met een gat ≤ 2400 ticks, MP-4 ≤ 40 %, MP-6 ≥ 40 % met ≥ 1 pompslag van P2, SL-01
## ≥ 100 LP vóór de eerste pompslag (L-14 c, over de lus), en
## MP-7 (b)–(d), over de lus en per kamer (W38: per kamer = `KAMER` tot `KAMER`; de
## boss = `BOSS_START` … `BOSS_VERSLAGEN`, apart van de route van S8). MP-3 en MP-7 (a)
## (een mediaan over mensen) staan alleen in de uitvoer; MP-7 (a) tegen de solo-lus van
## dezelfde D uit dit script.
##
## MP-7 (b) van P2 **ook in de boss** (`BOSS_START` … `BOSS_VERSLAGEN`; B-14 (g),
## `slice-vijanden-en-boss.md` §6): een check in S8 los (D = 60) en in de lus bij 60, 90, 120 en
## 180, met de co-op-regel van fase 1 (GMB-14: de wissel) en de boss-bot van B-14 (`tests/boss_bot.gd`).
## **De boss in de Kadewijk-arena in co-op** (B-14 (6), GM-01): de boss start pas als beide spelers
## binnen de muren staan (deur rechts dan dicht); van `BOSS_START` tot `BOSS_VERSLAGEN` staat de
## camera vast op de arena met beide spelers in beeld en binnen de muren, en als tegencheck staat
## hij in S8 vóór `BOSS_START` en na `BOSS_VERSLAGEN` níet op de arena en volgt hij beide spelers;
## de co-op-regel geldt (`DOELHELFT` in fase 1); na `BOSS_VERSLAGEN` is de deur links open, en de
## lus loopt door naar S9. **De binnenkomst (GM-01) meet de lus**: daar lopen beide spelers vanuit
## S7 de arena in. In S8 los beginnen P1 en P2 op hetzelfde punt al binnen de muren (de boss start
## op tick 17), dus daar is de GM-01-check geen echte binnenkomst. Bij D = 60 ook de ontwerpcheck
## B-14 (f) in de echte arena: P2 zet in fase 1 merken vanaf beide helften (≥ 2 per helft) en heeft
## daar 0 JUMP-flanken.
## MP-7 (e) (gdd v0.8.6 §4.5, #292): het wachten per speler uit het meetlog (`WACHT_START` /
## `WACHT_EIND`, `meetlog.gd`: 120 ticks binnen 64 px zonder eigen actie), de langste
## wachtperiode en het aandeel van de speeltijd, over de lus, per kamer en in de boss (twee
## perioden die overlappen tellen als één). **Check** (langste ≤ 300 ticks en aandeel ≤ 5 % per
## speler, en P2 pompt mee) op trap 2 samen: van `BOSS_VERSLAGEN` tot P1 na trap 2 terug in S9
## is (#292; P2 minstens 3 van de 7 slagen). Over de hele lus buiten de boss haalt de duo-bot de
## norm (300 / 5 %) nog niet: hij wacht ook bij de keerpunten (de drager op de springer, die de
## langzame lijn van het vorige keerpunt nam) en bij de smalle plekken (de luiken, de schacht, de
## Dwaallichten): D = 60 ± 12 % per speler, bij D ≥ 120 ook langste > 300. Daar staat een
## **regressiegrens als check** (langste ≤ 400 ticks en aandeel ≤ 16 % per speler, besluit TD in
## PR #297); de norm volgt in #298 (GP: smalle plekken in de duo-bot) en #299 (LGD/WLD: keerpunten
## in co-op). Per kamer en in de boss is het een rapportwaarde.
## Ter vergelijking ook het wachten van de bot zelf (`wait_ticks`, ± 18 px, geen maat). Verder:
## de lus is rond, de boss verslagen (één poging), trap 2 en het water, alles opgepakt, geen
## respawn, en de run is deterministisch.
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
const Gemaalmeester = preload("res://scripts/combat/gemaalmeester.gd")
const InputBits = preload("res://scripts/input/input_bits.gd")

const RUN_LIMIT := 34000
## MP-7 (e) over de lus buiten de boss: regressiegrens per speler tot #298 en #299 (besluit TD,
## PR #297); de norm is 300 ticks / 5 %.
const WAIT_REGRESSIE_MAX := 400
const WAIT_REGRESSIE_SHARE := 0.16
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
	var arena := _watch_arena(wijk)
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
	return {"wijk": wijk, "progress": parts[1], "duo": duo, "rows": wijk.meetlog.rows, "hits": hits, "parts": parts,
		"arena": arena}


# --- De arena in co-op (B-14 (6), GM-01) ------------------------------------------------

func _door_closed(wijk, block_name: String) -> bool:
	var kamer = wijk.loader.kamers[&"S8"]
	if kamer.inhoud_node == null:
		return false
	var body := kamer.inhoud_node.get_node_or_null("Blokken/" + block_name) as StaticBody2D
	return body != null and body.collision_layer != 0


## Staat het lichaam helemaal tussen de muren van de arena?
func _in_arena(body: Node2D) -> bool:
	var x := body.position.x
	return x - Layout.HALF_W >= Layout.ARENA_WALL_L - 0.5 and x + Layout.HALF_W <= Layout.ARENA_WALL_R + 0.5


## Volgt de boss in de echte arena per tick: de binnenkomst (de tick van `BOSS_START`), de camera en
## beide spelers tijdens het gevecht, de merken en JUMP-flanken van P2 in fase 1 (B-14 (f)), en de
## deur links en de camera op de tick na `BOSS_VERSLAGEN`.
func _watch_arena(wijk) -> Dictionary:
	var a := {"boss": null, "start_tick": -1, "start": {}, "fight": 0, "cam_ok": 0, "cam_fout": 0,
		"buiten_beeld": 0, "buiten_arena": 0, "rond": 0, "rond_arena": 0, "rond_buiten_beeld": 0, "p2_weg": 0, "marks": {-1: 0, 1: 0}, "jumps": 0,
		"defeat_tick": -1, "after": {}, "coop": false}
	var prev := {"j": false}
	wijk.sim.combat.mark_set.connect(func(_tick: int, mark) -> void:
		if a["boss"] == null or not is_instance_valid(a["boss"]):
			return
		var boss: Gemaalmeester = a["boss"]
		if mark.setter == "p2" and mark.target == boss.ketel and boss.phase == Gemaalmeester.Phase.ONE \
				and boss.state == boss.State.FIGHT:
			a["marks"][boss.half_of(mark.set_at)] += 1)
	wijk.sim.tick_finished.connect(func(tick: int) -> void:
		if a["boss"] == null and wijk.boss != null:
			a["boss"] = wijk.boss
		if a["boss"] == null or not is_instance_valid(a["boss"]):
			return
		var boss: Gemaalmeester = a["boss"]
		var p2: Node2D = wijk.p2
		var p2_live: bool = p2 != null and is_instance_valid(p2) and not p2.dissolved
		if boss.is_defeated() or boss.state == boss.State.IDLE:
			if boss.is_defeated() and a["defeat_tick"] < 0:
				a["defeat_tick"] = tick
				a["after"] = {"deur_links_open": not _door_closed(wijk, "DeurLinks"), "arena_camera": wijk.is_arena_camera()}
			# Tegencheck (zoals `test_kadewijk_boss.gd`): rond het gevecht (S8 geladen, vóór
			# `BOSS_START` en na `BOSS_VERSLAGEN`) staat de camera níet op de arena en volgt hij beide spelers.
			a["rond"] += 1
			var free_view: Rect2 = wijk.camera_view()
			if wijk.is_arena_camera() or free_view == Kadewijk.arena_view():
				a["rond_arena"] += 1
			for body in [wijk.p1, p2 if p2_live else null]:
				if body != null and not free_view.has_point(body.position):
					a["rond_buiten_beeld"] += 1
			return
		if a["start_tick"] < 0:
			a["start_tick"] = tick
			a["coop"] = boss.is_coop()
			a["start"] = {"p1": wijk.p1.position, "p2": p2.position if p2 != null else Vector2.ZERO,
				"p1_binnen": _in_arena(wijk.p1), "p2_binnen": p2_live and _in_arena(p2),
				"deur_rechts_dicht": _door_closed(wijk, "DeurRechts"), "deur_links_dicht": _door_closed(wijk, "DeurLinks")}
		a["fight"] += 1
		var view: Rect2 = wijk.camera_view()
		if view == Kadewijk.arena_view():
			a["cam_ok"] += 1
		else:
			a["cam_fout"] += 1
		var bodies: Array = [wijk.p1]
		if p2_live:
			bodies.append(p2)
		else:
			a["p2_weg"] += 1
		for body: Node2D in bodies:
			if not view.has_point(body.position):
				a["buiten_beeld"] += 1
			if not _in_arena(body):
				a["buiten_arena"] += 1
		var down: bool = p2_live and p2.last_input & InputBits.JUMP != 0
		if down and not prev["j"] and boss.phase == Gemaalmeester.Phase.ONE and boss.state == boss.State.FIGHT:
			a["jumps"] += 1
		prev["j"] = down)
	return a


## De checks van B-14 (6) op de arena (en bij D = 60 B-14 (f)); geeft de note-tekst terug.
func _check_arena(t, name: String, out: Dictionary, d: int) -> String:
	var a: Dictionary = out["arena"]
	var rows: Array = out["rows"]
	var st: Dictionary = a["start"]
	t.check(a["start_tick"] >= 0 and a["coop"], "%s: geen BOSS_START in co-op (start %d, co-op %s)" % [name, a["start_tick"], a["coop"]])
	t.check(st.get("p1_binnen", false) and st.get("p2_binnen", false) and st.get("deur_rechts_dicht", false)
		and st.get("deur_links_dicht", false),
		"%s: binnenkomst (GM-01): bij BOSS_START %s" % [name, st])
	t.check(int(a["fight"]) > 0 and int(a["cam_fout"]) == 0 and int(a["cam_ok"]) == int(a["fight"]),
		"%s: arena-camera %d van %d ticks vast (%d fout)" % [name, a["cam_ok"], a["fight"], a["cam_fout"]])
	t.check(int(a["buiten_beeld"]) == 0 and int(a["buiten_arena"]) == 0 and int(a["p2_weg"]) == 0,
		"%s: in het gevecht %d keer een speler buiten beeld, %d buiten de arena, P2 %d ticks opgelost" % [
		name, a["buiten_beeld"], a["buiten_arena"], a["p2_weg"]])
	t.check(int(a["rond"]) > 0 and int(a["rond_arena"]) == 0 and int(a["rond_buiten_beeld"]) == 0,
		"%s: rond het gevecht (%d ticks in S8 vóór BOSS_START of na BOSS_VERSLAGEN) %d ticks de arena-camera, %d keer een speler buiten beeld" % [
		name, a["rond"], a["rond_arena"], a["rond_buiten_beeld"]])
	var b0 := _first(rows, "BOSS_START")
	var wissel := _first(rows, "BOSS_FASE", "wissel")
	var doel := 0
	for row in rows:
		if row[2] == "DOELHELFT" and int(row[0]) >= b0 and (wissel < 0 or int(row[0]) < wissel):
			doel += 1
	t.check(doel >= 2, "%s: %d keer DOELHELFT in fase 1 (de co-op-regel GMB-14 geldt niet in de arena?)" % [name, doel])
	var after: Dictionary = a["after"]
	t.check(a["defeat_tick"] >= 0 and after.get("deur_links_open", false) and not after.get("arena_camera", true),
		"%s: na BOSS_VERSLAGEN (tick %d): %s" % [name, a["defeat_tick"], after])
	var marks: Dictionary = a["marks"]
	if d == 60:
		t.check(int(marks[-1]) >= 2 and int(marks[1]) >= 2 and int(a["jumps"]) == 0,
			"%s: fase 1 merken van P2 links %d / rechts %d (≥ 2), JUMP-flanken P2 %d (0; B-14 (f))" % [
			name, marks[-1], marks[1], a["jumps"]])
	return "arena: BOSS_START tick %d (P1 %s, P2 %s), camera vast %d/%d ticks, rond het gevecht %d ticks vrij met beide spelers in beeld, DOELHELFT fase 1 %d×, merken P2 fase 1 L %d / R %d, JUMP P2 fase 1 %d" % [
		a["start_tick"], st.get("p1", Vector2.ZERO), st.get("p2", Vector2.ZERO), a["cam_ok"], a["fight"], a["rond"], doel, marks[-1], marks[1], a["jumps"]]


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


## SL-01 (L-14 c): LP gevuld van RUN_START tot de eerste pompslag (van P1 of P2), zoals
## `_lp_before_pump` in `test_kadewijk_deel2.gd` (solo: 112 bij D = 60).
func _lp_before_pump(rows: Array) -> int:
	var n := 0
	for row in rows:
		if row[2] == "POMP":
			return n
		if row[2] == "LP":
			n += int(str(row[3]).trim_prefix("+"))
	return n


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
	# MP-7 (e): de wachtperioden [begin, begin + lengte) per speler, geknipt op de stukken.
	var waits := {"p1": [], "p2": []}
	var wait_from := {}
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
		if event == "WACHT_START":
			wait_from[row[4]] = int(row[3])
		elif event == "WACHT_EIND" and wait_from.has(row[4]):
			var w0: int = wait_from[row[4]]
			waits[row[4]].append([w0, w0 + int(row[3])])
			wait_from.erase(row[4])
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
	for who: String in ["p1", "p2"]:
		# Twee perioden kunnen overlappen (de tweede begint 120 ticks vóór zijn eerste wachtende
		# tick): samen één periode, de vereniging.
		var merged: Array = []
		for w: Array in waits[who]:
			if not merged.is_empty() and int(w[0]) <= int(merged[-1][1]):
				merged[-1][1] = maxi(int(merged[-1][1]), int(w[1]))
			else:
				merged.append([int(w[0]), int(w[1])])
		var longest := 0
		var total := 0
		var count := 0
		for w: Array in merged:
			var hit := false
			for seg: Array in segments:
				var n := mini(int(w[1]), int(seg[1])) - maxi(int(w[0]), int(seg[0]))
				if n > 0:
					longest = maxi(longest, n)
					total += n
					hit = true
			if hit:
				count += 1
		m["wacht_max_" + who] = longest
		m["wacht_sum_" + who] = total
		m["wacht_n_" + who] = count
		m["mp7e_" + who] = float(total) / maxf(float(ticks), 1.0)
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
		"→ MP-7c %.2f/min per speler · MP-7d %.1f %% · MP-6 %.0f %% van %d LP · pomp P1 %d / P2 %d · %s") % [
		m["ticks"], m["ticks"] / 60.0, m["mp1_p1"], m["mp1_p2"], m["mp2"], m["gap"], m["coop"], m["bounce"], m["lancering"],
		m["vangen"], m["combos"], m["mp7c"], m["mp7d"] * 100.0, m["mp6"] * 100.0, m["lp"], m["pomp_p1"], m["pomp_p2"], _fmt_wait(m)]


## MP-7 (e) per speler: langste wachtperiode, aandeel van de ticks van het stuk, aantal perioden.
func _fmt_wait(m: Dictionary) -> String:
	return "MP-7e wachten P1 langste %d, %.1f %% (%d×) / P2 langste %d, %.1f %% (%d×)" % [
		m["wacht_max_p1"], m["mp7e_p1"] * 100.0, m["wacht_n_p1"], m["wacht_max_p2"], m["mp7e_p2"] * 100.0, m["wacht_n_p2"]]


## MP-7 (e), de norm (gdd §4.5): langste wachtperiode ≤ 300 ticks en aandeel ≤ 5 % per speler.
## `longest`/`share`: een andere grens (de regressiegrens over de lus buiten de boss).
func _wait_norms(m: Dictionary, longest := 300, share := 0.05) -> PackedStringArray:
	var out := PackedStringArray()
	for who: String in ["p1", "p2"]:
		if int(m["wacht_max_" + who]) > longest:
			out.append("MP-7e %s langste wachtperiode %d" % [who.to_upper(), m["wacht_max_" + who]])
		if float(m["mp7e_" + who]) > share:
			out.append("MP-7e %s wacht %.1f %%" % [who.to_upper(), float(m["mp7e_" + who]) * 100.0])
	return out


## Normen van de co-op-run (gdd §4.5, testplan T11 §2.1, §4): leeg = gehaald. `per_room`:
## dan geen MP-6 (een kamer zonder LP-bron is geen fout) en geen pompslag. `rates` = false:
## zonder MP-2 en MP-7 (c) (de route van S8, zie `_lus`). MP-7 (b) van P2 overal, ook in de boss
## (B-14 (g)).
func _norms(m: Dictionary, per_room: bool, rates := true) -> PackedStringArray:
	var out := PackedStringArray()
	if int(m["mp1_p1"]) > 300: out.append("MP-1 P1 %d" % m["mp1_p1"])
	if int(m["mp1_p2"]) > 300: out.append("MP-7b P2 %d" % m["mp1_p2"])
	if rates and float(m["mp2"]) < 3.0: out.append("MP-2 %.2f/min" % m["mp2"])
	if int(m["gap"]) > 2400: out.append("MP-2 gat %d" % m["gap"])
	if rates and float(m["mp7c"]) < 1.0: out.append("MP-7c %.2f/min" % m["mp7c"])
	if float(m["mp7d"]) > 0.10: out.append("MP-7d %.0f %%" % (float(m["mp7d"]) * 100.0))
	if not per_room:
		if float(m["mp6"]) < 0.40: out.append("MP-6 %.0f %%" % (float(m["mp6"]) * 100.0))
		if int(m["pomp_p2"]) < 1: out.append("MP-6 geen pompslag van P2")
	return out


## MP-7 (b) van P2 in de boss (check ≤ 300, B-14 (g)), met P1 ernaast.
func _boss_p2(m: Dictionary) -> String:
	return "MP-7b in de boss P2 %d / P1 %d (check ≤ 300)" % [int(m["mp1_p2"]), int(m["mp1_p1"])]


## Wachten op de ander volgens de bot zelf (`Seat.wait_ticks`, ± 18 px; geen maat, MP-7 (e)
## staat in `_fmt`): per kamer van die speler, en totaal.
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
	return "bot wacht op de ander (wait_ticks) %s ticks" % " / ".join(out)


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
	var sl01 := _lp_before_pump(rows)
	t.check(sl01 >= 100, "%s: %d LP vóór de eerste pompslag (SL-01: ≥ 100)" % [name, sl01])
	# Normen over de lus en per kamer.
	var first_tick := int(rows[0][0])
	var last_tick := int(rows[rows.size() - 1][0]) + 1
	var all := _measure(rows, [[first_tick, last_tick]])
	var mp4 := float(all["dissolved"]) / maxf(float(all["ticks"]), 1.0)
	# MP-7 (b) van P2 over de hele lus, de boss inbegrepen (B-14 (g)).
	var fails := _norms(all, false)
	var mp7e_buiten := ""
	t.check(_count(rows, "WACHT_START") == _count(rows, "WACHT_EIND"), "%s: WACHT_START en WACHT_EIND niet in paren" % name)
	if at["boss_start"] >= 0 and at["verslagen"] >= 0:
		var buiten := _measure(rows, [[first_tick, at["boss_start"]], [at["verslagen"], last_tick]])
		# MP-7 (e) over de lus buiten de boss: check op de regressiegrens (400 / 16 %), de norm
		# (300 / 5 %) volgt in #298 en #299, zie de kop; de boss: rapport.
		fails.append_array(_wait_norms(buiten, WAIT_REGRESSIE_MAX, WAIT_REGRESSIE_SHARE))
		var open_e := _wait_norms(buiten)
		mp7e_buiten = "%s → %s" % [_fmt_wait(buiten), "gehaald" if open_e.is_empty() else "niet gehaald (%s), grens 300 / 5 %% volgt in #298 en #299" % "; ".join(open_e)]
	else:
		fails.append("geen BOSS_START … BOSS_VERSLAGEN: MP-7e buiten de boss niet te meten")
	# MP-7 (e), de check van #292: trap 2 samen, van `BOSS_VERSLAGEN` tot P1 terug in S9 is
	# (de trap op, trap 2, de trap af). Daar wachtte P2 ± 1556 ticks onderaan de trap.
	var trap_from: int = at["verslagen"]
	var trap_to := -1
	for row in rows:
		if row[2] == "KAMER" and row[4] == "S9" and int(row[0]) > at["trap2"] and at["trap2"] > 0:
			trap_to = int(row[0])
			break
	var trap_e := ""
	if trap_from > 0 and trap_to > trap_from:
		var tm := _measure(rows, [[trap_from, trap_to]])
		var tf := _wait_norms(tm)
		t.check(tf.is_empty(), "%s: trap 2 samen (MP-7e, %d … %d) haalt niet: %s" % [name, trap_from, trap_to, "; ".join(tf)])
		t.check(int(tm["pomp_p2"]) >= 3, "%s: P2 pompt trap 2 niet mee (%d slagen, ≥ 3)" % [name, tm["pomp_p2"]])
		trap_e = "%d ticks, pomp P1 %d / P2 %d · %s" % [tm["ticks"], tm["pomp_p1"], tm["pomp_p2"], _fmt_wait(tm)]
	else:
		t.check(false, "%s: geen stuk BOSS_VERSLAGEN … terug in S9 na trap 2 (%s, %d)" % [name, at, trap_to])
	if mp4 > 0.40:
		fails.append("MP-4 %.0f %%" % (mp4 * 100.0))
	t.check(fails.is_empty(), "%s: de lus haalt niet: %s" % [name, "; ".join(fails)])
	var arena_note := _check_arena(t, name, out, d)
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
		var f := _norms(m, true, k != "S8")
		t.check(f.is_empty(), "%s: %s haalt niet: %s" % [name, k, "; ".join(f)])
		var solo_t: int = int(_solo.get("per", {}).get(k, 0)) if d == 60 else 0
		var extra := (" · " + _boss_p2(m)) if k == "Boss" else (" · " + _waits(duo, k))
		per_room.append("%s: %s%s%s" % [k, _fmt(m), (" · MP-7a %.2f× solo" % (float(m["ticks"]) / solo_t)) if solo_t > 0 else "", extra])
	var solo_run: int = int(_solo.get("run", 0)) if d == 60 else 0
	var rep = FlowReport.from_rows(rows, false)
	t.note("%s: MP-7e trap 2 samen (BOSS_VERSLAGEN … terug in S9; check: langste ≤ 300, ≤ 5 %%) %s" % [name, trap_e])
	t.note("%s: MP-7e buiten de boss (check: langste ≤ %d, ≤ %d %%; norm 300 / 5 %%) %s" % [name, WAIT_REGRESSIE_MAX, int(WAIT_REGRESSIE_SHARE * 100.0), mp7e_buiten])
	t.note("%s: run %d ticks (%.1f s) · %s · MP-3 %.0f %% van %d landingen zonder wachten · MP-4 %.1f %% · SL-01 %d LP vóór de eerste pompslag · MP-7a %s · treffers P1 %d · stuits P2 %d (combo %d) · %s · %s · lijnen %s" % [
		name, wijk.run_ticks(), wijk.run_ticks() / 60.0, _fmt(all), rep.landings_without_still * 100.0, rep.landings, mp4 * 100.0, sl01,
		("%.2f× solo (%d/%d)" % [float(wijk.run_ticks()) / solo_run, wijk.run_ticks(), solo_run]) if solo_run > 0 else "— (solo-referentie alleen bij D = 60)",
		out["hits"].size(), all["stuit_p2"], duo.p2_stuit_combos, _boss_p2(_measure(rows, segs.get("Boss", [[0, 0]]))),
		_waits(duo), duo.lines])
	t.note("%s per kamer (W38) · %s" % [name, " | ".join(per_room)])
	t.note("%s: %s" % [name, arena_note])
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
		var f := _norms(m, true)
		t.check(f.is_empty(), "%s: %s haalt niet: %s" % [name, k, "; ".join(f)])
		var extra := _boss_p2(m) if k == "Boss" else _waits(duo, k)
		t.note("%s: %s · %s · %s · keerpunten %s" % [name, k, _fmt(m), extra, legs])
	if id == &"S8":
		t.note("%s: %s" % [name, _check_arena(t, name, out, 60)])
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
