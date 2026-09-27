extends RefCounted
## Internal. A rect that slides from where it is to a new target, drawn by
## its owner: WoldSegmented's thumb, WoldTabs' pill.

var from := Rect2()
var to := Rect2()
var t := 1.0

var _owner: CanvasItem
# tweens go on a node of their own, so they don't cancel the owner's motion
var _anim: Node


func _init(owner: CanvasItem, anim: Node) -> void:
	_owner = owner
	_anim = anim


## Where it is right now, in the owner's space.
func rect() -> Rect2:
	if t >= 1.0:
		return to
	return Rect2(from.position.lerp(to.position, t), from.size.lerp(to.size, t))


func is_placed() -> bool:
	return to != Rect2()


## Jumps the first time, or when not animated; slides otherwise.
func move(target: Rect2, animate: bool) -> void:
	if not animate or to == Rect2() or not _owner.is_inside_tree() or Engine.is_editor_hint():
		to = target
		t = 1.0
		_owner.queue_redraw()
		return
	if target == to:
		return
	from = rect()
	to = target
	t = 0.0
	WoldMotion.tween_number(_anim, 0.0, 1.0, func(v: float):
		t = v
		_owner.queue_redraw(), WoldMotion.tokens().duration_base)


## The target moved with the layout: follow it without restarting a slide.
func retarget(target: Rect2) -> void:
	if target == to:
		return
	to = target
	_owner.queue_redraw()
