class_name Cfg
extends RefCounted
## Constantes globais do jogo: tamanho da tela, paleta neon e números do jogador.
## Mexa aqui para balancear o jogo (velocidade, vidas, cadência de tiro...).

const W := 540.0
const H := 960.0

# Paleta. Regra de legibilidade: CIANO = jogador. Cores quentes/roxas = inimigos.
const BG := Color(0.02, 0.004, 0.051)
const CYAN := Color(0.0, 0.94, 1.0)
const MAGENTA := Color(1.0, 0.169, 0.839)
const PINK := Color(1.0, 0.231, 0.553)
const YELLOW := Color(1.0, 0.902, 0.0)
const ORANGE := Color(1.0, 0.541, 0.0)
const RED := Color(1.0, 0.165, 0.239)
const LIME := Color(0.224, 1.0, 0.078)
const PURPLE := Color(0.753, 0.302, 1.0)
const VIOLET := Color(0.482, 0.361, 1.0)
const BLUE := Color(0.176, 0.482, 1.0)
const WHITE := Color(1.0, 1.0, 1.0)

# Jogador
const PLAYER_SPEED := 340.0        # px/s
const PLAYER_FOCUS_SPEED := 150.0  # px/s segurando o foco
const HIT_RADIUS := 3.5            # hitbox real (bem menor que o desenho)
const GRAZE_RADIUS := 20.0         # raio para "raspar" projéteis e ganhar pontos
const INVULN_TIME := 2.2           # invulnerabilidade após dano (s)
const FIRE_RATE := 0.08            # intervalo entre disparos (s)
const SHOT_SPEED := 1150.0
const START_LIVES := 3
const MAX_LIVES := 5
const START_BOMBS := 3
const MAX_BOMBS := 5
const MAX_POWER := 4
const TOUCH_SENS := 1.25           # multiplicador do arrasto do dedo

# Dificuldade geral (botões rápidos de balanceamento)
const BOSS_HP_SCALE := 0.75        # vida dos chefes (1.0 = original)
const BOSS_RATE_SCALE := 0.8       # cadência de tiro dos chefes (menor = atira menos)
const BULLET_HITBOX := 0.7         # fração do raio da bala que acerta (o núcleo branco é desenhado desse tamanho)
const BOMBS_PER_STAGE := 2         # todo setor começa com pelo menos essa quantidade de bombas

# Armas do jogador (trocadas pelo item W, que alterna de cor enquanto cai)
const WEAPONS := ["spread", "laser", "homing"]
const WEAPON_NAMES := {"spread": "LEQUE", "laser": "LASER", "homing": "ENXAME"}
const WEAPON_LETTER := {"spread": "S", "laser": "L", "homing": "H"}
const WEAPON_COLORS := {
	"spread": Color(0.0, 0.94, 1.0),
	"laser": Color(0.49, 0.78, 1.0),
	"homing": Color(0.36, 1.0, 0.69),
}

# Créditos (moeda da loja). Ficam salvos entre partidas.
const CREDITS := {"diamond": 1, "gunner": 3, "dart": 2, "orb": 1, "turret": 8}
const BOSS_CREDITS := 40           # + 20 por setor
const CLEAR_BONUS := 1000          # zerar os 10 setores

# Loja (Hangar). `costs` = preço de cada nível; o número de preços é o nível máximo.
const UPGRADES := [
	{"id": "hearts", "name": "CORAÇÕES", "desc": "+1 coração máximo (e no início da partida)", "costs": [150, 400]},
	{"id": "bombs", "name": "BOMBAS", "desc": "+1 bomba no início e em cada setor", "costs": [80, 180, 350]},
	{"id": "power", "name": "PODER INICIAL", "desc": "Começa a partida com mais poder de tiro", "costs": [120, 300, 600]},
	{"id": "damage", "name": "DANO", "desc": "+12% de dano em todos os tiros", "costs": [100, 200, 350, 550, 800]},
	{"id": "rate", "name": "CADÊNCIA", "desc": "+8% de velocidade de disparo", "costs": [100, 220, 400, 650]},
	{"id": "magnet", "name": "ÍMÃ", "desc": "Puxa itens de mais longe", "costs": [60, 140, 260]},
	{"id": "invuln", "name": "RECUPERAÇÃO", "desc": "+0,4 s de invulnerabilidade após levar dano", "costs": [80, 180, 320]},
	{"id": "shield", "name": "ESCUDO", "desc": "Absorve 1 acerto por setor (por nível), sem perder coração", "costs": [250, 550, 1000]},
	{"id": "drones", "name": "DRONES", "desc": "Nv1: 1 drone · Nv2: 2 drones · Nv3: drones mais fortes", "costs": [300, 700, 1200]},
	{"id": "laser", "name": "ARMA: LASER", "desc": "Libera começar a partida com o Laser", "costs": [400]},
	{"id": "homing", "name": "ARMA: ENXAME", "desc": "Libera começar a partida com o Enxame", "costs": [400]},
]

# Layout da loja (usado pelo main.gd e pelo hud.gd)
const SHOP_Y0 := 176.0
const SHOP_ROW_H := 50.0

const SAVE_PATH := "user://save.cfg"
