@tool
class_name WoldListRow
extends Button
## Save slot / lobby / codex entry row. It's a Button with a layout stuffed
## inside, so focus and pad activation come for free. Share one ButtonGroup
## across rows for single-select.
## Extra bits go in %Leading (avatar, flag) or %Trailing (a badge, say).

@export var title := "Row title":
	set(v):
		title = v
		_refresh()
@export var subtitle := "":
	set(v):
		subtitle = v
		_refresh()
## Leading icon by name. (`icon` is taken by Button.)
@export var icon_name := "":
	set(v):
		icon_name = v
		_refresh()
## Muted, right side: "Turn 42", "3 / 4".
@export var trailing_text := "":
	set(v):
		trailing_text = v
		_refresh()
@export var trailing_icon := "":
	set(v):
		trailing_icon = v
		_refresh()
## Just toggle_mode. Selection state is button_pressed.
@export var selectable := true:
	set(v):
		selectable = v
		toggle_mode = v
@export_range(0, 200) var min_height := 0:
	set(v):
		min_height = v
		_fit()

var _refreshing := false


func _ready() -> void:
	theme_type_variation = &"ListRow"
	toggle_mode = selectable
	text = ""
	alignment = HORIZONTAL_ALIGNMENT_LEFT
	%Content.minimum_size_changed.connect(_fit)
	_refresh()


func _notification(what: int) -> void:
	if what == NOTIFICATION_THEME_CHANGED:
		_fit.call_deferred()


## Subclass hook, before each restyle.
func _wold_refresh() -> void:
	pass


func _refresh() -> void:
	if _refreshing or not is_node_ready():
		return
	_refreshing = true
	_wold_refresh()
	var t := WoldUIRuntime.instance().tokens
	(%Title as Label).text = title
	(%Subtitle as Label).text = subtitle
	%Subtitle.visible = subtitle != ""
	var lead := %Icon as TextureRect
	lead.texture = t.icon(icon_name) if icon_name != "" else null
	lead.visible = icon_name != ""
	lead.custom_minimum_size = Vector2(t.icon_size_md, t.icon_size_md)
	lead.self_modulate = t.role("text_muted")
	(%Meta as Label).text = trailing_text
	%Meta.visible = trailing_text != ""
	var end := %End as TextureRect
	end.texture = t.icon(trailing_icon, "Sm") if trailing_icon != "" else null
	end.visible = trailing_icon != ""
	end.custom_minimum_size = Vector2(t.icon_size_sm, t.icon_size_sm)
	end.self_modulate = t.role("text_muted")
	_refreshing = false
	_fit()


# Button doesn't size itself to its children, so do it by hand: inset
# %Content by the stylebox margins and grow the min size to fit.
func _fit() -> void:
	if not is_node_ready():
		return
	var sb := get_theme_stylebox("normal")
	var content := %Content as Control
	content.offset_left = sb.get_margin(SIDE_LEFT)
	content.offset_top = sb.get_margin(SIDE_TOP)
	content.offset_right = -sb.get_margin(SIDE_RIGHT)
	content.offset_bottom = -sb.get_margin(SIDE_BOTTOM)
	var need := content.get_combined_minimum_size() + sb.get_minimum_size()
	custom_minimum_size = Vector2(need.x, maxf(need.y, min_height))


# all set in code, don't save them
func _validate_property(property: Dictionary) -> void:
	if property.name in ["custom_minimum_size", "theme_type_variation", "toggle_mode", "text", "alignment"]:
		property.usage &= ~PROPERTY_USAGE_STORAGE
