class_name Enemy
extends Node2D
## Inimigo comum. O campo `kind` escolhe comportamento e desenho:
##   diamond — losango que só desce (volume)
##   gunner  — quadrado que para e atira leques mirados
##   dart    — triângulo que entra pela lateral numa curva e dispara uma vez
##   orb     — círculo kamikaze que mira e avança no jogador
##   turret  — hexágono pesado que gira disparando anéis
## Parâmetros extras vêm do roteiro da fase (vx, vy, wob, ty, stay, rate, n, fire_at).

const DEFS := {
	"diamond": {"hp": 3, "r": 15.0, "score": 100},
	"gunner": {"hp": 14, "r": 20.0, "score": 300},
	"dart": {"hp": 5, "r": 15.0, "score": 150},
	"orb": {"hp": 2, "r": 12.0, "score": 80},
	"turret": {"hp": 45, "r": 28.0, "score": 1000},
}

var main
var kind := ""
var hp := 1.0
var r := 10.0
var score := 0
var color := Color.WHITE
var t := 0.0
var rot := 0.0
var flash := 0.0
var alive := true
var vel := Vector2.ZERO
var p: Dictionary = {}

var _cd := 0.0
var _fired := false
var _homed := false
var _a := 0.0
var _ph := 0.0


func setup(m, k: String, pos: Vector2, params: Dictionary) -> void:
	main = m
	kind = k
	position = pos
	p = params
	z_index = 2
	var d: Dictionary = DEFS[k]
	hp = ceilf(float(d["hp"]) * main.hp_mul)
	r = d["r"]
	score = d["score"]
	_ph = randf() * TAU
	match kind:
		"diamond":
			color = Cfg.MAGENTA
			vel = Vector2(_pf("vx", 0.0), _pf("vy", 210.0))
		"gunner":
			color = Cfg.YELLOW
			_cd = 1.0
		"dart":
			color = Cfg.ORANGE
			var dir := 1.0 if pos.x < Cfg.W / 2.0 else -1.0
			vel = Vector2(300.0 * dir, 40.0)
		"orb":
			color = Cfg.PURPLE
			vel = Vector2(_pf("vx", 0.0), _pf("vy", 160.0))
		"turret":
			color = Cfg.VIOLET
			_cd = 0.8


func _pf(key: String, fallback: float) -> float:
	return float(p.get(key, fallback))


func step(dt: float) -> void:
	t += dt
	flash = maxf(0.0, flash - dt)
	var bl = main.bullets
	match kind:
		"diamond":
			position += Vector2(vel.x + cos(t * 3.0 + _ph) * _pf("wob", 0.0), vel.y) * dt
		"gunner":
			var stay := _pf("stay", 6.0)
			if t < stay:
				position.y += (_pf("ty", 200.0) - position.y) * minf(1.0, 2.5 * dt)
			else:
				position.y -= 150.0 * dt
			rot += dt * 1.2
			if t > 0.6 and t < stay:
				_cd -= dt * main.rate_mul
				if _cd <= 0.0:
					_cd = _pf("rate", 1.5)
					bl.aim_fan(position, int(_pf("n", 3.0)), 0.35, 220.0, {"color": Cfg.ORANGE, "r": 6.0})
		"dart":
			vel.x *= pow(0.35, dt)
			vel.y += 220.0 * dt
			position += vel * dt
			rot = vel.angle()
			if not _fired and t > _pf("fire_at", 0.75):
				_fired = true
				bl.aim_fan(position, int(_pf("n", 5.0)), 0.8, 190.0, {"color": Cfg.RED, "needle": true})
		"orb":
			if not _homed and t > 0.7:
				_homed = true
				vel = Vector2.from_angle(bl.aim(position)) * 330.0
			if not _homed:
				vel.y *= pow(0.2, dt)
			position += vel * dt
		"turret":
			var stay := _pf("stay", 9.0)
			if t < stay:
				position.y += (_pf("ty", 230.0) - position.y) * minf(1.0, 1.5 * dt)
			else:
				position.y -= 110.0 * dt
			rot += dt * 0.8
			if t > 1.0 and t < stay:
				_cd -= dt * main.rate_mul
				if _cd <= 0.0:
					_cd = 0.32
					bl.ring(position, 6, 150.0, _a, {"color": Cfg.PURPLE, "r": 7.0})
					_a += 0.22
	# saiu da tela? some sem dar pontos
	if t > 1.0 and (position.y > Cfg.H + 70.0 or position.y < -90.0 or position.x < -90.0 or position.x > Cfg.W + 90.0):
		alive = false
	queue_redraw()


func _draw() -> void:
	var col := Cfg.WHITE if flash > 0.0 else color
	match kind:
		"diamond":
			var s := 16.0
			Neon.poly(self, PackedVector2Array([Vector2(0, -s * 1.2), Vector2(s * 0.75, 0), Vector2(0, s * 1.2), Vector2(-s * 0.75, 0)]), col, 2.0, 0.15)
		"gunner":
			Neon.poly(self, Neon.regular(Vector2.ZERO, 22.0, 4, rot + PI / 4.0), col, 2.2, 0.12)
			Neon.poly(self, Neon.regular(Vector2.ZERO, 9.0, 4, -rot * 2.0), col, 1.4, 0.3)
		"dart":
			var s := 17.0
			Neon.poly(self, PackedVector2Array([Vector2.from_angle(rot) * s * 1.3, Vector2.from_angle(rot + 2.4) * s, Vector2.from_angle(rot - 2.4) * s]), col, 2.0, 0.15)
		"orb":
			Neon.ring(self, Vector2.ZERO, 11.0, col, 2.0, 0.15)
			Neon.orb(self, Vector2.ZERO, 3.0, col)
		"turret":
			Neon.poly(self, Neon.regular(Vector2.ZERO, 30.0, 6, rot), col, 2.4, 0.1)
			Neon.poly(self, Neon.regular(Vector2.ZERO, 15.0, 6, -rot * 1.5), col, 1.6, 0.25)
