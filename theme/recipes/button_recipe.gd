@tool
extends RefCounted
## Button{Shape}{Size}, e.g. ButtonPrimarySm. No suffix = medium.
## A plain Button looks like ButtonSecondary.
## Plus the look x tone grid WoldButton.look uses: Button{Look}{Tone}{Size},
## e.g. ButtonFlatSuccessSm.

const SHAPES: PackedStringArray = ["Primary", "Secondary", "Outline", "Ghost", "Danger", "Icon"]
const SIZES: PackedStringArray = ["Sm", "", "Lg"]
const LOOKS: PackedStringArray = ["Solid", "Flat", "Bordered", "Light", "Faded", "Shadow", "Link"]
const TONES: PackedStringArray = ["Neutral", "Accent", "Success", "Warning", "Danger"]
const GRID_SIZES: PackedStringArray = ["Xs", "Sm", "", "Lg"]

# kept by hand for the tests and the gallery, add new ones here too
const STYLES: PackedStringArray = [
	"ButtonPrimary", "ButtonPrimarySm", "ButtonPrimaryLg",
	"ButtonSecondary", "ButtonSecondarySm", "ButtonSecondaryLg",
	"ButtonOutline", "ButtonOutlineSm", "ButtonOutlineLg",
	"ButtonGhost", "ButtonGhostSm", "ButtonGhostLg",
	"ButtonDanger", "ButtonDangerSm", "ButtonDangerLg",
	"ButtonIcon", "ButtonIconSm", "ButtonIconLg",
	"ButtonSolidAccent", "ButtonFlatSuccessSm", "ButtonBorderedDangerLg", "ButtonLinkNeutralXs",
	"ButtonStrip",
]


static func contribute(theme: Theme, t: WoldTokens) -> void:
	_paint(theme, "Button", "Secondary", "", t)
	for shape in SHAPES:
		for size in SIZES:
			var style: String = "Button" + shape + size
			# Sm/Lg inherit from the medium one, medium from Button
			theme.set_type_variation(style, "Button" + shape if size != "" else "Button")
			_paint(theme, style, shape, size, t)
	for look in LOOKS:
		for tone in TONES:
			for size in GRID_SIZES:
				var style: String = "Button" + look + tone + size
				theme.set_type_variation(style, "Button" + look + tone if size != "" else "Button")
				_paint_grid(theme, style, look, tone, size, t)
	# WoldButtonStrip: neighbours overlap by one border so seams are a single line
	theme.set_type_variation("ButtonStrip", "BoxContainer")
	theme.set_constant("separation", "ButtonStrip", -t.border_width)


static func _palette(shape: String, t: WoldTokens) -> Dictionary:
	var clear := Color(0, 0, 0, 0)
	match shape:
		"Primary":
			return {fill = [t.role("accent"), t.role("accent_hover"), t.role("accent_pressed")],
				border = clear, text = t.role("on_accent"), text_hover = t.role("on_accent")}
		"Danger":
			return {fill = [t.role("danger"), t.role("danger_hover"), t.role("danger_pressed")],
				border = clear, text = t.role("on_danger"), text_hover = t.role("on_danger")}
		"Outline":
			return {fill = [clear, t.role("surface_hover"), t.role("surface_pressed")],
				border = t.role("border_strong"), text = t.role("text"), text_hover = t.role("text")}
		"Ghost", "Icon":
			return {fill = [clear, t.role("surface_hover"), t.role("surface_pressed")],
				border = clear, text = t.role("text_muted"), text_hover = t.role("text")}
		_:
			return {fill = [t.role("control"), t.role("control_hover"), t.role("control_pressed")],
				border = t.role("border"), text = t.role("text"), text_hover = t.role("text")}


static func _paint(theme: Theme, style: String, shape: String, size: String, t: WoldTokens) -> void:
	var dims := t.control_size(size)
	var p: Dictionary = _palette(shape, t)
	var padding: Vector2i = dims.padding
	if shape == "Icon":
		padding = Vector2i(padding.y, padding.y)
	var radius: int = dims.radius
	var states := {"normal": p.fill[0], "hover": p.fill[1], "pressed": p.fill[2]}
	for state in states:
		theme.set_stylebox(state, style, WoldStyle.flat(states[state], radius, padding, p.border, t.border_width))
	var has_fill: bool = p.fill[0].a > 0.0
	theme.set_stylebox("disabled", style, WoldStyle.flat(t.role("control_disabled") if has_fill else Color(0, 0, 0, 0), radius, padding))
	theme.set_stylebox("focus", style, WoldStyle.ring(t, radius))

	var pressed_text: Color = p.text_hover
	var colors := {
		"font_color": p.text, "font_hover_color": p.text_hover, "font_focus_color": p.text_hover,
		"font_pressed_color": pressed_text, "font_hover_pressed_color": pressed_text,
		"font_disabled_color": t.role("text_disabled"),
		"icon_normal_color": p.text, "icon_hover_color": p.text_hover, "icon_focus_color": p.text_hover,
		"icon_pressed_color": pressed_text, "icon_hover_pressed_color": pressed_text,
		"icon_disabled_color": t.role("text_disabled"),
		"font_outline_color": t.role("text_outline"),
	}
	if t.icon_tint == WoldTokens.IconTint.ORIGINAL:
		for item in ["icon_normal_color", "icon_hover_color", "icon_focus_color", "icon_pressed_color", "icon_hover_pressed_color"]:
			colors[item] = Color.WHITE
		colors["icon_disabled_color"] = Color(1, 1, 1, 0.4)
	for item in colors:
		theme.set_color(item, style, colors[item])
	theme.set_font_size("font_size", style, dims.font)
	theme.set_constant("h_separation", style, t.space_sm)
	theme.set_constant("icon_max_width", style, dims.icon)
	theme.set_constant("outline_size", style, 0)


## Every grid style name. STYLES only carries a sample.
static func all_styles() -> PackedStringArray:
	var out := PackedStringArray()
	for look in LOOKS:
		for tone in TONES:
			for size in GRID_SIZES:
				out.append("Button" + look + tone + size)
	return out


# Colours for one look in one tone. Neutral borrows the control / surface
# roles, the tones their own ramp. fill = [normal, hover, pressed].
static func grid_palette(look: String, tone: String, t: WoldTokens) -> Dictionary:
	var clear := Color(0, 0, 0, 0)
	var neutral := tone == "Neutral"
	var r := tone.to_lower()
	var solid: Array = _solid_neutral(t) if neutral else _solid(r, t)
	var soft: Color = t.role("surface_hover") if neutral else t.role(r + "_soft")
	var tints: Array = [soft, _denser(soft, 1.6), _denser(soft, 2.2)]
	var on: Color = t.role("text") if neutral else t.role("on_" + r)
	var ink: Color = t.role("text") if neutral else t.role(r + "_text")
	# on a tint the plain _text colour gets thin, go a step further out
	var deep: Color = t.role("text") if neutral else t.tone(r, 200 if t.mode == WoldTokens.Mode.DARK else 800)
	var edge: Color = t.role("text_muted") if neutral else ink
	var p := {fill = solid, border = clear, border_width = 0, text = on, text_hover = on, shadow = clear}
	match look:
		"Flat":
			p.fill = tints
			p.text = deep
			p.text_hover = deep
		"Bordered":
			p.fill = [clear, tints[0], tints[1]]
			p.border = edge
			p.border_width = t.border_width * 2
			p.text = ink
			p.text_hover = ink
		"Light":
			p.fill = [clear, tints[0], tints[1]]
			p.text = t.role("text_muted") if neutral else ink
			p.text_hover = ink
		"Faded":
			# control_pressed is too dark for a tone label, and the dip already
			# says pressed
			p.fill = [t.role("control"), t.role("control_hover"), t.role("control_hover")]
			p.border = t.role("border")
			p.border_width = t.border_width * 2
			# grey control fill, so the tone needs to sit further out still
			var deeper: Color = t.role("text") if neutral else t.tone(r, 100 if t.mode == WoldTokens.Mode.DARK else 900)
			p.text = deeper
			p.text_hover = deeper
		"Shadow":
			p.shadow = Color(solid[0], 0.4)
		"Link":
			p.fill = [clear, clear, clear]
			p.text = t.role("text_muted") if neutral else ink
			p.text_hover = ink
	return p


# The role hover/pressed shades go lighter in dark mode, which is wrong for a
# light label on them. Step away from whatever the label is instead.
static func _solid(r: String, t: WoldTokens) -> Array:
	var light_ink := WoldColor.luminance(t.role("on_" + r)) > 0.5
	var steps := [600, 700] if light_ink else [400, 300]
	return [t.role(r), t.tone(r, steps[0]), t.tone(r, steps[1])]


# Light mode's control colour is nearly the page, fine with an edge but a
# solid button has none. A real grey step there.
static func _solid_neutral(t: WoldTokens) -> Array:
	if t.mode == WoldTokens.Mode.DARK:
		return [t.role("control"), t.role("control_hover"), t.role("control_pressed")]
	return [t.tone("neutral", 200), t.tone("neutral", 300), t.tone("neutral", 300)]


static func _denser(c: Color, factor: float) -> Color:
	return Color(c, minf(c.a * factor, 1.0))


static func _paint_grid(theme: Theme, style: String, look: String, tone: String, size: String, t: WoldTokens) -> void:
	var dims := t.control_size(size)
	var p := grid_palette(look, tone, t)
	var radius: int = dims.radius
	var padding: Vector2i = dims.padding
	var states := {"normal": p.fill[0], "hover": p.fill[1], "pressed": p.fill[2], "hover_pressed": p.fill[2]}
	for state in states:
		var sb := WoldStyle.flat(states[state], radius, padding, p.border, p.border_width)
		if p.shadow.a > 0.0:
			sb.shadow_color = p.shadow
			@warning_ignore("integer_division")
			sb.shadow_size = maxi(t.shadow_size / 2, 1)
			sb.shadow_offset = Vector2(0, maxf(t.shadow_offset.y / 2.0, 1.0))
		theme.set_stylebox(state, style, sb)
	var has_fill: bool = p.fill[0].a > 0.0 and look != "Flat"
	theme.set_stylebox("disabled", style, WoldStyle.flat(t.role("control_disabled") if has_fill else Color(0, 0, 0, 0), radius, padding))
	theme.set_stylebox("focus", style, WoldStyle.ring(t, radius))
	var colors := {
		"font_color": p.text, "font_hover_color": p.text_hover, "font_focus_color": p.text_hover,
		"font_pressed_color": p.text_hover, "font_hover_pressed_color": p.text_hover,
		"font_disabled_color": t.role("text_disabled"),
		"icon_normal_color": p.text, "icon_hover_color": p.text_hover, "icon_focus_color": p.text_hover,
		"icon_pressed_color": p.text_hover, "icon_hover_pressed_color": p.text_hover,
		"icon_disabled_color": t.role("text_disabled"),
		"font_outline_color": t.role("text_outline"),
	}
	# sizes inherit colours from their medium style; repeating them bloats
	# every generated theme file
	if size != "":
		colors.clear()
	if t.icon_tint == WoldTokens.IconTint.ORIGINAL:
		for item in ["icon_normal_color", "icon_hover_color", "icon_focus_color", "icon_pressed_color", "icon_hover_pressed_color"]:
			colors[item] = Color.WHITE
		colors["icon_disabled_color"] = Color(1, 1, 1, 0.4)
	for item in colors:
		theme.set_color(item, style, colors[item])
	theme.set_font_size("font_size", style, dims.font)
	theme.set_constant("h_separation", style, t.space_sm if size != "Xs" else t.space_xs)
	theme.set_constant("icon_max_width", style, dims.icon)
	theme.set_constant("outline_size", style, 0)
