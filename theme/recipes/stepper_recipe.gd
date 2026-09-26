@tool
extends RefCounted
## WoldStepper: the whole row is the button (so it highlights and takes focus
## as one), the arrows are small ghost icon buttons inside it.

const STYLES: PackedStringArray = ["Stepper", "StepperValue", "StepperValueDisabled", "StepperArrow"]


static func contribute(theme: Theme, t: WoldTokens) -> void:
	theme.set_type_variation("Stepper", "Button")
	var pad := Vector2i(t.space_sm, t.space_xs)
	var r := t.radius_md
	theme.set_stylebox("normal", "Stepper", WoldStyle.flat(Color(0, 0, 0, 0), r, pad))
	theme.set_stylebox("disabled", "Stepper", WoldStyle.flat(Color(0, 0, 0, 0), r, pad))
	for state in ["hover", "pressed", "hover_pressed"]:
		theme.set_stylebox(state, "Stepper", WoldStyle.flat(t.role("surface_hover"), r, pad))
	theme.set_stylebox("focus", "Stepper", WoldStyle.ring(t, r))

	theme.set_type_variation("StepperValue", "Label")
	theme.set_color("font_color", "StepperValue", t.role("text"))
	theme.set_font_size("font_size", "StepperValue", t.font_size(0))
	theme.set_type_variation("StepperValueDisabled", "StepperValue")
	theme.set_color("font_color", "StepperValueDisabled", t.role("text_disabled"))

	# chained on the small icon button, only the arrows' colour differs
	theme.set_type_variation("StepperArrow", "ButtonIconSm")
	theme.set_color("icon_normal_color", "StepperArrow", t.role("accent_text"))
	theme.set_color("icon_hover_color", "StepperArrow", t.role("text"))
