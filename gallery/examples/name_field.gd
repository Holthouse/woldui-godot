@tool
extends WoldField
## A field that checks itself as you type: at least 3 letters, and not a
## name that's already taken.

const TAKEN := ["rivermouth", "highlands"]


func _ready() -> void:
	super()
	if not Engine.is_editor_hint():
		(control() as LineEdit).text_changed.connect(check_name)


func check_name(text: String) -> void:
	if text.strip_edges().length() < 3:
		error = "At least 3 letters."
	elif text.strip_edges().to_lower() in TAKEN:
		error = "Another kingdom already has that name."
	else:
		error = ""
