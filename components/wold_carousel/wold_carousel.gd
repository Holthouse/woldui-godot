@tool
class_name WoldCarousel
extends BoxContainer
## One page at a time, with arrows and page dots under it: a tutorial, a
## codex entry's pictures, a pick-your-leader screen. Pages are the node's
## children, like WoldTabs. The new page slides in from the side you went.
## flow DOWN stacks the pages vertically: they slide up and down and the
## controls stand in a column on the right.
## LB / RB flip pages while focus is inside it.

signal page_changed(index: int)

enum Flow { ACROSS, DOWN }

@export var current := 0:
	set(v):
		# while loading the pages aren't there yet, clamping now would lose it
		if not is_node_ready():
			current = v
			return
		var count := page_count()
		var to := clampi(v, 0, maxi(count - 1, 0))
		var dir := signi(to - current)
		var changed := to != current
		current = to
		_apply(dir if changed else 0)
## Past the last page, back to the first.
@export var wrap := false:
	set(v):
		wrap = v
		_apply(0)
## Not `vertical`: that's BoxContainer's own, and this sets it.
@export var flow: Flow = Flow.ACROSS:
	set(v):
		flow = v
		_arrange()
## LB / RB flip pages while focus is inside. Reads the pad directly.
@export var pad_shoulders := true

var _building := false


func _ready() -> void:
	child_entered_tree.connect(func(_n): _apply.call_deferred(0))
	child_exiting_tree.connect(func(_n): _apply.call_deferred(0))
	%Prev.pressed.connect(func(): step(-1))
	%Next.pressed.connect(func(): step(1))
	%Dots.page_selected.connect(func(i): self.current = i)
	_arrange()
	_apply(0)


## Every Control child except the controls row.
func pages() -> Array[Control]:
	var out: Array[Control] = []
	for child in get_children():
		if child is Control and child != %Controls and not child.is_queued_for_deletion():
			out.append(child)
	return out


func page_count() -> int:
	return pages().size() if is_node_ready() else 1


## -1 back, 1 on. False at an end without wrap.
func step(direction: int) -> bool:
	var count := page_count()
	var to := current + direction
	if to < 0 or to >= count:
		if not wrap or count == 0:
			return false
		to = wrapi(to, 0, count)
	# keep the slide direction right when wrapping round
	var from := current
	current = to
	if wrap and signi(to - from) != direction:
		_slide_in(direction)
	return true


func _apply(dir: int) -> void:
	if not is_node_ready() or _building:
		return
	_building = true
	var list := pages()
	current = clampi(current, 0, maxi(list.size() - 1, 0))
	for i in list.size():
		list[i].visible = i == current
	var dots := %Dots as WoldPageDots
	dots.count = list.size()
	dots.current = current
	(%Prev as Button).disabled = list.size() < 2 or (current == 0 and not wrap)
	(%Next as Button).disabled = list.size() < 2 or (current == list.size() - 1 and not wrap)
	%Controls.visible = list.size() > 1
	# the controls stay last whatever gets added
	move_child(%Controls, get_child_count() - 1)
	_building = false
	if dir != 0:
		_slide_in(dir)
		page_changed.emit(current)


func _slide_in(dir: int) -> void:
	var list := pages()
	if current >= list.size() or not is_inside_tree() or Engine.is_editor_hint():
		return
	var from := Vector2(0, 48.0 * dir) if flow == Flow.DOWN else Vector2(48.0 * dir, 0)
	WoldMotion.nudge(list[current], from)


func _focus_inside() -> bool:
	var f := get_viewport().gui_get_focus_owner() if is_inside_tree() else null
	return f != null and (f == self or is_ancestor_of(f))


func _unhandled_input(event: InputEvent) -> void:
	if not pad_shoulders or not is_visible_in_tree() or Engine.is_editor_hint():
		return
	var jb := event as InputEventJoypadButton
	if jb and jb.pressed and _focus_inside():
		if jb.button_index == JOY_BUTTON_RIGHT_SHOULDER and step(1):
			get_viewport().set_input_as_handled()
		elif jb.button_index == JOY_BUTTON_LEFT_SHOULDER and step(-1):
			get_viewport().set_input_as_handled()


func _arrange() -> void:
	if not is_node_ready():
		return
	var down := flow == Flow.DOWN
	vertical = not down
	var controls := %Controls as BoxContainer
	controls.vertical = down
	controls.size_flags_vertical = Control.SIZE_SHRINK_CENTER if down else Control.SIZE_FILL
	(%Prev as WoldButton).icon_start = "chevron-up" if down else "chevron-left"
	(%Next as WoldButton).icon_start = "chevron-down" if down else "chevron-right"
	var dots := %Dots as WoldPageDots
	dots.vertical = down
	dots.size_flags_horizontal = Control.SIZE_SHRINK_CENTER if down else Control.SIZE_EXPAND | Control.SIZE_SHRINK_CENTER
	dots.size_flags_vertical = Control.SIZE_EXPAND | Control.SIZE_SHRINK_CENTER if down else Control.SIZE_FILL


func _validate_property(property: Dictionary) -> void:
	# `flow` sets it
	if property.name == "vertical":
		property.usage &= ~PROPERTY_USAGE_STORAGE
