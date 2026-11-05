extends Node
## Offline check (reset day C9, 2026-11-05): a dead monster's body whose removal never came goes after DEAD_BODY_MS;
## a dead character (gamebot / companion waiting for a rez) stays while the server keeps sending it, and goes once it
## stops. A stand-in ServerWorld with states made by hand.
##   --skip-login --zone=N --world-mode=1.65 --probe=dead_body_drop_probe


func _state(sw: ServerWorld, oid: int, nm: String, race: bool) -> NpcState:
	var spawn := {"id": "srv%d" % oid, "oid": oid, "name": nm, "realm": 0, "flags": 0, "level": 10, "model": "0",
			"pos": [0, 0, 0], "heading": 0, "temp": true}
	var st := NpcState.new(sw.states.size(), spawn, {"race": "briton"} if race else {})
	sw.states.append(st)
	sw.by_oid[oid] = st
	sw._mover[st] = {}
	st.seen_at = Time.get_ticks_msec()
	sw._set_health(st, 100)
	sw._set_health(st, 0)
	return st


func _ready() -> void:
	var v := get_tree().current_scene
	await get_tree().create_timer(5.0).timeout
	var sw := ServerWorld.new()
	sw.zone = v.zone
	sw.player = v.player
	v.add_child(sw)
	var wolf := _state(sw, 701, "wolf", false)
	var bot := _state(sw, 702, "Gamebot", true)
	var now := Time.get_ticks_msec()
	sw._drop_stale(10.0)
	var ok := sw.by_oid.has(701) and sw.by_oid.has(702)
	print("[body] just died: wolf kept %s, gamebot kept %s" % [sw.by_oid.has(701), sw.by_oid.has(702)])
	sw._mover[wolf]["dead_at"] = now - ServerWorld.DEAD_BODY_MS - 1000          # (as if 46 s ago)
	sw._mover[bot]["dead_at"] = now - ServerWorld.DEAD_BODY_MS - 1000
	bot.seen_at = now                                                         # (the server still sends the gamebot)
	sw._drop_stale(10.0)
	print("[body] 46 s later: wolf kept %s, gamebot kept %s (still sent)" % [sw.by_oid.has(701), sw.by_oid.has(702)])
	ok = ok and not sw.by_oid.has(701) and sw.by_oid.has(702)
	bot.seen_at = now - ServerWorld.STALE_MS - 1000
	sw._drop_stale(10.0)
	print("[body] gamebot no longer sent: kept %s" % sw.by_oid.has(702))
	ok = ok and not sw.by_oid.has(702)
	print("[body] RESULT ", "PASS" if ok else "FAIL")
	get_tree().quit()
