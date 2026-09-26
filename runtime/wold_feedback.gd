@tool
class_name WoldFeedback
extends Node
## Add as a child and every button under the parent gets hover/press motion
## and sounds. Also catches buttons added later.
##
## Per-button metadata: wold_sound = "confirm"/"back"/"open"/"close"/"none"
## (default "click"), wold_feedback = false to skip a button.

@export var motion := true
@export var sound := true
## Turn off for long lists, it gets noisy. Focus sounds aren't affected.
@export var hover_sound := true
## Empty = tokens' sounds.
@export var sounds: WoldSoundSet

const _WIRED := &"_wold_feedback"


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	var host := get_parent()
	if host == null:
		return
	_wire_tree(host)
	get_tree().node_added.connect(_on_node_added)


func _on_node_added(node: Node) -> void:
	var host := get_parent()
	if node is BaseButton and host and host.is_ancestor_of(node):
		_wire(node)


func _wire_tree(node: Node) -> void:
	if node is BaseButton:
		_wire(node)
	for child in node.get_children():
		_wire_tree(child)


func _wire(b: BaseButton) -> void:
	if b.has_meta(_WIRED) or b.get_meta("wold_feedback", true) == false:
		return
	b.set_meta(_WIRED, true)
	b.mouse_entered.connect(_on_hover.bind(b, true))
	b.mouse_exited.connect(_on_hover.bind(b, false))
	b.focus_entered.connect(_on_focus.bind(b, true))
	b.focus_exited.connect(_on_focus.bind(b, false))
	b.button_down.connect(_on_down.bind(b))
	b.pressed.connect(_on_pressed.bind(b))
	b.gui_input.connect(_on_gui_input.bind(b))


func _ui() -> WoldUIRuntime:
	return WoldUIRuntime.instance()


func _on_hover(b: BaseButton, on: bool) -> void:
	if b.disabled:
		return
	if motion and b is Control:
		WoldMotion.hover(b, on or b.has_focus() and _ui().is_focus_navigating())
	if on and sound and hover_sound:
		_ui().play("hover", sounds)


func _on_focus(b: BaseButton, on: bool) -> void:
	# clicking also grabs focus, only care about keyboard/pad focus moves
	if not _ui().is_focus_navigating():
		return
	if motion:
		WoldMotion.hover(b, on)
	if on and sound:
		_ui().play("focus", sounds)


func _on_down(b: BaseButton) -> void:
	if motion:
		WoldMotion.press(b)


func _on_pressed(b: BaseButton) -> void:
	var slot: String = b.get_meta("wold_sound", "click")
	if sound and slot != "none":
		_ui().play(slot, sounds)


# clicking a disabled button shakes it + error sound. Dead silence reads as a bug.
func _on_gui_input(event: InputEvent, b: BaseButton) -> void:
	if not b.disabled:
		return
	var mb := event as InputEventMouseButton
	if mb and mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
		if motion:
			WoldMotion.shake(b)
		if sound:
			_ui().play("error", sounds)
