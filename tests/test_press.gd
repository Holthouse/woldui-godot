extends "res://addons/woldui/tests/wold_test_base.gd"
## Press effects: which one a button gets, the clipped layer, cleanup.


@warning_ignore("missing_tool")
class Probe extends WoldPressEffect:
	var got: Array[Vector2] = []

	func _play(_button: Control, at: Vector2, layer: Control) -> void:
		got.append(at)
		release(layer, 0.05)


var stage: Control
var ui: WoldUIRuntime


func _run() -> void:
	ui = WoldUIRuntime.instance()
	ui.reduced_motion = false
	stage = VBoxContainer.new()
	stage.theme = WoldThemeBuilder.build(tokens())
	get_root().add_child(stage)
	stage.add_child(WoldFeedback.new())
	await _which()
	await _layer()
	await _custom()
	finish(12)


func _layers(b: Control) -> Array:
	return b.get_children(true).filter(func(n): return n.name == &"WoldPressLayer")


func _which() -> void:
	var fb: WoldFeedback = stage.get_child(0)
	var plain := Button.new()
	stage.add_child(plain)
	var off := Button.new()
	off.set_meta("wold_press_effect", "none")
	stage.add_child(off)
	var box := CheckBox.new()
	stage.add_child(box)
	var own: WoldButton = load("res://addons/woldui/components/wold_button/wold_button.tscn").instantiate()
	var flash := WoldPressFlash.new()
	own.press_effect = flash
	stage.add_child(own)
	var meta := Button.new()
	var probe := Probe.new()
	meta.set_meta("wold_press_effect", probe)
	stage.add_child(meta)
	await process_frame
	check(fb.press_effect_for(plain) == ui.tokens.press_effect and ui.tokens.press_effect is WoldRipple, "a plain button gets the tokens' effect (the bundled tokens ripple)")
	check(fb.press_effect_for(off) == null, "wold_press_effect = \"none\" turns it off")
	check(fb.press_effect_for(box) == null, "check boxes don't ripple")
	check(fb.press_effect_for(own) == flash, "WoldButton.press_effect wins over the tokens")
	check(fb.press_effect_for(meta) == probe, "so does a resource in the metadata")


func _layer() -> void:
	var b: WoldButton = load("res://addons/woldui/components/wold_button/wold_button.tscn").instantiate()
	b.look = WoldButton.Look.LIGHT
	b.text = "Ghost"
	stage.add_child(b)
	await process_frame
	b.button_down.emit()
	await process_frame
	var layers := _layers(b)
	check(layers.size() == 1 and layers[0].clip_children == CanvasItem.CLIP_CHILDREN_ONLY, "a press puts a clipped layer on the button")
	var mask: StyleBoxFlat = layers[0].get_theme_stylebox("panel")
	var real := b.get_theme_stylebox("normal")
	var radius: int = real.flat.corner_radius_top_left if "flat" in real else real.corner_radius_top_left
	check(mask.bg_color.a == 1.0 and mask.corner_radius_top_left == radius and radius > 0, "the mask is opaque with the button's corners, even for a see-through look")
	await create_timer((ui.tokens.press_effect as WoldRipple).seconds + 0.15).timeout
	check(_layers(b).is_empty(), "and it's gone once the ripple is done")
	ui.reduced_motion = true
	b.button_down.emit()
	await process_frame
	check(_layers(b).is_empty(), "reduced motion: no press effect")
	ui.reduced_motion = false
	b.queue_free()


func _custom() -> void:
	var b := Button.new()
	b.text = "Custom"
	var probe := Probe.new()
	b.set_meta("wold_press_effect", probe)
	stage.add_child(b)
	await process_frame
	var key := InputEventKey.new()
	key.pressed = true
	ui.note_input(key)
	b.button_down.emit()
	await process_frame
	check(probe.got.size() == 1 and probe.got[0].is_equal_approx(b.size / 2.0), "a subclass's _play runs; keyboard presses start from the middle")
	ui.note_input(InputEventMouseButton.new())
	b.button_down.emit()
	check(probe.got.size() == 2 and probe.got[1].is_equal_approx(b.get_local_mouse_position()), "mouse presses start where the mouse is")
	await create_timer(0.15).timeout
	check(_layers(b).is_empty(), "release() frees the layer")
	b.queue_free()
