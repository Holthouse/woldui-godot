@tool
extends WoldCheckbox
## "Select all" over a set of other checkboxes: checked when all are, the dash
## when only some are, and clicking it sets the lot.

@export var boxes: Array[WoldCheckbox] = []:
	set(v):
		boxes = v
		_watch()

var _syncing := false


func _ready() -> void:
	super()
	toggled.connect(_on_self_toggled)
	_watch()


func _watch() -> void:
	if not is_node_ready():
		return
	for b in boxes:
		if b and not b.toggled.is_connected(_sync):
			b.toggled.connect(_sync)
	_sync()


func _sync(_on := false) -> void:
	if _syncing:
		return
	var on := boxes.filter(func(b): return b and b.button_pressed).size()
	if on > 0 and on < boxes.size():
		indeterminate = true
	else:
		indeterminate = false
		set_pressed_no_signal(on > 0)
	queue_redraw()


func _on_self_toggled(_on: bool) -> void:
	_syncing = true
	for b in boxes:
		if b:
			b.button_pressed = button_pressed
	_syncing = false
