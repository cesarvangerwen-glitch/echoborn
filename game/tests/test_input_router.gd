extends RefCounted
## Tests voor de InputRouter: apparaat-GUID, drop-in en drop-out (issue #69, gdd C-03, C-05).
##
## Echte controllers zijn er headless niet. De tests sturen gesimuleerde InputEvents en
## `joy_connection_changed`-meldingen met verzonnen joypad-indexen en GUID's.

const InputRouter = preload("res://scripts/input/input_router.gd")
const InputBits = preload("res://scripts/input/input_bits.gd")
const PlayerActor = preload("res://scripts/echo/player_actor.gd")
const SpikeWorld = preload("res://scripts/world/spike_world.gd")

const GUID_XBOX := "030000005e0400008e02000010010000"
const GUID_DS4 := "050000004c050000cc09000000810000"


## Router buiten de boom: geen echte input, geen eigen ticks. `guids` = index -> GUID.
func _router(guids: Dictionary) -> InputRouter:
	var router := InputRouter.new()
	router.guid_lookup = func(device: int) -> String: return guids.get(device, "")
	return router


func _pad(router: InputRouter, device: int, button: JoyButton, pressed: bool) -> void:
	var event := InputEventJoypadButton.new()
	event.device = device
	event.button_index = button
	event.pressed = pressed
	router.handle_event(event)


func _tap(router: InputRouter, device: int, button: JoyButton) -> void:
	_pad(router, device, button, true)
	_pad(router, device, button, false)


func _stick(router: InputRouter, device: int, value: float) -> void:
	var event := InputEventJoypadMotion.new()
	event.device = device
	event.axis = JOY_AXIS_LEFT_X
	event.axis_value = value
	router.handle_event(event)


func _key(keycode: Key, pressed: bool, device: int = 0) -> InputEventKey:
	var event := InputEventKey.new()
	event.device = device
	event.physical_keycode = keycode
	event.pressed = pressed
	return event


func _steps(router: InputRouter, n: int) -> void:
	for i in n:
		router.step()


## Eerste knop op een willekeurig apparaat = plaats 1; daarna alleen "meedoen" voor plaats 2;
## een derde apparaat krijgt niets (7A: max. twee lichamen).
func test_join_fills_slot_1_then_slot_2_and_never_a_third(t) -> void:
	var router := _router({3: GUID_XBOX, 4: GUID_DS4, 5: GUID_DS4})
	var joined: Array = []
	router.slot_joined.connect(func(slot: int, device: String) -> void:
		joined.append([slot, device]))
	_tap(router, 3, JOY_BUTTON_A)
	t.check(router.slot_device(1) == "joy3", "eerste knop gaf plaats 1 niet aan joy3")
	_tap(router, 4, JOY_BUTTON_A)
	t.check(router.slot_state(2) == InputRouter.SlotState.FREE, "A (geen meedoen) vulde plaats 2")
	_tap(router, 4, JOY_BUTTON_START)
	t.check(router.slot_device(2) == "joy4", "Start gaf plaats 2 niet aan joy4")
	t.check(router.slot_guid(2) == GUID_DS4, "plaats 2 kent de GUID van joy4 niet")
	_tap(router, 5, JOY_BUTTON_START)
	t.check(router.slot_of_device("joy5") == 0, "derde apparaat kreeg een plaats")
	t.check(joined == [[1, "joy3"], [2, "joy4"]], "signalen: %s" % [joined])
	router.free()


## Enter op de P2-helft laat meedoen (gdd §2.5); Enter is ook springen, maar die druk springt
## niet. Toetsenbord en joypad 0 hebben allebei device 0 en mogen elkaar niet sturen.
func test_keyboard_half_joins_and_does_not_mix_with_joypad_0(t) -> void:
	var router := _router({0: GUID_XBOX})
	_tap(router, 0, JOY_BUTTON_A)
	router.handle_event(_key(KEY_ENTER, true, 0))
	t.check(router.slot_device(2) == "kb2", "Enter op de P2-helft gaf plaats 2 niet")
	t.check(router.slot_bits(2) == 0, "de meedoen-druk sprong ook: %s"
		% InputBits.describe(router.slot_bits(2)))
	router.handle_event(_key(KEY_ENTER, false, 0))
	router.handle_event(_key(KEY_ENTER, true, 0))
	t.check(router.slot_bits(2) == InputBits.JUMP, "tweede Enter springt niet")
	router.handle_event(_key(KEY_RIGHT, true, 0))
	t.check(router.slot_bits(1) == 0, "pijltje (device 0) stuurt joypad 0 in plaats 1")
	t.check(router.slot_bits(2) == InputBits.JUMP | InputBits.RIGHT, "pijltje werkt niet voor P2")
	_stick(router, 0, -0.9)
	t.check(router.slot_bits(1) == InputBits.LEFT, "stick links op joy0 geeft geen LEFT")
	t.check(router.slot_bits(2) & InputBits.LEFT == 0, "joy0 stuurt het toetsenbord in plaats 2")
	_stick(router, 0, 0.9)
	t.check(router.slot_bits(1) == InputBits.RIGHT, "stick van links naar rechts laat LEFT hangen")
	_stick(router, 0, 0.1)
	t.check(router.slot_bits(1) == 0, "stick in de dode zone geeft nog richting")
	router.free()


## Stopknop 59 ticks: P2 blijft; 60 ticks: P2 weg (gdd C-05). Plaats 1 kan niet stoppen.
func test_leave_hold_59_stays_60_leaves_and_slot_1_never_leaves(t) -> void:
	var router := _router({0: GUID_XBOX, 1: GUID_DS4})
	var left: Array = []
	router.slot_left.connect(func(slot: int, reason: String) -> void: left.append([slot, reason]))
	_tap(router, 0, JOY_BUTTON_A)
	_tap(router, 1, JOY_BUTTON_START)
	_pad(router, 1, JOY_BUTTON_BACK, true)
	_steps(router, 59)
	_pad(router, 1, JOY_BUTTON_BACK, false)
	router.step()
	t.check(router.slot_state(2) == InputRouter.SlotState.ACTIVE, "P2 weg na 59 ticks stoppen")
	_pad(router, 1, JOY_BUTTON_BACK, true)
	_steps(router, 59)
	t.check(router.slot_state(2) == InputRouter.SlotState.ACTIVE,
		"loslaten zette de teller niet terug")
	router.step()
	t.check(router.slot_state(2) == InputRouter.SlotState.FREE, "P2 niet weg na 60 ticks stoppen")
	t.check(left == [[2, "stoppen"]], "signalen: %s" % [left])
	_pad(router, 0, JOY_BUTTON_BACK, true)
	_steps(router, 200)
	t.check(router.slot_state(1) == InputRouter.SlotState.ACTIVE, "plaats 1 stopte")
	_pad(router, 1, JOY_BUTTON_BACK, false)
	_tap(router, 1, JOY_BUTTON_START)
	t.check(router.slot_device(2) == "joy1", "opnieuw meedoen na stoppen lukt niet")
	router.free()


## Pad van P2 ontkoppeld: de plaats wacht. Komt dezelfde GUID terug met een andere index,
## dan krijgt hij zijn plaats terug zonder knop. 179 ticks weg: blijft; 180: weg (C-05).
func test_reconnect_with_new_index_resumes_by_guid_and_180_ticks_drops_out(t) -> void:
	var guids := {0: GUID_XBOX, 1: GUID_DS4}
	var router := _router(guids)
	var events: Array = []
	router.slot_suspended.connect(func(slot: int) -> void: events.append(["weg", slot]))
	router.slot_resumed.connect(func(slot: int, device: String) -> void:
		events.append(["terug", slot, device]))
	_tap(router, 0, JOY_BUTTON_A)
	_tap(router, 1, JOY_BUTTON_START)
	_pad(router, 1, JOY_BUTTON_A, true)
	router.on_joy_connection_changed(1, false)
	guids.erase(1)
	t.check(router.slot_state(2) == InputRouter.SlotState.SUSPENDED, "plaats 2 wacht niet")
	t.check(router.slot_bits(2) == 0, "ingedrukte A blijft hangen na ontkoppelen")
	_steps(router, 179)
	guids[4] = GUID_DS4
	router.on_joy_connection_changed(4, true)
	t.check(router.slot_device(2) == "joy4", "zelfde GUID op index 4 kreeg plaats 2 niet terug")
	_pad(router, 4, JOY_BUTTON_A, true)
	t.check(router.slot_bits(2) == InputBits.JUMP, "joy4 stuurt plaats 2 niet")
	t.check(events == [["weg", 2], ["terug", 2, "joy4"]], "signalen: %s" % [events])
	router.on_joy_connection_changed(4, false)
	_steps(router, 179)
	t.check(router.slot_state(2) == InputRouter.SlotState.SUSPENDED, "P2 weg na 179 ticks")
	router.step()
	t.check(router.slot_state(2) == InputRouter.SlotState.FREE, "P2 niet weg na 180 ticks")
	router.free()


## Twee identieke pads hebben dezelfde GUID. De router houdt ze apart op index, en een
## teruggekeerde pad gaat naar de plaats die wacht, niet naar de plaats die speelt.
func test_identical_pads_share_guid_but_stay_separate(t) -> void:
	var guids := {0: GUID_XBOX, 1: GUID_XBOX}
	var router := _router(guids)
	_tap(router, 0, JOY_BUTTON_A)
	_tap(router, 1, JOY_BUTTON_START)
	_stick(router, 1, 1.0)
	t.check(router.slot_bits(1) == 0 and router.slot_bits(2) == InputBits.RIGHT,
		"twee pads met één GUID lopen door elkaar")
	router.on_joy_connection_changed(1, false)
	guids.erase(1)
	guids[2] = GUID_XBOX
	router.on_joy_connection_changed(2, true)
	t.check(router.slot_device(1) == "joy0", "plaats 1 verloor zijn pad")
	t.check(router.slot_device(2) == "joy2", "teruggekeerde pad kreeg plaats 2 niet")
	router.free()


## Werkaanname: een plaats waarvan het apparaat weg is, kan een ander apparaat overnemen
## (lege batterij, andere pad gepakt). Plaats 1: elke knop; plaats 2: meedoen.
func test_other_device_takes_over_a_waiting_slot(t) -> void:
	var guids := {0: GUID_XBOX, 1: GUID_DS4, 2: "03000000de2800000512000011010000"}
	var router := _router(guids)
	_tap(router, 0, JOY_BUTTON_A)
	_tap(router, 1, JOY_BUTTON_START)
	router.on_joy_connection_changed(0, false)
	router.on_joy_connection_changed(1, false)
	_tap(router, 2, JOY_BUTTON_A)
	t.check(router.slot_device(1) == "joy2", "elke knop nam plaats 1 niet over")
	router.handle_event(_key(KEY_RIGHT, true))
	t.check(router.slot_state(2) == InputRouter.SlotState.SUSPENDED, "pijltje nam plaats 2 over")
	router.handle_event(_key(KEY_ENTER, true))
	t.check(router.slot_device(2) == "kb2", "Enter nam plaats 2 niet over")
	t.check(router.slot_guid(2) == InputRouter.KEYBOARD_GUID,
		"GUID van plaats 2 is niet bijgewerkt")
	router.free()


## Drop-in en drop-out in een draaiende Sim: PlayerActor leest de plaats via `source_for`
## en staat stil zolang de plaats vrij is. De router zit in de boom en telt zelf ticks.
func test_drop_in_and_out_drive_player_in_sim(t) -> void:
	var sim = t.make_sim()
	var router := _router({})
	t.world_root().add_child(router)
	var player := PlayerActor.new()
	player.setup(2, router.source_for(2), Color.WHITE)
	player.position = SpikeWorld.PLAYER_SPAWN
	sim.add_player(player)
	router.handle_event(_key(KEY_A, true))
	router.handle_event(_key(KEY_A, false))
	router.handle_event(_key(KEY_RIGHT, true))
	await t.run_ticks(sim, 30)
	var x_before_join := player.position.x
	t.check(is_equal_approx(x_before_join, SpikeWorld.PLAYER_SPAWN.x),
		"P2 bewoog vóór meedoen: x %.2f" % x_before_join)
	router.handle_event(_key(KEY_ENTER, true))
	router.handle_event(_key(KEY_ENTER, false))
	await t.run_ticks(sim, 30)
	t.check(player.position.x > x_before_join + 10.0,
		"P2 bewoog niet na meedoen: x %.2f" % player.position.x)
	router.handle_event(_key(KEY_BACKSPACE, true))
	await t.run_ticks(sim, 65)
	t.check(router.slot_state(2) == InputRouter.SlotState.FREE, "P2 niet weg na 65 ticks stoppen")
	var x_after_leave := player.position.x
	await t.run_ticks(sim, 30)
	t.check(is_equal_approx(player.position.x, x_after_leave),
		"P2 bewoog na stoppen: %.2f -> %.2f" % [x_after_leave, player.position.x])
	t.note("P2 x: start %.1f, na meedoen +30 ticks verder, gestopt op %.1f"
		% [x_before_join, x_after_leave])


## Overdracht voor T16c: met `set_physics_process(false)` telt de router zelf niet meer, en
## telt hij precies mee met de Sim als die `step()` aanroept (hier via `tick_finished`).
func test_sim_can_drive_step_after_set_physics_process_false(t) -> void:
	var sim = t.make_sim()
	var router := _router({})
	t.world_root().add_child(router)
	router.set_physics_process(false)
	router.handle_event(_key(KEY_A, true))
	router.handle_event(_key(KEY_A, false))
	router.handle_event(_key(KEY_ENTER, true))
	router.handle_event(_key(KEY_ENTER, false))
	router.handle_event(_key(KEY_BACKSPACE, true))
	await t.run_ticks(sim, 90)
	t.check(router.slot_state(2) == InputRouter.SlotState.ACTIVE,
		"router telde zelf door na set_physics_process(false)")
	sim.tick_finished.connect(func(_tick: int) -> void: router.step())
	await t.run_ticks(sim, InputRouter.LEAVE_HOLD_TICKS - 1)
	t.check(router.slot_state(2) == InputRouter.SlotState.ACTIVE, "P2 weg na 59 Sim-ticks")
	await t.run_ticks(sim, 1)
	t.check(router.slot_state(2) == InputRouter.SlotState.FREE, "P2 niet weg na 60 Sim-ticks")


## Het autoload bestaat en echte events (via de viewport) bereiken `_input`.
func test_autoload_exists_and_viewport_events_reach_router(t) -> void:
	t.check(t.tree.root.has_node("InputRouter"), "autoload InputRouter ontbreekt")
	var router := _router({})
	t.tree.root.add_child(router)
	t.tree.root.push_input(_key(KEY_SPACE, true))
	t.check(router.slot_device(1) == "kb1", "event via de viewport kwam niet aan")
	t.tree.root.push_input(_key(KEY_SPACE, false))
	router.free()


## Loslaten tijdens een pauze komt aan, en de stopknop telt niet door tijdens de pauze.
## Focusverlies (alt-tab) zet alle knoppen los (review TD op PR #90).
func test_pause_and_focus_loss_leave_no_stuck_controls(t) -> void:
	var router := _router({1: GUID_DS4})
	t.tree.root.add_child(router)
	_tap(router, 1, JOY_BUTTON_A)
	router.handle_event(_key(KEY_ENTER, true))
	router.handle_event(_key(KEY_ENTER, false))
	router.handle_event(_key(KEY_RIGHT, true))
	router.handle_event(_key(KEY_BACKSPACE, true))
	t.tree.paused = true
	t.tree.root.push_input(_key(KEY_RIGHT, false))
	for i in 70:
		await t.tree.physics_frame
	t.tree.paused = false
	t.check(router.slot_state(2) == InputRouter.SlotState.ACTIVE,
		"stopknop telde door tijdens de pauze")
	t.check(router.slot_bits(2) == 0, "pijltje losgelaten tijdens pauze blijft hangen: %s"
		% InputBits.describe(router.slot_bits(2)))
	_stick(router, 1, 1.0)
	_pad(router, 1, JOY_BUTTON_A, true)
	router.notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	t.check(router.slot_bits(1) == 0, "knoppen blijven hangen na focusverlies")
	t.check(router.slot_device(1) == "joy1" and router.slot_device(2) == "kb2",
		"focusverlies kostte een plaats")
	router.handle_event(_key(KEY_BACKSPACE, false))
	router.free()


## Het controlescherm voor echte hardware laadt zonder fouten en toont beide plaatsen.
func test_debug_scene_shows_both_slots(t) -> void:
	var scene: PackedScene = load("res://scenes/debug/input_debug.tscn")
	var debug: Control = scene.instantiate()
	t.tree.root.add_child(debug)
	await t.tree.process_frame
	var text: String = debug.get_child(0).text
	t.check(text.contains("Plaats 1:") and text.contains("Plaats 2:"),
		"controlescherm toont de plaatsen niet")
	debug.free()
