> **Disclaimer.** Dark Age of Camelot is the intellectual property of Electronic Arts and Broadsword
> Online Games. Offline DAoC True 1.65 is not affiliated with, endorsed by, or connected to either company. The
> game client files, textures, models and other assets it uses belong to them, and this project is built on
> top of that copyrighted work.
>
> This is a free, non-commercial fan project. It is not a product and it is not for sale. No donations
> are accepted, and the project owner has not made, and will not make, any money from it. The client
> files are the same publicly available ones every free shard uses; the work original to this
> repository is the bot system, the server customizations and the new client's code. Because the code is open
> source, the owner cannot control what forks or other people do with it.
>
> This "time capsule" of the 2003 game was never meant to compete with the current retail Dark Age
> of Camelot, which is a very different, modern experience. If that interests you, please visit the
> official site: [darkageofcamelot.com](https://www.darkageofcamelot.com/).

> [!IMPORTANT]
> **Early development. Nothing has been released yet.** The first version will be **v0.1**. It is uncertain
> whether or when it will come out.

# Offline DAoC True 1.65: single-player Dark Age of Camelot as of patch 1.65

Offline DAoC True 1.65 is a local, single-player Dark Age of Camelot that runs entirely on your own PC. It
recreates the game as it was at **patch 1.65** (Classic and Shrouded Isles, November 2003), and fills the world
with gamebots that level, group, trade, craft and fight on their own.

It grew out of [Offline DAoC](https://github.com/shadowofze/OfflineDAoC), which is now on hold. The customizations
were developed with AI tools (Codex, then Claude) and directed and play-tested by the project owner.

## Built on OpenDAoC and Dawn of Light

The server is a modified [OpenDAoC](https://github.com/OpenDAoC/OpenDAoC-Core), which itself grew from
[Dawn of Light](https://github.com/Dawn-of-Light/DOLSharp) (DOL), the long-running open-source DAoC server emulator.
Their combat, spell, item, quest and world systems are the foundation everything here is built on, and their GPL
license and credits carry over to this project. True 1.65 adds the bot systems, the hired companions and the 1.65
rules on top, and replaces content that freeshards added later with period data.

## Built from period data

The 1.65 world is rebuilt from **about 85,000 pages of period data**, collected from the public sources players
used at the time:

| Source | Pages | What it gave |
|---|---|---|
| Uthgard bestiary (a 1.65 recreation) | about 25,000 | monsters, items and measured drop rates from players' kill logs |
| Allakhazam, the current site | about 24,700 | monsters, items, quests and zones, with player comments |
| Allakhazam as it read in 2001-2004 (Wayback Machine) | about 17,000 | period item stats, monster loot, merchant stock and quest walkthroughs |
| Camelot Warcry (Wayback Machine, 2001-2004) | about 11,600 | quest spoilers, items and news |
| CapnBry's DAoC radar | about 6,000 | monster positions and levels from 176,970 live-server sightings |

The patch 1.64 client's own data files supplied the recipe list, the class and race tables and the pre-game
screens.

Period sources come first: an item, drop or spawn stays only when the period data supports it, and nothing is
invented unless no source exists. **The period data itself is not in this repository at this time.** What's here
is the result: the world database and the content files built from it.

## How it differs from Offline DAoC

| | Offline DAoC (0.37 and earlier) | Offline DAoC True 1.65 |
|---|---|---|
| **Rules** | OpenDAoC's freeshard ruleset, plus many custom additions | Patch 1.65 rules only, with no mode toggle |
| **Client** | The original DAoC client, and a beta new client in 0.37c | The new client only, built in Godot 4 |
| **Items and loot** | Freeshard items, random "ROG" drops, items with later stats | Period 1.65 items, drops and vendor stock only |
| **Leveling** | XP rate options, free levels, buff merchants, hasteners | XP fixed at 1x, with no shortcuts |
| **Getting around** | Teleporters and `/tele` | Walking, horse routes and the period portals |
| **Your group** | `/spawn` companion bots on demand | Hired companions that you level, spec and gear |
| **Bots** | Separate bot rules | The same rules as players |
| **Saves** | Progress transfers from every older version | A fresh start: no progress import from Offline DAoC |

## What True 1.65 has

**The 1.65 game:**
- The Classic and Shrouded Isles world, with the three islands added in 1.65 and the Darkness Falls and Shrouded
  Isles entrances where the 1.64 client puts them.
- Base classes at character creation: you choose your class when you promote at a trainer at level 5. You spend
  your own stat points, and choose your height, face and hair. The pre-game screens follow the 1.64 client.
- Starting gear is a weapon and a training shield, from the town your race and class start in. There are 8
  character slots per realm.
- Crafting from the 1.64 client's recipe list, with the period success rates, hand tools and salvage.
- Gear wears and is repaired for coin, and arrows, throwing weapons and poisons are bought or crafted.
- Coin belongs to each character, deaths cost constitution, and songs need their own instrument type.
- Period tasks (`/task`) and housing. Quests, epic quests and epic armour are being brought to their 1.65
  versions.
- Loot comes from period sources: Allakhazam's period pages, CapnBry's radar sightings and Uthgard's measured
  drop rates. Nothing from Trials of Atlantis or later.

**Gamebots on the player rules:**
- Bots start as a base class and promote at level 5, like you.
- They sit to rest at player regeneration rates and walk to their loot bags.
- They buy their armour from vendors, repair their gear, visit healers, craft, and charm monsters only with a
  charm spell they've learned.
- They walk and ride horse routes; there are no teleporters and no boats.

**Hired companions** instead of summoned bots:
- Hire them at the traveler's inns near Caer Witrin, Connla and Huginfell.
- A new slot opens at levels 5, 10, 15, 20, 30, 40 and 45, so a full group of 8 is possible at level 45.
- You choose each companion's look, spec, realm abilities and gear.
- They level with you, and a healer revives them for free.

**Realm war:**
- Keep sieges and relic raids run on their own, and also start when you attack a keep.
- PvE realm events start only when a player sounds the Horn of Rallying at an inn.

**Kept on purpose, although they aren't from 1.65:**
- The gamebots and the bot systems.
- The Realm Exchange, now in a small building by each inn. It sells crafted and spellcrafted gear, potions,
  poisons, period drops and Darkness Falls items.
- Boss changes that let bots finish raids, and faster respawns for named and quest monsters.
- Quest markers, quest objectives and the quest guide (`/questguide`).
- Slash commands that skip the period game, such as `/tele` and `/tc`. They're kept for GM accounts only.

## Download and play

There is no release yet. When v0.1 comes out, its release page here will have a downloader and step-by-step
instructions. **Code > Download ZIP** on this page gives you the *source code*, not the playable game.

What the new client needs:
- A 64-bit Windows 10 or 11 PC.
- A graphics card that supports Vulkan, with current drivers. It's developed and tested on an RTX 2060 (6 GB).
- 16 GB RAM recommended.
- About 40 GB of free disk space for the game content and the engine. The exact figure comes with the release.

## Good to know

- **AI-written code can have bugs.** Keep a backup of your save before installing a new build or mod. There's
  no guarantee against regressions.
- **Licensing:** this repository holds the server, launcher, tools and the new client's source code. It does
  not hold the original game client's source. The new client's content is converted from the original
  client's files and ships only in the release download. The server's license doesn't relicense
  third-party client assets or dependencies. See [THIRD_PARTY.md](THIRD_PARTY.md).
- **Local only:** the default setup is for one PC. Running a public multiplayer server would need its own
  security work.
- **Forking:** you don't need permission to fork this repository and make it your own. Keep the existing
  licenses and credits ([THIRD_PARTY.md](THIRD_PARTY.md)).

## License

The server is licensed under the [GNU General Public License v3](LICENSE), like the OpenDAoC and Dawn of Light
code it is based on. Other parts keep their own licenses; see [THIRD_PARTY.md](THIRD_PARTY.md).
