@tool
extends WoldPressEffect
## Custom press effect: a ring of sparks flies out from the press. Shows how
## little a WoldPressEffect needs: draw on the layer, tween, release.

@export var sparks := 10
@export var spark_color := Color(1.0, 0.85, 0.4)
@export_range(0.1, 2.0, 0.05, "suffix:s") var seconds := 0.45


func _play(button: Control, at: Vector2, layer: Control) -> void:
	var reach := button.size.length() * 0.35
	var t := [0.0]
	layer.draw.connect(func():
		var v: float = t[0]
		for i in sparks:
			var dir := Vector2.RIGHT.rotated(TAU * i / sparks)
			layer.draw_circle(at + dir * reach * v, 2.5 * (1.0 - v) + 0.5, Color(spark_color, 1.0 - v), true, -1.0, true))
	var tw := layer.create_tween()
	tw.tween_method(func(v: float):
		t[0] = v
		layer.queue_redraw(), 0.0, 1.0, seconds).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	release(layer, seconds)
