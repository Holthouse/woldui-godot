extends "res://addons/woldui/tests/wold_test_base.gd"
## WoldScreen stack: push/pop, only the top one takes input, focus in and back.

const EXAMPLE := "res://addons/woldui/gallery/examples/settings_screen.tscn"
const BASE := "res://addons/woldui/components/wold_screen/wold_screen.tscn"

var ui: WoldUIRuntime
var stage: Control


func _run() -> void:
	ui = WoldUIRuntime.instance()
	get_root().size = Vector2i(1280, 720)
	get_root().theme = WoldThemeBuilder.build(tokens())
	stage = Control.new()
	stage.size = Vector2(1280, 720)
	get_root().add_child(stage)
	await _push_and_pop()
	await _back_and_focus()
	await _stacking()
	finish(16)


func _esc() -> InputEventKey:
	var e := InputEventKey.new()
	e.keycode = KEY_ESCAPE
	e.physical_keycode = KEY_ESCAPE
	e.pressed = true
	return e


func _push_and_pop() -> void:
	ui.last_sound = ""
	var s := WoldScreen.push(stage, EXAMPLE)
	await process_frame
	check(s.is_open and s.visible and s.get_parent().name == "WoldScreens", "push() puts the screen on the screen layer")
	check(ui.last_sound == "open", "entering plays the open sound")
	check(WoldScreen.top(stage) == s, "top() is the pushed screen")
	check(s.size == Vector2(1280, 720), "a screen fills the window")
	check(WoldScreen.pop(stage) and not s.is_open, "pop() closes the top screen")
	await create_timer(0.6).timeout
	check(not is_instance_valid(s), "and frees it after its exit")
	check(not WoldScreen.pop(stage), "pop() on an empty stack is harmless")


func _back_and_focus() -> void:
	var opener := Button.new()
	opener.text = "Settings"
	stage.add_child(opener)
	opener.grab_focus()
	var pad := InputEventJoypadButton.new()
	pad.pressed = true
	ui.note_input(pad)
	var s := WoldScreen.push(stage, EXAMPLE)
	await process_frame
	await process_frame
	var video := s.get_node("Center/Column/Rows/Video") as Control
	check(video.has_focus(), "first_focus is focused on enter, ready for the pad")
	var backs := []
	s.back_requested.connect(func(): backs.append(1))
	get_root().push_input(_esc())
	check(backs.size() == 1 and not s.is_open, "ui_cancel (Esc / B) goes back")
	await process_frame
	check(opener.has_focus(), "closing hands focus back to what opened it")
	await create_timer(0.6).timeout
	var stay: WoldScreen = load(BASE).instantiate()
	stay.auto_back = false
	stage.add_child(stay)
	stay.enter()
	get_root().push_input(_esc())
	check(stay.is_open, "auto_back off: back only emits back_requested")
	stay.exit(true)
	ui.note_input(InputEventMouseButton.new())
	opener.queue_free()
	await create_timer(0.6).timeout


func _stacking() -> void:
	var a := WoldScreen.push(stage, EXAMPLE)
	var b := WoldScreen.push(stage, EXAMPLE)
	await process_frame
	check(b.is_top() and not a.is_top(), "the newest screen is on top")
	get_root().push_input(_esc())
	check(not b.is_open and a.is_open, "back closes only the top screen")
	check(WoldScreen.top(stage) == a, "and the one below becomes the top")
	(a.get_node("%Back") as Button).pressed.emit()
	check(not a.is_open, "the example's Back button closes it")
	ui.reduced_motion = true
	var c := WoldScreen.push(stage, EXAMPLE)
	check(c.modulate.a == 1.0 and c.offset_transform_position == Vector2.ZERO, "reduced motion: a screen is simply there")
	ui.reduced_motion = false
	WoldScreen.pop(stage)
	await create_timer(0.6).timeout
