@tool
extends RefCounted
## Button{Shape}{Size}, e.g. ButtonPrimarySm. No suffix = medium.
## A plain Button looks like ButtonSecondary.

const SHAPES: PackedStringArray = ["Primary", "Secondary", "Outline", "Ghost", "Danger", "Icon"]
const SIZES: PackedStringArray = ["Sm", "", "Lg"]

# kept by hand for the tests and the gallery, add new ones here too
const STYLES: PackedStringArray = [
	"ButtonPrimary", "ButtonPrimarySm", "ButtonPrimaryLg",
	"ButtonSecondary", "ButtonSecondarySm", "ButtonSecondaryLg",
	"ButtonOutline", "ButtonOutlineSm", "ButtonOutlineLg",
	"ButtonGhost", "ButtonGhostSm", "ButtonGhostLg",
	"ButtonDanger", "ButtonDangerSm", "ButtonDangerLg",
	"ButtonIcon", "ButtonIconSm", "ButtonIconLg",
]


static func contribute(theme: Theme, t: WoldTokens) -> void:
	_paint(theme, "Button", "Secondary", "", t)
	for shape in SHAPES:
		for size in SIZES:
			var style: String = "Button" + shape + size
			# Sm/Lg inherit from the medium one, medium from Button
			theme.set_type_variation(style, "Button" + shape if size != "" else "Button")
			_paint(theme, style, shape, size, t)


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
