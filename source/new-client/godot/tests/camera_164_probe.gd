extends Node
## Offline check of the 1.64 camera options (owner 2026-11-03): CAMERA FOLLOW off keeps a turned camera while you
## run, on swings it back; Pan Camera turns the camera, not you; Camera Toggle = first person; Camera Reset clears it.
## Real key events; the camera is left at its defaults (what gets saved) at the end.
##   --skip-login --zone=N --world-mode=1.65 --probe=camera_164_probe


func _key(code: Key, down: bool, shift := false, ctrl := false) -> void:
	var e := InputEventKey.new()
	e.keycode = code
	e.physical_keycode = code
	e.pressed = down
	e.shift_pressed = shift
	e.ctrl_pressed = ctrl
	Input.parse_input_event(e)
	await get_tree().process_frame


func _ready() -> void:
	var v := get_tree().current_scene
	await get_tree().create_timer(6.0).timeout
	var p = v.player
	var ok := true
	var fwd: Key = Keybinds.NAMES.get(Keybinds.bindings.move_forward[0], OS.find_keycode_from_string(Keybinds.bindings.move_forward[0]))
	var left: Key = OS.find_keycode_from_string(Keybinds.bindings.turn_left[0]) if not Keybinds.NAMES.has(Keybinds.bindings.turn_left[0]) else Keybinds.NAMES[Keybinds.bindings.turn_left[0]]
	for follow in [false, true]:
		p.camera_follow = follow
		p.reset_camera()
		p.cam_yaw = p.char_yaw + 1.0                     # as if turned with the left mouse
		p._cam_offset = 1.0
		await _key(fwd, true)
		await get_tree().create_timer(1.0).timeout
		await _key(fwd, false)
		var off := angle_difference(p.char_yaw, p.cam_yaw)
		print("[cam] follow %s: camera angle after 1 s of running %.2f (was 1.00)" % [follow, off])
		ok = ok and (absf(off - 1.0) < 0.05 if not follow else absf(off) < 0.2)
	# Pan Camera (unbound by default: bound here for the test only, not saved)
	p.camera_follow = false
	p.reset_camera()
	Keybinds.bindings["pan_camera"] = ["Ctrl+Shift+P"]
	Keybinds._apply()
	var yaw0: float = p.char_yaw
	var cam0: float = p.cam_yaw
	await _key(KEY_P, true, true, true)
	await _key(KEY_CTRL, true, true, true)
	await _key(KEY_SHIFT, true, true, true)
	await _key(left, true, true, true)
	await get_tree().create_timer(0.6).timeout
	await _key(left, false, true, true)
	await _key(KEY_P, false)
	await _key(KEY_CTRL, false)
	await _key(KEY_SHIFT, false)
	await get_tree().create_timer(0.3).timeout
	print("[cam] pan: character turned %.2f, camera turned %.2f, offset kept %.2f" % [angle_difference(yaw0, p.char_yaw),
			angle_difference(cam0, p.cam_yaw), p._cam_offset])
	ok = ok and absf(angle_difference(yaw0, p.char_yaw)) < 0.02 and absf(angle_difference(cam0, p.cam_yaw)) > 0.3
	Keybinds.bindings["pan_camera"] = []
	Keybinds._apply()
	# Camera Toggle: first person and back
	var ct: Key = Keybinds.NAMES.get(Keybinds.bindings.camera_toggle[0], OS.find_keycode_from_string(Keybinds.bindings.camera_toggle[0]))
	await _key(ct, true)
	await _key(ct, false)
	await get_tree().create_timer(0.6).timeout
	var fp: bool = p.first_person
	var arm: float = p._arm.spring_length
	var hidden: bool = not p._model.visible if p._model else false
	await _key(ct, true)
	await _key(ct, false)
	await get_tree().create_timer(0.6).timeout
	print("[cam] first person: on %s (arm %.2f m, figure hidden %s); toggled back: %s (arm %.2f m, figure shown %s)" % [
			fp, arm, hidden, not p.first_person, p._arm.spring_length, p._model.visible if p._model else false])
	ok = ok and fp and arm < 0.3 and hidden and not p.first_person and p._arm.spring_length > 2.0
	p.cam_distance = 9.0
	p.reset_camera()
	print("[cam] reset: offset %.2f distance %.2f pitch %.2f" % [p._cam_offset, p.cam_distance, p.cam_pitch])
	ok = ok and p._cam_offset == 0.0 and p.cam_distance == p.CAM_DISTANCE
	p.camera_follow = true
	print("[cam] RESULT ", "PASS" if ok else "FAIL")
	get_tree().quit()
