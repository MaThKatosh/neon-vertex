extends Node
## Entrada unificada (autoload "Controls"): teclado, controle e toque.
## As ações são registradas por código, então não é preciso configurar o Input Map no editor.
##
## Celular: arrasto RELATIVO — o dedo pode ficar em qualquer lugar da tela (não cobre a nave)
## e a nave se move o quanto o dedo se move. Tiro é automático. Botões na tela: pausa e bomba.

var drag := Vector2.ZERO   # deslocamento acumulado do dedo neste quadro (coordenadas do jogo)
var taps: Array = []       # toques/cliques deste quadro (Vector2)
var is_touch := false
var buttons: Array = []    # botões ativos: [{"pos": Vector2, "r": float, "action": String}]

var _virtual := {}
var _move_index := -1
var _last := Vector2.ZERO


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	is_touch = OS.has_feature("mobile") or OS.has_feature("web_android") or OS.has_feature("web_ios")
	_add("left", [KEY_LEFT, KEY_A], [JOY_BUTTON_DPAD_LEFT], [[JOY_AXIS_LEFT_X, -1.0]])
	_add("right", [KEY_RIGHT, KEY_D], [JOY_BUTTON_DPAD_RIGHT], [[JOY_AXIS_LEFT_X, 1.0]])
	_add("up", [KEY_UP, KEY_W], [JOY_BUTTON_DPAD_UP], [[JOY_AXIS_LEFT_Y, -1.0]])
	_add("down", [KEY_DOWN, KEY_S], [JOY_BUTTON_DPAD_DOWN], [[JOY_AXIS_LEFT_Y, 1.0]])
	_add("focus", [KEY_SHIFT], [JOY_BUTTON_LEFT_SHOULDER, JOY_BUTTON_RIGHT_SHOULDER],
		[[JOY_AXIS_TRIGGER_LEFT, 1.0], [JOY_AXIS_TRIGGER_RIGHT, 1.0]])
	_add("bomb", [KEY_X, KEY_K], [JOY_BUTTON_B, JOY_BUTTON_X], [])
	_add("pause", [KEY_ESCAPE, KEY_P], [JOY_BUTTON_START], [])
	_add("confirm", [KEY_ENTER, KEY_KP_ENTER, KEY_SPACE, KEY_Z, KEY_J], [JOY_BUTTON_A], [])
	_add("mute", [KEY_M], [JOY_BUTTON_BACK], [])


func _add(action: String, keys: Array, joy_buttons: Array, joy_axes: Array) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action, 0.25)
	for k in keys:
		var ev := InputEventKey.new()
		ev.physical_keycode = k
		InputMap.action_add_event(action, ev)
	for b in joy_buttons:
		var ev := InputEventJoypadButton.new()
		ev.button_index = b
		InputMap.action_add_event(action, ev)
	for a in joy_axes:
		var ev := InputEventJoypadMotion.new()
		ev.axis = a[0]
		ev.axis_value = a[1]
		InputMap.action_add_event(action, ev)


func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		is_touch = true
		var p: Vector2 = event.position
		if event.pressed:
			for b in buttons:
				if p.distance_to(b["pos"]) < b["r"]:
					_virtual[b["action"]] = true
					return
			taps.append(p)
			if _move_index == -1:
				_move_index = event.index
				_last = p
		elif event.index == _move_index:
			_move_index = -1
	elif event is InputEventScreenDrag:
		if event.index == _move_index:
			var p: Vector2 = event.position
			drag += (p - _last) * Cfg.TOUCH_SENS
			_last = p
	elif event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			taps.append(event.position)


## Apertou neste quadro? (teclado, controle ou botão da tela)
func pressed(action: String) -> bool:
	return Input.is_action_just_pressed(action) or _virtual.has(action)


func move_vector() -> Vector2:
	return Input.get_vector("left", "right", "up", "down")


## Chamado pelo Main no fim de cada passo de física.
func end_frame() -> void:
	taps.clear()
	_virtual.clear()
	drag = Vector2.ZERO
