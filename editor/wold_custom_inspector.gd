@tool
extends EditorInspectorPlugin
## Puts "Customize" at the top of every Control's Inspector: a WoldCustom
## for just that control, kept in its wold_custom metadata. The plugin
## re-applies it whenever it changes.

const PROPERTY := "metadata/wold_custom"


func _can_handle(object: Object) -> bool:
	return object is Control


func _parse_begin(object: Object) -> void:
	var note := Label.new()
	note.text = "WoldUI: change just this control"
	note.tooltip_text = "New WoldCustom, then pick a fill, text colour, corners, padding or font.\nEverything left at its default keeps the design system's value."
	note.add_theme_color_override("font_color", EditorInterface.get_editor_theme().get_color("font_placeholder_color", "Editor"))
	add_custom_control(note)
	var editor := EditorInspector.instantiate_property_editor(object, TYPE_OBJECT, PROPERTY, PROPERTY_HINT_RESOURCE_TYPE, "WoldCustom", PROPERTY_USAGE_DEFAULT, true)
	if editor:
		add_property_editor(PROPERTY, editor, false, "Customize")
