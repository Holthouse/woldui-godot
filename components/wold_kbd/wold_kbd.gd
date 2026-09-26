@tool
class_name WoldKbd
extends HBoxContainer
## Key caps for a shortcut written in text: "Ctrl+K", "Shift+Tab", "F2".
## For an InputMap action that follows the player's device, use
## WoldButtonPrompt instead; this is for fixed text (help screens, menus).

@export var keys := "Ctrl+K":
	set(v):
		keys = v
		_rebuild()


func _ready() -> void:
	theme_type_variation = &"RowXs"
	_rebuild()


## The caps, as written: "Ctrl+K" -> ["Ctrl", "K"].
func parts() -> PackedStringArray:
	var out := PackedStringArray()
	for p in keys.split("+", false):
		out.append(p.strip_edges())
	return out


# generated and unowned, so they're never saved
func _rebuild() -> void:
	if not is_node_ready():
		return
	for child in get_children():
		remove_child(child)
		child.queue_free()
	for p in parts():
		var g := WoldPromptGlyph.new()
		g.glyph = {shape = "key", text = p, icon = "", art = ""}
		add_child(g)


func _validate_property(property: Dictionary) -> void:
	if property.name == "theme_type_variation":
		property.usage &= ~PROPERTY_USAGE_STORAGE
