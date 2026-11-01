extends Node3D
## Offline (no server), True 1.65 Mode classic figures: eight races in classic gear - plate + full helm +
## cloak + sword, a Highlander in a robe under a hooded cloak, leather / studded / scale sets with helms, a staff -
## shot from the front, mid-swing, casting, and from behind (cloaks).
##   Godot --path godot --screen 1 res://tests/classic_dress_probe.tscn -- --out=<png prefix>

const SETS := [
	["bri_m", {25: 86, 27: 87, 28: 88, 22: 89, 23: 90, 21: 93, 26: 57, 10: 3}],
	["hig_m", {25: 58, 26: 96}],
	["nor_f", {25: 240, 27: 241, 28: 242, 22: 243, 23: 244, 21: 335}],
	["tro_m", {25: 230, 27: 231, 28: 232, 22: 233, 23: 234, 21: 1289, 12: 327}],
	["cel_f", {25: 388, 27: 389, 28: 390, 22: 391, 23: 392, 21: 438, 26: 467}],
	["lur_m", {}],
	["kob_f", {25: 260, 27: 261, 28: 262, 22: 263, 23: 264, 21: 336, 10: 311}],
	["sar_m", {25: 31, 27: 32, 28: 33, 22: 34, 23: 133}],
	["inc_f", {21: 62, 26: 443, 25: 36, 27: 37}],
	["fir_m", {25: 708, 27: 709, 28: 710, 22: 711, 23: 712, 10: 445, 11: 59}],
]
var figs: Array = []
var cam: Camera3D


func _ready() -> void:
	Server.world_mode = "1.65"
	Fig3Figure._classic = -1
	print("[classic] mode classic: ", Fig3Figure.classic())
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color(0.35, 0.4, 0.45)
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color(0.6, 0.6, 0.6)
	add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-40, 30, 0)
	add_child(sun)
	cam = Camera3D.new()
	cam.position = Vector3(0, 1.2, 8.0)
	cam.fov = 50
	add_child(cam)
	for i in SETS.size():
		var prefix: String = SETS[i][0]
		var gear: Dictionary = SETS[i][1]
		var f := Fig3Figure.make()
		add_child(f)
		if not f.load_figure(prefix):
			print("[classic] %s did not load" % prefix)
			continue
		f.position = Vector3((i - 4.5) * 1.15, 0, 0)
		var item_at := func(slot: int) -> Dictionary:
			return {"model": int(gear[slot]), "color": 0} if gear.has(slot) else {}
		Player.dress(f, item_at, "twohand" if gear.has(12) else "standard", false, true, {})
		figs.append(f)
		var shown := []
		for part in f._meshes:
			for mi in f._meshes[part]:
				if (mi as MeshInstance3D).visible:
					shown.append(part)
					break
		print("[classic] %s %s: shown %s, clips %d" % [prefix, f.get_class(), str(shown), f.anim.get_animation_list().size() if f.anim else 0])
	_run()


func _shot(tag: String) -> void:
	for i in 20:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			get_viewport().get_texture().get_image().save_png("%s_%s.png" % [a.substr(6), tag])


func _run() -> void:
	await get_tree().create_timer(1.0).timeout
	await _shot("front")
	for f in figs:
		f.play("attack_med")
	await get_tree().create_timer(0.3).timeout
	await _shot("swing")
	for f in figs:
		f.play("cast_mid")
	await get_tree().create_timer(0.6).timeout
	await _shot("cast")
	for f in figs:
		f.play("idle")
		f.rotation_degrees.y = 180
	await _shot("back")
	print("[classic] done")
	get_tree().quit()
