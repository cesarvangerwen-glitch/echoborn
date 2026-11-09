extends RefCounted
## Bitmasker voor één tick input van één speler.
##
## Eén int per tick per speler: compact (600 ticks = 2,4 kB) en exact
## vergelijkbaar. Nieuwe knoppen krijgen het volgende vrije bit.

const LEFT := 1
const RIGHT := 2
const JUMP := 4
const ACTION := 8
## INTERACTIE uit gdd §2.5 (bit 4). Alleen nog als bit; een toets volgt met
## de volledige bitset van de Gameplay Programmer (T16a).
const INTERACT := 16


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
	if bits & INTERACT:
		parts.append("I")
	return "-" if parts.is_empty() else "".join(parts)
