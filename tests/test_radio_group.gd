extends "res://addons/woldui/tests/wold_test_base.gd"
## WoldRadioGroup: options, picking, arrows / d-pad, layout, saved scenes.

const SCENE := "res://addons/woldui/components/wold_radio_group/wold_radio_group.tscn"

var stage: VBoxContainer


func _run() -> void:
	get_root().size = Vector2i(1280, 720)
	stage = VBoxContainer.new()
	stage.size = Vector2(600, 600)
	stage.theme = WoldThemeBuilder.build(tokens())
	get_root().add_child(stage)
	await _options()
	await _picking()
	await _keys()
	await _layout()
	await _saved_scene()
	await _example()
	finish(18)


func _group() -> WoldRadioGroup:
	var g: WoldRadioGroup = load(SCENE).instantiate()
	stage.add_child(g)
	return g


func _options() -> void:
	var g := _group()
	await process_frame
	check(g.item_count() == 3 and g.item(0).label == "Small", "one radio per option")
	check(g.item(0).is_radio() and g.item(0).icon_name() == "radio_unchecked", "they draw as radios")
	check(g.item(2).description != "" and g.item(1).description == "", "descriptions line up with options, blanks skipped")
	check(g.item(1).button_pressed and not g.item(0).button_pressed, "`selected` is the picked one")
	g.options = PackedStringArray(["Ants", "Moles"])
	await process_frame
	check(g.item_count() == 2 and g.item(1).label == "Moles", "new options rebuild the list")
	check(g.selected == 1 and g.item(1).button_pressed, "and the pick is kept while it still exists")
	g.queue_free()


func _picking() -> void:
	var g := _group()
	await process_frame
	var seen := []
	g.selected_changed.connect(func(i): seen.append(i))
	g.item(2).button_pressed = true
	check(g.selected == 2 and not g.item(1).button_pressed, "clicking a radio picks it")
	check(seen == [2], "selected_changed fires once (%s)" % [seen])
	g.selected = 0
	check(g.item(0).button_pressed and not g.item(2).button_pressed, "setting `selected` moves the dot")
	g.selected = -1
	check(not g.item(0).button_pressed, "-1 picks nothing")
	g.queue_free()


func _press(action: StringName) -> void:
	var e := InputEventAction.new()
	e.action = action
	e.pressed = true
	get_root().push_input(e)
	await process_frame


func _keys() -> void:
	var before := Button.new()
	before.text = "before"
	stage.add_child(before)
	var g := _group()
	var after := Button.new()
	after.text = "after"
	stage.add_child(after)
	await process_frame
	g.item(1).grab_focus()
	await _press(&"ui_down")
	check(g.selected == 2 and g.item(2).has_focus(), "down moves the pick and the focus")
	await _press(&"ui_down")
	check(after.has_focus() and g.selected == 2, "past the end, focus leaves the group and the pick stays")
	g.horizontal = true
	g.item(1).grab_focus()
	await _press(&"ui_left")
	check(g.selected == 0 and g.item(0).has_focus(), "horizontal groups use left / right")
	before.queue_free()
	after.queue_free()
	g.queue_free()


func _layout() -> void:
	var g := _group()
	g.horizontal = true
	g.disabled = true
	await process_frame
	check(is_equal_approx(g.item(0).position.y, g.item(2).position.y) and g.item(2).position.x > g.item(0).position.x, "horizontal puts them in a row")
	check(g.item(0).disabled and g.item(0).icon_name().ends_with("_disabled"), "disabled reaches every option")
	g.queue_free()


func _saved_scene() -> void:
	var host := VBoxContainer.new()
	stage.add_child(host)
	var g: WoldRadioGroup = load(SCENE).instantiate()
	host.add_child(g)
	g.owner = host
	# rebuild while owned, like editing it in the editor
	g.options = PackedStringArray(["Small", "Medium", "Huge"])
	g.selected = 2
	await process_frame
	var packed := PackedScene.new()
	packed.pack(host)
	check(packed.get_state().get_node_count() == 2 and g.item(0).owner == null, "the generated radios have no owner, so they are never saved")
	var again := packed.instantiate()
	stage.add_child(again)
	await process_frame
	var copy := again.get_child(0) as WoldRadioGroup
	check(copy.item_count() == 3 and copy.item(2).button_pressed, "it rebuilds with the saved pick")
	host.queue_free()
	again.queue_free()


func _example() -> void:
	var g = load("res://addons/woldui/gallery/examples/game_speed.tscn").instantiate()
	stage.add_child(g)
	await process_frame
	var before: float = g.speed
	g.item(2).button_pressed = true
	check(before == 90.0 and g.speed == 45.0, "GameSpeed turns the pick into a turn timer (%.0f then %.0f)" % [before, g.speed])
	g.queue_free()
