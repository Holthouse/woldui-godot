@tool
extends RefCounted
## Progress bars, sliders, scrollbars. Meter tones are for game values
## (health, mana...). Give them a label or icon too, not just colour.

const STYLES: PackedStringArray = ["MeterAccent", "MeterSuccess", "MeterWarning", "MeterDanger", "MeterThin"]


static func contribute(theme: Theme, t: WoldTokens) -> void:
	var track := WoldStyle.flat(t.role("field"), t.radius_sm, Vector2i.ZERO, t.role("field_border"), t.border_width)
	track.content_margin_top = 4
	track.content_margin_bottom = 4
	theme.set_stylebox("background", "ProgressBar", track)
	theme.set_stylebox("fill", "ProgressBar", WoldStyle.flat(t.role("accent"), t.radius_sm))
	theme.set_color("font_color", "ProgressBar", t.role("text"))
	theme.set_color("font_outline_color", "ProgressBar", t.role("text_outline"))
	theme.set_constant("outline_size", "ProgressBar", 3)
	theme.set_font_size("font_size", "ProgressBar", t.font_size(-1))
	for tone in ["accent", "success", "warning", "danger"]:
		var style: String = "Meter" + tone.capitalize()
		theme.set_type_variation(style, "ProgressBar")
		theme.set_stylebox("fill", style, WoldStyle.flat(t.role(tone), t.radius_sm))
	theme.set_type_variation("MeterThin", "ProgressBar")
	var thin := WoldStyle.flat(t.role("field_border"), 2)
	thin.content_margin_top = 2
	thin.content_margin_bottom = 2
	theme.set_stylebox("background", "MeterThin", thin)
	theme.set_stylebox("fill", "MeterThin", WoldStyle.flat(t.role("accent"), 2))

	for type in ["HSlider", "VSlider"]:
		var rail := WoldStyle.flat(t.role("field"), 99, Vector2i(2, 2), t.role("field_border"), t.border_width)
		theme.set_stylebox("slider", type, rail)
		theme.set_stylebox("grabber_area", type, WoldStyle.flat(t.role("accent"), 99, Vector2i(2, 2)))
		theme.set_stylebox("grabber_area_highlight", type, WoldStyle.flat(t.role("accent_hover"), 99, Vector2i(2, 2)))

	for type in ["HScrollBar", "VScrollBar"]:
		theme.set_stylebox("scroll", type, WoldStyle.empty(Vector2i(3, 3)))
		theme.set_stylebox("scroll_focus", type, WoldStyle.empty(Vector2i(3, 3)))
		theme.set_stylebox("grabber", type, WoldStyle.flat(t.role("border_strong"), 99, Vector2i(3, 3)))
		theme.set_stylebox("grabber_highlight", type, WoldStyle.flat(t.role("text_muted"), 99, Vector2i(3, 3)))
		theme.set_stylebox("grabber_pressed", type, WoldStyle.flat(t.role("text"), 99, Vector2i(3, 3)))
		# no arrow buttons, zero-size placeholder icons hide them
		for icon in ["increment", "increment_highlight", "increment_pressed", "decrement", "decrement_highlight", "decrement_pressed"]:
			theme.set_icon(icon, type, PlaceholderTexture2D.new())
			(theme.get_icon(icon, type) as PlaceholderTexture2D).size = Vector2.ZERO
