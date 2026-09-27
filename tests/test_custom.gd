extends "res://addons/woldui/tests/wold_test_base.gd"
## WoldCustom: per-control changes on top of the design system, and the
## tokens-driven WoldFeedback.

var stage: VBoxContainer
var ui: WoldUIRuntime


func _run() -> void:
	ui = WoldUIRuntime.instance()
	ui.reduced_motion = false
	stage = VBoxContainer.new()
	stage.theme = WoldThemeBuilder.build(tokens())
	get_root().add_child(stage)
	await _boxes()
	await _text_and_clear()
	await _component_labels()
	await _feedback_bits()
	await _runtime_and_saved()
	await _with_fades()
	await _strip()
	await _auto_feedback()
	finish(36)


func _custom(node: Control, setup: Callable) -> WoldCustom:
	var c := WoldCustom.new()
	setup.call(c)
	node.set_meta(WoldCustomize.META, c)
	WoldCustomize.apply(node)
	return c


func _near(a: Color, b: Color) -> bool:
	return absf(a.r - b.r) + absf(a.g - b.g) + absf(a.b - b.b) + absf(a.a - b.a) < 0.01


func _boxes() -> void:
	var b := Button.new()
	b.text = "Recruit"
	stage.add_child(b)
	await process_frame
	var theme_hover := b.get_theme_stylebox("hover") as StyleBoxFlat
	var theme_focus := b.get_theme_stylebox("focus") as StyleBoxFlat
	var gold := Color(0.85, 0.65, 0.2)
	var c := _custom(b, func(c): c.fill = gold; c.corner_radius = 12; c.padding = Vector2i(30, 14))
	var normal := b.get_theme_stylebox("normal") as StyleBoxFlat
	var hover := b.get_theme_stylebox("hover") as StyleBoxFlat
	var pressed := b.get_theme_stylebox("pressed") as StyleBoxFlat
	check(b.has_theme_stylebox_override("normal") and _near(normal.bg_color, gold), "a fill lands on the button's normal box")
	check(not _near(hover.bg_color, gold) and not _near(pressed.bg_color, hover.bg_color), "hover and pressed get their own steps of it")
	var away := WoldColor.luminance(pressed.bg_color) < WoldColor.luminance(hover.bg_color) if WoldColor.luminance(gold) > 0.5 else WoldColor.luminance(pressed.bg_color) > WoldColor.luminance(hover.bg_color)
	check(away, "pressed steps further than hover, darker on a light fill, lighter on a dark one")
	check((b.get_theme_stylebox("disabled") as StyleBoxFlat).bg_color.a < gold.a, "disabled is a faded one")
	check(normal.corner_radius_top_left == 12 and (b.get_theme_stylebox("focus") as StyleBoxFlat).corner_radius_top_left == 12, "corner radius on every box, the focus ring too")
	check(normal.content_margin_left == 30 and normal.content_margin_top == 14, "padding")
	var ring := b.get_theme_stylebox("focus") as StyleBoxFlat
	check(_near(ring.bg_color, theme_focus.bg_color) and ring.draw_center == theme_focus.draw_center and _near(ring.border_color, theme_focus.border_color), "the focus ring keeps its own colours")
	WoldCustomize.apply(b)
	check(_near((b.get_theme_stylebox("hover") as StyleBoxFlat).bg_color, hover.bg_color), "applying again doesn't compound")
	c.fill = Color(0, 0, 0, 0)
	WoldCustomize.apply(b)
	check(_near((b.get_theme_stylebox("hover") as StyleBoxFlat).bg_color, theme_hover.bg_color), "clearing the fill gives the theme's colours back")
	var panel := PanelContainer.new()
	stage.add_child(panel)
	await process_frame
	_custom(panel, func(c): c.fill = Color.DARK_SLATE_BLUE; c.border = Color.GOLD)
	var sb := panel.get_theme_stylebox("panel") as StyleBoxFlat
	check(_near(sb.bg_color, Color.DARK_SLATE_BLUE) and _near(sb.border_color, Color.GOLD) and sb.border_width_top >= 1, "any Control: a panel gets its fill and a visible border")
	var bare := Button.new()
	bare.theme_type_variation = &"ButtonPrimary"
	stage.add_child(bare)
	await process_frame
	check((bare.get_theme_stylebox("normal") as StyleBoxFlat).border_width_top == 0, "(fixture) primary buttons have no border")
	_custom(bare, func(c): c.border = Color.GOLD)
	check((bare.get_theme_stylebox("normal") as StyleBoxFlat).border_width_top >= 1, "a border colour on a borderless button makes the border show")
	bare.queue_free()
	b.queue_free()
	panel.queue_free()


func _text_and_clear() -> void:
	var b := Button.new()
	b.text = "Back"
	var own := Color.ORANGE_RED
	b.add_theme_color_override("font_outline_color", own)
	stage.add_child(b)
	await process_frame
	var disabled := b.get_theme_color("font_disabled_color")
	_custom(b, func(c): c.text = Color.AQUA; c.font_size = 26)
	check(b.get_theme_color("font_color") == Color.AQUA and b.get_theme_color("font_hover_color") == Color.AQUA and b.get_theme_color("icon_normal_color") == Color.AQUA, "text colour on the label and icon in every state")
	check(b.get_theme_color("font_disabled_color") == disabled, "but disabled stays the theme's")
	check(b.get_theme_font_size("font_size") == 26, "font size")
	b.set_meta(WoldCustomize.META, null)
	b.remove_meta(WoldCustomize.META)
	WoldCustomize.apply(b)
	check(not b.has_theme_color_override("font_color") and not b.has_theme_font_size_override("font_size") and not b.has_meta(WoldCustomize.APPLIED), "removing the WoldCustom takes its overrides off")
	check(b.get_theme_color("font_outline_color") == own, "and leaves the ones you set yourself")
	var label := Label.new()
	label.text = "Gold"
	stage.add_child(label)
	await process_frame
	_custom(label, func(c): c.text = Color.GOLD)
	check(label.get_theme_color("font_color") == Color.GOLD, "a plain Label takes a text colour")
	b.queue_free()
	label.queue_free()


func _component_labels() -> void:
	var card: WoldCard = load("res://addons/woldui/components/wold_card/wold_card.tscn").instantiate()
	stage.add_child(card)
	await process_frame
	_custom(card, func(c): c.text = Color.PINK)
	var title := card.get_node("%Title") as Label
	check(title.get_theme_color("font_color") == Color.PINK, "a WoldUI component's own labels take the text colour")
	card.remove_meta(WoldCustomize.META)
	WoldCustomize.apply(card)
	check(title.get_theme_color("font_color") != Color.PINK, "and give it back")
	card.queue_free()


func _feedback_bits() -> void:
	var b: WoldButton = load("res://addons/woldui/components/wold_button/wold_button.tscn").instantiate()
	b.sound = "back"
	stage.add_child(b)
	await process_frame
	var flash := WoldPressFlash.new()
	_custom(b, func(c): c.sound = WoldCustom.Sound.CONFIRM; c.press = WoldCustom.Press.CUSTOM; c.press_effect = flash)
	check(b.get_meta("wold_sound") == "confirm" and b.get_meta("wold_press_effect") == flash, "sound and press effect for just this button")
	b.remove_meta(WoldCustomize.META)
	WoldCustomize.apply(b)
	check(b.get_meta("wold_sound") == "back" and not b.has_meta("wold_press_effect"), "and the button's own settings come back")
	check(WoldCustom.new().resource_local_to_scene, "a WoldCustom is local to its scene, copies don't share it")
	b.queue_free()


func _runtime_and_saved() -> void:
	var host := VBoxContainer.new()
	stage.add_child(host)
	var b := Button.new()
	b.text = "Saved"
	var c := WoldCustom.new()
	c.fill = Color.SEA_GREEN
	b.set_meta(WoldCustomize.META, c)
	host.add_child(b)
	b.owner = host
	await process_frame
	await process_frame
	check(_near((b.get_theme_stylebox("normal") as StyleBoxFlat).bg_color, Color.SEA_GREEN), "the WoldUI autoload applies it when the node enters the game")
	var packed := PackedScene.new()
	packed.pack(host)
	var again := packed.instantiate()
	stage.add_child(again)
	await process_frame
	await process_frame
	var copy := again.get_child(0) as Button
	check(copy.get_meta(WoldCustomize.META) is WoldCustom and _near((copy.get_theme_stylebox("normal") as StyleBoxFlat).bg_color, Color.SEA_GREEN), "it's saved with the scene and comes back")
	host.queue_free()
	again.queue_free()


func _with_fades() -> void:
	var host := VBoxContainer.new()
	stage.add_child(host)
	host.add_child(WoldFeedback.new())
	var b := Button.new()
	b.text = "Faded"
	var c := WoldCustom.new()
	c.fill = Color.STEEL_BLUE
	b.set_meta(WoldCustomize.META, c)
	host.add_child(b)
	await process_frame
	await process_frame
	var fade: Object = b.get_meta(&"_wold_fade")
	check(_near(fade.box().bg_color, Color.STEEL_BLUE), "under a WoldFeedback the state fade rests on the custom fill")
	b.notification(Control.NOTIFICATION_MOUSE_ENTER)
	await create_timer(tokens().duration_fast + 0.1).timeout
	check(_near(fade.box().bg_color, WoldCustomize.shade(Color.STEEL_BLUE, "hover")), "and fades to its hover step")
	c.fill = Color.CRIMSON
	WoldCustomize.apply(b)
	await process_frame
	check(_near(fade.box().bg_color, WoldCustomize.shade(Color.CRIMSON, "hover")) and b.get_theme_stylebox("hover") == b.get_theme_stylebox("normal"), "a later change goes to the fade, which keeps drawing")
	host.queue_free()


func _strip() -> void:
	var strip: WoldButtonStrip = load("res://addons/woldui/components/wold_button_strip/wold_button_strip.tscn").instantiate()
	var bs := []
	for n in ["A", "B", "C"]:
		var b := Button.new()
		b.text = n
		strip.add_child(b)
		bs.append(b)
	stage.add_child(strip)
	await process_frame
	await process_frame
	_custom(bs[1], func(c): c.corner_radius = 9)
	strip._join()
	await process_frame
	check((bs[1].get_theme_stylebox("normal") as StyleBoxFlat).corner_radius_top_left == 9 and not strip.is_joined(bs[1]), "a customised button in a strip keeps its own corners")
	strip.queue_free()


func _auto_feedback() -> void:
	check(ui.tokens.auto_feedback and ui.feedback == null, "no automatic WoldFeedback for a script run (no current scene)")
	ui.start_feedback()
	check(ui.feedback == null, "start_feedback() alone doesn't start one there either")
	ui.start_feedback(true)
	check(ui.feedback != null, "start_feedback(true) does, for a game's own tests")
	ui.feedback.free()
	ui.feedback = null
	var scene := VBoxContainer.new()
	get_root().add_child(scene)
	current_scene = scene
	ui.tokens.fade_states = false
	ui.start_feedback()
	ui.tokens.fade_states = true
	check(ui.feedback != null and ui.feedback.auto and ui.feedback.get_parent() == get_root(), "a running game gets one on the root")
	check(not ui.feedback.fade_states and ui.feedback.hover_sound == ui.tokens.hover_sound, "set from the tokens' Feedback group")
	var mine := VBoxContainer.new()
	scene.add_child(mine)
	var own := WoldFeedback.new()
	own.fade_states = false
	mine.add_child(own)
	var b := Button.new()
	mine.add_child(b)
	var loose := Button.new()
	scene.add_child(loose)
	await process_frame
	await process_frame
	check(b.has_meta(WoldFeedback._WIRED) and not b.has_meta(&"_wold_fade"), "a WoldFeedback of your own wins in its part of the tree")
	check(loose.has_meta(WoldFeedback._WIRED) and not loose.has_meta(&"_wold_fade"), "everything else gets the automatic one, with the tokens' settings")
	ui.feedback.queue_free()
	ui.feedback = null
	current_scene = null
	scene.queue_free()
	await process_frame
