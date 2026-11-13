extends "res://scripts/objects/sim_object.gd"
## `SLICE_EIND` (gdd §4.5, §5.1; `wereld.md` §2.2, L-14 f; #83): het eind van
## de route-tijd van de slice. Een object in de inhoud van S1, bij het snelluik
## in de gang (`Layout.SNELLUIK`): het **wapent** zodra het middelpunt van P1
## onder de gang in de schacht van S9 is (x binnen het snelluik, y onder de
## vloer van de gang), en **meldt** `reached` op de eerste tick daarna waarop
## P1 op de vloer van de gang staat (voeten op `S1_FLOOR`, ± 1,5 px) binnen
## `MARGE` px van het snelluik. De lus is dan rond: van S9 door het snelluik
## terug in S1.
##
## Eén keer per scène; geen blijvende stand (de route-tijd is van een run, niet
## van de save). Alleen P1 (de route-tijd is die van P1); de echo en P2 tellen
## niet. Werkaanname (GP): dezelfde regel als de placeholder van de WLD in
## `kadewijk.gd` (kamerdoc §3f), dus dezelfde tick.

const PlayerActor = preload("res://scripts/echo/player_actor.gd")
const Layout = preload("res://levels/kadewijk/kadewijk_layout.gd")

## P1 kwam door het snelluik en staat op de gang.
signal reached(tick: int, at: Vector2)

## Zo ver naast het snelluik telt staan op de gang nog (px, het middelpunt).
const MARGE := 40.0

var armed := false
## Tick van `reached`, of -1.
var reached_tick := -1


func sim_update(tick: int, bodies: Array[Node2D]) -> void:
	if reached_tick >= 0:
		return
	for body in bodies:
		if not (body is PlayerActor and body.player_index == 1):
			continue
		var p1: PlayerActor = body
		var at := p1.global_position
		var luik := Layout.SNELLUIK
		if at.x >= luik.position.x and at.x <= luik.end.x and at.y > Layout.S1_FLOOR + Layout.HALF_H:
			armed = true
		if not armed or not p1.motor.on_floor:
			return
		if absf(at.y - (Layout.S1_FLOOR - Layout.HALF_H)) > 1.5:
			return
		if at.x < luik.position.x - MARGE or at.x > luik.end.x + MARGE:
			return
		reached_tick = tick
		reached.emit(tick, at)
		return
