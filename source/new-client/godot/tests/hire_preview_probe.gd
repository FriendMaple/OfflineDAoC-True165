extends Node
## Offline look at GitHub issue #9: the innkeeper's hire window preview for a Hibernian Druid (Celt / Sylvan, male and
## female) - the hire page's numbers as the server sends them; a shot of each.
##   --skip-login --zone=N --world-mode=1.65 --probe=hire_preview_probe --out=<dir>


func _ready() -> void:
	var v := get_tree().current_scene
	await get_tree().create_timer(6.0).timeout
	var out := String(v.args.get("out", "user://"))
	var w = v.ui.companion_hire
	if w == null:                                    # (built only for the server's game: built here the same way)
		var cn := CompanionNet.new()
		v.ui.add_child(cn)
		w = SrvHireWindow.new()
		w.net = cn
		w.manage = func(_r: int, _p: int): pass
		v.ui.root.add_child(w)
		w.build()
	var net = w.net
	var cases := [["celt_m", 9, 0, 535], ["celt_f", 9, 1, 310], ["sylvan_m", 15, 0, 700], ["sylvan_f", 15, 1, 714]]
	for c in cases:
		net.hire = {"race": c[1], "gender": c[2], "class": 40, "face": 0, "faces": 7, "hair": 0, "hairs": 1,
				"hair_color": 0, "model": c[3], "cost": 100, "enabled": true, "height": 2, "colors": 0}
		w.show_window()
		w.show_page(1)
		w.refresh()
		await get_tree().create_timer(2.5).timeout
		await RenderingServer.frame_post_draw
		var r: Rect2 = w.get_global_rect()
		get_viewport().get_texture().get_image().get_region(Rect2i(r)).save_png(out + "/hire_%s.png" % c[0])
		var meshes := []
		if w._figure:
			for mi in w._figure.find_children("*", "MeshInstance3D", true, false):
				if (mi as MeshInstance3D).is_visible_in_tree():
					meshes.append(String(mi.name))
		print("[hire] %s model %d: figure %s, %d visible meshes %s" % [c[0], c[3], w._figure != null, meshes.size(), meshes.slice(0, 8)])
	get_tree().quit()
