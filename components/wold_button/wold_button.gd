@tool
class_name WoldButton
extends Button
## Plain Button plus shape, size and a second icon after the text.
## Still a real Button underneath, so toggle_mode, button_group, shortcuts and
## all the signals behave as normal.
# Style names come out as Button{Shape}{Size}, e.g. ButtonPrimarySm, ButtonGhost.
# To make a custom button, subclass and set props in _wold_refresh() (the
# gallery's confirm_button does this).

enum Shape { PRIMARY, SECONDARY, OUTLINE, GHOST, DANGER, ICON }
enum Size { SM, MD, LG }

const _SHAPE_NAMES := ["Primary", "Secondary", "Outline", "Ghost", "Danger", "Icon"]
const _SIZE_SUFFIX := ["Sm", "", "Lg"]
const _STATES := ["normal", "hover", "pressed", "disabled", "focus"]

@export var shape: Shape = Shape.SECONDARY:
	set(value):
		shape = value
		_refresh()
## Not `size`, Control already has one.
@export var button_size: Size = Size.MD:
	set(value):
		button_size = value
		_refresh()
## Theme type that overrides shape + size ("ButtonGold"). Empty = derived.
@export var variant := "":
	set(value):
		variant = value
		_refresh()

@export_group("Icons")
## Icon name from the tokens. A texture below wins over the name.
@export var icon_start := "":
	set(value):
		icon_start = value
		_refresh()
@export var icon_start_texture: Texture2D:
	set(value):
		icon_start_texture = value
		_refresh()
@export var icon_end := "":
	set(value):
		icon_end = value
		_refresh()
@export var icon_end_texture: Texture2D:
	set(value):
		icon_end_texture = value
		_refresh()

@export_group("Feedback")
## Played through WoldFeedback, if there's one above this button.
@export_enum("click", "confirm", "back", "open", "close", "none") var sound := "click":
	set(value):
		sound = value
		set_meta("wold_sound", value)

var _end_texture: Texture2D
var _applying := false
var _base_right_pad := 0.0
# Hidden twin with the same type variation. Reading styleboxes off it gives
# the theme's real padding, not the padded copies we install on ourselves.
var _probe := Button.new()


func _init() -> void:
	# an inherited scene sets the script once per level, so this runs twice on
	# one node: drop the probe the first script left behind
	for child in get_children(true):
		if child.name == &"WoldProbe":
			remove_child(child)
			child.free()
	_probe.name = &"WoldProbe"
	_probe.visible = false
	add_child(_probe, false, Node.INTERNAL_MODE_FRONT)
	set_meta("wold_sound", sound)


func _ready() -> void:
	_refresh()


func _notification(what: int) -> void:
	# deferred: we get THEME_CHANGED before the probe does, so it'd still
	# report the old style here
	if what == NOTIFICATION_THEME_CHANGED and not _applying:
		_refresh.call_deferred()


## Theme type variation in use.
func style_name() -> StringName:
	if variant != "":
		return StringName(variant)
	return StringName("Button" + _SHAPE_NAMES[shape] + _SIZE_SUFFIX[button_size])


func end_icon() -> Texture2D:
	return _end_texture


## Tint for the end icon. Same icon_*_color lookup Button does for its own
## icon, so both icons match in every state.
func end_icon_color() -> Color:
	match get_draw_mode():
		DRAW_DISABLED:
			return get_theme_color("icon_disabled_color")
		DRAW_PRESSED:
			return get_theme_color("icon_pressed_color")
		DRAW_HOVER:
			return get_theme_color("icon_hover_color")
		DRAW_HOVER_PRESSED:
			return get_theme_color("icon_hover_pressed_color")
	return get_theme_color("icon_focus_color") if has_focus() else get_theme_color("icon_normal_color")


## Subclass hook. Set shape/text/icons/disabled in here and they land in the
## same restyle pass.
func _wold_refresh() -> void:
	pass


var _refreshing := false


## Restyle from the props. Call it from a subclass's own setters.
func _refresh() -> void:
	if _refreshing or (not is_node_ready() and not is_inside_tree()):
		return
	_refreshing = true
	_wold_refresh()
	theme_type_variation = style_name()
	_probe.theme_type_variation = theme_type_variation
	var size_name: String = _SIZE_SUFFIX[button_size]
	icon = _resolve(icon_start, icon_start_texture, size_name)
	_end_texture = _resolve(icon_end, icon_end_texture, size_name)
	_apply_end_padding()
	_refreshing = false
	queue_redraw()


func _resolve(icon_name: String, texture: Texture2D, size_name: String) -> Texture2D:
	if texture:
		return texture
	if icon_name == "":
		return null
	return WoldUIRuntime.instance().tokens.icon(icon_name, size_name)


# Room for the end icon: copy each state's stylebox with icon width + gap
# added to the right margin, and hang them off a throwaway Theme on this node.
# Went with a Theme instead of theme overrides because overrides get saved into
# the .tscn; the Theme is stripped in _validate_property.
# NOTE: this means WoldButton takes over its own `theme` property. Anything you
# assign there gets replaced on the next refresh, style it through the tokens.
func _apply_end_padding() -> void:
	_applying = true
	# clear first so the probe sees the unpadded theme
	theme = null
	if _end_texture:
		var local := Theme.new()
		var extra := _end_width() + _probe.get_theme_constant("h_separation")
		_base_right_pad = _probe.get_theme_stylebox("normal").get_margin(SIDE_RIGHT)
		for state in _STATES:
			var base := _probe.get_theme_stylebox(state)
			if base == null:
				continue
			var padded := base.duplicate() as StyleBox
			if state != "focus":
				padded.content_margin_right = base.get_margin(SIDE_RIGHT) + extra
			local.set_stylebox(state, theme_type_variation, padded)
		theme = local
	_applying = false


func _end_width() -> float:
	if _end_texture == null:
		return 0.0
	var max_w := _probe.get_theme_constant("icon_max_width")
	var w := _end_texture.get_width()
	return float(mini(w, max_w)) if max_w > 0 else float(w)


func _draw() -> void:
	if _end_texture == null:
		return
	# lands in the gap _apply_end_padding reserved, left of the original margin
	var w := _end_width()
	var h := _end_texture.get_height() * (w / _end_texture.get_width())
	var rect := Rect2(size.x - _base_right_pad - w, (size.y - h) / 2.0, w, h)
	draw_texture_rect(_end_texture, rect, false, end_icon_color())


# All rebuilt from props on load, so keep them out of the .tscn.
func _validate_property(property: Dictionary) -> void:
	var generated: bool = property.name == "icon" and (icon_start != "" or icon_start_texture != null)
	generated = generated or property.name == "theme"
	generated = generated or property.name == "theme_type_variation"
	if generated:
		property.usage &= ~PROPERTY_USAGE_STORAGE
