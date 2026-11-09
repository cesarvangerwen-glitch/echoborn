extends RefCounted
## Meetlog van één run (gdd §4.5): de events die T16b en T17 nodig hebben
## voor de flownormen, vooral norm (1) stilstand (MP-1), norm (2) echo-acties
## (MP-2), R-V12 (MP-3) en echo Leeg (MP-4).
##
## Luistert alleen naar signalen en leest na elke tick de toestand van P1
## (standaarden §6: geen testhaken in gameplaycode). Deterministisch: dezelfde
## `ScriptedInput` en dezelfde D geven dezelfde regels. Kolommen:
## `tick, kamer, event, waarde, bron, x, y`. Nog niet in deze versie: kamers
## (KAMER, `buiten`, T5b), lichtmeter en gemaal (LP, POMP, T16b) en co-op
## (DROP_IN … P2_TERUG, LANCERING, VANGEN; T16c).

const PlayerActor = preload("res://scripts/echo/player_actor.gd")
const Motor = preload("res://scripts/echo/motor.gd")

const HEADER := "tick,kamer,event,waarde,bron,x,y"
## MP-1: venster en straal voor een stille tick; uitgesloten ticks.
const STILL_WINDOW := 30
const STILL_RADIUS := 24.0
const RUN_GRACE := 30
const RESPAWN_GRACE := 60
## LM-02: springplank-reeks telt tot n = 4.
const CHAIN_MAX := 4

## Regels als arrays van 7 strings, in volgorde van ontstaan.
var rows: Array[PackedStringArray] = []
var room := ""

var _sim: Node
var _p1: PlayerActor
var _echo: Node2D
var _start_tick := 0
var _positions: Array[Vector2] = []
var _last_move_tick := -1_000_000
var _grace_until := 0
var _still_since := -1
var _chain := 0
var _closed := false


## Begint het log op de volgende tick van `sim`. `echo` mag null zijn (co-op).
func _init(sim: Node, p1: PlayerActor, echo: Node2D) -> void:
	_sim = sim
	_p1 = p1
	_echo = echo
	_start_tick = sim.tick
	_grace_until = _start_tick + RUN_GRACE
	_add(_start_tick, "RUN_START", "", "", p1.position)
	sim.tick_finished.connect(_on_tick)
	var combat: RefCounted = sim.combat
	combat.mark_set.connect(func(tick: int, mark: RefCounted) -> void:
		_add(tick, "MERK_GEZET", "", str(mark.id), mark.center()))
	combat.mark_exploded.connect(func(tick: int, mark: RefCounted, link: int) -> void:
		_add(tick, "ONTPLOFFING", str(link), str(mark.id), mark.center()))
	if echo:
		echo.state_changed.connect(func(tick: int, active: bool) -> void:
			_add(tick, "ECHO_LEEG_EIND" if active else "ECHO_LEEG_START", "" if active else "reset",
				"echo", echo.position))
		echo.broke.connect(func(tick: int, at: Vector2) -> void:
			_add(tick, "BREEK", "", "echo", at))
		echo.merksprong_started.connect(func(tick: int, mark_id: int) -> void:
			_add(tick, "MERKSPRONG", "", str(mark_id), echo.recorded_position))


## Sluit het log af (RUN_EIND en een open stilstand).
func finish() -> void:
	var tick: int = _sim.tick - 1
	if _still_since >= 0:
		_add(tick, "STIL_EIND", str(tick - _still_since + 1), "p1", _p1.position)
		_still_since = -1
	_add(tick, "RUN_EIND", "", "", _p1.position)
	# Daarna komt er niets meer bij, ook niet als de Sim nog een tick draait.
	_closed = true
	if _sim.tick_finished.is_connected(_on_tick):
		_sim.tick_finished.disconnect(_on_tick)


func to_csv() -> String:
	var lines := PackedStringArray([HEADER])
	for row in rows:
		lines.append(",".join(row))
	return "\n".join(lines) + "\n"


## Schrijft het log naar `path` (bv. `user://meetlog_<datum>_solo_D120_p1.csv`).
func save(path: String) -> Error:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	file.store_string(to_csv())
	return OK


## Aantal regels met dit event (voor rapporten en tests).
func count(event: String) -> int:
	var n := 0
	for row in rows:
		if row[2] == event:
			n += 1
	return n


func _on_tick(tick: int) -> void:
	var ev := _p1.move_events
	match _p1.echo_reset:
		PlayerActor.EchoReset.RELEASE:
			_add(tick, "LOSLATEN", "", "p1", _p1.position)
		PlayerActor.EchoReset.RESPAWN:
			_add(tick, "RESPAWN", "", "p1", _p1.position)
			_grace_until = tick + RESPAWN_GRACE
	if ev & Motor.EV_LAND:
		_chain = 0
	if ev & Motor.EV_SPRINGPLANK:
		_chain = mini(_chain + 1, CHAIN_MAX)
		_add(tick, "SPRINGPLANK", str(_chain), "echo", _p1.position)
	if ev & Motor.EV_BOUNCE:
		_add(tick, "BOUNCE", str(maxi(_chain, 1)), "echo", _p1.position)
	# C-13: een vang telt voor `n` als springplank-landing; C-11b: lancering.
	if ev & Motor.EV_CATCH:
		_chain = mini(_chain + 1, CHAIN_MAX)
		_add(tick, "VANGEN", str(_chain), "echo", _p1.position)
	if ev & Motor.EV_LAUNCH:
		_add(tick, "LANCERING", str(maxi(_chain, 1)), "echo", _p1.position)
	if ev & (Motor.EV_JUMP | Motor.EV_DASH):
		_last_move_tick = tick
	_update_still(tick)


## MP-1: tick t is stil als P1 in t − 30 … t binnen 24 px van zijn positie
## op t − 30 bleef en er in t − 29 … t geen sprong of dash begon.
func _update_still(tick: int) -> void:
	_positions.append(_p1.position)
	if _positions.size() > STILL_WINDOW + 1:
		_positions.pop_front()
	var still := tick >= _grace_until and _positions.size() == STILL_WINDOW + 1 \
		and tick - _last_move_tick >= STILL_WINDOW
	if still:
		var origin := _positions[0]
		for at in _positions:
			if at.distance_to(origin) > STILL_RADIUS:
				still = false
				break
	if still and _still_since < 0:
		_still_since = tick
		_add(tick, "STIL_START", "", "p1", _p1.position)
	elif not still and _still_since >= 0:
		_add(tick, "STIL_EIND", str(tick - _still_since), "p1", _p1.position)
		_still_since = -1


func _add(tick: int, event: String, value: String, source: String, at: Vector2) -> void:
	if _closed:
		return
	rows.append(PackedStringArray([str(tick), room, event, value, source,
		"%.2f" % at.x, "%.2f" % at.y]))
