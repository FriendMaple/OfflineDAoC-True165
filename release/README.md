# Release tools

How a True 1.65 release is built and published. Players don't need any of this; they use the downloader from the
release page (see [docs/PLAY.md](../docs/PLAY.md)).

| File | What it does |
|---|---|
| `make_release_true165.py` | Packs a release into verified parts under GitHub's 2 GB limit, adds the player docs, and records the baseline. It refuses to pack if it finds a login, a log, a backup, a test character, a developer switch or a world that isn't clean. |
| `Get-OfflineDAoC-True165.ps1` | The downloader players run. It checks the PC (64-bit Windows 10/11, AVX2, Vulkan, memory, free space, a short folder path), downloads the parts from the release (resuming if stopped), checks each part's SHA-256, unpacks it, deletes it, and offers a desktop shortcut. It installs into a new folder and never overwrites one. |
| `GET-OFFLINE-DAOC-TRUE165.cmd` | What players double-click. It runs the downloader with Windows PowerShell, and says so if it was started from inside the zip. |
| `make_downloader_true165.py` | Makes the small `Download-OfflineDAoC-True165-v<version>.zip` for the release page. |
| `RELEASE-NOTES-<version>.md` | The release page's text. |

## Making a release

1. **Game package:** `development-source/tools/build_release_true165.py` builds `runtime\`, `tools\dotnet\` and
   `START OFFLINE DAOC TRUE 1.65.cmd` from a working install, with the clean world from `database/make_clean_db.py`.
2. **Client package:** `source/new-client/tools/stage_true165_release.py` stages `new-client\` (the game, its
   converted content and the engine; no `save\`, `dev_mode.txt` or tests).
3. **Pack:**
   ```
   python -I release/make_release_true165.py --game <game package> --client <folder holding new-client> --repo . --out <assets>
   python -I release/make_downloader_true165.py --assets <assets>
   ```
4. **Test** a full install from the parts on disk, as a player would:
   `GET-OFFLINE-DAOC-TRUE165.cmd -LocalAssets <assets>`. Then compare the installed files with
   `<assets>/baseline-<version>.sha256`.
5. **Publish:** create the release `v<version>` with `RELEASE-NOTES-<version>.md` as its text, and upload everything
   in `<assets>/v<version>/`. Check every uploaded file's SHA-256 against `SHA256SUMS.txt`. Then run the downloader
   against the live release.
6. **Baseline:** commit `<assets>/baseline-<version>.sha256` as `release-baselines/<version>/package.sha256`.
