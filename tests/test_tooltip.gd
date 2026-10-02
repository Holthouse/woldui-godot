extends "res://addons/woldui/tests/wold_test_base.gd"
## WoldTooltip: hover delay, focus, one at a time, placement + edge flip, content, _wold_fill.

const TIP := "res://addons/woldui/components/wold_tooltip/wold_tooltip.tscn"

var ui: WoldUIRuntime
var stage: Control


func _run() -> void:
	ui = WoldUIRuntime.instance()
	# 64px headless window again, placement needs a real screen
	get_root().size = Vector2i(1280, 720)
	await process_frame
	get_root().theme = WoldThemeBuilder.build(tokens())
	stage = Control.new()
	stage.size = get_root().get_visible_rect().size
	get_root().add_child(stage)
	await _hover()
	await _focus()
	await _content()
	await _placement()
	await _one_at_a_time_and_cleanup()
	await _hook()
	await _touch()
	finish(30)


func _target(pos := Vector2(400, 300)) -> Button:
	var b := Button.new()
	b.text = "Spearman"
	b.position = pos
	b.size = Vector2(120, 40)
	stage.add_child(b)
	return b


func _tip(on: Control) -> WoldTooltip:
	var t: WoldTooltip = load(TIP).instantiate()
	t.delay = 0.2
	on.add_child(t)
	return t


func _hover() -> void:
	var b := _target()
	var t := _tip(b)
	await process_frame
	b.mouse_entered.emit()
	await create_timer(0.1).timeout
	check(not t.is_showing(), "hovering waits for the delay")
	await create_timer(0.2).timeout
	check(t.is_showing(), "then the tooltip shows")
	check(t.panel.mouse_filter == Control.MOUSE_FILTER_IGNORE, "and never blocks the mouse")
	check(t.panel.get_parent() is CanvasLayer and (t.panel.get_parent() as CanvasLayer).layer == WoldTooltip.LAYER, "on its own top layer")
	b.mouse_exited.emit()
	check(not t.is_showing(), "leaving hides it")
	b.mouse_entered.emit()
	await create_timer(0.1).timeout
	b.mouse_exited.emit()
	await create_timer(0.25).timeout
	check(not t.is_showing(), "a brush-past shorter than the delay shows nothing")
	b.queue_free()


func _focus() -> void:
	var b := _target()
	var t := _tip(b)
	await process_frame
	ui.note_input(InputEventMouseButton.new())
	b.focus_entered.emit()
	check(not t.is_showing(), "focus from a mouse click shows nothing")
	var pad := InputEventJoypadButton.new()
	pad.pressed = true
	ui.note_input(pad)
	b.focus_entered.emit()
	check(t.is_showing(), "focus while on a pad shows it at once, no mouse needed")
	b.focus_exited.emit()
	check(not t.is_showing(), "and moving focus away hides it")
	t.show_on_focus = false
	b.focus_entered.emit()
	check(not t.is_showing(), "show_on_focus off")
	ui.note_input(InputEventMouseButton.new())
	b.queue_free()


func _content() -> void:
	var b := _target()
	var t := _tip(b)
	await process_frame
	t.show_tip()
	var p := t.panel
	check((p.get_node("%Title") as Label).text == "Spearman" and p.get_node("%Icon").visible, "title and icon")
	check((p.get_node("%Icon") as TextureRect).self_modulate == p.get_theme_color("font_color", "TooltipTitle") and p.get_theme_color("font_color", "TooltipTitle") != Color.WHITE, "the icon is tinted like the title (white icons vanished on a light panel)")
	check((p.get_node("%Body") as RichTextLabel).text.contains("[b]Double damage[/b]"), "the body is BBCode")
	var grid := p.get_node("%Rows") as GridContainer
	check(grid.get_child_count() == 6 and (grid.get_child(0) as Label).text == "Attack" and (grid.get_child(1) as Label).text == "6", "each row is a label and a value")
	check((p.get_node("%Hint") as Label).text == "Right-click for details", "the hint line")
	t.hide_tip()
	t.rows = {}
	t.hint = ""
	t.icon = ""
	t.show_tip()
	check(not t.panel.get_node("%Rows").visible and not t.panel.get_node("%Hint").visible and not t.panel.get_node("%Icon").visible, "empty parts take no space")
	t.hide_tip()
	b.queue_free()


func _placement() -> void:
	var gap := float(tokens().space_sm)
	var b := _target(Vector2(400, 300))
	var t := _tip(b)
	await process_frame
	t.show_tip()
	await process_frame
	var r := b.get_global_rect()
	var pr := t.panel.get_global_rect()
	check(is_equal_approx(pr.end.y, r.position.y - gap), "AUTO puts it above the target, a gap away")
	check(absf(pr.get_center().x - r.get_center().x) < 1.0, "centred on the target")
	t.hide_tip()
	b.position = Vector2(400, 4)
	t.show_tip()
	await process_frame
	check(is_equal_approx(t.panel.global_position.y, b.get_global_rect().end.y + gap), "no room above: it flips below")
	t.hide_tip()
	b.position = Vector2(stage.size.x - 60, 300)
	t.show_tip()
	await process_frame
	check(t.panel.get_global_rect().end.x <= stage.size.x - gap + 0.5, "it stays on screen at the right edge")
	t.hide_tip()
	t.placement = WoldTooltip.Placement.RIGHT
	b.position = Vector2(200, 300)
	t.show_tip()
	await process_frame
	check(is_equal_approx(t.panel.global_position.x, b.get_global_rect().end.x + gap), "RIGHT puts it beside the target")
	t.hide_tip()
	b.queue_free()


func _one_at_a_time_and_cleanup() -> void:
	var a := _target(Vector2(100, 300))
	var b := _target(Vector2(500, 300))
	var ta := _tip(a)
	var tb := _tip(b)
	await process_frame
	ta.show_tip()
	tb.show_tip()
	check(not ta.is_showing() and tb.is_showing(), "only one tooltip shows at a time")
	var panel := tb.panel
	b.queue_free()
	await process_frame
	await process_frame
	check(not is_instance_valid(panel), "freeing the target removes its tooltip")
	ta.show_tip()
	var p2 := ta.panel
	a.visible = false
	await process_frame
	check(not is_instance_valid(p2) or p2.is_queued_for_deletion(), "hiding the target removes its tooltip")
	a.queue_free()
	ui.reduced_motion = true
	var c := _target()
	var tc := _tip(c)
	await process_frame
	tc.show_tip()
	check(tc.panel.modulate.a == 1.0, "reduced motion: there at once")
	ui.reduced_motion = false
	c.queue_free()


func _hook() -> void:
	var b := _target()
	var script := GDScript.new()
	script.source_code = "extends WoldTooltip\nvar calls := 0\nfunc _wold_fill(p):\n\tcalls += 1\n\tvar l := Label.new()\n\tl.name = \"Mine\"\n\tp.get_node(\"%Extra\").add_child(l)\n"
	script.reload()
	var t: WoldTooltip = script.new()
	b.add_child(t)
	await process_frame
	t.show_tip()
	check(t.calls == 1 and t.panel.get_node("%Extra").get_node_or_null("Mine") != null, "_wold_fill adds your own content to the Extra slot")
	t.hide_tip()
	b.queue_free()


func _touch_at(at: Vector2, pressed: bool) -> void:
	var e := InputEventScreenTouch.new()
	e.position = at
	e.pressed = pressed
	get_root().push_input(e)
	await process_frame


# a finger can't hover: long-press shows it, the next touch puts it away
func _touch() -> void:
	var rt := WoldUIRuntime.instance()
	var b := _target()
	var tip := _tip(b)
	tip.delay = 0.05
	await process_frame
	await _touch_at(Vector2(5, 5), true)
	await _touch_at(Vector2(5, 5), false)
	b.mouse_entered.emit()
	await create_timer(0.2).timeout
	check(rt.is_touch() and not tip.is_showing(), "touch: the hover a tap fakes doesn't show it")
	var at := b.get_global_rect().get_center()
	await _touch_at(at, true)
	await _touch_at(at, false)
	await create_timer(0.7).timeout
	check(not tip.is_showing(), "a quick tap doesn't either")
	await _touch_at(at, true)
	await create_timer(0.7).timeout
	check(tip.is_showing(), "holding a finger on it does")
	await _touch_at(at, false)
	await _touch_at(Vector2(5, 5), true)
	await _touch_at(Vector2(5, 5), false)
	check(not tip.is_showing(), "and the next touch anywhere puts it away")
	rt.note_input(InputEventMouseButton.new())
	b.queue_free()
