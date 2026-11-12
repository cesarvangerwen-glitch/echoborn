extends RefCounted
## Bitmasker voor één tick input van één speler (gdd §2.5, inputbitset v0.4).
##
## Eén int per tick per speler: compact en exact vergelijkbaar. Bit 7 (DOWN)
## is de Neerslag (V-01); bit 6 (UP) is gereserveerd voor de Combat Designer.

const LEFT := 1
const RIGHT := 2
const JUMP := 4
## AANVAL (gdd §2.5, bit 3). Heette ACTION in de spike.
const ATTACK := 8
## INTERACTIE (bit 4): hendel, deur, oppakken.
const INTERACT := 16
## Echo-knop (bit 5): Loslaten na 30 ticks vasthouden (E-09). Nooit een event.
const ECHO := 32
## Omlaag (bit 7): de Neerslag (V-01, gdd §2.5). Zit in de toestand, geen event. UP (bit 6)
## blijft gereserveerd.
const DOWN := 128
## Dash (bit 8, §2.5a).
const DASH := 256


static func describe(bits: int) -> String:
	var parts: PackedStringArray = []
	if bits & LEFT:
		parts.append("L")
	if bits & RIGHT:
		parts.append("R")
	if bits & JUMP:
		parts.append("J")
	if bits & ATTACK:
		parts.append("A")
	if bits & INTERACT:
		parts.append("I")
	if bits & ECHO:
		parts.append("E")
	if bits & DOWN:
		parts.append("v")
	if bits & DASH:
		parts.append("D")
	return "-" if parts.is_empty() else "".join(parts)
