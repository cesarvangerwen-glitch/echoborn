extends RefCounted
## Tests voor het meetlog (gdd §4.5) dat T16b nodig heeft voor norm (1)
## (MP-1, stilstand), norm (2) (MP-2, echo-acties) en R-V12 (MP-3).
## T16a deel 2, #76. MP-1 voor P2 (MP-7 b, werkaanname W5): #125.

const Fx = preload("res://tests/echo_fixture.gd")
const InputBits = preload("res://scripts/input/input_bits.gd")
const Meetlog = preload("res://scripts/events/meetlog.gd")
const CombatTarget = preload("res://scripts/combat/combat_target.gd")
const PlayerActor = preload("res://scripts/echo/player_actor.gd")
const FlowReport = preload("res://levels/flowkamer/flow_report.gd")

const L := InputBits.LEFT
const R := InputBits.RIGHT
const J := InputBits.JUMP
const A := InputBits.ATTACK
const E := InputBits.ECHO

## P1 slaat een vijand (merk), springt op zijn echo, bounct, landt weer op
## de echo (tweede landing zonder grond: n = 2) en laat later los.
const RUN := [[10, 0], [1, A], [89, 0], [1, J], [39, 0], [1, J], [159, 0], [30, E], [80, 0]]


func _run(t, d: int) -> Meetlog:
	var sim = Fx.world(t)
	Fx.target(sim, CombatTarget.Kind.ENEMY, 220.0)
	var p1 := Fx.p1(sim, RUN)
	var echo := Fx.tail_echo(sim, p1, d)
	var log := Meetlog.new(sim, p1, echo)
	await t.run_ticks(sim, 410)
	log.finish()
	return log


## Twee runs met dezelfde input en D geven hetzelfde log; het log bevat de
## events van MP-1 tot MP-4 die deze run oplevert.
func test_log_is_deterministic_and_complete(t) -> void:
	var first := await _run(t, 90)
	await t.cleanup()
	var second := await _run(t, 90)
	t.check(first.to_csv() == second.to_csv(), "twee runs gaven een ander log")
	t.check(first.to_csv().begins_with(Meetlog.HEADER), "kopregel ontbreekt")
	for event in ["RUN_START", "RUN_EIND", "MERK_GEZET", "MERKSPRONG", "ONTPLOFFING", "SPRINGPLANK",
			"BOUNCE", "ECHO_LEEG_START", "ECHO_LEEG_EIND", "LOSLATEN", "STIL_START", "STIL_EIND"]:
		t.check(first.count(event) >= 1, "event %s ontbreekt" % event)
	var chain: Array = []
	for row in first.rows:
		if row[2] == "SPRINGPLANK" or row[2] == "VANGEN":
			chain.append(row[3])
	t.check(chain.slice(0, 2) == ["1", "2"], "springplank-reeks %s (1, 2)" % str(chain))
	t.check(_rows_of(first, "p2").is_empty(), "solo: regels met bron p2")
	t.check(first.save("user://meetlog_test_solo_D90_p1.csv") == OK, "log niet opgeslagen")
	t.note("%d regels, %d springplank-landingen" % [first.rows.size(), first.count("SPRINGPLANK")])


func _still_lengths(log: Meetlog) -> Array:
	var lengths: Array = []
	for row in log.rows:
		if row[2] == "STIL_EIND":
			lengths.append(int(row[3]))
	return lengths


## MP-1: stilstaand slaan telt als stilstand; wiebelen ook. Keren tegen een
## muur geeft volgens de definitie 3–4 stille ticks (bij 2 px/tick is 24 px
## twaalf ticks lopen; gdd §4.6 MP-1 (5) zegt "hooguit 2"), maar nooit een
## stilstand van 20 ticks. Ter plaatse springen (elke 40 ticks)
## geeft volgens de definitie van MP-1 per sprong 2 stille ticks (het venster
## t − 30 … t blijft vlak voor de landing binnen 24 px van zijn begin, want de
## sprong is 50 px hoog); gdd §4.6 MP-1 (4) verwacht er 0. Beide als vraag
## aan de LGD; de test eist hier wat de definitie geeft.
func test_mp1_still_ticks(t) -> void:
	var cases := {
		"slaan": [[40, R]] + _repeat([[1, A], [19, 0]], 30),
		"wiebelen": [[40, R]] + _repeat([[6, L], [6, R]], 25),
		"springen": _repeat([[1, J], [39, 0]], 8),
		"keren": [[100, R], [100, L]],  # muur zo dat P1 hem op tick 100 raakt
	}
	for name: String in cases:
		var sim = Fx.world(t)
		if name == "keren":
			Fx.block(t, "Wall", Rect2(408, 300, 20, 100), 1)
		var p1 := Fx.p1(sim, cases[name])
		var log := Meetlog.new(sim, p1, null)
		var ticks := {"slaan": 640, "wiebelen": 320, "springen": 300, "keren": 200}
		await t.run_ticks(sim, ticks[name])
		log.finish()
		var lengths := _still_lengths(log)
		match name:
			"slaan":
				t.check(lengths.size() == 1 and lengths[0] >= 570, "slaan: stilstanden %s (één, ≥ 570)" % str(lengths))
			"wiebelen":
				t.check(lengths.size() == 1 and lengths[0] >= 230, "wiebelen: stilstanden %s (één lange)" % str(lengths))
			"springen":
				var longest: int = lengths.max() if not lengths.is_empty() else 0
				t.check(longest <= 2, "springen: stilstanden %s (≤ 2 ticks)" % str(lengths))
				t.note("ter plaatse springen: stilstanden %s (zie vraag aan de LGD)" % str(lengths))
			"keren":
				var total := 0
				for n: int in lengths:
					total += n
				t.check(total <= 4 and (lengths.is_empty() or lengths.max() < 20),
					"keren tegen de muur: stilstanden %s (≤ 4 stille ticks, geen 20)" % str(lengths))
				t.note("keren tegen de muur: stilstanden %s (zie vraag aan de LGD)" % str(lengths))
		await t.cleanup()


func _repeat(segments: Array, times: int) -> Array:
	var out: Array = []
	for i in times:
		out += segments
	return out


# --- MP-1 voor P2 (MP-7 b, #125) ---------------------------------------------

## STIL_START/STIL_EIND met deze bron, als [tick, event, waarde].
func _rows_of(log: Meetlog, source: String) -> Array:
	var out: Array = []
	for row in log.rows:
		if (row[2] == "STIL_START" or row[2] == "STIL_EIND") and row[4] == source:
			out.append([int(row[0]), row[2], row[3]])
	return out


func _coop(t, p1_at: Vector2, p2_at: Vector2) -> Array:
	var sim = Fx.world(t)
	var p1 := Fx.manual_player(sim, 1, p1_at)
	var p2 := Fx.manual_player(sim, 2, p2_at)
	return [sim, p1, p2, Meetlog.new(sim, p1, null)]


func _bits(p: PlayerActor, bits: int) -> void:
	(p.input_source as Fx.ManualInput).bits = bits


## W5: voor P2 geldt dezelfde definitie als voor P1. Beide staan 200 ticks
## stil en lopen dan elk een kant op: dezelfde stilstand, met bron p1 en p2.
func test_mp1_p2_same_definition_as_p1(t) -> void:
	var c := _coop(t, Vector2(300, Fx.STAND_Y), Vector2(340, Fx.STAND_Y))
	var sim: Node = c[0]
	var log: Meetlog = c[3]
	await t.run_ticks(sim, 200)
	_bits(c[1], L)
	_bits(c[2], R)
	await t.run_ticks(sim, 40)
	log.finish()
	var p1_rows := _rows_of(log, "p1")
	var p2_rows := _rows_of(log, "p2")
	t.check(p1_rows.size() == 2 and p2_rows == p1_rows,
		"P1 %s, P2 %s (gelijk, één stilstand)" % [str(p1_rows), str(p2_rows)])
	var rep = FlowReport.from_rows(log.rows, false)
	t.check(rep.longest_still_p2 == rep.longest_still and rep.longest_still >= 150,
		"rapport: P1 %d, P2 %d" % [rep.longest_still, rep.longest_still_p2])
	t.note("stilstand P1 en P2: %s" % str(p2_rows))
	await t.cleanup()


## W5: P2 staat stil tot hij oplost; de stilstand sluit op de tick van het
## oplossen, opgeloste ticks tellen niet en na P2_TERUG gelden 60 ticks niet.
## P1 loopt intussen heen en weer (bron p1 staat los van bron p2).
func test_mp1_p2_dissolved_and_return_grace(t) -> void:
	var c := _coop(t, Vector2(300, Fx.STAND_Y), Vector2(340, Fx.STAND_Y))
	var sim: Node = c[0]
	var log: Meetlog = c[3]
	var back: Array = []
	sim.partner_returned.connect(func(tick: int, _at: Vector2) -> void: back.append(tick))
	await t.run_ticks(sim, 150)
	var gone_tick: int = sim.tick
	sim.dissolve_partner("val")
	while back.is_empty() and sim.tick < gone_tick + 200:
		await t.run_ticks(sim, 1)
	await t.run_ticks(sim, 150)
	log.finish()
	var rows := _rows_of(log, "p2")
	t.check(not back.is_empty(), "P2 kwam niet terug")
	if back.is_empty() or rows.size() < 3:
		t.check(false, "P2-stilstanden %s (verwacht: vóór en na het oplossen)" % str(rows))
		await t.cleanup()
		return
	var back_tick: int = back[0]
	t.check(rows[1][1] == "STIL_EIND" and rows[1][0] == gone_tick,
		"stilstand vóór oplossen eindigt op %s (oplossen op %d)" % [str(rows[1]), gone_tick])
	t.check(int(rows[1][2]) == gone_tick - rows[0][0], "lengte %s telt opgeloste ticks" % str(rows[1]))
	t.check(rows[2][1] == "STIL_START" and rows[2][0] == back_tick + Meetlog.RESPAWN_GRACE,
		"na P2_TERUG (%d) begint de stilstand op %s (verwacht %d)"
		% [back_tick, str(rows[2]), back_tick + Meetlog.RESPAWN_GRACE])
	for row in rows:
		t.check(row[0] <= gone_tick or row[0] >= back_tick + Meetlog.RESPAWN_GRACE,
			"P2-regel %s tijdens oplossen of de 60 ticks erna" % str(row))
	await t.cleanup()


## Drop-out sluit een open stilstand van P2; RUN_EIND ook. START en EIND van
## P2 staan altijd in paren, en een nieuwe P2 begint opnieuw.
func test_mp1_p2_closed_at_drop_out_and_run_end(t) -> void:
	var c := _coop(t, Vector2(300, Fx.STAND_Y), Vector2(340, Fx.STAND_Y))
	var sim: Node = c[0]
	var p1: PlayerActor = c[1]
	var log: Meetlog = c[3]
	await t.run_ticks(sim, 100)
	var out_tick: int = sim.tick
	sim.drop_out()
	await t.run_ticks(sim, 20)
	var rows := _rows_of(log, "p2")
	t.check(rows.size() == 2 and rows[1][1] == "STIL_EIND" and rows[1][0] == out_tick,
		"drop-out op %d: P2-stilstanden %s" % [out_tick, str(rows)])
	var p2 := Fx.manual_player(sim, 2, p1.position + Vector2(40, 0))
	var in_tick: int = sim.tick
	await t.run_ticks(sim, 80)
	log.finish()
	rows = _rows_of(log, "p2")
	t.check(rows.size() == 4 and rows[2][1] == "STIL_START" and rows[2][0] >= in_tick + Meetlog.STILL_WINDOW
		and rows[3][1] == "STIL_EIND" and rows[3][0] == sim.tick - 1,
		"nieuwe P2 (in op %d): %s" % [in_tick, str(rows)])
	t.check(p2 != null, "geen nieuwe P2")
	await t.cleanup()


## Achterwaarts leesbaar: een log zonder regels met bron p2 (zoals vóór #125)
## geeft hetzelfde MP-1 voor P1 en 0 voor P2; regels met bron p2 veranderen
## MP-1 en MP-3 van P1 niet.
func test_report_reads_old_and_new_logs(t) -> void:
	var old := [["0", "K1", "RUN_START", "", "", "0", "0"],
		["100", "K1", "STIL_START", "", "p1", "0", "0"],
		["180", "K1", "STIL_EIND", "80", "p1", "0", "0"],
		["600", "K1", "RUN_EIND", "", "", "0", "0"]]
	var new := old.duplicate()
	new.insert(2, ["120", "K1", "STIL_START", "", "p2", "0", "0"])
	new.insert(4, ["520", "K1", "STIL_EIND", "400", "p2", "0", "0"])
	var a = FlowReport.from_rows(old, false)
	var b = FlowReport.from_rows(new, false)
	t.check(a.longest_still == 80 and a.longest_still_p2 == 0, "oud log: P1 %d, P2 %d" % [a.longest_still, a.longest_still_p2])
	t.check(b.longest_still == 80 and b.longest_still_p2 == 400 and b.still_runs == a.still_runs,
		"nieuw log: P1 %d, P2 %d, runs %s" % [b.longest_still, b.longest_still_p2, str(b.still_runs)])


## O-24 (gdd v0.8.1 §4.5; `kamers/flowkamer.md` §12 antwoord 6 en 7): MP-3 in co-op meet de
## stilstand van de springer (bron = de drager: `p1` → P2 sprong, anders P1); één contact = één
## actie: SPRINGPLANK + LANCERING van dezelfde springer op dezelfde tick tellen in MP-2 één keer, en
## een VANGEN is in MP-3 een landing.
func test_o24_mp3_springer_and_one_contact(t) -> void:
	var rows := [["0", "K1", "RUN_START", "", "", "0", "0"],
		# P1 (de drager) staat 40 ticks stil vóór de landing van P2 op hem: telt niet voor P2.
		["100", "K1", "STIL_START", "", "p1", "0", "0"],
		["140", "K1", "STIL_EIND", "40", "p1", "0", "0"],
		["150", "K1", "SPRINGPLANK", "1", "p1", "0", "0"],
		# P2 (de drager) wacht niet, P1 landt op hem en wordt gelanceerd op dezelfde tick.
		["300", "K1", "SPRINGPLANK", "1", "p2", "0", "0"],
		["300", "K1", "LANCERING", "1", "p2", "0", "0"],
		# P2 staat 30 ticks stil en landt dan op P1 (springer P2 wachtte).
		["400", "K1", "STIL_START", "", "p2", "0", "0"],
		["430", "K1", "STIL_EIND", "30", "p2", "0", "0"],
		["440", "K1", "SPRINGPLANK", "2", "p1", "0", "0"],
		# Een vang van P1 op P2: een contact zonder SPRINGPLANK.
		["500", "K1", "VANGEN", "3", "p2", "0", "0"],
		["600", "K1", "RUN_EIND", "", "", "0", "0"]]
	var rep = FlowReport.from_rows(rows, false)
	t.check(rep.landings == 4, "landingen %d (4: drie SPRINGPLANK en een VANGEN)" % rep.landings)
	t.check(is_equal_approx(rep.landings_without_still, 0.75),
		"zonder wachten %.2f (0,75: alleen de landing van P2 na zijn eigen stilstand telt als wachten)" % rep.landings_without_still)
	t.check(rep.actions.size() == 4, "acties %s (4: SPRINGPLANK + LANCERING op 300 is één)" % [rep.actions])
	t.check(rep.still_runs_p2 == [[400, 429]] and rep.longest_still == 40, "runs P2 %s, MP-1 %d" % [rep.still_runs_p2, rep.longest_still])
