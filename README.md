# WoldUI for Godot

A design system for Godot 4.7 games, driven by one tokens file. You pick a handful of colours, fonts and sizes, and every Control in the game restyles from them. Motion, sound and icons come with the components, and anything you can tweak, you can tweak in the editor.

It's the Godot port of my web UI kit of the same name. Current version: 0.8.1.

## Install

You need Godot 4.7 or later. The addon has to end up at `addons/woldui/`.

Easiest is to grab a release zip (`woldui-<version>.zip`) and unzip it into your project folder; it already contains the `addons/woldui/` path. If you'd rather be able to pull updates, add it as a submodule:

```bash
git submodule add <repo-url> addons/woldui
```

Then:

1. Enable WoldUI in Project -> Project Settings -> Plugins. A WoldUI dock shows up.
2. Copy `addons/woldui/tokens/default_dark.tres` (or `default_light.tres`) somewhere in your game, say `ui/theme/my_tokens.tres`.
3. In the dock, click "Change..." and pick that file, then "Use as project theme".

That's it. Every Control in the game now uses the generated theme. Hit "Edit tokens" to tweak them in the Inspector; the theme rebuilds on every change and open scenes repaint.

## Tokens and styles

`WoldTokens` holds the primitives: a seed colour for each tone (neutral, accent, success, warning, danger), fonts, a type scale, spacing, radii, borders, shadows, motion timings, icon sizes and sounds. Each seed becomes a 50-950 ramp, and step 500 is exactly the colour you picked.

From the ramps come semantic roles like `role("text")`, `role("surface_raised")` or `role("accent_text")`, worked out for dark or light mode. If one role comes out wrong for your game, replace just that one in `role_overrides`. The dock shows each role's contrast so you can see what you're doing.

The part you actually touch day to day is the named styles. You put them in a node's Theme Type Variation:

- Buttons: `ButtonPrimary`, `ButtonSecondary`, `ButtonOutline`, `ButtonGhost`, `ButtonDanger`, `ButtonIcon`, each also in `Sm` and `Lg`
- Text: `Display`, `Title`, `Heading`, `Subheading`, `Body`, `Caption`, `Overline`, `Muted`, `TextAccent`, `TextSuccess`, `TextWarning`, `TextDanger`, `TextOutlined`
- Panels: `PanelBase`, `PanelRaised`, `PanelOverlay`, `PanelHud`, `PanelSunken`, `PanelCallout`, `PanelScrim`, `PanelBare`
- Fields and meters: `FieldSm`, `FieldLg`, `MeterAccent`, `MeterSuccess`, `MeterWarning`, `MeterDanger`, `MeterThin`
- Spacing: `Stack*` for VBoxes, `Row*` for HBoxes, `Inset*` for MarginContainers, plus `Grid*` and `Flow*`, all in `Xs`, `Sm`, `Md`, `Lg`, `Xl`, `Xxl`

Plain engine controls (Button, LineEdit, TabContainer, PopupMenu, scrollbars, tooltips and so on) get styled too, so you get something even if you never touch a component.

## Components

Every component is its own scene under `components/`, runs as `@tool` so you see it live in the editor, and takes its whole look from the tokens. Most have a `_wold_...` hook you can override from an inherited scene, so you can extend them without editing the addon.

### WoldButton

```gdscript
var b: WoldButton = preload("res://addons/woldui/components/wold_button/wold_button.tscn").instantiate()
b.text = "Continue"
b.shape = WoldButton.Shape.PRIMARY      # PRIMARY, SECONDARY, OUTLINE, GHOST, DANGER, ICON
b.button_size = WoldButton.Size.LG      # SM, MD, LG
b.icon_start = "swords"                 # any icon name, or icon_start_texture
b.icon_end = "arrow-right"
b.sound = "confirm"                     # what WoldFeedback plays
```

It's still a real Button underneath, so toggles, button groups, shortcuts, focus and all the signals work like you'd expect, and `text` is still the text. Icons follow the size step and recolour with the button state. Set `variant = "ButtonGold"` to use one of your own styles instead of shape + size.

Saved scenes only hold the props. Icons and styling are rebuilt on load, so you don't end up with embedded textures or stale overrides in your .tscn files.

To make your own button, make an inherited scene of `wold_button.tscn`, give it a script that `extends WoldButton`, and do your extra stuff in `_wold_refresh()`, which runs at the start of every restyle. `gallery/examples/confirm_button.tscn` adds a `busy` prop that way in about ten lines.

### WoldStat

An icon, a number and a label. Think resources in a top bar, health, score.

```gdscript
var gold: WoldStat = preload("res://addons/woldui/components/wold_stat/wold_stat.tscn").instantiate()
gold.icon = "coins"
gold.value = 610
gold.compact = true            # 1.2k, 3.4M
gold.delta = 20                # shown as "+20" when show_delta is on
gold.show_delta = true
gold.surface = WoldStat.Surface.BARE
# later: gold.value = 830     -> counts up and flashes
```

`layout` is INLINE or STACKED (label above the value), `max_value` gives you "12 / 20", and `tone`, `surface` and `stat_size` cover the look. When the value changes it counts up or down and flashes; with `animate` off or reduced motion on it just jumps. `value_changed(old, new)` fires either way.

There's an `%Extra` slot for your own nodes, and you can override `_wold_format(v)` for your own number format. `gallery/examples/health_stat.tscn` puts a WoldMeter in the slot.

### WoldBadge

A small pill for a status, a count or just a dot.

```gdscript
badge.text = "Allied"; badge.icon = "shield"; badge.tone = WoldBadge.Tone.SUCCESS
badge.count = 3               # a number instead of text; 120 -> "99+", 0 hides it
badge.dot = true              # just a coloured dot
badge.pin = WoldBadge.Pin.TOP_RIGHT   # sit on the parent's corner (a count on a button)
badge.pulse = true            # breathe (a turn indicator)
```

Mix `tone` (neutral, accent, success, warning, danger), `fill` (soft, solid, outline) and `badge_size` (sm, md) however you like. The tests check every combination for 4.5:1 text contrast with both the dark and light tokens. A rising count bumps the badge. A text badge never un-hides itself if your game hid it; only a count shows or hides on its own.

### WoldDialog

A modal with a scrim, icon, title, message, your content and confirm/cancel buttons.

```gdscript
# One line, from anywhere:
var answer := await WoldDialog.ask(self, "Leave the match?", "Your army stays.", "Leave", "Stay", true)
if answer == "confirm": ...

# Or place wold_dialog.tscn in a scene, set its props, and call open().
dialog.open()
var result = await dialog.closed      # "confirm", "cancel", or close("anything")
```

Focus starts on confirm, can't wander off to the screen behind, and goes back where it was when the dialog closes. The focus ring only shows for keyboard and pad. If `closable` is on, `ui_cancel` (Esc, or B on a pad) and clicking the scrim both cancel. Setting `confirm_text` or `cancel_text` to empty hides that button, and `destructive` makes confirm a danger button.

Signals are `opened`, `confirmed`, `cancelled` and `closed(result)`. Put your own nodes in `%Content`, extra buttons in `%Actions`, and use `_wold_on_open()` / `_wold_on_close(result)` if you need to. `gallery/examples/quit_dialog.tscn` adds a "Don't ask again" box.

`dialog_size = SM` is the quick yes / no: narrower, centred text, no X, and the two buttons share the width. Dialogs stack: when one opens over another (a confirm from inside a sheet), only the top one keeps focus and answers Esc.

### WoldSheet

A WoldDialog that slides in from an edge instead of popping up in the middle: an inventory, a city screen, a drawer of options.

```gdscript
var sheet: WoldSheet = preload("res://addons/woldui/components/wold_sheet/wold_sheet.tscn").instantiate()
sheet.edge = WoldSheet.Edge.RIGHT
sheet.extent = 380            # width for a side sheet, height for top / bottom
sheet.title = "Rivermouth"
sheet.get_node("%Content").add_child(buildings)
layer.add_child(sheet)
sheet.open()
```

Everything else is the dialog's: `%Content` and `%Actions`, the focus trap, Esc and scrim clicks, `closed(result)`. The edge it comes in from stays square and the open side rounds off. See `gallery/examples/city_sheet.tscn`.

### WoldToast and WoldToaster

Short notifications that stack in a corner and go away on their own.

```gdscript
WoldToast.notify(self, "Game saved", WoldToast.Tone.SUCCESS)
var t := WoldToast.notify(self, "The Ants offer 20 wood.", WoldToast.Tone.ACCENT, "Trade offer", 0)  # 0 = stays
t.action_text = "View offer"
t.action_pressed.connect(open_trade)
```

Each tone has its own icon, and a thin bar shows the time left. Hovering pauses it. `WoldToaster` holds the stack: `place` picks the corner (top or bottom, left, right or centre), `max_visible` caps it, and when a toast leaves the others slide into its space instead of jumping. `notify()` creates a toaster on a top layer the first time; place `wold_toaster.tscn` yourself if you want to pick the layer.

### WoldTooltip

A richer tooltip. Drop `wold_tooltip.tscn` under any Control and fill in `title`, `icon`, a BBCode `body`, `rows` (label/value pairs like Attack 6, Range 2) and a `hint` line in the Inspector.

The main reason it exists: engine tooltips are mouse-only, and this one also shows when a keyboard or pad player focuses the control (`show_on_focus`). It waits `tooltip_delay` from the tokens so brushing past doesn't trigger it, sits next to the control rather than under the cursor (`placement`), flips when there's no room, and never eats mouse input. Only one shows at a time. Override `_wold_fill(panel)` to add your own nodes.

### WoldListRow

A row for save slots, lobbies, codex entries, settings.

```gdscript
row.title = "Autosave"
row.subtitle = "Turn 42"
row.icon_name = "save"
row.trailing_icon = "chevron-right"
```

There's also `trailing_text`, and `%Leading` / `%Trailing` slots (a WoldBadge fits nicely). It's a Button, so focus, pad activation, disabled and WoldFeedback all work. Give a set of rows one `ButtonGroup` and they select one at a time; the selected one gets an accent tint and an accent bar on its leading edge.

### WoldSwitch

An on/off switch whose knob slides.

```gdscript
sw.label = "Show hex grid"
sw.description = "Outlines every tile on the map."
sw.toggled.connect(func(on): settings.hex_grid = on)
```

It's a toggle Button, so `button_pressed` is the state and `toggled` the signal. Disabled dims the label and description too. Plain CheckBox and CheckButton controls get matching drawn icons from the theme, so they fit in even if you don't use the component. `gallery/examples/motion_switch.tscn` binds one to the Reduce motion preference.

### WoldCheckbox and WoldRadioGroup

```gdscript
box.label = "Show damage numbers"
box.indeterminate = true          # the dash, for "some of these"

radios.options = PackedStringArray(["Small", "Medium", "Large"])
radios.selected = 1
radios.selected_changed.connect(func(i): settings.map_size = i)
```

WoldCheckbox has the same `label` / `description` as the switch. Put a few in one `ButtonGroup` and they draw as radios. WoldRadioGroup builds those radios from `options` (and optional `descriptions`), lays them out in a column or a row (`horizontal`), and moves the pick with the arrow keys or d-pad; at either end focus moves on out of the group, so pad players don't get stuck in it. See `gallery/examples/check_all.tscn` and `game_speed.tscn`.

### WoldSegmented

Joined toggle buttons, for view modes and filters where radios would take too much room.

```gdscript
seg.options = PackedStringArray(["Map", "Cities", "Units"])
seg.icons = PackedStringArray(["map", "castle", "swords"])
seg.selected_changed.connect(func(i): show_view(i))
```

With one pick, a raised thumb slides to the chosen segment. Set `multiple` and any number can be on instead (`pressed_items()`, `item_toggled`). `segment_size` is SM or MD, and `stretch` shares the width equally. An option with an icon and no text gets the icon name as its tooltip; set a better one through `item(i)`. See `gallery/examples/map_layers.tscn`.

### WoldToggle

A WoldButton that stays on, for tool palettes and view options: no fill when off, an accent tint and accent text when on.

```gdscript
grid.text = "Grid"
grid.icon_start = "grid-3x3"
grid.toggled.connect(func(on): map.show_grid = on)
```

`outline` adds an edge, `button_size` is SM, MD or LG, and `shape = ICON` makes it square for an icon-only toggle (give it a tooltip). The other shapes don't apply. See `gallery/examples/fast_forward.tscn`.

### WoldSelect

A field that drops down a list of options.

```gdscript
sel.options = PackedStringArray(["Small", "Medium", "Large"])
sel.placeholder = "Map size"
sel.item_selected.connect(func(i): settings.map_size = i)
```

`selected = -1` shows the placeholder. `icons` puts an icon next to each option (and in the field once picked), `select_size` is SM, MD or LG, and `min_width` stops it being narrower than you want. It sizes itself to the longest option, so picking one never resizes it. Accept opens the list on keyboard or pad, the list takes up / down / accept / cancel, and focus comes back to the field when it closes. It isn't an OptionButton: that one saves its generated items into your scene. Plain PopupMenus also get drawn check boxes, radio dots and a submenu arrow from the theme. See `gallery/examples/faction_select.tscn`.

### WoldMenu

A PopupMenu you fill in code, one callback per item, for dropdowns and context menus.

```gdscript
var m := WoldMenu.new()
m.item("Rename", rename, "pencil", "F2")          # label, callback, icon, shortcut
m.check("Auto-explore", true, func(on): auto = on)
m.radio("Line", &"formation", true, set_line)
var send := m.submenu("Send to", "send")
send.item("Rivermouth", send_to.bind("rivermouth"))
m.separator()
m.danger("Disband", disband, "trash", "Delete")
add_child(m)
m.open_at(button)        # or m.open_at_mouse() for a context menu
```

Keyboard, pad, submenus and type-to-search are PopupMenu's own. Shortcuts are shown on the right (and work while the menu is open). Icons take the text colour, danger items get a red icon, and focus goes back to whatever had it when the menu closes. `open_at` takes a side and an alignment; `anchor_position()` tells you where it will ask to go. Plain PopupMenus and MenuBars pick up the same look from the theme. Menus fade in like the other popups; `WoldMotion.popup_in(popup)` does the same for any popup window of your own. See `gallery/examples/unit_menu.tscn`.

### WoldPopover

A panel that floats next to the Control it's a child of: a unit's details, a rename form, a filter.

```gdscript
var pop: WoldPopover = preload("res://addons/woldui/components/wold_popover/wold_popover.tscn").instantiate()
pop.title = "Rename army"
pop.get_node("%Content").add_child(name_edit)
rename_button.add_child(pop)     # the button now opens it
```

`trigger` is CLICK (the anchor's press or a click toggles it), HOVER (a hover card, which keyboard and pad focus on the anchor open too) or MANUAL (`open()` / `close()`). `placement` and `align` say where it goes; it flips if there's no room and stays on screen. Esc, a click outside or focus moving elsewhere closes it, and focus goes back to the anchor. Opened from the keyboard or pad, focus lands inside. While open it lives on its own CanvasLayer (above dialogs) and borrows the theme it sat under, so a WoldScope still applies. Use `content()` to reach `%Content` while it's open. See `gallery/examples/city_card.tscn`.

### WoldStepper

The console-style `< Normal >` setting, for settings screens you drive with a pad.

```gdscript
step.label = "Difficulty"
step.options = PackedStringArray(["Easy", "Normal", "Hard"])
step.value_changed.connect(func(v): settings.difficulty = int(v))
```

The whole row takes focus, so up and down still move between rows while left and right (keys, d-pad or the little arrows) step the value. Accept steps forward and goes round at the end; a click or tap steps towards whichever side of the value it lands on, so the whole row is a target. With no `options` it steps numbers from `min_value` to `max_value` by `step`, shown with `format` (`"%d%%"`). `wrap` makes both ends go round. The value box is as wide as its widest step, so the arrows stay put. See `gallery/examples/ui_volume.tscn`.

### WoldField

The wrapper for a form row: label, control, a hint under it and an error line.

```gdscript
var name_edit := LineEdit.new()
var field := WoldField.make(name_edit, "Kingdom name", "Shown to other players.")
field.max_length = 24                 # adds a "10 / 24" counter and caps the LineEdit
field.error = "That name is taken."   # shows the line, gives the LineEdit a danger border
```

Any control goes in the `%Control` slot (in the editor: Editable Children, or an inherited scene). A click on the label focuses the control, and the label and hint become the control's accessibility name and description. LineEdit and TextEdit (and the Sm / Lg field styles) have an `...Invalid` style that the error switches on; other controls keep their look and just get the message. See `gallery/examples/name_field.tscn`, which checks itself as you type.

### WoldButtonStrip

Put buttons under it and they join into one strip: only the outer corners stay round and the borders overlap into single seams. `vertical` stacks them.

```gdscript
var strip: WoldButtonStrip = preload("res://addons/woldui/components/wold_button_strip/wold_button_strip.tscn").instantiate()
strip.add_child(undo_button)
strip.add_child(redo_button)
```

Any Button works, WoldButtons included, and it keeps up when a button changes shape, hides, or the tokens change. It's only looks: for pick-one behaviour give the buttons a `ButtonGroup` as usual. The joins are stylebox overrides on your buttons, taken off right before the editor saves so they never end up in your scene. See `gallery/examples/map_zoom.tscn`.

### WoldCard

A surface with a header (icon, title, description and an `%Action` slot), a `%Content` slot and a `%Footer` slot. Parts you leave empty take no room, and the padding stays even whichever ones are there.

```gdscript
card.title = "Great Library"
card.description = "Wonder. +3 research in every city."
card.icon = "library"
card.get_node("%Footer").add_child(build_button)
```

`card_size` is SM or MD. Set `selectable` and it becomes a choice: it takes focus, lights up on hover, and a click or accept emits `pressed`. Cards that share a `card_group` select one at a time, which is most of an upgrade picker. See `gallery/examples/upgrade_card.tscn`.

### WoldCollapsible and WoldAccordion

```gdscript
var more: WoldCollapsible = preload("res://addons/woldui/components/wold_collapsible/wold_collapsible.tscn").instantiate()
more.title = "How does trade work?"
more.get_node("%Content").add_child(help_text)
more.toggled.connect(func(open): print(open))
```

A collapsible is a trigger row that opens to show its `%Content`. The height slides open (reduced motion just opens it), and closed content is properly hidden so Tab and the d-pad can't land inside it. It keeps up when the content changes size while open.

A WoldAccordion is collapsibles as children: they turn into flush rows with a line between them, and only one is open at a time unless `multiple`. Turn `collapsible` off to keep one section always open. `item_toggled(index, open)` reports changes. See `gallery/examples/unit_details.tscn` and `codex_accordion.tscn`.

### WoldAvatar and WoldAvatarGroup

```gdscript
avatar.texture = preload("res://art/portraits/mab.png")   # or leave it empty for initials
avatar.display_name = "Queen Mab"                          # "QM", and the tooltip
avatar.status = WoldAvatar.Status.ONLINE
```

The picture is cropped to a circle or a rounded square (`shape`) and covers the frame. With no picture it shows the initials, on `color` if you give it one (a faction colour, say) with the text colour picked to read on it. `status` puts a presence dot on the rim: online, away, busy or offline. For a count, add a WoldBadge as a child with `pin = TOP_RIGHT`. `initials` overrides the letters.

WoldAvatarGroup builds overlapping avatars from `names` (and optional `textures`), each with a ring in the surface colour, and folds anything past `max_visible` into a "+N" whose tooltip lists who's in it. See `gallery/examples/faction_leader.tscn` and `lobby_players.tscn`.

### WoldAlert

A banner that sits in the layout, for things that should stay put until dealt with (a toast goes away on its own).

```gdscript
alert.tone = WoldAlert.Tone.WARNING
alert.title = "Low food"
alert.description = "Your population stops growing next turn."
alert.dismissible = true
```

The tone picks the fill, the edge and a default icon, the same icons WoldToast uses; `icon` overrides it. Buttons go in `%Action`. `close()` fades it out and emits `closed`; `free_on_close` frees it afterwards. See `gallery/examples/treaty_alert.tscn`.

### WoldEmpty, WoldSkeleton, WoldSpinner, WoldSeparator

The quiet ones.

- **WoldEmpty** is what a list or inventory shows with nothing in it: an `icon` in a soft circle, a `title`, a `description`, and buttons in `%Actions`, all centred. See `gallery/examples/no_saves.tscn`.
- **WoldSkeleton** stands in for something still loading. Size it like the real thing, or set `lines` for a block of text (the last line comes out shorter). `shape = ROUND` is for portraits. It breathes while `active`. See `text_skeleton.tscn`.
- **WoldSpinner** is a turning loader icon (`icon`, `spinner_size`). It only turns while visible, and the icon turns inside its drawing, not the node, so it's fine in containers. See `saving_spinner.tscn`.
- **WoldSeparator** is a line that can carry a label ("or", "Turn 12"), in the middle or near the start (`place`), and can be `vertical`. See `turn_divider.tscn`.

Under Reduce motion the skeleton and spinner hold still.

### WoldCarousel and WoldPageDots

```gdscript
# pages are the carousel's children, like WoldTabs
carousel.add_child(page_one)
carousel.add_child(page_two)
carousel.page_changed.connect(func(i): print("page ", i))
```

One page at a time with arrows and page dots under it. The new page slides in from the side you went, `wrap` goes round at the ends, and LB / RB flip pages while focus is somewhere inside the carousel (so two on one screen don't fight). With a single page the controls hide.

WoldPageDots is the dots on their own: `count`, `current`, and `page_selected` when one is clicked. The current dot stretches into a pill that slides along. See `gallery/examples/how_to_play.tscn` and `step_dots.tscn`.

### WoldBubble, WoldMessage, WoldMessageLog

Speech and chat, for multiplayer lobbies, diplomacy screens and NPCs talking.

```gdscript
log.say("The Ants", "20 wood for 10 gold?")
log.say("You", "Deal.", true)          # your own lines sit on the right
log.add(any_control)                   # a turn marker, a notice, a card
```

- **WoldBubble** is the speech bubble: `text`, a `look` (default accent, secondary, muted, tinted, outline, ghost, danger), and a `tail` that squares off the corner towards the speaker. It shrinks to short lines and wraps at `max_width`. `%Content` takes buttons inside it, `%Reactions` badges under it. See `gallery/examples/npc_bark.tscn`.
- **WoldMessage** is one chat line: avatar, `author`, `time`, and a bubble. `mine` flips it to the right. `show_header = false` makes a follow-up line that keeps the avatar's gap. See `trade_offer.tscn`, which puts Accept / Decline in the bubble.
- **WoldMessageLog** holds them. New lines slide in, and it follows them while you're at the bottom. Scroll up and it stays put, showing an "N new" button that takes you back down. Lines from the same speaker in a row share a header, and past `max_items` the oldest drop off. See `diplomacy_log.tscn`.

### WoldKbd

Key caps for a shortcut written as text: `keys = "Ctrl+Shift+S"`. It uses the same drawn caps as WoldButtonPrompt. Use WoldButtonPrompt when you want an InputMap action that follows the player's device, and WoldKbd for fixed text in help screens and menus. See `gallery/examples/save_shortcut.tscn`.

### WoldTabs

Tabs with an underline that slides to the current one.

```gdscript
tabs.current = 1
tabs.tab_changed.connect(func(i): print("tab ", i))
```

Add your pages as children of the WoldTabs node, like a TabContainer; each page's name is its tab label. Page metadata `wold_title`, `wold_icon` and `wold_badge` change the label, add an icon or add a count. With no pages and `tabs` set, it's just a tab bar. `stretch` spreads the tabs over the width, and LB/RB switch tabs on a pad with no InputMap setup (`pad_shoulders`). See `gallery/examples/tabs_example.tscn`.

### WoldButtonPrompt

The "[A] Confirm" thing, using the player's actual bindings.

```gdscript
prompt.action = &"end_turn"
prompt.label = "End turn"
```

It follows whatever the player is using right now (keyboard, pad or mouse) unless you pin it with `input_kind`. Pads are detected as Xbox, PlayStation or Nintendo from their name, or set `pad_family`. Glyphs are drawn from the tokens, so there's no bundled art; to use your own, add textures to your icon set under the glyph name (`prompt_xbox_a`, `prompt_ps_cross`, `prompt_key_e`, `prompt_mouse_left`). Call `refresh()` after the player rebinds. `WoldPrompts.glyph_for(event, family)` is the plain mapping if you need it elsewhere.

### WoldMeter and WoldSlider

`WoldMeter` is a ProgressBar, `WoldSlider` an HSlider and `WoldVSlider` a VSlider. Both take a `WoldFill`, which is a texture plus a mode:

- `TILE` repeats the artwork at a fixed scale (`tile_scale`), so the value never squashes it. Good for stripes and pips.
- `REVEAL` spreads one image across the whole track and the value uncovers it.
- `STRETCH` squeezes it into the filled part, which is what the engine normally does.

```gdscript
var f := WoldFill.new()
f.texture = preload("res://ui/art/stripes.png")
f.mode = WoldFill.Mode.TILE
meter.fill = f
```

The fill is clipped to the track's rounded shape and drawn under the grabber and the percentage text. `WoldSlider.track_height` makes the rail thicker if your texture needs the room. `WoldVSlider` is the upright one (a volume fader, say): same props, with `track_width` for the rail, and the fill grows from the bottom up. See `gallery/examples/ui_fader.tscn`.

### WoldScope

Token overrides for one subtree, a bit like CSS variables on a wrapper.

```gdscript
scope.accent = Color("c0392b")                    # this faction's panel goes red
scope.token_overrides = {"radius_md": 0, "base_font_size": 15}
```

Everything inside follows the overrides, components included, and nothing outside changes. Scopes nest and stack: an inner one starts from the outer one's overrides and adds its own (nearest wins), rebuild when their props change or when the game swaps tokens with `WoldUI.apply_tokens`, and never save their generated theme into the scene.

### WoldScreen

A base for full screens: menus, settings, overlays.

```gdscript
WoldScreen.push(self, "res://ui/settings_screen.tscn")   # enters with a transition
WoldScreen.pop(self)                                      # the top screen leaves
```

Screens come in and out with `enter_preset` / `exit_preset` and the open/close sounds. `first_focus` gets focus on enter so pad players can go straight away, and focus returns to whatever opened the screen when it closes. `ui_cancel` goes back on the top screen only; set `auto_back = false` if you just want the `back_requested` signal. `backdrop` is BASE, SCRIM or NONE. `gallery/examples/settings_screen.tscn` is a full example.

## Motion and feedback

All UI animation goes through `WoldMotion`:

```gdscript
WoldMotion.appear(panel)                                  # "appear" preset
WoldMotion.appear(panel, WoldMotion.preset("dialog_in"))
WoldMotion.disappear(toast, null, true)                   # then free it
WoldMotion.stagger(list.get_children())
WoldMotion.count_to(gold_label, 120, 240, "%d gold")
WoldMotion.pulse(waiting_label)
WoldMotion.shake(button)
WoldTransition.swap(old_screen, new_screen)
```

For a timed sequence of your own (a turn banner, a toast that holds), build one with `sequence()`: its fades are instant under Reduce motion, but holds still hold, since they're reading time.

```gdscript
var tw := WoldMotion.sequence(banner)       # a new one on the node kills the old
WoldMotion.fade(tw, banner, 1.0, 0.35)
tw.tween_interval(0.9)
WoldMotion.fade(tw, banner, 0.0, 0.35)
tw.tween_callback(banner.hide)
```

`WoldMotion.slide(card, Vector2(-40, 0))` eases something the layout just moved in from where it was.

The important bit is that it only animates `modulate.a` and a Control's offset transform, which is visual only. Containers don't reset it, so a node can animate inside a VBoxContainer without its neighbours jumping, and clicks still land where the node really is. Starting a new motion on a node replaces the running one. With reduced motion on, everything goes straight to its end state, but the tween still finishes so `await` works the same.

Presets are `.tres` files in `motion/presets/` (appear, disappear, dialog_in, toast_in, screen_enter and a few more). Each one picks a duration step, an easing from the tokens and a starting alpha/offset/scale. To change one for the whole game, put your own under the same name in the tokens' `motion_presets`.

For buttons, drop a `WoldFeedback` node into a scene. Every button under its parent then gets a hover/focus lift, a press dip, sounds, and a shake plus error sound when someone clicks it while it's disabled. Buttons added later are picked up too. Per button you can set metadata `wold_sound` (`confirm`, `back`, `open`, `close` or `none`) or `wold_feedback = false`.

There are eight sound slots (hover, click, confirm, back, error, open, close, focus), set through a `WoldSoundSet` on the tokens. Empty slots fall back to built-in synthesised sounds while `use_builtin_sounds` is on: soft mallet notes (confirm goes up, back comes down), a wooden tick for clicks, a low double knock for errors and quiet whooshes for open and close. They're made on first use, so there are no audio files, and `WoldSounds.mallet()`, `tick()`, `knock()`, `whoosh()` and `mix()` are there if you want to make your own the same way.

Enabling the plugin adds a `WoldUI` autoload. It holds the player preferences (`reduced_motion`, `sound_enabled`, `sound_volume_db`) and tracks the input device in `input_mode` (MOUSE, KEYBOARD, PAD or TOUCH), with `input_mode_changed` when it switches. Focus sounds only play on keyboard and pad.

On touch (`WoldUI.is_touch()`) the components behave for fingers: buttons don't lift or play a hover sound on a tap, tooltips show on a long-press and hide on the next touch, hover cards open on a tap, page dots take a fingertip-sized tap, and a stepper steps towards whichever side of its value you tap. Button prompts hide when `hide_on_mouse` is on, as they do for the mouse. If you don't have the autoload, `WoldUIRuntime.instance()` makes one when first needed.

The dock's "Motion & sound" tab plays every preset and sound right in the editor.

## Icons

All 1,848 [Lucide](https://lucide.dev) icons (v1.47.0) are bundled. They're rendered from SVG at whatever size you ask for, and drawn white so the control's colours tint them.

```gdscript
button.icon = tokens.icon("swords")        # token size (md), token stroke
button.icon = tokens.icon("coins", "Lg")   # a size step
WoldIcons.texture("coins", 32, 1.5)        # explicit px and stroke
```

Browse them in the dock's Icons tab or in the gallery; clicking one copies its name. `icon_stroke` in the tokens sets the line weight for the whole game. An unknown name is an error, not a blank icon.

To add your own, make a `WoldIconSet`, add name -> texture entries, and set it as the tokens' `icon_set`. New names get added to the library, and a name that matches a Lucide icon replaces it. Import SVGs as DPITexture so they stay sharp. White artwork tints like the built-in ones; for full-colour art set `icon_tint` to `ORIGINAL`.

To update Lucide: `node tools/build_lucide.mjs <path to node_modules/lucide-react>`.

Lucide is ISC licensed; the licence is in `icons/LICENSE-lucide.txt`.

## Extending it

You shouldn't need to fork the addon for one game. Roughly in order of effort:

- A different look: change the tokens.
- A new variant, like a gold button: in the dock, "New variant..." creates a `WoldVariant`. Set `base` to `ButtonPrimary` and put `accent` = gold in `token_overrides`. You get the base style redrawn with those tokens, plus any single items you override. No code.
- A textured frame for one style: add it to the tokens' `texture_overrides`, e.g. `"PanelOverlay/panel"` -> your `StyleBoxTexture`.
- A style for something only your game has, like a resource bar: write a script with `static func contribute(theme: Theme, t: WoldTokens)` and list it in the tokens' `extra_recipes`. Build from `t.role()`, the `t.space_*` values and `WoldStyle`, and it restyles along with everything else.
- Different tokens for one part of the UI: wrap it in a `WoldScope`.

The gallery shows your own styles under "Game styles" without you doing anything.

## Development

```bash
powershell -ExecutionPolicy Bypass -File tools/run_tests.ps1
powershell -ExecutionPolicy Bypass -File tools/run_tests.ps1 -Only test_theme
```

Set `GODOT_EXE` or have `godot` on your PATH. The tests run in a dev project at `%LOCALAPPDATA%\woldui-godot-dev`, whose `addons/woldui` is a junction to this repo, so nothing gets copied. `tools/dev_project.ps1 -Open` opens that project in the editor with the gallery as the main scene.

To rebuild a game's theme without the editor (CI, or when the editor is closed):

```bash
godot --headless --path <game> -s res://addons/woldui/tools/build_theme.gd
```

## Releasing

Bump `version` in `plugin.cfg` and commit, then run:

```bash
powershell -ExecutionPolicy Bypass -File tools/package_release.ps1
```

That packs HEAD into `dist/woldui-<version>.zip` with everything under `addons/woldui/`. Tests and dev scripts are left out through `export-ignore` in `.gitattributes`, and so is anything you haven't committed. Upload the zip or attach it to a GitHub release, and tag the commit `v<version>`.

The rules I try to stick to are in [docs/guidelines.md](docs/guidelines.md).

## License

MIT.
