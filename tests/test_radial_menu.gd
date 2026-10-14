extends "res://addons/woldui/tests/wold_test_base.gd"
## WoldRadialMenu: aiming with a stick, stepping, choosing, disabled slices, the mouse.

const SCENE := "res://addons/woldui/components/wold_radial_menu/wold_radial_menu.tscn"

var stage: Control


func _run() -> void:
	get_root().size = Vector2i(1280, 720)
	stage = Control.new()
	stage.size = Vector2(900, 600)
	stage.theme = WoldThemeBuilder.build(tokens())
	get_root().add_child(stage)
	await _scene()
	await _aim_and_choose()
	await _mouse()
	await _centre_and_caption()
	await _choose_glyph()
	finish(19)


func _menu(count: int) -> WoldRadialMenu:
	var m: WoldRadialMenu = load(SCENE).instantiate()
	var list := []
	for i in count:
		list.append({label = "Item %d" % i})
	m.items = list
	stage.add_child(m)
	return m


func _scene() -> void:
	var m: WoldRadialMenu = load(SCENE).instantiate()
	stage.add_child(m)
	await process_frame
	check(m.items.size() == 5 and m.center_title == "City", "the scene shows its preview slices on its own")
	check(m.size.x >= m.radius * 2.0, "it is as big as its ring")
	m.queue_free()


func _aim_and_choose() -> void:
	var m := _menu(4)
	await process_frame
	m.aim(Vector2(0, -1))
	check(m.highlighted == 0, "up picks the first slice, at the top")
	m.aim(Vector2(1, 0))
	check(m.highlighted == 1, "and they go round clockwise: right is the second of four")
	m.aim(Vector2(0.1, 0.1))
	check(m.highlighted == 1, "a stick at rest keeps the pick")
	m.step(1)
	m.step(1)
	m.step(1)
	check(m.highlighted == 0, "stepping wraps round")
	m.step(-1)
	check(m.highlighted == 3, "both ways")
	var got := []
	m.chosen.connect(func(i): got.append(i))
	check(m.choose() and got == [3], "choose() picks the highlighted slice")
	var list := m.items.duplicate()
	list[3] = {label = "Off", disabled = true}
	m.items = list
	m.highlighted = 3
	check(not m.choose() and got == [3], "a disabled slice can't be chosen")
	m.queue_free()


func _mouse() -> void:
	var m := _menu(4)
	await process_frame
	var move := InputEventMouseMotion.new()
	move.position = m.size / 2.0 + Vector2(-m.radius * 0.8, 0)
	m._gui_input(move)
	check(m.highlighted == 3, "hovering a slice highlights it (left is the fourth)")
	move.position = m.size / 2.0
	m._gui_input(move)
	check(m.highlighted == -1, "the centre highlights nothing")
	var got := []
	m.chosen.connect(func(i): got.append(i))
	move.position = m.size / 2.0 + Vector2(0, -m.radius * 0.8)
	m._gui_input(move)
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	click.position = move.position
	m._gui_input(click)
	check(got == [0], "a click chooses the slice under it")
	m.queue_free()


func _centre_and_caption() -> void:
	var m := _menu(3)
	m.center_title = "Worker"
	m.items = [{label = "Build Farm", hint = "Grows food.", details = [{text = "3"}, {text = "1"}]},
		{label = "Gather"}, {label = "Build", count = 4}]
	await process_frame
	check(m.center_text().title == "Worker" and m.center_text().hint == "", "at rest the centre says what the menu is for")
	m.aim(Vector2(0, -1))
	await process_frame
	var said := m.center_text()
	check(said.title == "Build Farm" and said.hint == "Grows food." and said.details == 2,
		"pointing at a choice puts its name, details and hint in the centre (%s)" % said)
	m.aim(Vector2(1, 0.4))
	await process_frame
	check(m.center_text().details == 0 and m.center_text().hint == "", "and a choice without them clears them")
	var bare_height := m.get_combined_minimum_size().y
	m.caption = "Site Commands"
	await process_frame
	await process_frame
	var plaque: Control = m._caption_panel
	check(plaque.visible and m.get_combined_minimum_size().y > bare_height, "a caption adds a plaque, and room for it")
	check(plaque.position.y >= m.ring_center().y + m.radius, "the plaque sits under the ring, clear of the choices")
	m.queue_free()


func _choose_glyph() -> void:
	var ui := WoldUIRuntime.instance()
	var was := ui.input_mode
	var m := _menu(4)
	m.choose_action = &"ui_accept"
	ui.input_mode = WoldUIRuntime.InputMode.PAD
	ui.input_mode_changed.emit(ui.input_mode)
	m.aim(Vector2(1, 0))
	await process_frame
	await process_frame
	var glyph := m.choose_prompt()
	var near := glyph.position.distance_to(m.item_position(1)) < m.item_radius * 3.0
	check(glyph.visible and near, "on a pad the pick button's glyph sits by the pointed-at choice")
	ui.input_mode = WoldUIRuntime.InputMode.MOUSE
	ui.input_mode_changed.emit(ui.input_mode)
	await process_frame
	await process_frame
	check(not glyph.visible, "a pointer clicks the choice itself, so no glyph")
	ui.input_mode = was
	ui.input_mode_changed.emit(ui.input_mode)
	m.queue_free()
