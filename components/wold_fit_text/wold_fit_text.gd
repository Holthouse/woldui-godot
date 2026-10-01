class_name WoldFitText
extends Node
## Shrinks the text of the Button or Label it sits under until it fits the width
## the layout gave it. Past min_scale it truncates with an ellipsis and puts the
## full text in the tooltip.
## Only for controls whose width comes from the layout (a grid cell, a fixed
## column, an expanding row). The text stops setting the control's minimum width,
## so in a container that sizes to its children the control would collapse.
# Hooks the target's draw and resized signals: a text, size or translation change
# redraws it, which is when the fit has to run. The override is only touched when
# the size really changes, otherwise this would redraw forever. Changing the
# override can resize the control and fire resized on the spot, so every change
# of ours is behind the _busy flag.

## Smallest size, as a fraction of the theme's font size.
@export_range(0.4, 1.0, 0.05) var min_scale := 0.75:
	set(v):
		min_scale = v
		refit()
@export var enabled := true:
	set(v):
		enabled = v
		refit()

var _target: Control
var _base := 0
var _base_variation := &""
var _was_clipping := false
var _tooltip_set := false
var _hooked := false
var _busy := false
var _queued := false


func _ready() -> void:
	_target = get_parent() as Control
	if not (_target is Button or _target is Label):
		push_warning("WoldFitText needs a Button or a Label as its parent")
		_target = null
		return
	if _target is Button:
		_was_clipping = (_target as Button).clip_text
	_hook(true)
	refit()


func _exit_tree() -> void:
	if not is_instance_valid(_target):
		return
	_hook(false)
	# a target that is going away needs no cleanup, and restyling it now can
	# queue a refresh on a node that is being freed
	if not _target.is_queued_for_deletion():
		_restore()


## Run the fit now. Call after changing the theme variation by hand.
func refit() -> void:
	_base = 0
	if _target and is_inside_tree():
		_schedule()


## Font size the target is drawn at right now.
func current_size() -> int:
	if _target == null:
		return 0
	return _target.get_theme_font_size("font_size")


func _hook(on: bool) -> void:
	if on == _hooked:
		return
	_hooked = on
	if on:
		_target.draw.connect(_schedule)
		_target.resized.connect(_schedule)
	else:
		_target.draw.disconnect(_schedule)
		_target.resized.disconnect(_schedule)


# draw and resized come in the middle of the control's own update, so the fit
# waits for the end of the frame
func _schedule() -> void:
	if _queued or _busy:
		return
	_queued = true
	_fit.call_deferred()


func _fit() -> void:
	_queued = false
	if _busy or _target == null or not is_instance_valid(_target) or not is_inside_tree():
		return
	_busy = true
	if not enabled:
		_restore()
	elif not (_target is Label and (_target as Label).autowrap_mode != TextServer.AUTOWRAP_OFF):
		_prepare()
		var avail := _available_width()
		if avail > 0.0:
			_apply(avail)
	_busy = false


func _prepare() -> void:
	# the text must not set the minimum width, or there is nothing to fit into
	if _target is Button:
		(_target as Button).clip_text = true
	else:
		(_target as Label).text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		(_target as Label).clip_text = true
	if _base == 0 or _base_variation != _target.theme_type_variation:
		_base_variation = _target.theme_type_variation
		if _target.has_theme_font_size_override("font_size"):
			_target.remove_theme_font_size_override("font_size")
		_base = _target.get_theme_font_size("font_size")


func _available_width() -> float:
	var w := _target.size.x
	if _target is Button:
		var b := _target as Button
		w -= b.get_theme_stylebox("normal").get_minimum_size().x
		if b.icon:
			w -= b.icon.get_width() + b.get_theme_constant("h_separation")
	return w


func _width_at(px: int) -> float:
	var font := _target.get_theme_font("font")
	return font.get_string_size(_target.text, HORIZONTAL_ALIGNMENT_LEFT, -1, px).x


func _apply(avail: float) -> void:
	var px := _base
	var natural := _width_at(_base)
	var floor_px := maxi(1, ceili(_base * min_scale))
	if natural > avail:
		px = clampi(floori(_base * avail / natural), floor_px, _base)
	var truncated := _width_at(px) > avail + 0.5
	if px == _base:
		if _target.has_theme_font_size_override("font_size"):
			_target.remove_theme_font_size_override("font_size")
	elif _target.get_theme_font_size("font_size") != px:
		_target.add_theme_font_size_override("font_size", px)
	_set_tooltip(truncated)


# only a tooltip we put there ourselves is ours to take away
func _set_tooltip(truncated: bool) -> void:
	if truncated:
		if _target.tooltip_text == "":
			_target.tooltip_text = _target.text
			_tooltip_set = true
	elif _tooltip_set:
		_target.tooltip_text = ""
		_tooltip_set = false


func _restore() -> void:
	if _target.has_theme_font_size_override("font_size"):
		_target.remove_theme_font_size_override("font_size")
	if _target is Button:
		(_target as Button).clip_text = _was_clipping
	_set_tooltip(false)
