@tool
extends RefCounted
## Internal. Buttons that hold their own layout (%Content) don't grow to fit
## it, so this insets the content by the normal stylebox and sets the minimum
## size. Also the label dimming shared by the toggles.


## `min_height` is for the content box, the stylebox margins go on top.
static func fit(b: Button, content: Control, min_height := 0.0) -> void:
	var sb := b.get_theme_stylebox("normal")
	content.offset_left = sb.get_margin(SIDE_LEFT)
	content.offset_top = sb.get_margin(SIDE_TOP)
	content.offset_right = -sb.get_margin(SIDE_RIGHT)
	content.offset_bottom = -sb.get_margin(SIDE_BOTTOM)
	var need := content.get_combined_minimum_size() + sb.get_minimum_size()
	b.custom_minimum_size = Vector2(need.x, maxf(need.y, min_height + sb.get_margin(SIDE_TOP) + sb.get_margin(SIDE_BOTTOM)))


## A child Label doesn't know its button went disabled. `style` + "Disabled"
## while it is (ToggleLabel -> ToggleLabelDisabled).
static func dim(b: BaseButton, label: Label, style: StringName) -> void:
	var want := StringName(style + "Disabled") if b.disabled else style
	if label.theme_type_variation != want:
		label.theme_type_variation = want


## Vertical middle of `label` in the button's space. Indicators (knob, check
## box) line up with the first line, not with label + description.
static func label_mid(b: Button, content: Control, label: Control, has_description: bool) -> float:
	if not has_description or not label.visible:
		return b.size.y / 2.0
	return content.position.y + label.position.y + label.size.y / 2.0
