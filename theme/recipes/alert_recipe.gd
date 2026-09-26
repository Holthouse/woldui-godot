@tool
extends RefCounted
## WoldAlert: a banner that sits in the layout (not a toast). Soft tone fill,
## tone edge, the icon in the tone's text colour.

const TONES: PackedStringArray = ["Neutral", "Accent", "Success", "Warning", "Danger"]

const STYLES: PackedStringArray = [
	"AlertNeutral", "AlertAccent", "AlertSuccess", "AlertWarning", "AlertDanger", "AlertTitle", "AlertBody",
]


static func contribute(theme: Theme, t: WoldTokens) -> void:
	var pad := Vector2i(t.space_md, t.space_md)
	for tone in TONES:
		var style: String = "Alert" + tone
		theme.set_type_variation(style, "PanelContainer")
		var key := tone.to_lower()
		var fill := t.role("surface_sunken") if tone == "Neutral" else t.role(key + "_soft")
		var edge := t.role("border_strong") if tone == "Neutral" else t.role(key)
		theme.set_stylebox("panel", style, WoldStyle.flat(fill, t.radius_md, pad, edge, t.border_width))
		theme.set_color("icon", style, t.role("text_muted") if tone == "Neutral" else t.role(key + "_text"))
	theme.set_type_variation("AlertTitle", "Label")
	theme.set_font_size("font_size", "AlertTitle", t.font_size(0))
	theme.set_color("font_color", "AlertTitle", t.role("text"))
	theme.set_type_variation("AlertBody", "Label")
	theme.set_font_size("font_size", "AlertBody", t.font_size(-1))
	theme.set_color("font_color", "AlertBody", t.role("text_muted"))
