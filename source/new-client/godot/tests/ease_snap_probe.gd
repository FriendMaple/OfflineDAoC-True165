extends Node
## Offline check (reset day C13, 2026-11-05: in lag companions snapped onto you): an update that puts a living a few
## metres from where it is drawn - here a stopped companion 4 m off - is walked off over a moment (ServerWorld._ease),
## never jumped; it ends on the server's place.
##   --skip-login --zone=N --world-mode=1.65 --probe=ease_snap_probe


func _ready() -> void:
	var v := get_tree().current_scene
	await get_tree().create_timer(5.0).timeout
	var sw := ServerWorld.new()
	sw.zone = v.zone
	sw.player = v.player
	v.add_child(sw)
	var p0: Vector3 = v.player.global_position + Vector3(3, 0, 0)
	var spawn := {"id": "srv900", "oid": 900, "name": "Companion", "realm": 1, "flags": 0, "level": 10, "model": "0",
			"pos": [p0.x, p0.y, p0.z], "heading": 0, "temp": true}
	var st := NpcState.new(sw.states.size(), spawn, {"race": "briton"})
	st.pos = p0
	sw.states.append(st)
	sw.by_oid[900] = st
	st.alive = true
	st.health = 1.0
	st.seen_at = Time.get_ticks_msec()
	sw._mover[st] = {"speed": 0.0, "dest": null, "target": 0, "flying": false, "sy": p0.y,
			"ease": Vector3(4, 0, 0)}                                   # (the update said: 4 m further, stopped)
	var goal := p0 + Vector3(4, 0, 0)
	var biggest := 0.0
	var last := st.pos
	for i in 60:
		sw._physics_body(1.0 / 60.0)
		biggest = maxf(biggest, Vector2(st.pos.x - last.x, st.pos.z - last.z).length())
		last = st.pos
	var left := Vector2(st.pos.x - goal.x, st.pos.z - goal.z).length()
	print("[ease] 4 m gap: biggest one-frame move %.3f m, %.3f m from the server's place after 1 s (60 frames), mode %d" % [biggest, left, st.mode])
	var ok := biggest < 0.5 and left < 0.05
	print("[ease] RESULT ", "PASS" if ok else "FAIL")
	get_tree().quit()
