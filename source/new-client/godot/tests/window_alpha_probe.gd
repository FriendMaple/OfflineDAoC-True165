extends Node
## Offline check (owner 2026-11-03: window transparency "an option per window"): the right-click Alpha panel's arrow
## changes only the window it was opened on, the value is saved and read back, Options' ALPHA sets every window again
## and drops the per-window values; Camera Follow defaults to OFF (the 1.64 camera).
##   --skip-login --zone=N --world-mode=1.65 --probe=window_alpha_probe


func _a(w: ClassicWindow) -> float:
	return snappedf((w.frame as Control).modulate.a, 0.01) if w and w.frame else -1.0


func _ready() -> void:
	var v := get_tree().current_scene
	await get_tree().create_timer(6.0).timeout
	var ui = v.ui
	var ok := true
	var follow: bool = v.player.camera_follow
	print("[alpha] camera_follow default ", follow)
	ok = ok and not follow
	ClassicWindow.set_interface_alpha(100, get_tree())
	var chat: ClassicWindow = ui.chat
	var other: ClassicWindow = null
	for w in get_tree().get_nodes_in_group("classic_windows"):
		var cw := w as ClassicWindow
		if cw != chat and cw.window_id != chat.window_id and cw.window_id != "" and cw.frame:
			other = cw
			break
	print("[alpha] chat '", chat.window_id, "' other '", other.window_id, "'")
	# the right-click panel on the chat window, its "<" arrow pressed 3 times
	chat._alpha_panel(chat.get_global_rect().get_center())
	await get_tree().process_frame
	var host: Node = chat.get_parent()
	var catcher: Node = host.get_child(host.get_child_count() - 1)
	var arrows: Array = []
	for b in catcher.find_children("*", "Button", true, false):
		arrows.append(b)
	for i in 3:
		(arrows[0] as Button).pressed.emit()
	await get_tree().process_frame
	print("[alpha] after 3x '<' on chat: chat %.2f other %.2f" % [_a(chat), _a(other)])
	ok = ok and is_equal_approx(_a(chat), 0.7) and is_equal_approx(_a(other), 1.0)
	catcher.queue_free()
	var cfg := ConfigFile.new()
	cfg.load(UiArt.settings_path)
	print("[alpha] saved [window_alpha] ", cfg.get_value("window_alpha", chat.window_id, "none"), "  [interface] alpha ", cfg.get_value("interface", "alpha", "none"))
	ok = ok and int(cfg.get_value("window_alpha", chat.window_id, 0)) == 70
	# as after a restart: read back from the file
	ClassicWindow._per_window = null
	print("[alpha] read back: chat %.2f other %.2f" % [chat.window_alpha(), other.window_alpha()])
	ok = ok and is_equal_approx(chat.window_alpha(), 0.7) and is_equal_approx(other.window_alpha(), 1.0)
	# Options' ALPHA: every window, per-window values dropped
	ClassicWindow.set_interface_alpha(50, get_tree())
	cfg = ConfigFile.new()
	cfg.load(UiArt.settings_path)
	print("[alpha] Options ALPHA 50: chat %.2f other %.2f, section left %s" % [_a(chat), _a(other), cfg.has_section("window_alpha")])
	ok = ok and is_equal_approx(_a(chat), 0.5) and is_equal_approx(_a(other), 0.5) and not cfg.has_section("window_alpha")
	ClassicWindow.set_interface_alpha(100, get_tree())
	print("[alpha] RESULT ", "PASS" if ok else "FAIL")
	get_tree().quit()
