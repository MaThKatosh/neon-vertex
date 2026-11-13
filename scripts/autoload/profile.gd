extends Node
## Perfil salvo do jogador (autoload "Profile"): créditos, upgrades, NEW GAME + e recordes.
## É a parte "roguelite": cada partida começa do setor 1, mas o que você compra fica para sempre.

var credits := 0
var hi := 0
var best_stage := 0
var runs := 0
var levels := {}             # id do upgrade -> nível comprado
var start_weapon := "spread"
var ng_cleared := -1         # maior NG concluído (-1 = nunca zerou; 0 = zerou o normal)
var ng_selected := 0         # modo escolhido no Hangar
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
	ng_cleared = int(cf.get_value("profile", "ng_cleared", -1))
	ng_selected = clampi(int(cf.get_value("profile", "ng_selected", 0)), 0, ng_available())
	if not weapon_owned(start_weapon):
		start_weapon = "spread"


func save_profile() -> void:
	if not save_enabled:
		return
	var cf := ConfigFile.new()
	cf.load(Cfg.SAVE_PATH)   # preserva outras seções (áudio, controles)
	cf.set_value("profile", "credits", credits)
	cf.set_value("score", "hi", hi)
	cf.set_value("profile", "best_stage", best_stage)
	cf.set_value("profile", "runs", runs)
	cf.set_value("profile", "levels", levels)
	cf.set_value("profile", "start_weapon", start_weapon)
	cf.set_value("profile", "ng_cleared", ng_cleared)
	cf.set_value("profile", "ng_selected", ng_selected)
	cf.save(Cfg.SAVE_PATH)


# ------------------------------------------------------------------ loja

func upgrade_def(id: String) -> Dictionary:
	for u in Cfg.UPGRADES:
		if u["id"] == id:
			return u
	return {}


func level(id: String) -> int:
	return int(levels.get(id, 0))


func has(id: String) -> bool:
	return level(id) > 0


func max_level(id: String) -> int:
	return upgrade_def(id)["costs"].size()


## Upgrades de elite só aparecem para compra depois de concluir o NG exigido.
func is_available(id: String) -> bool:
	var u := upgrade_def(id)
	return not u.has("req") or ng_cleared >= int(u["req"])


## Texto do requisito de um item bloqueado.
func req_text(id: String) -> String:
	var r := int(upgrade_def(id).get("req", -1))
	return "ZERE O JOGO" if r == 0 else "ZERE O NG+%d" % r


## Custo do próximo nível, ou -1 se já está no máximo.
func next_cost(id: String) -> int:
	var lv := level(id)
	var costs: Array = upgrade_def(id)["costs"]
	return int(costs[lv]) if lv < costs.size() else -1


## "ok", "max", "poor" ou "locked"
func buy(id: String) -> String:
	if not is_available(id):
		return "locked"
	var cost := next_cost(id)
	if cost < 0:
		return "max"
	if credits < cost:
		return "poor"
	credits -= cost
	levels[id] = level(id) + 1
	save_profile()
	return "ok"


func weapon_owned(w: String) -> bool:
	return w == "spread" or level(w) > 0


func owned_weapons() -> Array:
	var out := []
	for w in Cfg.WEAPONS:
		if weapon_owned(w):
			out.append(w)
	return out


func cycle_start_weapon(dir := 1) -> void:
	var own := owned_weapons()
	var i := own.find(start_weapon)
	start_weapon = own[(i + dir + own.size()) % own.size()]
	save_profile()


# ------------------------------------------------------------------ NEW GAME +

func ng_available() -> int:
	return mini(Cfg.NG_MAX, ng_cleared + 1)


func cycle_ng(dir := 1) -> void:
	var n := ng_available() + 1
	ng_selected = (ng_selected + dir + n) % n
	save_profile()


static func ng_label(ng: int) -> String:
	return "NORMAL" if ng <= 0 else "NEW GAME +%d" % ng


## Registra a vitória num NG. Retorna os ids de upgrades liberados agora (primeira vez).
func clear_ng(ng: int) -> Array:
	var unlocked := []
	if ng > ng_cleared:
		for u in Cfg.UPGRADES:
			var r := int(u.get("req", -1))
			if r > ng_cleared and r <= ng:
				unlocked.append(u["id"])
		ng_cleared = ng
		ng_selected = ng_available()
	save_profile()
	return unlocked


# ------------------------------------------------------------------ efeitos (lidos pelo jogo)

func damage_mult() -> float:
	return 1.0 + 0.12 * level("damage") + (0.3 if has("overdrive") else 0.0)


func rate_mult() -> float:
	return 1.0 + 0.08 * level("rate")


func credit_mult() -> float:
	return 1.5 if has("collector") else 1.0


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


## Quantidade de drones (até 2 pelo upgrade comum + 1 do Terceiro Drone).
func drone_count() -> int:
	return mini(level("drones"), 2) + (1 if has("drone3") else 0)
