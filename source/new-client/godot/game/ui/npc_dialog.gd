class_name NpcDialog
extends ClassicWindow
## The NPC interaction window (npctalk.bmp, 384x320): what an NPC says to you, with its [keywords] clickable - the
## client's way of answering an NPC (clicking a bracketed word whispers it back). Trainers, quest givers and other
## talking NPCs use it; the words go to the zone viewer through `keyword`.

signal keyword(npc_id: String, word: String)

var npc_id := ""
var _title: Label
var _body: RichTextLabel


func build() -> void:
	closable = true
	_title = UiArt.label("", 11, UiArt.GOLD_HI)
	_title.position = Vector2(12, 20)
	_title.size = Vector2(350, 16)
	add_child(_title)
	_body = RichTextLabel.new()
	_body.position = Vector2(12, 40)
	_body.size = Vector2(352, 245)
	_body.bbcode_enabled = true
	_body.meta_underlined = false                      # (the keywords in brackets, not underlined: the original client)
	_body.scroll_following = false
	_body.add_theme_font_override("normal_font", UiArt.font(false))
	_body.add_theme_font_size_override("normal_font_size", 10)
	_body.add_theme_font_override("bold_font", UiArt.font(true))       # the keywords: bold, in brackets (owner 2026-11-05)
	_body.add_theme_font_size_override("bold_font_size", 10)
	_body.add_theme_color_override("default_color", UiArt.CREAM)
	_body.meta_clicked.connect(func(m): keyword.emit(npc_id, String(_links.get(String(m), String(m)))))
	UiArt.themed(_body)
	add_child(_body)


## Show an NPC's words. "[word]" becomes a gold link.
## Several things one NPC says at one moment stack (a trainer's greeting and the quests it offers you) instead of the
## last one replacing the rest (owner 2026-10-09: Magus Oreal's quest offer vanished under his training line).
var _frame := -1
var _links := {}                                   # link id ("k3") -> the keyword's words


## Text shown as it is: a stray "[" outside a keyword would start a BBCode tag.
static func _escape(t: String) -> String:
	return t.replace("[", "[lb]")


func say(id: String, npc_name: String, text: String) -> void:
	var stack := Engine.get_process_frames() == _frame and id == npc_id and visible
	_frame = Engine.get_process_frames()
	npc_id = id
	_title.text = npc_name.to_upper()
	# each [keyword] links by a short id, its words kept in _links (reset day S9: Kaere's long "[Will you gather the
	# components for Keare's spell to protect Anniogel?]" did not show - a long value with spaces and an apostrophe
	# inside the [url=...] tag broke it). Shown in its brackets and not underlined, as the original client (owner
	# 2026-11-05: "they should be in brackets like old client does").
	if not stack:
		_links.clear()
	var re := RegEx.create_from_string("\\[([^\\]]+)\\]")
	var src := text.replace("\n", "\n\n")
	var bb := ""
	var at := 0
	for m in re.search_all(src):
		var k := "k%d" % _links.size()
		_links[k] = m.get_string(1)
		bb += _escape(src.substr(at, m.get_start() - at))
		bb += "[url=%s][color=#f0c060][b][lb]%s[rb][/b][/color][/url]" % [k, _escape(m.get_string(1))]
		at = m.get_end()
	bb += _escape(src.substr(at))
	_body.text = (_body.text + "\n\n" + bb) if stack else bb
	show_window()
