@tool
extends RefCounted
## Plain engine types (Label, Panel, tooltip...) so unstyled nodes already fit.
## No named styles here.

const STYLES: PackedStringArray = []


static func contribute(theme: Theme, t: WoldTokens) -> void:
	theme.set_color("font_color", "Label", t.role("text"))
	theme.set_color("font_outline_color", "Label", t.role("text_outline"))
	theme.set_color("font_shadow_color", "Label", Color(0, 0, 0, 0))
	theme.set_constant("line_spacing", "Label", 2)

	theme.set_color("default_color", "RichTextLabel", t.role("text"))
	theme.set_color("font_outline_color", "RichTextLabel", t.role("text_outline"))
	theme.set_color("selection_color", "RichTextLabel", t.role("accent_soft"))
	theme.set_color("font_selected_color", "RichTextLabel", t.role("text"))
	for item in ["normal_font_size", "bold_font_size", "italics_font_size", "bold_italics_font_size", "mono_font_size"]:
		theme.set_font_size(item, "RichTextLabel", t.font_size(0))
	if t.mono_font:
		theme.set_font("mono_font", "RichTextLabel", t.mono_font)
	# fake bold for [b]. Leaving base_font empty = default font, which keeps it
	# from getting embedded in the .tres
	var bold := FontVariation.new()
	if t.body_font:
		bold.base_font = t.body_font
	bold.variation_embolden = 0.8
	theme.set_font("bold_font", "RichTextLabel", bold)
	theme.set_stylebox("normal", "RichTextLabel", WoldStyle.empty())
	theme.set_stylebox("focus", "RichTextLabel", WoldStyle.empty())

	var raised := WoldStyle.flat(t.role("surface_raised"), t.radius_md, Vector2i(t.space_lg, t.space_lg), t.role("border"), t.border_width)
	theme.set_stylebox("panel", "PanelContainer", raised)
	theme.set_stylebox("panel", "Panel", raised)

	theme.set_stylebox("panel", "TooltipPanel", WoldStyle.raised(t.role("surface_overlay"), t.radius_sm, Vector2i(t.space_sm + 2, t.space_xs + 2), t, t.role("border")))
	theme.set_color("font_color", "TooltipLabel", t.role("text"))
	theme.set_color("font_outline_color", "TooltipLabel", t.role("text_outline"))
	theme.set_font_size("font_size", "TooltipLabel", t.font_size(-1))

	theme.set_stylebox("separator", "HSeparator", WoldStyle.line(t.role("border"), t.border_width))
	theme.set_stylebox("separator", "VSeparator", WoldStyle.line(t.role("border"), t.border_width, true))
	theme.set_constant("separation", "HSeparator", t.space_md)
	theme.set_constant("separation", "VSeparator", t.space_md)

	theme.set_stylebox("panel", "ScrollContainer", WoldStyle.empty())
