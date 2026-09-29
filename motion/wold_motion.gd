@tool
class_name WoldMotion
## All UI tweens go through here so timing/easing/reduced motion live in one spot.
##
## Only modulate.a and the offset transform get animated.
# containers reset position/scale on every sort, the offset transform they
# leave alone. Reduced motion still returns a Tween (done next frame) so
# awaiting it always works.

const PRESET_DIR := "res://addons/woldui/motion/presets/"
const _META := &"_wold_tween"


# ------------------------------------------------------------------ presets

## tokens.motion_presets[name] if set, else the bundled .tres.
static func preset(preset_name: String) -> WoldMotionPreset:
	var t := tokens()
	if t and t.motion_presets.has(preset_name) and t.motion_presets[preset_name]:
		return t.motion_presets[preset_name]
	var path := PRESET_DIR + preset_name + ".tres"
	assert(ResourceLoader.exists(path), "WoldMotion: no preset '%s'" % preset_name)
	return load(path)


static func preset_names() -> PackedStringArray:
	var out := PackedStringArray()
	for file in DirAccess.get_files_at(PRESET_DIR):
		if file.ends_with(".tres"):
			out.append(file.get_basename())
	return out


static func tokens() -> WoldTokens:
	return WoldUIRuntime.instance().tokens


static func reduced() -> bool:
	return WoldUIRuntime.instance().reduced_motion


# ------------------------------------------------------------------ enter / leave

## Popup windows (PopupMenu, OptionButton lists) have no modulate of their
## own, but they draw everything, shadow included, in an internal
## PanelContainer. This animates that in. Call it from about_to_popup.
static func popup_in(popup: Window, p: WoldMotionPreset = null) -> Tween:
	var panel := popup_panel(popup)
	if panel == null:
		return null
	return appear(panel, p if p else preset("tooltip_in"))


## The internal panel popup_in() animates, or null.
static func popup_panel(popup: Window) -> Control:
	for child in popup.get_children(true):
		if child is PanelContainer:
			return child
	return null


## Makes it visible and animates from the preset's from-state to rest.
static func appear(node: Control, p: WoldMotionPreset = null, extra_delay := 0.0) -> Tween:
	p = p if p else preset("appear")
	_prepare(node)
	node.visible = true
	if reduced():
		_rest(node)
		return _finished(node)
	var t := tokens()
	node.modulate.a = p.from_alpha
	node.offset_transform_position = p.from_offset
	node.offset_transform_scale = p.from_scale
	var tw := _tween(node, p, t)
	var d := p.seconds(t)
	var delay := p.delay + extra_delay
	tw.tween_property(node, "modulate:a", 1.0, d).set_delay(delay)
	tw.tween_property(node, "offset_transform_position", Vector2.ZERO, d).set_delay(delay)
	tw.tween_property(node, "offset_transform_scale", Vector2.ONE, d).set_delay(delay)
	return tw


## Animates out, then hides or frees.
# disappear presets read backwards: "from" is where it ends up
static func disappear(node: Control, p: WoldMotionPreset = null, then_free := false) -> Tween:
	p = p if p else preset("disappear")
	_prepare(node)
	var finish := func():
		if then_free:
			node.queue_free()
		else:
			node.visible = false
			_rest(node)
	if reduced() or not node.visible:
		finish.call()
		return _finished(node)
	var t := tokens()
	var tw := _tween(node, p, t)
	var d := p.seconds(t)
	tw.tween_property(node, "modulate:a", p.from_alpha, d).set_delay(p.delay)
	tw.tween_property(node, "offset_transform_position", p.from_offset, d).set_delay(p.delay)
	tw.tween_property(node, "offset_transform_scale", p.from_scale, d).set_delay(p.delay)
	tw.chain().tween_callback(finish)
	return tw


## appear() down a list. Returns the last node's tween, which ends last.
static func stagger(nodes: Array, p: WoldMotionPreset = null) -> Tween:
	p = p if p else preset("item")
	var last: Tween
	for i in nodes.size():
		last = appear(nodes[i], p, i * p.stagger)
	return last


# ------------------------------------------------------------------ feedback

## Button press dip.
static func press(node: Control) -> Tween:
	var t := tokens()
	_prepare(node)
	if reduced() or is_equal_approx(t.press_scale, 1.0):
		return _finished(node)
	var tw := _tween(node, null, t, false)
	var down := Vector2(t.press_scale, t.press_scale)
	tw.tween_property(node, "offset_transform_scale", down, t.duration_instant).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(node, "offset_transform_scale", Vector2.ONE, t.duration_fast).set_trans(t.enter_transition).set_ease(t.enter_ease)
	return tw


## Little swell for "this changed", e.g. a count going up.
static func bump(node: Control, amount := 1.18) -> Tween:
	var t := tokens()
	_prepare(node)
	if reduced():
		return _finished(node)
	var tw := _tween(node, null, t, false)
	tw.tween_property(node, "offset_transform_scale", Vector2(amount, amount), t.duration_instant).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(node, "offset_transform_scale", Vector2.ONE, t.duration_base).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	return tw


## Slides in from `from` (an offset) while fading up. A value stepping
## left / right in a WoldStepper, say.
static func nudge(node: Control, from: Vector2) -> Tween:
	var t := tokens()
	_prepare(node)
	if reduced():
		_rest(node)
		return _finished(node)
	var tw := _tween(node, null, t)
	node.offset_transform_position = from
	node.modulate.a = 0.35
	tw.tween_property(node, "offset_transform_position", Vector2.ZERO, t.duration_fast).set_trans(t.enter_transition).set_ease(t.enter_ease)
	tw.tween_property(node, "modulate:a", 1.0, t.duration_fast)
	return tw


## Slides in from `from` (an offset) to where layout put it, alpha to full.
## For moving something the layout just moved (a card shuffling along).
static func slide(node: Control, from: Vector2, seconds := -1.0) -> Tween:
	var t := tokens()
	_prepare(node)
	if reduced():
		_rest(node)
		return _finished(node)
	var tw := _tween(node, null, t)
	node.offset_transform_position = from
	var d := seconds if seconds > 0.0 else t.duration_base
	tw.tween_property(node, "offset_transform_position", Vector2.ZERO, d).set_trans(t.move_transition).set_ease(t.move_ease)
	# a slide can cut a fade short; finish it
	tw.tween_property(node, "modulate:a", 1.0, d)
	return tw


# ------------------------------------------------------------------ sequences

## A game's own timed sequence on `node` (a turn banner, a toast): build it
## with fade(), tween_interval() and tween_callback(). Like every WoldMotion
## tween, a new one on the same node kills the old.
static func sequence(node: Node) -> Tween:
	return _tween(node, null, tokens(), false)


## A fade step in a sequence. Instant under reduced motion; holds around it
## stay, they're reading time, not motion. `together` runs it alongside the
## step before.
static func fade(tw: Tween, node: CanvasItem, alpha: float, seconds: float, together := false) -> PropertyTweener:
	if together:
		tw.parallel()
	return tw.tween_property(node, "modulate:a", alpha, 0.0 if reduced() else seconds)


## Eases a 0..1 style amount (hover glow, a selected tint) for things a
## component draws itself. Its own tween, so it runs alongside hover and press
## motion on the same node. Kills `prev`; null when it jumped (reduced motion,
## editor, not in the tree).
static func blend(prev: Tween, node: Node, from: float, to: float, show: Callable, seconds := -1.0) -> Tween:
	if prev:
		prev.kill()
	var t := tokens()
	if reduced() or Engine.is_editor_hint() or not node.is_inside_tree() or is_equal_approx(from, to):
		show.call(to)
		return null
	var tw := node.create_tween()
	tw.tween_method(show, from, to, seconds if seconds >= 0.0 else t.duration_fast).set_trans(t.state_transition).set_ease(t.state_ease)
	return tw


static func hover(node: Control, on: bool) -> Tween:
	var t := tokens()
	_prepare(node)
	var target := Vector2(t.hover_scale, t.hover_scale) if on else Vector2.ONE
	if reduced() or is_equal_approx(t.hover_scale, 1.0):
		node.offset_transform_scale = Vector2.ONE
		return _finished(node)
	var tw := _tween(node, null, t, false)
	tw.tween_property(node, "offset_transform_scale", target, t.duration_fast).set_trans(t.enter_transition).set_ease(t.enter_ease)
	return tw


## Horizontal "no" shake. Skipped under reduced motion, so don't rely on it
## alone - pair it with a sound or message.
static func shake(node: Control, strength := 6.0) -> Tween:
	var t := tokens()
	_prepare(node)
	if reduced():
		return _finished(node)
	var tw := _tween(node, null, t, false)
	var step := t.duration_instant / 2.0
	for x in [strength, -strength, strength * 0.6, -strength * 0.6, strength * 0.25, 0.0]:
		tw.tween_property(node, "offset_transform_position:x", x, step).set_trans(Tween.TRANS_SINE)
	return tw


## Slow alpha breathing. loops = 0 runs until stopped. seconds is one way
## (full to low, or back); the default is twice duration_slow. hold waits at
## low_alpha each cycle, so a pulse down to 0 stays gone for a moment.
static func pulse(node: Control, low_alpha := 0.4, loops := 0, seconds := -1.0, hold := 0.0) -> Tween:
	var t := tokens()
	_prepare(node)
	if reduced():
		node.modulate.a = 1.0
		return _finished(node)
	var d := seconds if seconds > 0.0 else t.duration_slow * 2.0
	var tw := _tween(node, null, t, false)
	tw.set_loops(loops)
	tw.tween_property(node, "modulate:a", low_alpha, d).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	if hold > 0.0:
		tw.tween_interval(hold)
	tw.tween_property(node, "modulate:a", 1.0, d).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	return tw


## Tints self_modulate toward `color` and back. Damage hits etc.
# uses its own tween, so it can run on top of another motion
static func flash(node: CanvasItem, color: Color, seconds := -1.0) -> Tween:
	var t := tokens()
	var rest := node.self_modulate
	if reduced():
		return _finished(node)
	var d := seconds if seconds > 0.0 else t.duration_base
	var tw := node.create_tween()
	tw.tween_property(node, "self_modulate", color, d * 0.3)
	tw.tween_property(node, "self_modulate", rest, d * 0.7).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	return tw


## `format` takes one number: "%d", "%.1f", "%d gold".
static func count_to(label: Label, from: float, to: float, format := "%d", seconds := -1.0) -> Tween:
	var show := func(v: float) -> void:
		label.text = format % (roundi(v) if format.contains("%d") else v)
	return tween_number(label, from, to, show, seconds)


## Like count_to but you do the formatting in `show`. WoldStat uses this.
## Reduced motion just calls show(to).
static func tween_number(owner_node: Node, from: float, to: float, show: Callable, seconds := -1.0) -> Tween:
	var t := tokens()
	if reduced() or is_equal_approx(from, to):
		show.call(to)
		return _finished(owner_node)
	var d := seconds if seconds > 0.0 else t.duration_slow * 1.5
	var tw := _tween(owner_node, null, t, false)
	tw.tween_method(show, from, to, d).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	return tw


static func stop(node: Control) -> void:
	_kill(node)
	_rest(node)


# ------------------------------------------------------------------ internals

static func _prepare(node: Control) -> void:
	node.offset_transform_enabled = true
	node.offset_transform_visual_only = true
	node.offset_transform_pivot_ratio = Vector2(0.5, 0.5)


static func _rest(node: Control) -> void:
	node.modulate.a = 1.0
	node.offset_transform_position = Vector2.ZERO
	node.offset_transform_scale = Vector2.ONE
	node.offset_transform_rotation = 0.0


# one tween per node, a new one kills the old so they don't fight
static func _tween(node: Node, p: WoldMotionPreset, t: WoldTokens, parallel := true) -> Tween:
	_kill(node)
	var tw := node.create_tween()
	if parallel:
		tw.set_parallel(true)
	if p:
		tw.set_trans(p.transition(t)).set_ease(p.ease_type(t))
	node.set_meta(_META, tw)
	return tw


static func _kill(node: Node) -> void:
	if node.has_meta(_META):
		var old: Tween = node.get_meta(_META)
		if old and old.is_valid():
			old.kill()
		node.remove_meta(_META)


static func _finished(node: Node) -> Tween:
	_kill(node)
	var tw := node.create_tween()
	tw.tween_interval(0.0)
	return tw
