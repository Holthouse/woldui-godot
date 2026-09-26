@tool
extends RefCounted
## WoldTabs: tab buttons, the sliding indicator and its hairline.

const STYLES: PackedStringArray = ["TabButton", "TabsIndicator", "TabsTrack"]


static func contribute(theme: Theme, t: WoldTokens) -> void:
	var pad := Vector2i(t.space_md, t.space_sm)
	var clear := Color(0, 0, 0, 0)
	theme.set_type_variation("TabButton", "Button")
	for state in ["normal", "pressed", "disabled"]:
		theme.set_stylebox(state, "TabButton", WoldStyle.flat(clear, t.radius_sm, pad))
	for state in ["hover", "hover_pressed"]:
		theme.set_stylebox(state, "TabButton", WoldStyle.flat(t.role("surface_hover"), t.radius_sm, pad))
	theme.set_stylebox("focus", "TabButton", WoldStyle.ring(t, t.radius_sm))
	var colors := {
		"font_color": t.role("text_muted"), "font_hover_color": t.role("text"), "font_focus_color": t.role("text"),
		"font_pressed_color": t.role("text"), "font_hover_pressed_color": t.role("text"),
		"font_disabled_color": t.role("text_disabled"),
		"icon_normal_color": t.role("text_muted"), "icon_hover_color": t.role("text"), "icon_focus_color": t.role("text"),
		"icon_pressed_color": t.role("accent_text"), "icon_hover_pressed_color": t.role("accent_text"),
		"icon_disabled_color": t.role("text_disabled"),
	}
	for item in colors:
		theme.set_color(item, "TabButton", colors[item])
	theme.set_font_size("font_size", "TabButton", t.font_size(0))
	theme.set_constant("h_separation", "TabButton", t.space_sm)
	theme.set_type_variation("TabsIndicator", "Panel")
	theme.set_stylebox("panel", "TabsIndicator", WoldStyle.flat(t.role("accent"), 99))
	theme.set_type_variation("TabsTrack", "Panel")
	theme.set_stylebox("panel", "TabsTrack", WoldStyle.flat(t.role("border"), 0))
