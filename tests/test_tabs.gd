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
	finish(26)


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
