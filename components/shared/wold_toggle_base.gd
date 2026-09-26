@tool
extends Button
## Internal. The bit WoldSwitch and WoldCheckbox share: a toggle Button with a
## label, an optional description, and an indicator drawn in the room the
## stylebox leaves on the left.

const Content := preload("wold_button_content.gd")

@export var label := "Label":
	set(v):
		label = v
		_refresh()
@export_multiline var description := "":
	set(v):
		description = v
		_refresh()

var _refreshing := false


func _init() -> void:
	toggle_mode = true


func _ready() -> void:
	theme_type_variation = _style()
	text = ""
	%Content.minimum_size_changed.connect(_fit)
	_refresh()


func _notification(what: int) -> void:
	if what == NOTIFICATION_THEME_CHANGED:
		_fit.call_deferred()


## Subclass hook, before each restyle.
func _wold_refresh() -> void:
	pass


## Where the indicator goes, in the button's own space. Lines up with the
## label's first line when there's a description.
func indicator_rect() -> Rect2:
	var s := _indicator_size()
	var x := get_theme_stylebox("normal").get_margin(SIDE_LEFT) - s.x - get_theme_constant("h_separation")
	var mid := Content.label_mid(self, %Content, %Label, description != "")
	return Rect2(x, mid - s.y / 2.0, s.x, s.y)


func _style() -> StringName:
	return &""


func _indicator_size() -> Vector2:
	return Vector2.ZERO


func _draw_indicator(_rect: Rect2) -> void:
	pass


func _refresh() -> void:
	if _refreshing or not is_node_ready():
		return
	_refreshing = true
	_wold_refresh()
	(%Label as Label).text = label
	%Label.visible = label != ""
	(%Description as Label).text = description
	%Description.visible = description != ""
	_refreshing = false
	_fit()


func _fit() -> void:
	if not is_node_ready():
		return
	Content.fit(self, %Content, _indicator_size().y)
	queue_redraw()


func _draw() -> void:
	# disabled has no signal, but it always redraws
	Content.dim(self, %Label, &"ToggleLabel")
	Content.dim(self, %Description, &"ToggleDescription")
	_draw_indicator(indicator_rect())


func _validate_property(property: Dictionary) -> void:
	if property.name in ["custom_minimum_size", "theme_type_variation", "toggle_mode", "text"]:
		property.usage &= ~PROPERTY_USAGE_STORAGE
