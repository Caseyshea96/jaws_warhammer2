# Co-op implementation backlog

All items are pending. This is an implementation sequence, not a claim of supported game behavior.

## 1. Establish the build and tools

After Steam finishes, inspect `~/.local/share/Steam/steamapps/common/Total War WARHAMMER II` and the manifest for app 594570. Confirm `Warhammer2.exe` exists and record game build and Proton version. If Steam installed the native port, select a Steam Play compatibility tool and let Steam finish switching builds. Do not modify a running download.

Choose and pin an RPFM release supporting WH2, inspect its actual command-line interface, and extract only relevant scripts into ignored `local/`. Inspect campaign, frontend, and battle mod-loading paths; UI events; keyboard shortcuts; output logging; file I/O; and timers. Record exact source paths and observations. Never edit vanilla packs to deploy this mod.

Prepare a Lua 5.1-compatible syntax check and a C# toolchain. Keep the protocol/parser and console output backend runnable on Linux; place JAWS COM and Windows input behind platform-specific adapters. Select the target framework after confirming the friend's Windows version. Test COM process architecture instead of inferring it from the game or installer filename.

Deliverable: environment notes, verified entry paths, and a repeatable pack-building command. No guessed loader paths should ship.

## 2. Speech and transport probes, independent of game installation

Implement a companion console mode that reads sample records and prints what it would speak. Test partial records, Unicode, invalid messages, duplicate sequences, and stream restart. Then add a Windows COM probe that speaks a fixed sentence, interrupts it, and stops speech. Test JAWS missing, closed, and restarted, plus the game in focus.

Deliverable: a Windows speech diagnostic and a Linux-testable message reader. These prove infrastructure only, not game accessibility.

## 3. Minimal game probe

Package a startup marker and a read-only UI inspection command. Probe dedicated file output first, game logging second. Measure flushing and path behavior; ensure absence of the companion never blocks the game. Verify startup and cleanup in campaign, battle, frontend, and save/reload separately.

Inspect one campaign panel and one unit card. Capture representative sanitized text and component paths for regression fixtures. Prefer event-triggered reads and bounded refreshes over scanning the entire UI every frame.

Deliverable: a game-to-companion spoken message and a documented list of supported contexts.

## 4. Two small interactive slices

Campaign: on the local player's active turn, navigate one settlement panel, read an option and its cost/state, activate a normal action, and announce success only when observed. Test back/cancel and modal dialogs. Prefer a reversible UI action during initial debugging before a paid gameplay action.

Battle: select a locally controllable unit, read its status, browse a visible target, and issue normal attack/halt commands. Add one simple movement operation once the command route is established. Distinguish unit ownership from current control; allied status alone must not authorize an order.

Probe game keyboard events before adding a return channel. If a helper command file is necessary, use data-only allowlisted commands, session and UI-generation identifiers, acknowledgements, and duplicate rejection. Never run received text as Lua. Do not retry uncertain gameplay commands automatically.

Develop both in single-player, then test each in the actual co-op campaign immediately. A working tutorial/custom battle is insufficient evidence for campaign battles.

Deliverable: one usable campaign interaction and one usable battle interaction verified by the friend with JAWS.

## 5. Co-op acceptance and expansion

Run the co-op test plan with identical pack hashes and load order, helper present only on Windows. Repeat with host roles reversed. Resolve failures before adding more screens or commands.

Expand toward a complete co-op session: lobby navigation, turn announcements, settlement/army browsing, recruitment, research, construction, movement, diplomacy and dilemmas; battle deployment, target selection, movement, attack/halt, routing alerts, and results. Track unsupported screens explicitly. Assisted setup may be acceptable for an early probe, but must be recorded rather than described as independent accessibility.

## Decisions intentionally awaiting evidence

- Exact loader paths, file channel, poll frequency, and keyboard events: installed game inspection and runtime probes.
- Whether custom battle controllers synchronize: no assumption; favor normal input/UI paths and test results.
- How to detect co-op control transfers: inspect and test, never equate faction ownership with control.
- Local speech enablement: companion-local configuration; identical game packs for both players initially.
- Campaign/faction test fixture: choose content both players own; avoid introducing DLC dependencies just for testing.
- Initial transport mode: whichever co-op mode works in the unmodded baseline. LAN/server independence is a separate test, not a prerequisite for speech development.
- Friend's Windows/JAWS version, test availability, key preferences, and braille requirements: still to establish.
