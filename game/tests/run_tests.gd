extends SceneTree
## Minimale headless testrunner zonder plug-ins.
##
## Draaien (vanuit de repo-root):
##   godot --headless --path game --fixed-fps 60 -s res://tests/run_tests.gd
##
## Voert elke methode `test_*` uit in de scripts in TEST_SCRIPTS. Elke test
## krijgt een TestContext en mag `await` gebruiken. Exitcode 0 = alles groen.

const TestContext = preload("res://tests/test_context.gd")

const TEST_SCRIPTS := [
	"res://tests/test_echo.gd",
]


func _initialize() -> void:
	_run()


func _run() -> void:
	var passed := 0
	var failed := 0
	var started := Time.get_ticks_msec()
	print("Echoborn tests - Godot %s, physics %d Hz" % [
		Engine.get_version_info().string,
		Engine.physics_ticks_per_second])
	for path: String in TEST_SCRIPTS:
		var script: GDScript = load(path)
		if script == null:
			printerr("FOUT: kan %s niet laden" % path)
			failed += 1
			continue
		print("\n%s" % path)
		for method: Dictionary in script.get_script_method_list():
			var method_name: String = method["name"]
			if not method_name.begins_with("test_"):
				continue
			var suite: Object = script.new()
			var ctx := TestContext.new(self)
			await suite.call(method_name, ctx)
			await ctx.cleanup()
			if ctx.failures.is_empty():
				passed += 1
				print("  PASS %s (%d checks)" % [method_name, ctx.checks])
			else:
				failed += 1
				print("  FAIL %s" % method_name)
				for failure in ctx.failures:
					print("       - %s" % failure)
			for line in ctx.notes:
				print("       %s" % line)
	var seconds := (Time.get_ticks_msec() - started) / 1000.0
	print("\nResultaat: %d geslaagd, %d mislukt (%.2f s)" % [passed, failed, seconds])
	quit(0 if failed == 0 else 1)
