extends "res://addons/woldui/tests/wold_test_base.gd"
## WoldCheckbox: layout, states and their icons, indeterminate, radios, saved scenes.

const SCENE := "res://addons/woldui/components/wold_checkbox/wold_checkbox.tscn"

var stage: VBoxContainer


func _run() -> void:
	get_root().size = Vector2i(1280, 720)
	stage = VBoxContainer.new()
	stage.size = Vector2(600, 600)
	stage.theme = WoldThemeBuilder.build(tokens())
	get_root().add_child(stage)
	await _layout()
	await _states()
	await _indeterminate()
	await _radios()
	await _saved_scene()
	await _check_all()
	await _sizes_prop()
	finish(24)


func _box() -> WoldCheckbox:
	var c: WoldCheckbox = load(SCENE).instantiate()
	stage.add_child(c)
	return c


func _layout() -> void:
	var c := _box()
	await process_frame
	check(c is Button and c.toggle_mode and c.focus_mode == Control.FOCUS_ALL, "a checkbox is a focusable toggle Button")
	c.label = "Autosave"
	check(c.text == "" and (c.get_node("%Label") as Label).text == "Autosave", "the label lives in %Label")
	var box := c.indicator_rect()
	var content := c.get_node("%Content") as Control
	check(box.position.x >= 0.0 and box.end.x < content.position.x, "the box sits left of the text")
	check(box.size.x == tokens().icon_size_md, "the box is icon sized")
	var lbl := content.get_node("%Label") as Control
	check(absf(box.get_center().y - (content.position.y + lbl.position.y + lbl.size.y / 2.0)) < 1.0, "the box lines up with the label, not with label + description")
	c.label = ""
	c.description = ""
	await process_frame
	var pad := c.get_theme_stylebox("normal").get_minimum_size().y
	check(c.size.y >= box.size.y + pad, "with no text it still fits its box")
	c.queue_free()


func _states() -> void:
	var t := tokens()
	var c := _box()
	await process_frame
	check(c.icon_name() == "unchecked", "starts unchecked")
	c.button_pressed = true
	check(c.icon_name() == "checked", "checking it swaps the icon")
	check(c.get_theme_icon(c.icon_name(), &"CheckBox") == stage.theme.get_icon("checked", "CheckBox"), "the icons are the drawn ones from the theme")
	c.disabled = true
	await process_frame
	await process_frame
	check(c.icon_name() == "checked_disabled", "disabled has its own icon")
	check((c.get_node("%Label") as Label).get_theme_color("font_color") == t.role("text_disabled"), "and dims the label")
	c.queue_free()


func _indeterminate() -> void:
	var c := _box()
	await process_frame
	c.button_pressed = true
	c.indeterminate = true
	check(c.icon_name() == "indeterminate" and not c.button_pressed, "indeterminate shows the dash and clears the check")
	c.button_pressed = true
	check(not c.indeterminate and c.button_pressed and c.icon_name() == "checked", "a click from indeterminate checks it")
	c.queue_free()


func _radios() -> void:
	var group := ButtonGroup.new()
	var boxes: Array[WoldCheckbox] = []
	for i in 3:
		var c := _box()
		c.button_group = group
		boxes.append(c)
	await process_frame
	check(boxes[0].is_radio() and boxes[0].icon_name() == "radio_unchecked", "in a ButtonGroup it draws as a radio")
	boxes[1].button_pressed = true
	boxes[2].button_pressed = true
	check(boxes[2].icon_name() == "radio_checked" and not boxes[1].button_pressed, "radios pick one at a time")
	boxes[0].indeterminate = true
	check(boxes[0].icon_name() == "radio_unchecked", "radios have no mixed state")
	var fb := WoldFeedback.new()
	stage.add_child(fb)
	await process_frame
	check(boxes.all(func(b): return b.has_meta(WoldFeedback._WIRED)), "WoldFeedback wires checkboxes")
	fb.queue_free()
	for b in boxes:
		b.queue_free()


func _saved_scene() -> void:
	var host := VBoxContainer.new()
	stage.add_child(host)
	var c: WoldCheckbox = load(SCENE).instantiate()
	host.add_child(c)
	c.owner = host
	c.label = "Vsync"
	await process_frame
	var packed := PackedScene.new()
	packed.pack(host)
	var state := packed.get_state()
	var saved := {}
	for i in state.get_node_property_count(1):
		saved[state.get_node_property_name(1, i)] = true
	check(not saved.has("custom_minimum_size") and not saved.has("text") and not saved.has("theme_type_variation"), "derived state is not saved (saved: %s)" % [saved.keys()])
	var again := packed.instantiate()
	stage.add_child(again)
	await process_frame
	var copy := again.get_child(0) as WoldCheckbox
	check((copy.get_node("%Label") as Label).text == "Vsync" and copy.custom_minimum_size.y > 0.0, "it rebuilds from its props on load")
	host.queue_free()
	again.queue_free()


func _check_all() -> void:
	var boxes: Array[WoldCheckbox] = []
	for i in 3:
		boxes.append(_box())
	var all: WoldCheckbox = load("res://addons/woldui/gallery/examples/check_all.tscn").instantiate()
	stage.add_child(all)
	all.boxes = boxes
	await process_frame
	check(not all.button_pressed and not all.indeterminate, "CheckAll: none picked, unchecked")
	boxes[1].button_pressed = true
	check(all.indeterminate, "some picked, the dash")
	all.button_pressed = true
	check(boxes.all(func(b): return b.button_pressed) and all.button_pressed and not all.indeterminate, "clicking it from the dash picks them all")
	all.queue_free()
	for b in boxes:
		b.queue_free()


func _sizes_prop() -> void:
	var sizes := []
	for z in [WoldCheckbox.Size.SM, WoldCheckbox.Size.MD, WoldCheckbox.Size.LG]:
		var c: WoldCheckbox = load(SCENE).instantiate()
		c.toggle_size = z
		stage.add_child(c)
		await process_frame
		sizes.append(c.indicator_rect().size.x)
		if z == WoldCheckbox.Size.SM:
			check(c.theme_type_variation == &"CheckboxSm", "toggle_size SM picks CheckboxSm")
		c.queue_free()
	check(sizes[0] < sizes[1] and sizes[1] < sizes[2], "SM < MD < LG boxes (%s)" % [sizes])
