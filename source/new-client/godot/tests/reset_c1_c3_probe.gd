extends Node
## Offline check (reset day 2026-11-05, C1-C3): the status window's health trough, the information window widening to a
## long item name, and the Realm Exchange vs the information window (opened beside it; a click brings a window to the
## front).
##   --skip-login --zone=N --world-mode=1.65 --probe=reset_c1_c3_probe


func _click(at: Vector2) -> void:
	for down in [true, false]:
		var e := InputEventMouseButton.new()
		e.button_index = MOUSE_BUTTON_LEFT
		e.pressed = down
		e.position = at
		e.global_position = at
		e.button_mask = MOUSE_BUTTON_MASK_LEFT if down else 0
		Input.parse_input_event(e)
		await get_tree().process_frame
	await get_tree().process_frame


func _ready() -> void:
	var v := get_tree().current_scene
	await get_tree().create_timer(6.0).timeout
	var ui = v.ui
	var ok := true
	# C1
	var st: ClassicWindow = ui.windows.status
	var troughs := 0
	for c in st.get_children():
		if c is TextureRect and (c as TextureRect).texture == UiArt.tex("redbg"):
			troughs += 1
	print("[c1] redbg troughs in the status window: ", troughs)
	ok = ok and troughs == 2
	# C2
	ui.show_lines("Hammer of the Otherworld", ["Level 45", "Two handed"])
	await get_tree().create_timer(0.3).timeout
	var info: ClassicWindow = ui.windows.info
	var title := info.get_node("Title") as Label
	var need := title.get_theme_font("font").get_string_size(title.text, HORIZONTAL_ALIGNMENT_LEFT, -1, title.get_theme_font_size("font_size")).x
	print("[c2] info width %.0f, title needs %.0f, title box %.0f" % [info.size.x, need, title.size.x])
	ok = ok and title.size.x >= need and info.size.x > GameUI.INFO_W
	info.hide_window()
	# C3: the exchange open, the info window placed over it, then a result's stats shown
	var ex: ExchangeWindow = ui.exchange
	ex.show_window()
	info.position = ex.position + Vector2(200, 300) * ex.scale
	ui.show_lines("Short Sword", ["Level 5"])
	await get_tree().create_timer(0.3).timeout
	var exr := Rect2(ex.position, ex.size * ex.scale)
	var inr := Rect2(info.position, info.size * info.scale)
	print("[c3] exchange ", exr, " info ", inr, " overlap ", exr.intersects(inr))
	ok = ok and not exr.intersects(inr)
	# a click on the exchange brings it in front of a window lying over it
	info.position = ex.position + Vector2(200, 300) * ex.scale
	info.move_to_front()
	await get_tree().process_frame
	var spot: Vector2 = ex.get_global_rect().position + Vector2(60, 200) * ex.get_global_transform().get_scale()
	print("[c3] before click: exchange index %d, info index %d" % [ex.get_index(), info.get_index()])
	await _click(spot)
	print("[c3] after a click on the exchange: exchange index %d, info index %d" % [ex.get_index(), info.get_index()])
	ok = ok and ex.get_index() > info.get_index()
	print("[c1-c3] RESULT ", "PASS" if ok else "FAIL")
	get_tree().quit()
