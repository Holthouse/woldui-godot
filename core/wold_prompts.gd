@tool
class_name WoldPrompts
## InputEvent -> button glyph, so prompts follow the actual (rebound) bindings.
##
## Glyph = {shape, text, icon, art}. shape is "key", "face" (pad A/B/X/Y),
## "pill" (LB, RT, Menu...) or "icon" (mouse). `art` is the name to put your
## own texture under in a WoldIconSet, e.g. "prompt_xbox_a", "prompt_key_e".

enum Family { XBOX, PLAYSTATION, NINTENDO }
enum Device { KEYBOARD, PAD, MOUSE }

const _FACE := {
	JOY_BUTTON_A: [["A", ""], ["", "x"], ["B", ""]],
	JOY_BUTTON_B: [["B", ""], ["", "circle"], ["A", ""]],
	JOY_BUTTON_X: [["X", ""], ["", "square"], ["Y", ""]],
	JOY_BUTTON_Y: [["Y", ""], ["", "triangle"], ["X", ""]],
}
const _FACE_ART := {
	JOY_BUTTON_A: ["a", "cross", "b"], JOY_BUTTON_B: ["b", "circle", "a"],
	JOY_BUTTON_X: ["x", "square", "y"], JOY_BUTTON_Y: ["y", "triangle", "x"],
}
const _PILL := {
	JOY_BUTTON_LEFT_SHOULDER: ["LB", "L1", "L"], JOY_BUTTON_RIGHT_SHOULDER: ["RB", "R1", "R"],
	JOY_BUTTON_LEFT_STICK: ["LS", "L3", "LS"], JOY_BUTTON_RIGHT_STICK: ["RS", "R3", "RS"],
	JOY_BUTTON_BACK: ["View", "Create", "−"], JOY_BUTTON_START: ["Menu", "Options", "+"],
	JOY_BUTTON_GUIDE: ["Home", "PS", "Home"],
}
## Pills that show a symbol instead of their name. Xbox prints one on its two
## middle buttons and players don't know them as "View" and "Menu".
const _PILL_ICON := {
	JOY_BUTTON_BACK: ["copy", "", ""], JOY_BUTTON_START: ["menu", "", ""],
}
const _DPAD := {
	JOY_BUTTON_DPAD_UP: "arrow-up", JOY_BUTTON_DPAD_DOWN: "arrow-down",
	JOY_BUTTON_DPAD_LEFT: "arrow-left", JOY_BUTTON_DPAD_RIGHT: "arrow-right",
}
const _KEY_SHORT := {
	"Escape": "Esc", "Backspace": "⌫", "Delete": "Del", "Control": "Ctrl",
	"PageUp": "PgUp", "PageDown": "PgDn", "CapsLock": "Caps",
}
const _KEY_ICON := {KEY_UP: "arrow-up", KEY_DOWN: "arrow-down", KEY_LEFT: "arrow-left", KEY_RIGHT: "arrow-right"}
const _FAMILY_NAME := ["xbox", "ps", "switch"]


## Which glyphs a pad wants. `device` -1 means the pad pressed last
## (WoldUIRuntime.pad_device). A game's family resolver answers first, then the
## pad's name; anything unknown counts as Xbox.
static func family_of(device := -1) -> Family:
	if device < 0:
		device = WoldUIRuntime.instance().pad_device
	if _family_resolver.is_valid():
		var told = _family_resolver.call(device)
		if told is int and told >= 0 and told <= Family.NINTENDO:
			return told
	return family_from_name(Input.get_joy_name(device))


## The family a pad's name gives away (the names Godot reports, from SDL's
## controller list, and the raw ones some drivers use).
static func family_from_name(joy_name: String) -> Family:
	var n := joy_name.to_lower()
	for word in ["playstation", "dualsense", "dualshock", "ps3", "ps4", "ps5", "sony"]:
		if n.contains(word):
			return Family.PLAYSTATION
	for word in ["nintendo", "switch", "joy-con", "joycon", "pro controller"]:
		if n.contains(word):
			return Family.NINTENDO
	return Family.XBOX


## Some pads hide what they are: Steam Input, for one, shows every controller to
## the game as an Xbox pad. A game that can find out hands it over here:
## Callable(device: int) -> int, a Family, or -1 when it doesn't know. Call
## WoldUIRuntime.refresh_pad_family() when its answer may have changed.
static var _family_resolver := Callable()


static func set_family_resolver(resolver: Callable) -> void:
	_family_resolver = resolver
	WoldUIRuntime.instance().refresh_pad_family()


## A game that keeps its bindings somewhere other than the InputMap hands
## them over here: Callable(action: StringName, device: Device) -> InputEvent
## (or null when it doesn't know the action, which falls back to the InputMap).
static var _resolver := Callable()


static func set_binding_resolver(resolver: Callable) -> void:
	_resolver = resolver


## First event on `action` for that device, or null.
static func event_for(action: StringName, device: Device) -> InputEvent:
	if _resolver.is_valid():
		var resolved = _resolver.call(action, device)
		if resolved is InputEvent:
			return resolved
	if not InputMap.has_action(action):
		return null
	for e in InputMap.action_get_events(action):
		match device:
			Device.KEYBOARD:
				if e is InputEventKey:
					return e
			Device.PAD:
				if e is InputEventJoypadButton or e is InputEventJoypadMotion:
					return e
			Device.MOUSE:
				if e is InputEventMouseButton:
					return e
	return null


static func glyph_for(event: InputEvent, family := Family.XBOX) -> Dictionary:
	var fam: String = _FAMILY_NAME[family]
	if event is InputEventKey:
		var k := event as InputEventKey
		var code := k.keycode if k.keycode != KEY_NONE else DisplayServer.keyboard_get_keycode_from_physical(k.physical_keycode)
		if _KEY_ICON.has(code):
			return {shape = "key", text = "", icon = _KEY_ICON[code], art = "prompt_key_" + OS.get_keycode_string(code).to_lower()}
		var label := OS.get_keycode_string(code)
		return {shape = "key", text = _KEY_SHORT.get(label, label), icon = "", art = "prompt_key_" + label.to_lower()}
	if event is InputEventJoypadButton:
		var b := (event as InputEventJoypadButton).button_index
		if _FACE.has(b):
			var f: Array = _FACE[b][family]
			return {shape = "face", text = f[0], icon = f[1], art = "prompt_%s_%s" % [fam, _FACE_ART[b][family]]}
		if _DPAD.has(b):
			return {shape = "pill", text = "", icon = _DPAD[b], art = "prompt_%s_%s" % [fam, _DPAD[b].replace("arrow", "dpad")]}
		if _PILL.has(b):
			var label: String = _PILL[b][family]
			var symbol: String = _PILL_ICON[b][family] if _PILL_ICON.has(b) else ""
			return {shape = "pill", text = "" if symbol != "" else label, icon = symbol,
				art = "prompt_%s_%s" % [fam, label.to_lower()]}
	if event is InputEventJoypadMotion:
		var axis := (event as InputEventJoypadMotion).axis
		var label: String
		match axis:
			JOY_AXIS_TRIGGER_LEFT: label = ["LT", "L2", "ZL"][family]
			JOY_AXIS_TRIGGER_RIGHT: label = ["RT", "R2", "ZR"][family]
			JOY_AXIS_LEFT_X, JOY_AXIS_LEFT_Y: label = ["LS", "L", "L"][family]
			_: label = ["RS", "R", "R"][family]
		return {shape = "pill", text = label, icon = "", art = "prompt_%s_%s" % [fam, label.to_lower()]}
	if event is InputEventMouseButton:
		var mb := (event as InputEventMouseButton).button_index
		var icon := "mouse-right" if mb == MOUSE_BUTTON_RIGHT else ("mouse" if mb == MOUSE_BUTTON_MIDDLE else "mouse-left")
		return {shape = "icon", text = "", icon = icon, art = "prompt_" + icon.replace("-", "_")}
	return {shape = "key", text = "?", icon = "", art = ""}
