@tool
class_name WoldFill
extends Resource
## Textured fill for WoldMeter / WoldSlider.
##
## TILE: repeats at a fixed pixel scale, more value = more tiles. Stripes, pips.
## REVEAL: one image across the whole track, the value uncovers it. Resizing
## the control refits it, changing the value doesn't.
## STRETCH: just squashed into the filled part.
##
## Clipping to the rounded track is the component's job, not this one's.

enum Mode { TILE, REVEAL, STRETCH }

@export var texture: Texture2D
@export var mode: Mode = Mode.TILE
## Multiplied in. White = the texture's own colours.
@export var tint := Color.WHITE
## TILE only. Screen px per texel.
@export_range(0.25, 8.0, 0.05) var tile_scale := 1.0


## The draw as data {dest, src, tile, scale}, so tests can check it headless.
## `src` only matters when not tiling.
func plan(track: Rect2, filled: Rect2) -> Dictionary:
	var tex_size := texture.get_size() if texture else Vector2.ONE
	match mode:
		Mode.TILE:
			return {dest = filled, src = Rect2(Vector2.ZERO, tex_size), tile = true, scale = tile_scale}
		Mode.REVEAL:
			var ratio := filled.size.x / track.size.x if track.size.x > 0.0 else 0.0
			return {dest = filled, src = Rect2(0, 0, tex_size.x * ratio, tex_size.y), tile = false,
				scale = track.size.x / tex_size.x}
	return {dest = filled, src = Rect2(Vector2.ZERO, tex_size), tile = false, scale = filled.size.x / tex_size.x}


func draw_into(ci: CanvasItem, track: Rect2, filled: Rect2) -> void:
	if texture == null or filled.size.x <= 0.0 or filled.size.y <= 0.0:
		return
	var p := plan(track, filled)
	var dest: Rect2 = p.dest
	if p.tile:
		var s: float = p.scale
		ci.draw_set_transform(dest.position, 0.0, Vector2(s, s))
		ci.draw_texture_rect(texture, Rect2(Vector2.ZERO, dest.size / s), true, tint)
		ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	else:
		ci.draw_texture_rect_region(texture, dest, p.src, tint)
