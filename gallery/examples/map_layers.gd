@tool
extends WoldSegmented
## Multiple mode as a set of map layer toggles. `layers()` gives the names
## that are on.


func layers() -> PackedStringArray:
	var out := PackedStringArray()
	for i in pressed_items():
		out.append(options[i])
	return out
