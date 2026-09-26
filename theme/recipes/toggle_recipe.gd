@tool
extends RefCounted
## Check boxes, radios and switches: the engine's own icons swapped for ones
## drawn from the tokens, plus WoldSwitch and WoldSegmented.
## Icons are SVG (DPITexture) so they stay sharp at any UI scale.

const STYLES: PackedStringArray = [
	"Switch", "Checkbox", "ToggleLabel", "ToggleLabelDisabled", "ToggleDescription", "ToggleDescriptionDisabled", "Segmented", "SegmentedButton", "SegmentedThumb",
	"SegmentedSm", "SegmentedButtonSm",
	"Toggle", "ToggleSm", "ToggleLg", "ToggleOutline", "ToggleOutlineSm", "ToggleOutlineLg",
	"ToggleIcon", "ToggleIconSm", "ToggleIconLg", "ToggleOutlineIcon", "ToggleOutlineIconSm", "ToggleOutlineIconLg",
]


static func contribute(theme: Theme, t: WoldTokens) -> void:
	var px := t.icon_size_md
	var on := t.role("accent")
	var mark := t.role("on_accent")
	var off_fill := t.role("field")
	var edge := t.role("field_border")
	var dim := t.role("text_disabled")
	var dim_fill := t.role("control_disabled")
	var r := t.radius_sm

	theme.set_icon("unchecked", "CheckBox", box(px, r, off_fill, edge, t.border_width))
	theme.set_icon("checked", "CheckBox", box(px, r, on, on, t.border_width, check_path(px), mark))
	theme.set_icon("unchecked_disabled", "CheckBox", box(px, r, dim_fill, dim, t.border_width))
	theme.set_icon("checked_disabled", "CheckBox", box(px, r, dim_fill, dim, t.border_width, check_path(px), dim))
	# not an engine item, WoldCheckbox swaps it in for the mixed state
	theme.set_icon("indeterminate", "CheckBox", box(px, r, on, on, t.border_width, dash_path(px), mark))
	theme.set_icon("indeterminate_disabled", "CheckBox", box(px, r, dim_fill, dim, t.border_width, dash_path(px), dim))
	theme.set_icon("radio_unchecked", "CheckBox", dot(px, off_fill, edge, t.border_width, 0.0, mark))
	theme.set_icon("radio_checked", "CheckBox", dot(px, on, on, t.border_width, 0.36, mark))
	theme.set_icon("radio_unchecked_disabled", "CheckBox", dot(px, dim_fill, dim, t.border_width, 0.0, dim))
	theme.set_icon("radio_checked_disabled", "CheckBox", dot(px, dim_fill, dim, t.border_width, 0.36, dim))

	# CheckButton gets the same look as WoldSwitch, just without the slide
	var w := switch_width(t)
	var h := switch_height(t)
	var knob := t.role("text") if t.mode == WoldTokens.Mode.DARK else Color.WHITE
	for mirrored in ["", "_mirrored"]:
		theme.set_icon("unchecked" + mirrored, "CheckButton", switch(w, h, t.role("control_pressed"), edge, knob, mirrored != ""))
		theme.set_icon("checked" + mirrored, "CheckButton", switch(w, h, on, on, t.role("on_accent"), mirrored == ""))
		theme.set_icon("unchecked_disabled" + mirrored, "CheckButton", switch(w, h, dim_fill, dim, dim, mirrored != ""))
		theme.set_icon("checked_disabled" + mirrored, "CheckButton", switch(w, h, dim_fill, dim, dim, mirrored == ""))

	# the toggles' own labels are separate Labels, so they need a disabled look
	theme.set_type_variation("ToggleLabel", "Label")
	theme.set_font_size("font_size", "ToggleLabel", t.font_size(0))
	theme.set_color("font_color", "ToggleLabel", t.role("text"))
	theme.set_type_variation("ToggleLabelDisabled", "ToggleLabel")
	theme.set_color("font_color", "ToggleLabelDisabled", t.role("text_disabled"))
	theme.set_type_variation("ToggleDescription", "Label")
	theme.set_font_size("font_size", "ToggleDescription", t.font_size(-1))
	theme.set_color("font_color", "ToggleDescription", t.role("text_muted"))
	theme.set_type_variation("ToggleDescriptionDisabled", "ToggleDescription")
	theme.set_color("font_color", "ToggleDescriptionDisabled", t.role("text_disabled"))

	_switch_style(theme, t, w, h, knob)
	_labelled(theme, t, "Checkbox", px)
	theme.set_constant("check_size", "Checkbox", px)
	theme.set_color("halo", "Checkbox", t.role("surface_hover"))
	_segmented(theme, t, "", t.control_size(""))
	_segmented(theme, t, "Sm", t.control_size("Sm"))
	for outline in [false, true]:
		for square in [false, true]:
			for size in ["", "Sm", "Lg"]:
				_toggle(theme, t, outline, square, size)


static func switch_width(t: WoldTokens) -> int:
	return int(round(t.icon_size_md * 1.8))


static func switch_height(t: WoldTokens) -> int:
	return t.icon_size_md


# WoldSwitch and WoldCheckbox draw their own indicator; the styleboxes only
# reserve room for it on the left, so the text lands after it and the focus
# ring wraps both
static func _labelled(theme: Theme, t: WoldTokens, style: String, indicator_w: int) -> void:
	theme.set_type_variation(style, "Button")
	var pad := Vector2i(t.space_xs, t.space_xs)
	for state in ["normal", "hover", "pressed", "hover_pressed", "disabled"]:
		var sb := WoldStyle.empty(pad)
		sb.content_margin_left = pad.x + indicator_w + t.space_sm
		theme.set_stylebox(state, style, sb)
	theme.set_stylebox("focus", style, WoldStyle.ring(t, t.radius_sm))
	theme.set_constant("h_separation", style, t.space_sm)
	theme.set_font_size("font_size", style, t.font_size(0))


static func _switch_style(theme: Theme, t: WoldTokens, w: int, h: int, knob: Color) -> void:
	_labelled(theme, t, "Switch", w)
	theme.set_color("track_on", "Switch", t.role("accent"))
	theme.set_color("track_on_hover", "Switch", t.role("accent_hover"))
	theme.set_color("track_off", "Switch", t.role("control_pressed"))
	theme.set_color("track_off_hover", "Switch", t.role("control_hover"))
	theme.set_color("track_border", "Switch", t.role("field_border"))
	theme.set_color("track_disabled", "Switch", t.role("control_disabled"))
	theme.set_color("knob", "Switch", knob)
	theme.set_color("knob_on", "Switch", t.role("on_accent"))
	theme.set_color("knob_disabled", "Switch", t.role("text_disabled"))
	theme.set_constant("track_width", "Switch", w)
	theme.set_constant("track_height", "Switch", h)
	theme.set_constant("border_width", "Switch", t.border_width)


static func _segmented(theme: Theme, t: WoldTokens, size: String, dims: Dictionary) -> void:
	var track: String = "Segmented" + size
	var button: String = "SegmentedButton" + size
	theme.set_type_variation(track, "PanelContainer")
	theme.set_stylebox("panel", track, WoldStyle.flat(t.role("surface_sunken"), dims.radius + 2, Vector2i(2, 2), t.role("border"), t.border_width))
	theme.set_type_variation(button, "Button")
	var pad: Vector2i = dims.padding
	pad.y = maxi(pad.y - 2, 2)
	var clear := Color(0, 0, 0, 0)
	for state in ["normal", "pressed", "hover_pressed", "disabled"]:
		theme.set_stylebox(state, button, WoldStyle.flat(clear, dims.radius, pad))
	theme.set_stylebox("hover", button, WoldStyle.flat(t.role("surface_hover"), dims.radius, pad))
	theme.set_stylebox("focus", button, WoldStyle.ring(t, dims.radius))
	var colors := {
		"font_color": t.role("text_muted"), "font_hover_color": t.role("text"), "font_focus_color": t.role("text"),
		"font_pressed_color": t.role("text"), "font_hover_pressed_color": t.role("text"),
		"font_disabled_color": t.role("text_disabled"),
		"icon_normal_color": t.role("text_muted"), "icon_hover_color": t.role("text"), "icon_focus_color": t.role("text"),
		"icon_pressed_color": t.role("text"), "icon_hover_pressed_color": t.role("text"),
		"icon_disabled_color": t.role("text_disabled"),
	}
	for item in colors:
		theme.set_color(item, button, colors[item])
	theme.set_font_size("font_size", button, dims.font)
	theme.set_constant("h_separation", button, t.space_xs + 2)
	if size == "":
		theme.set_type_variation("SegmentedThumb", "Panel")
		theme.set_stylebox("panel", "SegmentedThumb", WoldStyle.raised(t.role("control"), dims.radius, Vector2i.ZERO, t, t.role("border")))
		(theme.get_stylebox("panel", "SegmentedThumb") as StyleBoxFlat).shadow_size = 4
		(theme.get_stylebox("panel", "SegmentedThumb") as StyleBoxFlat).shadow_offset = Vector2(0, 1)


# WoldToggle: quiet when off, accent tint + accent text when on. The plain
# button pressed look is a press, not a state, so it reads too weak here.
static func _toggle(theme: Theme, t: WoldTokens, outline: bool, square: bool, size: String) -> void:
	var style := "Toggle" + ("Outline" if outline else "") + ("Icon" if square else "") + size
	theme.set_type_variation(style, "Button" if size == "" else style.trim_suffix(size))
	var dims := t.control_size(size)
	var pad: Vector2i = dims.padding
	if square:
		pad = Vector2i(pad.y, pad.y)
	var radius: int = dims.radius
	var clear := Color(0, 0, 0, 0)
	var edge := t.role("border_strong") if outline else clear
	var on_edge := t.role("accent") if outline else clear
	var bw := t.border_width
	theme.set_stylebox("normal", style, WoldStyle.flat(clear, radius, pad, edge, bw))
	theme.set_stylebox("hover", style, WoldStyle.flat(t.role("surface_hover"), radius, pad, edge, bw))
	theme.set_stylebox("pressed", style, WoldStyle.flat(t.role("accent_soft"), radius, pad, on_edge, bw))
	var hot := t.role("accent_soft")
	hot.a = minf(hot.a * 1.6, 1.0)
	theme.set_stylebox("hover_pressed", style, WoldStyle.flat(hot, radius, pad, on_edge, bw))
	theme.set_stylebox("disabled", style, WoldStyle.flat(clear, radius, pad, t.role("control_disabled") if outline else clear, bw))
	theme.set_stylebox("focus", style, WoldStyle.ring(t, radius))
	var off := t.role("text_muted")
	var on := t.role("accent_text")
	var colors := {
		"font_color": off, "font_hover_color": t.role("text"), "font_focus_color": t.role("text"),
		"font_pressed_color": on, "font_hover_pressed_color": on, "font_disabled_color": t.role("text_disabled"),
		"icon_normal_color": off, "icon_hover_color": t.role("text"), "icon_focus_color": t.role("text"),
		"icon_pressed_color": on, "icon_hover_pressed_color": on, "icon_disabled_color": t.role("text_disabled"),
	}
	for item in colors:
		theme.set_color(item, style, colors[item])
	theme.set_font_size("font_size", style, dims.font)
	theme.set_constant("h_separation", style, t.space_sm)
	theme.set_constant("icon_max_width", style, dims.icon)


# ---------------------------------------------------------------- svg

static func _hex(c: Color) -> String:
	return "#" + c.to_html(false)


static func _paint(attr: String, c: Color) -> String:
	return '%s="%s" %s-opacity="%.3f"' % [attr, _hex(c), attr, c.a]


static func _texture(w: int, h: int, body: String) -> DPITexture:
	var svg := '<svg xmlns="http://www.w3.org/2000/svg" width="%d" height="%d" viewBox="0 0 %d %d">%s</svg>' % [w, h, w, h, body]
	return DPITexture.create_from_string(svg)


## Rounded square, optionally with a stroked mark path inside.
static func box(px: int, radius: int, fill: Color, border: Color, border_w: int, mark_path := "", mark_color := Color.WHITE) -> DPITexture:
	var inset := border_w / 2.0
	var body := '<rect x="%.1f" y="%.1f" width="%.1f" height="%.1f" rx="%d" %s %s stroke-width="%d"/>' % [
		inset, inset, px - border_w, px - border_w, radius, _paint("fill", fill), _paint("stroke", border), border_w]
	if mark_path != "":
		body += '<path d="%s" fill="none" %s stroke-width="%.1f" stroke-linecap="round" stroke-linejoin="round"/>' % [mark_path, _paint("stroke", mark_color), maxf(px / 9.0, 1.5)]
	return _texture(px, px, body)


## Circle, with a centre dot of radius `dot_ratio` * px (0 = none).
static func dot(px: int, fill: Color, border: Color, border_w: int, dot_ratio: float, dot_color: Color) -> DPITexture:
	var c := px / 2.0
	var body := '<circle cx="%.1f" cy="%.1f" r="%.1f" %s %s stroke-width="%d"/>' % [c, c, c - border_w / 2.0, _paint("fill", fill), _paint("stroke", border), border_w]
	if dot_ratio > 0.0:
		body += '<circle cx="%.1f" cy="%.1f" r="%.1f" %s/>' % [c, c, px * dot_ratio / 2.0, _paint("fill", dot_color)]
	return _texture(px, px, body)


## Pill track with the knob at one end.
static func switch(w: int, h: int, track: Color, border: Color, knob: Color, knob_right: bool) -> DPITexture:
	var r := h / 2.0
	var kr := r - maxf(h / 8.0, 2.0)
	var kx := w - r if knob_right else r
	var body := '<rect x="0.5" y="0.5" width="%d" height="%d" rx="%.1f" %s %s stroke-width="1"/>' % [w - 1, h - 1, r - 0.5, _paint("fill", track), _paint("stroke", border)]
	body += '<circle cx="%.1f" cy="%.1f" r="%.1f" %s/>' % [kx, r, kr, _paint("fill", knob)]
	return _texture(w, h, body)


static func check_path(px: int) -> String:
	var s := px / 20.0
	return "M%.1f %.1fL%.1f %.1fL%.1f %.1f" % [5.5 * s, 10.5 * s, 8.5 * s, 13.5 * s, 14.5 * s, 7 * s]


static func dash_path(px: int) -> String:
	var s := px / 20.0
	return "M%.1f %.1fH%.1f" % [6 * s, 10 * s, 14 * s]


## Just a stroked path, no box. Menu checks and arrows.
static func mark(px: int, path: String, color: Color) -> DPITexture:
	return _texture(px, px, '<path d="%s" fill="none" %s stroke-width="%.1f" stroke-linecap="round" stroke-linejoin="round"/>' % [path, _paint("stroke", color), maxf(px / 10.0, 1.5)])


## Empty square, for keeping menu items lined up.
static func blank(px: int) -> DPITexture:
	return _texture(px, px, "")


## `right` false = pointing down.
static func chevron_path(px: int, right: bool) -> String:
	var s := px / 20.0
	if right:
		return "M%.1f %.1fL%.1f %.1fL%.1f %.1f" % [8 * s, 5 * s, 13 * s, 10 * s, 8 * s, 15 * s]
	return "M%.1f %.1fL%.1f %.1fL%.1f %.1f" % [5 * s, 8 * s, 10 * s, 13 * s, 15 * s, 8 * s]
