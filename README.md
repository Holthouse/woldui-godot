# WoldUI for Godot

A design system for Godot 4.7 games, driven by one tokens file. You pick a handful of colours, fonts and sizes, and every Control in the game restyles from them. Motion, sound and icons come with the components, and anything you can tweak, you can tweak in the editor.

It's the Godot port of my web UI kit of the same name. Current version: 0.3.1.

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

`WoldMeter` is a ProgressBar and `WoldSlider` an HSlider. Both take a `WoldFill`, which is a texture plus a mode:

- `TILE` repeats the artwork at a fixed scale (`tile_scale`), so the value never squashes it. Good for stripes and pips.
- `REVEAL` spreads one image across the whole track and the value uncovers it.
- `STRETCH` squeezes it into the filled part, which is what the engine normally does.

```gdscript
var f := WoldFill.new()
f.texture = preload("res://ui/art/stripes.png")
f.mode = WoldFill.Mode.TILE
meter.fill = f
```

The fill is clipped to the track's rounded shape and drawn under the grabber and the percentage text. `WoldSlider.track_height` makes the rail thicker if your texture needs the room.

### WoldScope

Token overrides for one subtree, a bit like CSS variables on a wrapper.

```gdscript
scope.accent = Color("c0392b")                    # this faction's panel goes red
scope.token_overrides = {"radius_md": 0, "base_font_size": 15}
```

Everything inside follows the overrides, components included, and nothing outside changes. Scopes nest (nearest wins), rebuild when their props change or when the game swaps tokens with `WoldUI.apply_tokens`, and never save their generated theme into the scene.

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

The important bit is that it only animates `modulate.a` and a Control's offset transform, which is visual only. Containers don't reset it, so a node can animate inside a VBoxContainer without its neighbours jumping, and clicks still land where the node really is. Starting a new motion on a node replaces the running one. With reduced motion on, everything goes straight to its end state, but the tween still finishes so `await` works the same.

Presets are `.tres` files in `motion/presets/` (appear, disappear, dialog_in, toast_in, screen_enter and a few more). Each one picks a duration step, an easing from the tokens and a starting alpha/offset/scale. To change one for the whole game, put your own under the same name in the tokens' `motion_presets`.

For buttons, drop a `WoldFeedback` node into a scene. Every button under its parent then gets a hover/focus lift, a press dip, sounds, and a shake plus error sound when someone clicks it while it's disabled. Buttons added later are picked up too. Per button you can set metadata `wold_sound` (`confirm`, `back`, `open`, `close` or `none`) or `wold_feedback = false`.

There are eight sound slots (hover, click, confirm, back, error, open, close, focus), set through a `WoldSoundSet` on the tokens. Empty slots fall back to built-in synthesised sounds while `use_builtin_sounds` is on, so a prototype isn't silent.

Enabling the plugin adds a `WoldUI` autoload. It holds the player preferences (`reduced_motion`, `sound_enabled`, `sound_volume_db`) and tracks the input device in `input_mode` (MOUSE, KEYBOARD or PAD), with `input_mode_changed` when it switches. Focus sounds only play on keyboard and pad. If you don't have the autoload, `WoldUIRuntime.instance()` makes one when first needed.

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

## Known gaps

- `WoldSlider` is horizontal only.
- The built-in sounds are placeholders.
- Nothing touch-specific yet.
- Nested `WoldScope`s don't stack: an inner scope starts from the global tokens, not the outer scope's overrides.

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
