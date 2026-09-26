@tool
class_name WoldToggle
extends WoldButton
## A button that stays on: quiet when off, accent tint when on. For tool
## palettes and view options ("show grid", "bold"). `button_pressed` is the
## state, `toggled` the signal. Only two shapes mean anything here: ICON
## (square, for icon-only toggles) and anything else. Use `outline` for the edge.

@export var outline := false:
	set(v):
		outline = v
		_refresh()


func _init() -> void:
	super()
	toggle_mode = true


func style_name() -> StringName:
	if variant != "":
		return StringName(variant)
	return StringName("Toggle" + ("Outline" if outline else "") + ("Icon" if shape == Shape.ICON else "") + _SIZE_SUFFIX[button_size])


func _validate_property(property: Dictionary) -> void:
	super(property)
	if property.name == "toggle_mode":
		property.usage &= ~PROPERTY_USAGE_STORAGE
