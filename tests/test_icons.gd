extends "res://addons/woldui/tests/wold_test_base.gd"
## Lucide + WoldIconSet: renders, size/stroke, game icons win, unknown names fail loud.


func _run() -> void:
	_library()
	_every_icon_renders()
	_sizes_and_cache()
	_icon_sets()
	_aliases()
	_tokens_icon()
	finish(27)


func _library() -> void:
	check(WoldIcons.names().size() >= 1500, "the library bundles the Lucide set (%d icons)" % WoldIcons.names().size())
	check(WoldIcons.version() != "", "the library records its Lucide version")
	check(WoldIcons.has("sword") and WoldIcons.has("coins") and WoldIcons.has("x"), "common names are there")
	check(not WoldIcons.has("definitely-not-an-icon"), "has() is false for a made-up name")
	var found := WoldIcons.search("shield check")
	check(found.has("shield-check"), "search matches every word (shield check -> shield-check)")
	check(WoldIcons.search("e", 5).size() == 5, "search honours its limit")
	check(FileAccess.file_exists("res://addons/woldui/icons/LICENSE-lucide.txt"), "Lucide's ISC licence ships with the icons")


## draw every icon once. a bad conversion (attr, unescaped quote) shows up empty or unparseable
func _every_icon_renders() -> void:
	var blank := PackedStringArray()
	for n in WoldIcons.names():
		var tex := WoldIcons.texture(n, 24)
		if tex == null or not _has_ink(tex.get_image()):
			blank.append(n)
	check(blank.is_empty(), "every library icon renders with visible strokes (blank: %s)" % ", ".join(blank.slice(0, 10)))


func _sizes_and_cache() -> void:
	var small := WoldIcons.texture("sword", 16)
	var big := WoldIcons.texture("sword", 48)
	check(small.get_size() == Vector2(16, 16), "an icon is exactly the size asked (16)")
	check(big.get_size() == Vector2(48, 48), "an icon is exactly the size asked (48)")
	var img := big.get_image()
	check(img.get_pixel(0, 0).a == 0.0, "the background is transparent")
	var ink := _ink_colour(img)
	check(ink.r > 0.95 and ink.g > 0.95 and ink.b > 0.95, "icons are white, so button icon colours tint them (got %s)" % ink)
	check(WoldIcons.texture("sword", 48) == big, "the same icon at the same size is cached")
	var thin := WoldIcons.texture("sword", 48, 1.0)
	check(thin != big and _ink_count(thin.get_image()) < _ink_count(img), "a thinner stroke draws less ink")


func _icon_sets() -> void:
	var own := ImageTexture.create_from_image(Image.create(8, 8, false, Image.FORMAT_RGBA8))
	var set := WoldIconSet.new()
	set.icons = {"sword": own, "food": own}
	check(set.get_icon("sword") == own, "a game's own icon replaces the library icon of the same name")
	check(set.get_icon("food") == own, "a game's own name works")
	check(set.get_icon("coins", 20) == WoldIcons.texture("coins", 20), "any other name falls through to the library")
	var outer := WoldIconSet.new()
	outer.fallback = set
	check(outer.get_icon("food") == own, "a set falls back to another set")
	check(outer.custom_names().has("food"), "custom_names includes the fallback's names")
	set.use_library = false
	check(not set.has_icon("coins"), "use_library off hides the library")
	check(set.get_icon("coins") == null, "and an unknown name returns null (with an error), never a random icon")


func _tokens_icon() -> void:
	var t := tokens()
	check(t.icon("coins", "Lg").get_size() == Vector2(t.icon_size_lg, t.icon_size_lg), "tokens.icon uses the token size for Lg")
	check(t.icon("coins", "Sm").get_size() == Vector2(t.icon_size_sm, t.icon_size_sm), "tokens.icon uses the token size for Sm")
	var own := ImageTexture.create_from_image(Image.create(8, 8, false, Image.FORMAT_RGBA8))
	var custom := t.derive({})
	custom.icon_set = WoldIconSet.new()
	custom.icon_set.icons = {"coins": own}
	check(custom.icon("coins") == own, "tokens.icon asks the game's icon set first")


func _has_ink(img: Image) -> bool:
	return _ink_count(img) > 0


func _ink_count(img: Image) -> int:
	var n := 0
	for y in img.get_height():
		for x in img.get_width():
			if img.get_pixel(x, y).a > 0.5:
				n += 1
	return n


func _ink_colour(img: Image) -> Color:
	for y in img.get_height():
		for x in img.get_width():
			var c := img.get_pixel(x, y)
			if c.a > 0.9:
				return c
	return Color.BLACK


# a game names its icons by meaning ("food") before it has art for them
func _aliases() -> void:
	var set := WoldIconSet.new()
	set.aliases = {"food": "wheat", "gold": "coins"}
	check(set.has_icon("food") and set.get_icon("food", 20) == WoldIcons.texture("wheat", 20), "an alias stands in for a library icon")
	var art := ImageTexture.create_from_image(Image.create(8, 8, false, Image.FORMAT_RGBA8))
	set.icons = {"food": art}
	check(set.get_icon("food") == art, "real art under the same name replaces the stand-in")
	check(set.custom_names().has("gold"), "aliases count as the game's own names")
