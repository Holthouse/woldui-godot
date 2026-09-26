extends "res://addons/woldui/tests/wold_test_base.gd"
## prompts: glyph per key/pad/family, live device switch, fallbacks, hide_on_mouse, custom art.

const SCENE := "res://addons/woldui/components/wold_button_prompt/wold_button_prompt.tscn"
const ACTION := &"wold_test_confirm"

var ui: WoldUIRuntime
var stage: Control


func _run() -> void:
	ui = WoldUIRuntime.instance()
	stage = Control.new()
	stage.theme = WoldThemeBuilder.build(tokens())
	get_root().add_child(stage)
	_mapping()
	_bind()
	await _live_switching()
	await _fallbacks_and_hiding()
	await _own_art()
	finish(27)


func _key(code: Key, physical := false) -> InputEventKey:
	var e := InputEventKey.new()
	if physical:
		e.physical_keycode = code
	else:
		e.keycode = code
	return e


func _pad(button: JoyButton) -> InputEventJoypadButton:
	var e := InputEventJoypadButton.new()
	e.button_index = button
	return e


func _mapping() -> void:
	var X := WoldPrompts.Family.XBOX
	var P := WoldPrompts.Family.PLAYSTATION
	var N := WoldPrompts.Family.NINTENDO
	var g := WoldPrompts.glyph_for(_key(KEY_E))
	check(g.shape == "key" and g.text == "E" and g.art == "prompt_key_e", "a letter key is a keycap with its letter")
	check(WoldPrompts.glyph_for(_key(KEY_ESCAPE)).text == "Esc", "long key names are shortened (Esc)")
	check(WoldPrompts.glyph_for(_key(KEY_UP)).icon == "arrow-up", "arrow keys draw an arrow")
	check(WoldPrompts.glyph_for(_key(KEY_Q, true)).text != "" and WoldPrompts.glyph_for(_key(KEY_Q, true)).text != "?", "a physical-key binding still shows a label")
	var a := _pad(JOY_BUTTON_A)
	check(WoldPrompts.glyph_for(a, X).shape == "face" and WoldPrompts.glyph_for(a, X).text == "A", "Xbox: the bottom face button is A")
	check(WoldPrompts.glyph_for(a, P).icon == "x" and WoldPrompts.glyph_for(a, P).art == "prompt_ps_cross", "PlayStation: it is the cross")
	check(WoldPrompts.glyph_for(a, N).text == "B", "Nintendo: it is B (the letters are swapped)")
	check(WoldPrompts.glyph_for(_pad(JOY_BUTTON_Y), P).icon == "triangle", "PlayStation Y is the triangle")
	var lb := WoldPrompts.glyph_for(_pad(JOY_BUTTON_LEFT_SHOULDER), X)
	check(lb.shape == "pill" and lb.text == "LB", "shoulders are pills (LB)")
	check(WoldPrompts.glyph_for(_pad(JOY_BUTTON_LEFT_SHOULDER), P).text == "L1", "PlayStation shoulders are L1")
	var trig := InputEventJoypadMotion.new()
	trig.axis = JOY_AXIS_TRIGGER_RIGHT
	check(WoldPrompts.glyph_for(trig, X).text == "RT" and WoldPrompts.glyph_for(trig, N).text == "ZR", "triggers: RT / ZR")
	check(WoldPrompts.glyph_for(_pad(JOY_BUTTON_DPAD_LEFT), X).icon == "arrow-left", "the d-pad draws arrows")
	var mouse := InputEventMouseButton.new()
	mouse.button_index = MOUSE_BUTTON_RIGHT
	check(WoldPrompts.glyph_for(mouse).shape == "icon" and WoldPrompts.glyph_for(mouse).icon == "mouse-right", "mouse buttons are mouse icons")


func _bind() -> void:
	if InputMap.has_action(ACTION):
		InputMap.erase_action(ACTION)
	InputMap.add_action(ACTION)
	InputMap.action_add_event(ACTION, _key(KEY_E))
	InputMap.action_add_event(ACTION, _pad(JOY_BUTTON_A))
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	InputMap.action_add_event(ACTION, click)


func _prompt() -> WoldButtonPrompt:
	var p: WoldButtonPrompt = load(SCENE).instantiate()
	p.action = ACTION
	p.pad_family = WoldButtonPrompt.PadFamily.XBOX
	stage.add_child(p)
	return p


func _live_switching() -> void:
	var p := _prompt()
	await process_frame
	check(p.size.x > 0.0 and (p.get_node("%Label") as Label).text == "Confirm", "the scene instantiates with its label")
	var key := InputEventKey.new()
	key.pressed = true
	ui.note_input(key)
	check(p.glyph.text == "E", "on the keyboard it shows the key bound to the action")
	var pad := InputEventJoypadButton.new()
	pad.pressed = true
	ui.note_input(pad)
	check(p.glyph.shape == "face" and p.glyph.text == "A", "picking up a pad switches it to the pad button, live")
	ui.note_input(InputEventMouseButton.new())
	check(p.glyph.icon == "mouse-left", "with the mouse it shows the mouse button")
	p.pad_family = WoldButtonPrompt.PadFamily.PLAYSTATION
	p.input_kind = WoldButtonPrompt.InputKind.PAD
	check(p.glyph.icon == "x", "input_kind pins the device; pad_family picks the symbols")
	InputMap.action_erase_events(ACTION)
	InputMap.action_add_event(ACTION, _pad(JOY_BUTTON_Y))
	p.refresh()
	check(p.glyph.icon == "triangle", "refresh() follows a rebinding")
	_bind()
	check((p.get_node("%Glyph") as Control).get_combined_minimum_size().y == float(stage.theme.get_constant("height", "PromptGlyph")), "the glyph is the token height")
	p.queue_free()


func _fallbacks_and_hiding() -> void:
	var p := _prompt()
	InputMap.action_erase_events(ACTION)
	InputMap.action_add_event(ACTION, _key(KEY_SPACE))
	p.input_kind = WoldButtonPrompt.InputKind.PAD
	await process_frame
	check(p.glyph.shape == "key" and p.glyph.text == "Space", "no pad binding: it falls back to the key")
	p.action = &"no_such_action"
	check(p.glyph.text == "?", "an unknown action shows ?, not an empty space")
	_bind()
	p.action = ACTION
	p.input_kind = WoldButtonPrompt.InputKind.AUTO
	p.hide_on_mouse = true
	ui.note_input(InputEventMouseButton.new())
	check(not p.visible, "hide_on_mouse hides it under the mouse")
	var key := InputEventKey.new()
	key.pressed = true
	ui.note_input(key)
	check(p.visible, "and shows it again on the keyboard")
	var tap := InputEventScreenTouch.new()
	tap.pressed = true
	ui.note_input(tap)
	check(not p.visible, "a finger counts as the mouse here too")
	ui.note_input(InputEventMouseButton.new())
	p.queue_free()


func _own_art() -> void:
	var art := ImageTexture.create_from_image(Image.create(32, 32, false, Image.FORMAT_RGBA8))
	var t := tokens().derive({})
	t.icon_set = WoldIconSet.new()
	t.icon_set.icons = {"prompt_xbox_a": art}
	var before := ui.tokens
	ui.tokens = t
	var p := _prompt()
	p.input_kind = WoldButtonPrompt.InputKind.PAD
	await process_frame
	check((p.get_node("%Glyph") as WoldPromptGlyph).art == art, "a game's own glyph art replaces the drawn glyph")
	p.pad_family = WoldButtonPrompt.PadFamily.NINTENDO
	check((p.get_node("%Glyph") as WoldPromptGlyph).art == null, "only for the glyphs it supplies")
	ui.tokens = before
	p.queue_free()
