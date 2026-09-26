@tool
extends WoldMenu
## A WoldMenu that builds itself and reports what was picked as one signal,
## so the game only listens to `command`.

signal command(what: StringName)


func _ready() -> void:
	clear()
	item("Move", command.emit.bind(&"move"), "move", "M")
	item("Fortify", command.emit.bind(&"fortify"), "shield", "F")
	check("Auto-explore", false, func(on): command.emit(&"explore_on" if on else &"explore_off"))
	var send := submenu("Send to", "send")
	for city in ["Rivermouth", "Highlands"]:
		send.item(city, command.emit.bind(StringName("send_" + city.to_lower())))
	separator()
	danger("Disband", command.emit.bind(&"disband"), "trash", "Delete")
