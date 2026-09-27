@tool
extends RefCounted
## WoldTabs: tab buttons, the sliding indicator and its hairline.

const STYLES: PackedStringArray = ["TabButton", "TabsIndicator", "TabsTrack", "TabButtonPill", "TabsPillTrack", "TabsPill", "TabsPillInset", "TabsLineInset"]


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
	_pill(theme, t)


# The pill look: a sunken track with a raised pill sliding behind the picked
# tab. The tabs themselves only change colour.
static func _pill(theme: Theme, t: WoldTokens) -> void:
	var clear := Color(0, 0, 0, 0)
	var pad := Vector2i(t.space_md, t.space_xs + 2)
	theme.set_type_variation("TabButtonPill", "Button")
	for state in ["normal", "hover", "pressed", "hover_pressed", "disabled"]:
		theme.set_stylebox(state, "TabButtonPill", WoldStyle.flat(clear, t.radius_sm, pad))
	theme.set_stylebox("focus", "TabButtonPill", WoldStyle.ring(t, t.radius_sm))
	var lit := t.role("text")
	var colors := {
		"font_color": t.role("text_muted"), "font_hover_color": lit, "font_focus_color": lit,
		"font_pressed_color": lit, "font_hover_pressed_color": lit,
		"font_disabled_color": t.role("text_disabled"),
		"icon_normal_color": t.role("text_muted"), "icon_hover_color": lit, "icon_focus_color": lit,
		"icon_pressed_color": lit, "icon_hover_pressed_color": lit,
		"icon_disabled_color": t.role("text_disabled"),
	}
	for item in colors:
		theme.set_color(item, "TabButtonPill", colors[item])
	theme.set_font_size("font_size", "TabButtonPill", t.font_size(0))
	theme.set_constant("h_separation", "TabButtonPill", t.space_sm)
	theme.set_type_variation("TabsPillTrack", "Panel")
	theme.set_stylebox("panel", "TabsPillTrack", WoldStyle.flat(t.role("surface_sunken"), t.radius_md, Vector2i.ZERO, t.role("border"), t.border_width))
	theme.set_type_variation("TabsPill", "Panel")
	var pill := WoldStyle.raised(t.role("control"), t.radius_sm, Vector2i.ZERO, t, t.role("border"))
	pill.shadow_size = 4
	pill.shadow_offset = Vector2(0, 1)
	theme.set_stylebox("panel", "TabsPill", pill)
	# room between the track's edge and the pill; none for the line look
	for pair in [["TabsPillInset", t.space_xs], ["TabsLineInset", 0]]:
		theme.set_type_variation(pair[0], "MarginContainer")
		for side in ["margin_left", "margin_top", "margin_right", "margin_bottom"]:
			theme.set_constant(side, pair[0], pair[1])
