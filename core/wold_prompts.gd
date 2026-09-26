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
	JOY_BUTTON_BACK: ["View", "Share", "−"], JOY_BUTTON_START: ["Menu", "Options", "+"],
	JOY_BUTTON_GUIDE: ["Home", "PS", "Home"],
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


## Guessed from the joy name. Anything unknown counts as Xbox.
static func family_of(device := 0) -> Family:
	var n := Input.get_joy_name(device).to_lower()
	if n.contains("playstation") or n.contains("dualsense") or n.contains("dualshock") or n.contains("ps4") or n.contains("ps5") or n.contains("sony"):
		return Family.PLAYSTATION
	if n.contains("nintendo") or n.contains("switch") or n.contains("joy-con"):
		return Family.NINTENDO
	return Family.XBOX


## First event on `action` for that device, or null.
static func event_for(action: StringName, device: Device) -> InputEvent:
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
			return {shape = "pill", text = label, icon = "", art = "prompt_%s_%s" % [fam, label.to_lower()]}
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
