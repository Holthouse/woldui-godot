@tool
extends RefCounted
## Spacing as styles (StackMd, RowSm, InsetLg, GridMd...) so scenes never
## hard-code a separation. Change a space token and everything follows.

const SIZES := ["Xs", "Sm", "Md", "Lg", "Xl", "Xxl"]

const STYLES: PackedStringArray = [
	"StackXs", "StackSm", "StackMd", "StackLg", "StackXl", "StackXxl",
	"RowXs", "RowSm", "RowMd", "RowLg", "RowXl", "RowXxl",
	"InsetXs", "InsetSm", "InsetMd", "InsetLg", "InsetXl", "InsetXxl",
	"GridXs", "GridSm", "GridMd", "GridLg", "GridXl", "GridXxl",
	"FlowXs", "FlowSm", "FlowMd", "FlowLg", "FlowXl", "FlowXxl",
	"StackNone", "RowNone",
]


static func space(t: WoldTokens, size: String) -> int:
	return t.get("space_" + size.to_lower())


static func contribute(theme: Theme, t: WoldTokens) -> void:
	# engine default is 4px, which isn't on our scale
	theme.set_constant("separation", "VBoxContainer", t.space_sm)
	theme.set_constant("separation", "HBoxContainer", t.space_sm)
	theme.set_constant("h_separation", "GridContainer", t.space_sm)
	theme.set_constant("v_separation", "GridContainer", t.space_sm)
	# zero gap, for bits that have to touch (tab bar + rail)
	theme.set_type_variation("StackNone", "VBoxContainer")
	theme.set_constant("separation", "StackNone", 0)
	theme.set_type_variation("RowNone", "HBoxContainer")
	theme.set_constant("separation", "RowNone", 0)
	for size in SIZES:
		var px := space(t, size)
		theme.set_type_variation("Stack" + size, "VBoxContainer")
		theme.set_constant("separation", "Stack" + size, px)
		theme.set_type_variation("Row" + size, "HBoxContainer")
		theme.set_constant("separation", "Row" + size, px)
		theme.set_type_variation("Inset" + size, "MarginContainer")
		for side in ["margin_left", "margin_top", "margin_right", "margin_bottom"]:
			theme.set_constant(side, "Inset" + size, px)
		theme.set_type_variation("Grid" + size, "GridContainer")
		theme.set_constant("h_separation", "Grid" + size, px)
		theme.set_constant("v_separation", "Grid" + size, px)
		theme.set_type_variation("Flow" + size, "HFlowContainer")
		theme.set_constant("h_separation", "Flow" + size, px)
		theme.set_constant("v_separation", "Flow" + size, px)
