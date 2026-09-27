@tool
class_name WoldFeedback
extends Node
## Add as a child and every button under the parent gets hover/press motion
## and sounds. Also catches buttons added later. With fade_states the plain
## controls ease between their theme states too (buttons, tabs, focus rings),
## and PopupMenus fade in.
##
## Per-button metadata: wold_sound = "confirm"/"back"/"open"/"close"/"none"
## (default "click"), wold_feedback = false to skip a node and whatever is
## inside it.

@export var motion := true
@export var sound := true
## Turn off for long lists, it gets noisy. Focus sounds aren't affected.
@export var hover_sound := true
## Empty = tokens' sounds.
@export var sounds: WoldSoundSet
## Crossfade buttons, tabs and focus rings between theme states instead of
## the engine's hard swap. wold_fade = false on a node skips it.
@export var fade_states := true
## Fade popups in: PopupMenus (OptionButton lists, MenuButton, context
## menus) and PopupPanels, which includes the engine's tooltips.
@export var animate_popups := true

## Set on the one the WoldUI autoload makes (tokens' auto_feedback). It waits a
## frame before wiring anything new, so a WoldFeedback of your own in that
## part of the tree gets there first and wins.
var auto := false

const _WIRED := &"_wold_feedback"
const _SEEN := &"_wold_feedback_seen"
const _FADE := &"_wold_fade"
const ButtonFade := preload("res://addons/woldui/runtime/fade/button_fade.gd")
const TabFade := preload("res://addons/woldui/runtime/fade/tab_fade.gd")
const FocusFade := preload("res://addons/woldui/runtime/fade/focus_fade.gd")
const PopupFade := preload("res://addons/woldui/runtime/fade/popup_fade.gd")
const PanelFade := preload("res://addons/woldui/runtime/fade/panel_fade.gd")


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
	if not host or not host.is_ancestor_of(node):
		return
	if auto:
		(func():
			if is_instance_valid(node) and node.is_inside_tree():
				_wire_node(node)).call_deferred()
	else:
		_wire_node(node)


# internal children too: an OptionButton's list is one
func _wire_tree(node: Node) -> void:
	_wire_node(node)
	for child in node.get_children(true):
		_wire_tree(child)


func _wire_node(node: Node) -> void:
	# one WoldFeedback per node, whichever reaches it first
	if node.has_meta(_SEEN):
		return
	node.set_meta(_SEEN, true)
	if node.get_meta("wold_feedback", true) == false:
		return
	# an opted-out node's insides stay out too
	var parent := node.get_parent()
	if parent and parent.get_meta("wold_feedback", true) == false:
		node.set_meta("wold_feedback", false)
		return
	if node is BaseButton:
		_wire(node)
	if node.has_meta(_FADE) or node.get_meta("wold_fade", true) == false:
		return
	var fade: RefCounted
	if node is PopupMenu:
		if animate_popups or fade_states:
			fade = PopupFade.new(node, animate_popups, fade_states)
	elif node is PopupPanel:
		if animate_popups:
			fade = PanelFade.new(node)
	elif not fade_states:
		return
	elif node is Button:
		fade = ButtonFade.new(node)
	elif node is TabContainer:
		fade = TabFade.new(node)
	elif node is TabBar and not (node.get_parent() and node.get_parent().get_parent() is TabContainer):
		fade = TabFade.new(node)
	elif node is LineEdit or node is TextEdit or node is Slider or node is ItemList or node is Tree:
		fade = FocusFade.new(node)
	if fade:
		node.set_meta(_FADE, fade)


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
	# fingers don't hover; a tap would leave the button lifted
	if b.disabled or _ui().is_touch():
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
		var effect := press_effect_for(b)
		if effect:
			# keyboard, pad and touch have no point to grow from; mouse does
			var at: Vector2 = b.get_local_mouse_position() if _ui().input_mode == WoldUIRuntime.InputMode.MOUSE else b.size / 2.0
			effect.play(b, at)


## The press effect `b` gets: its wold_press_effect metadata ("none" = off),
## then WoldButton.press_effect, then the tokens'. Check boxes and switches
## don't get one, the mark is their feedback.
func press_effect_for(b: BaseButton) -> WoldPressEffect:
	if not b is Button or b is CheckBox or b is CheckButton or b.has_method(&"hot"):
		return null
	var meta: Variant = b.get_meta("wold_press_effect") if b.has_meta("wold_press_effect") else null
	if meta is String and meta == "none":
		return null
	if meta is WoldPressEffect:
		return meta
	var own: Variant = b.get("press_effect")
	if own is WoldPressEffect:
		return own
	return _ui().tokens.press_effect


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
