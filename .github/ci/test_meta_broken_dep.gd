extends RefCounted
## Meta-run voor de CI (#82, ontwerp.md §9 "Streng vóór de eerste test"):
## hangt af van `meta_broken_dep.gd`, dat bewust een parse-fout heeft.
## De workflow kopieert beide tijdelijk naar game/tests/ en zet dit script
## in TEST_SCRIPTS. Verwacht: de scriptcontrole vóór de eerste test meldt
## `FAIL res://tests/meta_broken_dep.gd laadt niet`. Nooit in game/ committen.

const BrokenDep = preload("res://tests/meta_broken_dep.gd")


func test_meta_broken_dependency_must_fail(t) -> void:
	t.check(BrokenDep.new().kapot() == 1, "")
