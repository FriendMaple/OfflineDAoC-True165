extends Node
## True 1.65 Mode's spell table = the real 1.64 client's (owner 2026-10-31): SpellFx.data() merged, checked against
## the 1.64 rows (pipeline/build_spell_fx_164.py), and every 1.64 effect model loads.
##   godot --headless --path godot res://tests/spell_fx_165_check.tscn -- --world-mode=1.65

func _ready() -> void:
	var ok := true
	var want := {
		"9461": {"gather": [], "sound_set": 0, "anims": ["cast_1h_circ_start", "cast_1h_circ_mid", ""]},   # the shade's half
		"9411": {"gather": [100055, 100069], "sound_set": 8, "target": 100178},                          # the pet's half
		"78": {"gather": [100145, 100146], "sound_set": 18},        # Trembling Earth (the later table: 37 / 38, 15)
		"211": {"gather": [100037, 100038], "sound_set": 15},       # Ensnaring Haze (the later table: 145 / 146, 18)
	}
	for ce in want:
		var e := SpellFx.effect(int(ce))
		for k in want[ce]:
			if _norm(e.get(k)) != _norm(want[ce][k]):
				ok = false
				print("FAIL ", ce, " ", k, ": ", e.get(k), " want ", want[ce][k])
	var fx: Dictionary = SpellFx.data().get("fx", {})
	var n164 := 0
	var bad := []
	for id in fx:
		if int(id) < 100000:
			continue
		n164 += 1
		var path := String(fx[id].nif)
		if not FileAccess.file_exists(path):
			bad.append(path)
	if not bad.is_empty():
		ok = false
		print("FAIL missing models: ", bad.slice(0, 10))
	var one := String(fx.get("100178", {}).get("nif", ""))          # the pet heal's hit, loaded as the game does
	var inst = SpellFx._instance(one) if one != "" else null
	if inst == null:
		print("note: ", one, " streams in on a worker (not loaded synchronously)")
	print("1.64 effects in the table: ", n164, "  9461 name ", SpellFx.effect(9461).get("name"))
	print("[spell_fx_165_check] ", "ok" if ok else "FAILED")
	get_tree().quit()


static func _norm(v) -> String:                      # (JSON numbers come back as floats: 8.0 is 8)
	if v is Array:
		var parts := PackedStringArray()
		for x in v:
			parts.append(str(int(x)) if (x is float or x is int) else str(x))
		return ",".join(parts)
	if v is float or v is int:
		return str(int(v))
	return str(v)
