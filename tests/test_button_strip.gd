extends "res://addons/woldui/tests/wold_test_base.gd"
## WoldButtonStrip: joined corners both ways, seams, changes, token swaps, saving.

const SCENE := "res://addons/woldui/components/wold_button_strip/wold_button_strip.tscn"

var stage: VBoxContainer


func _run() -> void:
	get_root().size = Vector2i(1280, 720)
	stage = VBoxContainer.new()
	stage.theme = WoldThemeBuilder.build(tokens())
	get_root().add_child(stage)
	await _corners()
	await _vertical_and_changes()
	await _restyle()
	await _saving()
	var zoom: WoldButtonStrip = load("res://addons/woldui/gallery/examples/map_zoom.tscn").instantiate()
	stage.add_child(zoom)
	await _frames()
	var top := _sb(zoom.buttons()[0])
	check(zoom.vertical and zoom.buttons().size() == 3 and top.corner_radius_top_left > 0 and top.corner_radius_bottom_left == 0, "MapZoom is a joined vertical strip")
	zoom.queue_free()
	finish(16)


func _strip() -> WoldButtonStrip:
	var g: WoldButtonStrip = load(SCENE).instantiate()
	for label in ["Undo", "Redo", "History"]:
		var b: WoldButton = load("res://addons/woldui/components/wold_button/wold_button.tscn").instantiate()
		b.text = label
		g.add_child(b)
	g.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	stage.add_child(g)
	return g


func _sb(b: Control, state := "normal") -> StyleBoxFlat:
	return b.get_theme_stylebox(state) as StyleBoxFlat


func _frames() -> void:
	await process_frame
	await process_frame


func _corners() -> void:
	var r := tokens().radius_md
	var g := _strip()
	await _frames()
	var list := g.buttons()
	check(list.size() == 3, "three buttons to join")
	var first := _sb(list[0])
	var mid := _sb(list[1])
	var last := _sb(list[2])
	check(first.corner_radius_top_left == r and first.corner_radius_bottom_left == r and first.corner_radius_top_right == 0 and first.corner_radius_bottom_right == 0, "the first keeps only its left corners")
	check(mid.corner_radius_top_left == 0 and mid.corner_radius_bottom_right == 0, "the middle one is square")
	check(last.corner_radius_top_right == r and last.corner_radius_top_left == 0, "the last keeps its right corners")
	check(_sb(list[1], "hover").corner_radius_top_left == 0 and _sb(list[1], "focus").corner_radius_top_left == 0, "every state is joined, focus ring too")
	check(is_equal_approx(list[1].position.x, list[0].position.x + list[0].size.x - tokens().border_width), "neighbours overlap by one border, so seams are one line")
	g.queue_free()


func _vertical_and_changes() -> void:
	var r := tokens().radius_md
	var g := _strip()
	g.vertical = true
	await _frames()
	var list := g.buttons()
	check(_sb(list[0]).corner_radius_top_right == r and _sb(list[0]).corner_radius_bottom_left == 0, "vertical: the first keeps its top corners")
	var extra := Button.new()
	extra.text = "More"
	g.add_child(extra)
	await _frames()
	check(_sb(list[2]).corner_radius_bottom_left == 0 and _sb(extra).corner_radius_bottom_left == r, "adding a button moves the end corners to it")
	extra.visible = false
	await _frames()
	check(_sb(list[2]).corner_radius_bottom_left == r, "a hidden button leaves the strip")
	g.remove_child(extra)
	check(not extra.has_theme_stylebox_override("normal"), "a button taken out gets its own corners back")
	extra.queue_free()
	g.queue_free()


func _restyle() -> void:
	var g := _strip()
	await _frames()
	var b := g.buttons()[1] as WoldButton
	b.shape = WoldButton.Shape.PRIMARY
	await _frames()
	check(_sb(b).bg_color == tokens().role("accent") and _sb(b).corner_radius_top_left == 0, "restyling a WoldButton inside keeps it joined, with its new look")
	var rounder := tokens().derive({"radius_md": 14})
	stage.theme = WoldThemeBuilder.build(rounder)
	await _frames()
	check(_sb(g.buttons()[0]).corner_radius_top_left == 14, "new tokens reach the joined buttons")
	stage.theme = WoldThemeBuilder.build(tokens())
	g.queue_free()


func _saving() -> void:
	var g := _strip()
	await _frames()
	var b := g.buttons()[0]
	check(g.is_joined(b) and b.has_theme_stylebox_override("normal"), "joined buttons carry overrides")
	g.propagate_notification(Node.NOTIFICATION_EDITOR_PRE_SAVE)
	var metas := b.get_meta_list().filter(func(m): return not str(m).begins_with("wold_sound"))
	check(not b.has_theme_stylebox_override("normal") and metas.is_empty(), "right before an editor save they come off, and nothing else is left on the button (%s)" % [metas])
	g.propagate_notification(Node.NOTIFICATION_EDITOR_POST_SAVE)
	check(b.has_theme_stylebox_override("normal"), "and go back on after")
	g.queue_free()
