extends SceneTree
## Offline: True 1.65 Mode's base classes per race from content/classes/base_classes_165.json (no server).
func _initialize() -> void:
	await process_frame
	var srv = root.get_node("Server")
	srv.world_mode = "1.65"
	for realm in ["alb", "mid", "hib"]:
		for race in [1, 2, 3, 4, 13, 5, 6, 7, 8, 14, 9, 10, 11, 12, 15]:
			var cl: Array = srv.classes_for(realm, race, false)
			if not cl.is_empty():
				print("%s race %d: %s" % [realm, race, ", ".join(cl.map(func(c): return "%d %s" % [c[0], c[1]]))])
	print("desc 36: ", srv.base_description(36).substr(0, 90))
	quit()
