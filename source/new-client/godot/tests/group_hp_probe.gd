extends SceneTree
## Headless check of GitHub issue #10: a group member's health survives the group window list coming again, and a
## dead member (GroupMemberUpdate status 0x01) reads 0 health.
##   Godot --headless --path godot -s res://tests/group_hp_probe.gd


func _initialize() -> void:
	await process_frame
	var S = root.get_node("Server")
	var P = root.get_node("PlayerData")
	S.me_oid = 1
	var members := [{"oid": 1, "name": "Me", "class_name": "Cleric", "level": 9},
			{"oid": 7, "name": "Isolde", "class_name": "Cleric", "level": 9}]
	S._on_world_inner("group", {"members": members})
	S._on_world_inner("group_update", {"list": [{"index": 1, "hp": 0, "power": 40, "end": 90, "status": 1}]})
	var after_update: float = P.group[0].hp
	members[1]["level"] = 10                         # (a level-up: the server sends the window list again)
	S._on_world_inner("group", {"members": members})
	var g: Dictionary = P.group[0]
	print("[group] after the dead update hp %.2f; after the list again: hp %.2f power %.2f status %d level %d" % [
			after_update, g.hp, g.power, int(g.status), int(g.level)])
	print("[group] RESULT ", "PASS" if after_update == 0.0 and g.hp == 0.0 and absf(g.power - 0.4) < 0.01
			and int(g.status) == 1 and int(g.level) == 10 else "FAIL")
	quit()
