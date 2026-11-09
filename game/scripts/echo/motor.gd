extends RefCounted
## Gedeelde beweging voor speler (en echo in INPUT-modus): gdd §2.5a en E-07a.
##
## Eén functie, één codepad. Geen `Input`, geen tijd, geen random: alleen
## (lichaam, toestand, input-bits, tick) -> nieuwe toestand. Snelheden staan
## in px/tick in `State.velocity`; Godot krijgt ze ×60 voor `move_and_slide`.
## Waarden komen uit `res://data/echo_v04.json` (Tuning).

const InputBits = preload("res://scripts/input/input_bits.gd")
const Layers = preload("res://scripts/world/layers.gd")
const Tuning = preload("res://scripts/echo/tuning.gd")

## Waar het lichaam op steunt (E-01, E-08b).
enum Support { NONE, WORLD, LIGHT, SHADOW_BODY }
## Grove animatietoestand voor de opname (E-01); de Animator verfijnt dit.
enum Anim { IDLE, RUN, AIR, DASH }

## Bewegingsevents van één tick (bitmasker). Dit zijn géén echo-events (E-10):
## de echo voert ze niet uit; ze zijn er voor lichtmeter en meetlog.
const EV_JUMP := 1
const EV_BOUNCE := 2         ## E-07a (3)
const EV_SPRINGPLANK := 4    ## E-07a (2): landing van boven op een schaduwplank
const EV_LAND := 8           ## landing op wereld of licht-geometrie
const EV_DASH := 16

const TICKS_PER_SECOND := 60.0
const NEVER := -1_000_000


## De verborgen toestand van één lichaam: alles wat de beweging nodig heeft
## om exact te herhalen (ontwerp.md §4, verborgen toestand).
class State:
	var velocity := Vector2.ZERO          ## px/tick
	var facing := 1                       ## E-10a: +1 rechts, -1 links
	var on_floor := false                 ## aan het eind van de vorige tick
	var support: int = Support.NONE       ## idem
	var plank: CollisionObject2D = null   ## de plank waarop het lichaam staat
	var plank_position := Vector2.ZERO    ## positie van die plank aan het eind van de vorige tick
	var last_support_tick := NEVER        ## laatste tick die met steun eindigde
	var last_support_was_plank := false
	var jump_flank_tick := NEVER          ## laatste JUMP-flank die nog niet gebruikt is
	var jumped_since_support := false
	var dash_ready := true
	var dash_ready_after_dash := false    ## geland tijdens een dash: na de dash terug
	var dash_left := 0
	var dash_dir := 1
	var last_dash_tick := NEVER
	var prev_bits := 0
	var anim: int = Anim.IDLE


## Stap van één tick. Geeft het masker met bewegingsevents van deze tick.
static func step(body: CharacterBody2D, s: State, bits: int, tick: int) -> int:
	var m: Dictionary = Tuning.movement()
	var events := 0
	var rising := bits & ~s.prev_bits
	s.prev_bits = bits

	# E-10a: kijkrichting.
	var horizontal := bits & (InputBits.LEFT | InputBits.RIGHT)
	if horizontal == InputBits.LEFT:
		s.facing = -1
	elif horizontal == InputBits.RIGHT:
		s.facing = 1

	# E-07a (1): meebewegen met de plank van de vorige tick, tegen laag 1 + 4.
	var started_on_plank := s.support == Support.SHADOW_BODY and _plank_usable(s.plank)
	if started_on_plank:
		var delta := s.plank.global_position - s.plank_position
		if delta != Vector2.ZERO:
			var mask := body.collision_mask
			body.collision_mask = mask & ~Layers.PLANK
			body.move_and_collide(delta)
			body.collision_mask = mask
	var started_supported := s.on_floor and (s.support != Support.SHADOW_BODY or started_on_plank)

	if rising & InputBits.JUMP:
		s.jump_flank_tick = tick

	# Springen vanaf de grond of de plank (bounce), of in de coyote-tijd.
	var jump_now := false
	if s.jump_flank_tick == tick:
		if started_supported:
			jump_now = true
			events |= _start_jump(s, m, started_on_plank)
		elif not s.jumped_since_support:
			var coyote := int(m["bounce_coyote_ticks"]) if s.last_support_was_plank \
				else int(m["coyote_ticks"])
			# De eerste tick zonder steun is tick 0 na het verlaten.
			if tick - (s.last_support_tick + 1) <= coyote:
				jump_now = true
				events |= _start_jump(s, m, s.last_support_was_plank)

	# Dash: 1× per luchtfase, op de grond met een herhaaltijd (§2.5a).
	if rising & InputBits.DASH and s.dash_left == 0 and s.dash_ready:
		var on_ground := started_supported and not jump_now
		if not on_ground or tick - s.last_dash_tick >= int(m["dash_ground_cooldown_ticks"]):
			s.dash_left = int(m["dash_ticks"])
			s.dash_dir = s.facing
			s.dash_ready = false
			s.dash_ready_after_dash = false
			s.last_dash_tick = tick
			events |= EV_DASH

	# Snelheid en verplaatsing.
	var move := Vector2.ZERO
	var dashing := s.dash_left > 0
	if dashing:
		s.velocity = Vector2(float(m["dash_speed"]) * s.dash_dir, 0.0)
		move = s.velocity
	else:
		var direction := 0.0
		if bits & InputBits.RIGHT:
			direction += 1.0
		if bits & InputBits.LEFT:
			direction -= 1.0
		s.velocity.x = direction * float(m["walk_speed"])
		# Middelpuntsregel: de verplaatsing is het gemiddelde van de snelheid
		# vóór en na de zwaartekracht. Zo is de sprong een exacte parabool
		# (top 50 px, 40 ticks in de lucht bij -5,0 en 0,25; gdd §2.5a).
		var vy_new := minf(s.velocity.y + float(m["gravity"]), float(m["max_fall_speed"]))
		move = Vector2(s.velocity.x, (s.velocity.y + vy_new) * 0.5)
		s.velocity.y = vy_new
	body.velocity = move * TICKS_PER_SECOND
	body.move_and_slide()
	if dashing:
		s.dash_left -= 1

	if body.is_on_floor() and s.velocity.y > 0.0:
		s.velocity.y = 0.0
	if body.is_on_ceiling() and s.velocity.y < 0.0:
		s.velocity.y = 0.0

	# Steun aan het eind van de tick, landen (E-07a (2)) en de buffer.
	var support := _floor_support(body)
	s.on_floor = support != Support.NONE
	s.support = support
	s.plank = _floor_collider(body) if support == Support.SHADOW_BODY else null
	if s.plank:
		s.plank_position = s.plank.global_position
	if s.on_floor:
		var on_plank := support == Support.SHADOW_BODY
		var new_landing := not started_supported or on_plank != started_on_plank
		s.last_support_tick = tick
		s.last_support_was_plank = on_plank
		if not jump_now:
			s.jumped_since_support = false
			# Dash terug bij landen; landt hij tijdens een dash, dan na de dash.
			if s.dash_left > 0:
				s.dash_ready_after_dash = true
			else:
				s.dash_ready = true
			if new_landing:
				events |= EV_SPRINGPLANK if on_plank else (EV_LAND if not started_supported else 0)
				var buffer := int(m["bounce_buffer_ticks"]) if on_plank else int(m["jump_buffer_ticks"])
				if tick - s.jump_flank_tick <= buffer:
					events |= _start_jump(s, m, on_plank)
	if s.dash_left == 0 and s.dash_ready_after_dash:
		s.dash_ready = true
		s.dash_ready_after_dash = false

	s.anim = _anim(s)
	return events


static func _start_jump(s: State, m: Dictionary, bounce: bool) -> int:
	s.velocity.y = float(m["bounce_velocity"]) if bounce else float(m["jump_velocity"])
	s.jump_flank_tick = NEVER
	s.jumped_since_support = true
	s.dash_left = 0
	if bounce:
		# E-07a (3): een bounce geeft de dash terug.
		s.dash_ready = true
		s.dash_ready_after_dash = false
		return EV_JUMP | EV_BOUNCE
	return EV_JUMP


static func _plank_usable(plank: CollisionObject2D) -> bool:
	return plank != null and is_instance_valid(plank) and plank.collision_layer & Layers.PLANK != 0


static func _floor_collider(body: CharacterBody2D) -> CollisionObject2D:
	if not body.is_on_floor():
		return null
	for i in body.get_slide_collision_count():
		var collision := body.get_slide_collision(i)
		if collision.get_normal().dot(body.up_direction) > 0.7:
			return collision.get_collider() as CollisionObject2D
	return null


static func _floor_support(body: CharacterBody2D) -> int:
	var collider := _floor_collider(body)
	if collider == null:
		return Support.NONE
	if collider.collision_layer & Layers.PLANK:
		return Support.SHADOW_BODY
	if collider.collision_layer & Layers.LIGHT_GEOMETRY:
		return Support.LIGHT
	return Support.WORLD


static func _anim(s: State) -> int:
	if s.dash_left > 0:
		return Anim.DASH
	if not s.on_floor:
		return Anim.AIR
	return Anim.RUN if s.velocity.x != 0.0 else Anim.IDLE
