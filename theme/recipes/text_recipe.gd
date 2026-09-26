@tool
extends RefCounted
## Type scale + text tones as Label styles. Pick by role (Heading), not by
## pixel size.

const STYLES: PackedStringArray = [
	"Display", "Title", "Heading", "Subheading", "Body", "Caption", "Overline",
	"Muted", "TextAccent", "TextSuccess", "TextWarning", "TextDanger", "TextOutlined",
]

# name -> [scale step, display font?]
const SCALE := {
	"Display": [4, true],
	"Title": [3, true],
	"Heading": [2, false],
	"Subheading": [1, false],
	"Body": [0, false],
	"Caption": [-1, false],
	"Overline": [-1, false],
}


static func contribute(theme: Theme, t: WoldTokens) -> void:
	for style in SCALE:
		theme.set_type_variation(style, "Label")
		theme.set_font_size("font_size", style, t.font_size(SCALE[style][0]))
		if SCALE[style][1] and t.display():
			theme.set_font("font", style, t.display())
	# Display is the one that ends up over the world most
	theme.set_constant("outline_size", "Display", t.text_outline_size)
	theme.set_color("font_color", "Caption", t.role("text_muted"))
	theme.set_color("font_color", "Overline", t.role("accent_text"))

	theme.set_type_variation("Muted", "Label")
	theme.set_color("font_color", "Muted", t.role("text_muted"))

	for tone in ["accent", "success", "warning", "danger"]:
		var style: String = "Text" + tone.capitalize()
		theme.set_type_variation(style, "Label")
		theme.set_color("font_color", style, t.role(tone + "_text"))

	theme.set_type_variation("TextOutlined", "Label")
	theme.set_constant("outline_size", "TextOutlined", t.text_outline_size)
