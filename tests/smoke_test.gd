extends SceneTree
## Teste automático rápido: joga o jogo sozinho (em modo invencível), passa por todos os
## setores e chefes e imprime o que aconteceu. Erros de script aparecem no console.
## Rodar:  godot --headless --path . -s res://tests/smoke_test.gd

var main
var frame := 0
var step := "boot"
var wait := 0
var boss_seen := 0
var log_state := ""


func _initialize() -> void:
	main = load("res://scenes/main.tscn").instantiate()
	main.save_enabled = false
	root.add_child(main)


func _physics_process(_dt: float) -> bool:
	frame += 1
	var s: String = "%s/%s" % [main.state, main.phase]
	if s != log_state:
		log_state = s
		print("[%d] estado=%s inimigos=%d balas=%d score=%d" % [frame, s, main.enemies.size(), main.bullets.list.size(), main.score])
	if main.state == "playing" and step != "death":
		main.player.invuln = 999.0   # modo deus para o teste
	match step:
		"boot":
			if frame > 30:
				main._new_game()
				step = "waves"
		"waves":
			# fase 1 com as ondas inteiras; nas demais pula rápido
			if main.phase == "waves" and main.stage_idx > 0 and main.pt < 30.0:
				main.pt = 45.0
			if main.phase == "boss" and main.boss != null:
				step = "boss"
				wait = 0
				boss_seen += 1
				# alterna a arma a cada chefe para testar todas
				main.collect("W", main.player.position, Cfg.WEAPONS[boss_seen % Cfg.WEAPONS.size()])
				print("  chefe: ", main.boss.boss_name, "  arma: ", main.player.weapon)
		"boss":
			wait += 1
			if main.boss != null and main.boss.state == "fight" and wait % 360 == 0:
				print("    fase %d: balas=%d  vida restante=%.0f%%  tiros do jogador=%d" % [main.boss.phase, main.bullets.list.size(), main.boss.frac() * 100.0, main.bullets.shots.size()])
				if main.boss.phase == 1:
					main.player.invuln = 0.0
					main.player.bombs = 2
					main.player.bomb()
				main.boss.damage(99999.0)
			if main.state == "victory":
				print("VITÓRIA alcançada no quadro ", frame)
				step = "death"
				main._next_loop()
				main.player.invuln = 0.0
			elif main.phase != "boss" and main.boss == null and main.phase == "waves":
				step = "waves"
		"death":
			wait += 1
			if main.state == "playing" and wait % 30 == 0:
				main.player.invuln = 0.0
				main.player.hit()
			if main.state == "gameover":
				print("GAME OVER ok. recorde=", main.hi)
				print("TESTE CONCLUIDO: chefes vistos=", boss_seen)
				quit(0)
	if frame > 60 * 60 * 12:
		print("TIMEOUT")
		quit(1)
	return false
