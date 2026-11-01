extends Node
## Debug, headless (owner 2026-10-19: a troll companion's cloth vest drawn grey and streaky): a figure texture's
## compressed copy (fig3_textures/x4plus_bc/<key>.res, what Fig3Figure.load_texture draws) decompressed next to its
## source PNG (x4plus) - the mean colour difference, and user://bc_<key>.png to look at. -- <key> [<key> ...]
func _ready() -> void:
	for key in OS.get_cmdline_user_args():
		var bc := "res://content/characters/fig3_textures/x4plus_bc/%s.res" % key
		var src := Image.load_from_file(ProjectSettings.globalize_path("res://content/characters/fig3_textures/x4plus/%s.png" % key))
		var cimg := ResourceLoader.load(bc, "Image") as Image if ResourceLoader.exists(bc) else null
		if cimg == null or src == null:
			print("[bc] %s: bc %s, png %s" % [key, cimg != null, src != null])
			continue
		var img := cimg.duplicate() as Image
		if img.is_compressed():
			img.decompress()
		img.clear_mipmaps()
		img.convert(Image.FORMAT_RGBA8)
		src.convert(Image.FORMAT_RGBA8)
		print("[bc] %s: bc %dx%d fmt %d mips %s | png %dx%d" % [key, cimg.get_width(), cimg.get_height(), cimg.get_format(), cimg.has_mipmaps(), src.get_width(), src.get_height()])
		if img.get_size() != src.get_size():
			src.resize(img.get_width(), img.get_height())
		var diff := 0.0
		var n := 0
		for y in range(0, img.get_height(), 8):
			for x in range(0, img.get_width(), 8):
				var a := img.get_pixel(x, y)
				var b := src.get_pixel(x, y)
				diff += absf(a.r - b.r) + absf(a.g - b.g) + absf(a.b - b.b)
				n += 1
		print("[bc] %s: mean |difference| %.3f per channel" % [key, diff / maxf(n * 3.0, 1.0)])
		img.save_png("user://bc_%s.png" % key)
	get_tree().quit()
