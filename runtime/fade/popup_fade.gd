extends RefCounted
## PopupMenu: fades the list in when it opens and eases each row's hover
## highlight in as you move over it.
# Rows only fade in. The one you left snaps off, which reads fine in a list
# and keeps fast mouse moves from smearing.

const LiveBox := preload("res://addons/woldui/runtime/fade/live_box.gd")
const Lookup := preload("res://addons/woldui/runtime/fade/theme_lookup.gd")

var popup: PopupMenu
var animate_open := true
var fade_rows := true

var _box := LiveBox.new()
var _on: StyleBoxFlat
var _off: StyleBoxFlat
var _item := -1
var _tween: Tween
var _setting := false


func _init(p: PopupMenu, open_motion: bool, row_fades: bool) -> void:
	popup = p
	animate_open = open_motion
	fade_rows = row_fades
	p.about_to_popup.connect(_on_open)
	p.popup_hide.connect(_on_hide)
	if fade_rows and not p.has_theme_stylebox_override("hover"):
		_read()
		_to(1.0)
		_setting = true
		p.add_theme_stylebox_override("hover", _box)
		_setting = false
		p.theme_changed.connect(_on_theme_changed)
	else:
		fade_rows = false


func highlight() -> StyleBoxFlat:
	return _box.flat


func _read() -> void:
	_on = WoldStyle.blendable(Lookup.stylebox(popup, "hover"))
	if _on == null:
		_on = WoldStyle.blendable(StyleBoxEmpty.new())
	_off = WoldStyle.blendable(StyleBoxEmpty.new(), _on)


func _to(v: float) -> void:
	WoldStyle.blend(_off, _on, v, _box.flat)
	_box.sync_margins()
	_redraw(popup)


# PopupMenu is a Window, the rows are drawn by a control a few levels in
func _redraw(node: Node) -> void:
	for child in node.get_children(true):
		if child is CanvasItem:
			child.queue_redraw()
		_redraw(child)


func _on_open() -> void:
	# WoldMenu and WoldSelect animate their own
	var own := popup is WoldMenu or popup.get_parent() is WoldSelect
	if animate_open and not own:
		WoldMotion.popup_in(popup)
	if not fade_rows:
		return
	_item = popup.get_focused_item()
	if _tween:
		_tween.kill()
	_to(1.0)
	if not popup.get_tree().process_frame.is_connected(_poll):
		popup.get_tree().process_frame.connect(_poll)


func _on_hide() -> void:
	if popup.is_inside_tree() and popup.get_tree().process_frame.is_connected(_poll):
		popup.get_tree().process_frame.disconnect(_poll)


# process_frame runs after input and before drawing, so the new row gets the
# clear box on its very first frame
func _poll() -> void:
	if not is_instance_valid(popup):
		return
	var i := popup.get_focused_item()
	if i == _item:
		return
	_item = i
	if i < 0:
		return
	if _tween:
		_tween.kill()
	if WoldMotion.reduced():
		_to(1.0)
		return
	_to(0.0)
	_tween = popup.create_tween()
	_tween.tween_method(_to, 0.0, 1.0, WoldMotion.tokens().duration_instant).set_trans(WoldMotion.tokens().state_transition).set_ease(WoldMotion.tokens().state_ease)


func _on_theme_changed() -> void:
	if _setting:
		return
	_read()
	_to(1.0)
