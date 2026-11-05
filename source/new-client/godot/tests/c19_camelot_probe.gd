extends Node
## Live check (reset day C19, 2026-11-05: "Camelot stutter"): Claude's own test character (GM test account) jumps to
## Camelot's market (region 10, the densest NPC spot: dyemasters, guards, merchants) and runs walk_perf's loop there -
## every frame over 33 ms listed with what was being built. Read only: nothing in the world is changed.
##   Godot --path godot res://tests/server_session.tscn -- --server=127.0.0.1 --account=<a> --password=<p>
##       --char=Claudeperf --world-mode=1.65 --probe=c19_camelot_probe --secs=40 --radius=20


func _ready() -> void:
	await get_tree().create_timer(6.0).timeout
	print("[c19] jumping to Camelot's market")
	Server.command("/jump to 35500 30900 8000 10")
	await get_tree().create_timer(15.0).timeout                 # (the region change, the city and its NPCs in)
	var v := get_tree().current_scene
	print("[c19] at ", v.player.global_position if v and v.get("player") else "?", " zone ", v.zone.info.get("name", "?") if v and v.get("zone") else "?")
	var w: Node = load("res://tests/walk_perf.gd").new()
	add_child(w)
