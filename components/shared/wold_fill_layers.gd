@tool
extends Control
## Internal. Track + textured fill for WoldMeter and WoldSlider, drawn behind
## the host so the grabber / percentage text stay on top.
# Lives as an internal child, so it never ends up in a .tscn. The fill gets
# clipped to the track's rounded corners through a clip_children mask.

var track_style: StyleBox
var track_rect := Rect2()
## Where the fill stops, host coords: x left-to-right, or y when `vertical`
## (it fills bottom-up to there). `reverse` flips both: right-to-left, or
## top-down.
var fill_end := 0.0
var vertical := false
var reverse := false
var fill: WoldFill

var _mask := Control.new()
var _fill_node := Control.new()


func _init() -> void:
	name = "WoldFillLayers"
	show_behind_parent = true
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	for node in [_mask, _fill_node]:
		node.mouse_filter = Control.MOUSE_FILTER_IGNORE
		node.set_anchors_preset(Control.PRESET_FULL_RECT)
	_mask.clip_children = CanvasItem.CLIP_CHILDREN_ONLY
	_mask.draw.connect(_draw_mask)
	_fill_node.draw.connect(_draw_fill)
	add_child(_mask)
	_mask.add_child(_fill_node)


func refresh() -> void:
	queue_redraw()
	_mask.queue_redraw()
	_fill_node.queue_redraw()


func _draw() -> void:
	if track_style:
		draw_style_box(track_style, track_rect)


# Mask shape. CLIP_CHILDREN_ONLY never draws this itself, it just cuts the fill.
func _draw_mask() -> void:
	var shape := _inner_rect()
	if track_style is StyleBoxFlat:
		var flat := (track_style as StyleBoxFlat).duplicate() as StyleBoxFlat
		flat.bg_color = Color.WHITE
		flat.draw_center = true
		flat.set_border_width_all(0)
		flat.shadow_size = 0
		_mask.draw_style_box(flat, shape)
	else:
		_mask.draw_rect(shape, Color.WHITE)


func _draw_fill() -> void:
	if fill:
		fill.draw_into(_fill_node, _inner_rect(), filled_rect(), vertical)


# minus the border, so the fill sits inside the outline
func _inner_rect() -> Rect2:
	if track_style is StyleBoxFlat:
		var flat := track_style as StyleBoxFlat
		return track_rect.grow_individual(-flat.border_width_left, -flat.border_width_top, -flat.border_width_right, -flat.border_width_bottom)
	return track_rect


## Inside of the track, clamped to fill_end.
func filled_rect() -> Rect2:
	var inner := _inner_rect()
	if vertical:
		var edge := clampf(fill_end, inner.position.y, inner.end.y)
		if reverse:
			return Rect2(inner.position.x, inner.position.y, inner.size.x, edge - inner.position.y)
		return Rect2(inner.position.x, edge, inner.size.x, inner.end.y - edge)
	var x := clampf(fill_end, inner.position.x, inner.end.x)
	if reverse:
		return Rect2(x, inner.position.y, inner.end.x - x, inner.size.y)
	inner.size.x = x - inner.position.x
	return inner
