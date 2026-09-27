extends "res://addons/woldui/tests/wold_test_base.gd"
## WoldSegmented: segments, the sliding thumb, multiple, sizes, saved scenes.

const SCENE := "res://addons/woldui/components/wold_segmented/wold_segmented.tscn"

var stage: VBoxContainer


func _run() -> void:
	get_root().size = Vector2i(1280, 720)
	stage = VBoxContainer.new()
	stage.size = Vector2(800, 600)
	stage.theme = WoldThemeBuilder.build(tokens())
	get_root().add_child(stage)
	await _segments()
	await _thumb()
	await _reduced()
	await _multiple()
	await _sizes()
	await _saved_scene()
	await _vertical_and_outline()
	await _example()
	finish(26)


func _seg() -> WoldSegmented:
	var s: WoldSegmented = load(SCENE).instantiate()
	stage.add_child(s)
	return s


func _segments() -> void:
	var t := tokens()
	var s := _seg()
	await process_frame
	check(s.item_count() == 3 and s.item(1).text == "Cities" and s.item(1).icon != null, "one toggle button per option, with its icon")
	check(s.item(0).button_pressed and not s.item(1).button_pressed, "`selected` is pressed, the rest are not")
	check(s.item(0).get_theme_color("font_pressed_color") == t.role("text") and s.item(1).get_theme_color("font_color") == t.role("text_muted"), "the picked one reads stronger than the rest")
	check(s.item(0).focus_mode == Control.FOCUS_ALL, "segments take keyboard / pad focus")
	s.options = PackedStringArray(["", "Grid"])
	s.icons = PackedStringArray(["list"])
	await process_frame
	check(s.item(0).tooltip_text == "list" and s.item(1).icon == null, "an icon-only segment gets a tooltip")
	s.queue_free()


func _thumb() -> void:
	WoldUIRuntime.instance().reduced_motion = false
	var s := _seg()
	await process_frame
	await process_frame
	var first := Rect2(s.get_node("%Buttons").position + s.item(0).position, s.item(0).size)
	check(s.thumb_rect().is_equal_approx(first), "the thumb sits under the picked segment")
	var seen := []
	s.selected_changed.connect(func(i): seen.append(i))
	s.item(2).button_pressed = true
	check(s.selected == 2 and not s.item(0).button_pressed and seen == [2], "clicking a segment picks it, one signal (%s)" % [seen])
	await process_frame
	var mid := s.thumb_rect().position.x
	var last := Rect2(s.get_node("%Buttons").position + s.item(2).position, s.item(2).size)
	check(mid > first.position.x and mid < last.position.x, "the thumb slides over")
	await create_timer(tokens().duration_base + 0.1).timeout
	check(s.thumb_rect().is_equal_approx(last), "and lands under the new pick")
	s.queue_free()


func _reduced() -> void:
	WoldUIRuntime.instance().reduced_motion = true
	var s := _seg()
	await process_frame
	await process_frame
	s.selected = 2
	await process_frame
	var last := Rect2(s.get_node("%Buttons").position + s.item(2).position, s.item(2).size)
	check(s.thumb_rect().is_equal_approx(last), "reduced motion: the thumb jumps")
	WoldUIRuntime.instance().reduced_motion = false
	s.queue_free()


func _multiple() -> void:
	var s := _seg()
	s.multiple = true
	await process_frame
	var seen := []
	s.item_toggled.connect(func(i, on): seen.append([i, on]))
	s.item(0).button_pressed = true
	s.item(2).button_pressed = true
	check(s.pressed_items() == PackedInt32Array([0, 2]), "multiple: any number can be on (%s)" % [s.pressed_items()])
	s.item(0).button_pressed = false
	check(seen == [[0, true], [2, true], [0, false]], "item_toggled reports each change (%s)" % [seen])
	check(s.item(0).button_group == null, "no ButtonGroup in multiple mode")
	s.queue_free()


func _sizes() -> void:
	var md := _seg()
	var sm := _seg()
	sm.segment_size = WoldSegmented.Size.SM
	await process_frame
	check(sm.theme_type_variation == &"SegmentedSm" and sm.item(0).theme_type_variation == &"SegmentedButtonSm", "SM uses the small styles")
	check(sm.size.y < md.size.y, "and is shorter")
	var wide := _seg()
	wide.options = PackedStringArray(["A", "Longer one"])
	wide.icons = PackedStringArray()
	wide.stretch = true
	wide.custom_minimum_size.x = 500
	wide.size_flags_horizontal = Control.SIZE_FILL
	await process_frame
	await process_frame
	check(absf(wide.item(0).size.x - wide.item(1).size.x) < 1.0, "stretch shares the width equally")
	check(md.get_theme_stylebox("panel") is StyleBoxFlat and (md.get_theme_stylebox("panel") as StyleBoxFlat).bg_color == tokens().role("surface_sunken"), "the track is sunken")
	md.queue_free()
	sm.queue_free()
	wide.queue_free()


func _saved_scene() -> void:
	var host := VBoxContainer.new()
	stage.add_child(host)
	var s: WoldSegmented = load(SCENE).instantiate()
	host.add_child(s)
	s.owner = host
	s.options = PackedStringArray(["A", "B", "C"])
	s.selected = 2
	await process_frame
	check(s.item(0).owner == null, "the generated segments have no owner, so they are never saved")
	var packed := PackedScene.new()
	packed.pack(host)
	var state := packed.get_state()
	var saved := {}
	for i in state.get_node_property_count(1):
		saved[state.get_node_property_name(1, i)] = true
	check(not saved.has("theme_type_variation"), "the size style is not saved (saved: %s)" % [saved.keys()])
	var again := packed.instantiate()
	stage.add_child(again)
	await process_frame
	var copy := again.get_child(0) as WoldSegmented
	check(copy.item_count() == 3 and copy.item(2).button_pressed, "it rebuilds with the saved pick")
	host.queue_free()
	again.queue_free()


func _example() -> void:
	var s = load("res://addons/woldui/gallery/examples/map_layers.tscn").instantiate()
	stage.add_child(s)
	await process_frame
	s.item(0).button_pressed = true
	s.item(2).button_pressed = true
	check(s.layers() == PackedStringArray(["Grid", "Borders"]), "MapLayers names the layers that are on (%s)" % [s.layers()])
	s.queue_free()


func _vertical_and_outline() -> void:
	WoldUIRuntime.instance().reduced_motion = false
	var s := _seg()
	s.vertical = true
	s.stretch = true
	await process_frame
	await process_frame
	check((s.get_node("%Buttons") as BoxContainer).vertical and s.item(1).global_position.y > s.item(0).global_position.y, "vertical stacks the segments")
	check(s.item(0).size_flags_vertical == Control.SIZE_EXPAND_FILL, "stretch shares the height when vertical")
	var first := s.thumb_rect()
	s.selected = 2
	await create_timer(tokens().duration_base * 0.4).timeout
	var mid := s.thumb_rect()
	await create_timer(tokens().duration_base + 0.1).timeout
	check(mid.position.y > first.position.y and mid.position.y < s.thumb_rect().position.y and is_equal_approx(mid.position.x, first.position.x), "the thumb slides down, not across")
	s.outline = true
	s.segment_size = WoldSegmented.Size.SM
	await process_frame
	check(s.theme_type_variation == &"SegmentedOutlineSm", "outline + SM pick SegmentedOutlineSm")
	var sb := s.get_theme_stylebox("panel") as StyleBoxFlat
	check(sb.bg_color.a == 0.0 and sb.border_color.a > 0.0, "an outline track: edge, no fill")
	s.queue_free()
