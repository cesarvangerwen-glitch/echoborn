extends SceneTree
## Minimale headless testrunner zonder plug-ins.
##
## Draaien (vanuit de repo-root):
##   godot --headless --path game --fixed-fps 60 -s res://tests/run_tests.gd
##
## Voert elke methode `test_*` uit in de scripts in TEST_SCRIPTS. Elke test
## krijgt een TestContext en mag `await` gebruiken. Exitcode 0 = alles groen.
##
## Een test is FAIL bij een mislukte check, maar ook bij 0 checks, bij een
## scriptfout of enginefout tijdens de test, en als hij niet binnen
## MAX_FRAMES_PER_TEST frames klaar is (#30). Een testscript dat niet laadt of
## geen `test_*`-methoden heeft, telt ook als mislukt.
##
## Streng vóór de eerste test (#82): eerst laadt de runner elk `.gd`-bestand
## onder SCAN_DIRS en controleert hij de autoloads. Een scriptfout in een
## script waar een test van afhangt, maakt de suite zo altijd rood, ook als
## de fout al bij het laden valt. Daarom preloadt de runner zelf alleen
## `error_log.gd` (zonder afhankelijkheden): faalt een preload van de runner,
## dan start Godot hem niet en is de exitcode 0. Een fout buiten een test
## (bij het laden, tussen twee tests, na de laatste) telt ook als mislukt.

const ErrorLog = preload("res://tests/error_log.gd")
## Mappen waarvan elk script moet laden (recursief, gesorteerd).
const SCAN_DIRS := ["res://scripts", "res://scenes", "res://prototypes", "res://tests"]

const TEST_SCRIPTS := [
	"res://tests/test_runner.gd",
	"res://tests/test_echo.gd",
	"res://tests/test_sim.gd",
	"res://tests/test_input.gd",
	"res://tests/test_input_router.gd",
	"res://tests/test_events.gd",
	"res://tests/test_objects.gd",
	"res://tests/test_motor.gd",
	"res://tests/test_echo_v04.gd",
	"res://tests/test_combat.gd",
	"res://tests/test_meetlog.gd",
	"res://tests/test_coop.gd",
	"res://tests/test_coop_deel2.gd",
	"res://tests/test_area_loader.gd",
	"res://tests/test_lm13.gd",
	"res://tests/test_save.gd",
	"res://tests/test_flowkamer.gd",
	"res://tests/test_regels_na_f0.gd",
	"res://tests/test_flowkamer_na_f0.gd",
	"res://tests/test_wachtbot.gd",
	"res://tests/test_flowtest_t17.gd",
	"res://tests/test_localization.gd",
	"res://tests/test_save_slots.gd",
	"res://tests/test_save_gemaal.gd",
	"res://tests/test_flowtest_duo.gd",
	"res://tests/test_deck_settings.gd",
	"res://tests/test_respawn.gd",
	"res://tests/test_vijanden.gd",
	"res://tests/test_boss.gd",
	"res://tests/test_boss_rad.gd",
	"res://tests/test_boss_runs.gd",
]

## 2 minuten speltijd bij 60 Hz. De langste test duurt ±3000 ticks (C-01).
const MAX_FRAMES_PER_TEST := 7200
## Een testscript mag voor een test die langer duurt (een scripted boss-run, T8b B-9) een eigen
## grens zetten: `const MAX_FRAMES := {"test_naam": frames}`. Nooit boven deze bovengrens
## (10 minuten speltijd); een test die zijn grens haalt, is FAIL zoals hierboven.
const MAX_FRAMES_CAP := 36000

var _errors := ErrorLog.new()
## test_context.gd, pas geladen als de logger aan staat.
var _context_script: GDScript
## Tot hier zijn de gelogde fouten al aan een test of controle toegewezen.
var _seen_errors := 0
var _passed := 0
var _failed := 0


func _initialize() -> void:
	OS.add_logger(_errors)
	_run()


func _run() -> void:
	var started := Time.get_ticks_msec()
	print("Polderlight tests - Godot %s, physics %d Hz" % [
		Engine.get_version_info().string,
		Engine.physics_ticks_per_second])
	_check_scripts_and_autoloads()
	_context_script = load("res://tests/test_context.gd")
	if _context_script == null or not _context_script.can_instantiate():
		_failed += 1
		print("\nFAIL test_context.gd laadt niet; geen tests gedraaid")
		_finish(started)
		return
	for path: String in TEST_SCRIPTS:
		print("\n%s" % path)
		_check_errors_outside_tests("vóór %s" % path.get_file())
		var script: GDScript = load(path)
		var load_errors := _take_errors()
		if script == null or not script.can_instantiate() or not load_errors.is_empty():
			_failed += 1
			print("  FAIL script laadt niet")
			for error in load_errors:
				print("       - %s" % error)
			continue
		var tests_in_script := 0
		for method: Dictionary in script.get_script_method_list():
			var method_name: String = method["name"]
			if not method_name.begins_with("test_"):
				continue
			tests_in_script += 1
			_check_errors_outside_tests("vóór %s" % method_name)
			var reasons: PackedStringArray = await _run_one(script, method_name, _frame_limit(script, method_name))
			if reasons.is_empty():
				_passed += 1
			else:
				_failed += 1
		if tests_in_script == 0:
			_failed += 1
			print("  FAIL geen test_*-methoden gevonden")
	await process_frame
	_check_errors_outside_tests("na de laatste test")
	_finish(started)


func _finish(started: int) -> void:
	var seconds := (Time.get_ticks_msec() - started) / 1000.0
	print("\nResultaat: %d geslaagd, %d mislukt (%.2f s)" % [_passed, _failed, seconds])
	OS.remove_logger(_errors)
	quit(0 if _failed == 0 else 1)


## Laadt elk script onder SCAN_DIRS en controleert of elke autoload uit
## project.godot als node met een script bestaat. Elke fout telt als FAIL.
func _check_scripts_and_autoloads() -> void:
	var paths := PackedStringArray()
	for dir: String in SCAN_DIRS:
		_collect_scripts(dir, paths)
	print("\nscripts en autoloads (%d scripts)" % paths.size())
	var failed_before := _failed
	# Fouten van vóór de logger (bv. een autoload die niet compileert) zien
	# we niet; de autoload-controle hieronder vangt die wel.
	for path in paths:
		var script: GDScript = load(path)
		var errors := _take_errors()
		if script == null or not script.can_instantiate() or not errors.is_empty():
			_failed += 1
			print("  FAIL %s laadt niet" % path)
			for error in errors:
				print("       - %s" % error)
	for property: Dictionary in ProjectSettings.get_property_list():
		var key: String = property["name"]
		if not key.begins_with("autoload/"):
			continue
		var autoload_name := key.trim_prefix("autoload/")
		var node := root.get_node_or_null(NodePath(autoload_name))
		if node == null or node.get_script() == null:
			_failed += 1
			print("  FAIL autoload %s bestaat niet of heeft geen script" % autoload_name)
	if _failed == failed_before:
		print("  PASS alle scripts en autoloads laden")


func _collect_scripts(dir_path: String, into: PackedStringArray) -> void:
	var dir := DirAccess.open(dir_path)
	if dir == null:
		return
	var files := dir.get_files()
	files.sort()
	for file in files:
		if file.ends_with(".gd"):
			into.append(dir_path.path_join(file))
	var dirs := dir.get_directories()
	dirs.sort()
	for sub in dirs:
		_collect_scripts(dir_path.path_join(sub), into)


## Fouten die sinds de vorige toewijzing gelogd zijn, en markeert ze als gezien.
func _take_errors() -> PackedStringArray:
	var errors := _errors.errors_since(_seen_errors)
	_seen_errors += errors.size()
	return errors


## Fouten buiten een test (bv. in een signaal of `queue_free` na afloop van
## de vorige test) tellen als één FAIL per plek.
func _check_errors_outside_tests(where: String) -> void:
	var errors := _take_errors()
	if errors.is_empty():
		return
	_failed += 1
	print("  FAIL fout buiten een test (%s)" % where)
	for error in errors:
		print("       - %s" % error)


## De framegrens van een test: `MAX_FRAMES[naam]` uit het script (hooguit MAX_FRAMES_CAP), anders
## MAX_FRAMES_PER_TEST.
func _frame_limit(script: GDScript, method_name: String) -> int:
	var limits: Variant = script.get_script_constant_map().get("MAX_FRAMES", {})
	if limits is Dictionary and (limits as Dictionary).has(method_name):
		return clampi(int(limits[method_name]), 1, MAX_FRAMES_CAP)
	return MAX_FRAMES_PER_TEST


## Draait één test en print het resultaat. Geeft de redenen voor FAIL terug.
func _run_one(script: GDScript, method_name: String, max_frames := MAX_FRAMES_PER_TEST) -> PackedStringArray:
	var suite: Object = script.new()
	var ctx: RefCounted = _context_script.new(self)
	var state := {"done": false}
	_call_test(suite, method_name, ctx, state)
	var frames := 0
	while not state["done"] and frames < max_frames:
		await process_frame
		frames += 1
	await ctx.cleanup()
	var reasons: PackedStringArray = ctx.verdict(_take_errors(), state["done"])
	if reasons.is_empty():
		print("  PASS %s (%d checks)" % [method_name, ctx.checks])
	else:
		print("  FAIL %s (%d checks)" % [method_name, ctx.checks])
		for reason in reasons:
			print("       - %s" % reason)
	for line in ctx.notes:
		print("       %s" % line)
	return reasons


## Een scriptfout stopt alleen de testmethode; deze coroutine loopt daarna
## door en zet `done`. Een test die blijft hangen, zet `done` nooit.
func _call_test(suite: Object, method_name: String, ctx: RefCounted, state: Dictionary) -> void:
	await suite.call(method_name, ctx)
	state["done"] = true
