extends RefCounted
## Zet de acties voor 2 lokale spelers in de InputMap en legt de joypadknoppen vast.
##
## Toetsenbord en joypad volgens gdd §2.5; de volledige tabel en de werkaannames staan in
## `docs/tech/input.md` §2a. Helft 1 = WASD-kant, helft 2 = pijltjeskant, met meedoen (Enter)
## en stoppen (Backspace) op helft 2. Later komt dit uit een rebind-scherm (UX Designer) en
## een opgeslagen config; de actienamen blijven gelijk.

const InputBits = preload("res://scripts/input/input_bits.gd")

const ALL_DEVICES := -1
## Drempel voor stick en acties, voor de InputMap en de InputRouter gelijk.
const DEADZONE := 0.3

## Spelbesturing (worden bits). Meedoen en stoppen zijn géén bits (gdd §2.5).
## `down` = de Neerslag (V-01, bit 7; TD-besluit PR #201).
const CONTROLS: PackedStringArray = ["left", "right", "jump", "attack", "interact", "echo", "dash",
	"down"]

## Knopbesturing -> inputbit (left en right komen ook van de stick, zie de InputRouter).
const BUTTON_BITS := {
	"left": InputBits.LEFT,
	"right": InputBits.RIGHT,
	"jump": InputBits.JUMP,
	"attack": InputBits.ATTACK,
	"interact": InputBits.INTERACT,
	"echo": InputBits.ECHO,
	"dash": InputBits.DASH,
	"down": InputBits.DOWN,
}

## Fysieke toetsen (positie, niet het teken): op AZERTY en QWERTZ liggen ze op dezelfde plek.
const KEYS := {
	1: {"left": KEY_A, "right": KEY_D, "jump": KEY_SPACE, "attack": KEY_E,
		"interact": KEY_F, "echo": KEY_Q, "dash": KEY_SHIFT, "down": KEY_S},
	2: {"left": KEY_LEFT, "right": KEY_RIGHT, "jump": KEY_ENTER, "attack": KEY_CTRL,
		"interact": KEY_SLASH, "echo": KEY_PERIOD, "dash": KEY_SHIFT, "down": KEY_DOWN,
		"join": KEY_ENTER, "leave": KEY_BACKSPACE},
}
## Toetsen waarvan alleen de linker- of rechtervariant telt. Zonder `location`
## matcht KEY_CTRL beide Ctrl-toetsen, en dan start linker Ctrl ook de echo
## van P2 (#14).
const KEY_LOCATIONS := {
	"p2_attack": KEY_LOCATION_RIGHT,
	"p1_dash": KEY_LOCATION_LEFT,
	"p2_dash": KEY_LOCATION_RIGHT,
}

## Joypadknoppen per besturing, voor elke pad gelijk (de InputRouter kiest de speler).
## Meedoen = Start/Menu, stoppen = Select/View, echo = linker en dash = rechter schouderknop
## (gdd §2.5). D-pad omlaag = DOWN (Neerslag, bit 7); d-pad omhoog blijft vrij voor UP (bit 6).
const PAD_BUTTONS := {
	JOY_BUTTON_DPAD_LEFT: "left",
	JOY_BUTTON_DPAD_RIGHT: "right",
	JOY_BUTTON_A: "jump",
	JOY_BUTTON_X: "attack",
	JOY_BUTTON_Y: "interact",
	JOY_BUTTON_LEFT_SHOULDER: "echo",
	JOY_BUTTON_RIGHT_SHOULDER: "dash",
	JOY_BUTTON_DPAD_DOWN: "down",
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
