extends Node
## `SimSfx`: start een SFX op een tick van de Sim (audio bible §10), als
## `AudioStreamPlayer2D` op een plek in de wereld, met een vast aantal stemmen.
##
## Basis voor de koppeling van de slice-audio (T8d, `slice-audio.md` §7; later
## ook `MerkAudio`): een luisteraar (bv. `pompslag_audio.gd`) hangt aan een
## signaal van de Sim of een Sim-object en roept daar `play_on_tick` aan. Zo
## start het geluid op het event van de Sim (`_physics_process`), nooit vanuit
## `_process` of een animatie.
##
## **Determinisme.** Audio leest alleen de argumenten van het signaal en de
## plek van een node; hij schrijft nooit naar de Sim, gebruikt geen toeval en
## geen tijd van de klok. Headless (tests, bots; Dummy-driver) speelt hij
## gewoon mee; buiten de boom slaat hij alleen het afspelen over.
##
## **Stemmen.** `max_voices` spelers, om de beurt gebruikt: een nieuw geluid
## neemt de speler die het langst geleden startte (de oudste valt weg, bible
## §8.3).
##
## **Log.** `starts` houdt de laatste `MAX_LOG` starts bij (tick, stream, bus,
## send, volume, pitch, beginpunt, wie, plek, of het in een physics-frame
## was), voor tests en later de meetlog. Alleen audio, nooit Sim-stand.

const AudioBuses = preload("res://scripts/audio/audio_buses.gd")

## Waarden van de audio (designers en de Audio Director tunen zonder code).
const DATA_PATH := "res://data/audio.json"
const MAX_LOG := 64

static var _data: Dictionary = {}

## Zoveel geluiden tegelijk van deze bron.
@export var max_voices := 3
## De laatste starts (zie boven), oudste eerst.
var starts: Array[Dictionary] = []

var _voices: Array[AudioStreamPlayer2D] = []
var _next := 0


## De groep `section` uit `data/audio.json`.
static func config(section: String) -> Dictionary:
	if _data.is_empty():
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(DATA_PATH))
		if typeof(parsed) != TYPE_DICTIONARY:
			push_error("SimSfx: %s ontbreekt of is geen geldige JSON" % DATA_PATH)
			return {}
		_data = parsed
	if not _data.has(section):
		push_error("SimSfx: groep '%s' ontbreekt in %s" % [section, DATA_PATH])
		return {}
	return _data[section]


## Het geluid op `path` (uit de resource-cache van Godot: zolang iemand het
## vasthoudt, is het hetzelfde object). Leeg pad of nog geen bestand: null,
## zonder fout (het geluid volgt later, de koppeling staat al). Een luisteraar
## laadt zijn geluid één keer en houdt het vast; geen statische cache, die
## zou bij het afsluiten als lek tellen.
static func stream(path: String) -> AudioStream:
	if path == "" or not ResourceLoader.exists(path):
		return null
	return load(path) as AudioStream


## De plek van `node` in de wereld (buiten de boom: zijn eigen `position`).
static func place_of(node: Node2D) -> Vector2:
	if node == null:
		return Vector2.ZERO
	return node.global_position if node.is_inside_tree() else node.position


## `2^(halftonen / 12)`.
static func pitch_for(semitones: float) -> float:
	return pow(2.0, semitones / 12.0)


## Start `sfx` op Sim-tick `tick` op plek `at`. Geeft de speler, of null
## zonder geluid (`sfx` null). `from` is het beginpunt in seconden.
func play_on_tick(tick: int, sfx: AudioStream, at: Vector2, bus: StringName,
		volume_db: float, pitch: float, who: String, from := 0.0) -> AudioStreamPlayer2D:
	if sfx == null:
		return null
	AudioBuses.ensure()
	var player := _voice()
	player.stop()
	player.stream = sfx
	player.bus = bus
	player.volume_db = volume_db
	player.pitch_scale = pitch
	# De ouder (`SimSfx`) is geen CanvasItem: `position` is de plek in de wereld.
	player.position = at
	if player.is_inside_tree():
		player.play(from)
	starts.append({"tick": tick, "stream": player.stream, "bus": player.bus,
		"send": AudioBuses.send_of(player.bus), "area_mask": player.area_mask,
		"volume_db": player.volume_db, "pitch": player.pitch_scale, "from": from,
		"who": who, "at": at, "physics": Engine.is_in_physics_frame(), "player": player})
	if starts.size() > MAX_LOG:
		starts.pop_front()
	return player


## De speler die het langst geleden startte (of een nieuwe, tot `max_voices`).
func _voice() -> AudioStreamPlayer2D:
	if _voices.size() < maxi(max_voices, 1):
		var player := AudioStreamPlayer2D.new()
		player.name = "Stem%d" % (_voices.size() + 1)
		add_child(player)
		_voices.append(player)
		return player
	var oldest := _voices[_next]
	_next = (_next + 1) % _voices.size()
	return oldest
