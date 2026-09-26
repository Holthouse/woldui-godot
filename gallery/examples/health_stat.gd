@tool
extends WoldStat
## Example: wold_stat.tscn with a WoldMeter in the Extra slot, kept in sync
## via value_changed and _wold_refresh().

@onready var _meter: WoldMeter = %Extra.get_node("Meter")


func _ready() -> void:
	super()
	value_changed.connect(func(_old, _new): _sync())
	_sync()


func _wold_refresh() -> void:
	_sync()


func _sync() -> void:
	if _meter == null:
		return
	_meter.max_value = max_value if max_value > 0.0 else 100.0
	_meter.value = value
