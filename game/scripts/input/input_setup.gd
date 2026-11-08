extends RefCounted
## Zet de acties voor 2 lokale spelers in de InputMap (spike, v0).
##
## P1: WASD + spatie + E, en joypad 0.  P2: pijltjes + Enter + rechter Ctrl,
## en joypad 1. Later komt dit uit een rebind-scherm (UX Designer) en een
## opgeslagen config; de actienamen blijven gelijk.

const ALL_DEVICES := -1

const KEYS := {
	1: {"left": KEY_A, "right": KEY_D, "jump": KEY_SPACE, "action": KEY_E},
	2: {"left": KEY_LEFT, "right": KEY_RIGHT, "jump": KEY_ENTER, "action": KEY_CTRL},
}


static func ensure_actions() -> void:
	for player: int in KEYS:
		var device := player - 1
		var keys: Dictionary = KEYS[player]
		for action_name: String in keys:
			var action := "p%d_%s" % [player, action_name]
			if InputMap.has_action(action):
				continue
			InputMap.add_action(action, 0.3)
			var key := InputEventKey.new()
			key.device = ALL_DEVICES
			key.physical_keycode = keys[action_name]
			InputMap.action_add_event(action, key)
			InputMap.action_add_event(action, _joy_event(action_name, device))


static func _joy_event(action_name: String, device: int) -> InputEvent:
	match action_name:
		"left", "right":
			var motion := InputEventJoypadMotion.new()
			motion.device = device
			motion.axis = JOY_AXIS_LEFT_X
			motion.axis_value = -1.0 if action_name == "left" else 1.0
			return motion
		"jump":
			var jump := InputEventJoypadButton.new()
			jump.device = device
			jump.button_index = JOY_BUTTON_A
			return jump
		_:
			var other := InputEventJoypadButton.new()
			other.device = device
			other.button_index = JOY_BUTTON_X
			return other
