class_name Synth
extends RefCounted
## Sintetizador simples: escreve ondas, ruído e envelopes num buffer e gera um AudioStreamWAV.
## Cada instância tem o próprio buffer, então dá para gerar músicas numa thread separada.

const RATE := 22050

var b := PackedFloat32Array()


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


func wav(loop: bool) -> AudioStreamWAV:
	var n := b.size()
	var data := PackedByteArray()
	data.resize(n * 2)
	for i in n:
		var v := tanh(b[i])   # saturação suave em vez de clipar
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
