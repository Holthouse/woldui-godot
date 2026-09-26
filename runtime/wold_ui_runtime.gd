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

enum InputMode { MOUSE, KEYBOARD, PAD }

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
## for tests
var last_sound := ""

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
		p.bus = bus if AudioServer.get_bus_index(bus) >= 0 else &"Master"
		_voices.append(p)
		add_child(p)


func _input(event: InputEvent) -> void:
	note_input(event)


## Called from _input. Public in case your game routes input itself.
# TODO: touch events are ignored, a touch counts as whatever came before it
func note_input(event: InputEvent) -> void:
	var mode := input_mode
	if event is InputEventJoypadButton:
		mode = InputMode.PAD
	elif event is InputEventJoypadMotion:
		if absf((event as InputEventJoypadMotion).axis_value) >= PAD_DEADZONE:
			mode = InputMode.PAD
	elif event is InputEventKey:
		mode = InputMode.KEYBOARD
	elif event is InputEventMouseButton or (event is InputEventMouseMotion and (event as InputEventMouseMotion).relative.length() > 2.0):
		mode = InputMode.MOUSE
	if mode != input_mode:
		input_mode = mode
		input_mode_changed.emit(mode)


## Keys or pad. Focus rings/sounds and prompts only matter then.
func is_focus_navigating() -> bool:
	return input_mode != InputMode.MOUSE


## Play a slot ("click", "confirm"...). `sounds` overrides the token set.
## Empty slots use the built-in blips unless use_builtin_sounds is off.
func play(slot: String, sounds: WoldSoundSet = null) -> void:
	if not sound_enabled:
		return
	var set := sounds if sounds else tokens.sounds
	var stream: AudioStream = set.stream(slot) if set else null
	var volume := set.volume_db if set else -6.0
	var jitter := set.pitch_jitter if set else 0.04
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


## Runtime token swap (high contrast, faction colours...). Rebuilds the theme
## and sets it on the root window.
func apply_tokens(new_tokens: WoldTokens) -> void:
	tokens = new_tokens
	get_tree().root.theme = WoldThemeBuilder.build(new_tokens)
	tokens_changed.emit()
