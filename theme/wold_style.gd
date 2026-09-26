@tool
class_name WoldStyle
## Stylebox factories. All generated styleboxes come through here so global
## stuff (AA, focus ring placement) is a one-line change. Colours come in as args.


## Rounded box. padding.x = left/right margin, padding.y = top/bottom.
static func flat(bg: Color, radius: int, padding := Vector2i.ZERO, border := Color(0, 0, 0, 0), border_width := 0) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.set_corner_radius_all(radius)
	sb.corner_detail = 8
	sb.anti_aliasing = true
	pad(sb, padding)
	if border.a > 0.0 and border_width > 0:
		sb.border_color = border
		sb.set_border_width_all(border_width)
	return sb


## flat() plus drop shadow, for dialogs and overlays.
static func raised(bg: Color, radius: int, padding: Vector2i, t: WoldTokens, border := Color(0, 0, 0, 0)) -> StyleBoxFlat:
	var sb := flat(bg, radius, padding, border, t.border_width)
	sb.shadow_color = t.role("shadow")
	sb.shadow_size = t.shadow_size
	sb.shadow_offset = t.shadow_offset
	return sb


## Focus ring.
# sits outside the control via expand margin, so it never eats the border or text
static func ring(t: WoldTokens, radius: int) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.draw_center = false
	sb.border_color = t.role("focus")
	sb.set_border_width_all(t.focus_width)
	sb.set_expand_margin_all(t.focus_offset + t.focus_width)
	sb.set_corner_radius_all(radius + t.focus_offset + t.focus_width)
	sb.corner_detail = 8
	sb.anti_aliasing = true
	return sb


## Bottom border only. Selected tabs etc.
static func underline(color: Color, width: int, padding: Vector2i) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0, 0, 0, 0)
	sb.border_color = color
	sb.border_width_bottom = width
	pad(sb, padding)
	return sb


static func empty(padding := Vector2i.ZERO) -> StyleBoxEmpty:
	var sb := StyleBoxEmpty.new()
	pad(sb, padding)
	return sb


static func line(color: Color, thickness: int, vertical := false) -> StyleBoxLine:
	var sb := StyleBoxLine.new()
	sb.color = color
	sb.thickness = thickness
	sb.vertical = vertical
	return sb


static func pad(sb: StyleBox, padding: Vector2i) -> void:
	sb.content_margin_left = padding.x
	sb.content_margin_right = padding.x
	sb.content_margin_top = padding.y
	sb.content_margin_bottom = padding.y
