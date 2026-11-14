extends "res://scripts/combat/combat_target.gd"
## Eén hurtbox van een boss (C-14 a, GMB-02): het schot en de kern, de merkplek, later het rad.
##
## Voor `Combat` een gewoon doel: treffers, merken en ontploffingen lopen langs dezelfde weg als bij
## een vijand (E-10a, E-14). De schade zelf houdt de boss bij (`Boss.receive`), met zijn fasen,
## drempels en klemmen; het deel heeft geen eigen leven. Of het deel raakbaar en `Merkbaar` is,
## zet de boss per fase (`hittable`, `markable`). Een merk hangt op het middelpunt van het deel.

## De boss waar dit deel bij hoort (`Boss`).
var boss: Node2D = null
## Raakt een aanvalsvlak of ontploffing dit deel nu? (GMB-02: in fase 2 heeft de kern geen hurtbox.)
var hittable := true
## Draagt het nu een merk (E-14a, GM-07: in fase 2 niet `Merkbaar`)?
var markable := true
## Laatste tick van een tink (VJ-07), voor beeld en tests.
var tink_tick := -1_000_000


## Een deel van `p_boss` met een hurtbox van `size`, op `local_at` ten opzichte van de boss.
func setup_part(p_boss: Node2D, part_name: String, size: Vector2, local_at: Vector2) -> void:
	setup_target(Kind.ENEMY)
	setup(Layers.LIGHT | Layers.SHADOW, size)
	boss = p_boss
	name = part_name
	walks = false
	position = local_at
	start_position = local_at
	_ensure_visual()
	var visual := get_node_or_null(^"Beeld") as CanvasItem
	if visual != null:
		visual.visible = false  # het beeld tekent de boss zelf (placeholder, B-11)


func is_markable() -> bool:
	return alive and hittable and markable


## GMB-14 c: de boss beslist (de doelhelft in co-op, fase 1).
func allows_mark(tick: int, from: Vector2) -> bool:
	return boss == null or not boss.has_method(&"part_allows_mark") or boss.part_allows_mark(self, tick, from)


func allows_detonate(tick: int, from: Vector2, mark: RefCounted) -> bool:
	return boss == null or not boss.has_method(&"part_allows_detonate") \
		or boss.part_allows_detonate(self, tick, from, mark)


func is_hit_by(box: Rect2, attacker_layer: int) -> bool:
	return hittable and super.is_hit_by(box, attacker_layer)


## Een deel heeft geen eigen leven: de boss beslist (fase, drempel, Wankel, finisher).
func apply_damage(tick: int, amount: int, source: String) -> int:
	if not alive or not hittable or boss == null:
		return 0
	var done: int = boss.receive(tick, amount, source, self)
	if done > 0:
		damage_taken += done
		damaged.emit(tick, done, source)
	return done


func break_armor(tick: int) -> void:
	if not armor_intact:
		return
	super.break_armor(tick)
	if boss != null:
		boss.on_armor_broken(tick, self)


func tink(tick: int) -> void:
	super.tink(tick)
	tink_tick = tick


## Een boss staat nooit stil van een treffer (VJ-04 geldt voor vijanden).
func stun(_tick: int) -> void:
	pass


## De boss werkt zijn delen bij in zijn eigen stap (5).
func sim_update(_tick: int, _bodies: Array[Node2D]) -> void:
	pass


## Een boss bewaart geen `verslagen`-vlag via de AreaLoader (de arena zet de stand, T8a).
func has_persistent_state() -> bool:
	return false
