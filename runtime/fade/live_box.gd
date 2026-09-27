@tool
extends StyleBox
## The box a fade paints through. Changing `flat` doesn't emit `changed`, so
## the control doesn't get THEME_CHANGED sixty times a second; whoever changes
## it calls queue_redraw on the control instead.
# (a mutated StyleBoxFlat override would re-theme the control every frame, and
# half the components restyle on THEME_CHANGED)

var flat := StyleBoxFlat.new()


func _draw(to_canvas_item: RID, rect: Rect2) -> void:
	flat.draw(to_canvas_item, rect)


func _get_draw_rect(rect: Rect2) -> Rect2:
	return rect.grow_individual(flat.expand_margin_left, flat.expand_margin_top, flat.expand_margin_right, flat.expand_margin_bottom)


## Content margins do change layout, so these go through the normal path, and
## only when they actually move.
func sync_margins() -> void:
	for side in 4:
		if get_content_margin(side) != flat.get_content_margin(side):
			set_content_margin(side, flat.get_content_margin(side))
