extends "res://addons/woldui/tests/wold_test_base.gd"
## WoldAccordion: one at a time, multiple, collapsible off, dividers, keyboard, saved scenes.

const SCENE := "res://addons/woldui/components/wold_accordion/wold_accordion.tscn"

var stage: VBoxContainer


func _run() -> void:
	WoldUIRuntime.instance().reduced_motion = true
	get_root().size = Vector2i(1280, 720)
	stage = VBoxContainer.new()
	stage.size = Vector2(600, 700)
	stage.theme = WoldThemeBuilder.build(tokens())
	get_root().add_child(stage)
	await _single()
	await _multiple()
	await _not_collapsible()
	await _looks_and_keys()
	await _saved_scene()
	var codex: WoldAccordion = load("res://addons/woldui/gallery/examples/codex_accordion.tscn").instantiate()
	stage.add_child(codex)
	await _frames()
	codex.items()[0].open = false
	await _frames()
	check(codex.items()[0].open and not codex.collapsible, "CodexAccordion keeps a section open")
	codex.queue_free()
	finish(12)


func _acc() -> WoldAccordion:
	var a: WoldAccordion = load(SCENE).instantiate()
	stage.add_child(a)
	return a


func _frames() -> void:
	await process_frame
	await process_frame


func _single() -> void:
	var a := _acc()
	await _frames()
	var items := a.items()
	check(items.size() == 3 and not items.any(func(i): return i.open), "three items, all shut")
	var seen := []
	a.item_toggled.connect(func(i, o): seen.append([i, o]))
	items[0].open = true
	items[2].open = true
	check(items[2].open and not items[0].open, "opening one closes the other")
	check(seen == [[0, true], [0, false], [2, true]], "item_toggled reports each change (%s)" % [seen])
	items[2].open = false
	check(not items.any(func(i): return i.open), "the open one can be closed (collapsible)")
	a.queue_free()


func _multiple() -> void:
	var a := _acc()
	a.multiple = true
	await _frames()
	var items := a.items()
	items[0].open = true
	items[1].open = true
	check(items[0].open and items[1].open, "multiple: several open at once")
	a.queue_free()


func _not_collapsible() -> void:
	var a := _acc()
	a.collapsible = false
	await _frames()
	var items := a.items()
	items[1].open = true
	items[1].open = false
	await _frames()
	check(items[1].open, "collapsible off: the last open one stays open")
	items[0].open = true
	check(items[0].open and not items[1].open, "but opening another still swaps")
	a.queue_free()


func _looks_and_keys() -> void:
	var a := _acc()
	await _frames()
	var items := a.items()
	check(items[0].is_divided() and items[0].trigger().theme_type_variation == &"AccordionTrigger", "items inside an accordion are flush rows")
	var loose: WoldCollapsible = load("res://addons/woldui/components/wold_collapsible/wold_collapsible.tscn").instantiate()
	stage.add_child(loose)
	await _frames()
	check(not loose.is_divided() and loose.trigger().theme_type_variation == &"CollapsibleTrigger", "a collapsible on its own isn't")
	items[0].trigger().grab_focus()
	var e := InputEventAction.new()
	e.action = &"ui_down"
	e.pressed = true
	get_root().push_input(e)
	await process_frame
	check(items[1].trigger().has_focus(), "down moves to the next trigger")
	loose.queue_free()
	a.queue_free()


func _saved_scene() -> void:
	var host := VBoxContainer.new()
	stage.add_child(host)
	var a: WoldAccordion = load(SCENE).instantiate()
	host.add_child(a)
	a.owner = host
	# its items come from its own scene: they save through Editable Children
	host.set_editable_instance(a, true)
	await _frames()
	a.items()[1].open = true
	var packed := PackedScene.new()
	packed.pack(host)
	var again := packed.instantiate()
	stage.add_child(again)
	await _frames()
	var copy := again.get_child(0) as WoldAccordion
	check(copy.items()[1].open and not copy.items()[0].open, "an open item stays open through a save")
	host.queue_free()
	again.queue_free()
