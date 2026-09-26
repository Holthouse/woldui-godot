@tool
extends RefCounted
## WoldCard. The card itself has no padding; its sections pad themselves, so
## a header with nothing under it doesn't leave a gap.

const STYLES: PackedStringArray = [
	"Card", "CardSm", "CardSection", "CardSectionSm", "CardSectionNext", "CardSectionNextSm",
	"CardTitle", "CardTitleSm", "CardDescription",
]


static func contribute(theme: Theme, t: WoldTokens) -> void:
	for size in ["", "Sm"]:
		var card: String = "Card" + size
		var pad: int = t.space_lg if size == "" else t.space_md
		var r: int = t.radius_lg if size == "" else t.radius_md
		theme.set_type_variation(card, "PanelContainer" if size == "" else "Card")
		theme.set_stylebox("panel", card, WoldStyle.flat(t.role("surface_raised"), r, Vector2i.ZERO, t.role("border"), t.border_width))
		# drawn on top of the panel by a selectable card
		theme.set_stylebox("hover", card, WoldStyle.flat(t.role("surface_hover"), r))
		var picked := WoldStyle.flat(t.role("accent_soft"), r)
		picked.border_color = t.role("accent")
		picked.set_border_width_all(t.focus_width)
		theme.set_stylebox("selected", card, picked)
		theme.set_stylebox("focus", card, WoldStyle.ring(t, r))

		var section: String = "CardSection" + size
		theme.set_type_variation(section, "MarginContainer")
		for side in ["left", "top", "right", "bottom"]:
			theme.set_constant("margin_" + side, section, pad)
		# every section after the first: no top margin, the one above has it
		var next: String = "CardSectionNext" + size
		theme.set_type_variation(next, section)
		theme.set_constant("margin_top", next, 0)

		var title: String = "CardTitle" + size
		theme.set_type_variation(title, "Label")
		theme.set_font_size("font_size", title, t.font_size(1 if size == "" else 0))
		theme.set_color("font_color", title, t.role("text"))
	theme.set_type_variation("CardDescription", "Label")
	theme.set_font_size("font_size", "CardDescription", t.font_size(-1))
	theme.set_color("font_color", "CardDescription", t.role("text_muted"))
