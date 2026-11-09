extends "res://scripts/objects/sim_object.gd"
## Iets wat je kunt raken (E-10a, E-14): de basisvijand, het pantserdoel of
## de trefpop (gdd §4.3, §4.1).
##
## Het vlak (`shape`) is de hurtbox. Schade komt alleen via `Combat` in stap
## (4); de basisvijand beweegt en valt aan in stap (5). Een merk hangt aan
## het doel en volgt zijn positie (E-14a).

## Schade of een gebroken pantser, voor HUD, meetlog en tests.
signal damaged(tick: int, amount: int, source: String)
signal armor_broken(tick: int)
signal died(tick: int)
## Een aanvalsvlak van de vijand raakte P1 (kost P1 1 levenspunt, LM-05).
signal hit_player(tick: int, player: Node2D)

const Tuning = preload("res://scripts/echo/tuning.gd")
const BodyBuilder = preload("res://scripts/echo/body_builder.gd")

## Placeholder-kleuren (grijze flow-kamer, §4.1).
const COLORS := {Kind.ENEMY: Color(0.75, 0.3, 0.3), Kind.ARMORED: Color(0.55, 0.55, 0.6),
	Kind.DUMMY: Color(0.6, 0.5, 0.3)}

enum Kind {
	ENEMY,   ## basisvijand: Merkbaar, loopt naar P1, valt aan
	ARMORED, ## pantserdoel: Merkbaar, staat stil, pantser (E-14g)
	DUMMY,   ## trefpop: niet Merkbaar, alleen voor tests
}

var kind: Kind = Kind.ENEMY
var health := 30
var armor_intact := false
var alive := true
## Totale schade, voor tests en meetlog.
var damage_taken := 0
## Loopt de basisvijand (§4.3)? Uit = staat stil, valt niet aan.
var walks := true
var facing := 1

var _stunned_until := -1
var _windup_left := 0
var _attack_left := 0
var _attack_hit := false


func setup_target(p_kind: Kind) -> void:
	var c: Dictionary = Tuning.combat()
	var size: Array = c["enemy_size"]
	setup(Layers.LIGHT | Layers.SHADOW, Vector2(float(size[0]), float(size[1])))
	kind = p_kind
	health = int(c["enemy_health"]) if kind != Kind.DUMMY else 1_000_000
	armor_intact = kind == Kind.ARMORED
	walks = kind == Kind.ENEMY
	add_child(BodyBuilder.make_visual(shape.get_rect().size, COLORS[kind]))


## E-14a: alleen vijanden en pantserdoelen dragen een merk.
func is_markable() -> bool:
	return alive and kind != Kind.DUMMY


## Wordt dit doel geraakt door een aanvalsvlak `box` (in wereldcoördinaten)
## van een lichaam op laag `attacker_layer` (E-06)?
func is_hit_by(box: Rect2, attacker_layer: int) -> bool:
	if not alive or attacker_layer & owner_layers == 0:
		return false
	var rect := RectangleShape2D.new()
	rect.size = box.size
	return shape.collide(global_transform, rect, Transform2D(0.0, box.get_center()))


## Schade van `amount` SE. Geeft de echt toegepaste schade terug.
func apply_damage(tick: int, amount: int, source: String) -> int:
	if not alive or amount <= 0:
		return 0
	var done := mini(amount, health)
	health -= done
	damage_taken += done
	damaged.emit(tick, done, source)
	if health <= 0:
		alive = false
		died.emit(tick)
	return done


func break_armor(tick: int) -> void:
	armor_intact = false
	armor_broken.emit(tick)


## §4.3: na elke treffer 30 ticks stil.
func stun(tick: int) -> void:
	if kind == Kind.ENEMY:
		_stunned_until = tick + int(Tuning.combat()["enemy_stun_ticks"])
		_windup_left = 0
		_attack_left = 0


## Stap (5): de basisvijand loopt naar P1 en valt aan (§4.3). Hij springt
## niet en blijft op zijn hoogte.
func sim_update(tick: int, bodies: Array[Node2D]) -> void:
	if not alive or not walks:
		return
	var p1: Node2D = null
	for body in bodies:
		if (body as CollisionObject2D).collision_layer & Layers.LIGHT:
			p1 = body
	if p1 == null or tick < _stunned_until:
		return
	var c: Dictionary = Tuning.combat()
	var dx := p1.global_position.x - global_position.x
	if _attack_left > 0:
		_attack_left -= 1
		if not _attack_hit and _attack_box(c).intersects(_body_rect(p1)):
			_attack_hit = true
			hit_player.emit(tick, p1)
		return
	if _windup_left > 0:
		_windup_left -= 1
		if _windup_left == 0:
			_attack_left = int(c["enemy_attack_ticks"])
			_attack_hit = false
		return
	if absf(dx) <= float(c["enemy_attack_range_px"]) + shape.get_rect().size.x:
		facing = 1 if dx >= 0.0 else -1
		_windup_left = int(c["enemy_windup_ticks"])
		return
	facing = 1 if dx > 0.0 else -1
	position.x += float(c["enemy_speed"]) * facing


func _attack_box(c: Dictionary) -> Rect2:
	var size: Array = c["attack_box"]
	var box := Vector2(float(size[0]), float(size[1]))
	var half := shape.get_rect().size.x * 0.5
	var center := global_position + Vector2(facing * (half + box.x * 0.5), 0.0)
	return Rect2(center - box * 0.5, box)


func _body_rect(body: Node2D) -> Rect2:
	var size := Tuning.body_size()
	return Rect2(body.global_position - size * 0.5, size)
