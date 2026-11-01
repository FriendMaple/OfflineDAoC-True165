class_name Pregame164
extends Control
## True 1.65 Mode: the period 1.64 pregame (owner 2026-10-31: "figure out what the period 1.65 realm selection,
## character select screen, creation screen, play buttons, etc. actually looked like ... replace the current ones";
## PERIOD PREGAME PLAN.md). The real 1.64 client's own art (pipeline/build_pregame_164.py -> content/ui/pregame164) at
## the places its game.dll puts it (1.65 MODE CLIENT\work\164\pregame-layout\1.64 PREGAME LAYOUT.txt, the retired
## original-client chat): Choose Your Realm -> the standing stones (8 slots, PLAY / OPTIONS / QUIT / Delete Character,
## the selected character on the stones) -> one creation page (name + Generate, race, base class, sex, hair colour,
## face, height, Points Left + the 8 attributes, a help box, the figure with its face close-up) -> the summary page.
## Everything sits in the 800 x 600 art space, scaled to the window; the art fills the sides blurred (no black bars).

const ART := "res://content/ui/pregame164"
const W := 800.0
const H := 600.0
const CREAM := Color(0.93, 0.89, 0.78)
const GOLD := Color(1.0, 0.85, 0.45)
const HELP := Color(0.62, 0.8, 0.92)
const ERROR := Color(1.0, 0.45, 0.35)
const REALM_ORDER := ["alb", "mid", "hib"]
const REALM_RACES := {"alb": [1, 2, 3, 4, 13], "mid": [5, 6, 7, 8, 14], "hib": [9, 10, 11, 12, 15]}
# charbut.tga rows (y) and places (1.64 game.dll); 97 x 23, columns 0 disabled / 97 over / 194 normal / 291 pressed
const RACE_BUTTONS := {
	1: [8, 114, 207], 2: [8, 141, 184], 3: [110, 114, 230], 4: [110, 141, 253], 13: [56, 166, 1035],
	5: [8, 114, 667], 6: [8, 141, 644], 8: [110, 114, 690], 7: [110, 141, 713], 14: [56, 166, 1058],
	9: [15, 115, 851], 10: [15, 141, 897], 12: [122, 115, 874], 11: [122, 141, 920], 15: [56, 166, 1081]}
const CLASS_BUTTONS := {
	"alb": [["FIGH", 8, 216, 552], ["ROGU", 108, 216, 621], ["MAGE", 8, 243, 575], ["ELEM", 108, 243, 506],
			["ACOL", 8, 270, 598], ["ARAW", 108, 270, 1104]],
	"mid": [["WARR", 56, 216, 737], ["MYST", 56, 242, 828], ["NROG", 56, 268, 782], ["SPIR", 56, 294, 759]],
	"hib": [["ARMS", 56, 216, 943], ["STEA", 56, 242, 966], ["NATU", 56, 268, 989], ["MAGI", 56, 294, 1012],
			["GROV", 56, 320, 1127]]}
# the help box's texts, word for word from the 1.64 game.dll (0x23c3f0 - 0x23d0ac; owner 2026-10-31: "leave out your
# additions"). Classes: the Shrouded Isles versions (Reaver, Savage, Bonedancer, the Grove, the Disciple).
const CLASS_HELP := {
	"FIGH": "Fighters use the force of\nArms to gain their goals.\n\nCareers:\nArmsman, Mercenary,\nPaladin, Reaver ",
	"ELEM": "Elementalists excel in the\nuse of magical forces.\n\nCareers:\nWizard, Theurgist ",
	"ROGU": "Rogues use stealth and\nsubterfuge-based skills.\n\nCareers:\nScout, Minstrel, Infiltrator ",
	"ACOL": "Acolytes provide healing and\nholy aid to friends.\n\nCareers:\nCleric, Friar",
	"MAGE": "Mages provide sorcerous\nmagic.\n\nCareers:\nSorcerer, Cabalist ",
	"ARAW": "Worshipper of Arawn,\nlord of the underworld.\n\nCareers:\nNecromancer ",
	"WARR": "The weapon-user of\nthe Realm of Midgard.\n\nCan become a\nThane, Warrior, Skald,\nBerserker or Savage.",
	"MYST": "The offensive spellcasting\nPriests of Midgard.\n\nCan be a Spiritmaster,\nRunemaster or Bonedancer.",
	"SPIR": "The healing and helping\nPriests of Midgard.\n\nCan become\nthe Healer or Shaman.",
	"NROG": "Specializing in \nsneaking and stealing.\n\nCan become a \nShadowblade or Hunter.",
	"ARMS": "Guardians are skilled in\nthe use of melee weapons\n\nCareers:\nChampion, Blademaster,\nHero ",
	"STEA": "Stalkers use cunning and\nguile to achieve their goals\n\nCareers:\nRanger, Nightshade",
	"NATU": "Naturalists blend with and\nuse the primal forces of\nNature\n\nCareers:\nWarden, Bard, Druid",
	"MAGI": "The way of arcane research,\nspellcasting and raw power\n\nCareers:\nMentalist, Eldritch,\nEnchanter",
	"GROV": "Affinity with Nature.\n\nCareers:\nValewalker, Animist"}
# races: [male, female] (Albion's differ by sex; the period typo "womenfrom" kept)
const RACE_HELP := {
	1: ["Standard man of Albion.", "Standard woman of Albion."],
	2: ["Tall intelligent men from\nthe island city of Avalon.", "Tall slender intelligent\nwomenfrom the island city\nof Avalon."],
	3: ["Tall strong men from the\nhills near Camelot.", "Tall strong women from the\nhills near Camelot."],
	4: ["Dusky slender men\nof desert origin.", "Dusky slender women\nof desert origin."],
	13: ["Underground servant race\nof Arawn, lord of the\nunderworld.\nAdept at necromancy."],
	5: ["Hardy humans living in\nthe frozen lands of Midgard.\nCan become any class."],
	6: ["Huge fearsome creatures.\nStrong, but clumsy and slow.\nTrolls make a great warrior."],
	7: ["Short man-like creature.\nStrong and hardy.\nDwarves can become\nmost classes."],
	8: ["Small dextrous underground\ncreature. Agile, but not\nstrong.\nKobolds are excellent rogues."],
	14: ["Primitive humanoid race\nfrom the island of Aegir.\nQuick and dextrous.\nValkyn are excellent savages and bonedancers."],
	9: ["Standard Celtic human"],
	10: ["A strong and hardy\ncross of human and\ngiant, Firbolgs make\ngreat fighters."],
	11: ["Tall, beautiful\ncreatures specializing\nin magic"],
	12: ["Small and dextrous\nmagical creatures."],
	15: ["Born of nature.\nHardy and strong."]}
# the attribute rows, top to bottom, as the period page lists them -> the server's stat order (STR DEX CON QUI INT
# PIE EMP CHA); and what the help box says over each (game.dll)
const STAT_ROWS := [["STR", 0], ["CON", 2], ["DEX", 1], ["QUI", 3], ["INT", 4], ["PIE", 5], ["EMP", 6], ["CHA", 7]]
const STAT_HELP := {
	"STR": "Potential for\neffective action",
	"CON": "General health\nand well-being",
	"DEX": "Skill and grace\nin physical\nmovement",
	"QUI": "Reflexes and\nreaction time",
	"INT": "Ability to\nunderstand and\nuse information",
	"PIE": "Religious devotion\nand reverence",
	"EMP": "Relation to\nthings natural\nand supernatural",
	"CHA": "Personal magnetism\nor charm"}
## The pregame scene to open (the period one in True 1.65 Mode - the only mode since 2026-10-31 - else the old one).
static func scene() -> String:
	return "res://game/pregame_164.tscn" if Server.world_mode == "1.65" else "res://game/pregame.tscn"


static var last_realm := ""                # back on the same realm's stones after leaving the world
const BUDGET := 30                       # the server's CharacterStatValidator: all 30 points, 1 / 2 / 3 above +10 / +15
const HEIGHTS := [["SHORT", 253, 345], ["AVERAGE", 354, 368], ["TALL", 455, 391]]

var realm := ""
var screen := ""
var chars: Array = []
var sel := -1                            # the slot (0..7) selected on the stones
var draft := {}
var _entered_at := -100000
var _tex := {}
var _blur: TextureRect
var _stage: Control
var _help: RichTextLabel
var _name_edit: LineEdit
var _options: OptionsWindow             # the game's options window, pregame pages only (owner 2026-10-31)
var _top: Control                        # the art space above the screens (the options window; not rebuilt)
var _views := {}                         # name -> [SubViewport, Camera3D]
var _figure: Fig3Figure
var _figure_key := ""
var _gear: Array = []
var _bg_name := ""                       # the screen art under the buttons (_blended)
var test_chars: Array = []               # (tests/pregame164_shot: characters to show with no server)
var _yaw := 0.0                          # the figure turned by a left-drag (owner 2026-10-31), kept while the page rebuilds
var _turning := false


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	PregameMusic.play()
	var bg := ColorRect.new()
	bg.color = Color.BLACK
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	_blur = TextureRect.new()                             # the art again behind, blurred, filling the sides
	_blur.set_anchors_preset(Control.PRESET_FULL_RECT)
	_blur.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_blur.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_blur.modulate = Color(0.55, 0.55, 0.6)
	add_child(_blur)
	_stage = Control.new()
	_stage.size = Vector2(W, H)
	add_child(_stage)
	_top = Control.new()
	_top.size = Vector2(W, H)
	_top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_top)
	_options = OptionsWindow.new()
	_options.pregame = true
	_options.setup("pregame_options", "options", Rect2(), Vector2(208, 90))
	_top.add_child(_options)
	_options.visible = false
	_options.build()
	resized.connect(_fit)
	if Server.active:
		Server.characters_ready.connect(func(r):
			_entered_at = -100000
			if screen == "select" and r == realm:
				_show("select"))
		Server.disconnected.connect(func(_why): _entered_at = -100000)
		Server.login_failed.connect(func(_why): _entered_at = -100000)
		Server.created.connect(_on_created)
		Server.deleted.connect(func():
			sel = -1
			_show("select"))
		Server.name_checked.connect(_on_name_checked)
	if last_realm != "":
		realm = last_realm
		_show("select")
	else:
		_show("realm")
	_fit.call_deferred()


func _fit() -> void:
	var k := minf(size.x / W, size.y / H)
	_stage.scale = Vector2(k, k)
	_stage.position = ((size - Vector2(W, H) * k) * 0.5).floor()
	_top.scale = _stage.scale
	_top.position = _stage.position


## Left-drag on the figure turns it (owner 2026-10-31: "i cant left click drag to move the character around") - the
## period screens had no turning; on the select screen over the stones, on the creation page over the body / face views.
func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if not event.pressed:
			_turning = false
		elif _figure and not _options.visible and _on_figure(_stage.get_global_transform().affine_inverse() * event.position):
			_turning = true
	elif event is InputEventMouseMotion and _turning:
		if not (event.button_mask & MOUSE_BUTTON_MASK_LEFT) or _figure == null:
			_turning = false
			return
		_yaw += event.relative.x * 0.5
		_figure.rotation_degrees.y = 20.0 + _yaw


## Whether an art-space point is on the figure's own view (not on a button beside it).
func _on_figure(p: Vector2) -> bool:
	match screen:
		"select": return Rect2(464, 70, 336, 485).has_point(p)
		"create": return Rect2(232, 69, 352, 494).has_point(p) or Rect2(488, 24, 96, 126).has_point(p)
	return false


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and _options.visible:
		if not _options.capturing():
			_options.hide_window()
			get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("ui_cancel") and screen == "select":   # (not period: the realm screen again)
		_show("realm")
		get_viewport().set_input_as_handled()


# ---------------------------------------------------------------- art

func _texture(name: String) -> Texture2D:
	if not _tex.has(name):
		var img := Image.load_from_file(ProjectSettings.globalize_path("%s/original/%s.png" % [ART, name]))
		_tex[name] = ImageTexture.create_from_image(img) if img else null
	return _tex[name]


func _blurred(name: String) -> Texture2D:
	var key := name + "#blur"
	if not _tex.has(key):
		var img := Image.load_from_file(ProjectSettings.globalize_path("%s/original/%s.png" % [ART, name]))
		if img:
			img.resize(40, 30, Image.INTERPOLATE_BILINEAR)
			img.resize(400, 300, Image.INTERPOLATE_CUBIC)
		_tex[key] = ImageTexture.create_from_image(img) if img else null
	return _tex[key]


func _backdrop(name: String) -> void:
	_bg_name = name
	_blur.texture = _blurred(name)
	var t := TextureRect.new()
	t.texture = _texture(name)
	t.size = Vector2(W, H)
	t.stretch_mode = TextureRect.STRETCH_SCALE
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_stage.add_child(t)


func _region(sheet: String, r: Rect2) -> AtlasTexture:
	var a := AtlasTexture.new()
	a.atlas = _texture(sheet)
	a.region = r
	a.filter_clip = true                                  # (no bleeding from the next cell when scaled: white edges)
	return a


## A button state cut from its sheet with the backdrop under it see-through: the period sheets are opaque copies of
## the screen's own art (the 1.64 client blits them), and drawn over the scaled backdrop their slightly different
## background showed as a square (owner 2026-10-31) - only the pixels that differ from the art (the letters, the glow,
## the gold border) are kept, faded in by how much they differ.
func _blended(sheet: String, r: Rect2, at: Vector2) -> Texture2D:
	var key := "%s|%s|%s|%s" % [sheet, str(r), str(at), _bg_name]
	if _tex.has(key):
		return _tex[key]
	var src: Texture2D = _texture(sheet)
	var bg: Texture2D = _texture(_bg_name)
	if src == null or bg == null:
		return _region(sheet, r)
	var a := src.get_image().get_region(Rect2i(r))
	var b := bg.get_image().get_region(Rect2i(Rect2(at, r.size)))
	a.convert(Image.FORMAT_RGBA8)
	b.convert(Image.FORMAT_RGBA8)
	for y in a.get_height():
		for x in a.get_width():
			var c := a.get_pixel(x, y)
			var u := b.get_pixel(x, y)
			var d := maxf(absf(c.r - u.r), maxf(absf(c.g - u.g), absf(c.b - u.b)))
			c.a = clampf((d - 0.045) / 0.09, 0.0, 1.0)
			a.set_pixel(x, y, c)
	var t := ImageTexture.create_from_image(a)
	_tex[key] = t
	return t


## An image button: its four sheet rects in the order normal, mouse over, pressed, disabled (1.64 game.dll 0x4CF4AC).
func _image_button(sheet: String, states: Array, sz: Vector2, at: Vector2, cb: Callable, toggle := false,
		blend := false) -> TextureButton:
	var b := TextureButton.new()
	var cut := func(i: int) -> Texture2D:
		return _blended(sheet, Rect2(states[i], sz), at) if blend else _region(sheet, Rect2(states[i], sz))
	b.texture_normal = cut.call(0)
	b.texture_hover = cut.call(1)
	b.texture_pressed = cut.call(2)
	b.texture_disabled = cut.call(3)
	b.ignore_texture_size = true
	b.stretch_mode = TextureButton.STRETCH_SCALE
	b.position = at
	b.size = sz
	b.toggle_mode = toggle
	b.focus_mode = Control.FOCUS_NONE
	b.pressed.connect(cb)
	_stage.add_child(b)
	return b


## A 97 x 23 charbut.tga button (columns: 0 disabled, 97 over, 194 normal, 291 pressed) at its row y.
func _charbut(row_y: int, at: Vector2, cb: Callable, toggle := false) -> TextureButton:
	return _image_button("charbut", [Vector2(194, row_y), Vector2(97, row_y), Vector2(291, row_y), Vector2(0, row_y)],
			Vector2(97, 23), at, cb, toggle)


## CANCEL / PROCEED / BACK (charcanpro.TGA, 109 x 23, rows 0 / 23 / 46, the same columns).
func _bottom(row_y: int, at: Vector2, cb: Callable) -> TextureButton:
	return _image_button("cancel_proceed_back", [Vector2(218, row_y), Vector2(109, row_y), Vector2(327, row_y),
			Vector2(0, row_y)], Vector2(109, 23), at, cb, false, true)


## A 16 x 16 arrow (statbut.tga: up / right row 0, down / left row 16; columns 32 normal, 16 over, 48 pressed, 0 off).
func _arrow(up: bool, at: Vector2, cb: Callable) -> TextureButton:
	var y := 0 if up else 16
	return _image_button("statbut", [Vector2(32, y), Vector2(16, y), Vector2(48, y), Vector2(0, y)], Vector2(16, 16), at, cb)


func _text(s: String, at: Vector2, sz: Vector2, fs := 13, col := CREAM, align := HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var l := Label.new()
	l.text = s
	l.position = at
	l.size = sz
	l.add_theme_font_override("font", UiArt.font(true))
	l.add_theme_font_size_override("font_size", fs)
	l.add_theme_color_override("font_color", col)
	l.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	l.add_theme_constant_override("shadow_offset_x", 1)
	l.add_theme_constant_override("shadow_offset_y", 1)
	l.horizontal_alignment = align
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_stage.add_child(l)
	return l


func _say(s: String, col := ERROR) -> void:
	if _help:
		_help.clear()
		_help.push_color(col)
		_help.add_text(s)
		_help.pop()


# ---------------------------------------------------------------- screens

func _show(which: String) -> void:
	if which != screen:
		_yaw = 0.0
	screen = which
	_turning = false
	for c in _stage.get_children():
		c.queue_free()
	_help = null
	_name_edit = null
	_views.clear()
	_figure = null
	_figure_key = ""
	_gear.clear()
	match which:
		"realm": _build_realm()
		"select": _build_select()
		"create": _build_create()
		"summary": _build_summary()


## Choose Your Realm (chooserealm.tga): the three emblems in the triple knot.
func _build_realm() -> void:
	_backdrop("chooserealm")
	var em := {"alb": [Vector2(339, 352), Vector2(118, 101), 0, [236, 354, 118, 0]],
			"mid": [Vector2(498, 117), Vector2(83, 105), 101, [166, 249, 83, 0]],
			"hib": [Vector2(218, 117), Vector2(88, 105), 206, [176, 264, 88, 0]]}
	for r in REALM_ORDER:
		var e: Array = em[r]
		var y: int = e[2]
		var xs: Array = e[3]
		_image_button("realm_emblems", [Vector2(xs[0], y), Vector2(xs[1], y), Vector2(xs[2], y), Vector2(xs[3], y)],
				e[1], e[0], func(): _pick_realm(r), false, true)


func _pick_realm(r: String) -> void:
	realm = r
	last_realm = r
	sel = -1
	_show("select")


## The standing stones (Main.tga): 8 slots on the left, PLAY / OPTIONS in the middle, QUIT / Delete Character below,
## the selected character on the stones (its own view, x 464..800, y 70..600).
func _build_select() -> void:
	_backdrop("main")
	chars = Server.characters_in(realm) if Server.active else test_chars
	if sel < 0 or _char_at(sel).is_empty():
		sel = -1
		for i in Server.SLOTS_PER_REALM + 2:
			if not _char_at(i).is_empty():
				sel = i
				break
	# the 8 slots; a character from before the 8-slot limit in slot 9 or 10 (the server keeps them playable, server
	# chat 2026-10-31) gets a short row under them, and no new one is offered there
	var rows := []
	for i in Server.SLOTS_PER_REALM:
		rows.append([i, Rect2(9, 30 + 60 * i, 345, 60)])
	for i in [Server.SLOTS_PER_REALM, Server.SLOTS_PER_REALM + 1]:
		if not _char_at(i).is_empty():
			rows.append([i, Rect2(120, 510 + 22 * (i - Server.SLOTS_PER_REALM), 260, 22)])
	for row in rows:
		var i: int = row[0]
		var c := _char_at(i)
		var b := Button.new()
		b.flat = true
		b.focus_mode = Control.FOCUS_NONE
		b.position = (row[1] as Rect2).position
		b.size = (row[1] as Rect2).size
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.add_theme_font_override("font", UiArt.font(true))
		b.add_theme_font_size_override("font_size", 15 if i < Server.SLOTS_PER_REALM else 12)
		var col := GOLD if i == sel else CREAM
		for k in ["font_color", "font_focus_color"]:
			b.add_theme_color_override(k, col)
		b.add_theme_color_override("font_hover_color", GOLD)
		b.add_theme_color_override("font_pressed_color", Color(1, 0.4, 0.3))
		b.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
		b.add_theme_constant_override("outline_size", 3)
		if c.is_empty():
			b.text = "Create New Character"
			b.pressed.connect(func(): _start_create(i))
		else:
			b.text = "%s the %s (level %d)" % [String(c.name), String(c.class_name), int(c.level)]
			var where := String(c.get("location_text", ""))
			if where != "":
				b.text += "\n   in " + where
			b.pressed.connect(func():
				sel = i
				_show("select"))
		_stage.add_child(b)
	var play := _image_button("play", [Vector2(0, 136), Vector2(0, 68), Vector2(0, 204), Vector2(0, 0)], Vector2(147, 68),
			Vector2(383, 202), _play, false, true)
	play.disabled = sel < 0
	_image_button("options", [Vector2(0, 74), Vector2(0, 37), Vector2(0, 111), Vector2(0, 0)], Vector2(147, 37),
			Vector2(383, 289), func(): _options.toggle_window(), false, true)
	_image_button("quit", [Vector2(0, 82), Vector2(0, 41), Vector2(0, 123), Vector2(0, 0)], Vector2(90, 41),
			Vector2(18, 557), func(): _confirm("quit"), false, true)
	var del := _image_button("delete", [Vector2(0, 72), Vector2(0, 36), Vector2(0, 108), Vector2(0, 0)], Vector2(233, 36),
			Vector2(539, 560), func(): _confirm("delete"), false, true)
	del.disabled = sel < 0
	if Server.active and Server.last_error != "":         # (an entry the server refused: PLAY works again at once)
		_entered_at = -100000
		var err := _text(Server.last_error, Vector2(360, 340), Vector2(200, 60), 12, ERROR, HORIZONTAL_ALIGNMENT_CENTER)
		err.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		Server.last_error = ""
	if sel >= 0:
		var vp := _view("select", Rect2(464, 70, 336, 530))
		_place_figure(vp, _char_at(sel))
		_select_camera()


func _char_at(slot: int) -> Dictionary:
	for c in chars:
		if int(c.get("slot", -1)) == slot:
			return c
	return {}


func _play() -> void:
	var c := _char_at(sel)
	if c.is_empty() or not Server.active:
		return
	var now := Time.get_ticks_msec()
	if now - _entered_at < 10000:                       # already on its way in (a double-click)
		return
	_entered_at = now
	Server.enter_world(c)


## The delete / quit confirm box (dialog.tga at 260,218; lines at 267,253/273/293; DELETE or QUIT and CANCEL).
func _confirm(what: String) -> void:
	var shade := ColorRect.new()
	shade.color = Color(0, 0, 0, 0.45)
	shade.size = Vector2(W, H)
	shade.mouse_filter = Control.MOUSE_FILTER_STOP
	_stage.add_child(shade)
	var box := TextureRect.new()
	box.texture = _texture("dialog")
	box.position = Vector2(260, 218)
	box.size = Vector2(280, 164)
	box.stretch_mode = TextureRect.STRETCH_SCALE
	box.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	shade.add_child(box)
	var lines := ["Are you sure you", "want to quit?", ""]
	var yes: LineEdit = null
	if what == "delete":
		var c := _char_at(sel)
		lines = ["Are you sure you want %s" % String(c.get("name", "")), "to delete!  Type \"YES\" to confirm.",
				"Press Delete to complete"]
	for i in 3:
		var l := Label.new()
		l.text = lines[i]
		l.position = Vector2(267, 253 + 20 * i)
		l.size = Vector2(266, 20)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.add_theme_font_override("font", UiArt.font(true))
		l.add_theme_font_size_override("font_size", 12)
		l.add_theme_color_override("font_color", CREAM)
		shade.add_child(l)
	var close := func(): shade.queue_free()
	var ok_row := 437                                    # QUIT
	if what == "delete":
		ok_row = 414                                     # DELETE
		yes = LineEdit.new()
		yes.position = Vector2(360, 295)
		yes.size = Vector2(80, 20)
		yes.add_theme_font_size_override("font_size", 12)
		yes.max_length = 3
		yes.alignment = HORIZONTAL_ALIGNMENT_CENTER
		shade.add_child(yes)
		yes.grab_focus.call_deferred()
		(shade.get_child(3) as Label).position.y = 273   # (the third line moves up beside the box for YES)
		(shade.get_child(3) as Label).text = ""
	var ok := _charbut(ok_row, Vector2(293, 330), func():
		if what == "quit":
			get_tree().quit()
		elif yes and yes.text.strip_edges().to_upper() == "YES":
			var c := _char_at(sel)
			if not c.is_empty():
				Server.delete_character(realm, c)
			close.call())
	ok.reparent(shade)
	var cancel := _charbut(460, Vector2(421, 330), close)
	cancel.reparent(shade)
	if yes:
		ok.disabled = true
		yes.text_changed.connect(func(t: String): ok.disabled = t.strip_edges().to_upper() != "YES")


# ---------------------------------------------------------------- creation

func _start_create(slot: int) -> void:
	# a ready character from the start - the realm's first race, male, its first class, the points spent for that
	# class (owner 2026-10-31: "player model is gone completely now" / "make it automatic again ... with the option to
	# change the stats if you want"); every button still changes it
	draft = {"slot": slot, "race": int(REALM_RACES[realm][0]), "base": "", "gender": 0, "face": 0, "hair": 0,
			"height": 2, "name": ""}
	var bases := _allowed_bases()
	draft.base = String(bases[0]) if bases.size() > 0 else ""
	_auto_stats()
	_show("create")


## The 30 creation points spent automatically, as the server did before the period page: +10 on each of the class's
## three stats (Server.create_character's old fill; CharacterStatValidator: exactly 30). + / - change them after.
func _auto_stats() -> void:
	draft.stats = _race_stats()
	if int(draft.race) == 0 or String(draft.base) == "":
		return
	var picked := []
	for st in Server.class_stats(int(Server.BASE_IDS.get(String(draft.base), 0))):
		var i := int(Server.STAT_INDEX.get(String(st), -1))
		if i >= 0 and not (i in picked):
			picked.append(i)
	for i in [0, 2, 1, 3, 4, 5, 6, 7]:                      # (a class naming a stat twice: the next ones)
		if picked.size() >= 3:
			break
		if not (i in picked):
			picked.append(i)
	for i in picked:
		draft.stats[i] = int(draft.stats[i]) + 10


func _race_stats() -> Array:
	return (Server.RACE_STATS.get(int(draft.race), [60, 60, 60, 60, 60, 60, 60, 60]) as Array).duplicate()


static func _cost(base: int, val: int) -> int:
	var above := val - base
	return above + maxi(0, above - 10) + maxi(0, above - 15)


func _points_left() -> int:
	if int(draft.race) == 0:
		return BUDGET
	var base := _race_stats()
	var spent := 0
	for i in 8:
		spent += _cost(int(base[i]), int(draft.stats[i]))
	return BUDGET - spent


func _build_create() -> void:
	_backdrop("chargen")
	_name_edit = LineEdit.new()
	_name_edit.position = Vector2(310, 6)
	_name_edit.size = Vector2(190, 20)
	_name_edit.max_length = 20
	_name_edit.text = String(draft.name)
	_name_edit.flat = true
	_name_edit.add_theme_font_override("font", UiArt.font(true))
	_name_edit.add_theme_font_size_override("font_size", 13)
	_name_edit.add_theme_color_override("font_color", CREAM)
	_name_edit.text_changed.connect(func(t: String): draft.name = t.strip_edges())
	_stage.add_child(_name_edit)
	_charbut(322, Vector2(203, 32), _generate)
	for rid in REALM_RACES[realm]:
		var rb: Array = RACE_BUTTONS[rid]
		var b := _charbut(int(rb[2]), Vector2(rb[0], rb[1]), func(): _pick_race(rid), true)
		b.button_pressed = int(draft.race) == rid
		b.mouse_entered.connect(func():
			var t: Array = RACE_HELP.get(rid, [""])
			_say(String(t[mini(maxi(int(draft.gender), 0), t.size() - 1)]), HELP))
	var allowed := _allowed_bases()
	for e in CLASS_BUTTONS[realm]:
		var key := String(e[0])
		var b := _charbut(int(e[3]), Vector2(e[1], e[2]), func(): _pick_base(key), true)
		b.button_pressed = String(draft.base) == key
		b.disabled = int(draft.race) != 0 and not (key in allowed)
		_hover(b, String(CLASS_HELP.get(key, "")))
	for g in 2:
		var b := _charbut([276, 299][g], Vector2([8, 108][g], 345), func(): _pick_gender(g), true)
		b.button_pressed = int(draft.gender) == g
	var ready := int(draft.race) != 0 and int(draft.gender) >= 0
	for row in [[399, "hair"], [448, "face"]]:
		var key: String = row[1]
		var l := _arrow(false, Vector2(35, row[0]), func(): _step(key, -1))
		var r := _arrow(true, Vector2(160, row[0]), func(): _step(key, 1))
		l.disabled = not ready
		r.disabled = not ready
	for i in HEIGHTS.size():
		var h: Array = HEIGHTS[i]
		var b := _charbut(int(h[2]), Vector2(h[1], 570), func():
			draft.height = i + 1
			_show("create"), true)
		b.button_pressed = int(draft.height) == i + 1
	# Points Left and the 8 attributes (yellow: the class's own)
	var left := _points_left()
	_text(str(left), Vector2(637, 49), Vector2(97, 23), 15, GOLD if left == 0 else CREAM, HORIZONTAL_ALIGNMENT_CENTER)
	var key_stats: Array = Server.class_stats(int(Server.BASE_IDS.get(String(draft.base), 0))) if String(draft.base) != "" else []
	for k in STAT_ROWS.size():
		var row: Array = STAT_ROWS[k]
		var si: int = row[1]
		var y := 39 * k
		# the mouse-over help zone 599,85+39k 192x32 - under the - / + (drawn after them it took their clicks:
		# owner 2026-10-31 "the + and - doesnt do anything")
		var zone := Control.new()
		zone.position = Vector2(599, 85 + y)
		zone.size = Vector2(192, 32)
		zone.mouse_filter = Control.MOUSE_FILTER_PASS
		_stage.add_child(zone)
		zone.mouse_entered.connect(func(): _say(String(STAT_HELP[row[0]]), HELP))
		var minus := _arrow(false, Vector2(611, 91 + y), func(): _stat(si, -1))
		var plus := _arrow(true, Vector2(663, 92 + y), func(): _stat(si, 1))
		minus.disabled = int(draft.race) == 0 or int(draft.stats[si]) <= int(_race_stats()[si])
		plus.disabled = int(draft.race) == 0 or not _can_raise(si)
		_text(str(int(draft.stats[si])) if int(draft.race) != 0 else "", Vector2(630, 88 + y), Vector2(29, 28), 14, CREAM,
				HORIZONTAL_ALIGNMENT_CENTER)
		var plate := TextureRect.new()
		var yellow := key_stats.any(func(n): return int(Server.STAT_INDEX.get(String(n), -1)) == si)
		plate.texture = _region("stats", Rect2(92 if yellow else 0, 18 * k, 92, 18))
		plate.position = Vector2(691, 91 + y)
		plate.size = Vector2(92, 18)
		plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_stage.add_child(plate)
		minus.mouse_entered.connect(func(): _say(String(STAT_HELP[row[0]]), HELP))
		plus.mouse_entered.connect(func(): _say(String(STAT_HELP[row[0]]), HELP))
	_help = RichTextLabel.new()
	_help.position = Vector2(589, 400)
	_help.size = Vector2(196, 136)
	_help.bbcode_enabled = false
	_help.add_theme_font_override("normal_font", UiArt.font(true))
	_help.add_theme_font_size_override("normal_font_size", 12)
	_help.add_theme_color_override("default_color", HELP)
	_help.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_stage.add_child(_help)
	_bottom(0, Vector2(13, 566), func(): _show("select"))
	_bottom(23, Vector2(678, 566), _proceed)
	if ready:
		var body := _view("body", Rect2(216, 69, 368, 531))
		_place_figure(body, {"prefix": _prefix(), "look": _look()})
		var head := _view("head", Rect2(488, 24, 96, 126), body)
		_creation_cameras(body, head)


func _hover(b: Control, s: String) -> void:
	b.mouse_entered.connect(func(): _say(s, HELP))


## The base classes this race may start as, in the page's own order (Fighter / Viking / Way of Arms first).
func _allowed_bases() -> Array:
	var out := []
	if int(draft.race) == 0:
		return out
	var ok := []
	for c in Server.base_classes_for(realm, int(draft.race)):
		ok.append(Server.base_key_of(int(c[0])))
	for e in CLASS_BUTTONS[realm]:
		if String(e[0]) in ok:
			out.append(String(e[0]))
	return out


func _pick_race(rid: int) -> void:
	draft.race = rid
	draft.face = 0
	draft.hair = 0
	var bases := _allowed_bases()
	if not (String(draft.base) in bases):
		draft.base = String(bases[0]) if bases.size() > 0 else ""
	_auto_stats()
	_show("create")


func _pick_base(key: String) -> void:
	draft.base = key
	_auto_stats()
	_show("create")


func _pick_gender(g: int) -> void:
	draft.gender = g
	draft.face = 0
	draft.hair = 0
	_show("create")


func _prefix() -> String:
	return "%s_%s" % [Server.RACES[int(draft.race)][1], "f" if int(draft.gender) == 1 else "m"]


func _meta() -> Dictionary:
	return ClassicFigure.meta_of(_prefix())


func _face_count() -> int:
	return maxi(1, (_meta().get("player_looks", []) as Array).size())


## The look the period page builds: the face (one of the race's 12 player looks) and the hair colour (an index into
## that look's hair.csv set).
func _look() -> Dictionary:
	var looks: Array = _meta().get("player_looks", [])
	var model := int(looks[clampi(int(draft.face), 0, looks.size() - 1)]) if looks.size() > 0 else 0
	return {"model": model, "hair_index": int(draft.hair), "hair_color": int(draft.hair), "height": int(draft.height)}


func _hair_count() -> int:
	var m := _meta()
	var row := ClassicFigure.look_row(m, _look())
	return maxi(1, (m.get("hair_sets", {}).get(str(int(row.get("hair_set", 0))), []) as Array).size())


func _step(key: String, d: int) -> void:
	if key == "face":
		draft.face = posmod(int(draft.face) + d, _face_count())
		draft.hair = mini(int(draft.hair), _hair_count() - 1)
	else:
		draft.hair = posmod(int(draft.hair) + d, _hair_count())
	_show("create")


func _can_raise(si: int) -> bool:
	var base := int(_race_stats()[si])
	var v := int(draft.stats[si])
	return v < 100 and _cost(base, v + 1) - _cost(base, v) <= _points_left()


func _stat(si: int, d: int) -> void:
	if d > 0 and not _can_raise(si):
		return
	if d < 0 and int(draft.stats[si]) <= int(_race_stats()[si]):
		return
	draft.stats[si] = int(draft.stats[si]) + d
	_show("create")


func _generate() -> void:
	if int(draft.race) == 0:
		_say("You must select\na race!")
		return
	var races: Array = CharacterFactory.RACES[realm]
	var ri := 0
	for i in races.size():
		if String(races[i][2]) == String(Server.RACES[int(draft.race)][1]):
			ri = i
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	draft.name = CharacterFactory.random_name(realm, ri, rng)
	if _name_edit:
		_name_edit.text = String(draft.name)


## Proceed: the period's checks, the server's name check, then the summary page.
func _proceed() -> void:
	if String(draft.name) == "":
		_say("You must enter a name!")
	elif String(draft.name).length() < 3:
		_say("Your name is too short!")
	elif int(draft.race) == 0:
		_say("You must select\na race!")
	elif String(draft.base) == "":
		_say("You must select\na class!")
	elif int(draft.gender) < 0:
		_say("You must select\na gender!")
	elif _points_left() != 0:
		_say("You must use\nall your points!")
	elif Server.active:
		var err := Server.name_error(String(draft.name))
		if err != "":
			_say(err)
			return
		_say("Checking Server\n . . .", HELP)
		Server.check_name(String(draft.name))


func _on_name_checked(n: String, result: int) -> void:
	if screen != "create" or n.to_lower() != String(draft.name).to_lower():
		return
	if result == 2:
		_say("That name is\nalready taken.")
	elif result == 1:
		_say("That name is\nnot allowed.")
	else:
		_show("summary")


## The summary page (chargen_Summ.tga): the race + base class's text from the client's summary.txt.
func _build_summary() -> void:
	_backdrop("chargen_summary")
	var t := RichTextLabel.new()
	t.position = Vector2(60, 50)
	t.size = Vector2(500, 470)
	t.add_theme_font_override("normal_font", UiArt.font(true))
	t.add_theme_font_size_override("normal_font_size", 14)
	t.add_theme_color_override("default_color", CREAM)
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	t.text = _summary_text()
	_stage.add_child(t)
	_help = RichTextLabel.new()                            # (the create errors, if the server refuses)
	_help.position = Vector2(560, 470)
	_help.size = Vector2(220, 80)
	_help.add_theme_font_size_override("normal_font_size", 12)
	_stage.add_child(_help)
	_bottom(0, Vector2(13, 566), func(): _show("select"))
	_bottom(46, Vector2(135, 566), func(): _show("create"))
	_bottom(23, Vector2(678, 566), _create)


func _summary_text() -> String:
	var races: Array = CharacterFactory.RACES[realm]
	var code := ""
	for r in races:
		if String(r[2]) == String(Server.RACES[int(draft.race)][1]):
			code = String(r[1])
	var raw := FileAccess.get_file_as_string("%s/summary.txt" % ART)
	var tag := "[%s-%s]" % [code, String(draft.base)]
	var i := raw.find(tag)
	if i < 0:
		return "%s\n\n%s" % [String(draft.name), CLASS_HELP.get(String(draft.base), "")]
	var j := raw.find("\n[", i + tag.length())
	var body := raw.substr(i + tag.length(), (j - i - tag.length()) if j > 0 else -1).strip_edges()
	return "%s\n\n%s" % [String(draft.name).to_upper(), body]


func _create() -> void:
	if not Server.active:
		return
	var err := Server.create_character(realm, String(Server.RACES[int(draft.race)][0]), int(draft.gender) == 1,
			int(Server.BASE_IDS.get(String(draft.base), 0)), String(draft.name), _look(), draft.stats, int(draft.height),
			int(draft.slot))
	if err != "":
		_say(err)
		return
	_say("Creating %s . . ." % String(draft.name), HELP)


func _on_created(ok: bool, why: String) -> void:
	chars = Server.characters_in(realm)
	if ok:
		for c in chars:
			if String(c.name).to_lower() == String(draft.get("name", "")).to_lower():
				sel = int(c.slot)
		_show("select")
	else:
		_say(why)


# ---------------------------------------------------------------- the figure views

## A 3D view at an art-space rect: its own world (or another view's, for the face close-up), transparent, lit by an
## ambient light (0.5) and a directional light as the 1.64 screens.
func _view(key: String, r: Rect2, share: SubViewport = null) -> SubViewport:
	var holder := SubViewportContainer.new()
	holder.position = r.position
	holder.size = r.size
	holder.stretch = true
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_stage.add_child(holder)
	var vp := SubViewport.new()
	vp.transparent_bg = true
	vp.size = Vector2i(r.size * 2.0)
	if share:
		vp.world_3d = share.world_3d
	else:
		vp.world_3d = World3D.new()                       # (a World3D of its own that the face close-up can share)
		var env := WorldEnvironment.new()
		env.environment = Environment.new()
		env.environment.background_mode = Environment.BG_CLEAR_COLOR
		env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
		env.environment.ambient_light_color = Color(1, 1, 1)
		env.environment.ambient_light_energy = 0.5
		vp.add_child(env)
		var sun := DirectionalLight3D.new()
		sun.rotation_degrees = Vector3(-35, 30, 0)
		sun.light_energy = 1.0
		vp.add_child(sun)
	holder.add_child(vp)
	var cam := Camera3D.new()
	cam.current = true
	vp.add_child(cam)
	_views[key] = [vp, cam]
	return vp


## The character on its view: classic figure, worn gear, idle; turned 110 deg as the period screens (no turning).
func _place_figure(vp: SubViewport, c: Dictionary) -> void:
	var prefix := String(c.get("prefix", ""))
	if prefix == "":
		return
	_figure = Fig3Figure.make()
	vp.add_child(_figure)
	if not _figure.load_figure(prefix):
		return
	_figure.apply(c.get("look", {}))
	_figure.rotation_degrees.y = 20.0 + _yaw              # (110 deg about the up axis in the client's frame; + a drag)
	var inv: Dictionary = c.get("inventory", {}) if c.get("inventory") is Dictionary else {}
	if not inv.is_empty():
		var item_at := func(slot: int) -> Dictionary:
			var e = inv.get(str(slot))
			return ItemDb.item(String(e.id)) if e is Dictionary and e.has("id") else {}
		_gear = Player.dress(_figure, item_at, String(c.get("active_weapon", "standard")), false)
	_figure.play("idle")


## The select view's camera (1.64: 420 units in front, 40 above the figure's feet, frustum T .1533 B -.1283 at near 1).
func _select_camera() -> void:
	var cam: Camera3D = _views["select"][1]
	cam.projection = Camera3D.PROJECTION_FRUSTUM
	cam.near = 1.0
	cam.far = 100.0
	cam.size = 0.2816
	cam.frustum_offset = Vector2(0, 0.0125)
	cam.keep_aspect = Camera3D.KEEP_HEIGHT
	cam.position = Vector3(-0.125, 1.0, 10.5)


## The creation views (1.64: both 420 units in front, 45 above; the body frustum +-0.141 high, the face close-up a
## narrow one on the head).
func _creation_cameras(body: SubViewport, _head: SubViewport) -> void:
	var cam: Camera3D = _views["body"][1]
	cam.projection = Camera3D.PROJECTION_FRUSTUM
	cam.near = 1.0
	cam.far = 100.0
	cam.size = 0.282
	cam.keep_aspect = Camera3D.KEEP_HEIGHT
	cam.position = Vector3(0, 1.125, 10.5)
	var hc: Camera3D = _views["head"][1]
	hc.projection = Camera3D.PROJECTION_FRUSTUM
	hc.near = 1.0
	hc.far = 100.0
	hc.size = 0.044
	hc.keep_aspect = Camera3D.KEEP_HEIGHT
	hc.position = Vector3(0, _head_height(), 10.5)


func _head_height() -> float:
	if _figure:
		for sk in _figure.find_children("*", "Skeleton3D", true, false):
			var s := sk as Skeleton3D
			var i := s.find_bone("Bip01 Head")
			if i >= 0:
				return (s.global_transform * s.get_bone_global_pose(i)).origin.y + 0.08
	return 1.62
