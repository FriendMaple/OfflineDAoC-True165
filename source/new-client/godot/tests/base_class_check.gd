extends Node
## Live test (owner 2026-10-30, 1.65 Mode: the create screen offers the period base classes): logs in the launcher's
## way with --world-mode=1.65, lists every realm's races and the classes offered, shoots the create screen (--out=),
## then creates a test Briton Fighter (base class 14) on Claude's test account to see the server take a base class
## id, and deletes it again.
##   Godot --path godot res://tests/base_class_check.tscn -- --server=... --account=... --password=... --world-mode=1.65

func _ready() -> void:
	var d := Driver.new()
	d.name = "BaseClassDriver"
	get_tree().root.add_child.call_deferred(d)
	get_tree().change_scene_to_file.call_deferred("res://game/login_screen.tscn")


class Driver extends Node:
	func _ready() -> void:
		process_mode = Node.PROCESS_MODE_ALWAYS
		_run()

	func _run() -> void:
		var waited := 0
		while waited < 120:
			await get_tree().create_timer(1.0).timeout
			waited += 1
			var s := get_tree().current_scene
			if s and s.has_method("_play") and Server.logged:
				break
		var pg := get_tree().current_scene
		if pg == null or not pg.has_method("_play"):
			print("[base] never reached character select")
			get_tree().quit()
			return
		print("[base] world mode: ", Server.world_mode)
		await get_tree().create_timer(3.0).timeout
		for realm in ["alb", "mid", "hib"]:
			for race in CharacterFactory.RACES[realm]:
				var cl: Array = Server.classes_for(realm, int(Server.RACE_BY_NAME.get(String(race[0]), 0)), false)
				print("[base] %s %-10s %s" % [realm, race[0], str(cl.map(func(c): return "%s (%d)" % [c[1], c[0]]))])
		# the create screen, Hibernia, an Elf
		pg.call("_pick_realm", "hib")
		await get_tree().create_timer(1.0).timeout
		pg.call("_start_create")
		await get_tree().create_timer(1.0).timeout
		pg.get("draft")["race"] = 2
		pg.call("_check_server_class")
		pg.call("_show", "create")
		await get_tree().create_timer(2.0).timeout
		await RenderingServer.frame_post_draw
		var out := ""
		for a in OS.get_cmdline_user_args():
			if a.begins_with("--out="):
				out = a.substr(6)
		if out != "":
			get_viewport().get_texture().get_image().save_png(out)
			print("[base] shot ", out)
		print("[base] stats a Fighter's points follow: ", Server.class_stats(14), "; Way of the Grove: ", Server.class_stats(57))
		# a base class character on the server
		var err := Server.create_character("alb", "Briton", false, 14, "Claudefighter", {})
		print("[base] create Claudefighter (Fighter, 14): ", err if err != "" else "sent")
		if err == "":
			var res: Array = await Server.created
			print("[base] created: ", res)
			await get_tree().create_timer(2.0).timeout
			Server.request_characters("alb")
			await get_tree().create_timer(3.0).timeout
			for c in Server.characters_in("alb"):
				if String(c.name) == "Claudefighter":
					print("[base] on the server: class %d level %d" % [int(c.get("class_id", 0)), int(c.get("level", 0))])
					Server.delete_character("alb", c)
					await get_tree().create_timer(3.0).timeout
					Server.request_characters("alb")
					await get_tree().create_timer(3.0).timeout
					print("[base] deleted: ", not Server.characters_in("alb").any(func(x): return String(x.name) == "Claudefighter"))
		print("[base] done")
		get_tree().quit()
