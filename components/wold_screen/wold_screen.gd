@tool
class_name WoldScreen
extends Control
## Root node for a menu / settings page / overlay. Handles the in/out
## animation, Esc/B as back, and putting focus back where it was.
##   WoldScreen.push(self, "res://ui/settings_screen.tscn")
##   WoldScreen.pop(self)
## That's the whole screen manager. You can also just drop one in a scene and
## call enter() / exit() yourself.

signal entered
signal exited
signal back_requested

enum Backdrop { BASE, SCRIM, NONE }

# below WoldDialog.ask's layer (100), so a dialog always sits over screens
const LAYER := 80

## BASE is opaque, SCRIM dims whatever is underneath.
@export var backdrop: Backdrop = Backdrop.BASE:
	set(v):
		backdrop = v
		queue_redraw()
## Gets focus on enter, for keyboard/pad players.
@export var first_focus: NodePath
## Off = ui_cancel only emits back_requested and you decide.
@export var auto_back := true
@export var enter_preset := "screen_enter"
@export var exit_preset := "screen_exit"

var is_open := false
var _return_focus: Control


## Scene or path. Root must be a WoldScreen.
static func push(host: Node, screen_scene: Variant) -> WoldScreen:
	var packed: PackedScene = load(screen_scene) if screen_scene is String else screen_scene
	var screen := packed.instantiate() as WoldScreen
	assert(screen != null, "WoldScreen.push: the scene's root must be a WoldScreen")
	var focused := host.get_viewport().gui_get_focus_owner()
	_stack(host).add_child(screen)
	screen._return_focus = focused
	screen.enter()
	return screen


## false if the stack was empty.
static func pop(host: Node) -> bool:
	var screen := top(host)
	if screen == null:
		return false
	screen.exit(true)
	return true


static func top(host: Node) -> WoldScreen:
	var stack := _stack(host)
	for i in range(stack.get_child_count() - 1, -1, -1):
		var s := stack.get_child(i) as WoldScreen
		if s and s.is_open:
			return s
	return null


static func _stack(host: Node) -> CanvasLayer:
	var root := host.get_tree().root
	var layer := root.get_node_or_null("WoldScreens") as CanvasLayer
	if layer == null:
		layer = CanvasLayer.new()
		layer.name = "WoldScreens"
		layer.layer = LAYER
		root.add_child(layer)
	return layer


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP


## Override hooks, called as the animation starts.
func _wold_on_enter() -> void:
	pass


func _wold_on_exit() -> void:
	pass


func enter() -> void:
	if is_open:
		return
	is_open = true
	if _return_focus == null:
		var f := get_viewport().gui_get_focus_owner()
		_return_focus = f if f and not is_ancestor_of(f) else null
	WoldUIRuntime.instance().play("open")
	WoldMotion.appear(self, WoldMotion.preset(enter_preset))
	_focus_first.call_deferred()
	_wold_on_enter()
	entered.emit()


func exit(then_free := false) -> void:
	if not is_open:
		return
	is_open = false
	_wold_on_exit()
	WoldUIRuntime.instance().play("close")
	WoldMotion.disappear(self, WoldMotion.preset(exit_preset), then_free)
	if is_instance_valid(_return_focus) and _return_focus.is_visible_in_tree():
		_return_focus.grab_focus(not WoldUIRuntime.instance().is_focus_navigating())
	exited.emit()


## Only checks siblings, so screens in different parents don't know about
## each other.
func is_top() -> bool:
	var parent := get_parent()
	if parent == null:
		return true
	for i in range(get_index() + 1, parent.get_child_count()):
		var above := parent.get_child(i) as WoldScreen
		if above and above.is_open:
			return false
	return true


func _unhandled_input(event: InputEvent) -> void:
	if not is_open or Engine.is_editor_hint() or not is_top():
		return
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		back_requested.emit()
		if auto_back:
			# only free screens that push() made; hand-placed ones just hide
			exit(get_parent() != null and get_parent().name == "WoldScreens")


func _focus_first() -> void:
	if not is_open or first_focus.is_empty():
		return
	var target := get_node_or_null(first_focus) as Control
	if target and target.is_visible_in_tree():
		target.grab_focus(not WoldUIRuntime.instance().is_focus_navigating())


func _draw() -> void:
	if backdrop == Backdrop.NONE:
		return
	var style := &"PanelBase" if backdrop == Backdrop.BASE else &"PanelScrim"
	draw_style_box(get_theme_stylebox("panel", style), Rect2(Vector2.ZERO, size))
