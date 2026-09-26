@tool
class_name WoldField
extends VBoxContainer
## Label, a control, a hint under it and an error line: the wrapper for a form
## row. Put your LineEdit / TextEdit / WoldSelect / anything in the %Control
## slot (Editable Children, or `field.get_node("%Control").add_child(x)`).
## A click on the label focuses the control. Setting `error` shows the line
## and gives a LineEdit or TextEdit its invalid border.

@export var label := "Label":
	set(v):
		label = v
		_refresh()
@export_multiline var description := "":
	set(v):
		description = v
		_refresh()
## Empty = no error.
@export_multiline var error := "":
	set(v):
		var appearing := error == "" and v != ""
		error = v
		_refresh()
		if appearing and is_inside_tree() and not Engine.is_editor_hint():
			WoldMotion.appear(%Error)
## Shows "n / max" and caps a LineEdit. 0 = no counter.
@export_range(0, 10000) var max_length := 0:
	set(v):
		max_length = v
		_bind()

const _BASE := &"_wold_field_base"
const SCENE := "res://addons/woldui/components/wold_field/wold_field.tscn"

var _bound: Control
var _refreshing := false


func _ready() -> void:
	%Control.child_entered_tree.connect(func(_n): _bind.call_deferred())
	%Control.child_exiting_tree.connect(func(_n): _bind.call_deferred())
	%Label.gui_input.connect(_on_label_input)
	_bind()


## Subclass hook, before each restyle.
func _wold_refresh() -> void:
	pass


## For UIs built in code: a field with `c` already in the slot.
static func make(c: Control, label_text: String, description_text := "") -> WoldField:
	var f: WoldField = load(SCENE).instantiate()
	f.label = label_text
	f.description = description_text
	f.get_node("%Control").add_child(c)
	return f


## The control in the slot, or null.
func control() -> Control:
	if not is_node_ready():
		return null
	for child in %Control.get_children():
		if child is Control and not child.is_queued_for_deletion():
			return child
	return null


func is_invalid() -> bool:
	return error != ""


## Characters in the control (LineEdit / TextEdit), -1 for anything else.
func length() -> int:
	var c := control()
	if c is LineEdit or c is TextEdit:
		return c.text.length()
	return -1


func _bind() -> void:
	if not is_node_ready():
		return
	var c := control()
	if c != _bound:
		if is_instance_valid(_bound) and _bound.has_signal(&"text_changed") and _bound.text_changed.is_connected(_on_text):
			_bound.text_changed.disconnect(_on_text)
		_bound = c
		if c and c.has_signal(&"text_changed"):
			c.text_changed.connect(_on_text)
	if c is LineEdit and max_length > 0:
		(c as LineEdit).max_length = max_length
	_refresh()


func _on_text(_t = null) -> void:
	_refresh()


func _refresh() -> void:
	if _refreshing or not is_node_ready():
		return
	_refreshing = true
	_wold_refresh()
	var t := WoldUIRuntime.instance().tokens
	(%Label as Label).text = label
	%Label.visible = label != ""
	(%Description as Label).text = description
	%Description.visible = description != ""
	(%ErrorText as Label).text = error
	%Error.visible = error != ""
	var icon := %ErrorIcon as TextureRect
	icon.texture = t.icon("circle-alert", "Sm")
	icon.custom_minimum_size = Vector2(t.icon_size_sm, t.icon_size_sm)
	# from the theme, not the tokens: a WoldScope or a second theme may differ
	icon.self_modulate = (%ErrorText as Label).get_theme_color("font_color")
	var n := length()
	var counter := %Counter as Label
	counter.visible = max_length > 0 and n >= 0
	counter.text = "%d / %d" % [n, max_length]
	counter.theme_type_variation = &"FieldCounterOver" if n > max_length else &"FieldCounter"
	var c := control()
	if c:
		_mark_invalid(c)
		# what a screen reader says for the control, like <label for> on the web
		if not Engine.is_editor_hint() and (c.accessibility_name == "" or c.has_meta(&"_wold_field_named")):
			c.accessibility_name = label
			c.set_meta(&"_wold_field_named", true)
			c.accessibility_description = error if error != "" else description
	_refreshing = false


# swap to X + "Invalid" and back. Not in the editor, it'd get saved.
func _mark_invalid(c: Control) -> void:
	if Engine.is_editor_hint() or not (c is LineEdit or c is TextEdit):
		return
	if not c.has_meta(_BASE):
		var base := c.theme_type_variation
		if base == &"":
			base = &"TextEdit" if c is TextEdit else &"LineEdit"
		c.set_meta(_BASE, base)
	var base: StringName = c.get_meta(_BASE)
	var bad := StringName(base + "Invalid")
	if error != "" and c.has_theme_stylebox(&"normal", bad):
		c.theme_type_variation = bad
	else:
		c.theme_type_variation = &"" if base == &"LineEdit" or base == &"TextEdit" else base


func _on_label_input(event: InputEvent) -> void:
	var mb := event as InputEventMouseButton
	if mb and mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
		var c := control()
		if c and c.focus_mode != FOCUS_NONE:
			c.grab_focus(true)
