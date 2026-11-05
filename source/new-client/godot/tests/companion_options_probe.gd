extends Node
## Offline check (reset day C17, 2026-11-05, the client side of S33): the companion window's PETS / SONGS tab from op 14
## rows - shown only for a companion with choices; a Bonedancer's sub-pets with the x/75 count, a minstrel's songs per
## slot and Twist; picking sends the agreed /companionui verb. A stand-in client, made-up rows, a shot to --out.
##   --skip-login --zone=N --world-mode=1.65 --probe=companion_options_probe --out=<dir>


class FakeClient extends Node:
	var commands: Array = []

	func Command(t: String) -> void:
		commands.append(t)


func _op14(row: int, kind: int, slot: int, chosen: int, names: Array, used := 0, cap := 0) -> PackedByteArray:
	var b := PackedByteArray([0, 0x48, 1, 14, row, kind, slot, chosen, names.size()])
	b.resize(13)
	b.encode_u16(9, used)
	b.encode_u16(11, cap)
	for n in names:
		b.append_array(String(n).to_ascii_buffer())
		b.append(0)
	return b


func _ready() -> void:
	var v := get_tree().current_scene
	await get_tree().create_timer(5.0).timeout
	var fake := FakeClient.new()
	add_child(fake)
	var was = Server.client
	Server.client = fake
	var net := CompanionNet.new()
	add_child(net)
	var w := SrvCompanionWindow.new()
	w.net = net
	v.ui.root.add_child(w)
	w.build()
	w.open_row(1, 2)
	await get_tree().process_frame
	var hidden_without: bool = not (w._tabs[4] as Button).visible
	# row 0: a Bonedancer (sub-pets), row 1: a minstrel (songs + Twist)
	for m in [_op14(0, 3, 1, 1, ["Automatic", "Swordsman", "Archer", "Healer"], 30, 75),
			_op14(0, 3, 2, 0, ["Automatic", "Swordsman", "Archer", "Healer"], 30, 75),
			_op14(0, 3, 3, 2, ["Automatic", "Swordsman", "Archer", "Healer"], 30, 75),
			[0, 0x48, 1, 14, 0, 0xFF],
			_op14(1, 4, 1, 0, ["Automatic", "Battle Song", "Power Song"]),
			_op14(1, 4, 2, 1, ["Automatic", "Battle Song", "Power Song"]),
			_op14(1, 4, 3, 0, ["Automatic", "Speed Song"]),
			_op14(1, 4, 4, 0, ["No", "Yes"]),
			[0, 0x48, 1, 14, 1, 0xFF]]:
		net.handle(PackedByteArray(m))
	await get_tree().process_frame
	var shown_with: bool = (w._tabs[4] as Button).visible
	w.show_page(4)
	await get_tree().process_frame
	fake.commands.clear()
	var buttons := []
	var lists := []
	for c in w._options_box.get_children():
		if c is OptionButton:
			lists.append(c)
		elif c is Button:
			buttons.append(c)
	(buttons[1] as Button).pressed.emit()                              # Twist: "Yes"
	(lists[0] as OptionButton).item_selected.emit(2)                   # in combat: Power Song
	print("[opts] tab hidden without choices %s, shown with %s; rows %d lists %d buttons %d; sent %s" % [hidden_without,
			shown_with, (net.options.get(1, []) as Array).size(), lists.size(), buttons.size(), fake.commands])
	var ok: bool = hidden_without and shown_with and fake.commands == ["&companionui song 1 4 1", "&companionui song 1 1 2"]
	await get_tree().create_timer(0.3).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(String(v.args.get("out", "user://")) + "/companion_options_songs.png")
	# the Bonedancer's tab
	w.open_row(0, 4)
	fake.commands.clear()
	await get_tree().process_frame
	var caps := []
	lists.clear()
	for c in w._options_box.get_children():
		if c is Label and (c as Label).text.begins_with("SUB-PETS"):
			caps.append((c as Label).text)
		if c is OptionButton:
			lists.append(c)
	(lists[2] as OptionButton).item_selected.emit(3)                   # sub-pet 3: Healer
	print("[opts] bonedancer: %s, lists %d, sent %s" % [caps, lists.size(), fake.commands])
	ok = ok and caps == ["SUB-PETS 30 / 75"] and lists.size() == 3 and fake.commands.has("&companionui subpet 0 3 3")
	await get_tree().create_timer(0.3).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(String(v.args.get("out", "user://")) + "/companion_options_bd.png")
	Server.client = was
	print("[opts] RESULT ", "PASS" if ok else "FAIL")
	get_tree().quit()
