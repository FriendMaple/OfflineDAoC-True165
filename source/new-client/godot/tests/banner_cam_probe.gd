extends Node
## Offline: the two Salisbury Plains round towers and their Albion banners, seen from the owner's 2026-10-31 spot on
## the West Downs road (about 516, 718 m - "a floating albion banner"), and from 300 m / 120 m.
##   --skip-login --zone=1 --probe=banner_cam_probe --out=<dir>
var v: Node


func _ready() -> void:
	v = get_tree().current_scene
	await get_tree().create_timer(8.0).timeout
	var out := String(v.args.get("out", "user://"))
	var spot := Vector3(516.0, 0.0, 718.0)
	spot.y = v.zone.height_at(spot.x, spot.z) + 2.0
	v.player.global_position = spot
	await get_tree().create_timer(3.0).timeout
	var cam := Camera3D.new()
	v.add_child(cam)
	cam.far = 3000.0
	cam.fov = 60.0
	var towers := {"north": Vector3(161.6, 47.0, 223.5), "south": Vector3(225.2, 54.8, 1317.1)}
	for name in towers:
		var t: Vector3 = towers[name]
		for d in [-1.0, 300.0, 120.0]:
			var at: Vector3 = spot if d < 0.0 else t + (spot - t).normalized() * d
			at.y = v.zone.height_at(at.x, at.z) + 2.0
			v.player.global_position = at
			cam.global_position = at
			cam.look_at(t + Vector3(0, 20, 0))
			cam.current = true
			await get_tree().create_timer(2.5).timeout
			await RenderingServer.frame_post_draw
			var f := "%s/banner_%s_%d.png" % [out, name, int(at.distance_to(t))]
			get_viewport().get_texture().get_image().save_png(f)
			print("[banner] ", f, "  ", int(Vector2(at.x - t.x, at.z - t.z).length()), " m")
	var fog_clip: float = SkySystem.region_fog_clip(v.zone)
	print("[banner] region fog clip ", fog_clip, " m; view_mult ", ZoneLoader.view_mult)
	for c in v.zone.find_children("*", "MultiMeshInstance3D", true, false):
		var n := String(c.name)
		if n.begins_with("pennant_a") or n.begins_with("Round Tower"):
			print("[banner] ", n, " draws to ", (c as MultiMeshInstance3D).visibility_range_end, " m")
	get_tree().quit()
