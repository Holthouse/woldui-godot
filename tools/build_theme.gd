extends SceneTree
## Headless theme build:
##   godot --headless --path <game> -s res://addons/woldui/tools/build_theme.gd
## reads woldui/tokens, writes to WoldThemeBuilder.output_path (in place if it exists).
## prints BUILT <path> or ERROR ..., exit 0/1


func _initialize() -> void:
	var tokens_path: String = ProjectSettings.get_setting("woldui/tokens", "res://addons/woldui/tokens/default_dark.tres")
	var t := load(tokens_path) as WoldTokens
	if t == null:
		print("ERROR no WoldTokens at ", tokens_path)
		quit(1)
		return
	var built := WoldThemeBuilder.build(t)
	var out := WoldThemeBuilder.output_path(tokens_path)
	var target: Theme = built
	if ResourceLoader.exists(out):
		var existing := load(out) as Theme
		if existing:
			WoldThemeBuilder.update_in_place(existing, built)
			target = existing
	var err := ResourceSaver.save(target, out)
	if err != OK:
		print("ERROR could not save ", out, " (", err, ")")
		quit(1)
		return
	print("BUILT ", out)
	quit(0)
