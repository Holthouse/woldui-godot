extends "res://addons/woldui/tests/wold_test_base.gd"
## WoldListRow: content, sizing, selection (+ButtonGroup), slots, feedback, saved scenes.

const SCENE := "res://addons/woldui/components/wold_list_row/wold_list_row.tscn"

var stage: VBoxContainer


func _run() -> void:
	get_root().size = Vector2i(1280, 720)
	stage = VBoxContainer.new()
	stage.size = Vector2(600, 600)
	stage.theme = WoldThemeBuilder.build(tokens())
	get_root().add_child(stage)
	await _content_and_size()
	await _selection()
	await _slots_and_feedback()
	await _saved_scene()
	await _theme_tint()
	await _looks_and_sizes()
	finish(26)


func _row() -> WoldListRow:
	var r: WoldListRow = load(SCENE).instantiate()
	stage.add_child(r)
	return r


func _content_and_size() -> void:
	var t := tokens()
	var r := _row()
	await process_frame
	check(r.size.x > 0.0 and r.size.y > 0.0, "the scene instantiates on its own with a size")
	check(r is Button and r.focus_mode == Control.FOCUS_ALL, "a row is a real, focusable Button")
	check((r.get_node("%Title") as Label).text == "Rivers, turn 42" and r.get_node("%Subtitle").visible, "title and subtitle show")
	check(r.get_node("%Icon").visible and r.get_node("%End").visible and r.get_node("%Meta").visible, "leading icon, trailing text and trailing icon show")
	var pad := r.get_theme_stylebox("normal").get_minimum_size()
	check(r.get_combined_minimum_size().y >= t.icon_size_md + pad.y, "the row is at least as tall as its content plus padding")
	var content := r.get_node("%Content") as Control
	check(is_equal_approx(content.position.x, r.get_theme_stylebox("normal").get_margin(SIDE_LEFT)), "its content sits inside the row's padding")
	r.subtitle = ""
	r.icon_name = ""
	r.trailing_text = ""
	r.trailing_icon = ""
	check(not r.get_node("%Subtitle").visible and not r.get_node("%Icon").visible and not r.get_node("%Meta").visible and not r.get_node("%End").visible, "empty parts take no space")
	r.min_height = 72
	check(r.get_combined_minimum_size().y >= 72.0, "min_height keeps a row tall")
	r.queue_free()


func _selection() -> void:
	var group := ButtonGroup.new()
	var rows: Array[WoldListRow] = []
	for i in 3:
		var r := _row()
		r.button_group = group
		rows.append(r)
	await process_frame
	rows[0].pressed.emit()
	rows[0].button_pressed = true
	check(rows[0].button_pressed, "clicking selects a row")
	rows[2].button_pressed = true
	check(rows[2].button_pressed and not rows[0].button_pressed, "in a ButtonGroup, selecting one deselects the others")
	var sel := rows[2].get_theme_stylebox("pressed") as StyleBoxFlat
	check(sel.border_width_left > 0 and sel.border_color == tokens().role("accent"), "the selected row has an accent bar on its leading edge")
	check(sel.bg_color == tokens().role("accent_soft"), "and an accent tint")
	var plain := rows[1].get_theme_stylebox("normal") as StyleBoxFlat
	check(plain.bg_color.a == 0.0, "an unselected row is quiet (no fill)")
	rows[1].selectable = false
	check(not rows[1].toggle_mode, "selectable off: a row is a plain action")
	for r in rows:
		r.queue_free()


func _slots_and_feedback() -> void:
	var r := _row()
	var badge: WoldBadge = load("res://addons/woldui/components/wold_badge/wold_badge.tscn").instantiate()
	badge.text = "Online"
	r.get_node("%Trailing").add_child(badge)
	var fb := WoldFeedback.new()
	stage.add_child(fb)
	await process_frame
	check(badge.is_visible_in_tree(), "the Trailing slot holds your own content (a badge)")
	var before := r.get_combined_minimum_size().x
	badge.text = "Online, in a match"
	await process_frame
	check(r.get_combined_minimum_size().x > before, "the row grows with its slot content")
	check(r.has_meta(WoldFeedback._WIRED), "WoldFeedback wires rows like any button")
	r.queue_free()
	fb.queue_free()


func _saved_scene() -> void:
	var host := VBoxContainer.new()
	stage.add_child(host)
	var r: WoldListRow = load(SCENE).instantiate()
	host.add_child(r)
	r.owner = host
	r.title = "Lobby 3"
	await process_frame
	var packed := PackedScene.new()
	packed.pack(host)
	var state := packed.get_state()
	var saved := {}
	for i in state.get_node_property_count(1):
		saved[state.get_node_property_name(1, i)] = true
	check(not saved.has("custom_minimum_size") and not saved.has("toggle_mode"), "the derived size and toggle mode are not saved (saved: %s)" % [saved.keys()])
	check(state.get_node_count() == 2, "nor are the row's insides")
	var again := packed.instantiate()
	stage.add_child(again)
	await process_frame
	var copy := again.get_child(0) as WoldListRow
	check(copy.title == "Lobby 3" and copy.toggle_mode and copy.custom_minimum_size.y > 0.0, "it rebuilds from its props on load")
	host.queue_free()
	again.queue_free()


# icons used to take the global tokens' colour, so a WoldScope or a second
# theme left them behind
func _theme_tint() -> void:
	var light := WoldThemeBuilder.build(tokens("res://addons/woldui/tokens/default_light.tres"))
	var host := VBoxContainer.new()
	host.theme = light
	stage.add_child(host)
	var r: WoldListRow = load(SCENE).instantiate()
	host.add_child(r)
	await process_frame
	await process_frame
	var want := light.get_color("font_color", "ListRowMeta")
	check(r.get_node("%Icon").self_modulate == want and r.get_node("%End").self_modulate == want, "icons take their colour from the theme the row sits in")
	host.queue_free()


func _looks_and_sizes() -> void:
	var r: WoldListRow = load(SCENE).instantiate()
	stage.add_child(r)
	await process_frame
	var plain_pad := r.get_theme_stylebox("normal").get_margin(SIDE_TOP)
	r.look = WoldListRow.Look.OUTLINE
	check(r.theme_type_variation == &"ListRowOutline" and (r.get_theme_stylebox("normal") as StyleBoxFlat).border_width_top > 0, "OUTLINE: ListRowOutline, with an edge at rest")
	r.look = WoldListRow.Look.MUTED
	check(r.theme_type_variation == &"ListRowMuted" and (r.get_theme_stylebox("normal") as StyleBoxFlat).bg_color.a > 0.0, "MUTED: a soft fill at rest")
	var muted_hover := (r.get_theme_stylebox("hover") as StyleBoxFlat).bg_color.a
	check(muted_hover > (r.get_theme_stylebox("normal") as StyleBoxFlat).bg_color.a, "and hover is still a step up from it")
	r.row_size = WoldListRow.Size.SM
	await process_frame
	check(r.theme_type_variation == &"ListRowMutedSm" and r.get_theme_stylebox("normal").get_margin(SIDE_TOP) < plain_pad, "SM: tighter padding")
	check((r.get_node("%Title") as Label).theme_type_variation == &"ListRowTitleSm", "and a smaller title")
	r.queue_free()
