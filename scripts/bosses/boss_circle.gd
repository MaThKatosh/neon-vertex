extends Boss
## CÍRCULO — o único sem vértices: explora movimento e rotação.
##   Fase 1: voa em "oito" soltando anéis.
##   Fase 2: flor de balas que curvam (dupla espiral).
##   Fase 3: quica pela arena como uma bola, explodindo em anéis a cada batida.


func _define() -> void:
	boss_name = "CÍRCULO // ORB-02"
	color = Cfg.MAGENTA
	radius = 56.0
	phase_hp = [650, 760, 720]


func _phase(i: int, _dt: float) -> void:
	match i:
		0:
			move_to(Vector2(Cfg.W / 2.0 + sin(pt * 1.1) * 170.0, 230.0 + sin(pt * 2.2) * 70.0), 3.0)
			if every("ring", 0.6):
				mem["o"] = mem.get("o", 0.0) + 0.17
				bl.ring(position, 18, 170.0, mem["o"], {"color": Cfg.MAGENTA})
			if every("aim", 1.9):
				bl.stack(position, bl.aim(position), 4, 250.0, 400.0, {"color": Cfg.PINK, "needle": true})
		1:
			move_to(Vector2(Cfg.W / 2.0, 260.0), 2.0)
			if every("spiral", 0.15):
				mem["a"] = mem.get("a", 0.0) + 0.21
				for k in 5:
					bl.shoot(position, mem["a"] + k * TAU / 5.0, 140.0, {"color": Cfg.MAGENTA, "ang_vel": 0.55})
					bl.shoot(position, -mem["a"] + k * TAU / 5.0, 140.0, {"color": Cfg.PINK, "ang_vel": -0.55})
			if every("aim", 2.4):
				bl.aim_fan(position, 3, 0.25, 260.0, {"color": Cfg.ORANGE, "needle": true})
		2:
			if not mem.has("v"):
				mem["v"] = Vector2(280.0, 210.0)
			var v: Vector2 = mem["v"]
			position += v * dt
			var bounced := false
			if position.x < 70.0 or position.x > Cfg.W - 70.0:
				v.x = -v.x
				position.x = clampf(position.x, 70.0, Cfg.W - 70.0)
				bounced = true
			if position.y < 110.0 or position.y > Cfg.H * 0.55:
				v.y = -v.y
				position.y = clampf(position.y, 110.0, Cfg.H * 0.55)
				bounced = true
			mem["v"] = v
			if bounced:
				bl.ring(position, 16, 150.0, randf() * TAU, {"color": Cfg.MAGENTA})
				main.fx.add_shake(4.0)
				Sfx.play("slam")
			if every("trail", 0.12):
				bl.shoot(position, (-v).angle() + randf_range(-0.5, 0.5), 90.0,
					{"color": Cfg.PINK, "r": 5.0, "accel": 60.0, "max_speed": 220.0})
			if every("aim", 1.4):
				bl.aim_fan(position, 3, 0.3, 250.0, {"color": Cfg.ORANGE, "needle": true})


func _draw_body(col: Color) -> void:
	Neon.ring(self, Vector2.ZERO, 60.0, col, 3.0, 0.08)
	for k in 3:
		var a0 := rot * 2.0 + k * TAU / 3.0
		Neon.arc(self, Vector2.ZERO, 42.0, a0, a0 + 1.3, col, 2.0)
	Neon.ring(self, Vector2.ZERO, 20.0, col, 1.6, 0.25)
	for k in 8:
		var a := -rot * 1.5 + k * TAU / 8.0
		Neon.orb(self, Vector2.from_angle(a) * 78.0, 3.0, col)
	Neon.orb(self, Vector2.ZERO, 7.0, col)
