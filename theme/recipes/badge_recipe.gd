@tool
extends RefCounted
## Badges. Badge{Tone}{Fill}{Size} is the pill (PanelContainer),
## BadgeLabel{Tone}{Fill}{Size} its Label, BadgeDot{Tone} just a dot.
## Size is "Sm" or nothing.

const TONES: PackedStringArray = ["Neutral", "Accent", "Success", "Warning", "Danger"]
const FILLS: PackedStringArray = ["Soft", "Solid", "Outline", "Ghost"]
const SIZES: PackedStringArray = ["Sm", ""]

const STYLES: PackedStringArray = [
	"BadgeNeutralSoft", "BadgeAccentSoft", "BadgeSuccessSoft", "BadgeWarningSoft", "BadgeDangerSoft",
	"BadgeNeutralSolid", "BadgeAccentSolid", "BadgeSuccessSolid", "BadgeWarningSolid", "BadgeDangerSolid",
	"BadgeNeutralOutline", "BadgeAccentOutline", "BadgeSuccessOutline", "BadgeWarningOutline", "BadgeDangerOutline",
	"BadgeAccentGhost", "BadgeLabelAccentGhost",
	"BadgeLabelAccentSoft", "BadgeLabelDangerSolid", "BadgeAccentSoftSm", "BadgeLabelAccentSoftSm",
	"BadgeDotNeutral", "BadgeDotAccent", "BadgeDotSuccess", "BadgeDotWarning", "BadgeDotDanger",
]


static func colors(t: WoldTokens, tone: String, fill: String) -> Dictionary:
	var clear := Color(0, 0, 0, 0)
	if tone == "Neutral":
		match fill:
			"Solid": return {bg = t.role("text_muted"), fg = t.role("surface_base"), border = clear}
			"Outline": return {bg = clear, fg = t.role("text_muted"), border = t.role("border_strong")}
			"Ghost": return {bg = clear, fg = t.role("text_muted"), border = clear}
		return {bg = t.role("control"), fg = t.role("text"), border = clear}
	var r := tone.to_lower()
	match fill:
		"Solid": return {bg = t.role(r), fg = t.role("on_" + r), border = clear}
		"Outline": return {bg = clear, fg = t.role(r + "_text"), border = t.role(r + "_text")}
		"Ghost": return {bg = clear, fg = t.role(r + "_text"), border = clear}
	# soft tint eats contrast, push the text one step further than _text
	var strong := t.tone(r, 200 if t.mode == WoldTokens.Mode.DARK else 800)
	return {bg = t.role(r + "_soft"), fg = strong, border = clear}


static func contribute(theme: Theme, t: WoldTokens) -> void:
	for tone in TONES:
		for fill in FILLS:
			var c := colors(t, tone, fill)
			for size in SIZES:
				var pad := Vector2i(t.space_xs + 2, 1) if size == "Sm" else Vector2i(t.space_sm, 2)
				var panel: String = "Badge" + tone + fill + size
				theme.set_type_variation(panel, "PanelContainer")
				theme.set_stylebox("panel", panel, WoldStyle.flat(c.bg, 999, pad, c.border, t.border_width))
				var text: String = "BadgeLabel" + tone + fill + size
				theme.set_type_variation(text, "Label")
				theme.set_color("font_color", text, c.fg)
				theme.set_font_size("font_size", text, t.font_size(-2 if size == "Sm" else -1))
		var dot: String = "BadgeDot" + tone
		theme.set_type_variation(dot, "PanelContainer")
		theme.set_stylebox("panel", dot, WoldStyle.flat(colors(t, tone, "Solid").bg, 999))
