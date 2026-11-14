extends RefCounted
## Het beeld van een slice-vijand (Kadeloper, Schotdrager, Dwaallicht) uit de
## sprites van de Animator (Technical Artist, #272; overdracht
## `docs/art/animatie-timing.md` §2.5, manifest `<type>.json`, `koppeling`).
## Vervangt de placeholder-polygons van `slice_enemy.gd`.
##
## Alleen beeld: dit leest de vlaggen van `slice_enemy.gd` en verandert niets
## aan de Sim (de ticks van een run blijven gelijk). Elke tick kiest
## `update(tick)` de animatie en het frame uit de tick en de vlaggen (geen eigen
## klok), in deze volgorde:
##
## 1. `uit_stoom` (add uit een spuigat, `add_inactief` 30): de vijand staat bij
##    zijn eerste beeldtick langer dan 2 ticks stil (`hold_until`; het wekken van
##    de Kadewijk houdt hem 2 ticks vast).
## 2. `breuk` (12) na `break_armor()`; daarna de `gebroken_*`-rijen en `stuk`
##    als losse sprite op de plek van de breuk.
## 3. `tink` (4) na een treffer op het intacte schot (`tink_tick`).
## 4. `stil` (30) na `stun()`: `_stunned_until` springt naar tick + 30.
## 5. Aanloop op de voortgang van de aanloop: frame 0–3 op kwarten van
##    (aanloop − 3), frame 4 (de uithaal) de laatste 3 ticks; ook verlicht (40).
## 6. Actief (het verste frame) en herstel op de ticks van de fase.
## 7. Anders lopen (de node schoof deze tick) of staan; het Dwaallicht zweeft.
##
## De tell ligt op het vlak, onder het lijf: lopers op `_walker_box()` (vroeg
## < 50 %, laat, actief), het Dwaallicht op de landingsplek met de duiklijn erboven (alleen in
## de aanloop: in de duik is zijn lichaam het vlak). `dood` speelt na het
## verslaan als los effect naast de vijand (`vijand_dood.gd`).
##
## De atlas volgt de waterstand via `lit` (VJ-06: verlicht = `s = 2`): `grijs`
## bij `s < 2`, `kleur` bij `s = 2`, zoals de kamers (deel 2 §9.4). `set_staat`
## zet hem vast (bv. `half` voor de kleurgolf).

const Sprite = preload("res://art/animatie/vijanden/vijand_sprite.gd")
const Dood = preload("res://art/animatie/vijanden/vijand_dood.gd")
const EnemyData = preload("res://scripts/combat/enemy_data.gd")

const DIR := "res://art/animatie/"
const STATEN := ["grijs", "half", "kleur"]
## Laatste ticks van de aanloop met de uithaal (frame 4).
const UITHAAL := 3
## Langer dan dit vastgehouden bij de eerste beeldtick = uit de stoom (het wekken houdt 2 vast).
const WEKKEN := 2
## Tink-vonk (VJ-07, `slice_enemy.gd` TINK_TICKS).
const TINK_TICKS := 4
## `SliceEnemy.Phase.RECOVER` (`test_vijanden_beeld.gd` controleert dat het klopt).
const RECOVER := 3
## Rol → animatie, per type (manifest `animaties`).
const ANIMS := {
	"kadeloper": {"staan": "staan", "lopen": "lopen", "aanloop": "haak_aanloop", "actief": "haak_slag",
		"herstel": "haak_herstel", "stil": "stil"},
	"schotdrager": {"staan": "staan", "lopen": "lopen", "aanloop": "stoot_aanloop", "actief": "stoot_actief",
		"herstel": "stoot_herstel", "stil": "stil"},
	"schotdrager_gebroken": {"staan": "gebroken_staan", "lopen": "gebroken_lopen", "aanloop": "gebroken_aanloop",
		"actief": "gebroken_actief", "herstel": "gebroken_herstel", "stil": "gebroken_stil"},
	"dwaallicht": {"staan": "zweven", "lopen": "zweven", "aanloop": "aanloop", "actief": "duik",
		"herstel": "terug", "stil": "stil"},
}
const TELLS := {"kadeloper": "tell_haak", "schotdrager": "tell_stoot", "dwaallicht": "tell_duik"}

var enemy: Node2D
## `kadeloper`, `schotdrager` of `dwaallicht` (`enemy._group()`).
var type_naam := ""
var staat := "grijs"
var manifest: Dictionary = {}
var lijf: Sprite
var tell: Sprite
## Alleen het Dwaallicht.
var lijn: Sprite
## De stukken van het schot op de vloer (Schotdrager, na de breuk), of null.
var stuk: Sprite

var _staat_vast := ""
var _tex := {}
var _eerste := true
var _vorig_tot := -1_000_000
var _vorig_x := NAN
var _beweegt := false
var _stil_vanaf := -1_000_000
var _stoom_vanaf := -1
var _stoom_tot := -1
var _breuk := -1_000_000
var _pantser := false

static var _m: Dictionary = {}


static func lees_manifest(naam: String) -> Dictionary:
	if not _m.has(naam):
		var data = JSON.parse_string(FileAccess.get_file_as_string("%s%s/%s.json" % [DIR, naam, naam]))
		if data is Dictionary:
			_m[naam] = data
		else:
			push_error("VijandBeeld: manifest %s leest niet" % naam)
			return {}
	return _m[naam]


func _init(p_enemy: Node2D, p_type_naam: String) -> void:
	enemy = p_enemy
	type_naam = p_type_naam
	manifest = lees_manifest(type_naam)
	# De tell en de duiklijn liggen onder het lijf (manifest `koppeling`: in het actieve frame
	# moeten de haak en het schot op het vlak zichtbaar zijn, zoals in de renders): zelfde z
	# als het lijf, eerder in de boom.
	var z := int(blad(type_naam).get("z_index", 0))
	tell = _sprite("Tell", TELLS[type_naam], z)
	if type_naam == "dwaallicht":
		lijn = _sprite("Duiklijn", "duiklijn", z)
	lijf = _sprite("Lijf", type_naam, z)
	_pantser = enemy.armor_intact
	staat = _gewenste_staat()
	_zet_textures()
	_toon(lijf, type_naam, ANIMS[type_naam]["staan"], 0)
	_plaats_lijf()
	enemy.died.connect(_op_dood)


func _sprite(naam: String, blad_naam: String, z: int) -> Sprite:
	var s := Sprite.new()
	s.name = naam
	s.blad = blad_naam
	s.centered = false
	s.region_enabled = true
	s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	s.z_index = z
	s.visible = false
	enemy.add_child(s)
	return s


## Haalt de sprites weg (bij een ander type).
func wis() -> void:
	for s: Node in [lijf, tell, lijn]:
		if s != null and is_instance_valid(s):
			s.free()
	_wis_stuk()
	if enemy.died.is_connected(_op_dood):
		enemy.died.disconnect(_op_dood)


func blad(naam: String) -> Dictionary:
	return manifest["bladen"][naam]


## Zet de bestanden vast (`grijs`, `half`, `kleur`); "" = weer de waterstand volgen (`lit`).
func set_staat(nieuw: String) -> void:
	if nieuw != "" and not STATEN.has(nieuw):
		push_error("VijandBeeld: onbekende staat %s" % nieuw)
		return
	_staat_vast = nieuw
	_volg_staat()


func _gewenste_staat() -> String:
	if _staat_vast != "":
		return _staat_vast
	return "kleur" if enemy.lit else "grijs"


func _volg_staat() -> void:
	var wil := _gewenste_staat()
	if wil != staat:
		staat = wil
		_zet_textures()


func _zet_textures() -> void:
	for s: Sprite in [lijf, tell, lijn, stuk]:
		if s != null and is_instance_valid(s):
			s.texture = _texture(s.blad)


func _texture(blad_naam: String) -> Texture2D:
	var pad := "%s%s/%s" % [DIR, type_naam, blad(blad_naam)["bestanden"][staat]]
	if not _tex.has(pad):
		_tex[pad] = load(pad)
	return _tex[pad]


## Frame van animatie `anim` na `e` ticks (lus of niet; voorbij het einde het laatste frame).
## `rek` vermenigvuldigt de ticks (lopen in een verlichte wijk: ×2, manifest `lopen`).
func frame_at(blad_naam: String, anim: String, e: int, rek := 1) -> int:
	var a: Dictionary = blad(blad_naam)["animaties"][anim]
	var t: Array = a["ticks"]
	var som := 0
	for v in t:
		som += int(v) * rek
	if a.get("lus", false):
		e = posmod(e, maxi(som, 1))
	elif e >= som:
		return t.size() - 1
	for i in t.size():
		e -= int(t[i]) * rek
		if e < 0:
			return i
	return t.size() - 1


func _duur(blad_naam: String, anim: String) -> int:
	var som := 0
	for v in blad(blad_naam)["animaties"][anim]["ticks"]:
		som += int(v)
	return som


func _toon(s: Sprite, blad_naam: String, anim: String, frame: int) -> void:
	s.visible = true
	if s.blad == blad_naam and s.anim == anim and s.frame_nr == frame:
		return
	if s.blad != blad_naam:
		s.blad = blad_naam
		s.texture = _texture(blad_naam)
	s.anim = anim
	s.frame_nr = frame
	var f: Array = blad(blad_naam)["animaties"][anim]["frames"][frame]
	s.region_rect = Rect2(f[0], f[1], f[2], f[3])


func _verberg(s: Sprite) -> void:
	if s == null:
		return
	s.visible = false
	s.anim = ""
	s.frame_nr = -1


## Kijkrichting: links = `flip_h` en `offset_links` (het Dwaallicht is symmetrisch).
func _links() -> bool:
	return type_naam != "dwaallicht" and enemy.facing < 0


func _offset(blad_naam: String, links: bool) -> Vector2:
	var b := blad(blad_naam)
	var o: Array = b["offset_links"] if links and b.has("offset_links") else b["offset"]
	return Vector2(o[0], o[1])


func _plaats_lijf() -> void:
	var links := _links()
	lijf.flip_h = links
	lijf.position = _offset(type_naam, links)


## Voortgang van de aanloop: e ticks sinds de start, van `totaal`.
func _aanloop(tick: int) -> Vector2i:
	var totaal := EnemyData.windup(type_naam, enemy.lit)
	return Vector2i(clampi(totaal - (enemy._phase_end - tick), 0, totaal - 1), totaal)


func _aanloop_frame(e: int, totaal: int) -> int:
	if e >= totaal - UITHAAL:
		return 4
	return clampi(int(floor(4.0 * e / float(maxi(totaal - UITHAAL, 1)))), 0, 3)


## Kies per tick het frame van lijf en tell uit de vlaggen (alleen beeld).
func update(tick: int) -> void:
	if not enemy.alive:
		for s: Sprite in [lijf, tell, lijn]:
			_verberg(s)
		return
	_volg_staat()
	_lees_vlaggen(tick)
	var rol := _rol(tick)
	var anims: Dictionary = ANIMS[_rijen()]
	var naam: String = rol[0] if not anims.has(rol[0]) else anims[rol[0]]
	var frame: int = rol[1] if rol[0] == "aanloop" else frame_at(type_naam, naam, rol[1],
		2 if naam.ends_with("lopen") and enemy.lit else 1)
	_toon(lijf, type_naam, naam, frame)
	_plaats_lijf()
	_update_tell(tick)


func _rijen() -> String:
	if type_naam == "schotdrager" and not enemy.armor_intact:
		return "schotdrager_gebroken"
	return type_naam


func _lees_vlaggen(tick: int) -> void:
	var tot: int = enemy._stunned_until
	var stil := EnemyData.ticks("gedeeld", "stil_na_treffer")
	if _eerste:
		_eerste = false
		if tot - tick > WEKKEN and blad(type_naam)["animaties"].has("uit_stoom"):
			# Het einde valt op het einde van `add_inactief`: dan stapt hij uit de stoom.
			_stoom_vanaf = tot - _duur(type_naam, "uit_stoom")
			_stoom_tot = tot
	elif tot != _vorig_tot and tot - tick > WEKKEN:
		_stil_vanaf = tot - stil
		_stoom_tot = -1
	_vorig_tot = tot
	var x: float = enemy.position.x
	_beweegt = not is_nan(_vorig_x) and absf(x - _vorig_x) > 0.0001
	_vorig_x = x
	if _pantser and not enemy.armor_intact and type_naam == "schotdrager":
		_breuk = tick
		_leg_stuk()
	elif enemy.armor_intact and not _pantser:
		_breuk = -1_000_000
		_wis_stuk()
	_pantser = enemy.armor_intact


## [rol of animatie, e (ticks in de animatie) of het frame bij de aanloop].
func _rol(tick: int) -> Array:
	if tick < _stoom_tot:
		return ["uit_stoom", tick - _stoom_vanaf]
	if type_naam == "schotdrager" and tick - _breuk < _duur(type_naam, "breuk"):
		return ["breuk", tick - _breuk]
	if type_naam == "schotdrager" and enemy.armor_intact and tick - enemy.tink_tick < TINK_TICKS:
		return ["tink", tick - enemy.tink_tick]
	if enemy.is_stunned(tick) and tick >= _stil_vanaf \
			and tick < _stil_vanaf + EnemyData.ticks("gedeeld", "stil_na_treffer"):
		return ["stil", tick - _stil_vanaf]
	if enemy.is_telling():
		var a := _aanloop(tick)
		return ["aanloop", _aanloop_frame(a.x, a.y)]
	if enemy.is_attack_active():
		return ["actief", tick - (enemy._phase_end - EnemyData.ticks(type_naam, "actief"))]
	if enemy.phase == RECOVER:
		return ["herstel", tick - (enemy._phase_end - EnemyData.ticks(type_naam, "herstel"))]
	return ["lopen" if _beweegt else "staan", tick]


func _update_tell(tick: int) -> void:
	var windup: bool = enemy.is_telling()
	var active: bool = enemy.is_attack_active()
	var tell_blad: String = TELLS[type_naam]
	if type_naam == "dwaallicht":
		if not windup:
			_verberg(tell)
			_verberg(lijn)
			return
		var a := _aanloop(tick)
		var stap := "vroeg" if a.x < a.y * 0.5 else "laat"
		var size: Vector2 = enemy.body_size()
		var landing_top: float = enemy.floor_top - EnemyData.value(type_naam, "duik_hoogte") - size.y
		_toon(tell, tell_blad, stap, 0)
		tell.position = Vector2(-size.x * 0.5, landing_top - enemy.position.y) + _offset(tell_blad, false)
		# De duiklijn: van de onderkant van de hurtbox tot de landingsplek (manifest `duiklijn`).
		var gat := int(round(landing_top - (enemy.position.y + size.y * 0.5)))
		if gat <= 0:
			_verberg(lijn)
			return
		_toon(lijn, "duiklijn", stap, 0)
		var f: Array = blad("duiklijn")["animaties"][stap]["frames"][0]
		lijn.region_rect = Rect2(f[0], f[1], f[2], mini(gat, int(f[3])))
		lijn.position = Vector2(0.0, size.y * 0.5) + _offset("duiklijn", false)
		return
	if not windup and not active:
		_verberg(tell)
		return
	var stap := "actief"
	if windup:
		var a := _aanloop(tick)
		stap = "vroeg" if a.x < a.y * 0.5 else "laat"
	_toon(tell, tell_blad, stap, 0)
	var box: Rect2 = enemy._walker_box()
	tell.position = box.position - enemy.global_position + _offset(tell_blad, false)


## De ouder van de vijand (de inhoud van een kamer, of de Sim voor een add) en de plek daarin:
## `position` geldt in de ouder, ook als die geen `Node2D` is (dan is het de wereldplek).
func _ouder_en_plek(local: Vector2) -> Array:
	var ouder := enemy.get_parent()
	if ouder == null:
		return [null, Vector2.ZERO]
	return [ouder, enemy.position + local]


## De stukken van het schot blijven liggen waar hij brak (manifest `stuk`).
func _leg_stuk() -> void:
	_wis_stuk()
	var links: bool = enemy.facing < 0
	var r := _ouder_en_plek(_offset(type_naam, links))
	stuk = Sprite.new()
	stuk.name = String(enemy.name).validate_node_name() + "_Stuk"
	stuk.blad = type_naam
	stuk.centered = false
	stuk.region_enabled = true
	stuk.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	stuk.texture = _texture(type_naam)
	stuk.flip_h = links
	stuk.z_index = enemy.z_index + int(blad(type_naam).get("z_index", 0)) - 1
	var f: Array = blad(type_naam)["animaties"]["stuk"]["frames"][0]
	stuk.region_rect = Rect2(f[0], f[1], f[2], f[3])
	stuk.anim = "stuk"
	stuk.frame_nr = 0
	if r[0] != null:
		stuk.position = r[1]
		(r[0] as Node).add_child(stuk)
	else:
		stuk.top_level = true
		stuk.position = enemy.global_position + _offset(type_naam, links)
		enemy.add_child(stuk)


func _wis_stuk() -> void:
	if stuk != null and is_instance_valid(stuk):
		stuk.queue_free()
	stuk = null


## `dood` als los effect naast de vijand (die is op deze tick al weg, LM-13).
func _op_dood(_tick: int) -> void:
	var links := _links()
	var r := _ouder_en_plek(_offset(type_naam, links))
	if r[0] == null:
		return
	var a: Dictionary = blad(type_naam)["animaties"]["dood"]
	var d := Dood.new()
	d.name = String(enemy.name).validate_node_name() + "_Dood"
	d.blad = type_naam
	d.centered = false
	d.region_enabled = true
	d.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	d.texture = _texture(type_naam)
	d.flip_h = links
	d.z_index = enemy.z_index + int(blad(type_naam).get("z_index", 0))
	d.position = r[1]
	d.speel(a["frames"], a["ticks"])
	(r[0] as Node).add_child(d)
