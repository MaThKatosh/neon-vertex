class_name Player
extends Node2D
## O triângulo. Tiro automático; o nível de poder (1-4) muda o padrão de disparo.
## Segurar FOCO deixa a nave lenta, concentra os tiros e mostra a hitbox.

var main
var lives := Cfg.START_LIVES
var bombs := Cfg.START_BOMBS
var power := 1
var weapon := "spread"     # spread (leque) | laser | homing (enxame)
var invuln := 0.0
var bombing := 0.0
var fire_cd := 0.0
var focus := false
var dead := false
var tilt := 0.0

var _shot_count := 0


func _ready() -> void:
	z_index = 3


func reset() -> void:
	position = Vector2(Cfg.W / 2.0, Cfg.H - 150.0)
	lives = Cfg.START_LIVES
	bombs = Cfg.START_BOMBS
	power = 1
	weapon = "spread"
	invuln = 0.0
	bombing = 0.0
	fire_cd = 0.0
	dead = false
	tilt = 0.0


func step(dt: float) -> void:
	queue_redraw()
	if dead:
		return
	focus = Input.is_action_pressed("focus")
	var spd := Cfg.PLAYER_FOCUS_SPEED if focus else Cfg.PLAYER_SPEED
	var mv: Vector2 = Controls.move_vector()
	var drag: Vector2 = Controls.drag
	var old_x := position.x
	position += mv * spd * dt + drag
	position.x = clampf(position.x, 18.0, Cfg.W - 18.0)
	position.y = clampf(position.y, 110.0, Cfg.H - 30.0)
	var vx := (position.x - old_x) / dt
	tilt = lerpf(tilt, clampf(vx / Cfg.PLAYER_SPEED, -1.0, 1.0), 0.25)

	invuln = maxf(0.0, invuln - dt)
	if bombing > 0.0:
		bombing -= dt
		main.bullets.cancel_all(true)

	fire_cd -= dt
	if fire_cd <= 0.0:
		match weapon:
			"laser":
				fire_cd += 0.05
				_fire_laser()
			"homing":
				fire_cd += 0.16
				_fire_homing()
			_:
				fire_cd += Cfg.FIRE_RATE
				_fire()
		_shot_count += 1
		if _shot_count % 2 == 0:
			Sfx.play("shoot", -12.0)

	if Controls.pressed("bomb"):
		bomb()

	# rastro do motor
	if randf() < 0.7:
		var flame := Cfg.WHITE if focus else Cfg.MAGENTA
		main.fx.emit(position + Vector2(randf_range(-3.0, 3.0), 16.0),
			Vector2(randf_range(-20.0, 20.0), randf_range(160.0, 260.0)), flame, 0.22, 2.4)


func _fire() -> void:
	var s := 0.0
	_shot(-6.0, 0.0)
	_shot(6.0, 0.0)
	if power >= 2:
		s = 0.025 if focus else 0.1
		_shot(-12.0, -s)
		_shot(12.0, s)
	if power >= 3:
		_shot(0.0, 0.0)
	if power >= 4:
		s = 0.06 if focus else 0.26
		_shot(-16.0, -s)
		_shot(16.0, s)


## LASER: feixes rápidos e finos que ATRAVESSAM inimigos. Ótimo contra filas e chefes.
func _fire_laser() -> void:
	var lines: int = [1, 2, 2, 3][power - 1]
	var dmg := 1.4 if power < 3 else 1.75
	var gap := 6.0 if focus else 11.0
	for i in lines:
		var dx := (i - (lines - 1) / 2.0) * gap
		main.bullets.add_shot(position + Vector2(dx, -24.0), Vector2(0, -1500.0), dmg, 1)


## ENXAME: orbes teleguiados mais lentos que procuram o alvo mais próximo. Nunca erram, mas batem fraco.
func _fire_homing() -> void:
	var n: int = [2, 3, 4, 6][power - 1]
	var spread := 0.25 if focus else 0.45
	for i in n:
		var a := -PI / 2.0 + (i - (n - 1) / 2.0) * spread
		main.bullets.add_shot(position + Vector2(0, -10.0), Vector2.from_angle(a) * 600.0, 1.6, 2)


func _shot(dx: float, a: float) -> void:
	var ang := -PI / 2.0 + a
	main.bullets.add_shot(position + Vector2(dx, -14.0), Vector2.from_angle(ang) * Cfg.SHOT_SPEED, 1.0)


func hit() -> void:
	if invuln > 0.0 or dead:
		return
	lives -= 1
	power = maxi(1, power - 1)
	invuln = Cfg.INVULN_TIME
	main.fx.explode(position, Cfg.CYAN, 1.4)
	main.fx.add_shake(14.0)
	main.fx.flash(Cfg.RED, 0.35)
	main.bullets.cancel(position, 170.0, false)   # limpa a área: segunda chance justa
	Sfx.play("player_hit")
	if lives <= 0:
		dead = true
		main.fx.explode(position, Cfg.CYAN, 3.0)
		main.fx.explode(position, Cfg.MAGENTA, 2.0)
		Sfx.play("big_explode")


func bomb() -> void:
	if bombs <= 0 or dead or bombing > 0.0:
		return
	bombs -= 1
	bombing = 1.0
	invuln = maxf(invuln, 2.4)
	main.bullets.cancel_all(true)
	main.fx.ring(position, Cfg.CYAN, 650.0, 0.9, 10.0)
	main.fx.ring(position, Cfg.MAGENTA, 450.0, 0.7, 6.0)
	main.fx.flash(Cfg.CYAN, 0.4)
	main.fx.add_shake(10.0)
	Sfx.play("bomb")
	main.bomb_damage()


func _draw() -> void:
	if dead:
		return
	var blink := invuln > 0.0 and int(invuln * 16.0) % 2 == 0
	if not blink:
		# inclina as asas na direção do movimento
		var rw := 15.0 * (1.0 - 0.3 * maxf(0.0, tilt))
		var lw := 15.0 * (1.0 - 0.3 * maxf(0.0, -tilt))
		var body := PackedVector2Array([Vector2(0, -22), Vector2(rw, 15), Vector2(0, 8), Vector2(-lw, 15)])
		Neon.poly(self, body, Cfg.WEAPON_COLORS[weapon], 2.2, 0.12)   # a nave assume a cor da arma
		Neon.poly(self, PackedVector2Array([Vector2(0, -10), Vector2(4, 2), Vector2(-4, 2)]), Cfg.MAGENTA, 1.2, 0.3)
		Neon.glow(self, Vector2(0, 15), 9.0 + randf() * 3.0, Cfg.MAGENTA)
	# hitbox sempre visível (pequena); maior e com raio de graze no foco
	Neon.orb(self, Vector2.ZERO, 3.0 if focus else 2.2, Cfg.WHITE)
	if focus:
		draw_arc(Vector2.ZERO, Cfg.GRAZE_RADIUS, 0.0, TAU, 32, Color(Cfg.CYAN, 0.35), 1.0, true)
