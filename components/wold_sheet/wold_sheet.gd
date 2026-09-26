@tool
class_name WoldSheet
extends WoldDialog
## A panel that slides in from an edge of the screen over a scrim: an
## inventory, a city screen, a mobile-style settings drawer. It's a
## WoldDialog underneath, so title / message / %Content / %Actions, the focus
## trap, Esc, scrim clicks and open() / close() / closed all work the same.

enum Edge { RIGHT, LEFT, BOTTOM, TOP }

const _STYLES := ["SheetRight", "SheetLeft", "SheetBottom", "SheetTop"]

@export var edge: Edge = Edge.RIGHT:
	set(v):
		edge = v
		_refresh()
## Width for a side sheet, height for a top / bottom one.
@export_range(160, 1600) var extent := 380:
	set(v):
		extent = v
		_refresh()


func _refresh() -> void:
	super()
	if not is_node_ready():
		return
	var panel := %Panel as PanelContainer
	panel.theme_type_variation = StringName(_STYLES[edge])
	# full length along the edge, `extent` deep
	var side := edge == Edge.LEFT or edge == Edge.RIGHT
	panel.custom_minimum_size = Vector2(extent, 0) if side else Vector2(0, extent)
	# by hand: the presets keep stale offsets, and it has to grow away from
	# its edge when the content is taller than `extent`
	var e := float(extent)
	match edge:
		Edge.RIGHT:
			_pin(panel, [1, 0, 1, 1], [-e, 0, 0, 0])
			panel.grow_horizontal = GROW_DIRECTION_BEGIN
		Edge.LEFT:
			_pin(panel, [0, 0, 0, 1], [0, 0, e, 0])
			panel.grow_horizontal = GROW_DIRECTION_END
		Edge.BOTTOM:
			_pin(panel, [0, 1, 1, 1], [0, -e, 0, 0])
			panel.grow_vertical = GROW_DIRECTION_BEGIN
		Edge.TOP:
			_pin(panel, [0, 0, 1, 0], [0, 0, 0, e])
			panel.grow_vertical = GROW_DIRECTION_END


# anchors and offsets as [left, top, right, bottom]
func _pin(c: Control, anchors: Array, offsets: Array) -> void:
	for i in 4:
		c.set_anchor(i, anchors[i])
	for i in 4:
		c.set_offset(i, offsets[i])


## Which way it comes in from, as an offset of its own depth.
func slide_offset() -> Vector2:
	match edge:
		Edge.RIGHT:
			return Vector2(extent, 0)
		Edge.LEFT:
			return Vector2(-extent, 0)
		Edge.BOTTOM:
			return Vector2(0, extent)
	return Vector2(0, -extent)


func _wold_panel_in() -> WoldMotionPreset:
	var p := WoldMotionPreset.new()
	p.duration = WoldMotionPreset.Duration.BASE
	p.from_alpha = 1.0
	p.from_offset = slide_offset()
	return p


func _wold_panel_out() -> WoldMotionPreset:
	var p := _wold_panel_in()
	p.easing = WoldMotionPreset.Easing.MOVE
	return p
