@tool
extends EditorPlugin
## Adds the dock and rebuilds the theme when tokens (or variants, icon sets...)
## change in the Inspector.
##
## `woldui/tokens` points at the tokens file. The generated theme sits next to
## it; point gui/theme/custom at that.

const SETTING_TOKENS := "woldui/tokens"
const SETTING_AUTO := "woldui/rebuild_on_edit"
const DEFAULT_TOKENS := "res://addons/woldui/tokens/default_dark.tres"
const GALLERY := "res://addons/woldui/gallery/gallery.tscn"
const RUNTIME := "res://addons/woldui/runtime/wold_ui_runtime.gd"
const WATCHED := [&"WoldTokens", &"WoldVariant", &"WoldIconSet", &"WoldSoundSet", &"WoldMotionPreset"]

var dock: Control
var _rebuild_queued := false
var _custom_inspector: EditorInspectorPlugin
# WoldCustom -> the node it belongs to, so edits land on the right control
var _customs := {}


func _enter_tree() -> void:
	_ensure_setting(SETTING_TOKENS, DEFAULT_TOKENS, TYPE_STRING, PROPERTY_HINT_FILE, "*.tres")
	_ensure_setting(SETTING_AUTO, true, TYPE_BOOL)
	dock = preload("editor/wold_dock.gd").new()
	dock.plugin = self
	dock.name = "WoldUI"
	add_control_to_dock(DOCK_SLOT_RIGHT_UL, dock)
	EditorInterface.get_inspector().property_edited.connect(_on_property_edited)
	_custom_inspector = preload("editor/wold_custom_inspector.gd").new()
	add_inspector_plugin(_custom_inspector)
	EditorInterface.get_inspector().edited_object_changed.connect(_watch_edited)
	scene_changed.connect(_on_scene_changed)


func _enable_plugin() -> void:
	add_autoload_singleton("WoldUI", RUNTIME)


func _disable_plugin() -> void:
	remove_autoload_singleton("WoldUI")


func _exit_tree() -> void:
	var inspector := EditorInterface.get_inspector()
	if _custom_inspector:
		remove_inspector_plugin(_custom_inspector)
	if inspector.edited_object_changed.is_connected(_watch_edited):
		inspector.edited_object_changed.disconnect(_watch_edited)
	if inspector.property_edited.is_connected(_on_property_edited):
		inspector.property_edited.disconnect(_on_property_edited)
	if dock:
		remove_control_from_docks(dock)
		dock.queue_free()


func tokens_path() -> String:
	return ProjectSettings.get_setting(SETTING_TOKENS, DEFAULT_TOKENS)


func set_tokens_path(path: String) -> void:
	ProjectSettings.set_setting(SETTING_TOKENS, path)
	ProjectSettings.save()
	rebuild()


func tokens() -> WoldTokens:
	var path := tokens_path()
	if not ResourceLoader.exists(path):
		return null
	return load(path) as WoldTokens


func theme_path() -> String:
	return WoldThemeBuilder.output_path(tokens_path())


func is_project_theme() -> bool:
	return ProjectSettings.get_setting("gui/theme/custom", "") == theme_path()


## Returns an error message, or "" if it worked.
# writes into the existing Theme instead of replacing it, otherwise open scenes
# keep the old one until reloaded
func rebuild() -> String:
	var t := tokens()
	if t == null:
		return "No WoldTokens at %s" % tokens_path()
	var built := WoldThemeBuilder.build(t)
	var out := theme_path()
	var target: Theme = built
	if ResourceLoader.exists(out):
		var existing := load(out) as Theme
		if existing:
			WoldThemeBuilder.update_in_place(existing, built)
			target = existing
	var err := ResourceSaver.save(target, out)
	# customised controls are worked out from the theme, so they follow it
	var edited := EditorInterface.get_edited_scene_root()
	if edited:
		WoldCustomize.apply_tree(edited)
	if dock:
		dock.refresh()
	return "" if err == OK else "Could not save %s (error %d)" % [out, err]


func use_as_project_theme() -> String:
	var err := rebuild()
	if err != "":
		return err
	ProjectSettings.set_setting("gui/theme/custom", theme_path())
	ProjectSettings.save()
	return ""


func open_gallery() -> void:
	EditorInterface.open_scene_from_path(GALLERY)


func _on_property_edited(property: String) -> void:
	if property == "metadata/wold_custom":
		_watch_edited()
		var node := EditorInterface.get_inspector().get_edited_object() as Control
		if node:
			WoldCustomize.apply(node)
		return
	if not ProjectSettings.get_setting(SETTING_AUTO, true):
		return
	var edited := EditorInterface.get_inspector().get_edited_object()
	if edited == null or edited.get_script() == null:
		return
	if not WATCHED.has(edited.get_script().get_global_name()):
		return
	# colour picker drags fire this constantly, debounce
	if _rebuild_queued:
		return
	_rebuild_queued = true
	await get_tree().create_timer(0.2).timeout
	_rebuild_queued = false
	rebuild()


func _ensure_setting(setting: String, value: Variant, type: int, hint := PROPERTY_HINT_NONE, hint_string := "") -> void:
	if not ProjectSettings.has_setting(setting):
		ProjectSettings.set_setting(setting, value)
	ProjectSettings.set_initial_value(setting, value)
	ProjectSettings.add_property_info({name = setting, type = type, hint = hint, hint_string = hint_string})
	ProjectSettings.set_as_basic(setting, true)


# follow the WoldCustom of whatever Control is in the Inspector
func _watch_edited() -> void:
	var node := EditorInterface.get_inspector().get_edited_object() as Control
	if node:
		_watch(node)


func _watch(node: Control) -> void:
	var c := WoldCustomize.custom_of(node)
	if c == null:
		return
	# Ctrl+D shares the resource between the copies; give this one its own
	if _customs.has(c) and is_instance_valid(_customs[c]) and _customs[c] != node:
		c = c.duplicate()
		node.set_meta(WoldCustomize.META, c)
	_customs[c] = node
	if not c.changed.is_connected(_on_custom_changed):
		c.changed.connect(_on_custom_changed.bind(c))


func _on_custom_changed(c: WoldCustom) -> void:
	var node: Control = _customs.get(c)
	if not is_instance_valid(node):
		_customs.erase(c)
		return
	WoldCustomize.apply(node)
	EditorInterface.mark_scene_as_unsaved()


# an opened scene gets its customised controls applied against the current
# tokens (they may have changed since it was saved)
func _on_scene_changed(root: Node) -> void:
	if root == null:
		return
	WoldCustomize.apply_tree(root)
	for node in root.find_children("*", "Control", true, false) + [root]:
		if node is Control and node.has_meta(WoldCustomize.META):
			_watch(node)
