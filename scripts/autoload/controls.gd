extends Node
## Entrada unificada (autoload "Controls"): teclado, controle e toque — com teclas personalizáveis.
## As ações são registradas por código; as escolhas do jogador ficam salvas em user://save.cfg.
##
## Celular: arrasto RELATIVO — o dedo pode ficar em qualquer lugar (não cobre a nave) e a nave se move
## o quanto o dedo se move. Tiro automático. Botões na tela: pausa, bomba e FOCO (segure).

const ACTIONS := ["up", "down", "left", "right", "focus", "bomb", "pause", "confirm", "mute"]
const ACTION_NAMES := {
	"up": "MOVER: CIMA", "down": "MOVER: BAIXO", "left": "MOVER: ESQUERDA", "right": "MOVER: DIREITA",
	"focus": "FOCO (LENTO)", "bomb": "BOMBA", "pause": "PAUSA", "confirm": "CONFIRMAR", "mute": "SOM",
}
const DEFAULT_KEYS := {
	"up": [KEY_UP, KEY_W], "down": [KEY_DOWN, KEY_S], "left": [KEY_LEFT, KEY_A], "right": [KEY_RIGHT, KEY_D],
	"focus": [KEY_SHIFT, KEY_C], "bomb": [KEY_X, KEY_K], "pause": [KEY_ESCAPE, KEY_P],
	"confirm": [KEY_ENTER, KEY_Z], "mute": [KEY_M, KEY_NONE],
}
const DEFAULT_PAD := {
	"up": JOY_BUTTON_DPAD_UP, "down": JOY_BUTTON_DPAD_DOWN, "left": JOY_BUTTON_DPAD_LEFT, "right": JOY_BUTTON_DPAD_RIGHT,
	"focus": JOY_BUTTON_RIGHT_SHOULDER, "bomb": JOY_BUTTON_B, "pause": JOY_BUTTON_START,
	"confirm": JOY_BUTTON_A, "mute": JOY_BUTTON_BACK,
}
const PAD_NAMES := {
	JOY_BUTTON_A: "A", JOY_BUTTON_B: "B", JOY_BUTTON_X: "X", JOY_BUTTON_Y: "Y",
	JOY_BUTTON_BACK: "SELECT", JOY_BUTTON_START: "START", JOY_BUTTON_GUIDE: "GUIA",
	JOY_BUTTON_LEFT_STICK: "L3", JOY_BUTTON_RIGHT_STICK: "R3",
	JOY_BUTTON_LEFT_SHOULDER: "LB", JOY_BUTTON_RIGHT_SHOULDER: "RB",
	JOY_BUTTON_DPAD_UP: "D-CIMA", JOY_BUTTON_DPAD_DOWN: "D-BAIXO",
	JOY_BUTTON_DPAD_LEFT: "D-ESQ", JOY_BUTTON_DPAD_RIGHT: "D-DIR",
}
const KEY_LABELS := {
	KEY_UP: "SETA CIMA", KEY_DOWN: "SETA BAIXO", KEY_LEFT: "SETA ESQ", KEY_RIGHT: "SETA DIR",
	KEY_ESCAPE: "ESC", KEY_ENTER: "ENTER", KEY_SPACE: "ESPAÇO", KEY_SHIFT: "SHIFT",
	KEY_CTRL: "CTRL", KEY_ALT: "ALT", KEY_TAB: "TAB", KEY_BACKSPACE: "APAGAR",
}

# configuração (salva)
var keys := {}               # ação -> [tecla1, tecla2] (physical keycode; KEY_NONE = vazio)
var pad := {}                # ação -> botão do controle (-1 = vazio)
var touch_sens := 1.25       # multiplicador do arrasto do dedo
var touch_left := false      # botões do lado esquerdo (canhotos)
var touch_focus_btn := true  # mostra o botão de FOCO no celular

# estado por quadro
var drag := Vector2.ZERO     # deslocamento acumulado do dedo neste quadro (coordenadas do jogo)
var taps: Array = []         # toques/cliques deste quadro (Vector2)
var is_touch := false
var buttons: Array = []      # botões ativos: [{"pos", "r", "action", "hold"?}]
var touch_focus := false     # botão de foco sendo segurado

# captura de tecla na tela de controles
var capturing := ""          # ação aguardando tecla ("" = nenhuma)
var capture_slot := 0        # 0/1 = teclas, 2 = controle
var capture_t := 0.0
var capture_cool := 0.0

var _virtual := {}
var _move_index := -1
var _focus_index := -1
var _last := Vector2.ZERO


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	is_touch = OS.has_feature("mobile") or OS.has_feature("web_android") or OS.has_feature("web_ios")
	reset_defaults(false)
	_load()
	apply()


func _process(delta: float) -> void:
	capture_cool = maxf(0.0, capture_cool - delta)
	if capturing != "":
		capture_t -= delta
		if capture_t <= 0.0:
			_end_capture(false)


# ------------------------------------------------------------------ configuração

func reset_defaults(save := true) -> void:
	keys = {}
	pad = {}
	for a in ACTIONS:
		keys[a] = (DEFAULT_KEYS[a] as Array).duplicate()
		pad[a] = DEFAULT_PAD[a]
	touch_sens = 1.25
	touch_left = false
	touch_focus_btn = true
	if save:
		apply()
		save_settings()


func apply() -> void:
	for a in ACTIONS:
		if InputMap.has_action(a):
			InputMap.action_erase_events(a)
		else:
			InputMap.add_action(a, 0.25)
		for k in keys[a]:
			if int(k) != KEY_NONE:
				var ev := InputEventKey.new()
				ev.physical_keycode = int(k)
				InputMap.action_add_event(a, ev)
		if int(pad[a]) >= 0:
			var jb := InputEventJoypadButton.new()
			jb.button_index = int(pad[a])
			InputMap.action_add_event(a, jb)
	# fixos: analógico para mover, gatilhos para foco, Enter do teclado numérico para confirmar
	_axis("left", JOY_AXIS_LEFT_X, -1.0)
	_axis("right", JOY_AXIS_LEFT_X, 1.0)
	_axis("up", JOY_AXIS_LEFT_Y, -1.0)
	_axis("down", JOY_AXIS_LEFT_Y, 1.0)
	_axis("focus", JOY_AXIS_TRIGGER_LEFT, 1.0)
	_axis("focus", JOY_AXIS_TRIGGER_RIGHT, 1.0)
	var kp := InputEventKey.new()
	kp.physical_keycode = KEY_KP_ENTER
	InputMap.action_add_event("confirm", kp)


func _axis(action: String, axis: int, value: float) -> void:
	var ev := InputEventJoypadMotion.new()
	ev.axis = axis
	ev.axis_value = value
	InputMap.action_add_event(action, ev)


func _load() -> void:
	var cf := ConfigFile.new()
	if cf.load(Cfg.SAVE_PATH) != OK:
		return
	var sk: Dictionary = cf.get_value("controls", "keys", {})
	var sp: Dictionary = cf.get_value("controls", "pad", {})
	for a in ACTIONS:
		if sk.has(a) and sk[a] is Array and sk[a].size() == 2:
			keys[a] = sk[a]
		if sp.has(a):
			pad[a] = int(sp[a])
	touch_sens = float(cf.get_value("controls", "touch_sens", touch_sens))
	touch_left = bool(cf.get_value("controls", "touch_left", touch_left))
	touch_focus_btn = bool(cf.get_value("controls", "touch_focus_btn", touch_focus_btn))


func save_settings() -> void:
	if not Profile.save_enabled:
		return
	var cf := ConfigFile.new()
	cf.load(Cfg.SAVE_PATH)
	cf.set_value("controls", "keys", keys)
	cf.set_value("controls", "pad", pad)
	cf.set_value("controls", "touch_sens", touch_sens)
	cf.set_value("controls", "touch_left", touch_left)
	cf.set_value("controls", "touch_focus_btn", touch_focus_btn)
	cf.save(Cfg.SAVE_PATH)


# ------------------------------------------------------------------ captura de tecla

## slot 0/1 = primeira/segunda tecla, 2 = botão do controle.
func start_capture(action: String, slot: int) -> void:
	capturing = action
	capture_slot = slot
	capture_t = 5.0


func _end_capture(changed: bool) -> void:
	capturing = ""
	capture_cool = 0.3
	if changed:
		apply()
		save_settings()


func _capture_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		get_viewport().set_input_as_handled()
		var k: int = event.physical_keycode
		if k == KEY_ESCAPE:
			_end_capture(false)
			return
		var clear := k == KEY_BACKSPACE or k == KEY_DELETE
		if capture_slot == 2:
			if clear:
				pad[capturing] = -1
				_end_capture(true)
			return
		if clear:
			k = KEY_NONE
		else:
			# a mesma tecla não pode estar em duas ações
			for a in ACTIONS:
				for s in 2:
					if int(keys[a][s]) == k:
						keys[a][s] = KEY_NONE
		keys[capturing][capture_slot] = k
		_end_capture(true)
	elif event is InputEventJoypadButton and event.pressed:
		get_viewport().set_input_as_handled()
		if capture_slot != 2:
			return
		var b: int = event.button_index
		for a in ACTIONS:
			if int(pad[a]) == b:
				pad[a] = -1
		pad[capturing] = b
		_end_capture(true)


func key_name(k: int) -> String:
	if k == KEY_NONE:
		return "---"
	if KEY_LABELS.has(k):
		return KEY_LABELS[k]
	return OS.get_keycode_string(k).to_upper()


func pad_name(b: int) -> String:
	if b < 0:
		return "---"
	return PAD_NAMES.get(b, "BOTÃO %d" % b)


func binding_text(action: String, slot: int) -> String:
	if slot == 2:
		return pad_name(int(pad[action]))
	return key_name(int(keys[action][slot]))


# ------------------------------------------------------------------ toque

## Botões da tela durante o jogo (o lado muda para canhotos).
func touch_layout() -> Array:
	var bx := 66.0 if touch_left else Cfg.W - 66.0
	var out := [
		{"pos": Vector2(Cfg.W / 2.0, 34.0), "r": 34.0, "action": "pause"},
		{"pos": Vector2(bx, Cfg.H - 86.0), "r": 54.0, "action": "bomb"},
	]
	if touch_focus_btn:
		out.append({"pos": Vector2(bx, Cfg.H - 206.0), "r": 46.0, "action": "focus", "hold": true})
	return out


func _input(event: InputEvent) -> void:
	if capturing != "":
		_capture_input(event)
		return
	if event is InputEventScreenTouch:
		is_touch = true
		var p: Vector2 = event.position
		if event.pressed:
			for b in buttons:
				if p.distance_to(b["pos"]) < b["r"]:
					if b.get("hold", false):
						_focus_index = event.index
						touch_focus = true
					else:
						_virtual[b["action"]] = true
					return
			taps.append(p)
			if _move_index == -1:
				_move_index = event.index
				_last = p
		else:
			if event.index == _move_index:
				_move_index = -1
			if event.index == _focus_index:
				_focus_index = -1
				touch_focus = false
	elif event is InputEventScreenDrag:
		if event.index == _move_index:
			var p: Vector2 = event.position
			drag += (p - _last) * touch_sens
			_last = p
	elif event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			taps.append(event.position)


# ------------------------------------------------------------------ leitura

## Apertou neste quadro? (teclado, controle ou botão da tela)
func pressed(action: String) -> bool:
	return Input.is_action_just_pressed(action) or _virtual.has(action)


func focus_held() -> bool:
	return Input.is_action_pressed("focus") or touch_focus


func move_vector() -> Vector2:
	return Input.get_vector("left", "right", "up", "down")


## Chamado pelo Main no fim de cada passo de física.
func end_frame() -> void:
	taps.clear()
	_virtual.clear()
	drag = Vector2.ZERO
	if buttons.is_empty():
		touch_focus = false
		_focus_index = -1
