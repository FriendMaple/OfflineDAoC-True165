extends SceneTree
## Offline check of ServerWorld._ride_lost (owner 2026-10-31: gamebots "teleporting behind the horse"): a stable
## horse drawn far behind its updates keeps its rider; a rider whose server place really left its horse is let go
## after RIDE_APART_MS; a horse whose updates stopped lets its rider go once they are apart.
##   godot --headless --path godot -s res://tests/ride_lost_check.gd

func _initialize() -> void:
	var w = load("res://game/net/server_world.gd").new()       # (loaded at run time: -s scripts compile before autoloads)
	var ns = load("res://game/npcs/npc_state.gd")
	var rider = ns.new(0, {"name": "Bot", "pos": [0, 0, 0], "heading": 0}, {})
	var steed = ns.new(1, {"name": "Horse", "pos": [0, 0, 0], "heading": 0}, {})
	var now := 100000
	var ok := true
	# 1. on the route: both updates carry the same server place; the horse is DRAWN 40 m behind it
	w._mover[rider] = {"srv_pos": Vector3(100, 0, 0), "srv_at": now - 200}
	w._mover[steed] = {"srv_pos": Vector3(92, 0, 0), "srv_at": now - 400, "speed": 1500.0}   # 0.2 s older, 37 m/s
	steed.pos = Vector3(60, 0, 0)
	for t in [0, 1000, 2000, 4000]:
		if w._ride_lost(7, rider, steed, now + t):
			ok = false
			print("FAIL 1: seated rider dropped at +", t)
	# 2. really apart (a dismount never received): 50 m between the two server places
	w._mover[rider] = {"srv_pos": Vector3(150, 0, 0), "srv_at": now - 100}
	w._mover[steed] = {"srv_pos": Vector3(100, 0, 0), "srv_at": now - 100, "speed": 0.0}
	var first: bool = w._ride_lost(8, rider, steed, now)
	w._mover[rider]["srv_at"] = now + 3000
	w._mover[steed]["srv_at"] = now + 3000
	var later: bool = w._ride_lost(8, rider, steed, now + 3100)
	if first or not later:
		ok = false
		print("FAIL 2: apart first=", first, " after 3 s=", later)
	# 3. the horse's updates stopped 8 s ago at a zone edge, the rider's go on 30 m away
	w._mover[rider] = {"srv_pos": Vector3(130, 0, 0), "srv_at": now - 100}
	w._mover[steed] = {"srv_pos": Vector3(100, 0, 0), "srv_at": now - 8000, "speed": 1500.0}
	steed.pos = Vector3(100, 0, 0)
	w._ride_lost(9, rider, steed, now)
	w._mover[rider]["srv_at"] = now + 3000
	if not w._ride_lost(9, rider, steed, now + 3100):
		ok = false
		print("FAIL 3: rider kept on a silent horse")
	print("[ride_lost_check] ", "ok" if ok else "FAILED")
	w.free()
	quit()
