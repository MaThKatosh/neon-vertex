class_name BulletManager
extends Node2D
## Projéteis. Em vez de um nó por bala (pesado com centenas delas), guardamos dados simples
## em listas e desenhamos tudo de uma vez. Também contém os "padrões" de disparo (anel, leque...).

class Bullet:
	var pos := Vector2.ZERO
	var vel := Vector2.ZERO
	var ang := 0.0
	var speed := 0.0
	var accel := 0.0
	var ang_vel := 0.0       # curva (rad/s)
	var min_speed := 0.0
	var max_speed := 9999.0
	var r := 6.0
	var color := Color.WHITE
	var needle := false      # formato alongado
	var t := 0.0
	var grazed := false
	var split_t := -1.0      # se >= 0: após esse tempo a bala "estoura" chamando `split`
	var split := Callable()
	var alive := true

class Shot:
	var pos := Vector2.ZERO
	var vel := Vector2.ZERO
	var dmg := 1.0
	var alive := true
	var kind := 0          # 0 normal (leque), 1 laser (atravessa), 2 teleguiado (enxame)
	var hits: Array = []   # alvos que o laser já atingiu (acerta cada um uma vez)
	var t := 0.0

const MAX_BULLETS := 1500

var main
var list: Array[Bullet] = []    # projéteis inimigos
var shots: Array[Shot] = []     # tiros do jogador
var speed_mul := 1.0            # aumenta nos ciclos mais difíceis

var _free: Array[Bullet] = []
var _shot_layer   # draw_proxy.gd (sem tipo para acessar `draw_fn`)


func _ready() -> void:
	z_index = 5
	var m := CanvasItemMaterial.new()
	m.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	material = m
	# Tiros do jogador ficam numa camada abaixo dos inimigos.
	_shot_layer = preload("res://scripts/draw_proxy.gd").new()
	_shot_layer.draw_fn = _draw_shots
	_shot_layer.z_as_relative = false
	_shot_layer.z_index = 1
	var m2 := CanvasItemMaterial.new()
	m2.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	_shot_layer.material = m2
	add_child(_shot_layer)


# ------------------------------------------------------------------ criação

## Opções aceitas em `o`: color, r, needle, accel, ang_vel, min_speed, max_speed, split, split_t
func shoot(pos: Vector2, ang: float, speed: float, o: Dictionary = {}) -> Bullet:
	if list.size() >= MAX_BULLETS:
		return null
	var b: Bullet = _free.pop_back() if _free.size() > 0 else Bullet.new()
	b.pos = pos
	b.ang = ang
	b.speed = speed * speed_mul
	b.accel = float(o.get("accel", 0.0)) * speed_mul
	b.ang_vel = float(o.get("ang_vel", 0.0))
	b.min_speed = float(o.get("min_speed", 0.0)) * speed_mul
	b.max_speed = float(o.get("max_speed", 9999.0)) * speed_mul
	b.r = float(o.get("r", 6.0))
	b.color = o.get("color", Cfg.PINK)
	b.needle = bool(o.get("needle", false))
	b.split = o.get("split", Callable())
	b.split_t = float(o.get("split_t", -1.0))
	b.t = 0.0
	b.grazed = false
	b.alive = true
	b.vel = Vector2.from_angle(ang) * b.speed
	list.append(b)
	return b


func add_shot(pos: Vector2, vel: Vector2, dmg: float, kind := 0) -> void:
	var s := Shot.new()
	s.pos = pos
	s.vel = vel
	s.dmg = dmg
	s.kind = kind
	shots.append(s)


## Tiro teleguiado: vira aos poucos na direção do alvo mais próximo.
func _steer(s: Shot, dt: float) -> void:
	var target = main.nearest_target(s.pos)
	if target == null:
		return
	var cur := s.vel.angle()
	var want: float = (target - s.pos).angle()
	var turn := clampf(wrapf(want - cur, -PI, PI), -7.0 * dt, 7.0 * dt)
	s.vel = Vector2.from_angle(cur + turn) * minf(s.vel.length() + 900.0 * dt, 950.0)


# ------------------------------------------------------------------ padrões

func aim(from: Vector2) -> float:
	return (main.player.position - from).angle()


func ring(pos: Vector2, n: int, speed: float, off := 0.0, o: Dictionary = {}) -> void:
	for i in n:
		shoot(pos, off + TAU * i / n, speed, o)


func fan(pos: Vector2, ang: float, n: int, spread: float, speed: float, o: Dictionary = {}) -> void:
	if n == 1:
		shoot(pos, ang, speed, o)
		return
	for i in n:
		shoot(pos, ang - spread / 2.0 + spread * i / (n - 1), speed, o)


func aim_fan(pos: Vector2, n: int, spread: float, speed: float, o: Dictionary = {}) -> void:
	fan(pos, aim(pos), n, spread, speed, o)


## Várias balas na mesma direção com velocidades diferentes (uma "fila").
func stack(pos: Vector2, ang: float, n: int, s0: float, s1: float, o: Dictionary = {}) -> void:
	for i in n:
		shoot(pos, ang, s0 + (s1 - s0) * i / maxf(1.0, n - 1.0), o)


## Anel com buracos: a cada `every` balas, pula `gap`.
func gap_ring(pos: Vector2, n: int, speed: float, off: float, every: int, gap: int, o: Dictionary = {}) -> void:
	for i in n:
		if i % every >= gap:
			shoot(pos, off + TAU * i / n, speed, o)


# ------------------------------------------------------------------ atualização

func step(dt: float) -> void:
	var i := 0
	while i < list.size():   # `while` porque splits podem adicionar balas durante o laço
		var b: Bullet = list[i]
		i += 1
		if not b.alive:
			continue
		b.t += dt
		if b.accel != 0.0 or b.ang_vel != 0.0:
			if b.accel != 0.0:
				b.speed = clampf(b.speed + b.accel * dt, b.min_speed, b.max_speed)
			b.ang += b.ang_vel * dt
			b.vel = Vector2.from_angle(b.ang) * b.speed
		b.pos += b.vel * dt
		if b.split_t >= 0.0 and b.t >= b.split_t:
			b.alive = false
			b.split_t = -1.0
			if b.split.is_valid():
				b.split.call(b.pos)
			continue
		if b.pos.x < -50.0 or b.pos.x > Cfg.W + 50.0 or b.pos.y < -80.0 or b.pos.y > Cfg.H + 50.0 or b.t > 15.0:
			b.alive = false
	_compact()

	var j := 0
	for k in shots.size():
		var s: Shot = shots[k]
		s.t += dt
		if s.kind == 2 and s.t > 0.08:
			_steer(s, dt)
		s.pos += s.vel * dt
		var inside := s.pos.y > -40.0 and s.pos.y < Cfg.H + 40.0 and s.pos.x > -40.0 and s.pos.x < Cfg.W + 40.0
		if s.alive and inside and s.t < 3.0:
			shots[j] = s
			j += 1
	shots.resize(j)
	queue_redraw()
	_shot_layer.queue_redraw()


func _compact() -> void:
	var j := 0
	for k in list.size():
		var b: Bullet = list[k]
		if b.alive:
			list[j] = b
			j += 1
		else:
			_free.append(b)
	list.resize(j)


## Apaga balas inimigas num raio (radius <= 0 apaga todas). Pode dar 10 pontos por bala.
func cancel(center: Vector2, radius: float, give_score: bool) -> int:
	var n := 0
	var r2 := radius * radius
	for b in list:
		if not b.alive:
			continue
		if radius > 0.0 and b.pos.distance_squared_to(center) > r2:
			continue
		b.alive = false
		n += 1
		if n < 200:
			main.fx.spark(b.pos, b.color, 1, 60.0, 0.35, 2.5)
	_compact()
	if give_score and n > 0:
		main.add_score(n * 10)
	return n


func cancel_all(give_score: bool) -> int:
	return cancel(Vector2.ZERO, 0.0, give_score)


func clear_all() -> void:
	for b in list:
		_free.append(b)
	list.clear()
	shots.clear()


# ------------------------------------------------------------------ desenho

func _draw() -> void:
	var gt := Neon.glow_tex()
	var ct := Neon.core_tex()
	for b in list:
		var r: float = b.r
		var col: Color = b.color
		if b.needle:
			draw_set_transform(b.pos, b.ang, Vector2(1.7, 0.6))
		else:
			draw_set_transform(b.pos, 0.0, Vector2.ONE)
		# halo = só brilho; o núcleo claro tem o tamanho exato da área que acerta
		var hr: float = r * Cfg.BULLET_HITBOX + 1.0
		draw_texture_rect(gt, Rect2(-r * 2.6, -r * 2.6, r * 5.2, r * 5.2), false, Color(col, 0.55))
		draw_texture_rect(ct, Rect2(-r * 1.15, -r * 1.15, r * 2.3, r * 2.3), false, col)
		draw_texture_rect(ct, Rect2(-hr, -hr, hr * 2.0, hr * 2.0), false, Neon.hot(col.lerp(Color.WHITE, 0.7), 1.5))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_shots(ci: CanvasItem) -> void:
	var gt := Neon.glow_tex()
	var ct := Neon.core_tex()
	var halo := Color(Cfg.CYAN, 0.8)
	var core := Neon.hot(Color(0.8, 1.0, 1.0), 1.5)
	var laser: Color = Cfg.WEAPON_COLORS["laser"]
	var homing: Color = Cfg.WEAPON_COLORS["homing"]
	for s in shots:
		match s.kind:
			1:
				ci.draw_texture_rect(gt, Rect2(s.pos.x - 6.0, s.pos.y - 34.0, 12.0, 68.0), false, Color(laser, 0.85))
				ci.draw_texture_rect(ct, Rect2(s.pos.x - 1.5, s.pos.y - 28.0, 3.0, 56.0), false, Neon.hot(Color(0.85, 0.95, 1.0), 1.8))
			2:
				ci.draw_texture_rect(gt, Rect2(s.pos.x - 14.0, s.pos.y - 14.0, 28.0, 28.0), false, homing)
				ci.draw_texture_rect(ct, Rect2(s.pos.x - 4.5, s.pos.y - 4.5, 9.0, 9.0), false, Neon.hot(homing.lerp(Color.WHITE, 0.5), 1.6))
			_:
				ci.draw_texture_rect(gt, Rect2(s.pos.x - 8.0, s.pos.y - 20.0, 16.0, 40.0), false, halo)
				ci.draw_texture_rect(ct, Rect2(s.pos.x - 2.5, s.pos.y - 10.0, 5.0, 20.0), false, core)
