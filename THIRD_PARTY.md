# Existing projects and notices

The server and navigation-builder source contain GPL version 3 license texts. Preserve these and all
per-file notices; dependencies may have other licenses. The project's AI-developed additions do not remove
upstream attribution.

- Dawn of Light / OpenDAoC: server emulator foundation. See the server source's LICENSE, gpl.txt,
  gplheader.txt and source headers.
- Navigation builder (OpenDAoC-BuildNav): see its LICENSE and the native pathing dependencies' notices.
- Quest Guide walkthroughs (classic-quest-guides.json): the Allakhazam (camelot.allakhazam.com) Dark Age of
  Camelot quest pages as they read in 2001-2004, most taken from the Internet Archive's Wayback Machine copies.
  They were written by Allakhazam and its contributors, who keep their rights; each guide names its source page
  and capture date.
- Period game data (monster placement and levels, loot, vendor stock, item stats): drawn from period player
  references: Allakhazam's 2001-2004 pages (through the Wayback Machine), CapnBry's DAoC radar sightings and
  the Uthgard bestiary and measured drop rates. Those sites and their contributors keep their rights. The raw
  downloaded pages are not included in this repository.
- Recipes, class and race tables and pre-game art: read from the patch 1.64 DAoC client's own data files.
- New client: Godot Engine 4.7.2 with GodotSharp (MIT; Copyright (c) 2014-present Godot Engine contributors,
  (c) 2007-2014 Juan Linietsky, Ariel Manzur). The engine and its bundled components' notices ship in the new
  client's tools/godot_net/LICENSE.txt.
- New client content pipeline: nif.xml from the NifTools project (github.com/niftools/nifxml, GPL-3.0), in the
  pipeline's spec folder. Real-ESRGAN (xinntao/Real-ESRGAN, BSD 3-Clause) was used to upscale the converted
  textures 4x; it is not included.
- The new client's converted zones, models, textures, sounds and interface art are derived from the original
  DAoC client's files, like the original client itself; they are not authored by this project.
- Bundled SDK, native and Python packages keep their own licenses and notices; including them is not a
  blanket relicense.
- Fixes ported from community forks of Offline DAoC are credited to their authors in the changelog.

The original DAoC client, art, sound, maps and other third-party assets are not represented as authored by
this project. Being noncommercial does not itself change third-party rights. The GPL server license is not a
license for those assets.
