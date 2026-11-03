extends Node
## Offline stress check (a player's logs, 2026-11-03: "Parameter 'material' is null" bursts after a particle effect
## was prefetched): every converted effect with particles packed in the background while copies of them play in
## front of you. --mode=old packs and frees them on a worker thread the old way (the bug); default = NifScene.prefetch
## (now: particle effects packed / freed on the main thread). The run's own log is counted for the error afterwards.
##   --skip-login --zone=N --world-mode=1.65 --probe=particle_prefetch_probe [--mode=old]


var _paths: Array = []


func _old_pack(path: String) -> void:
	var n := NifScene.new()
	if n.load_scene(path):
		for c in n.find_children("*", "", true, false):
			c.owner = n
		var ps := PackedScene.new()
		ps.pack(n)
	n.free()


func _ready() -> void:
	var v := get_tree().current_scene
	await get_tree().create_timer(5.0).timeout
	for root in ["res://content/monsters/effects", "res://content/monsters/effects164"]:
		for d in DirAccess.get_directories_at(root):
			var f: String = String(root).path_join(d).path_join("model.gltf")
			if not FileAccess.file_exists(f):
				continue
			var j = JSON.parse_string(FileAccess.get_file_as_string(f))
			if j is Dictionary and not ((j as Dictionary).get("extras", {}).get("nif_particles", []) as Array).is_empty():
				_paths.append(f)
	_paths = _paths.slice(0, 160)
	var old := String(v.args.get("mode", "")) == "old"
	print("[pp] %d particle effects, mode %s" % [_paths.size(), "old (worker pack + free)" if old else "prefetch (fixed)"])
	var t := Thread.new()
	if old:
		t.start(func():
			for p in _paths:
				_old_pack(p))
	else:
		for p in _paths:
			NifScene.prefetch(p)
	# meanwhile: copies of a few already-made effects play in front of the camera, every frame drawn
	var shown := 0
	var start := Time.get_ticks_msec()
	while Time.get_ticks_msec() - start < 25000:
		var p: String = _paths[shown % _paths.size()]
		if NifScene.is_loaded(p) or old:
			var e := NifScene.copy_of(p)
			if e:
				v.add_child(e)
				e.global_position = v.player.global_position + Vector3(randf_range(-3, 3), 1.5, randf_range(-6, -2))
				get_tree().create_timer(1.5).timeout.connect(e.queue_free)
		shown += 1
		await get_tree().process_frame
		if old and not t.is_alive():
			break
		if not old and _paths.all(func(x): return NifScene.is_loaded(x)) and Time.get_ticks_msec() - start > 8000:
			break
	if t.is_started():
		t.wait_to_finish()
	await get_tree().create_timer(1.0).timeout
	print("[pp] done: %d copies shown in %.1f s" % [shown, (Time.get_ticks_msec() - start) / 1000.0])
	get_tree().quit()
