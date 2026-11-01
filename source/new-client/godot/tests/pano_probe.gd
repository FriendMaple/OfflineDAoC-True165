extends Node
## Offline: 8 shots all around one spot (the owner's screenshot spot read off his map) and every zone prop / fixture
## within --r metres with its height over the ground.
##   --skip-login --zone=N --probe=pano_probe --spot=x,z (metres) [--r=80] --out=<dir>
var v: Node


func _ready() -> void:
	v = get_tree().current_scene
	await get_tree().create_timer(8.0).timeout
	var out := String(v.args.get("out", "user://"))
	var sp := String(v.args.get("spot", "0,0")).split(",")
	var at := Vector3(float(sp[0]), 0.0, float(sp[1]))
	at.y = v.zone.height_at(at.x, at.z) + 2.0
	v.player.global_position = Vector3(at.x, at.y - 1.7, at.z)
	var cam := Camera3D.new()
	v.add_child(cam)
	cam.far = 3000.0
	cam.fov = 70.0
	for i in 8:
		var yaw := TAU * i / 8.0
		cam.global_position = at
		cam.look_at(at + Vector3(sin(yaw), -0.05, cos(yaw)) * 10.0)
		cam.current = true
		await get_tree().create_timer(2.0).timeout
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("%s/pano_%d.png" % [out, i])
	var r := float(v.args.get("r", "80"))
	var info: Dictionary = v.zone.info
	for f in info.get("fixtures", []):
		var p := Vector3(f.pos[0], f.pos[1], f.pos[2])
		var d := Vector2(p.x - at.x, p.z - at.z).length()
		if d <= r:
			var m: Dictionary = info.models[int(f.m)]
			var up: float = p.y - v.zone.height_at(p.x, p.z)
			var dir := int(fposmod(rad_to_deg(atan2(p.x - at.x, p.z - at.z)) + 22.5, 360.0) / 45.0)
			print("[pano] %5.1f m  shot %d  %-28s %-26s base %.1f m over the ground" % [d, dir, String(m.name), String(f.get("name", "")), up])
	get_tree().quit()
