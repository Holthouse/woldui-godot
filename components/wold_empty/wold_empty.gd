@tool
class_name WoldEmpty
extends VBoxContainer
## What a list, inventory or search shows when there's nothing in it: an
## icon, a line saying so, a hint, and buttons in %Actions ("Start a game").

@export var icon := "inbox":
	set(v):
		icon = v
		_refresh()
@export var title := "Nothing here yet":
	set(v):
		title = v
		_refresh()
@export_multiline var description := "":
	set(v):
		description = v
		_refresh()

var _refreshing := false


func _ready() -> void:
	%Actions.child_entered_tree.connect(func(_n): _refresh.call_deferred())
	%Actions.child_exiting_tree.connect(func(_n): _refresh.call_deferred())
	_refresh()


func _notification(what: int) -> void:
	if what == NOTIFICATION_THEME_CHANGED:
		_refresh.call_deferred()


## Subclass hook, before each restyle.
func _wold_refresh() -> void:
	pass


func _refresh() -> void:
	if _refreshing or not is_node_ready():
		return
	_refreshing = true
	_wold_refresh()
	var t := WoldUIRuntime.instance().tokens
	var media := %Media as Control
	media.visible = icon != ""
	var pic := %Icon as TextureRect
	pic.texture = t.icon(icon, "Lg") if icon != "" else null
	pic.custom_minimum_size = Vector2(t.icon_size_lg, t.icon_size_lg)
	pic.self_modulate = media.get_theme_color(&"icon")
	(%Title as Label).text = title
	%Title.visible = title != ""
	(%Description as Label).text = description
	%Description.visible = description != ""
	%Actions.visible = %Actions.get_children().any(func(c): return not c.is_queued_for_deletion())
	_refreshing = false
