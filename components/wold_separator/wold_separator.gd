@tool
class_name WoldSeparator
extends Control
## A dividing line, with an optional label in it ("or", "Turn 12"). Unlike
## HSeparator it can carry text, and it's vertical when you ask.

enum Place { CENTER, START }

@export var text := "":
	set(v):
		text = v
		_refresh()
@export var vertical := false:
	set(v):
		vertical = v
		_refresh()
## Where the label sits along the line.
@export var place: Place = Place.CENTER:
	set(v):
		place = v
		_refresh()


func _ready() -> void:
	theme_type_variation = &"Divider"
	_refresh()


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_THEME_CHANGED:
			_refresh.call_deferred()
		NOTIFICATION_RESIZED:
			_place_label()


func _refresh() -> void:
	if not is_node_ready():
		return
	var label := %Label as Label
	label.text = text
	label.visible = text != "" and not vertical
	var line := float(get_theme_constant(&"thickness"))
	if vertical:
		custom_minimum_size = Vector2(line, 0)
	else:
		var need := label.get_combined_minimum_size() if label.visible else Vector2.ZERO
		custom_minimum_size = Vector2(need.x + get_theme_constant(&"gap") * 4.0 if label.visible else 0.0, maxf(need.y, line))
	_place_label()
	queue_redraw()


## Where the label goes, in our own space. Empty when there isn't one.
func label_rect() -> Rect2:
	var label := %Label as Label
	if not label.visible:
		return Rect2()
	var s := label.get_combined_minimum_size()
	var x := (size.x - s.x) / 2.0 if place == Place.CENTER else float(get_theme_constant(&"gap")) * 2.0
	return Rect2(Vector2(x, (size.y - s.y) / 2.0), s)


func _place_label() -> void:
	var r := label_rect()
	var label := %Label as Label
	label.position = r.position
	label.size = r.size


func _draw() -> void:
	var c := get_theme_color(&"line")
	var w := float(get_theme_constant(&"thickness"))
	if vertical:
		draw_rect(Rect2((size.x - w) / 2.0, 0, w, size.y), c)
		return
	var y := (size.y - w) / 2.0
	var r := label_rect()
	if r.size == Vector2.ZERO:
		draw_rect(Rect2(0, y, size.x, w), c)
		return
	var gap := float(get_theme_constant(&"gap"))
	draw_rect(Rect2(0, y, maxf(r.position.x - gap, 0.0), w), c)
	var after := r.end.x + gap
	draw_rect(Rect2(after, y, maxf(size.x - after, 0.0), w), c)


func _validate_property(property: Dictionary) -> void:
	if property.name in ["custom_minimum_size", "theme_type_variation"]:
		property.usage &= ~PROPERTY_USAGE_STORAGE
