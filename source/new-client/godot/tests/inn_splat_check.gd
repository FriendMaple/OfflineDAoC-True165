extends Node
## Offline, True 1.65 Mode: prints which ground-blend weight maps and distance ground the loaded zone uses
## for the inn road patches (ZoneLoader._add_inn_165), and how many inn fixtures / lights it added.
func _ready() -> void:
	await get_tree().create_timer(3.0).timeout
	var zone: ZoneLoader = get_tree().current_scene.zone
	var inn = JSON.parse_string(FileAccess.get_file_as_string(zone.dir.path_join("inns_165.json")))
	for k in inn.splat_patches:
		print("[splat] ", k, " -> ", zone.info.ground_splat.patches[k].weights)
	print("[splat] terrain sets ", zone.info.terrain_sets, " using ", zone.terrain_set)
	print("[splat] inn fixtures ", (zone.info.fixtures as Array).filter(func(f): return f.get("source", "") == "inn_165").size(),
			", lights ", (zone.info.lights as Array).filter(func(l): return l.get("source", "") == "inn_165").size())
	get_tree().quit()
