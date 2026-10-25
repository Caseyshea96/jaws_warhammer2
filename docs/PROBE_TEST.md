# First game-side probe

Status: built, checked with Lua 5.1.5 and engine mocks, packed/extracted with RPFM, and copied to Casey's game data directory. Not enabled or tested in a running game by the agent. No JAWS speech is implemented.

The mod only reads UI information and appends a diagnostic log. It does not issue gameplay commands. Default F-key behavior may still occur; the listener does not consume shortcuts. Start in a disposable single-player session.

## Run

1. Launch through Steam using Proton. Enable `jaws_probe` in the launcher mod manager. If it is not listed, stop and report that; do not rename it to a movie pack or replace game scripts.
2. At the main menu, press F2, hover a labeled button and press F3, then press F4.
3. Repeat in a single-player campaign, then in a battle. Return to the campaign and repeat F2. Save/reload and repeat if the initial checks work.
4. Look for `jaws_probe.jsonl` in the game directory, beside `Warhammer2.exe`. The filename is relative to the game's runtime working directory, so its actual location is part of this test. If absent, check `lua_mod_log.txt` for probe load/error lines.

F2 records the current game context. F3 records the **last hovered** component's ID, label and tooltip; it is a diagnostic sample and may contain stale text or game markup. F4 reports the UI root's child count. This is not keyboard navigation or a usable screen-reader interface yet.

Each record is JSON with a diagnostic session identifier and an increasing sequence. Expect a startup `hello` per script context and a first-tick message in campaign. File output stops after the first write failure, with a best-effort error in the normal mod log. No continuous hover logging or networking is performed. The file is append-only and should be archived/deleted between testing sessions while the game is closed.

## Report

Record whether the mod appears, which contexts produce `hello`, which keys generate records, whether hover text matches the UI, and whether returning from battle or reloading produces duplicates/errors. Preserve the log with the game build and pack hash. JAWS-specific keyboard conflicts will be tested separately on Windows.

Disable the probe in the launcher when finished. To remove it completely, close the game and delete only `data/jaws_probe.pack`; the separate diagnostic log can also be removed. No vanilla files need restoring.

## Rebuild and verify

```sh
local/tools/lua-5.1.5/src/luac -p mod/script/_lib/mod/jaws_probe.lua
python3 tests/check_probe.py
bash tools/build-probe.sh
```

The test runner requires a Lua interpreter path (optional first argument), defaulting to the locally built official Lua 5.1.5. Tests mock engine objects: they do not prove actual engine behavior or co-op compatibility. The builder creates a WH2 PFH5 Mod pack containing only `script/_lib/mod/jaws_probe.lua`, extracts it again, compares source bytes, and writes a SHA-256 alongside the result in `artifacts/`. Rebuilding does not automatically redeploy the pack.
