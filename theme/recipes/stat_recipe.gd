@tool
extends RefCounted
## WoldStat: value (3 sizes), caption, up/down delta.

const STYLES: PackedStringArray = [
	"StatValueSm", "StatValue", "StatValueLg", "StatCaption", "StatDeltaUp", "StatDeltaDown",
]


static func contribute(theme: Theme, t: WoldTokens) -> void:
	# tnum so counting numbers don't wobble. Only for a real font file, otherwise
	# the fallback font gets embedded whole in the theme
	var digits: Font = null
	if t.body_font and t.body_font.resource_path != "":
		var v := FontVariation.new()
		v.base_font = t.body_font
		v.opentype_features = {TextServerManager.get_primary_interface().name_to_tag("tnum"): 1}
		digits = v
	var sizes := {"StatValueSm": 0, "StatValue": 1, "StatValueLg": 3}
	for style in sizes:
		theme.set_type_variation(style, "Label")
		theme.set_font_size("font_size", style, t.font_size(sizes[style]))
		if digits:
			theme.set_font("font", style, digits)
	theme.set_type_variation("StatCaption", "Label")
	theme.set_font_size("font_size", "StatCaption", t.font_size(-1))
	theme.set_color("font_color", "StatCaption", t.role("text_muted"))
	for pair in [["StatDeltaUp", "success_text"], ["StatDeltaDown", "danger_text"]]:
		theme.set_type_variation(pair[0], "Label")
		theme.set_font_size("font_size", pair[0], t.font_size(-1))
		theme.set_color("font_color", pair[0], t.role(pair[1]))
