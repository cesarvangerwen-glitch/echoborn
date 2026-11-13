extends SceneTree
## Hulpscript van QA (MT2, #250): schrijft de meetlogs van de gescripte lus door
## de Kadewijk (S1 → S8 → de Gemaalmeester → S9 → S1, `SLICE_EIND`), om
## `rekenen.gd` te voeden (testplan MT2 §2.2 punt 3, 4, 9 en 10). Geen test:
## niets wordt gecontroleerd, alleen geschreven. Aangepaste kopie van
## `docs/qa/mt1-meetlogs/botlogs.gd` (dat blijft ongewijzigd voor MT1).
##
##   godot --headless --path game --fixed-fps 60 -s "$PWD/docs/qa/mt2-meetlogs/botlogs.gd" -- <uitvoermap>
##   godot --headless --path game -s "$PWD/docs/qa/mt2-meetlogs/rekenen.gd" -- <uitvoermap>
##
## Schrijft per D (60, en als regressie 90 / 120 / 180):
## - `bot_lus_D<D>.csv`: het meetlog van de lus, zoals `test_kadewijk_lus.gd`
##   hem loopt (`kadewijk_bot.gd` met `lus`, in S8 `boss_bot.gd`);
## - `hang_lus_D<D>.csv`: per tick de toestand van P1 en de echo
##   (`tick,kamer,x,y,vx,vy,vloer,echo,ex,ey`), waaruit `rekenen.gd` de
##   hangtijd boven de echo bij keren telt (RV-1, W33). Het meetlog zelf heeft
##   geen afzet-event, daarom dit aparte log.

const Scene := preload("res://levels/kadewijk/kadewijk.tscn")
const Bot = preload("res://levels/kadewijk/kadewijk_bot.gd")
const BossBot = preload("res://tests/boss_bot.gd")
const Layout = preload("res://levels/kadewijk/kadewijk_layout.gd")
const Kadewijk = preload("res://levels/kadewijk/kadewijk.gd")
const Progress = preload("res://scripts/save/progress.gd")

const RUN_LIMIT := 30000

var out := ""


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	out = args[0] if args.size() > 0 else "user://botlogs_mt2"
	DirAccess.make_dir_recursive_absolute(out)
	_run.call_deferred()


func _run() -> void:
	for d in [60, 90, 120, 180]:
		await _lus(d)
	quit()


func _lus(d: int) -> void:
	var progress := Progress.new()
	progress.name = "QAProgress"
	root.add_child(progress)
	var wijk = Scene.instantiate()
	wijk.tail = d
	wijk.echo_on = true
	wijk.show_hud = false
	wijk.progress = progress
	wijk.start_at = Layout.ROOM_START[&"S1"]
	wijk.run_end = Kadewijk.RUN_END_LUS
	var bot := Bot.new(wijk, d, &"S1")
	bot.lus = true
	bot.boss_input = func(sim: Node, boss: Node) -> RefCounted:
		return BossBot.new(sim, boss).p1_source
	wijk.input_override = bot
	root.add_child(wijk)
	var hang := PackedStringArray(["tick,kamer,x,y,vx,vy,vloer,echo,ex,ey"])
	await physics_frame
	while not wijk.run_over and wijk.sim.tick < RUN_LIMIT:
		await physics_frame
		var p1 = wijk.p1
		var e = wijk.echo
		var present: bool = e != null and e.is_present()
		hang.append("%d,%s,%.2f,%.2f,%.3f,%.3f,%d,%d,%.2f,%.2f" % [wijk.sim.tick, wijk.room,
			p1.position.x, p1.position.y, p1.motor.velocity.x, p1.motor.velocity.y, int(p1.motor.on_floor),
			int(present), e.position.x if present else 0.0, e.position.y if present else 0.0])
	if not wijk.run_over:
		wijk.meetlog.finish()
	wijk.meetlog.save(out.path_join("bot_lus_D%d.csv" % d))
	var f := FileAccess.open(out.path_join("hang_lus_D%d.csv" % d), FileAccess.WRITE)
	f.store_string("\n".join(hang) + "\n")
	f.close()
	print("bot_lus_D%d.csv · SLICE_EIND %s op tick %d · run %d ticks · kamer %s" % [
		d, wijk.slice_end_tick > 0, wijk.sim.tick, wijk.run_ticks(), wijk.room])
	wijk.queue_free()
	progress.queue_free()
	await process_frame
