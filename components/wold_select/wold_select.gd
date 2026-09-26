@tool
class_name WoldSelect
extends Button
## Pick one option from a list that drops down. Looks like a field; the open
## list checks the current option. Keyboard and pad: accept opens it, the list
## takes up / down / accept / cancel, and focus comes back here when it closes.
# Not an OptionButton: its items would end up saved in the scene, and it
# can't show a placeholder.

signal item_selected(index: int)

enum Size { SM, MD, LG }

const Content := preload("../shared/wold_button_content.gd")
const _SUFFIX := ["Sm", "", "Lg"]

@export var options: PackedStringArray = ["Option"]:
	set(v):
		options = v
		selected = selected
		_refresh()
## Icon names, same order as `options`.
@export var icons: PackedStringArray = []:
	set(v):
		icons = v
		_refresh()
## -1 = nothing yet, the placeholder shows.
@export var selected := -1:
	set(v):
		selected = clampi(v, -1, options.size() - 1)
		_refresh()
@export var placeholder := "Choose...":
	set(v):
		placeholder = v
		_refresh()
## Not `size`, Control has one.
@export var select_size: Size = Size.MD:
	set(v):
		select_size = v
		_refresh()
@export_range(0, 800) var min_width := 0:
	set(v):
		min_width = v
		_fit()

var _menu := PopupMenu.new()
var _refreshing := false


func _ready() -> void:
	if _menu.get_parent() == null:
		_menu.theme_type_variation = &"SelectPopup"
		# else it shrinks to the longest option instead of matching the field
		_menu.shrink_width = false
		add_child(_menu, false, Node.INTERNAL_MODE_FRONT)
		_menu.index_pressed.connect(_on_picked)
		_menu.popup_hide.connect(_on_closed)
	if not pressed.is_connected(open):
		pressed.connect(open)
	text = ""
	%Content.minimum_size_changed.connect(_fit)
	_refresh()


func _notification(what: int) -> void:
	if what == NOTIFICATION_THEME_CHANGED:
		_fit.call_deferred()


## Subclass hook, before each restyle.
func _wold_refresh() -> void:
	pass


## The option text, or "" when nothing is picked.
func value() -> String:
	return options[selected] if selected >= 0 else ""


func is_open() -> bool:
	return _menu.visible


## The dropdown list, if you need to poke at it.
func menu() -> PopupMenu:
	return _menu


func open() -> void:
	if disabled or options.is_empty():
		return
	_menu.clear()
	var t := WoldUIRuntime.instance().tokens
	for i in options.size():
		if i < icons.size() and icons[i] != "":
			_menu.add_icon_radio_check_item(t.icon(icons[i], "Sm"), options[i])
		else:
			_menu.add_radio_check_item(options[i])
		# PopupMenu draws icons untinted (white, gone on a light theme). The
		# modulate also hits the check mark, which is white for this reason
		if t.icon_tint == WoldTokens.IconTint.INHERIT or i >= icons.size() or icons[i] == "":
			_menu.set_item_icon_modulate(i, _menu.get_theme_color("font_color"))
		_menu.set_item_checked(i, i == selected)
	var r := dropdown_rect()
	# same dance as OptionButton: place and size first, then popup() keeps them
	_menu.position = r.position
	_menu.size = r.size
	_menu.popup()
	_menu.set_focused_item(maxi(selected, 0))
	queue_redraw()


## Where the list asks to go: under the field, as wide as it. The popup adds
## its shadow around that, and gets pushed back on screen if it won't fit.
func dropdown_rect() -> Rect2i:
	var gap := WoldUIRuntime.instance().tokens.space_xs
	var at := get_screen_position() + Vector2(0, size.y + gap)
	return Rect2i(Vector2i(at), Vector2i(int(size.x), 0))


func close() -> void:
	_menu.hide()


func _on_picked(index: int) -> void:
	var changed := index != selected
	selected = index
	if changed:
		item_selected.emit(index)


func _on_closed() -> void:
	if is_inside_tree() and focus_mode != FOCUS_NONE:
		grab_focus(not WoldUIRuntime.instance().is_focus_navigating())
	_refresh()


func _refresh() -> void:
	if _refreshing or not is_node_ready():
		return
	_refreshing = true
	_wold_refresh()
	var t := WoldUIRuntime.instance().tokens
	var suffix: String = _SUFFIX[select_size]
	theme_type_variation = StringName("Select" + suffix)
	var picked := selected >= 0
	var value_label := %Value as Label
	value_label.text = options[selected] if picked else placeholder
	value_label.theme_type_variation = StringName(("SelectValue" if picked and not disabled else "SelectPlaceholder") + suffix)
	var px := get_theme_constant("icon_size")
	var lead := %Icon as TextureRect
	var icon_name: String = icons[selected] if picked and selected < icons.size() else ""
	lead.texture = t.icon(icon_name, suffix) if icon_name != "" else null
	lead.visible = lead.texture != null
	lead.custom_minimum_size = Vector2(px, px)
	var chevron := %Chevron as TextureRect
	chevron.texture = t.icon("chevron-up" if is_open() else "chevron-down", suffix)
	chevron.custom_minimum_size = Vector2(px, px)
	var tint := get_theme_color("icon_disabled_color" if disabled else "icon_color")
	chevron.self_modulate = tint
	lead.self_modulate = tint
	_refreshing = false
	_fit()


func _fit() -> void:
	if not is_node_ready():
		return
	# wide enough for the longest option, so picking one doesn't resize the field
	var value_label := %Value as Label
	var font := value_label.get_theme_font("font")
	var px := value_label.get_theme_font_size("font_size")
	var widest := 0.0
	for s in Array(options) + [placeholder]:
		widest = maxf(widest, font.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, px).x)
	value_label.custom_minimum_size.x = ceilf(widest)
	Content.fit(self, %Content)
	custom_minimum_size.x = maxf(custom_minimum_size.x, min_width)


func _draw() -> void:
	# no signal for disabled, but it redraws
	var suffix: String = _SUFFIX[select_size]
	var want := StringName(("SelectValue" if selected >= 0 and not disabled else "SelectPlaceholder") + suffix)
	if (%Value as Label).theme_type_variation != want:
		_refresh.call_deferred()


func _validate_property(property: Dictionary) -> void:
	if property.name in ["custom_minimum_size", "theme_type_variation", "text"]:
		property.usage &= ~PROPERTY_USAGE_STORAGE
