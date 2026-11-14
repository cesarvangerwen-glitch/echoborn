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
##   - per kamer MP-1, MP-2, MP-4 (S8 mét de boss) en F4b(b) (S8 alleen de route) (T11 Q-1,
##     `docs/qa/testplan-t11-slice.md` §3.1, W38, W40);
##   - RV-2 (stuiten boven het kanaal van S7) en RV-4 (de lege loop na S3);
##   - RV-1: de hangtijd boven de echo per keerpunt (W33), uit het hanglog
##     van `botlogs.gd` (`hang_*.csv`); een meetlog van de CEO heeft geen
##     hanglog, dan alleen de uitkomst A–D;
##   - echo-acties per soort en per kamer; `DEBUG`, `RESPAWN`, `BREEK`;
##   - **gaten en rustpunt** (besluit LGD over B-1, #83): daar telt ook een
##     `POMP` van de echo als echo-moment; MP-2 blijft zonder `POMP` (gdd §4.5).
##     Plus het gat van de laatste pompslag van de echo bij trap 2 tot de
##     eerste echo-actie in S9 (de wandeling na trap 2, kaart vraag 9b, RV-6);
##     pompte de echo bij trap 2 niet (in de kamer van `TRAP_VOL 2`, bij dat
##     bezoek), dan vanaf de laatste `POMP` van P1 (T11 Q-2).
##
## Co-op (T11 Q-3, `docs/qa/testplan-t11-slice.md` §4.1): een meetlog met bron
## `p2` is co-op. P2 is dan het tweede lichaam: de `POMP` van P2 telt voor de
## gaten en RV-6 (W39), LP met bron `_p2` of uit een samenwerkingsactie
## (`springplank`, `bounce`, `lancering`, `vangen`, `ontploffing`) telt als LP
## met het tweede lichaam (MP-6, F4b(b) (3)), en MP-4 vervalt (geen echo).
## Extra: per kamer MP-7 (a)–(d) (W38), met MP-1 van P2 uit `STIL_EIND` bron
## `p2` en de tijd dat P2 opgelost is uit `P2_OPGELOST` … `P2_TERUG`/`DROP_OUT`.
## MP-7 (a) per kamer tegen de solo-lus van dezelfde D in dezelfde map
## (`bot_*lus*.csv` zonder bron `p2`), alleen voor een lus. Zelfde
## rekenregels als `game/tests/test_kadewijk_coop.gd`, behalve MP-1 per kamer:
## hier het deel van een stilstand dat in de kamer valt (zoals Q-1), daar de
## stilstand die in de kamer eindigt.
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
## LP-bronnen van een samenwerkingsactie (co-op, MP-6; zoals `test_kadewijk_coop.gd`).
const COOP_LP := ["springplank", "bounce", "lancering", "vangen", "ontploffing"]

## Co-op (Q-3): kamertijden van de solo-lus per D, voor MP-7 (a).
var solo_ref := {}


func _init() -> void:
	var dirs := OS.get_cmdline_user_args()
	var todo: Array = []
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
				todo.append([file_name, _read(dir_path.path_join(file_name), 7), hang])
	# Eerst de solo-lussen van de bot als referentie voor MP-7 (a) (Q-3).
	for item: Array in todo:
		var rows: Array = item[1]
		if item[0].begins_with("bot_") and item[0].contains("lus") and not _is_coop(rows):
			var d := _d_of(item[0], rows)
			if not solo_ref.has(d):
				var segs := _room_segs(rows, _first(rows, "RUN_START"), maxi(_first(rows, "RUN_EIND"), int(rows[rows.size() - 1][0])),
					_first(rows, "BOSS_START"), _first(rows, "BOSS_VERSLAGEN"))
				var ticks := {}
				for k: String in segs:
					ticks[k] = _seg_ticks(segs[k])
				solo_ref[d] = ticks
	for item: Array in todo:
		_report(item[0], item[1], item[2])
	quit()


func _is_coop(rows: Array) -> bool:
	for r: Array in rows:
		if r[4] == "p2":
			return true
	return false


## LP met het tweede lichaam: solo de echo (bron `_echo`), co-op P2 of een
## samenwerkingsactie (MP-6, F4b(b) (3)).
func _lp_second(src: String, coop: bool) -> bool:
	if not coop:
		return src.ends_with("_echo")
	var parts := src.rsplit("_", true, 1)
	return parts[parts.size() - 1] == "p2" or parts[0] in COOP_LP


## De bron van het tweede lichaam: de echo, of in co-op P2.
func _second(coop: bool) -> String:
	return "p2" if coop else "echo"


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


## Echo-momenten voor de gaten en het rustpunt (LGD, B-1): de MP-2-acties plus
## elke `POMP` van de echo (co-op: van P2, W39).
func _moments(rows: Array, acts: Array, coop: bool) -> Array:
	var out: Array = acts.duplicate()
	for r: Array in rows:
		if r[2] == "POMP" and r[4] == _second(coop):
			out.append([int(r[0]), r[1], "POMP"])
	out.sort_custom(func(a, b) -> bool: return a[0] < b[0])
	return out


func _report(file_name: String, rows: Array, hang: Array) -> void:
	var d := _d_of(file_name, rows)
	var rep = FlowReport.from_rows(rows, true)
	var start := _first(rows, "RUN_START")
	var end := maxi(_first(rows, "RUN_EIND"), rep.end)
	var boss_a := _first(rows, "BOSS_START")
	var boss_b := _first(rows, "BOSS_VERSLAGEN")
	var in_boss := func(t: int) -> bool: return boss_a >= 0 and t >= boss_a and (boss_b < 0 or t <= boss_b)
	var coop := _is_coop(rows)
	var acts := _actions(rows)
	var moments := _moments(rows, acts, coop)
	print("\n=== %s (D = %d%s) ===" % [file_name, d, ", co-op: P1 + P2, P2 als tweede lichaam" if coop else ""])
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
		for a: Array in moments:
			if a[0] > s9_in and a[0] <= s9_end and a[1] == "S9":
				gaps.append(a[0] - last)
				last = a[0]
		gaps.append(s9_end - last)
		var ok := gaps.size() > 0 and gaps[0] <= S9_RUST
		for i in range(1, gaps.size()):
			ok = ok and gaps[i] <= S9_GAT
		print("  S9 gaten vanaf binnenkomst %d (met POMP van %s): %s · rustpunt ≤ %d, daarna ≤ %d: %s" % [s9_in, "P2" if coop else "de echo", gaps, S9_RUST, S9_GAT, "ja" if ok else "NEE"])
	# Langste gat zonder echo-moment (met POMP van de echo), naast MP-2.
	var gap_m := 0
	var gap_at := start
	var prev := start
	for a: Array in moments:
		if a[0] - prev > gap_m:
			gap_m = a[0] - prev
			gap_at = prev
		prev = a[0]
	print("  langste gat zonder echo-moment (met POMP van %s): %d ticks (%.1f s) vanaf tick %d" % ["P2" if coop else "de echo", gap_m, gap_m / 60.0, gap_at])
	# Na trap 2 (RV-6): laatste POMP van de echo (co-op: P2) bij trap 2 → eerste echo-actie in S9.
	# "Bij trap 2" = in de kamer van TRAP_VOL 2, vanaf de laatste binnenkomst daar tot 120
	# ticks na TRAP_VOL. Pompte de echo daar niet, dan vanaf de laatste POMP van P1 (Q-2).
	var trap2 := -1
	var trap2_room := ""
	for r: Array in rows:
		if r[2] == "TRAP_VOL" and r[3] == "2":
			trap2 = int(r[0])
			trap2_room = r[1]
	if trap2 >= 0:
		var visit := start
		for r: Array in rows:
			if int(r[0]) > trap2:
				break
			if r[2] == "KAMER" and r[4] == trap2_room:
				visit = int(r[0])
		var who := "de echo" if not coop else "P2"
		var last_pomp := -1
		for r: Array in rows:
			if r[2] == "POMP" and r[4] == _second(coop) and int(r[0]) >= visit and int(r[0]) <= trap2 + 120:
				last_pomp = int(r[0])
		if last_pomp < 0:
			who = "P1 (%s pompte niet bij trap 2, Q-2)" % who
			for r: Array in rows:
				if r[2] == "POMP" and r[4] == "p1" and int(r[0]) >= visit and int(r[0]) <= trap2 + 120:
					last_pomp = int(r[0])
		var first_s9 := -1
		for a: Array in acts:
			if a[0] > last_pomp and a[1] == "S9":
				first_s9 = a[0]
				break
		print("  na trap 2 (RV-6): laatste pompslag van %s %d → eerste echo-actie in S9 %d: %d ticks (%.1f s; rustpunt ± 12 s, gat < 40 s)" % [
			who, last_pomp, first_s9, first_s9 - last_pomp, (first_s9 - last_pomp) / 60.0])

	# --- punt 4: MP-3, MP-4, MP-6 ---
	if coop:
		var lp_t := 0
		var lp_s := 0
		var pumps_p2 := 0
		for r: Array in rows:
			if r[2] == "LP":
				var n := int(str(r[3]).trim_prefix("+"))
				lp_t += n
				if _lp_second(str(r[4]), true):
					lp_s += n
			elif r[2] == "POMP" and r[4] == "p2":
				pumps_p2 += 1
		print("MP-3 %.0f %% van %d landingen zonder stilstand van de springer · MP-4 — (co-op: geen echo; zie MP-7 (d)) · MP-6 %.0f %% van %d LP met P2 of samen, %d pompslagen van P2 · SL-01 %d LP vóór de eerste pompslag · BREEK %d · RESPAWN %d · DEBUG %d" % [
			rep.landings_without_still * 100.0, rep.landings, 100.0 * lp_s / maxf(lp_t, 1.0), lp_t, pumps_p2, _lp_before_pump(rows),
			rep.breaks, rows.filter(func(r) -> bool: return r[2] == "RESPAWN").size(),
			rows.filter(func(r) -> bool: return r[2] == "DEBUG").size()])
	else:
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
				if _lp_second(str(r[4]), coop):
					lp_echo += n
	var mins := maxf(route, 1.0) / MINUTE
	var f1 := n_act / mins
	var f2a := n_plank / mins
	var f2b := n_boom / mins
	var f3 := float(lp_echo) / maxf(lp_all, 1.0)
	print("F4b(b) route-tijd %.1f s: (1) %.2f echo-acties/min (≥ 2,0) · (2) springplank %.2f/min (≥ 1,0), ontploffingen %.2f/min (≥ 0,5) · (3) %.0f %% van %d LP met %s (≥ 30 %%) → %s" % [
		route / 60.0, f1, f2a, f2b, f3 * 100.0, lp_all, "P2 of samen" if coop else "de echo",
		"positief" if f1 >= 2.0 and f2a >= 1.0 and f2b >= 0.5 and f3 >= 0.3 else "NEGATIEF"])

	# --- Q-1 (T11 §6): MP-1, MP-2, MP-4 en F4b(b) per kamer, de boss apart (W38) ---
	_per_room(rows, rep, start, end, boss_a, boss_b, acts, coop)
	if coop:
		_per_room_coop(file_name, d, rows, rep, start, end, boss_a, boss_b, acts)

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


## Q-1 (testplan T11 §6): per kamer MP-1, MP-2, MP-4 en F4b(b), met de boss als
## eigen rij (W38). Een kamer = alle stukken van `KAMER` tot het volgende
## `KAMER` met die naam (ook een tweede bezoek, zoals S5/S6 bij trap 2), half
## open [begin, eind). **S8 telt voor F4 (MP-1, MP-2, MP-4) mét de boss**
## (`testplan-mt2.md` §3: de normen van P1 gelden ook in het gevecht); de rij
## "S8 route" (zonder `BOSS_START` … `BOSS_VERSLAGEN`) is alleen voor F4b(b)
## (gdd §5.1, W38), de rij "boss" alleen ter informatie. Events tellen naar hun
## tick, niet naar de kamerkolom; MP-2 per kamer is zo gelijk aan MP-2 per kamer
## van FlowReport. Definities zoals over de doorloop:
## MP-1 = langste stilstand van P1 binnen de stukken (een stilstand over een
## kamergrens telt per kamer voor het deel dat erin valt); MP-4 = de tijd dat
## de echo Leeg is (vanaf `RUN_START` tot de eerste `ECHO_LEEG_EIND`, en elke
## `ECHO_LEEG_START` … `ECHO_LEEG_EIND`) gedeeld door de kamertijd; F4b(b)
## zoals de regel F4b(b) hierboven, met de kamertijd als route-tijd.
func _per_room(rows: Array, rep, start: int, end: int, boss_a: int, boss_b: int, acts: Array, coop: bool) -> void:
	var segs := _room_segs(rows, start, end, boss_a, boss_b)
	var has_boss := boss_a >= 0 and boss_b >= 0
	# Per rij: "alles" = F4 en F4b(b); "f4" = alleen F4; "f4b" = alleen F4b(b).
	var mode := {}
	if has_boss and segs.has("S8"):
		mode["S8"] = "f4"
		mode["S8 route"] = "f4b"
	# De echo Leeg: [begin, eind) zoals FlowReport. Co-op: geen echo, MP-4 vervalt.
	var empty: Array = []
	var empty_since := start if not coop else -1
	for r: Array in rows:
		match r[2]:
			"ECHO_LEEG_START":
				if empty_since < 0:
					empty_since = int(r[0])
			"ECHO_LEEG_EIND":
				if empty_since >= 0:
					empty.append([empty_since, int(r[0])])
					empty_since = -1
	if empty_since >= 0:
		empty.append([empty_since, end])
	var order: Array = []
	for room in Layout.ORDER:
		order.append(String(room))
	if has_boss:
		mode["boss"] = "boss"
		order.insert(order.find("S8") + 1, "S8 route")
		order.insert(order.find("S8") + 2, "boss")
	var lines := PackedStringArray()
	lines.append("| kamer | tijd (s) | MP-1 (≤ 300) | MP-2 /min (≥ 3,0) | MP-4 Leeg (≤ 40 %%) | F4b(b) (1) acties/min (≥ 2,0) | (2) plank · ontploffing /min (≥ 1,0 · ≥ 0,5) | (3) LP met %s (≥ 30 %%) | F4b(b) |" % ("P2 of samen" if coop else "de echo"))
	lines.append("|---|---|---|---|---|---|---|---|---|")
	for k: String in order:
		if not segs.has(k):
			continue
		var s: Array = segs[k]
		var t := 0
		for seg: Array in s:
			t += seg[1] - seg[0]
		if t <= 0:
			continue
		var mins := t / MINUTE
		# MP-1: stilstanden van P1 zijn [begin, eind] inclusief.
		var still := 0
		for run: Array in rep.still_runs:
			for seg: Array in s:
				still = maxi(still, mini(int(run[1]) + 1, seg[1]) - maxi(int(run[0]), seg[0]))
		var leeg := 0
		for e: Array in empty:
			for seg: Array in s:
				leeg += maxi(0, mini(e[1], seg[1]) - maxi(e[0], seg[0]))
		var n_act := 0
		for a: Array in acts:
			if _in_segs(s, a[0]):
				n_act += 1
		var n_plank := 0
		var n_boom := 0
		var lp_all := 0
		var lp_echo := 0
		var contacts := {}
		for r: Array in rows:
			if not _in_segs(s, int(r[0])):
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
					if _lp_second(str(r[4]), coop):
						lp_echo += n
		var f1 := n_act / mins
		var f2a := n_plank / mins
		var f2b := n_boom / mins
		var lp_txt := "%.0f %% van %d" % [100.0 * lp_echo / lp_all, lp_all] if lp_all > 0 else "geen LP"
		var m: String = mode.get(k, "alles")
		var verdict := "telt niet (gdd §5.1)"
		if m == "f4":
			verdict = "zie S8 route"
		elif m != "boss":
			var miss := PackedStringArray()
			if f1 < 2.0:
				miss.append("(1)")
			if f2a < 1.0:
				miss.append("(2) plank")
			if f2b < 0.5:
				miss.append("(2) ontploffing")
			if lp_all > 0 and float(lp_echo) / lp_all < 0.3:
				miss.append("(3)")
			verdict = "positief" if miss.is_empty() else "mist " + ", ".join(miss)
		var f4 := "%d%s | %.1f%s | %s" % [still, "" if still <= 300 else " **> 300**", f1,
			"" if f1 >= 3.0 else " **< 3,0**", "%.1f %%" % (100.0 * leeg / t) if not coop else "— (co-op)"]
		if m == "f4b":
			f4 = "— | — | —"
		elif m == "boss":
			f4 = "(%s)" % f4.replace(" | ", ") | (")
		var f4b := "%.1f | %.1f · %.1f | %s" % [f1, f2a, f2b, lp_txt]
		if m == "f4" or m == "boss":
			f4b = "— | — | —"
		lines.append("| %s | %.1f | %s | %s | %s |" % [k, t / 60.0, f4, f4b, verdict])
	print("per kamer (Q-1; F4 met S8 mét de boss, testplan-mt2 §3; F4b(b) met de S8-route, W38; boss = informatie):\n%s" % "\n".join(lines))


## De stukken per kamer (W38): `KAMER` tot `KAMER` (ook een tweede bezoek), half
## open. Met een boss: "S8" mét de boss, "S8 route" zonder, "boss" apart, en de
## andere kamers zonder de boss-ticks.
func _room_segs(rows: Array, start: int, end: int, boss_a: int, boss_b: int) -> Dictionary:
	var segs := {}
	var room_now := ""
	var since := start
	for r: Array in rows:
		match r[2]:
			"RUN_START":
				room_now = r[1]
				since = int(r[0])
			"KAMER":
				_add_seg(segs, room_now, since, int(r[0]))
				room_now = r[4]
				since = int(r[0])
	_add_seg(segs, room_now, since, end)
	if boss_a >= 0 and boss_b >= 0:
		for k: String in segs.keys():
			if k == "S8":
				segs["S8 route"] = _minus(segs["S8"], boss_a, boss_b)
			else:
				segs[k] = _minus(segs[k], boss_a, boss_b)
		segs["boss"] = [[boss_a, boss_b]]
	return segs


func _seg_ticks(s: Array) -> int:
	var t := 0
	for seg: Array in s:
		t += seg[1] - seg[0]
	return t


## SL-01 (L-14 c): LP van `RUN_START` tot de eerste pompslag (van wie ook).
func _lp_before_pump(rows: Array) -> int:
	var n := 0
	for r: Array in rows:
		if r[2] == "POMP":
			return n
		if r[2] == "LP":
			n += int(str(r[3]).trim_prefix("+"))
	return n


## Q-3 (testplan T11 §4.1): MP-7 (a)–(d) per kamer in co-op, de boss apart (W38).
## (a) tijd co-op / tijd solo-lus van dezelfde D (≥ 0,5; alleen voor een lus);
## (b) MP-1 van P1 én P2 ≤ 300 (deel van een stilstand in de kamer, zoals Q-1);
## (c) samenwerkingsacties per minuut ≥ 1,0 (de MP-2-acties: elke actie is er
## een van beide spelers); (d) de tijd dat P2 opgelost is ≤ 10 %. Plus MP-6
## (LP met P2 of samen). "S8 route" (arena in en uit) zonder (c), zoals de test.
func _per_room_coop(file_name: String, d: int, rows: Array, rep, start: int, end: int, boss_a: int, boss_b: int, acts: Array) -> void:
	var segs := _room_segs(rows, start, end, boss_a, boss_b)
	var ref: Dictionary = solo_ref.get(d, {}) if file_name.contains("lus") else {}
	# P2 opgelost: [P2_OPGELOST, P2_TERUG of DROP_OUT).
	var gone: Array = []
	var gone_since := -1
	for r: Array in rows:
		match r[2]:
			"P2_OPGELOST":
				if gone_since < 0:
					gone_since = int(r[0])
			"P2_TERUG", "DROP_OUT":
				if gone_since >= 0:
					gone.append([gone_since, int(r[0])])
					gone_since = -1
	if gone_since >= 0:
		gone.append([gone_since, end])
	var order: Array = []
	for room in Layout.ORDER:
		order.append(String(room))
	if segs.has("boss"):
		order.insert(order.find("S8") + 1, "S8 route")
		order.insert(order.find("S8") + 2, "boss")
	segs["doorloop"] = [[start, end]]
	order.append("doorloop")
	if segs.has("boss"):
		segs["route"] = _minus([[start, end]], boss_a, boss_b)
		order.append("route")
	var lines := PackedStringArray()
	lines.append("| kamer | tijd co-op (s) | (a) co-op / solo (≥ 0,5) | MP-1 P1 (≤ 300) | (b) MP-1 P2 (≤ 300) | (c) samen /min (≥ 1,0) | (d) P2 opgelost (≤ 10 %) | MP-6 LP met P2 of samen | MP-7 |")
	lines.append("|---|---|---|---|---|---|---|---|---|")
	for k: String in order:
		if not segs.has(k):
			continue
		var s: Array = segs[k]
		var t := _seg_ticks(s)
		if t <= 0:
			continue
		var p1 := 0
		for run: Array in rep.still_runs:
			for seg: Array in s:
				p1 = maxi(p1, mini(int(run[1]) + 1, seg[1]) - maxi(int(run[0]), seg[0]))
		var p2 := 0
		for run: Array in rep.still_runs_p2:
			for seg: Array in s:
				p2 = maxi(p2, mini(int(run[1]) + 1, seg[1]) - maxi(int(run[0]), seg[0]))
		var n := 0
		for a: Array in acts:
			if _in_segs(s, a[0]):
				n += 1
		var off := 0
		for g: Array in gone:
			for seg: Array in s:
				off += maxi(0, mini(g[1], seg[1]) - maxi(g[0], seg[0]))
		var lp_all := 0
		var lp_s := 0
		for r: Array in rows:
			if r[2] == "LP" and _in_segs(s, int(r[0])):
				var v := int(str(r[3]).trim_prefix("+"))
				lp_all += v
				if _lp_second(str(r[4]), true):
					lp_s += v
		var key := "S8" if k == "doorloop" else k
		var ratio := "—"
		var ratio_v := -1.0
		if k == "doorloop" and not ref.is_empty():
			var tot := 0
			for rk: String in ref:
				if rk != "S8 route" and rk != "boss":
					tot += int(ref[rk])
			ratio_v = float(t) / maxf(tot, 1.0)
		elif k != "route" and ref.has(key) and k != "doorloop":
			ratio_v = float(t) / maxf(float(ref[key]), 1.0)
		if ratio_v >= 0.0:
			ratio = "%.2f×" % ratio_v
		var c := n * MINUTE / t
		var miss := PackedStringArray()
		if ratio_v >= 0.0 and ratio_v < 0.5:
			miss.append("(a)")
		if p1 > 300:
			miss.append("MP-1 P1")
		if p2 > 300:
			miss.append("(b)")
		if c < 1.0 and k != "S8 route":
			miss.append("(c)")
		if float(off) / t > 0.10:
			miss.append("(d)")
		var c_txt := "%.1f" % c if k != "S8 route" else "(%.1f)" % c
		lines.append("| %s | %.1f | %s | %d%s | %d%s | %s%s | %.1f %% | %s | %s |" % [k, t / 60.0, ratio,
			p1, "" if p1 <= 300 else " **> 300**", p2, "" if p2 <= 300 else " **> 300**", c_txt,
			" **< 1,0**" if c < 1.0 and k != "S8 route" else "", 100.0 * off / t,
			"%.0f %% van %d" % [100.0 * lp_s / lp_all, lp_all] if lp_all > 0 else "geen LP",
			"gehaald" if miss.is_empty() else "mist " + ", ".join(miss)])
	print("co-op per kamer (Q-3; MP-7 (a)–(d), W38; S8 route zonder (c); solo-referentie %s):\n%s" % [
		"D = %d" % d if not ref.is_empty() else "geen", "\n".join(lines)])


func _add_seg(segs: Dictionary, room: String, a: int, b: int) -> void:
	if room == "" or b <= a:
		return
	if not segs.has(room):
		segs[room] = []
	segs[room].append([a, b])


## De stukken zonder [a, b) (de boss).
func _minus(s: Array, a: int, b: int) -> Array:
	var out: Array = []
	for seg: Array in s:
		if seg[1] <= a or seg[0] >= b:
			out.append(seg)
			continue
		if seg[0] < a:
			out.append([seg[0], a])
		if seg[1] > b:
			out.append([b, seg[1]])
	return out


func _in_segs(s: Array, t: int) -> bool:
	for seg: Array in s:
		if t >= seg[0] and t < seg[1]:
			return true
	return false


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
