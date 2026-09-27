extends RefCounted
## PopupPanel fades in when it shows. That covers the engine's own tooltips
## (tooltip_text): a PopupPanel with a Panel and a Label, shown with show()
## rather than popup(), so there's no about_to_popup to hang it on.

var popup: PopupPanel


func _init(p: PopupPanel) -> void:
	popup = p
	p.visibility_changed.connect(_on_visibility)


func _on_visibility() -> void:
	if not popup.visible:
		return
	# the panel draws the box, the content is a sibling of it; both have to go
	for child in popup.get_children(true):
		if child is Control:
			WoldMotion.appear(child, WoldMotion.preset("tooltip_in"))
