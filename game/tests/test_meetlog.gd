extends RefCounted
## Tests voor het meetlog (gdd §4.5) dat T16b nodig heeft voor norm (1)
## (MP-1, stilstand), norm (2) (MP-2, echo-acties) en R-V12 (MP-3).
## T16a deel 2, #76.

const Fx = preload("res://tests/echo_fixture.gd")
const InputBits = preload("res://scripts/input/input_bits.gd")
const Meetlog = preload("res://scripts/events/meetlog.gd")
const CombatTarget = preload("res://scripts/combat/combat_target.gd")

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
		if row[2] == "SPRINGPLANK":
			chain.append(row[3])
	t.check(chain.slice(0, 2) == ["1", "2"], "springplank-reeks %s (1, 2)" % str(chain))
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
