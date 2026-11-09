extends RefCounted
## Flow-test T17 (#80), deel 1: de scripted runs van de QA Lead in de grijze
## flow-kamer, solo en co-op, per staart D = 90 / 120 / 180 (1,5 / 2 / 3 s).
## Plan en rapport: `docs/qa/testplan-f0.md`, `docs/qa/rapport-f0-flowtest.md`.
##
## Deze tests **meten**; ze toetsen de normen niet. Een norm die niet
## gehaald wordt is een bevinding in het rapport, geen rode CI. Ze checken
## alleen dat elke run eindigt (`RUN_EIND`), dat de meting compleet is en dat
## de co-op-run deterministisch is. De meetwaarden staan als `note` in de
## uitvoer (`T17 ...`-regels); het rapport neemt ze daaruit over.
##
## Runs:
## - **solo**: de geoefende bot van de WLD (`flow_bot.gd`), echo aan.
## - **co-op schaduwpartner**: P1 = dezelfde bot; P2 doet na drop-in exact de
##   knoppen van P1 van D ticks eerder, dus loopt de route van de echo, tot
##   hij dat spoor kwijt is; daarna loopt hij mee. Werkaanname QA (T17): een
##   ondergrens, geen geoefend duo; er is nog geen gescripte co-op-run van de
##   WLD (gdd §4.5).
## - **co-op meeloper**: P2 loopt alleen achter P1 aan (zoals C-15 (2) in
##   `test_coop_deel2.gd`). Ondergrens: een partner die niets samen doet.
##
## Geen spelcode gewijzigd: de bot krijgt in co-op een proxy van de kamer
## waarin P2 de rol van de echo heeft (`_CoopView`).

const FlowRoom = preload("res://levels/flowkamer/flow_room.gd")
const FlowBot = preload("res://levels/flowkamer/flow_bot.gd")
const FlowReport = preload("res://levels/flowkamer/flow_report.gd")
const InputBits = preload("res://scripts/input/input_bits.gd")
const Motor = preload("res://scripts/echo/motor.gd")

const TICK_CAP := 7000
const MINUTE := 3600.0
## Samenwerkingsacties (§2.7) als LP-bron (LM-02).
const COOP_LP := ["springplank", "bounce", "vang", "lancering", "ontploffing"]

## Runtijd solo per D, voor MP-7 (a).
static var _solo_ticks := {}
## Meetlog-CSV van de schaduwpartner-run D = 120, voor de determinismetest.
static var _coop120_csv := ""


# --- Inputbronnen en proxy ---------------------------------------------------

## Inputbron van P1: de bot, en bewaart de bits per tick voor de partner.
class _P1Input:
	extends RefCounted
	var bot
	var history := {}
	var before: Callable
	var stopped := false

	func sample(tick: int) -> int:
		if stopped:
			return 0
		if before.is_valid():
			before.call()
		var bits: int = bot.sample(tick)
		history[tick] = bits
		return bits


## P2 als schaduwpartner: de knoppen van P1 van `delay` ticks eerder, zolang
## P2 op het spoor van P1 blijft (≤ 24 px van waar P1 `delay` ticks eerder
## stond). Raakt hij het spoor kwijt (een fysiek lichaam heeft, anders dan de
## echo, zelf een plank nodig om omhoog te komen), dan loopt hij verder als
## meeloper. Werkaanname QA (T17).
class _ShadowPartner:
	extends RefCounted
	var p1_input
	var delay := 0
	var room: Node
	var trail := {}
	var on_track := true
	var lost_at := -1
	var follower

	func sample(tick: int) -> int:
		var p2: Node2D = room.p2
		if on_track and p2 != null and trail.has(tick - delay):
			if p2.position.distance_to(trail[tick - delay]) > 24.0:
				on_track = false
				lost_at = tick
		if not on_track:
			return follower.sample(tick)
		return int(p1_input.history.get(tick - delay, 0))


## P2 als meeloper: 40 px achter P1, springt en slaat nooit.
class _Follower:
	extends RefCounted
	var room: Node

	func sample(_tick: int) -> int:
		var p1: Node2D = room.p1
		var p2: Node2D = room.p2
		if p2 == null:
			return 0
		var dx: float = (p1.position.x - 40.0 * float(p1.motor.facing)) - p2.position.x
		if absf(dx) < 6.0:
			return 0
		return InputBits.RIGHT if dx > 0 else InputBits.LEFT


## Wat de bot van de echo leest, maar dan van P2.
class _EchoOfP2:
	extends Node2D
	var p2: Node2D
	var in_merksprong := false

	var view: Node

	func is_present() -> bool:
		return p2 != null and is_instance_valid(p2) and not p2.dissolved and view._tracking()


## Het gemaal zoals de bot het leest: slagen van P2 tellen als slagen van "de echo".
class _GemaalView:
	extends RefCounted
	var g

	var fill: int:
		get: return g.fill
	var full_tick: int:
		get: return g.full_tick
	var strokes: Dictionary:
		get: return {"echo": int(g.strokes.get("p2", 0)), "p1": int(g.strokes.get("p1", 0))}

	func in_deep_water(at: Vector2, tick: int) -> bool:
		return g.in_deep_water(at, tick)


## De kamer zoals de bot hem leest; na drop-in is P2 "de echo".
class _CoopView:
	extends Node
	var r: Node
	var echo_view: _EchoOfP2
	var gemaal_view: _GemaalView
	## De partner; de bot ziet hem als echo zolang hij op het spoor is.
	var partner

	func _tracking() -> bool:
		return r.p2 == null or (partner != null and partner.get("on_track") == true)

	var p1:
		get: return r.p1
	var echo:
		get:
			if r.p2 != null:
				return echo_view
			return r.echo
	var echo_on: bool:
		get: return _tracking()
	var enemies:
		get: return r.enemies
	var gemaal:
		get: return gemaal_view if r.p2 != null else r.gemaal
	var meter:
		get: return r.meter
	var room: String:
		get: return r.room
	var run_over: bool:
		get: return r.run_over
	var sim:
		get: return r.sim
	var wave: int:
		get: return r.wave

	func sync() -> void:
		if r.p2 != null and is_instance_valid(r.p2):
			echo_view.p2 = r.p2
			echo_view.position = r.p2.position


# --- MP-1 voor P2 (MP-7 b) -----------------------------------------------------

## Stilstand van P2 volgens MP-1 (gdd §4.5), op zijn middelpunt. Werkaanname QA:
## ticks dat P2 opgelost is tellen niet mee en na P2_TERUG volgt, net als na een
## respawn, 60 ticks die niet meetellen. Het meetlog doet MP-1 alleen voor P1.
class _StillP2:
	extends RefCounted
	var room: Node
	var positions: Array[Vector2] = []
	var last_move := -1_000_000
	var grace_until := 0
	var since := -1
	var longest := 0
	var dissolved_ticks := 0
	var present_ticks := 0
	var was_dissolved := false

	func on_tick(tick: int) -> void:
		var p2 = room.p2
		if p2 == null or not is_instance_valid(p2) or room.run_over:
			return
		present_ticks += 1
		if p2.dissolved:
			dissolved_ticks += 1
			was_dissolved = true
			_close(tick)
			positions.clear()
			return
		if was_dissolved:
			was_dissolved = false
			grace_until = tick + 60
		if p2.move_events & (Motor.EV_JUMP | Motor.EV_DASH):
			last_move = tick
		positions.append(p2.position)
		if positions.size() > 31:
			positions.pop_front()
		var still: bool = tick >= grace_until and positions.size() == 31 and tick - last_move >= 30
		if still:
			for at in positions:
				if at.distance_to(positions[0]) > 24.0:
					still = false
					break
		if still and since < 0:
			since = tick
		elif not still:
			_close(tick)

	func _close(tick: int) -> void:
		if since >= 0:
			longest = maxi(longest, tick - since)
			since = -1


# --- Runs ----------------------------------------------------------------------

func _make_room(t, d: int, echo_on: bool, input: RefCounted) -> Node:
	var room = FlowRoom.new()
	room.tail = d
	room.echo_on = echo_on
	room.autosave = false
	room.show_hud = false
	room.input_override = input
	t.tree.root.add_child(room)
	return room


## Welke bouwsteen van de bot loopt er (voor vraag 4: waar de landingen zijn).
func _leg_name(bot) -> String:
	var legs: Array = bot._legs
	return str(legs[mini(bot.leg, legs.size() - 1)][0])


## Draait tot RUN_EIND of TICK_CAP; houdt per bouwsteen de springplank-landingen bij.
func _run(t, room, bot, still_p2 = null, trail = null) -> Dictionary:
	var per_leg := {}
	var seen := 0
	while not room.run_over and room.sim.tick < TICK_CAP:
		await t.tree.physics_frame
		if trail != null:
			trail[room.sim.tick] = room.p1.position
		if still_p2 != null:
			still_p2.on_tick(room.sim.tick)
		var rows: Array = room.meetlog.rows
		while seen < rows.size():
			var row: PackedStringArray = rows[seen]
			if row[2] in ["SPRINGPLANK", "VANGEN"]:
				var key := _leg_name(bot)
				per_leg[key] = int(per_leg.get(key, 0)) + 1
			seen += 1
	return per_leg


func _count(room, event: String, source: String = "") -> int:
	var n := 0
	for row in room.meetlog.rows:
		if row[2] == event and (source == "" or row[4] == source):
			n += 1
	return n


func _per_min(n: int, ticks: int) -> float:
	return n * MINUTE / maxf(float(ticks), 1.0)


## Gemeenschappelijke regels: MP-1–MP-4 uit FlowReport, plus acties (vraag 8).
func _common(rep: FlowReport, room, per_leg: Dictionary) -> String:
	var ticks: int = rep.duration
	return ("tijd %d ticks (%.1f s) · MP-1 P1 %d · MP-2 %.2f/min (K1 %.2f, K2 %.2f), gat %d · " +
		"MP-3 %.2f landingen/min, %.0f %% zonder stilstand · bounce %.2f/min, merk-combo %.2f/min, " +
		"lancering %d, vang %d · landingen per bouwsteen %s") % [
		ticks, ticks / 60.0, rep.longest_still, rep.actions_per_min,
		rep.actions_per_min_room.get("K1", 0.0), rep.actions_per_min_room.get("K2", 0.0), rep.longest_gap,
		rep.landings_per_min, rep.landings_without_still * 100.0,
		_per_min(_count(room, "BOUNCE"), ticks), _per_min(_count(room, "ONTPLOFFING", "") - _chain_links(room), ticks),
		_count(room, "LANCERING"), _count(room, "VANGEN"), str(per_leg)]


## Ontploffingen die niet de eerste schakel zijn (een ketting = één merk-combo).
func _chain_links(room) -> int:
	var n := 0
	for row in room.meetlog.rows:
		if row[2] == "ONTPLOFFING" and row[3] != "1":
			n += 1
	return n


func _solo(t, d: int) -> void:
	var input := _P1Input.new()
	var room := _make_room(t, d, true, input)
	input.bot = FlowBot.new(room)
	var per_leg := await _run(t, room, input.bot)
	if not room.meetlog.is_closed():
		room.meetlog.finish()
	var rep: FlowReport = FlowReport.from_rows(room.meetlog.rows)
	t.check(room.run_over, "solo D=%d: geen RUN_EIND binnen %d ticks" % [d, TICK_CAP])
	t.check(rep.landings > 0 and rep.lp_total > 0, "solo D=%d: meting leeg" % d)
	_solo_ticks[d] = room.run_ticks()
	t.note("T17 solo D=%d · %s · MP-4 Leeg %.1f %% · MP-6 echo %.0f %% van %d LP, %d echo-pompslagen · breuken %d · normen: %s" % [
		d, _common(rep, room, per_leg), rep.echo_empty_share * 100.0, rep.lp_echo_share * 100.0,
		rep.lp_total, rep.echo_pumps, rep.breaks, _verdict(rep.failures())])
	room.queue_free()
	await t.tree.process_frame


func _verdict(fails: PackedStringArray) -> String:
	return "gehaald" if fails.is_empty() else "NIET: " + "; ".join(fails)


## Co-op. `mode` = "schaduw" of "meeloper". P2 komt erin zodra de echo er is
## (tick ± D): dan neemt P2 de plek van de echo over (C-01).
func _coop(t, d: int, mode: String) -> String:
	var input := _P1Input.new()
	var room := _make_room(t, d, true, input)
	var view := _CoopView.new()
	view.r = room
	view.echo_view = _EchoOfP2.new()
	view.echo_view.view = view
	view.gemaal_view = _GemaalView.new()
	view.gemaal_view.g = room.gemaal
	input.bot = FlowBot.new(view)
	input.before = view.sync
	var still := _StillP2.new()
	still.room = room
	var joined_at := -1
	var trail := {}
	while joined_at < 0 and room.sim.tick < 400:
		await t.tree.physics_frame
		trail[room.sim.tick] = room.p1.position
		if room.echo != null and room.echo.is_present():
			var partner: RefCounted
			var follower := _Follower.new()
			follower.room = room
			if mode == "schaduw":
				partner = _ShadowPartner.new()
				partner.p1_input = input
				partner.delay = d
				partner.room = room
				partner.follower = follower
				partner.trail = trail
			else:
				partner = follower
			view.partner = partner
			t.check(room.join_partner(partner), "co-op D=%d: drop-in mislukt" % d)
			joined_at = room.sim.tick
	var per_leg := await _run(t, room, input.bot, still, trail)
	if not room.meetlog.is_closed():
		room.meetlog.finish()  # run niet af: tot hier meten
	var rows: Array = room.meetlog.rows
	var rep: FlowReport = FlowReport.from_rows(rows)
	var ticks: int = rep.duration
	t.check(room.run_over, "co-op %s D=%d: geen RUN_EIND binnen %d ticks (bot op %s/%s, kamer %s)" % [
		mode, d, TICK_CAP, input.bot.leg, input.bot.sub, room.room])
	t.check(joined_at > 0 and room.coop_seen, "co-op %s D=%d: P2 niet in het spel" % [mode, d])
	# MP-6 co-op: LP uit bronnen met P2 of met een samenwerkingsactie; pompslagen van P2.
	var lp_coop := 0
	for row in rows:
		if row[2] != "LP":
			continue
		var parts: PackedStringArray = str(row[4]).rsplit("_", true, 1)
		if parts[parts.size() - 1] == "p2" or parts[0] in COOP_LP:
			lp_coop += int(str(row[3]).trim_prefix("+"))
	var pumps_p2 := _count(room, "POMP", "p2")
	# MP-7 (c): acties per speler als springer (meetlog: bron = drager).
	var as_springer_p1 := 0
	var as_springer_p2 := 0
	for row in rows:
		if row[2] in ["SPRINGPLANK", "LANCERING", "VANGEN"]:
			if row[4] == "p2":
				as_springer_p1 += 1
			elif row[4] == "p1":
				as_springer_p2 += 1
	var combos: int = _count(room, "ONTPLOFFING") - _chain_links(room)
	# Elke springplank/lancering/vang heeft één drager en één springer: hij telt voor allebei.
	var per_player := as_springer_p1 + as_springer_p2 + combos
	# MP-7 (a) vraagt de solo-run van dezelfde D (een eerdere test in dit script).
	var solo: int = _solo_ticks.get(d, 0)
	t.check(solo > 0, "co-op %s D=%d: geen solo-run om MP-7 (a) mee te vergelijken" % [mode, d])
	var ratio := float(room.run_ticks()) / float(solo) if solo > 0 else NAN
	# MP-4 co-op (werkaanname QA): tijd zonder tweede lichaam = echo Leeg vóór
	# drop-in + P2 opgelost.
	var empty_before := joined_at - rep.start
	var no_body := float(empty_before + still.dissolved_ticks) / maxf(float(ticks), 1.0)
	var dissolved_share := float(still.dissolved_ticks) / maxf(float(still.present_ticks), 1.0)
	var fails := PackedStringArray()
	if rep.longest_still > 300: fails.append("MP-1 P1 %d" % rep.longest_still)
	if rep.actions_per_min < 3.0: fails.append("MP-2 %.2f/min" % rep.actions_per_min)
	for k in ["K1", "K2"]:
		if float(rep.actions_per_min_room.get(k, 0.0)) < 3.0:
			fails.append("MP-2 %s %.2f/min" % [k, rep.actions_per_min_room.get(k, 0.0)])
	if rep.longest_gap > 2400: fails.append("MP-2 gat %d" % rep.longest_gap)
	if rep.landings > 0 and rep.landings_without_still < 0.75: fails.append("MP-3 %.0f %%" % (rep.landings_without_still * 100.0))
	if no_body > 0.40: fails.append("MP-4 %.0f %%" % (no_body * 100.0))
	if rep.lp_total <= 0 or float(lp_coop) / rep.lp_total < 0.40: fails.append("MP-6 %d/%d LP" % [lp_coop, rep.lp_total])
	if pumps_p2 < 1: fails.append("MP-6 geen pompslag P2")
	if is_nan(ratio) or ratio < 0.5: fails.append("MP-7a %.2f×" % ratio)
	if still.longest > 300: fails.append("MP-7b P2 %d" % still.longest)
	if _per_min(per_player, ticks) < 1.0: fails.append("MP-7c %.2f/min" % _per_min(per_player, ticks))
	if dissolved_share > 0.10: fails.append("MP-7d %.0f %%" % (dissolved_share * 100.0))
	var lost := "n.v.t."
	if view.partner != null and view.partner.get("lost_at") != null:
		lost = str(view.partner.lost_at) if view.partner.lost_at >= 0 else "nooit"
	t.note(("T17 co-op %s D=%d · drop-in tick %d · spoor kwijt op tick %s · %s · MP-4 zonder tweede lichaam %.1f %% · " +
		"MP-6 co-op %.0f %% van %d LP, %d pompslagen P2 · MP-7a %.2f× solo (%d/%d) · MP-7b P2 %d · " +
		"MP-7c springer P1 %d, P2 %d, merk-combo %d → %.2f/min per speler · MP-7d P2 opgelost %.1f %% (%d×) · normen: %s") % [
		mode, d, joined_at, lost, _common(rep, room, per_leg), no_body * 100.0,
		float(lp_coop) / maxf(float(rep.lp_total), 1.0) * 100.0, rep.lp_total, pumps_p2,
		ratio, room.run_ticks(), _solo_ticks.get(d, 0), still.longest,
		as_springer_p1, as_springer_p2, combos, _per_min(per_player, ticks),
		dissolved_share * 100.0, _count(room, "P2_OPGELOST"),
		"gehaald" if fails.is_empty() else "NIET: " + "; ".join(fails)])
	var csv: String = room.meetlog.to_csv()
	input.stopped = true
	room.queue_free()
	await t.tree.process_frame
	await t.tree.physics_frame
	view.echo_view.free()
	view.free()
	return csv


# --- Tests (één run per test: de runner geeft 7200 frames) ---------------------

func test_t17_solo_d90(t) -> void:
	await _solo(t, 90)


func test_t17_solo_d120(t) -> void:
	await _solo(t, 120)


func test_t17_solo_d180(t) -> void:
	await _solo(t, 180)


func test_t17_coop_shadow_d90(t) -> void:
	await _coop(t, 90, "schaduw")


func test_t17_coop_shadow_d120(t) -> void:
	_coop120_csv = await _coop(t, 120, "schaduw")


func test_t17_coop_shadow_d180(t) -> void:
	await _coop(t, 180, "schaduw")


## Dezelfde run nog eens: hetzelfde meetlog (de meting is herhaalbaar).
func test_t17_coop_shadow_d120_deterministic(t) -> void:
	t.check(_coop120_csv != "", "geen eerste co-op-run D=120")
	var again: String = await _coop(t, 120, "schaduw")
	t.check(again == _coop120_csv, "co-op-run D=120 gaf de tweede keer een ander meetlog")


func test_t17_coop_follower_d90(t) -> void:
	await _coop(t, 90, "meeloper")


func test_t17_coop_follower_d120(t) -> void:
	await _coop(t, 120, "meeloper")


func test_t17_coop_follower_d180(t) -> void:
	await _coop(t, 180, "meeloper")
