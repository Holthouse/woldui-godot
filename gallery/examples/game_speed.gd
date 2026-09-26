@tool
extends WoldRadioGroup
## The options mean something: `speed` is the turn timer the pick stands for.

const SECONDS := [0.0, 90.0, 45.0]

var speed: float:
	get:
		return SECONDS[selected] if selected >= 0 else 0.0
