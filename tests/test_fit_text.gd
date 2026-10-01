extends "res://addons/woldui/tests/wold_test_base.gd"
## WoldFitText and WoldButton.fit_text: shrink to the given width, truncate past the
## floor, give the size back when there is room, leave other tooltips alone.

var stage: Control


func _run() -> void:
	stage = Control.new()
	stage.theme = WoldThemeBuilder.build(tokens())
	get_root().add_child(stage)
	await _label()
	await _button()
	await _wold_button()
	await _tooltip()
	await _off()
	finish(20)


func _fixed_label(text: String, width: float) -> Label:
	var l := Label.new()
	l.text = text
	l.custom_minimum_size = Vector2(width, 0)
	l.size = Vector2(width, 30)
	l.set_anchors_preset(Control.PRESET_TOP_LEFT)
	stage.add_child(l)
	return l


func _settle() -> void:
	for i in 3:
		await process_frame


func _label() -> void:
	var l := _fixed_label("Quick join a lobby", 300.0)
	var fit := WoldFitText.new()
	l.add_child(fit)
	await _settle()
	var base := l.get_theme_font_size("font_size")
	check(not l.has_theme_font_size_override("font_size"), "text that fits keeps the theme size")
	l.text = "A much longer line than three hundred pixels can hold at the normal size"
	l.size = Vector2(300, 30)
	await _settle()
	var shrunk := l.get_theme_font_size("font_size")
	check(shrunk < base, "a long text shrinks (%d from %d)" % [shrunk, base])
	check(shrunk >= ceili(base * fit.min_scale), "...but not below the floor")
	check(l.tooltip_text == l.text, "past the floor the full text goes in the tooltip")
	check(l.text_overrun_behavior == TextServer.OVERRUN_TRIM_ELLIPSIS, "...and the label trims with an ellipsis")
	l.text = "Another line far too long for three hundred pixels, even at the smallest size"
	await _settle()
	check(l.tooltip_text == l.text, "a new text that is still too long updates the tooltip")
	l.text = "Short"
	await _settle()
	check(l.get_theme_font_size("font_size") == base, "a short text gets the full size back")
	check(l.tooltip_text == "", "...and our tooltip goes away")
	l.custom_minimum_size = Vector2.ZERO
	l.size = Vector2(80, 30)
	l.text = "Medium length text"
	await _settle()
	var narrow := l.get_theme_font_size("font_size")
	l.size = Vector2(300, 30)
	await _settle()
	check(l.get_theme_font_size("font_size") > narrow, "widening the label gives size back")
	# a fit that touches the font override on every pass redraws for ever
	var draws := [0]
	l.draw.connect(func(): draws[0] += 1)
	for i in 10:
		await process_frame
	check(draws[0] <= 1, "the fit settles instead of redrawing every frame (%d draws in 10 frames)" % draws[0])
	l.queue_free()


func _button() -> void:
	var b := Button.new()
	b.text = "Resize the whole map now"
	b.size = Vector2(120, 40)
	stage.add_child(b)
	var fit := WoldFitText.new()
	b.add_child(fit)
	await _settle()
	check(b.clip_text, "the text stops deciding the button's minimum width")
	check(b.get_theme_font_size("font_size") < b.get_theme_default_font_size() or b.has_theme_font_size_override("font_size"),
			"a button too narrow for its text shrinks it")
	var narrow_min := b.get_minimum_size().x
	check(narrow_min < 100.0, "...and reports a small minimum width (%d)" % int(narrow_min))
	b.queue_free()


func _wold_button() -> void:
	var b := WoldButton.new()
	b.text = "Resize the whole map now"
	b.fit_text = true
	b.custom_minimum_size = Vector2(110, 0)
	b.size = Vector2(110, 40)
	stage.add_child(b)
	await _settle()
	check(b.clip_text and b.has_theme_font_size_override("font_size"), "WoldButton.fit_text shrinks the text")
	b.fit_text = false
	await _settle()
	check(not b.has_theme_font_size_override("font_size") and not b.clip_text, "turning it off restores the button")
	b.queue_free()


func _tooltip() -> void:
	var l := _fixed_label("Some text that is far too long for this little label to hold", 60.0)
	l.tooltip_text = "Mine"
	l.add_child(WoldFitText.new())
	await _settle()
	check(l.tooltip_text == "Mine", "a tooltip the author set is not replaced")
	l.queue_free()


func _off() -> void:
	var l := _fixed_label("Some text that is far too long for this little label", 80.0)
	var fit := WoldFitText.new()
	l.add_child(fit)
	await _settle()
	check(l.has_theme_font_size_override("font_size"), "premise: it shrank")
	fit.enabled = false
	await _settle()
	check(not l.has_theme_font_size_override("font_size"), "enabled = false gives the size back")
	check(not l.clip_text and l.text_overrun_behavior == TextServer.OVERRUN_NO_TRIMMING, "...and the label its own clipping and overrun")
	fit.enabled = true
	await _settle()
	check(l.has_theme_font_size_override("font_size"), "...and turning it back on fits again")
	l.queue_free()
