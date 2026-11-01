class_name SrvHornWindow
extends ClassicWindow
## True 1.65 Mode: the Horn of Rallying's window (owner 2026-10-30: "the HORN WINDOW built in both
## clients"), from the server's DebugMode 0x21 'H' ops 20 - 23 (CompanionNet.horn). The Horn Handler opens it once its
## level-50 quest is turned in. Each PvE event of your realm the horn can start: its name, the server's status line,
## its state - READY, UNDERWAY, a boss respawning or the event cooling down (with the time left), UNAVAILABLE - the
## bots assigned of the size it suggests, and SOUND (/horn sound <index>) while it is ready. The server answers a sound
## with one line (op 23) and a fresh list; the list is asked again every 10 s while the window is open (/horn list).

const SIZE := Vector2(470, 300)
const ROW_H := 30.0
const STATES := ["READY", "UNDERWAY", "RESPAWNING", "COOLDOWN", "UNAVAILABLE"]

var net: CompanionNet
var _title: Label
var _list: VBoxContainer
var _message: Label
var _poll := 0.0
var _times: Array = []                          # [Label, seconds at the list's time, state] - the countdowns


func build() -> void:
	closable = true
	_title = CompanionUi.frame(self, "horn", SIZE, Vector2(180, 70), "THE HORN OF RALLYING")
	CompanionUi.text(self, "SOUND THE HORN TO RALLY YOUR REALM'S BOTS TO AN EVENT.", Vector2(14, 20), Vector2(SIZE.x - 28, 12),
			8, CompanionUi.DIM)
	var box := CompanionUi.inset(self, Vector2(12, 36), Vector2(SIZE.x - 24, SIZE.y - 76))
	var sc := ScrollContainer.new()
	sc.position = Vector2(3, 3)
	sc.size = box.size - Vector2(6, 6)
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	box.add_child(sc)
	_list = VBoxContainer.new()
	_list.custom_minimum_size = Vector2(sc.size.x - 10, 0)
	_list.add_theme_constant_override("separation", 2)
	sc.add_child(_list)
	_message = CompanionUi.text(self, "", Vector2(14, SIZE.y - 36), Vector2(SIZE.x - 28 - 130, 24), 8, UiArt.CREAM, true)
	# REFRESH and CLOSE, as the original client's horn window has them (original client 2026-10-30)
	CompanionUi.button(self, "Refresh", Vector2(SIZE.x - 12 - 124, SIZE.y - 34), Vector2(60, 16), func():
		_poll = 0.0
		net.horn_command("list"), 8)
	CompanionUi.button(self, "Close", Vector2(SIZE.x - 12 - 60, SIZE.y - 34), Vector2(60, 16), hide_window, 8)
	net.horn_opened.connect(func():
		show_window()
		refresh())
	net.horn_closed.connect(func():
		if visible:
			super.hide_window())
	net.horn_changed.connect(refresh)


func hide_window() -> void:
	if visible and net:
		net.horn_command("close")
	super.hide_window()


func refresh() -> void:
	if not visible or net == null:
		return
	var t := String(net.horn.get("title", ""))
	_title.text = t.to_upper() if t != "" else "THE HORN OF RALLYING"
	_message.text = String(net.horn.get("message", ""))
	for c in _list.get_children():
		c.queue_free()
	_times.clear()
	var rows: Array = (net.horn.get("rows", []) as Array).filter(func(r): return r is Dictionary)
	if rows.is_empty():
		CompanionUi.text(_list, "NO EVENTS.", Vector2.ZERO, Vector2(300, 14), 8, CompanionUi.DIM)
		return
	for r in rows:
		_list.add_child(_row(r))
	_tick_times()


func _row(e: Dictionary) -> Control:
	var row := Control.new()
	row.custom_minimum_size = Vector2(_list.custom_minimum_size.x, ROW_H)
	var state := clampi(int(e.state), 0, 4)
	CompanionUi.text(row, String(e.name), Vector2(4, 2), Vector2(170, 12), 9, UiArt.GOLD_HI)
	CompanionUi.text(row, String(e.status), Vector2(4, 15), Vector2(250, 12), 8, UiArt.CREAM)
	var col: Color = [CompanionUi.GREEN, UiArt.GOLD, CompanionUi.RED, CompanionUi.RED, CompanionUi.DIM][state]
	var st := CompanionUi.text(row, STATES[state], Vector2(258, 2), Vector2(96, 12), 8, col)
	if state == 2 or state == 3:
		_times.append([st, int(e.seconds), state])
	if int(e.needed) > 0 or int(e.assigned) > 0:
		CompanionUi.text(row, "BOTS %d / %d" % [int(e.assigned), int(e.needed)], Vector2(258, 15), Vector2(96, 12), 8, UiArt.CREAM)
	var idx := int(e.index)
	var b := CompanionUi.button(row, "Sound", Vector2(_list.custom_minimum_size.x - 62, 7), Vector2(58, 16), func():
		net.horn_command("sound %d" % idx), 9)
	b.disabled = state != 0
	return row


## A respawning boss's / a cooling event's time left, counted down from the list's own time.
func _tick_times() -> void:
	var gone := (Time.get_ticks_msec() - int(net.horn.get("at", 0))) / 1000
	for t in _times:
		var left := maxi(0, int(t[1]) - gone)
		(t[0] as Label).text = "%s %d:%02d" % ["RESPAWNING" if int(t[2]) == 2 else "COOLDOWN", left / 60, left % 60] \
				if left < 3600 else "%s %dh %02dm" % ["RESPAWNING" if int(t[2]) == 2 else "COOLDOWN", left / 3600, (left % 3600) / 60]


func _process(delta: float) -> void:
	if not visible or net == null:
		return
	_tick_times()
	_poll += delta
	if _poll >= 10.0:                              # (the list again: states change as the bots muster)
		_poll = 0.0
		net.horn_command("list")
