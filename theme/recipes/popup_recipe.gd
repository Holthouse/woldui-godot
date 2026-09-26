@tool
extends RefCounted
## PopupMenu (option lists, context menus) and plain popups.

const STYLES: PackedStringArray = []


static func contribute(theme: Theme, t: WoldTokens) -> void:
	theme.set_stylebox("panel", "PopupMenu", WoldStyle.raised(t.role("surface_overlay"), t.radius_md, Vector2i(t.space_xs, t.space_xs), t, t.role("border")))
	theme.set_stylebox("hover", "PopupMenu", WoldStyle.flat(t.role("accent_soft"), t.radius_sm))
	theme.set_stylebox("separator", "PopupMenu", WoldStyle.line(t.role("border"), t.border_width))
	theme.set_color("font_color", "PopupMenu", t.role("text"))
	theme.set_color("font_hover_color", "PopupMenu", t.role("text"))
	theme.set_color("font_disabled_color", "PopupMenu", t.role("text_disabled"))
	theme.set_color("font_accelerator_color", "PopupMenu", t.role("text_muted"))
	theme.set_color("font_separator_color", "PopupMenu", t.role("text_muted"))
	theme.set_constant("v_separation", "PopupMenu", t.space_sm)
	theme.set_constant("h_separation", "PopupMenu", t.space_sm)
	theme.set_constant("item_start_padding", "PopupMenu", t.space_md)
	theme.set_constant("item_end_padding", "PopupMenu", t.space_md)
	theme.set_font_size("font_size", "PopupMenu", t.font_size(0))
	theme.set_stylebox("panel", "PopupPanel", WoldStyle.raised(t.role("surface_overlay"), t.radius_md, Vector2i(t.space_md, t.space_md), t, t.role("border")))
