@tool
class_name WoldTokens
extends Resource
## Design tokens. One .tres per game, WoldThemeBuilder turns it into a Theme.
## Semantic colours (role("text") etc.) are derived from the seeds.

enum Mode { DARK, LIGHT }
enum IconTint { INHERIT, ORIGINAL }

@export var mode: Mode = Mode.DARK

@export_group("Colour seeds")
## Surfaces, borders, text. A bit of hue here tints all the greys.
@export var neutral := Color("6f7480")
## Primary buttons, focus, selection. Just the one.
@export var accent := Color("c9a15b")
@export var success := Color("5da574")
@export var warning := Color("d99a3c")
@export var danger := Color("c2413b")
## {"accent": {700: Color(...)}}
@export var ramp_overrides: Dictionary = {}
## {"text_muted": Color(...)}, see role()
@export var role_overrides: Dictionary[String, Color] = {}
## HUD panels, lets the world show through.
@export_range(0.0, 1.0, 0.01) var hud_opacity := 0.86

@export_group("Typography")
## null = engine default
@export var body_font: Font
## Titles. Falls back to body_font.
@export var display_font: Font
@export var mono_font: Font
@export_range(8, 64) var base_font_size := 18
@export_range(1.05, 1.6, 0.005) var type_ratio := 1.25
## For text straight over the world (TextOutlined, Display).
@export_range(0, 16) var text_outline_size := 4

@export_group("Space")
@export var space_xs := 4
@export var space_sm := 8
@export var space_md := 12
@export var space_lg := 16
@export var space_xl := 24
@export var space_xxl := 32

@export_group("Controls")
## Button/field padding (x, y) per size.
@export var padding_sm := Vector2i(12, 5)
@export var padding_md := Vector2i(18, 9)
@export var padding_lg := Vector2i(26, 13)

@export_group("Shape")
@export var radius_sm := 3
@export var radius_md := 6
@export var radius_lg := 10
@export var border_width := 1
@export var focus_width := 2
## Gap between control and focus ring.
@export var focus_offset := 2
@export var shadow_size := 14
@export var shadow_offset := Vector2(0, 4)

@export_group("Motion")
@export_range(0.0, 1.0, 0.01) var duration_instant := 0.08
@export_range(0.0, 1.0, 0.01) var duration_fast := 0.15
@export_range(0.0, 2.0, 0.01) var duration_base := 0.24
@export_range(0.0, 2.0, 0.01) var duration_slow := 0.36
## Arrivals. Fast in, soft landing.
@export var enter_transition: Tween.TransitionType = Tween.TRANS_QUART
@export var enter_ease: Tween.EaseType = Tween.EASE_OUT
## Moving from one on-screen spot to another.
@export var move_transition: Tween.TransitionType = Tween.TRANS_CUBIC
@export var move_ease: Tween.EaseType = Tween.EASE_IN_OUT
@export_range(0.8, 1.0, 0.005) var press_scale := 0.97
@export_range(1.0, 1.2, 0.005) var hover_scale := 1.0
## Hover time before a WoldTooltip shows.
@export_range(0.0, 2.0, 0.05, "suffix:s") var tooltip_delay := 0.45
## Game-wide replacements for bundled presets ("appear", "screen_enter"...).
## Unlisted names use motion/presets/<name>.tres.
@export var motion_presets: Dictionary[String, WoldMotionPreset] = {}

@export_group("Icons")
## Your own icons over Lucide. null = just Lucide (browse in the WoldUI dock).
@export var icon_set: WoldIconSet
## On Lucide's 24px grid. 2 is Lucide's default.
@export_range(0.5, 3.0, 0.25) var icon_stroke := 2.0
@export var icon_size_sm := 16
@export var icon_size_md := 20
@export var icon_size_lg := 24
@export var icon_tint: IconTint = IconTint.INHERIT

@export_group("Sound")
## Empty slots fall back to the built-in sounds (if on).
@export var sounds: WoldSoundSet
## Synthesised placeholder blips for empty slots. Off = silence.
@export var use_builtin_sounds := true

@export_group("Extension")
@export var variants: Array[WoldVariant] = []
## Scripts with `static func contribute(theme: Theme, t: WoldTokens)`, for
## stuff a WoldVariant can't express.
@export var extra_recipes: Array[Script] = []
## Hand-made stylebox in place of a generated one:
## {"PanelOverlay/panel": StyleBoxTexture}
@export var texture_overrides: Dictionary[String, StyleBox] = {}
## {"food": Color} for meter fills and such. Don't let colour be the only cue.
@export var extra_colors: Dictionary[String, Color] = {}


# ---------------------------------------------------------------- ramps

## "neutral", "accent", "success", "warning" or "danger".
func ramp(tone_name: String) -> Dictionary:
	return WoldColor.ramp(get(tone_name), ramp_overrides.get(tone_name, {}))


## e.g. tone("accent", 300)
func tone(tone_name: String, step: int) -> Color:
	return ramp(tone_name)[step]


# ---------------------------------------------------------------- semantic

const TONES: PackedStringArray = ["accent", "success", "warning", "danger"]

# gallery + contrast test read this, so a new role only goes in _roles()
func role_names() -> PackedStringArray:
	return PackedStringArray(_roles().keys())


## Semantic colour by name. role_overrides wins.
func role(role_name: String) -> Color:
	if role_overrides.has(role_name):
		return role_overrides[role_name]
	var all := _roles()
	assert(all.has(role_name), "WoldTokens: unknown role '%s'" % role_name)
	return all.get(role_name, Color.MAGENTA)


func _roles() -> Dictionary:
	var n := ramp("neutral")
	var dark := mode == Mode.DARK
	var r := {}
	r.surface_base = n[950] if dark else n[100]
	r.surface_raised = n[900] if dark else n[50]
	r.surface_overlay = n[800] if dark else Color.WHITE
	r.surface_sunken = n[950].darkened(0.25) if dark else n[200]
	# fields need a 3:1 edge on every surface (WCAG 1.4.11) or they vanish
	# into the panel
	r.field = n[950].darkened(0.25) if dark else Color.WHITE
	r.field_border = n[300] if dark else n[500]
	r.surface_hover = Color(n[50], 0.08) if dark else Color(n[900], 0.06)
	r.surface_pressed = Color(n[50], 0.14) if dark else Color(n[900], 0.11)
	r.surface_hud = Color(r.surface_base, hud_opacity)
	r.control = n[800] if dark else n[100]
	r.control_hover = n[700] if dark else n[200]
	r.control_pressed = n[600] if dark else n[300]
	r.border = n[700] if dark else n[200]
	r.border_strong = n[500] if dark else n[400]
	r.text = n[50] if dark else n[900]
	r.text_muted = n[200] if dark else n[700]
	r.text_disabled = n[500] if dark else n[400]
	r.control_disabled = Color(n[500], 0.14) if dark else Color(n[400], 0.16)
	r.scrim = Color(n[950].darkened(0.4), 0.72) if dark else Color(n[900], 0.45)
	r.shadow = Color(0, 0, 0, 0.5) if dark else Color(n[900], 0.18)
	r.text_outline = Color(0, 0, 0, 0.9) if dark else Color(1, 1, 1, 0.9)
	for t in TONES:
		var ramp_t := ramp(t)
		r[t] = ramp_t[500]
		r[t + "_hover"] = ramp_t[400] if dark else ramp_t[600]
		r[t + "_pressed"] = ramp_t[600] if dark else ramp_t[700]
		r["on_" + t] = WoldColor.on(ramp_t[500], Color.WHITE, n[950])
		# 500 works as a fill but is often too dim as text on a surface
		r[t + "_text"] = ramp_t[300] if dark else ramp_t[700]
		r[t + "_soft"] = Color(ramp_t[500], 0.16 if dark else 0.12)
	r.focus = ramp("accent")[300] if dark else ramp("accent")[600]
	return r


# ---------------------------------------------------------------- scales

## 0 = base_font_size, each step multiplies by type_ratio.
func font_size(step: int) -> int:
	return int(round(base_font_size * pow(type_ratio, step)))


func display() -> Font:
	return display_font if display_font else body_font


## "Sm", "" or "Lg". Anything else is treated as medium.
func control_size(size_name: String) -> Dictionary:
	match size_name:
		"Sm":
			return {padding = padding_sm, font = font_size(-1), icon = icon_size_sm, radius = radius_sm}
		"Lg":
			return {padding = padding_lg, font = font_size(1), icon = icon_size_lg, radius = radius_md}
		_:
			return {padding = padding_md, font = font_size(0), icon = icon_size_md, radius = radius_md}


## Icon at a control size, via icon_set if there is one.
func icon(icon_name: String, size_name := "") -> Texture2D:
	var px: int = control_size(size_name).icon
	if icon_set:
		return icon_set.get_icon(icon_name, px, icon_stroke)
	return WoldIcons.texture(icon_name, px, icon_stroke)


## Copy with some tokens swapped, {"accent": Color.RED}. Used by variants and
## WoldScope.
# shallow duplicate: sub-resources (icon_set, sounds) stay shared
func derive(overrides: Dictionary) -> WoldTokens:
	var copy: WoldTokens = duplicate(false)
	for key in overrides:
		assert(key in copy, "WoldTokens.derive: unknown token '%s'" % key)
		copy.set(key, overrides[key])
	return copy
