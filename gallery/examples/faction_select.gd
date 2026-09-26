@tool
extends WoldSelect
## A select that knows what its options are: each faction has a colour, and
## `accent()` hands back the picked one's (for a WoldScope, say).

const COLOURS := [Color("c0392b"), Color("3a7bd5"), Color("5da574")]


func accent() -> Color:
	return COLOURS[selected] if selected >= 0 else Color.TRANSPARENT
