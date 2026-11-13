extends Boss
## HEXÁGONO — chefe final, combina tudo.
##   Fase 1: muralhas de balas com 6 brechas giratórias.
##   Fase 2: invoca 2 torres hexagonais + espiral tripla.
##   Fase 3: dupla espiral em sentidos opostos + muralhas + leques.


func _define() -> void:
	boss_name = "HEXÁGONO // HEX-04"
	color = Cfg.PURPLE
	radius = 66.0
	phase_hp = [900, 950, 1100]


func _phase(i: int, _dt: float) -> void:
	match i:
		0:
			move_to(Vector2(Cfg.W / 2.0 + sin(pt * 0.6) * 110.0, 210.0), 2.0)
			if every("wall", 1.15):
				mem["o"] = mem.get("o", 0.0) + 0.23
				bl.gap_ring(position, 48, 150.0, mem["o"], 8, 2, {"color": Cfg.PURPLE})
			if every("aim", 0.9):
				bl.aim_fan(position, 3, 0.22, 270.0, {"color": Cfg.MAGENTA, "needle": true})
		1:
			move_to(Vector2(Cfg.W / 2.0, 190.0), 2.0)
			if every("summon", 9.0) and main.count_kind("turret") < 2:
				main.spawn("turret", 110.0, -40.0, {"ty": 380.0, "stay": 999.0})
				main.spawn("turret", Cfg.W - 110.0, -40.0, {"ty": 380.0, "stay": 999.0})
			if every("spiral", 0.11):
				mem["a"] = mem.get("a", 0.0) + 0.19
				for k in 3:
					bl.shoot(position, mem["a"] + k * TAU / 3.0, 180.0, {"color": Cfg.PURPLE})
			if every("aim", 1.5):
				bl.stack(position, bl.aim(position), 5, 230.0, 420.0, {"color": Cfg.MAGENTA, "needle": true})
		2:
			move_to(Vector2(Cfg.W / 2.0 + sin(pt * 0.8) * 90.0, 220.0), 2.0)
			if every("spiral", 0.09):
				mem["a"] = mem.get("a", 0.0) + 0.15
				for k in 3:
					bl.shoot(position, mem["a"] + k * TAU / 3.0, 190.0, {"color": Cfg.PURPLE})
					bl.shoot(position, -mem["a"] + k * TAU / 3.0 + 0.5, 190.0, {"color": Cfg.MAGENTA})
			if every("wall", 1.8):
				mem["o"] = mem.get("o", 0.0) + 0.4
				bl.gap_ring(position, 42, 130.0, mem["o"], 7, 2, {"color": Cfg.VIOLET, "r": 7.0})
			if every("aim", 2.3):
				bl.aim_fan(position, 7, 0.8, 250.0, {"color": Cfg.RED, "needle": true})


func _draw_body(col: Color) -> void:
	draw_poly_body(col, 6, 78.0)
