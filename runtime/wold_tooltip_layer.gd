class_name WoldTooltipLayer
extends CanvasLayer
## Draws every plain tooltip_text tooltip itself, as a Control that ignores
## the mouse, instead of the engine's tooltip window.
##
## Why: the engine's tooltip is a popup window, and a click that lands while
## one is up gets eaten by it, so a button with a tooltip needs two clicks.
## Turn the engine's off in Project Settings (gui/timers/tooltip_delay_sec,
## something huge like 100000). It's read when the tooltip is made, so setting
## it from code at runtime does nothing.
##
## The runtime puts one on the root when tokens.tooltip_layer is on. It reads
## Control.get_tooltip() of the hovered control or its nearest parent that has
## one, so tooltip_text and a script's own _get_tooltip() both work. Text wraps
## at tokens.tooltip_max_width. The tip sits centred under the control the
## text belongs to, or above it if there's no room. Over text and lists
## (RichTextLabel, ItemList, Tree, TextEdit) or anything very tall it goes
## under the cursor instead: there the tip is about the bit you pointed at.

const NAME := "WoldTooltipLayer"
const LAYER := 110
# a control taller than this is anchored at the cursor
const TALL := 120.0
# room left for the pointer when anchored at the cursor
const CURSOR_HEIGHT := 22.0

var _panel: PanelContainer
var _label: Label
var _hovered: Control
# what the tip is anchored to right now; null + _floating = the cursor
var _anchor: Control
var _text := ""
var _waited := 0.0
var _suppressed: Control
var _floating := ""
# last pointer position seen, in this viewport's coordinates
var _mouse := Vector2.INF


## Adds one to the root, unless there is one already or it's headless.
static func install(tree: SceneTree, force := false) -> WoldTooltipLayer:
	if tree == null:
		return null
	var have := tree.root.get_node_or_null(NAME) as WoldTooltipLayer
	if have or (DisplayServer.get_name() == "headless" and not force):
		return have
	var tips := WoldTooltipLayer.new()
	tips.name = NAME
	tree.root.add_child.call_deferred(tips)
	return tips


## The one on the root, or null.
static func current() -> WoldTooltipLayer:
	var loop := Engine.get_main_loop() as SceneTree
	if loop == null or loop.root == null:
		return null
	return loop.root.get_node_or_null(NAME) as WoldTooltipLayer


## The text the engine would show for this control: its own tooltip, else
## the nearest parent's.
static func tooltip_for(control: Control) -> String:
	var owner := owner_of(control)
	return owner.get_tooltip(owner.get_local_mouse_position()) if owner else ""


## The control a tooltip comes from: this one if it has one, else the nearest
## parent that does. That's what the tip is placed under.
static func owner_of(control: Control) -> Control:
	var node: Node = control
	while node is Control:
		var c := node as Control
		if c.get_tooltip(c.get_local_mouse_position()) != "":
			return c
		node = node.get_parent()
	return null


## Whether a tip for this control goes under the cursor rather than under the
## control: text and lists, where it's about one part, and very tall things.
static func follows_cursor(control: Control) -> bool:
	return control is RichTextLabel or control is ItemList or control is Tree 			or control is TextEdit or control.size.y > TALL


func _ready() -> void:
	layer = LAYER
	process_mode = Node.PROCESS_MODE_ALWAYS
	_panel = PanelContainer.new()
	_panel.theme_type_variation = &"TooltipPanel"
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.visible = false
	_label = Label.new()
	_label.theme_type_variation = &"TooltipLabel"
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.add_child(_label)
	add_child(_panel)


func _input(event: InputEvent) -> void:
	if event is InputEventMouse:
		_mouse = (event as InputEventMouse).position
	# a press hides it until the pointer leaves that control
	if event is InputEventMouseButton and event.pressed:
		_suppressed = _hovered
		hide_tip()


## For things that aren't Controls (a unit on the map): shown at the cursor,
## following it, until called again with "".
func show_floating(text: String) -> void:
	_floating = text
	if text == "":
		hide_tip()


## Shows a control's tooltip now, skipping the delay. Handy for keyboard and
## pad focus.
func show_for(control: Control) -> void:
	var owner := owner_of(control)
	if owner == null:
		hide_tip()
		return
	_present(tooltip_for(owner), owner)


func is_showing() -> bool:
	return _panel != null and _panel.visible


func hide_tip() -> void:
	_text = ""
	_anchor = null
	if _panel != null:
		_panel.visible = false


## The panel, for tests and for anyone restyling it.
func panel() -> PanelContainer:
	return _panel


func _process(delta: float) -> void:
	# follow a control that slides, or the cursor
	place()
	if _floating != "":
		_present(_floating, null)
		return
	var control := get_viewport().gui_get_hovered_control()
	if control != _hovered:
		_hovered = control
		_waited = 0.0
		hide_tip()
		if control != _suppressed:
			_suppressed = null
	if _hovered == null or _hovered == _suppressed or not is_instance_valid(_hovered):
		return
	var owner := owner_of(_hovered)
	if owner == null:
		hide_tip()
		return
	_waited += delta
	if _waited < WoldUIRuntime.instance().tokens.tooltip_delay:
		return
	_present(tooltip_for(owner), owner)


func _present(text: String, anchor: Control) -> void:
	var appearing := not _panel.visible
	if text != _text:
		_text = text
		_wrap(text)
	_anchor = anchor
	_panel.visible = true
	place()
	if appearing:
		WoldMotion.appear(_panel, WoldMotion.preset("tooltip_in"))


# one line if it fits, wrapped at the token width if it doesn't
func _wrap(text: String) -> void:
	var cap := float(WoldUIRuntime.instance().tokens.tooltip_max_width)
	_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	_label.custom_minimum_size.x = 0.0
	_label.text = text
	if _label.get_minimum_size().x > cap:
		_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_label.custom_minimum_size.x = cap
	_panel.reset_size()


## Puts the panel under its anchor (or above, if it doesn't fit), kept on
## screen. Runs again every frame it's up, so a moving control is followed.
func place() -> void:
	if not is_showing():
		return
	_panel.reset_size()
	var view := get_viewport().get_visible_rect().size
	var s := _panel.size
	var gap := float(WoldUIRuntime.instance().tokens.space_sm)
	var r := _anchor_rect()
	var p := Vector2(r.get_center().x - s.x / 2.0, r.end.y + gap)
	if p.y + s.y > view.y - gap:
		p.y = r.position.y - gap - s.y
	p.x = clampf(p.x, gap, maxf(gap, view.x - s.x - gap))
	p.y = clampf(p.y, gap, maxf(gap, view.y - s.y - gap))
	_panel.position = p


func _anchor_rect() -> Rect2:
	var mouse := _mouse if _mouse != Vector2.INF else get_viewport().get_mouse_position()
	var at_cursor := Rect2(mouse.x, mouse.y, 0.0, CURSOR_HEIGHT)
	if _anchor == null or not is_instance_valid(_anchor) or not _anchor.is_inside_tree():
		return at_cursor
	if follows_cursor(_anchor):
		return at_cursor
	return _anchor.get_global_rect()

