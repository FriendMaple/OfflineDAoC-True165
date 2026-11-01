extends Control
## Offline (no server): the Horn of Rallying window fed made-up ops 20 - 23 as the server sends them, then a screenshot
## (--out=<png>). Checks the layout, states, countdowns and the message line.

func _body(op: int, fill: Callable) -> PackedByteArray:
	var b := PackedByteArray()
	b.resize(128)
	b[1] = 0x48
	b[2] = 1
	b[3] = op
	fill.call(b)
	return b


static func _put(b: PackedByteArray, at: int, s: String) -> void:
	var a := s.to_ascii_buffer()
	for i in a.size():
		b[at + i] = a[i]


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.color = Color(0.2, 0.22, 0.25)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var net := CompanionNet.new()
	add_child(net)
	var w := SrvHornWindow.new()
	w.net = net
	add_child(w)
	w.build()
	w.visible = false
	var rows := [[0, 0, 0, 12, "Golestandt", "Ready"], [1, 1, 0, 24, "Caer Sidi", "Raid rally - Muster"],
			[2, 2, 2520, 0, "Gjalpinulva", "Respawning: 42 min"], [3, 3, 5400, 0, "Darkness Falls", "Cooling down"],
			[4, 4, 0, 0, "Tuscaran Glacier", "Not in 1.65"]]
	net.handle(_body(20, func(b):
		b[4] = rows.size()
		b[5] = 3
		_put(b, 6, "THE HORN OF RALLYING")))
	for r in rows:
		net.handle(_body(21, func(b):
			b[4] = r[0]
			b[5] = r[1]
			b[6] = int(r[2]) & 0xFF
			b[7] = (int(r[2]) >> 8) & 0xFF
			b[10] = 8 if r[1] == 1 else 0
			b[12] = r[3]
			_put(b, 14, r[4])
			_put(b, 62, r[5])))
	net.handle(_body(23, func(b): _put(b, 4, "You sound the Horn of Rallying! The realm musters for Golestandt.")))
	for i in 20:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			get_viewport().get_texture().get_image().save_png(a.substr(6))
	print("[horn] visible %s rows %d" % [str(w.visible), (net.horn.rows as Array).size()])
	get_tree().quit()
