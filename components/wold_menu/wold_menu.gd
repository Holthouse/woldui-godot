@tool
class_name WoldMenu
extends PopupMenu
## A PopupMenu you fill in code with a callback per item, then open next to
## a control (dropdown) or at the mouse (context menu). Keyboard, pad,
## submenus and type-to-search are PopupMenu's own. Focus goes back to
## whatever had it when the menu closes.
##   var m := WoldMenu.new()
##   m.item("Rename", rename, "pencil", "F2")
##   m.danger("Disband", disband, "trash")
##   add_child(m)
##   m.open_at(button)

enum Placement { BOTTOM, TOP, RIGHT, LEFT }
enum Align { START, CENTER, END }

# item id -> Callable
var _actions := {}
var _danger := {}
var _return_focus: Control


func _init() -> void:
	id_pressed.connect(_on_id)
	about_to_popup.connect(_on_about_to_popup)
	popup_hide.connect(_on_hide)


func _notification(what: int) -> void:
	if what == NOTIFICATION_THEME_CHANGED:
		_tint()


## A plain item. Returns its id.
func item(label: String, action := Callable(), icon_name := "", shortcut_text := "") -> int:
	var id := item_count
	if icon_name != "":
		add_icon_item(_icon(icon_name), label, id)
	else:
		add_item(label, id)
	_setup(id, action, shortcut_text)
	return id


## A red one, for things you can't undo.
func danger(label: String, action := Callable(), icon_name := "", shortcut_text := "") -> int:
	var id := item(label, action, icon_name, shortcut_text)
	_danger[id] = true
	_tint()
	return id


## A tick box. `action` gets the new state. No icon: PopupMenu would tint the
## box with it.
func check(label: String, on: bool, action := Callable()) -> int:
	var id := item_count
	add_check_item(label, id)
	set_item_checked(get_item_index(id), on)
	_setup(id, action, "")
	return id


## One of a set. Items with the same `group` untick each other; `action` gets
## no arguments.
func radio(label: String, group: StringName, on: bool, action := Callable()) -> int:
	var id := item_count
	add_radio_check_item(label, id)
	set_item_checked(get_item_index(id), on)
	set_item_metadata(get_item_index(id), group)
	_setup(id, action, "")
	return id


## A line, or a labelled one.
func separator(label := "") -> void:
	add_separator(label)


## A nested WoldMenu. Fill the one it returns.
func submenu(label: String, icon_name := "") -> WoldMenu:
	var sub := WoldMenu.new()
	add_submenu_node_item(label, sub)
	if icon_name != "":
		set_item_icon(item_count - 1, _icon(icon_name))
		_tint()
	return sub


## Where the menu asks to go next to `anchor`. The popup adds its shadow round
## that and gets pushed back on screen if it won't fit.
func anchor_position(anchor: Control, placement := Placement.BOTTOM, align := Align.START) -> Vector2i:
	var r := Rect2(anchor.get_screen_position(), anchor.size)
	var s := Vector2(get_contents_minimum_size())
	var gap := float(WoldUIRuntime.instance().tokens.space_xs)
	var p := Vector2.ZERO
	match placement:
		Placement.BOTTOM:
			p.y = r.end.y + gap
		Placement.TOP:
			p.y = r.position.y - gap - s.y
		Placement.RIGHT:
			p.x = r.end.x + gap
		Placement.LEFT:
			p.x = r.position.x - gap - s.x
	var vertical := placement == Placement.BOTTOM or placement == Placement.TOP
	var along := r.position.x if vertical else r.position.y
	var length := r.size.x if vertical else r.size.y
	var own := s.x if vertical else s.y
	var offset := 0.0
	match align:
		Align.CENTER:
			offset = (length - own) / 2.0
		Align.END:
			offset = length - own
	if vertical:
		p.x = along + offset
	else:
		p.y = along + offset
	return Vector2i(p)


## Dropdown: open next to `anchor`.
func open_at(anchor: Control, placement := Placement.BOTTOM, align := Align.START) -> void:
	_remember_focus(anchor)
	reset_size()
	position = anchor_position(anchor, placement, align)
	popup()


## Context menu: open at the mouse.
func open_at_mouse() -> void:
	_remember_focus(null)
	reset_size()
	var vp := _host_viewport()
	position = Vector2i(vp.get_mouse_position()) if vp else Vector2i.ZERO
	popup()


func _setup(id: int, action: Callable, shortcut_text: String) -> void:
	if action.is_valid():
		_actions[id] = action
	if shortcut_text != "":
		# "Ctrl+S", "F2": shown on the right, and works while the menu is open
		var key := OS.find_keycode_from_string(shortcut_text)
		if key != KEY_NONE:
			set_item_accelerator(get_item_index(id), key)
	_tint()


func _icon(icon_name: String) -> Texture2D:
	return WoldUIRuntime.instance().tokens.icon(icon_name, "Sm")


# PopupMenu draws icons untinted: give them the text colour, danger ones red
func _tint() -> void:
	if WoldUIRuntime.instance().tokens.icon_tint != WoldTokens.IconTint.INHERIT:
		return
	var normal := get_theme_color(&"font_color")
	var red := get_theme_color(&"font_danger_color")
	for i in item_count:
		var id := get_item_id(i)
		# the modulate also hits check / radio marks, which carry their own colour
		if get_item_icon(i) == null:
			set_item_icon_modulate(i, Color.WHITE)
		else:
			set_item_icon_modulate(i, red if _danger.has(id) else normal)


func is_danger(id: int) -> bool:
	return _danger.has(id)


func _on_id(id: int) -> void:
	var index := get_item_index(id)
	if is_item_radio_checkable(index):
		var group = get_item_metadata(index)
		for i in item_count:
			if is_item_radio_checkable(i) and get_item_metadata(i) == group:
				set_item_checked(i, i == index)
		if _actions.has(id):
			_actions[id].call()
		return
	if is_item_checkable(index):
		set_item_checked(index, not is_item_checked(index))
		if _actions.has(id):
			_actions[id].call(is_item_checked(index))
		return
	if _actions.has(id):
		_actions[id].call()


# the viewport we sit in (a Window is a viewport itself, so ask the parent)
func _host_viewport() -> Viewport:
	var p := get_parent()
	return p.get_viewport() if p and p.is_inside_tree() else null


func _remember_focus(fallback: Control) -> void:
	var vp := _host_viewport()
	var focused: Control = vp.gui_get_focus_owner() if vp else null
	_return_focus = focused if focused else fallback


func _on_about_to_popup() -> void:
	_tint()
	WoldUIRuntime.instance().play("open")


func _on_hide() -> void:
	if is_instance_valid(_return_focus) and _return_focus.is_visible_in_tree() and _return_focus.focus_mode != Control.FOCUS_NONE:
		_return_focus.grab_focus(not WoldUIRuntime.instance().is_focus_navigating())
