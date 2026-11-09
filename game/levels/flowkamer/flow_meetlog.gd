extends "res://scripts/events/meetlog.gd"
## Meetlog van de flow-kamer (gdd §4.5): het meetlog van T16a plus de events
## die de kamer zelf kent.
##
## Erbij: `KAMER`, `LP`, `POMP`, `GEMAAL_VOL`, `DROP_IN`, `DROP_OUT` en
## (werkaanname, niet in de tabel van §4.5) `SCORE` voor norm (3) (MP-5): na
## de run geeft de speler per kamer een score 1–5, met `waarde` = score en
## `bron` = kamer. Zo staan de meetpunten van norm (1)–(3) en R-V12 in één CSV.
##
## Eén wijziging in gedrag: de springplank-reeks `n` (LM-02) begint ook opnieuw
## als P1 van de echo áfloopt op de vloer (dan is er geen EV_LAND, want hij
## stond al). Zo is `n` in `SPRINGPLANK` gelijk aan die van de lichtmeter.

const Motor2 = preload("res://scripts/echo/motor.gd")


func _init(sim: Node, p1: Node, echo: Node2D, start_room: String) -> void:
	super(sim, p1, echo)
	room = start_room
	var first: PackedStringArray = rows[0]
	first[1] = start_room
	rows[0] = first


## Een regel van de kamer zelf (KAMER, LP, POMP, ...).
func add_row(tick: int, event: String, value: String, source: String, at: Vector2) -> void:
	_add(tick, event, value, source, at)


## Volgt een nieuwe echo, bv. na een drop-out (C-05) of als de echo weer aan gaat.
func watch_echo(echo: Node2D) -> void:
	_echo = echo
	if echo == null:
		return
	echo.state_changed.connect(func(tick: int, active: bool) -> void:
		_add(tick, "ECHO_LEEG_EIND" if active else "ECHO_LEEG_START", "" if active else "reset",
			"echo", echo.position))
	echo.broke.connect(func(tick: int, at: Vector2) -> void:
		_add(tick, "BREEK", "", "echo", at))
	echo.merksprong_started.connect(func(tick: int, mark_id: int) -> void:
		_add(tick, "MERKSPRONG", "", str(mark_id), echo.recorded_position))


## Score voor norm (3) na de run (MP-5), ook als het log al dicht is.
func add_score(tick: int, room_name: String, score: int) -> void:
	rows.append(PackedStringArray([str(tick), room_name, "SCORE", str(score), room_name, "", ""]))


func is_closed() -> bool:
	return _closed


func _on_tick(tick: int) -> void:
	var motor = _p1.motor
	if motor.on_floor and motor.support != Motor2.Support.SHADOW_BODY:
		_chain = 0
	super._on_tick(tick)
