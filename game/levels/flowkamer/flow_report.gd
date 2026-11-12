extends RefCounted
## Rekent de flownormen uit één meetlog (gdd §4.5): MP-1, MP-2, MP-3, MP-4,
## MP-6 en de LP-stand. Voor de tests van de kamer en als hulp voor T17; het
## rapport zelf is van de QA Lead (T17). Werkt op de regels van het meetlog
## (`tick, kamer, event, waarde, bron, x, y`), dus ook op een CSV.
##
## O-24 (gdd v0.8.1 §4.5, `kamers/flowkamer.md` §12 antwoord 6 en 7): één contact = één actie:
## `SPRINGPLANK` en `LANCERING`/`VANGEN` van dezelfde springer op dezelfde tick tellen in MP-2 als
## één actie; in MP-3 is een landing één contact met een plank (`SPRINGPLANK` of `VANGEN`; een
## lancering volgt altijd op zo'n contact). MP-3 meet de stilstand van de **springer**: solo P1,
## in co-op het lichaam dat landt (bron = de drager: `p1` → springer P2, anders P1).

const MINUTE := 3600.0
const MP2_WINDOW := 2400   ## 40 s
const MP3_LOOKBACK := 120
const MP3_STILL := 20

var start := 0
var end := 0
var duration := 0
## MP-1: langste stilstand van P1 (ticks).
var longest_still := 0
## MP-7 (b): langste stilstand van P2 (ticks; 0 solo of in een log van vóór #125).
var longest_still_p2 := 0
## MP-2: echo-acties (tick, kamer).
var actions: Array = []
var actions_per_min := 0.0
var actions_per_min_room := {}
var longest_gap := 0
## MP-3.
var landings := 0
var landings_per_min := 0.0
var landings_without_still := 0.0
## MP-4: aandeel van de tijd dat de echo Leeg of Buiten is.
var echo_empty_share := 0.0
## MP-6.
var lp_total := 0
var lp_echo := 0
var lp_echo_share := 0.0
var echo_pumps := 0
var lp_by_source := {}
## LP opgebouwd vóór de eerste keer K3 (K1 + één keer K2, gdd §4.2: ≥ 100).
var lp_before_k3 := 0
var gemaal_full_tick := -1
var breaks := 0
var room_time := {}
var still_runs: Array = []  ## [begin, eind] inclusief
## Stilstanden van P2 (co-op), voor MP-3 als P2 de springer is.
var still_runs_p2: Array = []


static func from_rows(rows: Array, has_echo: bool = true):
	var r = new()
	r._compute(rows, has_echo)
	return r


func _compute(rows: Array, has_echo: bool) -> void:
	var room_enter := 0
	var room_now := ""
	var empty_since := -1
	var empty_total := 0
	var seen_k3 := false
	var echo_rows_seen := false
	var contacts := {}
	for row in rows:
		var tick := int(row[0])
		var event: String = row[2]
		match event:
			"RUN_START":
				start = tick
				room_enter = tick
				room_now = row[1]
				# De echo begint Leeg (E-03): tot zijn eerste ECHO_LEEG_EIND.
				empty_since = tick if has_echo else -1
			"RUN_EIND":
				end = tick
			"KAMER":
				room_time[room_now] = int(room_time.get(room_now, 0)) + tick - room_enter
				room_now = row[4]
				room_enter = tick
				if room_now == "K3":
					seen_k3 = true
			"STIL_EIND":
				var n := int(row[3])
				# Bron `p2` is MP-7 (b); P1 (bron `p1`) blijft MP-1 en MP-3.
				if row[4] == "p2":
					longest_still_p2 = maxi(longest_still_p2, n)
					still_runs_p2.append([tick - n, tick - 1])
				else:
					longest_still = maxi(longest_still, n)
					still_runs.append([tick - n, tick - 1])
			"SPRINGPLANK", "LANCERING", "VANGEN":
				# Eén contact = één actie (antwoord 6): dezelfde springer (bron = drager) op dezelfde tick.
				var contact := "%d|%s" % [tick, row[4]]
				if not contacts.has(contact):
					contacts[contact] = true
					actions.append([tick, row[1]])
				if event != "LANCERING":
					landings += 1
			"ONTPLOFFING":
				# Een ketting telt als één actie: alleen de eerste schakel.
				if row[3] == "1":
					actions.append([tick, row[1]])
			"ECHO_LEEG_START":
				echo_rows_seen = true
				if empty_since < 0:
					empty_since = tick
			"ECHO_LEEG_EIND":
				echo_rows_seen = true
				if empty_since >= 0:
					empty_total += tick - empty_since
					empty_since = -1
			"LP":
				var n := int(str(row[3]).trim_prefix("+"))
				lp_total += n
				lp_by_source[row[4]] = int(lp_by_source.get(row[4], 0)) + n
				if str(row[4]).ends_with("_echo"):
					lp_echo += n
				if not seen_k3:
					lp_before_k3 += n
			"POMP":
				if row[4] == "echo":
					echo_pumps += 1
			"GEMAAL_VOL":
				gemaal_full_tick = tick
			"BREEK":
				breaks += 1
	room_time[room_now] = int(room_time.get(room_now, 0)) + end - room_enter
	if empty_since >= 0:
		empty_total += end - empty_since
	duration = maxi(end - start, 1)
	actions_per_min = actions.size() * MINUTE / duration
	for room_name: String in room_time:
		var n := 0
		for a: Array in actions:
			if a[1] == room_name:
				n += 1
		actions_per_min_room[room_name] = n * MINUTE / maxf(float(room_time[room_name]), 1.0)
	var last := start
	for a: Array in actions:
		longest_gap = maxi(longest_gap, int(a[0]) - last)
		last = int(a[0])
	longest_gap = maxi(longest_gap, end - last)
	landings_per_min = landings * MINUTE / duration
	var clean := 0
	for row in rows:
		if row[2] != "SPRINGPLANK" and row[2] != "VANGEN":
			continue
		var t := int(row[0])
		var waited := false
		# De springer (antwoord 7): bron `p1` = P1 droeg, dus P2 landde.
		var runs: Array = still_runs_p2 if row[4] == "p1" else still_runs
		for run: Array in runs:
			var lo := maxi(int(run[0]), t - MP3_LOOKBACK)
			var hi := mini(int(run[1]), t)
			if hi - lo + 1 >= MP3_STILL:
				waited = true
		if not waited:
			clean += 1
	landings_without_still = float(clean) / landings if landings > 0 else 0.0
	echo_empty_share = float(empty_total) / duration if has_echo else 1.0
	lp_echo_share = float(lp_echo) / lp_total if lp_total > 0 else 0.0


## Haalt de run de normen die de kamer moet kunnen halen (gdd §4.5)?
## Geeft de redenen waarom niet; leeg = gehaald.
func failures() -> PackedStringArray:
	var out := PackedStringArray()
	if longest_still > 300:
		out.append("MP-1: langste stilstand %d ticks (≤ 300)" % longest_still)
	if actions_per_min < 3.0:
		out.append("MP-2: %.2f echo-acties per minuut (≥ 3,0)" % actions_per_min)
	for room_name in ["K1", "K2"]:
		if float(actions_per_min_room.get(room_name, 0.0)) < 3.0:
			out.append("MP-2: %s %.2f echo-acties per minuut (≥ 3,0)" % [room_name, actions_per_min_room.get(room_name, 0.0)])
	if longest_gap > MP2_WINDOW:
		out.append("MP-2: %d ticks zonder echo-actie (≤ 2400)" % longest_gap)
	if echo_empty_share > 0.40:
		out.append("MP-4: echo %.0f %% Leeg (≤ 40 %%)" % (echo_empty_share * 100.0))
	if lp_echo_share < 0.40:
		out.append("MP-6: %.0f %% van de LP met de echo (≥ 40 %%)" % (lp_echo_share * 100.0))
	if echo_pumps < 1:
		out.append("MP-6: geen pompslag van de echo")
	return out


func summary() -> String:
	return ("run %.1f s · MP-1 langste stil %d · MP-2 %.1f/min (K1 %.1f, K2 %.1f, K3 %.1f), gat %.1f s · " +
		"MP-3 %.1f landingen/min, %.0f %% zonder wachten · MP-4 Leeg %.0f %% · MP-6 echo %.0f %% van %d LP, %d echo-pompslagen · " +
		"LP vóór K3 %d · breuken %d") % [duration / 60.0, longest_still, actions_per_min,
		actions_per_min_room.get("K1", 0.0), actions_per_min_room.get("K2", 0.0), actions_per_min_room.get("K3", 0.0),
		longest_gap / 60.0, landings_per_min, landings_without_still * 100.0, echo_empty_share * 100.0,
		lp_echo_share * 100.0, lp_total, echo_pumps, lp_before_k3, breaks]
