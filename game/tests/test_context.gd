extends RefCounted
## Hulpmiddelen voor één test: wereld opbouwen, ticks draaien, controleren.

const Sim = preload("res://scripts/sim.gd")
const SpikeWorld = preload("res://scripts/world/spike_world.gd")

var tree: SceneTree
var failures: PackedStringArray = []
var notes: PackedStringArray = []
var checks := 0

var _root: Node2D


func _init(p_tree: SceneTree) -> void:
	tree = p_tree


## Nieuwe, lege testwereld met de spike-level en een Sim.
func make_sim() -> Sim:
	_root = Node2D.new()
	_root.name = "TestWorld"
	tree.root.add_child(_root)
	SpikeWorld.build(_root)
	var sim := Sim.new()
	sim.name = "Sim"
	_root.add_child(sim)
	return sim


func world_root() -> Node2D:
	return _root


## Wacht tot de Sim precies `n` extra ticks heeft verwerkt. Komt terug aan
## het begin van de volgende physics-frame, vóór de Sim die frame stapt.
func run_ticks(sim: Sim, n: int) -> void:
	var target := sim.tick + n
	while sim.tick < target:
		await tree.physics_frame


func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures.append(message)


func note(message: String) -> void:
	notes.append(message)


func cleanup() -> void:
	if _root:
		_root.queue_free()
		_root = null
	await tree.process_frame


## Waarom deze test FAIL is; leeg = PASS. Een test zonder checks, met een
## scriptfout of enginefout, of die niet binnen de tijd klaar was, faalt
## altijd (#30), ook als geen enkele check mislukte.
func verdict(errors: PackedStringArray, finished: bool) -> PackedStringArray:
	var reasons := failures.duplicate()
	if not finished:
		reasons.append("test niet afgerond binnen de tijdslimiet (hangt of wacht op een tick die niet komt)")
	for error in errors:
		reasons.append("fout tijdens de test: %s" % error)
	if checks == 0:
		reasons.append("0 checks: de test controleerde niets (gecrasht vóór de eerste check?)")
	return reasons
