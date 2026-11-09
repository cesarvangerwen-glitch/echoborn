extends RefCounted
## Tests voor objectdetectie (A2, #68): objecten zien de lichamen van déze
## tick, met een directe vormtest in stap (5) van E-07b. De twee
## alternatieven via de physics-ruimte lopen achter; dat legt de laatste test
## vast.

const InputBits = preload("res://scripts/input/input_bits.gd")
const ScriptedInput = preload("res://scripts/input/scripted_input.gd")
const PlayerActor = preload("res://scripts/echo/player_actor.gd")
const EchoActor = preload("res://scripts/echo/echo_actor.gd")
const BodyBuilder = preload("res://scripts/echo/body_builder.gd")
const PressurePlate = preload("res://scripts/objects/pressure_plate.gd")
const Layers = preload("res://scripts/world/layers.gd")
const SpikeWorld = preload("res://scripts/world/spike_world.gd")

const R := InputBits.RIGHT
const PLATE_X := 420.0
const PLATE_SIZE := Vector2(48, 8)
const PLATE_Y := SpikeWorld.FLOOR_Y - 2.0
## P1 loopt 60 ticks naar de plaat, staat er 30 ticks stil en loopt door.
const SCRIPT := [[20, 0], [60, R], [30, 0], [60, R], [430, 0]]


func _plate_rect() -> Rect2:
	return Rect2(Vector2(PLATE_X, PLATE_Y) - PLATE_SIZE * 0.5, PLATE_SIZE)


## Overlapt een lichaam op positie `pos` de plaat? Rekenkundig, als referentie.
func _on_plate(pos: Vector2) -> bool:
	var body := Rect2(pos - BodyBuilder.SIZE * 0.5, BodyBuilder.SIZE)
	return body.intersects(_plate_rect())


func _add_plate(sim: Node, plate_name: String, owner: int) -> PressurePlate:
	var plate := PressurePlate.new()
	plate.name = plate_name
	plate.setup(owner, PLATE_SIZE)
	plate.position = Vector2(PLATE_X, PLATE_Y)
	sim.add_object(plate)
	return plate


## Per tick: [verwacht (rekenkundig, uit de positie van deze tick), schaduw-,
## licht-, gedeelde plaat]. Positie komt van `body` ná de tick.
func _record(sim: Node, body: Node2D, plates: Array, rows: Array) -> Callable:
	var on_tick := func(_tick: int) -> void:
		var row := [_on_plate(body.position)]
		for plate: PressurePlate in plates:
			row.append(plate.active)
		rows.append(row)
	sim.tick_finished.connect(on_tick)
	return on_tick


## E-06 + E-13 + A2: P1 en daarna zijn echo lopen over drie platen op
## dezelfde plek (schaduw, licht, gedeeld) en staan er 30 ticks op. Op elke
## tick is een plaat aan precies wanneer het lichaam van déze tick hem
## overlapt en hij dat lichaam mag voelen. Geen tick vertraging.
func test_plates_follow_bodies_on_the_same_tick(t) -> void:
	var sim = t.make_sim()
	var shadow := _add_plate(sim, "ShadowPlate", Layers.SHADOW)
	var light := _add_plate(sim, "LightPlate", Layers.LIGHT)
	var shared := _add_plate(sim, "SharedPlate", Layers.LIGHT | Layers.SHADOW)
	var plates := [shadow, light, shared]
	var p1 := PlayerActor.new()
	p1.setup(1, ScriptedInput.new(SCRIPT), Color.WHITE)
	p1.position = SpikeWorld.PLAYER_SPAWN
	sim.add_player(p1)
	var rows_p1 := []
	var hook := _record(sim, p1, plates, rows_p1)
	await t.run_ticks(sim, 600)
	sim.tick_finished.disconnect(hook)
	var echo := EchoActor.new()
	echo.setup(Color.BLACK)
	t.check(sim.add_echo(echo), "echo werd geweigerd")
	echo.start(p1.recorder.snapshot(), EchoActor.Mode.STATE)
	var rows_echo := []
	hook = _record(sim, echo, plates, rows_echo)
	await t.run_ticks(sim, 600)
	sim.tick_finished.disconnect(hook)
	t.check(not _on_plate(p1.position), "P1 hoort tijdens het afspelen van de plaat af te staan")
	# P1 (laag 2): licht en gedeeld volgen P1, schaduw blijft uit.
	var wrong_p1 := 0
	var wrong_echo := 0
	var on_p1 := 0
	var on_echo := 0
	for row: Array in rows_p1:
		on_p1 += 1 if row[0] else 0
		if row[1] != false or row[2] != row[0] or row[3] != row[0]:
			wrong_p1 += 1
	# Echo (laag 3): schaduw en gedeeld volgen de echo, licht blijft uit.
	for row: Array in rows_echo:
		on_echo += 1 if row[0] else 0
		if row[1] != row[0] or row[2] != false or row[3] != row[0]:
			wrong_echo += 1
	t.check(rows_p1.size() == 600 and rows_echo.size() == 600, "aantal ticks %d / %d" % [
		rows_p1.size(), rows_echo.size()])
	t.check(on_p1 >= 30, "P1 stond maar %d ticks op de plaat; test zegt dan weinig" % on_p1)
	t.check(on_echo == on_p1, "echo stond %d ticks op de plaat, P1 %d (E-13: precies dezelfde ticks)" % [
		on_echo, on_p1])
	t.check(wrong_p1 == 0, "%d ticks een verkeerde plaatstand bij P1" % wrong_p1)
	t.check(wrong_echo == 0, "%d ticks een verkeerde plaatstand bij de echo" % wrong_echo)
	t.note("P1 en echo elk %d ticks op de plaat; 0 ticks verschil met de positie van dezelfde tick" % on_p1)


## Legt de verworpen alternatieven vast (A2). Via de physics-ruimte ziet een
## object de echo te laat: een `intersect_shape`-query precies één tick, een
## `Area2D` (`get_overlapping_bodies()`) precies twee ticks. Oorzaak: Godot
## 4.6 past de nieuwe positie van een kinematisch lichaam pas toe in de
## physics-stap ná `_physics_process`, en een Area2D meldt zijn overlap pas
## de frame daarna. Geen bug in onze code. Wordt deze test rood na een
## engine-update, dan is die volgorde veranderd: herbekijk A2.
func test_physics_space_lags_behind_direct_test(t) -> void:
	var sim = t.make_sim()
	var plate := _add_plate(sim, "ShadowPlate", Layers.SHADOW)
	var area := Area2D.new()
	area.collision_layer = 0
	area.collision_mask = Layers.SHADOW
	area.position = Vector2(PLATE_X, PLATE_Y)
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = PLATE_SIZE
	shape.shape = rect
	area.add_child(shape)
	t.world_root().add_child(area)
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = rect
	query.transform = Transform2D(0.0, Vector2(PLATE_X, PLATE_Y))
	query.collision_mask = Layers.SHADOW
	var p1 := PlayerActor.new()
	p1.setup(1, ScriptedInput.new(SCRIPT), Color.WHITE)
	p1.position = SpikeWorld.PLAYER_SPAWN
	sim.add_player(p1)
	await t.run_ticks(sim, 600)
	var echo := EchoActor.new()
	echo.setup(Color.BLACK)
	sim.add_echo(echo)
	echo.start(p1.recorder.snapshot(), EchoActor.Mode.STATE)
	var direct: Array[bool] = []
	var space: Array[bool] = []
	var area_on: Array[bool] = []
	var on_tick := func(_tick: int) -> void:
		direct.append(plate.active)
		space.append(not t.world_root().get_world_2d().direct_space_state.intersect_shape(query).is_empty())
		area_on.append(not area.get_overlapping_bodies().is_empty())
	sim.tick_finished.connect(on_tick)
	await t.run_ticks(sim, 600)
	sim.tick_finished.disconnect(on_tick)
	var counts := {"space_same": 0, "space_lag1": 0, "area_same": 0, "area_lag2": 0}
	for i in range(2, direct.size()):
		counts["space_same"] += 1 if space[i] == direct[i] else 0
		counts["space_lag1"] += 1 if space[i] == direct[i - 1] else 0
		counts["area_same"] += 1 if area_on[i] == direct[i] else 0
		counts["area_lag2"] += 1 if area_on[i] == direct[i - 2] else 0
	var n := direct.size() - 2
	t.check(direct.count(true) >= 30, "echo stond maar %d ticks op de plaat; test zegt dan weinig" % direct.count(true))
	t.check(counts["space_lag1"] == n, "intersect_shape loopt niet overal één tick achter (%d van %d)" % [counts["space_lag1"], n])
	t.check(counts["space_same"] < n, "intersect_shape liep gelijk; dan is de vertraging verdwenen")
	t.check(counts["area_lag2"] == n, "Area2D loopt niet overal twee ticks achter (%d van %d)" % [counts["area_lag2"], n])
	t.check(counts["area_same"] < n, "Area2D liep gelijk; dan is de vertraging verdwenen")
	t.note("van %d ticks gelijk met de directe test: intersect_shape %d, Area2D %d; met 1 resp. 2 ticks verschuiving: %d en %d" % [
		n, counts["space_same"], counts["area_same"], counts["space_lag1"], counts["area_lag2"]])
