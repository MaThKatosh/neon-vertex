class_name Boss
extends Node2D
## Base de todos os chefes: entrada, fases com barra de vida, transições e morte.
##
## Para criar um chefe novo: crie um script `extends Boss` e implemente
##   _define()           -> nome, cor, raio e vida de cada fase
##   _phase(i, dt)       -> o comportamento da fase i (movimento + disparos)
##   _draw_body(col)     -> o desenho
## Use `every("chave", intervalo)` para disparar algo periodicamente e `mem` para guardar estado da fase.

var main
var bl                      # atalho para main.bullets
var boss_name := "CHEFE"
var color := Cfg.WHITE
var radius := 60.0
var phase_hp: Array = []
var phase := 0
var hp := 1.0
var state := "enter"        # enter | fight | transition | dying
var st := 0.0               # tempo no estado atual
var pt := 0.0               # tempo na fase atual
var t := 0.0
var rot := 0.0
var spin := 1.0
var flash := 0.0
var alive := true
var mem := {}               # memória da fase atual (zerada a cada fase)
var dt := 0.0
var disp_frac := 1.0        # usado pela barra de vida (animação)


func setup(m) -> void:
	main = m
	bl = m.bullets
	_define()
	for i in phase_hp.size():
		phase_hp[i] = ceilf(float(phase_hp[i]) * main.hp_mul * Cfg.BOSS_HP_SCALE)
	hp = phase_hp[0]
	position = Vector2(Cfg.W / 2.0, -160.0)
	z_index = 2


func _define() -> void:
	pass


func _phase(_i: int, _dt: float) -> void:
	pass


func _draw_body(_col: Color) -> void:
	pass


# ------------------------------------------------------------------ ajudantes

func every(key: String, interval: float) -> bool:
	if not mem.has(key):
		mem[key] = minf(interval, 0.6)
	mem[key] -= dt * main.rate_mul * Cfg.BOSS_RATE_SCALE
	if mem[key] <= 0.0:
		mem[key] += interval
		return true
	return false


func move_to(target: Vector2, k: float) -> void:
	position += (target - position) * minf(1.0, k * dt)


## Vida restante total (0..1), somando as fases que faltam.
func frac() -> float:
	var total := 0.0
	var rem := 0.0
	for i in phase_hp.size():
		total += phase_hp[i]
		if i > phase:
			rem += phase_hp[i]
	if state != "dying":
		rem += maxf(0.0, hp)
	return rem / total


# ------------------------------------------------------------------ ciclo

func step(delta: float) -> void:
	dt = delta
	t += delta
	st += delta
	flash = maxf(0.0, flash - delta)
	rot += delta * (0.5 + phase * 0.5) * spin
	queue_redraw()
	match state:
		"enter":
			move_to(Vector2(Cfg.W / 2.0, 210.0), 1.6)
			if st > 2.4:
				_set_state("fight")
		"transition":
			move_to(Vector2(Cfg.W / 2.0, 210.0), 2.5)
			if st > 1.5:
				_set_state("fight")
		"dying":
			position.x += randf_range(-2.0, 2.0)
			if randf() < 0.25:
				var c: Color = [color, Cfg.WHITE, Cfg.MAGENTA].pick_random()
				main.fx.explode(position + Vector2(randf_range(-60.0, 60.0), randf_range(-60.0, 60.0)), c, 1.2)
				main.fx.add_shake(6.0)
				Sfx.play("explode")
			if st > 2.6:
				alive = false
				main.fx.explode(position, color, 4.0)
				main.fx.explode(position, Cfg.WHITE, 3.0)
				main.fx.ring(position, color, 500.0, 1.0, 8.0)
				main.fx.flash(Cfg.WHITE, 0.6)
				main.fx.add_shake(22.0)
				Sfx.play("big_explode")
				main.on_boss_defeated(self)
		"fight":
			pt += delta
			_phase(phase, delta)
			position.x = clampf(position.x, 50.0, Cfg.W - 50.0)
			position.y = clampf(position.y, 60.0, Cfg.H * 0.6)


func damage(d: float) -> bool:
	if state != "fight":
		return false
	hp -= d
	flash = 0.04
	if hp <= 0.0:
		_next_phase()
	return true


func _next_phase() -> void:
	main.kill_all_enemies()
	main.bullets.cancel_all(true)
	main.fx.explode(position, color, 2.5)
	main.fx.ring(position, Cfg.WHITE, 300.0, 0.6, 5.0)
	main.fx.add_shake(12.0)
	main.fx.flash(color, 0.25)
	main.add_score(3000)
	Sfx.play("phase")
	phase += 1
	if phase >= phase_hp.size():
		hp = 0.0
		_set_state("dying")
		return
	hp = phase_hp[phase]
	_set_state("transition")


func _set_state(s: String) -> void:
	state = s
	st = 0.0
	if s == "fight":
		pt = 0.0
		mem = {}


func _draw() -> void:
	# leve clarão ao tomar dano (sem apagar a cor do chefe, que toma tiro o tempo todo)
	_draw_body(color.lerp(Cfg.WHITE, 0.35) if flash > 0.0 else color)


## Desenho padrão para chefes poligonais: 3 polígonos girando + núcleo + vértices brilhantes.
func draw_poly_body(col: Color, sides: int, size: float) -> void:
	Neon.poly(self, Neon.regular(Vector2.ZERO, size, sides, rot), col, 3.0, 0.08)
	Neon.poly(self, Neon.regular(Vector2.ZERO, size * 0.62, sides, -rot * 1.4 + PI / sides), col, 2.0, 0.12)
	Neon.poly(self, Neon.regular(Vector2.ZERO, size * 0.28, sides, rot * 2.0), col, 1.6, 0.3)
	for v in Neon.regular(Vector2.ZERO, size, sides, rot):
		Neon.glow(self, v, 10.0, col)
	Neon.orb(self, Vector2.ZERO, 6.0 * (1.2 + sin(t * 6.0) * 0.15), col)
