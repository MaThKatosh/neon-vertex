extends SceneTree
## Teste automático: menu, controles personalizáveis, loja (abas, bloqueios de elite), NEW GAME +,
## as 6 armas e os 10 chefes (todas as fases), escudo, revive, bomba nova, vitória, recompensas e morte.
## Joga em modo invencível; não grava nada no save.
## Rodar:  godot --headless --path . -s res://tests/smoke_test.gd

var main
var prof
var ctl
var sfx
var frame := 0
var step := "boot"
var wait := 0
var boss_seen := 0
var log_state := ""
var fails: Array = []


func _initialize() -> void:
	prof = root.get_node("Profile")
	ctl = root.get_node("Controls")
	sfx = root.get_node("Sfx")
	prof.save_enabled = false
	prof.credits = 200000
	prof.levels = {}
	prof.start_weapon = "spread"
	prof.ng_cleared = -1
	prof.ng_selected = 0
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)


func _check(cond: bool, msg: String) -> void:
	if not cond:
		fails.append(msg)
		print("  FALHOU: ", msg)


func _buy_all_in_tab(tab: int) -> void:
	main.shop_tab = tab
	var n: int = main.shop_cards().size()
	for i in n:
		for k in 6:
			main._shop_activate(i)


func _physics_process(_dt: float) -> bool:
	frame += 1
	var s: String = "%s/%s" % [main.state, main.phase]
	if s != log_state:
		log_state = s
		print("[%d] estado=%s setor=%d NG=%d balas=%d cr=%d" % [frame, s, main.stage_idx + 1, main.loop, main.bullets.list.size(), main.run_credits])
	if main.state == "playing" and step != "death":
		main.player.invuln = 999.0
	match step:
		"boot":
			if frame == 5:
				# síntese em fatias (versão Web): resultado igual ao normal e nenhuma fatia longa
				var sl = Synth.new()
				sl.recording = true
				sfx._compose(sl, "boss", 4)
				var slices := 0
				var worst := 0
				var done := false
				while not done:
					var t0 := Time.get_ticks_usec()
					done = sl.step(3000)
					worst = maxi(worst, Time.get_ticks_usec() - t0)
					slices += 1
				var full = sfx._build_track(Synth.new(), "boss", 4)
				var sliced = sl.finish_wav(true)
				_check(sliced.data.size() == full.data.size(), "trilha em fatias com tamanho diferente")
				_check(worst < 12000, "fatia de síntese longa demais: %d us" % worst)
				print("  síntese em fatias: %d fatias, pior fatia %.1f ms" % [slices, worst / 1000.0])
			if frame == 8:
				# OPÇÕES: idioma, volume e conforto visual
				_check(main.state == "title", "não começou no menu")
				main._on_title_menu(1)
				_check(main.state == "options", "menu OPÇÕES não abriu")
				prof.settings["lang"] = "pt"
				main._opt_adjust("lang", 1)
				_check(I18n.t("JOGAR") == "PLAY" and I18n.t("PONTOS  %d") % 5 == "SCORE  5", "tradução para inglês falhou")
				main._opt_adjust("lang", 1)
				_check(I18n.t("JOGAR") == "JOGAR", "voltar para português falhou")
				main._opt_adjust("music", -1)
				_check(absf(float(prof.settings["music"]) - 0.7) < 0.01, "volume da música não mudou")
				main._opt_adjust("shake", 1)
				_check(prof.shake_mult() == 0.5, "tremor não foi reduzido")
				main._opt_adjust("shake", 1)
				_check(prof.shake_mult() == 0.0, "tremor não foi desligado")
				main.fx.shake = 0.0
				main.fx.add_shake(10.0)
				_check(main.fx.shake == 0.0, "tremor desligado ainda treme")
				main._opt_adjust("shake", 1)
				_check(prof.shake_mult() == 1.0, "tremor não voltou ao normal")
				_check(Neon.font() != ThemeDB.fallback_font and Neon.title_font() != ThemeDB.fallback_font, "fontes não carregaram")
				main._menu_back()
				_check(main.state == "title", "voltar das opções falhou")
			if frame == 10:
				_check(main.state == "title", "não começou no menu")
				main._on_title_menu(2)
				_check(main.state == "controls", "menu CONTROLES não abriu")
			if frame == 12:
				# troca a tecla de BOMBA para B e confere no InputMap
				ctl.keys["bomb"][0] = KEY_B
				ctl.apply()
				var found := false
				for ev in InputMap.action_get_events("bomb"):
					if ev is InputEventKey and ev.physical_keycode == KEY_B:
						found = true
				_check(found, "troca de tecla não aplicada")
				ctl.reset_defaults(false)
				ctl.apply()
				main._ctl_adjust("sens", 1)
				_check(absf(ctl.touch_sens - 1.35) < 0.01, "ajuste de sensibilidade falhou")
				ctl.touch_focus_btn = true
				var lay: Array = ctl.touch_layout()
				_check(lay.size() == 3 and lay[2]["action"] == "focus", "botão de foco ausente no toque")
				main._to_title()
				main._on_title_menu(0)
				_check(main.state == "shop", "menu JOGAR não abriu o Hangar")
			if frame == 20:
				# elite bloqueada antes de zerar
				main.shop_tab = 2
				_check(prof.buy("prism") == "locked", "elite deveria estar bloqueada")
				_check(prof.ng_available() == 0, "NG+ deveria estar bloqueado")
				_buy_all_in_tab(0)
				_buy_all_in_tab(1)
				_check(prof.level("drones") == 3 and prof.level("shield") == 3 and prof.level("hearts") == 2, "upgrades básicos não subiram")
				# simula ter zerado tudo para liberar a elite e o NG+
				prof.clear_ng(10)
				_check(prof.ng_available() == 10, "NG+10 não liberou")
				_buy_all_in_tab(2)
				_check(prof.has("vertex") and prof.has("revive") and prof.has("drone3"), "elite não comprou")
				_check(prof.owned_weapons().size() == 6, "nem todas as armas ficaram disponíveis")
				prof.ng_selected = 2
				print("  loja ok: créditos restantes %d" % prof.credits)
			if frame == 30:
				main.shop_tab = 0
				main.shop_sel = main.shop_cards().size() + 2
				main._shop_activate(main.shop_sel)   # INICIAR
				_check(main.state == "playing" and main.loop == 2, "não iniciou no NG+2")
				_check(main.player.drone_pos.size() == 3 and main.player.lives == 5, "upgrades não aplicados")
				step = "waves"
		"waves":
			if main.phase == "waves" and main.stage_idx > 0 and main.pt < 30.0:
				main.pt = 45.0
			if main.phase == "boss" and main.boss != null:
				step = "boss"
				wait = 0
				boss_seen += 1
				var w: String = Cfg.WEAPONS[boss_seen % Cfg.WEAPONS.size()]
				main.player.weapon = w
				print("  chefe %d: %s  (arma: %s)" % [boss_seen, main.boss.boss_name, w])
		"boss":
			wait += 1
			var b = main.boss
			if b != null and b.state == "fight" and wait % 300 == 0:
				print("    fase %d: balas=%d tiros=%d vida=%.0f%%" % [b.phase, main.bullets.list.size(), main.bullets.shots.size(), b.frac() * 100.0])
				if boss_seen == 1 and b.phase == 0:
					main.player.invuln = 0.0
					main.player.shield = 0
					main.player.lives = 1
					main.player.hit()   # Segunda Chance deve salvar
					_check(not main.player.dead and main.player.lives == 2, "segunda chance falhou")
					main.player.invuln = 0.0
					main.player.bomb()   # bomba nova
				b.damage(99999.0)
			if main.state == "victory":
				print("VITÓRIA NG+%d no quadro %d, créditos: %d" % [main.loop, frame, main.run_credits])
				print("  resumo: ", main.summary)
				_check(sfx.tracks.has("stage4") and sfx.tracks.has("boss4"), "trilhas intensas não foram geradas")
				print("  trilhas: ", sfx.tracks.keys())
				step = "death"
				main._next_loop()
				_check(main.loop == 3, "não seguiu para o NG+3")
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
