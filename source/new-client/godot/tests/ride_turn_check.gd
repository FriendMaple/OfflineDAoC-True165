extends SceneTree
## Offline check (owner 2026-11-03: N Tir na Nog -> Druim Ligen, the horse went sideways most of the ride): a route that
## turns 119 degrees - the next point is behind the drawn horse, and the server already faces it. The drawn horse must
## turn and follow (facing within 20 degrees of the new leg, close to the server's place); an overshoot (the point
## passed, the server still facing the same way) must not turn it around.
##   godot --headless --path godot -s res://tests/ride_turn_check.gd

const DT := 1.0 / 60.0
const SPEED := 1500.0
const M := 0.025


func _leg_yaw(dir: Vector3) -> float:
	return atan2(dir.x, dir.z)


func _initialize() -> void:
	var w = load("res://game/net/server_world.gd").new()
	var ns = load("res://game/npcs/npc_state.gd")
	var steed = ns.new(1, {"name": "Horse", "pos": [0, 0, 0], "heading": 0}, {"figure": "gryphon"})
	steed.info = {"figure": "gryphon"}
	var mv := {"speed": SPEED, "sy": 0.0, "err": Vector3.ZERO, "dest": null}
	w._mover[steed] = mv
	# --- a 119 degree turn at the corner
	var leg1 := Vector3(1, 0, 0)
	var leg2 := leg1.rotated(Vector3.UP, deg_to_rad(119.0))
	var corner := leg1 * 300.0
	steed.pos = Vector3.ZERO
	steed.yaw = _leg_yaw(leg1)
	var srv := Vector3.ZERO
	var t := 0.0
	var next_upd := 0.0
	var after := []
	while t < 25.0:
		var on_leg2 := srv.distance_to(Vector3.ZERO) >= 300.0 or t > 10.0
		var dir := leg2 if on_leg2 else leg1
		srv += dir * SPEED * M * 0.8 * DT
		if t >= next_upd:
			next_upd = t + 0.1
			mv["dest"] = corner + leg2 * 600.0 if on_leg2 else corner
			mv["heading"] = _leg_yaw(dir)
			var e: Vector3 = srv - steed.pos
			e.y = 0.0
			mv["err"] = e
		w._move_ridden(steed, mv, SPEED * M * DT, DT)
		if on_leg2 and t > 14.0:
			after.append([absf(rad_to_deg(angle_difference(steed.yaw, _leg_yaw(leg2)))), steed.pos.distance_to(srv)])
		t += DT
	var worst_yaw := 0.0
	var worst_gap := 0.0
	for a in after:
		worst_yaw = maxf(worst_yaw, a[0])
		worst_gap = maxf(worst_gap, a[1])
	print("[turn] 119-degree turn: after it, facing off the new leg by at most %.1f deg, at most %.1f m from the server" % [worst_yaw, worst_gap])
	# --- an overshoot: the point just passed, the server still facing the same way
	steed.pos = Vector3(310, 0, 0)
	steed.yaw = _leg_yaw(leg1)
	mv["dest"] = Vector3(300, 0, 0)
	mv["heading"] = _leg_yaw(leg1)
	mv["err"] = Vector3.ZERO
	for k in 60:
		w._move_ridden(steed, mv, SPEED * M * DT, DT)
	var turned := absf(rad_to_deg(angle_difference(steed.yaw, _leg_yaw(leg1))))
	print("[turn] overshoot: turned %.1f deg (should stay ~0)" % turned)
	print("[turn] RESULT ", "PASS" if worst_yaw < 20.0 and worst_gap < 15.0 and turned < 5.0 else "FAIL")
	w.free()
	quit()
