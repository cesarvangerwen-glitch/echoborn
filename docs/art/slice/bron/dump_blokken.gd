extends SceneTree
## Art Director (#85, deel 4): schrijft Layout.blocks() van alle kamers bij D = 60/90/120/180 als JSON,
## de bron van de geometrie voor genereer_slice_deel4.py. Draaien vanaf de repo-root:
##   godot --headless --path game -s "$PWD/docs/art/slice/bron/dump_blokken.gd" -- docs/art/slice/bron/kadewijk_blokken.json
const Layout = preload("res://levels/kadewijk/kadewijk_layout.gd")
func _init() -> void:
	var out := {}
	for d in [60, 90, 120, 180]:
		var per := {}
		for id in Layout.ORDER:
			var arr := []
			for spec: Array in Layout.blocks(id, d):
				var r: Rect2 = spec[1]
				arr.append([str(spec[0]), r.position.x, r.position.y, r.size.x, r.size.y, spec[2]])
			per[str(id)] = {"rect": [Layout.ROOMS[id].position.x, Layout.ROOMS[id].position.y, Layout.ROOMS[id].size.x, Layout.ROOMS[id].size.y], "blocks": arr}
		out[str(d)] = per
	var f := FileAccess.open(OS.get_cmdline_user_args()[0], FileAccess.WRITE)
	f.store_string(JSON.stringify(out))
	f.close()
	quit(0)
