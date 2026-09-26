extends "res://addons/woldui/tests/wold_test_base.gd"
## tokens -> theme: ramps, contrast, styles, variants, recipes, textures, in-place update

const RECIPE_DIR := "res://addons/woldui/theme/recipes/"
const TOKEN_FILES := [
	"res://addons/woldui/tokens/default_dark.tres",
	"res://addons/woldui/tokens/default_light.tres",
]
## [text, surface, min ratio]. 4.5 = WCAG AA body, 3.0 = AA large text / UI parts
const CONTRAST_PAIRS := [
	["text", "surface_base", 4.5], ["text", "surface_raised", 4.5], ["text", "surface_overlay", 4.5],
	["text_muted", "surface_base", 4.5], ["text_muted", "surface_raised", 4.5], ["text_muted", "surface_overlay", 4.5],
	["text", "control", 4.5], ["text", "control_hover", 4.5],
	["on_accent", "accent", 4.5], ["on_danger", "danger", 4.5],
	["accent_text", "surface_raised", 4.5], ["success_text", "surface_raised", 4.5],
	["warning_text", "surface_raised", 4.5], ["danger_text", "surface_raised", 4.5],
	["focus", "surface_base", 3.0], ["focus", "surface_raised", 3.0],
	["text", "surface_hud", 4.5],
	# fields have to stand off the surface (light ones used to vanish) and read inside
	["field_border", "surface_base", 3.0], ["field_border", "surface_raised", 3.0],
	["field_border", "surface_overlay", 3.0], ["field_border", "field", 3.0],
	["text", "field", 4.5], ["text_muted", "field", 4.5],
	# segmented controls: unpicked labels sit on the sunken track
	["text_muted", "surface_sunken", 4.5],
]


func _run() -> void:
	_every_script_compiles("res://addons/woldui/")
	_ramps()
	for path in TOKEN_FILES:
		_contrast(path)
		_declared_styles(path)
	_seed_restyles()
	_variant()
	_extra_recipe_and_override()
	_update_in_place()
	await _resolves_on_a_real_control()
	_layout_spacing()
	finish(260)


## a broken script only fails when something loads it (bit me once with an enum
## named after an engine class). editor scripts skipped, they need the editor.
func _every_script_compiles(dir: String) -> void:
	for sub in DirAccess.get_directories_at(dir):
		if sub != "editor":
			_every_script_compiles(dir + sub + "/")
	for file in DirAccess.get_files_at(dir):
		if file.ends_with(".gd") and file != "plugin.gd":
			var script := load(dir + file) as GDScript
			check(script != null and script.can_instantiate(), "%s compiles" % (dir + file).trim_prefix("res://addons/woldui/"))


func _ramps() -> void:
	var seed := Color("c9a15b")
	var r := WoldColor.ramp(seed)
	check(r.size() == WoldColor.STEPS.size(), "a ramp has every step")
	check(r[500] == seed, "step 500 IS the seed, so the picked colour is the colour you get")
	var last := 2.0
	var monotonic := true
	for step in WoldColor.STEPS:
		monotonic = monotonic and r[step].ok_hsl_l < last
		last = r[step].ok_hsl_l
	check(monotonic, "ramp lightness falls strictly from 50 to 950")
	var pale := WoldColor.ramp(Color("f4efe4"))
	var pale_ok := true
	last = 2.0
	for step in WoldColor.STEPS:
		pale_ok = pale_ok and pale[step].ok_hsl_l < last
		last = pale[step].ok_hsl_l
	check(pale_ok, "a very pale seed still gives a monotonic ramp")
	var custom := WoldColor.ramp(seed, {700: Color.RED})
	check(custom[700] == Color.RED, "a ramp override replaces its step")
	check(absf(WoldColor.contrast(Color.BLACK, Color.WHITE) - 21.0) < 0.01, "black on white is 21:1")


func _contrast(path: String) -> void:
	var t := tokens(path)
	for pair in CONTRAST_PAIRS:
		var ratio := WoldColor.contrast(t.role(pair[0]), t.role(pair[1]))
		check(ratio >= pair[2], "%s: %s on %s is %.2f:1, needs %.1f" % [path.get_file(), pair[0], pair[1], ratio, pair[2]])


func _declared_styles(path: String) -> void:
	var t := tokens(path)
	var theme := WoldThemeBuilder.build(t)
	check(theme.has_meta(WoldThemeBuilder.META), "a built theme is marked as generated")
	var declared := 0
	for file in DirAccess.get_files_at(RECIPE_DIR):
		if not file.ends_with(".gd"):
			continue
		var recipe: Script = load(RECIPE_DIR + file)
		for style in recipe.STYLES:
			declared += 1
			var native := WoldThemeBuilder.native_base(theme, style)
			check(theme.get_type_variation_base(style) != &"", "%s declares %s and the theme has it" % [file, style])
			# popups are Windows, not Controls, and take variations just the same
			check(ClassDB.class_exists(native) and (ClassDB.is_parent_class(native, "Control") or ClassDB.is_parent_class(native, "Window")), "%s ends on a Control or Window class (got %s)" % [style, native])
	check(declared >= 76, "the recipes declare the whole catalogue (%d styles)" % declared)
	var names := WoldThemeBuilder.variation_names(theme)
	for style in names:
		check(theme.get_type_list().has(style), "variation_names lists only real types: " + style)


func _seed_restyles() -> void:
	var t := tokens()
	var before: StyleBoxFlat = WoldThemeBuilder.build(t).get_stylebox("normal", "ButtonPrimary")
	var after: StyleBoxFlat = WoldThemeBuilder.build(t.derive({"accent": Color("3a7bd5")})).get_stylebox("normal", "ButtonPrimary")
	check(before.bg_color != after.bg_color, "changing the accent seed repaints ButtonPrimary")
	check(after.bg_color == Color("3a7bd5"), "ButtonPrimary's fill is exactly the accent seed")
	var sharp: StyleBoxFlat = WoldThemeBuilder.build(t.derive({"radius_md": 0})).get_stylebox("normal", "PanelRaised")
	check(sharp.corner_radius_top_left == 0, "a radius token reaches the panels")
	check(WoldThemeBuilder.build(t.derive({"space_md": 20})).get_constant("separation", "StackMd") == 20, "a space token reaches the stacks")


func _variant() -> void:
	var t := tokens().derive({})
	var gold := WoldVariant.new()
	gold.name = "ButtonGold"
	gold.base = "ButtonPrimary"
	gold.token_overrides = {"accent": Color("e8b923")}
	gold.constants = {"h_separation": 30}
	t.variants = [gold]
	var theme := WoldThemeBuilder.build(t)
	check(theme.get_type_variation_base("ButtonGold") == &"ButtonPrimary", "a variant sits on its base")
	var fill: StyleBoxFlat = theme.get_stylebox("normal", "ButtonGold")
	check(fill != null and fill.bg_color == Color("e8b923"), "a variant is its base REDRAWN with its tokens")
	var base_fill: StyleBoxFlat = theme.get_stylebox("normal", "ButtonPrimary")
	check(base_fill.bg_color == t.accent, "the base keeps the original tokens")
	check(theme.get_constant("h_separation", "ButtonGold") == 30, "a variant's item override wins")
	check(not theme.has_stylebox("panel", "ButtonGold"), "a variant only takes its base's items, not the whole redrawn theme")


func _extra_recipe_and_override() -> void:
	var t := tokens().derive({})
	t.extra_recipes = [load("res://addons/woldui/tests/fixtures/fixture_recipe.gd")]
	var frame := StyleBoxTexture.new()
	t.texture_overrides = {"PanelOverlay/panel": frame}
	var theme := WoldThemeBuilder.build(t)
	check(theme.get_type_variation_base("ResourceChip") == &"PanelContainer", "an extra recipe adds the game's own style")
	var chip: StyleBoxFlat = theme.get_stylebox("panel", "ResourceChip")
	check(chip != null and chip.bg_color == t.role("surface_hud"), "an extra recipe builds from the same tokens")
	check(theme.get_stylebox("panel", "PanelOverlay") == frame, "a texture override replaces exactly one generated stylebox")
	check(theme.get_stylebox("panel", "PanelRaised") is StyleBoxFlat, "and leaves the others alone")


func _update_in_place() -> void:
	var target := WoldThemeBuilder.build(tokens())
	var changed := [false]
	target.changed.connect(func(): changed[0] = true)
	var built := WoldThemeBuilder.build(tokens().derive({"accent": Color("3a7bd5")}))
	WoldThemeBuilder.update_in_place(target, built)
	check(changed[0], "an in-place update tells users of the theme to repaint")
	check((target.get_stylebox("normal", "ButtonPrimary") as StyleBoxFlat).bg_color == Color("3a7bd5"), "an in-place update carries the new styles")
	check(target.get_type_variation_base("ButtonPrimarySm") == &"ButtonPrimary", "an in-place update keeps the style chain")


func _resolves_on_a_real_control() -> void:
	var root := Control.new()
	root.theme = WoldThemeBuilder.build(tokens())
	get_root().add_child(root)
	var b := Button.new()
	b.theme_type_variation = &"ButtonPrimarySm"
	root.add_child(b)
	var l := Label.new()
	l.theme_type_variation = &"Heading"
	root.add_child(l)
	await process_frame
	var t := tokens()
	check((b.get_theme_stylebox("normal") as StyleBoxFlat).bg_color == t.role("accent"), "a real Button resolves ButtonPrimarySm's fill")
	check(b.get_theme_font_size("font_size") == t.font_size(-1), "a small button uses the small type step")
	check(b.get_theme_stylebox("focus") is StyleBoxFlat and not (b.get_theme_stylebox("focus") as StyleBoxFlat).draw_center, "buttons get the focus ring")
	check(l.get_theme_font_size("font_size") == t.font_size(2), "Heading is two type steps up")
	check(l.get_theme_color("font_color") == t.role("text"), "a text style inherits the text colour from Label")
	root.queue_free()


func _layout_spacing() -> void:
	var t := tokens()
	var theme := WoldThemeBuilder.build(t)
	for size in ["Xs", "Sm", "Md", "Lg", "Xl", "Xxl"]:
		var px: int = t.get("space_" + size.to_lower())
		check(theme.get_constant("separation", "Stack" + size) == px, "Stack%s = space_%s" % [size, size.to_lower()])
		check(theme.get_constant("separation", "Row" + size) == px, "Row%s = space_%s" % [size, size.to_lower()])
		check(theme.get_constant("margin_left", "Inset" + size) == px, "Inset%s = space_%s" % [size, size.to_lower()])
