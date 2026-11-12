extends SceneTree
## Hulpscript van QA (MT1, #80): schrijft meetlogs van de bots op D = 60, om
## `rekenen.gd` te toetsen (testplan MT1 §2.2 punt 9). Geen test: niets wordt
## gecontroleerd, alleen geschreven. Bijgewerkte kopie van
## `docs/qa/f0-2-meetlogs/botlogs.gd`.
##
##   godot --headless --path game --fixed-fps 60 -s "$PWD/docs/qa/mt1-meetlogs/botlogs.gd" -- <uitvoermap>
##   godot --headless --path game -s "$PWD/docs/qa/mt1-meetlogs/rekenen.gd" -- <uitvoermap>
##
## Schrijft:
## - `bot_D<D>_echo.csv`: de gescripte geoefende run (`flow_bot.gd`) vanaf RUN_START,
##   D = 60 en als regressie 90 / 120 / 180;
## - `bot_D60_zonder.csv`: dezelfde run met echo uit (FK-2);
## - `bot_D60_laat8.csv`: de late bot, bounce 8 ticks te laat;
## - `wachtbot_D60_B1_in_<x>[_zonderdash].csv`: de wachtbot in B1, op weg naar
##   binnen, stil op x px van de keerwand.

const FlowRoom = preload("res://levels/flowkamer/flow_room.gd")
const FlowBot = preload("res://levels/flowkamer/flow_bot.gd")
const Wachtbot = preload("res://levels/flowkamer/flow_wachtbot.gd")
const Layout = preload("res://levels/flowkamer/flow_layout.gd")

const TICK_CAP := 7000

var out := ""


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	out = args[0] if args.size() > 0 else "user://botlogs"
	DirAccess.make_dir_recursive_absolute(out)
	_run.call_deferred()


func _run() -> void:
	for d in [60, 90, 120, 180]:
		await _bot(d, true, 0, "echo")
	await _bot(60, false, 0, "zonder")
	await _bot(60, true, 8, "laat8")
	for x in [0.0, 20.0]:
		await _wacht(60, x, false)
	for x in [40.0, 160.0]:
		await _wacht(60, x, true)
	quit()


func _room(d: int, echo_on: bool):
	var room = FlowRoom.new()
	room.tail = d
	room.echo_on = echo_on
	room.autosave = false
	room.show_hud = false
	return room


func _bot(d: int, echo_on: bool, late: int, tag: String) -> void:
	var room = _room(d, echo_on)
	var bot = FlowBot.new(room)
	bot.bounce_delay = late
	room.input_override = bot
	root.add_child(room)
	while not room.run_over and room.sim.tick < TICK_CAP:
		await physics_frame
	if not room.run_over:
		room.meetlog.finish()
	var file_name := "bot_D%d_%s.csv" % [d, tag]
	room.meetlog.save(out.path_join(file_name))
	print("%s · RUN_EIND %s op tick %d · echolijn per stap %s · bounce px van de wand %s · landing px %s" % [
		file_name, room.run_over, room.sim.tick, bot.lines, bot.bounce_from_wall, bot.landed_from_wall])
	room.queue_free()
	await process_frame


func _wacht(d: int, x: float, dash: bool) -> void:
	var room = _room(d, true)
	var bot = Wachtbot.new(room, Layout.turn_points()[0], "in", x)
	bot.use_dash = dash
	room.input_override = bot
	root.add_child(room)
	room.p1.position = bot.start_position()
	var frames := 0
	while frames < 1200 and not bot.done:
		await physics_frame
		frames += 1
	room.meetlog.finish()
	var file_name := "wachtbot_D%d_B1_in_%d%s.csv" % [d, int(x), "" if dash else "_zonderdash"]
	room.meetlog.save(out.path_join(file_name))
	print("%s · uitkomst %s · gewacht %d ticks" % [file_name, bot.result, bot.waited])
	room.queue_free()
	await process_frame
