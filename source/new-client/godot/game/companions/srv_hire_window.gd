class_name SrvHireWindow
extends ClassicWindow
## True 1.65 Mode (LOCAL ONLY): the traveler's-inn innkeeper's hiring window - and the healer's, for a free REVIVE -
## drawn from the server's messages (CompanionNet, plan 17g). Every choice is the server's: the arrows and buttons send
## /companionui commands and the server answers with the new page. The preview is the companion's own classic figure,
## from the hire page's numbers (race, gender, model).
##   YOUR COMPANIONS: each hired companion - name, class and level, where it is, its XP bubbles, and the buttons the
##     server allows (SUMMON, DISMISS, RELEASE, REVIVE) plus MANAGE (its gear, spec, stats, realm abilities)
##   HIRE A COMPANION: race, class, gender, face, hair, name, what it costs, HIRE

const SIZE := Vector2(460, 312)
const ROW_H := 30.0

var net: CompanionNet
var manage: Callable                            # (row, page) -> that companion's window on a page (GameUI)
var _title: Label
var _tabs: Array = []
var _pages: Array = []
var _slots: Label
var _list: VBoxContainer
var _values := {}                               # hire page: text slot -> its value label
var _height: Label                              # hire page: SHORT / AVERAGE / TALL
var _name: LineEdit
var _blurb: Label
var _cost: Label
var _problem: Label
var _hire: Button
var _vp: SubViewport
var _pivot: Node3D
var _figure: Fig3Figure
var _figure_key := ""
var _turn := 0.0


func build() -> void:
	closable = true
	_title = CompanionUi.frame(self, "companion_hire", SIZE, Vector2(160, 60), "INNKEEPER")
	_tabs = CompanionUi.tabs(self, ["Your companions", "Hire a companion"], Vector2(12, 20), SIZE.x - 24, show_page)
	for i in 2:
		var page := Control.new()
		page.position = Vector2(0, 40)
		page.size = Vector2(SIZE.x, SIZE.y - 44)
		page.mouse_filter = Control.MOUSE_FILTER_PASS
		add_child(page)
		_pages.append(page)
	_build_roster(_pages[0])
	_build_hire(_pages[1])
	show_page(0)
	net.opened.connect(func(m: int):
		_title.text = "HEALER - YOUR COMPANIONS" if m == 1 else (String(net.texts.get(0, "INNKEEPER")).to_upper())
		(_tabs[1] as Button).visible = m == 0
		show_window()
		show_page(0 if m == 1 or not net.roster.is_empty() else 1)
		refresh())
	net.closed.connect(hide_window)
	net.changed.connect(refresh)


func hide_window() -> void:
	if visible and net:
		net.command("close")                              # (the server takes down its preview and forgets the page)
	super.hide_window()


func show_page(i: int) -> void:
	for k in _pages.size():
		(_pages[k] as Control).visible = k == i
	CompanionUi.select_tab(_tabs, i)
	refresh()


func refresh() -> void:
	if not visible or net == null:
		return
	if net.texts.has(0) and net.mode == 0:
		_title.text = String(net.texts[0]).to_upper()
	_refresh_roster()
	_refresh_hire()


# --- your companions ------------------------------------------------------------------------------------------

func _build_roster(page: Control) -> void:
	_slots = CompanionUi.text(page, "", Vector2(14, 0), Vector2(SIZE.x - 28, 12), 8, UiArt.GOLD)
	var box := CompanionUi.inset(page, Vector2(12, 16), Vector2(SIZE.x - 24, SIZE.y - 66))
	var sc := ScrollContainer.new()
	sc.position = Vector2(3, 3)
	sc.size = box.size - Vector2(6, 6)
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	box.add_child(sc)
	_list = VBoxContainer.new()
	_list.custom_minimum_size = Vector2(sc.size.x - 10, 0)
	_list.add_theme_constant_override("separation", 2)
	sc.add_child(_list)


func _refresh_roster() -> void:
	var line := String(net.texts.get(9, ""))
	if line == "":
		line = "COMPANIONS %d OF %d (%d SLOTS)%s" % [int(net.slots.used), int(net.slots.open), int(net.slots.total),
				("   -   NEXT SLOT AT LEVEL %d" % int(net.slots.next)) if int(net.slots.next) > 0 else ""]
	_slots.text = line.to_upper()
	for c in _list.get_children():
		c.queue_free()
	# (the server sends unused rows named "(empty)" / "(locked)" - server chat 2026-10-30; they aren't companions)
	var rows: Array = net.roster.keys().filter(func(r): return not net.row_name(int(r)).to_lower() in ["(empty)", "(locked)"])
	rows.sort()
	if rows.is_empty():
		CompanionUi.text(_list, "NO COMPANIONS YET." if net.mode == 1 else "NO COMPANIONS YET - HIRE ONE ON THE NEXT PAGE.",
				Vector2.ZERO, Vector2(380, 14), 8, CompanionUi.DIM)
		return
	for r in rows:
		_list.add_child(_row(int(r), net.roster[r]))


## A roster row, as the original client's (original-client chat 2026-10-30 - both clients the same): name, class and
## level, where, XP bubbles, then SUMMON / DISMISS / RELEASE / REVIVE as the server's button bits allow, each
## "/companionui <verb> <row>", and MANAGE ("select <row>" and that companion's window). The healer: REVIVE only.
func _row(r: int, rec: Dictionary) -> Control:
	var row := Control.new()
	row.custom_minimum_size = Vector2(_list.custom_minimum_size.x, ROW_H)
	var state := int(rec.get("state", 0))
	CompanionUi.text(row, net.row_name(r), Vector2(4, 2), Vector2(120, 12), 9, UiArt.GOLD_HI)
	var cls := net.row_class_line(r)
	if cls == "":
		cls = "LEVEL %d" % int(rec.level)
	CompanionUi.text(row, cls, Vector2(4, 15), Vector2(120, 12), 8)
	var where := net.row_where(r)
	if where == "":
		where = ["AT THE INN", "WITH YOU", "DEAD"][clampi(state, 0, 2)]
	CompanionUi.text(row, where, Vector2(126, 2), Vector2(84, 12), 8,
			CompanionUi.RED if state == 2 else (CompanionUi.GREEN if state == 1 else CompanionUi.DIM))
	row.add_child(XpBubbles.make(int(rec.get("xp", 0)), Vector2(126, 17), Vector2(80, 6)))
	var b := int(rec.get("buttons", 0))
	# the innkeeper: SUMMON / DISMISS / RELEASE / MANAGE; a healer: REVIVE only - companions are revived at healers
	# (owner 2026-10-30, both clients; REVIVE under MANAGE had left a grey sliver beside it)
	var x := 212.0
	for spec in [[1, "Summon", "summon"], [2, "Dismiss", "dismiss"], [4, "Release", "release"], [8, "Revive", "revive"]]:
		if (net.mode == 1) != (String(spec[2]) == "revive"):
			continue
		var cmd := "%s %d" % [String(spec[2]), r]
		var btn := CompanionUi.button(row, String(spec[1]), Vector2(x, 7), Vector2(48, 15), func(): net.command(cmd), 8)
		btn.disabled = not (b & int(spec[0]))
		x += 51.0
	if net.mode == 0 and manage.is_valid():
		CompanionUi.button(row, "Manage", Vector2(x + 4, 7), Vector2(52, 15), func():
			net.command("select %d" % r)
			manage.call(r, 0), 8)
	return row


# --- hire a companion -----------------------------------------------------------------------------------------

func _build_hire(page: Control) -> void:
	# one LOOK picker for face and hair (owner 2026-10-30: "merge the buttons into one option" - a classic figure's looks
	# are fixed face + hair pairs): "/companionui look- / look+", the server's "Look n of N" in text slot 4
	# and HAIR COLOR (owner 2026-10-30: "there needs to be hair color options"): hair- / hair+, the server's
	# "Hair colour n of N" in text slot 5 - an index into the look's hair.csv set (op 4 [12] / [13])
	# and HEIGHT (owner 2026-10-31, server chat: a hired Bard came out taller than his own character): height- /
	# height+, Short / Average / Tall as the period creation page (op 4 [21])
	var rows := [[1, "RACE", "race"], [2, "CLASS", "class"], [3, "GENDER", ""], [4, "LOOK", "look"], [5, "HAIR", "hair"],
			[-1, "HEIGHT", "height"]]
	for i in rows.size():
		var spec: Array = rows[i]
		var y := 2.0 + i * 20.0
		CompanionUi.text(page, String(spec[1]), Vector2(14, y + 2), Vector2(56, 12), 8, UiArt.GOLD)
		var key := String(spec[2])
		if key == "":
			CompanionUi.button(page, "<", Vector2(72, y), Vector2(16, 15), func(): net.command("gender"), 9)
			CompanionUi.button(page, ">", Vector2(214, y), Vector2(16, 15), func(): net.command("gender"), 9)
		else:
			CompanionUi.button(page, "<", Vector2(72, y), Vector2(16, 15), func(): net.command(key + "-"), 9)
			CompanionUi.button(page, ">", Vector2(214, y), Vector2(16, 15), func(): net.command(key + "+"), 9)
		var v := CompanionUi.text(page, "", Vector2(90, y + 2), Vector2(122, 12), 8)
		v.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		if int(spec[0]) < 0:
			_height = v
		else:
			_values[int(spec[0])] = v
	CompanionUi.button(page, "New look", Vector2(72, 122), Vector2(158, 15), func(): net.command("look"), 8)
	CompanionUi.text(page, "NAME", Vector2(14, 144), Vector2(56, 12), 8, UiArt.GOLD)
	_name = CompanionUi.field(page, Vector2(72, 141), Vector2(76, 17), "NAME")
	_name.max_length = 20                              # (the server's rule: letters only, at most 20)
	# SET, as the original client's NAME row (owner 2026-10-30: "so I can type my own name"); Enter / leaving the box too
	CompanionUi.button(page, "Set", Vector2(150, 142), Vector2(28, 15), func():
		if _name.text.strip_edges() != "":
			net.command("name " + _name.text.strip_edges()), 8)
	_name.text_submitted.connect(func(t: String): net.command("name " + t.strip_edges()))
	_name.focus_exited.connect(func():
		if _name.text.strip_edges() != "" and _name.text.strip_edges() != String(net.texts.get(6, "")):
			net.command("name " + _name.text.strip_edges()))
	CompanionUi.button(page, "Random", Vector2(180, 142), Vector2(50, 15), func(): net.command("name"), 8)
	_blurb = CompanionUi.text(page, "", Vector2(14, 162), Vector2(218, 44), 8, UiArt.CREAM, true)
	_cost = CompanionUi.text(page, "", Vector2(14, 207), Vector2(218, 12), 8, UiArt.GOLD)
	_problem = CompanionUi.text(page, "", Vector2(14, 220), Vector2(218, 20), 8, CompanionUi.RED, true)
	_hire = CompanionUi.button(page, "Hire", Vector2(60, 242), Vector2(120, 18), func(): net.command("hire"), 10)
	var box := CompanionUi.inset(page, Vector2(244, 0), Vector2(204, 262))
	var cont := SubViewportContainer.new()
	cont.stretch = true
	cont.position = Vector2(2, 2)
	cont.size = box.size - Vector2(4, 4)
	cont.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(cont)
	_vp = SubViewport.new()
	_vp.own_world_3d = true
	_vp.transparent_bg = true
	_vp.size = Vector2i(400, 516)
	cont.add_child(_vp)
	var cam := Camera3D.new()
	cam.position = Vector3(0, 1.05, 3.2)
	cam.fov = 38
	_vp.add_child(cam)
	cam.look_at(Vector3(0, 0.95, 0))
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-35, 25, 0)
	sun.light_energy = 1.4
	_vp.add_child(sun)
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color(0.55, 0.52, 0.48)
	env.environment.ambient_light_energy = 0.9
	_vp.add_child(env)
	_pivot = Node3D.new()
	_vp.add_child(_pivot)


func _refresh_hire() -> void:
	if _hire == null:
		return
	for k in _values:
		(_values[k] as Label).text = String(net.texts.get(k, "")).to_upper()
	if _height:
		_height.text = ["AVERAGE", "SHORT", "AVERAGE", "TALL"][clampi(int(net.hire.get("height", 2)), 0, 3)]
	if not _name.has_focus():
		_name.text = String(net.texts.get(6, ""))
	_blurb.text = "%s %s %s" % [String(net.texts.get(10, "")), String(net.texts.get(11, "")), String(net.texts.get(12, ""))]
	var cost := int(net.hire.get("cost", 0))
	_cost.text = String(net.texts.get(7, "")).to_upper() if net.texts.has(7) else \
			("COST: " + ("FREE" if cost == 0 else PlayerData.money_string(cost).to_upper()))
	_problem.text = String(net.texts.get(8, ""))
	_hire.disabled = not bool(net.hire.get("enabled", false))
	_update_figure()


## The companion as it would look: its race and gender's figure (classic in True 1.65 Mode) with the server's model id
## for its face / hair (ClassicFigure.look_row) - or the Catacombs look from the face / hair / colour numbers.
func _update_figure() -> void:
	if net.hire.is_empty() or not Server.RACES.has(int(net.hire.race)):
		return
	var prefix := "%s_%s" % [Server.RACES[int(net.hire.race)][1], "f" if int(net.hire.gender) == 1 else "m"]
	var look := {"model": int(net.hire.model)} if Fig3Figure.classic() else \
			{"face": int(net.hire.face), "hair": int(net.hire.hair), "hair_color": int(net.hire.hair_color)}
	if Fig3Figure.classic() and int(net.hire.get("colors", 0)) > 0:
		look["hair_index"] = int(net.hire.hair_color)       # (a server with the HAIR COLOR row: the look's hair.csv set)
	if Fig3Figure.classic():
		look["height"] = int(net.hire.get("height", 2))
	var key := "%s|%s" % [prefix, JSON.stringify(look)]
	if key == _figure_key:
		return
	_figure_key = key
	if _figure:
		_figure.queue_free()
	_figure = Fig3Figure.make()
	_pivot.add_child(_figure)
	_fit_height = ClassicFigure.height_factor(int(look.get("height", 2)))
	if _figure.load_figure(prefix):
		_figure.apply(look)
		# straight into the idle pose: play() blends 0.15 s in from the bind pose, so every new look showed a T-pose
		# first (owner 2026-10-30: "hair works but causes a t pose")
		if _figure.anim and _figure.anim.has_animation("idle"):
			_figure.anim.play("idle")
			_figure.anim.advance(0.0)
	_fit.call_deferred()


const FIT_HEIGHT := 1.85
var _fit_height := 1.0                          # the HEIGHT's factor: Tall fills the box, Average / Short stand lower


func _fit() -> void:
	if _pivot == null or not is_inside_tree():
		return
	await get_tree().process_frame
	_pivot.scale = Vector3.ONE
	_pivot.position = Vector3.ZERO
	var lo := INF
	var hi := -INF
	for mi in _pivot.find_children("*", "MeshInstance3D", true, false):
		var m := mi as MeshInstance3D
		if not m.is_visible_in_tree() or m.mesh == null:
			continue
		var box: AABB = _pivot.global_transform.affine_inverse() * m.global_transform * m.get_aabb()
		lo = minf(lo, box.position.y)
		hi = maxf(hi, box.end.y)
	if hi > lo:
		var k := FIT_HEIGHT / ClassicFigure.height_factor(3) * _fit_height / (hi - lo)
		_pivot.scale = Vector3.ONE * k
		_pivot.position.y = -lo * k


func _process(delta: float) -> void:
	if _figure and visible and (_pages[1] as Control).visible:
		_turn += delta * 0.6
		_figure.rotation.y = sin(_turn) * 0.7


## The 1.65 XP bubbles: ten per level, the last one filling (per mille of the level).
class XpBubbles extends Control:
	var permille := 0

	static func make(pm: int, pos: Vector2, sz: Vector2) -> XpBubbles:
		var b := XpBubbles.new()
		b.permille = pm
		b.position = pos
		b.size = sz
		b.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.tooltip_text = "%d%% OF THE LEVEL" % (pm / 10)
		return b

	func _draw() -> void:
		var w := size.x / 10.0
		for i in 10:
			var r := Rect2(i * w + 0.5, 0, w - 1.0, size.y)
			draw_rect(r, Color(0.08, 0.07, 0.06))
			var fill := clampf((permille - i * 100) / 100.0, 0.0, 1.0)
			if fill > 0.0:
				draw_rect(Rect2(r.position, Vector2(r.size.x * fill, r.size.y)), Color(0.85, 0.7, 0.3))
			draw_rect(r, UiArt.GOLD.darkened(0.45), false, 1.0)
