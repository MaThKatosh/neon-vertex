extends Node2D
## Itens que caem: P = poder, B = bomba, V = vida extra, W = arma.
## O item W troca de arma a cada 1,2 s enquanto cai: pegue na hora certa para escolher.
## Pegar a mesma arma que você já usa aumenta o poder.
## São atraídos pelo jogador quando ele chega perto ou sobe até o topo da tela.

const WEAPON_CYCLE := 1.2

class Item:
	var pos := Vector2.ZERO
	var vel := Vector2.ZERO
	var kind := "P"
	var t := 0.0
	var magnet := false
	var w0 := 0

var main
var list: Array = []


func _ready() -> void:
	z_index = 1


func spawn(pos: Vector2, kind: String) -> void:
	var it := Item.new()
	it.pos = pos
	it.vel = Vector2(randf_range(-60.0, 60.0), -180.0)
	it.kind = kind
	it.w0 = randi() % Cfg.WEAPONS.size()
	list.append(it)


## O item W alterna entre as 3 armas básicas + as exclusivas que você já comprou.
func weapon_of(it) -> String:
	var own: Array = Cfg.WEAPONS.slice(0, 3)
	for w in Profile.owned_weapons():
		if not own.has(w):
			own.append(w)
	return own[(it.w0 + int(it.t / WEAPON_CYCLE)) % own.size()]


func magnet_all() -> void:
	for it in list:
		it.magnet = true


func clear_all() -> void:
	list.clear()


func step(dt: float) -> void:
	var pl = main.player
	var keep: Array = []
	for it in list:
		it.t += dt
		var d2: float = it.pos.distance_squared_to(pl.position)
		# a arma não é puxada pela linha do topo, para dar tempo de escolher
		var top_pull: bool = pl.position.y < Cfg.H * 0.28 and it.kind != "W"
		var mr := Profile.magnet_radius()
		if not pl.dead and (it.magnet or d2 < mr * mr or top_pull):
			it.pos += (pl.position - it.pos).normalized() * 560.0 * dt
		else:
			var fall := 80.0 if it.kind == "W" else 110.0
			it.vel.y = minf(it.vel.y + 300.0 * dt, fall)
			it.vel.x *= pow(0.1, dt)
			it.pos += it.vel * dt
		if not pl.dead and d2 < 28.0 * 28.0:
			main.collect(it.kind, it.pos, weapon_of(it) if it.kind == "W" else "")
			continue
		if it.pos.y > Cfg.H + 30.0:
			continue
		keep.append(it)
	list = keep
	queue_redraw()


static func color_of(kind: String) -> Color:
	match kind:
		"B":
			return Cfg.YELLOW
		"V":
			return Cfg.PINK
	return Cfg.LIME


func _draw() -> void:
	for it in list:
		if it.kind == "W":
			var w := weapon_of(it)
			var wc: Color = Cfg.WEAPON_COLORS[w]
			var ws: float = 15.0 + sin(it.t * 8.0) * 1.5
			Neon.poly(self, Neon.regular(it.pos, ws, 6, it.t * 1.5), wc, 2.2, 0.3)
			Neon.text(self, Cfg.WEAPON_LETTER[w], it.pos, 14, Cfg.WHITE, HORIZONTAL_ALIGNMENT_CENTER, false)
			continue
		var col := color_of(it.kind)
		var s: float = 12.0 + sin(it.t * 8.0) * 1.5
		Neon.poly(self, Neon.regular(it.pos, s, 4, it.t * 2.0), col, 1.8, 0.2)
		Neon.text(self, it.kind, it.pos, 12, Cfg.WHITE, HORIZONTAL_ALIGNMENT_CENTER, false)
