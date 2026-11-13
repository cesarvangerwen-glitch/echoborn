extends RefCounted
## Het beeld van de Gemaalmeester uit de sprites van de Animator (Technical
## Artist, #265; overdracht `docs/art/animatie-timing.md` §1.6, manifest
## `gemaalmeester.json`, `koppeling`). Vervangt de placeholder-polygons.
##
## Alleen beeld: dit leest de vlaggen en signalen van `boss.gd` en
## `gemaalmeester.gd` en verandert niets aan de Sim (de ticks van een
## boss-run blijven gelijk). Elke tick kiest `update(tick)` per laag de
## animatie en het frame, uit de tick en de vlaggen (geen eigen klok):
##
## - `LichaamBeeld` (z −2): idle; bij een aanval de aanloop op
##   `windup_progress`, frame 0–3 op kwarten van (aanloop − 3) en frame 4 (de
##   uithaal) op de laatste 3 ticks; de allereerste aanloop (60) begint met de
##   aarzeling (20); het actieve vlak = het verste frame; herstel; na de
##   pompslag `pomp_terug`. Fasewissel, wankel, geraakt, oplossen.
## - `KetelBeeld` (z −1): schot (tink), breuk → kern (kern_geraakt),
##   schot_sluit, in fase 2 schot_dicht, bij Wankel merkplek_open → merkplek.
## - `RadBeeld` (z −3): in fase 1 op de rug van het lichaam (middle(), 120),
##   draai_s0 frame 0; hangt: draai (8 ticks), trilt (de frames schuiven zelf),
##   draait en fasewissel: draai met `ticks_draaien` (3); treffer na `rad_hit`.
##   Scheur `s0` tot de UX Designer beslist (combat §9.2).
## - `Tell` (z 0) en `Effect` (z 1) op `attack_box`: tell vroeg / laat / actief
##   op `windup_progress` en `is_attack_active()`; het effect pompslag of zwiep.
## - `Spuigat_links/_rechts` (z −1): gloei zolang `spout_glowing`, dan stoom.
## In het gevecht de grijze bestanden (`staat`, s = 1).

const Sprite = preload("res://art/animatie/gemaalmeester/gemaalmeester_sprite.gd")
const EnemyData = preload("res://scripts/combat/enemy_data.gd")

const DIR := "res://art/animatie/gemaalmeester/"
const MANIFEST := DIR + "gemaalmeester.json"
## Laatste ticks van de aanloop met de uithaal (frame 4).
const UITHAAL := 3
## Scheur van het rad tot het besluit van de UX Designer.
const SCHEUR := 0

var boss: Node2D
var staat := "grijs"
var manifest: Dictionary = {}
var sprites := {}
var _tex := {}

var _aanval := -1
var _aanval_kind := ""
var _aanval_kant := 0
var _vorige_fase := 0
var _terug := -1
var _terug_kant := 0
var _wissel := -1
var _wankel := -1
var _geraakt := -1
var _breuk := -1
var _kern_geraakt := -1
var _sluit := -1
var _gloei := -1
var _stoom := -1
var _rad_treffer := -1


static var _m: Dictionary = {}


static func lees_manifest() -> Dictionary:
	if _m.is_empty():
		var data = JSON.parse_string(FileAccess.get_file_as_string(MANIFEST))
		if data is Dictionary:
			_m = data
		else:
			push_error("GemaalmeesterBeeld: manifest %s leest niet" % MANIFEST)
	return _m


func _init(p_boss: Node2D, p_staat := "grijs") -> void:
	boss = p_boss
	staat = p_staat
	manifest = lees_manifest()
	for naam: String in ["RadBeeld", "LichaamBeeld", "KetelBeeld", "Spuigat_links", "Spuigat_rechts", "Tell", "Effect"]:
		var s := Sprite.new()
		s.name = naam
		s.centered = false
		s.region_enabled = true
		s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		s.visible = false
		boss.add_child(s)
		sprites[naam] = s
	boss.attack_started.connect(func(tick: int, kind: String, side: int) -> void:
		_aanval = tick
		_aanval_kind = kind
		_aanval_kant = side)
	boss.phase_changed.connect(func(tick: int, wat: String) -> void:
		if wat == "wissel":
			_wissel = tick
		elif wat == "wankel":
			_wankel = tick)
	boss.shot_broken.connect(func(tick: int) -> void: _breuk = tick)
	boss.core_closed.connect(func(tick: int, _reason: String) -> void: _sluit = tick)
	boss.damaged.connect(func(tick: int, amount: int, _source: String) -> void:
		if amount > 0 and boss.core_open:
			_geraakt = tick
			_kern_geraakt = tick)
	boss.finisher_strike.connect(func(tick: int, _who: String) -> void: _geraakt = tick)
	boss.rad_hit.connect(func(tick: int, _source: String, _action: String, _amount: int) -> void: _rad_treffer = tick)
	boss.boss_reset.connect(func(_tick: int) -> void: _wis())


func _wis() -> void:
	for k in ["_aanval", "_terug", "_wissel", "_wankel", "_geraakt", "_breuk", "_kern_geraakt", "_sluit", "_gloei", "_stoom", "_rad_treffer"]:
		set(k, -1)
	_vorige_fase = 0


## Wisselt de bestanden (`grijs`, `half`, `kleur`); in het gevecht `grijs`.
func set_staat(nieuw: String) -> void:
	staat = nieuw
	_tex.clear()


func blad(naam: String) -> Dictionary:
	return manifest["bladen"][naam]


## Frame van animatie `anim` na `e` ticks (lus of niet). Voorbij het einde: het laatste
## frame, of -1 met `weg_na`. `ticks` vervangt de ticks van het manifest (fase 2, draaien).
func frame_at(blad_naam: String, anim: String, e: int, weg_na := false, ticks: Array = []) -> int:
	var a: Dictionary = blad(blad_naam)["animaties"][anim]
	var t: Array = ticks if not ticks.is_empty() else a["ticks"]
	var som := 0
	for v in t:
		som += int(v)
	if a.get("lus", false):
		e = posmod(e, maxi(som, 1))
	elif e >= som:
		return -1 if weg_na else t.size() - 1
	for i in t.size():
		e -= int(t[i])
		if e < 0:
			return i
	return t.size() - 1


func _toon(naam: String, blad_naam: String, anim: String, n: int, at: Vector2) -> void:
	var s: Sprite = sprites[naam]
	s.blad = blad_naam
	s.anim = anim
	s.frame_nr = n
	s.visible = n >= 0
	if n < 0:
		return
	var b := blad(blad_naam)
	var key := blad_naam + "/" + staat
	if not _tex.has(key):
		_tex[key] = load(DIR + String(b["bestanden"][staat]))
	s.texture = _tex[key]
	s.z_index = int(b["z_index"])
	var f: Array = b["animaties"][anim]["frames"][n]
	s.region_rect = Rect2(f[0], f[1], f[2], f[3])
	s.position = at + Vector2(b["offset"][0], b["offset"][1])


func _weg(naam: String) -> void:
	_toon(naam, "", "", -1, Vector2.ZERO)


func update(tick: int) -> void:
	var fase: int = boss.attack_phase
	if _vorige_fase == boss.AttackPhase.RECOVER and fase == boss.AttackPhase.IDLE and _aanval_kind == "pomp":
		_terug = tick
		_terug_kant = _aanval_kant
	_vorige_fase = fase
	if boss.spout_glowing and _gloei < 0:
		_gloei = tick
		_stoom = -1
	elif not boss.spout_glowing and _gloei >= 0:
		_gloei = -1
		_stoom = tick
	_lichaam(tick)
	_ketel(tick)
	_rad(tick)
	_aanval_beeld(tick)
	_spuigaten(tick)


func _kant(side: int) -> String:
	return "links" if side < 0 else "rechts"


func _lichaam(tick: int) -> void:
	var anim := "idle"
	var e := tick
	var ticks: Array = []
	var weg_na := false
	if boss.is_defeated():
		anim = "oplossen"
		e = tick - boss.defeated_tick
		weg_na = true
	elif _geraakt >= 0 and tick - _geraakt < 8:
		anim = "geraakt"
		e = tick - _geraakt
	elif boss.state == boss.State.WANKEL or boss.state == boss.State.FINISHER:
		e = tick - maxi(_wankel, 0)
		anim = "wankel_in" if e < 16 else "wankel"
		e = e if e < 16 else e - 16
	elif boss.phase == boss.Phase.SWITCH:
		anim = "fasewissel"
		e = tick - _wissel
	elif boss.attack_phase != boss.AttackPhase.IDLE:
		var k := _kant(boss.attack_side)
		var soort: String = boss.attack_kind
		if boss.is_telling():
			var start := _aanval
			var totaal: int = boss.windup_end_tick() - start
			var eerste := EnemyData.ticks(boss.data_group, "eerste_aanloop")
			if soort == "pomp" and totaal == eerste and tick - start < eerste - EnemyData.ticks(boss.data_group, "pomp1_aanloop"):
				anim = "aarzeling_" + k
				e = tick - start
			else:
				if soort == "pomp" and totaal == eerste:
					start += eerste - EnemyData.ticks(boss.data_group, "pomp1_aanloop")
					totaal = boss.windup_end_tick() - start
				anim = ("pomp_aanloop_" if soort == "pomp" else "zwiep_aanloop_") + k
				_toon("LichaamBeeld", "lichaam", anim, _aanloop_frame(tick, start, totaal), Vector2.ZERO)
				return
		elif boss.is_attack_active():
			anim = ("pomp_slag_" if soort == "pomp" else "zwiep_veeg_") + k
			e = tick - boss.windup_end_tick()
		else:
			anim = ("pomp_ligt_" if soort == "pomp" else "zwiep_uit_") + k
			e = tick - boss.active_end_tick()
	elif _terug >= 0 and tick - _terug < 12:
		anim = "pomp_terug_" + _kant(_terug_kant)
		e = tick - _terug
	_toon("LichaamBeeld", "lichaam", anim, frame_at("lichaam", anim, e, weg_na, ticks), Vector2.ZERO)


## Frame 0–3 op kwarten van (aanloop − 3), frame 4 (de uithaal) op de laatste 3 ticks.
func _aanloop_frame(tick: int, start: int, totaal: int) -> int:
	if boss.windup_end_tick() - tick <= UITHAAL:
		return 4
	var e := tick - start
	return clampi(int(floor(4.0 * float(e) / float(maxi(totaal - UITHAAL, 1)))), 0, 3)


func _ketel(tick: int) -> void:
	var anim := "schot"
	var e := tick
	var weg_na := false
	if boss.is_defeated():
		anim = "oplossen"
		e = tick - boss.defeated_tick
		weg_na = true
	elif boss.state == boss.State.WANKEL or boss.state == boss.State.FINISHER:
		e = tick - maxi(_wankel, 0)
		anim = "merkplek_open" if e < 20 else "merkplek"
		e = e if e < 20 else e - 20
	elif boss.phase != boss.Phase.ONE:
		anim = "schot_dicht"
		e = 0
	elif boss.core_open:
		if _breuk >= 0 and tick - _breuk < 12:
			anim = "breuk"
			e = tick - _breuk
		elif _kern_geraakt >= 0 and tick - _kern_geraakt < 6:
			anim = "kern_geraakt"
			e = tick - _kern_geraakt
		else:
			anim = "kern"
	elif _sluit >= 0 and tick - _sluit < 20:
		anim = "schot_sluit"
		e = tick - _sluit
	elif tick - boss.ketel.tink_tick < boss.TINK_TICKS:
		anim = "tink"
		e = 0
	_toon("KetelBeeld", "ketel", anim, frame_at("ketel", anim, e, weg_na), Vector2.ZERO)


func _rad(tick: int) -> void:
	var s := "_s%d" % SCHEUR
	var at: Vector2 = boss.rad.position
	var anim := "draai" + s
	var e := tick
	var ticks: Array = []
	var weg_na := false
	var b := blad("rad")
	if boss.is_defeated():
		anim = "oplossen"
		e = tick - boss.defeated_tick
		weg_na = true
	elif boss.phase == boss.Phase.SWITCH or boss.rad_state == boss.RadState.TURNING:
		ticks = b["animaties"][anim]["ticks_draaien"]
	elif boss.rad_state == boss.RadState.HIDDEN:
		at = Vector2(boss.middle(), boss.rad.position.y)
		e = 0
		ticks = [1 << 30]
	elif boss.rad_state == boss.RadState.SHAKING:
		anim = "trilt" + s
	elif _rad_treffer >= 0 and tick - _rad_treffer < 6:
		anim = "treffer" + s
		e = tick - _rad_treffer
	_toon("RadBeeld", "rad", anim, frame_at("rad", anim, e, weg_na, ticks), at)


func _aanval_beeld(tick: int) -> void:
	if boss.is_defeated() or not (boss.is_telling() or boss.is_attack_active() or boss.attack_phase == boss.AttackPhase.RECOVER):
		_weg("Tell")
		_weg("Effect")
		return
	var at: Vector2 = boss.attack_box.position - boss.global_position
	var soort: String = boss.attack_kind
	var p: float = boss.windup_progress(tick)
	if boss.is_attack_active():
		_toon("Tell", "tell_" + soort, "actief", 0, at)
	elif boss.is_telling():
		_toon("Tell", "tell_" + soort, "laat" if p >= 0.5 else "vroeg", 0, at)
	else:
		_weg("Tell")
	var effect := "pompslag" if soort == "pomp" else "zwiep_" + _kant(boss.attack_side)
	if boss.is_telling():
		if soort == "pomp":
			_toon("Effect", effect, "aanloop", clampi(int(floor(p * 4.0)), 0, 3), at)
		elif p >= 0.5:
			_toon("Effect", effect, "aanloop", 0 if p < 0.75 else 1, at)
		else:
			_weg("Effect")
	elif boss.is_attack_active():
		_toon("Effect", effect, "actief", frame_at(effect, "actief", tick - boss.windup_end_tick()), at)
	else:
		_toon("Effect", effect, "herstel", frame_at(effect, "herstel", tick - boss.active_end_tick()), at)


func _spuigaten(tick: int) -> void:
	for kant: String in ["links", "rechts"]:
		var naam := "Spuigat_" + kant
		var at := Vector2(EnemyData.value(boss.data_group, "spuigat_" + kant), 0.0)
		if boss.is_defeated():
			_weg(naam)
		elif _gloei >= 0:
			_toon(naam, "spuigat", "gloei", frame_at("spuigat", "gloei", tick - _gloei), at)
		elif _stoom >= 0:
			_toon(naam, "spuigat", "stoom", frame_at("spuigat", "stoom", tick - _stoom, true), at)
		else:
			_weg(naam)
