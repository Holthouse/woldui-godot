@tool
extends VBoxContainer
## Editor dock: pick the tokens file, rebuild, set as project theme, preview
## colours + contrast. Uses the editor theme, not ours.

var plugin: EditorPlugin

var _path_label: Label
var _status: Label
var _auto: CheckBox
var _swatches: VBoxContainer
var _file_dialog: EditorFileDialog
var _own_copy: Button

const OWN_COPY := "res://design_system.tres"


func _ready() -> void:
	add_theme_constant_override("separation", 6)

	var main := _button("Edit design system", _edit_tokens)
	main.tooltip_text = "Opens the tokens in the Inspector: colours, fonts, sizes, spacing, motion, sounds and feedback for the whole game. The theme rebuilds as you change them."
	add_child(main)
	var hint := _caption("One file for the whole look. To change a single control, select it and use Customize at the top of its Inspector.")
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(hint)
	_own_copy = _button("Make it this project's own copy", _make_own_copy)
	_own_copy.tooltip_text = "The tokens in use are the ones that ship inside the addon, and an update would overwrite your changes. This copies them to %s and switches to the copy." % OWN_COPY
	add_child(_own_copy)

	var path_row := HBoxContainer.new()
	add_child(path_row)
	_path_label = Label.new()
	_path_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_path_label.clip_text = true
	path_row.add_child(_path_label)
	path_row.add_child(_button("Change…", _choose_tokens))

	var actions := HFlowContainer.new()
	add_child(actions)
	actions.add_child(_button("Rebuild theme", _rebuild))
	actions.add_child(_button("Use as project theme", _use_as_project))
	actions.add_child(_button("Open gallery", func(): plugin.open_gallery()))
	actions.add_child(_button("New variant…", _new_variant))

	_auto = CheckBox.new()
	_auto.text = "Rebuild on every token edit"
	_auto.toggled.connect(func(on):
		ProjectSettings.set_setting(plugin.SETTING_AUTO, on)
		ProjectSettings.save())
	add_child(_auto)

	_status = Label.new()
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(_status)

	var tabs := TabContainer.new()
	tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(tabs)
	var scroll := ScrollContainer.new()
	scroll.name = "Colours"
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	tabs.add_child(scroll)
	_swatches = VBoxContainer.new()
	_swatches.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_swatches)
	tabs.add_child(_icon_browser())
	tabs.add_child(_motion_and_sound())

	_file_dialog = EditorFileDialog.new()
	_file_dialog.file_mode = EditorFileDialog.FILE_MODE_OPEN_FILE
	_file_dialog.add_filter("*.tres", "WoldTokens")
	_file_dialog.file_selected.connect(func(path):
		if load(path) is WoldTokens:
			plugin.set_tokens_path(path)
		else:
			_say("%s is not a WoldTokens resource." % path))
	add_child(_file_dialog)
	refresh()


func refresh() -> void:
	if not is_inside_tree() or plugin == null:
		return
	_path_label.text = plugin.tokens_path()
	_path_label.tooltip_text = "Tokens: %s\nGenerated theme: %s" % [plugin.tokens_path(), plugin.theme_path()]
	_auto.set_pressed_no_signal(ProjectSettings.get_setting(plugin.SETTING_AUTO, true))
	_own_copy.visible = plugin.tokens_path().begins_with("res://addons/woldui/")
	var t: WoldTokens = plugin.tokens()
	if t == null:
		_say("No WoldTokens at %s. Pick a file with Change…" % plugin.tokens_path())
		return
	if plugin.is_project_theme():
		_say("Project theme: %s" % plugin.theme_path().get_file())
	else:
		_say("The project does not use this theme yet. Press \"Use as project theme\".")
	_draw_swatches(t)


func _draw_swatches(t: WoldTokens) -> void:
	for child in _swatches.get_children():
		child.queue_free()
	_swatches.add_child(_caption("Ramps (50 → 950)"))
	for tone in ["neutral", "accent", "success", "warning", "danger"]:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 0)
		var ramp := t.ramp(tone)
		for step in WoldColor.STEPS:
			var chip := ColorRect.new()
			chip.color = ramp[step]
			chip.custom_minimum_size = Vector2(16, 16)
			chip.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			chip.tooltip_text = "%s %d  #%s" % [tone, step, ramp[step].to_html(false)]
			row.add_child(chip)
		_swatches.add_child(row)
	_swatches.add_child(_caption("Roles (contrast on surface_raised)"))
	var bg := t.role("surface_raised")
	for role in t.role_names():
		var row := HBoxContainer.new()
		var chip := ColorRect.new()
		chip.color = t.role(role)
		chip.custom_minimum_size = Vector2(28, 16)
		row.add_child(chip)
		var name_label := Label.new()
		name_label.text = role
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(name_label)
		var ratio := WoldColor.contrast(t.role(role), bg)
		var ratio_label := Label.new()
		ratio_label.text = "%.1f:1" % ratio
		ratio_label.tooltip_text = "WCAG: 4.5 for body text, 3.0 for large text and UI parts"
		row.add_child(ratio_label)
		_swatches.add_child(row)


# icon search, click to copy the name
func _icon_browser() -> Control:
	var page := VBoxContainer.new()
	page.name = "Icons"
	var search := LineEdit.new()
	search.placeholder_text = "Search %d icons…" % WoldIcons.names().size()
	search.clear_button_enabled = true
	page.add_child(search)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	page.add_child(scroll)
	var grid := HFlowContainer.new()
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(grid)
	var tint := EditorInterface.get_editor_theme().get_color("font_color", "Editor")
	var fill := func(query: String) -> void:
		for child in grid.get_children():
			child.queue_free()
		var names := PackedStringArray()
		var t: WoldTokens = plugin.tokens() if plugin else null
		if t and t.icon_set:
			for n in t.icon_set.custom_names():
				if query == "" or n.contains(query.to_lower()):
					names.append(n)
		names.append_array(WoldIcons.search(query, 240))
		for n in names:
			var b := Button.new()
			b.flat = true
			b.icon = t.icon(n) if t else WoldIcons.texture(n, 20)
			b.add_theme_color_override("icon_normal_color", tint)
			b.tooltip_text = n
			b.pressed.connect(func():
				DisplayServer.clipboard_set(n)
				_say("Copied \"%s\" to the clipboard." % n))
			grid.add_child(b)
	search.text_changed.connect(fill)
	fill.call("")
	return page


# play presets on a sample card and try the sound slots. Clicking a preset
# opens it in the Inspector
func _motion_and_sound() -> Control:
	var scroll := ScrollContainer.new()
	scroll.name = "Motion & sound"
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var page := VBoxContainer.new()
	page.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(page)

	var player := AudioStreamPlayer.new()
	page.add_child(player)

	var stage := Panel.new()
	stage.custom_minimum_size = Vector2(0, 90)
	stage.clip_contents = true
	page.add_child(stage)
	var card := Button.new()
	card.text = "Sample"
	card.custom_minimum_size = Vector2(110, 40)
	card.set_anchors_and_offsets_preset(Control.PRESET_CENTER, Control.PRESET_MODE_KEEP_SIZE)
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stage.add_child(card)

	page.add_child(_caption("Motion presets (▶ plays, name opens it)"))
	for preset_name in WoldMotion.preset_names():
		var row := HBoxContainer.new()
		var play := Button.new()
		play.text = "▶"
		play.tooltip_text = "Play %s on the sample" % preset_name
		play.pressed.connect(func():
			var p := WoldMotion.preset(preset_name)
			card.text = preset_name
			if preset_name.contains("disappear") or preset_name.ends_with("_out") or preset_name.ends_with("_exit"):
				await WoldMotion.disappear(card, p).finished
				await get_tree().create_timer(0.3).timeout
				card.visible = true
			else:
				card.visible = false
				WoldMotion.appear(card, p))
		row.add_child(play)
		var open := Button.new()
		open.text = preset_name
		open.flat = true
		open.alignment = HORIZONTAL_ALIGNMENT_LEFT
		open.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		open.pressed.connect(func(): EditorInterface.edit_resource(WoldMotion.preset(preset_name)))
		row.add_child(open)
		page.add_child(row)

	page.add_child(_caption("Sound slots (▶ plays; empty = built-in)"))
	for slot in WoldSoundSet.SLOTS:
		var row := HBoxContainer.new()
		var play := Button.new()
		play.text = "▶"
		play.pressed.connect(func():
			var t: WoldTokens = plugin.tokens()
			var stream: AudioStream = t.sounds.stream(slot) if t and t.sounds else null
			var builtin := stream == null
			if builtin:
				stream = WoldSounds.builtin().stream(slot)
			player.stream = stream
			player.play()
			_say("%s: %s" % [slot, "built-in" if builtin else stream.resource_path.get_file()]))
		row.add_child(play)
		var label := Label.new()
		label.text = slot
		row.add_child(label)
		page.add_child(row)
	return scroll


func _choose_tokens() -> void:
	_file_dialog.current_path = plugin.tokens_path()
	_file_dialog.popup_file_dialog()


func _edit_tokens() -> void:
	var t: WoldTokens = plugin.tokens()
	if t:
		EditorInterface.edit_resource(t)


func _rebuild() -> void:
	var err: String = plugin.rebuild()
	_say(err if err != "" else "Rebuilt %s." % plugin.theme_path().get_file())


func _use_as_project() -> void:
	var err: String = plugin.use_as_project_theme()
	_say(err if err != "" else "Every Control now uses %s." % plugin.theme_path().get_file())


# blank variant, the rest gets filled in via the Inspector
func _new_variant() -> void:
	var t: WoldTokens = plugin.tokens()
	if t == null:
		return
	var v := WoldVariant.new()
	v.name = "NewVariant%d" % (t.variants.size() + 1)
	v.base = "ButtonPrimary"
	t.variants.append(v)
	ResourceSaver.save(t, t.resource_path)
	EditorInterface.edit_resource(v)
	_say("Added %s to the tokens. Set its base and token overrides in the Inspector." % v.name)
	plugin.rebuild()


func _button(text: String, action: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.pressed.connect(action)
	return b


func _caption(text: String) -> Label:
	var l := Label.new()
	l.text = text
	l.modulate = Color(1, 1, 1, 0.7)
	return l


func _say(text: String) -> void:
	_status.text = text


func _make_own_copy() -> void:
	var t: WoldTokens = plugin.tokens()
	if t == null:
		return
	if ResourceLoader.exists(OWN_COPY):
		_say("%s already exists; pick it with Change… or move it first." % OWN_COPY)
		return
	var copy := t.duplicate(true) as WoldTokens
	var err := ResourceSaver.save(copy, OWN_COPY)
	if err != OK:
		_say("Could not save %s (error %d)" % [OWN_COPY, err])
		return
	EditorInterface.get_resource_filesystem().scan()
	ProjectSettings.set_setting(plugin.SETTING_TOKENS, OWN_COPY)
	ProjectSettings.save()
	var msg: String = plugin.use_as_project_theme()
	_say(msg if msg != "" else "Now using %s. Edit design system opens it." % OWN_COPY)
	EditorInterface.edit_resource(load(OWN_COPY))
