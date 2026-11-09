extends RefCounted
## Samenwerkingsacties op een drager (gdd §2.7): vang (C-13) en lancering
## (C-11), na de stap van de springer. De bounce (C-10) is gewoon E-07a in
## `Motor`, op elke plank (schaduwplank en lichtplank).
##
## Een drager is P1, P2 of de solo-echo; hij heeft `plank`, `carrier_valid()`,
## `carrier_in_stance(tick)`, `consume_stance(tick)` en `carrier_facing()`.
## De springer is altijd een PlayerActor. Voorrang op dezelfde tick (C-11b):
## vang > lancering > bounce.

const Motor = preload("res://scripts/echo/motor.gd")
const Tuning = preload("res://scripts/echo/tuning.gd")

## Tolerantie voor "de onderkant raakt de bovenkant" (C-13 (2)), in px.
const CONTACT_MARGIN := 0.5


## Na `springer.sim_step(tick)`. `carrier` mag null zijn (geen tweede lichaam).
## `pre_position` en `pre_velocity` zijn de toestand vóór de stap.
static func after_step(tick: int, springer: Node2D, carrier: Node2D,
		pre_position: Vector2, pre_velocity: Vector2) -> void:
	if carrier == null or not is_instance_valid(carrier) or not carrier.carrier_valid():
		return
	if _try_catch(tick, springer, carrier, pre_position, pre_velocity):
		return
	_try_launch(tick, springer, carrier)


## C-13: alle vier de voorwaarden op deze tick, dan de zwiep.
static func _try_catch(tick: int, springer: Node2D, carrier: Node2D,
		pre_position: Vector2, pre_velocity: Vector2) -> bool:
	var c: Dictionary = Tuning.coop()
	var s: Motor.State = springer.motor
	var half_h := Tuning.body_size().y * 0.5
	# (1) snel vallen, niet in lanceerstaat.
	if pre_velocity.y < float(c["catch_min_fall_speed"]) or s.launch_left > 0 or s.launch_pending:
		return false
	# (4) één vang per luchtfase.
	if springer.caught_this_airphase:
		return false
	# (2) de onderkant gaat deze tick van boven door de bovenkant van de drager.
	var top: float = carrier.global_position.y - half_h
	var bottom_before := pre_position.y + half_h
	var bottom_after: float = springer.position.y + half_h
	# Wie deze tick op de plank landde, staat er met de veiligheidsmarge van
	# `move_and_slide` net boven (± 0,02 px): dat telt als erdoor.
	if bottom_before > top or bottom_after < top - CONTACT_MARGIN:
		return false
	# (3) vangvlak: middelpunten horizontaal binnen 24 px.
	if absf(springer.position.x - carrier.global_position.x) > float(c["catch_half_width_px"]):
		return false
	springer.position.y = top - half_h
	s.velocity.y = float(c["catch_swing_velocity"])
	s.on_floor = false
	s.support = Motor.Support.NONE
	s.plank = null
	s.dash_ready = true
	s.dash_ready_after_dash = false
	s.jumped_since_support = true
	s.jump_flank_tick = Motor.NEVER  # JUMP op de vangtick doet niets extra
	springer.caught_this_airphase = true
	# Telt voor de ladderregel als springplank-landing (C-13, C-09).
	springer.plank_since_ground = true
	springer.invulnerable_until = tick + int(c["catch_invulnerable_ticks"])
	springer.move_events = (springer.move_events & ~(Motor.EV_SPRINGPLANK | Motor.EV_LAND
		| Motor.EV_BOUNCE | Motor.EV_JUMP)) | Motor.EV_CATCH
	return true


## C-11b: staat de springer aan het eind van zijn stap op de plank van een
## drager in houding (ook op de landingstick), of zette hij er deze tick met
## een bounce vanaf, dan wordt hij gelanceerd. De lancering gaat vóór de bounce.
static func _try_launch(tick: int, springer: Node2D, carrier: Node2D) -> bool:
	var s: Motor.State = springer.motor
	var on_plank: bool = s.on_floor and s.support == Motor.Support.SHADOW_BODY and s.plank == carrier.plank
	var bounced_off: bool = springer.move_events & Motor.EV_BOUNCE != 0 \
		and springer.started_on_plank == carrier.plank
	if not (on_plank or bounced_off):
		return false
	if not carrier.carrier_in_stance(tick):
		return false
	var r: int = carrier.carrier_facing()
	carrier.consume_stance(tick)
	s.launch_pending = true
	s.launch_dir = r
	s.facing = r
	s.dash_ready = true
	s.dash_ready_after_dash = false
	springer.move_events = (springer.move_events & ~(Motor.EV_BOUNCE | Motor.EV_JUMP)) | Motor.EV_LAUNCH
	return true
