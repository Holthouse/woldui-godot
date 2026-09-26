extends "res://addons/woldui/tests/wold_test_base.gd"
## WoldCollapsible: closed / open, the slide, reduced motion, focus, content changes, saved scenes.

const SCENE := "res://addons/woldui/components/wold_collapsible/wold_collapsible.tscn"

var stage: VBoxContainer


func _run() -> void:
	get_root().size = Vector2i(1280, 720)
	stage = VBoxContainer.new()
	stage.size = Vector2(600, 700)
	stage.theme = WoldThemeBuilder.build(tokens())
	get_root().add_child(stage)
	await _closed_and_open()
	await _slide()
	await _reduced()
	await _content_changes()
	await _saved_scene()
	var u: WoldCollapsible = load("res://addons/woldui/gallery/examples/unit_details.tscn").instantiate()
	stage.add_child(u)
	await _frames()
	check(u.get_node("%Content").get_child_count() == 3 and u.title == "Spearman", "UnitDetails builds one row per stat")
	u.queue_free()
	finish(16)


func _item(text := "Trade needs a road or a river between the cities.") -> WoldCollapsible:
	var c: WoldCollapsible = load(SCENE).instantiate()
	var l := Label.new()
	l.text = text
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	c.get_node("%Content").add_child(l)
	var b := Button.new()
	b.text = "Open trade"
	c.get_node("%Content").add_child(b)
	stage.add_child(c)
	return c


func _frames() -> void:
	await process_frame
	await process_frame


func _closed_and_open() -> void:
	WoldUIRuntime.instance().reduced_motion = true
	var c := _item()
	await _frames()
	var trigger := c.trigger()
	check(trigger.text == "How does trade work?" and trigger.theme_type_variation == &"CollapsibleTrigger", "the trigger shows the title")
	check(c.shown_height() == 0.0 and not c.get_node("%Body").visible, "closed: no height and the content is hidden")
	var closed_h := c.size.y
	var seen := []
	c.toggled.connect(func(o): seen.append(o))
	trigger.pressed.emit()
	await _frames()
	check(c.open and seen == [true], "pressing the trigger opens it, one signal")
	check(c.shown_height() > 20.0 and is_equal_approx(c.shown_height(), c.body_height()) and c.size.y > closed_h, "open: it's as tall as its content")
	check(trigger.end_icon() == tokens().icon("chevron-up"), "the chevron flips")
	var btn := c.get_node("%Content").get_child(1) as Button
	check(btn.is_visible_in_tree(), "the content is reachable while open")
	c.open = false
	await _frames()
	check(not btn.is_visible_in_tree(), "and not once closed, so focus can't land in it")
	WoldUIRuntime.instance().reduced_motion = false
	c.queue_free()


func _slide() -> void:
	WoldUIRuntime.instance().reduced_motion = false
	var c := _item()
	await _frames()
	c.open = true
	await process_frame
	await process_frame
	var mid := c.shown_height()
	check(mid > 0.0 and mid < c.body_height(), "opening slides (%.0f of %.0f)" % [mid, c.body_height()])
	await create_timer(tokens().duration_base + 0.15).timeout
	check(is_equal_approx(c.shown_height(), c.body_height()), "and ends fully open")
	c.open = false
	await create_timer(tokens().duration_base + 0.15).timeout
	check(c.shown_height() == 0.0 and not c.get_node("%Body").visible, "closing slides shut and hides the content")
	c.queue_free()


func _reduced() -> void:
	WoldUIRuntime.instance().reduced_motion = true
	var c := _item()
	await _frames()
	c.open = true
	await process_frame
	check(is_equal_approx(c.shown_height(), c.body_height()), "reduced motion: it just opens")
	WoldUIRuntime.instance().reduced_motion = false
	c.queue_free()


func _content_changes() -> void:
	WoldUIRuntime.instance().reduced_motion = true
	var c := _item()
	c.open = true
	await _frames()
	var h := c.shown_height()
	var more := Label.new()
	more.text = "Another line."
	c.get_node("%Content").add_child(more)
	await _frames()
	check(c.shown_height() > h, "content added while open grows it")
	c.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	c.custom_minimum_size.x = 260
	var wide_h := c.shown_height()
	await _frames()
	check(c.shown_height() > wide_h and is_equal_approx(c.shown_height(), c.body_height()) and is_equal_approx(c.get_node("%Body").size.x, c.size.x), "narrower, the wrapped text gets taller and it follows (%.0f -> %.0f)" % [wide_h, c.shown_height()])
	WoldUIRuntime.instance().reduced_motion = false
	c.queue_free()


func _saved_scene() -> void:
	var host := VBoxContainer.new()
	stage.add_child(host)
	var c: WoldCollapsible = load(SCENE).instantiate()
	host.add_child(c)
	c.owner = host
	c.open = true
	await _frames()
	var packed := PackedScene.new()
	packed.pack(host)
	var state := packed.get_state()
	var saved := {}
	for i in state.get_node_property_count(1):
		saved[state.get_node_property_name(1, i)] = true
	check(saved.has("open") and state.get_node_count() == 2, "saves `open`, not its insides (saved: %s)" % [saved.keys()])
	var again := packed.instantiate()
	stage.add_child(again)
	await _frames()
	var copy := again.get_child(0) as WoldCollapsible
	check(copy.open and copy.get_node("%Body").visible and copy.trigger().icon_end == "chevron-up", "it comes back open")
	host.queue_free()
	again.queue_free()
