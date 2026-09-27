extends RefCounted
## Crossfades a Button between its theme states instead of the hard swap.
## WoldFeedback makes one per button when fade_states is on.
# Every state stylebox on the button is overridden with ONE live box, and
# every font/icon colour with one colour, so the engine can't swap looks
# behind our back. ThemeLookup reads what the theme really says for each
# state, from under those overrides. (Not a hidden twin Button: that would
# turn up in every find_children("*", "BaseButton") the game does.)
# State changes are noticed in the draw signal. That frame was drawn with our
# box, which still looks like the old state, so nothing pops for a frame.

const LiveBox := preload("res://addons/woldui/runtime/fade/live_box.gd")
const Mark := preload("res://addons/woldui/runtime/fade/check_mark.gd")
const Lookup := preload("res://addons/woldui/runtime/fade/theme_lookup.gd")
const BOXES: PackedStringArray = ["normal", "hover", "pressed", "hover_pressed", "disabled"]
# "focus" = normal while focused; Button has its own font/icon colours for it
const FONT := {
	"normal": "font_color", "focus": "font_focus_color", "hover": "font_hover_color",
	"pressed": "font_pressed_color", "hover_pressed": "font_hover_pressed_color",
	"disabled": "font_disabled_color",
}
const ICON := {
	"normal": "icon_normal_color", "focus": "icon_focus_color", "hover": "icon_hover_color",
	"pressed": "icon_pressed_color", "hover_pressed": "icon_hover_pressed_color",
	"disabled": "icon_disabled_color",
}

var button: Button
var state := ""

var _own := {}
var _fonts := {}
var _icons := {}
var _box := LiveBox.new()
var _ring := LiveBox.new()
var _from := StyleBoxFlat.new()
var _boxes := {}
var _ring_on: StyleBoxFlat
var _ring_off: StyleBoxFlat
var _font := Color.WHITE
var _icon := Color.WHITE
var _from_font := Color.WHITE
var _from_icon := Color.WHITE
var _put_font := Color(0, 0, 0, 0)
var _put_icon := Color(0, 0, 0, 0)
var _corners: Array[bool] = [true, true, true, true]
var _ringed := false
var _tween: Tween
var _ring_tween: Tween
var _boxes_ok := true
var _setting := false
var _reread_queued := false
# CheckBox / CheckButton: the old mark stays on an overlay while the new one
# fades in over it
var _marks: Control
var _mark_name := ""
var _mark_from := ""
var _mark := 1.0
var _mark_tween: Tween


func _init(b: Button) -> void:
	button = b
	# overrides the button already had are what it should fade to. Not a
	# strip's squared copies though, it hands us the corners instead
	var strip := b.get_parent() is WoldButtonStrip
	var boxes := [] if strip else Array(BOXES) + ["focus"]
	_own = Lookup.overrides(b, boxes, FONT.values() + ICON.values())
	_read()
	state = _state_now()
	_ringed = b.has_focus(true)
	_setting = true
	_step(1.0)
	_ring_to(1.0 if _ringed else 0.0)
	b.begin_bulk_theme_override()
	if _boxes_ok:
		for item in BOXES:
			b.add_theme_stylebox_override(item, _box)
	if _ring_on:
		b.add_theme_stylebox_override("focus", _ring)
	b.end_bulk_theme_override()
	_setting = false
	if Mark.applies(b):
		_mark_name = Mark.icon_name(b)
		_marks = Control.new()
		_marks.name = &"WoldMarkFade"
		_marks.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_marks.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		_marks.draw.connect(_draw_marks)
		b.add_child(_marks, false, Node.INTERNAL_MODE_BACK)
	b.draw.connect(_on_draw)
	b.theme_changed.connect(_on_theme_changed)


## normal, focus, hover, pressed, hover_pressed or disabled. Same rules the
## engine uses to pick a stylebox and font colour.
func _state_now() -> String:
	match button.get_draw_mode():
		BaseButton.DRAW_DISABLED:
			return "disabled"
		BaseButton.DRAW_PRESSED:
			return "pressed"
		BaseButton.DRAW_HOVER:
			return "hover"
		BaseButton.DRAW_HOVER_PRESSED:
			return "hover_pressed"
	return "focus" if button.has_focus() else "normal"


## What's being drawn right now. For tests.
func box() -> StyleBoxFlat:
	return _box.flat


func font_color() -> Color:
	return _font


func ring() -> StyleBoxFlat:
	return _ring.flat


## New per-control values to fade between, item name -> StyleBox or Color;
## WoldCustomize hands them over instead of overriding the button itself.
func set_own(own: Dictionary) -> void:
	_own = own.duplicate()
	_read()
	if not is_fading():
		_step(1.0)
	_ring_to(1.0 if _ringed else 0.0)


## Square off corners, [top_left, top_right, bottom_right, bottom_left].
## WoldButtonStrip does this instead of its own overrides.
func set_corners(keep: Array[bool]) -> void:
	if keep == _corners:
		return
	_corners = keep.duplicate()
	if _tween == null or not _tween.is_running():
		_step(1.0)
	_ring_to(1.0 if _ringed else 0.0)


func is_fading() -> bool:
	return _tween != null and _tween.is_running()


func _read() -> void:
	_boxes_ok = true
	var normal := Lookup.stylebox(button, "normal", _own)
	for item in BOXES:
		var sb := WoldStyle.blendable(Lookup.stylebox(button, item, _own), normal)
		_boxes_ok = _boxes_ok and sb != null
		_boxes[item] = sb
	_boxes["focus"] = _boxes["normal"]
	for s in FONT:
		_fonts[s] = Lookup.color(button, FONT[s], _own)
		_icons[s] = Lookup.color(button, ICON[s], _own)
	var focus := Lookup.stylebox(button, "focus", _own)
	_ring_on = WoldStyle.blendable(focus)
	_ring_off = null
	if _ring_on:
		_ring_off = WoldStyle.blendable(StyleBoxEmpty.new(), _ring_on)
		for side in 4:
			_ring_off.set_content_margin(side, focus.get_content_margin(side))


func _on_draw() -> void:
	var now := _state_now()
	if now != state:
		_go(now)
	var ringed := button.has_focus(true)
	if ringed != _ringed:
		_ringed = ringed
		_fade_ring()
	if _marks:
		var mark := Mark.icon_name(button)
		if mark != _mark_name:
			_fade_mark(mark)


## 1 when the check mark is settled, less while a new one fades in.
func mark_progress() -> float:
	return _mark


func _fade_mark(to: String) -> void:
	_mark_from = _mark_name
	_mark_name = to
	_mark = 0.0
	_mark_tween = WoldMotion.blend(_mark_tween, button, 0.0, 1.0, func(v: float):
		_mark = v
		_marks.queue_redraw())


# the engine already drew the new mark underneath; cover it with the old one
# and lay the new one over that at the fade's alpha
func _draw_marks() -> void:
	if _mark >= 1.0 or _mark_from == "":
		return
	var old := button.get_theme_icon(_mark_from)
	var now := button.get_theme_icon(_mark_name)
	if old == null or now == null:
		return
	_marks.draw_texture_rect(old, Mark.rect(button, old), false)
	_marks.draw_texture_rect(now, Mark.rect(button, now), false, Color(1, 1, 1, _mark))


func _go(to: String) -> void:
	state = to
	_from = _box.flat.duplicate()
	_from_font = _font
	_from_icon = _icon
	if _tween:
		_tween.kill()
	var t := WoldMotion.tokens()
	# presses have to feel instant, the rest can breathe
	var d := t.duration_instant if to.ends_with("pressed") else t.duration_fast
	if WoldMotion.reduced() or d <= 0.0:
		_step(1.0)
		return
	_tween = button.create_tween()
	_tween.tween_method(_step, 0.0, 1.0, d).set_trans(t.state_transition).set_ease(t.state_ease)


func _step(v: float) -> void:
	if _boxes_ok:
		var to: StyleBoxFlat = _boxes[state]
		WoldStyle.blend(_from if v < 1.0 else to, to, v, _box.flat)
		for corner in 4:
			if not _corners[corner]:
				_box.flat.set_corner_radius(corner, 0)
		_box.sync_margins()
	_font = WoldStyle.mix(_from_font, _fonts[state], v)
	_icon = WoldStyle.mix(_from_icon, _icons[state], v)
	# colour overrides re-theme the button, so only when they move. Putting
	# them every step loops: WoldButton restyles on THEME_CHANGED, that lands
	# in _reread, which steps again
	if _font != _put_font or _icon != _put_icon:
		_put_font = _font
		_put_icon = _icon
		var was := _setting
		_setting = true
		button.begin_bulk_theme_override()
		for item in FONT.values():
			button.add_theme_color_override(item, _font)
		for item in ICON.values():
			button.add_theme_color_override(item, _icon)
		button.end_bulk_theme_override()
		_setting = was
	button.queue_redraw()


func _ring_to(v: float) -> void:
	if _ring_on == null:
		return
	WoldStyle.blend(_ring_off, _ring_on, v, _ring.flat)
	for corner in 4:
		if not _corners[corner]:
			_ring.flat.set_corner_radius(corner, 0)
	_ring.sync_margins()
	button.queue_redraw()


# Only fades in. Once focus leaves, the engine stops drawing the ring at once.
func _fade_ring() -> void:
	if _ring_on == null:
		return
	if _ring_tween:
		_ring_tween.kill()
	if not _ringed or WoldMotion.reduced():
		_ring_to(1.0 if _ringed else 0.0)
		return
	_ring_to(0.0)
	_ring_tween = button.create_tween()
	_ring_tween.tween_method(_ring_to, 0.0, 1.0, WoldMotion.tokens().duration_fast).set_trans(WoldMotion.tokens().state_transition).set_ease(WoldMotion.tokens().state_ease)


func _on_theme_changed() -> void:
	if _setting or _reread_queued:
		return
	_reread_queued = true
	_reread.call_deferred()


func _reread() -> void:
	_reread_queued = false
	if not is_instance_valid(button):
		return
	var had_boxes := _boxes_ok
	_read()
	if had_boxes != _boxes_ok:
		# a texture box turned up (or went away): hand the boxes back
		_setting = true
		for item in BOXES:
			if _boxes_ok:
				button.add_theme_stylebox_override(item, _box)
			else:
				button.remove_theme_stylebox_override(item)
		_setting = false
	if not is_fading():
		_step(1.0)
	_ring_to(1.0 if _ringed else 0.0)

