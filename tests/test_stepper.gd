extends "res://addons/woldui/tests/wold_test_base.gd"
## WoldStepper: options and numbers, keys / d-pad, ends and wrap, arrows, layout, saved scenes.

const SCENE := "res://addons/woldui/components/wold_stepper/wold_stepper.tscn"

var stage: VBoxContainer


func _run() -> void:
	get_root().size = Vector2i(1280, 720)
	stage = VBoxContainer.new()
	stage.size = Vector2(600, 600)
	stage.theme = WoldThemeBuilder.build(tokens())
	get_root().add_child(stage)
	await _options()
	await _numbers()
	await _keys()
	await _ends()
	await _layout()
	await _saved_scene()
	await _example()
	await _sides()
	finish(26)


func _stepper() -> WoldStepper:
	var s: WoldStepper = load(SCENE).instantiate()
	stage.add_child(s)
	return s


func _press(action: StringName) -> void:
	var e := InputEventAction.new()
	e.action = action
	e.pressed = true
	get_root().push_input(e)
	await process_frame


func _options() -> void:
	var s := _stepper()
	await process_frame
	check(s.value_text() == "Normal" and (s.get_node("%Value") as Label).text == "Normal", "shows the option at `value`")
	var seen := []
	s.value_changed.connect(func(v): seen.append(v))
	check(s.step_by(1) and s.value_text() == "Hard", "stepping right moves to the next option")
	check(seen == [2.0], "value_changed fires once (%s)" % [seen])
	s.value = 99
	check(s.value == 3.0, "value is clamped to the options")
	s.queue_free()


func _numbers() -> void:
	var s := _stepper()
	s.options = PackedStringArray()
	s.min_value = 0
	s.max_value = 100
	s.step = 25
	s.format = "%d%%"
	s.value = 50
	await process_frame
	check(s.value_text() == "50%", "no options: a formatted number (%s)" % s.value_text())
	s.step_by(1)
	check(s.value == 75.0, "numbers step by `step`")
	s.value = 130
	check(s.value == 100.0, "and clamp to the range")
	s.queue_free()


func _keys() -> void:
	var above := Button.new()
	stage.add_child(above)
	var s := _stepper()
	var below := Button.new()
	stage.add_child(below)
	await process_frame
	s.grab_focus()
	await _press(&"ui_right")
	check(s.value_text() == "Hard" and s.has_focus(), "right (key or d-pad) steps and keeps focus on the row")
	await _press(&"ui_left")
	await _press(&"ui_left")
	check(s.value_text() == "Easy", "left steps back")
	await _press(&"ui_down")
	check(below.has_focus(), "down still moves to the next row")
	s.value = 3
	s.pressed.emit()
	check(s.value_text() == "Easy", "accept on the last option goes round to the first")
	above.queue_free()
	below.queue_free()
	s.queue_free()


func _ends() -> void:
	var s := _stepper()
	s.value = 0
	await process_frame
	await process_frame
	check((s.get_node("%Prev") as Button).disabled and not (s.get_node("%Next") as Button).disabled, "at the start the left arrow is off")
	check(not s.step_by(-1) and s.value == 0.0, "and stepping past it does nothing")
	s.wrap = true
	await process_frame
	check(not (s.get_node("%Prev") as Button).disabled, "wrap turns it back on")
	check(s.step_by(-1) and s.value_text() == "Brutal", "and goes round to the end")
	(s.get_node("%Prev") as Button).pressed.emit()
	check(s.value_text() == "Hard", "the arrows step too")
	s.disabled = true
	await process_frame
	check(not s.step_by(1) and s.value_text() == "Hard", "disabled: nothing steps")
	check((s.get_node("%Value") as Label).get_theme_color("font_color") == tokens().role("text_disabled"), "and the value dims")
	s.queue_free()


func _layout() -> void:
	var s := _stepper()
	await process_frame
	var prev_x := (s.get_node("%Prev") as Control).position.x
	s.value = 0
	await process_frame
	await process_frame
	check(is_equal_approx((s.get_node("%Prev") as Control).position.x, prev_x), "the arrows don't move when the text changes length")
	check(s.focus_mode == Control.FOCUS_ALL and (s.get_node("%Prev") as Button).focus_mode == Control.FOCUS_NONE, "the row takes focus, the arrows don't")
	var fb := WoldFeedback.new()
	stage.add_child(fb)
	await process_frame
	check(s.has_meta(WoldFeedback._WIRED), "WoldFeedback wires it")
	fb.queue_free()
	s.queue_free()


func _saved_scene() -> void:
	var host := VBoxContainer.new()
	stage.add_child(host)
	var s: WoldStepper = load(SCENE).instantiate()
	host.add_child(s)
	s.owner = host
	s.value = 2
	await process_frame
	var packed := PackedScene.new()
	packed.pack(host)
	var state := packed.get_state()
	var saved := {}
	for i in state.get_node_property_count(1):
		saved[state.get_node_property_name(1, i)] = true
	check(not saved.has("custom_minimum_size") and not saved.has("theme_type_variation"), "derived state is not saved (saved: %s)" % [saved.keys()])
	var again := packed.instantiate()
	stage.add_child(again)
	await process_frame
	check(((again.get_child(0) as WoldStepper).get_node("%Value") as Label).text == "Hard", "it rebuilds with its value")
	host.queue_free()
	again.queue_free()


func _example() -> void:
	var ui := WoldUIRuntime.instance()
	ui.sound_volume_db = 0.0
	var s: WoldStepper = load("res://addons/woldui/gallery/examples/ui_volume.tscn").instantiate()
	stage.add_child(s)
	await process_frame
	var start := s.value_text()
	s.step_by(-1)
	check(start == "100%" and s.value_text() == "90%" and is_equal_approx(ui.sound_volume_db, linear_to_db(0.9)), "UiVolume shows the volume as a percentage and writes it back in dB")
	ui.sound_volume_db = 0.0
	s.queue_free()


func _click(at: Vector2) -> void:
	for down in [true, false]:
		var e := InputEventMouseButton.new()
		e.button_index = MOUSE_BUTTON_LEFT
		e.pressed = down
		e.position = at
		e.global_position = at
		get_root().push_input(e)
		await process_frame


# the arrows are small for a finger; the whole row is the target instead
func _sides() -> void:
	var s := _stepper()
	await process_frame
	await process_frame
	var r := s.get_global_rect()
	await _click(Vector2(r.position.x + 20, r.get_center().y))
	check(s.value_text() == "Easy", "a click or tap left of the value steps back (%s)" % s.value_text())
	await _click(Vector2(r.end.x - 4, r.get_center().y))
	await _click(Vector2(r.end.x - 4, r.get_center().y))
	check(s.value_text() == "Hard", "right of it steps on (%s)" % s.value_text())
	s.queue_free()
