extends RefCounted
## Meetlog van één run (gdd §4.5): de events die T16b en T17 nodig hebben
## voor de flownormen, vooral norm (1) stilstand (MP-1), norm (2) echo-acties
## (MP-2), R-V12 (MP-3) en echo Leeg (MP-4).
##
## Luistert alleen naar signalen en leest na elke tick de toestand van P1 en,
## in co-op, van P2 (standaarden §6: geen testhaken in gameplaycode).
## Deterministisch: dezelfde `ScriptedInput` en dezelfde D geven dezelfde
## regels. Kolommen: `tick, kamer, event, waarde, bron, x, y`. Kamers, LP, POMP en
## DROP_IN … P2_TERUG schrijft de flow-kamer (`flow_meetlog.gd`); hier staan
## de springplank-events van P1 en, in co-op, van P2 (bron = de drager).
##
## MP-1 (`STIL_START`, `STIL_EIND`) geldt voor P1 (bron `p1`) en, in co-op,
## ook voor P2 (bron `p2`, MP-7 b, #125). Werkaanname W5 (testplan-f0 §6):
## voor P2 dezelfde definitie op zijn middelpunt; ticks dat P2 opgelost is
## tellen niet mee (een open stilstand sluit bij `P2_OPGELOST` en bij een
## drop-out) en na `P2_TERUG` gelden 60 ticks niet, zoals na een respawn.
## Lezers die alleen P1 willen, filteren op bron `p1`.
##
## `STUIT` (V-01b): een neerslag van P1 of P2 raakte iets (bron `p1`/`p2`). Een boss meldt zich met
## `watch_boss` (T8b B-10): `BOSS_START`, `BOSS_FASE` (waarde 1, wissel, 2, wankel), `SCHOT_BREUK`,
## `KERN_DICHT` (waarde drempel/tijd), `RAD_TREFFER` (waarde de actie: bounce, lancering, vang,
## stuit, sprong of echo; bron wie sloeg), `RAD_DRAAI` (waarde treffers/tijd; bron de kant waar het
## heen draait: links/rechts), `BOSS_AANVAL` (waarde soort_helft, bron raak/mis), `FINISHER_START`,
## `FINISHERSLAG` (bron wie), `BOSS_VERSLAGEN` (waarde het aantal finisherslagen), `DOELHELFT`
## (fase 1 co-op, waarde links/rechts: de doelhelft wordt die helft; geen: de doelhelft gaat uit bij
## een drop-out; B-14, v0.1.6, v0.1.7).
##
## MP-7 (e) (`WACHT_START`, `WACHT_EIND`; gdd v0.8.6 §4.5, #292): alleen in co-op, voor P1 en P2
## (bron `p1`/`p2`), uit de spelstaat (niet uit een bot), dus ook bij mensen. Een tick `t` is
## wachtend als het middelpunt van de speler in `t − 120 … t` steeds binnen 64 px (rechte
## afstand) van zijn middelpunt op `t − 120` bleef, en hij in die ticks geen eigen actie had:
## een `LP`- of `POMP`-regel met hem als bron, of een `SPRINGPLANK`, `BOUNCE`, `VANGEN` of
## `LANCERING` waarin hij drager (bron) of springer (het andere lichaam) was. `WACHT_START` staat
## op de eerste wachtende tick `t₀`, met waarde de begintick `t₀ − 120`; `WACHT_EIND` op de eerste
## tick die niet meer wacht (of bij `finish`, dan telt de laatste tick mee), met waarde de lengte:
## een wachtperiode is `[waarde van WACHT_START, die + lengte)`, zodat een lezer hem per kamer of
## per bossfase kan knippen. Niet mee telt wat MP-1 niet telt (de eerste 30 ticks, 60 na een
## respawn of `P2_TERUG`), voor P2 de ticks dat hij opgelost is, en `WARD_START … WARD_EIND`:
## het venster van 120 ticks moet helemaal buiten die ticks liggen.

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
## MP-7 (e): venster en straal voor een wachtende tick.
const WAIT_WINDOW := 120
const WAIT_RADIUS := 64.0
## Rijen die een eigen actie zijn van hun bron (MP-7 e); bij de plank-events ook van de springer.
const OWN_ACTION := ["LP", "POMP"]
const PLANK_ACTION := ["SPRINGPLANK", "BOUNCE", "VANGEN", "LANCERING"]


## MP-7 (e): het wachten van één speler (zie de kop van dit script).
class Wait:
	extends RefCounted
	var source := ""
	var positions: Array[Vector2] = []
	var last_action := -1_000_000
	## Eerste tick die als begin van een venster mag gelden (na een uitgesloten tick).
	var from_tick := 0
	## Begintick (`t₀ − 120`) van de open wachtperiode, of -1.
	var since := -1
	var at := Vector2.ZERO

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
var _chain_p2 := 0
var _closed := false
## MP-1 voor P2: zelfde velden als voor P1, per P2-lichaam.
var _p2: Node2D
var _p2_positions: Array[Vector2] = []
var _p2_last_move_tick := -1_000_000
var _p2_grace_until := 0
var _p2_still_since := -1
## MP-7 (e): wachten van P1 en P2 (alleen co-op), en `WARD_START … WARD_EIND`.
var _wait_p1 := Wait.new()
var _wait_p2 := Wait.new()
var _ward := false
var _p2_wait_body: Node2D = null


## Begint het log op de volgende tick van `sim`. `echo` mag null zijn (co-op).
func _init(sim: Node, p1: PlayerActor, echo: Node2D) -> void:
	_sim = sim
	_p1 = p1
	_echo = echo
	_start_tick = sim.tick
	_grace_until = _start_tick + RUN_GRACE
	_wait_p1.source = "p1"
	_wait_p2.source = "p2"
	_wait_p1.from_tick = _grace_until
	_wait_p2.from_tick = _grace_until
	_add(_start_tick, "RUN_START", "", "", p1.position)
	sim.tick_finished.connect(_on_tick)
	if sim.has_signal("partner_returned"):
		sim.partner_returned.connect(func(tick: int, _at: Vector2) -> void:
			_p2_grace_until = tick + RESPAWN_GRACE
			_p2_positions.clear()
			_wait_p2.positions.clear()
			_wait_p2.from_tick = maxi(_wait_p2.from_tick, _p2_grace_until))
	if sim.has_signal("stuit"):
		sim.stuit.connect(func(tick: int, player: Node2D) -> void:
			_add(tick, "STUIT", "", "p%d" % player.player_index, player.position))
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


## B-10: de events van een boss (`Boss`; de Gemaalmeester geeft ook schot, kern en rad).
func watch_boss(boss: Node) -> void:
	var at := func() -> Vector2: return _p1.position if is_instance_valid(_p1) else Vector2.ZERO
	boss.boss_started.connect(func(tick: int) -> void: _add(tick, "BOSS_START", "", "", at.call()))
	boss.phase_changed.connect(func(tick: int, phase: String) -> void:
		_add(tick, "BOSS_FASE", phase, "", at.call()))
	boss.attack_ended.connect(func(tick: int, kind: String, side: int, hit: bool) -> void:
		var half := "links" if side < 0 else ("rechts" if side > 0 else "midden")
		_add(tick, "BOSS_AANVAL", "%s_%s" % [kind, half], "raak" if hit else "mis", at.call()))
	boss.finisher_started.connect(func(tick: int) -> void: _add(tick, "FINISHER_START", "", "", at.call()))
	boss.finisher_strike.connect(func(tick: int, who: String) -> void:
		_add(tick, "FINISHERSLAG", "", who, at.call()))
	boss.boss_defeated.connect(func(tick: int) -> void:
		_add(tick, "BOSS_VERSLAGEN", str(boss.finisher_count), "", at.call()))
	if boss.has_signal("shot_broken"):
		boss.shot_broken.connect(func(tick: int) -> void: _add(tick, "SCHOT_BREUK", "", "", at.call()))
	if boss.has_signal("core_closed"):
		boss.core_closed.connect(func(tick: int, reason: String) -> void:
			_add(tick, "KERN_DICHT", reason, "", at.call()))
	if boss.has_signal("rad_hit"):
		boss.rad_hit.connect(func(tick: int, source: String, action: String, _amount: int) -> void:
			_add(tick, "RAD_TREFFER", action, source, at.call()))
	if boss.has_signal("target_half_changed"):
		boss.target_half_changed.connect(func(tick: int, side: int) -> void:
			_add(tick, "DOELHELFT", "geen" if side == 0 else ("links" if side < 0 else "rechts"), "", at.call()))
	if boss.has_signal("rad_turning"):
		boss.rad_turning.connect(func(tick: int, reason: String, to_side: int) -> void:
			_add(tick, "RAD_DRAAI", reason, "links" if to_side < 0 else "rechts", at.call()))


## Sluit het log af (RUN_EIND en een open stilstand).
func finish() -> void:
	var tick: int = _sim.tick - 1
	if _still_since >= 0:
		_add(tick, "STIL_EIND", str(tick - _still_since + 1), "p1", _p1.position)
		_still_since = -1
	if _p2_still_since >= 0:
		# Lengte bewust als bij P1 hierboven: de laatste tick is nog stil (+ 1).
		var at: Vector2 = _p2.position if _p2 != null and is_instance_valid(_p2) else Vector2.ZERO
		_add(tick, "STIL_EIND", str(tick - _p2_still_since + 1), "p2", at)
		_p2_still_since = -1
	# MP-7 (e): een open wachtperiode loopt tot en met de laatste tick (+ 1).
	_close_wait(_wait_p1, tick + 1, tick)
	_close_wait(_wait_p2, tick + 1, tick)
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
			# Zoals MP-1: de respawn-ticks tellen voor P1 en P2 niet.
			_wait_p1.from_tick = maxi(_wait_p1.from_tick, _grace_until)
			_wait_p2.from_tick = maxi(_wait_p2.from_tick, _grace_until)
	var p2: PlayerActor = _sim.get_player(2) if _sim.has_method("get_player") else null
	# Bron = de drager (§4.5): solo de echo, in co-op het andere lichaam.
	_chain = _plank_rows(tick, ev, _chain, "p2" if p2 != null else "echo", _p1.position)
	if p2 != null and not p2.dissolved:
		if p2.motor.on_floor and p2.motor.support != Motor.Support.SHADOW_BODY:
			_chain_p2 = 0
		_chain_p2 = _plank_rows(tick, p2.move_events, _chain_p2, "p1", p2.position)
	elif p2 == null:
		_chain_p2 = 0
	if ev & (Motor.EV_JUMP | Motor.EV_DASH):
		_last_move_tick = tick
	_update_still(tick)
	_update_still_p2(tick, p2)
	_update_waits(tick, p2)


## SPRINGPLANK, BOUNCE, VANGEN en LANCERING van één springer; `n` (LM-02) per
## springer, `source` is de drager. Geeft de nieuwe `n` terug.
func _plank_rows(tick: int, ev: int, n: int, source: String, at: Vector2) -> int:
	if ev & Motor.EV_LAND:
		n = 0
	if ev & Motor.EV_SPRINGPLANK:
		n = mini(n + 1, CHAIN_MAX)
		_add(tick, "SPRINGPLANK", str(n), source, at)
	if ev & Motor.EV_BOUNCE:
		_add(tick, "BOUNCE", str(maxi(n, 1)), source, at)
	# C-13: een vang telt voor `n` als springplank-landing; C-11b: lancering.
	if ev & Motor.EV_CATCH:
		n = mini(n + 1, CHAIN_MAX)
		_add(tick, "VANGEN", str(n), source, at)
	if ev & Motor.EV_LAUNCH:
		_add(tick, "LANCERING", str(maxi(n, 1)), source, at)
	return n


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


## MP-1 voor P2 (MP-7 b, W5): als `_update_still`, op het middelpunt van P2.
func _update_still_p2(tick: int, p2: PlayerActor) -> void:
	if p2 != _p2:
		# Drop-in, drop-out of een nieuw P2-lichaam: opnieuw beginnen.
		_close_still_p2(tick)
		_p2 = p2
		_p2_positions.clear()
		_p2_last_move_tick = -1_000_000
	if p2 == null:
		return
	if p2.dissolved:
		_close_still_p2(tick)
		_p2_positions.clear()
		return
	if p2.move_events & (Motor.EV_JUMP | Motor.EV_DASH):
		_p2_last_move_tick = tick
	_p2_positions.append(p2.position)
	if _p2_positions.size() > STILL_WINDOW + 1:
		_p2_positions.pop_front()
	var still := tick >= _grace_until and tick >= _p2_grace_until \
		and _p2_positions.size() == STILL_WINDOW + 1 and tick - _p2_last_move_tick >= STILL_WINDOW
	if still:
		var origin := _p2_positions[0]
		for at in _p2_positions:
			if at.distance_to(origin) > STILL_RADIUS:
				still = false
				break
	if still and _p2_still_since < 0:
		_p2_still_since = tick
		_add(tick, "STIL_START", "", "p2", p2.position)
	elif not still:
		_close_still_p2(tick)


## Sluit een open stilstand van P2 op `tick` (die tick is niet meer stil).
func _close_still_p2(tick: int) -> void:
	if _p2_still_since < 0:
		return
	var at: Vector2 = _p2.position if _p2 != null and is_instance_valid(_p2) else Vector2.ZERO
	_add(tick, "STIL_EIND", str(tick - _p2_still_since), "p2", at)
	_p2_still_since = -1


## MP-7 (e), na MP-1: het wachten van P1 en P2, alleen zolang er een P2 is (co-op).
func _update_waits(tick: int, p2: PlayerActor) -> void:
	if p2 != _p2_wait_body:
		# Drop-in, drop-out of een nieuw P2-lichaam: beide opnieuw, het venster pas vanaf nu.
		_close_wait(_wait_p1, tick, tick)
		_close_wait(_wait_p2, tick, tick)
		_p2_wait_body = p2
		for w: Wait in [_wait_p1, _wait_p2]:
			w.positions.clear()
			w.from_tick = maxi(w.from_tick, tick)
	if p2 == null:
		return
	_step_wait(_wait_p1, tick, _p1.position)
	if p2.dissolved:
		_close_wait(_wait_p2, tick, tick)
		_wait_p2.positions.clear()
		_wait_p2.from_tick = maxi(_wait_p2.from_tick, tick + 1)
		return
	_step_wait(_wait_p2, tick, p2.position)


func _step_wait(w: Wait, tick: int, at: Vector2) -> void:
	w.at = at
	if _ward:
		w.from_tick = maxi(w.from_tick, tick + 1)
	w.positions.append(at)
	if w.positions.size() > WAIT_WINDOW + 1:
		w.positions.pop_front()
	var begin := tick - WAIT_WINDOW
	var waiting := begin >= w.from_tick and w.positions.size() == WAIT_WINDOW + 1 \
		and w.last_action < begin
	if waiting:
		var origin := w.positions[0]
		for p in w.positions:
			if p.distance_to(origin) > WAIT_RADIUS:
				waiting = false
				break
	if waiting and w.since < 0:
		w.since = begin
		_add(tick, "WACHT_START", str(begin), w.source, at)
	elif not waiting:
		_close_wait(w, tick, tick)


## Sluit een open wachtperiode op de regel van `tick`; `end` is de eerste tick die niet meer
## meetelt (lengte = `end − (t₀ − 120)`).
func _close_wait(w: Wait, end: int, tick: int) -> void:
	if w.since < 0:
		return
	var since := w.since
	w.since = -1
	_add(tick, "WACHT_EIND", str(end - since), w.source, w.at)


## MP-7 (e): een eigen actie van `who` (`p1` of `p2`) op `tick`.
func _note_action(tick: int, who: String) -> void:
	if who == "p1":
		_wait_p1.last_action = maxi(_wait_p1.last_action, tick)
	elif who == "p2":
		_wait_p2.last_action = maxi(_wait_p2.last_action, tick)


func _add(tick: int, event: String, value: String, source: String, at: Vector2) -> void:
	if _closed:
		return
	if event in OWN_ACTION:
		_note_action(tick, source.get_slice("_", source.get_slice_count("_") - 1))
	elif event in PLANK_ACTION and (source == "p1" or source == "p2"):
		_note_action(tick, "p1")
		_note_action(tick, "p2")
	elif event == "WARD_START":
		_ward = true
	elif event == "WARD_EIND":
		_ward = false
	rows.append(PackedStringArray([str(tick), room, event, value, source,
		"%.2f" % at.x, "%.2f" % at.y]))
