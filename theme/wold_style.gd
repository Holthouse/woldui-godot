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


# ------------------------------------------------------------------ blending
# for the state fades in runtime/fade/

## A flat box that blend() can use for `sb`, or null (texture and line boxes
## don't blend). Empty and centre-less boxes become a clear copy of `like`,
## so a fade from nothing doesn't dip through black.
static func blendable(sb: StyleBox, like: StyleBox = null) -> StyleBoxFlat:
	if sb is StyleBoxFlat and (sb as StyleBoxFlat).draw_center:
		return sb
	if sb != null and not (sb is StyleBoxEmpty or sb is StyleBoxFlat):
		return null
	var out: StyleBoxFlat
	if sb is StyleBoxFlat:
		out = sb.duplicate()
	elif like is StyleBoxFlat:
		out = like.duplicate()
		out.border_color.a = 0.0
		out.shadow_color.a = 0.0
	else:
		out = StyleBoxFlat.new()
	out.bg_color.a = 0.0
	out.draw_center = true
	if sb != null:
		for side in 4:
			out.set_content_margin(side, sb.get_content_margin(side))
	return out


## Writes a -> b at `v` into `into`. Margins, AA and corner detail snap to b.
static func blend(a: StyleBoxFlat, b: StyleBoxFlat, v: float, into: StyleBoxFlat) -> void:
	into.set_block_signals(true)
	into.bg_color = mix(a.bg_color, b.bg_color, v)
	into.border_color = mix(a.border_color, b.border_color, v)
	into.shadow_color = mix(a.shadow_color, b.shadow_color, v)
	for side in 4:
		into.set_border_width(side, roundi(lerpf(a.get_border_width(side), b.get_border_width(side), v)))
		into.set_expand_margin(side, lerpf(a.get_expand_margin(side), b.get_expand_margin(side), v))
		into.set_content_margin(side, b.get_content_margin(side))
	for corner in 4:
		into.set_corner_radius(corner, roundi(lerpf(a.get_corner_radius(corner), b.get_corner_radius(corner), v)))
	into.shadow_size = roundi(lerpf(a.shadow_size, b.shadow_size, v))
	into.shadow_offset = a.shadow_offset.lerp(b.shadow_offset, v)
	into.skew = a.skew.lerp(b.skew, v)
	into.draw_center = true
	into.border_blend = b.border_blend
	into.anti_aliasing = b.anti_aliasing
	into.anti_aliasing_size = b.anti_aliasing_size
	into.corner_detail = b.corner_detail
	into.set_block_signals(false)
	into.emit_changed()


## Colour lerp where a fully clear end takes the other end's hue.
static func mix(a: Color, b: Color, v: float) -> Color:
	if a.a == 0.0:
		a = Color(b, 0.0)
	if b.a == 0.0:
		b = Color(a, 0.0)
	return a.lerp(b, v)


## `sb` at alpha `a`, for boxes a component fades in itself. Only flat boxes
## really fade; anything else shows from halfway.
static func faded(sb: StyleBox, a: float) -> StyleBox:
	if a >= 1.0:
		return sb
	if sb is StyleBoxFlat:
		var out: StyleBoxFlat = sb.duplicate()
		out.bg_color.a *= a
		out.border_color.a *= a
		out.shadow_color.a *= a
		return out
	return sb if a >= 0.5 else StyleBoxEmpty.new()
