extends SceneTree
## Rekent de meetlogs van de tweede flow-test F0-2 uit (T17-2, #80;
## `docs/qa/testplan-f0-2.md` §4). Uitbreiding van `docs/qa/f0-meetlogs/rekenen.gd`:
## per run `flow_report.gd` (MP-1–MP-4, MP-6) en daarnaast, uit dezelfde
## CSV-regels (geen nieuwe events, gdd §4.7.4):
##   - MP-1 met plek (kamer, bouwsteen, x, y) en de stilstand in B4 apart (W14);
##   - MP-3 per landing en per bouwsteen, en per keerpunt de uitkomst A–D (§4.2,
##     W15) met de wachtafstand tot de keerwand;
##   - stilstand per kamer met plek (§4.3): K1 per bouwsteen, K2 per merk, K3
##     elke stilstand ≥ 30 ticks (schoepen / sluis / bovenste trede / elders),
##     de landing op de bovenste trede en de stilstand bij de sluis (LM-04);
##   - de kamervolgorde (KAMER-events) en de LP vóór de eerste keer K3.
##
## Draaien vanuit de root van de repo (Godot 4.6.3):
##   godot --headless --path game -s "$PWD/docs/qa/f0-2-meetlogs/rekenen.gd" -- "$PWD/docs/qa/f0-2-meetlogs"
## Een tweede map mag (bv. logs van de gescripte run of de wachtbot); bestanden
## die niet met `meetlog_` beginnen, krijgen het label "bot".
##
## Afstanden tot de keerwand zijn van het middelpunt van P1 tot het wandvlak
## (zoals `flowkamer.md` §9); P1 staat tegen de wand op ± 8 px.

const FlowReport := preload("res://levels/flowkamer/flow_report.gd")

const MP3_LOOKBACK := 120
const MP3_STILL := 20
## Niveaus van K1 (vloer-y) met keerwand (flowkamer.md §3; flow_layout.turn_points).
const TURNS := [
	{"name": "B1", "floor": 540.0, "wall": 20.0},
	{"name": "B2-0", "floor": 450.0, "wall": 500.0},
	{"name": "B2-1", "floor": 360.0, "wall": 20.0},
	{"name": "B2-2", "floor": 270.0, "wall": 500.0},
	{"name": "B2-3", "floor": 180.0, "wall": 20.0},
]
const VANES := [1980.0, 1900.0, 1820.0, 1740.0]
const HALF_H := 15.0
## P1 is 30 hoog; op de echo (30 hoog) staat zijn middelpunt 45 boven de vloer.
const ON_ECHO := 45.0


func _init() -> void:
	var dirs := OS.get_cmdline_user_args()
	if dirs.is_empty():
		dirs = PackedStringArray(["res://../docs/qa/f0-2-meetlogs"])
	for dir_path: String in dirs:
		_run_dir(dir_path)
	quit()


func _run_dir(dir_path: String) -> void:
	var names := Array(DirAccess.get_files_at(dir_path))
	names.sort()
	var done := 0
	for file_name: String in names:
		if not file_name.ends_with(".csv"):
			continue
		var rows := _read(dir_path.path_join(file_name))
		var label := "bot"
		if file_name.begins_with("meetlog_"):
			var scores := rows.filter(func(r) -> bool: return r[2] == "SCORE").size()
			var ended := rows.any(func(r) -> bool: return r[2] == "RUN_EIND")
			if file_name.contains("_afgebroken") or not ended or scores < 3:
				label = "afgebroken (telt niet, W12)"
			else:
				done += 1
				label = "oefenrun %d (telt niet, W7)" % done if done <= 2 else "getelde run %d" % (done - 2)
		_report(file_name, label, rows)


func _read(path: String) -> Array:
	var f := FileAccess.open(path, FileAccess.READ)
	var rows: Array = []
	f.get_csv_line()  # kop
	while not f.eof_reached():
		var line := f.get_csv_line()
		if line.size() >= 7:
			rows.append(line)
	return rows


func _report(file_name: String, label: String, rows: Array) -> void:
	var d := -1
	var scores := PackedStringArray()
	var stills: Array = []  # [begin, eind, kamer, x, y] (begin = tick van STIL_START)
	var open := {}
	var rooms := PackedStringArray()
	var gemaal := -1
	var run_end := -1
	var launch := -1
	for r: Array in rows:
		var t := int(r[0])
		match r[2]:
			"ECHO_LEEG_EIND":
				if d < 0:
					d = t
			"SCORE":
				scores.append(r[3])
			"STIL_START":
				if r[4] == "p1":
					open = {"t": t, "x": float(r[5]), "y": float(r[6]), "k": r[1]}
			"STIL_EIND":
				if r[4] == "p1":
					var n := int(r[3])
					var x: float = open.get("x", float(r[5]))
					var y: float = open.get("y", float(r[6]))
					stills.append([t - n, t, open.get("k", r[1]), x, y])
					open = {}
			"KAMER":
				rooms.append("%s@%d(%d,%d)" % [r[4], t, int(float(r[5])), int(float(r[6]))])
			"GEMAAL_VOL":
				gemaal = t
			"RUN_EIND":
				run_end = t
			"LANCERING":
				if launch < 0:
					launch = t
	var rep = FlowReport.from_rows(rows, true)
	var fails: PackedStringArray = rep.failures()
	print("\n=== %s · %s" % [file_name, label])
	print("  D uit log (eerste ECHO_LEEG_EIND): %s · scores K1/K2/K3: %s" % [
		str(d) if d >= 0 else "-", "/".join(scores) if scores.size() > 0 else "-"])
	print("  flow_report: %s" % rep.summary())
	print("  normen MP-1/-2/-4/-6: %s" % ("gehaald" if fails.is_empty() else "NIET: " + "; ".join(fails)))
	print("  kamers: K1@0 → %s · LP vóór K3 %d" % [" → ".join(rooms), rep.lp_before_k3])
	_mp1(stills, launch)
	_k1(rows, stills)
	_k2(rows, stills, d)
	_k3(rows, stills, gemaal, run_end)


func _floor_of(y: float, offset: float) -> float:
	return roundf(y + offset)


func _bouwsteen(k: String, x: float, y: float, offset: float) -> String:
	if k != "K1":
		return k
	var f := _floor_of(y, offset)
	for tp: Dictionary in TURNS:
		if absf(f - tp["floor"]) <= 3.0:
			return tp["name"]
	if absf(f - 90.0) <= 3.0:
		return "bovenroute"
	if x >= 1150.0 and f >= 600.0:
		return "B4"
	if absf(f - 650.0) <= 3.0:
		return "startgang"
	if absf(f - 610.0) <= 3.0:
		return "opstap/B3-kom"
	if absf(f - 565.0) <= 3.0 and x >= 480.0:
		return "B3-blok"
	if f < 540.0 and (x < 80.0 or x > 440.0):
		return "trede/richel 135"
	return "K1 (%d, %d)" % [int(x), int(y)]


func _mp1(stills: Array, launch: int) -> void:
	var best: Array = []
	var b4: Array = []
	for s: Array in stills:
		var n: int = s[1] - s[0]
		var place := _bouwsteen(s[2], s[3], s[4], HALF_H)
		if place == "B4" and (b4.is_empty() or n > b4[1] - b4[0]):
			b4 = s
		if best.is_empty() or n > best[1] - best[0]:
			best = s
	if best.is_empty():
		print("  MP-1: geen stilstand")
		return
	print("  MP-1: langste stilstand %d ticks in %s, %s (x %d, y %d), tick %d–%d" % [
		best[1] - best[0], best[2], _bouwsteen(best[2], best[3], best[4], HALF_H),
		int(best[3]), int(best[4]), best[0], best[1]])
	if not b4.is_empty():
		print("  B4 apart (W14): langste stilstand %d ticks (x %d); lancering: %s" % [
			b4[1] - b4[0], int(b4[3]), "tick %d" % launch if launch >= 0 else "geen (telt dus mee)"])


## Langste stille stuk (in ticks) in het venster [t − 120, t].
func _wait_before(stills: Array, t: int) -> Array:
	var best := 0
	var at: Array = []
	for s: Array in stills:
		var lo := maxi(int(s[0]), t - MP3_LOOKBACK)
		var hi := mini(int(s[1]) - 1, t)
		if hi - lo + 1 > best:
			best = hi - lo + 1
			at = s
	return [best, at]


func _k1(rows: Array, stills: Array) -> void:
	var landings: Array = []
	for r: Array in rows:
		if r[2] == "SPRINGPLANK":
			landings.append(r)
	var clean := 0
	var per_block := {}
	var lines := PackedStringArray()
	for r: Array in landings:
		var t := int(r[0])
		var place := _bouwsteen(r[1], float(r[5]), float(r[6]), ON_ECHO)
		var w := _wait_before(stills, t)
		var waited: bool = w[0] >= MP3_STILL
		if not waited:
			clean += 1
		var cell: Array = per_block.get(place, [0, 0])
		cell[0] += 1
		cell[1] += 0 if waited else 1
		per_block[place] = cell
		lines.append("%s t%d x%d %s" % [place, t, int(float(r[5])), "stil %d" % w[0] if waited else "zonder stilstand"])
	print("  MP-3: %d landingen, %d zonder stilstand ≥ %d in %d ticks ervoor%s" % [
		landings.size(), clean, MP3_STILL, MP3_LOOKBACK, "" if lines.is_empty() else ": " + "; ".join(lines)])
	var pb := PackedStringArray()
	for k: String in per_block:
		pb.append("%s %d/%d" % [k, per_block[k][1], per_block[k][0]])
	if not pb.is_empty():
		print("  MP-3 per bouwsteen (zonder stilstand / landingen): %s" % ", ".join(pb))
	# Per keerpunt (§4.2, W15).
	var reached_k2 := rows.any(func(r) -> bool: return r[2] == "KAMER" and r[4] == "K2")
	var outcome := PackedStringArray()
	for tp: Dictionary in TURNS:
		var wall: float = tp["wall"]
		var here: Array = landings.filter(func(r) -> bool:
			return r[1] == "K1" and absf(_floor_of(float(r[6]), ON_ECHO) - tp["floor"]) <= 3.0)
		var far: Array = here.filter(func(r) -> bool: return absf(float(r[5]) - wall) >= 60.0)
		if not far.is_empty():
			var r: Array = far[0]
			var t := int(r[0])
			var w := _wait_before(stills, t)
			if w[0] < MP3_STILL:
				outcome.append("%s A (landing %d px van de wand)" % [tp["name"], int(absf(float(r[5]) - wall))])
			else:
				var s: Array = w[1]
				var dist := absf(float(s[3]) - wall)
				var band := "80–119 px (keerzone)" if dist < 120.0 else ("120–240 px (restgat)" if dist <= 240.0 else "> 240 px")
				if dist < 80.0:
					band = "< 80 px"
				# Richting: eerder op dit niveau een stilstand of landing in de keerzone.
				var after_turn := false
				for e: Array in stills:
					if e[1] < s[0] and e[2] == "K1" and absf(_floor_of(e[4], HALF_H) - tp["floor"]) <= 3.0 \
							and absf(float(e[3]) - wall) < 120.0:
						after_turn = true
				for e: Array in here:
					if int(e[0]) < t and absf(float(e[5]) - wall) < 120.0:
						after_turn = true
				outcome.append("%s B (stilstand %d ticks, waarvan %d in de 120 vóór de landing, op %d px van de wand, %s, %s)" % [
					tp["name"], int(s[1]) - int(s[0]), int(w[0]), int(dist), band,
					"na het keren" if after_turn else "richting onbekend"])
		elif not here.is_empty():
			outcome.append("%s C (springplank %d px van de wand)" % [tp["name"], int(absf(float(here[0][5]) - wall))])
		else:
			# Wachtte hij wel? (stilstand op dit niveau, zonder springplank)
			var waits := PackedStringArray()
			for e: Array in stills:
				if e[2] == "K1" and absf(_floor_of(e[4], HALF_H) - tp["floor"]) <= 3.0 and e[1] - e[0] >= MP3_STILL:
					waits.append("%d ticks op %d px" % [e[1] - e[0], int(absf(float(e[3]) - wall))])
			outcome.append("%s D (%s%s)" % [tp["name"], "langzame lijn" if reached_k2 else "niveau niet gehaald",
				"" if waits.is_empty() else ", stil: " + ", ".join(waits)])
	print("  MP-3 per keerpunt: %s" % "; ".join(outcome))
	# Stilstand in K1 per bouwsteen.
	var k1 := {}
	for s: Array in stills:
		if s[2] != "K1":
			continue
		var place := _bouwsteen(s[2], s[3], s[4], HALF_H)
		k1[place] = maxi(int(k1.get(place, 0)), s[1] - s[0])
	var parts := PackedStringArray()
	for k: String in k1:
		parts.append("%s %d" % [k, k1[k]])
	print("  K1 langste stilstand per bouwsteen: %s" % (", ".join(parts) if not parts.is_empty() else "geen stilstand in K1"))


func _k2(rows: Array, stills: Array, d: int) -> void:
	var marks := {}
	var jumps := {}
	for r: Array in rows:
		if r[2] == "MERK_GEZET" and not marks.has(r[4]):
			marks[r[4]] = int(r[0])
		elif r[2] == "MERKSPRONG" and not jumps.has(r[4]):
			jumps[r[4]] = int(r[0])
	var worst := 0
	var worst_id := ""
	var no_jump := 0
	for id: String in marks:
		var t0: int = marks[id]
		var t1: int = jumps.get(id, t0 + d + 30)
		if not jumps.has(id):
			no_jump += 1
		for s: Array in stills:
			var n := mini(int(s[1]), t1) - maxi(int(s[0]), t0)
			if n > worst:
				worst = n
				worst_id = id
	var k2_long := 0
	var k2_at: Array = []
	for s: Array in stills:
		if s[2] == "K2" and s[1] - s[0] > k2_long:
			k2_long = s[1] - s[0]
			k2_at = s
	print("  K2: %d merken, %d met merksprong; langste stilstand tussen merk en merksprong: %d ticks (merk %s); langste stilstand in K2: %d%s" % [
		marks.size(), marks.size() - no_jump, worst, worst_id, k2_long,
		"" if k2_at.is_empty() else " (x %d, tick %d)" % [int(k2_at[3]), k2_at[0]]])


func _k3(rows: Array, stills: Array, gemaal: int, run_end: int) -> void:
	var parts := PackedStringArray()
	var sluice := 0
	for s: Array in stills:
		if s[2] != "K3":
			continue
		var n: int = s[1] - s[0]
		var x: float = s[3]
		var place := "elders"
		if x >= 2000.0 and x <= 2026.0 + 8.0 and s[4] < 400.0:
			place = "bovenste trede"
		elif x >= 1440.0 and x <= 1540.0:
			place = "sluis"
			sluice = maxi(sluice, n)
		else:
			for v: float in VANES:
				if absf(x - v) <= 40.0:
					place = "schoep %d" % int(v)
		if n >= 30 or place == "bovenste trede":
			parts.append("%d ticks %s (x %d, y %d)" % [n, place, int(x), int(s[4])])
	# Landing op de bovenste trede: een K3-binnenkomst bij x 2000–2034 die binnen
	# 60 ticks weer K2 wordt (sprong terug), of een stilstand daar.
	var top := PackedStringArray()
	for i in rows.size():
		var r: Array = rows[i]
		if r[2] != "KAMER" or r[4] != "K3":
			continue
		var x := float(r[5])
		for j in range(i + 1, rows.size()):
			var q: Array = rows[j]
			if q[2] == "KAMER":
				if q[4] == "K2" and int(q[0]) - int(r[0]) < 60:
					top.append("tick %d (x %d): na %d ticks terug in K2" % [int(r[0]), int(x), int(q[0]) - int(r[0])])
				break
	print("  K3: stilstand ≥ 30 of op de trede: %s" % (", ".join(parts) if not parts.is_empty() else "geen"))
	print("  K3: kort in K3 en terug naar K2 (bovenste trede, sprong omhoog): %s" % (", ".join(top) if not top.is_empty() else "nee"))
	print("  K3: stilstand bij de sluis %d ticks (LM-04 ≤ 30); GEMAAL_VOL op %d, RUN_EIND %d ticks later" % [
		sluice, gemaal, run_end - gemaal if gemaal >= 0 else -1])
