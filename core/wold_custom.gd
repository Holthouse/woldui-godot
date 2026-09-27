@tool
class_name WoldCustom
extends Resource
## Changes for one control only, on top of the design system: pick a colour,
## a corner radius, a font size... and just this control follows. Anything
## left at its default keeps the theme's value.
##
## Select any Control in the editor and use "Customize this control" at the
## top of the Inspector (it lives in the node's metadata as wold_custom).
## Hover and pressed shades are worked out from the fill you pick.

enum Sound { THEME, CLICK, CONFIRM, BACK, OPEN, CLOSE, NONE }
enum Press { THEME, NONE, CUSTOM }

@export_group("Colours")
## Background. Clear (the default) keeps the theme's; hover and pressed get
## a lighter / darker step of it.
@export var fill := Color(0, 0, 0, 0):
	set(v):
		fill = v
		emit_changed()
## Text and icons. Clear = the theme's.
@export var text := Color(0, 0, 0, 0):
	set(v):
		text = v
		emit_changed()
## Clear = the theme's.
@export var border := Color(0, 0, 0, 0):
	set(v):
		border = v
		emit_changed()

@export_group("Shape")
## -1 = the theme's.
@export_range(-1, 64) var corner_radius := -1:
	set(v):
		corner_radius = v
		emit_changed()
## -1 = the theme's.
@export_range(-1, 16) var border_width := -1:
	set(v):
		border_width = v
		emit_changed()
## Space inside, left/right and top/bottom. -1 = the theme's.
@export var padding := Vector2i(-1, -1):
	set(v):
		padding = v
		emit_changed()

@export_group("Text")
## Empty = the theme's.
@export var font: Font:
	set(v):
		font = v
		emit_changed()
## 0 = the theme's.
@export_range(0, 128) var font_size := 0:
	set(v):
		font_size = v
		emit_changed()

@export_group("Feedback")
## What WoldFeedback plays when it's pressed.
@export var sound: Sound = Sound.THEME:
	set(v):
		sound = v
		emit_changed()
## THEME = the tokens' press effect, CUSTOM = the one below.
@export var press: Press = Press.THEME:
	set(v):
		press = v
		emit_changed()
@export var press_effect: WoldPressEffect:
	set(v):
		press_effect = v
		emit_changed()


func _init() -> void:
	# a duplicated node gets its own copy, not a shared one
	resource_local_to_scene = true


## True when nothing is set, so the control looks exactly like the theme.
func is_empty() -> bool:
	return fill.a == 0.0 and text.a == 0.0 and border.a == 0.0 and corner_radius < 0 \
		and border_width < 0 and padding.x < 0 and padding.y < 0 and font == null and font_size <= 0 \
		and sound == Sound.THEME and press == Press.THEME
