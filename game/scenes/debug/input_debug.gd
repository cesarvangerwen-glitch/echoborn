extends Control
## Controlescherm voor de InputRouter op echte hardware (`docs/tech/input.md` §4).
##
## Toont de aangesloten joypads met index, naam en GUID, de twee plaatsen en hun bits, en
## een log van meedoen, stoppen, weg en terug. Elke logregel gaat ook naar stdout.

const InputBits = preload("res://scripts/input/input_bits.gd")

const STATE_NAMES := ["vrij", "speelt", "wacht op apparaat"]
const MAX_LOG_LINES := 14

var _router: Node
var _label: Label
var _log: PackedStringArray = []
var _frame := 0
## Index -> GUID, bewaard terwijl de pad aangesloten is: na ontkoppelen geeft Godot "".
var _guids: Dictionary = {}


func _ready() -> void:
	_label = Label.new()
	_label.position = Vector2(16, 16)
	add_child(_label)
	_router = get_node("/root/InputRouter")
	_router.slot_joined.connect(func(slot: int, device: String) -> void:
		_add_log("plaats %d: meedoen met %s" % [slot, device]))
	_router.slot_left.connect(func(slot: int, reason: String) -> void:
		_add_log("plaats %d: weg (%s)" % [slot, reason]))
	_router.slot_suspended.connect(func(slot: int) -> void:
		_add_log("plaats %d: apparaat weg, wacht" % slot))
	_router.slot_resumed.connect(func(slot: int, device: String) -> void:
		_add_log("plaats %d: terug met %s" % [slot, device]))
	Input.joy_connection_changed.connect(_on_joy_connection_changed)
	_refresh()


func _process(_delta: float) -> void:
	_frame += 1
	_refresh()


func _refresh() -> void:
	var lines: PackedStringArray = ["InputRouter-controle  (frame %d)" % _frame, ""]
	lines.append("Aangesloten joypads:")
	var pads := Input.get_connected_joypads()
	if pads.is_empty():
		lines.append("  geen")
	for device in pads:
		_guids[device] = Input.get_joy_guid(device)
		lines.append("  joy%d  %s  GUID %s  %s" % [device, Input.get_joy_name(device),
			Input.get_joy_guid(device), Input.get_joy_info(device)])
	lines.append("")
	for slot in range(1, 3):
		lines.append("Plaats %d: %s  apparaat %s  GUID %s  bits %s" % [slot,
			STATE_NAMES[_router.slot_state(slot)], _router.slot_device(slot),
			_router.slot_guid(slot), InputBits.describe(_router.slot_bits(slot))])
	lines.append("")
	lines.append("Log:")
	lines.append_array(_log)
	_label.text = "\n".join(lines)


func _on_joy_connection_changed(device: int, connected: bool) -> void:
	if connected:
		_guids[device] = Input.get_joy_guid(device)
	_add_log("joy%d %s: GUID %s" % [device, "aan" if connected else "los",
		_guids.get(device, "?")])
	if not connected:
		_guids.erase(device)


func _add_log(line: String) -> void:
	print("[input] %s" % line)
	_log.append(line)
	if _log.size() > MAX_LOG_LINES:
		_log.remove_at(0)
