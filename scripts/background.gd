extends Node2D
## Fundo: grade neon rolando + riscos de velocidade. A cor muda a cada setor.

var color := Cfg.MAGENTA
var speed := 1.0

var _scroll := 0.0
var _streaks: Array = []   # Vector3(x, y, profundidade)


func _ready() -> void:
	z_index = -10
	for i in 60:
		_streaks.append(Vector3(randf() * Cfg.W, randf() * Cfg.H, randf_range(0.2, 1.0)))


func step(dt: float) -> void:
	_scroll = fmod(_scroll + 90.0 * speed * dt, 64.0)
	for i in _streaks.size():
		var s: Vector3 = _streaks[i]
		s.y += (150.0 + 650.0 * s.z) * s.z * speed * dt
		if s.y > Cfg.H + 30.0:
			s.y = -30.0
			s.x = randf() * Cfg.W
		_streaks[i] = s
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(-40, -40, Cfg.W + 80, Cfg.H + 80), Cfg.BG)

	# névoa colorida no topo e na base
	var clear := Color(color, 0.0)
	draw_polygon(PackedVector2Array([Vector2(-40, -40), Vector2(Cfg.W + 40, -40), Vector2(Cfg.W + 40, Cfg.H * 0.5), Vector2(-40, Cfg.H * 0.5)]),
		PackedColorArray([Color(color, 0.16), Color(color, 0.16), clear, clear]))
	draw_polygon(PackedVector2Array([Vector2(-40, Cfg.H * 0.6), Vector2(Cfg.W + 40, Cfg.H * 0.6), Vector2(Cfg.W + 40, Cfg.H + 40), Vector2(-40, Cfg.H + 40)]),
		PackedColorArray([clear, clear, Color(color, 0.1), Color(color, 0.1)]))

	# grade
	var lines := PackedVector2Array()
	var x := 0.0
	while x <= Cfg.W:
		lines.append(Vector2(x, -40))
		lines.append(Vector2(x, Cfg.H + 40))
		x += 54.0
	var y := _scroll - 64.0
	while y <= Cfg.H + 40.0:
		lines.append(Vector2(-40, y))
		lines.append(Vector2(Cfg.W + 40, y))
		y += 64.0
	draw_multiline(lines, Color(color, 0.05), 5.0)
	draw_multiline(lines, Color(color, 0.15), 1.0)

	# riscos de velocidade
	var near := PackedVector2Array()
	var far := PackedVector2Array()
	for s in _streaks:
		var ln: float = 6.0 + s.z * 26.0
		if s.z > 0.6:
			near.append(Vector2(s.x, s.y))
			near.append(Vector2(s.x, s.y - ln))
		else:
			far.append(Vector2(s.x, s.y))
			far.append(Vector2(s.x, s.y - ln))
	if near.size() > 0:
		draw_multiline(near, Color(0.62, 0.86, 1.0, 0.4), 1.2)
	if far.size() > 0:
		draw_multiline(far, Color(0.62, 0.86, 1.0, 0.15), 1.2)
