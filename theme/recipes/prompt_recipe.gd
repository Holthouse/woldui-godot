@tool
extends RefCounted
## Button prompts: PromptGlyph (drawn by WoldPromptGlyph) and its label.

const STYLES: PackedStringArray = ["PromptLabel"]


static func contribute(theme: Theme, t: WoldTokens) -> void:
	theme.set_color("fill_color", "PromptGlyph", t.role("control"))
	theme.set_color("border_color", "PromptGlyph", t.role("border_strong"))
	theme.set_color("font_color", "PromptGlyph", t.role("text"))
	theme.set_font_size("font_size", "PromptGlyph", t.font_size(-2))
	theme.set_constant("height", "PromptGlyph", int(round(t.font_size(0) * 1.35)))
	theme.set_constant("radius", "PromptGlyph", t.radius_sm)
	theme.set_type_variation("PromptLabel", "Label")
	theme.set_font_size("font_size", "PromptLabel", t.font_size(-1))
	theme.set_color("font_color", "PromptLabel", t.role("text_muted"))
