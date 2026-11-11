extends SceneTree
## Rekent elke meetlog-CSV in deze map uit met `flow_report.gd` (T17, #80).
## Draaien vanuit de root van de repo:
##   godot --headless --path game -s "$PWD/docs/qa/f0-meetlogs/rekenen.gd" -- "$PWD/docs/qa/f0-meetlogs"

const FlowReport := preload("res://levels/flowkamer/flow_report.gd")


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var dir_path: String = args[0] if args.size() > 0 else "res://../docs/qa/f0-meetlogs"
	var names := Array(DirAccess.get_files_at(dir_path))
	names.sort()
	for file_name: String in names:
		if not file_name.ends_with(".csv"):
			continue
		var f := FileAccess.open(dir_path.path_join(file_name), FileAccess.READ)
		var rows: Array = []
		var scores := PackedStringArray()
		var first_full := -1
		f.get_csv_line()  # kop
		while not f.eof_reached():
			var line := f.get_csv_line()
			if line.size() < 7:
				continue
			rows.append(line)
			if line[2] == "SCORE":
				scores.append(line[3])
			if line[2] == "ECHO_LEEG_EIND" and first_full < 0:
				first_full = int(line[0])
		var r = FlowReport.from_rows(rows, true)
		var fails: PackedStringArray = r.failures()
		print("%s\n  D uit log (eerste ECHO_LEEG_EIND): %s · scores %s\n  %s\n  ✗ %s" % [file_name,
			str(first_full) if first_full >= 0 else "-", "/".join(scores) if scores.size() > 0 else "-",
			r.summary(), "; ".join(fails) if fails.size() > 0 else "geen (MP-1, -2, -4, -6 gehaald)"])
	quit()
