extends RefCounted
## Tests voor de MT2-voorwaarden van de Tools Programmer (#250,
## `docs/qa/testplan-mt2.md` §2.1; handleiding `docs/tools/kadewijk-meetlog.md`):
##
## - V-5: de start voor de CEO verandert de MT1-start niet (de hoofdscène blijft
##   de flow-kamer); de Kadewijk start op D = 60 uit data met de echo aan, en
##   schrijft de CSV alleen als hij zelf de `current_scene` is (niet in tests).
## - V-6: de CSV na een korte bot-run (S1 → S2): de naam, de kolommen, gelijk
##   aan het meetlog; bij afbreken (een D-toets, het venster dicht) `_afgebroken`.
## - V-7: F8, de D-toetsen en F4 geven een regel `DEBUG`.
##
## De CSV's gaan naar een eigen map (`DIR`), die de test daarna leegmaakt.

const Scene := preload("res://levels/kadewijk/kadewijk.tscn")
const Kadewijk = preload("res://levels/kadewijk/kadewijk.gd")
const Bot = preload("res://levels/kadewijk/kadewijk_bot.gd")
const Layout = preload("res://levels/kadewijk/kadewijk_layout.gd")
const MeetlogCsv = preload("res://levels/kadewijk/kadewijk_meetlog_csv.gd")
const Meetlog = preload("res://scripts/events/meetlog.gd")
const Progress = preload("res://scripts/save/progress.gd")
const ScriptedInput = preload("res://scripts/input/scripted_input.gd")
const Tuning = preload("res://scripts/echo/tuning.gd")

const DIR := "user://test_kadewijk_meetlog"
const MT1_MAIN_SCENE := "res://levels/flowkamer/flowkamer.tscn"
const NAME_RE := "^meetlog_\\d{8}-\\d{6}_kadewijk_solo_D60_p1%s\\.csv$"


func _wijk(t, save_csv: int, input: RefCounted = null, run_end: StringName = &"S4") -> Array:
	_clear_dir()
	var progress := Progress.new()
	progress.name = "TestProgress"
	t.tree.root.add_child(progress)
	var wijk = Scene.instantiate()
	wijk.tail = 60
	wijk.show_hud = false
	wijk.progress = progress
	wijk.save_csv = save_csv
	wijk.log_dir = DIR
	wijk.run_end = run_end
	wijk.input_override = input if input != null else Bot.new(wijk, 60, &"S1")
	t.tree.root.add_child(wijk)
	return [wijk, progress]


func _free(t, parts: Array) -> void:
	for node in parts:
		node.queue_free()
	await t.tree.process_frame
	_clear_dir()
	DirAccess.remove_absolute(DIR)


func _files() -> PackedStringArray:
	var dir := DirAccess.open(DIR)
	return dir.get_files() if dir else PackedStringArray()


func _clear_dir() -> void:
	DirAccess.make_dir_recursive_absolute(DIR)
	for f in _files():
		DirAccess.remove_absolute(DIR.path_join(f))


func _rows_with(wijk, event: String) -> Array:
	var out: Array = []
	for row in wijk.meetlog.rows:
		if row[2] == event:
			out.append(row)
	return out


func _key(code: int) -> InputEventKey:
	var ev := InputEventKey.new()
	ev.physical_keycode = code
	ev.pressed = true
	return ev


# --- V-5: de start ------------------------------------------------------------

## MT1 wacht nog op de CEO: F5 in de editor start nog steeds de flow-kamer.
func test_mt1_start_ongewijzigd(t) -> void:
	var main := str(ProjectSettings.get_setting("application/run/main_scene"))
	t.check(main == MT1_MAIN_SCENE, "hoofdscène %s (MT1: %s)" % [main, MT1_MAIN_SCENE])
	var scene: PackedScene = load(MT1_MAIN_SCENE)
	var state := scene.get_state()
	var script_path := ""
	for i in state.get_node_property_count(0):
		if state.get_node_property_name(0, i) == &"script":
			script_path = (state.get_node_property_value(0, i) as Script).resource_path
	t.check(script_path == "res://levels/flowkamer/flow_room.gd", "flow-kamer met script %s" % script_path)


## Zonder eigen D en echo-keuze (zoals bij de start voor de CEO): D = 60 uit
## data, de echo aan. In een test is de wijk niet de `current_scene`: geen CSV.
func test_start_d60_echo_aan_geen_csv_in_tests(t) -> void:
	var data_d := int(Tuning.echo()["tail_ticks"])
	t.check(data_d == 60, "standaard-D in data %d (60)" % data_d)
	t.check(Kadewijk.chosen_tail == data_d, "debugmenu start op D = %d (data %d)" % [Kadewijk.chosen_tail, data_d])
	var parts := _wijk(t, -1, ScriptedInput.new([]))
	var wijk = parts[0]
	await t.tree.physics_frame
	t.check(wijk.tail == 60 and wijk.echo != null, "D %d, echo %s" % [wijk.tail, wijk.echo])
	t.check(t.tree.current_scene != wijk and wijk.meetlog_csv == null, "CSV-schrijver aan in een test")
	await _free(t, parts)


# --- V-6: de CSV --------------------------------------------------------------

## Een korte bot-run S1 → S2 (`run_end` = S2): bij `RUN_EIND` staat er één CSV
## met de naam van V-6, de kop van het meetlog, 7 kolommen per regel, en
## dezelfde inhoud als het meetlog in het geheugen, met precies één `RUN_EIND`.
func test_csv_na_korte_bot_run(t) -> void:
	var parts := _wijk(t, 1, null, &"S2")
	var wijk = parts[0]
	while not wijk.run_over and wijk.sim.tick < 3000:
		await t.tree.physics_frame
	t.check(wijk.run_over, "RUN_EIND niet gehaald (tick %d, kamer %s)" % [wijk.sim.tick, wijk.room])
	var files := _files()
	t.check(files.size() == 1, "CSV's: %s" % [files])
	if files.size() == 1:
		var re := RegEx.create_from_string(NAME_RE % "")
		t.check(re.search(files[0]) != null, "naam %s" % files[0])
		t.check(DIR.path_join(files[0]) == wijk.meetlog_csv.csv_path, "pad %s" % wijk.meetlog_csv.csv_path)
		var text := FileAccess.get_file_as_string(DIR.path_join(files[0]))
		t.check(text == wijk.meetlog.to_csv(), "CSV wijkt af van het meetlog")
		var lines := text.strip_edges().split("\n")
		t.check(lines[0] == Meetlog.HEADER, "kop %s" % lines[0])
		var bad := 0
		for line in lines:
			if line.split(",").size() != 7:
				bad += 1
		t.check(bad == 0, "%d regels zonder 7 kolommen" % bad)
		t.check(lines[1].split(",")[2] == "RUN_START" and lines[1].split(",")[1] == "S1", "eerste regel %s" % lines[1])
		t.check(text.contains(",S2,KAMER,,S2,"), "geen KAMER S2")
		t.check(lines[lines.size() - 1].split(",")[2] == "RUN_EIND", "laatste regel %s" % lines[lines.size() - 1])
		var run_eind := 0
		for line in lines:
			if line.split(",")[2] == "RUN_EIND":
				run_eind += 1
		t.check(run_eind == 1, "%d regels RUN_EIND in de CSV (verwacht 1)" % run_eind)
		t.check(not text.contains("DEBUG"), "DEBUG in een run zonder debugtoets")
	await _free(t, parts)


## Venster dicht vóór `RUN_EIND`: het log sluit en staat er als `_afgebroken`.
func test_csv_afgebroken_bij_venster_dicht(t) -> void:
	var parts := _wijk(t, 1, ScriptedInput.new([]))
	var wijk = parts[0]
	for i in 10:
		await t.tree.physics_frame
	t.check(_files().is_empty(), "CSV vóór het afbreken: %s" % [_files()])
	wijk.meetlog_csv._notification(Node.NOTIFICATION_WM_CLOSE_REQUEST)
	var files := _files()
	t.check(files.size() == 1 and RegEx.create_from_string(NAME_RE % "_afgebroken").search(files[0]) != null,
		"afgebroken CSV's: %s" % [files])
	t.check(wijk.meetlog.is_closed() and wijk.meetlog.count("RUN_EIND") == 1, "log niet gesloten met RUN_EIND")
	# Nog eens (F6 na het sluiten): geen tweede bestand.
	wijk.debug_key(KEY_F6)
	t.check(_files().size() == 1, "tweede CSV na F6: %s" % [_files()])
	await _free(t, parts)


# --- V-7: DEBUG ---------------------------------------------------------------

## F8 (via het debugmenu): een regel `DEBUG` met de toets en de kamer waar P1
## heen springt; P1 staat daarna in die kamer. Zonder CSV-schrijver geen bestand.
func test_debug_regel_f8(t) -> void:
	var parts := _wijk(t, 0, ScriptedInput.new([]))
	var wijk = parts[0]
	for i in 5:
		await t.tree.physics_frame
	wijk._unhandled_input(_key(KEY_F8))
	var rows := _rows_with(wijk, "DEBUG")
	t.check(rows.size() == 1, "DEBUG-regels: %s" % [rows])
	if rows.size() == 1:
		t.check(rows[0][3] == "F8" and rows[0][4] == "S2" and rows[0][1] == "S1", "regel %s" % [rows[0]])
	for i in 5:
		await t.tree.physics_frame
	t.check(wijk.room == &"S2", "na F8 in %s" % wijk.room)
	t.check(_files().is_empty() and wijk.meetlog_csv == null, "CSV zonder schrijver")
	await _free(t, parts)


## F4 en een D-toets: een regel `DEBUG` (bron de echo-keuze of de nieuwe D).
## Beide herladen de scène, dus met de CSV-schrijver staat de CSV er dan als
## `_afgebroken`, met de `DEBUG`-regel erin. (`debug_key` direct: het herladen
## zelf en de static keuzes van het debugmenu blijven buiten de test.)
func test_debug_regel_d_toets_en_f4(t) -> void:
	var parts := _wijk(t, 0, ScriptedInput.new([]))
	var wijk = parts[0]
	await t.tree.physics_frame
	wijk.debug_key(KEY_F4)
	var rows := _rows_with(wijk, "DEBUG")
	t.check(rows.size() == 1 and rows[0][3] == "F4" and rows[0][4] == ("echo_uit" if Kadewijk.chosen_echo_on else "echo_aan"),
		"F4: %s" % [rows])
	await _free(t, parts)
	parts = _wijk(t, 1, ScriptedInput.new([]))
	wijk = parts[0]
	for i in 5:
		await t.tree.physics_frame
	var d90 := int(Tuning.echo()["tail_options"][Kadewijk.DEBUG_TAIL_KEYS[KEY_F2]])
	wijk.debug_key(KEY_F2)
	rows = _rows_with(wijk, "DEBUG")
	t.check(rows.size() == 1 and rows[0][3] == "F2" and rows[0][4] == "D%d" % d90, "F2: %s" % [rows])
	var files := _files()
	t.check(files.size() == 1 and RegEx.create_from_string(NAME_RE % "_afgebroken").search(files[0]) != null,
		"CSV's: %s" % [files])
	if files.size() == 1:
		var text := FileAccess.get_file_as_string(DIR.path_join(files[0]))
		t.check(text.contains(",DEBUG,F2,D%d," % d90), "DEBUG F2 niet in de CSV")
	# Na het sluiten: geen DEBUG-regel meer.
	wijk.debug_key(KEY_F8)
	t.check(_rows_with(wijk, "DEBUG").size() == 1, "DEBUG in een gesloten log")
	t.check(Kadewijk.chosen_tail == 60, "debug_key veranderde de D-keuze")
	await _free(t, parts)


## Bestandsnamen (V-6): solo/coop, D, `_afgebroken`.
func test_bestandsnaam(t) -> void:
	t.check(MeetlogCsv.file_name("20261113-142501", false, 60, false) == "meetlog_20261113-142501_kadewijk_solo_D60_p1.csv", "solo")
	t.check(MeetlogCsv.file_name("20261113-142501", true, 90, true) == "meetlog_20261113-142501_kadewijk_coop_D90_p1_afgebroken.csv", "coop afgebroken")
	t.check(RegEx.create_from_string("^\\d{8}-\\d{6}$").search(MeetlogCsv.stamp_now()) != null, "stempel %s" % MeetlogCsv.stamp_now())
