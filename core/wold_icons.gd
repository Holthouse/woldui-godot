@tool
class_name WoldIcons
## Bundled Lucide icons (ISC licence), rendered from SVG at any size, drawn
## white so they tint. You usually want tokens.icon() instead.
# regenerate lucide.json with tools/build_lucide.mjs

const LIBRARY_PATH := "res://addons/woldui/icons/lucide.json"
const SVG := '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="#ffffff" stroke-width="%s" stroke-linecap="round" stroke-linejoin="round">%s</svg>'

static var _library: Dictionary = {}
# TODO: never cleared. Fine for a normal UI, but lots of sizes/strokes pile up.
static var _cache: Dictionary = {}


static func library() -> Dictionary:
	if _library.is_empty():
		var json := load(LIBRARY_PATH) as JSON
		assert(json != null, "WoldIcons: %s is missing; run tools/build_lucide.mjs" % LIBRARY_PATH)
		if json:
			_library = json.data
	return _library


static func version() -> String:
	return library().get("version", "")


static func has(icon_name: String) -> bool:
	return library().get("icons", {}).has(icon_name)


static func names() -> PackedStringArray:
	var out := PackedStringArray(library().get("icons", {}).keys())
	out.sort()
	return out


## Every word must match: "shield check" finds shield-check.
static func search(query: String, limit := 200) -> PackedStringArray:
	var words := query.to_lower().strip_edges().split(" ", false)
	var out := PackedStringArray()
	for n in names():
		var ok := true
		for w in words:
			if not n.contains(w):
				ok = false
				break
		if ok:
			out.append(n)
			if out.size() >= limit:
				break
	return out


## `size` px square, stroke scales with it. Cached per name/size/stroke.
static func texture(icon_name: String, size := 24, stroke := 2.0) -> Texture2D:
	var key := "%s@%d@%.2f" % [icon_name, size, stroke]
	if _cache.has(key):
		return _cache[key]
	var icons: Dictionary = library().get("icons", {})
	if not icons.has(icon_name):
		push_error("WoldIcons: no icon named '%s' (browse them in the WoldUI dock)" % icon_name)
		return null
	var svg := SVG % [str(stroke), icons[icon_name]]
	var tex := DPITexture.create_from_string(svg, size / 24.0)
	_cache[key] = tex
	return tex
