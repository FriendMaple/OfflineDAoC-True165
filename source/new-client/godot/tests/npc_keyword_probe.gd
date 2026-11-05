extends Node
## Offline check (reset day S9 + owner 2026-11-05): an NPC's [keywords] in the dialogue window - every one shown (Kaere's
## long one with an apostrophe and a "?" was missing), in its brackets, bold, not underlined; a click answers with the
## keyword's own words. A shot of the window to --out.
##   --skip-login --zone=N --world-mode=1.65 --probe=npc_keyword_probe --out=<dir>


func _ready() -> void:
	var v := get_tree().current_scene
	await get_tree().create_timer(6.0).timeout
	var d: NpcDialog = v.ui.npc_dialog
	var text := "Anniogel is in danger, and I need a rare component from the forest. I am too old to go myself - " + \
			"could you [get it for me]? [Will you gather the components for Keare's spell to protect Anniogel?] " + \
			"A stray [ bracket ] and a lone ] stay as they are."
	var heard := []
	d.keyword.connect(func(_id, k): heard.append(k))
	d.say("kaere", "Kaere", text)
	await get_tree().process_frame
	var shown := d._body.get_parsed_text()
	print("[kw] shown: ", shown)
	var ok := shown.contains("[get it for me]") and shown.contains("[Will you gather the components for Keare's spell to protect Anniogel?]")
	for k in d._links:
		d._body.meta_clicked.emit(k)
	print("[kw] links ", d._links.size(), " clicks answered: ", heard)
	ok = ok and heard.has("get it for me") and heard.has("Will you gather the components for Keare's spell to protect Anniogel?")
	print("[kw] underlined ", d._body.meta_underlined)
	ok = ok and not d._body.meta_underlined
	await get_tree().create_timer(0.5).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(String(v.args.get("out", "user://")) + "/npc_keyword.png")
	print("[kw] RESULT ", "PASS" if ok else "FAIL")
	get_tree().quit()
