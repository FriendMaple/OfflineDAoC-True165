extends Node
## Offline check (reset day C7, 2026-11-05): a death plays once - turning the body into a corpse (the server's removal,
## a right-clicked loot bag) does not start it again; a body sent already dead lies at the death's last frame at once.
##   --skip-login --zone=N --world-mode=1.65 --probe=death_once_probe


func _ready() -> void:
	var v := get_tree().current_scene
	await get_tree().create_timer(8.0).timeout
	var views := []
	for k in v.npcs.active:
		var n: Npc = v.npcs.active[k]
		if n.anim and n.anim.has_animation("death") and n.state.alive:
			views.append(n)
		if views.size() == 2:
			break
	if views.size() < 2:
		print("[death] FAIL: no two npcs with a death clip")
		get_tree().quit()
		return
	var a: Npc = views[0]
	v.player.global_position = a.global_position + Vector3(3, 0.5, 0)
	await get_tree().create_timer(1.0).timeout
	a.state.health = 0.0
	a.state.respawn_left = 1e9
	a.state.corpse_left = 1e9
	a.state.alive = false
	a.state.mode = NpcState.Mode.DEAD
	a.play_death(true)
	await get_tree().create_timer(0.4).timeout
	var p1 := a.anim.current_animation_position
	print("[death] before corpse: died=%s pos %.2f playing %s" % [a._died, a.anim.current_animation_position, a.anim.is_playing()])
	a.make_corpse()
	print("[death] right after corpse: pos %.2f" % a.anim.current_animation_position)
	for i in 3:
		await get_tree().process_frame
		print("[death] frame %d: pos %.2f clip %s" % [i, a.anim.current_animation_position, a.anim.current_animation])
	var p2 := a.anim.current_animation_position
	print("[death] dying %.2f s in; after make_corpse %.2f s (clip %s)" % [p1, p2, a.anim.current_animation])
	var ok := p2 >= p1 - 0.01
	var b: Npc = views[1]
	b.state.health = 0.0
	b.state.respawn_left = 1e9
	b.state.corpse_left = 1e9
	b.state.alive = false
	b.state.mode = NpcState.Mode.DEAD
	b.play_death(false, true)
	await get_tree().process_frame
	var len := b.anim.current_animation_length
	print("[death] sent dead: at %.2f of %.2f s" % [b.anim.current_animation_position, len])
	ok = ok and b.anim.current_animation_position >= len - 0.05
	print("[death] RESULT ", "PASS" if ok else "FAIL")
	get_tree().quit()
