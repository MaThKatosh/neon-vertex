extends SceneTree
## Diretor do trailer: roda o jogo no modo Movie Maker do Godot e anota onde começa/termina cada cena.
## Rodar:  godot --path . --resolution 540x960 --fixed-fps 60 --write-movie <saida.avi> -s res://tests/trailer.gd -- <cenas.txt>
## Depois tools/trailer.cmd usa o FFmpeg para cortar as cenas e montar o MP4 e o GIF.

# [setor, fase do chefe, arma, segundos gravados]  (setor -1 = jogo normal do setor 1)
const SCENES := [
	[-1, 0, "spread", 4.0],
	[5, 1, "laser", 5.0],
	[6, 2, "prism", 4.5],
	[7, 0, "homing", 4.0],
	[8, 2, "pulse", 4.5],
	[9, 4, "vertex", 6.0],
]

var main
var prof
var frame := 0
var marks: Array = []        # [início, fim] em quadros
var out := "user://cenas.txt"
var idx := -2                # -2 = tela inicial
var rec_from := -1
var t0 := 0


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		out = args[0]
	prof = root.get_node("Profile")
	prof.save_enabled = false
	prof.settings["tips"] = false
	prof.settings["lang"] = "pt"
	prof.credits = 0
	prof.hi = 1250000
	prof.ng_cleared = 3
	prof.levels = {"hearts": 2, "damage": 3, "drones": 2, "shield": 1, "laser": 1, "homing": 1, "prism": 1, "pulse": 1, "vertex": 1}
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)


func _physics_process(_dt: float) -> bool:
	frame += 1
	if idx == -2:
		if frame == 20:
			prof.apply_settings()
			rec_from = frame
		if frame == 20 + 150:   # 2,5 s de tela inicial
			marks.append([rec_from, frame])
			main.god_mode = true
			main._new_game()
			main.player.power = 3
			idx = -1
			_next()
		return false
	if idx >= SCENES.size():
		return false

	var sc: Array = SCENES[idx]
	main.player.invuln = 0.0
	main.player.position = Vector2(270.0 + sin(frame * 0.025) * 150.0, 800.0 + sin(frame * 0.04) * 40.0)
	var b = main.boss
	if int(sc[0]) >= 0:
		if b != null and b.state == "fight" and b.phase < int(sc[1]) and frame - t0 > 120:
			b.damage(99999.0)
		if rec_from < 0 and b != null and b.state == "fight" and b.phase == int(sc[1]) and b.pt > 0.6:
			rec_from = frame
	elif rec_from < 0 and frame - t0 > 100:
		rec_from = frame
	if rec_from >= 0 and frame - rec_from >= int(float(sc[3]) * 60.0):
		marks.append([rec_from, frame])
		_next()
	return false


func _next() -> void:
	idx += 1
	rec_from = -1
	t0 = frame
	if idx >= SCENES.size():
		var f := FileAccess.open(out, FileAccess.WRITE)
		for m in marks:
			f.store_line("%d %d" % [m[0], m[1]])
		f.close()
		print("cenas: ", marks)
		quit(0)
		return
	var sc: Array = SCENES[idx]
	main.player.weapon = sc[2]
	main.player.power = 4 if idx > 0 else 3
	if int(sc[0]) >= 0:
		main._begin_stage(int(sc[0]))
		main.phase = "warning"
		main.pt = 10.0
