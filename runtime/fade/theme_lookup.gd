extends RefCounted
## What the theme says for a node, looking past its overrides. The fades put
## their own overrides on a control and still need the real values under them.
# Same order the engine uses: the node's theme and its ancestors' (up through
# Controls and Windows only, anything else breaks the chain), then the project
# theme, then the default. In each theme the variation chain comes before the
# class chain. `own` holds overrides the node had before we took over.


static func stylebox(node: Node, item: StringName, own := {}) -> StyleBox:
	if own.has(item):
		return own[item]
	return _find(node, Theme.DATA_TYPE_STYLEBOX, item)


static func color(node: Node, item: StringName, own := {}) -> Color:
	if own.has(item):
		return own[item]
	var c: Variant = _find(node, Theme.DATA_TYPE_COLOR, item)
	return c if c != null else Color(0, 0, 0, 1)


## The node's current overrides for `items`, to pass back in as `own`.
static func overrides(node: Node, boxes: Array, colors: Array) -> Dictionary:
	var out := {}
	for item in boxes:
		if node.has_theme_stylebox_override(item):
			out[StringName(item)] = node.get_theme_stylebox(item)
	for item in colors:
		if node.has_theme_color_override(item):
			out[StringName(item)] = node.get_theme_color(item)
	return out


static func _find(node: Node, kind: Theme.DataType, item: StringName) -> Variant:
	var themes := _themes(node)
	var types := _types(node, themes)
	for th in themes:
		for type in types:
			if th.has_theme_item(kind, item, type):
				return th.get_theme_item(kind, item, type)
	return null


static func _themes(node: Node) -> Array[Theme]:
	var out: Array[Theme] = []
	var n := node
	while n is Control or n is Window:
		var th: Theme = n.theme
		if th:
			out.append(th)
		n = n.get_parent()
	var project := ThemeDB.get_project_theme()
	if project:
		out.append(project)
	out.append(ThemeDB.get_default_theme())
	return out


static func _types(node: Node, themes: Array[Theme]) -> Array[StringName]:
	var out: Array[StringName] = []
	var variation: StringName = node.theme_type_variation
	if variation != &"":
		out.append(variation)
		# the first theme that knows the variation says what it's based on
		for th in themes:
			if th.get_type_variation_base(variation) != &"":
				var base := th.get_type_variation_base(variation)
				while base != &"" and not out.has(base):
					out.append(base)
					base = th.get_type_variation_base(base)
				break
	var cls := StringName(node.get_class())
	while cls != &"":
		out.append(cls)
		cls = ClassDB.get_parent_class(cls)
	return out
