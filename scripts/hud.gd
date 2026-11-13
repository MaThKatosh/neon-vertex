extends Node2D
## Interface (fica num CanvasLayer, então não treme com a câmera):
## HUD, barra do chefe, faixas de aviso, botões de toque, menus, Hangar, tela de controles e tela inicial.

const TAB_COLORS := [Color(0.0, 0.94, 1.0), Color(1.0, 0.902, 0.0), Color(0.753, 0.302, 1.0)]

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
	match m.state:
		"title":
			_title()
		"shop":
			_shop()
		"controls":
			_controls()
		"options":
			_options()
		_:
			_hud()
			if m.boss != null:
				_boss_bar(m.boss)
			if m.banner != null:
				_banner(m.banner)
			if m.state == "playing" and Controls.is_touch:
				_touch_buttons()
			match m.state:
				"paused":
					_menu_screen("PAUSA", Cfg.CYAN, ["ESC / START PARA VOLTAR", "os créditos desta missão já estão salvos"])
				"gameover":
					_menu_screen("FIM DE JOGO", Cfg.RED, m.summary)
				"victory":
					_menu_screen("VITÓRIA", Cfg.LIME, ["O CAOS FOI CONTIDO"] + m.summary)
	if m.fx.flash_a > 0.0:
		draw_rect(Rect2(0, 0, Cfg.W, Cfg.H), Color(m.fx.flash_color, m.fx.flash_a * 0.6))
	draw_multiline(_scan, Color(0, 0, 0, 0.16), 1.0)


# ------------------------------------------------------------------ utilidades de desenho

func _box(r: Rect2, col: Color, fill_a: float, w := 1.6) -> void:
	if fill_a > 0.0:
		draw_rect(r, Color(col, fill_a))
	Neon.poly(self, PackedVector2Array([r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)]), col, w, 0.0)


func _panel(r: Rect2) -> void:
	draw_rect(r, Color(Cfg.BG, 0.88))


func _heart(c: Vector2, s: float, full: bool, col := Cfg.PINK) -> void:
	var pts := PackedVector2Array()
	for i in 24:
		var a := TAU * i / 24.0
		var x := 16.0 * pow(sin(a), 3.0)
		var y := -(13.0 * cos(a) - 5.0 * cos(2.0 * a) - 2.0 * cos(3.0 * a) - cos(4.0 * a))
		pts.append(c + Vector2(x, y) * (s / 16.0))
	if full:
		Neon.poly(self, pts, col, 2.0, 0.5)
	else:
		Neon.poly(self, pts, Color(0.35, 0.14, 0.25), 1.2, 0.0)


## Ícone de cada upgrade (desenhado com formas, sem imagens).
func _icon(kind: String, c: Vector2, col: Color) -> void:
	if kind.begins_with("w:"):
		var w := kind.substr(2)
		var wc: Color = Cfg.WEAPON_COLORS[w]
		Neon.poly(self, PackedVector2Array([c + Vector2(0, -14), c + Vector2(11, 10), c + Vector2(0, 4), c + Vector2(-11, 10)]), wc, 1.8, 0.2)
		Neon.text(self, Cfg.WEAPON_LETTER[w], c + Vector2(13, 10), 11, wc, HORIZONTAL_ALIGNMENT_CENTER, false)
		return
	match kind:
		"heart":
			_heart(c + Vector2(0, -2), 11.0, true, col)
		"shield":
			draw_arc(c, 13.0, 0.0, TAU, 32, col, 2.0, true)
			draw_arc(c, 7.0, 0.0, TAU, 24, Color(col, 0.6), 2.0, true)
		"bomb":
			Neon.poly(self, Neon.regular(c, 12.0, 6, PI / 6.0), col, 1.8, 0.3)
		"clock":
			draw_arc(c, 13.0, 0.0, TAU, 32, col, 2.0, true)
			draw_line(c, c + Vector2(0, -9), col, 2.0)
			draw_line(c, c + Vector2(6, 3), col, 2.0)
		"magnet":
			draw_arc(c + Vector2(0, -2), 10.0, 0.0, PI, 20, col, 4.0, true)
			draw_line(c + Vector2(-10, -2), c + Vector2(-10, -12), col, 4.0)
			draw_line(c + Vector2(10, -2), c + Vector2(10, -12), col, 4.0)
		"power":
			Neon.poly(self, PackedVector2Array([c + Vector2(0, -13), c + Vector2(11, 8), c + Vector2(-11, 8)]), col, 1.8, 0.2)
			draw_line(c + Vector2(0, 4), c + Vector2(0, -6), col, 2.0)
		"damage":
			for k in 8:
				var a := k * TAU / 8.0
				var r := 13.0 if k % 2 == 0 else 7.0
				draw_line(c, c + Vector2.from_angle(a) * r, col, 2.0)
		"rate":
			for k in 3:
				var y := c.y + 8.0 - k * 8.0
				draw_polyline(PackedVector2Array([Vector2(c.x - 9, y + 4), Vector2(c.x, y - 3), Vector2(c.x + 9, y + 4)]), col, 2.0, true)
		"drones":
			for k in 3:
				var d := c + Vector2(-10 + k * 10, 4 if k != 1 else -6)
				Neon.poly(self, PackedVector2Array([d + Vector2(0, -6), d + Vector2(5, 4), d + Vector2(-5, 4)]), col, 1.4, 0.2)
		"coin":
			draw_arc(c, 12.0, 0.0, TAU, 32, col, 2.0, true)
			Neon.text(self, "CR", c, 10, col, HORIZONTAL_ALIGNMENT_CENTER, false)
		"revive":
			draw_arc(c, 11.0, -PI * 0.2, PI * 1.5, 28, col, 2.4, true)
			Neon.poly(self, PackedVector2Array([c + Vector2(8, -14), c + Vector2(14, -6), c + Vector2(4, -6)]), col, 1.4, 0.6)
		_:
			Neon.poly(self, Neon.regular(c, 12.0, 4, 0.0), col, 1.8, 0.2)


func _menu_items(m) -> void:
	for i in m.menu_items.size():
		var y: float = m.menu_y(i)
		var sel: bool = i == m.menu_sel
		if sel:
			_box(Rect2(80, y - 24, Cfg.W - 160, 48), Cfg.CYAN, 0.08, 1.6)
		var c := Cfg.CYAN if sel else Color(0.6, 0.55, 0.7)
		Neon.text(self, m.menu_items[i], Vector2(Cfg.W / 2.0, y), 20, c, HORIZONTAL_ALIGNMENT_CENTER, sel)


# ------------------------------------------------------------------ HUD de jogo

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
	Neon.text(self, "+%d CR" % m.run_credits, Vector2(Cfg.W - 16.0, 58.0), 12, Cfg.YELLOW, HORIZONTAL_ALIGNMENT_RIGHT, false)
	for i in p.shield:
		draw_arc(Vector2(Cfg.W - 120.0 - i * 18.0, 58.0), 6.0, 0.0, TAU, 20, Cfg.WHITE, 2.0, true)
	var mode := I18n.t("SETOR %02d") % (m.stage_idx + 1)
	if m.loop > 0:
		mode += "  •  NG+%d" % m.loop
	Neon.text(self, mode, Vector2(Cfg.W / 2.0, 66.0), 10, Color(1, 1, 1, 0.55), HORIZONTAL_ALIGNMENT_CENTER, false)

	# arma + poder + bombas (vão para o outro lado quando os botões de toque estão à esquerda)
	var bx := 18.0
	if Controls.is_touch and Controls.touch_left:
		bx = Cfg.W - 200.0
	var wc: Color = Cfg.WEAPON_COLORS[p.weapon]
	Neon.text(self, Cfg.WEAPON_NAMES[p.weapon], Vector2(bx, Cfg.H - 66), 11, wc, HORIZONTAL_ALIGNMENT_LEFT, true)
	for i in Cfg.MAX_POWER:
		var c := wc if i < p.power else Color(wc, 0.15)
		draw_rect(Rect2(bx + 64.0 + i * 16.0, Cfg.H - 71.0, 12.0, 10.0), c)
	Neon.text(self, "BOMBA", Vector2(bx, Cfg.H - 40), 11, Cfg.YELLOW, HORIZONTAL_ALIGNMENT_LEFT, false)
	for i in p.bombs:
		Neon.poly(self, Neon.regular(Vector2(bx + 72.0 + i * 20.0, Cfg.H - 40.0), 7.0, 6, PI / 6.0), Cfg.YELLOW, 1.4, 0.35)


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
	for b in Controls.touch_layout():
		var c: Vector2 = b["pos"]
		match b["action"]:
			"pause":
				Neon.ring(self, c, 20.0, Cfg.CYAN, 1.4, 0.08)
				draw_rect(Rect2(c.x - 8, c.y - 9, 5, 18), Cfg.CYAN)
				draw_rect(Rect2(c.x + 3, c.y - 9, 5, 18), Cfg.CYAN)
			"bomb":
				Neon.ring(self, c, 40.0, Cfg.YELLOW, 2.0, 0.12 if p.bombs > 0 else 0.02)
				Neon.text(self, "B", c + Vector2(0, -5), 24, Cfg.YELLOW)
				Neon.text(self, "x%d" % p.bombs, c + Vector2(0, 18), 12, Cfg.YELLOW, HORIZONTAL_ALIGNMENT_CENTER, false)
			"focus":
				var held := Controls.touch_focus
				Neon.ring(self, c, 34.0, Cfg.WHITE, 1.6, 0.25 if held else 0.04)
				Neon.text(self, "FOCO", c, 13, Cfg.WHITE, HORIZONTAL_ALIGNMENT_CENTER, held)


func _menu_screen(title: String, col: Color, lines: Array) -> void:
	var m = main
	draw_rect(Rect2(0, 0, Cfg.W, Cfg.H), Color(Cfg.BG, 0.78))
	Neon.glitch(self, title, Vector2(Cfg.W / 2.0, Cfg.H * 0.27), 46, m.t, col, Cfg.CYAN)
	# cada linha é um texto ou [texto, cor]
	for i in lines.size():
		var line := ""
		var lc := Cfg.WHITE
		if lines[i] is Array:
			line = str(lines[i][0])
			lc = lines[i][1]
		else:
			line = str(lines[i])
		Neon.text(self, line, Vector2(Cfg.W / 2.0, Cfg.H * 0.35 + i * 28.0), 15, lc, HORIZONTAL_ALIGNMENT_CENTER, lc == Cfg.PURPLE)
	_menu_items(m)


# ------------------------------------------------------------------ tela inicial

func _title() -> void:
	var m = main
	var tm: float = m.t
	var c := Vector2(Cfg.W / 2.0, Cfg.H * 0.42)
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
	var y := c.y + sin(tm * 2.0) * 6.0
	Neon.poly(self, PackedVector2Array([Vector2(c.x, y - 30), Vector2(c.x + 21, y + 20), Vector2(c.x, y + 10), Vector2(c.x - 21, y + 20)]), Cfg.CYAN, 2.6, 0.12)

	Neon.glitch(self, "NEON", Vector2(c.x, Cfg.H * 0.15), 80, tm, Cfg.MAGENTA, Cfg.CYAN)
	Neon.glitch(self, "VERTEX", Vector2(c.x, Cfg.H * 0.15 + 82.0), 64, tm + 1.3, Cfg.CYAN, Cfg.MAGENTA)

	_menu_items(m)

	var hint := Color(0.75, 0.7, 0.9)
	var hy := Cfg.H * 0.8
	if Controls.is_touch:
		Neon.text(self, "ARRASTE EM QUALQUER LUGAR PARA MOVER", Vector2(c.x, hy), 12, hint, HORIZONTAL_ALIGNMENT_CENTER, false)
		Neon.text(self, "SEGURE FOCO: LENTO  •  B: BOMBA  •  TIRO AUTOMÁTICO", Vector2(c.x, hy + 22.0), 12, hint, HORIZONTAL_ALIGNMENT_CENTER, false)
	else:
		var keys := [Controls.binding_text("up", 1), Controls.binding_text("down", 1), Controls.binding_text("focus", 0), Controls.binding_text("bomb", 0)].map(func(k): return I18n.t(k))
		Neon.text(self, I18n.t("%s/%s: MOVER   %s: FOCO   %s: BOMBA") % keys, Vector2(c.x, hy), 12, hint, HORIZONTAL_ALIGNMENT_CENTER, false)
		Neon.text(self, "TIRO AUTOMÁTICO  •  TECLAS PERSONALIZÁVEIS EM CONTROLES", Vector2(c.x, hy + 22.0), 12, hint, HORIZONTAL_ALIGNMENT_CENTER, false)
	Neon.text(self, I18n.t("RECORDE  %08d") % Profile.hi, Vector2(c.x, Cfg.H * 0.9), 13, Cfg.MAGENTA)
	var ng := I18n.t("  •  NG+%d CONCLUÍDO") % Profile.ng_cleared if Profile.ng_cleared > 0 else (I18n.t("  •  JOGO ZERADO") if Profile.ng_cleared == 0 else "")
	Neon.text(self, I18n.t("CRÉDITOS  %d%s") % [Profile.credits, ng], Vector2(c.x, Cfg.H * 0.9 + 26.0), 12, Cfg.YELLOW, HORIZONTAL_ALIGNMENT_CENTER, false)


# ------------------------------------------------------------------ Hangar (loja)

func _shop() -> void:
	var m = main
	var cx := Cfg.W / 2.0
	draw_rect(Rect2(0, 0, Cfg.W, Cfg.H), Color(Cfg.BG, 0.6))

	# cabeçalho
	Neon.glitch(self, "HANGAR", Vector2(cx, 54.0), 44, m.t, Cfg.CYAN, Cfg.MAGENTA)
	_box(Rect2(cx - 110, 88, 220, 36), Cfg.YELLOW, 0.1, 1.4)
	Neon.text(self, "%d CR" % Profile.credits, Vector2(cx, 106.0), 20, Cfg.YELLOW, HORIZONTAL_ALIGNMENT_CENTER, true)

	# abas
	for k in Cfg.SHOP_TABS.size():
		var tx: float = m.shop_tab_x(k)
		var on: bool = k == m.shop_tab
		var tc: Color = TAB_COLORS[k]
		var r := Rect2(tx - 76, Cfg.SHOP_TAB_Y - 17, 152, 34)
		_box(r, tc if on else Color(tc, 0.35), 0.22 if on else 0.0, 1.8 if on else 1.0)
		var label: String = Cfg.SHOP_TABS[k][1]
		Neon.text(self, label, Vector2(tx, Cfg.SHOP_TAB_Y), 15, tc if on else Color(tc, 0.5), HORIZONTAL_ALIGNMENT_CENTER, on)
	var accent: Color = TAB_COLORS[m.shop_tab]

	# cartões
	var cards: Array = m.shop_cards()
	var n := cards.size()
	for i in range(m.shop_scroll, mini(n, m.shop_scroll + Cfg.SHOP_VISIBLE)):
		_card(cards[i], m.shop_card_y(i), i == m.shop_sel, accent)
	# indicadores de rolagem
	if m.shop_scroll > 0:
		draw_colored_polygon(PackedVector2Array([Vector2(cx - 10, 205), Vector2(cx + 10, 205), Vector2(cx, 195)]), Color(accent, 0.7))
	if m.shop_scroll + Cfg.SHOP_VISIBLE < n:
		var ly := Cfg.SHOP_LIST_Y0 + Cfg.SHOP_VISIBLE * Cfg.SHOP_CARD_H - 34.0
		draw_colored_polygon(PackedVector2Array([Vector2(cx - 10, ly), Vector2(cx + 10, ly), Vector2(cx, ly + 10)]), Color(accent, 0.7))

	# painel inferior: arma, modo e iniciar
	draw_line(Vector2(18, 712), Vector2(Cfg.W - 18, 712), Color(1, 1, 1, 0.15), 1.0)
	var w: String = Profile.start_weapon
	_selector(Cfg.SHOP_WEAPON_Y, "ARMA INICIAL", Cfg.WEAPON_NAMES[w], Cfg.WEAPON_COLORS[w], m.shop_sel == n)
	var ng: int = Profile.ng_selected
	var ngc := Cfg.WHITE if ng == 0 else Color.from_hsv(0.0 - ng * 0.03 + 1.0, 0.75, 1.0)
	_selector(Cfg.SHOP_NG_Y, "MODO", Profile.ng_label(ng), ngc, m.shop_sel == n + 1)
	if m.shop_sel == n + 1:
		var info := "liberado só depois de zerar o jogo" if Profile.ng_available() == 0 else \
			I18n.t("vida x%.2f  •  tiros +%d%%  •  créditos x%.2f") % [1.0 + ng * 0.25, ng * 10, 1.0 + ng * 0.25]
		Neon.text(self, info, Vector2(cx, Cfg.SHOP_NG_Y + 34.0), 10, Color(1, 1, 1, 0.6), HORIZONTAL_ALIGNMENT_CENTER, false)

	var start_sel: bool = m.shop_sel == n + 2
	var sr := Rect2(56, Cfg.SHOP_START_Y - 28, Cfg.W - 112, 56)
	_box(sr, Cfg.LIME, 0.22 if start_sel else 0.08, 2.4 if start_sel else 1.4)
	Neon.text(self, "INICIAR MISSÃO", Vector2(cx, Cfg.SHOP_START_Y), 22, Cfg.LIME, HORIZONTAL_ALIGNMENT_CENTER, start_sel)

	# mensagem de compra + dica
	if m.shop_msg_t > 0.0:
		Neon.text(self, m.shop_msg, Vector2(cx, 918.0), 14, m.shop_msg_col, HORIZONTAL_ALIGNMENT_CENTER, true)
	else:
		var hint := "toque no preço para comprar  •  arraste para rolar" if Controls.is_touch \
			else "cima/baixo: escolher  •  esq/dir: abas  •  ENTER: comprar  •  ESC: voltar"
		Neon.text(self, hint, Vector2(cx, 918.0), 10, Color(1, 1, 1, 0.45), HORIZONTAL_ALIGNMENT_CENTER, false)


func _card(id: String, cy: float, sel: bool, accent: Color) -> void:
	var u: Dictionary = Profile.upgrade_def(id)
	var lv: int = Profile.level(id)
	var mx: int = Profile.max_level(id)
	var cost: int = Profile.next_cost(id)
	var avail: bool = Profile.is_available(id)
	var r := Rect2(18, cy - 35, Cfg.W - 36, 70)
	_panel(r)
	var border := accent if sel else Color(accent, 0.3 if avail else 0.15)
	_box(r, border, 0.07 if sel else 0.0, 2.0 if sel else 1.0)

	# ícone
	var ic := Vector2(56, cy)
	_box(Rect2(ic.x - 24, cy - 24, 48, 48), Color(accent, 0.5 if avail else 0.2), 0.08, 1.0)
	_icon(u["icon"], ic, accent if avail else Color(0.5, 0.5, 0.6))

	# nome, descrição e nível
	var name_col := Cfg.WHITE if avail else Color(0.6, 0.6, 0.7)
	Neon.text(self, u["name"], Vector2(94, cy - 16), 15, name_col, HORIZONTAL_ALIGNMENT_LEFT, sel and avail)
	var desc: String = u["desc"] if avail else I18n.t("Para liberar: ") + Profile.req_text(id)
	Neon.text(self, desc, Vector2(94, cy + 5), 11, Color(0.75, 0.75, 0.88) if avail else Color(0.75, 0.55, 1.0, 0.8), HORIZONTAL_ALIGNMENT_LEFT, false)
	for k in mx:
		var on := k < lv
		draw_rect(Rect2(94 + k * 20, cy + 21, 16, 5), accent if on else Color(accent, 0.15))

	# botão de preço
	var br := Rect2(Cfg.W - 128, cy - 18, 100, 36)
	if not avail:
		_box(br, Color(0.75, 0.55, 1.0, 0.6), 0.05, 1.0)
		var r_txt: String = "ZERAR" if int(u.get("req", 0)) == 0 else "NG+%d" % int(u["req"])
		Neon.text(self, r_txt, br.get_center(), 13, Color(0.8, 0.6, 1.0), HORIZONTAL_ALIGNMENT_CENTER, false)
	elif cost < 0:
		_box(br, Cfg.LIME, 0.1, 1.2)
		Neon.text(self, "MÁX", br.get_center(), 15, Cfg.LIME, HORIZONTAL_ALIGNMENT_CENTER, true)
	else:
		var can: bool = Profile.credits >= cost
		var pc := Cfg.YELLOW if can else Color(Cfg.RED, 0.8)
		_box(br, pc, 0.16 if (can and sel) else 0.05, 1.8 if can else 1.0)
		Neon.text(self, "%d" % cost, br.get_center() + Vector2(-8, 0), 16, pc, HORIZONTAL_ALIGNMENT_CENTER, can)
		Neon.text(self, "CR", br.get_center() + Vector2(32, 1), 10, pc, HORIZONTAL_ALIGNMENT_CENTER, false)


func _selector(y: float, label: String, value: String, col: Color, sel: bool) -> void:
	if sel:
		_box(Rect2(18, y - 22, Cfg.W - 36, 44), Cfg.CYAN, 0.07, 1.4)
	Neon.text(self, label, Vector2(32, y), 14, Cfg.WHITE if sel else Color(0.75, 0.75, 0.88), HORIZONTAL_ALIGNMENT_LEFT, false)
	var vx := Cfg.W - 140.0
	draw_colored_polygon(PackedVector2Array([Vector2(vx - 92, y), Vector2(vx - 82, y - 8), Vector2(vx - 82, y + 8)]), Color(col, 0.8))
	draw_colored_polygon(PackedVector2Array([Vector2(vx + 92, y), Vector2(vx + 82, y - 8), Vector2(vx + 82, y + 8)]), Color(col, 0.8))
	Neon.text(self, value, Vector2(vx, y), 14, col, HORIZONTAL_ALIGNMENT_CENTER, sel)


# ------------------------------------------------------------------ tela de controles

func _controls() -> void:
	var m = main
	var cx := Cfg.W / 2.0
	draw_rect(Rect2(0, 0, Cfg.W, Cfg.H), Color(Cfg.BG, 0.7))
	Neon.glitch(self, "CONTROLES", Vector2(cx, 54.0), 40, m.t, Cfg.CYAN, Cfg.MAGENTA)
	Neon.text(self, "TECLADO E CONTROLE", Vector2(24, 112), 11, Cfg.CYAN, HORIZONTAL_ALIGNMENT_LEFT, false)
	var heads := ["TECLA 1", "TECLA 2", "CONTROLE"]
	for c in 3:
		Neon.text(self, heads[c], Vector2(m.ctl_col_x(c), 112), 10, Color(1, 1, 1, 0.5), HORIZONTAL_ALIGNMENT_CENTER, false)

	var rows: Array = m.ctl_rows()
	for i in rows.size():
		var row: Dictionary = rows[i]
		var y: float = m.ctl_row_y(i)
		var sel: bool = i == m.ctl_sel
		var t: String = row["type"]
		if i == Controls.ACTIONS.size():
			Neon.text(self, "TOQUE (CELULAR)", Vector2(24, y - 30), 11, Cfg.PINK, HORIZONTAL_ALIGNMENT_LEFT, false)
		if sel and t != "action":
			_box(Rect2(18, y - 18, Cfg.W - 36, 36), Cfg.CYAN, 0.07, 1.2)
		var name_col := Cfg.WHITE if sel else Color(0.75, 0.75, 0.88)
		match t:
			"action":
				var id: String = row["id"]
				Neon.text(self, Controls.ACTION_NAMES[id], Vector2(24, y), 13, name_col, HORIZONTAL_ALIGNMENT_LEFT, false)
				for c in 3:
					var cell := Rect2(m.ctl_col_x(c) - 44, y - 15, 88, 30)
					var on: bool = sel and c == m.ctl_col
					var waiting: bool = Controls.capturing == id and Controls.capture_slot == c
					if waiting:
						var blink := 0.5 + 0.5 * absf(sin(m.t * 8.0))
						_box(cell, Cfg.YELLOW, 0.2 * blink, 1.8)
						Neon.text(self, "APERTE...", cell.get_center(), 10, Cfg.YELLOW, HORIZONTAL_ALIGNMENT_CENTER, true)
					else:
						_box(cell, Cfg.CYAN if on else Color(1, 1, 1, 0.18), 0.12 if on else 0.0, 1.6 if on else 1.0)
						Neon.text(self, Controls.binding_text(id, c), cell.get_center(), 10, Cfg.WHITE if on else Color(0.85, 0.85, 1.0), HORIZONTAL_ALIGNMENT_CENTER, false)
			"sens":
				_setting(y, "SENSIBILIDADE DO ARRASTO", "%.2fx" % Controls.touch_sens, name_col, sel)
			"side":
				_setting(y, "LADO DOS BOTÕES", "ESQUERDO" if Controls.touch_left else "DIREITO", name_col, sel)
			"focusbtn":
				_setting(y, "BOTÃO DE FOCO NA TELA", "LIGADO" if Controls.touch_focus_btn else "DESLIGADO", name_col, sel)
			"reset":
				Neon.text(self, "RESTAURAR PADRÃO", Vector2(cx, y), 14, Cfg.ORANGE if sel else Color(Cfg.ORANGE, 0.7), HORIZONTAL_ALIGNMENT_CENTER, sel)
			"back":
				Neon.text(self, "VOLTAR", Vector2(cx, y), 16, Cfg.LIME if sel else Color(Cfg.LIME, 0.7), HORIZONTAL_ALIGNMENT_CENTER, sel)

	# guia
	var gy := 770.0
	var g := Color(0.8, 0.78, 0.95)
	Neon.text(self, "NO CELULAR", Vector2(24, gy), 11, Cfg.PINK, HORIZONTAL_ALIGNMENT_LEFT, false)
	Neon.text(self, "arraste o dedo em qualquer lugar: move a nave (o dedo não cobre a nave)", Vector2(24, gy + 22), 11, g, HORIZONTAL_ALIGNMENT_LEFT, false)
	Neon.text(self, "segure FOCO: nave lenta + hitbox visível   •   B: bomba   •   II: pausa", Vector2(24, gy + 42), 11, g, HORIZONTAL_ALIGNMENT_LEFT, false)
	Neon.text(self, "o tiro é sempre automático", Vector2(24, gy + 62), 11, g, HORIZONTAL_ALIGNMENT_LEFT, false)
	var hint := "ENTER: trocar tecla  •  ESC: cancelar  •  APAGAR: limpar" if Controls.capturing == "" \
		else I18n.t("aperte a nova tecla/botão para %s  (ESC cancela, APAGAR limpa)") % I18n.t(Controls.ACTION_NAMES[Controls.capturing])
	Neon.text(self, hint, Vector2(cx, 918.0), 10, Cfg.YELLOW if Controls.capturing != "" else Color(1, 1, 1, 0.45), HORIZONTAL_ALIGNMENT_CENTER, false)


func _setting(y: float, label: String, value: String, name_col: Color, sel: bool) -> void:
	Neon.text(self, label, Vector2(24, y), 13, name_col, HORIZONTAL_ALIGNMENT_LEFT, false)
	var vx := Cfg.W - 100.0
	var col := Cfg.CYAN if sel else Color(0.85, 0.85, 1.0)
	draw_colored_polygon(PackedVector2Array([Vector2(vx - 74, y), Vector2(vx - 64, y - 7), Vector2(vx - 64, y + 7)]), Color(col, 0.8))
	draw_colored_polygon(PackedVector2Array([Vector2(vx + 74, y), Vector2(vx + 64, y - 7), Vector2(vx + 64, y + 7)]), Color(col, 0.8))
	Neon.text(self, value, Vector2(vx, y), 13, col, HORIZONTAL_ALIGNMENT_CENTER, sel)


# ------------------------------------------------------------------ tela de opções

func _options() -> void:
	var m = main
	var cx := Cfg.W / 2.0
	draw_rect(Rect2(0, 0, Cfg.W, Cfg.H), Color(Cfg.BG, 0.8))
	Neon.glitch(self, "OPÇÕES", Vector2(cx, 70.0), 42, m.t, Cfg.CYAN, Cfg.MAGENTA)
	var rows: Array = m.opt_rows()
	var s: Dictionary = Profile.settings
	var sections := {"lang": "GERAL", "music": "ÁUDIO", "shake": "CONFORTO VISUAL"}
	for i in rows.size():
		var row: String = rows[i]
		var y: float = m.opt_row_y(i)
		var sel: bool = i == m.opt_sel
		if sections.has(row):
			Neon.text(self, sections[row], Vector2(24, y - 34), 11, Cfg.PINK, HORIZONTAL_ALIGNMENT_LEFT, false)
		if row == "back":
			if sel:
				_box(Rect2(150, y - 20, Cfg.W - 300, 40), Cfg.LIME, 0.08, 1.4)
			Neon.text(self, "VOLTAR", Vector2(cx, y), 18, Cfg.LIME if sel else Color(Cfg.LIME, 0.7), HORIZONTAL_ALIGNMENT_CENTER, sel)
			continue
		if sel:
			_box(Rect2(18, y - 22, Cfg.W - 36, 44), Cfg.CYAN, 0.07, 1.4)
		var label := ""
		var value := ""
		match row:
			"lang":
				label = "IDIOMA"
				value = I18n.LANG_NAMES.get(str(s["lang"]), "?")
			"music":
				label = "MÚSICA"
			"sfx":
				label = "EFEITOS SONOROS"
			"shake":
				label = "TREMOR DE TELA"
				value = _level_name(float(s["shake"]))
			"flash":
				label = "FLASHES DE TELA"
				value = _level_name(float(s["flash"]))
			"fullscreen":
				label = "TELA CHEIA"
				value = "LIGADO" if bool(s["fullscreen"]) else "DESLIGADO"
		Neon.text(self, label, Vector2(32, y), 15, Cfg.WHITE if sel else Color(0.78, 0.78, 0.9), HORIZONTAL_ALIGNMENT_LEFT, false)
		var vx := Cfg.W - 130.0
		var col := Cfg.CYAN if sel else Color(0.85, 0.85, 1.0)
		draw_colored_polygon(PackedVector2Array([Vector2(vx - 92, y), Vector2(vx - 82, y - 8), Vector2(vx - 82, y + 8)]), Color(col, 0.8))
		draw_colored_polygon(PackedVector2Array([Vector2(vx + 92, y), Vector2(vx + 82, y - 8), Vector2(vx + 82, y + 8)]), Color(col, 0.8))
		if row == "music" or row == "sfx":
			# barra de volume em 10 passos
			var v := roundi(float(s[row]) * 10.0)
			for k in 10:
				draw_rect(Rect2(vx - 70 + k * 14, y - 7, 10, 14), col if k < v else Color(col, 0.15))
		else:
			Neon.text(self, value, Vector2(vx, y), 14, col, HORIZONTAL_ALIGNMENT_CENTER, sel)
	var hint := "toque à esquerda/direita do valor para ajustar" if Controls.is_touch else "esq/dir: ajustar  •  ESC: voltar"
	Neon.text(self, hint, Vector2(cx, 918.0), 11, Color(1, 1, 1, 0.45), HORIZONTAL_ALIGNMENT_CENTER, false)


func _level_name(v: float) -> String:
	if v >= 0.99:
		return "LIGADO"
	if v > 0.01:
		return "REDUZIDO"
	return "DESLIGADO"