@tool
class_name WoldAvatarGroup
extends HBoxContainer
## Overlapping avatars for a lobby or a party, from `names` (and optional
## `textures`, same order). Past `max_visible` the rest fold into a "+N".

@export var names: PackedStringArray = ["Queen Mab", "Old Tom", "Ivy"]:
	set(v):
		names = v
		_rebuild()
@export var textures: Array[Texture2D] = []:
	set(v):
		textures = v
		_rebuild()
## 0 = show them all.
@export_range(0, 50) var max_visible := 4:
	set(v):
		max_visible = v
		_rebuild()
@export var avatar_size: WoldAvatar.Size = WoldAvatar.Size.MD:
	set(v):
		avatar_size = v
		_rebuild()

# a path, not preload: WoldAvatar refers back to this class, and preloading its
# scene while it compiles is a cycle
const AVATAR := "res://addons/woldui/components/wold_avatar/wold_avatar.tscn"


func _ready() -> void:
	_rebuild()


## Avatars on show, the "+N" one included.
func avatars() -> Array[WoldAvatar]:
	var out: Array[WoldAvatar] = []
	for child in get_children():
		if child is WoldAvatar and not child.is_queued_for_deletion():
			out.append(child)
	return out


## How many folded into the "+N". 0 = none.
func hidden_count() -> int:
	return maxi(names.size() - max_visible, 0) if max_visible > 0 else 0


# generated and unowned, so none of it is saved
func _rebuild() -> void:
	if not is_node_ready():
		return
	theme_type_variation = StringName("AvatarGroup" + ["Sm", "", "Lg"][avatar_size])
	for child in get_children():
		if child is WoldAvatar and child.owner == null:
			remove_child(child)
			child.queue_free()
	var extra := hidden_count()
	var shown := names.size() - extra
	for i in shown:
		var a: WoldAvatar = load(AVATAR).instantiate()
		a.display_name = names[i]
		a.texture = textures[i] if i < textures.size() else null
		a.avatar_size = avatar_size
		add_child(a)
	if extra > 0:
		var more: WoldAvatar = load(AVATAR).instantiate()
		more.avatar_size = avatar_size
		more.initials = "+%d" % extra
		more.display_name = ", ".join(names.slice(shown))
		add_child(more)


func _validate_property(property: Dictionary) -> void:
	if property.name == "theme_type_variation":
		property.usage &= ~PROPERTY_USAGE_STORAGE
