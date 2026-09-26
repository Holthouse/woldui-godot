@tool
class_name WoldBadge
extends PanelContainer
## Little pill for a status ("Allied"), a count (3, 99+) or just a dot.
## Drop it in a layout, or set `pin` to stick it on a corner of its parent,
## e.g. an unread count on a button.
# theme types: Badge{Tone}{Fill}{Size}, BadgeLabel{...}, BadgeDot{Tone}

enum Tone { NEUTRAL, ACCENT, SUCCESS, WARNING, DANGER }
enum Fill { SOFT, SOLID, OUTLINE }
enum Size { SM, MD }
enum Pin { NONE, TOP_RIGHT, TOP_LEFT }

const _TONES := ["Neutral", "Accent", "Success", "Warning", "Danger"]
const _FILLS := ["Soft", "Solid", "Outline"]
const _SIZES := ["Sm", ""]

## Ignored while count is on.
@export var text := "Badge":
	set(v):
		text = v
		_refresh()
@export var icon := "":
	set(v):
		icon = v
		_refresh()
@export var icon_texture: Texture2D:
	set(v):
		icon_texture = v
		_refresh()
## -1 = off, otherwise shows the number instead of text.
@export var count := -1:
	set(v):
		var old := count
		count = v
		_refresh()
		if animate and v > old and old >= 0 and is_inside_tree() and not Engine.is_editor_hint() and visible:
			WoldMotion.bump(self)
## Past this it reads "99+".
@export var max_count := 99:
	set(v):
		max_count = v
		_refresh()
@export var hide_zero := true:
	set(v):
		hide_zero = v
		_refresh()
@export var dot := false:
	set(v):
		dot = v
		_refresh()

@export_group("Look")
@export var tone: Tone = Tone.NEUTRAL:
	set(v):
		tone = v
		_refresh()
@export var fill: Fill = Fill.SOFT:
	set(v):
		fill = v
		_refresh()
@export var badge_size: Size = Size.MD:
	set(v):
		badge_size = v
		_refresh()
@export var pin: Pin = Pin.NONE:
	set(v):
		pin = v
		_refresh()
## Slow breathing, for a "your turn" marker. Stays solid under reduced motion.
@export var pulse := false:
	set(v):
		pulse = v
		_apply_pulse()
## Bump when the count goes up.
@export var animate := true

var _refreshing := false


func _ready() -> void:
	_refresh()
	_apply_pulse()
	resized.connect(_place)


## Override hook, runs first thing in every restyle.
func _wold_refresh() -> void:
	pass


## Current label text, "" for a dot.
func shown_text() -> String:
	if dot:
		return ""
	if count >= 0:
		return "%d+" % max_count if count > max_count else str(count)
	return text


func _refresh() -> void:
	if _refreshing or not is_node_ready():
		return
	_refreshing = true
	_wold_refresh()
	var size_suffix: String = _SIZES[badge_size]
	var label := %Label as Label
	var icon_node := %Icon as TextureRect
	if dot:
		theme_type_variation = StringName("BadgeDot" + _TONES[tone])
		var d := 8.0 if badge_size == Size.SM else 10.0
		custom_minimum_size = Vector2(d, d)
		label.visible = false
		icon_node.visible = false
	else:
		theme_type_variation = StringName("Badge" + _TONES[tone] + _FILLS[fill] + size_suffix)
		custom_minimum_size = Vector2.ZERO
		label.theme_type_variation = StringName("BadgeLabel" + _TONES[tone] + _FILLS[fill] + size_suffix)
		label.text = shown_text()
		label.visible = label.text != ""
		var tex := _icon_texture()
		icon_node.texture = tex
		icon_node.visible = tex != null
		var px := 12.0 if badge_size == Size.SM else 14.0
		icon_node.custom_minimum_size = Vector2(px, px)
		icon_node.self_modulate = label.get_theme_color("font_color")
	# only touch visible in count mode, otherwise it's the game's call
	if count >= 0 and not dot:
		visible = not (count == 0 and hide_zero)
	_refreshing = false
	_place()


# Centred on the parent's corner. Does nothing inside a Container, which owns
# the layout there.
func _place() -> void:
	if pin == Pin.NONE or not is_inside_tree() or get_parent() is Container:
		return
	var s := get_combined_minimum_size()
	var right := pin == Pin.TOP_RIGHT
	anchor_left = 1.0 if right else 0.0
	anchor_right = anchor_left
	anchor_top = 0.0
	anchor_bottom = 0.0
	offset_left = -s.x / 2.0
	offset_right = s.x / 2.0
	offset_top = -s.y / 2.0
	offset_bottom = s.y / 2.0


func _apply_pulse() -> void:
	if not is_inside_tree() or Engine.is_editor_hint():
		return
	if pulse:
		WoldMotion.pulse(self)
	else:
		WoldMotion.stop(self)


func _icon_texture() -> Texture2D:
	if icon_texture:
		return icon_texture
	if icon == "":
		return null
	var t := WoldUIRuntime.instance().tokens
	var px := 12 if badge_size == Size.SM else 14
	if t.icon_set:
		return t.icon_set.get_icon(icon, px, t.icon_stroke)
	return WoldIcons.texture(icon, px, t.icon_stroke)
