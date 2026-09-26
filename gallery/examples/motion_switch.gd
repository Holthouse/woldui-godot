@tool
extends WoldSwitch
## Switch bound to a setting: WoldUI's own Reduce motion preference. Starts
## from the saved value without sliding, writes back when flipped.


func _ready() -> void:
	if not Engine.is_editor_hint():
		set_pressed_no_signal(WoldUIRuntime.instance().reduced_motion)
		toggled.connect(func(on): WoldUIRuntime.instance().reduced_motion = on)
	super()
