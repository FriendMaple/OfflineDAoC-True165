extends SceneTree
## Offline: ClassDb.find + SkillInfo for a few companion preview names (the hover box of the TRAIN tab's previews).
func _initialize() -> void:
	for pair in [["style", "Daze"], ["style", "Back Crush"], ["style", "Devastate"], ["spell", "Amethyst Shield"], ["style", "No Such Style"]]:
		var id := ClassDb.find(pair[0], pair[1])
		print("[find] %s %s -> %s" % [pair[0], pair[1], id])
		if id != "":
			print("   ", SkillInfo.lines({"kind": pair[0], "id": int(id)}).slice(0, 4))
	quit()
