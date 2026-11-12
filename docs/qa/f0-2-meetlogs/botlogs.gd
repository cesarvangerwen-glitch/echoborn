extends SceneTree
## Hulpscript van QA (T17-2, #80): schrijft meetlogs van de bots, om
## `rekenen.gd` te toetsen (testplan F0-2 §2) en als eerste indicatie op D = 60
## (besluit 2026-11-12). Geen test: niets wordt gecontroleerd, alleen geschreven.
##
##   godot --headless --path game --fixed-fps 60 -s "$PWD/docs/qa/f0-2-meetlogs/botlogs.gd" -- <uitvoermap>
##   godot --headless --path game -s "$PWD/docs/qa/f0-2-meetlogs/rekenen.gd" -- <uitvoermap>
##
## Schrijft:
## - `bot_D<D>_echo.csv`: de gescripte geoefende run (`flow_bot.gd`) per D, vanaf RUN_START;
## - `bot_D120_zonder.csv`: dezelfde run met echo uit (langzame lijn, FK-2);
## - `botB1_D<D>.csv`: de gescripte run vanaf B1 (route-stap 3, P1 op x 320 van de
##   B1-gang): bij D = 60 komt de run vanaf RUN_START niet voorbij B3 (B3-blok
##   = D − 60 = 0 px), dus zo meet QA B1, B2, K2 en K3 apart;
## - `wachtbot_D<D>_B1_in_<x>.csv`: de wachtbot (`flow_wachtbot.gd`) in B1, op weg
##   naar binnen, stil op x px van de keerwand.

const FlowRoom = preload("res://levels/flowkamer/flow_room.gd")
const FlowBot = preload("res://levels/flowkamer/flow_bot.gd")
const Wachtbot = preload("res://levels/flowkamer/flow_wachtbot.gd")
const Layout = preload("res://levels/flowkamer/flow_layout.gd")

const TICK_CAP := 7000
## Route-stap B1 in `flow_bot.gd` (`_legs`: B4, Omkeer, B3, B1, …).
const LEG_B1 := 3

var out := ""


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	out = args[0] if args.size() > 0 else "user://botlogs"
	DirAccess.make_dir_recursive_absolute(out)
	_run.call_deferred()


func _run() -> void:
	for d in [60, 90, 120, 180]:
		await _bot(d, true, false)
	await _bot(120, false, false)
	for d in [60, 90]:
		await _bot(d, true, true)
	for d in [60, 120]:
		for x in [40.0, 160.0]:
			await _wacht(d, x)
	quit()


func _room(d: int, echo_on: bool):
	var room = FlowRoom.new()
	room.tail = d
	room.echo_on = echo_on
	room.autosave = false
	room.show_hud = false
	return room


func _bot(d: int, echo_on: bool, from_b1: bool) -> void:
	var room = _room(d, echo_on)
	var bot = FlowBot.new(room)
	if from_b1:
		bot.leg = LEG_B1
	room.input_override = bot
	root.add_child(room)
	if from_b1:
		room.p1.position = Vector2(320, Layout.LEVEL_540 - Layout.HALF_H)
	while not room.run_over and room.sim.tick < TICK_CAP:
		await physics_frame
	if not room.run_over:
		room.meetlog.finish()
	var file_name := ("botB1_D%d.csv" % d) if from_b1 else ("bot_D%d_%s.csv" % [d, "echo" if echo_on else "zonder"])
	room.meetlog.save(out.path_join(file_name))
	print("%s · RUN_EIND %s op tick %d · echolijn per stap %s · bounce px van de wand %s · landing px %s · keertick %s · klaar %s" % [
		file_name, room.run_over, room.sim.tick, bot.lines, bot.bounce_from_wall, bot.landed_from_wall,
		bot.turned, bot.leg_done])
	room.queue_free()
	await process_frame


func _wacht(d: int, x: float) -> void:
	var room = _room(d, true)
	var bot = Wachtbot.new(room, Layout.turn_points()[0], "in", x)
	room.input_override = bot
	root.add_child(room)
	room.p1.position = bot.start_position()
	var frames := 0
	while frames < 1200 and not bot.done:
		await physics_frame
		frames += 1
	room.meetlog.finish()
	var file_name := "wachtbot_D%d_B1_in_%d.csv" % [d, int(x)]
	room.meetlog.save(out.path_join(file_name))
	print("%s · uitkomst %s · gewacht %d ticks" % [file_name, bot.result, bot.waited])
	room.queue_free()
	await process_frame
