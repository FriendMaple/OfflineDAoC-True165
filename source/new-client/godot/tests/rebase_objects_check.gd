extends Node
## Offline: a seamless border crossing moves the server's ground objects and the movers' server places with the world
## (owner 2026-10-31: floating objects after a horse ride - ServerWorld had no rebase).
##   godot --headless --path godot res://tests/rebase_objects_check.tscn

func _ready() -> void:
	var w = load("res://game/net/server_world.gd").new()
	add_child(w)
	var holder := Node3D.new()
	w.add_child(holder)
	holder.position = Vector3(1700.0, 50.0, 300.0)
	w.objects[7] = holder
	var st = load("res://game/npcs/npc_state.gd").new(0, {"name": "bot", "pos": [1690.0, 50.0, 300.0], "heading": 0}, {})
	w.states.append(st)
	w._mover[st] = {"speed": 200.0, "dest": Vector3(1720.0, 50.0, 300.0), "srv_pos": Vector3(1690.0, 50.0, 300.0), "sy": 50.0, "target": 0}
	var d := Vector3(1638.4, 0.0, 0.0)                       # crossed east into the next zone
	w.rebase(d)
	var ok: bool = holder.position.is_equal_approx(Vector3(61.6, 50.0, 300.0)) \
			and (w._mover[st].dest as Vector3).is_equal_approx(Vector3(81.6, 50.0, 300.0)) \
			and (w._mover[st].srv_pos as Vector3).is_equal_approx(Vector3(51.6, 50.0, 300.0)) \
			and st.pos.is_equal_approx(Vector3(51.6, 50.0, 300.0))
	print("object ", holder.position, "  dest ", w._mover[st].dest, "  livings ", st.pos)
	print("[rebase_objects_check] ", "ok" if ok else "FAILED")
	get_tree().quit()
