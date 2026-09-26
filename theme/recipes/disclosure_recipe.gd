@tool
extends RefCounted
## WoldCollapsible / WoldAccordion: a full-width trigger row and the line
## between accordion items.

const STYLES: PackedStringArray = ["CollapsibleTrigger", "AccordionTrigger", "CollapsibleBody"]


static func contribute(theme: Theme, t: WoldTokens) -> void:
	for style in ["CollapsibleTrigger", "AccordionTrigger"]:
		theme.set_type_variation(style, "Button")
		# accordion rows sit flush with their divider, plain collapsibles get a bit of air
		var pad := Vector2i(t.space_sm, t.space_sm) if style == "CollapsibleTrigger" else Vector2i(t.space_xs, t.space_md)
		var clear := Color(0, 0, 0, 0)
		theme.set_stylebox("normal", style, WoldStyle.flat(clear, t.radius_sm, pad))
		for state in ["hover", "hover_pressed"]:
			theme.set_stylebox(state, style, WoldStyle.flat(t.role("surface_hover"), t.radius_sm, pad))
		theme.set_stylebox("pressed", style, WoldStyle.flat(clear, t.radius_sm, pad))
		theme.set_stylebox("disabled", style, WoldStyle.flat(clear, t.radius_sm, pad))
		theme.set_stylebox("focus", style, WoldStyle.ring(t, t.radius_sm))
		for item in ["font_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color", "font_focus_color"]:
			theme.set_color(item, style, t.role("text"))
		for item in ["icon_normal_color", "icon_pressed_color", "icon_focus_color"]:
			theme.set_color(item, style, t.role("text_muted"))
		for item in ["icon_hover_color", "icon_hover_pressed_color"]:
			theme.set_color(item, style, t.role("text"))
		theme.set_color("font_disabled_color", style, t.role("text_disabled"))
		theme.set_color("icon_disabled_color", style, t.role("text_disabled"))
		theme.set_font_size("font_size", style, t.font_size(0))
		theme.set_constant("h_separation", style, t.space_sm)
		theme.set_constant("icon_max_width", style, t.icon_size_md)
	theme.set_type_variation("CollapsibleBody", "MarginContainer")
	for side in ["left", "right"]:
		theme.set_constant("margin_" + side, "CollapsibleBody", t.space_sm)
	theme.set_constant("margin_top", "CollapsibleBody", t.space_xs)
	theme.set_constant("margin_bottom", "CollapsibleBody", t.space_md)
	theme.set_color("divider", "AccordionTrigger", t.role("border"))
	theme.set_constant("divider_width", "AccordionTrigger", t.border_width)
