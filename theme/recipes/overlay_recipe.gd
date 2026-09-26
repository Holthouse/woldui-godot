@tool
extends RefCounted
## WoldPopover (a floating panel next to something) and WoldSheet (a panel
## that slides in from an edge).

const STYLES: PackedStringArray = [
	"Popover", "PopoverTitle", "PopoverDescription",
	"SheetLeft", "SheetRight", "SheetTop", "SheetBottom",
]


static func contribute(theme: Theme, t: WoldTokens) -> void:
	theme.set_type_variation("Popover", "PanelContainer")
	theme.set_stylebox("panel", "Popover", WoldStyle.raised(t.role("surface_overlay"), t.radius_md, Vector2i(t.space_md, t.space_md), t, t.role("border")))
	theme.set_constant("gap", "Popover", t.space_xs)
	theme.set_type_variation("PopoverTitle", "Label")
	theme.set_font_size("font_size", "PopoverTitle", t.font_size(0))
	theme.set_color("font_color", "PopoverTitle", t.role("text"))
	theme.set_type_variation("PopoverDescription", "Label")
	theme.set_font_size("font_size", "PopoverDescription", t.font_size(-1))
	theme.set_color("font_color", "PopoverDescription", t.role("text_muted"))

	# the edge a sheet comes in from stays square, the others round off
	var pad := Vector2i(t.space_xl, t.space_xl)
	for side in ["Left", "Right", "Top", "Bottom"]:
		var style: String = "Sheet" + side
		theme.set_type_variation(style, "PanelContainer")
		var sb := WoldStyle.raised(t.role("surface_overlay"), t.radius_lg, pad, t, t.role("border"))
		match side:
			"Left":
				sb.corner_radius_top_left = 0
				sb.corner_radius_bottom_left = 0
			"Right":
				sb.corner_radius_top_right = 0
				sb.corner_radius_bottom_right = 0
			"Top":
				sb.corner_radius_top_left = 0
				sb.corner_radius_top_right = 0
			"Bottom":
				sb.corner_radius_bottom_left = 0
				sb.corner_radius_bottom_right = 0
		theme.set_stylebox("panel", style, sb)
