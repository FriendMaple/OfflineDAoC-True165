extends Node
## Offline, True 1.65 Mode: the drawn floors at the inn doors and paths (owner 2026-10-30: an adventurer
## sank into the floor at the Albion inn entrance). For each point (zone units x, y, the layout's / server's z):
## the terrain, every floor hit straight down from 10 m above, and what NpcManager.floor_at gives from the server's Z.
##   Godot --path godot --screen 1 res://game/zone_viewer.tscn -- --zone=9 --world-mode=1.65 --no-npcs --mute
##       --single-zone --probe=inn_floor_probe --points="x,y,z;x,y,z;..."
const M := 0.025


func _ready() -> void:
	await get_tree().create_timer(4.0).timeout
	var viewer := get_tree().current_scene
	var zone: ZoneLoader = viewer.zone
	var spec := ""
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--points="):
			spec = a.get_slice("=", 1)
	var space := zone.get_world_3d().direct_space_state
	for item in spec.split(";", false):
		var v := item.split(",")
		var x := float(v[0]) * M
		var z := float(v[1]) * M
		var sy := float(v[2]) * M
		var hits := []
		var top := sy + 10.0
		for i in 8:
			var q := PhysicsRayQueryParameters3D.create(Vector3(x, top, z), Vector3(x, sy - 6.0, z), ZoneLoader.LAYER_FLOOR)
			var hit := space.intersect_ray(q)
			if hit.is_empty():
				break
			hits.append(snappedf(float(hit.position.y) - sy, 0.01))
			top = float(hit.position.y) - 0.01
		var q2 := PhysicsRayQueryParameters3D.create(Vector3(x, sy + 1.2, z), Vector3(x, sy - 6.0, z), ZoneLoader.LAYER_FLOOR)
		var h2 := space.intersect_ray(q2)
		print("[floor] %s,%s server z %.2f m: terrain %+.2f, floors (m above server z) %s, floor_at %+.2f" % [v[0], v[1], sy,
				zone.height_at(x, z) - sy, str(hits), (float(h2.position.y) if not h2.is_empty() else zone.height_at(x, z)) - sy])
	get_tree().quit()
