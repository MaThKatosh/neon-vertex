extends Node
## Perfil salvo do jogador (autoload "Profile"): créditos, upgrades comprados e recordes.
## É a parte "roguelite": cada partida começa do setor 1, mas o que você compra fica para sempre.

var credits := 0
var hi := 0
var best_stage := 0
var runs := 0
var levels := {}             # id do upgrade -> nível comprado
var start_weapon := "spread"
var save_enabled := true     # os testes automáticos desligam


func _ready() -> void:
	load_profile()


func load_profile() -> void:
	var cf := ConfigFile.new()
	if cf.load(Cfg.SAVE_PATH) != OK:
		return
	credits = int(cf.get_value("profile", "credits", 0))
	hi = int(cf.get_value("score", "hi", 0))
	best_stage = int(cf.get_value("profile", "best_stage", 0))
	runs = int(cf.get_value("profile", "runs", 0))
	levels = cf.get_value("profile", "levels", {})
	start_weapon = str(cf.get_value("profile", "start_weapon", "spread"))
	if not weapon_unlocked(start_weapon):
		start_weapon = "spread"


func save_profile() -> void:
	if not save_enabled:
		return
	var cf := ConfigFile.new()
	cf.load(Cfg.SAVE_PATH)   # preserva outras seções (ex.: áudio)
	cf.set_value("profile", "credits", credits)
	cf.set_value("score", "hi", hi)
	cf.set_value("profile", "best_stage", best_stage)
	cf.set_value("profile", "runs", runs)
	cf.set_value("profile", "levels", levels)
	cf.set_value("profile", "start_weapon", start_weapon)
	cf.save(Cfg.SAVE_PATH)


# ------------------------------------------------------------------ loja

func upgrade_def(id: String) -> Dictionary:
	for u in Cfg.UPGRADES:
		if u["id"] == id:
			return u
	return {}


func level(id: String) -> int:
	return int(levels.get(id, 0))


func max_level(id: String) -> int:
	return upgrade_def(id)["costs"].size()


## Custo do próximo nível, ou -1 se já está no máximo.
func next_cost(id: String) -> int:
	var lv := level(id)
	var costs: Array = upgrade_def(id)["costs"]
	return int(costs[lv]) if lv < costs.size() else -1


## "ok", "max" ou "poor"
func buy(id: String) -> String:
	var cost := next_cost(id)
	if cost < 0:
		return "max"
	if credits < cost:
		return "poor"
	credits -= cost
	levels[id] = level(id) + 1
	save_profile()
	return "ok"


func weapon_unlocked(w: String) -> bool:
	return w == "spread" or level(w) > 0


func cycle_start_weapon() -> void:
	var i := Cfg.WEAPONS.find(start_weapon)
	for k in Cfg.WEAPONS.size():
		i = (i + 1) % Cfg.WEAPONS.size()
		if weapon_unlocked(Cfg.WEAPONS[i]):
			start_weapon = Cfg.WEAPONS[i]
			break
	save_profile()


# ------------------------------------------------------------------ efeitos (lidos pelo jogo)

func damage_mult() -> float:
	return 1.0 + 0.12 * level("damage")


func rate_mult() -> float:
	return 1.0 + 0.08 * level("rate")


func max_lives() -> int:
	return Cfg.START_LIVES + level("hearts")


func lives_cap() -> int:
	return Cfg.MAX_LIVES + level("hearts")


func start_bombs() -> int:
	return Cfg.START_BOMBS + level("bombs")


func stage_bombs() -> int:
	return Cfg.BOMBS_PER_STAGE + level("bombs")


func start_power() -> int:
	return mini(Cfg.MAX_POWER, 1 + level("power"))


func magnet_radius() -> float:
	return 120.0 + 60.0 * level("magnet")


func invuln_time() -> float:
	return Cfg.INVULN_TIME + 0.4 * level("invuln")


func shield_charges() -> int:
	return level("shield")


func drones() -> int:
	return level("drones")
