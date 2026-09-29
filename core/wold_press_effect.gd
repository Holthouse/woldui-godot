@tool
class_name WoldPressEffect
extends Resource
## What a button does when it's pressed, on top of the press dip. WoldFeedback
## plays it. The tokens' press_effect is the game-wide one; WoldButton's
## press_effect, or metadata wold_press_effect on any Button, overrides it
## (the string "none" turns it off).
##
## To make your own, extend this and override _play(). See
## gallery/examples/spark_press.gd.


## Plays on `button` at `at`, in the button's own space. Skipped under reduced
## motion.
func play(button: Control, at: Vector2) -> void:
	if WoldMotion.reduced() or not button.is_inside_tree():
		return
	_play(button, at, _layer(button))


## Override this. `layer` sits over the button, clipped to the shape of its
## box, and is yours: draw on it (its draw signal) or add children, then call
## release(layer, seconds) so it goes away.
func _play(_button: Control, _at: Vector2, layer: Control) -> void:
	release(layer, 0.0)


## Frees `layer` (and the mask it sits in) after `seconds`.
func release(layer: Control, seconds: float) -> void:
	var mask := layer.get_parent() if layer.get_parent() and layer.get_parent().name == &"WoldPressLayer" else layer
	# by id: a lambda that captured a node freed before the timer fires logs an
	# error even when it checks validity first (a click that closes its own screen)
	var id := mask.get_instance_id()
	layer.get_tree().create_timer(seconds).timeout.connect(func():
		var m := instance_from_id(id) as Node
		if m != null:
			m.queue_free())


## The drawing surface _play gets: a Panel masking its children to the
## button's rounded box (clip_children draws the mask, not the Panel).
static func _layer(button: Control) -> Control:
	var mask := Panel.new()
	mask.name = &"WoldPressLayer"
	mask.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mask.clip_children = CanvasItem.CLIP_CHILDREN_ONLY
	mask.add_theme_stylebox_override("panel", shape_of(button))
	mask.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	button.add_child(mask, false, Node.INTERNAL_MODE_BACK)
	var surface := Control.new()
	surface.name = &"Surface"
	surface.mouse_filter = Control.MOUSE_FILTER_IGNORE
	surface.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mask.add_child(surface)
	return surface


## An opaque box with the button's corners, to clip against. A ghost button's
## own box is see-through, and clip_children goes by alpha.
static func shape_of(button: Control) -> StyleBoxFlat:
	var src: Variant = button.get_theme_stylebox("normal")
	# the state fades draw through a live box that carries the real one inside
	if src and not src is StyleBoxFlat and "flat" in src:
		src = src.flat
	var out := StyleBoxFlat.new()
	out.bg_color = Color.WHITE
	out.anti_aliasing = true
	if src is StyleBoxFlat:
		for corner in 4:
			out.set_corner_radius(corner, src.get_corner_radius(corner))
		for side in 4:
			out.set_expand_margin(side, src.get_expand_margin(side))
		out.corner_detail = src.corner_detail
	return out
