extends SceneTree
## Abre o jogo com janela e salva capturas: menu, controles, Hangar (abas) e jogo no celular com armas novas.
## Rodar:  godot --path . -s res://tests/screenshots.gd -- <pasta_de_saida>

var main
var frame := 0
var out := "user://"


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		out = args[0]
	var prof = root.get_node("Profile")
	prof.save_enabled = false
	prof.credits = 2350
	prof.ng_cleared = 2
	prof.ng_selected = 0
	prof.levels = {"hearts": 1, "damage": 2, "shield": 1, "drones": 2, "laser": 1, "prism": 1, "collector": 1}
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)


func _physics_process(_dt: float) -> bool:
	frame += 1
	var ctl = root.get_node("Controls")
	match frame:
		90:
			_snap("01_titulo")
			main._on_title_menu(1)
			main.ctl_sel = 5
			main.ctl_col = 1
		150:
			_snap("02_controles")
			main._to_title()
			main._on_title_menu(0)
			main.shop_sel = 1
		210:
			_snap("03_hangar_nave")
			main._shop_set_tab(2)
			main.shop_sel = 2
		260:
			_snap("04_hangar_elite")
			main.shop_sel = main.shop_cards().size() + 1
			root.get_node("Profile").ng_selected = 2
		300:
			_snap("05_hangar_modo")
			ctl.is_touch = true
			main._shop_set_tab(0)
			main.shop_sel = main.shop_cards().size() + 2
			main._shop_activate(main.shop_sel)
			main.player.power = 4
			main.player.weapon = "prism"
		700:
			_snap("06_jogo_prisma_toque")
			main.player.weapon = "pulse"
		900:
			_snap("07_jogo_pulso")
			quit(0)
	if main.state == "playing":
		main.player.invuln = 999.0
		main.player.position.x = 270.0 + sin(frame * 0.02) * 150.0
	return false


func _snap(name: String) -> void:
	var img := root.get_texture().get_image()
	img.save_png(out.path_join(name + ".png"))
	print("captura: ", name)
