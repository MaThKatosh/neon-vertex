extends Boss
## QUADRADO — primeiro chefe (o "professor": ensina a ler padrões).
##   Fase 1: leques mirados + anéis lentos.
##   Fase 2: espiral de 4 braços (um por lado), com espaço para circular.
##   Fase 3: investidas laterais com aviso; deixam uma cortina rala de balas e explodem na parede.


func _define() -> void:
	boss_name = "QUADRADO // SQR-01"
	color = Cfg.YELLOW
	radius = 58.0
	phase_hp = [460, 520, 540]


func _phase(i: int, _dt: float) -> void:
	match i:
		0:
			move_to(Vector2(Cfg.W / 2.0 + sin(pt * 0.9) * 160.0, 200.0), 3.0)
			if every("aim", 1.1):
				bl.aim_fan(position + Vector2(0, 30), 3, 0.5, 210.0, {"color": Cfg.YELLOW, "r": 7.0})
				Sfx.play("enemy_shot")
			if every("ring", 2.8):
				bl.ring(position, 14, 130.0, randf() * TAU, {"color": Cfg.ORANGE})
		1:
			move_to(Vector2(Cfg.W / 2.0 + sin(pt * 0.5) * 60.0, 230.0), 2.0)
			if every("spin", 0.14):
				mem["a"] = mem.get("a", 0.0) + 0.2
				for k in 4:
					bl.shoot(position, mem["a"] + k * TAU / 4.0, 170.0, {"color": Cfg.YELLOW, "needle": true})
			if every("aim", 2.2):
				bl.stack(position, bl.aim(position), 3, 200.0, 320.0, {"color": Cfg.ORANGE, "r": 7.0})
		2:
			_dash()


func _dash() -> void:
	if not mem.has("s"):
		mem["s"] = "wait"
		mem["tt"] = 1.2
		mem["side"] = 1.0 if position.x < Cfg.W / 2.0 else -1.0
	mem["tt"] -= dt
	if mem["s"] == "wait":
		move_to(Vector2(position.x, 170.0), 4.0)
		# aviso: treme antes de investir
		if mem["tt"] < 0.4:
			position.x += randf_range(-2.5, 2.5)
		if mem["tt"] <= 0.0:
			mem["s"] = "dash"
			mem["tx"] = Cfg.W - 70.0 if mem["side"] > 0.0 else 70.0
			mem["side"] = -mem["side"]
			Sfx.play("dash")
	else:
		var tx: float = mem["tx"]
		var dir := signf(tx - position.x)
		position.x += dir * 700.0 * dt
		if every("trail", 0.07):
			bl.shoot(position + Vector2(0, 40), PI / 2.0 + randf_range(-0.12, 0.12), randf_range(100.0, 140.0), {"color": Cfg.YELLOW})
		if dir == 0.0 or (dir > 0.0 and position.x >= tx) or (dir < 0.0 and position.x <= tx):
			position.x = tx
			mem["s"] = "wait"
			mem["tt"] = 1.3
			bl.ring(position, 16, 150.0, randf() * TAU, {"color": Cfg.ORANGE})
			bl.aim_fan(position, 3, 0.5, 210.0, {"color": Cfg.RED, "needle": true})
			main.fx.add_shake(9.0)
			Sfx.play("slam")


func _draw_body(col: Color) -> void:
	draw_poly_body(col, 4, 66.0)
