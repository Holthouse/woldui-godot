extends "res://addons/woldui/tests/wold_test_base.gd"
## motion/transitions/feedback: end states, containers, reduced motion, sounds, input mode.

var ui: WoldUIRuntime
var stage: Control


func _run() -> void:
	ui = WoldUIRuntime.instance()
	await process_frame
	stage = Control.new()
	stage.theme = WoldThemeBuilder.build(tokens())
	get_root().add_child(stage)
	_presets()
	await _appear_and_disappear()
	await _inside_a_container()
	await _reduced_motion()
	await _pulse_speed()
	await _stagger()
	await _count_and_press()
	await _nudge()
	await _sequences()
	await _transition()
	_input_mode()
	_sounds()
	await _feedback()
	await _touch_feedback()
	ui.reduced_motion = false
	ui.sound_enabled = true
	finish(77)


func _card() -> PanelContainer:
	var c := PanelContainer.new()
	c.custom_minimum_size = Vector2(120, 40)
	stage.add_child(c)
	return c


func _presets() -> void:
	var names := WoldMotion.preset_names()
	for n in ["appear", "disappear", "item", "screen_enter", "screen_exit", "toast_in", "toast_out", "dialog_in", "dialog_out"]:
		check(names.has(n) and WoldMotion.preset(n) is WoldMotionPreset, "the bundled preset '%s' loads" % n)
	var own := WoldMotionPreset.new()
	ui.tokens = tokens().derive({})
	ui.tokens.motion_presets = {"appear": own}
	check(WoldMotion.preset("appear") == own, "a game's motion_presets entry replaces a bundled preset")
	ui.tokens = tokens()


func _appear_and_disappear() -> void:
	var c := _card()
	c.visible = false
	var p := WoldMotion.preset("appear")
	var tw := WoldMotion.appear(c)
	check(c.visible, "appear shows the node")
	check(c.modulate.a == p.from_alpha and c.offset_transform_position == p.from_offset, "appear starts from the preset's from-state")
	check(c.offset_transform_enabled and c.offset_transform_visual_only, "motion uses the visual-only offset transform")
	await tw.finished
	check(is_equal_approx(c.modulate.a, 1.0) and c.offset_transform_position == Vector2.ZERO and c.offset_transform_scale == Vector2.ONE, "appear ends at rest")

	var out := WoldMotion.disappear(c)
	await out.finished
	await process_frame
	check(not c.visible, "disappear hides the node at the end")
	check(c.modulate.a == 1.0 and c.offset_transform_position == Vector2.ZERO, "and leaves it at rest for next time")

	# new motion replaces the old one, no fighting
	c.visible = true
	WoldMotion.disappear(c)
	var back := WoldMotion.appear(c)
	await back.finished
	await create_timer(0.3).timeout
	check(c.visible and is_equal_approx(c.modulate.a, 1.0), "appear right after disappear wins; the node stays visible")

	var gone := _card()
	await WoldMotion.disappear(gone, null, true).finished
	await process_frame
	check(not is_instance_valid(gone), "disappear(then_free) frees the node")
	c.queue_free()


func _inside_a_container() -> void:
	var box := VBoxContainer.new()
	stage.add_child(box)
	var first := Button.new()
	first.custom_minimum_size = Vector2(100, 30)
	box.add_child(first)
	var moving := Button.new()
	moving.custom_minimum_size = Vector2(100, 30)
	box.add_child(moving)
	await process_frame
	var rest_rect := moving.get_rect()
	var slow := WoldMotionPreset.new()
	slow.duration = WoldMotionPreset.Duration.CUSTOM
	slow.custom_seconds = 0.5
	slow.from_offset = Vector2(0, 20)
	WoldMotion.appear(moving, slow)
	await create_timer(0.1).timeout
	box.queue_sort()
	await process_frame
	check(moving.offset_transform_position.y > 0.0, "a container re-sort does not cancel the motion (offset %s)" % moving.offset_transform_position)
	check(moving.get_rect() == rest_rect and first.get_rect().position == Vector2.ZERO, "the layout never moves while a node animates")
	WoldMotion.stop(moving)
	check(moving.offset_transform_position == Vector2.ZERO, "stop puts a node at rest")
	box.queue_free()


func _reduced_motion() -> void:
	ui.reduced_motion = true
	var c := _card()
	c.visible = false
	var tw := WoldMotion.appear(c)
	check(c.visible and c.modulate.a == 1.0 and c.offset_transform_position == Vector2.ZERO, "reduced motion: appear is at its end state in the same frame")
	await tw.finished
	check(true, "reduced motion: the tween still finishes, so await works")
	WoldMotion.disappear(c)
	check(not c.visible, "reduced motion: disappear hides at once")
	c.visible = true
	WoldMotion.pulse(c)
	await process_frame
	check(c.modulate.a == 1.0, "reduced motion: pulse keeps the node still and visible")
	var label := Label.new()
	stage.add_child(label)
	WoldMotion.count_to(label, 0, 500)
	check(label.text == "500", "reduced motion: count_to shows the final number at once")
	ui.reduced_motion = false
	c.queue_free()
	label.queue_free()


func _pulse_speed() -> void:
	var c := _card()
	var t0 := Time.get_ticks_msec()
	var tw := WoldMotion.pulse(c, 0.4, 1, 0.1)
	await tw.finished
	var quick := Time.get_ticks_msec() - t0
	check(quick < 700, "pulse takes its half-cycle from seconds (one loop took %d ms; the default is about 1440)" % quick)
	t0 = Time.get_ticks_msec()
	tw = WoldMotion.pulse(c, 0.4, 1, 1.0)
	await tw.finished
	var slow := Time.get_ticks_msec() - t0
	check(slow > 1700, "a longer seconds slows the pulse (one loop took %d ms)" % slow)
	tw = WoldMotion.pulse(c, 0.0, 1, 0.1, 0.5)
	await create_timer(0.35).timeout
	check(c.modulate.a == 0.0, "pulse waits at low_alpha for hold seconds (alpha %.2f mid-hold)" % c.modulate.a)
	await tw.finished
	check(c.modulate.a == 1.0, "and is back at full after the hold")
	c.queue_free()


func _stagger() -> void:
	var p := WoldMotionPreset.new()
	p.duration = WoldMotionPreset.Duration.CUSTOM
	p.custom_seconds = 0.1
	p.stagger = 0.3
	var cards := [_card(), _card(), _card()]
	var last := WoldMotion.stagger(cards, p)
	await create_timer(0.2).timeout
	check(is_equal_approx(cards[0].modulate.a, 1.0), "stagger: the first item is in")
	check(cards[2].modulate.a < 0.5, "stagger: the last item is still waiting (alpha %.2f)" % cards[2].modulate.a)
	await last.finished
	check(is_equal_approx(cards[2].modulate.a, 1.0), "stagger: the last item arrives")
	for c in cards:
		c.queue_free()


func _count_and_press() -> void:
	var label := Label.new()
	stage.add_child(label)
	var tw := WoldMotion.count_to(label, 0, 250, "%d gold", 0.2)
	await create_timer(0.08).timeout
	var mid := label.text
	await tw.finished
	check(label.text == "250 gold", "count_to ends on the exact number with its format")
	check(mid != "250 gold" and mid.ends_with(" gold"), "count_to passes through the numbers on the way (%s)" % mid)

	var b := Button.new()
	stage.add_child(b)
	WoldMotion.press(b)
	await create_timer(tokens().duration_instant * 0.8).timeout
	check(b.offset_transform_scale.x < 1.0, "press dips the button")
	await create_timer(0.4).timeout
	check(is_equal_approx(b.offset_transform_scale.x, 1.0), "press springs back to rest")
	label.queue_free()
	b.queue_free()


func _nudge() -> void:
	var c := _card()
	var tw := WoldMotion.nudge(c, Vector2(12, 0))
	check(c.offset_transform_position.x > 0.0 and c.modulate.a < 1.0, "nudge starts off to the side, faded")
	await tw.finished
	check(c.offset_transform_position == Vector2.ZERO and is_equal_approx(c.modulate.a, 1.0), "and settles at rest")
	ui.reduced_motion = true
	WoldMotion.nudge(c, Vector2(-12, 0))
	check(c.offset_transform_position == Vector2.ZERO and c.modulate.a == 1.0, "reduced motion: nudge doesn't move it")
	ui.reduced_motion = false
	c.queue_free()


func _transition() -> void:
	var a := _card()
	var b := _card()
	b.visible = false
	var tw := WoldTransition.swap(a, b)
	await tw.finished
	await create_timer(0.4).timeout
	check(not a.visible and b.visible, "swap: the old screen leaves, the new one arrives")
	check(is_equal_approx(b.modulate.a, 1.0), "swap: the new screen ends at rest")
	a.queue_free()
	b.queue_free()


func _input_mode() -> void:
	var seen := []
	var on_change := func(mode): seen.append(mode)
	ui.input_mode_changed.connect(on_change)
	var mouse := InputEventMouseButton.new()
	mouse.pressed = true
	ui.note_input(mouse)
	var pad := InputEventJoypadButton.new()
	pad.pressed = true
	ui.note_input(pad)
	check(ui.input_mode == WoldUIRuntime.InputMode.PAD, "a pad button switches to PAD")
	check(ui.is_focus_navigating(), "PAD counts as focus navigation")
	ui.note_input(mouse)
	var drift := InputEventJoypadMotion.new()
	drift.axis_value = 0.1
	ui.note_input(drift)
	check(ui.input_mode == WoldUIRuntime.InputMode.MOUSE, "stick drift under the deadzone is not the player picking up the pad")
	var key := InputEventKey.new()
	key.pressed = true
	ui.note_input(key)
	check(ui.input_mode == WoldUIRuntime.InputMode.KEYBOARD, "a key switches to KEYBOARD")
	check(seen.has(WoldUIRuntime.InputMode.PAD) and seen.has(WoldUIRuntime.InputMode.KEYBOARD), "input_mode_changed fires on each switch")
	var touch := InputEventScreenTouch.new()
	touch.pressed = true
	ui.note_input(touch)
	check(ui.input_mode == WoldUIRuntime.InputMode.TOUCH and not ui.is_focus_navigating(), "a touch switches to TOUCH, which isn't focus navigation")
	# what Godot makes up from a tap for controls that only know the mouse
	var emulated := InputEventMouseButton.new()
	emulated.pressed = true
	emulated.device = InputEvent.DEVICE_ID_EMULATION
	ui.note_input(emulated)
	check(ui.input_mode == WoldUIRuntime.InputMode.TOUCH, "the mouse clicks a tap turns into don't switch it back")
	ui.input_mode_changed.disconnect(on_change)
	ui.note_input(mouse)


func _sounds() -> void:
	var builtin := WoldSounds.builtin()
	for slot in WoldSoundSet.SLOTS:
		var s := builtin.stream(slot) as AudioStreamWAV
		check(s != null and s.get_length() > 0.005 and s.get_length() < 0.3, "built-in '%s' is a short sound (%.3f s)" % [slot, s.get_length() if s else 0.0])
	ui.last_sound = ""
	ui.play("click")
	check(ui.last_sound == "click", "play() plays a built-in sound when the game set none")
	ui.tokens = tokens().derive({"use_builtin_sounds": false})
	ui.last_sound = ""
	ui.play("click")
	check(ui.last_sound == "", "use_builtin_sounds off: an empty slot stays silent")
	var own := WoldSoundSet.new()
	own.click = WoldSounds.tone(440.0, 440.0, 0.05, 0.2)
	ui.play("click", own)
	check(ui.last_sound == "click", "a component's own sound set is used")
	ui.tokens = tokens()
	ui.sound_enabled = false
	ui.last_sound = ""
	ui.play("click")
	check(ui.last_sound == "", "the player's sound setting silences everything")
	ui.sound_enabled = true


func _feedback() -> void:
	var host := VBoxContainer.new()
	stage.add_child(host)
	var plain := Button.new()
	host.add_child(plain)
	var confirm := Button.new()
	confirm.set_meta("wold_sound", "confirm")
	host.add_child(confirm)
	var skipped := Button.new()
	skipped.set_meta("wold_feedback", false)
	host.add_child(skipped)
	var fb := WoldFeedback.new()
	host.add_child(fb)
	await process_frame
	var later := Button.new()
	host.add_child(later)
	await process_frame
	check(plain.has_meta(WoldFeedback._WIRED) and later.has_meta(WoldFeedback._WIRED), "feedback wires existing buttons and ones added later")
	check(not skipped.has_meta(WoldFeedback._WIRED), "wold_feedback = false opts a button out")

	ui.last_sound = ""
	plain.pressed.emit()
	check(ui.last_sound == "click", "a pressed button clicks")
	confirm.pressed.emit()
	check(ui.last_sound == "confirm", "wold_sound metadata picks the button's sound")
	plain.button_down.emit()
	await create_timer(tokens().duration_instant * 0.8).timeout
	check(plain.offset_transform_scale.x < 1.0, "a pressed button dips")

	ui.last_sound = ""
	ui.note_input(InputEventMouseButton.new())
	plain.focus_entered.emit()
	check(ui.last_sound == "", "focus from a mouse click makes no focus sound")
	var key := InputEventKey.new()
	key.pressed = true
	ui.note_input(key)
	plain.focus_entered.emit()
	check(ui.last_sound == "focus", "focus moved by keyboard or pad plays the focus sound")

	plain.disabled = true
	ui.last_sound = ""
	var click := InputEventMouseButton.new()
	click.pressed = true
	click.button_index = MOUSE_BUTTON_LEFT
	plain.gui_input.emit(click)
	check(ui.last_sound == "error", "clicking a disabled button answers with the error sound")
	ui.note_input(InputEventMouseButton.new())
	host.queue_free()


# a finger has no hover: a tap mustn't leave a button lifted or click twice
func _touch_feedback() -> void:
	var keep := ui.tokens
	ui.tokens = keep.derive({"hover_scale": 1.1})
	var holder := Control.new()
	stage.add_child(holder)
	var b := Button.new()
	holder.add_child(b)
	var fb := WoldFeedback.new()
	holder.add_child(fb)
	await process_frame
	ui.last_sound = ""
	b.mouse_entered.emit()
	await create_timer(0.2).timeout
	var lifted := b.offset_transform_scale.x > 1.0
	b.mouse_exited.emit()
	await create_timer(0.2).timeout
	var tap := InputEventScreenTouch.new()
	tap.pressed = true
	ui.note_input(tap)
	ui.last_sound = ""
	b.mouse_entered.emit()
	await create_timer(0.2).timeout
	check(lifted and b.offset_transform_scale.x == 1.0, "with a mouse hovering lifts a button, with a finger it doesn't")
	check(ui.last_sound != "hover", "and no hover sound on touch")
	ui.note_input(InputEventMouseButton.new())
	ui.tokens = keep
	holder.queue_free()


# a game's own timed sequence (a turn banner): fades honour reduced motion,
# holds don't, and a new sequence on the node kills the old one
func _sequences() -> void:
	var c := _card()
	c.modulate.a = 0.0
	var steps := []
	var tw := WoldMotion.sequence(c)
	WoldMotion.fade(tw, c, 1.0, 0.2)
	tw.tween_interval(0.2)
	tw.tween_callback(func(): steps.append("held"))
	WoldMotion.fade(tw, c, 0.0, 0.2)
	await create_timer(0.1).timeout
	check(c.modulate.a > 0.0 and c.modulate.a < 1.0 and steps.is_empty(), "a sequence fades at its own pace")
	await tw.finished
	check(c.modulate.a == 0.0 and steps == ["held"], "and runs its steps in order")
	ui.reduced_motion = true
	var quick := WoldMotion.sequence(c)
	WoldMotion.fade(quick, c, 1.0, 0.2)
	quick.tween_interval(0.25)
	await process_frame
	await process_frame
	check(c.modulate.a == 1.0 and quick.is_running(), "reduced motion: the fade is instant but the hold still holds")
	var newer := WoldMotion.sequence(c)
	check(not quick.is_valid() and newer.is_valid(), "a new sequence on the node kills the old one")
	newer.kill()
	ui.reduced_motion = false
	var s := _card()
	s.modulate.a = 0.4
	WoldMotion.slide(s, Vector2(-40, 0))
	check(s.offset_transform_position.x < 0.0, "slide starts off to the side")
	await create_timer(tokens().duration_base + 0.1).timeout
	check(s.offset_transform_position == Vector2.ZERO and s.modulate.a == 1.0, "and settles, finishing any fade it cut short")
	c.queue_free()
	s.queue_free()
