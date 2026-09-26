extends "res://addons/woldui/tests/wold_test_base.gd"
## WoldDialog: results/signals, Esc + scrim, modal focus, ask(), Content slot.

const SCENE := "res://addons/woldui/components/wold_dialog/wold_dialog.tscn"
const EXAMPLE := "res://addons/woldui/gallery/examples/quit_dialog.tscn"

var stage: Control
var ui: WoldUIRuntime


func _run() -> void:
	ui = WoldUIRuntime.instance()
	stage = Control.new()
	stage.size = Vector2(1280, 720)
	stage.theme = WoldThemeBuilder.build(tokens())
	get_root().add_child(stage)
	await _open_and_confirm()
	await _cancel_paths()
	await _modal_focus()
	await _props()
	await _ask()
	await _extension()
	await _small()
	await _freed_while_open()
	finish(33)


func _dialog() -> WoldDialog:
	var d: WoldDialog = load(SCENE).instantiate()
	stage.add_child(d)
	return d


func _open_and_confirm() -> void:
	var d := _dialog()
	await process_frame
	check(not d.visible, "a dialog starts hidden in the game")
	var events := []
	d.opened.connect(func(): events.append("opened"))
	d.confirmed.connect(func(): events.append("confirmed"))
	d.closed.connect(func(r): events.append("closed:" + r))
	ui.last_sound = ""
	d.open()
	check(d.visible and d.is_open, "open() shows it")
	check(ui.last_sound == "open", "opening plays the open sound")
	await process_frame
	check(d.get_node("%Confirm").has_focus(), "focus starts on the confirm button (keyboard / pad ready)")
	(d.get_node("%Confirm") as Button).pressed.emit()
	check(not d.is_open and events == ["opened", "confirmed", "closed:confirm"], "confirm emits confirmed and closed('confirm') (%s)" % [events])
	check(ui.last_sound == "close", "closing plays the close sound")
	await create_timer(0.5).timeout
	check(not d.visible, "and it hides once the close animation is over")
	d.queue_free()


func _cancel_paths() -> void:
	var d := _dialog()
	await process_frame
	var results := []
	d.closed.connect(func(r): results.append(r))
	d.open()
	var esc := InputEventKey.new()
	esc.keycode = KEY_ESCAPE
	esc.physical_keycode = KEY_ESCAPE
	esc.pressed = true
	get_root().push_input(esc)
	check(results == ["cancel"], "Esc (ui_cancel) cancels a closable dialog")
	await create_timer(0.4).timeout

	d.open()
	var click := InputEventMouseButton.new()
	click.pressed = true
	click.button_index = MOUSE_BUTTON_LEFT
	d.get_node("%Scrim").gui_input.emit(click)
	check(results == ["cancel", "cancel"], "a click on the scrim cancels")
	await create_timer(0.4).timeout

	d.closable = false
	d.open()
	get_root().push_input(esc)
	d.get_node("%Scrim").gui_input.emit(click)
	check(d.is_open, "a dialog that is not closable ignores Esc and the scrim")
	check(not d.get_node("%Close").visible, "and has no close button")
	d.close("custom")
	check(results.back() == "custom", "close() takes any result")
	d.queue_free()
	await create_timer(0.4).timeout


func _modal_focus() -> void:
	var behind := Button.new()
	behind.text = "Behind"
	stage.add_child(behind)
	var d := _dialog()
	await process_frame
	behind.grab_focus()
	d.open()
	await process_frame
	behind.grab_focus()
	await process_frame
	await process_frame
	var owner := get_root().gui_get_focus_owner()
	check(owner != behind and d.is_ancestor_of(owner), "focus cannot leave an open dialog (it went back to %s)" % (owner.name if owner else "nothing"))
	d.close("cancel")
	await process_frame
	check(behind.has_focus(), "closing gives focus back to where it was")
	behind.grab_focus()
	await process_frame
	check(behind.has_focus(), "a closed dialog no longer holds focus")
	behind.queue_free()
	d.queue_free()


func _props() -> void:
	var d := _dialog()
	await process_frame
	d.title = "Surrender?"
	d.message = ""
	d.icon = "flag"
	d.tone = WoldDialog.Tone.DANGER
	d.cancel_text = ""
	d.destructive = true
	check((d.get_node("%Title") as Label).text == "Surrender?", "title shows")
	check(not d.get_node("%Message").visible, "an empty message takes no space")
	check(d.get_node("%Icon").visible and (d.get_node("%Icon") as TextureRect).self_modulate == d.get_theme_color("font_color", "TextDanger"), "icon with its tone")
	check(not d.get_node("%Cancel").visible, "an empty cancel_text hides cancel")
	check((d.get_node("%Confirm") as WoldButton).shape == WoldButton.Shape.DANGER, "destructive makes confirm a danger button")
	d.width = 600
	check(d.get_node("%Panel").custom_minimum_size.x == 600, "width sets the panel width")

	ui.reduced_motion = true
	d.open()
	check(d.get_node("%Panel").modulate.a == 1.0, "reduced motion: the panel is there at once")
	d.close("cancel")
	await process_frame
	await process_frame
	check(not d.visible, "reduced motion: gone at once")
	ui.reduced_motion = false
	d.queue_free()


func _ask() -> void:
	var answer := [""]
	var asker := func(): answer[0] = await WoldDialog.ask(get_root(), "Trade 20 wood for 10 gold?", "", "Trade", "No")
	asker.call()
	await process_frame
	var layer := get_root().get_child(get_root().get_child_count() - 1)
	var d := layer.get_child(0) as WoldDialog if layer is CanvasLayer else null
	check(d != null and d.is_open, "ask() shows a dialog on its own top layer")
	check((d.get_node("%Confirm") as Button).text == "Trade", "with the given labels")
	(d.get_node("%Confirm") as Button).pressed.emit()
	await process_frame
	check(answer[0] == "confirm", "ask() returns the answer")
	await create_timer(0.6).timeout
	check(not is_instance_valid(layer), "and cleans up its layer after closing")


func _extension() -> void:
	var q: WoldDialog = load(EXAMPLE).instantiate()
	stage.add_child(q)
	await process_frame
	var box := q.get_node("%Content").get_node("DontAsk") as CheckBox
	check(box != null and (q.get_node("%Confirm") as WoldButton).shape == WoldButton.Shape.DANGER, "the example adds content to the slot and keeps its props")
	q.open()
	box.button_pressed = true
	(q.get_node("%Confirm") as Button).pressed.emit()
	check(q.dont_ask_again, "the hook reads the slot content on close")
	q.queue_free()


func _small() -> void:
	ui.reduced_motion = true
	var d := _dialog()
	d.dialog_size = WoldDialog.Size.SM
	await process_frame
	d.open()
	await process_frame
	await process_frame
	var panel := d.get_node("%Panel") as Control
	check(panel.size.x <= 340.0 + 1.0 and not d.get_node("%Close").visible, "SM: narrow, and no X")
	check((d.get_node("%Title") as Label).horizontal_alignment == HORIZONTAL_ALIGNMENT_CENTER and (d.get_node("%Message") as Label).horizontal_alignment == HORIZONTAL_ALIGNMENT_CENTER, "the text is centred")
	var confirm := d.get_node("%Confirm") as Control
	var cancel := d.get_node("%Cancel") as Control
	check(absf(confirm.size.x - cancel.size.x) < 1.0 and confirm.size.x > 100.0, "and the buttons share the width")
	d.close()
	ui.reduced_motion = false
	d.queue_free()


func _freed_while_open() -> void:
	ui.reduced_motion = true
	var gone := _dialog()
	var next := _dialog()
	await process_frame
	next.open()
	await process_frame
	# opened last, so it was on top
	gone.open()
	await process_frame
	gone.free()
	await process_frame
	var e := InputEventAction.new()
	e.action = &"ui_cancel"
	e.pressed = true
	get_root().push_input(e)
	await process_frame
	check(not next.is_open, "a dialog freed while open doesn't block the next one")
	ui.reduced_motion = false
	next.queue_free()
