@tool
class_name WoldMeter
extends ProgressBar
## ProgressBar that can draw a texture as its fill (health bar with a pattern,
## a wood-grain XP bar...). Without a textured WoldFill it's just a normal
## ProgressBar in whatever Meter* style you give it.
# The texture fill follows fill_mode like the native one: set
# FILL_BOTTOM_TO_TOP (and a tall size) for an upright bar.

const FillLayers := preload("../shared/wold_fill_layers.gd")

## Needs a texture to kick in. Clipped to the track's rounded corners.
@export var fill: WoldFill:
	set(value):
		if fill and fill.changed.is_connected(_refresh):
			fill.changed.disconnect(_refresh)
		fill = value
		if fill:
			fill.changed.connect(_refresh)
		_refresh()

var _layers := FillLayers.new()
var _placed_mode := -1
# same trick as WoldButton: a hidden twin to read the un-overridden styleboxes
var _probe := ProgressBar.new()


func _init() -> void:
	# an inherited scene runs _init once per script level; keep one of each
	for child in get_children(true):
		if child.name in [&"WoldProbe", &"WoldFillLayers"]:
			remove_child(child)
			child.free()
	_probe.name = &"WoldProbe"
	_probe.visible = false
	add_child(_probe, false, Node.INTERNAL_MODE_FRONT)
	add_child(_layers, false, Node.INTERNAL_MODE_FRONT)
	if not value_changed.is_connected(_on_value):
		value_changed.connect(_on_value)
		changed.connect(_place)


func _on_value(_v: float) -> void:
	_place()


func _ready() -> void:
	_refresh()


func _notification(what: int) -> void:
	if what == NOTIFICATION_THEME_CHANGED or what == NOTIFICATION_RESIZED:
		_refresh()
	# fill_mode has no signal, but setting it redraws
	elif what == NOTIFICATION_DRAW and fill_mode != _placed_mode and uses_fill():
		_place.call_deferred()


func uses_fill() -> bool:
	return fill != null and fill.texture != null


## Where the texture goes. Handy for tests or drawing on top.
func filled_rect() -> Rect2:
	return _layers.filled_rect()


func _refresh() -> void:
	_probe.theme_type_variation = theme_type_variation
	var on := uses_fill()
	_layers.visible = on
	_layers.fill = fill
	if on:
		_layers.track_style = _probe.get_theme_stylebox("background")
		# blank out the native track + fill, FillLayers draws both instead
		for item in ["background", "fill"]:
			if not has_theme_stylebox_override(item):
				add_theme_stylebox_override(item, StyleBoxEmpty.new())
	else:
		for item in ["background", "fill"]:
			if has_theme_stylebox_override(item):
				remove_theme_stylebox_override(item)
	_place()


func _place() -> void:
	var span := max_value - min_value
	var filled := clampf((value - min_value) / span, 0.0, 1.0) if span > 0.0 else 0.0
	_layers.track_rect = Rect2(Vector2.ZERO, size)
	var edge := Rect2(Vector2.ZERO, size)
	if _layers.track_style is StyleBoxFlat:
		var flat := _layers.track_style as StyleBoxFlat
		edge = edge.grow_individual(-flat.border_width_left, -flat.border_width_top, -flat.border_width_right, -flat.border_width_bottom)
	_placed_mode = fill_mode
	_layers.vertical = fill_mode == FILL_BOTTOM_TO_TOP or fill_mode == FILL_TOP_TO_BOTTOM
	_layers.reverse = fill_mode == FILL_END_TO_BEGIN or fill_mode == FILL_TOP_TO_BOTTOM
	match fill_mode:
		FILL_END_TO_BEGIN:
			_layers.fill_end = edge.end.x - edge.size.x * filled
		FILL_BOTTOM_TO_TOP:
			_layers.fill_end = edge.end.y - edge.size.y * filled
		FILL_TOP_TO_BOTTOM:
			_layers.fill_end = edge.position.y + edge.size.y * filled
		_:
			_layers.fill_end = edge.position.x + edge.size.x * filled
	_layers.refresh()
