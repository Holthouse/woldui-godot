extends RefCounted
## TabBar / TabContainer: tabs ease in and out of hover and selection.
# TabBar has no per-tab styling. So the hovered and the selected tab each get
# a live box (and colour) that fades in from how the tab looked, and a tab
# that leaves either state is painted over by a "ghost" of its old look that
# fades out on an overlay. The ghost redraws the tab's text exactly where
# TabBar puts it (checked pixel for pixel), so the colour change crossfades.

const LiveBox := preload("res://addons/woldui/runtime/fade/live_box.gd")
const Lookup := preload("res://addons/woldui/runtime/fade/theme_lookup.gd")
const COLORS: PackedStringArray = ["font_unselected_color", "font_hovered_color", "font_selected_color", "icon_hovered_color", "icon_selected_color"]

var host: Control
var bar: TabBar

var _overlay := Control.new()
var _hover := LiveBox.new()
var _sel := LiveBox.new()
var _look := {}
var _own := {}
var _hover_font := Color.WHITE
var _sel_font := Color.WHITE
var _hovered := -1
var _selected := -1
var _hover_tween: Tween
var _sel_tween: Tween
# {tab, box: StyleBoxFlat, font: Color, a: float, tween}
var _ghosts: Array[Dictionary] = []
var _setting := false
var _reread_queued := false
var _ok := false


func _init(c: Control) -> void:
	host = c
	bar = c.get_tab_bar() if c is TabContainer else c
	_own = Lookup.overrides(c, ["tab_unselected", "tab_hovered", "tab_selected"], COLORS)
	_read()
	if not _ok:
		return
	_selected = bar.current_tab
	_set_hover(_look.hovered, _look.hovered_font)
	_set_sel(_look.selected, _look.selected_font)
	_install()
	_overlay.name = &"WoldTabGhosts"
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_overlay.draw.connect(_draw_ghosts)
	bar.add_child(_overlay, false, Node.INTERNAL_MODE_BACK)
	bar.tab_hovered.connect(_on_hover)
	bar.mouse_exited.connect(_on_hover.bind(-1))
	bar.tab_changed.connect(_on_selected)
	host.theme_changed.connect(_on_theme_changed)


## The live boxes and the ghosts, for tests.
func hover_box() -> StyleBoxFlat:
	return _hover.flat


func selected_box() -> StyleBoxFlat:
	return _sel.flat


func ghosts() -> Array[Dictionary]:
	return _ghosts


func _read() -> void:
	var boxes := {}
	for item in ["tab_unselected", "tab_hovered", "tab_selected"]:
		boxes[item] = Lookup.stylebox(host, item, _own)
	var unselected := WoldStyle.blendable(boxes.tab_unselected, boxes.tab_selected)
	var hovered := WoldStyle.blendable(boxes.tab_hovered, boxes.tab_selected)
	var selected := WoldStyle.blendable(boxes.tab_selected, boxes.tab_hovered)
	_ok = unselected != null and hovered != null and selected != null
	_look = {
		"unselected": unselected, "hovered": hovered, "selected": selected,
		"unselected_font": Lookup.color(host, "font_unselected_color", _own),
		"hovered_font": Lookup.color(host, "font_hovered_color", _own),
		"selected_font": Lookup.color(host, "font_selected_color", _own),
	}


func _install() -> void:
	_setting = true
	host.begin_bulk_theme_override()
	host.add_theme_stylebox_override("tab_hovered", _hover)
	host.add_theme_stylebox_override("tab_selected", _sel)
	host.end_bulk_theme_override()
	_put_colors()
	_setting = false


func _put_colors() -> void:
	var was := _setting
	_setting = true
	# straight onto the bar as well: TabContainer only passes its overrides on
	# a frame later, which would flash the text
	for target in [host, bar] if host != bar else [host]:
		target.begin_bulk_theme_override()
		target.add_theme_color_override("font_hovered_color", _hover_font)
		target.add_theme_color_override("icon_hovered_color", _hover_font)
		target.add_theme_color_override("font_selected_color", _sel_font)
		target.add_theme_color_override("icon_selected_color", _sel_font)
		target.end_bulk_theme_override()
	_setting = was


func _set_hover(box: StyleBoxFlat, font: Color) -> void:
	WoldStyle.blend(box, box, 1.0, _hover.flat)
	_hover.sync_margins()
	_hover_font = font


func _set_sel(box: StyleBoxFlat, font: Color) -> void:
	WoldStyle.blend(box, box, 1.0, _sel.flat)
	_sel.sync_margins()
	_sel_font = font


# how tab `i` looks right now, before the change we're about to make
func _current_look(i: int) -> Array:
	if i == _selected:
		return [_sel.flat.duplicate(), _sel_font]
	if i == _hovered and not bar.is_tab_disabled(i):
		return [_hover.flat.duplicate(), _hover_font]
	var box: StyleBoxFlat = _look.unselected
	var font: Color = _look.unselected_font
	var ghost := _ghost_of(i)
	if ghost:
		var mixed := StyleBoxFlat.new()
		WoldStyle.blend(box, ghost.box, ghost.a, mixed)
		return [mixed, WoldStyle.mix(font, ghost.font, ghost.a)]
	return [box.duplicate(), font]


func _ghost_of(i: int) -> Dictionary:
	for g in _ghosts:
		if g.tab == i:
			return g
	return {}


func _drop_ghost(i: int) -> void:
	for g in _ghosts.duplicate():
		if g.tab == i:
			if g.tween:
				g.tween.kill()
			_ghosts.erase(g)
	_overlay.queue_redraw()


func _on_hover(i: int) -> void:
	if i == _hovered:
		return
	var old := _hovered
	var from := _current_look(i) if i >= 0 else []
	_hovered = i
	if old >= 0 and old != _selected and old < bar.tab_count and not bar.is_tab_disabled(old):
		_add_ghost(old, _hover.flat.duplicate(), _hover_font)
	if i < 0 or i == _selected or bar.is_tab_disabled(i):
		return
	_drop_ghost(i)
	_hover_tween = _fade(_hover_tween, func(v: float):
		WoldStyle.blend(from[0], _look.hovered, v, _hover.flat)
		_hover_font = WoldStyle.mix(from[1], _look.hovered_font, v)
		_put_colors()
		bar.queue_redraw())


func _on_selected(i: int) -> void:
	if i == _selected:
		return
	var old := _selected
	var old_look := [_sel.flat.duplicate(), _sel_font]
	var from := _current_look(i)
	_selected = i
	if old >= 0 and old < bar.tab_count:
		if old == _hovered:
			# still under the mouse: ease from selected to hovered instead
			_hover_tween = _fade(_hover_tween, func(v: float):
				WoldStyle.blend(old_look[0], _look.hovered, v, _hover.flat)
				_hover_font = WoldStyle.mix(old_look[1], _look.hovered_font, v)
				_put_colors()
				bar.queue_redraw())
		else:
			_add_ghost(old, old_look[0], old_look[1])
	if i < 0:
		return
	_drop_ghost(i)
	_sel_tween = _fade(_sel_tween, func(v: float):
		WoldStyle.blend(from[0], _look.selected, v, _sel.flat)
		_sel_font = WoldStyle.mix(from[1], _look.selected_font, v)
		_put_colors()
		bar.queue_redraw())


func _fade(old: Tween, step: Callable) -> Tween:
	if old:
		old.kill()
	step.call(0.0)
	if WoldMotion.reduced():
		step.call(1.0)
		return null
	var t := WoldMotion.tokens()
	var tw := bar.create_tween()
	tw.tween_method(step, 0.0, 1.0, t.duration_fast).set_trans(t.state_transition).set_ease(t.state_ease)
	return tw


func _add_ghost(i: int, box: StyleBoxFlat, font: Color) -> void:
	_drop_ghost(i)
	if WoldMotion.reduced():
		return
	var g := {"tab": i, "box": box, "font": font, "a": 1.0, "tween": null}
	var t := WoldMotion.tokens()
	var tw := bar.create_tween()
	tw.tween_method(func(v: float):
		g.a = v
		_overlay.queue_redraw(), 1.0, 0.0, t.duration_fast).set_trans(t.state_transition).set_ease(t.state_ease)
	tw.tween_callback(func():
		_ghosts.erase(g)
		_overlay.queue_redraw())
	g.tween = tw
	_ghosts.append(g)
	_overlay.queue_redraw()


func _draw_ghosts() -> void:
	for g in _ghosts:
		var i: int = g.tab
		if i >= bar.tab_count or g.a <= 0.0:
			continue
		var rect := bar.get_tab_rect(i)
		var sb: StyleBoxFlat = g.box.duplicate()
		sb.bg_color.a *= g.a
		sb.border_color.a *= g.a
		sb.shadow_color.a *= g.a
		_overlay.draw_style_box(sb, rect)
		var font: Color = g.font
		font.a *= g.a
		_draw_tab_face(i, rect, font)


# Same layout TabBar uses: left margin of the tab's box, icon, separation,
# then the text centred on the tab's height.
func _draw_tab_face(i: int, rect: Rect2, color: Color) -> void:
	var sb := bar.get_theme_stylebox("tab_selected" if i == bar.current_tab else "tab_unselected")
	var x := rect.position.x + sb.get_margin(SIDE_LEFT)
	var icon := bar.get_tab_icon(i)
	if icon:
		var w := icon.get_width()
		var max_w := bar.get_tab_icon_max_width(i)
		var h := icon.get_height()
		if max_w > 0 and w > max_w:
			h = h * max_w / w
			w = max_w
		_overlay.draw_texture_rect(icon, Rect2(x, rect.position.y + floorf((rect.size.y - h) / 2.0), w, h), false, color)
		x += w + bar.get_theme_constant("h_separation")
	var title := bar.get_tab_title(i)
	if title == "":
		return
	var line := TextLine.new()
	line.add_string(title, bar.get_theme_font("font"), bar.get_theme_font_size("font_size"))
	var y := rect.position.y + floorf((rect.size.y - line.get_size().y) / 2.0)
	line.draw(_overlay.get_canvas_item(), Vector2(x, y), color)


func _on_theme_changed() -> void:
	if _setting or _reread_queued:
		return
	_reread_queued = true
	_reread.call_deferred()


func _reread() -> void:
	_reread_queued = false
	if not is_instance_valid(host):
		return
	_read()
	if not _ok:
		return
	if _hover_tween == null or not _hover_tween.is_running():
		_set_hover(_look.hovered, _look.hovered_font)
	if _sel_tween == null or not _sel_tween.is_running():
		_set_sel(_look.selected, _look.selected_font)
	_put_colors()
	bar.queue_redraw()
