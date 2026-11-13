extends Boss
## OCTÓGONO FORTALEZA — protegido por um escudo de 8 placas que GIRA. Seus tiros só passam pelas brechas.
##   Fase 1: 2 brechas; muralhas de balas + tiros mirados.
##   Fase 2: 3 brechas; os 8 canhões disparam filas em sequência, como um relógio.
##   Fase 3: 4 brechas girando rápido e trocando de sentido; anéis que aceleram.

const SHIELD_R := 104.0
const SHIELD_W := 16.0

var shield_rot := 0.0
var gaps: Array = [0, 4]
var _spin_dir := 1.0


func _define() -> void:
	boss_name = "OCTÓGONO // OCT-08"
	color = Cfg.BLUE
	radius = 60.0
	phase_hp = [1200, 1300, 1400]


func _animate(dt: float) -> void:
	var speed := [0.5, 0.7, 1.3][mini(phase, 2)] as float
	shield_rot += speed * _spin_dir * dt


func _segment_at(p: Vector2) -> int:
	var a := wrapf((p - position).angle() - shield_rot, 0.0, TAU)
	return int(a / (TAU / 8.0)) % 8


func blocks(p: Vector2) -> bool:
	if state == "dying":
		return false
	var d := p.distance_to(position)
	if d < SHIELD_R - SHIELD_W or d > SHIELD_R + SHIELD_W:
		return false
	return not gaps.has(_segment_at(p))


func _phase(i: int, _dt: float) -> void:
	match i:
		0:
			gaps = [0, 4]
			move_to(Vector2(Cfg.W / 2.0 + sin(pt * 0.5) * 90.0, 220.0), 2.0)
			if every("wall", 1.3):
				bl.gap_ring(position, 40, 140.0, shield_rot, 10, 2, {"color": Cfg.BLUE})
			if every("aim", 1.0):
				bl.aim_fan(position, 3, 0.25, 240.0, {"color": Cfg.PURPLE, "needle": true})
		1:
			gaps = [0, 3, 6]
			move_to(Vector2(Cfg.W / 2.0, 210.0), 2.0)
			if every("cannon", 0.14):
				var k: int = mem.get("k", 0)
				mem["k"] = k + 1
				var a := rot + k * TAU / 8.0
				bl.stack(position + Vector2.from_angle(a) * 70.0, a, 3, 150.0, 240.0, {"color": Cfg.BLUE})
			if every("aim", 1.8):
				bl.aim_fan(position, 5, 0.5, 230.0, {"color": Cfg.PURPLE})
		2:
			gaps = [0, 2, 4, 6]
			move_to(Vector2(Cfg.W / 2.0 + sin(pt * 0.7) * 70.0, 220.0), 2.0)
			if every("flip", 2.5):
				_spin_dir = -_spin_dir
			if every("burst", 1.0):
				bl.ring(position, 32, 60.0, randf() * TAU, {"color": Cfg.BLUE, "accel": 120.0, "max_speed": 260.0})
			if every("aim", 1.3):
				bl.stack(position, bl.aim(position), 4, 220.0, 380.0, {"color": Cfg.PURPLE, "needle": true})


func _draw_body(col: Color) -> void:
	draw_poly_body(col, 8, 62.0)
	# placas do escudo (as brechas não são desenhadas)
	var seg := TAU / 8.0
	for k in 8:
		if gaps.has(k):
			continue
		var a0 := shield_rot + k * seg + 0.05
		Neon.arc(self, Vector2.ZERO, SHIELD_R, a0, a0 + seg - 0.1, Cfg.BLUE.lerp(Cfg.WHITE, 0.25), 3.0)
