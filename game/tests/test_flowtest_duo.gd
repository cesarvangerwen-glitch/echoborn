extends RefCounted
## Flow-test T17 (#80), co-op: de gescripte geoefende co-op-run van de WLD
## (`flow_duo.gd`, gdd §4.5; #125) per staart D = 90 / 120 / 180.
##
## P1 en P2 zijn allebei een inputbron van het duo: lancering in B4 (P2 vliegt
## over P1), bounce in beide richtingen in B3, B1 en B2, merk-combo's in K2 en
## pompslagen van beide spelers in K3. De metingen gebruiken de MP-7-code van
## `test_flowtest_t17.gd` (`_StillP2`, `_count`, `_chain_links`, `_per_min`)
## met dezelfde werkaannames W4–W6 (`docs/qa/testplan-f0.md` §6). MP-7 (a)
## vergelijkt met de solo-run van dezelfde D uit dat script (draait eerder).
##
## Zoals T17 zetten deze tests alle meetwaarden als `note` in de uitvoer
## (`T17 co-op duo ...`-regels). Anders dan de ondergrenzen van T17 is dit de
## run die volgens gdd §4.5 bewijst dat de kamer de normen in co-op kán halen
## (zoals `test_flowkamer.gd` voor solo): MP-1, MP-2, MP-4, MP-6 en MP-7 (b)–(d)
## zijn dus checks; MP-3 en MP-7 (a) alleen meetwaarden. Verder checken ze dat
## het duo doet wat het moet (lancering in B4, bounce door P1 én door P2, een
## merk-combo in K2, pompslagen van P2), dat de run eindigt en dat hij
## deterministisch is.
##
## P2 doet mee vóór de eerste tick (drop-in, echo nog Leeg: P2 verschijnt bij
## P1, C-03): een duo begint samen. Werkaanname WLD (#125).

const FlowRoom = preload("res://levels/flowkamer/flow_room.gd")
const FlowDuo = preload("res://levels/flowkamer/flow_duo.gd")
const FlowReport = preload("res://levels/flowkamer/flow_report.gd")
const T17 = preload("res://tests/test_flowtest_t17.gd")

const TICK_CAP := 7000
## Een lancering in B4 begint op de plank van de drager aan de rand van de kloof.
const B4_MIN_X := 1180.0

static var _duo120_csv := ""


func _run(t, d: int) -> String:
	var t17 = T17.new()
	var room = FlowRoom.new()
	room.tail = d
	room.echo_on = true
	room.autosave = false
	room.show_hud = false
	var duo := FlowDuo.new(room)
	room.input_override = duo.p1_input
	t.tree.root.add_child(room)
	await t.tree.physics_frame
	t.check(room.join_partner(duo.p2_input), "duo D=%d: drop-in mislukt" % d)
	var joined_at: int = room.sim.tick
	var still = T17._StillP2.new()
	still.room = room
	var trail := {}
	# Springplank-landingen per bouwsteen (van de springer): zoals `_run` in T17.
	var per_leg := {}
	var seen := 0
	while not room.run_over and room.sim.tick < TICK_CAP:
		await t.tree.physics_frame
		still.on_tick(room.sim.tick)
		var rows: Array = room.meetlog.rows
		while seen < rows.size():
			var row: PackedStringArray = rows[seen]
			if row[2] in ["SPRINGPLANK", "VANGEN", "LANCERING"]:
				var springer: FlowDuo.Seat = duo.p2_input if row[4] == "p1" else duo.p1_input
				var key := "%s %s" % [row[2], FlowDuo.STEPS[mini(springer.step, FlowDuo.STEPS.size() - 1)][0]]
				per_leg[key] = int(per_leg.get(key, 0)) + 1
			seen += 1
	if not room.meetlog.is_closed():
		room.meetlog.finish()
	var rows: Array = room.meetlog.rows
	var rep: FlowReport = FlowReport.from_rows(rows)
	var ticks: int = rep.duration
	t.check(room.run_over, "duo D=%d: geen RUN_EIND binnen %d ticks (P1 op %s/%s, P2 op %s/%s, kamer %s)" % [
		d, TICK_CAP, duo.p1_input.step, duo.p1_input.sub, duo.p2_input.step, duo.p2_input.sub, room.room])
	t.check(room.coop_seen and room.p2 != null, "duo D=%d: P2 niet in het spel" % d)
	# Wat het duo moet doen (#125 punt 1).
	var launches_b4 := 0
	for row in rows:
		# Drager P1 (bron), springer P2: de rolverdeling van B4 in `flow_duo.gd`.
		if row[2] == "LANCERING" and row[1] == "K1" and row[4] == "p1" and float(row[5]) > B4_MIN_X:
			launches_b4 += 1
	t.check(launches_b4 >= 1, "duo D=%d: geen lancering van P2 over P1 in B4" % d)
	# MP-6 co-op (zoals T17): LP uit bronnen met P2 of een samenwerkingsactie.
	var lp_coop := 0
	for row in rows:
		if row[2] != "LP":
			continue
		var parts: PackedStringArray = str(row[4]).rsplit("_", true, 1)
		if parts[parts.size() - 1] == "p2" or parts[0] in T17.COOP_LP:
			lp_coop += int(str(row[3]).trim_prefix("+"))
	var pumps_p2: int = t17._count(room, "POMP", "p2")
	var pumps_p1: int = t17._count(room, "POMP", "p1")
	# MP-7 (c), W6: bron = drager, de springer is de ander.
	var as_springer_p1 := 0
	var as_springer_p2 := 0
	for row in rows:
		if row[2] in ["SPRINGPLANK", "LANCERING", "VANGEN"]:
			if row[4] == "p2":
				as_springer_p1 += 1
			elif row[4] == "p1":
				as_springer_p2 += 1
	var bounces_p1 := 0
	var bounces_p2 := 0
	for row in rows:
		if row[2] == "BOUNCE":
			if row[4] == "p2":
				bounces_p1 += 1
			elif row[4] == "p1":
				bounces_p2 += 1
	t.check(bounces_p1 >= 1 and bounces_p2 >= 1, "duo D=%d: bounce niet in beide richtingen (P1 %d, P2 %d)" % [
		d, bounces_p1, bounces_p2])
	var combos: int = t17._count(room, "ONTPLOFFING") - t17._chain_links(room)
	var combos_k2 := 0
	for row in rows:
		if row[2] == "ONTPLOFFING" and row[3] == "1" and row[1] == "K2":
			combos_k2 += 1
	t.check(combos_k2 >= 1, "duo D=%d: geen merk-combo in K2" % d)
	t.check(pumps_p2 >= 1, "duo D=%d: geen pompslag van P2" % d)
	var per_player := as_springer_p1 + as_springer_p2 + combos
	var solo: int = T17._solo_ticks.get(d, 0)
	t.check(solo > 0, "duo D=%d: geen solo-run (test_flowtest_t17.gd) om MP-7 (a) mee te vergelijken" % d)
	var ratio := float(room.run_ticks()) / float(solo) if solo > 0 else NAN
	# MP-4 co-op (W4): echo Leeg vóór de drop-in + P2 opgelost.
	var no_body := float(joined_at - rep.start + still.dissolved_ticks) / maxf(float(ticks), 1.0)
	var dissolved_share := float(still.dissolved_ticks) / maxf(float(still.present_ticks), 1.0)
	# `fails` = alle normen (zoals T17); `required` = wat de gescripte co-op-run
	# volgens gdd §4.5 moet halen: MP-1, MP-2, MP-4, MP-6 en MP-7 (b)–(d). MP-3
	# en MP-7 (a) staan alleen in de uitvoer (MP-7 (a) is een mediaan over mensen).
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
	if t17._per_min(per_player, ticks) < 1.0: fails.append("MP-7c %.2f/min" % t17._per_min(per_player, ticks))
	if dissolved_share > 0.10: fails.append("MP-7d %.0f %%" % (dissolved_share * 100.0))
	var required := PackedStringArray()
	for f in fails:
		if not (f.begins_with("MP-3") or f.begins_with("MP-7a")):
			required.append(f)
	t.check(required.is_empty(), "duo D=%d: de gescripte co-op-run haalt niet: %s" % [d, "; ".join(required)])
	t.note(("T17 co-op duo D=%d · drop-in tick %d · tijd %d ticks (%.1f s) · MP-1 P1 %d · MP-2 %.2f/min (K1 %.2f, K2 %.2f), gat %d · " +
		"MP-3 %.2f landingen/min, %.0f %% zonder stilstand · lancering %d (B4 %d), bounce P1 %d / P2 %d, merk-combo %d (K2 %d), vang %d · " +
		"acties per bouwsteen %s · MP-4 zonder tweede lichaam %.1f %% · MP-6 co-op %.0f %% van %d LP (LP vóór K3 %d), pompslagen P1 %d / P2 %d · " +
		"MP-7a %.2f× solo (%d/%d) · MP-7b P2 %d · MP-7c springer P1 %d, P2 %d, merk-combo %d → %.2f/min per speler · " +
		"MP-7d P2 opgelost %.1f %% (%d×) · lijnen %s · normen: %s") % [
		d, joined_at, ticks, ticks / 60.0, rep.longest_still, rep.actions_per_min,
		rep.actions_per_min_room.get("K1", 0.0), rep.actions_per_min_room.get("K2", 0.0), rep.longest_gap,
		rep.landings_per_min, rep.landings_without_still * 100.0,
		t17._count(room, "LANCERING"), launches_b4, bounces_p1, bounces_p2, combos, combos_k2, t17._count(room, "VANGEN"),
		str(per_leg), no_body * 100.0, float(lp_coop) / maxf(float(rep.lp_total), 1.0) * 100.0, rep.lp_total,
		rep.lp_before_k3, pumps_p1, pumps_p2, ratio, room.run_ticks(), solo, still.longest,
		as_springer_p1, as_springer_p2, combos, t17._per_min(per_player, ticks),
		dissolved_share * 100.0, t17._count(room, "P2_OPGELOST"), str(duo.lines),
		"gehaald" if fails.is_empty() else "NIET: " + "; ".join(fails)])
	var csv: String = room.meetlog.to_csv()
	room.queue_free()
	await t.tree.process_frame
	await t.tree.physics_frame
	return csv


# --- Tests (één run per test: de runner geeft 7200 frames) ---------------------

func test_t17_coop_duo_d90(t) -> void:
	await _run(t, 90)


func test_t17_coop_duo_d120(t) -> void:
	_duo120_csv = await _run(t, 120)


func test_t17_coop_duo_d180(t) -> void:
	await _run(t, 180)


## Dezelfde run nog eens: hetzelfde meetlog (gdd §4.5: het log is deterministisch).
func test_t17_coop_duo_d120_deterministic(t) -> void:
	t.check(_duo120_csv != "", "geen eerste duo-run D=120")
	var again: String = await _run(t, 120)
	t.check(again == _duo120_csv, "duo-run D=120 gaf de tweede keer een ander meetlog")
