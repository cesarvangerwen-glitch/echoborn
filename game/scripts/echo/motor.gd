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
const EV_LAUNCH := 32        ## C-11b: gelanceerd (op de lanceertick, bij de springer)
const EV_CATCH := 64         ## C-13: gevangen (op de vangtick, bij de springer)

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
	## C-11b: lancering gaat in op de volgende stap, met deze richting.
	var launch_pending := false
	var launch_dir := 1
	## C-11b/c: ticks lanceerstaat die nog over zijn (0 = geen).
	var launch_left := 0


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

	# C-11b: de lancering van de vorige tick gaat nu in (`v.y`, 30 ticks `v.x`).
	var launch_start := false
	if s.launch_pending:
		var c: Dictionary = Tuning.coop()
		s.launch_pending = false
		s.launch_left = int(c["launch_ticks"])
		s.velocity.y = float(c["launch_velocity_y"])
		s.facing = s.launch_dir
		launch_start = true
	elif s.launch_left > 0:
		# C-11b: LEFT en RIGHT veranderen tijdens de lanceerstaat niets.
		s.facing = s.launch_dir

	# E-07a (1): meebewegen met de plank van de vorige tick, tegen laag 1 + 4.
	var started_on_plank := s.support == Support.SHADOW_BODY and _plank_usable(s.plank)
	if started_on_plank:
		var delta := s.plank.global_position - s.plank_position
		if delta != Vector2.ZERO:
			var mask := body.collision_mask
			body.collision_mask = mask & ~Layers.ANY_PLANK
			body.move_and_collide(delta)
			body.collision_mask = mask
	var started_supported := s.on_floor and (s.support != Support.SHADOW_BODY or started_on_plank)

	if rising & InputBits.JUMP:
		s.jump_flank_tick = tick
	if launch_start:
		# Afzetten gebeurt door de lancering, niet door een sprong.
		started_supported = false
		s.jumped_since_support = true

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
			s.launch_left = 0  # C-11c: de dash neemt het over
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
		if s.launch_left > 0:
			s.velocity.x = float(Tuning.coop()["launch_speed_x"]) * s.launch_dir
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
	if s.launch_left > 0:
		s.launch_left -= 1
		# C-11c: tegen een muur stopt de lanceerstaat, `v.x = 0`.
		if body.is_on_wall():
			s.velocity.x = 0.0
			s.launch_left = 0

	# Steun aan het eind van de tick, landen (E-07a (2)) en de buffer.
	var floor := _floor_collider(body, s)
	var support := _support_of(floor)
	s.on_floor = support != Support.NONE
	s.support = support
	s.plank = floor if support == Support.SHADOW_BODY else null
	if s.plank:
		s.plank_position = s.plank.global_position
	if s.on_floor and not launch_start:
		s.launch_left = 0  # C-11c: landen stopt de lanceerstaat
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
	return plank != null and is_instance_valid(plank) and plank.collision_layer & Layers.ANY_PLANK != 0


## De vloer onder het lichaam na de stap. Staat het op twee vloeren tegelijk
## (bv. een richel en de plank ernaast), dan blijft de vloer van de vorige
## tick gelden zolang hij er nog onder ligt: zo wisselt de steun maar één
## keer en telt een springplank-landing maar één keer (E-07a (2)).
static func _floor_collider(body: CharacterBody2D, s: State) -> CollisionObject2D:
	if not body.is_on_floor():
		return null
	var first: CollisionObject2D = null
	for i in body.get_slide_collision_count():
		var collision := body.get_slide_collision(i)
		if collision.get_normal().dot(body.up_direction) <= 0.7:
			continue
		var collider := collision.get_collider() as CollisionObject2D
		if collider == null:
			continue
		if first == null:
			first = collider
		var same_kind := (_support_of(collider) == Support.SHADOW_BODY) == (s.support == Support.SHADOW_BODY)
		if s.on_floor and same_kind:
			return collider
	if first == null and body.is_on_wall():
		# Tegen een muur (#231): `move_and_slide` botst eerst op de muur en zet
		# het lichaam daarna met de floor snap terug op de vloer. Dan is
		# `is_on_floor()` waar, maar staat de vloer niet bij de botsingen van
		# de stap. Zonder deze vraag (alleen testen, niets verschuift) verloor
		# P1 de vloer zolang hij tegen de muur liep en kon hij na de
		# coyote-tijd niet meer springen. Alleen tegen een muur: in de lucht
		# boven een plank die net uitging (E-02m) blijft het zoals het was.
		var below := body.move_and_collide(Vector2(0.0, body.floor_snap_length), true, body.safe_margin, true)
		if below != null and below.get_normal().dot(body.up_direction) > 0.7:
			first = below.get_collider() as CollisionObject2D
	return first


static func _support_of(collider: CollisionObject2D) -> int:
	if collider == null:
		return Support.NONE
	# Schaduwplank (E-07) of lichtplank (C-09): steun op een lichaam.
	if collider.collision_layer & Layers.ANY_PLANK:
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
