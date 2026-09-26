@tool
extends WoldCollapsible
## Fills its own %Content: one row per stat, rebuilt when `stats` changes.

@export var stats: Dictionary[String, String] = {}:
	set(v):
		stats = v
		_refresh()


func _wold_refresh() -> void:
	var content := %Content as Node
	for child in content.get_children():
		content.remove_child(child)
		child.queue_free()
	for key in stats:
		var row := HBoxContainer.new()
		row.theme_type_variation = &"RowSm"
		var name_label := Label.new()
		name_label.text = key
		name_label.theme_type_variation = &"Muted"
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(name_label)
		var value := Label.new()
		value.text = stats[key]
		row.add_child(value)
		content.add_child(row)
