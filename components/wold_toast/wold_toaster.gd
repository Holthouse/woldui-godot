@tool
class_name WoldToaster
extends Control
## The column toasts stack in. You usually don't touch this: notify() spawns
## one on layer 90 the first time. Put wold_toaster.tscn in your scene if you
## want a different corner or layer.
# Each toast sits in its own slot Control so the gap can shrink smoothly when
# one leaves, instead of the rest snapping up.

enum Place { TOP_RIGHT, TOP_LEFT, BOTTOM_RIGHT, BOTTOM_LEFT, TOP_CENTER, BOTTOM_CENTER }

const SCENE := "res://addons/woldui/components/wold_toast/wold_toaster.tscn"
const GROUP := &"wold_toaster"

@export var place: Place = Place.TOP_RIGHT:
	set(v):
		place = v
		_place()
@export_range(200, 800) var toast_width := 360:
	set(v):
		toast_width = v
		_place()
## Oldest ones get dismissed past this.
@export_range(1, 10) var max_visible := 4


## First toaster in the tree, or a fresh one.
static func find_or_create(host: Node) -> WoldToaster:
	var tree := host.get_tree()
	for node in tree.get_nodes_in_group(GROUP):
		if node is WoldToaster and node.is_inside_tree():
			return node
	var layer := CanvasLayer.new()
	layer.layer = 90
	layer.name = "WoldToasts"
	tree.root.add_child(layer)
	var toaster: WoldToaster = load(SCENE).instantiate()
	layer.add_child(toaster)
	return toaster


func _ready() -> void:
	add_to_group(GROUP)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_place()


## Oldest first, leaving ones excluded.
func toasts() -> Array[WoldToast]:
	var out: Array[WoldToast] = []
	var list := %Stack.get_children()
	if _top():
		list.reverse()
	for slot in list:
		if slot.get_child_count() > 0 and slot.get_child(0) is WoldToast and not slot.get_child(0).is_leaving:
			out.append(slot.get_child(0))
	return out


## Newest goes nearest the screen edge.
func push(toast: WoldToast) -> void:
	var slot := Control.new()
	# no clip_contents here, it'd eat the drop shadow. collapse() turns it on.
	slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	%Stack.add_child(slot)
	if _top():
		%Stack.move_child(slot, 0)
	slot.add_child(toast)
	toast.set_anchors_preset(Control.PRESET_TOP_WIDE)
	var fit := func():
		if is_instance_valid(toast) and not toast.is_leaving:
			slot.custom_minimum_size.y = toast.get_combined_minimum_size().y
			toast.size = Vector2(slot.size.x, slot.custom_minimum_size.y)
	toast.minimum_size_changed.connect(fit)
	slot.resized.connect(fit)
	fit.call()
	toast.arrive()
	var live := toasts()
	while live.size() > max_visible:
		live.pop_front().dismiss()


## Shrinks the toast's slot to 0 and frees it. Called from WoldToast.dismiss().
func collapse(toast: WoldToast) -> void:
	var slot := toast.get_parent() as Control
	if WoldMotion.reduced() or slot == null:
		(slot if slot else toast).queue_free()
		return
	slot.clip_contents = true
	var t := WoldMotion.tokens()
	var tw := slot.create_tween()
	tw.tween_property(slot, "custom_minimum_size:y", 0.0, t.duration_fast).set_trans(t.move_transition).set_ease(t.move_ease)
	tw.tween_callback(slot.queue_free)


func _top() -> bool:
	return place in [Place.TOP_RIGHT, Place.TOP_LEFT, Place.TOP_CENTER]


func _place() -> void:
	if not is_node_ready():
		return
	var stack := %Stack as VBoxContainer
	var margin := float(WoldUIRuntime.instance().tokens.space_xl)
	var h: float = {Place.TOP_RIGHT: 1.0, Place.BOTTOM_RIGHT: 1.0, Place.TOP_LEFT: 0.0, Place.BOTTOM_LEFT: 0.0, Place.TOP_CENTER: 0.5, Place.BOTTOM_CENTER: 0.5}[place]
	var top := _top()
	stack.anchor_left = h
	stack.anchor_right = h
	stack.anchor_top = 0.0 if top else 1.0
	stack.anchor_bottom = stack.anchor_top
	var x := -toast_width * h + margin * (1.0 - 2.0 * h)
	stack.offset_left = x
	stack.offset_right = x + toast_width
	stack.offset_top = margin if top else -margin
	stack.offset_bottom = stack.offset_top
	stack.grow_vertical = Control.GROW_DIRECTION_END if top else Control.GROW_DIRECTION_BEGIN
	stack.alignment = BoxContainer.ALIGNMENT_BEGIN if top else BoxContainer.ALIGNMENT_END
