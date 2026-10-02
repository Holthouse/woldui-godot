extends "res://addons/woldui/tests/wold_test_base.gd"
## WoldBadge: text, counts, dots, tone/fill contrast in both token sets, pinning, bump.

const SCENE := "res://addons/woldui/components/wold_badge/wold_badge.tscn"
const BadgeRecipe := preload("res://addons/woldui/theme/recipes/badge_recipe.gd")

var stage: Control
var ui: WoldUIRuntime


func _run() -> void:
	ui = WoldUIRuntime.instance()
	stage = Control.new()
	stage.theme = WoldThemeBuilder.build(tokens())
	get_root().add_child(stage)
	await _basics()
	_counts()
	_contrast()
	await _corner()
	await _bump()
	finish(60)


func _badge() -> WoldBadge:
	var b: WoldBadge = load(SCENE).instantiate()
	stage.add_child(b)
	return b


func _label(b: WoldBadge) -> Label:
	return b.get_node("%Label")


func _basics() -> void:
	var b := _badge()
	await process_frame
	check(b.size.x > 0.0 and _label(b).text == "Badge", "the scene instantiates on its own")
	b.text = "Allied"
	b.tone = WoldBadge.Tone.SUCCESS
	b.fill = WoldBadge.Fill.SOLID
	b.badge_size = WoldBadge.Size.SM
	check(b.theme_type_variation == &"BadgeSuccessSolidSm" and _label(b).theme_type_variation == &"BadgeLabelSuccessSolidSm", "tone, fill and size pick the pill and its text")
	check(_label(b).text == "Allied", "text shows")
	b.icon = "shield"
	var icon := b.get_node("%Icon") as TextureRect
	check(icon.visible and icon.texture != null, "an icon shows before the text")
	check(icon.self_modulate == _label(b).get_theme_color("font_color"), "the icon takes the text colour")
	b.dot = true
	check(b.theme_type_variation == &"BadgeDotSuccess" and not _label(b).visible and not icon.visible, "dot: a bare coloured dot")
	check(b.custom_minimum_size == Vector2(8, 8), "a small dot is 8 px")
	b.visible = false
	b.dot = false
	b.tone = WoldBadge.Tone.DANGER
	check(not b.visible, "restyling a text badge never overrides the game hiding it")
	b.queue_free()


func _counts() -> void:
	var b := _badge()
	b.count = 3
	check(_label(b).text == "3" and b.visible, "a count shows the number")
	b.count = 120
	check(_label(b).text == "99+", "above max_count: 99+")
	b.max_count = 9
	b.count = 12
	check(_label(b).text == "9+", "max_count is a prop")
	b.count = 0
	check(not b.visible, "a count of 0 hides the badge")
	b.hide_zero = false
	check(b.visible and _label(b).text == "0", "unless hide_zero is off")
	b.count = -1
	check(_label(b).text == b.text, "count -1 goes back to the text")
	b.queue_free()


## soft pills are see-through, so check text against the pill blended on surface_raised
func _contrast() -> void:
	for path in ["res://addons/woldui/tokens/default_dark.tres", "res://addons/woldui/tokens/default_light.tres"]:
		var t: WoldTokens = load(path)
		var surface := t.role("surface_raised")
		for tone in BadgeRecipe.TONES:
			for fill in BadgeRecipe.FILLS:
				var c: Dictionary = BadgeRecipe.colors(t, tone, fill)
				var bg: Color = surface.blend(c.bg)
				var ratio := WoldColor.contrast(c.fg, bg)
				check(ratio >= 4.5, "%s: %s %s badge text is %.2f:1" % [path.get_file(), tone, fill, ratio])


func _corner() -> void:
	var host := Button.new()
	host.custom_minimum_size = Vector2(120, 40)
	stage.add_child(host)
	var b: WoldBadge = load(SCENE).instantiate()
	b.count = 4
	b.tone = WoldBadge.Tone.DANGER
	b.fill = WoldBadge.Fill.SOLID
	b.pin = WoldBadge.Pin.TOP_RIGHT
	host.add_child(b)
	await process_frame
	await process_frame
	var centre := b.position + b.size / 2.0
	check(centre.distance_to(Vector2(host.size.x, 0)) < 1.5, "TOP_RIGHT centres the badge on the parent's corner (%s vs %s)" % [centre, Vector2(host.size.x, 0)])
	b.pin = WoldBadge.Pin.TOP_LEFT
	await process_frame
	centre = b.position + b.size / 2.0
	check(centre.distance_to(Vector2.ZERO) < 1.5, "TOP_LEFT centres it on the other corner")
	host.queue_free()


func _bump() -> void:
	var b := _badge()
	b.count = 1
	await process_frame
	b.count = 2
	await create_timer(tokens().duration_instant * 0.8).timeout
	check(b.offset_transform_scale.x > 1.0, "a rising count bumps the badge")
	await create_timer(0.6).timeout
	check(is_equal_approx(b.offset_transform_scale.x, 1.0), "and it settles back")
	b.count = 1
	await create_timer(tokens().duration_instant * 0.8).timeout
	check(is_equal_approx(b.offset_transform_scale.x, 1.0), "a falling count does not bump")
	ui.reduced_motion = true
	b.count = 5
	check(is_equal_approx(b.offset_transform_scale.x, 1.0), "reduced motion: no bump")
	ui.reduced_motion = false
	b.queue_free()
