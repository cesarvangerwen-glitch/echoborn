extends RefCounted
## Meta-run voor de CI (#82, ontwerp.md §9 "Streng vóór de eerste test"):
## bewust een parse-fout, in een script waar een test van afhangt
## (`test_meta_broken_dep.gd` preloadt het). De runner moet dit vóór de
## eerste test als FAIL melden. Nooit in game/ committen.


func kapot() -> int:
	return (1 +
