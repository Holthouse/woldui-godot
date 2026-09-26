@tool
extends RefCounted
## Native TabBar/TabContainer. Selected tab gets an accent underline.

const STYLES: PackedStringArray = []


static func contribute(theme: Theme, t: WoldTokens) -> void:
	var pad := Vector2i(t.space_md, t.space_sm)
	for type in ["TabBar", "TabContainer"]:
		theme.set_stylebox("tab_unselected", type, WoldStyle.underline(Color(0, 0, 0, 0), t.focus_width, pad))
		theme.set_stylebox("tab_hovered", type, WoldStyle.underline(t.role("border_strong"), t.focus_width, pad))
		theme.set_stylebox("tab_selected", type, WoldStyle.underline(t.role("accent"), t.focus_width, pad))
		theme.set_stylebox("tab_disabled", type, WoldStyle.underline(Color(0, 0, 0, 0), t.focus_width, pad))
		theme.set_stylebox("tab_focus", type, WoldStyle.ring(t, t.radius_sm))
		theme.set_color("font_unselected_color", type, t.role("text_muted"))
		theme.set_color("font_hovered_color", type, t.role("text"))
		theme.set_color("font_selected_color", type, t.role("text"))
		theme.set_color("font_disabled_color", type, t.role("text_disabled"))
		theme.set_color("icon_unselected_color", type, t.role("text_muted"))
		theme.set_color("icon_hovered_color", type, t.role("text"))
		theme.set_color("icon_selected_color", type, t.role("text"))
		theme.set_color("icon_disabled_color", type, t.role("text_disabled"))
		theme.set_color("drop_mark_color", type, t.role("accent"))
		theme.set_font_size("font_size", type, t.font_size(0))
	theme.set_constant("h_separation", "TabBar", t.space_xs)
	theme.set_stylebox("panel", "TabContainer", WoldStyle.flat(t.role("surface_raised"), t.radius_md, Vector2i(t.space_lg, t.space_lg)))
	theme.set_stylebox("tabbar_background", "TabContainer", WoldStyle.line(t.role("border"), t.border_width))
	theme.set_constant("side_margin", "TabContainer", 0)
