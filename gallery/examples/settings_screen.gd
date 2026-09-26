@tool
extends WoldScreen
## Example screen, inherits wold_screen.tscn. back button + a first focus for pads.


func _ready() -> void:
	super()
	if not Engine.is_editor_hint():
		%Back.pressed.connect(func(): exit(true))
