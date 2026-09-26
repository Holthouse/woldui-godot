@tool
class_name WoldBubble
extends VBoxContainer
## A speech bubble: chat lines, NPC barks, a tutorial character talking.
## It shrinks to short text and wraps at `max_width`. `tail` squares off the
## corner towards whoever is speaking. Reactions (badges, emoji) go in
## %Reactions under it; anything else in %Content inside it.

enum Look { DEFAULT, SECONDARY, MUTED, TINTED, OUTLINE, GHOST, DANGER }
enum Tail { NONE, START, END }

const _LOOKS := ["Default", "Secondary", "Muted", "Tinted", "Outline", "Ghost", "Danger"]
const _TAILS := ["", "Start", "End"]

@export_multiline var text := "":
	set(v):
		text = v
		_refresh()
@export var look: Look = Look.SECONDARY:
	set(v):
		look = v
		_refresh()
@export var tail: Tail = Tail.START:
	set(v):
		tail = v
		_refresh()
@export_range(80, 1200) var max_width := 360:
	set(v):
		max_width = v
		_refresh()

var _refreshing := false


func _ready() -> void:
	for slot in [%Reactions, %Content]:
		slot.child_entered_tree.connect(func(_n): _refresh.call_deferred())
		slot.child_exiting_tree.connect(func(_n): _refresh.call_deferred())
	_refresh()


func _notification(what: int) -> void:
	if what == NOTIFICATION_THEME_CHANGED:
		_refresh.call_deferred()


## Subclass hook, before each restyle.
func _wold_refresh() -> void:
	pass


func style_name() -> StringName:
	return StringName("Bubble" + _LOOKS[look] + _TAILS[tail])


func _refresh() -> void:
	if _refreshing or not is_node_ready():
		return
	_refreshing = true
	_wold_refresh()
	var panel := %Panel as PanelContainer
	panel.theme_type_variation = style_name()
	var label := %Text as Label
	label.text = text
	label.visible = text != ""
	label.add_theme_color_override(&"font_color", panel.get_theme_color(&"text"))
	# as wide as the text, up to max_width; then it wraps
	var inner := float(max_width) - panel.get_theme_stylebox(&"panel").get_minimum_size().x
	var font := label.get_theme_font(&"font")
	var px := label.get_theme_font_size(&"font_size")
	var w := font.get_multiline_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, px).x if text != "" else 0.0
	label.custom_minimum_size.x = ceilf(minf(w, inner))
	# the bubble hugs its own side of the row
	var side := SIZE_SHRINK_END if tail == Tail.END else SIZE_SHRINK_BEGIN
	panel.size_flags_horizontal = side
	%Content.visible = %Content.get_children().any(func(c): return not c.is_queued_for_deletion())
	var reactions := %Reactions as Control
	reactions.size_flags_horizontal = side
	reactions.visible = reactions.get_children().any(func(c): return not c.is_queued_for_deletion())
	_refreshing = false
