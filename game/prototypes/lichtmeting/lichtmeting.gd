extends Node2D
## Lichtmeting 2D (issue #21, risico C7): wat kost dynamisch 2D-licht in de
## Compatibility-renderer op Steam Deck-resolutie (1280x800)?
##
## Eén kamer naar de stijltest (docs/art/stijltests.md §2): grijs-donkere
## wereld (CanvasModulate), tegels en zuilen als lichtvangers, 2 spelers en
## hun echo's uit de spike (Sim, PlayerActor, EchoActor in STATE-modus, staart
## 2 s volgens besluit #51 8A). Per scenario verandert één ding: aantal
## PointLight2D's, schaduw aan/uit, schaduwfilter, aantal LightOccluder2D's,
## echo-effect, saturatie-pass (grijs -> kleur), FelLicht-zone, resolutie.
##
## Draaien (vanuit de repo-root, met venster; zie docs/tech/lichtmeting.md §3):
##   godot --path game --resolution 1280x800 res://prototypes/lichtmeting/lichtmeting.tscn
## Opties na `--`:  --frames=300  --warmup=90  --only=S4,typisch  --shots (PNG per scenario)
## Uitvoer: een tabel op stdout en user://lichtmeting.csv. Stopt zelf.
##
## Prototype, geen productiecode: niets uit game/scripts hangt hiervan af.

const Sim = preload("res://scripts/sim.gd")
const PlayerActor = preload("res://scripts/echo/player_actor.gd")
const EchoActor = preload("res://scripts/echo/echo_actor.gd")
const ScriptedInput = preload("res://scripts/input/scripted_input.gd")
const InputBits = preload("res://scripts/input/input_bits.gd")
const SpikeWorld = preload("res://scripts/world/spike_world.gd")

const WORLD_SIZE := Vector2(1280, 800)   ## wereld in spike-eenheden
const PIXEL_SIZE := Vector2i(640, 400)   ## pixel-art-resolutie Deck (besluit #18)
const TILE := 32.0                       ## 16 px pixel-art = 32 wereld-eenheden
const LIGHT_TEX_SIZE := 256
const LIGHT_SCALE := 1.5                 ## lichtdiameter 384 eenheden = 30 % schermbreedte
const ECHO_TAIL_TICKS := 120             ## 2 s staart (#51 8A)
const GHOSTS_PER_ECHO := 8               ## nabeelden in de staart
const GHOST_STEP := 15                   ## ticks tussen nabeelden (8 x 15 = 2 s)
const GREY := Color(0.22, 0.22, 0.27)    ## "grijs-donker" vóór het oppompen

const SAT_SHADER := """
shader_type canvas_item;
uniform sampler2D screen_tex : hint_screen_texture, filter_nearest;
uniform float saturation = 0.35;
void fragment() {
	vec3 c = texture(screen_tex, SCREEN_UV).rgb;
	float g = dot(c, vec3(0.299, 0.587, 0.114));
	COLOR = vec4(mix(vec3(g), c, saturation), 1.0);
}
"""

## Basis van elk scenario; een scenario overschrijft alleen wat het test.
const BASE := {
	"lights": 0, "shadows": false, "filter": Light2D.SHADOW_FILTER_PCF5,
	"occluders": 32, "echo_fx": false, "post": false, "fel": false, "native": false,
}

var scenarios: Array = [
	["basis", {}],
	["L1", {"lights": 1}], ["L2", {"lights": 2}], ["L4", {"lights": 4}],
	["L8", {"lights": 8}], ["L16", {"lights": 16}],
	["S1", {"lights": 1, "shadows": true}], ["S2", {"lights": 2, "shadows": true}],
	["S4", {"lights": 4, "shadows": true}], ["S8", {"lights": 8, "shadows": true}],
	["S16", {"lights": 16, "shadows": true}],
	["S4-occ0", {"lights": 4, "shadows": true, "occluders": 0}],
	["S4-occ8", {"lights": 4, "shadows": true, "occluders": 8}],
	["S4-occ128", {"lights": 4, "shadows": true, "occluders": 128}],
	["S4-hard", {"lights": 4, "shadows": true, "filter": Light2D.SHADOW_FILTER_NONE}],
	["S4-pcf13", {"lights": 4, "shadows": true, "filter": Light2D.SHADOW_FILTER_PCF13}],
	["S4-echo", {"lights": 4, "shadows": true, "echo_fx": true}],
	["S4-post", {"lights": 4, "shadows": true, "post": true}],
	["S4-fel", {"lights": 4, "shadows": true, "fel": true}],
	["typisch", {"lights": 4, "shadows": true, "echo_fx": true, "post": true, "fel": true}],
	["zwaar", {"lights": 8, "shadows": true, "echo_fx": true, "post": true, "fel": true,
		"occluders": 64}],
	["N-basis", {"native": true}],
	["N-L4", {"lights": 4, "native": true}],
	["N-S4", {"lights": 4, "shadows": true, "native": true}],
	["N-typisch", {"lights": 4, "shadows": true, "echo_fx": true, "post": true, "fel": true,
		"native": true}],
	["basis-eind", {}],   # zelfde als "basis": toont drift (warmte, achtergrondlast)
]

var _frames := 300
var _warmup := 90
var _sim: Sim
var _camera: Camera2D
var _fx: Node2D            ## alles wat per scenario wisselt
var _post: CanvasLayer
var _light_tex: GradientTexture2D
var _tile_tex: ImageTexture
var _echo_of: Dictionary = {}
var _ghosts: Array[Sprite2D] = []
var _echo_lights: Array[PointLight2D] = []
var _results: Array = []
var _index := -1
var _frame := 0
var _last_usec := 0
var _samples := PackedFloat32Array()
var _cpu_render := 0.0
var _gpu_render := 0.0
var _shots := false


func _ready() -> void:
	_parse_args()
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	Engine.max_fps = 0
	RenderingServer.viewport_set_measure_render_time(get_viewport().get_viewport_rid(), true)
	_light_tex = _make_light_texture()
	_tile_tex = _make_tile_texture()
	_build_room()
	_build_actors()
	_fx = Node2D.new()
	_fx.name = "Fx"
	add_child(_fx)
	_print_header()
	_next_scenario()


func _parse_args() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--frames="):
			_frames = int(arg.get_slice("=", 1))
		elif arg.begins_with("--warmup="):
			_warmup = int(arg.get_slice("=", 1))
		elif arg.begins_with("--only="):
			var keep := arg.get_slice("=", 1).split(",")
			scenarios = scenarios.filter(func(s: Array) -> bool: return s[0] in keep)
		elif arg == "--shots":
			_shots = true


# --- Kamer en actors -------------------------------------------------------

func _build_room() -> void:
	var modulate_node := CanvasModulate.new()
	modulate_node.color = GREY
	add_child(modulate_node)
	# Achterwand: één grote getextureerde sprite over het hele scherm.
	var wall := Sprite2D.new()
	wall.texture = _tile_tex
	wall.centered = false
	wall.region_enabled = true
	wall.region_rect = Rect2(Vector2.ZERO, WORLD_SIZE)
	wall.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	wall.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	wall.modulate = Color(0.55, 0.5, 0.6)
	add_child(wall)
	# Botsing uit de spike (vloer, muren, platform).
	SpikeWorld.build(self)
	# Voorgrondtegels: vloer, zuilen, richels. Elke tegel is een lichtvanger.
	var tiles := Node2D.new()
	tiles.name = "Tiles"
	add_child(tiles)
	for x in range(0, int(WORLD_SIZE.x), int(TILE)):
		for row in 4:   # vloer + ondergrond
			_add_tile(tiles, Vector2(x, SpikeWorld.FLOOR_Y + row * TILE))
		_add_tile(tiles, Vector2(x, 0))   # plafond
	for col in [3, 10, 17, 24, 31, 37]:   # zuilen
		for y in range(1, 10):
			_add_tile(tiles, Vector2(col * TILE, y * TILE + TILE))
	for i in 6:   # richels, licht- en schaduwplatforms
		for k in 4:
			_add_tile(tiles, Vector2((5 + i * 6 + k) * TILE, (5 + (i % 3) * 2) * TILE))


func _add_tile(parent: Node, pos: Vector2) -> void:
	var s := Sprite2D.new()
	s.texture = _tile_tex
	s.centered = false
	s.scale = Vector2.ONE * (TILE / 16.0)
	s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	s.position = pos
	parent.add_child(s)


func _build_actors() -> void:
	_sim = Sim.new()
	_sim.name = "Sim"
	add_child(_sim)
	# Gescripte input die eindeloos heen en weer loopt en springt.
	var loop := []
	for i in 400:
		loop.append([50, InputBits.RIGHT])
		loop.append([12, InputBits.RIGHT | InputBits.JUMP])
		loop.append([60, InputBits.LEFT])
		loop.append([12, InputBits.LEFT | InputBits.JUMP])
	var colors := [Color(1.0, 0.85, 0.4), Color(0.5, 0.85, 1.0)]
	for i in 2:
		var player := PlayerActor.new()
		player.setup(i + 1, ScriptedInput.new(loop), colors[i])
		player.position = SpikeWorld.PLAYER_SPAWN + Vector2(300 + 360 * i, 0)
		_sim.add_player(player)
	_camera = Camera2D.new()
	_camera.position = WORLD_SIZE * 0.5
	add_child(_camera)


func _physics_process(_delta: float) -> void:
	# Elke 2 s per speler een nieuwe echo van zijn laatste 2 s (zoals main.gd).
	if _sim.tick > 0 and _sim.tick % ECHO_TAIL_TICKS == 0:
		for player in _sim.players:
			if _echo_of.has(player.player_index):
				_sim.remove_echo(_echo_of[player.player_index])
			var echo := EchoActor.new()
			echo.setup(Color(0.2, 0.15, 0.35, 0.8))
			_sim.add_echo(echo)
			echo.start(player.recorder.snapshot(ECHO_TAIL_TICKS), EchoActor.Mode.STATE)
			_echo_of[player.player_index] = echo


# --- Scenario's ------------------------------------------------------------

func _apply(cfg: Dictionary) -> void:
	for child in _fx.get_children():
		child.queue_free()
	_ghosts.clear()
	_echo_lights.clear()
	if _post:
		_post.queue_free()
		_post = null
	var win := get_window()
	if cfg.native:
		win.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
		_camera.zoom = Vector2.ONE * (float(win.size.y) / WORLD_SIZE.y)
	else:
		win.content_scale_mode = Window.CONTENT_SCALE_MODE_VIEWPORT
		win.content_scale_size = PIXEL_SIZE
		win.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP
		_camera.zoom = Vector2.ONE * (float(PIXEL_SIZE.y) / WORLD_SIZE.y)
	# Lichten in een raster boven de kamer, zodat ze overlappen zoals in een echte kamer.
	var n: int = cfg.lights
	var cols := maxi(1, ceili(sqrt(n * 1.6)))
	var rows := maxi(1, ceili(float(n) / cols))
	for i in n:
		var light := _make_light(Color(1.0, 0.75, 0.4) if i % 2 == 0 else Color(0.7, 0.8, 1.0))
		light.position = Vector2((i % cols + 0.5) * WORLD_SIZE.x / cols,
			(floorf(float(i) / cols) + 0.5) * (SpikeWorld.FLOOR_Y - 40.0) / rows + 20.0)
		light.shadow_enabled = cfg.shadows
		light.shadow_filter = cfg.filter
		light.shadow_filter_smooth = 1.5
		_fx.add_child(light)
	# Occluders: blokken van een tegel breed op zuilen en richels.
	for i in int(cfg.occluders):
		var occ := LightOccluder2D.new()
		var poly := OccluderPolygon2D.new()
		poly.polygon = PackedVector2Array([Vector2(0, 0), Vector2(TILE, 0),
			Vector2(TILE, TILE), Vector2(0, TILE)])
		occ.occluder = poly
		occ.position = Vector2(fmod(i * 7.0 * TILE + 64.0, WORLD_SIZE.x - TILE),
			TILE * (2 + (i * 3) % 9))
		_fx.add_child(occ)
	if cfg.echo_fx:
		# Per echo: een klein eigen licht (zonder schaduw) en een staart van nabeelden.
		for k in 2 * GHOSTS_PER_ECHO:
			var g := Sprite2D.new()
			g.texture = _light_tex
			g.scale = Vector2.ONE * 0.12
			g.modulate = Color(1.0, 0.7, 0.3, 0.5 * (1.0 - float(k % GHOSTS_PER_ECHO) / GHOSTS_PER_ECHO))
			var mat := CanvasItemMaterial.new()
			mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
			g.material = mat
			_fx.add_child(g)
			_ghosts.append(g)
		for k in 2:
			var el := _make_light(Color(1.0, 0.6, 0.25))
			el.texture_scale = 0.5
			el.energy = 0.6
			_fx.add_child(el)
			_echo_lights.append(el)
	if cfg.fel:
		# FelLicht-zone: één harde schaduwlamp + een SUB-licht dat alleen de
		# schaduwgeometrie (light_mask 2) wegvreet: "hier lost de brug op".
		var fel := _make_light(Color(1.0, 1.0, 0.9))
		fel.position = Vector2(980, 120)
		fel.energy = 1.4
		fel.shadow_enabled = true
		_fx.add_child(fel)
		var sub := _make_light(Color(1, 1, 1))
		sub.position = fel.position + Vector2(0, 160)
		sub.blend_mode = Light2D.BLEND_MODE_SUB
		sub.range_item_cull_mask = 2
		_fx.add_child(sub)
		for k in 8:   # schaduwbrug
			var s := Sprite2D.new()
			s.texture = _tile_tex
			s.centered = false
			s.scale = Vector2.ONE * (TILE / 16.0)
			s.position = Vector2(820 + k * TILE, 300)
			s.light_mask = 2
			s.modulate = Color(0.6, 0.5, 0.9)
			_fx.add_child(s)
	if cfg.post:
		_post = CanvasLayer.new()
		_post.layer = 10
		var rect := ColorRect.new()
		rect.set_anchors_preset(Control.PRESET_FULL_RECT)
		rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var sm := ShaderMaterial.new()
		var sh := Shader.new()
		sh.code = SAT_SHADER
		sm.shader = sh
		rect.material = sm
		_post.add_child(rect)
		add_child(_post)


func _make_light(color: Color) -> PointLight2D:
	var light := PointLight2D.new()
	light.texture = _light_tex
	light.texture_scale = LIGHT_SCALE
	light.color = color
	light.energy = 1.0
	return light


func _process(_delta: float) -> void:
	var now := Time.get_ticks_usec()
	_update_echo_fx()
	if _frame >= _warmup:
		_samples.append((now - _last_usec) / 1000.0)
		var vp := get_viewport().get_viewport_rid()
		_cpu_render += RenderingServer.viewport_get_measured_render_time_cpu(vp)
		_gpu_render += RenderingServer.viewport_get_measured_render_time_gpu(vp)
	_last_usec = now
	_frame += 1
	if _frame >= _warmup + _frames:
		_finish_scenario()
		_next_scenario()


func _update_echo_fx() -> void:
	if _ghosts.is_empty():
		return
	var k := 0
	for player_index in [1, 2]:
		var echo: EchoActor = _echo_of.get(player_index)
		for i in GHOSTS_PER_ECHO:
			if k >= _ghosts.size():
				break
			var g := _ghosts[k]
			k += 1
			if echo == null or echo.trace.is_empty():
				g.visible = false
				continue
			var idx := maxi(0, echo.trace.size() - 1 - i * GHOST_STEP)
			g.visible = true
			g.position = echo.trace[idx]
	for i in _echo_lights.size():
		var echo: EchoActor = _echo_of.get(i + 1)
		if echo:
			_echo_lights[i].position = echo.position


func _next_scenario() -> void:
	_index += 1
	if _index >= scenarios.size():
		_write_results()
		get_tree().quit(0)
		return
	var cfg: Dictionary = BASE.duplicate()
	cfg.merge(scenarios[_index][1], true)
	_apply(cfg)
	_frame = 0
	_samples = PackedFloat32Array()
	_cpu_render = 0.0
	_gpu_render = 0.0
	_last_usec = Time.get_ticks_usec()


func _finish_scenario() -> void:
	if _shots:
		var shot := get_viewport().get_texture().get_image()
		shot.save_png("user://lichtmeting_%s.png" % scenarios[_index][0])
	var sorted := _samples.duplicate()
	sorted.sort()
	var total := 0.0
	for v in sorted:
		total += v
	var n := sorted.size()
	var cfg: Dictionary = BASE.duplicate()
	cfg.merge(scenarios[_index][1], true)
	var row := {
		"scenario": scenarios[_index][0],
		"lights": cfg.lights, "shadows": cfg.shadows, "occluders": cfg.occluders,
		"res": "1280x800" if cfg.native else "640x400",
		"mean_ms": total / n, "p50_ms": sorted[floori(n * 0.5)], "p95_ms": sorted[int(n * 0.95)],
		"cpu_render_ms": _cpu_render / n, "gpu_render_ms": _gpu_render / n,
	}
	_results.append(row)
	print("%-11s %3d %-5s %4d %-8s %8.2f %8.2f %8.2f %8.2f %8.2f" % [row.scenario,
		row.lights, "ja" if row.shadows else "nee", row.occluders, row.res, row.mean_ms,
		row.p50_ms, row.p95_ms, row.cpu_render_ms, row.gpu_render_ms])


func _print_header() -> void:
	print("Lichtmeting 2D (#21) - Godot %s - %s - %s" % [Engine.get_version_info().string,
		RenderingServer.get_video_adapter_name(), RenderingServer.get_video_adapter_api_version()])
	print("venster %s, %d warmup + %d meetframes per scenario" % [get_window().size,
		_warmup, _frames])
	print("%-11s %3s %-5s %4s %-8s %8s %8s %8s %8s %8s" % ["scenario", "lic", "schad",
		"occ", "render", "gem_ms", "p50_ms", "p95_ms", "cpu_ms", "gpu_ms"])


func _write_results() -> void:
	var f := FileAccess.open("user://lichtmeting.csv", FileAccess.WRITE)
	if f == null:
		return
	f.store_line("scenario,lights,shadows,occluders,res,mean_ms,p50_ms,p95_ms,cpu_render_ms,gpu_render_ms,adapter")
	for r in _results:
		f.store_line("%s,%d,%s,%d,%s,%.3f,%.3f,%.3f,%.3f,%.3f,%s" % [r.scenario, r.lights,
			r.shadows, r.occluders, r.res, r.mean_ms, r.p50_ms, r.p95_ms, r.cpu_render_ms,
			r.gpu_render_ms, RenderingServer.get_video_adapter_name()])
	print("CSV: %s" % ProjectSettings.globalize_path("user://lichtmeting.csv"))


# --- Placeholder-textures (in code, geen assets) ----------------------------

func _make_light_texture() -> GradientTexture2D:
	var grad := Gradient.new()
	grad.set_color(0, Color(1, 1, 1, 1))
	grad.set_color(1, Color(1, 1, 1, 0))
	var tex := GradientTexture2D.new()
	tex.gradient = grad
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(1.0, 0.5)
	tex.width = LIGHT_TEX_SIZE
	tex.height = LIGHT_TEX_SIZE
	return tex


func _make_tile_texture() -> ImageTexture:
	var img := Image.create(16, 16, false, Image.FORMAT_RGBA8)
	for y in 16:
		for x in 16:
			var edge := x == 0 or y == 0 or x == 15 or y == 15
			var v := 0.45 + 0.1 * float((x * 7 + y * 13) % 5) / 4.0
			img.set_pixel(x, y, Color(v * 0.8, v * 0.8, v) if not edge else Color(0.25, 0.25, 0.3))
	return ImageTexture.create_from_image(img)
