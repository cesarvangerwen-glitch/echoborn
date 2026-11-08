extends CharacterBody2D
## De echo: speelt een EchoClip af, één frame per physics-tick.
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
var finished := false
## Positie na elke afgespeelde tick; tests vergelijken dit met clip.post_pos.
var trace := PackedVector2Array()

var _frame := 0


func setup(color: Color) -> void:
	collision_layer = Layers.SHADOW
	collision_mask = Layers.WORLD
	BodyBuilder.add_box(self, color)


func start(p_clip: EchoClip, p_mode: Mode) -> void:
	clip = p_clip
	mode = p_mode
	_frame = 0
	finished = clip.is_empty()
	trace = PackedVector2Array()
	if not finished:
		position = clip.start_position()
		velocity = clip.start_velocity()
	visible = not finished


func sim_step(_tick: int, delta: float) -> void:
	if finished:
		return
	match mode:
		Mode.STATE:
			position = clip.post_pos[_frame]
			velocity = clip.post_vel[_frame]
		Mode.INPUT:
			Motor.step(self, clip.inputs[_frame], delta)
	trace.append(position)
	_frame += 1
	if _frame >= clip.size():
		finished = true
		playback_finished.emit()


## Grootste afstand tussen echo en origineel over de afgespeelde frames.
func max_deviation() -> float:
	var worst := 0.0
	for i in trace.size():
		worst = maxf(worst, trace[i].distance_to(clip.post_pos[i]))
	return worst
