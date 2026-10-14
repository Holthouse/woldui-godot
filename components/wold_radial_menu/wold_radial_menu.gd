@tool
class_name WoldRadialMenu
extends Control
## A ring of choices round a centre, the way console strategy games do
## commands: point the stick at a choice, press to pick it. The mouse works too
## (hover a choice, click it). The menu only draws and picks; your game decides
## which stick and which buttons drive it (aim(), step(), choose()).
##
## Each choice is a round medallion on a dark band. The one you point at grows
## and lights up, and the centre says what it is: its label, a row of details
## (a cost, say) and a line of hint. Each item is a Dictionary:
##   {label, icon (Texture2D), disabled, hint, details, count}
## `details` is a list of {icon (Texture2D), text}; `count` puts a small number
## on the medallion (how many choices a group opens). The first item sits at
## the top and they go round clockwise.

signal chosen(index: int)
signal highlight_changed(index: int)

@export var items: Array = []:
	set(v):
		items = v
		_pops.resize(items.size())
		_pops.fill(0.0)
		highlighted = -1
		_refresh_centre()
		queue_redraw()
## Outer edge of the ring, from its centre.
@export var radius := 170.0:
	set(v):
		radius = v
		update_minimum_size()
		_layout()
		queue_redraw()
## The centre disc, where the pointed-at choice is described.
@export var inner_radius := 84.0:
	set(v):
		inner_radius = v
		_layout()
		queue_redraw()
## The size of each medallion on the ring.
@export var item_radius := 28.0:
	set(v):
		item_radius = v
		queue_redraw()
## Words in the centre while nothing is pointed at (what the choices are for).
@export var center_title := "":
	set(v):
		center_title = v
		_refresh_centre()
@export var center_icon: Texture2D:
	set(v):
		center_icon = v
		queue_redraw()
## A plaque under the ring naming the menu ("Worker", "Site Commands").
@export var caption := "":
	set(v):
		caption = v
		_refresh_caption()
## The action that picks, shown as its button glyph beside the pointed-at
## choice ("ui_accept", or your own). Empty shows none. Hidden on the mouse.
@export var choose_action: StringName = &"":
	set(v):
		choose_action = v
		if _prompt:
			_prompt.action = v
		_place_prompt()
## How far the stick has to lean before it picks a choice.
@export var aim_deadzone := 0.5

var highlighted := -1:
	set(v):
		var clamped := v if v >= 0 and v < items.size() else -1
		if clamped == highlighted:
			return
		highlighted = clamped
		highlight_changed.emit(highlighted)
		_refresh_centre()
		_place_prompt()
		set_process(true)
		queue_redraw()

const _BAND_PAD := 9.0       # band beyond the medallions
const _POP := 0.22           # how much the pointed-at medallion grows
const _CAPTION_GAP := 10.0

# 0..1 per item: how far it has grown toward "pointed at"
var _pops: Array[float] = []
var _centre: VBoxContainer
var _title: Label
var _details: HBoxContainer
var _hint: Label
var _caption_panel: PanelContainer
var _caption_label: Label
var _prompt: Control


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	focus_mode = Control.FOCUS_NONE
	# Internal children: built here, never saved into a scene
	_centre = VBoxContainer.new()
	_centre.theme_type_variation = &"StackXs"
	_centre.alignment = BoxContainer.ALIGNMENT_CENTER
	_centre.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_centre, false, Node.INTERNAL_MODE_FRONT)
	_title = Label.new()
	_title.theme_type_variation = &"Subheading"
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_title.max_lines_visible = 2
	_centre.add_child(_title)
	_details = HBoxContainer.new()
	_details.theme_type_variation = &"RowSm"
	_details.alignment = BoxContainer.ALIGNMENT_CENTER
	_details.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_centre.add_child(_details)
	_hint = Label.new()
	_hint.theme_type_variation = &"Muted"
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_hint.max_lines_visible = 4
	_hint.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_centre.add_child(_hint)
	_caption_panel = PanelContainer.new()
	_caption_panel.theme_type_variation = &"PanelRaised"
	_caption_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_caption_panel, false, Node.INTERNAL_MODE_FRONT)
	_caption_label = Label.new()
	_caption_label.theme_type_variation = &"Subheading"
	_caption_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_caption_panel.add_child(_caption_label)
	set_process(false)


func _ready() -> void:
	_prompt = load("res://addons/woldui/components/wold_button_prompt/wold_button_prompt.tscn").instantiate()
	_prompt.label = ""
	_prompt.action = choose_action
	_prompt.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_prompt, false, Node.INTERNAL_MODE_BACK)
	_prompt.resized.connect(_place_prompt)
	_caption_panel.resized.connect(_layout)
	_centre.minimum_size_changed.connect(_layout)
	var ui := WoldUIRuntime.instance()
	if not ui.input_mode_changed.is_connected(_on_mode):
		ui.input_mode_changed.connect(_on_mode)
	_refresh_centre()
	_refresh_caption()
	_layout()


func _exit_tree() -> void:
	var ui := WoldUIRuntime.instance()
	if ui.input_mode_changed.is_connected(_on_mode):
		ui.input_mode_changed.disconnect(_on_mode)


func _on_mode(_mode: int) -> void:
	_place_prompt.call_deferred()


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_layout()


func _get_minimum_size() -> Vector2:
	var below := 0.0
	if caption != "" and _caption_panel:
		below = _CAPTION_GAP + _caption_panel.get_combined_minimum_size().y
	return Vector2(radius * 2.0, radius * 2.0 + below)


## The ring's centre, in this control's space.
func ring_center() -> Vector2:
	return Vector2(size.x / 2.0, radius)


## Where the medallions sit, from the centre.
func ring_radius() -> float:
	return radius - item_radius * (1.0 + _POP) - _BAND_PAD


func slice_angle() -> float:
	return TAU / maxf(1.0, float(items.size()))


## The centre of item `index`'s medallion.
func item_position(index: int) -> Vector2:
	return ring_center() + Vector2.from_angle(-PI / 2.0 + slice_angle() * index) * ring_radius()


## The choice a direction points at (screen space: up is (0, -1)).
func index_at(dir: Vector2) -> int:
	if items.is_empty() or dir == Vector2.ZERO:
		return -1
	# item 0 is centred straight up, then clockwise
	var a := fposmod(dir.angle() + PI / 2.0 + slice_angle() / 2.0, TAU)
	return clampi(int(a / slice_angle()), 0, items.size() - 1)


## Point at a choice with a stick; a resting stick keeps what was picked.
func aim(dir: Vector2) -> void:
	if dir.length() < aim_deadzone:
		return
	highlighted = index_at(dir)


## Next or previous choice (the d-pad, a key), wrapping round.
func step(by: int) -> void:
	if items.is_empty():
		return
	if highlighted < 0:
		highlighted = 0 if by > 0 else items.size() - 1
		return
	highlighted = posmod(highlighted + by, items.size())


func is_enabled(index: int) -> bool:
	return index >= 0 and index < items.size() and not bool(items[index].get("disabled", false))


## Pick the highlighted choice. False if there's none or it's disabled.
func choose() -> bool:
	if not is_enabled(highlighted):
		return false
	chosen.emit(highlighted)
	return true


## What the centre says now: the pointed-at choice's words, or the menu's own.
func center_text() -> Dictionary:
	return {"title": _title.text, "hint": _hint.text, "details": _details.get_child_count()}


## The glyph beside the pointed-at choice, or null (for tests).
func choose_prompt() -> Control:
	return _prompt


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		var off: Vector2 = (event as InputEventMouseMotion).position - ring_center()
		var inside := off.length() >= inner_radius and off.length() <= radius
		highlighted = index_at(off) if inside else -1
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if choose():
			accept_event()


func _process(delta: float) -> void:
	var speed := 1.0 / maxf(0.01, WoldUIRuntime.instance().tokens.duration_fast)
	var moving := false
	for i in _pops.size():
		var want := 1.0 if i == highlighted else 0.0
		if WoldMotion.reduced():
			_pops[i] = want
		elif not is_equal_approx(_pops[i], want):
			_pops[i] = move_toward(_pops[i], want, delta * speed)
			moving = true
	queue_redraw()
	_place_prompt()
	if not moving:
		set_process(false)


func _draw() -> void:
	var tokens := WoldUIRuntime.instance().tokens
	var c := ring_center()
	var ring := ring_radius()
	var band := item_radius * (1.0 + _POP) * 2.0 + _BAND_PAD * 2.0
	# the band the medallions sit on, one solid disc under the centre's, with a
	# fine edge each side (a thick draw_arc lets the board show through)
	var outer := ring + band / 2.0
	draw_circle(c, outer, tokens.role("surface_overlay"))
	var edge := Color(tokens.role("accent"), 0.45)
	draw_arc(c, outer, 0.0, TAU, 96, edge, 1.5, true)
	draw_arc(c, ring - band / 2.0, 0.0, TAU, 96, Color(edge, 0.25), 1.0, true)
	# the band lights up behind the pointed-at choice, about a medallion wide
	if highlighted >= 0 and items.size() > 1:
		var mid := -PI / 2.0 + slice_angle() * highlighted
		var half := minf(slice_angle() / 2.0, item_radius * 1.9 / ring)
		draw_colored_polygon(_sector(c, ring - band / 2.0, outer, mid - half, mid + half),
			Color(tokens.role("accent"), 0.16))
	# the centre disc
	draw_circle(c, inner_radius, tokens.role("surface_raised"))
	draw_arc(c, inner_radius, 0.0, TAU, 96, edge, 2.0, true)
	if center_icon != null and highlighted < 0:
		var cs := Vector2.ONE * minf(40.0, inner_radius * 0.5)
		draw_texture_rect(center_icon, Rect2(c - Vector2(cs.x / 2.0, inner_radius * 0.62), cs), false, tokens.role("text_muted"))
	var font := get_theme_font("font", "Label")
	for i in items.size():
		_draw_medallion(i, tokens, font)


func _draw_medallion(i: int, tokens: WoldTokens, font: Font) -> void:
	var p: float = _pops[i] if i < _pops.size() else 0.0
	var at := item_position(i)
	var r := item_radius * (1.0 + _POP * p)
	var enabled := is_enabled(i)
	if p > 0.0:
		draw_circle(at, r + 7.0 * p, Color(tokens.role("accent"), 0.28 * p))
	draw_circle(at, r, tokens.role("surface_raised") if enabled else tokens.role("surface_sunken"))
	var rim: Color = tokens.role("border_strong").lerp(tokens.role("accent"), p)
	draw_arc(at, r, 0.0, TAU, 48, rim, 2.0 + 1.5 * p, true)
	var ink: Color = tokens.role("text") if enabled else tokens.role("text_disabled")
	var icon: Texture2D = items[i].get("icon", null)
	if icon != null:
		var s := Vector2.ONE * r * 1.05
		draw_texture_rect(icon, Rect2(at - s / 2.0, s), false, ink)
	elif font != null:
		var label := String(items[i].get("label", "")).left(2)
		var fs := get_theme_font_size("font_size", "Label")
		var w := font.get_string_size(label, HORIZONTAL_ALIGNMENT_CENTER, -1, fs).x
		draw_string(font, at + Vector2(-w / 2.0, fs / 3.0), label, HORIZONTAL_ALIGNMENT_CENTER, -1, fs, ink)
	var n := int(items[i].get("count", 0))
	if n > 0 and font != null:
		var badge_at := at + Vector2(r * 0.74, -r * 0.74)
		var br := maxf(10.0, r * 0.4)
		draw_circle(badge_at, br, tokens.role("accent") if enabled else tokens.role("control_disabled"))
		var fs := int(br * 1.25)
		var text := str(n)
		var w := font.get_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1, fs).x
		draw_string(font, badge_at + Vector2(-w / 2.0, fs * 0.36), text, HORIZONTAL_ALIGNMENT_CENTER, -1, fs,
			tokens.role("on_accent") if enabled else tokens.role("text_disabled"))


# A piece of ring between two radii and two angles, as a polygon
func _sector(c: Vector2, r0: float, r1: float, a0: float, a1: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	for s in 13:
		points.append(c + Vector2.from_angle(lerpf(a0, a1, s / 12.0)) * r1)
	for s in range(12, -1, -1):
		points.append(c + Vector2.from_angle(lerpf(a0, a1, s / 12.0)) * r0)
	return points


# The centre's words: the pointed-at choice, or the menu's own title
func _refresh_centre() -> void:
	if not _title:
		return
	for child in _details.get_children():
		_details.remove_child(child)
		child.queue_free()
	if highlighted < 0 or highlighted >= items.size():
		_title.text = center_title
		_hint.text = ""
		_details.visible = false
		_hint.visible = false
		return
	var item: Dictionary = items[highlighted]
	_title.text = String(item.get("label", ""))
	_hint.text = String(item.get("hint", ""))
	_hint.visible = _hint.text != ""
	var details: Array = item.get("details", [])
	_details.visible = not details.is_empty()
	for d in details:
		var part := HBoxContainer.new()
		part.theme_type_variation = &"RowXs"
		part.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var tex: Texture2D = d.get("icon", null)
		if tex != null:
			var pic := TextureRect.new()
			pic.texture = tex
			pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			pic.custom_minimum_size = Vector2.ONE * 18.0
			pic.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			pic.self_modulate = WoldUIRuntime.instance().tokens.role("text_muted")
			part.add_child(pic)
		var words := Label.new()
		words.text = String(d.get("text", ""))
		part.add_child(words)
		_details.add_child(part)


func _refresh_caption() -> void:
	if not _caption_panel:
		return
	_caption_label.text = caption
	_caption_panel.visible = caption != ""
	update_minimum_size()
	_layout()


func _layout() -> void:
	if not _centre:
		return
	var c := ring_center()
	# the words fit the square inside the centre disc, centred on it however
	# many lines they take (the title at most two, the hint four)
	var side := inner_radius * 1.45
	_centre.custom_minimum_size = Vector2(side, 0.0)
	_centre.size = Vector2(side, 0.0)
	var tall := _centre.get_combined_minimum_size().y
	_centre.size = Vector2(side, tall)
	_centre.position = c - Vector2(side, tall) / 2.0
	if _caption_panel.visible:
		var want := _caption_panel.get_combined_minimum_size()
		_caption_panel.size = want
		_caption_panel.position = Vector2(c.x - want.x / 2.0, c.y + radius + _CAPTION_GAP)
	_place_prompt()


# The pick button's glyph sits just outside the pointed-at medallion, on the
# pad and keyboard; a pointer clicks the medallion itself
func _place_prompt() -> void:
	if not _prompt:
		return
	var mode := WoldUIRuntime.instance().input_mode
	var wanted := choose_action != &"" and is_enabled(highlighted) \
			and mode not in [WoldUIRuntime.InputMode.MOUSE, WoldUIRuntime.InputMode.TOUCH]
	_prompt.visible = wanted
	if not wanted:
		return
	var p: float = _pops[highlighted] if highlighted < _pops.size() else 1.0
	var dir := Vector2.from_angle(-PI / 2.0 + slice_angle() * highlighted)
	var r := item_radius * (1.0 + _POP * p)
	var want := _prompt.get_combined_minimum_size()
	_prompt.size = want
	var at := item_position(highlighted) + Vector2(r * 0.7, r * 0.7)
	if dir.x < -0.3:
		at = item_position(highlighted) + Vector2(-r * 0.7 - want.x, r * 0.7)
	_prompt.position = at - Vector2(0.0, want.y / 2.0)
