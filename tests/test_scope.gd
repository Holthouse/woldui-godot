extends "res://addons/woldui/tests/wold_test_base.gd"
## WoldScope: stays inside, nests, follows changes + token swaps, never saved.

const SCENE := "res://addons/woldui/components/wold_scope/wold_scope.tscn"

var ui: WoldUIRuntime
var stage: VBoxContainer


func _run() -> void:
	ui = WoldUIRuntime.instance()
	stage = VBoxContainer.new()
	stage.theme = WoldThemeBuilder.build(tokens())
	get_root().add_child(stage)
	await _inside_and_outside()
	await _nesting_and_changes()
	await _runtime_swap_and_saving()
	finish(12)


func _fill(b: Button) -> Color:
	return (b.get_theme_stylebox("normal") as StyleBoxFlat).bg_color


func _primary() -> Button:
	var b := Button.new()
	b.theme_type_variation = &"ButtonPrimary"
	return b


func _inside_and_outside() -> void:
	var red := Color("c0392b")
	var scope: WoldScope = load(SCENE).instantiate()
	scope.accent = red
	stage.add_child(scope)
	var inside := _primary()
	var holder := VBoxContainer.new()
	scope.add_child(holder)
	holder.add_child(inside)
	var outside := _primary()
	stage.add_child(outside)
	var badge: WoldBadge = load("res://addons/woldui/components/wold_badge/wold_badge.tscn").instantiate()
	badge.tone = WoldBadge.Tone.ACCENT
	badge.fill = WoldBadge.Fill.SOLID
	holder.add_child(badge)
	await process_frame
	check(_fill(inside) == red, "a button deep inside the scope takes its accent")
	check(_fill(outside) == tokens().accent, "a sibling outside keeps the game's accent")
	check((badge.get_theme_stylebox("panel") as StyleBoxFlat).bg_color == red, "components inside follow the scope too (a solid accent badge)")
	scope.queue_free()
	outside.queue_free()


func _nesting_and_changes() -> void:
	var outer: WoldScope = load(SCENE).instantiate()
	outer.accent = Color("c0392b")
	outer.token_overrides = {"radius_md": 0}
	stage.add_child(outer)
	var inner: WoldScope = load(SCENE).instantiate()
	inner.accent = Color("27ae60")
	outer.add_child(inner)
	var deep := _primary()
	inner.add_child(deep)
	await process_frame
	check(_fill(deep) == Color("27ae60"), "the nearest scope wins")
	check((deep.get_theme_stylebox("normal") as StyleBoxFlat).corner_radius_top_left == tokens().radius_md, "an inner scope starts from the game's tokens, not the outer scope's")
	var b := _primary()
	outer.remove_child(inner)
	inner.queue_free()
	outer.add_child(b)
	await process_frame
	check((b.get_theme_stylebox("normal") as StyleBoxFlat).corner_radius_top_left == 0, "token_overrides reach any token (radius_md 0)")
	outer.accent = Color("8e44ad")
	check(_fill(b) == Color("8e44ad"), "changing a prop rebuilds the scope")
	outer.accent = Color(0, 0, 0, 0)
	outer.token_overrides = {}
	check(outer.theme == null and _fill(b) == tokens().accent, "no overrides: the scope steps aside")
	outer.queue_free()


func _runtime_swap_and_saving() -> void:
	var scope: WoldScope = load(SCENE).instantiate()
	scope.token_overrides = {"radius_md": 0}
	stage.add_child(scope)
	var b := _primary()
	scope.add_child(b)
	await process_frame
	var before := ui.tokens
	var swapped := tokens().derive({"accent": Color("2980b9")})
	ui.tokens = swapped
	ui.tokens_changed.emit()
	check(_fill(b) == Color("2980b9"), "a runtime token swap reaches inside scopes (their overrides stay)")
	check((b.get_theme_stylebox("normal") as StyleBoxFlat).corner_radius_top_left == 0, "and the scope's own override still applies")
	ui.tokens = before
	ui.tokens_changed.emit()
	var host := Control.new()
	stage.add_child(host)
	var saved_scope: WoldScope = load(SCENE).instantiate()
	saved_scope.accent = Color("c0392b")
	host.add_child(saved_scope)
	saved_scope.owner = host
	await process_frame
	var packed := PackedScene.new()
	packed.pack(host)
	var state := packed.get_state()
	var names := []
	for i in state.get_node_property_count(1):
		names.append(state.get_node_property_name(1, i))
	check(not names.has("theme"), "the generated theme is never saved (%s)" % [names])
	check(saved_scope.theme != null, "(and there was one to save)")
	scope.queue_free()
	host.queue_free()
