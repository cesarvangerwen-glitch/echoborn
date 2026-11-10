extends RefCounted
## Respawn bij 0 levenspunten (gdd E-04b, C-08, LM-05, LM-08; T5b deel 3b,
## punt 1, #82; ontwerp.md §7).
##
## Valt het aantal levenspunten van P1 op 0, dan zet dit P1 op de volgende
## tick terug (`PlayerActor.respawn_at(…, death = true)`):
## - op het checkpoint in `Progress.state` (`checkpoint_positie`, LM-08) als
##   er een is in het gebied van nu (`Progress.has_checkpoint_in_area`);
## - anders op het begin van de kamer (`room_start`, zoals LM-05 in de
##   flow-kamer): bij een nieuw spel, zonder `Progress` of zonder loader, en
##   in een nieuw gebied vóór zijn eerste checkpoint.
##
## Wat er op de respawntick gebeurt, doet de bestaande weg:
## - `PlayerActor`: positie, stilstand, levenspunten weer vol
##   (`p1_health`), `echo_reset = RESPAWN` en `died`.
## - De echo is D ticks Leeg en `geldig_vanaf` = de respawntick (E-04b).
## - De AreaLoader volgt P1 in stap (3): een checkpoint in een kamer die geen
##   buur is, is een kamerwissel met reset (E-04a) en laadt die kamer.
## - In co-op zet de Sim P2 naast P1 volgens de plaatsingsregel (C-08, C-03),
##   ook een opgeloste P2.
## - Het `Checkpoint` voelt P1 binnenkomen in stap (5): een extra autosave op
##   dezelfde plek (§7).
## Een respawn laadt de save niet opnieuw: L, G, hendels en sluizen blijven
## zoals ze zijn (LM-05, LM-06).
##
## Randgeval (§7): de laatste treffer valt in stap (5) van tick `t0 − 1`.
## Zet een object later in die stap nog een nieuw checkpoint (binnenlopen),
## dan geldt dat nieuwe: `Progress.checkpoint_reached` vóór de respawntick
## verplaatst de respawn erheen en meldt `requested` opnieuw. Zo klopt de
## respawnplek altijd met de save.
##
## Niet hier: terugzetten na een gemiste sprong, diep water of doorns
## (L-10, LM-06) gaat naar de laatste vloerpositie, nooit naar het
## checkpoint; dat roept `respawn_at` zonder `death` aan.
##
## Gebruik in een gebiedsscène (houd een verwijzing vast: een `RefCounted`
## zonder verwijzing verdwijnt, en dan ook de verbinding):
##   respawn = Respawn.new(p1, func() -> Vector2: return kamer_begin, Progress)

const PlayerActor = preload("res://scripts/echo/player_actor.gd")

## P1 viel op tick `tick` op 0 levenspunten en respawnt op de volgende tick
## op `positie`; `op_checkpoint` = het checkpoint (anders het begin van de kamer).
signal requested(tick: int, positie: Vector2, op_checkpoint: bool)

var p1: PlayerActor
## Geeft het begin van de kamer waar P1 nu is (`() -> Vector2`).
var room_start: Callable
## De autoload `Progress` of een eigen node in een test; null = geen
## checkpoint (altijd het begin van de kamer).
var progress: Node

## Tick van de laatste treffer zolang de respawn nog moet komen, anders -1.
var _pending_tick := -1


func _init(p_p1: PlayerActor, p_room_start: Callable, p_progress: Node = null) -> void:
	p1 = p_p1
	room_start = p_room_start
	progress = p_progress
	p1.health_changed.connect(_on_health_changed)
	if is_instance_valid(progress):
		progress.checkpoint_reached.connect(_on_checkpoint_reached)


## Respawnt P1 nu op het checkpoint?
func has_checkpoint() -> bool:
	return is_instance_valid(progress) and progress.has_checkpoint_in_area()


## Waar P1 nu zou respawnen.
func target() -> Vector2:
	if has_checkpoint():
		return progress.state.checkpoint_positie
	return room_start.call()


func _on_health_changed(tick: int, health: int) -> void:
	if health > 0:
		# Stap (2) van de respawntick: de levenspunten zijn weer vol.
		_pending_tick = -1
		return
	_pending_tick = tick
	var on_checkpoint := has_checkpoint()
	var at: Vector2 = progress.state.checkpoint_positie if on_checkpoint else room_start.call()
	p1.respawn_at(at, true)
	requested.emit(tick, at, on_checkpoint)


## Randgeval (§7): een nieuw checkpoint nadat P1 op 0 viel, maar vóór de
## respawntick, wordt de respawnplek.
func _on_checkpoint_reached(_kamer: StringName, _positie: Vector2) -> void:
	if _pending_tick < 0 or not has_checkpoint():
		return
	var at: Vector2 = progress.state.checkpoint_positie
	p1.respawn_at(at, true)
	requested.emit(_pending_tick, at, true)
