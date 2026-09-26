@tool
class_name WoldSpinner
extends Control
## "Working on it": a turning loader icon. Turns only while visible; under
## reduced motion it holds still and breathes instead.
# The icon is rotated inside _draw, not by rotating the node, so it's fine in
# containers and the offset transform stays free for WoldMotion.

enum Size { SM, MD, LG }

## Not `size`, Control has one.
@export var spinner_size: Size = Size.MD:
	set(v):
		spinner_size = v
		_refresh()
## Lucide name. loader-circle, loader, loader-pinwheel...
@export var icon := "loader-circle":
	set(v):
		icon = v
		_refresh()

var angle := 0.0
var _texture: Texture2D


func _ready() -> void:
	theme_type_variation = &"Spinner"
	var ui := WoldUIRuntime.instance()
	if not ui.preferences_changed.is_connected(_update_running):
		ui.preferences_changed.connect(_update_running)
	_refresh()


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_VISIBILITY_CHANGED, NOTIFICATION_ENTER_TREE:
			_update_running.call_deferred()
		NOTIFICATION_THEME_CHANGED:
			queue_redraw()


func is_spinning() -> bool:
	return is_processing()


func _refresh() -> void:
	if not is_node_ready():
		return
	var t := WoldUIRuntime.instance().tokens
	var suffix: String = ["Sm", "", "Lg"][spinner_size]
	_texture = t.icon(icon, suffix)
	var px := float([t.icon_size_sm, t.icon_size_md, t.icon_size_lg][spinner_size])
	custom_minimum_size = Vector2(px, px)
	queue_redraw()


func _update_running() -> void:
	if not is_inside_tree():
		return
	var ui := WoldUIRuntime.instance()
	var run := is_visible_in_tree() and not Engine.is_editor_hint()
	set_process(run and not ui.reduced_motion)
	if run and ui.reduced_motion:
		WoldMotion.pulse(self)
	elif not run:
		WoldMotion.stop(self)


func _process(delta: float) -> void:
	var period := maxf(get_theme_constant(&"period_ms") / 1000.0, 0.05)
	angle = fmod(angle + TAU * delta / period, TAU)
	queue_redraw()


func _draw() -> void:
	if _texture == null:
		return
	var s := Vector2(_texture.get_width(), _texture.get_height())
	var box := minf(size.x, size.y)
	var k := box / maxf(s.x, 1.0)
	draw_set_transform(size / 2.0, angle, Vector2(k, k))
	draw_texture(_texture, -s / 2.0, get_theme_color(&"color"))
	draw_set_transform(Vector2.ZERO)


func _validate_property(property: Dictionary) -> void:
	if property.name in ["custom_minimum_size", "theme_type_variation"]:
		property.usage &= ~PROPERTY_USAGE_STORAGE
