# Changelog

The newest version is first.

Offline DAoC True 1.65 grew out of [Offline DAoC](https://github.com/shadowofze/OfflineDAoC) (0.3 to 0.37c, now on
hold). Its changelog has the history of everything this version inherits.

## 0.1 (not released yet)

The first version of True 1.65: Classic and Shrouded Isles as they were at patch 1.65 (1 November 2003). The only
additions to the period game are the bot and companion systems and the Realm Exchange. It is early in development:
most of the systems below have been tested in autonomous bot runs, but not yet by players.

### Compared with Offline DAoC

- **One mode:** True 1.65 only. The launcher has no normal mode and refuses a world that isn't a True 1.65 one.
- **One client:** the new client. The original DAoC client is not supported, and there is no DXVK.
- **A fresh start:** nothing transfers from Offline DAoC, and there is no progress importer.
- **No Sluaghbinder:** the custom class is gone.

### The world, as in 1.65

- **Freeshard and post-1.65 content removed.** Removed rows are archived in the world database, not just deleted.
  Removed:
  - click teleporters;
  - town and frontier hasteners (they came in 1.70 and New Frontiers);
  - Atlas master trainers, item merchants, the buff merchant, the Market Explorer, account vault keepers and
    training dummies;
  - Atlas event controllers, "new mob" placeholders and helper NPCs;
  - the random "ROG" item drops.
- **Regions off:** the tutorial, Cathal Valley, the duplicate Summoner's Hall, the New Frontiers battlegrounds,
  Passage of Conflict and every Trials of Atlantis region.
- **Period drops:**
  - rebuilt from Uthgard's measured drops, period Allakhazam loot lists and period item pages, for about 1,950
    monsters;
  - 886 freeshard and dead loot rows removed: Atlas XP items, orbs, trophies, timed drops and items no source knows;
  - 1,334 period items built from their period pages;
  - the 8 period boss trophies stay (they came with housing in June 2003).
- **Coin as in 1.65:** a monster carries coin or it doesn't. The chance comes from Uthgard's measured kills, and the
  amounts are unchanged.
- **Item stats:** about 7,200 corrected to the period item pages. Invented quest rewards were replaced by the real
  items.
- **Spawns:** 16,292 period spawns restored and 453 period spawns added. Spawns off the walkable ground were moved
  onto it. Levels and factions were corrected where two sources agree.
- **Merchants:** period stock from the period Allakhazam item and merchant pages (1,458 stock rows, 8 new lists), and
  7 missing period merchants added where CapnBry's radar saw them.
- **Crafting:**
  - the recipe list is the 1.64 client's (about 380 later recipes removed);
  - skills are per character;
  - no speed bonuses; quality is 94-99%; hand tools are needed; salvage gives the full yield;
  - frontier siege equipment is crafted (Siegecraft), not sold.
- **Travel:**
  - the Shrouded Isles entrances are the 1.64 client's jump boxes (Avalon Marsh, Gotar/Nalliten, Shannon Estuary);
  - the Darkness Falls entrances are the period ones;
  - frontier portal masters walk between their post and the pad;
  - horse routes follow bridge decks and dips;
  - there is no personal bind recall stone.

### Rules for players

- XP is 1x, with no free levels and no `/level`.
- Coin belongs to each character, not to the account. Each realm has 8 character slots.
- Base classes at creation; you choose your class at a trainer at level 5. A starting class and race with no class to
  promote to is refused.
- New characters start with a weapon and a training shield.
- No autoloot. Songs need their own instrument (drum, lute or flute).
- Charm is cast on a real target, with the original Dawn of Light level limit and resist rules. A freed charmed
  monster turns on its charmer.
- Cheat and convenience commands are for GM accounts only. That includes `/tele`, `/tc`, `/grind`, `/level`,
  `/mobs`, `/buff`, `/raid` and `/spawn`, and the launcher's "Teleport to" on a bot.
  [ALL SERVER COMMANDS.txt](ALL%20SERVER%20COMMANDS.txt) has the full list.
  - `/switch`, `/sell`, `/craftmacro` and `/faction` are GM only too: neither the 1.64 client's command help nor
    the DAoC Manual lists them. `/transfercorpse` is in both, so players keep it.
- No player horses: horses, horse armour and barding are off every merchant. Horse travel is by the stablemasters'
  routes.
- `/task` follows the period rules: kill targets 3 levels below you to 1 above, period task XP, and plain guards say
  who gives tasks.
- The quest markers, the objective highlights and the quest guide (`/questguide`) stay.

### The traveler's inns (new)

- One inn per realm: near Caer Witrin (Albion), near Huginfell (Midgard) and near Connla (Hibernia). Aggressive
  monsters were moved away from the inns and the roads to them.
- The **innkeeper** hires companions.
- The **Horn of Rallying:** a level-50 player who has done its courier quest starts a PvE realm event there (a dragon,
  an epic dungeon, Summoner's Hall or Darkness Falls). PvE events never start by themselves; keep sieges and relic
  raids still do.
- The **Realm Exchange**, the auction house where gamebots and players buy and sell to each other, moved from the
  capitals to the inns. Valuable items ask more, within limits. Unsold bot
  listings are relisted at 90%, then 80%, then returned.
- Couriers at levels 5 and 50 bring the inn and horn quests, with map markers. Road patrols, wandering arrow and
  poison traders, and guards complete the inns.

### Hired companions (new; they replace `/spawn` and `/raid` for players)

- Hired at the innkeeper. Slots open at levels 5, 10, 15, 20, 30, 40 and 45. You choose the race, class, gender,
  look, height and name.
- They are persistent: they log in and out with you, ride your horse routes with you, and arrive where you are.
- You manage them in their own windows:
  - gear, with a 10-slot bag;
  - spec training, with a free respec;
  - realm abilities, stats and XP.

  A smith repairs their gear.
- They stop at your level, never loot, heal your pet, and talk about what is going on. A healer revives them for
  free.

### Gamebots on the player rules

- Bots use the player rules for crit, skill, resists, crowd control, speed, procs, dual wield, focus, concentration
  and regeneration.
- **Armour works like a player's.** Before, a bot's armour did nothing when it was hit.
- They start with their class's period starting weapon only, buy their armour from vendors when they can afford it,
  and plan trips for upgrades. A bot that walks to the merchant its plan names is served there at once, and it
  wields a weapon it buys straight away.
- Arrows, bolts and poisons come from their bags and are restocked on town errands.
- Their gear wears and is repaired, for coin, by a smith or by crafting.
- **Deaths cost them:** Constitution loss on a PvE release (once per death, at most 3 points), resurrection sickness,
  and a healer visit or a wait.
- They sit to rest at the player rates, and walk to their loot bags.
- They start as a base class and are promoted at a trainer at level 5.
- About 1 in 5 bots craft: they make real recipes, gain skill, and list what they make on the Realm Exchange.
  Siegecrafters supply the siege crews.
- Camps and pulls:
  - solo bots pull from range: only a shot that reaches the monster counts (a miss or a resist still does), and a
    monster that takes no notice within 3 seconds is pulled the ordinary way;
  - camps are chosen by challenge colour;
  - grey targets are a last resort;
  - outleveled camps are left alone for 30 minutes.

### Also in Offline DAoC

These were built during this work and are shared with Offline DAoC.

- **Relic raids:**
  - the army goes to the shrine;
  - a chosen carrier runs home through its own gates;
  - sentinel keeps are taken first;
  - campaigns survive a restart.
- Solo bots pick up their own coin and loot again.
- Dead bots stay where they died. Gamebots face their melee target.

### The new client

- The period 1.64 pre-game: Choose Your Realm, the standing stones, the one-page creation with stat points, height,
  face and hair, and the summary page.
- The classic character figures and looks, and the 1.64 spell table.
- The companion windows: hire, roster, gear and train, with baseline spells.
- The Horn of Rallying window. The inns on the map, with their markers and turn-in marks.
- Models numbered past 2047. Riders seated on stable horses. Bots sitting to rest. Fighters facing their target.
  Objects that stay put across zone borders.
- The window title is "Offline DAoC True 1.65 v0.1".

### The launcher

- Fixed to True 1.65. START SERVER applies the world content and keeps every save. One ENTER REALM button starts the
  new client.
- A fresh install makes its own local login, so ENTER REALM works the first time and the server creates the account.
- Removed:
  - the XP rate controls;
  - the level-50 bot buttons (bots are added at level 1);
  - forced realm events (PvE events start from the Horn of Rallying);
  - the Realm Exchange tab (the Exchange is in game only);
  - the Reset Keeps & Relics button.

### Known issues

- **Bot deaths are high at levels 6-9.** True 1.65 bots start with no armour, so they take much more damage. The
  fixes (armour shopping first, solo ranged pulls) are in, but not yet proven in a long run.
- **Gear wears slowly**, at the player rate, so bots rarely need repairs early on. This is expected.
- **Coin-only monsters:** about 2,100 monster names still drop only coin, mostly in the Shrouded Isles, where no period
  source has their loot.
- **Merchants:** about 133 low-confidence period goods aren't added yet. Darkness Falls seal stock still includes the
  later items beside the period ones.
- Support bots don't leave combat while only their pet fights.
- The period login panel is still the older one.
- None of this has been tested by players yet beyond the owner's own play.

### Fork credits

Fixes taken from community forks of Offline DAoC, inherited from its source:

| Fix | From |
|---|---|
| Smooth group travel, the Minstrel mez freeze, Valewalker proc ranks, the Warden speed chant, and the idea for the Savage shield/offhand loop guard | [stefanrows/OfflineDAoC](https://github.com/stefanrows/OfflineDAoC) (code by Stefan Rows and Aaron Zielke, GPL-3.0) |
| The console no longer spins a CPU core when its input closes | lometur ([shadowofze/OfflineDAoC#3](https://github.com/shadowofze/OfflineDAoC/pull/3)) |
| Dead gamebots stay where they died; a meetup member that dies 3 times is a no-show | [chris4aker/OfflineDAoC-SocialExpansion](https://github.com/chris4aker/OfflineDAoC-SocialExpansion), branches `offer-0.37/dead-bot-corpse` and `offer-0.37/meetup-death-cap` |
| `/spawn` healers hold position in a fight and don't walk away to heal or buff | [Nikse77/OfflineDAoC](https://github.com/Nikse77/OfflineDAoC), branch `mod-0.37` |
| A boss's self-recasting area spell no longer runs the server out of memory | [chris4aker/OfflineDAoC-LivingServer](https://github.com/chris4aker/OfflineDAoC-LivingServer) |
| `/tc` is only the Realm Exchange teleport | lometur/HearthDAoC |
| The siege expiry throttle, effects that never end, pooled navigation queries, a bot login handle leak, medallion merchant lag, resurrection offers, one world entry per client, Torst eddies, interrupt wait seconds, the siege weapon owner, case-free quest names | [chris4aker/OfflineDAoC-LivingServer](https://github.com/chris4aker/OfflineDAoC-LivingServer) v1.1-beta. The siege throttle was first found by stefanrows/OfflineDAoC, and the endless effects by rambodolphin13/OfflineDAoC. |
| New client: target buttons, server-side targeting and the ability quickbar | [chris4aker/OfflineDAoC-SocialExpansion](https://github.com/chris4aker/OfflineDAoC-SocialExpansion), branch `offer-0.37` (author chris4aker) |
