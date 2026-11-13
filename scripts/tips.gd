class_name Tips
extends RefCounted
## Dicas do tutorial: aparecem uma única vez, no momento em que a coisa acontece pela primeira vez.
## Cada dica tem título e texto; "%s" é trocado pela tecla configurada (teclado) ou pelo gesto (celular).

const PC := {
	"move": ["MOVIMENTO", "%s %s %s %s movem a nave  •  o tiro é automático"],
	"focus": ["FOCO", "segure %s: nave lenta + ponto de acerto visível"],
	"bomb": ["BOMBA", "aperte %s para limpar a tela de balas"],
}
const TOUCH := {
	"move": ["MOVIMENTO", "arraste em qualquer lugar  •  o tiro é automático"],
	"focus": ["FOCO", "segure FOCO: nave lenta + ponto de acerto visível"],
	"bomb": ["BOMBA", "toque em B para limpar a tela de balas"],
}
const COMMON := {
	"graze": ["GRAZE", "raspar nas balas sem encostar dá pontos"],
	"item_p": ["ITEM P", "pegue para aumentar o poder de tiro"],
	"item_w": ["ITEM W", "troca de arma enquanto cai: pegue na cor que quiser"],
	"boss": ["CHEFE", "a barra no topo mostra as fases; cada fase muda o ataque"],
	"hangar": ["HANGAR", "créditos nunca se perdem: compre melhorias e tente de novo"],
}


## [título, texto] já traduzidos, ou [] se a dica não existe.
static func get_tip(key: String) -> Array:
	var src: Dictionary = TOUCH if Controls.is_touch else PC
	var tip: Array = src.get(key, COMMON.get(key, []))
	if tip.is_empty():
		return []
	var body := I18n.t(tip[1])
	if not Controls.is_touch:
		match key:
			"move":
				body = body % [_k("up"), _k("left"), _k("down"), _k("right")]
			"focus":
				body = body % _k("focus")
			"bomb":
				body = body % _k("bomb")
	return [I18n.t(tip[0]), body]


static func _k(action: String) -> String:
	return I18n.t(Controls.binding_text(action, 1 if action in ["up", "down", "left", "right"] else 0))
