extends RefCounted
## Inputbron die een vooraf vastgelegd script afspeelt (voor tests en demo's).
##
## Het script is een lijst van [aantal_ticks, bits]-paren. Na het einde
## geeft de bron 0 (niets ingedrukt).

var _segments: Array
var _start_tick := -1


func _init(segments: Array) -> void:
	_segments = segments


func sample(tick: int) -> int:
	if _start_tick < 0:
		_start_tick = tick
	var local := tick - _start_tick
	for segment: Array in _segments:
		var length: int = segment[0]
		if local < length:
			return segment[1]
		local -= length
	return 0


## Totale lengte van het script in ticks.
func length() -> int:
	var total := 0
	for segment: Array in _segments:
		total += int(segment[0])
	return total
