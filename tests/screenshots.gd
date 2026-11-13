extends SceneTree
## Abre o jogo com janela e salva capturas: menu, opções, Hangar e jogo (em português e em inglês).
## Rodar:  godot --path . --resolution 540x960 -s res://tests/screenshots.gd -- <pasta_de_saida>

var main
var prof
var frame := 0
var out := "user://"


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		out = args[0]
	prof = root.get_node("Profile")
	prof.save_enabled = false
	prof.credits = 2350
	prof.ng_cleared = 2
	prof.levels = {"hearts": 1, "damage": 2, "shield": 1, "drones": 2, "laser": 1, "prism": 1}
	prof.settings["lang"] = "pt"
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)


func _physics_process(_dt: float) -> bool:
	frame += 1
	match frame:
		60:
			prof.settings["lang"] = "pt"
			prof.apply_settings()
		90:
			_snap("01_titulo_pt")
			main._on_title_menu(1)
			main.opt_sel = 2
		130:
			_snap("02_opcoes_pt")
			main._opt_adjust("lang", 1)   # muda para inglês
		170:
			_snap("03_opcoes_en")
			main._menu_back()
		210:
			_snap("04_titulo_en")
			main._on_title_menu(0)
			main.shop_sel = 2
		250:
			_snap("05_hangar_en")
			main.shop_sel = main.shop_cards().size() + 2
			main._shop_activate(main.shop_sel)
			main.player.power = 3
		330:
			_snap("06_jogo_en_banner")
			main._set_state("paused")
		360:
			_snap("07_pausa_en")
			quit(0)
	if main.state == "playing":
		main.player.invuln = 999.0
	return false


func _snap(name: String) -> void:
	root.get_texture().get_image().save_png(out.path_join(name + ".png"))
	print("captura: ", name)
