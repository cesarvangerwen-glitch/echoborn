extends RefCounted
## Wat er in een save staat: schema v1 (T5b, #82; ontwerp.md §7).
##
## Bron van waarheid voor voortgang. Scènes slaan zelf niets op; ze lezen en
## schrijven hier. Niet in de save: de echo-opname (vluchtig, E-01), de
## staartlengte D (per sessie, debugmenu, E-02), live posities (je laadt op
## een checkpoint) en de besturing (een apart instellingenbestand, R3).
##
## **Werkaanname** (fasekader §5): de inhoud volgt wat de flow-kamer en de
## slice nu nodig hebben (gdd §2.12 LM-01–LM-06, E-04b); vaardigheden en
## verzamelobjecten komen met T3c. Een nieuw veld = een nieuwe versie met een
## migratie in `save_service.gd`.

## Gebied waarin het checkpoint ligt (de scène die de AreaLoader laadt).
var gebied: StringName = &""
## Checkpoint (E-04b): kamer en positie waarop P1 na laden verschijnt.
var checkpoint_kamer: StringName = &""
var checkpoint_positie := Vector2.ZERO
## Lichtmeter in LP (LM-01).
var lichtmeter := 0
## Per gemaal (LM-03, LM-06): {id: {"vulstand": int G 0–100, "vol": bool}}.
## De stand van een gemaal blijft bewaard (ook bij respawn, LM-06).
var gemalen: Dictionary = {}
## Vlaggen voor alles wat eenmalig verandert: een geopende sluis, een
## eenmalige hendel (E-13), later verzameld. {naam: true}; alleen ware
## vlaggen worden bewaard.
var vlaggen: Dictionary = {}
## Gespeelde tijd in ticks (60 Hz), niet in klokuren: geen echte tijd in
## gameplaydata (ontwerp.md §2, regel 5).
var speeltijd_ticks := 0


func set_flag(flag: StringName, on: bool = true) -> void:
	if on:
		vlaggen[flag] = true
	else:
		vlaggen.erase(flag)


func has_flag(flag: StringName) -> bool:
	return vlaggen.has(flag)


func set_gemaal(id: StringName, vulstand: int, vol: bool) -> void:
	gemalen[id] = {"vulstand": vulstand, "vol": vol}


## Als JSON-vriendelijke Dictionary, zonder `version` (dat zet SaveService).
func to_dict() -> Dictionary:
	var g := {}
	for id in gemalen:
		g[String(id)] = {"vulstand": int(gemalen[id]["vulstand"]), "vol": bool(gemalen[id]["vol"])}
	var v := {}
	for flag in vlaggen:
		v[String(flag)] = true
	return {
		"gebied": String(gebied),
		"checkpoint": {
			"kamer": String(checkpoint_kamer),
			"x": checkpoint_positie.x,
			"y": checkpoint_positie.y,
		},
		"lichtmeter": lichtmeter,
		"gemalen": g,
		"vlaggen": v,
		"speeltijd_ticks": speeltijd_ticks,
	}


## Grenzen per veld (SM-punt #82): LP en speeltijd zijn hele getallen ≥ 0,
## een vulstand een heel getal 0–100 (LM-03), een positie eindig.
const VULSTAND_MAX := 100


## Leest een Dictionary van de huidige versie. Geeft null en vult `errors`
## bij een ontbrekend veld, een verkeerd type of een waarde buiten zijn
## bereik; laat niets half ingevuld.
static func from_dict(data: Dictionary, errors: PackedStringArray) -> RefCounted:
	var start := errors.size()
	var cp: Variant = data.get("checkpoint")
	_need(data, "gebied", TYPE_STRING, errors)
	_need(data, "lichtmeter", -1, errors)
	_need(data, "speeltijd_ticks", -1, errors)
	_need(data, "gemalen", TYPE_DICTIONARY, errors)
	_need(data, "vlaggen", TYPE_DICTIONARY, errors)
	if typeof(cp) != TYPE_DICTIONARY:
		errors.append("veld 'checkpoint' ontbreekt of is geen object")
	else:
		_need(cp, "kamer", TYPE_STRING, errors)
		_need(cp, "x", -1, errors)
		_need(cp, "y", -1, errors)
	if errors.size() > start:
		return null
	_need_whole(data["lichtmeter"], "lichtmeter", 0, -1, errors)
	_need_whole(data["speeltijd_ticks"], "speeltijd_ticks", 0, -1, errors)
	for axis in ["x", "y"]:
		if not is_finite(float(cp[axis])):
			errors.append("veld 'checkpoint.%s' is geen eindig getal" % axis)
	for id in data["gemalen"]:
		var entry: Variant = data["gemalen"][id]
		if typeof(entry) != TYPE_DICTIONARY or not _is_number(entry.get("vulstand")) \
				or typeof(entry.get("vol")) != TYPE_BOOL:
			errors.append("gemaal '%s' heeft geen geldige vulstand/vol" % id)
		else:
			_need_whole(entry["vulstand"], "gemalen.%s.vulstand" % id, 0, VULSTAND_MAX, errors)
	for flag in data["vlaggen"]:
		if typeof(data["vlaggen"][flag]) != TYPE_BOOL:
			errors.append("vlag '%s' is geen true/false" % flag)
	if errors.size() > start:
		return null
	var state: RefCounted = load("res://scripts/save/game_state.gd").new()
	state.gebied = StringName(data["gebied"])
	state.checkpoint_kamer = StringName(cp["kamer"])
	state.checkpoint_positie = Vector2(float(cp["x"]), float(cp["y"]))
	state.lichtmeter = int(data["lichtmeter"])
	state.speeltijd_ticks = int(data["speeltijd_ticks"])
	for id in data["gemalen"]:
		var entry: Dictionary = data["gemalen"][id]
		state.set_gemaal(StringName(id), int(entry["vulstand"]), bool(entry["vol"]))
	for flag in data["vlaggen"]:
		if data["vlaggen"][flag] == true:
			state.set_flag(StringName(flag))
	return state


## Zelfde inhoud? (voor tests en "is er iets veranderd sinds de vorige save")
func equals(other: RefCounted) -> bool:
	return other != null and to_dict() == other.to_dict()


## `type` -1 = een getal (JSON maakt van elk getal een float).
static func _need(data: Dictionary, key: String, type: int, errors: PackedStringArray) -> void:
	if not data.has(key):
		errors.append("veld '%s' ontbreekt" % key)
	elif type == -1 and not _is_number(data[key]):
		errors.append("veld '%s' is geen getal" % key)
	elif type != -1 and typeof(data[key]) != type:
		errors.append("veld '%s' heeft het verkeerde type" % key)


## Een heel getal in [low, high] (high -1 = geen bovengrens).
static func _need_whole(value: Variant, key: String, low: int, high: int, errors: PackedStringArray) -> void:
	var number := float(value)
	if number != floorf(number) or number < low or (high >= 0 and number > high):
		var range_text := "%d–%d" % [low, high] if high >= 0 else "≥ %d" % low
		errors.append("veld '%s' = %s, verwacht een heel getal %s" % [key, value, range_text])


static func _is_number(value: Variant) -> bool:
	return typeof(value) == TYPE_INT or typeof(value) == TYPE_FLOAT
