class_name I18n
extends RefCounted
## Idiomas do jogo. O texto-base é o português: ele mesmo é a chave da tradução.
## Neon.text() traduz automaticamente todo texto desenhado; para textos com números use
## I18n.t("PONTOS  %d") % pontos (traduz o modelo antes de preencher).
## Para adicionar um idioma: crie outro dicionário igual ao EN e registre em setup().

const LANGS := ["pt", "en"]
const LANG_NAMES := {"pt": "PORTUGUÊS", "en": "ENGLISH"}

const EN := {
	# menus e telas
	"JOGAR": "PLAY", "OPÇÕES": "OPTIONS", "CONTROLES": "CONTROLS", "CONTINUAR": "CONTINUE",
	"ABANDONAR MISSÃO": "ABANDON MISSION", "HANGAR (LOJA)": "HANGAR (SHOP)", "MENU INICIAL": "MAIN MENU",
	"SEGUIR PARA %s": "CONTINUE TO %s", "PAUSA": "PAUSE", "ESC / START PARA VOLTAR": "ESC / START TO RESUME",
	"os créditos desta missão já estão salvos": "this mission's credits are already saved",
	"FIM DE JOGO": "GAME OVER", "VITÓRIA": "VICTORY", "O CAOS FOI CONTIDO": "CHAOS HAS BEEN CONTAINED",
	"MODO  %s": "MODE  %s", "PONTOS  %d": "SCORE  %d", "NOVO RECORDE!": "NEW HIGH SCORE!",
	"RECORDE  %d": "HIGH SCORE  %d", "SETOR ALCANÇADO  %d / %d": "SECTOR REACHED  %d / %d",
	"CRÉDITOS GANHOS  +%d": "CREDITS EARNED  +%d", "LIBERADO NA ABA ELITE: %s": "UNLOCKED IN THE ELITE TAB: %s",
	"LIBERADO: %s": "UNLOCKED: %s",
	# jogo
	"WARNING": "WARNING", "ANOMALIA DETECTADA": "ANOMALY DETECTED",
	"ALVO DE GRANDE PORTE DETECTADO": "LARGE TARGET DETECTED", "SETOR LIMPO": "SECTOR CLEAR",
	"+20000 PONTOS   +%d CRÉDITOS": "+20000 POINTS   +%d CREDITS",
	"+BOMBA": "+BOMB", "+VIDA": "+LIFE", "+VIDA (GRAZE)": "+LIFE (GRAZE)",
	"SEGUNDA CHANCE": "SECOND CHANCE", "o núcleo se reconstruiu": "the core rebuilt itself",
	"SETOR %02d": "SECTOR %02d", "BOMBA": "BOMB", "FOCO": "FOCUS",
	# setores
	"SETOR 01": "SECTOR 01", "SETOR 02": "SECTOR 02", "SETOR 03": "SECTOR 03", "SETOR 04": "SECTOR 04",
	"SETOR 05": "SECTOR 05", "SETOR 06": "SECTOR 06", "SETOR 07": "SECTOR 07", "SETOR 08": "SECTOR 08",
	"SETOR 09": "SECTOR 09", "SETOR 10": "SECTOR 10",
	"GRADE NEON": "NEON GRID", "DISTRITO ORBITAL": "ORBITAL DISTRICT", "SALA DE ESPELHOS": "HALL OF MIRRORS",
	"NÚCLEO DE DADOS": "DATA CORE", "COLMEIA": "THE HIVE", "CONSTELAÇÃO": "CONSTELLATION",
	"SINAPSE": "SYNAPSE", "BASTIÃO": "BASTION", "HIPERESPAÇO": "HYPERSPACE", "O VAZIO": "THE VOID",
	# chefes
	"QUADRADO // SQR-01": "SQUARE // SQR-01", "CÍRCULO // ORB-02": "CIRCLE // ORB-02",
	"TRIÂNGULO // RVL-03": "TRIANGLE // RVL-03", "PENTÁGONO // PNT-04": "PENTAGON // PNT-04",
	"HEXÁGONO // HEX-05": "HEXAGON // HEX-05", "ESTRELA // STR-06": "STAR // STR-06",
	"GÊMEOS // LSG-07": "TWINS // LSG-07", "OCTÓGONO // OCT-08": "OCTAGON // OCT-08",
	"TESSERATO // TSR-09": "TESSERACT // TSR-09", "CAOS // ???-10": "CHAOS // ???-10",
	# armas
	"LEQUE": "SPREAD", "ENXAME": "SWARM", "PRISMA": "PRISM", "PULSO": "PULSE",
	# tela inicial
	"ARRASTE EM QUALQUER LUGAR PARA MOVER": "DRAG ANYWHERE TO MOVE",
	"SEGURE FOCO: LENTO  •  B: BOMBA  •  TIRO AUTOMÁTICO": "HOLD FOCUS: SLOW  •  B: BOMB  •  AUTO-FIRE",
	"%s/%s: MOVER   %s: FOCO   %s: BOMBA": "%s/%s: MOVE   %s: FOCUS   %s: BOMB",
	"TIRO AUTOMÁTICO  •  TECLAS PERSONALIZÁVEIS EM CONTROLES": "AUTO-FIRE  •  REMAP KEYS IN CONTROLS",
	"RECORDE  %08d": "HIGH SCORE  %08d", "  •  NG+%d CONCLUÍDO": "  •  NG+%d CLEARED",
	"  •  JOGO ZERADO": "  •  GAME CLEARED", "CRÉDITOS  %d%s": "CREDITS  %d%s",
	# Hangar
	"NAVE": "SHIP", "ARMAS": "WEAPONS", "ARMA INICIAL": "STARTING WEAPON", "MODO": "MODE",
	"INICIAR MISSÃO": "START MISSION",
	"cima/baixo: escolher  •  esq/dir: abas  •  ENTER: comprar  •  ESC: voltar": "up/down: select  •  left/right: tabs  •  ENTER: buy  •  ESC: back",
	"toque no preço para comprar  •  arraste para rolar": "tap the price to buy  •  drag to scroll",
	"liberado só depois de zerar o jogo": "unlocked after you beat the game",
	"vida x%.2f  •  tiros +%d%%  •  créditos x%.2f": "health x%.2f  •  fire rate +%d%%  •  credits x%.2f",
	"ZERAR": "BEAT", "MÁX": "MAX", "Para liberar: ": "To unlock: ", "ZERE O JOGO": "BEAT THE GAME",
	"ZERE O NG+%d": "BEAT NG+%d", "COMPRADO: %s NV %d": "BOUGHT: %s LV %d", "NÍVEL MÁXIMO": "MAX LEVEL",
	"BLOQUEADO: %s": "LOCKED: %s", "CRÉDITOS INSUFICIENTES": "NOT ENOUGH CREDITS",
	# upgrades
	"CORAÇÕES": "HEARTS", "+1 coração máximo e no início": "+1 max heart (and at start)",
	"ESCUDO": "SHIELD", "Absorve 1 acerto por setor (por nível)": "Absorbs 1 hit per sector (per level)",
	"BOMBAS": "BOMBS", "+1 bomba no início e em cada setor": "+1 bomb at start and each sector",
	"RECUPERAÇÃO": "RECOVERY", "+0,4 s invulnerável após dano": "+0.4 s invulnerable after a hit",
	"ÍMÃ": "MAGNET", "Puxa itens de mais longe": "Pulls items from farther away",
	"PODER INICIAL": "STARTING POWER", "Começa com mais poder de tiro": "Start with more firepower",
	"DANO": "DAMAGE", "+12% de dano em todos os tiros": "+12% damage on all shots",
	"CADÊNCIA": "FIRE RATE", "+8% de velocidade de disparo": "+8% firing speed",
	"1 drone · 2 drones · drones fortes": "1 drone · 2 drones · stronger drones",
	"ARMA: LASER": "WEAPON: LASER", "Liberar para começar com o Laser": "Unlock to start with the Laser",
	"ARMA: ENXAME": "WEAPON: SWARM", "Liberar para começar com o Enxame": "Unlock to start with the Swarm",
	"ARMA: PRISMA": "WEAPON: PRISM", "Tiros que se dividem em 3": "Shots that split into 3",
	"COLETOR": "COLLECTOR", "+50% de créditos em toda partida": "+50% credits every run",
	"ARMA: PULSO": "WEAPON: PULSE", "Ondas largas que atravessam tudo": "Wide waves that pierce everything",
	"1x por partida, volta com 2 corações": "Once per run, revive with 2 hearts",
	"ESCUDO VIVO": "LIVING SHIELD", "Recupera 1 escudo a cada 25 s": "Restores 1 shield every 25 s",
	"BOMBA NOVA": "NOVA BOMB", "Bombas com 3x dano e mais longas": "Bombs deal 3x damage and last longer",
	"TERCEIRO DRONE": "THIRD DRONE", "Um drone extra atrás da nave": "An extra drone behind the ship",
	"GRAZE VAMPÍRICO": "VAMPIRIC GRAZE", "120 raspões = +1 coração": "120 grazes = +1 heart",
	"NÚCLEO ESTÁVEL": "STABLE CORE", "Não perde poder ao levar dano": "Don't lose power when hit",
	"SOBRECARGA": "OVERDRIVE", "+30% de dano em tudo": "+30% damage on everything",
	"ARMA: VERTEX": "WEAPON: VERTEX", "Leque + laser + enxame juntos": "Spread + laser + swarm at once",
	# controles
	"TECLADO E CONTROLE": "KEYBOARD & GAMEPAD", "TECLA 1": "KEY 1", "TECLA 2": "KEY 2", "CONTROLE": "GAMEPAD",
	"TOQUE (CELULAR)": "TOUCH (MOBILE)", "APERTE...": "PRESS...", "SENSIBILIDADE DO ARRASTO": "DRAG SENSITIVITY",
	"LADO DOS BOTÕES": "BUTTON SIDE", "ESQUERDO": "LEFT", "DIREITO": "RIGHT",
	"BOTÃO DE FOCO NA TELA": "ON-SCREEN FOCUS BUTTON", "LIGADO": "ON", "DESLIGADO": "OFF",
	"RESTAURAR PADRÃO": "RESTORE DEFAULTS", "VOLTAR": "BACK", "NO CELULAR": "ON MOBILE",
	"arraste o dedo em qualquer lugar: move a nave (o dedo não cobre a nave)": "drag anywhere to move the ship (your finger never covers it)",
	"segure FOCO: nave lenta + hitbox visível   •   B: bomba   •   II: pausa": "hold FOCUS: slow ship + visible hitbox   •   B: bomb   •   II: pause",
	"o tiro é sempre automático": "firing is always automatic",
	"ENTER: trocar tecla  •  ESC: cancelar  •  APAGAR: limpar": "ENTER: change key  •  ESC: cancel  •  BACKSPACE: clear",
	"aperte a nova tecla/botão para %s  (ESC cancela, APAGAR limpa)": "press the new key/button for %s  (ESC cancels, BACKSPACE clears)",
	"MOVER: CIMA": "MOVE: UP", "MOVER: BAIXO": "MOVE: DOWN", "MOVER: ESQUERDA": "MOVE: LEFT",
	"MOVER: DIREITA": "MOVE: RIGHT", "FOCO (LENTO)": "FOCUS (SLOW)", "CONFIRMAR": "CONFIRM", "SOM": "SOUND",
	"SETA CIMA": "UP", "SETA BAIXO": "DOWN", "SETA ESQ": "LEFT", "SETA DIR": "RIGHT", "ESPAÇO": "SPACE",
	"APAGAR": "BACKSPACE", "GUIA": "GUIDE", "D-CIMA": "D-UP", "D-BAIXO": "D-DOWN", "D-ESQ": "D-LEFT",
	"D-DIR": "D-RIGHT", "BOTÃO %d": "BUTTON %d",
	# opções
	"IDIOMA": "LANGUAGE", "MÚSICA": "MUSIC", "EFEITOS SONOROS": "SOUND EFFECTS", "TREMOR DE TELA": "SCREEN SHAKE",
	"FLASHES DE TELA": "SCREEN FLASHES", "REDUZIDO": "REDUCED", "TELA CHEIA": "FULLSCREEN",
	"ÁUDIO": "AUDIO", "GERAL": "GENERAL", "CONFORTO VISUAL": "VISUAL COMFORT",
	"esq/dir: ajustar  •  ESC: voltar": "left/right: adjust  •  ESC: back",
	"toque à esquerda/direita do valor para ajustar": "tap left/right of a value to adjust",
	"DICAS DO TUTORIAL": "TUTORIAL TIPS",
	# dicas do tutorial
	"MOVIMENTO": "MOVEMENT", "CHEFE": "BOSS",
	"%s %s %s %s movem a nave  •  o tiro é automático": "%s %s %s %s move the ship  •  firing is automatic",
	"segure %s: nave lenta + ponto de acerto visível": "hold %s: slow ship + visible hit point",
	"aperte %s para limpar a tela de balas": "press %s to clear the screen of bullets",
	"arraste em qualquer lugar  •  o tiro é automático": "drag anywhere  •  firing is automatic",
	"segure FOCO: nave lenta + ponto de acerto visível": "hold FOCUS: slow ship + visible hit point",
	"toque em B para limpar a tela de balas": "tap B to clear the screen of bullets",
	"raspar nas balas sem encostar dá pontos": "grazing bullets without touching them gives points",
	"pegue para aumentar o poder de tiro": "grab it to boost your firepower",
	"troca de arma enquanto cai: pegue na cor que quiser": "it cycles weapons as it falls: grab the color you want",
	"a barra no topo mostra as fases; cada fase muda o ataque": "the top bar shows its phases; each phase changes the attack",
	"créditos nunca se perdem: compre melhorias e tente de novo": "credits are never lost: buy upgrades and try again",
}

static var _registered := false


## Registra as traduções (uma vez) e ativa o idioma pedido ("pt" ou "en").
static func setup(lang: String) -> void:
	if not _registered:
		var tr_en := Translation.new()
		tr_en.locale = "en"
		for k in EN:
			tr_en.add_message(k, EN[k])
		TranslationServer.add_translation(tr_en)
		_registered = true
	TranslationServer.set_locale(lang if LANGS.has(lang) else "en")


## Traduz um texto (use para modelos com %d / %s antes de preencher).
static func t(s: String) -> String:
	return TranslationServer.translate(s)


## Idioma inicial: português se o sistema estiver em português, senão inglês.
static func default_lang() -> String:
	return "pt" if OS.get_locale_language() == "pt" else "en"
