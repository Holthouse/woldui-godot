@tool
extends PanelContainer
## Dev showcase: every WoldUI style under one tokens file. F6 to run it, or just
## open it in the editor, it's @tool and draws live.
## Sections come from the built theme, so a game's own variants and recipes land
## under "Game styles" without touching this file.
## TODO: all built in code instead of a scene tree. tweaking layout is a pain.

const TOKEN_DIR := "res://addons/woldui/tokens/"
const SAMPLE := "The quick brown fox jumps over the lazy dog"

## empty = project tokens
@export_file("*.tres") var tokens_path := "":
	set(value):
		tokens_path = value
		if is_inside_tree():
			rebuild()
## for eyeballing disabled states
@export var show_disabled := false:
	set(value):
		show_disabled = value
		if is_inside_tree():
			rebuild()

var tokens: WoldTokens
var _content: VBoxContainer
var _picker: OptionButton
var _picker_paths: PackedStringArray = []
var _mode_label: Label


func _ready() -> void:
	theme_type_variation = &"PanelBase"
	rebuild()


func rebuild() -> void:
	var path := _resolved_path()
	tokens = load(path) as WoldTokens
	if tokens == null:
		push_error("WoldUI gallery: no WoldTokens at %s" % path)
		return
	theme = WoldThemeBuilder.build(tokens)
	for child in get_children():
		remove_child(child)
		child.queue_free()

	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)
	var margin := MarginContainer.new()
	margin.theme_type_variation = &"InsetXxl"
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(margin)
	_content = VBoxContainer.new()
	_content.theme_type_variation = &"StackXxl"
	margin.add_child(_content)

	# hover/press/sound on every button in here
	if not Engine.is_editor_hint():
		add_child(WoldFeedback.new())

	_header(path)
	_wold_buttons()
	_wold_stats()
	_wold_badges()
	_wold_dialogs()
	_wold_toasts()
	_wold_tooltips()
	_wold_list_rows()
	_wold_switches()
	_wold_checkboxes()
	_wold_radio_groups()
	_wold_segmented()
	_wold_toggles()
	_wold_selects()
	_wold_steppers()
	_wold_fields()
	_wold_button_strips()
	_wold_cards()
	_wold_disclosure()
	_wold_avatars()
	_wold_alerts()
	_wold_status()
	_wold_carousels()
	_wold_menus()
	_wold_popovers()
	_wold_sheets()
	_wold_chat()
	_wold_tabs()
	_wold_prompts()
	_wold_scopes()
	_wold_screens()
	_motion()
	_colours()
	_type()
	_buttons()
	_inputs()
	_meters_and_tabs()
	_panels()
	_fills()
	_layout()
	_icons()
	_game_styles()


func _resolved_path() -> String:
	if tokens_path != "":
		return tokens_path
	return ProjectSettings.get_setting("woldui/tokens", TOKEN_DIR + "default_dark.tres")


# ------------------------------------------------------------------ sections

func _header(path: String) -> void:
	var row := _row(&"RowLg")
	_content.add_child(row)
	var titles := _stack(&"StackXs")
	titles.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(titles)
	titles.add_child(_label("WoldUI", &"Display"))
	titles.add_child(_label("Every style, drawn from %s" % path.get_file(), &"Muted"))

	_picker = OptionButton.new()
	_picker_paths = _token_files()
	for i in _picker_paths.size():
		_picker.add_item(_picker_paths[i].get_file())
		if _picker_paths[i] == path:
			_picker.select(i)
	_picker.item_selected.connect(func(i): tokens_path = _picker_paths[i])
	_picker.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(_picker)

	var disabled := CheckBox.new()
	disabled.text = "Disabled"
	disabled.button_pressed = show_disabled
	disabled.toggled.connect(func(on): show_disabled = on)
	disabled.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(disabled)


## ConfirmButton is an inherited scene with its own `busy` prop
func _wold_buttons() -> void:
	var s := _section("WoldButton", "components/wold_button. Icons at the start and/or end by name; shape, size and sound are props. ConfirmButton extends it with a busy prop.")
	var scene := load("res://addons/woldui/components/wold_button/wold_button.tscn")
	var make := func(label: String, shape: int, size: int, start := "", end := "") -> WoldButton:
		var b: WoldButton = scene.instantiate()
		b.text = label
		b.shape = shape
		b.button_size = size
		b.icon_start = start
		b.icon_end = end
		b.disabled = show_disabled
		b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		return b
	var S := WoldButton.Shape
	var Z := WoldButton.Size
	var row := _row(&"RowMd")
	row.add_child(make.call("Continue", S.PRIMARY, Z.MD, "", "arrow-right"))
	row.add_child(make.call("Settings", S.SECONDARY, Z.MD, "settings", "chevron-down"))
	row.add_child(make.call("Map", S.OUTLINE, Z.MD, "map"))
	row.add_child(make.call("Back", S.GHOST, Z.MD, "arrow-left"))
	row.add_child(make.call("Delete", S.DANGER, Z.MD, "trash"))
	s.add_child(row)
	var sizes := _row(&"RowMd")
	for z in [Z.SM, Z.MD, Z.LG]:
		sizes.add_child(make.call("Recruit", S.PRIMARY, z, "swords", "plus"))
	for z in [Z.SM, Z.MD, Z.LG]:
		var only: WoldButton = make.call("", S.ICON, z, "x")
		only.tooltip_text = "Close"
		sizes.add_child(only)
	s.add_child(sizes)
	var extended := _row(&"RowMd")
	var confirm: WoldButton = load("res://addons/woldui/gallery/examples/confirm_button.tscn").instantiate()
	extended.add_child(confirm)
	var busy := CheckButton.new()
	busy.text = "busy"
	busy.toggled.connect(func(on): confirm.busy = on)
	extended.add_child(busy)
	s.add_child(extended)


## HealthStat = a meter in the Extra slot
func _wold_stats() -> void:
	var s := _section("WoldStat", "components/wold_stat. Icon, value and meaning; counts and flashes when the value changes. HealthStat puts a meter in the Extra slot.")
	var scene := load("res://addons/woldui/components/wold_stat/wold_stat.tscn")
	var make := func(icon: String, value: float, label := "", delta := 0.0) -> WoldStat:
		var st: WoldStat = scene.instantiate()
		st.icon = icon
		st.value = value
		st.label = label
		st.delta = delta
		st.show_delta = delta != 0.0
		st.tooltip_text = label
		st.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		return st

	# top-bar HUD row
	var bar := PanelContainer.new()
	bar.theme_type_variation = &"PanelHud"
	bar.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	var bar_row := _row(&"RowXl")
	bar.add_child(bar_row)
	var resources := [["wheat", 1240, "Food", 12], ["trees", 380, "Wood", 8], ["mountain", 95, "Stone", -2], ["coins", 610, "Gold", 20], ["flask-conical", 44, "Research", 3]]
	var stats: Array[WoldStat] = []
	for r in resources:
		var st: WoldStat = make.call(r[0], r[1], "", r[3])
		st.surface = WoldStat.Surface.BARE
		st.compact = true
		st.tooltip_text = r[2]
		bar_row.add_child(st)
		stats.append(st)
	var pop: WoldStat = make.call("users", 12)
	pop.max_value = 20
	pop.surface = WoldStat.Surface.BARE
	pop.tooltip_text = "Population"
	bar_row.add_child(pop)
	s.add_child(bar)

	var controls := _row(&"RowSm")
	var income := Button.new()
	income.theme_type_variation = &"ButtonPrimarySm"
	income.text = "Next turn"
	income.icon = tokens.icon("hourglass", "Sm")
	income.pressed.connect(func():
		for st in stats:
			st.value += st.delta * 10)
	controls.add_child(income)
	s.add_child(controls)

	var variants := _row(&"RowLg")
	for z in [WoldStat.Size.SM, WoldStat.Size.MD, WoldStat.Size.LG]:
		var st: WoldStat = make.call("trophy", 2480, "Score")
		st.stat_size = z
		st.tone = WoldStat.Tone.ACCENT
		st.surface = WoldStat.Surface.RAISED
		variants.add_child(st)
	var stacked: WoldStat = make.call("clock", 42, "Turn")
	stacked.layout = WoldStat.Layout.STACKED
	stacked.surface = WoldStat.Surface.RAISED
	variants.add_child(stacked)
	s.add_child(variants)

	var health_row := _row(&"RowMd")
	var health: WoldStat = load("res://addons/woldui/gallery/examples/health_stat.tscn").instantiate()
	health.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	health_row.add_child(health)
	for pair in [["Hit for 15", -15.0, "sword"], ["Heal 20", 20.0, "heart-plus"]]:
		var b := Button.new()
		b.theme_type_variation = &"ButtonSecondarySm"
		b.text = pair[0]
		b.icon = tokens.icon(pair[2], "Sm")
		b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		var amount: float = pair[1]
		b.pressed.connect(func(): health.value = clampf(health.value + amount, 0.0, health.max_value))
		health_row.add_child(b)
	s.add_child(health_row)


func _wold_badges() -> void:
	var s := _section("WoldBadge", "components/wold_badge. Tone × fill, a count (99+), a dot, or pinned to a corner of its parent.")
	var scene := load("res://addons/woldui/components/wold_badge/wold_badge.tscn")
	var tones := ["Neutral", "Accent", "Success", "Warning", "Danger"]
	for fill in [WoldBadge.Fill.SOFT, WoldBadge.Fill.SOLID, WoldBadge.Fill.OUTLINE]:
		var row := _row(&"RowSm")
		var tag := _label(WoldBadge.Fill.keys()[fill].capitalize(), &"Caption")
		tag.custom_minimum_size.x = 120
		row.add_child(tag)
		for i in tones.size():
			var b: WoldBadge = scene.instantiate()
			b.text = tones[i]
			b.tone = i
			b.fill = fill
			b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			row.add_child(b)
		s.add_child(row)

	var row := _row(&"RowXl")
	var labelled := [["Allied", "shield", WoldBadge.Tone.SUCCESS], ["At war", "swords", WoldBadge.Tone.DANGER], ["New", "sparkles", WoldBadge.Tone.ACCENT]]
	for l in labelled:
		var b: WoldBadge = scene.instantiate()
		b.text = l[0]
		b.icon = l[1]
		b.tone = l[2]
		b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(b)
	var inbox := Button.new()
	inbox.theme_type_variation = &"ButtonSecondary"
	inbox.text = "Messages"
	inbox.icon = tokens.icon("mail")
	inbox.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var counter: WoldBadge = scene.instantiate()
	counter.count = 3
	counter.tone = WoldBadge.Tone.DANGER
	counter.fill = WoldBadge.Fill.SOLID
	counter.badge_size = WoldBadge.Size.SM
	counter.pin = WoldBadge.Pin.TOP_RIGHT
	inbox.add_child(counter)
	inbox.pressed.connect(func(): counter.count += 1)
	row.add_child(inbox)
	var turn := _row(&"RowSm")
	var dot: WoldBadge = scene.instantiate()
	dot.dot = true
	dot.tone = WoldBadge.Tone.ACCENT
	dot.pulse = true
	dot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	turn.add_child(dot)
	turn.add_child(_label("Your turn", &"Body"))
	row.add_child(turn)
	s.add_child(row)


func _wold_dialogs() -> void:
	var s := _section("WoldDialog", "components/wold_dialog. Modal for mouse, keyboard and pad: focus starts on confirm, stays inside, and returns on close. Esc cancels.")
	var row := _row(&"RowMd")
	var answer := _label("", &"Muted")
	var ask := Button.new()
	ask.theme_type_variation = &"ButtonSecondary"
	ask.text = "WoldDialog.ask()"
	ask.icon = tokens.icon("message-circle-question-mark")
	ask.pressed.connect(func():
		var result := await WoldDialog.ask(self, "Trade 20 wood for 10 gold?", "The offer goes to the Spidobots.", "Offer trade", "Not now")
		answer.text = "ask() returned \"%s\"" % result)
	row.add_child(ask)
	var quit := Button.new()
	quit.theme_type_variation = &"ButtonSecondary"
	quit.text = "QuitDialog example"
	quit.icon = tokens.icon("log-out")
	quit.pressed.connect(func():
		var layer := CanvasLayer.new()
		layer.layer = 100
		add_child(layer)
		var d: WoldDialog = load("res://addons/woldui/gallery/examples/quit_dialog.tscn").instantiate()
		d.free_on_close = true
		d.tree_exited.connect(layer.queue_free)
		d.closed.connect(func(r): answer.text = "QuitDialog closed with \"%s\", dont_ask_again = %s" % [r, d.dont_ask_again])
		layer.add_child(d)
		d.open())
	row.add_child(quit)
	answer.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(answer)
	s.add_child(row)


func _wold_toasts() -> void:
	var s := _section("WoldToast", "components/wold_toast. WoldToast.notify(self, text, tone) from anywhere. Hover pauses the timer; the stack closes up smoothly.")
	var row := _row(&"RowSm")
	var samples := [
		["Info", WoldToast.Tone.NEUTRAL, "", "The Spidobots ended their turn."],
		["Accent", WoldToast.Tone.ACCENT, "Wonder started", "Your Great Library will take 6 turns."],
		["Success", WoldToast.Tone.SUCCESS, "", "Game saved."],
		["Warning", WoldToast.Tone.WARNING, "Low food", "Your population stops growing next turn."],
		["Danger", WoldToast.Tone.DANGER, "City under attack", "Rivermouth is being besieged."],
	]
	for sample in samples:
		var b := Button.new()
		b.theme_type_variation = &"ButtonOutlineSm"
		b.text = sample[0]
		b.pressed.connect(func(): WoldToast.notify(self, sample[3], sample[1], sample[2]))
		row.add_child(b)
	var sticky := Button.new()
	sticky.theme_type_variation = &"ButtonSecondarySm"
	sticky.text = "Sticky with action"
	sticky.pressed.connect(func():
		var t := WoldToast.notify(self, "The Ants offer 20 wood for 10 gold.", WoldToast.Tone.ACCENT, "Trade offer", 0.0)
		t.action_text = "View offer"
		t.action_pressed.connect(func(): WoldToast.notify(self, "Opening the trade screen…")))
	row.add_child(sticky)
	var place := OptionButton.new()
	for p in WoldToaster.Place.keys():
		place.add_item(p.capitalize())
	place.item_selected.connect(func(i): WoldToaster.find_or_create(self).place = i)
	row.add_child(place)
	s.add_child(row)


## tab through these to check pad/keyboard behaviour
func _wold_tooltips() -> void:
	var s := _section("WoldTooltip", "components/wold_tooltip. A node under any Control. Hover, or Tab to a control: keyboard and pad players see tooltips too.")
	var row := _row(&"RowMd")
	var units := [
		["Spearman", "swords", "Cheap infantry. [b]Double damage[/b] against riders.", {"Attack": "6", "Defence": "4", "Move": "2"}],
		["Archer", "crosshair", "Shoots from [b]2 hexes[/b] away; weak up close.", {"Attack": "5", "Range": "2", "Move": "2"}],
		["Rider", "rabbit", "Fast. Takes [color=#d4564f]double damage[/color] from spearmen.", {"Attack": "7", "Move": "4"}],
	]
	for u in units:
		var b: WoldButton = load("res://addons/woldui/components/wold_button/wold_button.tscn").instantiate()
		b.text = u[0]
		b.icon_start = u[1]
		var tip: WoldTooltip = load("res://addons/woldui/components/wold_tooltip/wold_tooltip.tscn").instantiate()
		tip.title = u[0]
		tip.icon = u[1]
		tip.body = u[2]
		tip.rows.assign(u[3])
		tip.hint = "Costs 30 food"
		b.add_child(tip)
		row.add_child(b)
	var gold: WoldStat = load("res://addons/woldui/components/wold_stat/wold_stat.tscn").instantiate()
	gold.icon = "coins"
	gold.value = 610
	gold.label = ""
	gold.delta = 20
	gold.show_delta = true
	gold.focus_mode = Control.FOCUS_ALL
	var gold_tip: WoldTooltip = load("res://addons/woldui/components/wold_tooltip/wold_tooltip.tscn").instantiate()
	gold_tip.title = "Gold"
	gold_tip.icon = "coins"
	gold_tip.body = "Spent on trades, wonders and upkeep."
	gold_tip.rows.assign({"Markets": "+14", "Trade routes": "+9", "Upkeep": "−3"})
	gold_tip.hint = "+20 per turn"
	gold.add_child(gold_tip)
	row.add_child(gold)
	s.add_child(row)


## ButtonGroup so only one slot is selected
func _wold_list_rows() -> void:
	var s := _section("WoldListRow", "components/wold_list_row. Real buttons, so focus, pad and ButtonGroup selection work. Slots for your own content.")
	var list := PanelContainer.new()
	list.theme_type_variation = &"PanelRaised"
	list.custom_minimum_size.x = 560
	list.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	var rows := _stack(&"StackXs")
	list.add_child(rows)
	var group := ButtonGroup.new()
	var saves := [
		["Rivers, turn 42", "Ants vs Spidobots, 2 hours ago", "Medium", "save", ""],
		["Highlands, turn 17", "Four players, yesterday", "Large", "save", "Autosave"],
		["Tutorial", "Chapter 3 of 5", "Small", "graduation-cap", ""],
	]
	var scene := load("res://addons/woldui/components/wold_list_row/wold_list_row.tscn")
	for i in saves.size():
		var r: WoldListRow = scene.instantiate()
		r.title = saves[i][0]
		r.subtitle = saves[i][1]
		r.trailing_text = saves[i][2]
		r.icon_name = saves[i][3]
		r.button_group = group
		r.disabled = show_disabled
		if saves[i][4] != "":
			var b: WoldBadge = load("res://addons/woldui/components/wold_badge/wold_badge.tscn").instantiate()
			b.text = saves[i][4]
			b.badge_size = WoldBadge.Size.SM
			b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			r.get_node("%Trailing").add_child(b)
		rows.add_child(r)
		if i == 0:
			r.button_pressed = true
	s.add_child(list)


## MotionSwitch is bound to the real Reduce motion preference
func _wold_switches() -> void:
	var s := _section("WoldSwitch", "components/wold_switch. A toggle Button whose knob slides. Label and description are props; the description lines up under the label. MotionSwitch is bound to a real setting.")
	var panel := PanelContainer.new()
	panel.theme_type_variation = &"PanelRaised"
	panel.custom_minimum_size.x = 480
	panel.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	var col := _stack(&"StackSm")
	panel.add_child(col)
	var scene := load("res://addons/woldui/components/wold_switch/wold_switch.tscn")
	var items := [["Show hex grid", "Outlines every tile on the map.", true], ["Auto end turn", "", false], ["Fog of war", "Set by the scenario.", true]]
	for i in items.size():
		var sw: WoldSwitch = scene.instantiate()
		sw.label = items[i][0]
		sw.description = items[i][1]
		sw.button_pressed = items[i][2]
		sw.disabled = show_disabled or i == 2
		col.add_child(sw)
	col.add_child(HSeparator.new())
	col.add_child(load("res://addons/woldui/gallery/examples/motion_switch.tscn").instantiate())
	s.add_child(panel)


## CheckAll is an inherited scene that drives the other three
func _wold_checkboxes() -> void:
	var s := _section("WoldCheckbox", "components/wold_checkbox. Label, description and a mixed state. In a ButtonGroup the same component draws as radios. CheckAll shows the dash while only some units are picked.")
	var row := _row(&"RowXl")
	var scene := load("res://addons/woldui/components/wold_checkbox/wold_checkbox.tscn")
	var units := _stack(&"StackXs")
	var all: WoldCheckbox = load("res://addons/woldui/gallery/examples/check_all.tscn").instantiate()
	all.disabled = show_disabled
	units.add_child(all)
	var picked: Array[WoldCheckbox] = []
	for unit in [["Spearmen", true], ["Archers", false], ["Riders", true]]:
		var indent := MarginContainer.new()
		indent.add_theme_constant_override("margin_left", tokens.space_xl)
		var c: WoldCheckbox = scene.instantiate()
		c.label = unit[0]
		c.description = ""
		c.button_pressed = unit[1]
		c.disabled = show_disabled
		indent.add_child(c)
		units.add_child(indent)
		picked.append(c)
	all.boxes = picked
	row.add_child(units)
	var radios := _stack(&"StackXs")
	radios.add_child(_label("Difficulty", &"Caption"))
	var group := ButtonGroup.new()
	for level in [["Settler", "For learning the ropes."], ["Chieftain", "The AI plays fair."], ["Deity", "The AI gets a head start."]]:
		var r: WoldCheckbox = scene.instantiate()
		r.label = level[0]
		r.description = level[1]
		r.button_group = group
		r.button_pressed = level[0] == "Chieftain"
		r.disabled = show_disabled
		radios.add_child(r)
	row.add_child(radios)
	s.add_child(row)


## GameSpeed maps the pick to a value
func _wold_radio_groups() -> void:
	var s := _section("WoldRadioGroup", "components/wold_radio_group. Options and descriptions as props; arrows or the d-pad move the pick, and focus leaves at either end. GameSpeed turns the pick into a value.")
	var row := _row(&"RowXxl")
	var speed: WoldRadioGroup = load("res://addons/woldui/gallery/examples/game_speed.tscn").instantiate()
	speed.disabled = show_disabled
	row.add_child(speed)
	var col := _stack(&"StackLg")
	var sides: WoldRadioGroup = load("res://addons/woldui/components/wold_radio_group/wold_radio_group.tscn").instantiate()
	sides.legend = "Play as"
	sides.options = PackedStringArray(["Ants", "Spidobots", "Moles"])
	sides.descriptions = PackedStringArray()
	sides.horizontal = true
	sides.selected = 0
	sides.disabled = show_disabled
	col.add_child(sides)
	var note := _label("", &"Muted")
	var show_speed := func(_i := 0): note.text = "speed = %.0f s" % speed.speed
	speed.selected_changed.connect(show_speed)
	show_speed.call()
	col.add_child(note)
	row.add_child(col)
	s.add_child(row)


## MapLayers is the multiple mode
func _wold_segmented() -> void:
	var s := _section("WoldSegmented", "components/wold_segmented. Joined toggle buttons: pick one and the raised thumb slides to it, or turn on any number with multiple. MapLayers is a set of layer toggles.")
	var scene := load("res://addons/woldui/components/wold_segmented/wold_segmented.tscn")
	var row := _row(&"RowXl")
	var views: WoldSegmented = scene.instantiate()
	row.add_child(views)
	var range_pick: WoldSegmented = scene.instantiate()
	range_pick.options = PackedStringArray(["10 turns", "50 turns", "All"])
	range_pick.icons = PackedStringArray()
	range_pick.segment_size = WoldSegmented.Size.SM
	range_pick.selected = 2
	range_pick.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(range_pick)
	var layers: WoldSegmented = load("res://addons/woldui/gallery/examples/map_layers.tscn").instantiate()
	layers.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(layers)
	for seg in [views, range_pick, layers]:
		for i in seg.item_count():
			seg.item(i).disabled = show_disabled
	s.add_child(row)
	var wide: WoldSegmented = scene.instantiate()
	wide.options = PackedStringArray(["Ants", "Spidobots", "Moles", "Random"])
	wide.icons = PackedStringArray()
	wide.stretch = true
	wide.custom_minimum_size.x = 520
	s.add_child(wide)


## FastForward is a scene-only example: an icon-only outline toggle
func _wold_toggles() -> void:
	var s := _section("WoldToggle", "components/wold_toggle. A WoldButton that stays on: quiet when off, accent tint when on. outline adds an edge; shape ICON makes it square for icon-only toggles.")
	var scene := load("res://addons/woldui/components/wold_toggle/wold_toggle.tscn")
	var make := func(label: String, icon: String, on: bool, outline := false, square := false, size := WoldButton.Size.MD) -> WoldToggle:
		var b: WoldToggle = scene.instantiate()
		b.text = label
		b.icon_start = icon
		b.outline = outline
		b.button_size = size
		if square:
			b.shape = WoldButton.Shape.ICON
			b.tooltip_text = icon
		b.button_pressed = on
		b.disabled = show_disabled
		b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		return b
	var row := _row(&"RowXs")
	for l in [["Grid", "grid-3x3", true], ["Yields", "wheat", false], ["Fog", "cloud-fog", true]]:
		row.add_child(make.call(l[0], l[1], l[2]))
	row.add_child(VSeparator.new())
	for l in [["eye", true], ["flag", false], ["mountain", false]]:
		row.add_child(make.call("", l[0], l[1], true, true))
	row.add_child(VSeparator.new())
	for z in [WoldButton.Size.SM, WoldButton.Size.MD, WoldButton.Size.LG]:
		row.add_child(make.call("Pin", "pin", true, true, false, z))
	row.add_child(VSeparator.new())
	var ff: WoldToggle = load("res://addons/woldui/gallery/examples/fast_forward.tscn").instantiate()
	ff.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	ff.disabled = show_disabled
	row.add_child(ff)
	s.add_child(row)


## FactionSelect recolours a WoldScope from the pick
func _wold_selects() -> void:
	var s := _section("WoldSelect", "components/wold_select. A field that drops down a list; the current option is checked. Accept opens it on keyboard or pad and focus comes back when it closes. FactionSelect tints a WoldScope.")
	var row := _row(&"RowLg")
	var scene := load("res://addons/woldui/components/wold_select/wold_select.tscn")
	for z in [WoldSelect.Size.SM, WoldSelect.Size.MD, WoldSelect.Size.LG]:
		var sel: WoldSelect = scene.instantiate()
		sel.select_size = z
		sel.min_width = 160
		sel.selected = 1 if z == WoldSelect.Size.MD else -1
		sel.disabled = show_disabled
		sel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(sel)
	var faction: WoldSelect = load("res://addons/woldui/gallery/examples/faction_select.tscn").instantiate()
	faction.disabled = show_disabled
	faction.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(faction)
	var scope: WoldScope = load("res://addons/woldui/components/wold_scope/wold_scope.tscn").instantiate()
	var badge: WoldBadge = load("res://addons/woldui/components/wold_badge/wold_badge.tscn").instantiate()
	badge.text = "Your colour"
	badge.tone = WoldBadge.Tone.ACCENT
	badge.fill = WoldBadge.Fill.SOLID
	scope.add_child(badge)
	scope.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	scope.visible = false
	faction.item_selected.connect(func(_i):
		scope.accent = faction.accent()
		scope.visible = true)
	row.add_child(scope)
	s.add_child(row)


## a settings list: the row takes focus, left / right change it
func _wold_steppers() -> void:
	var s := _section("WoldStepper", "components/wold_stepper. The console-style < value > setting. Left and right step it (keys, d-pad or the arrows); up and down move between rows. UiVolume is bound to WoldUI's sound volume.")
	var panel := PanelContainer.new()
	panel.theme_type_variation = &"PanelRaised"
	panel.custom_minimum_size.x = 480
	panel.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	var col := _stack(&"StackXs")
	panel.add_child(col)
	var scene := load("res://addons/woldui/components/wold_stepper/wold_stepper.tscn")
	var difficulty: WoldStepper = scene.instantiate()
	col.add_child(difficulty)
	var turns: WoldStepper = scene.instantiate()
	turns.label = "Turn limit"
	turns.options = PackedStringArray()
	turns.min_value = 50
	turns.max_value = 500
	turns.step = 50
	turns.value = 200
	col.add_child(turns)
	var speed: WoldStepper = scene.instantiate()
	speed.label = "Animation speed"
	speed.options = PackedStringArray(["Slow", "Normal", "Fast", "Instant"])
	speed.wrap = true
	col.add_child(speed)
	col.add_child(load("res://addons/woldui/gallery/examples/ui_volume.tscn").instantiate())
	for st in col.get_children():
		st.disabled = show_disabled
	s.add_child(panel)


## NameField validates as you type; the others show each part
func _wold_fields() -> void:
	var s := _section("WoldField", "components/wold_field. Label, any control in the %Control slot, a hint and an error line. An error gives LineEdit and TextEdit a danger border. Clicking the label focuses the control. NameField checks itself as you type.")
	var row := _row(&"RowXl")
	var name_field: WoldField = load("res://addons/woldui/gallery/examples/name_field.tscn").instantiate()
	name_field.custom_minimum_size.x = 300
	row.add_child(name_field)
	var col := _stack(&"StackLg")
	var sel: WoldSelect = load("res://addons/woldui/components/wold_select/wold_select.tscn").instantiate()
	sel.min_width = 300
	var map := WoldField.make(sel, "Map size", "Bigger maps take longer.")
	col.add_child(map)
	var notes := TextEdit.new()
	notes.custom_minimum_size = Vector2(300, 80)
	notes.placeholder_text = "Anything the other players should know"
	var notes_field := WoldField.make(notes, "Lobby notes")
	notes_field.max_length = 80
	col.add_child(notes_field)
	row.add_child(col)
	var bad := LineEdit.new()
	bad.text = "12"
	var port := WoldField.make(bad, "Port")
	port.error = "Use a port between 1024 and 65535."
	port.custom_minimum_size.x = 260
	row.add_child(port)
	for f in [name_field, map, notes_field, port]:
		var c: Control = f.control()
		if c is LineEdit or c is TextEdit:
			c.editable = not show_disabled
		elif c is BaseButton:
			c.disabled = show_disabled
	s.add_child(row)


## joins whatever buttons you put under it
func _wold_button_strips() -> void:
	var s := _section("WoldButtonStrip", "components/wold_button_strip. Joins the buttons under it into one strip: outer corners stay round, seams are a single line. Any Button, any shape. MapZoom is a vertical one.")
	var row := _row(&"RowXl")
	var scene := load("res://addons/woldui/components/wold_button_strip/wold_button_strip.tscn")
	var button := load("res://addons/woldui/components/wold_button/wold_button.tscn")
	for spec in [[WoldButton.Shape.SECONDARY, [["Undo", "undo-2"], ["Redo", "redo-2"], ["", "clock"]]], [WoldButton.Shape.OUTLINE, [["Day", ""], ["Week", ""], ["Month", ""]]], [WoldButton.Shape.PRIMARY, [["Save", "save"], ["", "chevron-down"]]]]:
		var strip: WoldButtonStrip = scene.instantiate()
		strip.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		for b_spec in spec[1]:
			var b: WoldButton = button.instantiate()
			b.shape = spec[0]
			b.text = b_spec[0]
			b.icon_start = b_spec[1]
			b.disabled = show_disabled
			if b.text == "":
				b.tooltip_text = b_spec[1]
			strip.add_child(b)
		row.add_child(strip)
	var zoom: WoldButtonStrip = load("res://addons/woldui/gallery/examples/map_zoom.tscn").instantiate()
	row.add_child(zoom)
	s.add_child(row)


## UpgradeCard: selectable, one-of-a-group choices
func _wold_cards() -> void:
	var s := _section("WoldCard", "components/wold_card. Header (icon, title, description, %Action), %Content and %Footer; empty parts take no room. selectable makes it a choice you can focus and press; UpgradeCards pick one at a time.")
	var picks := _row(&"RowLg")
	var ups := [["Sharper spears", "Spearmen deal +2 damage.", "swords", 40], ["Granaries", "Cities keep half their food when they grow.", "wheat", 60], ["Scouting", "See two hexes further.", "eye", 0]]
	for u in ups:
		var c: WoldCard = load("res://addons/woldui/gallery/examples/upgrade_card.tscn").instantiate()
		c.title = u[0]
		c.description = u[1]
		c.icon = u[2]
		c.cost = u[3]
		c.size_flags_vertical = Control.SIZE_FILL
		picks.add_child(c)
	s.add_child(picks)
	var row := _row(&"RowLg")
	var info: WoldCard = load("res://addons/woldui/components/wold_card/wold_card.tscn").instantiate()
	info.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	var body := _label("Takes 6 turns. Only one civilisation can build it.", &"Body")
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info.get_node("%Content").add_child(body)
	var meter := WoldMeter.new()
	meter.value = 35
	meter.show_percentage = false
	meter.custom_minimum_size.y = 8
	info.get_node("%Content").add_child(meter)
	var build: WoldButton = load("res://addons/woldui/components/wold_button/wold_button.tscn").instantiate()
	build.text = "Build"
	build.shape = WoldButton.Shape.PRIMARY
	build.disabled = show_disabled
	info.get_node("%Footer").add_child(build)
	var later: WoldButton = load("res://addons/woldui/components/wold_button/wold_button.tscn").instantiate()
	later.text = "Later"
	later.shape = WoldButton.Shape.GHOST
	info.get_node("%Footer").add_child(later)
	row.add_child(info)
	var small: WoldCard = load("res://addons/woldui/components/wold_card/wold_card.tscn").instantiate()
	small.card_size = WoldCard.Size.SM
	small.title = "Rivermouth"
	small.description = "Pop 12, +4 gold"
	small.icon = "castle"
	small.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	small.custom_minimum_size.x = 220
	row.add_child(small)
	s.add_child(row)


## CodexAccordion keeps one section open; UnitDetails fills itself
func _wold_disclosure() -> void:
	var s := _section("WoldCollapsible / WoldAccordion", "components/wold_collapsible, wold_accordion. The height slides open and closed content is really hidden, so focus can't land in it. An accordion is collapsibles as children, one open at a time unless multiple.")
	var row := _row(&"RowXxl")
	var codex: WoldAccordion = load("res://addons/woldui/gallery/examples/codex_accordion.tscn").instantiate()
	codex.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	row.add_child(codex)
	var col := _stack(&"StackSm")
	col.custom_minimum_size.x = 320
	col.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	var unit: WoldCollapsible = load("res://addons/woldui/gallery/examples/unit_details.tscn").instantiate()
	unit.open = true
	col.add_child(unit)
	var rider: WoldCollapsible = load("res://addons/woldui/gallery/examples/unit_details.tscn").instantiate()
	rider.title = "Rider"
	rider.icon = "rabbit"
	var st: Dictionary[String, String] = {}
	st.assign({"Attack": "7", "Defence": "3", "Move": "4"})
	rider.stats = st
	col.add_child(rider)
	row.add_child(col)
	for c in [codex.items()[0].trigger(), codex.items()[1].trigger(), unit.trigger()]:
		c.disabled = show_disabled
	s.add_child(row)


## FactionLeader and LobbyPlayers are scene-only examples
func _wold_avatars() -> void:
	var s := _section("WoldAvatar / WoldAvatarGroup", "components/wold_avatar, wold_avatar_group. A portrait cropped round or square, initials when there's no picture, a presence dot. Groups overlap and fold the rest into +N.")
	var scene := load("res://addons/woldui/components/wold_avatar/wold_avatar.tscn")
	var row := _row(&"RowLg")
	var portrait := _gradient_portrait()
	var people := [["Queen Mab", WoldAvatar.Size.SM, null, WoldAvatar.Status.NONE], ["Old Tom", WoldAvatar.Size.MD, null, WoldAvatar.Status.ONLINE], ["Ivy", WoldAvatar.Size.LG, null, WoldAvatar.Status.AWAY], ["Bramble", WoldAvatar.Size.LG, portrait, WoldAvatar.Status.BUSY]]
	for p in people:
		var a: WoldAvatar = scene.instantiate()
		a.display_name = p[0]
		a.avatar_size = p[1]
		a.texture = p[2]
		a.status = p[3]
		a.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(a)
	for f in [["Ants", Color("c0392b")], ["Spidobots", Color("3a7bd5")], ["Moles", Color("5da574")]]:
		var a: WoldAvatar = scene.instantiate()
		a.display_name = f[0]
		a.color = f[1]
		a.shape = WoldAvatar.Shape.SQUARE
		a.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(a)
	var leader: WoldAvatar = load("res://addons/woldui/gallery/examples/faction_leader.tscn").instantiate()
	leader.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(leader)
	s.add_child(row)
	var groups := _row(&"RowXxl")
	groups.add_child(load("res://addons/woldui/components/wold_avatar_group/wold_avatar_group.tscn").instantiate())
	groups.add_child(load("res://addons/woldui/gallery/examples/lobby_players.tscn").instantiate())
	s.add_child(groups)


func _gradient_portrait() -> Texture2D:
	var g := Gradient.new()
	g.set_color(0, tokens.tone("accent", 300))
	g.set_color(1, tokens.tone("accent", 800))
	var tex := GradientTexture2D.new()
	tex.gradient = g
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.4, 0.3)
	tex.fill_to = Vector2(1.0, 1.0)
	tex.width = 64
	tex.height = 64
	return tex


## TreatyAlert: danger, an action and a close button
func _wold_alerts() -> void:
	var s := _section("WoldAlert", "components/wold_alert. A banner in the layout, unlike a toast. Tone picks the colour and a default icon; buttons go in %Action; dismissible adds a close button.")
	var grid := GridContainer.new()
	grid.columns = 2
	grid.theme_type_variation = &"GridMd"
	var scene := load("res://addons/woldui/components/wold_alert/wold_alert.tscn")
	var samples := [[WoldAlert.Tone.NEUTRAL, "Autosave is on", "Every 5 turns, the last 3 are kept."], [WoldAlert.Tone.ACCENT, "New wonder available", ""], [WoldAlert.Tone.SUCCESS, "Treaty signed", "The Ants will trade wood for gold for 20 turns."], [WoldAlert.Tone.WARNING, "Low food", "Your population stops growing next turn."]]
	for sample in samples:
		var a: WoldAlert = scene.instantiate()
		a.tone = sample[0]
		a.title = sample[1]
		a.description = sample[2]
		a.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		grid.add_child(a)
	var treaty: WoldAlert = load("res://addons/woldui/gallery/examples/treaty_alert.tscn").instantiate()
	treaty.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_child(treaty)
	var again: WoldButton = load("res://addons/woldui/components/wold_button/wold_button.tscn").instantiate()
	again.text = "Show it again"
	again.shape = WoldButton.Shape.GHOST
	again.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	again.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	again.pressed.connect(func(): WoldMotion.appear(treaty))
	grid.add_child(again)
	s.add_child(grid)


## the quiet ones: NoSaves, TextSkeleton, SavingSpinner, TurnDivider
func _wold_status() -> void:
	var s := _section("WoldEmpty / WoldSkeleton / WoldSpinner / WoldSeparator", "Nothing here yet, still loading, working on it, and a line with an optional label. The skeleton breathes and the spinner turns; under Reduce motion both hold still.")
	var row := _row(&"RowXxl")
	var empty: WoldEmpty = load("res://addons/woldui/gallery/examples/no_saves.tscn").instantiate()
	empty.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	row.add_child(empty)
	var loading := _stack(&"StackMd")
	loading.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	var person := _row(&"RowMd")
	var face: WoldSkeleton = load("res://addons/woldui/components/wold_skeleton/wold_skeleton.tscn").instantiate()
	face.shape = WoldSkeleton.Shape.ROUND
	face.custom_minimum_size = Vector2(40, 40)
	person.add_child(face)
	person.add_child(load("res://addons/woldui/gallery/examples/text_skeleton.tscn").instantiate())
	loading.add_child(person)
	loading.add_child(load("res://addons/woldui/components/wold_skeleton/wold_skeleton.tscn").instantiate())
	var spinners := _row(&"RowLg")
	for z in [WoldSpinner.Size.SM, WoldSpinner.Size.MD]:
		var sp: WoldSpinner = load("res://addons/woldui/components/wold_spinner/wold_spinner.tscn").instantiate()
		sp.spinner_size = z
		spinners.add_child(sp)
	spinners.add_child(load("res://addons/woldui/gallery/examples/saving_spinner.tscn").instantiate())
	spinners.add_child(_label("Saving...", &"Muted"))
	loading.add_child(spinners)
	row.add_child(loading)
	var lines := _stack(&"StackLg")
	lines.custom_minimum_size.x = 280
	lines.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	var plain: WoldSeparator = load("res://addons/woldui/components/wold_separator/wold_separator.tscn").instantiate()
	plain.text = ""
	lines.add_child(plain)
	lines.add_child(load("res://addons/woldui/components/wold_separator/wold_separator.tscn").instantiate())
	lines.add_child(load("res://addons/woldui/gallery/examples/turn_divider.tscn").instantiate())
	row.add_child(lines)
	s.add_child(row)


## HowToPlay: pages are children; StepDots on its own
func _wold_carousels() -> void:
	var s := _section("WoldCarousel / WoldPageDots", "components/wold_carousel, wold_page_dots. One page at a time with arrows and dots; the page slides in from the side you went, and LB / RB flip pages while focus is inside. The dots work on their own too.")
	var row := _row(&"RowXxl")
	var panel := PanelContainer.new()
	panel.theme_type_variation = &"PanelRaised"
	panel.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	panel.add_child(load("res://addons/woldui/gallery/examples/how_to_play.tscn").instantiate())
	row.add_child(panel)
	var col := _stack(&"StackMd")
	col.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var dots: WoldPageDots = load("res://addons/woldui/gallery/examples/step_dots.tscn").instantiate()
	col.add_child(dots)
	var note := _label("", &"Muted")
	var show := func(i: int): note.text = "Step %d of %d" % [i + 1, dots.count]
	dots.page_selected.connect(show)
	show.call(dots.current)
	col.add_child(note)
	row.add_child(col)
	s.add_child(row)


## UnitMenu builds itself; right-click the panel for a context menu
func _wold_menus() -> void:
	var s := _section("WoldMenu", "components/wold_menu. A PopupMenu you fill in code, one callback per item: icons, shortcuts, checks, radio groups, submenus, danger items. open_at(control) for a dropdown, open_at_mouse() for a context menu. Focus goes back when it closes.")
	var row := _row(&"RowXl")
	var unit: WoldButton = load("res://addons/woldui/components/wold_button/wold_button.tscn").instantiate()
	unit.text = "Spearman"
	unit.icon_start = "swords"
	unit.icon_end = "chevron-down"
	unit.disabled = show_disabled
	var menu: WoldMenu = load("res://addons/woldui/gallery/examples/unit_menu.tscn").instantiate()
	unit.add_child(menu)
	var said := _label("", &"Muted")
	menu.command.connect(func(what): said.text = "command: %s" % what)
	unit.pressed.connect(func(): menu.open_at(unit))
	row.add_child(unit)
	var area := PanelContainer.new()
	area.theme_type_variation = &"PanelSunken"
	area.custom_minimum_size = Vector2(240, 60)
	area.add_child(_label("Right-click here", &"Muted"))
	var ctx := WoldMenu.new()
	ctx.item("Copy", func(): said.text = "copied", "copy", "Ctrl+C")
	ctx.item("Paste", func(): said.text = "pasted", "clipboard", "Ctrl+V")
	area.add_child(ctx)
	area.gui_input.connect(func(e):
		if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_RIGHT:
			ctx.open_at_mouse())
	row.add_child(area)
	var bar := MenuBar.new()
	for title in ["Game", "View"]:
		var pm := WoldMenu.new()
		pm.name = title
		pm.item("New", Callable(), "plus")
		pm.item("Load", Callable(), "folder-open")
		bar.add_child(pm)
	bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(bar)
	said.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(said)
	s.add_child(row)


## click for a small form, hover (or focus) the city for CityCard
func _wold_popovers() -> void:
	var s := _section("WoldPopover", "components/wold_popover. A panel that floats next to the Control it's under, flipped and kept on screen. CLICK opens from the anchor, HOVER is a hover card that keyboard and pad focus open too. Esc, a click outside or focus leaving closes it.")
	var row := _row(&"RowXl")
	var rename: WoldButton = load("res://addons/woldui/components/wold_button/wold_button.tscn").instantiate()
	rename.text = "Rename army"
	rename.icon_start = "pencil"
	rename.disabled = show_disabled
	var pop: WoldPopover = load("res://addons/woldui/components/wold_popover/wold_popover.tscn").instantiate()
	pop.title = "Rename army"
	pop.description = "Shown on the map and in reports."
	var name_edit := LineEdit.new()
	name_edit.text = "First Spears"
	pop.get_node("%Content").add_child(name_edit)
	var save: WoldButton = load("res://addons/woldui/components/wold_button/wold_button.tscn").instantiate()
	save.text = "Save"
	save.shape = WoldButton.Shape.PRIMARY
	save.button_size = WoldButton.Size.SM
	save.size_flags_horizontal = Control.SIZE_SHRINK_END
	save.pressed.connect(pop.close)
	pop.get_node("%Content").add_child(save)
	rename.add_child(pop)
	row.add_child(rename)
	var city: WoldButton = load("res://addons/woldui/components/wold_button/wold_button.tscn").instantiate()
	city.text = "Rivermouth"
	city.icon_start = "castle"
	city.shape = WoldButton.Shape.GHOST
	city.add_child(load("res://addons/woldui/gallery/examples/city_card.tscn").instantiate())
	row.add_child(city)
	s.add_child(row)


## sheets open on their own layer, like WoldDialog.ask()
func _wold_sheets() -> void:
	var s := _section("WoldSheet / small WoldDialog", "components/wold_sheet. A WoldDialog that slides in from an edge: the same props, focus trap, Esc and scrim. dialog_size SM is the quick yes / no: narrow, centred, buttons share the width.")
	var row := _row(&"RowSm")
	for e in [["Right", WoldSheet.Edge.RIGHT, "panel-right"], ["Left", WoldSheet.Edge.LEFT, "panel-left"], ["Bottom", WoldSheet.Edge.BOTTOM, "panel-bottom"]]:
		var b: WoldButton = load("res://addons/woldui/components/wold_button/wold_button.tscn").instantiate()
		b.text = e[0]
		b.icon_start = e[2]
		b.shape = WoldButton.Shape.OUTLINE
		var edge: int = e[1]
		b.pressed.connect(func(): _open_layered(func():
			var sheet: WoldSheet = load("res://addons/woldui/gallery/examples/city_sheet.tscn").instantiate()
			sheet.edge = edge
			sheet.extent = 300 if edge == WoldSheet.Edge.BOTTOM else 380
			return sheet))
		row.add_child(b)
	var small: WoldButton = load("res://addons/woldui/components/wold_button/wold_button.tscn").instantiate()
	small.text = "Small dialog"
	small.icon_start = "message-circle-question-mark"
	small.pressed.connect(func(): _open_layered(func():
		var d: WoldDialog = load("res://addons/woldui/components/wold_dialog/wold_dialog.tscn").instantiate()
		d.dialog_size = WoldDialog.Size.SM
		d.title = "End your turn?"
		d.message = "Two units still have moves left."
		d.icon = ""
		d.confirm_text = "End turn"
		d.cancel_text = "Keep playing"
		d.free_on_close = true
		return d))
	row.add_child(small)
	s.add_child(row)


# a dialog or sheet on its own top layer, gone when it closes
func _open_layered(make: Callable) -> void:
	var layer := CanvasLayer.new()
	layer.layer = 100
	add_child(layer)
	var d: WoldDialog = make.call()
	d.free_on_close = true
	d.tree_exited.connect(layer.queue_free)
	layer.add_child(d)
	d.open()


## DiplomacyLog: say() lines and turn markers; scroll up to see "N new"
func _wold_chat() -> void:
	var s := _section("WoldBubble / WoldMessage / WoldMessageLog / WoldKbd", "Speech bubbles with a squared-off tail, chat lines with avatars (yours on the right), and a log that follows new lines unless you've scrolled up. WoldKbd draws key caps for a written shortcut.")
	var row := _row(&"RowXxl")
	var panel := PanelContainer.new()
	panel.theme_type_variation = &"PanelRaised"
	var col := _stack(&"StackSm")
	panel.add_child(col)
	var log_view = load("res://addons/woldui/gallery/examples/diplomacy_log.tscn").instantiate()
	col.add_child(log_view)
	var lines := [["The Ants", "Your scouts are on our land.", false], ["You", "Just passing through.", true], ["The Ants", "Then pass faster.", false]]
	log_view.turn(41)
	for l in lines:
		log_view.say(l[0], l[1], l[2])
	log_view.turn(42)
	var more := [["The Ants", "We could use some wood."], ["The Ants", "20 wood for 10 gold?"], ["Spidobots", "Beep. Declined on their behalf."]]
	var next := [0]
	var say: WoldButton = load("res://addons/woldui/components/wold_button/wold_button.tscn").instantiate()
	say.text = "Next line"
	say.button_size = WoldButton.Size.SM
	say.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	say.pressed.connect(func():
		var l: Array = more[next[0] % more.size()]
		log_view.say(l[0], l[1])
		next[0] += 1)
	col.add_child(say)
	row.add_child(panel)
	var side := _stack(&"StackLg")
	side.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	side.add_child(load("res://addons/woldui/gallery/examples/npc_bark.tscn").instantiate())
	side.add_child(load("res://addons/woldui/gallery/examples/trade_offer.tscn").instantiate())
	var keys := _row(&"RowMd")
	keys.add_child(_label("Quick save", &"Muted"))
	keys.add_child(load("res://addons/woldui/gallery/examples/save_shortcut.tscn").instantiate())
	side.add_child(keys)
	row.add_child(side)
	s.add_child(row)


func _wold_tabs() -> void:
	var s := _section("WoldTabs", "components/wold_tabs. Pages are the node's children; page metadata adds icons and badges. The underline slides; LB / RB switch tabs.")
	var panel := PanelContainer.new()
	panel.theme_type_variation = &"PanelRaised"
	panel.custom_minimum_size = Vector2(560, 0)
	panel.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	panel.add_child(load("res://addons/woldui/gallery/examples/tabs_example.tscn").instantiate())
	s.add_child(panel)
	var bar: WoldTabs = load("res://addons/woldui/components/wold_tabs/wold_tabs.tscn").instantiate()
	bar.tabs = PackedStringArray(["Small", "Medium", "Large"])
	bar.stretch = true
	bar.custom_minimum_size.x = 420
	bar.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	s.add_child(bar)


## TODO: the wold_demo_* actions are added to the InputMap and never removed.
func _wold_prompts() -> void:
	var s := _section("WoldButtonPrompt", "components/wold_button_prompt. Glyphs from the real bindings; switches live between keyboard, pad and mouse. Try it: press a key, then a pad button.")
	var actions := {
		&"wold_demo_confirm": ["Confirm", [_demo_key(KEY_ENTER), _demo_pad(JOY_BUTTON_A), _demo_mouse(MOUSE_BUTTON_LEFT)]],
		&"wold_demo_back": ["Back", [_demo_key(KEY_ESCAPE), _demo_pad(JOY_BUTTON_B), _demo_mouse(MOUSE_BUTTON_RIGHT)]],
		&"wold_demo_next_tab": ["Next tab", [_demo_key(KEY_E), _demo_pad(JOY_BUTTON_RIGHT_SHOULDER)]],
		&"wold_demo_end_turn": ["End turn", [_demo_key(KEY_SPACE), _demo_pad(JOY_BUTTON_Y)]],
	}
	for action in actions:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
			for e in actions[action][1]:
				InputMap.action_add_event(action, e)
	var scene := load("res://addons/woldui/components/wold_button_prompt/wold_button_prompt.tscn")
	var rows := [
		["Live", WoldButtonPrompt.InputKind.AUTO, WoldButtonPrompt.PadFamily.AUTO],
		["Keyboard", WoldButtonPrompt.InputKind.KEYBOARD, WoldButtonPrompt.PadFamily.AUTO],
		["Xbox", WoldButtonPrompt.InputKind.PAD, WoldButtonPrompt.PadFamily.XBOX],
		["PlayStation", WoldButtonPrompt.InputKind.PAD, WoldButtonPrompt.PadFamily.PLAYSTATION],
		["Nintendo", WoldButtonPrompt.InputKind.PAD, WoldButtonPrompt.PadFamily.NINTENDO],
	]
	for r in rows:
		var row := _row(&"RowXl")
		var tag := _label(r[0], &"Caption")
		tag.custom_minimum_size.x = 120
		row.add_child(tag)
		for action in actions:
			var p: WoldButtonPrompt = scene.instantiate()
			p.action = action
			p.label = actions[action][0]
			p.input_kind = r[1]
			p.pad_family = r[2]
			row.add_child(p)
		s.add_child(row)


func _demo_key(code: Key) -> InputEventKey:
	var e := InputEventKey.new()
	e.keycode = code
	return e


func _demo_pad(button: JoyButton) -> InputEventJoypadButton:
	var e := InputEventJoypadButton.new()
	e.button_index = button
	return e


func _demo_mouse(button: MouseButton) -> InputEventMouseButton:
	var e := InputEventMouseButton.new()
	e.button_index = button
	return e


## WoldScope: the same panel under three faction accents.
func _wold_scopes() -> void:
	var s := _section("WoldScope", "components/wold_scope. Token overrides for one subtree, like CSS variables on a wrapper. Same panel, three faction accents.")
	var row := _row(&"RowLg")
	var factions := [["Ants", Color("c0392b"), "bug"], ["Spidobots", Color("3a7bd5"), "bot"], ["Moles", Color("5da574"), "shovel"]]
	for f in factions:
		var scope: WoldScope = load("res://addons/woldui/components/wold_scope/wold_scope.tscn").instantiate()
		scope.accent = f[1]
		var panel := PanelContainer.new()
		panel.theme_type_variation = &"PanelRaised"
		var col := _stack(&"StackMd")
		var head := _row(&"RowSm")
		var badge: WoldBadge = load("res://addons/woldui/components/wold_badge/wold_badge.tscn").instantiate()
		badge.text = f[0]
		badge.icon = f[2]
		badge.tone = WoldBadge.Tone.ACCENT
		head.add_child(badge)
		col.add_child(head)
		var stat: WoldStat = load("res://addons/woldui/components/wold_stat/wold_stat.tscn").instantiate()
		stat.icon = "castle"
		stat.value = 4
		stat.label = "Cities"
		stat.tone = WoldStat.Tone.ACCENT
		stat.surface = WoldStat.Surface.BARE
		col.add_child(stat)
		var b: WoldButton = load("res://addons/woldui/components/wold_button/wold_button.tscn").instantiate()
		b.text = "Declare war"
		b.shape = WoldButton.Shape.PRIMARY
		b.icon_start = "swords"
		col.add_child(b)
		panel.add_child(col)
		scope.add_child(panel)
		row.add_child(scope)
	s.add_child(row)


## WoldScreen: push the example settings screen; Esc / B or Back pops it.
func _wold_screens() -> void:
	var s := _section("WoldScreen", "components/wold_screen. push() / pop() with transitions; Esc or B goes back; focus returns to what opened it.")
	var b: WoldButton = load("res://addons/woldui/components/wold_button/wold_button.tscn").instantiate()
	b.text = "Push the settings screen"
	b.icon_start = "settings"
	b.icon_end = "arrow-right"
	b.shape = WoldButton.Shape.SECONDARY
	b.sound = "open"
	b.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	b.pressed.connect(func(): WoldScreen.push(self, "res://addons/woldui/gallery/examples/settings_screen.tscn"))
	s.add_child(b)


func _motion() -> void:
	var ui := WoldUIRuntime.instance()
	var s := _section("Motion & feedback", "Every animation goes through WoldMotion and honours Reduce motion. Buttons get hover, press and sound from a WoldFeedback node.")

	var prefs := _row(&"RowXl")
	var reduce := CheckButton.new()
	reduce.text = "Reduce motion"
	reduce.button_pressed = ui.reduced_motion
	reduce.toggled.connect(func(on): ui.reduced_motion = on)
	prefs.add_child(reduce)
	var sound := CheckButton.new()
	sound.text = "Sound"
	sound.button_pressed = ui.sound_enabled
	sound.toggled.connect(func(on): ui.sound_enabled = on)
	prefs.add_child(sound)
	_mode_label = _label("", &"Muted")
	_mode_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_on_input_mode(ui.input_mode)
	if not ui.input_mode_changed.is_connected(_on_input_mode):
		ui.input_mode_changed.connect(_on_input_mode)
	prefs.add_child(_mode_label)
	s.add_child(prefs)

	var stage := PanelContainer.new()
	stage.theme_type_variation = &"PanelSunken"
	stage.custom_minimum_size = Vector2(0, 120)
	var card := PanelContainer.new()
	card.theme_type_variation = &"PanelOverlay"
	card.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	card.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var card_label := _label("Sample card", &"Subheading")
	card.add_child(card_label)
	stage.add_child(card)
	var presets := HFlowContainer.new()
	presets.theme_type_variation = &"FlowSm"
	for preset_name in WoldMotion.preset_names():
		var b := Button.new()
		b.theme_type_variation = &"ButtonOutlineSm"
		b.text = preset_name
		b.icon = tokens.icon("play", "Sm")
		b.pressed.connect(func():
			card_label.text = preset_name
			var p := WoldMotion.preset(preset_name)
			if preset_name.contains("disappear") or preset_name.ends_with("_out") or preset_name.ends_with("_exit"):
				await WoldMotion.disappear(card, p).finished
				await get_tree().create_timer(0.35).timeout
				WoldMotion.appear(card, WoldMotion.preset("appear_fade"))
			else:
				card.visible = false
				WoldMotion.appear(card, p))
		presets.add_child(b)
	s.add_child(presets)
	s.add_child(stage)

	var demos := _row(&"RowXl")
	var list := _stack(&"StackXs")
	list.custom_minimum_size.x = 220
	for i in 5:
		var row := PanelContainer.new()
		row.theme_type_variation = &"PanelRaised"
		row.add_child(_label("List item %d" % (i + 1), &"Body"))
		list.add_child(row)
	var list_col := _stack(&"StackSm")
	var list_play := Button.new()
	list_play.theme_type_variation = &"ButtonSecondarySm"
	list_play.text = "Stagger in"
	list_play.icon = tokens.icon("list", "Sm")
	list_play.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	list_play.pressed.connect(func(): WoldMotion.stagger(list.get_children()))
	list_col.add_child(list_play)
	list_col.add_child(list)
	demos.add_child(list_col)

	var counter_col := _stack(&"StackSm")
	var gold := _label("0 gold", &"Title")
	var total := [0]
	var earn := Button.new()
	earn.theme_type_variation = &"ButtonPrimarySm"
	earn.text = "Earn 120"
	earn.icon = tokens.icon("coins", "Sm")
	earn.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	earn.set_meta("wold_sound", "confirm")
	earn.pressed.connect(func():
		WoldMotion.count_to(gold, total[0], total[0] + 120, "%d gold")
		total[0] += 120)
	counter_col.add_child(earn)
	counter_col.add_child(gold)
	var waiting := _label("Waiting for the other player…", &"Muted")
	counter_col.add_child(waiting)
	if not Engine.is_editor_hint():
		WoldMotion.pulse.call_deferred(waiting)
	demos.add_child(counter_col)

	var sounds_col := _stack(&"StackSm")
	sounds_col.add_child(_label("Button sounds (wold_sound metadata)", &"Caption"))
	var sound_row := _row(&"RowSm")
	for slot in ["click", "confirm", "back", "open", "close"]:
		var b := Button.new()
		b.theme_type_variation = &"ButtonSecondarySm"
		b.text = slot.capitalize()
		b.set_meta("wold_sound", slot)
		sound_row.add_child(b)
	sounds_col.add_child(sound_row)
	var locked := Button.new()
	locked.theme_type_variation = &"ButtonSecondarySm"
	locked.text = "Locked (click me)"
	locked.icon = tokens.icon("lock", "Sm")
	locked.disabled = true
	sounds_col.add_child(locked)
	demos.add_child(sounds_col)
	s.add_child(demos)


func _colours() -> void:
	var s := _section("Colour", "One seed per tone; every step and role is derived. Ratios are contrast on surface_raised.")
	for tone in ["neutral", "accent", "success", "warning", "danger"]:
		var row := _row(&"RowXs")
		var name_label := _label(tone, &"Caption")
		name_label.custom_minimum_size.x = 80
		row.add_child(name_label)
		var ramp := tokens.ramp(tone)
		for step in WoldColor.STEPS:
			var chip := ColorRect.new()
			chip.color = ramp[step]
			chip.custom_minimum_size = Vector2(44, 28)
			chip.tooltip_text = "%s %d  #%s" % [tone, step, ramp[step].to_html(false)]
			row.add_child(chip)
		s.add_child(row)
	var grid := GridContainer.new()
	grid.theme_type_variation = &"GridSm"
	grid.columns = 4
	var bg := tokens.role("surface_raised")
	for role in tokens.role_names():
		var cell := _row(&"RowSm")
		var chip := ColorRect.new()
		chip.color = tokens.role(role)
		chip.custom_minimum_size = Vector2(28, 20)
		cell.add_child(chip)
		cell.add_child(_label(role, &"Caption"))
		cell.add_child(_label("%.1f" % WoldColor.contrast(tokens.role(role), bg), &"Muted"))
		cell.custom_minimum_size.x = 240
		grid.add_child(cell)
	s.add_child(grid)


func _type() -> void:
	var s := _section("Type", "Size is picked by role. base_font_size %d, ratio %.3f." % [tokens.base_font_size, tokens.type_ratio])
	for style in ["Display", "Title", "Heading", "Subheading", "Body", "Caption", "Overline", "Muted", "TextAccent", "TextSuccess", "TextWarning", "TextDanger", "TextOutlined"]:
		var row := _row(&"RowLg")
		var tag := _label(style, &"Caption")
		tag.custom_minimum_size.x = 120
		row.add_child(tag)
		row.add_child(_label(SAMPLE if style != "Overline" else SAMPLE.to_upper(), style))
		s.add_child(row)


func _buttons() -> void:
	var s := _section("Buttons", "Shape × size. A plain Button is ButtonSecondary. Tab / arrow keys move focus.")
	var shape_icons := {"Primary": "swords", "Secondary": "castle", "Outline": "map", "Ghost": "eye", "Danger": "trash", "Icon": "settings"}
	for shape in ["Primary", "Secondary", "Outline", "Ghost", "Danger", "Icon"]:
		var row := _row(&"RowMd")
		var tag := _label(shape, &"Caption")
		tag.custom_minimum_size.x = 120
		row.add_child(tag)
		for size in ["Sm", "", "Lg"]:
			var b := Button.new()
			b.theme_type_variation = StringName("Button" + shape + size)
			b.text = "" if shape == "Icon" else (shape + (" " + size if size != "" else " Md"))
			b.icon = tokens.icon(shape_icons[shape], size)
			b.disabled = show_disabled
			b.tooltip_text = "Button" + shape + size
			row.add_child(b)
		var toggle := Button.new()
		toggle.theme_type_variation = StringName("Button" + shape)
		toggle.toggle_mode = true
		toggle.button_pressed = true
		toggle.text = "" if shape == "Icon" else "Toggled"
		toggle.icon = tokens.icon("check") if shape == "Icon" else null
		toggle.disabled = show_disabled
		row.add_child(toggle)
		s.add_child(row)


func _inputs() -> void:
	var s := _section("Inputs", "")
	var fields := _row(&"RowMd")
	for style in ["FieldSm", "LineEdit", "FieldLg"]:
		var e := LineEdit.new()
		e.theme_type_variation = StringName(style)
		e.placeholder_text = style
		e.custom_minimum_size.x = 200
		e.editable = not show_disabled
		fields.add_child(e)
	s.add_child(fields)
	var toggles := _row(&"RowXl")
	var cb := CheckBox.new()
	cb.text = "Check box"
	cb.button_pressed = true
	cb.disabled = show_disabled
	toggles.add_child(cb)
	var cb2 := CheckBox.new()
	cb2.text = "Unchecked"
	cb2.disabled = show_disabled
	toggles.add_child(cb2)
	var sw := CheckButton.new()
	sw.text = "Switch"
	sw.button_pressed = true
	sw.disabled = show_disabled
	toggles.add_child(sw)
	var opt := OptionButton.new()
	for item in ["Small map", "Medium map", "Large map"]:
		opt.add_item(item)
	opt.disabled = show_disabled
	toggles.add_child(opt)
	var spin := SpinBox.new()
	spin.value = 4
	spin.editable = not show_disabled
	toggles.add_child(spin)
	s.add_child(toggles)
	var slider := HSlider.new()
	slider.value = 40
	slider.custom_minimum_size.x = 320
	slider.editable = not show_disabled
	s.add_child(slider)
	var text := TextEdit.new()
	text.placeholder_text = "TextEdit"
	text.custom_minimum_size = Vector2(420, 90)
	text.editable = not show_disabled
	s.add_child(text)


func _meters_and_tabs() -> void:
	var s := _section("Meters", "Pair a meter with a label or icon: colour alone never carries meaning.")
	for style in ["ProgressBar", "MeterAccent", "MeterSuccess", "MeterWarning", "MeterDanger", "MeterThin"]:
		var row := _row(&"RowMd")
		var tag := _label(style, &"Caption")
		tag.custom_minimum_size.x = 120
		row.add_child(tag)
		var bar := ProgressBar.new()
		bar.theme_type_variation = StringName(style)
		bar.value = 65
		bar.show_percentage = style == "ProgressBar"
		bar.custom_minimum_size.x = 360
		row.add_child(bar)
		s.add_child(row)
	var t := _section("Tabs", "")
	var tabs := TabContainer.new()
	tabs.custom_minimum_size = Vector2(480, 140)
	for tab_name in ["Army", "Economy", "Research"]:
		var page := MarginContainer.new()
		page.name = tab_name
		page.add_child(_label("%s tab content" % tab_name, &"Body"))
		tabs.add_child(page)
	t.add_child(tabs)


## two values per mode: TILE / REVEAL keep the art's shape, STRETCH squashes it
func _fills() -> void:
	var s := _section("Textured fills", "WoldMeter and WoldSlider take a WoldFill. TILE and REVEAL keep the artwork's shape as the value moves; STRETCH squashes it.")
	var stripes := _stripes()
	var gradient := _gradient()
	for mode in [WoldFill.Mode.TILE, WoldFill.Mode.REVEAL, WoldFill.Mode.STRETCH]:
		var row := _row(&"RowLg")
		var tag := _label(WoldFill.Mode.keys()[mode], &"Caption")
		tag.custom_minimum_size.x = 120
		row.add_child(tag)
		for v in [30, 80]:
			var f := WoldFill.new()
			f.mode = mode
			f.texture = stripes if mode == WoldFill.Mode.TILE else gradient
			var meter := WoldMeter.new()
			meter.fill = f
			meter.value = v
			meter.show_percentage = false
			meter.custom_minimum_size = Vector2(260, 16)
			meter.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			row.add_child(meter)
		s.add_child(row)
	var slider_row := _row(&"RowLg")
	var tag := _label("WoldSlider", &"Caption")
	tag.custom_minimum_size.x = 120
	slider_row.add_child(tag)
	var fill := WoldFill.new()
	fill.texture = stripes
	var slider := WoldSlider.new()
	slider.fill = fill
	slider.track_height = 10
	slider.value = 60
	slider.editable = not show_disabled
	slider.custom_minimum_size = Vector2(540, 24)
	slider_row.add_child(slider)
	s.add_child(slider_row)


## click an icon to copy its name
func _icons() -> void:
	var total := WoldIcons.names().size()
	var s := _section("Icons", "%d Lucide icons (v%s) plus your own icon set. Click one to copy its name; use it as tokens.icon(\"name\")." % [total, WoldIcons.version()])
	var bar := _row(&"RowMd")
	var search := LineEdit.new()
	search.placeholder_text = "Search icons…"
	search.custom_minimum_size.x = 320
	search.right_icon = tokens.icon("search", "Sm")
	bar.add_child(search)
	var note := _label("", &"Muted")
	bar.add_child(note)
	s.add_child(bar)
	var grid := HFlowContainer.new()
	grid.theme_type_variation = &"FlowXs"
	s.add_child(grid)
	var fill_grid := func(query: String) -> void:
		for child in grid.get_children():
			child.queue_free()
		var names := PackedStringArray()
		if tokens.icon_set:
			for n in tokens.icon_set.custom_names():
				if query == "" or n.contains(query.to_lower()):
					names.append(n)
		names.append_array(WoldIcons.search(query, 160))
		for n in names:
			var b := Button.new()
			b.theme_type_variation = &"ButtonIcon"
			b.icon = tokens.icon(n)
			b.tooltip_text = n
			b.pressed.connect(func():
				DisplayServer.clipboard_set(n)
				note.text = "Copied \"%s\"" % n)
			grid.add_child(b)
		note.text = "%d shown" % names.size()
	search.text_changed.connect(fill_grid)
	fill_grid.call("")


func _panels() -> void:
	var s := _section("Panels", "")
	var flow := HFlowContainer.new()
	flow.theme_type_variation = &"FlowLg"
	for style in ["PanelRaised", "PanelOverlay", "PanelHud", "PanelSunken", "PanelCallout"]:
		var panel := PanelContainer.new()
		panel.theme_type_variation = StringName(style)
		panel.custom_minimum_size.x = 240
		var inner := _stack(&"StackXs")
		inner.add_child(_label(style, &"Subheading"))
		inner.add_child(_label("Body copy sits on this surface.", &"Muted"))
		panel.add_child(inner)
		flow.add_child(panel)
	s.add_child(flow)


func _layout() -> void:
	var s := _section("Spacing", "Stack / Row / Inset / Grid / Flow + Xs…Xxl, one per space token.")
	var row := _row(&"RowXl")
	for size in ["Xs", "Sm", "Md", "Lg", "Xl", "Xxl"]:
		var col := _stack(&"StackXs")
		col.add_child(_label("Row" + size, &"Caption"))
		var demo := _row(StringName("Row" + size))
		for i in 3:
			var chip := ColorRect.new()
			chip.color = tokens.role("accent")
			chip.custom_minimum_size = Vector2(14, 14)
			demo.add_child(chip)
		col.add_child(demo)
		row.add_child(col)
	s.add_child(row)


func _game_styles() -> void:
	var core := {}
	for recipe in WoldThemeBuilder.CORE_RECIPES:
		for style in recipe.STYLES:
			core[style] = true
	var extra := PackedStringArray()
	for style in WoldThemeBuilder.variation_names(theme):
		if not core.has(style):
			extra.append(style)
	if extra.is_empty():
		return
	var s := _section("Game styles", "From this tokens file's variants and extra recipes.")
	var flow := HFlowContainer.new()
	flow.theme_type_variation = &"FlowLg"
	for style in extra:
		flow.add_child(_sample_for(style))
	s.add_child(flow)


func _sample_for(style: String) -> Control:
	var native := WoldThemeBuilder.native_base(theme, style)
	var node: Control
	if ClassDB.is_parent_class(native, "BaseButton"):
		var b := Button.new()
		b.text = style
		b.disabled = show_disabled
		node = b
	elif ClassDB.is_parent_class(native, "Label"):
		node = _label(style, &"")
	elif ClassDB.is_parent_class(native, "Range"):
		var bar := ProgressBar.new()
		bar.value = 65
		bar.custom_minimum_size.x = 200
		node = bar
	elif ClassDB.is_parent_class(native, "Container") and native != "PanelContainer":
		node = ClassDB.instantiate(native)
		for i in 3:
			node.add_child(_label(style if i == 0 else "·", &"Caption"))
	else:
		var panel := PanelContainer.new()
		panel.add_child(_label(style, &"Body"))
		node = panel
	node.theme_type_variation = StringName(style)
	node.tooltip_text = "%s (on %s)" % [style, native]
	return node


# ------------------------------------------------------------------ helpers

func _section(title: String, note: String) -> VBoxContainer:
	var s := _stack(&"StackMd")
	s.add_child(_label(title.to_upper(), &"Overline"))
	if note != "":
		# must wrap. one long note widens the page and the scroll container
		# shoves the whole gallery off the left edge
		var n := _label(note, &"Muted")
		n.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		n.custom_minimum_size.x = 1
		s.add_child(n)
	_content.add_child(s)
	var body := _stack(&"StackMd")
	s.add_child(body)
	return body


func _stack(style: StringName) -> VBoxContainer:
	var v := VBoxContainer.new()
	v.theme_type_variation = style
	return v


func _row(style: StringName) -> HBoxContainer:
	var h := HBoxContainer.new()
	h.theme_type_variation = style
	return h


func _label(text: String, style: StringName) -> Label:
	var l := Label.new()
	l.text = text
	if style != &"":
		l.theme_type_variation = style
	return l


## demo art: stripes for TILE, gradient for REVEAL, colours from the tokens
func _stripes() -> Texture2D:
	var img := Image.create(12, 12, false, Image.FORMAT_RGBA8)
	var a := tokens.tone("accent", 400)
	var b := tokens.tone("accent", 600)
	for y in 12:
		for x in 12:
			img.set_pixel(x, y, a if (x + y) % 12 < 6 else b)
	return ImageTexture.create_from_image(img)


func _gradient() -> Texture2D:
	var g := Gradient.new()
	g.set_color(0, tokens.tone("success", 500))
	g.set_color(1, tokens.tone("danger", 500))
	g.add_point(0.5, tokens.tone("warning", 500))
	var tex := GradientTexture2D.new()
	tex.gradient = g
	tex.width = 256
	tex.height = 8
	return tex


func _token_files() -> PackedStringArray:
	var out := PackedStringArray()
	for file in DirAccess.get_files_at(TOKEN_DIR):
		if file.ends_with(".tres"):
			out.append(TOKEN_DIR + file)
	var project: String = ProjectSettings.get_setting("woldui/tokens", "")
	if project != "" and not out.has(project):
		out.append(project)
	return out


func _on_input_mode(mode: int) -> void:
	if is_instance_valid(_mode_label):
		_mode_label.text = "Input: %s" % WoldUIRuntime.InputMode.keys()[mode].capitalize()
