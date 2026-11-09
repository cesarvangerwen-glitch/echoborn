extends RefCounted
## Zet de input van één speler per tick om in events (gdd E-10).
##
## Een event ontstaat op de tick waarop het bit van 0 naar 1 gaat (flank),
## tenzij dezelfde soort minder dan `cooldown` ticks geleden ontstond.
## Alleen ticks tellen; geen tijd, geen `Input` (standaarden §4).

const GameEvents = preload("res://scripts/events/game_events.gd")

const NEVER := -1_000_000

var _previous_bits := 0
var _last_tick := PackedInt32Array()


func _init() -> void:
	_last_tick.resize(GameEvents.FROM_INPUT.size())
	_last_tick.fill(NEVER)


## Events van deze tick als bitmasker (GameEvents.ATTACK, ...).
func detect(tick: int, bits: int) -> int:
	var events := 0
	var rising := bits & ~_previous_bits
	for i in GameEvents.FROM_INPUT.size():
		var rule: Dictionary = GameEvents.FROM_INPUT[i]
		if rising & int(rule["bit"]) and tick - _last_tick[i] >= int(rule["cooldown"]):
			events |= int(rule["event"])
			_last_tick[i] = tick
	_previous_bits = bits
	return events


func reset() -> void:
	_previous_bits = 0
	_last_tick.fill(NEVER)
