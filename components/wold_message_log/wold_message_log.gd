@tool
class_name WoldMessageLog
extends Control
## A chat or event log that keeps up: new lines slide in, and it sticks to
## the bottom while you're reading there. Scroll up to read back and it stays
## put, showing a "N new" button that takes you back down.
##   log.say("Queen Mab", "Trade you 20 wood for 10 gold?")
##   log.say("You", "Deal.", true)
##   log.add(any_control)
## Lines from the same speaker in a row share one header.

## Oldest lines drop off past this. 0 = keep everything.
@export_range(0, 5000) var max_items := 200

const MESSAGE := "res://addons/woldui/components/wold_message/wold_message.tscn"

var unread := 0
var _last_author := ""
var _last_mine := false


func _ready() -> void:
	%Jump.pressed.connect(func(): scroll_to_end())
	(%Scroll as ScrollContainer).get_v_scroll_bar().value_changed.connect(func(_v):
		if is_at_bottom():
			_set_unread(0))
	_set_unread(0)


## The lines, oldest first.
func items() -> Array[Control]:
	var out: Array[Control] = []
	for child in %List.get_children():
		if child is Control and not child.is_queued_for_deletion():
			out.append(child)
	return out


## A chat line. Same speaker as the last line (and same side): no repeat
## header or avatar.
func say(author: String, text: String, mine := false, look := WoldBubble.Look.SECONDARY, time := "") -> WoldMessage:
	var m: WoldMessage = load(MESSAGE).instantiate()
	m.author = author
	m.text = text
	m.mine = mine
	m.look = WoldBubble.Look.DEFAULT if mine and look == WoldBubble.Look.SECONDARY else look
	m.time = time
	var follow_up := not items().is_empty() and author == _last_author and mine == _last_mine
	m.show_header = not follow_up
	_last_author = author
	_last_mine = mine
	add(m)
	return m


## Any Control as a line: a system notice, a separator, a card.
func add(line: Control) -> void:
	var stick := is_at_bottom()
	if not line is WoldMessage:
		_last_author = ""
	%List.add_child(line)
	_trim()
	if is_inside_tree() and not Engine.is_editor_hint():
		WoldMotion.appear(line, WoldMotion.preset("item"))
	if stick:
		scroll_to_end.call_deferred(false)
	else:
		_set_unread(unread + 1)


func clear() -> void:
	for child in %List.get_children():
		%List.remove_child(child)
		child.queue_free()
	_last_author = ""
	_set_unread(0)


## Within a few pixels of the end (or nothing to scroll).
func is_at_bottom() -> bool:
	var bar := (%Scroll as ScrollContainer).get_v_scroll_bar()
	return bar.value + bar.page >= bar.max_value - 4.0


func scroll_to_end(animated := true) -> void:
	var scroll := %Scroll as ScrollContainer
	# the list sorts at the end of the frame; wait for the real height
	await get_tree().process_frame
	var bar := scroll.get_v_scroll_bar()
	var target := bar.max_value - bar.page
	if animated and not WoldMotion.reduced():
		var t := WoldUIRuntime.instance().tokens
		WoldMotion.tween_number(scroll, bar.value, target, func(v: float): scroll.scroll_vertical = int(v), t.duration_base)
	else:
		scroll.scroll_vertical = int(target)
	_set_unread(0)


func _trim() -> void:
	if max_items <= 0:
		return
	var list := items()
	for i in maxi(list.size() - max_items, 0):
		%List.remove_child(list[i])
		list[i].queue_free()


func _set_unread(n: int) -> void:
	unread = n
	var jump := %Jump as WoldButton
	jump.text = "%d new" % n if n > 1 else "1 new"
	jump.visible = n > 0
