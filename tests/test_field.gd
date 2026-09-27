extends "res://addons/woldui/tests/wold_test_base.gd"
## WoldField: label / description / error, invalid borders, counter, label click, accessibility, saved scenes.

const SCENE := "res://addons/woldui/components/wold_field/wold_field.tscn"

var stage: VBoxContainer


func _run() -> void:
	get_root().size = Vector2i(1280, 720)
	stage = VBoxContainer.new()
	stage.size = Vector2(600, 600)
	stage.theme = WoldThemeBuilder.build(tokens())
	get_root().add_child(stage)
	await _parts()
	await _errors()
	await _counter()
	await _label_click()
	await _other_controls()
	await _saved_scene()
	await _example()
	await _horizontal()
	finish(26)


func _field(c: Control = null) -> WoldField:
	var edit := c if c else LineEdit.new()
	var f := WoldField.make(edit, "Kingdom name", "Shown to other players.")
	stage.add_child(f)
	return f


func _parts() -> void:
	var t := tokens()
	var f := _field()
	await process_frame
	check(f.control() is LineEdit, "make() puts the control in the slot")
	var lbl := f.get_node("%Label") as Label
	check(lbl.text == "Kingdom name" and lbl.get_theme_color("font_color") == t.role("text"), "the label shows")
	var d := f.get_node("%Description") as Label
	check(d.visible and d.get_theme_color("font_color") == t.role("text_muted"), "the description is muted, under the control")
	check(d.get_index() > f.get_node("%Control").get_index() and lbl.get_parent().get_index() < f.get_node("%Control").get_index(), "label above, description below")
	check(not f.get_node("%Error").visible and not f.get_node("%Counter").visible, "no error or counter until asked for")
	f.queue_free()


func _errors() -> void:
	var t := tokens()
	var f := _field()
	await process_frame
	var edit := f.control() as LineEdit
	f.error = "That name is taken."
	await process_frame
	check(f.get_node("%Error").visible and (f.get_node("%ErrorText") as Label).get_theme_color("font_color") == t.role("danger_text"), "an error shows in danger text")
	var light := WoldThemeBuilder.build(tokens("res://addons/woldui/tokens/default_light.tres"))
	var host := VBoxContainer.new()
	host.theme = light
	stage.add_child(host)
	var lf := WoldField.make(LineEdit.new(), "Name")
	host.add_child(lf)
	lf.error = "Nope."
	await process_frame
	check((lf.get_node("%ErrorIcon") as TextureRect).self_modulate == light.get_color("font_color", "FieldError"), "the error icon takes its colour from the theme it sits in")
	host.queue_free()
	check(edit.theme_type_variation == &"LineEditInvalid" and (edit.get_theme_stylebox("normal") as StyleBoxFlat).border_color == t.role("danger_text"), "and the field gets a danger border")
	f.error = ""
	await process_frame
	check(not f.get_node("%Error").visible and edit.theme_type_variation == &"", "clearing it puts the field back")
	var sm := LineEdit.new()
	sm.theme_type_variation = &"FieldSm"
	var g := _field(sm)
	await process_frame
	g.error = "Too short."
	check(sm.theme_type_variation == &"FieldSmInvalid", "a small field gets the small invalid style")
	g.error = ""
	check(sm.theme_type_variation == &"FieldSm", "and its own style back")
	f.queue_free()
	g.queue_free()


func _counter() -> void:
	var f := _field()
	f.max_length = 12
	await process_frame
	var edit := f.control() as LineEdit
	check(f.get_node("%Counter").visible and edit.max_length == 12, "max_length shows a counter and caps a LineEdit")
	edit.text = "Rivermouth"
	edit.text_changed.emit(edit.text)
	await process_frame
	check((f.get_node("%Counter") as Label).text == "10 / 12", "the counter follows typing (%s)" % (f.get_node("%Counter") as Label).text)
	var te := TextEdit.new()
	var g := _field(te)
	g.max_length = 5
	await process_frame
	te.text = "Too long here"
	te.text_changed.emit()
	await process_frame
	check((g.get_node("%Counter") as Label).theme_type_variation == &"FieldCounterOver", "a TextEdit over the limit turns the counter red")
	f.queue_free()
	g.queue_free()


func _label_click() -> void:
	var f := _field()
	await process_frame
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	f.get_node("%Label").gui_input.emit(click)
	check(f.control().has_focus(), "clicking the label focuses the control")
	check(f.control().accessibility_name == "Kingdom name" and f.control().accessibility_description == "Shown to other players.", "the label and hint name the control for screen readers")
	f.error = "Taken."
	check(f.control().accessibility_description == "Taken.", "and the error replaces the hint while it shows")
	f.queue_free()


func _other_controls() -> void:
	var sel: WoldSelect = load("res://addons/woldui/components/wold_select/wold_select.tscn").instantiate()
	var f := _field(sel)
	await process_frame
	f.error = "Pick one."
	await process_frame
	check(f.control() == sel and sel.theme_type_variation == &"Select" and f.get_node("%Error").visible, "any control fits; ones without an invalid style keep theirs")
	f.queue_free()


func _saved_scene() -> void:
	var host := VBoxContainer.new()
	stage.add_child(host)
	var f: WoldField = load(SCENE).instantiate()
	host.add_child(f)
	f.owner = host
	var edit := LineEdit.new()
	f.get_node("%Control").add_child(edit)
	edit.owner = host
	# same as ticking Editable Children in the editor
	host.set_editable_instance(f, true)
	f.error = "Nope."
	await process_frame
	var packed := PackedScene.new()
	packed.pack(host)
	var again := packed.instantiate()
	stage.add_child(again)
	await process_frame
	var copy := again.get_child(0) as WoldField
	check(copy.control() is LineEdit and copy.get_node("%Error").visible, "a slotted control is saved with the scene and the error comes back")
	host.queue_free()
	again.queue_free()


func _example() -> void:
	var f: WoldField = load("res://addons/woldui/gallery/examples/name_field.tscn").instantiate()
	stage.add_child(f)
	await process_frame
	var edit := f.control() as LineEdit
	var said := []
	for text in ["Ri", "Rivermouth", "Anthill"]:
		edit.text = text
		edit.text_changed.emit(text)
		said.append(f.error != "")
	check(said == [true, true, false] and edit.max_length == 24, "NameField: too short, taken, then fine (%s)" % [said])
	f.queue_free()


func _horizontal() -> void:
	var edit := LineEdit.new()
	var f := WoldField.make(edit, "Kingdom name", "Shown to other players.")
	f.custom_minimum_size.x = 460
	stage.add_child(f)
	await process_frame
	var lab := f.get_node("%Label") as Control
	check(lab.global_position.y < edit.global_position.y, "stacked by default: label above the control")
	f.horizontal = true
	await process_frame
	await process_frame
	var desc := f.get_node("%Description") as Control
	check(lab.global_position.x + lab.size.x <= edit.global_position.x and edit.global_position.x > f.global_position.x + 50, "horizontal: the label has a column on the left")
	var mid_l := lab.global_position.y + lab.size.y / 2.0
	var mid_c := edit.global_position.y + edit.size.y / 2.0
	check(absf(mid_l - mid_c) <= 2.0, "centred on the control's row (%.1f vs %.1f)" % [mid_l, mid_c])
	check(is_equal_approx(desc.global_position.x, edit.global_position.x) and desc.global_position.y > edit.global_position.y, "the hint sits under the control, not under the label")
	var col := edit.global_position.x - f.global_position.x
	f.label_width = 220
	await process_frame
	await process_frame
	check(edit.global_position.x - f.global_position.x > col, "label_width widens the column")
	check(f.get_minimum_size().x >= 220 + edit.get_combined_minimum_size().x, "and the minimum size makes room for it (%s)" % f.get_minimum_size())
	f.queue_free()
