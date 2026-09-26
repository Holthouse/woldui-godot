@tool
class_name WoldPromptGlyph
extends Control
## One drawn input glyph: keycap, round face button, pill or icon.
## Used by WoldButtonPrompt; style it via the PromptGlyph theme type.

var glyph: Dictionary = {shape = "key", text = "E", icon = "", art = ""}:
	set(v):
		glyph = v
		update_minimum_size()
		queue_redraw()
## Game-supplied texture. If set, drawn instead of the shape.
var art: Texture2D:
	set(v):
		art = v
		update_minimum_size()
		queue_redraw()


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _notification(what: int) -> void:
	if what == NOTIFICATION_THEME_CHANGED:
		update_minimum_size()
		queue_redraw()


func _height() -> float:
	return float(get_theme_constant("height", "PromptGlyph"))


func _get_minimum_size() -> Vector2:
	var h := _height()
	if art:
		return Vector2(h * art.get_width() / maxf(art.get_height(), 1.0), h)
	match glyph.shape:
		"face", "icon":
			return Vector2(h, h)
	var w := h
	if glyph.text != "":
		var font := get_theme_font("font", "PromptGlyph")
		var fs := get_theme_font_size("font_size", "PromptGlyph")
		w = maxf(h, font.get_string_size(glyph.text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x + h * 0.6)
	return Vector2(w, h)


func _draw() -> void:
	var r := Rect2(Vector2.ZERO, size)
	if art:
		draw_texture_rect(art, r, false)
		return
	var fill := get_theme_color("fill_color", "PromptGlyph")
	var edge := get_theme_color("border_color", "PromptGlyph")
	var ink := get_theme_color("font_color", "PromptGlyph")
	var sb := StyleBoxFlat.new()
	sb.bg_color = fill
	sb.border_color = edge
	sb.set_border_width_all(1)
	sb.anti_aliasing = true
	sb.corner_detail = 8
	match glyph.shape:
		"face", "pill":
			sb.set_corner_radius_all(int(size.y / 2.0))
		"icon":
			sb.draw_center = false
			sb.set_border_width_all(0)
		_:
			sb.set_corner_radius_all(get_theme_constant("radius", "PromptGlyph"))
			# thicker bottom edge reads as a keycap
			sb.border_width_bottom = 2
	draw_style_box(sb, r)
	if glyph.icon != "":
		var px := int(size.y * (0.9 if glyph.shape == "icon" else 0.58))
		var tex := WoldUIRuntime.instance().tokens.icon_set.get_icon(glyph.icon, px) if WoldUIRuntime.instance().tokens.icon_set else WoldIcons.texture(glyph.icon, px)
		if tex:
			var s := Vector2(px, px)
			draw_texture_rect(tex, Rect2((size - s) / 2.0, s), false, ink)
	elif glyph.text != "":
		var font := get_theme_font("font", "PromptGlyph")
		var fs := get_theme_font_size("font_size", "PromptGlyph")
		var baseline := (size.y + font.get_ascent(fs) - font.get_descent(fs)) / 2.0
		draw_string(font, Vector2(0, baseline), glyph.text, HORIZONTAL_ALIGNMENT_CENTER, size.x, fs, ink)
