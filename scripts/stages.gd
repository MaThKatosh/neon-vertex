class_name Stages
extends RefCounted
## Roteiro das fases — é aqui que você desenha as ondas de inimigos, sem mexer em código.
##
## Cada evento: [tempo_em_segundos, formação, tipo_de_inimigo, argumentos...]
##   ["one",    tipo, x, {params}]              — um inimigo em x
##   ["stream", tipo, x, n, intervalo, {params}] — n inimigos em fila (x pode ser "rand" ou "alt")
##   ["row",    tipo, n, {params}]              — n inimigos lado a lado
##   ["sweep",  tipo, lado(-1/1), n, intervalo, {params}] — entram pela lateral
##   ["vee",    tipo, x_centro, n, {params}]    — formação em V
## Os {params} são opcionais (veja enemy.gd). Mantenha os eventos em ordem de tempo.

const W := Cfg.W

const STAGE_1 := [
	[1.0, "stream", "diamond", W * 0.3, 5, 0.32],
	[3.0, "stream", "diamond", W * 0.7, 5, 0.32],
	[5.5, "row", "diamond", 6, {"vy": 170.0}],
	[7.5, "one", "gunner", W * 0.5, {"ty": 210.0}],
	[10.0, "sweep", "dart", -1.0, 4, 0.35],
	[12.5, "sweep", "dart", 1.0, 4, 0.35],
	[15.0, "one", "gunner", W * 0.25, {"ty": 180.0}],
	[15.0, "one", "gunner", W * 0.75, {"ty": 240.0}],
	[17.0, "stream", "diamond", 60.0, 6, 0.3, {"vx": 60.0, "wob": 120.0}],
	[17.0, "stream", "diamond", W - 60.0, 6, 0.3, {"vx": -60.0, "wob": 120.0}],
	[21.0, "vee", "diamond", W * 0.5, 7, {"vy": 230.0}],
	[23.0, "sweep", "dart", -1.0, 3, 0.3],
	[23.0, "sweep", "dart", 1.0, 3, 0.3],
	[26.0, "row", "diamond", 5, {"vy": 150.0}],
	[26.0, "one", "gunner", W * 0.5, {"ty": 260.0, "n": 5}],
	[29.0, "one", "gunner", 100.0, {"ty": 200.0}],
	[29.0, "one", "gunner", W - 100.0, {"ty": 200.0}],
	[29.0, "one", "gunner", W * 0.5, {"ty": 150.0}],
	[33.0, "stream", "diamond", "rand", 10, 0.22, {"vy": 260.0}],
	[36.0, "sweep", "dart", -1.0, 5, 0.25],
]

const STAGE_2 := [
	[1.0, "stream", "orb", "rand", 6, 0.4],
	[4.0, "row", "diamond", 7, {"vy": 190.0, "wob": 80.0}],
	[6.5, "one", "gunner", W * 0.3, {"ty": 200.0, "n": 5}],
	[6.5, "one", "gunner", W * 0.7, {"ty": 200.0, "n": 5}],
	[9.0, "sweep", "dart", -1.0, 5, 0.3],
	[9.0, "stream", "orb", W * 0.5, 4, 0.5],
	[12.0, "sweep", "dart", 1.0, 5, 0.3],
	[14.0, "one", "turret", W * 0.5, {"ty": 220.0, "stay": 8.0}],
	[17.0, "stream", "orb", "alt", 8, 0.35],
	[21.0, "vee", "diamond", W * 0.3, 5],
	[21.0, "vee", "diamond", W * 0.7, 5],
	[23.5, "one", "gunner", 90.0, {"ty": 170.0, "rate": 1.2}],
	[23.5, "one", "gunner", W - 90.0, {"ty": 170.0, "rate": 1.2}],
	[26.0, "sweep", "dart", -1.0, 4, 0.3],
	[26.0, "sweep", "dart", 1.0, 4, 0.3],
	[29.0, "stream", "orb", "rand", 12, 0.25],
	[33.0, "one", "turret", W * 0.3, {"ty": 200.0, "stay": 7.0}],
	[33.0, "one", "turret", W * 0.7, {"ty": 260.0, "stay": 7.0}],
	[38.0, "row", "diamond", 8, {"vy": 220.0}],
]

const STAGE_3 := [
	[1.0, "sweep", "dart", -1.0, 6, 0.25],
	[3.0, "sweep", "dart", 1.0, 6, 0.25],
	[5.5, "one", "turret", W * 0.5, {"ty": 200.0, "stay": 7.0}],
	[5.5, "stream", "diamond", 70.0, 6, 0.3, {"wob": 100.0}],
	[5.5, "stream", "diamond", W - 70.0, 6, 0.3, {"wob": 100.0}],
	[10.0, "one", "gunner", 80.0, {"ty": 160.0, "rate": 1.4}],
	[10.0, "one", "gunner", 207.0, {"ty": 230.0, "rate": 1.4}],
	[10.0, "one", "gunner", 333.0, {"ty": 160.0, "rate": 1.4}],
	[10.0, "one", "gunner", 460.0, {"ty": 230.0, "rate": 1.4}],
	[14.0, "stream", "orb", "rand", 10, 0.25],
	[17.0, "vee", "diamond", W * 0.5, 9, {"vy": 250.0}],
	[19.0, "sweep", "dart", -1.0, 5, 0.25, {"n": 7}],
	[19.0, "sweep", "dart", 1.0, 5, 0.25, {"n": 7}],
	[23.0, "one", "turret", 120.0, {"ty": 230.0, "stay": 7.0}],
	[23.0, "one", "turret", W - 120.0, {"ty": 230.0, "stay": 7.0}],
	[27.0, "row", "diamond", 8, {"vy": 200.0, "wob": 60.0}],
	[27.0, "stream", "orb", W * 0.5, 6, 0.3],
	[30.0, "one", "gunner", W * 0.5, {"ty": 200.0, "n": 7, "rate": 1.1}],
	[30.0, "sweep", "dart", -1.0, 4, 0.3],
	[33.0, "sweep", "dart", 1.0, 4, 0.3],
	[33.0, "stream", "orb", "rand", 8, 0.3],
	[37.0, "one", "turret", W * 0.5, {"ty": 260.0, "stay": 6.0}],
	[37.0, "row", "diamond", 6, {"vy": 180.0}],
]

const STAGE_4 := [
	[1.0, "row", "diamond", 8, {"vy": 210.0, "wob": 90.0}],
	[3.0, "one", "turret", W * 0.25, {"ty": 190.0, "stay": 6.0}],
	[3.0, "one", "turret", W * 0.75, {"ty": 190.0, "stay": 6.0}],
	[7.0, "sweep", "dart", -1.0, 6, 0.22, {"n": 7}],
	[7.0, "sweep", "dart", 1.0, 6, 0.22, {"n": 7}],
	[10.0, "stream", "orb", "rand", 14, 0.2],
	[13.0, "one", "gunner", 70.0, {"ty": 150.0, "rate": 1.3}],
	[13.0, "one", "gunner", 170.0, {"ty": 230.0, "rate": 1.3}],
	[13.0, "one", "gunner", 270.0, {"ty": 150.0, "rate": 1.3}],
	[13.0, "one", "gunner", 370.0, {"ty": 230.0, "rate": 1.3}],
	[13.0, "one", "gunner", 470.0, {"ty": 150.0, "rate": 1.3}],
	[18.0, "vee", "diamond", W * 0.3, 7, {"vy": 260.0}],
	[18.0, "vee", "diamond", W * 0.7, 7, {"vy": 260.0}],
	[21.0, "one", "turret", W * 0.5, {"ty": 240.0, "stay": 8.0}],
	[21.0, "sweep", "dart", -1.0, 4, 0.3],
	[21.0, "sweep", "dart", 1.0, 4, 0.3],
	[25.0, "stream", "orb", "alt", 12, 0.25],
	[28.0, "one", "gunner", 100.0, {"ty": 220.0, "n": 5}],
	[28.0, "one", "gunner", W - 100.0, {"ty": 220.0, "n": 5}],
	[28.0, "stream", "diamond", W * 0.5, 8, 0.25, {"wob": 160.0}],
	[32.0, "one", "turret", 120.0, {"ty": 210.0, "stay": 7.0}],
	[32.0, "one", "turret", W - 120.0, {"ty": 210.0, "stay": 7.0}],
	[32.0, "one", "turret", W * 0.5, {"ty": 300.0, "stay": 7.0}],
	[37.0, "sweep", "dart", -1.0, 6, 0.2],
	[37.0, "sweep", "dart", 1.0, 6, 0.2],
	[37.0, "row", "diamond", 8, {"vy": 240.0}],
]

const ALL := [
	{"name": "SETOR 01", "sub": "GRADE NEON", "color": Cfg.MAGENTA, "boss": "square", "events": STAGE_1},
	{"name": "SETOR 02", "sub": "DISTRITO ORBITAL", "color": Cfg.BLUE, "boss": "circle", "events": STAGE_2},
	{"name": "SETOR 03", "sub": "NÚCLEO DE DADOS", "color": Cfg.LIME, "boss": "pentagon", "events": STAGE_3},
	{"name": "SETOR 04", "sub": "COLMEIA", "color": Cfg.RED, "boss": "hexagon", "events": STAGE_4},
]
