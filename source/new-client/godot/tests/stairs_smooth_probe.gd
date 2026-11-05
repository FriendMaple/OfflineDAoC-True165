extends Node
## Offline check (reset day C12, 2026-11-05: "character and camera jerk up and down" on stairs): run up and down the
## Lethantis tower's side stairs (0.40 m risers) and log, every physics frame, the real height, the drawn model's and
## the camera's. Going up the real height still jumps (climbing as before) but the drawn ones move in small steps;
## going down nothing snaps and you stay on the ground (no fall pose).
##   --skip-login --zone=8 --world-mode=1.65 --probe=stairs_smooth_probe
var viewer: Node


func _run(p: Player, at: Vector3, yaw: float, label: String) -> bool:
	p.global_position = at
	p.velocity = Vector3.ZERO
	p.char_yaw = yaw
	p.cam_yaw = yaw
	await get_tree().create_timer(0.8).timeout
	var y0 := p.global_position.y
	var real_max := 0.0
	var model_max := 0.0
	var cam_max := 0.0
	var air := 0
	var last_real := p.global_position.y
	var last_model := p._model.global_position.y
	var last_cam := p._pivot.global_position.y
	p.autorun = true
	for i in 150:
		await get_tree().physics_frame
		var r := p.global_position.y
		var m := p._model.global_position.y
		var c := p._pivot.global_position.y
		real_max = maxf(real_max, absf(r - last_real))
		model_max = maxf(model_max, absf(m - last_model))
		cam_max = maxf(cam_max, absf(c - last_cam))
		last_real = r
		last_model = m
		last_cam = c
		if not p.grounded:
			air += 1
	p.autorun = false
	var dy := p.global_position.y - y0
	print("[stairs] %s: height %+.2f m | biggest one-frame change: real %.3f, model %.3f, camera %.3f | frames off the ground %d" %
			[label, dy, real_max, model_max, cam_max, air])
	return absf(dy) > 1.0 and model_max < 0.15 and cam_max < 0.15 and air < 5


func _ready() -> void:
	viewer = get_tree().current_scene
	await get_tree().create_timer(6.0).timeout
	var p: Player = viewer.player
	var ok: bool = await _run(p, Vector3(15137 * 0.025 - 1.5, 2292 * 0.025 + 0.3, 6084 * 0.025), -PI * 0.5, "up the side stairs")
	ok = await _run(p, Vector3(15137 * 0.025 + 4.5, 62.4, 6084 * 0.025), PI * 0.5, "down the side stairs") and ok
	print("[stairs] RESULT ", "PASS" if ok else "FAIL")
	get_tree().quit()
