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


func _enter_tree() -> void:
	_ensure_setting(SETTING_TOKENS, DEFAULT_TOKENS, TYPE_STRING, PROPERTY_HINT_FILE, "*.tres")
	_ensure_setting(SETTING_AUTO, true, TYPE_BOOL)
	dock = preload("editor/wold_dock.gd").new()
	dock.plugin = self
	dock.name = "WoldUI"
	add_control_to_dock(DOCK_SLOT_RIGHT_UL, dock)
	EditorInterface.get_inspector().property_edited.connect(_on_property_edited)


func _enable_plugin() -> void:
	add_autoload_singleton("WoldUI", RUNTIME)


func _disable_plugin() -> void:
	remove_autoload_singleton("WoldUI")


func _exit_tree() -> void:
	var inspector := EditorInterface.get_inspector()
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


func _on_property_edited(_property: String) -> void:
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
