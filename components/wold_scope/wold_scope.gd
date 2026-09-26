@tool
class_name WoldScope
extends MarginContainer
## Wrap a subtree in this to re-theme just that bit from a few token tweaks,
## e.g. a faction colour on one panel or a tighter radius on a side list.
## Builds a whole Theme off the global tokens + your overrides. Scopes nest:
## an inner one starts from the outer one's overrides and adds its own.

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


# moved under a different scope (or out of one)
func _notification(what: int) -> void:
	if what == NOTIFICATION_PARENTED and is_node_ready():
		rebuild.call_deferred()


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


## overrides() on top of every scope around this one, nearest wins.
func stacked_overrides() -> Dictionary:
	var outer := outer_scope()
	var all := outer.stacked_overrides() if outer else {}
	all.merge(overrides(), true)
	return all


## The nearest WoldScope above this one, or null.
func outer_scope() -> WoldScope:
	var n := get_parent()
	while n:
		if n is WoldScope:
			return n
		n = n.get_parent()
	return null


func rebuild() -> void:
	if not is_node_ready():
		return
	var all := stacked_overrides()
	if all.is_empty():
		theme = null
	else:
		theme = WoldThemeBuilder.build(WoldUIRuntime.instance().tokens.derive(all))
	# the scopes inside build on ours, so they go again too
	for inner in _inner_scopes(self):
		inner.rebuild()


# the next scopes down each branch; they handle their own insides
func _inner_scopes(node: Node) -> Array[WoldScope]:
	var out: Array[WoldScope] = []
	for child in node.get_children():
		if child is WoldScope:
			out.append(child)
		else:
			out.append_array(_inner_scopes(child))
	return out


# generated, keep it out of the .tscn
func _validate_property(property: Dictionary) -> void:
	if property.name == "theme":
		property.usage &= ~PROPERTY_USAGE_STORAGE
