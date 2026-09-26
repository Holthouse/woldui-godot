@tool
class_name WoldMeter
extends ProgressBar
## ProgressBar that can draw a texture as its fill (health bar with a pattern,
## a wood-grain XP bar...). Without a textured WoldFill it's just a normal
## ProgressBar in whatever Meter* style you give it.
# TODO: left-to-right only. fill_mode is ignored once a texture is in play.

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
# same trick as WoldButton: a hidden twin to read the un-overridden styleboxes
var _probe := ProgressBar.new()


func _init() -> void:
	_probe.visible = false
	add_child(_probe, false, Node.INTERNAL_MODE_FRONT)
	add_child(_layers, false, Node.INTERNAL_MODE_FRONT)
	value_changed.connect(func(_v): _place())
	changed.connect(_place)


func _ready() -> void:
	_refresh()


func _notification(what: int) -> void:
	if what == NOTIFICATION_THEME_CHANGED or what == NOTIFICATION_RESIZED:
		_refresh()


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
	var ratio := clampf((value - min_value) / span, 0.0, 1.0) if span > 0.0 else 0.0
	_layers.track_rect = Rect2(Vector2.ZERO, size)
	var inner_start := 0.0
	if _layers.track_style is StyleBoxFlat:
		inner_start = (_layers.track_style as StyleBoxFlat).border_width_left
	var inner_width := size.x - inner_start * 2.0
	_layers.fill_end = inner_start + inner_width * ratio
	_layers.refresh()
