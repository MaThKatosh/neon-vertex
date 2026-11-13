extends SceneTree
## Abre o jogo com janela e salva capturas: Hangar e cada chefe numa fase escolhida.
## Rodar:  godot --path . -s res://tests/screenshots.gd -- <pasta_de_saida>

const SHOTS := [
	# [índice do setor, fase do chefe, nome do arquivo]
	[2, 2, "chefe_03_triangulo_f3"],
	[5, 1, "chefe_06_estrela_f2"],
	[6, 2, "chefe_07_gemeos_f3"],
	[7, 0, "chefe_08_octogono_f1"],
	[8, 2, "chefe_09_tesserato_f3"],
	[9, 0, "chefe_10_caos_f1"],
	[9, 4, "chefe_10_caos_f5"],
]

var main
var frame := 0
var out := "user://"
var idx := -1
var t0 := 0


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		out = args[0]
	var prof = root.get_node("Profile")
	prof.save_enabled = false
	prof.credits = 1850
	prof.levels = {"hearts": 1, "damage": 2, "shield": 1, "drones": 2, "laser": 1}
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)


func _physics_process(_dt: float) -> bool:
	frame += 1
	if frame == 60:
		main._open_shop()
		main.shop_sel = 10
	if frame == 120:
		_snap("hangar")
		main._new_game()
		main.player.power = 4
		_next()
	if idx >= 0 and idx < SHOTS.size():
		main.player.invuln = 999.0
		main.player.position.x = 270.0 + sin(frame * 0.02) * 150.0
		var target_phase: int = SHOTS[idx][1]
		var since := frame - t0
		var b = main.boss
		if b != null and b.state == "fight" and b.phase < target_phase and since > 200:
			b.damage(99999.0)
		if b != null and b.state == "fight" and b.phase == target_phase and b.pt > 4.0:
			_snap(SHOTS[idx][2])
			_next()
	if idx >= SHOTS.size() or frame > 60 * 60 * 6:
		quit(0)
	return false


func _next() -> void:
	idx += 1
	if idx >= SHOTS.size():
		return
	t0 = frame
	main._begin_stage(SHOTS[idx][0])
	main.phase = "warning"
	main.pt = 10.0


func _snap(name: String) -> void:
	var img := root.get_texture().get_image()
	img.save_png(out.path_join(name + ".png"))
	print("captura: ", name)
