extends "res://addons/woldui/tests/wold_test_base.gd"
## WoldButton: props pick the style, start/end icons, clean saved scenes, subclass hook.

const SCENE := "res://addons/woldui/components/wold_button/wold_button.tscn"
const EXAMPLE := "res://addons/woldui/gallery/examples/confirm_button.tscn"

var stage: Control


func _run() -> void:
	stage = Control.new()
	stage.theme = WoldThemeBuilder.build(tokens())
	get_root().add_child(stage)
	await _styles()
	await _icons_and_room()
	await _state_colours()
	await _saved_scene()
	await _theme_change()
	await _extension()
	finish(26)


func _button() -> WoldButton:
	var b: WoldButton = load(SCENE).instantiate()
	stage.add_child(b)
	return b


func _styles() -> void:
	var b := _button()
	await process_frame
	check(b.size.x > 0.0 and b.size.y > 0.0, "the scene instantiates on its own with a size")
	check(b.theme_type_variation == &"ButtonSecondary", "default: a secondary, medium button")
	b.shape = WoldButton.Shape.PRIMARY
	b.button_size = WoldButton.Size.SM
	check(b.theme_type_variation == &"ButtonPrimarySm", "shape + button_size pick the style (ButtonPrimarySm)")
	b.variant = "ButtonDangerLg"
	check(b.theme_type_variation == &"ButtonDangerLg", "variant replaces shape + size")
	b.variant = ""
	check(b.theme_type_variation == &"ButtonPrimarySm", "clearing variant goes back to shape + size")
	b.sound = "confirm"
	check(b.get_meta("wold_sound") == "confirm", "sound sets what WoldFeedback plays")
	b.queue_free()


func _width(b: WoldButton) -> float:
	return b.get_combined_minimum_size().x


func _icons_and_room() -> void:
	var t := tokens()
	var b := _button()
	b.text = "Go"
	await process_frame
	var plain := _width(b)
	b.icon_start = "swords"
	await process_frame
	check(b.icon != null and b.icon.get_size() == Vector2(t.icon_size_md, t.icon_size_md), "icon_start draws the library icon at the size's token")
	var with_start := _width(b)
	check(with_start > plain, "a start icon makes the button wider (%.0f -> %.0f)" % [plain, with_start])
	b.icon_end = "arrow-right"
	await process_frame
	var with_both := _width(b)
	var gap := stage.theme.get_constant("h_separation", "ButtonSecondary")
	check(is_equal_approx(with_both - with_start, t.icon_size_md + gap), "an end icon adds exactly its width plus the icon gap (%.0f)" % (with_both - with_start))
	check(b.end_icon() != null, "the end icon is resolved")

	b.button_size = WoldButton.Size.LG
	await process_frame
	check(b.icon.get_size().x == t.icon_size_lg and b.end_icon().get_size().x == t.icon_size_lg, "a larger button takes larger icons")

	var own := ImageTexture.create_from_image(Image.create(10, 10, false, Image.FORMAT_RGBA8))
	b.icon_start_texture = own
	check(b.icon == own, "a texture wins over the icon name")

	b.icon_start = ""
	b.icon_start_texture = null
	b.icon_end = ""
	await process_frame
	check(b.icon == null and b.end_icon() == null, "clearing the icons clears them")
	check(b.theme == null, "without an end icon the theme's styleboxes are used untouched")

	var only := _button()
	only.text = ""
	only.shape = WoldButton.Shape.ICON
	only.icon_start = "settings"
	await process_frame
	check(only.theme_type_variation == &"ButtonIcon" and only.icon != null, "an icon-only button")
	check(is_equal_approx(only.size.x, only.size.y), "an icon-only button is square (%s)" % only.size)
	b.queue_free()
	only.queue_free()


func _state_colours() -> void:
	var b := _button()
	b.shape = WoldButton.Shape.PRIMARY
	b.text = "Next"
	b.icon_end = "arrow-right"
	await process_frame
	check(b.end_icon_color() == b.get_theme_color("icon_normal_color"), "the end icon uses the normal icon colour at rest")
	b.disabled = true
	check(b.end_icon_color() == b.get_theme_color("icon_disabled_color"), "the end icon greys out with the button")
	check(b.end_icon_color() != b.get_theme_color("icon_normal_color"), "(and disabled really is a different colour)")
	b.queue_free()


## icons + end padding are rebuilt from props on load -> nothing baked into the scene
func _saved_scene() -> void:
	var b := _button()
	b.shape = WoldButton.Shape.OUTLINE
	b.icon_start = "map"
	b.icon_end = "chevron-down"
	b.text = "Map"
	await process_frame
	var packed := PackedScene.new()
	check(packed.pack(b) == OK, "the button packs into a scene")
	var state := packed.get_state()
	var saved := {}
	for i in state.get_node_property_count(0):
		saved[state.get_node_property_name(0, i)] = state.get_node_property_value(0, i)
	check(not saved.has("icon"), "the generated start icon is not saved (saved: %s)" % [saved.keys()])
	check(not saved.has("theme") and saved.keys().filter(func(k): return String(k).begins_with("theme_override")).is_empty(), "the end-icon padding is not saved")
	check(saved.get("icon_start") == "map" and saved.get("icon_end") == "chevron-down", "the props are saved")
	var again: WoldButton = packed.instantiate()
	stage.add_child(again)
	await process_frame
	check(again.icon != null and again.end_icon() != null and again.theme_type_variation == &"ButtonOutline", "a saved button rebuilds its icons and style on load")
	b.queue_free()
	again.queue_free()


func _theme_change() -> void:
	var b := _button()
	b.text = "Go"
	b.icon_end = "arrow-right"
	await process_frame
	var before := b.get_theme_stylebox("normal").get_margin(SIDE_RIGHT)
	stage.theme = WoldThemeBuilder.build(tokens().derive({"padding_md": Vector2i(40, 9)}))
	await process_frame
	var after := b.get_theme_stylebox("normal").get_margin(SIDE_RIGHT)
	check(is_equal_approx(after - before, 40 - tokens().padding_md.x), "a new theme re-pads the end icon from the new style (%.0f -> %.0f)" % [before, after])
	stage.theme = WoldThemeBuilder.build(tokens())
	b.queue_free()


func _extension() -> void:
	var c: WoldButton = load(EXAMPLE).instantiate()
	stage.add_child(c)
	await process_frame
	check(c is WoldButton and c.text == "Continue", "the inherited example scene instantiates with its own defaults")
	check(c.theme_type_variation == &"ButtonPrimary" and c.get_meta("wold_sound") == "confirm", "it keeps the props its scene set")
	check(c.hook_calls > 0, "the _wold_refresh hook runs")
	c.busy = true
	var spinner := WoldUIRuntime.instance().tokens.icon("loader-circle")
	check(c.disabled and c.end_icon() == spinner, "a new prop built only on the hook works (busy shows the spinner in the same pass)")
	c.busy = false
	check(not c.disabled and c.icon_end == "arrow-right", "and switches back")
	c.queue_free()
