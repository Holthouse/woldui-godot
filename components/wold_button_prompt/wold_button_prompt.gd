@tool
class_name WoldButtonPrompt
extends HBoxContainer
## "[A] Confirm". Reads the action's actual bindings and swaps glyphs live as
## the player moves between keyboard, pad and mouse.
## Call refresh() after you rebind something.
# Custom art: put a texture in the icon set under the glyph's art name
# (prompt_xbox_a, prompt_ps_cross, prompt_key_e...) and it's used instead of
# the drawn keycap.
# TODO: pad buttons WoldPrompts has no mapping for come out as "?", and
# family detection only knows Xbox / PlayStation / Nintendo, so a Steam Deck
# or generic pad just gets Xbox glyphs.

enum InputKind { AUTO, KEYBOARD, PAD, MOUSE }
enum PadFamily { AUTO, XBOX, PLAYSTATION, NINTENDO }

@export var action: StringName = &"ui_accept":
	set(v):
		action = v
		refresh()
## Text next to the glyph. Empty hides it.
@export var label := "Confirm":
	set(v):
		label = v
		refresh()
## AUTO follows the player's last input; the rest pin one device.
@export var input_kind: InputKind = InputKind.AUTO:
	set(v):
		input_kind = v
		refresh()
## AUTO guesses from the joypad name.
@export var pad_family: PadFamily = PadFamily.AUTO:
	set(v):
		pad_family = v
		refresh()
@export var hide_on_mouse := false:
	set(v):
		hide_on_mouse = v
		refresh()

## Current glyph dict, as WoldPrompts builds it.
var glyph: Dictionary = {}


func _ready() -> void:
	var ui := WoldUIRuntime.instance()
	if not ui.input_mode_changed.is_connected(_on_mode):
		ui.input_mode_changed.connect(_on_mode)
	refresh()


func _exit_tree() -> void:
	var ui := WoldUIRuntime.instance()
	if ui.input_mode_changed.is_connected(_on_mode):
		ui.input_mode_changed.disconnect(_on_mode)


func _on_mode(_mode: int) -> void:
	refresh()


## Which device's binding we're showing.
func device() -> WoldPrompts.Device:
	match input_kind:
		InputKind.KEYBOARD: return WoldPrompts.Device.KEYBOARD
		InputKind.PAD: return WoldPrompts.Device.PAD
		InputKind.MOUSE: return WoldPrompts.Device.MOUSE
	match WoldUIRuntime.instance().input_mode:
		WoldUIRuntime.InputMode.PAD: return WoldPrompts.Device.PAD
		WoldUIRuntime.InputMode.MOUSE, WoldUIRuntime.InputMode.TOUCH: return WoldPrompts.Device.MOUSE
	return WoldPrompts.Device.KEYBOARD


func refresh() -> void:
	if not is_node_ready():
		return
	var ui := WoldUIRuntime.instance()
	(%Label as Label).text = label
	%Label.visible = label != ""
	var dev := device()
	var event := WoldPrompts.event_for(action, dev)
	# nothing bound for this device? take whatever is, keyboard first
	for other in [WoldPrompts.Device.KEYBOARD, WoldPrompts.Device.PAD, WoldPrompts.Device.MOUSE]:
		if event == null:
			event = WoldPrompts.event_for(action, other)
	var fam: WoldPrompts.Family = WoldPrompts.family_of() if pad_family == PadFamily.AUTO else pad_family - 1
	glyph = WoldPrompts.glyph_for(event, fam) if event else {shape = "key", text = "?", icon = "", art = ""}
	var g := %Glyph as WoldPromptGlyph
	g.glyph = glyph
	var set := ui.tokens.icon_set
	g.art = set.get_icon(glyph.art) if set and glyph.art != "" and set.custom_names().has(glyph.art) else null
	# a finger is a pointer too: button glyphs mean nothing to it
	var mouse_now := input_kind == InputKind.AUTO and ui.input_mode in [WoldUIRuntime.InputMode.MOUSE, WoldUIRuntime.InputMode.TOUCH]
	visible = not (hide_on_mouse and mouse_now)
	if event == null and not Engine.is_editor_hint():
		push_warning("WoldButtonPrompt: action '%s' has no bindings" % action)
