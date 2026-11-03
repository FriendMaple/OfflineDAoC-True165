extends Node
## Offline check (owner 2026-11-03: the account vault keepers, a True 1.65 QoL exception): the keeper's greeting and its
## HouseVault window (4) with page one's items open the ACCOUNT VAULT window (vault.bmp) with its FIRST / SECOND page
## buttons, even with the companion-gear filter active; a later move into slot 151 is kept. Shot of the window.
##   --skip-login --zone=N --world-mode=1.65 --probe=account_vault_probe --out=<dir>


func _item(slot: int, nm: String, model: int) -> Dictionary:
	return {"slot": slot, "name": nm, "model": model, "level": 10, "value1": 0, "value2": 0, "hand": 0, "type_damage": 0,
			"object_type": 0, "weight": 1, "condition": 100, "durability": 100, "quality": 99, "bonus": 0, "extension": 0,
			"effect": 0, "count": 1, "flag": 0, "item_type": 40}


func _ready() -> void:
	var v := get_tree().current_scene
	await get_tree().create_timer(6.0).timeout
	var out := String(v.args.get("out", "user://"))
	var ui = v.ui
	if ui.vault == null:
		print("[acct] no vault window")
		get_tree().quit()
		return
	Server.world_mode = "1.65"
	CompanionNet.asked_gear_at = Time.get_ticks_msec()          # (the companion-gear filter active)
	# the vault window is hooked to Server.vault_open only in the server's game: hooked here the same way
	Server.vault_open.connect(func(title: String, first: int, count: int): ui.vault.open_range(title, first, count))
	Server.playing = true
	Server.active = true                                       # (as in the server game: the inventory follows its packets)
	Server._on_world_inner("message", {"text": "Greetings Tester, nice meeting you. I am happy to offer you my services. You can browse the [first] or [second] page of your Account Vault.", "type": 0})
	Server.on_inventory({"window": 4, "weapon_slots": 0, "items": [_item(150, "Sword of Tests", 1), _item(152, "Shield of Tests", 59)]})
	await get_tree().create_timer(0.5).timeout
	var title: String = ui.vault._title.text
	var buttons: bool = ui.vault._acct.visible
	var has150 := Server.inv.has(150)
	Server.on_inventory({"window": 0, "weapon_slots": 0, "items": [_item(151, "Moved In", 2)]})   # a move from the backpack, later
	var has151 := Server.inv.has(151)
	Server.active = true                                       # (drawn as in the server's game: its slots)
	ui.vault.refresh()
	await get_tree().create_timer(0.5).timeout
	await RenderingServer.frame_post_draw
	var r: Rect2 = ui.vault.get_global_rect().grow_side(SIDE_BOTTOM, 40.0 * ui.vault.get_global_transform().get_scale().y)
	get_viewport().get_texture().get_image().get_region(Rect2i(r)).save_png(out + "/account_vault.png")
	Server.active = false
	print("[acct] title '%s', page buttons %s, slot 150 %s, moved-in 151 %s" % [title, buttons, has150, has151])
	ui.vault.hide_window()
	print("[acct] closed: account_vault_open %s" % Server.account_vault_open)
	print("[acct] RESULT ", "PASS" if title.begins_with("ACCOUNT VAULT") and buttons and has150 and has151 and not Server.account_vault_open else "FAIL")
	Server.playing = false
	get_tree().quit()
