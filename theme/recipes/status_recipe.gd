@tool
extends RefCounted
## The quiet stuff: WoldEmpty (nothing here yet), WoldSkeleton (loading
## shapes), WoldSpinner and WoldSeparator.

const STYLES: PackedStringArray = [
	"EmptyMedia", "EmptyTitle", "EmptyBody", "Skeleton", "SkeletonRound", "SkeletonLines", "Spinner",
	"Divider", "DividerLabel",
]


static func contribute(theme: Theme, t: WoldTokens) -> void:
	theme.set_type_variation("EmptyMedia", "PanelContainer")
	theme.set_stylebox("panel", "EmptyMedia", WoldStyle.flat(t.role("surface_sunken"), 64, Vector2i(t.space_md, t.space_md)))
	theme.set_color("icon", "EmptyMedia", t.role("text_muted"))
	theme.set_type_variation("EmptyTitle", "Label")
	theme.set_font_size("font_size", "EmptyTitle", t.font_size(1))
	theme.set_color("font_color", "EmptyTitle", t.role("text"))
	theme.set_type_variation("EmptyBody", "Label")
	theme.set_font_size("font_size", "EmptyBody", t.font_size(-1))
	theme.set_color("font_color", "EmptyBody", t.role("text_muted"))

	theme.set_type_variation("Skeleton", "Panel")
	theme.set_stylebox("panel", "Skeleton", WoldStyle.flat(t.role("control_hover"), t.radius_sm))
	theme.set_type_variation("SkeletonRound", "Skeleton")
	theme.set_stylebox("panel", "SkeletonRound", WoldStyle.flat(t.role("control_hover"), 999))
	# text lines: no panel, WoldSkeleton draws a bar per line
	theme.set_type_variation("SkeletonLines", "Skeleton")
	theme.set_stylebox("panel", "SkeletonLines", StyleBoxEmpty.new())
	theme.set_stylebox("bar", "SkeletonLines", WoldStyle.flat(t.role("control_hover"), t.radius_sm))

	theme.set_type_variation("Spinner", "Control")
	theme.set_color("color", "Spinner", t.role("text_muted"))
	# ms per turn
	theme.set_constant("period_ms", "Spinner", 900)

	theme.set_type_variation("Divider", "Control")
	theme.set_color("line", "Divider", t.role("border"))
	theme.set_constant("thickness", "Divider", t.border_width)
	theme.set_constant("gap", "Divider", t.space_sm)
	theme.set_type_variation("DividerLabel", "Label")
	theme.set_font_size("font_size", "DividerLabel", t.font_size(-1))
	theme.set_color("font_color", "DividerLabel", t.role("text_muted"))
