# Local speech protocol v1

The game writes UTF-8 newline-delimited JSON to `%LOCALAPPDATA%/JawsWarhammer2/bridge.jsonl`, falling back to `jaws_access.jsonl` in the game working directory. The companion reads local output only; there is no command return channel or replacement multiplayer transport.

Records contain `version` (1), `session`, positive increasing `sequence`, `context` (frontend/campaign/battle), `generation`, `kind` (speech/hello/context/error/hover), and `text`. Sessions use local context/time identity without gameplay RNG. Generation changes invalidate pending UI activation. Input is handled through native game shortcuts/UI clicks and Windows keyboard mouse controls.

The Lua writer caps text at 6000 bytes and rotates output at 2 MiB. The reader skips existing history on startup, retains incomplete UTF-8 records, detects truncation/replacement, reads at most 64 KiB per poll and rejects lines beyond 32 KiB. The parser validates envelopes, drops duplicate sequences and retired sessions, and bounds retired-session memory. Fresh game input is required after starting the companion.

The companion speaks the newest primary message per polling batch; optional hover speech is off by default and yields to primary messages. Repeat, stop and mute are companion-local. Input dispatch is not proof of gameplay success; activation is never automatically retried.

See `tests/bridge_tests.ps1` and `tests/check_access.py` for automated coverage. Actual game file permissions, JAWS COM speech and co-op operation still require live testing.
