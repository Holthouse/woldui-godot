@tool
extends RefCounted
## WoldPageDots and WoldCarousel. Idle dots use the field edge colour: they're
## controls, so they need 3:1 on the surface like a field border does.

const STYLES: PackedStringArray = ["PageDots"]


static func contribute(theme: Theme, t: WoldTokens) -> void:
	theme.set_type_variation("PageDots", "Control")
	theme.set_color("dot", "PageDots", t.role("field_border"))
	theme.set_color("dot_hover", "PageDots", t.role("text_muted"))
	theme.set_color("active", "PageDots", t.role("accent"))
	theme.set_constant("dot", "PageDots", t.space_sm)
	theme.set_constant("pill", "PageDots", t.space_sm * 3)
	theme.set_constant("gap", "PageDots", t.space_sm - 2)
