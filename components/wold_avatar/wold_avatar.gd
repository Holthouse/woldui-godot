@tool
class_name WoldAvatar
extends Control
## A portrait: player, faction leader, unit. Shows `texture` cropped to a
## circle or rounded square, or the initials of `display_name` when there's
## no picture. `status` puts a presence dot on it. Add a WoldBadge as a child
## (pin TOP_RIGHT) for a count.

enum Shape { ROUND, SQUARE }
enum Size { SM, MD, LG }
enum Status { NONE, ONLINE, AWAY, BUSY, OFFLINE }

const _SUFFIX := ["Sm", "", "Lg"]
const _STATUS := ["", "AvatarOnline", "AvatarAway", "AvatarBusy", "AvatarOffline"]

@export var texture: Texture2D:
	set(v):
		texture = v
		_refresh()
## Initials come from this ("Queen Mab" -> QM). Also the tooltip.
@export var display_name := "":
	set(v):
		display_name = v
		_refresh()
## Shown instead of the initials ("+3"). Empty = from display_name.
@export var initials := "":
	set(v):
		initials = v
		_refresh()
@export var shape: Shape = Shape.ROUND:
	set(v):
		shape = v
		_refresh()
## Not `size`, Control has one.
@export var avatar_size: Size = Size.MD:
	set(v):
		avatar_size = v
		_refresh()
@export var status: Status = Status.NONE:
	set(v):
		status = v
		_refresh()
## Behind the initials, a faction colour say. Transparent = the theme's.
@export var color := Color(0, 0, 0, 0):
	set(v):
		color = v
		_refresh()
## A ring in the surface colour, so overlapping avatars stay apart. Always
## on inside a WoldAvatarGroup.
@export var ring := false:
	set(v):
		ring = v
		queue_redraw()

var _refreshing := false


func _ready() -> void:
	_refresh()


func _notification(what: int) -> void:
	if what == NOTIFICATION_THEME_CHANGED:
		_refresh.call_deferred()


## Subclass hook, before each restyle.
func _wold_refresh() -> void:
	pass


## "Queen Mab" -> "QM", "rivermouth" -> "R". Two letters at most.
static func initials_of(text: String) -> String:
	var out := ""
	for word in text.strip_edges().split(" ", false):
		out += word.substr(0, 1).to_upper()
		if out.length() == 2:
			break
	return out


func frame_style() -> StringName:
	return StringName("Avatar" + ("Round" if shape == Shape.ROUND else "Square") + _SUFFIX[avatar_size])


func _refresh() -> void:
	if _refreshing or not is_node_ready():
		return
	_refreshing = true
	_wold_refresh()
	var mask := %Mask as Panel
	mask.theme_type_variation = frame_style()
	var px := float(mask.get_theme_constant(&"size"))
	custom_minimum_size = Vector2(px, px)
	(%Image as TextureRect).texture = texture
	%Image.visible = texture != null
	var fill := %Fill as ColorRect
	fill.visible = color.a > 0.0 and texture == null
	fill.color = color
	var label := %Initials as Label
	label.theme_type_variation = StringName("AvatarInitials" + _SUFFIX[avatar_size])
	label.text = initials if initials != "" else initials_of(display_name)
	label.visible = texture == null
	if fill.visible:
		label.add_theme_color_override(&"font_color", WoldColor.on(color))
	else:
		label.remove_theme_color_override(&"font_color")
	tooltip_text = display_name
	var dot := %Status as Panel
	dot.visible = status != Status.NONE
	if dot.visible:
		dot.theme_type_variation = StringName(_STATUS[status])
		var d := roundf(px * 0.3)
		# on the rim at 45 degrees for a circle, the corner for a square
		var at := px / 2.0 + px / 2.0 * 0.7071 if shape == Shape.ROUND else px - d * 0.35
		dot.size = Vector2(d, d)
		dot.position = Vector2(at, at) - Vector2(d, d) / 2.0
	_refreshing = false
	queue_redraw()


func has_ring() -> bool:
	return ring or get_parent() is WoldAvatarGroup


func _draw() -> void:
	if not has_ring():
		return
	var w := float((%Mask as Control).get_theme_constant(&"ring_width"))
	var sb := ((%Mask as Control).get_theme_stylebox(&"panel") as StyleBoxFlat).duplicate() as StyleBoxFlat
	sb.bg_color = (%Mask as Control).get_theme_color(&"ring")
	for c in 4:
		sb.set_corner_radius(c, sb.get_corner_radius(c) + int(w))
	draw_style_box(sb, Rect2(-w, -w, size.x + w * 2.0, size.y + w * 2.0))


func _validate_property(property: Dictionary) -> void:
	if property.name in ["custom_minimum_size", "tooltip_text"]:
		property.usage &= ~PROPERTY_USAGE_STORAGE
