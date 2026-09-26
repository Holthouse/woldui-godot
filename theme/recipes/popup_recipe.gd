@tool
extends RefCounted
## PopupMenu (option lists, context menus) and plain popups, plus WoldSelect.

const Toggle := preload("toggle_recipe.gd")

const STYLES: PackedStringArray = [
	"Select", "SelectSm", "SelectLg", "SelectValue", "SelectValueSm", "SelectValueLg",
	"SelectPlaceholder", "SelectPlaceholderSm", "SelectPlaceholderLg", "SelectPopup",
]


static func contribute(theme: Theme, t: WoldTokens) -> void:
	theme.set_stylebox("panel", "PopupMenu", WoldStyle.raised(t.role("surface_overlay"), t.radius_md, Vector2i(t.space_xs, t.space_xs), t, t.role("border")))
	theme.set_stylebox("hover", "PopupMenu", WoldStyle.flat(t.role("accent_soft"), t.radius_sm))
	theme.set_stylebox("separator", "PopupMenu", WoldStyle.line(t.role("border"), t.border_width))
	theme.set_color("font_color", "PopupMenu", t.role("text"))
	theme.set_color("font_hover_color", "PopupMenu", t.role("text"))
	theme.set_color("font_disabled_color", "PopupMenu", t.role("text_disabled"))
	theme.set_color("font_accelerator_color", "PopupMenu", t.role("text_muted"))
	theme.set_color("font_separator_color", "PopupMenu", t.role("text_muted"))
	theme.set_constant("v_separation", "PopupMenu", t.space_sm)
	theme.set_constant("h_separation", "PopupMenu", t.space_sm)
	theme.set_constant("item_start_padding", "PopupMenu", t.space_md)
	theme.set_constant("item_end_padding", "PopupMenu", t.space_md)
	theme.set_font_size("font_size", "PopupMenu", t.font_size(0))
	theme.set_stylebox("panel", "PopupPanel", WoldStyle.raised(t.role("surface_overlay"), t.radius_md, Vector2i(t.space_md, t.space_md), t, t.role("border")))
	_menu_icons(theme, t)
	_select(theme, t)


# PopupMenu draws these as they are (no tint), so they carry their colour
static func _menu_icons(theme: Theme, t: WoldTokens) -> void:
	var px := t.icon_size_sm
	var on := t.role("accent")
	var edge := t.role("field_border")
	var dim := t.role("text_disabled")
	var dim_fill := t.role("control_disabled")
	var bw := t.border_width
	theme.set_icon("unchecked", "PopupMenu", Toggle.box(px, t.radius_sm, t.role("field"), edge, bw))
	theme.set_icon("checked", "PopupMenu", Toggle.box(px, t.radius_sm, on, on, bw, Toggle.check_path(px), t.role("on_accent")))
	theme.set_icon("unchecked_disabled", "PopupMenu", Toggle.box(px, t.radius_sm, dim_fill, dim, bw))
	theme.set_icon("checked_disabled", "PopupMenu", Toggle.box(px, t.radius_sm, dim_fill, dim, bw, Toggle.check_path(px), dim))
	theme.set_icon("radio_unchecked", "PopupMenu", Toggle.dot(px, t.role("field"), edge, bw, 0.0, on))
	theme.set_icon("radio_checked", "PopupMenu", Toggle.dot(px, on, on, bw, 0.4, t.role("on_accent")))
	theme.set_icon("radio_unchecked_disabled", "PopupMenu", Toggle.dot(px, dim_fill, dim, bw, 0.0, dim))
	theme.set_icon("radio_checked_disabled", "PopupMenu", Toggle.dot(px, dim_fill, dim, bw, 0.4, dim))
	theme.set_icon("submenu", "PopupMenu", Toggle.mark(px, Toggle.chevron_path(px, true), t.role("text_muted")))
	# mirrored = pointing left
	var left := Toggle.mark(px, Toggle.chevron_path(px, true), t.role("text_muted"))
	var img := left.get_image()
	img.flip_x()
	theme.set_icon("submenu_mirrored", "PopupMenu", ImageTexture.create_from_image(img))


# WoldSelect: the trigger looks like a field, the list marks the current
# option with a plain check instead of a radio dot
static func _select(theme: Theme, t: WoldTokens) -> void:
	for size in ["", "Sm", "Lg"]:
		var style: String = "Select" + size
		theme.set_type_variation(style, "Button" if size == "" else "Select")
		var dims := t.control_size(size)
		var pad: Vector2i = dims.padding
		pad.x = maxi(pad.x - 6, t.space_sm)
		var r: int = dims.radius
		var bw := t.border_width
		theme.set_stylebox("normal", style, WoldStyle.flat(t.role("field"), r, pad, t.role("field_border"), bw))
		theme.set_stylebox("hover", style, WoldStyle.flat(t.role("field").lerp(t.role("control_hover"), 0.5), r, pad, t.role("field_border"), bw))
		theme.set_stylebox("pressed", style, WoldStyle.flat(t.role("field"), r, pad, t.role("focus"), bw))
		theme.set_stylebox("hover_pressed", style, WoldStyle.flat(t.role("field"), r, pad, t.role("focus"), bw))
		theme.set_stylebox("disabled", style, WoldStyle.flat(t.role("control_disabled"), r, pad, t.role("control_disabled"), bw))
		theme.set_stylebox("focus", style, WoldStyle.ring(t, r))
		theme.set_font_size("font_size", style, dims.font)
		theme.set_constant("icon_size", style, dims.icon)
		theme.set_constant("h_separation", style, t.space_sm)
		theme.set_color("icon_color", style, t.role("text_muted"))
		theme.set_color("icon_disabled_color", style, t.role("text_disabled"))
		# the value is a Label inside the button, so it needs its own size step
		var value: String = "SelectValue" + size
		theme.set_type_variation(value, "Label")
		theme.set_font_size("font_size", value, dims.font)
		theme.set_color("font_color", value, t.role("text"))
		var hint: String = "SelectPlaceholder" + size
		theme.set_type_variation(hint, value)
		theme.set_color("font_color", hint, t.role("text_muted"))
	theme.set_type_variation("SelectPopup", "PopupMenu")
	var px := t.icon_size_sm
	theme.set_icon("radio_checked", "SelectPopup", Toggle.mark(px, Toggle.check_path(px), t.role("accent_text")))
	theme.set_icon("radio_unchecked", "SelectPopup", Toggle.blank(px))
	theme.set_icon("radio_checked_disabled", "SelectPopup", Toggle.mark(px, Toggle.check_path(px), t.role("text_disabled")))
	theme.set_icon("radio_unchecked_disabled", "SelectPopup", Toggle.blank(px))
