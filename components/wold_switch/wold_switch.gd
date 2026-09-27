@tool
class_name WoldSwitch
extends "../shared/wold_toggle_base.gd"
## On/off switch for settings. It's a toggle Button, so button_pressed is the
## state and `toggled` is the signal; the knob slides instead of snapping.
## `label` is the text (Button's own text stays empty), `description` a muted
## line under it.

# 0 = off, 1 = on. Only differs from button_pressed while sliding.
var _knob := 0.0
var _sliding := false
# the knob tween hangs off this, so it can't kill a WoldFeedback press dip on us
var _anim := Node.new()


# not in _init: an inherited scene swaps the script, so _init runs twice on
# one node
func _ready() -> void:
	if _anim.get_parent() == null:
		add_child(_anim, false, Node.INTERNAL_MODE_FRONT)
	if not toggled.is_connected(_on_toggled):
		toggled.connect(_on_toggled)
	_knob = 1.0 if button_pressed else 0.0
	super()


## Where the knob is, 0 (off) to 1 (on).
func knob_position() -> float:
	return _knob if _sliding else (1.0 if button_pressed else 0.0)


## The track, in the switch's own space.
func track_rect() -> Rect2:
	return indicator_rect()


func _style() -> StringName:
	return StringName("Switch" + SIZE_SUFFIX[toggle_size])


func _indicator_size() -> Vector2:
	return Vector2(get_theme_constant("track_width"), get_theme_constant("track_height"))


func _on_toggled(on: bool) -> void:
	if not is_inside_tree() or Engine.is_editor_hint():
		queue_redraw()
		return
	_sliding = true
	var t := WoldUIRuntime.instance().tokens
	var tw := WoldMotion.tween_number(_anim, _knob, 1.0 if on else 0.0, func(v: float):
		_knob = v
		queue_redraw(), t.duration_fast)
	tw.finished.connect(func():
		_sliding = false
		_knob = 1.0 if button_pressed else 0.0
		queue_redraw())


func _draw_indicator(track: Rect2) -> void:
	var h := track.size.y
	var k := knob_position()
	var lit := hot()
	var off_col := get_theme_color("track_off").lerp(get_theme_color("track_off_hover"), lit)
	var on_col := get_theme_color("track_on").lerp(get_theme_color("track_on_hover"), lit)
	var fill := off_col.lerp(on_col, k)
	var knob_col := get_theme_color("knob").lerp(get_theme_color("knob_on"), k)
	if disabled:
		fill = get_theme_color("track_disabled")
		knob_col = get_theme_color("knob_disabled")
	var box := StyleBoxFlat.new()
	box.bg_color = fill
	box.set_corner_radius_all(int(h / 2.0))
	box.corner_detail = 8
	box.anti_aliasing = true
	var bw := get_theme_constant("border_width")
	if k < 0.5 or disabled:
		box.border_color = get_theme_color("track_border")
		box.set_border_width_all(bw)
	draw_style_box(box, track)
	var r := h / 2.0
	var kr := r - maxf(h / 8.0, 2.0)
	var cx := lerpf(track.position.x + r, track.end.x - r, k)
	draw_circle(Vector2(cx, track.get_center().y), kr, knob_col, true, -1.0, true)
