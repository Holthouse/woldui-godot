extends "res://addons/woldui/tests/wold_test_base.gd"
## WoldToggle: styles per state, outline and sizes, contrast of the on state.

const SCENE := "res://addons/woldui/components/wold_toggle/wold_toggle.tscn"

var stage: HBoxContainer


func _run() -> void:
	get_root().size = Vector2i(1280, 720)
	stage = HBoxContainer.new()
	stage.theme = WoldThemeBuilder.build(tokens())
	get_root().add_child(stage)
	await _states()
	await _variants()
	for path in ["res://addons/woldui/tokens/default_dark.tres", "res://addons/woldui/tokens/default_light.tres"]:
		_contrast(path)
	await _saved_scene()
	var ff: WoldToggle = load("res://addons/woldui/gallery/examples/fast_forward.tscn").instantiate()
	stage.add_child(ff)
	await process_frame
	check(ff.theme_type_variation == &"ToggleOutlineIcon" and ff.text == "" and ff.tooltip_text != "", "FastForward is a square outline toggle with a tooltip")
	ff.queue_free()
	finish(14)


func _toggle() -> WoldToggle:
	var b: WoldToggle = load(SCENE).instantiate()
	stage.add_child(b)
	return b


func _states() -> void:
	var t := tokens()
	var b := _toggle()
	await process_frame
	check(b.toggle_mode and b.theme_type_variation == &"Toggle" and b.icon != null, "a toggle is a WoldButton in toggle mode on the Toggle style")
	var off := b.get_theme_stylebox("normal") as StyleBoxFlat
	check(off.bg_color.a == 0.0 and b.get_theme_color("font_color") == t.role("text_muted"), "off it's quiet: no fill, muted text")
	b.button_pressed = true
	var on := b.get_theme_stylebox("pressed") as StyleBoxFlat
	check(on.bg_color == t.role("accent_soft") and b.get_theme_color("font_pressed_color") == t.role("accent_text"), "on it's tinted with accent text")
	check(b.get_theme_color("icon_pressed_color") == t.role("accent_text"), "and the icon follows")
	check((b.get_theme_stylebox("hover_pressed") as StyleBoxFlat).bg_color.a > on.bg_color.a, "hovering an on toggle deepens the tint")
	b.queue_free()


func _variants() -> void:
	var t := tokens()
	var b := _toggle()
	b.outline = true
	b.button_size = WoldButton.Size.SM
	await process_frame
	check(b.theme_type_variation == &"ToggleOutlineSm", "outline + SM gives ToggleOutlineSm")
	var off := b.get_theme_stylebox("normal") as StyleBoxFlat
	var on := b.get_theme_stylebox("pressed") as StyleBoxFlat
	check(off.border_width_left > 0 and off.border_color == t.role("border_strong") and on.border_color == t.role("accent"), "outline has an edge, accent when on")
	check(b.get_theme_font_size("font_size") == t.font_size(-1), "SM is the small type step")
	b.shape = WoldButton.Shape.PRIMARY
	check(b.theme_type_variation == &"ToggleOutlineSm", "most shapes don't change a toggle")
	b.shape = WoldButton.Shape.ICON
	b.text = ""
	await process_frame
	var sq := b.get_theme_stylebox("normal")
	check(b.theme_type_variation == &"ToggleOutlineIconSm" and sq.get_margin(SIDE_LEFT) == sq.get_margin(SIDE_TOP), "ICON gives the square icon-only toggle")
	b.queue_free()


func _contrast(path: String) -> void:
	var t := tokens(path)
	var bg := t.role("surface_raised").blend(t.role("accent_soft"))
	var ratio := WoldColor.contrast(t.role("accent_text"), bg)
	check(ratio >= 4.5, "%s: on-state text is %.2f:1 on its tint" % [path.get_file(), ratio])


func _saved_scene() -> void:
	var host := HBoxContainer.new()
	stage.add_child(host)
	var b: WoldToggle = load(SCENE).instantiate()
	host.add_child(b)
	b.owner = host
	b.button_pressed = true
	await process_frame
	var packed := PackedScene.new()
	packed.pack(host)
	var state := packed.get_state()
	var saved := {}
	for i in state.get_node_property_count(1):
		saved[state.get_node_property_name(1, i)] = true
	check(not saved.has("theme_type_variation") and saved.has("button_pressed"), "saves its state, not its style (saved: %s)" % [saved.keys()])
	host.queue_free()
