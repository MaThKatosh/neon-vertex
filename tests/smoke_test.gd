extends SceneTree
## Teste automático: compra upgrades na loja, joga sozinho (modo invencível) pelos 10 setores,
## passa por TODAS as fases de todos os chefes, testa escudo/bomba/morte e o depósito de créditos.
## Erros de script aparecem no console. Não grava nada no save.
## Rodar:  godot --headless --path . -s res://tests/smoke_test.gd

var main
var frame := 0
var step := "boot"
var wait := 0
var boss_seen := 0
var log_state := ""
var fails: Array = []


func _initialize() -> void:
	var prof = root.get_node("Profile")
	prof.save_enabled = false
	prof.credits = 100000
	prof.levels = {}
	prof.start_weapon = "spread"
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)


func _check(cond: bool, msg: String) -> void:
	if not cond:
		fails.append(msg)
		print("  FALHOU: ", msg)


func _physics_process(_dt: float) -> bool:
	frame += 1
	var prof = root.get_node("Profile")
	var s: String = "%s/%s" % [main.state, main.phase]
	if s != log_state:
		log_state = s
		print("[%d] estado=%s setor=%d inimigos=%d balas=%d cr=%d" % [frame, s, main.stage_idx + 1, main.enemies.size(), main.bullets.list.size(), main.run_credits])
	if main.state == "playing" and step != "death":
		main.player.invuln = 999.0   # modo deus para o teste
	match step:
		"boot":
			if frame == 20:
				main._open_shop()
			if frame == 30:
				# compra tudo de todos os upgrades pela loja
				var before: int = prof.credits
				var rows: Array = main.shop_rows()
				for i in rows.size():
					if rows[i]["type"] == "up":
						for k in 6:
							main._shop_activate(i)
				_check(prof.credits < before, "loja não cobrou créditos")
				_check(prof.level("drones") == 3 and prof.level("shield") == 3, "upgrades não subiram de nível")
				_check(prof.buy("hearts") == "max", "compra além do máximo deveria falhar")
				prof.start_weapon = "spread"
				prof.cycle_start_weapon()
				_check(prof.start_weapon == "laser", "troca de arma inicial falhou")
				print("  loja ok: créditos %d -> %d, arma inicial %s" % [before, prof.credits, prof.start_weapon])
			if frame == 40:
				main._shop_activate(0)   # INICIAR MISSÃO
				_check(main.state == "playing", "INICIAR não começou a partida")
				_check(main.player.lives == 5 and main.player.drone_pos.size() == 2 and main.player.shield == 3, "upgrades não aplicados ao jogador")
				step = "waves"
		"waves":
			if main.phase == "waves" and main.stage_idx > 0 and main.pt < 30.0:
				main.pt = 45.0   # setor 1 roda completo; os outros pulam as ondas
			if main.phase == "boss" and main.boss != null:
				step = "boss"
				wait = 0
				boss_seen += 1
				main.collect("W", main.player.position, Cfg.WEAPONS[boss_seen % Cfg.WEAPONS.size()])
				print("  chefe %d: %s  (arma: %s)" % [boss_seen, main.boss.boss_name, main.player.weapon])
		"boss":
			wait += 1
			var b = main.boss
			if b != null and b.state == "fight" and wait % 330 == 0:
				print("    fase %d: balas=%d lasers=%d vida=%.0f%%" % [b.phase, main.bullets.list.size(), main.bullets.beams.size(), b.frac() * 100.0])
				if b.phase == 1 and boss_seen == 1:
					# escudo: absorve sem perder coração
					main.player.invuln = 0.0
					var lives: int = main.player.lives
					main.player.hit()
					_check(main.player.lives == lives and main.player.shield == 2, "escudo não absorveu o acerto")
					main.player.invuln = 0.0
					main.player.bomb()
				b.damage(99999.0)
			if main.state == "victory":
				print("VITÓRIA no quadro %d, créditos da partida: %d" % [frame, main.run_credits])
				_check(main.run_credits > Cfg.CLEAR_BONUS, "bônus de vitória não somado")
				step = "death"
				main._next_loop()
				main.player.invuln = 0.0
			elif main.boss == null and main.phase == "waves":
				step = "waves"
		"death":
			wait += 1
			if main.state == "playing" and wait % 30 == 0:
				main.player.invuln = 0.0
				main.player.shield = 0
				main.player.hit()
			if main.state == "gameover":
				print("GAME OVER ok. resumo: ", main.summary)
				_check(boss_seen == 10, "nem todos os chefes apareceram (%d)" % boss_seen)
				print("TESTE CONCLUIDO: chefes vistos=%d  falhas=%d" % [boss_seen, fails.size()])
				quit(0 if fails.is_empty() else 1)
	if frame > 60 * 60 * 25:
		print("TIMEOUT")
		quit(1)
	return false
