@tool
class_name WoldPageDots
extends Control
## "Page 2 of 5" as dots; the current one stretches into a pill and slides
## along. Click a dot to jump. Not a focus stop: the carousel or screen that
## owns it handles the keys.

signal page_selected(index: int)

@export_range(0, 50) var count := 3:
	set(v):
		count = v
		current = current
		update_minimum_size()
		queue_redraw()
@export var current := 0:
	set(v):
		var from := current
		current = clampi(v, 0, maxi(count - 1, 0))
		_slide(from)

# where the pill is, as a float index; slides between pages
var _at := 0.0
var _hot := -1
var _anim := Node.new()
# per dot hover glow, eased
var _lit := PackedFloat32Array()
var _lit_tween: Tween


func _ready() -> void:
	theme_type_variation = &"PageDots"
	if _anim.get_parent() == null:
		add_child(_anim, false, Node.INTERNAL_MODE_FRONT)
	_at = current
	mouse_exited.connect(_set_hot.bind(-1))


func _get_minimum_size() -> Vector2:
	var dot := float(get_theme_constant(&"dot"))
	if count <= 0:
		return Vector2(0, dot)
	return Vector2((count - 1) * (dot + get_theme_constant(&"gap")) + get_theme_constant(&"pill"), dot)


## Each dot's rect right now, in our own space.
func dot_rects() -> Array[Rect2]:
	var out: Array[Rect2] = []
	var dot := float(get_theme_constant(&"dot"))
	var pill := float(get_theme_constant(&"pill"))
	var gap := float(get_theme_constant(&"gap"))
	var x := (size.x - get_combined_minimum_size().x) / 2.0
	var y := (size.y - dot) / 2.0
	for i in count:
		var w := lerpf(dot, pill, _weight(i))
		out.append(Rect2(x, y, w, dot))
		x += w + gap
	return out


# 1 for the pill, 0 for a plain dot, in between while sliding
func _weight(i: int) -> float:
	return clampf(1.0 - absf(i - _at), 0.0, 1.0)


func _slide(from: int) -> void:
	if not is_node_ready():
		_at = current
		return
	if not is_inside_tree() or Engine.is_editor_hint():
		_at = current
		queue_redraw()
		return
	var t := WoldUIRuntime.instance().tokens
	WoldMotion.tween_number(_anim, _at if from != current else float(current), float(current), func(v: float):
		_at = v
		queue_redraw(), t.duration_base)


func _gui_input(event: InputEvent) -> void:
	var mm := event as InputEventMouseMotion
	if mm:
		_set_hot(_dot_at(mm.position))
	var mb := event as InputEventMouseButton
	if mb and mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
		var i := _dot_at(mb.position)
		if i >= 0:
			accept_event()
			current = i
			page_selected.emit(i)


func _set_hot(h: int) -> void:
	if h == _hot:
		return
	_hot = h
	_lit.resize(count)
	var from := _lit.duplicate()
	_lit_tween = WoldMotion.blend(_lit_tween, self, 0.0, 1.0, func(v: float):
		for i in _lit.size():
			_lit[i] = lerpf(from[i], 1.0 if i == _hot else 0.0, v)
		queue_redraw())


# generous hit boxes: the gap is split between neighbours
func _dot_at(p: Vector2) -> int:
	var gap := float(get_theme_constant(&"gap"))
	var rects := dot_rects()
	for i in rects.size():
		# at least 44 px tall: a dot is far smaller than a fingertip
		var tall := maxf(4.0, (44.0 - rects[i].size.y) / 2.0)
		if rects[i].grow_individual(gap / 2.0 + 4.0, tall, gap / 2.0 + 4.0, tall).has_point(p):
			return i
	return -1


func _draw() -> void:
	var idle := get_theme_color(&"dot")
	var active := get_theme_color(&"active")
	var rects := dot_rects()
	for i in rects.size():
		var base := idle.lerp(get_theme_color(&"dot_hover"), _lit[i] if i < _lit.size() else 0.0)
		var sb := StyleBoxFlat.new()
		sb.bg_color = base.lerp(active, _weight(i))
		sb.set_corner_radius_all(int(rects[i].size.y / 2.0))
		sb.anti_aliasing = true
		sb.corner_detail = 8
		draw_style_box(sb, rects[i])


func _validate_property(property: Dictionary) -> void:
	if property.name == "theme_type_variation":
		property.usage &= ~PROPERTY_USAGE_STORAGE
