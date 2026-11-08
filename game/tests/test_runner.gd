extends RefCounted
## Tests voor de testrunner zelf (#30): wanneer is een test FAIL?
##
## Een echte crashende test kan hier niet staan: die maakt de suite rood.
## Daarom testen we het oordeel (`TestContext.verdict`) met nagemaakte
## uitkomsten. Een echte crash is aangetoond met een tijdelijke test (zie #30).

const TestContext = preload("res://tests/test_context.gd")


func _fresh(t) -> TestContext:
	return TestContext.new(t.tree)


func test_zero_checks_is_fail(t) -> void:
	var ctx := _fresh(t)
	t.check(ctx.verdict([], true).size() == 1, "0 checks moet precies één reden geven")


func test_script_error_is_fail_even_with_passing_checks(t) -> void:
	var ctx := _fresh(t)
	ctx.check(true, "")
	var reasons := ctx.verdict(["Invalid call (res://x.gd:3, f)"], true)
	t.check(reasons.size() == 1, "scriptfout moet FAIL geven, kreeg %s" % str(reasons))


func test_crash_before_first_check_gives_only_the_error(t) -> void:
	var ctx := _fresh(t)
	var reasons := ctx.verdict(["Invalid call (res://x.gd:3, f)"], true)
	t.check(reasons.size() == 1 and reasons[0].contains("Invalid call"),
		"alleen de foutregel verwacht, kreeg %s" % str(reasons))


func test_unfinished_test_is_fail(t) -> void:
	var ctx := _fresh(t)
	ctx.check(true, "")
	t.check(ctx.verdict([], false).size() == 1, "niet afgeronde test moet FAIL geven")


func test_clean_test_with_checks_is_pass(t) -> void:
	var ctx := _fresh(t)
	ctx.check(true, "")
	t.check(ctx.verdict([], true).is_empty(), "test met geslaagde check en geen fouten moet PASS zijn")


func test_failed_check_is_reported(t) -> void:
	var ctx := _fresh(t)
	ctx.check(false, "x klopt niet")
	var reasons := ctx.verdict([], true)
	t.check(reasons.size() == 1 and reasons[0] == "x klopt niet", "mislukte check: %s" % str(reasons))
