extends RefCounted
## Wachtbot en late bot (T16d, #176; gdd §4.6 L-08 (a) en (b), §4.7.4 W-6).
##
## - **Wachtbot** (L-08 (a), rapport, geen voorwaarde): bij elk keerpunt van
##   B1 en B2 en per D staat P1 stil op `x` = 0, 20, 40 … px van de keerwand,
##   op weg naar binnen (tot de ingang van het niveau, dus ook onder de weg
##   omhoog en op `x > D`) en na het keren (`x` = 0 … D), tot de echo onder
##   hem stilstaat; dan springt hij op hem, bounct, stuurt van de wand af en
##   dasht op de top (`flow_wachtbot.gd`). De test schrijft per `x` de uitkomst
##   en de stilstand (`note`, tabel in `flowkamer.md` §9). Enige voorwaarde:
##   wie tegen de wand wacht (`x` = 0), haalt de weg omhoog niet (keerzone,
##   gdd §4.3).
## - **Late bot** (L-08 (b)): de gescripte geoefende run met de bounce 4 en 8
##   ticks te laat haalt bij elke D in B1 en elke verdieping van B2 de weg
##   omhoog, zonder dash. Daarnaast de dash 0, 4 en 8 ticks na de top van de
##   bounce (de geoefende run dasht niet: "weggelaten" is de gewone run in
##   `test_flowkamer_na_f0.gd`); die varianten rapporteren de landing.
##
## Elke run staat in een eigen SubViewport met een eigen World2D, zodat de
## runs van één D tegelijk lopen (eigen physics-ruimte per kamer).

const FlowRoom = preload("res://levels/flowkamer/flow_room.gd")
const FlowBot = preload("res://levels/flowkamer/flow_bot.gd")
const Wachtbot = preload("res://levels/flowkamer/flow_wachtbot.gd")
const Layout = preload("res://levels/flowkamer/flow_layout.gd")

const TURNS := ["B1", "B2-0", "B2-1", "B2-2", "B2-3"]
## Index van de bovenroute in de route van `flow_bot.gd`: daar is K1 klaar.
const LEG_AFTER_K1 := 8
## Ingang van het niveau, vanaf de keerwand: de gang van B1 (320 px) en de
## richels van B2 (360 px; de vloer van B2-0 is de galerij van B1, 360 px).
const LEVEL_LEN := {"B1": 320.0, "B2-0": 360.0, "B2-1": 360.0, "B2-2": 360.0, "B2-3": 360.0}


## Een kamer in een eigen SubViewport (eigen World2D). Geeft [viewport, kamer].
func _isolated_room(t, d: int) -> Array:
	var vp := SubViewport.new()
	vp.world_2d = World2D.new()
	vp.render_target_update_mode = SubViewport.UPDATE_DISABLED
	t.tree.root.add_child(vp)
	var room = FlowRoom.new()
	room.tail = d
	room.echo_on = true
	room.autosave = false
	room.show_hud = false
	return [vp, room]


func _free_all(t, viewports: Array) -> void:
	for vp: Node in viewports:
		vp.queue_free()
	await t.tree.process_frame


# --- Wachtbot (L-08 (a)) -------------------------------------------------------

func _wachtbot(t, d: int) -> void:
	var lines: Array = []
	for tp: Dictionary in Layout.turn_points():
		var jobs: Array = []
		var x := 0.0
		while x <= float(LEVEL_LEN[tp["name"]]) - 20.0:
			jobs.append(["in", x])
			x += 20.0
		x = 0.0
		while x <= d:
			jobs.append(["uit", x])
			x += 20.0
		var bots: Array = []
		var vps: Array = []
		for job: Array in jobs:
			var pair := _isolated_room(t, d)
			var room = pair[1]
			var bot = Wachtbot.new(room, tp, job[0], job[1])
			room.input_override = bot
			pair[0].add_child(room)
			room.p1.position = bot.start_position()
			bots.append(bot)
			vps.append(pair[0])
		var frames := 0
		while frames < 1200 and bots.any(func(b) -> bool: return not b.done):
			await t.tree.physics_frame
			frames += 1
		var cells := {"in": [], "uit": []}
		for b in bots:
			t.check(b.done, "D=%d %s %s x=%d: wachtbot niet klaar" % [d, tp["name"], b.mode, int(b.x)])
			if b.x == 0.0:
				t.check(b.result != "omhoog", "D=%d %s %s: tegen de wand gewacht en toch de weg omhoog (keerzone)" % [d, tp["name"], b.mode])
			cells[b.mode].append("%d %s %d" % [int(b.x), b.result, b.waited])
		lines.append("D=%d %s wachtbot in: %s | uit: %s" % [d, tp["name"], ", ".join(cells["in"]), ", ".join(cells["uit"])])
		await _free_all(t, vps)
	for line: String in lines:
		t.note(line)


func test_wachtbot_d90(t) -> void:
	await _wachtbot(t, 90)


func test_wachtbot_d120(t) -> void:
	await _wachtbot(t, 120)


func test_wachtbot_d180(t) -> void:
	await _wachtbot(t, 180)


# --- Late bot (L-08 (b)) ------------------------------------------------------

## [naam, bounce_delay, dash_delay]; dash_delay -1 = geen dash.
const LATE := [["bounce+4", 4, -1], ["bounce+8", 8, -1], ["dash+0", 0, 0], ["dash+4", 0, 4], ["dash+8", 0, 8]]


func _late_bot(t, d: int) -> void:
	var bots: Array = []
	var vps: Array = []
	var rooms: Array = []
	for v: Array in LATE:
		var pair := _isolated_room(t, d)
		var room = pair[1]
		var bot = FlowBot.new(room)
		bot.bounce_delay = v[1]
		bot.dash_delay = v[2]
		room.input_override = bot
		pair[0].add_child(room)
		bots.append(bot)
		vps.append(pair[0])
		rooms.append(room)
	var frames := 0
	while frames < 4000 and bots.any(func(b) -> bool: return b.leg < LEG_AFTER_K1):
		await t.tree.physics_frame
		frames += 1
	for i in LATE.size():
		var bot = bots[i]
		var cells: Array = []
		for leg_name: String in TURNS:
			var up: bool = bot.lines.get(leg_name, false)
			if LATE[i][2] < 0:
				# De bounce te laat, zonder dash: moet de weg omhoog halen.
				t.check(up, "D=%d %s: %s niet via de echo omhoog (L-08 (b))" % [d, LATE[i][0], leg_name])
			cells.append("%s %s bounce %d landing %d" % [leg_name, "omhoog" if up else "langzame lijn",
				int(bot.bounce_from_wall.get(leg_name, -1)), int(bot.landed_from_wall.get(leg_name, -1))])
		t.check(bot.leg >= LEG_AFTER_K1, "D=%d %s: K1 niet klaar (stap %d/%s)" % [d, LATE[i][0], bot.leg, bot.sub])
		t.note("D=%d late bot %s (px van de wand): %s" % [d, LATE[i][0], ", ".join(cells)])
	await _free_all(t, vps)


func test_late_bot_d90(t) -> void:
	await _late_bot(t, 90)


func test_late_bot_d120(t) -> void:
	await _late_bot(t, 120)


func test_late_bot_d180(t) -> void:
	await _late_bot(t, 180)
