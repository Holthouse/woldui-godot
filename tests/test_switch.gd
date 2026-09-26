extends "res://addons/woldui/tests/wold_test_base.gd"
## WoldSwitch: layout, the slide, reduced motion, disabled look, saved scenes.
## Also the drawn CheckBox / CheckButton icons from toggle_recipe.

const SCENE := "res://addons/woldui/components/wold_switch/wold_switch.tscn"

var stage: VBoxContainer


func _run() -> void:
	get_root().size = Vector2i(1280, 720)
	stage = VBoxContainer.new()
	stage.size = Vector2(600, 600)
	stage.theme = WoldThemeBuilder.build(tokens())
	get_root().add_child(stage)
	await _layout()
	await _slide()
	await _reduced()
	await _disabled()
	await _engine_icons()
	await _saved_scene()
	await _example()
	finish(26)


func _switch() -> WoldSwitch:
	var s: WoldSwitch = load(SCENE).instantiate()
	stage.add_child(s)
	return s


func _layout() -> void:
	var s := _switch()
	await process_frame
	check(s is Button and s.toggle_mode and s.focus_mode == Control.FOCUS_ALL, "a switch is a focusable toggle Button")
	s.label = "Music"
	check(s.text == "" and (s.get_node("%Label") as Label).text == "Music", "the label lives in %Label, not Button.text")
	s.label = "Show hex grid"
	var track := s.track_rect()
	var content := s.get_node("%Content") as Control
	check(track.position.x >= 0.0 and track.end.x < content.position.x, "the track sits left of the text")
	var bare := _switch()
	bare.label = ""
	bare.description = ""
	await process_frame
	var pad := bare.get_theme_stylebox("normal").get_minimum_size().y
	check(bare.size.y >= track.size.y + pad, "with no text at all it still fits its track (%.0f px)" % bare.size.y)
	bare.queue_free()
	var lbl := s.get_node("%Label") as Control
	var label_mid := content.position.y + lbl.position.y + lbl.size.y / 2.0
	check(absf(track.get_center().y - label_mid) < 1.0, "with a description the track lines up with the label, not the middle")
	s.description = ""
	await process_frame
	check(not s.get_node("%Description").visible, "no description, no line")
	check(absf(s.track_rect().get_center().y - s.size.y / 2.0) < 1.0, "without one the track is centred")
	var h := s.size.y
	s.description = "A long second line that makes the switch taller."
	await process_frame
	check(s.size.y > h, "the switch grows with its content")
	var fb := WoldFeedback.new()
	stage.add_child(fb)
	await process_frame
	check(s.has_meta(WoldFeedback._WIRED), "WoldFeedback wires switches like any button")
	fb.queue_free()
	s.queue_free()


func _slide() -> void:
	WoldUIRuntime.instance().reduced_motion = false
	var s := _switch()
	await process_frame
	check(s.knob_position() == 0.0, "off: the knob is on the left")
	s.button_pressed = true
	await process_frame
	var k := s.knob_position()
	check(k > 0.0 and k < 1.0, "turning it on slides the knob (at %.2f one frame in)" % k)
	await create_timer(tokens().duration_fast + 0.1).timeout
	check(s.knob_position() == 1.0, "and it lands on the right")
	s.queue_free()


func _reduced() -> void:
	WoldUIRuntime.instance().reduced_motion = true
	var s := _switch()
	await process_frame
	s.button_pressed = true
	check(s.knob_position() == 1.0, "reduced motion: the knob jumps")
	await process_frame
	await process_frame
	check(s.knob_position() == 1.0 and not s._sliding, "and it stays there")
	WoldUIRuntime.instance().reduced_motion = false
	s.queue_free()


func _disabled() -> void:
	var t := tokens()
	var s := _switch()
	await process_frame
	var lbl := s.get_node("%Label") as Label
	check(lbl.get_theme_color("font_color") == t.role("text"), "the label reads in the text colour")
	s.disabled = true
	await process_frame
	await process_frame
	check(lbl.get_theme_color("font_color") == t.role("text_disabled"), "disabling the switch dims its label")
	check((s.get_node("%Description") as Label).get_theme_color("font_color") == t.role("text_disabled"), "and its description")
	s.disabled = false
	await process_frame
	await process_frame
	check(lbl.get_theme_color("font_color") == t.role("text"), "and enabling it brings them back")
	s.queue_free()


func _engine_icons() -> void:
	var cb := CheckBox.new()
	cb.text = "Plain"
	stage.add_child(cb)
	var sw := CheckButton.new()
	stage.add_child(sw)
	await process_frame
	var engine := ThemeDB.get_default_theme()
	check(cb.get_theme_icon("checked") is DPITexture and cb.get_theme_icon("checked") != engine.get_icon("checked", "CheckBox"), "a plain CheckBox gets the drawn icons")
	check(cb.has_theme_icon("indeterminate") and cb.get_theme_icon("indeterminate") is DPITexture, "including the mixed state")
	check(sw.get_theme_icon("checked") is DPITexture and sw.get_theme_icon("checked").get_width() == toggle_width(), "a plain CheckButton looks like the switch")
	cb.queue_free()
	sw.queue_free()


func toggle_width() -> int:
	return preload("res://addons/woldui/theme/recipes/toggle_recipe.gd").switch_width(tokens())


func _saved_scene() -> void:
	var host := VBoxContainer.new()
	stage.add_child(host)
	var s: WoldSwitch = load(SCENE).instantiate()
	host.add_child(s)
	s.owner = host
	s.label = "Subtitles"
	await process_frame
	var packed := PackedScene.new()
	packed.pack(host)
	var state := packed.get_state()
	var saved := {}
	for i in state.get_node_property_count(1):
		saved[state.get_node_property_name(1, i)] = true
	check(not saved.has("custom_minimum_size") and not saved.has("toggle_mode") and not saved.has("text"), "derived size, toggle mode and text are not saved (saved: %s)" % [saved.keys()])
	var again := packed.instantiate()
	stage.add_child(again)
	await process_frame
	var copy := again.get_child(0) as WoldSwitch
	check((copy.get_node("%Label") as Label).text == "Subtitles" and copy.custom_minimum_size.y > 0.0, "it rebuilds from its props on load")
	host.queue_free()
	again.queue_free()


func _example() -> void:
	var ui := WoldUIRuntime.instance()
	ui.reduced_motion = true
	var s: WoldSwitch = load("res://addons/woldui/gallery/examples/motion_switch.tscn").instantiate()
	stage.add_child(s)
	await process_frame
	check(s.button_pressed and s.knob_position() == 1.0, "MotionSwitch starts from the saved preference")
	var hooked := s.toggled.get_connections().filter(func(c): return c.callable.get_method() == &"_on_toggled")
	# the inherited scene sets the script twice, once per level
	check(hooked.size() == 1 and s.get_child_count(true) - s.get_child_count() == 1, "an inherited switch is wired once (%d toggled hooks, %d internal nodes)" % [hooked.size(), s.get_child_count(true) - s.get_child_count()])
	s.button_pressed = false
	check(not ui.reduced_motion, "flipping it writes the preference back")
	s.queue_free()
