extends Node
## Offline check of GitHub issue #8: a press on the combat chat box's top-right corner starts a resize (as on the main
## box, and the 1.64 chat corners) instead of hiding it. Real mouse events; the box's size is put back afterwards.
##   --skip-login --zone=N --world-mode=1.65 --probe=chat_corner_probe


func _ev(e: InputEvent) -> void:
	Input.parse_input_event(e)
	await get_tree().process_frame
	await get_tree().process_frame


func _ready() -> void:
	var v := get_tree().current_scene
	await get_tree().create_timer(6.0).timeout
	var ok := true
	for c in [v.ui.chat_combat, v.ui.chat]:
		var w: ChatWindow = c
		w.show_window()
		await get_tree().process_frame
		var keep: Vector2 = w.size
		var keep_pos: Vector2 = w.position
		var sc: Vector2 = w.get_global_transform().get_scale()
		var corner := w.global_position + Vector2(w.size.x - 3, 3) * sc
		var m := InputEventMouseMotion.new()
		m.position = corner
		m.global_position = corner
		get_viewport().warp_mouse(corner)
		await _ev(m)
		var down := InputEventMouseButton.new()
		down.button_index = MOUSE_BUTTON_LEFT
		down.pressed = true
		down.position = corner
		down.global_position = corner
		await _ev(down)
		var started: String = w._resize
		var hov := get_viewport().gui_get_hovered_control()
		print("[corner] %s: corner %s rect %s resize '%s' hovered %s" % [w.window_id, corner, w.get_global_rect(), w._resize, hov.get_path() if hov else "-"])
		for k in 6:
			var mv := InputEventMouseMotion.new()
			mv.button_mask = MOUSE_BUTTON_MASK_LEFT
			mv.position = corner + Vector2(5, -4) * (k + 1)
			mv.global_position = mv.position
			mv.relative = Vector2(5, -4)
			get_viewport().warp_mouse(mv.position)
			await _ev(mv)
		var up := down.duplicate() as InputEventMouseButton
		up.pressed = false
		up.position = corner + Vector2(30, -24)
		up.global_position = up.position
		await _ev(up)
		print("[corner] %s: visible %s, size %s -> %s" % [w.window_id, w.visible, keep, w.size])
		# (the resize itself follows the real pointer, which a synthetic event cannot move in an unfocused window)
		ok = ok and w.visible and started == "topright"
		w.position = keep_pos
		w.set_window_size(keep)
		w.save_position()
	print("[corner] RESULT ", "PASS" if ok else "FAIL")
	get_tree().quit()
