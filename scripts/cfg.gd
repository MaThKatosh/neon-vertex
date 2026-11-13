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

# Armas do jogador. As 3 primeiras são básicas; Prisma, Pulso e Vertex são exclusivas do NEW GAME +.
# O item W alterna entre as armas que você possui enquanto cai.
const WEAPONS := ["spread", "laser", "homing", "prism", "pulse", "vertex"]
const WEAPON_NAMES := {"spread": "LEQUE", "laser": "LASER", "homing": "ENXAME", "prism": "PRISMA", "pulse": "PULSO", "vertex": "VERTEX"}
const WEAPON_LETTER := {"spread": "S", "laser": "L", "homing": "H", "prism": "R", "pulse": "O", "vertex": "X"}
const WEAPON_COLORS := {
	"spread": Color(0.0, 0.94, 1.0),
	"laser": Color(0.49, 0.78, 1.0),
	"homing": Color(0.36, 1.0, 0.69),
	"prism": Color(0.85, 0.65, 1.0),
	"pulse": Color(0.55, 1.0, 0.95),
	"vertex": Color(1.0, 1.0, 1.0),
}

# Créditos (moeda da loja). Ficam salvos entre partidas.
const CREDITS := {"diamond": 1, "gunner": 3, "dart": 2, "orb": 1, "turret": 8}
const BOSS_CREDITS := 40           # + 20 por setor
const CLEAR_BONUS := 1000          # zerar os 10 setores

# NEW GAME +: zerar o jogo libera o NG+1, zerar o NG+1 libera o NG+2... até o NG+10.
const NG_MAX := 10

# Loja (Hangar). `costs` = preço de cada nível (o número de preços é o nível máximo).
# `tab` = aba da loja. `req` = nível de NG que precisa ser concluído para liberar (0 = zerar o modo normal).
const SHOP_TABS := [["nave", "NAVE"], ["armas", "ARMAS"], ["elite", "ELITE"]]
const UPGRADES := [
	{"id": "hearts", "tab": "nave", "icon": "heart", "name": "CORAÇÕES", "desc": "+1 coração máximo e no início", "costs": [150, 400]},
	{"id": "shield", "tab": "nave", "icon": "shield", "name": "ESCUDO", "desc": "Absorve 1 acerto por setor (por nível)", "costs": [250, 550, 1000]},
	{"id": "bombs", "tab": "nave", "icon": "bomb", "name": "BOMBAS", "desc": "+1 bomba no início e em cada setor", "costs": [80, 180, 350]},
	{"id": "invuln", "tab": "nave", "icon": "clock", "name": "RECUPERAÇÃO", "desc": "+0,4 s invulnerável após dano", "costs": [80, 180, 320]},
	{"id": "magnet", "tab": "nave", "icon": "magnet", "name": "ÍMÃ", "desc": "Puxa itens de mais longe", "costs": [60, 140, 260]},
	{"id": "power", "tab": "armas", "icon": "power", "name": "PODER INICIAL", "desc": "Começa com mais poder de tiro", "costs": [120, 300, 600]},
	{"id": "damage", "tab": "armas", "icon": "damage", "name": "DANO", "desc": "+12% de dano em todos os tiros", "costs": [100, 200, 350, 550, 800]},
	{"id": "rate", "tab": "armas", "icon": "rate", "name": "CADÊNCIA", "desc": "+8% de velocidade de disparo", "costs": [100, 220, 400, 650]},
	{"id": "drones", "tab": "armas", "icon": "drones", "name": "DRONES", "desc": "1 drone · 2 drones · drones fortes", "costs": [300, 700, 1200]},
	{"id": "laser", "tab": "armas", "icon": "w:laser", "name": "ARMA: LASER", "desc": "Liberar para começar com o Laser", "costs": [400]},
	{"id": "homing", "tab": "armas", "icon": "w:homing", "name": "ARMA: ENXAME", "desc": "Liberar para começar com o Enxame", "costs": [400]},
	{"id": "prism", "tab": "elite", "req": 0, "icon": "w:prism", "name": "ARMA: PRISMA", "desc": "Tiros que se dividem em 3", "costs": [800]},
	{"id": "collector", "tab": "elite", "req": 1, "icon": "coin", "name": "COLETOR", "desc": "+50% de créditos em toda partida", "costs": [1000]},
	{"id": "pulse", "tab": "elite", "req": 2, "icon": "w:pulse", "name": "ARMA: PULSO", "desc": "Ondas largas que atravessam tudo", "costs": [1200]},
	{"id": "revive", "tab": "elite", "req": 3, "icon": "revive", "name": "SEGUNDA CHANCE", "desc": "1x por partida, volta com 2 corações", "costs": [1500]},
	{"id": "regen", "tab": "elite", "req": 4, "icon": "shield", "name": "ESCUDO VIVO", "desc": "Recupera 1 escudo a cada 25 s", "costs": [1500]},
	{"id": "nova", "tab": "elite", "req": 5, "icon": "bomb", "name": "BOMBA NOVA", "desc": "Bombas com 3x dano e mais longas", "costs": [1800]},
	{"id": "drone3", "tab": "elite", "req": 6, "icon": "drones", "name": "TERCEIRO DRONE", "desc": "Um drone extra atrás da nave", "costs": [2000]},
	{"id": "vampire", "tab": "elite", "req": 7, "icon": "heart", "name": "GRAZE VAMPÍRICO", "desc": "120 raspões = +1 coração", "costs": [2200]},
	{"id": "stable", "tab": "elite", "req": 8, "icon": "power", "name": "NÚCLEO ESTÁVEL", "desc": "Não perde poder ao levar dano", "costs": [2500]},
	{"id": "overdrive", "tab": "elite", "req": 9, "icon": "damage", "name": "SOBRECARGA", "desc": "+30% de dano em tudo", "costs": [3000]},
	{"id": "vertex", "tab": "elite", "req": 10, "icon": "w:vertex", "name": "ARMA: VERTEX", "desc": "Leque + laser + enxame juntos", "costs": [5000]},
]

# Layout do Hangar (usado pelo main.gd e pelo hud.gd)
const SHOP_TAB_Y := 166.0
const SHOP_LIST_Y0 := 240.0        # centro do primeiro cartão
const SHOP_CARD_H := 80.0
const SHOP_VISIBLE := 6
const SHOP_WEAPON_Y := 744.0
const SHOP_NG_Y := 796.0
const SHOP_START_Y := 868.0

const SAVE_PATH := "user://save.cfg"