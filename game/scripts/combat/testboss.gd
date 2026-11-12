extends "res://scripts/combat/boss.gd"
## De testboss van de C-14- en C-16-test (gdd §4.6, O-14; T8b B-5): 100 SE, `Merkbaar`, drempel
## 20 SE, één hurtbox op de vloer en één stamp-aanval per maat. Alle waarden uit `slice.csv`
## (groep `testboss`). Geen boss in een kamer: alleen voor de regeltests van `Boss`.

const COLOR := Color(0.45, 0.4, 0.55)
const TELL_COLOR := Color(1.0, 0.85, 0.55)

var core: BossPart

var _next_beat := 0


## De boss-node op `origin` (linkermuur, bovenkant vloer); de hurtbox met middelpunt op arena-x `x`.
func setup_testboss(origin: Vector2, x: float) -> void:
	setup_boss("testboss")
	position = origin
	var size := Vector2(EnemyData.value(data_group, "breedte"), EnemyData.value(data_group, "hoogte"))
	core = add_part("Kern", size, Vector2(x, size.y * 0.5))
	var body := BodyBuilder.make_visual(size, COLOR)
	body.name = "Lichaam"
	body.position = core.position
	add_child(body)
	var tell := Polygon2D.new()
	tell.name = "Tell"
	tell.visible = false
	add_child(tell)


func on_start(tick: int) -> void:
	_next_beat = tick


func on_reset(_tick: int) -> void:
	_next_beat = 0


## Eén stamp per maat: een vlak rond zijn middelpunt op de vloer.
func fight_update(tick: int, _p1: Node2D) -> void:
	if tick < _next_beat:
		return
	_next_beat = tick + EnemyData.ticks(data_group, "maat")
	var half := EnemyData.value(data_group, "vlak_breedte") * 0.5
	var x := core.position.x
	var box := arena_rect(x - half, x + half, 0.0, EnemyData.value(data_group, "vlak_hoogte"))
	begin_attack(tick, "stamp", 0, box, EnemyData.ticks(data_group, "aanloop"),
		EnemyData.ticks(data_group, "actief"), EnemyData.ticks(data_group, "herstel"))


func update_visual(tick: int) -> void:
	var tell := get_node_or_null(^"Tell") as Polygon2D
	if tell == null:
		return
	tell.visible = is_telling() or is_attack_active()
	if tell.visible:
		var r := Rect2(attack_box.position - global_position, attack_box.size)
		tell.polygon = PackedVector2Array([r.position, Vector2(r.end.x, r.position.y), r.end,
			Vector2(r.position.x, r.end.y)])
		tell.color = Color(TELL_COLOR, 0.15 + 0.45 * windup_progress(tick)) if is_telling() \
			else Color(1, 0.4, 0.3, 0.8)
	var body := get_node_or_null(^"Lichaam") as CanvasItem
	if body != null:
		body.visible = not is_defeated()
