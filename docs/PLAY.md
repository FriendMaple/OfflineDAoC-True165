# How to download and play

> **Nothing has been released yet.** This guide describes how v0.1 will work. The download steps are filled in when
> the release comes out.

## Before you start

- A 64-bit Windows 10 or 11 PC whose CPU supports **AVX2**. The bots' navigation needs it. Most CPUs from 2014
  onward do.
- A graphics card that supports **Vulkan**, with current drivers. The game is developed and tested on an RTX 2060
  (6 GB).
- 16 GB RAM recommended.
- About 40 GB of free disk space. The exact figure comes with the release.
- You don't need an original DAoC client, and you don't need to install .NET: the download includes everything.

## 1. Download

The release page will have a small downloader zip. It fetches the game in checked parts into a new folder. If it
stops, run it again and it continues. Put it in a folder with a short path, for example `C:\Games\OfflineDAoC`.

> **Code > Download ZIP** on the repository page gives you the *source code*, not the playable game.

True 1.65 is a fresh start: saves from Offline DAoC 0.37 and earlier can't be brought over.

## 2. Play

1. Open your game folder and double-click the start file. The launcher shows **VERSION 0.1**.
2. Click **START SERVER** and wait until it says **RUNNING**. The first start sets up the world and can take a few
   minutes.
3. Click **ENTER REALM**. The game opens in the new client. Your own local account is created automatically the
   first time.
4. Choose a realm and create a character, as in the 1.64 client:
   - you start as a base class and choose your class at a trainer at level 5;
   - you spend your own stat points, and choose your height, face and hair;
   - each realm has 8 character slots.
5. To finish: quit the game, click **STOP SERVER**, and wait for it to save.

Only one server can run at a time.

### Bots

The world fills with gamebots that level, group, craft, trade and fight on their own.

- **Add bots** with the **+ Lv.1** button on a realm's card in the launcher. Hold **Shift** for 10 at a time, or
  **Ctrl** for 100. Bots start at level 1 and level up in the world, like you.
- **Start small** and add more as your PC allows. Every bot is simulated by the server on your PC.
- The launcher's tabs show the active population, groups, RvR, battlegrounds, realm events and realm records.
  **Bot Goals Setting** sets what the bots aim for.

### Companions

You hire your own group at your realm's **traveler's inn**: near Caer Witrin in Albion, near Huginfell in Midgard,
near Connla in Hibernia.

- At level 5 a courier brings you the inn's quest. Turn it in at the **innkeeper**, who opens the hiring window.
- A new slot opens at levels 5, 10, 15, 20, 30, 40 and 45. Your first companion is free; later ones cost coin.
- You choose each companion's race, class, look and name. It joins at level 5 with a training weapon. You give it
  gear, train its specs and pick its realm abilities.
- Companions stop at your level, never loot, and are revived for free by any healer of your realm. A smith repairs
  their gear.

### Realm war

- Keep sieges and relic raids happen on their own, and also start when you attack a keep.
- At level 50, the **Horn of Rallying** at the inn starts a great hunt: a dragon, an epic dungeon, Summoner's Hall
  or Darkness Falls. These PvE events never start by themselves.

### Commands

[QUICK COMMANDS.txt](../QUICK%20COMMANDS.txt) has the everyday commands and the launcher shortcuts, and
[ALL SERVER COMMANDS.txt](../ALL%20SERVER%20COMMANDS.txt) has every command. Shortcut commands such as `/tele` and
`/tc` are for GM accounts only in True 1.65. The client's keys and its own commands are in
[NEW-CLIENT.md](NEW-CLIENT.md).

## Troubleshooting

| Problem | Try this |
|---|---|
| ENTER REALM stays greyed out | Wait until the launcher shows RUNNING. The first start can take a few minutes. |
| START SERVER shows an error | The launcher couldn't apply the world content. It changes nothing when that happens. Note the message and report it. |
| "Port 10300 is in use", or the server won't start | Another server is running. Stop it first; only one can run at a time. |
| The game window stays black or closes at once | Update your graphics driver. The new client needs Vulkan. |
| The folder path is too long | Move the game to a shorter path, for example `C:\Games\OfflineDAoC`. |
| Windows SmartScreen blocks a file | Choose **More info → Run anyway**. The files are unsigned community builds. |
| A part of the download fails its check | Run the downloader again; it fetches only what's missing or broken. |

Keep a backup of your save before you try a new build or a mod. Your world and characters are in
`runtime\data\opendaoc-165.sqlite3.db`.
