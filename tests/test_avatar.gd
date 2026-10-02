extends "res://addons/woldui/tests/wold_test_base.gd"
## WoldAvatar + WoldAvatarGroup: initials, picture and mask, sizes, colour, status, rings, "+N", saving.

const SCENE := "res://addons/woldui/components/wold_avatar/wold_avatar.tscn"
const GROUP := "res://addons/woldui/components/wold_avatar_group/wold_avatar_group.tscn"

var stage: HBoxContainer


func _run() -> void:
	get_root().size = Vector2i(1280, 720)
	stage = HBoxContainer.new()
	stage.theme = WoldThemeBuilder.build(tokens())
	get_root().add_child(stage)
	await _initials()
	await _picture()
	await _sizes_and_shapes()
	await _status()
	await _group()
	await _saved_scene()
	var leader: WoldAvatar = load("res://addons/woldui/gallery/examples/faction_leader.tscn").instantiate()
	var lobby: WoldAvatarGroup = load("res://addons/woldui/gallery/examples/lobby_players.tscn").instantiate()
	stage.add_child(leader)
	stage.add_child(lobby)
	await _frames()
	check(leader.get_node("%Fill").visible and leader.frame_style() == &"AvatarSquareLg" and lobby.avatars().size() == 4 and lobby.hidden_count() == 2, "FactionLeader and LobbyPlayers come up as set")
	leader.queue_free()
	lobby.queue_free()
	finish(21)


func _avatar() -> WoldAvatar:
	var a: WoldAvatar = load(SCENE).instantiate()
	stage.add_child(a)
	return a


func _frames() -> void:
	await process_frame
	await process_frame


func _initials() -> void:
	check(WoldAvatar.initials_of("Queen Mab") == "QM" and WoldAvatar.initials_of("rivermouth") == "R" and WoldAvatar.initials_of("  a b c ") == "AB", "initials: first letters, two at most")
	var a := _avatar()
	await _frames()
	var label := a.get_node("%Initials") as Label
	check(label.visible and label.text == "QM" and a.tooltip_text == "Queen Mab", "no picture: the initials, and the name as tooltip")
	a.initials = "+3"
	check(label.text == "+3", "`initials` overrides them")
	a.color = Color("c0392b")
	await _frames()
	check(a.get_node("%Fill").visible and label.get_theme_color("font_color") == WoldColor.on(Color("c0392b")), "a colour fills behind them, with readable text on top")
	a.queue_free()


func _picture() -> void:
	var a := _avatar()
	var img := Image.create(8, 8, false, Image.FORMAT_RGBA8)
	img.fill(Color.RED)
	a.texture = ImageTexture.create_from_image(img)
	await _frames()
	check(a.get_node("%Image").visible and not a.get_node("%Initials").visible and not a.get_node("%Fill").visible, "a picture replaces initials and colour")
	var mask := a.get_node("%Mask") as Panel
	check(mask.clip_children == CanvasItem.CLIP_CHILDREN_AND_DRAW and (a.get_node("%Image") as TextureRect).stretch_mode == TextureRect.STRETCH_KEEP_ASPECT_COVERED, "it's cropped to the frame (which still draws, for initials), covering it")
	a.queue_free()


func _sizes_and_shapes() -> void:
	var t := tokens()
	var a := _avatar()
	await _frames()
	check(a.size == Vector2(t.icon_size_md * 2, t.icon_size_md * 2), "MD is twice an icon (%s)" % a.size)
	a.avatar_size = WoldAvatar.Size.SM
	await _frames()
	check(a.size.x == t.icon_size_sm * 2 and (a.get_node("%Initials") as Label).get_theme_font_size("font_size") == t.font_size(-2), "SM is smaller, with smaller type")
	var circle := (a.get_node("%Mask").get_theme_stylebox("panel") as StyleBoxFlat).corner_radius_top_left
	a.shape = WoldAvatar.Shape.SQUARE
	await _frames()
	var square := (a.get_node("%Mask").get_theme_stylebox("panel") as StyleBoxFlat).corner_radius_top_left
	check(circle == int(a.size.x / 2) and square < circle, "round is a circle, square just rounded")
	a.queue_free()


func _status() -> void:
	var t := tokens()
	var a := _avatar()
	await _frames()
	check(not a.get_node("%Status").visible, "no status, no dot")
	a.status = WoldAvatar.Status.ONLINE
	await _frames()
	var dot := a.get_node("%Status") as Panel
	check(dot.visible and (dot.get_theme_stylebox("panel") as StyleBoxFlat).bg_color == t.role("success"), "online is a success dot")
	var c := dot.position + dot.size / 2.0 - a.size / 2.0
	check(absf(c.length() - a.size.x / 2.0) < 1.0 and c.x > 0 and c.y > 0, "sitting on the rim, bottom right")
	a.status = WoldAvatar.Status.BUSY
	check((dot.get_theme_stylebox("panel") as StyleBoxFlat).bg_color == t.role("danger"), "busy is danger")
	a.queue_free()


func _group() -> void:
	var g: WoldAvatarGroup = load(GROUP).instantiate()
	stage.add_child(g)
	await _frames()
	var list := g.avatars()
	check(list.size() == 5 and g.hidden_count() == 2, "six names, four shown plus a +2")
	check((list[4].get_node("%Initials") as Label).text == "+2" and list[4].tooltip_text == "Nettle, Sorrel", "the +N avatar names who's folded in")
	check(list[1].position.x < list[0].position.x + list[0].size.x and list[1].has_ring(), "they overlap, with rings")
	var overlap := list[0].position.x + list[0].size.x - list[1].position.x
	var md_size := list[0].size.x
	g.avatar_size = WoldAvatar.Size.SM
	await _frames()
	var sm_list := g.avatars()
	var sm_overlap := sm_list[0].position.x + sm_list[0].size.x - sm_list[1].position.x
	check(is_equal_approx(overlap, floorf(md_size / 5.0)) and sm_overlap < overlap, "the overlap scales with the size (%.0f, small %.0f)" % [overlap, sm_overlap])
	g.max_visible = 0
	await _frames()
	check(g.avatars().size() == 6 and g.hidden_count() == 0, "max_visible 0 shows everyone")
	check(g.avatars()[0].owner == null, "generated avatars have no owner, so they're never saved")
	g.queue_free()


func _saved_scene() -> void:
	var host := HBoxContainer.new()
	stage.add_child(host)
	var a: WoldAvatar = load(SCENE).instantiate()
	host.add_child(a)
	a.owner = host
	a.status = WoldAvatar.Status.AWAY
	await _frames()
	var packed := PackedScene.new()
	packed.pack(host)
	var state := packed.get_state()
	var saved := {}
	for i in state.get_node_property_count(1):
		saved[state.get_node_property_name(1, i)] = true
	check(not saved.has("custom_minimum_size") and not saved.has("tooltip_text") and saved.has("status"), "saves its props, not what they make (saved: %s)" % [saved.keys()])
	host.queue_free()
