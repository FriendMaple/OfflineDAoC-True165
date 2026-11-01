# "New old" UI direction

Decided while building the character screens (2026-10-09). "New old" means: **copy the original client UI 1:1, then
give it a modern readability pass**. Nothing is invented: the art, layout, wording and options come from the client.

## Keep from the old client
- **Layout:** the same screens and steps, in the same order, with each control in the same place (realm → select →
  create → customize; the in-game windows later on). When the client we have is newer than 1.65, follow 1.65: for
  example there is no starting-location screen.
- **Art:** the client's frames, stone bars, medallions, knobs, arrows, locks, emblems and 3D backdrops. Use the
  Real-ESRGAN x4plus copies (4x for small pieces, 2x for full-screen frames); palettes are copied exactly.
- **Text content:** the client's own text (realm descriptions, class texts, start towns, names). Only 1.65
  Classic + SI content is shown.
- **3D:** the client's realm scenes and camera framing, and the Catacombs figures with the client's options.

## The modern pass
- **ALL CAPS, bold** (Minion Pro Bold from the client's fonts); body text in Minion Pro Regular caps.
- **Bigger, readable text** with a dark drop shadow; gold for headings and selected items, cream for normal text,
  dim grey for secondary lines, soft red for errors.
- **Wide screens:** frames keep their side panels, only the middle stretches; nothing is cropped or squashed.
- **Clear states:** hover glow on every button, the selected option in bright gold, unavailable options greyed (not
  hidden).
- **Small conveniences** that don't change the game: captions under medallions, tooltips, mouse wheel zoom,
  double-click to play.
- **Removed:** steps the owner doesn't want (Adjust Attributes: stats fill in like the old client) and anything
  post-1.65 (later races and classes, private-server text such as the Atlas planner URL).

## Not allowed
- New art or substitute art, unless the owner OKs it (anything filled in is reported as mine).
- Modern UI clichés that change the look: flat buttons, rounded cards, icon fonts.
- Mixed-case text.
