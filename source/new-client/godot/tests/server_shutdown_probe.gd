extends Node
## Test helper: Claude's own GM test account asks the server to shut down cleanly (the admin /shutdown <seconds>: it
## saves the world first) - for stopping the local test server after a live test, instead of killing the process.
##   Godot --path godot res://tests/server_session.tscn -- --server=127.0.0.1 --account=<a> --password=<p>
##       --char=Claudeperf --world-mode=1.65 --probe=server_shutdown_probe


func _ready() -> void:
	await get_tree().create_timer(4.0).timeout
	print("[shutdown] asking the server to shut down in 15 s")
	Server.command("/shutdown 15")
	await get_tree().create_timer(3.0).timeout
	get_tree().quit()
