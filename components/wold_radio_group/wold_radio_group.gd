@tool
class_name WoldRadioGroup
extends VBoxContainer
## Pick one of a few options. Each option is a WoldCheckbox in a shared
## ButtonGroup, so it draws as a radio. Arrow keys / d-pad move the pick
## along the group; past either end focus leaves the group as normal.

signal selected_changed(index: int)

## Caption above the options. Empty = none.
@export var legend := "":
	set(v):
		legend = v
		_refresh()
@export var options: PackedStringArray = ["Option"]:
	set(v):
		options = v
		_rebuild()
## Muted line per option, same order. Missing or empty = none.
@export var descriptions: PackedStringArray = []:
	set(v):
		descriptions = v
		_rebuild()
## -1 = nothing picked.
@export var selected := -1:
	set(v):
		v = clampi(v, -1, options.size() - 1)
		var changed := v != selected
		selected = v
		_apply()
		if changed and is_node_ready():
			selected_changed.emit(selected)
@export var horizontal := false:
	set(v):
		horizontal = v
		_refresh()
@export var disabled := false:
	set(v):
		disabled = v
		_refresh()

const ITEM := preload("../wold_checkbox/wold_checkbox.tscn")

var _group := ButtonGroup.new()
var _refreshing := false


func _ready() -> void:
	_rebuild()


## Subclass hook, before each restyle.
func _wold_refresh() -> void:
	pass


func item(index: int) -> WoldCheckbox:
	return %Items.get_child(index) as WoldCheckbox


func item_count() -> int:
	return %Items.get_child_count()


# the options live as unowned children of %Items, so they're never saved
func _rebuild() -> void:
	if not is_node_ready():
		return
	var items := %Items as Node
	for child in items.get_children():
		items.remove_child(child)
		child.queue_free()
	for i in options.size():
		var c: WoldCheckbox = ITEM.instantiate()
		c.label = options[i]
		c.description = descriptions[i] if i < descriptions.size() else ""
		c.button_group = _group
		c.toggled.connect(func(on: bool):
			if on and selected != i:
				selected = i)
		c.gui_input.connect(_on_item_input.bind(i))
		items.add_child(c)
	selected = selected
	_refresh()


func _refresh() -> void:
	if _refreshing or not is_node_ready():
		return
	_refreshing = true
	_wold_refresh()
	(%Legend as Label).text = legend
	%Legend.visible = legend != ""
	(%Items as BoxContainer).vertical = not horizontal
	(%Items as BoxContainer).theme_type_variation = &"RowLg" if horizontal else &"StackXs"
	for i in item_count():
		item(i).disabled = disabled
	_refreshing = false
	_apply()


func _apply() -> void:
	if not is_node_ready():
		return
	for i in item_count():
		item(i).set_pressed_no_signal(i == selected)
		item(i).queue_redraw()


func _on_item_input(event: InputEvent, index: int) -> void:
	var back := &"ui_left" if horizontal else &"ui_up"
	var next := &"ui_right" if horizontal else &"ui_down"
	var step := 0
	if event.is_action_pressed(back, true):
		step = -1
	elif event.is_action_pressed(next, true):
		step = 1
	var to := index + step
	if step == 0 or to < 0 or to >= item_count():
		return
	get_viewport().set_input_as_handled()
	selected = to
	item(to).grab_focus()
