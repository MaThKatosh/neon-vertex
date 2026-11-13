extends Node2D
## Nó auxiliar: delega o desenho para uma função de outro script.
## Útil para desenhar coisas do mesmo sistema em camadas (z_index) diferentes.

var draw_fn: Callable


func _draw() -> void:
	if draw_fn.is_valid():
		draw_fn.call(self)
