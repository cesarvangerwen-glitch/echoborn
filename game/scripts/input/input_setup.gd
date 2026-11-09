extends RefCounted
## Zet de acties voor 2 lokale spelers in de InputMap en legt de joypadknoppen vast.
##
## Toetsenbord: helft 1 = WASD + spatie + E (+ linker Shift = dash, Q = echo-knop,
## gdd §2.5; de InputRouter zet die nog niet om in bits), helft 2 = pijltjes + Enter + rechter Ctrl,
## met meedoen (Enter) en stoppen (Backspace) op helft 2 (gdd §2.5). Later komt dit uit
## een rebind-scherm (UX Designer) en een opgeslagen config; de actienamen blijven gelijk.

const ALL_DEVICES := -1
## Drempel voor stick en acties, voor de InputMap en de InputRouter gelijk.
const DEADZONE := 0.3

## Spelbesturing (worden bits). Meedoen en stoppen zijn géén bits (gdd §2.5).
const CONTROLS: PackedStringArray = ["left", "right", "jump", "action"]

const KEYS := {
	1: {"left": KEY_A, "right": KEY_D, "jump": KEY_SPACE, "action": KEY_E,
		"dash": KEY_SHIFT, "echo": KEY_Q},
	2: {"left": KEY_LEFT, "right": KEY_RIGHT, "jump": KEY_ENTER, "action": KEY_CTRL,
		"join": KEY_ENTER, "leave": KEY_BACKSPACE},
}
## Toetsen waarvan alleen de linker- of rechtervariant telt. Zonder `location`
## matcht KEY_CTRL beide Ctrl-toetsen, en dan start linker Ctrl ook de echo
## van P2 (#14).
const KEY_LOCATIONS := {
	"p2_action": KEY_LOCATION_RIGHT,
	"p1_dash": KEY_LOCATION_LEFT,
}

## Joypadknoppen per besturing, voor elke pad gelijk (de InputRouter kiest de speler).
## Meedoen = Start/Menu, stoppen = Select/View (gdd §2.5).
const PAD_BUTTONS := {
	JOY_BUTTON_DPAD_LEFT: "left",
	JOY_BUTTON_DPAD_RIGHT: "right",
	JOY_BUTTON_A: "jump",
	JOY_BUTTON_X: "action",
	JOY_BUTTON_START: "join",
	JOY_BUTTON_BACK: "leave",
}
const PAD_AXIS_X := JOY_AXIS_LEFT_X


static func ensure_actions() -> void:
	for player: int in KEYS:
		var device := player - 1
		var keys: Dictionary = KEYS[player]
		for action_name: String in keys:
			var action := "p%d_%s" % [player, action_name]
			if InputMap.has_action(action):
				continue
			InputMap.add_action(action, DEADZONE)
			var key := InputEventKey.new()
			key.device = ALL_DEVICES
			key.physical_keycode = keys[action_name]
			key.location = KEY_LOCATIONS.get(action, KEY_LOCATION_UNSPECIFIED)
			InputMap.action_add_event(action, key)
			# Vaste joypad-index per speler: alleen voor DeviceInput (spike, main.gd).
			# De InputRouter leest joypads zelf, op apparaat-GUID.
			if action_name in CONTROLS:
				InputMap.action_add_event(action, _joy_event(action_name, device))


static func _joy_event(action_name: String, device: int) -> InputEvent:
	if action_name == "left" or action_name == "right":
		var motion := InputEventJoypadMotion.new()
		motion.device = device
		motion.axis = PAD_AXIS_X
		motion.axis_value = -1.0 if action_name == "left" else 1.0
		return motion
	var button := InputEventJoypadButton.new()
	button.device = device
	button.button_index = PAD_BUTTONS.find_key(action_name)
	return button
