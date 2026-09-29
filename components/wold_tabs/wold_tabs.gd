@tool
class_name WoldTabs
extends BoxContainer
## Tab bar with a sliding marker. Works like TabContainer: each child you add
## is a page, and its node name is the tab label.
## `look`: an underline (LINE) or a raised pill on a sunken track (PILL).
## `layout`: tabs across the top, or down the SIDE with pages to the right
## (give the pages SIZE_EXPAND_FILL horizontally so they take the room).
## Per-page meta if you want more: wold_title (label), wold_icon, wold_badge
## (a count, 0 = none).
## No pages at all -> fill in `tabs` and use it as a bare bar.

const Thumb := preload("../shared/wold_thumb.gd")

signal tab_changed(index: int)

enum Look { LINE, PILL }
enum Layout { TOP, SIDE }

@export var current := 0:
	set(v):
		# while loading the pages aren't there yet; _rebuild clamps it later
		if not is_node_ready():
			current = v
			return
		var count := tab_count()
		var clamped := clampi(v, 0, maxi(count - 1, 0))
		var changed := clamped != current
		current = clamped
		_apply(changed)
## Only used when there are no page children.
@export var tabs: PackedStringArray = []:
	set(v):
		tabs = v
		_rebuild()
@export var stretch := false:
	set(v):
		stretch = v
		_rebuild()
@export var look: Look = Look.LINE:
	set(v):
		look = v
		_rebuild()
## Not `vertical`: that's BoxContainer's own, and this sets it.
@export var layout: Layout = Layout.TOP:
	set(v):
		layout = v
		_rebuild()
## The underline goes before the tabs (left of a side bar, above a top one)
## instead of after them. Only the LINE look draws it.
@export var marker_first := false:
	set(v):
		marker_first = v
		_rebuild()
## LB/RB flip tabs. Reads the joypad buttons directly, no InputMap needed.
@export var pad_shoulders := true
@export var animate_pages := true

var _group := ButtonGroup.new()
var _slide: Tween
var _building := false
var _anim := Node.new()
var _pill := Thumb.new(self, _anim)


func _ready() -> void:
	if _anim.get_parent() == null:
		add_child(_anim, false, Node.INTERNAL_MODE_FRONT)
	child_entered_tree.connect(func(_n): _rebuild.call_deferred())
	child_exiting_tree.connect(func(_n): _rebuild.call_deferred())
	# after the bar lays its buttons out; resized comes before that
	%Bar.sort_children.connect(_follow, CONNECT_DEFERRED)
	_rebuild()


## Subclass hook, runs before the bar is rebuilt.
func _wold_refresh() -> void:
	pass


## Every Control child except the header.
func pages() -> Array[Control]:
	var out: Array[Control] = []
	for child in get_children():
		if child is Control and child != %Header and not child.is_queued_for_deletion():
			out.append(child)
	return out


func tab_count() -> int:
	if not is_node_ready():
		return maxi(tabs.size(), 1)
	var p := pages().size()
	return p if p > 0 else tabs.size()


func tab_button(index: int) -> Button:
	return %Bar.get_child(index) as Button


func _unhandled_input(event: InputEvent) -> void:
	if not pad_shoulders or not is_visible_in_tree() or Engine.is_editor_hint():
		return
	var jb := event as InputEventJoypadButton
	if jb and jb.pressed:
		if jb.button_index == JOY_BUTTON_RIGHT_SHOULDER and current < tab_count() - 1:
			self.current = current + 1
			get_viewport().set_input_as_handled()
		elif jb.button_index == JOY_BUTTON_LEFT_SHOULDER and current > 0:
			self.current = current - 1
			get_viewport().set_input_as_handled()


func _rebuild() -> void:
	if _building or not is_node_ready():
		return
	_building = true
	_wold_refresh()
	_arrange()
	var bar := %Bar as BoxContainer
	# throw the buttons away and rebuild; cheap enough for a handful of tabs
	for child in bar.get_children():
		bar.remove_child(child)
		child.queue_free()
	var labels: Array = []
	var page_list := pages()
	if page_list.is_empty():
		for t in tabs:
			labels.append({title = t, icon = "", badge = 0})
	else:
		for p in page_list:
			labels.append({title = String(p.get_meta("wold_title", p.name)), icon = String(p.get_meta("wold_icon", "")), badge = int(p.get_meta("wold_badge", 0))})
	var tokens := WoldUIRuntime.instance().tokens
	for i in labels.size():
		var b := Button.new()
		b.theme_type_variation = &"TabButtonPill" if look == Look.PILL else &"TabButton"
		if layout == Layout.SIDE:
			b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.text = labels[i].title
		b.toggle_mode = true
		b.button_group = _group
		b.focus_mode = Control.FOCUS_ALL
		if labels[i].icon != "":
			b.icon = tokens.icon(labels[i].icon)
		if stretch and layout == Layout.TOP:
			b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		elif stretch:
			b.size_flags_vertical = Control.SIZE_EXPAND_FILL
		if labels[i].badge > 0:
			var badge: WoldBadge = load("res://addons/woldui/components/wold_badge/wold_badge.tscn").instantiate()
			badge.count = labels[i].badge
			badge.tone = WoldBadge.Tone.ACCENT
			badge.fill = WoldBadge.Fill.SOLID
			badge.badge_size = WoldBadge.Size.SM
			badge.pin = WoldBadge.Pin.TOP_RIGHT
			b.add_child(badge)
		var index := i
		b.pressed.connect(func(): self.current = index)
		bar.add_child(b)
	_building = false
	current = clampi(current, 0, maxi(labels.size() - 1, 0))
	_apply(false)


func _apply(changed: bool) -> void:
	if not is_node_ready() or _building:
		return
	var bar := %Bar as BoxContainer
	if current < bar.get_child_count():
		(bar.get_child(current) as Button).set_pressed_no_signal(true)
	var page_list := pages()
	for i in page_list.size():
		var show := i == current
		if show and not page_list[i].visible and changed and animate_pages and not Engine.is_editor_hint():
			page_list[i].visible = true
			WoldMotion.appear(page_list[i], WoldMotion.preset("appear_fade"))
		else:
			page_list[i].visible = show
	# deferred so the bar has laid out the new buttons first
	_place_indicator.call_deferred(changed)
	if changed:
		tab_changed.emit(current)


## Where the underline goes for the current tab, in the rail's space: under
## it for TOP, beside it for SIDE.
func indicator_target() -> Rect2:
	var bar := %Bar as BoxContainer
	if current >= bar.get_child_count():
		return Rect2()
	var b := bar.get_child(current) as Control
	var rail := %Rail as Control
	var at := b.global_position - rail.global_position
	if layout == Layout.SIDE:
		return Rect2(0.0, at.y, rail.size.x, b.size.y)
	return Rect2(at.x, 0.0, b.size.x, rail.size.y)


func _follow() -> void:
	if look == Look.PILL:
		_pill.retarget(pill_target())
	else:
		_place_indicator(false)


## The pill's target for the current tab, in our own space.
func pill_target() -> Rect2:
	var bar := %Bar as BoxContainer
	if current >= bar.get_child_count():
		return Rect2()
	var b := bar.get_child(current) as Control
	return Rect2(b.global_position - global_position, b.size)


## Where the pill is drawn right now, in our own space.
func pill_rect() -> Rect2:
	return _pill.rect()


func _place_indicator(animated: bool) -> void:
	if not is_node_ready():
		return
	if look == Look.PILL:
		_pill.move(pill_target(), animated)
		queue_redraw()
		return
	var ind := %Indicator as Control
	var target := indicator_target()
	if _slide:
		_slide.kill()
	var live := animated and not WoldMotion.reduced() and not Engine.is_editor_hint() and ind.size.x > 0.0
	if not live:
		ind.position = target.position
		ind.size = target.size
		return
	var t := WoldUIRuntime.instance().tokens
	_slide = ind.create_tween().set_parallel().set_trans(t.move_transition).set_ease(t.move_ease)
	_slide.tween_property(ind, "position", target.position, t.duration_base)
	_slide.tween_property(ind, "size", target.size, t.duration_base)


# The bits the look and layout move around: which boxes run which way, where
# the rail sits, the track padding.
func _arrange() -> void:
	var top := layout == Layout.TOP
	vertical = top
	(%Header as BoxContainer).vertical = top
	(%Bar as BoxContainer).vertical = not top
	# down the side the bar is only as tall as its tabs
	(%Header as Control).size_flags_vertical = Control.SIZE_FILL if top else Control.SIZE_SHRINK_BEGIN
	var header := %Header as Control
	header.move_child(%Rail, 0 if marker_first else header.get_child_count() - 1)
	var line := look == Look.LINE
	(%BarPad as Control).theme_type_variation = &"TabsLineInset" if line else &"TabsPillInset"
	var rail := %Rail as Control
	rail.visible = line
	rail.custom_minimum_size = Vector2(0, 2) if top else Vector2(2, 0)
	var track := %Track as Control
	if top:
		track.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
		track.offset_top = -1.0
	else:
		track.set_anchors_and_offsets_preset(Control.PRESET_RIGHT_WIDE)
		track.offset_left = -1.0
	queue_redraw()


# the pill look draws its track and pill here, behind the tab buttons
func _draw() -> void:
	if look != Look.PILL:
		return
	var pad := %BarPad as Control
	draw_style_box(get_theme_stylebox(&"panel", &"TabsPillTrack"), Rect2(pad.global_position - global_position, pad.size))
	if _pill.is_placed():
		draw_style_box(get_theme_stylebox(&"panel", &"TabsPill"), _pill.rect())


func _validate_property(property: Dictionary) -> void:
	# `layout` sets it
	if property.name == "vertical":
		property.usage &= ~PROPERTY_USAGE_STORAGE
