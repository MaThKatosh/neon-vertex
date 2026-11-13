extends SceneTree
## Gera as imagens da página da loja (itch.io): capa 630x500 + capturas 540x960.
## Rodar:  godot --path . --resolution 540x960 -s res://tests/store_media.gd -- <pasta_de_saida>

const BOSSES := [
	# [setor, fase, nome]
	[5, 1, "03_estrela_lasers"],
	[6, 2, "04_gemeos"],
	[7, 0, "05_octogono"],
	[9, 4, "06_caos_final"],
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
	prof.credits = 4820
	prof.hi = 1250000
	prof.ng_cleared = 3
	prof.ng_selected = 0
	prof.levels = {"hearts": 1, "damage": 3, "rate": 2, "shield": 1, "drones": 2, "laser": 1, "homing": 1, "prism": 1, "collector": 1, "pulse": 1}
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)


func _physics_process(_dt: float) -> bool:
	frame += 1
	if frame == 100:
		var img := _grab()
		img.save_png(out.path_join("02_titulo.png"))
		# capa: recorte do topo da tela inicial (nome + chefes) ampliado para 630x500
		var cover := img.get_region(Rect2i(0, 70, 540, 429))
		cover.resize(630, 500, Image.INTERPOLATE_LANCZOS)
		cover.save_png(out.path_join("00_capa_630x500.png"))
		print("capa e título ok")
		main._on_title_menu(0)
		main.shop_sel = 1
	if frame == 160:
		_grab().save_png(out.path_join("07_hangar.png"))
		main._new_game()
		main.player.power = 4
		main.player.weapon = "laser"
		_next()
	if idx >= 0 and idx < BOSSES.size():
		main.player.invuln = 999.0
		main.player.position.x = 270.0 + sin(frame * 0.02) * 140.0
		var target: int = BOSSES[idx][1]
		var b = main.boss
		if b != null and b.state == "fight" and b.phase < target and frame - t0 > 200:
			b.damage(99999.0)
		if b != null and b.state == "fight" and b.phase == target and b.pt > 3.5:
			_grab().save_png(out.path_join(BOSSES[idx][2] + ".png"))
			print("captura: ", BOSSES[idx][2])
			_next()
	if idx >= BOSSES.size() or frame > 60 * 60 * 5:
		quit(0)
	return false


func _next() -> void:
	idx += 1
	if idx >= BOSSES.size():
		return
	t0 = frame
	main.player.weapon = ["laser", "prism", "homing", "pulse"][idx]
	main._begin_stage(BOSSES[idx][0])
	main.phase = "warning"
	main.pt = 10.0


func _grab() -> Image:
	return root.get_texture().get_image()
