# Period 1.64 / 1.65 pregame - plan (2026-10-31)

**2026-10-31: normal mode is discontinued (owner) - the game is True 1.65 Mode only, so this plan is for 1.65 only:
classic figures, base classes, the 1.65 server.**

Owner: "figure out what the period 1.65 realm selection, character select screen, creation screen, play buttons, etc.
actually looked like and plan to replace the current ones with true 1.65 era versions".

Sources: the real 1.64 client (`DAOC HIATUS\1.64 real client\DAoC 1.64.zip`, retail CD 2003-08): `charman\*.tga`,
`data\login.mpk`, `data\title.tga` / `camback.tga`, `charman\summary.mpk` (summary.txt), `charman\names.dat`, and its
`DAoC Manual.pdf` (Character: Select & Create, pages 8-18). Picture sheet: `PERIOD PREGAME 1.64 SCREENS.png`.
Exact control positions: asked of the retired old-client chat (1.64 game.dll / login.dll) - to fill in below.

## What the period pregame was

All 2D, 800 x 600 painted screens with a Celtic font. Buttons are pictures with four states side by side or
stacked: grey (normal), gold (hover), white, red (pressed).

1. **Login** - `login.bmp`: the DAoC logo with Account / Password / Quick Entry ("select an existing character to
   load the game directly, or No Thank You"), over the stone chamber (`smcamback`) with the animated flames. The
   current login already uses smcamback + flames; only its panel differs.
2. **Server select** - `server_selection.bmp`: "Choose a Server and Hit Play", the server list and "News / Patch
   Messages". (One server here: could show it with the CHANGELOG / news, or be skipped.)
3. **Choose Your Realm** - `chooserealm.tga`: the Celtic triple knot on a night sky, red dragon in the middle, the
   tree (Hibernia), hammer (Midgard) and chalice (Albion) in its three loops (`chooserealm_but`, 4 states each, the
   selected one ringed in its realm colour). Its help text is painted at the bottom.
4. **Character select (Main)** - `Main.tga`: standing stones on a cliff under a full moon. PLAY and OPTIONS in the
   middle, QUIT bottom left, Delete Character bottom right (CREDITS exists too). A button per character slot ("Create
   New Character" on an empty one); the selected character stands on the stones. The manual says 8 characters per
   realm (an older paragraph says 4).
5. **Creation** - `chargen.tga`, ONE page: Enter Name + Generate; Select Race (5 per realm, SI races too); Select Class
   (the base classes / Hibernia's "Way of ..." - unavailable ones dark); Select Sex; Hair Color - / +; Select Face
   - / +; Height Short / Average / Tall; Points Left and the 8 attributes with - / + (class stats in yellow); a
   full-body figure in the middle with a rotating close-up of its face above; a help box at the lower right that
   describes whatever the mouse is over. Cancel / Proceed.
6. **Summary** - `chargen_Summ.tga`: the race + class description (summary.txt, e.g. "[BRIT-FIGH] Briton Fighter ...
   At fifth level, you must choose ...") with Cancel / Back / Proceed. With Shrouded Isles a Starting Location choice
   (original lands or the isles) could follow; Proceed saves and returns to the select screen.
7. **Delete** - type YES to confirm; **Options** - mouse / keyboard / resolution / performance / interface / sound.

## What the new client has now

The later client's screens: the 3D realm panels, a 3D character-select scene per realm with 10 slots on a right
panel and medallion buttons (PLAY/CREATE swords, REALM shield, DELETE skull, CUSTOMIZE figure, OPTIONS dragon, QUIT),
create (race / gender / class), then a Catacombs customize page (face sliders, eye / skin / hair colours, size,
tattoos). In True 1.65 Mode the select screen already uses the 1.64 standing stones (Main.tga) with the figure on the
ledge, the 1.64 loading pictures and the base classes.

## The plan

**P1 - art pipeline** (`pipeline/build_pregame_164.py`): pull charman / login.mpk / title / camback from the 1.64 zip,
cut the button sheets into their states (charbut: 4 columns x 51 rows, names listed), x4 upscale the 800x600 screens,
fit widescreen without black bars (extend the painted sky sideways - the owner hates bars).

**P2 - login**: the period `login.bmp` panel (Account / Password / Quick Entry with a character pick list) over the
stone chamber and flames. Server select: show it with the one server and the news (or skip - owner).

**P3 - Choose Your Realm**: chooserealm.tga with the three emblem buttons (4 states), click = that realm.

**P4 - character select**: Main.tga for every realm; PLAY / OPTIONS / QUIT / Delete Character (/ CREDITS) as the
period pictures; the slot buttons as the period's; the selected character (classic figure) in 3D standing on the stones
(the 1.65 version of this exists - build on it); PLAY greyed with no character.

**P5 - creation (one page)**: chargen.tga with the charbut buttons: name + Generate (names.dat), race, base class
(Hibernia's "Way of ..."), sex, hair colour -/+, face -/+ (the classic looks), height Short / Average / Tall, Points Left +
8 attributes -/+ (yellow class stats, the server's create packet carries the stats), full figure + rotating face
close-up, the mouse-over help box. Proceed -> summary page (summary.txt) with Cancel / Back / Proceed (-> start
location if the isles are offered) -> back to select.

**P6 - small screens**: delete (type YES), pregame options (our options window, period look), credits (login.mpk
page01-15).

**P7 - server side** (ask the server chat): create packet stats / height / slot count, Quick Entry, starting
locations.

## Owner answers (2026-10-31)

- Modes: True 1.65 Mode only (normal mode discontinued); base classes only.
- Looks: period choices only - face (the classic look), hair colour, height. The Catacombs customize page goes.
- Attributes: spend points at creation (Points Left + 8 stats). The server already enforces it
  (CharacterStatValidator: 30 points over the race's STARTING_STATS_DICT, costs 1 / 2 / 3 above +10 / +15) - the client
  mirrors those rules exactly.
- Slots: 8 per realm (told the server chat: refuse slots 9-10).
- No server select screen, no credits pages.
- Server facts (server chat 2026-10-31): height = bits 11-12 of the create packet's CreationModel (model = (size << 11)
  | modelId; 1 Short, 2 Average, 3 Tall; 0 refused). Stats: the same CharacterStatValidator / STARTING_STATS_DICT in
  1.65. Slots: the create packet's slot byte is per account (realm r = (r-1)*10 .. +9); the 8-slot limit waits on the
  owner's direct OK to the server chat (plan: refuse new characters in a realm's slots 9-10, keep existing ones).
  Catacombs customize fields: send defaults. The launcher always passes --world-mode=1.65 now.
- Exact layout (retired old-client chat, read from the 1.64 game.dll / login.dll 2026-10-31): `DAOC HIATUS.65 MODE
  CLIENT (local only)\workt\pregame-layout.64 PREGAME LAYOUT.txt` (+ annotated art). Every rect, sheet state
  rect (order normal / over / pressed / disabled), the 8 slots (x 9, w 345, h 60, y 30 + 60i), the figure viewports
  (select: x 464..800 y 70..600; creation: body 216..584 / 69..600, head 488..584 / 24..150), the stat rows, the help
  box, the confirm dialog and the login dialogs.
