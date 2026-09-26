extends "res://addons/woldui/tests/wold_test_base.gd"
## WoldCard: header parts, slots and their padding, sizes, selectable cards, groups, saved scenes.

const SCENE := "res://addons/woldui/components/wold_card/wold_card.tscn"

var stage: HBoxContainer


func _run() -> void:
	get_root().size = Vector2i(1280, 720)
	stage = HBoxContainer.new()
	stage.theme = WoldThemeBuilder.build(tokens())
	get_root().add_child(stage)
	await _header()
	await _slots()
	await _sizes()
	await _choice()
	await _saved_scene()
	await _example()
	finish(19)


func _card() -> WoldCard:
	var c: WoldCard = load(SCENE).instantiate()
	c.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	stage.add_child(c)
	return c


func _frames() -> void:
	await process_frame
	await process_frame


func _header() -> void:
	var t := tokens()
	var c := _card()
	await _frames()
	check((c.get_node("%Title") as Label).text == "Great Library" and c.get_node("%Icon").visible, "title and icon show")
	check((c.get_node("%Description") as Label).get_theme_color("font_color") == t.role("text_muted"), "the description is muted")
	check((c.get_theme_stylebox("panel") as StyleBoxFlat).bg_color == t.role("surface_raised"), "it's a raised surface")
	check(not c.get_node("%ContentBox").visible and not c.get_node("%FooterBox").visible, "empty content and footer take no room")
	var header := c.get_node("%Header") as Control
	check(is_equal_approx(header.get_theme_constant("margin_top"), t.space_lg) and is_equal_approx(header.get_theme_constant("margin_bottom"), t.space_lg), "the header pads itself")
	c.title = ""
	c.description = ""
	c.icon = ""
	await _frames()
	check(not header.visible, "no title, text, icon or action: no header")
	c.queue_free()


func _slots() -> void:
	var t := tokens()
	var c := _card()
	var body := Label.new()
	body.text = "Costs 400 production."
	c.get_node("%Content").add_child(body)
	var b := Button.new()
	b.text = "Build"
	c.get_node("%Footer").add_child(b)
	await _frames()
	var content := c.get_node("%ContentBox") as Control
	check(content.visible and c.get_node("%FooterBox").visible, "slots show when you fill them")
	check(content.get_theme_constant("margin_top") == 0 and c.get_node("%Header").get_theme_constant("margin_top") == t.space_lg, "only the first section pads its top, so gaps stay even")
	c.title = ""
	c.description = ""
	c.icon = ""
	await _frames()
	check(content.get_theme_constant("margin_top") == t.space_lg, "with no header the content pads its own top")
	c.queue_free()


func _sizes() -> void:
	var t := tokens()
	var c := _card()
	c.card_size = WoldCard.Size.SM
	await _frames()
	check(c.theme_type_variation == &"CardSm" and c.get_node("%Header").get_theme_constant("margin_left") == t.space_md, "SM pads less")
	check((c.get_node("%Title") as Label).get_theme_font_size("font_size") == t.font_size(0), "and has a smaller title")
	c.queue_free()


func _choice() -> void:
	var a := _card()
	var b := _card()
	var plain := _card()
	for c in [a, b]:
		c.selectable = true
		c.card_group = &"upgrade"
	await _frames()
	check(a.focus_mode == Control.FOCUS_ALL and plain.focus_mode == Control.FOCUS_NONE, "selectable cards take focus, plain ones don't")
	var hits := []
	b.pressed.connect(func(): hits.append("b"))
	b.grab_focus()
	var e := InputEventAction.new()
	e.action = &"ui_accept"
	e.pressed = true
	get_root().push_input(e)
	await process_frame
	check(hits == ["b"] and b.selected, "accept on a focused card presses and selects it")
	a.activate()
	check(a.selected and not b.selected, "a card group selects one at a time")
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = false
	click.global_position = b.get_global_rect().get_center()
	b._gui_input(click)
	check(b.selected and hits.size() == 2, "a click does the same")
	plain.selected = true
	check(plain.selected and b.selected, "cards outside the group aren't touched")
	for c in [a, b, plain]:
		c.queue_free()


func _saved_scene() -> void:
	var host := HBoxContainer.new()
	stage.add_child(host)
	var c: WoldCard = load(SCENE).instantiate()
	host.add_child(c)
	c.owner = host
	c.selectable = true
	await process_frame
	var packed := PackedScene.new()
	packed.pack(host)
	var state := packed.get_state()
	var saved := {}
	for i in state.get_node_property_count(1):
		saved[state.get_node_property_name(1, i)] = true
	check(not saved.has("theme_type_variation") and not saved.has("focus_mode") and saved.has("selectable"), "saves its props, not what they derive (saved: %s)" % [saved.keys()])
	c.card_group = &"relic"
	var joined := c.is_in_group(&"_wold_card_relic")
	c.card_group = &""
	check(joined and not c.is_in_group(&"_wold_card_relic"), "changing card_group moves it between groups")
	host.queue_free()


func _example() -> void:
	var a: WoldCard = load("res://addons/woldui/gallery/examples/upgrade_card.tscn").instantiate()
	var b: WoldCard = load("res://addons/woldui/gallery/examples/upgrade_card.tscn").instantiate()
	stage.add_child(a)
	stage.add_child(b)
	await _frames()
	var badge := a.get_node("%Action").get_child(0) as WoldBadge
	a.activate()
	b.activate()
	check(a.selectable and badge and badge.text == "40" and b.selected and not a.selected, "UpgradeCards show their cost and pick one at a time")
	a.queue_free()
	b.queue_free()
