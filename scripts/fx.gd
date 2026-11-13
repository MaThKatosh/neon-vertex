class_name FX
extends Node2D
## Efeitos visuais: faíscas, estilhaços, ondas de choque, textos flutuantes, tremor e flash de tela.
## Usa uma lista simples de partículas (sem nós), desenhada com mistura aditiva para brilhar.

class P:
	var kind := 0          # 0 faísca, 1 estilhaço, 2 anel, 3 texto
	var pos := Vector2.ZERO
	var vel := Vector2.ZERO
	var life := 0.0
	var max_life := 1.0
	var color := Color.WHITE
	var size := 3.0
	var drag := 0.92
	var rot := 0.0
	var spin := 0.0
	var text := ""
	var lw := 2.0

const MAX := 1100

var parts: Array[P] = []
var shake := 0.0
var flash_a := 0.0
var flash_color := Color.WHITE

var _free: Array[P] = []


func _ready() -> void:
	z_index = 4
	var m := CanvasItemMaterial.new()
	m.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	material = m


func _make(kind: int, pos: Vector2, vel: Vector2, life: float, col: Color, size: float) -> P:
	if parts.size() >= MAX:
		return null
	var p: P = _free.pop_back() if _free.size() > 0 else P.new()
	p.kind = kind
	p.pos = pos
	p.vel = vel
	p.life = life
	p.max_life = life
	p.color = col
	p.size = size
	p.drag = 0.92
	p.rot = randf() * TAU
	p.spin = randf_range(-8.0, 8.0)
	p.text = ""
	p.lw = 2.0
	parts.append(p)
	return p


func spark(pos: Vector2, col: Color, n := 8, speed := 300.0, life := 0.45, size := 3.0) -> void:
	for i in n:
		var v := Vector2.from_angle(randf() * TAU) * speed * randf_range(0.25, 1.0)
		_make(0, pos, v, life * randf_range(0.6, 1.2), col, size * randf_range(0.7, 1.3))


func emit(pos: Vector2, vel: Vector2, col: Color, life: float, size: float) -> void:
	var p := _make(0, pos, vel, life, col, size)
	if p != null:
		p.drag = 0.96


func shards(pos: Vector2, col: Color, n: int, speed: float, size: float) -> void:
	for i in n:
		var v := Vector2.from_angle(randf() * TAU) * speed * randf_range(0.3, 1.0)
		var p := _make(1, pos, v, randf_range(0.5, 0.9), col, size * randf_range(0.6, 1.2))
		if p != null:
			p.drag = 0.95


func ring(pos: Vector2, col: Color, radius := 60.0, life := 0.4, lw := 3.0) -> void:
	var p := _make(2, pos, Vector2.ZERO, life, col, radius)
	if p != null:
		p.lw = lw


func text(pos: Vector2, s: String, col: Color, size := 14) -> void:
	var p := _make(3, pos, Vector2(0, -70), 0.9, col, size)
	if p != null:
		p.text = s
		p.drag = 0.96


## Explosão padrão: a forma se "estilhaça".
func explode(pos: Vector2, col: Color, scale := 1.0) -> void:
	spark(pos, col, int(round(14 * scale)), 380.0 * scale, 0.5, 3.5)
	spark(pos, Color.WHITE, int(round(5 * scale)), 200.0 * scale, 0.3, 2.5)
	shards(pos, col, int(round(5 * scale)), 240.0 * scale, 9.0 * minf(scale, 2.0))
	ring(pos, col, 40.0 * scale, 0.35, 3.0)


func add_shake(amount: float) -> void:
	shake = maxf(shake, amount)


func flash(col: Color, amount: float) -> void:
	flash_color = col
	flash_a = maxf(flash_a, amount)


func step(dt: float) -> void:
	var j := 0
	for i in parts.size():
		var p: P = parts[i]
		p.life -= dt
		if p.life <= 0.0:
			_free.append(p)
			continue
		p.pos += p.vel * dt
		p.vel *= pow(p.drag, dt * 60.0)
		p.rot += p.spin * dt
		parts[j] = p
		j += 1
	parts.resize(j)
	shake = maxf(0.0, shake - dt * 40.0)
	flash_a = maxf(0.0, flash_a - dt * 2.5)
	queue_redraw()


func clear_all() -> void:
	for p in parts:
		_free.append(p)
	parts.clear()


func _draw() -> void:
	var gt := Neon.glow_tex()
	for p in parts:
		var t: float = p.life / p.max_life
		match p.kind:
			0:
				var s: float = p.size * 2.2 * (0.5 + 0.5 * t)
				draw_texture_rect(gt, Rect2(p.pos.x - s, p.pos.y - s, s * 2.0, s * 2.0), false, Color(p.color, t))
			1:
				var d: Vector2 = Vector2(cos(p.rot), sin(p.rot)) * p.size
				draw_line(p.pos - d, p.pos + d, Color(p.color, t * 0.3), 6.0, true)
				draw_line(p.pos - d, p.pos + d, Color(p.color, t), 2.0, true)
			2:
				var r: float = maxf(0.5, p.size * (1.0 - t * t))
				draw_arc(p.pos, r, 0.0, TAU, 40, Color(p.color, t * 0.3), p.lw * 3.0, true)
				draw_arc(p.pos, r, 0.0, TAU, 40, Color(p.color, t), p.lw * (0.5 + t), true)
			3:
				Neon.text(self, p.text, p.pos, int(p.size), Color(p.color, minf(1.0, t * 2.0)), HORIZONTAL_ALIGNMENT_CENTER, false)
