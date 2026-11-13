extends Node
## Het meetlog van de Kadewijk naar schijf (MT2, testplan-mt2 §2.1 V-6 en V-7;
## #250). Handleiding: `docs/tools/kadewijk-meetlog.md`.
##
## Zelfde aanpak als de flow-kamer (`flow_room.gd`, `save_log`): het meetlog
## (`flow_meetlog.gd`, kolommen `tick, kamer, event, waarde, bron, x, y`) gaat
## als CSV naar `user://` (`%APPDATA%\godot\app_userdata\Echoborn` op
## Windows, `custom_user_dir_name` in `project.godot`):
## - bij `RUN_EIND` (`run_finished` van de wijk):
##   `meetlog_<datum-tijd>_kadewijk_<solo|coop>_D<D>_p1.csv`;
## - bij afbreken (F6 of een andere debugtoets die de scène herlaadt, of het
##   venster sluiten): hetzelfde met `_afgebroken`, na `finish()` (een open
##   stilstand en `RUN_EIND` sluiten het log, zoals in de flow-kamer).
##
## De wijk (`kadewijk.gd`) maakt deze node alleen als de CSV aan staat; de
## regel `DEBUG` (V-7) schrijft de wijk zelf, ook zonder deze node.

const FlowMeetlog = preload("res://levels/flowkamer/flow_meetlog.gd")

## Map voor de CSV.
var log_dir := "user://"
## Pad van de laatst geschreven CSV (leeg = nog niets geschreven).
var csv_path := ""

var _wijk: Node


func _init(wijk: Node, dir: String = "user://") -> void:
	name = "MeetlogCsv"
	_wijk = wijk
	log_dir = dir


func _ready() -> void:
	_wijk.run_finished.connect(func(_tick: int) -> void: save(false))


## Bestandsnaam volgens V-6, bv. `meetlog_20261113-142501_kadewijk_solo_D60_p1.csv`.
## `stamp` = `JJJJMMDD-uummss` (zoals de flow-kamer).
static func file_name(stamp: String, coop: bool, tail: int, aborted: bool) -> String:
	return "meetlog_%s_kadewijk_%s_D%d_p1%s.csv" % [stamp, "coop" if coop else "solo", tail,
		"_afgebroken" if aborted else ""]


## De tijd van nu als `JJJJMMDD-uummss`.
static func stamp_now() -> String:
	return Time.get_datetime_string_from_system(false, false).replace("-", "").replace(":", "").replace("T", "-")


## Schrijft het meetlog van de wijk. Geeft het pad terug, of "" bij een fout.
func save(aborted: bool) -> String:
	var meetlog: FlowMeetlog = _wijk.meetlog
	var coop := meetlog.count("DROP_IN") > 0
	csv_path = log_dir.path_join(file_name(stamp_now(), coop, _wijk.tail, aborted))
	var err := meetlog.save(csv_path)
	if err != OK:
		push_error("Meetlog niet opgeslagen (%s): %s" % [error_string(err), csv_path])
		return ""
	print("Meetlog opgeslagen: %s" % ProjectSettings.globalize_path(csv_path))
	return csv_path


## Afbreken (F6, een D-toets, F4, het venster dicht): sluit een open log en
## schrijft het met `_afgebroken`. Na `RUN_EIND` is er al een CSV: dan niets.
func abort() -> void:
	var meetlog: FlowMeetlog = _wijk.meetlog
	if meetlog == null or meetlog.is_closed():
		return
	meetlog.finish()
	save(true)


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		abort()
