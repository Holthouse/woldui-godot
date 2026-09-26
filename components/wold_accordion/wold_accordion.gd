@tool
class_name WoldAccordion
extends VBoxContainer
## A stack of WoldCollapsibles (its children) with lines between them. One
## open at a time unless `multiple`.

signal item_toggled(index: int, open: bool)

## Any number open at once.
@export var multiple := false
## With one-at-a-time, whether the open one can be closed again (all shut).
@export var collapsible := true


func _ready() -> void:
	child_entered_tree.connect(_hook)
	for child in get_children():
		_hook(child)


## The collapsibles, in order.
func items() -> Array[WoldCollapsible]:
	var out: Array[WoldCollapsible] = []
	for child in get_children():
		if child is WoldCollapsible and not child.is_queued_for_deletion():
			out.append(child)
	return out


func _hook(child: Node) -> void:
	if child is WoldCollapsible and not child.toggled.is_connected(_on_item):
		child.toggled.connect(_on_item.bind(child))


func _on_item(open: bool, item: WoldCollapsible) -> void:
	if open and not multiple:
		for other in items():
			if other != item and other.open:
				other.open = false
	if not open and not multiple and not collapsible and not items().any(func(i): return i.open):
		# can't close the last one; put it back
		item.set_deferred(&"open", true)
		return
	item_toggled.emit(items().find(item), open)
