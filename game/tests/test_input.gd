extends RefCounted
## Tests voor de input-acties van 2 lokale spelers (issue #14).

const InputSetup = preload("res://scripts/input/input_setup.gd")


func _key(keycode: Key, location: KeyLocation) -> InputEventKey:
	var key := InputEventKey.new()
	key.physical_keycode = keycode
	key.location = location
	key.pressed = true
	return key


## P2-aanval zit op rechter Ctrl (#14): linker Ctrl mag `p2_attack` niet starten.
func test_p2_attack_only_on_right_ctrl(t) -> void:
	InputSetup.ensure_actions()
	t.check(InputMap.event_is_action(_key(KEY_CTRL, KEY_LOCATION_RIGHT), "p2_attack", true),
		"rechter Ctrl start p2_attack niet")
	t.check(not InputMap.event_is_action(_key(KEY_CTRL, KEY_LOCATION_LEFT), "p2_attack", true),
		"linker Ctrl start ook p2_attack")
	t.check(not InputMap.event_is_action(_key(KEY_CTRL, KEY_LOCATION_LEFT), "p1_attack", true),
		"linker Ctrl start p1_attack")
	t.check(InputMap.event_is_action(_key(KEY_E, KEY_LOCATION_UNSPECIFIED), "p1_attack", true),
		"E start p1_attack niet")


## Dash zit op linker Shift (P1) en rechter Shift (P2): de helften sturen elkaar niet (#101).
func test_dash_shift_is_split_per_keyboard_half(t) -> void:
	InputSetup.ensure_actions()
	t.check(InputMap.event_is_action(_key(KEY_SHIFT, KEY_LOCATION_LEFT), "p1_dash", true),
		"linker Shift start p1_dash niet")
	t.check(not InputMap.event_is_action(_key(KEY_SHIFT, KEY_LOCATION_RIGHT), "p1_dash", true),
		"rechter Shift start ook p1_dash")
	t.check(InputMap.event_is_action(_key(KEY_SHIFT, KEY_LOCATION_RIGHT), "p2_dash", true),
		"rechter Shift start p2_dash niet")
	t.check(not InputMap.event_is_action(_key(KEY_SHIFT, KEY_LOCATION_LEFT), "p2_dash", true),
		"linker Shift start ook p2_dash")


## Elke spelbesturing bestaat voor P1 en P2, met een toets, een joypadknop of -as en een bit;
## geen toets hoort bij twee besturingen van verschillende spelers (#101).
func test_every_control_has_key_pad_and_bit_for_both_players(t) -> void:
	InputSetup.ensure_actions()
	var pad_controls: Array = InputSetup.PAD_BUTTONS.values()
	for control: String in InputSetup.CONTROLS:
		t.check(InputSetup.BUTTON_BITS.has(control), "%s heeft geen inputbit" % control)
		if control != "left" and control != "right":
			t.check(control in pad_controls, "%s heeft geen joypadknop" % control)
		for player: int in [1, 2]:
			var action := "p%d_%s" % [player, control]
			t.check(InputMap.has_action(action), "%s bestaat niet" % action)
			var has_key := false
			var has_pad := false
			for event in InputMap.action_get_events(action):
				has_key = has_key or event is InputEventKey
				has_pad = has_pad or event is InputEventJoypadButton \
					or event is InputEventJoypadMotion
			t.check(has_key and has_pad, "%s mist een toets of joypad-event" % action)
	for control: String in InputSetup.KEYS[1]:
		for other: String in InputSetup.KEYS[2]:
			var a := "p1_%s" % control
			var b := "p2_%s" % other
			if InputSetup.KEYS[1][control] == InputSetup.KEYS[2][other]:
				t.check(InputSetup.KEY_LOCATIONS.get(a, 0) != InputSetup.KEY_LOCATIONS.get(b, 0)
					and InputSetup.KEY_LOCATIONS.has(a) and InputSetup.KEY_LOCATIONS.has(b),
					"%s en %s delen een toets" % [a, b])
