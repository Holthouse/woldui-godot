@tool
class_name WoldMessage
extends HBoxContainer
## One line of chat: avatar, name and time, and a WoldBubble. `mine` flips it
## to the other side, like your own messages in a chat app. Turn off
## `show_header` for a follow-up line from the same person.

@export var author := "Queen Mab":
	set(v):
		author = v
		_refresh()
@export_multiline var text := "":
	set(v):
		text = v
		_refresh()
## "12:04", "Turn 42". Empty = none.
@export var time := "":
	set(v):
		time = v
		_refresh()
@export var mine := false:
	set(v):
		mine = v
		_refresh()
@export var look: WoldBubble.Look = WoldBubble.Look.SECONDARY:
	set(v):
		look = v
		_refresh()
@export var avatar_texture: Texture2D:
	set(v):
		avatar_texture = v
		_refresh()
@export var show_avatar := true:
	set(v):
		show_avatar = v
		_refresh()
## Name and time above the bubble. Off for a follow-up line.
@export var show_header := true:
	set(v):
		show_header = v
		_refresh()

var _refreshing := false


func _ready() -> void:
	_refresh()


## Subclass hook, before each restyle.
func _wold_refresh() -> void:
	pass


func bubble() -> WoldBubble:
	return %Bubble


func _refresh() -> void:
	if _refreshing or not is_node_ready():
		return
	_refreshing = true
	_wold_refresh()
	var avatar := %Avatar as WoldAvatar
	avatar.display_name = author
	avatar.texture = avatar_texture
	# a follow-up keeps the gap where the avatar was, so bubbles line up
	avatar.modulate.a = 1.0 if show_avatar and show_header else 0.0
	avatar.visible = show_avatar
	var b := %Bubble as WoldBubble
	b.text = text
	b.look = look
	b.tail = WoldBubble.Tail.END if mine else WoldBubble.Tail.START
	(%Name as Label).text = author
	(%Time as Label).text = time
	%Time.visible = time != ""
	%Header.visible = show_header
	(%Header as BoxContainer).alignment = BoxContainer.ALIGNMENT_END if mine else BoxContainer.ALIGNMENT_BEGIN
	# own messages: avatar on the right
	move_child(avatar, get_child_count() - 1 if mine else 0)
	alignment = BoxContainer.ALIGNMENT_END if mine else BoxContainer.ALIGNMENT_BEGIN
	_refreshing = false
