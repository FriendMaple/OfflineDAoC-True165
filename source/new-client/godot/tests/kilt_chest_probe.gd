extends Node3D
## Offline (no server), True 1.65 Mode (reset day C20, 2026-11-05): a Highlander's kilt takes the worn chest item's
## lower-body skin - none (the race's plaid), a leather tunic, a chain hauberk, a plate breast, leather leggings alone
## (no chest: still the plaid). Shot from the front; the kilt's texture printed.
##   Godot --path godot res://tests/kilt_chest_probe.tscn -- --out=<png prefix>

const SETS := [
	["hig_m", {}],
	["hig_m", {25: 31}],
	["hig_m", {25: 41, 27: 42}],
	["hig_m", {25: 46}],
	["hig_m", {27: 32}],
	["hig_f", {25: 31}],
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
		f.position = Vector3((i - 2.5) * 1.15, 0, 0)
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
		var lb := String(f._shown.get("lbody", ""))
		var tex := ""
		for mi in f._parts(lb) if lb != "" else []:
			var m := (mi as MeshInstance3D).material_override as ShaderMaterial
			if m and m.get_shader_parameter("albedo_tex"):
				tex = (m.get_shader_parameter("albedo_tex") as Texture2D).resource_path.get_file()
		print("[kilt] %s gear %s: lower body %s, texture %s" % [prefix, str(gear), lb, tex])
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
	print("[kilt] done")
	get_tree().quit()
