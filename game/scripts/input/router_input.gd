extends RefCounted
## Inputbron voor één spelersplaats van de InputRouter.
##
## Zelfde interface als DeviceInput en ScriptedInput (`sample(tick) -> int`), zodat
## PlayerActor niet weet of een plaats bezet is: een vrije plaats geeft gewoon 0.

## Plaats 1 of 2.
var slot: int

var _router: Node


func _init(p_router: Node, p_slot: int) -> void:
	_router = p_router
	slot = p_slot


## Geeft de input-bits van deze plaats. `_tick` hoort bij de interface.
func sample(_tick: int) -> int:
	return _router.slot_bits(slot)
