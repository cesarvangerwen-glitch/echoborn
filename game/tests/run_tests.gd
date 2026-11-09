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

const TestContext = preload("res://tests/test_context.gd")
const ErrorLog = preload("res://tests/error_log.gd")

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
]

## 2 minuten speltijd bij 60 Hz. De langste test duurt ±3000 ticks (C-01).
const MAX_FRAMES_PER_TEST := 7200

var _errors := ErrorLog.new()


func _initialize() -> void:
	OS.add_logger(_errors)
	_run()


func _run() -> void:
	var passed := 0
	var failed := 0
	var started := Time.get_ticks_msec()
	print("Echoborn tests - Godot %s, physics %d Hz" % [
		Engine.get_version_info().string,
		Engine.physics_ticks_per_second])
	for path: String in TEST_SCRIPTS:
		print("\n%s" % path)
		var load_start := _errors.count()
		var script: GDScript = load(path)
		var load_errors := _errors.errors_since(load_start)
		if script == null or not script.can_instantiate() or not load_errors.is_empty():
			failed += 1
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
			var reasons: PackedStringArray = await _run_one(script, method_name)
			if reasons.is_empty():
				passed += 1
			else:
				failed += 1
		if tests_in_script == 0:
			failed += 1
			print("  FAIL geen test_*-methoden gevonden")
	var seconds := (Time.get_ticks_msec() - started) / 1000.0
	print("\nResultaat: %d geslaagd, %d mislukt (%.2f s)" % [passed, failed, seconds])
	OS.remove_logger(_errors)
	quit(0 if failed == 0 else 1)


## Draait één test en print het resultaat. Geeft de redenen voor FAIL terug.
func _run_one(script: GDScript, method_name: String) -> PackedStringArray:
	var error_start := _errors.count()
	var suite: Object = script.new()
	var ctx := TestContext.new(self)
	var state := {"done": false}
	_call_test(suite, method_name, ctx, state)
	var frames := 0
	while not state["done"] and frames < MAX_FRAMES_PER_TEST:
		await process_frame
		frames += 1
	await ctx.cleanup()
	var reasons := ctx.verdict(_errors.errors_since(error_start), state["done"])
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
func _call_test(suite: Object, method_name: String, ctx: TestContext, state: Dictionary) -> void:
	await suite.call(method_name, ctx)
	state["done"] = true
