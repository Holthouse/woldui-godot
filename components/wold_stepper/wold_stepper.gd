@tool
class_name WoldStepper
extends Button
## The console-style "< Normal >" setting. Left / right (keys, d-pad, or the
## arrows) step through `options`, or through numbers when there are none.
## The whole row takes focus as one, so up / down still move between rows.
## Accept steps forward; a click or tap steps towards whichever side of the
## value it lands on, so the whole row is the target, not just the arrows.

signal value_changed(value: float)

const Content := preload("../shared/wold_button_content.gd")

## Row caption on the left. Empty = just the selector.
@export var label := "":
	set(v):
		label = v
		_refresh()
## Named steps. Empty = numbers from min_value to max_value.
@export var options: PackedStringArray = []:
	set(v):
		options = v
		value = value
		_refresh()
## With options, the index.
@export var value := 0.0:
	set(v):
		var clamped := _clamp(v)
		var changed := not is_equal_approx(clamped, value)
		value = clamped
		_refresh()
		if changed and is_node_ready():
			value_changed.emit(value)
@export_group("Numbers")
@export var min_value := 0.0:
	set(v):
		min_value = v
		value = value
@export var max_value := 10.0:
	set(v):
		max_value = v
		value = value
@export var step := 1.0
## Takes the number: "%d", "%d%%", "x%.1f".
@export var format := "%d":
	set(v):
		format = v
		_refresh()
@export_group("")
## Past the last step, back to the first (and the other way).
@warning_ignore("shadowed_global_identifier")
@export var wrap := false:
	set(v):
		wrap = v
		_refresh()

var _refreshing := false
# where the last click / tap went down, x in our space; -1 = keys or pad
var _press_x := -1.0


func _ready() -> void:
	theme_type_variation = &"Stepper"
	text = ""
	%Prev.pressed.connect(step_by.bind(-1))
	%Next.pressed.connect(step_by.bind(1))
	pressed.connect(_on_pressed)
	%Content.minimum_size_changed.connect(_fit)
	_refresh()


func _notification(what: int) -> void:
	if what == NOTIFICATION_THEME_CHANGED:
		_fit.call_deferred()


## Subclass hook, before each restyle.
func _wold_refresh() -> void:
	pass


## What the selector shows right now.
func value_text() -> String:
	if not options.is_empty():
		return options[int(value)]
	return _format(value)


## One step left (-1) or right (1). Returns false at an end without wrap.
func step_by(direction: int) -> bool:
	if disabled:
		return false
	var lo := _lo()
	var hi := _hi()
	var s := _step()
	var next := value + s * direction
	if next > hi + 0.0001 or next < lo - 0.0001:
		if not wrap:
			if is_inside_tree():
				WoldMotion.shake(%Value, 4.0)
			return false
		next = lo if direction > 0 else hi
	value = next
	if is_inside_tree() and not Engine.is_editor_hint():
		WoldMotion.nudge(%Value, Vector2(10.0 * direction, 0))
	return true


func _gui_input(event: InputEvent) -> void:
	var mb := event as InputEventMouseButton
	if mb and mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
		_press_x = mb.position.x
	if event.is_action_pressed(&"ui_left", true):
		step_by(-1)
		accept_event()
	elif event.is_action_pressed(&"ui_right", true):
		step_by(1)
		accept_event()


func _on_pressed() -> void:
	if _press_x >= 0.0:
		var value_mid := (%Value as Control).get_global_rect().get_center().x - global_position.x
		var dir := -1 if _press_x < value_mid else 1
		_press_x = -1.0
		step_by(dir)
		return
	# accept: forward, and round again at the end even without wrap
	if not step_by(1) and not wrap and value >= _hi() - 0.0001:
		value = _lo()


func _lo() -> float:
	return 0.0 if not options.is_empty() else min_value


func _hi() -> float:
	return float(options.size() - 1) if not options.is_empty() else max_value


func _step() -> float:
	return 1.0 if not options.is_empty() else maxf(step, 0.0001)


func _clamp(v: float) -> float:
	if not options.is_empty():
		return float(clampi(roundi(v), 0, options.size() - 1))
	return clampf(v, min_value, max_value)


func _format(v: float) -> String:
	if format.contains("%d"):
		return format % roundi(v)
	return format % v


func _refresh() -> void:
	if _refreshing or not is_node_ready():
		return
	_refreshing = true
	_wold_refresh()
	var t := WoldUIRuntime.instance().tokens
	(%Label as Label).text = label
	%Label.visible = label != ""
	(%Value as Label).text = value_text()
	var at_start := value <= _lo() + 0.0001
	var at_end := value >= _hi() - 0.0001
	(%Prev as Button).icon = t.icon("chevron-left", "Sm")
	(%Next as Button).icon = t.icon("chevron-right", "Sm")
	(%Prev as Button).disabled = disabled or (at_start and not wrap)
	(%Next as Button).disabled = disabled or (at_end and not wrap)
	_refreshing = false
	_fit()


# the value box is as wide as its widest step, so the arrows never move
func _fit() -> void:
	if not is_node_ready():
		return
	var v := %Value as Label
	var font := v.get_theme_font("font")
	var px := v.get_theme_font_size("font_size")
	var texts: Array = Array(options) if not options.is_empty() else [_format(min_value), _format(max_value)]
	var widest := 0.0
	for s in texts:
		widest = maxf(widest, font.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, px).x)
	v.custom_minimum_size.x = ceilf(widest)
	Content.fit(self, %Content)


func _draw() -> void:
	# disabled has no signal, but it redraws
	Content.dim(self, %Label, &"ToggleLabel")
	Content.dim(self, %Value, &"StepperValue")
	var off := disabled or (value <= _lo() + 0.0001 and not wrap)
	if (%Prev as Button).disabled != off or (%Next as Button).disabled != (disabled or (value >= _hi() - 0.0001 and not wrap)):
		_refresh.call_deferred()


func _validate_property(property: Dictionary) -> void:
	if property.name in ["custom_minimum_size", "theme_type_variation", "text"]:
		property.usage &= ~PROPERTY_USAGE_STORAGE
