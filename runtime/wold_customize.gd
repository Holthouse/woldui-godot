@tool
class_name WoldCustomize
extends RefCounted
## Turns a control's WoldCustom (metadata wold_custom) into theme overrides
## on that control only. The editor plugin runs it as you edit, the WoldUI
## autoload again when the node enters the game, so a token change still
## reaches customised controls.
# The overrides are worked out from the theme the control would have without
# them (ThemeLookup), so re-applying never compounds.

const META := &"wold_custom"
const APPLIED := &"_wold_custom_applied"
const Lookup := preload("res://addons/woldui/runtime/fade/theme_lookup.gd")
const _SOUNDS := ["", "click", "confirm", "back", "open", "close", "none"]
# text colours; the disabled, placeholder and outline ones stay the theme's
const _INK_SKIP := ["disabled", "outline", "placeholder", "uneditable", "readonly", "shadow", "caret", "selection", "clear_button", "drop_mark", "guide"]


static func custom_of(node: Node) -> WoldCustom:
	return node.get_meta(META) as WoldCustom if node.has_meta(META) else null


## Applies `node`'s WoldCustom, replacing whatever it applied before.
static func apply(node: Control) -> void:
	clear(node)
	var c := custom_of(node)
	if c == null:
		return
	var boxes := {}
	var colors := {}
	for item in _items(node, Theme.DATA_TYPE_STYLEBOX):
		var sb := _box(node, item, c)
		if sb:
			boxes[item] = sb
	if c.text.a > 0.0:
		for item in _items(node, Theme.DATA_TYPE_COLOR):
			if _is_ink(item):
				colors[item] = c.text
	var sizes := {}
	if c.font_size > 0:
		for item in _items(node, Theme.DATA_TYPE_FONT_SIZE):
			sizes[item] = c.font_size
	var fonts := {}
	if c.font:
		for item in _items(node, Theme.DATA_TYPE_FONT):
			fonts[item] = c.font
	var applied := {boxes = boxes.keys(), colors = colors.keys(), sizes = sizes.keys(), fonts = fonts.keys(), labels = []}
	var fade: Object = node.get_meta(&"_wold_fade") if node.has_meta(&"_wold_fade") else null
	if fade and fade.has_method(&"set_own"):
		# the fade draws the boxes and colours itself; it just needs new targets
		var own := {}
		own.merge(boxes)
		own.merge(colors)
		fade.set_own(own)
		applied.fade = true
	else:
		node.begin_bulk_theme_override()
		for item in boxes:
			node.add_theme_stylebox_override(item, boxes[item])
		for item in colors:
			node.add_theme_color_override(item, colors[item])
		node.end_bulk_theme_override()
	for item in sizes:
		node.add_theme_font_size_override(item, sizes[item])
	for item in fonts:
		node.add_theme_font_override(item, fonts[item])
	# a WoldUI component draws its text with Labels of its own
	if c.text.a > 0.0 or c.font or c.font_size > 0:
		for label in node.find_children("*", "Label", true, false):
			if label.owner != node:
				continue
			if c.text.a > 0.0:
				label.add_theme_color_override("font_color", c.text)
			if c.font:
				label.add_theme_font_override("font", c.font)
			if c.font_size > 0:
				label.add_theme_font_size_override("font_size", c.font_size)
			applied.labels.append(node.get_path_to(label))
	_feedback_meta(node, c, applied)
	node.set_meta(APPLIED, applied)


## Takes off everything apply() put on.
static func clear(node: Control) -> void:
	if not node.has_meta(APPLIED):
		return
	var applied: Dictionary = node.get_meta(APPLIED)
	var fade: Object = node.get_meta(&"_wold_fade") if node.has_meta(&"_wold_fade") else null
	if applied.get("fade", false) and fade:
		fade.set_own({})
	else:
		node.begin_bulk_theme_override()
		for item in applied.get("boxes", []):
			node.remove_theme_stylebox_override(item)
		for item in applied.get("colors", []):
			node.remove_theme_color_override(item)
		node.end_bulk_theme_override()
	for item in applied.get("sizes", []):
		node.remove_theme_font_size_override(item)
	for item in applied.get("fonts", []):
		node.remove_theme_font_override(item)
	for path in applied.get("labels", []):
		var label := node.get_node_or_null(path) as Label
		if label:
			label.remove_theme_color_override("font_color")
			label.remove_theme_font_override("font")
			label.remove_theme_font_size_override("font_size")
	for key in ["wold_sound", "wold_press_effect"]:
		if applied.has(key):
			if applied[key] == null:
				node.remove_meta(key)
			else:
				node.set_meta(key, applied[key])
	node.remove_meta(APPLIED)


## Every customised control under `root` (itself included), re-applied.
static func apply_tree(root: Node) -> void:
	if root is Control and root.has_meta(META):
		apply(root)
	for child in root.get_children():
		apply_tree(child)


# Items the engine's own theme has for this kind of control, nearest class
# first (a CheckBox has its own list, a scripted button reports Button).
static func _items(node: Node, kind: Theme.DataType) -> PackedStringArray:
	var base := ThemeDB.get_default_theme()
	var cls := StringName(node.get_class())
	while cls != &"":
		var list := base.get_theme_item_list(kind, cls)
		if not list.is_empty():
			return list
		cls = ClassDB.get_parent_class(cls)
	return PackedStringArray()


static func _is_ink(item: String) -> bool:
	if not (item.begins_with("font_") or item.begins_with("icon_")) or not item.ends_with("color"):
		return false
	for skip in _INK_SKIP:
		if item.contains(skip):
			return false
	return true


static func _box(node: Control, item: String, c: WoldCustom) -> StyleBox:
	var focus := item.contains("focus")
	var shaped := c.corner_radius >= 0 or c.border_width >= 0 or (c.padding.x >= 0 or c.padding.y >= 0) and not focus
	var coloured := not focus and (c.fill.a > 0.0 or c.border.a > 0.0)
	if not shaped and not coloured:
		return null
	var base := Lookup.stylebox(node, item)
	var sb: StyleBoxFlat
	if base is StyleBoxFlat:
		sb = base.duplicate()
	elif (base == null or base is StyleBoxEmpty) and c.fill.a > 0.0 and not focus:
		# nothing drawn there by the theme, but they asked for a fill
		sb = WoldStyle.blendable(base if base else StyleBoxEmpty.new())
	else:
		return null
	if c.corner_radius >= 0:
		sb.set_corner_radius_all(c.corner_radius)
	if focus:
		return sb
	if c.border_width >= 0:
		sb.set_border_width_all(c.border_width)
	if c.border.a > 0.0:
		sb.border_color = c.border
		if c.border_width < 0 and sb.get_border_width_min() == 0 and not item.contains("disabled"):
			sb.set_border_width_all(1)
	if c.padding.x >= 0:
		sb.content_margin_left = c.padding.x
		sb.content_margin_right = c.padding.x
	if c.padding.y >= 0:
		sb.content_margin_top = c.padding.y
		sb.content_margin_bottom = c.padding.y
	if c.fill.a > 0.0:
		sb.bg_color = shade(c.fill, item)
		sb.draw_center = true
	return sb


## The fill for one state: hover a step off it, pressed two, disabled faded.
static func shade(fill: Color, item: String) -> Color:
	var step := 0.0
	if item.contains("disabled"):
		return Color(fill, fill.a * 0.45)
	if item.contains("hover") and item.contains("pressed"):
		step = 0.16
	elif item.contains("pressed") or item.contains("selected"):
		step = 0.16
	elif item.contains("hover"):
		step = 0.08
	if step == 0.0:
		return fill
	# away from white on light fills, towards it on dark ones
	return fill.darkened(step) if WoldColor.luminance(fill) > 0.5 else fill.lightened(step)


static func _feedback_meta(node: Node, c: WoldCustom, applied: Dictionary) -> void:
	if c.sound != WoldCustom.Sound.THEME:
		applied.wold_sound = node.get_meta("wold_sound") if node.has_meta("wold_sound") else null
		node.set_meta("wold_sound", _SOUNDS[c.sound])
	if c.press != WoldCustom.Press.THEME:
		applied.wold_press_effect = node.get_meta("wold_press_effect") if node.has_meta("wold_press_effect") else null
		if c.press == WoldCustom.Press.NONE or c.press_effect == null:
			node.set_meta("wold_press_effect", "none")
		else:
			node.set_meta("wold_press_effect", c.press_effect)
