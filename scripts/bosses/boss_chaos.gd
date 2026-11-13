extends Boss
## CAOS — o chefe final. Um polígono completamente irregular que se deforma o tempo todo
## e usa os poderes de todos os chefes anteriores, dois por fase:
##   1. Quadrado + Círculo   — quica pela arena soltando leques e anéis
##   2. Triângulo + Pentágono — espelha você com colunas de tiro e solta minas
##   3. Hexágono + Estrela    — muralhas com brechas e lasers giratórios
##   4. Gêmeos + Octógono     — escudo giratório + fogo cruzado das laterais
##   5. Tesserato + todos     — grade de lasers, espiral dupla e leques (desespero)

const PHASE_COLORS := [
	Color(1.0, 0.902, 0.0),     # quadrado
	Color(1.0, 0.231, 0.553),   # triângulo/pentágono
	Color(0.753, 0.302, 1.0),   # hexágono/estrela
	Color(0.176, 0.482, 1.0),   # gêmeos/octógono
	Color(1.0, 1.0, 1.0),       # tudo
]
const SHIELD_R := 104.0

var _base: Array = []
var _speed: Array = []
var _ph: Array = []
var shield_rot := 0.0
var _dir := 1.0


func _define() -> void:
	boss_name = "CAOS // ???-10"
	color = PHASE_COLORS[0]
	radius = 64.0
	phase_hp = [1200, 1300, 1400, 1500, 1800]
	for k in 11:
		_base.append(randf_range(55.0, 100.0))
		_speed.append(randf_range(1.5, 4.0))
		_ph.append(randf() * TAU)


func _animate(dt: float) -> void:
	color = PHASE_COLORS[mini(phase, PHASE_COLORS.size() - 1)]
	shield_rot += dt * 0.9 * _dir


func _shape(scale_: float, a0: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	var n := _base.size()
	for k in n:
		var r: float = _base[k] * (1.0 + 0.18 * sin(t * _speed[k] + _ph[k])) * scale_
		var a := a0 + k * TAU / n + 0.12 * sin(t * 1.3 + k)
		pts.append(Vector2.from_angle(a) * r)
	return pts


func blocks(p: Vector2) -> bool:
	if phase != 3 or state != "fight":
		return false
	var d := p.distance_to(position)
	if d < SHIELD_R - 16.0 or d > SHIELD_R + 16.0:
		return false
	var seg := int(wrapf((p - position).angle() - shield_rot, 0.0, TAU) / (TAU / 8.0)) % 8
	return seg != 0 and seg != 4


func _phase(i: int, dt_: float) -> void:
	var c: Color = color
	match i:
		0:   # Quadrado + Círculo
			if not mem.has("v"):
				mem["v"] = Vector2(210.0, 160.0)
			var v: Vector2 = mem["v"]
			position += v * dt_
			if position.x < 80.0 or position.x > Cfg.W - 80.0:
				v.x = -v.x
				position.x = clampf(position.x, 80.0, Cfg.W - 80.0)
				bl.ring(position, 14, 150.0, randf() * TAU, {"color": Cfg.MAGENTA})
			if position.y < 120.0 or position.y > Cfg.H * 0.45:
				v.y = -v.y
				position.y = clampf(position.y, 120.0, Cfg.H * 0.45)
				bl.ring(position, 14, 150.0, randf() * TAU, {"color": Cfg.MAGENTA})
			mem["v"] = v
			if every("fan", 0.9):
				bl.aim_fan(position, 5, 0.55, 230.0, {"color": c, "r": 7.0})
		1:   # Triângulo + Pentágono
			var px: float = main.player.position.x
			move_to(Vector2(Cfg.W - px, 190.0), 1.4)
			if every("volley", 0.3):
				for k in [-1, 1]:
					bl.shoot(position + Vector2(k * 34.0, 40.0), PI / 2.0, 330.0, {"color": Cfg.RED, "needle": true})
			if every("mine", 1.8):
				for k in 5:
					bl.shoot(position, PI / 2.0 + (k - 2) * 0.5, 250.0, {"color": c, "r": 13.0, "accel": -250.0,
						"split_t": 1.0 + k * 0.06, "split": _mine_burst})
		2:   # Hexágono + Estrela
			move_to(Vector2(Cfg.W / 2.0, 220.0), 2.0)
			if every("wall", 1.4):
				mem["o"] = mem.get("o", 0.0) + 0.3
				bl.gap_ring(position, 44, 140.0, mem["o"], 11, 3, {"color": c})
			if every("lasers", 3.8):
				_dir = -_dir
				var a0 := randf() * TAU
				for k in 3:
					bl.beam(position, a0 + k * TAU / 3.0, 1.0, 1.4, 18.0, Color(1.0, 0.78, 0.25), 0.4 * _dir)
		3:   # Gêmeos + Octógono
			move_to(Vector2(Cfg.W / 2.0 + sin(pt * 0.5) * 80.0, 210.0), 2.0)
			if every("flip", 3.0):
				_dir = -_dir
			if every("cross", 0.5):
				var y := 260.0 + sin(pt * 0.9) * 180.0
				bl.stack(Vector2(-10.0, y), 0.12, 3, 170.0, 250.0, {"color": Color(1.0, 0.231, 0.553), "needle": true})
				bl.stack(Vector2(Cfg.W + 10.0, Cfg.H * 0.62 - y * 0.5), PI - 0.12, 3, 170.0, 250.0, {"color": Color(0.482, 0.361, 1.0), "needle": true})
			if every("aim", 1.2):
				bl.aim_fan(position, 3, 0.3, 240.0, {"color": c})
		4:   # Tesserato + todos
			spin = 2.5
			move_to(Vector2(Cfg.W / 2.0 + sin(pt * 1.3) * 60.0, 210.0 + sin(pt * 2.1) * 25.0), 2.0)
			if every("grid", 5.0):
				_laser_grid()
			if every("spiral", 0.11):
				mem["a"] = mem.get("a", 0.0) + 0.17
				for k in 2:
					bl.shoot(position, mem["a"] + k * PI, 170.0, {"color": c})
					bl.shoot(position, -mem["a"] + k * PI + 0.5, 170.0, {"color": Cfg.MAGENTA})
			if every("fan", 1.7):
				bl.aim_fan(position, 7, 0.9, 240.0, {"color": Cfg.YELLOW, "needle": true})


func _mine_burst(p: Vector2) -> void:
	bl.ring(p, 10, 130.0, randf() * TAU, {"color": Cfg.ORANGE})
	main.fx.ring(p, Cfg.YELLOW, 40.0, 0.3, 2.0)


func _laser_grid() -> void:
	var cols := [0, 1, 2, 3, 4, 5]
	cols.shuffle()
	for k in 2:
		bl.beam(Vector2(45.0 + cols[k] * 90.0, -20.0), PI / 2.0, 1.2, 1.0, 24.0, Cfg.MAGENTA, 0.0, 1100.0)
	var rows := [0, 1, 2, 3]
	rows.shuffle()
	bl.beam(Vector2(-20.0, 520.0 + rows[0] * 100.0), 0.0, 1.2, 1.0, 24.0, Cfg.MAGENTA, 0.0, 600.0)


func _draw_body(col: Color) -> void:
	Neon.poly(self, _shape(1.0, rot), col, 3.0, 0.08)
	Neon.poly(self, _shape(0.55, -rot * 1.7), col.lerp(Cfg.MAGENTA, 0.3), 2.0, 0.12)
	Neon.poly(self, _shape(0.25, rot * 3.0), Cfg.WHITE, 1.4, 0.3)
	for v in _shape(1.0, rot):
		Neon.glow(self, v, 9.0, col)
	Neon.orb(self, Vector2.ZERO, 7.0 * (1.1 + sin(t * 9.0) * 0.2), col)
	if phase == 3 and state == "fight":
		var seg := TAU / 8.0
		for k in 8:
			if k == 0 or k == 4:
				continue
			var a0 := shield_rot + k * seg + 0.05
			Neon.arc(self, Vector2.ZERO, SHIELD_R, a0, a0 + seg - 0.1, Cfg.BLUE.lerp(Cfg.WHITE, 0.25), 3.0)
