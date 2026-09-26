extends "res://addons/woldui/tests/wold_test_base.gd"
## toasts: notify(), auto-dismiss + hover pause, sticky, buttons, stacking, cap, collapse, position

const TOAST := "res://addons/woldui/components/wold_toast/wold_toast.tscn"

var ui: WoldUIRuntime


func _run() -> void:
	ui = WoldUIRuntime.instance()
	get_root().theme = WoldThemeBuilder.build(tokens())
	await _notify_and_auto_dismiss()
	await _hover_and_sticky()
	await _action_and_close()
	await _stacking()
	await _placement()
	_look()
	finish(26)


func _toaster() -> WoldToaster:
	return WoldToaster.find_or_create(get_root())


func _notify_and_auto_dismiss() -> void:
	ui.last_sound = ""
	var t := WoldToast.notify(get_root(), "Game saved", WoldToast.Tone.SUCCESS, "", 0.3)
	await process_frame
	var toaster := _toaster()
	check(toaster.get_parent() is CanvasLayer and toaster.toasts() == [t], "notify() makes a toaster on its own layer and shows the toast")
	check(WoldToast.notify(get_root(), "Again", 0, "", 0.3) and _toaster() == toaster, "a second notify() reuses the same toaster")
	check(ui.last_sound == "open", "a toast arriving plays the open sound")
	var slot := t.get_parent() as Control
	check(slot.custom_minimum_size.y > 0.0, "the toast takes room in the stack")
	await create_timer(0.3 + 0.5).timeout
	check(not is_instance_valid(t), "it leaves on its own after its duration, and is freed")
	await create_timer(0.3).timeout


func _hover_and_sticky() -> void:
	var t := WoldToast.notify(get_root(), "Hover me", 0, "", 0.3)
	await process_frame
	t.mouse_entered.emit()
	await create_timer(0.6).timeout
	check(is_instance_valid(t) and not t.is_leaving, "hovering pauses the timer")
	t.mouse_exited.emit()
	await create_timer(0.9).timeout
	check(not is_instance_valid(t), "leaving the toast lets the timer run out")

	var sticky := WoldToast.notify(get_root(), "Sticky", 0, "", 0.0)
	await create_timer(0.5).timeout
	check(is_instance_valid(sticky) and not sticky.is_leaving, "duration 0 stays until closed")
	check(not sticky.get_node("%Timer").visible, "and shows no timer bar")
	sticky.dismiss()
	await create_timer(0.6).timeout


func _action_and_close() -> void:
	var t := WoldToast.notify(get_root(), "Trade offer", WoldToast.Tone.ACCENT, "The Ants", 0.0)
	t.action_text = "View"
	var got := []
	t.action_pressed.connect(func(): got.append("action"))
	t.dismissed.connect(func(): got.append("dismissed"))
	await process_frame
	check(t.get_node("%Action").visible and (t.get_node("%Action") as Button).text == "View", "action_text shows an action button")
	(t.get_node("%Action") as Button).pressed.emit()
	check(got == ["action", "dismissed"], "the action emits action_pressed and dismisses")
	var c := WoldToast.notify(get_root(), "Close me", 0, "", 0.0)
	await process_frame
	(c.get_node("%Close") as Button).pressed.emit()
	check(c.is_leaving, "the close button dismisses")
	c.closable = false
	check(not c.get_node("%Close").visible, "closable off hides it")
	await create_timer(0.6).timeout


func _stacking() -> void:
	var toaster := _toaster()
	toaster.max_visible = 3
	var made := []
	for i in 5:
		made.append(WoldToast.notify(get_root(), "Toast %d" % i, 0, "", 0.0))
	await process_frame
	var live := toaster.toasts()
	check(live.size() == 3, "max_visible caps the stack (%d showing)" % live.size())
	check(live == [made[2], made[3], made[4]], "the oldest go first")
	var first_slot := (toaster.get_node("%Stack") as VBoxContainer).get_child(0)
	check(first_slot.get_child(0) == made[4], "top corners put the newest at the top")

	var leaving: WoldToast = made[3]
	var slot := leaving.get_parent() as Control
	var h := slot.custom_minimum_size.y
	leaving.dismiss()
	await create_timer(tokens().duration_fast + 0.05).timeout
	await create_timer(tokens().duration_fast * 0.5).timeout
	check(is_instance_valid(slot) and slot.custom_minimum_size.y < h, "a leaving toast's space closes up gradually (%.0f of %.0f)" % [slot.custom_minimum_size.y if is_instance_valid(slot) else -1.0, h])
	await create_timer(0.5).timeout
	check(not is_instance_valid(slot), "and the slot is freed")

	ui.reduced_motion = true
	var quick: WoldToast = made[4]
	var quick_slot := quick.get_parent()
	quick.dismiss()
	await process_frame
	await process_frame
	check(not is_instance_valid(quick_slot), "reduced motion: a dismissed toast is gone at once")
	ui.reduced_motion = false
	for t in toaster.toasts():
		t.dismiss()
	toaster.max_visible = 4
	await create_timer(0.6).timeout


func _placement() -> void:
	var toaster := _toaster()
	var view := toaster.get_viewport_rect().size
	var margin := float(tokens().space_xl)
	var stack := toaster.get_node("%Stack") as Control
	toaster.place = WoldToaster.Place.TOP_RIGHT
	await process_frame
	check(is_equal_approx(stack.get_global_rect().end.x, view.x - margin) and is_equal_approx(stack.global_position.y, margin), "TOP_RIGHT: the stack sits a margin in from the corner")
	toaster.place = WoldToaster.Place.BOTTOM_LEFT
	await process_frame
	check(is_equal_approx(stack.global_position.x, margin) and stack.alignment == BoxContainer.ALIGNMENT_END, "BOTTOM_LEFT: left edge, growing upwards")
	toaster.place = WoldToaster.Place.TOP_CENTER
	await process_frame
	check(is_equal_approx(stack.get_global_rect().get_center().x, view.x / 2.0), "TOP_CENTER: centred")
	toaster.place = WoldToaster.Place.TOP_RIGHT


func _look() -> void:
	var t: WoldToast = load(TOAST).instantiate()
	get_root().add_child(t)
	t.tone = WoldToast.Tone.DANGER
	t.icon = ""
	var icon := t.get_node("%Icon") as TextureRect
	check(icon.texture == tokens().icon("circle-alert"), "each tone has its own default icon (danger: circle-alert)")
	check(icon.self_modulate == t.get_theme_color("font_color", "TextDanger"), "in the tone's colour")
	check(t.get_node("%Timer").theme_type_variation == &"MeterDanger", "and a timer bar in that tone")
	t.title = ""
	check(not t.get_node("%Title").visible, "no title, no title line")
	t.queue_free()
