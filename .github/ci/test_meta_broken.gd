extends RefCounted
## Meta-run voor de CI (#70, ontwerp.md §9 "Schuld"): deze tests zijn
## bewust kapot. De workflow kopieert dit bestand tijdelijk naar
## game/tests/, zet het in TEST_SCRIPTS en verwacht exitcode 1 met
## beide tests als FAIL. Blijft de suite groen, dan vangt de runner
## scriptfouten of lege tests niet meer op (R18). Nooit in game/ committen.


func test_meta_script_error_must_fail(t) -> void:
	t.check(true, "")
	var leeg: Object = null
	leeg.call("bestaat_niet")


func test_meta_zero_checks_must_fail(_t) -> void:
	pass
