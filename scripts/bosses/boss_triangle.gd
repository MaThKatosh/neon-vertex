extends Boss
## TRIÂNGULO RIVAL — o seu reflexo invertido.
##   Fase 1: segue o seu X espelhado e devolve duas colunas de tiro (o meio fica livre).
##   Fase 2: leques de balas que ricocheteiam nas paredes.
##   Fase 3: "Trindade" — 3 cópias giram em volta dele e atiram; as cópias também levam dano.

var _tri_a := 0.0


func _define() -> void:
	boss_name = "TRIÂNGULO // RVL-03"
	color = Cfg.RED
	radius = 50.0
	phase_hp = [700, 780, 820]


func _animate(dt: float) -> void:
	_tri_a += dt * 1.1


func _copies() -> Array:
	var out := []
	for k in 3:
		out.append(position + Vector2.from_angle(_tri_a + k * TAU / 3.0) * 95.0)
	return out


func hit_points() -> Array:
	var pts := [[position, radius]]
	if phase == 2 and state == "fight":
		for c in _copies():
			pts.append([c, 22.0])
	return pts


func _phase(i: int, _dt: float) -> void:
	match i:
		0:
			var px: float = main.player.position.x
			move_to(Vector2(Cfg.W - px, 190.0), 1.4)
			if every("volley", 0.3):
				for k in [-1, 1]:
					bl.shoot(position + Vector2(k * 34.0, 40.0), PI / 2.0, 340.0, {"color": Cfg.RED, "needle": true})
			if every("ring", 2.0):
				bl.ring(position, 14, 140.0, randf() * TAU, {"color": Cfg.ORANGE})
		1:
			move_to(Vector2(Cfg.W / 2.0 + sin(pt * 0.8) * 150.0, 200.0), 2.0)
			if every("bounce", 1.3):
				bl.fan(position, PI / 2.0, 6, 2.2, 190.0, {"color": Cfg.RED, "bounce": 2, "r": 7.0})
				Sfx.play("enemy_shot")
			if every("aim", 1.7):
				bl.aim_fan(position, 3, 0.3, 240.0, {"color": Cfg.ORANGE, "needle": true})
		2:
			move_to(Vector2(Cfg.W / 2.0, 220.0), 2.0)
			if every("tri", 0.55):
				for c in _copies():
					bl.aim_fan(c, 2, 0.25, 220.0, {"color": Cfg.RED, "needle": true})
			if every("ring", 2.4):
				bl.ring(position, 18, 130.0, randf() * TAU, {"color": Cfg.ORANGE, "bounce": 1})


func _tri(c: Vector2, size: float, col: Color, w: float, fill: float) -> void:
	# triângulo apontando para baixo (o contrário do jogador)
	Neon.poly(self, PackedVector2Array([c + Vector2(0, size), c + Vector2(size * 0.85, -size * 0.6), c + Vector2(-size * 0.85, -size * 0.6)]), col, w, fill)


func _draw_body(col: Color) -> void:
	var wob := sin(t * 3.0) * 4.0
	_tri(Vector2(0, wob), 70.0, col, 3.0, 0.08)
	_tri(Vector2(0, wob), 42.0, col, 2.0, 0.12)
	Neon.poly(self, PackedVector2Array([Vector2(0, 18 + wob), Vector2(8, -2 + wob), Vector2(-8, -2 + wob)]), Cfg.MAGENTA, 1.4, 0.4)
	Neon.orb(self, Vector2(0, wob), 6.0, col)
	if phase == 2 and state == "fight":
		for c in _copies():
			_tri(c - position, 22.0, col, 2.0, 0.15)
