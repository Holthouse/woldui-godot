@tool
class_name WoldSegmented
extends PanelContainer
## A row of joined toggle buttons: pick one (a raised thumb slides to it) or,
## with `multiple`, any number. Good for filters and view modes, where radios
## would take too much room.

signal selected_changed(index: int)
## Only with `multiple`.
signal item_toggled(index: int, on: bool)

enum Size { SM, MD }

const Thumb := preload("../shared/wold_thumb.gd")

@export var options: PackedStringArray = ["Day", "Week", "Month"]:
	set(v):
		options = v
		_rebuild()
## Icon names, same order as `options`. An option with an icon and no text is
## icon-only, give it a tooltip.
@export var icons: PackedStringArray = []:
	set(v):
		icons = v
		_rebuild()
## Single pick. -1 = nothing.
@export var selected := 0:
	set(v):
		v = clampi(v, -1, options.size() - 1)
		var changed := v != selected
		selected = v
		_apply(changed)
		if changed and is_node_ready() and not multiple:
			selected_changed.emit(selected)
@export var multiple := false:
	set(v):
		multiple = v
		_rebuild()
## Not `size`, Control has one.
@export var segment_size: Size = Size.MD:
	set(v):
		segment_size = v
		_rebuild()
## Segments share the width (or the height, when vertical) equally.
@export var stretch := false:
	set(v):
		stretch = v
		_rebuild()
## Stacked top to bottom; the thumb slides up and down.
@export var vertical := false:
	set(v):
		vertical = v
		_rebuild()
## A bordered track with no fill, like the web toggle group's outline look.
@export var outline := false:
	set(v):
		outline = v
		_rebuild()

var _refreshing := false
var _anim := Node.new()
var _thumb := Thumb.new(self, _anim)


func _ready() -> void:
	if _anim.get_parent() == null:
		add_child(_anim, false, Node.INTERNAL_MODE_FRONT)
	# deferred: sort_children fires before the buttons move
	%Buttons.sort_children.connect(_apply.bind(false), CONNECT_DEFERRED)
	_rebuild()


## Subclass hook, before the segments are rebuilt.
func _wold_refresh() -> void:
	pass


func item(index: int) -> Button:
	return %Buttons.get_child(index) as Button


func item_count() -> int:
	return %Buttons.get_child_count()


## Picked indices. With `multiple` off it's just `selected`.
func pressed_items() -> PackedInt32Array:
	var out := PackedInt32Array()
	for i in item_count():
		if item(i).button_pressed:
			out.append(i)
	return out


## Where the thumb is drawn right now, in our own space.
func thumb_rect() -> Rect2:
	return _thumb.rect()


func _rebuild() -> void:
	if _refreshing or not is_node_ready():
		return
	_refreshing = true
	_wold_refresh()
	var sm := segment_size == Size.SM
	theme_type_variation = StringName("Segmented" + ("Outline" if outline else "") + ("Sm" if sm else ""))
	(%Buttons as BoxContainer).vertical = vertical
	var style := &"SegmentedButtonSm" if sm else &"SegmentedButton"
	var group: ButtonGroup = null if multiple else ButtonGroup.new()
	var box := %Buttons as Node
	for child in box.get_children():
		box.remove_child(child)
		child.queue_free()
	var t := WoldUIRuntime.instance().tokens
	for i in options.size():
		var b := Button.new()
		b.theme_type_variation = style
		b.toggle_mode = true
		b.button_group = group
		b.text = options[i]
		if i < icons.size() and icons[i] != "":
			b.icon = t.icon(icons[i], "Sm" if sm else "")
		if b.text == "" and b.icon:
			b.tooltip_text = icons[i]
		if vertical:
			b.size_flags_vertical = Control.SIZE_EXPAND_FILL if stretch else Control.SIZE_FILL
		else:
			b.size_flags_horizontal = Control.SIZE_EXPAND_FILL if stretch else Control.SIZE_FILL
		b.alignment = HORIZONTAL_ALIGNMENT_CENTER
		b.toggled.connect(_on_toggled.bind(i))
		box.add_child(b)
	_refreshing = false
	_apply(false)


func _on_toggled(on: bool, index: int) -> void:
	if multiple:
		item_toggled.emit(index, on)
		queue_redraw()
	elif on:
		selected = index


func _apply(animate: bool) -> void:
	if not is_node_ready() or _refreshing:
		return
	if not multiple:
		for i in item_count():
			item(i).set_pressed_no_signal(i == selected)
	var target := _item_rect(selected) if selected >= 0 and selected < item_count() else Rect2()
	_thumb.move(target, animate)


func _item_rect(index: int) -> Rect2:
	var b := item(index)
	return Rect2(%Buttons.position + b.position, b.size)


func _draw() -> void:
	var sb := get_theme_stylebox(&"panel", &"SegmentedThumb")
	if multiple:
		for i in pressed_items():
			draw_style_box(sb, _item_rect(i))
	elif selected >= 0 and _thumb.is_placed():
		draw_style_box(sb, thumb_rect())


func _validate_property(property: Dictionary) -> void:
	if property.name == "theme_type_variation":
		property.usage &= ~PROPERTY_USAGE_STORAGE
