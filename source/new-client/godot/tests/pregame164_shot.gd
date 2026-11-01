extends Node
## Offline shots of the period 1.64 pregame (game/pregame_164.gd), no server:
##   godot --path godot res://tests/pregame164_shot.tscn --world-mode=1.65 -- --out=<prefix> [--realm=alb]
## Writes <prefix>_realm.png, _select.png, _create.png, _create_done.png, _summary.png, _delete.png.

func _ready() -> void:
	var args := {}
	for a in OS.get_cmdline_user_args():
		var kv := a.trim_prefix("--").split("=", true, 1)
		args[kv[0]] = kv[1] if kv.size() > 1 else ""
	var out := String(args.get("out", "user://pregame164"))
	var realm := String(args.get("realm", "alb"))
	get_window().size = Vector2i(1600, 900)
	var p: Pregame164 = load("res://game/pregame_164.tscn").instantiate()
	add_child(p)
	await _frames(10)
	await _shot(out + "_realm.png")
	var rid: int = {"alb": 1, "mid": 5, "hib": 9}[realm]
	var prefix := "%s_m" % String(Server.RACES[rid][1])
	var looks: Array = ClassicFigure.meta_of(prefix).get("player_looks", [0])
	p.test_chars = [{"name": "Testone", "class_name": "Fighter", "level": 5, "slot": 0, "prefix": prefix,
			"look": {"model": int(looks[0])}, "location_text": "Camelot Hills"},
			{"name": "Testtwo", "class_name": "Mage", "level": 12, "slot": 2, "prefix": prefix,
			"look": {"model": int(looks[min(3, looks.size() - 1)])}},
			{"name": "Oldslot", "class_name": "Rogue", "level": 20, "slot": 9, "prefix": prefix,
			"look": {"model": int(looks[0])}}]
	p._pick_realm(realm)
	await _frames(20)
	await _shot(out + "_select.png")
	p._options.show_window()
	await _frames(5)
	await _shot(out + "_options.png")
	p._options.show_page("controls")
	await _frames(5)
	await _shot(out + "_options_controls.png")
	p._options.hide_window()
	p._confirm("delete")
	await _frames(5)
	await _shot(out + "_delete.png")
	p._start_create(1)
	await _frames(20)
	await _shot(out + "_create.png")
	for h in [["class", Pregame164.CLASS_HELP[String(p.draft.base)]], ["race", Pregame164.RACE_HELP[int(p.draft.race)][0]],
			["stat", Pregame164.STAT_HELP["STR"]]]:
		p._say(String(h[1]), Pregame164.HELP)                # (what a mouse-over puts in the help box)
		await _frames(3)
		await _shot(out + "_help_%s.png" % h[0])
	print("auto: race ", p.draft.race, " base ", p.draft.base, " stats ", p.draft.stats, " left ", p._points_left())
	var before: Array = (p.draft.stats as Array).duplicate()
	var at: Vector2 = p._stage.get_global_transform() * Vector2(611 + 8, 91 + 8)   # STR's minus, a real click
	for pressed in [true, false]:
		var mb := InputEventMouseButton.new()
		mb.button_index = MOUSE_BUTTON_LEFT
		mb.pressed = pressed
		mb.position = at
		mb.global_position = at
		get_viewport().push_input(mb)
		await get_tree().process_frame
	await _frames(3)
	print("click STR -: ", before[0], " -> ", p.draft.stats[0], " left ", p._points_left())
	var mid: Vector2 = p._stage.get_global_transform() * Vector2(400, 300)    # a left-drag across the figure
	var down := InputEventMouseButton.new()
	down.button_index = MOUSE_BUTTON_LEFT
	down.pressed = true
	down.position = mid
	down.global_position = mid
	get_viewport().push_input(down)
	await get_tree().process_frame
	var mv := InputEventMouseMotion.new()
	mv.position = mid + Vector2(120, 0)
	mv.global_position = mv.position
	mv.relative = Vector2(120, 0)
	mv.button_mask = MOUSE_BUTTON_MASK_LEFT
	get_viewport().push_input(mv)
	await get_tree().process_frame
	var up := down.duplicate()
	up.pressed = false
	get_viewport().push_input(up)
	await _frames(3)
	print("drag: yaw ", p._yaw, " figure y ", p._figure.rotation_degrees.y)
	await _shot(out + "_create_turned.png")
	p._pick_race(rid)
	p._pick_gender(0)
	var bases: Array = p._allowed_bases()
	p._pick_base(String(bases[0]) if bases.size() > 0 else String(Pregame164.CLASS_BUTTONS[realm][0][0]))
	for si in [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1]:
		p._stat(si, 1)
	p._step("face", 2)
	p._step("hair", 1)
	p.draft.name = "Periodtest"
	p._show("create")
	await _frames(20)
	await _shot(out + "_create_done.png")
	print("points left ", p._points_left(), " stats ", p.draft.stats)
	p._show("summary")
	await _frames(5)
	await _shot(out + "_summary.png")
	get_tree().quit()


func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame


func _shot(path: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(path)
	print("wrote ", path)
