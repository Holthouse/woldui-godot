extends "res://addons/woldui/tests/wold_test_base.gd"
## WoldSheet: edges and sizes, the slide, and the dialog behaviour it inherits.

const SCENE := "res://addons/woldui/components/wold_sheet/wold_sheet.tscn"

var stage: Control


func _run() -> void:
	get_root().size = Vector2i(1280, 720)
	stage = Control.new()
	stage.size = Vector2(1280, 720)
	stage.theme = WoldThemeBuilder.build(tokens())
	get_root().add_child(stage)
	await _right()
	await _slide()
	await _other_edges()
	await _dialog_bits()
	await _stacked()
	var city: WoldSheet = load("res://addons/woldui/gallery/examples/city_sheet.tscn").instantiate()
	stage.add_child(city)
	await _frames()
	check(city.get_node("%Content").get_child_count() == 3 and city.free_on_close and city.confirm_text == "", "CitySheet lists its buildings and just has Close")
	city.queue_free()
	finish(17)


func _sheet() -> WoldSheet:
	var s: WoldSheet = load(SCENE).instantiate()
	stage.add_child(s)
	return s


func _frames() -> void:
	await process_frame
	await process_frame


func _right() -> void:
	WoldUIRuntime.instance().reduced_motion = true
	var s := _sheet()
	await _frames()
	check(not s.visible, "closed until opened")
	s.open()
	await _frames()
	var r := (s.get_node("%Panel") as Control).get_global_rect()
	check(s.visible and is_equal_approx(r.end.x, 1280.0) and is_equal_approx(r.size.y, 720.0) and is_equal_approx(r.size.x, 380.0), "RIGHT: full height against the right edge, extent wide (%s)" % r)
	var sb := (s.get_node("%Panel") as Control).get_theme_stylebox("panel") as StyleBoxFlat
	check(sb.corner_radius_top_right == 0 and sb.corner_radius_top_left > 0, "square on its edge, round on the open side")
	check(s.get_node("%Cancel").has_focus(), "focus moves in")
	s.close()
	WoldUIRuntime.instance().reduced_motion = false
	s.queue_free()


func _slide() -> void:
	WoldUIRuntime.instance().reduced_motion = false
	var s := _sheet()
	await _frames()
	s.open()
	await process_frame
	await process_frame
	var panel := s.get_node("%Panel") as Control
	check(panel.offset_transform_position.x > 0.0, "it slides in from the right (at %.0f)" % panel.offset_transform_position.x)
	await create_timer(tokens().duration_base + 0.15).timeout
	check(panel.offset_transform_position == Vector2.ZERO, "and settles against the edge")
	s.close()
	await process_frame
	await process_frame
	check(panel.offset_transform_position.x > 0.0, "closing slides it back out")
	await create_timer(tokens().duration_base + 0.15).timeout
	s.queue_free()


func _other_edges() -> void:
	WoldUIRuntime.instance().reduced_motion = true
	var s := _sheet()
	s.edge = WoldSheet.Edge.LEFT
	await _frames()
	s.open()
	await _frames()
	var r := (s.get_node("%Panel") as Control).get_global_rect()
	check(r.position.x == 0.0 and s.slide_offset().x < 0.0 and s.get_node("%Panel").theme_type_variation == &"SheetLeft", "LEFT: against the left edge, comes in from the left")
	s.close()
	s.edge = WoldSheet.Edge.BOTTOM
	s.extent = 260
	s.open()
	await _frames()
	r = (s.get_node("%Panel") as Control).get_global_rect()
	check(is_equal_approx(r.size.x, 1280.0) and is_equal_approx(r.size.y, 260.0) and is_equal_approx(r.end.y, 720.0), "BOTTOM: full width, extent tall (%s)" % r)
	s.close()
	WoldUIRuntime.instance().reduced_motion = false
	s.queue_free()


func _dialog_bits() -> void:
	WoldUIRuntime.instance().reduced_motion = true
	var before := Button.new()
	stage.add_child(before)
	var s := _sheet()
	await _frames()
	before.grab_focus()
	var results := []
	s.closed.connect(func(r): results.append(r))
	s.open()
	await _frames()
	var e := InputEventAction.new()
	e.action = &"ui_cancel"
	e.pressed = true
	get_root().push_input(e)
	await _frames()
	check(not s.is_open and results == ["cancel"], "Esc closes it, like a dialog")
	check(before.has_focus(), "and focus goes back")
	s.open()
	await _frames()
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	s.get_node("%Scrim").gui_input.emit(click)
	check(not s.is_open, "a click on the scrim closes it")
	s.open()
	await _frames()
	var stray := Button.new()
	stage.add_child(stray)
	stray.grab_focus()
	await _frames()
	check(s.get_node("%Panel").is_ancestor_of(get_root().gui_get_focus_owner()), "focus can't leave while it's open")
	s.close()
	WoldUIRuntime.instance().reduced_motion = false
	before.queue_free()
	stray.queue_free()
	s.queue_free()


# a confirm dialog opened from inside a sheet: two focus traps at once
func _stacked() -> void:
	WoldUIRuntime.instance().reduced_motion = true
	# dialog first in the tree, so the sheet sees input first: only being on
	# top may decide who answers Esc
	var d: WoldDialog = load("res://addons/woldui/components/wold_dialog/wold_dialog.tscn").instantiate()
	stage.add_child(d)
	var s := _sheet()
	await _frames()
	s.open()
	await _frames()
	d.open()
	for i in 4:
		await process_frame
	check(d.get_node("%Panel").is_ancestor_of(get_root().gui_get_focus_owner()), "the dialog on top keeps focus, the sheet under it doesn't pull it back")
	var e := InputEventAction.new()
	e.action = &"ui_cancel"
	e.pressed = true
	get_root().push_input(e)
	await _frames()
	check(not d.is_open and s.is_open, "Esc closes only the top one")
	await _frames()
	check(s.get_node("%Panel").is_ancestor_of(get_root().gui_get_focus_owner()), "and focus is back in the sheet")
	s.close()
	WoldUIRuntime.instance().reduced_motion = false
	s.queue_free()
	d.queue_free()
