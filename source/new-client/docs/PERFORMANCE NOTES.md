# Performance notes (2026-10-10)

The owner's goal: 40-60+ fps in an end-game raid with 200-300 bots (plus pets) animating and casting near you. Quiet places (a small town, a capital) must keep full quality. Detail may drop only while the game is under its FPS target. Upscalers (DLSS / FSR 3.1) are scrapped for now (owner): native performance only.

Test: `tests/crowd_probe.gd`, at Connla (Shannon Estuary), RTX 2060 6 GB, 1600x900 window.
- **Quiet:** your own spot.
- **Raid:** 250 clones of the zone's humanoid NPCs (real races and gear) in a ring 4-40 m around you. Every one casts real spells at the others: casting clips, hand glows, the spell, the hit, the sounds.
- **Flags:** `--variants`, `--diag`, `--split`, `--budget`, `--clips`, `--kids` and `--churn` break the cost down.

## Results

| Scene | Start of day | Now |
|---|---|---|
| Quiet Connla (15 NPCs) | 137 fps | 136 fps |
| 250 bots idle | 33 fps | 76 fps |
| 250 bots casting, FPS target 60 (default) | 7.5 fps | 67-73 fps (1% low ~50) |
| 250 bots casting, target OFF (full detail) | 7.5 fps | ~34 fps |
| City of Camelot right after loading | 1-10 fps for 1-2 min | 130-137 fps from the first frame |
| Building 250 NPCs | 31 s | 4.3 s |

## What was wrong, and the fix

1. **Advancing a stopped AnimationPlayer costs 15-20x more than a playing one** (0.6 ms vs 0.04 ms). Every bot that finished a one-shot cast or swing clip was still advanced each frame.
   - Fix: `Npc._animate_lod` skips stopped players.
   - The casting styles' mid clips now loop (`Fig3Figure.loops`).
2. **The figure textures were 4x PNGs, uncompressed, decoded the first time an NPC wore them** (about 20 MB and 0.2 s each). This caused the 1-2 minutes of slowness after loading, and 4.9 GB of VRAM in Camelot.
   - Fix: `tools/compress_textures.gd` stores BC7 copies with their mipmaps in `fig3_textures/x4plus_bc/` (same resolution, mean error 0.5/255). `Fig3Figure._tex` loads those.
3. **Godot's separate render thread** (`project.godot` `rendering/driver/threads/thread_model=2`) took the idle crowd from 41 to 75 fps. The frame was CPU-bound; the GPU needed only ~8.5 ms (`--gpu-profile`).
   - Catch: anything that reads a value back from the render thread now waits for it.
     - `GPUParticles3D.emitting` reads: NifScene keeps its own flag. They had dropped casting to ~1 fps.
     - `Node.duplicate()` of particle nodes (it reads every property back): effects are instanced from a PackedScene (`NifScene.copy_of`).
4. **Effects were rebuilt per cast** (about 1.4 ms each).
   - Fix: SpellFx pools them (`release`), and NifScene.restart replays the timeline.
   - Effects are culled when off screen, beyond `Perf.fx_range`, or past `Perf.max_effects` alive (the nearest are kept).
   - A zone's monster spells and your own spells are preloaded behind the loading screen (`SpellFx.preload_effects`).
5. **Sounds:** every NPC kept its own WAV cache, and parsed the 431 KB `sounds.json` once per NPC.
   - Both are now shared.
   - A voice cap (`Perf.voices`, 48 -> 16 under load) keeps the nearest and loudest.
   - NPC footsteps are off: in the original you only hear your own.
6. **Name plates re-coloured 265 Label3Ds every frame**, and Label3D rebuilds its text mesh each time. Now only on change.
7. **NPC updates:**
   - One loop in `NpcManager._process` (`Npc.tick`): near NPCs every frame, beyond 20 m every 2nd frame, beyond 45 m every 4th.
   - Off-screen skeletons are not updated.
   - Skeleton updates fall off by distance, within a per-frame budget.
   - Transforms are only set when they change.
   - The world simulation steps spawns more than 120 m away (and not fighting) every 4th tick.
8. **Race figures:** each race's 22 MB figure glTF took 2.5 s to parse the first time a zone needed it.
   - Fix: `tools/pack_scenes.gd` writes `figure.scn` next to it: the unused texture references stripped, animations compressed, 3.8 MB, about 0.18 s to load. `Fig3Figure.load_figure` uses it when it is newer than the glTF.
   - Owner, 2026-10-10: the load time is fine now. Don't spend more on it unless they ask.

## The governor (autoload `Perf`, `game/perf_governor.gd`)

Options > VIDEO > PERFORMANCE > FPS TARGET (default 60). OFF = brute force (`Perf.brute`): nothing is culled or simplified anywhere, for hardware that can draw a full raid. That means no effect culling, every skeleton updated every frame (on screen or not), no NPC update tiers and no far-simulation stepping. Every 0.5 s, the smoothed frame time moves one load level:
- up quickly when under 95% of the target;
- down slowly when above 120% of it for 3 s.

At level 0, everything is full quality. Toward level 1:
- NPC animation distances drop to 15%, and the skeleton update budget from 60 to 8 per frame;
- NPC shadows: 60 m -> 8 m;
- particle density: 100% -> 25%;
- spell effects: 80 m -> 10 m, 300 -> 30 alive;
- other casters' hand glows: 80 m -> 6 m;
- sound voices: 48 -> 16;
- texture mip bias: 0 -> 1.5 (only near the top).

## If load times come up again (not done; owner said leave it)

- **Load race figures in a background thread** during the loading screen: `ResourceLoader.load_threaded_request` on the `.scn` files the zone's spawns need.
- **Compress the other textures to BC7 too.** NifMaterials (zone fixtures, effects) and monster glTF images are still PNG + mipmaps generated at load. The same tool works: `tools/compress_textures.gd <dir>`. The loaders would need the `.res` lookup that `Fig3Figure._tex` has.
- **Pack monster / weapon / effect glTFs as `.scn`** with `tools/pack_scenes.gd` (monsters, weapons and effects would keep their own textures: set `keep_textures`, or strip them and give the loaders the `.res` path).
- **Zone build** (~5 s for Shannon Estuary, zone_loader) wasn't looked at.

## Still open

- With the target OFF, a raid runs at ~34 fps with every effect on: that's the full-detail cost.
- The FPS cost of bots playing on their own (AI, pathing, combat decisions) isn't known yet. The bots aren't built; the governor and the simulation LOD (point 7) are where it would be absorbed.
- Debug timers (`Npc.prof_*`, `NifScene.prof_us`, `SpellFx.prof_*`) are still in the code: cheap, used by `crowd_probe`.

## Stutter near bots (2026-10-13, 0.36c client)
- Thread errors: a spell effect on a bone of an NPC / bot had its BoneAttachment3D put on the main thread (keep_on_main);
  the skeleton is posed on a worker thread and moves the attachment every frame -> one "caller thread can't call
  set_transform()" error per frame per effect (100-500 thousand a session; each error is a locked log write).
  Rule: keep_on_main the EFFECT under the attachment, never the attachment (tests/thread_attach_probe.tscn case 8 vs 9).
  AnimLod._apply_shadow walks the model itself and skips keep_on_main nodes (find_children on them errors too).
- View churn: the server removes livings at its visibility edge (~45 m) and creates them again on return; each return
  built the figure from scratch (~18 ms warm in headless, more with the GPU upload) and every EquipmentUpdate rebuilt it.
  ServerWorld now parks removed views (hidden, 60 s, 64 max) and takes them back for the same oid / model / size /
  flags; an EquipmentUpdate with the same rows + hood/hidden flags no longer rebuilds.
- Timing probe: tests/idle_probe.gd (--secs, --rebuild, --bench-models, --toggle-fight) prints Npc.prof_build parts.
