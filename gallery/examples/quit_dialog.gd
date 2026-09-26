@tool
extends WoldDialog
## Example: wold_dialog.tscn plus a "Don't ask again" box in Content,
## read back in _wold_on_close().

## only valid once closed
var dont_ask_again := false


func _wold_on_close(result: String) -> void:
	dont_ask_again = result == "confirm" and (%Content.get_node("DontAsk") as CheckBox).button_pressed
