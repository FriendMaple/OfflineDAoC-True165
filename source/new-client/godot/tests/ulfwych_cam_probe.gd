extends Node
## Offline: Caer Ulfwych (Campacorentin Forest) - its small castle (tower5) and the Albion banner on it, from the
## owner's 2026-10-31 spot east of it ("more floating stuff in camperetin forest") and closer.
##   --skip-login --zone=8 --probe=ulfwych_cam_probe --out=<dir>
var v: Node


func _ready() -> void:
	v = get_tree().current_scene
	await get_tree().create_timer(8.0).timeout
	var out := String(v.args.get("out", "user://"))
	var castle := Vector3(971.2, 45.0, 864.0)
	var cam := Camera3D.new()
	v.add_child(cam)
	cam.far = 3000.0
	cam.fov = 65.0
	var spots := {"owner": Vector3(1054.0, 0, 888.0), "near": Vector3(1010.0, 0, 880.0), "above": Vector3(1040.0, 0, 900.0)}
	for k in spots:
		var at: Vector3 = spots[k]
		at.y = v.zone.height_at(at.x, at.z) + (2.0 if k != "above" else 40.0)
		v.player.global_position = Vector3(at.x, v.zone.height_at(at.x, at.z) + 0.3, at.z)
		cam.global_position = at
		cam.look_at(castle + Vector3(0, 12, 0))
		cam.current = true
		await get_tree().create_timer(3.0).timeout
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("%s/ulfwych_%s.png" % [out, k])
		print("[ulfwych] ", k, " ", int(Vector2(at.x - castle.x, at.z - castle.z).length()), " m")
	var n := 0
	for c in v.zone.find_children("*", "MultiMeshInstance3D", true, false):
		if String(c.name).begins_with("tower5"):
			n += 1
			print("[ulfwych] ", c.name, " visible ", (c as MultiMeshInstance3D).is_visible_in_tree(), " to ", (c as MultiMeshInstance3D).visibility_range_end)
	print("[ulfwych] tower5 batches: ", n)
	get_tree().quit()
