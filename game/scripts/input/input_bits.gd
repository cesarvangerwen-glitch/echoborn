extends RefCounted
## Bitmasker voor één tick input van één speler.
##
## Eén int per tick per speler: compact (600 ticks = 2,4 kB) en exact
## vergelijkbaar. Nieuwe knoppen krijgen het volgende vrije bit.

const LEFT := 1
const RIGHT := 2
const JUMP := 4
const ACTION := 8


static func describe(bits: int) -> String:
	var parts: PackedStringArray = []
	if bits & LEFT:
		parts.append("L")
	if bits & RIGHT:
		parts.append("R")
	if bits & JUMP:
		parts.append("J")
	if bits & ACTION:
		parts.append("A")
	return "-" if parts.is_empty() else "".join(parts)
