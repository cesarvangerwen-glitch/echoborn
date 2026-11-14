extends RefCounted
## Aanval (E-10a), schaduwmerk (E-14) en de merk-combo in co-op (C-12).
##
## Hoort bij de Sim. Treffers komen in stap (4) binnen via `attack`; de echo
## laat een merk ontploffen via `detonate` (merksprong, E-02m). Kettingen
## lopen één schakel per tick (`after_events`), merken doven in `begin_tick`.
## Alles in ticks, zonder physics-ruimte: een directe vormtest (A2).

## Een merk is gezet (meetlog MERK_GEZET).
signal mark_set(tick: int, mark: Mark)
## Een merk ontploft als schakel `link` (meetlog ONTPLOFFING).
signal mark_exploded(tick: int, mark: Mark, link: int)
## Een merk is zonder effect gedoofd (E-14b).
signal mark_faded(tick: int, mark: Mark)
## Een aanvalsvlak raakte een doel (E-10a), met de toegepaste schade.
signal hit(tick: int, attacker: String, target: Node2D, damage: int)

const Tuning = preload("res://scripts/echo/tuning.gd")
const Layers = preload("res://scripts/world/layers.gd")
const CombatTarget = preload("res://scripts/combat/combat_target.gd")


## Eén schaduwmerk (E-14). Hangt aan zijn doel en beweegt mee.
class Mark:
	var id: int
	var target: CombatTarget
	## "p1" of "p2": wie het merk zette (E-14a, C-12).
	var setter: String
	var born: int
	## Middelpunt van de zetter op de tick van zetten (wereld). GMB-14 c: in co-op knalt het merk
	## alleen door een treffer vanaf de andere helft dan deze.
	var set_at := Vector2.ZERO
	## Eerste tick waarop het merk er niet meer is: solo born + D + 30 (E-14b),
	## in co-op born + 150, los van D (C-12e). Ligt vast op de tick van zetten.
	var expires: int
	var alive := true

	func center() -> Vector2:
		return target.global_position

	## Telt het merk af (laatste 60 ticks, beeld en carillon)?
	func counting_down(tick: int, countdown: int) -> bool:
		return alive and tick >= expires - countdown


## D, de staartlengte van de sessie (E-14b, C-12e). De echo zet hem.
var tail_ticks := int(Tuning.echo()["tail_ticks"])
## Doet P2 mee (co-op)? De Sim zet dit bij elke speler die erbij komt of
## weggaat. Bepaalt de levensduur van een nieuw merk (C-12e).
var coop := false
## Staat de echo aan (solo, er is een staart-echo, ook als die nu Leeg is)?
## De Sim zet dit vóór stap (4), na de resets van P1 (E-07b). Voor de
## schaduwklep van een luik (V-01d, #227).
var echo_on := false
## C-14e: loopt er een finisher? Dan zet een treffer geen merk en vallen vijanden niet aan. De boss
## zet dit (`Boss`).
var finisher_running := false
var targets: Array[CombatTarget] = []
var marks: Array[Mark] = []

var _next_id := 1
## Kettingschakels die nog moeten ontploffen: tick -> [[mark, link], ...].
var _pending := {}
## Pantser dat op deze tick brak: een tweede schakel op dezelfde tick doet
## er nog niets (E-14g, aanname: "eerste ontploffing" per tick).
var _armor_broke_tick := {}


func add_target(target: CombatTarget) -> void:
	targets.append(target)


## Het merk op `target`, of null (max. 1 per doel, E-14a).
func mark_on(target: CombatTarget) -> Mark:
	for mark in marks:
		if mark.alive and mark.target == target:
			return mark
	return null


## Begin van de tick: gedoofde merken en merken op dode doelen weg (E-14b).
func begin_tick(tick: int) -> void:
	for mark in marks:
		if mark.alive and (tick >= mark.expires or not mark.target.alive):
			mark.alive = false
			mark_faded.emit(tick, mark)
	marks = marks.filter(func(m: Mark) -> bool: return m.alive)


## Stap (4): een AANVAL-event van een lichaam (E-10a). `attacker` is "p1",
## "p2" of "echo"; `layer` de laag van het lichaam (E-06). Elk doel dat het
## aanvalsvlak overlapt, wordt geraakt. `down`: een neerslag (V-01a), met het
## vlak onder het lichaam. Geeft het aantal geraakte doelen (V-01b: > 0 = stuit).
func attack(tick: int, attacker: String, layer: int, center: Vector2, facing: int,
		down := false) -> int:
	var box := neerslag_box(center) if down else attack_box(center, facing)
	var c: Dictionary = Tuning.combat()
	var struck := 0
	for target in targets:
		if not target.is_hit_by(box, layer):
			continue
		struck += 1
		var mark := mark_on(target)
		var damage := 0
		if attacker == "echo":
			# E-14e: gewone echo-treffer; de echo zet nooit een merk (E-14a).
			damage = int(c["hit_echo"])
		elif mark != null and mark.setter != attacker and target.allows_detonate(tick, center, mark):
			# C-12b: het andere lichaam laat het merk knallen, in plaats van 10 SE.
			_explode(tick, mark, 1)
			hit.emit(tick, attacker, target, 0)
			continue
		else:
			# Mag het merk niet knallen (GMB-14 c: vanaf dezelfde helft), dan een gewone treffer en
			# blijft het merk staan.
			damage = int(c["hit_p1"]) if attacker == "p1" else int(c["hit_p2"])
			if mark == null and target.is_markable() and not finisher_running \
					and target.allows_mark(tick, center):
				_set_mark(tick, target, attacker, center)
		if target.armor_intact:
			damage = 0  # E-14g: een intact pantser krijgt niets van treffers
			target.tink(tick)  # VJ-07: eigen geluid en vonk
		var done := target.apply_damage(tick, damage, attacker)
		target.stun(tick)
		hit.emit(tick, attacker, target, done)
	return struck


## Het aanvalsvlak: 20 × 16 px direct vóór het lichaam (E-10a).
func attack_box(center: Vector2, facing: int) -> Rect2:
	var c: Dictionary = Tuning.combat()
	var size: Array = c["attack_box"]
	var box := Vector2(float(size[0]), float(size[1]))
	var half := Tuning.body_size().x * 0.5
	var box_center := center + Vector2(facing * (half + box.x * 0.5), 0.0)
	return Rect2(box_center - box * 0.5, box)


## V-01a: het neerslagvlak, 16 × 20 px direct onder het lichaam.
func neerslag_box(center: Vector2) -> Rect2:
	var size: Array = Tuning.combat()["neerslag_box"]
	var box := Vector2(float(size[0]), float(size[1]))
	var bottom := center.y + Tuning.body_size().y * 0.5
	return Rect2(Vector2(center.x - box.x * 0.5, bottom), box)


## Doven zonder effect (E-14b), bv. de merken op een boss bij een fasewissel (GMB-12).
func fade_marks_on(on_targets: Array, tick: int) -> void:
	for mark in marks:
		if mark.alive and on_targets.has(mark.target):
			mark.alive = false
			mark_faded.emit(tick, mark)
	marks = marks.filter(func(m: Mark) -> bool: return m.alive)


## E-02m: het doelmerk voor een AANVAL van de echo op `from` (frame p): het
## dichtstbijzijnde merk binnen R met vrije zichtlijn (laag 1 en 5); bij
## gelijke afstand het oudste.
func find_jump_target(from: Vector2, space: PhysicsDirectSpaceState2D) -> Mark:
	var radius := float(Tuning.combat()["merksprong_radius_px"])
	var best: Mark = null
	var best_distance := INF
	for mark in marks:
		if not mark.alive:
			continue
		var distance := from.distance_to(mark.center())
		if distance > radius or distance >= best_distance:
			continue
		var ray := PhysicsRayQueryParameters2D.create(from, mark.center(),
			Layers.WORLD | Layers.SHADOW_GEOMETRY)
		if not space.intersect_ray(ray).is_empty():
			continue
		best = mark
		best_distance = distance
	return best


## De echo laat `mark` ontploffen (E-02m, E-14c), als het er nog is.
func detonate(tick: int, mark: Mark) -> void:
	if mark != null and mark.alive:
		_explode(tick, mark, 1)


## Na de events van stap (4): de kettingschakels van deze tick (E-14d).
func after_events(tick: int) -> void:
	if not _pending.has(tick):
		return
	var due: Array = _pending[tick]
	_pending.erase(tick)
	due.sort_custom(func(a: Array, b: Array) -> bool: return (a[0] as Mark).id < (b[0] as Mark).id)
	for entry: Array in due:
		var mark: Mark = entry[0]
		if mark.alive:
			_explode(tick, mark, entry[1])


## Levensduur van een merk dat nu gezet wordt: solo D + 30 (E-14b), in
## co-op vast 150 ticks (C-12e). Een merk houdt zijn levensduur, ook als P2
## daarna meedoet of stopt (C-05: "leeft zijn 150 ticks uit").
func life_ticks() -> int:
	var c: Dictionary = Tuning.combat()
	if coop:
		return int(c["mark_coop_life_ticks"])
	return tail_ticks + int(c["mark_extra_life_ticks"])


func _set_mark(tick: int, target: CombatTarget, setter: String, at := Vector2.ZERO) -> void:
	var mark := Mark.new()
	mark.id = _next_id
	_next_id += 1
	mark.target = target
	mark.setter = setter
	mark.set_at = at
	mark.born = tick
	mark.expires = tick + life_ticks()
	marks.append(mark)
	mark_set.emit(tick, mark)


## E-14d: schade binnen E, het merk weg, buren binnen K op de volgende tick.
func _explode(tick: int, mark: Mark, link: int) -> void:
	var c: Dictionary = Tuning.combat()
	mark.alive = false
	var at := mark.center()
	var step := float(c["chain_step"])
	var damage := int(floor(float(c["explosion_damage"]) * (1.0 + step * (mini(link, int(c["chain_max_link"])) - 1))))
	mark_exploded.emit(tick, mark, link)
	for target in targets:
		if not target.alive or not target.is_markable() \
				or target.global_position.distance_to(at) > float(c["explosion_radius_px"]):
			continue
		if target.armor_intact:
			target.break_armor(tick)
			_armor_broke_tick[target.get_instance_id()] = tick
			continue
		if _armor_broke_tick.get(target.get_instance_id(), -1) == tick:
			continue
		target.apply_damage(tick, damage, "ontploffing")
	var chain := float(c["chain_radius_px"])
	for other in marks:
		if other.alive and other != mark and not _is_pending(other) \
				and other.center().distance_to(at) <= chain:
			if not _pending.has(tick + 1):
				_pending[tick + 1] = []
			_pending[tick + 1].append([other, link + 1])


func _is_pending(mark: Mark) -> bool:
	for due: Array in _pending.values():
		for entry: Array in due:
			if entry[0] == mark:
				return true
	return false
