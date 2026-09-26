extends "res://addons/woldui/tests/wold_test_base.gd"
## WoldStat: formatting, layout, change indicator, count-up, saved scenes, Extra slot.

const SCENE := "res://addons/woldui/components/wold_stat/wold_stat.tscn"
const EXAMPLE := "res://addons/woldui/gallery/examples/health_stat.tscn"

var stage: Control
var ui: WoldUIRuntime


func _run() -> void:
	ui = WoldUIRuntime.instance()
	stage = Control.new()
	stage.theme = WoldThemeBuilder.build(tokens())
	get_root().add_child(stage)
	await _standalone()
	_formatting()
	await _layout_and_icon()
	await _delta()
	await _counting()
	await _saved_scene()
	await _extension()
	finish(34)


func _stat() -> WoldStat:
	var s: WoldStat = load(SCENE).instantiate()
	s.animate = false
	stage.add_child(s)
	return s


func _value(s: WoldStat) -> String:
	return (s.get_node("%Value") as Label).text


func _standalone() -> void:
	var s: WoldStat = load(SCENE).instantiate()
	stage.add_child(s)
	await process_frame
	check(s.size.x > 0.0 and s.size.y > 0.0, "the scene instantiates on its own with a size")
	check(_value(s) == "120" and (s.get_node("%Icon") as TextureRect).texture != null, "its preview props show (icon, 120, Score)")
	check(s.theme_type_variation == &"PanelHud", "default surface: a HUD panel")
	s.queue_free()


func _formatting() -> void:
	var s: WoldStat = load(SCENE).instantiate()
	s.format = "%d gold"
	check(s.display_text(250) == "250 gold", "format writes the number")
	s.format = "%.1f"
	check(s.display_text(2.25) == "2.3" or s.display_text(2.25) == "2.2", "format with decimals")
	s.format = "%d"
	s.compact = true
	check(s.display_text(999) == "999", "compact leaves small numbers alone")
	check(s.display_text(1200) == "1.2k" and s.display_text(1000) == "1k", "compact thousands (1.2k, 1k)")
	check(s.display_text(3_400_000) == "3.4M" and s.display_text(-1500) == "-1.5k", "compact millions and negatives")
	s.compact = false
	s.max_value = 20
	check(s.display_text(12) == "12 / 20", "max_value shows value / max")
	s.free()


func _layout_and_icon() -> void:
	var t := tokens()
	var s := _stat()
	s.label = "Gold"
	s.icon = "coins"
	await process_frame
	var icon := s.get_node("%Icon") as TextureRect
	check(icon.texture == t.icon("coins"), "icon draws the named icon at the size's token")
	check(icon.custom_minimum_size == Vector2(t.icon_size_md, t.icon_size_md), "the icon box is the token size")
	check(s.get_node("%Label").visible and not s.get_node("%Caption").visible, "INLINE: the label sits beside the value")
	s.layout = WoldStat.Layout.STACKED
	check(s.get_node("%Caption").visible and not s.get_node("%Label").visible, "STACKED: the label sits above the value")
	s.label = ""
	check(not s.get_node("%Caption").visible and not s.get_node("%Label").visible, "no label, no empty label node")
	s.stat_size = WoldStat.Size.LG
	check(icon.texture == t.icon("coins", "Lg") and s.get_node("%Value").theme_type_variation == &"StatValueLg", "LG: larger icon and value")
	s.icon = ""
	check(not icon.visible, "no icon, no icon space")
	s.icon = "coins"
	s.tone = WoldStat.Tone.ACCENT
	check(icon.self_modulate == t.role("accent_text"), "tone colours the icon (accent)")
	s.tone = WoldStat.Tone.NEUTRAL
	check(icon.self_modulate == t.role("text_muted"), "NEUTRAL icons are muted")
	s.surface = WoldStat.Surface.RAISED
	check(s.theme_type_variation == &"PanelRaised", "surface picks the panel")
	s.queue_free()


func _delta() -> void:
	var s := _stat()
	s.show_delta = true
	s.delta = 5
	var d := s.get_node("%Delta") as Label
	check(d.visible and d.text == "+5" and d.theme_type_variation == &"StatDeltaUp", "a rise shows +5 in the up style")
	s.delta = -3
	check(d.text == WoldStat.MINUS + "3" and d.theme_type_variation == &"StatDeltaDown", "a fall shows a real minus sign in the down style")
	s.delta = 0
	check(not d.visible, "no change, no indicator")
	s.delta = 5
	s.show_delta = false
	check(not d.visible, "show_delta off hides it")
	s.queue_free()


func _counting() -> void:
	var s := _stat()
	s.animate = true
	s.label = ""
	s.value = 0
	await process_frame
	var seen := []
	s.value_changed.connect(func(o, n): seen.append([o, n]))
	s.value = 300
	await create_timer(0.08).timeout
	var mid := _value(s)
	check(mid != "300", "a new value counts up instead of jumping (showing %s)" % mid)
	check(seen == [[0.0, 300.0]], "value_changed reports old and new")
	await create_timer(1.0).timeout
	check(_value(s) == "300", "and lands exactly on it")

	ui.reduced_motion = true
	s.value = 50
	check(_value(s) == "50", "reduced motion: the number jumps straight there")
	ui.reduced_motion = false
	s.animate = false
	s.value = 70
	check(_value(s) == "70", "animate off: the number jumps straight there")
	s.queue_free()


## only props get saved, inner nodes are rebuilt
func _saved_scene() -> void:
	var host := Control.new()
	stage.add_child(host)
	var s: WoldStat = load(SCENE).instantiate()
	host.add_child(s)
	s.owner = host
	s.animate = false
	s.icon = "wheat"
	s.value = 42
	s.label = "Food"
	await process_frame
	var packed := PackedScene.new()
	packed.pack(host)
	var state := packed.get_state()
	check(state.get_node_count() == 2, "a saved scene holds the host and the stat, not the stat's insides (%d nodes)" % state.get_node_count())
	var again := packed.instantiate()
	stage.add_child(again)
	await process_frame
	var copy := again.get_child(0) as WoldStat
	check(copy.value == 42.0 and _value(copy) == "42" and copy.label == "Food", "it reloads from its props")
	host.queue_free()
	again.queue_free()


func _extension() -> void:
	var h: WoldStat = load(EXAMPLE).instantiate()
	h.animate = false
	stage.add_child(h)
	await process_frame
	var meter := h.get_node("%Extra").get_node_or_null("Meter") as WoldMeter
	check(meter != null, "the example puts a WoldMeter in the Extra slot")
	check(_value(h) == "64 / 100" and h.get_node("%Caption").visible, "it keeps its own props (stacked, 64 / 100)")
	check(meter.value == 64.0 and meter.max_value == 100.0, "the meter starts in step with the value")
	h.value = 30
	check(meter.value == 30.0, "and follows the value")
	h.max_value = 50
	check(meter.max_value == 50.0, "and the max, through the hook")
	h.queue_free()
