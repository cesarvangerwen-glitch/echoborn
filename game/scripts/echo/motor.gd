extends RefCounted
## Gedeelde bewegingslogica voor speler én echo.
##
## Eén functie, één codepad: de echo in input-modus roept exact dezelfde
## stap aan als de speler. Geen `Input`, geen tijd, geen random: alleen
## (lichaam, input-bits, vaste delta) -> nieuwe toestand.

const InputBits = preload("res://scripts/input/input_bits.gd")

const SPEED := 220.0
const GRAVITY := 1400.0
const JUMP_VELOCITY := -520.0


static func step(body: CharacterBody2D, bits: int, delta: float) -> void:
	var velocity := body.velocity
	var direction := 0.0
	if bits & InputBits.RIGHT:
		direction += 1.0
	if bits & InputBits.LEFT:
		direction -= 1.0
	velocity.x = direction * SPEED
	if body.is_on_floor():
		if bits & InputBits.JUMP:
			velocity.y = JUMP_VELOCITY
	else:
		velocity.y += GRAVITY * delta
	body.velocity = velocity
	body.move_and_slide()
