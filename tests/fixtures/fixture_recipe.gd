extends RefCounted
## game-side recipe, for test_theme

const STYLES: PackedStringArray = ["ResourceChip"]


static func contribute(theme: Theme, t: WoldTokens) -> void:
	theme.set_type_variation("ResourceChip", "PanelContainer")
	theme.set_stylebox("panel", "ResourceChip", WoldStyle.flat(t.role("surface_hud"), t.radius_sm, Vector2i(t.space_sm, t.space_xs)))
