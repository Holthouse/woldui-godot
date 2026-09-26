extends "res://addons/woldui/tests/wold_test_base.gd"
## gallery builds under every bundled tokens file, keyboard reachable, feedback wired


func _run() -> void:
	# headless window is 64px, give it a real size
	get_root().size = Vector2i(1280, 720)
	await process_frame
	for path in ["res://addons/woldui/tokens/default_dark.tres", "res://addons/woldui/tokens/default_light.tres"]:
		await _gallery(path)
	finish(16)


func _gallery(path: String) -> void:
	var g: Control = load("res://addons/woldui/gallery/gallery.tscn").instantiate()
	g.tokens_path = path
	get_root().add_child(g)
	await process_frame
	await process_frame
	var buttons := _all(g, "BaseButton")
	var file := path.get_file()
	var page := (g.get_child(0) as ScrollContainer).get_child(0) as Control
	check(page.get_combined_minimum_size().x <= 1280.0, "%s: the page fits a 1280 px window (needs %.0f px; a long note that does not wrap pushes the gallery off-screen)" % [file, page.get_combined_minimum_size().x])
	check(buttons.size() > 150, "%s: the gallery shows the catalogue (%d buttons)" % [file, buttons.size()])
	var unreachable := buttons.filter(func(b): return b.focus_mode == Control.FOCUS_NONE)
	check(unreachable.is_empty(), "%s: every button can take keyboard / pad focus (%d cannot)" % [file, unreachable.size()])
	var fields := _all(g, "LineEdit")
	check(not fields.is_empty() and fields.all(func(f): return f.focus_mode != Control.FOCUS_NONE), "%s: fields take focus" % file)
	check(g.get_children().any(func(c): return c is WoldFeedback), "%s: the gallery carries a WoldFeedback node" % file)
	var wired := buttons.filter(func(b): return b.has_meta(WoldFeedback._WIRED))
	check(wired.size() == buttons.size(), "%s: every gallery button is wired for feedback (%d of %d)" % [file, wired.size(), buttons.size()])
	var labels := _all(g, "Button").map(func(b): return b.text)
	check(Array(WoldMotion.preset_names()).all(func(n): return labels.has(n)), "%s: every motion preset has a play button" % file)
	var tips := _all(g, "Node").filter(func(n): return n is WoldTooltip)
	check(tips.size() >= 4 and tips.all(func(t): return not t.rows.is_empty()), "%s: every gallery tooltip got its rows (%d tooltips)" % [file, tips.size()])
	g.queue_free()
	await process_frame


func _all(node: Node, type: String) -> Array:
	var out := []
	if node.is_class(type):
		out.append(node)
	for child in node.get_children():
		out.append_array(_all(child, type))
	return out
