@tool
class_name WoldAlert
extends PanelContainer
## A banner that sits in the layout: "Autosave failed", "The Moles broke the
## treaty". Tone picks the colour and a default icon. Buttons go in %Action.
## `dismissible` adds a close button; closing fades it out.

signal closed

enum Tone { NEUTRAL, ACCENT, SUCCESS, WARNING, DANGER }

# same icons as WoldToast, so a tone means the same thing everywhere
const _ICONS := ["info", "sparkles", "circle-check", "triangle-alert", "circle-alert"]
const _STYLES := ["AlertNeutral", "AlertAccent", "AlertSuccess", "AlertWarning", "AlertDanger"]

@export var tone: Tone = Tone.NEUTRAL:
	set(v):
		tone = v
		_refresh()
@export var title := "Heads up":
	set(v):
		title = v
		_refresh()
@export_multiline var description := "":
	set(v):
		description = v
		_refresh()
## Empty = the tone's own icon.
@export var icon := "":
	set(v):
		icon = v
		_refresh()
@export var dismissible := false:
	set(v):
		dismissible = v
		_refresh()
## Free it after closing instead of just hiding it.
@export var free_on_close := false

var _refreshing := false


func _ready() -> void:
	%Close.pressed.connect(close)
	%Action.child_entered_tree.connect(func(_n): _refresh.call_deferred())
	%Action.child_exiting_tree.connect(func(_n): _refresh.call_deferred())
	_refresh()


func _notification(what: int) -> void:
	if what == NOTIFICATION_THEME_CHANGED:
		_refresh.call_deferred()


## Subclass hook, before each restyle.
func _wold_refresh() -> void:
	pass


## Fades out, then hides (or frees). Emits `closed` at the end.
func close() -> void:
	var tw := WoldMotion.disappear(self, null, free_on_close)
	tw.finished.connect(func(): closed.emit())


func _refresh() -> void:
	if _refreshing or not is_node_ready():
		return
	_refreshing = true
	_wold_refresh()
	var t := WoldUIRuntime.instance().tokens
	theme_type_variation = StringName(_STYLES[tone])
	(%Title as Label).text = title
	%Title.visible = title != ""
	(%Description as Label).text = description
	%Description.visible = description != ""
	var lead := %Icon as TextureRect
	lead.texture = t.icon(icon if icon != "" else _ICONS[tone])
	lead.custom_minimum_size = Vector2(t.icon_size_md, t.icon_size_md)
	lead.self_modulate = get_theme_color(&"icon")
	%Action.visible = %Action.get_children().any(func(c): return not c.is_queued_for_deletion())
	var close_button := %Close as Button
	close_button.visible = dismissible
	close_button.icon = t.icon("x", "Sm")
	_refreshing = false


func _validate_property(property: Dictionary) -> void:
	if property.name == "theme_type_variation":
		property.usage &= ~PROPERTY_USAGE_STORAGE
