@tool
extends WoldVSlider
## A fader for WoldUI's own UI sound volume, 0 to 100, stored in dB.


func _ready() -> void:
	if not Engine.is_editor_hint():
		var ui := WoldUIRuntime.instance()
		set_value_no_signal(roundf(db_to_linear(ui.sound_volume_db) * 100.0))
		value_changed.connect(func(v: float): ui.sound_volume_db = linear_to_db(maxf(v, 0.1) / 100.0))
	super()
