extends Node
## Offline check (reset day C15, 2026-11-05, the client side): a companion's gear hover asks the server for the item's
## full delve ("/companionui delve <row> item <slot>") and shows it in the item hover box once the DetailWindow is
## here; a style's hover the same ("... style <line> <level>"); its stats green when buffed, red when debuffed against
## op 10's base values. A stand-in client and made-up server answers.
##   --skip-login --zone=N --world-mode=1.65 --probe=companion_tips_probe


class FakeClient extends Node:
	var commands: Array = []

	func Command(t: String) -> void:
		commands.append(t)


func _op10(row: int, cur: Array, base: Array) -> PackedByteArray:
	var b := PackedByteArray()
	b.resize(81)
	b[1] = 0x48
	b[2] = 1
	b[3] = 10
	b[4] = row
	b[5] = 20
	for i in 8:
		b.encode_u16(8 + i * 2, int(cur[i]))
		b.encode_u16(63 + i * 2, int(base[i]))
	b.encode_u16(44, 30)
	b.encode_u16(79, 20)
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
	net.gear[0] = {10: {"slot": 10, "model": 4, "color": 0, "level": 20, "quality": 95, "condition": 100,
			"object_type": 3, "icon": 0, "name": "Short Sword", "count": 0}}
	w.open_row(0, 0)
	await get_tree().process_frame
	var cell: Control = null
	for c in w.find_children("*", "", true, false):
		if c.get("slot") == 10 and c.get("item") is Dictionary and not (c.get("item") as Dictionary).is_empty():
			cell = c
	fake.commands.clear()
	cell.notification(Control.NOTIFICATION_MOUSE_ENTER)
	var before = cell._make_custom_tooltip("")
	Server.take_detail({"mode": 0, "caption": "Short Sword", "lines": ["Level 20", "Damage Per Second: 4.5", "Slash"]})
	var after = cell._make_custom_tooltip("")
	print("[ctips] hover sent %s; tooltip before the answer: %s, after: %s" % [fake.commands, before, after != null])
	var ok: bool = fake.commands == ["&companionui delve 0 item 10"] and before == null and after != null
	# a style's hover
	var tip := SrvCompanionWindow.SkillTipLabel.new()
	tip.entry = {"kind": "style", "id": "", "name": "Backstab"}
	tip.server_key = "cs:0:2:4"
	tip.server_cmd = "/companionui delve 0 style 2 4"
	add_child(tip)
	fake.commands.clear()
	tip.notification(Control.NOTIFICATION_MOUSE_ENTER)
	Server.take_detail({"mode": 0, "caption": "Backstab", "lines": ["Endurance cost: Low", "Threat: Low"]})
	var stip = tip._make_custom_tooltip("")
	print("[ctips] style hover sent %s, box %s" % [fake.commands, stip != null])
	ok = ok and fake.commands == ["&companionui delve 0 style 2 4"] and stip != null
	# stats: strength buffed, constitution debuffed, the rest as base
	net.handle(_op10(0, [80, 50, 60, 60, 60, 60, 60, 60], [60, 60, 60, 60, 60, 60, 60, 60]))
	w.show_page(2)
	w.refresh()
	await get_tree().process_frame
	var cols := {}
	for l in w._stats_box.get_children():
		if l is Label and (l as Label).text in ["80", "50"]:
			cols[(l as Label).text] = (l as Label).get_theme_color("font_color")
	print("[ctips] stat colours: 80 -> %s, 50 -> %s" % [cols.get("80"), cols.get("50")])
	ok = ok and cols.get("80") == SrvCompanionWindow.BUFFED and cols.get("50") == CompanionUi.RED
	Server.client = was
	print("[ctips] RESULT ", "PASS" if ok else "FAIL")
	get_tree().quit()
