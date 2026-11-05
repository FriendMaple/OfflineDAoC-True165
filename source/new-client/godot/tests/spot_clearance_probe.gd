extends Node
## Offline: how much room an NPC spot has (server region units) - the floor under it and the nearest wall around it
## (16 level rays at knee, chest and head height, all collision layers). --spots="name:x:y:z;..." checks those;
## --around="x:y:z:r" also tries 16 spots at r units around that point (a keeper and its neighbour's candidates).
##   --skip-login --zone=N --pos=x,y,z --world-mode=1.65 --probe=spot_clearance_probe --spots="..." [--around=...]
var v: Node
var zi: Dictionary


func _arg(k: String, def: String) -> String:
	return String(v.args.get(k, def))


func _local(gx: float, gy: float, gz: float) -> Vector3:
	return Vector3((gx - float(zi.get("x", 0)) * 8192.0) * 0.025, gz * 0.025, (gy - float(zi.get("y", 0)) * 8192.0) * 0.025)


## [floor y (m) or NAN, nearest wall (m), its direction (degrees, 0 = +x)]
func _room(at: Vector3) -> Array:
	var space: PhysicsDirectSpaceState3D = v.zone.get_world_3d().direct_space_state
	var down := PhysicsRayQueryParameters3D.create(at + Vector3(0, 1.6, 0), at - Vector3(0, 6, 0), ZoneLoader.LAYER_FLOOR)
	var hit := space.intersect_ray(down)
	var fy := float(hit.position.y) if not hit.is_empty() else NAN
	var base := Vector3(at.x, fy if not is_nan(fy) else at.y, at.z)
	var best := 99.0
	var dir := 0.0
	for h in [0.4, 1.1, 1.8]:
		for i in 16:
			var a := TAU * i / 16.0
			var d := Vector3(cos(a), 0, sin(a))
			var q := PhysicsRayQueryParameters3D.create(base + Vector3(0, h, 0), base + Vector3(0, h, 0) + d * 5.0)
			var r := space.intersect_ray(q)
			if not r.is_empty():
				var dist := (r.position as Vector3).distance_to(base + Vector3(0, h, 0))
				if dist < best:
					best = dist
					dir = rad_to_deg(a)
	return [fy, best, dir]


func _ready() -> void:
	v = get_tree().current_scene
	await get_tree().create_timer(8.0).timeout
	var idx = JSON.parse_string(FileAccess.get_file_as_string("res://content/zones/zones_index.json"))
	zi = idx.get(str(int(v.zone.info.id)), {})
	for one in _arg("spots", "").split(";", false):
		var f := one.split(":")
		var r := _room(_local(float(f[1]), float(f[2]), float(f[3])))
		print("[room] %-10s %s,%s  floor %s  nearest wall %.2f m (%d units) toward %d deg" % [f[0], f[1], f[2],
				"none" if is_nan(r[0]) else "%.0f" % (float(r[0]) / 0.025), r[1], roundi(r[1] / 0.025), roundi(r[2])])
	var ar := _arg("around", "").split(":")
	if ar.size() == 4:
		var c := Vector3(float(ar[0]), float(ar[1]), float(ar[2]))
		var rad := float(ar[3])
		for i in 16:
			var a := TAU * i / 16.0
			var gx := roundf(c.x + cos(a) * rad)
			var gy := roundf(c.y + sin(a) * rad)
			var r := _room(_local(gx, gy, c.z))
			print("[around] %d,%d  floor %s  nearest wall %.2f m (%d units)" % [gx, gy,
					"none" if is_nan(r[0]) else "%.0f" % (float(r[0]) / 0.025), r[1], roundi(r[1] / 0.025)])
	get_tree().quit()
