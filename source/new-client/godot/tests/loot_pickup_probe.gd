extends Node
## Offline check (reset day C8, 2026-11-05): the Pick Up Loot key takes the nearest loot in the server's reach (256
## units) - one a press, never a gravestone, nothing out of reach - with no pointing or targeting; a right click over
## loot is the loot's (ServerWorld.loot_under). A stand-in ServerWorld with fake ground objects and a stand-in client
## that records what would be sent.
##   --skip-login --zone=N --world-mode=1.65 --probe=loot_pickup_probe


class FakeClient extends Node:
	var sent: Array = []

	func Target(oid: int, _flags: int) -> void:
		sent.append("Target %d" % oid)

	func PickUp(_x: int, _y: int, oid: int) -> void:
		sent.append("PickUp %d" % oid)

	func Interact(oid: int, _x: int, _y: int) -> void:
		sent.append("Interact %d" % oid)


func _holder(sw: ServerWorld, oid: int, nm: String, model: int, at: Vector3) -> Node3D:
	var h := StaticBody3D.new()
	h.collision_layer = ServerWorld.OBJECT_PICK
	var cs := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(0.6, 0.6, 0.6)
	cs.shape = box
	h.add_child(cs)
	h.set_meta("name", nm)
	h.set_meta("model", model)
	h.set_meta("server_object", oid)
	sw.add_child(h)
	h.global_position = at
	sw.objects[oid] = h
	return h


func _ready() -> void:
	var v := get_tree().current_scene
	await get_tree().create_timer(6.0).timeout
	var fake := FakeClient.new()
	add_child(fake)
	var was_client = Server.client
	Server.client = fake
	var sw := ServerWorld.new()
	sw.zone = v.zone
	sw.player = v.player
	v.add_child(sw)
	var p: Vector3 = v.player.global_position
	_holder(sw, 101, "Adventurer's Grave", 0, p + Vector3(1, 0, 0))     # nearest, but a gravestone
	_holder(sw, 102, "bag of coins", 488, p + Vector3(0, 0, 3))
	_holder(sw, 103, "short sword", 4, p + Vector3(-5, 0, 0))
	_holder(sw, 104, "studded boots", 50, p + Vector3(0, 0, -9))       # out of reach (6.4 m)
	var ok := true
	sw.pick_up_nearest_loot()
	print("[loot] 1st press: ", fake.sent)
	ok = ok and fake.sent.has("PickUp 102")
	sw.objects.erase(102)                                                # (the server took it away)
	fake.sent.clear()
	sw.pick_up_nearest_loot()
	print("[loot] 2nd press: ", fake.sent)
	ok = ok and fake.sent.has("PickUp 103")
	sw.objects.erase(103)
	fake.sent.clear()
	sw.pick_up_nearest_loot()
	print("[loot] 3rd press (only the grave and a far item left): ", fake.sent)
	ok = ok and fake.sent.is_empty()
	# a right click over loot: a bag right in the middle of the view
	var cam: Camera3D = v.player.camera
	var mid := get_viewport().get_visible_rect().size * 0.5
	var at := cam.project_ray_origin(mid) + cam.project_ray_normal(mid) * 4.0
	var bag := _holder(sw, 105, "bag of coins", 488, at)
	await get_tree().physics_frame
	await get_tree().physics_frame
	var over_bag := sw.loot_under(cam, mid)
	bag.set_meta("name", "Adventurer's Grave")
	var over_grave := sw.loot_under(cam, mid)
	print("[loot] right click over a bag: loot %s; over a grave: loot %s" % [over_bag, over_grave])
	ok = ok and over_bag and not over_grave
	Server.client = was_client
	print("[loot] RESULT ", "PASS" if ok else "FAIL")
	get_tree().quit()
