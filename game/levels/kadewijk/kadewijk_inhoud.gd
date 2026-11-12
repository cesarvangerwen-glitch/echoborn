extends Node2D
## De inhoud van één kamer van de Kadewijk (meestreamend, `Kamer.inhoud`;
## ontwerp.md §3a). Bouwt bij het laden de grijze blokken van zijn kamer uit
## `kadewijk_layout.gd`, voor de D van de sessie (`tail`, gezet door de
## gebiedsscène vóór `AreaLoader.start`): wat van D afhangt (keerzone, de trede
## op 90, het B3-blok) zit zo in data en niet in de scène (fasekader v0.4 §4,
## regel 2).
##
## Wat níét van D afhangt, staat als nodes in de scène: de vijanden
## (`SliceEnemy`, `slice-vijanden-en-boss.md` §2.6), het checkpoint, de
## bevroren echo's (WS-09: beeld zonder collision) en de markeringen. De wortel
## van elke kamerscène staat op `-midden van de kamer`, dus de kinderen staan
## in wereldcoördinaten.

const Layout = preload("res://levels/kadewijk/kadewijk_layout.gd")
const SpikeWorld = preload("res://scripts/world/spike_world.gd")

const BLOCK_COLOR := Color(0.35, 0.35, 0.4)
const ONE_WAY_COLOR := Color(0.55, 0.55, 0.6)
const TREAD_COLOR := Color(0.42, 0.5, 0.42)

## D van de sessie; de gebiedsscène zet hem vóór het laden van de eerste kamer.
static var tail := 60

@export var kamer_id: StringName = &""


func _ready() -> void:
	var level := Node2D.new()
	level.name = "Blokken"
	add_child(level)
	move_child(level, 0)
	for spec: Array in Layout.blocks(kamer_id, tail):
		var rect: Rect2 = spec[1]
		var body := SpikeWorld.add_block(level, spec[0], to_local(rect.get_center()), rect.size, 1, spec[2])
		var color := BLOCK_COLOR
		if spec[2]:
			color = TREAD_COLOR if str(spec[0]).contains("Trede") else ONE_WAY_COLOR
		for child in body.get_children():
			if child is Polygon2D:
				(child as Polygon2D).color = color
