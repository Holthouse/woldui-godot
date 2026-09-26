@tool
extends WoldCard
## A pick-one upgrade: selectable, in the "upgrade" group, with its cost as a
## badge in the %Action slot.

## 0 = free, no badge.
@export var cost := 0:
	set(v):
		cost = v
		_refresh()

var _badge: WoldBadge


func _wold_refresh() -> void:
	selectable = true
	card_group = &"upgrade"
	if cost > 0 and _badge == null:
		_badge = preload("res://addons/woldui/components/wold_badge/wold_badge.tscn").instantiate()
		_badge.icon = "coins"
		_badge.tone = WoldBadge.Tone.WARNING
		%Action.add_child(_badge)
	if _badge:
		_badge.text = str(cost)
		_badge.visible = cost > 0
