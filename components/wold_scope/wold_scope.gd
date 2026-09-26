@tool
class_name WoldScope
extends MarginContainer
## Wrap a subtree in this to re-theme just that bit from a few token tweaks,
## e.g. a faction colour on one panel or a tighter radius on a side list.
## Builds a whole Theme off the global tokens + your overrides.
# NOTE: nested scopes don't stack. The inner one starts from the global tokens,
# not from the outer scope's overrides.

## Shortcut for the accent token. Alpha 0 = leave it alone.
@export var accent := Color(0, 0, 0, 0):
	set(v):
		accent = v
		rebuild()
## Token name -> value, e.g. {"radius_md": 0, "base_font_size": 16}.
@export var token_overrides: Dictionary = {}:
	set(v):
		token_overrides = v
		rebuild()


func _ready() -> void:
	var ui := WoldUIRuntime.instance()
	if not ui.tokens_changed.is_connected(rebuild):
		ui.tokens_changed.connect(rebuild)
	rebuild()


func _exit_tree() -> void:
	var ui := WoldUIRuntime.instance()
	if ui.tokens_changed.is_connected(rebuild):
		ui.tokens_changed.disconnect(rebuild)


## token_overrides with accent merged in.
func overrides() -> Dictionary:
	var all := token_overrides.duplicate()
	if accent.a > 0.0:
		all["accent"] = accent
	return all


func rebuild() -> void:
	if not is_node_ready():
		return
	var all := overrides()
	if all.is_empty():
		theme = null
		return
	theme = WoldThemeBuilder.build(WoldUIRuntime.instance().tokens.derive(all))


# generated, keep it out of the .tscn
func _validate_property(property: Dictionary) -> void:
	if property.name == "theme":
		property.usage &= ~PROPERTY_USAGE_STORAGE
