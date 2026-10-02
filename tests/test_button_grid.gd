extends "res://addons/woldui/tests/wold_test_base.gd"
## WoldButton's look x tone grid: every style there, readable in both modes,
## sizes chained, the props picking the right name.

const Recipe := preload("res://addons/woldui/theme/recipes/button_recipe.gd")
const DARK := "res://addons/woldui/tokens/default_dark.tres"
const LIGHT := "res://addons/woldui/tokens/default_light.tres"

var stage: Control


func _run() -> void:
	for path in [DARK, LIGHT]:
		_grid(path)
		_readable(path)
	stage = Control.new()
	stage.theme = WoldThemeBuilder.build(tokens())
	get_root().add_child(stage)
	await _props()
	await _icon_only_and_sizes()
	await _link()
	finish(44)


func _grid(path: String) -> void:
	var theme := WoldThemeBuilder.build(tokens(path))
	var missing := []
	var unchained := []
	for style in Recipe.all_styles():
		if not theme.get_type_variation_base(style):
			missing.append(style)
			continue
		var medium: String = style.trim_suffix("Xs").trim_suffix("Sm").trim_suffix("Lg")
		var want := "Button" if medium == style else medium
		if theme.get_type_variation_base(style) != StringName(want):
			unchained.append(style)
	check(Recipe.all_styles().size() == 140, "7 looks x 5 tones x 4 sizes")
	check(missing.is_empty(), "%s: every grid style is in the theme (missing %s)" % [path.get_file(), missing.slice(0, 4)])
	check(unchained.is_empty(), "%s: sizes are based on their medium style, medium on Button (%s)" % [path.get_file(), unchained.slice(0, 4)])
	check(theme.has_stylebox("hover_pressed", "ButtonSolidAccent"), "%s: the grid has a hover_pressed box" % path.get_file())
	var flat_sizes := []
	for look in Recipe.LOOKS:
		for tone in Recipe.TONES:
			var base: String = "Button" + look + tone
			var pads := []
			var fonts := []
			for size in Recipe.GRID_SIZES:
				pads.append(theme.get_stylebox("normal", base + size).get_margin(SIDE_LEFT))
				fonts.append(theme.get_font_size("font_size", base + size))
			if not (pads[0] < pads[1] and pads[1] < pads[2] and pads[2] < pads[3] and fonts[0] < fonts[1] and fonts[1] < fonts[2] and fonts[2] < fonts[3]):
				flat_sizes.append(base)
	check(flat_sizes.is_empty(), "%s: Xs < Sm < Md < Lg in padding and font (%s)" % [path.get_file(), flat_sizes.slice(0, 3)])


# text on its own fill, flattened over the surfaces a button sits on
func _readable(path: String) -> void:
	var t := tokens(path)
	var theme := WoldThemeBuilder.build(t)
	var grounds := [t.role("surface_base"), t.role("surface_raised")]
	for look in Recipe.LOOKS:
		var worst := 99.0
		var where := ""
		for tone in Recipe.TONES:
			var style: String = "Button" + look + tone
			for pair in [["normal", "font_color"], ["hover", "font_hover_color"], ["pressed", "font_pressed_color"]]:
				var fill: Color = (theme.get_stylebox(pair[0], style) as StyleBoxFlat).bg_color
				var ink := theme.get_color(pair[1], style)
				for ground in grounds:
					var bg: Color = ground.blend(fill)
					var ratio := WoldColor.contrast(ink, bg)
					if ratio < worst:
						worst = ratio
						where = "%s %s" % [style, pair[0]]
		check(worst >= 4.5, "%s: %s text reads on its fill, worst %.2f:1 (%s)" % [path.get_file(), look, worst, where])
	var faint := []
	for look in ["Solid", "Shadow"]:
		for tone in Recipe.TONES:
			var fill := (theme.get_stylebox("normal", "Button" + look + tone) as StyleBoxFlat).bg_color
			for ground in grounds:
				if WoldColor.contrast(ground.blend(fill), ground) < 1.15:
					faint.append(look + tone)
	check(faint.is_empty(), "%s: a solid button's fill shows against the page (%s)" % [path.get_file(), faint])
	var edge_worst := 99.0
	for tone in Recipe.TONES:
		var edge := (theme.get_stylebox("normal", "ButtonBordered" + tone) as StyleBoxFlat).border_color
		for ground in grounds:
			edge_worst = minf(edge_worst, WoldColor.contrast(edge, ground))
	check(edge_worst >= 3.0, "%s: bordered edges stand out, worst %.2f:1" % [path.get_file(), edge_worst])


func _button() -> WoldButton:
	var b: WoldButton = load("res://addons/woldui/components/wold_button/wold_button.tscn").instantiate()
	b.text = "Recruit"
	stage.add_child(b)
	return b


func _props() -> void:
	var b := _button()
	await process_frame
	check(b.look == WoldButton.Look.SHAPE and b.style_name() == &"ButtonSecondary", "look SHAPE (the default) keeps the old shape names")
	b.look = WoldButton.Look.FLAT
	b.tone = WoldButton.Tone.SUCCESS
	b.button_size = WoldButton.Size.SM
	check(b.theme_type_variation == &"ButtonFlatSuccessSm", "look + tone + size pick the grid style")
	b.button_size = WoldButton.Size.XS
	check(b.theme_type_variation == &"ButtonFlatSuccessXs", "XS is a grid size")
	check(b.get_theme_color("font_color") == stage.theme.get_color("font_color", "ButtonFlatSuccess") and b.get_theme_color("font_color") != stage.theme.get_color("font_color", "Button"), "sizes take their colours from the medium style")
	b.look = WoldButton.Look.SHAPE
	check(b.theme_type_variation == &"ButtonSecondarySm", "the old shapes have no XS, so they fall back to Sm")
	b.variant = "ButtonGhost"
	b.look = WoldButton.Look.SOLID
	check(b.theme_type_variation == &"ButtonGhost", "variant still wins over everything")
	b.queue_free()
	var toggle: WoldToggle = load("res://addons/woldui/components/wold_toggle/wold_toggle.tscn").instantiate()
	toggle.button_size = WoldButton.Size.XS
	stage.add_child(toggle)
	await process_frame
	check(stage.theme.get_type_variation_base(toggle.theme_type_variation) != &"", "WoldToggle at XS lands on a real style")
	toggle.queue_free()


func _icon_only_and_sizes() -> void:
	var sizes := {}
	for z in [WoldButton.Size.XS, WoldButton.Size.SM]:
		var sized := _button()
		sized.look = WoldButton.Look.SOLID
		sized.button_size = z
		await process_frame
		sizes[z] = sized.get_combined_minimum_size()
		sized.queue_free()
	check(sizes[WoldButton.Size.XS].y < sizes[WoldButton.Size.SM].y and sizes[WoldButton.Size.XS].x < sizes[WoldButton.Size.SM].x, "XS is smaller than SM")
	var b := _button()
	b.text = ""
	b.look = WoldButton.Look.LIGHT
	b.icon_start = "settings"
	await process_frame
	var wide := b.get_combined_minimum_size()
	b.icon_only = true
	await process_frame
	await process_frame
	var sq := b.get_combined_minimum_size()
	check(sq.x < wide.x and absf(sq.x - sq.y) <= 1.0, "icon_only makes it square (%s)" % sq)
	check(b.get_theme_stylebox("normal").get_margin(SIDE_LEFT) == b.get_theme_stylebox("normal").get_margin(SIDE_TOP), "by giving the sides the top padding")
	var packed := PackedScene.new()
	packed.pack(b)
	var text := var_to_str(packed._bundled)
	check(not text.contains("Theme"), "the square padding isn't saved with the scene")
	b.queue_free()


func _link() -> void:
	WoldUIRuntime.instance().reduced_motion = false
	var b := _button()
	b.look = WoldButton.Look.LINK
	await process_frame
	check(b.link_underline() == 0.0, "a link has no underline at rest")
	b.mouse_entered.emit()
	await create_timer(tokens().duration_fast * 0.4).timeout
	check(b.link_underline() > 0.0 and b.link_underline() < 1.0, "hover eases the underline in")
	await create_timer(tokens().duration_fast + 0.1).timeout
	check(b.link_underline() == 1.0, "all the way")
	b.mouse_exited.emit()
	await create_timer(tokens().duration_fast + 0.1).timeout
	check(b.link_underline() == 0.0, "and back out")
	var solid := _button()
	solid.look = WoldButton.Look.SOLID
	await process_frame
	solid.mouse_entered.emit()
	await create_timer(tokens().duration_fast + 0.1).timeout
	check(solid.link_underline() == 0.0, "only the link look underlines")
	b.queue_free()
	solid.queue_free()
