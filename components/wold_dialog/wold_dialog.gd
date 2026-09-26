@tool
class_name WoldDialog
extends Control
## Modal confirm/cancel dialog over a scrim. Quickest way in:
##   var answer := await WoldDialog.ask(self, "Leave the match?", "", "Leave", "Stay")
## For anything custom, instance the scene, put your nodes under %Content
## (extra buttons under %Actions) and call open().
# Keyboard/pad focus is trapped inside while open and handed back on close.

signal opened
signal confirmed
signal cancelled
## "confirm", "cancel", or whatever string you passed to close().
signal closed(result: String)

enum Tone { NEUTRAL, ACCENT, SUCCESS, WARNING, DANGER }
enum Size { MD, SM }
const _TONE_STYLES := ["Muted", "TextAccent", "TextSuccess", "TextWarning", "TextDanger"]
const SCENE := "res://addons/woldui/components/wold_dialog/wold_dialog.tscn"

@export var title := "Title":
	set(v):
		title = v
		_refresh()
@export_multiline var message := "":
	set(v):
		message = v
		_refresh()
@export var icon := "":
	set(v):
		icon = v
		_refresh()
## Only tints the icon.
@export var tone: Tone = Tone.NEUTRAL:
	set(v):
		tone = v
		_refresh()

@export_group("Actions")
## Empty = no confirm button. Same goes for cancel_text.
@export var confirm_text := "OK":
	set(v):
		confirm_text = v
		_refresh()
@export var cancel_text := "Cancel":
	set(v):
		cancel_text = v
		_refresh()
## Red confirm button.
@export var destructive := false:
	set(v):
		destructive = v
		_refresh()

@export_group("Behaviour")
## X button, Esc/B and scrim clicks. Off = the player has to pick.
@export var closable := true:
	set(v):
		closable = v
		_refresh()
@export var dismiss_on_scrim := true
@export_range(200, 1200) var width := 420:
	set(v):
		width = v
		_refresh()
## SM is the quick yes / no: narrower, centred, buttons share the width.
## Not `size`, Control has one.
@export var dialog_size: Size = Size.MD:
	set(v):
		dialog_size = v
		_refresh()
@export var free_on_close := false
## Open on start in-game. The editor always shows it anyway.
@export var start_open := false

var is_open := false
var _return_focus: Control
# open dialogs, newest last. Only the top one traps focus and takes Esc, so a
# confirm opened from a sheet doesn't fight it for focus
static var _stack: Array[WoldDialog] = []
var _refreshing := false


func _ready() -> void:
	_refresh()
	if Engine.is_editor_hint():
		return
	%Confirm.pressed.connect(func(): close("confirm"))
	%Cancel.pressed.connect(func(): close("cancel"))
	%Close.pressed.connect(func(): close("cancel"))
	%Scrim.gui_input.connect(_on_scrim_input)
	visible = false
	if start_open:
		open.call_deferred()


## Subclass hooks. Refresh runs before every restyle, the other two when the
## open/close animation starts.
func _wold_refresh() -> void:
	pass


func _wold_on_open() -> void:
	pass


func _wold_on_close(_result: String) -> void:
	pass


## How the panel comes in and goes out. WoldSheet slides from its edge.
func _wold_panel_in() -> WoldMotionPreset:
	return WoldMotion.preset("dialog_in")


func _wold_panel_out() -> WoldMotionPreset:
	return WoldMotion.preset("dialog_out")


## Await this. Builds a throwaway dialog on its own CanvasLayer (100) and
## returns "confirm" or "cancel".
static func ask(host: Node, ask_title: String, ask_message := "", confirm := "OK", cancel := "Cancel", is_destructive := false) -> String:
	var layer := CanvasLayer.new()
	layer.layer = 100
	host.get_tree().root.add_child(layer)
	var d: WoldDialog = load(SCENE).instantiate()
	d.title = ask_title
	d.message = ask_message
	d.confirm_text = confirm
	d.cancel_text = cancel
	d.destructive = is_destructive
	# layer dies with the dialog, after the close animation
	d.free_on_close = true
	d.tree_exited.connect(layer.queue_free)
	layer.add_child(d)
	d.open()
	return await d.closed


func open() -> void:
	if is_open:
		return
	is_open = true
	_stack.append(self)
	var focused := get_viewport().gui_get_focus_owner()
	_return_focus = focused if focused and not is_ancestor_of(focused) else null
	visible = true
	WoldMotion.appear(%Scrim, WoldMotion.preset("appear_fade"))
	WoldMotion.appear(%Panel, _wold_panel_in())
	WoldUIRuntime.instance().play("open")
	if not get_viewport().gui_focus_changed.is_connected(_on_focus_changed):
		get_viewport().gui_focus_changed.connect(_on_focus_changed)
	_focus_first()
	_wold_on_open()
	opened.emit()


# freed while open (a scene change, say): don't block the ones left behind
func _exit_tree() -> void:
	_stack.erase(self)


## True when no other open dialog sits over this one.
func is_top() -> bool:
	return not _stack.is_empty() and _stack.back() == self


## Any string works as a result; only "confirm"/"cancel" fire their own signal.
func close(result := "cancel") -> void:
	if not is_open:
		return
	is_open = false
	_stack.erase(self)
	if get_viewport().gui_focus_changed.is_connected(_on_focus_changed):
		get_viewport().gui_focus_changed.disconnect(_on_focus_changed)
	_wold_on_close(result)
	if result == "confirm":
		confirmed.emit()
	elif result == "cancel":
		cancelled.emit()
	WoldUIRuntime.instance().play("close")
	WoldMotion.disappear(%Scrim, WoldMotion.preset("disappear"))
	var tw := WoldMotion.disappear(%Panel, _wold_panel_out())
	if is_instance_valid(_return_focus) and _return_focus.is_visible_in_tree():
		_return_focus.grab_focus(not WoldUIRuntime.instance().is_focus_navigating())
	closed.emit(result)
	await tw.finished
	if not is_open:
		visible = false
		%Scrim.visible = true
		%Panel.visible = true
		if free_on_close:
			queue_free()


func _unhandled_input(event: InputEvent) -> void:
	if not is_open or not is_top():
		return
	if event.is_action_pressed("ui_cancel") and closable:
		close("cancel")
		get_viewport().set_input_as_handled()


func _on_scrim_input(event: InputEvent) -> void:
	var mb := event as InputEventMouseButton
	if is_open and dismiss_on_scrim and closable and mb and mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
		close("cancel")


# Focus trap.
# NOTE: refocus is deferred, so focus can sit outside the dialog for a frame.
func _on_focus_changed(node: Control) -> void:
	if is_open and is_top() and node and not is_ancestor_of(node):
		_focus_first.call_deferred()


func _focus_first() -> void:
	# always grab focus so Enter confirms, but hide the ring for mouse users
	var hide := not WoldUIRuntime.instance().is_focus_navigating()
	for candidate in [%Confirm, %Cancel]:
		if candidate.visible and candidate.focus_mode != Control.FOCUS_NONE:
			candidate.grab_focus(hide)
			return
	var any := _first_focusable(%Panel)
	if any:
		any.grab_focus(hide)


func _first_focusable(node: Node) -> Control:
	for child in node.get_children():
		if child is Control and child.is_visible_in_tree() and child.focus_mode == Control.FOCUS_ALL:
			return child
		var inner := _first_focusable(child)
		if inner:
			return inner
	return null


func _refresh() -> void:
	if _refreshing or not is_node_ready():
		return
	_refreshing = true
	_wold_refresh()
	(%Title as Label).text = title
	(%Message as Label).text = message
	%Message.visible = message != ""
	var icon_node := %Icon as TextureRect
	var t := WoldUIRuntime.instance().tokens
	icon_node.texture = t.icon(icon, "Lg") if icon != "" else null
	icon_node.visible = icon != ""
	icon_node.self_modulate = get_theme_color("font_color", _TONE_STYLES[tone])
	var confirm := %Confirm as WoldButton
	confirm.text = confirm_text
	confirm.visible = confirm_text != ""
	confirm.shape = WoldButton.Shape.DANGER if destructive else WoldButton.Shape.PRIMARY
	var cancel := %Cancel as WoldButton
	cancel.text = cancel_text
	cancel.visible = cancel_text != ""
	# the small one is a straight question: no X, Esc still cancels
	%Close.visible = closable and dialog_size == Size.MD
	var small := dialog_size == Size.SM
	%Panel.custom_minimum_size.x = mini(width, 340) if small else width
	var middle := HORIZONTAL_ALIGNMENT_CENTER if small else HORIZONTAL_ALIGNMENT_LEFT
	(%Title as Label).horizontal_alignment = middle
	(%Title as Label).size_flags_horizontal = SIZE_EXPAND_FILL
	(%Message as Label).horizontal_alignment = middle
	for b in [confirm, cancel]:
		b.size_flags_horizontal = SIZE_EXPAND_FILL if small else SIZE_FILL
	_refreshing = false
