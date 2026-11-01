extends Control
## Offline: the map window's traveler's inn markers (owner 2026-10-31) - each inn zone's map and its realm map.
##   godot --path godot res://tests/map_inn_shot.tscn -- --world-mode=1.65 --out=<prefix>

func _ready() -> void:
	var out := "user://mapinn"
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			out = a.split("=", true, 1)[1]
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.color = Color(0.15, 0.15, 0.17)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var mw := MapWindow.new()
	mw.setup("map", "interact", Rect2(), Vector2(40, 40))
	add_child(mw)
	mw.build()
	mw.size = Vector2(520, 560)
	mw.show_window()
	for shot in [["zone", 9, 1], ["zone", 102, 100], ["zone", 202, 200]]:
		mw._show({"kind": "zone", "id": shot[1]}, true)
		await _frames(4)
		await _shot("%s_zone%d.png" % [out, shot[1]])
		mw._show({"kind": "region", "id": shot[2]}, true)
		await _frames(4)
		await _shot("%s_region%d.png" % [out, shot[2]])
	get_tree().quit()


func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame


func _shot(path: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(path)
	print("wrote ", path)
