extends "res://scripts/audio/sim_sfx.gd"
## RAD_TREFFER van de Gemaalmeester (B-10; #243, audio bible v0.5 §4.1). Hangt
## onder de boss (`gemaalmeester.gd` maakt hem aan) en start op
## `rad_hit(tick, source, action, amount)` een `AudioStreamPlayer2D` op het rad.
##
## - **P1/P2** (telt mee voor `kant_treffers`): `gm_rad_treffer_1`, en
##   `gm_rad_treffer_2` (een kwart hoger, "deze kant is klaar") op de treffer
##   die `kant_treffers` haalt; bus `SFX`.
## - **De echo** doet minder (5 SE, telt niet mee): **altijd** de holle
##   `echo_gm_rad_treffer_1` op bus `Echo`, met `play(0.2)` op de treffer-tick
##   (zonder aanloop, `slice-audio.md` §7.2), en **nooit** `_2`: die belooft
##   een treffer die niet telt.
##
## Waarden in `data/audio.json`, groep `rad_treffer`. De levende
## `gm_rad_treffer_1/_2` staan nog niet in `game/audio/` (alleen in
## `docs/audio/t8d-slice/`): tot ze er zijn, zijn de treffers van P1/P2 stil.

const EnemyData = preload("res://scripts/combat/enemy_data.gd")

## Untyped: de signalen en velden staan in het script van het object.
var boss
## De geluiden; standaard uit de data, in een test ook direct te zetten.
var sfx_1: AudioStream
var sfx_2: AudioStream
var sfx_echo: AudioStream


func _init() -> void:
	name = "RadAudio"
	var c := config("rad_treffer")
	max_voices = int(c.get("max_stemmen", 3))
	sfx_1 = stream(String(c.get("stream_1", "")))
	sfx_2 = stream(String(c.get("stream_2", "")))
	sfx_echo = stream(String(c.get("echo_stream", "")))


func bind(p_boss: Node2D) -> void:
	boss = p_boss
	if not boss.rad_hit.is_connected(_on_rad_hit):
		boss.rad_hit.connect(_on_rad_hit)


func _on_rad_hit(tick: int, source: String, _action: String, _amount: int) -> void:
	var c := config("rad_treffer")
	var at := place_of(boss.rad if boss.rad != null else boss)
	if source == "echo":
		play_on_tick(tick, sfx_echo, at, AudioBuses.ECHO, float(c.get("echo_volume_db", 0.0)), 1.0,
			source, float(c.get("echo_start_s", 0.2)))
		return
	# `rad_side_hits` telt deze treffer al mee (`on_damage` vóór `rad_hit`).
	var last := int(boss.rad_side_hits) >= EnemyData.ticks(boss.data_group, "kant_treffers")
	play_on_tick(tick, sfx_2 if last else sfx_1, at, AudioBuses.SFX, float(c.get("volume_db", 0.0)),
		1.0, source)
