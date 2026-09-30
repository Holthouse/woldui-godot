extends "res://addons/woldui/tests/wold_test_base.gd"
## WoldFeedback's state fades: buttons, tabs, focus rings, popup lists.

var stage: Control
var ui: WoldUIRuntime
var dark: Theme
var light: Theme


func _run() -> void:
	ui = WoldUIRuntime.instance()
	ui.reduced_motion = false
	dark = WoldThemeBuilder.build(tokens())
	light = WoldThemeBuilder.build(tokens("res://addons/woldui/tokens/default_light.tres"))
	stage = Control.new()
	stage.theme = dark
	stage.size = Vector2(800, 600)
	get_root().size = Vector2i(800, 600)
	get_root().add_child(stage)
	await _button_hover()
	await _button_font_and_reduced()
	await _button_ring()
	await _button_theme_swap()
	await _lookup()
	await _button_opt_outs()
	await _button_strip()
	await _wold_button_settles()
	await _tabs()
	await _tabs_select()
	await _focus_fields()
	await _popups()
	await _native_checks()
	await _rereads()
	await _component_fades()
	finish(69)


func _frames(n: int) -> void:
	for i in n:
		await process_frame


# part way through a fade. Frames alone can be microseconds apart headless.
func _mid() -> void:
	await create_timer(tokens().duration_fast * 0.4).timeout


func _settle() -> void:
	await create_timer(tokens().duration_fast + 0.1).timeout
	await _frames(2)


func _host() -> VBoxContainer:
	var host := VBoxContainer.new()
	stage.add_child(host)
	var fb := WoldFeedback.new()
	host.add_child(fb)
	return host


func _fade(node: Node) -> Object:
	return node.get_meta(&"_wold_fade") if node.has_meta(&"_wold_fade") else null


# theme value a plain, unwired control of the same kind gets
func _theme_box(kind: String, variation: StringName, item: String) -> StyleBoxFlat:
	var probe: Node = ClassDB.instantiate(kind)
	probe.theme_type_variation = variation
	stage.add_child(probe)
	var sb: StyleBoxFlat = probe.call("get_theme_stylebox", item)
	probe.free()
	return sb


func _theme_color(kind: String, variation: StringName, item: String) -> Color:
	var probe: Control = ClassDB.instantiate(kind)
	probe.theme_type_variation = variation
	stage.add_child(probe)
	var c := probe.get_theme_color(item)
	probe.free()
	return c


func _near(a: Color, b: Color) -> bool:
	return a.is_equal_approx(b) or (absf(a.r - b.r) + absf(a.g - b.g) + absf(a.b - b.b) + absf(a.a - b.a)) < 0.01


func _between(v: Color, a: Color, b: Color) -> bool:
	return not _near(v, a) and not _near(v, b)


func _button_hover() -> void:
	var host := _host()
	var b := Button.new()
	b.text = "Recruit"
	b.theme_type_variation = &"ButtonSecondary"
	host.add_child(b)
	await _frames(2)
	var fade := _fade(b)
	check(fade != null and b.get_theme_stylebox("hover") == b.get_theme_stylebox("normal"), "a wired button draws every state through one live box")
	var normal := _theme_box("Button", &"ButtonSecondary", "normal")
	var hover := _theme_box("Button", &"ButtonSecondary", "hover")
	check(not _near(normal.bg_color, hover.bg_color), "(fixture) secondary normal and hover differ")
	check(_near(fade.box().bg_color, normal.bg_color), "at rest the live box is the theme's normal box")
	b.notification(Control.NOTIFICATION_MOUSE_ENTER)
	await _mid()
	check(b.get_draw_mode() == BaseButton.DRAW_HOVER and fade.state == "hover", "hover is picked up from the draw")
	check(_between(fade.box().bg_color, normal.bg_color, hover.bg_color), "a frame into hover the box is part way, not swapped")
	await _settle()
	check(_near(fade.box().bg_color, hover.bg_color), "the fade lands on the theme's hover box")
	b.notification(Control.NOTIFICATION_MOUSE_EXIT)
	await _mid()
	check(_between(fade.box().bg_color, normal.bg_color, hover.bg_color), "leaving hover fades back too")
	await _settle()
	check(_near(fade.box().bg_color, normal.bg_color), "and ends on normal")
	host.queue_free()


func _button_font_and_reduced() -> void:
	var host := _host()
	var b := Button.new()
	b.text = "Army"
	b.theme_type_variation = &"TabButton"
	host.add_child(b)
	await _frames(2)
	var fade := _fade(b)
	var muted := _theme_color("Button", &"TabButton", "font_color")
	var lit := _theme_color("Button", &"TabButton", "font_hover_color")
	b.notification(Control.NOTIFICATION_MOUSE_ENTER)
	await _mid()
	check(_between(b.get_theme_color("font_hover_color"), muted, lit), "the label colour crossfades as well")
	await _settle()
	check(_near(b.get_theme_color("font_hover_color"), lit), "and ends on the hover colour")
	ui.reduced_motion = true
	b.notification(Control.NOTIFICATION_MOUSE_EXIT)
	await _frames(1)
	check(_near(fade.font_color(), muted), "reduced motion: straight to the new state")
	ui.reduced_motion = false
	host.queue_free()


func _button_ring() -> void:
	var host := _host()
	var b := Button.new()
	b.text = "Ring"
	host.add_child(b)
	await _frames(2)
	var fade := _fade(b)
	var ring := _theme_box("Button", &"", "focus")
	check(fade.ring().border_color.a == 0.0, "no focus, no ring")
	b.grab_focus(true)
	await _frames(2)
	check(fade.ring().border_color.a == 0.0, "focus from a click keeps the ring clear")
	b.release_focus()
	await _frames(1)
	b.grab_focus(false)
	await _mid()
	check(fade.ring().border_color.a > 0.0 and fade.ring().border_color.a < ring.border_color.a, "keyboard focus fades the ring in")
	await _settle()
	check(_near(fade.ring().border_color, ring.border_color), "to the theme's focus ring")
	b.release_focus()
	host.queue_free()


func _button_theme_swap() -> void:
	var host := _host()
	var b := Button.new()
	b.text = "Swap"
	host.add_child(b)
	await _frames(2)
	var fade := _fade(b)
	stage.theme = light
	await _frames(3)
	var normal := _theme_box("Button", &"", "normal")
	check(_near(fade.box().bg_color, normal.bg_color), "a new theme above retargets the live box")
	stage.theme = dark
	await _frames(3)
	host.queue_free()


func _button_opt_outs() -> void:
	var host := _host()
	var skip := Button.new()
	skip.set_meta("wold_fade", false)
	host.add_child(skip)
	var off := VBoxContainer.new()
	stage.add_child(off)
	var fb := WoldFeedback.new()
	fb.fade_states = false
	off.add_child(fb)
	var plain := Button.new()
	off.add_child(plain)
	await _frames(2)
	check(_fade(skip) == null and skip.get_theme_stylebox("hover") != skip.get_theme_stylebox("normal"), "wold_fade = false leaves a button to the engine")
	check(_fade(plain) == null and plain.has_meta(WoldFeedback._WIRED), "fade_states = false: still wired for sound and motion, no fade")
	var wired := Button.new()
	host.add_child(wired)
	await _frames(2)
	check(_fade(wired) != null and wired.find_children("*", "BaseButton", true, false).is_empty(), "a faded button has no hidden helper buttons inside (game code searches for buttons)")
	var shy := Button.new()
	shy.set_meta("wold_feedback", false)
	var ob := OptionButton.new()
	shy.add_child(ob)
	host.add_child(shy)
	await _frames(1)
	check(not ob.has_meta(WoldFeedback._WIRED) and _fade(ob.get_popup()) == null, "wold_feedback = false covers what's inside the node too")
	host.queue_free()
	off.queue_free()


func _button_strip() -> void:
	var host := _host()
	var strip: WoldButtonStrip = load("res://addons/woldui/components/wold_button_strip/wold_button_strip.tscn").instantiate()
	for n in ["Left", "Mid", "Right"]:
		var sb := Button.new()
		sb.text = n
		strip.add_child(sb)
	host.add_child(strip)
	await _frames(3)
	var bs := strip.buttons()
	var first: Object = _fade(bs[0])
	var mid: Object = _fade(bs[1])
	check(first != null and mid != null, "(fixture) strip buttons are faded")
	var m: StyleBoxFlat = mid.box()
	var f: StyleBoxFlat = first.box()
	check(m.corner_radius_top_left == 0 and m.corner_radius_bottom_right == 0 and f.corner_radius_top_left > 0 and f.corner_radius_top_right == 0, "the strip squares inner corners through the fade")
	await _frames(5)
	check(mid.box().corner_radius_top_left == 0 and bs[1].get_theme_stylebox("hover") == bs[1].get_theme_stylebox("normal"), "and they stay squared, still one live box")
	host.queue_free()


# WoldButton restyles on every THEME_CHANGED; the fade must not keep that going
func _wold_button_settles() -> void:
	var host := _host()
	var b: WoldButton = load("res://addons/woldui/components/wold_button/wold_button.tscn").instantiate()
	b.icon_end = "chevron-right"
	host.add_child(b)
	await _frames(2)
	b.notification(Control.NOTIFICATION_MOUSE_ENTER)
	await _settle()
	var count := [0]
	b.theme_changed.connect(func(): count[0] += 1)
	await _frames(10)
	check(count[0] == 0, "a WoldButton goes quiet after a fade (no theme ping-pong)")
	check(_fade(b.get_children(true).filter(func(n): return n.name == &"WoldProbe").front()) == null, "WoldButton's own probe isn't faded")
	host.queue_free()


func _tab_container(host: Control) -> TabContainer:
	var tc := TabContainer.new()
	tc.custom_minimum_size = Vector2(400, 200)
	for n in ["Army", "Economy", "Research"]:
		var page := Control.new()
		page.name = n
		tc.add_child(page)
	host.add_child(tc)
	return tc


func _tabs() -> void:
	var host := _host()
	var tc := _tab_container(host)
	var solo := TabBar.new()
	solo.add_tab("One")
	host.add_child(solo)
	await _frames(3)
	var fade := _fade(tc)
	var bar := tc.get_tab_bar()
	check(fade != null and _fade(bar) == null and _fade(solo) != null, "TabContainer and a loose TabBar get a tab fade, the container's own bar doesn't")
	var hovered := _theme_box("TabContainer", &"", "tab_hovered")
	var muted := _theme_color("TabContainer", &"", "font_unselected_color")
	var lit := _theme_color("TabContainer", &"", "font_hovered_color")
	bar.tab_hovered.emit(1)
	check(_near(bar.get_theme_color("font_hovered_color"), muted), "the bar gets the start colour at once, before it draws (no flash)")
	await _mid()
	var hb: StyleBoxFlat = fade.hover_box()
	check(hb.border_color.a > 0.0 and hb.border_color.a < hovered.border_color.a, "a hovered tab's underline fades in")
	check(_between(bar.get_theme_color("font_hovered_color"), muted, lit), "its label crossfades on the bar straight away")
	await _settle()
	check(_near(fade.hover_box().border_color, hovered.border_color), "ending on the theme's hover look")
	bar.tab_hovered.emit(2)
	await _mid()
	var ghosts: Array = fade.ghosts()
	check(ghosts.size() == 1 and ghosts[0].tab == 1 and ghosts[0].a < 1.0 and ghosts[0].a > 0.0, "the tab the mouse left fades out as a ghost")
	await _settle()
	check(fade.ghosts().is_empty(), "the ghost goes once it's faded")
	host.queue_free()


func _tabs_select() -> void:
	var host := _host()
	var tc := _tab_container(host)
	await _frames(3)
	var fade := _fade(tc)
	var selected := _theme_box("TabContainer", &"", "tab_selected")
	tc.current_tab = 2
	await _mid()
	var ghosts: Array = fade.ghosts()
	check(ghosts.size() == 1 and ghosts[0].tab == 0, "the old tab's accent fades out as a ghost")
	var sb: StyleBoxFlat = fade.selected_box()
	check(sb.border_color.a < selected.border_color.a, "the new tab's accent fades in")
	await _settle()
	check(_near(fade.selected_box().border_color, selected.border_color) and fade.ghosts().is_empty(), "then it's the plain selected look")
	ui.reduced_motion = true
	tc.current_tab = 1
	await _frames(1)
	check(fade.ghosts().is_empty() and _near(fade.selected_box().border_color, selected.border_color), "reduced motion: tabs switch at once")
	ui.reduced_motion = false
	stage.theme = light
	await _frames(3)
	var light_sel := _theme_box("TabContainer", &"", "tab_selected")
	check(_near(fade.selected_box().border_color, light_sel.border_color), "a new theme retargets the tab boxes")
	stage.theme = dark
	await _frames(2)
	host.queue_free()


func _focus_fields() -> void:
	var host := _host()
	var edit := LineEdit.new()
	host.add_child(edit)
	var styled := LineEdit.new()
	var own := StyleBoxFlat.new()
	styled.add_theme_stylebox_override("focus", own)
	host.add_child(styled)
	var slider := HSlider.new()
	host.add_child(slider)
	await _frames(2)
	var fade := _fade(edit)
	var ring := _theme_box("LineEdit", &"", "focus")
	check(fade != null and _fade(slider) != null, "text fields and sliders get a focus fade")
	check(styled.get_theme_stylebox("focus") == own, "a hand-set focus box is left alone")
	edit.grab_focus(false)
	await _mid()
	check(fade.ring().border_color.a > 0.0 and fade.ring().border_color.a < ring.border_color.a, "keyboard focus on a field fades its ring in")
	await _settle()
	check(_near(fade.ring().border_color, ring.border_color), "to the theme's ring")
	edit.release_focus()
	await _frames(1)
	edit.grab_focus(true)
	await _frames(2)
	check(fade.ring().border_color.a == 0.0, "a clicked-in field shows no ring")
	edit.release_focus()
	host.queue_free()


func _popups() -> void:
	var host := _host()
	var ob := OptionButton.new()
	for n in ["Small", "Medium", "Large"]:
		ob.add_item(n)
	host.add_child(ob)
	var off := VBoxContainer.new()
	stage.add_child(off)
	var fb := WoldFeedback.new()
	fb.animate_popups = false
	off.add_child(fb)
	var still := OptionButton.new()
	still.add_item("One")
	off.add_child(still)
	await _frames(2)
	var popup := ob.get_popup()
	var fade := _fade(popup)
	check(fade != null, "an OptionButton's list is wired (internal child)")
	var pre := VBoxContainer.new()
	stage.add_child(pre)
	var early := OptionButton.new()
	early.add_item("One")
	pre.add_child(early)
	await _frames(1)
	pre.add_child(WoldFeedback.new())
	await _frames(1)
	check(_fade(early.get_popup()) != null, "so is the list of one that was there before the feedback")
	pre.queue_free()
	ob.show_popup()
	await _frames(1)
	var panel := WoldMotion.popup_panel(popup)
	check(panel.modulate.a < 1.0, "the list fades in when it opens")
	await create_timer(0.5).timeout
	check(is_equal_approx(panel.modulate.a, 1.0), "and finishes opaque")
	var hover := _theme_box("PopupMenu", &"", "hover")
	popup.set_focused_item(2)
	await _mid()
	var hl: StyleBoxFlat = fade.highlight()
	check(hl.bg_color.a > 0.0 and hl.bg_color.a < hover.bg_color.a, "a newly hovered row's highlight eases in")
	await _settle()
	check(_near(fade.highlight().bg_color, hover.bg_color), "to the theme's hover box")
	popup.hide()
	still.show_popup()
	await _frames(1)
	check(is_equal_approx(WoldMotion.popup_panel(still.get_popup()).modulate.a, 1.0), "animate_popups = false: the list just appears")
	still.get_popup().hide()
	# popup_max_height: a long dropdown scrolls instead of running off the screen
	var capped := VBoxContainer.new()
	stage.add_child(capped)
	var cap_fb := WoldFeedback.new()
	cap_fb.popup_max_height = 200
	capped.add_child(cap_fb)
	var long_list := OptionButton.new()
	for i in 60:
		long_list.add_item("Row %d" % i)
	capped.add_child(long_list)
	await _frames(2)
	long_list.show_popup()
	await _frames(2)
	check(long_list.get_popup().max_size.y == 200, "popup_max_height caps a list's height (max_size.y %d)" % long_list.get_popup().max_size.y)
	check(long_list.get_popup().size.y <= 200, "so a 60-row list is no taller than that (%d)" % long_list.get_popup().size.y)
	check(popup.max_size.y > 200, "a list under a WoldFeedback without a cap is left alone")
	long_list.get_popup().hide()
	capped.queue_free()
	var tip := PopupPanel.new()
	var words := Label.new()
	words.text = "Wood: 12"
	tip.add_child(words)
	host.add_child(tip)
	var plain_tip := PopupPanel.new()
	off.add_child(plain_tip)
	await _frames(1)
	tip.show()
	await _frames(1)
	var bg_panel: Control = tip.get_children(true).filter(func(n): return n is Panel).front()
	check(words.modulate.a < 1.0 and bg_panel.modulate.a < 1.0, "a PopupPanel (what tooltip_text makes) fades its box and content in on show()")
	check(_fade(plain_tip) == null, "animate_popups = false leaves PopupPanels alone")
	tip.hide()
	host.queue_free()
	off.queue_free()


func _native_checks() -> void:
	var host := _host()
	var box := CheckBox.new()
	box.text = "Fog"
	host.add_child(box)
	var sw := CheckButton.new()
	sw.text = "Music"
	host.add_child(sw)
	await _frames(2)
	check(box.get_theme_color("checkbox_checked_color") == Color.WHITE and sw.get_theme_color("button_checked_color") == Color.WHITE, "native check marks aren't tinted a second time (the icons carry their colour)")
	check(sw.get_theme_constant("icon_max_width") == 0, "CheckButton's switch isn't squashed by Button's icon_max_width")
	var fade := _fade(box)
	box.button_pressed = true
	await _mid()
	check(fade.mark_progress() > 0.0 and fade.mark_progress() < 1.0, "a CheckBox's new mark fades in over the old one")
	await _settle()
	check(fade.mark_progress() == 1.0, "and settles")
	ui.reduced_motion = true
	box.button_pressed = false
	await _frames(1)
	check(fade.mark_progress() == 1.0, "reduced motion: the mark just changes")
	ui.reduced_motion = false
	host.queue_free()


func _component_fades() -> void:
	var host := _host()
	var cb: WoldCheckbox = load("res://addons/woldui/components/wold_checkbox/wold_checkbox.tscn").instantiate()
	host.add_child(cb)
	var sw: WoldSwitch = load("res://addons/woldui/components/wold_switch/wold_switch.tscn").instantiate()
	host.add_child(sw)
	var card: WoldCard = load("res://addons/woldui/components/wold_card/wold_card.tscn").instantiate()
	card.selectable = true
	host.add_child(card)
	var dots: WoldPageDots = load("res://addons/woldui/components/wold_page_dots/wold_page_dots.tscn").instantiate()
	host.add_child(dots)
	await _frames(2)
	sw.mouse_entered.emit()
	cb.mouse_entered.emit()
	await _mid()
	check(sw.hot() > 0.0 and sw.hot() < 1.0 and cb.hot() > 0.0 and cb.hot() < 1.0, "switch and checkbox hover glows ease in")
	await _settle()
	check(sw.hot() == 1.0, "and reach full")
	cb.button_pressed = true
	await _mid()
	check(cb._mark > 0.0 and cb._mark < 1.0, "WoldCheckbox crossfades its mark")
	card.selected = true
	card.mouse_entered.emit()
	await _mid()
	check(card._sel > 0.0 and card._sel < 1.0 and card._hot > 0.0 and card._hot < 1.0, "a card's selected tint and hover ease in")
	dots._set_hot(1)
	await _mid()
	check(dots._lit[1] > 0.0 and dots._lit[1] < 1.0, "a page dot's hover eases in")
	await _settle()
	ui.reduced_motion = true
	card.selected = false
	sw.mouse_exited.emit()
	await _frames(1)
	check(card._sel == 0.0 and sw.hot() == 0.0, "reduced motion: component states jump")
	ui.reduced_motion = false
	host.queue_free()


func _flat(c: Color) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = c
	return sb


# the fades read the theme from under their own overrides
func _lookup() -> void:
	var host := _host()
	var local := Theme.new()
	local.set_type_variation("FadeProbe", "Button")
	local.set_stylebox("hover", "FadeProbe", _flat(Color.RED))
	local.set_type_variation("FadeProbeSm", "FadeProbe")
	host.theme = local
	var b := Button.new()
	b.theme_type_variation = &"FadeProbeSm"
	host.add_child(b)
	var own := Button.new()
	own.add_theme_stylebox_override("normal", _flat(Color.GREEN))
	host.add_child(own)
	await _frames(2)
	b.notification(Control.NOTIFICATION_MOUSE_ENTER)
	await _settle()
	check(_near(_fade(b).box().bg_color, Color.RED), "a variation of a variation still finds its base's hover box")
	check(_near(_fade(own).box().bg_color, Color.GREEN), "a hand-set override is what the button rests on")
	host.queue_free()


func _rereads() -> void:
	var host := _host()
	var edit := LineEdit.new()
	host.add_child(edit)
	var ob := OptionButton.new()
	ob.add_item("One")
	ob.add_item("Two")
	host.add_child(ob)
	await _frames(2)
	stage.theme = light
	await _frames(3)
	var ring := _theme_box("LineEdit", &"", "focus")
	var hover := _theme_box("PopupMenu", &"", "hover")
	edit.grab_focus(false)
	await _settle()
	check(_near(_fade(edit).ring().border_color, ring.border_color), "a field's ring follows a theme swap")
	edit.release_focus()
	ob.show_popup()
	await _frames(2)
	check(_near(_fade(ob.get_popup()).highlight().bg_color, hover.bg_color), "so does a list's row highlight")
	ob.get_popup().hide()
	stage.theme = dark
	await _frames(2)
	host.queue_free()
