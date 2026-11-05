extends Node
## A shot for the owner (2026-11-05): the realm map (M, then the realm view) with each zone's quest dot and count, and
## the zone map of one of those zones with its quest marks - offline, the game's own quest data.
##   --skip-login --zone=N --world-mode=1.65 --probe=realm_map_shot --out=<dir>


func _ready() -> void:
	var v := get_tree().current_scene
	await get_tree().create_timer(6.0).timeout
	var m: MapWindow = v.ui.map_window
	m.show_window()
	var regions: Dictionary = m._maps.get("regions", {})
	print("[map] realm maps: ", regions.keys())
	var rid := ""
	for k in regions:
		for q in (regions[k] as Dictionary).get("zones", []):
			if int(q.zone) == int(v.zone.info.id):
				rid = k
	if rid == "":
		rid = regions.keys()[0]
	# made-up server markers (the server's own format: id range -> kind, Vector4 region, x, y, z) in four of the realm's
	# zones: turn-ins (green "?") and quest steps (orange) - S40's "quest available" (yellow "!") will come the same way
	var zones: Array = (regions[rid] as Dictionary).get("zones", [])
	var was_active := Server.active
	Server.active = true
	var n := 0
	var idx = JSON.parse_string(FileAccess.get_file_as_string("res://content/zones/zones_index.json"))
	if Server.zone_info(0).is_empty() and Server.get("_index") is Dictionary:
		for k in idx:
			Server._index[k] = idx[k]
	for q in zones.slice(0, 4):
		var zi: Dictionary = Server.zone_info(int(q.zone)) if not Server.zone_info(int(q.zone)).is_empty() else idx.get(str(int(q.zone)), {})
		var cx := float(zi.get("x", 0)) * 8192.0 + 30000.0
		var cy := float(zi.get("y", 0)) * 8192.0 + 30000.0
		var reg := int(zi.get("region", 1))
		for k in n + 1:
			Server.map_markers[Server.TURNIN_MARKERS + n * 10 + k] = Vector4(reg, cx + k * 2000.0, cy, 0)
		Server.map_markers[Server.QUEST_MARKERS + n] = Vector4(reg, cx, cy + 3000.0, 0)
		if n % 2 == 0:                                       # quest givers with a quest for you (S40): yellow "!"
			for k in 2 + n:
				Server.map_markers[Server.GIVER_MARKERS + 1 + n * 10 + k] = Vector4(reg, cx - 4000.0 + k * 1500.0, cy - 6000.0, 0)
		n += 1
	m._show({"kind": "region", "id": int(rid)}, true)
	await get_tree().create_timer(1.0).timeout
	var best := -1
	var most := 0
	for q in (regions[rid] as Dictionary).get("zones", []):
		var ms: Array = m.zone_quest_marks(int(q.zone))
		if ms.size() > 0:
			var kinds := {}
			for mk in ms:
				kinds[mk.kind] = int(kinds.get(mk.kind, 0)) + 1
			print("[map] zone %d %s: %d quest marks %s" % [int(q.zone), String(m._zone(int(q.zone)).get("name", "")), ms.size(), kinds])
		if ms.filter(func(x): return x.kind == "!").size() > 0 and ms.size() > most:
			most = ms.size()
			best = int(q.zone)
	var out := String(v.args.get("out", "user://"))
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(out + "/realm_map.png")
	if best >= 0:
		m._show({"kind": "zone", "id": best}, true)
		await get_tree().create_timer(1.0).timeout
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png(out + "/zone_map_quests.png")
		m.set_legend(false)                                   # Options > MAP LEGEND off: the map takes its room
		await get_tree().create_timer(0.5).timeout
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png(out + "/zone_map_legend_off.png")
		m.set_legend(true)
		var before: int = m._view._drawn_marks.size()
		m.set_quest_marks(false)                              # Options > QUEST MARKERS ON MAP off
		await get_tree().process_frame
		await RenderingServer.frame_post_draw
		print("[map] quest marks on: %d drawn; off: %d drawn, legend shown %s" % [before, m._view._drawn_marks.size(),
				m._legend.visible])
		print("[map] RESULT ", "PASS" if before > 0 and m._view._drawn_marks.is_empty() and not m._legend.visible else "FAIL")
		m.set_quest_marks(true)
	Server.active = was_active
	Server.map_markers.clear()
	get_tree().quit()
