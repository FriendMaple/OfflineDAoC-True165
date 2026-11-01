extends Node3D
## Offline, True 1.65 Mode classic figures (LOCAL ONLY): one race's looks side by side, by the server's model id - the
## hire window's face / hair picker (owner 2026-10-30: the preview never changed). Head-and-shoulders shot.
##   Godot --path godot --screen 1 res://tests/classic_faces_probe.tscn -- --race=bri_m --models=32,471,473,14,257
##       --out=<png prefix>

func _ready() -> void:
	Server.world_mode = "1.65"
	Fig3Figure._classic = -1
	var race := "bri_m"
	var models := PackedStringArray(["32", "33", "34"])
	var out := "user://faces"
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--race="):
			race = a.get_slice("=", 1)
		elif a.begins_with("--models="):
			models = a.get_slice("=", 1).split(",")
		elif a.begins_with("--out="):
			out = a.get_slice("=", 1)
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color(0.35, 0.4, 0.45)
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color(0.6, 0.6, 0.6)
	add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-30, 20, 0)
	add_child(sun)
	var n := models.size()
	var cam := Camera3D.new()
	cam.position = Vector3(0, 1.55, 0.6 + n * 0.32)
	cam.fov = 40
	add_child(cam)
	for i in n:
		var f := Fig3Figure.make()
		add_child(f)
		if not f.load_figure(race):
			print("[faces] did not load")
			continue
		f.apply({"model": int(models[i])})
		f.position = Vector3((i - (n - 1) / 2.0) * 0.55, 0, 0)
		f.play("idle")
		print("[faces] %s model %s: %s" % [race, models[i], str(ClassicFigure.look_row(f.meta, {"model": int(models[i])}))])
	await get_tree().create_timer(1.0).timeout
	for i in 20:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(out + ".png")
	print("[faces] done")
	get_tree().quit()
