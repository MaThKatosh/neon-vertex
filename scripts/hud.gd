extends Node2D
## Interface (fica num CanvasLayer, então não treme com a câmera):
## HUD, barra do chefe, faixas de aviso, botões de toque, menus e tela inicial.

var main

var _scan := PackedVector2Array()


func _ready() -> void:
	# linhas de varredura estilo CRT
	var y := 0.0
	while y < Cfg.H:
		_scan.append(Vector2(0, y))
		_scan.append(Vector2(Cfg.W, y))
		y += 3.0


func _draw() -> void:
	var m = main
	if m.state == "title":
		_title()
	elif m.state == "shop":
		_shop()
	else:
		_hud()
		if m.boss != null:
			_boss_bar(m.boss)
		if m.banner != null:
			_banner(m.banner)
		if m.state == "playing" and Controls.is_touch:
			_touch_buttons()
		match m.state:
			"paused":
				_menu_screen("PAUSA", Cfg.CYAN, ["ESC / START PARA VOLTAR", "créditos desta missão já estão salvos"])
			"gameover":
				_menu_screen("FIM DE JOGO", Cfg.RED, m.summary)
			"victory":
				_menu_screen("VITÓRIA", Cfg.LIME, ["O CAOS FOI CONTIDO"] + m.summary)
	if m.fx.flash_a > 0.0:
		draw_rect(Rect2(0, 0, Cfg.W, Cfg.H), Color(m.fx.flash_color, m.fx.flash_a * 0.6))
	draw_multiline(_scan, Color(0, 0, 0, 0.16), 1.0)


func _hud() -> void:
	var m = main
	var p = m.player
	var top := Color(Cfg.BG, 0.92)
	var clear := Color(Cfg.BG, 0.0)
	draw_polygon(PackedVector2Array([Vector2(0, 0), Vector2(Cfg.W, 0), Vector2(Cfg.W, 80), Vector2(0, 80)]),
		PackedColorArray([top, top, clear, clear]))
	Neon.text(self, "SCORE", Vector2(18, 18), 11, Cfg.CYAN, HORIZONTAL_ALIGNMENT_LEFT, false)
	Neon.text(self, "%08d" % m.score, Vector2(18, 40), 22, Cfg.WHITE, HORIZONTAL_ALIGNMENT_LEFT, true)
	Neon.text(self, "HI %08d" % maxi(Profile.hi, m.score), Vector2(18, 62), 11, Cfg.MAGENTA, HORIZONTAL_ALIGNMENT_LEFT, false)

	var n: int = maxi(p.lives, Profile.max_lives())
	for i in n:
		_heart(Vector2(Cfg.W - 28.0 - i * 28.0, 30.0), 10.0, i < p.lives)
	# créditos da partida + cargas de escudo
	Neon.text(self, "+%d CR" % m.run_credits, Vector2(Cfg.W - 16.0, 58.0), 12, Cfg.YELLOW, HORIZONTAL_ALIGNMENT_RIGHT, false)
	for i in p.shield:
		draw_arc(Vector2(Cfg.W - 120.0 - i * 18.0, 58.0), 6.0, 0.0, TAU, 20, Cfg.WHITE, 2.0, true)
	Neon.text(self, "SETOR %02d" % (m.stage_idx + 1), Vector2(Cfg.W / 2.0, 66.0), 10, Color(1, 1, 1, 0.5), HORIZONTAL_ALIGNMENT_CENTER, false)

	# arma atual + nível de poder
	var wc: Color = Cfg.WEAPON_COLORS[p.weapon]
	Neon.text(self, Cfg.WEAPON_NAMES[p.weapon], Vector2(18, Cfg.H - 66), 11, wc, HORIZONTAL_ALIGNMENT_LEFT, true)
	for i in Cfg.MAX_POWER:
		var c := wc if i < p.power else Color(wc, 0.15)
		draw_rect(Rect2(82.0 + i * 16.0, Cfg.H - 71.0, 12.0, 10.0), c)
	Neon.text(self, "BOMBA", Vector2(18, Cfg.H - 40), 11, Cfg.YELLOW, HORIZONTAL_ALIGNMENT_LEFT, false)
	for i in p.bombs:
		Neon.poly(self, Neon.regular(Vector2(90.0 + i * 20.0, Cfg.H - 40.0), 7.0, 6, PI / 6.0), Cfg.YELLOW, 1.4, 0.35)


func _heart(c: Vector2, s: float, full: bool) -> void:
	var pts := PackedVector2Array()
	for i in 24:
		var a := TAU * i / 24.0
		var x := 16.0 * pow(sin(a), 3.0)
		var y := -(13.0 * cos(a) - 5.0 * cos(2.0 * a) - 2.0 * cos(3.0 * a) - cos(4.0 * a))
		pts.append(c + Vector2(x, y) * (s / 16.0))
	if full:
		Neon.poly(self, pts, Cfg.PINK, 2.0, 0.5)
	else:
		Neon.poly(self, pts, Color(0.35, 0.14, 0.25), 1.2, 0.0)


func _boss_bar(b) -> void:
	var x := 24.0
	var y := 96.0
	var w := Cfg.W - 48.0
	var h := 6.0
	var f: float = b.frac()
	if b.state == "enter":
		f *= minf(1.0, b.st / 2.0)
	b.disp_frac = lerpf(b.disp_frac, f, 0.08) if b.disp_frac > f else f
	var col: Color = b.color
	Neon.text(self, b.boss_name, Vector2(x, y - 12.0), 11, col, HORIZONTAL_ALIGNMENT_LEFT, true)
	draw_rect(Rect2(x, y, w, h), Color(1, 1, 1, 0.08))
	draw_rect(Rect2(x, y, w * b.disp_frac, h), Color(1, 1, 1, 0.5))   # dano recente
	draw_rect(Rect2(x, y - 2.0, w * f, h + 4.0), Color(col, 0.25))
	draw_rect(Rect2(x, y, w * f, h), Neon.hot(col, 1.4))
	# marcas das fases
	var total := 0.0
	for v in b.phase_hp:
		total += v
	var acc := 0.0
	var n: int = b.phase_hp.size()
	for i in range(n - 1, 0, -1):
		acc += b.phase_hp[i]
		draw_rect(Rect2(x + w * acc / total - 1.5, y - 2.0, 3.0, h + 4.0), Cfg.BG)


func _banner(bn: Dictionary) -> void:
	var k: float = bn["t"] / bn["dur"]
	var al := 1.0
	if k < 0.15:
		al = k / 0.15
	elif k > 0.8:
		al = (1.0 - k) / 0.2
	var col: Color = bn["color"]
	var y := Cfg.H * 0.38
	draw_rect(Rect2(0, y - 50.0, Cfg.W, 100.0), Color(col, 0.1 * al))
	draw_line(Vector2(0, y - 50.0), Vector2(Cfg.W, y - 50.0), Color(col, 0.8 * al), 2.0)
	draw_line(Vector2(0, y + 50.0), Vector2(Cfg.W, y + 50.0), Color(col, 0.8 * al), 2.0)
	Neon.glitch(self, bn["title"], Vector2(Cfg.W / 2.0, y - 8.0), 44, main.t, col, Cfg.WHITE, al)
	Neon.text(self, bn["sub"], Vector2(Cfg.W / 2.0, y + 30.0), 14, Color(col, al))


func _touch_buttons() -> void:
	var p = main.player
	Neon.ring(self, Vector2(270, 34), 20.0, Cfg.CYAN, 1.4, 0.08)
	draw_rect(Rect2(262, 25, 5, 18), Cfg.CYAN)
	draw_rect(Rect2(273, 25, 5, 18), Cfg.CYAN)
	var bc := Vector2(474, 874)
	Neon.ring(self, bc, 40.0, Cfg.YELLOW, 2.0, 0.12 if p.bombs > 0 else 0.02)
	Neon.text(self, "B", bc + Vector2(0, -5), 24, Cfg.YELLOW)
	Neon.text(self, "x%d" % p.bombs, bc + Vector2(0, 18), 12, Cfg.YELLOW, HORIZONTAL_ALIGNMENT_CENTER, false)


func _menu_screen(title: String, col: Color, lines: Array) -> void:
	var m = main
	draw_rect(Rect2(0, 0, Cfg.W, Cfg.H), Color(Cfg.BG, 0.75))
	Neon.glitch(self, title, Vector2(Cfg.W / 2.0, Cfg.H * 0.3), 46, m.t, col, Cfg.CYAN)
	for i in lines.size():
		var lc := Cfg.YELLOW if str(lines[i]).begins_with("CRÉDITOS") else Cfg.WHITE
		Neon.text(self, lines[i], Vector2(Cfg.W / 2.0, Cfg.H * 0.38 + i * 30.0), 16, lc, HORIZONTAL_ALIGNMENT_CENTER, false)
	for i in m.menu_items.size():
		var y: float = m.menu_y(i)
		var sel: bool = i == m.menu_sel
		if sel:
			Neon.poly(self, PackedVector2Array([Vector2(90, y - 24), Vector2(450, y - 24), Vector2(450, y + 24), Vector2(90, y + 24)]), Cfg.CYAN, 1.6, 0.08)
		var c := Cfg.CYAN if sel else Color(0.55, 0.5, 0.65)
		Neon.text(self, m.menu_items[i], Vector2(Cfg.W / 2.0, y), 20, c, HORIZONTAL_ALIGNMENT_CENTER, sel)


func _title() -> void:
	var tm: float = main.t
	var c := Vector2(Cfg.W / 2.0, Cfg.H * 0.5)
	# os chefes orbitando
	var shapes := [[4, Cfg.YELLOW], [0, Cfg.MAGENTA], [3, Cfg.RED], [5, Cfg.ORANGE], [6, Cfg.PURPLE], [8, Cfg.BLUE]]
	for i in shapes.size():
		var a := tm * 0.4 + i * TAU / shapes.size()
		var pos := c + Vector2(cos(a) * 190.0, sin(a) * 50.0)
		var s := 26.0 + sin(a) * 8.0
		var sides: int = shapes[i][0]
		var col: Color = shapes[i][1]
		if sides > 0:
			Neon.poly(self, Neon.regular(pos, s, sides, tm * (0.5 + i * 0.2)), col, 2.0, 0.08)
		else:
			Neon.ring(self, pos, s * 0.9, col, 2.0, 0.08)
	# o jogador
	var y := c.y + sin(tm * 2.0) * 6.0
	Neon.poly(self, PackedVector2Array([Vector2(c.x, y - 30), Vector2(c.x + 21, y + 20), Vector2(c.x, y + 10), Vector2(c.x - 21, y + 20)]), Cfg.CYAN, 2.6, 0.12)

	Neon.glitch(self, "NEON", Vector2(c.x, Cfg.H * 0.2), 76, tm, Cfg.MAGENTA, Cfg.CYAN)
	Neon.glitch(self, "VERTEX", Vector2(c.x, Cfg.H * 0.2 + 78.0), 60, tm + 1.3, Cfg.CYAN, Cfg.MAGENTA)
	Neon.text(self, "SHOOT'EM UP GEOMÉTRICO", Vector2(c.x, Cfg.H * 0.2 + 134.0), 14, Cfg.YELLOW)

	if int(tm * 2.0) % 2 == 0:
		var prompt := "TOQUE PARA JOGAR" if Controls.is_touch else "PRESSIONE ENTER"
		Neon.text(self, prompt, Vector2(c.x, Cfg.H * 0.65), 22, Cfg.WHITE)

	var hint := Color(0.75, 0.7, 0.9)
	if Controls.is_touch:
		Neon.text(self, "ARRASTE EM QUALQUER LUGAR PARA MOVER", Vector2(c.x, Cfg.H * 0.74), 12, hint, HORIZONTAL_ALIGNMENT_CENTER, false)
		Neon.text(self, "TIRO AUTOMÁTICO  •  BOTÃO B = BOMBA", Vector2(c.x, Cfg.H * 0.74 + 24.0), 12, hint, HORIZONTAL_ALIGNMENT_CENTER, false)
	else:
		Neon.text(self, "WASD / SETAS: MOVER    SHIFT: FOCO", Vector2(c.x, Cfg.H * 0.74), 12, hint, HORIZONTAL_ALIGNMENT_CENTER, false)
		Neon.text(self, "X: BOMBA    ESC: PAUSA    M: SOM", Vector2(c.x, Cfg.H * 0.74 + 24.0), 12, hint, HORIZONTAL_ALIGNMENT_CENTER, false)
		Neon.text(self, "CONTROLE: ANALÓGICO  •  B: BOMBA  •  LB/RB: FOCO", Vector2(c.x, Cfg.H * 0.74 + 48.0), 12, hint, HORIZONTAL_ALIGNMENT_CENTER, false)
	Neon.text(self, "RECORDE  %08d" % Profile.hi, Vector2(c.x, Cfg.H * 0.9), 13, Cfg.MAGENTA)
	Neon.text(self, "CRÉDITOS  %d   •   MELHOR SETOR  %d/10" % [Profile.credits, Profile.best_stage], Vector2(c.x, Cfg.H * 0.9 + 26.0), 12, Cfg.YELLOW, HORIZONTAL_ALIGNMENT_CENTER, false)


# ------------------------------------------------------------------ Hangar (loja)

func _shop() -> void:
	var m = main
	var cx := Cfg.W / 2.0
	draw_rect(Rect2(0, 0, Cfg.W, Cfg.H), Color(Cfg.BG, 0.55))
	Neon.glitch(self, "HANGAR", Vector2(cx, 60.0), 46, m.t, Cfg.CYAN, Cfg.MAGENTA)
	Neon.text(self, "CRÉDITOS  %d" % Profile.credits, Vector2(cx, 112.0), 20, Cfg.YELLOW, HORIZONTAL_ALIGNMENT_CENTER, true)
	Neon.text(self, "partidas: %d   •   melhor setor: %d/10" % [Profile.runs, Profile.best_stage], Vector2(cx, 140.0), 11, Color(1, 1, 1, 0.5), HORIZONTAL_ALIGNMENT_CENTER, false)

	var rows: Array = m.shop_rows()
	var desc := ""
	for i in rows.size():
		var row: Dictionary = rows[i]
		var y: float = m.shop_row_y(i)
		var sel: bool = i == m.shop_sel
		if sel:
			Neon.poly(self, PackedVector2Array([Vector2(16, y - 21), Vector2(Cfg.W - 16, y - 21), Vector2(Cfg.W - 16, y + 21), Vector2(16, y + 21)]), Cfg.CYAN, 1.4, 0.08)
		match row["type"]:
			"start":
				Neon.text(self, ">>  INICIAR MISSÃO  <<", Vector2(cx, y), 20, Cfg.LIME if sel else Color(Cfg.LIME, 0.7), HORIZONTAL_ALIGNMENT_CENTER, sel)
				if sel:
					desc = "Toda partida começa no Setor 01. Morra, compre upgrades, volte mais forte."
			"weapon":
				var w: String = Profile.start_weapon
				var wc: Color = Cfg.WEAPON_COLORS[w]
				Neon.text(self, "ARMA INICIAL", Vector2(32, y), 15, Cfg.WHITE, HORIZONTAL_ALIGNMENT_LEFT, false)
				Neon.text(self, "<  %s  >" % Cfg.WEAPON_NAMES[w], Vector2(Cfg.W - 32.0, y), 15, wc, HORIZONTAL_ALIGNMENT_RIGHT, sel)
				if sel:
					desc = "Escolha com as setas laterais (ou toque). Laser e Enxame precisam ser liberados na loja."
			"up":
				var id: String = row["id"]
				var u: Dictionary = Profile.upgrade_def(id)
				var lv: int = Profile.level(id)
				var mx: int = Profile.max_level(id)
				var cost: int = Profile.next_cost(id)
				Neon.text(self, u["name"], Vector2(32, y), 15, Cfg.WHITE if sel else Color(0.8, 0.8, 0.9), HORIZONTAL_ALIGNMENT_LEFT, false)
				for k in mx:
					var px := 250.0 + k * 18.0
					var on := k < lv
					draw_rect(Rect2(px, y - 5.0, 12.0, 10.0), Cfg.CYAN if on else Color(Cfg.CYAN, 0.15))
				var ctext := "MÁX" if cost < 0 else "%d CR" % cost
				var ccol := Cfg.LIME if cost < 0 else (Cfg.YELLOW if Profile.credits >= cost else Color(Cfg.RED, 0.8))
				Neon.text(self, ctext, Vector2(Cfg.W - 32.0, y), 15, ccol, HORIZONTAL_ALIGNMENT_RIGHT, false)
				if sel:
					desc = u["desc"]
	# descrição do item selecionado + mensagem de compra
	var dy := Cfg.SHOP_Y0 + rows.size() * Cfg.SHOP_ROW_H + 6.0
	Neon.text(self, desc, Vector2(cx, dy), 12, Color(0.85, 0.85, 1.0), HORIZONTAL_ALIGNMENT_CENTER, false)
	if m.shop_msg_t > 0.0:
		Neon.text(self, m.shop_msg, Vector2(cx, dy + 26.0), 14, Cfg.YELLOW, HORIZONTAL_ALIGNMENT_CENTER, true)
	var hint := "toque: seleciona  •  toque de novo: compra" if Controls.is_touch else "cima/baixo: escolher  •  ENTER comprar  •  ESC voltar"
	Neon.text(self, hint, Vector2(cx, Cfg.H - 22.0), 11, Color(1, 1, 1, 0.45), HORIZONTAL_ALIGNMENT_CENTER, false)
