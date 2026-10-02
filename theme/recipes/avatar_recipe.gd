@tool
extends RefCounted
## WoldAvatar: portrait frame, initials, status dot. Round or square, three
## sizes. The frame's stylebox is also the clip mask for the picture.

const STYLES: PackedStringArray = [
	"AvatarRound", "AvatarRoundSm", "AvatarRoundLg", "AvatarSquare", "AvatarSquareSm", "AvatarSquareLg",
	"AvatarInitials", "AvatarInitialsSm", "AvatarInitialsLg",
	"AvatarOnline", "AvatarAway", "AvatarBusy", "AvatarOffline", "AvatarGroup", "AvatarGroupSm", "AvatarGroupLg",
]


static func contribute(theme: Theme, t: WoldTokens) -> void:
	var sizes := {"Sm": t.icon_size_sm * 2, "": t.icon_size_md * 2, "Lg": t.icon_size_lg * 2 + t.space_sm}
	var fonts := {"Sm": t.font_size(-2), "": t.font_size(-1), "Lg": t.font_size(1)}
	for size in sizes:
		var px: int = sizes[size]
		for shape in ["Round", "Square"]:
			var style: String = "Avatar" + shape + size
			theme.set_type_variation(style, "Panel")
			@warning_ignore("integer_division")
			var r: int = px / 2 if shape == "Round" else (t.radius_md if size != "Lg" else t.radius_lg)
			var sb := WoldStyle.flat(t.role("control_pressed"), r)
			sb.corner_detail = 16
			theme.set_stylebox("panel", style, sb)
			theme.set_constant("size", style, px)
			theme.set_constant("ring_width", style, 2)
			theme.set_color("ring", style, t.role("surface_raised"))
		var initials: String = "AvatarInitials" + size
		theme.set_type_variation(initials, "Label")
		theme.set_font_size("font_size", initials, fonts[size])
		theme.set_color("font_color", initials, t.role("text"))
	var dots := {"AvatarOnline": "success", "AvatarAway": "warning", "AvatarBusy": "danger", "AvatarOffline": "text_disabled"}
	for style in dots:
		theme.set_type_variation(style, "Panel")
		var sb := WoldStyle.flat(t.role(dots[style]), 64, Vector2i.ZERO, t.role("surface_raised"), 2)
		sb.corner_detail = 12
		theme.set_stylebox("panel", style, sb)
	# overlap in a group by a fifth of the avatar, each ring keeps them apart
	for size in sizes:
		var group: String = "AvatarGroup" + size
		theme.set_type_variation(group, "HBoxContainer")
		theme.set_constant("separation", group, -int(sizes[size] / 5))
