@tool
class_name WoldSkeleton
extends Panel
## A grey shape standing in for something still loading. Size it like the
## thing it replaces (custom_minimum_size), or give it `lines` for a block of
## text. It breathes while `active`; under reduced motion it just sits there.

enum Shape { BLOCK, ROUND }

@export var shape: Shape = Shape.BLOCK:
	set(v):
		shape = v
		_refresh()
## More than 0: draws this many text lines instead of one block, the last one
## shorter. Height comes from the tokens' body text.
@export_range(0, 20) var lines := 0:
	set(v):
		lines = v
		_refresh()
@export var active := true:
	set(v):
		active = v
		_breathe()

var _refreshing := false


func _ready() -> void:
	_refresh()
	_breathe()


func _notification(what: int) -> void:
	if what == NOTIFICATION_VISIBILITY_CHANGED and is_node_ready():
		_breathe()


func _refresh() -> void:
	if _refreshing or not is_node_ready():
		return
	_refreshing = true
	theme_type_variation = &"SkeletonLines" if lines > 0 else (&"SkeletonRound" if shape == Shape.ROUND else &"Skeleton")
	if lines > 0:
		var t := WoldUIRuntime.instance().tokens
		var line := float(t.font_size(0))
		custom_minimum_size.y = lines * line + (lines - 1) * t.space_sm
	queue_redraw()
	_refreshing = false


## The bars drawn in lines mode, in our own space.
func line_rects() -> Array[Rect2]:
	var out: Array[Rect2] = []
	if lines <= 0:
		return out
	var t := WoldUIRuntime.instance().tokens
	var h := float(t.font_size(0))
	for i in lines:
		var w := size.x * (0.6 if i == lines - 1 and lines > 1 else 1.0)
		out.append(Rect2(0, i * (h + t.space_sm), w, h))
	return out


func _draw() -> void:
	if lines <= 0:
		return
	var sb := get_theme_stylebox(&"bar")
	for r in line_rects():
		draw_style_box(sb, r)


func _breathe() -> void:
	if not is_inside_tree() or Engine.is_editor_hint():
		return
	if active and is_visible_in_tree():
		WoldMotion.pulse(self, 0.45)
	else:
		WoldMotion.stop(self)


func _validate_property(property: Dictionary) -> void:
	if property.name == "theme_type_variation" or (property.name == "custom_minimum_size" and lines > 0):
		property.usage &= ~PROPERTY_USAGE_STORAGE
