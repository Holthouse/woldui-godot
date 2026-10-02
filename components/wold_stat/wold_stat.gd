@tool
class_name WoldStat
extends PanelContainer
## Icon + number + label, the top-bar resource counter. Gold, population
## 12 / 20, a score. Changing value in-game rolls the number and flashes it
## in the StatDeltaUp / StatDeltaDown colour.
## Override _wold_format() if you need your own units ("3d 4h"). %Extra is
## there for anything else you want to stick on (a meter, a button).

signal value_changed(old_value: float, new_value: float)

enum Layout { INLINE, STACKED }
enum Surface { BARE, HUD, RAISED, SUNKEN }
enum Size { SM, MD, LG }
enum Tone { NEUTRAL, ACCENT, SUCCESS, WARNING, DANGER }

const _SURFACES := ["PanelBare", "PanelHud", "PanelRaised", "PanelSunken"]
const _VALUE_STYLES := ["StatValueSm", "StatValue", "StatValueLg"]
const _ICON_SIZES := ["Sm", "", "Lg"]
const _TONE_STYLES := ["Muted", "TextAccent", "TextSuccess", "TextWarning", "TextDanger"]
# proper minus sign (U+2212), a hyphen looks too short next to "+"
const MINUS := "−"

## Icon name. icon_texture wins if both are set.
@export var icon := "":
	set(v):
		icon = v
		_refresh()
@export var icon_texture: Texture2D:
	set(v):
		icon_texture = v
		_refresh()
@export var value := 0.0:
	set(v):
		var old := value
		value = v
		_on_value(old)
## > 0 shows "value / max".
@export var max_value := 0.0:
	set(v):
		max_value = v
		_refresh()
## printf style: "%d", "%.1f", "%d gold".
@export var format := "%d":
	set(v):
		format = v
		_refresh()
## 1200 -> 1.2k, 3400000 -> 3.4M. Ignores format.
@export var compact := false:
	set(v):
		compact = v
		_refresh()
@export var label := "":
	set(v):
		label = v
		_refresh()
## INLINE: label after the value. STACKED: label above it.
@export var layout: Layout = Layout.INLINE:
	set(v):
		layout = v
		_refresh()

@export_group("Change")
## e.g. +5 per turn. Needs show_delta.
@export var delta := 0.0:
	set(v):
		delta = v
		_refresh()
@export var show_delta := false:
	set(v):
		show_delta = v
		_refresh()
## Count-up + flash when value changes.
@export var animate := true

@export_group("Look")
## Icon colour.
@export var tone: Tone = Tone.NEUTRAL:
	set(v):
		tone = v
		_refresh()
@export var surface: Surface = Surface.HUD:
	set(v):
		surface = v
		_refresh()
@export var stat_size: Size = Size.MD:
	set(v):
		stat_size = v
		_refresh()

var _refreshing := false


func _ready() -> void:
	_refresh()


func _notification(what: int) -> void:
	if what == NOTIFICATION_THEME_CHANGED:
		_refresh.call_deferred()


## Subclass hook, first thing in _refresh().
func _wold_refresh() -> void:
	pass


## Formats a single number. Used for value, max and delta alike.
func _wold_format(v: float) -> String:
	if compact:
		return _compact(v)
	if format.contains("%d"):
		return format % roundi(v)
	return format % v


## What the Value label shows. Pass v to format something other than value
## (the count-up tween does).
func display_text(v := NAN) -> String:
	if is_nan(v):
		v = value
	var s := _wold_format(v)
	if max_value > 0.0:
		s += " / " + _wold_format(max_value)
	return s


func delta_text() -> String:
	if is_zero_approx(delta):
		return ""
	return ("+" if delta > 0.0 else MINUS) + _wold_format(absf(delta))


func _refresh() -> void:
	if _refreshing or not is_node_ready():
		return
	_refreshing = true
	_wold_refresh()
	theme_type_variation = StringName(_SURFACES[surface])
	var icon_node := _node("Icon") as TextureRect
	var tex := _icon_texture()
	icon_node.texture = tex
	icon_node.visible = tex != null
	var px: float = _tokens().control_size(_ICON_SIZES[stat_size]).icon
	icon_node.custom_minimum_size = Vector2(px, px)
	icon_node.self_modulate = icon_color()
	var value_node := _node("Value") as Label
	value_node.theme_type_variation = StringName(_VALUE_STYLES[stat_size])
	value_node.text = display_text()
	var caption := _node("Caption") as Label
	caption.text = label
	caption.visible = layout == Layout.STACKED and label != ""
	var inline := _node("Label") as Label
	inline.text = label
	inline.visible = layout == Layout.INLINE and label != ""
	var delta_node := _node("Delta") as Label
	delta_node.text = delta_text()
	delta_node.visible = show_delta and delta_node.text != ""
	delta_node.theme_type_variation = &"StatDeltaUp" if delta > 0.0 else &"StatDeltaDown"
	_refreshing = false


## Tone colour, or plain white if the tokens say icons keep their own colours.
func icon_color() -> Color:
	if _tokens().icon_tint == WoldTokens.IconTint.ORIGINAL:
		return Color.WHITE
	return get_theme_color("font_color", _TONE_STYLES[tone])


func _on_value(old: float) -> void:
	if not is_node_ready():
		return
	var value_node := _node("Value") as Label
	var live := animate and is_inside_tree() and not Engine.is_editor_hint()
	if live and not is_equal_approx(old, value):
		var set_text := func(v: float) -> void:
			value_node.text = display_text(v)
		WoldMotion.tween_number(value_node, old, value, set_text)
		var up_style := &"StatDeltaUp" if value > old else &"StatDeltaDown"
		WoldMotion.flash(value_node, get_theme_color("font_color", up_style))
	else:
		value_node.text = display_text()
	if not is_equal_approx(old, value):
		value_changed.emit(old, value)


func _icon_texture() -> Texture2D:
	if icon_texture:
		return icon_texture
	if icon == "":
		return null
	return _tokens().icon(icon, _ICON_SIZES[stat_size])


func _tokens() -> WoldTokens:
	return WoldUIRuntime.instance().tokens


func _node(node_name: String) -> Node:
	return get_node("%" + node_name)


static func _compact(v: float) -> String:
	var a := absf(v)
	for step in [[1e9, "B"], [1e6, "M"], [1e3, "k"]]:
		if a >= step[0]:
			var s := "%.1f" % (v / step[0])
			return s.trim_suffix(".0") + step[1]
	return str(roundi(v))
