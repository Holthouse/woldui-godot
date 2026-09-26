extends "res://addons/woldui/tests/wold_test_base.gd"
## chat_recipe: WoldBubble, WoldMessage, WoldMessageLog, plus WoldKbd.

var stage: VBoxContainer


func _run() -> void:
	WoldUIRuntime.instance().reduced_motion = true
	get_root().size = Vector2i(1280, 720)
	stage = VBoxContainer.new()
	stage.size = Vector2(700, 700)
	stage.theme = WoldThemeBuilder.build(tokens())
	get_root().add_child(stage)
	await _bubble()
	for path in ["res://addons/woldui/tokens/default_dark.tres", "res://addons/woldui/tokens/default_light.tres"]:
		_contrast(path)
	await _message()
	await _log()
	await _kbd()
	var bark: WoldBubble = _add("res://addons/woldui/gallery/examples/npc_bark.tscn")
	var offer: WoldMessage = _add("res://addons/woldui/gallery/examples/trade_offer.tscn")
	var dlog = _add("res://addons/woldui/gallery/examples/diplomacy_log.tscn")
	var save: WoldKbd = _add("res://addons/woldui/gallery/examples/save_shortcut.tscn")
	await _frames()
	dlog.turn(7)
	check(bark.look == WoldBubble.Look.TINTED and offer.bubble().get_node("%Content").get_child_count() == 2 and dlog.items()[0] is WoldSeparator and save.get_child_count() == 3, "the chat examples come up as set")
	for n in [bark, offer, dlog, save]:
		n.queue_free()
	finish(26)


func _frames() -> void:
	await process_frame
	await process_frame


func _add(path: String) -> Node:
	var n: Node = load(path).instantiate()
	stage.add_child(n)
	return n


func _bubble() -> void:
	var t := tokens()
	var b: WoldBubble = _add("res://addons/woldui/components/wold_bubble/wold_bubble.tscn")
	await _frames()
	var panel := b.get_node("%Panel") as Control
	var sb := panel.get_theme_stylebox("panel") as StyleBoxFlat
	check(b.style_name() == &"BubbleSecondaryStart" and sb.corner_radius_bottom_left < sb.corner_radius_top_left, "the tail squares off the speaker's bottom corner")
	b.look = WoldBubble.Look.MUTED
	await _frames()
	check((b.get_node("%Text") as Label).get_theme_color("font_color") == t.role("text_muted"), "text in the look's colour")
	b.look = WoldBubble.Look.SECONDARY
	var short_w := panel.size.x
	check(short_w < b.max_width, "a short line makes a small bubble (%.0f)" % short_w)
	b.text = "The Spidobots have crossed the river at three points and our scouts say more are coming."
	await _frames()
	check(panel.size.x <= b.max_width + 0.5 and panel.size.x > short_w and (b.get_node("%Text") as Label).get_line_count() > 1, "long text wraps at max_width")
	b.tail = WoldBubble.Tail.END
	b.look = WoldBubble.Look.DEFAULT
	await _frames()
	sb = panel.get_theme_stylebox("panel") as StyleBoxFlat
	check(sb.corner_radius_bottom_right < sb.corner_radius_bottom_left and panel.size_flags_horizontal == Control.SIZE_SHRINK_END, "END: tail on the right, hugging the right side")
	check((b.get_node("%Text") as Label).get_theme_color("font_color") == t.role("on_accent"), "DEFAULT is the accent bubble")
	check(not b.get_node("%Reactions").visible and not b.get_node("%Content").visible, "empty slots take no room")
	var badge: WoldBadge = load("res://addons/woldui/components/wold_badge/wold_badge.tscn").instantiate()
	badge.text = "+2"
	b.get_node("%Reactions").add_child(badge)
	await _frames()
	check(b.get_node("%Reactions").visible, "a reaction shows its row")
	b.queue_free()


func _contrast(path: String) -> void:
	var t := tokens(path)
	var th := WoldThemeBuilder.build(t)
	var on := t.role("surface_raised")
	var ratio := func(style: String) -> float:
		var bg := on.blend((th.get_stylebox("panel", style) as StyleBoxFlat).bg_color)
		return WoldColor.contrast(th.get_color("text", style), bg)
	var tinted: float = ratio.call("BubbleTinted")
	var danger: float = ratio.call("BubbleDanger")
	check(tinted >= 4.5 and danger >= 4.5, "%s: tinted and danger bubbles read (%.2f, %.2f)" % [path.get_file(), tinted, danger])
	var fill := (th.get_stylebox("panel", "BubbleSecondary") as StyleBoxFlat).bg_color
	check(fill != t.role("surface_base") and fill != t.role("surface_raised"), "%s: a secondary bubble shows on the page and on panels" % path.get_file())


func _message() -> void:
	var m: WoldMessage = _add("res://addons/woldui/components/wold_message/wold_message.tscn")
	m.time = "12:04"
	m.author = "Old Tom"
	await _frames()
	var avatar := m.get_node("%Avatar") as WoldAvatar
	check((m.get_node("%Name") as Label).text == "Old Tom" and (m.get_node("%Time") as Label).text == "12:04" and avatar.display_name == "Old Tom", "name, time and avatar")
	check(m.get_child(0) == avatar and m.bubble().tail == WoldBubble.Tail.START, "someone else: avatar on the left, tail towards it")
	m.mine = true
	await _frames()
	check(m.get_child(m.get_child_count() - 1) == avatar and m.bubble().tail == WoldBubble.Tail.END and m.bubble().get_global_rect().end.x > 600.0, "mine: flipped to the right")
	m.show_header = false
	await _frames()
	check(not m.get_node("%Header").visible and avatar.visible and avatar.modulate.a == 0.0, "a follow-up drops the header and keeps the avatar's gap")
	m.queue_free()


func _log() -> void:
	var l: WoldMessageLog = _add("res://addons/woldui/components/wold_message_log/wold_message_log.tscn")
	await _frames()
	var a := l.say("Queen Mab", "Trade you 20 wood?")
	var b := l.say("Queen Mab", "Or 10 gold.")
	var c := l.say("You", "Deal.", true)
	check(a.show_header and not b.show_header and c.show_header, "same speaker in a row: one header")
	check(c.look == WoldBubble.Look.DEFAULT and c.mine, "your own lines get the accent bubble")
	for i in 20:
		l.say("Old Tom" if i % 2 else "Ivy", "Line %d" % i)
	await _frames()
	await _frames()
	check(l.is_at_bottom(), "while you're at the bottom it follows new lines")
	var scroll := l.get_node("%Scroll") as ScrollContainer
	scroll.scroll_vertical = 0
	await _frames()
	l.say("Ivy", "Anyone there?")
	await _frames()
	check(l.unread == 1 and l.get_node("%Jump").visible and scroll.scroll_vertical == 0, "scrolled up: it stays put and shows 1 new")
	(l.get_node("%Jump") as Button).pressed.emit()
	await _frames()
	await _frames()
	check(l.is_at_bottom() and l.unread == 0 and not l.get_node("%Jump").visible, "the button takes you down and clears it")
	l.max_items = 5
	l.say("Ivy", "Trim time.")
	check(l.items().size() == 5, "past max_items the oldest lines drop off")
	var note := Label.new()
	note.text = "Turn 43"
	l.add(note)
	check(l.items().back() == note, "any Control can be a line")
	l.queue_free()


func _kbd() -> void:
	var k: WoldKbd = _add("res://addons/woldui/components/wold_kbd/wold_kbd.tscn")
	await _frames()
	var caps := k.get_children()
	check(caps.size() == 2 and caps[0] is WoldPromptGlyph and caps[0].glyph.text == "Ctrl" and caps[1].glyph.text == "K", "Ctrl+K: two key caps")
	k.keys = "Shift + Tab"
	await _frames()
	check(k.get_child_count() == 2 and k.get_child(1).glyph.text == "Tab" and k.get_child(0).owner == null, "keys rebuild the caps (never saved)")
	k.queue_free()
