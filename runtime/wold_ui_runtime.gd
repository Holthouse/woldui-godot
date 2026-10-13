@tool
extends Node
class_name WoldUIRuntime
## The `WoldUI` autoload: current tokens, motion/sound prefs, UI sound
## playback, and which input device is active.
##
## If the plugin isn't enabled, instance() makes one on first use instead.

signal input_mode_changed(mode: InputMode)
signal preferences_changed
## From apply_tokens(). WoldScopes listen and rebuild.
signal tokens_changed

enum InputMode { MOUSE, KEYBOARD, PAD, TOUCH }

const SETTING_TOKENS := "woldui/tokens"
const SETTING_BUS := "woldui/sound_bus"
const DEFAULT_TOKENS := "res://addons/woldui/tokens/default_dark.tres"
# below this it's stick drift, not someone picking up the pad
const PAD_DEADZONE := 0.4
const VOICES := 6

static var _fallback: WoldUIRuntime

var tokens: WoldTokens
## "Reduce motion". WoldMotion checks this everywhere.
var reduced_motion := false:
	set(value):
		reduced_motion = value
		preferences_changed.emit()
var sound_enabled := true:
	set(value):
		sound_enabled = value
		preferences_changed.emit()
## Added on top of the set's volume. Hook a settings slider to it.
var sound_volume_db := 0.0
var input_mode: InputMode = InputMode.MOUSE
## Moving between the pad and the keyboard/mouse takes a press, and that press
## only switches: it's eaten before the GUI and _unhandled_input see it, so
## picking up the pad never also clicks whatever has focus. The very first press
## is let through (it's the player choosing a device, e.g. "press any button").
## A mouse that only moves doesn't take over from the pad. Off by default.
var swallow_mode_switch := false
## for tests
var last_sound := ""

# set by the first press of any device; until then nothing is swallowed
var _device_chosen := false

## The WoldFeedback that the tokens' auto_feedback puts on the root, or null.
var feedback: WoldFeedback

var _voices: Array[AudioStreamPlayer] = []
var _next_voice := 0


## The autoload, or a fallback node if there isn't one.
static func instance() -> WoldUIRuntime:
	var loop := Engine.get_main_loop() as SceneTree
	if loop and loop.root:
		var node := loop.root.get_node_or_null("WoldUI")
		if node is WoldUIRuntime:
			return node
	if _fallback == null or not is_instance_valid(_fallback):
		_fallback = WoldUIRuntime.new()
		_fallback.name = "WoldUI"
		# don't add stuff to the editor's tree
		if loop and loop.root and not Engine.is_editor_hint():
			loop.root.add_child.call_deferred(_fallback)
	return _fallback


func _init() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var path: String = ProjectSettings.get_setting(SETTING_TOKENS, DEFAULT_TOKENS)
	tokens = load(path) as WoldTokens
	if tokens == null:
		tokens = load(DEFAULT_TOKENS)
	var bus: String = ProjectSettings.get_setting(SETTING_BUS, "Master")
	for i in VOICES:
		var p := AudioStreamPlayer.new()
		p.bus = bus if AudioServer.get_bus_index(bus) >= 0 else "Master"
		_voices.append(p)
		add_child(p)


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	get_tree().node_added.connect(_on_node_added)
	# the main scene isn't in yet while autoloads get ready
	start_feedback.call_deferred()
	start_tooltips()


## Puts a WoldFeedback on the root when the tokens ask for it (auto_feedback),
## set from the tokens' Feedback group. Only in a running game: a script run
## (tests, tools) has no current_scene and gets none, unless it passes
## `force` (a game's own tests, say, that should see what players get).
func start_feedback(force := false) -> void:
	if is_instance_valid(feedback) or tokens == null or not tokens.auto_feedback:
		return
	var tree := get_tree()
	if tree == null or (tree.current_scene == null and not force):
		return
	feedback = WoldFeedback.new()
	feedback.name = "WoldFeedback"
	feedback.auto = true
	feedback.motion = tokens.feedback_motion
	feedback.sound = tokens.feedback_sounds
	feedback.hover_sound = tokens.hover_sound
	feedback.fade_states = tokens.fade_states
	feedback.animate_popups = tokens.animate_popups
	feedback.popup_max_height = tokens.popup_max_height
	tree.root.add_child(feedback)


## Puts a WoldTooltipLayer on the root when tokens.tooltip_layer is on. Not
## headless unless `force`.
func start_tooltips(force := false) -> void:
	if tokens == null or not tokens.tooltip_layer or not is_inside_tree():
		return
	WoldTooltipLayer.install(get_tree(), force)


# customised controls re-apply once they're in, so they follow the tokens the
# game runs with; deferred so their own labels are in too
func _on_node_added(node: Node) -> void:
	if node is Control and node.has_meta(WoldCustomize.META):
		var id := node.get_instance_id()
		(func():
			var n := instance_from_id(id) as Control
			if n != null and n.is_inside_tree():
				WoldCustomize.apply(n)).call_deferred()


func _input(event: InputEvent) -> void:
	if note_input(event) and is_inside_tree():
		get_viewport().set_input_as_handled()


## Called from _input. Public in case your game routes input itself; then eat
## the event yourself when this returns true (see swallow_mode_switch).
func note_input(event: InputEvent) -> bool:
	# a tap also arrives as made-up mouse events for mouse-only controls;
	# those mustn't flip TOUCH back to MOUSE
	if event is InputEventMouse and event.device == InputEvent.DEVICE_ID_EMULATION:
		return false
	var mode := input_mode
	var press := false
	if event is InputEventScreenTouch or event is InputEventScreenDrag:
		mode = InputMode.TOUCH
	elif event is InputEventJoypadButton:
		mode = InputMode.PAD
		press = event.pressed
	elif event is InputEventJoypadMotion:
		if absf((event as InputEventJoypadMotion).axis_value) >= PAD_DEADZONE:
			mode = InputMode.PAD
			press = true
	elif event is InputEventKey:
		mode = InputMode.KEYBOARD
		press = event.pressed and not event.echo
	elif event is InputEventMouseButton:
		mode = InputMode.MOUSE
		press = event.pressed
	elif event is InputEventMouseMotion and (event as InputEventMouseMotion).relative.length() > 2.0:
		# a nudged mouse doesn't take the screen from someone on the pad
		if not (swallow_mode_switch and input_mode == InputMode.PAD):
			mode = InputMode.MOUSE
	var eat := swallow_mode_switch and press and _device_chosen \
			and (mode == InputMode.PAD) != (input_mode == InputMode.PAD)
	if press:
		_device_chosen = true
	if mode != input_mode:
		input_mode = mode
		input_mode_changed.emit(mode)
	return eat


## Godot's ui_accept and ui_cancel come with keys only, so out of the box a
## pad can move focus but not press anything or go back. This adds the bottom
## face button to ui_accept and the right one to ui_cancel (A and B on an Xbox
## pad), unless they're there already. Call it once at startup.
static func add_pad_ui_bindings() -> void:
	for pair in [[&"ui_accept", JOY_BUTTON_A], [&"ui_cancel", JOY_BUTTON_B]]:
		if not InputMap.has_action(pair[0]):
			continue
		var has := false
		for e in InputMap.action_get_events(pair[0]):
			if e is InputEventJoypadButton and (e as InputEventJoypadButton).button_index == pair[1]:
				has = true
		if not has:
			var b := InputEventJoypadButton.new()
			b.button_index = pair[1]
			# any pad, not just the first one plugged in
			b.device = -1
			InputMap.action_add_event(pair[0], b)


## Keys or pad. Focus rings/sounds and prompts only matter then.
func is_focus_navigating() -> bool:
	return input_mode == InputMode.KEYBOARD or input_mode == InputMode.PAD


## Fingers: no hover, bigger targets, long-press for tooltips.
func is_touch() -> bool:
	return input_mode == InputMode.TOUCH


## Play a slot ("click", "confirm"...). `sounds` overrides the token set.
## Empty slots use the built-in blips unless use_builtin_sounds is off.
func play(slot: String, sounds: WoldSoundSet = null) -> void:
	if not sound_enabled:
		return
	var bank := sounds if sounds else tokens.sounds
	var stream: AudioStream = bank.stream(slot) if bank else null
	var volume := bank.volume_db if bank else -6.0
	var jitter := bank.pitch_jitter if bank else 0.04
	if stream == null and tokens.use_builtin_sounds:
		var builtin := WoldSounds.builtin()
		stream = builtin.stream(slot)
		volume = builtin.volume_db
		jitter = builtin.pitch_jitter
	if stream == null:
		return
	last_sound = slot
	if not is_inside_tree():
		return
	var voice := _voices[_next_voice]
	_next_voice = (_next_voice + 1) % _voices.size()
	voice.stream = stream
	voice.volume_db = volume + sound_volume_db
	voice.pitch_scale = 1.0 + randf_range(-jitter, jitter)
	voice.play()


## Runtime token swap (light/dark, high contrast, faction colours...). Rebuilds
## the theme and writes it into the project theme in memory (never saved), or,
## without one, into the engine's default theme. Not onto the root window: a
## Window's theme stops at a CanvasLayer, so a HUD under one kept the old look.
## Controls repaint from the theme's `changed`.
func apply_tokens(new_tokens: WoldTokens) -> void:
	tokens = new_tokens
	var built := WoldThemeBuilder.build(new_tokens)
	var project := ThemeDB.get_project_theme()
	if project:
		WoldThemeBuilder.update_in_place(project, built)
	else:
		# merge, not replace: the default theme also holds what WoldUI doesn't style
		ThemeDB.get_default_theme().merge_with(built)
	tokens_changed.emit()
	WoldCustomize.apply_tree(get_tree().root)
