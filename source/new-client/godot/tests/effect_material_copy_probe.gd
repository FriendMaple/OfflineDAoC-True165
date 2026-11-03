extends Node
## Offline check (a player's logs, 2026-11-03): an effect copy that fades / changes colour takes its own material copy
## (NifMaterials.copy_of, not duplicate(): no RenderingServer.shader_get_parameter_default sync per copy) - every
## parameter the original has set comes along. Five effects, three copies each.
##   --skip-login --zone=N --world-mode=1.65 --probe=effect_material_copy_probe


func _ready() -> void:
	await get_tree().create_timer(4.0).timeout
	var ok := true
	var checked := 0
	for path in ["res://content/monsters/effects/absorb_redpulse/model.gltf", "res://content/monsters/effects/air_inhale1/model.gltf",
			"res://content/monsters/effects/alb_arcticwind_hit/model.gltf", "res://content/monsters/effects/alb_clstrbuff1_hit/model.gltf",
			"res://content/monsters/effects/alb_clstrbuff2_hit/model.gltf"]:
		for k in 3:
			var e := NifScene.copy_of(path)
			if e == null:
				continue
			add_child(e)
			for a in e._alphas:
				var own: ShaderMaterial = a.mat
				var src: ShaderMaterial = null
				for mi in e.find_children("*", "MeshInstance3D", true, false):
					for i in (mi as MeshInstance3D).mesh.get_surface_count():
						if (mi as MeshInstance3D).get_surface_override_material(i) == own:
							src = (mi as MeshInstance3D).mesh.surface_get_material(i)
				if src == null:
					continue
				checked += 1
				for n in NifMaterials._uniforms.get(src.shader, []):
					if src.get_shader_parameter(n) != own.get_shader_parameter(n):
						ok = false
						print("[mat] differs: %s %s" % [path.get_base_dir().get_file(), n])
				ok = ok and own != src and own.shader == src.shader
			e.queue_free()
	print("[mat] effect material copies checked: %d" % checked)
	print("[mat] RESULT ", "PASS" if ok and checked > 0 else "FAIL")
	get_tree().quit()
