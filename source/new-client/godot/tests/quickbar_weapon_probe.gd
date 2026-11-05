extends Node
## Offline check (reset day C11, 2026-11-05): a worn weapon / instrument used from the quickbar is sent as a click
## (UseSlot type 0 - the server readies that weapon set only then); a backpack item stays a use (type 1).
##   --skip-login --zone=N --world-mode=1.65 --probe=quickbar_weapon_probe


class FakeClient extends Node:
	var sent: Array = []

	func UseSlot(_x, _y, _z, _speed, _heading, _in_view, slot: int, type: int) -> void:
		sent.append([slot, type])


func _ready() -> void:
	var v := get_tree().current_scene
	await get_tree().create_timer(5.0).timeout
	var fake := FakeClient.new()
	add_child(fake)
	var was = Server.client
	Server.client = fake
	for id in ["srv:10", "srv:11", "srv:12", "srv:13", "srv:45"]:
		Server.use_entry(id, v.player, int(v.zone.info.id), true)
	Server.client = was
	print("[qbw] sent [slot, type]: ", fake.sent)
	var ok: bool = fake.sent == [[10, 0], [11, 0], [12, 0], [13, 0], [45, 1]]
	print("[qbw] RESULT ", "PASS" if ok else "FAIL")
	get_tree().quit()
