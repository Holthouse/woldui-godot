extends "res://addons/woldui/tests/wold_test_base.gd"
## WoldMenu: the builder, callbacks, check / radio, danger, shortcuts, placement, focus, menu styling.

var stage: VBoxContainer


func _run() -> void:
	get_root().size = Vector2i(1280, 720)
	stage = VBoxContainer.new()
	stage.size = Vector2(600, 600)
	stage.theme = WoldThemeBuilder.build(tokens())
	get_root().add_child(stage)
	await _builder()
	await _toggles()
	await _placement()
	await _focus()
	_styling()
	var um: WoldMenu = load("res://addons/woldui/gallery/examples/unit_menu.tscn").instantiate()
	stage.add_child(um)
	await process_frame
	var got := []
	um.command.connect(func(w): got.append(w))
	um.id_pressed.emit(um.get_item_id(1))
	um.id_pressed.emit(um.get_item_id(um.item_count - 1))
	check(got == [&"fortify", &"disband"] and um.is_danger(um.get_item_id(um.item_count - 1)), "UnitMenu reports picks through one signal (%s)" % [got])
	um.queue_free()
	finish(18)


func _menu() -> WoldMenu:
	var m := WoldMenu.new()
	stage.add_child(m)
	return m


func _builder() -> void:
	var t := tokens()
	var hits := []
	var m := _menu()
	var rename := m.item("Rename", func(): hits.append("rename"), "pencil", "F2")
	var gone := m.danger("Disband", func(): hits.append("disband"), "trash")
	m.separator("More")
	var sub := m.submenu("Send to", "send")
	sub.item("Allies")
	await process_frame
	check(m.item_count == 4 and m.get_item_text(m.get_item_index(rename)) == "Rename" and m.get_item_icon(0) != null, "items with icons")
	m.id_pressed.emit(rename)
	check(hits == ["rename"], "an item runs its callback")
	check(m.get_item_accelerator(0) == OS.find_keycode_from_string("F2"), "a shortcut shows on the right")
	m._tint()
	check(m.get_item_icon_modulate(0) == t.role("text") and m.get_item_icon_modulate(m.get_item_index(gone)) == t.role("danger_text"), "icons take the text colour, danger ones red")
	check(m.is_danger(gone) and not m.is_danger(rename), "danger items know it")
	check(m.get_item_submenu_node(3) == sub and sub.item_count == 1, "submenu() nests a WoldMenu")
	m.queue_free()


func _toggles() -> void:
	var m := _menu()
	var said := []
	var grid := m.check("Show grid", false, func(on): said.append(on))
	var a := m.radio("Small", &"size", true)
	var b := m.radio("Large", &"size", false, func(): said.append("large"))
	var other := m.radio("Fast", &"speed", true)
	m.id_pressed.emit(grid)
	check(m.is_item_checked(m.get_item_index(grid)) and said == [true], "a check item flips and hands over its state")
	m._tint()
	check(m.get_item_icon_modulate(m.get_item_index(grid)) == Color.WHITE, "check and radio marks keep their own colours")
	m.id_pressed.emit(b)
	check(m.is_item_checked(m.get_item_index(b)) and not m.is_item_checked(m.get_item_index(a)) and said.back() == "large", "radios untick the rest of their group")
	check(m.is_item_checked(m.get_item_index(other)), "and leave other groups alone")
	m.queue_free()


func _placement() -> void:
	var anchor := Button.new()
	anchor.text = "Actions"
	anchor.position = Vector2(200, 100)
	anchor.custom_minimum_size = Vector2(160, 40)
	var host := Control.new()
	stage.add_child(host)
	host.add_child(anchor)
	var m := _menu()
	m.item("One")
	m.item("A much longer second item")
	await process_frame
	var gap := tokens().space_xs
	var r := Rect2(anchor.get_screen_position(), anchor.size)
	var below := m.anchor_position(anchor)
	check(below.y == int(r.end.y + gap) and below.x == int(r.position.x), "a dropdown goes under its button, left edges lined up")
	var right := m.anchor_position(anchor, WoldMenu.Side.BOTTOM, WoldMenu.Align.END)
	check(right.x + m.get_contents_minimum_size().x == int(r.end.x), "END lines up the right edges")
	var above := m.anchor_position(anchor, WoldMenu.Side.TOP)
	check(above.y + m.get_contents_minimum_size().y == int(r.position.y - gap), "TOP sits above it")
	m.queue_free()
	host.queue_free()


func _focus() -> void:
	var b := Button.new()
	b.text = "Menu"
	stage.add_child(b)
	var m := _menu()
	m.item("One")
	await process_frame
	b.grab_focus()
	m.open_at(b)
	await process_frame
	check(m.visible, "open_at shows it")
	b.release_focus()
	m.hide()
	await process_frame
	check(b.has_focus(), "closing hands focus back")
	m.queue_free()
	b.queue_free()


func _styling() -> void:
	var t := tokens()
	var th := stage.theme
	check((th.get_stylebox("hover", "PopupMenu") as StyleBoxFlat).bg_color == t.role("accent_soft") and th.get_color("font_danger_color", "PopupMenu") == t.role("danger_text"), "menus: accent hover, a danger colour")
	check((th.get_stylebox("pressed", "MenuBar") as StyleBoxFlat).bg_color == t.role("accent_soft") and th.get_color("font_color", "MenuBar") == t.role("text"), "a MenuBar's open title is tinted the same way")
