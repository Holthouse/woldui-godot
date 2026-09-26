@tool
class_name WoldToast
extends PanelContainer
## Corner notification that times out by itself.
##   WoldToast.notify(self, "Game saved", WoldToast.Tone.SUCCESS)
## notify() hands the toast back, so you can bolt on a button afterwards:
##   var t := WoldToast.notify(self, "Trade offer", WoldToast.Tone.ACCENT, "Trade", 0)
##   t.action_text = "View"; t.action_pressed.connect(open_trade)
# Plays "error" for DANGER and "open" otherwise. Want silent toasts? Leave
# "open" empty in your WoldSoundSet.

signal action_pressed
signal dismissed

enum Tone { NEUTRAL, ACCENT, SUCCESS, WARNING, DANGER }
const _TONE_STYLES := ["Muted", "TextAccent", "TextSuccess", "TextWarning", "TextDanger"]
const _TONE_ICONS := ["info", "sparkles", "circle-check", "triangle-alert", "circle-alert"]
const _TONE_METERS := ["MeterThin", "MeterAccent", "MeterSuccess", "MeterWarning", "MeterDanger"]
const SCENE := "res://addons/woldui/components/wold_toast/wold_toast.tscn"

@export var title := "":
	set(v):
		title = v
		_refresh()
@export_multiline var message := "Notification":
	set(v):
		message = v
		_refresh()
## Empty = the tone's default icon.
@export var icon := "":
	set(v):
		icon = v
		_refresh()
@export var tone: Tone = Tone.NEUTRAL:
	set(v):
		tone = v
		_refresh()
## Adds a button. Pressing it emits action_pressed and dismisses.
@export var action_text := "":
	set(v):
		action_text = v
		_refresh()
## 0 = sticks around until closed.
@export_range(0.0, 30.0, 0.1, "suffix:s") var duration := 4.0
@export var closable := true:
	set(v):
		closable = v
		_refresh()
## Thin countdown bar. Hidden under reduced motion.
@export var show_timer := true:
	set(v):
		show_timer = v
		_refresh()

var is_leaving := false
var _life: Tween
var _refreshing := false


## Makes the toaster too if there isn't one yet.
static func notify(host: Node, text: String, toast_tone := Tone.NEUTRAL, toast_title := "", seconds := 4.0) -> WoldToast:
	var t: WoldToast = load(SCENE).instantiate()
	t.message = text
	t.tone = toast_tone
	t.title = toast_title
	t.duration = seconds
	WoldToaster.find_or_create(host).push(t)
	return t


func _ready() -> void:
	_refresh()
	if Engine.is_editor_hint():
		return
	%Action.pressed.connect(func():
		action_pressed.emit()
		dismiss())
	%Close.pressed.connect(dismiss)
	# TODO: hover pauses the countdown but focus doesn't, so a pad player
	# tabbing to the action button can still lose the toast.
	mouse_entered.connect(func(): if _life: _life.pause())
	mouse_exited.connect(func(): if _life and not is_leaving: _life.play())


## Subclass hook.
func _wold_refresh() -> void:
	pass


## Toaster calls this once it's parented. Starts the countdown.
func arrive() -> void:
	WoldMotion.appear(self, WoldMotion.preset("toast_in"))
	WoldUIRuntime.instance().play("error" if tone == Tone.DANGER else "open")
	if duration > 0.0:
		var bar := %Timer as ProgressBar
		bar.value = 100.0
		_life = create_tween()
		_life.tween_property(bar, "value", 0.0, duration)
		_life.tween_callback(dismiss)


## Safe to call twice.
func dismiss() -> void:
	if is_leaving:
		return
	is_leaving = true
	if _life:
		_life.kill()
	dismissed.emit()
	var tw := WoldMotion.disappear(self, WoldMotion.preset("toast_out"))
	await tw.finished
	var toaster := _toaster()
	if toaster:
		toaster.collapse(self)
	else:
		queue_free()


func _toaster() -> WoldToaster:
	var n := get_parent()
	while n and not n is WoldToaster:
		n = n.get_parent()
	return n as WoldToaster


func _refresh() -> void:
	if _refreshing or not is_node_ready():
		return
	_refreshing = true
	_wold_refresh()
	(%Title as Label).text = title
	%Title.visible = title != ""
	(%Message as Label).text = message
	var icon_node := %Icon as TextureRect
	icon_node.texture = WoldUIRuntime.instance().tokens.icon(icon if icon != "" else _TONE_ICONS[tone])
	icon_node.self_modulate = get_theme_color("font_color", _TONE_STYLES[tone])
	var action := %Action as WoldButton
	action.text = action_text
	action.visible = action_text != ""
	%Close.visible = closable
	var bar := %Timer as ProgressBar
	bar.theme_type_variation = StringName(_TONE_METERS[tone])
	bar.visible = show_timer and duration > 0.0 and not WoldUIRuntime.instance().reduced_motion
	_refreshing = false
