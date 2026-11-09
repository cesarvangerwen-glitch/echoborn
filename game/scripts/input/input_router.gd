extends Node
## Koppelt invoerapparaten aan maximaal 2 spelersplaatsen en regelt drop-in/drop-out.
##
## Autoload `InputRouter` (ontwerp §3, §5). Joypads worden op apparaat-GUID herkend, zodat een
## pad die opnieuw aansluit met een andere index zijn plaats terugkrijgt (R19, C5). Regels en
## werkaannames: `docs/tech/input.md`.

signal slot_joined(slot: int, device: String)
signal slot_left(slot: int, reason: String)
signal slot_suspended(slot: int)
signal slot_resumed(slot: int, device: String)

enum SlotState { FREE, ACTIVE, SUSPENDED }

const InputBits = preload("res://scripts/input/input_bits.gd")
const InputSetup = preload("res://scripts/input/input_setup.gd")
const RouterInput = preload("res://scripts/input/router_input.gd")

## Co-op 7A: maximaal twee lichamen, dus twee plaatsen.
const MAX_SLOTS := 2
## Plaats 2 is de partner: alleen die kan stoppen (gdd C-05).
const PARTNER_SLOT := 2
## Stopknop vasthouden (gdd C-05, parameter van de UX Designer).
const LEAVE_HOLD_TICKS := 60
## Apparaat van de partner weg (gdd C-05, parameter van Engine & Platform).
const DISCONNECT_TICKS := 180
const KEYBOARD_GUID := "keyboard"

## Geeft de GUID van een joypad-index. Standaard `Input.get_joy_guid`; een test of een
## platformlaag (Steam Input) kan een andere bron geven.
var guid_lookup: Callable = Callable(Input, "get_joy_guid")

var _slots: Array[Dictionary] = []
## Apparaatsleutel ("kb1", "kb2", "joy<index>") -> toestand van dat apparaat.
var _devices: Dictionary = {}


func _init() -> void:
	InputSetup.ensure_actions()
	for i in MAX_SLOTS:
		_slots.append(_empty_slot())


func _ready() -> void:
	Input.joy_connection_changed.connect(on_joy_connection_changed)


func _input(event: InputEvent) -> void:
	handle_event(event)


func _physics_process(_delta: float) -> void:
	step()


## Verwerkt één InputEvent. Markeert het event niet als afgehandeld.
func handle_event(event: InputEvent) -> void:
	if event is InputEventKey:
		_handle_key(event)
	elif event is InputEventJoypadButton:
		_handle_pad_button(event)
	elif event is InputEventJoypadMotion:
		_handle_pad_motion(event)


## Eén tick: telt de stopknop en de tijd dat een apparaat weg is (gdd C-05). Loopt standaard
## in `_physics_process`; de Sim kan dat overnemen met `set_physics_process(false)`.
func step() -> void:
	for slot in range(1, MAX_SLOTS + 1):
		var s := _slots[slot - 1]
		if slot != PARTNER_SLOT:
			continue
		if s["state"] == SlotState.ACTIVE:
			if _is_pressed(s["device"], "leave"):
				s["leave_ticks"] += 1
				if s["leave_ticks"] >= LEAVE_HOLD_TICKS:
					_free(slot, "stoppen")
			else:
				s["leave_ticks"] = 0
		elif s["state"] == SlotState.SUSPENDED:
			s["gone_ticks"] += 1
			if s["gone_ticks"] >= DISCONNECT_TICKS:
				_free(slot, "apparaat weg")


## Koppelt aan `Input.joy_connection_changed`.
func on_joy_connection_changed(device: int, connected: bool) -> void:
	var key := _pad_key(device)
	if not connected:
		var slot := slot_of_device(key)
		_devices.erase(key)
		if slot != 0:
			var s := _slots[slot - 1]
			s["state"] = SlotState.SUSPENDED
			s["device"] = ""
			s["gone_ticks"] = 0
			s["leave_ticks"] = 0
			slot_suspended.emit(slot)
		return
	_devices.erase(key)
	var state := _device_state(key)
	for slot in range(1, MAX_SLOTS + 1):
		var s := _slots[slot - 1]
		if s["state"] == SlotState.SUSPENDED and s["guid"] == state["guid"]:
			_bind(slot, key)
			return


## Input-bits van een plaats voor deze tick; 0 als de plaats vrij of zonder apparaat is.
func slot_bits(slot: int) -> int:
	var s := _slots[slot - 1]
	if s["state"] != SlotState.ACTIVE:
		return 0
	return _device_bits(s["device"])


func slot_state(slot: int) -> SlotState:
	return _slots[slot - 1]["state"]


## Apparaatsleutel van een plaats ("" als er geen apparaat aan hangt).
func slot_device(slot: int) -> String:
	return _slots[slot - 1]["device"]


## GUID waarop de plaats wacht of draait ("" als de plaats vrij is).
func slot_guid(slot: int) -> String:
	return _slots[slot - 1]["guid"]


## Plaats van een apparaat, of 0 als het apparaat geen plaats heeft.
func slot_of_device(key: String) -> int:
	for slot in range(1, MAX_SLOTS + 1):
		if _slots[slot - 1]["state"] == SlotState.ACTIVE and _slots[slot - 1]["device"] == key:
			return slot
	return 0


## Inputbron voor een plaats, voor `PlayerActor.setup` (zelfde interface als DeviceInput).
func source_for(slot: int) -> RouterInput:
	return RouterInput.new(self, slot)


## Maakt een plaats vrij, bv. bij terug naar het titelscherm (gameplay of UX beslist).
func release_slot(slot: int) -> void:
	if _slots[slot - 1]["state"] != SlotState.FREE:
		_free(slot, "vrijgegeven")


func _handle_key(event: InputEventKey) -> void:
	for half: int in InputSetup.KEYS:
		var key := "kb%d" % half
		var controls: PackedStringArray = []
		for control: String in InputSetup.KEYS[half]:
			if event.is_action("p%d_%s" % [half, control]):
				_set_pressed(key, control, event.pressed)
				controls.append(control)
		if not controls.is_empty() and event.pressed and not event.echo:
			_on_press(key, controls)


func _handle_pad_button(event: InputEventJoypadButton) -> void:
	var key := _pad_key(event.device)
	var controls: PackedStringArray = []
	var control: String = InputSetup.PAD_BUTTONS.get(event.button_index, "")
	if control != "":
		_set_pressed(key, control, event.pressed)
		controls.append(control)
	else:
		_device_state(key)
	if event.pressed:
		_on_press(key, controls)


func _handle_pad_motion(event: InputEventJoypadMotion) -> void:
	if event.axis == InputSetup.PAD_AXIS_X:
		_device_state(_pad_key(event.device))["axis_x"] = event.axis_value


## Een knop die net is ingedrukt op een apparaat zonder plaats: meedoen of overnemen.
## `controls` zijn de besturingen van die ene knop (Enter = springen + meedoen).
func _on_press(key: String, controls: PackedStringArray) -> void:
	if slot_of_device(key) != 0:
		return
	var slot := _claimable_slot(controls)
	if slot == 0:
		return
	_bind(slot, key)
	# De knop die liet meedoen, doet in het spel niets tot hij is losgelaten.
	for control in controls:
		_device_state(key)["swallowed"][control] = true


## Werkaanname: plaats 1 neemt elke knop (titelscherm); plaats 2 alleen "meedoen" (C-03).
## Een plaats waarvan het apparaat weg is, gaat vóór een vrije plaats.
func _claimable_slot(controls: PackedStringArray) -> int:
	var first: SlotState = _slots[0]["state"]
	if first != SlotState.ACTIVE:
		return 1
	var partner: SlotState = _slots[PARTNER_SLOT - 1]["state"]
	if partner != SlotState.ACTIVE and "join" in controls:
		return PARTNER_SLOT
	return 0


func _bind(slot: int, key: String) -> void:
	var s := _slots[slot - 1]
	var resumed: bool = s["state"] == SlotState.SUSPENDED
	s["state"] = SlotState.ACTIVE
	s["device"] = key
	s["guid"] = _device_state(key)["guid"]
	s["leave_ticks"] = 0
	s["gone_ticks"] = 0
	if resumed:
		slot_resumed.emit(slot, key)
	else:
		slot_joined.emit(slot, key)


func _free(slot: int, reason: String) -> void:
	_slots[slot - 1] = _empty_slot()
	slot_left.emit(slot, reason)


func _device_bits(key: String) -> int:
	if not _devices.has(key):
		return 0
	var axis_x: float = _devices[key]["axis_x"]
	var bits := 0
	if _is_pressed(key, "left") or axis_x < -InputSetup.DEADZONE:
		bits |= InputBits.LEFT
	if _is_pressed(key, "right") or axis_x > InputSetup.DEADZONE:
		bits |= InputBits.RIGHT
	if _is_pressed(key, "jump"):
		bits |= InputBits.JUMP
	if _is_pressed(key, "action"):
		bits |= InputBits.ACTION
	return bits


func _is_pressed(key: String, control: String) -> bool:
	if not _devices.has(key):
		return false
	var state: Dictionary = _devices[key]
	return state["pressed"].get(control, false) and not state["swallowed"].has(control)


func _set_pressed(key: String, control: String, pressed: bool) -> void:
	var state := _device_state(key)
	state["pressed"][control] = pressed
	if not pressed:
		state["swallowed"].erase(control)


## Toestand van een apparaat; maakt hem aan bij het eerste event (pads die al aangesloten
## waren bij de start, geven geen `joy_connection_changed`).
func _device_state(key: String) -> Dictionary:
	if not _devices.has(key):
		var guid := KEYBOARD_GUID
		if key.begins_with("joy"):
			guid = guid_lookup.call(int(key.substr(3)))
		_devices[key] = {"guid": guid, "pressed": {}, "axis_x": 0.0, "swallowed": {}}
	return _devices[key]


func _pad_key(device: int) -> String:
	return "joy%d" % device


func _empty_slot() -> Dictionary:
	return {"state": SlotState.FREE, "device": "", "guid": "", "leave_ticks": 0, "gone_ticks": 0}
