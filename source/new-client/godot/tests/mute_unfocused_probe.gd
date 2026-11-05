extends Node
## Offline check (reset day C6, 2026-11-05): the sound mutes while the game is not the focused window (on by default)
## and comes back on return; with the option off it never mutes.
##   --skip-login --zone=N --world-mode=1.65 --probe=mute_unfocused_probe


func _ready() -> void:
	await get_tree().create_timer(4.0).timeout
	var ok := BootSettings.mute_unfocused
	print("[mute] default on: ", BootSettings.mute_unfocused)
	BootSettings.notification(NOTIFICATION_APPLICATION_FOCUS_OUT)
	var out := AudioServer.is_bus_mute(0)
	BootSettings.notification(NOTIFICATION_APPLICATION_FOCUS_IN)
	var back := AudioServer.is_bus_mute(0)
	print("[mute] focus out -> muted %s, focus in -> muted %s" % [out, back])
	ok = ok and out and not back
	BootSettings.set_mute_unfocused(false)
	BootSettings.notification(NOTIFICATION_APPLICATION_FOCUS_OUT)
	var off := AudioServer.is_bus_mute(0)
	print("[mute] option off, focus out -> muted %s" % off)
	ok = ok and not off
	BootSettings.notification(NOTIFICATION_APPLICATION_FOCUS_IN)
	BootSettings.mute_unfocused = true
	print("[mute] RESULT ", "PASS" if ok else "FAIL")
	get_tree().quit()
