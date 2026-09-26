@tool
extends WoldStepper
## Numbers mode bound to a real setting: WoldUI's own UI sound volume, shown as
## a percentage and stored in dB.


func _ready() -> void:
	if not Engine.is_editor_hint():
		var ui := WoldUIRuntime.instance()
		value = roundf(db_to_linear(ui.sound_volume_db) * 10.0) * 10.0
		value_changed.connect(func(v: float):
			ui.sound_volume_db = linear_to_db(maxf(v, 0.001) / 100.0)
			ui.play("click"))
	super()
