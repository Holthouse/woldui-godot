extends RefCounted
## Fades the focus ring in on text fields, sliders and lists. Buttons get
## theirs from button_fade.
# Fade in only: when focus leaves, the engine just stops drawing the ring.

const LiveBox := preload("res://addons/woldui/runtime/fade/live_box.gd")
const Lookup := preload("res://addons/woldui/runtime/fade/theme_lookup.gd")

var control: Control

var _ring := LiveBox.new()
var _on: StyleBoxFlat
var _off: StyleBoxFlat
var _ringed := false
var _tween: Tween
var _setting := false
var _reread_queued := false


func _init(c: Control) -> void:
	control = c
	# someone styled this one by hand, leave it be
	if c.has_theme_stylebox_override("focus"):
		return
	_read()
	_ringed = c.has_focus(true)
	_to(1.0 if _ringed else 0.0)
	_setting = true
	c.add_theme_stylebox_override("focus", _ring)
	_setting = false
	c.draw.connect(_on_draw)
	c.theme_changed.connect(_on_theme_changed)


func ring() -> StyleBoxFlat:
	return _ring.flat


func _read() -> void:
	var focus := Lookup.stylebox(control, "focus")
	_on = WoldStyle.blendable(focus)
	if _on == null:
		_on = WoldStyle.blendable(StyleBoxEmpty.new())
	_off = WoldStyle.blendable(StyleBoxEmpty.new(), _on)
	for side in 4:
		_off.set_content_margin(side, _on.get_content_margin(side))


func _to(v: float) -> void:
	WoldStyle.blend(_off, _on, v, _ring.flat)
	_ring.sync_margins()
	control.queue_redraw()


func _on_draw() -> void:
	var ringed := control.has_focus(true)
	if ringed == _ringed:
		return
	_ringed = ringed
	if _tween:
		_tween.kill()
	if not ringed or WoldMotion.reduced():
		_to(1.0 if ringed else 0.0)
		return
	_to(0.0)
	_tween = control.create_tween()
	_tween.tween_method(_to, 0.0, 1.0, WoldMotion.tokens().duration_fast).set_trans(WoldMotion.tokens().state_transition).set_ease(WoldMotion.tokens().state_ease)


func _on_theme_changed() -> void:
	if _setting or _reread_queued:
		return
	_reread_queued = true
	_reread.call_deferred()


func _reread() -> void:
	_reread_queued = false
	if not is_instance_valid(control):
		return
	_read()
	if _tween == null or not _tween.is_running():
		_to(1.0 if _ringed else 0.0)
