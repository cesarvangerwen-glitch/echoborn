extends RefCounted
## Tests voor de eerste audiokoppeling (#243; audio bible v0.5 §4.1, §8.3, §10):
## de pompslag van P1 en van de echo, het breekgeluid van het luik en de
## rad-treffer van de echo, plus de basis (bussen, `SimSfx`).
##
## Headless draait Godot met de Dummy-driver: er klinkt niets en `SimSfx` roept
## `play()` niet aan (anders telt een afspeling bij het afsluiten als lek), maar
## de spelers, bussen en starts bestaan gewoon. De test controleert daarom wat elke
## `AudioStreamPlayer2D` krijgt (stream-object, `volume_db`, bus, send,
## `pitch_scale`, plek) en wanneer hij start, niet het geluid zelf.

const Fx = preload("res://tests/echo_fixture.gd")
const InputBits = preload("res://scripts/input/input_bits.gd")
const PlayerActor = preload("res://scripts/echo/player_actor.gd")
const Layers = preload("res://scripts/world/layers.gd")
const LightMeter = preload("res://scripts/light/light_meter.gd")
const Gemaal = preload("res://scripts/light/gemaal.gd")
const Pomprad = preload("res://scripts/light/pomprad.gd")
const Luik = preload("res://scripts/objects/luik.gd")
const Gemaalmeester = preload("res://scripts/combat/gemaalmeester.gd")
const EnemyData = preload("res://scripts/combat/enemy_data.gd")
const SimSfx = preload("res://scripts/audio/sim_sfx.gd")
const PompslagAudio = preload("res://scripts/audio/pompslag_audio.gd")
const AudioBuses = preload("res://scripts/audio/audio_buses.gd")

const D := 60
const VANE_X := 400.0
const VANE_UP := 30.0
const ECHO_PITCH := 0.944


# --- hulpmiddelen ----------------------------------------------------------

## P1 (handmatige input) met een staart-echo van D ticks, een meter met 100 LP
## en een gemaal met één schoep en een sluis ver weg.
func _pompgang(t, d := D) -> Dictionary:
	var sim = Fx.world(t)
	var p1 := Fx.manual_player(sim, 1, Vector2(200, Fx.STAND_Y))
	Fx.tail_echo(sim, p1, d)
	var meter := LightMeter.new(sim, p1)
	meter.value = 100
	var vane := Pomprad.new()
	vane.setup_pomprad()
	vane.name = "Pompschoep1"
	vane.position = Vector2(VANE_X, Fx.FLOOR_TOP - VANE_UP)
	sim.add_object(vane)
	var sluice: StaticBody2D = Fx.block(t, "Sluis", Rect2(1400, 200, 20, 200), Layers.WORLD)
	var gemaal := Gemaal.new()
	gemaal.setup_gemaal(meter, [vane], sluice, Rect2(1500, 360, 300, 40), 370.0, 395.0)
	gemaal.connect_combat(sim.combat)
	sim.add_object(gemaal)
	# Na de koppeling van de audio verbonden: hier is de start van het geluid
	# (als die op de tick van `pumped` gebeurt) al in `starts`.
	var pumps: Array = []
	gemaal.pumped.connect(func(tick: int, amount: int, who: String) -> void:
		pumps.append({"tick": tick, "who": who, "amount": amount, "sim_tick": sim.tick,
			"starts": gemaal.audio.starts.size() if gemaal.audio else -1,
			"physics": Engine.is_in_physics_frame()}))
	return {"sim": sim, "p1": p1, "gemaal": gemaal, "vane": vane, "pumps": pumps}


## P1 loopt naar de schoep, slaat één keer en loopt door; daarna tot de echo
## ook geslagen heeft. Geeft de positie van P1 per tick (voor de vergelijking).
func _slag_en_echo(t, w: Dictionary) -> Array:
	var sim = w["sim"]
	var p1: PlayerActor = w["p1"]
	var trace: Array = []
	var hit := false
	for i in 400:
		var bits := InputBits.RIGHT
		if not hit and p1.position.x >= VANE_X - 32.0:
			bits |= InputBits.ATTACK
			hit = true
		p1.input_source.bits = bits if p1.position.x < VANE_X + 80.0 else 0
		await t.run_ticks(sim, 1)
		trace.append(p1.position)
		if w["pumps"].size() >= 2:
			break
	await t.run_ticks(sim, 2)
	return trace


## Een korte, stille WAV (10 ms) als stand-in voor een geluid dat nog niet in
## `game/audio/` staat.
func _test_stream() -> AudioStreamWAV:
	var s := AudioStreamWAV.new()
	s.format = AudioStreamWAV.FORMAT_16_BITS
	s.mix_rate = 48000
	var data := PackedByteArray()
	data.resize(960)
	s.data = data
	return s


# --- basis -----------------------------------------------------------------

## De bussen van bible §10 (minimaal): SFX en Echo bestaan, SFX komt uit in
## Master en heeft geen effect; Echo hangt onder SFX op 0 dB (slice-audio §7.2);
## de Master heeft de HardLimiter.
func test_bussen(t) -> void:
	AudioBuses.ensure()
	for bus: StringName in [&"Master", &"Muziek", &"Omgeving", &"SFX", &"Speler", &"Echo", &"Combat", &"UI"]:
		t.check(AudioServer.get_bus_index(bus) >= 0, "bus %s ontbreekt" % bus)
	t.check(AudioBuses.send_of(&"SFX") == &"Master" and AudioBuses.effect_count(&"SFX") == 0,
		"SFX: send %s, %d effecten (verwacht Master, 0)" % [AudioBuses.send_of(&"SFX"), AudioBuses.effect_count(&"SFX")])
	var echo := AudioServer.get_bus_index(&"Echo")
	t.check(AudioBuses.send_of(&"Echo") == &"SFX" and is_equal_approx(AudioServer.get_bus_volume_db(echo), 0.0),
		"Echo: send %s, %.1f dB (verwacht SFX, 0 dB)" % [AudioBuses.send_of(&"Echo"), AudioServer.get_bus_volume_db(echo)])
	var master := AudioServer.get_bus_index(&"Master")
	t.check(AudioServer.get_bus_effect_count(master) == 1
		and AudioServer.get_bus_effect(master, 0) is AudioEffectHardLimiter,
		"Master zonder HardLimiter")


# --- pompslag --------------------------------------------------------------

## #243 (D = 60): P1 slaat een schoep, de echo D ticks later. Beide spelers
## krijgen hetzelfde stream-object (de placeholder), dezelfde `volume_db`, bus
## SFX en send; de pitch van P1 is 1,0, die van de echo 0,944 ± 0,001. Het
## geluid start op de Sim-tick van `pumped` (in die aanroep, in een
## physics-frame), op de plek van de geraakte schoep.
func test_pompslag_p1_en_echo_gelijk_d60(t) -> void:
	var w := _pompgang(t)
	await _slag_en_echo(t, w)
	var g: Gemaal = w["gemaal"]
	var audio: PompslagAudio = g.audio
	var pumps: Array = w["pumps"]
	t.check(audio != null and audio.get_parent() == g, "het gemaal heeft geen PompslagAudio")
	t.check(pumps.size() == 2 and pumps[0]["who"] == "p1" and pumps[1]["who"] == "echo"
		and pumps[1]["tick"] == pumps[0]["tick"] + D,
		"pompslagen %s (verwacht P1 op x en de echo op x + %d)" % [pumps, D])
	if pumps.size() != 2 or audio.starts.size() != 2:
		t.check(false, "starts: %s" % [audio.starts if audio else []])
		await t.cleanup()
		return
	var a: Dictionary = audio.starts[0]
	var b: Dictionary = audio.starts[1]
	var expected: AudioStream = audio.sfx
	t.check(expected is AudioStreamWAV and expected.resource_path == String(SimSfx.config("pompslag")["stream"]),
		"pompslag_schoep_placeholder.wav laadt niet: %s" % expected)
	t.check(a["who"] == "p1" and b["who"] == "echo", "volgorde van de starts: %s, %s" % [a["who"], b["who"]])
	t.check(a["stream"] != null and is_same(a["stream"], b["stream"]) and is_same(a["stream"], expected),
		"niet hetzelfde stream-object: %s / %s" % [a["stream"], b["stream"]])
	t.check(a["volume_db"] == b["volume_db"], "volume_db %.2f / %.2f" % [a["volume_db"], b["volume_db"]])
	t.check(a["bus"] == &"SFX" and b["bus"] == &"SFX", "bus %s / %s (verwacht SFX, niet Echo)" % [a["bus"], b["bus"]])
	t.check(a["send"] == b["send"] and a["send"] == &"Master" and a["area_mask"] == b["area_mask"],
		"send %s / %s" % [a["send"], b["send"]])
	t.check(is_equal_approx(a["pitch"], 1.0), "pitch P1 %.4f (verwacht 1,0)" % a["pitch"])
	t.check(absf(b["pitch"] - ECHO_PITCH) <= 0.001, "pitch echo %.4f (verwacht 0,944 ± 0,001)" % b["pitch"])
	t.check(is_zero_approx(a["from"]) and is_zero_approx(b["from"]), "beginpunt niet 0")
	# Op de Sim-tick van `pumped`, in die aanroep en in een physics-frame (niet uit `_process`).
	for i in 2:
		var p: Dictionary = pumps[i]
		var s: Dictionary = audio.starts[i]
		t.check(s["tick"] == p["tick"] and p["sim_tick"] == p["tick"] and p["starts"] == i + 1
			and s["physics"] and p["physics"],
			"%s: start op tick %d, pumped op %d (Sim %d), %d starts in de aanroep, physics %s"
			% [p["who"], s["tick"], p["tick"], p["sim_tick"], p["starts"], s["physics"]])
	# Op de schoep, twee spelers (de slag van P1 loopt nog als die van de echo start).
	var vane: Node2D = w["vane"]
	var pa: AudioStreamPlayer2D = a["player"]
	var pb: AudioStreamPlayer2D = b["player"]
	t.check(a["at"] == vane.global_position and b["at"] == vane.global_position
		and pa.global_position == vane.global_position,
		"plek %s / %s (schoep %s)" % [a["at"], b["at"], vane.global_position])
	t.check(pa != pb and pa.bus == &"SFX" and pb.bus == &"SFX" and is_same(pa.stream, pb.stream)
		and pa.volume_db == pb.volume_db and is_equal_approx(pa.pitch_scale, 1.0)
		and absf(pb.pitch_scale - ECHO_PITCH) <= 0.001,
		"spelers: %s %s %.3f / %s %s %.3f" % [pa.bus, pa.stream, pa.pitch_scale, pb.bus, pb.stream, pb.pitch_scale])
	await t.cleanup()


## Bible §8.3: max. 3 pompslagen tegelijk; de vierde neemt de speler van de oudste.
func test_pompslag_max_3_stemmen(t) -> void:
	var w := _pompgang(t)
	var g: Gemaal = w["gemaal"]
	g.last_vane = w["vane"]
	for i in 5:
		g.pumped.emit(10 + i * 20, 15, "echo" if i % 2 == 1 else "p1")
	var audio: PompslagAudio = g.audio
	var players: Array = audio.starts.map(func(s: Dictionary) -> Node: return s["player"])
	t.check(audio.get_child_count() == 3 and audio.max_voices == 3, "%d stemmen (verwacht 3)" % audio.get_child_count())
	t.check(players.size() == 5 and players[3] == players[0] and players[4] == players[1]
		and players[0] != players[1] and players[1] != players[2],
		"stemmen worden niet om de beurt (oudste eerst) hergebruikt")
	await t.cleanup()


## Determinisme: dezelfde run met en zonder audio geeft dezelfde pompslagen,
## vulstand en dezelfde baan van P1 (audio schrijft nooit naar de Sim).
func test_audio_raakt_de_sim_niet(t) -> void:
	var runs: Array = []
	for with_audio: bool in [true, false]:
		var w := _pompgang(t)
		var g: Gemaal = w["gemaal"]
		if not with_audio:
			g.pumped.disconnect(g.audio._on_pumped)
			g.audio.queue_free()
			g.audio = null
		var trace := await _slag_en_echo(t, w)
		var pumps: Array = w["pumps"].map(func(p: Dictionary) -> Array: return [p["tick"], p["who"], p["amount"]])
		runs.append([pumps, g.fill, trace])
		await t.cleanup()
	t.check(runs[0][1] == 30 and runs[0][0].size() == 2, "run met audio: G = %d, %s" % [runs[0][1], runs[0][0]])
	t.check(runs[0] == runs[1], "met audio %s, G %d; zonder %s, G %d" % [runs[0][0], runs[0][1], runs[1][0], runs[1][1]])


# --- luik ------------------------------------------------------------------

## Bible §4.1: breekt P1 of de echo het luik, dan klinkt hetzelfde breekgeluid
## (stream, volume_db, bus SFX, pitch 1,0). De schaduwklep die de echo weghaalt
## klinkt ook zo; die die vanzelf weggaat ("tijd") niet. Zonder bestand (de
## data, nog leeg) is het luik stil en zonder fout.
func test_luik_zelfde_breekgeluid(t) -> void:
	var sim = Fx.world(t)
	var luiken: Array = []
	for i in 3:
		var luik := Luik.new()
		luik.name = "Luik%d" % (i + 1)
		luik.position = Vector2(200 + i * 200, Fx.FLOOR_TOP + 4.0)
		t.world_root().add_child(luik)
		sim.add_object(luik)
		luiken.append(luik)
	var stil: Luik = luiken[2]
	stil.apply_damage(5, 0, "p1")
	t.check(stil.is_open and stil.audio != null and stil.audio.starts.is_empty(),
		"luik zonder geluid: %d starts" % (stil.audio.starts.size() if stil.audio else -1))
	var sfx := _test_stream()
	var a: Luik = luiken[0]
	var b: Luik = luiken[1]
	a.audio.sfx = sfx
	b.audio.sfx = sfx
	a.apply_damage(10, 0, "p1")
	b.apply_damage(70, 0, "echo")
	b.schaduwklep_weg.emit(80, "tijd")
	b.schaduwklep_weg.emit(90, "echo")
	var sa: Array = a.audio.starts
	var sb: Array = b.audio.starts
	t.check(sa.size() == 1 and sb.size() == 2, "starts: P1 %d, echo %d (verwacht 1 en 2: 'tijd' is stil)" % [sa.size(), sb.size()])
	if sa.size() == 1 and sb.size() == 2:
		for s: Dictionary in sb:
			t.check(is_same(s["stream"], sa[0]["stream"]) and s["volume_db"] == sa[0]["volume_db"]
				and s["bus"] == &"SFX" and sa[0]["bus"] == &"SFX" and s["send"] == sa[0]["send"]
				and is_equal_approx(s["pitch"], 1.0) and is_equal_approx(sa[0]["pitch"], 1.0),
				"echo (%s) breekt anders dan P1: %s / %s" % [s["who"], s, sa[0]])
		t.check(sb[0]["tick"] == 70 and sb[1]["tick"] == 90 and sa[0]["tick"] == 10, "ticks van de starts")
	await t.cleanup()


# --- rad -------------------------------------------------------------------

## Bible §4.1: de rad-treffer van P1 is `gm_rad_treffer_1`, op de treffer die
## `kant_treffers` haalt `_2` (bus SFX), ook in co-op maar één keer per kant. De echo krijgt altijd de holle
## `echo_gm_rad_treffer_1` op bus Echo met `play(0.2)`, en **nooit** `_2`, ook
## niet als de kant op dat moment vol is.
func test_rad_echo_nooit_treffer_2(t) -> void:
	var sim = Fx.world(t)
	var p1 := Fx.manual_player(sim, 1, Vector2(200, Fx.STAND_Y))
	p1.health = 100000
	sim.set_tail_ticks(D)
	var boss := Gemaalmeester.new()
	boss.setup_gemaalmeester(Vector2(0, Fx.FLOOR_TOP))
	boss.attach(sim)
	var audio = boss.audio
	t.check(audio != null and audio.get_parent() == boss, "de boss heeft geen RadAudio")
	t.check(audio.sfx_echo is AudioStreamWAV, "echo_gm_rad_treffer_1_placeholder.wav laadt niet")
	var s1 := _test_stream()
	var s2 := _test_stream()
	audio.sfx_1 = s1
	audio.sfx_2 = s2
	var kant := EnemyData.ticks(boss.data_group, "kant_treffers")
	# P1: eerste treffer, dan de treffer die de kant vol maakt (`on_damage` telt vóór `rad_hit`).
	boss.rad_side_hits = 1
	boss.rad_hit.emit(10, "p1", "sprong", 33)
	boss.rad_side_hits = kant
	boss.rad_hit.emit(30, "p1", "bounce", 33)
	# De echo: met 0, kant − 1 en een volle kant.
	for hits: int in [0, kant - 1, kant, kant + 1]:
		boss.rad_side_hits = hits
		boss.rad_hit.emit(100 + hits, "echo", "echo", 5)
	var starts: Array = audio.starts
	t.check(starts.size() == 6, "%d starts (verwacht 6)" % starts.size())
	if starts.size() == 6:
		t.check(is_same(starts[0]["stream"], s1) and starts[0]["bus"] == &"SFX"
			and is_same(starts[1]["stream"], s2) and starts[1]["bus"] == &"SFX",
			"P1: %s op %s, dan %s op %s (verwacht _1 en _2 op SFX)"
			% [starts[0]["stream"], starts[0]["bus"], starts[1]["stream"], starts[1]["bus"]])
		for s: Dictionary in starts.slice(2):
			t.check(s["who"] == "echo" and is_same(s["stream"], audio.sfx_echo) and not is_same(s["stream"], s2)
				and not is_same(s["stream"], s1) and s["bus"] == &"Echo" and is_equal_approx(s["from"], 0.2),
				"echo op tick %d: %s op %s vanaf %.2f s (verwacht de holle _1 op Echo vanaf 0,2 s)"
				% [s["tick"], s["stream"], s["bus"], s["from"]])
	t.check(starts.all(func(s: Dictionary) -> bool: return not (s["who"] == "echo" and is_same(s["stream"], s2))),
		"de echo startte gm_rad_treffer_2")
	# Co-op: P1 en P2 op dezelfde tick als de kant vol raakt (`on_damage` telt per treffer, dan
	# `rad_hit`): `_2` klinkt maar één keer, de tweede treffer krijgt `_1`.
	var before: int = starts.size()
	boss.rad_side_hits = kant - 1
	for source: String in ["p1", "p2"]:
		boss.rad_side_hits += 1
		boss.rad_hit.emit(200, source, "sprong", 25)
	var coop: Array = audio.starts.slice(before)
	t.check(coop.size() == 2 and is_same(coop[0]["stream"], s2) and is_same(coop[1]["stream"], s1)
		and coop.filter(func(s: Dictionary) -> bool: return is_same(s["stream"], s2)).size() == 1,
		"co-op, P1 en P2 op dezelfde tick: %s (verwacht één keer _2, dan _1)"
		% [coop.map(func(s: Dictionary) -> String: return "%s:%s" % [s["who"], "_2" if is_same(s["stream"], s2) else "_1"])])
	await t.cleanup()
