extends RefCounted
## Tuningwaarden van beweging en echo, gelezen uit `res://data/echo_v04.json`.
##
## Designers passen de JSON aan zonder code (gdd §2.9). Eén keer gelezen en
## daarna gedeeld; een ontbrekende sleutel is een fout, geen stille standaard.

const PATH := "res://data/echo_v04.json"

static var _data: Dictionary = {}


## De groep `movement` (gdd §2.5a, E-07a).
static func movement() -> Dictionary:
	return _section("movement")


## De groep `echo` (E-02, E-08, E-09).
static func echo() -> Dictionary:
	return _section("echo")


static func body_size() -> Vector2:
	var size: Array = movement()["body_size"]
	return Vector2(float(size[0]), float(size[1]))


static func _section(section: String) -> Dictionary:
	if _data.is_empty():
		var text := FileAccess.get_file_as_string(PATH)
		var parsed: Variant = JSON.parse_string(text)
		if typeof(parsed) != TYPE_DICTIONARY:
			push_error("Tuning: %s ontbreekt of is geen geldige JSON" % PATH)
			return {}
		_data = parsed
	if not _data.has(section):
		push_error("Tuning: groep '%s' ontbreekt in %s" % [section, PATH])
		return {}
	return _data[section]


## De groep `combat` (E-10a, E-14, E-02m, basisvijand §4.3).
static func combat() -> Dictionary:
	return _section("combat")


## De groep `coop` (C-03, C-09–C-13).
static func coop() -> Dictionary:
	return _section("coop")
