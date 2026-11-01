extends Control
## Offline (no server), True 1.65 Mode: the innkeeper's hire window fed made-up ops 1 / 3 / 4 as the server sends them -
## two roster rows (one with you, one dead) - then a screenshot (--out=<png>). Checks the roster row layout (owner
## 2026-10-30: MANAGE lay over REVIVE; companions revive at healers: no REVIVE here).

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
	net._own_preview = true                          # (offline: no "ownpreview" command)
	add_child(net)
	var w := SrvHireWindow.new()
	w.net = net
	w.manage = func(_r: int, _p: int): pass
	add_child(w)
	w.build()
	w.visible = false
	var texts := {9: "Companions: 2 of 2 open (next at level 10)", 16: "Osbert", 17: "Armsman 5", 18: "With you",
			19: "Gwendolyn", 20: "Cleric 12", 21: "Dead"}
	for k in texts:
		net.handle(_body(3, func(b):
			b[4] = k
			_put(b, 5, texts[k])))
	for r in [[0, 1, 5, 2, 1, 0, 2 | 4], [1, 2, 12, 6, 1, 1, 4 | 8]]:
		net.handle(_body(4, func(b):
			b[4] = 1
			for i in 6:
				b[5 + i] = r[i]
			b[11] = r[6]))
	net.handle(_body(1, func(b):
		b[4] = 0
		b[5] = 2
		b[6] = 2
		b[7] = 10))
	if "--hire" in OS.get_cmdline_user_args():            # the HIRE A COMPANION page: a Briton armsman, look 2, hair 8
		Server.world_mode = "1.65"
		Fig3Figure._classic = -1
		var hire_texts := {1: "Briton", 2: "Armsman", 3: "Male", 4: "Look 2 of 12", 5: "Hair colour 8 of 8", 6: "Osbert"}
		for k in hire_texts:
			net.handle(_body(3, func(b):
				b[4] = k
				_put(b, 5, hire_texts[k])))
		net.handle(_body(4, func(b):
			b[4] = 0
			b[5] = 1
			b[6] = 0
			b[7] = 2
			b[12] = 7
			b[13] = 8
			b[14] = 32
			b[20] = 1
			for a in OS.get_cmdline_user_args():          # --height=1|2|3: the HEIGHT row ([21], count [22])
				if a.begins_with("--height="):
					b[21] = int(a.split("=")[1])
					b[22] = 3))
		w.show_page(1)
		if "--type-name" in OS.get_cmdline_user_args():  # click the NAME box, type a name, press Enter - as a player
			for i in 10:
				await get_tree().process_frame
			var box: LineEdit = w._name
			var at := box.get_global_rect().get_center()
			for pressed in [true, false]:
				var mb := InputEventMouseButton.new()
				mb.button_index = MOUSE_BUTTON_LEFT
				mb.pressed = pressed
				mb.position = at
				mb.global_position = at
				get_viewport().push_input(mb)
				await get_tree().process_frame
			print("[hire] focus after click: ", get_viewport().gui_get_focus_owner() == box)
			box.select_all()
			for ch in "Brannoc":
				var k := InputEventKey.new()
				k.pressed = true
				k.unicode = ch.unicode_at(0)
				k.keycode = OS.find_keycode_from_string(ch.to_upper())
				get_viewport().push_input(k)
				await get_tree().process_frame
			print("[hire] typed: '%s'" % box.text)
			box.text_submitted.connect(func(t): print("[hire] submitted -> /companionui name ", t))
			var enter := InputEventKey.new()
			enter.pressed = true
			enter.keycode = KEY_ENTER
			get_viewport().push_input(enter)
			await get_tree().process_frame
	for i in 40:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			get_viewport().get_texture().get_image().save_png(a.substr(6))
	print("[hire] visible %s rows %d" % [str(w.visible), net.roster.size()])
	get_tree().quit()
