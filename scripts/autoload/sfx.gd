extends Node
## Áudio (autoload "Sfx"). Tudo é SINTETIZADO por código na abertura do jogo — não há arquivos de som.
## Para trocar por sons/músicas de verdade depois, basta colocar AudioStreams em `sounds` e `tracks`.

const RATE := 22050
const GAP := {"shoot": 0.06, "hit": 0.045, "explode": 0.035, "graze": 0.045, "enemy_shot": 0.08,
	"laser": 0.15, "charge": 0.12, "coin": 0.04}

var sounds := {}
var tracks := {}
var muted := false

var _players: Array = []
var _next := 0
var _music: AudioStreamPlayer
var _mode := ""
var _last := {}
var _b := PackedFloat32Array()   # buffer de trabalho da síntese dos efeitos
var _thread: Thread
var _tier := 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for i in 14:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_players.append(p)
	_music = AudioStreamPlayer.new()
	_music.volume_db = -7.0
	add_child(_music)
	_build_sfx()
	# a música fica mais frenética a cada par de setores: 5 níveis de intensidade (0..4).
	# Gera na hora só o que o começo do jogo usa; o resto é gerado numa thread em segundo plano.
	var s := Synth.new()
	tracks["title"] = _build_track(s, "title", 0)
	tracks["stage0"] = _build_track(s, "stage", 0)
	tracks["boss0"] = _build_track(s, "boss", 0)
	_thread = Thread.new()
	_thread.start(_build_rest)
	var cf := ConfigFile.new()
	if cf.load(Cfg.SAVE_PATH) == OK:
		muted = bool(cf.get_value("audio", "muted", false))
	AudioServer.set_bus_mute(0, muted)


func play(sound: String, vol_db := 0.0) -> void:
	if not sounds.has(sound):
		return
	var now := Time.get_ticks_msec() / 1000.0
	var gap: float = GAP.get(sound, 0.03)
	if now - float(_last.get(sound, -10.0)) < gap:
		return
	_last[sound] = now
	var p: AudioStreamPlayer = _players[_next]
	_next = (_next + 1) % _players.size()
	p.stream = sounds[sound]
	p.volume_db = vol_db
	p.play()


## Nível de intensidade da música para um setor (0 = setores 1-2 ... 4 = setores 9-10).
## Do NG+3 em diante a trilha já começa um nível acima.
static func tier_for(stage_idx: int, ng: int) -> int:
	return clampi(int(stage_idx / 2.0) + (1 if ng >= 3 else 0), 0, 4)


## "title", "stage", "boss" ou "silence". `tier` escolhe a intensidade (0..4).
func music(mode: String, tier := 0) -> void:
	var key := mode
	if mode == "stage" or mode == "boss":
		# se a versão pedida ainda está sendo gerada, usa a mais intensa já pronta
		var k := tier
		while k > 0 and not tracks.has("%s%d" % [mode, k]):
			k -= 1
		key = "%s%d" % [mode, k]
	if key == _mode:
		return
	_mode = key
	if tracks.has(key):
		_music.stream = tracks[key]
		_music.play()
	else:
		_music.stop()


func _build_rest() -> void:
	var s := Synth.new()
	var done := {}
	for k in range(1, 5):
		done["stage%d" % k] = _build_track(s, "stage", k)
		done["boss%d" % k] = _build_track(s, "boss", k)
	_on_rest_ready.call_deferred(done)


func _on_rest_ready(done: Dictionary) -> void:
	_thread.wait_to_finish()
	for key in done:
		tracks[key] = done[key]


func _exit_tree() -> void:
	if _thread != null and _thread.is_started():
		_thread.wait_to_finish()


func toggle_mute() -> void:
	muted = not muted
	AudioServer.set_bus_mute(0, muted)
	var cf := ConfigFile.new()
	cf.load(Cfg.SAVE_PATH)
	cf.set_value("audio", "muted", muted)
	cf.save(Cfg.SAVE_PATH)


# ------------------------------------------------------------------ efeitos

func _build_sfx() -> void:
	_new_buf(0.05)
	_tone(0.0, 0.045, 1200.0, 600.0, 0.22, 1, 4000.0)
	sounds["shoot"] = _wav(false)

	_new_buf(0.06)
	_tone(0.0, 0.05, 420.0, 220.0, 0.4, 3)
	sounds["hit"] = _wav(false)

	_new_buf(0.1)
	_tone(0.0, 0.09, 700.0, 350.0, 0.35, 0)
	sounds["enemy_shot"] = _wav(false)

	_new_buf(0.4)
	_noise(0.0, 0.36, 0.6, 2400.0, 150.0)
	_tone(0.0, 0.3, 140.0, 40.0, 0.6, 0)
	sounds["explode"] = _wav(false)

	_new_buf(1.3)
	_noise(0.0, 1.25, 0.8, 3500.0, 60.0)
	_tone(0.0, 1.1, 90.0, 25.0, 0.8, 0)
	sounds["big_explode"] = _wav(false)

	_new_buf(0.04)
	_tone(0.0, 0.035, 2600.0, 2200.0, 0.25, 0)
	sounds["graze"] = _wav(false)

	_new_buf(0.3)
	var notes := [523.0, 659.0, 784.0, 1047.0]
	for i in 4:
		_tone(i * 0.05, 0.08, notes[i], 0.0, 0.3, 1, 3000.0)
	sounds["power"] = _wav(false)

	_new_buf(0.6)
	_tone(0.0, 0.55, 700.0, 60.0, 0.5, 2)
	_noise(0.0, 0.4, 0.6, 3000.0, 200.0)
	sounds["player_hit"] = _wav(false)

	_new_buf(1.6)
	_noise(0.0, 1.55, 0.8, 6000.0, 80.0)
	_tone(0.0, 1.3, 220.0, 30.0, 0.8, 0)
	sounds["bomb"] = _wav(false)

	_new_buf(2.1)
	for i in 4:
		_tone(i * 0.5, 0.22, 440.0, 0.0, 0.3, 1, 2000.0)
		_tone(i * 0.5 + 0.25, 0.22, 330.0, 0.0, 0.3, 1, 2000.0)
	sounds["warning"] = _wav(false)

	_new_buf(0.1)
	_tone(0.0, 0.09, 660.0, 1320.0, 0.3, 1, 4000.0)
	sounds["select"] = _wav(false)

	_new_buf(0.04)
	_tone(0.0, 0.03, 880.0, 0.0, 0.25, 1, 3000.0)
	sounds["tick"] = _wav(false)

	_new_buf(0.65)
	_tone(0.0, 0.5, 150.0, 900.0, 0.4, 2, 2500.0)
	_noise(0.0, 0.6, 0.5, 4000.0, 300.0)
	sounds["phase"] = _wav(false)

	_new_buf(0.32)
	_tone(0.0, 0.3, 120.0, 40.0, 0.7, 0)
	_noise(0.0, 0.25, 0.4, 1500.0, 100.0)
	sounds["slam"] = _wav(false)

	_new_buf(0.36)
	_noise(0.0, 0.35, 0.5, 400.0, 3000.0)
	sounds["dash"] = _wav(false)

	_new_buf(0.65)
	var up := [440.0, 554.0, 659.0, 880.0, 1109.0]
	for i in 5:
		_tone(i * 0.09, 0.18, up[i], 0.0, 0.28, 1, 3500.0)
	sounds["clear"] = _wav(false)

	_new_buf(1.0)
	var down := [440.0, 392.0, 349.0, 220.0]
	for i in 4:
		_tone(i * 0.22, 0.3, down[i], down[i] * 0.98, 0.3, 2, 1800.0)
	sounds["game_over"] = _wav(false)

	_new_buf(0.5)
	_tone(0.0, 0.45, 180.0, 120.0, 0.35, 2, 1500.0)
	_noise(0.0, 0.45, 0.25, 3000.0, 800.0)
	sounds["laser"] = _wav(false)

	_new_buf(0.4)
	_tone(0.0, 0.38, 300.0, 900.0, 0.18, 1, 2500.0)
	sounds["charge"] = _wav(false)

	_new_buf(0.25)
	_tone(0.0, 0.07, 988.0, 0.0, 0.25, 1, 4000.0)
	_tone(0.07, 0.16, 1319.0, 0.0, 0.25, 1, 4000.0)
	sounds["coin"] = _wav(false)

	_new_buf(0.35)
	_tone(0.0, 0.3, 1400.0, 500.0, 0.35, 0)
	_noise(0.0, 0.2, 0.2, 5000.0, 1500.0)
	sounds["shield"] = _wav(false)

	_new_buf(0.2)
	_tone(0.0, 0.18, 200.0, 140.0, 0.3, 1, 1200.0)
	sounds["deny"] = _wav(false)


# ------------------------------------------------------------------ trilhas

const PROG := [55.0, 43.65, 65.41, 49.0]   # Lá, Fá, Dó, Sol (graves)
const BASS := [1.0, 0.0, 1.0, 2.0, 1.0, 0.0, 1.0, 1.0, 1.0, 0.0, 2.0, 1.0, 1.0, 1.0, 2.0, 1.5]
const ARP := [1.0, 1.19, 1.5, 2.0]         # tônica, terça menor, quinta, oitava


const LEAD := [1.0, 1.5, 1.19, 2.0, 1.78, 1.5]


## Gera um loop de 4 compassos (64 semicolcheias) no estilo synthwave.
## `k` = intensidade 0..4. Cada nível acelera o andamento e acrescenta camadas:
##   1: chimbal no contratempo · 2: arpejo em semicolcheias + caixa fantasma
##   3: bumbo sincopado + baixo com oitavas · 4: lead serrilhado + virada de caixa + sobe um tom
## O chefe toca sempre um nível acima do setor (até 5).
func _build_track(s: Synth, mode: String, k: int) -> AudioStreamWAV:
	var boss := mode == "boss"
	var lvl := k + (1 if boss else 0)
	var bpm := 118.0 if mode == "title" else 120.0 + 9.0 * k + (12.0 if boss else 0.0)
	var spb := 60.0 / bpm / 4.0
	var shift := pow(2.0, 2.0 / 12.0) if k >= 4 else 1.0
	s.start(spb * 64.0)
	for n in 64:
		var t := n * spb
		var bar := int(n / 16.0)
		var st := n % 16
		var root: float = PROG[bar] * shift
		var bm: float = BASS[st]
		if mode == "title":
			var arp_t: float = ARP[int(st / 2.0) % 4]
			if st % 2 == 0 and bm > 0.0:
				s.tone(t, 0.22, root * 2.0 * bm, 0.0, 0.16, 2, 600.0)
			if st % 2 == 1:
				s.tone(t, 0.25, root * 8.0 * arp_t, 0.0, 0.07, 3, 2500.0)
			continue
		# bateria
		if st % 4 == 0:
			s.tone(t, 0.16, 150.0, 42.0, 0.7, 0)                           # bumbo
		if lvl >= 3 and (st == 10 or (st == 14 and bar % 2 == 1)):
			s.tone(t, 0.12, 140.0, 45.0, 0.45, 0)                          # bumbo extra
		if st % 4 == 2:
			s.noise(t, 0.05, 0.13, 6000.0, 6000.0, true)                   # chimbal aberto
		if lvl >= 1 and st % 2 == 1:
			s.noise(t, 0.025, 0.07, 7000.0, 7000.0, true)                  # chimbal fechado
		if lvl >= 4 and st % 2 == 0 and st % 4 != 2:
			s.noise(t, 0.02, 0.05, 8000.0, 8000.0, true)
		if st % 8 == 4:
			s.noise(t, 0.14, 0.3, 2200.0, 900.0)                           # caixa
		if lvl >= 2 and st == 15:
			s.noise(t, 0.06, 0.12, 2400.0, 1200.0)                         # caixa fantasma
		if lvl >= 4 and bar == 3 and st >= 12:
			s.noise(t, 0.07, 0.12 + 0.05 * (st - 12), 2600.0, 1200.0)      # virada
		# baixo: o filtro abre conforme a intensidade
		var cut := 650.0 + 170.0 * lvl
		if bm > 0.0:
			s.tone(t, 0.12, root * 2.0 * bm, 0.0, 0.22, 2, cut)
		elif lvl >= 3:
			s.tone(t, 0.08, root * 4.0, 0.0, 0.12, 2, cut)
		# arpejo
		var every := 1 if lvl >= 2 else 2
		if (lvl >= 1 or bar >= 2) and st % every == 0:
			var arp: float = ARP[(st if lvl >= 2 else int(st / 2.0)) % 4]
			s.tone(t, 0.08, root * 8.0 * arp, 0.0, 0.05, 1, 2600.0 + 300.0 * lvl)
		# lead
		if lvl >= 4 and bar >= 2 and (st == 0 or st == 3 or st == 6 or st == 10 or st == 12):
			var ld: float = LEAD[(st + bar) % LEAD.size()]
			s.tone(t, 0.18, root * 4.0 * ld, 0.0, 0.07, 2, 3200.0)
	return s.wav(true)


# ------------------------------------------------------------------ síntese

func _new_buf(seconds: float) -> void:
	_b = PackedFloat32Array()
	_b.resize(int(seconds * RATE))


func _osc(kind: int, ph: float) -> float:
	var x := ph - floorf(ph)
	match kind:
		0:
			return sin(x * TAU)               # senoide
		1:
			return 1.0 if x < 0.5 else -1.0   # quadrada
		2:
			return 2.0 * x - 1.0              # dente de serra
	return 4.0 * absf(x - 0.5) - 1.0          # triangular


## Nota com glissando (f0 -> f1), envelope de decaimento e filtro passa-baixa opcional (lp em Hz).
func _tone(start: float, dur: float, f0: float, f1: float, vol: float, kind: int, lp := 0.0) -> void:
	var size := _b.size()
	var i0 := int(start * RATE)
	var n := int(dur * RATE)
	if n <= 0 or size == 0:
		return
	var f := f0
	var fm := 1.0
	if f1 > 0.0 and f1 != f0:
		fm = pow(f1 / f0, 1.0 / n)
	var a := 1.0
	if lp > 0.0:
		a = 1.0 - exp(-TAU * lp / RATE)
	var ph := 0.0
	var y := 0.0
	var att := 0.004 * RATE
	for i in n:
		ph += f / RATE
		f *= fm
		var s := _osc(kind, ph)
		if lp > 0.0:
			y += a * (s - y)
			s = y
		var k := 1.0 - float(i) / n
		var env := minf(1.0, i / att) * k * k
		var idx := (i0 + i) % size
		_b[idx] += s * env * vol


## Ruído filtrado (explosões, bateria). Varre o filtro de f0 até f1.
func _noise(start: float, dur: float, vol: float, f0: float, f1: float, highpass := false) -> void:
	var size := _b.size()
	var i0 := int(start * RATE)
	var n := int(dur * RATE)
	if n <= 0 or size == 0:
		return
	var f := f0
	var fm := 1.0
	if f1 > 0.0 and f1 != f0:
		fm = pow(f1 / f0, 1.0 / n)
	var y := 0.0
	for i in n:
		var a := 1.0 - exp(-TAU * f / RATE)
		f *= fm
		var s := randf() * 2.0 - 1.0
		y += a * (s - y)
		var o := s - y if highpass else y
		var k := 1.0 - float(i) / n
		var idx := (i0 + i) % size
		_b[idx] += o * vol * k * k


func _wav(loop: bool) -> AudioStreamWAV:
	var n := _b.size()
	var data := PackedByteArray()
	data.resize(n * 2)
	for i in n:
		var v := tanh(_b[i])   # saturação suave em vez de clipar
		data.encode_s16(i * 2, int(v * 32000.0))
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = RATE
	w.stereo = false
	w.data = data
	if loop:
		w.loop_mode = AudioStreamWAV.LOOP_FORWARD
		w.loop_begin = 0
		w.loop_end = n
	return w
