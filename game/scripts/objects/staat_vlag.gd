extends "res://scripts/objects/sim_object.gd"
## Een blijvende vlag zonder vlak en zonder spelregel (R10, LM-12; #83): iets
## in een kamer dat eenmalig verandert en na laden zo moet blijven, terwijl het
## object zelf niet in de inhoud staat. Voorbeeld: `S8/BossVerslagen`, de
## Gemaalmeester is verslagen (`BOSS_VERSLAGEN`, GM-10); de boss zelf wordt in
## code neergezet en is geen object met een stand.
##
## Zo staat de vlag in de save onder dezelfde naam als elk ander object
## (`<gebied>/<kamer>/<pad>`, `AreaLoader.object_flag`) en kent
## `AreaLoader.unknown_flags` hem. Wie hem zet, is de gebiedsscène.

## Aan (true) of uit.
var aan := false


func has_persistent_state() -> bool:
	return true


func get_persistent_state() -> bool:
	return aan


func set_persistent_state(on: bool) -> void:
	aan = on
