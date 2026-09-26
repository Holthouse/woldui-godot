@tool
extends RefCounted
## WoldTooltip panel, title, body, stat rows, hint.

const STYLES: PackedStringArray = [
	"PanelTooltip", "TooltipTitle", "TooltipBody", "TooltipKey", "TooltipValue", "TooltipHint",
]


static func contribute(theme: Theme, t: WoldTokens) -> void:
	theme.set_type_variation("PanelTooltip", "PanelContainer")
	theme.set_stylebox("panel", "PanelTooltip", WoldStyle.raised(t.role("surface_overlay"), t.radius_md, Vector2i(t.space_md, t.space_sm + 2), t, t.role("border")))
	theme.set_type_variation("TooltipTitle", "Label")
	theme.set_font_size("font_size", "TooltipTitle", t.font_size(0))
	theme.set_type_variation("TooltipBody", "RichTextLabel")
	theme.set_color("default_color", "TooltipBody", t.role("text_muted"))
	for item in ["normal_font_size", "bold_font_size", "italics_font_size", "bold_italics_font_size", "mono_font_size"]:
		theme.set_font_size(item, "TooltipBody", t.font_size(-1))
	theme.set_type_variation("TooltipKey", "Label")
	theme.set_font_size("font_size", "TooltipKey", t.font_size(-1))
	theme.set_color("font_color", "TooltipKey", t.role("text_muted"))
	theme.set_type_variation("TooltipValue", "Label")
	theme.set_font_size("font_size", "TooltipValue", t.font_size(-1))
	theme.set_type_variation("TooltipHint", "Label")
	theme.set_font_size("font_size", "TooltipHint", t.font_size(-2))
	theme.set_color("font_color", "TooltipHint", t.role("accent_text"))
