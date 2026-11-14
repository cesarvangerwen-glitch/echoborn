extends "res://art/animatie/vijanden/vijand_sprite.gd"
## De animatie `dood` van een slice-vijand als los effect (Technical Artist, #272;
## animatie-timing §2.5 punt 4). Een verslagen vijand is op de tick zelf weg
## (LM-13: `visible = false`, niet meer `alive`), dus dit effect hangt naast hem
## in de boom, op zijn plek en in zijn kijkrichting. Het speelt de frames van
## `dood` (manifest: 8 × 6 = 48 ticks, voorstel van de Animator; de duur beslist
## de Combat Designer) één physics-frame per tick en ruimt zichzelf op.
##
## Alleen beeld: het staat niet in de Sim, heeft geen vlak en raakt niets.

var _frames: Array = []
var _ticks: Array = []
var _e := 0


## `frames` en `ticks` uit het manifest (`animaties.dood`).
func speel(p_frames: Array, p_ticks: Array) -> void:
	_frames = p_frames
	_ticks = p_ticks
	_e = 0
	anim = "dood"
	_toon()


func _physics_process(_delta: float) -> void:
	_e += 1
	_toon()


func _toon() -> void:
	var som := 0
	for i in _ticks.size():
		som += int(_ticks[i])
		if _e < som:
			if frame_nr != i:
				frame_nr = i
				var f: Array = _frames[i]
				region_rect = Rect2(f[0], f[1], f[2], f[3])
			return
	frame_nr = -1
	queue_free()
