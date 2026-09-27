@tool
class_name WoldRipple
extends WoldPressEffect
## A circle grows out from where the button was pressed and fades, like the
## web version's ripple.

## Clear = the button's text colour.
@export var color := Color(0, 0, 0, 0)
@export_range(0.0, 1.0, 0.01) var opacity := 0.25
@export_range(0.05, 2.0, 0.05, "suffix:s") var seconds := 0.6


func _play(button: Control, at: Vector2, layer: Control) -> void:
	var ink := color if color.a > 0.0 else button.get_theme_color("font_color")
	var reach := maxf(button.size.x, button.size.y)
	var grown := [0.0]
	layer.draw.connect(func():
		var v: float = grown[0]
		layer.draw_circle(at, reach * v, Color(ink, opacity * (1.0 - v)), true, -1.0, true))
	# one eased curve for both, so it reads as a spread rather than a blink
	var tw := layer.create_tween()
	tw.tween_method(func(v: float):
		grown[0] = v
		layer.queue_redraw(), 0.0, 1.0, seconds).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	release(layer, seconds)
