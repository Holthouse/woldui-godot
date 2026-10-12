@tool
class_name WoldRadialMenu
extends Control
## A ring of choices round a centre, the way console strategy games do
## commands: point the stick at a slice, press to pick it. The mouse works too
## (hover a slice, click it). The menu only draws and picks; your game decides
## which stick and which buttons drive it (aim(), step(), choose()).
## Each item is a Dictionary: {label, icon (Texture2D), disabled, hint}. The
## first slice sits at the top and they go round clockwise.

signal chosen(index: int)
signal highlight_changed(index: int)

@export var items: Array = []:
	set(v):
		items = v
		highlighted = -1
		queue_redraw()
## Outer edge of the ring, from the centre.
@export var radius := 170.0:
	set(v):
		radius = v
		update_minimum_size()
		queue_redraw()
## Where the slices start; the centre disc fills the inside.
@export var inner_radius := 72.0:
	set(v):
		inner_radius = v
		queue_redraw()
## Words in the centre (what the choices are for).
@export var center_title := "":
	set(v):
		center_title = v
		queue_redraw()
@export var center_icon: Texture2D:
	set(v):
		center_icon = v
		queue_redraw()
## How far the stick has to lean before it picks a slice.
@export var aim_deadzone := 0.5

var highlighted := -1:
	set(v):
		var clamped := v if v >= 0 and v < items.size() else -1
		if clamped == highlighted:
			return
		highlighted = clamped
		highlight_changed.emit(highlighted)
		queue_redraw()

const _GAP := 0.03  # radians between slices
const _ARC_STEPS := 12


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	focus_mode = Control.FOCUS_NONE


func _get_minimum_size() -> Vector2:
	return Vector2.ONE * radius * 2.0


func slice_angle() -> float:
	return TAU / maxf(1.0, float(items.size()))


## The slice a direction points at (screen space: up is (0, -1)).
func index_at(dir: Vector2) -> int:
	if items.is_empty() or dir == Vector2.ZERO:
		return -1
	# slice 0 is centred straight up, then clockwise
	var a := fposmod(dir.angle() + PI / 2.0 + slice_angle() / 2.0, TAU)
	return clampi(int(a / slice_angle()), 0, items.size() - 1)


## Point at a slice with a stick; a resting stick keeps what was picked.
func aim(dir: Vector2) -> void:
	if dir.length() < aim_deadzone:
		return
	highlighted = index_at(dir)


## Next or previous slice (the d-pad, a key), wrapping round.
func step(by: int) -> void:
	if items.is_empty():
		return
	if highlighted < 0:
		highlighted = 0 if by > 0 else items.size() - 1
		return
	highlighted = posmod(highlighted + by, items.size())


func is_enabled(index: int) -> bool:
	return index >= 0 and index < items.size() and not bool(items[index].get("disabled", false))


## Pick the highlighted slice. False if there's none or it's disabled.
func choose() -> bool:
	if not is_enabled(highlighted):
		return false
	chosen.emit(highlighted)
	return true


func _gui_input(event: InputEvent) -> void:
	var centre := size / 2.0
	if event is InputEventMouseMotion:
		var off: Vector2 = (event as InputEventMouseMotion).position - centre
		highlighted = index_at(off) if off.length() >= inner_radius * 0.6 else -1
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if choose():
			accept_event()


func _draw() -> void:
	var tokens := WoldUIRuntime.instance().tokens
	var centre := size / 2.0
	var count := items.size()
	var font := get_theme_font("font", "Label")
	var font_size := get_theme_font_size("font_size", "Label")
	for i in count:
		var mid := -PI / 2.0 + slice_angle() * i
		var a0 := mid - slice_angle() / 2.0 + _GAP
		var a1 := mid + slice_angle() / 2.0 - _GAP
		var points := PackedVector2Array()
		for s in _ARC_STEPS + 1:
			var a := lerpf(a0, a1, float(s) / _ARC_STEPS)
			points.append(centre + Vector2.from_angle(a) * radius)
		for s in range(_ARC_STEPS, -1, -1):
			var a := lerpf(a0, a1, float(s) / _ARC_STEPS)
			points.append(centre + Vector2.from_angle(a) * inner_radius)
		var on := i == highlighted
		var fill: Color = tokens.role("accent") if on else tokens.role("surface_overlay")
		if not is_enabled(i):
			fill = tokens.role("control_disabled") if not on else tokens.role("control_pressed")
		draw_colored_polygon(points, fill)
		var ink: Color = tokens.role("on_accent") if on and is_enabled(i) \
				else (tokens.role("text_disabled") if not is_enabled(i) else tokens.role("text"))
		var at := centre + Vector2.from_angle(mid) * (inner_radius + radius) / 2.0
		var icon: Texture2D = items[i].get("icon", null)
		if icon != null:
			var s := Vector2(icon.get_size()).clamp(Vector2.ZERO, Vector2.ONE * 36.0)
			draw_texture_rect(icon, Rect2(at - s / 2.0, s), false, ink)
		elif font != null:
			var label := String(items[i].get("label", ""))
			var w := font.get_string_size(label, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size).x
			draw_string(font, at + Vector2(-w / 2.0, font_size / 3.0), label, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size, ink)
	# the centre: what this is all for, and the highlighted slice's name under it
	draw_circle(centre, inner_radius - 4.0, tokens.role("surface_raised"))
	if center_icon != null:
		var cs := Vector2.ONE * minf(48.0, inner_radius)
		draw_texture_rect(center_icon, Rect2(centre - cs / 2.0 - Vector2(0, 10), cs), false)
	if font != null:
		var title := center_title
		if highlighted >= 0:
			title = String(items[highlighted].get("label", ""))
		draw_string(font, centre + Vector2(-inner_radius * 0.9, inner_radius * 0.55), title,
				HORIZONTAL_ALIGNMENT_CENTER, inner_radius * 1.8, font_size, tokens.role("text"))
