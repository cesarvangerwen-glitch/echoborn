extends RefCounted
## Tests voor de input-acties van 2 lokale spelers (issue #14).

const InputSetup = preload("res://scripts/input/input_setup.gd")


func _key(keycode: Key, location: KeyLocation) -> InputEventKey:
	var key := InputEventKey.new()
	key.physical_keycode = keycode
	key.location = location
	key.pressed = true
	return key


## P2-echo zit op rechter Ctrl: linker Ctrl mag `p2_action` niet starten.
func test_p2_action_only_on_right_ctrl(t) -> void:
	InputSetup.ensure_actions()
	t.check(InputMap.event_is_action(_key(KEY_CTRL, KEY_LOCATION_RIGHT), "p2_action", true),
		"rechter Ctrl start p2_action niet")
	t.check(not InputMap.event_is_action(_key(KEY_CTRL, KEY_LOCATION_LEFT), "p2_action", true),
		"linker Ctrl start ook p2_action")
	t.check(not InputMap.event_is_action(_key(KEY_CTRL, KEY_LOCATION_LEFT), "p1_action", true),
		"linker Ctrl start p1_action")
	t.check(InputMap.event_is_action(_key(KEY_E, KEY_LOCATION_UNSPECIFIED), "p1_action", true),
		"E start p1_action niet")
