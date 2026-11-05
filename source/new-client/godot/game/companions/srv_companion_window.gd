class_name SrvCompanionWindow
extends ClassicWindow
## True 1.65 Mode: one hired companion's window, from the server's messages (CompanionNet, plan 17h).
##   GEAR   its worn items on a paper doll and its bag - 10 slots, no weight limit (op 7; owner 2026-10-30). Drag an item from your backpack onto a slot to put it on
##          (/companionui equip, or swap when the slot is taken), right-click or double-click one to take it back
##          (unequip). REPAIR repairs it all at a smith (the server asks the price first).
##   TRAIN  its spec lines, points, the next level's cost and what each level gives (op 8 / 9): TRAIN, and RESPEC (free)
##   STATS  level and XP bubbles, its stats, health / power / endurance, armour, resists, money, realm points (op 10)
##   REALM  its realm rank and abilities (op 11): BUY the next level
## Nothing here decides: every button is a /companionui command and the server answers with fresh messages.

const SIZE := Vector2(470, 345)
const DOLL := [[21, 29, 26], [25, 28, 22], [32, 27, 23], [33, 34, 24], [35, 36, -1], [10, 11, 12], [13, -1, -1]]

var net: CompanionNet
var row := 0
var _title: Label
var _tabs: Array = []
var _pages: Array = []
var _page := 0
var _problem: Label
# gear
var _doll_vp: SubViewport
var _doll_view: TextureRect
var _doll_fig: Node3D             # the pivot Node3D holding the Fig3Figure
var _doll_figure: Fig3Figure      # the figure itself, for turning
var _turn := false                # dragging the doll turns it
var _gear_cells: Array = []
var _bag: VBoxContainer
var _bag_title: Label
const BAG_SLOTS := 10
const BAG_FIRST := 40                               # (the companion's own backpack slots 40 - 49)
# spec
var _spec_points: Label
var _spec_list: VBoxContainer
var _preview_list: VBoxContainer
var _preview_line := -1
# stats
var _stats_box: Control
# realm
var _ra_head: Label
var _ra_list: VBoxContainer


func build() -> void:
	closable = true
	_title = CompanionUi.frame(self, "companion_manage", SIZE, Vector2(200, 80), "COMPANION")
	_tabs = CompanionUi.tabs(self, ["Gear", "Train", "Stats", "Realm abilities"], Vector2(12, 20), SIZE.x - 24, show_page)
	for i in 4:
		var page := Control.new()
		page.position = Vector2(0, 40)
		page.size = Vector2(SIZE.x, SIZE.y - 60)
		page.mouse_filter = Control.MOUSE_FILTER_PASS
		add_child(page)
		_pages.append(page)
	_build_gear(_pages[0])
	_build_spec(_pages[1])
	_build_stats(_pages[2])
	_build_realm(_pages[3])
	_problem = CompanionUi.text(self, "", Vector2(14, SIZE.y - 18), Vector2(SIZE.x - 28, 12), 8, CompanionUi.RED)
	net.changed.connect(refresh)


## Open this window on a roster row, at a page (0 gear, 1 spec, 2 stats, 3 realm abilities).
func open_row(r: int, page := 0) -> void:
	row = r
	show_window()
	net.command("stats %d" % row)
	show_page(page)


func show_page(i: int) -> void:
	_page = i
	for k in _pages.size():
		(_pages[k] as Control).visible = k == i
	CompanionUi.select_tab(_tabs, i)
	match i:
		0: net.command("gear %d" % row)
		1: net.command("spec %d" % row)
		2: net.command("stats %d" % row)
		3: net.command("ra %d" % row)
	refresh()


## The GEAR tab asks again every few seconds while it is open: the server sends a stack's count (arrows, poisons, thrown
## weapons) only when the gear is sent, and the companion uses them up as it fights.
const GEAR_POLL_S := 5.0
var _gear_poll := 0.0


func _process(delta: float) -> void:
	if not visible or net == null or _page != 0:
		_gear_poll = 0.0
		return
	_gear_poll += delta
	if _gear_poll >= GEAR_POLL_S:
		_gear_poll = 0.0
		net.command("gear %d" % row)
	# turn the paperdoll while dragging it
	if _turn and _doll_figure:
		_doll_figure.rotation.y += delta * 1.0


func _gui_input(event: InputEvent) -> void:
	# let ClassicWindow handle close (top-right cross) and drag (top band / move handle)
	super._gui_input(event)
	# turn the paperdoll while dragging it on the doll area
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		_turn = event.pressed
	elif event is InputEventMouseMotion and _turn:
		_doll_fig.rotation.y += event.relative.x * 0.02


func refresh() -> void:
	if not visible or net == null:
		return
	var nm := net.row_name(row)
	var st: Dictionary = net.stats.get(row, {})
	_title.text = ("%s - LEVEL %d" % [nm, int(st.level)] if not st.is_empty() else nm).to_upper() if nm != "" else "COMPANION"
	_problem.text = String(net.texts.get(8, ""))
	match _page:
		0: _refresh_gear()
		1: _refresh_spec()
		2: _refresh_stats()
		3: _refresh_realm()


static func _scroll_list(parent: Control, pos: Vector2, size: Vector2) -> VBoxContainer:
	var box := CompanionUi.inset(parent, pos, size)
	var sc := ScrollContainer.new()
	sc.position = Vector2(3, 3)
	sc.size = box.size - Vector2(6, 6)
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	sc.mouse_filter = Control.MOUSE_FILTER_PASS        # (drops on it reach its parent: the bag's drop target)
	box.add_child(sc)
	var list := VBoxContainer.new()
	list.custom_minimum_size = Vector2(sc.size.x - 10, 0)
	list.add_theme_constant_override("separation", 2)
	sc.add_child(list)
	return list


static func _clear(c: Control) -> void:
	for k in c.get_children():
		k.queue_free()


# --- gear -----------------------------------------------------------------------------------------------------

func _build_gear(page: Control) -> void:
	CompanionUi.text(page, "WORN - DRAG FROM YOUR BACKPACK TO EQUIP, RIGHT-CLICK TO TAKE BACK", Vector2(14, 0),
			Vector2(300, 12), 7, CompanionUi.DIM)
	# paperdoll figure centered between left ring (slot 35) and right ring (slot 36),
	# like inventory_sheet.gd's middle column
	_doll_vp = SubViewport.new()
	_doll_vp.size = Vector2i(100, 140)
	_doll_vp.own_world_3d = true
	_doll_vp.transparent_bg = true
	_doll_vp.msaa_3d = Viewport.MSAA_4X
	_doll_vp.render_target_update_mode = SubViewport.UPDATE_WHEN_VISIBLE
	page.add_child(_doll_vp)
	_doll_view = TextureRect.new()
	_doll_view.texture = _doll_vp.get_texture()
	_doll_view.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_doll_view.stretch_mode = TextureRect.STRETCH_SCALE
	_doll_view.position = Vector2(161.5, 80.5)
	_doll_view.size = Vector2(100, 140)
	_doll_view.mouse_filter = Control.MOUSE_FILTER_IGNORE
	page.add_child(_doll_view)
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_CLEAR_COLOR
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color(0.55, 0.55, 0.6)
	_doll_vp.add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-35, 25, 0)
	sun.light_energy = 1.1
	_doll_vp.add_child(sun)
	var cam := Camera3D.new()
	cam.fov = 30
	cam.keep_aspect = Camera3D.KEEP_HEIGHT
	cam.position = Vector3(0, 0.95, 4.2)
	_doll_vp.add_child(cam)
	cam.look_at(Vector3(0, 0.92, 0))
	_doll_fig = Node3D.new()
	_doll_vp.add_child(_doll_fig)
	_doll_fig.rotation.y = deg_to_rad(15)
	_dress_doll()
	_doll_vp.call_deferred("set_render_target_update_mode", SubViewport.UPDATE_ALWAYS)
	# repair button under the left hand / two-hand slots
	CompanionUi.button(page, "Repair", Vector2(161, 280), Vector2(100, 16), func(): net.command("repair %d" % row), 9)
	# its bag: 10 slots, no weight limit (owner 2026-10-30, as the server built it) - drag an item onto the list to put it
	# in, right-click one to take it back
	_bag_title = CompanionUi.text(page, "ITS BAG", Vector2(318, 0), Vector2(140, 12), 8, UiArt.GOLD)
	_bag = VBoxContainer.new()
	_bag.position = Vector2(318, 14)
	_bag.size = Vector2(140, 206)
	page.add_child(_bag)


func _dress_doll() -> void:
	# companion appearance: from the roster (world right-click) or the hire page (innkeeper/healer).
	# fall back to a default figure so the paperdoll always shows something.
	var hire_data: Dictionary = net.roster.get(row, {})
	if hire_data.is_empty():
		hire_data = net.hire
	# clear any previous figure
	for c in _doll_fig.get_children():
		c.queue_free()
	# build the figure prefix from race/gender; default to cel_m when no hire data is available yet
	var race_id := int(hire_data.get("race", 0))
	var race_info: Array = Server.RACES.get(race_id, [])
	var prefix := "cel_m"
	if race_info.size() >= 2:
		prefix = "%s_%s" % [String(race_info[1]), "f" if int(hire_data.get("gender", 0)) == 1 else "m"]
	var f := Fig3Figure.make()
	_doll_fig.add_child(f)
	_doll_figure = f
	var look := {"model": int(hire_data.get("model", 0))} if Fig3Figure.classic() else \
		{"face": int(hire_data.get("face", 0)), "hair": int(hire_data.get("hair", 0)), "hair_color": int(hire_data.get("hair_color", 0))}
	if Fig3Figure.classic():
		look["height"] = int(hire_data.get("height", 2))
	if f.load_figure(prefix):
		f.apply(look)
		# dress from worn gear
		var gear: Dictionary = net.gear.get(row, {})
		Player.dress(f, func(s): return gear.get(s, {}), "", false, true, gear)
	call_deferred("_fit_doll")

func _fit_doll() -> void:
	if not is_inside_tree() or _doll_fig == null:
		return
	await get_tree().process_frame
	_doll_fig.scale = Vector3.ONE
	var lo := INF
	var hi := -INF
	for mi in _doll_fig.find_children("*", "MeshInstance3D", true, false):
		var m := mi as MeshInstance3D
		if not m.is_visible_in_tree() or m.mesh == null:
			continue
		var box: AABB = _doll_fig.global_transform.affine_inverse() * m.global_transform * m.get_aabb()
		lo = minf(lo, box.position.y)
		hi = maxf(hi, box.end.y)
	if hi > lo:
		var k := 1.75 / (hi - lo)
		_doll_fig.scale = Vector3.ONE * k
		_doll_fig.position.y = -lo * k

func _refresh_gear() -> void:
	# re-dress the paperdoll when worn gear changes
	_dress_doll()
	# clear old gear slot cells
	for c in _gear_cells:
		if c and is_instance_valid(c):
			c.queue_free()
	_gear_cells.clear()
	# equipment slots at inventory_sheet.gd's SLOTS positions (all slots shown, empty ones as placeholders)
	var items: Dictionary = net.gear.get(row, {})
	var pg: Control = _pages[0]
	var SLOTS := {
		25: Rect2(7, 36, 31, 31), 21: Rect2(155, 36, 31, 31),
		29: Rect2(41, 36, 15, 15), 26: Rect2(137, 36, 15, 15),
		28: Rect2(7, 75, 31, 31), 22: Rect2(155, 75, 31, 31),
		24: Rect2(7, 116, 15, 15), 32: Rect2(171, 116, 15, 15),
		35: Rect2(7, 143, 15, 15), 36: Rect2(171, 143, 15, 15),
		33: Rect2(7, 170, 15, 15), 34: Rect2(171, 170, 15, 15),
		27: Rect2(7, 196, 31, 31), 23: Rect2(155, 196, 31, 31),
		10: Rect2(14, 239, 31, 31), 11: Rect2(58, 239, 31, 31),
		12: Rect2(102, 239, 31, 31), 13: Rect2(146, 239, 31, 31)
	}
	for slot_id in SLOTS.keys():
		var r: Rect2 = SLOTS[slot_id]
		var cell := GearSlot.new()
		cell.window = self
		cell.slot = slot_id
		cell.item = items.get(slot_id, {})
		cell.position = Vector2(115.0 + r.position.x, 0.0 + r.position.y)
		cell.size = Vector2(r.size.x, r.size.y)
		pg.add_child(cell)
		_gear_cells.append(cell)
		# slot caption centered below the box (like inventory_sheet.gd's painted labels beside each slot)
		var label_w: float
		var label_x: float
		var label_align: HorizontalAlignment
		if slot_id in [10, 11, 12, 13]:          # weapons: wider label so "R HAND" / "L HAND" don't collide
			label_w = 44.0
			label_x = 115.0 + r.position.x + r.size.x / 2.0 - label_w / 2.0
			label_align = HORIZONTAL_ALIGNMENT_CENTER
		elif slot_id in [21, 22, 23]:			# Helm Hands and Feet
			label_w = r.size.x
			label_x = 115.0 + r.position.x
			label_align = HORIZONTAL_ALIGNMENT_CENTER
		elif r.position.x >= 137:                 # right column: right-align so text stays within cell width
			label_w = 44.0                        # wider than the cell: text extends leftward into empty page space
			label_x = 115.0 + r.position.x + r.size.x - label_w   # right edge of label = right edge of cell
			label_align = HORIZONTAL_ALIGNMENT_RIGHT
		else:
			label_w = r.size.x
			label_x = 115.0 + r.position.x
			label_align = HORIZONTAL_ALIGNMENT_CENTER
		var label_y := r.position.y + r.size.y + 2.0
		var slabel := CompanionUi.text(pg, String(CompanionNet.SLOT_NAMES.get(slot_id, "")),
				Vector2(label_x, label_y), Vector2(label_w, 12), 7, CompanionUi.DIM)
		slabel.horizontal_alignment = label_align
	# the bag: its 10 slots (the companion's backpack 40 - 49, server protocol, 2026-10-30), each a drop target
	if _bag:
		_clear(_bag)
	var used := 0
	for s in range(BAG_FIRST, BAG_FIRST + BAG_SLOTS):
		var cell := GearSlot.new()
		cell.window = self
		cell.slot = s
		cell.item = items.get(s, {})
		cell.custom_minimum_size = Vector2(120, 22)
		cell.size = Vector2(120, 22)
		_bag.add_child(cell)
		if items.has(s):
			used += 1
	_bag_title.text = "BAG (%d / %d)" % [used, BAG_SLOTS]


## An item from your backpack onto one of its slots: a bag slot (or the bag, -1) puts it in the bag - "bag", which takes
## anything; a worn slot puts it on - "equip" (or "swap" when the slot is taken).
func equip_from(backpack_slot: int, onto: int, taken: bool) -> void:
	if onto < 0 or (onto >= BAG_FIRST and onto < BAG_FIRST + BAG_SLOTS):
		net.command("bag %d %d%s" % [row, backpack_slot, (" %d" % onto) if onto >= 0 and not taken else ""])
		return
	if taken:
		net.command("swap %d %d %d" % [row, onto, backpack_slot])
	else:
		net.command("equip %d %d" % [row, backpack_slot])


func unequip(slot: int) -> void:
	net.command("unequip %d %d" % [row, slot])


## The bag list as a drop target: an item from your backpack put into the bag (the server's equip puts what it can't
## wear into the bag).
class BagDrop extends Control:
	var window: SrvCompanionWindow

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_PASS

	func _can_drop_data(_p: Vector2, data: Variant) -> bool:
		return InventorySheet.is_item(data) and int(data.slot) >= 40 and int(data.slot) <= 79

	func _drop_data(_p: Vector2, data: Variant) -> void:
		window.equip_from(int(data.slot), -1, false)


class GearSlot extends Control:
	const STACKABLE := [16, 43, 44, 46]                # eObjectType Thrown, Arrow, Bolt, Poison
	var window: SrvCompanionWindow
	var slot := 0
	var item := {}
	var _icon: TextureRect
	var _rim: Panel
	var _name: Label
	var _cond: Label

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_STOP
		# drag-target highlight border (like InventorySheet.EquipSlot._rim)
		_rim = Panel.new()
		var s := StyleBoxFlat.new()
		s.bg_color = Color(0, 0, 0, 0)
		s.border_color = UiArt.GOLD
		s.set_border_width_all(1.0)
		_rim.add_theme_stylebox_override("panel", s)
		_rim.set_anchors_preset(Control.PRESET_FULL_RECT)
		_rim.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_rim.visible = false
		add_child(_rim)
		# item icon, always shown; hover shows the tooltip only (like EquipSlot)
		_icon = TextureRect.new()
		_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		_icon.stretch_mode = TextureRect.STRETCH_SCALE
		_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(_icon)
		# item name / condition labels. Bag slots (40-49) show these always; worn
		# slots keep them empty so hover shows the tooltip only (like EquipSlot).
		_name = UiArt.label("", 7, UiArt.CREAM)
		_name.clip_text = true
		_name.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(_name)
		_cond = UiArt.label("", 7, CompanionUi.DIM)
		_cond.clip_text = true
		_cond.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(_cond)

	func _ready() -> void:
		if size.x <= 0.0:
			size = custom_minimum_size
		refresh()

	## Sync the persistent icon + (bag-only) name/condition labels with the item.
	func refresh() -> void:
		if item.is_empty():
			_icon.texture = null
			_name.text = ""
			_cond.text = ""
			tooltip_text = String(CompanionNet.SLOT_NAMES.get(slot, "BAG %d" % (slot - SrvCompanionWindow.BAG_FIRST + 1))).to_upper()
			queue_redraw()
			return
		var ic := Server.item_icon(int(item.model))
		_icon.texture = ItemDb.icon(ic if ic > 0 else int(item.icon))
		_icon.position = Vector2(2, 2)
		_icon.size = Vector2(size.y - 4, size.y - 4)
		var is_bag := slot >= BAG_FIRST
		if is_bag:
			var name_text := String(CompanionNet.SLOT_NAMES.get(slot, "BAG %d" % (slot - SrvCompanionWindow.BAG_FIRST + 1)))
			_name.text = String(item.name)
			_name.position = Vector2(size.y + 2, 2)
			_name.size = Vector2(size.x - size.y - 4, 12)
			var cond := int(item.condition)
			var count := int(item.get("count", 0))
			var stack := int(item.object_type) in STACKABLE or count > 1
			var second := ("%s  x%d" % [name_text, count]) if stack and count > 0 else "%s  %d%%" % [name_text, cond]
			_cond.text = second
			_cond.position = Vector2(size.y + 2, 15)
			_cond.size = Vector2(size.x - size.y - 4, 12)
			_cond.add_theme_color_override("font_color", CompanionUi.RED if stack and count > 0 and count <= 5 else CompanionUi.DIM)
			tooltip_text = String(item.name).to_upper()
		else:
			# worn slot: icon only; hover reveals the tooltip (like EquipSlot)
			_name.text = ""
			_cond.text = ""
			tooltip_text = String(item.name).to_upper()
		queue_redraw()

	func _gui_input(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.pressed:
			if item.is_empty():
				return
			var mb := event as InputEventMouseButton
			if mb.button_index == MOUSE_BUTTON_RIGHT or (mb.button_index == MOUSE_BUTTON_LEFT and mb.double_click):
				window.unequip(slot)
				accept_event()

	func _notification(what: int) -> void:
		match what:
			NOTIFICATION_MOUSE_EXIT:
				refresh()
			NOTIFICATION_DRAG_END:
				_rim.visible = false
				refresh()

	func _draw() -> void:
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.05, 0.045, 0.04, 0.9))
		draw_rect(Rect2(Vector2.ZERO, size), UiArt.GOLD if _rim.visible else UiArt.GOLD.darkened(0.55), false, 1.0)

	## Hover popup: the mini delve box, drawn above other menus (like EquipSlot).
	func _make_custom_tooltip(_for_text: String) -> Object:
		var tip := ItemTooltip.make(item) if not item.is_empty() else null
		if tip == null and not item.is_empty():
			# non-gear items (potions, arrows, poisons): ItemTooltip.make returns null,
			# so build a simple name-only tooltip so hover still shows above everything
			tip = ItemTooltip.text_box(String(item.name).to_upper(), [])
		return tip

	func _can_drop_data(_p: Vector2, data: Variant) -> bool:
		var ok := InventorySheet.is_item(data) and int(data.slot) >= 40 and int(data.slot) <= 79
		_rim.visible = ok
		return ok

	func _drop_data(_p: Vector2, data: Variant) -> void:
		_rim.visible = false
		window.equip_from(int(data.slot), slot, not item.is_empty())

	## Dragged out onto your backpack (owner 2026-10-30: "i cant drag off weapons and bag items, i can only right click"):
	## the backpack takes it with the server's "unequip" - right-click / double-click still do the same.
	func _get_drag_data(_p: Vector2) -> Variant:
		if item.is_empty():
			return null
		var prev := TextureRect.new()
		var ic := Server.item_icon(int(item.model))
		prev.texture = ItemDb.icon(ic if ic > 0 else int(item.icon))
		prev.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		prev.size = Vector2(32, 32) * get_global_transform().get_scale()
		set_drag_preview(prev)
		return {"kind": "companion_item", "slot": slot, "name": String(item.name), "take": window.unequip.bind(slot)}


# --- spec -----------------------------------------------------------------------------------------------------

func _build_spec(page: Control) -> void:
	_spec_points = CompanionUi.text(page, "", Vector2(14, 0), Vector2(130, 12), 8, UiArt.GOLD)
	# (no confirm box of its own: as the original client, the server's answer is the respec - it's free). Over the spec
	# list, beside the points (owner 2026-10-30: on the right it lay over "WHAT EACH LEVEL GIVES")
	CompanionUi.button(page, "Respec (free)", Vector2(12 + 246 - 104, -2), Vector2(104, 15), func(): net.command("respec %d" % row), 8)
	_spec_list = _scroll_list(page, Vector2(12, 16), Vector2(246, 230))
	CompanionUi.text(page, "WHAT EACH LEVEL GIVES", Vector2(266, 2), Vector2(190, 12), 8, UiArt.GOLD)
	_preview_list = _scroll_list(page, Vector2(264, 16), Vector2(194, 230))


func _refresh_spec() -> void:
	var sp: Dictionary = net.spec.get(row, {})
	_spec_points.text = "SPEC POINTS: %d" % int(sp.get("points", 0))
	_clear(_spec_list)
	var lines: Array = sp.get("lines", [])
	for ln in lines:
		if not ln is Dictionary:
			continue
		var line: Dictionary = ln
		var r := Control.new()
		r.custom_minimum_size = Vector2(_spec_list.custom_minimum_size.x, 20)
		var idx := int(line.index)
		var nm := CompanionUi.button(r, String(line.name), Vector2(0, 2), Vector2(112, 15), func():
			_preview_line = idx
			_refresh_spec(), 8)
		nm.toggle_mode = true
		nm.button_pressed = idx == _preview_line
		CompanionUi.text(r, "%d / %d" % [int(line.level), int(line.cap)], Vector2(116, 4), Vector2(44, 12), 8)
		var cost := int(line.cost)
		var can := int(line.level) < int(line.cap) and cost > 0 and cost <= int(sp.get("points", 0))
		CompanionUi.text(r, ("COST %d" % cost) if int(line.level) < int(line.cap) else "MAX", Vector2(158, 4),
				Vector2(40, 12), 7, UiArt.CREAM if can else CompanionUi.DIM)
		var t := CompanionUi.button(r, "Train", Vector2(196, 2), Vector2(38, 15), func(): net.command("train %d %d" % [row, idx]), 8)
		t.disabled = not can
		_spec_list.add_child(r)
	if _preview_line < 0 and not lines.is_empty() and lines[0] is Dictionary:
		_preview_line = int(lines[0].index)
	_clear(_preview_list)
	# kind 4: a BASELINE spell (server protocol, 2026-10-31) - it comes with the companion's level, not its trained points,
	# drawn in its own cool grey (owner: "clear what each spec line actually unlocks"), never the dim of "not reached"
	var kinds := {1: "STYLE", 2: "SPELL", 3: "ABILITY", 4: "BASELINE"}
	var cur := -1
	for ln in lines:
		if ln is Dictionary and int(ln.index) == _preview_line:
			cur = int(ln.level)
	for e in (net.previews.get(row, {}) as Dictionary).get(_preview_line, []):
		var got := int(e.level) <= cur
		var col := CompanionUi.BASELINE if int(e.kind) == 4 else (UiArt.CREAM if got else CompanionUi.DIM)
		var l := CompanionUi.text(_preview_list, "%d  %s - %s" % [int(e.level), String(kinds.get(int(e.kind), "")), String(e.name)],
				Vector2.ZERO, Vector2(180, 12), 7, col)
		_skill_tip(l, e)


## Hovering a preview line shows what the style / spell / ability does (owner 2026-10-30: "when hovering over a spell or
## style it should tell me what it does") - the delve box from the client's own class data (SkillInfo), found by its
## name and icon: the previews are the companion's, not yours, so there is no server delve of them.
func _skill_tip(l: Label, e: Dictionary) -> void:
	var kind := String({1: "style", 2: "spell", 3: "ability", 4: "spell"}.get(int(e.kind), ""))
	if kind == "":
		return
	var id := ClassDb.find(kind, String(e.name), int(e.get("icon", -1)))
	if id == "":
		return
	var box := SkillTipLabel.new()
	box.entry = {"kind": kind, "id": id if kind == "ability" else int(id), "name": String(e.name)}
	box.tooltip_text = String(e.name)                      # (any text: Godot asks _make_custom_tooltip only then)
	box.mouse_filter = Control.MOUSE_FILTER_STOP
	box.size = l.size
	box.custom_minimum_size = Vector2(l.size.x, 12)
	l.add_child(box)


class SkillTipLabel extends Control:
	var entry := {}

	func _make_custom_tooltip(_for_text: String) -> Object:
		return ItemTooltip.text_box(String(entry.name), SkillInfo.lines(entry))


# --- stats ----------------------------------------------------------------------------------------------------

func _build_stats(page: Control) -> void:
	_stats_box = Control.new()
	_stats_box.position = Vector2(12, 0)
	_stats_box.size = Vector2(SIZE.x - 24, 250)
	page.add_child(_stats_box)


func _refresh_stats() -> void:
	_clear(_stats_box)
	var st: Dictionary = net.stats.get(row, {})
	if st.is_empty():
		CompanionUi.text(_stats_box, "ASKING...", Vector2(2, 2), Vector2(200, 12), 8, CompanionUi.DIM)
		return
	CompanionUi.text(_stats_box, "LEVEL %d  -  %s" % [int(st.level), net.row_class_line(row)], Vector2(2, 0), Vector2(300, 12), 9, UiArt.GOLD_HI)
	_stats_box.add_child(SrvHireWindow.XpBubbles.make(int(st.xp), Vector2(2, 16), Vector2(200, 8)))
	var names := ["STRENGTH", "CONSTITUTION", "DEXTERITY", "QUICKNESS", "INTELLIGENCE", "PIETY", "EMPATHY", "CHARISMA"]
	for i in 8:
		CompanionUi.text(_stats_box, names[i], Vector2(2, 32 + i * 14), Vector2(100, 12), 8, UiArt.GOLD)
		CompanionUi.text(_stats_box, str(int(st.stats[i])), Vector2(104, 32 + i * 14), Vector2(40, 12), 8)
	var right := [["HEALTH", "%d / %d" % [int(st.health), int(st.max_health)]], ["POWER", "%d / %d" % [int(st.power), int(st.max_power)]],
			["ENDURANCE", "%d / %d" % [int(st.endurance), int(st.max_endurance)]], ["ARMOR FACTOR", str(int(st.af))],
			["ABSORB", "%d%%" % int(st.absorb)], ["MONEY", PlayerData.money_string(int(st.money)).to_upper()],
			["REALM POINTS", "%d" % (int(st.rp) * 1000)]]
	for i in right.size():
		CompanionUi.text(_stats_box, String(right[i][0]), Vector2(170, 32 + i * 14), Vector2(100, 12), 8, UiArt.GOLD)
		CompanionUi.text(_stats_box, String(right[i][1]), Vector2(272, 32 + i * 14), Vector2(170, 12), 8)
	var resists := ["CRUSH", "SLASH", "THRUST", "HEAT", "COLD", "MATTER", "BODY", "SPIRIT", "ENERGY"]
	CompanionUi.text(_stats_box, "RESISTS", Vector2(2, 152), Vector2(100, 12), 9, UiArt.GOLD_HI)
	for i in 9:
		var x := 2.0 + (i % 5) * 88.0
		var y := 168.0 + (i / 5) * 14.0
		CompanionUi.text(_stats_box, "%s %d%%" % [resists[i], int(st.resists[i])], Vector2(x, y), Vector2(86, 12), 8)


# --- realm abilities ------------------------------------------------------------------------------------------

func _build_realm(page: Control) -> void:
	_ra_head = CompanionUi.text(page, "", Vector2(14, 0), Vector2(SIZE.x - 28, 12), 8, UiArt.GOLD)
	_ra_list = _scroll_list(page, Vector2(12, 16), Vector2(SIZE.x - 24, 230))


func _refresh_realm() -> void:
	_clear(_ra_list)
	var list: Array = (net.ras.get(row, []) as Array).filter(func(e): return e is Dictionary)
	if list.is_empty():
		_ra_head.text = "REALM ABILITIES"
		CompanionUi.text(_ra_list, "NONE YET.", Vector2.ZERO, Vector2(200, 12), 8, CompanionUi.DIM)
		return
	var first: Dictionary = list[0]
	_ra_head.text = "REALM RANK %dL%d   -   REALM ABILITY POINTS: %d" % [int(first.rank), int(first.sub), int(first.points)]
	for e in list:
		var r := Control.new()
		r.custom_minimum_size = Vector2(_ra_list.custom_minimum_size.x, 18)
		CompanionUi.text(r, String(e.name), Vector2(4, 3), Vector2(220, 12), 8, UiArt.CREAM)
		CompanionUi.text(r, "%d / %d" % [int(e.level), int(e.max)], Vector2(230, 3), Vector2(50, 12), 8)
		var maxed := int(e.level) >= int(e.max)
		var can := not maxed and int(e.cost) <= int(e.points)
		CompanionUi.text(r, "MAX" if maxed else "COST %d" % int(e.cost), Vector2(286, 3), Vector2(60, 12), 7,
				UiArt.CREAM if can else CompanionUi.DIM)
		var idx := int(e.index)
		var b := CompanionUi.button(r, "Buy", Vector2(352, 1), Vector2(44, 15), func(): net.command("buyra %d %d" % [row, idx]), 8)
		b.disabled = not can
		_ra_list.add_child(r)
