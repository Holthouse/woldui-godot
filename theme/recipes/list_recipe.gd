@tool
extends RefCounted
## WoldListRow. Quiet until hovered; selected gets an accent tint + edge bar.

const STYLES: PackedStringArray = ["ListRow", "ListRowTitle", "ListRowSubtitle", "ListRowMeta"]


static func contribute(theme: Theme, t: WoldTokens) -> void:
	var pad := Vector2i(t.space_md, t.space_sm)
	theme.set_type_variation("ListRow", "Button")
	theme.set_stylebox("normal", "ListRow", WoldStyle.flat(Color(0, 0, 0, 0), t.radius_sm, pad))
	theme.set_stylebox("hover", "ListRow", WoldStyle.flat(t.role("surface_hover"), t.radius_sm, pad))
	theme.set_stylebox("disabled", "ListRow", WoldStyle.flat(Color(0, 0, 0, 0), t.radius_sm, pad))
	for state in ["pressed", "hover_pressed"]:
		var sel := WoldStyle.flat(t.role("accent_soft"), t.radius_sm, pad)
		sel.border_color = t.role("accent")
		sel.border_width_left = t.focus_width + 1
		sel.content_margin_left = pad.x
		theme.set_stylebox(state, "ListRow", sel)
	theme.set_stylebox("focus", "ListRow", WoldStyle.ring(t, t.radius_sm))

	theme.set_type_variation("ListRowTitle", "Label")
	theme.set_font_size("font_size", "ListRowTitle", t.font_size(0))
	theme.set_type_variation("ListRowSubtitle", "Label")
	theme.set_font_size("font_size", "ListRowSubtitle", t.font_size(-1))
	theme.set_color("font_color", "ListRowSubtitle", t.role("text_muted"))
	theme.set_type_variation("ListRowMeta", "Label")
	theme.set_font_size("font_size", "ListRowMeta", t.font_size(-1))
	theme.set_color("font_color", "ListRowMeta", t.role("text_muted"))
