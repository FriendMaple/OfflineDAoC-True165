"""Every input the content pipeline reads from outside this client's own folder, in one place (2026-10-31). Each one
can be set by an environment variable; without it, the repository layout is tried first and then the development
layout. A script that needs a missing input stops with need(), saying what is missing and which variable to set.

| Variable            | What                                                    | Repository layout / development layout          |
|---------------------|---------------------------------------------------------|-------------------------------------------------|
| DAOC_CLIENT         | the DAoC client's files (1.127-era, its app folder)     | (no default in the repository)                  |
| OFFLINEDAOC_SERVER  | the True 1.65 server's tree (source, runtime, data)     | the repository root / ../new class test - CLAUDE VERSION |
| OFFLINEDAOC_WORLD_DB| the True 1.65 world database                            | <server>/runtime/data/opendaoc-165.sqlite3.db    |
| PERIOD_DATA         | the period data archive (Allakhazam, Uthgard, guides)   | not in the repository / <server>/development-source/research/period-data |
| DAOC_164_ZIP        | the real 1.64 client (DAoC 1.64.zip)                    | not in the repository / ../1.64 real client/DAoC 1.64.zip |
| TRUE165_WORK        | the 1.65 layouts and extracts (inn layouts, loading)    | not in the repository / ../1.65 MODE CLIENT (local only) |
"""
import os
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent           # the new client's folder (godot/, pipeline/, ...)
_DEV = ROOT.parent                                      # the development layout's parent folder


def _env(name, *fallbacks):
    v = os.environ.get(name)
    if v:
        return Path(v)
    for f in fallbacks:
        if f is not None and f.exists():
            return f
    return fallbacks[-1] if fallbacks else None


# the repository layout: source/new-client inside the repository, the server's tree at the repository root
_REPO = ROOT.parent.parent if ROOT.parent.name == 'source' else None
SERVER = _env('OFFLINEDAOC_SERVER', _REPO if _REPO and (_REPO / 'development-source/server').exists() else None,
              _DEV / 'new class test - CLAUDE VERSION')
SERVER_SOURCE = SERVER / 'development-source/server'
GAMESERVER = SERVER_SOURCE / 'GameServer'
SERVER_RUNTIME = SERVER / 'runtime/server'
WORLD_DB = _env('OFFLINEDAOC_WORLD_DB', SERVER / 'runtime/data/opendaoc-165.sqlite3.db')
PERIOD_DATA = _env('PERIOD_DATA', SERVER / 'development-source/research/period-data')
# (development: the client copy the shipped content was built from - the server's own copy has a modified gamedata.mpk
# and pregame.mpk, so rebuilding from it would differ)
CLIENT = _env('DAOC_CLIENT', None if _REPO else ROOT / 'external/old_project/runtime/client-opendaoc/app',
              SERVER / 'runtime/client-opendaoc/app')
ZIP_164 = _env('DAOC_164_ZIP', _DEV / '1.64 real client' / 'DAoC 1.64.zip')
TRUE165_WORK = _env('TRUE165_WORK', _DEV / '1.65 MODE CLIENT (local only)')

_WHAT = {'CLIENT': 'the DAoC client files (set DAOC_CLIENT to the client\'s app folder)',
         'SERVER': 'the True 1.65 server tree (set OFFLINEDAOC_SERVER)',
         'WORLD_DB': 'the True 1.65 world database (set OFFLINEDAOC_WORLD_DB; the repository has it compressed under database/)',
         'PERIOD_DATA': 'the period data archive (set PERIOD_DATA - it is not in the repository)',
         'ZIP_164': 'the real 1.64 client, DAoC 1.64.zip (set DAOC_164_ZIP - it is not in the repository)',
         'TRUE165_WORK': 'the 1.65 layouts / extracts folder (set TRUE165_WORK - it is not in the repository)'}


def need(path, key=None):
    """The path, or stop with what is missing and how to set it."""
    p = Path(path)
    if not p.exists():
        raise SystemExit(f'missing: {p}\n  {_WHAT.get(key, "set the matching variable in pipeline/paths.py")}')
    return p
