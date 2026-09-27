@tool
extends RefCounted
## WoldListRow. Quiet until hovered; selected gets an accent tint + edge bar.
## ListRow{Look}{Size}: no look = plain, Outline has an edge, Muted a soft
## fill. Sm is the tighter row.

const LOOKS: PackedStringArray = ["", "Outline", "Muted"]
const STYLES: PackedStringArray = [
	"ListRow", "ListRowSm", "ListRowOutline", "ListRowOutlineSm", "ListRowMuted", "ListRowMutedSm",
	"ListRowTitle", "ListRowTitleSm", "ListRowSubtitle", "ListRowMeta",
]


static func contribute(theme: Theme, t: WoldTokens) -> void:
	for look in LOOKS:
		for size in ["", "Sm"]:
			var style: String = "ListRow" + look + size
			theme.set_type_variation(style, "Button")
			_row(theme, style, look, size, t)

	theme.set_type_variation("ListRowTitle", "Label")
	theme.set_font_size("font_size", "ListRowTitle", t.font_size(0))
	theme.set_type_variation("ListRowTitleSm", "ListRowTitle")
	theme.set_font_size("font_size", "ListRowTitleSm", t.font_size(-1))
	theme.set_type_variation("ListRowSubtitle", "Label")
	theme.set_font_size("font_size", "ListRowSubtitle", t.font_size(-1))
	theme.set_color("font_color", "ListRowSubtitle", t.role("text_muted"))
	theme.set_type_variation("ListRowMeta", "Label")
	theme.set_font_size("font_size", "ListRowMeta", t.font_size(-1))
	theme.set_color("font_color", "ListRowMeta", t.role("text_muted"))


static func _row(theme: Theme, style: String, look: String, size: String, t: WoldTokens) -> void:
	var pad := Vector2i(t.space_md, t.space_sm) if size == "" else Vector2i(t.space_sm, t.space_xs)
	var clear := Color(0, 0, 0, 0)
	var rest := clear
	var hover := t.role("surface_hover")
	var edge := clear
	var edge_w := 0
	match look:
		"Outline":
			edge = t.role("border")
			edge_w = t.border_width
		"Muted":
			rest = t.role("surface_hover")
			hover = Color(hover, minf(hover.a * 2.0, 1.0))
	theme.set_stylebox("normal", style, WoldStyle.flat(rest, t.radius_sm, pad, edge, edge_w))
	theme.set_stylebox("hover", style, WoldStyle.flat(hover, t.radius_sm, pad, edge, edge_w))
	theme.set_stylebox("disabled", style, WoldStyle.flat(rest, t.radius_sm, pad, edge, edge_w))
	for state in ["pressed", "hover_pressed"]:
		var sel := WoldStyle.flat(t.role("accent_soft"), t.radius_sm, pad, t.role("accent") if edge_w > 0 else clear, edge_w)
		sel.border_color = t.role("accent")
		sel.border_width_left = t.focus_width + 1
		sel.content_margin_left = pad.x
		theme.set_stylebox(state, style, sel)
	theme.set_stylebox("focus", style, WoldStyle.ring(t, t.radius_sm))
