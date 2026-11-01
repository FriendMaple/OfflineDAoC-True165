extends Node3D
## Offline: the classic (True 1.65 Mode) figures' ride_horse pose against the Catacombs figures' - the server riders
## (ServerWorld._seat_riders) put a rider's origin on its steed's saddle, measured on the Catacombs figures. Prints the
## pelvis and foot heights over the origin for each, and saves a side shot (--out=<png>).
const RACES := ["bri_m", "hig_f", "tro_m", "kob_m", "cel_f", "nor_m"]
var rows := []


func _fig(prefix: String, classic: bool, x: float) -> Node3D:
	Server.world_mode = "1.65" if classic else "normal"
	Fig3Figure._classic = -1
	var f := Fig3Figure.make()
	add_child(f)
	if not f.load_figure(prefix):
		print("[ride] %s %s did not load" % [prefix, "classic" if classic else "cata"])
		return null
	f.position = Vector3(x, 0, 0)
	f.rotation_degrees.y = 90
	if f.anim and f.anim.has_animation("ride_horse"):
		f.anim.play("ride_horse")
		f.anim.advance(0.3)
	else:
		print("[ride] %s %s: no ride_horse" % [prefix, "classic" if classic else "cata"])
	rows.append([prefix, classic, f])
	return f


func _bone_y(f: Node3D, names: Array) -> float:
	var sk: Skeleton3D = f.find_children("*", "Skeleton3D", true, false)[0]
	for n in names:
		var i := sk.find_bone(n)
		if i >= 0:
			return (sk.global_transform * sk.get_bone_global_pose(i)).origin.y - f.global_position.y
	return NAN


func _ready() -> void:
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color(0.35, 0.4, 0.45)
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color(0.7, 0.7, 0.7)
	add_child(env)
	var cam := Camera3D.new()
	cam.position = Vector3(0, 0.6, 9)
	cam.fov = 45
	add_child(cam)
	for i in RACES.size():
		_fig(RACES[i], false, (i - 2.5) * 1.6 - 0.35)
		_fig(RACES[i], true, (i - 2.5) * 1.6 + 0.35)
	var line := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(12, 0.01, 0.01)
	line.mesh = bm
	add_child(line)
	for k in 10:
		await get_tree().process_frame
	for r in rows:
		print("[ride] %-6s %-7s pelvis %+.2f  foot %+.2f" % [r[0], "classic" if r[1] else "cata",
				_bone_y(r[2], ["Bip01 Pelvis", "Bip01"]), _bone_y(r[2], ["Bip01 L Foot", "Bip01 L Toe0"])])
	await RenderingServer.frame_post_draw
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			get_viewport().get_texture().get_image().save_png(a.substr(6))
	get_tree().quit()
