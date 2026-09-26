extends "res://addons/woldui/tests/wold_test_base.gd"
## WoldAlert: tones, icons, text, action slot, dismissing, contrast, saving.

const SCENE := "res://addons/woldui/components/wold_alert/wold_alert.tscn"

var stage: VBoxContainer


func _run() -> void:
	get_root().size = Vector2i(1280, 720)
	stage = VBoxContainer.new()
	stage.size = Vector2(600, 600)
	stage.theme = WoldThemeBuilder.build(tokens())
	get_root().add_child(stage)
	await _tones()
	await _parts()
	await _dismiss()
	for path in ["res://addons/woldui/tokens/default_dark.tres", "res://addons/woldui/tokens/default_light.tres"]:
		_contrast(path)
	await _saved_scene()
	var treaty: WoldAlert = load("res://addons/woldui/gallery/examples/treaty_alert.tscn").instantiate()
	stage.add_child(treaty)
	await _frames()
	check(treaty.tone == WoldAlert.Tone.DANGER and treaty.get_node("%Action").visible and treaty.get_node("%Close").visible, "TreatyAlert: danger, with its action and a close button")
	treaty.queue_free()
	finish(13)


func _alert() -> WoldAlert:
	var a: WoldAlert = load(SCENE).instantiate()
	stage.add_child(a)
	return a


func _frames() -> void:
	await process_frame
	await process_frame


func _tones() -> void:
	var t := tokens()
	var a := _alert()
	await _frames()
	var sb := a.get_theme_stylebox("panel") as StyleBoxFlat
	check(a.theme_type_variation == &"AlertWarning" and sb.bg_color == t.role("warning_soft") and sb.border_color == t.role("warning"), "warning: soft warning fill and edge")
	check((a.get_node("%Icon") as TextureRect).texture == t.icon("triangle-alert") and a.get_node("%Icon").self_modulate == t.role("warning_text"), "with the warning icon in warning text colour")
	a.tone = WoldAlert.Tone.DANGER
	await _frames()
	check((a.get_theme_stylebox("panel") as StyleBoxFlat).border_color == t.role("danger") and a.get_node("%Icon").self_modulate == t.role("danger_text"), "tone changes restyle it")
	a.icon = "skull"
	check((a.get_node("%Icon") as TextureRect).texture == t.icon("skull"), "a custom icon wins")
	a.queue_free()


func _parts() -> void:
	var a := _alert()
	await _frames()
	check(not a.get_node("%Action").visible and not a.get_node("%Close").visible, "no action row or close button until asked for")
	var b := Button.new()
	b.text = "Open city"
	a.get_node("%Action").add_child(b)
	a.description = ""
	await _frames()
	check(a.get_node("%Action").visible and not a.get_node("%Description").visible, "a button in %Action shows the row; no description, no line")
	a.queue_free()


func _dismiss() -> void:
	WoldUIRuntime.instance().reduced_motion = true
	var a := _alert()
	a.dismissible = true
	await _frames()
	var close := a.get_node("%Close") as Button
	check(close.visible and close.icon != null, "dismissible adds a close button")
	var said := []
	a.closed.connect(func(): said.append(true))
	close.pressed.emit()
	await _frames()
	check(not a.visible and said == [true], "closing hides it and says so")
	a.free_on_close = true
	a.visible = true
	a.close()
	await _frames()
	check(not is_instance_valid(a), "free_on_close frees it")
	WoldUIRuntime.instance().reduced_motion = false


func _contrast(path: String) -> void:
	var t := tokens(path)
	var worst := 99.0
	for tone in ["accent", "success", "warning", "danger"]:
		var bg := t.role("surface_raised").blend(t.role(tone + "_soft"))
		worst = minf(worst, WoldColor.contrast(t.role("text_muted"), bg))
	check(worst >= 4.5, "%s: the description reads on every tint (worst %.2f:1)" % [path.get_file(), worst])


func _saved_scene() -> void:
	var host := VBoxContainer.new()
	stage.add_child(host)
	var a: WoldAlert = load(SCENE).instantiate()
	host.add_child(a)
	a.owner = host
	a.tone = WoldAlert.Tone.SUCCESS
	await _frames()
	var packed := PackedScene.new()
	packed.pack(host)
	var state := packed.get_state()
	var saved := {}
	for i in state.get_node_property_count(1):
		saved[state.get_node_property_name(1, i)] = true
	check(not saved.has("theme_type_variation") and saved.has("tone"), "saves the tone, not the style it picks (saved: %s)" % [saved.keys()])
	host.queue_free()
