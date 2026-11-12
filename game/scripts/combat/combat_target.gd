extends "res://scripts/objects/sim_object.gd"
## Iets wat je kunt raken (E-10a, E-14): de basisvijand, het pantserdoel of
## de trefpop (gdd §4.3, §4.1).
##
## Het vlak (`shape`) is de hurtbox. Schade komt alleen via `Combat` in stap
## (4); de basisvijand beweegt en valt aan in stap (5). Een merk hangt aan
## het doel en volgt zijn positie (E-14a).
##
## LM-13 (T5b, #82; ontwerp.md §3a): in de gestreamde inhoud van een kamer
## heeft een vijand de blijvende stand `verslagen` (= niet `alive`), die de
## AreaLoader als vlag bewaart. Verslagen = onzichtbaar, op de tick zelf.
## Of hij terugkomt, hangt af van `terugkerend`
## (LM-13a) en van het gemaal van de wijk; dat beslist de loader, die dan
## `revive` aanroept. De trefpop (en dus het pomprad) heeft geen stand.

## Schade of een gebroken pantser, voor HUD, meetlog en tests.
signal damaged(tick: int, amount: int, source: String)
signal armor_broken(tick: int)
signal died(tick: int)
## Een aanvalsvlak van de vijand raakte P1 (kost P1 1 levenspunt, LM-05).
signal hit_player(tick: int, player: Node2D)
## Een treffer op een intact pantser: 0 SE, wel een merk; eigen geluid en vonk (VJ-07, T8b).
signal armor_tinked(tick: int)
## De basisvijand begint zijn aanloop (§4.3; voor tests en meetlog).
signal windup_started(tick: int)

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

## LM-13(a): komt deze vijand terug? STANDAARD volgt de soort: de
## basisvijand wel, het pantserdoel niet. Een nieuw type (Dwaallicht,
## minibaas) zet JA of NEE (Combat Designer).
enum Terugkeer { STANDAARD, JA, NEE }

## Geëxporteerd, zodat een doel in gestreamde inhoud zijn soort houdt.
@export var kind: Kind = Kind.ENEMY
@export var terugkerend: Terugkeer = Terugkeer.STANDAARD
## Startplek (LM-13c/d): gezet door `remember_start` (de AreaLoader, bij het
## laden), terug bij `revive`.
var start_position := Vector2.ZERO
var health := 30
var armor_intact := false
var alive := true
## Totale schade, voor tests en meetlog.
var damage_taken := 0
## Loopt de basisvijand (§4.3)? Uit = staat stil, valt niet aan.
@export var walks := true
var facing := 1

## Gezet door `setup_target` of `_ready` (doel uit de editor).
var _set_up := false
var _stunned_until := -1
var _windup_left := 0
var _attack_left := 0
var _attack_hit := false


## In code (flow-kamer, tests): soort, vlak, leven en beeld. Een doel dat je
## in de editor in een scène zet, hoeft dit niet: zie `_ready`.
func setup_target(p_kind: Kind) -> void:
	var c: Dictionary = Tuning.combat()
	var size: Array = c["enemy_size"]
	setup(Layers.LIGHT | Layers.SHADOW, Vector2(float(size[0]), float(size[1])))
	kind = p_kind
	health = int(c["enemy_health"]) if kind != Kind.DUMMY else 1_000_000
	armor_intact = kind == Kind.ARMORED
	walks = kind == Kind.ENEMY
	_set_up = true
	_ensure_visual()


## LM-13, een vijand in de editor (ontwerp.md §3a): een scène bewaart `kind`,
## `walks`, `terugkerend`, `owner_layers` en het vlak, niet het leven en niet
## het beeld (dat is geen kind met een owner). Kwam het doel niet uit
## `setup_target`, dan krijgt het hier: het standaardvlak als `shape` leeg
## is, vol leven, het pantser van zijn soort, en het placeholderbeeld.
## Alleen de basisvijand loopt (§4.3), wat `walks` ook zegt.
func _ready() -> void:
	if _set_up:
		return
	_set_up = true
	if shape == null:
		var size: Array = Tuning.combat()["enemy_size"]
		setup(owner_layers, Vector2(float(size[0]), float(size[1])))
	_reset_fight()
	walks = walks and kind == Kind.ENEMY
	_ensure_visual()


## Het placeholderbeeld (`Beeld`, een `Polygon2D` zo groot als het vlak, in
## de kleur van de soort): bestaat het al, dan alleen bijwerken.
func _ensure_visual() -> void:
	var size := shape.get_rect().size if shape != null else Vector2.ZERO
	var visual := BodyBuilder.make_visual(size, COLORS[kind])
	var old := get_node_or_null(^"Beeld") as Polygon2D
	if old != null:
		old.polygon = visual.polygon
		old.color = visual.color
		visual.free()
		return
	visual.name = "Beeld"
	add_child(visual)


## LM-13(a): terugkerend (basisvijand zonder pantser) of niet.
func is_returning() -> bool:
	match terugkerend:
		Terugkeer.JA:
			return true
		Terugkeer.NEE:
			return false
	return kind == Kind.ENEMY


## Bij het laden van de inhoud (LM-13d): de plek uit de scène is de
## startplek, met vol leven en (pantserdoel) een heel pantser.
func remember_start() -> void:
	start_position = position
	_reset_fight()


## LM-13(c): de vijand staat weer op zijn startplek, met vol leven.
func revive() -> void:
	alive = true
	visible = true
	position = start_position
	facing = 1
	_reset_fight()


## Vol leven voor deze soort.
func health_full() -> int:
	return int(Tuning.combat()["enemy_health"]) if kind != Kind.DUMMY else 1_000_000


func _reset_fight() -> void:
	health = health_full()
	armor_intact = kind == Kind.ARMORED
	_stunned_until = -1
	_windup_left = 0
	_attack_left = 0
	_attack_hit = false


## LM-13(b): een vijand of pantserdoel bewaart `verslagen`; de trefpop niet.
func has_persistent_state() -> bool:
	return kind != Kind.DUMMY


## `verslagen`: sinds de tick waarop het leven op 0 viel (`apply_damage`).
func get_persistent_state() -> bool:
	return not alive


## Verslagen uit de save: weg (niet zichtbaar, geen leven). Of hij toch
## terugkomt, beslist de AreaLoader (`revive`). Niet verslagen: niets,
## `remember_start` gaf al vol leven.
func set_persistent_state(on: bool) -> void:
	if on:
		alive = false
		health = 0
		visible = false


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
		# LM-13: verslagen = weg, ook in een kamer die geladen blijft. Hij
		# blijft bij de Sim aangemeld (niet `alive`: beweegt niet, wordt niet
		# geraakt) tot zijn kamer ontlaadt, of `revive` hem terugzet.
		alive = false
		visible = false
		died.emit(tick)
	return done


## VJ-07: een treffer op het intacte pantser (Combat, E-14g).
func tink(tick: int) -> void:
	armor_tinked.emit(tick)


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
## niet en blijft op zijn hoogte. Een aanloop begint alleen als P1 binnen
## bereik is én zijn voeten binnen de hoogtegrens van de vloer van de vijand
## zijn (gdd v0.8.2 §4.3, G-9; zoals VJ-08); anders loopt hij door naar P1.
## Een aanloop die loopt, loopt door.
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
	if absf(dx) <= float(c["enemy_attack_range_px"]) + shape.get_rect().size.x \
			and _p1_in_windup_height(p1, c):
		facing = 1 if dx >= 0.0 else -1
		_windup_left = int(c["enemy_windup_ticks"])
		windup_started.emit(tick)
		return
	facing = 1 if dx > 0.0 else -1
	position.x += float(c["enemy_speed"]) * facing


## G-9 (gdd v0.8.2 §4.3, VJ-08): de voeten van P1 tussen `enemy_windup_height_min` en
## `enemy_windup_height_max` px boven de vloer van de vijand (−20 … +20; negatief = lager).
func _p1_in_windup_height(p1: Node2D, c: Dictionary) -> bool:
	var own_floor := global_position.y + shape.get_rect().size.y * 0.5
	var feet := p1.global_position.y + Tuning.body_size().y * 0.5
	var height := own_floor - feet
	return height >= float(c["enemy_windup_height_min"]) - 0.0001 \
		and height <= float(c["enemy_windup_height_max"]) + 0.0001


func _attack_box(c: Dictionary) -> Rect2:
	var size: Array = c["attack_box"]
	var box := Vector2(float(size[0]), float(size[1]))
	var half := shape.get_rect().size.x * 0.5
	var center := global_position + Vector2(facing * (half + box.x * 0.5), 0.0)
	return Rect2(center - box * 0.5, box)


func _body_rect(body: Node2D) -> Rect2:
	var size := Tuning.body_size()
	return Rect2(body.global_position - size * 0.5, size)
