@tool
class_name WoldListRow
extends Button
## Save slot / lobby / codex entry row. It's a Button with a layout stuffed
## inside, so focus and pad activation come for free. Share one ButtonGroup
## across rows for single-select.
## Extra bits go in %Leading (avatar, flag) or %Trailing (a badge, say).

const Content := preload("../shared/wold_button_content.gd")

enum Look { PLAIN, OUTLINE, MUTED }
enum Size { SM, MD }

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
## PLAIN is quiet until hovered, OUTLINE has an edge, MUTED a soft fill.
@export var look: Look = Look.PLAIN:
	set(v):
		look = v
		_refresh()
## Not `size`, Control has one.
@export var row_size: Size = Size.MD:
	set(v):
		row_size = v
		_refresh()
@export_range(0, 200) var min_height := 0:
	set(v):
		min_height = v
		_fit()

var _refreshing := false


func _ready() -> void:
	toggle_mode = selectable
	text = ""
	alignment = HORIZONTAL_ALIGNMENT_LEFT
	%Content.minimum_size_changed.connect(_fit)
	_refresh()


func _notification(what: int) -> void:
	if what == NOTIFICATION_THEME_CHANGED:
		_fit.call_deferred()
		# deferred: the labels hear about the new theme after we do
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
	var sm := row_size == Size.SM
	theme_type_variation = StringName("ListRow" + ["", "Outline", "Muted"][look] + ("Sm" if sm else ""))
	(%Title as Label).theme_type_variation = &"ListRowTitleSm" if sm else &"ListRowTitle"
	(%Title as Label).text = title
	(%Subtitle as Label).text = subtitle
	%Subtitle.visible = subtitle != ""
	var lead := %Icon as TextureRect
	lead.texture = t.icon(icon_name, "Sm" if sm else "") if icon_name != "" else null
	lead.visible = icon_name != ""
	var px := t.icon_size_sm if sm else t.icon_size_md
	lead.custom_minimum_size = Vector2(px, px)
	lead.self_modulate = _tint()
	(%Meta as Label).text = trailing_text
	%Meta.visible = trailing_text != ""
	var end := %End as TextureRect
	end.texture = t.icon(trailing_icon, "Sm") if trailing_icon != "" else null
	end.visible = trailing_icon != ""
	end.custom_minimum_size = Vector2(t.icon_size_sm, t.icon_size_sm)
	end.self_modulate = _tint()
	_refreshing = false
	_fit()


# the muted colour of the theme we sit in (a WoldScope may differ from the
# global tokens)
func _tint() -> Color:
	return (%Meta as Label).get_theme_color(&"font_color")


func _fit() -> void:
	if not is_node_ready():
		return
	Content.fit(self, %Content)
	# min_height is the whole row, padding included
	custom_minimum_size.y = maxf(custom_minimum_size.y, min_height)


# all set in code, don't save them
func _validate_property(property: Dictionary) -> void:
	if property.name in ["custom_minimum_size", "theme_type_variation", "toggle_mode", "text", "alignment"]:
		property.usage &= ~PROPERTY_USAGE_STORAGE
