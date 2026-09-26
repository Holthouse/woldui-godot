@tool
class_name WoldCheckbox
extends "../shared/wold_toggle_base.gd"
## Check box with a label and an optional description. Give a few of them one
## ButtonGroup and they draw as radios (like the engine's CheckBox).
## `indeterminate` shows a dash for "some of these"; a click clears it and
## checks the box.

@export var indeterminate := false:
	set(v):
		indeterminate = v
		if v:
			# so the next click lands on checked
			set_pressed_no_signal(false)
		queue_redraw()


func _ready() -> void:
	if not toggled.is_connected(_on_toggled):
		toggled.connect(_on_toggled)
	super()


## True when it draws as a radio.
func is_radio() -> bool:
	return button_group != null


## Theme icon name for the current state, off the CheckBox type.
func icon_name() -> String:
	var n := "unchecked"
	if indeterminate and not is_radio():
		n = "indeterminate"
	elif button_pressed:
		n = "checked"
	if is_radio():
		n = "radio_" + n
	return n + ("_disabled" if disabled else "")


func _style() -> StringName:
	return &"Checkbox"


func _indicator_size() -> Vector2:
	var px := get_theme_constant("check_size")
	return Vector2(px, px)


func _on_toggled(_on: bool) -> void:
	if indeterminate:
		indeterminate = false
		set_pressed_no_signal(true)
	queue_redraw()


func _draw_indicator(rect: Rect2) -> void:
	if is_hovered() and not disabled:
		var grow := rect.size.x * 0.3
		var halo := rect.grow(grow)
		var sb := StyleBoxFlat.new()
		sb.bg_color = get_theme_color("halo")
		sb.set_corner_radius_all(int(halo.size.x / 2.0))
		sb.corner_detail = 8
		sb.anti_aliasing = true
		draw_style_box(sb, halo)
	draw_texture_rect(get_theme_icon(icon_name(), &"CheckBox"), rect, false)
