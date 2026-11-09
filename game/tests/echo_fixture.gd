extends RefCounted
## Gedeelde opbouw voor de tests van beweging en echo v0.4 (T16a).
##
## Een lege wereld met een vloer, P1, de staart-echo, en een "spookbron":
## een speler die niet in de Sim zit en waarvan de test de opname zelf
## invult. Zo kan een test de echo elk pad laten lopen (bv. 3 px/tick).

const PlayerActor = preload("res://scripts/echo/player_actor.gd")
const TailEcho = preload("res://scripts/echo/tail_echo.gd")
const ScriptedInput = preload("res://scripts/input/scripted_input.gd")
const SpikeWorld = preload("res://scripts/world/spike_world.gd")
const Layers = preload("res://scripts/world/layers.gd")
const Motor = preload("res://scripts/echo/motor.gd")
const Zone = preload("res://scripts/objects/zone.gd")

const FLOOR_TOP := 400.0
## Middelpunt van een lichaam (16 × 30) dat op de vloer staat.
const STAND_Y := FLOOR_TOP - 15.0
## Bovenkant van een echo die op de vloer staat = waar P1 erop staat.
const ON_ECHO_Y := STAND_Y - 30.0


## Lege wereld met een vloer van x = -1000 tot 3000.
static func world(t) -> Node:
	var sim = t.make_sim(false)
	SpikeWorld.add_block(t.world_root(), "Floor", Vector2(1000, FLOOR_TOP + 20), Vector2(4000, 40))
	return sim


## Blok op een laag; `rect` in wereldcoördinaten.
static func block(t, block_name: String, rect: Rect2, layer: int, one_way := false) -> StaticBody2D:
	return SpikeWorld.add_block(t.world_root(), block_name, rect.get_center(), rect.size, layer, one_way)


static func zone(t, kind: Zone.Kind, rect: Rect2) -> Zone:
	var z := Zone.new()
	z.setup(kind, rect.size)
	z.position = rect.get_center()
	t.world_root().add_child(z)
	return z


static func p1(sim: Node, segments: Array, at := Vector2(200, STAND_Y)) -> PlayerActor:
	var player := PlayerActor.new()
	player.setup(1, ScriptedInput.new(segments), Color.WHITE)
	player.position = at
	sim.add_player(player)
	return player


static func tail_echo(sim: Node, source: PlayerActor, tail: int) -> TailEcho:
	var echo := TailEcho.new()
	echo.setup(source, Color.BLACK, tail, sim.tick)
	if not sim.add_echo(echo):
		echo.free()
		return null
	return echo


## Spookbron: een speler buiten de Sim, onzichtbaar en zonder laag. De test
## vult de opname met `ghost_frame`.
static func ghost(t) -> PlayerActor:
	var player := PlayerActor.new()
	player.setup(1, ScriptedInput.new([]), Color.WHITE)
	player.name = "Ghost"
	player.collision_layer = 0
	player.collision_mask = 0
	player.visible = false
	t.world_root().add_child(player)
	return player


static func ghost_frame(source: PlayerActor, tick: int, at: Vector2, on_floor := true,
		support: int = Motor.Support.WORLD, events := 0) -> void:
	source.recorder.push(tick, 0, at, Vector2.ZERO, on_floor, at, Vector2.ZERO, events,
		on_floor, 1, support)


## Vult de spookbron voor ticks `from` .. `from + count - 1` met posities uit
## `path(k)` (k = 0 .. count - 1).
static func ghost_path(source: PlayerActor, from: int, count: int, path: Callable,
		on_floor := true, support: int = Motor.Support.WORLD) -> void:
	if count > source.recorder.capacity:
		push_error("ghost_path: %d frames passen niet in %d" % [count, source.recorder.capacity])
	for k in count:
		ghost_frame(source, from + k, path.call(k), on_floor, support)


## Houdt per tick (na stap 5) de positie van elke node bij: rows[i][tick].
static func trace(sim: Node, nodes: Array) -> Array:
	var rows: Array = []
	for i in nodes.size():
		rows.append({})
	sim.tick_finished.connect(func(tick: int) -> void:
		for i in nodes.size():
			rows[i][tick] = (nodes[i] as Node2D).position)
	return rows
