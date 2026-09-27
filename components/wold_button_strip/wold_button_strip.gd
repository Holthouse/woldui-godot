@tool
class_name WoldButtonStrip
extends BoxContainer
## Joins the buttons under it into one strip: only the outer corners stay
## round and the borders overlap into single seams. Any Button works,
## WoldButtons included. `vertical` stacks them. (Not a ButtonGroup: that one
## makes toggles exclusive, this is only looks.)
# The joined corners are stylebox overrides on the children. Overrides get
# saved with a scene, so they come off right before an editor save and go
# back on after. Nothing else is put on the children (meta would be saved too).

const STATES: PackedStringArray = ["normal", "hover", "pressed", "hover_pressed", "disabled", "focus"]

# child -> what its overrides were built from; a child in here is joined
var _joined := {}
var _joining := false


func _ready() -> void:
	theme_type_variation = &"ButtonStrip"
	child_entered_tree.connect(_on_child_entered)
	child_exiting_tree.connect(_on_child_exiting)
	for child in get_children():
		_on_child_entered(child)


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_SORT_CHILDREN:
			_join.call_deferred()
		NOTIFICATION_EDITOR_PRE_SAVE:
			for b in _joined.keys():
				_unjoin(b)
		NOTIFICATION_EDITOR_POST_SAVE:
			_join()


## The buttons being joined, in order.
func buttons() -> Array[BaseButton]:
	var out: Array[BaseButton] = []
	for child in get_children():
		if child is BaseButton and child.visible and not child.is_queued_for_deletion():
			out.append(child)
	return out


## Which corners a button keeps: [top_left, top_right, bottom_right, bottom_left].
func corners_for(index: int, count: int) -> Array[bool]:
	var first := index == 0
	var last := index == count - 1
	if vertical:
		return [first, first, last, last]
	return [first, last, last, first]


func is_joined(b: BaseButton) -> bool:
	return _joined.has(b)


func _on_child_entered(child: Node) -> void:
	if child is Control and not child.visibility_changed.is_connected(_on_child_visibility):
		child.theme_changed.connect(_on_child_theme.bind(child))
		child.visibility_changed.connect(_on_child_visibility)
	_join.call_deferred()


func _on_child_exiting(child: Node) -> void:
	if child is Control:
		for c in child.theme_changed.get_connections():
			if c.callable.get_object() == self:
				child.theme_changed.disconnect(c.callable)
		if child.visibility_changed.is_connected(_on_child_visibility):
			child.visibility_changed.disconnect(_on_child_visibility)
	if child is BaseButton:
		_unjoin(child)
	_join.call_deferred()


func _on_child_visibility() -> void:
	_join.call_deferred()


# not ours: the theme above changed (new tokens, a scope), so the copies are
# stale even though nothing in the key moved
func _on_child_theme(child: Control) -> void:
	if _joining:
		return
	if _joined.has(child):
		_joined[child] = []
	_join.call_deferred()


func _join() -> void:
	if _joining or not is_inside_tree():
		return
	_joining = true
	var list := buttons()
	for b in _joined.keys():
		if not is_instance_valid(b) or not list.has(b):
			_unjoin(b)
	for i in list.size():
		var b := list[i]
		var keep := corners_for(i, list.size())
		# a customised button (WoldCustom) keeps its own shape; the strip's
		# overrides would fight it, and get stripped with it at every save
		if b.has_meta(&"wold_custom"):
			if _joined.has(b):
				_unjoin(b)
				WoldCustomize.apply(b)
			continue
		# skip when nothing changed, so a re-sort doesn't restyle (and re-sort)
		var fade: Object = b.get_meta(&"_wold_fade") if b.has_meta(&"_wold_fade") else null
		var key := [keep, b.theme_type_variation, b.theme, fade != null]
		if _joined.get(b, []) == key:
			continue
		_unjoin(b)
		if fade:
			# WoldFeedback is crossfading this one, it squares its own corners
			fade.set_corners(keep)
			_joined[b] = key
			continue
		for state in STATES:
			var src := b.get_theme_stylebox(state)
			if not src is StyleBoxFlat:
				continue
			var sb := src.duplicate() as StyleBoxFlat
			if not keep[0]:
				sb.corner_radius_top_left = 0
			if not keep[1]:
				sb.corner_radius_top_right = 0
			if not keep[2]:
				sb.corner_radius_bottom_right = 0
			if not keep[3]:
				sb.corner_radius_bottom_left = 0
			b.add_theme_stylebox_override(state, sb)
		_joined[b] = key
	_joining = false


func _unjoin(b: Control) -> void:
	if not _joined.has(b):
		return
	_joined.erase(b)
	if not is_instance_valid(b):
		return
	var was := _joining
	_joining = true
	if b.has_meta(&"_wold_fade"):
		var all: Array[bool] = [true, true, true, true]
		b.get_meta(&"_wold_fade").set_corners(all)
	else:
		for state in STATES:
			b.remove_theme_stylebox_override(state)
	_joining = was
