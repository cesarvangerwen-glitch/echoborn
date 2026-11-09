extends RefCounted
## Soorten events en hoe ze uit de input ontstaan (gdd E-10).
##
## Een event is één bit in een int per tick per actor, net als de input.
## Zo neemt de recorder ze zonder extra allocaties op, en voert de Sim ze in
## een vaste volgorde uit (oplopend bit). Nieuwe soorten (bv. het schaduwmerk
## van E-14 of de merksprong van E-02, T3a/T16a) krijgen het volgende vrije
## bit en een regel in FROM_INPUT, of worden door hun eigen systeem gezet.

const InputBits = preload("res://scripts/input/input_bits.gd")

const ATTACK := 1    ## AANVAL (E-10, E-10a)
const INTERACT := 2  ## INTERACTIE (E-10b)

## Alle soorten in uitvoervolgorde.
const KINDS: PackedInt32Array = [ATTACK, INTERACT]

## Welk inputbit welk event geeft, met de herhaaltijd in ticks (E-10:
## binnen `cooldown` ticks na een event van die soort ontstaat er geen nieuw).
## Waarden zijn parameters uit gdd v0.2; T3a kan ze wijzigen.
const FROM_INPUT := [
	{"bit": InputBits.ATTACK, "event": ATTACK, "cooldown": 20},
	{"bit": InputBits.INTERACT, "event": INTERACT, "cooldown": 0},
]


static func describe(events: int) -> String:
	var parts: PackedStringArray = []
	if events & ATTACK:
		parts.append("aanval")
	if events & INTERACT:
		parts.append("interactie")
	return "-" if parts.is_empty() else "+".join(parts)
