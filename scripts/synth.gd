class_name Synth
extends RefCounted
## Sintetizador simples: escreve ondas, ruído e envelopes num buffer e gera um AudioStreamWAV.
## Cada instância tem o próprio buffer, então dá para gerar músicas numa thread separada.

const RATE := 22050

var b := PackedFloat32Array()

# Modo "em fatias": com `recording = true`, tone()/noise() só anotam as notas;
# depois step() processa um pouco por quadro, sem travar o jogo (usado na versão Web).
var recording := false
var _queue: Array = []
var _qi := 0
var _enc_i := 0
var _data := PackedByteArray()


func start(seconds: float) -> void:
	b = PackedFloat32Array()
	b.resize(int(seconds * RATE))


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
func tone(start_s: float, dur: float, f0: float, f1: float, vol: float, kind: int, lp := 0.0) -> void:
	if recording:
		_queue.append([0, start_s, dur, f0, f1, vol, kind, lp])
		return
	var size := b.size()
	var i0 := int(start_s * RATE)
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
		b[idx] += s * env * vol


## Ruído filtrado (explosões, bateria). Varre o filtro de f0 até f1.
func noise(start_s: float, dur: float, vol: float, f0: float, f1: float, highpass := false) -> void:
	if recording:
		_queue.append([1, start_s, dur, vol, f0, f1, highpass])
		return
	var size := b.size()
	var i0 := int(start_s * RATE)
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
		b[idx] += o * vol * k * k


## Processa as notas anotadas e depois codifica o áudio, parando quando gastar `budget_usec`.
## Retorna true quando terminou (aí é só chamar finish_wav()).
func step(budget_usec: int) -> bool:
	var t0 := Time.get_ticks_usec()
	recording = false
	while _qi < _queue.size():
		var e: Array = _queue[_qi]
		_qi += 1
		if e[0] == 0:
			tone(e[1], e[2], e[3], e[4], e[5], e[6], e[7])
		else:
			noise(e[1], e[2], e[3], e[4], e[5], e[6])
		if Time.get_ticks_usec() - t0 > budget_usec:
			return false
	if _data.size() != b.size() * 2:
		_data.resize(b.size() * 2)
	while _enc_i < b.size():
		var end := mini(b.size(), _enc_i + 2048)
		for i in range(_enc_i, end):
			_data.encode_s16(i * 2, int(tanh(b[i]) * 32000.0))
		_enc_i = end
		if Time.get_ticks_usec() - t0 > budget_usec:
			return false
	return true


func finish_wav(loop: bool) -> AudioStreamWAV:
	return _make_wav(_data, b.size(), loop)


func wav(loop: bool) -> AudioStreamWAV:
	var n := b.size()
	var data := PackedByteArray()
	data.resize(n * 2)
	for i in n:
		var v := tanh(b[i])   # saturação suave em vez de clipar
		data.encode_s16(i * 2, int(v * 32000.0))
	return _make_wav(data, n, loop)


func _make_wav(data: PackedByteArray, n: int, loop: bool) -> AudioStreamWAV:
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
