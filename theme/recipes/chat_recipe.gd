@tool
extends RefCounted
## Speech and chat: WoldBubble, WoldMessage, WoldMessageLog. A bubble's
## "tail" is the corner nearest the speaker squared off, chat-app style.

const VARIANTS: PackedStringArray = ["Default", "Secondary", "Muted", "Tinted", "Outline", "Ghost", "Danger"]
const TAILS: PackedStringArray = ["", "Start", "End"]

const STYLES: PackedStringArray = [
	"BubbleDefault", "BubbleDefaultStart", "BubbleDefaultEnd",
	"BubbleSecondary", "BubbleSecondaryStart", "BubbleSecondaryEnd",
	"BubbleMuted", "BubbleMutedStart", "BubbleMutedEnd",
	"BubbleTinted", "BubbleTintedStart", "BubbleTintedEnd",
	"BubbleOutline", "BubbleOutlineStart", "BubbleOutlineEnd",
	"BubbleGhost", "BubbleGhostStart", "BubbleGhostEnd",
	"BubbleDanger", "BubbleDangerStart", "BubbleDangerEnd",
	"MessageName", "MessageTime", "MessageLog",
]


static func contribute(theme: Theme, t: WoldTokens) -> void:
	var pad := Vector2i(t.space_md, t.space_sm)
	var r := t.radius_lg
	var clear := Color(0, 0, 0, 0)
	# [fill, text, border]
	var looks := {
		"Default": [t.role("accent"), t.role("on_accent"), clear],
		# control_hover, not control: in light mode control IS the base surface
		"Secondary": [t.role("control_hover"), t.role("text"), clear],
		"Muted": [t.role("surface_sunken"), t.role("text_muted"), clear],
		"Tinted": [t.role("accent_soft"), t.role("text"), clear],
		"Outline": [clear, t.role("text"), t.role("border_strong")],
		"Ghost": [clear, t.role("text"), clear],
		"Danger": [t.role("danger_soft"), t.role("danger_text"), t.role("danger")],
	}
	for v in VARIANTS:
		var look: Array = looks[v]
		for tail in TAILS:
			var style: String = "Bubble" + v + tail
			theme.set_type_variation(style, "PanelContainer" if tail == "" else "Bubble" + v)
			var sb := WoldStyle.flat(look[0], r, pad, look[2], t.border_width)
			# the tail is the bottom corner on the speaker's side
			if tail == "Start":
				@warning_ignore("integer_division")
				sb.corner_radius_bottom_left = t.radius_sm / 2
			elif tail == "End":
				@warning_ignore("integer_division")
				sb.corner_radius_bottom_right = t.radius_sm / 2
			theme.set_stylebox("panel", style, sb)
			theme.set_color("text", style, look[1])
	theme.set_type_variation("MessageName", "Label")
	theme.set_font_size("font_size", "MessageName", t.font_size(-1))
	theme.set_color("font_color", "MessageName", t.role("text"))
	theme.set_type_variation("MessageTime", "Label")
	theme.set_font_size("font_size", "MessageTime", t.font_size(-2))
	theme.set_color("font_color", "MessageTime", t.role("text_muted"))
	theme.set_type_variation("MessageLog", "ScrollContainer")
	theme.set_stylebox("panel", "MessageLog", WoldStyle.empty())
