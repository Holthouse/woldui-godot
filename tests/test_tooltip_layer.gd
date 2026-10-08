extends "res://addons/woldui/tests/wold_test_base.gd"
## WoldTooltipLayer: wraps at the token width, sits centred under the control
## (above when there's no room), big controls anchor at the cursor, floating
## tips, a press hides it.

const LONG := "A tooltip that keeps going well past any sensible width, so it has to wrap onto a second line and probably a third one as well."

var ui: WoldUIRuntime
var layer: WoldTooltipLayer
var stage: Control


func _run() -> void:
	ui = WoldUIRuntime.instance()
	get_root().size = Vector2i(1280, 720)
	await process_frame
	get_root().theme = WoldThemeBuilder.build(tokens())
	stage = Control.new()
	stage.size = get_root().get_visible_rect().size
	get_root().add_child(stage)
	layer = WoldTooltipLayer.install(self, true)
	await process_frame
	check(layer != null and layer.is_inside_tree() and WoldTooltipLayer.current() == layer, "install puts one on the root")
	check(WoldTooltipLayer.install(self, true) == layer, "and a second install reuses it")
	await _width()
	await _placement()
	await _big()
	await _floating_and_press()
	finish(18)


func _target(pos: Vector2, tip: String) -> Button:
	var b := Button.new()
	b.text = "Spearman"
	b.position = pos
	b.size = Vector2(120, 40)
	b.tooltip_text = tip
	stage.add_child(b)
	return b


func _width() -> void:
	var cap := float(ui.tokens.tooltip_max_width)
	var b := _target(Vector2(400, 300), "Spear")
	layer.show_for(b)
	await process_frame
	var one_line := layer.panel().size.y
	check(layer.is_showing() and layer.panel().size.x < cap, "a short tip stays as narrow as its text (%s)" % layer.panel().size)
	layer.hide_tip()
	b.tooltip_text = LONG
	layer.show_for(b)
	await process_frame
	var label := layer.panel().get_child(0) as Label
	check(label.size.x <= cap + 1.0, "a long tip wraps at tokens.tooltip_max_width (%s, cap %d)" % [label.size.x, cap])
	check(layer.panel().size.y > one_line * 1.5, "onto more lines (%s vs %s)" % [layer.panel().size.y, one_line])
	layer.hide_tip()
	var was := ui.tokens.tooltip_max_width
	ui.tokens.tooltip_max_width = 200
	layer.show_for(b)
	await process_frame
	check(label.size.x <= 201.0, "the width follows the token (%s)" % label.size.x)
	ui.tokens.tooltip_max_width = was
	layer.hide_tip()
	b.queue_free()


func _placement() -> void:
	var b := _target(Vector2(400, 300), "Spearman: holds the line")
	layer.show_for(b)
	await process_frame
	var p := layer.panel().get_global_rect()
	var r := b.get_global_rect()
	check(absf(p.get_center().x - r.get_center().x) < 1.0, "centred on the control (%s vs %s)" % [p.get_center().x, r.get_center().x])
	check(p.position.y >= r.end.y, "and under it")
	layer.hide_tip()
	# a column-wide button (a menu entry) is still a button: under its middle,
	# not under the pointer
	b.size = Vector2(700, 50)
	var off_centre := InputEventMouseMotion.new()
	off_centre.position = Vector2(950, 320)
	off_centre.global_position = off_centre.position
	get_root().push_input(off_centre)
	layer.show_for(b)
	await process_frame
	check(absf(layer.panel().get_global_rect().get_center().x - b.get_global_rect().get_center().x) < 1.0,
			"a wide button's tip centres on the button, not the pointer (%s vs %s)" % [layer.panel().get_global_rect().get_center().x, b.get_global_rect().get_center().x])
	layer.hide_tip()
	# a child without a tooltip: the tip goes under the parent it came from
	b.size = Vector2(120, 40)
	var icon := Control.new()
	icon.position = Vector2(80, 8)
	icon.size = Vector2(24, 24)
	b.add_child(icon)
	await process_frame
	check(WoldTooltipLayer.owner_of(icon) == b, "a child's tooltip belongs to the parent that has it")
	layer.show_for(icon)
	await process_frame
	check(absf(layer.panel().get_global_rect().get_center().x - b.get_global_rect().get_center().x) < 1.0,
			"and the tip centres on that parent, not the child")
	icon.queue_free()
	layer.hide_tip()
	b.position = Vector2(400, 690)
	layer.show_for(b)
	await process_frame
	p = layer.panel().get_global_rect()
	check(p.end.y <= b.get_global_rect().position.y, "above it when there's no room below")
	layer.hide_tip()
	b.position = Vector2(1240, 300)
	b.tooltip_text = LONG
	layer.show_for(b)
	await process_frame
	check(layer.panel().get_global_rect().end.x <= 1280.0, "kept on screen at the edge")
	layer.hide_tip()
	b.queue_free()


func _big() -> void:
	var text := RichTextLabel.new()
	text.position = Vector2(100, 100)
	text.size = Vector2(900, 300)
	text.tooltip_text = "A word in the middle of a paragraph"
	stage.add_child(text)
	var move := InputEventMouseMotion.new()
	move.position = Vector2(700, 200)
	move.global_position = move.position
	get_root().push_input(move)
	await process_frame
	layer.show_for(text)
	await process_frame
	var p := layer.panel().get_global_rect()
	check(absf(p.get_center().x - 700.0) < 1.0 and p.position.y > 200.0,
			"over a paragraph the tip goes at the cursor, not its middle (%s)" % p)
	layer.hide_tip()
	text.queue_free()


func _floating_and_press() -> void:
	layer.show_floating("A unit on the map")
	await process_frame
	check(layer.is_showing(), "a floating tip shows without a control")
	layer.show_floating("")
	check(not layer.is_showing(), "and goes with an empty one")
	var b := _target(Vector2(400, 300), "Spear")
	layer.show_for(b)
	await process_frame
	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.pressed = true
	press.position = Vector2(460, 320)
	press.global_position = press.position
	get_root().push_input(press)
	await process_frame
	check(not layer.is_showing(), "a press hides it")
	check(layer.panel().mouse_filter == Control.MOUSE_FILTER_IGNORE, "and it never takes the mouse")
	b.queue_free()
