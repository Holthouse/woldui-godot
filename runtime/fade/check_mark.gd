extends RefCounted
## Where CheckBox and CheckButton draw their mark and which icon it is, so
## button_fade can crossfade it on an overlay. Matches the engine's layout
## (compared pixel for pixel).

const _CHECKBOX_ICONS: PackedStringArray = [
	"checked", "unchecked", "checked_disabled", "unchecked_disabled",
	"radio_checked", "radio_unchecked", "radio_checked_disabled", "radio_unchecked_disabled",
]
const _SWITCH_ICONS: PackedStringArray = ["checked", "unchecked", "checked_disabled", "unchecked_disabled"]


static func applies(b: Button) -> bool:
	return b is CheckBox or b is CheckButton


static func icon_name(b: Button) -> String:
	var n := "checked" if b.button_pressed else "unchecked"
	if b is CheckBox and b.button_group != null:
		n = "radio_" + n
	return n + ("_disabled" if b.disabled else "")


# the engine centres the biggest of the set, so a smaller icon sits in the
# same box
static func _slot(b: Button) -> Vector2:
	var out := Vector2.ZERO
	for item in (_CHECKBOX_ICONS if b is CheckBox else _SWITCH_ICONS):
		var tex := b.get_theme_icon(item)
		if tex:
			out = out.max(tex.get_size())
	return out


static func rect(b: Button, tex: Texture2D) -> Rect2:
	var slot := _slot(b)
	var sb := b.get_theme_stylebox("normal")
	var pos := Vector2.ZERO
	if b is CheckBox:
		pos.x = sb.get_margin(SIDE_LEFT)
	else:
		pos.x = b.size.x - slot.x - sb.get_margin(SIDE_RIGHT)
	pos.y = floorf((b.size.y - slot.y) / 2.0) + b.get_theme_constant("check_v_offset")
	var s := tex.get_size()
	var max_w := b.get_theme_constant("icon_max_width")
	if max_w > 0 and s.x > max_w:
		s = Vector2(max_w, s.y * max_w / s.x)
	return Rect2(pos, s)
