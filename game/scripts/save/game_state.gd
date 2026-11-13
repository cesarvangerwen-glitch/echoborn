extends RefCounted
## Wat er in een save staat: schema v2 (T5b, #82; ontwerp.md §7).
##
## Bron van waarheid voor voortgang. Scènes slaan zelf niets op; ze lezen en
## schrijven hier. Niet in de save: de echo-opname (vluchtig, E-01), de
## staartlengte D (per sessie, debugmenu, E-02), live posities (je laadt op
## een checkpoint) en de besturing (een apart instellingenbestand, R3).
##
## **Werkaanname** (fasekader §5): de inhoud volgt LM-12 (gdd v0.8.5 §2.12):
## `L`, levenspunten, per gemaal `G`, per wijk `s`, de vaardigheden en de
## verzamelobjecten, plus het checkpoint (E-04b, LM-08), de eenmalige
## veranderingen (vlaggen, R10, LM-13) en de speeltijd. v1 had de laatste vier
## velden van LM-12 nog niet; `SaveService` migreert v1 → v2. Een nieuw veld =
## een nieuwe versie met een migratie in `save_service.gd`.

const Tuning = preload("res://scripts/echo/tuning.gd")

## Gebied waarin het checkpoint ligt (de scène die de AreaLoader laadt).
var gebied: StringName = &""
## Checkpoint (E-04b): kamer en positie waarop P1 na laden verschijnt.
var checkpoint_kamer: StringName = &""
var checkpoint_positie := Vector2.ZERO
## Lichtmeter in LP (LM-01).
var lichtmeter := 0
## Per gemaal (LM-03, LM-06, LM-08): {id: {"vulstand": int G 0–200, "vol": bool}};
## `vol` = trap 1 vol, de waterstand `s` volgt uit de vulstand (LM-10).
## De stand van een gemaal blijft bewaard (ook bij respawn, LM-06).
var gemalen: Dictionary = {}
## Vlaggen voor alles wat eenmalig verandert: een geopende sluis, een
## eenmalige hendel (E-13), later verzameld. {naam: true}; alleen ware
## vlaggen worden bewaard.
var vlaggen: Dictionary = {}
## v2, LM-07, LM-12: de levenspunten van P1 (P2 heeft er geen, C-02), 0 tot
## `LEVENSPUNTEN_MAX`. Nieuw spel: de startwaarde (`p1_health` in
## `data/echo_v04.json`). Een save tussen de laatste treffer en de respawntick
## kan 0 hebben; bij laden geldt dan vol (er volgt toch een respawn, E-04b).
var levenspunten := start_levenspunten()
## v2, LM-10, LM-12: per wijk de waterstand `s` (0 = het hoogst, tot
## `Gemaal.MAX_TRAPPEN`). De sleutel is de id van het gemaal van de wijk (één
## gemaal per wijk, L-14; `AreaLoader.wijk_gemaal_id`), zoals in `gemalen`.
## {wijk: int}
var waterstanden: Dictionary = {}
## v2, gdd §3, LM-12: de vaardigheden die P1 (en dus P2, C-02) heeft, op hun
## id uit de gdd (`V-01` … `V-04`). {id: true}; in het bestand een gesorteerde lijst.
var vaardigheden: Dictionary = {}
## v2, WS-08, LM-11, LM-12: de opgepakte verzamelobjecten, {id: soort}; de id is
## de vlag van het object (`AreaLoader.object_flag`), de soort `lampglas` of
## `logbladzijde`. Het maximum aan levenspunten volgt eruit (`max_levenspunten`).
var verzamelobjecten: Dictionary = {}
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


## LM-07: levenspunten bij een nieuw spel (5, uit data).
static func start_levenspunten() -> int:
	return int(Tuning.combat()["p1_health"])


func set_waterstand(wijk: StringName, s: int) -> void:
	waterstanden[wijk] = s


## De waterstand van `wijk`; 0 (het hoogst) als hij nog niet in de save staat.
func waterstand(wijk: StringName) -> int:
	return int(waterstanden.get(wijk, 0))


func set_vaardigheid(id: StringName, on: bool = true) -> void:
	if on:
		vaardigheden[id] = true
	else:
		vaardigheden.erase(id)


func has_vaardigheid(id: StringName) -> bool:
	return vaardigheden.has(id)


## Een opgepakt verzamelobject (`soort`: een van `VERZAMEL_SOORTEN`).
func add_verzamelobject(id: StringName, soort: StringName) -> void:
	verzamelobjecten[id] = soort


func has_verzamelobject(id: StringName) -> bool:
	return verzamelobjecten.has(id)


## WS-08 (a): het aantal gevonden lampglazen.
func lampglazen() -> int:
	var n := 0
	for id in verzamelobjecten:
		if verzamelobjecten[id] == &"lampglas":
			n += 1
	return n


## LM-07, WS-08 (a): 5 plus 1 per lampglas, hooguit `LEVENSPUNTEN_MAX`.
func max_levenspunten() -> int:
	return mini(start_levenspunten() + lampglazen(), LEVENSPUNTEN_MAX)


## Als JSON-vriendelijke Dictionary, zonder `version` (dat zet SaveService).
func to_dict() -> Dictionary:
	var g := {}
	for id in gemalen:
		g[String(id)] = {"vulstand": int(gemalen[id]["vulstand"]), "vol": bool(gemalen[id]["vol"])}
	var v := {}
	for flag in vlaggen:
		v[String(flag)] = true
	var w := {}
	for wijk in waterstanden:
		w[String(wijk)] = int(waterstanden[wijk])
	var skills: Array[String] = []
	for id in vaardigheden:
		skills.append(String(id))
	skills.sort()
	var items := {}
	for id in verzamelobjecten:
		items[String(id)] = String(verzamelobjecten[id])
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
		"levenspunten": levenspunten,
		"waterstanden": w,
		"vaardigheden": skills,
		"verzamelobjecten": items,
	}


## Grenzen per veld (SM-punt #82): LP en speeltijd zijn hele getallen 0–2^53,
## een vulstand een heel getal 0–200 (LM-03, LM-08: `G_max = 100 × trappen`,
## hooguit 2 trappen; #83), een positie eindig. Een gemaal met één trap klemt
## een te hoge vulstand bij het laden op 100 (`Gemaal.restore_state`).
## v2: levenspunten 0–9, een waterstand 0–2 en nooit meer dan het aantal volle
## trappen van zijn gemaal, een vaardigheid `V-` + twee cijfers (eenmaal), een
## verzamelobject `lampglas` of `logbladzijde`, hooguit 4 lampglazen.
const VULSTAND_MAX := 200
## G per trap (LM-08; gelijk aan `Gemaal.MAX`).
const TRAP_G := 100
## LM-08: hooguit 2 trappen, dus waterstand 0–2 (LM-10).
const WATERSTAND_MAX := 2
## LM-07: hooguit 9 levenspunten (`PlayerActor.HEALTH_CAP`).
const LEVENSPUNTEN_MAX := 9
## WS-08 (a): één lampglas per gebied, 4 gebieden (5 + 4 = 9).
const LAMPGLAZEN_MAX := 4
## WS-08: de soorten verzamelobjecten.
const VERZAMEL_SOORTEN: Array[String] = ["lampglas", "logbladzijde"]
## Bovengrens voor hele getallen zonder eigen grens (2^53).
const WHOLE_MAX := 9007199254740992.0


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
	_need(data, "levenspunten", -1, errors)
	_need(data, "waterstanden", TYPE_DICTIONARY, errors)
	_need(data, "vaardigheden", TYPE_ARRAY, errors)
	_need(data, "verzamelobjecten", TYPE_DICTIONARY, errors)
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
	_need_whole(data["levenspunten"], "levenspunten", 0, LEVENSPUNTEN_MAX, errors)
	for wijk in data["waterstanden"]:
		var s: Variant = data["waterstanden"][wijk]
		if not _is_number(s):
			errors.append("waterstand '%s' is geen getal" % wijk)
			continue
		var before := errors.size()
		_need_whole(s, "waterstanden.%s" % wijk, 0, WATERSTAND_MAX, errors)
		var entry: Variant = data["gemalen"].get(wijk)
		if errors.size() == before and typeof(entry) == TYPE_DICTIONARY and _is_number(entry.get("vulstand")) \
				and is_finite(float(entry["vulstand"])) and float(s) > floorf(float(entry["vulstand"]) / TRAP_G):
			errors.append("waterstand '%s' = %s, maar zijn gemaal heeft maar %d volle trap(pen) (LM-10)" % [
				wijk, s, int(floorf(float(entry["vulstand"]) / TRAP_G))])
	var seen := {}
	for id in data["vaardigheden"]:
		if typeof(id) != TYPE_STRING or not _is_skill_id(id):
			errors.append("vaardigheid '%s' is geen id V-nn" % [id])
		elif seen.has(id):
			errors.append("vaardigheid '%s' staat er twee keer in" % id)
		else:
			seen[id] = true
	var glazen := 0
	for id in data["verzamelobjecten"]:
		var soort: Variant = data["verzamelobjecten"][id]
		if typeof(soort) != TYPE_STRING or not VERZAMEL_SOORTEN.has(soort):
			errors.append("verzamelobject '%s' heeft geen soort uit %s" % [id, VERZAMEL_SOORTEN])
		elif soort == "lampglas":
			glazen += 1
	if glazen > LAMPGLAZEN_MAX:
		errors.append("veld 'verzamelobjecten' heeft %d lampglazen, hooguit %d (WS-08)" % [glazen, LAMPGLAZEN_MAX])
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
	state.levenspunten = int(data["levenspunten"])
	for wijk in data["waterstanden"]:
		state.set_waterstand(StringName(wijk), int(data["waterstanden"][wijk]))
	for id in data["vaardigheden"]:
		state.set_vaardigheid(StringName(id))
	for id in data["verzamelobjecten"]:
		state.add_verzamelobject(StringName(id), StringName(data["verzamelobjecten"][id]))
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
## Zonder eigen bovengrens geldt WHOLE_MAX (2^53): tot daar is elk heel getal
## exact als float (JSON), en `int()` loopt niet over. INF en NaN vallen af.
static func _need_whole(value: Variant, key: String, low: int, high: int, errors: PackedStringArray) -> void:
	var number := float(value)
	var top := float(high) if high >= 0 else WHOLE_MAX
	if not is_finite(number) or number != floorf(number) or number < low or number > top:
		var range_text := "%d–%d" % [low, high] if high >= 0 else "%d–2^53" % low
		errors.append("veld '%s' = %s, verwacht een heel getal %s" % [key, value, range_text])


## Een vaardigheid-id uit de gdd: `V-` en twee cijfers (§3: V-01 … V-04).
static func _is_skill_id(id: String) -> bool:
	return id.length() == 4 and id.begins_with("V-") \
		and "0123456789".contains(id[2]) and "0123456789".contains(id[3])


static func _is_number(value: Variant) -> bool:
	return typeof(value) == TYPE_INT or typeof(value) == TYPE_FLOAT
