@tool
extends RefCounted
## Text fields, toggles, pickers. The check / radio / switch icons are drawn
## in toggle_recipe.

const STYLES: PackedStringArray = [
	"FieldSm", "FieldLg", "LineEditInvalid", "FieldSmInvalid", "FieldLgInvalid", "TextEditInvalid",
	"FieldLabel", "FieldDescription", "FieldError", "FieldCounter", "FieldCounterOver",
]


static func contribute(theme: Theme, t: WoldTokens) -> void:
	for size in ["", "Sm", "Lg"]:
		var style: String = "LineEdit" if size == "" else "Field" + size
		if size != "":
			theme.set_type_variation(style, "LineEdit")
		_field(theme, style, t, t.control_size(size))
	_field(theme, "TextEdit", t, t.control_size(""))
	for style in ["LineEdit", "FieldSm", "FieldLg", "TextEdit"]:
		_invalid(theme, style, t)
	_field_text(theme, t)
	theme.set_color("background_color", "TextEdit", Color(0, 0, 0, 0))
	theme.set_color("current_line_color", "TextEdit", t.role("surface_hover"))
	theme.set_color("font_readonly_color", "TextEdit", t.role("text_muted"))
	theme.set_color("caret_background_color", "TextEdit", t.role("field"))

	for type in ["CheckBox", "CheckButton"]:
		for state in ["normal", "pressed", "hover", "hover_pressed", "disabled"]:
			theme.set_stylebox(state, type, WoldStyle.empty(Vector2i(t.space_xs, t.space_xs)))
		theme.set_stylebox("focus", type, WoldStyle.ring(t, t.radius_sm))
		theme.set_color("font_color", type, t.role("text"))
		theme.set_color("font_hover_color", type, t.role("text"))
		theme.set_color("font_pressed_color", type, t.role("text"))
		theme.set_color("font_hover_pressed_color", type, t.role("text"))
		theme.set_color("font_focus_color", type, t.role("text"))
		theme.set_color("font_disabled_color", type, t.role("text_disabled"))
		theme.set_constant("h_separation", type, t.space_sm)

	for type in ["OptionButton", "MenuButton"]:
		var dims := t.control_size("")
		var fills := {"normal": t.role("control"), "hover": t.role("control_hover"), "pressed": t.role("control_pressed")}
		for state in fills:
			theme.set_stylebox(state, type, WoldStyle.flat(fills[state], dims.radius, dims.padding, t.role("border"), t.border_width))
		theme.set_stylebox("disabled", type, WoldStyle.flat(t.role("control_disabled"), dims.radius, dims.padding))
		theme.set_stylebox("focus", type, WoldStyle.ring(t, dims.radius))
		for item in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_hover_pressed_color"]:
			theme.set_color(item, type, t.role("text"))
		theme.set_color("font_disabled_color", type, t.role("text_disabled"))
		theme.set_constant("h_separation", type, t.space_sm)
	theme.set_constant("arrow_margin", "OptionButton", t.space_md)

	theme.set_color("font_color", "LinkButton", t.role("accent_text"))
	theme.set_color("font_hover_color", "LinkButton", t.role("text"))
	theme.set_color("font_pressed_color", "LinkButton", t.role("accent_text"))
	theme.set_color("font_focus_color", "LinkButton", t.role("text"))
	theme.set_stylebox("focus", "LinkButton", WoldStyle.ring(t, t.radius_sm))


# WoldField swaps a control to X + "Invalid" while it shows an error.
# danger_text, not danger: plain danger drops under 3:1 on dark panels
static func _invalid(theme: Theme, style: String, t: WoldTokens) -> void:
	var bad := style + "Invalid"
	theme.set_type_variation(bad, style)
	for state in ["normal", "focus"]:
		var sb := (theme.get_stylebox(state, style) as StyleBoxFlat).duplicate() as StyleBoxFlat
		sb.border_color = t.role("danger_text")
		theme.set_stylebox(state, bad, sb)


static func _field_text(theme: Theme, t: WoldTokens) -> void:
	var small := t.font_size(-1)
	var styles := {
		"FieldLabel": [t.font_size(0), t.role("text")],
		"FieldDescription": [small, t.role("text_muted")],
		"FieldError": [small, t.role("danger_text")],
		"FieldCounter": [small, t.role("text_muted")],
		"FieldCounterOver": [small, t.role("danger_text")],
	}
	for style in styles:
		theme.set_type_variation(style, "Label")
		theme.set_font_size("font_size", style, styles[style][0])
		theme.set_color("font_color", style, styles[style][1])
	# WoldField.horizontal: the label column and the gap after it
	theme.set_constant("label_width", "FieldLabel", t.space_xxl * 4)
	theme.set_constant("label_gap", "FieldLabel", t.space_md)


static func _field(theme: Theme, style: String, t: WoldTokens, dims: Dictionary) -> void:
	var padding: Vector2i = dims.padding
	padding.x = maxi(padding.x - 6, t.space_sm)
	theme.set_stylebox("normal", style, WoldStyle.flat(t.role("field"), dims.radius, padding, t.role("field_border"), t.border_width))
	theme.set_stylebox("read_only", style, WoldStyle.flat(Color(0, 0, 0, 0), dims.radius, padding, t.role("border_strong"), t.border_width))
	# focus just recolours the field border, no separate ring
	var focus := WoldStyle.flat(Color(0, 0, 0, 0), dims.radius, padding, t.role("focus"), t.focus_width)
	focus.draw_center = false
	theme.set_stylebox("focus", style, focus)
	theme.set_color("font_color", style, t.role("text"))
	theme.set_color("font_selected_color", style, t.role("text"))
	theme.set_color("font_uneditable_color", style, t.role("text_muted"))
	theme.set_color("font_placeholder_color", style, t.role("text_disabled"))
	theme.set_color("caret_color", style, t.role("accent"))
	theme.set_color("selection_color", style, t.role("accent_soft"))
	theme.set_color("clear_button_color", style, t.role("text_muted"))
	theme.set_color("clear_button_color_pressed", style, t.role("text"))
	theme.set_font_size("font_size", style, dims.font)
