class_name Main
extends Node2D
## Cena principal: monta o mundo, roda a máquina de estados do jogo, o "diretor" das fases,
## as colisões, a pontuação e os créditos. Tudo é atualizado aqui em ordem fixa, a 60 passos por segundo.
##
## Estados: title -> shop (Hangar) -> playing <-> paused -> gameover / victory -> shop ...
## Fases de um setor: intro -> waves -> warning -> boss -> clear
## Campanha roguelite: toda partida começa no setor 1; os créditos ganhos compram upgrades permanentes.

const BOSS_SCRIPTS := {
	"square": preload("res://scripts/bosses/boss_square.gd"),
	"circle": preload("res://scripts/bosses/boss_circle.gd"),
	"triangle": preload("res://scripts/bosses/boss_triangle.gd"),
	"pentagon": preload("res://scripts/bosses/boss_pentagon.gd"),
	"hexagon": preload("res://scripts/bosses/boss_hexagon.gd"),
	"star": preload("res://scripts/bosses/boss_star.gd"),
	"twins": preload("res://scripts/bosses/boss_twins.gd"),
	"octagon": preload("res://scripts/bosses/boss_octagon.gd"),
	"tesseract": preload("res://scripts/bosses/boss_tesseract.gd"),
	"chaos": preload("res://scripts/bosses/boss_chaos.gd"),
}
const TOUCH_BUTTONS := [
	{"pos": Vector2(270, 34), "r": 34.0, "action": "pause"},
	{"pos": Vector2(474, 874), "r": 54.0, "action": "bomb"},
]

var state := "title"
var state_t := 0.0
var t := 0.0
var score := 0
var new_hi := false
var loop := 0                 # ciclo (cada volta completa fica mais difícil)
var hp_mul := 1.0
var rate_mul := 1.0
var enemy_hp_mul := 1.0       # cresce a cada setor
var enemy_rate := 1.0

var stage_idx := 0
var stage: Dictionary = {}
var phase := "intro"
var pt := 0.0
var ev_idx := 0
var timers: Array = []        # [[segundos_restantes, Callable], ...]
var boss = null
var banner = null             # Dictionary ou null
var kills := 0
var dead_t := 0.0
var menu_sel := 0
var menu_items: Array = []

# créditos da partida atual (vão para o perfil ao "depositar")
var run_credits := 0
var _banked := 0
var summary: Array = []       # linhas da tela de fim de partida

# loja
var shop_sel := 0
var shop_msg := ""
var shop_msg_t := 0.0

var bg
var items
var hud
var enemy_layer: Node2D
var player: Player
var bullets: BulletManager
var fx: FX
var cam: Camera2D
var enemies: Array = []


func _ready() -> void:
	randomize()
	bg = preload("res://scripts/background.gd").new()
	add_child(bg)
	items = preload("res://scripts/items.gd").new()
	items.main = self
	add_child(items)
	enemy_layer = Node2D.new()
	add_child(enemy_layer)
	player = Player.new()
	player.main = self
	player.visible = false
	add_child(player)
	bullets = BulletManager.new()
	bullets.main = self
	add_child(bullets)
	fx = FX.new()
	add_child(fx)
	cam = Camera2D.new()
	cam.position = Vector2(Cfg.W / 2.0, Cfg.H / 2.0)
	add_child(cam)
	cam.make_current()
	var layer := CanvasLayer.new()
	layer.layer = 10
	add_child(layer)
	hud = preload("res://scripts/hud.gd").new()
	hud.main = self
	layer.add_child(hud)
	_setup_glow()
	Sfx.music("title")


## Brilho (bloom) de tela inteira. Cores "quentes" (acima de 1.0) acendem mais.
func _setup_glow() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_CANVAS
	env.glow_enabled = true
	env.glow_intensity = 0.9
	env.glow_strength = 1.0
	env.glow_bloom = 0.05
	env.glow_hdr_threshold = 0.85
	env.glow_blend_mode = Environment.GLOW_BLEND_MODE_SCREEN
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_APPLICATION_PAUSED:
		if state == "playing":
			_set_state("paused")
		_bank()


# ------------------------------------------------------------------ laço principal

func _physics_process(dt: float) -> void:
	t += dt
	state_t += dt
	if Controls.pressed("mute"):
		Sfx.toggle_mute()
	Controls.buttons = TOUCH_BUTTONS if (state == "playing" and Controls.is_touch) else []

	match state:
		"title":
			_update_title(dt)
		"shop":
			_update_shop(dt)
		"playing":
			if Controls.pressed("pause"):
				_set_state("paused")
				_bank()
				Sfx.play("select")
			else:
				_update_playing(dt)
		"paused":
			if Controls.pressed("pause"):
				_set_state("playing")
			else:
				_menu(["CONTINUAR", "ABANDONAR MISSÃO"], _on_pause_menu)
		"gameover":
			bg.speed = 0.3
			bg.step(dt)
			fx.step(dt)
			if state_t > 1.2:
				_menu(["HANGAR (LOJA)", "MENU INICIAL"], _on_end_menu)
		"victory":
			bg.step(dt)
			fx.step(dt)
			if state_t > 1.2:
				_menu(["NOVO CICLO (MAIS DIFÍCIL)", "HANGAR (LOJA)"], _on_victory_menu)

	cam.offset = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * fx.shake if fx.shake > 0.1 else Vector2.ZERO
	hud.queue_redraw()
	Controls.end_frame()


func _update_title(dt: float) -> void:
	bg.speed = 0.6
	bg.step(dt)
	# chama do motor do triângulo da tela inicial
	if randf() < 0.8:
		var y := Cfg.H * 0.5 + sin(t * 2.0) * 6.0 + 20.0
		fx.emit(Vector2(Cfg.W / 2.0 + randf_range(-3.0, 3.0), y), Vector2(randf_range(-20.0, 20.0), randf_range(160.0, 260.0)), Cfg.MAGENTA, 0.3, 3.0)
	fx.step(dt)
	if state_t > 0.3 and (Controls.pressed("confirm") or Controls.taps.size() > 0):
		Sfx.play("select")
		_open_shop()


func _update_playing(dt: float) -> void:
	bg.speed = 1.6 if phase == "boss" else 1.0
	if stage_idx == Stages.ALL.size() - 1:
		bg.color = Color.from_hsv(fmod(t * 0.05, 1.0), 0.7, 1.0)   # setor final: cores mudando
	bg.step(dt)
	_update_director(dt)
	_update_timers(dt)
	player.step(dt)
	for e in enemies:
		if e.alive:
			e.step(dt)
	if boss != null:
		boss.step(dt)
	bullets.step(dt)
	_collide()
	_cleanup_enemies()
	items.step(dt)
	fx.step(dt)
	if banner != null:
		banner["t"] += dt
		if banner["t"] > banner["dur"]:
			banner = null
	if player.dead:
		dead_t += dt
		if dead_t > 2.2:
			_end_run(false)


# ------------------------------------------------------------------ estados e menus

func _set_state(s: String) -> void:
	state = s
	state_t = 0.0
	menu_sel = 0
	menu_items = []


func _new_game() -> void:
	score = 0
	loop = 0
	kills = 0
	dead_t = 0.0
	new_hi = false
	run_credits = 0
	_banked = 0
	Profile.runs += 1
	player.reset()
	player.visible = true
	_set_difficulty()
	_begin_stage(0)
	_set_state("playing")


func _next_loop() -> void:
	loop += 1
	_banked = 0
	run_credits = 0
	_set_difficulty()
	_begin_stage(0)
	_set_state("playing")


func _to_title() -> void:
	_clear_world()
	fx.clear_all()
	banner = null
	player.visible = false
	bg.color = Cfg.MAGENTA
	_set_state("title")
	Sfx.music("title")


func _open_shop() -> void:
	_clear_world()
	fx.clear_all()
	banner = null
	player.visible = false
	bg.color = Cfg.CYAN
	shop_sel = 0
	shop_msg = ""
	_set_state("shop")
	Sfx.music("title")


## Fim da partida (morte ou vitória): deposita créditos e monta o resumo.
func _end_run(won: bool) -> void:
	if won:
		add_credits(Cfg.CLEAR_BONUS)
	_bank()
	Profile.best_stage = maxi(Profile.best_stage, stage_idx + 1)
	if score > Profile.hi:
		Profile.hi = score
		new_hi = true
	Profile.save_profile()
	summary = [
		"PONTOS  %d" % score,
		"NOVO RECORDE!" if new_hi else "RECORDE  %d" % Profile.hi,
		"SETOR ALCANÇADO  %d / %d" % [stage_idx + 1, Stages.ALL.size()],
		"CRÉDITOS GANHOS  +%d" % run_credits,
	]
	if won:
		_set_state("victory")
		Sfx.music("title")
	else:
		_set_state("gameover")
		Sfx.music("silence")
		Sfx.play("game_over")


func _set_difficulty() -> void:
	hp_mul = 1.0 + loop * 0.35
	rate_mul = 1.0 + loop * 0.25
	bullets.speed_mul = 1.0 + loop * 0.15


func menu_y(i: int) -> float:
	return Cfg.H * 0.62 + i * 62.0


func _menu(opts: Array, cb: Callable) -> void:
	menu_items = opts
	var n := opts.size()
	if Controls.pressed("up"):
		menu_sel = (menu_sel + n - 1) % n
		Sfx.play("tick")
	if Controls.pressed("down"):
		menu_sel = (menu_sel + 1) % n
		Sfx.play("tick")
	if Controls.pressed("confirm"):
		Sfx.play("select")
		cb.call(menu_sel)
		return
	for tp in Controls.taps:
		for i in n:
			if absf(tp.y - menu_y(i)) < 28.0 and absf(tp.x - Cfg.W / 2.0) < 200.0:
				menu_sel = i
				Sfx.play("select")
				cb.call(i)
				return


func _on_pause_menu(i: int) -> void:
	if i == 0:
		_set_state("playing")
	else:
		_end_run(false)


func _on_end_menu(i: int) -> void:
	if i == 0:
		_open_shop()
	else:
		_to_title()


func _on_victory_menu(i: int) -> void:
	if i == 0:
		_next_loop()
	else:
		_open_shop()


# ------------------------------------------------------------------ Hangar (loja)

## Linhas da loja: [INICIAR, ARMA INICIAL, upgrades...]
func shop_rows() -> Array:
	var rows: Array = [{"type": "start"}, {"type": "weapon"}]
	for u in Cfg.UPGRADES:
		rows.append({"type": "up", "id": u["id"]})
	return rows


func shop_row_y(i: int) -> float:
	return Cfg.SHOP_Y0 + i * Cfg.SHOP_ROW_H


func _update_shop(dt: float) -> void:
	bg.speed = 0.4
	bg.step(dt)
	fx.step(dt)
	shop_msg_t = maxf(0.0, shop_msg_t - dt)
	var rows := shop_rows()
	var n := rows.size()
	if Controls.pressed("up"):
		shop_sel = (shop_sel + n - 1) % n
		Sfx.play("tick")
	if Controls.pressed("down"):
		shop_sel = (shop_sel + 1) % n
		Sfx.play("tick")
	if rows[shop_sel]["type"] == "weapon" and (Controls.pressed("left") or Controls.pressed("right")):
		_shop_activate(shop_sel)
	if Controls.pressed("confirm"):
		_shop_activate(shop_sel)
		return
	if Controls.pressed("pause") and state_t > 0.2:
		_to_title()
		return
	# toque: 1º toque seleciona, 2º compra (INICIAR e ARMA respondem no 1º toque)
	for tp in Controls.taps:
		var idx := int(floor((tp.y - Cfg.SHOP_Y0 + Cfg.SHOP_ROW_H * 0.5) / Cfg.SHOP_ROW_H))
		if idx < 0 or idx >= n or absf(tp.x - Cfg.W / 2.0) > 250.0:
			continue
		if idx == shop_sel or rows[idx]["type"] != "up":
			shop_sel = idx
			_shop_activate(idx)
		else:
			shop_sel = idx
			Sfx.play("tick")
		return


func _shop_activate(i: int) -> void:
	var row: Dictionary = shop_rows()[i]
	match row["type"]:
		"start":
			Sfx.play("select")
			_new_game()
		"weapon":
			Profile.cycle_start_weapon()
			Sfx.play("tick")
		"up":
			var id: String = row["id"]
			match Profile.buy(id):
				"ok":
					Sfx.play("coin")
					fx.spark(Vector2(Cfg.W - 70.0, shop_row_y(i)), Cfg.YELLOW, 14, 220.0)
					_shop_say("COMPRADO: %s NV %d" % [Profile.upgrade_def(id)["name"], Profile.level(id)])
				"max":
					Sfx.play("deny")
					_shop_say("NÍVEL MÁXIMO")
				_:
					Sfx.play("deny")
					_shop_say("CRÉDITOS INSUFICIENTES")


func _shop_say(msg: String) -> void:
	shop_msg = msg
	shop_msg_t = 2.0


# ------------------------------------------------------------------ créditos

func add_credits(n: int) -> void:
	run_credits += int(round(n * (1.0 + loop * 0.5)))


## Passa para o perfil (salvo) os créditos ainda não depositados desta partida.
func _bank() -> void:
	if run_credits > _banked:
		Profile.credits += run_credits - _banked
		_banked = run_credits
		Profile.save_profile()


# ------------------------------------------------------------------ diretor das fases

func _begin_stage(i: int) -> void:
	_clear_world()
	stage_idx = i
	stage = Stages.ALL[i]
	phase = "intro"
	pt = 0.0
	ev_idx = 0
	enemy_hp_mul = hp_mul * (1.0 + i * 0.08)
	enemy_rate = rate_mul * (1.0 + i * 0.05)
	bg.color = stage["color"]
	player.bombs = maxi(player.bombs, Profile.stage_bombs())
	player.shield = maxi(player.shield, Profile.shield_charges())
	var sub: String = stage["sub"]
	if loop > 0:
		sub += "  //  CICLO %d" % (loop + 1)
	show_banner(stage["name"], sub, stage["color"], 2.6)
	Sfx.music("stage")


func _clear_world() -> void:
	bullets.clear_all()
	items.clear_all()
	for e in enemies:
		e.queue_free()
	enemies.clear()
	timers.clear()
	if boss != null:
		boss.queue_free()
		boss = null


func _update_director(dt: float) -> void:
	pt += dt
	match phase:
		"intro":
			if pt > 2.0:
				phase = "waves"
				pt = 0.0
		"waves":
			var events: Array = stage["events"]
			while ev_idx < events.size() and pt >= float(events[ev_idx][0]):
				var ev: Array = events[ev_idx]
				ev_idx += 1
				_run_event(ev)
			var last_t: float = events[events.size() - 1][0]
			var done := ev_idx >= events.size() and timers.is_empty() and pt > last_t + 2.0
			if done and (enemies.is_empty() or pt > last_t + 12.0):
				phase = "warning"
				pt = 0.0
				var is_final := stage_idx == Stages.ALL.size() - 1
				show_banner("WARNING", "ANOMALIA DETECTADA" if is_final else "ALVO DE GRANDE PORTE DETECTADO", Cfg.RED, 2.6)
				Sfx.play("warning")
				Sfx.music("silence")
		"warning":
			if pt > 2.6:
				phase = "boss"
				pt = 0.0
				boss = BOSS_SCRIPTS[stage["boss"]].new()
				boss.setup(self)
				add_child(boss)
				Sfx.music("boss")
		"clear":
			if pt > 4.0:
				if stage_idx + 1 < Stages.ALL.size():
					_begin_stage(stage_idx + 1)
				else:
					_end_run(true)


func _opt(ev: Array, idx: int) -> Dictionary:
	return ev[idx] if ev.size() > idx else {}


## Interpreta uma linha do roteiro (veja stages.gd).
func _run_event(ev: Array) -> void:
	var form: String = ev[1]
	var kind: String = ev[2]
	match form:
		"one":
			spawn(kind, float(ev[3]), -40.0, _opt(ev, 4))
		"stream":
			var n: int = ev[4]
			var gap: float = ev[5]
			for i in n:
				after(i * gap, _spawn_stream.bind(kind, ev[3], i, _opt(ev, 6)))
		"row":
			var n: int = ev[3]
			for i in n:
				spawn(kind, 60.0 + (Cfg.W - 120.0) * i / maxf(1.0, n - 1.0), -30.0, _opt(ev, 4))
		"sweep":
			var side: float = ev[3]
			var n: int = ev[4]
			var gap: float = ev[5]
			var prm := _opt(ev, 6)
			var y0: float = prm.get("y0", 90.0)
			var x := -30.0 if side < 0.0 else Cfg.W + 30.0
			for i in n:
				after(i * gap, spawn.bind(kind, x, y0 + i * 18.0, prm))
		"vee":
			var cx: float = ev[3]
			var n: int = ev[4]
			for i in n:
				var o := i - (n - 1) / 2.0
				after(absf(o) * 0.18, spawn.bind(kind, cx + o * 50.0, -30.0, _opt(ev, 5)))


func _spawn_stream(kind: String, x, i: int, prm: Dictionary) -> void:
	var xx := 0.0
	if x is String:
		if x == "rand":
			xx = randf_range(60.0, Cfg.W - 60.0)
		else:
			xx = 80.0 if i % 2 == 1 else Cfg.W - 80.0
	else:
		xx = float(x)
	spawn(kind, xx, -30.0, prm)


func after(delay: float, fn: Callable) -> void:
	timers.append([delay, fn])


func _update_timers(dt: float) -> void:
	var i := timers.size() - 1
	while i >= 0:
		if i < timers.size():
			timers[i][0] -= dt
			if timers[i][0] <= 0.0:
				var fn: Callable = timers[i][1]
				timers.remove_at(i)
				fn.call()
		i -= 1


func show_banner(title: String, sub: String, col: Color, dur: float) -> void:
	banner = {"title": title, "sub": sub, "color": col, "t": 0.0, "dur": dur}


# ------------------------------------------------------------------ inimigos

func spawn(kind: String, x: float, y: float, params: Dictionary = {}) -> Enemy:
	var e := Enemy.new()
	e.setup(self, kind, Vector2(x, y), params)
	enemy_layer.add_child(e)
	enemies.append(e)
	return e


func _boss_targetable() -> bool:
	return boss != null and boss.alive and boss.state != "enter" and boss.state != "dying"


## Alvo mais próximo para os tiros teleguiados (posição) ou null se não houver nenhum.
func nearest_target(from: Vector2):
	var best = null
	var best_d := INF
	for e in enemies:
		if e.alive and e.position.y > 0.0:
			var d: float = from.distance_squared_to(e.position)
			if d < best_d:
				best_d = d
				best = e.position
	if boss != null and boss.alive and boss.state == "fight":
		for hp_ in boss.hit_points():
			var d: float = from.distance_squared_to(hp_[0])
			if d < best_d:
				best_d = d
				best = hp_[0]
	return best


func count_kind(kind: String) -> int:
	var n := 0
	for e in enemies:
		if e.alive and e.kind == kind:
			n += 1
	return n


func damage_enemy(e, d: float) -> void:
	if not e.alive:
		return
	e.hp -= d
	e.flash = 0.05
	if e.hp <= 0.0:
		kill_enemy(e)
	else:
		Sfx.play("hit", -6.0)


func kill_enemy(e) -> void:
	e.alive = false
	var big: bool = e.r > 25.0
	fx.explode(e.position, e.color, 2.0 if big else 1.0)
	fx.add_shake(8.0 if big else 3.0)
	add_score(e.score)
	add_credits(int(Cfg.CREDITS.get(e.kind, 1)))
	fx.text(e.position, str(e.score), e.color, 14)
	Sfx.play("big_explode" if big else "explode")
	# a partir do ciclo 2, inimigos soltam balas ao morrer
	if loop > 0 and e.kind != "turret":
		bullets.ring(e.position, 6 + loop * 2, 120.0, randf() * TAU, {"color": Cfg.PINK, "r": 5.0})
	kills += 1
	if e.kind == "turret" or kills % 14 == 0:
		items.spawn(e.position, "P")
	if kills % 70 == 0:
		items.spawn(e.position, "B")
	if kills % 30 == 0:
		items.spawn(e.position, "W")


func kill_all_enemies() -> void:
	for e in enemies:
		if e.alive:
			kill_enemy(e)


func _cleanup_enemies() -> void:
	var keep: Array = []
	for e in enemies:
		if e.alive:
			keep.append(e)
		else:
			e.queue_free()
	enemies = keep


func bomb_damage() -> void:
	for e in enemies.duplicate():
		if e.alive:
			damage_enemy(e, 40.0)
	if boss != null:
		boss.damage(70.0)


func on_boss_defeated(b) -> void:
	kill_all_enemies()
	bullets.cancel_all(true)
	add_score(20000)
	var cr := Cfg.BOSS_CREDITS + 20 * stage_idx
	add_credits(cr)
	for k in 5:
		items.spawn(b.position + Vector2(randf_range(-50.0, 50.0), randf_range(-30.0, 30.0)), "P")
	items.spawn(b.position, "B")
	items.spawn(b.position, "V")
	items.spawn(b.position + Vector2(0, 40), "W")
	after(0.8, Callable(items, "magnet_all"))
	boss = null
	b.queue_free()
	phase = "clear"
	pt = 0.0
	show_banner("SETOR LIMPO", "+20000 PONTOS   +%d CRÉDITOS" % cr, Cfg.LIME, 3.0)
	Sfx.music("silence")
	Sfx.play("clear")
	_bank()


# ------------------------------------------------------------------ colisões

func _collide() -> void:
	# tiros do jogador -> inimigos e chefe
	var spark_col: Color = Cfg.WEAPON_COLORS[player.weapon]
	var boss_pts: Array = boss.hit_points() if _boss_targetable() else []
	for s in bullets.shots:
		if not s.alive:
			continue
		var pierce: bool = s.kind == 1   # o laser atravessa e acerta cada alvo uma vez
		for e in enemies:
			if not e.alive or (pierce and s.hits.has(e)):
				continue
			var rr: float = e.r + 6.0
			if s.pos.distance_squared_to(e.position) < rr * rr:
				damage_enemy(e, s.dmg)
				fx.spark(s.pos, spark_col, 2, 120.0, 0.2, 2.0)
				if pierce:
					s.hits.append(e)
				else:
					s.alive = false
					break
		if not s.alive or boss_pts.is_empty() or boss == null:
			continue
		if boss.blocks(s.pos):
			s.alive = false
			fx.spark(s.pos, Cfg.WHITE, 2, 140.0, 0.2, 2.0)
			continue
		if pierce and s.hits.has(boss):
			continue
		for hp_ in boss_pts:
			var br: float = hp_[1] + 6.0
			if s.pos.distance_squared_to(hp_[0]) < br * br:
				if pierce:
					s.hits.append(boss)
				else:
					s.alive = false
				if boss.damage(s.dmg):
					Sfx.play("hit", -8.0)
				fx.spark(s.pos, spark_col, 1, 120.0, 0.2, 2.0)
				break
		if boss == null:
			boss_pts = []

	if player.dead:
		return
	var pp := player.position
	var hr := Cfg.HIT_RADIUS
	var invuln := player.invuln > 0.0

	# balas inimigas -> jogador (e "graze": passar raspando dá pontos)
	for b in bullets.list:
		if not b.alive:
			continue
		var d2: float
		var hit_r: float
		if b.needle:
			# agulha: colisão em "cápsula" ao longo da direção, igual ao desenho alongado
			var dir := Vector2.from_angle(b.ang)
			var rel: Vector2 = pp - b.pos
			var along := clampf(rel.dot(dir), -b.r * 1.1, b.r * 1.1)
			d2 = (rel - dir * along).length_squared()
			hit_r = b.r * 0.5 + hr
		else:
			d2 = b.pos.distance_squared_to(pp)
			hit_r = b.r * Cfg.BULLET_HITBOX + hr
		if d2 < hit_r * hit_r:
			if not invuln:
				b.alive = false
				player.hit()
				return
			continue
		if not invuln and not b.grazed:
			var g: float = Cfg.GRAZE_RADIUS + b.r
			if d2 < g * g:
				b.grazed = true
				add_score(20)
				fx.spark(b.pos, Cfg.WHITE, 2, 90.0, 0.2, 2.0)
				Sfx.play("graze", -8.0)

	if invuln:
		return
	# lasers dos chefes
	if bullets.beam_hits(pp, hr):
		player.hit()
		return
	# corpos -> jogador
	for e in enemies:
		if not e.alive:
			continue
		var rr: float = e.r * 0.7 + hr
		if e.position.distance_squared_to(pp) < rr * rr:
			player.hit()
			damage_enemy(e, 10.0)
			return
	if _boss_targetable():
		for hp_ in boss.hit_points():
			var br: float = hp_[1] * 0.75
			if pp.distance_squared_to(hp_[0]) < br * br:
				player.hit()
				return


# ------------------------------------------------------------------ pontos e itens

func add_score(n: int) -> void:
	score += int(round(n * (1.0 + loop * 0.5)))


func collect(kind: String, pos: Vector2, weapon := "") -> void:
	var col := Cfg.LIME
	match kind:
		"W":
			col = Cfg.WEAPON_COLORS[weapon]
			if player.weapon == weapon:
				if player.power < Cfg.MAX_POWER:
					player.power += 1
					fx.text(pos + Vector2(0, -20), "POWER UP", col, 14)
				else:
					add_score(1000)
					fx.text(pos + Vector2(0, -20), "+1000", col, 14)
			else:
				player.weapon = weapon
				fx.text(pos + Vector2(0, -20), Cfg.WEAPON_NAMES[weapon], col, 18)
				fx.ring(player.position, col, 60.0, 0.4, 3.0)
		"P":
			if player.power < Cfg.MAX_POWER:
				player.power += 1
				fx.text(pos + Vector2(0, -20), "POWER UP", Cfg.LIME, 14)
			else:
				add_score(1000)
				fx.text(pos + Vector2(0, -20), "+1000", Cfg.LIME, 14)
		"B":
			col = Cfg.YELLOW
			player.bombs = mini(Cfg.MAX_BOMBS + Profile.level("bombs"), player.bombs + 1)
			fx.text(pos + Vector2(0, -20), "+BOMBA", col, 14)
		"V":
			col = Cfg.PINK
			if player.lives < Profile.lives_cap():
				player.lives += 1
				fx.text(pos + Vector2(0, -20), "+VIDA", col, 14)
			else:
				add_score(5000)
				fx.text(pos + Vector2(0, -20), "+5000", col, 14)
	fx.spark(pos, col, 10, 200.0)
	Sfx.play("power")
