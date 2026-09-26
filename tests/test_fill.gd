extends "res://addons/woldui/tests/wold_test_base.gd"
## textured fills keep their shape as the value moves (TILE on resize too)


func _run() -> void:
	_geometry()
	await _meter()
	await _slider()
	finish(22)


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
	var root := Control.new()
	root.theme = WoldThemeBuilder.build(tokens())
	get_root().add_child(root)
	var meter: WoldMeter = load("res://addons/woldui/components/wold_meter/wold_meter.tscn").instantiate()
	meter.size = Vector2(300, 20)
	meter.value = 50
	root.add_child(meter)
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
	check(thin_track == root.theme.get_stylebox("background", "MeterThin"), "the textured track follows the meter's style")

	meter.fill = null
	await process_frame
	check(meter.get_theme_stylebox("fill") is StyleBoxFlat, "removing the fill restores the style's flat fill")
	root.queue_free()


func _slider() -> void:
	var root := Control.new()
	root.theme = WoldThemeBuilder.build(tokens())
	get_root().add_child(root)
	var slider: WoldSlider = load("res://addons/woldui/components/wold_slider/wold_slider.tscn").instantiate()
	slider.size = Vector2(300, 24)
	slider.value = 25
	root.add_child(slider)
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
	root.queue_free()
