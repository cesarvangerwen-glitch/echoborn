extends RefCounted
## Inputbron voor één lokale speler, gelezen uit de InputMap.
##
## Elke speler heeft eigen acties met prefix `p<n>_` (bv. `p1_left`).
## Spelcode leest nooit rechtstreeks `Input`; alleen een inputbron doet dat.
## Zo kunnen tests en de echo dezelfde code voeden met andere bronnen.

const InputBits = preload("res://scripts/input/input_bits.gd")

var player_index: int


func _init(p_player_index: int) -> void:
	player_index = p_player_index


## Geeft de input-bits voor deze tick. `_tick` wordt hier niet gebruikt,
## maar hoort bij de interface die ook ScriptedInput heeft.
func sample(_tick: int) -> int:
	var prefix := "p%d_" % player_index
	var bits := 0
	if Input.is_action_pressed(prefix + "left"):
		bits |= InputBits.LEFT
	if Input.is_action_pressed(prefix + "right"):
		bits |= InputBits.RIGHT
	if Input.is_action_pressed(prefix + "jump"):
		bits |= InputBits.JUMP
	if Input.is_action_pressed(prefix + "action"):
		bits |= InputBits.ACTION
	return bits
