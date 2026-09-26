@tool
class_name WoldCollapsible
extends VBoxContainer
## A row that opens to show more. Put the hidden part in the %Content slot.
## The height slides open (reduced motion: it just opens), and closed content
## is hidden for real so Tab / the d-pad can't wander into it.
# Height is layout, not a transform: the clip's minimum height is what
# animates, so the container around it follows along.

signal toggled(open: bool)

@export var title := "Details":
	set(v):
		title = v
		_refresh()
## Leading icon by name.
@export var icon := "":
	set(v):
		icon = v
		_refresh()
@export var open := false:
	set(v):
		var changed := v != open
		open = v
		_refresh()
		_apply(changed)
		if changed and is_node_ready():
			toggled.emit(open)

var _anim := Node.new()
# 0 shut, 1 open. What animates; the pixel height follows the content live,
# so wrapped text that settles mid-slide doesn't throw it off
var _frac := 0.0
var _refreshing := false


func _ready() -> void:
	if _anim.get_parent() == null:
		add_child(_anim, false, Node.INTERNAL_MODE_FRONT)
	%Trigger.pressed.connect(func(): self.open = not open)
	%Body.minimum_size_changed.connect(_sync)
	_refresh()
	_apply(false)


## Subclass hook, before each restyle.
func _wold_refresh() -> void:
	pass


## Full height of the open part.
func body_height() -> float:
	return %Body.get_combined_minimum_size().y


## How far open it is right now, in pixels.
func shown_height() -> float:
	return (%Clip as Control).custom_minimum_size.y


## Inside a WoldAccordion: flush rows with a line under each.
func is_divided() -> bool:
	return get_parent() is WoldAccordion


func trigger() -> WoldButton:
	return %Trigger


func _refresh() -> void:
	if _refreshing or not is_node_ready():
		return
	_refreshing = true
	_wold_refresh()
	var b := %Trigger as WoldButton
	b.text = title
	b.icon_start = icon
	b.icon_end = "chevron-up" if open else "chevron-down"
	b.variant = "AccordionTrigger" if is_divided() else "CollapsibleTrigger"
	_refreshing = false
	queue_redraw()


func _apply(animate: bool) -> void:
	if not is_node_ready():
		return
	var target := 1.0 if open else 0.0
	if not animate or not is_inside_tree() or Engine.is_editor_hint():
		_frac = target
		_sync()
		return
	var t := WoldUIRuntime.instance().tokens
	WoldMotion.tween_number(_anim, _frac, target, func(v: float):
		_frac = v
		_sync(), t.duration_base)


func _sync() -> void:
	var body := %Body as Control
	body.visible = _frac > 0.0
	body.modulate.a = _frac
	(%Clip as Control).custom_minimum_size.y = roundf(_frac * body_height())


func _draw() -> void:
	if is_divided():
		var w := float(get_theme_constant(&"divider_width", &"AccordionTrigger"))
		draw_rect(Rect2(0, size.y - w, size.x, w), get_theme_color(&"divider", &"AccordionTrigger"))


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		queue_redraw()
	elif what == NOTIFICATION_PARENTED:
		_refresh()
