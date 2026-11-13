extends Boss
## TESSERATO — um cubo de 4 dimensões projetado na tela; a forma se dobra enquanto gira.
##   Fase 1: os vértices disparam para fora (o padrão muda com a rotação 4D).
##   Fase 2: "dobra" — teletransporta (com aviso no destino) e explode em anéis.
##   Fase 3: grade de lasers horizontais e verticais: ache a célula segura.

const ICE := Color(0.82, 0.9, 1.0)

var _verts: Array = []   # 16 vértices 4D
var _edges: Array = []   # 32 arestas
var _a1 := 0.0
var _a2 := 0.0
var tele_to := Vector2.ZERO
var tele_warn := 0.0


func _define() -> void:
	boss_name = "TESSERATO // TSR-09"
	color = ICE
	radius = 62.0
	phase_hp = [1300, 1400, 1600]
	for n in 16:
		_verts.append([
			1.0 if n & 1 else -1.0, 1.0 if n & 2 else -1.0,
			1.0 if n & 4 else -1.0, 1.0 if n & 8 else -1.0])
	for a in 16:
		for bit in [1, 2, 4, 8]:
			var b: int = a ^ bit
			if b > a:
				_edges.append([a, b])


func _animate(dt: float) -> void:
	_a1 += dt * (0.7 + phase * 0.2)
	_a2 += dt * 0.45
	tele_warn = maxf(0.0, tele_warn - dt)


## Projeção 4D -> 3D -> 2D (coordenadas locais).
func _proj() -> PackedVector2Array:
	var pts := PackedVector2Array()
	var c1 := cos(_a1)
	var s1 := sin(_a1)
	var c2 := cos(_a2)
	var s2 := sin(_a2)
	for v in _verts:
		var x: float = v[0] * c1 - v[3] * s1
		var w: float = v[0] * s1 + v[3] * c1
		var y: float = v[1] * c2 - v[2] * s2
		var z: float = v[1] * s2 + v[2] * c2
		var k4 := 1.0 / (2.6 - w)
		var k3 := 1.0 / (3.2 - z * k4)
		pts.append(Vector2(x, y) * k4 * k3 * 230.0)
	return pts


func _phase(i: int, dt_: float) -> void:
	match i:
		0:
			move_to(Vector2(Cfg.W / 2.0 + sin(pt * 0.5) * 100.0, 220.0), 2.0)
			if every("verts", 0.6):
				var pts := _proj()
				for k in 4:
					var v: Vector2 = pts[randi() % pts.size()]
					bl.shoot(position + v, v.angle(), 160.0, {"color": ICE})
					bl.shoot(position + v, v.angle() + 0.2, 130.0, {"color": Cfg.PURPLE})
			if every("aim", 2.0):
				bl.aim_fan(position, 5, 0.5, 230.0, {"color": Cfg.MAGENTA, "needle": true})
		1:
			if not mem.has("s"):
				mem["s"] = "stay"
				mem["tt"] = 1.0
			mem["tt"] -= dt_
			if mem["s"] == "stay":
				if every("verts", 0.5):
					for v in _proj():
						if randf() < 0.2:
							bl.shoot(position + v, v.angle(), 150.0, {"color": ICE})
				if mem["tt"] <= 0.0:
					mem["s"] = "warn"
					mem["tt"] = 0.7
					tele_to = Vector2(randf_range(90.0, Cfg.W - 90.0), randf_range(150.0, 380.0))
					tele_warn = 0.7
					Sfx.play("charge")
			elif mem["tt"] <= 0.0:
				main.fx.ring(position, ICE, 80.0, 0.3, 3.0)
				position = tele_to
				main.fx.ring(position, ICE, 120.0, 0.4, 4.0)
				bl.ring(position, 24, 150.0, randf() * TAU, {"color": ICE})
				bl.aim_fan(position, 5, 0.6, 220.0, {"color": Cfg.PURPLE, "needle": true})
				Sfx.play("slam")
				mem["s"] = "stay"
				mem["tt"] = 1.5
		2:
			move_to(Vector2(Cfg.W / 2.0, 200.0), 2.0)
			if every("grid", 4.4):
				_laser_grid()
			if every("verts", 0.55):
				for v in _proj():
					if randf() < 0.15:
						bl.shoot(position + v, v.angle(), 140.0, {"color": ICE})


## 3 de 6 colunas e 1-2 de 4 linhas viram laser; sempre sobram células seguras.
func _laser_grid() -> void:
	var cols := [0, 1, 2, 3, 4, 5]
	cols.shuffle()
	for k in 3:
		var x: float = 45.0 + cols[k] * 90.0
		bl.beam(Vector2(x, -20.0), PI / 2.0, 1.1, 1.0, 24.0, Cfg.MAGENTA, 0.0, 1100.0)
	var rows := [0, 1, 2, 3]
	rows.shuffle()
	for k in randi_range(1, 2):
		var y: float = 520.0 + rows[k] * 100.0
		bl.beam(Vector2(-20.0, y), 0.0, 1.1, 1.0, 24.0, Cfg.MAGENTA, 0.0, 600.0)


func _draw_body(col: Color) -> void:
	var pts := _proj()
	for e in _edges:
		var a: Vector2 = pts[e[0]]
		var b: Vector2 = pts[e[1]]
		draw_line(a, b, Color(col, 0.15), 6.0, true)
		draw_line(a, b, Neon.hot(col, 1.2), 1.6, true)
	for v in pts:
		Neon.glow(self, v, 7.0, col)
	Neon.orb(self, Vector2.ZERO, 6.0, col)
	if tele_warn > 0.0:
		var p := tele_to - position
		var al := 0.4 + 0.4 * absf(sin(t * 25.0))
		draw_arc(p, 50.0, 0.0, TAU, 40, Color(col, al), 2.0, true)
		draw_line(p + Vector2(-60, 0), p + Vector2(60, 0), Color(col, al), 1.5)
		draw_line(p + Vector2(0, -60), p + Vector2(0, 60), Color(col, al), 1.5)
