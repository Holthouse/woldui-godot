extends "res://addons/woldui/tests/wold_test_base.gd"
## textured fills keep their shape as the value moves (TILE on resize too)


func _run() -> void:
	_geometry()
	await _meter()
	await _slider()
	await _vslider()
	await _subclassed()
	await _meter_directions()
	finish(34)


func _texture(w: int, h: int) -> Texture2D:
	return ImageTexture.create_from_image(Image.create(w, h, false, Image.FORMAT_RGBA8))


## px per texel
func _scale(f: WoldFill, width: float, ratio: float) -> float:
	var track := Rect2(0, 0, width, 12)
	return f.plan(track, Rect2(0, 0, width * ratio, 12)).scale


func _geometry() -> void:
	var f := WoldFill.new()
	f.texture = _texture(16, 12)
	f.mode = WoldFill.Mode.TILE
	check(_scale(f, 300, 0.3) == _scale(f, 300, 0.8), "TILE: the pattern keeps its scale as the value changes")
	check(_scale(f, 300, 0.5) == _scale(f, 600, 0.5), "TILE: the pattern keeps its scale when the control is resized")
	f.tile_scale = 2.0
	check(_scale(f, 300, 0.4) == 2.0, "TILE: tile_scale sets the pixel scale")

	f.mode = WoldFill.Mode.REVEAL
	check(is_equal_approx(_scale(f, 300, 0.3), _scale(f, 300, 0.8)), "REVEAL: the image keeps its scale as the value changes")
	var half: Rect2 = f.plan(Rect2(0, 0, 300, 12), Rect2(0, 0, 150, 12)).src
	check(is_equal_approx(half.size.x, 8.0), "REVEAL: half the value shows half the image, not a squashed whole")
	check(half.position == Vector2.ZERO, "REVEAL: the image is revealed from the start of the track")

	# control case: STRETCH does squash, so the checks above can actually fail
	f.mode = WoldFill.Mode.STRETCH
	check(not is_equal_approx(_scale(f, 300, 0.3), _scale(f, 300, 0.8)), "STRETCH squashes with the value (so the checks above are not vacuous)")


func _meter() -> void:
	var host := Control.new()
	host.theme = WoldThemeBuilder.build(tokens())
	get_root().add_child(host)
	var meter: WoldMeter = load("res://addons/woldui/components/wold_meter/wold_meter.tscn").instantiate()
	meter.size = Vector2(300, 20)
	meter.value = 50
	host.add_child(meter)
	await process_frame
	check(meter.get_combined_minimum_size().x > 0.0 and meter.size.x > 0.0, "the meter scene instantiates on its own with a size")
	check(meter.get_theme_stylebox("background") is StyleBoxFlat, "without a fill the meter draws its style's own track")
	check(not meter.uses_fill(), "no fill texture means the plain flat fill")

	var f := WoldFill.new()
	f.texture = _texture(16, 16)
	meter.fill = f
	await process_frame
	check(meter.uses_fill(), "a fill texture switches the meter to the textured fill")
	check(meter.get_theme_stylebox("fill") is StyleBoxEmpty, "the native flat fill steps aside")
	check(meter.get_theme_stylebox("background") is StyleBoxEmpty, "the native track steps aside (the layers draw it, behind the text)")
	var inner := 300.0 - 2.0 * tokens().border_width
	check(is_equal_approx(meter.filled_rect().size.x, inner * 0.5), "at 50%% the fill covers half the inside of the track (%s)" % meter.filled_rect())
	meter.value = 80
	await process_frame
	check(is_equal_approx(meter.filled_rect().size.x, inner * 0.8), "the fill follows the value")

	meter.theme_type_variation = &"MeterThin"
	await process_frame
	var thin_track = meter._layers.track_style
	check(thin_track == host.theme.get_stylebox("background", "MeterThin"), "the textured track follows the meter's style")

	meter.fill = null
	await process_frame
	check(meter.get_theme_stylebox("fill") is StyleBoxFlat, "removing the fill restores the style's flat fill")
	host.queue_free()


func _slider() -> void:
	var host := Control.new()
	host.theme = WoldThemeBuilder.build(tokens())
	get_root().add_child(host)
	var slider: WoldSlider = load("res://addons/woldui/components/wold_slider/wold_slider.tscn").instantiate()
	slider.size = Vector2(300, 24)
	slider.value = 25
	host.add_child(slider)
	var f := WoldFill.new()
	f.texture = _texture(16, 16)
	slider.fill = f
	slider.track_height = 10
	await process_frame
	check(slider.uses_fill(), "a slider takes a fill")
	check(slider.get_theme_stylebox("grabber_area") is StyleBoxEmpty, "the slider's flat fill steps aside")
	check(is_equal_approx(slider._layers.track_rect.size.y, 10.0), "track_height sets the rail thickness")
	check(is_equal_approx(slider.filled_rect().end.x, slider.grabber_center_x()), "the fill ends under the grabber's centre")
	var before := slider.filled_rect().end.x
	slider.value = 75
	await process_frame
	check(slider.filled_rect().end.x > before, "moving the slider moves the end of the fill")
	host.queue_free()


func _vslider() -> void:
	var host := Control.new()
	host.theme = WoldThemeBuilder.build(tokens())
	get_root().add_child(host)
	var s: WoldVSlider = load("res://addons/woldui/components/wold_vslider/wold_vslider.tscn").instantiate()
	s.size = Vector2(24, 300)
	s.value = 25
	host.add_child(s)
	var f := WoldFill.new()
	f.texture = _texture(16, 16)
	s.fill = f
	s.track_width = 10
	await process_frame
	check(s is VSlider and s.uses_fill() and s.get_theme_stylebox("grabber_area") is StyleBoxEmpty, "a vertical slider takes a fill the same way")
	check(is_equal_approx(s._layers.track_rect.size.x, 10.0) and is_equal_approx(s._layers.track_rect.size.y, 300.0), "track_width sets the rail's thickness, it runs the full height")
	var r := s.filled_rect()
	check(is_equal_approx(r.position.y, s.grabber_center_y()) and is_equal_approx(r.end.y, s._layers._inner_rect().end.y), "the fill runs from the bottom up to the grabber")
	check(s.grabber_center_y() > 150.0, "a low value sits near the bottom (%.0f)" % s.grabber_center_y())
	var before := r.size.y
	s.value = 75
	await process_frame
	check(s.filled_rect().size.y > before, "raising it grows the fill upward")
	var reveal := WoldFill.new()
	reveal.texture = _texture(8, 100)
	reveal.mode = WoldFill.Mode.REVEAL
	var track := Rect2(0, 0, 10, 200)
	var p := reveal.plan(track, Rect2(0, 150, 10, 50), true)
	var src: Rect2 = p.src
	check(is_equal_approx(src.position.y, 75.0) and is_equal_approx(src.size.y, 25.0), "vertical REVEAL uncovers the bottom of the image first (%s)" % src)
	var ui := WoldUIRuntime.instance()
	ui.sound_volume_db = linear_to_db(0.5)
	var fader: WoldVSlider = load("res://addons/woldui/gallery/examples/ui_fader.tscn").instantiate()
	host.add_child(fader)
	await process_frame
	var hidden := fader.get_child_count(true) - fader.get_child_count()
	check(hidden == 2 and is_equal_approx(fader.value, 50.0), "UiFader starts from the saved volume, with one set of hidden layers (%d)" % hidden)
	fader.value = 25
	check(is_equal_approx(ui.sound_volume_db, linear_to_db(0.25)), "and moving it writes the volume back")
	ui.sound_volume_db = 0.0
	host.queue_free()


# a script on top of the component's (what an inherited scene with its own
# script does) runs _init again on the same node
func _subclassed() -> void:
	var host := Control.new()
	host.theme = WoldThemeBuilder.build(tokens())
	get_root().add_child(host)
	var counts := []
	for pair in [["WoldMeter", "res://addons/woldui/components/wold_meter/wold_meter.tscn"], ["WoldSlider", "res://addons/woldui/components/wold_slider/wold_slider.tscn"], ["WoldVSlider", "res://addons/woldui/components/wold_vslider/wold_vslider.tscn"]]:
		var sub := GDScript.new()
		sub.source_code = "@tool\nextends %s\n" % pair[0]
		sub.reload()
		var n: Range = load(pair[1]).instantiate()
		n.set_script(sub)
		host.add_child(n)
		await process_frame
		n.value = 30
		counts.append(n.get_child_count(true) - n.get_child_count())
	check(counts == [2, 2, 2], "meter, slider and vertical slider keep one set of hidden layers when subclassed (%s)" % [counts])
	host.queue_free()


func _meter_directions() -> void:
	var host := Control.new()
	get_root().add_child(host)
	var fill := WoldFill.new()
	var img := Image.create(8, 8, false, Image.FORMAT_RGBA8)
	img.fill(Color.WHITE)
	fill.texture = ImageTexture.create_from_image(img)
	var m := WoldMeter.new()
	m.fill = fill
	m.value = 25
	m.show_percentage = false
	m.size = Vector2(20, 200)
	host.add_child(m)
	m.fill_mode = ProgressBar.FILL_BOTTOM_TO_TOP
	await process_frame
	await process_frame
	var r := m.filled_rect()
	check(r.end.y >= 198.0 and r.size.y > 40.0 and r.size.y < 60.0, "FILL_BOTTOM_TO_TOP: the texture fills a quarter from the bottom (%s)" % r)
	m.fill_mode = ProgressBar.FILL_TOP_TO_BOTTOM
	await process_frame
	await process_frame
	r = m.filled_rect()
	check(r.position.y <= 2.0 and r.size.y > 40.0 and r.size.y < 60.0, "FILL_TOP_TO_BOTTOM: from the top (%s)" % r)
	m.size = Vector2(200, 20)
	m.fill_mode = ProgressBar.FILL_END_TO_BEGIN
	await process_frame
	await process_frame
	r = m.filled_rect()
	check(r.end.x >= 198.0 and r.size.x > 40.0 and r.size.x < 60.0, "FILL_END_TO_BEGIN: from the right (%s)" % r)
	host.queue_free()
