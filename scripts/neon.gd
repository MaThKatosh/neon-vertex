class_name Neon
extends RefCounted
## Utilitários de desenho neon usados por todas as formas do jogo.
## O "brilho" vem de desenhar a mesma linha várias vezes: larga e fraca -> fina e forte -> núcleo branco.
## Além disso, cores com valor acima de 1.0 ("hot") estouram no glow do WorldEnvironment.

static var _glow: Texture2D
static var _core: Texture2D
static var _font: Font


static func glow_tex() -> Texture2D:
	if _glow == null:
		_glow = _radial([0.0, 0.2, 0.45, 1.0],
			[Color(1, 1, 1, 1), Color(1, 1, 1, 0.55), Color(1, 1, 1, 0.16), Color(1, 1, 1, 0)])
	return _glow


static func core_tex() -> Texture2D:
	if _core == null:
		_core = _radial([0.0, 0.6, 0.85, 1.0],
			[Color(1, 1, 1, 1), Color(1, 1, 1, 1), Color(1, 1, 1, 0.4), Color(1, 1, 1, 0)])
	return _core


static func _radial(offsets: Array, colors: Array) -> Texture2D:
	var g := Gradient.new()
	g.offsets = PackedFloat32Array(offsets)
	g.colors = PackedColorArray(colors)
	var t := GradientTexture2D.new()
	t.gradient = g
	t.width = 64
	t.height = 64
	t.fill = GradientTexture2D.FILL_RADIAL
	t.fill_from = Vector2(0.5, 0.5)
	t.fill_to = Vector2(1.0, 0.5)
	return t


## Fonte: coloque um .ttf em res://assets/fonts/game_font.ttf para trocar a fonte do jogo inteiro.
static func font() -> Font:
	if _font == null:
		if ResourceLoader.exists("res://assets/fonts/game_font.ttf"):
			_font = load("res://assets/fonts/game_font.ttf")
		else:
			_font = ThemeDB.fallback_font
	return _font


## Cor "quente" para HDR (brilha mais no glow).
static func hot(c: Color, k: float) -> Color:
	return Color(c.r * k, c.g * k, c.b * k, c.a)


static func regular(c: Vector2, r: float, sides: int, rot: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in sides:
		var a := rot + TAU * i / sides
		pts.append(c + Vector2(cos(a), sin(a)) * r)
	return pts


## Polígono fechado com brilho neon.
static func poly(ci: CanvasItem, pts: PackedVector2Array, col: Color, w: float, fill_a := 0.0) -> void:
	if fill_a > 0.0:
		ci.draw_colored_polygon(pts, Color(col, fill_a * col.a))
	var loop := pts.duplicate()
	loop.append(pts[0])
	ci.draw_polyline(loop, Color(col, 0.12 * col.a), w * 6.0, true)
	ci.draw_polyline(loop, Color(col, 0.3 * col.a), w * 2.6, true)
	ci.draw_polyline(loop, hot(col, 1.3), w, true)
	ci.draw_polyline(loop, Color(1, 1, 1, 0.65 * col.a), maxf(0.8, w * 0.35), true)


static func ring(ci: CanvasItem, c: Vector2, r: float, col: Color, w: float, fill_a := 0.0) -> void:
	if fill_a > 0.0:
		ci.draw_circle(c, r, Color(col, fill_a))
	arc(ci, c, r, 0.0, TAU, col, w)


static func arc(ci: CanvasItem, c: Vector2, r: float, a0: float, a1: float, col: Color, w: float) -> void:
	ci.draw_arc(c, r, a0, a1, 48, Color(col, 0.12), w * 6.0, true)
	ci.draw_arc(c, r, a0, a1, 48, Color(col, 0.3), w * 2.6, true)
	ci.draw_arc(c, r, a0, a1, 48, hot(col, 1.3), w, true)
	ci.draw_arc(c, r, a0, a1, 48, Color(1, 1, 1, 0.65), maxf(0.8, w * 0.35), true)


## Halo suave (textura radial tingida).
static func glow(ci: CanvasItem, pos: Vector2, radius: float, col: Color) -> void:
	ci.draw_texture_rect(glow_tex(), Rect2(pos.x - radius, pos.y - radius, radius * 2.0, radius * 2.0), false, col)


## Orbe: halo colorido + núcleo claro (visual padrão dos projéteis).
static func orb(ci: CanvasItem, pos: Vector2, r: float, col: Color) -> void:
	glow(ci, pos, r * 3.0, col)
	ci.draw_texture_rect(core_tex(), Rect2(pos.x - r, pos.y - r, r * 2.0, r * 2.0), false,
		hot(col.lerp(Color.WHITE, 0.65), 1.4))


## Texto centralizado verticalmente em `pos.y`.
static func text(ci: CanvasItem, s: String, pos: Vector2, size: int, col: Color,
		align := HORIZONTAL_ALIGNMENT_CENTER, glow_on := true) -> void:
	var f := font()
	var w := 1000.0
	var x := pos.x
	if align == HORIZONTAL_ALIGNMENT_CENTER:
		x -= w / 2.0
	elif align == HORIZONTAL_ALIGNMENT_RIGHT:
		x -= w
	var base := Vector2(x, pos.y + size * 0.36)
	if glow_on:
		ci.draw_string_outline(f, base, s, align, w, size, 9, Color(col, 0.18 * col.a))
		ci.draw_string_outline(f, base, s, align, w, size, 4, Color(col, 0.4 * col.a))
	ci.draw_string(f, base, s, align, w, size, col)


## Texto com aberração cromática ("glitch") — dois fantasmas coloridos + branco por cima.
static func glitch(ci: CanvasItem, s: String, pos: Vector2, size: int, t: float,
		c1: Color, c2: Color, alpha := 1.0) -> void:
	var j := 0.0
	if sin(t * 37.0) > 0.93:
		j = randf_range(-8.0, 8.0)
	var d := 2.5 + absf(j) * 0.5
	var dy := 2.0 if j != 0.0 else 0.0
	text(ci, s, pos + Vector2(-d + j, 0.0), size, Color(c1, alpha), HORIZONTAL_ALIGNMENT_CENTER, true)
	text(ci, s, pos + Vector2(d - j, dy), size, Color(c2, alpha), HORIZONTAL_ALIGNMENT_CENTER, true)
	text(ci, s, pos, size, Color(1, 1, 1, alpha), HORIZONTAL_ALIGNMENT_CENTER, false)
