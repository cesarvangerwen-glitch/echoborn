extends SceneTree
## Rekent de meetlogs van mijlpaaltest MT2 uit (de Kadewijk S1–S9 met de
## Gemaalmeester; `docs/qa/testplan-mt2.md` §2.2, §4), op D = 60 en als
## regressie op 90 / 120 / 180. Aangepaste kopie van
## `docs/qa/mt1-meetlogs/rekenen.gd` (dat blijft ongewijzigd voor MT1).
##
## Anders dan MT1:
##   - kamers S1–S9 in plaats van K1–K3; de keerpunten uit
##     `kadewijk_layout.gd` (`turn_points`) plus S4-B4 (de bolder);
##   - geen `SCORE`-regels (W32) en geen oefenrun (W31);
##   - MP-2 per kamer en de gaten in S9 (rustpunt ≤ 720, daarna ≤ 600 ticks);
##   - F4b(b) met route-tijd zonder de arena (gdd §5.1);
##   - RV-2 (stuiten boven het kanaal van S7) en RV-4 (de lege loop na S3);
##   - RV-1: de hangtijd boven de echo per keerpunt (W33), uit het hanglog
##     van `botlogs.gd` (`hang_*.csv`); een meetlog van de CEO heeft geen
##     hanglog, dan alleen de uitkomst A–D;
##   - echo-acties per soort en per kamer; `DEBUG`, `RESPAWN`, `BREEK`.
##
## Draaien vanuit de root van de repo (Godot 4.6.3):
##   godot --headless --path game -s "$PWD/docs/qa/mt2-meetlogs/rekenen.gd" -- <map met CSV's>
## Het rekent elk `bot_*.csv` en `meetlog_*kadewijk*.csv` in de map; bij
## `bot_X.csv` zoekt het `hang_X.csv` (zelfde achtervoegsel).

const FlowReport := preload("res://levels/flowkamer/flow_report.gd")
const Layout := preload("res://levels/kadewijk/kadewijk_layout.gd")

const MINUTE := 3600.0
const MP3_LOOKBACK := 120
const MP3_STILL := 20
## W26 (MT1): gewacht dichter dan C_MAX px bij de keerwand = C.
const C_MAX := 30.0
## Een keerpunt telt als "tegen de wand" binnen deze afstand (middelpunt P1).
const AT_WALL := 20.0
## W33: in de lucht en horizontaal niet meer dan dit per tick = hangen.
const HANG_VX := 0.5
## Kanaal in S7 (`kadewijk.md` §3d).
const KANAAL := [4960.0, 5120.0]
const S9_RUST := 720
const S9_GAT := 600


func _init() -> void:
	var dirs := OS.get_cmdline_user_args()
	for dir_path: String in dirs:
		var names := Array(DirAccess.get_files_at(dir_path))
		names.sort()
		for file_name: String in names:
			if not file_name.ends_with(".csv"):
				continue
			if file_name.begins_with("bot_") or (file_name.begins_with("meetlog_") and file_name.contains("kadewijk")):
				var hang_path := dir_path.path_join(file_name.replace("bot_", "hang_"))
				var hang: Array = []
				if file_name.begins_with("bot_") and FileAccess.file_exists(hang_path):
					hang = _read(hang_path, 10)
				_report(file_name, _read(dir_path.path_join(file_name), 7), hang)
	quit()


func _read(path: String, cols: int) -> Array:
	var f := FileAccess.open(path, FileAccess.READ)
	var rows: Array = []
	f.get_csv_line()
	while not f.eof_reached():
		var line := f.get_csv_line()
		if line.size() >= cols:
			rows.append(line)
	return rows


func _d_of(file_name: String, rows: Array) -> int:
	var m := RegEx.create_from_string("_D(\\d+)").search(file_name)
	if m != null:
		return int(m.get_string(1))
	for r: Array in rows:
		if r[2] == "ECHO_LEEG_EIND":
			return int(r[0])
	return 60


func _first(rows: Array, event: String) -> int:
	for r: Array in rows:
		if r[2] == event:
			return int(r[0])
	return -1


## Echo-acties zoals MP-2 (FlowReport): één contact per springer en tick, en
## een ketting als één actie (alleen de eerste schakel).
func _actions(rows: Array) -> Array:
	var out: Array = []
	var seen := {}
	for r: Array in rows:
		match r[2]:
			"SPRINGPLANK", "LANCERING", "VANGEN":
				var key := "%s|%s" % [r[0], r[4]]
				if not seen.has(key):
					seen[key] = true
					out.append([int(r[0]), r[1], r[2]])
			"ONTPLOFFING":
				if r[3] == "1":
					out.append([int(r[0]), r[1], r[2]])
	return out


func _report(file_name: String, rows: Array, hang: Array) -> void:
	var d := _d_of(file_name, rows)
	var rep = FlowReport.from_rows(rows, true)
	var start := _first(rows, "RUN_START")
	var end := maxi(_first(rows, "RUN_EIND"), rep.end)
	var boss_a := _first(rows, "BOSS_START")
	var boss_b := _first(rows, "BOSS_VERSLAGEN")
	var in_boss := func(t: int) -> bool: return boss_a >= 0 and t >= boss_a and (boss_b < 0 or t <= boss_b)
	var acts := _actions(rows)
	print("\n=== %s (D = %d) ===" % [file_name, d])
	print("runtijd %d ticks (%.1f s), SLICE_EIND %s, BOSS %d → %d (%.1f s)" % [end - start, (end - start) / 60.0,
		_first(rows, "SLICE_EIND"), boss_a, boss_b, (boss_b - boss_a) / 60.0 if boss_a >= 0 and boss_b >= 0 else 0.0])

	# --- punt 2 en 3: MP-1, MP-2 per kamer, het langste gat ---
	var per_room := PackedStringArray()
	var mp2_fail := PackedStringArray()
	for room in Layout.ORDER:
		var k := String(room)
		if not rep.room_time.has(k):
			continue
		var v: float = rep.actions_per_min_room.get(k, 0.0)
		per_room.append("%s %.1f (%d s)" % [k, v, int(rep.room_time[k] / 60.0)])
		if v < 3.0:
			mp2_fail.append(k)
	print("MP-1 langste stilstand %d · MP-2 %.1f per min, per kamer: %s · langste gat %d ticks (%.1f s)" % [
		rep.longest_still, rep.actions_per_min, ", ".join(per_room), rep.longest_gap, rep.longest_gap / 60.0])
	print("  MP-2 < 3,0 in: %s" % (", ".join(mp2_fail) if not mp2_fail.is_empty() else "geen"))
	# Gaten in S9 vanaf de laatste binnenkomst (via de trap af) tot SLICE_EIND.
	var s9_in := -1
	for r: Array in rows:
		if r[2] == "KAMER" and r[4] == "S9":
			s9_in = int(r[0])
	if s9_in >= 0:
		var gaps := PackedInt32Array()
		var last := s9_in
		var s9_end := _first(rows, "SLICE_EIND")
		if s9_end < 0:
			s9_end = end
		for a: Array in acts:
			if a[0] > s9_in and a[0] <= s9_end and a[1] == "S9":
				gaps.append(a[0] - last)
				last = a[0]
		gaps.append(s9_end - last)
		var ok := gaps.size() > 0 and gaps[0] <= S9_RUST
		for i in range(1, gaps.size()):
			ok = ok and gaps[i] <= S9_GAT
		print("  S9 gaten vanaf binnenkomst %d: %s · rustpunt ≤ %d, daarna ≤ %d: %s" % [s9_in, gaps, S9_RUST, S9_GAT, "ja" if ok else "NEE"])

	# --- punt 4: MP-3, MP-4, MP-6 ---
	print("MP-3 %.0f %% van %d landingen zonder stilstand · MP-4 echo Leeg %.1f %% · MP-6 %.0f %% van %d LP met de echo, %d pompslagen van de echo · BREEK %d · RESPAWN %d · DEBUG %d" % [
		rep.landings_without_still * 100.0, rep.landings, rep.echo_empty_share * 100.0, rep.lp_echo_share * 100.0,
		rep.lp_total, rep.echo_pumps, rep.breaks, rows.filter(func(r) -> bool: return r[2] == "RESPAWN").size(),
		rows.filter(func(r) -> bool: return r[2] == "DEBUG").size()])

	# --- punt 9: F4b(b), route-tijd zonder de arena (gdd §5.1) ---
	var route := float(end - start)
	if boss_a >= 0 and boss_b >= 0:
		route -= boss_b - boss_a
	var n_act := 0
	var n_plank := 0
	var n_boom := 0
	var lp_all := 0
	var lp_echo := 0
	var contacts := {}
	for a: Array in acts:
		if not in_boss.call(a[0]):
			n_act += 1
	for r: Array in rows:
		var t := int(r[0])
		if in_boss.call(t):
			continue
		match r[2]:
			"SPRINGPLANK", "VANGEN", "LANCERING":
				var key := "%s|%s" % [r[0], r[4]]
				if not contacts.has(key):
					contacts[key] = true
					n_plank += 1
			"ONTPLOFFING":
				n_boom += 1
			"LP":
				var n := int(str(r[3]).trim_prefix("+"))
				lp_all += n
				if str(r[4]).ends_with("_echo"):
					lp_echo += n
	var mins := maxf(route, 1.0) / MINUTE
	var f1 := n_act / mins
	var f2a := n_plank / mins
	var f2b := n_boom / mins
	var f3 := float(lp_echo) / maxf(lp_all, 1.0)
	print("F4b(b) route-tijd %.1f s: (1) %.2f echo-acties/min (≥ 2,0) · (2) springplank %.2f/min (≥ 1,0), ontploffingen %.2f/min (≥ 0,5) · (3) %.0f %% van %d LP met de echo (≥ 30 %%) → %s" % [
		route / 60.0, f1, f2a, f2b, f3 * 100.0, lp_all,
		"positief" if f1 >= 2.0 and f2a >= 1.0 and f2b >= 0.5 and f3 >= 0.3 else "NEGATIEF"])

	# --- echo-acties per soort en per kamer (pitch §5, tabel voor de LGD) ---
	var kinds := {}
	for r: Array in rows:
		if r[2] in ["SPRINGPLANK", "BOUNCE", "LANCERING", "VANGEN", "STUIT", "MERKSPRONG", "ONTPLOFFING"]:
			var k: String = r[1]
			if not kinds.has(k):
				kinds[k] = {}
			kinds[k][r[2]] = int(kinds[k].get(r[2], 0)) + 1
	var kind_line := PackedStringArray()
	for room in Layout.ORDER:
		if kinds.has(String(room)):
			kind_line.append("%s %s" % [room, kinds[String(room)]])
	print("echo-acties per kamer: %s" % "; ".join(kind_line))

	# --- RV-2: stuiten boven het kanaal (S7); RV-4: de lege loop na S3 ---
	var stuit_kanaal := rows.filter(func(r) -> bool:
		return r[2] == "STUIT" and r[1] == "S7" and float(r[5]) >= KANAAL[0] and float(r[5]) <= KANAAL[1]).size()
	var boom_s7 := rows.filter(func(r) -> bool: return r[2] == "ONTPLOFFING" and r[1] == "S7").size()
	print("RV-2 S7: %d stuits boven het kanaal, %d ontploffingen in S7 (%s)" % [stuit_kanaal, boom_s7,
		"stuitlijn" if stuit_kanaal > 0 else "langzame lijn"])
	var last_s3 := -1
	for r: Array in rows:
		if r[2] == "ONTPLOFFING" and r[1] == "S3":
			last_s3 = int(r[0])
	if last_s3 >= 0:
		var next := -1
		for a: Array in acts:
			if a[0] > last_s3:
				next = a[0]
				break
		print("RV-4 lege loop: laatste ontploffing S3 tick %d → volgende echo-actie tick %d: %d ticks (%.1f s; > 600 = bevinding)" % [
			last_s3, next, next - last_s3, (next - last_s3) / 60.0])

	# --- §4.2 en RV-1: per keerpunt A–D, en de hangtijd (alleen met hanglog) ---
	_turns(d, rows, rep, hang)


func _turns(d: int, rows: Array, rep, hang: Array) -> void:
	var tps: Array = Layout.turn_points(d).filter(func(tp) -> bool: return tp["name"] != "S8-rad")
	tps.insert(3, {"name": "S4-B4", "wall": Layout.B4_NEAR_EDGE - Layout.B4_BOLDER_W, "floor": Layout.S4_FLOOR, "side": 1})
	var line := PackedStringArray()
	for tp: Dictionary in tps:
		var y_floor: float = tp["floor"] - Layout.HALF_H
		var wall: float = tp["wall"]
		var t_turn := -1
		if not hang.is_empty():
			# Eerste aanraking van de keerwand op dat niveau; keren = de laatste tick ervan.
			var touching := false
			for h: Array in hang:
				var at := int(h[6]) == 1 and absf(float(h[3]) - y_floor) <= 3.0 and absf(float(h[2]) - wall) <= AT_WALL
				if at:
					touching = true
					t_turn = int(h[0])
				elif touching:
					break
		else:
			# Zonder hanglog: de eerste regel van het meetlog op dat niveau dicht bij de wand.
			for r: Array in rows:
				if absf(float(r[6]) - y_floor) <= 3.0 and absf(float(r[5]) - wall) <= AT_WALL:
					t_turn = int(r[0])
					break
		if t_turn < 0:
			line.append("%s: niet gezien" % tp["name"])
			continue
		# De eerste landing op een plank (de echo) na het keren, vóór het volgende niveau.
		var t_land := -1
		var land_x := 0.0
		for r: Array in rows:
			var t := int(r[0])
			if t > t_turn and t <= t_turn + 300 and (r[2] == "SPRINGPLANK" or r[2] == "VANGEN"):
				t_land = t
				land_x = float(r[5])
				break
		if t_land < 0:
			line.append("%s: D (langzame lijn, geen plank binnen 300 ticks na keren op %d)" % [tp["name"], t_turn])
			continue
		# A/B/C (W26): een stilstand van ≥ 20 ticks in de 120 ervoor?
		var outcome := "A"
		for run: Array in rep.still_runs:
			var lo := maxi(int(run[0]), t_land - MP3_LOOKBACK)
			var hi := mini(int(run[1]), t_land)
			if hi - lo + 1 >= MP3_STILL:
				outcome = "B"
				var sx := _x_at(rows, hang, int(run[0]))
				if absf(sx - wall) < C_MAX:
					outcome = "C"
		var text := "%s: %s, keren %d → plank %d (%d ticks, %.0f px van de wand)" % [
			tp["name"], outcome, t_turn, t_land, t_land - t_turn, absf(land_x - wall)]
		if not hang.is_empty():
			var air := 0
			var hang_n := 0
			var hang_run := 0
			var best_run := 0
			var afzet := -1
			for h: Array in hang:
				var t := int(h[0])
				if t <= t_turn or t >= t_land:
					continue
				if int(h[6]) == 0:
					air += 1
					if afzet < 0:
						afzet = t
					if absf(float(h[4])) <= HANG_VX:
						hang_n += 1
						hang_run += 1
						best_run = maxi(best_run, hang_run)
					else:
						hang_run = 0
				else:
					hang_run = 0
			text += "; in de lucht %d ticks (afzet %d), hangen %d ticks (langst aaneen %d)" % [air, afzet, hang_n, best_run]
		line.append(text)
	print("keerpunten (A–D, W26; hangen = in de lucht met |vx| ≤ %.1f, W33):\n  %s" % [HANG_VX, "\n  ".join(line)])


func _x_at(rows: Array, hang: Array, tick: int) -> float:
	for h: Array in hang:
		if int(h[0]) == tick:
			return float(h[2])
	var x := 0.0
	for r: Array in rows:
		if int(r[0]) > tick:
			break
		x = float(r[5])
	return x
