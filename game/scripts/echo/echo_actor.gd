extends "res://scripts/echo/echo_body.gd"
## Clip-echo: speelt een vaste EchoClip af, één frame per physics-tick.
##
## Dit is de echo van de spike (knop, 10 s). De echo van v0.4 is de
## staart-echo (`tail_echo.gd`, E-02). De clip-echo blijft voor tests van
## het event- en objectsysteem en later voor de co-op-finisher (8A, T3b).
##
## Twee modi, zodat de spike beide aanpakken naast elkaar bewijst:
## - STATE: zet per tick de opgenomen toestand (positie/snelheid). Exact
##   per definitie, ongeacht wat er in de wereld veranderd is.
## - INPUT: voert de opgenomen input opnieuw door Motor.step. Exact zolang
##   wereld en begintoestand gelijk zijn; wijkt af zodra de wereld anders is.

signal playback_finished

enum Mode { STATE, INPUT }

const Motor = preload("res://scripts/echo/motor.gd")
const EchoClip = preload("res://scripts/echo/echo_clip.gd")
const BodyBuilder = preload("res://scripts/echo/body_builder.gd")
const Layers = preload("res://scripts/world/layers.gd")

var mode: Mode = Mode.STATE
var clip: EchoClip
## Positie na elke afgespeelde tick; tests vergelijken dit met clip.post_pos.
var trace := PackedVector2Array()

var _frame := 0
var _motor := Motor.State.new()


func setup(color: Color) -> void:
	collision_layer = 0
	collision_mask = Layers.WORLD
	BodyBuilder.add_box(self, color)
	_sync_presence()


## Een echo telt alleen als lichaam zolang hij afspeelt: dan staat hij op
## laag 3 en zien objecten hem. Klaar of nog niet gestart = geen lichaam,
## onzichtbaar en voor geen enkele query vindbaar (C-01, E-07).
func is_active() -> bool:
	return clip != null and not finished


## Staat de echo nu als lichaam in de wereld (laag 3, zichtbaar)? Na zijn
## laatste frame blijft dat zo tot het einde van die tick (`sim_end_tick`).
func is_present() -> bool:
	return collision_layer != 0


## Haalt de echo uit de wereld (bv. bij `Sim.remove_echo`), in dezelfde tick.
func stop() -> void:
	finished = true
	tick_events = 0
	_sync_presence()


func _sync_presence() -> void:
	var active := is_active()
	visible = active
	collision_layer = Layers.SHADOW if active else 0


func start(p_clip: EchoClip, p_mode: Mode) -> void:
	clip = p_clip
	mode = p_mode
	_frame = 0
	finished = clip.is_empty()
	trace = PackedVector2Array()
	_motor = Motor.State.new()
	if not finished:
		position = clip.start_position()
		_motor.velocity = clip.start_velocity()
	tick_events = 0
	_sync_presence()


func sim_step(tick: int, _delta: float) -> void:
	tick_events = 0
	if finished:
		return
	match mode:
		Mode.STATE:
			position = clip.post_pos[_frame]
			velocity = clip.post_vel[_frame]
		Mode.INPUT:
			Motor.step(self, _motor, clip.inputs[_frame], tick)
	tick_events = clip.events[_frame]
	trace.append(position)
	_frame += 1
	if _frame >= clip.size():
		# Het laatste frame telt nog mee: lichaam en events blijven tot het
		# einde van deze tick; `sim_end_tick` haalt hem daarna weg.
		finished = true
		playback_finished.emit()


## Door de Sim aangeroepen na stap (3). Een clip-echo reageert niet op
## resets van zijn bron.
func sim_after_source(_tick: int) -> void:
	pass


## Door de Sim aangeroepen na stap (5): een echo die deze tick zijn laatste
## frame speelde, verdwijnt pas nu, zodat objecten dat frame nog zagen.
func sim_end_tick() -> void:
	if finished and is_present():
		_sync_presence()


## Grootste afstand tussen echo en origineel over de afgespeelde frames.
func max_deviation() -> float:
	var worst := 0.0
	for i in trace.size():
		worst = maxf(worst, trace[i].distance_to(clip.post_pos[i]))
	return worst
