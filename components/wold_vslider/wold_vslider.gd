@tool
class_name WoldVSlider
extends VSlider
## WoldSlider standing up: a volume fader, a zoom level. Same props; the fill
## grows from the bottom up to the grabber.
## No fill texture = plain VSlider in its theme style.

const FillLayers := preload("../shared/wold_fill_layers.gd")

## Only used if it has a texture.
@export var fill: WoldFill:
	set(value):
		if fill and fill.changed.is_connected(_refresh):
			fill.changed.disconnect(_refresh)
		fill = value
		if fill:
			fill.changed.connect(_refresh)
		_refresh()
## Rail thickness in px, 0 = from the style. Textures look better thick.
@export_range(0, 64) var track_width := 0:
	set(value):
		track_width = value
		_refresh()

var _layers := FillLayers.new()
var _probe := VSlider.new()


func _init() -> void:
	# an inherited scene runs _init once per script level; keep one of each
	for child in get_children(true):
		if child.name in [&"WoldProbe", &"WoldFillLayers"]:
			remove_child(child)
			child.free()
	_probe.name = &"WoldProbe"
	_probe.visible = false
	_layers.vertical = true
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


func uses_fill() -> bool:
	return fill != null and fill.texture != null


func filled_rect() -> Rect2:
	return _layers.filled_rect()


## Grabber centre in local y (min at the bottom). The fill ends here.
func grabber_center_y() -> float:
	var grabber := get_theme_icon("grabber")
	var gh: float = float(grabber.get_height()) if grabber else 0.0
	var span := max_value - min_value
	var filled := clampf((value - min_value) / span, 0.0, 1.0) if span > 0.0 else 0.0
	return size.y - (filled * (size.y - gh) + gh / 2.0)


func _refresh() -> void:
	_probe.theme_type_variation = theme_type_variation
	var on := uses_fill()
	_layers.visible = on
	_layers.fill = fill
	if on:
		_layers.track_style = _probe.get_theme_stylebox("slider")
		for item in ["slider", "grabber_area", "grabber_area_highlight"]:
			if not has_theme_stylebox_override(item):
				add_theme_stylebox_override(item, StyleBoxEmpty.new())
	else:
		for item in ["slider", "grabber_area", "grabber_area_highlight"]:
			if has_theme_stylebox_override(item):
				remove_theme_stylebox_override(item)
	_place()


func _place() -> void:
	var w := float(track_width)
	if w <= 0.0 and _layers.track_style:
		w = maxf(_layers.track_style.get_minimum_size().x, 4.0)
	_layers.track_rect = Rect2((size.x - w) / 2.0, 0.0, w, size.y)
	_layers.fill_end = grabber_center_y()
	_layers.refresh()
