extends RefCounted
## Inputbron voor één lokale speler, gelezen uit de InputMap.
##
## Elke speler heeft eigen acties met prefix `p<n>_` (bv. `p1_left`).
## Spelcode leest nooit rechtstreeks `Input`; alleen een inputbron doet dat.
## Zo kunnen tests en de echo dezelfde code voeden met andere bronnen.

const InputSetup = preload("res://scripts/input/input_setup.gd")

var player_index: int


func _init(p_player_index: int) -> void:
	player_index = p_player_index


## Geeft de input-bits voor deze tick. `_tick` wordt hier niet gebruikt,
## maar hoort bij de interface die ook ScriptedInput heeft.
func sample(_tick: int) -> int:
	var prefix := "p%d_" % player_index
	var bits := 0
	for control: String in InputSetup.BUTTON_BITS:
		if Input.is_action_pressed(prefix + control):
			bits |= InputSetup.BUTTON_BITS[control]
	return bits
