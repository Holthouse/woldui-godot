# Guidelines

The rules I keep in WoldUI, and try to keep in the games that use it.

## Style comes from the tokens

No colour, size, radius, spacing or duration gets typed into a scene or feature script. A Control picks a named style (Theme Type Variation) and the style comes from the tokens. That includes spacing: a VBoxContainer gets `StackMd`, not a `separation` override.

The generated `*_theme.tres` is build output. Don't hand-edit it, the next rebuild overwrites it.

Name styles by role, not by value: `Heading`, not `Text28`; `ButtonDanger`, not `ButtonRed`. Then the value can change in one token.

## Colour

- Pick one seed per tone, not individual steps. Step 500 is the seed.
- Text uses the `*_text` roles. A tone that works as a fill often isn't readable as text.
- Contrast is tested. `tests/test_theme.gd` checks every pair it lists against WCAG AA (4.5:1 for text, 3:1 for the focus ring) in both dark and light tokens. Add your game's tokens file to its list if you want the same check.
- Colour never carries meaning on its own. Pair it with a label, an icon or a shape.
- One accent per screen, for the thing that matters. Surfaces stay neutral.

## Icons

Icons are always fetched by name through the tokens (`tokens.icon("coins", "Lg")`), never from a file path, so a game's `WoldIconSet` can swap any of them. They're white line art tinted by the control; full-colour art is the exception (`icon_tint = ORIGINAL`).

## Fills

A value should never squash a fill's artwork. Use `WoldFill` in `TILE` or `REVEAL` for anything with a pattern or picture, and keep `STRETCH` for plain colour.

## Games are not web pages

Focus matters, because pad and keyboard players live on it. Every interactive control has a focus ring, and the engine already hides it after a mouse click. Text drawn straight over the 3D world uses `TextOutlined` or `Display`; HUD panels use `PanelHud`.

## Motion

- Every UI tween goes through `WoldMotion`. No `create_tween` for UI in feature code.
- Lay content out where it ends up, and only animate from an offset.
- Animate the offset transform, never `position` or `scale`. Containers reset those on every sort; they leave the offset transform alone.
- Reduced motion means jump to the end state, not a shorter animation.
- Motion never carries meaning alone: a shake comes with the error sound, a pulse with a label.
- Feedback is one `WoldFeedback` node per scene, with per-button metadata, not a script on every button. Focus sounds and lifts only happen on keyboard or pad.

## Naming

Don't name an enum after a Godot class or global enum (`Curve`, `Corner`, `Side`, `Orientation`, `Anchor`...). It shadows the engine's and the script stops compiling. Use `Easing`, `Pin`, `Place`, `Placement` and so on; `test_theme` compiles every script, so you find out quickly. Same for props: `button_size`, not `size`.

## Extending

Data first: a `WoldVariant` covers most "like X but..." cases. A recipe second: a `static func contribute(theme, t)` in `extra_recipes`, built only from tokens and `WoldStyle`. Don't edit the addon for one game. If every game needs something, it goes into the addon with a test.

A new core style goes in its recipe's `STYLES` list, gets built in `contribute()`, and shows up in the gallery. `test_theme` checks it exists.
