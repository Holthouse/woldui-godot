extends "res://addons/woldui/tests/wold_test_base.gd"
## WoldSelect: placeholder / value, the dropdown, keys and pad, sizes, menu icons, saved scenes.

const SCENE := "res://addons/woldui/components/wold_select/wold_select.tscn"

var stage: VBoxContainer


func _run() -> void:
	get_root().size = Vector2i(1280, 720)
	stage = VBoxContainer.new()
	stage.size = Vector2(600, 600)
	stage.theme = WoldThemeBuilder.build(tokens())
	get_root().add_child(stage)
	await _value()
	await _dropdown()
	await _keys()
	await _sizes()
	await _icons_tinted()
	await _menu_icons()
	await _saved_scene()
	var f = load("res://addons/woldui/gallery/examples/faction_select.tscn").instantiate()
	stage.add_child(f)
	await process_frame
	var none: Color = f.accent()
	f.selected = 1
	check(none.a == 0.0 and f.accent() == Color("3a7bd5") and f.value() == "Spidobots", "FactionSelect hands back the picked faction's colour")
	f.queue_free()
	finish(27)


func _select() -> WoldSelect:
	var s: WoldSelect = load(SCENE).instantiate()
	stage.add_child(s)
	return s


func _press(action: StringName) -> void:
	var e := InputEventAction.new()
	e.action = action
	e.pressed = true
	get_root().push_input(e)
	await process_frame
	e = e.duplicate()
	e.pressed = false
	get_root().push_input(e)
	await process_frame


func _value() -> void:
	var t := tokens()
	var s := _select()
	s.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	await process_frame
	var v := s.get_node("%Value") as Label
	check(s.value() == "" and v.text == "Map size" and v.get_theme_color("font_color") == t.role("text_muted"), "nothing picked: the placeholder, muted")
	s.selected = 2
	await process_frame
	check(s.value() == "Large" and v.text == "Large" and v.get_theme_color("font_color") == t.role("text"), "a pick shows its option in the text colour")
	check(s.size.x >= 220.0, "min_width keeps it wide (%.0f)" % s.size.x)
	s.icons = PackedStringArray(["", "", "mountain"])
	check(s.get_node("%Icon").visible and s.get_node("%Chevron").visible, "the picked option's icon shows, and the chevron")
	s.selected = 9
	check(s.selected == 3, "selected is clamped to the options")
	s.queue_free()


func _dropdown() -> void:
	var s := _select()
	s.selected = 1
	await process_frame
	s.pressed.emit()
	await process_frame
	var m := s.menu()
	check(s.is_open() and m.item_count == 4, "clicking opens the list with every option")
	check(m.is_item_checked(1) and not m.is_item_checked(0), "the current option is checked")
	check(m.get_focused_item() == 1, "and has the keyboard focus")
	# headless clamps popups into a tiny screen, so check what it asks for
	var r := s.dropdown_rect()
	check(r.size.x == int(s.size.x) and not m.shrink_width, "the list asks to be as wide as the field, and won't shrink")
	check(r.position.y > int(s.global_position.y + s.size.y), "and to drop below it (%s)" % [r])
	m.index_pressed.emit(3)
	await process_frame
	check(s.selected == 3 and s.value() == "Huge", "picking an option selects it")
	s.close()
	await process_frame
	s.disabled = true
	s.open()
	await process_frame
	check(not s.is_open(), "disabled: it won't open")
	s.queue_free()


func _keys() -> void:
	var s := _select()
	s.selected = 0
	await process_frame
	var seen := []
	s.item_selected.connect(func(i): seen.append(i))
	s.grab_focus()
	await _press(&"ui_accept")
	check(s.is_open(), "accept on the field opens the list")
	await _press(&"ui_down")
	# a stray click can take focus while it's open
	s.release_focus()
	await _press(&"ui_accept")
	await process_frame
	check(not s.is_open() and s.selected == 1 and seen == [1], "down + accept picks the next one and closes (%s)" % [seen])
	check(s.has_focus(), "focus comes back to the field")
	await _press(&"ui_accept")
	await _press(&"ui_down")
	await _press(&"ui_cancel")
	await process_frame
	check(not s.is_open() and s.selected == 1 and s.has_focus(), "cancel closes without changing anything")
	s.queue_free()


func _icons_tinted() -> void:
	var light := WoldThemeBuilder.build(tokens("res://addons/woldui/tokens/default_light.tres"))
	var host := Control.new()
	host.theme = light
	stage.add_child(host)
	var s: WoldSelect = load(SCENE).instantiate()
	s.icons = PackedStringArray(["map"])
	host.add_child(s)
	await process_frame
	s.open()
	await process_frame
	var tint := s.menu().get_item_icon_modulate(0)
	check(tint == tokens("res://addons/woldui/tokens/default_light.tres").role("text"), "list icons take the text colour, so they show on a light theme (%s)" % tint)
	s.close()
	host.queue_free()


func _sizes() -> void:
	var md := _select()
	var sm := _select()
	sm.select_size = WoldSelect.Size.SM
	await process_frame
	check(sm.theme_type_variation == &"SelectSm" and sm.size.y < md.size.y, "SM is a smaller field")
	check((sm.get_node("%Value") as Label).get_theme_font_size("font_size") == tokens().font_size(-1), "with the small type step")
	var lg := _select()
	lg.select_size = WoldSelect.Size.LG
	lg.min_width = 100
	lg.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	await process_frame
	await process_frame
	var v := lg.get_node("%Value") as Label
	var need := v.get_theme_font("font").get_string_size("Map size", HORIZONTAL_ALIGNMENT_LEFT, -1, v.get_theme_font_size("font_size")).x
	var w := lg.size.x
	lg.selected = 0
	await process_frame
	check(v.size.x >= need and is_equal_approx(lg.size.x, w), "the field fits its longest option and doesn't resize on a pick (%.0f for %.0f)" % [v.size.x, need])
	lg.queue_free()
	md.queue_free()
	sm.queue_free()


func _menu_icons() -> void:
	var s := _select()
	var plain := PopupMenu.new()
	stage.add_child(plain)
	await process_frame
	var m := s.menu()
	check(m.get_theme_icon("radio_checked") == stage.theme.get_icon("radio_checked", "SelectPopup"), "the select's list uses a plain check for the current option")
	check(plain.get_theme_icon("radio_checked") != m.get_theme_icon("radio_checked") and plain.get_theme_icon("radio_checked") == stage.theme.get_icon("radio_checked", "PopupMenu"), "while other menus keep radio dots")
	check(stage.theme.has_icon("submenu", "PopupMenu") and stage.theme.has_icon("checked", "PopupMenu"), "menus get drawn check boxes and a submenu arrow")
	s.queue_free()
	plain.queue_free()


func _saved_scene() -> void:
	var host := VBoxContainer.new()
	stage.add_child(host)
	var s: WoldSelect = load(SCENE).instantiate()
	host.add_child(s)
	s.owner = host
	s.selected = 2
	await process_frame
	check(s.menu().get_parent() == s and s.menu().owner == null and not s.get_children().has(s.menu()), "the list is an unowned internal child")
	var packed := PackedScene.new()
	packed.pack(host)
	var state := packed.get_state()
	var saved := {}
	for i in state.get_node_property_count(1):
		saved[state.get_node_property_name(1, i)] = true
	check(not saved.has("custom_minimum_size") and not saved.has("theme_type_variation") and not saved.has("text"), "derived state is not saved (saved: %s)" % [saved.keys()])
	var again := packed.instantiate()
	stage.add_child(again)
	await process_frame
	var copy := again.get_child(0) as WoldSelect
	check(copy.value() == "Large" and (copy.get_node("%Value") as Label).text == "Large", "it rebuilds with its pick")
	host.queue_free()
	again.queue_free()
