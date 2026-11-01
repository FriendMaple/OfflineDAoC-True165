extends Node3D
## Offline: the Albion inn NPCs' classic looks (owner 2026-10-30: bad cloak mesh, helm colour). From classic_dress_probe: eight races in classic gear - plate + full helm +
## cloak + sword, a Highlander in a robe under a hooded cloak, leather / studded / scale sets with helms, a staff -
## shot from the front, mid-swing, casting, and from behind (cloaks).
##   Godot --path godot --screen 1 res://tests/classic_dress_probe.tscn -- --out=<png prefix>

const SETS := [
	["sar_m", {25: 662, 27: 47, 28: 48, 22: 49, 23: 50, 26: 91, 12: 68}],     # the plate "albion adventurer" (model 48)
	["hig_m", {25: 46, 28: 48, 27: 47, 22: 49, 23: 50, 21: 95, 26: 92, 12: 26}],   # Osric the Horn Handler (model 42)
	["bri_m", {25: 46, 28: 48, 27: 47, 22: 49, 23: 50, 21: 95, 26: 91}],     # a Briton in the same, for comparison
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
	cam.position = Vector3(0, 1.1, 4.2)
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
		f.position = Vector3((i - 1.0) * 1.2, 0, 0)
		f.apply(Fig3Figure.npc_look("srv%d" % (1000 + i), f.meta, [48, 42, 32][i]))   # as Npc._build_model: the server's model
		var item_at := func(slot: int) -> Dictionary:
			return {"model": int(gear[slot]), "color": 0} if gear.has(slot) else {}
		Player.dress(f, item_at, "twohand" if gear.has(12) else "standard", false, true, {})
		figs.append(f)
		for a in OS.get_cmdline_user_args():             # --cloak-uv=1 / 2: the cloak skin on that UV set (a test)
			if a.begins_with("--cloak-uv="):
				var set_n := int(a.get_slice("=", 1))
				for part in f._meshes:
					if not String(part).begins_with("Cloak"):
						continue
					for mi in f._meshes[part]:
						var sm := (mi as MeshInstance3D).material_override as ShaderMaterial
						if sm == null:
							continue
						var sh := Shader.new()
						sh.code = sm.shader.code.replace("texture(albedo_tex, UV)", "texture(albedo_tex, UV2)" if set_n == 1 else "texture(albedo_tex, logo_uv)")
						var m2 := sm.duplicate() as ShaderMaterial
						m2.shader = sh
						(mi as MeshInstance3D).material_override = m2
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
	for f in figs:
		f.rotation_degrees.y = 90
	await _shot("side")
	for f in figs:
		f.play("walk")
	await get_tree().create_timer(0.4).timeout
	await _shot("walk_side")
	print("[classic] done")
	get_tree().quit()
