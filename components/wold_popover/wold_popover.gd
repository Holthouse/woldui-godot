@tool
class_name WoldPopover
extends Control
## A panel that floats next to the Control it's under: a unit's details, a
## filter form, a colour pick. Put your nodes in %Content.
## trigger CLICK opens it from the anchor (a button's press or a click),
## HOVER is a hover card (also opens when the anchor gets keyboard / pad
## focus), MANUAL leaves it to open() / close().
## Esc, a click outside, or focus leaving closes it; focus goes back to the
## anchor.
# While open the panel is moved to a CanvasLayer so it draws and takes input
# above everything else, then moved back under this node when it closes.

signal opened
signal closed

enum Trigger { CLICK, HOVER, MANUAL }
enum Placement { BOTTOM, TOP, RIGHT, LEFT }
enum Align { START, CENTER, END }

const LAYER := 105

@export var title := "":
	set(v):
		title = v
		_refresh()
@export_multiline var description := "":
	set(v):
		description = v
		_refresh()
@export var trigger: Trigger = Trigger.CLICK:
	set(v):
		trigger = v
		_hook()
@export var placement: Placement = Placement.BOTTOM
@export var align: Align = Align.CENTER
## Hover cards: seconds before it opens. -1 = the tokens' tooltip_delay.
@export var delay := -1.0

var is_open := false
var _anchor: Control
var _panel: PanelContainer
# held directly: %names stop resolving while the panel lives in the layer
var _title: Label
var _description: Label
var _wait: SceneTreeTimer
var _over_anchor := false
var _over_panel := false
var _refreshing := false


func _ready() -> void:
	_panel = %Panel
	_title = %Title
	_description = %Description
	mouse_filter = MOUSE_FILTER_IGNORE
	_refresh()
	if Engine.is_editor_hint():
		return
	_panel.visible = false
	# wrapped text settles a frame late; follow the real size
	_panel.minimum_size_changed.connect(place)
	_panel.mouse_entered.connect(func(): _over_panel = true)
	_panel.mouse_exited.connect(func():
		_over_panel = false
		_on_leave())
	_hook()


func _exit_tree() -> void:
	if is_open:
		_put_back()


## Subclass hook, before each restyle.
func _wold_refresh() -> void:
	pass


## Where your nodes go. Use this rather than %Content while it's open.
func content() -> VBoxContainer:
	return _panel.get_node("Body/Content") as VBoxContainer if _panel else null


func anchor() -> Control:
	return get_parent() as Control


func panel() -> PanelContainer:
	return _panel


func toggle() -> void:
	if is_open:
		close()
	else:
		open()


func open() -> void:
	var a := anchor()
	if is_open or a == null or not is_inside_tree():
		return
	is_open = true
	var layer := _layer()
	_panel.reparent(layer, false)
	# out in the layer it would lose the theme it sat under (a WoldScope, a
	# local theme); borrow the nearest one above the anchor
	_panel.theme = _nearest_theme(a)
	_panel.visible = true
	_panel.reset_size()
	place()
	WoldMotion.appear(_panel, WoldMotion.preset("tooltip_in"))
	var vp := get_viewport()
	if not vp.gui_focus_changed.is_connected(_on_focus_changed):
		vp.gui_focus_changed.connect(_on_focus_changed)
	# pad / keyboard players land inside; mouse players keep their focus
	if WoldUIRuntime.instance().is_focus_navigating() and trigger != Trigger.HOVER:
		var first := _first_focusable(_panel)
		if first:
			first.grab_focus()
	opened.emit()


func close() -> void:
	if not is_open:
		return
	is_open = false
	var vp := get_viewport()
	if vp and vp.gui_focus_changed.is_connected(_on_focus_changed):
		vp.gui_focus_changed.disconnect(_on_focus_changed)
	var focused: Control = vp.gui_get_focus_owner() if vp else null
	var a := anchor()
	if focused and _panel.is_ancestor_of(focused) and a and a.focus_mode != FOCUS_NONE:
		a.grab_focus(not WoldUIRuntime.instance().is_focus_navigating())
	var tw := WoldMotion.disappear(_panel, WoldMotion.preset("disappear"))
	closed.emit()
	await tw.finished
	if not is_open:
		_put_back()


## Where the panel goes, in the layer's (viewport) space: next to the anchor
## on `placement`, flipped if there's no room, kept on screen.
func panel_rect() -> Rect2:
	var a := anchor()
	if a == null:
		return Rect2()
	var r := a.get_global_rect()
	var s := _panel.get_combined_minimum_size()
	var view := a.get_viewport_rect().size
	var gap := float(_panel.get_theme_constant(&"gap"))
	var chosen := placement
	match placement:
		Placement.BOTTOM:
			if r.end.y + gap + s.y > view.y and r.position.y - gap - s.y >= 0.0:
				chosen = Placement.TOP
		Placement.TOP:
			if r.position.y - gap - s.y < 0.0:
				chosen = Placement.BOTTOM
		Placement.RIGHT:
			if r.end.x + gap + s.x > view.x and r.position.x - gap - s.x >= 0.0:
				chosen = Placement.LEFT
		Placement.LEFT:
			if r.position.x - gap - s.x < 0.0:
				chosen = Placement.RIGHT
	var p := Vector2.ZERO
	var vertical := chosen == Placement.BOTTOM or chosen == Placement.TOP
	match chosen:
		Placement.BOTTOM:
			p.y = r.end.y + gap
		Placement.TOP:
			p.y = r.position.y - gap - s.y
		Placement.RIGHT:
			p.x = r.end.x + gap
		Placement.LEFT:
			p.x = r.position.x - gap - s.x
	var start := r.position.x if vertical else r.position.y
	var length := r.size.x if vertical else r.size.y
	var own := s.x if vertical else s.y
	var along := start
	match align:
		Align.CENTER:
			along = start + (length - own) / 2.0
		Align.END:
			along = start + length - own
	if vertical:
		p.x = along
	else:
		p.y = along
	var edge := gap
	p.x = clampf(p.x, edge, maxf(edge, view.x - s.x - edge))
	p.y = clampf(p.y, edge, maxf(edge, view.y - s.y - edge))
	return Rect2(p, s)


## Call again if the anchor moves while it's open.
func place() -> void:
	if is_open:
		var r := panel_rect()
		_panel.position = r.position
		_panel.size = r.size


func _refresh() -> void:
	if _refreshing or not is_node_ready():
		return
	_refreshing = true
	_wold_refresh()
	_title.text = title
	_title.visible = title != ""
	_description.text = description
	_description.visible = description != ""
	_refreshing = false


func _hook() -> void:
	if not is_node_ready() or Engine.is_editor_hint():
		return
	var a := anchor()
	if a == null:
		return
	if _anchor and _anchor != a:
		_unhook(_anchor)
	_anchor = a
	_unhook(a)
	match trigger:
		Trigger.CLICK:
			if a is BaseButton:
				a.pressed.connect(toggle)
			else:
				a.gui_input.connect(_on_anchor_input)
		Trigger.HOVER:
			# fingers can't hover, so on touch a tap toggles it instead
			if a is BaseButton:
				a.pressed.connect(_on_touch_tap)
			else:
				a.gui_input.connect(_on_touch_input)
			a.mouse_entered.connect(_on_hover)
			a.mouse_exited.connect(_on_anchor_exit)
			a.focus_entered.connect(_on_anchor_focus)
			a.focus_exited.connect(_on_anchor_blur)


func _unhook(a: Control) -> void:
	for pair in [[&"pressed", toggle], [&"gui_input", _on_anchor_input], [&"pressed", _on_touch_tap], [&"gui_input", _on_touch_input], [&"mouse_entered", _on_hover], [&"mouse_exited", _on_anchor_exit], [&"focus_entered", _on_anchor_focus], [&"focus_exited", _on_anchor_blur]]:
		if a.has_signal(pair[0]) and a.is_connected(pair[0], pair[1]):
			a.disconnect(pair[0], pair[1])


func _on_anchor_input(event: InputEvent) -> void:
	var mb := event as InputEventMouseButton
	if mb and mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
		toggle()


func _on_touch_tap() -> void:
	if WoldUIRuntime.instance().is_touch():
		toggle()


func _on_touch_input(event: InputEvent) -> void:
	var touch := event as InputEventScreenTouch
	if touch and touch.pressed and WoldUIRuntime.instance().is_touch():
		toggle()


func _on_hover() -> void:
	# on touch that's the pointer faked from a tap; _on_touch_tap handles it
	if WoldUIRuntime.instance().is_touch():
		return
	_over_anchor = true
	var wait := delay if delay >= 0.0 else WoldUIRuntime.instance().tokens.tooltip_delay
	var timer := get_tree().create_timer(wait)
	_wait = timer
	await timer.timeout
	if _wait == timer and _pointer_over():
		open()


# a little grace so moving from the anchor onto the card doesn't close it
func _on_leave() -> void:
	if trigger != Trigger.HOVER or WoldUIRuntime.instance().is_touch():
		return
	var a := anchor()
	if a and not a.get_global_rect().has_point(a.get_global_mouse_position()):
		_over_anchor = false
	_wait = null
	await get_tree().create_timer(0.15).timeout
	if is_open and not _pointer_over() and not _focus_inside():
		close()


func _on_anchor_exit() -> void:
	_over_anchor = false
	_on_leave()


func _on_anchor_focus() -> void:
	if WoldUIRuntime.instance().is_focus_navigating():
		open()


func _on_anchor_blur() -> void:
	await get_tree().process_frame
	if is_open and not _focus_inside() and not _pointer_over():
		close()


# enter / exit flags, backed by the rect: either alone misses cases (exit
# fires going onto a child; headless has no real mouse position)
func _pointer_over() -> bool:
	var a := anchor()
	var m := get_viewport().get_mouse_position()
	var on_anchor := _over_anchor or (a and a.get_global_rect().has_point(m))
	return on_anchor or (is_open and (_over_panel or _panel.get_global_rect().has_point(m)))


func _focus_inside() -> bool:
	var f := get_viewport().gui_get_focus_owner()
	return f != null and (_panel.is_ancestor_of(f) or f == _panel)


func _on_focus_changed(node: Control) -> void:
	if is_open and node and not _panel.is_ancestor_of(node) and node != anchor():
		close()


func _input(event: InputEvent) -> void:
	if not is_open:
		return
	var mb := event as InputEventMouseButton
	if mb and mb.pressed:
		var inside := _panel.get_global_rect().has_point(mb.position)
		var on_anchor := anchor() and anchor().get_global_rect().has_point(mb.position)
		# the anchor's own press toggles, so leave that click to it
		if not inside and not on_anchor:
			close()


func _unhandled_input(event: InputEvent) -> void:
	if is_open and event.is_action_pressed(&"ui_cancel"):
		get_viewport().set_input_as_handled()
		var a := anchor()
		close()
		if a and a.focus_mode != FOCUS_NONE:
			a.grab_focus(not WoldUIRuntime.instance().is_focus_navigating())


func _first_focusable(node: Node) -> Control:
	for child in node.get_children():
		if child is Control and child.is_visible_in_tree() and child.focus_mode == Control.FOCUS_ALL:
			return child
		var inner := _first_focusable(child)
		if inner:
			return inner
	return null


func _put_back() -> void:
	if not is_instance_valid(_panel):
		return
	_panel.visible = false
	_panel.theme = null
	if _panel.get_parent() != self:
		_panel.reparent(self, false)


func _nearest_theme(from: Node) -> Theme:
	var n := from
	while n:
		if n is Control and n.theme:
			return n.theme
		n = n.get_parent()
	return null


func _layer() -> CanvasLayer:
	var root := get_tree().root
	var layer := root.get_node_or_null("WoldPopovers") as CanvasLayer
	if layer == null:
		layer = CanvasLayer.new()
		layer.name = "WoldPopovers"
		layer.layer = LAYER
		root.add_child(layer)
	return layer
