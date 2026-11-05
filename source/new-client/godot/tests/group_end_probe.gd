extends Node
## Offline check (reset day C5, 2026-11-05): the group page draws each member's endurance between health and power.
## A fake member at 80% health, 40% endurance, 60% power; a shot of the page to --out.
##   --skip-login --zone=N --world-mode=1.65 --probe=group_end_probe --out=<dir>


func _ready() -> void:
	var v := get_tree().current_scene
	await get_tree().create_timer(6.0).timeout
	PlayerData.group = [{"name": "Testmember", "class_name": "Minstrel", "level": 20, "hp": 0.8, "end": 0.4,
			"power": 0.6, "effects": [], "status": 0, "oid": 999}]
	PlayerData.group_changed.emit()
	v.ui._set_sheet("group")
	v.ui._collapse(false)
	v.ui.right_panel.show_window()
	await get_tree().create_timer(1.5).timeout
	PlayerData.group = [{"name": "Testmember", "class_name": "Minstrel", "level": 20, "hp": 0.8, "end": 0.4,
			"power": 0.6, "effects": [], "status": 0, "oid": 999}]       # (again: offline the game's own group may reset it)
	PanelSheets.update_group(v.ui._sheet_body)
	await get_tree().process_frame
	var ends := []
	for n in v.ui.find_children("End", "TextureRect", true, false):
		if (n as Control).is_visible_in_tree():
			ends.append(roundi((n as Control).size.x))
	print("[c5] visible endurance lines (widths): ", ends)
	print("[c5] rows: ", PlayerData.group_rows().size(), " End nodes: ", v.ui.find_children("End", "", true, false).size(),
			" body visible ", v.ui._sheet_body.is_visible_in_tree(), " tab ", v.ui.sheet_tab, " collapsed ", v.ui._collapsed,
			" member_0 ", v.ui._sheet_body.get_node_or_null("member_0"))
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(String(v.args.get("out", "user://")) + "/group_end.png")
	print("[c5] RESULT ", "PASS" if ends.has(28) else "FAIL")
	get_tree().quit()
