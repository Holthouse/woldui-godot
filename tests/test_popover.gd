extends "res://addons/woldui/tests/wold_test_base.gd"
## WoldPopover: click to open, placement (flip, clamp), dismissing, focus, hover cards, theme.

const SCENE := "res://addons/woldui/components/wold_popover/wold_popover.tscn"

var stage: Control


func _run() -> void:
	WoldUIRuntime.instance().reduced_motion = true
	get_root().size = Vector2i(1280, 720)
	stage = Control.new()
	stage.size = Vector2(1280, 720)
	stage.theme = WoldThemeBuilder.build(tokens())
	get_root().add_child(stage)
	await _click()
	await _placement()
	await _dismiss()
	await _keyboard()
	await _hover()
	await _touch_hover()
	var a := _anchor()
	var card: WoldPopover = load("res://addons/woldui/gallery/examples/city_card.tscn").instantiate()
	a.add_child(card)
	await _frames()
	check(card.trigger == WoldPopover.Trigger.HOVER and card.content().get_child_count() == 2, "CityCard is a hover card with its own content")
	a.queue_free()
	finish(22)


func _frames() -> void:
	await process_frame
	await process_frame


func _anchor(at := Vector2(400, 200)) -> Button:
	var b := Button.new()
	b.text = "Rivermouth"
	b.position = at
	b.size = Vector2(140, 40)
	stage.add_child(b)
	return b


func _pop(a: Control) -> WoldPopover:
	var p: WoldPopover = load(SCENE).instantiate()
	a.add_child(p)
	return p


func _mouse(at: Vector2, pressed := false) -> void:
	if pressed:
		var e := InputEventMouseButton.new()
		e.button_index = MOUSE_BUTTON_LEFT
		e.pressed = true
		e.position = at
		e.global_position = at
		get_root().push_input(e)
	else:
		var m := InputEventMouseMotion.new()
		m.position = at
		m.global_position = at
		get_root().push_input(m)
	await process_frame


func _click() -> void:
	var a := _anchor()
	var p := _pop(a)
	await _frames()
	check(not p.panel().visible and p.panel().get_parent() == p, "closed: the panel waits, hidden, under the popover")
	var said := []
	p.opened.connect(func(): said.append("open"))
	p.title = "Highlands"
	a.pressed.emit()
	await _frames()
	check(p.is_open and p.panel().visible and p.panel().get_parent().name == "WoldPopovers" and said == ["open"], "the anchor's press opens it on its own layer")
	check(p.panel().theme == stage.theme, "and it keeps the theme it sat under")
	check((p.panel().get_node("Body/Title") as Label).text == "Highlands" and p.content() != null, "title shows, content is reachable")
	a.pressed.emit()
	await _frames()
	check(not p.is_open and p.panel().get_parent() == p and not p.panel().visible and p.panel().theme == null, "pressing again closes it and puts the panel back")
	a.queue_free()


func _placement() -> void:
	var a := _anchor()
	var p := _pop(a)
	await _frames()
	p.open()
	await _frames()
	var r := p.panel_rect()
	var gap := p.panel().get_theme_constant("gap")
	check(is_equal_approx(r.position.y, a.get_global_rect().end.y + gap) and absf(r.get_center().x - a.get_global_rect().get_center().x) < 1.0, "BOTTOM + CENTER: under the anchor, centred")
	check(p.panel().position == r.position, "the panel is where it says (%s vs %s)" % [p.panel().position, r])
	p.close()
	a.position = Vector2(400, 680)
	p.open()
	await _frames()
	check(p.panel_rect().end.y <= a.get_global_rect().position.y, "no room below: it flips above")
	p.close()
	a.position = Vector2(1240, 300)
	p.placement = WoldPopover.Placement.BOTTOM
	p.open()
	await _frames()
	check(p.panel_rect().end.x <= 1280.0, "and never hangs off the screen")
	p.close()
	await _frames()
	a.queue_free()


func _dismiss() -> void:
	var a := _anchor()
	var p := _pop(a)
	var inside := Button.new()
	inside.text = "Rename"
	p.get_node("%Content").add_child(inside)
	await _frames()
	a.grab_focus()
	p.open()
	await _frames()
	await _mouse(p.panel().get_global_rect().get_center(), true)
	check(p.is_open, "a click inside keeps it open")
	await _mouse(Vector2(20, 20), true)
	check(not p.is_open, "a click outside closes it")
	p.open()
	await _frames()
	inside.grab_focus()
	var e := InputEventAction.new()
	e.action = &"ui_cancel"
	e.pressed = true
	get_root().push_input(e)
	await _frames()
	check(not p.is_open and a.has_focus(), "Esc closes it and focus goes back to the anchor")
	a.queue_free()


func _keyboard() -> void:
	var ui := WoldUIRuntime.instance()
	var key := InputEventKey.new()
	key.keycode = KEY_TAB
	key.pressed = true
	ui.note_input(key)
	var a := _anchor()
	var p := _pop(a)
	var inside := Button.new()
	inside.text = "Rename"
	p.get_node("%Content").add_child(inside)
	var other := _anchor(Vector2(40, 40))
	await _frames()
	a.grab_focus()
	p.open()
	await _frames()
	check(inside.has_focus(), "opened from the keyboard: focus lands inside")
	other.grab_focus()
	await _frames()
	check(not p.is_open, "focus leaving closes it")
	a.queue_free()
	other.queue_free()


func _hover() -> void:
	var ui := WoldUIRuntime.instance()
	var a := _anchor()
	var p := _pop(a)
	p.trigger = WoldPopover.Trigger.HOVER
	p.delay = 0.05
	var away := _anchor(Vector2(40, 600))
	await _frames()
	await _mouse(Vector2(10, 10))
	await _mouse(a.get_global_rect().get_center())
	await create_timer(0.15).timeout
	check(p.is_open, "hover card: resting on the anchor opens it")
	await _mouse(p.panel().get_global_rect().get_center())
	await create_timer(0.25).timeout
	check(p.is_open, "moving onto the card keeps it open")
	await _mouse(Vector2(10, 10))
	await create_timer(0.25).timeout
	check(not p.is_open, "leaving both closes it")
	var key := InputEventKey.new()
	key.keycode = KEY_TAB
	key.pressed = true
	ui.note_input(key)
	a.grab_focus()
	await _frames()
	check(p.is_open, "keyboard focus on the anchor opens it too")
	away.grab_focus()
	await _frames()
	await _frames()
	check(not p.is_open, "and focus moving on closes it")
	a.queue_free()
	away.queue_free()


# hover cards on touch: a tap is the only way in
func _touch_hover() -> void:
	var ui := WoldUIRuntime.instance()
	var tap := InputEventScreenTouch.new()
	tap.pressed = true
	ui.note_input(tap)
	var a := _anchor()
	var p := _pop(a)
	p.trigger = WoldPopover.Trigger.HOVER
	p.delay = 0.05
	await _frames()
	a.pressed.emit()
	await _frames()
	a.mouse_exited.emit()
	await create_timer(0.3).timeout
	check(p.is_open, "touch: tapping a hover card's anchor opens it, and the faked pointer leaving doesn't close it")
	a.pressed.emit()
	await _frames()
	check(not p.is_open, "tapping again closes it")
	ui.note_input(InputEventMouseButton.new())
	a.queue_free()
