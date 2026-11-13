extends Boss
## PENTÁGONO — padrões em sequência baseados no número 5.
##   Fase 1: estrelas de 5 pontas que giram a cada rajada.
##   Fase 2: minas que freiam e explodem em anéis (balas que geram balas).
##   Fase 3: 5 braços giratórios que invertem o sentido + anéis lentos.


func _define() -> void:
	boss_name = "PENTÁGONO // PNT-04"
	color = Cfg.ORANGE
	radius = 60.0
	phase_hp = [750, 850, 880]


func _phase(i: int, _dt: float) -> void:
	match i:
		0:
			move_to(Vector2(Cfg.W / 2.0 + sin(pt * 0.7) * 120.0, 210.0), 2.5)
			if every("star", 0.75):
				mem["a"] = mem.get("a", 0.0) + 0.31
				for k in 5:
					bl.fan(position, mem["a"] + k * TAU / 5.0, 3, 0.2, 200.0, {"color": Cfg.ORANGE})
			if every("aim", 1.6):
				bl.aim_fan(position, 5, 0.5, 250.0, {"color": Cfg.YELLOW, "needle": true})
		1:
			move_to(Vector2(Cfg.W / 2.0 + sin(pt * 0.5) * 140.0, 200.0), 2.0)
			if every("mine", 1.35):
				for k in 5:
					var a := PI / 2.0 + (k - 2) * 0.45
					bl.shoot(position, a, 260.0, {"color": Cfg.YELLOW, "r": 13.0, "accel": -260.0,
						"min_speed": 0.0, "split_t": 1.0 + k * 0.06, "split": _mine_burst})
				Sfx.play("enemy_shot")
			if every("aim", 0.55):
				bl.shoot(position, bl.aim(position), 300.0, {"color": Cfg.RED, "needle": true})
		2:
			move_to(Vector2(Cfg.W / 2.0, 220.0), 2.0)
			if not mem.has("dir"):
				mem["dir"] = 1.0
				mem["a"] = PI / 2.0
				mem["flip"] = 0.0
			mem["flip"] += dt
			if mem["flip"] > 3.2:
				mem["flip"] = 0.0
				mem["dir"] = -mem["dir"]
			mem["a"] += mem["dir"] * 0.75 * dt
			if every("arm", 0.07):
				for k in 5:
					bl.shoot(position, mem["a"] + k * TAU / 5.0, 260.0, {"color": Cfg.RED, "needle": true})
			if every("ring", 1.3):
				bl.ring(position, 24, 120.0, randf() * TAU, {"color": Cfg.YELLOW})


func _mine_burst(p: Vector2) -> void:
	bl.ring(p, 12, 130.0, randf() * TAU, {"color": Cfg.ORANGE})
	main.fx.ring(p, Cfg.YELLOW, 40.0, 0.3, 2.0)


func _draw_body(col: Color) -> void:
	draw_poly_body(col, 5, 70.0)
