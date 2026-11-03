extends Node
## Headless check of GitHub issue #9: every player-race look model (the classic figures' figure.json looks) that has no
## monsters.json row is drawn as its race (ServerWorld._model_info -> race), never as the objects.csv item with that
## number - Sylvan look 12 (852) was the Alb Thorn Bow. Siege objects (2598 ...) stay objects.
##   --skip-login --zone=N --world-mode=1.65 --probe=race_look_models_probe


func _ready() -> void:
	await get_tree().create_timer(4.0).timeout
	var sw := ServerWorld.new()
	var m = JSON.parse_string(FileAccess.get_file_as_string("res://content/monsters/monsters.json"))
	sw.models = m
	var bad := []
	var fixed := 0
	var no_base := {}
	for prefix in DirAccess.get_directories_at(ClassicFigure.CLASSIC_ROOT):
		for id in (ClassicFigure.meta_of(prefix).get("looks", {}) as Dictionary):
			var info: Dictionary = sw._model_info(int(id))
			if String(info.get("race", "")) != prefix:
				bad.append([id, prefix, info])
			elif not sw.models.has(str(id)):
				fixed += 1
				if not info.has("strides_units"):
					no_base[prefix] = true
	for k in [852, 856, 702, 850, 855]:
		print("[looks] %d -> %s" % [k, sw._model_info(k).get("race", sw._model_info(k))])
	print("[looks] siege 2602 -> %s" % [sw._model_info(2602)])
	print("[looks] looks without a monsters.json row, now their race: %d; wrong: %d %s; races with no row to copy: %s" % [
			fixed, bad.size(), bad.slice(0, 5), no_base.keys()])
	print("[looks] RESULT ", "PASS" if bad.is_empty() and sw._model_info(2602).has("object_model") else "FAIL")
	sw.free()
	get_tree().quit()
