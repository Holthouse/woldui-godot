@tool
extends WoldButton
## Example of extending a component: inherited scene of wold_button.tscn,
## adds a `busy` prop, all through _wold_refresh().

## disabled + spinner at the end
@export var busy := false:
	set(value):
		busy = value
		_refresh()

## hook call count, the tests read this
var hook_calls := 0


func _wold_refresh() -> void:
	hook_calls += 1
	disabled = busy
	icon_end = "loader-circle" if busy else "arrow-right"
