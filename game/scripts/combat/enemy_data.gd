extends RefCounted
## Waarden van de vijanden en de boss van de slice, uit `res://data/vijanden/slice.csv`
## (slice-vijanden-en-boss.md v0.1.1, B-1 en B-11).
##
## Eén regel per waarde: `groep,sleutel,waarde,eenheid,bron`. De Combat Designer past de CSV
## aan zonder code. Eén keer gelezen en daarna gedeeld; een ontbrekende sleutel is een fout.

const PATH := "res://data/vijanden/slice.csv"
const Tuning = preload("res://scripts/echo/tuning.gd")

static var _data: Dictionary = {}


## Alle groepen: {groep: {sleutel: float}}.
static func groups() -> Dictionary:
	if _data.is_empty():
		_data = parse(PATH)
	return _data


## Leest een CSV in het formaat hierboven. Regels die met `#` beginnen of leeg zijn, tellen niet.
static func parse(path: String) -> Dictionary:
	var result := {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("EnemyData: %s ontbreekt" % path)
		return result
	var header := file.get_csv_line()
	if header.size() < 3 or header[0] != "groep" or header[1] != "sleutel" or header[2] != "waarde":
		push_error("EnemyData: kop van %s is geen groep,sleutel,waarde,..." % path)
		return result
	while not file.eof_reached():
		var row := file.get_csv_line()
		if row.size() == 0 or row[0].strip_edges() == "" or row[0].begins_with("#"):
			continue
		if row.size() < 3 or not row[2].strip_edges().is_valid_float():
			push_error("EnemyData: ongeldige regel in %s: %s" % [path, ",".join(row)])
			continue
		var group := row[0].strip_edges()
		if not result.has(group):
			result[group] = {}
		result[group][row[1].strip_edges()] = row[2].strip_edges().to_float()
	return result


## Eén groep (bv. `kadeloper`).
static func group(name: String) -> Dictionary:
	var all := groups()
	if not all.has(name):
		push_error("EnemyData: groep '%s' ontbreekt in %s" % [name, PATH])
		return {}
	return all[name]


static func value(group_name: String, key: String) -> float:
	var g := group(group_name)
	if not g.has(key):
		push_error("EnemyData: '%s.%s' ontbreekt in %s" % [group_name, key, PATH])
		return 0.0
	return float(g[key])


static func ticks(group_name: String, key: String) -> int:
	return int(round(value(group_name, key)))


## VJ-03: `v(D) = min(v_max; 44 / (D − 27))`, nooit boven `v_grens` (0,70). In een verlichte
## wijk ×0,5 (VJ-06). `type_group` is `kadeloper`, `schotdrager` of `dwaallicht`.
static func speed(type_group: String, tail_ticks: int, lit := false) -> float:
	var denominator := float(tail_ticks) - value("gedeeld", "v_aftrek")
	var v := value(type_group, "v_max")
	if denominator > 0.0:
		v = minf(v, value("gedeeld", "v_teller") / denominator)
	v = minf(v, value("gedeeld", "v_grens"))
	if lit:
		v *= value("gedeeld", "verlicht_snelheid")
	return v


## VJ-01 en VJ-06: de aanloop van een aanval, +10 in een verlichte wijk.
static func windup(type_group: String, lit := false) -> int:
	return ticks(type_group, "aanloop") + (ticks("gedeeld", "verlicht_aanloop_extra") if lit else 0)


## D van de sessie zonder Combat: de standaard uit `echo_v04.json`.
static func default_tail() -> int:
	return int(Tuning.echo()["tail_ticks"])
