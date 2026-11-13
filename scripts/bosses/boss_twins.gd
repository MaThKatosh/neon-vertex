extends Boss
## LOSANGOS GÊMEOS — dois chefes ao mesmo tempo, com a mesma barra de vida.
##   Fase 1: orbitam um centro e atiram alternadamente.
##   Fase 2: vão para as laterais e fazem fogo cruzado, criando "faixas" para você atravessar.
##   Fase 3: giram juntos ligados por um laser que vira uma lâmina, abrindo e fechando.

const COL_A := Color(1.0, 0.231, 0.553)   # rosa
const COL_B := Color(0.482, 0.361, 1.0)   # violeta

var pa := Vector2.ZERO
var pb := Vector2.ZERO
var _oa := 0.0
var _orad := 130.0
var _orbit := true
var _turn := 0
var _link = null


func _define() -> void:
	boss_name = "GÊMEOS // LSG-07"
	color = COL_A
	radius = 34.0
	phase_hp = [1100, 1200, 1300]


func _animate(_dt: float) -> void:
	if _orbit:
		var off := Vector2.from_angle(_oa) * _orad
		pa = position + off
		pb = position - off


func hit_points() -> Array:
	return [[pa, radius], [pb, radius]]


func _phase(i: int, dt_: float) -> void:
	match i:
		0:
			_orbit = true
			_orad = 130.0
			_oa += dt_ * 1.4
			move_to(Vector2(Cfg.W / 2.0 + sin(pt * 0.6) * 80.0, 230.0), 2.0)
			if every("alt", 0.7):
				_turn += 1
				var src := pa if _turn % 2 == 0 else pb
				var c := COL_A if _turn % 2 == 0 else COL_B
				bl.aim_fan(src, 3, 0.35, 220.0, {"color": c})
			if every("ring", 2.2):
				bl.ring(pa, 10, 140.0, randf() * TAU, {"color": COL_A})
				bl.ring(pb, 10, 140.0, randf() * TAU, {"color": COL_B})
		1:
			_orbit = false
			var k := minf(1.0, 2.0 * dt_)
			pa = pa.lerp(Vector2(70.0, 220.0 + sin(pt * 0.9) * 150.0), k)
			pb = pb.lerp(Vector2(Cfg.W - 70.0, 220.0 + cos(pt * 0.9) * 150.0), k)
			if pt > 1.0 and every("cross", 0.45):
				bl.stack(pa, 0.15, 3, 180.0, 260.0, {"color": COL_A, "needle": true})
				bl.stack(pb, PI - 0.15, 3, 180.0, 260.0, {"color": COL_B, "needle": true})
			if pt > 1.0 and every("aim", 1.6):
				bl.aim_fan(pa, 2, 0.2, 240.0, {"color": COL_A})
				bl.aim_fan(pb, 2, 0.2, 240.0, {"color": COL_B})
		2:
			# volta suavemente para a órbita antes de ligar a lâmina
			_orbit = pt > 0.8
			if not _orbit:
				pa = pa.lerp(position + Vector2(-140, 0), minf(1.0, 3.0 * dt_))
				pb = pb.lerp(position + Vector2(140, 0), minf(1.0, 3.0 * dt_))
				return
			move_to(Vector2(Cfg.W / 2.0, 240.0), 2.0)
			_oa += dt_ * 1.6
			_orad = 150.0 + sin(pt * 0.7) * 90.0
			if _link == null or not _link.alive:
				_link = bl.beam(pa, 0.0, 1.0, 999.0, 12.0, COL_B)
			_link.pos = pa
			_link.ang = (pb - pa).angle()
			_link.length = pa.distance_to(pb)
			if every("spiral", 0.14):
				bl.shoot(pa, _oa + PI / 2.0, 150.0, {"color": COL_A})
				bl.shoot(pb, _oa - PI / 2.0, 150.0, {"color": COL_B})
			if every("aim", 2.0):
				bl.aim_fan(position, 5, 0.6, 230.0, {"color": Cfg.ORANGE, "needle": true})


func _diamond(c: Vector2, s: float, col: Color) -> void:
	Neon.poly(self, PackedVector2Array([c + Vector2(0, -s * 1.3), c + Vector2(s * 0.8, 0), c + Vector2(0, s * 1.3), c + Vector2(-s * 0.8, 0)]), col, 2.6, 0.1)
	Neon.poly(self, PackedVector2Array([c + Vector2(0, -s * 0.6), c + Vector2(s * 0.4, 0), c + Vector2(0, s * 0.6), c + Vector2(-s * 0.4, 0)]), col, 1.6, 0.25)
	Neon.orb(self, c, 5.0, col)


func _draw_body(col: Color) -> void:
	var flash_on := col != color
	var a := pa - position
	var b := pb - position
	draw_line(a, b, Color(COL_B, 0.12), 2.0)
	_diamond(a, 36.0, Cfg.WHITE if flash_on else COL_A)
	_diamond(b, 36.0, Cfg.WHITE.lerp(COL_B, 0.6) if flash_on else COL_B)
