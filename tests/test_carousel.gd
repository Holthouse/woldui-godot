extends "res://addons/woldui/tests/wold_test_base.gd"
## WoldCarousel + WoldPageDots: pages, arrows, dots, wrap, the slide, shoulders, saving.

const SCENE := "res://addons/woldui/components/wold_carousel/wold_carousel.tscn"
const DOTS := "res://addons/woldui/components/wold_page_dots/wold_page_dots.tscn"

var stage: VBoxContainer


func _run() -> void:
	get_root().size = Vector2i(1280, 720)
	stage = VBoxContainer.new()
	stage.size = Vector2(600, 700)
	stage.theme = WoldThemeBuilder.build(tokens())
	get_root().add_child(stage)
	await _dots()
	await _pages()
	await _wrap_and_slide()
	await _shoulders()
	await _saved_scene()
	var how: WoldCarousel = load("res://addons/woldui/gallery/examples/how_to_play.tscn").instantiate()
	var steps: WoldPageDots = load("res://addons/woldui/gallery/examples/step_dots.tscn").instantiate()
	stage.add_child(how)
	stage.add_child(steps)
	await _frames()
	check(how.pages().size() == 3 and how.pages()[0].visible and steps.count == 4 and steps.current == 1, "HowToPlay has its three pages, StepDots its four")
	how.queue_free()
	steps.queue_free()
	finish(18)


func _frames() -> void:
	await process_frame
	await process_frame


func _carousel(n := 3) -> WoldCarousel:
	var c: WoldCarousel = load(SCENE).instantiate()
	for i in n:
		var page := Label.new()
		page.name = "Page%d" % i
		page.text = "Page %d" % (i + 1)
		c.add_child(page)
	stage.add_child(c)
	return c


func _dots() -> void:
	var t := tokens()
	var d: WoldPageDots = load(DOTS).instantiate()
	stage.add_child(d)
	await _frames()
	var rects := d.dot_rects()
	check(rects.size() == 5 and rects[0].size.x == t.space_sm * 3 and rects[1].size.x == t.space_sm, "the current dot is a pill, the rest dots")
	var hit := InputEventMouseButton.new()
	hit.button_index = MOUSE_BUTTON_LEFT
	hit.pressed = true
	hit.position = rects[3].get_center()
	var said := []
	d.page_selected.connect(func(i): said.append(i))
	d._gui_input(hit)
	check(d.current == 3 and said == [3], "clicking a dot picks it")
	await create_timer(t.duration_base + 0.1).timeout
	rects = d.dot_rects()
	check(rects[3].size.x == t.space_sm * 3 and rects[0].size.x == t.space_sm, "and the pill slides over to it")
	check(WoldColor.contrast(d.get_theme_color("dot"), t.role("surface_raised")) >= 3.0, "idle dots stand off the surface (3:1)")
	d.queue_free()


func _pages() -> void:
	var c := _carousel()
	await _frames()
	var pages := c.pages()
	check(pages.size() == 3 and pages[0].visible and not pages[1].visible, "one page at a time, the controls aren't a page")
	check(c.get_child(c.get_child_count() - 1) == c.get_node("%Controls"), "the controls stay under the pages")
	check((c.get_node("%Prev") as Button).disabled and not (c.get_node("%Next") as Button).disabled, "at the first page, back is off")
	var seen := []
	c.page_changed.connect(func(i): seen.append(i))
	(c.get_node("%Next") as Button).pressed.emit()
	check(c.current == 1 and pages[1].visible and not pages[0].visible and seen == [1], "next moves on, one signal")
	(c.get_node("%Dots") as WoldPageDots).page_selected.emit(2)
	check(c.current == 2 and (c.get_node("%Next") as Button).disabled, "the dots jump; at the end, next is off")
	check(not c.step(1) and c.current == 2, "and stepping past it does nothing")
	var solo := _carousel(1)
	await _frames()
	check(not solo.get_node("%Controls").visible, "one page: no controls at all")
	solo.queue_free()
	c.queue_free()


func _wrap_and_slide() -> void:
	WoldUIRuntime.instance().reduced_motion = false
	var c := _carousel()
	c.wrap = true
	await _frames()
	check(not (c.get_node("%Prev") as Button).disabled, "wrap turns back on at the start")
	c.step(-1)
	await process_frame
	var page := c.pages()[2]
	check(c.current == 2 and page.offset_transform_position.x < 0.0, "going back from the first wraps to the last, sliding in from the left")
	c.step(1)
	await process_frame
	check(c.current == 0 and c.pages()[0].offset_transform_position.x > 0.0, "and on from the last wraps to the first, from the right")
	c.queue_free()


func _shoulders() -> void:
	var c := _carousel()
	var elsewhere := Button.new()
	stage.add_child(elsewhere)
	await _frames()
	var rb := InputEventJoypadButton.new()
	rb.button_index = JOY_BUTTON_RIGHT_SHOULDER
	rb.pressed = true
	elsewhere.grab_focus()
	get_root().push_input(rb)
	await process_frame
	check(c.current == 0, "RB does nothing while focus is elsewhere")
	(c.get_node("%Next") as Button).grab_focus()
	get_root().push_input(rb)
	await process_frame
	check(c.current == 1, "RB flips a page while focus is inside")
	elsewhere.queue_free()
	c.queue_free()


func _saved_scene() -> void:
	var host := VBoxContainer.new()
	stage.add_child(host)
	var c: WoldCarousel = load(SCENE).instantiate()
	host.add_child(c)
	c.owner = host
	for i in 3:
		var page := Label.new()
		page.text = str(i)
		c.add_child(page)
		page.owner = host
	c.current = 2
	await _frames()
	var packed := PackedScene.new()
	packed.pack(host)
	var again := packed.instantiate()
	stage.add_child(again)
	await _frames()
	var copy := again.get_child(0) as WoldCarousel
	check(copy.current == 2 and copy.pages().size() == 3 and copy.pages()[2].visible and not copy.pages()[0].visible, "saved with its pages, on the same page")
	host.queue_free()
	again.queue_free()
