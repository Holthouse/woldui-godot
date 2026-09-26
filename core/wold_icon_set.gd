@tool
class_name WoldIconSet
extends Resource
## Your game's own icons by name, layered over the bundled Lucide set.
##
## Lookup: `icons`, then `fallback`, then Lucide (if `use_library`). So you only
## list what you add or replace, every other Lucide name keeps working.
##
## Import SVGs as DPITexture or they go blurry when scaled. White art tints like
## text; for full-colour art set tokens.icon_tint = ORIGINAL.

@export var icons: Dictionary[String, Texture2D] = {}
@export var fallback: WoldIconSet
## Fall back to Lucide for names not in this set.
@export var use_library := true


func has_icon(icon_name: String) -> bool:
	if icons.has(icon_name):
		return true
	if fallback and fallback.has_icon(icon_name):
		return true
	return use_library and WoldIcons.has(icon_name)


## `size`/`stroke` only affect library icons, your own textures come back as-is.
# unknown names push_error on purpose - a silent blank icon is worse
func get_icon(icon_name: String, size := 24, stroke := 2.0) -> Texture2D:
	if icons.has(icon_name):
		return icons[icon_name]
	if fallback and fallback.has_icon(icon_name):
		return fallback.get_icon(icon_name, size, stroke)
	if use_library and WoldIcons.has(icon_name):
		return WoldIcons.texture(icon_name, size, stroke)
	push_error("WoldIconSet: no icon named '%s'" % icon_name)
	return null


## Own + fallback names, without the library.
func custom_names() -> PackedStringArray:
	var out := PackedStringArray(icons.keys())
	if fallback:
		for n in fallback.custom_names():
			if not out.has(n):
				out.append(n)
	out.sort()
	return out
