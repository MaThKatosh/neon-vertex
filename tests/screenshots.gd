extends SceneTree
## Abre o jogo com janela, avança por momentos-chave e salva capturas de tela.
## Rodar:  godot --path . -s res://tests/screenshots.gd -- <pasta_de_saida>

var main
var frame := 0
var out := "user://"
var shots := {
	90: "01_titulo",
	700: "02_fase1",
	1500: "03_fase1_mais",
}


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		out = args[0]
	main = load("res://scenes/main.tscn").instantiate()
	main.save_enabled = false
	root.add_child(main)


func _physics_process(_dt: float) -> bool:
	frame += 1
	if main.state == "playing":
		main.player.invuln = 999.0
		# movimenta a nave de um lado para o outro
		main.player.position.x = 270.0 + sin(frame * 0.02) * 150.0
	if frame == 100:
		main._new_game()
	if frame == 1600:
		main._begin_stage(0)
		main.phase = "warning"
		main.pt = 10.0
	if frame == 1900:
		main.player.power = 4
		main.player.weapon = "laser"
		main.items.spawn(Vector2(400, 500), "W")
		main.items.spawn(Vector2(140, 520), "W")
	if frame == 2560:
		main.player.weapon = "homing"
	if frame == 2100:
		_snap("04_chefe_quadrado")
	if frame == 2150:
		main.boss.damage(99999.0)
	if frame == 2500:
		_snap("05_quadrado_fase2")
	if frame == 2560:
		main._begin_stage(3)
		main.phase = "warning"
		main.pt = 10.0
	if frame == 3100:
		main.boss.damage(99999.0)
	if frame == 3500:
		_snap("06_hexagono_fase2")
	if frame == 3560:
		main.player.invuln = 0.0
		main.player.bombs = 3
		main.player.bomb()
	if frame == 3575:
		_snap("07_bomba")
	if frame == 3600:
		main._set_state("paused")
	if frame == 3640:
		_snap("08_pausa")
		quit(0)
	if shots.has(frame):
		_snap(shots[frame])
	return false


func _snap(name: String) -> void:
	var img := root.get_texture().get_image()
	img.save_png(out.path_join(name + ".png"))
	print("captura: ", name)
