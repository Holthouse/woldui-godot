@tool
extends RefCounted
## Surfaces. PanelContainer styles, work on a plain Panel too.

const STYLES: PackedStringArray = [
	"PanelBase", "PanelRaised", "PanelOverlay", "PanelHud", "PanelSunken", "PanelCallout", "PanelScrim", "PanelBare",
]


static func contribute(theme: Theme, t: WoldTokens) -> void:
	var inset := Vector2i(t.space_lg, t.space_lg)
	# full-screen backdrop (menus)
	_panel(theme, "PanelBase", WoldStyle.flat(t.role("surface_base"), 0))
	_panel(theme, "PanelRaised", WoldStyle.flat(t.role("surface_raised"), t.radius_md, inset, t.role("border"), t.border_width))
	_panel(theme, "PanelOverlay", WoldStyle.raised(t.role("surface_overlay"), t.radius_lg, Vector2i(t.space_xl, t.space_xl), t, t.role("border")))
	_panel(theme, "PanelHud", WoldStyle.flat(t.role("surface_hud"), t.radius_md, Vector2i(t.space_md, t.space_sm)))
	_panel(theme, "PanelSunken", WoldStyle.flat(t.role("surface_sunken"), t.radius_sm, Vector2i(t.space_md, t.space_md), t.role("border"), t.border_width))
	var callout := WoldStyle.flat(t.role("accent_soft"), t.radius_md, inset)
	callout.border_color = t.role("accent")
	callout.border_width_left = t.focus_width + 1
	_panel(theme, "PanelCallout", callout)
	_panel(theme, "PanelScrim", WoldStyle.flat(t.role("scrim"), 0))
	_panel(theme, "PanelBare", WoldStyle.empty())


static func _panel(theme: Theme, style: String, sb: StyleBox) -> void:
	theme.set_type_variation(style, "PanelContainer")
	theme.set_stylebox("panel", style, sb)
