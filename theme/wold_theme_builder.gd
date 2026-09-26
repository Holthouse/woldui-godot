@tool
class_name WoldThemeBuilder
## Tokens in, Theme out. Don't hand-edit the output, it gets overwritten.
##
## Layer order matters: core recipes, extra_recipes, variants, texture_overrides.
## Later layers build on (and overwrite) earlier ones.
# TODO: rebuilds everything on any token change. Fast enough so far.

const CORE_RECIPES: Array[Script] = [
	preload("recipes/base_recipe.gd"),
	preload("recipes/text_recipe.gd"),
	preload("recipes/panel_recipe.gd"),
	preload("recipes/card_recipe.gd"),
	preload("recipes/disclosure_recipe.gd"),
	preload("recipes/avatar_recipe.gd"),
	preload("recipes/alert_recipe.gd"),
	preload("recipes/status_recipe.gd"),
	preload("recipes/pager_recipe.gd"),
	preload("recipes/button_recipe.gd"),
	preload("recipes/input_recipe.gd"),
	preload("recipes/toggle_recipe.gd"),
	preload("recipes/stepper_recipe.gd"),
	preload("recipes/range_recipe.gd"),
	preload("recipes/tabs_recipe.gd"),
	preload("recipes/popup_recipe.gd"),
	preload("recipes/layout_recipe.gd"),
	preload("recipes/stat_recipe.gd"),
	preload("recipes/badge_recipe.gd"),
	preload("recipes/tooltip_recipe.gd"),
	preload("recipes/list_recipe.gd"),
	preload("recipes/tabs_bar_recipe.gd"),
	preload("recipes/prompt_recipe.gd"),
]

## Set on generated themes so tools can tell them apart from hand-made ones.
const META := &"woldui_generated"


static func build(t: WoldTokens, with_variants := true) -> Theme:
	var theme := Theme.new()
	if t.body_font:
		theme.default_font = t.body_font
	theme.default_font_size = t.base_font_size
	for recipe in CORE_RECIPES:
		recipe.contribute(theme, t)
	for recipe in t.extra_recipes:
		if recipe:
			assert(recipe.has_method("contribute"), "WoldUI: extra recipe %s has no static contribute(theme, tokens)" % recipe.resource_path)
			recipe.contribute(theme, t)
	if with_variants:
		for v in t.variants:
			if v:
				_apply_variant(theme, t, v)
	for key in t.texture_overrides:
		var parts: PackedStringArray = key.split("/")
		assert(parts.size() == 2, "WoldUI: texture_overrides key must be 'Type/item', got '%s'" % key)
		if parts.size() == 2 and t.texture_overrides[key]:
			theme.set_stylebox(parts[1], parts[0], t.texture_overrides[key])
	theme.set_meta(META, true)
	return theme


## All type variations in the theme.
static func variation_names(theme: Theme) -> PackedStringArray:
	var out := PackedStringArray()
	for type in theme.get_type_list():
		if theme.get_type_variation_base(type) != &"":
			out.append(type)
	out.sort()
	return out


## "ButtonGold" -> "Button"
static func native_base(theme: Theme, type: StringName) -> StringName:
	var seen := {}
	while theme.get_type_variation_base(type) != &"" and not seen.has(type):
		seen[type] = true
		type = theme.get_type_variation_base(type)
	return type


## Copies `built` into `target` so Controls already using it repaint, no reload.
# merge_with emits `changed` by itself (test_theme checks that)
static func update_in_place(target: Theme, built: Theme) -> void:
	target.clear()
	target.default_font = built.default_font
	target.default_font_size = built.default_font_size
	target.default_base_scale = built.default_base_scale
	target.merge_with(built)
	target.set_meta(META, true)


## foo_tokens.tres -> foo_tokens_theme.tres, same folder.
static func output_path(tokens_path: String) -> String:
	return tokens_path.get_basename() + "_theme.tres"


static func _apply_variant(theme: Theme, t: WoldTokens, v: WoldVariant) -> void:
	assert(v.name != "" and v.base != "", "WoldUI: a variant needs a name and a base")
	if v.name == "" or v.base == "":
		return
	theme.set_type_variation(v.name, v.base)
	if not v.token_overrides.is_empty():
		# NOTE: a whole theme build per variant, we only keep the base's items
		# from it. Wasteful but simple.
		var redrawn := build(t.derive(v.token_overrides), false)
		for data_type in Theme.DATA_TYPE_MAX:
			for item in redrawn.get_theme_item_list(data_type, v.base):
				theme.set_theme_item(data_type, item, v.name, redrawn.get_theme_item(data_type, item, v.base))
	for item in v.colors:
		theme.set_color(item, v.name, v.colors[item])
	for item in v.constants:
		theme.set_constant(item, v.name, v.constants[item])
	for item in v.font_sizes:
		theme.set_font_size(item, v.name, v.font_sizes[item])
	for item in v.fonts:
		theme.set_font(item, v.name, v.fonts[item])
	for item in v.styleboxes:
		theme.set_stylebox(item, v.name, v.styleboxes[item])
	for item in v.icons:
		theme.set_icon(item, v.name, v.icons[item])
