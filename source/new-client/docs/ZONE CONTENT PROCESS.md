# Zone content process (owner 2026-10-09)

The repeatable process for putting a zone's people, shops, quests and drops into the MMOEngine. Lough Derg is the
first (LOUGH DERG LEDGER.md is the worked example); every zone afterwards goes through the same steps and gets its
own `<ZONE> LEDGER.md`. Improve this file whenever a zone teaches something new.

## Ground rules
1. **1.65 only.** Nothing added after patch 1.65 (UI, items, classes, races, quests, monsters).
2. **Authoritative base: the old OfflineDAoC project** (`new class test - CLAUDE VERSION`): its database and
   `runtime/server/classic-quests.json` hold the vetted classic quests, quest NPCs and monsters built from period
   data. Monster stats, levels, abilities, models: take them from there; never invent them.
3. **Fill its known gaps from period data only**: quest reward items + stats, missing / broken dialogue, bad quest
   scripts, drops.
4. **No ROG drops.** Every monster: real drop table. Period source first, Uthgard 2.0 (measured rates) as fallback.
5. **Period ranking** (always record which one was used, per item / line):
   a. Wayback copy captured before Trials of Atlantis (2003-10-28)
   b. Wayback copy captured before Catacombs (2004-12-07) - tag "pre-Catacombs"
   c. Uthgard 2.0 (a 1.65 recreation with measured drop rates) - for drops
   d. Live Allakhazam page (has "Last Updated" dates; later edits possible) - tag "live", only when a-c have nothing
6. **The client is the truth for art and names it holds**: models, icons, zone data, text tables. Period data never
   overrides what the client ships.
7. **Read-only**: the old database, the old client and the period-data archive are never modified.
8. Anything filled with a placeholder or a judgement call goes in the zone ledger for the owner's review.

## NPC types: what 1.65 had (owner 2026-10-09; verify each against period sources when a zone has them)
- IN: border / relic keep Portal Masters and their portal ceremonies (launch 2001); Shrouded Isles Channelers that
  port from the capital cities to the SI towns (Caer Gothwaite, Aegirhamn, Grove of Domnann; patch 1.60);
  battlegrounds via the border keep's medallion merchant + portal: patch 1.48 notes (Mar 2002, Warcry archive):
  "The medallion merchant's speech has been updated to reflect the changes within the Battlegrounds. Should you have
  questions on the function of the portals or which battleground your level/realm rank can travel to, please seek
  him out." (Thidranki 20-24, Murdaigean 25-29, Caledonia 30-35 then; the 1.66 date is for the later frontier
  portal medallions, not the battleground ones.)
- OUT (remove in EVERY zone, cities and housing areas included): town teleporters like the Mag Mell "Channeler"
  (old DB class LiveTeleporter), hasteners (GameHastener; owner: added ~1.70, recheck later), housing teleporters
  (1.68), and anything else the old server added after 1.65. pipeline/build_npcs.py NOT_165 holds the class list.
- Fast checks: pipeline/period_index.py (full-text index of the whole period archive + the old DB's NPC / monster /
  item / drop / quest data) - seconds per lookup instead of re-reading the archives.

## Steps per zone
1. **Bounds**: `zones.dat` [zoneNNN] region + region_offset_x/y + width/height (x 8192) -> global X/Y box.
   (The DB Zones table offsets can differ - use zones.dat.)
2. **People**: old DB `Mob` rows in that region inside the box. Split realm NPCs (merchants, trainers, healers,
   guards, quest givers) from monsters (realm 0). Record counts per kind and level ranges.
3. **Quests**: `DataQuest` rows with ID >= 20000 whose StartName NPC stands INSIDE the box (count by the giver's
   position - a text search over-counts; 136 vs the real 29 in Lough Derg). Note per-class variant rows. Split by
   the level cap in force.
4. **Quest gaps**: per quest, check accept / step / advance / target / finish texts and classic-quests.json Chat;
   per reward template, check ItemTemplate exists and has stats.
5. **Reward stats**: search period sources by item name - `archive/wayback-allakhazam/items_direct.jsonl.gz`,
   `quests/reward_items.jsonl`, `archive/allakhazam-live/item.jsonl.gz` (HTML; also search for pages citing the
   quest - the walkthrough's reward name can differ from the template name, e.g. Wind Bracelet = "Wind Formed
   Bracelet").
6. **Dialogue**: `quests/dialogue.json` + `walkthroughs.jsonl` (recorded NPC speech, keyword chains);
   placeholders only where none exists.
7. **Merchants**: old DB `MerchantItem` lists; flag entries pointing to missing templates; period vendor lists are a
   known gap - keep the server's lists, mark unverified.
8. **Drops**: Uthgard `monster.php` pages ("Statistics for "<name>" found in <zone>", gear / craft / generic items
   with drop rates) from `archive/uthgard/raw_pages.repaired.jsonl.gz` (read with `read_archive.records`, it skips
   damaged parts). Kinds with no page: period Allakhazam mob pages, else listed as a gap.
9. **NPC looks: equipment ALWAYS on** (owner 2026-10-09, after Greagoir showed up in plain clothes): every NPC wears
   its old-DB `NPCEquipment` list (Mob.EquipmentTemplateID -> rows of Slot / Model / Color / Effect / Extension;
   exported by build_npcs.py into npcs.json "equipment"). Armour models are objects.csv rows whose Catacombs columns
   name the fig3 armour parts. Weapons / shields come from build_weapons.py (attach bones: Bip01 R Hand, L Shield,
   L Belt / R Belt, L Back / R Back). An NPC in default clothes when the DB gives it armour is a bug.
10. **Templates first** (2026-10-09 lesson: Lough Derg showed stale levels): apply NpcTemplate the old server's way
   (build_npcs.py: ReplaceMobValues -> level list / model + size lists / aggro / flags / speed; TetherRange always).
   Never trust Mob.Level when the spawn has a template.
10. **Combat data**: build_npcs.py exports stats (STR / CON / DEX / QUI), MeleeDamageType, RespawnInterval,
   AggroLevel / AggroRange; build_monsters.py exports death + canims.csv combat clips for every monster model;
   build_rules.py holds the rule numbers (XP tables, class HP / weapon-skill bases, miss / damage constants).
11. **Build** (pipeline scripts, outputs under godot/content): NPCs + monsters, merchant stock, quest data with
   markers, drop tables, reward items, dialogue.
12. **Test in game** at the levels that zone allows; every quest end to end; shops buy / sell; drops roll.
13. **Ledger**: write `<ZONE> LEDGER.md` (sources used, gaps, placeholders, judgement calls) and update this file.

## Doors
Client zone NIFs carry their doors: a `doorNNN` node per doorway with leaf nodes (`door L01`, `door R01`) that hold
an open animation (NiKeyframeController, rotation keys 0 -> 1 s), a visible panel (`visibleNN`) and a collision
shape (`collideeNN`). Clicking a door opens it (the client), the server says which doors exist / are locked (old DB
Door table, InternalID = zone*1000000 + fixture*100 + door). The zone converter must keep each leaf as its own node
(pivot, panel, collision, closed / open rotation) - never bake doors into the static mesh.
**Lough Derg lesson (owner 2026-10-09): the first import baked the Mag Mell doors shut and dropped their collision -
every zone must come out with working doors; check a door in each town when a zone is built.**
Doors close again 5 s after opening (old server GameDoor STAYS_OPEN_DURATION 5000).

## Lessons so far
- Text matches over-count quests (136 -> 29): always use the giver's coordinates.
- Most surviving Allakhazam quest copies are from Oct 2004; the page's "Last Updated" date and comment dates help
  tell period content from later edits.
- Uthgard pages: drops are per zone and per-realm-wide; prefer the per-zone table.
