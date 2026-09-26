@tool
class_name WoldTransition
## Screen transitions. Uses the screen_enter / screen_exit presets and the
## open/close sounds. Doesn't manage a screen stack, bring your own.


static func enter(screen: Control, sound := true) -> Tween:
	if sound:
		WoldUIRuntime.instance().play("open")
	return WoldMotion.appear(screen, WoldMotion.preset("screen_enter"))


static func exit(screen: Control, then_free := false, sound := true) -> Tween:
	if sound:
		WoldUIRuntime.instance().play("close")
	return WoldMotion.disappear(screen, WoldMotion.preset("screen_exit"), then_free)


## Both run at once. Returns the incoming screen's tween.
static func swap(from: Control, to: Control, free_old := false) -> Tween:
	if from:
		exit(from, free_old, false)
	return enter(to)
