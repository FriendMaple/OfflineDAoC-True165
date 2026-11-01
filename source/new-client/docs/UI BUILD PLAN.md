# In-game UI build plan ("new old", 1.65 era)

Owner request (2026-10-09). **Pure 1.65 era**; the only exceptions are the owner's custom systems such as gamebots and companion bots (no mythical slot, no frontier-necklace teleport). **Don't build the gamebot / companion-bot features or UI yet: the owner has plans for those.**

Owner request details:
- Wire up the entire in-game UI, accurate to the 1.65 era client, in the new-old style.
- Include every setting: resolution, keybindings, quickbars and so on, plus the settings that only the original client's loading / character-select screens had.
- Leave out settings that don't apply (spell-icon options: we use the 0.35 OfflineDAoC icons).
- 3 quickbars (the owner changed their mind: only the 3 the old client has, no 4th).
- Pet window, group window, mini group and everything else the 1.65 client could show (confirmed or very likely).
- Inventory / equipment fully working: drag an item onto the paper doll or a slot to equip, swap, unequip, move between bags.
- Server and bot settings go on the character-select screen, not in the game UI.
- The exceptions to "1.65 only" are the owner's own features: the Quest Guide and the classic-frontier war map. They are the owner's 0.35 additions and get ported later with those systems.

## HARD RULE (owner 2026-10-09): nothing added after 1.65

- **No UI element, keybinding, inventory slot, option or window that was added after 1.65.** The current client files are a later version, so check each one.
- Already out: the MYTHICAL paper-doll slot (1.97); the 'Down' / dive binding and any underwater movement (Trials of Atlantis, 1.70).
- **You cannot go below the water surface at all**: surface swimming only (player.gd holds the surface).
- Bindings still to verify as 1.65 (keep until checked; remove if later): Nearest Loot, Map Window (in-game zone map), Perf. Meter, Camera Toggle, Use Item 2nd, Information/Delve, Toggle Interface, Quest Journal key, Realm War Map key, Sprint, Stick, Face. The later client also has Master Level, Champion level, Minotaur relic, Mount, Bazaar / Housing market, Title, Casual group finder, LFG, Subclass, Community windows: all post-1.65, never built.

## Which art is 1.65

- 1.65 (Oct 2003) used the original built-in interface: bitmaps in `app/data/`.
  - Right-hand stone panel (`right.bmp`) with 7 tab icons;
  - sheets: `charsheet` / `skillsheet` / `Magicsheet` / `combstylesheet` / `group` / `pperdoll`;
  - `options`, `command`, `merchant`, `interact`, `trade`, `vault`, `training`, `dialog` windows;
  - `buttons*.bmp` button sheets, `compass_bar`, `leftbot` / `rightbot` corner panels with the HP / END / POW bars;
  - `expjwl` experience jewel, chat borders, `minipet`, `group`, `grouppicker`, `namelist`, `timedisp`, `LagMeter`.
- The XML skins in `app/ui/` (atlantis, isles) are later (Atlantis skin: patch 1.89, 2007). They are NOT the 1.65 look, but are a reference for later windows if needed.
- Post-1.65 details in those bitmaps are dropped: e.g. the MYTHICAL paper-doll slot (1.97). (The owner asked about the frontier-teleport necklace in the mythical slot: that is the OpenDAoC server's mechanic. In 1.65 the frontiers were teleporter-only zones from each realm's portal keep; portal medallions came in 1.66.)

## Keybinding actions (from game.dll, 0x5531d4 / 0x538c20)

- Categories: Movement, Combat, Targeting, Interaction, Camera, Chat, Show, Misc.
- Presets: "rpgdefault" and "fpsdefault".
- Actions include:
  - Move Forward / Backward, Turn Left / Right, Strafe Left / Right / Toggle, Jump, Walk, Run Lock, Sprint, Sit/Stand;
  - Attack Mode, Face, Stick, Follow;
  - Nearest Enemy / Friend / Object / Loot, Target Group #1-8, Last Attacker, Consider, Ground Target;
  - Select/Open, Get Item, Use Item, Destroy Item, Craft;
  - Camera Reset / Pan / Toggle, Look Up / Down, Mouse Look (Toggle);
  - Chat, Reply, Chat Page Up / Down, Chat Logging;
  - Show Inventory / Stats / Skills / Spells / Combat / Group, Map, Realm War Map, Quest Journal, Command Window, Compass;
  - Toggle Interface, Toggle Names, Torch, Take Screenshot, Information/Delve, Perf. Meter;
  - Right Hand / Two Handed / Ranged Weapon;
  - quickbar slots (/qbind bank, slot, bar).

## Build order

1. **Art:** `pipeline/build_ui_classic.py`. All classic UI bitmaps → `content/ui/classic/{original,x4plus}` (4x, the UI is small), colour-keyed transparency, plus layout metadata (tab icon cells, button cells).
2. **Input** (owner: must support modern bindings, e.g. Mouse 4 / Mouse 5 on gaming mice, the wheel and modifier combinations): `Keybinds` autoload. The client's action list and defaults go into the Godot InputMap, are saved in user://settings.cfg, and the rebinding window uses them. The player and zone viewer move from hard-coded keys to actions.
3. **Window framework:** a draggable classic-frame window with close button and saved position, the UI scale, and the ALL CAPS bold theme.
4. **HUD:**
   - compass bar;
   - own HP / END / POW + experience jewel;
   - target window;
   - chat window (tabs, scroll);
   - quickbars 1-3 (no 4th), 10 slots × 10 banks;
   - minimized group, pet window, concentration, effect icons.
5. **Right panel windows:**
   - character sheet;
   - skills (specializations + abilities);
   - magic;
   - combat styles;
   - group;
   - inventory / paper doll;
   - options (all settings incl. the pregame ones);
   - keybindings;
   - command window.
6. **Items:**
   - item data (1.65-era templates exported read-only from the old server DB);
   - icons (0.35 OfflineDAoC icon set);
   - an inventory model (equipment slots of 1.65, backpack, wallet);
   - drag & drop equip / swap / unequip;
   - the figure's appearance updates from worn armour (Catacombs "Cata <name>" sets).
7. Merchant / trade / vault / training / interact windows come with the NPC systems.

## Progress 2026-10-09 (first full pass, renders on the Acer)
Written in godot/game/ui: ui_art, classic_window (drag by the corner handle / top band, positions saved per screen
shape in settings.cfg [ui_layout_<w>x<h>], like the client's [Panels-800x600]), keybinds (autoload), player_data
(autoload: inventory, stats, quickbars, money, saved with the character), item_db, game_ui, quickbar, chat_window,
options_window, inventory_sheet, character_sheet, panel_sheets. Mounted in zone_viewer (replaces the temporary
GameMenu; Esc = close top window / options). The whole UI scales with the window height (800x600 layout units).
Test: `--skip-login --zone=200 "--at=Mag Mell" --ui-test --ui-shots=<folder>` (sample Celt Guardian, never saved)
and headless `godot res://tests/ui_smoke.tscn`. Without --skip-login a test run sits on the login screen.

Owner rulings this pass:
- New characters start with ONLY their weapon (no starter armour/shield; that was a free-shard addition).
  pipeline/build_items.py keeps the class's weapon rows of StarterEquipment as 'starter'.
- Bonus stats are given automatically (no allocation screen): race base + the class's default 30-point spread,
  read out of game.dll (pipeline/client_re/race_stats.py -> content/characters/stats.json). Matches the owner's
  three Optimize screenshots exactly.
- Base class -> advanced class at a trainer at level 5; at level 5 experience stops until the advanced class is
  picked (the old client). Advanced classes come with trainers in the world plan.

Icons: item icon numbers map to the client's sheets 100-199 ITM_1200, 200-299 WPN_900, 500-599 ITM_1300,
2200-2299 ITM_1400 (others are later series). Quickbar / spell icons use the global numbering (sheet per hundred).

Still open:
- Skills / magic / combat lists (spec, spell line, style data per class) and the group / mini group / pet windows'
  live data (need the character systems); command window.
- Equipping doesn't change the figure's look yet (Catacombs armour meshes not exported).
- Status panel: bar order health / power / endurance and the lower rows (target?) to check against a 1.65 shot.
- Buttons use a plain stone-and-gold box, not yet the client's buttons.bmp pieces.
- The to-verify bindings list above.

## 1.65 window audit (2026-10-09)
Sources: the client's default.ini [Panels-800x600] window list (a later client: also lists post-1.65 windows),
the classic buttons.bmp captions, camelotherald / gamebanshee patch notes.
Not 1.65 (left out): realm war map (New Frontiers, test 1.70 2004; /rw), zone map /map (test 1.71d, Aug 2004),
floating target / focus target, titles, mounts, master / champion levels, group buffs window, menu bar.
The owner's own classic-frontier war map (0.35 custom) is a later port, owner's call.

| Window (default.ini) | 1.65 | State |
|---|---|---|
| Stats = right panel, 6 tabs | yes | done (inventory on the old grey-stone skin, owner) |
| status (rightbot): you, experience, target | yes | done; target rows wait for targeting |
| Quickbar 1-3 (turn vertical / horizontal) | yes | done |
| ChatWindow0 Main, ChatWindow1 Combat | yes | done, resizable |
| Compass, TimeDisplay | yes | done (time = the game clock) |
| MiniGroup | yes | window done, waits for groups |
| MiniPet (pet commands) | yes | done, opens on summon; waits for pets |
| OptionsDialog + KeyConfig | yes | done (VIDEO / AUDIO / CONTROLS / INTERFACE / WINDOWS) |
| MiniConc (concentration list, CONC) | yes | TODO with spells |
| SpellEffect (effect icons) | yes | TODO with spells |
| CommandWindow (command.bmp) | yes | TODO - contents to confirm |
| MiniFriends (FRIENDS) | yes | TODO |
| Help (HELP) | yes | TODO |
| QuestLog (JOURNAL) | yes | TODO with quests |
| Merchant (BUY / SELL / APPRAISE), Train, Bank (vault), NpcTalk, Dialog | yes | TODO with NPCs |
| TradeWindow (TRADE / ACCEPT / DECLINE) | yes | TODO |
| Group sheet buttons JOIN / INVITE / DISBAND, LFG (LOOKING / FIND) | yes | TODO with groups |
| Siege (ARM / AIM / LOAD / FIRE) | yes | TODO with keeps |
| release / death dialog with the auto-release countdown (added in 1.65) | yes | TODO with combat |
| MiniInfo / InfoPage (delve) | yes | TODO |
| TradeSkillWindow / MiniCraft (crafting) | yes | TODO with crafting |
| LagMeter | yes | optional (offline) |
| Housing, Bazaar, PlayerMerchant (housing 1.62+) | yes | owner's call |

## Godot sizing trap (2026-10-09, caused several owner-reported bugs)
A text Control (Label / Button / LineEdit / OptionButton) built OUTSIDE the scene tree measures itself with Godot's
default 16 px font, and any size set then is clamped up to that and never shrinks back once its real font applies.
Symptoms seen: buttons 159x31 instead of 114x20 (captions off-centre / cut by the next button), the status name
box 23 tall (name sat below its bar), the chat input 31 tall (hung under the window).
Fix: UiArt.themed(c) (= c.notification(NOTIFICATION_THEME_CHANGED)) after the theme overrides and before sizing -
UiArt.label / UiArt.button do it; anything else built by hand must call it. Or add to the tree first, then size
(pregame _at does that now).
Also: chatext.bmp is TWO stacked 512x64 chat panels - the frame uses one (Rect2(0,0,512,64), nine-patch).
Item hover = name only (client tooltips are captions); details = information window (InfoPage = interact.bmp),
shift-click.

## Quickbar keys + chat boxes (2026-10-09)
- Quickbar hover text is the client's (game.dll 0x4d7e4f): "Quickbar N" + "Modifier - None / Alt / Ctrl"; bar 1 = no
  modifier, bar 2 = Alt, bar 3 = Ctrl (keyboard.dat AltModifier / CtrlModifier). Defaults: qb1 1-0, qb2 Alt+1-0,
  qb3 Ctrl+1-0, Shift+1-0 = quickbar 1's bank (patch 1.54: "/qbar 2 ... the same as pressing Shift-2"); /qbar works.
  The hover text follows the bar's actual binding. keybinds.cfg version 2 fills the new defaults once.
- Arrow tooltips: PREVIOUS BAR / NEXT BAR (owner; the client has no hover text for them - its messages say "bank").
- Chat: TWO separate boxes (owner: like the newer client's ChatWindow0 Main / ChatWindow1 Combat), combat box on top,
  chat box (typing line) below at the bottom left; each moves / resizes on its own; Options > CHAT picks each box's
  message types. The client's 65 per-channel switch names are in its text tables (not decoded) - our type names.
  1.65 evidence: chatext.bmp = two stacked framed boxes; keybinds PageUp/PageDown + PageUpSys/PageDownSys; 1.65 notes
  "Resists Changed channel in the system window".

## Saving (2026-10-09, owner bug "UI not saving after quit")
- Window layout, settings and keybindings are game-wide (user://settings.cfg, user://keybinds.cfg); quickbar contents
  and the selected bank are per character (bank persists: patch 1.54). Options > CONTROLS "CHARACTER-SPECIFIC KEY
  BINDINGS" (off by default, WoW-style) gives a character its own user://keybinds/<account>_<name>.cfg.
- Bug: OptionsWindow kept the settings file it loaded at build and wrote that old copy back on every change, erasing
  window positions saved since. Now it re-reads before every save. RULE: every writer loads fresh, sets, saves.
- Windows also save to a game-wide [ui_layout] fallback used when the current window shape has no layout yet.
- Display: BootSettings autoload applies window mode / resolution / frame cap at launch (not on entering the world).
  "borderless" = a borderless WINDOW at the chosen resolution, centred (owner's 1920x1080 borderless windowed);
  "fullscreen" = exclusive full screen. Test runs (--ui-test etc.) skip it and use user://settings_uitest.cfg.
- Check: godot res://tests/persist_probe.tscn (headless).

## Items, death, realm select (2026-10-09)
- Hover on a weapon or armour piece: game/ui/item_tooltip.gd. It shows the client's mini delve (owner's screenshots) with the name in the item's con colour.
- Right-click: the classic information window (interact.bmp nine-patch, half width, fitted to its text) with the same lines. Shift+I: the full delve. No weapon speed in the 1.65 full delve (added 2004).
- Death window: one RELEASE button. City / house release came after 1.65 (owner confirmed).
- Realm select fills the screen. realm_selection_wide = the frame stretched to 16:9 before the x4plus pass. The hover cells of the Hibernia / Midgard emblems are trimmed 1 px (stray white strip).
- Overhead names: Label3D, depth-tested (walls clip them like the client), Minion Pro Bold, set size (LOUGH DERG LEDGER.md).
- Esc / ground click untarget. The zone music waits until loading is done.
