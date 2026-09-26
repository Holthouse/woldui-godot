extends "res://addons/woldui/tests/wold_test_base.gd"
## The quiet ones from status_recipe: WoldEmpty, WoldSkeleton, WoldSpinner, WoldSeparator.

var stage: VBoxContainer


func _run() -> void:
	get_root().size = Vector2i(1280, 720)
	stage = VBoxContainer.new()
	stage.size = Vector2(600, 700)
	stage.theme = WoldThemeBuilder.build(tokens())
	get_root().add_child(stage)
	await _empty()
	await _skeleton()
	await _spinner()
	await _separator()
	var ns: WoldEmpty = _add("res://addons/woldui/gallery/examples/no_saves.tscn")
	var ts: WoldSkeleton = _add("res://addons/woldui/gallery/examples/text_skeleton.tscn")
	var sv: WoldSpinner = _add("res://addons/woldui/gallery/examples/saving_spinner.tscn")
	var td: WoldSeparator = _add("res://addons/woldui/gallery/examples/turn_divider.tscn")
	await _frames()
	check(ns.get_node("%Actions").visible and ts.line_rects().size() == 3 and sv.size.x == tokens().icon_size_lg and td.label_rect().position.x < td.size.x / 4.0, "the four examples come up as set")
	for n in [ns, ts, sv, td]:
		n.queue_free()
	finish(20)


func _add(path: String) -> Node:
	var n: Node = load(path).instantiate()
	stage.add_child(n)
	return n


func _frames() -> void:
	await process_frame
	await process_frame


func _empty() -> void:
	var t := tokens()
	var e: WoldEmpty = _add("res://addons/woldui/components/wold_empty/wold_empty.tscn")
	await _frames()
	e.title = "The hold is empty"
	check((e.get_node("%Title") as Label).text == "The hold is empty" and e.get_node("%Media").visible, "an icon and a line saying so")
	check((e.get_node("%Icon") as TextureRect).self_modulate == t.role("text_muted") and (e.get_node("%Description") as Label).get_theme_color("font_color") == t.role("text_muted"), "the icon and hint are muted")
	check(not e.get_node("%Actions").visible, "no actions row until you add one")
	var b := Button.new()
	b.text = "Start a game"
	e.get_node("%Actions").add_child(b)
	e.icon = ""
	await _frames()
	check(e.get_node("%Actions").visible and not e.get_node("%Media").visible, "a button shows the row; no icon, no circle")
	check(absf(b.get_global_rect().get_center().x - e.get_global_rect().get_center().x) < 1.0, "everything is centred (%.0f vs %.0f)" % [b.get_global_rect().get_center().x, e.get_global_rect().get_center().x])
	e.queue_free()


func _skeleton() -> void:
	WoldUIRuntime.instance().reduced_motion = false
	var s: WoldSkeleton = _add("res://addons/woldui/components/wold_skeleton/wold_skeleton.tscn")
	s.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	await _frames()
	check((s.get_theme_stylebox("panel") as StyleBoxFlat).bg_color == tokens().role("control_hover") and s.size == Vector2(240, 16), "a block the size you give it")
	await create_timer(0.3).timeout
	check(s.modulate.a < 1.0, "it breathes (alpha %.2f)" % s.modulate.a)
	s.active = false
	check(s.modulate.a == 1.0, "and stops when not active")
	s.lines = 3
	await _frames()
	var bars := s.line_rects()
	check(bars.size() == 3 and bars[2].size.x < bars[0].size.x and s.size.y >= bars[2].end.y, "lines: a bar per line, the last one shorter")
	check(s.get_theme_stylebox("panel") is StyleBoxEmpty, "and no block behind them")
	s.lines = 0
	s.shape = WoldSkeleton.Shape.ROUND
	s.custom_minimum_size = Vector2(40, 40)
	await _frames()
	var tall := Control.new()
	tall.custom_minimum_size = Vector2(10, 120)
	var row := HBoxContainer.new()
	stage.add_child(row)
	s.reparent(row)
	row.add_child(tall)
	await _frames()
	check((s.get_theme_stylebox("panel") as StyleBoxFlat).corner_radius_top_left >= 20 and s.size == Vector2(40, 40), "ROUND is a circle, and stays one in a taller row (%s)" % s.size)
	row.queue_free()
	WoldUIRuntime.instance().reduced_motion = true
	var still: WoldSkeleton = _add("res://addons/woldui/components/wold_skeleton/wold_skeleton.tscn")
	await create_timer(0.3).timeout
	check(still.modulate.a == 1.0, "reduced motion: it holds still")
	WoldUIRuntime.instance().reduced_motion = false
	still.queue_free()


func _spinner() -> void:
	var ui := WoldUIRuntime.instance()
	ui.reduced_motion = false
	var s: WoldSpinner = _add("res://addons/woldui/components/wold_spinner/wold_spinner.tscn")
	await _frames()
	var a0 := s.angle
	await create_timer(0.1).timeout
	check(s.is_spinning() and s.angle != a0, "it turns")
	check(s.size.x == tokens().icon_size_md and s.rotation == 0.0, "icon sized, and the node itself never rotates")
	s.visible = false
	await _frames()
	check(not s.is_spinning(), "hidden, it stops turning")
	s.visible = true
	ui.reduced_motion = true
	await _frames()
	check(not s.is_spinning(), "reduced motion: it holds still (and breathes instead)")
	ui.reduced_motion = false
	s.queue_free()


func _separator() -> void:
	var sep: WoldSeparator = _add("res://addons/woldui/components/wold_separator/wold_separator.tscn")
	await _frames()
	var r := sep.label_rect()
	check(sep.get_node("%Label").visible and absf(r.get_center().x - sep.size.x / 2.0) < 1.0, "the label sits in the middle of the line")
	sep.place = WoldSeparator.Place.START
	await _frames()
	check(sep.label_rect().position.x < sep.size.x / 4.0, "or near the start")
	sep.text = ""
	await _frames()
	check(not sep.get_node("%Label").visible and sep.label_rect() == Rect2() and sep.size.y == tokens().border_width, "no text: just a line, border thick")
	sep.queue_free()
