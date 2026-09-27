extends "res://addons/woldui/tests/wold_test_base.gd"
## WoldTabs: pages, switching, indicator, page metadata, shoulders, bar-only, feedback.

const SCENE := "res://addons/woldui/components/wold_tabs/wold_tabs.tscn"
const EXAMPLE := "res://addons/woldui/gallery/examples/tabs_example.tscn"

var ui: WoldUIRuntime
var stage: Control


func _run() -> void:
	ui = WoldUIRuntime.instance()
	get_root().size = Vector2i(1280, 720)
	stage = Control.new()
	stage.size = Vector2(900, 600)
	stage.theme = WoldThemeBuilder.build(tokens())
	get_root().add_child(stage)
	await _bar_only()
	await _pages_and_switching()
	await _indicator()
	await _metadata_and_live_pages()
	await _pad()
	await _saved_past_three()
	await _pill()
	await _side()
	finish(42)


func _bar_only() -> void:
	var t: WoldTabs = load(SCENE).instantiate()
	stage.add_child(t)
	await process_frame
	check(t.tab_count() == 3 and t.tab_button(0).text == "Army", "the scene shows its preview tabs on its own")
	check(t.pages().is_empty(), "a bar without pages")
	t.tabs = PackedStringArray(["One", "Two"])
	await process_frame
	check(t.tab_count() == 2 and t.tab_button(1).text == "Two", "tabs sets the labels")
	t.queue_free()


func _example() -> WoldTabs:
	var t: WoldTabs = load(EXAMPLE).instantiate()
	stage.add_child(t)
	return t


func _pages_and_switching() -> void:
	var t := _example()
	await process_frame
	var pages := t.pages()
	check(pages.size() == 3 and t.tab_count() == 3, "each child page gets a tab (no Editable Children needed)")
	check(pages[0].visible and not pages[1].visible and not pages[2].visible, "only the current page shows")
	check(t.tab_button(0).button_pressed, "and its tab is pressed")
	var seen := []
	t.tab_changed.connect(func(i): seen.append(i))
	t.current = 2
	check(pages[2].visible and not pages[0].visible and t.tab_button(2).button_pressed, "setting current switches page and tab")
	check(seen == [2], "tab_changed fires once")
	t.tab_button(1).pressed.emit()
	check(t.current == 1 and pages[1].visible, "clicking a tab switches to it")
	t.current = 99
	check(t.current == 2, "current is clamped to the tabs there are")
	t.queue_free()


func _indicator() -> void:
	var t := _example()
	await process_frame
	await process_frame
	var ind := t.get_node("%Indicator") as Control
	var first := t.tab_button(0)
	check(is_equal_approx(ind.position.x, first.position.x) and is_equal_approx(ind.size.x, first.size.x), "the indicator starts under the first tab")
	t.current = 2
	await create_timer(tokens().duration_base * 0.4).timeout
	var target := t.tab_button(2)
	check(ind.position.x > first.position.x and ind.position.x < target.position.x, "it slides between tabs rather than jumping (x %.0f)" % ind.position.x)
	await create_timer(tokens().duration_base + 0.1).timeout
	check(is_equal_approx(ind.position.x, target.position.x) and is_equal_approx(ind.size.x, target.size.x), "and lands under the new tab, matching its width")
	ui.reduced_motion = true
	t.current = 0
	await process_frame
	await process_frame
	check(is_equal_approx(ind.position.x, first.position.x), "reduced motion: it jumps straight there")
	ui.reduced_motion = false
	t.queue_free()


func _metadata_and_live_pages() -> void:
	var t := _example()
	await process_frame
	check(t.tab_button(2).text == "Research tree", "wold_title labels a tab")
	check(t.tab_button(0).icon != null, "wold_icon puts an icon on a tab")
	var badge: WoldBadge = null
	for c in t.tab_button(1).get_children():
		if c is WoldBadge:
			badge = c
	check(badge != null and badge.count == 2, "wold_badge puts a count on a tab")
	var extra := Label.new()
	extra.name = "Diplomacy"
	t.add_child(extra)
	await process_frame
	await process_frame
	check(t.tab_count() == 4 and t.tab_button(3).text == "Diplomacy", "a page added at runtime gets a tab")
	extra.queue_free()
	await process_frame
	await process_frame
	check(t.tab_count() == 3, "and a removed page loses it")
	var fb := WoldFeedback.new()
	stage.add_child(fb)
	await process_frame
	t.tabs = PackedStringArray()
	await process_frame
	check(t.tab_button(0).has_meta(WoldFeedback._WIRED), "WoldFeedback wires the tab buttons")
	check(t.tab_button(0).focus_mode == Control.FOCUS_ALL, "tabs take keyboard / pad focus")
	fb.queue_free()
	t.queue_free()


func _pad() -> void:
	var t := _example()
	await process_frame
	var rb := InputEventJoypadButton.new()
	rb.button_index = JOY_BUTTON_RIGHT_SHOULDER
	rb.pressed = true
	get_root().push_input(rb)
	check(t.current == 1, "RB moves to the next tab")
	get_root().push_input(rb)
	get_root().push_input(rb)
	check(t.current == 2, "and stops at the last")
	var lb := InputEventJoypadButton.new()
	lb.button_index = JOY_BUTTON_LEFT_SHOULDER
	lb.pressed = true
	get_root().push_input(lb)
	check(t.current == 1, "LB moves back")
	t.pad_shoulders = false
	get_root().push_input(lb)
	check(t.current == 1, "pad_shoulders off ignores them")
	t.queue_free()


# the scene's default `tabs` has 3 names; a saved current past that used to
# get clamped while loading, before the pages were back
func _saved_past_three() -> void:
	var host := VBoxContainer.new()
	get_root().add_child(host)
	var tabs: WoldTabs = load("res://addons/woldui/components/wold_tabs/wold_tabs.tscn").instantiate()
	host.add_child(tabs)
	tabs.owner = host
	for i in 5:
		var page := Label.new()
		page.name = "Page%d" % i
		page.text = str(i)
		tabs.add_child(page)
		page.owner = host
	await process_frame
	tabs.current = 4
	await process_frame
	var packed := PackedScene.new()
	packed.pack(host)
	var again := packed.instantiate()
	get_root().add_child(again)
	await process_frame
	await process_frame
	var copy := again.get_child(0) as WoldTabs
	check(copy.current == 4 and copy.pages()[4].visible, "a saved tab past the third comes back (got %d)" % copy.current)
	host.queue_free()
	again.queue_free()


func _pill() -> void:
	ui.reduced_motion = false
	var t: WoldTabs = load(EXAMPLE).instantiate()
	t.look = WoldTabs.Look.PILL
	stage.add_child(t)
	await process_frame
	await process_frame
	check(t.tab_button(0).theme_type_variation == &"TabButtonPill" and not t.get_node("%Rail").visible, "PILL: pill tab buttons, no underline rail")
	check(t.get_node("%BarPad").theme_type_variation == &"TabsPillInset", "the bar sits inset in its track")
	check(t.pill_rect().is_equal_approx(t.pill_target()) and t.pill_rect().size.x > 0.0, "the pill sits behind the current tab")
	var first := t.pill_target()
	t.current = 2
	await create_timer(tokens().duration_base * 0.4).timeout
	var mid := t.pill_rect()
	await create_timer(tokens().duration_base + 0.1).timeout
	var last := t.pill_target()
	check(mid.position.x > first.position.x and mid.position.x < last.position.x, "switching slides it over")
	check(t.pill_rect().is_equal_approx(last), "and it lands behind the new tab")
	ui.reduced_motion = true
	t.current = 0
	await process_frame
	check(t.pill_rect().is_equal_approx(t.pill_target()), "reduced motion: it jumps")
	ui.reduced_motion = false
	t.stretch = true
	await process_frame
	await process_frame
	var narrow := t.pill_rect().size.x
	t.custom_minimum_size.x = 800
	await process_frame
	await process_frame
	check(t.pill_rect().size.x > narrow and t.pill_rect().is_equal_approx(t.pill_target()), "the pill follows its tab when the bar is resized (%s -> %s, target %s)" % [narrow, t.pill_rect(), t.pill_target()])
	var line: WoldTabs = load(SCENE).instantiate()
	line.stretch = true
	stage.add_child(line)
	await process_frame
	await process_frame
	var before := (line.get_node("%Indicator") as Control).size.x
	line.custom_minimum_size.x = 800
	await process_frame
	await process_frame
	check((line.get_node("%Indicator") as Control).size.x > before and is_equal_approx((line.get_node("%Indicator") as Control).size.x, line.indicator_target().size.x), "so does the underline")
	line.queue_free()
	t.queue_free()


func _side() -> void:
	var t: WoldTabs = load(EXAMPLE).instantiate()
	t.layout = WoldTabs.Layout.SIDE
	stage.add_child(t)
	await process_frame
	await process_frame
	var bar: BoxContainer = t.get_node("%Bar")
	check(not t.vertical and bar.vertical and (t.get_node("%Header") as BoxContainer).vertical == false, "SIDE: tabs stacked down the left, pages beside them")
	check(t.tab_button(0).alignment == HORIZONTAL_ALIGNMENT_LEFT, "side tabs read from the left edge")
	var b1 := t.tab_button(1)
	check(t.tab_button(0).global_position.x == b1.global_position.x and b1.global_position.y > t.tab_button(0).global_position.y, "one under the other")
	t.current = 1
	await process_frame
	await create_timer(tokens().duration_base + 0.1).timeout
	var ind := t.get_node("%Indicator") as Control
	check(is_equal_approx(ind.size.y, b1.size.y) and ind.size.x <= 2.0 and is_equal_approx(ind.global_position.y, b1.global_position.y), "the underline runs down beside the current tab")
	check(t.tab_button(0).find_valid_focus_neighbor(SIDE_BOTTOM) == b1, "down moves focus to the next tab")
	var header := t.get_node("%Header") as Control
	check(header.size.y < t.size.y or t.size.y == header.size.y and header.size_flags_vertical == Control.SIZE_SHRINK_BEGIN, "the bar is only as tall as its tabs")
	var host := VBoxContainer.new()
	get_root().add_child(host)
	# packed as a root, like an inherited scene would be: vertical differs from
	# BoxContainer's default there, so it would be saved
	var top_root: WoldTabs = load(SCENE).instantiate()
	host.add_child(top_root)
	await process_frame
	var own := PackedScene.new()
	own.pack(top_root)
	var own_state := own.get_state()
	var own_props := []
	for i in own_state.get_node_property_count(0):
		own_props.append(own_state.get_node_property_name(0, i))
	check(not own_props.has("vertical"), "vertical, which layout drives, isn't saved (%s)" % [own_props])
	var saved: WoldTabs = load(SCENE).instantiate()
	saved.layout = WoldTabs.Layout.SIDE
	host.add_child(saved)
	saved.owner = host
	await process_frame
	var packed := PackedScene.new()
	packed.pack(host)
	var again := packed.instantiate()
	get_root().add_child(again)
	await process_frame
	check(not (again.get_child(0) as WoldTabs).vertical, "a saved SIDE layout comes back sideways")
	host.queue_free()
	again.queue_free()
	t.queue_free()
