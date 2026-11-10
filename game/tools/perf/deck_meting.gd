extends Node
## Deck-meting van de flow-kamer (T7, issue #79). Meetscript, geen gamecode.
##
## Laadt `levels/flowkamer/flowkamer.tscn` per scenario opnieuw, laat de
## gescripte run (`flow_bot.gd`) spelen en meet frametijd, render-tijd
## (CPU/GPU, zoals `prototypes/lichtmeting`), draw calls, lichten, occluders
## en geheugen. Het lichtbudget komt uit `docs/tech/lichtmeting.md` §5:
## de scenario's "wijk20" en "piek30" voegen tijdens de meting een lichtset
## toe die het normale (20 LE) en het piekbudget (30 LE) vult. De kamer en
## haar scripts blijven ongewijzigd; alles wat hier wordt toegevoegd, bestaat
## alleen tijdens de meting.
##
## Opties na `--`: `--frames=300`, `--warmup=90`, `--only=grijs,wijk20`,
## `--res=native|640|project` (native = render op venstergrootte, zonder stretch;
## 640 = wereld op 640×400 renderen en ×2 opschalen; project = de instellingen
## uit `project.godot` laten staan, in de Deck-build dus 640×400). De camerazoom
## volgt de rendergrootte zelf (`FlowRoom.camera_zoom`, #120); het script zet
## hem niet meer. Zie docs/tech/performance-flowkamer.md §3.
## Uitleg en drempels: `docs/tech/performance-flowkamer.md`.

const FLOW_SCENE := "res://levels/flowkamer/flowkamer.tscn"
const FlowBot = preload("res://levels/flowkamer/flow_bot.gd")

## [naam, wat, schaduwlichten, lichten zonder schaduw, texture_scale schaduwlichten, saturatiepass, LE volgens lichtmeting §5.1]
const SCENARIOS := [
	["grijs", "flow-kamer zoals gemerged (geen 2D-licht)", 0, 0, 1.5, false, 0.0],
	["wijk20", "verlichte wijk: 3 schaduwlichten 384 px, 1 licht 192 px, occluders, saturatiepass", 3, 1, 3.0, true, 20.0],
	["piek30", "piek: 8 schaduwlichten 192 px, occluders, saturatiepass", 8, 0, 1.5, true, 30.0],
	["grijs-eind", "controle drift (gelijk aan grijs)", 0, 0, 1.5, false, 0.0],
]

var frames := 300
var warmup := 120
var only: PackedStringArray = []
var res_mode := "native"

var _rows: Array = []
var _light_tex: Texture2D
var _follow: Node2D
var _follow_cam: Camera2D


func _ready() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--frames="):
			frames = int(arg.get_slice("=", 1))
		elif arg.begins_with("--warmup="):
			warmup = int(arg.get_slice("=", 1))
		elif arg.begins_with("--only="):
			only = arg.get_slice("=", 1).split(",")
		elif arg.begins_with("--res="):
			res_mode = arg.get_slice("=", 1)
	var vp := get_viewport().get_viewport_rid()
	RenderingServer.viewport_set_measure_render_time(vp, true)
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	Engine.max_fps = 0
	if res_mode == "640":
		get_window().content_scale_mode = Window.CONTENT_SCALE_MODE_VIEWPORT
		get_window().content_scale_size = Vector2i(640, 400)
		get_window().content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP
	elif res_mode == "native":
		# Ook in de Deck-build (die op 640×400 staat) native meten.
		get_window().content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	_light_tex = _make_light_texture()
	_print_header()
	for sc: Array in SCENARIOS:
		if only.size() > 0 and not only.has(sc[0]):
			continue
		await _run_scenario(sc)
	_print_table()
	_save_csv()
	get_tree().quit(0)


func _process(_delta: float) -> void:
	if is_instance_valid(_follow) and is_instance_valid(_follow_cam):
		_follow.position = _follow_cam.get_screen_center_position()


func _print_header() -> void:
	print("Deck-meting flow-kamer (T7) - Godot %s" % Engine.get_version_info().string)
	print("adapter: %s | %s | api %s" % [RenderingServer.get_video_adapter_vendor(),
		RenderingServer.get_video_adapter_name(), RenderingServer.get_video_adapter_api_version()])
	print("renderer: %s | os: %s | cpu: %s (%d threads)" % [
		ProjectSettings.get_setting("rendering/renderer/rendering_method"), OS.get_name(),
		OS.get_processor_name(), OS.get_processor_count()])
	print("venster: %s | render: %s | res-modus: %s | features deck: %s | frames %d, opwarm %d" % [
		get_window().size, get_viewport().get_texture().get_size(), res_mode,
		OS.has_feature("deck"), frames, warmup])


func _run_scenario(sc: Array) -> void:
	var t0 := Time.get_ticks_usec()
	var room: Node = (load(FLOW_SCENE) as PackedScene).instantiate()
	room.autosave = false
	room.input_override = FlowBot.new(room)
	add_child(room)
	await get_tree().process_frame
	var load_ms := (Time.get_ticks_usec() - t0) / 1000.0
	var zoom_start: float = room._camera.zoom.x
	var rig := _add_light_rig(room, sc)
	for i in warmup:
		await get_tree().process_frame
	var vp := get_viewport().get_viewport_rid()
	var ft: Array[float] = []
	var cpu := 0.0
	var gpu := 0.0
	var dc_sum := 0.0
	var dc_max := 0
	var obj_sum := 0.0
	var last := Time.get_ticks_usec()
	for i in frames:
		await get_tree().process_frame
		var now := Time.get_ticks_usec()
		ft.append((now - last) / 1000.0)
		last = now
		cpu += RenderingServer.viewport_get_measured_render_time_cpu(vp)
		gpu += RenderingServer.viewport_get_measured_render_time_gpu(vp)
		var dc := int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
		dc_sum += dc
		dc_max = maxi(dc_max, dc)
		obj_sum += Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME)
	var sorted := ft.duplicate()
	sorted.sort()
	var avg := 0.0
	for v in ft:
		avg += v
	avg /= ft.size()
	_rows.append({
		"scenario": sc[0], "wat": sc[1], "le": sc[6],
		"lichten": rig.lights, "schaduwlichten": rig.shadow_lights, "occluders": rig.occluders,
		"gem_ms": avg, "p50_ms": sorted[sorted.size() / 2], "p95_ms": sorted[int(sorted.size() * 0.95)],
		"max_ms": sorted[sorted.size() - 1],
		"cpu_ms": cpu / frames, "gpu_ms": gpu / frames,
		"drawcalls": dc_sum / frames, "drawcalls_max": dc_max, "objecten": obj_sum / frames,
		"mem_mb": Performance.get_monitor(Performance.MEMORY_STATIC) / 1048576.0,
		"vram_mb": Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED) / 1048576.0,
		"laad_ms": load_ms, "tick": room.sim.tick, "run_klaar": room.run_over,
		"zoom_start": zoom_start, "zoom_eind": room._camera.zoom.x,
	})
	print("  klaar: %s (tick %d, render %s, zoom start %.3f / eind %.3f)" % [sc[0], room.sim.tick,
		get_viewport().get_visible_rect().size, zoom_start, room._camera.zoom.x])
	room.queue_free()
	await get_tree().process_frame
	await get_tree().process_frame


## Lichtset die het lichtbudget vult; volgt de camera, zodat alles op het scherm valt.
func _add_light_rig(room: Node, sc: Array) -> Dictionary:
	var info := {"lights": 0, "shadow_lights": 0, "occluders": 0}
	var n_shadow: int = sc[2]
	var n_plain: int = sc[3]
	if n_shadow + n_plain == 0:
		return info
	var mod := CanvasModulate.new()
	mod.color = Color(0.22, 0.22, 0.27)
	room.add_child(mod)
	# Occluders op elk blok van de kamer (vierhoek van de botsvorm).
	for body in room.find_children("*", "StaticBody2D", true, false):
		for shape in body.find_children("*", "CollisionShape2D", false, false):
			var rect := shape.shape as RectangleShape2D
			if rect == null:
				continue
			var occ := LightOccluder2D.new()
			var poly := OccluderPolygon2D.new()
			var h := rect.size * 0.5
			poly.polygon = PackedVector2Array([Vector2(-h.x, -h.y), Vector2(h.x, -h.y), h, Vector2(-h.x, h.y)])
			occ.occluder = poly
			occ.position = shape.position
			body.add_child(occ)
			info.occluders += 1
	var follow := Node2D.new()
	follow.name = "Lichtrig"
	room.add_child(follow)
	var cam: Camera2D = room._camera
	var spots := [Vector2(-200, -80), Vector2(0, -110), Vector2(200, -80), Vector2(-100, 40),
		Vector2(100, 40), Vector2(-260, 60), Vector2(260, 60), Vector2(0, 120)]
	for i in n_shadow + n_plain:
		var l := PointLight2D.new()
		l.texture = _light_tex
		var shadow := i < n_shadow
		l.texture_scale = sc[4] if shadow else 1.5
		l.shadow_enabled = shadow
		l.shadow_filter = Light2D.SHADOW_FILTER_PCF5
		l.energy = 1.1
		l.color = Color(1.0, 0.85, 0.6)
		l.position = spots[i % spots.size()]
		follow.add_child(l)
		info.lights += 1
		if shadow:
			info.shadow_lights += 1
	_follow = follow
	_follow_cam = cam
	if sc[5]:
		var layer := CanvasLayer.new()
		layer.layer = 5
		var rect := ColorRect.new()
		rect.set_anchors_preset(Control.PRESET_FULL_RECT)
		rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var mat := ShaderMaterial.new()
		var sh := Shader.new()
		sh.code = "shader_type canvas_item;\nuniform sampler2D screen_tex : hint_screen_texture, filter_nearest;\nuniform float sat = 0.6;\nvoid fragment() {\n\tvec3 c = texture(screen_tex, SCREEN_UV).rgb;\n\tfloat g = dot(c, vec3(0.299, 0.587, 0.114));\n\tCOLOR = vec4(mix(vec3(g), c, sat), 1.0);\n}\n"
		mat.shader = sh
		rect.material = mat
		layer.add_child(rect)
		room.add_child(layer)
	return info


func _make_light_texture() -> Texture2D:
	var g := Gradient.new()
	g.set_color(0, Color(1, 1, 1, 1))
	g.set_color(1, Color(1, 1, 1, 0))
	var tex := GradientTexture2D.new()
	tex.gradient = g
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(1.0, 0.5)
	tex.width = 256
	tex.height = 256
	return tex


func _print_table() -> void:
	print("")
	print("| scenario | LE | lichten (schaduw) | occluders | frame gem ms | p95 ms | max ms | CPU-render ms | GPU ms | draw calls gem/max | laad ms |")
	print("|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|")
	for r: Dictionary in _rows:
		print("| %s | %.0f | %d (%d) | %d | %.1f | %.1f | %.1f | %.2f | %.2f | %.0f / %d | %.0f |" % [
			r.scenario, r.le, r.lichten, r.schaduwlichten, r.occluders, r.gem_ms, r.p95_ms, r.max_ms,
			r.cpu_ms, r.gpu_ms, r.drawcalls, r.drawcalls_max, r.laad_ms])
	if _rows.size() > 0:
		var r: Dictionary = _rows[_rows.size() - 1]
		print("geheugen statisch %.1f MB, video %.1f MB" % [r.mem_mb, r.vram_mb])


func _save_csv() -> void:
	var path := "user://deck_meting_%s.csv" % res_mode
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		push_warning("CSV niet opgeslagen: %s" % path)
		return
	var keys := ["scenario", "le", "lichten", "schaduwlichten", "occluders", "gem_ms", "p50_ms", "p95_ms",
		"max_ms", "cpu_ms", "gpu_ms", "drawcalls", "drawcalls_max", "objecten", "mem_mb", "vram_mb", "laad_ms", "tick", "run_klaar", "zoom_start", "zoom_eind"]
	f.store_line(",".join(keys))
	for r: Dictionary in _rows:
		var vals := PackedStringArray()
		for k in keys:
			vals.append(str(r[k]))
		f.store_line(",".join(vals))
	print("CSV: %s" % ProjectSettings.globalize_path(path))
