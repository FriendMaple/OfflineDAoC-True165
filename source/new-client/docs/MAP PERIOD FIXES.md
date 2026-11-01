# Map period fixes (2026-10-09)

The map window uses the old client's own painted maps (`ui/maps`: `z###.dds` zone maps, `z###_NN.dds` town / dungeon-level maps, `r###.dds` realm maps, `regions.dat`, `areas.dat`). That client is much newer than 1.65, so its maps show things 1.65 didn't have. `pipeline/map_edits.py` paints them out of the 256-px client pictures before the 4x upscale. The untouched pictures are kept in `godot/content/maps/client/`, and the per-picture list of removals is in `godot/content/maps/period_fixes.json`.

## Removed

| What | Where | Why (source) |
|---|---|---|
| **Boat taxis and their light-blue routes** (12 boat icons) | Lough Derg, Silvermine Mts., Camelot Hills, East Svealand, Gotar | No sailing in 1.65; the owner places boats at Trials of Atlantis. The boat sprite was found by template match: it appears on these 5 maps and nowhere else. |
| **Catacombs instanced dungeon extensions**: red names, red entrance ticks and red leader lines | Stonehenge Barrows (+ Upper), Tomb of Mithra, Keltoi Fogou, Catacombs of Cardova, Tepok's Mine, Spindelhalla (+ both levels), Vendo Caverns, Varulvhamn, Cursed Tomb, Nisse's Lair, Coruscating Mine, Muire Tomb, Spraggon Den, Koalinth Caverns, Treibh Caillte | Warcry, 14 Jul 2004: Catacombs "adds new dungeon areas to each Realm, instanced content", in stores December 2004. Allakhazam lists every one of these as an "Instanced Dungeon" (list below). |
| **"Abandoned Mines" exits** (label + yellow tick) | the same 16 classic dungeons | Catacombs patch notes (Warcry, 30 Nov 2004): "Abandoned Mines… Tunnels leading to the entrances of the classic dungeons". |
| **"Catacombs" entrance labels** (+ tick) | City of Camelot, Jordheim, Tir na Nog | The capitals' Catacombs entrances are Catacombs content. |
| **City "region" pictures** r010 / r101 / r201 | dropdown | Unfinished raw renders in the client, not maps. |
| **Small dome icons with no dungeon behind them** (30) | Camelot Hills (4), Black Mtns. South (3), Black Mtns. North, Campacorentin (2), Avalon Marsh, Vale of Mularn (3), East Svealand (4), West Svealand, Gotar, Myrkwood, Lough Derg (3, incl. the two beside Mag Mell), Silvermine (2), Valley of Bri Leith, Connacht (3) | Each is far from every real entrance in its zone and from the realm's 1.65 dungeons; they're the client's later instanced dungeon entrances. Real dungeon icons stay, whatever their shape (Spraggon Den, Muire Tomb, Mithra, DF, Tuscaran Glacier...). |
| **Shrouded Isles portal labels moved** | Hy Brasil: Mag Mell -> beside Connla's tower (Shannon Estuary); Avalon: Cotswold -> Avalon Marsh; Aegir: Mularn -> Nalliten (Gotar) | The later client moved the portals. Period walkthrough: "the tower next to the portal to Hy Brasil" near Connla. Allakhazam: "Original SI portal has been moved to just outside Cotswold Village" / "...outside Mularn Village" (the NPCs are in Avalon Marsh / at Nalliten, Gotar). Our world's portal exits are at those places too. |

### The extension names (all listed by Allakhazam as Instanced Dungeons)

- **Albion:** Deliah's Sanctuary, The Lost Wing, The Hidden Crypt, The Hall of Reawakening, The Betrayer's Den, Ritual Hall, Lair of Doom, The Arena, Goblin's Cookery, The Beastmaster's Den.
- **Midgard:** The Master's Lair, Arachnid's Labyrinth, The Lost Burrow, Den of Bones, The Burrow, The Cursed Lair, Liche's Unrest, Lio's Eternal Rest, Tomte Prison, Nisse's Retreat.
- **Hibernia:** The Forgotten Vein, The Pit of Despair, Serf's Folly, The Steward's Crypt, Rise of the Spraggons, The Warrens, The Brawler's Den, Felena's Sorrow, The Ancient's Retreat, Shaman's Inner Sanctum.

## Kept, and why

- **Inishail Island, Modernagrav and Allta Fearann**, and their faction flights. They came with patch 1.65 (Allakhazam zone notes, Oct 2003: "not added untill the 1.65 patch… a free add on zone"). The white flight arcs on the SI maps stay.
- **The pink "Avalon / Albion / Aegir / Midgard / Hy Brasil / Hibernia" labels:** the Shrouded Isles links, which existed by 1.65.
- **Hall of the Corrupt / Darkness Falls / Summoner's Hall / Passage of Conflict:** their colours are realm areas and keys, not extensions.

## Known leftovers

A label that sat on top of corridors leaves a soft blur where it was. One faint fragment of the Tomte Prison leader line remains on Nisse's Lair.
