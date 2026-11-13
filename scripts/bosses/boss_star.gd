extends Boss
## ESTRELA — cinco pontas, cinco lasers.
##   Fase 1: cada ponta dispara um leque para fora; a estrela gira e o padrão gira junto.
##   Fase 2: 5 lasers (com aviso) saem das pontas e giram devagar; entre eles, anéis lentos.
##   Fase 3: gira rápido soltando balas pela tangente das pontas + lasers giratórios.

const GOLD := Color(1.0, 0.78, 0.25)
var _dir := 1.0


func _define() -> void:
	boss_name = "ESTRELA // STR-06"
	color = GOLD
	radius = 56.0
	phase_hp = [1000, 1100, 1200]


func _tip_angle(k: int) -> float:
	return rot + k * TAU / 5.0 - PI / 2.0


func _tip(k: int) -> Vector2:
	return position + Vector2.from_angle(_tip_angle(k)) * 80.0


func _phase(i: int, _dt: float) -> void:
	match i:
		0:
			move_to(Vector2(Cfg.W / 2.0 + sin(pt * 0.6) * 120.0, 210.0), 2.0)
			if every("tips", 0.9):
				for k in 5:
					bl.fan(_tip(k), _tip_angle(k), 3, 0.3, 200.0, {"color": GOLD})
			if every("aim", 1.7):
				bl.stack(position, bl.aim(position), 4, 220.0, 380.0, {"color": Cfg.ORANGE, "needle": true})
		1:
			move_to(Vector2(Cfg.W / 2.0, 230.0), 2.0)
			if every("lasers", 3.4):
				_dir = -_dir
				for k in 5:
					bl.beam(position, _tip_angle(k), 0.9, 1.1, 18.0, GOLD, 0.35 * _dir)
			if every("ring", 0.9):
				bl.ring(position, 16, 120.0, randf() * TAU, {"color": Cfg.ORANGE})
		2:
			spin = 2.2
			move_to(Vector2(Cfg.W / 2.0 + sin(pt * 0.5) * 60.0, 220.0), 2.0)
			if every("tangent", 0.1):
				for k in 5:
					bl.shoot(_tip(k), _tip_angle(k) + PI / 2.0, 170.0, {"color": GOLD, "needle": true})
			if every("lasers", 4.2):
				_dir = -_dir
				for k in 5:
					bl.beam(position, _tip_angle(k) + 0.3, 1.0, 2.0, 16.0, Cfg.RED, 0.5 * _dir)


func _star(r_out: float, r_in: float, a0: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for k in 10:
		var r := r_out if k % 2 == 0 else r_in
		pts.append(Vector2.from_angle(a0 + k * TAU / 10.0 - PI / 2.0) * r)
	return pts


func _draw_body(col: Color) -> void:
	Neon.poly(self, _star(80.0, 34.0, rot), col, 3.0, 0.08)
	Neon.poly(self, _star(44.0, 18.0, -rot * 1.5), col, 2.0, 0.15)
	for k in 5:
		Neon.glow(self, Vector2.from_angle(_tip_angle(k)) * 80.0, 12.0, col)
	Neon.orb(self, Vector2.ZERO, 7.0 * (1.1 + sin(t * 7.0) * 0.15), col)
