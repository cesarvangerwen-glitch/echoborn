extends Logger
## Vangt fouten van de engine en van scripts op, zodat de testrunner een test
## die crasht (SCRIPT ERROR) of een enginefout geeft als FAIL kan melden.
##
## Nodig omdat GDScript bij een runtimefout de functie stopt en de aanroeper
## gewoon laat doorlopen: zonder deze logger leek zo'n test geslaagd (#30).
## `Logger` en `OS.add_logger()` bestaan sinds Godot 4.5.

var _mutex := Mutex.new()
var _errors: PackedStringArray = []


## Engine-callback, kan vanuit elke thread komen.
func _log_error(function: String, file: String, line: int, code: String,
		rationale: String, _editor_notify: bool, error_type: int,
		_script_backtraces: Array[ScriptBacktrace]) -> void:
	if error_type == ERROR_TYPE_WARNING:
		return
	var text := rationale if rationale != "" else code
	_mutex.lock()
	_errors.append("%s (%s:%d, %s)" % [text, file, line, function])
	_mutex.unlock()


func _log_message(_message: String, _error: bool) -> void:
	pass


## Aantal fouten tot nu toe; gebruik als startpunt voor `errors_since()`.
func count() -> int:
	_mutex.lock()
	var n := _errors.size()
	_mutex.unlock()
	return n


## Alle fouten die gelogd zijn sinds `start` (een eerdere `count()`).
func errors_since(start: int) -> PackedStringArray:
	_mutex.lock()
	var result := _errors.slice(start)
	_mutex.unlock()
	return result
