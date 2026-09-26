@tool
class_name WoldTooltip
extends Node
## Rich tooltip for whatever Control it's parented to. Add it as a child and
## fill it in from the Inspector.
## Main reason it exists over tooltip_text: it also shows on keyboard/pad
## focus, and it's anchored to the control rather than the cursor.
## Override _wold_fill() to stuff extra nodes into the panel's %Extra.
## On touch it shows on a long-press instead, and the next touch hides it.

signal shown
signal hidden

enum Placement { AUTO, TOP, BOTTOM, LEFT, RIGHT }

const PANEL := "res://addons/woldui/components/wold_tooltip/wold_tooltip_panel.tscn"
# above dialogs (100) so tooltips inside a dialog still show
const LAYER := 110

@export var title := ""
@export var icon := ""
## BBCode.
@export_multiline var body := ""
## Stat lines, e.g. {"Attack": "6", "Range": "2"}.
@export var rows: Dictionary[String, String] = {}
## Small footer line, "Right-click for details" kind of thing.
@export var hint := ""
## AUTO tries above, falls back to below. TOP/BOTTOM also flip if cramped.
@export var placement: Placement = Placement.AUTO
@export_range(120, 800) var max_width := 320
@export var show_on_focus := true
## Hover delay in seconds. -1 = use tokens.tooltip_delay.
@export_range(-1.0, 3.0, 0.05) var delay := -1.0

## null when hidden.
var panel: PanelContainer

# one tooltip at a time, across all instances
static var _current: WoldTooltip
var _wait: SceneTreeTimer
# long-press: where the finger went down, and when
var _press_at := Vector2.INF
var _press_timer: SceneTreeTimer

const LONG_PRESS := 0.5
# a finger that moves this far is scrolling, not pressing
const PRESS_SLOP := 12.0


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	var target := get_parent() as Control
	if target == null:
		push_error("WoldTooltip must be the child of a Control")
		return
	target.mouse_entered.connect(_on_hover)
	target.mouse_exited.connect(hide_tip)
	target.focus_entered.connect(_on_focus)
	target.focus_exited.connect(hide_tip)
	target.visibility_changed.connect(func(): if not target.is_visible_in_tree(): hide_tip())
	tree_exiting.connect(hide_tip)


## Called on every show, with a freshly built panel.
func _wold_fill(_panel: PanelContainer) -> void:
	pass


func is_showing() -> bool:
	return is_instance_valid(panel)


## Skips the delay.
func show_tip() -> void:
	if is_showing() or not is_inside_tree():
		return
	if is_instance_valid(_current) and _current != self:
		_current.hide_tip()
	_current = self
	panel = load(PANEL).instantiate()
	_fill()
	_layer().add_child(panel)
	# icons are white line art, tint to the title colour. Has to happen after
	# add_child or there's no theme to read.
	(panel.get_node("%Icon") as TextureRect).self_modulate = panel.get_theme_color("font_color", "TooltipTitle")
	panel.reset_size()
	place()
	WoldMotion.appear(panel, WoldMotion.preset("tooltip_in"))
	shown.emit()


func hide_tip() -> void:
	_wait = null
	if not is_showing():
		return
	panel.queue_free()
	panel = null
	if _current == self:
		_current = null
	hidden.emit()


## Re-run if the target moves while the tip is up. Clamped to the viewport.
func place() -> void:
	var target := get_parent() as Control
	if not is_showing() or target == null:
		return
	var view := target.get_viewport_rect().size
	var r := target.get_global_rect()
	var s := panel.size
	var gap := float(WoldUIRuntime.instance().tokens.space_sm)
	var chosen := placement
	if chosen == Placement.AUTO:
		chosen = Placement.TOP if r.position.y - gap - s.y >= 0.0 else Placement.BOTTOM
	elif chosen == Placement.TOP and r.position.y - gap - s.y < 0.0:
		chosen = Placement.BOTTOM
	elif chosen == Placement.BOTTOM and r.end.y + gap + s.y > view.y:
		chosen = Placement.TOP
	var p: Vector2
	match chosen:
		Placement.TOP:
			p = Vector2(r.get_center().x - s.x / 2.0, r.position.y - gap - s.y)
		Placement.BOTTOM:
			p = Vector2(r.get_center().x - s.x / 2.0, r.end.y + gap)
		Placement.LEFT:
			p = Vector2(r.position.x - gap - s.x, r.get_center().y - s.y / 2.0)
		_:
			p = Vector2(r.end.x + gap, r.get_center().y - s.y / 2.0)
	var edge := gap
	p.x = clampf(p.x, edge, maxf(edge, view.x - s.x - edge))
	p.y = clampf(p.y, edge, maxf(edge, view.y - s.y - edge))
	panel.position = p


func _on_hover() -> void:
	# on touch this is the pointer Godot fakes from a tap, not a real hover
	if WoldUIRuntime.instance().is_touch():
		return
	var wait := delay if delay >= 0.0 else WoldUIRuntime.instance().tokens.tooltip_delay
	var timer := get_tree().create_timer(wait)
	_wait = timer
	await timer.timeout
	# hide_tip() or a newer hover replaced _wait -> this one's stale
	if _wait == timer:
		show_tip()


# fingers: _input sees every touch, the target doesn't need to be on top
func _input(event: InputEvent) -> void:
	var target := get_parent() as Control
	if target == null or Engine.is_editor_hint():
		return
	var touch := event as InputEventScreenTouch
	if touch and touch.pressed:
		if is_showing():
			hide_tip()
		elif target.is_visible_in_tree() and target.get_global_rect().has_point(touch.position):
			_press_at = touch.position
			var timer := get_tree().create_timer(LONG_PRESS)
			_press_timer = timer
			await timer.timeout
			if _press_timer == timer and _press_at != Vector2.INF:
				show_tip()
	elif touch:
		_press_at = Vector2.INF
		_press_timer = null
	elif event is InputEventScreenDrag and _press_at != Vector2.INF:
		if (event as InputEventScreenDrag).position.distance_to(_press_at) > PRESS_SLOP:
			_press_at = Vector2.INF
			_press_timer = null


func _on_focus() -> void:
	if show_on_focus and WoldUIRuntime.instance().is_focus_navigating():
		show_tip()


func _fill() -> void:
	var t := WoldUIRuntime.instance().tokens
	panel.custom_minimum_size.x = 0
	(panel.get_node("%Title") as Label).text = title
	panel.get_node("%Header").visible = title != "" or icon != ""
	var icon_node := panel.get_node("%Icon") as TextureRect
	icon_node.texture = t.icon(icon, "Sm") if icon != "" else null
	icon_node.visible = icon != ""
	var body_node := panel.get_node("%Body") as RichTextLabel
	body_node.text = body
	body_node.visible = body != ""
	body_node.custom_minimum_size.x = max_width - t.space_md * 2
	var grid := panel.get_node("%Rows") as GridContainer
	for key in rows:
		var k := Label.new()
		k.theme_type_variation = &"TooltipKey"
		k.text = key
		grid.add_child(k)
		var v := Label.new()
		v.theme_type_variation = &"TooltipValue"
		v.text = rows[key]
		v.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		grid.add_child(v)
	grid.visible = not rows.is_empty()
	(panel.get_node("%Hint") as Label).text = hint
	panel.get_node("%Hint").visible = hint != ""
	_wold_fill(panel)


func _layer() -> CanvasLayer:
	var root := get_tree().root
	var layer := root.get_node_or_null("WoldTooltips") as CanvasLayer
	if layer == null:
		layer = CanvasLayer.new()
		layer.name = "WoldTooltips"
		layer.layer = LAYER
		root.add_child(layer)
	return layer
