@tool
class_name WoldCard
extends PanelContainer
## A surface with a header (icon, title, description, %Action slot), a
## %Content slot and a %Footer slot. Empty parts take no room.
## `selectable` turns it into a choice (upgrade picks, factions): it takes
## focus, lights up on hover, and accept / click emits `pressed`. Cards that
## share a `card_group` select one at a time.

signal pressed

enum Size { SM, MD }

@export var title := "Card title":
	set(v):
		title = v
		_refresh()
@export_multiline var description := "":
	set(v):
		description = v
		_refresh()
## Header icon by name.
@export var icon := "":
	set(v):
		icon = v
		_refresh()
## Not `size`, Control has one.
@export var card_size: Size = Size.MD:
	set(v):
		card_size = v
		_refresh()
@export_group("Choice")
@export var selectable := false:
	set(v):
		selectable = v
		focus_mode = FOCUS_ALL if v else FOCUS_NONE
		mouse_default_cursor_shape = CURSOR_POINTING_HAND if v else CURSOR_ARROW
		queue_redraw()
@export var selected := false:
	set(v):
		selected = v
		if v and card_group != &"" and is_inside_tree():
			for other in get_tree().get_nodes_in_group(_group_name()):
				if other != self and other.selected:
					other.selected = false
		_sel_tween = WoldMotion.blend(_sel_tween, self, _sel, 1.0 if v else 0.0, func(a: float):
			_sel = a
			queue_redraw())
## Cards with the same group select one at a time. Empty = independent.
@export var card_group: StringName = &"":
	set(v):
		if is_inside_tree() and card_group != &"":
			remove_from_group(_group_name())
		card_group = v
		if is_inside_tree() and v != &"":
			add_to_group(_group_name())

# eased 0..1 amounts for hover, selected and the focus ring
var _hot := 0.0
var _sel := 0.0
var _ring := 0.0
var _hot_tween: Tween
var _sel_tween: Tween
var _ring_tween: Tween
var _refreshing := false


func _ready() -> void:
	mouse_entered.connect(_ease_hot.bind(true))
	mouse_exited.connect(_ease_hot.bind(false))
	_sel = 1.0 if selected else 0.0
	for slot in [%Action, %Content, %Footer]:
		slot.child_entered_tree.connect(func(_n): _refresh.call_deferred())
		slot.child_exiting_tree.connect(func(_n): _refresh.call_deferred())
	_refresh()


func _enter_tree() -> void:
	if card_group != &"":
		add_to_group(_group_name())


## Subclass hook, before each restyle.
func _wold_refresh() -> void:
	pass


func _group_name() -> StringName:
	return StringName("_wold_card_" + card_group)


func _gui_input(event: InputEvent) -> void:
	if not selectable:
		return
	var mb := event as InputEventMouseButton
	var click := mb and mb.button_index == MOUSE_BUTTON_LEFT and not mb.pressed and get_global_rect().has_point(mb.global_position)
	if click or event.is_action_pressed(&"ui_accept"):
		accept_event()
		activate()


## What a click or accept does: select (if in a group) and emit `pressed`.
func activate() -> void:
	if card_group != &"":
		selected = true
	WoldUIRuntime.instance().play("click")
	if is_inside_tree() and not Engine.is_editor_hint():
		WoldMotion.press(self)
	pressed.emit()


func _refresh() -> void:
	if _refreshing or not is_node_ready():
		return
	_refreshing = true
	_wold_refresh()
	var sm := card_size == Size.SM
	var suffix := "Sm" if sm else ""
	theme_type_variation = StringName("Card" + suffix)
	var t := WoldUIRuntime.instance().tokens
	(%Title as Label).text = title
	(%Title as Label).theme_type_variation = StringName("CardTitle" + suffix)
	%Title.visible = title != ""
	(%Description as Label).text = description
	%Description.visible = description != ""
	var lead := %Icon as TextureRect
	lead.texture = t.icon(icon, "" if sm else "Lg") if icon != "" else null
	lead.visible = icon != ""
	var px := t.icon_size_md if sm else t.icon_size_lg
	lead.custom_minimum_size = Vector2(px, px)
	lead.self_modulate = (%Title as Label).get_theme_color("font_color")
	var has_header := title != "" or description != "" or icon != "" or %Action.get_child_count() > 0
	%Header.visible = has_header
	%ContentBox.visible = %Content.get_child_count() > 0
	%FooterBox.visible = %Footer.get_child_count() > 0
	# only the first section shown pads its top
	var first := true
	for section in [%Header, %ContentBox, %FooterBox]:
		var style := "CardSection" if first else "CardSectionNext"
		section.theme_type_variation = StringName(style + suffix)
		if section.visible:
			first = false
	_refreshing = false


func _ease_hot(on: bool) -> void:
	_hot_tween = WoldMotion.blend(_hot_tween, self, _hot, 1.0 if on else 0.0, func(a: float):
		_hot = a
		queue_redraw())


func _draw() -> void:
	var r := Rect2(Vector2.ZERO, size)
	if selectable and _hot > 0.0:
		draw_style_box(WoldStyle.faded(get_theme_stylebox(&"hover"), _hot), r)
	if _sel > 0.0:
		draw_style_box(WoldStyle.faded(get_theme_stylebox(&"selected"), _sel), r)
	if has_focus() and WoldUIRuntime.instance().is_focus_navigating():
		draw_style_box(WoldStyle.faded(get_theme_stylebox(&"focus"), _ring), r)


func _notification(what: int) -> void:
	if what == NOTIFICATION_FOCUS_ENTER:
		# the ring fades in; on the way out it just goes
		_ring_tween = WoldMotion.blend(_ring_tween, self, 0.0, 1.0, func(a: float):
			_ring = a
			queue_redraw())
	elif what == NOTIFICATION_FOCUS_EXIT:
		queue_redraw()


func _validate_property(property: Dictionary) -> void:
	if property.name in ["theme_type_variation", "focus_mode", "mouse_default_cursor_shape"]:
		property.usage &= ~PROPERTY_USAGE_STORAGE
