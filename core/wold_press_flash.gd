@tool
class_name WoldPressFlash
extends WoldPressEffect
## The whole button lights up and fades back. Quieter than a ripple.

## Clear = the button's text colour.
@export var color := Color(0, 0, 0, 0)
@export_range(0.0, 1.0, 0.01) var opacity := 0.25
@export_range(0.05, 2.0, 0.05, "suffix:s") var seconds := 0.35


func _play(button: Control, _at: Vector2, layer: Control) -> void:
	var ink := color if color.a > 0.0 else button.get_theme_color("font_color")
	var left := [1.0]
	layer.draw.connect(func():
		layer.draw_rect(Rect2(Vector2.ZERO, layer.size), Color(ink, opacity * left[0])))
	var tw := layer.create_tween()
	tw.tween_method(func(v: float):
		left[0] = v
		layer.queue_redraw(), 1.0, 0.0, seconds).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	release(layer, seconds)
